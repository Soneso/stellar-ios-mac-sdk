"""Tests of generate_sac_spec.py. They run offline on temporary directories."""

import base64
import contextlib
import hashlib
import http.client
import io
import json
import os
import re
import sys
import tempfile
import unittest
import urllib.error
from unittest import mock

TOOL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(os.path.dirname(TOOL_DIR))
sys.path.insert(0, TOOL_DIR)

import generate_sac_spec  # noqa: E402

SPEC = bytes(range(256)) * 3 + b"spec"
SPEC_SHA256 = hashlib.sha256(SPEC).hexdigest()
COMMIT = "0123456789abcdef0123456789abcdef01234567"
TEMPLATE = (
    "// Generated from {{REPOSITORY}}, {{FILE}}, {{COMMIT}}, {{SIZE}} bytes, {{SHA256}}.\n"
    "commit = \"{{COMMIT}}\"\n"
    "sha256 = \"{{SHA256}}\"\n"
    "base64 = \"{{BASE64}}\"\n"
)
EXPECTED_OUTPUT = (
    "// Generated from example/spec-repo, spec.xdr, " + COMMIT + ", 772 bytes, " + SPEC_SHA256 + ".\n"
    "commit = \"" + COMMIT + "\"\n"
    "sha256 = \"" + SPEC_SHA256 + "\"\n"
    "base64 = \"" + base64.b64encode(SPEC).decode("ascii") + "\"\n"
)


class FakeResponse:
    """The context manager urlopen returns, answering fixed bytes."""

    def __init__(self, body):
        self.body = body

    def __enter__(self):
        return self

    def __exit__(self, *arguments):
        return False

    def read(self):
        return self.body


class CutResponse(FakeResponse):
    """A response whose connection ends in the middle of the body."""

    def read(self):
        raise http.client.IncompleteRead(self.body, 100)


