#!/usr/bin/env python3
"""
Stellar iOS SDK API Reference Generator

Generates a compact markdown file listing all public class/method/property signatures
for the stellar-ios-mac-sdk by parsing Swift source files.

Emits a member iff it is effectively PUBLIC: it carries an explicit `public`/`open`
modifier, OR it carries no explicit access modifier and its enclosing context makes
members public-by-default (a `public`/`open` extension, or a protocol body). Members
with an explicit `private`/`fileprivate`/`internal` modifier are never emitted.

Usage: python3 generate_api_reference.py
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import List

# Configuration — paths derived from script location (CWD-independent)
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SDK_PATH = REPO_ROOT / "stellarsdk" / "stellarsdk"
OUTPUT_PATH = REPO_ROOT / "skills" / "stellar-ios-mac-sdk" / "references" / "api_reference.md"

# Directories to skip entirely.
# Matched by basename at ANY depth (path-blind): a directory whose final path
# component equals one of these is pruned wherever it appears (e.g. the nested
# `responses/xdr` is skipped, which is intended). There is no `sep` directory in
# the SDK — SEP sources live in named directories (kyc, toml, web_authentication,
# transfer_server_protocol, etc.) and ARE scanned.
SKIP_DIRS = {"xdr", "Tests"}

# Directory-name suffixes to skip (bundle directories carry no scannable sources).
SKIP_DIR_SUFFIXES = (".xcodeproj", ".xcassets")

# First characters of a declaration that may follow a top-level newline without
# the preceding line being a continuation. Each letter covers the Swift keyword(s)
# a member declaration can begin with:
#   p -> public/private        o -> open/override/operator
#   i -> internal/init/indirect    f -> func/fileprivate/final
#   v -> var                   l -> lazy/let
#   s -> static/struct/subscript   c -> class/case/convenience
#   t -> typealias             e -> enum/extension
#   @ -> attribute             } -> end of an enclosing block
DECL_START_CHARS = ('p', 'o', 'i', 'f', 'v', 'l', 's', 'c', 't', 'e', '@', '}')

# Group titles (order matters for output)
GROUP_TITLES = {
    "core": "Core Classes",
    "requests": "Requests",
    "responses": "Responses",
    "soroban": "Soroban",
    "crypto": "Crypto",
    "operations": "Operations",
    "sdk": "SDK Core",
}

# Member field names in canonical emit order. Single source of truth: every
# consumer (format_type_section, count_members, merge_extensions) is driven from
# this tuple, so adding a member kind means editing exactly one list.
MEMBER_FIELDS = (
    "typealiases", "constants", "cases", "nested_types",
    "properties", "initializers", "methods", "subscripts",
)

# --- Reusable regex fragments ---------------------------------------------------
# ACCESS matches an explicit access modifier optionally followed by a
# setter-access restriction such as `private(set)`. The member is public when its
# access keyword is public/open; the setter restriction does not change that.
ACCESS = r'(?:public|open)(?:\((?:set)\))?(?:\s+(?:private|fileprivate|internal|public)\(set\))?'
GENERICS = r'(?:<[^>]+>)?'

# Modifiers that may appear (in any order) alongside the access keyword on a
# stored/computed property or a static constant.
_PROP_OTHER_MODS = ('static', 'class', 'lazy', 'weak', 'unowned', 'final')
# Modifiers that may appear on a method.
_METHOD_OTHER_MODS = ('static', 'class', 'final', 'override', 'mutating', 'nonmutating')
# Modifiers that may appear on an initializer.
_INIT_OTHER_MODS = ('convenience', 'required', 'override')

# Precompiled per-declaration patterns (compiled once at module load).
RE_ATTRIBUTE = re.compile(r'@\w+(?:\([^)]*\))?\s*')
RE_EXPLICIT_NONPUBLIC = re.compile(r'^(?:private|fileprivate|internal)\b')
RE_HAS_PUBLIC = re.compile(r'\b(?:public|open)\b')

RE_TYPEALIAS = re.compile(r'(?:typealias)\s+(\w+)\s*=\s*(.+)')

# Static/class constant. The `let`/`var` group is captured deliberately so the
# storage keyword survives into the output; do NOT collapse `let` into `var`.
RE_STATIC_CONST = re.compile(
    r'(?:static|class)\s+(let|var)\s+(\w+)\s*'
    r'(?::\s*([^=]+?))?'          # optional explicit type
    r'(?:\s*=\s*(.*))?$'          # optional initializer RHS (may be empty when a
                                  # closure body was split off as a member block)
)

RE_PROPERTY = re.compile(
    r'((?:(?:' + '|'.join(_PROP_OTHER_MODS) + r')\s+)*)'
    r'(?:var|let)\s+(\w+)\s*'
    r'(?::\s*([^=\{]+?))?'        # optional explicit type
    r'(?:\s*=\s*[^\{]+)?'         # optional initializer RHS
    r'(\{.*)?$'                   # optional computed-property accessor block
)

RE_INIT = re.compile(
    r'((?:(?:' + '|'.join(_INIT_OTHER_MODS) + r')\s+)*)'
    r'init([?!])?\s*' + GENERICS + r'\s*\('
)

RE_FUNC = re.compile(
    r'((?:(?:' + '|'.join(_METHOD_OTHER_MODS) + r')\s+)*)'
    r'func\s+([\w+\-*/%<>=!&|^~]+)(' + GENERICS + r')\s*\('
)

RE_SUBSCRIPT = re.compile(
    r'((?:(?:static|class)\s+)*)'
    r'subscript\s*(' + GENERICS + r')\s*\('
)

RE_NESTED_TYPE = re.compile(
    r'((?:final|open)\s+)?'
    r'(class|struct|enum|protocol|actor)\s+(\w+)'
)

# Enum case declaration (the `case` keyword inside an enum body).
RE_ENUM_CASE = re.compile(r'case\s+(.+)$')

# Top-level type declaration.
RE_TYPE_DECL = re.compile(
    r'\b(?:(public|open)\s+)?'
    r'((?:final|open)\s+)?'
    r'(class|struct|enum|protocol|actor|extension)\s+'
    r'(\w+)'
    r'((?:\s*:\s*[\w<>,\s&@]+)?)'  # @ supports @unchecked, @retroactive, etc.
    r'(?:\s+where\s+[^{]+)?'
    r'\s*\{',
    re.MULTILINE
)


@dataclass
class MemberInfo:
    """Parsed class/struct/enum/protocol information."""
    name: str
    kind: str = ""  # "class", "struct", "enum", "protocol", "actor", "extension"
    access: str = "public"
    protocols: List[str] = field(default_factory=list)
    typealiases: List[str] = field(default_factory=list)
    constants: List[str] = field(default_factory=list)
    cases: List[str] = field(default_factory=list)
    nested_types: List[str] = field(default_factory=list)
    properties: List[str] = field(default_factory=list)
    initializers: List[str] = field(default_factory=list)
    methods: List[str] = field(default_factory=list)
    subscripts: List[str] = field(default_factory=list)


def determine_group(rel_path: str) -> str:
    """Determine which group a file belongs to based on its relative path."""
    parts = rel_path.split(os.sep)
    if len(parts) > 1:
        subdir = parts[0]
        if subdir in GROUP_TITLES:
            return subdir
        # Map some directories
        if "request" in subdir.lower():
            return "requests"
        if "response" in subdir.lower():
            return "responses"
        if "operation" in subdir.lower() or subdir == "sdk":
            return "operations"
    return "core"


def strip_comments(content: str) -> str:
    """Remove all comments from Swift source."""
    result = []
    i = 0
    n = len(content)

    while i < n:
        # String literals
        if content[i] == '"':
            quote = content[i]
            # Triple-quoted strings
            if i + 2 < n and content[i:i+3] == '"""':
                result.append('"""')
                i += 3
                while i < n:
                    if content[i:i+3] == '"""':
                        result.append('"""')
                        i += 3
                        break
                    if content[i] == '\\':
                        result.append(content[i:i+2])
                        i += 2
                    else:
                        result.append(content[i])
                        i += 1
            else:
                result.append(quote)
                i += 1
                while i < n and content[i] != quote:
                    if content[i] == '\\':
                        result.append(content[i:i+2])
                        i += 2
                    elif content[i] == '\n':
                        # Swift strings can't contain unescaped newlines
                        break
                    else:
                        result.append(content[i])
                        i += 1
                if i < n and content[i] == quote:
                    result.append(quote)
                    i += 1
        # Multi-line comments
        elif content[i:i+2] == '/*':
            i += 2
            while i < n and content[i:i+2] != '*/':
                if content[i] == '\n':
                    result.append('\n')
                i += 1
            i += 2  # skip */
        # Single-line comments
        elif content[i:i+2] == '//':
            while i < n and content[i] != '\n':
                i += 1
            if i < n:
                result.append('\n')
                i += 1
        else:
            result.append(content[i])
            i += 1

    return ''.join(result)


