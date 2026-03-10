#!/usr/bin/env python3
"""
Horizon API Compatibility Matrix Generator for Stellar iOS/Mac SDK

This script generates detailed compatibility matrices comparing the iOS/macOS SDK
implementation against the Horizon API by fetching the latest Horizon release,
parsing router.go to extract endpoints, analyzing Swift service files, and
generating a comprehensive markdown matrix.

Features:
- Automatic version detection from GitHub releases
- Go Chi router parsing for endpoint extraction
- Swift service file analysis for SDK method mapping
- Detailed coverage statistics and streaming support tracking
- Production-ready error handling and logging

Usage:
    python generate_horizon_matrix.py
    python generate_horizon_matrix.py --horizon-version v25.0.0
    python generate_horizon_matrix.py --output custom_matrix.md
    python generate_horizon_matrix.py --verbose

Author: Generated for Stellar iOS/Mac SDK
Date: 2026-01-06
Python: 3.10+
"""

import argparse
import json
import logging
import plistlib
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


def get_sdk_version_from_plist(sdk_root: Path) -> str:
    """Read SDK version from Info.plist"""
    plist_path = sdk_root / "stellarsdk" / "stellarsdk" / "Info.plist"
    try:
        with open(plist_path, 'rb') as f:
            plist = plistlib.load(f)
            return plist.get('CFBundleShortVersionString', 'unknown')
    except Exception as e:
        logging.warning(f"Could not read version from Info.plist: {e}")
        return 'unknown'

# Import Horizon parameter definitions
from horizon_params import HORIZON_PARAMS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# Excluded endpoints - deprecated or redundant endpoints not counted in public API
EXCLUDED_ENDPOINTS = {
    ("/paths", "GET"): "Deprecated - use /paths/strict-receive and /paths/strict-send",
    ("/friendbot", "POST"): "Redundant - GET method is used instead",
}


# Single-resource endpoints excluded from streaming consideration
# These endpoints are not commonly used for streaming and no major SDK implements streaming for them
STREAMING_EXCLUDED = {
    ("/claimable_balances/{id}", "GET"),
    ("/liquidity_pools/{liquidity_pool_id}", "GET"),
    ("/offers/{offer_id}", "GET"),
    ("/ledgers/{ledger_id}", "GET"),
    ("/transactions/{tx_id}", "GET"),
    ("/operations/{id}", "GET"),
}


