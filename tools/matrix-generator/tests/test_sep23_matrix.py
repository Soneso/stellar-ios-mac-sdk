"""Tests for the SEP-23 matrix: the specification parser, the SDK checks, and the rendered matrix.

fixtures/sep-0023.md is ecosystem/sep-0023.md of stellar-protocol at 9cd7030.
"""

import contextlib
import io
import logging
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

TOOL_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = TOOL_DIR.parents[1]
sys.path.insert(0, str(TOOL_DIR / "sep"))

import generate_sep_matrix  # noqa: E402
from generate_sep_matrix import SDKAnalyzer, SEP23Analyzer, SEP23SpecParser, SEPAnalyzerFactory, SEPInfo  # noqa: E402
from generate_sep_matrix import SEPMatrixGenerator  # noqa: E402

SPEC = (Path(__file__).resolve().parent / "fixtures" / "sep-0023.md").read_text(encoding="utf-8")
TRACKED_MATRIX = REPO_ROOT / "compatibility" / "sep" / "SEP-0023_COMPATIBILITY_MATRIX.md"

TEST_FILE = "stellarsdk/stellarsdkUnitTests/sep/strkey/StrKeyUnitTests.swift"
VERSION_BYTE_PATH = "stellarsdk/stellarsdk/crypto/VersionByte.swift"
ENCODE_PATH = "stellarsdk/stellarsdk/extensions/Data+KeyUtils.swift"
DECODE_PATH = "stellarsdk/stellarsdk/extensions/String+KeyUtils.swift"
KEY_TYPES_SECTION = "Key types"
VECTORS_SECTION = "Test vectors quoted in the StrKey unit test files"

KEY_TYPES = [
    ("STRKEY_PUBKEY", "6 << 3", 48, "G"), ("STRKEY_MUXED", "12 << 3", 96, "M"),
    ("STRKEY_PRIVKEY", "18 << 3", 144, "S"), ("STRKEY_PRE_AUTH_TX", "19 << 3", 152, "T"),
    ("STRKEY_HASH_X", "23 << 3", 184, "X"), ("STRKEY_SIGNED_PAYLOAD", "15 << 3", 120, "P"),
    ("STRKEY_CONTRACT", "2 << 3", 16, "C"), ("STRKEY_LIQUIDITY_POOL", "11 << 3", 88, "L"),
    ("STRKEY_CLAIMABLE_BALANCE", "1 << 3", 8, "B"),
]
ALL_KEY_TYPES = {name for name, _, _, _ in KEY_TYPES}

VALID_VECTORS = [
    ("valid_01", "Valid non-multiplexed account", "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"),
    ("valid_02", "Valid multiplexed account", "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ"),
    ("valid_03", "Valid multiplexed account in which unsigned id exceeds maximum signed 64-bit integer",
     "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"),
    ("valid_04", "Valid signed payload with an ed25519 public key and a 32-byte payload.",
     "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM"),
    ("valid_05", "Valid signed payload with an ed25519 public key and a 29-byte payload which becomes zero padded.",
     "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU"),
    ("valid_06", "Valid contract", "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"),
    ("valid_07", "Valid liquidity pool address", "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"),
    ("valid_08", "Valid claimable balance address", "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"),
]

INVALID_VECTORS = [
    ("invalid_01", "Invalid length (Ed25519 should be 32 bytes, not 5)", "GAAAAAAAACGC6"),
    ("invalid_02", "The unused trailing bit must be zero in the encoding of the last three bytes (24 bits) as five "
     "base-32 symbols (25 bits)", "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUR"),
    ("invalid_03", "Invalid length (congruent to 1 mod 8)", "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA"),
    ("invalid_04", "Invalid length (base-32 decoding should yield 35 bytes, not 36)",
     "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUACUSI"),
    ("invalid_05", "Invalid algorithm (low 3 bits of version byte are 7)",
     "G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I"),
    ("invalid_06", "Invalid length (congruent to 6 mod 8)",
     "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLKA"),
    ("invalid_07", "Invalid length (base-32 decoding should yield 43 bytes, not 44)",
     "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAAV75I"),
    ("invalid_08", "Invalid algorithm (low 3 bits of version byte are 7)",
     "M47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ"),
    ("invalid_09", "Padding bytes are not allowed",
     "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUK==="),
    ("invalid_10", "Invalid checksum", "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUO"),
    ("invalid_11", "Length prefix specifies length that is shorter than payload in signed payload",
     "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IAAAAAAAAPM"),
    ("invalid_12", "Length prefix specifies length that is longer than payload in signed payload",
     "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4Z2PQ"),
    ("invalid_13", "No zero padding in signed payload",
     "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DXFH6"),
    ("invalid_14", "The unused trailing 2-bits must be zero in the encoding of the last symbol.",
     "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TV"),
    ("invalid_15", "Invalid claimable balance type (first byte of binary key is not 0)",
     "BAAT6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGXACA"),
]