def balance(text: str, start: int, open_ch: str, close_ch: str) -> int:
    """Find the index of the delimiter matching the `open_ch` at `start`.

    Clamps to `len(text) - 1` when the source is unbalanced, so callers never
    need to guard against an out-of-range return value.
    """
    depth = 0
    i = start
    n = len(text)
    in_string = False

    while i < n:
        if text[i] == '"' and (i == 0 or text[i-1] != '\\'):
            in_string = not in_string
        elif not in_string:
            if text[i] == open_ch:
                depth += 1
            elif text[i] == close_ch:
                depth -= 1
                if depth == 0:
                    return i
        i += 1

    return n - 1


def compact_whitespace(s: str) -> str:
    """Normalize whitespace in a string."""
    return re.sub(r'\s+', ' ', s).strip()


def normalize_modifiers(decl: str) -> str:
    """Move an access modifier that trails another modifier to the front.

    Swift allows `final public let` as well as `public final let`. Hoisting the
    access keyword to the front lets a single set of front-anchored patterns
    match either ordering.
    """
    tokens = decl.split(' ')
    access_idx = None
    for idx, tok in enumerate(tokens[:4]):
        base = tok.split('(')[0]
        if base in ('public', 'open') and idx != 0:
            # Only hoist when everything before it is another leading modifier.
            leading = ('final', 'static', 'class', 'lazy', 'weak', 'unowned',
                       'convenience', 'required', 'override', 'mutating',
                       'nonmutating', 'indirect')
            if all(tokens[j].split('(')[0] in leading for j in range(idx)):
                access_idx = idx
            break
    if access_idx is not None:
        tok = tokens.pop(access_idx)
        tokens.insert(0, tok)
    return ' '.join(tokens)


