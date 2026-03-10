#!/usr/bin/env python3
"""
Stellar RPC API vs iOS/macOS SDK Compatibility Matrix Generator

This script compares the Stellar RPC API methods with the iOS/macOS SDK Soroban implementation
and generates a detailed compatibility matrix with coverage statistics.

Analyzes actual Swift source code to extract method signatures and response fields.

Author: Stellar iOS/macOS SDK Team
License: Apache-2.0
"""

import json
import plistlib
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional, Set
from dataclasses import dataclass, field
from enum import Enum


class SupportStatus(Enum):
    """Support status for RPC methods"""
    FULLY_SUPPORTED = "Full"
    PARTIALLY_SUPPORTED = "Partial"
    NOT_SUPPORTED = "Missing"


@dataclass
class RPCVersionInfo:
    """RPC version information from GitHub"""
    version: str
    release_date: str
    html_url: str


@dataclass
class SDKMethod:
    """Parsed SDK method information"""
    name: str
    rpc_method: str
    parameters: List[str]
    response_type: str
    line_number: int


@dataclass
class SDKResponseType:
    """Parsed SDK response type information"""
    name: str
    fields: List[str]  # JSON field names from CodingKeys


@dataclass
class MethodComparison:
    """Comparison data for a single RPC method"""
    rpc_method: str
    sdk_method: str
    sdk_params: List[str]
    response_type: str
    status: SupportStatus
    rpc_required_params: List[str]
    rpc_optional_params: List[str]
    sdk_supported_params: List[str]
    rpc_response_fields: List[str]
    sdk_response_fields: List[str]
    missing_params: List[str]
    missing_fields: List[str]
    notes: str
    category: str


def fetch_rpc_version() -> RPCVersionInfo:
    """Fetch the latest RPC version from GitHub releases API"""
    url = "https://api.github.com/repos/stellar/stellar-rpc/releases"

    try:
        request = urllib.request.Request(url)
        request.add_header('User-Agent', 'stellar-ios-sdk-compatibility-checker')

        with urllib.request.urlopen(request, timeout=10) as response:
            releases = json.loads(response.read().decode('utf-8'))

            # Find the latest release that starts with 'v' (not rpcclient)
            for release in releases:
                tag = release.get('tag_name', '')
                if tag.startswith('v') and not tag.startswith('rpcclient'):
                    published = release.get('published_at', '')[:10]
                    return RPCVersionInfo(
                        version=tag,
                        release_date=published,
                        html_url=release.get('html_url', '')
                    )

    except (urllib.error.URLError, json.JSONDecodeError) as e:
        print(f"Warning: Could not fetch RPC version from GitHub: {e}")

    # Fallback to hardcoded version
    return RPCVersionInfo(
        version="v25.0.0",
        release_date="2025-12-12",
        html_url="https://github.com/stellar/stellar-rpc/releases/tag/v25.0.0"
    )


def get_sdk_version(sdk_root: Path) -> str:
    """Extract SDK version from Info.plist"""
    plist_path = sdk_root / "stellarsdk" / "stellarsdk" / "Info.plist"
    try:
        with open(plist_path, 'rb') as f:
            plist = plistlib.load(f)
            return plist.get('CFBundleShortVersionString', '3.4.2')
    except Exception:
        return "3.4.2"


# RPC method categories for organization
METHOD_CATEGORIES = {
    "sendTransaction": "Transaction Methods",
    "simulateTransaction": "Transaction Methods",
    "getTransaction": "Transaction Methods",
    "getTransactions": "Transaction Methods",
    "getLatestLedger": "Ledger Methods",
    "getLedgers": "Ledger Methods",
    "getLedgerEntries": "Ledger Methods",
    "getEvents": "Event Methods",
    "getNetwork": "Network Info Methods",
    "getVersionInfo": "Network Info Methods",
    "getFeeStats": "Network Info Methods",
    "getHealth": "Network Info Methods",
}


def load_rpc_methods(json_path: Path) -> Dict[str, Any]:
    """Load RPC method definitions from JSON file"""
    if not json_path.exists():
        raise FileNotFoundError(f"RPC methods file not found: {json_path}")

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    return data


# RPC parameters to ignore (optional params with sensible defaults)
IGNORED_RPC_PARAMS = {"xdrFormat"}

