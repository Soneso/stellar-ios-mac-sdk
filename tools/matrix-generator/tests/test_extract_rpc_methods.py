"""Tests for extract_rpc_methods: release lookups and failure on any missing method definition."""

import contextlib
import http.client
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
    import requests.adapters  # noqa: E402
    import urllib3  # noqa: E402

import extract_rpc_methods  # noqa: E402
import rpc_releases  # noqa: E402
from extract_rpc_methods import (  # noqa: E402
    KNOWN_METHODS,
    GitHubFetcher,
    GoSourceParser,
    check_method_set,
    go_file_name,
    registered_methods,
)
from rpc_releases import ReleaseLookupError  # noqa: E402

from release_fixtures import release_list  # noqa: E402

HANDLER_SOURCE = "package methods\n"

# Copies of the stellar-rpc registration files at v30.0.0 and v30.0.1.
FIXTURES = Path(__file__).resolve().parent / "fixtures"
V30_0_0_SOURCE = (FIXTURES / "stellar-rpc-v30.0.0-jsonrpc.go").read_text(encoding="utf-8")
V30_0_1_SOURCE = (FIXTURES / "stellar-rpc-v30.0.1-rpcv1-jsonrpc.go").read_text(encoding="utf-8")
RPCV1_FILE = "cmd/stellar-rpc/internal/rpcv1/jsonrpc.go"
INTERNAL_FILE = "cmd/stellar-rpc/internal/jsonrpc.go"
# The methods that stellar-rpc v30.0.0 and v30.0.1 register, in source order.
SERVED_METHODS_V30 = [
    "getHealth", "getEvents", "getNetwork", "getVersionInfo", "getLatestLedger", "getLedgers",
    "getLedgerEntries", "getTransaction", "getTransactions", "sendTransaction",
    "simulateTransaction", "getFeeStats",
]


def raw_url(tag: str, file_path: str) -> str:
    return f"https://raw.githubusercontent.com/stellar/stellar-rpc/{tag}/{file_path}"


RPCV1_URL = raw_url("v30.0.1", RPCV1_FILE)
INTERNAL_URL = raw_url("v30.0.1", INTERNAL_FILE)


def pascal(method_name: str) -> str:
    return method_name[0].upper() + method_name[1:]