# The VersionByte case, raw value, encode function and decode function the SDK declares per key type.
SDK_DECLARATIONS = [
    ("ed25519PublicKey", "48", "encodeEd25519PublicKey", "decodeEd25519PublicKey"),
    ("med25519PublicKey", "96", "encodeMEd25519AccountId", "decodeMed25519PublicKey"),
    ("ed25519SecretSeed", "144", "encodeEd25519SecretSeed", "decodeEd25519SecretSeed"),
    ("preAuthTX", "152", "encodePreAuthTx", "decodePreAuthTx"),
    ("sha256Hash", "184", "encodeSha256Hash", "decodeSha256Hash"),
    ("signedPayload", "120", "encodeSignedPayload", "decodeSignedPayload"),
    ("contract", "16", "encodeContractId", "decodeContractId"),
    ("liquidityPool", "88", "encodeLiquidityPoolId", "decodeLiquidityPoolId"),
    ("claimableBalance", "8", "encodeClaimableBalanceId", "decodeClaimableBalanceId"),
]
VERSION_BYTE_SWIFT = "enum VersionByte:UInt8 {\n" + "".join(
    f"    /// Version byte of {case}\n    case {case} = {value} // SEP-23 base value\n"
    for case, value, _, _ in SDK_DECLARATIONS) + "}\n"
DATA_KEY_UTILS_SWIFT = "extension Data {\n" + "".join(
    f"    public func {encode}() throws -> String {{\n        return try encodeCheck(versionByte: .{case})\n    }}\n"
    for case, _, encode, _ in SDK_DECLARATIONS) + "}\n"
STRING_KEY_UTILS_SWIFT = "extension String {\n" + "".join(
    f"    public func {decode}() throws -> Data {{\n        return try decodeCheck(versionByte: .{case})\n    }}\n"
    for case, _, _, decode in SDK_DECLARATIONS) + "}\n"


def quoted_literals(strkeys) -> str:
    """A Swift test file quoting each strkey as a string literal."""
    lines = [f'        let strKey{index} = "{strkey}"' for index, strkey in enumerate(strkeys)]
    return "final class StrKeyUnitTests: XCTestCase {\n    func testVectors() {\n" + "\n".join(lines) + "\n    }\n}\n"


EXACT_UNIT_TESTS = quoted_literals(strkey for _, _, strkey in VALID_VECTORS + INVALID_VECTORS)


def setUpModule():
    logging.disable(logging.INFO)


def tearDownModule():
    logging.disable(logging.NOTSET)


def edited(text: str, old: str, new: str) -> str:
    """The text with its single occurrence of old replaced by new."""
    if text.count(old) != 1:
        raise AssertionError(f"expected exactly one occurrence of {old!r}, found {text.count(old)}")
    return text.replace(old, new)


def without_span(text: str, start: str, end: str, replacement: str = "") -> str:
    """The text with everything from start up to, not including, end replaced."""
    begin = text.index(start)
    return text[:begin] + replacement + text[text.index(end, begin):]


def write_sdk_root(root: Path, version_byte=VERSION_BYTE_SWIFT, encoders=DATA_KEY_UTILS_SWIFT,
                   decoders=STRING_KEY_UTILS_SWIFT, unit_tests=EXACT_UNIT_TESTS) -> None:
    """Create an SDK tree with the StrKey sources and unit test file; None leaves a file out."""
    (root / "stellarsdk" / "stellarsdk").mkdir(parents=True)
    files = {VERSION_BYTE_PATH: version_byte, ENCODE_PATH: encoders, DECODE_PATH: decoders, TEST_FILE: unit_tests}
    for relative, text in files.items():
        if text is not None:
            (root / relative).parent.mkdir(parents=True, exist_ok=True)
            (root / relative).write_text(text, encoding="utf-8")