def extract_params(decl: str, search_from: int) -> tuple[str, str]:
    """Return (params, trailer) for a paren clause starting at/after search_from.

    `params` is the compacted text between the matched parentheses; `trailer` is
    everything after the closing paren (effects, return type, generics where,
    accessor block).
    """
    paren_start = decl.index('(', search_from)
    paren_end = balance(decl, paren_start, '(', ')')
    params = compact_whitespace(decl[paren_start + 1:paren_end])
    trailer = decl[paren_end + 1:].strip()
    return params, trailer


def trailer_modifiers(trailer: str) -> list[str]:
    """Extract async/throws effect modifiers from a signature trailer."""
    mods = []
    if 'async' in trailer:
        mods.append('async')
    if 'throws' in trailer or 'rethrows' in trailer:
        mods.append('throws')
    return mods


def member_is_public(decl: str, ctx_kind: str, ctx_access: str) -> bool:
    """Compute whether a member declaration is effectively public.

    A member is effectively public when:
      - it has an explicit public/open modifier, OR
      - it has NO explicit access modifier AND its enclosing context makes
        members public-by-default (a protocol body, or a public/open extension).
    A member with an explicit private/fileprivate/internal modifier is never
    public.
    """
    if RE_EXPLICIT_NONPUBLIC.match(decl):
        return False
    if RE_HAS_PUBLIC.search(decl):
        return True
    # No explicit access modifier: public only by virtue of the context.
    if ctx_kind == "protocol":
        return True
    if ctx_kind == "extension" and ctx_access in ("public", "open"):
        return True
    return False


