"""Tests for extract_rpc_methods: release lookups and failure on any missing method definition."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
import urllib.error
import warnings
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "rpc"))

with warnings.catch_warnings():
    # requests warns about its urllib3/chardet versions on import on some machines.
    warnings.simplefilter("ignore")
    import requests  # noqa: E402

import extract_rpc_methods  # noqa: E402
import rpc_releases  # noqa: E402
from extract_rpc_methods import (  # noqa: E402
    KNOWN_METHODS,
    GitHubFetcher,
    GoSourceParser,
    NotFoundError,
    RPCMethodExtractor,
    check_method_set,
)
from rpc_releases import ReleaseLookupError  # noqa: E402

from release_fixtures import FakeResponse, FakeUrlopen, release, release_list  # noqa: E402

HANDLER_SOURCE = "package methods\n"


def pascal(method_name: str) -> str:
    return method_name[0].upper() + method_name[1:]


def protocol_source(method_name: str) -> str:
    """A go-stellar-sdk protocol file declaring the method's request and response structs."""
    name = pascal(method_name)
    return (
        f"type {name}Request struct {{\n\tStartLedger uint32 `json:\"startLedger\"`\n}}\n\n"
        f"type {name}Response struct {{\n\tLatestLedger uint32 `json:\"latestLedger\"`\n}}\n"
    )


def registration_source(method_names) -> str:
    """A stellar-rpc jsonrpc.go handler table registering the given methods, in the v28.0.1 layout."""
    entries = "".join(
        "\t\t{\n"
        f"\t\t\tmethodName:{' ' if index % 2 else '           '}protocol.{pascal(name)}MethodName,\n"
        f"\t\t\tunderlyingHandler:    methods.New{pascal(name)}Handler(params.Logger),\n"
        f"\t\t\tlongName:             toSnakeCase(protocol.{pascal(name)}MethodName),\n"
        "\t\t},\n"
        for index, name in enumerate(method_names)
    )
    return ("package internal\n\nfunc NewJSONRPCHandler() {\n\thandlers := []struct {\n"
            "\t\tmethodName string\n\t}{\n" + entries + "\t}\n}\n")


def literal_registration_source(method_names) -> str:
    """A jsonrpc.go handler table in the string-literal layout of stellar-rpc releases up to v22.1.1."""
    entries = "".join(f'\t\t{{\n\t\t\tmethodName: "{name}",\n\t\t}},\n' for name in method_names)
    return ("package internal\n\nfunc NewJSONRPCHandler() {\n\thandlers := []struct {\n"
            "\t\tmethodName string\n\t}{\n" + entries + "\t}\n}\n")