def analyze(content: str = SPEC, **sdk_files):
    """Run the SEP-23 analyzer against a temporary SDK tree."""
    with tempfile.TemporaryDirectory() as tmp:
        write_sdk_root(Path(tmp), **sdk_files)
        info = SEPInfo(number="23", title="Strkeys", purpose="Strkey", version="1.3.0", status="Active",
                       raw_content=content)
        return SEP23Analyzer(SDKAnalyzer(Path(tmp))).analyze(info)


def implemented(matrix, section_name: str) -> set:
    section = next(section for section in matrix.sections if section.name == section_name)
    return {field.name for field in section.fields if field.implemented}


class SpecParserTest(unittest.TestCase):

    def test_key_types_in_table_order_with_evaluated_base_values(self):
        key_types = SEP23SpecParser().parse_key_types(SPEC)
        self.assertEqual([(kt.name, kt.base_expression, kt.version_byte, kt.first_char) for kt in key_types], KEY_TYPES)

    def test_valid_vectors_in_document_order_with_collapsed_titles(self):
        valid, _ = SEP23SpecParser().parse_test_vectors(SPEC)
        self.assertEqual([(v.name, v.title, v.strkey) for v in valid], VALID_VECTORS)

    def test_invalid_vectors_in_document_order_with_collapsed_titles(self):
        _, invalid = SEP23SpecParser().parse_test_vectors(SPEC)
        self.assertEqual([(v.name, v.title, v.strkey) for v in invalid], INVALID_VECTORS)

    def test_invalid_list_ends_before_the_paragraph_introducing_the_c_array(self):
        document = edited(SPEC, "the following array:\n", "the following array:\n\n   - Strkey: `EXTRA`\n")
        _, invalid = SEP23SpecParser().parse_test_vectors(document)
        self.assertEqual([v.strkey for v in invalid], [strkey for _, _, strkey in INVALID_VECTORS])

    def test_both_sections_follow_the_upstream_text(self):
        for base_value, version_byte in (("7 << 3", 56), ("48", 48)):
            with self.subTest(base_value):
                document = edited(edited(SPEC, "| 6 << 3     |", f"| {base_value:<10} |"), "7UJUWDA`", "7UJUWDB`")
                pubkey = SEP23SpecParser().parse_key_types(document)[0]
                valid, _ = SEP23SpecParser().parse_test_vectors(document)
                self.assertEqual((pubkey.base_expression, pubkey.version_byte), (base_value, version_byte))
                self.assertEqual(valid[5].strkey, "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDB")

    def test_version_byte_table_errors_raise(self):
        table_start, table_end = SPEC.index("| Key type "), SPEC.index("\n\nThe low 3 bits") + 1
        moved = edited(SPEC[:table_start] + SPEC[table_end:], "## Implementation\n\n",
                       "## Implementation\n\n" + SPEC[table_start:table_end] + "\n")
        documents = {
            "table after the Specification section": (moved, "text has no version byte table"),
            "Specification heading renamed": (edited(SPEC, "## Specification\n", "## Specifics\n"),
                                              "text has no version byte table"),
            "no First char column": (edited(SPEC, "| First char |", "| First      |"), "text has no version byte table"),
            "no Base value column": (edited(SPEC, "| Base value |", "| Base       |"),
                                     "version byte table has no 'Base value' column"),
            "empty key type": (edited(SPEC, "| STRKEY_MUXED ", "|              "),
                               "version byte table row does not match its header"),
            "empty first char": (edited(SPEC, "| 12 << 3    | M ", "| 12 << 3    |   "),
                                 "version byte table row does not match its header"),
            "no rows": (without_span(SPEC, "| STRKEY_PUBKEY ", "\nThe low 3 bits"), "version byte table has no rows"),
            "short row": (edited(SPEC, "| G          | no    | PK   |", "| G          | no    |"),
                          "version byte table row does not match its header"),
            "base value in another form": (edited(SPEC, "| 6 << 3     |", "| 0x30       |"),
                                           "base value '0x30' is neither an integer nor a shift expression"),
        }
        for case, (document, message) in documents.items():
            with self.subTest(case):
                with self.assertRaisesRegex(ValueError, "SEP-23 " + re.escape(message)):
                    SEP23SpecParser().parse_key_types(document)

    def test_test_case_errors_raise(self):
        contract = "   - Strkey `CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA`\n"
        documents = {
            "no Tests section": (edited(SPEC, "## Tests\n", "## Test Suite\n"), "text has no ## Tests section"),
            "no valid subsection": (edited(SPEC, "### Valid test cases\n", "### Valid cases\n"),
                                    "## Tests section has no ### Valid test cases subsection"),
            "no invalid subsection": (edited(SPEC, "### Invalid test cases\n", "### Invalid cases\n"),
                                      "## Tests section has no ### Invalid test cases subsection"),
            "empty valid list": (without_span(SPEC, "1. Valid non-multiplexed", "### Invalid test cases"),
                                 "### Valid test cases lists no test cases"),
            "empty invalid list": (without_span(SPEC, "1. Invalid length (Ed25519", "You can paste"),
                                   "### Invalid test cases lists no test cases"),
            "case without a strkey": (edited(SPEC, contract, ""), "### Valid test cases case 'Valid contract' lists 0 strkeys"),
            "case with two strkeys": (edited(SPEC, contract, contract * 2), "### Valid test cases case 'Valid contract' lists 2 strkeys"),
        }
        for case, (document, message) in documents.items():
            with self.subTest(case):
                with self.assertRaisesRegex(ValueError, "SEP-23 " + re.escape(message)):
                    SEP23SpecParser().parse_test_vectors(document)


