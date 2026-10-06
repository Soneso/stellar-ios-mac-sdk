#!/usr/bin/env python3
"""
Stellar RPC Method Extractor

Extracts RPC method specifications from the stellar-rpc GitHub repository by
parsing Go source files.

This script reads the handlers of the newest stable stellar-rpc release (or the
release given by --rpc-version) and the request and response structs of the
go-stellar-sdk version that the release's go.mod requires, and writes a JSON
file documenting all RPC methods with their parameters and response fields.

Usage:
    python3 extract_rpc_methods.py [--output PATH] [--rpc-version VERSION] [--verbose]

Requirements:
    - Python 3.10+
    - requests library (pip install requests)

Authentication:
    To avoid GitHub API rate limits (60 req/hour unauthenticated vs 5,000 authenticated),
    set a GitHub token via one of these methods:

    1. Environment variable: export GITHUB_TOKEN=your_token
    2. gh CLI config: The token is read from ~/.config/gh/hosts.yml if available
    3. Command line: --token YOUR_TOKEN

    To create a token: https://github.com/settings/tokens
    Required scope: No scopes needed for public repo access (just need authentication)

Failures:
    A failed release lookup, a go.mod without a go-stellar-sdk requirement (every
    stellar-rpc release before v25.0.0), a failed fetch or parse of any handler,
    request definition, or response definition, or a set of methods registered in
    the release's jsonrpc.go that differs from KNOWN_METHODS raises. The script
    then exits non-zero and writes no JSON.
"""

import json
import re
import sys
from collections.abc import Iterable
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

try:
    import requests
except ImportError:
    print("Error: requests library is required. Install with: pip install requests", file=sys.stderr)
    sys.exit(1)

from rpc_releases import (
    REQUEST_TIMEOUT_SECONDS,
    STELLAR_RPC_REPO,
    USER_AGENT,
    get_github_token,
    resolve_release,
)

GITHUB_RAW_BASE = "https://raw.githubusercontent.com"
GO_STELLAR_SDK_REPO = "stellar/go-stellar-sdk"

# stellar-rpc paths from v25.0.0, the first release whose go.mod requires go-stellar-sdk.
METHODS_DIR = "cmd/stellar-rpc/internal/methods"
REGISTRATION_FILE = "cmd/stellar-rpc/internal/jsonrpc.go"
# The go-stellar-sdk directory that declares the request and response structs.
PROTOCOL_DIR = "protocols/rpc"

# The go.mod requirement of go-stellar-sdk. A Go pseudo-version is not a git tag;
# its git ref is the trailing commit hash. Both pseudo-version forms carry a
# 14-digit UTC timestamp directly before the final hash segment:
# vX.Y.Z-yyyymmddhhmmss-<12 hex> and vX.Y.Z-0.yyyymmddhhmmss-<12 hex>.
GO_STELLAR_SDK_REQUIREMENT = re.compile(r"github\.com/stellar/go-stellar-sdk\s+(\S+)")
PSEUDO_VERSION = re.compile(r"v\S*\d{14}-([0-9a-f]{12})")

# The JSON-RPC methods. Each one's handler file in METHODS_DIR and protocol file in
# PROTOCOL_DIR are named after the method in snake_case.
KNOWN_METHODS = [
    "getHealth",
    "getNetwork",
    "getVersionInfo",
    "getFeeStats",
    "getLatestLedger",
    "getLedgerEntries",
    "getLedgers",
    "getEvents",
    "getTransaction",
    "getTransactions",
    "sendTransaction",
    "simulateTransaction",
]


def go_file_name(method_name: str) -> str:
    """The Go file of a method, in stellar-rpc and go-stellar-sdk alike: getLedgerEntries -> get_ledger_entries.go"""
    return re.sub(r"(?<!^)(?=[A-Z])", "_", method_name).lower() + ".go"