class FakeGitHub:
    """
    Replaces the extractor's network access: release lists, handler files, the
    stellar-rpc protocol directory, and go-stellar-sdk protocol files.
    """

    def __init__(self, rpc_releases_list=None, go_releases_list=None):
        self.rpc_releases = rpc_releases_list if rpc_releases_list is not None else release_list()
        self.go_releases = go_releases_list if go_releases_list is not None else [
            release("horizonclient-v24.0.0", repo="stellar/go-stellar-sdk"),
            release("v0.7.3", "2026-08-24T10:00:00Z", repo="stellar/go-stellar-sdk"),
            release("v0.7.2", "2026-08-01T10:00:00Z", repo="stellar/go-stellar-sdk"),
        ]
        self.handler_errors = {}
        self.fetched_handlers = []
        self.refs_by_path = {}
        self.protocol_refs = []
        self.registrations = list(KNOWN_METHODS)
        self.registration_dir = "cmd/stellar-rpc/internal"
        self.registration_layout = registration_source

    def fetch_releases(self, owner, repo, token):
        return {"stellar-rpc": self.rpc_releases, "go-stellar-sdk": self.go_releases}[repo]

    def fetch_file(self, file_path, ref):
        self.fetched_handlers.append(file_path)
        self.refs_by_path[file_path] = ref
        if file_path in self.handler_errors:
            raise self.handler_errors[file_path]
        if self.registration_dir and file_path == f"{self.registration_dir}/jsonrpc.go":
            return self.registration_layout(self.registrations)
        if file_path.startswith("cmd/stellar-rpc/internal/methods/") and not file_path.endswith("/health.go"):
            return HANDLER_SOURCE
        raise NotFoundError(f"{file_path} does not exist at {ref}")

    def list_directory(self, dir_path, ref):
        raise NotFoundError(f"{dir_path} does not exist at {ref}")

    def fetch_go_stellar_sdk_protocol_file(self, method_name, ref):
        self.protocol_refs.append(ref)
        return protocol_source(method_name)

    @contextlib.contextmanager
    def installed(self, fake_release_lists=True):
        """Patch the fetcher; with fake_release_lists False, release lists go through the real fetch_releases."""
        with contextlib.ExitStack() as stack:
            no_checkout = stack.enter_context(tempfile.TemporaryDirectory())
            stack.enter_context(mock.patch.object(extract_rpc_methods, "GO_STELLAR_SDK_PATH", Path(no_checkout) / "absent"))
            if fake_release_lists:
                stack.enter_context(mock.patch.object(extract_rpc_methods, "fetch_releases", self.fetch_releases))
            stack.enter_context(mock.patch.object(GitHubFetcher, "fetch_file",
                                                  lambda _self, path, ref: self.fetch_file(path, ref)))
            stack.enter_context(mock.patch.object(GitHubFetcher, "list_directory",
                                                  lambda _self, path, ref: self.list_directory(path, ref)))
            stack.enter_context(mock.patch.object(GitHubFetcher, "fetch_go_stellar_sdk_protocol_file",
                                                  lambda _self, method, ref: self.fetch_go_stellar_sdk_protocol_file(method, ref)))
            yield


def run_main(argv):
    stdout, stderr = io.StringIO(), io.StringIO()
    with mock.patch.object(sys, "argv", ["extract_rpc_methods.py", *argv]), \
            contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
        exit_code = extract_rpc_methods.main()
    return exit_code, stdout.getvalue(), stderr.getvalue()


class ReleaseLookupTest(unittest.TestCase):

    def fetcher(self):
        return GitHubFetcher(token="test-token")

    def test_rpc_default_is_newest_stable(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=release_list()):
            self.assertEqual(self.fetcher().resolve_rpc_version(None), "v28.0.10")

    def test_rpc_override_present(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=release_list()):
            self.assertEqual(self.fetcher().resolve_rpc_version("v28.0.9"), "v28.0.9")

    def test_rpc_prerelease_override_is_allowed(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=release_list()), \
                contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(self.fetcher().resolve_rpc_version("v29.0.0-rc.1"), "v29.0.0-rc.1")
        self.assertIn("v29.0.0-rc.1 is a prerelease", out.getvalue())

    def test_rpc_override_absent_raises(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=release_list()):
            with self.assertRaisesRegex(ReleaseLookupError, "has no release with tag v26.0.0"):
                self.fetcher().resolve_rpc_version("v26.0.0")

    def test_rpc_override_pointing_at_draft_raises(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=release_list()):
            with self.assertRaisesRegex(ReleaseLookupError, "v31.0.0 is a draft"):
                self.fetcher().resolve_rpc_version("v31.0.0")

    def test_go_stellar_sdk_selection_uses_the_same_rule(self):
        go_list = release_list(repo="stellar/go-stellar-sdk")
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=go_list) as lookup:
            self.assertEqual(self.fetcher().get_latest_go_stellar_sdk_release(), "v28.0.10")
        lookup.assert_called_once_with("stellar", "go-stellar-sdk", "test-token")

    def test_go_stellar_sdk_selection_follows_pagination(self):
        first = "https://api.github.com/repos/stellar/go-stellar-sdk/releases?per_page=100"
        second = "https://api.github.com/repositories/2/releases?per_page=100&page=2"
        fake = FakeUrlopen({
            first: FakeResponse(release_list(repo="stellar/go-stellar-sdk"), link=f'<{second}>; rel="next"'),
            second: FakeResponse([release("v28.1.0", "2026-09-25T10:00:00Z", repo="stellar/go-stellar-sdk")]),
        })
        with mock.patch.object(rpc_releases.urllib.request, "urlopen", fake):
            self.assertEqual(self.fetcher().get_latest_go_stellar_sdk_release(), "v28.1.0")
        self.assertEqual(fake.urls, [first, second])

    def test_rpc_lookup_failure_raises(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases",
                               side_effect=ReleaseLookupError("GET failed: HTTP 502 Bad Gateway")):
            with self.assertRaisesRegex(ReleaseLookupError, "HTTP 502"):
                self.fetcher().resolve_rpc_version(None)

    def test_go_stellar_sdk_lookup_failure_raises(self):
        with mock.patch.object(extract_rpc_methods, "fetch_releases",
                               side_effect=ReleaseLookupError("GET failed: HTTP 502 Bad Gateway")):
            with self.assertRaisesRegex(ReleaseLookupError, "HTTP 502"):
                self.fetcher().get_latest_go_stellar_sdk_release()

    def test_go_stellar_sdk_without_stable_release_raises(self):
        go_list = [release("v0.8.0-rc.1", prerelease=True, repo="stellar/go-stellar-sdk")]
        with mock.patch.object(extract_rpc_methods, "fetch_releases", return_value=go_list):
            with self.assertRaisesRegex(ReleaseLookupError, "stellar/go-stellar-sdk has no stable release"):
                self.fetcher().get_latest_go_stellar_sdk_release()