class KeyTypeCheckTest(unittest.TestCase):

    def test_all_nine_key_types_implemented(self):
        matrix = analyze()
        fields = {field.name: field for field in matrix.sections[0].fields}
        self.assertEqual(list(fields), [name for name, _, _, _ in KEY_TYPES])
        self.assertEqual(implemented(matrix, KEY_TYPES_SECTION), ALL_KEY_TYPES)
        self.assertEqual(fields["STRKEY_MUXED"].sdk_property,
                         "VersionByte.med25519PublicKey, encodeMEd25519AccountId(), decodeMed25519PublicKey()")
        self.assertEqual(fields["STRKEY_PUBKEY"].description, "Base value 6 << 3 = 48, first character G")
        self.assertEqual(matrix.implementation_files, [VERSION_BYTE_PATH, ENCODE_PATH, DECODE_PATH])

    def test_value_that_differs_renders_not_implemented(self):
        cases = {
            "SDK value": {"version_byte": edited(VERSION_BYTE_SWIFT, "ed25519PublicKey = 48", "ed25519PublicKey = 49")},
            "upstream value": {"content": edited(SPEC, "| 6 << 3     |", "| 7 << 3     |")},
        }
        for case, arguments in cases.items():
            with self.subTest(case):
                self.assertEqual(implemented(analyze(**arguments), KEY_TYPES_SECTION), ALL_KEY_TYPES - {"STRKEY_PUBKEY"})

    def test_accepted_value_and_declaration_forms(self):
        forms = {
            "hexadecimal": ("ed25519PublicKey = 48", "ed25519PublicKey = 0x30"),
            "binary with separators": ("ed25519SecretSeed = 144", "ed25519SecretSeed = 0b1001_0000"),
            "octal": ("contract = 16", "contract = 0o20"),
            "decimal with separators and a leading zero": ("sha256Hash = 184", "sha256Hash = 01__84_"),
            "computed property between cases": ("    /// Version byte of med25519PublicKey\n",
                                                "    var isAccount: Bool { return self == .ed25519PublicKey }\n"),
            "further conformances": ("enum VersionByte:UInt8 {", "public enum VersionByte: UInt8, Sendable {"),
        }
        for case, (old, new) in forms.items():
            with self.subTest(case):
                matrix = analyze(version_byte=edited(VERSION_BYTE_SWIFT, old, new))
                self.assertEqual(implemented(matrix, KEY_TYPES_SECTION), ALL_KEY_TYPES)

    def test_key_type_mapped_to_none_renders_not_implemented(self):
        with mock.patch.dict(SEP23Analyzer.SDK_NAMES, {"STRKEY_CONTRACT": None}):
            matrix = analyze(version_byte=edited(VERSION_BYTE_SWIFT, "    case contract = 16", "    case other = 16"))
        self.assertEqual(implemented(matrix, KEY_TYPES_SECTION), ALL_KEY_TYPES - {"STRKEY_CONTRACT"})

    def assert_raises_for(self, cases: dict) -> None:
        """Expect each case, a dict of analyze() arguments, to raise the given message after the SEP-23 prefix."""
        for case, (arguments, message) in cases.items():
            with self.subTest(case):
                with self.assertRaisesRegex(ValueError, re.escape("SEP-23 " + message)):
                    analyze(**arguments)

    def test_absent_or_unclosed_enum_raises(self):
        self.assert_raises_for({
            "enum renamed": ({"version_byte": edited(VERSION_BYTE_SWIFT, "enum VersionByte:", "enum VersionBytes:")},
                             f"enum VersionByte: UInt8 not found in {VERSION_BYTE_PATH}"),
            "raw type changed": ({"version_byte": edited(VERSION_BYTE_SWIFT, "VersionByte:UInt8", "VersionByte: Int")},
                                 f"enum VersionByte: UInt8 not found in {VERSION_BYTE_PATH}"),
            "raw type only prefixed by UInt8": ({"version_byte": edited(VERSION_BYTE_SWIFT, ":UInt8", ": UInt8Value")},
                                                f"enum VersionByte: UInt8 not found in {VERSION_BYTE_PATH}"),
            "no closing brace": ({"version_byte": VERSION_BYTE_SWIFT.rstrip()[:-1]},
                                 f"enum VersionByte: UInt8 in {VERSION_BYTE_PATH} has no closing brace"),
        })

    def test_absent_mapped_name_raises(self):
        row = "| STRKEY_CLAIMABLE_BALANCE | 1 << 3     | B          | no    | Hash |\n"
        self.assert_raises_for({
            "case": ({"version_byte": edited(VERSION_BYTE_SWIFT, "case contract =", "case contracts =")},
                     f"VersionByte case contract not found in {VERSION_BYTE_PATH}"),
            "case only after the enum": ({"version_byte": edited(VERSION_BYTE_SWIFT, "    case contract = 16", "")
                                          + "enum Other: UInt8 {\n    case contract = 16\n}\n"},
                                         f"VersionByte case contract not found in {VERSION_BYTE_PATH}"),
            "encode function": ({"encoders": edited(DATA_KEY_UTILS_SWIFT, "func encodeSha256Hash(", "func hash(")},
                                f"function encodeSha256Hash not found in {ENCODE_PATH}"),
            "decode function": ({"decoders": edited(STRING_KEY_UTILS_SWIFT, "func decodeContractId(", "func id(")},
                                f"function decodeContractId not found in {DECODE_PATH}"),
            "decode function only under a longer name": (
                {"decoders": edited(STRING_KEY_UTILS_SWIFT, "func decodeContractId(", "func decodeContractIdToHex(")},
                f"function decodeContractId not found in {DECODE_PATH}"),
            "key type without a mapping": ({"content": edited(SPEC, row, row + row.replace("CLAIMABLE_BALANCE", "FUTURE"))},
                                           "key type STRKEY_FUTURE has no entry in SEP23Analyzer.SDK_NAMES"),
        })

    def test_missing_or_unreadable_file_raises(self):
        self.assert_raises_for({
            "source file missing": ({"decoders": None},
                                    "source file String+KeyUtils.swift not found under stellarsdk/stellarsdk"),
            "unit test file missing": ({"unit_tests": None}, f"cannot read {TEST_FILE}: "),
        })
        with tempfile.TemporaryDirectory() as tmp:
            write_sdk_root(Path(tmp))
            (Path(tmp) / VERSION_BYTE_PATH).write_bytes(b"\xff\xfe")
            with self.assertRaisesRegex(ValueError, re.escape(f"SEP-23 cannot read {VERSION_BYTE_PATH}: ")):
                SEP23Analyzer(SDKAnalyzer(Path(tmp))).analyze(SEPInfo("23", "Strkeys", "", raw_content=SPEC))

    def test_case_value_the_reader_cannot_evaluate_raises(self):
        forms = {
            "no raw value": ("case contract = 16", "case contract", "contract"),
            "associated value": ("case contract = 16", "case contract(Int)", "contract(Int)"),
            "shift expression": ("contract = 16", "contract = 2 << 3", "contract = 2 << 3"),
            "several cases on one line": ("contract = 16", "contract = 16, other = 17", "contract = 16, other = 17"),
            "separator after the prefix": ("contract = 16", "contract = 0x_10", "contract = 0x_10"),
            "uppercase prefix": ("contract = 16", "contract = 0X10", "contract = 0X10"),
            "negative": ("contract = 16", "contract = -16", "contract = -16"),
        }
        for case, (old, new, declaration) in forms.items():
            with self.subTest(case):
                message = f"SEP-23 cannot evaluate VersionByte case '{declaration}' in {VERSION_BYTE_PATH}"
                with self.assertRaisesRegex(ValueError, re.escape(message)):
                    analyze(version_byte=edited(VERSION_BYTE_SWIFT, old, new))


