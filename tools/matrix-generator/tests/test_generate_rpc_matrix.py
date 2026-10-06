"""Tests for generate_rpc_matrix: cited release, SDK version, response field matching, and failure without output."""

import contextlib
import io
import json
import plistlib
import subprocess
import sys
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "rpc"))

import generate_rpc_matrix  # noqa: E402
import rpc_releases  # noqa: E402
from rpc_releases import ReleaseLookupError  # noqa: E402

from release_fixtures import release_list  # noqa: E402


def write_sdk_root(root: Path, version: str = "3.12.0") -> None:
    """Create the Info.plist the generator reads the SDK version from."""
    plist_dir = root / "stellarsdk" / "stellarsdk"
    plist_dir.mkdir(parents=True)
    with open(plist_dir / "Info.plist", "wb") as f:
        plistlib.dump({"CFBundleShortVersionString": version}, f)


def write_rpc_methods(path: Path, version: str) -> None:
    path.write_text(json.dumps({"metadata": {"version": version}, "methods": {}}))


class FetchRpcVersionTest(unittest.TestCase):

    def test_header_release_is_the_recorded_version_not_the_newest(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            cited = generate_rpc_matrix.fetch_rpc_version({"metadata": {"version": "v28.0.9"}})
        self.assertEqual(cited.tag, "v28.0.9")
        self.assertEqual(cited.published_date, "2026-09-05")
        self.assertEqual(cited.html_url, "https://github.com/stellar/stellar-rpc/releases/tag/v28.0.9")

    def test_recorded_version_absent_from_release_list_raises(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            with self.assertRaisesRegex(ReleaseLookupError, "has no release tagged v26.0.0"):
                generate_rpc_matrix.fetch_rpc_version({"metadata": {"version": "v26.0.0"}})

    def test_recorded_version_that_is_a_draft_raises(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            with self.assertRaisesRegex(ReleaseLookupError, "v31.0.0 is a draft"):
                generate_rpc_matrix.fetch_rpc_version({"metadata": {"version": "v31.0.0"}})

    def test_missing_recorded_version_raises_without_lookup(self):
        lookup = mock.Mock(return_value=release_list())
        with mock.patch.object(rpc_releases, "fetch_releases", lookup):
            for rpc_data in ({}, {"metadata": {}}, {"metadata": {"rpc_version": "v28.0.1"}}, {"metadata": {"version": ""}}):
                with self.subTest(rpc_data=rpc_data):
                    with self.assertRaisesRegex(ValueError, "records no metadata.version"):
                        generate_rpc_matrix.fetch_rpc_version(rpc_data)
        lookup.assert_not_called()


class SdkVersionTest(unittest.TestCase):

    def test_reads_bundle_short_version(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_sdk_root(Path(tmp), "3.12.0")
            self.assertEqual(generate_rpc_matrix.get_sdk_version(Path(tmp)), "3.12.0")

    def test_missing_info_plist_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(ValueError, "Cannot read the SDK version"):
                generate_rpc_matrix.get_sdk_version(Path(tmp))

    def test_unparseable_info_plist_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            plist_dir = Path(tmp) / "stellarsdk" / "stellarsdk"
            plist_dir.mkdir(parents=True)
            (plist_dir / "Info.plist").write_bytes(b"not a plist")
            with self.assertRaisesRegex(ValueError, "Cannot read the SDK version"):
                generate_rpc_matrix.get_sdk_version(Path(tmp))

    def test_info_plist_without_version_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            plist_dir = Path(tmp) / "stellarsdk" / "stellarsdk"
            plist_dir.mkdir(parents=True)
            with open(plist_dir / "Info.plist", "wb") as f:
                plistlib.dump({"CFBundleVersion": "1"}, f)
            with self.assertRaisesRegex(ValueError, "has no CFBundleShortVersionString"):
                generate_rpc_matrix.get_sdk_version(Path(tmp))


class HeaderTest(unittest.TestCase):

    def test_header_lines_come_from_one_release_record(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_sdk_root(root, "3.12.0")
            methods_file = root / "rpc_methods.json"
            write_rpc_methods(methods_file, "v28.0.9")
            output = root / "RPC_COMPATIBILITY_MATRIX.md"

            with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()), \
                    contextlib.redirect_stdout(io.StringIO()):
                generator = generate_rpc_matrix.RPCMatrixGenerator(root, methods_file)
                generator.analyze()
                generator.generate_markdown(output)

            lines = output.read_text().split("\n")
        self.assertEqual(lines[2], "**RPC Version:** v28.0.9 (released 2026-09-05)  ")
        self.assertEqual(lines[3], "**RPC Source:** [v28.0.9](https://github.com/stellar/stellar-rpc/releases/tag/v28.0.9)  ")
        self.assertEqual(lines[4], "**SDK Version:** 3.12.0  ")
        self.assertRegex(lines[5], r"^\*\*Generated:\*\* \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$")


class ResponseFieldMatchingTest(unittest.TestCase):

    def test_field_only_inside_a_nested_type_is_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_sdk_root(root)
            responses = root / "stellarsdk" / "stellarsdk" / "soroban" / "responses"
            responses.mkdir(parents=True)
            (responses.parent / "SorobanServer.swift").write_text(
                "public func getTransaction(transactionHash:String) async -> GetTransactionResponseEnum {}\n"
            )
            (responses / "GetTransactionResponse.swift").write_text(
                "public struct GetTransactionResponse: Decodable {\n"
                "    public let status:String\n"
                "    public let events:TransactionEvents?\n"
                "    private enum CodingKeys: String, CodingKey {\n"
                "        case status\n"
                "        case events\n"
                "    }\n"
                "}\n"
            )
            (responses / "TransactionEvents.swift").write_text(
                "public struct TransactionEvents: Decodable {\n"
                "    private enum CodingKeys: String, CodingKey {\n"
                "        case diagnosticEventsXdr\n"
                "    }\n"
                "}\n"
            )
            methods_file = root / "rpc_methods.json"
            methods_file.write_text(json.dumps({"metadata": {"version": "v28.0.9"}, "methods": {"getTransaction": {
                "parameters": {"required": [{"name": "hash"}], "optional": []},
                "response": {"fields": [{"name": "status"}, {"name": "diagnosticEventsXdr"}]},
            }}}))

            with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()), \
                    contextlib.redirect_stdout(io.StringIO()):
                generator = generate_rpc_matrix.RPCMatrixGenerator(root, methods_file)
                generator.analyze()

        [comparison] = generator.comparisons
        self.assertEqual(comparison.missing_fields, ["diagnosticEventsXdr"])
        self.assertEqual(comparison.status, generate_rpc_matrix.SupportStatus.PARTIALLY_SUPPORTED)


class MainFailureTest(unittest.TestCase):

    def run_main(self):
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = generate_rpc_matrix.main()
        return exit_code, stderr.getvalue()

    def test_release_lookup_request_error_exits_non_zero_and_writes_nothing(self):
        failing = mock.Mock(side_effect=urllib.error.URLError("network unreachable"))
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", failing), \
                mock.patch.object(generate_rpc_matrix, "get_github_token", return_value=None), \
                mock.patch.object(Path, "write_text") as writer:
            exit_code, stderr = self.run_main()
        self.assertEqual(exit_code, 1)
        self.assertIn("network unreachable", stderr)
        failing.assert_called_once()
        writer.assert_not_called()

    def test_unreadable_info_plist_exits_non_zero_and_writes_nothing(self):
        cited = rpc_releases.find_release(release_list(), "stellar/stellar-rpc", "v28.0.10")
        with mock.patch.object(generate_rpc_matrix, "fetch_rpc_version", return_value=cited), \
                mock.patch.object(plistlib, "load", side_effect=plistlib.InvalidFileException()), \
                mock.patch.object(Path, "write_text") as writer:
            exit_code, stderr = self.run_main()
        self.assertEqual(exit_code, 1)
        self.assertIn("Cannot read the SDK version", stderr)
        writer.assert_not_called()


class StandardLibraryOnlyTest(unittest.TestCase):

    def test_generator_imports_without_requests(self):
        rpc_dir = Path(generate_rpc_matrix.__file__).resolve().parent
        code = (
            "import sys; sys.modules['requests'] = None; "
            f"sys.path.insert(0, {str(rpc_dir)!r}); import generate_rpc_matrix"
        )
        result = subprocess.run([sys.executable, "-c", code], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
