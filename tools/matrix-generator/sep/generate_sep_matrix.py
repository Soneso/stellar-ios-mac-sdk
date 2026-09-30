#!/usr/bin/env python3
"""
SEP Compatibility Matrix Generator for Stellar iOS/Mac SDK

Generates one compatibility matrix per Stellar Ecosystem Proposal (SEP) by comparing the SEP
with the iOS/Mac SDK sources: the status of every field, coverage by section, and required
versus optional coverage.

A class or file the analyzer cannot find renders its fields as not implemented. An SDK file
that is found but cannot be read, an unreadable SDK version, a missing or invalid definition
file in data/, or a SEP that cannot be fetched raises, and the run writes no matrix.

Usage:
    python3 generate_sep_matrix.py --sep 01
    python3 generate_sep_matrix.py --sep 10 --output custom_output.md
    python3 generate_sep_matrix.py --list
"""

import argparse
import json
import logging
import re
import sys
from dataclasses import dataclass, field as dataclass_field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import urljoin
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from sdk_version import get_sdk_version  # noqa: E402

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def read_source(path: Path) -> str:
    """The text of an SDK file that was found; a file that cannot be read raises ValueError"""
    try:
        return path.read_text(encoding='utf-8')
    except (OSError, UnicodeDecodeError) as e:
        raise ValueError(f"Cannot read {path}: {e}") from e


@dataclass
class SEPField:
    """Represents a single field from a SEP specification"""
    name: str  # Field or feature name as the SEP or the analyzer names it (e.g., "VERSION", "tx_approve")
    required: bool  # Is this field required?
    description: str  # Field description from SEP
    sdk_property: Optional[str] = None  # Swift property name (e.g., "version", "code")
    implemented: bool = False  # Is it implemented in SDK?
    server_only: bool = False  # Is this a server-side-only feature not applicable to client SDKs?

    def mark(self, sdk_property: str) -> None:
        """Record the field as implemented by sdk_property"""
        self.implemented = True
        self.sdk_property = sdk_property


@dataclass
class SEPSection:
    """Represents a section of fields in a SEP"""
    name: str
    fields: List[SEPField] = dataclass_field(default_factory=list)

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
    raw_content: str = ""


@dataclass
class CompatibilityMatrix:
    """Complete compatibility matrix for a SEP"""
    sep_info: SEPInfo
    sections: List[SEPSection]
    implementation_files: List[str]
    key_classes: Dict[str, str]  # SDK type name to description, rendered under Key Classes
    last_updated: str = dataclass_field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d"))

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

        title = "Unknown"
        for line in lines:
            if line.startswith('# '):
                title = line[2:].strip()
                break

        version = None
        status = None
        in_preamble = False

        for i, line in enumerate(lines):
            # Check if previous lines have Preamble heading (## Preamble)
            if '```' in line and i > 0:
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

    def search_files(self, pattern: str) -> List[Path]:
        """The Swift files whose text matches pattern (case-insensitive), sorted by path"""
        pattern_re = re.compile(pattern, re.IGNORECASE)
        return sorted(swift_file for swift_file in self.stellarsdk_path.rglob("*.swift")
                      if pattern_re.search(read_source(swift_file)))

    def find_class_or_struct(self, name: str) -> Optional[Path]:
        """The first file by path that declares a class, struct or enum named name; None when none does"""
        files = self.search_files(rf"(class|struct|enum)\s+{re.escape(name)}\b")
        return files[0] if files else None

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

        content = read_source(file_path)

        # Find the Keys enum that maps TOML names to Swift properties
        enum_match = re.search(r'enum\s+Keys:\s*String\s*\{([^}]+)\}', content, re.DOTALL)
        if enum_match:
            enum_content = enum_match.group(1)
            for match in re.finditer(r'case\s+(\w+)\s*=\s*"([^"]+)"', enum_content):
                swift_property = match.group(1)
                toml_name = match.group(2)
                property_map[toml_name] = swift_property

        # Also find public var declarations to ensure completeness
        var_pattern = r'public\s+var\s+(\w+):\s*[^=\n]+'
        for match in re.finditer(var_pattern, content):
            property_name = match.group(1)
            # A property outside the Keys enum maps to its inferred TOML name
            if property_name not in property_map.values():
                property_map[self._infer_toml_name(property_name)] = property_name

        return property_map

    def _infer_toml_name(self, property_name: str) -> str:
        """Infer TOML field name from Swift property name: code -> code, anchorAsset -> anchor_asset"""
        if property_name.islower():
            return property_name
        return re.sub('([a-z0-9])([A-Z])', r'\1_\2', property_name).lower()


class SEPAnalyzerBase:
    """Shared construction of the SEP analyzers

    A subclass implements analyze() and declares KEY_CLASSES, the SDK types listed under Key
    Classes with their descriptions.
    """

    KEY_CLASSES: Dict[str, str] = {}

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        self.sdk_analyzer = sdk_analyzer
        self.implementation_files: List[str] = []

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        raise NotImplementedError

    def _implementation_file(self, class_name: str) -> Optional[Path]:
        """The file declaring class_name, listed once among the implementation files; None when absent"""
        return self._record(self.sdk_analyzer.find_class_or_struct(class_name))

    def _implementation_file_named(self, filename: str) -> Optional[Path]:
        """The SDK file with this name, listed once among the implementation files; None when absent"""
        return self._record(self.sdk_analyzer.find_file_by_name(filename))

    def _record(self, path: Optional[Path]) -> Optional[Path]:
        if path is not None:
            relative_path = self.sdk_analyzer.get_relative_path(path)
            if relative_path not in self.implementation_files:
                self.implementation_files.append(relative_path)
        return path

    def _check_declared_properties(self, section: SEPSection, class_name: str, properties: Dict[str, str]) -> None:
        """Mark each field whose property, mapped by field name, class_name declares with let or var"""
        class_file = self.sdk_analyzer.find_class_or_struct(class_name)
        if not class_file:
            return
        content = read_source(class_file)
        for field in section.fields:
            sdk_property = properties.get(field.name)
            if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                field.mark(sdk_property)

    def _matrix(self, sep_info: SEPInfo, sections: List[SEPSection]) -> CompatibilityMatrix:
        return CompatibilityMatrix(sep_info=sep_info, sections=sections,
                                   implementation_files=self.implementation_files, key_classes=self.KEY_CLASSES)

    @staticmethod
    def _load_definition(filename: str, features_key: str) -> List[SEPSection]:
        """The sections of a definition file in data/, one field per entry under features_key

        The file is part of the generator, so a missing or invalid file, or one without
        sections, raises.
        """
        definition_path = Path(__file__).parent / 'data' / filename
        try:
            definition = json.loads(definition_path.read_text(encoding='utf-8'))
        except (OSError, ValueError) as e:
            raise ValueError(f"Cannot load the SEP definition {definition_path}: {e}") from e
        sections = [
            SEPSection(section_data['title'], [
                SEPField(feature['name'], feature.get('required', True), feature['description'])
                for feature in section_data.get(features_key, [])
            ])
            for section_data in definition.get('sections', [])
        ]
        if not sections:
            raise ValueError(f"SEP definition {definition_path} declares no sections")
        return sections


class SEP01Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-01 (stellar.toml); the fields come from the tables of the SEP text"""

    KEY_CLASSES = {
        'StellarToml': 'Main parser class for stellar.toml files',
        'AccountInformation': 'General Information fields from stellar.toml',
        'IssuerDocumentation': 'Organization Documentation fields ([DOCUMENTATION] section)',
        'PointOfContactDocumentation': 'Point of Contact fields ([[PRINCIPALS]] section)',
        'CurrencyDocumentation': 'Currency Documentation fields ([[CURRENCIES]] section)',
        'ValidatorInformation': 'Validator Information fields ([[VALIDATORS]] section)',
    }

    # Mapping of Swift class names to their sections
    CLASS_SECTION_MAP = {
        'AccountInformation': 'General Information',
        'IssuerDocumentation': 'Organization Documentation',
        'PointOfContactDocumentation': 'Point of Contact Documentation',
        'CurrencyDocumentation': 'Currency Documentation',
        'ValidatorInformation': 'Validator Information',
    }

    # SEP headings whose field tables are parsed, with the section each produces
    SECTION_PATTERNS = [
        (r'###\s+General Information', 'General Information'),
        (r'###\s+Organization Documentation', 'Organization Documentation'),
        (r'###\s+Point of Contact Documentation', 'Point of Contact Documentation'),
        (r'###\s+Currency Documentation', 'Currency Documentation'),
        (r'###\s+Validator Information', 'Validator Information'),
    ]

    # Fields required regardless of their description: the currency code, the issuer of a
    # Stellar asset, and the contract of a non-Stellar asset
    REQUIRED_FIELDS = {'code', 'issuer', 'contract'}

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-01 implementation"""
        logger.info("Analyzing SEP-01 (stellar.toml) implementation")

        sections = self._parse_sections(sep_info.raw_content)
        self._implementation_file('StellarToml')
        sdk_property_maps = {}
        for class_name, section_name in self.CLASS_SECTION_MAP.items():
            file_path = self._implementation_file(class_name)
            if file_path:
                sdk_property_maps[section_name] = self.sdk_analyzer.extract_properties_from_swift_class(file_path)
        for section in sections:
            if section.name in sdk_property_maps:
                property_map = sdk_property_maps[section.name]

                for field in section.fields:
                    if field.name in property_map:
                        field.mark(property_map[field.name])
                    else:
                        field_variants = [
                            field.name.lower(),
                            field.name.upper(),
                            field.name.replace('_', ''),
                        ]

                        for variant in field_variants:
                            if variant in property_map:
                                field.mark(property_map[variant])
                                break

        return self._matrix(sep_info, sections)

    def _parse_sections(self, content: str) -> List[SEPSection]:
        """The SEP-01 field tables; a heading without a table of fields yields no section"""
        lines = content.split('\n')
        sections = []
        for pattern, section_name in self.SECTION_PATTERNS:
            section = self._extract_section_fields(lines, pattern, section_name)
            if section and section.fields:
                sections.append(section)
        return sections

    def _extract_section_fields(self, lines: List[str], section_pattern: str, section_name: str) -> Optional[SEPSection]:
        """Extract fields from a specific section"""
        section = SEPSection(section_name)

        section_start = -1
        for i, line in enumerate(lines):
            if re.match(section_pattern, line):
                section_start = i
                break

        if section_start == -1:
            return None

        table_start = -1
        for i in range(section_start, min(section_start + 20, len(lines))):
            if '| Field' in lines[i] or '| field' in lines[i]:
                table_start = i
                break

        if table_start == -1:
            return None

        # Skip header separator line (|----|----| etc)
        table_data_start = table_start + 2

        for i in range(table_data_start, len(lines)):
            line = lines[i].strip()

            if not line or line.startswith('#') or not line.startswith('|'):
                break

            field = self._parse_table_row(line)
            if field:
                section.fields.append(field)

        return section

    def _parse_table_row(self, row: str) -> Optional[SEPField]:
        """Parse a single table row into a SEPField"""
        parts = [p.strip() for p in row.split('|')]
        parts = [p for p in parts if p]

        if len(parts) < 3:
            return None

        field_name = parts[0].strip('`').strip()
        description = parts[2]
        return SEPField(field_name, self._is_field_required(field_name, description), description)

    def _is_field_required(self, field_name: str, description: str) -> bool:
        """Determine if a field is required"""
        if 'Required' in description and 'if' not in description.split('Required')[0]:
            return True
        return field_name.lower() in self.REQUIRED_FIELDS