# SDK parameter mapping - extracted from Swift service implementations
SDK_PARAMS: Dict[Tuple[str, str], List[str]] = {
    ("/accounts", "GET"): ["signer", "asset", "sponsor", "liquidity_pool", "cursor", "order", "limit"],
    ("/accounts/{account_id}", "GET"): [],
    ("/accounts/{account_id}/data/{key}", "GET"): [],
    ("/assets", "GET"): ["asset_code", "asset_issuer", "cursor", "order", "limit"],
    ("/claimable_balances", "GET"): ["asset", "claimant", "sponsor", "cursor", "order", "limit"],
    ("/claimable_balances/{id}", "GET"): [],
    ("/effects", "GET"): ["cursor", "order", "limit"],
    ("/fee_stats", "GET"): [],
    ("/ledgers", "GET"): ["cursor", "order", "limit"],
    ("/ledgers/{ledger_id}", "GET"): [],
    ("/liquidity_pools", "GET"): ["reserves", "account", "cursor", "order", "limit"],
    ("/liquidity_pools/{liquidity_pool_id}", "GET"): [],
    ("/liquidity_pools/{liquidity_pool_id}/trades", "GET"): ["cursor", "order", "limit"],
    ("/offers", "GET"): ["seller", "selling", "buying", "sponsor", "cursor", "order", "limit"],
    ("/offers/{offer_id}", "GET"): [],
    ("/offers/{offer_id}/trades", "GET"): ["cursor", "order", "limit"],
    ("/operations", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/operations/{op_id}", "GET"): ["join"],
    ("/order_book", "GET"): ["selling_asset_type", "selling_asset_code", "selling_asset_issuer", "buying_asset_type", "buying_asset_code", "buying_asset_issuer", "limit"],
    ("/paths", "GET"): ["destination_account", "destination_asset_type", "destination_asset_code", "destination_asset_issuer", "destination_amount", "source_account"],
    ("/paths/strict-receive", "GET"): ["source_account", "source_assets", "destination_account", "destination_asset_type", "destination_asset_code", "destination_asset_issuer", "destination_amount"],
    ("/paths/strict-send", "GET"): ["source_amount", "source_asset_type", "source_asset_code", "source_asset_issuer", "destination_account", "destination_assets"],
    ("/payments", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/trades", "GET"): ["base_asset_type", "base_asset_code", "base_asset_issuer", "counter_asset_type", "counter_asset_code", "counter_asset_issuer", "offer_id", "account_id", "liquidity_pool_id", "trade_type", "cursor", "order", "limit"],
    ("/trade_aggregations", "GET"): ["start_time", "end_time", "resolution", "offset", "base_asset_type", "base_asset_code", "base_asset_issuer", "counter_asset_type", "counter_asset_code", "counter_asset_issuer", "cursor", "order", "limit"],
    ("/transactions", "GET"): ["cursor", "order", "limit", "include_failed"],
    ("/transactions", "POST"): ["tx"],
    ("/transactions_async", "POST"): ["tx"],
    ("/transactions/{tx_id}", "GET"): [],
    # Sub-resource endpoints inherit pagination from parent service
    ("/accounts/{account_id}/offers", "GET"): ["cursor", "order", "limit"],
    ("/accounts/{account_id}/trades", "GET"): ["cursor", "order", "limit"],
    ("/accounts/{account_id}/effects", "GET"): ["cursor", "order", "limit"],
    ("/accounts/{account_id}/operations", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/accounts/{account_id}/payments", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/accounts/{account_id}/transactions", "GET"): ["cursor", "order", "limit", "include_failed"],
    ("/ledgers/{ledger_id}/transactions", "GET"): ["cursor", "order", "limit", "include_failed"],
    ("/ledgers/{ledger_id}/operations", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/ledgers/{ledger_id}/payments", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/ledgers/{ledger_id}/effects", "GET"): ["cursor", "order", "limit"],
    ("/liquidity_pools/{liquidity_pool_id}/transactions", "GET"): ["cursor", "order", "limit", "include_failed"],
    ("/liquidity_pools/{liquidity_pool_id}/operations", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/liquidity_pools/{liquidity_pool_id}/effects", "GET"): ["cursor", "order", "limit"],
    ("/claimable_balances/{id}/transactions", "GET"): ["cursor", "order", "limit", "include_failed"],
    ("/claimable_balances/{id}/operations", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/transactions/{tx_id}/operations", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/transactions/{tx_id}/payments", "GET"): ["cursor", "order", "limit", "include_failed", "join"],
    ("/transactions/{tx_id}/effects", "GET"): ["cursor", "order", "limit"],
    ("/operations/{op_id}/effects", "GET"): ["cursor", "order", "limit"],
    ("/health", "GET"): [],
    ("/", "GET"): [],
    ("/friendbot", "GET"): ["addr"],
    ("/friendbot", "POST"): ["addr"],
}


def compare_params(endpoint: str, method: str) -> Tuple[List[str], List[str], bool]:
    """
    Compare Horizon params with SDK params.

    Args:
        endpoint: Normalized endpoint path
        method: HTTP method

    Returns:
        Tuple of (missing_params, extra_params, is_full_match)
        - missing_params: Parameters Horizon has but SDK doesn't
        - extra_params: Parameters SDK has but Horizon doesn't
        - is_full_match: True if all Horizon params are implemented
    """
    horizon = set(HORIZON_PARAMS.get((endpoint, method), []))
    sdk = set(SDK_PARAMS.get((endpoint, method), []))

    missing = horizon - sdk  # Horizon has but SDK doesn't
    extra = sdk - horizon    # SDK has but Horizon doesn't

    return sorted(list(missing)), sorted(list(extra)), len(missing) == 0


@dataclass
class HorizonRelease:
    """Represents a Horizon release from GitHub"""
    version: str
    tag_name: str
    release_date: str
    html_url: str

    @property
    def ref(self) -> str:
        """Git reference for fetching files"""
        return self.tag_name


@dataclass
class HorizonEndpoint:
    """Represents a single Horizon API endpoint"""
    path: str
    method: str
    handler: str
    category: str
    streaming: bool = False
    path_params: List[str] = field(default_factory=list)
    internal: bool = False

@dataclass
class SDKMethod:
    """Represents a Swift SDK method that calls a Horizon endpoint"""
    name: str
    service: str
    file_path: str
    horizon_endpoint: str
    http_method: str = "GET"
    streaming: bool = False

    @property
    def full_name(self) -> str:
        """Full method identifier"""
        if self.service:
            return f"{self.service}.{self.name}()"
        return self.name


@dataclass
class EndpointMatch:
    """Represents a match between Horizon endpoint and SDK method"""
    endpoint: HorizonEndpoint
    sdk_method: Optional[SDKMethod] = None
    missing_params: List[str] = field(default_factory=list)
    extra_params: List[str] = field(default_factory=list)
    streaming_match: bool = True
    notes: str = ""

    @property
    def is_excluded(self) -> bool:
        """Check if endpoint is excluded from matrix"""
        return (self.endpoint.path, self.endpoint.method) in EXCLUDED_ENDPOINTS

    @property
    def is_streaming_excluded(self) -> bool:
        """Check if endpoint is excluded from streaming consideration"""
        return (self.endpoint.path, self.endpoint.method) in STREAMING_EXCLUDED

    @property
    def coverage_status(self) -> str:
        """Calculate coverage status"""
        if self.endpoint.internal or self.is_excluded:
            return "n/a"
        if not self.sdk_method:
            return "missing"
        # For streaming-excluded endpoints, only check parameters
        if self.is_streaming_excluded:
            if self.missing_params:
                return "partial"
            return "full"
        # For regular endpoints, check both parameters and streaming
        if self.missing_params or not self.streaming_match:
            return "partial"
        return "full"


@dataclass
class CategoryStats:
    """Statistics for a category of endpoints"""
    name: str
    total: int = 0
    full: int = 0
    partial: int = 0
    missing: int = 0
    na: int = 0

    @property
    def coverage_percentage(self) -> float:
        """Calculate coverage percentage (excluding N/A)"""
        applicable = self.total - self.na
        if applicable == 0:
            return 100.0
        supported = self.full + self.partial
        return (supported / applicable) * 100.0


@dataclass
class ComparisonResult:
    """Complete comparison result"""
    horizon_release: HorizonRelease
    sdk_version: str
    matches: List[EndpointMatch] = field(default_factory=list)
    categories: List[CategoryStats] = field(default_factory=list)
    overall_coverage: float = 0.0
    streaming_coverage: float = 0.0

    def calculate_statistics(self) -> None:
        """Calculate all statistics from matches"""
        category_map: Dict[str, CategoryStats] = {}

        # Only count non-excluded endpoints
        for match in self.matches:
            if match.is_excluded:
                continue

            category = match.endpoint.category
            if category not in category_map:
                category_map[category] = CategoryStats(name=category)

            stats = category_map[category]
            stats.total += 1

            status = match.coverage_status
            if status == "full":
                stats.full += 1
            elif status == "partial":
                stats.partial += 1
            elif status == "missing":
                stats.missing += 1
            elif status == "n/a":
                stats.na += 1

        self.categories = sorted(category_map.values(), key=lambda x: x.name)

        # Calculate overall coverage
        total_applicable = sum(c.total - c.na for c in self.categories)
        total_supported = sum(c.full + c.partial for c in self.categories)
        self.overall_coverage = (total_supported / total_applicable * 100.0) if total_applicable > 0 else 0.0

        # Calculate streaming coverage - exclude streaming-excluded endpoints
        streaming_endpoints = [
            m for m in self.matches
            if m.endpoint.streaming
            and not m.endpoint.internal
            and not m.is_excluded
            and not m.is_streaming_excluded
        ]
        streaming_implemented = [m for m in streaming_endpoints if m.streaming_match]
        self.streaming_coverage = (len(streaming_implemented) / len(streaming_endpoints) * 100.0) if streaming_endpoints else 0.0


class HorizonFetcher:
    """Fetches and parses Horizon release information and router.go"""

    RELEASES_API = "https://api.github.com/repos/stellar/stellar-horizon/releases/latest"
    ROUTER_RAW_URL = "https://raw.githubusercontent.com/stellar/stellar-horizon/{ref}/internal/httpx/router.go"

    def __init__(self, timeout: int = 30):
        self.timeout = timeout

    def get_latest_release(self) -> HorizonRelease:
        """
        Fetch the latest Horizon release from GitHub

        Returns:
            HorizonRelease object with version information

        Raises:
            ValueError: If release cannot be fetched or parsed
        """
        logger.info("Fetching latest Horizon release from GitHub")

        try:
            req = Request(self.RELEASES_API)
            req.add_header('User-Agent', 'Stellar-iOS-SDK-Horizon-Analyzer/1.0')
            req.add_header('Accept', 'application/vnd.github.v3+json')

            with urlopen(req, timeout=self.timeout) as response:
                data = json.loads(response.read().decode('utf-8'))

            # Parse the latest release
            return self._parse_release(data)

        except HTTPError as e:
            raise ValueError(f"HTTP error fetching releases: {e.code} {e.reason}")
        except URLError as e:
            raise ValueError(f"Network error fetching releases: {e.reason}")
        except Exception as e:
            raise ValueError(f"Error fetching latest release: {str(e)}")

    def get_release(self, version: str) -> HorizonRelease:
        """
        Fetch a specific Horizon release by version

        Args:
            version: Version string (e.g., "v25.0.0", "v2.33.0")

        Returns:
            HorizonRelease object

        Raises:
            ValueError: If release cannot be found
        """
        logger.info(f"Fetching Horizon release {version}")

        # Normalize version - ensure it starts with 'v'
        if not version.startswith('v'):
            version = f"v{version}"

        try:
            releases_list_api = "https://api.github.com/repos/stellar/stellar-horizon/releases"
            req = Request(releases_list_api)
            req.add_header('User-Agent', 'Stellar-iOS-SDK-Horizon-Analyzer/1.0')
            req.add_header('Accept', 'application/vnd.github.v3+json')

            with urlopen(req, timeout=self.timeout) as response:
                data = json.loads(response.read().decode('utf-8'))

            for release in data:
                if release.get('tag_name') == version:
                    return self._parse_release(release)

            raise ValueError(f"Release {version} not found")

        except HTTPError as e:
            raise ValueError(f"HTTP error fetching release: {e.code} {e.reason}")
        except URLError as e:
            raise ValueError(f"Network error fetching release: {e.reason}")
        except Exception as e:
            raise ValueError(f"Error fetching release {version}: {str(e)}")

    def _parse_release(self, release_data: dict) -> HorizonRelease:
        """Parse GitHub release data into HorizonRelease object"""
        tag_name = release_data.get('tag_name', '')

        # Extract version number (e.g., "v2.33.0" -> "v2.33.0")
        # Note: Horizon uses semantic versioning (v2.x.x), not protocol version
        version_match = re.search(r'v(\d+\.\d+\.\d+)', tag_name)
        if version_match:
            version = f"v{version_match.group(1)}"
        else:
            version = tag_name

        release_date = release_data.get('published_at', '')
        if release_date:
            release_date = release_date.split('T')[0]

        return HorizonRelease(
            version=version,
            tag_name=tag_name,
            release_date=release_date,
            html_url=release_data.get('html_url', '')
        )

    def fetch_router(self, ref: str = "master") -> str:
        """
        Fetch router.go content from GitHub

        Args:
            ref: Git reference (tag, branch, or commit)

        Returns:
            router.go file content

        Raises:
            ValueError: If file cannot be fetched
        """
        url = self.ROUTER_RAW_URL.format(ref=ref)
        logger.info(f"Fetching router.go from {url}")

        try:
            req = Request(url)
            req.add_header('User-Agent', 'Stellar-iOS-SDK-Horizon-Analyzer/1.0')

            with urlopen(req, timeout=self.timeout) as response:
                content = response.read().decode('utf-8')

            logger.info(f"Successfully fetched router.go ({len(content)} bytes)")
            return content

        except HTTPError as e:
            if e.code == 404:
                raise ValueError(f"router.go not found at {url}")
            raise ValueError(f"HTTP error fetching router.go: {e.code} {e.reason}")
        except URLError as e:
            raise ValueError(f"Network error fetching router.go: {e.reason}")
        except Exception as e:
            raise ValueError(f"Error fetching router.go: {str(e)}")

    def parse_router(self, content: str) -> List[HorizonEndpoint]:
        """
        Parse Go Chi router to extract endpoints

        Args:
            content: router.go file content

        Returns:
            List of HorizonEndpoint objects

        Note: Some Horizon endpoints may be defined in non-standard ways that this parser
        may miss. Known potentially missing patterns:
        - /operations (list all operations)
        - /payments (list all payments)
        - /accounts/{id}/operations
        - /accounts/{id}/payments
        - /ledgers/{id}/operations
        - /ledgers/{id}/payments
        - /transactions/{id}/operations

        These endpoints exist in Horizon API but may not be extracted if they use
        handler delegation or non-standard routing patterns.
        """
        logger.info("Parsing router.go to extract endpoints")

        endpoints: List[HorizonEndpoint] = []

        # Track context for nested routes
        route_stack: List[str] = []
        category_stack: List[str] = []

        lines = content.split('\n')
        i = 0

        while i < len(lines):
            line = lines[i].strip()

            # Match Route() calls: r.Route("/path", func(r chi.Router) {
            route_match = re.match(r'r\.Route\("([^"]+)",\s*func\(r\s+chi\.Router\)\s*\{', line)
            if route_match:
                path = route_match.group(1)
                route_stack.append(path)

                # Determine category from path
                category = self._determine_category(path)
                category_stack.append(category)

                i += 1
                continue

            # Match closing braces (end of Route)
            if line == '})' and route_stack:
                route_stack.pop()
                if category_stack:
                    category_stack.pop()
                i += 1
                continue

            # Match HTTP method calls: r.Get("/path", handler) or r.Post()
            method_match = re.match(r'r\.(Get|Post|Put|Delete|Patch)\("([^"]+)",\s*([^)]+)\)', line)
            if method_match:
                http_method = method_match.group(1).upper()
                path = method_match.group(2)
                handler = method_match.group(3).strip()
                endpoints.append(self._build_endpoint(http_method, path, handler, route_stack))
                i += 1
                continue

            # Match .Method() calls: r.Method(http.MethodGet, "/path", handler) or with middleware
            # Pattern: r.With(middleware).Method(http.MethodGet, "/path", ...) - just extract method and path
            method_call_match = re.search(r'\.Method\s*\(\s*http\.Method(\w+)\s*,\s*"([^"]+)"', line)

            # Also check for multi-line .Method() where method and path are on separate lines
            if not method_call_match and '.Method(' in line and i + 3 < len(lines):
                # Look ahead for http.Method and path on next lines
                multi_lines = ' '.join([line] + [lines[j].strip() for j in range(i+1, min(i+4, len(lines)))])
                method_call_match = re.search(r'\.Method\s*\(\s*http\.Method(\w+)\s*,\s*"([^"]+)"', multi_lines)

            if method_call_match:
                http_method = method_call_match.group(1).upper()
                path = method_call_match.group(2)
                handler_match = re.search(r'actions\.(\w+)', line)
                handler = handler_match.group(1) if handler_match else f"{http_method}Handler"
                endpoints.append(self._build_endpoint(http_method, path, handler, route_stack))
                i += 1
                continue

            i += 1

        logger.info(f"Extracted {len(endpoints)} endpoints from router.go")
        return endpoints

    def _build_endpoint(self, http_method: str, path: str, handler: str, route_stack: List[str]) -> HorizonEndpoint:
        """Build a HorizonEndpoint from parsed router components"""
        full_path = ''.join(route_stack) + path
        path_params = self._extract_path_params(full_path)
        full_path = self._clean_path(full_path)
        return HorizonEndpoint(
            path=full_path,
            method=http_method,
            handler=handler,
            category=self._determine_category(full_path),
            streaming=self._supports_streaming(handler, full_path, http_method),
            path_params=path_params,
            internal=self._is_internal_endpoint(full_path, handler)
        )

    def _determine_category(self, path: str) -> str:
        """Determine endpoint category from path based on primary resource"""
        path = path.lower()

        # Root paths
        if path == '/' or path == '/health':
            return "Root"

        # Internal/Admin paths
        if path.startswith('/metrics') or path.startswith('/debug') or path.startswith('/ingestion'):
            return "Internal/Admin"

        # Categorize by primary resource (first path segment)
        # Use startswith to catch both collection and item endpoints
        if path.startswith('/accounts'):
            return "Accounts"
        if path.startswith('/claimable_balances'):
            return "Claimable Balances"
        if path.startswith('/liquidity_pools'):
            return "Liquidity Pools"
        if path.startswith('/ledgers'):
            return "Ledgers"
        if path.startswith('/transactions'):
            return "Transactions"
        if path.startswith('/operations'):
            return "Operations"
        if path.startswith('/payments'):
            return "Payments"
        if path.startswith('/effects'):
            return "Effects"
        if path.startswith('/trade_aggregations'):
            return "Trades"
        if path.startswith('/trades'):
            return "Trades"
        if path.startswith('/offers'):
            return "Offers"
        if path.startswith('/assets'):
            return "Assets"
        if path.startswith('/paths'):
            return "Paths"
        if path.startswith('/order_book'):
            return "Order Book"
        if path.startswith('/fee_stats'):
            return "Network"
        if path.startswith('/friendbot'):
            return "Friendbot"

        return "Other"

    def _extract_path_params(self, path: str) -> List[str]:
        """Extract path parameters from path"""
        # Extract parameters and clean regex patterns (e.g., {account_id:\\w+} -> account_id)
        params = re.findall(r'\{([^}:]+)(?::[^}]+)?\}', path)
        return params

    def _clean_path(self, path: str) -> str:
        """Clean path by removing regex patterns from parameters and trailing slashes"""
        # Convert {account_id:\\w+} to {account_id}
        cleaned = re.sub(r'\{([^}:]+):[^}]+\}', r'{\1}', path)
        # Strip trailing slashes (except for root path "/")
        if cleaned != "/" and cleaned.endswith("/"):
            cleaned = cleaned.rstrip("/")
        return cleaned

    def _is_internal_endpoint(self, path: str, handler: str) -> bool:
        """Check if endpoint is internal/admin only"""
        internal_prefixes = ['/metrics', '/debug', '/ingestion']
        return any(path.startswith(prefix) for prefix in internal_prefixes)

    def _supports_streaming(self, handler: str, path: str, method: str = "GET") -> bool:
        """
        Determine if endpoint supports streaming

        Based on Horizon documentation, these endpoints typically support SSE streaming:
        - List endpoints (accounts, transactions, operations, etc.)
        - Detail endpoints for resources that can change

        Note: Only GET endpoints support streaming. POST endpoints do not stream.
        """
        # POST endpoints don't support streaming
        if method == "POST":
            return False

        # Streaming is typically available for GET collection endpoints
        streaming_patterns = [
            '/accounts/{',
            '/ledgers',
            '/transactions',
            '/operations',
            '/payments',
            '/effects',
            '/trades',
            '/offers',
            '/order_book',
            '/claimable_balances/{',
            '/liquidity_pools/{',
        ]

        return any(pattern in path for pattern in streaming_patterns)


class SDKAnalyzer:
    """Analyzes iOS SDK Swift service files"""

    SERVICE_PATH = "stellarsdk/stellarsdk/service/"

    def __init__(self, sdk_root: Path):
        self.sdk_root = sdk_root
        self.service_path = sdk_root / self.SERVICE_PATH

        if not self.service_path.exists():
            raise ValueError(f"Service path not found: {self.service_path}")

    def find_service_files(self) -> List[Path]:
        """Find all *Service.swift files"""
        service_files = sorted(self.service_path.glob("*Service.swift"))
        logger.info(f"Found {len(service_files)} service files")
        return service_files

    def analyze_all_services(self) -> Dict[str, List[SDKMethod]]:
        """
        Analyze all service files and extract SDK methods

        Returns:
            Dictionary mapping service name to list of methods
        """
        logger.info("Analyzing all SDK service files")

        service_files = self.find_service_files()
        all_methods: Dict[str, List[SDKMethod]] = {}

        for service_file in service_files:
            service_name = service_file.stem
            methods = self.analyze_service(service_file)
            all_methods[service_name] = methods
            logger.info(f"  {service_name}: {len(methods)} methods")

        total_methods = sum(len(methods) for methods in all_methods.values())
        logger.info(f"Extracted {total_methods} total SDK methods")

        return all_methods

    def analyze_service(self, file_path: Path) -> List[SDKMethod]:
        """
        Analyze a single service file to extract methods

        Args:
            file_path: Path to Swift service file

        Returns:
            List of SDKMethod objects
        """
        try:
            content = file_path.read_text(encoding='utf-8')
            service_name = file_path.stem

            methods = self._extract_methods_from_swift(content, service_name, str(file_path))
            return methods

        except Exception as e:
            logger.warning(f"Error analyzing {file_path}: {e}")
            return []

    def _extract_methods_from_swift(self, content: str, service_name: str, file_path: str) -> List[SDKMethod]:
        """Extract method information from Swift content"""
        methods: List[SDKMethod] = []

        # Pattern to match public/open/private functions (include private for helper methods with paths)
        func_pattern = re.compile(
            r'(?:open|public|private|fileprivate|internal)?\s*func\s+(\w+)\s*\([^)]*\)\s*(?:async\s*)?(?:->\s*([^\{]+))?\s*\{',
            re.MULTILINE
        )

        # Find all public functions
        for func_match in func_pattern.finditer(content):
            method_name = func_match.group(1)
            return_type = func_match.group(2).strip() if func_match.group(2) else ""

            # Extract the function body to find requestPath
            func_start = func_match.end()
            func_body = self._extract_function_body(content, func_start)

            # Extract requestPath
            endpoint = self._extract_request_path(func_body)
            if not endpoint:
                continue

            # Extract HTTP method (default GET)
            http_method = self._extract_http_method(func_body)

            # Check for streaming support
            streaming = self._is_streaming_method(func_body, return_type)

            method = SDKMethod(
                name=method_name,
                service=service_name,
                file_path=file_path,
                horizon_endpoint=endpoint,
                http_method=http_method,
                streaming=streaming,
            )

            methods.append(method)

        return methods

    def _extract_function_body(self, content: str, start_pos: int) -> str:
        """Extract function body from start position"""
        brace_count = 1
        pos = start_pos

        while pos < len(content) and brace_count > 0:
            if content[pos] == '{':
                brace_count += 1
            elif content[pos] == '}':
                brace_count -= 1
            pos += 1

        return content[start_pos:pos]

    def _extract_request_path(self, func_body: str) -> Optional[str]:
        """Extract requestPath from function body"""
        # Pattern 1: String concatenation with + operator (check first, most specific)
        # Matches: let path = "/accounts/" + accountId + "/transactions"
        # or: let path = "/claimable_balances/" + id + "/transactions"
        concat_match = re.search(r'(?:var|let)\s+(?:path|requestPath)\s*=\s*"([^"]+)"\s*\+\s*\w+\s*\+\s*"([^"]+)"', func_body)
        if concat_match:
            # Reconstruct path with placeholder
            path = concat_match.group(1) + '{id}' + concat_match.group(2)
            return self._normalize_path_parameters(path)

        # Pattern 2: Simple string concatenation: "/path/" + variable
        concat_simple = re.search(r'(?:var|let)\s+(?:path|requestPath)\s*=\s*"([^"]+)"\s*\+\s*\w+', func_body)
        if concat_simple:
            path = concat_simple.group(1) + '{id}'
            return self._normalize_path_parameters(path)

        # Pattern 3: let requestPath = "/path" or var requestPath = "/path"
        path_match = re.search(r'(?:var|let)\s+requestPath\s*=\s*"([^"]+)"', func_body)
        if path_match:
            path = path_match.group(1)
            return self._normalize_path_parameters(path)

        # Pattern 4: requestPath = "/path/\(param)" (assignment without let/var)
        path_match = re.search(r'requestPath\s*=\s*"([^"]+)', func_body)
        if path_match:
            path = path_match.group(1)
            return self._normalize_path_parameters(path)

        # Pattern 5: let path = "/path" or var path = "/path"
        path_match = re.search(r'(?:var|let)\s+path\s*=\s*"([^"]+)"', func_body)
        if path_match:
            path = path_match.group(1)
            return self._normalize_path_parameters(path)

        # Pattern 6: Direct path in GETRequestWithPath
        path_match = re.search(r'GETRequestWithPath\(path:\s*"([^"]+)"', func_body)
        if path_match:
            path = path_match.group(1)
            return self._normalize_path_parameters(path)

        # Pattern 7: Direct path in POSTRequestWithPath
        path_match = re.search(r'POSTRequestWithPath\(path:\s*"([^"]+)"', func_body)
        if path_match:
            path = path_match.group(1)
            return self._normalize_path_parameters(path)

        # Pattern 8: Direct path in POSTMultipartRequestWithPath
        path_match = re.search(r'POSTMultipartRequestWithPath\(path:\s*"([^"]+)"', func_body)
        if path_match:
            path = path_match.group(1)
            return self._normalize_path_parameters(path)

        # Pattern 9: Path passed to helper method - extract from method call
        # Matches: getTransactions(onPath: path, ...)
        helper_match = re.search(r'(?:getTransactions|getAccounts|getOperations|getEffects|getPayments|getTrades|getOffers|getLedgers)\(onPath:\s*(\w+)', func_body)
        if helper_match:
            # The path variable name, now search for its assignment
            path_var = helper_match.group(1)

            # Look for string concatenation assignment first (most specific)
            concat_assignment = re.search(rf'(?:var|let)\s+{path_var}\s*=\s*"([^"]+)"\s*\+\s*\w+\s*\+\s*"([^"]+)"', func_body)
            if concat_assignment:
                path = concat_assignment.group(1) + '{id}' + concat_assignment.group(2)
                return self._normalize_path_parameters(path)

            # Look for simple concatenation
            simple_concat = re.search(rf'(?:var|let)\s+{path_var}\s*=\s*"([^"]+)"\s*\+\s*\w+', func_body)
            if simple_concat:
                path = simple_concat.group(1) + '{id}'
                return self._normalize_path_parameters(path)

            # Look for the path variable assignment (plain string)
            path_assignment = re.search(rf'(?:var|let)\s+{path_var}\s*=\s*"([^"]+)"', func_body)
            if path_assignment:
                path = path_assignment.group(1)
                return self._normalize_path_parameters(path)

        return None

    def _normalize_path_parameters(self, path: str) -> str:
        r"""
        Normalize path parameters to standard {id} format

        Handles:
        - Swift string interpolation: \(param) -> {id}
        - Multiple parameters in same path
        - Already normalized paths
        """
        # Normalize Swift string interpolation to {id}
        # Matches \(accountId), \(ledger), \(transactionHash), etc.
        normalized = re.sub(r'\\?\([\w.]+\)', '{id}', path)
        return normalized

    def _extract_http_method(self, func_body: str) -> str:
        """Extract HTTP method from function body"""
        if 'POSTRequestWithPath' in func_body or 'POSTMultipartRequestWithPath' in func_body:
            return 'POST'
        elif 'PUTRequestWithPath' in func_body:
            return 'PUT'
        elif 'DELETERequestWithPath' in func_body:
            return 'DELETE'
        else:
            return 'GET'

    def _is_streaming_method(self, func_body: str, return_type: str) -> bool:
        """Check if method supports streaming"""
        # Look for streaming indicators
        streaming_indicators = [
            'StreamItem',
            'AsyncStream',
            'stream(',
            'EventSource',
            'text/event-stream'
        ]

        return any(indicator in func_body or indicator in return_type for indicator in streaming_indicators)


class EndpointComparator:
    """Compares Horizon endpoints with SDK methods"""

    # Known mappings for endpoints that use external URLs or special patterns
    KNOWN_MAPPINGS = {
        ("/friendbot", "GET"): {
            "sdk_method": "AccountService.createTestAccount()",
            "notes": "External friendbot URL"
        },
        ("/friendbot", "POST"): {
            "sdk_method": "AccountService.createTestAccount()",
            "notes": "External friendbot URL (GET)"
        },
        ("/", "GET"): {
            "sdk_method": "StellarSDK (configuration)",
            "notes": "Via SDK initialization"
        }
    }

    # Streaming support mapping - endpoints that have streaming via stream(for:) methods
    # Each entry maps normalized path pattern to the streaming method info (concise format)
    STREAMING_SUPPORT = {
        # AccountService streaming methods
        "/accounts/{id}": "streamAccount(accountId:)",
        "/accounts/{id}/data/{id}": "streamAccountData(accountId:key:)",

        # TransactionsService.stream(for:) with TransactionsChange enum
        "/transactions": "stream(for: .allTransactions)",
        "/accounts/{id}/transactions": "stream(for: .transactionsForAccount)",
        "/claimable_balances/{id}/transactions": "stream(for: .transactionsForClaimableBalance)",
        "/ledgers/{id}/transactions": "stream(for: .transactionsForLedger)",
        "/liquidity_pools/{id}/transactions": "stream(for: .transactionsForLiquidityPool)",

        # EffectsService.stream(for:) with EffectsChange enum
        "/effects": "stream(for: .allEffects)",
        "/accounts/{id}/effects": "stream(for: .effectsForAccount)",
        "/ledgers/{id}/effects": "stream(for: .effectsForLedger)",
        "/operations/{id}/effects": "stream(for: .effectsForOperation)",
        "/transactions/{id}/effects": "stream(for: .effectsForTransaction)",
        "/liquidity_pools/{id}/effects": "stream(for: .effectsForLiquidityPool)",

        # OperationsService.stream(for:) with OperationsChange enum
        "/operations": "stream(for: .allOperations)",
        "/accounts/{id}/operations": "stream(for: .operationsForAccount)",
        "/ledgers/{id}/operations": "stream(for: .operationsForLedger)",
        "/transactions/{id}/operations": "stream(for: .operationsForTransaction)",
        "/liquidity_pools/{id}/operations": "stream(for: .operationsForLiquidityPool)",
        "/claimable_balances/{id}/operations": "stream(for: .operationsForClaimableBalance)",

        # PaymentsService.stream(for:) with PaymentsChange enum
        "/payments": "stream(for: .allPayments)",
        "/accounts/{id}/payments": "stream(for: .paymentsForAccount)",
        "/ledgers/{id}/payments": "stream(for: .paymentsForLedger)",
        "/transactions/{id}/payments": "stream(for: .paymentsForTransaction)",

        # TradesService.stream(for:) with TradesChange enum
        "/trades": "stream(for: .tradesForAssetPair)",
        "/accounts/{id}/trades": "stream(for: .tradesForAccount)",

        # LiquidityPoolsService streaming methods
        "/liquidity_pools/{id}/trades": "streamTrades(forPoolId:)",

        # OffersService streaming methods
        "/offers": "stream(for: .allOffers)",
        "/accounts/{id}/offers": "stream(for: .offersForAccount)",
        "/offers/{id}/trades": "streamTrades(forOffer:)",

        # LedgersService.stream(for:) with LedgersChange enum
        "/ledgers": "stream(for: .allLedgers)",

        # OrderbookService.stream(for:)
        "/order_book": "stream(for:)",
    }

    def compare(
        self,
        horizon_endpoints: List[HorizonEndpoint],
        sdk_methods: Dict[str, List[SDKMethod]],
        horizon_release: HorizonRelease,
        sdk_version: str
    ) -> ComparisonResult:
        """
        Compare Horizon endpoints with SDK implementation

        Args:
            horizon_endpoints: List of Horizon endpoints
            sdk_methods: Dictionary of SDK methods by service
            horizon_release: Horizon release information
            sdk_version: SDK version string

        Returns:
            ComparisonResult with matches and statistics
        """
        logger.info("Comparing Horizon endpoints with SDK implementation")

        result = ComparisonResult(
            horizon_release=horizon_release,
            sdk_version=sdk_version
        )

        # Flatten SDK methods
        all_sdk_methods = []
        for methods in sdk_methods.values():
            all_sdk_methods.extend(methods)

        # Match each Horizon endpoint
        for endpoint in horizon_endpoints:
            match = self._match_endpoint(endpoint, all_sdk_methods)
            result.matches.append(match)

        # Calculate statistics
        result.calculate_statistics()

        logger.info(f"Overall coverage: {result.overall_coverage:.1f}%")
        logger.info(f"Streaming coverage: {result.streaming_coverage:.1f}%")

        return result

    def _match_endpoint(
        self,
        endpoint: HorizonEndpoint,
        sdk_methods: List[SDKMethod]
    ) -> EndpointMatch:
        """
        Match a Horizon endpoint to SDK methods

        Args:
            endpoint: Horizon endpoint to match
            sdk_methods: List of all SDK methods

        Returns:
            EndpointMatch object
        """
        match = EndpointMatch(endpoint=endpoint)

        # Check known mappings first (for endpoints with special handling)
        key = (endpoint.path, endpoint.method)
        if key in self.KNOWN_MAPPINGS:
            mapping = self.KNOWN_MAPPINGS[key]
            # Create a synthetic SDK method for display
            match.sdk_method = SDKMethod(
                name=mapping["sdk_method"],
                service="",
                file_path="",
                horizon_endpoint=endpoint.path,
                http_method=endpoint.method
            )
            match.notes = mapping["notes"]
            return match

        # Normalize endpoint path for matching
        normalized_horizon = self._normalize_path(endpoint.path)

        # Find matching SDK methods
        candidates = []
        for method in sdk_methods:
            normalized_sdk = self._normalize_path(method.horizon_endpoint)

            if normalized_sdk == normalized_horizon and method.http_method == endpoint.method:
                candidates.append(method)

        if not candidates:
            match.notes = "No SDK method found for this endpoint"
            return match

        # Use first candidate (they should be equivalent)
        sdk_method = candidates[0]
        match.sdk_method = sdk_method

        # Normalize endpoint path for parameter comparison
        normalized_param_path = self.normalize_endpoint_path(endpoint.path)

        # Compare query parameters
        missing_params, extra_params, params_match = compare_params(normalized_param_path, endpoint.method)
        match.missing_params = missing_params
        match.extra_params = extra_params

        # Check streaming support using STREAMING_SUPPORT mapping
        notes_parts = []
        if endpoint.streaming:
            streaming_method = self.STREAMING_SUPPORT.get(normalized_horizon)
            if streaming_method:
                match.streaming_match = True
                notes_parts.append(streaming_method)
            else:
                match.streaming_match = False
                notes_parts.append("No streaming")

        # Add missing parameters to notes if any
        if missing_params:
            notes_parts.append(f"Missing: {', '.join(missing_params)}")

        # Set notes
        match.notes = "; ".join(notes_parts) if notes_parts else "-"

        return match

    @staticmethod
    def normalize_endpoint_path(path: str) -> str:
        """Normalize endpoint path parameter names for HORIZON_PARAMS dict lookup."""
        if "/liquidity_pools/" in path:
            path = re.sub(r'\{[^}]+\}', '{liquidity_pool_id}', path, count=1)
        if "/accounts/" in path and "/accounts/{" in path:
            path = re.sub(r'/accounts/\{[^}]+\}', '/accounts/{account_id}', path)
        if "/ledgers/" in path and "/ledgers/{" in path:
            path = re.sub(r'/ledgers/\{[^}]+\}', '/ledgers/{ledger_id}', path)
        if "/transactions/" in path and "/transactions/{" in path:
            path = re.sub(r'/transactions/\{[^}]+\}', '/transactions/{tx_id}', path)
        if "/operations/" in path and "/operations/{" in path:
            path = re.sub(r'/operations/\{[^}]+\}', '/operations/{op_id}', path)
        if "/offers/" in path and "/offers/{" in path:
            path = re.sub(r'/offers/\{[^}]+\}', '/offers/{offer_id}', path)
        if "/claimable_balances/" in path and "/claimable_balances/{" in path:
            path = re.sub(r'/claimable_balances/\{[^}]+\}', '/claimable_balances/{id}', path)
        if "/data/" in path:
            path = re.sub(r'/data/\{[^}]+\}', '/data/{key}', path)
        return path

    def _normalize_path(self, path: str) -> str:
        """
        Normalize path for comparison

        Examples:
            /accounts/{account_id} -> /accounts/{id}
            /accounts/{id} -> /accounts/{id}
            /accounts/ -> /accounts
        """
        normalized = re.sub(r'\{[^}]+\}', '{id}', path)
        if normalized != "/" and normalized.endswith("/"):
            normalized = normalized.rstrip("/")
        return normalized


class MatrixRenderer:
    """Renders comparison results as markdown"""

    def render(self, result: ComparisonResult) -> str:
        """
        Render complete compatibility matrix

        Args:
            result: ComparisonResult to render

        Returns:
            Markdown formatted string
        """
        sections = [
            self._render_header(result),
            self._render_overall_coverage(result),
            self._render_coverage_by_category(result),
            self._render_streaming_summary(result),
            self._render_compatibility_matrix(result),
            self._render_parameter_coverage(result),
            self._render_legend()
        ]

        return '\n\n'.join(sections)

    def _render_header(self, result: ComparisonResult) -> str:
        """Render document header with version information"""
        horizon = result.horizon_release
        generated = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Count all endpoints and excluded ones
        all_endpoints = len(result.matches)
        excluded_count = sum(1 for m in result.matches if m.is_excluded)
        public_endpoints = all_endpoints - excluded_count

        # Build exclusion note
        exclusion_lines = []
        if excluded_count > 0:
            exclusion_lines.append(f"> **Note:** {excluded_count} endpoint{'s' if excluded_count != 1 else ''} intentionally excluded from the matrix:")
            for (path, method), reason in EXCLUDED_ENDPOINTS.items():
                exclusion_lines.append(f"> - `{method} {path}` - {reason}")

        exclusion_note = "\n".join(exclusion_lines)

        # Use two trailing spaces for markdown line breaks
        br = "  "  # Two spaces for markdown line break
        lines = [
            "# Horizon API vs iOS/macOS SDK Compatibility Matrix",
            "",
            f"**Horizon Version:** {horizon.version} (released {horizon.release_date}){br}",
            f"**Horizon Source:** [{horizon.version}]({horizon.html_url}){br}",
            f"**SDK Version:** {result.sdk_version}{br}",
            f"**Generated:** {generated}",
            "",
            f"**Horizon Endpoints Discovered:** {all_endpoints}{br}",
            f"**Public API Endpoints (in matrix):** {public_endpoints}",
        ]

        if exclusion_note:
            lines.append("")
            lines.append(exclusion_note)

        return "\n".join(lines)

    def _render_legend(self) -> str:
        """Render legend at bottom of document"""
        return """## Legend

- **Full** - Complete implementation with all features
- **Partial** - Basic functionality with some limitations
- **Missing** - Endpoint not implemented"""

    def _render_overall_coverage(self, result: ComparisonResult) -> str:
        """Render overall coverage summary in Flutter style"""
        # Public endpoints = non-excluded, non-internal
        total_endpoints = sum(c.total for c in result.categories)
        total_na = sum(c.na for c in result.categories)
        public_endpoints = total_endpoints - total_na
        full_supported = sum(c.full for c in result.categories)
        partial_supported = sum(c.partial for c in result.categories)
        missing = sum(c.missing for c in result.categories)

        return f"""## Overall Coverage

**Coverage:** {result.overall_coverage:.1f}% ({full_supported + partial_supported}/{public_endpoints} public API endpoints)

- **Fully Supported:** {full_supported}/{public_endpoints}
- **Partially Supported:** {partial_supported}/{public_endpoints}
- **Not Supported:** {missing}/{public_endpoints}"""

    def _render_parameter_coverage(self, result: ComparisonResult) -> str:
        """Render query parameter support summary"""
        # Calculate parameter coverage statistics
        # Only include public endpoints that have SDK methods and are not excluded
        endpoints_with_sdk = [m for m in result.matches if m.sdk_method and not m.endpoint.internal and not m.is_excluded]

        # Count endpoints with/without missing parameters
        total_with_params = 0
        fully_implemented = 0
        missing_params_list = []

        for match in endpoints_with_sdk:
            # Normalize path for parameter lookup
            normalized_path = EndpointComparator.normalize_endpoint_path(match.endpoint.path)
            horizon_params = HORIZON_PARAMS.get((normalized_path, match.endpoint.method), [])

            # Skip endpoints without query parameters
            if not horizon_params:
                continue

            total_with_params += 1

            if not match.missing_params:
                fully_implemented += 1
            else:
                missing_params_list.append({
                    'endpoint': match.endpoint.path,
                    'method': match.endpoint.method,
                    'missing': match.missing_params
                })

        # Calculate percentage
        param_coverage_pct = (fully_implemented / total_with_params * 100.0) if total_with_params > 0 else 0.0

        lines = ["## Query Parameter Support"]
        lines.append(f"\n**Filter Parameters Coverage:** {fully_implemented}/{total_with_params} ({param_coverage_pct:.1f}%)")

        # Show missing parameters if any
        if missing_params_list:
            lines.append("\n### Missing Filter Parameters")
            lines.append("| Endpoint | Method | Missing Parameters |")
            lines.append("|----------|--------|-------------------|")

            # Sort by number of missing params (most first), then by endpoint
            missing_params_list.sort(key=lambda x: (-len(x['missing']), x['endpoint']))

            for item in missing_params_list:
                endpoint = item['endpoint']
                method = item['method']
                missing = ', '.join(item['missing'])
                lines.append(f"| `{endpoint}` | {method} | {missing} |")

        return '\n'.join(lines)

    def _render_compatibility_matrix(self, result: ComparisonResult) -> str:
        """Render endpoint compatibility matrix by category"""
        sections = ["## Detailed Endpoint Comparison"]

        # Group matches by category
        category_matches: Dict[str, List[EndpointMatch]] = {}
        for match in result.matches:
            category = match.endpoint.category
            if category not in category_matches:
                category_matches[category] = []
            category_matches[category].append(match)

        # Render each category
        for category in sorted(category_matches.keys()):
            matches = category_matches[category]
            section = self._render_category_table(category, matches)
            sections.append(section)

        return '\n\n'.join(sections)

    def _render_category_table(self, category: str, matches: List[EndpointMatch]) -> str:
        """Render table for a single category"""
        # Format category name to title case with underscores replaced
        formatted_category = category.replace('_', ' ').title()
        lines = [f"### {formatted_category}"]
        lines.append("")
        lines.append("| Endpoint | Method | Status | SDK Method | Streaming | Notes |")
        lines.append("|----------|--------|--------|------------|-----------|-------|")

        for match in matches:
            # Skip excluded endpoints
            if match.is_excluded:
                continue

            endpoint = match.endpoint
            status = match.coverage_status

            # Status indicator with symbol
            if status == "full":
                status_text = "Full"
            elif status == "partial":
                status_text = "Partial"
            elif status == "missing":
                status_text = "Missing"
            else:
                status_text = "N/A"

            # Streaming indicator - show SDK support (not just Horizon capability)
            streaming = "Yes" if endpoint.streaming and match.streaming_match else ""

            # SDK method
            sdk_method = match.sdk_method.full_name if match.sdk_method else "-"

            # Notes
            notes = match.notes if match.notes else ""

            lines.append(
                f"| `{endpoint.path}` | {endpoint.method} | {status_text} | `{sdk_method}` | {streaming} | {notes} |"
            )

        return '\n'.join(lines)

    def _render_streaming_summary(self, result: ComparisonResult) -> str:
        """Render streaming support summary"""
        # Only include streaming endpoints that are not excluded from streaming consideration
        streaming_endpoints = [
            m for m in result.matches
            if m.endpoint.streaming
            and not m.endpoint.internal
            and not m.is_excluded
            and not m.is_streaming_excluded
        ]
        implemented = [m for m in streaming_endpoints if m.streaming_match]

        if streaming_endpoints:
            coverage = len(implemented) / len(streaming_endpoints) * 100
        else:
            coverage = 0

        return f"""## Streaming Support

**Coverage:** {coverage:.1f}%

- Streaming endpoints: {len(streaming_endpoints)}
- Supported: {len(implemented)}"""

    def _render_coverage_by_category(self, result: ComparisonResult) -> str:
        """Render coverage statistics by category"""
        lines = ["## Coverage by Category"]
        lines.append("")
        lines.append("| Category | Coverage | Supported | Not Supported | Total |")
        lines.append("|----------|----------|-----------|---------------|-------|")

        for category in result.categories:
            if category.name == "Internal/Admin":
                continue

            applicable = category.total - category.na
            supported = category.full + category.partial
            not_supported = category.missing
            coverage = category.coverage_percentage

            lines.append(
                f"| {category.name.lower()} | {coverage:.1f}% | {supported} | {not_supported} | {applicable} |"
            )

        return '\n'.join(lines)


class HorizonMatrixGenerator:
    """Main generator orchestrator"""

    DEFAULT_OUTPUT = "compatibility/horizon/HORIZON_COMPATIBILITY_MATRIX.md"

    def __init__(self, sdk_root: Path, verbose: bool = False):
        self.sdk_root = sdk_root

        if verbose:
            logger.setLevel(logging.DEBUG)

        self.fetcher = HorizonFetcher()
        self.analyzer = SDKAnalyzer(sdk_root)
        self.comparator = EndpointComparator()
        self.renderer = MatrixRenderer()

    def generate(
        self,
        horizon_version: Optional[str] = None,
        output_path: Optional[str] = None,
        skip_api: bool = False
    ) -> int:
        """
        Generate compatibility matrix

        Args:
            horizon_version: Specific Horizon version (None for latest)
            output_path: Output file path (None for default)
            skip_api: Skip GitHub API calls (use manual version info)

        Returns:
            Exit code (0 for success, 1 for failure)
        """
        try:
            # Fetch Horizon release
            if skip_api:
                # Use manual version info to avoid GitHub API rate limits
                version = horizon_version or "v25.0.0"
                horizon_release = HorizonRelease(
                    version=version,
                    tag_name=version,
                    release_date="2025-12-11",
                    html_url=f"https://github.com/stellar/stellar-horizon/releases/tag/{version}"
                )
                logger.info(f"Using manual version info: {version} (--skip-api mode)")
            elif horizon_version:
                horizon_release = self.fetcher.get_release(horizon_version)
            else:
                horizon_release = self.fetcher.get_latest_release()

            logger.info(f"Using Horizon {horizon_release.version}")

            # Fetch and parse router.go
            router_content = self.fetcher.fetch_router(horizon_release.ref)
            horizon_endpoints = self.fetcher.parse_router(router_content)

            # Analyze SDK
            sdk_methods = self.analyzer.analyze_all_services()

            # Compare
            sdk_version = get_sdk_version_from_plist(self.sdk_root)
            result = self.comparator.compare(
                horizon_endpoints,
                sdk_methods,
                horizon_release,
                sdk_version
            )

            # Render
            markdown = self.renderer.render(result)

            # Write output
            if output_path is None:
                output_path = self.sdk_root / self.DEFAULT_OUTPUT
            else:
                output_path = Path(output_path)

            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(markdown, encoding='utf-8')

            logger.info(f"Generated matrix: {output_path}")
            logger.info(f"Coverage: {result.overall_coverage:.1f}%")

            return 0

        except Exception as e:
            logger.error(f"Error generating matrix: {e}", exc_info=True)
            return 1


def main() -> int:
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Generate Horizon API compatibility matrix for Stellar iOS/Mac SDK",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate matrix against latest Horizon
  python generate_horizon_matrix.py

  # Specify Horizon version
  python generate_horizon_matrix.py --horizon-version v25.0.0

  # Custom output path
  python generate_horizon_matrix.py --output custom.md

  # Verbose mode
  python generate_horizon_matrix.py --verbose
        """
    )

    parser.add_argument(
        '--horizon-version',
        type=str,
        help='Specific Horizon version to compare against (e.g., v25.0.0). Default: latest'
    )

    parser.add_argument(
        '--output',
        type=str,
        help=f'Output file path. Default: {HorizonMatrixGenerator.DEFAULT_OUTPUT}'
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )

    parser.add_argument(
        '--skip-api',
        action='store_true',
        help='Skip GitHub API calls (use with --horizon-version to avoid rate limits)'
    )

    args = parser.parse_args()

    # Determine SDK root
    sdk_root = Path(__file__).parent.parent.parent.parent

    # Create generator
    generator = HorizonMatrixGenerator(
        sdk_root=sdk_root,
        verbose=args.verbose
    )

    # Generate matrix
    return generator.generate(
        horizon_version=args.horizon_version,
        output_path=args.output,
        skip_api=args.skip_api
    )


if __name__ == '__main__':
    sys.exit(main())
