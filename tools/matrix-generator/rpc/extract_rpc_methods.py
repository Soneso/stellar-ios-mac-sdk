#!/usr/bin/env python3
"""
Stellar RPC Method Extractor

Automatically extracts RPC method specifications from the stellar-rpc GitHub repository
by parsing Go source files.

This script fetches the stellar-rpc source code of the newest stable release (or the
release given by --rpc-version) from GitHub and generates a structured JSON file
documenting all RPC methods with their parameters, response fields, and other metadata.

Usage:
    python3 extract_rpc_methods.py [--output PATH] [--rpc-version VERSION] [--verbose]

Requirements:
    - Python 3.12+
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
    A failed release lookup, a failed fetch or parse of any handler, request
    definition, or response definition, or a set of methods registered in the
    release's jsonrpc.go that differs from KNOWN_METHODS raises. The script then
    exits non-zero and writes no JSON.
"""

import json
import re
import sys
from collections.abc import Iterable
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Optional
from urllib.parse import urljoin

try:
    import requests
except ImportError:
    print("Error: requests library is required. Install with: pip install requests", file=sys.stderr)
    sys.exit(1)

from rpc_releases import fetch_releases, find_release, get_github_token, select_newest_stable


class ResponseStructParser:
    """Parses Go response structs from go-stellar-sdk protocol files."""

    def __init__(self, go_stellar_sdk_path: Path, verbose: bool = False):
        """
        Initialize the parser.

        Args:
            go_stellar_sdk_path: Path to the go-stellar-sdk repository
            verbose: Enable verbose logging
        """
        self.protocol_path = go_stellar_sdk_path / "protocols" / "rpc"
        self.verbose = verbose
        self.protocol_cache = {}  # Cache loaded protocol files
        self._load_protocol_files()

    def _load_protocol_files(self):
        """Load all protocol .go files into memory."""
        if not self.protocol_path.exists():
            if self.verbose:
                print(f"Warning: Protocol path not found: {self.protocol_path}")
            return

        for go_file in self.protocol_path.glob("*.go"):
            try:
                content = go_file.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError) as e:
                raise RuntimeError(f"Failed to read local protocol file {go_file}: {e}") from e
            self.protocol_cache[go_file.stem] = content
            if self.verbose:
                print(f"  Loaded protocol file: {go_file.name}")

    def parse_response_struct(self, method_name: str) -> dict[str, Any]:
        """
        Parse the response struct for a given RPC method.

        Args:
            method_name: The RPC method name (e.g., "getHealth")

        Returns:
            Dictionary containing response structure with fields and nested types
        """
        # Convert method name to response struct name
        struct_names = self._get_response_struct_names(method_name)

        # Try to find the struct in protocol files
        for struct_name in struct_names:
            struct_def = self._find_struct_definition(struct_name)
            if struct_def:
                return self._parse_struct_fields(struct_name, struct_def)

        # Not found
        if self.verbose:
            print(f"  Warning: Response struct not found for {method_name}")
        return {"type": "object", "fields": [], "nested_types": {}}

    def _get_response_struct_names(self, method_name: str) -> list[str]:
        """
        Get possible response struct names for a method.

        Args:
            method_name: The RPC method name (e.g., "getHealth")

        Returns:
            List of possible struct names to try
        """
        # Convert getHealth -> GetHealth
        pascal_case = method_name[0].upper() + method_name[1:]

        return [
            f"{pascal_case}Response",  # GetHealthResponse
            f"{pascal_case}Result",     # GetHealthResult
        ]

    def _find_struct_definition(self, struct_name: str) -> Optional[str]:
        """
        Find a struct definition in loaded protocol files.

        Args:
            struct_name: Name of the struct to find

        Returns:
            Struct body content or None if not found
        """
        pattern = rf'type\s+{re.escape(struct_name)}\s+struct\s*\{{([^}}]+(?:\{{[^}}]*\}}[^}}]*)*)\}}'

        for file_content in self.protocol_cache.values():
            match = re.search(pattern, file_content, re.DOTALL)
            if match:
                return match.group(1)

        return None

    def _parse_struct_fields(self, struct_name: str, struct_body: str, _seen: set | None = None) -> dict[str, Any]:
        """
        Parse fields from a struct body, resolving embedded structs.

        Args:
            struct_name: Name of the struct
            struct_body: Body content of the struct
            _seen: Set of already-visited struct names to prevent infinite recursion

        Returns:
            Dictionary with fields and nested types
        """
        if _seen is None:
            _seen = set()
        _seen.add(struct_name)

        fields = []
        nested_types = {}

        # Resolve embedded structs (lines with just a type name, no field name or json tag)
        embedded_pattern = r'^\s+(\w+)\s*$'
        for match in re.finditer(embedded_pattern, struct_body, re.MULTILINE):
            embedded_type = match.group(1)
            if embedded_type in _seen:
                continue
            embedded_struct = self._find_struct_definition(embedded_type)
            if embedded_struct:
                embedded_result = self._parse_struct_fields(embedded_type, embedded_struct, _seen)
                fields.extend(embedded_result["fields"])
                nested_types.update(embedded_result.get("nested_types", {}))

        # Pattern to match struct fields with json tags
        # Handles: FieldName Type `json:"jsonName,omitempty"`
        field_pattern = r'(\w+)\s+([\w\[\]\.\*]+)\s*`json:"([^"]+)"([^`]*)`'

        for match in re.finditer(field_pattern, struct_body):
            field_name = match.group(1)
            field_type = match.group(2)
            json_tag = match.group(3)

            # Extract json field name (remove ,omitempty, ,string, etc.)
            json_name = json_tag.split(',')[0]

            # Skip if json:"-" (not serialized)
            if json_name == "-":
                continue

            # Determine the JSON type
            json_type = self._go_type_to_json_type(field_type)

            # Check if this is a nested custom type
            if self._is_custom_type(field_type):
                nested_type_name = field_type.lstrip('*').lstrip('[').lstrip(']')
                if nested_type_name not in nested_types:
                    nested_struct = self._find_struct_definition(nested_type_name)
                    if nested_struct:
                        nested_types[nested_type_name] = self._parse_struct_fields(
                            nested_type_name, nested_struct, _seen
                        )

            fields.append({
                "name": json_name,
                "type": json_type,
                "description": f"Field: {json_name}"
            })

        return {
            "type": "object",
            "fields": fields,
            "nested_types": nested_types
        }

    def _is_custom_type(self, go_type: str) -> bool:
        """
        Check if a Go type is a custom type (not a primitive).

        Args:
            go_type: The Go type string

        Returns:
            True if it's a custom type
        """
        # Remove pointer and array indicators
        base_type = go_type.lstrip('*').lstrip('[').lstrip(']')

        # List of Go primitive types
        primitives = {
            'string', 'bool', 'int', 'int8', 'int16', 'int32', 'int64',
            'uint', 'uint8', 'uint16', 'uint32', 'uint64',
            'float32', 'float64', 'byte', 'rune',
            'json.RawMessage', 'time.Time'
        }

        return base_type not in primitives

    def _go_type_to_json_type(self, go_type: str) -> str:
        """
        Convert Go type to JSON type description.

        Args:
            go_type: The Go type string

        Returns:
            JSON type description
        """
        # Remove pointer indicator
        go_type = go_type.lstrip('*')

        # Handle arrays
        if go_type.startswith('[]'):
            inner_type = go_type[2:]
            return f"array[{self._go_type_to_json_type(inner_type)}]"

        # Map Go types to JSON types
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

    def count_all_fields(self, response_struct: dict[str, Any]) -> int:
        """
        Count all fields including nested types.

        Args:
            response_struct: The parsed response structure

        Returns:
            Total count of all fields including nested ones
        """
        count = len(response_struct.get("fields", []))

        # Add counts from nested types
        nested_types = response_struct.get("nested_types", {})
        for nested_type in nested_types.values():
            count += self.count_all_fields(nested_type)

        return count


