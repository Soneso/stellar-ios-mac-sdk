"""Tests for generate_sep_matrix: a run that cannot read the SDK version or a found SDK file writes nothing."""

import contextlib
import io
import logging
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sep"))

import generate_sep_matrix  # noqa: E402

SEP_TEXT = "# SEP-XX\n\n## Simple Summary\n\nA summary.\n"


def write_sdk_root(root: Path, sdk_version, swift_files: dict) -> None:
    """An SDK tree with an Info.plist (none for sdk_version None) and the given Swift files, as bytes."""
    sources = root / "stellarsdk" / "stellarsdk"
    sources.mkdir(parents=True)
    if sdk_version is not None:
        with open(sources / "Info.plist", "wb") as f:
            plistlib.dump({"CFBundleShortVersionString": sdk_version}, f)
    for relative, content in swift_files.items():
        (sources / relative).parent.mkdir(parents=True, exist_ok=True)
        (sources / relative).write_bytes(content)


class FailedRunTest(unittest.TestCase):

    def run_main(self, sep: str, sdk_version, swift_files: dict):
        """Run main() on a temporary SDK tree; return the exit status, whether a matrix exists, the log, the fetch mock."""
        with tempfile.TemporaryDirectory() as tmp:
            sdk_root = Path(tmp) / "sdk"
            write_sdk_root(sdk_root, sdk_version, swift_files)
            output = Path(tmp) / "matrix.md"
            argv = ["generate_sep_matrix.py", "--sep", sep, "--sdk-root", str(sdk_root), "--output", str(output)]
            fetch = mock.Mock(return_value=io.BytesIO(SEP_TEXT.encode("utf-8")))
            with mock.patch.object(sys, "argv", argv), mock.patch.object(generate_sep_matrix, "urlopen", fetch), \
                    contextlib.redirect_stdout(io.StringIO()), \
                    self.assertLogs(generate_sep_matrix.logger, logging.ERROR) as logs:
                status = generate_sep_matrix.main()
            return status, output.exists(), "\n".join(logs.output), fetch

    def test_unreadable_sdk_version_exits_non_zero_before_any_request(self):
        for case, sdk_version in (("no Info.plist", None), ("empty version", " ")):
            with self.subTest(case):
                status, written, log, fetch = self.run_main("02", sdk_version, {})
                self.assertEqual(status, 1)
                self.assertFalse(written)
                self.assertIn("Info.plist", log)
                fetch.assert_not_called()

    def test_unreadable_sdk_file_exits_non_zero_naming_it(self):
        runs = {
            "file read by the class search": ("02", "federation/Federation.swift"),
            "file read from a source directory": ("51", "xdr_json/XdrJson.swift"),
        }
        for case, (sep, relative) in runs.items():
            with self.subTest(case):
                status, written, log, _ = self.run_main(sep, "3.12.0", {relative: b"\xff\xfe not utf-8"})
                self.assertEqual(status, 1)
                self.assertFalse(written)
                self.assertRegex(log, f"Cannot read .*{relative}")


if __name__ == "__main__":
    unittest.main()