# SDK parameters to ignore in count (correspond to ignored RPC params)
IGNORED_SDK_PARAMS = {"format"}  # format maps to xdrFormat

# Response field suffixes to ignore (SDK decodes XDR directly, doesn't need JSON variants)
IGNORED_FIELD_SUFFIXES = ("Json",)

# SDK response fields to ignore (legacy aliases for backwards compatibility)
IGNORED_SDK_FIELDS = {
    # getVersionInfo - protocol 21 snake_case aliases
    "commit_hash",
    "build_time_stamp",
    "captive_core_version",
    "protocol_version",
}

# Parameter name mappings (SDK param name -> RPC param name)
PARAM_MAPPINGS = {
    "base64EncodedKeys": "keys",
    "transactionHash": "hash",
    "simulateTxRequest": "transaction",  # Contains transaction and optional params
    "eventFilters": "filters",
    "paginationOptions": "pagination",
    "format": "xdrFormat",
}

# SDK params that wrap multiple RPC params (for counting purposes)
# Maps SDK param name -> list of underlying RPC params it contains
REQUEST_OBJECT_PARAMS = {
    "simulateTxRequest": ["transaction", "resourceConfig", "authMode"],
}


class SwiftSourceAnalyzer:
    """Analyzes Swift source code to extract SDK implementation details"""

    def __init__(self, sdk_root: Path):
        self.sdk_root = sdk_root
        self.soroban_path = sdk_root / "stellarsdk" / "stellarsdk" / "soroban"
        self.methods: Dict[str, SDKMethod] = {}
        self.response_types: Dict[str, SDKResponseType] = {}

    def analyze(self) -> None:
        """Analyze SDK source code"""
        self._parse_soroban_server()
        self._parse_response_types()

    def _parse_soroban_server(self) -> None:
        """Parse SorobanServer.swift to extract method signatures"""
        server_path = self.soroban_path / "SorobanServer.swift"
        if not server_path.exists():
            print(f"Warning: SorobanServer.swift not found at {server_path}")
            return

        content = server_path.read_text()

        # Pattern to match public async methods
        # public func methodName(param1: Type1, param2: Type2? = nil) async -> ResponseEnum
        pattern = r'public\s+func\s+(\w+)\s*\(([^)]*)\)\s*async\s*->\s*(\w+)'

        for match in re.finditer(pattern, content):
            method_name = match.group(1)
            params_str = match.group(2)
            response_enum = match.group(3)

            # Extract parameter names
            params = []
            if params_str.strip():
                # Parse each parameter
                for param in params_str.split(','):
                    param = param.strip()
                    # Extract parameter name (before the colon)
                    param_match = re.match(r'(\w+)\s*:', param)
                    if param_match:
                        params.append(param_match.group(1))

            # Extract response type from enum name (e.g., GetHealthResponseEnum -> GetHealthResponse)
            response_type = response_enum.replace('Enum', '')

            # Map method name to RPC method name
            rpc_method = method_name

            self.methods[rpc_method] = SDKMethod(
                name=method_name,
                rpc_method=rpc_method,
                parameters=params,
                response_type=response_type,
                line_number=content[:match.start()].count('\n') + 1
            )

    def _parse_response_types(self) -> None:
        """Parse response Swift files to extract field definitions"""
        responses_path = self.soroban_path / "responses"
        if not responses_path.exists():
            print(f"Warning: responses directory not found at {responses_path}")
            return

        for swift_file in responses_path.glob("*.swift"):
            self._parse_response_file(swift_file)

    def _parse_response_file(self, file_path: Path) -> None:
        """Parse a single response file to extract CodingKeys"""
        content = file_path.read_text()

        # Find struct name
        struct_match = re.search(r'public\s+struct\s+(\w+Response)\s*:', content)
        if not struct_match:
            return

        struct_name = struct_match.group(1)

        # Find CodingKeys enum
        coding_keys_match = re.search(
            r'private\s+enum\s+CodingKeys\s*:\s*String\s*,\s*CodingKey\s*\{([^}]+)\}',
            content,
            re.DOTALL
        )

        fields = []
        if coding_keys_match:
            keys_content = coding_keys_match.group(1)
            # Extract case names and their raw values
            # Pattern: case fieldName = "jsonKey" or just case fieldName
            for case_match in re.finditer(r'case\s+(\w+)(?:\s*=\s*"([^"]+)")?', keys_content):
                case_name = case_match.group(1)
                raw_value = case_match.group(2)
                # Use raw value if present, otherwise use case name
                json_key = raw_value if raw_value else case_name
                fields.append(json_key)

        self.response_types[struct_name] = SDKResponseType(
            name=struct_name,
            fields=fields
        )