class GeneratorTestCase(unittest.TestCase):

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = directory.name
        os.makedirs(os.path.join(self.root, "templates"))
        os.makedirs(os.path.join(self.root, "out"))
        self.pin_path = os.path.join(self.root, "pin.json")
        self.source_path = os.path.join(self.root, "spec.xdr")
        self.template_path = os.path.join(self.root, "templates", "Spec.template")
        self.output_path = os.path.join(self.root, "out", "Spec.txt")
        self.write_pin()
        self.write(self.source_path, SPEC)
        self.write(self.template_path, TEMPLATE.encode("utf-8"))

    def write(self, path, data):
        with open(path, "wb") as handle:
            handle.write(data)

    def write_pin(self, **changes):
        pin = {
            "repository": "example/spec-repo",
            "commit": COMMIT,
            "file": "spec.xdr",
            "sha256": SPEC_SHA256,
            "template": "templates/Spec.template",
            "output": "out/Spec.txt",
        }
        for key, value in changes.items():
            if value is None:
                del pin[key]
            else:
                pin[key] = value
        self.write(self.pin_path, json.dumps(pin).encode("utf-8"))

    def run_main(self, with_source=True):
        """Runs main on the temporary root; returns the exit status and stderr."""
        argv = ["--pin", self.pin_path, "--root", self.root]
        if with_source:
            argv += ["--source", self.source_path]
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            status = generate_sac_spec.main(argv)
        return status, stderr.getvalue()

    def read_output(self):
        with open(self.output_path, "rb") as handle:
            return handle.read()

    def assert_fails_unwritten(self, status):
        self.assertEqual(status, 1)
        self.assertEqual(os.listdir(os.path.join(self.root, "out")), [])

    def test_matching_digest_fills_every_placeholder(self):
        status, stderr = self.run_main()
        self.assertEqual(status, 0)
        self.assertEqual(stderr, "")
        output = self.read_output()
        self.assertEqual(output, EXPECTED_OUTPUT.encode("utf-8"))
        self.assertNotIn(b"{{", output)
        self.assertEqual(os.listdir(os.path.join(self.root, "out")), ["Spec.txt"])

    def test_two_runs_give_identical_bytes(self):
        self.assertEqual(self.run_main()[0], 0)
        first = self.read_output()
        self.assertEqual(self.run_main()[0], 0)
        self.assertEqual(self.read_output(), first)

    def test_output_has_lf_endings_for_a_crlf_template(self):
        self.write(self.template_path, TEMPLATE.replace("\n", "\r\n").encode("utf-8"))
        self.assertEqual(self.run_main()[0], 0)
        self.assertEqual(self.read_output(), EXPECTED_OUTPUT.encode("utf-8"))

    def test_run_replaces_an_existing_output(self):
        self.write(self.output_path, b"stale")
        self.assertEqual(self.run_main()[0], 0)
        self.assertEqual(self.read_output(), EXPECTED_OUTPUT.encode("utf-8"))

    def test_output_has_the_mode_of_a_new_file(self):
        umask = os.umask(0)
        os.umask(umask)
        self.assertEqual(self.run_main()[0], 0)
        self.assertEqual(os.stat(self.output_path).st_mode & 0o777, 0o666 & ~umask)

    def test_run_gives_an_existing_restricted_output_the_mode_of_a_new_file(self):
        umask = os.umask(0)
        os.umask(umask)
        self.write(self.output_path, b"stale")
        os.chmod(self.output_path, 0o600)
        self.assertEqual(self.run_main()[0], 0)
        self.assertEqual(os.stat(self.output_path).st_mode & 0o777, 0o666 & ~umask)

    def test_mismatched_digest_exits_1_with_both_digests(self):
        pinned = "f" * 64
        self.write_pin(sha256=pinned)
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertEqual(
            stderr,
            "error: sha256 mismatch for spec.xdr: got {}, the pin expects {}\n".format(SPEC_SHA256, pinned))

    def test_mismatched_digest_keeps_an_existing_output(self):
        self.write(self.output_path, b"previous")
        self.write_pin(sha256="f" * 64)
        self.assertEqual(self.run_main()[0], 1)
        self.assertEqual(self.read_output(), b"previous")

    def test_leftover_placeholder_exits_1(self):
        self.write(self.template_path, (TEMPLATE + "{{UNKNOWN}}\n").encode("utf-8"))
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertEqual(
            stderr, "error: the template templates/Spec.template has an unknown placeholder in line 5\n")

    def test_commit_must_be_40_lowercase_hex_characters(self):
        for commit in (COMMIT[:39], COMMIT + "0", COMMIT.upper(), "g" * 40):
            with self.subTest(commit=commit):
                self.write_pin(commit=commit)
                status, stderr = self.run_main()
                self.assert_fails_unwritten(status)
                self.assertIn("needs \"commit\" as 40 lowercase hex characters, got " + commit, stderr)

    def test_sha256_must_be_64_lowercase_hex_characters(self):
        for digest in (SPEC_SHA256[:63], SPEC_SHA256 + "0", SPEC_SHA256.upper(), "g" * 64):
            with self.subTest(sha256=digest):
                self.write_pin(sha256=digest)
                status, stderr = self.run_main()
                self.assert_fails_unwritten(status)
                self.assertIn("needs \"sha256\" as 64 lowercase hex characters, got " + digest, stderr)

    def test_missing_pin_key_exits_1(self):
        for key in generate_sac_spec.PIN_KEYS:
            with self.subTest(key=key):
                self.write_pin(**{key: None})
                status, stderr = self.run_main()
                self.assert_fails_unwritten(status)
                self.assertIn("has no string \"{}\"".format(key), stderr)

    def test_unreadable_pin_exits_1_naming_the_path(self):
        os.remove(self.pin_path)
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertIn("cannot read the pin " + self.pin_path, stderr)

    def test_pin_that_is_not_json_exits_1_naming_the_path(self):
        self.write(self.pin_path, b"not json")
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertIn("cannot read the pin " + self.pin_path, stderr)

    def test_pin_that_is_not_an_object_exits_1(self):
        self.write(self.pin_path, b"[]")
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertEqual(stderr, "error: the pin {} is not a JSON object\n".format(self.pin_path))

    def test_missing_source_exits_1_naming_the_path(self):
        os.remove(self.source_path)
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertIn("cannot read " + self.source_path, stderr)
        self.assertIn("No such file or directory", stderr)

    def test_missing_template_exits_1_naming_the_path(self):
        os.remove(self.template_path)
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertIn("cannot read " + self.template_path, stderr)

    def test_template_that_is_not_utf8_exits_1_naming_the_path(self):
        self.write(self.template_path, b"\xff\xfe")
        status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertIn("cannot read " + self.template_path, stderr)

    def test_missing_output_directory_exits_1_naming_the_path(self):
        os.rmdir(os.path.join(self.root, "out"))
        status, stderr = self.run_main()
        self.assertEqual(status, 1)
        self.assertIn("cannot write " + self.output_path, stderr)
        self.assertFalse(os.path.exists(os.path.join(self.root, "out")))

    def test_failed_replace_removes_the_temporary_file(self):
        with mock.patch.object(generate_sac_spec.os, "replace", side_effect=OSError("replace refused")):
            status, stderr = self.run_main()
        self.assert_fails_unwritten(status)
        self.assertEqual(stderr, "error: cannot write {}: replace refused\n".format(self.output_path))

    def test_download_reads_the_raw_url_of_the_pinned_commit(self):
        with mock.patch.object(generate_sac_spec.urllib.request, "urlopen",
                               return_value=FakeResponse(SPEC)) as urlopen:
            status, _ = self.run_main(with_source=False)
        self.assertEqual(status, 0)
        urlopen.assert_called_once_with(
            "https://raw.githubusercontent.com/example/spec-repo/" + COMMIT + "/spec.xdr", timeout=60)
        self.assertEqual(self.read_output(), EXPECTED_OUTPUT.encode("utf-8"))

    def test_download_error_exits_1_naming_the_url(self):
        with mock.patch.object(generate_sac_spec.urllib.request, "urlopen",
                               side_effect=urllib.error.URLError("no route to host")):
            status, stderr = self.run_main(with_source=False)
        self.assert_fails_unwritten(status)
        self.assertEqual(
            stderr,
            "error: cannot download https://raw.githubusercontent.com/example/spec-repo/" + COMMIT
            + "/spec.xdr: <urlopen error no route to host>\n")

    def test_download_cut_in_the_body_exits_1_naming_the_url(self):
        with mock.patch.object(generate_sac_spec.urllib.request, "urlopen",
                               return_value=CutResponse(SPEC[:10])):
            status, stderr = self.run_main(with_source=False)
        self.assert_fails_unwritten(status)
        self.assertEqual(
            stderr,
            "error: cannot download https://raw.githubusercontent.com/example/spec-repo/" + COMMIT
            + "/spec.xdr: IncompleteRead(10 bytes read, 100 more expected)\n")

    def test_downloaded_bytes_with_another_digest_exit_1(self):
        with mock.patch.object(generate_sac_spec.urllib.request, "urlopen",
                               return_value=FakeResponse(SPEC + b"x")):
            status, stderr = self.run_main(with_source=False)
        self.assert_fails_unwritten(status)
        self.assertIn(hashlib.sha256(SPEC + b"x").hexdigest(), stderr)
        self.assertIn(SPEC_SHA256, stderr)

    def test_defaults_are_the_pin_beside_the_script_and_the_repository_root(self):
        self.assertEqual(generate_sac_spec.default_pin_path(), os.path.join(TOOL_DIR, "pin.json"))
        self.assertEqual(generate_sac_spec.default_root(), REPO_ROOT)