def split_top_level_declarations(body: str) -> List[str]:
    """
    Split class body into top-level declarations.
    Returns list of declaration strings (at brace depth 0).
    """
    declarations = []
    current = []
    depth = 0
    paren_depth = 0
    i = 0
    n = len(body)
    in_string = False

    while i < n:
        ch = body[i]

        # Track string literals
        if ch == '"' and (i == 0 or body[i-1] != '\\'):
            in_string = not in_string
            current.append(ch)
            i += 1
            continue

        if in_string:
            current.append(ch)
            i += 1
            continue

        # Track paren depth so multi-line signatures (parameters spread over
        # several lines) are not split mid-declaration.
        if ch == '(':
            paren_depth += 1
        elif ch == ')':
            if paren_depth > 0:
                paren_depth -= 1

        # Track brace depth
        if ch == '{':
            if depth == 0:
                # This is start of a member body - find matching }
                decl_text = ''.join(current).strip()
                if decl_text:
                    declarations.append(decl_text)
                current = []
                # Skip to end of block
                end = balance(body, i, '{', '}')
                i = end + 1
                continue
            else:
                depth += 1
        elif ch == '}':
            depth -= 1
        elif ch == '\n' and depth == 0 and paren_depth == 0:
            # Check if this line ends a declaration
            line = ''.join(current).strip()
            # Computed properties/getters have { get } on same line
            if line and not line.endswith(',') and '{' not in line:
                # Check if next non-whitespace is not a continuation
                j = i + 1
                while j < n and body[j] in (' ', '\t', '\n'):
                    j += 1
                # If next char starts a new declaration, save current
                if j < n and body[j] in DECL_START_CHARS:
                    if line:
                        declarations.append(line)
                    current = []
                    i += 1
                    continue

        current.append(ch)
        i += 1

    # Process remaining
    remaining = ''.join(current).strip()
    if remaining:
        declarations.append(remaining)

    return declarations


def _render_property(decl: str, m: re.Match) -> str:
    """Render a stored/computed property declaration to a signature string."""
    modifiers = compact_whitespace(m.group(1) or "")
    name = m.group(2)
    type_hint = (m.group(3) or "").strip()

    is_computed = ' { get' in decl or ' { set' in decl or ' { return' in decl

    sig = ""
    if modifiers:
        sig += f"{modifiers} "
    sig += f"var {name}"
    if type_hint:
        sig += f": {type_hint}"
    if is_computed:
        if ' { get' in decl and ' set' in decl:
            sig += " { get set }"
        else:
            sig += " { get }"
    return sig


