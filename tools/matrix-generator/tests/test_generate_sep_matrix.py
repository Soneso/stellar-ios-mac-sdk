"""Tests for generate_sep_matrix: a run that cannot read the SDK version or a found SDK file writes nothing,
the SEP-29 analyzer marks the fee bump check only where the memo check decodes the posted envelope, and the
SEP-51 analyzer marks the ScAddress and MuxedContract rows only where the SDK source converts the W strkey."""

import contextlib
import io
import logging
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sep"))

import generate_sep_matrix  # noqa: E402

SEP_TEXT = "# SEP-XX\n\n## Simple Summary\n\nA summary.\n"

# The SEP-29 memo check of TransactionsService.swift in its current form: both post methods pass the
# posted envelope to memoCheckTransaction, which decodes it.
SEP29_SERVICE = """open class TransactionsService: @unchecked Sendable {
    open func postTransaction(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false) async -> TransactionPostResponseEnum {
        if !skipMemoRequiredCheck, let transaction = memoCheckTransaction(envelope: transactionEnvelope) {
            let checkMemoRequiredEnum = await checkMemoRequired(transaction: transaction)
            return await postChecked(checkMemoRequiredEnum, transactionEnvelope: transactionEnvelope)
        }
        return await postTransactionCore(transactionEnvelope: transactionEnvelope)
    }

    open func postTransactionAsync(transactionEnvelope:String, skipMemoRequiredCheck:Bool = false) async -> TransactionPostAsyncResponseEnum {
        if !skipMemoRequiredCheck, let transaction = memoCheckTransaction(envelope: transactionEnvelope) {
            let checkMemoRequiredEnum = await checkMemoRequired(transaction: transaction)
            return await postAsyncChecked(checkMemoRequiredEnum, transactionEnvelope: transactionEnvelope)
        }
        return await postTransactionAsyncCore(transactionEnvelope: transactionEnvelope)
    }

    private func memoCheckTransaction(envelope: String) -> Transaction? {
        let scalars = envelope.unicodeScalars.filter { $0 != "\\r" && $0 != "\\n" }
        return try? Transaction(envelopeXdr: String(String.UnicodeScalarView(scalars)))
    }
}
"""
SEP29_DECODE = "return try? Transaction(envelopeXdr: String(String.UnicodeScalarView(scalars)))"
SEP29_ENVELOPE_HELPERS = """extension TransactionEnvelopeXDR {
    public var txMemo: MemoXDR {
        switch self {
        case .feeBump(let tevf):
            switch tevf.tx.innerTx {
            case .v1(let tev1):
                return tev1.tx.memo
            }
        case .v1(let tev1):
            return tev1.tx.memo
        }
    }
}
"""

# The XDR-JSON reader of SCAddressXDR.swift, one case per strkey prefix, and the conversion of
# MuxedContractXDR.swift: the lines the SEP-51 ScAddress and MuxedContract probes read.
SEP51_SC_ADDRESS = """extension SCAddressXDR: XdrJsonCodable {
  public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> SCAddressXDR {
    let text = try XdrJson.string(value, type: "SCAddressXDR")
    switch text.first {
    case "G":
      return .account(try PublicKey.fromXdrJsonValue(value))
    case "C":
      return .contract(try ContractIDXDRJsonCodec.fromXdrJsonValue(value, type: "SCAddressXDR", key: "contract"))
    case "M":
      return .muxedAccount(try MuxedAccountMed25519XDR.fromXdrJsonValue(value))
    case "B":
      return .claimableBalanceId(try ClaimableBalanceIDXDR.fromXdrJsonValue(value))
    case "L":
      return .liquidityPoolId(try PoolIDXDRJsonCodec.fromXdrJsonValue(value, type: "SCAddressXDR", key: "liquidity_pool"))
    case "W":
      return .muxedContract(try MuxedContractXDR.fromXdrJsonValue(value))
    default:
      throw XdrJsonError.invalidValue(type: "SCAddressXDR", key: nil, message: "not an address strkey")
    }
  }
}
"""
SEP51_SC_ADDRESS_W_CASE = """    case "W":
      return .muxedContract(try MuxedContractXDR.fromXdrJsonValue(value))
"""
SEP51_MUXED_CONTRACT = """extension MuxedContractXDR: XdrJsonCodable {
  public func toXdrJsonValue() throws -> XdrJsonValue {
    return .string(try XdrJson.strKey(self.strKeyPayload, expectedLength: 40,
                                      type: "MuxedContractXDR", key: nil) { try $0.encodeMuxedContractId() })
  }

  public static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> MuxedContractXDR {
    let text = try XdrJson.string(value, type: "MuxedContractXDR")
    return MuxedContractXDR(strKeyPayload: try XdrJson.strKeyBytes(text, expectedLength: 40,
                                                                   type: "MuxedContractXDR", key: nil) { try $0.decodeMuxedContractId() })
  }
}
"""