# GitHub API configuration
GITHUB_API_BASE = "https://api.github.com"
GITHUB_RAW_BASE = "https://raw.githubusercontent.com"
REPO_OWNER = "stellar"
REPO_NAME = "stellar-rpc"
DEFAULT_BRANCH = "main"

# Method handler directories (different in different versions)
# v21-v22: cmd/soroban-rpc/internal/methods
# v23+: cmd/stellar-rpc/internal/methods
METHODS_DIRS = [
    "cmd/stellar-rpc/internal/methods",  # v23+
    "cmd/soroban-rpc/internal/methods",  # v21-v22
]
# Protocol type definitions inside stellar-rpc; releases from v25.0.0 have no such
# directory because go-stellar-sdk holds those types.
PROTOCOL_DIR = "protocol"

# Local go-stellar-sdk path for protocol definitions
GO_STELLAR_SDK_PATH = Path("/Users/chris/projects/Stellar/go-stellar-sdk")
GO_STELLAR_SDK_PROTOCOL_PATH = GO_STELLAR_SDK_PATH / "protocols" / "rpc"

# Known RPC method list with their file mappings
# Some methods have different file names in different versions
KNOWN_METHODS = {
    "getHealth": ["get_health.go", "health.go"],  # v25+ uses get_health.go, v21-v24 uses health.go
    "getNetwork": "get_network.go",
    "getVersionInfo": "get_version_info.go",
    "getFeeStats": "get_fee_stats.go",
    "getLatestLedger": "get_latest_ledger.go",
    "getLedgerEntries": "get_ledger_entries.go",
    "getLedgers": "get_ledgers.go",
    "getEvents": "get_events.go",
    "getTransaction": "get_transaction.go",
    "getTransactions": "get_transactions.go",
    "sendTransaction": "send_transaction.go",
    "simulateTransaction": "simulate_transaction.go",
}


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