def extract_type_members(body: str, type_name: str,
                         ctx_kind: str, ctx_access: str) -> MemberInfo:
    """Extract effectively-public members from a type/extension/protocol body."""
    info = MemberInfo(name=type_name)

    declarations = split_top_level_declarations(body)

    for decl in declarations:
        decl = compact_whitespace(decl)

        # Remove attributes
        decl = RE_ATTRIBUTE.sub('', decl).strip()
        if not decl:
            continue

        # --- Enum cases (only meaningful inside an enum body) ---
        if ctx_kind == "enum":
            mc = RE_ENUM_CASE.match(decl)
            if mc:
                # Expand `case a, b, c` into individual entries; keep associated
                # value / raw value detail intact for each.
                raw = mc.group(1).strip()
                for entry in split_case_entries(raw):
                    info.cases.append(f"case {entry}")
                continue

        # Apply the effective-access gate.
        if not member_is_public(decl, ctx_kind, ctx_access):
            continue

        # Normalize leading modifier order (e.g. `final public let`).
        decl = normalize_modifiers(decl)

        # Strip the access keyword (and any setter-access restriction) so the
        # per-kind patterns can anchor on the remaining modifiers.
        decl_no_access = re.sub(r'^' + ACCESS + r'\s+', '', decl)

        # --- Typealias ---
        m = RE_TYPEALIAS.match(decl_no_access)
        if m:
            info.typealiases.append(f"typealias {m.group(1)} = {m.group(2)}")
            continue

        # --- Static/class constants ---
        m = RE_STATIC_CONST.match(decl_no_access)
        if m:
            keyword = m.group(1)
            name = m.group(2)
            type_hint = (m.group(3) or "").strip()
            rhs = (m.group(4) or "").strip()
            sig = f"static {keyword} {name}"
            if type_hint:
                sig += f": {type_hint}"
            elif rhs and len(rhs) <= 40:
                sig += f" = {rhs}"
            info.constants.append(sig)
            continue

        # --- Properties (let/var) ---
        m = RE_PROPERTY.match(decl_no_access)
        if m:
            info.properties.append(_render_property(decl, m))
            continue

        # --- Initializers ---
        m = RE_INIT.match(decl_no_access)
        if m:
            modifiers = compact_whitespace(m.group(1) or "")
            failable = m.group(2) or ""
            # Recover the generics clause (between init?/init and the paren).
            gen_match = re.search(r'init[?!]?\s*(<[^>]+>)?\s*\(', decl_no_access)
            generics = gen_match.group(1) if gen_match and gen_match.group(1) else ""

            params, trailer = extract_params(decl_no_access, m.start())
            mods_after = trailer_modifiers(trailer)

            sig = ""
            if modifiers:
                sig += f"{modifiers} "
            sig += f"init{failable}{generics}({params})"
            if mods_after:
                sig += " " + " ".join(mods_after)
            info.initializers.append(sig)
            continue

        # --- Methods (func) ---
        m = RE_FUNC.match(decl_no_access)
        if m:
            modifiers = compact_whitespace(m.group(1) or "")
            method_name = m.group(2)
            generics = m.group(3) or ""

            params, trailer = extract_params(decl_no_access, m.start())
            # Method effects appear before the return arrow.
            before_arrow = trailer.split('->')[0]
            mods_after = trailer_modifiers(before_arrow)
            return_type = ""
            if '->' in trailer:
                return_type = trailer.split('->', 1)[1].strip()

            sig = ""
            if modifiers:
                sig += f"{modifiers} "
            sig += f"func {method_name}{generics}({params})"
            if mods_after:
                sig += " " + " ".join(mods_after)
            if return_type:
                sig += f" -> {return_type}"
            info.methods.append(sig)
            continue

        # --- Subscripts ---
        m = RE_SUBSCRIPT.match(decl_no_access)
        if m:
            modifiers = compact_whitespace(m.group(1) or "")
            generics = m.group(2) or ""

            params, trailer = extract_params(decl_no_access, m.start())
            return_type = ""
            if '->' in trailer:
                return_type = trailer.split('->', 1)[1].strip()
                return_type = return_type.split('{')[0].strip()

            sig = ""
            if modifiers:
                sig += f"{modifiers} "
            sig += f"subscript{generics}({params})"
            if return_type:
                sig += f" -> {return_type}"
            info.subscripts.append(sig)
            continue

        # --- Nested types ---
        m = RE_NESTED_TYPE.match(decl_no_access)
        if m:
            modifier = (m.group(1) or "").strip()
            kind = m.group(2)
            name = m.group(3)
            sig = ""
            if modifier:
                sig += f"{modifier} "
            sig += f"{kind} {name}"
            info.nested_types.append(sig)
            continue

    return info


def split_case_entries(raw: str) -> List[str]:
    """Split a `case` line's payload into individual case entries.

    Handles `a, b, c` while keeping associated-value tuples and raw-value
    assignments intact (commas inside parentheses are not split points).
    """
    entries = []
    depth = 0
    current = []
    for ch in raw:
        if ch == '(':
            depth += 1
            current.append(ch)
        elif ch == ')':
            depth -= 1
            current.append(ch)
        elif ch == ',' and depth == 0:
            entries.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    tail = ''.join(current).strip()
    if tail:
        entries.append(tail)
    return [e for e in entries if e]


def count_members(info: MemberInfo) -> int:
    """Total number of public members captured for a type."""
    return sum(len(getattr(info, fieldname)) for fieldname in MEMBER_FIELDS)