class ExtractorMainTest(unittest.TestCase):

    def test_full_set_writes_json_citing_selected_releases(self):
        fake = FakeGitHub()
        with tempfile.TemporaryDirectory() as tmp, fake.installed():
            output = Path(tmp) / "rpc_methods.json"
            exit_code, _, stderr = run_main(["--output", str(output)])
            self.assertEqual(exit_code, 0, stderr)
            data = json.loads(output.read_text())

        self.assertEqual(set(data["methods"]), set(KNOWN_METHODS))
        self.assertEqual(data["metadata"]["version"], "v28.0.10")
        self.assertEqual(data["metadata"]["total_methods"], 12)
        self.assertEqual(data["metadata"]["protocol_definitions"],
                         "https://github.com/stellar/go-stellar-sdk/tree/v0.7.3/protocols/rpc")
        self.assertEqual(set(fake.protocol_refs), {"v0.7.3"})
        self.assertEqual(fake.refs_by_path["cmd/stellar-rpc/internal/jsonrpc.go"], "v28.0.10")
        for name, method in data["methods"].items():
            with self.subTest(method=name):
                self.assertNotIn("notes", method)
                self.assertEqual([p["name"] for p in method["parameters"]["required"]], ["startLedger"])
                self.assertEqual([f["name"] for f in method["response"]["fields"]], ["latestLedger"])

    def test_one_handler_fetch_failing_exits_non_zero_and_writes_no_json(self):
        fake = FakeGitHub()
        fake.handler_errors["cmd/stellar-rpc/internal/methods/get_ledgers.go"] = RuntimeError(
            "Failed to fetch cmd/stellar-rpc/internal/methods/get_ledgers.go: 502 Server Error")
        with tempfile.TemporaryDirectory() as tmp, fake.installed():
            output = Path(tmp) / "rpc_methods.json"
            exit_code, _, stderr = run_main(["--output", str(output)])
            self.assertFalse(output.exists())
        self.assertEqual(exit_code, 1)
        self.assertIn("Failed to extract getLedgers", stderr)

    def test_handler_absent_at_every_candidate_path_raises_naming_the_method(self):
        fake = FakeGitHub()
        fake.handler_errors["cmd/stellar-rpc/internal/methods/get_events.go"] = NotFoundError("absent")
        with fake.installed():
            with self.assertRaisesRegex(RuntimeError, "Failed to extract getEvents: No handler file at v28.0.10"):
                RPCMethodExtractor(github_token="t").extract()

    def test_request_error_on_a_candidate_path_raises_without_trying_the_next(self):
        fake = FakeGitHub()
        fake.handler_errors["cmd/stellar-rpc/internal/methods/get_health.go"] = RuntimeError("503 Service Unavailable")
        with fake.installed():
            with self.assertRaisesRegex(RuntimeError, "Failed to extract getHealth: 503 Service Unavailable"):
                RPCMethodExtractor(github_token="t").extract()
        self.assertNotIn("cmd/soroban-rpc/internal/methods/get_health.go", fake.fetched_handlers)

    def test_handler_found_at_a_later_candidate_path(self):
        fake = FakeGitHub()
        fake.handler_errors["cmd/stellar-rpc/internal/methods/get_health.go"] = NotFoundError("absent")
        original = fake.fetch_file

        def fetch_file(file_path, ref):
            if file_path == "cmd/stellar-rpc/internal/methods/health.go":
                fake.fetched_handlers.append(file_path)
                return HANDLER_SOURCE
            return original(file_path, ref)

        fake.fetch_file = fetch_file
        with fake.installed():
            data = RPCMethodExtractor(github_token="t").extract()
        self.assertEqual(data["methods"]["getHealth"]["handler_file"], "cmd/stellar-rpc/internal/methods/health.go")

    def test_rpc_release_request_error_exits_non_zero_and_writes_no_json(self):
        fake = FakeGitHub()
        failing = mock.Mock(side_effect=urllib.error.URLError("network unreachable"))
        with tempfile.TemporaryDirectory() as tmp, fake.installed(fake_release_lists=False), \
                mock.patch.object(rpc_releases.urllib.request, "urlopen", failing):
            output = Path(tmp) / "rpc_methods.json"
            exit_code, _, stderr = run_main(["--output", str(output)])
            self.assertFalse(output.exists())
        self.assertEqual(exit_code, 1)
        self.assertIn("repos/stellar/stellar-rpc/releases", stderr)
        self.assertIn("network unreachable", stderr)
        self.assertEqual(fake.fetched_handlers, [])

    def run_extractor(self, fake):
        """Run main() against the fake; return exit code, whether JSON was written, and stderr."""
        with tempfile.TemporaryDirectory() as tmp, fake.installed():
            output = Path(tmp) / "rpc_methods.json"
            exit_code, _, stderr = run_main(["--output", str(output)])
            return exit_code, output.exists(), stderr

    def test_upstream_registration_added_exits_non_zero_naming_it(self):
        fake = FakeGitHub()
        fake.registrations = [*KNOWN_METHODS, "queryEvents"]
        exit_code, written, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertFalse(written)
        self.assertIn("extra: queryEvents", stderr)

    def test_upstream_registration_removed_exits_non_zero_naming_it(self):
        fake = FakeGitHub()
        fake.registrations = [name for name in KNOWN_METHODS if name != "getFeeStats"]
        exit_code, written, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertFalse(written)
        self.assertIn("missing: getFeeStats", stderr)

    def test_registration_file_absent_at_every_directory_exits_non_zero(self):
        fake = FakeGitHub()
        fake.registration_dir = None
        exit_code, written, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertFalse(written)
        self.assertIn("No jsonrpc.go registration file at v28.0.10", stderr)
        self.assertIn("cmd/stellar-rpc/internal/jsonrpc.go", fake.fetched_handlers)
        self.assertIn("cmd/soroban-rpc/internal/jsonrpc.go", fake.fetched_handlers)

    def test_registration_file_in_string_literal_layout_exits_non_zero_naming_the_cause(self):
        fake = FakeGitHub()
        fake.registration_layout = literal_registration_source
        exit_code, written, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertFalse(written)
        self.assertIn("No protocol.<Name>MethodName registrations found in jsonrpc.go at v28.0.10", stderr)

    def test_registration_file_in_legacy_directory_is_used(self):
        fake = FakeGitHub()
        fake.registration_dir = "cmd/soroban-rpc/internal"
        exit_code, written, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 0, stderr)
        self.assertTrue(written)
        self.assertEqual(fake.refs_by_path["cmd/soroban-rpc/internal/jsonrpc.go"], "v28.0.10")

    def test_registration_request_error_raises_without_trying_the_next_directory(self):
        fake = FakeGitHub()
        fake.handler_errors["cmd/stellar-rpc/internal/jsonrpc.go"] = RuntimeError("502 Bad Gateway")
        exit_code, written, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertFalse(written)
        self.assertIn("502 Bad Gateway", stderr)
        self.assertNotIn("cmd/soroban-rpc/internal/jsonrpc.go", fake.fetched_handlers)

    def test_release_lookup_failure_exits_non_zero_and_writes_no_json(self):
        fake = FakeGitHub(rpc_releases_list=[])
        with tempfile.TemporaryDirectory() as tmp, fake.installed():
            output = Path(tmp) / "rpc_methods.json"
            exit_code, _, stderr = run_main(["--output", str(output)])
            self.assertFalse(output.exists())
        self.assertEqual(exit_code, 1)
        self.assertIn("stellar/stellar-rpc has no stable release", stderr)