def pascal_case(method_name: str) -> str:
    """The Go type prefix of a method: getHealth -> GetHealth"""
    return method_name[0].upper() + method_name[1:]


def _go_type_to_json_type(go_type: str) -> str:
    """Convert a Go type string to a JSON type description."""
    go_type = go_type.lstrip('*')

    if go_type.startswith('[]'):
        return f"array[{_go_type_to_json_type(go_type[2:])}]"

    type_map = {
        'string': 'string',
        'bool': 'boolean',
        'int': 'integer',
        'int32': 'int32',
        'int64': 'int64',
        'uint': 'uint',
        'uint32': 'uint32',
        'uint64': 'uint64 (string)',
        'float32': 'float',
        'float64': 'float',
        'json.RawMessage': 'object',
        'time.Time': 'string (RFC3339)',
    }

    return type_map.get(go_type, go_type)


def check_method_set(method_names: Iterable[str]) -> None:
    """Raise unless the method names registered upstream are exactly KNOWN_METHODS, naming every missing and extra method."""
    extracted = set(method_names)
    known = set(KNOWN_METHODS)
    missing = sorted(known - extracted)
    extra = sorted(extracted - known)
    if missing or extra:
        problems = []
        if missing:
            problems.append(f"missing: {', '.join(missing)}")
        if extra:
            problems.append(f"extra: {', '.join(extra)}")
        raise ValueError(f"Registered stellar-rpc methods differ from KNOWN_METHODS ({'; '.join(problems)})")


# One member of a Go struct body, in declaration order: an embedded struct (a line holding
# only its type name) or a field with a JSON tag (FieldName Type `json:"jsonName,omitempty"`).
STRUCT_MEMBER = re.compile(
    r'^\s+(?P<embedded>\w+)\s*$|\w+\s+(?P<type>[\w\[\]\.\*]+)\s*`json:"(?P<json>[^"]+)"[^`]*`',
    re.MULTILINE,
)


class ResponseStructParser:
    """Parses Go response structs from go-stellar-sdk protocol sources.

    Embedded structs resolve across all sources, because a response can embed a
    struct that another method's protocol file declares.
    """

    def __init__(self, sources: list[str]):
        self.sources = sources

    def parse_response_struct(self, method_name: str) -> dict[str, Any]:
        """
        Parse the <Method>Response struct of an RPC method.

        Returns the struct's JSON fields in declaration order, an embedded struct's
        fields at its position. Raises when no source declares the struct or the
        struct has no JSON field.
        """
        struct_name = f"{pascal_case(method_name)}Response"
        struct_def = self._find_struct_definition(struct_name)
        if not struct_def:
            raise ValueError(
                f"Response struct {struct_name} for {method_name} not found in the go-stellar-sdk protocol sources"
            )
        fields = self._parse_struct_fields(struct_name, struct_def)
        if not fields:
            raise ValueError(f"Response struct {struct_name} for {method_name} has no JSON fields")
        return {"type": "object", "fields": fields}

    def _find_struct_definition(self, struct_name: str) -> Optional[str]:
        """Return the body of a struct declared in the sources, or None."""
        pattern = rf'type\s+{re.escape(struct_name)}\s+struct\s*\{{([^}}]+(?:\{{[^}}]*\}}[^}}]*)*)\}}'

        for source in self.sources:
            match = re.search(pattern, source, re.DOTALL)
            if match:
                return match.group(1)

        return None

    def _parse_struct_fields(self, struct_name: str, struct_body: str,
                             _seen: set | None = None) -> list[dict[str, str]]:
        """
        Return the JSON fields of a struct body in declaration order.

        An embedded struct contributes its own fields at its position; its fields are
        part of the response, so an embedded type no source declares raises. _seen holds
        the structs visited so far; an embedded type already in it adds nothing, which stops
        recursion.
        """
        if _seen is None:
            _seen = set()
        _seen.add(struct_name)

        fields = []
        for member in STRUCT_MEMBER.finditer(struct_body):
            embedded_type = member.group("embedded")
            if embedded_type:
                if embedded_type in _seen:
                    continue
                embedded_struct = self._find_struct_definition(embedded_type)
                if not embedded_struct:
                    raise ValueError(
                        f"{struct_name} embeds {embedded_type}, which no go-stellar-sdk protocol source declares"
                    )
                fields.extend(self._parse_struct_fields(embedded_type, embedded_struct, _seen))
                continue

            # The JSON name without options such as omitempty; json:"-" is not serialized.
            json_name = member.group("json").split(',')[0]
            if json_name != "-":
                fields.append({"name": json_name, "type": _go_type_to_json_type(member.group("type"))})

        return fields