class SEP02Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-02 (Federation Protocol)"""

    KEY_CLASSES = {
        'Federation': 'Main class for resolving Stellar federation addresses',
        'ResolveAddressResponse': 'Response model for federation address resolution',
        'FederationError': 'Error types for federation operations',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-02 implementation"""
        logger.info("Analyzing SEP-02 (Federation Protocol) implementation")

        sections = self._create_sections()
        federation_file = self._implementation_file('Federation')
        response_file = self._implementation_file('ResolveAddressResponse')
        self._implementation_file('FederationError')

        for section in sections:
            if section.name == 'Request Parameters':
                self._analyze_request_parameters(section, federation_file)
            elif section.name == 'Request Types':
                self._analyze_request_types(section, federation_file)
            elif section.name == 'Response Fields':
                self._analyze_response_fields(section, response_file)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-02 sections and their fields"""
        return [
            SEPSection('Request Parameters', [
                SEPField('q', True, 'String to look up (stellar address, account ID, or transaction ID)'),
                SEPField('type', True, 'Type of lookup (name, id, txid, or forward)'),
            ]),
            SEPSection('Request Types', [
                SEPField('name', True, 'returns the federation record for the given Stellar address.'),
                SEPField('id', True, "returns the federation record of the Stellar address associated with the given account ID. In some cases this is ambiguous. For instance if an anchor sends transactions on behalf of its users, the account ID will be of the anchor's account and not of the user's account."),
                SEPField('txid', False, 'returns the federation record of the sender of the transaction if known by the server.'),
                SEPField('forward', False, 'Used for forwarding the payment on to a different network or different financial institution. The other parameters of the query will vary depending on what kind of institution is the ultimate destination of the payment and what you as the forwarding anchor supports.'),
            ]),
            SEPSection('Response Fields', [
                SEPField('stellar_address', True, 'stellar address'),
                SEPField('account_id', True, 'Stellar public key / account ID'),
                SEPField('memo_type', False, 'type of memo to attach to transaction, one of text, id or hash'),
                SEPField('memo', False, 'value of memo to attach to transaction, for hash this should be base64-encoded. This field should always be of type string (even when memo_type is equal to id) to support parsing value in languages that do not support big numbers.'),
            ]),
        ]

    def _analyze_request_parameters(self, section: SEPSection, federation_file: Optional[Path]) -> None:
        """Analyze request parameter support"""
        if not federation_file:
            return

        content = read_source(federation_file)

        for field in section.fields:
            if field.name == 'q':
                if '?q=' in content or 'q=' in content:
                    field.mark('q')
            elif field.name == 'type':
                if 'type=' in content:
                    field.mark('type')

    def _analyze_request_types(self, section: SEPSection, federation_file: Optional[Path]) -> None:
        """Analyze request type support"""
        if not federation_file:
            return

        content = read_source(federation_file)

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
                    field.mark(sdk_method)

    def _analyze_response_fields(self, section: SEPSection, response_file: Optional[Path]) -> None:
        """Analyze response field support"""
        if not response_file:
            return

        content = read_source(response_file)

        field_property_map = {
            'stellar_address': 'stellarAddress',
            'account_id': 'accountId',
            'memo_type': 'memoType',
            'memo': 'memo',
        }

        for field in section.fields:
            if field.name in field_property_map:
                sdk_property = field_property_map[field.name]
                if (f'let {sdk_property}' in content or f'var {sdk_property}' in content) and f'"{field.name}"' in content:
                    field.mark(sdk_property)


class SEP05Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-05 (Key Derivation Methods for Stellar Keys)"""

    KEY_CLASSES = {
        'Mnemonic': 'BIP-39 mnemonic generation, seed creation, and validation',
        'WalletUtils': 'High-level wallet utilities for key pair generation from mnemonics',
        'Ed25519Derivation': 'BIP-32/SLIP-0010 Ed25519 key derivation implementation',
        'WordList': 'BIP-39 word lists for multiple languages',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-05 implementation"""
        logger.info("Analyzing SEP-05 (Key Derivation Methods) implementation")

        sections = self._create_sections()
        mnemonic_file = self._implementation_file('Mnemonic')
        wallet_file = self._implementation_file('WalletUtils')
        ed25519_file = self._implementation_file('Ed25519Derivation')
        wordlist_file = self._implementation_file('WordList')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-05 sections and their fields"""
        return [
            SEPSection('BIP-39 Mnemonic Features', [
                SEPField('mnemonic_generation_12_words', True, 'Generate 12-word BIP-39 mnemonic phrase'),
                SEPField('mnemonic_generation_24_words', True, 'Generate 24-word BIP-39 mnemonic phrase'),
                SEPField('mnemonic_to_seed', True, 'Convert BIP-39 mnemonic to seed using PBKDF2'),
                SEPField('mnemonic_validation', True, 'Validate BIP-39 mnemonic phrase (word list and checksum)'),
                SEPField('passphrase_support', False, 'Support optional BIP-39 passphrase (25th word)'),
            ]),
            SEPSection('BIP-32 Key Derivation', [
                SEPField('master_key_generation', True, 'Generate master key from seed'),
                SEPField('hd_key_derivation', True, 'BIP-32 hierarchical deterministic key derivation'),
                SEPField('child_key_derivation', True, 'Derive child keys from parent keys'),
                SEPField('ed25519_curve', True, 'Support Ed25519 curve for Stellar keys'),
            ]),
            SEPSection('BIP-44 Multi-Account Support', [
                SEPField('stellar_derivation_path', True, "Support Stellar's BIP-44 derivation path: m/44'/148'/account'"),
                SEPField('multiple_accounts', True, 'Derive multiple Stellar accounts from single seed'),
                SEPField('account_index_support', True, 'Support account index parameter in derivation'),
            ]),
            SEPSection('Key Derivation Methods', [
                SEPField('keypair_from_mnemonic', True, 'Generate Stellar KeyPair from mnemonic'),
                SEPField('seed_from_mnemonic', True, 'Convert mnemonic to raw seed bytes'),
                SEPField('account_id_from_mnemonic', True, 'Get Stellar account ID from mnemonic'),
            ]),
            SEPSection('Language Support', [
                SEPField('english', True, 'English BIP-39 word list (2048 words)'),
                SEPField('chinese_simplified', False, 'Chinese Simplified BIP-39 word list'),
                SEPField('chinese_traditional', False, 'Chinese Traditional BIP-39 word list'),
                SEPField('french', False, 'French BIP-39 word list'),
                SEPField('italian', False, 'Italian BIP-39 word list'),
                SEPField('japanese', False, 'Japanese BIP-39 word list'),
                SEPField('korean', False, 'Korean BIP-39 word list'),
                SEPField('spanish', False, 'Spanish BIP-39 word list'),
            ]),
        ]

    def _analyze_bip39_features(self, section: SEPSection, mnemonic_file: Optional[Path], wallet_file: Optional[Path]) -> None:
        """Analyze BIP-39 mnemonic feature support"""
        if not mnemonic_file or not wallet_file:
            return

        mnemonic_content = read_source(mnemonic_file)
        wallet_content = read_source(wallet_file)

        for field in section.fields:
            if field.name == 'mnemonic_generation_12_words':
                if 'generate12WordMnemonic' in wallet_content:
                    field.mark('generate12WordMnemonic')
            elif field.name == 'mnemonic_generation_24_words':
                if 'generate24WordMnemonic' in wallet_content:
                    field.mark('generate24WordMnemonic')
            elif field.name == 'mnemonic_to_seed':
                if 'createSeed' in mnemonic_content and 'PBKDF2SHA512' in mnemonic_content:
                    field.mark('createSeed')
            elif field.name == 'mnemonic_validation':
                # iOS SDK doesn't have explicit validation, but it has checksum handling in mnemonic generation
                if 'sha256' in mnemonic_content and 'checkSum' in mnemonic_content:
                    field.mark('create (with checksum)')
            elif field.name == 'passphrase_support':
                if 'withPassphrase' in mnemonic_content or 'passphrase' in wallet_content:
                    field.mark('createSeed(withPassphrase:)')

    def _analyze_bip32_features(self, section: SEPSection, ed25519_file: Optional[Path]) -> None:
        """Analyze BIP-32 key derivation feature support"""
        if not ed25519_file:
            return

        content = read_source(ed25519_file)

        for field in section.fields:
            if field.name == 'master_key_generation':
                if 'ed25519 seed' in content and 'HMACSHA512' in content:
                    field.mark('Ed25519Derivation.init(seed:)')
            elif field.name == 'hd_key_derivation':
                if 'func derived' in content or 'derived(at' in content:
                    field.mark('derived(at:)')
            elif field.name == 'child_key_derivation':
                # Check for child key derivation (same as hd_key_derivation in this implementation)
                if 'func derived' in content or 'derived(at' in content:
                    field.mark('derived(at:)')
            elif field.name == 'ed25519_curve':
                if 'Ed25519' in content and 'ed25519 seed' in content:
                    field.mark('Ed25519Derivation')

    def _analyze_bip44_features(self, section: SEPSection, wallet_file: Optional[Path]) -> None:
        """Analyze BIP-44 multi-account support"""
        if not wallet_file:
            return

        content = read_source(wallet_file)

        for field in section.fields:
            if field.name == 'stellar_derivation_path':
                if "derived(at: 44)" in content and "derived(at: 148)" in content:
                    field.mark("createKeyPair (m/44'/148'/index')")
            elif field.name == 'multiple_accounts':
                if 'index:' in content and 'derived(at: UInt32(index))' in content:
                    field.mark('createKeyPair(index:)')
            elif field.name == 'account_index_support':
                if 'index: Int' in content:
                    field.mark('index parameter')

    def _analyze_key_derivation_methods(self, section: SEPSection, wallet_file: Optional[Path]) -> None:
        """Analyze key derivation method support"""
        if not wallet_file:
            return

        content = read_source(wallet_file)

        for field in section.fields:
            if field.name == 'keypair_from_mnemonic':
                if 'createKeyPair' in content and 'mnemonic:' in content:
                    field.mark('createKeyPair(mnemonic:passphrase:index:)')
            elif field.name == 'seed_from_mnemonic':
                if 'createSeed' in content:
                    field.mark('Mnemonic.createSeed')
            elif field.name == 'account_id_from_mnemonic':
                # Can be derived from KeyPair
                if 'KeyPair' in content and 'createKeyPair' in content:
                    field.mark('createKeyPair().accountId')

    def _analyze_language_support(self, section: SEPSection, wordlist_file: Optional[Path]) -> None:
        """Analyze language support for BIP-39 word lists"""
        if not wordlist_file:
            return

        content = read_source(wordlist_file)

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
                    field.sdk_property = field.name.replace('_', ' ').title().replace(' ', '')


class SEP08Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-08 (Regulated Assets)"""

    KEY_CLASSES = {
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

    # Response class and SDK property of each field of the POST /tx_approve responses
    RESPONSE_FIELDS = {
        'Success Response Fields': ('Sep08PostTransactionSuccess', {'tx': 'tx', 'message': 'message'}),
        'Revised Response Fields': ('Sep08PostTransactionRevised', {'tx': 'tx', 'message': 'message'}),
        'Pending Response Fields': ('Sep08PostTransactionPending', {'timeout': 'timeout', 'message': 'message'}),
        'Action Required Response Fields': ('Sep08PostTransactionActionRequired', {
            'message': 'message', 'action_url': 'actionUrl', 'action_method': 'actionMethod', 'action_fields': 'actionFields',
        }),
        'Rejected Response Fields': ('Sep08PostTransactionRejected', {'error': 'error'}),
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-08 implementation"""
        logger.info("Analyzing SEP-08 (Regulated Assets) implementation")

        sections = self._create_sections()
        service_file = self._implementation_file('RegulatedAssetsService')

        for section in sections:
            if section.name == 'Approval Endpoint':
                self._analyze_approval_endpoint(section, service_file)
            elif section.name == 'Request Parameters':
                self._analyze_request_parameters(section, service_file)
            elif section.name == 'Response Statuses':
                self._analyze_response_statuses(section, service_file)
            elif section.name in self.RESPONSE_FIELDS:
                self._analyze_response_fields(section)
            elif section.name == 'Action URL Handling':
                self._analyze_action_url_handling(section, service_file)
            elif section.name == 'Stellar TOML Fields':
                self._analyze_stellar_toml_fields(section)
            elif section.name == 'Authorization Flags':
                self._analyze_authorization_flags(section, service_file)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-08 sections and their fields"""
        return [
            SEPSection('Approval Endpoint', [
                SEPField('tx_approve', True, 'POST /tx_approve - Approval server endpoint that receives a signed transaction, checks for compliance, and signs it on success'),
            ]),
            SEPSection('Request Parameters', [
                SEPField('tx', True, 'A base64 encoded transaction envelope XDR signed by the user. This is the transaction that will be tested for compliance and signed on success.'),
            ]),
            SEPSection('Response Statuses', [
                SEPField('success', True, 'Transaction was found compliant and signed without being revised'),
                SEPField('revised', True, 'Transaction was revised to be made compliant'),
                SEPField('pending', True, 'Issuer could not determine whether to approve the transaction at the time of receiving it'),
                SEPField('action_required', True, 'User must complete an action before this transaction can be approved'),
                SEPField('rejected', True, 'Transaction is not compliant and could not be revised to be made compliant'),
            ]),
            SEPSection('Success Response Fields', [
                SEPField('status', True, 'Status value "success"'),
                SEPField('tx', True, 'Transaction envelope XDR, base64 encoded. This transaction will have both the original signature(s) from the request as well as one or multiple additional signatures from the issuer.'),
                SEPField('message', False, 'A human readable string containing information to pass on to the user'),
            ]),
            SEPSection('Revised Response Fields', [
                SEPField('status', True, 'Status value "revised"'),
                SEPField('tx', True, 'Transaction envelope XDR, base64 encoded. This transaction is a revised compliant version of the original request transaction, signed by the issuer.'),
                SEPField('message', True, 'A human readable string explaining the modifications made to the transaction to make it compliant'),
            ]),
            SEPSection('Pending Response Fields', [
                SEPField('status', True, 'Status value "pending"'),
                SEPField('timeout', True, 'Number of milliseconds to wait before submitting the same transaction again. Use 0 if the wait time cannot be determined.'),
                SEPField('message', False, 'A human readable string containing information to pass on to the user'),
            ]),
            SEPSection('Action Required Response Fields', [
                SEPField('status', True, 'Status value "action_required"'),
                SEPField('message', True, 'A human readable string containing information regarding the action required'),
                SEPField('action_url', True, 'A URL that allows the user to complete the actions required to have the transaction approved'),
                SEPField('action_method', False, 'GET or POST, indicating the type of request that should be made to the action_url. If not provided, GET is assumed.'),
                SEPField('action_fields', False, 'An array of additional fields defined by SEP-9 Standard KYC / AML fields that the client may optionally provide to the approval service when sending the request to the action_url'),
            ]),
            SEPSection('Rejected Response Fields', [
                SEPField('status', True, 'Status value "rejected"'),
                SEPField('error', True, 'A human readable string explaining why the transaction is not compliant and could not be made compliant'),
            ]),
            SEPSection('Action URL Handling', [
                SEPField('action_url_get', True, 'Support for GET method to action_url with query parameters'),
                SEPField('action_url_post', True, 'Support for POST method to action_url with JSON body'),
                SEPField('action_url_post_response_no_further_action', True, 'Handle POST response with result "no_further_action_required"'),
                SEPField('action_url_post_response_follow_next_url', True, 'Handle POST response with result "follow_next_url" and next_url field'),
            ]),
            SEPSection('Stellar TOML Fields', [
                SEPField('regulated', True, 'A boolean indicating whether or not this is a regulated asset. If missing, false is assumed.'),
                SEPField('approval_server', True, 'The URL of an approval service that signs validated transactions'),
                SEPField('approval_criteria', False, "A human readable string that explains the issuer's requirements for approving transactions"),
            ]),
            SEPSection('Authorization Flags', [
                SEPField('authorization_required', True, 'Authorization Required flag must be set on issuer account'),
                SEPField('authorization_revocable', True, 'Authorization Revocable flag must be set on issuer account'),
            ]),
        ]

    def _analyze_approval_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze approval endpoint support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'tx_approve':
                # Check for postTransaction method which implements POST /tx_approve
                if 'func postTransaction(txB64Xdr: String, apporvalServer:String)' in content:
                    field.mark('postTransaction(txB64Xdr:apporvalServer:)')

    def _analyze_request_parameters(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze request parameter support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'tx':
                if 'txRequest["tx"] = txB64Xdr' in content:
                    field.mark('txB64Xdr parameter')

    def _analyze_response_statuses(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze response status support"""
        if not service_file:
            return

        content = read_source(service_file)

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
                if f'case {case_name}' in content:
                    field.mark(f'{enum_name}.{case_name}')

    def _analyze_response_fields(self, section: SEPSection) -> None:
        """Analyze the fields of one POST /tx_approve response class; status is implicit in the enum case"""
        class_name, properties = self.RESPONSE_FIELDS[section.name]
        response_file = self.sdk_analyzer.find_class_or_struct(class_name)
        if not response_file:
            return
        content = read_source(response_file)
        for field in section.fields:
            if field.name == 'status':
                field.mark('status (implicit)')
            elif field.name in properties and f'var {properties[field.name]}' in content:
                field.mark(properties[field.name])

    def _analyze_action_url_handling(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze action URL handling support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'action_url_get':
                # GET support is implicit via action_url field
                if 'actionUrl' in content:
                    field.mark('actionUrl field support')
            elif field.name == 'action_url_post':
                if 'func postAction(url: String, actionFields:[String : Any])' in content:
                    field.mark('postAction(url:actionFields:)')
            elif field.name == 'action_url_post_response_no_further_action':
                if '"no_further_action_required"' in content and 'PostSep08ActionEnum' in content:
                    field.mark('PostSep08ActionEnum.done')
            elif field.name == 'action_url_post_response_follow_next_url':
                if '"follow_next_url"' in content and 'Sep08PostActionNextUrl' in content:
                    field.mark('PostSep08ActionEnum.nextUrl')

    def _analyze_stellar_toml_fields(self, section: SEPSection) -> None:
        """Analyze Stellar TOML field support"""
        currency_doc_file = self.sdk_analyzer.find_class_or_struct('CurrencyDocumentation')

        if not currency_doc_file:
            return

        currency_content = read_source(currency_doc_file)

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
                if f'let {prop_name}' in currency_content or f'var {prop_name}' in currency_content:
                    field.mark(sdk_property)

    def _analyze_authorization_flags(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze authorization flag support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'authorization_required':
                if 'authRequired' in content and 'flags.authRequired' in content:
                    field.mark('authorizationRequired() checks authRequired flag')
            elif field.name == 'authorization_revocable':
                if 'authRevocable' in content and 'flags.authRevocable' in content:
                    field.mark('authorizationRequired() checks authRevocable flag')


class SEP09Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-09 (Standard KYC Fields)"""

    KEY_CLASSES = {
        'KYCNaturalPersonFieldsEnum': 'Enum for all natural person KYC fields (34 fields)',
        'KYCNaturalPersonFieldKey': 'Static constants for natural person field keys',
        'KYCOrganizationFieldsEnum': 'Enum for all organization KYC fields (17 fields)',
        'KYCOrganizationFieldKey': 'Static constants for organization field keys',
        'KYCFinancialAccountFieldsEnum': 'Enum for all financial account fields (14 fields)',
        'KYCFinancialAccountFieldKey': 'Static constants for financial account field keys',
        'KYCCardFieldsEnum': 'Enum for all card payment fields (11 fields)',
        'KYCCardFieldKey': 'Static constants for card field keys',
    }

    # The prefix a section's field names carry and its enum cases drop
    FIELD_PREFIXES = {
        'Natural Person Fields': '',
        'Organization Fields': 'organization.',
        'Financial Account Fields': '',
        'Card Fields': 'card.',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-09 implementation"""
        logger.info("Analyzing SEP-09 (Standard KYC Fields) implementation")

        sections = self._create_sections()
        kyc_fields_file = self._implementation_file('KYCNaturalPersonFieldsEnum')

        for section in sections:
            self._analyze_kyc_fields(section, kyc_fields_file)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-09 sections and their fields"""
        return [
            SEPSection('Natural Person Fields', [
                SEPField('last_name', False, 'Family or last name'),
                SEPField('first_name', False, 'Given or first name'),
                SEPField('additional_name', False, 'Middle name or other additional name'),
                SEPField('address_country_code', False, 'Country code for current address'),
                SEPField('state_or_province', False, 'Name of state/province/region/prefecture'),
                SEPField('city', False, 'Name of city/town'),
                SEPField('postal_code', False, "Postal or other code identifying user's locale"),
                SEPField('address', False, 'Entire address (country, state, postal code, street address, etc.) as a multi-line string'),
                SEPField('mobile_number', False, 'Mobile phone number with country code, in E.164 format'),
                SEPField('mobile_number_format', False, 'Expected format of the mobile_number field (E.164, hash, etc.)'),
                SEPField('email_address', False, 'Email address'),
                SEPField('birth_date', False, 'Date of birth (e.g., 1976-07-04)'),
                SEPField('birth_place', False, 'Place of birth (city, state, country; as on passport)'),
                SEPField('birth_country_code', False, 'ISO Code of country of birth (ISO 3166-1 alpha-3)'),
                SEPField('tax_id', False, 'Tax identifier of user in their country (social security number in US)'),
                SEPField('tax_id_name', False, 'Name of the tax ID (SSN or ITIN in the US)'),
                SEPField('occupation', False, 'Occupation ISCO code'),
                SEPField('employer_name', False, 'Name of employer'),
                SEPField('employer_address', False, 'Address of employer'),
                SEPField('language_code', False, 'Primary language (ISO 639-1)'),
                SEPField('id_type', False, 'Type of ID (passport, drivers_license, id_card, etc.)'),
                SEPField('id_country_code', False, 'Country issuing passport or photo ID (ISO 3166-1 alpha-3)'),
                SEPField('id_issue_date', False, 'ID issue date'),
                SEPField('id_expiration_date', False, 'ID expiration date'),
                SEPField('id_number', False, 'Passport or ID number'),
                SEPField('photo_id_front', False, "Image of front of user's photo ID or passport"),
                SEPField('photo_id_back', False, "Image of back of user's photo ID or passport"),
                SEPField('notary_approval_of_photo_id', False, "Image of notary's approval of photo ID or passport"),
                SEPField('ip_address', False, "IP address of customer's computer"),
                SEPField('photo_proof_residence', False, "Image of a utility bill, bank statement or similar with the user's name and address"),
                SEPField('sex', False, 'Gender (male, female, or other)'),
                SEPField('proof_of_income', False, "Image of user's proof of income document"),
                SEPField('proof_of_liveness', False, 'Video or image file of user as a liveness proof'),
                SEPField('referral_id', False, "User's origin (such as an id in another application) or a referral code"),
            ]),
            SEPSection('Organization Fields', [
                SEPField('organization.name', False, 'Full organization name as on the incorporation papers'),
                SEPField('organization.VAT_number', False, 'Organization VAT number'),
                SEPField('organization.registration_number', False, 'Organization registration number'),
                SEPField('organization.registration_date', False, 'Date the organization was registered'),
                SEPField('organization.registered_address', False, 'Organization registered address'),
                SEPField('organization.number_of_shareholders', False, 'Organization shareholder number'),
                SEPField('organization.shareholder_name', False, 'Name of shareholder (can be organization or person)'),
                SEPField('organization.photo_incorporation_doc', False, 'Image of incorporation documents'),
                SEPField('organization.photo_proof_address', False, "Image of a utility bill, bank statement with the organization's name and address"),
                SEPField('organization.address_country_code', False, 'Country code for current address'),
                SEPField('organization.state_or_province', False, 'Name of state/province/region/prefecture'),
                SEPField('organization.city', False, 'Name of city/town'),
                SEPField('organization.postal_code', False, "Postal or other code identifying organization's locale"),
                SEPField('organization.director_name', False, 'Organization registered managing director'),
                SEPField('organization.website', False, 'Organization website'),
                SEPField('organization.email', False, 'Organization contact email'),
                SEPField('organization.phone', False, 'Organization contact phone'),
            ]),
            SEPSection('Financial Account Fields', [
                SEPField('bank_account_number', False, 'Number identifying bank account'),
                SEPField('bank_account_type', False, 'Type of bank account'),
                SEPField('bank_number', False, 'Number identifying bank in national banking system (routing number in US)'),
                SEPField('bank_phone_number', False, 'Phone number with country code for bank'),
                SEPField('bank_branch_number', False, 'Number identifying bank branch'),
                SEPField('bank_name', False, 'Name of the bank'),
                SEPField('clabe_number', False, 'Bank account number for Mexico'),
                SEPField('cbu_number', False, 'Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU)'),
                SEPField('cbu_alias', False, 'The alias for a CBU or CVU'),
                SEPField('crypto_address', False, 'Address for a cryptocurrency account'),
                SEPField('crypto_memo', False, 'A destination tag/memo used to identify a transaction'),
                SEPField('mobile_money_number', False, 'Mobile phone number in E.164 format with which a mobile money account is associated'),
                SEPField('mobile_money_provider', False, 'Name of the mobile money service provider'),
                SEPField('external_transfer_memo', False, 'A destination tag/memo used to identify a transaction'),
            ]),
            SEPSection('Card Fields', [
                SEPField('card.number', False, 'Card number'),
                SEPField('card.expiration_date', False, 'Expiration month and year in YY-MM format (e.g., 29-11, November 2029)'),
                SEPField('card.cvc', False, 'CVC number (Digits on the back of the card)'),
                SEPField('card.holder_name', False, 'Name of the card holder'),
                SEPField('card.network', False, 'Brand of the card/network it operates within (e.g., Visa, Mastercard, AmEx, etc.)'),
                SEPField('card.postal_code', False, 'Billing address postal code'),
                SEPField('card.country_code', False, 'Billing address country code in ISO 3166-1 alpha-2 code (e.g., US)'),
                SEPField('card.state_or_province', False, 'Name of state/province/region/prefecture in ISO 3166-2 format'),
                SEPField('card.city', False, 'Name of city/town'),
                SEPField('card.address', False, 'Entire address (country, state, postal code, street address, etc.) as a multi-line string'),
                SEPField('card.token', False, 'Token representation of the card in some external payment system (e.g., Stripe)'),
            ]),
        ]

    def _analyze_kyc_fields(self, section: SEPSection, kyc_fields_file: Optional[Path]) -> None:
        """Mark each field whose enum case, the camelCase field name without its section prefix, is declared"""
        if not kyc_fields_file:
            return
        content = read_source(kyc_fields_file)
        for field in section.fields:
            words = field.name.replace(self.FIELD_PREFIXES[section.name], '').split('_')
            camel_case = words[0] + ''.join(word.title() for word in words[1:])
            if f'case {camel_case}' in content:
                field.mark(camel_case)


class SEP12Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-12 (KYC API)"""

    KEY_CLASSES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-12 implementation"""
        logger.info("Analyzing SEP-12 (KYC API) implementation")

        sections = self._create_sections()
        kyc_service_file = self._implementation_file('KycService')
        for class_name in ['GetCustomerInfoResponse', 'PutCustomerInfoResponse',
                          'GetCustomerFilesResponse', 'CustomerFileResponse']:
            self._implementation_file(class_name)
        for class_name in ['GetCustomerInfoRequest', 'PutCustomerInfoRequest',
                          'PutCustomerVerificationRequest', 'PutCustomerCallbackRequest']:
            self._implementation_file(class_name)
        self._implementation_file_named('KycAmlFields.swift')
        self._implementation_file('KycServiceError')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-12 sections and their fields"""
        return [
            SEPSection('API Endpoints', [
                SEPField('get_customer', True, 'GET /customer - Check the status of a customers info'),
                SEPField('put_customer', True, 'PUT /customer - Upload customer information to an anchor'),
                SEPField('delete_customer', True, 'DELETE /customer/{account} - Delete all personal information about a customer'),
                SEPField('put_customer_verification', True, 'PUT /customer/verification - Verify customer fields with confirmation codes'),
                SEPField('put_customer_callback', True, 'PUT /customer/callback - Register a callback URL for customer status updates'),
                SEPField('post_customer_files', True, 'POST /customer/files - Upload binary files for customer KYC'),
                SEPField('get_customer_files', True, 'GET /customer/files - Get metadata about uploaded files'),
            ]),
            SEPSection('Authentication', [
                SEPField('jwt_authentication', True, 'JWT Token via SEP-10 - All endpoints require SEP-10 JWT authentication via Authorization header'),
            ]),
            SEPSection('Field Type Specifications', [
                SEPField('type', True, 'Data type of field value'),
                SEPField('description', False, 'Human-readable description of the field'),
                SEPField('choices', False, 'Array of valid values for this field'),
                SEPField('optional', False, 'Whether this field is required to proceed'),
                SEPField('status', False, 'Status of provided field'),
                SEPField('error', False, 'Description of why field was rejected'),
            ]),
            SEPSection('File Upload', [
                SEPField('multipart_file_upload', True, 'Binary files uploaded using multipart/form-data for photo_id, proof_of_address, etc.'),
            ]),
            SEPSection('Request Parameters', [
                SEPField('id', False, 'ID of the customer as returned in previous PUT request'),
                SEPField('account', False, 'Stellar account ID (G...) of the customer'),
                SEPField('memo', False, 'Memo that uniquely identifies a customer in shared accounts'),
                SEPField('memo_type', False, 'Type of memo: text, id, or hash'),
                SEPField('type', False, 'Type of action the customer is being KYCd for'),
                SEPField('transaction_id', False, 'Transaction ID with which customer info is associated'),
                SEPField('lang', False, 'Language code (ISO 639-1) for human-readable responses'),
            ]),
            SEPSection('Response Fields', [
                SEPField('id', False, 'ID of the customer'),
                SEPField('status', True, 'Status of customer KYC process'),
                SEPField('fields', False, 'Fields the anchor has not yet received'),
                SEPField('provided_fields', False, 'Fields the anchor has received'),
                SEPField('message', False, 'Human readable message describing KYC status'),
            ]),
            SEPSection('SEP-9 Integration', [
                SEPField('standard_kyc_fields', True, 'Supports all SEP-9 standard KYC fields for natural persons and organizations'),
            ]),
        ]

    def _analyze_api_endpoints(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze API endpoint support"""
        if not kyc_service_file:
            return

        content = read_source(kyc_service_file)

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
                field.mark(method_name)

    def _analyze_authentication(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze authentication support"""
        if not kyc_service_file:
            return

        content = read_source(kyc_service_file)

        for field in section.fields:
            if field.name == 'jwt_authentication':
                if 'jwtToken:' in content or 'jwt:String' in content:
                    field.mark('JWT Token')

    def _analyze_field_types(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze field type specification support"""
        field_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoField')
        provided_field_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoProvidedField')

        if not field_file and not provided_field_file:
            return

        field_content = ""
        if field_file:
            field_content = read_source(field_file)

        provided_content = ""
        if provided_field_file:
            provided_content = read_source(provided_field_file)

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
                    field.mark(sdk_property)

    def _analyze_file_upload(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze file upload support"""
        if not kyc_service_file:
            return

        content = read_source(kyc_service_file)

        for field in section.fields:
            if field.name == 'multipart_file_upload':
                if 'PUTMultipartRequestWithPath' in content or 'POSTMultipartRequestWithPath' in content:
                    field.mark('multipart/form-data')

    def _analyze_request_parameters(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze request parameter support"""
        request_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoRequest')
        put_request_file = self.sdk_analyzer.find_class_or_struct('PutCustomerInfoRequest')

        if not request_file and not put_request_file:
            return

        request_content = ""
        if request_file:
            request_content = read_source(request_file)

        put_content = ""
        if put_request_file:
            put_content = read_source(put_request_file)

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
                    field.mark(sdk_property)

    def _analyze_response_fields(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze response field support"""
        response_file = self.sdk_analyzer.find_class_or_struct('GetCustomerInfoResponse')

        if not response_file:
            return

        content = read_source(response_file)

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
                    field.mark(sdk_property)

    def _analyze_sep9_integration(self, section: SEPSection, kyc_service_file: Optional[Path]) -> None:
        """Analyze SEP-9 standard KYC fields support"""
        fields_file = self.sdk_analyzer.find_class_or_struct('KYCNaturalPersonFieldsEnum')
        org_file = self.sdk_analyzer.find_class_or_struct('KYCOrganizationFieldsEnum')
        financial_file = self.sdk_analyzer.find_class_or_struct('KYCFinancialAccountFieldsEnum')
        card_file = self.sdk_analyzer.find_class_or_struct('KYCCardFieldsEnum')

        if not any([fields_file, org_file, financial_file, card_file]):
            return

        for field in section.fields:
            if field.name == 'standard_kyc_fields':
                if fields_file or org_file or financial_file or card_file:
                    field.mark('StandardKYCFields')


class SEP10Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-10 (Stellar Web Authentication)"""

    KEY_CLASSES = {
        'WebAuthenticator': 'Main class implementing SEP-10 authentication flow',
        'AccountInformation': 'Contains WEB_AUTH_ENDPOINT and SIGNING_KEY from stellar.toml',
        'SEPConstants': 'Contains WEBAUTH_GRACE_PERIOD_SECONDS for time bounds validation',
        'ChallengeValidationError': 'Error enum for challenge validation failures',
        'GetJWTTokenError': 'Error enum for JWT token retrieval failures',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-10 implementation"""
        logger.info("Analyzing SEP-10 (Stellar Web Authentication) implementation")

        sections = self._create_sections()
        web_auth_file = self._implementation_file('WebAuthenticator')
        self._implementation_file('AccountInformation')
        self._implementation_file_named('SEPConstants.swift')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-10 sections and their fields"""
        return [
            SEPSection('Authentication Endpoints', [
                SEPField('get_auth_challenge', True, 'GET /auth endpoint - Returns challenge transaction'),
                SEPField('post_auth_token', True, 'POST /auth endpoint - Validates signed challenge and returns JWT token'),
            ]),
            SEPSection('Challenge Transaction Features', [
                SEPField('challenge_transaction_generation', True, 'Generate challenge transaction with proper structure'),
                SEPField('home_domain_operation', True, 'First operation contains home_domain + " auth" as data name'),
                SEPField('manage_data_operations', True, 'Challenge uses ManageData operations for auth data'),
                SEPField('nonce_generation', True, 'Random nonce in ManageData operation value'),
                SEPField('sequence_number_zero', True, 'Challenge transaction has sequence number 0'),
                SEPField('server_signature', True, 'Challenge is signed by server before sending to client'),
                SEPField('timebounds_enforcement', True, 'Challenge transaction has timebounds for expiration'),
                SEPField('transaction_envelope_format', True, 'Challenge uses proper Stellar transaction envelope format'),
                SEPField('web_auth_domain_operation', False, 'Optional operation with web_auth_domain for domain verification'),
            ]),
            SEPSection('Client Domain Features', [
                SEPField('client_domain_operation', False, 'Add client_domain ManageData operation to challenge'),
                SEPField('client_domain_parameter', False, 'Support optional client_domain parameter in GET /auth'),
                SEPField('client_domain_signature', False, 'Require signature from client domain account'),
                SEPField('client_domain_verification', False, 'Verify client domain by checking stellar.toml **Note:** This is a server-side verification feature. Client SDKs only need to support the client_domain parameter and signing.', server_only=True),
            ]),
            SEPSection('JWT Token Features', [
                SEPField('jwt_claims', True, 'JWT token includes required claims (sub, iat, exp)'),
                SEPField('jwt_expiration', True, 'JWT token includes expiration time'),
                SEPField('jwt_token_generation', True, 'Generate JWT token after successful challenge validation'),
                SEPField('jwt_token_response', True, 'Return JWT token in JSON response with "token" field'),
                SEPField('jwt_token_validation', False, 'Validate JWT token structure and signature **Note:** This is a server-side validation feature. Client SDKs only need to receive, store, and send the JWT as a bearer token.', server_only=True),
            ]),
            SEPSection('Verification Features', [
                SEPField('challenge_validation', True, 'Validate challenge transaction structure and content'),
                SEPField('home_domain_validation', True, 'Validate home domain in challenge matches server'),
                SEPField('memo_support', False, 'Support optional memo in challenge for muxed accounts'),
                SEPField('multi_signature_support', True, 'Support multiple signatures on challenge (client account + signers)'),
                SEPField('signature_verification', True, 'Verify all signatures on challenge transaction'),
                SEPField('timebounds_validation', True, 'Validate challenge is within valid time window'),
            ]),
        ]

    def _analyze_authentication_endpoints(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze authentication endpoint support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'get_auth_challenge':
                if 'func getChallenge' in content and 'forAccount accountId' in content:
                    field.mark('getChallenge(forAccount:memo:homeDomain:clientDomain:)')
            elif field.name == 'post_auth_token':
                if 'func sendCompletedChallenge' in content and 'base64EnvelopeXDR' in content:
                    field.mark('sendCompletedChallenge(base64EnvelopeXDR:)')

    def _analyze_challenge_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze challenge transaction feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'challenge_transaction_generation':
                if 'func getChallenge' in content:
                    field.mark('getChallenge()')
            elif field.name == 'home_domain_operation':
                if 'serverHomeDomain + " auth"' in content:
                    field.mark('isValidChallenge (home domain validation)')
            elif field.name == 'manage_data_operations':
                if 'case .manageData' in content:
                    field.mark('isValidChallenge (operation type check)')
            elif field.name == 'nonce_generation':
                # Server-side feature, but client receives it
                if 'getChallenge' in content:
                    field.mark('getChallenge (receives nonce)')
            elif field.name == 'sequence_number_zero':
                if 'txSeqNum != 0' in content or 'sequenceNumberNot0' in content:
                    field.mark('isValidChallenge (sequence validation)')
            elif field.name == 'server_signature':
                if 'serverKeyPair.verify' in content or 'invalidSignature' in content:
                    field.mark('isValidChallenge (signature verification)')
            elif field.name == 'timebounds_enforcement':
                if 'timeBounds' in content and 'invalidTimeBounds' in content:
                    field.mark('isValidChallenge (timebounds validation)')
            elif field.name == 'transaction_envelope_format':
                if 'TransactionEnvelopeXDR' in content:
                    field.mark('TransactionEnvelopeXDR')
            elif field.name == 'web_auth_domain_operation':
                if '"web_auth_domain"' in content and 'invalidWebAuthDomain' in content:
                    field.mark('isValidChallenge (web_auth_domain validation)')

    def _analyze_client_domain_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze client domain feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'client_domain_operation':
                if '"client_domain"' in content and 'manageData' in content:
                    field.mark('isValidChallenge (client_domain operation)')
            elif field.name == 'client_domain_parameter':
                if 'clientDomain' in content and 'client_domain=' in content:
                    field.mark('getChallenge(clientDomain:)')
            elif field.name == 'client_domain_signature':
                if 'clientDomainAccountKeyPair' in content and 'signTransaction' in content:
                    field.mark('jwtToken(clientDomainAccountKeyPair:)')
            elif field.name == 'client_domain_verification':
                # This is a server-side-only feature, marked as such in field definition
                # No need to analyze implementation since it's not applicable to client SDKs
                pass

    def _analyze_jwt_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze JWT token feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'jwt_claims':
                # Server-side generates claims, client receives token
                if 'jwtToken' in content and 'sendCompletedChallenge' in content:
                    field.mark('sendCompletedChallenge (receives JWT)')
            elif field.name == 'jwt_expiration':
                # Server-side generates expiration, client receives token
                if 'jwtToken' in content:
                    field.mark('JWT token response')
            elif field.name == 'jwt_token_generation':
                # Server-side feature, client receives it
                if 'sendCompletedChallenge' in content and '"token"' in content:
                    field.mark('sendCompletedChallenge (receives JWT)')
            elif field.name == 'jwt_token_response':
                if '"token"' in content and 'jwtToken' in content:
                    field.mark('sendCompletedChallenge response')
            elif field.name == 'jwt_token_validation':
                # This is a server-side-only feature, marked as such in field definition
                # No need to analyze implementation since it's not applicable to client SDKs
                pass

    def _analyze_verification_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze verification feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'challenge_validation':
                if 'func isValidChallenge' in content:
                    field.mark('isValidChallenge()')
            elif field.name == 'home_domain_validation':
                if 'invalidHomeDomain' in content and 'serverHomeDomain' in content:
                    field.mark('isValidChallenge (home domain check)')
            elif field.name == 'memo_support':
                if 'memo:UInt64?' in content and 'MEMO_TYPE_ID' in content:
                    field.mark('getChallenge(memo:)')
            elif field.name == 'multi_signature_support':
                if 'signers:[KeyPair]' in content and 'signTransaction' in content:
                    field.mark('signTransaction(keyPairs:)')
            elif field.name == 'signature_verification':
                if 'serverKeyPair.verify' in content and 'signature:' in content:
                    field.mark('isValidChallenge (signature verification)')
            elif field.name == 'timebounds_validation':
                if 'timeBounds' in content and 'timeBoundsGracePeriod' in content:
                    field.mark('isValidChallenge (timebounds with grace period)')


class SEP06Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-06 (Deposit and Withdrawal API)"""

    KEY_CLASSES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-06 implementation"""
        logger.info("Analyzing SEP-06 (Deposit and Withdrawal API) implementation")

        sections = self._create_sections()
        transfer_service_file = self._implementation_file('TransferServerService')
        for class_name in ['DepositRequest', 'DepositResponse', 'DepositExchangeRequest',
                           'WithdrawRequest', 'WithdrawResponse', 'WithdrawExchangeRequest',
                           'AnchorInfoResponse', 'AnchorTransactionsResponse', 'AnchorTransaction',
                           'FeeRequest', 'AnchorFeeResponse', 'TransferServerError']:
            self._implementation_file(class_name)

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-06 sections and their fields"""
        return [
            SEPSection('Deposit Endpoints', [
                SEPField('deposit', True, 'GET /deposit - Initiates a deposit transaction for on-chain assets'),
                SEPField('deposit_exchange', False, 'GET /deposit-exchange - Initiates a deposit with asset exchange (SEP-38 integration)'),
            ]),
            SEPSection('Deposit Request Parameters', [
                SEPField('asset_code', True, 'Code of the on-chain asset the user wants to receive'),
                SEPField('account', True, 'Stellar account ID of the user'),
                SEPField('memo_type', False, 'Type of memo to attach to transaction'),
                SEPField('memo', False, 'Value of memo to attach to transaction'),
                SEPField('email_address', False, 'Email address of the user (for notifications)'),
                SEPField('type', False, 'Type of deposit method (e.g., bank_account, cash, mobile_money)'),
                SEPField('wallet_name', False, 'Name of the wallet the user is using'),
                SEPField('wallet_url', False, 'URL of the wallet the user is using'),
                SEPField('lang', False, 'Language code for response messages (ISO 639-1)'),
                SEPField('on_change_callback', False, 'URL for anchor to send callback when transaction status changes'),
                SEPField('amount', False, 'Amount of on-chain asset the user wants to receive'),
                SEPField('country_code', False, 'Country code of the user (ISO 3166-1 alpha-3)'),
                SEPField('claimable_balance_supported', False, 'Whether the client supports receiving claimable balances'),
                SEPField('customer_id', False, 'ID of the customer from SEP-12 KYC process'),
                SEPField('location_id', False, 'ID of the physical location for cash pickup'),
            ]),
            SEPSection('Deposit Response Fields', [
                SEPField('how', True, 'Instructions for how to deposit the asset'),
                SEPField('id', False, 'Persistent transaction identifier'),
                SEPField('eta', False, 'Estimated seconds until deposit completes'),
                SEPField('min_amount', False, 'Minimum deposit amount'),
                SEPField('max_amount', False, 'Maximum deposit amount'),
                SEPField('fee_fixed', False, 'Fixed fee for deposit'),
                SEPField('fee_percent', False, 'Percentage fee for deposit'),
                SEPField('extra_info', False, 'Additional information about the deposit'),
            ]),
            SEPSection('Withdraw Endpoints', [
                SEPField('withdraw', True, 'GET /withdraw - Initiates a withdrawal transaction for off-chain assets'),
                SEPField('withdraw_exchange', False, 'GET /withdraw-exchange - Initiates a withdrawal with asset exchange (SEP-38 integration)'),
            ]),
            SEPSection('Withdraw Request Parameters', [
                SEPField('asset_code', True, 'Code of the on-chain asset the user wants to send'),
                SEPField('type', True, 'Type of withdrawal method (e.g., bank_account, cash, mobile_money)'),
                SEPField('dest', False, 'Destination for withdrawal (bank account number, etc.)'),
                SEPField('dest_extra', False, 'Extra information for destination (routing number, etc.)'),
                SEPField('account', False, 'Stellar account ID of the user'),
                SEPField('memo', False, 'Memo to identify the user if account is shared'),
                SEPField('memo_type', False, 'Type of memo (text, id, or hash)'),
                SEPField('wallet_name', False, 'Name of the wallet the user is using'),
                SEPField('wallet_url', False, 'URL of the wallet the user is using'),
                SEPField('lang', False, 'Language code for response messages (ISO 639-1)'),
                SEPField('on_change_callback', False, 'URL for anchor to send callback when transaction status changes'),
                SEPField('amount', False, 'Amount of on-chain asset the user wants to send'),
                SEPField('country_code', False, 'Country code of the user (ISO 3166-1 alpha-3)'),
                SEPField('refund_memo', False, 'Memo to use for refund transaction if withdrawal fails'),
                SEPField('refund_memo_type', False, 'Type of refund memo (text, id, or hash)'),
                SEPField('customer_id', False, 'ID of the customer from SEP-12 KYC process'),
                SEPField('location_id', False, 'ID of the physical location for cash pickup'),
            ]),
            SEPSection('Withdraw Response Fields', [
                SEPField('account_id', True, 'Stellar account to send withdrawn assets to'),
                SEPField('memo_type', False, 'Type of memo to attach to transaction'),
                SEPField('memo', False, 'Value of memo to attach to transaction'),
                SEPField('id', True, 'Persistent transaction identifier'),
                SEPField('eta', False, 'Estimated seconds until withdrawal completes'),
                SEPField('min_amount', False, 'Minimum withdrawal amount'),
                SEPField('max_amount', False, 'Maximum withdrawal amount'),
                SEPField('fee_fixed', False, 'Fixed fee for withdrawal'),
                SEPField('fee_percent', False, 'Percentage fee for withdrawal'),
                SEPField('extra_info', False, 'Additional information about the withdrawal'),
            ]),
            SEPSection('Info Endpoint', [
                SEPField('info_endpoint', True, 'GET /info - Provides anchor capabilities and asset information'),
            ]),
            SEPSection('Info Response Fields', [
                SEPField('deposit', True, 'Map of asset codes to deposit asset information'),
                SEPField('withdraw', True, 'Map of asset codes to withdraw asset information'),
                SEPField('deposit-exchange', False, 'Map of asset codes to deposit-exchange asset information'),
                SEPField('withdraw-exchange', False, 'Map of asset codes to withdraw-exchange asset information'),
                SEPField('fee', False, 'Fee endpoint information'),
                SEPField('transactions', False, 'Transaction history endpoint information'),
                SEPField('transaction', False, 'Single transaction endpoint information'),
                SEPField('features', False, 'Feature flags supported by the anchor'),
            ]),
            SEPSection('Fee Endpoint', [
                SEPField('fee_endpoint', False, 'GET /fee - Calculates fees for a deposit or withdrawal operation (deprecated)'),
            ]),
            SEPSection('Transaction Endpoints', [
                SEPField('transactions', True, 'GET /transactions - Retrieves transaction history for an account'),
                SEPField('transaction', True, 'GET /transaction - Retrieves details for a single transaction'),
                SEPField('patch_transaction', False, 'PATCH /transaction - Updates transaction fields (for debugging/testing)'),
            ]),
            SEPSection('Transaction Fields', [
                SEPField('id', True, 'Unique transaction identifier'),
                SEPField('kind', True, 'Kind of transaction (deposit, withdrawal, deposit-exchange, withdrawal-exchange)'),
                SEPField('status', True, 'Current status of the transaction'),
                SEPField('started_at', True, 'When transaction was created (ISO 8601)'),
                SEPField('status_eta', False, 'Estimated seconds until status changes'),
                SEPField('amount_in', False, 'Amount received by anchor'),
                SEPField('amount_out', False, 'Amount sent by anchor to user'),
                SEPField('amount_fee', False, 'Total fee charged for transaction'),
                SEPField('completed_at', False, 'When transaction completed (ISO 8601)'),
                SEPField('stellar_transaction_id', False, 'Hash of the Stellar transaction'),
                SEPField('external_transaction_id', False, 'Identifier from external system'),
                SEPField('message', False, 'Human-readable message about transaction'),
                SEPField('refunded', False, 'Whether transaction was refunded'),
                SEPField('refunds', False, 'Refund information if applicable'),
                SEPField('from', False, 'Stellar account that initiated the transaction'),
                SEPField('to', False, 'Stellar account receiving the transaction'),
            ]),
            SEPSection('Transaction Status Values', [
                SEPField('completed', True, 'Transaction completed successfully'),
                SEPField('pending_anchor', True, 'Anchor is processing the transaction'),
                SEPField('pending_stellar', False, 'Stellar transaction has been submitted'),
                SEPField('pending_user_transfer_start', True, 'Waiting for user to initiate off-chain transfer'),
                SEPField('incomplete', True, 'Deposit/withdrawal has not yet been submitted'),
                SEPField('pending_external', False, 'Waiting for external action (banking system, etc.)'),
                SEPField('pending_trust', False, 'User needs to add trustline for asset'),
                SEPField('pending_user', False, 'Waiting for user action (accepting claimable balance)'),
                SEPField('pending_user_transfer_complete', False, 'Off-chain transfer has been initiated'),
                SEPField('error', False, 'Transaction failed with error'),
                SEPField('refunded', False, 'Transaction refunded'),
                SEPField('expired', False, 'Transaction expired without completion'),
            ]),
        ]

    def _analyze_deposit_endpoints(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze deposit endpoint support"""
        if not transfer_service_file:
            return

        content = read_source(transfer_service_file)

        for field in section.fields:
            if field.name == 'deposit':
                if 'func deposit(request: DepositRequest)' in content:
                    field.mark('deposit(request:)')
            elif field.name == 'deposit_exchange':
                if 'func depositExchange(request: DepositExchangeRequest)' in content:
                    field.mark('depositExchange(request:)')

    def _analyze_deposit_request_parameters(self, section: SEPSection) -> None:
        """Analyze deposit request parameter support"""
        self._check_declared_properties(section, 'DepositRequest', {
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
        })

    def _analyze_deposit_response_fields(self, section: SEPSection) -> None:
        """Analyze deposit response field support"""
        self._check_declared_properties(section, 'DepositResponse', {
            'how': 'how',
            'id': 'id',
            'eta': 'eta',
            'min_amount': 'minAmount',
            'max_amount': 'maxAmount',
            'fee_fixed': 'feeFixed',
            'fee_percent': 'feePercent',
            'extra_info': 'extraInfo',
        })

    def _analyze_withdraw_endpoints(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze withdraw endpoint support"""
        if not transfer_service_file:
            return

        content = read_source(transfer_service_file)

        for field in section.fields:
            if field.name == 'withdraw':
                if 'func withdraw(request: WithdrawRequest)' in content:
                    field.mark('withdraw(request:)')
            elif field.name == 'withdraw_exchange':
                if 'func withdrawExchange(request: WithdrawExchangeRequest)' in content:
                    field.mark('withdrawExchange(request:)')

    def _analyze_withdraw_request_parameters(self, section: SEPSection) -> None:
        """Analyze withdraw request parameter support"""
        self._check_declared_properties(section, 'WithdrawRequest', {
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
        })

    def _analyze_withdraw_response_fields(self, section: SEPSection) -> None:
        """Analyze withdraw response field support"""
        self._check_declared_properties(section, 'WithdrawResponse', {
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
        })

    def _analyze_info_endpoint(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze info endpoint support"""
        if not transfer_service_file:
            return

        content = read_source(transfer_service_file)

        for field in section.fields:
            if field.name == 'info_endpoint':
                if 'func info(language:' in content:
                    field.mark('info(language:jwtToken:)')

    def _analyze_info_response_fields(self, section: SEPSection) -> None:
        """Analyze info response field support"""
        self._check_declared_properties(section, 'AnchorInfoResponse', {
            'deposit': 'deposit',
            'withdraw': 'withdraw',
            'deposit-exchange': 'depositExchange',
            'withdraw-exchange': 'withdrawExchange',
            'fee': 'fee',
            'transactions': 'transactions',
            'transaction': 'transaction',
            'features': 'features',
        })

    def _analyze_fee_endpoint(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze fee endpoint support"""
        if not transfer_service_file:
            return

        content = read_source(transfer_service_file)

        for field in section.fields:
            if field.name == 'fee_endpoint':
                if 'func fee(request: FeeRequest)' in content:
                    field.mark('fee(request:)')

    def _analyze_transaction_endpoints(self, section: SEPSection, transfer_service_file: Optional[Path]) -> None:
        """Analyze transaction endpoint support"""
        if not transfer_service_file:
            return

        content = read_source(transfer_service_file)

        for field in section.fields:
            if field.name == 'transactions':
                if 'func getTransactions(request:' in content:
                    field.mark('getTransactions(request:)')
            elif field.name == 'transaction':
                if 'func getTransaction(request:' in content:
                    field.mark('getTransaction(request:)')
            elif field.name == 'patch_transaction':
                if 'func patchTransaction(id:' in content:
                    field.mark('patchTransaction(id:jwt:contentType:body:)')

    def _analyze_transaction_fields(self, section: SEPSection) -> None:
        """Analyze transaction field support"""
        self._check_declared_properties(section, 'AnchorTransaction', {
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
        })

    def _analyze_transaction_status_values(self, section: SEPSection) -> None:
        """Analyze transaction status value support"""
        status_file = self.sdk_analyzer.find_class_or_struct('AnchorTransactionStatus')
        if not status_file:
            return

        content = read_source(status_file)

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
            if sdk_property and f'case {sdk_property}' in content:
                field.mark(sdk_property)


class SEP38Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-38 (Anchor RFQ API)"""

    KEY_CLASSES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-38 implementation"""
        logger.info("Analyzing SEP-38 (Anchor RFQ API) implementation")

        sections = self._create_sections()
        quote_service_file = self._implementation_file('QuoteService')
        self._implementation_file('Sep38PostQuoteRequest')
        for response_class in ['Sep38InfoResponse', 'Sep38PricesResponse', 'Sep38PriceResponse',
                                'Sep38QuoteResponse', 'Sep38Asset', 'Sep38BuyAsset',
                                'Sep38Fee', 'Sep38FeeDetails']:
            self._implementation_file(response_class)
        self._implementation_file('QuoteServiceError')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-38 sections and their fields"""
        return [
            SEPSection('Info Endpoint', [
                SEPField('info_endpoint', True, 'GET /info - Returns supported Stellar and off-chain assets available for trading'),
            ]),
            SEPSection('Info Response Fields', [
                SEPField('assets', True, 'Array of asset objects supported for trading'),
            ]),
            SEPSection('Asset Fields', [
                SEPField('asset', True, 'Asset identifier in Asset Identification Format'),
                SEPField('sell_delivery_methods', False, 'Array of delivery methods for selling this asset'),
                SEPField('buy_delivery_methods', False, 'Array of delivery methods for buying this asset'),
                SEPField('country_codes', False, 'Array of ISO 3166-2 or ISO 3166-1 alpha-2 country codes'),
            ]),
            SEPSection('Delivery Method Fields', [
                SEPField('name', True, 'Delivery method name identifier'),
                SEPField('description', True, 'Human-readable description of the delivery method'),
            ]),
            SEPSection('Prices Endpoint', [
                SEPField('prices_endpoint', True, 'GET /prices - Returns indicative prices of off-chain assets in exchange for Stellar assets'),
            ]),
            SEPSection('Prices Request Parameters', [
                SEPField('sell_asset', True, 'Asset to sell using Asset Identification Format'),
                SEPField('sell_amount', True, 'Amount of sell_asset to exchange'),
                SEPField('sell_delivery_method', False, 'Delivery method for off-chain sell asset'),
                SEPField('buy_delivery_method', False, 'Delivery method for off-chain buy asset'),
                SEPField('country_code', False, 'ISO 3166-2 or ISO-3166-1 alpha-2 country code'),
            ]),
            SEPSection('Prices Response Fields', [
                SEPField('buy_assets', True, 'Array of buy asset objects with prices'),
            ]),
            SEPSection('Buy Asset Fields', [
                SEPField('asset', True, 'Asset identifier in Asset Identification Format'),
                SEPField('price', True, 'Price offered by anchor for one unit of buy_asset'),
                SEPField('decimals', True, 'Number of decimals for the buy asset'),
            ]),
            SEPSection('Price Endpoint', [
                SEPField('price_endpoint', True, 'GET /price - Returns indicative price for a specific asset pair'),
            ]),
            SEPSection('Price Request Parameters', [
                SEPField('context', True, 'Context for quote usage (sep6 or sep31)'),
                SEPField('sell_asset', True, 'Asset client would like to sell'),
                SEPField('buy_asset', True, 'Asset client would like to exchange for sell_asset'),
                SEPField('sell_amount', False, 'Amount of sell_asset to exchange (mutually exclusive with buy_amount)'),
                SEPField('buy_amount', False, 'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)'),
                SEPField('sell_delivery_method', False, 'Delivery method for off-chain sell asset'),
                SEPField('buy_delivery_method', False, 'Delivery method for off-chain buy asset'),
                SEPField('country_code', False, 'ISO 3166-2 or ISO-3166-1 alpha-2 country code'),
            ]),
            SEPSection('Price Response Fields', [
                SEPField('total_price', True, 'Total conversion price including fees'),
                SEPField('price', True, 'Base conversion price excluding fees'),
                SEPField('sell_amount', True, 'Amount of sell_asset that will be exchanged'),
                SEPField('buy_amount', True, 'Amount of buy_asset that will be received'),
                SEPField('fee', True, 'Fee object with total, asset, and optional details'),
            ]),
            SEPSection('Post Quote Endpoint', [
                SEPField('post_quote_endpoint', True, 'POST /quote - Request a firm quote for asset exchange'),
            ]),
            SEPSection('Post Quote Request Fields', [
                SEPField('context', True, 'Context for quote usage (sep6 or sep31)'),
                SEPField('sell_asset', True, 'Asset client would like to sell'),
                SEPField('buy_asset', True, 'Asset client would like to exchange for sell_asset'),
                SEPField('sell_amount', False, 'Amount of sell_asset to exchange (mutually exclusive with buy_amount)'),
                SEPField('buy_amount', False, 'Amount of buy_asset to exchange for (mutually exclusive with sell_amount)'),
                SEPField('expire_after', False, 'Requested expiration timestamp for the quote (ISO 8601)'),
                SEPField('sell_delivery_method', False, 'Delivery method for off-chain sell asset'),
                SEPField('buy_delivery_method', False, 'Delivery method for off-chain buy asset'),
                SEPField('country_code', False, 'ISO 3166-2 or ISO-3166-1 alpha-2 country code'),
            ]),
            SEPSection('Get Quote Endpoint', [
                SEPField('get_quote_endpoint', True, 'GET /quote/:id - Fetch a previously-provided firm quote'),
            ]),
            SEPSection('Quote Response Fields', [
                SEPField('id', True, 'Unique identifier for the quote'),
                SEPField('expires_at', True, 'Expiration timestamp for the quote (ISO 8601)'),
                SEPField('total_price', True, 'Total conversion price including fees'),
                SEPField('price', True, 'Base conversion price excluding fees'),
                SEPField('sell_asset', True, 'Asset to be sold'),
                SEPField('sell_amount', True, 'Amount of sell_asset to be exchanged'),
                SEPField('buy_asset', True, 'Asset to be bought'),
                SEPField('buy_amount', True, 'Amount of buy_asset to be received'),
                SEPField('fee', True, 'Fee object with total, asset, and optional details'),
            ]),
            SEPSection('Fee Fields', [
                SEPField('total', True, 'Total fee amount as decimal string'),
                SEPField('asset', True, 'Asset identifier for the fee'),
                SEPField('details', False, 'Optional array of fee breakdown objects'),
            ]),
            SEPSection('Fee Details Fields', [
                SEPField('name', True, 'Name identifier for the fee component'),
                SEPField('amount', True, 'Fee amount as decimal string'),
                SEPField('description', False, 'Human-readable description of the fee'),
            ]),
        ]

    def _analyze_info_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze info endpoint support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

        for field in section.fields:
            if field.name == 'info_endpoint':
                if 'func info(jwt:' in content and '/info' in content:
                    field.mark('info(jwt:)')

    def _analyze_info_response_fields(self, section: SEPSection) -> None:
        """Analyze info response field support"""
        info_response_file = self.sdk_analyzer.find_class_or_struct('Sep38InfoResponse')
        if not info_response_file:
            return

        content = read_source(info_response_file)

        for field in section.fields:
            if field.name == 'assets':
                if ('let assets:' in content or 'var assets:' in content) and 'Sep38Asset' in content:
                    field.mark('assets')

    def _analyze_asset_fields(self, section: SEPSection) -> None:
        """Analyze asset field support"""
        self._check_declared_properties(section, 'Sep38Asset', {
            'asset': 'asset',
            'sell_delivery_methods': 'sellDeliveryMethods',
            'buy_delivery_methods': 'buyDeliveryMethods',
            'country_codes': 'countryCodes',
        })

    def _analyze_delivery_method_fields(self, section: SEPSection) -> None:
        """Analyze delivery method field support"""
        sell_dm_file = self.sdk_analyzer.find_class_or_struct('Sep38SellDeliveryMethod')
        buy_dm_file = self.sdk_analyzer.find_class_or_struct('Sep38BuyDeliveryMethod')

        if not sell_dm_file and not buy_dm_file:
            return

        # Use whichever file exists (both have same structure)
        content = (read_source(sell_dm_file) if sell_dm_file
                  else read_source(buy_dm_file))

        field_map = {
            'name': 'name',
            'description': 'description',
        }

        for field in section.fields:
            sdk_property = field_map.get(field.name)
            if sdk_property and (f'let {sdk_property}:' in content or f'var {sdk_property}:' in content):
                field.mark(sdk_property)

    def _analyze_prices_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze prices endpoint support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

        for field in section.fields:
            if field.name == 'prices_endpoint':
                if 'func prices(sellAsset:' in content and '/prices' in content:
                    field.mark('prices(sellAsset:sellAmount:sellDeliveryMethod:buyDeliveryMethod:countryCode:jwt:)')

    def _analyze_prices_request_parameters(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze prices request parameter support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

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
                if f'{sdk_property}:' in content and 'func prices(' in content:
                    field.mark(sdk_property)

    def _analyze_prices_response_fields(self, section: SEPSection) -> None:
        """Analyze prices response field support"""
        prices_response_file = self.sdk_analyzer.find_class_or_struct('Sep38PricesResponse')
        if not prices_response_file:
            return

        content = read_source(prices_response_file)

        for field in section.fields:
            if field.name == 'buy_assets':
                if ('let buyAssets:' in content or 'var buyAssets:' in content) and 'Sep38BuyAsset' in content:
                    field.mark('buyAssets')

    def _analyze_buy_asset_fields(self, section: SEPSection) -> None:
        """Analyze buy asset field support"""
        self._check_declared_properties(section, 'Sep38BuyAsset', {
            'asset': 'asset',
            'price': 'price',
            'decimals': 'decimals',
        })

    def _analyze_price_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze price endpoint support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

        for field in section.fields:
            if field.name == 'price_endpoint':
                if 'func price(context:' in content and '/price' in content:
                    field.mark('price(context:sellAsset:buyAsset:sellAmount:buyAmount:sellDeliveryMethod:buyDeliveryMethod:countryCode:jwt:)')

    def _analyze_price_request_parameters(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze price request parameter support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

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
                if f'{sdk_property}:' in content and 'func price(' in content:
                    field.mark(sdk_property)

    def _analyze_price_response_fields(self, section: SEPSection) -> None:
        """Analyze price response field support"""
        self._check_declared_properties(section, 'Sep38PriceResponse', {
            'total_price': 'totalPrice',
            'price': 'price',
            'sell_amount': 'sellAmount',
            'buy_amount': 'buyAmount',
            'fee': 'fee',
        })

    def _analyze_post_quote_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze post quote endpoint support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

        for field in section.fields:
            if field.name == 'post_quote_endpoint':
                if 'func postQuote(request:' in content and 'POST' in content and '/quote' in content:
                    field.mark('postQuote(request:jwt:)')

    def _analyze_post_quote_request_fields(self, section: SEPSection) -> None:
        """Analyze post quote request field support"""
        self._check_declared_properties(section, 'Sep38PostQuoteRequest', {
            'context': 'context',
            'sell_asset': 'sellAsset',
            'buy_asset': 'buyAsset',
            'sell_amount': 'sellAmount',
            'buy_amount': 'buyAmount',
            'expire_after': 'expireAfter',
            'sell_delivery_method': 'sellDeliveryMethod',
            'buy_delivery_method': 'buyDeliveryMethod',
            'country_code': 'countryCode',
        })

    def _analyze_get_quote_endpoint(self, section: SEPSection, quote_service_file: Optional[Path]) -> None:
        """Analyze get quote endpoint support"""
        if not quote_service_file:
            return

        content = read_source(quote_service_file)

        for field in section.fields:
            if field.name == 'get_quote_endpoint':
                if 'func getQuote(id:' in content and '/quote' in content:
                    field.mark('getQuote(id:jwt:)')

    def _analyze_quote_response_fields(self, section: SEPSection) -> None:
        """Analyze quote response field support"""
        self._check_declared_properties(section, 'Sep38QuoteResponse', {
            'id': 'id',
            'expires_at': 'expiresAt',
            'total_price': 'totalPrice',
            'price': 'price',
            'sell_asset': 'sellAsset',
            'sell_amount': 'sellAmount',
            'buy_asset': 'buyAsset',
            'buy_amount': 'buyAmount',
            'fee': 'fee',
        })

    def _analyze_fee_fields(self, section: SEPSection) -> None:
        """Analyze fee field support"""
        self._check_declared_properties(section, 'Sep38Fee', {
            'total': 'total',
            'asset': 'asset',
            'details': 'details',
        })

    def _analyze_fee_details_fields(self, section: SEPSection) -> None:
        """Analyze fee details field support"""
        self._check_declared_properties(section, 'Sep38FeeDetails', {
            'name': 'name',
            'amount': 'amount',
            'description': 'description',
        })


@dataclass(frozen=True)
class StrKeyType:
    """One row of the SEP-23 version byte table"""
    name: str  # Key type as printed (e.g. "STRKEY_PUBKEY")
    base_expression: str  # Base value expression as printed (e.g. "6 << 3")
    version_byte: int  # The evaluated base value (e.g. 48)
    first_char: str  # First character of the encoded strkey (e.g. "G")


@dataclass(frozen=True)
class StrKeyTestVector:
    """One numbered case of the SEP-23 valid or invalid test cases"""
    name: str  # Position in its list (e.g. "valid_01", "invalid_09")
    title: str  # Case title with its line breaks collapsed
    strkey: str  # The strkey the case lists


@dataclass(frozen=True)
class StrKeySdkNames:
    """The SDK names implementing one SEP-23 key type"""
    version_byte_case: str  # Case of the VersionByte enum
    encode_function: str  # Data extension function in Data+KeyUtils.swift
    decode_function: str  # String extension function in String+KeyUtils.swift


class SEP23SpecParser:
    """Reads the key types and the test vectors from the SEP-23 Markdown

    Items come from the fetched text, so a key type or test case added upstream appears in the
    next matrix. A missing, empty or malformed table, section, subsection or case list raises
    ValueError, which ends the run before a matrix is written.
    """

    SPECIFICATION_HEADING = '## Specification'
    TESTS_HEADING = '## Tests'
    VALID_HEADING = '### Valid test cases'
    INVALID_HEADING = '### Invalid test cases'

    KEY_TYPE_COLUMN = 'Key type'
    BASE_VALUE_COLUMN = 'Base value'
    FIRST_CHAR_COLUMN = 'First char'

    # The paragraph after the invalid cases introduces a C array repeating their strkeys.
    INVALID_LIST_END = 'You can paste'

    HEADING = re.compile(r'^(#+)\s')
    SEPARATOR_CELL = re.compile(r':?-+:?')
    # A base value is an integer or a shift expression such as "6 << 3".
    BASE_VALUE = re.compile(r'(?P<value>\d+)(?:\s*<<\s*(?P<shift>\d+))?')
    CASE_START = re.compile(r'^\d+\.\s+(\S.*)$')
    # The strkey sits on the "- Strkey" line or, after "- Strkey:", on the next line.
    CASE_STRKEY = re.compile(r'- Strkey:?\s*\n?\s*`([^`]+)`')

    def parse_key_types(self, content: str) -> List[StrKeyType]:
        """The rows of the version byte table, in document order"""
        specification = self._section(content.split('\n'), self.SPECIFICATION_HEADING) or []

        header_index = next(
            (index for index, line in enumerate(specification) if self._is_version_byte_header(line)),
            None
        )
        if header_index is None:
            raise ValueError(
                f"SEP-23 text has no version byte table: no table under {self.SPECIFICATION_HEADING} "
                f"has a header row naming '{self.KEY_TYPE_COLUMN}' and '{self.FIRST_CHAR_COLUMN}'"
            )
        header = self._cells(specification[header_index])
        if self.BASE_VALUE_COLUMN not in header:
            raise ValueError(f"SEP-23 version byte table has no '{self.BASE_VALUE_COLUMN}' column")

        key_types = []
        for line in specification[header_index + 1:]:
            if not line.lstrip().startswith('|'):
                break
            cells = self._cells(line)
            if all(self.SEPARATOR_CELL.fullmatch(cell) for cell in cells):
                continue
            row = dict(zip(header, cells))
            if (len(cells) != len(header) or not row[self.KEY_TYPE_COLUMN]
                    or not row[self.FIRST_CHAR_COLUMN]):
                raise ValueError(f"SEP-23 version byte table row does not match its header: {line.strip()}")
            key_types.append(StrKeyType(
                name=row[self.KEY_TYPE_COLUMN],
                base_expression=row[self.BASE_VALUE_COLUMN],
                version_byte=self._evaluate_base_value(row[self.BASE_VALUE_COLUMN]),
                first_char=row[self.FIRST_CHAR_COLUMN],
            ))

        if not key_types:
            raise ValueError("SEP-23 version byte table has no rows")
        return key_types

    def _is_version_byte_header(self, line: str) -> bool:
        """Whether a line is a table header row naming the key type and first char columns"""
        cells = self._cells(line)
        return (line.lstrip().startswith('|')
                and self.KEY_TYPE_COLUMN in cells and self.FIRST_CHAR_COLUMN in cells)

    def parse_test_vectors(self, content: str) -> Tuple[List[StrKeyTestVector], List[StrKeyTestVector]]:
        """The valid and the invalid test cases, each list in document order"""
        tests = self._section(content.split('\n'), self.TESTS_HEADING)
        if tests is None:
            raise ValueError(f"SEP-23 text has no {self.TESTS_HEADING} section")

        valid = self._subsection(tests, self.VALID_HEADING)
        invalid = self._subsection(tests, self.INVALID_HEADING)
        end = next(
            (index for index, line in enumerate(invalid) if line.startswith(self.INVALID_LIST_END)),
            len(invalid)
        )

        return (
            self._parse_cases(valid, 'valid', self.VALID_HEADING),
            self._parse_cases(invalid[:end], 'invalid', self.INVALID_HEADING),
        )

    def _subsection(self, tests: List[str], heading: str) -> List[str]:
        """The lines of a subsection of the Tests section"""
        lines = self._section(tests, heading)
        if lines is None:
            raise ValueError(f"SEP-23 {self.TESTS_HEADING} section has no {heading} subsection")
        return lines

    def _parse_cases(self, lines: List[str], prefix: str, heading: str) -> List[StrKeyTestVector]:
        """One test vector per numbered case, named by its position in the list

        The title is the text after the list number up to the first blank line, with its line
        breaks and indentation collapsed to single spaces.
        """
        starts = [index for index, line in enumerate(lines) if self.CASE_START.match(line)]
        if not starts:
            raise ValueError(f"SEP-23 {heading} lists no test cases")

        vectors = []
        for position, (start, end) in enumerate(zip(starts, starts[1:] + [len(lines)]), start=1):
            case = lines[start:end]
            title_lines = [self.CASE_START.match(case[0]).group(1)]
            for line in case[1:]:
                if not line.strip():
                    break
                title_lines.append(line)
            title = ' '.join(line.strip() for line in title_lines)

            strkeys = self.CASE_STRKEY.findall('\n'.join(case))
            if len(strkeys) != 1:
                raise ValueError(
                    f"SEP-23 {heading} case '{title}' lists {len(strkeys)} strkeys, expected one"
                )
            vectors.append(StrKeyTestVector(name=f'{prefix}_{position:02d}', title=title, strkey=strkeys[0]))

        return vectors

    def _section(self, lines: List[str], heading: str) -> Optional[List[str]]:
        """The lines below a heading up to the next heading of the same or a higher level

        Returns None when the heading is absent.
        """
        level = len(heading) - len(heading.lstrip('#'))
        start = next((index for index, line in enumerate(lines) if line.rstrip() == heading), None)
        if start is None:
            return None

        body = []
        for line in lines[start + 1:]:
            marker = self.HEADING.match(line)
            if marker and len(marker.group(1)) <= level:
                break
            body.append(line)
        return body

    def _evaluate_base_value(self, expression: str) -> int:
        """The version byte a base value such as "6 << 3" or "48" stands for"""
        match = self.BASE_VALUE.fullmatch(expression)
        if not match:
            raise ValueError(
                f"SEP-23 base value '{expression}' is neither an integer nor a shift expression such as '6 << 3'"
            )
        return int(match.group('value')) << int(match.group('shift') or 0)

    @staticmethod
    def _cells(row: str) -> List[str]:
        """The trimmed cells of a Markdown table row"""
        return [cell.strip() for cell in row.strip().strip('|').split('|')]


class SEP23Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-23: Strkeys - The ASCII encoding of Stellar account IDs, muxed accounts, keys and signers

    A key type is implemented when its VersionByte case carries the evaluated base value of the
    version byte table. The case and the mapped encode and decode functions are looked up by name
    in the file text; a key type mapped to None is one the SDK does not implement. A test vector
    is implemented when it appears as a complete double-quoted literal in the StrKey unit test
    file; presence does not show which assertion uses the vector, or in which direction.

    The file names, the enum and the key type to SDK name mapping are generator constants. A
    missing or unreadable file, an absent enum, case or function, a case value that is not a
    Swift integer literal, or a key type without an entry in SDK_NAMES raises ValueError and ends
    the run before a matrix is written.
    """

    KEY_CLASSES = {
        'VersionByte': 'Enum of the version bytes, one case per SEP-23 key type, with the encoded lengths each type allows',
        'Data+KeyUtils': 'Data extension with one encode function per key type, writing the version byte, the key bytes and the CRC-16 checksum as unpadded base32',
        'String+KeyUtils': 'String extension with one decode and one isValid function per key type; decoding checks the length, the canonical base32 re-encoding, the version byte, the checksum and the signed payload and claimable balance framing',
    }

    SECTION_KEY_TYPES = 'Key types'
    SECTION_TEST_VECTORS = 'Test vectors quoted in the StrKey unit test files'

    VERSION_BYTE_FILE = 'VersionByte.swift'
    ENCODE_FILE = 'Data+KeyUtils.swift'
    DECODE_FILE = 'String+KeyUtils.swift'

    # SDKAnalyzer searches only the SDK sources, so the unit test file is read by its path.
    TEST_FILE = 'stellarsdk/stellarsdkUnitTests/sep/strkey/StrKeyUnitTests.swift'

    # The VersionByte case, the Data encode function and the String decode function of each key
    # type; None marks a key type the SDK does not implement.
    SDK_NAMES: Dict[str, Optional[StrKeySdkNames]] = {
        'STRKEY_PUBKEY': StrKeySdkNames('ed25519PublicKey', 'encodeEd25519PublicKey', 'decodeEd25519PublicKey'),
        'STRKEY_MUXED': StrKeySdkNames('med25519PublicKey', 'encodeMEd25519AccountId', 'decodeMed25519PublicKey'),
        'STRKEY_PRIVKEY': StrKeySdkNames('ed25519SecretSeed', 'encodeEd25519SecretSeed', 'decodeEd25519SecretSeed'),
        'STRKEY_PRE_AUTH_TX': StrKeySdkNames('preAuthTX', 'encodePreAuthTx', 'decodePreAuthTx'),
        'STRKEY_HASH_X': StrKeySdkNames('sha256Hash', 'encodeSha256Hash', 'decodeSha256Hash'),
        'STRKEY_SIGNED_PAYLOAD': StrKeySdkNames('signedPayload', 'encodeSignedPayload', 'decodeSignedPayload'),
        'STRKEY_CONTRACT': StrKeySdkNames('contract', 'encodeContractId', 'decodeContractId'),
        'STRKEY_LIQUIDITY_POOL': StrKeySdkNames('liquidityPool', 'encodeLiquidityPoolId', 'decodeLiquidityPoolId'),
        'STRKEY_CLAIMABLE_BALANCE': StrKeySdkNames('claimableBalance', 'encodeClaimableBalanceId', 'decodeClaimableBalanceId'),
    }

    # UInt8 is the raw type; further conformances may follow it.
    VERSION_BYTE_ENUM = re.compile(r'\benum\s+VersionByte\s*:\s*UInt8\b[^{]*\{')
    # A Swift integer literal: hexadecimal, octal, binary or decimal, with _ separators after
    # the first digit.
    SWIFT_INTEGER_LITERAL = re.compile(
        r'0x(?P<hex>[0-9A-Fa-f][0-9A-Fa-f_]*)|0o(?P<octal>[0-7][0-7_]*)|0b(?P<binary>[01][01_]*)'
        r'|(?P<decimal>[0-9][0-9_]*)'
    )

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-23 implementation"""
        logger.info("Analyzing SEP-23 (Strkeys) implementation")

        parser = SEP23SpecParser()
        key_types = parser.parse_key_types(sep_info.raw_content)
        valid_vectors, invalid_vectors = parser.parse_test_vectors(sep_info.raw_content)
        logger.info(
            f"SEP-23 lists {len(key_types)} key types, {len(valid_vectors)} valid and "
            f"{len(invalid_vectors)} invalid test vectors"
        )

        self.implementation_files = [self._find_source(name)
                                     for name in (self.VERSION_BYTE_FILE, self.ENCODE_FILE, self.DECODE_FILE)]
        version_byte_path, encode_path, decode_path = self.implementation_files
        enum_body = self._enum_body(self._read(version_byte_path), version_byte_path)
        sources = {
            self.VERSION_BYTE_FILE: (version_byte_path, enum_body),
            self.ENCODE_FILE: (encode_path, self._read(encode_path)),
            self.DECODE_FILE: (decode_path, self._read(decode_path)),
        }
        test_source = self._read(self.TEST_FILE)

        return self._matrix(sep_info, [
            self._key_type_section(key_types, sources),
            self._test_vector_section(valid_vectors + invalid_vectors, test_source),
        ])

    def _key_type_section(self, key_types: List[StrKeyType], sources: Dict[str, Tuple[str, str]]) -> SEPSection:
        """One field per key type of the version byte table

        sources maps each StrKey source file name to its SDK-relative path and text; for
        VersionByte.swift the text is the enum body.
        """
        version_byte_path, enum_body = sources[self.VERSION_BYTE_FILE]
        encode_path, encoders = sources[self.ENCODE_FILE]
        decode_path, decoders = sources[self.DECODE_FILE]

        section = SEPSection(name=self.SECTION_KEY_TYPES)
        for key_type in key_types:
            if key_type.name not in self.SDK_NAMES:
                raise ValueError(f"SEP-23 key type {key_type.name} has no entry in SEP23Analyzer.SDK_NAMES")
            names = self.SDK_NAMES[key_type.name]
            field = SEPField(key_type.name, True, f'Base value {key_type.base_expression} = {key_type.version_byte}, '
                                                  f'first character {key_type.first_char}')
            if names is not None:
                value = self._case_value(enum_body, names.version_byte_case, version_byte_path)
                self._require_function(encoders, names.encode_function, encode_path)
                self._require_function(decoders, names.decode_function, decode_path)
                if value == key_type.version_byte:
                    field.mark(f'VersionByte.{names.version_byte_case}, '
                               f'{names.encode_function}(), {names.decode_function}()')
            section.fields.append(field)
        return section

    def _test_vector_section(self, vectors: List[StrKeyTestVector], test_source: str) -> SEPSection:
        """One field per test case, implemented when its vector is a complete double-quoted literal in
        stellarsdk/stellarsdkUnitTests/sep/strkey/StrKeyUnitTests.swift

        The closing quote keeps a vector that prefixes a longer one apart. The description names
        the file without its directory and before the case title, because the renderer cuts
        descriptions at 150 characters.
        """
        section = SEPSection(name=self.SECTION_TEST_VECTORS)
        file_name = Path(self.TEST_FILE).name
        for vector in vectors:
            field = SEPField(vector.name, True, f'quoted in `{file_name}`: {vector.title}')
            if f'"{vector.strkey}"' in test_source:
                field.implemented = True
            section.fields.append(field)
        return section

    def _enum_body(self, source: str, path: str) -> str:
        """The text between the braces of the VersionByte enum, found by counting braces"""
        declaration = self.VERSION_BYTE_ENUM.search(source)
        if declaration is None:
            raise ValueError(f"SEP-23 enum VersionByte: UInt8 not found in {path}")
        depth = 1
        for brace in re.finditer(r'[{}]', source[declaration.end():]):
            depth += 1 if brace.group() == '{' else -1
            if depth == 0:
                return source[declaration.end():declaration.end() + brace.start()]
        raise ValueError(f"SEP-23 enum VersionByte: UInt8 in {path} has no closing brace")

    def _case_value(self, enum_body: str, name: str, path: str) -> int:
        """The raw value of a VersionByte case, read from its declaration line without its line comment"""
        case = re.search(r'\bcase\s+' + re.escape(name) + r'\b(?P<definition>[^\n]*)', enum_body)
        if case is None:
            raise ValueError(f"SEP-23 VersionByte case {name} not found in {path}")
        definition = case.group('definition').split('//')[0]
        raw_value = re.fullmatch(r'\s*=\s*(?P<literal>\S+)\s*', definition)
        value = None if raw_value is None else self._swift_integer(raw_value.group('literal'))
        if value is None:
            declaration = ' '.join((name + definition).split())
            raise ValueError(f"SEP-23 cannot evaluate VersionByte case '{declaration}' in {path}")
        return value

    @classmethod
    def _swift_integer(cls, literal: str) -> Optional[int]:
        """The value of a Swift integer literal, or None when literal is not one"""
        match = cls.SWIFT_INTEGER_LITERAL.fullmatch(literal)
        if match is None:
            return None
        bases = {'hex': 16, 'octal': 8, 'binary': 2, 'decimal': 10}
        kind = next(name for name in bases if match.group(name) is not None)
        return int(match.group(kind).replace('_', ''), bases[kind])

    @staticmethod
    def _require_function(source: str, name: str, path: str) -> None:
        """Raise unless the file text declares a function with this name"""
        if re.search(r'\bfunc\s+' + re.escape(name) + r'\s*\(', source) is None:
            raise ValueError(f"SEP-23 function {name} not found in {path}")

    def _find_source(self, filename: str) -> str:
        """The SDK-relative path of a StrKey source file"""
        file_path = self.sdk_analyzer.find_file_by_name(filename)
        if file_path is None:
            search_root = self.sdk_analyzer.get_relative_path(self.sdk_analyzer.stellarsdk_path)
            raise ValueError(f"SEP-23 source file {filename} not found under {search_root}")
        return self.sdk_analyzer.get_relative_path(file_path)

    def _read(self, path: str) -> str:
        """The text of the file at an SDK-relative path"""
        try:
            return (self.sdk_analyzer.sdk_root / path).read_text(encoding='utf-8')
        except (OSError, UnicodeDecodeError) as e:
            raise ValueError(f"SEP-23 cannot read {path}: {e}") from e


class SEP24Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-24 (Hosted Deposit and Withdrawal)"""

    KEY_CLASSES = {
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

    # Sep24Transaction carries the status as a String, so it represents every value once the class exists.
    TRANSACTION_STATUS_VALUES = [
        'incomplete', 'pending_user_transfer_start', 'pending_user_transfer_complete', 'pending_external',
        'pending_anchor', 'pending_stellar', 'pending_trust', 'pending_user', 'completed', 'refunded',
        'expired', 'error',
    ]

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-24 implementation"""
        logger.info("Analyzing SEP-24 (Hosted Deposit and Withdrawal) implementation")

        sections = self._create_sections()
        service_file = self._implementation_file('InteractiveService')
        for request_class in ['Sep24DepositRequest', 'Sep24WithdrawRequest',
                               'Sep24FeeRequest', 'Sep24TransactionRequest',
                               'Sep24TransactionsRequest']:
            self._implementation_file(request_class)
        self._implementation_file('InteractiveServiceError')
        for response_class in ['Sep24InfoResponse', 'Sep24InteractiveResponse',
                                'Sep24TransactionResponse', 'Sep24TransactionsResponse',
                                'Sep24FeeResponse', 'Sep24DepositAsset',
                                'Sep24WithdrawAsset', 'Sep24Transaction',
                                'Sep24FeeEndpointInfo', 'Sep24FeatureFlags']:
            self._implementation_file(response_class)

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-24 sections and their fields"""
        return [
            SEPSection('Info Endpoint', [
                SEPField('info_endpoint', True, 'GET /info - Provides anchor capabilities and supported assets for interactive deposits/withdrawals'),
            ]),
            SEPSection('Interactive Deposit Endpoint', [
                SEPField('interactive_deposit', True, 'POST /transactions/deposit/interactive - Initiates an interactive deposit transaction'),
            ]),
            SEPSection('Interactive Withdraw Endpoint', [
                SEPField('interactive_withdraw', True, 'POST /transactions/withdraw/interactive - Initiates an interactive withdrawal transaction'),
            ]),
            SEPSection('Transaction Endpoints', [
                SEPField('transactions', True, 'GET /transactions - Retrieves transaction history for authenticated account'),
                SEPField('transaction', True, 'GET /transaction - Retrieves details for a single transaction'),
            ]),
            SEPSection('Fee Endpoint', [
                SEPField('fee_endpoint', False, 'GET /fee - Calculates fees for a deposit or withdrawal operation (optional)'),
            ]),
            SEPSection('Deposit Request Parameters', [
                SEPField('asset_code', True, 'Code of the Stellar asset the user wants to receive'),
                SEPField('asset_issuer', False, 'Issuer of the Stellar asset (optional if anchor is issuer)'),
                SEPField('source_asset', False, 'Off-chain asset user wants to deposit (in SEP-38 format)'),
                SEPField('amount', False, 'Amount of asset to deposit'),
                SEPField('quote_id', False, 'ID from SEP-38 quote (for asset exchange)'),
                SEPField('account', False, 'Stellar or muxed account for receiving deposit'),
                SEPField('memo', False, 'Memo value for transaction identification'),
                SEPField('memo_type', False, 'Type of memo (text, id, or hash)'),
                SEPField('wallet_name', False, 'Name of wallet for user communication'),
                SEPField('wallet_url', False, 'URL to link in transaction notifications'),
                SEPField('lang', False, 'Language code for UI and messages (RFC 4646)'),
                SEPField('claimable_balance_supported', False, 'Whether client supports claimable balances'),
            ]),
            SEPSection('Withdraw Request Parameters', [
                SEPField('asset_code', True, 'Code of the Stellar asset user wants to send'),
                SEPField('asset_issuer', False, 'Issuer of the Stellar asset (optional if anchor is issuer)'),
                SEPField('destination_asset', False, 'Off-chain asset user wants to receive (in SEP-38 format)'),
                SEPField('amount', False, 'Amount of asset to withdraw'),
                SEPField('quote_id', False, 'ID from SEP-38 quote (for asset exchange)'),
                SEPField('account', False, 'Stellar or muxed account that will send the withdrawal'),
                SEPField('memo', False, 'Memo for identifying the withdrawal transaction'),
                SEPField('memo_type', False, 'Type of memo (text, id, or hash)'),
                SEPField('wallet_name', False, 'Name of wallet for user communication'),
                SEPField('wallet_url', False, 'URL to link in transaction notifications'),
                SEPField('lang', False, 'Language code for UI and messages (RFC 4646)'),
            ]),
            SEPSection('Interactive Response Fields', [
                SEPField('type', True, 'Always "interactive_customer_info_needed" for SEP-24'),
                SEPField('url', True, 'URL for interactive flow popup/iframe'),
                SEPField('id', True, 'Unique transaction identifier'),
            ]),
            SEPSection('Transaction Status Values', [
                SEPField('incomplete', True, 'Customer information still being collected via interactive flow'),
                SEPField('pending_user_transfer_start', True, 'Waiting for user to send funds (deposits)'),
                SEPField('pending_user_transfer_complete', False, 'User transfer detected, awaiting confirmations'),
                SEPField('pending_external', False, 'Transaction being processed by external system'),
                SEPField('pending_anchor', True, 'Anchor processing the transaction'),
                SEPField('pending_stellar', False, 'Transaction submitted to Stellar network'),
                SEPField('pending_trust', False, 'User needs to establish trustline'),
                SEPField('pending_user', False, 'Waiting for user action (e.g., accepting claimable balance)'),
                SEPField('completed', True, 'Transaction completed successfully'),
                SEPField('refunded', False, 'Transaction refunded'),
                SEPField('expired', False, 'Transaction expired before completion'),
                SEPField('error', False, 'Transaction encountered an error'),
            ]),
            SEPSection('Transaction Fields', [
                SEPField('id', True, 'Unique transaction identifier'),
                SEPField('kind', True, 'Kind of transaction (deposit or withdrawal)'),
                SEPField('status', True, 'Current status of the transaction'),
                SEPField('status_eta', False, 'Estimated seconds until status changes'),
                SEPField('kyc_verified', False, 'Whether KYC has been verified for this transaction'),
                SEPField('more_info_url', True, 'URL with additional transaction information'),
                SEPField('amount_in', False, 'Amount received by anchor'),
                SEPField('amount_in_asset', False, 'Asset received by anchor (SEP-38 format)'),
                SEPField('amount_out', False, 'Amount sent by anchor to user'),
                SEPField('amount_out_asset', False, 'Asset delivered to user (SEP-38 format)'),
                SEPField('amount_fee', False, 'Total fee charged for transaction'),
                SEPField('amount_fee_asset', False, 'Asset in which fees are calculated (SEP-38 format)'),
                SEPField('quote_id', False, 'ID of SEP-38 quote used for this transaction'),
                SEPField('started_at', True, 'When transaction was created (ISO 8601)'),
                SEPField('completed_at', False, 'When transaction completed (ISO 8601)'),
                SEPField('updated_at', False, 'When transaction status last changed (ISO 8601)'),
                SEPField('user_action_required_by', False, 'Deadline for user action (ISO 8601)'),
                SEPField('stellar_transaction_id', False, 'Hash of the Stellar transaction'),
                SEPField('external_transaction_id', False, 'Identifier from external system'),
                SEPField('message', False, 'Human-readable message about transaction'),
                SEPField('refunded', False, 'Whether transaction was refunded (deprecated)'),
                SEPField('refunds', False, 'Refund information object'),
                SEPField('from', False, 'Source address (Stellar for withdrawals, external for deposits)'),
                SEPField('to', False, 'Destination address (Stellar for deposits, external for withdrawals)'),
                SEPField('deposit_memo', False, 'Memo for deposit to Stellar address'),
                SEPField('deposit_memo_type', False, 'Type of deposit memo'),
                SEPField('claimable_balance_id', False, 'ID of claimable balance for deposit'),
                SEPField('withdraw_anchor_account', False, "Anchor's Stellar account for withdrawal payment"),
                SEPField('withdraw_memo', False, 'Memo for withdrawal to anchor account'),
                SEPField('withdraw_memo_type', False, 'Type of withdraw memo'),
            ]),
            SEPSection('Info Response Fields', [
                SEPField('deposit', True, 'Map of asset codes to deposit asset information'),
                SEPField('withdraw', True, 'Map of asset codes to withdraw asset information'),
                SEPField('fee', False, 'Fee endpoint information object'),
                SEPField('features', False, 'Feature flags object'),
            ]),
            SEPSection('Deposit Asset Fields', [
                SEPField('enabled', True, 'Whether deposits are enabled for this asset'),
                SEPField('min_amount', False, 'Minimum deposit amount'),
                SEPField('max_amount', False, 'Maximum deposit amount'),
                SEPField('fee_fixed', False, 'Fixed deposit fee'),
                SEPField('fee_percent', False, 'Percentage deposit fee'),
                SEPField('fee_minimum', False, 'Minimum deposit fee'),
            ]),
            SEPSection('Withdraw Asset Fields', [
                SEPField('enabled', True, 'Whether withdrawals are enabled for this asset'),
                SEPField('min_amount', False, 'Minimum withdrawal amount'),
                SEPField('max_amount', False, 'Maximum withdrawal amount'),
                SEPField('fee_fixed', False, 'Fixed withdrawal fee'),
                SEPField('fee_percent', False, 'Percentage withdrawal fee'),
                SEPField('fee_minimum', False, 'Minimum withdrawal fee'),
            ]),
            SEPSection('Feature Flags Fields', [
                SEPField('account_creation', False, 'Whether anchor supports creating accounts'),
                SEPField('claimable_balances', False, 'Whether anchor supports claimable balances'),
            ]),
            SEPSection('Fee Endpoint Info Fields', [
                SEPField('enabled', True, 'Whether fee endpoint is available'),
                SEPField('authentication_required', False, 'Whether authentication is required for fee endpoint'),
            ]),
        ]

    def _analyze_info_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze info endpoint support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'info_endpoint':
                if 'func info(language:' in content and '/info' in content:
                    field.mark('info(language:)')

    def _analyze_interactive_deposit_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze interactive deposit endpoint support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'interactive_deposit':
                if 'func deposit(request:' in content and '/transactions/deposit/interactive' in content:
                    field.mark('deposit(request:)')

    def _analyze_interactive_withdraw_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze interactive withdraw endpoint support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'interactive_withdraw':
                if 'func withdraw(request:' in content and '/transactions/withdraw/interactive' in content:
                    field.mark('withdraw(request:)')

    def _analyze_transaction_endpoints(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze transaction endpoints support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'transactions':
                if 'func getTransactions(request:' in content and 'GET' in content:
                    field.mark('getTransactions(request:)')
            elif field.name == 'transaction':
                if 'func getTransaction(request:' in content and '/transaction' in content:
                    field.mark('getTransaction(request:)')

    def _analyze_fee_endpoint(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze fee endpoint support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'fee_endpoint':
                if 'func fee(request:' in content and '/fee' in content:
                    field.mark('fee(request:)')

    def _analyze_deposit_request_parameters(self, section: SEPSection) -> None:
        """Analyze deposit request parameter support"""
        self._check_declared_properties(section, 'Sep24DepositRequest', {
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
        })

    def _analyze_withdraw_request_parameters(self, section: SEPSection) -> None:
        """Analyze withdraw request parameter support"""
        self._check_declared_properties(section, 'Sep24WithdrawRequest', {
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
        })

    def _analyze_interactive_response_fields(self, section: SEPSection) -> None:
        """Analyze interactive response field support"""
        self._check_declared_properties(section, 'Sep24InteractiveResponse', {
            'type': 'type',
            'url': 'url',
            'id': 'id',
        })

    def _analyze_transaction_status_values(self, section: SEPSection) -> None:
        """Analyze transaction status value support"""
        if not self.sdk_analyzer.find_class_or_struct('Sep24Transaction'):
            return
        for field in section.fields:
            if field.name in self.TRANSACTION_STATUS_VALUES:
                field.mark(f'status: "{field.name}"')

    def _analyze_transaction_fields(self, section: SEPSection) -> None:
        """Analyze transaction field support"""
        self._check_declared_properties(section, 'Sep24Transaction', {
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
        })

    def _analyze_info_response_fields(self, section: SEPSection) -> None:
        """Analyze info response field support"""
        self._check_declared_properties(section, 'Sep24InfoResponse', {
            'deposit': 'depositAssets',
            'withdraw': 'withdrawAssets',
            'fee': 'feeEndpointInfo',
            'features': 'featureFlags',
        })

    def _analyze_deposit_asset_fields(self, section: SEPSection) -> None:
        """Analyze deposit asset field support"""
        self._check_declared_properties(section, 'Sep24DepositAsset', {
            'enabled': 'enabled',
            'min_amount': 'minAmount',
            'max_amount': 'maxAmount',
            'fee_fixed': 'feeFixed',
            'fee_percent': 'feePercent',
            'fee_minimum': 'feeMinimum',
        })

    def _analyze_withdraw_asset_fields(self, section: SEPSection) -> None:
        """Analyze withdraw asset field support"""
        self._check_declared_properties(section, 'Sep24WithdrawAsset', {
            'enabled': 'enabled',
            'min_amount': 'minAmount',
            'max_amount': 'maxAmount',
            'fee_fixed': 'feeFixed',
            'fee_percent': 'feePercent',
            'fee_minimum': 'feeMinimum',
        })

    def _analyze_feature_flags_fields(self, section: SEPSection) -> None:
        """Analyze feature flags field support"""
        self._check_declared_properties(section, 'Sep24FeatureFlags', {
            'account_creation': 'accountCreation',
            'claimable_balances': 'claimableBalances',
        })

    def _analyze_fee_endpoint_info_fields(self, section: SEPSection) -> None:
        """Analyze fee endpoint info field support"""
        self._check_declared_properties(section, 'Sep24FeeEndpointInfo', {
            'enabled': 'enabled',
            'authentication_required': 'authenticationRequired',
        })


class SEP29Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-29: Account Memo Requirements - Checking payment destinations for the config.memo_required data entry before submission"""

    KEY_CLASSES = {
        'TransactionsService': 'Horizon transactions service whose submit and post methods run the SEP-29 memo required check unless skipMemoRequiredCheck is true',
        'TransactionPostResponseEnum': 'Submission result enum whose destinationRequiresMemo(destinationAccountId:) case names the account that requires a memo',
        'TransactionPostAsyncResponseEnum': 'Async submission result enum with the same destinationRequiresMemo(destinationAccountId:) case',
        'ManageDataOperation': 'Sets or removes the config.memo_required data entry on an account',
    }

    SECTION_FLAG = 'Memo Requirement Flag'
    SECTION_CHECK = 'Sender-side Check'
    SECTION_SUBMISSION = 'Submission Integration'

    # Submit methods of TransactionsService that expose the skipMemoRequiredCheck opt-out.
    SUBMIT_METHODS = {
        'submit_transaction_opt_out': 'submitTransaction',
        'submit_async_transaction_opt_out': 'submitAsyncTransaction',
        'submit_fee_bump_transaction_opt_out': 'submitFeeBumpTransaction',
        'submit_fee_bump_async_transaction_opt_out': 'submitFeeBumpAsyncTransaction',
        'post_transaction_opt_out': 'postTransaction',
        'post_transaction_async_opt_out': 'postTransactionAsync',
    }

    SOURCE_FILES = {
        'service': 'TransactionsService.swift',
        'envelope': 'TransactionEnvelopeXDR+Helpers.swift',
        'manage_data': 'ManageDataOperation.swift',
        'strict_send': 'PathPaymentStrictSendOperation.swift',
        'strict_receive': 'PathPaymentStrictReceiveOperation.swift',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-29 implementation"""
        logger.info("Analyzing SEP-29 (Account Memo Requirements) implementation")

        sections = self._create_sections()
        # The check lives in TransactionsService, the fee bump unwrap in the envelope helpers,
        # and setting the flag uses the manage data operation; the path payment operation
        # files are read for their superclass but not listed.
        sources: Dict[str, str] = {}
        for key, filename in self.SOURCE_FILES.items():
            if key in ('service', 'envelope', 'manage_data'):
                file_path = self._implementation_file_named(filename)
            else:
                file_path = self.sdk_analyzer.find_file_by_name(filename)
            sources[key] = read_source(file_path) if file_path else ''

        for section in sections:
            self._analyze_section(section, sources)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-29 sections and their fields"""
        return [
            SEPSection(self.SECTION_FLAG, [
                SEPField('memo_required_data_entry', True, "Reads the destination account's config.memo_required data entry and compares it with the base64 encoding of 1"),
                SEPField('set_memo_required_flag', True, 'Sets or removes the data entry with a manage data operation'),
            ]),
            SEPSection(self.SECTION_CHECK, [
                SEPField('payment_destination', True, 'Checks the destination of a payment operation'),
                SEPField('path_payment_strict_send_destination', True, 'Checks the destination of a path payment strict send operation'),
                SEPField('path_payment_strict_receive_destination', True, 'Checks the destination of a path payment strict receive operation'),
                SEPField('account_merge_destination', True, 'Checks the destination of an account merge operation'),
                SEPField('muxed_destination_exempt', True, 'Checks G-address destinations only and skips multiplexed M-address destinations'),
                SEPField('memo_present_skips_lookup', True, 'Performs no lookup when the transaction carries a memo'),
                SEPField('fee_bump_inner_transaction', True, 'Checks a fee bump envelope through the memo and operations of its inner transaction'),
                SEPField('unknown_destination_skipped', True, 'Skips a destination Horizon does not know and lets the network report it'),
            ]),
            SEPSection(self.SECTION_SUBMISSION, [
                *(SEPField(name, True, f'{method} runs the check unless skipMemoRequiredCheck is true')
                  for name, method in self.SUBMIT_METHODS.items()),
                SEPField('destination_requires_memo_result', True, 'Submission result case carrying the id of the account that requires a memo'),
            ]),
        ]

    def _analyze_section(self, section: SEPSection, sources: Dict[str, str]) -> None:
        """Analyze implementation for a section"""
        service = sources.get('service', '')
        envelope = sources.get('envelope', '')
        manage_data = sources.get('manage_data', '')
        strict_send = sources.get('strict_send', '')
        strict_receive = sources.get('strict_receive', '')

        for field in section.fields:
            detected, sdk_property = self._detect(
                field.name, service, envelope, manage_data, strict_send, strict_receive
            )
            if detected:
                field.mark(sdk_property)

    def _detect(self, name: str, service: str, envelope: str, manage_data: str,
                strict_send: str, strict_receive: str) -> Tuple[bool, Optional[str]]:
        """Detect a single SEP-29 feature in the SDK sources"""
        checks_path_payments = 'operation as? PathPaymentOperation' in service

        if name == 'memo_required_data_entry':
            if 'data["config.memo_required"]' in service and '"MQ=="' in service:
                return True, 'checkMemoRequiredForDestinations (config.memo_required == "MQ==")'
        elif name == 'set_memo_required_flag':
            if 'public class ManageDataOperation' in manage_data and re.search(r'init\(sourceAccountId:\s*String\?,\s*name:\s*String,\s*data:\s*Data\?', manage_data):
                return True, 'ManageDataOperation(sourceAccountId:name:data:)'
        elif name == 'payment_destination':
            if 'operation as? PaymentOperation' in service:
                return True, 'checkMemoRequired (PaymentOperation)'
        elif name == 'path_payment_strict_send_destination':
            if checks_path_payments and re.search(r'class\s+PathPaymentStrictSendOperation\s*:\s*PathPaymentOperation', strict_send):
                return True, 'checkMemoRequired (PathPaymentStrictSendOperation)'
        elif name == 'path_payment_strict_receive_destination':
            if checks_path_payments and re.search(r'class\s+PathPaymentStrictReceiveOperation\s*:\s*PathPaymentOperation', strict_receive):
                return True, 'checkMemoRequired (PathPaymentStrictReceiveOperation)'
        elif name == 'account_merge_destination':
            if 'operation as? AccountMergeOperation' in service:
                return True, 'checkMemoRequired (AccountMergeOperation)'
        elif name == 'muxed_destination_exempt':
            if service.count('destinationAccountId.hasPrefix("G")') >= 3:
                return True, 'checkMemoRequired (M-address destinations skipped)'
        elif name == 'memo_present_skips_lookup':
            if 'transaction.memo != Memo.none' in service:
                return True, 'checkMemoRequired (memo short-circuit)'
        elif name == 'fee_bump_inner_transaction':
            if 'Transaction(envelopeXdr: transactionEnvelope)' in service and 'tevf.tx.innerTx' in envelope:
                return True, 'Transaction(envelopeXdr:) (fee bump inner transaction)'
        elif name == 'unknown_destination_skipped':
            if 'case .notFound(' in service and 'checkMemoRequiredForDestinations' in service:
                return True, 'checkMemoRequiredForDestinations (HTTP 404 skipped)'
        elif name in self.SUBMIT_METHODS:
            method = self.SUBMIT_METHODS[name]
            pattern = r'open\s+func\s+' + re.escape(method) + r'\([^)]*skipMemoRequiredCheck\s*:\s*Bool\s*=\s*false'
            if re.search(pattern, service):
                return True, f'{method}(skipMemoRequiredCheck:)'
        elif name == 'destination_requires_memo_result':
            if ('enum TransactionPostResponseEnum' in service
                    and 'enum TransactionPostAsyncResponseEnum' in service
                    and service.count('case destinationRequiresMemo(destinationAccountId: String)') >= 2):
                return True, 'destinationRequiresMemo(destinationAccountId:)'
        return False, None


class SEP30Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-30 (Account Recovery: multi-party recovery of Stellar accounts)"""

    KEY_CLASSES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-30 implementation"""
        logger.info("Analyzing SEP-30 (Account Recovery) implementation")

        sections = self._create_sections()
        service_file = self._implementation_file('RecoveryService')
        for request_class in ['Sep30Request', 'Sep30RequestIdentity', 'Sep30AuthMethod']:
            self._implementation_file(request_class)
        for response_class in ['Sep30AccountResponse', 'Sep30SignatureResponse',
                                'Sep30AccountsResponse', 'SEP30ResponseIdentity',
                                'SEP30ResponseSigner']:
            self._implementation_file(response_class)
        error_file = self._implementation_file('RecoveryServiceError')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-30 sections and their fields"""
        return [
            SEPSection('API Endpoints', [
                SEPField('register_account', True, 'POST /accounts/{address} - Register an account for recovery'),
                SEPField('update_account', True, 'PUT /accounts/{address} - Update identities for an account'),
                SEPField('get_account', True, 'GET /accounts/{address} - Retrieve account details'),
                SEPField('delete_account', True, 'DELETE /accounts/{address} - Delete account record'),
                SEPField('list_accounts', True, 'GET /accounts - List accessible accounts'),
                SEPField('sign_transaction', True, 'POST /accounts/{address}/sign/{signing-address} - Sign a transaction'),
            ]),
            SEPSection('Request Fields', [
                SEPField('identities', True, 'Array of identity objects for account recovery'),
                SEPField('role', True, 'Role of the identity (owner or other)'),
                SEPField('auth_methods', True, 'Array of authentication methods for the identity'),
                SEPField('type', True, 'Type of authentication method'),
                SEPField('value', True, 'Value of the authentication method (address, phone, email, etc.)'),
                SEPField('transaction', True, 'Base64-encoded XDR transaction envelope to sign'),
                SEPField('after', False, 'Cursor for pagination in list accounts endpoint'),
            ]),
            SEPSection('Response Fields', [
                SEPField('address', True, 'Stellar address of the registered account'),
                SEPField('identities', True, 'Array of registered identity objects'),
                SEPField('signers', True, 'Array of signer objects for the account'),
                SEPField('role', True, 'Role of the identity in response'),
                SEPField('authenticated', False, 'Whether the identity has been authenticated'),
                SEPField('key', True, 'Public key of the signer'),
                SEPField('signature', True, 'Base64-encoded signature of the transaction'),
                SEPField('network_passphrase', True, 'Network passphrase used for signing'),
                SEPField('accounts', True, 'Array of account objects in list response'),
            ]),
            SEPSection('Error Codes', [
                SEPField('400', True, 'Bad Request - Invalid request parameters or malformed data'),
                SEPField('401', True, 'Unauthorized - Missing or invalid JWT token'),
                SEPField('404', True, 'Not Found - Account or resource not found'),
                SEPField('409', True, 'Conflict - Account already exists or conflicting operation'),
            ]),
            SEPSection('Recovery Features', [
                SEPField('multi_party_recovery', True, 'Support for multi-server account recovery'),
                SEPField('flexible_auth_methods', True, 'Support for multiple authentication method types'),
                SEPField('transaction_signing', True, 'Server-side transaction signing for recovery'),
                SEPField('account_sharing', False, 'Support for shared account access'),
                SEPField('identity_roles', True, 'Support for owner and other identity roles'),
                SEPField('pagination', False, 'Pagination support in list accounts endpoint'),
            ]),
            SEPSection('Authentication', [
                SEPField('jwt_token', True, 'All endpoints require authentication via Authorization header with JWT token from SEP-10 or external auth provider'),
            ]),
        ]

    def _analyze_api_endpoints(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze API endpoints support"""
        if not service_file:
            return

        content = read_source(service_file)

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
                    field.mark(sdk_property)

    def _analyze_request_fields(self, section: SEPSection) -> None:
        """Analyze request field support"""
        request_file = self.sdk_analyzer.find_class_or_struct('Sep30Request')
        identity_file = self.sdk_analyzer.find_class_or_struct('Sep30RequestIdentity')
        auth_file = self.sdk_analyzer.find_class_or_struct('Sep30AuthMethod')

        request_content = read_source(request_file) if request_file else ''
        identity_content = read_source(identity_file) if identity_file else ''
        auth_content = read_source(auth_file) if auth_file else ''

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

                if field.name == 'transaction':
                    # transaction is passed directly as parameter in signTransaction
                    service_file = self.sdk_analyzer.find_class_or_struct('RecoveryService')
                    if service_file:
                        service_content = read_source(service_file)
                        if 'transaction:String' in service_content:
                            field.mark('transaction (parameter)')
                elif field.name == 'after':
                    # after is optional parameter in accounts method
                    service_file = self.sdk_analyzer.find_class_or_struct('RecoveryService')
                    if service_file:
                        service_content = read_source(service_file)
                        if 'after:String?' in service_content:
                            field.mark('after (parameter)')
                elif f'var {sdk_property}:' in content or f'var {sdk_property} =' in content:
                    field.mark(sdk_property)

    def _analyze_response_fields(self, section: SEPSection) -> None:
        """Analyze response field support"""
        account_response_file = self.sdk_analyzer.find_class_or_struct('Sep30AccountResponse')
        signature_response_file = self.sdk_analyzer.find_class_or_struct('Sep30SignatureResponse')
        accounts_response_file = self.sdk_analyzer.find_class_or_struct('Sep30AccountsResponse')
        identity_file = self.sdk_analyzer.find_class_or_struct('SEP30ResponseIdentity')
        signer_file = self.sdk_analyzer.find_class_or_struct('SEP30ResponseSigner')

        account_content = read_source(account_response_file) if account_response_file else ''
        signature_content = read_source(signature_response_file) if signature_response_file else ''
        accounts_content = read_source(accounts_response_file) if accounts_response_file else ''
        identity_content = read_source(identity_file) if identity_file else ''
        signer_content = read_source(signer_file) if signer_file else ''

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
                    field.mark(sdk_property)

    def _analyze_error_codes(self, section: SEPSection, error_file: Optional[Path]) -> None:
        """Analyze error codes support"""
        if not error_file:
            return

        content = read_source(error_file)

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
                    field.mark(error_case)

    def _analyze_recovery_features(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze recovery features support"""
        if not service_file:
            return

        service_content = read_source(service_file)

        # These are conceptual features validated by endpoint support
        for field in section.fields:
            if field.name == 'multi_party_recovery':
                if 'registerAccount' in service_content and 'signTransaction' in service_content:
                    field.mark('Supported via registration and signing endpoints')

            elif field.name == 'flexible_auth_methods':
                auth_file = self.sdk_analyzer.find_class_or_struct('Sep30AuthMethod')
                if auth_file:
                    auth_content = read_source(auth_file)
                    if 'var type:' in auth_content and 'var value:' in auth_content:
                        field.mark('Sep30AuthMethod.type and value')

            elif field.name == 'transaction_signing':
                if 'signTransaction' in service_content:
                    field.mark('signTransaction(address:signingAddress:transaction:jwt:)')

            elif field.name == 'account_sharing':
                if 'accounts(jwt:' in service_content:
                    field.mark('accounts(jwt:after:) endpoint')

            elif field.name == 'identity_roles':
                identity_file = self.sdk_analyzer.find_class_or_struct('Sep30RequestIdentity')
                if identity_file:
                    identity_content = read_source(identity_file)
                    if 'var role:' in identity_content:
                        field.mark('Sep30RequestIdentity.role')

            elif field.name == 'pagination':
                if 'after:String?' in service_content:
                    field.mark('accounts(jwt:after:) with optional after parameter')

    def _analyze_authentication(self, section: SEPSection, service_file: Optional[Path]) -> None:
        """Analyze authentication support"""
        if not service_file:
            return

        content = read_source(service_file)

        for field in section.fields:
            if field.name == 'jwt_token':
                jwt_count = content.count('jwt:String')

                if jwt_count >= 6:  # All 6 endpoints require JWT
                    field.mark('jwt parameter required for all endpoints')


class SEP07Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-07 (URI Scheme to facilitate delegated signing)"""

    KEY_CLASSES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-07 implementation"""
        logger.info("Analyzing SEP-07 (URI Scheme to facilitate delegated signing) implementation")

        sections = self._create_sections()
        uri_scheme_file = self._implementation_file('URIScheme')
        validator_file = self._implementation_file('URISchemeValidator')
        enums_file = self._implementation_file('SignTransactionParams')
        self._implementation_file('URISchemeErrors')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-07 sections and their fields"""
        return [
            SEPSection('URI Operations', [
                SEPField('tx', True, 'Transaction operation - Request to sign a transaction'),
                SEPField('pay', True, 'Payment operation - Request to pay a specific address'),
            ]),
            SEPSection('TX Operation Parameters', [
                SEPField('xdr', True, 'Base64 encoded TransactionEnvelope XDR'),
                SEPField('replace', False, 'URL-encoded field replacement using Txrep (SEP-0011) format'),
                SEPField('callback', False, 'URL for transaction submission callback'),
                SEPField('pubkey', False, 'Stellar public key to specify which key should sign'),
                SEPField('chain', False, 'Nested SEP-0007 URL for transaction chaining'),
            ]),
            SEPSection('PAY Operation Parameters', [
                SEPField('destination', True, 'Stellar account ID or payment address to receive payment'),
                SEPField('amount', False, 'Amount to send'),
                SEPField('asset_code', False, 'Asset code for the payment (e.g., USD, BTC)'),
                SEPField('asset_issuer', False, 'Stellar account ID of asset issuer'),
                SEPField('memo', False, 'Memo value to attach to transaction'),
                SEPField('memo_type', False, 'Type of memo (MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN)'),
            ]),
            SEPSection('Common Parameters', [
                SEPField('msg', False, 'Message for the user (max 300 characters)'),
                SEPField('network_passphrase', False, 'Network passphrase for the transaction'),
                SEPField('origin_domain', False, 'Fully qualified domain name of the service originating the request'),
                SEPField('signature', False, 'Signature of the URL for verification'),
            ]),
            SEPSection('Validation Features', [
                SEPField('validate_uri_scheme', True, 'Validate that URI starts with web+stellar:'),
                SEPField('validate_operation_type', True, 'Validate operation type is tx or pay'),
                SEPField('validate_xdr_parameter', True, 'Validate XDR parameter for tx operation'),
                SEPField('validate_destination_parameter', True, 'Validate destination parameter for pay operation'),
                SEPField('validate_stellar_address', True, 'Validate Stellar addresses (account IDs, muxed accounts, contract IDs)'),
                SEPField('validate_asset_code', True, 'Validate asset code length and format'),
                SEPField('validate_memo_type', True, 'Validate memo type is one of allowed types'),
                SEPField('validate_memo_value', True, 'Validate memo value based on memo type'),
                SEPField('validate_message_length', True, 'Validate message parameter length (max 300 chars)'),
                SEPField('validate_origin_domain', True, 'Validate origin_domain is fully qualified domain name'),
                SEPField('validate_chain_nesting', True, 'Validate chain parameter nesting depth (max 7 levels)'),
            ]),
            SEPSection('Signature Features', [
                SEPField('sign_uri', True, 'Sign a SEP-0007 URI with a keypair'),
                SEPField('verify_signature', True, 'Verify URI signature with a public key'),
                SEPField('verify_signed_uri', True, 'Verify signed URI by fetching signing key from origin domain TOML'),
            ]),
        ]

    def _analyze_uri_operations(self, section: SEPSection, uri_scheme_file: Optional[Path]) -> None:
        """Analyze URI operations support"""
        if not uri_scheme_file:
            return

        content = read_source(uri_scheme_file)

        for field in section.fields:
            if field.name == 'tx':
                if 'func getSignTransactionURI' in content:
                    field.mark('getSignTransactionURI(transactionXDR:...)')

            elif field.name == 'pay':
                if 'func getPayOperationURI' in content:
                    field.mark('getPayOperationURI(destination:...)')

    def _analyze_tx_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                               enums_file: Optional[Path]) -> None:
        """Analyze TX operation parameters support"""
        self._analyze_operation_parameters(section, uri_scheme_file, enums_file, 'SignTransactionParams',
                                           ['xdr', 'replace', 'callback', 'pubkey', 'chain'])

    def _analyze_pay_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                enums_file: Optional[Path]) -> None:
        """Analyze PAY operation parameters support"""
        self._analyze_operation_parameters(section, uri_scheme_file, enums_file, 'PayOperationParams',
                                           ['destination', 'amount', 'asset_code', 'asset_issuer', 'memo', 'memo_type'])

    def _analyze_operation_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                      enums_file: Optional[Path], enum_name: str, parameters: List[str]) -> None:
        """Mark each parameter that is a case of enum_name and that URIScheme uses

        getPayOperationURI takes memo_type as its memoType argument rather than as the enum case.
        """
        if not uri_scheme_file or not enums_file:
            return

        uri_content = read_source(uri_scheme_file)
        enum_content = read_source(enums_file)
        if f'enum {enum_name}' not in enum_content:
            return

        for field in section.fields:
            if field.name not in parameters or f'case {field.name}' not in enum_content:
                continue
            if f'{enum_name}.{field.name}' in uri_content:
                field.mark(f'{enum_name}.{field.name}')
            elif field.name == 'memo_type' and 'memoType: String?' in uri_content:
                field.mark('memoType parameter in getPayOperationURI')

    def _analyze_common_parameters(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                  enums_file: Optional[Path]) -> None:
        """Analyze common parameters support"""
        if not uri_scheme_file or not enums_file:
            return

        uri_content = read_source(uri_scheme_file)
        enum_content = read_source(enums_file)

        # Common parameters appear in both SignTransactionParams and PayOperationParams enums
        for field in section.fields:
            if f'case {field.name}' in enum_content:
                sign_tx_param = f'SignTransactionParams.{field.name}'
                pay_op_param = f'PayOperationParams.{field.name}'

                if sign_tx_param in uri_content and pay_op_param in uri_content:
                    field.mark(f'SignTransactionParams.{field.name} / PayOperationParams.{field.name}')

    def _analyze_validation_features(self, section: SEPSection, uri_scheme_file: Optional[Path],
                                    validator_file: Optional[Path]) -> None:
        """Analyze validation features support"""
        if not uri_scheme_file and not validator_file:
            return

        uri_content = read_source(uri_scheme_file) if uri_scheme_file else ""
        validator_content = read_source(validator_file) if validator_file else ""

        for field in section.fields:
            if field.name == 'validate_uri_scheme':
                if 'URISchemeName = "web+stellar:"' in uri_content:
                    field.mark('URISchemeName constant ("web+stellar:")')

            elif field.name == 'validate_operation_type':
                if 'SignOperation = "tx?"' in uri_content and 'PayOperation = "pay?"' in uri_content:
                    field.mark('SignOperation ("tx?") / PayOperation ("pay?") constants')

            elif field.name == 'validate_xdr_parameter':
                if 'transactionXDR: TransactionXDR' in uri_content and 'encodedEnvelope()' in uri_content:
                    field.mark('TransactionXDR parameter validation in getSignTransactionURI')

            elif field.name == 'validate_destination_parameter':
                if 'destination: String' in uri_content and 'getPayOperationURI' in uri_content:
                    field.mark('destination parameter requirement in getPayOperationURI')

            elif field.name == 'validate_stellar_address':
                if 'PublicKey' in validator_content and 'accountId' in validator_content:
                    field.mark('PublicKey(accountId:) validation')

            elif field.name == 'validate_asset_code':
                if 'assetCode: String?' in uri_content:
                    field.mark('assetCode parameter in getPayOperationURI')

            elif field.name == 'validate_memo_type':
                if 'MemoTypeAsString.TEXT' in uri_content and 'MemoTypeAsString.ID' in uri_content:
                    field.mark('MemoTypeAsString enum validation in switch statement')

            elif field.name == 'validate_memo_value':
                if 'switch memoType' in uri_content and 'base64Encoded()' in uri_content:
                    field.mark('Type-specific memo encoding in getPayOperationURI')

            elif field.name == 'validate_message_length':
                if 'MessageMaximumLength' in uri_content and 'message.count <' in uri_content:
                    field.mark('MessageMaximumLength constant (300) with count check')

            elif field.name == 'validate_origin_domain':
                if 'isFullyQualifiedDomainName' in validator_content:
                    field.mark('isFullyQualifiedDomainName validation in URISchemeValidator')

            elif field.name == 'validate_chain_nesting':
                # Chain parameter exists, but nesting depth validation not explicitly enforced
                if 'chain: String?' in uri_content and 'urlEncodedChain' in uri_content:
                    field.mark('chain parameter with URL encoding')

    def _analyze_signature_features(self, section: SEPSection, validator_file: Optional[Path]) -> None:
        """Analyze signature features support"""
        if not validator_file:
            return

        content = read_source(validator_file)

        for field in section.fields:
            if field.name == 'sign_uri':
                if 'func signURI(url:' in content and 'signerKeyPair: KeyPair' in content:
                    field.mark('signURI(url:signerKeyPair:)')

            elif field.name == 'verify_signature':
                if 'func verify(forURL url:' in content and 'signerPublicKey: PublicKey' in content:
                    field.mark('verify(forURL:urlEncodedBase64Signature:signerPublicKey:)')

            elif field.name == 'verify_signed_uri':
                if 'func checkURISchemeIsValid' in content and 'StellarToml.from(domain:' in content:
                    field.mark('checkURISchemeIsValid(url:)')


class SEP11Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-11 (Txrep: human-readable low-level representation of Stellar transactions)"""

    KEY_CLASSES = {
        'TxRep': 'Main class implementing bidirectional conversion between XDR and txrep format',
        'toTxRep(transactionEnvelope:)': 'Converts transaction envelope XDR (base64) to human-readable txrep text format',
        'fromTxRep(txRep:)': 'Parses txrep text format back to transaction envelope XDR (base64)',
        'TxRepError': 'Error enum for txrep parsing failures (missingValue, invalidValue)',
    }

    # TxRep sources scanned besides TxRep, TxRepHelper and txrep/extensions: the XDR types whose
    # generator-emitted toTxRep and fromTxRep carry the conversion
    XDR_TARGETS = [
        'MemoXDR.swift',
        'OperationBodyXDR.swift',
        'OperationType.swift',
        'PreconditionsXDR.swift',
        'PreconditionsV2XDR.swift',
        'DecoratedSignatureXDR.swift',
        'SorobanTransactionDataXDR.swift',
        'AssetXDR.swift',
    ]

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-11 implementation"""
        logger.info("Analyzing SEP-11 (Txrep) implementation")

        sections = self._create_sections()
        scan_paths = [self._implementation_file('TxRep'), self._implementation_file_named('TxRepHelper.swift')]
        scan_paths += [self._record(path)
                       for path in sorted((self.sdk_analyzer.stellarsdk_path / 'txrep' / 'extensions').glob('*.swift'))]
        xdr_dir = self.sdk_analyzer.stellarsdk_path / 'responses' / 'xdr'
        scan_paths += [xdr_dir / name for name in self.XDR_TARGETS if (xdr_dir / name).exists()]
        aggregated = ''.join('\n' + read_source(path) for path in scan_paths if path)

        for section in sections:
            if section.name == 'Encoding Features':
                self._analyze_encoding_features(section, aggregated)
            elif section.name == 'Decoding Features':
                self._analyze_decoding_features(section, aggregated)
            elif section.name == 'Asset Encoding':
                self._analyze_asset_encoding(section, aggregated)
            elif section.name == 'Operation Types':
                self._analyze_operation_types(section, aggregated)
            elif section.name == 'Format Features':
                self._analyze_format_features(section, aggregated)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-11 sections and their fields"""
        return [
            SEPSection('Encoding Features', [
                SEPField('encode_transaction', True, 'Convert transaction envelope XDR to txrep text format'),
                SEPField('encode_fee_bump_transaction', True, 'Convert fee bump transaction envelope to txrep format'),
                SEPField('encode_source_account', True, 'Encode source account (including muxed accounts)'),
                SEPField('encode_memo', True, 'Encode all memo types (NONE, TEXT, ID, HASH, RETURN)'),
                SEPField('encode_operations', True, 'Encode all Stellar operation types'),
                SEPField('encode_preconditions', True, 'Encode transaction preconditions (time bounds, ledger bounds, min seq num, etc.)'),
                SEPField('encode_signatures', True, 'Encode transaction signatures'),
                SEPField('encode_soroban_data', True, 'Encode Soroban transaction data (resources, footprint, etc.)'),
            ]),
            SEPSection('Decoding Features', [
                SEPField('decode_transaction', True, 'Parse txrep text format to transaction envelope XDR'),
                SEPField('decode_fee_bump_transaction', True, 'Parse fee bump transaction from txrep format'),
                SEPField('decode_source_account', True, 'Parse source account (including muxed accounts)'),
                SEPField('decode_memo', True, 'Parse all memo types from txrep'),
                SEPField('decode_operations', True, 'Parse all Stellar operation types from txrep'),
                SEPField('decode_preconditions', True, 'Parse transaction preconditions from txrep'),
                SEPField('decode_signatures', True, 'Parse transaction signatures from txrep'),
                SEPField('decode_soroban_data', True, 'Parse Soroban transaction data from txrep'),
            ]),
            SEPSection('Asset Encoding', [
                SEPField('encode_native_asset', True, 'Encode native XLM asset in txrep format'),
                SEPField('encode_alphanumeric4_asset', True, 'Encode 4-character alphanumeric asset'),
                SEPField('encode_alphanumeric12_asset', True, 'Encode 12-character alphanumeric asset'),
            ]),
            SEPSection('Operation Types', [
                SEPField('create_account', True, 'Encode/decode CREATE_ACCOUNT operation'),
                SEPField('payment', True, 'Encode/decode PAYMENT operation'),
                SEPField('path_payment_strict_receive', True, 'Encode/decode PATH_PAYMENT_STRICT_RECEIVE operation'),
                SEPField('path_payment_strict_send', True, 'Encode/decode PATH_PAYMENT_STRICT_SEND operation'),
                SEPField('manage_sell_offer', True, 'Encode/decode MANAGE_SELL_OFFER operation'),
                SEPField('manage_buy_offer', True, 'Encode/decode MANAGE_BUY_OFFER operation'),
                SEPField('create_passive_sell_offer', True, 'Encode/decode CREATE_PASSIVE_SELL_OFFER operation'),
                SEPField('set_options', True, 'Encode/decode SET_OPTIONS operation'),
                SEPField('change_trust', True, 'Encode/decode CHANGE_TRUST operation'),
                SEPField('allow_trust', True, 'Encode/decode ALLOW_TRUST operation'),
                SEPField('account_merge', True, 'Encode/decode ACCOUNT_MERGE operation'),
                SEPField('manage_data', True, 'Encode/decode MANAGE_DATA operation'),
                SEPField('bump_sequence', True, 'Encode/decode BUMP_SEQUENCE operation'),
                SEPField('create_claimable_balance', True, 'Encode/decode CREATE_CLAIMABLE_BALANCE operation'),
                SEPField('claim_claimable_balance', True, 'Encode/decode CLAIM_CLAIMABLE_BALANCE operation'),
                SEPField('begin_sponsoring_future_reserves', True, 'Encode/decode BEGIN_SPONSORING_FUTURE_RESERVES operation'),
                SEPField('end_sponsoring_future_reserves', True, 'Encode/decode END_SPONSORING_FUTURE_RESERVES operation'),
                SEPField('revoke_sponsorship', True, 'Encode/decode REVOKE_SPONSORSHIP operation'),
                SEPField('clawback', True, 'Encode/decode CLAWBACK operation'),
                SEPField('clawback_claimable_balance', True, 'Encode/decode CLAWBACK_CLAIMABLE_BALANCE operation'),
                SEPField('set_trust_line_flags', True, 'Encode/decode SET_TRUST_LINE_FLAGS operation'),
                SEPField('liquidity_pool_deposit', True, 'Encode/decode LIQUIDITY_POOL_DEPOSIT operation'),
                SEPField('liquidity_pool_withdraw', True, 'Encode/decode LIQUIDITY_POOL_WITHDRAW operation'),
                SEPField('invoke_host_function', True, 'Encode/decode INVOKE_HOST_FUNCTION operation (Soroban)'),
                SEPField('extend_footprint_ttl', True, 'Encode/decode EXTEND_FOOTPRINT_TTL operation (Soroban)'),
                SEPField('restore_footprint', True, 'Encode/decode RESTORE_FOOTPRINT operation (Soroban)'),
            ]),
            SEPSection('Format Features', [
                SEPField('comment_support', True, 'Support for comments in txrep format'),
                SEPField('dot_notation', True, 'Use dot notation for nested structures'),
                SEPField('array_indexing', True, 'Support array indexing in txrep format'),
                SEPField('hex_encoding', True, 'Hexadecimal encoding for binary data'),
                SEPField('string_escaping', True, 'Proper string escaping with double quotes'),
            ]),
        ]

    def _analyze_encoding_features(self, section: SEPSection, content: str) -> None:
        """Analyze encoding features across the TxRep sources"""
        if not content:
            return

        for field in section.fields:
            if field.name == 'encode_transaction':
                # Public facade entry point in TxRep.swift
                if 'public static func toTxRep(transactionEnvelope: String)' in content:
                    field.mark('TxRep.toTxRep(transactionEnvelope:)')
            elif field.name == 'encode_fee_bump_transaction':
                # Fee bump envelope dispatch in TransactionEnvelopeXDR+TxRep.swift
                if 'case .feeBump(let envelope)' in content and 'prefix: "feeBump"' in content:
                    field.mark('TransactionEnvelopeXDR.toTxRep - feeBump arm')
            elif field.name == 'encode_source_account':
                # TransactionXDR+TxRep.swift emits <prefix>.sourceAccount: ...
                if '.sourceAccount: \\(try TxRepHelper.formatMuxedAccount' in content:
                    field.mark('TransactionXDR.toTxRep - sourceAccount')
            elif field.name == 'encode_memo':
                # MemoXDR.swift has generator-emitted toTxRep
                if 'public func toTxRep(prefix: String, lines: inout [String]) throws' in content and 'MEMO_TEXT' in content:
                    field.mark('MemoXDR.toTxRep')
            elif field.name == 'encode_operations':
                # OperationBodyXDR.swift has generator-emitted toTxRep with per-op cases
                if 'case .createAccountOp(let val)' in content and 'val.toTxRep(prefix:' in content:
                    field.mark('OperationBodyXDR.toTxRep')
            elif field.name == 'encode_preconditions':
                # PreconditionsXDR.swift has generator-emitted toTxRep
                if 'PreconditionsXDR' in content and 'PRECOND_NONE' in content and '.cond.type' in content:
                    field.mark('PreconditionsXDR.toTxRep')
            elif field.name == 'encode_signatures':
                # DecoratedSignatureXDR.swift toTxRep plus signatures[i] emission in TransactionEnvelopeXDR+TxRep.swift
                if 'DecoratedSignatureXDR' in content and 'signatures[' in content and '.hint' in content and '.signature' in content:
                    field.mark('DecoratedSignatureXDR.toTxRep')
            elif field.name == 'encode_soroban_data':
                # SorobanTransactionDataXDR.swift has generator-emitted toTxRep
                if 'SorobanTransactionDataXDR' in content and 'public func toTxRep(prefix: String, lines: inout [String]) throws' in content:
                    field.mark('SorobanTransactionDataXDR.toTxRep')

    def _analyze_decoding_features(self, section: SEPSection, content: str) -> None:
        """Analyze decoding features across the TxRep sources"""
        if not content:
            return

        for field in section.fields:
            if field.name == 'decode_transaction':
                # Public facade entry point in TxRep.swift
                if 'public static func fromTxRep(txRep: String)' in content:
                    field.mark('TxRep.fromTxRep(txRep:)')
            elif field.name == 'decode_fee_bump_transaction':
                # TransactionEnvelopeXDR+TxRep.swift detects fee bump via type marker
                if 'ENVELOPE_TYPE_TX_FEE_BUMP' in content and 'FeeBumpTransactionEnvelopeXDR.fromTxRep' in content:
                    field.mark('TransactionEnvelopeXDR.fromTxRep - feeBump arm')
            elif field.name == 'decode_source_account':
                # TransactionXDR+TxRep.swift parses <prefix>.sourceAccount via TxRepHelper.parseMuxedAccount
                if 'TxRepHelper.parseMuxedAccount' in content and '.sourceAccount' in content:
                    field.mark('TransactionXDR.fromTxRep - sourceAccount')
            elif field.name == 'decode_memo':
                # MemoXDR.swift has generator-emitted fromTxRep
                if 'MemoXDR' in content and 'public static func fromTxRep(_ map: [String: String], prefix: String) throws -> MemoXDR' in content:
                    field.mark('MemoXDR.fromTxRep')
            elif field.name == 'decode_operations':
                # OperationBodyXDR.swift has generator-emitted fromTxRep with per-op decoding
                if 'public static func fromTxRep(_ map: [String: String], prefix: String) throws -> OperationBodyXDR' in content and 'CREATE_ACCOUNT' in content:
                    field.mark('OperationBodyXDR.fromTxRep')
            elif field.name == 'decode_preconditions':
                # PreconditionsXDR.swift has generator-emitted fromTxRep
                if 'public static func fromTxRep(_ map: [String: String], prefix: String) throws -> PreconditionsXDR' in content:
                    field.mark('PreconditionsXDR.fromTxRep')
            elif field.name == 'decode_signatures':
                # DecoratedSignatureXDR.swift has generator-emitted fromTxRep
                if 'public static func fromTxRep(_ map: [String: String], prefix: String) throws -> DecoratedSignatureXDR' in content:
                    field.mark('DecoratedSignatureXDR.fromTxRep')
            elif field.name == 'decode_soroban_data':
                # SorobanTransactionDataXDR.swift has generator-emitted fromTxRep
                if 'public static func fromTxRep(_ map: [String: String], prefix: String) throws -> SorobanTransactionDataXDR' in content:
                    field.mark('SorobanTransactionDataXDR.fromTxRep')

    def _analyze_asset_encoding(self, section: SEPSection, content: str) -> None:
        """Analyze asset encoding support (TxRepHelper.formatAsset/parseAsset)."""
        if not content:
            return

        has_format_asset = 'public static func formatAsset(_ asset: AssetXDR)' in content
        has_parse_asset = 'public static func parseAsset(_ value: String)' in content

        for field in section.fields:
            if field.name == 'encode_native_asset':
                # formatAsset returns "XLM" for the native arm
                if has_format_asset and '"XLM"' in content:
                    field.mark('TxRepHelper.formatAsset - native')
            elif field.name == 'encode_alphanumeric4_asset':
                # formatAsset handles .alphanum4(Alpha4XDR) -> <code>:<issuer>
                if has_format_asset and has_parse_asset and 'case .alphanum4' in content:
                    field.mark('TxRepHelper.formatAsset - alphanum4')
            elif field.name == 'encode_alphanumeric12_asset':
                if has_format_asset and has_parse_asset and 'case .alphanum12' in content:
                    field.mark('TxRepHelper.formatAsset - alphanum12')

    def _analyze_operation_types(self, section: SEPSection, content: str) -> None:
        """Analyze operation type support (OperationBodyXDR.swift dispatch tables)."""
        if not content:
            return

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
                if encode_pattern in content and decode_pattern in content:
                    field.mark(f'{field.name} operation')

    def _analyze_format_features(self, section: SEPSection, content: str) -> None:
        """Analyze format features across the TxRep sources"""
        if not content:
            return

        for field in section.fields:
            if field.name == 'comment_support':
                # TxRepHelper.removeComment is the single source of comment stripping
                if 'public static func removeComment(_ value: String)' in content:
                    field.mark('TxRepHelper.removeComment')
            elif field.name == 'dot_notation':
                # Extensions use "tx.*" / "feeBump.*" dot notation when emitting keys
                if 'prefix: "tx"' in content or 'prefix: "feeBump"' in content or 'tx.sourceAccount' in content:
                    field.mark('Dot notation in key paths')
            elif field.name == 'array_indexing':
                if 'signatures[' in content and 'operations[' in content:
                    field.mark('Array indexing [n] syntax')
            elif field.name == 'hex_encoding':
                # TxRepHelper.bytesToHex is the canonical hex encoder
                if 'public static func bytesToHex(_ bytes: Data)' in content:
                    field.mark('TxRepHelper.bytesToHex')
            elif field.name == 'string_escaping':
                if 'public static func escapeString(_ s: String)' in content and 'public static func unescapeString(_ s: String)' in content:
                    field.mark('TxRepHelper.escapeString / unescapeString')


class SEP46Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-46: Contract Meta - A standard for the storage of metadata in contract Wasm files"""

    KEY_CLASSES = {
        'SorobanContractParser': 'Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta',
        'SorobanContractInfo': 'Stores information parsed from a soroban contract byte code such as Environment Meta, Contract Spec Entries and Contract Meta Entries',
        'SorobanContractParserError': 'Error enum for contract parsing failures',
        'SCMetaEntryXDR': 'XDR enum for contract metadata entries, supports SCMetaKind.v0',
        'SCMetaV0XDR': 'XDR struct for key-value metadata pairs (key: String, value: String)',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-46 implementation"""
        logger.info("Analyzing SEP-46 (Contract Meta) implementation")

        sections = self._load_definition('sep_0046_definition.json', 'contract_meta_features')
        parser_file = self._implementation_file('SorobanContractParser')

        for section in sections:
            if section.name == 'Contract Metadata Storage':
                self._analyze_metadata_storage(section, parser_file)
            elif section.name == 'Encoding Format':
                self._analyze_encoding_format(section, parser_file)
            elif section.name == 'Implementation Support':
                self._analyze_implementation_support(section, parser_file)

        return self._matrix(sep_info, sections)

    def _analyze_metadata_storage(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze metadata storage features"""
        if not parser_file:
            return

        content = read_source(parser_file)

        for field in section.fields:
            if field.name == 'contractmetav0_section':
                if 'from: "contractmetav0"' in content:
                    field.mark('parseMeta')
            elif field.name == 'multiple_entries_single_section':
                if 'while !meta.isEmpty' in content:
                    field.mark('parseMeta')
            elif field.name == 'multiple_sections':
                # Multiple sections supported via slice and end functions supporting multiple contractmetav0 sections
                if 'slice(input: bytesString, from: "contractmetav0"' in content:
                    field.mark('parseMeta')

    def _analyze_encoding_format(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze encoding format features"""
        if not parser_file:
            return

        content = read_source(parser_file)

        for field in section.fields:
            if field.name == 'scmetaentry_xdr':
                if 'SCMetaEntryXDR' in content:
                    field.mark('parseMeta')
            elif field.name == 'binary_stream_encoding':
                if 'XDRDecoder' in content and 'data(using: .isoLatin1)' in content:
                    field.mark('parseMeta')
            elif field.name == 'key_value_pairs':
                if 'result[' in content and '.key]' in content and '.value' in content:
                    field.mark('metaEntries')

    def _analyze_implementation_support(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze implementation support features"""
        if not parser_file:
            return

        content = read_source(parser_file)

        for field in section.fields:
            if field.name == 'parse_contract_meta':
                if 'parseContractByteCode' in content:
                    field.mark('parseContractByteCode')
            elif field.name == 'extract_meta_entries':
                if 'parseMeta' in content and 'metaEntries' in content:
                    field.mark('parseMeta')
            elif field.name == 'decode_scmetaentry':
                if 'SCMetaEntryXDR(from:' in content:
                    field.mark('parseMeta')


class SEP47Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-47: Contract Interface Discovery - A standard for a contract to indicate which SEPs it claims to implement"""

    KEY_CLASSES = {
        'SorobanContractParser': 'Parses a soroban contract byte code to get Environment Meta, Contract Spec and Contract Meta',
        'SorobanContractInfo': 'Stores information parsed from a soroban contract byte code, exposes supportedSeps property',
        'SorobanContractParserError': 'Error enum for contract parsing failures',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-47 implementation"""
        logger.info("Analyzing SEP-47 (Contract Interface Discovery) implementation")

        sections = self._load_definition('sep_0047_definition.json', 'contract_meta_features')
        parser_file = self._implementation_file('SorobanContractParser')

        for section in sections:
            if section.name == 'SEP Declaration':
                self._analyze_sep_declaration(section, parser_file)
            elif section.name == 'Meta Entry Format':
                self._analyze_meta_entry_format(section, parser_file)
            elif section.name == 'Implementation Support':
                self._analyze_implementation_support(section, parser_file)

        return self._matrix(sep_info, sections)

    def _analyze_sep_declaration(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze SEP declaration features"""
        if not parser_file:
            return

        content = read_source(parser_file)

        for field in section.fields:
            if field.name == 'sep_meta_key':
                if 'metaEntries["sep"]' in content:
                    field.mark('parseSupportedSeps')
            elif field.name == 'comma_separated_list':
                if 'split(separator: ",")' in content:
                    field.mark('parseSupportedSeps')
            elif field.name == 'multiple_sep_entries':
                # Multiple entries handled via metaEntries dictionary
                if 'parseSupportedSeps' in content and 'metaEntries' in content:
                    field.mark('parseSupportedSeps')

    def _analyze_meta_entry_format(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze meta entry format features"""
        if not parser_file:
            return

        content = read_source(parser_file)

        for field in section.fields:
            if field.name == 'sep_number_format':
                # Various formats supported via string trimming and filtering
                if 'parseSupportedSeps' in content:
                    field.mark('parseSupportedSeps')
            elif field.name == 'whitespace_handling':
                if 'trimmingCharacters(in: .whitespaces)' in content:
                    field.mark('parseSupportedSeps')
            elif field.name == 'empty_value_handling':
                if '!sepValue.isEmpty' in content and '!$0.isEmpty' in content:
                    field.mark('parseSupportedSeps')

    def _analyze_implementation_support(self, section: SEPSection, parser_file: Optional[Path]) -> None:
        """Analyze implementation support features"""
        if not parser_file:
            return

        content = read_source(parser_file)

        for field in section.fields:
            if field.name == 'parse_supported_seps':
                if 'parseSupportedSeps' in content and 'metaEntries:' in content:
                    field.mark('parseSupportedSeps')
            elif field.name == 'expose_supported_seps':
                if 'public let supportedSeps' in content or 'let supportedSeps' in content:
                    field.mark('supportedSeps')
            elif field.name == 'validate_sep_format':
                # Validation via filtering empty entries
                if 'filter { !$0.isEmpty }' in content:
                    field.mark('parseSupportedSeps')


class SEP48Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-48: Contract Interface Specification - A standard for contracts to self-describe their exported interface"""

    KEY_CLASSES = {
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

    # The generated XDR declares every SEP-48 spec type and SorobanContractParser reads them, so no field needs a source check.
    SDK_NAMES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-48 implementation"""
        logger.info("Analyzing SEP-48 (Contract Interface Specification) implementation")

        sections = self._create_sections()
        self._implementation_file('SorobanContractParser')
        self._implementation_file('ContractSpec')

        for section in sections:
            self._analyze_section(section)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-48 sections and their fields"""
        return [
            SEPSection('Wasm Custom Sections', [
                SEPField('contractspecv0_section', True, 'Support for "contractspecv0" Wasm custom section for contract specifications'),
                SEPField('contractenvmetav0_section', True, 'Support for "contractenvmetav0" Wasm custom section for environment metadata'),
                SEPField('contractmetav0_section', True, 'Support for "contractmetav0" Wasm custom section for contract metadata'),
                SEPField('xdr_binary_encoding', True, 'Parse XDR binary encoded specification entries'),
            ]),
            SEPSection('Entry Types', [
                SEPField('function_specs', True, 'Parse function specification entries (SC_SPEC_ENTRY_FUNCTION_V0)'),
                SEPField('struct_specs', True, 'Parse struct type specification entries (SC_SPEC_ENTRY_UDT_STRUCT_V0)'),
                SEPField('union_specs', True, 'Parse union type specification entries (SC_SPEC_ENTRY_UDT_UNION_V0)'),
                SEPField('enum_specs', True, 'Parse enum type specification entries (SC_SPEC_ENTRY_UDT_ENUM_V0)'),
                SEPField('error_enum_specs', True, 'Parse error enum specification entries (SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0)'),
                SEPField('event_specs', True, 'Parse event specification entries (SC_SPEC_ENTRY_EVENT_V0)'),
            ]),
            SEPSection('Type System - Primitive Types', [
                SEPField('numeric_types', True, 'Support for numeric types (u32, i32, u64, i64, u128, i128, u256, i256)'),
                SEPField('boolean_type', True, 'Support for boolean type (SC_SPEC_TYPE_BOOL)'),
                SEPField('void_type', True, 'Support for void type (SC_SPEC_TYPE_VOID)'),
                SEPField('bytes_string_symbol', True, 'Support for bytes, string, and symbol types'),
                SEPField('address_type', True, 'Support for address type (SC_SPEC_TYPE_ADDRESS)'),
                SEPField('timepoint_duration', True, 'Support for timepoint and duration types'),
            ]),
            SEPSection('Type System - Compound Types', [
                SEPField('option_type', True, 'Support for Option<T> type (SC_SPEC_TYPE_OPTION)'),
                SEPField('result_type', True, 'Support for Result<T, E> type (SC_SPEC_TYPE_RESULT)'),
                SEPField('vector_type', True, 'Support for Vec<T> type (SC_SPEC_TYPE_VEC)'),
                SEPField('map_type', True, 'Support for Map<K, V> type (SC_SPEC_TYPE_MAP)'),
                SEPField('tuple_type', True, 'Support for tuple types (SC_SPEC_TYPE_TUPLE)'),
                SEPField('bytes_n_type', True, 'Support for fixed-length bytes type (SC_SPEC_TYPE_BYTES_N)'),
                SEPField('user_defined_type', True, 'Support for user-defined types (SC_SPEC_TYPE_UDT)'),
            ]),
            SEPSection('Parsing Support', [
                SEPField('parse_contract_bytecode', True, 'Parse contract specifications from Wasm bytecode'),
                SEPField('parse_environment_meta', True, 'Parse environment metadata for interface version'),
                SEPField('parse_contract_meta', True, 'Parse contract metadata key-value pairs'),
                SEPField('extract_spec_entries', True, 'Extract and decode all specification entries from Wasm bytecode'),
            ]),
            SEPSection('XDR Support', [
                SEPField('decode_scspecentry', True, 'Decode SCSpecEntry XDR structures'),
                SEPField('decode_scspectypedef', True, 'Decode SCSpecTypeDef XDR structures for type definitions'),
                SEPField('decode_scenvmetaentry', True, 'Decode SCEnvMetaEntry XDR structures'),
                SEPField('decode_scmetaentry', True, 'Decode SCMetaEntry XDR structures'),
            ]),
        ]

    def _analyze_section(self, section: SEPSection) -> None:
        """Mark every field implemented with its SDK name from SDK_NAMES"""
        for field in section.fields:
            field.mark(self.SDK_NAMES.get(field.name, field.name))


class SEP45Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-45 (Web Authentication for Contract Accounts)"""

    KEY_CLASSES = {
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

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-45 implementation"""
        logger.info("Analyzing SEP-45 (Web Authentication for Contract Accounts) implementation")

        sections = self._create_sections()
        web_auth_contracts_file = self._implementation_file('WebAuthForContracts')
        self._implementation_file('WebAuthForContractsError')
        self._implementation_file('ContractChallengeResponse')

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

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-45 sections and their fields"""
        return [
            SEPSection('Authentication Endpoints', [
                SEPField('get_auth_challenge', True, 'GET /auth endpoint - Returns challenge authorization entries for contract accounts'),
                SEPField('post_auth_token', True, 'POST /auth endpoint - Validates signed authorization entries and returns JWT token'),
                SEPField('stellar_toml_discovery', True, 'Automatic discovery of WEB_AUTH_FOR_CONTRACTS_ENDPOINT and WEB_AUTH_CONTRACT_ID from stellar.toml'),
            ]),
            SEPSection('Challenge Authorization Entry Features', [
                SEPField('authorization_entries_decoding', True, 'Decode base64 XDR authorization entries from server response'),
                SEPField('contract_address_validation', True, 'Validate contract_address matches WEB_AUTH_CONTRACT_ID'),
                SEPField('function_name_validation', True, 'Validate function_name is "web_auth_verify"'),
                SEPField('no_sub_invocations', True, 'Reject entries with sub-invocations for security'),
                SEPField('args_map_parsing', True, 'Parse args map containing account, home_domain, web_auth_domain, nonce, etc.'),
                SEPField('nonce_validation', True, 'Validate nonce is consistent across all authorization entries'),
                SEPField('network_passphrase_validation', False, 'Validate network_passphrase if provided by server'),
            ]),
            SEPSection('Client Domain Features', [
                SEPField('client_domain_parameter', False, 'Support optional client_domain parameter in GET /auth'),
                SEPField('client_domain_entry', False, 'Handle client domain authorization entry in challenge'),
                SEPField('client_domain_local_signing', False, 'Sign client domain entry with local keypair'),
                SEPField('client_domain_callback_signing', False, 'Support remote signing via callback function'),
                SEPField('client_domain_account_validation', False, 'Validate client_domain_account matches expected account'),
            ]),
            SEPSection('Signature Features', [
                SEPField('client_entry_signing', True, 'Sign client authorization entry with provided signers'),
                SEPField('multi_signer_support', True, 'Support multiple signers for multi-sig contracts'),
                SEPField('signature_expiration_ledger', True, 'Set signature expiration ledger in credentials'),
                SEPField('auto_expiration_ledger', False, 'Auto-fill signature expiration ledger from Soroban RPC (current + 10)'),
                SEPField('empty_signers_support', False, 'Support empty signers array for contracts without signature requirements'),
            ]),
            SEPSection('Validation Features', [
                SEPField('server_entry_validation', True, 'Validate server authorization entry exists'),
                SEPField('client_entry_validation', True, 'Validate client authorization entry exists'),
                SEPField('server_signature_verification', True, 'Verify server signature on authorization entry using SIGNING_KEY'),
                SEPField('home_domain_validation', True, 'Validate home_domain in args matches expected value'),
                SEPField('web_auth_domain_validation', True, 'Validate web_auth_domain matches auth endpoint domain'),
                SEPField('account_validation', True, 'Validate account in args matches client contract account'),
            ]),
            SEPSection('JWT Token Features', [
                SEPField('authorization_entries_encoding', True, 'Encode signed authorization entries to base64 XDR for submission'),
                SEPField('jwt_token_response', True, 'Parse JWT token from server response'),
                SEPField('form_urlencoded_support', False, 'Support application/x-www-form-urlencoded for POST request'),
                SEPField('json_content_support', False, 'Support application/json for POST request'),
                SEPField('timeout_handling', False, 'Handle HTTP 504 timeout responses'),
            ]),
        ]

    def _analyze_authentication_endpoints(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze authentication endpoint support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'get_auth_challenge':
                if 'func getChallenge' in content and 'forContractAccount' in content:
                    field.mark('getChallenge(forContractAccount:homeDomain:clientDomain:)')
            elif field.name == 'post_auth_token':
                if 'func sendSignedChallenge' in content and 'signedEntries' in content:
                    field.mark('sendSignedChallenge(signedEntries:)')
            elif field.name == 'stellar_toml_discovery':
                if 'static func from' in content and 'StellarToml.from' in content:
                    field.mark('WebAuthForContracts.from(domain:network:)')

    def _analyze_challenge_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze challenge authorization entry feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'authorization_entries_decoding':
                if 'func decodeAuthorizationEntries' in content and 'base64Xdr' in content:
                    field.mark('decodeAuthorizationEntries(base64Xdr:)')
            elif field.name == 'contract_address_validation':
                if 'invalidContractAddress' in content and 'webAuthContractId' in content:
                    field.mark('validateChallenge (contract address check)')
            elif field.name == 'function_name_validation':
                if 'web_auth_verify' in content and 'invalidFunctionName' in content:
                    field.mark('validateChallenge (function name check)')
            elif field.name == 'no_sub_invocations':
                if 'subInvocationsFound' in content and 'subInvocations.count == 0' in content:
                    field.mark('validateChallenge (sub-invocation check)')
            elif field.name == 'args_map_parsing':
                if 'extractArgsFromEntry' in content and 'case .map' in content:
                    field.mark('extractArgsFromEntry(_:)')
            elif field.name == 'nonce_validation':
                if 'invalidNonce' in content and 'nonce' in content:
                    field.mark('validateChallenge (nonce validation)')
            elif field.name == 'network_passphrase_validation':
                if 'invalidNetworkPassphrase' in content and 'networkPassphrase' in content:
                    field.mark('jwtToken (network passphrase check)')

    def _analyze_client_domain_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze client domain feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'client_domain_parameter':
                if 'clientDomain' in content and 'client_domain=' in content:
                    field.mark('getChallenge(clientDomain:)')
            elif field.name == 'client_domain_entry':
                if 'clientDomainEntryFound' in content or 'clientDomainAccountId' in content:
                    field.mark('validateChallenge (client domain entry)')
            elif field.name == 'client_domain_local_signing':
                if 'clientDomainKeyPair' in content and 'entry.sign' in content:
                    field.mark('signAuthorizationEntries(clientDomainKeyPair:)')
            elif field.name == 'client_domain_callback_signing':
                if 'clientDomainSigningCallback' in content:
                    field.mark('signAuthorizationEntries(clientDomainSigningCallback:)')
            elif field.name == 'client_domain_account_validation':
                if 'invalidClientDomainAccount' in content:
                    field.mark('validateChallenge (client domain account check)')

    def _analyze_signature_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze signature feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'client_entry_signing':
                if 'entry.sign(signer:' in content and 'for signer in signers' in content:
                    field.mark('signAuthorizationEntries (client signing)')
            elif field.name == 'multi_signer_support':
                if 'signers: [KeyPair]' in content and 'for signer in signers' in content:
                    field.mark('jwtToken(signers:)')
            elif field.name == 'signature_expiration_ledger':
                if 'signatureExpirationLedger' in content:
                    field.mark('signAuthorizationEntries(signatureExpirationLedger:)')
            elif field.name == 'auto_expiration_ledger':
                if 'getLatestLedger' in content and 'sequence + 10' in content:
                    field.mark('jwtToken (auto-fill expiration)')
            elif field.name == 'empty_signers_support':
                if 'signers.isEmpty' in content:
                    field.mark('jwtToken (empty signers handling)')

    def _analyze_validation_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze validation feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'server_entry_validation':
                if 'missingServerEntry' in content and 'serverEntryFound' in content:
                    field.mark('validateChallenge (server entry check)')
            elif field.name == 'client_entry_validation':
                if 'missingClientEntry' in content and 'clientEntryFound' in content:
                    field.mark('validateChallenge (client entry check)')
            elif field.name == 'server_signature_verification':
                if 'verifyServerSignature' in content and 'invalidServerSignature' in content:
                    field.mark('verifyServerSignature(entry:)')
            elif field.name == 'home_domain_validation':
                if 'invalidHomeDomain' in content and 'home_domain' in content:
                    field.mark('validateChallenge (home domain check)')
            elif field.name == 'web_auth_domain_validation':
                if 'invalidWebAuthDomain' in content and 'web_auth_domain' in content:
                    field.mark('validateChallenge (web auth domain check)')
            elif field.name == 'account_validation':
                if 'invalidAccount' in content and '"account"' in content:
                    field.mark('validateChallenge (account check)')

    def _analyze_jwt_features(self, section: SEPSection, web_auth_file: Optional[Path]) -> None:
        """Analyze JWT token feature support"""
        if not web_auth_file:
            return

        content = read_source(web_auth_file)

        for field in section.fields:
            if field.name == 'authorization_entries_encoding':
                if 'encodeAuthorizationEntries' in content and 'base64EncodedString' in content:
                    field.mark('encodeAuthorizationEntries(_:)')
            elif field.name == 'jwt_token_response':
                if '"token"' in content and 'jwtToken' in content:
                    field.mark('sendSignedChallenge response')
            elif field.name == 'form_urlencoded_support':
                if 'useFormUrlEncoded' in content and 'application/x-www-form-urlencoded' in content:
                    field.mark('useFormUrlEncoded property')
            elif field.name == 'json_content_support':
                if 'application/json' in content:
                    field.mark('sendSignedChallenge (JSON support)')
            elif field.name == 'timeout_handling':
                if 'submitChallengeTimeout' in content:
                    field.mark('submitChallengeTimeout error')


class SEP53Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-53: Message Signing - A standard for signing and verifying arbitrary messages with Stellar keys"""

    KEY_CLASSES = {
        'KeyPair': 'Stellar key pair with SEP-53 message signing and verification methods (signMessage, verifyMessage, calculateMessageHash)',
    }

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-53 implementation"""
        logger.info("Analyzing SEP-53 (Message Signing) implementation")

        sections = self._create_sections()
        keypair_file = self._implementation_file_named('KeyPair.swift')

        for section in sections:
            self._analyze_section(section, keypair_file)

        return self._matrix(sep_info, sections)

    def _create_sections(self) -> List[SEPSection]:
        """The SEP-53 sections and their fields"""
        return [
            SEPSection('Message Signing (SEP-53)', [
                SEPField('message_prefix', True, 'Uses "Stellar Signed Message:\\n" prefix before hashing'),
                SEPField('sha256_hashing', True, 'SHA-256 hash of prefixed message'),
                SEPField('sign_message_binary', True, 'Sign binary message per SEP-53'),
                SEPField('sign_message_string', True, 'Sign UTF-8 string message per SEP-53'),
                SEPField('verify_message_binary', True, 'Verify binary message signature per SEP-53'),
                SEPField('verify_message_string', True, 'Verify UTF-8 string message signature per SEP-53'),
                SEPField('ed25519_signature', True, '64-byte Ed25519 signature output'),
                SEPField('utf8_encoding', True, 'UTF-8 encoding for string messages'),
            ]),
        ]

    def _analyze_section(self, section: SEPSection, keypair_file: Optional[Path]) -> None:
        """Analyze implementation for a section"""
        if not keypair_file:
            return

        content = read_source(keypair_file)

        for field in section.fields:
            if field.name == 'message_prefix':
                if 'Stellar Signed Message:\\n' in content and 'calculateMessageHash' in content:
                    field.mark('calculateMessageHash (prefix constant)')
            elif field.name == 'sha256_hashing':
                if 'sha256' in content.lower() and 'calculateMessageHash' in content:
                    field.mark('calculateMessageHash (SHA-256 hash)')
            elif field.name == 'sign_message_binary':
                if 'func signMessage(_ message: [UInt8])' in content:
                    field.mark('signMessage(_: [UInt8])')
            elif field.name == 'sign_message_string':
                if 'func signMessage(_ message: String)' in content:
                    field.mark('signMessage(_: String)')
            elif field.name == 'verify_message_binary':
                if 'func verifyMessage(_ message: [UInt8]' in content and 'signature' in content:
                    field.mark('verifyMessage(_: [UInt8], signature:)')
            elif field.name == 'verify_message_string':
                if 'func verifyMessage(_ message: String' in content and 'signature' in content:
                    field.mark('verifyMessage(_: String, signature:)')
            elif field.name == 'ed25519_signature':
                if 'func sign' in content and 'Ed25519' in content:
                    field.mark('sign (Ed25519 64-byte signature)')
            elif field.name == 'utf8_encoding':
                if '.utf8' in content and 'signMessage' in content:
                    field.mark('signMessage (UTF-8 encoding)')


class SEP51Analyzer(SEPAnalyzerBase):
    """Analyzer for SEP-51: XDR-JSON - A standard mapping between Stellar's XDR structures and a JSON representation"""

    KEY_CLASSES = {
        'XdrJsonCodable': 'Protocol XDR types conform to, declaring toXdrJsonValue() and fromXdrJsonValue(_:) and deriving toXdrJson(), fromXdrJson(_:) and fromXdrJsonTree(_:); the three transaction envelope classes carry the same five members without the conformance',
        'XdrJsonValue': 'XDR-JSON document tree (null, bool, number, string, array, object) holding object members in XDR declaration order',
        'XdrJsonMember': 'One key and value of an XdrJsonValue object',
        'XdrJson': 'Shared runtime carrying the escaping, hex, strkey, integer, container and depth rules every conversion applies',
        'XdrJsonWriter': 'Renders an XdrJsonValue as XDR-JSON text with no insignificant whitespace',
        'XdrJsonParser': 'Parses XDR-JSON text into an XdrJsonValue',
        'XdrWideInteger': 'Base-10 conversion for the 128-bit and 256-bit integer parts types',
        'XdrJsonError': 'Error enum for conversion failures (malformedJson, unexpectedType, missingField, duplicateKey, unknownEnumValue, unknownUnionArm, unknownField, invalidValue, recursionLimitExceeded, unrepresentable)',
        '<Name>JsonCodec': 'Conversion entry points for XDR types a Swift typealias collapses onto another type, such as HashXDRJsonCodec, AccountIDXDRJsonCodec and AssetCode4XDRJsonCodec',
    }

    # SEP-51 is prose and JSON snippets rather than field tables, so its features are bundled in data/.
    DEFINITION_FILE = 'sep_0051_definition.json'

    # A public XDR type declaration: either a typedef collapsed onto a Swift typealias, or a
    # struct, enum or class that participates in XDR encoding.
    XDR_TYPE_DECLARATION = re.compile(
        r"public (?:typealias (?P<alias>\w+)"
        r"|(?:final |indirect )?(?:struct|enum|class) (?P<name>\w+)\s*:[^\n]*XDR(?:Codable|Encodable|Decodable))"
    )

    # The escape ladder SEP-51 defines for the string data type, one branch per rule.
    STRING_ESCAPE_LADDER = [
        r'case 0x00: text += "\\0"',
        r'case 0x09: text += "\\t"',
        r'case 0x0A: text += "\\n"',
        r'case 0x0D: text += "\\r"',
        r'case 0x5C: text += "\\\\"',
        'case 0x20...0x7E: text.unicodeScalars.append(UnicodeScalar(byte))',
        r'text += "\\x"',
    ]

    def __init__(self, sdk_analyzer: SDKAnalyzer):
        super().__init__(sdk_analyzer)
        self.runtime_dir = sdk_analyzer.stellarsdk_path / 'xdr_json'
        self.handwritten_dir = self.runtime_dir / 'handwritten'
        self.generated_dir = sdk_analyzer.stellarsdk_path / 'responses' / 'xdr'
        self.runtime: Dict[str, str] = {}
        self.handwritten: Dict[str, str] = {}
        self.generated: Dict[str, str] = {}

    def analyze(self, sep_info: SEPInfo) -> CompatibilityMatrix:
        """Analyze SEP-51 implementation"""
        logger.info("Analyzing SEP-51 (XDR-JSON) implementation")

        sections = self._load_definition(self.DEFINITION_FILE, 'xdr_json_features')
        self._load_sources()
        self.implementation_files = [
            self.sdk_analyzer.get_relative_path(path)
            for path in sorted(self.runtime_dir.glob('*.swift')) + sorted(self.handwritten_dir.glob('*.swift'))
        ]
        if self.generated:
            # The generated XDR types are one file per type, so the directory stands for them.
            self.implementation_files.append(self.sdk_analyzer.get_relative_path(self.generated_dir) + '/')
        analyzers = {
            'XDR Data Types': self._analyze_xdr_data_types,
            'Address Types': self._analyze_address_types,
            'Asset Code Types': self._analyze_asset_code_types,
            'Integer Types': self._analyze_integer_types,
            'JSON Schema': self._analyze_json_schema,
            'XDR-JSON v1 Compatibility': self._analyze_v1_compatibility,
            'Implementation Support': self._analyze_implementation_support,
        }

        for section in sections:
            analyze_section = analyzers.get(section.name)
            if analyze_section is None:
                logger.warning(f"No analysis implemented for SEP-51 section: {section.name}")
                continue
            analyze_section(section)

        return self._matrix(sep_info, sections)

    def _load_sources(self) -> None:
        """Read the XDR-JSON runtime, the hand-written conversions and the generated XDR types"""
        self.runtime = self._read_directory(self.runtime_dir)
        self.handwritten = self._read_directory(self.handwritten_dir)
        self.generated = self._read_directory(self.generated_dir)

        logger.info(
            f"Read {len(self.runtime)} runtime file(s), {len(self.handwritten)} hand-written "
            f"conversion file(s) and {len(self.generated)} generated XDR file(s)"
        )

    def _read_directory(self, directory: Path) -> Dict[str, str]:
        """Read every Swift file directly inside a directory, keyed by file name"""
        return {path.name: read_source(path) for path in sorted(directory.glob('*.swift'))}

    def _runtime_source(self, name: str) -> str:
        """The text of an XDR-JSON runtime file, or an empty string when it is absent"""
        return self.runtime.get(name, '')

    def _handwritten_source(self, name: str) -> str:
        """The text of a hand-written conversion file, or an empty string when it is absent"""
        return self.handwritten.get(name, '')

    def _generated_source(self, name: str) -> str:
        """The text of a generated XDR type file, or an empty string when it is absent"""
        return self.generated.get(name, '')

    @staticmethod
    def _mark(field: SEPField, detected: bool, sdk_property: str) -> None:
        """Record a detection result on a field"""
        if detected:
            field.mark(sdk_property)

    def _analyze_xdr_data_types(self, section: SEPSection) -> None:
        """Analyze the mapping of the RFC 4506 data types"""
        runtime = self._runtime_source('XdrJson.swift')
        writer = self._runtime_source('XdrJsonWriter.swift')
        hash_xdr = self._generated_source('HashXDR.swift')
        bytes_xdr = self._generated_source('SCBytesXDR.swift')
        vec_xdr = self._generated_source('SCVecXDR.swift')
        asset_type = self._generated_source('AssetType.swift')
        time_bounds = self._generated_source('TimeBoundsXDR.swift')
        asset = self._generated_source('AssetXDR.swift')
        account_ext = self._generated_source('AccountEntryExtXDR.swift')
        set_options = self._generated_source('SetOptionsOperationXDR.swift')

        for field in section.fields:
            if field.name == 'integer_32bit':
                self._mark(
                    field,
                    'static func int32(_ value: Int32) -> XdrJsonValue { .number(String(value)) }' in runtime,
                    'XdrJson.int32')
            elif field.name == 'unsigned_integer_32bit':
                self._mark(
                    field,
                    'static func uint32(_ value: UInt32) -> XdrJsonValue { .number(String(value)) }' in runtime,
                    'XdrJson.uint32')
            elif field.name == 'hyper_integer_64bit':
                self._mark(
                    field,
                    'static func int64(_ value: Int64) -> XdrJsonValue { .string(String(value)) }' in runtime,
                    'XdrJson.int64')
            elif field.name == 'unsigned_hyper_integer_64bit':
                self._mark(
                    field,
                    'static func uint64(_ value: UInt64) -> XdrJsonValue { .string(String(value)) }' in runtime,
                    'XdrJson.uint64')
            elif field.name == 'boolean':
                self._mark(
                    field,
                    'static func bool(_ value: Bool) -> XdrJsonValue { .bool(value) }' in runtime
                    and 'guard case .bool(let flag) = value else' in runtime,
                    'XdrJson.bool')
            elif field.name == 'opaque_fixed_length':
                self._mark(
                    field,
                    'static func hex(_ data: Data, expectedLength: Int, type: String, key: String? = nil) throws -> XdrJsonValue' in runtime
                    and 'XdrJson.hex(value.wrapped, expectedLength: 32, type: type, key: key)' in hash_xdr,
                    'XdrJson.hex (declared width checked)')
            elif field.name == 'opaque_variable_length':
                self._mark(
                    field,
                    'static func hex(_ data: Data) -> XdrJsonValue' in runtime
                    and 'XdrJson.hex(' in bytes_xdr,
                    'XdrJson.hex')
            elif field.name == 'string_escape_ladder':
                self._mark(
                    field,
                    all(rule in runtime for rule in self.STRING_ESCAPE_LADDER)
                    and 'static func unescapeString(' in runtime,
                    'XdrJson.escapedText / XdrJson.unescapeString')
            elif field.name == 'string_json_escaping':
                self._mark(
                    field,
                    r'case "\\":' in writer and r'buffer += "\\\\"' in writer,
                    'XdrJsonWriter.writeString')
            elif field.name == 'array_fixed_length':
                self._mark(
                    field,
                    any(re.search(r'Elements\.count == Int\(\d+\)', source)
                        for source in self.generated.values()),
                    'XdrJson.array (declared element count enforced)')
            elif field.name == 'array_variable_length':
                self._mark(
                    field,
                    'static func array(_ values: [XdrJsonValue]) -> XdrJsonValue' in runtime
                    and 'static func array(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> [XdrJsonValue]' in runtime
                    and 'XdrJson.array(self.wrapped.map' in vec_xdr,
                    'XdrJson.array')
            elif field.name == 'enum_name_mapping':
                self._mark(
                    field,
                    'return "ASSET_TYPE_CREDIT_ALPHANUM4"' in asset_type
                    and 'return .string("credit_alphanum4")' in asset_type
                    and 'XdrJsonError.unknownEnumValue' in asset_type,
                    'AssetType (snake_case, shared prefix removed)')
            elif field.name == 'struct_object_keys':
                self._mark(
                    field,
                    'static func object(_ value: XdrJsonValue, type: String,' in runtime
                    and 'XdrJsonMember(key: "min_time"' in time_bounds
                    and 'XdrJson.object(value, type: "TimeBoundsXDR", keys: ["min_time", "max_time"])' in time_bounds,
                    'XdrJson.object')
            elif field.name == 'union_void_arm':
                self._mark(
                    field,
                    'case .native: return .string("native")' in asset
                    and re.search(r'case "native":\s*\n\s*return \.native', asset) is not None,
                    'AssetXDR (void arm as a bare string)')
            elif field.name == 'union_valued_arm':
                self._mark(
                    field,
                    'static func singleKeyObject(' in runtime
                    and 'XdrJsonMember(key: "credit_alphanum4", value: try payload.toXdrJsonValue())' in asset
                    and 'XdrJson.singleKeyObject(value, type: "AssetXDR")' in asset,
                    'XdrJson.singleKeyObject')
            elif field.name == 'union_integer_cases':
                self._mark(
                    field,
                    'case .void: return .string("v0")' in account_ext
                    and 'XdrJsonMember(key: "v1"' in account_ext,
                    'AccountEntryExtXDR (v0, v1)')
            elif field.name == 'void':
                self._mark(
                    field,
                    'this arm carries no value, so it is written as a bare string' in asset
                    and 'this arm carries a value, so it is written as a single-key object' in asset,
                    'AssetXDR (object form of a void arm rejected)')
            elif field.name == 'optional_null':
                self._mark(
                    field,
                    'static func optional(_ value: XdrJsonValue?) -> XdrJsonValue { value ?? .null }' in runtime
                    and 'XdrJson.optional(' in set_options
                    and '.isNull' in set_options,
                    'XdrJson.optional')

    def _analyze_address_types(self, section: SEPSection) -> None:
        """Analyze the Stellar address, signer and key types"""
        sc_address = self._generated_source('SCAddressXDR.swift')
        account_id = self._generated_source('AccountIDXDR.swift')
        contract_id = self._generated_source('ContractIDXDR.swift')
        pool_id = self._generated_source('PoolIDXDR.swift')
        balance_id = self._generated_source('ClaimableBalanceIDXDR.swift')
        node_id = self._generated_source('NodeIDXDR.swift')
        signer_key = self._generated_source('SignerKeyXDR.swift')
        signed_payload = self._generated_source('Ed25519SignedPayload.swift')
        account_keys = self._handwritten_source('PublicKey+XdrJson.swift')

        for field in section.fields:
            if field.name == 'sc_address':
                self._mark(
                    field,
                    'extension SCAddressXDR: XdrJsonCodable' in sc_address
                    and all(f'case "{prefix}":' in sc_address for prefix in ('G', 'C', 'M', 'B', 'L')),
                    'SCAddressXDR')
            elif field.name == 'account_id':
                self._mark(
                    field,
                    'public typealias AccountIDXDR = PublicKey' in account_id
                    and 'public enum AccountIDXDRJsonCodec {' in account_id
                    and 'PublicKey.fromXdrJsonValue(value)' in account_id,
                    'AccountIDXDRJsonCodec')
            elif field.name == 'contract_id':
                self._mark(
                    field,
                    'encodeContractId()' in contract_id and 'decodeContractId()' in contract_id,
                    'ContractIDXDRJsonCodec')
            elif field.name == 'muxed_account':
                self._mark(
                    field,
                    'extension MuxedAccountXDR: XdrJsonCodable' in account_keys
                    and 'case "G":' in account_keys and 'case "M":' in account_keys,
                    'MuxedAccountXDR')
            elif field.name == 'muxed_account_med25519':
                self._mark(
                    field,
                    'extension MuxedAccountMed25519XDR: XdrJsonCodable' in account_keys
                    and 'encodeMEd25519AccountId()' in account_keys
                    and 'decodeMed25519PublicKey()' in account_keys,
                    'MuxedAccountMed25519XDR')
            elif field.name == 'muxed_ed25519_account':
                self._mark(
                    field,
                    'return .muxedAccount(try MuxedAccountMed25519XDR.fromXdrJsonValue(value))' in sc_address,
                    'SCAddressXDR.muxedAccount')
            elif field.name == 'pool_id':
                self._mark(
                    field,
                    'encodeLiquidityPoolId()' in pool_id and 'decodeLiquidityPoolId()' in pool_id,
                    'PoolIDXDRJsonCodec')
            elif field.name == 'claimable_balance_id':
                self._mark(
                    field,
                    'encodeClaimableBalanceId()' in balance_id and 'decodeClaimableBalanceId()' in balance_id,
                    'ClaimableBalanceIDXDR')
            elif field.name == 'public_key':
                self._mark(
                    field,
                    'extension PublicKey: XdrJsonCodable' in account_keys
                    and 'encodeEd25519PublicKey()' in account_keys
                    and 'decodeEd25519PublicKey()' in account_keys,
                    'PublicKey')
            elif field.name == 'node_id':
                self._mark(
                    field,
                    'public typealias NodeIDXDR = PublicKey' in node_id
                    and 'public enum NodeIDXDRJsonCodec {' in node_id,
                    'NodeIDXDRJsonCodec')
            elif field.name == 'signer_key':
                self._mark(
                    field,
                    all(anchor in signer_key for anchor in (
                        'encodeEd25519PublicKey()', 'encodePreAuthTx()', 'encodeSha256Hash()',
                        'case "T":', 'case "X":', 'case "P":')),
                    'SignerKeyXDR')
            elif field.name == 'signer_key_ed25519_signed_payload':
                self._mark(
                    field,
                    'encodeSignedPayload()' in signed_payload and 'decodeSignedPayload()' in signed_payload,
                    'Ed25519SignedPayload')

    def _analyze_asset_code_types(self, section: SEPSection) -> None:
        """Analyze the asset code types"""
        asset_code = self._generated_source('AllowTrustOpAssetXDR.swift')
        asset_code4 = self._generated_source('AssetCode4XDR.swift')
        asset_code12 = self._generated_source('AssetCode12XDR.swift')

        for field in section.fields:
            if field.name == 'asset_code':
                self._mark(
                    field,
                    'XdrJson.unescapeString(value, type: "AllowTrustOpAssetXDR")' in asset_code
                    and 'raw.count <= 4' in asset_code and 'raw.count <= 12' in asset_code,
                    'AllowTrustOpAssetXDR')
            elif field.name == 'asset_code4':
                self._mark(
                    field,
                    'XdrJson.trimTrailingNulls(value.wrapped, keepingAtLeast: 0)' in asset_code4
                    and 'XdrJson.rightPad(raw, to: 4)' in asset_code4,
                    'AssetCode4XDRJsonCodec')
            elif field.name == 'asset_code12':
                self._mark(
                    field,
                    'XdrJson.trimTrailingNulls(value.wrapped, keepingAtLeast: 5)' in asset_code12
                    and 'XdrJson.rightPad(raw, to: 12)' in asset_code12,
                    'AssetCode12XDRJsonCodec')

    def _analyze_integer_types(self, section: SEPSection) -> None:
        """Analyze the 128-bit and 256-bit integer parts types"""
        parts_types = {
            'uint128_parts': ('UInt128PartsXDR', 128, 'false'),
            'int128_parts': ('Int128PartsXDR', 128, 'true'),
            'uint256_parts': ('UInt256PartsXDR', 256, 'false'),
            'int256_parts': ('Int256PartsXDR', 256, 'true'),
        }

        for field in section.fields:
            entry = parts_types.get(field.name)
            if entry is None:
                continue
            type_name, bit_size, signed = entry
            source = self._generated_source(f'{type_name}.swift')
            self._mark(
                field,
                f'signed: {signed})' in source
                and f'XdrJson.wideDecimal(value, bitSize: {bit_size}, signed: {signed}, type: "{type_name}")' in source,
                f'{type_name} (XdrJson.wideDecimal)')

    def _analyze_json_schema(self, section: SEPSection) -> None:
        """Analyze handling of the optional $schema property"""
        runtime = self._runtime_source('XdrJson.swift')

        for field in section.fields:
            if field.name == 'schema_property':
                self._mark(
                    field,
                    'static let schemaKey = "$schema"' in runtime
                    and 'static func stripSchema(_ members: [XdrJsonMember]) -> [XdrJsonMember]' in runtime
                    and 'members.filter { $0.key != schemaKey }' in runtime,
                    'XdrJson.stripSchema')

    def _analyze_v1_compatibility(self, section: SEPSection) -> None:
        """Analyze the XDR-JSON version 1 allowances for 64-bit integers

        Both allowances are about reading: a JSON number is accepted where a 64-bit integer
        is expected. Emission is unaffected and stays a string, which the Hyper and Unsigned
        Hyper features in the XDR Data Types section cover.
        """
        runtime = self._runtime_source('XdrJson.swift')

        fixed_width = re.search(
            r'private static func fixedWidth<T: FixedWidthInteger>\(.*?\n    \}',
            runtime, re.DOTALL)
        accepts_number = fixed_width is not None and 'case .number(let text):' in fixed_width.group(0)

        readers = {
            'hyper_json_number_input': ('int64', 'Int64', 'XdrJson.int64'),
            'unsigned_hyper_json_number_input': ('uint64', 'UInt64', 'XdrJson.uint64'),
        }

        for field in section.fields:
            entry = readers.get(field.name)
            if entry is None:
                continue
            method, return_type, sdk_property = entry
            delegates = re.search(
                r'static func %s\(_ value: XdrJsonValue, type: String, key: String\? = nil\) '
                r'throws -> %s \{\s*try fixedWidth\(' % (method, return_type),
                runtime)
            self._mark(field, accepts_number and delegates is not None,
                       f'{sdk_property} (JSON number accepted on input)')

    def _analyze_implementation_support(self, section: SEPSection) -> None:
        """Analyze the conversion surface the SDK exposes"""
        codable = self._runtime_source('XdrJsonCodable.swift')
        codec_namespaces = sum(
            1 for source in self.generated.values()
            if re.search(r'public enum \w+JsonCodec \{', source)
        )

        for field in section.fields:
            if field.name == 'to_xdr_json':
                self._mark(field, 'func toXdrJson() throws -> String' in codable,
                           'XdrJsonCodable.toXdrJson()')
            elif field.name == 'to_xdr_json_value':
                self._mark(field, 'func toXdrJsonValue() throws -> XdrJsonValue' in codable,
                           'XdrJsonCodable.toXdrJsonValue()')
            elif field.name == 'from_xdr_json':
                self._mark(field, 'static func fromXdrJson(_ json: String) throws -> Self' in codable,
                           'XdrJsonCodable.fromXdrJson(_:)')
            elif field.name == 'from_xdr_json_value':
                self._mark(field, 'static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> Self' in codable,
                           'XdrJsonCodable.fromXdrJsonValue(_:)')
            elif field.name == 'from_xdr_json_tree':
                self._mark(
                    field,
                    'static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> Self' in codable
                    and 'XdrJson.validateDepth(value)' in codable,
                    'XdrJsonCodable.fromXdrJsonTree(_:)')
            elif field.name == 'typedef_codec_namespace':
                self._mark(field, codec_namespaces > 0,
                           f'{codec_namespaces} <Name>JsonCodec namespace(s)')
            elif field.name == 'xdr_type_conversions':
                total, uncovered = self._xdr_type_conversion_coverage()
                if uncovered:
                    logger.warning(
                        "XDR types without an XDR-JSON conversion: "
                        + ", ".join(f"{type_name} ({file_name})" for file_name, type_name in uncovered))
                self._mark(field, total > 0 and not uncovered,
                           f'{total} XDR type(s), all convertible')

    @staticmethod
    def _declares_conversion(source: str) -> bool:
        """Whether a Swift file carries an XDR-JSON conversion of its own"""
        return (re.search(r':\s*XdrJsonCodable\b', source) is not None
                or re.search(r'public enum \w+JsonCodec \{', source) is not None)

    def _xdr_type_conversion_coverage(self) -> Tuple[int, List[Tuple[str, str]]]:
        """Count the XDR types and report those without an XDR-JSON conversion

        A type is convertible when

        - its own file carries the conversion,
        - a hand-written conversion converts it or uses it as an encoding intermediary,
        - another generated file converts it through a private helper, which is what happens
          when one Swift type stands in for two XDR types, or
        - it only ever appears as the discriminant of a union that is itself converted
          elsewhere, in which case its XDR-JSON form is the union's arm name rather than a
          value of its own.

        Returns:
            The number of XDR types declared and the (file, type) pairs left unconverted
        """
        handwritten_text = '\n'.join(self.handwritten.values())

        total = 0
        uncovered = []

        for file_name, source in self.generated.items():
            declared = [match.group('alias') or match.group('name')
                        for match in self.XDR_TYPE_DECLARATION.finditer(source)]
            total += len(declared)

            if self._declares_conversion(source):
                continue

            for type_name in declared:
                escaped = re.escape(type_name)

                # The conversion is hand-written for it.
                if re.search(rf'^extension {escaped}\b', handwritten_text, re.MULTILINE):
                    continue

                # A hand-written conversion uses it as an encoding intermediary. Calling the
                # type's own conversion does not count: that conversion is what this check is
                # looking for.
                if (re.search(rf'\b{escaped}\b', handwritten_text)
                        and not re.search(rf'\b{escaped}(?:JsonCodec)?\.fromXdrJson', handwritten_text)):
                    continue

                if any(re.search(rf'ToXdrJsonValue\(_ \w+: {escaped}\)', other)
                       for other in self.generated.values()):
                    continue

                # Referenced only as the raw value of a union discriminant, from files that
                # carry no conversion of their own and are therefore converted elsewhere.
                referencing = {
                    other_name: [match for match in re.finditer(rf'\b{escaped}\b(\.\w+\.rawValue)?', other)]
                    for other_name, other in self.generated.items() if other_name != file_name
                }
                referencing = {name: matches for name, matches in referencing.items() if matches}
                if referencing and all(
                    match.group(1) and not self._declares_conversion(self.generated[name])
                    for name, matches in referencing.items() for match in matches
                ):
                    continue

                uncovered.append((file_name, type_name))

        return total, uncovered


# Analyzers by two-digit SEP number, in the order --list prints them
ANALYZERS: Dict[str, type] = {
    '01': SEP01Analyzer, '02': SEP02Analyzer, '05': SEP05Analyzer, '06': SEP06Analyzer, '07': SEP07Analyzer,
    '08': SEP08Analyzer, '09': SEP09Analyzer, '10': SEP10Analyzer, '11': SEP11Analyzer, '12': SEP12Analyzer,
    '23': SEP23Analyzer, '24': SEP24Analyzer, '29': SEP29Analyzer, '30': SEP30Analyzer, '38': SEP38Analyzer,
    '45': SEP45Analyzer, '46': SEP46Analyzer, '47': SEP47Analyzer, '48': SEP48Analyzer, '51': SEP51Analyzer,
    '53': SEP53Analyzer,
}


def create_analyzer(sep_number: str, sdk_analyzer: SDKAnalyzer) -> SEPAnalyzerBase:
    """The analyzer for a two-digit ("10") or four-digit ("0010") SEP number; an unknown number raises"""
    key = sep_number[2:] if len(sep_number) == 4 and sep_number.startswith('00') else sep_number
    if key not in ANALYZERS:
        raise ValueError(f"Analyzer not implemented for SEP-{sep_number}. Available SEPs: {', '.join(ANALYZERS)}")
    return ANALYZERS[key](sdk_analyzer)


class MatrixRenderer:
    """Renders compatibility matrix to Markdown"""

    def render(self, matrix: CompatibilityMatrix, sdk_version: str) -> str:
        """Generate Markdown document"""
        return "\n\n".join([
            self._render_header(matrix, sdk_version),
            self._render_sep_summary(matrix),
            self._render_overall_coverage(matrix),
            self._render_implementation_status(matrix),
            self._render_coverage_by_section(matrix),
            self._render_detailed_fields(matrix),
            self._render_implementation_gaps(matrix),
            self._render_legend(matrix),
        ])

    def _render_header(self, matrix: CompatibilityMatrix, sdk_version: str) -> str:
        """Render document header"""
        sep_padded = matrix.sep_info.number.zfill(4)
        return f"""# SEP-{sep_padded} ({matrix.sep_info.title}) Compatibility Matrix

**Generated:** {matrix.last_updated}

**SDK Version:** {sdk_version}

**SEP Version:** {matrix.sep_info.version or 'Unknown'}

**SEP Status:** {matrix.sep_info.status or 'Unknown'}

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-{sep_padded}.md"""

    def _render_sep_summary(self, matrix: CompatibilityMatrix) -> str:
        """Render SEP summary"""
        paragraphs = matrix.sep_info.purpose.split('. ')
        formatted_paragraphs = []

        for para in paragraphs:
            if para.strip():
                # Add period back if it was removed by split
                if not para.endswith('.'):
                    para = para + '.'
                formatted_paragraphs.append(para.strip())

        purpose_text = '\n\n'.join(formatted_paragraphs)

        return f"""## SEP Summary

{purpose_text}"""

    def _render_overall_coverage(self, matrix: CompatibilityMatrix) -> str:
        """Render overall coverage statistics"""
        coverage_text = f"""## Overall Coverage

**Total Coverage:** {matrix.overall_coverage:.1f}% ({matrix.implemented_fields}/{matrix.total_fields} fields)

- ✅ **Implemented:** {matrix.implemented_fields}/{matrix.total_fields}
- ❌ **Not Implemented:** {matrix.total_fields - matrix.implemented_fields}/{matrix.total_fields}"""

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
        return '\n'.join(f"- **`{name}`**: {description}" for name, description in matrix.key_classes.items())

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

                if field.server_only:
                    status = "⚙️ Server"
                    sdk_prop = "N/A"
                else:
                    status = "✅" if field.implemented else "❌"
                    sdk_prop = f"`{field.sdk_property}`" if field.sdk_property else "-"

                desc = field.description
                if len(desc) > 150:
                    desc = desc[:147] + "..."

                desc = desc.replace("|", "\\|")

                sections.append(f"| {field_name} | {required} | {status} | {sdk_prop} | {desc} |")

        return '\n'.join(sections)

    def _render_implementation_gaps(self, matrix: CompatibilityMatrix) -> str:
        """Render implementation gaps"""
        missing_fields = []

        for section in matrix.sections:
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

    def _render_legend(self, matrix: CompatibilityMatrix) -> str:
        """Render status legend"""
        legend = """## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional"""

        if matrix.server_only_count > 0:
            legend += f"\n\n**Note:** Excludes {matrix.server_only_count} server-side-only feature(s) not applicable to client SDKs"

        return legend


class SEPMatrixGenerator:
    """Main generator orchestrating the matrix generation"""

    def __init__(self, sdk_root: Path):
        self.sdk_root = sdk_root
        self.fetcher = SEPFetcher()
        self.sdk_analyzer = SDKAnalyzer(sdk_root)
        self.sdk_version = get_sdk_version(sdk_root)
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

        sep_info = self.fetcher.fetch_sep(sep_number)

        analyzer = create_analyzer(sep_number, self.sdk_analyzer)

        matrix = analyzer.analyze(sep_info)

        markdown_content = self.renderer.render(matrix, self.sdk_version)

        if output_path is None:
            sep_padded = sep_number.zfill(4)
            output_dir = self.sdk_root / "compatibility" / "sep"
            output_dir.mkdir(parents=True, exist_ok=True)
            output_path = output_dir / f"SEP-{sep_padded}_COMPATIBILITY_MATRIX.md"

        output_path.write_text(markdown_content, encoding='utf-8')
        logger.info(f"Generated matrix: {output_path}")

        return output_path


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

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    if args.list:
        print("Available SEPs with implemented analyzers:")
        for sep in ANALYZERS:
            print(f"  - SEP-{sep.zfill(4)}")
        return 0

    if not args.sep:
        parser.error("--sep is required (or use --list to see available SEPs)")

    if not args.sdk_root.exists():
        parser.error(f"SDK root not found: {args.sdk_root}")

    try:
        generator = SEPMatrixGenerator(args.sdk_root)
        output_path = generator.generate_matrix(args.sep, args.output)

        print(f"Generated the SEP-{args.sep.zfill(4)} compatibility matrix: {output_path}")

        return 0

    except ValueError as e:
        logger.error(f"Error: {e}")
        return 1
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return 2


if __name__ == '__main__':
    sys.exit(main())