class GoStellarSdkProtocolFileTest(unittest.TestCase):

    def test_request_error_raises(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", side_effect=requests.ConnectionError("connection reset")):
            with self.assertRaisesRegex(RuntimeError, "get_ledgers.go at v0.7.3: connection reset"):
                fetcher.fetch_go_stellar_sdk_protocol_file("getLedgers", "v0.7.3")

    def test_http_error_raises(self):
        fetcher = GitHubFetcher(token="t")
        response = mock.Mock(status_code=404)
        response.raise_for_status.side_effect = requests.HTTPError("404 Client Error: Not Found")
        with mock.patch.object(fetcher.session, "get", return_value=response):
            with self.assertRaisesRegex(RuntimeError, "404 Client Error"):
                fetcher.fetch_go_stellar_sdk_protocol_file("getLedgers", "v0.7.3")

    def test_unmapped_method_raises(self):
        fetcher = GitHubFetcher(token="t")
        with self.assertRaisesRegex(ValueError, "No go-stellar-sdk protocol file is mapped for queryEvents"):
            fetcher.fetch_go_stellar_sdk_protocol_file("queryEvents", "v0.7.3")

    def test_fetches_from_the_given_ref(self):
        fetcher = GitHubFetcher(token="t")
        response = mock.Mock(status_code=200, text="package protocol\n")
        with mock.patch.object(fetcher.session, "get", return_value=response) as get:
            self.assertEqual(fetcher.fetch_go_stellar_sdk_protocol_file("getLedgers", "v0.7.3"), "package protocol\n")
        self.assertEqual(get.call_args.args[0],
                         "https://raw.githubusercontent.com/stellar/go-stellar-sdk/v0.7.3/protocols/rpc/get_ledgers.go")


class GitHubFetcherNotFoundTest(unittest.TestCase):

    def response(self, status_code, body=None):
        response = mock.Mock(status_code=status_code, text="package methods\n")
        response.json.return_value = body
        if status_code >= 400:
            response.raise_for_status.side_effect = requests.HTTPError(f"{status_code} Error")
        return response

    def test_fetch_file_404_raises_not_found(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(404)):
            with self.assertRaisesRegex(NotFoundError, "get_health.go does not exist at v28.0.1"):
                fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go", "v28.0.1")

    def test_fetch_file_server_error_is_not_a_not_found(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(502)):
            with self.assertRaises(RuntimeError) as raised:
                fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go", "v28.0.1")
        self.assertNotIsInstance(raised.exception, NotFoundError)

    def test_list_directory_404_raises_not_found(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(404)):
            with self.assertRaisesRegex(NotFoundError, "protocol does not exist at v28.0.1"):
                fetcher.list_directory("protocol", "v28.0.1")

    def test_list_directory_rate_limit_is_not_a_not_found(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(403)):
            with self.assertRaises(RuntimeError) as raised:
                fetcher.list_directory("protocol", "v24.0.0")
        self.assertNotIsInstance(raised.exception, NotFoundError)

    def test_requests_use_the_given_ref(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(200, [])) as get:
            fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go", "v28.0.1")
            fetcher.list_directory("protocol", "v24.0.0")
        self.assertEqual([c.args[0] for c in get.call_args_list], [
            "https://raw.githubusercontent.com/stellar/stellar-rpc/v28.0.1/cmd/stellar-rpc/internal/methods/get_health.go",
            "https://api.github.com/repos/stellar/stellar-rpc/contents/protocol?ref=v24.0.0",
        ])

    def test_ref_is_required(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get") as get:
            with self.assertRaises(TypeError):
                fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go")
            with self.assertRaises(TypeError):
                fetcher.list_directory("protocol")
        get.assert_not_called()

    def test_list_directory_that_is_not_a_list_raises(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(200, {"type": "file"})):
            with self.assertRaisesRegex(RuntimeError, "listing of protocol is not a list"):
                fetcher.list_directory("protocol", "v24.0.0")


class FetchProtocolFilesTest(unittest.TestCase):

    def extractor(self):
        with tempfile.TemporaryDirectory() as no_checkout, \
                mock.patch.object(extract_rpc_methods, "GO_STELLAR_SDK_PATH", Path(no_checkout) / "absent"):
            return RPCMethodExtractor(github_token="t")

    def test_directory_absent_at_the_ref_leaves_no_protocol_source(self):
        extractor = self.extractor()
        with mock.patch.object(extractor.fetcher, "list_directory", side_effect=NotFoundError("absent")) as listing:
            extractor._fetch_protocol_files("v28.0.1")
        listing.assert_called_once_with("protocol", "v28.0.1")
        self.assertIsNone(extractor.parser.protocol_source)

    def test_listing_request_error_raises(self):
        extractor = self.extractor()
        with mock.patch.object(extractor.fetcher, "list_directory",
                               side_effect=RuntimeError("Failed to list directory protocol: 403 rate limit")):
            with self.assertRaisesRegex(RuntimeError, "403 rate limit"):
                extractor._fetch_protocol_files("v24.0.0")

    def test_file_fetch_error_in_a_listed_directory_raises(self):
        extractor = self.extractor()
        listing = [{"type": "file", "name": "get_events.go"}, {"type": "file", "name": "get_ledgers.go"}]
        with mock.patch.object(extractor.fetcher, "list_directory", return_value=listing), \
                mock.patch.object(extractor.fetcher, "fetch_file",
                                  side_effect=["package protocol\n", RuntimeError("Failed to fetch protocol/get_ledgers.go")]):
            with self.assertRaisesRegex(RuntimeError, "protocol/get_ledgers.go"):
                extractor._fetch_protocol_files("v24.0.0")

    def test_listed_directory_sources_are_loaded(self):
        extractor = self.extractor()
        listing = [{"type": "file", "name": "a.go"}, {"type": "dir", "name": "sub"}, {"type": "file", "name": "b.go"}]
        with mock.patch.object(extractor.fetcher, "list_directory", return_value=listing) as list_directory, \
                mock.patch.object(extractor.fetcher, "fetch_file", side_effect=["// a\n", "// b\n"]) as fetch_file:
            extractor._fetch_protocol_files("v24.0.0")
        list_directory.assert_called_once_with("protocol", "v24.0.0")
        self.assertEqual([c.args for c in fetch_file.call_args_list],
                         [("protocol/a.go", "v24.0.0"), ("protocol/b.go", "v24.0.0")])
        self.assertIn("// a\n", extractor.parser.protocol_source)
        self.assertIn("// b\n", extractor.parser.protocol_source)


class DefinitionParsingTest(unittest.TestCase):

    def test_response_struct_not_found_in_any_source_raises_naming_the_method(self):
        parser = GoSourceParser(go_stellar_sdk_path=None)
        parser.set_protocol_source("type GetLedgersRequest struct {\n\tStartLedger uint32 `json:\"startLedger\"`\n}\n")
        with self.assertRaisesRegex(ValueError, "Response struct .* for getLedgers not found"):
            parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_response_struct_not_found_with_local_checkout_raises(self):
        with tempfile.TemporaryDirectory() as checkout:
            protocol_dir = Path(checkout) / "protocols" / "rpc"
            protocol_dir.mkdir(parents=True)
            (protocol_dir / "get_health.go").write_text(protocol_source("getHealth"))
            parser = GoSourceParser(go_stellar_sdk_path=Path(checkout))
            parser.set_protocol_source("type GetLedgersRequest struct{}\n")
            with self.assertRaisesRegex(ValueError, "for getLedgers not found in the local go-stellar-sdk checkout"):
                parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_response_struct_from_local_checkout_is_used(self):
        with tempfile.TemporaryDirectory() as checkout:
            protocol_dir = Path(checkout) / "protocols" / "rpc"
            protocol_dir.mkdir(parents=True)
            (protocol_dir / "get_ledgers.go").write_text(protocol_source("getLedgers"))
            parser = GoSourceParser(go_stellar_sdk_path=Path(checkout))
            parser.set_protocol_source("type GetLedgersRequest struct{}\n")
            spec = parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")
        self.assertEqual([f["name"] for f in spec.response["fields"]], ["latestLedger"])

    def test_unreadable_local_protocol_file_raises(self):
        with tempfile.TemporaryDirectory() as checkout:
            protocol_dir = Path(checkout) / "protocols" / "rpc"
            protocol_dir.mkdir(parents=True)
            (protocol_dir / "get_ledgers.go").write_bytes(b"\xff\xfe not utf-8")
            with self.assertRaisesRegex(RuntimeError, "Failed to read local protocol file .*get_ledgers.go"):
                GoSourceParser(go_stellar_sdk_path=Path(checkout))

    def test_response_struct_without_json_fields_raises(self):
        parser = GoSourceParser(go_stellar_sdk_path=None)
        parser.set_protocol_source(
            "type GetLedgersRequest struct{}\n\ntype GetLedgersResponse struct {\n\tinternal uint32\n}\n")
        with self.assertRaisesRegex(ValueError, "GetLedgersResponse for getLedgers has no JSON fields"):
            parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_request_struct_not_found_raises_naming_the_method(self):
        parser = GoSourceParser(go_stellar_sdk_path=None)
        parser.set_protocol_source(
            "type GetLedgersResponse struct {\n\tLatestLedger uint32 `json:\"latestLedger\"`\n}\n")
        with self.assertRaisesRegex(ValueError, "Request struct GetLedgersRequest for getLedgers not found"):
            parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_empty_request_struct_yields_no_parameters(self):
        parser = GoSourceParser(go_stellar_sdk_path=None)
        parser.set_protocol_source(
            "type GetHealthRequest struct{}\n\ntype GetHealthResponse struct {\n\tStatus string `json:\"status\"`\n}\n")
        spec = parser.parse_method_handler("getHealth", HANDLER_SOURCE, "get_health.go")
        self.assertEqual(spec.parameters, {"required": [], "optional": []})
        self.assertEqual([f["name"] for f in spec.response["fields"]], ["status"])


class MethodSetTest(unittest.TestCase):

    def test_full_set_passes(self):
        check_method_set(list(KNOWN_METHODS))

    def test_missing_method_raises_naming_it(self):
        methods = [name for name in KNOWN_METHODS if name != "getFeeStats"]
        with self.assertRaisesRegex(ValueError, r"missing: getFeeStats\)"):
            check_method_set(methods)

    def test_extra_method_raises_naming_it(self):
        with self.assertRaisesRegex(ValueError, r"extra: queryEvents\)"):
            check_method_set([*KNOWN_METHODS, "queryEvents"])

    def test_known_methods_has_twelve_entries(self):
        self.assertEqual(len(KNOWN_METHODS), 12)


if __name__ == "__main__":
    unittest.main()
