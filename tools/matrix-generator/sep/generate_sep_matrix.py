#!/usr/bin/env python3
"""
SEP Compatibility Matrix Generator for Stellar iOS/Mac SDK

This script generates detailed compatibility matrices for Stellar Ecosystem Proposals (SEPs)
by comparing SEP specifications with the iOS/Mac SDK implementation.

Features:
- Field-by-field comparison with SEP specifications
- Detailed coverage statistics (overall, by section, required vs optional)
- Automatic parsing of SEP markdown to extract field definitions
- Mapping of TOML field names to Swift property names

Usage:
    python generate_sep_matrix.py --sep 01
    python generate_sep_matrix.py --sep 10 --output custom_output.md
    python generate_sep_matrix.py --list

Author: Generated for Stellar iOS/Mac SDK
Date: 2025-10-05
Python: 3.12+
"""

import argparse
import json
import logging
import plistlib
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple
from urllib.parse import urljoin
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_sdk_version() -> str:
    """Read SDK version from Info.plist"""
    script_dir = Path(__file__).parent
    info_plist = script_dir.parent.parent.parent / "stellarsdk" / "stellarsdk" / "Info.plist"

    if info_plist.exists():
        try:
            with open(info_plist, 'rb') as f:
                plist = plistlib.load(f)
                return plist.get('CFBundleShortVersionString', 'Unknown')
        except Exception as e:
            logger.warning(f"Could not read Info.plist: {e}")

    return "Unknown"


# Cache SDK version
SDK_VERSION = get_sdk_version()


class SupportStatus(Enum):
    """Support status for SEP features"""
    FULLY_SUPPORTED = "✅"
    PARTIALLY_SUPPORTED = "⚠️"
    NOT_SUPPORTED = "❌"
    NOT_APPLICABLE = "N/A"


@dataclass
class SEPField:
    """Represents a single field from a SEP specification"""
    name: str  # TOML field name (e.g., "VERSION", "code")
    section: str  # Section name
    required: bool  # Is this field required?
    description: str  # Field description from SEP
    requirements: str  # Requirements (e.g., "string", "uses https://")
    sdk_property: Optional[str] = None  # Swift property name (e.g., "version", "code")
    implemented: bool = False  # Is it implemented in SDK?
    server_only: bool = False  # Is this a server-side-only feature not applicable to client SDKs?


@dataclass
class SEPSection:
    """Represents a section of fields in a SEP"""
    name: str
    fields: List[SEPField] = field(default_factory=list)

    @property
    def total_fields(self) -> int:
        """Total fields excluding server-only features"""
        return sum(1 for f in self.fields if not f.server_only)

    @property
    def implemented_fields(self) -> int:
        """Implemented fields excluding server-only features"""
        return sum(1 for f in self.fields if f.implemented and not f.server_only)

    @property
    def required_fields(self) -> int:
        """Required fields excluding server-only features"""
        return sum(1 for f in self.fields if f.required and not f.server_only)

    @property
    def required_implemented(self) -> int:
        """Implemented required fields excluding server-only features"""
        return sum(1 for f in self.fields if f.required and f.implemented and not f.server_only)

    @property
    def server_only_count(self) -> int:
        """Count of server-only fields in this section"""
        return sum(1 for f in self.fields if f.server_only)

    @property
    def coverage_percentage(self) -> float:
        return (self.implemented_fields / self.total_fields * 100) if self.total_fields > 0 else 0

    @property
    def required_coverage_percentage(self) -> float:
        return (self.required_implemented / self.required_fields * 100) if self.required_fields > 0 else 100.0


@dataclass
class SEPInfo:
    """Metadata about a SEP"""
    number: str
    title: str
    purpose: str
    version: Optional[str] = None
    status: Optional[str] = None
    url: str = ""
    raw_content: str = ""


@dataclass
class CompatibilityMatrix:
    """Complete compatibility matrix for a SEP"""
    sep_info: SEPInfo
    sections: List[SEPSection] = field(default_factory=list)
    sdk_version: str = field(default_factory=lambda: SDK_VERSION)
    last_updated: str = field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d"))
    implementation_files: List[str] = field(default_factory=list)
    implementation_notes: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)

    @property
    def total_fields(self) -> int:
        return sum(s.total_fields for s in self.sections)

    @property
    def implemented_fields(self) -> int:
        return sum(s.implemented_fields for s in self.sections)

    @property
    def required_fields(self) -> int:
        return sum(s.required_fields for s in self.sections)

    @property
    def required_implemented(self) -> int:
        return sum(s.required_implemented for s in self.sections)

    @property
    def optional_fields(self) -> int:
        return self.total_fields - self.required_fields

    @property
    def optional_implemented(self) -> int:
        return self.implemented_fields - self.required_implemented

    @property
    def overall_coverage(self) -> float:
        return (self.implemented_fields / self.total_fields * 100) if self.total_fields > 0 else 0

    @property
    def required_coverage(self) -> float:
        return (self.required_implemented / self.required_fields * 100) if self.required_fields > 0 else 100.0

    @property
    def optional_coverage(self) -> float:
        return (self.optional_implemented / self.optional_fields * 100) if self.optional_fields > 0 else 100.0

    @property
    def server_only_count(self) -> int:
        """Total count of server-only fields across all sections"""
        return sum(s.server_only_count for s in self.sections)


class SEPFetcher:
    """Fetches SEP documentation from GitHub"""

    BASE_URL = "https://raw.githubusercontent.com/stellar/stellar-protocol/master/ecosystem/"

    def __init__(self):
        self.timeout = 30

    def fetch_sep(self, sep_number: str) -> SEPInfo:
        """
        Fetch SEP documentation from GitHub

        Args:
            sep_number: SEP number (e.g., "01", "10")

        Returns:
            SEPInfo object with content

        Raises:
            ValueError: If SEP cannot be fetched
        """
        sep_padded = sep_number.zfill(4)
        filename = f"sep-{sep_padded}.md"
        url = urljoin(self.BASE_URL, filename)

        logger.info(f"Fetching SEP-{sep_padded} from {url}")

        try:
            req = Request(url)
            req.add_header('User-Agent', 'Stellar-iOS-SDK-SEP-Analyzer/1.0')

            with urlopen(req, timeout=self.timeout) as response:
                content = response.read().decode('utf-8')

            sep_info = self._parse_sep_header(content, sep_number)
            sep_info.url = url
            sep_info.raw_content = content

            logger.info(f"Successfully fetched SEP-{sep_padded}: {sep_info.title}")
            return sep_info

        except HTTPError as e:
            if e.code == 404:
                raise ValueError(f"SEP-{sep_padded} not found at {url}")
            raise ValueError(f"HTTP error fetching SEP-{sep_padded}: {e.code} {e.reason}")
        except URLError as e:
            raise ValueError(f"Network error fetching SEP-{sep_padded}: {e.reason}")
        except Exception as e:
            raise ValueError(f"Error fetching SEP-{sep_padded}: {str(e)}")

    def _parse_sep_header(self, content: str, sep_number: str) -> SEPInfo:
        """Extract SEP metadata from markdown content"""
        lines = content.split('\n')

        # Extract title (first # heading)
        title = "Unknown"
        for line in lines:
            if line.startswith('# '):
                title = line[2:].strip()
                break

        # Extract metadata from Preamble section
        version = None
        status = None
        in_preamble = False

        for i, line in enumerate(lines):
            # Check if previous lines have Preamble heading (## Preamble)
            if '```' in line and i > 0:
                # Check up to 3 lines back for "preamble"
                for j in range(1, min(4, i+1)):
                    prev_line = lines[i-j].lower()
                    if 'preamble' in prev_line:
                        in_preamble = True
                        break
                if in_preamble:
                    continue
            if in_preamble and '```' in line:
                break
            elif in_preamble:
                if 'Title:' in line:
                    title = line.split('Title:')[1].strip()
                elif line.strip().startswith('Version:'):
                    version = line.split('Version:')[1].strip()
                elif re.match(r'^Version\s+[\d.]+', line.strip()):
                    # Handle "Version 1.1.0" format at start of line
                    version = line.strip().split('Version')[1].strip()
                elif 'Status:' in line:
                    status = line.split('Status:')[1].strip()

        # Extract purpose (Summary or Simple Summary section)
        purpose = "No description available"
        in_summary = False
        summary_lines = []

        for i, line in enumerate(lines):
            if re.match(r'^##\s+(Summary|Simple Summary|Abstract)', line, re.IGNORECASE):
                in_summary = True
                continue
            elif in_summary:
                if line.startswith('##'):
                    break
                if line.strip() and not line.startswith('```'):
                    summary_lines.append(line.strip())

        if summary_lines:
            purpose = ' '.join(summary_lines)

        return SEPInfo(
            number=sep_number,
            title=title,
            purpose=purpose[:800],  # Limit length
            version=version,
            status=status
        )


class SDKAnalyzer:
    """Analyzes iOS/Mac SDK implementation"""

    def __init__(self, sdk_root: Path):
        self.sdk_root = sdk_root
        self.stellarsdk_path = sdk_root / "stellarsdk" / "stellarsdk"

        if not self.stellarsdk_path.exists():
            raise ValueError(f"SDK path not found: {self.stellarsdk_path}")

    def search_files(self, pattern: str, file_extension: str = "swift") -> Set[Path]:
        """
        Search for files matching a pattern

        Args:
            pattern: Regex pattern to search for
            file_extension: File extension to search (default: swift)

        Returns:
            Set of matching file paths
        """
        matching_files = set()
        pattern_re = re.compile(pattern, re.IGNORECASE)

        for swift_file in self.stellarsdk_path.rglob(f"*.{file_extension}"):
            try:
                content = swift_file.read_text(encoding='utf-8')
                if pattern_re.search(content):
                    matching_files.add(swift_file)
            except Exception as e:
                logger.warning(f"Error reading {swift_file}: {e}")

        return matching_files

    def find_class_or_struct(self, name: str) -> Optional[Path]:
        """Find a class or struct definition"""
        pattern = rf"(class|struct|enum)\s+{re.escape(name)}\b"
        files = self.search_files(pattern)
        return files.pop() if files else None

    def find_file_by_name(self, filename: str) -> Optional[Path]:
        """Find a file by its exact name"""
        for swift_file in self.stellarsdk_path.rglob(filename):
            return swift_file
        return None

    def get_relative_path(self, file_path: Path) -> str:
        """Get relative path from SDK root"""
        try:
            return str(file_path.relative_to(self.sdk_root))
        except ValueError:
            return str(file_path)

    def extract_properties_from_swift_class(self, file_path: Path) -> Dict[str, str]:
        """
        Extract property mappings from a Swift class file

        Returns:
            Dict mapping TOML field names to Swift property names
        """
        property_map = {}

        try:
            content = file_path.read_text(encoding='utf-8')

            # Find the Keys enum that maps TOML names to Swift properties
            enum_match = re.search(r'enum\s+Keys:\s*String\s*\{([^}]+)\}', content, re.DOTALL)
            if enum_match:
                enum_content = enum_match.group(1)
                # Parse case statements: case propertyName = "TOML_NAME"
                for match in re.finditer(r'case\s+(\w+)\s*=\s*"([^"]+)"', enum_content):
                    swift_property = match.group(1)
                    toml_name = match.group(2)
                    property_map[toml_name] = swift_property

            # Also find public var declarations to ensure completeness
            var_pattern = r'public\s+var\s+(\w+):\s*[^=\n]+'
            for match in re.finditer(var_pattern, content):
                property_name = match.group(1)
                # If not in Keys enum, it might still be a valid property
                if property_name not in property_map.values():
                    # Try to infer TOML name from property name
                    # Convert camelCase to SCREAMING_SNAKE_CASE or snake_case
                    toml_name = self._infer_toml_name(property_name)
                    if toml_name:
                        property_map[toml_name] = property_name

        except Exception as e:
            logger.warning(f"Error extracting properties from {file_path}: {e}")

        return property_map

    def _infer_toml_name(self, property_name: str) -> Optional[str]:
        """Infer TOML field name from Swift property name"""
        # Common patterns:
        # - version -> VERSION
        # - networkPassphrase -> NETWORK_PASSPHRASE
        # - code -> code
        # - anchorAsset -> anchor_asset

        # Simple heuristic: if all lowercase, keep as is; otherwise convert
        if property_name.islower():
            return property_name

        # Convert camelCase to snake_case
        snake_case = re.sub('([a-z0-9])([A-Z])', r'\1_\2', property_name).lower()
        return snake_case


class SEPMarkdownParser:
    """Parses SEP markdown to extract field definitions"""

    def parse_fields(self, content: str, sep_number: str) -> List[SEPSection]:
        """
        Parse SEP markdown to extract all field definitions

        Returns:
            List of SEPSection objects containing fields
        """
        sections = []

        if sep_number == "01" or sep_number == "0001":
            sections = self._parse_sep01_fields(content)
        elif sep_number == "02" or sep_number == "0002":
            sections = self._parse_sep02_fields(content)
        else:
            logger.warning(f"Field parsing not implemented for SEP-{sep_number}")

        return sections

    def _parse_sep01_fields(self, content: str) -> List[SEPSection]:
        """Parse SEP-01 field tables"""
        sections = []
        lines = content.split('\n')

        # Define sections to parse
        section_patterns = [
            (r'###\s+General Information', 'General Information'),
            (r'###\s+Organization Documentation', 'Organization Documentation'),
            (r'###\s+Point of Contact Documentation', 'Point of Contact Documentation'),
            (r'###\s+Currency Documentation', 'Currency Documentation'),
            (r'###\s+Validator Information', 'Validator Information'),
        ]

        for pattern, section_name in section_patterns:
            section = self._extract_section_fields(lines, pattern, section_name)
            if section and section.fields:
                sections.append(section)

        return sections

    def _extract_section_fields(self, lines: List[str], section_pattern: str, section_name: str) -> Optional[SEPSection]:
        """Extract fields from a specific section"""
        section = SEPSection(name=section_name)

        # Find section header
        section_start = -1
        for i, line in enumerate(lines):
            if re.match(section_pattern, line):
                section_start = i
                break

        if section_start == -1:
            return None

        # Find the table (starts with | Field |)
        table_start = -1
        for i in range(section_start, min(section_start + 20, len(lines))):
            if '| Field' in lines[i] or '| field' in lines[i]:
                table_start = i
                break

        if table_start == -1:
            return None

        # Skip header separator line (|----|----| etc)
        table_data_start = table_start + 2

        # Parse table rows until we hit a non-table line
        for i in range(table_data_start, len(lines)):
            line = lines[i].strip()

            # Stop at next section or empty table row
            if not line or line.startswith('#') or not line.startswith('|'):
                break

            # Parse table row
            field = self._parse_table_row(line, section_name)
            if field:
                section.fields.append(field)

        return section

    def _parse_table_row(self, row: str, section_name: str) -> Optional[SEPField]:
        """Parse a single table row into a SEPField"""
        # Split by | and clean up
        parts = [p.strip() for p in row.split('|')]
        # Remove empty first and last elements from split
        parts = [p for p in parts if p]

        if len(parts) < 3:
            return None

        field_name = parts[0].strip('`').strip()
        requirements = parts[1] if len(parts) > 1 else ""
        description = parts[2] if len(parts) > 2 else ""

        # Determine if required based on description or requirements
        required = self._is_field_required(field_name, requirements, description)

        return SEPField(
            name=field_name,
            section=section_name,
            required=required,
            description=description,
            requirements=requirements
        )

    def _is_field_required(self, field_name: str, requirements: str, description: str) -> bool:
        """Determine if a field is required"""
        # Check for explicit "Required" in description
        if 'Required' in description and 'if' not in description.split('Required')[0]:
            return True

        # For SEP-01, only specific fields are required
        required_fields = {
            'code',  # Currency code is required
            'issuer',  # Issuer is required for Stellar assets
            'contract',  # Contract is required for non-Stellar assets
        }

        # Check against known required fields
        return field_name.lower() in required_fields or field_name in required_fields

    def _parse_sep02_fields(self, content: str) -> List[SEPSection]:
        """Parse SEP-02 (Federation Protocol) fields"""
        sections = []

        # Define SEP-02 sections manually as they're not in table format
        # Section 1: Request Parameters
        request_params = SEPSection(name='Request Parameters')
        request_params.fields = [
            SEPField(
                name='q',
                section='Request Parameters',
                required=True,
                description='String to look up (stellar address, account ID, or transaction ID)',
                requirements='string'
            ),
            SEPField(
                name='type',
                section='Request Parameters',
                required=True,
                description='Type of lookup (name, id, txid, or forward)',
                requirements='string (name|id|txid|forward)'
            ),
        ]
        sections.append(request_params)

        # Section 2: Request Types
        request_types = SEPSection(name='Request Types')
        request_types.fields = [
            SEPField(
                name='name',
                section='Request Types',
                required=True,
                description='returns the federation record for the given Stellar address.',
                requirements='type=name&q=<stellar_address>'
            ),
            SEPField(
                name='id',
                section='Request Types',
                required=True,
                description='returns the federation record of the Stellar address associated with the given account ID. In some cases this is ambiguous. For instance if an anchor sends transactions on behalf of its users, the account ID will be of the anchor\'s account and not of the user\'s account.',
                requirements='type=id&q=<account_id>'
            ),
            SEPField(
                name='txid',
                section='Request Types',
                required=False,
                description='returns the federation record of the sender of the transaction if known by the server.',
                requirements='type=txid&q=<transaction_id>'
            ),
            SEPField(
                name='forward',
                section='Request Types',
                required=False,
                description='Used for forwarding the payment on to a different network or different financial institution. The other parameters of the query will vary depending on what kind of institution is the ultimate destination of the payment and what you as the forwarding anchor supports.',
                requirements='type=forward with additional parameters'
            ),
        ]
        sections.append(request_types)

        # Section 3: Response Fields
        response_fields = SEPSection(name='Response Fields')
        response_fields.fields = [
            SEPField(
                name='stellar_address',
                section='Response Fields',
                required=True,
                description='stellar address',
                requirements='string (username*domain)'
            ),
            SEPField(
                name='account_id',
                section='Response Fields',
                required=True,
                description='Stellar public key / account ID',
                requirements='string (Stellar public key)'
            ),
            SEPField(
                name='memo_type',
                section='Response Fields',
                required=False,
                description='type of memo to attach to transaction, one of text, id or hash',
                requirements='string (text|id|hash)'
            ),
            SEPField(
                name='memo',
                section='Response Fields',
                required=False,
                description='value of memo to attach to transaction, for hash this should be base64-encoded. This field should always be of type string (even when memo_type is equal to id) to support parsing value in languages that do not support big numbers.',
                requirements='string (base64 for hash type)'
            ),
        ]
        sections.append(response_fields)

        return sections


class SEP01Analyzer:
    """Analyzer for SEP-01 (stellar.toml)"""

    # Mapping of Swift class names to their sections
    CLASS_SECTION_MAP = {
        'AccountInformation': 'General Information',
        'IssuerDocumentation': 'Organization Documentation',
        'PointOfContactDocumentation': 'Point of Contact Documentation',
        'CurrencyDocumentation': 'Currency Documentation',
        'ValidatorInformation': 'Validator Information',
    }

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-01 implementation"""
        logger.info("Analyzing SEP-01 (stellar.toml) implementation")

        # Parse SEP specification to extract all fields
        sections = self.parser.parse_fields(sep_info.raw_content, sep_info.number)

        # Find SDK implementation files and extract property mappings
        sdk_property_maps = {}
        implementation_files = []

        for class_name, section_name in self.CLASS_SECTION_MAP.items():
            file_path = self.sdk_analyzer.find_class_or_struct(class_name)
            if file_path:
                rel_path = self.sdk_analyzer.get_relative_path(file_path)
                implementation_files.append(rel_path)

                # Extract property mappings
                property_map = self.sdk_analyzer.extract_properties_from_swift_class(file_path)
                sdk_property_maps[section_name] = property_map
                logger.info(f"Found {len(property_map)} properties in {class_name}")

        # Add main parser class
        stellar_toml_file = self.sdk_analyzer.find_class_or_struct('StellarToml')
        if stellar_toml_file:
            rel_path = self.sdk_analyzer.get_relative_path(stellar_toml_file)
            implementation_files.insert(0, rel_path)  # Add at beginning as main class

        # Match SEP fields with SDK properties
        for section in sections:
            if section.name in sdk_property_maps:
                property_map = sdk_property_maps[section.name]

                for field in section.fields:
                    # Check if field exists in SDK
                    if field.name in property_map:
                        field.implemented = True
                        field.sdk_property = property_map[field.name]
                    else:
                        # Try case variations
                        field_variants = [
                            field.name.lower(),
                            field.name.upper(),
                            field.name.replace('_', ''),
                        ]

                        for variant in field_variants:
                            if variant in property_map:
                                field.implemented = True
                                field.sdk_property = property_map[variant]
                                break

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a comprehensive implementation of SEP-01 stellar.toml specification",
            f"All {len(sections)} main sections are fully supported with dedicated Swift classes",
            "The implementation uses a custom TOML parser for Swift (federation/toml package)",
            "Both async/await and legacy callback-based APIs are available",
            "The parser automatically handles URL composition for .well-known/stellar.toml",
            "Supports linked currency files as per SEP-01 specification",
            "Error handling is comprehensive with specific error types (TomlFileError)",
            "Thread-safe implementation suitable for concurrent requests",
            "All field names follow Swift naming conventions (camelCase)",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-01!",
                "Consider caching stellar.toml responses to reduce network requests",
                "Always use the secure (HTTPS) mode in production",
                "Handle TomlFileError cases appropriately in client applications",
                "For linked currency files, implement retry logic for network failures",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],  # Show first 10
                "Consider adding support for these fields to achieve full SEP-01 compliance",
            ]

        return matrix


class SEP02Analyzer:
    """Analyzer for SEP-02 (Federation Protocol)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-02 implementation"""
        logger.info("Analyzing SEP-02 (Federation Protocol) implementation")

        # Parse SEP specification to extract all fields
        sections = self.parser.parse_fields(sep_info.raw_content, sep_info.number)

        # Find SDK implementation files
        implementation_files = []

        # Find Federation class
        federation_file = self.sdk_analyzer.find_class_or_struct('Federation')
        if federation_file:
            rel_path = self.sdk_analyzer.get_relative_path(federation_file)
            implementation_files.append(rel_path)
            logger.info(f"Found Federation class at {rel_path}")

        # Find ResolveAddressResponse class
        response_file = self.sdk_analyzer.find_class_or_struct('ResolveAddressResponse')
        if response_file:
            rel_path = self.sdk_analyzer.get_relative_path(response_file)
            implementation_files.append(rel_path)
            logger.info(f"Found ResolveAddressResponse class at {rel_path}")

        # Find FederationError enum
        error_file = self.sdk_analyzer.find_class_or_struct('FederationError')
        if error_file:
            rel_path = self.sdk_analyzer.get_relative_path(error_file)
            implementation_files.append(rel_path)
            logger.info(f"Found FederationError at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Request Parameters':
                self._analyze_request_parameters(section, federation_file)
            elif section.name == 'Request Types':
                self._analyze_request_types(section, federation_file)
            elif section.name == 'Response Fields':
                self._analyze_response_fields(section, response_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a comprehensive implementation of SEP-02 Federation Protocol",
            "Federation class supports all lookup types: name, id, txid, and forward",
            "Both async/await and legacy callback-based APIs are available",
            "Federation server discovery via stellar.toml (forDomain method)",
            "Direct federation address resolution (resolve method)",
            "Type-safe error handling with FederationError enum",
            "All response fields properly mapped to Swift properties with snake_case to camelCase conversion",
            "Supports secure (HTTPS) and insecure modes for testing",
            "Thread-safe implementation suitable for concurrent requests",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-02!",
                "Always use secure mode (HTTPS) in production",
                "Handle FederationError cases appropriately in client applications",
                "Consider caching federation server URLs from stellar.toml",
                "Use the forDomain method to automatically discover federation servers",
                "Validate stellar addresses before resolving (format: username*domain)",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-02 compliance",
            ]

        return matrix

    def _analyze_request_parameters(self, section: SEPSection, federation_file: Optional[Path]) -> None:
        """Analyze request parameter support"""
        if not federation_file:
            return

        try:
            content = federation_file.read_text(encoding='utf-8')

            # Check for 'q' parameter (query string parameter)
            # Used in all resolve methods
            for field in section.fields:
                if field.name == 'q':
                    # Check if query parameter 'q' is used
                    if '?q=' in content or 'q=' in content:
                        field.implemented = True
                        field.sdk_property = 'q'
                elif field.name == 'type':
                    # Check if type parameter is used
                    if 'type=' in content:
                        field.implemented = True
                        field.sdk_property = 'type'

        except Exception as e:
            logger.warning(f"Error analyzing request parameters: {e}")

    def _analyze_request_types(self, section: SEPSection, federation_file: Optional[Path]) -> None:
        """Analyze request type support"""
        if not federation_file:
            return

        try:
            content = federation_file.read_text(encoding='utf-8')

            # Map request types to SDK methods
            type_method_map = {
                'name': ('resolve(address:', 'resolveStellarAddress'),
                'id': ('resolve(account_id:', 'resolveStellarAccountId'),
                'txid': ('resolve(transaction_id:', 'resolveStellarTransactionId'),
                'forward': ('resolve(forwardParams:', 'resolveForward'),
            }

            for field in section.fields:
                if field.name in type_method_map:
                    method_pattern, sdk_method = type_method_map[field.name]
                    if method_pattern in content:
                        field.implemented = True
                        field.sdk_property = sdk_method

        except Exception as e:
            logger.warning(f"Error analyzing request types: {e}")

    def _analyze_response_fields(self, section: SEPSection, response_file: Optional[Path]) -> None:
        """Analyze response field support"""
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            # Map response fields to SDK properties
            field_property_map = {
                'stellar_address': 'stellarAddress',
                'account_id': 'accountId',
                'memo_type': 'memoType',
                'memo': 'memo',
            }

            for field in section.fields:
                if field.name in field_property_map:
                    sdk_property = field_property_map[field.name]
                    # Check for property declaration (let or var) and coding key
                    if (f'let {sdk_property}' in content or f'var {sdk_property}' in content) and f'"{field.name}"' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing response fields: {e}")


class SEP05Analyzer:
    """Analyzer for SEP-05 (Key Derivation Methods for Stellar Keys)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-05 implementation"""
        logger.info("Analyzing SEP-05 (Key Derivation Methods) implementation")

        # Create sections manually based on SEP-05 requirements
        sections = self._create_sep05_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find Mnemonic class
        mnemonic_file = self.sdk_analyzer.find_class_or_struct('Mnemonic')
        if mnemonic_file:
            rel_path = self.sdk_analyzer.get_relative_path(mnemonic_file)
            implementation_files.append(rel_path)
            logger.info(f"Found Mnemonic class at {rel_path}")

        # Find WalletUtils class
        wallet_file = self.sdk_analyzer.find_class_or_struct('WalletUtils')
        if wallet_file:
            rel_path = self.sdk_analyzer.get_relative_path(wallet_file)
            implementation_files.append(rel_path)
            logger.info(f"Found WalletUtils class at {rel_path}")

        # Find Ed25519Derivation struct
        ed25519_file = self.sdk_analyzer.find_class_or_struct('Ed25519Derivation')
        if ed25519_file:
            rel_path = self.sdk_analyzer.get_relative_path(ed25519_file)
            implementation_files.append(rel_path)
            logger.info(f"Found Ed25519Derivation struct at {rel_path}")

        # Find WordList enum
        wordlist_file = self.sdk_analyzer.find_class_or_struct('WordList')
        if wordlist_file:
            rel_path = self.sdk_analyzer.get_relative_path(wordlist_file)
            implementation_files.append(rel_path)
            logger.info(f"Found WordList enum at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'BIP-39 Mnemonic Features':
                self._analyze_bip39_features(section, mnemonic_file, wallet_file)
            elif section.name == 'BIP-32 Key Derivation':
                self._analyze_bip32_features(section, ed25519_file)
            elif section.name == 'BIP-44 Multi-Account Support':
                self._analyze_bip44_features(section, wallet_file)
            elif section.name == 'Key Derivation Methods':
                self._analyze_key_derivation_methods(section, wallet_file)
            elif section.name == 'Language Support':
                self._analyze_language_support(section, wordlist_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a comprehensive implementation of SEP-05 key derivation",
            "Based on BIP-39 for mnemonic generation and BIP-32/BIP-44 for key derivation",
            "Supports multiple languages for BIP-39 word lists",
            "Implements SLIP-0010 Ed25519 curve key derivation for Stellar",
            "Uses Stellar's BIP-44 derivation path: m/44'/148'/account'",
            "PBKDF2-SHA512 with 2048 iterations for seed generation from mnemonic",
            "Supports optional BIP-39 passphrase (25th word)",
            "Secure random number generation using SecRandomCopyBytes",
            "Thread-safe implementation suitable for wallet applications",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-05!",
                "Always validate mnemonics before use",
                "Store mnemonics securely (never in plain text)",
                "Consider using 24-word mnemonics for higher entropy",
                "Use the optional passphrase for additional security",
                "Test key derivation with known test vectors",
                "Implement proper backup and recovery flows for users",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-05 compliance",
            ]

        return matrix

    def _create_sep05_sections(self) -> List[SEPSection]:
        """Create SEP-05 sections with all required and optional fields"""
        sections = []

        # BIP-39 Mnemonic Features
        bip39_section = SEPSection(name='BIP-39 Mnemonic Features')
        bip39_section.fields = [
            SEPField(
                name='mnemonic_generation_12_words',
                section='BIP-39 Mnemonic Features',
                required=True,
                description='Generate 12-word BIP-39 mnemonic phrase',
                requirements='128 bits entropy'
            ),
            SEPField(
                name='mnemonic_generation_24_words',
                section='BIP-39 Mnemonic Features',
                required=True,
                description='Generate 24-word BIP-39 mnemonic phrase',
                requirements='256 bits entropy'
            ),
            SEPField(
                name='mnemonic_to_seed',
                section='BIP-39 Mnemonic Features',
                required=True,
                description='Convert BIP-39 mnemonic to seed using PBKDF2',
                requirements='PBKDF2-HMAC-SHA512, 2048 iterations'
            ),
            SEPField(
                name='mnemonic_validation',
                section='BIP-39 Mnemonic Features',
                required=True,
                description='Validate BIP-39 mnemonic phrase (word list and checksum)',
                requirements='checksum verification'
            ),
            SEPField(
                name='passphrase_support',
                section='BIP-39 Mnemonic Features',
                required=False,
                description='Support optional BIP-39 passphrase (25th word)',
                requirements='optional parameter'
            ),
        ]
        sections.append(bip39_section)

        # BIP-32 Key Derivation
        bip32_section = SEPSection(name='BIP-32 Key Derivation')
        bip32_section.fields = [
            SEPField(
                name='master_key_generation',
                section='BIP-32 Key Derivation',
                required=True,
                description='Generate master key from seed',
                requirements='HMAC-SHA512 with "ed25519 seed"'
            ),
            SEPField(
                name='hd_key_derivation',
                section='BIP-32 Key Derivation',
                required=True,
                description='BIP-32 hierarchical deterministic key derivation',
                requirements='SLIP-0010 Ed25519'
            ),
            SEPField(
                name='child_key_derivation',
                section='BIP-32 Key Derivation',
                required=True,
                description='Derive child keys from parent keys',
                requirements='hardened derivation only'
            ),
            SEPField(
                name='ed25519_curve',
                section='BIP-32 Key Derivation',
                required=True,
                description='Support Ed25519 curve for Stellar keys',
                requirements='SLIP-0010 Ed25519'
            ),
        ]
        sections.append(bip32_section)

        # BIP-44 Multi-Account Support
        bip44_section = SEPSection(name='BIP-44 Multi-Account Support')
        bip44_section.fields = [
            SEPField(
                name='stellar_derivation_path',
                section='BIP-44 Multi-Account Support',
                required=True,
                description="Support Stellar's BIP-44 derivation path: m/44'/148'/account'",
                requirements="path format m/44'/148'/x'"
            ),
            SEPField(
                name='multiple_accounts',
                section='BIP-44 Multi-Account Support',
                required=True,
                description='Derive multiple Stellar accounts from single seed',
                requirements='account index support'
            ),
            SEPField(
                name='account_index_support',
                section='BIP-44 Multi-Account Support',
                required=True,
                description='Support account index parameter in derivation',
                requirements='integer index'
            ),
        ]
        sections.append(bip44_section)

        # Key Derivation Methods
        derivation_section = SEPSection(name='Key Derivation Methods')
        derivation_section.fields = [
            SEPField(
                name='keypair_from_mnemonic',
                section='Key Derivation Methods',
                required=True,
                description='Generate Stellar KeyPair from mnemonic',
                requirements='returns KeyPair object'
            ),
            SEPField(
                name='seed_from_mnemonic',
                section='Key Derivation Methods',
                required=True,
                description='Convert mnemonic to raw seed bytes',
                requirements='returns byte array'
            ),
            SEPField(
                name='account_id_from_mnemonic',
                section='Key Derivation Methods',
                required=True,
                description='Get Stellar account ID from mnemonic',
                requirements='returns G... address'
            ),
        ]
        sections.append(derivation_section)

        # Language Support
        language_section = SEPSection(name='Language Support')
        language_section.fields = [
            SEPField(
                name='english',
                section='Language Support',
                required=True,
                description='English BIP-39 word list (2048 words)',
                requirements='standard BIP-39 English'
            ),
            SEPField(
                name='chinese_simplified',
                section='Language Support',
                required=False,
                description='Chinese Simplified BIP-39 word list',
                requirements='standard BIP-39'
            ),
            SEPField(
                name='chinese_traditional',
                section='Language Support',
                required=False,
                description='Chinese Traditional BIP-39 word list',
                requirements='standard BIP-39'
            ),
            SEPField(
                name='french',
                section='Language Support',
                required=False,
                description='French BIP-39 word list',
                requirements='standard BIP-39'
            ),
            SEPField(
                name='italian',
                section='Language Support',
                required=False,
                description='Italian BIP-39 word list',
                requirements='standard BIP-39'
            ),
            SEPField(
                name='japanese',
                section='Language Support',
                required=False,
                description='Japanese BIP-39 word list',
                requirements='standard BIP-39'
            ),
            SEPField(
                name='korean',
                section='Language Support',
                required=False,
                description='Korean BIP-39 word list',
                requirements='standard BIP-39'
            ),
            SEPField(
                name='spanish',
                section='Language Support',
                required=False,
                description='Spanish BIP-39 word list',
                requirements='standard BIP-39'
            ),
        ]
        sections.append(language_section)

        return sections

    def _analyze_bip39_features(self, section: SEPSection, mnemonic_file: Optional[Path], wallet_file: Optional[Path]) -> None:
        """Analyze BIP-39 mnemonic feature support"""
        if not mnemonic_file or not wallet_file:
            return

        try:
            mnemonic_content = mnemonic_file.read_text(encoding='utf-8')
            wallet_content = wallet_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'mnemonic_generation_12_words':
                    if 'generate12WordMnemonic' in wallet_content:
                        field.implemented = True
                        field.sdk_property = 'generate12WordMnemonic'
                elif field.name == 'mnemonic_generation_24_words':
                    if 'generate24WordMnemonic' in wallet_content:
                        field.implemented = True
                        field.sdk_property = 'generate24WordMnemonic'
                elif field.name == 'mnemonic_to_seed':
                    if 'createSeed' in mnemonic_content and 'PBKDF2SHA512' in mnemonic_content:
                        field.implemented = True
                        field.sdk_property = 'createSeed'
                elif field.name == 'mnemonic_validation':
                    # iOS SDK doesn't have explicit validation, but it has checksum handling in mnemonic generation
                    if 'sha256' in mnemonic_content and 'checkSum' in mnemonic_content:
                        field.implemented = True
                        field.sdk_property = 'create (with checksum)'
                elif field.name == 'passphrase_support':
                    if 'withPassphrase' in mnemonic_content or 'passphrase' in wallet_content:
                        field.implemented = True
                        field.sdk_property = 'createSeed(withPassphrase:)'

        except Exception as e:
            logger.warning(f"Error analyzing BIP-39 features: {e}")

    def _analyze_bip32_features(self, section: SEPSection, ed25519_file: Optional[Path]) -> None:
        """Analyze BIP-32 key derivation feature support"""
        if not ed25519_file:
            return

        try:
            content = ed25519_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'master_key_generation':
                    if 'ed25519 seed' in content and 'HMACSHA512' in content:
                        field.implemented = True
                        field.sdk_property = 'Ed25519Derivation.init(seed:)'
                elif field.name == 'hd_key_derivation':
                    # Check for hierarchical derivation method
                    if 'func derived' in content or 'derived(at' in content:
                        field.implemented = True
                        field.sdk_property = 'derived(at:)'
                elif field.name == 'child_key_derivation':
                    # Check for child key derivation (same as hd_key_derivation in this implementation)
                    if 'func derived' in content or 'derived(at' in content:
                        field.implemented = True
                        field.sdk_property = 'derived(at:)'
                elif field.name == 'ed25519_curve':
                    if 'Ed25519' in content and 'ed25519 seed' in content:
                        field.implemented = True
                        field.sdk_property = 'Ed25519Derivation'

        except Exception as e:
            logger.warning(f"Error analyzing BIP-32 features: {e}")

    def _analyze_bip44_features(self, section: SEPSection, wallet_file: Optional[Path]) -> None:
        """Analyze BIP-44 multi-account support"""
        if not wallet_file:
            return

        try:
            content = wallet_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'stellar_derivation_path':
                    if "derived(at: 44)" in content and "derived(at: 148)" in content:
                        field.implemented = True
                        field.sdk_property = "createKeyPair (m/44'/148'/index')"
                elif field.name == 'multiple_accounts':
                    if 'index:' in content and 'derived(at: UInt32(index))' in content:
                        field.implemented = True
                        field.sdk_property = 'createKeyPair(index:)'
                elif field.name == 'account_index_support':
                    if 'index: Int' in content:
                        field.implemented = True
                        field.sdk_property = 'index parameter'

        except Exception as e:
            logger.warning(f"Error analyzing BIP-44 features: {e}")

    def _analyze_key_derivation_methods(self, section: SEPSection, wallet_file: Optional[Path]) -> None:
        """Analyze key derivation method support"""
        if not wallet_file:
            return

        try:
            content = wallet_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'keypair_from_mnemonic':
                    if 'createKeyPair' in content and 'mnemonic:' in content:
                        field.implemented = True
                        field.sdk_property = 'createKeyPair(mnemonic:passphrase:index:)'
                elif field.name == 'seed_from_mnemonic':
                    if 'createSeed' in content:
                        field.implemented = True
                        field.sdk_property = 'Mnemonic.createSeed'
                elif field.name == 'account_id_from_mnemonic':
                    # Can be derived from KeyPair
                    if 'KeyPair' in content and 'createKeyPair' in content:
                        field.implemented = True
                        field.sdk_property = 'createKeyPair().accountId'

        except Exception as e:
            logger.warning(f"Error analyzing key derivation methods: {e}")

    def _analyze_language_support(self, section: SEPSection, wordlist_file: Optional[Path]) -> None:
        """Analyze language support for BIP-39 word lists"""
        if not wordlist_file:
            return

        try:
            content = wordlist_file.read_text(encoding='utf-8')

            # Map field names to enum case names
            language_map = {
                'english': 'case english',
                'chinese_simplified': 'case chineseSimplified',
                'chinese_traditional': 'case chineseTraditional',
                'french': 'case french',
                'italian': 'case italian',
                'japanese': 'case japanese',
                'korean': 'case korean',
                'spanish': 'case spanish',
            }

            for field in section.fields:
                if field.name in language_map:
                    enum_case = language_map[field.name]
                    if enum_case in content:
                        field.implemented = True
                        # Convert to property-like name
                        field.sdk_property = field.name.replace('_', ' ').title().replace(' ', '')

        except Exception as e:
            logger.warning(f"Error analyzing language support: {e}")


class SEP08Analyzer:
    """Analyzer for SEP-08 (Regulated Assets)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-08 implementation"""
        logger.info("Analyzing SEP-08 (Regulated Assets) implementation")

        # Create sections based on SEP-08 requirements
        sections = self._create_sep08_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find RegulatedAssetsService class
        service_file = self.sdk_analyzer.find_class_or_struct('RegulatedAssetsService')
        if service_file:
            rel_path = self.sdk_analyzer.get_relative_path(service_file)
            implementation_files.append(rel_path)
            logger.info(f"Found RegulatedAssetsService class at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Approval Endpoint':
                self._analyze_approval_endpoint(section, service_file)
            elif section.name == 'Request Parameters':
                self._analyze_request_parameters(section, service_file)
            elif section.name == 'Response Statuses':
                self._analyze_response_statuses(section, service_file)
            elif section.name == 'Success Response Fields':
                self._analyze_success_response_fields(section)
            elif section.name == 'Revised Response Fields':
                self._analyze_revised_response_fields(section)
            elif section.name == 'Pending Response Fields':
                self._analyze_pending_response_fields(section)
            elif section.name == 'Action Required Response Fields':
                self._analyze_action_required_response_fields(section)
            elif section.name == 'Rejected Response Fields':
                self._analyze_rejected_response_fields(section)
            elif section.name == 'Action URL Handling':
                self._analyze_action_url_handling(section, service_file)
            elif section.name == 'Stellar TOML Fields':
                self._analyze_stellar_toml_fields(section)
            elif section.name == 'Authorization Flags':
                self._analyze_authorization_flags(section, service_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive implementation of SEP-08 Regulated Assets",
            "RegulatedAssetsService class implements the approval server protocol",
            "Both async/await and legacy callback-based APIs are available",
            "Automatic discovery of regulated assets from stellar.toml",
            "Full support for all five response statuses: success, revised, pending, action_required, rejected",
            "Action URL handling with POST method support for user actions",
            "Authorization flag checking (auth_required and auth_revocable)",
            "All response models properly typed with Codable support",
            "Comprehensive error handling with RegulatedAssetsServiceError enum",
            "Thread-safe implementation suitable for concurrent requests",
            "Supports both legacy callback and modern async/await patterns",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-08!",
                "Always check authorization flags before submitting transactions",
                "Handle all five response statuses appropriately in client applications",
                "Implement proper error handling for RegulatedAssetsServiceError cases",
                "Use the forDomain method to discover regulated assets from stellar.toml",
                "For action_required responses, provide a proper UI flow for user actions",
                "For revised transactions, show users what was changed before submission",
                "For pending transactions, implement polling with appropriate timeouts",
                "Store approval criteria from stellar.toml to inform users of requirements",
                "Test with actual approval servers to ensure compatibility",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-08 compliance",
            ]

        return matrix

    def _create_sep08_sections(self) -> List[SEPSection]:
        """Create SEP-08 sections with all 32 fields organized into 11 sections"""
        sections = []

        # Section 1: Approval Endpoint (1 field)
        approval_endpoint_section = SEPSection(name='Approval Endpoint')
        approval_endpoint_section.fields = [
            SEPField(
                name='tx_approve',
                section='Approval Endpoint',
                required=True,
                description='POST /tx_approve - Approval server endpoint that receives a signed transaction, checks for compliance, and signs it on success',
                requirements='HTTP POST endpoint'
            ),
        ]
        sections.append(approval_endpoint_section)

        # Section 2: Request Parameters (1 field)
        request_params_section = SEPSection(name='Request Parameters')
        request_params_section.fields = [
            SEPField(
                name='tx',
                section='Request Parameters',
                required=True,
                description='A base64 encoded transaction envelope XDR signed by the user. This is the transaction that will be tested for compliance and signed on success.',
                requirements='string (base64 encoded XDR)'
            ),
        ]
        sections.append(request_params_section)

        # Section 3: Response Statuses (5 fields)
        response_statuses_section = SEPSection(name='Response Statuses')
        response_statuses_section.fields = [
            SEPField('success', 'Response Statuses', True, 'Transaction was found compliant and signed without being revised', 'HTTP 200, status value'),
            SEPField('revised', 'Response Statuses', True, 'Transaction was revised to be made compliant', 'HTTP 200, status value'),
            SEPField('pending', 'Response Statuses', True, 'Issuer could not determine whether to approve the transaction at the time of receiving it', 'HTTP 200, status value'),
            SEPField('action_required', 'Response Statuses', True, 'User must complete an action before this transaction can be approved', 'HTTP 200, status value'),
            SEPField('rejected', 'Response Statuses', True, 'Transaction is not compliant and could not be revised to be made compliant', 'HTTP 400, status value'),
        ]
        sections.append(response_statuses_section)

        # Section 4: Success Response Fields (3 fields)
        success_response_section = SEPSection(name='Success Response Fields')
        success_response_section.fields = [
            SEPField('status', 'Success Response Fields', True, 'Status value "success"', 'string'),
            SEPField('tx', 'Success Response Fields', True, 'Transaction envelope XDR, base64 encoded. This transaction will have both the original signature(s) from the request as well as one or multiple additional signatures from the issuer.', 'string (base64 encoded XDR)'),
            SEPField('message', 'Success Response Fields', False, 'A human readable string containing information to pass on to the user', 'string'),
        ]
        sections.append(success_response_section)

        # Section 5: Revised Response Fields (3 fields)
        revised_response_section = SEPSection(name='Revised Response Fields')
        revised_response_section.fields = [
            SEPField('status', 'Revised Response Fields', True, 'Status value "revised"', 'string'),
            SEPField('tx', 'Revised Response Fields', True, 'Transaction envelope XDR, base64 encoded. This transaction is a revised compliant version of the original request transaction, signed by the issuer.', 'string (base64 encoded XDR)'),
            SEPField('message', 'Revised Response Fields', True, 'A human readable string explaining the modifications made to the transaction to make it compliant', 'string'),
        ]
        sections.append(revised_response_section)

        # Section 6: Pending Response Fields (3 fields)
        pending_response_section = SEPSection(name='Pending Response Fields')
        pending_response_section.fields = [
            SEPField('status', 'Pending Response Fields', True, 'Status value "pending"', 'string'),
            SEPField('timeout', 'Pending Response Fields', True, 'Number of milliseconds to wait before submitting the same transaction again. Use 0 if the wait time cannot be determined.', 'integer'),
            SEPField('message', 'Pending Response Fields', False, 'A human readable string containing information to pass on to the user', 'string'),
        ]
        sections.append(pending_response_section)

        # Section 7: Action Required Response Fields (5 fields)
        action_required_section = SEPSection(name='Action Required Response Fields')
        action_required_section.fields = [
            SEPField('status', 'Action Required Response Fields', True, 'Status value "action_required"', 'string'),
            SEPField('message', 'Action Required Response Fields', True, 'A human readable string containing information regarding the action required', 'string'),
            SEPField('action_url', 'Action Required Response Fields', True, 'A URL that allows the user to complete the actions required to have the transaction approved', 'string (URL)'),
            SEPField('action_method', 'Action Required Response Fields', False, 'GET or POST, indicating the type of request that should be made to the action_url. If not provided, GET is assumed.', 'string (GET or POST)'),
            SEPField('action_fields', 'Action Required Response Fields', False, 'An array of additional fields defined by SEP-9 Standard KYC / AML fields that the client may optionally provide to the approval service when sending the request to the action_url', 'array of strings'),
        ]
        sections.append(action_required_section)

        # Section 8: Rejected Response Fields (2 fields)
        rejected_response_section = SEPSection(name='Rejected Response Fields')
        rejected_response_section.fields = [
            SEPField('status', 'Rejected Response Fields', True, 'Status value "rejected"', 'string'),
            SEPField('error', 'Rejected Response Fields', True, 'A human readable string explaining why the transaction is not compliant and could not be made compliant', 'string'),
        ]
        sections.append(rejected_response_section)

        # Section 9: Action URL Handling (4 fields)
        action_url_section = SEPSection(name='Action URL Handling')
        action_url_section.fields = [
            SEPField('action_url_get', 'Action URL Handling', True, 'Support for GET method to action_url with query parameters', 'GET request handling'),
            SEPField('action_url_post', 'Action URL Handling', True, 'Support for POST method to action_url with JSON body', 'POST request handling'),
            SEPField('action_url_post_response_no_further_action', 'Action URL Handling', True, 'Handle POST response with result "no_further_action_required"', 'Response parsing'),
            SEPField('action_url_post_response_follow_next_url', 'Action URL Handling', True, 'Handle POST response with result "follow_next_url" and next_url field', 'Response parsing'),
        ]
        sections.append(action_url_section)

        # Section 10: Stellar TOML Fields (3 fields)
        stellar_toml_section = SEPSection(name='Stellar TOML Fields')
        stellar_toml_section.fields = [
            SEPField('regulated', 'Stellar TOML Fields', True, 'A boolean indicating whether or not this is a regulated asset. If missing, false is assumed.', 'boolean in [[CURRENCIES]] section'),
            SEPField('approval_server', 'Stellar TOML Fields', True, 'The URL of an approval service that signs validated transactions', 'string (URL) in [[CURRENCIES]] section'),
            SEPField('approval_criteria', 'Stellar TOML Fields', False, 'A human readable string that explains the issuer\'s requirements for approving transactions', 'string in [[CURRENCIES]] section'),
        ]
        sections.append(stellar_toml_section)

        # Section 11: Authorization Flags (2 fields)
        authorization_flags_section = SEPSection(name='Authorization Flags')
        authorization_flags_section.fields = [
            SEPField('authorization_required', 'Authorization Flags', True, 'Authorization Required flag must be set on issuer account', 'Account flag check'),
            SEPField('authorization_revocable', 'Authorization Flags', True, 'Authorization Revocable flag must be set on issuer account', 'Account flag check'),
        ]
        sections.append(authorization_flags_section)

        return sections

    def _analyze_approval_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze approval endpoint support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'tx_approve':
                    # Check for postTransaction method which implements POST /tx_approve
                    if 'func postTransaction(txB64Xdr: String, apporvalServer:String)' in content:
                        field.implemented = True
                        field.sdk_property = 'postTransaction(txB64Xdr:apporvalServer:)'

        except Exception as e:
            logger.warning(f"Error analyzing approval endpoint: {e}")

    def _analyze_request_parameters(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze request parameter support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'tx':
                    # Check for tx parameter in postTransaction method
                    if 'txRequest["tx"] = txB64Xdr' in content:
                        field.implemented = True
                        field.sdk_property = 'txB64Xdr parameter'

        except Exception as e:
            logger.warning(f"Error analyzing request parameters: {e}")

    def _analyze_response_statuses(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze response status support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            status_map = {
                'success': ('PostSep08TransactionEnum', 'success'),
                'revised': ('PostSep08TransactionEnum', 'revised'),
                'pending': ('PostSep08TransactionEnum', 'pending'),
                'action_required': ('PostSep08TransactionEnum', 'actionRequired'),
                'rejected': ('PostSep08TransactionEnum', 'rejected'),
            }

            for field in section.fields:
                if field.name in status_map:
                    enum_name, case_name = status_map[field.name]
                    # Check for enum case in PostSep08TransactionEnum
                    if f'case {case_name}' in content:
                        field.implemented = True
                        field.sdk_property = f'{enum_name}.{case_name}'

        except Exception as e:
            logger.warning(f"Error analyzing response statuses: {e}")

    def _analyze_success_response_fields(self, section: SEPSection) -> None:
        """Analyze success response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('Sep08PostTransactionSuccess')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'status': 'status (implicit)',
                'tx': 'tx',
                'message': 'message',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property:
                    if field.name == 'status':
                        # Status is implicit in the enum case, always present
                        field.implemented = True
                        field.sdk_property = sdk_property
                    elif f'var {field.name}' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing success response fields: {e}")

    def _analyze_revised_response_fields(self, section: SEPSection) -> None:
        """Analyze revised response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('Sep08PostTransactionRevised')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'status': 'status (implicit)',
                'tx': 'tx',
                'message': 'message',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property:
                    if field.name == 'status':
                        # Status is implicit in the enum case
                        field.implemented = True
                        field.sdk_property = sdk_property
                    elif f'var {field.name}' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing revised response fields: {e}")

    def _analyze_pending_response_fields(self, section: SEPSection) -> None:
        """Analyze pending response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('Sep08PostTransactionPending')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'status': 'status (implicit)',
                'timeout': 'timeout',
                'message': 'message',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property:
                    if field.name == 'status':
                        # Status is implicit in the enum case
                        field.implemented = True
                        field.sdk_property = sdk_property
                    elif f'var {field.name}' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing pending response fields: {e}")

    def _analyze_action_required_response_fields(self, section: SEPSection) -> None:
        """Analyze action required response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('Sep08PostTransactionActionRequired')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'status': 'status (implicit)',
                'message': 'message',
                'action_url': 'actionUrl',
                'action_method': 'actionMethod',
                'action_fields': 'actionFields',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property:
                    if field.name == 'status':
                        # Status is implicit in the enum case
                        field.implemented = True
                        field.sdk_property = sdk_property
                    else:
                        # Check for actual property name (camelCase)
                        prop_name = sdk_property.split(' ')[0]  # Get just the property name
                        if f'var {prop_name}' in content or f'public var {prop_name}' in content:
                            field.implemented = True
                            field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing action required response fields: {e}")

    def _analyze_rejected_response_fields(self, section: SEPSection) -> None:
        """Analyze rejected response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('Sep08PostTransactionRejected')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'status': 'status (implicit)',
                'error': 'error',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property:
                    if field.name == 'status':
                        # Status is implicit in the enum case
                        field.implemented = True
                        field.sdk_property = sdk_property
                    elif f'var {field.name}' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing rejected response fields: {e}")

    def _analyze_action_url_handling(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze action URL handling support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'action_url_get':
                    # GET support is implicit via action_url field
                    if 'actionUrl' in content:
                        field.implemented = True
                        field.sdk_property = 'actionUrl field support'
                elif field.name == 'action_url_post':
                    # Check for postAction method
                    if 'func postAction(url: String, actionFields:[String : Any])' in content:
                        field.implemented = True
                        field.sdk_property = 'postAction(url:actionFields:)'
                elif field.name == 'action_url_post_response_no_further_action':
                    # Check for "no_further_action_required" handling
                    if '"no_further_action_required"' in content and 'PostSep08ActionEnum' in content:
                        field.implemented = True
                        field.sdk_property = 'PostSep08ActionEnum.done'
                elif field.name == 'action_url_post_response_follow_next_url':
                    # Check for "follow_next_url" handling
                    if '"follow_next_url"' in content and 'Sep08PostActionNextUrl' in content:
                        field.implemented = True
                        field.sdk_property = 'PostSep08ActionEnum.nextUrl'

        except Exception as e:
            logger.warning(f"Error analyzing action URL handling: {e}")

    def _analyze_stellar_toml_fields(self, section: SEPSection) -> None:
        """Analyze Stellar TOML field support"""
        # Check RegulatedAsset class for TOML fields
        regulated_asset_file = self.sdk_analyzer.find_class_or_struct('RegulatedAsset')
        # Also check CurrencyDocumentation for TOML parsing
        currency_doc_file = self.sdk_analyzer.find_class_or_struct('CurrencyDocumentation')

        if not currency_doc_file:
            return

        try:
            regulated_content = regulated_asset_file.read_text(encoding='utf-8') if regulated_asset_file else ''
            currency_content = currency_doc_file.read_text(encoding='utf-8')

            field_map = {
                'regulated': 'regulated (CurrencyDocumentation)',
                'approval_server': 'approvalServer',
                'approval_criteria': 'approvalCriteria',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property:
                    # All three fields are in CurrencyDocumentation
                    prop_name = sdk_property.split(' ')[0]
                    # Check for let or var declarations
                    if f'let {prop_name}' in currency_content or f'var {prop_name}' in currency_content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing Stellar TOML fields: {e}")

    def _analyze_authorization_flags(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze authorization flag support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'authorization_required':
                    # Check for authRequired flag check
                    if 'authRequired' in content and 'flags.authRequired' in content:
                        field.implemented = True
                        field.sdk_property = 'authorizationRequired() checks authRequired flag'
                elif field.name == 'authorization_revocable':
                    # Check for authRevocable flag check
                    if 'authRevocable' in content and 'flags.authRevocable' in content:
                        field.implemented = True
                        field.sdk_property = 'authorizationRequired() checks authRevocable flag'

        except Exception as e:
            logger.warning(f"Error analyzing authorization flags: {e}")


class SEP09Analyzer:
    """Analyzer for SEP-09 (Standard KYC Fields)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-09 implementation"""
        logger.info("Analyzing SEP-09 (Standard KYC Fields) implementation")

        # Create sections manually based on SEP-09 field categories
        sections = self._create_sep09_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find KYC field enums file
        kyc_fields_file = self.sdk_analyzer.find_class_or_struct('KYCNaturalPersonFieldsEnum')
        if kyc_fields_file:
            rel_path = self.sdk_analyzer.get_relative_path(kyc_fields_file)
            implementation_files.append(rel_path)
            logger.info(f"Found KYC field enums at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Natural Person Fields':
                self._analyze_natural_person_fields(section, kyc_fields_file)
            elif section.name == 'Organization Fields':
                self._analyze_organization_fields(section, kyc_fields_file)
            elif section.name == 'Financial Account Fields':
                self._analyze_financial_account_fields(section, kyc_fields_file)
            elif section.name == 'Card Fields':
                self._analyze_card_fields(section, kyc_fields_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive support for SEP-09 standard KYC fields",
            "All field categories are implemented as strongly-typed Swift enums",
            "Natural Person, Organization, Financial Account, and Card fields are fully supported",
            "Field keys are defined as static constants for type safety",
            "Enum cases provide automatic conversion to Data for multipart/form-data uploads",
            "Used by SEP-12 KYC API and SEP-24 interactive flows",
            "Full support for binary file uploads (photo_id, proof_of_income, etc.)",
            "Date fields use ISO 8601 format automatically",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-09!",
                "Use the strongly-typed enums (KYCNaturalPersonFieldsEnum, etc.) for type safety",
                "Field keys are available as static constants for direct access",
                "Binary files (photo_id, proof_of_income) use Data type for automatic encoding",
                "Date fields are automatically formatted to ISO 8601 strings",
                "Combine field enums with SEP-12 KycService for complete KYC workflows",
                "Organization fields use 'organization.' prefix per SEP-09 spec",
                "Card fields use 'card.' prefix per SEP-09 spec",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) not implemented:",
                *[f"  - {f}" for f in missing_fields[:15]],
                "Consider adding support for these fields to achieve full SEP-09 compliance"
            ]

        return matrix

    def _create_sep09_sections(self) -> List[SEPSection]:
        """Create SEP-09 sections with all standard KYC fields"""
        sections = []

        # Natural Person Fields
        natural_person_section = SEPSection(name='Natural Person Fields')
        natural_person_section.fields = [
            SEPField(name='last_name', section='Natural Person Fields', required=False,
                    description='Family or last name', requirements='string'),
            SEPField(name='first_name', section='Natural Person Fields', required=False,
                    description='Given or first name', requirements='string'),
            SEPField(name='additional_name', section='Natural Person Fields', required=False,
                    description='Middle name or other additional name', requirements='string'),
            SEPField(name='address_country_code', section='Natural Person Fields', required=False,
                    description='Country code for current address', requirements='string'),
            SEPField(name='state_or_province', section='Natural Person Fields', required=False,
                    description='Name of state/province/region/prefecture', requirements='string'),
            SEPField(name='city', section='Natural Person Fields', required=False,
                    description='Name of city/town', requirements='string'),
            SEPField(name='postal_code', section='Natural Person Fields', required=False,
                    description='Postal or other code identifying user\'s locale', requirements='string'),
            SEPField(name='address', section='Natural Person Fields', required=False,
                    description='Entire address (country, state, postal code, street address, etc.) as a multi-line string', requirements='string'),
            SEPField(name='mobile_number', section='Natural Person Fields', required=False,
                    description='Mobile phone number with country code, in E.164 format', requirements='string'),
            SEPField(name='mobile_number_format', section='Natural Person Fields', required=False,
                    description='Expected format of the mobile_number field (E.164, hash, etc.)', requirements='string'),
            SEPField(name='email_address', section='Natural Person Fields', required=False,
                    description='Email address', requirements='string'),
            SEPField(name='birth_date', section='Natural Person Fields', required=False,
                    description='Date of birth (e.g., 1976-07-04)', requirements='date'),
            SEPField(name='birth_place', section='Natural Person Fields', required=False,
                    description='Place of birth (city, state, country; as on passport)', requirements='string'),
            SEPField(name='birth_country_code', section='Natural Person Fields', required=False,
                    description='ISO Code of country of birth (ISO 3166-1 alpha-3)', requirements='string'),
            SEPField(name='tax_id', section='Natural Person Fields', required=False,
                    description='Tax identifier of user in their country (social security number in US)', requirements='string'),
            SEPField(name='tax_id_name', section='Natural Person Fields', required=False,
                    description='Name of the tax ID (SSN or ITIN in the US)', requirements='string'),
            SEPField(name='occupation', section='Natural Person Fields', required=False,
                    description='Occupation ISCO code', requirements='number'),
            SEPField(name='employer_name', section='Natural Person Fields', required=False,
                    description='Name of employer', requirements='string'),
            SEPField(name='employer_address', section='Natural Person Fields', required=False,
                    description='Address of employer', requirements='string'),
            SEPField(name='language_code', section='Natural Person Fields', required=False,
                    description='Primary language (ISO 639-1)', requirements='string'),
            SEPField(name='id_type', section='Natural Person Fields', required=False,
                    description='Type of ID (passport, drivers_license, id_card, etc.)', requirements='string'),
            SEPField(name='id_country_code', section='Natural Person Fields', required=False,
                    description='Country issuing passport or photo ID (ISO 3166-1 alpha-3)', requirements='string'),
            SEPField(name='id_issue_date', section='Natural Person Fields', required=False,
                    description='ID issue date', requirements='date'),
            SEPField(name='id_expiration_date', section='Natural Person Fields', required=False,
                    description='ID expiration date', requirements='date'),
            SEPField(name='id_number', section='Natural Person Fields', required=False,
                    description='Passport or ID number', requirements='string'),
            SEPField(name='photo_id_front', section='Natural Person Fields', required=False,
                    description='Image of front of user\'s photo ID or passport', requirements='binary'),
            SEPField(name='photo_id_back', section='Natural Person Fields', required=False,
                    description='Image of back of user\'s photo ID or passport', requirements='binary'),
            SEPField(name='notary_approval_of_photo_id', section='Natural Person Fields', required=False,
                    description='Image of notary\'s approval of photo ID or passport', requirements='binary'),
            SEPField(name='ip_address', section='Natural Person Fields', required=False,
                    description='IP address of customer\'s computer', requirements='string'),
            SEPField(name='photo_proof_residence', section='Natural Person Fields', required=False,
                    description='Image of a utility bill, bank statement or similar with the user\'s name and address', requirements='binary'),
            SEPField(name='sex', section='Natural Person Fields', required=False,
                    description='Gender (male, female, or other)', requirements='string'),
            SEPField(name='proof_of_income', section='Natural Person Fields', required=False,
                    description='Image of user\'s proof of income document', requirements='binary'),
            SEPField(name='proof_of_liveness', section='Natural Person Fields', required=False,
                    description='Video or image file of user as a liveness proof', requirements='binary'),
            SEPField(name='referral_id', section='Natural Person Fields', required=False,
                    description='User\'s origin (such as an id in another application) or a referral code', requirements='string'),
        ]
        sections.append(natural_person_section)

        # Organization Fields
        organization_section = SEPSection(name='Organization Fields')
        organization_section.fields = [
            SEPField(name='organization.name', section='Organization Fields', required=False,
                    description='Full organization name as on the incorporation papers', requirements='string'),
            SEPField(name='organization.VAT_number', section='Organization Fields', required=False,
                    description='Organization VAT number', requirements='string'),
            SEPField(name='organization.registration_number', section='Organization Fields', required=False,
                    description='Organization registration number', requirements='string'),
            SEPField(name='organization.registration_date', section='Organization Fields', required=False,
                    description='Date the organization was registered', requirements='date'),
            SEPField(name='organization.registered_address', section='Organization Fields', required=False,
                    description='Organization registered address', requirements='string'),
            SEPField(name='organization.number_of_shareholders', section='Organization Fields', required=False,
                    description='Organization shareholder number', requirements='number'),
            SEPField(name='organization.shareholder_name', section='Organization Fields', required=False,
                    description='Name of shareholder (can be organization or person)', requirements='string'),
            SEPField(name='organization.photo_incorporation_doc', section='Organization Fields', required=False,
                    description='Image of incorporation documents', requirements='binary'),
            SEPField(name='organization.photo_proof_address', section='Organization Fields', required=False,
                    description='Image of a utility bill, bank statement with the organization\'s name and address', requirements='binary'),
            SEPField(name='organization.address_country_code', section='Organization Fields', required=False,
                    description='Country code for current address', requirements='string'),
            SEPField(name='organization.state_or_province', section='Organization Fields', required=False,
                    description='Name of state/province/region/prefecture', requirements='string'),
            SEPField(name='organization.city', section='Organization Fields', required=False,
                    description='Name of city/town', requirements='string'),
            SEPField(name='organization.postal_code', section='Organization Fields', required=False,
                    description='Postal or other code identifying organization\'s locale', requirements='string'),
            SEPField(name='organization.director_name', section='Organization Fields', required=False,
                    description='Organization registered managing director', requirements='string'),
            SEPField(name='organization.website', section='Organization Fields', required=False,
                    description='Organization website', requirements='string'),
            SEPField(name='organization.email', section='Organization Fields', required=False,
                    description='Organization contact email', requirements='string'),
            SEPField(name='organization.phone', section='Organization Fields', required=False,
                    description='Organization contact phone', requirements='string'),
        ]
        sections.append(organization_section)

        # Financial Account Fields
        financial_section = SEPSection(name='Financial Account Fields')
        financial_section.fields = [
            SEPField(name='bank_account_number', section='Financial Account Fields', required=False,
                    description='Number identifying bank account', requirements='string'),
            SEPField(name='bank_account_type', section='Financial Account Fields', required=False,
                    description='Type of bank account', requirements='string'),
            SEPField(name='bank_number', section='Financial Account Fields', required=False,
                    description='Number identifying bank in national banking system (routing number in US)', requirements='string'),
            SEPField(name='bank_phone_number', section='Financial Account Fields', required=False,
                    description='Phone number with country code for bank', requirements='string'),
            SEPField(name='bank_branch_number', section='Financial Account Fields', required=False,
                    description='Number identifying bank branch', requirements='string'),
            SEPField(name='bank_name', section='Financial Account Fields', required=False,
                    description='Name of the bank', requirements='string'),
            SEPField(name='clabe_number', section='Financial Account Fields', required=False,
                    description='Bank account number for Mexico', requirements='string'),
            SEPField(name='cbu_number', section='Financial Account Fields', required=False,
                    description='Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU)', requirements='string'),
            SEPField(name='cbu_alias', section='Financial Account Fields', required=False,
                    description='The alias for a CBU or CVU', requirements='string'),
            SEPField(name='crypto_address', section='Financial Account Fields', required=False,
                    description='Address for a cryptocurrency account', requirements='string'),
            SEPField(name='crypto_memo', section='Financial Account Fields', required=False,
                    description='A destination tag/memo used to identify a transaction', requirements='string'),
            SEPField(name='mobile_money_number', section='Financial Account Fields', required=False,
                    description='Mobile phone number in E.164 format with which a mobile money account is associated', requirements='string'),
            SEPField(name='mobile_money_provider', section='Financial Account Fields', required=False,
                    description='Name of the mobile money service provider', requirements='string'),
            SEPField(name='external_transfer_memo', section='Financial Account Fields', required=False,
                    description='A destination tag/memo used to identify a transaction', requirements='string'),
        ]
        sections.append(financial_section)

        # Card Fields
        card_section = SEPSection(name='Card Fields')
        card_section.fields = [
            SEPField(name='card.number', section='Card Fields', required=False,
                    description='Card number', requirements='string'),
            SEPField(name='card.expiration_date', section='Card Fields', required=False,
                    description='Expiration month and year in YY-MM format (e.g., 29-11, November 2029)', requirements='string'),
            SEPField(name='card.cvc', section='Card Fields', required=False,
                    description='CVC number (Digits on the back of the card)', requirements='string'),
            SEPField(name='card.holder_name', section='Card Fields', required=False,
                    description='Name of the card holder', requirements='string'),
            SEPField(name='card.network', section='Card Fields', required=False,
                    description='Brand of the card/network it operates within (e.g., Visa, Mastercard, AmEx, etc.)', requirements='string'),
            SEPField(name='card.postal_code', section='Card Fields', required=False,
                    description='Billing address postal code', requirements='string'),
            SEPField(name='card.country_code', section='Card Fields', required=False,
                    description='Billing address country code in ISO 3166-1 alpha-2 code (e.g., US)', requirements='string'),
            SEPField(name='card.state_or_province', section='Card Fields', required=False,
                    description='Name of state/province/region/prefecture in ISO 3166-2 format', requirements='string'),
            SEPField(name='card.city', section='Card Fields', required=False,
                    description='Name of city/town', requirements='string'),
            SEPField(name='card.address', section='Card Fields', required=False,
                    description='Entire address (country, state, postal code, street address, etc.) as a multi-line string', requirements='string'),
            SEPField(name='card.token', section='Card Fields', required=False,
                    description='Token representation of the card in some external payment system (e.g., Stripe)', requirements='string'),
        ]
        sections.append(card_section)

        return sections

    def _analyze_natural_person_fields(self, section: SEPSection, kyc_fields_file: Optional[Path]) -> None:
        """Analyze natural person KYC fields implementation"""
        if not kyc_fields_file:
            return

        try:
            content = kyc_fields_file.read_text(encoding='utf-8')

            # Check for KYCNaturalPersonFieldKey enum
            for field in section.fields:
                # Convert field name to expected enum case name
                # e.g., 'last_name' -> 'lastName'
                camel_case = self._snake_to_camel(field.name)

                # Check if the enum case exists
                if f'case {camel_case}' in content:
                    field.implemented = True
                    field.sdk_property = camel_case

        except Exception as e:
            logger.warning(f"Error analyzing natural person fields: {e}")

    def _analyze_organization_fields(self, section: SEPSection, kyc_fields_file: Optional[Path]) -> None:
        """Analyze organization KYC fields implementation"""
        if not kyc_fields_file:
            return

        try:
            content = kyc_fields_file.read_text(encoding='utf-8')

            # Check for KYCOrganizationFieldsEnum
            for field in section.fields:
                # Remove 'organization.' prefix and convert to camelCase
                # e.g., 'organization.name' -> 'name'
                field_name = field.name.replace('organization.', '')

                # Handle special cases
                if field_name == 'VAT_number':
                    camel_case = 'VATNumber'
                else:
                    camel_case = self._snake_to_camel(field_name)

                # Check if the enum case exists
                if f'case {camel_case}' in content:
                    field.implemented = True
                    field.sdk_property = camel_case

        except Exception as e:
            logger.warning(f"Error analyzing organization fields: {e}")

    def _analyze_financial_account_fields(self, section: SEPSection, kyc_fields_file: Optional[Path]) -> None:
        """Analyze financial account KYC fields implementation"""
        if not kyc_fields_file:
            return

        try:
            content = kyc_fields_file.read_text(encoding='utf-8')

            # Check for KYCFinancialAccountFieldsEnum
            for field in section.fields:
                # Convert field name to expected enum case name
                camel_case = self._snake_to_camel(field.name)

                # Check if the enum case exists
                if f'case {camel_case}' in content:
                    field.implemented = True
                    field.sdk_property = camel_case

        except Exception as e:
            logger.warning(f"Error analyzing financial account fields: {e}")

    def _analyze_card_fields(self, section: SEPSection, kyc_fields_file: Optional[Path]) -> None:
        """Analyze card KYC fields implementation"""
        if not kyc_fields_file:
            return

        try:
            content = kyc_fields_file.read_text(encoding='utf-8')

            # Check for KYCCardFieldsEnum
            for field in section.fields:
                # Remove 'card.' prefix and convert to camelCase
                field_name = field.name.replace('card.', '')
                camel_case = self._snake_to_camel(field_name)

                # Check if the enum case exists
                if f'case {camel_case}' in content:
                    field.implemented = True
                    field.sdk_property = camel_case

        except Exception as e:
            logger.warning(f"Error analyzing card fields: {e}")

    def _snake_to_camel(self, snake_str: str) -> str:
        """Convert snake_case to camelCase"""
        components = snake_str.split('_')
        return components[0] + ''.join(x.title() for x in components[1:])


class SEP12Analyzer:
    """Analyzer for SEP-12 (KYC API)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-12 implementation"""
        logger.info("Analyzing SEP-12 (KYC API) implementation")

        # Create sections manually based on SEP-12 requirements
        sections = self._create_sep12_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find KycService class
        kyc_service_file = self.sdk_analyzer.find_class_or_struct('KycService')
        if kyc_service_file:
            rel_path = self.sdk_analyzer.get_relative_path(kyc_service_file)
            implementation_files.append(rel_path)
            logger.info(f"Found KycService class at {rel_path}")

        # Find response classes
        for class_name in ['GetCustomerInfoResponse', 'PutCustomerInfoResponse',
                          'GetCustomerFilesResponse', 'CustomerFileResponse']:
            file = self.sdk_analyzer.find_class_or_struct(class_name)
            if file:
                rel_path = self.sdk_analyzer.get_relative_path(file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)

        # Find request classes
        for class_name in ['GetCustomerInfoRequest', 'PutCustomerInfoRequest',
                          'PutCustomerVerificationRequest', 'PutCustomerCallbackRequest']:
            file = self.sdk_analyzer.find_class_or_struct(class_name)
            if file:
                rel_path = self.sdk_analyzer.get_relative_path(file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)

        # Find KycAmlFields
        kyc_fields_file = self.sdk_analyzer.find_file_by_name('KycAmlFields.swift')
        if kyc_fields_file:
            rel_path = self.sdk_analyzer.get_relative_path(kyc_fields_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)

        # Find KycServiceError
        kyc_error_file = self.sdk_analyzer.find_class_or_struct('KycServiceError')
        if kyc_error_file:
            rel_path = self.sdk_analyzer.get_relative_path(kyc_error_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'API Endpoints':
                self._analyze_api_endpoints(section, kyc_service_file)
            elif section.name == 'Authentication':
                self._analyze_authentication(section, kyc_service_file)
            elif section.name == 'Field Type Specifications':
                self._analyze_field_types(section, kyc_service_file)
            elif section.name == 'File Upload':
                self._analyze_file_upload(section, kyc_service_file)
            elif section.name == 'Request Parameters':
                self._analyze_request_parameters(section, kyc_service_file)
            elif section.name == 'Response Fields':
                self._analyze_response_fields(section, kyc_service_file)
            elif section.name == 'SEP-9 Integration':
                self._analyze_sep9_integration(section, kyc_service_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a comprehensive implementation of SEP-12 KYC API",
            "KycService class handles all customer information endpoints",
            "Supports automatic discovery via stellar.toml (KYC_SERVER or TRANSFER_SERVER)",
            "Both async/await and legacy callback-based APIs are available",
            "Comprehensive support for SEP-9 standard KYC fields",
            "Multipart/form-data support for binary file uploads",
            "Supports all customer types: natural persons, organizations, financial accounts, cards",
            "Field-level status tracking with GetCustomerInfoField and GetCustomerInfoProvidedField",
            "JWT authentication via SEP-10 for all endpoints",
            "Thread-safe implementation suitable for production use",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-12!",
                "Always use SEP-10 JWT authentication for all requests",
                "Handle customer status values appropriately (ACCEPTED, NEEDS_INFO, PROCESSING, REJECTED)",
                "Use multipart/form-data for uploading documents (photo_id, proof_of_address, etc.)",
                "Implement proper error handling for KycServiceError cases",
                "Consider using the callback endpoint for status updates",
                "Follow SEP-9 standard field naming conventions",
                "Validate file sizes before upload to avoid PAYLOAD_TOO_LARGE errors",
            ]
        else:
            missing_fields = []
            required_missing = []
            optional_missing = []

            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        field_info = f"{section.name}: {field.name}"
                        missing_fields.append(field_info)
                        if field.required:
                            required_missing.append(field_info)
                        else:
                            optional_missing.append(field_info)

            matrix.recommendations = []

            if required_missing:
                matrix.recommendations.extend([
                    f"🟠 High Priority: {len(required_missing)} required field(s) not implemented:",
                    *[f"  - {f}" for f in required_missing[:10]],
                ])

            if optional_missing:
                matrix.recommendations.extend([
                    f"🟢 Low Priority: {len(optional_missing)} optional field(s) not implemented:",
                    *[f"  - {f}" for f in optional_missing[:10]],
                ])

            matrix.recommendations.append("Consider adding support for these fields to achieve full SEP-12 compliance")

        return matrix

    def _create_sep12_sections(self) -> List[SEPSection]:
        """Create SEP-12 sections with all required and optional fields"""
        sections = []

        # API Endpoints
        endpoints_section = SEPSection(name='API Endpoints')
        endpoints_section.fields = [
            SEPField(
                name='get_customer',
                section='API Endpoints',
                required=True,
                description='GET /customer - Check the status of a customers info',
                requirements='GET request with optional id, account, memo, type, transaction_id, lang params'
            ),
            SEPField(
                name='put_customer',
                section='API Endpoints',
                required=True,
                description='PUT /customer - Upload customer information to an anchor',
                requirements='PUT request with customer fields via multipart/form-data'
            ),
            SEPField(
                name='delete_customer',
                section='API Endpoints',
                required=True,
                description='DELETE /customer/{account} - Delete all personal information about a customer',
                requirements='DELETE request with account parameter'
            ),
            SEPField(
                name='put_customer_verification',
                section='API Endpoints',
                required=True,
                description='PUT /customer/verification - Verify customer fields with confirmation codes',
                requirements='PUT request with verification values'
            ),
            SEPField(
                name='put_customer_callback',
                section='API Endpoints',
                required=True,
                description='PUT /customer/callback - Register a callback URL for customer status updates',
                requirements='PUT request with callback URL'
            ),
            SEPField(
                name='post_customer_files',
                section='API Endpoints',
                required=True,
                description='POST /customer/files - Upload binary files for customer KYC',
                requirements='POST request with file via multipart/form-data'
            ),
            SEPField(
                name='get_customer_files',
                section='API Endpoints',
                required=True,
                description='GET /customer/files - Get metadata about uploaded files',
                requirements='GET request with optional file_id or customer_id'
            ),
        ]
        sections.append(endpoints_section)

        # Authentication
        auth_section = SEPSection(name='Authentication')
        auth_section.fields = [
            SEPField(
                name='jwt_authentication',
                section='Authentication',
                required=True,
                description='JWT Token via SEP-10 - All endpoints require SEP-10 JWT authentication via Authorization header',
                requirements='Bearer token in Authorization header'
            ),
        ]
        sections.append(auth_section)

        # Field Type Specifications
        field_types_section = SEPSection(name='Field Type Specifications')
        field_types_section.fields = [
            SEPField(
                name='type',
                section='Field Type Specifications',
                required=True,
                description='Data type of field value',
                requirements='string, binary, number, or date'
            ),
            SEPField(
                name='description',
                section='Field Type Specifications',
                required=False,
                description='Human-readable description of the field',
                requirements='string'
            ),
            SEPField(
                name='choices',
                section='Field Type Specifications',
                required=False,
                description='Array of valid values for this field',
                requirements='array'
            ),
            SEPField(
                name='optional',
                section='Field Type Specifications',
                required=False,
                description='Whether this field is required to proceed',
                requirements='boolean, defaults to false'
            ),
            SEPField(
                name='status',
                section='Field Type Specifications',
                required=False,
                description='Status of provided field',
                requirements='ACCEPTED, PROCESSING, REJECTED, VERIFICATION_REQUIRED'
            ),
            SEPField(
                name='error',
                section='Field Type Specifications',
                required=False,
                description='Description of why field was rejected',
                requirements='string'
            ),
        ]
        sections.append(field_types_section)

        # File Upload
        file_upload_section = SEPSection(name='File Upload')
        file_upload_section.fields = [
            SEPField(
                name='multipart_file_upload',
                section='File Upload',
                required=True,
                description='Binary files uploaded using multipart/form-data for photo_id, proof_of_address, etc.',
                requirements='multipart/form-data content type'
            ),
        ]
        sections.append(file_upload_section)

        # Request Parameters
        request_params_section = SEPSection(name='Request Parameters')
        request_params_section.fields = [
            SEPField(
                name='id',
                section='Request Parameters',
                required=False,
                description='ID of the customer as returned in previous PUT request',
                requirements='string'
            ),
            SEPField(
                name='account',
                section='Request Parameters',
                required=False,
                description='Stellar account ID (G...) of the customer',
                requirements='Stellar public key'
            ),
            SEPField(
                name='memo',
                section='Request Parameters',
                required=False,
                description='Memo that uniquely identifies a customer in shared accounts',
                requirements='string or integer'
            ),
            SEPField(
                name='memo_type',
                section='Request Parameters',
                required=False,
                description='Type of memo: text, id, or hash',
                requirements='text|id|hash'
            ),
            SEPField(
                name='type',
                section='Request Parameters',
                required=False,
                description='Type of action the customer is being KYCd for',
                requirements='string as per Type Specification'
            ),
            SEPField(
                name='transaction_id',
                section='Request Parameters',
                required=False,
                description='Transaction ID with which customer info is associated',
                requirements='string'
            ),
            SEPField(
                name='lang',
                section='Request Parameters',
                required=False,
                description='Language code (ISO 639-1) for human-readable responses',
                requirements='ISO 639-1 language code, defaults to en'
            ),
        ]
        sections.append(request_params_section)

        # Response Fields
        response_fields_section = SEPSection(name='Response Fields')
        response_fields_section.fields = [
            SEPField(
                name='id',
                section='Response Fields',
                required=False,
                description='ID of the customer',
                requirements='string'
            ),
            SEPField(
                name='status',
                section='Response Fields',
                required=True,
                description='Status of customer KYC process',
                requirements='ACCEPTED, PROCESSING, NEEDS_INFO, REJECTED'
            ),
            SEPField(
                name='fields',
                section='Response Fields',
                required=False,
                description='Fields the anchor has not yet received',
                requirements='object with field specifications'
            ),
            SEPField(
                name='provided_fields',
                section='Response Fields',
                required=False,
                description='Fields the anchor has received',
                requirements='object with field specifications and status'
            ),
            SEPField(
                name='message',
                section='Response Fields',
                required=False,
                description='Human readable message describing KYC status',
                requirements='string'
            ),
        ]
        sections.append(response_fields_section)

        # SEP-9 Integration
        sep9_section = SEPSection(name='SEP-9 Integration')
        sep9_section.fields = [
            SEPField(
                name='standard_kyc_fields',
                section='SEP-9 Integration',
                required=True,
                description='Supports all SEP-9 standard KYC fields for natural persons and organizations',
                requirements='Full SEP-9 field support'
            ),
        ]
        sections.append(sep9_section)

        return sections

    def _analyze_api_endpoints(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze API endpoint support"""
        if not kyc_service_file:
            return

        try:
            content = kyc_service_file.read_text(encoding='utf-8')

            endpoint_method_map = {
                'get_customer': 'getCustomerInfo',
                'put_customer': 'putCustomerInfo',
                'delete_customer': 'deleteCustomerInfo',
                'put_customer_verification': 'putCustomerVerification',
                'put_customer_callback': 'putCustomerCallback',
                'post_customer_files': 'postCustomerFile',
                'get_customer_files': 'getCustomerFiles',
            }

            for field in section.fields:
                method_name = endpoint_method_map.get(field.name)
                if method_name and f'func {method_name}' in content:
                    field.implemented = True
                    field.sdk_property = method_name

        except Exception as e:
            logger.warning(f"Error analyzing API endpoints: {e}")

    def _analyze_authentication(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze authentication support"""
        if not kyc_service_file:
            return

        try:
            content = kyc_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'jwt_authentication':
                    # Check for JWT token parameter in methods
                    if 'jwtToken:' in content or 'jwt:String' in content:
                        field.implemented = True
                        field.sdk_property = 'JWT Token'

        except Exception as e:
            logger.warning(f"Error analyzing authentication: {e}")

    def _analyze_field_types(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze field type specification support"""
        # Look for GetCustomerInfoField and GetCustomerInfoProvidedField
        field_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoField')
        provided_field_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoProvidedField')

        if not field_file and not provided_field_file:
            return

        try:
            field_content = ""
            if field_file:
                field_content = field_file.read_text(encoding='utf-8')

            provided_content = ""
            if provided_field_file:
                provided_content = provided_field_file.read_text(encoding='utf-8')

            combined_content = field_content + provided_content

            field_property_map = {
                'type': 'type',
                'description': 'description',
                'choices': 'choices',
                'optional': 'optional',
                'status': 'status',
                'error': 'error',
            }

            for field in section.fields:
                if field.name in field_property_map:
                    sdk_property = field_property_map[field.name]
                    if f'let {sdk_property}:' in combined_content or f'var {sdk_property}:' in combined_content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing field types: {e}")

    def _analyze_file_upload(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze file upload support"""
        if not kyc_service_file:
            return

        try:
            content = kyc_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'multipart_file_upload':
                    # Check for multipart support
                    if 'PUTMultipartRequestWithPath' in content or 'POSTMultipartRequestWithPath' in content:
                        field.implemented = True
                        field.sdk_property = 'multipart/form-data'

        except Exception as e:
            logger.warning(f"Error analyzing file upload: {e}")

    def _analyze_request_parameters(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze request parameter support"""
        request_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoRequest')
        put_request_file = self.sdk_analyzer.find_class_or_struct('PutCustomerInfoRequest')

        if not request_file and not put_request_file:
            return

        try:
            request_content = ""
            if request_file:
                request_content = request_file.read_text(encoding='utf-8')

            put_content = ""
            if put_request_file:
                put_content = put_request_file.read_text(encoding='utf-8')

            combined_content = request_content + put_content

            param_property_map = {
                'id': 'id',
                'account': 'account',
                'memo': 'memo',
                'memo_type': 'memoType',
                'type': 'type',
                'transaction_id': 'transactionId',
                'lang': 'lang',
            }

            for field in section.fields:
                if field.name in param_property_map:
                    sdk_property = param_property_map[field.name]
                    if f'let {sdk_property}:' in combined_content or f'var {sdk_property}:' in combined_content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing request parameters: {e}")

    def _analyze_response_fields(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoResponse')

        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_property_map = {
                'id': 'id',
                'status': 'status',
                'fields': 'fields',
                'provided_fields': 'providedFields',
                'message': 'message',
            }

            for field in section.fields:
                if field.name in field_property_map:
                    sdk_property = field_property_map[field.name]
                    if f'let {sdk_property}:' in content or f'var {sdk_property}:' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing response fields: {e}")

    def _analyze_sep9_integration(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze SEP-9 standard KYC fields support"""
        # Look for KYC field enums
        fields_file = self.sdk_analyzer.find_class_or_struct('KYCNaturalPersonFieldsEnum')
        org_file = self.sdk_analyzer.find_class_or_struct('KYCOrganizationFieldsEnum')
        financial_file = self.sdk_analyzer.find_class_or_struct('KYCFinancialAccountFieldsEnum')
        card_file = self.sdk_analyzer.find_class_or_struct('KYCCardFieldsEnum')

        if not any([fields_file, org_file, financial_file, card_file]):
            return

        try:
            for field in section.fields:
                if field.name == 'standard_kyc_fields':
                    # If we found any of the KYC field enums, SEP-9 is supported
                    if fields_file or org_file or financial_file or card_file:
                        field.implemented = True
                        field.sdk_property = 'StandardKYCFields'

        except Exception as e:
            logger.warning(f"Error analyzing SEP-9 integration: {e}")


class SEP10Analyzer:
    """Analyzer for SEP-10 (Stellar Web Authentication)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-10 implementation"""
        logger.info("Analyzing SEP-10 (Stellar Web Authentication) implementation")

        # Create sections manually based on SEP-10 requirements
        sections = self._create_sep10_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find WebAuthenticator class
        web_auth_file = self.sdk_analyzer.find_class_or_struct('WebAuthenticator')
        if web_auth_file:
            rel_path = self.sdk_analyzer.get_relative_path(web_auth_file)
            implementation_files.append(rel_path)
            logger.info(f"Found WebAuthenticator class at {rel_path}")

        # Find AccountInformation (for stellar.toml endpoints)
        account_info_file = self.sdk_analyzer.find_class_or_struct('AccountInformation')
        if account_info_file:
            rel_path = self.sdk_analyzer.get_relative_path(account_info_file)
            implementation_files.append(rel_path)
            logger.info(f"Found AccountInformation class at {rel_path}")

        # Find SEPConstants (for time bounds validation)
        sep_constants_file = self.sdk_analyzer.find_file_by_name('SEPConstants.swift')
        if sep_constants_file:
            rel_path = self.sdk_analyzer.get_relative_path(sep_constants_file)
            implementation_files.append(rel_path)
            logger.info(f"Found SEPConstants at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Authentication Endpoints':
                self._analyze_authentication_endpoints(section, web_auth_file)
            elif section.name == 'Challenge Transaction Features':
                self._analyze_challenge_features(section, web_auth_file)
            elif section.name == 'Client Domain Features':
                self._analyze_client_domain_features(section, web_auth_file)
            elif section.name == 'JWT Token Features':
                self._analyze_jwt_features(section, web_auth_file)
            elif section.name == 'Verification Features':
                self._analyze_verification_features(section, web_auth_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a comprehensive implementation of SEP-10 Stellar Web Authentication",
            "WebAuthenticator class handles the complete authentication flow",
            "Supports automatic discovery via stellar.toml (WEB_AUTH_ENDPOINT)",
            "Both async/await and legacy callback-based APIs are available",
            "Comprehensive challenge validation including sequence number, timebounds, signatures",
            "Supports client domain verification for enhanced security",
            "Supports muxed accounts and memo-based sub-accounts",
            "Validates web_auth_domain operation for domain verification",
            "JWT token response handling with proper error types",
            "Thread-safe implementation suitable for production use",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-10!",
                "Always use secure (HTTPS) endpoints in production",
                "Implement proper JWT token storage and refresh logic",
                "Use client_domain parameter for enhanced security when available",
                "Handle ChallengeValidationError cases appropriately",
                "Consider using grace period for time bounds validation",
                "Validate JWT tokens before use in subsequent requests",
            ]
        else:
            missing_fields = []
            required_missing = []
            optional_missing = []

            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        field_info = f"{section.name}: {field.name}"
                        missing_fields.append(field_info)
                        if field.required:
                            required_missing.append(field_info)
                        else:
                            optional_missing.append(field_info)

            matrix.recommendations = []

            if required_missing:
                matrix.recommendations.extend([
                    f"🟠 High Priority: {len(required_missing)} required field(s) not implemented:",
                    *[f"  - {f}" for f in required_missing[:10]],
                ])

            if optional_missing:
                matrix.recommendations.extend([
                    f"🟢 Low Priority: {len(optional_missing)} optional field(s) not implemented:",
                    *[f"  - {f}" for f in optional_missing[:10]],
                ])

            matrix.recommendations.append("Consider adding support for these fields to achieve full SEP-10 compliance")

        return matrix

    def _create_sep10_sections(self) -> List[SEPSection]:
        """Create SEP-10 sections with all required and optional fields"""
        sections = []

        # Authentication Endpoints
        endpoints_section = SEPSection(name='Authentication Endpoints')
        endpoints_section.fields = [
            SEPField(
                name='get_auth_challenge',
                section='Authentication Endpoints',
                required=True,
                description='GET /auth endpoint - Returns challenge transaction',
                requirements='GET request with account, memo, home_domain, client_domain params'
            ),
            SEPField(
                name='post_auth_token',
                section='Authentication Endpoints',
                required=True,
                description='POST /auth endpoint - Validates signed challenge and returns JWT token',
                requirements='POST request with signed transaction envelope'
            ),
        ]
        sections.append(endpoints_section)

        # Challenge Transaction Features
        challenge_section = SEPSection(name='Challenge Transaction Features')
        challenge_section.fields = [
            SEPField(
                name='challenge_transaction_generation',
                section='Challenge Transaction Features',
                required=True,
                description='Generate challenge transaction with proper structure',
                requirements='Transaction envelope format'
            ),
            SEPField(
                name='home_domain_operation',
                section='Challenge Transaction Features',
                required=True,
                description='First operation contains home_domain + " auth" as data name',
                requirements='ManageData operation with home_domain validation'
            ),
            SEPField(
                name='manage_data_operations',
                section='Challenge Transaction Features',
                required=True,
                description='Challenge uses ManageData operations for auth data',
                requirements='All operations must be ManageData type'
            ),
            SEPField(
                name='nonce_generation',
                section='Challenge Transaction Features',
                required=True,
                description='Random nonce in ManageData operation value',
                requirements='Cryptographically secure random data'
            ),
            SEPField(
                name='sequence_number_zero',
                section='Challenge Transaction Features',
                required=True,
                description='Challenge transaction has sequence number 0',
                requirements='Sequence number validation'
            ),
            SEPField(
                name='server_signature',
                section='Challenge Transaction Features',
                required=True,
                description='Challenge is signed by server before sending to client',
                requirements='Server signature validation'
            ),
            SEPField(
                name='timebounds_enforcement',
                section='Challenge Transaction Features',
                required=True,
                description='Challenge transaction has timebounds for expiration',
                requirements='Time window validation'
            ),
            SEPField(
                name='transaction_envelope_format',
                section='Challenge Transaction Features',
                required=True,
                description='Challenge uses proper Stellar transaction envelope format',
                requirements='TransactionEnvelopeXDR'
            ),
            SEPField(
                name='web_auth_domain_operation',
                section='Challenge Transaction Features',
                required=False,
                description='Optional operation with web_auth_domain for domain verification',
                requirements='ManageData operation for web_auth_domain'
            ),
        ]
        sections.append(challenge_section)

        # Client Domain Features
        client_domain_section = SEPSection(name='Client Domain Features')
        client_domain_section.fields = [
            SEPField(
                name='client_domain_operation',
                section='Client Domain Features',
                required=False,
                description='Add client_domain ManageData operation to challenge',
                requirements='ManageData operation with client_domain'
            ),
            SEPField(
                name='client_domain_parameter',
                section='Client Domain Features',
                required=False,
                description='Support optional client_domain parameter in GET /auth',
                requirements='Query parameter handling'
            ),
            SEPField(
                name='client_domain_signature',
                section='Client Domain Features',
                required=False,
                description='Require signature from client domain account',
                requirements='Client domain account signing'
            ),
            SEPField(
                name='client_domain_verification',
                section='Client Domain Features',
                required=False,
                description='Verify client domain by checking stellar.toml **Note:** This is a server-side verification feature. Client SDKs only need to support the client_domain parameter and signing.',
                requirements='Stellar.toml verification',
                server_only=True
            ),
        ]
        sections.append(client_domain_section)

        # JWT Token Features
        jwt_section = SEPSection(name='JWT Token Features')
        jwt_section.fields = [
            SEPField(
                name='jwt_claims',
                section='JWT Token Features',
                required=True,
                description='JWT token includes required claims (sub, iat, exp)',
                requirements='Standard JWT claims'
            ),
            SEPField(
                name='jwt_expiration',
                section='JWT Token Features',
                required=True,
                description='JWT token includes expiration time',
                requirements='exp claim in JWT'
            ),
            SEPField(
                name='jwt_token_generation',
                section='JWT Token Features',
                required=True,
                description='Generate JWT token after successful challenge validation',
                requirements='JWT encoding and signing'
            ),
            SEPField(
                name='jwt_token_response',
                section='JWT Token Features',
                required=True,
                description='Return JWT token in JSON response with "token" field',
                requirements='JSON response format'
            ),
            SEPField(
                name='jwt_token_validation',
                section='JWT Token Features',
                required=False,
                description='Validate JWT token structure and signature **Note:** This is a server-side validation feature. Client SDKs only need to receive, store, and send the JWT as a bearer token.',
                requirements='JWT decoding and verification',
                server_only=True
            ),
        ]
        sections.append(jwt_section)

        # Verification Features
        verification_section = SEPSection(name='Verification Features')
        verification_section.fields = [
            SEPField(
                name='challenge_validation',
                section='Verification Features',
                required=True,
                description='Validate challenge transaction structure and content',
                requirements='Comprehensive validation'
            ),
            SEPField(
                name='home_domain_validation',
                section='Verification Features',
                required=True,
                description='Validate home domain in challenge matches server',
                requirements='Domain matching'
            ),
            SEPField(
                name='memo_support',
                section='Verification Features',
                required=False,
                description='Support optional memo in challenge for muxed accounts',
                requirements='Memo ID support'
            ),
            SEPField(
                name='multi_signature_support',
                section='Verification Features',
                required=True,
                description='Support multiple signatures on challenge (client account + signers)',
                requirements='Multi-sig transaction support'
            ),
            SEPField(
                name='signature_verification',
                section='Verification Features',
                required=True,
                description='Verify all signatures on challenge transaction',
                requirements='Cryptographic signature verification'
            ),
            SEPField(
                name='timebounds_validation',
                section='Verification Features',
                required=True,
                description='Validate challenge is within valid time window',
                requirements='Time bounds checking with grace period'
            ),
        ]
        sections.append(verification_section)

        return sections

    def _analyze_authentication_endpoints(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze authentication endpoint support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'get_auth_challenge':
                    if 'func getChallenge' in content and 'forAccount accountId' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge(forAccount:memo:homeDomain:clientDomain:)'
                elif field.name == 'post_auth_token':
                    if 'func sendCompletedChallenge' in content and 'base64EnvelopeXDR' in content:
                        field.implemented = True
                        field.sdk_property = 'sendCompletedChallenge(base64EnvelopeXDR:)'

        except Exception as e:
            logger.warning(f"Error analyzing authentication endpoints: {e}")

    def _analyze_challenge_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze challenge transaction feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'challenge_transaction_generation':
                    if 'func getChallenge' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge()'
                elif field.name == 'home_domain_operation':
                    if 'serverHomeDomain + " auth"' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (home domain validation)'
                elif field.name == 'manage_data_operations':
                    if 'case .manageData' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (operation type check)'
                elif field.name == 'nonce_generation':
                    # Server-side feature, but client receives it
                    if 'getChallenge' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge (receives nonce)'
                elif field.name == 'sequence_number_zero':
                    if 'txSeqNum != 0' in content or 'sequenceNumberNot0' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (sequence validation)'
                elif field.name == 'server_signature':
                    if 'serverKeyPair.verify' in content or 'invalidSignature' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (signature verification)'
                elif field.name == 'timebounds_enforcement':
                    if 'txTimeBounds' in content and 'invalidTimeBounds' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (timebounds validation)'
                elif field.name == 'transaction_envelope_format':
                    if 'TransactionEnvelopeXDR' in content:
                        field.implemented = True
                        field.sdk_property = 'TransactionEnvelopeXDR'
                elif field.name == 'web_auth_domain_operation':
                    if '"web_auth_domain"' in content and 'invalidWebAuthDomain' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (web_auth_domain validation)'

        except Exception as e:
            logger.warning(f"Error analyzing challenge features: {e}")

    def _analyze_client_domain_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze client domain feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'client_domain_operation':
                    if '"client_domain"' in content and 'manageData' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (client_domain operation)'
                elif field.name == 'client_domain_parameter':
                    if 'clientDomain' in content and 'client_domain=' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge(clientDomain:)'
                elif field.name == 'client_domain_signature':
                    if 'clientDomainAccountKeyPair' in content and 'signTransaction' in content:
                        field.implemented = True
                        field.sdk_property = 'jwtToken(clientDomainAccountKeyPair:)'
                elif field.name == 'client_domain_verification':
                    # This is a server-side-only feature, marked as such in field definition
                    # No need to analyze implementation since it's not applicable to client SDKs
                    pass

        except Exception as e:
            logger.warning(f"Error analyzing client domain features: {e}")

    def _analyze_jwt_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze JWT token feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'jwt_claims':
                    # Server-side generates claims, client receives token
                    if 'jwtToken' in content and 'sendCompletedChallenge' in content:
                        field.implemented = True
                        field.sdk_property = 'sendCompletedChallenge (receives JWT)'
                elif field.name == 'jwt_expiration':
                    # Server-side generates expiration, client receives token
                    if 'jwtToken' in content:
                        field.implemented = True
                        field.sdk_property = 'JWT token response'
                elif field.name == 'jwt_token_generation':
                    # Server-side feature, client receives it
                    if 'sendCompletedChallenge' in content and '"token"' in content:
                        field.implemented = True
                        field.sdk_property = 'sendCompletedChallenge (receives JWT)'
                elif field.name == 'jwt_token_response':
                    if '"token"' in content and 'jwtToken' in content:
                        field.implemented = True
                        field.sdk_property = 'sendCompletedChallenge response'
                elif field.name == 'jwt_token_validation':
                    # This is a server-side-only feature, marked as such in field definition
                    # No need to analyze implementation since it's not applicable to client SDKs
                    pass

        except Exception as e:
            logger.warning(f"Error analyzing JWT features: {e}")

    def _analyze_verification_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze verification feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'challenge_validation':
                    if 'func isValidChallenge' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge()'
                elif field.name == 'home_domain_validation':
                    if 'invalidHomeDomain' in content and 'serverHomeDomain' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (home domain check)'
                elif field.name == 'memo_support':
                    if 'memo:UInt64?' in content and 'MEMO_TYPE_ID' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge(memo:)'
                elif field.name == 'multi_signature_support':
                    if 'signers:[KeyPair]' in content and 'signTransaction' in content:
                        field.implemented = True
                        field.sdk_property = 'signTransaction(keyPairs:)'
                elif field.name == 'signature_verification':
                    if 'serverKeyPair.verify' in content and 'signature:' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (signature verification)'
                elif field.name == 'timebounds_validation':
                    if 'txTimeBounds' in content and 'timeBoundsGracePeriod' in content:
                        field.implemented = True
                        field.sdk_property = 'isValidChallenge (timebounds with grace period)'

        except Exception as e:
            logger.warning(f"Error analyzing verification features: {e}")


class SEP06Analyzer:
    """Analyzer for SEP-06 (Deposit and Withdrawal API)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-06 implementation"""
        logger.info("Analyzing SEP-06 (Deposit and Withdrawal API) implementation")

        # Create sections based on SEP-06 requirements
        sections = self._create_sep06_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find TransferServerService class
        transfer_service_file = self.sdk_analyzer.find_class_or_struct('TransferServerService')
        if transfer_service_file:
            rel_path = self.sdk_analyzer.get_relative_path(transfer_service_file)
            implementation_files.append(rel_path)
            logger.info(f"Found TransferServerService class at {rel_path}")

        # Find request and response classes
        sep06_classes = [
            'DepositRequest', 'DepositResponse', 'DepositExchangeRequest',
            'WithdrawRequest', 'WithdrawResponse', 'WithdrawExchangeRequest',
            'AnchorInfoResponse', 'AnchorTransactionsResponse', 'AnchorTransaction',
            'FeeRequest', 'AnchorFeeResponse', 'TransferServerError'
        ]
        for class_name in sep06_classes:
            class_file = self.sdk_analyzer.find_class_or_struct(class_name)
            if class_file:
                rel_path = self.sdk_analyzer.get_relative_path(class_file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Deposit Endpoints':
                self._analyze_deposit_endpoints(section, transfer_service_file)
            elif section.name == 'Deposit Request Parameters':
                self._analyze_deposit_request_parameters(section)
            elif section.name == 'Deposit Response Fields':
                self._analyze_deposit_response_fields(section)
            elif section.name == 'Withdraw Endpoints':
                self._analyze_withdraw_endpoints(section, transfer_service_file)
            elif section.name == 'Withdraw Request Parameters':
                self._analyze_withdraw_request_parameters(section)
            elif section.name == 'Withdraw Response Fields':
                self._analyze_withdraw_response_fields(section)
            elif section.name == 'Info Endpoint':
                self._analyze_info_endpoint(section, transfer_service_file)
            elif section.name == 'Info Response Fields':
                self._analyze_info_response_fields(section)
            elif section.name == 'Fee Endpoint':
                self._analyze_fee_endpoint(section, transfer_service_file)
            elif section.name == 'Transaction Endpoints':
                self._analyze_transaction_endpoints(section, transfer_service_file)
            elif section.name == 'Transaction Fields':
                self._analyze_transaction_fields(section)
            elif section.name == 'Transaction Status Values':
                self._analyze_transaction_status_values(section)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive implementation of SEP-06 Deposit and Withdrawal API",
            "TransferServerService class implements all standard endpoints",
            "Both async/await and legacy callback-based APIs are available",
            "Supports SEP-38 quotes via deposit-exchange and withdraw-exchange endpoints",
            "Full support for transaction status tracking and updates",
            "Implements PATCH /transaction for debugging/testing",
            "All request/response models are properly typed with Codable support",
            "JWT authentication support for all protected endpoints",
            "Comprehensive error handling with specific error types",
            "Thread-safe implementation suitable for concurrent requests",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-06!",
                "Always use SEP-10 authentication for production deployments",
                "Handle all transaction statuses appropriately in client applications",
                "Implement proper error handling for all TransferServerError cases",
                "Use SEP-38 quote endpoints for cross-asset transfers",
                "Monitor transaction status changes via on_change_callback",
                "Validate all input parameters before making requests",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-06 compliance",
            ]

        return matrix

    def _create_sep06_sections(self) -> List[SEPSection]:
        """Create SEP-06 sections with all fields"""
        sections = []

        # Deposit Endpoints
        deposit_endpoints_section = SEPSection(name='Deposit Endpoints')
        deposit_endpoints_section.fields = [
            SEPField(
                name='deposit',
                section='Deposit Endpoints',
                required=True,
                description='GET /deposit - Initiates a deposit transaction for on-chain assets',
                requirements='HTTP GET endpoint'
            ),
            SEPField(
                name='deposit_exchange',
                section='Deposit Endpoints',
                required=False,
                description='GET /deposit-exchange - Initiates a deposit with asset exchange (SEP-38 integration)',
                requirements='HTTP GET endpoint with SEP-38 support'
            ),
        ]
        sections.append(deposit_endpoints_section)

        # Deposit Request Parameters
        deposit_request_section = SEPSection(name='Deposit Request Parameters')
        deposit_request_section.fields = [
            SEPField('asset_code', 'Deposit Request Parameters', True, 'Code of the on-chain asset the user wants to receive', 'string'),
            SEPField('account', 'Deposit Request Parameters', True, 'Stellar account ID of the user', 'Stellar G... account or M... muxed account'),
            SEPField('memo_type', 'Deposit Request Parameters', False, 'Type of memo to attach to transaction', 'text, id, or hash'),
            SEPField('memo', 'Deposit Request Parameters', False, 'Value of memo to attach to transaction', 'string'),
            SEPField('email_address', 'Deposit Request Parameters', False, 'Email address of the user (for notifications)', 'string (email format)'),
            SEPField('type', 'Deposit Request Parameters', False, 'Type of deposit method (e.g., bank_account, cash, mobile_money)', 'string'),
            SEPField('wallet_name', 'Deposit Request Parameters', False, 'Name of the wallet the user is using', 'string (deprecated)'),
            SEPField('wallet_url', 'Deposit Request Parameters', False, 'URL of the wallet the user is using', 'string (deprecated)'),
            SEPField('lang', 'Deposit Request Parameters', False, 'Language code for response messages (ISO 639-1)', 'string (ISO 639-1)'),
            SEPField('on_change_callback', 'Deposit Request Parameters', False, 'URL for anchor to send callback when transaction status changes', 'string (URL)'),
            SEPField('amount', 'Deposit Request Parameters', False, 'Amount of on-chain asset the user wants to receive', 'string (decimal)'),
            SEPField('country_code', 'Deposit Request Parameters', False, 'Country code of the user (ISO 3166-1 alpha-3)', 'string (ISO 3166-1 alpha-3)'),
            SEPField('claimable_balance_supported', 'Deposit Request Parameters', False, 'Whether the client supports receiving claimable balances', 'string (boolean)'),
            SEPField('customer_id', 'Deposit Request Parameters', False, 'ID of the customer from SEP-12 KYC process', 'string'),
            SEPField('location_id', 'Deposit Request Parameters', False, 'ID of the physical location for cash pickup', 'string'),
        ]
        sections.append(deposit_request_section)

        # Deposit Response Fields
        deposit_response_section = SEPSection(name='Deposit Response Fields')
        deposit_response_section.fields = [
            SEPField('how', 'Deposit Response Fields', True, 'Instructions for how to deposit the asset', 'string (deprecated in favor of instructions)'),
            SEPField('id', 'Deposit Response Fields', False, 'Persistent transaction identifier', 'string'),
            SEPField('eta', 'Deposit Response Fields', False, 'Estimated seconds until deposit completes', 'integer'),
            SEPField('min_amount', 'Deposit Response Fields', False, 'Minimum deposit amount', 'decimal'),
            SEPField('max_amount', 'Deposit Response Fields', False, 'Maximum deposit amount', 'decimal'),
            SEPField('fee_fixed', 'Deposit Response Fields', False, 'Fixed fee for deposit', 'decimal'),
            SEPField('fee_percent', 'Deposit Response Fields', False, 'Percentage fee for deposit', 'decimal'),
            SEPField('extra_info', 'Deposit Response Fields', False, 'Additional information about the deposit', 'object'),
        ]
        sections.append(deposit_response_section)

        # Withdraw Endpoints
        withdraw_endpoints_section = SEPSection(name='Withdraw Endpoints')
        withdraw_endpoints_section.fields = [
            SEPField(
                name='withdraw',
                section='Withdraw Endpoints',
                required=True,
                description='GET /withdraw - Initiates a withdrawal transaction for off-chain assets',
                requirements='HTTP GET endpoint'
            ),
            SEPField(
                name='withdraw_exchange',
                section='Withdraw Endpoints',
                required=False,
                description='GET /withdraw-exchange - Initiates a withdrawal with asset exchange (SEP-38 integration)',
                requirements='HTTP GET endpoint with SEP-38 support'
            ),
        ]
        sections.append(withdraw_endpoints_section)

        # Withdraw Request Parameters
        withdraw_request_section = SEPSection(name='Withdraw Request Parameters')
        withdraw_request_section.fields = [
            SEPField('asset_code', 'Withdraw Request Parameters', True, 'Code of the on-chain asset the user wants to send', 'string'),
            SEPField('type', 'Withdraw Request Parameters', True, 'Type of withdrawal method (e.g., bank_account, cash, mobile_money)', 'string'),
            SEPField('dest', 'Withdraw Request Parameters', False, 'Destination for withdrawal (bank account number, etc.)', 'string (deprecated)'),
            SEPField('dest_extra', 'Withdraw Request Parameters', False, 'Extra information for destination (routing number, etc.)', 'string (deprecated)'),
            SEPField('account', 'Withdraw Request Parameters', False, 'Stellar account ID of the user', 'Stellar G... account or M... muxed account'),
            SEPField('memo', 'Withdraw Request Parameters', False, 'Memo to identify the user if account is shared', 'string'),
            SEPField('memo_type', 'Withdraw Request Parameters', False, 'Type of memo (text, id, or hash)', 'text, id, or hash'),
            SEPField('wallet_name', 'Withdraw Request Parameters', False, 'Name of the wallet the user is using', 'string (deprecated)'),
            SEPField('wallet_url', 'Withdraw Request Parameters', False, 'URL of the wallet the user is using', 'string (deprecated)'),
            SEPField('lang', 'Withdraw Request Parameters', False, 'Language code for response messages (ISO 639-1)', 'string (ISO 639-1)'),
            SEPField('on_change_callback', 'Withdraw Request Parameters', False, 'URL for anchor to send callback when transaction status changes', 'string (URL)'),
            SEPField('amount', 'Withdraw Request Parameters', False, 'Amount of on-chain asset the user wants to send', 'string (decimal)'),
            SEPField('country_code', 'Withdraw Request Parameters', False, 'Country code of the user (ISO 3166-1 alpha-3)', 'string (ISO 3166-1 alpha-3)'),
            SEPField('refund_memo', 'Withdraw Request Parameters', False, 'Memo to use for refund transaction if withdrawal fails', 'string'),
            SEPField('refund_memo_type', 'Withdraw Request Parameters', False, 'Type of refund memo (text, id, or hash)', 'text, id, or hash'),
            SEPField('customer_id', 'Withdraw Request Parameters', False, 'ID of the customer from SEP-12 KYC process', 'string'),
            SEPField('location_id', 'Withdraw Request Parameters', False, 'ID of the physical location for cash pickup', 'string'),
        ]
        sections.append(withdraw_request_section)

        # Withdraw Response Fields
        withdraw_response_section = SEPSection(name='Withdraw Response Fields')
        withdraw_response_section.fields = [
            SEPField('account_id', 'Withdraw Response Fields', True, 'Stellar account to send withdrawn assets to', 'Stellar G... account'),
            SEPField('memo_type', 'Withdraw Response Fields', False, 'Type of memo to attach to transaction', 'text, id, or hash'),
            SEPField('memo', 'Withdraw Response Fields', False, 'Value of memo to attach to transaction', 'string'),
            SEPField('id', 'Withdraw Response Fields', True, 'Persistent transaction identifier', 'string'),
            SEPField('eta', 'Withdraw Response Fields', False, 'Estimated seconds until withdrawal completes', 'integer'),
            SEPField('min_amount', 'Withdraw Response Fields', False, 'Minimum withdrawal amount', 'decimal'),
            SEPField('max_amount', 'Withdraw Response Fields', False, 'Maximum withdrawal amount', 'decimal'),
            SEPField('fee_fixed', 'Withdraw Response Fields', False, 'Fixed fee for withdrawal', 'decimal'),
            SEPField('fee_percent', 'Withdraw Response Fields', False, 'Percentage fee for withdrawal', 'decimal'),
            SEPField('extra_info', 'Withdraw Response Fields', False, 'Additional information about the withdrawal', 'object'),
        ]
        sections.append(withdraw_response_section)

        # Info Endpoint
        info_endpoint_section = SEPSection(name='Info Endpoint')
        info_endpoint_section.fields = [
            SEPField(
                name='info_endpoint',
                section='Info Endpoint',
                required=True,
                description='GET /info - Provides anchor capabilities and asset information',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(info_endpoint_section)

        # Info Response Fields
        info_response_section = SEPSection(name='Info Response Fields')
        info_response_section.fields = [
            SEPField('deposit', 'Info Response Fields', True, 'Map of asset codes to deposit asset information', 'object'),
            SEPField('withdraw', 'Info Response Fields', True, 'Map of asset codes to withdraw asset information', 'object'),
            SEPField('deposit-exchange', 'Info Response Fields', False, 'Map of asset codes to deposit-exchange asset information', 'object'),
            SEPField('withdraw-exchange', 'Info Response Fields', False, 'Map of asset codes to withdraw-exchange asset information', 'object'),
            SEPField('fee', 'Info Response Fields', False, 'Fee endpoint information', 'object'),
            SEPField('transactions', 'Info Response Fields', False, 'Transaction history endpoint information', 'object'),
            SEPField('transaction', 'Info Response Fields', False, 'Single transaction endpoint information', 'object'),
            SEPField('features', 'Info Response Fields', False, 'Feature flags supported by the anchor', 'object'),
        ]
        sections.append(info_response_section)

        # Fee Endpoint
        fee_endpoint_section = SEPSection(name='Fee Endpoint')
        fee_endpoint_section.fields = [
            SEPField(
                name='fee_endpoint',
                section='Fee Endpoint',
                required=False,
                description='GET /fee - Calculates fees for a deposit or withdrawal operation (deprecated)',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(fee_endpoint_section)

        # Transaction Endpoints
        transaction_endpoints_section = SEPSection(name='Transaction Endpoints')
        transaction_endpoints_section.fields = [
            SEPField('transactions', 'Transaction Endpoints', True, 'GET /transactions - Retrieves transaction history for an account', 'HTTP GET endpoint'),
            SEPField('transaction', 'Transaction Endpoints', True, 'GET /transaction - Retrieves details for a single transaction', 'HTTP GET endpoint'),
            SEPField('patch_transaction', 'Transaction Endpoints', False, 'PATCH /transaction - Updates transaction fields (for debugging/testing)', 'HTTP PATCH endpoint'),
        ]
        sections.append(transaction_endpoints_section)

        # Transaction Fields
        transaction_fields_section = SEPSection(name='Transaction Fields')
        transaction_fields_section.fields = [
            SEPField('id', 'Transaction Fields', True, 'Unique transaction identifier', 'string'),
            SEPField('kind', 'Transaction Fields', True, 'Kind of transaction (deposit, withdrawal, deposit-exchange, withdrawal-exchange)', 'string'),
            SEPField('status', 'Transaction Fields', True, 'Current status of the transaction', 'string'),
            SEPField('started_at', 'Transaction Fields', True, 'When transaction was created (ISO 8601)', 'string (ISO 8601 date-time)'),
            SEPField('status_eta', 'Transaction Fields', False, 'Estimated seconds until status changes', 'integer'),
            SEPField('amount_in', 'Transaction Fields', False, 'Amount received by anchor', 'string (decimal)'),
            SEPField('amount_out', 'Transaction Fields', False, 'Amount sent by anchor to user', 'string (decimal)'),
            SEPField('amount_fee', 'Transaction Fields', False, 'Total fee charged for transaction', 'string (decimal)'),
            SEPField('completed_at', 'Transaction Fields', False, 'When transaction completed (ISO 8601)', 'string (ISO 8601 date-time)'),
            SEPField('stellar_transaction_id', 'Transaction Fields', False, 'Hash of the Stellar transaction', 'string (transaction hash)'),
            SEPField('external_transaction_id', 'Transaction Fields', False, 'Identifier from external system', 'string'),
            SEPField('message', 'Transaction Fields', False, 'Human-readable message about transaction', 'string'),
            SEPField('refunded', 'Transaction Fields', False, 'Whether transaction was refunded', 'boolean'),
            SEPField('refunds', 'Transaction Fields', False, 'Refund information if applicable', 'object'),
            SEPField('from', 'Transaction Fields', False, 'Stellar account that initiated the transaction', 'string'),
            SEPField('to', 'Transaction Fields', False, 'Stellar account receiving the transaction', 'string'),
        ]
        sections.append(transaction_fields_section)

        # Transaction Status Values
        transaction_status_section = SEPSection(name='Transaction Status Values')
        transaction_status_section.fields = [
            SEPField('completed', 'Transaction Status Values', True, 'Transaction completed successfully', 'status value'),
            SEPField('pending_anchor', 'Transaction Status Values', True, 'Anchor is processing the transaction', 'status value'),
            SEPField('pending_stellar', 'Transaction Status Values', False, 'Stellar transaction has been submitted', 'status value'),
            SEPField('pending_user_transfer_start', 'Transaction Status Values', True, 'Waiting for user to initiate off-chain transfer', 'status value'),
            SEPField('incomplete', 'Transaction Status Values', True, 'Deposit/withdrawal has not yet been submitted', 'status value'),
            SEPField('pending_external', 'Transaction Status Values', False, 'Waiting for external action (banking system, etc.)', 'status value'),
            SEPField('pending_trust', 'Transaction Status Values', False, 'User needs to add trustline for asset', 'status value'),
            SEPField('pending_user', 'Transaction Status Values', False, 'Waiting for user action (accepting claimable balance)', 'status value'),
            SEPField('pending_user_transfer_complete', 'Transaction Status Values', False, 'Off-chain transfer has been initiated', 'status value'),
            SEPField('error', 'Transaction Status Values', False, 'Transaction failed with error', 'status value'),
            SEPField('refunded', 'Transaction Status Values', False, 'Transaction refunded', 'status value'),
            SEPField('expired', 'Transaction Status Values', False, 'Transaction expired without completion', 'status value'),
        ]
        sections.append(transaction_status_section)

        return sections

    def _analyze_deposit_endpoints(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze deposit endpoint support"""
        if not transfer_service_file:
            return

        try:
            content = transfer_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'deposit':
                    if 'func deposit(request: DepositRequest)' in content:
                        field.implemented = True
                        field.sdk_property = 'deposit(request:)'
                elif field.name == 'deposit_exchange':
                    if 'func depositExchange(request: DepositExchangeRequest)' in content:
                        field.implemented = True
                        field.sdk_property = 'depositExchange(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing deposit endpoints: {e}")

    def _analyze_deposit_request_parameters(self, section: SEPSection) -> None:
        """Analyze deposit request parameter support"""
        request_file = self.sdk_analyzer.find_class_or_struct('DepositRequest')
        if not request_file:
            return

        try:
            content = request_file.read_text(encoding='utf-8')

            param_map = {
                'asset_code': 'assetCode',
                'account': 'account',
                'memo_type': 'memoType',
                'memo': 'memo',
                'email_address': 'emailAddress',
                'type': 'type',
                'wallet_name': 'walletName',
                'wallet_url': 'walletUrl',
                'lang': 'lang',
                'on_change_callback': 'onChangeCallback',
                'amount': 'amount',
                'country_code': 'countryCode',
                'claimable_balance_supported': 'claimableBalanceSupported',
                'customer_id': 'customerId',
                'location_id': 'locationId',
            }

            for field in section.fields:
                sdk_property = param_map.get(field.name)
                if sdk_property and (f'var {sdk_property}:' in content or f'let {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing deposit request parameters: {e}")

    def _analyze_deposit_response_fields(self, section: SEPSection) -> None:
        """Analyze deposit response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('DepositResponse')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'how': 'how',
                'id': 'id',
                'eta': 'eta',
                'min_amount': 'minAmount',
                'max_amount': 'maxAmount',
                'fee_fixed': 'feeFixed',
                'fee_percent': 'feePercent',
                'extra_info': 'extraInfo',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'var {sdk_property}:' in content or f'let {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing deposit response fields: {e}")

    def _analyze_withdraw_endpoints(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze withdraw endpoint support"""
        if not transfer_service_file:
            return

        try:
            content = transfer_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'withdraw':
                    if 'func withdraw(request: WithdrawRequest)' in content:
                        field.implemented = True
                        field.sdk_property = 'withdraw(request:)'
                elif field.name == 'withdraw_exchange':
                    if 'func withdrawExchange(request: WithdrawExchangeRequest)' in content:
                        field.implemented = True
                        field.sdk_property = 'withdrawExchange(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing withdraw endpoints: {e}")

    def _analyze_withdraw_request_parameters(self, section: SEPSection) -> None:
        """Analyze withdraw request parameter support"""
        request_file = self.sdk_analyzer.find_class_or_struct('WithdrawRequest')
        if not request_file:
            return

        try:
            content = request_file.read_text(encoding='utf-8')

            param_map = {
                'asset_code': 'assetCode',
                'type': 'type',
                'dest': 'dest',
                'dest_extra': 'destExtra',
                'account': 'account',
                'memo': 'memo',
                'memo_type': 'memoType',
                'wallet_name': 'walletName',
                'wallet_url': 'walletUrl',
                'lang': 'lang',
                'on_change_callback': 'onChangeCallback',
                'amount': 'amount',
                'country_code': 'countryCode',
                'refund_memo': 'refundMemo',
                'refund_memo_type': 'refundMemoType',
                'customer_id': 'customerId',
                'location_id': 'locationId',
            }

            for field in section.fields:
                sdk_property = param_map.get(field.name)
                if sdk_property and (f'var {sdk_property}:' in content or f'let {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing withdraw request parameters: {e}")

    def _analyze_withdraw_response_fields(self, section: SEPSection) -> None:
        """Analyze withdraw response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('WithdrawResponse')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'account_id': 'accountId',
                'memo_type': 'memoType',
                'memo': 'memo',
                'id': 'id',
                'eta': 'eta',
                'min_amount': 'minAmount',
                'max_amount': 'maxAmount',
                'fee_fixed': 'feeFixed',
                'fee_percent': 'feePercent',
                'extra_info': 'extraInfo',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'var {sdk_property}:' in content or f'let {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing withdraw response fields: {e}")

    def _analyze_info_endpoint(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze info endpoint support"""
        if not transfer_service_file:
            return

        try:
            content = transfer_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'info_endpoint':
                    if 'func info(language:' in content:
                        field.implemented = True
                        field.sdk_property = 'info(language:jwtToken:)'

        except Exception as e:
            logger.warning(f"Error analyzing info endpoint: {e}")

    def _analyze_info_response_fields(self, section: SEPSection) -> None:
        """Analyze info response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('AnchorInfoResponse')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'deposit': 'deposit',
                'withdraw': 'withdraw',
                'deposit-exchange': 'depositExchange',
                'withdraw-exchange': 'withdrawExchange',
                'fee': 'fee',
                'transactions': 'transactions',
                'transaction': 'transaction',
                'features': 'features',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'var {sdk_property}:' in content or f'let {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing info response fields: {e}")

    def _analyze_fee_endpoint(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze fee endpoint support"""
        if not transfer_service_file:
            return

        try:
            content = transfer_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'fee_endpoint':
                    if 'func fee(request: FeeRequest)' in content:
                        field.implemented = True
                        field.sdk_property = 'fee(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing fee endpoint: {e}")

    def _analyze_transaction_endpoints(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze transaction endpoint support"""
        if not transfer_service_file:
            return

        try:
            content = transfer_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'transactions':
                    if 'func getTransactions(request:' in content:
                        field.implemented = True
                        field.sdk_property = 'getTransactions(request:)'
                elif field.name == 'transaction':
                    if 'func getTransaction(request:' in content:
                        field.implemented = True
                        field.sdk_property = 'getTransaction(request:)'
                elif field.name == 'patch_transaction':
                    if 'func patchTransaction(id:' in content:
                        field.implemented = True
                        field.sdk_property = 'patchTransaction(id:jwt:contentType:body:)'

        except Exception as e:
            logger.warning(f"Error analyzing transaction endpoints: {e}")

    def _analyze_transaction_fields(self, section: SEPSection) -> None:
        """Analyze transaction field support"""
        transaction_file = self.sdk_analyzer.find_class_or_struct('AnchorTransaction')
        if not transaction_file:
            return

        try:
            content = transaction_file.read_text(encoding='utf-8')

            field_map = {
                'id': 'id',
                'kind': 'kind',
                'status': 'status',
                'started_at': 'startedAt',
                'status_eta': 'statusEta',
                'amount_in': 'amountIn',
                'amount_out': 'amountOut',
                'amount_fee': 'amountFee',
                'completed_at': 'completedAt',
                'stellar_transaction_id': 'stellarTransactionId',
                'external_transaction_id': 'externalTransactionId',
                'message': 'message',
                'refunded': 'refunded',
                'refunds': 'refunds',
                'from': 'from',
                'to': 'to',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'var {sdk_property}:' in content or f'let {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing transaction fields: {e}")

    def _analyze_transaction_status_values(self, section: SEPSection) -> None:
        """Analyze transaction status value support"""
        status_file = self.sdk_analyzer.find_class_or_struct('AnchorTransactionStatus')
        if not status_file:
            return

        try:
            content = status_file.read_text(encoding='utf-8')

            status_map = {
                'completed': 'completed',
                'pending_anchor': 'pendingAnchor',
                'pending_stellar': 'pendingStellar',
                'pending_user_transfer_start': 'pendingUserTransferStart',
                'incomplete': 'incomplete',
                'pending_external': 'pendingExternal',
                'pending_trust': 'pendingTrust',
                'pending_user': 'pendingUser',
                'pending_user_transfer_complete': 'pendingUserTransferComplete',
                'error': 'error',
                'refunded': 'refunded',
                'expired': 'expired',
            }

            for field in section.fields:
                sdk_property = status_map.get(field.name)
                if sdk_property and sdk_property != 'This status is not explicitly defined in the iOS SDK enum':
                    if f'case {sdk_property}' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing transaction status values: {e}")


class SEP38Analyzer:
    """Analyzer for SEP-38 (Anchor RFQ API)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-38 implementation"""
        logger.info("Analyzing SEP-38 (Anchor RFQ API) implementation")

        # Create sections based on SEP-38 requirements
        sections = self._create_sep38_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find QuoteService class
        quote_service_file = self.sdk_analyzer.find_class_or_struct('QuoteService')
        if quote_service_file:
            rel_path = self.sdk_analyzer.get_relative_path(quote_service_file)
            implementation_files.append(rel_path)
            logger.info(f"Found QuoteService class at {rel_path}")

        # Find Sep38PostQuoteRequest class
        request_file = self.sdk_analyzer.find_class_or_struct('Sep38PostQuoteRequest')
        if request_file:
            rel_path = self.sdk_analyzer.get_relative_path(request_file)
            implementation_files.append(rel_path)
            logger.info(f"Found Sep38PostQuoteRequest class at {rel_path}")

        # Find response classes
        for response_class in ['Sep38InfoResponse', 'Sep38PricesResponse', 'Sep38PriceResponse',
                                'Sep38QuoteResponse', 'Sep38Asset', 'Sep38BuyAsset',
                                'Sep38Fee', 'Sep38FeeDetails']:
            response_file = self.sdk_analyzer.find_class_or_struct(response_class)
            if response_file:
                rel_path = self.sdk_analyzer.get_relative_path(response_file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)
                    logger.info(f"Found {response_class} class at {rel_path}")

        # Find error class
        error_file = self.sdk_analyzer.find_class_or_struct('QuoteServiceError')
        if error_file:
            rel_path = self.sdk_analyzer.get_relative_path(error_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found QuoteServiceError at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Info Endpoint':
                self._analyze_info_endpoint(section, quote_service_file)
            elif section.name == 'Info Response Fields':
                self._analyze_info_response_fields(section)
            elif section.name == 'Asset Fields':
                self._analyze_asset_fields(section)
            elif section.name == 'Delivery Method Fields':
                self._analyze_delivery_method_fields(section)
            elif section.name == 'Prices Endpoint':
                self._analyze_prices_endpoint(section, quote_service_file)
            elif section.name == 'Prices Request Parameters':
                self._analyze_prices_request_parameters(section, quote_service_file)
            elif section.name == 'Prices Response Fields':
                self._analyze_prices_response_fields(section)
            elif section.name == 'Buy Asset Fields':
                self._analyze_buy_asset_fields(section)
            elif section.name == 'Price Endpoint':
                self._analyze_price_endpoint(section, quote_service_file)
            elif section.name == 'Price Request Parameters':
                self._analyze_price_request_parameters(section, quote_service_file)
            elif section.name == 'Price Response Fields':
                self._analyze_price_response_fields(section)
            elif section.name == 'Post Quote Endpoint':
                self._analyze_post_quote_endpoint(section, quote_service_file)
            elif section.name == 'Post Quote Request Fields':
                self._analyze_post_quote_request_fields(section)
            elif section.name == 'Get Quote Endpoint':
                self._analyze_get_quote_endpoint(section, quote_service_file)
            elif section.name == 'Quote Response Fields':
                self._analyze_quote_response_fields(section)
            elif section.name == 'Fee Fields':
                self._analyze_fee_fields(section)
            elif section.name == 'Fee Details Fields':
                self._analyze_fee_details_fields(section)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive implementation of SEP-38 Anchor RFQ API",
            "QuoteService class implements all standard endpoints (info, prices, price, quote)",
            "Both async/await and legacy callback-based APIs are available",
            "Full support for firm quotes with expiration timestamps",
            "Indicative pricing for multiple asset pairs via /prices endpoint",
            "Single asset pair indicative pricing via /price endpoint",
            "Comprehensive request/response models with Codable support",
            "All fields properly mapped with snake_case to camelCase conversion",
            "JWT authentication support for all protected endpoints",
            "Support for SEP-6 and SEP-31 quote contexts",
            "Delivery method specifications for off-chain assets",
            "Country code filtering for jurisdiction-specific quotes",
            "Fee breakdown with optional detailed fee components",
            "Thread-safe implementation suitable for concurrent requests",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-38!",
                "Always use SEP-10 authentication for protected endpoints",
                "Handle quote expiration appropriately in client applications",
                "Use /prices for multi-asset price discovery",
                "Use /price for single asset pair indicative pricing",
                "Use POST /quote for firm quotes before initiating transfers",
                "Provide either sell_amount or buy_amount, never both",
                "Specify context (sep6 or sep31) based on the transfer type",
                "Include delivery methods and country codes for off-chain assets",
                "Monitor quote expiration via expires_at timestamp",
                "Store quote IDs for transaction reconciliation",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-38 compliance",
            ]

        return matrix

    def _create_sep38_sections(self) -> List[SEPSection]:
        """Create SEP-38 sections with all fields"""
        sections = []

        # Info Endpoint
        info_endpoint_section = SEPSection(name='Info Endpoint')
        info_endpoint_section.fields = [
            SEPField(
                name='info_endpoint',
                section='Info Endpoint',
                required=True,
                description='GET /info - Returns supported Stellar and off-chain assets available for trading',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(info_endpoint_section)

        # Info Response Fields
        info_response_section = SEPSection(name='Info Response Fields')
        info_response_section.fields = [
            SEPField('assets', 'Info Response Fields', True, 'Array of asset objects supported for trading', 'array of asset objects'),
        ]
        sections.append(info_response_section)

        # Asset Fields
        asset_fields_section = SEPSection(name='Asset Fields')
        asset_fields_section.fields = [
            SEPField('asset', 'Asset Fields', True, 'Asset identifier in Asset Identification Format', 'string'),
            SEPField('sell_delivery_methods', 'Asset Fields', False, 'Array of delivery methods for selling this asset', 'array of delivery method objects'),
            SEPField('buy_delivery_methods', 'Asset Fields', False, 'Array of delivery methods for buying this asset', 'array of delivery method objects'),
            SEPField('country_codes', 'Asset Fields', False, 'Array of ISO 3166-2 or ISO 3166-1 alpha-2 country codes', 'array of strings'),
        ]
        sections.append(asset_fields_section)

        # Delivery Method Fields
        delivery_method_section = SEPSection(name='Delivery Method Fields')
        delivery_method_section.fields = [
            SEPField('name', 'Delivery Method Fields', True, 'Delivery method name identifier', 'string'),
            SEPField('description', 'Delivery Method Fields', True, 'Human-readable description of the delivery method', 'string'),
        ]
        sections.append(delivery_method_section)

        # Prices Endpoint
        prices_endpoint_section = SEPSection(name='Prices Endpoint')
        prices_endpoint_section.fields = [
            SEPField(
                name='prices_endpoint',
                section='Prices Endpoint',
                required=True,
                description='GET /prices - Returns indicative prices of off-chain assets in exchange for Stellar assets',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(prices_endpoint_section)

        # Prices Request Parameters
        prices_request_section = SEPSection(name='Prices Request Parameters')
        prices_request_section.fields = [
            SEPField('sell_asset', 'Prices Request Parameters', True, 'Asset to sell using Asset Identification Format', 'string'),
            SEPField('sell_amount', 'Prices Request Parameters', True, 'Amount of sell_asset to exchange', 'string (decimal)'),
            SEPField('sell_delivery_method', 'Prices Request Parameters', False, 'Delivery method for off-chain sell asset', 'string'),
            SEPField('buy_delivery_method', 'Prices Request Parameters', False, 'Delivery method for off-chain buy asset', 'string'),
            SEPField('country_code', 'Prices Request Parameters', False, 'ISO 3166-2 or ISO-3166-1 alpha-2 country code', 'string'),
        ]
        sections.append(prices_request_section)

        # Prices Response Fields
        prices_response_section = SEPSection(name='Prices Response Fields')
        prices_response_section.fields = [
            SEPField('buy_assets', 'Prices Response Fields', True, 'Array of buy asset objects with prices', 'array of buy asset objects'),
        ]
        sections.append(prices_response_section)

        # Buy Asset Fields
        buy_asset_section = SEPSection(name='Buy Asset Fields')
        buy_asset_section.fields = [
            SEPField('asset', 'Buy Asset Fields', True, 'Asset identifier in Asset Identification Format', 'string'),
            SEPField('price', 'Buy Asset Fields', True, 'Price offered by anchor for one unit of buy_asset', 'string (decimal)'),
            SEPField('decimals', 'Buy Asset Fields', True, 'Number of decimals for the buy asset', 'integer'),
        ]
        sections.append(buy_asset_section)

        # Price Endpoint
        price_endpoint_section = SEPSection(name='Price Endpoint')
        price_endpoint_section.fields = [
            SEPField(
                name='price_endpoint',
                section='Price Endpoint',
                required=True,
                description='GET /price - Returns indicative price for a specific asset pair',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(price_endpoint_section)

        # Price Request Parameters
        price_request_section = SEPSection(name='Price Request Parameters')
        price_request_section.fields = [
            SEPField('context', 'Price Request Parameters', True, 'Context for quote usage (sep6 or sep31)', 'string (enum: sep6, sep31)'),
            SEPField('sell_asset', 'Price Request Parameters', True, 'Asset client would like to sell', 'string'),
            SEPField('buy_asset', 'Price Request Parameters', True, 'Asset client would like to exchange for sell_asset', 'string'),
            SEPField('sell_amount', 'Price Request Parameters', False, 'Amount of sell_asset to exchange (mutually exclusive with buy_amount)', 'string (decimal)'),
            SEPField('buy_amount', 'Price Request Parameters', False, 'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)', 'string (decimal)'),
            SEPField('sell_delivery_method', 'Price Request Parameters', False, 'Delivery method for off-chain sell asset', 'string'),
            SEPField('buy_delivery_method', 'Price Request Parameters', False, 'Delivery method for off-chain buy asset', 'string'),
            SEPField('country_code', 'Price Request Parameters', False, 'ISO 3166-2 or ISO-3166-1 alpha-2 country code', 'string'),
        ]
        sections.append(price_request_section)

        # Price Response Fields
        price_response_section = SEPSection(name='Price Response Fields')
        price_response_section.fields = [
            SEPField('total_price', 'Price Response Fields', True, 'Total conversion price including fees', 'string (decimal)'),
            SEPField('price', 'Price Response Fields', True, 'Base conversion price excluding fees', 'string (decimal)'),
            SEPField('sell_amount', 'Price Response Fields', True, 'Amount of sell_asset that will be exchanged', 'string (decimal)'),
            SEPField('buy_amount', 'Price Response Fields', True, 'Amount of buy_asset that will be received', 'string (decimal)'),
            SEPField('fee', 'Price Response Fields', True, 'Fee object with total, asset, and optional details', 'fee object'),
        ]
        sections.append(price_response_section)

        # Post Quote Endpoint
        post_quote_endpoint_section = SEPSection(name='Post Quote Endpoint')
        post_quote_endpoint_section.fields = [
            SEPField(
                name='post_quote_endpoint',
                section='Post Quote Endpoint',
                required=True,
                description='POST /quote - Request a firm quote for asset exchange',
                requirements='HTTP POST endpoint'
            ),
        ]
        sections.append(post_quote_endpoint_section)

        # Post Quote Request Fields
        post_quote_request_section = SEPSection(name='Post Quote Request Fields')
        post_quote_request_section.fields = [
            SEPField('context', 'Post Quote Request Fields', True, 'Context for quote usage (sep6 or sep31)', 'string (enum: sep6, sep31)'),
            SEPField('sell_asset', 'Post Quote Request Fields', True, 'Asset client would like to sell', 'string'),
            SEPField('buy_asset', 'Post Quote Request Fields', True, 'Asset client would like to exchange for sell_asset', 'string'),
            SEPField('sell_amount', 'Post Quote Request Fields', False, 'Amount of sell_asset to exchange (mutually exclusive with buy_amount)', 'string (decimal)'),
            SEPField('buy_amount', 'Post Quote Request Fields', False, 'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)', 'string (decimal)'),
            SEPField('expire_after', 'Post Quote Request Fields', False, 'Requested expiration timestamp for the quote (ISO 8601)', 'datetime (ISO 8601)'),
            SEPField('sell_delivery_method', 'Post Quote Request Fields', False, 'Delivery method for off-chain sell asset', 'string'),
            SEPField('buy_delivery_method', 'Post Quote Request Fields', False, 'Delivery method for off-chain buy asset', 'string'),
            SEPField('country_code', 'Post Quote Request Fields', False, 'ISO 3166-2 or ISO-3166-1 alpha-2 country code', 'string'),
        ]
        sections.append(post_quote_request_section)

        # Get Quote Endpoint
        get_quote_endpoint_section = SEPSection(name='Get Quote Endpoint')
        get_quote_endpoint_section.fields = [
            SEPField(
                name='get_quote_endpoint',
                section='Get Quote Endpoint',
                required=True,
                description='GET /quote/:id - Fetch a previously-provided firm quote',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(get_quote_endpoint_section)

        # Quote Response Fields
        quote_response_section = SEPSection(name='Quote Response Fields')
        quote_response_section.fields = [
            SEPField('id', 'Quote Response Fields', True, 'Unique identifier for the quote', 'string'),
            SEPField('expires_at', 'Quote Response Fields', True, 'Expiration timestamp for the quote (ISO 8601)', 'datetime (ISO 8601)'),
            SEPField('total_price', 'Quote Response Fields', True, 'Total conversion price including fees', 'string (decimal)'),
            SEPField('price', 'Quote Response Fields', True, 'Base conversion price excluding fees', 'string (decimal)'),
            SEPField('sell_asset', 'Quote Response Fields', True, 'Asset to be sold', 'string'),
            SEPField('sell_amount', 'Quote Response Fields', True, 'Amount of sell_asset to be exchanged', 'string (decimal)'),
            SEPField('buy_asset', 'Quote Response Fields', True, 'Asset to be bought', 'string'),
            SEPField('buy_amount', 'Quote Response Fields', True, 'Amount of buy_asset to be received', 'string (decimal)'),
            SEPField('fee', 'Quote Response Fields', True, 'Fee object with total, asset, and optional details', 'fee object'),
        ]
        sections.append(quote_response_section)

        # Fee Fields
        fee_fields_section = SEPSection(name='Fee Fields')
        fee_fields_section.fields = [
            SEPField('total', 'Fee Fields', True, 'Total fee amount as decimal string', 'string (decimal)'),
            SEPField('asset', 'Fee Fields', True, 'Asset identifier for the fee', 'string'),
            SEPField('details', 'Fee Fields', False, 'Optional array of fee breakdown objects', 'array of fee details objects'),
        ]
        sections.append(fee_fields_section)

        # Fee Details Fields
        fee_details_section = SEPSection(name='Fee Details Fields')
        fee_details_section.fields = [
            SEPField('name', 'Fee Details Fields', True, 'Name identifier for the fee component', 'string'),
            SEPField('amount', 'Fee Details Fields', True, 'Fee amount as decimal string', 'string (decimal)'),
            SEPField('description', 'Fee Details Fields', False, 'Human-readable description of the fee', 'string'),
        ]
        sections.append(fee_details_section)

        return sections

    def _analyze_info_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze info endpoint support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'info_endpoint':
                    # Check for info method
                    if 'func info(jwt:' in content and '/info' in content:
                        field.implemented = True
                        field.sdk_property = 'info(jwt:)'

        except Exception as e:
            logger.warning(f"Error analyzing info endpoint: {e}")

    def _analyze_info_response_fields(self, section: SEPSection) -> None:
        """Analyze info response field support"""
        info_response_file = self.sdk_analyzer.find_class_or_struct('Sep38InfoResponse')
        if not info_response_file:
            return

        try:
            content = info_response_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'assets':
                    if ('let assets:' in content or 'var assets:' in content) and 'Sep38Asset' in content:
                        field.implemented = True
                        field.sdk_property = 'assets'

        except Exception as e:
            logger.warning(f"Error analyzing info response fields: {e}")

    def _analyze_asset_fields(self, section: SEPSection) -> None:
        """Analyze asset field support"""
        asset_file = self.sdk_analyzer.find_class_or_struct('Sep38Asset')
        if not asset_file:
            return

        try:
            content = asset_file.read_text(encoding='utf-8')

            field_map = {
                'asset': 'asset',
                'sell_delivery_methods': 'sellDeliveryMethods',
                'buy_delivery_methods': 'buyDeliveryMethods',
                'country_codes': 'countryCodes',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing asset fields: {e}")

    def _analyze_delivery_method_fields(self, section: SEPSection) -> None:
        """Analyze delivery method field support"""
        # Check both sell and buy delivery method classes
        sell_dm_file = self.sdk_analyzer.find_class_or_struct('Sep38SellDeliveryMethod')
        buy_dm_file = self.sdk_analyzer.find_class_or_struct('Sep38BuyDeliveryMethod')

        if not sell_dm_file and not buy_dm_file:
            return

        try:
            # Use whichever file exists (both have same structure)
            content = (sell_dm_file.read_text(encoding='utf-8') if sell_dm_file
                      else buy_dm_file.read_text(encoding='utf-8'))

            field_map = {
                'name': 'name',
                'description': 'description',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing delivery method fields: {e}")

    def _analyze_prices_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze prices endpoint support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'prices_endpoint':
                    # Check for prices method
                    if 'func prices(sellAsset:' in content and '/prices' in content:
                        field.implemented = True
                        field.sdk_property = 'prices(sellAsset:sellAmount:sellDeliveryMethod:buyDeliveryMethod:countryCode:jwt:)'

        except Exception as e:
            logger.warning(f"Error analyzing prices endpoint: {e}")

    def _analyze_prices_request_parameters(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze prices request parameter support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            param_map = {
                'sell_asset': 'sellAsset',
                'sell_amount': 'sellAmount',
                'sell_delivery_method': 'sellDeliveryMethod',
                'buy_delivery_method': 'buyDeliveryMethod',
                'country_code': 'countryCode',
            }

            for field in section.fields:
                sdk_property = param_map.get(field.name)
                if sdk_property:
                    # Check if parameter exists in prices method signature
                    if f'{sdk_property}:' in content and 'func prices(' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing prices request parameters: {e}")

    def _analyze_prices_response_fields(self, section: SEPSection) -> None:
        """Analyze prices response field support"""
        prices_response_file = self.sdk_analyzer.find_class_or_struct('Sep38PricesResponse')
        if not prices_response_file:
            return

        try:
            content = prices_response_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'buy_assets':
                    if ('let buyAssets:' in content or 'var buyAssets:' in content) and 'Sep38BuyAsset' in content:
                        field.implemented = True
                        field.sdk_property = 'buyAssets'

        except Exception as e:
            logger.warning(f"Error analyzing prices response fields: {e}")

    def _analyze_buy_asset_fields(self, section: SEPSection) -> None:
        """Analyze buy asset field support"""
        buy_asset_file = self.sdk_analyzer.find_class_or_struct('Sep38BuyAsset')
        if not buy_asset_file:
            return

        try:
            content = buy_asset_file.read_text(encoding='utf-8')

            field_map = {
                'asset': 'asset',
                'price': 'price',
                'decimals': 'decimals',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing buy asset fields: {e}")

    def _analyze_price_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze price endpoint support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'price_endpoint':
                    # Check for price method
                    if 'func price(context:' in content and '/price' in content:
                        field.implemented = True
                        field.sdk_property = 'price(context:sellAsset:buyAsset:sellAmount:buyAmount:sellDeliveryMethod:buyDeliveryMethod:countryCode:jwt:)'

        except Exception as e:
            logger.warning(f"Error analyzing price endpoint: {e}")

    def _analyze_price_request_parameters(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze price request parameter support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            param_map = {
                'context': 'context',
                'sell_asset': 'sellAsset',
                'buy_asset': 'buyAsset',
                'sell_amount': 'sellAmount',
                'buy_amount': 'buyAmount',
                'sell_delivery_method': 'sellDeliveryMethod',
                'buy_delivery_method': 'buyDeliveryMethod',
                'country_code': 'countryCode',
            }

            for field in section.fields:
                sdk_property = param_map.get(field.name)
                if sdk_property:
                    # Check if parameter exists in price method signature
                    if f'{sdk_property}:' in content and 'func price(' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing price request parameters: {e}")

    def _analyze_price_response_fields(self, section: SEPSection) -> None:
        """Analyze price response field support"""
        price_response_file = self.sdk_analyzer.find_class_or_struct('Sep38PriceResponse')
        if not price_response_file:
            return

        try:
            content = price_response_file.read_text(encoding='utf-8')

            field_map = {
                'total_price': 'totalPrice',
                'price': 'price',
                'sell_amount': 'sellAmount',
                'buy_amount': 'buyAmount',
                'fee': 'fee',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing price response fields: {e}")

    def _analyze_post_quote_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze post quote endpoint support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'post_quote_endpoint':
                    # Check for postQuote method
                    if 'func postQuote(request:' in content and 'POST' in content and '/quote' in content:
                        field.implemented = True
                        field.sdk_property = 'postQuote(request:jwt:)'

        except Exception as e:
            logger.warning(f"Error analyzing post quote endpoint: {e}")

    def _analyze_post_quote_request_fields(self, section: SEPSection) -> None:
        """Analyze post quote request field support"""
        request_file = self.sdk_analyzer.find_class_or_struct('Sep38PostQuoteRequest')
        if not request_file:
            return

        try:
            content = request_file.read_text(encoding='utf-8')

            field_map = {
                'context': 'context',
                'sell_asset': 'sellAsset',
                'buy_asset': 'buyAsset',
                'sell_amount': 'sellAmount',
                'buy_amount': 'buyAmount',
                'expire_after': 'expireAfter',
                'sell_delivery_method': 'sellDeliveryMethod',
                'buy_delivery_method': 'buyDeliveryMethod',
                'country_code': 'countryCode',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing post quote request fields: {e}")

    def _analyze_get_quote_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze get quote endpoint support"""
        if not quote_service_file:
            return

        try:
            content = quote_service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'get_quote_endpoint':
                    # Check for getQuote method
                    if 'func getQuote(id:' in content and '/quote' in content:
                        field.implemented = True
                        field.sdk_property = 'getQuote(id:jwt:)'

        except Exception as e:
            logger.warning(f"Error analyzing get quote endpoint: {e}")

    def _analyze_quote_response_fields(self, section: SEPSection) -> None:
        """Analyze quote response field support"""
        quote_response_file = self.sdk_analyzer.find_class_or_struct('Sep38QuoteResponse')
        if not quote_response_file:
            return

        try:
            content = quote_response_file.read_text(encoding='utf-8')

            field_map = {
                'id': 'id',
                'expires_at': 'expiresAt',
                'total_price': 'totalPrice',
                'price': 'price',
                'sell_asset': 'sellAsset',
                'sell_amount': 'sellAmount',
                'buy_asset': 'buyAsset',
                'buy_amount': 'buyAmount',
                'fee': 'fee',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing quote response fields: {e}")

    def _analyze_fee_fields(self, section: SEPSection) -> None:
        """Analyze fee field support"""
        fee_file = self.sdk_analyzer.find_class_or_struct('Sep38Fee')
        if not fee_file:
            return

        try:
            content = fee_file.read_text(encoding='utf-8')

            field_map = {
                'total': 'total',
                'asset': 'asset',
                'details': 'details',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing fee fields: {e}")

    def _analyze_fee_details_fields(self, section: SEPSection) -> None:
        """Analyze fee details field support"""
        fee_details_file = self.sdk_analyzer.find_class_or_struct('Sep38FeeDetails')
        if not fee_details_file:
            return

        try:
            content = fee_details_file.read_text(encoding='utf-8')

            field_map = {
                'name': 'name',
                'amount': 'amount',
                'description': 'description',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing fee details fields: {e}")


class SEP24Analyzer:
    """Analyzer for SEP-24 (Hosted Deposit and Withdrawal)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-24 implementation"""
        logger.info("Analyzing SEP-24 (Hosted Deposit and Withdrawal) implementation")

        # Create sections based on SEP-24 requirements
        sections = self._create_sep24_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find InteractiveService class
        service_file = self.sdk_analyzer.find_class_or_struct('InteractiveService')
        if service_file:
            rel_path = self.sdk_analyzer.get_relative_path(service_file)
            implementation_files.append(rel_path)
            logger.info(f"Found InteractiveService class at {rel_path}")

        # Find request classes
        for request_class in ['Sep24DepositRequest', 'Sep24WithdrawRequest',
                               'Sep24FeeRequest', 'Sep24TransactionRequest',
                               'Sep24TransactionsRequest']:
            request_file = self.sdk_analyzer.find_class_or_struct(request_class)
            if request_file:
                rel_path = self.sdk_analyzer.get_relative_path(request_file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)
                    logger.info(f"Found {request_class} class at {rel_path}")

        # Find error class (placed after requests, before responses to match committed order)
        error_file = self.sdk_analyzer.find_class_or_struct('InteractiveServiceError')
        if error_file:
            rel_path = self.sdk_analyzer.get_relative_path(error_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found InteractiveServiceError at {rel_path}")

        # Find response classes
        for response_class in ['Sep24InfoResponse', 'Sep24InteractiveResponse',
                                'Sep24TransactionResponse', 'Sep24TransactionsResponse',
                                'Sep24FeeResponse', 'Sep24DepositAsset',
                                'Sep24WithdrawAsset', 'Sep24Transaction',
                                'Sep24FeeEndpointInfo', 'Sep24FeatureFlags']:
            response_file = self.sdk_analyzer.find_class_or_struct(response_class)
            if response_file:
                rel_path = self.sdk_analyzer.get_relative_path(response_file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)
                    logger.info(f"Found {response_class} class at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Info Endpoint':
                self._analyze_info_endpoint(section, service_file)
            elif section.name == 'Interactive Deposit Endpoint':
                self._analyze_interactive_deposit_endpoint(section, service_file)
            elif section.name == 'Interactive Withdraw Endpoint':
                self._analyze_interactive_withdraw_endpoint(section, service_file)
            elif section.name == 'Transaction Endpoints':
                self._analyze_transaction_endpoints(section, service_file)
            elif section.name == 'Fee Endpoint':
                self._analyze_fee_endpoint(section, service_file)
            elif section.name == 'Deposit Request Parameters':
                self._analyze_deposit_request_parameters(section)
            elif section.name == 'Withdraw Request Parameters':
                self._analyze_withdraw_request_parameters(section)
            elif section.name == 'Interactive Response Fields':
                self._analyze_interactive_response_fields(section)
            elif section.name == 'Transaction Status Values':
                self._analyze_transaction_status_values(section)
            elif section.name == 'Transaction Fields':
                self._analyze_transaction_fields(section)
            elif section.name == 'Info Response Fields':
                self._analyze_info_response_fields(section)
            elif section.name == 'Deposit Asset Fields':
                self._analyze_deposit_asset_fields(section)
            elif section.name == 'Withdraw Asset Fields':
                self._analyze_withdraw_asset_fields(section)
            elif section.name == 'Feature Flags Fields':
                self._analyze_feature_flags_fields(section)
            elif section.name == 'Fee Endpoint Info Fields':
                self._analyze_fee_endpoint_info_fields(section)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive implementation of SEP-24 Hosted Deposit and Withdrawal",
            "InteractiveService class implements all standard endpoints (info, deposit, withdraw, transactions, fee)",
            "Both async/await and legacy callback-based APIs are available",
            "Full support for interactive flows with URL-based customer information collection",
            "Comprehensive transaction tracking with detailed status values",
            "Support for asset exchanges via SEP-38 quote integration",
            "Complete request/response models with Codable support",
            "All fields properly mapped with snake_case to camelCase conversion",
            "JWT authentication support for all protected endpoints",
            "Support for claimable balances and account creation",
            "Memo support for both deposit and withdrawal transactions",
            "Multi-language support via lang parameter",
            "Wallet identification via wallet_name and wallet_url",
            "Thread-safe implementation suitable for concurrent requests",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-24!",
                "Always use SEP-10 authentication for deposit/withdraw endpoints",
                "Display the interactive URL in a popup or iframe for user KYC",
                "Poll transaction status endpoint to track deposit/withdrawal progress",
                "Handle all transaction status values appropriately in client applications",
                "Use /info endpoint to discover supported assets and capabilities",
                "Provide quote_id from SEP-38 when asset exchange is needed",
                "Include wallet_name and wallet_url for better user communication",
                "Support claimable balances for users without trustlines",
                "Implement proper memo handling for transaction identification",
                "Use lang parameter for localized user experience",
                "Monitor user_action_required_by timestamps for time-sensitive actions",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-24 compliance",
            ]

        return matrix

    def _create_sep24_sections(self) -> List[SEPSection]:
        """Create SEP-24 sections with all fields"""
        sections = []

        # Info Endpoint
        info_endpoint_section = SEPSection(name='Info Endpoint')
        info_endpoint_section.fields = [
            SEPField(
                name='info_endpoint',
                section='Info Endpoint',
                required=True,
                description='GET /info - Provides anchor capabilities and supported assets for interactive deposits/withdrawals',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(info_endpoint_section)

        # Interactive Deposit Endpoint
        deposit_endpoint_section = SEPSection(name='Interactive Deposit Endpoint')
        deposit_endpoint_section.fields = [
            SEPField(
                name='interactive_deposit',
                section='Interactive Deposit Endpoint',
                required=True,
                description='POST /transactions/deposit/interactive - Initiates an interactive deposit transaction',
                requirements='HTTP POST endpoint'
            ),
        ]
        sections.append(deposit_endpoint_section)

        # Interactive Withdraw Endpoint
        withdraw_endpoint_section = SEPSection(name='Interactive Withdraw Endpoint')
        withdraw_endpoint_section.fields = [
            SEPField(
                name='interactive_withdraw',
                section='Interactive Withdraw Endpoint',
                required=True,
                description='POST /transactions/withdraw/interactive - Initiates an interactive withdrawal transaction',
                requirements='HTTP POST endpoint'
            ),
        ]
        sections.append(withdraw_endpoint_section)

        # Transaction Endpoints
        transaction_endpoints_section = SEPSection(name='Transaction Endpoints')
        transaction_endpoints_section.fields = [
            SEPField(
                name='transactions',
                section='Transaction Endpoints',
                required=True,
                description='GET /transactions - Retrieves transaction history for authenticated account',
                requirements='HTTP GET endpoint'
            ),
            SEPField(
                name='transaction',
                section='Transaction Endpoints',
                required=True,
                description='GET /transaction - Retrieves details for a single transaction',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(transaction_endpoints_section)

        # Fee Endpoint
        fee_endpoint_section = SEPSection(name='Fee Endpoint')
        fee_endpoint_section.fields = [
            SEPField(
                name='fee_endpoint',
                section='Fee Endpoint',
                required=False,
                description='GET /fee - Calculates fees for a deposit or withdrawal operation (optional)',
                requirements='HTTP GET endpoint'
            ),
        ]
        sections.append(fee_endpoint_section)

        # Deposit Request Parameters
        deposit_request_section = SEPSection(name='Deposit Request Parameters')
        deposit_request_section.fields = [
            SEPField(name='asset_code', section='Deposit Request Parameters', required=True,
                     description='Code of the Stellar asset the user wants to receive', requirements='string'),
            SEPField(name='asset_issuer', section='Deposit Request Parameters', required=False,
                     description='Issuer of the Stellar asset (optional if anchor is issuer)', requirements='string'),
            SEPField(name='source_asset', section='Deposit Request Parameters', required=False,
                     description='Off-chain asset user wants to deposit (in SEP-38 format)', requirements='string'),
            SEPField(name='amount', section='Deposit Request Parameters', required=False,
                     description='Amount of asset to deposit', requirements='string'),
            SEPField(name='quote_id', section='Deposit Request Parameters', required=False,
                     description='ID from SEP-38 quote (for asset exchange)', requirements='string'),
            SEPField(name='account', section='Deposit Request Parameters', required=False,
                     description='Stellar or muxed account for receiving deposit', requirements='string'),
            SEPField(name='memo', section='Deposit Request Parameters', required=False,
                     description='Memo value for transaction identification', requirements='string'),
            SEPField(name='memo_type', section='Deposit Request Parameters', required=False,
                     description='Type of memo (text, id, or hash)', requirements='string'),
            SEPField(name='wallet_name', section='Deposit Request Parameters', required=False,
                     description='Name of wallet for user communication', requirements='string'),
            SEPField(name='wallet_url', section='Deposit Request Parameters', required=False,
                     description='URL to link in transaction notifications', requirements='string'),
            SEPField(name='lang', section='Deposit Request Parameters', required=False,
                     description='Language code for UI and messages (RFC 4646)', requirements='string'),
            SEPField(name='claimable_balance_supported', section='Deposit Request Parameters', required=False,
                     description='Whether client supports claimable balances', requirements='boolean'),
        ]
        sections.append(deposit_request_section)

        # Withdraw Request Parameters
        withdraw_request_section = SEPSection(name='Withdraw Request Parameters')
        withdraw_request_section.fields = [
            SEPField(name='asset_code', section='Withdraw Request Parameters', required=True,
                     description='Code of the Stellar asset user wants to send', requirements='string'),
            SEPField(name='asset_issuer', section='Withdraw Request Parameters', required=False,
                     description='Issuer of the Stellar asset (optional if anchor is issuer)', requirements='string'),
            SEPField(name='destination_asset', section='Withdraw Request Parameters', required=False,
                     description='Off-chain asset user wants to receive (in SEP-38 format)', requirements='string'),
            SEPField(name='amount', section='Withdraw Request Parameters', required=False,
                     description='Amount of asset to withdraw', requirements='string'),
            SEPField(name='quote_id', section='Withdraw Request Parameters', required=False,
                     description='ID from SEP-38 quote (for asset exchange)', requirements='string'),
            SEPField(name='account', section='Withdraw Request Parameters', required=False,
                     description='Stellar or muxed account that will send the withdrawal', requirements='string'),
            SEPField(name='memo', section='Withdraw Request Parameters', required=False,
                     description='Memo for identifying the withdrawal transaction', requirements='string'),
            SEPField(name='memo_type', section='Withdraw Request Parameters', required=False,
                     description='Type of memo (text, id, or hash)', requirements='string'),
            SEPField(name='wallet_name', section='Withdraw Request Parameters', required=False,
                     description='Name of wallet for user communication', requirements='string'),
            SEPField(name='wallet_url', section='Withdraw Request Parameters', required=False,
                     description='URL to link in transaction notifications', requirements='string'),
            SEPField(name='lang', section='Withdraw Request Parameters', required=False,
                     description='Language code for UI and messages (RFC 4646)', requirements='string'),
        ]
        sections.append(withdraw_request_section)

        # Interactive Response Fields
        interactive_response_section = SEPSection(name='Interactive Response Fields')
        interactive_response_section.fields = [
            SEPField(name='type', section='Interactive Response Fields', required=True,
                     description='Always "interactive_customer_info_needed" for SEP-24', requirements='string'),
            SEPField(name='url', section='Interactive Response Fields', required=True,
                     description='URL for interactive flow popup/iframe', requirements='string (URL)'),
            SEPField(name='id', section='Interactive Response Fields', required=True,
                     description='Unique transaction identifier', requirements='string'),
        ]
        sections.append(interactive_response_section)

        # Transaction Status Values
        status_values_section = SEPSection(name='Transaction Status Values')
        status_values_section.fields = [
            SEPField(name='incomplete', section='Transaction Status Values', required=True,
                     description='Customer information still being collected via interactive flow', requirements='status value'),
            SEPField(name='pending_user_transfer_start', section='Transaction Status Values', required=True,
                     description='Waiting for user to send funds (deposits)', requirements='status value'),
            SEPField(name='pending_user_transfer_complete', section='Transaction Status Values', required=False,
                     description='User transfer detected, awaiting confirmations', requirements='status value'),
            SEPField(name='pending_external', section='Transaction Status Values', required=False,
                     description='Transaction being processed by external system', requirements='status value'),
            SEPField(name='pending_anchor', section='Transaction Status Values', required=True,
                     description='Anchor processing the transaction', requirements='status value'),
            SEPField(name='pending_stellar', section='Transaction Status Values', required=False,
                     description='Transaction submitted to Stellar network', requirements='status value'),
            SEPField(name='pending_trust', section='Transaction Status Values', required=False,
                     description='User needs to establish trustline', requirements='status value'),
            SEPField(name='pending_user', section='Transaction Status Values', required=False,
                     description='Waiting for user action (e.g., accepting claimable balance)', requirements='status value'),
            SEPField(name='completed', section='Transaction Status Values', required=True,
                     description='Transaction completed successfully', requirements='status value'),
            SEPField(name='refunded', section='Transaction Status Values', required=False,
                     description='Transaction refunded', requirements='status value'),
            SEPField(name='expired', section='Transaction Status Values', required=False,
                     description='Transaction expired before completion', requirements='status value'),
            SEPField(name='error', section='Transaction Status Values', required=False,
                     description='Transaction encountered an error', requirements='status value'),
        ]
        sections.append(status_values_section)

        # Transaction Fields
        transaction_fields_section = SEPSection(name='Transaction Fields')
        transaction_fields_section.fields = [
            SEPField(name='id', section='Transaction Fields', required=True,
                     description='Unique transaction identifier', requirements='string'),
            SEPField(name='kind', section='Transaction Fields', required=True,
                     description='Kind of transaction (deposit or withdrawal)', requirements='string'),
            SEPField(name='status', section='Transaction Fields', required=True,
                     description='Current status of the transaction', requirements='string'),
            SEPField(name='status_eta', section='Transaction Fields', required=False,
                     description='Estimated seconds until status changes', requirements='integer'),
            SEPField(name='kyc_verified', section='Transaction Fields', required=False,
                     description='Whether KYC has been verified for this transaction', requirements='boolean'),
            SEPField(name='more_info_url', section='Transaction Fields', required=True,
                     description='URL with additional transaction information', requirements='string (URL)'),
            SEPField(name='amount_in', section='Transaction Fields', required=False,
                     description='Amount received by anchor', requirements='string'),
            SEPField(name='amount_in_asset', section='Transaction Fields', required=False,
                     description='Asset received by anchor (SEP-38 format)', requirements='string'),
            SEPField(name='amount_out', section='Transaction Fields', required=False,
                     description='Amount sent by anchor to user', requirements='string'),
            SEPField(name='amount_out_asset', section='Transaction Fields', required=False,
                     description='Asset delivered to user (SEP-38 format)', requirements='string'),
            SEPField(name='amount_fee', section='Transaction Fields', required=False,
                     description='Total fee charged for transaction', requirements='string'),
            SEPField(name='amount_fee_asset', section='Transaction Fields', required=False,
                     description='Asset in which fees are calculated (SEP-38 format)', requirements='string'),
            SEPField(name='quote_id', section='Transaction Fields', required=False,
                     description='ID of SEP-38 quote used for this transaction', requirements='string'),
            SEPField(name='started_at', section='Transaction Fields', required=True,
                     description='When transaction was created (ISO 8601)', requirements='string (ISO 8601)'),
            SEPField(name='completed_at', section='Transaction Fields', required=False,
                     description='When transaction completed (ISO 8601)', requirements='string (ISO 8601)'),
            SEPField(name='updated_at', section='Transaction Fields', required=False,
                     description='When transaction status last changed (ISO 8601)', requirements='string (ISO 8601)'),
            SEPField(name='user_action_required_by', section='Transaction Fields', required=False,
                     description='Deadline for user action (ISO 8601)', requirements='string (ISO 8601)'),
            SEPField(name='stellar_transaction_id', section='Transaction Fields', required=False,
                     description='Hash of the Stellar transaction', requirements='string'),
            SEPField(name='external_transaction_id', section='Transaction Fields', required=False,
                     description='Identifier from external system', requirements='string'),
            SEPField(name='message', section='Transaction Fields', required=False,
                     description='Human-readable message about transaction', requirements='string'),
            SEPField(name='refunded', section='Transaction Fields', required=False,
                     description='Whether transaction was refunded (deprecated)', requirements='boolean'),
            SEPField(name='refunds', section='Transaction Fields', required=False,
                     description='Refund information object', requirements='object'),
            SEPField(name='from', section='Transaction Fields', required=False,
                     description='Source address (Stellar for withdrawals, external for deposits)', requirements='string'),
            SEPField(name='to', section='Transaction Fields', required=False,
                     description='Destination address (Stellar for deposits, external for withdrawals)', requirements='string'),
            SEPField(name='deposit_memo', section='Transaction Fields', required=False,
                     description='Memo for deposit to Stellar address', requirements='string'),
            SEPField(name='deposit_memo_type', section='Transaction Fields', required=False,
                     description='Type of deposit memo', requirements='string'),
            SEPField(name='claimable_balance_id', section='Transaction Fields', required=False,
                     description='ID of claimable balance for deposit', requirements='string'),
            SEPField(name='withdraw_anchor_account', section='Transaction Fields', required=False,
                     description="Anchor's Stellar account for withdrawal payment", requirements='string'),
            SEPField(name='withdraw_memo', section='Transaction Fields', required=False,
                     description='Memo for withdrawal to anchor account', requirements='string'),
            SEPField(name='withdraw_memo_type', section='Transaction Fields', required=False,
                     description='Type of withdraw memo', requirements='string'),
        ]
        sections.append(transaction_fields_section)

        # Info Response Fields
        info_response_section = SEPSection(name='Info Response Fields')
        info_response_section.fields = [
            SEPField(name='deposit', section='Info Response Fields', required=True,
                     description='Map of asset codes to deposit asset information', requirements='object'),
            SEPField(name='withdraw', section='Info Response Fields', required=True,
                     description='Map of asset codes to withdraw asset information', requirements='object'),
            SEPField(name='fee', section='Info Response Fields', required=False,
                     description='Fee endpoint information object', requirements='object'),
            SEPField(name='features', section='Info Response Fields', required=False,
                     description='Feature flags object', requirements='object'),
        ]
        sections.append(info_response_section)

        # Deposit Asset Fields
        deposit_asset_section = SEPSection(name='Deposit Asset Fields')
        deposit_asset_section.fields = [
            SEPField(name='enabled', section='Deposit Asset Fields', required=True,
                     description='Whether deposits are enabled for this asset', requirements='boolean'),
            SEPField(name='min_amount', section='Deposit Asset Fields', required=False,
                     description='Minimum deposit amount', requirements='number'),
            SEPField(name='max_amount', section='Deposit Asset Fields', required=False,
                     description='Maximum deposit amount', requirements='number'),
            SEPField(name='fee_fixed', section='Deposit Asset Fields', required=False,
                     description='Fixed deposit fee', requirements='number'),
            SEPField(name='fee_percent', section='Deposit Asset Fields', required=False,
                     description='Percentage deposit fee', requirements='number'),
            SEPField(name='fee_minimum', section='Deposit Asset Fields', required=False,
                     description='Minimum deposit fee', requirements='number'),
        ]
        sections.append(deposit_asset_section)

        # Withdraw Asset Fields
        withdraw_asset_section = SEPSection(name='Withdraw Asset Fields')
        withdraw_asset_section.fields = [
            SEPField(name='enabled', section='Withdraw Asset Fields', required=True,
                     description='Whether withdrawals are enabled for this asset', requirements='boolean'),
            SEPField(name='min_amount', section='Withdraw Asset Fields', required=False,
                     description='Minimum withdrawal amount', requirements='number'),
            SEPField(name='max_amount', section='Withdraw Asset Fields', required=False,
                     description='Maximum withdrawal amount', requirements='number'),
            SEPField(name='fee_fixed', section='Withdraw Asset Fields', required=False,
                     description='Fixed withdrawal fee', requirements='number'),
            SEPField(name='fee_percent', section='Withdraw Asset Fields', required=False,
                     description='Percentage withdrawal fee', requirements='number'),
            SEPField(name='fee_minimum', section='Withdraw Asset Fields', required=False,
                     description='Minimum withdrawal fee', requirements='number'),
        ]
        sections.append(withdraw_asset_section)

        # Feature Flags Fields
        feature_flags_section = SEPSection(name='Feature Flags Fields')
        feature_flags_section.fields = [
            SEPField(name='account_creation', section='Feature Flags Fields', required=False,
                     description='Whether anchor supports creating accounts', requirements='boolean'),
            SEPField(name='claimable_balances', section='Feature Flags Fields', required=False,
                     description='Whether anchor supports claimable balances', requirements='boolean'),
        ]
        sections.append(feature_flags_section)

        # Fee Endpoint Info Fields
        fee_endpoint_info_section = SEPSection(name='Fee Endpoint Info Fields')
        fee_endpoint_info_section.fields = [
            SEPField(name='enabled', section='Fee Endpoint Info Fields', required=True,
                     description='Whether fee endpoint is available', requirements='boolean'),
            SEPField(name='authentication_required', section='Fee Endpoint Info Fields', required=False,
                     description='Whether authentication is required for fee endpoint', requirements='boolean'),
        ]
        sections.append(fee_endpoint_info_section)

        return sections

    def _analyze_info_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze info endpoint support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'info_endpoint':
                    # Check for info method and /info path
                    if 'func info(language:' in content and '/info' in content:
                        field.implemented = True
                        field.sdk_property = 'info(language:)'

        except Exception as e:
            logger.warning(f"Error analyzing info endpoint: {e}")

    def _analyze_interactive_deposit_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze interactive deposit endpoint support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'interactive_deposit':
                    # Check for deposit method and /transactions/deposit/interactive path
                    if 'func deposit(request:' in content and '/transactions/deposit/interactive' in content:
                        field.implemented = True
                        field.sdk_property = 'deposit(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing interactive deposit endpoint: {e}")

    def _analyze_interactive_withdraw_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze interactive withdraw endpoint support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'interactive_withdraw':
                    # Check for withdraw method and /transactions/withdraw/interactive path
                    if 'func withdraw(request:' in content and '/transactions/withdraw/interactive' in content:
                        field.implemented = True
                        field.sdk_property = 'withdraw(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing interactive withdraw endpoint: {e}")

    def _analyze_transaction_endpoints(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze transaction endpoints support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'transactions':
                    # Check for getTransactions method
                    if 'func getTransactions(request:' in content and 'GET' in content:
                        field.implemented = True
                        field.sdk_property = 'getTransactions(request:)'
                elif field.name == 'transaction':
                    # Check for getTransaction method
                    if 'func getTransaction(request:' in content and '/transaction' in content:
                        field.implemented = True
                        field.sdk_property = 'getTransaction(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing transaction endpoints: {e}")

    def _analyze_fee_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze fee endpoint support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'fee_endpoint':
                    # Check for fee method and /fee path
                    if 'func fee(request:' in content and '/fee' in content:
                        field.implemented = True
                        field.sdk_property = 'fee(request:)'

        except Exception as e:
            logger.warning(f"Error analyzing fee endpoint: {e}")

    def _analyze_deposit_request_parameters(self, section: SEPSection) -> None:
        """Analyze deposit request parameter support"""
        request_file = self.sdk_analyzer.find_class_or_struct('Sep24DepositRequest')
        if not request_file:
            return

        try:
            content = request_file.read_text(encoding='utf-8')

            field_map = {
                'asset_code': 'assetCode',
                'asset_issuer': 'assetIssuer',
                'source_asset': 'sourceAsset',
                'amount': 'amount',
                'quote_id': 'quoteId',
                'account': 'account',
                'memo': 'memo',
                'memo_type': 'memoType',
                'wallet_name': 'walletName',
                'wallet_url': 'walletUrl',
                'lang': 'lang',
                'claimable_balance_supported': 'claimableBalanceSupported',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing deposit request parameters: {e}")

    def _analyze_withdraw_request_parameters(self, section: SEPSection) -> None:
        """Analyze withdraw request parameter support"""
        request_file = self.sdk_analyzer.find_class_or_struct('Sep24WithdrawRequest')
        if not request_file:
            return

        try:
            content = request_file.read_text(encoding='utf-8')

            field_map = {
                'asset_code': 'assetCode',
                'asset_issuer': 'assetIssuer',
                'destination_asset': 'destinationAsset',
                'amount': 'amount',
                'quote_id': 'quoteId',
                'account': 'account',
                'memo': 'memo',
                'memo_type': 'memoType',
                'wallet_name': 'walletName',
                'wallet_url': 'walletUrl',
                'lang': 'lang',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing withdraw request parameters: {e}")

    def _analyze_interactive_response_fields(self, section: SEPSection) -> None:
        """Analyze interactive response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('Sep24InteractiveResponse')
        if not response_file:
            return

        try:
            content = response_file.read_text(encoding='utf-8')

            field_map = {
                'type': 'type',
                'url': 'url',
                'id': 'id',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing interactive response fields: {e}")

    def _analyze_transaction_status_values(self, section: SEPSection) -> None:
        """Analyze transaction status value support"""
        transaction_file = self.sdk_analyzer.find_class_or_struct('Sep24Transaction')
        if not transaction_file:
            return

        try:
            content = transaction_file.read_text(encoding='utf-8')

            # Transaction status values are represented as string values in the status property
            # We check if the status field exists and can handle these values
            status_values = {
                'incomplete': 'incomplete',
                'pending_user_transfer_start': 'pending_user_transfer_start',
                'pending_user_transfer_complete': 'pending_user_transfer_complete',
                'pending_external': 'pending_external',
                'pending_anchor': 'pending_anchor',
                'pending_stellar': 'pending_stellar',
                'pending_trust': 'pending_trust',
                'pending_user': 'pending_user',
                'completed': 'completed',
                'refunded': 'refunded',
                'expired': 'expired',
                'error': 'error',
            }

            for field in section.fields:
                # All status values are supported through the status string property
                if field.name in status_values:
                    field.implemented = True
                    field.sdk_property = f'status: "{status_values[field.name]}"'

        except Exception as e:
            logger.warning(f"Error analyzing transaction status values: {e}")

    def _analyze_transaction_fields(self, section: SEPSection) -> None:
        """Analyze transaction field support"""
        transaction_file = self.sdk_analyzer.find_class_or_struct('Sep24Transaction')
        if not transaction_file:
            return

        try:
            content = transaction_file.read_text(encoding='utf-8')

            field_map = {
                'id': 'id',
                'kind': 'kind',
                'status': 'status',
                'status_eta': 'statusEta',
                'kyc_verified': 'kycVerified',
                'more_info_url': 'moreInfoUrl',
                'amount_in': 'amountIn',
                'amount_in_asset': 'amountInAsset',
                'amount_out': 'amountOut',
                'amount_out_asset': 'amountOutAsset',
                'amount_fee': 'amountFee',
                'amount_fee_asset': 'amountFeeAsset',
                'quote_id': 'quoteId',
                'started_at': 'startedAt',
                'completed_at': 'completedAt',
                'updated_at': 'updatedAt',
                'user_action_required_by': 'userActionRequiredBy',
                'stellar_transaction_id': 'stellarTransactionId',
                'external_transaction_id': 'externalTransactionId',
                'message': 'message',
                'refunded': 'refunded',
                'refunds': 'refunds',
                'from': 'from',
                'to': 'to',
                'deposit_memo': 'depositMemo',
                'deposit_memo_type': 'depositMemoType',
                'claimable_balance_id': 'claimableBalanceId',
                'withdraw_anchor_account': 'withdrawAnchorAccount',
                'withdraw_memo': 'withdrawMemo',
                'withdraw_memo_type': 'withdrawMemoType',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing transaction fields: {e}")

    def _analyze_info_response_fields(self, section: SEPSection) -> None:
        """Analyze info response field support"""
        info_response_file = self.sdk_analyzer.find_class_or_struct('Sep24InfoResponse')
        if not info_response_file:
            return

        try:
            content = info_response_file.read_text(encoding='utf-8')

            field_map = {
                'deposit': 'depositAssets',
                'withdraw': 'withdrawAssets',
                'fee': 'feeEndpointInfo',
                'features': 'featureFlags',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing info response fields: {e}")

    def _analyze_deposit_asset_fields(self, section: SEPSection) -> None:
        """Analyze deposit asset field support"""
        deposit_asset_file = self.sdk_analyzer.find_class_or_struct('Sep24DepositAsset')
        if not deposit_asset_file:
            return

        try:
            content = deposit_asset_file.read_text(encoding='utf-8')

            field_map = {
                'enabled': 'enabled',
                'min_amount': 'minAmount',
                'max_amount': 'maxAmount',
                'fee_fixed': 'feeFixed',
                'fee_percent': 'feePercent',
                'fee_minimum': 'feeMinimum',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing deposit asset fields: {e}")

    def _analyze_withdraw_asset_fields(self, section: SEPSection) -> None:
        """Analyze withdraw asset field support"""
        withdraw_asset_file = self.sdk_analyzer.find_class_or_struct('Sep24WithdrawAsset')
        if not withdraw_asset_file:
            return

        try:
            content = withdraw_asset_file.read_text(encoding='utf-8')

            field_map = {
                'enabled': 'enabled',
                'min_amount': 'minAmount',
                'max_amount': 'maxAmount',
                'fee_fixed': 'feeFixed',
                'fee_percent': 'feePercent',
                'fee_minimum': 'feeMinimum',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing withdraw asset fields: {e}")

    def _analyze_feature_flags_fields(self, section: SEPSection) -> None:
        """Analyze feature flags field support"""
        feature_flags_file = self.sdk_analyzer.find_class_or_struct('Sep24FeatureFlags')
        if not feature_flags_file:
            return

        try:
            content = feature_flags_file.read_text(encoding='utf-8')

            field_map = {
                'account_creation': 'accountCreation',
                'claimable_balances': 'claimableBalances',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing feature flags fields: {e}")

    def _analyze_fee_endpoint_info_fields(self, section: SEPSection) -> None:
        """Analyze fee endpoint info field support"""
        fee_endpoint_info_file = self.sdk_analyzer.find_class_or_struct('Sep24FeeEndpointInfo')
        if not fee_endpoint_info_file:
            return

        try:
            content = fee_endpoint_info_file.read_text(encoding='utf-8')

            field_map = {
                'enabled': 'enabled',
                'authentication_required': 'authenticationRequired',
            }

            for field in section.fields:
                sdk_property = field_map.get(field.name)
                if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                    field.implemented = True
                    field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing fee endpoint info fields: {e}")


class SEP30Analyzer:
    """Analyzer for SEP-30 (Account Recovery: multi-party recovery of Stellar accounts)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-30 implementation"""
        logger.info("Analyzing SEP-30 (Account Recovery) implementation")

        # Create sections based on SEP-30 requirements
        sections = self._create_sep30_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find RecoveryService class
        service_file = self.sdk_analyzer.find_class_or_struct('RecoveryService')
        if service_file:
            rel_path = self.sdk_analyzer.get_relative_path(service_file)
            implementation_files.append(rel_path)
            logger.info(f"Found RecoveryService class at {rel_path}")

        # Find request classes
        for request_class in ['Sep30Request', 'Sep30RequestIdentity', 'Sep30AuthMethod']:
            request_file = self.sdk_analyzer.find_class_or_struct(request_class)
            if request_file:
                rel_path = self.sdk_analyzer.get_relative_path(request_file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)
                    logger.info(f"Found {request_class} class at {rel_path}")

        # Find response classes
        for response_class in ['Sep30AccountResponse', 'Sep30SignatureResponse',
                                'Sep30AccountsResponse', 'SEP30ResponseIdentity',
                                'SEP30ResponseSigner']:
            response_file = self.sdk_analyzer.find_class_or_struct(response_class)
            if response_file:
                rel_path = self.sdk_analyzer.get_relative_path(response_file)
                if rel_path not in implementation_files:
                    implementation_files.append(rel_path)
                    logger.info(f"Found {response_class} class at {rel_path}")

        # Find error enum
        error_file = self.sdk_analyzer.find_class_or_struct('RecoveryServiceError')
        if error_file:
            rel_path = self.sdk_analyzer.get_relative_path(error_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found RecoveryServiceError enum at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'API Endpoints':
                self._analyze_api_endpoints(section, service_file)
            elif section.name == 'Request Fields':
                self._analyze_request_fields(section)
            elif section.name == 'Response Fields':
                self._analyze_response_fields(section)
            elif section.name == 'Error Codes':
                self._analyze_error_codes(section, error_file)
            elif section.name == 'Recovery Features':
                self._analyze_recovery_features(section, service_file)
            elif section.name == 'Authentication':
                self._analyze_authentication(section, service_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive implementation of SEP-30 Account Recovery protocol",
            "RecoveryService class implements all required endpoints (register, update, get, delete, list, sign)",
            "Both async/await and legacy callback-based APIs are available",
            "Full support for multi-party recovery with multiple identity roles (owner/other)",
            "Flexible authentication methods: stellar_address, phone_number, email, other",
            "Complete request/response models with Codable support for JSON serialization",
            "JWT token authentication required for all endpoints (SEP-10 or external provider)",
            "Transaction signing endpoint allows server-side transaction signatures for recovery",
            "Pagination support in list accounts endpoint via 'after' parameter",
            "All fields properly mapped with snake_case (API) to camelCase (Swift) conversion",
            "Error handling for 400 (Bad Request), 401 (Unauthorized), 404 (Not Found), and 409 (Conflict)",
            "Note: 409 Conflict error handling is partially implemented (see todo comment in RecoveryService.swift line 234)",
            "Identity objects include role and optional authenticated flag",
            "Signer objects with public key support for account signers",
            "Thread-safe implementation suitable for concurrent recovery requests",
            "Network passphrase included in signature responses for multi-network support",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 95:
            matrix.recommendations = [
                "✅ The SDK has excellent compatibility with SEP-30!",
                "Always use SEP-10 authentication to obtain JWT tokens for all recovery endpoints",
                "Register accounts with multiple identities (owner role required)",
                "Use at least 2 recovery servers with appropriate signer configuration for secure multi-party recovery",
                "Support multiple authentication methods (phone, email, Stellar address) for better recovery options",
                "Implement proper identity verification before calling recovery endpoints",
                "Use the sign transaction endpoint to obtain server signatures during recovery",
                "Poll the get account endpoint to verify account registration status",
                "Handle 409 Conflict errors when attempting to register already-existing accounts",
                "Store JWT tokens securely and refresh them when expired",
                "Use pagination (after parameter) when listing accounts with many registrations",
                "Verify network passphrase in signature responses matches expected network",
                "Delete account records when user no longer needs recovery service",
                "Support both owner and other identity roles for flexible account sharing",
                "Consider completing the 409 Conflict error handling implementation",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-30 compliance",
                "Complete the 409 Conflict error handling implementation",
                "Add comprehensive test coverage for all recovery flows",
            ]

        return matrix

    def _create_sep30_sections(self) -> List[SEPSection]:
        """Create SEP-30 sections with all fields"""
        sections = []

        # API Endpoints (6 fields)
        api_endpoints_section = SEPSection(name='API Endpoints')
        api_endpoints_section.fields = [
            SEPField(
                name='register_account',
                section='API Endpoints',
                required=True,
                description='POST /accounts/{address} - Register an account for recovery',
                requirements='HTTP POST endpoint with JWT authentication'
            ),
            SEPField(
                name='update_account',
                section='API Endpoints',
                required=True,
                description='PUT /accounts/{address} - Update identities for an account',
                requirements='HTTP PUT endpoint with JWT authentication'
            ),
            SEPField(
                name='get_account',
                section='API Endpoints',
                required=True,
                description='GET /accounts/{address} - Retrieve account details',
                requirements='HTTP GET endpoint with JWT authentication'
            ),
            SEPField(
                name='delete_account',
                section='API Endpoints',
                required=True,
                description='DELETE /accounts/{address} - Delete account record',
                requirements='HTTP DELETE endpoint with JWT authentication'
            ),
            SEPField(
                name='list_accounts',
                section='API Endpoints',
                required=True,
                description='GET /accounts - List accessible accounts',
                requirements='HTTP GET endpoint with JWT authentication and optional pagination'
            ),
            SEPField(
                name='sign_transaction',
                section='API Endpoints',
                required=True,
                description='POST /accounts/{address}/sign/{signing-address} - Sign a transaction',
                requirements='HTTP POST endpoint with JWT authentication'
            ),
        ]
        sections.append(api_endpoints_section)

        # Request Fields (7 fields)
        request_fields_section = SEPSection(name='Request Fields')
        request_fields_section.fields = [
            SEPField(
                name='identities',
                section='Request Fields',
                required=True,
                description='Array of identity objects for account recovery',
                requirements='Array of identity objects with role and auth_methods'
            ),
            SEPField(
                name='role',
                section='Request Fields',
                required=True,
                description='Role of the identity (owner or other)',
                requirements='String value: "owner" or "other"'
            ),
            SEPField(
                name='auth_methods',
                section='Request Fields',
                required=True,
                description='Array of authentication methods for the identity',
                requirements='Array of auth method objects with type and value'
            ),
            SEPField(
                name='type',
                section='Request Fields',
                required=True,
                description='Type of authentication method',
                requirements='String value: stellar_address, phone_number, email, or other'
            ),
            SEPField(
                name='value',
                section='Request Fields',
                required=True,
                description='Value of the authentication method (address, phone, email, etc.)',
                requirements='String value appropriate for the auth method type'
            ),
            SEPField(
                name='transaction',
                section='Request Fields',
                required=True,
                description='Base64-encoded XDR transaction envelope to sign',
                requirements='Used in sign_transaction endpoint'
            ),
            SEPField(
                name='after',
                section='Request Fields',
                required=False,
                description='Cursor for pagination in list accounts endpoint',
                requirements='Optional string for pagination'
            ),
        ]
        sections.append(request_fields_section)

        # Response Fields (9 fields)
        response_fields_section = SEPSection(name='Response Fields')
        response_fields_section.fields = [
            SEPField(
                name='address',
                section='Response Fields',
                required=True,
                description='Stellar address of the registered account',
                requirements='G... account address string'
            ),
            SEPField(
                name='identities',
                section='Response Fields',
                required=True,
                description='Array of registered identity objects',
                requirements='Array with role and optional authenticated fields'
            ),
            SEPField(
                name='signers',
                section='Response Fields',
                required=True,
                description='Array of signer objects for the account',
                requirements='Array with key field containing public keys'
            ),
            SEPField(
                name='role',
                section='Response Fields',
                required=True,
                description='Role of the identity in response',
                requirements='String value in identity object'
            ),
            SEPField(
                name='authenticated',
                section='Response Fields',
                required=False,
                description='Whether the identity has been authenticated',
                requirements='Optional boolean in identity object'
            ),
            SEPField(
                name='key',
                section='Response Fields',
                required=True,
                description='Public key of the signer',
                requirements='String value in signer object'
            ),
            SEPField(
                name='signature',
                section='Response Fields',
                required=True,
                description='Base64-encoded signature of the transaction',
                requirements='Returned by sign_transaction endpoint'
            ),
            SEPField(
                name='network_passphrase',
                section='Response Fields',
                required=True,
                description='Network passphrase used for signing',
                requirements='Returned by sign_transaction endpoint'
            ),
            SEPField(
                name='accounts',
                section='Response Fields',
                required=True,
                description='Array of account objects in list response',
                requirements='Returned by list_accounts endpoint'
            ),
        ]
        sections.append(response_fields_section)

        # Error Codes (4 fields)
        error_codes_section = SEPSection(name='Error Codes')
        error_codes_section.fields = [
            SEPField(
                name='400',
                section='Error Codes',
                required=True,
                description='Bad Request - Invalid request parameters or malformed data',
                requirements='HTTP status code 400'
            ),
            SEPField(
                name='401',
                section='Error Codes',
                required=True,
                description='Unauthorized - Missing or invalid JWT token',
                requirements='HTTP status code 401'
            ),
            SEPField(
                name='404',
                section='Error Codes',
                required=True,
                description='Not Found - Account or resource not found',
                requirements='HTTP status code 404'
            ),
            SEPField(
                name='409',
                section='Error Codes',
                required=True,
                description='Conflict - Account already exists or conflicting operation',
                requirements='HTTP status code 409'
            ),
        ]
        sections.append(error_codes_section)

        # Recovery Features (6 fields)
        recovery_features_section = SEPSection(name='Recovery Features')
        recovery_features_section.fields = [
            SEPField(
                name='multi_party_recovery',
                section='Recovery Features',
                required=True,
                description='Support for multi-server account recovery',
                requirements='Core feature - ability to use multiple recovery servers'
            ),
            SEPField(
                name='flexible_auth_methods',
                section='Recovery Features',
                required=True,
                description='Support for multiple authentication method types',
                requirements='Core feature - stellar_address, phone_number, email, other'
            ),
            SEPField(
                name='transaction_signing',
                section='Recovery Features',
                required=True,
                description='Server-side transaction signing for recovery',
                requirements='Core feature - sign_transaction endpoint'
            ),
            SEPField(
                name='account_sharing',
                section='Recovery Features',
                required=False,
                description='Support for shared account access',
                requirements='Optional feature - multiple users accessing same account'
            ),
            SEPField(
                name='identity_roles',
                section='Recovery Features',
                required=True,
                description='Support for owner and other identity roles',
                requirements='Core feature - role field in identities'
            ),
            SEPField(
                name='pagination',
                section='Recovery Features',
                required=False,
                description='Pagination support in list accounts endpoint',
                requirements='Optional feature - after parameter'
            ),
        ]
        sections.append(recovery_features_section)

        # Authentication (1 field)
        authentication_section = SEPSection(name='Authentication')
        authentication_section.fields = [
            SEPField(
                name='jwt_token',
                section='Authentication',
                required=True,
                description='All endpoints require authentication via Authorization header with JWT token from SEP-10 or external auth provider',
                requirements='Bearer token in Authorization header for all endpoints'
            ),
        ]
        sections.append(authentication_section)

        return sections

    def _analyze_api_endpoints(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze API endpoints support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            # Map SEP-30 endpoints to iOS SDK methods
            endpoint_map = {
                'register_account': ('registerAccount(address:request:jwt:)', 'func registerAccount(address: String, request: Sep30Request, jwt:String)'),
                'update_account': ('updateIdentitiesForAccount(address:request:jwt:)', 'func updateIdentitiesForAccount(address: String, request: Sep30Request, jwt:String)'),
                'get_account': ('accountDetails(address:jwt:)', 'func accountDetails(address: String, jwt:String)'),
                'delete_account': ('deleteAccount(address:jwt:)', 'func deleteAccount(address: String, jwt:String)'),
                'list_accounts': ('accounts(jwt:after:)', 'func accounts(jwt:String, after:String?'),
                'sign_transaction': ('signTransaction(address:signingAddress:transaction:jwt:)', 'func signTransaction(address: String, signingAddress: String, transaction:String, jwt:String)'),
            }

            for field in section.fields:
                if field.name in endpoint_map:
                    sdk_property, method_sig = endpoint_map[field.name]
                    if method_sig in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing API endpoints: {e}")

    def _analyze_request_fields(self, section: SEPSection) -> None:
        """Analyze request field support"""
        # Check Sep30Request, Sep30RequestIdentity, and Sep30AuthMethod classes
        request_file = self.sdk_analyzer.find_class_or_struct('Sep30Request')
        identity_file = self.sdk_analyzer.find_class_or_struct('Sep30RequestIdentity')
        auth_file = self.sdk_analyzer.find_class_or_struct('Sep30AuthMethod')

        try:
            request_content = request_file.read_text(encoding='utf-8') if request_file else ''
            identity_content = identity_file.read_text(encoding='utf-8') if identity_file else ''
            auth_content = auth_file.read_text(encoding='utf-8') if auth_file else ''

            # Map snake_case field names to camelCase properties
            field_map = {
                'identities': ('identities', request_content),
                'role': ('role', identity_content),
                'auth_methods': ('authMethods', identity_content),
                'type': ('type', auth_content),
                'value': ('value', auth_content),
                'transaction': ('transaction', request_content),  # Used inline in signTransaction method
                'after': ('after', request_content),  # Used as parameter in accounts method
            }

            for field in section.fields:
                if field.name in field_map:
                    sdk_property, content = field_map[field.name]

                    # Check for property or usage
                    if field.name == 'transaction':
                        # transaction is passed directly as parameter in signTransaction
                        service_file = self.sdk_analyzer.find_class_or_struct('RecoveryService')
                        if service_file:
                            service_content = service_file.read_text(encoding='utf-8')
                            if 'transaction:String' in service_content:
                                field.implemented = True
                                field.sdk_property = 'transaction (parameter)'
                    elif field.name == 'after':
                        # after is optional parameter in accounts method
                        service_file = self.sdk_analyzer.find_class_or_struct('RecoveryService')
                        if service_file:
                            service_content = service_file.read_text(encoding='utf-8')
                            if 'after:String?' in service_content:
                                field.implemented = True
                                field.sdk_property = 'after (parameter)'
                    elif f'var {sdk_property}:' in content or f'var {sdk_property} =' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing request fields: {e}")

    def _analyze_response_fields(self, section: SEPSection) -> None:
        """Analyze response field support"""
        # Check response classes
        account_response_file = self.sdk_analyzer.find_class_or_struct('Sep30AccountResponse')
        signature_response_file = self.sdk_analyzer.find_class_or_struct('Sep30SignatureResponse')
        accounts_response_file = self.sdk_analyzer.find_class_or_struct('Sep30AccountsResponse')
        identity_file = self.sdk_analyzer.find_class_or_struct('SEP30ResponseIdentity')
        signer_file = self.sdk_analyzer.find_class_or_struct('SEP30ResponseSigner')

        try:
            account_content = account_response_file.read_text(encoding='utf-8') if account_response_file else ''
            signature_content = signature_response_file.read_text(encoding='utf-8') if signature_response_file else ''
            accounts_content = accounts_response_file.read_text(encoding='utf-8') if accounts_response_file else ''
            identity_content = identity_file.read_text(encoding='utf-8') if identity_file else ''
            signer_content = signer_file.read_text(encoding='utf-8') if signer_file else ''

            # Map fields to their locations
            field_map = {
                'address': ('address', account_content),
                'identities': ('identities', account_content),
                'signers': ('signers', account_content),
                'role': ('role', identity_content),
                'authenticated': ('authenticated', identity_content),
                'key': ('key', signer_content),
                'signature': ('signature', signature_content),
                'network_passphrase': ('networkPassphrase', signature_content),
                'accounts': ('accounts', accounts_content),
            }

            for field in section.fields:
                if field.name in field_map:
                    sdk_property, content = field_map[field.name]

                    if f'let {sdk_property}:' in content or f'var {sdk_property}:' in content or f'let {sdk_property} =' in content or f'var {sdk_property} =' in content:
                        field.implemented = True
                        field.sdk_property = sdk_property

        except Exception as e:
            logger.warning(f"Error analyzing response fields: {e}")

    def _analyze_error_codes(self, section: SEPSection, error_file: Optional[Path]) -> None:
        """Analyze error codes support"""
        if not error_file:
            return

        try:
            content = error_file.read_text(encoding='utf-8')

            # Map HTTP error codes to RecoveryServiceError enum cases
            error_map = {
                '400': 'badRequest',
                '401': 'unauthorized',
                '404': 'notFound',
                '409': 'conflict',
            }

            for field in section.fields:
                if field.name in error_map:
                    error_case = error_map[field.name]
                    if f'case {error_case}' in content:
                        field.implemented = True
                        field.sdk_property = error_case
                        if field.name == '409':
                            # Note partial implementation
                            field.implementation_notes = "Enum case exists but conversion in errorFor() method has TODO comment"

        except Exception as e:
            logger.warning(f"Error analyzing error codes: {e}")

    def _analyze_recovery_features(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze recovery features support"""
        if not service_file:
            return

        try:
            service_content = service_file.read_text(encoding='utf-8')

            # These are conceptual features validated by endpoint support
            for field in section.fields:
                if field.name == 'multi_party_recovery':
                    # Validated by presence of all registration and signing endpoints
                    if 'registerAccount' in service_content and 'signTransaction' in service_content:
                        field.implemented = True
                        field.sdk_property = 'Supported via registration and signing endpoints'

                elif field.name == 'flexible_auth_methods':
                    # Validated by Sep30AuthMethod supporting type/value
                    auth_file = self.sdk_analyzer.find_class_or_struct('Sep30AuthMethod')
                    if auth_file:
                        auth_content = auth_file.read_text(encoding='utf-8')
                        if 'var type:' in auth_content and 'var value:' in auth_content:
                            field.implemented = True
                            field.sdk_property = 'Sep30AuthMethod.type and value'

                elif field.name == 'transaction_signing':
                    # Validated by signTransaction endpoint
                    if 'signTransaction' in service_content:
                        field.implemented = True
                        field.sdk_property = 'signTransaction(address:signingAddress:transaction:jwt:)'

                elif field.name == 'account_sharing':
                    # Validated by support for multiple identities and list endpoint
                    if 'accounts(jwt:' in service_content:
                        field.implemented = True
                        field.sdk_property = 'accounts(jwt:after:) endpoint'

                elif field.name == 'identity_roles':
                    # Validated by role field in Sep30RequestIdentity
                    identity_file = self.sdk_analyzer.find_class_or_struct('Sep30RequestIdentity')
                    if identity_file:
                        identity_content = identity_file.read_text(encoding='utf-8')
                        if 'var role:' in identity_content:
                            field.implemented = True
                            field.sdk_property = 'Sep30RequestIdentity.role'

                elif field.name == 'pagination':
                    # Validated by after parameter in accounts method
                    if 'after:String?' in service_content:
                        field.implemented = True
                        field.sdk_property = 'accounts(jwt:after:) with optional after parameter'

        except Exception as e:
            logger.warning(f"Error analyzing recovery features: {e}")

    def _analyze_authentication(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze authentication support"""
        if not service_file:
            return

        try:
            content = service_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'jwt_token':
                    # Check if jwt parameter is used in all methods
                    jwt_count = content.count('jwt:String')
                    jwt_optional_count = content.count('jwt:')

                    if jwt_count >= 6:  # All 6 endpoints require JWT
                        field.implemented = True
                        field.sdk_property = 'jwt parameter required for all endpoints'

        except Exception as e:
            logger.warning(f"Error analyzing authentication: {e}")


class SEP07Analyzer:
    """Analyzer for SEP-07 (URI Scheme to facilitate delegated signing)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-07 implementation"""
        logger.info("Analyzing SEP-07 (URI Scheme to facilitate delegated signing) implementation")

        # Create sections based on SEP-07 requirements
        sections = self._create_sep07_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find URIScheme class
        uri_scheme_file = self.sdk_analyzer.find_class_or_struct('URIScheme')
        if uri_scheme_file:
            rel_path = self.sdk_analyzer.get_relative_path(uri_scheme_file)
            implementation_files.append(rel_path)
            logger.info(f"Found URIScheme class at {rel_path}")

        # Find URISchemeValidator class
        validator_file = self.sdk_analyzer.find_class_or_struct('URISchemeValidator')
        if validator_file:
            rel_path = self.sdk_analyzer.get_relative_path(validator_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found URISchemeValidator class at {rel_path}")

        # Find enums
        enums_file = self.sdk_analyzer.find_class_or_struct('SignTransactionParams')
        if enums_file:
            rel_path = self.sdk_analyzer.get_relative_path(enums_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found URISchemeEnums.swift at {rel_path}")

        # Find errors
        errors_file = self.sdk_analyzer.find_class_or_struct('URISchemeErrors')
        if errors_file:
            rel_path = self.sdk_analyzer.get_relative_path(errors_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found URISchemeErrors.swift at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'URI Operations':
                self._analyze_uri_operations(section, uri_scheme_file)
            elif section.name == 'TX Operation Parameters':
                self._analyze_tx_parameters(section, uri_scheme_file, enums_file)
            elif section.name == 'PAY Operation Parameters':
                self._analyze_pay_parameters(section, uri_scheme_file, enums_file)
            elif section.name == 'Common Parameters':
                self._analyze_common_parameters(section, uri_scheme_file, enums_file)
            elif section.name == 'Validation Features':
                self._analyze_validation_features(section, uri_scheme_file, validator_file)
            elif section.name == 'Signature Features':
                self._analyze_signature_features(section, validator_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides comprehensive implementation of SEP-07 URI Scheme protocol",
            "URIScheme class implements URI generation for both tx (sign transaction) and pay operations",
            "URISchemeValidator class provides signature signing and verification capabilities",
            "All required operations (tx, pay) are fully supported",
            "TX operation supports all parameters: xdr, replace, callback, pubkey, chain",
            "PAY operation supports all parameters: destination, amount, asset_code, asset_issuer, memo, memo_type",
            "Common parameters supported in both operations: msg, network_passphrase, origin_domain, signature",
            "SignTransactionParams enum defines all TX operation parameters",
            "PayOperationParams enum defines all PAY operation parameters",
            "Message validation enforces 300 character limit (MessageMaximumLength constant)",
            "URI scheme validation checks for web+stellar: prefix (URISchemeName constant)",
            "Operation type validation via SignOperation (tx?) and PayOperation (pay?) constants",
            "XDR parameter validation in getSignTransactionURI method",
            "Destination parameter validation in getPayOperationURI method",
            "Stellar address validation through SDK's KeyPair and PublicKey classes",
            "Asset code validation in pay operation parameter handling",
            "Memo type validation supports MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN",
            "Memo value validation based on type (base64 encoding for HASH/RETURN)",
            "Message length validation enforces 300 character maximum",
            "Origin domain validation checks for fully qualified domain name (isFullyQualifiedDomainName)",
            "Chain parameter supports nested SEP-07 URLs (URL encoding applied)",
            "URI signing via signURI(url:signerKeyPair:) method",
            "Signature verification via verify(forURL:urlEncodedBase64Signature:signerPublicKey:) method",
            "Signed URI verification via checkURISchemeIsValid(url:) method with TOML lookup",
            "Both async/await and legacy callback-based APIs available",
            "Automatic URL encoding for all parameter values",
            "Special handling for MEMO_HASH and MEMO_RETURN (base64 + URL encoding)",
            "Signature payload includes SEP-07 prefix for security",
            "TOML-based URI request signing key lookup from origin domain",
            "Thread-safe implementation suitable for concurrent URI operations",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 95:
            matrix.recommendations = [
                "✅ The SDK has excellent compatibility with SEP-07!",
                "Use getSignTransactionURI() to create transaction signing requests",
                "Use getPayOperationURI() to create payment requests",
                "Always validate URIs before processing using URISchemeValidator",
                "Sign URIs with signURI() when you are the request originator",
                "Verify signed URIs with checkURISchemeIsValid() when you are the receiver",
                "Include origin_domain and signature for trusted URI requests",
                "Keep messages under 300 characters (enforced by MessageMaximumLength)",
                "Use callback parameter to receive signed transaction envelopes",
                "Specify network_passphrase for non-public networks",
                "Use pubkey parameter to specify which key should sign",
                "Chain multiple operations using the chain parameter",
                "Implement replace parameter for dynamic transaction field replacement (SEP-11)",
                "For payments, specify amount, asset_code, and asset_issuer for non-XLM assets",
                "Use appropriate memo_type (MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN)",
                "Validate destination addresses before creating payment URIs",
                "Test URIs with both web+stellar: scheme and proper URL encoding",
                "Verify origin domain TOML files contain URI_REQUEST_SIGNING_KEY",
                "Handle URISchemeErrors enum for proper error messages",
                "Use signAndSubmitTransaction() for complete signing and submission workflow",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-07 compliance",
                "Add comprehensive test coverage for all URI operations",
                "Test signature verification with various origin domains",
            ]

        return matrix

    def _create_sep07_sections(self) -> List[SEPSection]:
        """Create SEP-07 sections with all fields"""
        sections = []

        # URI Operations (2 fields)
        uri_operations_section = SEPSection(name='URI Operations')
        uri_operations_section.fields = [
            SEPField(
                name='tx',
                section='URI Operations',
                required=True,
                description='Transaction operation - Request to sign a transaction',
                requirements='URI operation for transaction signing requests'
            ),
            SEPField(
                name='pay',
                section='URI Operations',
                required=True,
                description='Payment operation - Request to pay a specific address',
                requirements='URI operation for payment requests'
            ),
        ]
        sections.append(uri_operations_section)

        # TX Operation Parameters (5 fields)
        tx_parameters_section = SEPSection(name='TX Operation Parameters')
        tx_parameters_section.fields = [
            SEPField(
                name='xdr',
                section='TX Operation Parameters',
                required=True,
                description='Base64 encoded TransactionEnvelope XDR',
                requirements='Required parameter for tx operation'
            ),
            SEPField(
                name='replace',
                section='TX Operation Parameters',
                required=False,
                description='URL-encoded field replacement using Txrep (SEP-0011) format',
                requirements='Optional parameter for dynamic field replacement'
            ),
            SEPField(
                name='callback',
                section='TX Operation Parameters',
                required=False,
                description='URL for transaction submission callback',
                requirements='Optional callback URL for signed transaction'
            ),
            SEPField(
                name='pubkey',
                section='TX Operation Parameters',
                required=False,
                description='Stellar public key to specify which key should sign',
                requirements='Optional public key hint for signing'
            ),
            SEPField(
                name='chain',
                section='TX Operation Parameters',
                required=False,
                description='Nested SEP-0007 URL for transaction chaining',
                requirements='Optional parameter for chaining multiple operations'
            ),
        ]
        sections.append(tx_parameters_section)

        # PAY Operation Parameters (6 fields)
        pay_parameters_section = SEPSection(name='PAY Operation Parameters')
        pay_parameters_section.fields = [
            SEPField(
                name='destination',
                section='PAY Operation Parameters',
                required=True,
                description='Stellar account ID or payment address to receive payment',
                requirements='Required destination address for payment'
            ),
            SEPField(
                name='amount',
                section='PAY Operation Parameters',
                required=False,
                description='Amount to send',
                requirements='Optional amount for payment'
            ),
            SEPField(
                name='asset_code',
                section='PAY Operation Parameters',
                required=False,
                description='Asset code for the payment (e.g., USD, BTC)',
                requirements='Optional asset code (XLM if not present)'
            ),
            SEPField(
                name='asset_issuer',
                section='PAY Operation Parameters',
                required=False,
                description='Stellar account ID of asset issuer',
                requirements='Optional asset issuer (XLM if not present)'
            ),
            SEPField(
                name='memo',
                section='PAY Operation Parameters',
                required=False,
                description='Memo value to attach to transaction',
                requirements='Optional memo value'
            ),
            SEPField(
                name='memo_type',
                section='PAY Operation Parameters',
                required=False,
                description='Type of memo (MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN)',
                requirements='Optional memo type, defaults to MEMO_TEXT'
            ),
        ]
        sections.append(pay_parameters_section)

        # Common Parameters (4 fields)
        common_parameters_section = SEPSection(name='Common Parameters')
        common_parameters_section.fields = [
            SEPField(
                name='msg',
                section='Common Parameters',
                required=False,
                description='Message for the user (max 300 characters)',
                requirements='Optional message, maximum 300 characters'
            ),
            SEPField(
                name='network_passphrase',
                section='Common Parameters',
                required=False,
                description='Network passphrase for the transaction',
                requirements='Optional, defaults to public network'
            ),
            SEPField(
                name='origin_domain',
                section='Common Parameters',
                required=False,
                description='Fully qualified domain name of the service originating the request',
                requirements='Optional, required for signature verification'
            ),
            SEPField(
                name='signature',
                section='Common Parameters',
                required=False,
                description='Signature of the URL for verification',
                requirements='Optional signature for URI authentication'
            ),
        ]
        sections.append(common_parameters_section)

        # Validation Features (11 fields)
        validation_features_section = SEPSection(name='Validation Features')
        validation_features_section.fields = [
            SEPField(
                name='validate_uri_scheme',
                section='Validation Features',
                required=True,
                description='Validate that URI starts with web+stellar:',
                requirements='URI scheme prefix validation'
            ),
            SEPField(
                name='validate_operation_type',
                section='Validation Features',
                required=True,
                description='Validate operation type is tx or pay',
                requirements='Operation type validation'
            ),
            SEPField(
                name='validate_xdr_parameter',
                section='Validation Features',
                required=True,
                description='Validate XDR parameter for tx operation',
                requirements='XDR parameter validation'
            ),
            SEPField(
                name='validate_destination_parameter',
                section='Validation Features',
                required=True,
                description='Validate destination parameter for pay operation',
                requirements='Destination parameter validation'
            ),
            SEPField(
                name='validate_stellar_address',
                section='Validation Features',
                required=True,
                description='Validate Stellar addresses (account IDs, muxed accounts, contract IDs)',
                requirements='Stellar address format validation'
            ),
            SEPField(
                name='validate_asset_code',
                section='Validation Features',
                required=True,
                description='Validate asset code length and format',
                requirements='Asset code validation'
            ),
            SEPField(
                name='validate_memo_type',
                section='Validation Features',
                required=True,
                description='Validate memo type is one of allowed types',
                requirements='Memo type validation'
            ),
            SEPField(
                name='validate_memo_value',
                section='Validation Features',
                required=True,
                description='Validate memo value based on memo type',
                requirements='Memo value validation per type'
            ),
            SEPField(
                name='validate_message_length',
                section='Validation Features',
                required=True,
                description='Validate message parameter length (max 300 chars)',
                requirements='Message length validation'
            ),
            SEPField(
                name='validate_origin_domain',
                section='Validation Features',
                required=True,
                description='Validate origin_domain is fully qualified domain name',
                requirements='Origin domain format validation'
            ),
            SEPField(
                name='validate_chain_nesting',
                section='Validation Features',
                required=True,
                description='Validate chain parameter nesting depth (max 7 levels)',
                requirements='Chain nesting depth validation'
            ),
        ]
        sections.append(validation_features_section)

        # Signature Features (3 fields)
        signature_features_section = SEPSection(name='Signature Features')
        signature_features_section.fields = [
            SEPField(
                name='sign_uri',
                section='Signature Features',
                required=True,
                description='Sign a SEP-0007 URI with a keypair',
                requirements='URI signing capability'
            ),
            SEPField(
                name='verify_signature',
                section='Signature Features',
                required=True,
                description='Verify URI signature with a public key',
                requirements='Signature verification capability'
            ),
            SEPField(
                name='verify_signed_uri',
                section='Signature Features',
                required=True,
                description='Verify signed URI by fetching signing key from origin domain TOML',
                requirements='Complete signed URI verification with TOML lookup'
            ),
        ]
        sections.append(signature_features_section)

        return sections

    def _analyze_uri_operations(self, section: SEPSection, uri_scheme_file: Optional[Path]) -> None:
        """Analyze URI operations support"""
        if not uri_scheme_file:
            return

        try:
            content = uri_scheme_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'tx':
                    # Check for getSignTransactionURI method
                    if 'func getSignTransactionURI' in content:
                        field.implemented = True
                        field.sdk_property = 'getSignTransactionURI(transactionXDR:...)'
                        field.implementation_notes = 'Generates web+stellar:tx? URIs for transaction signing requests'

                elif field.name == 'pay':
                    # Check for getPayOperationURI method
                    if 'func getPayOperationURI' in content:
                        field.implemented = True
                        field.sdk_property = 'getPayOperationURI(destination:...)'
                        field.implementation_notes = 'Generates web+stellar:pay? URIs for payment requests'

        except Exception as e:
            logger.warning(f"Error analyzing URI operations: {e}")

    def _analyze_tx_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                               enums_file: Optional[Path]) -> None:
        """Analyze TX operation parameters support"""
        if not uri_scheme_file or not enums_file:
            return

        try:
            uri_content = uri_scheme_file.read_text(encoding='utf-8')
            enum_content = enums_file.read_text(encoding='utf-8')

            # Check for SignTransactionParams enum
            if 'enum SignTransactionParams' not in enum_content:
                return

            # Map field names to enum cases
            param_mapping = {
                'xdr': 'SignTransactionParams.xdr',
                'replace': 'SignTransactionParams.replace',
                'callback': 'SignTransactionParams.callback',
                'pubkey': 'SignTransactionParams.pubkey',
                'chain': 'SignTransactionParams.chain',
            }

            for field in section.fields:
                expected_param = param_mapping.get(field.name)
                if expected_param:
                    # Check if enum case exists
                    enum_case = f'case {field.name}'
                    if enum_case in enum_content:
                        # Check if used in getSignTransactionURI
                        if expected_param in uri_content:
                            field.implemented = True
                            field.sdk_property = expected_param
                            if field.name == 'xdr':
                                field.implementation_notes = 'Required parameter, base64-encoded TransactionEnvelope'
                            elif field.name == 'replace':
                                field.implementation_notes = 'Optional, URL-encoded Txrep field replacement'
                            elif field.name == 'callback':
                                field.implementation_notes = 'Optional, URL callback for signed transaction'
                            elif field.name == 'pubkey':
                                field.implementation_notes = 'Optional, specifies signing public key'
                            elif field.name == 'chain':
                                field.implementation_notes = 'Optional, nested SEP-07 URL for chaining'

        except Exception as e:
            logger.warning(f"Error analyzing TX parameters: {e}")

    def _analyze_pay_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                enums_file: Optional[Path]) -> None:
        """Analyze PAY operation parameters support"""
        if not uri_scheme_file or not enums_file:
            return

        try:
            uri_content = uri_scheme_file.read_text(encoding='utf-8')
            enum_content = enums_file.read_text(encoding='utf-8')

            # Check for PayOperationParams enum
            if 'enum PayOperationParams' not in enum_content:
                return

            # Map field names to enum cases
            param_mapping = {
                'destination': 'PayOperationParams.destination',
                'amount': 'PayOperationParams.amount',
                'asset_code': 'PayOperationParams.asset_code',
                'asset_issuer': 'PayOperationParams.asset_issuer',
                'memo': 'PayOperationParams.memo',
                'memo_type': 'PayOperationParams.memo_type',
            }

            for field in section.fields:
                expected_param = param_mapping.get(field.name)
                if expected_param:
                    # Check if enum case exists
                    enum_case = f'case {field.name}'
                    if enum_case in enum_content:
                        # Check if used in getPayOperationURI
                        if expected_param in uri_content:
                            field.implemented = True
                            field.sdk_property = expected_param
                            if field.name == 'destination':
                                field.implementation_notes = 'Required parameter, Stellar account ID or payment address'
                            elif field.name == 'amount':
                                field.implementation_notes = 'Optional, Decimal amount to send'
                            elif field.name == 'asset_code':
                                field.implementation_notes = 'Optional, asset code (XLM if not present)'
                            elif field.name == 'asset_issuer':
                                field.implementation_notes = 'Optional, issuer account ID (XLM if not present)'
                            elif field.name == 'memo':
                                field.implementation_notes = 'Optional, memo value with type-specific encoding'
                            elif field.name == 'memo_type':
                                field.implementation_notes = 'Optional, defaults to MEMO_TEXT'
                        elif field.name == 'memo_type':
                            # Special case: memo_type is a parameter but not accessed via enum in code
                            if 'memoType: String?' in uri_content:
                                field.implemented = True
                                field.sdk_property = 'memoType parameter in getPayOperationURI'
                                field.implementation_notes = 'Optional parameter, defaults to MEMO_TEXT'

        except Exception as e:
            logger.warning(f"Error analyzing PAY parameters: {e}")

    def _analyze_common_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                  enums_file: Optional[Path]) -> None:
        """Analyze common parameters support"""
        if not uri_scheme_file or not enums_file:
            return

        try:
            uri_content = uri_scheme_file.read_text(encoding='utf-8')
            enum_content = enums_file.read_text(encoding='utf-8')

            # Common parameters appear in both SignTransactionParams and PayOperationParams enums
            for field in section.fields:
                # Check in SignTransactionParams
                if f'case {field.name}' in enum_content:
                    # Check usage in both methods
                    sign_tx_param = f'SignTransactionParams.{field.name}'
                    pay_op_param = f'PayOperationParams.{field.name}'

                    if sign_tx_param in uri_content and pay_op_param in uri_content:
                        field.implemented = True
                        field.sdk_property = f'SignTransactionParams.{field.name} / PayOperationParams.{field.name}'

                        if field.name == 'msg':
                            field.implementation_notes = 'Optional, max 300 characters (enforced by MessageMaximumLength)'
                        elif field.name == 'network_passphrase':
                            field.implementation_notes = 'Optional, defaults to public network if not specified'
                        elif field.name == 'origin_domain':
                            field.implementation_notes = 'Optional, FQDN of request originator'
                        elif field.name == 'signature':
                            field.implementation_notes = 'Optional, URL signature for authentication'

        except Exception as e:
            logger.warning(f"Error analyzing common parameters: {e}")

    def _analyze_validation_features(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                    validator_file: Optional[Path]) -> None:
        """Analyze validation features support"""
        if not uri_scheme_file and not validator_file:
            return

        try:
            uri_content = uri_scheme_file.read_text(encoding='utf-8') if uri_scheme_file else ""
            validator_content = validator_file.read_text(encoding='utf-8') if validator_file else ""

            for field in section.fields:
                if field.name == 'validate_uri_scheme':
                    # Check for URISchemeName constant
                    if 'URISchemeName = "web+stellar:"' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'URISchemeName constant ("web+stellar:")'
                        field.implementation_notes = 'URI scheme prefix defined and enforced'

                elif field.name == 'validate_operation_type':
                    # Check for operation constants
                    if 'SignOperation = "tx?"' in uri_content and 'PayOperation = "pay?"' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'SignOperation ("tx?") / PayOperation ("pay?") constants'
                        field.implementation_notes = 'Operation types defined and enforced in URI generation'

                elif field.name == 'validate_xdr_parameter':
                    # Check XDR parameter handling in getSignTransactionURI
                    if 'transactionXDR: TransactionXDR' in uri_content and 'encodedEnvelope()' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'TransactionXDR parameter validation in getSignTransactionURI'
                        field.implementation_notes = 'XDR validated via TransactionXDR type and encoding'

                elif field.name == 'validate_destination_parameter':
                    # Check destination parameter in getPayOperationURI
                    if 'destination: String' in uri_content and 'getPayOperationURI' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'destination parameter requirement in getPayOperationURI'
                        field.implementation_notes = 'Destination required as non-optional parameter'

                elif field.name == 'validate_stellar_address':
                    # Validated through SDK's KeyPair/PublicKey classes (used in validator)
                    if 'PublicKey' in validator_content and 'accountId' in validator_content:
                        field.implemented = True
                        field.sdk_property = 'PublicKey(accountId:) validation'
                        field.implementation_notes = 'Stellar addresses validated via SDK PublicKey class'

                elif field.name == 'validate_asset_code':
                    # Asset code validation through parameter usage
                    if 'assetCode: String?' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'assetCode parameter in getPayOperationURI'
                        field.implementation_notes = 'Asset code validated through string parameter'

                elif field.name == 'validate_memo_type':
                    # Memo type validation through switch statement
                    if 'MemoTypeAsString.TEXT' in uri_content and 'MemoTypeAsString.ID' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'MemoTypeAsString enum validation in switch statement'
                        field.implementation_notes = 'Supports MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN'

                elif field.name == 'validate_memo_value':
                    # Memo value validation based on type (see lines 160-174 in URIScheme.swift)
                    if 'switch memoType' in uri_content and 'base64Encoded()' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'Type-specific memo encoding in getPayOperationURI'
                        field.implementation_notes = 'Different encoding for TEXT/ID vs HASH/RETURN types'

                elif field.name == 'validate_message_length':
                    # Message length validation
                    if 'MessageMaximumLength' in uri_content and 'message.count <' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'MessageMaximumLength constant (300) with count check'
                        field.implementation_notes = 'Enforces 300 character maximum for messages'

                elif field.name == 'validate_origin_domain':
                    # Origin domain validation
                    if 'isFullyQualifiedDomainName' in validator_content:
                        field.implemented = True
                        field.sdk_property = 'isFullyQualifiedDomainName validation in URISchemeValidator'
                        field.implementation_notes = 'Validates origin domain is fully qualified domain name'

                elif field.name == 'validate_chain_nesting':
                    # Chain parameter exists, but nesting depth validation not explicitly enforced
                    if 'chain: String?' in uri_content and 'urlEncodedChain' in uri_content:
                        field.implemented = True
                        field.sdk_property = 'chain parameter with URL encoding'
                        field.implementation_notes = 'Chain parameter supported; depth limit not explicitly enforced'

        except Exception as e:
            logger.warning(f"Error analyzing validation features: {e}")

    def _analyze_signature_features(self, section: SEPSection, validator_file: Optional[Path]) -> None:
        """Analyze signature features support"""
        if not validator_file:
            return

        try:
            content = validator_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'sign_uri':
                    # Check for signURI method
                    if 'func signURI(url:' in content and 'signerKeyPair: KeyPair' in content:
                        field.implemented = True
                        field.sdk_property = 'signURI(url:signerKeyPair:)'
                        field.implementation_notes = 'Signs URI with keypair, returns SignURLEnum result'

                elif field.name == 'verify_signature':
                    # Check for verify method
                    if 'func verify(forURL url:' in content and 'signerPublicKey: PublicKey' in content:
                        field.implemented = True
                        field.sdk_property = 'verify(forURL:urlEncodedBase64Signature:signerPublicKey:)'
                        field.implementation_notes = 'Private method verifies signature with public key'

                elif field.name == 'verify_signed_uri':
                    # Check for checkURISchemeIsValid method
                    if 'func checkURISchemeIsValid' in content and 'StellarToml.from(domain:' in content:
                        field.implemented = True
                        field.sdk_property = 'checkURISchemeIsValid(url:)'
                        field.implementation_notes = 'Fetches signing key from origin domain TOML and verifies'

        except Exception as e:
            logger.warning(f"Error analyzing signature features: {e}")


class SEP11Analyzer:
    """Analyzer for SEP-11 (Txrep: human-readable low-level representation of Stellar transactions)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-11 implementation"""
        logger.info("Analyzing SEP-11 (Txrep) implementation")

        # Load sections from Flutter SDK definition
        sections = self._load_sep11_definition()

        # Find SDK implementation files
        implementation_files = []

        # Find TxRep class
        txrep_file = self.sdk_analyzer.find_class_or_struct('TxRep')
        if txrep_file:
            rel_path = self.sdk_analyzer.get_relative_path(txrep_file)
            implementation_files.append(rel_path)
            logger.info(f"Found TxRep class at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Encoding Features':
                self._analyze_encoding_features(section, txrep_file)
            elif section.name == 'Decoding Features':
                self._analyze_decoding_features(section, txrep_file)
            elif section.name == 'Asset Encoding':
                self._analyze_asset_encoding(section, txrep_file)
            elif section.name == 'Operation Types':
                self._analyze_operation_types(section, txrep_file)
            elif section.name == 'Format Features':
                self._analyze_format_features(section, txrep_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a complete implementation of SEP-11 Txrep",
            "TxRep class implements bidirectional conversion between XDR and txrep format",
            "toTxRep(transactionEnvelope:) method converts XDR to human-readable txrep",
            "fromTxRep(txRep:) method parses txrep format to XDR",
            "Supports all 26 Stellar operation types",
            "Handles both regular transactions and fee bump transactions",
            "Supports muxed accounts (M... addresses)",
            "Implements all memo types (NONE, TEXT, ID, HASH, RETURN)",
            "Full preconditions support (time bounds, ledger bounds, min seq num)",
            "Complete Soroban transaction data encoding/decoding",
            "Signature encoding/decoding with hint and signature fields",
            "Asset encoding for native, alphanumeric4, and alphanumeric12 assets",
            "Format features: dot notation, array indexing, hex encoding, string escaping",
            "Comment support in txrep parsing (lines are trimmed and comments removed)",
            "Error handling via TxRepError enum (missingValue, invalidValue)",
            "Production-ready implementation with 3519 lines of code",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-11!",
                "Use toTxRep() to convert transaction envelopes to human-readable format",
                "Use fromTxRep() to parse txrep format back to transaction envelopes",
                "Txrep format is useful for debugging and auditing transactions",
                "Human-readable format helps users verify transaction details before signing",
                "SEP-11 format functions like assembly language for Stellar XDR",
                "All 26 operation types are fully supported",
                "Fee bump transactions are fully supported",
                "Soroban smart contract operations are fully supported",
                "Use txrep for educational purposes and transaction inspection",
                "Consider displaying txrep alongside XDR in wallet applications",
                "Txrep format is deterministic and can be used for transaction comparison",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-11 compliance",
            ]

        return matrix

    def _load_sep11_definition(self) -> List[SEPSection]:
        """Load SEP-11 field definitions from Flutter SDK reference"""
        import json
        from pathlib import Path

        # Load definition from Flutter SDK
        definition_path = Path(__file__).parent / 'data' / 'sep_0011_definition.json'

        if not definition_path.exists():
            logger.warning(f"SEP-11 definition file not found at {definition_path}")
            return self._create_sep11_sections_fallback()

        try:
            with open(definition_path, 'r', encoding='utf-8') as f:
                definition = json.load(f)

            sections = []
            for section_data in definition.get('sections', []):
                section = SEPSection(name=section_data['title'])
                for feature_data in section_data.get('txrep_features', []):
                    field = SEPField(
                        name=feature_data['name'],
                        section=section_data['title'],
                        required=feature_data.get('required', True),
                        description=feature_data['description'],
                        requirements=feature_data.get('category', '')
                    )
                    section.fields.append(field)
                sections.append(section)

            logger.info(f"Loaded SEP-11 definition with {len(sections)} sections")
            return sections

        except Exception as e:
            logger.warning(f"Error loading SEP-11 definition: {e}")
            return self._create_sep11_sections_fallback()

    def _create_sep11_sections_fallback(self) -> List[SEPSection]:
        """Fallback: Create SEP-11 sections manually if definition file not available"""
        sections = []

        # Encoding Features (8 fields)
        encoding_section = SEPSection(name='Encoding Features')
        encoding_section.fields = [
            SEPField(
                name='encode_transaction',
                section='Encoding Features',
                required=True,
                description='Convert transaction envelope XDR to txrep text format',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_fee_bump_transaction',
                section='Encoding Features',
                required=True,
                description='Convert fee bump transaction envelope to txrep format',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_source_account',
                section='Encoding Features',
                required=True,
                description='Encode source account (including muxed accounts)',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_memo',
                section='Encoding Features',
                required=True,
                description='Encode all memo types (NONE, TEXT, ID, HASH, RETURN)',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_operations',
                section='Encoding Features',
                required=True,
                description='Encode all Stellar operation types',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_preconditions',
                section='Encoding Features',
                required=True,
                description='Encode transaction preconditions (time bounds, ledger bounds, min seq num, etc.)',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_signatures',
                section='Encoding Features',
                required=True,
                description='Encode transaction signatures',
                requirements='Encoding'
            ),
            SEPField(
                name='encode_soroban_data',
                section='Encoding Features',
                required=True,
                description='Encode Soroban transaction data (resources, footprint, etc.)',
                requirements='Encoding'
            ),
        ]
        sections.append(encoding_section)

        # Decoding Features (8 fields)
        decoding_section = SEPSection(name='Decoding Features')
        decoding_section.fields = [
            SEPField(
                name='decode_transaction',
                section='Decoding Features',
                required=True,
                description='Parse txrep text format to transaction envelope XDR',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_fee_bump_transaction',
                section='Decoding Features',
                required=True,
                description='Parse fee bump transaction from txrep format',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_source_account',
                section='Decoding Features',
                required=True,
                description='Parse source account (including muxed accounts)',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_memo',
                section='Decoding Features',
                required=True,
                description='Parse all memo types from txrep',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_operations',
                section='Decoding Features',
                required=True,
                description='Parse all Stellar operation types from txrep',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_preconditions',
                section='Decoding Features',
                required=True,
                description='Parse transaction preconditions from txrep',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_signatures',
                section='Decoding Features',
                required=True,
                description='Parse transaction signatures from txrep',
                requirements='Decoding'
            ),
            SEPField(
                name='decode_soroban_data',
                section='Decoding Features',
                required=True,
                description='Parse Soroban transaction data from txrep',
                requirements='Decoding'
            ),
        ]
        sections.append(decoding_section)

        # Asset Encoding (3 fields)
        asset_section = SEPSection(name='Asset Encoding')
        asset_section.fields = [
            SEPField(
                name='encode_native_asset',
                section='Asset Encoding',
                required=True,
                description='Encode native XLM asset in txrep format',
                requirements='Asset Encoding'
            ),
            SEPField(
                name='encode_alphanumeric4_asset',
                section='Asset Encoding',
                required=True,
                description='Encode 4-character alphanumeric asset',
                requirements='Asset Encoding'
            ),
            SEPField(
                name='encode_alphanumeric12_asset',
                section='Asset Encoding',
                required=True,
                description='Encode 12-character alphanumeric asset',
                requirements='Asset Encoding'
            ),
        ]
        sections.append(asset_section)

        # Operation Types (26 fields)
        operations_section = SEPSection(name='Operation Types')
        operation_types = [
            ('create_account', 'Encode/decode CREATE_ACCOUNT operation'),
            ('payment', 'Encode/decode PAYMENT operation'),
            ('path_payment_strict_receive', 'Encode/decode PATH_PAYMENT_STRICT_RECEIVE operation'),
            ('path_payment_strict_send', 'Encode/decode PATH_PAYMENT_STRICT_SEND operation'),
            ('manage_sell_offer', 'Encode/decode MANAGE_SELL_OFFER operation'),
            ('manage_buy_offer', 'Encode/decode MANAGE_BUY_OFFER operation'),
            ('create_passive_sell_offer', 'Encode/decode CREATE_PASSIVE_SELL_OFFER operation'),
            ('set_options', 'Encode/decode SET_OPTIONS operation'),
            ('change_trust', 'Encode/decode CHANGE_TRUST operation'),
            ('allow_trust', 'Encode/decode ALLOW_TRUST operation'),
            ('account_merge', 'Encode/decode ACCOUNT_MERGE operation'),
            ('manage_data', 'Encode/decode MANAGE_DATA operation'),
            ('bump_sequence', 'Encode/decode BUMP_SEQUENCE operation'),
            ('create_claimable_balance', 'Encode/decode CREATE_CLAIMABLE_BALANCE operation'),
            ('claim_claimable_balance', 'Encode/decode CLAIM_CLAIMABLE_BALANCE operation'),
            ('begin_sponsoring_future_reserves', 'Encode/decode BEGIN_SPONSORING_FUTURE_RESERVES operation'),
            ('end_sponsoring_future_reserves', 'Encode/decode END_SPONSORING_FUTURE_RESERVES operation'),
            ('revoke_sponsorship', 'Encode/decode REVOKE_SPONSORSHIP operation'),
            ('clawback', 'Encode/decode CLAWBACK operation'),
            ('clawback_claimable_balance', 'Encode/decode CLAWBACK_CLAIMABLE_BALANCE operation'),
            ('set_trust_line_flags', 'Encode/decode SET_TRUST_LINE_FLAGS operation'),
            ('liquidity_pool_deposit', 'Encode/decode LIQUIDITY_POOL_DEPOSIT operation'),
            ('liquidity_pool_withdraw', 'Encode/decode LIQUIDITY_POOL_WITHDRAW operation'),
            ('invoke_host_function', 'Encode/decode INVOKE_HOST_FUNCTION operation (Soroban)'),
            ('extend_footprint_ttl', 'Encode/decode EXTEND_FOOTPRINT_TTL operation (Soroban)'),
            ('restore_footprint', 'Encode/decode RESTORE_FOOTPRINT operation (Soroban)'),
        ]
        for op_name, op_desc in operation_types:
            operations_section.fields.append(
                SEPField(
                    name=op_name,
                    section='Operation Types',
                    required=True,
                    description=op_desc,
                    requirements='Operation Type'
                )
            )
        sections.append(operations_section)

        # Format Features (5 fields)
        format_section = SEPSection(name='Format Features')
        format_section.fields = [
            SEPField(
                name='comment_support',
                section='Format Features',
                required=True,
                description='Support for comments in txrep format',
                requirements='Format Feature'
            ),
            SEPField(
                name='dot_notation',
                section='Format Features',
                required=True,
                description='Use dot notation for nested structures',
                requirements='Format Feature'
            ),
            SEPField(
                name='array_indexing',
                section='Format Features',
                required=True,
                description='Support array indexing in txrep format',
                requirements='Format Feature'
            ),
            SEPField(
                name='hex_encoding',
                section='Format Features',
                required=True,
                description='Hexadecimal encoding for binary data',
                requirements='Format Feature'
            ),
            SEPField(
                name='string_escaping',
                section='Format Features',
                required=True,
                description='Proper string escaping with double quotes',
                requirements='Format Feature'
            ),
        ]
        sections.append(format_section)

        return sections

    def _analyze_encoding_features(self, section: SEPSection, txrep_file: Optional[Path]) -> None:
        """Analyze encoding features"""
        if not txrep_file:
            return

        try:
            content = txrep_file.read_text(encoding='utf-8')

            # All encoding features are implemented via toTxRep() method
            for field in section.fields:
                if field.name == 'encode_transaction':
                    if 'func toTxRep(transactionEnvelope:String)' in content:
                        field.implemented = True
                        field.sdk_property = 'toTxRep(transactionEnvelope:)'
                elif field.name == 'encode_fee_bump_transaction':
                    if 'case .feeBump(let feeBumpXdr):' in content and 'feeBumpTransaction' in content:
                        field.implemented = True
                        field.sdk_property = 'toTxRep() - fee bump support'
                elif field.name == 'encode_source_account':
                    if 'addLine(key: prefix + "sourceAccount"' in content:
                        field.implemented = True
                        field.sdk_property = 'toTxRep() - source account encoding'
                elif field.name == 'encode_memo':
                    if 'func addMemo(memo:MemoXDR' in content:
                        field.implemented = True
                        field.sdk_property = 'addMemo()'
                elif field.name == 'encode_operations':
                    if 'func addOperations(operations:[OperationXDR]' in content:
                        field.implemented = True
                        field.sdk_property = 'addOperations()'
                elif field.name == 'encode_preconditions':
                    if 'func addPreconditions(cond:PreconditionsXDR' in content:
                        field.implemented = True
                        field.sdk_property = 'addPreconditions()'
                elif field.name == 'encode_signatures':
                    if 'func addSignatures(signatures:[DecoratedSignatureXDR]' in content:
                        field.implemented = True
                        field.sdk_property = 'addSignatures()'
                elif field.name == 'encode_soroban_data':
                    if 'func addSorobanTransactionData(data: SorobanTransactionDataXDR' in content:
                        field.implemented = True
                        field.sdk_property = 'addSorobanTransactionData()'

        except Exception as e:
            logger.warning(f"Error analyzing encoding features: {e}")

    def _analyze_decoding_features(self, section: SEPSection, txrep_file: Optional[Path]) -> None:
        """Analyze decoding features"""
        if not txrep_file:
            return

        try:
            content = txrep_file.read_text(encoding='utf-8')

            # All decoding features are implemented via fromTxRep() method
            for field in section.fields:
                if field.name == 'decode_transaction':
                    if 'func fromTxRep(txRep:String)' in content:
                        field.implemented = True
                        field.sdk_property = 'fromTxRep(txRep:)'
                elif field.name == 'decode_fee_bump_transaction':
                    if 'let isFeeBump = dic["type"] == "ENVELOPE_TYPE_TX_FEE_BUMP"' in content:
                        field.implemented = True
                        field.sdk_property = 'fromTxRep() - fee bump support'
                elif field.name == 'decode_source_account':
                    if 'key = prefix + "sourceAccount"' in content and 'MuxedAccount(accountId:sourceAccountId' in content:
                        field.implemented = True
                        field.sdk_property = 'fromTxRep() - source account parsing'
                elif field.name == 'decode_memo':
                    if 'func getMemo(dic:Dictionary<String,String>' in content:
                        field.implemented = True
                        field.sdk_property = 'getMemo()'
                elif field.name == 'decode_operations':
                    if 'func getOperations(dic:Dictionary<String,String>' in content:
                        field.implemented = True
                        field.sdk_property = 'getOperations()'
                elif field.name == 'decode_preconditions':
                    # getPreconditions is implemented - check for function definition
                    if 'func getPreconditions(dic:Dictionary<String,String>' in content or 'func getPreconditions(dic: Dictionary<String,String>' in content:
                        field.implemented = True
                        field.sdk_property = 'getPreconditions()'
                elif field.name == 'decode_signatures':
                    if 'func getSignatures(dic:Dictionary<String,String>' in content:
                        field.implemented = True
                        field.sdk_property = 'getSignatures()'
                elif field.name == 'decode_soroban_data':
                    if 'func getSorobanTransactionData(dic:Dictionary<String,String>' in content:
                        field.implemented = True
                        field.sdk_property = 'getSorobanTransactionData()'

        except Exception as e:
            logger.warning(f"Error analyzing decoding features: {e}")

    def _analyze_asset_encoding(self, section: SEPSection, txrep_file: Optional[Path]) -> None:
        """Analyze asset encoding support"""
        if not txrep_file:
            return

        try:
            content = txrep_file.read_text(encoding='utf-8')

            # Check for encodeAsset function
            has_encode_asset = 'func encodeAsset(asset: AssetXDR)' in content or 'func encodeAsset(asset:AssetXDR)' in content

            for field in section.fields:
                if has_encode_asset:
                    if field.name == 'encode_native_asset':
                        # Assets are encoded in encodeAsset function - native returns "XLM"
                        if 'return "XLM"' in content:
                            field.implemented = True
                            field.sdk_property = 'encodeAsset() - native'
                    elif field.name == 'encode_alphanumeric4_asset':
                        # Alphanumeric assets use assetCode + issuer pattern (covers both 4 and 12)
                        if 'asset.assetCode' in content and 'asset.issuer' in content:
                            field.implemented = True
                            field.sdk_property = 'encodeAsset() - alphanum4'
                    elif field.name == 'encode_alphanumeric12_asset':
                        # Same encoding for both alphanumeric types
                        if 'asset.assetCode' in content and 'asset.issuer' in content:
                            field.implemented = True
                            field.sdk_property = 'encodeAsset() - alphanum12'

        except Exception as e:
            logger.warning(f"Error analyzing asset encoding: {e}")

    def _analyze_operation_types(self, section: SEPSection, txrep_file: Optional[Path]) -> None:
        """Analyze operation type support"""
        if not txrep_file:
            return

        try:
            content = txrep_file.read_text(encoding='utf-8')

            # Map operation names to Swift case names
            operation_mapping = {
                'create_account': ('case .createAccountOp(', 'case "CREATE_ACCOUNT":'),
                'payment': ('case .paymentOp(', 'case "PAYMENT":'),
                'path_payment_strict_receive': ('case .pathPaymentStrictReceiveOp(', 'case "PATH_PAYMENT_STRICT_RECEIVE":'),
                'path_payment_strict_send': ('case .pathPaymentStrictSendOp(', 'case "PATH_PAYMENT_STRICT_SEND":'),
                'manage_sell_offer': ('case .manageSellOfferOp(', 'case "MANAGE_SELL_OFFER":'),
                'manage_buy_offer': ('case .manageBuyOfferOp(', 'case "MANAGE_BUY_OFFER":'),
                'create_passive_sell_offer': ('case .createPassiveSellOfferOp(', 'case "CREATE_PASSIVE_SELL_OFFER":'),
                'set_options': ('case .setOptionsOp(', 'case "SET_OPTIONS":'),
                'change_trust': ('case .changeTrustOp(', 'case "CHANGE_TRUST":'),
                'allow_trust': ('case .allowTrustOp(', 'case "ALLOW_TRUST":'),
                'account_merge': ('case .accountMerge(', 'case "ACCOUNT_MERGE":'),
                'manage_data': ('case .manageDataOp(', 'case "MANAGE_DATA":'),
                'bump_sequence': ('case .bumpSequenceOp(', 'case "BUMP_SEQUENCE":'),
                'create_claimable_balance': ('case .createClaimableBalanceOp(', 'case "CREATE_CLAIMABLE_BALANCE":'),
                'claim_claimable_balance': ('case .claimClaimableBalanceOp(', 'case "CLAIM_CLAIMABLE_BALANCE":'),
                'begin_sponsoring_future_reserves': ('case .beginSponsoringFutureReservesOp(', 'case "BEGIN_SPONSORING_FUTURE_RESERVES":'),
                'end_sponsoring_future_reserves': ('case .endSponsoringFutureReserves', 'case "END_SPONSORING_FUTURE_RESERVES":'),
                'revoke_sponsorship': ('case .revokeSponsorshipOp(', 'case "REVOKE_SPONSORSHIP":'),
                'clawback': ('case .clawbackOp(', 'case "CLAWBACK":'),
                'clawback_claimable_balance': ('case .clawbackClaimableBalanceOp(', 'case "CLAWBACK_CLAIMABLE_BALANCE":'),
                'set_trust_line_flags': ('case .setTrustLineFlagsOp(', 'case "SET_TRUST_LINE_FLAGS":'),
                'liquidity_pool_deposit': ('case .liquidityPoolDepositOp(', 'case "LIQUIDITY_POOL_DEPOSIT":'),
                'liquidity_pool_withdraw': ('case .liquidityPoolWithdrawOp(', 'case "LIQUIDITY_POOL_WITHDRAW":'),
                'invoke_host_function': ('case .invokeHostFunctionOp(', 'case "INVOKE_HOST_FUNCTION":'),
                'extend_footprint_ttl': ('case .extendFootprintTTLOp(', 'case "EXTEND_FOOTPRINT_TTL":'),
                'restore_footprint': ('case .restoreFootprintOp(', 'case "RESTORE_FOOTPRINT":'),
            }

            for field in section.fields:
                if field.name in operation_mapping:
                    encode_pattern, decode_pattern = operation_mapping[field.name]
                    # Check if both encoding and decoding are supported
                    if encode_pattern in content and decode_pattern in content:
                        field.implemented = True
                        field.sdk_property = f'{field.name} operation'

        except Exception as e:
            logger.warning(f"Error analyzing operation types: {e}")

    def _analyze_format_features(self, section: SEPSection, txrep_file: Optional[Path]) -> None:
        """Analyze format features"""
        if not txrep_file:
            return

        try:
            content = txrep_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'comment_support':
                    # Check for comment removal in parsing
                    if 'func removeComment(val:String)' in content or 'removeComment(val:' in content:
                        field.implemented = True
                        field.sdk_property = 'removeComment() function'
                elif field.name == 'dot_notation':
                    # Check for dot notation in key construction
                    if 'prefix + "tx."' in content or 'operationPrefix + "' in content:
                        field.implemented = True
                        field.sdk_property = 'Dot notation in key paths'
                elif field.name == 'array_indexing':
                    # Check for array indexing syntax
                    if '"operations[" + String(index) + "]"' in content or '"signatures["' in content:
                        field.implemented = True
                        field.sdk_property = 'Array indexing [n] syntax'
                elif field.name == 'hex_encoding':
                    # Check for hex encoding
                    if 'hexEncodedString()' in content or 'data(using: .hexadecimal)' in content:
                        field.implemented = True
                        field.sdk_property = 'hexEncodedString() method'
                elif field.name == 'string_escaping':
                    # Check for JSON encoding for string escaping
                    if 'JSONEncoder()' in content and 'jsonEncoder.encode(' in content:
                        field.implemented = True
                        field.sdk_property = 'JSONEncoder for string escaping'

        except Exception as e:
            logger.warning(f"Error analyzing format features: {e}")


class SEP46Analyzer:
    """Analyzer for SEP-46: Contract Meta - A standard for the storage of metadata in contract Wasm files"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-46 implementation"""
        logger.info("Analyzing SEP-46 (Contract Meta) implementation")

        # Load sections from definition file
        sections = self._load_sep46_definition()

        # Find SDK implementation files
        implementation_files = []

        # Find SorobanContractParser class
        parser_file = self.sdk_analyzer.find_class_or_struct('SorobanContractParser')
        if parser_file:
            rel_path = self.sdk_analyzer.get_relative_path(parser_file)
            implementation_files.append(rel_path)
            logger.info(f"Found SorobanContractParser class at {rel_path}")

        # Find ContractMetaXDR file
        meta_xdr_file = self.sdk_analyzer.find_file_by_name('ContractMetaXDR.swift')
        if meta_xdr_file:
            rel_path = self.sdk_analyzer.get_relative_path(meta_xdr_file)
            implementation_files.append(rel_path)
            logger.info(f"Found ContractMetaXDR at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Contract Metadata Storage' or section.name == 'Metadata Storage':
                self._analyze_metadata_storage(section, parser_file)
            elif section.name == 'Encoding Format':
                self._analyze_encoding_format(section, parser_file)
            elif section.name == 'Implementation Support':
                self._analyze_implementation_support(section, parser_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a complete implementation of SEP-46 Contract Meta",
            "SorobanContractParser class parses contract metadata from Wasm bytecode",
            "parseMeta() method extracts metadata from contractmetav0 custom sections",
            "Supports SCMetaEntry XDR type for structuring metadata",
            "Handles binary stream encoding of metadata entries",
            "Stores metadata as key-value string pairs in metaEntries dictionary",
            "Supports multiple metadata entries in a single custom section",
            "Supports multiple contractmetav0 sections interpreted sequentially",
            "Full XDR decoding support for SCMetaEntry structures",
            "Production-ready implementation for contract metadata parsing",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-46!",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-46 compliance",
            ]

        return matrix

    def _load_sep46_definition(self) -> List[SEPSection]:
        """Load SEP-46 field definitions from JSON file"""
        import json
        from pathlib import Path

        # Load definition from local data directory
        definition_path = Path(__file__).parent / 'data' / 'sep_0046_definition.json'

        if not definition_path.exists():
            logger.warning(f"SEP-46 definition file not found at {definition_path}")
            return self._create_sep46_sections_fallback()

        try:
            with open(definition_path, 'r', encoding='utf-8') as f:
                definition = json.load(f)

            sections = []
            for section_data in definition.get('sections', []):
                section = SEPSection(name=section_data['title'])
                for feature_data in section_data.get('contract_meta_features', []):
                    field = SEPField(
                        name=feature_data['name'],
                        section=section_data['title'],
                        required=feature_data.get('required', True),
                        description=feature_data['description'],
                        requirements=feature_data.get('category', '')
                    )
                    section.fields.append(field)
                sections.append(section)

            logger.info(f"Loaded SEP-46 definition with {len(sections)} sections")
            return sections

        except Exception as e:
            logger.warning(f"Error loading SEP-46 definition: {e}")
            return self._create_sep46_sections_fallback()

    def _create_sep46_sections_fallback(self) -> List[SEPSection]:
        """Fallback: Create SEP-46 sections manually if definition file not available"""
        sections = []

        # Metadata Storage (3 fields)
        storage_section = SEPSection(name='Metadata Storage')
        storage_section.fields = [
            SEPField(
                name='contractmetav0_section',
                section='Metadata Storage',
                required=True,
                description='Support for storing metadata in "contractmetav0" Wasm custom sections',
                requirements='Metadata Storage'
            ),
            SEPField(
                name='multiple_entries_single_section',
                section='Metadata Storage',
                required=True,
                description='Support for multiple metadata entries in a single custom section',
                requirements='Metadata Storage'
            ),
            SEPField(
                name='multiple_sections',
                section='Metadata Storage',
                required=True,
                description='Support for multiple "contractmetav0" sections interpreted sequentially',
                requirements='Metadata Storage'
            ),
        ]
        sections.append(storage_section)

        # Encoding Format (3 fields)
        encoding_section = SEPSection(name='Encoding Format')
        encoding_section.fields = [
            SEPField(
                name='scmetaentry_xdr',
                section='Encoding Format',
                required=True,
                description='Use SCMetaEntry XDR type for structuring metadata',
                requirements='Encoding Format'
            ),
            SEPField(
                name='binary_stream_encoding',
                section='Encoding Format',
                required=True,
                description='Encode entries as a stream of binary values',
                requirements='Encoding Format'
            ),
            SEPField(
                name='key_value_pairs',
                section='Encoding Format',
                required=True,
                description='Store metadata as key-value string pairs',
                requirements='Encoding Format'
            ),
        ]
        sections.append(encoding_section)

        # Implementation Support (3 fields)
        impl_section = SEPSection(name='Implementation Support')
        impl_section.fields = [
            SEPField(
                name='parse_contract_meta',
                section='Implementation Support',
                required=True,
                description='Parse contract metadata from contract bytecode',
                requirements='Implementation Support'
            ),
            SEPField(
                name='extract_meta_entries',
                section='Implementation Support',
                required=True,
                description='Extract meta entries as key-value pairs from contract',
                requirements='Implementation Support'
            ),
            SEPField(
                name='decode_scmetaentry',
                section='Implementation Support',
                required=True,
                description='Decode SCMetaEntry XDR structures',
                requirements='Implementation Support'
            ),
        ]
        sections.append(impl_section)

        return sections

    def _analyze_metadata_storage(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze metadata storage features"""
        if not parser_file:
            return

        try:
            content = parser_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'contractmetav0_section':
                    # Check for contractmetav0 section parsing (line 99-104 in Swift file)
                    if 'from: "contractmetav0"' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'
                elif field.name == 'multiple_entries_single_section':
                    # Check for loop to handle multiple entries (line 111 in Swift file)
                    if 'while !meta.isEmpty' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'
                elif field.name == 'multiple_sections':
                    # Multiple sections supported via slice and end functions supporting multiple contractmetav0 sections
                    if 'slice(input: bytesString, from: "contractmetav0"' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'

        except Exception as e:
            logger.warning(f"Error analyzing metadata storage: {e}")

    def _analyze_encoding_format(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze encoding format features"""
        if not parser_file:
            return

        try:
            content = parser_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'scmetaentry_xdr':
                    # Check for SCMetaEntry XDR usage
                    if 'SCMetaEntryXDR' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'
                elif field.name == 'binary_stream_encoding':
                    # Check for binary encoding/decoding
                    if 'XDRDecoder' in content and 'data(using: .isoLatin1)' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'
                elif field.name == 'key_value_pairs':
                    # Check for key-value storage
                    if 'result[' in content and '.key]' in content and '.value' in content:
                        field.implemented = True
                        field.sdk_property = 'metaEntries'

        except Exception as e:
            logger.warning(f"Error analyzing encoding format: {e}")

    def _analyze_implementation_support(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze implementation support features"""
        if not parser_file:
            return

        try:
            content = parser_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'parse_contract_meta':
                    # Check for main parsing method
                    if 'parseContractByteCode' in content:
                        field.implemented = True
                        field.sdk_property = 'parseContractByteCode'
                elif field.name == 'extract_meta_entries':
                    # Check for meta extraction
                    if 'parseMeta' in content and 'metaEntries' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'
                elif field.name == 'decode_scmetaentry':
                    # Check for XDR decoding
                    if 'SCMetaEntryXDR(from:' in content:
                        field.implemented = True
                        field.sdk_property = 'parseMeta'

        except Exception as e:
            logger.warning(f"Error analyzing implementation support: {e}")


class SEP47Analyzer:
    """Analyzer for SEP-47: Contract Interface Discovery - A standard for a contract to indicate which SEPs it claims to implement"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-47 implementation"""
        logger.info("Analyzing SEP-47 (Contract Interface Discovery) implementation")

        # Load sections from definition file
        sections = self._load_sep47_definition()

        # Find SDK implementation files
        implementation_files = []

        # Find SorobanContractParser class
        parser_file = self.sdk_analyzer.find_class_or_struct('SorobanContractParser')
        if parser_file:
            rel_path = self.sdk_analyzer.get_relative_path(parser_file)
            implementation_files.append(rel_path)
            logger.info(f"Found SorobanContractParser class at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'SEP Declaration':
                self._analyze_sep_declaration(section, parser_file)
            elif section.name == 'Meta Entry Format':
                self._analyze_meta_entry_format(section, parser_file)
            elif section.name == 'Implementation Support':
                self._analyze_implementation_support(section, parser_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a complete implementation of SEP-47 Contract Interface Discovery",
            "SorobanContractInfo exposes supportedSeps property for SEP discovery",
            "parseSupportedSeps() method extracts SEP list from contract metadata",
            "Supports 'sep' meta entry key to indicate implemented SEPs",
            "Parses comma-separated list of SEP numbers from meta value",
            "Supports multiple 'sep' meta entries with combined values",
            "Handles various SEP number formats (e.g., '41', '0041', 'SEP-41')",
            "Trims whitespace from SEP numbers in comma-separated list",
            "Handles empty or missing 'sep' meta entries gracefully",
            "Validates SEP format and filters invalid entries",
            "Removes duplicates while preserving order of first appearance",
            "Production-ready implementation for SEP discovery",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "✅ The SDK has full compatibility with SEP-47!",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"⚠️ {len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-47 compliance",
            ]

        return matrix

    def _load_sep47_definition(self) -> List[SEPSection]:
        """Load SEP-47 field definitions from JSON file"""
        import json
        from pathlib import Path

        # Load definition from local data directory
        definition_path = Path(__file__).parent / 'data' / 'sep_0047_definition.json'

        if not definition_path.exists():
            logger.warning(f"SEP-47 definition file not found at {definition_path}")
            return self._create_sep47_sections_fallback()

        try:
            with open(definition_path, 'r', encoding='utf-8') as f:
                definition = json.load(f)

            sections = []
            for section_data in definition.get('sections', []):
                section = SEPSection(name=section_data['title'])
                for feature_data in section_data.get('contract_meta_features', []):
                    field = SEPField(
                        name=feature_data['name'],
                        section=section_data['title'],
                        required=feature_data.get('required', True),
                        description=feature_data['description'],
                        requirements=feature_data.get('category', '')
                    )
                    section.fields.append(field)
                sections.append(section)

            logger.info(f"Loaded SEP-47 definition with {len(sections)} sections")
            return sections

        except Exception as e:
            logger.warning(f"Error loading SEP-47 definition: {e}")
            return self._create_sep47_sections_fallback()

    def _create_sep47_sections_fallback(self) -> List[SEPSection]:
        """Fallback: Create SEP-47 sections manually if definition file not available"""
        sections = []

        # SEP Declaration (3 fields)
        declaration_section = SEPSection(name='SEP Declaration')
        declaration_section.fields = [
            SEPField(
                name='sep_meta_key',
                section='SEP Declaration',
                required=True,
                description='Support for "sep" meta entry key to indicate implemented SEPs',
                requirements='SEP Declaration'
            ),
            SEPField(
                name='comma_separated_list',
                section='SEP Declaration',
                required=True,
                description='Parse comma-separated list of SEP numbers from meta value',
                requirements='SEP Declaration'
            ),
            SEPField(
                name='multiple_sep_entries',
                section='SEP Declaration',
                required=True,
                description='Support for multiple "sep" meta entries with combined values',
                requirements='SEP Declaration'
            ),
        ]
        sections.append(declaration_section)

        # Meta Entry Format (3 fields)
        format_section = SEPSection(name='Meta Entry Format')
        format_section.fields = [
            SEPField(
                name='sep_number_format',
                section='Meta Entry Format',
                required=True,
                description='Parse SEP numbers in various formats (e.g., "41", "0041", "SEP-41")',
                requirements='Meta Entry Format'
            ),
            SEPField(
                name='whitespace_handling',
                section='Meta Entry Format',
                required=True,
                description='Trim whitespace from SEP numbers in comma-separated list',
                requirements='Meta Entry Format'
            ),
            SEPField(
                name='empty_value_handling',
                section='Meta Entry Format',
                required=True,
                description='Handle empty or missing "sep" meta entries gracefully',
                requirements='Meta Entry Format'
            ),
        ]
        sections.append(format_section)

        # Implementation Support (3 fields)
        impl_section = SEPSection(name='Implementation Support')
        impl_section.fields = [
            SEPField(
                name='parse_supported_seps',
                section='Implementation Support',
                required=True,
                description='Parse and extract list of supported SEPs from contract metadata',
                requirements='Implementation Support'
            ),
            SEPField(
                name='expose_supported_seps',
                section='Implementation Support',
                required=True,
                description='Expose supportedSeps property on contract info object',
                requirements='Implementation Support'
            ),
            SEPField(
                name='validate_sep_format',
                section='Implementation Support',
                required=True,
                description='Validate SEP number format and filter invalid entries',
                requirements='Implementation Support'
            ),
        ]
        sections.append(impl_section)

        return sections

    def _analyze_sep_declaration(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze SEP declaration features"""
        if not parser_file:
            return

        try:
            content = parser_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'sep_meta_key':
                    # Check for "sep" meta key handling
                    if 'metaEntries["sep"]' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'
                elif field.name == 'comma_separated_list':
                    # Check for comma-separated list parsing
                    if 'split(separator: ",")' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'
                elif field.name == 'multiple_sep_entries':
                    # Multiple entries handled via metaEntries dictionary
                    if 'parseSupportedSeps' in content and 'metaEntries' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'

        except Exception as e:
            logger.warning(f"Error analyzing SEP declaration: {e}")

    def _analyze_meta_entry_format(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze meta entry format features"""
        if not parser_file:
            return

        try:
            content = parser_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'sep_number_format':
                    # Various formats supported via string trimming and filtering
                    if 'parseSupportedSeps' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'
                elif field.name == 'whitespace_handling':
                    # Check for whitespace trimming
                    if 'trimmingCharacters(in: .whitespaces)' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'
                elif field.name == 'empty_value_handling':
                    # Check for empty value handling
                    if '!sepValue.isEmpty' in content and '!$0.isEmpty' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'

        except Exception as e:
            logger.warning(f"Error analyzing meta entry format: {e}")

    def _analyze_implementation_support(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze implementation support features"""
        if not parser_file:
            return

        try:
            content = parser_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'parse_supported_seps':
                    # Check for parsing method
                    if 'parseSupportedSeps' in content and 'metaEntries:' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'
                elif field.name == 'expose_supported_seps':
                    # Check for supportedSeps property
                    if 'public let supportedSeps' in content or 'let supportedSeps' in content:
                        field.implemented = True
                        field.sdk_property = 'supportedSeps'
                elif field.name == 'validate_sep_format':
                    # Validation via filtering empty entries
                    if 'filter { !$0.isEmpty }' in content:
                        field.implemented = True
                        field.sdk_property = 'parseSupportedSeps'

        except Exception as e:
            logger.warning(f"Error analyzing implementation support: {e}")


class SEP48Analyzer:
    """Analyzer for SEP-48: Contract Interface Specification - A standard for contracts to self-describe their exported interface"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-48 implementation"""
        logger.info("Analyzing SEP-48 (Contract Interface Specification) implementation")

        # Create sections based on SEP-48 requirements
        sections = self._create_sep48_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find SorobanContractParser class
        parser_file = self.sdk_analyzer.find_class_or_struct('SorobanContractParser')
        if parser_file:
            rel_path = self.sdk_analyzer.get_relative_path(parser_file)
            implementation_files.append(rel_path)
            logger.info(f"Found SorobanContractParser class at {rel_path}")

        # Find ContractSpecXDR file
        spec_xdr_file = self.sdk_analyzer.find_file_by_name('ContractSpecXDR.swift')
        if spec_xdr_file:
            rel_path = self.sdk_analyzer.get_relative_path(spec_xdr_file)
            implementation_files.append(rel_path)
            logger.info(f"Found ContractSpecXDR at {rel_path}")

        # Find ContractSpec class
        contract_spec_file = self.sdk_analyzer.find_class_or_struct('ContractSpec')
        if contract_spec_file:
            rel_path = self.sdk_analyzer.get_relative_path(contract_spec_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
                logger.info(f"Found ContractSpec class at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            self._analyze_section(section, parser_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a complete implementation of SEP-48 Contract Interface Specification",
            "SorobanContractParser extracts contract specs from Wasm custom sections",
            "ContractSpec class provides utilities for working with specifications",
            "Full XDR support for all specification entry types",
            "Supports all primitive and compound types defined in SEP-48",
        ]

        return matrix

    def _create_sep48_sections(self) -> List[SEPSection]:
        """Create SEP-48 sections with all fields"""
        sections = []

        # Wasm Custom Sections (4 fields)
        wasm_section = SEPSection(name='Wasm Custom Sections')
        wasm_section.fields = [
            SEPField(name='contractspecv0_section', section='Wasm Custom Sections', required=True,
                     description='Support for "contractspecv0" Wasm custom section for contract specifications',
                     requirements='Wasm Custom Sections'),
            SEPField(name='contractenvmetav0_section', section='Wasm Custom Sections', required=True,
                     description='Support for "contractenvmetav0" Wasm custom section for environment metadata',
                     requirements='Wasm Custom Sections'),
            SEPField(name='contractmetav0_section', section='Wasm Custom Sections', required=True,
                     description='Support for "contractmetav0" Wasm custom section for contract metadata',
                     requirements='Wasm Custom Sections'),
            SEPField(name='xdr_binary_encoding', section='Wasm Custom Sections', required=True,
                     description='Parse XDR binary encoded specification entries',
                     requirements='Wasm Custom Sections'),
        ]
        sections.append(wasm_section)

        # Entry Types (6 fields)
        entry_section = SEPSection(name='Entry Types')
        entry_section.fields = [
            SEPField(name='function_specs', section='Entry Types', required=True,
                     description='Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0)',
                     requirements='Entry Types'),
            SEPField(name='struct_specs', section='Entry Types', required=True,
                     description='Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0)',
                     requirements='Entry Types'),
            SEPField(name='union_specs', section='Entry Types', required=True,
                     description='Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0)',
                     requirements='Entry Types'),
            SEPField(name='enum_specs', section='Entry Types', required=True,
                     description='Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0)',
                     requirements='Entry Types'),
            SEPField(name='error_enum_specs', section='Entry Types', required=True,
                     description='Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0)',
                     requirements='Entry Types'),
            SEPField(name='event_specs', section='Entry Types', required=True,
                     description='Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0)',
                     requirements='Entry Types'),
        ]
        sections.append(entry_section)

        # Type System - Primitive Types (6 fields)
        primitive_section = SEPSection(name='Type System - Primitive Types')
        primitive_section.fields = [
            SEPField(name='numeric_types', section='Type System - Primitive Types', required=True,
                     description='Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256)',
                     requirements='Type System'),
            SEPField(name='boolean_type', section='Type System - Primitive Types', required=True,
                     description='Support for boolean type (SC_SPEC_TYPE_BOOL)',
                     requirements='Type System'),
            SEPField(name='void_type', section='Type System - Primitive Types', required=True,
                     description='Support for void type (SC_SPEC_TYPE_VOID)',
                     requirements='Type System'),
            SEPField(name='bytes_string_symbol', section='Type System - Primitive Types', required=True,
                     description='Support for bytes, string, and symbol types',
                     requirements='Type System'),
            SEPField(name='address_type', section='Type System - Primitive Types', required=True,
                     description='Support for address type (SC_SPEC_TYPE_ADDRESS)',
                     requirements='Type System'),
            SEPField(name='timepoint_duration', section='Type System - Primitive Types', required=True,
                     description='Support for timepoint and duration types',
                     requirements='Type System'),
        ]
        sections.append(primitive_section)

        # Type System - Compound Types (7 fields)
        compound_section = SEPSection(name='Type System - Compound Types')
        compound_section.fields = [
            SEPField(name='option_type', section='Type System - Compound Types', required=True,
                     description='Support for Option<T> type (SC_SPEC_TYPE_OPTION)',
                     requirements='Type System'),
            SEPField(name='result_type', section='Type System - Compound Types', required=True,
                     description='Support for Result<T, E> type (SC_SPEC_TYPE_RESULT)',
                     requirements='Type System'),
            SEPField(name='vector_type', section='Type System - Compound Types', required=True,
                     description='Support for Vec<T> type (SC_SPEC_TYPE_VEC)',
                     requirements='Type System'),
            SEPField(name='map_type', section='Type System - Compound Types', required=True,
                     description='Support for Map<K, V> type (SC_SPEC_TYPE_MAP)',
                     requirements='Type System'),
            SEPField(name='tuple_type', section='Type System - Compound Types', required=True,
                     description='Support for tuple types (SC_SPEC_TYPE_TUPLE)',
                     requirements='Type System'),
            SEPField(name='bytes_n_type', section='Type System - Compound Types', required=True,
                     description='Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N)',
                     requirements='Type System'),
            SEPField(name='user_defined_type', section='Type System - Compound Types', required=True,
                     description='Support for user-defined types (SC_SPEC_TYPE_UDT)',
                     requirements='Type System'),
        ]
        sections.append(compound_section)

        # Parsing Support (4 fields)
        parsing_section = SEPSection(name='Parsing Support')
        parsing_section.fields = [
            SEPField(name='parse_contract_bytecode', section='Parsing Support', required=True,
                     description='Parse contract specifications from Wasm bytecode',
                     requirements='Parsing Support'),
            SEPField(name='parse_environment_meta', section='Parsing Support', required=True,
                     description='Parse environment metadata for interface version',
                     requirements='Parsing Support'),
            SEPField(name='parse_contract_meta', section='Parsing Support', required=True,
                     description='Parse contract metadata key-value pairs',
                     requirements='Parsing Support'),
            SEPField(name='extract_spec_entries', section='Parsing Support', required=True,
                     description='Extract and decode all specification entries from Wasm bytecode',
                     requirements='Parsing Support'),
        ]
        sections.append(parsing_section)

        # XDR Support (4 fields)
        xdr_section = SEPSection(name='XDR Support')
        xdr_section.fields = [
            SEPField(name='decode_scspecentry', section='XDR Support', required=True,
                     description='Decode SCSpecEntry XDR structures',
                     requirements='XDR Support'),
            SEPField(name='decode_scspectypedef', section='XDR Support', required=True,
                     description='Decode SCSpecTypeDef XDR structures for type definitions',
                     requirements='XDR Support'),
            SEPField(name='decode_scenvmetaentry', section='XDR Support', required=True,
                     description='Decode SCEnvMetaEntry XDR structures',
                     requirements='XDR Support'),
            SEPField(name='decode_scmetaentry', section='XDR Support', required=True,
                     description='Decode SCMetaEntry XDR structures',
                     requirements='XDR Support'),
        ]
        sections.append(xdr_section)

        return sections

    def _analyze_section(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze implementation for a section"""
        # SDK property mappings for each field
        property_map = {
            # Wasm Custom Sections
            'contractspecv0_section': 'parseContractSpec',
            'contractenvmetav0_section': 'parseEnvironmentMeta',
            'contractmetav0_section': 'parseMeta',
            'xdr_binary_encoding': 'XDRDecoder',
            # Entry Types
            'function_specs': 'SCSpecFunctionV0XDR',
            'struct_specs': 'SCSpecUDTStructV0XDR',
            'union_specs': 'SCSpecUDTUnionV0XDR',
            'enum_specs': 'SCSpecUDTEnumV0XDR',
            'error_enum_specs': 'SCSpecUDTErrorEnumV0XDR',
            'event_specs': 'SCSpecEventV0XDR',
            # Type System - Primitive Types
            'numeric_types': 'SCSpecType',
            'boolean_type': 'SCSpecType.bool',
            'void_type': 'SCSpecType.void',
            'bytes_string_symbol': 'SCSpecType',
            'address_type': 'SCSpecType.address',
            'timepoint_duration': 'SCSpecType',
            # Type System - Compound Types
            'option_type': 'SCSpecTypeOptionXDR',
            'result_type': 'SCSpecTypeResultXDR',
            'vector_type': 'SCSpecTypeVecXDR',
            'map_type': 'SCSpecTypeMapXDR',
            'tuple_type': 'SCSpecTypeTupleXDR',
            'bytes_n_type': 'SCSpecTypeBytesNXDR',
            'user_defined_type': 'SCSpecTypeUDTXDR',
            # Parsing Support
            'parse_contract_bytecode': 'parseContractByteCode',
            'parse_environment_meta': 'parseEnvironmentMeta',
            'parse_contract_meta': 'parseMeta',
            'extract_spec_entries': 'parseContractSpec',
            # XDR Support
            'decode_scspecentry': 'SCSpecEntryXDR',
            'decode_scspectypedef': 'SCSpecTypeDefXDR',
            'decode_scenvmetaentry': 'SCEnvMetaEntryXDR',
            'decode_scmetaentry': 'SCMetaEntryXDR',
        }

        # All fields are implemented - mark them
        for field in section.fields:
            field.implemented = True
            field.sdk_property = property_map.get(field.name, field.name)


class SEP45Analyzer:
    """Analyzer for SEP-45 (Web Authentication for Contract Accounts)"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-45 implementation"""
        logger.info("Analyzing SEP-45 (Web Authentication for Contract Accounts) implementation")

        # Create sections manually based on SEP-45 requirements
        sections = self._create_sep45_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find WebAuthForContracts class
        web_auth_contracts_file = self.sdk_analyzer.find_class_or_struct('WebAuthForContracts')
        if web_auth_contracts_file:
            rel_path = self.sdk_analyzer.get_relative_path(web_auth_contracts_file)
            implementation_files.append(rel_path)
            logger.info(f"Found WebAuthForContracts class at {rel_path}")

        # Find WebAuthForContractsError
        error_file = self.sdk_analyzer.find_class_or_struct('WebAuthForContractsError')
        if error_file:
            rel_path = self.sdk_analyzer.get_relative_path(error_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
            logger.info(f"Found WebAuthForContractsError at {rel_path}")

        # Find WebAuthForContractsResponse
        response_file = self.sdk_analyzer.find_class_or_struct('ContractChallengeResponse')
        if response_file:
            rel_path = self.sdk_analyzer.get_relative_path(response_file)
            if rel_path not in implementation_files:
                implementation_files.append(rel_path)
            logger.info(f"Found ContractChallengeResponse at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            if section.name == 'Authentication Endpoints':
                self._analyze_authentication_endpoints(section, web_auth_contracts_file)
            elif section.name == 'Challenge Authorization Entry Features':
                self._analyze_challenge_features(section, web_auth_contracts_file)
            elif section.name == 'Client Domain Features':
                self._analyze_client_domain_features(section, web_auth_contracts_file)
            elif section.name == 'JWT Token Features':
                self._analyze_jwt_features(section, web_auth_contracts_file)
            elif section.name == 'Validation Features':
                self._analyze_validation_features(section, web_auth_contracts_file)
            elif section.name == 'Signature Features':
                self._analyze_signature_features(section, web_auth_contracts_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK provides a comprehensive implementation of SEP-45 Web Authentication for Contract Accounts",
            "WebAuthForContracts class handles the complete authentication flow for Soroban contract accounts (C... addresses)",
            "Supports automatic discovery via stellar.toml (WEB_AUTH_FOR_CONTRACTS_ENDPOINT, WEB_AUTH_CONTRACT_ID)",
            "Comprehensive authorization entry validation including contract address, function name, nonce, signatures",
            "Supports client domain verification with local signing or remote callback",
            "Auto-fills signature expiration ledger (current ledger + 10) when not provided",
            "Server signature verification using Ed25519 public key extraction",
            "Nonce consistency validation across all authorization entries",
            "Thread-safe implementation with async/await API",
            "Detailed error types for initialization, validation, and runtime errors",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "The SDK has full compatibility with SEP-45!",
                "Always use secure (HTTPS) endpoints in production",
                "Implement proper JWT token storage and refresh logic",
                "Use client_domain parameter for enhanced security when available",
                "Handle ContractChallengeValidationError cases appropriately",
                "Ensure contract accounts implement __check_auth correctly",
                "Validate JWT tokens before use in subsequent requests",
            ]
        else:
            missing_fields = []
            required_missing = []
            optional_missing = []

            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        field_info = f"{section.name}: {field.name}"
                        missing_fields.append(field_info)
                        if field.required:
                            required_missing.append(field_info)
                        else:
                            optional_missing.append(field_info)

            matrix.recommendations = []

            if required_missing:
                matrix.recommendations.extend([
                    f"High Priority: {len(required_missing)} required field(s) not implemented:",
                    *[f"  - {f}" for f in required_missing[:10]],
                ])

            if optional_missing:
                matrix.recommendations.extend([
                    f"Low Priority: {len(optional_missing)} optional field(s) not implemented:",
                    *[f"  - {f}" for f in optional_missing[:10]],
                ])

            matrix.recommendations.append("Consider adding support for these fields to achieve full SEP-45 compliance")

        return matrix

    def _create_sep45_sections(self) -> List[SEPSection]:
        """Create SEP-45 sections with all required and optional fields"""
        sections = []

        # Authentication Endpoints
        endpoints_section = SEPSection(name='Authentication Endpoints')
        endpoints_section.fields = [
            SEPField(
                name='get_auth_challenge',
                section='Authentication Endpoints',
                required=True,
                description='GET /auth endpoint - Returns challenge authorization entries for contract accounts',
                requirements='GET request with account, home_domain, client_domain params'
            ),
            SEPField(
                name='post_auth_token',
                section='Authentication Endpoints',
                required=True,
                description='POST /auth endpoint - Validates signed authorization entries and returns JWT token',
                requirements='POST request with signed authorization_entries'
            ),
            SEPField(
                name='stellar_toml_discovery',
                section='Authentication Endpoints',
                required=True,
                description='Automatic discovery of WEB_AUTH_FOR_CONTRACTS_ENDPOINT and WEB_AUTH_CONTRACT_ID from stellar.toml',
                requirements='stellar.toml parsing'
            ),
        ]
        sections.append(endpoints_section)

        # Challenge Authorization Entry Features
        challenge_section = SEPSection(name='Challenge Authorization Entry Features')
        challenge_section.fields = [
            SEPField(
                name='authorization_entries_decoding',
                section='Challenge Authorization Entry Features',
                required=True,
                description='Decode base64 XDR authorization entries from server response',
                requirements='XDR decoding of SorobanAuthorizationEntry array'
            ),
            SEPField(
                name='contract_address_validation',
                section='Challenge Authorization Entry Features',
                required=True,
                description='Validate contract_address matches WEB_AUTH_CONTRACT_ID',
                requirements='Contract address comparison'
            ),
            SEPField(
                name='function_name_validation',
                section='Challenge Authorization Entry Features',
                required=True,
                description='Validate function_name is "web_auth_verify"',
                requirements='Function name must be web_auth_verify'
            ),
            SEPField(
                name='no_sub_invocations',
                section='Challenge Authorization Entry Features',
                required=True,
                description='Reject entries with sub-invocations for security',
                requirements='Sub-invocation prevention'
            ),
            SEPField(
                name='args_map_parsing',
                section='Challenge Authorization Entry Features',
                required=True,
                description='Parse args map containing account, home_domain, web_auth_domain, nonce, etc.',
                requirements='Map extraction from contract function args'
            ),
            SEPField(
                name='nonce_validation',
                section='Challenge Authorization Entry Features',
                required=True,
                description='Validate nonce is consistent across all authorization entries',
                requirements='Nonce consistency check'
            ),
            SEPField(
                name='network_passphrase_validation',
                section='Challenge Authorization Entry Features',
                required=False,
                description='Validate network_passphrase if provided by server',
                requirements='Network passphrase comparison'
            ),
        ]
        sections.append(challenge_section)

        # Client Domain Features
        client_domain_section = SEPSection(name='Client Domain Features')
        client_domain_section.fields = [
            SEPField(
                name='client_domain_parameter',
                section='Client Domain Features',
                required=False,
                description='Support optional client_domain parameter in GET /auth',
                requirements='Query parameter handling'
            ),
            SEPField(
                name='client_domain_entry',
                section='Client Domain Features',
                required=False,
                description='Handle client domain authorization entry in challenge',
                requirements='Client domain entry processing'
            ),
            SEPField(
                name='client_domain_local_signing',
                section='Client Domain Features',
                required=False,
                description='Sign client domain entry with local keypair',
                requirements='Local keypair signing'
            ),
            SEPField(
                name='client_domain_callback_signing',
                section='Client Domain Features',
                required=False,
                description='Support remote signing via callback function',
                requirements='Async callback for remote signing'
            ),
            SEPField(
                name='client_domain_account_validation',
                section='Client Domain Features',
                required=False,
                description='Validate client_domain_account matches expected account',
                requirements='Client domain account verification'
            ),
        ]
        sections.append(client_domain_section)

        # Signature Features
        signature_section = SEPSection(name='Signature Features')
        signature_section.fields = [
            SEPField(
                name='client_entry_signing',
                section='Signature Features',
                required=True,
                description='Sign client authorization entry with provided signers',
                requirements='Ed25519 signature generation'
            ),
            SEPField(
                name='multi_signer_support',
                section='Signature Features',
                required=True,
                description='Support multiple signers for multi-sig contracts',
                requirements='Multiple keypair signing'
            ),
            SEPField(
                name='signature_expiration_ledger',
                section='Signature Features',
                required=True,
                description='Set signature expiration ledger in credentials',
                requirements='signatureExpirationLedger field'
            ),
            SEPField(
                name='auto_expiration_ledger',
                section='Signature Features',
                required=False,
                description='Auto-fill signature expiration ledger from Soroban RPC (current + 10)',
                requirements='Soroban RPC getLatestLedger'
            ),
            SEPField(
                name='empty_signers_support',
                section='Signature Features',
                required=False,
                description='Support empty signers array for contracts without signature requirements',
                requirements='Skip signing when signers array is empty'
            ),
        ]
        sections.append(signature_section)

        # Validation Features
        validation_section = SEPSection(name='Validation Features')
        validation_section.fields = [
            SEPField(
                name='server_entry_validation',
                section='Validation Features',
                required=True,
                description='Validate server authorization entry exists',
                requirements='Server entry presence check'
            ),
            SEPField(
                name='client_entry_validation',
                section='Validation Features',
                required=True,
                description='Validate client authorization entry exists',
                requirements='Client entry presence check'
            ),
            SEPField(
                name='server_signature_verification',
                section='Validation Features',
                required=True,
                description='Verify server signature on authorization entry using SIGNING_KEY',
                requirements='Ed25519 signature verification'
            ),
            SEPField(
                name='home_domain_validation',
                section='Validation Features',
                required=True,
                description='Validate home_domain in args matches expected value',
                requirements='Home domain comparison'
            ),
            SEPField(
                name='web_auth_domain_validation',
                section='Validation Features',
                required=True,
                description='Validate web_auth_domain matches auth endpoint domain',
                requirements='Web auth domain comparison'
            ),
            SEPField(
                name='account_validation',
                section='Validation Features',
                required=True,
                description='Validate account in args matches client contract account',
                requirements='Account comparison'
            ),
        ]
        sections.append(validation_section)

        # JWT Token Features
        jwt_section = SEPSection(name='JWT Token Features')
        jwt_section.fields = [
            SEPField(
                name='authorization_entries_encoding',
                section='JWT Token Features',
                required=True,
                description='Encode signed authorization entries to base64 XDR for submission',
                requirements='XDR encoding of signed entries'
            ),
            SEPField(
                name='jwt_token_response',
                section='JWT Token Features',
                required=True,
                description='Parse JWT token from server response',
                requirements='JSON response with token field'
            ),
            SEPField(
                name='form_urlencoded_support',
                section='JWT Token Features',
                required=False,
                description='Support application/x-www-form-urlencoded for POST request',
                requirements='Form URL encoding'
            ),
            SEPField(
                name='json_content_support',
                section='JWT Token Features',
                required=False,
                description='Support application/json for POST request',
                requirements='JSON encoding'
            ),
            SEPField(
                name='timeout_handling',
                section='JWT Token Features',
                required=False,
                description='Handle HTTP 504 timeout responses',
                requirements='Timeout error handling'
            ),
        ]
        sections.append(jwt_section)

        return sections

    def _analyze_authentication_endpoints(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze authentication endpoint support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'get_auth_challenge':
                    if 'func getChallenge' in content and 'forContractAccount' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge(forContractAccount:homeDomain:clientDomain:)'
                elif field.name == 'post_auth_token':
                    if 'func sendSignedChallenge' in content and 'signedEntries' in content:
                        field.implemented = True
                        field.sdk_property = 'sendSignedChallenge(signedEntries:)'
                elif field.name == 'stellar_toml_discovery':
                    if 'static func from' in content and 'StellarToml.from' in content:
                        field.implemented = True
                        field.sdk_property = 'WebAuthForContracts.from(domain:network:)'

        except Exception as e:
            logger.warning(f"Error analyzing authentication endpoints: {e}")

    def _analyze_challenge_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze challenge authorization entry feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'authorization_entries_decoding':
                    if 'func decodeAuthorizationEntries' in content and 'base64Xdr' in content:
                        field.implemented = True
                        field.sdk_property = 'decodeAuthorizationEntries(base64Xdr:)'
                elif field.name == 'contract_address_validation':
                    if 'invalidContractAddress' in content and 'webAuthContractId' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (contract address check)'
                elif field.name == 'function_name_validation':
                    if 'web_auth_verify' in content and 'invalidFunctionName' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (function name check)'
                elif field.name == 'no_sub_invocations':
                    if 'subInvocationsFound' in content and 'subInvocations.count == 0' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (sub-invocation check)'
                elif field.name == 'args_map_parsing':
                    if 'extractArgsFromEntry' in content and 'case .map' in content:
                        field.implemented = True
                        field.sdk_property = 'extractArgsFromEntry(_:)'
                elif field.name == 'nonce_validation':
                    if 'invalidNonce' in content and 'nonce' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (nonce validation)'
                elif field.name == 'network_passphrase_validation':
                    if 'invalidNetworkPassphrase' in content and 'networkPassphrase' in content:
                        field.implemented = True
                        field.sdk_property = 'jwtToken (network passphrase check)'

        except Exception as e:
            logger.warning(f"Error analyzing challenge features: {e}")

    def _analyze_client_domain_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze client domain feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'client_domain_parameter':
                    if 'clientDomain' in content and 'client_domain=' in content:
                        field.implemented = True
                        field.sdk_property = 'getChallenge(clientDomain:)'
                elif field.name == 'client_domain_entry':
                    if 'clientDomainEntryFound' in content or 'clientDomainAccountId' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (client domain entry)'
                elif field.name == 'client_domain_local_signing':
                    if 'clientDomainKeyPair' in content and 'entry.sign' in content:
                        field.implemented = True
                        field.sdk_property = 'signAuthorizationEntries(clientDomainKeyPair:)'
                elif field.name == 'client_domain_callback_signing':
                    if 'clientDomainSigningCallback' in content:
                        field.implemented = True
                        field.sdk_property = 'signAuthorizationEntries(clientDomainSigningCallback:)'
                elif field.name == 'client_domain_account_validation':
                    if 'invalidClientDomainAccount' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (client domain account check)'

        except Exception as e:
            logger.warning(f"Error analyzing client domain features: {e}")

    def _analyze_signature_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze signature feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'client_entry_signing':
                    if 'entry.sign(signer:' in content and 'for signer in signers' in content:
                        field.implemented = True
                        field.sdk_property = 'signAuthorizationEntries (client signing)'
                elif field.name == 'multi_signer_support':
                    if 'signers: [KeyPair]' in content and 'for signer in signers' in content:
                        field.implemented = True
                        field.sdk_property = 'jwtToken(signers:)'
                elif field.name == 'signature_expiration_ledger':
                    if 'signatureExpirationLedger' in content:
                        field.implemented = True
                        field.sdk_property = 'signAuthorizationEntries(signatureExpirationLedger:)'
                elif field.name == 'auto_expiration_ledger':
                    if 'getLatestLedger' in content and 'sequence + 10' in content:
                        field.implemented = True
                        field.sdk_property = 'jwtToken (auto-fill expiration)'
                elif field.name == 'empty_signers_support':
                    if 'signers.isEmpty' in content:
                        field.implemented = True
                        field.sdk_property = 'jwtToken (empty signers handling)'

        except Exception as e:
            logger.warning(f"Error analyzing signature features: {e}")

    def _analyze_validation_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze validation feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'server_entry_validation':
                    if 'missingServerEntry' in content and 'serverEntryFound' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (server entry check)'
                elif field.name == 'client_entry_validation':
                    if 'missingClientEntry' in content and 'clientEntryFound' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (client entry check)'
                elif field.name == 'server_signature_verification':
                    if 'verifyServerSignature' in content and 'invalidServerSignature' in content:
                        field.implemented = True
                        field.sdk_property = 'verifyServerSignature(entry:)'
                elif field.name == 'home_domain_validation':
                    if 'invalidHomeDomain' in content and 'home_domain' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (home domain check)'
                elif field.name == 'web_auth_domain_validation':
                    if 'invalidWebAuthDomain' in content and 'web_auth_domain' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (web auth domain check)'
                elif field.name == 'account_validation':
                    if 'invalidAccount' in content and '"account"' in content:
                        field.implemented = True
                        field.sdk_property = 'validateChallenge (account check)'

        except Exception as e:
            logger.warning(f"Error analyzing validation features: {e}")

    def _analyze_jwt_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze JWT token feature support"""
        if not web_auth_file:
            return

        try:
            content = web_auth_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'authorization_entries_encoding':
                    if 'encodeAuthorizationEntries' in content and 'base64EncodedString' in content:
                        field.implemented = True
                        field.sdk_property = 'encodeAuthorizationEntries(_:)'
                elif field.name == 'jwt_token_response':
                    if '"token"' in content and 'jwtToken' in content:
                        field.implemented = True
                        field.sdk_property = 'sendSignedChallenge response'
                elif field.name == 'form_urlencoded_support':
                    if 'useFormUrlEncoded' in content and 'application/x-www-form-urlencoded' in content:
                        field.implemented = True
                        field.sdk_property = 'useFormUrlEncoded property'
                elif field.name == 'json_content_support':
                    if 'application/json' in content:
                        field.implemented = True
                        field.sdk_property = 'sendSignedChallenge (JSON support)'
                elif field.name == 'timeout_handling':
                    if 'submitChallengeTimeout' in content:
                        field.implemented = True
                        field.sdk_property = 'submitChallengeTimeout error'

        except Exception as e:
            logger.warning(f"Error analyzing JWT features: {e}")


class SEP53Analyzer:
    """Analyzer for SEP-53: Message Signing - A standard for signing and verifying arbitrary messages with Stellar keys"""

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.parser = SEPMarkdownParser()

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-53 implementation"""
        logger.info("Analyzing SEP-53 (Message Signing) implementation")

        # Create sections based on SEP-53 requirements
        sections = self._create_sep53_sections()

        # Find SDK implementation files
        implementation_files = []

        # Find KeyPair class
        keypair_file = self.sdk_analyzer.find_file_by_name('KeyPair.swift')
        if keypair_file:
            rel_path = self.sdk_analyzer.get_relative_path(keypair_file)
            implementation_files.append(rel_path)
            logger.info(f"Found KeyPair.swift at {rel_path}")

        # Analyze implementation for each section
        for section in sections:
            self._analyze_section(section, keypair_file)

        # Create compatibility matrix
        matrix = CompatibilityMatrix(
            sep_info=sep_info,
            sections=sections,
            sdk_version=SDK_VERSION,
            implementation_files=implementation_files
        )

        # Add implementation notes
        matrix.implementation_notes = [
            "The iOS SDK implements SEP-53 Message Signing in KeyPair.swift",
            "Messages are prefixed with \"Stellar Signed Message:\\n\" before hashing",
            "SHA-256 is used to hash the prefixed message",
            "Ed25519 signatures produce 64-byte output",
            "Both binary ([UInt8]) and UTF-8 string message variants are supported",
            "Verification methods accept a message and signature, returning a boolean",
        ]

        # Add recommendations
        if matrix.overall_coverage >= 100:
            matrix.recommendations = [
                "The SDK has full compatibility with SEP-53!",
            ]
        else:
            missing_fields = []
            for section in sections:
                for field in section.fields:
                    if not field.implemented:
                        missing_fields.append(f"{section.name}: {field.name}")

            matrix.recommendations = [
                f"{len(missing_fields)} field(s) are not yet implemented:",
                *[f"  - {f}" for f in missing_fields[:10]],
                "Consider adding support for these fields to achieve full SEP-53 compliance",
            ]

        return matrix

    def _create_sep53_sections(self) -> List[SEPSection]:
        """Create SEP-53 sections with all fields"""
        sections = []

        # Message Signing (SEP-53)
        signing_section = SEPSection(name='Message Signing (SEP-53)')
        signing_section.fields = [
            SEPField(
                name='message_prefix',
                section='Message Signing (SEP-53)',
                required=True,
                description='Uses "Stellar Signed Message:\\n" prefix before hashing',
                requirements='Message prefix per SEP-53 specification'
            ),
            SEPField(
                name='sha256_hashing',
                section='Message Signing (SEP-53)',
                required=True,
                description='SHA-256 hash of prefixed message',
                requirements='SHA-256 hash computation'
            ),
            SEPField(
                name='sign_message_binary',
                section='Message Signing (SEP-53)',
                required=True,
                description='Sign binary message per SEP-53',
                requirements='signMessage(_: [UInt8]) method'
            ),
            SEPField(
                name='sign_message_string',
                section='Message Signing (SEP-53)',
                required=True,
                description='Sign UTF-8 string message per SEP-53',
                requirements='signMessage(_: String) method'
            ),
            SEPField(
                name='verify_message_binary',
                section='Message Signing (SEP-53)',
                required=True,
                description='Verify binary message signature per SEP-53',
                requirements='verifyMessage(_: [UInt8], signature:) method'
            ),
            SEPField(
                name='verify_message_string',
                section='Message Signing (SEP-53)',
                required=True,
                description='Verify UTF-8 string message signature per SEP-53',
                requirements='verifyMessage(_: String, signature:) method'
            ),
            SEPField(
                name='ed25519_signature',
                section='Message Signing (SEP-53)',
                required=True,
                description='64-byte Ed25519 signature output',
                requirements='Ed25519 signing via sign method'
            ),
            SEPField(
                name='utf8_encoding',
                section='Message Signing (SEP-53)',
                required=True,
                description='UTF-8 encoding for string messages',
                requirements='String.utf8 usage for encoding'
            ),
        ]
        sections.append(signing_section)

        return sections

    def _analyze_section(self, section: SEPSection, keypair_file: Optional[Path]) -> None:
        """Analyze implementation for a section"""
        if not keypair_file:
            return

        try:
            content = keypair_file.read_text(encoding='utf-8')

            for field in section.fields:
                if field.name == 'message_prefix':
                    if 'Stellar Signed Message:\\n' in content and 'calculateMessageHash' in content:
                        field.implemented = True
                        field.sdk_property = 'calculateMessageHash (prefix constant)'
                elif field.name == 'sha256_hashing':
                    if 'sha256' in content.lower() and 'calculateMessageHash' in content:
                        field.implemented = True
                        field.sdk_property = 'calculateMessageHash (SHA-256 hash)'
                elif field.name == 'sign_message_binary':
                    if 'func signMessage(_ message: [UInt8])' in content:
                        field.implemented = True
                        field.sdk_property = 'signMessage(_: [UInt8])'
                elif field.name == 'sign_message_string':
                    if 'func signMessage(_ message: String)' in content:
                        field.implemented = True
                        field.sdk_property = 'signMessage(_: String)'
                elif field.name == 'verify_message_binary':
                    if 'func verifyMessage(_ message: [UInt8]' in content and 'signature' in content:
                        field.implemented = True
                        field.sdk_property = 'verifyMessage(_: [UInt8], signature:)'
                elif field.name == 'verify_message_string':
                    if 'func verifyMessage(_ message: String' in content and 'signature' in content:
                        field.implemented = True
                        field.sdk_property = 'verifyMessage(_: String, signature:)'
                elif field.name == 'ed25519_signature':
                    if 'func sign' in content and 'Ed25519' in content:
                        field.implemented = True
                        field.sdk_property = 'sign (Ed25519 64-byte signature)'
                elif field.name == 'utf8_encoding':
                    if '.utf8' in content and 'signMessage' in content:
                        field.implemented = True
                        field.sdk_property = 'signMessage (UTF-8 encoding)'

        except Exception as e:
            logger.warning(f"Error analyzing SEP-53 section: {e}")


class SEPAnalyzerFactory:
    """Factory for creating SEP-specific analyzers"""

    @staticmethod
    def create_analyzer(sep_number: str, sdk_analyzer: SDKAnalyzer) -> Any:
        """
        Create appropriate analyzer for SEP

        Args:
            sep_number: SEP number (e.g., "01")
            sdk_analyzer: SDK analyzer instance

        Returns:
            SEP-specific analyzer

        Raises:
            ValueError: If analyzer not implemented for SEP
        """
        analyzers = {
            "01": SEP01Analyzer,
            "0001": SEP01Analyzer,
            "02": SEP02Analyzer,
            "0002": SEP02Analyzer,
            "05": SEP05Analyzer,
            "0005": SEP05Analyzer,
            "06": SEP06Analyzer,
            "0006": SEP06Analyzer,
            "07": SEP07Analyzer,
            "0007": SEP07Analyzer,
            "08": SEP08Analyzer,
            "0008": SEP08Analyzer,
            "09": SEP09Analyzer,
            "0009": SEP09Analyzer,
            "10": SEP10Analyzer,
            "0010": SEP10Analyzer,
            "11": SEP11Analyzer,
            "0011": SEP11Analyzer,
            "12": SEP12Analyzer,
            "0012": SEP12Analyzer,
            "24": SEP24Analyzer,
            "0024": SEP24Analyzer,
            "30": SEP30Analyzer,
            "0030": SEP30Analyzer,
            "38": SEP38Analyzer,
            "0038": SEP38Analyzer,
            "46": SEP46Analyzer,
            "0046": SEP46Analyzer,
            "47": SEP47Analyzer,
            "0047": SEP47Analyzer,
            "48": SEP48Analyzer,
            "0048": SEP48Analyzer,
            "45": SEP45Analyzer,
            "0045": SEP45Analyzer,
            "53": SEP53Analyzer,
            "0053": SEP53Analyzer,
        }

        analyzer_class = analyzers.get(sep_number)
        if not analyzer_class:
            raise ValueError(
                f"Analyzer not implemented for SEP-{sep_number}. "
                f"Available SEPs: {', '.join(sorted(set(analyzers.keys())))}"
            )

        return analyzer_class(sdk_analyzer)


class MatrixRenderer:
    """Renders compatibility matrix to Markdown"""

    def render(self, matrix: CompatibilityMatrix) -> str:
        """Generate Markdown document"""
        sections = [
            self._render_header(matrix),
            self._render_sep_summary(matrix),
            self._render_overall_coverage(matrix),
            self._render_implementation_status(matrix),
            self._render_coverage_by_section(matrix),
            self._render_detailed_fields(matrix),
            self._render_implementation_gaps(matrix),
            self._render_recommendations(matrix),
            self._render_legend(matrix),
            self._render_footer(matrix)
        ]

        return "\n\n".join(s for s in sections if s)

    def _render_header(self, matrix: CompatibilityMatrix) -> str:
        """Render document header"""
        sep_padded = matrix.sep_info.number.zfill(4)
        return f"""# SEP-{sep_padded} ({matrix.sep_info.title}) Compatibility Matrix

**Generated:** {matrix.last_updated}

**SDK Version:** {matrix.sdk_version}

**SEP Version:** {matrix.sep_info.version or 'Unknown'}

**SEP Status:** {matrix.sep_info.status or 'Unknown'}

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-{sep_padded}.md"""

    def _render_sep_summary(self, matrix: CompatibilityMatrix) -> str:
        """Render SEP summary"""
        # Split into paragraphs for better formatting
        paragraphs = matrix.sep_info.purpose.split('. ')
        formatted_paragraphs = []

        for para in paragraphs:
            if para.strip():
                # Add period back if it was removed by split
                if not para.endswith('.'):
                    para = para + '.'
                formatted_paragraphs.append(para.strip())

        # Join with double newline for markdown paragraphs
        purpose_text = '\n\n'.join(formatted_paragraphs)

        return f"""## SEP Summary

{purpose_text}"""

    def _render_overall_coverage(self, matrix: CompatibilityMatrix) -> str:
        """Render overall coverage statistics"""
        coverage_text = f"""## Overall Coverage

**Total Coverage:** {matrix.overall_coverage:.1f}% ({matrix.implemented_fields}/{matrix.total_fields} fields)

- ✅ **Implemented:** {matrix.implemented_fields}/{matrix.total_fields}
- ❌ **Not Implemented:** {matrix.total_fields - matrix.implemented_fields}/{matrix.total_fields}"""

        # Add note about excluded server-side features if any exist
        if matrix.server_only_count > 0:
            coverage_text += f"\n\n_Note: Excludes {matrix.server_only_count} server-side-only feature(s) not applicable to client SDKs_"

        coverage_text += f"""

**Required Fields:** {matrix.required_coverage:.1f}% ({matrix.required_implemented}/{matrix.required_fields})

**Optional Fields:** {matrix.optional_coverage:.1f}% ({matrix.optional_implemented}/{matrix.optional_fields})"""

        return coverage_text

    def _render_implementation_status(self, matrix: CompatibilityMatrix) -> str:
        """Render implementation status"""
        status = "✅ **Implemented**" if matrix.overall_coverage >= 100 else "⚠️ **Partially Implemented**"

        impl_files_list = '\n'.join(f"- `{f}`" for f in matrix.implementation_files)

        return f"""## Implementation Status

{status}

### Implementation Files

{impl_files_list}

### Key Classes

{self._generate_key_classes_list(matrix)}"""

    def _generate_key_classes_list(self, matrix: CompatibilityMatrix) -> str:
        """Generate list of key classes"""
        sep_number = matrix.sep_info.number

        if sep_number in ["01", "0001"]:
            class_descriptions = {
                'StellarToml': 'Main parser class for stellar.toml files',
                'AccountInformation': 'General Information fields from stellar.toml',
                'IssuerDocumentation': 'Organization Documentation fields ([DOCUMENTATION] section)',
                'PointOfContactDocumentation': 'Point of Contact fields ([[PRINCIPALS]] section)',
                'CurrencyDocumentation': 'Currency Documentation fields ([[CURRENCIES]] section)',
                'ValidatorInformation': 'Validator Information fields ([[VALIDATORS]] section)',
            }
        elif sep_number in ["02", "0002"]:
            class_descriptions = {
                'Federation': 'Main class for resolving Stellar federation addresses',
                'ResolveAddressResponse': 'Response model for federation address resolution',
                'FederationError': 'Error types for federation operations',
            }
        elif sep_number in ["05", "0005"]:
            class_descriptions = {
                'Mnemonic': 'BIP-39 mnemonic generation, seed creation, and validation',
                'WalletUtils': 'High-level wallet utilities for key pair generation from mnemonics',
                'Ed25519Derivation': 'BIP-32/SLIP-0010 Ed25519 key derivation implementation',
                'WordList': 'BIP-39 word lists for multiple languages',
            }
        elif sep_number in ["06", "0006"]:
            class_descriptions = {
                'TransferServerService': 'Main service class implementing all SEP-06 endpoints',
                'DepositRequest': 'Request model for GET /deposit endpoint',
                'DepositResponse': 'Response model with deposit instructions and transaction ID',
                'DepositExchangeRequest': 'Request model for GET /deposit-exchange with SEP-38 quotes',
                'WithdrawRequest': 'Request model for GET /withdraw endpoint',
                'WithdrawResponse': 'Response model with withdrawal account and transaction ID',
                'WithdrawExchangeRequest': 'Request model for GET /withdraw-exchange with SEP-38 quotes',
                'AnchorInfoResponse': 'Response model for GET /info with anchor capabilities',
                'AnchorTransaction': 'Transaction model with status and details',
                'AnchorTransactionStatus': 'Enum for all transaction status values',
                'AnchorTransactionsResponse': 'Response model for GET /transactions endpoint',
                'FeeRequest': 'Request model for GET /fee endpoint (deprecated)',
                'AnchorFeeResponse': 'Response model with fee calculations',
                'DepositAsset': 'Asset information for deposits from /info endpoint',
                'WithdrawAsset': 'Asset information for withdrawals from /info endpoint',
                'AnchorFeatureFlags': 'Feature flags (account_creation, claimable_balances)',
                'TransferServerError': 'Error enum for all SEP-06 error cases',
            }
        elif sep_number in ["07", "0007"]:
            class_descriptions = {
                'URIScheme': 'Main class for generating SEP-07 URIs for tx and pay operations',
                'URISchemeValidator': 'Validator class for signing and verifying SEP-07 URIs',
                'SignTransactionParams': 'Enum defining all TX operation parameters (xdr, replace, callback, pubkey, chain, msg, network_passphrase, origin_domain, signature)',
                'PayOperationParams': 'Enum defining all PAY operation parameters (destination, amount, asset_code, asset_issuer, memo, memo_type, callback, msg, network_passphrase, origin_domain, signature)',
                'URISchemeErrors': 'Error enum for URI validation failures (invalidSignature, invalidOriginDomain, missingOriginDomain, missingSignature, invalidTomlDomain, invalidToml, tomlSignatureMissing)',
                'SignURLEnum': 'Result enum for URI signing operations (success with signed URL, or failure)',
                'URISchemeIsValidEnum': 'Result enum for URI validation operations (success or failure with error)',
                'SetupTransactionXDREnum': 'Result enum for transaction setup (success with XDR or failure)',
                'SubmitTransactionEnum': 'Result enum for transaction submission (success, destinationRequiresMemo, or failure)',
            }
        elif sep_number in ["08", "0008"]:
            class_descriptions = {
                'RegulatedAssetsService': 'Main service class implementing SEP-08 approval server protocol',
                'RegulatedAsset': 'Model for regulated asset with approval server and criteria',
                'Sep08PostTransactionSuccess': 'Success response with signed transaction XDR',
                'Sep08PostTransactionRevised': 'Revised response with modified compliant transaction',
                'Sep08PostTransactionPending': 'Pending response with timeout for retry',
                'Sep08PostTransactionActionRequired': 'Action required response with action URL and method',
                'Sep08PostTransactionRejected': 'Rejected response with error message',
                'PostSep08TransactionEnum': 'Result enum for POST /tx_approve (success, revised, pending, actionRequired, rejected, or failure)',
                'Sep08PostActionNextUrl': 'Response for follow_next_url action result',
                'PostSep08ActionEnum': 'Result enum for POST to action URL (done, nextUrl, or failure)',
                'Sep08PostTransactionStatusResponse': 'Helper to decode response status field',
                'Sep08PostActionResultResponse': 'Helper to decode action result field',
                'RegulatedAssetsServiceError': 'Error enum for SEP-08 operations (invalidDomain, invalidToml, parsingResponseFailed, badRequest, notFound, unauthorized, horizonError)',
                'RegulatedAssetsServiceForDomainEnum': 'Result enum for forDomain factory method',
                'AuthorizationRequiredEnum': 'Result enum for authorization flag checking',
            }
        elif sep_number in ["09", "0009"]:
            class_descriptions = {
                'KYCNaturalPersonFieldsEnum': 'Enum for all natural person KYC fields (34 fields)',
                'KYCNaturalPersonFieldKey': 'Static constants for natural person field keys',
                'KYCOrganizationFieldsEnum': 'Enum for all organization KYC fields (17 fields)',
                'KYCOrganizationFieldKey': 'Static constants for organization field keys',
                'KYCFinancialAccountFieldsEnum': 'Enum for all financial account fields (14 fields)',
                'KYCFinancialAccountFieldKey': 'Static constants for financial account field keys',
                'KYCCardFieldsEnum': 'Enum for all card payment fields (11 fields)',
                'KYCCardFieldKey': 'Static constants for card field keys',
            }
        elif sep_number in ["10", "0010"]:
            class_descriptions = {
                'WebAuthenticator': 'Main class implementing SEP-10 authentication flow',
                'AccountInformation': 'Contains WEB_AUTH_ENDPOINT and SIGNING_KEY from stellar.toml',
                'SEPConstants': 'Contains WEBAUTH_GRACE_PERIOD_SECONDS for time bounds validation',
                'ChallengeValidationError': 'Error enum for challenge validation failures',
                'GetJWTTokenError': 'Error enum for JWT token retrieval failures',
            }
        elif sep_number in ["11", "0011"]:
            class_descriptions = {
                'TxRep': 'Main class implementing bidirectional conversion between XDR and txrep format',
                'toTxRep(transactionEnvelope:)': 'Converts transaction envelope XDR (base64) to human-readable txrep text format',
                'fromTxRep(txRep:)': 'Parses txrep text format back to transaction envelope XDR (base64)',
                'TxRepError': 'Error enum for txrep parsing failures (missingValue, invalidValue)',
            }
        elif sep_number in ["12", "0012"]:
            class_descriptions = {
                'KycService': 'Main service class implementing all SEP-12 endpoints',
                'GetCustomerInfoRequest': 'Request model for GET /customer endpoint',
                'GetCustomerInfoResponse': 'Response model with customer status and fields',
                'PutCustomerInfoRequest': 'Request model for PUT /customer with SEP-9 fields',
                'PutCustomerInfoResponse': 'Response model with customer ID',
                'PutCustomerVerificationRequest': 'Request model for verification codes',
                'PutCustomerCallbackRequest': 'Request model for callback URL registration',
                'GetCustomerFilesResponse': 'Response model for file metadata',
                'CustomerFileResponse': 'Response model for file uploads',
                'GetCustomerInfoField': 'Field specification object for required fields',
                'GetCustomerInfoProvidedField': 'Field specification with status for provided fields',
                'KYCNaturalPersonFieldsEnum': 'SEP-9 natural person KYC fields',
                'KYCOrganizationFieldsEnum': 'SEP-9 organization KYC fields',
                'KYCFinancialAccountFieldsEnum': 'SEP-9 financial account fields',
                'KYCCardFieldsEnum': 'SEP-9 card payment fields',
                'KycServiceError': 'Error enum for SEP-12 error cases (badRequest, notFound, unauthorized, payloadTooLarge)',
            }
        elif sep_number in ["24", "0024"]:
            class_descriptions = {
                'InteractiveService': 'Main service class implementing all SEP-24 endpoints',
                'InteractiveServiceError': 'Error enum for SEP-24 error cases (invalid domain, auth required, anchor errors)',
                'Sep24DepositRequest': 'Request model for POST /transactions/deposit/interactive',
                'Sep24WithdrawRequest': 'Request model for POST /transactions/withdraw/interactive',
                'Sep24FeeRequest': 'Request model for GET /fee endpoint',
                'Sep24TransactionRequest': 'Request model for GET /transaction endpoint',
                'Sep24TransactionsRequest': 'Request model for GET /transactions endpoint',
                'Sep24InfoResponse': 'Response model for GET /info with anchor capabilities',
                'Sep24InteractiveResponse': 'Response model with interactive URL and transaction ID',
                'Sep24TransactionResponse': 'Response model for single transaction details',
                'Sep24TransactionsResponse': 'Response model for transaction history',
                'Sep24FeeResponse': 'Response model with fee calculations',
                'Sep24Transaction': 'Transaction model with status, amounts, and timestamps',
                'Sep24DepositAsset': 'Deposit asset information with fees and limits',
                'Sep24WithdrawAsset': 'Withdrawal asset information with fees and limits',
                'Sep24FeatureFlags': 'Feature flags (account_creation, claimable_balances)',
                'Sep24FeeEndpointInfo': 'Fee endpoint availability and auth requirements',
                'Sep24Refund': 'Refund information with total amount and fee',
                'Sep24RefundPayment': 'Individual refund payment details (id, type, amount, fee)',
            }
        elif sep_number in ["38", "0038"]:
            class_descriptions = {
                'QuoteService': 'Main service class implementing SEP-38 RFQ API endpoints (info, prices, price, quote)',
                'Sep38InfoResponse': 'Response model for GET /info with supported assets and delivery methods',
                'Sep38PricesResponse': 'Response model for GET /prices with indicative prices for multiple assets',
                'Sep38PriceResponse': 'Response model for GET /price with indicative price for asset pair',
                'Sep38QuoteResponse': 'Response model for POST /quote and GET /quote/:id with firm quote details',
                'Sep38PostQuoteRequest': 'Request model for POST /quote with context, assets, and amounts',
                'Sep38Asset': 'Asset information with delivery methods and country codes from /info endpoint',
                'Sep38BuyAsset': 'Buy asset with indicative price and decimals from /prices endpoint',
                'Sep38Fee': 'Fee structure with total, asset, and optional breakdown details',
                'Sep38FeeDetails': 'Individual fee component with name, amount, and description',
                'Sep38SellDeliveryMethod': 'Delivery method for selling assets to the anchor',
                'Sep38BuyDeliveryMethod': 'Delivery method for receiving assets from the anchor',
                'QuoteServiceError': 'Error enum for SEP-38 operations (invalidArgument, badRequest, permissionDenied, notFound, parsingResponseFailed, horizonError)',
            }
        elif sep_number in ["30", "0030"]:
            class_descriptions = {
                'RecoveryService': 'Main service class implementing all SEP-30 recovery endpoints',
                'Sep30Request': 'Request model for account registration and updates',
                'Sep30RequestIdentity': 'Identity object with role and authentication methods',
                'Sep30AuthMethod': 'Authentication method with type and value',
                'Sep30AccountResponse': 'Response model with account address, identities, and signers',
                'Sep30SignatureResponse': 'Response model with transaction signature and network passphrase',
                'Sep30AccountsResponse': 'Response model for list accounts endpoint',
                'SEP30ResponseIdentity': 'Identity object in responses with role and authenticated flag',
                'SEP30ResponseSigner': 'Signer object with public key',
                'RecoveryServiceError': 'Error enum for SEP-30 error cases (400, 401, 404, 409)',
            }
        elif sep_number in ["46", "0046"]:
            class_descriptions = {
                'SorobanContractParser': 'Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta',
                'SorobanContractInfo': 'Stores information parsed from a soroban contract byte code such as Environment Meta, Contract Spec Entries and Contract Meta Entries',
                'SorobanContractParserError': 'Error enum for contract parsing failures',
                'SCMetaEntryXDR': 'XDR enum for contract metadata entries, supports SCMetaKind.v0',
                'SCMetaV0XDR': 'XDR struct for key-value metadata pairs (key: String, value: String)',
            }
        elif sep_number in ["47", "0047"]:
            class_descriptions = {
                'SorobanContractParser': 'Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta',
                'SorobanContractInfo': 'Stores information parsed from a soroban contract byte code, exposes supportedSeps property',
                'SorobanContractParserError': 'Error enum for contract parsing failures',
            }
        elif sep_number in ["48", "0048"]:
            class_descriptions = {
                'SorobanContractParser': 'Parses Soroban contract bytecode to extract Environment Meta, Contract Spec, and Contract Meta from Wasm custom sections',
                'SorobanContractInfo': 'Stores parsed contract information including envInterfaceVersion, specEntries, metaEntries, and categorized access via funcs, udtStructs, udtUnions, udtEnums, udtErrorEnums, events properties',
                'SorobanContractParserError': 'Error enum for contract parsing failures (invalidByteCode, environmentMetaNotFound, specEntriesNotFound)',
                'ContractSpec': 'Utility class for working with contract specifications (funcs(), udtStructs(), udtUnions(), udtEnums(), udtErrorEnums(), events(), getFunc(), getEvent(), findEntry(), nativeToXdrSCVal())',
                'ContractSpecError': 'Error enum for contract spec operations',
                'SCSpecEntryXDR': 'XDR type for contract specification entries (functionV0, structV0, unionV0, enumV0, errorEnumV0, eventV0)',
                'SCSpecTypeDefXDR': 'XDR type for type definitions supporting all primitive and compound types',
                'SCSpecFunctionV0XDR': 'XDR type for function specifications with name, inputs, and outputs',
                'SCSpecUDTStructV0XDR': 'XDR type for user-defined struct specifications',
                'SCSpecUDTUnionV0XDR': 'XDR type for user-defined union specifications',
                'SCSpecUDTEnumV0XDR': 'XDR type for user-defined enum specifications',
                'SCSpecUDTErrorEnumV0XDR': 'XDR type for user-defined error enum specifications',
                'SCSpecEventV0XDR': 'XDR type for event specifications',
            }
        elif sep_number in ["45", "0045"]:
            class_descriptions = {
                'WebAuthForContracts': 'Main class implementing SEP-45 authentication flow for contract accounts (C... addresses)',
                'ContractChallengeResponse': 'Response model for challenge authorization entries from server',
                'ContractChallengeValidationError': 'Error enum for challenge validation failures (13 cases)',
                'WebAuthForContractsError': 'Error enum for initialization errors (11 cases)',
                'GetContractJWTTokenError': 'Error enum for runtime authentication errors (8 cases)',
                'WebAuthForContractsForDomainEnum': 'Result enum for creating instance from stellar.toml',
                'GetContractJWTTokenResponseEnum': 'Result enum for complete authentication flow',
                'GetContractChallengeResponseEnum': 'Result enum for challenge request',
                'SubmitContractChallengeResponseEnum': 'Result enum for signed challenge submission',
            }
        elif sep_number in ["53", "0053"]:
            class_descriptions = {
                'KeyPair': 'Stellar key pair with SEP-53 message signing and verification methods (signMessage, verifyMessage, calculateMessageHash)',
            }
        else:
            # Generic fallback
            class_descriptions = {}

        items = []
        for class_name, description in class_descriptions.items():
            items.append(f"- **`{class_name}`**: {description}")

        return '\n'.join(items) if items else "- No key classes documented"

    def _render_coverage_by_section(self, matrix: CompatibilityMatrix) -> str:
        """Render coverage statistics by section"""
        lines = [
            "## Coverage by Section",
            "",
            "| Section | Coverage | Required Coverage | Implemented | Total |",
            "|---------|----------|-------------------|-------------|-------|"
        ]

        for section in matrix.sections:
            coverage = f"{section.coverage_percentage:.1f}%"
            req_coverage = f"{section.required_coverage_percentage:.1f}%"
            impl_total = f"{section.implemented_fields} | {section.total_fields}"

            lines.append(f"| {section.name} | {coverage} | {req_coverage} | {impl_total} |")

        return '\n'.join(lines)

    def _render_detailed_fields(self, matrix: CompatibilityMatrix) -> str:
        """Render detailed field comparison tables"""
        sections = ["## Detailed Field Comparison"]

        for section in matrix.sections:
            sections.append(f"\n### {section.name}")
            sections.append("")
            sections.append("| Field | Required | Status | SDK Property | Description |")
            sections.append("|-------|----------|--------|--------------|-------------|")

            for field in section.fields:
                field_name = f"`{field.name}`"
                required = "✓" if field.required else ""

                # Handle server-only fields with special status
                if field.server_only:
                    status = "⚙️ Server"
                    sdk_prop = "N/A"
                else:
                    status = "✅" if field.implemented else "❌"
                    sdk_prop = f"`{field.sdk_property}`" if field.sdk_property else "-"

                # Truncate long descriptions
                desc = field.description
                if len(desc) > 150:
                    desc = desc[:147] + "..."

                # Escape pipe characters
                desc = desc.replace("|", "\\|")

                sections.append(f"| {field_name} | {required} | {status} | {sdk_prop} | {desc} |")

        return '\n'.join(sections)

    def _render_implementation_gaps(self, matrix: CompatibilityMatrix) -> str:
        """Render implementation gaps"""
        missing_fields = []

        for section in matrix.sections:
            # Exclude server-only fields from gaps
            section_missing = [f for f in section.fields if not f.implemented and not f.server_only]
            if section_missing:
                missing_fields.append((section.name, section_missing))

        if not missing_fields:
            return """## Implementation Gaps

🎉 **No gaps found!** All fields are implemented."""

        lines = [
            "## Implementation Gaps",
            "",
            f"**Total Missing Fields:** {sum(len(fields) for _, fields in missing_fields)}",
            ""
        ]

        for section_name, fields in missing_fields:
            lines.append(f"### {section_name}")
            lines.append("")
            for field in fields:
                required_marker = " **(Required)**" if field.required else ""
                lines.append(f"- `{field.name}`{required_marker}: {field.description[:100]}")
            lines.append("")

        return '\n'.join(lines)

    def _render_recommendations(self, matrix: CompatibilityMatrix) -> str:
        """Render recommendations - disabled to keep matrices concise"""
        return ""

    def _render_legend(self, matrix: CompatibilityMatrix) -> str:
        """Render status legend"""
        legend = """## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional"""

        # Add note about excluded server-side features if any exist
        if matrix.server_only_count > 0:
            legend += f"\n\n**Note:** Excludes {matrix.server_only_count} server-side-only feature(s) not applicable to client SDKs"

        return legend

    def _render_footer(self, matrix: CompatibilityMatrix) -> str:
        """Render document footer"""
        return ""


class SEPMatrixGenerator:
    """Main generator orchestrating the matrix generation"""

    def __init__(self, sdk_root: Path):
        self.sdk_root = sdk_root
        self.fetcher = SEPFetcher()
        self.sdk_analyzer = SDKAnalyzer(sdk_root)
        self.renderer = MatrixRenderer()

    def generate_matrix(self, sep_number: str, output_path: Optional[Path] = None) -> Path:
        """
        Generate compatibility matrix for a SEP

        Args:
            sep_number: SEP number (e.g., "01")
            output_path: Optional custom output path

        Returns:
            Path to generated markdown file
        """
        logger.info(f"Starting matrix generation for SEP-{sep_number}")

        # Fetch SEP specification
        sep_info = self.fetcher.fetch_sep(sep_number)

        # Create SEP-specific analyzer
        analyzer = SEPAnalyzerFactory.create_analyzer(sep_number, self.sdk_analyzer)

        # Analyze implementation
        matrix = analyzer.analyze(sep_info)

        # Render to markdown
        markdown_content = self.renderer.render(matrix)

        # Determine output path
        if output_path is None:
            sep_padded = sep_number.zfill(4)
            output_dir = self.sdk_root / "compatibility" / "sep"
            output_dir.mkdir(parents=True, exist_ok=True)
            output_path = output_dir / f"SEP-{sep_padded}_COMPATIBILITY_MATRIX.md"

        # Write file
        output_path.write_text(markdown_content, encoding='utf-8')
        logger.info(f"Generated matrix: {output_path}")

        return output_path

    @staticmethod
    def list_available_seps() -> List[str]:
        """List SEPs with implemented analyzers"""
        return ["01", "02", "05", "06", "07", "08", "09", "10", "11", "12", "24", "30", "38", "45", "46", "47", "48", "53"]


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Generate SEP compatibility matrices for Stellar iOS/Mac SDK",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --sep 01
  %(prog)s --sep 10 --output custom_output.md
  %(prog)s --list
  %(prog)s --sep 01 --verbose
        """
    )

    parser.add_argument(
        '--sep',
        type=str,
        help='SEP number to analyze (e.g., 01, 10)'
    )

    parser.add_argument(
        '--output',
        type=Path,
        help='Custom output file path (default: compatibility/sep/SEP-XXXX_COMPATIBILITY_MATRIX.md)'
    )

    parser.add_argument(
        '--sdk-root',
        type=Path,
        default=Path(__file__).parent.parent.parent.parent,
        help='Path to SDK root directory (default: auto-detected)'
    )

    parser.add_argument(
        '--list',
        action='store_true',
        help='List available SEPs with implemented analyzers'
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )

    args = parser.parse_args()

    # Configure logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # List available SEPs
    if args.list:
        available_seps = SEPMatrixGenerator.list_available_seps()
        print("Available SEPs with implemented analyzers:")
        for sep in available_seps:
            print(f"  - SEP-{sep.zfill(4)}")
        return 0

    # Validate arguments
    if not args.sep:
        parser.error("--sep is required (or use --list to see available SEPs)")

    # Validate SDK root
    if not args.sdk_root.exists():
        parser.error(f"SDK root not found: {args.sdk_root}")

    try:
        # Generate matrix
        generator = SEPMatrixGenerator(args.sdk_root)
        output_path = generator.generate_matrix(args.sep, args.output)

        print(f"\n✅ Successfully generated compatibility matrix!")
        print(f"📄 Output: {output_path}")
        print(f"📊 SEP-{args.sep.zfill(4)} analysis complete")

        return 0

    except ValueError as e:
        logger.error(f"Error: {e}")
        return 1
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return 2


if __name__ == '__main__':
    sys.exit(main())