@dataclass
class Parameter:
    """Represents a method parameter."""
    name: str
    type: str
    description: str
    required: bool = False
    default: Optional[str] = None


@dataclass
class Field:
    """Represents a response field."""
    name: str
    type: str
    description: str


@dataclass
class MethodSpec:
    """Represents an RPC method specification."""
    name: str
    description: str
    handler_file: str
    parameters: dict[str, list[Parameter]] = field(default_factory=lambda: {"required": [], "optional": []})
    response: dict[str, Any] = field(default_factory=dict)
    introduced_in: str = ""
    last_modified: str = ""
    notes: str = ""

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary."""
        result = {
            "name": self.name,
            "description": self.description,
            "handler_file": self.handler_file,
            "parameters": {
                "required": [asdict(p) for p in self.parameters["required"]],
                "optional": [asdict(p) for p in self.parameters["optional"]]
            },
            "response": self.response,
            "introduced_in": self.introduced_in,
            "last_modified": self.last_modified,
        }
        if self.notes:
            result["notes"] = self.notes
        return result


class NotFoundError(RuntimeError):
    """The requested file or directory does not exist at the given ref (HTTP 404)."""


class GitHubFetcher:
    """Handles fetching files from GitHub."""

    def __init__(self, token: Optional[str] = None, verbose: bool = False):
        # Auto-detect token if not explicitly provided
        self.token = token if token else get_github_token()
        self.verbose = verbose
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": "stellar-php-sdk-compatibility-tools"})
        if self.token:
            self.session.headers.update({"Authorization": f"Bearer {self.token}"})
            if verbose:
                print("Authentication: Enabled (5,000 requests/hour)")
        elif verbose:
            print("Authentication: Not configured (60 requests/hour)")
            print("  Tip: Set GITHUB_TOKEN env var for higher rate limits")

    def fetch_go_stellar_sdk_protocol_file(self, method_name: str, ref: str) -> str:
        """Fetch the protocol file that defines a method's request and response types from go-stellar-sdk at ref."""
        # Map method name to protocol file
        protocol_files = {
            "getLedgerEntries": "get_ledger_entries.go",
            "getLedgers": "get_ledgers.go",
            "getEvents": "get_events.go",
            "getTransaction": "get_transaction.go",
            "getTransactions": "get_transactions.go",
            "sendTransaction": "send_transaction.go",
            "simulateTransaction": "simulate_transaction.go",
            "getHealth": "get_health.go",
            "getNetwork": "get_network.go",
            "getVersionInfo": "get_version_info.go",
            "getFeeStats": "get_fee_stats.go",
            "getLatestLedger": "get_latest_ledger.go",
        }

        protocol_file = protocol_files.get(method_name)
        if not protocol_file:
            raise ValueError(f"No go-stellar-sdk protocol file is mapped for {method_name}")

        url = f"{GITHUB_RAW_BASE}/stellar/go-stellar-sdk/{ref}/protocols/rpc/{protocol_file}"

        if self.verbose:
            print(f"  Fetching protocol file: protocols/rpc/{protocol_file}")

        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            raise RuntimeError(f"Failed to fetch go-stellar-sdk protocols/rpc/{protocol_file} at {ref}: {e}") from e

    def resolve_rpc_version(self, override: Optional[str] = None) -> str:
        """
        Return the stellar-rpc release tag to extract from.

        Without an override, the newest stable release. An override must name a
        non-draft release; a prerelease is allowed.
        """
        releases = fetch_releases(REPO_OWNER, REPO_NAME, self.token)
        if override:
            release = find_release(releases, override, f"{REPO_OWNER}/{REPO_NAME}")
            if release.prerelease:
                print(f"Note: {release.version} is a prerelease")
        else:
            release = select_newest_stable(releases, f"{REPO_OWNER}/{REPO_NAME}")
        if self.verbose:
            print(f"stellar-rpc version: {release.version}")
        return release.version

    def get_latest_go_stellar_sdk_release(self) -> str:
        """Return the newest stable go-stellar-sdk release tag (the protocols module is
        versioned as vX.Y.Z). Protocol param definitions are read from this released
        ref, so fields not yet in a released RPC are not measured."""
        release = select_newest_stable(fetch_releases("stellar", "go-stellar-sdk", self.token), "stellar/go-stellar-sdk")
        if self.verbose:
            print(f"Latest go-stellar-sdk release: {release.version}")
        return release.version

    def get_latest_commit_hash(self, branch: str = DEFAULT_BRANCH) -> str:
        """Fetch the latest commit hash for a branch."""
        url = f"{GITHUB_API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/commits/{branch}"
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            commit_data = response.json()
            commit_hash = commit_data["sha"][:8]
            if self.verbose:
                print(f"Latest commit: {commit_hash}")
            return commit_hash
        except requests.RequestException as e:
            raise RuntimeError(f"Failed to fetch commit hash: {e}") from e

    def fetch_file(self, file_path: str, ref: str) -> str:
        """Fetch a file from the repository at ref. Raises NotFoundError when the file does not exist at ref."""
        url = f"{GITHUB_RAW_BASE}/{REPO_OWNER}/{REPO_NAME}/{ref}/{file_path}"

        if self.verbose:
            print(f"Fetching: {file_path}")

        try:
            response = self.session.get(url, timeout=30)
            if response.status_code == 404:
                raise NotFoundError(f"{file_path} does not exist at {ref}")
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            raise RuntimeError(f"Failed to fetch {file_path}: {e}") from e

    def list_directory(self, dir_path: str, ref: str) -> list[dict[str, Any]]:
        """List directory contents at ref via GitHub API. Raises NotFoundError when the directory does not exist at ref."""
        url = f"{GITHUB_API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/contents/{dir_path}?ref={ref}"

        if self.verbose:
            print(f"Listing directory: {dir_path}")

        try:
            response = self.session.get(url, timeout=30)
            if response.status_code == 404:
                raise NotFoundError(f"{dir_path} does not exist at {ref}")
            response.raise_for_status()
            listing = response.json()
        except requests.RequestException as e:
            raise RuntimeError(f"Failed to list directory {dir_path}: {e}") from e
        if not isinstance(listing, list):
            raise RuntimeError(f"Directory listing of {dir_path} is not a list")
        return listing


