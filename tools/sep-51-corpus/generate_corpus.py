#!/usr/bin/env python3
"""Builds the SEP-0051 (XDR-JSON) conformance corpus from the hand-authored seeds.

Each seed is encoded to XDR with the pinned reference CLI and decoded straight
back, so every entry is checked by the reference before it is written. The
decoded document is what the SDK must emit, except for the seeds marked
incomparable, where the reference and SEP-0051 disagree and a named
transformation derives the specified form from the reference's output.

A transformation is not trusted to rewrite the right thing. Every incomparable
seed declares the JSON paths it expects the transformation to touch, the
transformation reports the paths it actually touched, and a difference in either
direction fails the run. Path syntax is dotted for object keys and ``[n]`` for
array indices; the empty string names the whole document, which is what an
``integer_string`` seed rewrites. A union arm key is an ordinary object key, so
``ip.i_pv4`` addresses an arm payload with the syntax struct fields already use.

Output is byte-deterministic: fixed entry order, fixed key order and one
serialisation configuration. It carries no timestamp, so a re-run on an
unchanged input produces an unchanged file and any diff is real drift.

Usage:
    python3 generate_corpus.py [--output PATH] [--advisory]

Exit codes:
    0  corpus written
    1  a seed failed, a declared divergence has disappeared, or a declared
       rewrite path set does not match what the transformation rewrote
    2  the reference CLI is missing or does not match the pin
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
ORACLE_DIR = os.path.join(REPO_ROOT, "tools", "sep-51-oracle")
PIN_FILE = os.path.join(ORACLE_DIR, "oracle-pin.json")
TYPE_MAP_FILE = os.path.join(ORACLE_DIR, "type_map.json")
NAME_MAP_FILE = os.path.join(ORACLE_DIR, "name-map.json")
MAKEFILE = os.path.join(REPO_ROOT, "Makefile")
# The committed corpus lives inside the unit-test target rather than beside this
# script. SwiftPM resolves a `.copy` resource relative to its target directory and
# rejects a path that escapes it, and the corpus is read through `Bundle.module`,
# so the file has to sit under the target's own tree. There is exactly one
# committed copy; nothing duplicates it into a generated Swift constant.
TEST_TARGET_DIR = os.path.join(REPO_ROOT, "stellarsdk", "stellarsdkUnitTests")
DEFAULT_OUTPUT = os.path.join(TEST_TARGET_DIR, "sep", "xdr_json", "corpus.json")

sys.path.insert(0, SCRIPT_DIR)
from seeds import SEEDS  # noqa: E402

# One serialisation configuration for every string written into the corpus.
DUMP = dict(ensure_ascii=False, separators=(",", ":"))

# The keys a seed may carry. A seed that supplies the fields the reference is
# supposed to produce is how a corpus turns self-referential, so the whitelist is
# enforced rather than documented. `xdr` is admitted only for a spec seed, whose
# type the reference provably cannot resolve.
SEED_KEYS = {"type", "ios_type", "json", "note", "oracle", "spec_form",
             "spec_form_paths", "input_variants", "non_utf8_paths"}
SPEC_SEED_KEYS = SEED_KEYS | {"xdr"}

ORACLE_VALUES = {"reference", "incomparable", "spec"}


class GenerationError(Exception):
    """A seed is wrong, a declared divergence no longer holds, or a rewrite is unexpected."""


class PrerequisiteError(Exception):
    """The reference CLI is absent or does not match the pin."""


# --- Reference CLI ------------------------------------------------------------


def resolve_cli(pin):
    cli = os.environ.get("STELLAR_XDR", "stellar-xdr")
    resolved = shutil.which(cli)
    if resolved is None and os.path.isfile(cli) and os.access(cli, os.X_OK):
        resolved = cli
    if resolved is None:
        raise PrerequisiteError(
            "reference CLI '%s' not found. Install it with:\n    %s\n"
            "then ensure it is on PATH, or set STELLAR_XDR."
            % (cli, pin["install"])
        )
    return resolved


def read_version(cli):
    """The version and vendored xdr commit `<cli> version` reports."""
    try:
        out = subprocess.run([cli, "version"], capture_output=True, text=True,
                             check=True).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        raise PrerequisiteError(
            "'%s version' failed; is it the XDR reference CLI? (%s)" % (cli, error)
        )
    lines = out.splitlines()
    version = lines[0].split()[1] if lines and len(lines[0].split()) > 1 else "unknown"
    commit = "unknown"
    for line in lines:
        if line.startswith("xdr:"):
            commit = line.split()[1]
            break
    return version, commit


def verify_pin(cli, pin):
    """Refuses any build but the pinned one: key spellings differ between releases."""
    version, commit = read_version(cli)
    if version != pin["version"] or commit != pin["xdr_commit"]:
        raise PrerequisiteError(
            "reference CLI does not match the pin.\n"
            "    want: version %s, xdr %s\n"
            "    got:  version %s, xdr %s\n"
            "  Install the pinned build with:\n    %s"
            % (pin["version"], pin["xdr_commit"], version, commit, pin["install"])
        )


def encode(cli, type_name, document):
    result = subprocess.run(
        [cli, "encode", "--type", type_name],
        input=json.dumps(document, **DUMP), capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise GenerationError(
            "the reference CLI rejected the authored JSON for %s: %s"
            % (type_name, result.stderr.strip())
        )
    return result.stdout.strip()


def decode(cli, type_name, base64_text):
    result = subprocess.run(
        [cli, "decode", "--type", type_name, "--input", "single-base64",
         "--output", "json"],
        input=base64_text, capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise GenerationError(
            "the reference CLI could not decode its own encoding of %s: %s"
            % (type_name, result.stderr.strip())
        )
    return result.stdout.strip()


def known_types(cli):
    result = subprocess.run([cli, "types", "list"], capture_output=True, text=True)
    if result.returncode != 0:
        raise PrerequisiteError("'%s types list' failed" % cli)
    return set(result.stdout.split())


# --- Seed shape ---------------------------------------------------------------


def contains_schema_key(value):
    """Whether `$schema` appears as an object key anywhere in a document."""
    if isinstance(value, dict):
        if "$schema" in value:
            return True
        return any(contains_schema_key(item) for item in value.values())
    if isinstance(value, list):
        return any(contains_schema_key(item) for item in value)
    return False


def check_seed_shape(seed):
    """Rejects a seed the corpus cannot honestly build from the reference alone."""
    label = "%s (%s)" % (seed.get("type", "<no type>"), seed.get("ios_type", "<no ios_type>"))
    oracle = seed.get("oracle", "reference")
    if oracle not in ORACLE_VALUES:
        raise GenerationError(
            "seed for %s names the unknown oracle class %r; expected one of %s"
            % (label, oracle, ", ".join(sorted(ORACLE_VALUES)))
        )
    allowed = SPEC_SEED_KEYS if oracle == "spec" else SEED_KEYS
    unknown = sorted(set(seed) - allowed)
    if unknown:
        raise GenerationError(
            "seed for %s carries the unsupported key(s) %s. The corpus records what the "
            "reference produces; a seed that supplies those fields itself is how a corpus "
            "becomes self-referential." % (label, ", ".join(unknown))
        )
    for required in ("type", "ios_type", "json", "note"):
        if required not in seed:
            raise GenerationError("seed for %s is missing %s" % (label, required))
    documents = [seed["json"]] + list(seed.get("input_variants") or [])
    if any(contains_schema_key(document) for document in documents):
        raise GenerationError(
            "seed for %s carries a $schema property. The corpus is built by encoding each "
            "seed with the reference, which rejects $schema (SEP-0051 says a JSON object "
            "should allow it), so such a seed fails with an error that reads like an SDK "
            "bug. $schema belongs in the hand-written schema-property tests." % label
        )
    if oracle == "incomparable":
        if seed.get("spec_form") not in SPEC_FORMS:
            raise GenerationError(
                "seed for %s is incomparable but names no known spec_form (%r)"
                % (label, seed.get("spec_form"))
            )
        if "input_variants" in seed:
            raise GenerationError(
                "seed for %s is incomparable and carries input_variants. A variant is "
                "verified by encoding it with the reference, so it must be written in the "
                "form the reference accepts, while an incomparable entry records the form "
                "SEP-0051 requires; the two cannot be the same document." % label
            )
    if "spec_form_paths" in seed and not isinstance(seed["spec_form_paths"], list):
        raise GenerationError(
            "seed for %s declares spec_form_paths that is not a list" % label
        )
    if "non_utf8_paths" in seed and not isinstance(seed["non_utf8_paths"], list):
        raise GenerationError(
            "seed for %s declares non_utf8_paths that is not a list" % label
        )


# --- Type names ---------------------------------------------------------------


def check_type_names(type_map, available):
    """`type_map.json` is the sole authority on the reference spelling of an SDK type.

    The reference names every type in Rust UpperCamelCase derived from the `.x`
    identifier, so its spelling differs from this SDK's in acronym case
    (`IpAddrType`), in the reserved-name escape (`SError`) and in the `XDR` suffix
    this SDK appends. Deriving one name from the other reports resolvable types as
    unresolvable, so a missing mapping is a hard failure rather than a fallback.

    The same check is what keeps a divergent Swift type out of the corpus. Several
    XDR definitions can share one Swift type; the mapping records the single
    definition that type was generated from, so a seed naming the other definition
    finds no mapping and stops the run. Those definitions are reachable only
    through the union arm that selects them, and that is where they must be seeded.
    """
    for seed in SEEDS:
        type_name, ios_type = seed["type"], seed["ios_type"]
        if type_name not in available and seed.get("oracle") != "spec":
            raise GenerationError(
                "the reference CLI does not know the type %s (seed for %s)"
                % (type_name, ios_type)
            )
        if ios_type not in type_map:
            raise GenerationError(
                "no type_map.json entry for the SDK type %s (seed names %s as its "
                "reference type). Rebuild the map with: "
                "ruby tools/sep-51-oracle/name_map.rb --diff"
                % (ios_type, type_name)
            )
        mapped = type_map[ios_type]
        if mapped != type_name:
            raise GenerationError(
                "seed names %s as the reference type for %s, but type_map.json gives %s. "
                "Where several XDR definitions share one Swift type, only the definition "
                "the mapping records may be seeded on that type; seed the other through "
                "the union arm that selects it."
                % (type_name, ios_type, mapped)
            )


# --- Specified forms ----------------------------------------------------------


def join_path(prefix, key):
    return key if prefix == "" else "%s.%s" % (prefix, key)


def index_path(prefix, index):
    return "%s[%d]" % (prefix, index)


def integer_string(value, prefix=""):
    """SEP-0051 Hyper Integer: a 64-bit value is a base-10 string, not a JSON number.

    The rewrite covers the whole document, which for this divergence is a bare
    number, so the reported path is the root.
    """
    if not isinstance(value, int) or isinstance(value, bool):
        raise GenerationError(
            "integer_string expects a bare JSON number, got %r" % (value,)
        )
    return str(value), {prefix}


def opaque_hex(value, prefix=""):
    """SEP-0051 Opaque Data (Fixed Length): fixed opaque is lowercase hex, not a byte array.

    The rewrite is by value, not by type: any non-empty array whose every element
    is an integer in 0..255 becomes hex. The document carries no type information,
    so there is nothing else to key on, and the whole document is walked because
    an affected field can sit nested inside a larger value.

    That heuristic would also rewrite an array of small integers that is not
    opaque data at all -- a variable-length uint32 array whose values happened to
    stay under 256 would be turned into a hex string. It is safe because every
    rewrite reports its path and the caller compares that set against the paths the
    seed declares: an array caught by the heuristic that the author did not expect
    stops the run instead of reaching the corpus.
    """
    if isinstance(value, dict):
        rewritten = {}
        paths = set()
        for key, item in value.items():
            rewritten[key], nested = opaque_hex(item, join_path(prefix, key))
            paths |= nested
        return rewritten, paths
    if isinstance(value, list):
        if value and all(isinstance(item, int) and not isinstance(item, bool)
                         and 0 <= item <= 255 for item in value):
            return "".join("%02x" % item for item in value), {prefix}
        rewritten = []
        paths = set()
        for index, item in enumerate(value):
            converted, nested = opaque_hex(item, index_path(prefix, index))
            rewritten.append(converted)
            paths |= nested
        return rewritten, paths
    return value, set()


SPEC_FORMS = {
    "integer_string": (
        integer_string,
        "SEP-0051 renders a 64-bit integer as a base-10 string; the reference "
        "emits a bare JSON number.",
    ),
    "opaque_hex": (
        opaque_hex,
        "SEP-0051 renders fixed-length opaque data as lowercase hex; the "
        "reference emits an array of byte numbers.",
    ),
}


def render_path(path):
    return "<root>" if path == "" else path


# --- UTF-8 representability ---------------------------------------------------

# The SEP-0051 String ladder, inverted. Every other rendering the spec produces --
# hex, strkey, an enum name, a decimal string -- is printable ASCII and carries no
# backslash, so a string without one is valid UTF-8 by construction.
LADDER = {"0": 0x00, "t": 0x09, "n": 0x0A, "r": 0x0D, "\\": 0x5C}


def ladder_bytes(text):
    """The bytes a SEP-0051 escaped string stands for, or None if it is not one."""
    out = bytearray()
    index = 0
    while index < len(text):
        character = text[index]
        if character != "\\":
            out.append(ord(character))
            index += 1
            continue
        if index + 1 >= len(text):
            return None
        following = text[index + 1]
        if following in LADDER:
            out.append(LADDER[following])
            index += 2
        elif following == "x" and index + 3 < len(text):
            try:
                out.append(int(text[index + 2:index + 4], 16))
            except ValueError:
                return None
            index += 4
        else:
            return None
    return bytes(out)


def find_non_utf8_paths(value, prefix=""):
    """The paths of every string whose escape-ladder bytes are not valid UTF-8."""
    if isinstance(value, dict):
        found = set()
        for key, item in value.items():
            found |= find_non_utf8_paths(item, join_path(prefix, key))
        return found
    if isinstance(value, list):
        found = set()
        for index, item in enumerate(value):
            found |= find_non_utf8_paths(item, index_path(prefix, index))
        return found
    if isinstance(value, str) and "\\" in value:
        raw = ladder_bytes(value)
        if raw is None:
            return set()
        try:
            raw.decode("utf-8")
        except UnicodeDecodeError:
            return {prefix}
    return set()


def check_utf8(seed, document):
    """A string this SDK cannot hold must not reach the corpus undeclared.

    Every XDR `string<>` is a Swift `String`, which is guaranteed well-formed
    Unicode, so a value carrying a lone continuation or lead byte round-trips
    through the reference but cannot be constructed, decoded or held here: the
    binary decoder rejects it before any SEP-0051 code runs. An opaque field is
    backed by `Data` or `WrappedDataN` and is byte-exact, so the same bytes are
    fine there.

    The document alone does not say which of the two a string came from, and the
    distinction is not recoverable from the committed artefacts. So the seed
    declares it and the declaration is checked in both directions, the way a
    transformation declares the paths it rewrites.
    """
    declared = set(seed.get("non_utf8_paths") or [])
    found = find_non_utf8_paths(document)
    if declared == found:
        return
    undeclared = sorted(found - declared)
    absent = sorted(declared - found)
    detail = []
    if undeclared:
        detail.append(
            "not valid UTF-8 and not declared: %s"
            % ", ".join(render_path(path) for path in undeclared))
    if absent:
        detail.append(
            "declared but valid UTF-8: %s"
            % ", ".join(render_path(path) for path in absent))
    raise GenerationError(
        "seed for %s renders a string whose escape-ladder bytes do not match its "
        "non_utf8_paths declaration (%s). A value reaching an XDR string<> must be "
        "valid UTF-8, because this SDK models those fields as a Swift String and "
        "cannot hold anything else; declare the path only where the field is opaque "
        "and therefore byte-exact." % (seed["type"], "; ".join(detail))
    )


def check_rewrite_paths(seed, rewritten_paths):
    """The declared rewrite set must equal the rewritten one, in both directions."""
    if "spec_form_paths" not in seed:
        raise GenerationError(
            "seed for %s is marked incomparable but declares no spec_form_paths. Every "
            "incomparable seed declares the paths its transformation rewrites; a seed "
            "whose transformation rewrites nothing declares the empty list."
            % seed["type"]
        )
    declared = set(seed["spec_form_paths"])
    if declared == rewritten_paths:
        return
    unexpected = sorted(rewritten_paths - declared)
    absent = sorted(declared - rewritten_paths)
    detail = []
    if unexpected:
        detail.append("rewrote but did not declare: %s"
                      % ", ".join(render_path(path) for path in unexpected))
    if absent:
        detail.append("declared but did not rewrite: %s"
                      % ", ".join(render_path(path) for path in absent))
    raise GenerationError(
        "seed for %s declares a spec_form_paths set the %s transformation did not "
        "produce (%s). An undeclared rewrite is the case where the byte-array "
        "heuristic caught an integer array that is not opaque data."
        % (seed["type"], seed["spec_form"], "; ".join(detail))
    )


# --- Corpus -------------------------------------------------------------------


def read_json(path, what, remedy):
    """Reads a committed artefact, reporting an absent or malformed one as a prerequisite."""
    try:
        with open(path) as handle:
            return json.load(handle)
    except FileNotFoundError:
        raise PrerequisiteError("%s not found at %s. %s" % (what, path, remedy))
    except json.JSONDecodeError as error:
        raise PrerequisiteError("%s at %s is not valid JSON: %s. %s"
                                % (what, path, error, remedy))


def read_pin():
    return read_json(PIN_FILE, "the reference pin", "It is committed; restore it from git.")


def read_name_map():
    return read_json(
        NAME_MAP_FILE, "the name table",
        "Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff",
    )


def read_sdk_xdr_commit():
    """The XDR pin this SDK generates from, read from the Makefile that fetches the `.x`."""
    try:
        handle = open(MAKEFILE)
    except FileNotFoundError:
        raise PrerequisiteError("the Makefile carrying the XDR pin is not at %s" % MAKEFILE)
    with handle:
        for line in handle:
            stripped = line.strip()
            if stripped.startswith("XDR_COMMIT"):
                name, _, value = stripped.partition("=")
                if name.strip() == "XDR_COMMIT":
                    return value.strip()
    raise PrerequisiteError("XDR_COMMIT missing from %s" % MAKEFILE)


def read_unresolvable(name_map):
    """The names the reference CLI could not resolve when the name table was built.

    Both lists are empty while the reference vendors an XDR commit at least as
    new as the SDK's. Recording them keeps the corpus honest about its own
    coverage when that stops being true.
    """
    verification = name_map.get("verification")
    # A plain `name_map.rb` run records a sentence here instead of the counts, because it
    # never probed the reference. The corpus needs the lists, so that is a prerequisite.
    if not isinstance(verification, dict):
        raise PrerequisiteError(
            "%s carries no verification block, so the name table was built without probing "
            "the reference. Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff"
            % NAME_MAP_FILE
        )
    try:
        return (sorted(verification["enum_members_unresolvable"]),
                sorted(verification["struct_types_unresolvable"]))
    except KeyError as error:
        raise PrerequisiteError(
            "%s has a verification block without %s. Rebuild it with: "
            "ruby tools/sep-51-oracle/name_map.rb --diff" % (NAME_MAP_FILE, error)
        )


def check_input_variants(cli, seed, base64_text, findings):
    """Every alternative input spelling must encode to the entry's own base64.

    The corpus records what the SDK must emit, and the reference emits one spelling
    per key, so an accepted alternative cannot arrive through the normal path. It
    arrives as a variant instead, and stays oracle-verified because the reference
    is what proves the two documents mean the same XDR.
    """
    variants = seed.get("input_variants")
    if not variants:
        return None
    rendered = []
    for variant in variants:
        try:
            variant_base64 = encode(cli, seed["type"], variant)
        except GenerationError as error:
            if findings is None:
                raise
            findings.append("%s input variant: %s" % (seed["type"], error))
            return None
        if variant_base64 != base64_text:
            message = (
                "an input variant of %s encodes to %s, but the seed encodes to %s; a "
                "variant must be a second spelling of the same value"
                % (seed["type"], variant_base64, base64_text)
            )
            if findings is None:
                raise GenerationError(message)
            findings.append(message)
            return None
        rendered.append(json.dumps(variant, **DUMP))
    return rendered


def build_spec_entry(seed, available, unresolvable_names):
    """Builds the entry for a type the pinned reference cannot resolve.

    Such a value cannot be produced by the reference at all, so it is written from
    SEP-0051 and the `.x` by hand. The two guards that keep that from becoming a
    licence to hand-write anything: the type must appear in the name table's
    unresolvable list, and the reference must genuinely not know it.
    """
    if seed["type"] in available:
        raise GenerationError(
            "seed for %s is marked spec-derived, but the reference resolves that type. A "
            "spec-derived value is admissible only where the reference is silent; encode "
            "this seed through the reference instead." % seed["type"]
        )
    if seed["type"] not in unresolvable_names and seed["ios_type"] not in unresolvable_names:
        raise GenerationError(
            "seed for %s is marked spec-derived, but the name table does not list it as "
            "unresolvable. Rebuild the table with: "
            "ruby tools/sep-51-oracle/name_map.rb --diff" % seed["type"]
        )
    if "xdr" not in seed:
        raise GenerationError(
            "spec-derived seed for %s carries no xdr; the reference cannot supply it"
            % seed["type"]
        )
    return {
        "type": seed["type"],
        "ios_type": seed["ios_type"],
        "xdr": seed["xdr"],
        "json": json.dumps(seed["json"], **DUMP),
        "oracle": "spec",
        "note": seed["note"],
    }


def build_entry(cli, seed, available, unresolvable_names, findings=None):
    """Builds one corpus entry.

    A seed problem normally raises. When ``findings`` is a list the problem is appended to
    it instead, so an advisory run reports every affected seed in one pass rather than
    stopping at the first. A seed the build cannot process at all yields no entry, and its
    absence shows up in the diff alongside the recorded finding.
    """
    if seed.get("oracle") == "spec":
        try:
            return build_spec_entry(seed, available, unresolvable_names)
        except GenerationError as error:
            if findings is None:
                raise
            findings.append("%s: %s" % (seed["type"], error))
            return None

    try:
        base64_text = encode(cli, seed["type"], seed["json"])
        oracle_text = decode(cli, seed["type"], base64_text)
    except GenerationError as error:
        if findings is None:
            raise
        findings.append("%s: %s" % (seed["type"], error))
        return None
    oracle_value = json.loads(oracle_text)

    variants = check_input_variants(cli, seed, base64_text, findings)

    if seed.get("oracle") != "incomparable":
        try:
            check_utf8(seed, oracle_value)
        except GenerationError as error:
            if findings is None:
                raise
            findings.append(str(error))
        entry = {
            "type": seed["type"],
            "ios_type": seed["ios_type"],
            "xdr": base64_text,
            "json": json.dumps(oracle_value, **DUMP),
            "oracle": "reference",
            "note": seed["note"],
        }
        if variants:
            entry["input_variants"] = variants
        return entry

    form = seed["spec_form"]
    transform, reason = SPEC_FORMS[form]
    specified, rewritten_paths = transform(oracle_value)
    for check in (lambda: check_rewrite_paths(seed, rewritten_paths),
                  lambda: check_utf8(seed, specified)):
        try:
            check()
        except GenerationError as error:
            if findings is None:
                raise
            findings.append(str(error))
    if specified == oracle_value:
        message = (
            "seed for %s is marked incomparable under %s, but the reference "
            "already emits the specified form; the divergence is gone and the "
            "seed must be reclassified" % (seed["type"], form)
        )
        if findings is None:
            raise GenerationError(message)
        findings.append(message)
    return {
        "type": seed["type"],
        "ios_type": seed["ios_type"],
        "xdr": base64_text,
        "json": json.dumps(specified, **DUMP),
        "oracle": "incomparable",
        "note": seed["note"],
        "reason": reason,
        "spec_form": form,
        "spec_form_paths": sorted(seed["spec_form_paths"]),
        "oracle_json": json.dumps(oracle_value, **DUMP),
    }


# --- Completeness -------------------------------------------------------------


def json_tokens(value, into):
    """Every object key and every bare string in a document.

    A union arm renders as a bare string when the arm is void and as an object key
    when it is not, and a struct field is always a key, so the two together are
    where a derived wire name can appear.
    """
    if isinstance(value, dict):
        for key, item in value.items():
            into.add(key)
            json_tokens(item, into)
    elif isinstance(value, list):
        for item in value:
            json_tokens(item, into)
    elif isinstance(value, str):
        into.add(value)


def definition_wire_names(definition):
    """The JSON names one XDR definition puts on the wire."""
    if "members" in definition:
        return {member["json"] for member in definition["members"]}
    if "fields" in definition:
        return {field["json"] for field in definition["fields"]}
    if "arms" in definition:
        return {arm["json"] for arm in definition["arms"]}
    return set()


def divergent_wire_names(name_map):
    """The wire names on which XDR definitions sharing one Swift type disagree.

    Derived, never configured: the name table records every definition's Swift form,
    so a Swift name behind more than one definition is a collapse and a collapse
    whose definitions derive different names is a divergence. The names in the
    symmetric difference are exactly the ones a corpus exercising only one side of
    such a pair would never see.
    """
    by_swift = {}
    for group in ("enums", "structs", "unions"):
        for definition in name_map.get(group, []):
            by_swift.setdefault(definition["swift_name"], []).append(definition)
    divergent = {}
    for swift_name, definitions in by_swift.items():
        if len(definitions) < 2:
            continue
        name_sets = [definition_wire_names(definition) for definition in definitions]
        union = set().union(*name_sets)
        shared = set.intersection(*name_sets)
        if union != shared:
            divergent[swift_name] = sorted(union - shared)
    return divergent


def check_completeness(entries, name_map, unresolvable_enum_members,
                       unresolvable_struct_types, type_map):
    """Assertions read from the committed artefacts, never from a hardcoded list."""
    problems = []
    entry_types = {entry["type"] for entry in entries}
    by_type = {}
    for entry in entries:
        by_type.setdefault(entry["type"], []).append(entry)

    tokens = set()
    for entry in entries:
        json_tokens(json.loads(entry["json"]), tokens)

    def reference_name(swift_name):
        return type_map.get(swift_name, swift_name)

    # Every name the pinned reference cannot resolve carries a spec-derived entry.
    spec_types = {entry["type"] for entry in entries if entry["oracle"] == "spec"}
    spec_tokens = set()
    for entry in entries:
        if entry["oracle"] == "spec":
            json_tokens(json.loads(entry["json"]), spec_tokens)
    for name in unresolvable_struct_types:
        if reference_name(name) not in spec_types and name not in spec_types:
            problems.append(
                "the name table lists %s as unresolvable by the pinned reference, so it "
                "needs a spec-derived corpus entry" % name)
    for member in unresolvable_enum_members:
        wire = member.rsplit(".", 1)[-1]
        if wire not in spec_tokens:
            problems.append(
                "the name table lists the enum member %s as unresolvable by the pinned "
                "reference, so it needs a spec-derived corpus entry" % member)

    def enum_members(xdr_name):
        for enum in name_map.get("enums", []):
            if enum["xdr_qualified_name"] == xdr_name:
                return enum
        return None

    # The digit-leading branch of the naming rule has one exercise in the `.x` set.
    fuse = enum_members("BinaryFuseFilterType")
    if fuse is None:
        problems.append("BinaryFuseFilterType is absent from the name table")
    else:
        wanted = reference_name(fuse["swift_name"])
        rendered = {json.loads(entry["json"]) for entry in by_type.get(wanted, [])
                    if isinstance(json.loads(entry["json"]), str)}
        for member in fuse["members"]:
            if member["json"] not in rendered:
                problems.append(
                    "%s member %s carries no corpus entry; it is the digit-leading branch "
                    "of the enum naming rule" % (wanted, member["json"]))

    # Both arms of the address-family enum, whose word split yields `i_pv4`.
    ip = enum_members("IPAddrType")
    if ip is None:
        problems.append("IPAddrType is absent from the name table")
    else:
        wanted = reference_name(ip["swift_name"])
        rendered = {json.loads(entry["json"]) for entry in by_type.get(wanted, [])
                    if isinstance(json.loads(entry["json"]), str)}
        for member in ip["members"]:
            if member["json"] not in rendered:
                problems.append("%s member %s carries no corpus entry"
                                % (wanted, member["json"]))

    # Every type carrying an XDR field named `type`, and the alternative spelling.
    type_field_types = []
    for struct in name_map.get("structs", []):
        if any(field["identifier"] == "type" for field in struct["fields"]):
            type_field_types.append(reference_name(struct["swift_name"]))
    for wanted in type_field_types:
        if wanted not in entry_types:
            problems.append(
                "%s carries an XDR field named type and so needs a corpus entry" % wanted)
    variant_types = {entry["type"] for entry in entries if entry.get("input_variants")}
    if not variant_types & set(type_field_types):
        problems.append(
            "no type carrying an XDR field named type declares an input variant; the "
            "alternative spelling the reference accepts is otherwise unpinned")

    # The subset-union regression guard: the arm key comes from the discriminant
    # enum's full member list, not from the union's own single case.
    for union in name_map.get("unions", []):
        if union["xdr_qualified_name"] != "FeeBumpTransactionInnerTx":
            continue
        wanted = reference_name(union["swift_name"])
        expected = {arm["json"] for arm in union["arms"]}
        found = False
        for entry in by_type.get(wanted, []):
            document = json.loads(entry["json"])
            if isinstance(document, dict) and set(document) <= expected:
                found = True
        if not found:
            problems.append(
                "%s carries no corpus entry keyed on %s; it is the subset-union regression "
                "guard" % (wanted, ", ".join(sorted(expected))))
        break
    else:
        problems.append("FeeBumpTransactionInnerTx is absent from the name table")

    # Both sides of every collapse whose definitions render differently.
    for swift_name, names in sorted(divergent_wire_names(name_map).items()):
        for name in names:
            if name not in tokens:
                problems.append(
                    "the wire name %s is one of the renderings several XDR definitions "
                    "behind %s disagree on, and no corpus entry exercises it"
                    % (name, swift_name))
    return problems


# --- Generation ---------------------------------------------------------------


def seed_projection(seed):
    """The part of a corpus entry that is copied from its seed.

    Everything else in an entry comes from the reference and so cannot be re-derived
    without it. These fields can, which is what makes an offline check possible.
    """
    projected = {
        "type": seed["type"],
        "ios_type": seed["ios_type"],
        "oracle": seed.get("oracle", "reference"),
        "note": seed["note"],
    }
    if projected["oracle"] == "incomparable":
        projected["spec_form"] = seed["spec_form"]
        projected["spec_form_paths"] = sorted(seed["spec_form_paths"])
    return projected


def entry_projection(entry):
    """The same fields, read back out of a committed entry."""
    projected = {key: entry.get(key) for key in ("type", "ios_type", "oracle", "note")}
    if projected["oracle"] == "incomparable":
        projected["spec_form"] = entry.get("spec_form")
        projected["spec_form_paths"] = entry.get("spec_form_paths")
    return projected


def validate_committed(corpus_path=DEFAULT_OUTPUT):
    """Checks the committed artefacts against each other and against the seeds.

    This is the half of the corpus contract that needs no reference build: the seeds obey
    the shape rules, every seed reached the corpus with its declared metadata intact, the
    corpus was built from the pins that are committed today, and every completeness
    assertion still holds. What it cannot check is the half that only the reference can
    answer -- whether the recorded JSON and base64 are what the reference produces. That
    stays with `refresh_corpus.sh`.

    Returns the list of problems found; an empty list means agreement.
    """
    problems = []

    for seed in SEEDS:
        check_seed_shape(seed)
        if seed.get("oracle") == "incomparable" and "spec_form_paths" not in seed:
            problems.append(
                "seed for %s is marked incomparable but declares no spec_form_paths"
                % seed["type"]
            )

    pin = read_pin()
    name_map = read_name_map()
    type_map = read_json(
        TYPE_MAP_FILE, "the type map",
        "Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff",
    )["type_map"]
    corpus = read_json(
        corpus_path, "the committed corpus",
        "Rebuild it with: python3 tools/sep-51-corpus/generate_corpus.py",
    )
    entries = corpus.get("entries") or []
    metadata = corpus.get("metadata") or {}

    unmapped = sorted({seed["ios_type"] for seed in SEEDS} - set(type_map))
    if unmapped:
        problems.append(
            "no reference spelling recorded for %s; type_map.json is the sole authority "
            "on the pairing and a seed without one cannot be built" % ", ".join(unmapped)
        )

    expected = sorted((seed_projection(seed) for seed in SEEDS),
                      key=lambda item: (item["type"], item["ios_type"], item["note"]))
    actual = sorted((entry_projection(entry) for entry in entries),
                    key=lambda item: (item["type"], item["ios_type"], item["note"]))
    if expected != actual:
        problems.append(
            "the committed corpus does not match the seeds: %d seeds against %d entries. "
            "Regenerate it with: python3 tools/sep-51-corpus/generate_corpus.py"
            % (len(expected), len(actual))
        )
        for missing in [item for item in expected if item not in actual]:
            problems.append("  seeded but not in the corpus: %s (%s)"
                            % (missing["type"], missing["note"]))
        for extra in [item for item in actual if item not in expected]:
            problems.append("  in the corpus but not seeded: %s (%s)"
                            % (extra["type"], extra["note"]))

    for field, expected_value in (("reference_tool", pin["tool"]),
                                  ("reference_version", pin["version"]),
                                  ("reference_xdr_commit", pin["xdr_commit"]),
                                  ("sdk_xdr_commit", read_sdk_xdr_commit()),
                                  ("entry_count", len(entries))):
        if metadata.get(field) != expected_value:
            problems.append(
                "corpus metadata %s is %r but should be %r; the committed corpus was not "
                "built from the pins committed today"
                % (field, metadata.get(field), expected_value)
            )

    unresolvable_enum_members, unresolvable_struct_types = read_unresolvable(name_map)
    problems.extend(check_completeness(entries, name_map, unresolvable_enum_members,
                                       unresolvable_struct_types, type_map))
    return problems


def generate(output_path, advisory=False):
    """Builds the corpus.

    Normally the reference build must match the pin exactly. An advisory run instead
    accepts whatever build is on PATH and records its version in the metadata, so a newer
    release can be compared against the committed corpus without disturbing it. It never
    writes to the committed file; the caller supplies a scratch path.
    """
    pin = read_pin()
    cli = resolve_cli(pin)
    findings = [] if advisory else None

    if advisory:
        if os.path.abspath(output_path) == os.path.abspath(DEFAULT_OUTPUT):
            raise PrerequisiteError(
                "an advisory run must not write the committed corpus; pass --output"
            )
        version, commit = read_version(cli)
    else:
        verify_pin(cli, pin)
        version, commit = pin["version"], pin["xdr_commit"]

    for seed in SEEDS:
        check_seed_shape(seed)

    name_map = read_name_map()
    type_map = read_json(
        TYPE_MAP_FILE, "the type map",
        "Rebuild it with: ruby tools/sep-51-oracle/name_map.rb --diff",
    )["type_map"]
    available = known_types(cli)
    check_type_names(type_map, available)

    unresolvable_enum_members, unresolvable_struct_types = read_unresolvable(name_map)
    unresolvable_names = set(unresolvable_struct_types)

    built = [build_entry(cli, seed, available, unresolvable_names, findings)
             for seed in SEEDS]
    entries = [entry for entry in built if entry is not None]

    problems = check_completeness(entries, name_map, unresolvable_enum_members,
                                  unresolvable_struct_types, type_map)
    if problems:
        if findings is None:
            raise GenerationError(
                "the corpus is incomplete:\n    " + "\n    ".join(problems))
        findings.extend(problems)

    corpus = {
        "metadata": {
            "description": (
                "SEP-0051 (XDR-JSON) conformance corpus. Each entry pins the "
                "exact JSON text the SDK must emit for one XDR value and the "
                "base64 XDR that value encodes to."
            ),
            "reference_tool": pin["tool"],
            "reference_version": version,
            "reference_xdr_commit": commit,
            "sdk_xdr_commit": read_sdk_xdr_commit(),
            "entry_count": len(entries),
            "unresolvable_enum_members": unresolvable_enum_members,
            "unresolvable_struct_types": unresolvable_struct_types,
        },
        "entries": entries,
    }

    directory = os.path.dirname(os.path.abspath(output_path))
    if directory:
        os.makedirs(directory, exist_ok=True)
    with open(output_path, "w") as handle:
        json.dump(corpus, handle, ensure_ascii=False, indent=2, sort_keys=False)
        handle.write("\n")

    return corpus, findings or []


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--output", default=DEFAULT_OUTPUT,
                        help="where to write corpus.json (default: %(default)s)")
    parser.add_argument("--advisory", action="store_true",
                        help="accept a build other than the pinned one and record its "
                             "version; requires --output and never writes the committed "
                             "corpus. For comparing a new reference release.")
    parser.add_argument("--validate-committed", action="store_true",
                        help="check the committed corpus against the seeds, the pins and "
                             "the completeness rules without the reference CLI, and write "
                             "nothing. Does not check the recorded JSON or base64.")
    args = parser.parse_args()

    if args.validate_committed:
        try:
            problems = validate_committed(args.output)
        except PrerequisiteError as error:
            print("generate_corpus.py: %s" % error, file=sys.stderr)
            return 2
        except GenerationError as error:
            print("generate_corpus.py: %s" % error, file=sys.stderr)
            return 1
        if problems:
            print("generate_corpus.py: the committed corpus does not agree with the "
                  "committed seeds and pins:", file=sys.stderr)
            for problem in problems:
                print("    %s" % problem, file=sys.stderr)
            return 1
        print("Validated %s against %d seeds: shape, pins and completeness all agree."
              % (args.output, len(SEEDS)))
        return 0

    try:
        corpus, findings = generate(args.output, advisory=args.advisory)
    except PrerequisiteError as error:
        print("generate_corpus.py: %s" % error, file=sys.stderr)
        return 2
    except GenerationError as error:
        print("generate_corpus.py: %s" % error, file=sys.stderr)
        return 1

    entries = corpus["entries"]
    incomparable = [entry for entry in entries if entry["oracle"] == "incomparable"]
    incomparable_types = sorted({entry["type"] for entry in incomparable})
    if args.advisory:
        print("ADVISORY: generated against %s %s, not the pinned build."
              % (corpus["metadata"]["reference_tool"],
                 corpus["metadata"]["reference_version"]))
    print("Wrote %s" % args.output)
    print("  entries:        %d" % len(entries))
    print("  distinct types: %d" % len({entry["type"] for entry in entries}))
    print("  comparable:     %d" % (len(entries) - len(incomparable)))
    print("  incomparable:   %d (%s)" % (len(incomparable),
                                         ", ".join(incomparable_types)))
    print("  input variants: %d" % sum(len(entry.get("input_variants", []))
                                       for entry in entries))

    if findings:
        print("")
        print("ADVISORY: %d seed(s) behave differently under this build:" % len(findings))
        for finding in findings:
            print("  - %s" % finding)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