class VectorCheckTest(unittest.TestCase):

    def test_exact_literals_are_all_present(self):
        matrix = analyze(unit_tests=EXACT_UNIT_TESTS)
        fields = matrix.sections[1].fields
        self.assertEqual([field.name for field in fields], [name for name, _, _ in VALID_VECTORS + INVALID_VECTORS])
        self.assertTrue(all(field.implemented for field in fields))
        self.assertEqual([field.description for field in fields],
                         [f"quoted in `StrKeyUnitTests.swift`: {title}" for _, title, _ in VALID_VECTORS + INVALID_VECTORS])

    def test_literal_counts_only_when_complete(self):
        # Longer literals that contain valid_01, valid_03, invalid_10 and invalid_14 without closing where they
        # close, next to invalid_03 and invalid_06 quoted exactly; the last literal holds valid_02 after an X.
        unit_tests = quoted_literals([
            "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA",
            "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLKA",
            "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUO===",
            "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TV===",
            "XMA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ",
        ])
        self.assertEqual(implemented(analyze(unit_tests=unit_tests), VECTORS_SECTION), {"invalid_03", "invalid_06"})


class RegistrationTest(unittest.TestCase):

    def test_registered_under_both_number_forms_and_listed(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_sdk_root(Path(tmp))
            for number in ("23", "0023"):
                with self.subTest(number):
                    self.assertIsInstance(SEPAnalyzerFactory.create_analyzer(number, SDKAnalyzer(Path(tmp))), SEP23Analyzer)
        self.assertIn("23", SEPMatrixGenerator.list_available_seps())


class MainTest(unittest.TestCase):

    def run_main(self, content: str, output: Path, sdk_root: Path = REPO_ROOT) -> int:
        argv = ["generate_sep_matrix.py", "--sep", "23", "--sdk-root", str(sdk_root), "--output", str(output)]
        fetch = mock.Mock(return_value=io.BytesIO(content.encode("utf-8")))
        with mock.patch.object(sys, "argv", argv), mock.patch.object(generate_sep_matrix, "urlopen", fetch), \
                contextlib.redirect_stdout(io.StringIO()):
            status = generate_sep_matrix.main()
        self.assertTrue(fetch.call_args.args[0].full_url.endswith("/ecosystem/sep-0023.md"))
        return status

    def test_render_matches_the_tracked_matrix_except_generation_date_and_sdk_version(self):
        def normalized(text: str) -> str:
            return re.sub(r"^\*\*(Generated|SDK Version):\*\* .+$", r"**\1:**", text, flags=re.MULTILINE)

        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "SEP-0023_COMPATIBILITY_MATRIX.md"
            self.assertEqual(self.run_main(SPEC, output), 0)
            document = output.read_text(encoding="utf-8")
        self.assertIn("**Total Coverage:** 100.0% (32/32 fields)", document)
        self.assertEqual(normalized(document), normalized(TRACKED_MATRIX.read_text(encoding="utf-8")))

    def test_failed_run_exits_non_zero_and_writes_nothing(self):
        runs = {
            "no version byte table": (edited(SPEC, "| Key type ", "| Kind     "), {}),
            "no invalid cases": (without_span(SPEC, "1. Invalid length (Ed25519", "You can paste"), {}),
            "decode function absent": (SPEC, {"decoders": edited(STRING_KEY_UTILS_SWIFT, "func decodeContractId(", "func id(")}),
        }
        for case, (content, sdk_files) in runs.items():
            with self.subTest(case), tempfile.TemporaryDirectory() as tmp:
                sdk_root = Path(tmp) / "sdk"
                write_sdk_root(sdk_root, **sdk_files)
                output = Path(tmp) / "SEP-0023_COMPATIBILITY_MATRIX.md"
                with self.assertLogs(generate_sep_matrix.logger, "ERROR"):
                    status = self.run_main(content, output, sdk_root)
                self.assertEqual(status, 1)
                self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