class GoSourceParser:
    """Parses Go source files to extract RPC method specifications."""

    def __init__(self, verbose: bool = False, go_stellar_sdk_path: Optional[Path] = None):
        self.verbose = verbose
        self.protocol_source = None  # Cache for protocol file source
        
        # Initialize the response struct parser if path is provided
        self.response_parser = None
        if go_stellar_sdk_path and go_stellar_sdk_path.exists():
            self.response_parser = ResponseStructParser(go_stellar_sdk_path, verbose=verbose)
            if verbose:
                print("ResponseStructParser initialized successfully")

    def set_protocol_source(self, protocol_source: str):
        """Set the protocol file source for extracting external type definitions."""
        self.protocol_source = protocol_source

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

        # Extract description from comments
        description = self._extract_description(go_source, method_name)

        # Extract parameters from request struct
        parameters = self._extract_parameters(go_source, method_name)

        # Extract response structure
        response = self._extract_response(go_source, method_name)

        method_spec = MethodSpec(
            name=method_name,
            description=description,
            handler_file=handler_file,
            parameters=parameters,
            response=response
        )

        return method_spec

    def _extract_description(self, go_source: str, method_name: str) -> str:
        """Extract method description from comments."""
        # Look for comments above the Handler function or Request struct
        patterns = [
            # Look for comment above Handler function
            rf'//\s*(.+?)[\r\n]+func\s+\(.*?\)\s*{re.escape(method_name)}Handler',
            # Look for comment above NewXHandler function
            rf'//\s*(.+?)[\r.n]+func\s+New[A-Z]\w*Handler',
            # Look for package-level comments
            r'//\s*Package\s+methods\s+(.+)',
        ]

        for pattern in patterns:
            match = re.search(pattern, go_source, re.MULTILINE | re.IGNORECASE)
            if match:
                return match.group(1).strip()

        # Fallback to generic description
        return f"RPC method: {method_name}"

    def _extract_parameters(self, go_source: str, method_name: str) -> dict[str, list[Parameter]]:
        """
        Extract method parameters from the request struct.

        Every method has a request struct, declared as an empty struct{} when the
        method takes no parameters. Raises when neither the handler source nor the
        protocol source declares it.
        """
        parameters = {"required": [], "optional": []}

        # Convert method name to struct name (e.g., getHealth -> GetHealthRequest)
        struct_name = self._method_to_struct_name(method_name) + "Request"

        # Find the request struct definition - first try handler file, then protocol source
        struct_pattern = rf'type\s+{struct_name}\s+struct\s*\{{([^}}]*)\}}'
        match = re.search(struct_pattern, go_source, re.DOTALL)

        # If not found and we have protocol source, try that
        if not match and self.protocol_source:
            match = re.search(struct_pattern, self.protocol_source, re.DOTALL)

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
            field_name = field_match.group(1)
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

            # Get better type description and parameter description
            param_type = self._go_type_to_json_type(field_type)
            param_description = self._generate_parameter_description(method_name, json_name, field_type)

            param = Parameter(
                name=json_name,
                type=param_type,
                description=param_description,
                required=not is_optional
            )

            if is_optional:
                parameters["optional"].append(param)
            else:
                parameters["required"].append(param)

        if self.verbose:
            req_count = len(parameters["required"])
            opt_count = len(parameters["optional"])
            print(f"    Found {req_count} required, {opt_count} optional parameters")

        return parameters

    def _generate_parameter_description(self, method_name: str, param_name: str, go_type: str) -> str:
        """Generate a descriptive parameter description based on context."""
        # Map common parameter names to descriptions
        descriptions = {
            "keys": "Array of ledger entry keys to fetch (base64-encoded XDR)",
            "hash": "Transaction hash to retrieve",
            "transaction": "Base64-encoded transaction envelope XDR",
            "startLedger": "Starting ledger sequence number (inclusive)",
            "endLedger": "Ending ledger sequence number (exclusive)",
            "filters": "Event filters to apply",
            "pagination": "Pagination options (cursor and limit)",
            "cursor": "Pagination cursor",
            "limit": "Maximum number of results to return",
            "resourceConfig": "Resource configuration for simulation",
            "authMode": "Authorization mode (enforce, record, or record_allow_nonroot)",
            "xdrFormat": "Output format (xdr or json)",
        }

        # Use predefined description if available
        if param_name in descriptions:
            return descriptions[param_name]

        # Generate generic description
        return f"Parameter: {param_name}"

    def _extract_response(self, go_source: str, method_name: str) -> dict[str, Any]:
        """
        Extract the response structure.

        Sources in order: the local go-stellar-sdk checkout, the handler source, the
        protocol source. Raises when no source holds a response struct with at least
        one JSON field.
        """
        # Use ResponseStructParser if available
        if self.response_parser:
            response_struct = self.response_parser.parse_response_struct(method_name)
            if response_struct and response_struct.get("fields"):
                return response_struct
        
        # Fallback to old parsing logic if ResponseStructParser not available or fails
        # Try multiple naming patterns for response struct
        struct_names = [
            self._method_to_struct_name(method_name) + "Response",  # GetNetworkResponse
            self._method_to_struct_name(method_name) + "Result",    # HealthCheckResult
        ]

        # Also look for special cases
        if method_name == "getHealth":
            struct_names.insert(0, "HealthCheckResult")

        struct_body = None
        struct_name = None

        # First try to find in the handler file itself
        for name in struct_names:
            # Find the response struct definition
            struct_pattern = rf'type\s+{name}\s+struct\s*\{{([^}}]+)\}}'
            match = re.search(struct_pattern, go_source, re.DOTALL)
            if match:
                struct_body = match.group(1)
                struct_name = name
                break

        # If not found and we have protocol source, try that
        if not struct_body and self.protocol_source:
            for name in struct_names:
                struct_pattern = rf'type\s+{name}\s+struct\s*\{{([^}}]+)\}}'
                match = re.search(struct_pattern, self.protocol_source, re.DOTALL)
                if match:
                    struct_body = match.group(1)
                    struct_name = name
                    break

        if not struct_body:
            raise ValueError(
                f"Response struct ({', '.join(struct_names)}) for {method_name} not found in the local "
                "go-stellar-sdk checkout, the handler source, or the protocol source"
            )

        # Parse each field in the struct
        fields = []
        field_pattern = r'(\w+)\s+([\w\[\]\.\*]+)\s*`json:"([^"]+)"([^`]*)`'

        for field_match in re.finditer(field_pattern, struct_body):
            field_name = field_match.group(1)
            field_type = field_match.group(2)
            json_tag = field_match.group(3)
            tags = field_match.group(4)

            # Extract just the field name from json tag (remove omitempty, etc.)
            json_name = json_tag.split(',')[0]

            # Skip if json:"-" (not serialized)
            if json_name == "-":
                continue

            fields.append({
                "name": json_name,
                "type": self._go_type_to_json_type(field_type),
                "description": f"Field: {json_name}"
            })

        if not fields:
            raise ValueError(f"Response struct {struct_name} for {method_name} has no JSON fields")

        return {
            "type": "object",
            "fields": fields,
            "nested_types": {}
        }

    def _method_to_struct_name(self, method_name: str) -> str:
        """Convert method name to struct name."""
        # getHealth -> GetHealth
        # getFeeStats -> GetFeeStats
        if not method_name:
            return ""
        return method_name[0].upper() + method_name[1:]

    def _go_type_to_json_type(self, go_type: str) -> str:
        """Convert Go type to JSON type description."""
        # Remove pointer indicators
        go_type = go_type.lstrip('*')

        # Handle arrays
        if go_type.startswith('[]'):
            inner_type = go_type[2:]
            return f"array[{self._go_type_to_json_type(inner_type)}]"

        # Map Go types to JSON types
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
        }

        return type_map.get(go_type, go_type)