def merge_extensions(types: List[MemberInfo]) -> List[MemberInfo]:
    """
    Collapse multiple `extension <Type>` blocks on the same extended type into a
    single section. Members are concatenated in stable (first-seen) order and
    de-duplicated. Bare extensions that contribute no public members are dropped
    so they do not emit an empty section. Non-extension types pass through
    unchanged and keep their original relative order.
    """
    result: List[MemberInfo] = []
    ext_by_name: dict[str, MemberInfo] = {}

    for info in types:
        if info.kind != "extension":
            result.append(info)
            continue

        existing = ext_by_name.get(info.name)
        if existing is None:
            # Placeholder kept in output order; emitted only if non-empty.
            merged = MemberInfo(name=info.name, kind="extension", access=info.access)
            ext_by_name[info.name] = merged
            result.append(merged)
            existing = merged

        for fieldname in MEMBER_FIELDS:
            target = getattr(existing, fieldname)
            seen = set(target)
            for item in getattr(info, fieldname):
                if item not in seen:
                    target.append(item)
                    seen.add(item)

    # Drop extensions that ended up with no public members.
    return [info for info in result
            if info.kind != "extension" or count_members(info) > 0]


def parse_swift_file(filepath: Path) -> List[MemberInfo]:
    """Parse a Swift file and extract all public types with their members."""
    content = filepath.read_text(encoding='utf-8', errors='replace')

    # Strip comments
    clean = strip_comments(content)

    results = []

    # Find all type declarations.
    #
    # The leading access modifier is OPTIONAL so that bare `extension Foo { ... }`
    # blocks (the Swift idiom where `public` lives on each member rather than on
    # the extension itself) are captured. Extensions have no access modifier of
    # their own; their public members are filtered at the member level.
    #
    # For every NON-extension kind (class/struct/enum/protocol/actor) the
    # public/open gate is re-enforced below: a declaration that lacks an explicit
    # public/open access modifier is skipped. This keeps the access-control gate
    # for type-level declarations unchanged while letting bare extensions through.
    for m in RE_TYPE_DECL.finditer(clean):
        access = m.group(1)
        modifier = (m.group(2) or "").strip()
        kind = m.group(3)
        type_name = m.group(4)
        inheritance = (m.group(5) or "").strip()

        # Re-enforce the public/open gate for non-extension types. Only an
        # `extension` may appear without a leading public/open modifier.
        if kind != "extension" and not access:
            continue

        # Extract parent/protocols
        protocols = []
        if inheritance:
            inheritance = re.sub(r'^\s*:\s*', '', inheritance).strip()
            protocols = [p.strip() for p in inheritance.split(',')]

        # Find body
        brace_pos = m.end() - 1
        body_end = balance(clean, brace_pos, '{', '}')
        body = clean[brace_pos + 1:body_end]

        # Effective access of the enclosing context.
        #
        # A bare `extension` with no access keyword is INTERNAL, not public, so a
        # member written without an explicit modifier inside it stays internal
        # and must not be recovered by the public-by-default rule. Non-extension
        # kinds reaching this point are already gated to carry an explicit
        # public/open modifier, so defaulting them to "public" is correct.
        if modifier == "open" or access == "open":
            ctx_access = "open"
        elif access == "public":
            ctx_access = "public"
        elif kind == "extension":
            ctx_access = "internal"
        else:
            ctx_access = "public"

        # Parse members with the enclosing context so member-level public-by-
        # default rules (protocol bodies, public extensions) apply.
        info = extract_type_members(body, type_name, kind, ctx_access)
        info.kind = kind
        info.access = ctx_access
        info.protocols = protocols

        results.append(info)

    return results


def format_type_header(info: MemberInfo) -> str:
    """Format the type header line."""
    header = "## "
    # An extension carries no access of its own; never prefix one with an access
    # keyword (a bare extension's internal "access" is an implementation detail
    # used only to gate its members).
    if info.kind != "extension" and info.access and info.access != "public":
        header += f"{info.access} "
    header += f"{info.kind} {info.name}"

    if info.protocols:
        header += f": {', '.join(info.protocols)}"

    return header