class RPCMatrixGenerator:
    """Generator for RPC compatibility matrix"""

    def __init__(self, sdk_root: Path, rpc_methods_file: Path):
        self.sdk_root = sdk_root
        self.rpc_methods_file = rpc_methods_file
        self.rpc_data: Dict[str, Any] = {}
        self.rpc_version = fetch_rpc_version()
        self.sdk_version = get_sdk_version(sdk_root)
        self.analyzer = SwiftSourceAnalyzer(sdk_root)
        self.comparisons: List[MethodComparison] = []

    def analyze(self) -> None:
        """Analyze SDK implementation against RPC API"""
        # Load RPC methods from JSON
        print(f"  Loading RPC methods from: {self.rpc_methods_file.name}")
        self.rpc_data = load_rpc_methods(self.rpc_methods_file)

        # Update RPC version from JSON if available
        metadata = self.rpc_data.get("metadata", {})
        if metadata.get("rpc_version"):
            self.rpc_version = RPCVersionInfo(
                version=metadata.get("rpc_version", self.rpc_version.version),
                release_date=metadata.get("rpc_release_date", self.rpc_version.release_date),
                html_url=metadata.get("rpc_release_url", self.rpc_version.html_url)
            )

        print("  Parsing Swift source files...")
        self.analyzer.analyze()

        print(f"  Found {len(self.analyzer.methods)} SDK methods")
        print(f"  Found {len(self.analyzer.response_types)} response types")

        rpc_methods = self.rpc_data.get("methods", {})
        for rpc_method, rpc_def in rpc_methods.items():
            sdk_method = self.analyzer.methods.get(rpc_method)

            # Extract response field names from the new JSON structure
            # New format: {"response": {"fields": [{"name": "fieldName", ...}]}}
            # Old format: {"response_fields": [{"json_name": "fieldName"}]}
            rpc_response_field_names = []
            response_data = rpc_def.get("response", {})
            if isinstance(response_data, dict):
                fields = response_data.get("fields", [])
                for field in fields:
                    if isinstance(field, dict):
                        # New format uses "name", old format uses "json_name"
                        field_name = field.get("name") or field.get("json_name", "")
                        if field_name:
                            # Skip JSON variant fields (SDK decodes XDR directly)
                            if not field_name.endswith(IGNORED_FIELD_SUFFIXES):
                                rpc_response_field_names.append(field_name)
            else:
                # Fallback for old format
                rpc_response_fields_raw = rpc_def.get("response_fields", [])
                for field in rpc_response_fields_raw:
                    if isinstance(field, dict):
                        field_name = field.get("json_name", "")
                    else:
                        field_name = field
                    # Skip JSON variant fields
                    if field_name and not field_name.endswith(IGNORED_FIELD_SUFFIXES):
                        rpc_response_field_names.append(field_name)

            # Extract parameters from new format
            # New format: {"parameters": {"required": [...], "optional": [...]}}
            # Old format: {"required_params": [...], "optional_params": [...]}
            params_data = rpc_def.get("parameters", {})
            if isinstance(params_data, dict) and ("required" in params_data or "optional" in params_data):
                # New format - filter out ignored params
                rpc_required_list = [p.get("name", p) if isinstance(p, dict) else p
                                     for p in params_data.get("required", [])
                                     if (p.get("name", p) if isinstance(p, dict) else p) not in IGNORED_RPC_PARAMS]
                rpc_optional_list = [p.get("name", p) if isinstance(p, dict) else p
                                     for p in params_data.get("optional", [])
                                     if (p.get("name", p) if isinstance(p, dict) else p) not in IGNORED_RPC_PARAMS]
            else:
                # Old format - filter out ignored params
                rpc_required_list = [p for p in rpc_def.get("required_params", []) if p not in IGNORED_RPC_PARAMS]
                rpc_optional_list = [p for p in rpc_def.get("optional_params", []) if p not in IGNORED_RPC_PARAMS]

            if sdk_method:
                # Get response type fields
                response_type = sdk_method.response_type
                sdk_response = self.analyzer.response_types.get(response_type)
                sdk_fields = sdk_response.fields if sdk_response else []

                # Map SDK params to RPC params
                sdk_params = sdk_method.parameters
                sdk_mapped_params = set()
                for param in sdk_params:
                    mapped = PARAM_MAPPINGS.get(param, param)
                    sdk_mapped_params.add(mapped)
                    # Special handling for simulateTxRequest which contains multiple RPC params
                    if param == "simulateTxRequest":
                        sdk_mapped_params.add("transaction")
                        sdk_mapped_params.add("resourceConfig")
                        sdk_mapped_params.add("authMode")
                    if param == "paginationOptions":
                        sdk_mapped_params.add("pagination")
                        sdk_mapped_params.add("cursor")
                        sdk_mapped_params.add("limit")

                # Check required params
                rpc_required = set(rpc_required_list)
                rpc_optional = set(rpc_optional_list)
                rpc_all_params = rpc_required | rpc_optional

                missing_required = rpc_required - sdk_mapped_params
                missing_optional = rpc_optional - sdk_mapped_params
                missing_params = list(missing_required | missing_optional)

                # Check response fields
                rpc_fields = set(rpc_response_field_names)
                sdk_field_set = set(sdk_fields)
                missing_fields = list(rpc_fields - sdk_field_set)

                # Determine status
                if missing_required:
                    status = SupportStatus.NOT_SUPPORTED
                elif missing_params or missing_fields:
                    status = SupportStatus.PARTIALLY_SUPPORTED
                else:
                    status = SupportStatus.FULLY_SUPPORTED

                # Generate notes
                notes = self._generate_notes(rpc_method, missing_params, missing_fields)

                # Format SDK method signature
                if sdk_params:
                    params_str = ", ".join(f"{p}:" for p in sdk_params)
                    sdk_method_str = f"{sdk_method.name}({params_str})"
                else:
                    sdk_method_str = f"{sdk_method.name}()"

                comparison = MethodComparison(
                    rpc_method=rpc_method,
                    sdk_method=sdk_method_str,
                    sdk_params=sdk_params,
                    response_type=response_type,
                    status=status,
                    rpc_required_params=rpc_required_list,
                    rpc_optional_params=rpc_optional_list,
                    sdk_supported_params=list(sdk_mapped_params),
                    rpc_response_fields=rpc_response_field_names,
                    sdk_response_fields=sdk_fields,
                    missing_params=missing_params,
                    missing_fields=missing_fields,
                    notes=notes,
                    category=METHOD_CATEGORIES.get(rpc_method, "Other")
                )
            else:
                # Method not implemented
                comparison = MethodComparison(
                    rpc_method=rpc_method,
                    sdk_method="-",
                    sdk_params=[],
                    response_type="-",
                    status=SupportStatus.NOT_SUPPORTED,
                    rpc_required_params=rpc_required_list,
                    rpc_optional_params=rpc_optional_list,
                    sdk_supported_params=[],
                    rpc_response_fields=rpc_response_field_names,
                    sdk_response_fields=[],
                    missing_params=rpc_required_list + rpc_optional_list,
                    missing_fields=rpc_response_field_names,
                    notes="Method not implemented",
                    category=METHOD_CATEGORIES.get(rpc_method, "Other")
                )

            self.comparisons.append(comparison)

    def _generate_notes(self, method: str, missing_params: List[str], missing_fields: List[str]) -> str:
        """Generate notes based on implementation status"""
        notes = []

        # Method-specific notes
        method_notes = {
            "sendTransaction": "Full support for all response fields including diagnosticEvents, errorResult.",
            "simulateTransaction": "Supports transaction, resourceConfig (instructionLeeway), and authMode (protocol 23+).",
            "getTransaction": "Full support including protocol 23+ events field, computed properties.",
            "getTransactions": "Full pagination support with cursor and limit.",
            "getLatestLedger": "Returns id, protocolVersion, and sequence.",
            "getLedgers": "Full pagination support with cursor and limit.",
            "getLedgerEntries": "Supports up to 200 keys, returns entries with TTL info.",
            "getEvents": "Full support including endLedger, event filters (type, contractIds, topics), pagination.",
            "getNetwork": "Returns friendbotUrl (optional), passphrase, and protocolVersion.",
            "getVersionInfo": "Protocol 23 compliant (camelCase fields only).",
            "getFeeStats": "Full support for sorobanInclusionFee and inclusionFee statistics.",
            "getHealth": "Full support for all fields.",
        }

        if method in method_notes and not missing_params and not missing_fields:
            return method_notes[method]

        if missing_params:
            notes.append(f"Missing params: {', '.join(missing_params)}")
        if missing_fields:
            notes.append(f"Missing fields: {', '.join(missing_fields)}")

        return "; ".join(notes) if notes else "All parameters and response fields implemented"

    def generate_markdown(self, output_path: Path) -> None:
        """Generate markdown compatibility matrix"""
        br = "  "  # Two spaces for markdown line break

        # Calculate statistics
        total = len(self.comparisons)
        fully_supported = sum(1 for c in self.comparisons if c.status == SupportStatus.FULLY_SUPPORTED)
        partially_supported = sum(1 for c in self.comparisons if c.status == SupportStatus.PARTIALLY_SUPPORTED)
        not_supported = sum(1 for c in self.comparisons if c.status == SupportStatus.NOT_SUPPORTED)
        coverage = (fully_supported / total * 100) if total > 0 else 0

        lines = [
            "# Soroban RPC vs iOS/macOS SDK Compatibility Matrix",
            "",
            f"**RPC Version:** {self.rpc_version.version} (released {self.rpc_version.release_date}){br}",
            f"**RPC Source:** [{self.rpc_version.version}]({self.rpc_version.html_url}){br}",
            f"**SDK Version:** {self.sdk_version}{br}",
            f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "## Overall Coverage",
            "",
            f"**Coverage:** {coverage:.1f}%",
            "",
            f"- **Fully Supported:** {fully_supported}/{total}",
            f"- **Partially Supported:** {partially_supported}/{total}",
            f"- **Not Supported:** {not_supported}/{total}",
            "",
            "## Method Comparison",
            "",
        ]

        # Group by category
        categories = {}
        for comp in self.comparisons:
            if comp.category not in categories:
                categories[comp.category] = []
            categories[comp.category].append(comp)

        # Define category order
        category_order = [
            "Transaction Methods",
            "Ledger Methods",
            "Event Methods",
            "Network Info Methods",
        ]

        for category in category_order:
            if category not in categories:
                continue

            lines.append(f"### {category}")
            lines.append("")
            lines.append("| RPC Method | Status | SDK Method | Response Type | Notes |")
            lines.append("|------------|--------|------------|---------------|-------|")

            for comp in sorted(categories[category], key=lambda x: x.rpc_method):
                status_str = comp.status.value
                lines.append(
                    f"| {comp.rpc_method} | {status_str} | `{comp.sdk_method}` | {comp.response_type} | {comp.notes} |"
                )

            lines.append("")

        # Parameter Coverage
        lines.extend([
            "## Parameter Coverage",
            "",
            "Detailed breakdown of parameter support per method.",
            "",
            "| RPC Method | RPC Params | SDK Params | Missing |",
            "|------------|------------|------------|---------|",
        ])

        for comp in sorted(self.comparisons, key=lambda x: x.rpc_method):
            rpc_total = len(comp.rpc_required_params) + len(comp.rpc_optional_params)
            # Expand request object params and filter ignored params
            sdk_expanded = []
            for p in comp.sdk_params:
                if p in IGNORED_SDK_PARAMS:
                    continue
                if p in REQUEST_OBJECT_PARAMS:
                    sdk_expanded.extend(REQUEST_OBJECT_PARAMS[p])
                else:
                    sdk_expanded.append(p)
            sdk_count = len(sdk_expanded)
            missing = ", ".join(comp.missing_params) if comp.missing_params else "-"
            lines.append(
                f"| {comp.rpc_method} | {rpc_total} | {sdk_count} | {missing} |"
            )

        lines.append("")

        # Response Field Coverage
        lines.extend([
            "## Response Field Coverage",
            "",
            "Detailed breakdown of response field support per method.",
            "",
            "| RPC Method | RPC Fields | SDK Fields | Missing |",
            "|------------|------------|------------|---------|",
        ])

        for comp in sorted(self.comparisons, key=lambda x: x.rpc_method):
            rpc_count = len(comp.rpc_response_fields)
            # Filter out legacy SDK field aliases
            sdk_filtered = [f for f in comp.sdk_response_fields if f not in IGNORED_SDK_FIELDS]
            sdk_count = len(sdk_filtered)
            missing = ", ".join(comp.missing_fields) if comp.missing_fields else "-"
            lines.append(
                f"| {comp.rpc_method} | {rpc_count} | {sdk_count} | {missing} |"
            )

        lines.append("")

        # Legend at bottom
        lines.extend([
            "## Legend",
            "",
            "| Status | Description |",
            "|--------|-------------|",
            "| Full | Method implemented with all required parameters and response fields |",
            "| Partial | Basic functionality present, missing some optional parameters or response fields |",
            "| Missing | Method not implemented in SDK |",
            "",
        ])

        output_path.write_text("\n".join(lines))
        print(f"  Generated: {output_path}")

    def save_json_data(self, output_dir: Path) -> None:
        """Save comparison data as JSON"""
        data = {
            "metadata": {
                "rpc_version": self.rpc_version.version,
                "rpc_release_date": self.rpc_version.release_date,
                "rpc_release_url": self.rpc_version.html_url,
                "sdk_version": self.sdk_version,
                "generated_at": datetime.now().isoformat(),
                "total_methods": len(self.comparisons)
            },
            "methods": {
                comp.rpc_method: {
                    "status": comp.status.value,
                    "sdk_method": comp.sdk_method,
                    "response_type": comp.response_type,
                    "rpc_required_params": comp.rpc_required_params,
                    "rpc_optional_params": comp.rpc_optional_params,
                    "sdk_params": comp.sdk_params,
                    "missing_params": comp.missing_params,
                    "rpc_response_fields": comp.rpc_response_fields,
                    "sdk_response_fields": comp.sdk_response_fields,
                    "missing_fields": comp.missing_fields,
                    "notes": comp.notes,
                    "category": comp.category
                }
                for comp in self.comparisons
            }
        }

        output_file = output_dir / "rpc_comparison_result.json"
        output_file.write_text(json.dumps(data, indent=2))
        print(f"  Generated: {output_file}")