def write_sdk_root(root: Path, sdk_version, swift_files: dict) -> None:
    """An SDK tree with an Info.plist (none for sdk_version None) and the given Swift files, as bytes."""
    sources = root / "stellarsdk" / "stellarsdk"
    sources.mkdir(parents=True)
    if sdk_version is not None:
        with open(sources / "Info.plist", "wb") as f:
            plistlib.dump({"CFBundleShortVersionString": sdk_version}, f)
    for relative, content in swift_files.items():
        (sources / relative).parent.mkdir(parents=True, exist_ok=True)
        (sources / relative).write_bytes(content)


class FailedRunTest(unittest.TestCase):

    def run_main(self, sep: str, sdk_version, swift_files: dict):
        """Run main() on a temporary SDK tree; return the exit status, whether a matrix exists, the log, the fetch mock."""
        with tempfile.TemporaryDirectory() as tmp:
            sdk_root = Path(tmp) / "sdk"
            write_sdk_root(sdk_root, sdk_version, swift_files)
            output = Path(tmp) / "matrix.md"
            argv = ["generate_sep_matrix.py", "--sep", sep, "--sdk-root", str(sdk_root), "--output", str(output)]
            fetch = mock.Mock(return_value=io.BytesIO(SEP_TEXT.encode("utf-8")))
            with mock.patch.object(sys, "argv", argv), mock.patch.object(generate_sep_matrix, "urlopen", fetch), \
                    contextlib.redirect_stdout(io.StringIO()), \
                    self.assertLogs(generate_sep_matrix.logger, logging.ERROR) as logs:
                status = generate_sep_matrix.main()
            return status, output.exists(), "\n".join(logs.output), fetch

    def test_unreadable_sdk_version_exits_non_zero_before_any_request(self):
        for case, sdk_version in (("no Info.plist", None), ("empty version", " ")):
            with self.subTest(case):
                status, written, log, fetch = self.run_main("02", sdk_version, {})
                self.assertEqual(status, 1)
                self.assertFalse(written)
                self.assertIn("Info.plist", log)
                fetch.assert_not_called()

    def test_unreadable_sdk_file_exits_non_zero_naming_it(self):
        runs = {
            "file read by the class search": ("02", "federation/Federation.swift"),
            "file read from a source directory": ("51", "xdr_json/XdrJson.swift"),
        }
        for case, (sep, relative) in runs.items():
            with self.subTest(case):
                status, written, log, _ = self.run_main(sep, "3.12.0", {relative: b"\xff\xfe not utf-8"})
                self.assertEqual(status, 1)
                self.assertFalse(written)
                self.assertRegex(log, f"Cannot read .*{relative}")