@dataclass
class Parameter:
    """Represents a method parameter."""
    name: str
    type: str
    required: bool


@dataclass
class MethodSpec:
    """Represents an RPC method specification."""
    name: str
    handler_file: str
    parameters: dict[str, list[Parameter]]
    response: dict[str, Any]

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary."""
        return {
            "name": self.name,
            "handler_file": self.handler_file,
            "parameters": {
                "required": [asdict(p) for p in self.parameters["required"]],
                "optional": [asdict(p) for p in self.parameters["optional"]]
            },
            "response": self.response,
        }


class GitHubFetcher:
    """Fetches stellar-rpc and go-stellar-sdk files from GitHub."""

    def __init__(self, token: Optional[str] = None, verbose: bool = False):
        # Auto-detect token if not explicitly provided
        self.token = token if token else get_github_token()
        self.verbose = verbose
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": USER_AGENT})
        if self.token:
            self.session.headers.update({"Authorization": f"Bearer {self.token}"})
            if verbose:
                print("Authentication: Enabled (5,000 requests/hour)")
        elif verbose:
            print("Authentication: Not configured (60 requests/hour)")
            print("  Tip: Set GITHUB_TOKEN env var for higher rate limits")

    def resolve_rpc_version(self, override: Optional[str] = None) -> str:
        """
        Return the stellar-rpc release tag to extract from.

        Without an override, the newest stable release. An override must name a
        non-draft release; a prerelease is allowed.
        """
        version = resolve_release(STELLAR_RPC_REPO, override, self.token).tag
        if self.verbose:
            print(f"stellar-rpc version: {version}")
        return version

    def go_stellar_sdk_ref(self, rpc_version: str) -> str:
        """
        Return the go-stellar-sdk git ref that stellar-rpc's go.mod requires at rpc_version.

        A release version is its own tag; a pseudo-version names a commit, and the
        ref is its hash. Raises when go.mod requires no go-stellar-sdk version.
        """
        go_mod = self.fetch_file("go.mod", rpc_version)
        match = GO_STELLAR_SDK_REQUIREMENT.search(go_mod)
        if not match:
            raise RuntimeError(
                f"stellar-rpc go.mod at {rpc_version} requires no github.com/stellar/go-stellar-sdk version"
            )
        pseudo = PSEUDO_VERSION.fullmatch(match.group(1))
        ref = pseudo.group(1) if pseudo else match.group(1)
        if self.verbose:
            print(f"go-stellar-sdk ref: {ref}")
        return ref

    def fetch_file(self, file_path: str, ref: str) -> str:
        """Fetch a stellar-rpc file at ref."""
        return self._get(f"{GITHUB_RAW_BASE}/{STELLAR_RPC_REPO}/{ref}/{file_path}", f"{file_path} at {ref}")

    def fetch_protocol_file(self, method_name: str, ref: str) -> str:
        """Fetch the go-stellar-sdk file that declares a method's request and response structs at ref."""
        file_path = f"{PROTOCOL_DIR}/{go_file_name(method_name)}"
        return self._get(f"{GITHUB_RAW_BASE}/{GO_STELLAR_SDK_REPO}/{ref}/{file_path}",
                         f"go-stellar-sdk {file_path} at {ref}")

    def _get(self, url: str, description: str) -> str:
        """GET a raw file; any request error or HTTP error status raises, naming the file."""
        if self.verbose:
            print(f"Fetching: {description}")
        try:
            response = self.session.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            raise RuntimeError(f"Failed to fetch {description}: {e}") from e