def protocol_source(method_name: str) -> str:
    """
    A go-stellar-sdk protocol file declaring the method's request and response structs.

    As in go-stellar-sdk, GetTransactionResponse embeds TransactionDetails, which the
    getTransactions file declares.
    """
    name = pascal(method_name)
    embedded = "\tTransactionDetails\n" if method_name == "getTransaction" else ""
    declared = ("\ntype TransactionDetails struct {\n\tStatus string `json:\"status\"`\n}\n"
                if method_name == "getTransactions" else "")
    return (
        f"type {name}Request struct {{\n\tStartLedger uint32 `json:\"startLedger\"`\n}}\n\n"
        f"type {name}Response struct {{\n\tLatestLedger uint32 `json:\"latestLedger\"`\n{embedded}}}\n{declared}"
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


def go_mod(requirement: str = "github.com/stellar/go-stellar-sdk v0.7.2") -> str:
    """A stellar-rpc go.mod requiring the given module version."""
    return f"module github.com/stellar/stellar-rpc\n\ngo 1.24\n\nrequire (\n\t{requirement}\n)\n"


class FakeGitHub:
    """
    Replaces the extractor's network access: the stellar-rpc release list and the
    go.mod, handler and registration files, and the go-stellar-sdk protocol files.

    The handler and protocol files of a method the release does not register answer
    404, as they do upstream.
    """

    def __init__(self, rpc_releases_list=None):
        self.rpc_releases = rpc_releases_list if rpc_releases_list is not None else release_list()
        self.go_mod = go_mod()
        self.file_errors = {}
        self.fetched_files = []
        self.refs_by_path = {}
        self.protocol_refs = []
        self.registrations = list(KNOWN_METHODS)
        self.registration_file = INTERNAL_FILE
        self.registration_layout = registration_source

    def fetch_releases(self, repo, token):
        return {"stellar/stellar-rpc": self.rpc_releases}[repo]

    def fetch_file(self, file_path, ref):
        self.fetched_files.append(file_path)
        self.refs_by_path[file_path] = ref
        if file_path in self.file_errors:
            raise self.file_errors[file_path]
        if file_path == "go.mod":
            return self.go_mod
        if file_path in {f"cmd/stellar-rpc/internal/methods/{go_file_name(name)}" for name in self.registrations}:
            return HANDLER_SOURCE
        raise RuntimeError(f"Failed to fetch {file_path} at {ref}: 404 Client Error")

    def fetch_registration_source(self, ref):
        self.fetched_files.append(self.registration_file)
        self.refs_by_path[self.registration_file] = ref
        if self.registration_file in self.file_errors:
            raise self.file_errors[self.registration_file]
        return self.registration_file, self.registration_layout(self.registrations)

    def fetch_protocol_file(self, method_name, ref):
        self.protocol_refs.append(ref)
        if method_name not in self.registrations:
            raise RuntimeError(f"Failed to fetch go-stellar-sdk protocols/rpc/{go_file_name(method_name)} at {ref}: "
                               "404 Client Error")
        return protocol_source(method_name)

    @contextlib.contextmanager
    def installed(self, fake_release_lists=True):
        """Patch the fetcher; with fake_release_lists False, release lists go through the real fetch_releases."""
        with contextlib.ExitStack() as stack:
            if fake_release_lists:
                stack.enter_context(mock.patch.object(rpc_releases, "fetch_releases", self.fetch_releases))
            stack.enter_context(mock.patch.object(GitHubFetcher, "fetch_file",
                                                  lambda _self, path, ref: self.fetch_file(path, ref)))
            stack.enter_context(mock.patch.object(GitHubFetcher, "fetch_protocol_file",
                                                  lambda _self, method, ref: self.fetch_protocol_file(method, ref)))
            stack.enter_context(mock.patch.object(GitHubFetcher, "fetch_registration_source",
                                                  lambda _self, ref: self.fetch_registration_source(ref)))
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
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            self.assertEqual(self.fetcher().resolve_rpc_version(None), "v28.0.10")

    def test_rpc_override_present(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            self.assertEqual(self.fetcher().resolve_rpc_version("v28.0.9"), "v28.0.9")

    def test_rpc_prerelease_override_is_allowed(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            self.assertEqual(self.fetcher().resolve_rpc_version("v29.0.0-rc.1"), "v29.0.0-rc.1")

    def test_rpc_override_absent_raises(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            with self.assertRaisesRegex(ReleaseLookupError, "has no release tagged v26.0.0"):
                self.fetcher().resolve_rpc_version("v26.0.0")

    def test_rpc_override_pointing_at_draft_raises(self):
        with mock.patch.object(rpc_releases, "fetch_releases", return_value=release_list()):
            with self.assertRaisesRegex(ReleaseLookupError, "v31.0.0 is a draft"):
                self.fetcher().resolve_rpc_version("v31.0.0")

    def test_rpc_lookup_failure_raises(self):
        with mock.patch.object(rpc_releases, "fetch_releases",
                               side_effect=ReleaseLookupError("GET failed: HTTP 502 Bad Gateway")):
            with self.assertRaisesRegex(ReleaseLookupError, "HTTP 502"):
                self.fetcher().resolve_rpc_version(None)


class ExtractorMainTest(unittest.TestCase):

    def run_extractor(self, fake):
        """Run main() against the fake; return exit code, the written JSON or None, and stderr."""
        with tempfile.TemporaryDirectory() as tmp, fake.installed():
            output = Path(tmp) / "rpc_methods.json"
            exit_code, _, stderr = run_main(["--output", str(output)])
            return exit_code, json.loads(output.read_text()) if output.exists() else None, stderr

    def test_full_set_writes_json_citing_the_release_and_its_go_stellar_sdk_pin(self):
        fake = FakeGitHub()
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 0, stderr)
        self.assertEqual(set(data["methods"]), set(KNOWN_METHODS))
        self.assertEqual(data["metadata"]["version"], "v28.0.10")
        self.assertEqual(data["metadata"]["total_methods"], 12)
        self.assertEqual(data["metadata"]["protocol_definitions"],
                         "https://github.com/stellar/go-stellar-sdk/tree/v0.7.2/protocols/rpc")
        self.assertEqual(fake.protocol_refs, ["v0.7.2"] * 12)
        self.assertEqual(fake.refs_by_path["go.mod"], "v28.0.10")
        self.assertEqual(fake.refs_by_path["cmd/stellar-rpc/internal/jsonrpc.go"], "v28.0.10")
        for name, method in data["methods"].items():
            with self.subTest(method=name):
                self.assertEqual(list(method), ["name", "handler_file", "parameters", "response"])
                self.assertEqual(method["handler_file"], f"cmd/stellar-rpc/internal/methods/{go_file_name(name)}")
                self.assertEqual(method["parameters"],
                                 {"required": [{"name": "startLedger", "type": "uint32", "required": True}], "optional": []})
                self.assertEqual(list(method["response"]), ["type", "fields"])
                expected = [("latestLedger", "uint32")]
                if name == "getTransaction":
                    expected.append(("status", "string"))
                self.assertEqual([(f["name"], f["type"]) for f in method["response"]["fields"]], expected)
                self.assertTrue(all(list(f) == ["name", "type"] for f in method["response"]["fields"]))

    def test_pseudo_version_pin_resolves_to_its_commit(self):
        fake = FakeGitHub()
        fake.go_mod = go_mod("github.com/stellar/go-stellar-sdk v0.0.0-20251208182759-7568ee53f4fd")
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 0, stderr)
        self.assertEqual(set(fake.protocol_refs), {"7568ee53f4fd"})
        self.assertEqual(data["metadata"]["protocol_definitions"],
                         "https://github.com/stellar/go-stellar-sdk/tree/7568ee53f4fd/protocols/rpc")

    def test_go_mod_without_go_stellar_sdk_exits_non_zero_naming_the_cause(self):
        fake = FakeGitHub()
        fake.go_mod = go_mod("github.com/stellar/go v0.0.0-20250818235326-815d6a25c539")
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("go.mod at v28.0.10 requires no github.com/stellar/go-stellar-sdk version", stderr)
        self.assertEqual(fake.protocol_refs, [])

    def test_one_handler_fetch_failing_exits_non_zero_and_writes_no_json(self):
        fake = FakeGitHub()
        fake.file_errors["cmd/stellar-rpc/internal/methods/get_ledgers.go"] = RuntimeError(
            "Failed to fetch cmd/stellar-rpc/internal/methods/get_ledgers.go at v28.0.10: 404 Client Error")
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("Failed to extract getLedgers: Failed to fetch cmd/stellar-rpc/internal/methods/get_ledgers.go", stderr)

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
        self.assertEqual(fake.fetched_files, [])

    def test_upstream_registration_added_exits_non_zero_naming_it(self):
        fake = FakeGitHub()
        fake.registrations = [*KNOWN_METHODS, "queryEvents"]
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("extra: queryEvents", stderr)

    def test_upstream_registration_removed_exits_non_zero_naming_it(self):
        fake = FakeGitHub()
        fake.registrations = [name for name in KNOWN_METHODS if name != "getFeeStats"]
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("missing: getFeeStats", stderr)

    def test_registration_fetch_failure_exits_non_zero(self):
        fake = FakeGitHub()
        fake.file_errors["cmd/stellar-rpc/internal/jsonrpc.go"] = RuntimeError(
            "Failed to fetch cmd/stellar-rpc/internal/jsonrpc.go at v28.0.10: 502 Bad Gateway")
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("cmd/stellar-rpc/internal/jsonrpc.go at v28.0.10: 502 Bad Gateway", stderr)

    def test_registration_file_in_string_literal_layout_exits_non_zero_naming_the_cause(self):
        fake = FakeGitHub()
        fake.registration_layout = literal_registration_source
        exit_code, data, stderr = self.run_extractor(fake)
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("cmd/stellar-rpc/internal/jsonrpc.go at v28.0.10: unrecognized method registration entry: "
                      '{\n\t\t\tmethodName: "getHealth",\n\t\t}', stderr)

    def test_registration_file_of_either_form_writes_the_known_methods(self):
        for file_path, source in ((RPCV1_FILE, V30_0_1_SOURCE), (INTERNAL_FILE, V30_0_0_SOURCE)):
            with self.subTest(file=file_path):
                fake = FakeGitHub()
                fake.registration_file = file_path
                fake.registration_layout = lambda _names, text=source: text
                exit_code, data, stderr = self.run_extractor(fake)
                self.assertEqual(exit_code, 0, stderr)
                self.assertEqual(list(data["methods"]), KNOWN_METHODS)
                self.assertEqual(fake.refs_by_path[file_path], "v28.0.10")

    def test_release_lookup_failure_exits_non_zero_and_writes_no_json(self):
        exit_code, data, stderr = self.run_extractor(FakeGitHub(rpc_releases_list=[]))
        self.assertEqual(exit_code, 1)
        self.assertIsNone(data)
        self.assertIn("stellar/stellar-rpc has no stable vX.Y.Z release", stderr)


class GitHubFetcherTest(unittest.TestCase):

    def response(self, status_code):
        response = mock.Mock(status_code=status_code, text="package protocol\n")
        if status_code >= 400:
            response.raise_for_status.side_effect = requests.HTTPError(f"{status_code} Client Error")
        return response

    def test_requests_use_the_given_refs(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(200)) as get:
            fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go", "v28.0.1")
            self.assertEqual(fetcher.fetch_protocol_file("getLedgerEntries", "v0.7.2"), "package protocol\n")
        self.assertEqual([c.args[0] for c in get.call_args_list], [
            "https://raw.githubusercontent.com/stellar/stellar-rpc/v28.0.1/cmd/stellar-rpc/internal/methods/get_health.go",
            "https://raw.githubusercontent.com/stellar/go-stellar-sdk/v0.7.2/protocols/rpc/get_ledger_entries.go",
        ])

    def test_ref_is_required(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get") as get:
            with self.assertRaises(TypeError):
                fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go")
            with self.assertRaises(TypeError):
                fetcher.fetch_protocol_file("getLedgers")
        get.assert_not_called()

    def test_request_error_raises_naming_the_file(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", side_effect=requests.ConnectionError("connection reset")):
            with self.assertRaisesRegex(RuntimeError, "protocols/rpc/get_ledgers.go at v0.7.2: connection reset"):
                fetcher.fetch_protocol_file("getLedgers", "v0.7.2")

    def test_http_error_raises_naming_the_file(self):
        fetcher = GitHubFetcher(token="t")
        with mock.patch.object(fetcher.session, "get", return_value=self.response(404)):
            with self.assertRaisesRegex(RuntimeError, "get_health.go at v28.0.1: 404 Client Error"):
                fetcher.fetch_file("cmd/stellar-rpc/internal/methods/get_health.go", "v28.0.1")


class FailingBody(io.RawIOBase):
    """A response body whose read fails with the given error."""

    def __init__(self, error):
        super().__init__()
        self.error = error

    def readable(self):
        return True

    def readinto(self, buffer):
        raise self.error


class RawGitHub(requests.adapters.HTTPAdapter):
    """
    Serves raw files by URL through the requests response and body-read path.

    A response is (status, body) or an exception that the transport raises; a body
    that is an exception fails the body read. An unknown URL raises KeyError.
    """

    def __init__(self, responses):
        super().__init__()
        self.responses = responses
        self.requested = []

    def send(self, request, **kwargs):
        self.requested.append(request.url)
        response = self.responses[request.url]
        if isinstance(response, Exception):
            raise response
        status, body = response
        stream = FailingBody(body) if isinstance(body, Exception) else io.BytesIO(body)
        return self.build_response(request, urllib3.HTTPResponse(
            body=stream, status=status, reason=http.HTTPStatus(status).phrase, preload_content=False))


class RegistrationFetchTest(unittest.TestCase):
    """The registration file is read at the tag; the internal path only after HTTP 404 at that tag."""

    def fetch(self, responses, tag="v30.0.1"):
        fetcher = GitHubFetcher(token="t")
        self.github = RawGitHub(responses)
        fetcher.session.mount("https://", self.github)
        return fetcher.fetch_registration_source(tag)

    def test_reads_the_rpcv1_file(self):
        result = self.fetch({RPCV1_URL: (200, V30_0_1_SOURCE.encode()), INTERNAL_URL: (200, b"internal source")})
        self.assertEqual(result, (RPCV1_FILE, V30_0_1_SOURCE))
        self.assertEqual(self.github.requested, [RPCV1_URL])

    def test_falls_back_to_the_internal_file_of_the_same_tag_on_404(self):
        rpcv1_url, internal_url = raw_url("v30.0.0", RPCV1_FILE), raw_url("v30.0.0", INTERNAL_FILE)
        result = self.fetch({rpcv1_url: (404, b"404: Not Found"), internal_url: (200, V30_0_0_SOURCE.encode()),
                             RPCV1_URL: (200, b"rpcv1 source of another tag")}, tag="v30.0.0")
        self.assertEqual(result, (INTERNAL_FILE, V30_0_0_SOURCE))
        self.assertEqual(self.github.requested, [rpcv1_url, internal_url])

    def test_any_other_failure_on_either_path_raises_naming_the_tag_and_url(self):
        failures = {
            "500 Server Error: Internal Server Error": (500, b""),
            "429 Client Error: Too Many Requests": (429, b""),
            "403 Client Error: Forbidden": (403, b"rate limit exceeded"),
            "connection refused": requests.ConnectionError("connection refused"),
            "read timed out": requests.ReadTimeout("read timed out"),
            "IncompleteRead(7 bytes read, 100 more expected)": (200, http.client.IncompleteRead(b"package", 100)),
            "Connection reset by peer": (200, ConnectionResetError(54, "Connection reset by peer")),
            "'utf-8' codec can't decode": (200, b"package rpcv1 \xff"),
        }
        for failing_url, earlier_requests in ((RPCV1_URL, []), (INTERNAL_URL, [RPCV1_URL])):
            for cause, failure in failures.items():
                with self.subTest(url=failing_url, failure=cause):
                    responses = {RPCV1_URL: (404, b""), INTERNAL_URL: (200, V30_0_0_SOURCE.encode())}
                    responses[failing_url] = failure
                    with self.assertRaises(RuntimeError) as context:
                        self.fetch(responses)
                    message = str(context.exception)
                    self.assertTrue(message.startswith(f"Failed to read {failing_url} for stellar-rpc tag v30.0.1: "),
                                    message)
                    self.assertIn(cause, message)
                    self.assertEqual(self.github.requested, earlier_requests + [failing_url])

    def test_both_paths_absent_names_both_urls(self):
        with self.assertRaises(RuntimeError) as context:
            self.fetch({RPCV1_URL: (404, b""), INTERNAL_URL: (404, b"")})
        self.assertEqual(str(context.exception), "No JSON-RPC method registration file for stellar-rpc tag v30.0.1: "
                                                 f"HTTP 404 for {RPCV1_URL} and {INTERNAL_URL}")
        self.assertEqual(self.github.requested, [RPCV1_URL, INTERNAL_URL])


class DefinitionParsingTest(unittest.TestCase):

    def test_response_struct_not_found_in_any_source_raises_naming_the_method(self):
        parser = GoSourceParser(["type GetLedgersRequest struct {\n\tStartLedger uint32 `json:\"startLedger\"`\n}\n"])
        with self.assertRaisesRegex(ValueError, "Response struct .* for getLedgers not found"):
            parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_response_struct_without_json_fields_raises(self):
        parser = GoSourceParser(["type GetLedgersRequest struct{}\n\ntype GetLedgersResponse struct {\n\tinternal uint32\n}\n"])
        with self.assertRaisesRegex(ValueError, "GetLedgersResponse for getLedgers has no JSON fields"):
            parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_embedded_struct_from_another_protocol_file_adds_its_fields_at_its_position(self):
        get_transaction = (
            "type GetTransactionRequest struct {\n\tHash string `json:\"hash\"`\n}\n\n"
            "type GetTransactionResponse struct {\n\tLatestLedger uint32 `json:\"latestLedger\"`\n"
            "\tTransactionDetails\n\tLedgerCloseTime int64 `json:\"createdAt,string\"`\n}\n"
        )
        get_transactions = ("type TransactionDetails struct {\n\tStatus string `json:\"status\"`\n"
                            "\tTransactionHash string `json:\"txHash\"`\n}\n")
        parser = GoSourceParser([get_transaction, get_transactions])
        spec = parser.parse_method_handler("getTransaction", HANDLER_SOURCE, "get_transaction.go")
        self.assertEqual([f["name"] for f in spec.response["fields"]], ["latestLedger", "status", "txHash", "createdAt"])

    def test_embedded_struct_no_source_declares_raises_naming_both_types(self):
        parser = GoSourceParser([
            "type GetTransactionRequest struct{}\n\n"
            "type GetTransactionResponse struct {\n\tLatestLedger uint32 `json:\"latestLedger\"`\n\tTransactionDetails\n}\n"
        ])
        with self.assertRaisesRegex(ValueError, "GetTransactionResponse embeds TransactionDetails, which no go-stellar-sdk"):
            parser.parse_method_handler("getTransaction", HANDLER_SOURCE, "get_transaction.go")

    def test_request_struct_not_found_raises_naming_the_method(self):
        parser = GoSourceParser(["type GetLedgersResponse struct {\n\tLatestLedger uint32 `json:\"latestLedger\"`\n}\n"])
        with self.assertRaisesRegex(ValueError, "Request struct GetLedgersRequest for getLedgers not found"):
            parser.parse_method_handler("getLedgers", HANDLER_SOURCE, "get_ledgers.go")

    def test_empty_request_struct_yields_no_parameters(self):
        parser = GoSourceParser(["type GetHealthRequest struct{}\n\ntype GetHealthResponse struct {\n\tStatus string `json:\"status\"`\n}\n"])
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


class RegistrationParsingTest(unittest.TestCase):
    """registered_methods() reads the one registration block of either form and rejects anything else."""

    def assert_rejected(self, source, *parts):
        with self.assertRaises(ValueError) as context:
            registered_methods(source, "rpcv1/jsonrpc.go at v30.0.1")
        for part in ("rpcv1/jsonrpc.go at v30.0.1",) + parts:
            self.assertIn(part, str(context.exception))

    def edited(self, source, old, new):
        self.assertEqual(source.count(old), 1, old)
        return source.replace(old, new)

    def test_both_forms_register_the_served_methods(self):
        for name, source in (("v30.0.0", V30_0_0_SOURCE), ("v30.0.1", V30_0_1_SOURCE)):
            with self.subTest(fixture=name):
                self.assertEqual(registered_methods(source, name), SERVED_METHODS_V30)
                check_method_set(registered_methods(source, name))

    def test_comments_and_literals_in_the_block_are_neither_entries_nor_brackets(self):
        cases = {
            "v30.0.1": (V30_0_1_SOURCE, "\t\tprotocol.GetFeeStatsMethodName: {",
                        "\t\t// protocol.GetFooMethodName: {},\n"
                        "\t\t/* protocol.GetBarMethodName: {}, */ protocol.GetFeeStatsMethodName: {"),
            "v30.0.0": (V30_0_0_SOURCE, "longName:             toSnakeCase(protocol.GetHealthMethodName),",
                        'longName:             "get_health) // }", // ignored },'),
        }
        for name, (source, old, new) in cases.items():
            with self.subTest(fixture=name):
                self.assertEqual(registered_methods(self.edited(source, old, new), name), SERVED_METHODS_V30)

    def test_unrecognized_entry_is_named(self):
        cases = {
            "v30.0.1": (V30_0_1_SOURCE, "protocol.GetFeeStatsMethodName: {", '"getFeeStats": {'),
            "v30.0.0": (V30_0_0_SOURCE, "methodName:           protocol.GetFeeStatsMethodName,",
                        'methodName: "getFeeStats",'),
        }
        for name, (source, old, new) in cases.items():
            with self.subTest(fixture=name):
                self.assert_rejected(self.edited(source, old, new), "unrecognized method registration entry", new)

    def test_handler_without_exactly_one_method_name_is_named(self):
        old = "\t\t\tmethodName: protocol.GetHealthMethodName,\n"
        for count in (0, 2):
            with self.subTest(method_names=count):
                self.assert_rejected(self.edited(V30_0_0_SOURCE, old, old * count),
                                     "unrecognized method registration entry", "methods.NewHealthCheck(")

    def test_method_name_reference_outside_the_block_is_named(self):
        reference = "protocol.GetLedgerStateMethodName"
        cases = {
            "v30.0.1": (V30_0_1_SOURCE, "\tspecs = jsonrpc.LimitsByMethod{\n",
                        f"\tspecs = append(specs, jsonrpc.HandlerSpec{{MethodName: {reference}}})\n"),
            "v30.0.0": (V30_0_0_SOURCE, "\thandlersMap := handler.Map{}\n",
                        f"\thandlers[0].methodName = {reference}\n"),
        }
        for name, (source, anchor, added) in cases.items():
            for spelling in (reference, "protocol .\n\t\tGetLedgerStateMethodName"):
                with self.subTest(fixture=name, spelling=spelling):
                    self.assert_rejected(self.edited(source, anchor, added.replace(reference, spelling) + anchor),
                                         f"method name reference outside the registration block: {reference}")
            with self.subTest(fixture=name, spelling="comments and literals"):
                quoted = (f"\t// {reference} LimitsByMethod{{\n\t/* {reference} */\n"
                          f'\t_ = "{reference} LimitsByMethod{{" + `[]struct {{ methodName string }}{{ {reference}`\n')
                self.assertEqual(registered_methods(self.edited(source, anchor, quoted + anchor), name),
                                 SERVED_METHODS_V30)

    def test_empty_unclosed_or_not_exactly_one_block_raises(self):
        for source, part in (
                ("specs = jsonrpc.LimitsByMethod{\n}.Apply(specs)\n", "the method registration block is empty"),
                ("specs = jsonrpc.LimitsByMethod{\n\tprotocol.GetHealthMethodName: {},\n", "block is not closed"),
                ("package rpcv1\n", "holds 0 method registration blocks"),
                (V30_0_1_SOURCE + V30_0_0_SOURCE, "holds 2 method registration blocks")):
            with self.subTest(expected=part):
                self.assert_rejected(source, part)


if __name__ == "__main__":
    unittest.main()