class CommittedOutputTestCase(unittest.TestCase):
    """The committed output matches the committed pin."""

    def setUp(self):
        with open(os.path.join(TOOL_DIR, "pin.json"), "r", encoding="utf-8") as handle:
            self.pin = json.load(handle)
        with open(os.path.join(REPO_ROOT, self.pin["output"]), "r", encoding="utf-8") as handle:
            self.output = handle.read()

    def constant(self, name):
        matches = re.findall(r"public static let " + name + r" = \"([^\"]*)\"", self.output)
        self.assertEqual(len(matches), 1, name)
        return matches[0]

    def test_output_carries_the_pinned_commit_and_sha256(self):
        self.assertEqual(self.constant("UPSTREAM_COMMIT"), self.pin["commit"])
        self.assertEqual(self.constant("SHA256"), self.pin["sha256"])

    def test_base64_has_the_pinned_sha256(self):
        spec = base64.b64decode(self.constant("XDR_BASE64"), validate=True)
        self.assertEqual(hashlib.sha256(spec).hexdigest(), self.pin["sha256"])

    def test_output_has_no_placeholder_and_lf_endings(self):
        self.assertNotIn("{{", self.output)
        with open(os.path.join(REPO_ROOT, self.pin["output"]), "rb") as handle:
            self.assertNotIn(b"\r", handle.read())


if __name__ == "__main__":
    unittest.main()
