#!/usr/bin/env python3
"""Embeds a pinned Stellar Asset Contract spec file into a source file.

The pin names the upstream repository, the commit, the file, and the sha256 of
that file, together with the template to fill and the output to write. The
script reads the spec bytes (from --source, or from the raw URL of the pinned
commit), checks them against the pinned sha256, fills the template, and
replaces the output file. The output carries no timestamp, so a run at the
same pin reproduces it byte for byte.

Usage:
    python3 tools/sac-spec/generate_sac_spec.py [--pin PATH] [--root DIR] [--source FILE]

Exit status: 0 after the output is written, 1 on any error, with nothing written.
"""

import argparse
import base64
import hashlib
import http.client
import json
import os
import re
import secrets
import sys
import urllib.request

RAW_URL = "https://raw.githubusercontent.com/{repository}/{commit}/{file}"
DOWNLOAD_TIMEOUT_SECONDS = 60
PIN_KEYS = ("repository", "commit", "file", "sha256", "template", "output")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
PLACEHOLDER_OPENING = "{{"


class GeneratorError(Exception):
    """An error that ends the run with exit status 1 and its message on stderr."""


def default_pin_path():
    """The pin beside this script."""
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "pin.json")


def default_root():
    """The repository root, two directories above this script."""
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_pin(path):
    """Reads and validates the pin; every key is a non-empty string."""
    try:
        with open(path, "r", encoding="utf-8") as handle:
            pin = json.load(handle)
    except (OSError, ValueError) as error:
        raise GeneratorError("cannot read the pin {}: {}".format(path, error))
    if not isinstance(pin, dict):
        raise GeneratorError("the pin {} is not a JSON object".format(path))
    for key in PIN_KEYS:
        value = pin.get(key)
        if not isinstance(value, str) or not value:
            raise GeneratorError("the pin {} has no string \"{}\"".format(path, key))
    if not COMMIT_PATTERN.fullmatch(pin["commit"]):
        raise GeneratorError(
            "the pin {} needs \"commit\" as 40 lowercase hex characters, got {}".format(path, pin["commit"]))
    if not SHA256_PATTERN.fullmatch(pin["sha256"]):
        raise GeneratorError(
            "the pin {} needs \"sha256\" as 64 lowercase hex characters, got {}".format(path, pin["sha256"]))
    return pin


def read_file(path):
    """The bytes of the file at `path`."""
    try:
        with open(path, "rb") as handle:
            return handle.read()
    except OSError as error:
        raise GeneratorError("cannot read {}: {}".format(path, error))


def download(url):
    """The bytes the server answers for `url`."""
    try:
        with urllib.request.urlopen(url, timeout=DOWNLOAD_TIMEOUT_SECONDS) as response:
            return response.read()
    except (OSError, ValueError, http.client.HTTPException) as error:
        raise GeneratorError("cannot download {}: {}".format(url, error))


def render(template, pin, spec):
    """The template with every placeholder filled from the pin and the spec bytes."""
    values = {
        "{{REPOSITORY}}": pin["repository"],
        "{{FILE}}": pin["file"],
        "{{COMMIT}}": pin["commit"],
        "{{SHA256}}": pin["sha256"],
        "{{SIZE}}": str(len(spec)),
        "{{BASE64}}": base64.b64encode(spec).decode("ascii"),
    }
    rendered = template.replace("\r\n", "\n")
    for placeholder, value in values.items():
        rendered = rendered.replace(placeholder, value)
    if PLACEHOLDER_OPENING in rendered:
        line = rendered[:rendered.index(PLACEHOLDER_OPENING)].count("\n") + 1
        raise GeneratorError(
            "the template {} has an unknown placeholder in line {}".format(pin["template"], line))
    return rendered


def write_output(path, text):
    """Replaces the file at `path` with `text` through a temporary file beside it.

    The temporary file is created exclusively with mode 0o666, which the system masks with
    the process umask, so the output has the mode of any newly created file.
    """
    temporary = os.path.join(os.path.dirname(path), ".sac-spec-{}.tmp".format(secrets.token_hex(8)))
    created = False
    try:
        descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o666)
        created = True
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(text.encode("utf-8"))
        os.replace(temporary, path)
    except OSError as error:
        if created and os.path.exists(temporary):
            os.remove(temporary)
        raise GeneratorError("cannot write {}: {}".format(path, error))


def generate(pin_path, root, source):
    """Runs the generator and returns the path of the written output."""
    pin = load_pin(pin_path)
    if source is not None:
        spec = read_file(source)
    else:
        spec = download(RAW_URL.format(repository=pin["repository"], commit=pin["commit"], file=pin["file"]))
    digest = hashlib.sha256(spec).hexdigest()
    if digest != pin["sha256"]:
        raise GeneratorError(
            "sha256 mismatch for {}: got {}, the pin expects {}".format(pin["file"], digest, pin["sha256"]))
    template_path = os.path.join(root, pin["template"])
    try:
        template = read_file(template_path).decode("utf-8")
    except UnicodeDecodeError as error:
        raise GeneratorError("cannot read {}: {}".format(template_path, error))
    output_path = os.path.join(root, pin["output"])
    write_output(output_path, render(template, pin, spec))
    return output_path


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Embed the pinned Stellar Asset Contract spec into the output the pin names.")
    parser.add_argument("--pin", default=default_pin_path(),
                        help="the pin file (default: pin.json beside this script)")
    parser.add_argument("--root", default=default_root(),
                        help="the directory the pin's template and output paths resolve against "
                             "(default: two directories above this script)")
    parser.add_argument("--source",
                        help="a local copy of the spec file, read in place of the download")
    arguments = parser.parse_args(argv)
    try:
        output_path = generate(arguments.pin, arguments.root, arguments.source)
    except GeneratorError as error:
        print("error: {}".format(error), file=sys.stderr)
        return 1
    print("wrote {}".format(output_path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