def main():
    """Main execution function"""
    print("=" * 70)
    print("Stellar RPC API vs iOS/macOS SDK Comparison Generator")
    print("=" * 70)
    print()

    # Define paths
    script_dir = Path(__file__).parent
    sdk_root = script_dir.parent.parent.parent
    output_dir = sdk_root / "compatibility" / "rpc"
    output_file = output_dir / "RPC_COMPATIBILITY_MATRIX.md"
    rpc_methods_file = script_dir / "rpc_methods.json"

    try:
        # Create generator
        generator = RPCMatrixGenerator(sdk_root, rpc_methods_file)

        print("Loading RPC version information...")
        print(f"  RPC Version: {generator.rpc_version.version}")
        print(f"  Release Date: {generator.rpc_version.release_date}")
        print(f"  SDK Version: {generator.sdk_version}")
        print()

        # Analyze
        print("Analyzing SDK implementation...")
        generator.analyze()

        # Generate outputs
        print("\nGenerating outputs...")
        generator.generate_markdown(output_file)

        # Print summary
        total = len(generator.comparisons)
        fully = sum(1 for c in generator.comparisons if c.status == SupportStatus.FULLY_SUPPORTED)
        partial = sum(1 for c in generator.comparisons if c.status == SupportStatus.PARTIALLY_SUPPORTED)

        print()
        print("=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"RPC Version: {generator.rpc_version.version}")
        print(f"SDK Version: {generator.sdk_version}")
        print(f"Total Methods: {total}")
        print(f"Fully Supported: {fully}/{total} ({fully/total*100:.1f}%)")
        if partial > 0:
            print(f"Partially Supported: {partial}/{total}")

        # Show any issues
        issues = [c for c in generator.comparisons if c.status != SupportStatus.FULLY_SUPPORTED]
        if issues:
            print("\nIssues found:")
            for c in issues:
                print(f"  - {c.rpc_method}: {c.notes}")

        print()
        print("=" * 70)
        print("Comparison completed successfully!")
        print("=" * 70)

        return 0

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