class GoSourceParser:
    """Parses Go source files to extract RPC method specifications."""

    def __init__(self, protocol_sources: list[str], verbose: bool = False):
        self.verbose = verbose
        self.protocol_source = "\n\n".join(protocol_sources)
        self.response_parser = ResponseStructParser(protocol_sources)

    def parse_method_handler(self, method_name: str, go_source: str, handler_file: str) -> MethodSpec:
        """
        Parse a method handler Go file.

        Args:
            method_name: Name of the RPC method (e.g., "getHealth")
            go_source: Go source code content
            handler_file: Path to the handler file

        Returns:
            MethodSpec object with extracted information
        """
        if self.verbose:
            print(f"  Parsing {method_name}...")

        return MethodSpec(
            name=method_name,
            handler_file=handler_file,
            parameters=self._extract_parameters(go_source, method_name),
            response=self.response_parser.parse_response_struct(method_name),
        )

    def _extract_parameters(self, go_source: str, method_name: str) -> dict[str, list[Parameter]]:
        """
        Extract method parameters from the request struct.

        Every method has a request struct, declared as an empty struct{} when the
        method takes no parameters. Raises when neither the handler source nor the
        protocol source declares it.
        """
        parameters = {"required": [], "optional": []}

        struct_name = pascal_case(method_name) + "Request"

        # Find the request struct definition - first try handler file, then protocol source
        struct_pattern = rf'type\s+{struct_name}\s+struct\s*\{{([^}}]*)\}}'
        match = re.search(struct_pattern, go_source, re.DOTALL) or re.search(struct_pattern, self.protocol_source, re.DOTALL)

        if not match:
            raise ValueError(
                f"Request struct {struct_name} for {method_name} not found in the handler source or the protocol source"
            )

        struct_body = match.group(1)

        # Parse each field in the struct
        # Pattern: FieldName Type `json:"json_name" optional:"true"`
        # Handle multi-line field definitions and various type formats
        field_pattern = r'(\w+)\s+([\*\[\]]*[\w\.]+(?:\[[\w\.]+\])?)\s*`json:"([^"]+)"([^`]*)`'

        for field_match in re.finditer(field_pattern, struct_body):
            field_type = field_match.group(2)
            json_tag = field_match.group(3)
            tags = field_match.group(4)

            # Extract just the field name from json tag (remove omitempty, etc.)
            json_name = json_tag.split(',')[0]

            # Skip if json:"-" (not serialized)
            if json_name == "-":
                continue

            # Check if optional based on:
            # 1. omitempty in json tag
            # 2. Pointer type (*)
            # 3. optional: tag
            is_optional = (
                "omitempty" in json_tag or
                field_type.startswith("*") or
                "optional:" in tags
            )

            param = Parameter(name=json_name, type=_go_type_to_json_type(field_type), required=not is_optional)

            if is_optional:
                parameters["optional"].append(param)
            else:
                parameters["required"].append(param)

        if self.verbose:
            req_count = len(parameters["required"])
            opt_count = len(parameters["optional"])
            print(f"    Found {req_count} required, {opt_count} optional parameters")

        return parameters