class RPCMethodExtractor:
    """Main extraction orchestrator."""

    def __init__(self, github_token: Optional[str] = None, verbose: bool = False):
        self.fetcher = GitHubFetcher(token=github_token, verbose=verbose)
        self.parser = GoSourceParser(verbose=verbose, go_stellar_sdk_path=GO_STELLAR_SDK_PATH)
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

        self._fetch_protocol_files(rpc_version)

        # Protocol param definitions live in go-stellar-sdk. Read them from its newest
        # stable release so unreleased fields are not measured against the SDK.
        go_sdk_version = self.fetcher.get_latest_go_stellar_sdk_release()

        methods = {}
        for method_name, file_names in KNOWN_METHODS.items():
            # Support both single file name and list of file names
            if isinstance(file_names, str):
                file_names = [file_names]

            try:
                method_spec = self._extract_method(method_name, file_names, rpc_version, go_sdk_version)
            except Exception as e:
                raise RuntimeError(f"Failed to extract {method_name}: {e}") from e
            methods[method_name] = method_spec.to_dict()

        # KNOWN_METHODS must match the methods the extracted release registers.
        check_method_set(self._registered_methods(rpc_version))

        # Build output structure
        output = {
            "metadata": {
                "source": "stellar-rpc",
                "repository": f"https://github.com/{REPO_OWNER}/{REPO_NAME}",
                "version": rpc_version,
                "extracted_date": datetime.now().strftime("%Y-%m-%d"),
                "total_methods": len(methods),
                "protocol": "JSON-RPC 2.0",
                "protocol_definitions": f"https://github.com/stellar/go-stellar-sdk/tree/{go_sdk_version}/protocols/rpc"
            },
            "methods": methods
        }

        if self.verbose:
            print(f"\nExtraction complete: {len(methods)} methods")
            print(f"stellar-rpc version: {rpc_version}")

        return output

    def _fetch_protocol_files(self, rpc_version: str):
        """
        Load the Go files of the stellar-rpc PROTOCOL_DIR at rpc_version into the parser.

        A release without the directory (HTTP 404) adds no source here. Any other
        listing or file fetch failure raises.
        """
        try:
            files = self.fetcher.list_directory(PROTOCOL_DIR, rpc_version)
        except NotFoundError:
            if self.verbose:
                print(f"No stellar-rpc {PROTOCOL_DIR} directory at {rpc_version}")
            return

        sources = []
        for file_info in files:
            if file_info.get("type") == "file" and file_info.get("name", "").endswith(".go"):
                sources.append(self.fetcher.fetch_file(f"{PROTOCOL_DIR}/{file_info['name']}", rpc_version))
                if self.verbose:
                    print(f"  Loaded protocol file: {file_info['name']}")

        if sources:
            self.parser.set_protocol_source("\n\n".join(sources))

    def _registered_methods(self, rpc_version: str) -> list[str]:
        """
        Return the JSON-RPC method names that stellar-rpc registers in jsonrpc.go at rpc_version.

        The file sits next to a METHODS_DIRS handler directory; a directory without it
        (HTTP 404) is skipped. Raises when no directory has the file, on any other fetch
        failure, and when the file holds no protocol.<Name>MethodName registrations.
        """
        for methods_dir in METHODS_DIRS:
            registration_path = methods_dir.removesuffix("/methods") + "/jsonrpc.go"
            try:
                registration_source = self.fetcher.fetch_file(registration_path, rpc_version)
                break
            except NotFoundError:
                continue
        else:
            raise RuntimeError(f"No jsonrpc.go registration file at {rpc_version}")

        registered = re.findall(
            r"\bmethodName:\s*protocol\.([A-Za-z][A-Za-z0-9]*)MethodName\b",
            registration_source,
        )
        if not registered:
            raise RuntimeError(f"No protocol.<Name>MethodName registrations found in jsonrpc.go at {rpc_version}")
        return [name[0].lower() + name[1:] for name in registered]

    def _extract_method(self, method_name: str, file_names: list[str], rpc_version: str, go_sdk_version: str) -> MethodSpec:
        """
        Extract a single method specification.

        The handler is the first candidate file that exists at rpc_version. A
        candidate that does not exist (HTTP 404) is skipped; any other fetch
        failure raises.
        """
        candidates = [f"{methods_dir}/{file_name}" for file_name in file_names for methods_dir in METHODS_DIRS]
        for handler_file in candidates:
            try:
                go_source = self.fetcher.fetch_file(handler_file, rpc_version)
                break
            except NotFoundError:
                continue
        else:
            raise RuntimeError(f"No handler file at {rpc_version}; tried {', '.join(candidates)}")

        # The go-stellar-sdk protocol file defines the request and response types.
        protocol_source = self.fetcher.fetch_go_stellar_sdk_protocol_file(method_name, go_sdk_version)
        if self.parser.protocol_source:
            self.parser.protocol_source += "\n\n" + protocol_source
        else:
            self.parser.set_protocol_source(protocol_source)

        return self.parser.parse_method_handler(method_name, go_source, handler_file)


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