class SEP29FeeBumpDetectionTest(unittest.TestCase):

    def fee_bump_field(self, service: str):
        """The fee_bump_inner_transaction field after the SEP-29 analyzer read this service text."""
        with tempfile.TemporaryDirectory() as tmp:
            sdk_root = Path(tmp) / "sdk"
            write_sdk_root(sdk_root, "3.12.0", {
                "service/TransactionsService.swift": service.encode("utf-8"),
                "xdr_helpers/TransactionEnvelopeXDR+Helpers.swift": SEP29_ENVELOPE_HELPERS.encode("utf-8"),
            })
            info = generate_sep_matrix.SEPInfo("29", "Account Memo Requirements", "", raw_content=SEP_TEXT)
            analyzer = generate_sep_matrix.SEP29Analyzer(generate_sep_matrix.SDKAnalyzer(sdk_root))
            with self.assertLogs(generate_sep_matrix.logger, logging.INFO):
                matrix = analyzer.analyze(info)
        section = next(s for s in matrix.sections if s.name == generate_sep_matrix.SEP29Analyzer.SECTION_CHECK)
        return next(f for f in section.fields if f.name == "fee_bump_inner_transaction")

    def test_memo_check_decoding_the_posted_envelope_marks_the_fee_bump_check(self):
        field = self.fee_bump_field(SEP29_SERVICE)
        self.assertTrue(field.implemented)
        self.assertEqual(field.sdk_property, "Transaction(envelopeXdr:) (fee bump inner transaction)")

    def test_service_without_the_envelope_decode_leaves_the_fee_bump_check_unmarked(self):
        field = self.fee_bump_field(SEP29_SERVICE.replace(SEP29_DECODE, "return nil"))
        self.assertFalse(field.implemented)
        self.assertIsNone(field.sdk_property)


class SEP51AddressDetectionTest(unittest.TestCase):

    def address_fields(self, generated: dict):
        """The SEP-51 Address Types fields by name after the analyzer read these generated XDR files."""
        with tempfile.TemporaryDirectory() as tmp:
            sdk_root = Path(tmp) / "sdk"
            write_sdk_root(sdk_root, "3.15.0", {
                f"responses/xdr/{name}": source.encode("utf-8") for name, source in generated.items()})
            info = generate_sep_matrix.SEPInfo("51", "XDR-JSON", "", raw_content=SEP_TEXT)
            analyzer = generate_sep_matrix.SEP51Analyzer(generate_sep_matrix.SDKAnalyzer(sdk_root))
            with self.assertLogs(generate_sep_matrix.logger, logging.INFO):
                matrix = analyzer.analyze(info)
        section = next(s for s in matrix.sections if s.name == "Address Types")
        return {field.name: field for field in section.fields}

    def test_w_case_and_muxed_contract_conversion_mark_both_rows(self):
        fields = self.address_fields({"SCAddressXDR.swift": SEP51_SC_ADDRESS,
                                      "MuxedContractXDR.swift": SEP51_MUXED_CONTRACT})
        self.assertIn("sc_address", fields)
        self.assertIn("muxed_contract", fields)
        self.assertTrue(fields["sc_address"].implemented)
        self.assertEqual(fields["sc_address"].sdk_property, "SCAddressXDR")
        self.assertTrue(fields["muxed_contract"].implemented)
        self.assertEqual(fields["muxed_contract"].sdk_property, "MuxedContractXDR")

    def test_sc_address_without_the_w_case_leaves_sc_address_unmarked(self):
        self.assertIn(SEP51_SC_ADDRESS_W_CASE, SEP51_SC_ADDRESS)
        fields = self.address_fields({"SCAddressXDR.swift": SEP51_SC_ADDRESS.replace(SEP51_SC_ADDRESS_W_CASE, ""),
                                      "MuxedContractXDR.swift": SEP51_MUXED_CONTRACT})
        self.assertFalse(fields["sc_address"].implemented)
        self.assertIsNone(fields["sc_address"].sdk_property)
        self.assertTrue(fields["muxed_contract"].implemented)

    def test_absent_muxed_contract_source_leaves_muxed_contract_unmarked(self):
        fields = self.address_fields({"SCAddressXDR.swift": SEP51_SC_ADDRESS})
        self.assertFalse(fields["muxed_contract"].implemented)
        self.assertIsNone(fields["muxed_contract"].sdk_property)
        self.assertTrue(fields["sc_address"].implemented)


if __name__ == "__main__":
    unittest.main()