class RPCMethodExtractor:
    """Main extraction orchestrator."""

    def __init__(self, github_token: Optional[str] = None, verbose: bool = False):
        self.fetcher = GitHubFetcher(token=github_token, verbose=verbose)
        self.verbose = verbose

    def extract(self, rpc_version: Optional[str] = None) -> dict[str, Any]:
        """
        Extract all RPC methods and generate JSON structure.

        rpc_version overrides the stellar-rpc release; without it, the newest stable
        release is used. Raises when any method fails to extract or when the methods
        registered in the release's jsonrpc.go differ from KNOWN_METHODS.
        """
        if self.verbose:
            print("Starting RPC method extraction...")

        rpc_version = self.fetcher.resolve_rpc_version(rpc_version)
        go_sdk_ref = self.fetcher.go_stellar_sdk_ref(rpc_version)
        # KNOWN_METHODS must match the methods the release registers. The check runs before the
        # handler and protocol fetches, so a removed or renamed method fails with its name.
        check_method_set(self._registered_methods(rpc_version))

        # Every protocol file is fetched before any method is parsed, because a response
        # can embed a struct that another method's protocol file declares.
        parser = GoSourceParser(
            [self.fetcher.fetch_protocol_file(method_name, go_sdk_ref) for method_name in KNOWN_METHODS],
            verbose=self.verbose,
        )

        methods = {}
        for method_name in KNOWN_METHODS:
            handler_file = f"{METHODS_DIR}/{go_file_name(method_name)}"
            try:
                go_source = self.fetcher.fetch_file(handler_file, rpc_version)
                methods[method_name] = parser.parse_method_handler(method_name, go_source, handler_file).to_dict()
            except Exception as e:
                raise RuntimeError(f"Failed to extract {method_name}: {e}") from e

        output = {
            "metadata": {
                "source": "stellar-rpc",
                "repository": f"https://github.com/{STELLAR_RPC_REPO}",
                "version": rpc_version,
                "extracted_date": datetime.now().strftime("%Y-%m-%d"),
                "total_methods": len(methods),
                "protocol": "JSON-RPC 2.0",
                "protocol_definitions": f"https://github.com/{GO_STELLAR_SDK_REPO}/tree/{go_sdk_ref}/{PROTOCOL_DIR}"
            },
            "methods": methods
        }

        if self.verbose:
            print(f"\nExtraction complete: {len(methods)} methods")
            print(f"stellar-rpc version: {rpc_version}")

        return output

    def _registered_methods(self, rpc_version: str) -> list[str]:
        """
        Return the JSON-RPC method names that stellar-rpc registers in REGISTRATION_FILE at rpc_version.

        Raises on a fetch failure and when the file holds no protocol.<Name>MethodName
        registrations.
        """
        registration_source = self.fetcher.fetch_file(REGISTRATION_FILE, rpc_version)
        registered = re.findall(
            r"\bmethodName:\s*protocol\.([A-Za-z][A-Za-z0-9]*)MethodName\b",
            registration_source,
        )
        if not registered:
            raise RuntimeError(f"No protocol.<Name>MethodName registrations found in jsonrpc.go at {rpc_version}")
        return [name[0].lower() + name[1:] for name in registered]


def main() -> int:
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Extract RPC method specifications from stellar-rpc repository"
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path(__file__).parent / "rpc_methods.json",
        help="Output JSON file path (default: rpc_methods.json in script directory)"
    )
    parser.add_argument(
        "--rpc-version",
        type=str,
        help="stellar-rpc release tag to extract from, for example v28.0.1; must be a non-draft release (default: newest stable release)"
    )
    parser.add_argument(
        "--token",
        "-t",
        type=str,
        help="GitHub personal access token (for higher rate limits)"
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output"
    )

    args = parser.parse_args()

    try:
        # Extract methods
        extractor = RPCMethodExtractor(github_token=args.token, verbose=args.verbose)
        data = extractor.extract(rpc_version=args.rpc_version)

        # Ensure output directory exists
        args.output.parent.mkdir(parents=True, exist_ok=True)

        # Write JSON output
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")

        print(f"\nSuccessfully extracted {data['metadata']['total_methods']} methods")
        print(f"stellar-rpc version: {data['metadata']['version']}")
        print(f"Output written to: {args.output}")

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