def format_type_section(info: MemberInfo) -> str:
    """Format a complete type section for markdown output."""
    lines = [format_type_header(info)]
    for fieldname in MEMBER_FIELDS:
        lines.extend(getattr(info, fieldname))
    lines.append("")  # blank line between types
    return "\n".join(lines)


def main() -> None:
    """Scan the SDK source tree and write the markdown API reference."""
    if not SDK_PATH.exists():
        print(f"ERROR: SDK source not found at {SDK_PATH}", file=sys.stderr)
        print(f"Clone it first: git clone https://github.com/Soneso/stellar-ios-mac-sdk.git {SDK_PATH.parent.parent}", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning Swift files in {SDK_PATH}...", file=sys.stderr)

    # Collect all Swift files, grouped
    groups: dict[str, List[MemberInfo]] = {k: [] for k in GROUP_TITLES}
    stats = {"files": 0, "types": 0, "members": 0, "skipped_dirs": 0, "errors": 0}

    def _skip_dir(name: str) -> bool:
        return name in SKIP_DIRS or name.endswith(SKIP_DIR_SUFFIXES)

    for root, dirs, files in os.walk(SDK_PATH):
        # Prune excluded directories in place, keeping the skipped-count stat.
        stats["skipped_dirs"] += sum(1 for d in dirs if _skip_dir(d))
        dirs[:] = [d for d in dirs if not _skip_dir(d)]

        for fname in sorted(files):
            if not fname.endswith('.swift'):
                continue

            filepath = Path(root) / fname
            rel_path = os.path.relpath(filepath, SDK_PATH)
            group = determine_group(rel_path)

            try:
                types = parse_swift_file(filepath)
                if types:  # Only count files that had types
                    stats["files"] += 1

                for typ in types:
                    groups[group].append(typ)
                    member_count = count_members(typ)
                    if member_count > 0:
                        print(f"  {rel_path}: {typ.name} ({member_count} members)", file=sys.stderr)

            except Exception as e:
                print(f"  ERROR parsing {rel_path}: {e}", file=sys.stderr)
                stats["errors"] += 1

    # Merge extension blocks per type within each group, then sort
    # alphabetically. Merging is done after the full walk so extension blocks
    # split across multiple files collapse into a single section. Stats are
    # tallied from the merged result so they reflect what is emitted.
    for group_key in groups:
        groups[group_key] = merge_extensions(groups[group_key])
        groups[group_key].sort(key=lambda t: t.name)

    for group in groups.values():
        for typ in group:
            stats["types"] += 1
            stats["members"] += count_members(typ)

    # Generate markdown
    parts = [
        "# iOS SDK API Reference (Signatures)\n\n",
        "Compact method signature reference for `stellar-ios-mac-sdk`.\n",
        "Generated by `generate_api_reference.py`. Do not edit manually.\n\n",
        f"**Stats:** {stats['types']} types, {stats['members']} members\n\n",
    ]

    for group_key, title in GROUP_TITLES.items():
        type_list = groups[group_key]
        if not type_list:
            continue

        parts.append("---\n")
        parts.append(f"## {title}\n")
        parts.append("---\n\n")

        for typ in type_list:
            parts.append(format_type_section(typ))

    md = "".join(parts)

    # Write output
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(md, encoding='utf-8')

    # Print stats
    print("\n=== Generation Complete ===", file=sys.stderr)
    print(f"Files processed: {stats['files']}", file=sys.stderr)
    print(f"Types extracted: {stats['types']}", file=sys.stderr)
    print(f"Total members: {stats['members']}", file=sys.stderr)
    print(f"Directories skipped: {stats['skipped_dirs']}", file=sys.stderr)
    print(f"Errors: {stats['errors']}", file=sys.stderr)
    print(f"Output written to: {OUTPUT_PATH}", file=sys.stderr)
    print(f"File size: {OUTPUT_PATH.stat().st_size:,} bytes", file=sys.stderr)

    print("\nAPI reference generated successfully!")

    if stats["errors"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
