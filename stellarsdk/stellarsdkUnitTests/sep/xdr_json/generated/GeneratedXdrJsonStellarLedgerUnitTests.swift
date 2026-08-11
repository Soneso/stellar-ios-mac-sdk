//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It exercises
// the SEP-0051 (XDR-JSON) conversions of every type declared in one .x source. To
// regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import XCTest
import Foundation
import stellarsdk

final class GeneratedXdrJsonStellarLedgerUnitTests: XCTestCase {

    func test_ConfigUpgradeSetKeyXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigUpgradeSetKeyXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigUpgradeSetKeyXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigUpgradeSetKeyXDR_roundTrip() throws {
        let original: ConfigUpgradeSetKeyXDR = ConfigUpgradeSetKeyXDR(contractID: WrappedData32(Data(repeating: 0xAB, count: 32)), contentHash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigUpgradeSetKeyXDR.fromXdrJson(json)
        let viaValue = try ConfigUpgradeSetKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigUpgradeSetKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigUpgradeSetKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigUpgradeSetKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigUpgradeSetKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigUpgradeSetKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigUpgradeSetKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigUpgradeSetXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigUpgradeSetXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigUpgradeSetXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigUpgradeSetXDR_roundTrip() throws {
        let original: ConfigUpgradeSetXDR = ConfigUpgradeSetXDR(updatedEntry: [.contractMaxSizeBytes(UInt32(42))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigUpgradeSetXDR.fromXdrJson(json)
        let viaValue = try ConfigUpgradeSetXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigUpgradeSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigUpgradeSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigUpgradeSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigUpgradeSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigUpgradeSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigUpgradeSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractEventBodyV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractEventBodyV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractEventBodyV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractEventBodyV0XDR_roundTrip() throws {
        let original: ContractEventBodyV0XDR = ContractEventBodyV0XDR(topics: [.void], data: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractEventBodyV0XDR.fromXdrJson(json)
        let viaValue = try ContractEventBodyV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ContractEventBodyV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractEventBodyV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractEventBodyV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractEventBodyV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractEventBodyV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractEventBodyV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractEventBodyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ContractEventBodyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ContractEventBodyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ContractEventBodyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ContractEventBodyXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try ContractEventBodyXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ContractEventBodyXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractEventBodyXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ContractEventBodyXDR_v0_roundTrip() throws {
        let original: ContractEventBodyXDR = .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractEventBodyXDR.fromXdrJson(json)
        let viaValue = try ContractEventBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractEventBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractEventBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractEventBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractEventBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractEventBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractEventBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractEventType_CONTRACT() throws {
        let value: ContractEventType = .contract
        XCTAssertEqual(try value.toXdrJson(), "\"contract\"",
                       "ContractEventType.contract must render as contract")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ContractEventType.contract must keep its XDR value")
        XCTAssertEqual(try ContractEventType.fromXdrJson("\"contract\""), value,
                       "contract must read back as ContractEventType.contract")
    }

    func test_ContractEventType_DIAGNOSTIC() throws {
        let value: ContractEventType = .diagnostic
        XCTAssertEqual(try value.toXdrJson(), "\"diagnostic\"",
                       "ContractEventType.diagnostic must render as diagnostic")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ContractEventType.diagnostic must keep its XDR value")
        XCTAssertEqual(try ContractEventType.fromXdrJson("\"diagnostic\""), value,
                       "diagnostic must read back as ContractEventType.diagnostic")
    }

    func test_ContractEventType_SYSTEM() throws {
        let value: ContractEventType = .system
        XCTAssertEqual(try value.toXdrJson(), "\"system\"",
                       "ContractEventType.system must render as system")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ContractEventType.system must keep its XDR value")
        XCTAssertEqual(try ContractEventType.fromXdrJson("\"system\""), value,
                       "system must read back as ContractEventType.system")
    }

    func test_ContractEventType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ContractEventType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ContractEventType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractEventType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ContractEventXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractEventXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractEventXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractEventXDR_roundTrip() throws {
        let original: ContractEventXDR = ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractEventXDR.fromXdrJson(json)
        let viaValue = try ContractEventXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractEventXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractEventXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractEventXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractEventXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractEventXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractEventXDR must reach the same bytes through JSON and XDR")
    }

    func test_DependentTxClusterXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DependentTxClusterXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DependentTxClusterXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DependentTxClusterXDR_roundTrip() throws {
        let original: DependentTxClusterXDR = DependentTxClusterXDR(wrapped: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try DependentTxClusterXDR.fromXdrJson(json)
        let viaValue = try DependentTxClusterXDR.fromXdrJsonValue(tree)
        let viaTree = try DependentTxClusterXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "DependentTxClusterXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "DependentTxClusterXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "DependentTxClusterXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "DependentTxClusterXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "DependentTxClusterXDR must reach the same bytes through JSON and XDR")
    }

    func test_DiagnosticEventXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DiagnosticEventXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DiagnosticEventXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DiagnosticEventXDR_roundTrip() throws {
        let original: DiagnosticEventXDR = DiagnosticEventXDR(inSuccessfulContractCall: true, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try DiagnosticEventXDR.fromXdrJson(json)
        let viaValue = try DiagnosticEventXDR.fromXdrJsonValue(tree)
        let viaTree = try DiagnosticEventXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "DiagnosticEventXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "DiagnosticEventXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "DiagnosticEventXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "DiagnosticEventXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "DiagnosticEventXDR must reach the same bytes through JSON and XDR")
    }

    func test_GeneralizedTransactionSetXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try GeneralizedTransactionSetXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("GeneralizedTransactionSetXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "GeneralizedTransactionSetXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_GeneralizedTransactionSetXDR_v1TxSet_rejectsBareString() throws {
        XCTAssertThrowsError(try GeneralizedTransactionSetXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("GeneralizedTransactionSetXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "GeneralizedTransactionSetXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_GeneralizedTransactionSetXDR_v1TxSet_roundTrip() throws {
        let original: GeneralizedTransactionSetXDR = .v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try GeneralizedTransactionSetXDR.fromXdrJson(json)
        let viaValue = try GeneralizedTransactionSetXDR.fromXdrJsonValue(tree)
        let viaTree = try GeneralizedTransactionSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "GeneralizedTransactionSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "GeneralizedTransactionSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "GeneralizedTransactionSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "GeneralizedTransactionSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "GeneralizedTransactionSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionSuccessPreImageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try InvokeHostFunctionSuccessPreImageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "InvokeHostFunctionSuccessPreImageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_InvokeHostFunctionSuccessPreImageXDR_roundTrip() throws {
        let original: InvokeHostFunctionSuccessPreImageXDR = InvokeHostFunctionSuccessPreImageXDR(returnValue: .void, events: [ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionSuccessPreImageXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionSuccessPreImageXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionSuccessPreImageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionSuccessPreImageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionSuccessPreImageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionSuccessPreImageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionSuccessPreImageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionSuccessPreImageXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaExtV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerCloseMetaExtV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerCloseMetaExtV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerCloseMetaExtV1XDR_roundTrip() throws {
        let original: LedgerCloseMetaExtV1XDR = LedgerCloseMetaExtV1XDR(ext: .void, sorobanFeeWrite1KB: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaExtV1XDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaExtV1XDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaExtV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaExtV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaExtV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaExtV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaExtV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaExtV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerCloseMetaExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerCloseMetaExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerCloseMetaExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerCloseMetaExtXDR_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerCloseMetaExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerCloseMetaExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerCloseMetaExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerCloseMetaExtXDR_v1_roundTrip() throws {
        let original: LedgerCloseMetaExtXDR = .v1(LedgerCloseMetaExtV1XDR(ext: .void, sorobanFeeWrite1KB: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaExtXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaExtXDR_void_roundTrip() throws {
        let original: LedgerCloseMetaExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaExtXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerCloseMetaV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerCloseMetaV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerCloseMetaV0XDR_roundTrip() throws {
        let original: LedgerCloseMetaV0XDR = LedgerCloseMetaV0XDR(ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]), txProcessing: [TransactionResultMetaXDR(result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]))], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: [.v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaV0XDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaV0XDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerCloseMetaV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerCloseMetaV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerCloseMetaV1XDR_roundTrip() throws {
        let original: LedgerCloseMetaV1XDR = LedgerCloseMetaV1XDR(ext: .void, ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: .v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])), txProcessing: [TransactionResultMetaXDR(result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]))], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: [.v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))], totalByteSizeOfLiveSorobanState: UInt64(1234567), evictedKeys: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))], unused: [LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaV1XDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaV1XDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaV2XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerCloseMetaV2XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerCloseMetaV2XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerCloseMetaV2XDR_roundTrip() throws {
        let original: LedgerCloseMetaV2XDR = LedgerCloseMetaV2XDR(ext: .void, ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: .v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])), txProcessing: [TransactionResultMetaV1XDR(ext: .void, result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]), postTxApplyFeeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []))], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: [.v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))], totalByteSizeOfLiveSorobanState: UInt64(1234567), evictedKeys: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaV2XDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaV2XDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerCloseMetaXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerCloseMetaXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerCloseMetaXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerCloseMetaXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerCloseMetaXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerCloseMetaXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerCloseMetaXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerCloseMetaXDR_v0_roundTrip() throws {
        let original: LedgerCloseMetaXDR = .v0(LedgerCloseMetaV0XDR(ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]), txProcessing: [TransactionResultMetaXDR(result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]))], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: [.v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaXDR_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerCloseMetaXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerCloseMetaXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerCloseMetaXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerCloseMetaXDR_v1_roundTrip() throws {
        let original: LedgerCloseMetaXDR = .v1(LedgerCloseMetaV1XDR(ext: .void, ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: .v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])), txProcessing: [TransactionResultMetaXDR(result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]))], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: [.v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))], totalByteSizeOfLiveSorobanState: UInt64(1234567), evictedKeys: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))], unused: [LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void)]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseMetaXDR_v2_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerCloseMetaXDR.fromXdrJson("\"v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerCloseMetaXDR.v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerCloseMetaXDR")
            XCTAssertEqual(key, "v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerCloseMetaXDR_v2_roundTrip() throws {
        let original: LedgerCloseMetaXDR = .v2(LedgerCloseMetaV2XDR(ext: .void, ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: .v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])), txProcessing: [TransactionResultMetaV1XDR(ext: .void, result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]), postTxApplyFeeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []))], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: [.v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))], totalByteSizeOfLiveSorobanState: UInt64(1234567), evictedKeys: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerCloseValueSignatureXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerCloseValueSignatureXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerCloseValueSignatureXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerCloseValueSignatureXDR_roundTrip() throws {
        let original: LedgerCloseValueSignatureXDR = LedgerCloseValueSignatureXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signature: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseValueSignatureXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseValueSignatureXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseValueSignatureXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseValueSignatureXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseValueSignatureXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseValueSignatureXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseValueSignatureXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseValueSignatureXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryChangeType_LEDGER_ENTRY_CREATED() throws {
        let value: LedgerEntryChangeType = .ledgerEntryCreated
        XCTAssertEqual(try value.toXdrJson(), "\"created\"",
                       "LedgerEntryChangeType.ledgerEntryCreated must render as created")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "LedgerEntryChangeType.ledgerEntryCreated must keep its XDR value")
        XCTAssertEqual(try LedgerEntryChangeType.fromXdrJson("\"created\""), value,
                       "created must read back as LedgerEntryChangeType.ledgerEntryCreated")
    }

    func test_LedgerEntryChangeType_LEDGER_ENTRY_REMOVED() throws {
        let value: LedgerEntryChangeType = .ledgerEntryRemoved
        XCTAssertEqual(try value.toXdrJson(), "\"removed\"",
                       "LedgerEntryChangeType.ledgerEntryRemoved must render as removed")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "LedgerEntryChangeType.ledgerEntryRemoved must keep its XDR value")
        XCTAssertEqual(try LedgerEntryChangeType.fromXdrJson("\"removed\""), value,
                       "removed must read back as LedgerEntryChangeType.ledgerEntryRemoved")
    }

    func test_LedgerEntryChangeType_LEDGER_ENTRY_RESTORED() throws {
        let value: LedgerEntryChangeType = .ledgerEntryRestore
        XCTAssertEqual(try value.toXdrJson(), "\"restored\"",
                       "LedgerEntryChangeType.ledgerEntryRestore must render as restored")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "LedgerEntryChangeType.ledgerEntryRestore must keep its XDR value")
        XCTAssertEqual(try LedgerEntryChangeType.fromXdrJson("\"restored\""), value,
                       "restored must read back as LedgerEntryChangeType.ledgerEntryRestore")
    }

    func test_LedgerEntryChangeType_LEDGER_ENTRY_STATE() throws {
        let value: LedgerEntryChangeType = .ledgerEntryState
        XCTAssertEqual(try value.toXdrJson(), "\"state\"",
                       "LedgerEntryChangeType.ledgerEntryState must render as state")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "LedgerEntryChangeType.ledgerEntryState must keep its XDR value")
        XCTAssertEqual(try LedgerEntryChangeType.fromXdrJson("\"state\""), value,
                       "state must read back as LedgerEntryChangeType.ledgerEntryState")
    }

    func test_LedgerEntryChangeType_LEDGER_ENTRY_UPDATED() throws {
        let value: LedgerEntryChangeType = .ledgerEntryUpdated
        XCTAssertEqual(try value.toXdrJson(), "\"updated\"",
                       "LedgerEntryChangeType.ledgerEntryUpdated must render as updated")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "LedgerEntryChangeType.ledgerEntryUpdated must keep its XDR value")
        XCTAssertEqual(try LedgerEntryChangeType.fromXdrJson("\"updated\""), value,
                       "updated must read back as LedgerEntryChangeType.ledgerEntryUpdated")
    }

    func test_LedgerEntryChangeType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LedgerEntryChangeType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LedgerEntryChangeType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_LedgerEntryChangeXDR_created_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryChangeXDR.fromXdrJson("\"created\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryChangeXDR.created: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeXDR")
            XCTAssertEqual(key, "created",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryChangeXDR_created_roundTrip() throws {
        let original: LedgerEntryChangeXDR = .created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryChangeXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryChangeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryChangeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryChangeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryChangeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryChangeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryChangeXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerEntryChangeXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerEntryChangeXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerEntryChangeXDR_removed_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryChangeXDR.fromXdrJson("\"removed\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryChangeXDR.removed: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeXDR")
            XCTAssertEqual(key, "removed",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryChangeXDR_removed_roundTrip() throws {
        let original: LedgerEntryChangeXDR = .removed(.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryChangeXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryChangeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryChangeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryChangeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryChangeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryChangeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryChangeXDR_restored_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryChangeXDR.fromXdrJson("\"restored\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryChangeXDR.restored: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeXDR")
            XCTAssertEqual(key, "restored",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryChangeXDR_restored_roundTrip() throws {
        let original: LedgerEntryChangeXDR = .restored(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryChangeXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryChangeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryChangeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryChangeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryChangeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryChangeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryChangeXDR_state_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryChangeXDR.fromXdrJson("\"state\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryChangeXDR.state: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeXDR")
            XCTAssertEqual(key, "state",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryChangeXDR_state_roundTrip() throws {
        let original: LedgerEntryChangeXDR = .state(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryChangeXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryChangeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryChangeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryChangeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryChangeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryChangeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryChangeXDR_updated_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryChangeXDR.fromXdrJson("\"updated\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryChangeXDR.updated: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryChangeXDR")
            XCTAssertEqual(key, "updated",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryChangeXDR_updated_roundTrip() throws {
        let original: LedgerEntryChangeXDR = .updated(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryChangeXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryChangeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryChangeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryChangeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryChangeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryChangeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryChangeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryChangesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerEntryChangesXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerEntryChangesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerEntryChangesXDR_roundTrip() throws {
        let original: LedgerEntryChangesXDR = LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryChangesXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryChangesXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryChangesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryChangesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryChangesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryChangesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryChangesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryChangesXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderExtensionV1XDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerHeaderExtensionV1XDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerHeaderExtensionV1XDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerHeaderExtensionV1XDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerHeaderExtensionV1XDRExtXDR_void_roundTrip() throws {
        let original: LedgerHeaderExtensionV1XDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderExtensionV1XDRExtXDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderExtensionV1XDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderExtensionV1XDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderExtensionV1XDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderExtensionV1XDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderExtensionV1XDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderExtensionV1XDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderExtensionV1XDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderExtensionV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerHeaderExtensionV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerHeaderExtensionV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerHeaderExtensionV1XDR_roundTrip() throws {
        let original: LedgerHeaderExtensionV1XDR = LedgerHeaderExtensionV1XDR(flags: UInt32(42), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderExtensionV1XDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderExtensionV1XDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderExtensionV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderExtensionV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderExtensionV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderExtensionV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderExtensionV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderExtensionV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderFlagsXDR_DISABLE_LIQUIDITY_POOL_DEPOSIT_FLAG() throws {
        let value: LedgerHeaderFlagsXDR = .depositFlag
        XCTAssertEqual(try value.toXdrJson(), "\"deposit_flag\"",
                       "LedgerHeaderFlagsXDR.depositFlag must render as deposit_flag")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "LedgerHeaderFlagsXDR.depositFlag must keep its XDR value")
        XCTAssertEqual(try LedgerHeaderFlagsXDR.fromXdrJson("\"deposit_flag\""), value,
                       "deposit_flag must read back as LedgerHeaderFlagsXDR.depositFlag")
    }

    func test_LedgerHeaderFlagsXDR_DISABLE_LIQUIDITY_POOL_TRADING_FLAG() throws {
        let value: LedgerHeaderFlagsXDR = .tradingFlag
        XCTAssertEqual(try value.toXdrJson(), "\"trading_flag\"",
                       "LedgerHeaderFlagsXDR.tradingFlag must render as trading_flag")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "LedgerHeaderFlagsXDR.tradingFlag must keep its XDR value")
        XCTAssertEqual(try LedgerHeaderFlagsXDR.fromXdrJson("\"trading_flag\""), value,
                       "trading_flag must read back as LedgerHeaderFlagsXDR.tradingFlag")
    }

    func test_LedgerHeaderFlagsXDR_DISABLE_LIQUIDITY_POOL_WITHDRAWAL_FLAG() throws {
        let value: LedgerHeaderFlagsXDR = .withdrawalFlag
        XCTAssertEqual(try value.toXdrJson(), "\"withdrawal_flag\"",
                       "LedgerHeaderFlagsXDR.withdrawalFlag must render as withdrawal_flag")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "LedgerHeaderFlagsXDR.withdrawalFlag must keep its XDR value")
        XCTAssertEqual(try LedgerHeaderFlagsXDR.fromXdrJson("\"withdrawal_flag\""), value,
                       "withdrawal_flag must read back as LedgerHeaderFlagsXDR.withdrawalFlag")
    }

    func test_LedgerHeaderFlagsXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LedgerHeaderFlagsXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LedgerHeaderFlagsXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerHeaderFlagsXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_LedgerHeaderHistoryEntryXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerHeaderHistoryEntryXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerHeaderHistoryEntryXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerHeaderHistoryEntryXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerHeaderHistoryEntryXDRExtXDR_void_roundTrip() throws {
        let original: LedgerHeaderHistoryEntryXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderHistoryEntryXDRExtXDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderHistoryEntryXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderHistoryEntryXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderHistoryEntryXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderHistoryEntryXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderHistoryEntryXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderHistoryEntryXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderHistoryEntryXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderHistoryEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerHeaderHistoryEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerHeaderHistoryEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerHeaderHistoryEntryXDR_roundTrip() throws {
        let original: LedgerHeaderHistoryEntryXDR = LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderHistoryEntryXDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderHistoryEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderHistoryEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderHistoryEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderHistoryEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderHistoryEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderHistoryEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderHistoryEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerHeaderXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerHeaderXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerHeaderXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerHeaderXDRExtXDR_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerHeaderXDRExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerHeaderXDRExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerHeaderXDRExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerHeaderXDRExtXDR_v1_roundTrip() throws {
        let original: LedgerHeaderXDRExtXDR = .v1(LedgerHeaderExtensionV1XDR(flags: UInt32(42), ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderXDRExtXDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderXDRExtXDR_void_roundTrip() throws {
        let original: LedgerHeaderXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderXDRExtXDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerHeaderXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerHeaderXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerHeaderXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerHeaderXDR_roundTrip() throws {
        let original: LedgerHeaderXDR = LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerHeaderXDR.fromXdrJson(json)
        let viaValue = try LedgerHeaderXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerHeaderXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerHeaderXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerHeaderXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerHeaderXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerHeaderXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerHeaderXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerSCPMessagesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerSCPMessagesXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerSCPMessagesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerSCPMessagesXDR_roundTrip() throws {
        let original: LedgerSCPMessagesXDR = LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))), signature: Data([0x01, 0x02, 0x03]))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerSCPMessagesXDR.fromXdrJson(json)
        let viaValue = try LedgerSCPMessagesXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerSCPMessagesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerSCPMessagesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerSCPMessagesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerSCPMessagesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerSCPMessagesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerSCPMessagesXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_BASE_FEE() throws {
        let value: LedgerUpgradeTypeXDR = .baseFee
        XCTAssertEqual(try value.toXdrJson(), "\"base_fee\"",
                       "LedgerUpgradeTypeXDR.baseFee must render as base_fee")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "LedgerUpgradeTypeXDR.baseFee must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"base_fee\""), value,
                       "base_fee must read back as LedgerUpgradeTypeXDR.baseFee")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_BASE_RESERVE() throws {
        let value: LedgerUpgradeTypeXDR = .baseReserve
        XCTAssertEqual(try value.toXdrJson(), "\"base_reserve\"",
                       "LedgerUpgradeTypeXDR.baseReserve must render as base_reserve")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "LedgerUpgradeTypeXDR.baseReserve must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"base_reserve\""), value,
                       "base_reserve must read back as LedgerUpgradeTypeXDR.baseReserve")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_CONFIG() throws {
        let value: LedgerUpgradeTypeXDR = .config
        XCTAssertEqual(try value.toXdrJson(), "\"config\"",
                       "LedgerUpgradeTypeXDR.config must render as config")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "LedgerUpgradeTypeXDR.config must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"config\""), value,
                       "config must read back as LedgerUpgradeTypeXDR.config")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_FLAGS() throws {
        let value: LedgerUpgradeTypeXDR = .flags
        XCTAssertEqual(try value.toXdrJson(), "\"flags\"",
                       "LedgerUpgradeTypeXDR.flags must render as flags")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "LedgerUpgradeTypeXDR.flags must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"flags\""), value,
                       "flags must read back as LedgerUpgradeTypeXDR.flags")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE() throws {
        let value: LedgerUpgradeTypeXDR = .maxSorobanTxSetSize
        XCTAssertEqual(try value.toXdrJson(), "\"max_soroban_tx_set_size\"",
                       "LedgerUpgradeTypeXDR.maxSorobanTxSetSize must render as max_soroban_tx_set_size")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "LedgerUpgradeTypeXDR.maxSorobanTxSetSize must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"max_soroban_tx_set_size\""), value,
                       "max_soroban_tx_set_size must read back as LedgerUpgradeTypeXDR.maxSorobanTxSetSize")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_MAX_TX_SET_SIZE() throws {
        let value: LedgerUpgradeTypeXDR = .maxTxSetSize
        XCTAssertEqual(try value.toXdrJson(), "\"max_tx_set_size\"",
                       "LedgerUpgradeTypeXDR.maxTxSetSize must render as max_tx_set_size")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "LedgerUpgradeTypeXDR.maxTxSetSize must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"max_tx_set_size\""), value,
                       "max_tx_set_size must read back as LedgerUpgradeTypeXDR.maxTxSetSize")
    }

    func test_LedgerUpgradeTypeXDR_LEDGER_UPGRADE_VERSION() throws {
        let value: LedgerUpgradeTypeXDR = .version
        XCTAssertEqual(try value.toXdrJson(), "\"version\"",
                       "LedgerUpgradeTypeXDR.version must render as version")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "LedgerUpgradeTypeXDR.version must keep its XDR value")
        XCTAssertEqual(try LedgerUpgradeTypeXDR.fromXdrJson("\"version\""), value,
                       "version must read back as LedgerUpgradeTypeXDR.version")
    }

    func test_LedgerUpgradeTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LedgerUpgradeTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LedgerUpgradeTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_LedgerUpgradeXDR_newBaseFee_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"base_fee\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.base_fee: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "base_fee",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newBaseFee_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newBaseFee(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_newBaseReserve_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"base_reserve\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.base_reserve: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "base_reserve",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newBaseReserve_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newBaseReserve(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_newConfig_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"config\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.config: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "config",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newConfig_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newConfig(ConfigUpgradeSetKeyXDR(contractID: WrappedData32(Data(repeating: 0xAB, count: 32)), contentHash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_newFlags_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"flags\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.flags: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "flags",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newFlags_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newFlags(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_newLedgerVersion_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"version\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.version: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "version",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newLedgerVersion_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newLedgerVersion(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_newMaxSorobanTxSetSize_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"max_soroban_tx_set_size\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.max_soroban_tx_set_size: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "max_soroban_tx_set_size",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newMaxSorobanTxSetSize_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newMaxSorobanTxSetSize(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_newMaxTxSetSize_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"max_tx_set_size\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerUpgradeXDR.max_tx_set_size: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "max_tx_set_size",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerUpgradeXDR_newMaxTxSetSize_roundTrip() throws {
        let original: LedgerUpgradeXDR = .newMaxTxSetSize(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerUpgradeXDR.fromXdrJson(json)
        let viaValue = try LedgerUpgradeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerUpgradeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerUpgradeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerUpgradeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerUpgradeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerUpgradeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerUpgradeXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerUpgradeXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerUpgradeXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerUpgradeXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_OperationMetaV2XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try OperationMetaV2XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "OperationMetaV2XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_OperationMetaV2XDR_roundTrip() throws {
        let original: OperationMetaV2XDR = OperationMetaV2XDR(ext: .void, changes: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), events: [ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationMetaV2XDR.fromXdrJson(json)
        let viaValue = try OperationMetaV2XDR.fromXdrJsonValue(tree)
        let viaTree = try OperationMetaV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationMetaV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationMetaV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationMetaV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationMetaV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationMetaV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationMetaXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try OperationMetaXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "OperationMetaXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_OperationMetaXDR_roundTrip() throws {
        let original: OperationMetaXDR = OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationMetaXDR.fromXdrJson(json)
        let viaValue = try OperationMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_ParallelTxExecutionStageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ParallelTxExecutionStageXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ParallelTxExecutionStageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ParallelTxExecutionStageXDR_roundTrip() throws {
        let original: ParallelTxExecutionStageXDR = ParallelTxExecutionStageXDR(wrapped: [DependentTxClusterXDR(wrapped: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ParallelTxExecutionStageXDR.fromXdrJson(json)
        let viaValue = try ParallelTxExecutionStageXDR.fromXdrJsonValue(tree)
        let viaTree = try ParallelTxExecutionStageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ParallelTxExecutionStageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ParallelTxExecutionStageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ParallelTxExecutionStageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ParallelTxExecutionStageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ParallelTxExecutionStageXDR must reach the same bytes through JSON and XDR")
    }

    func test_ParallelTxsComponentXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ParallelTxsComponentXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ParallelTxsComponentXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ParallelTxsComponentXDR_roundTrip() throws {
        let original: ParallelTxsComponentXDR = ParallelTxsComponentXDR(baseFee: Int64(1234567), executionStages: [ParallelTxExecutionStageXDR(wrapped: [DependentTxClusterXDR(wrapped: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ParallelTxsComponentXDR.fromXdrJson(json)
        let viaValue = try ParallelTxsComponentXDR.fromXdrJsonValue(tree)
        let viaTree = try ParallelTxsComponentXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ParallelTxsComponentXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ParallelTxsComponentXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ParallelTxsComponentXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ParallelTxsComponentXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ParallelTxsComponentXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPHistoryEntryV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPHistoryEntryV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPHistoryEntryV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPHistoryEntryV0XDR_roundTrip() throws {
        let original: SCPHistoryEntryV0XDR = SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))), signature: Data([0x01, 0x02, 0x03]))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPHistoryEntryV0XDR.fromXdrJson(json)
        let viaValue = try SCPHistoryEntryV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCPHistoryEntryV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPHistoryEntryV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPHistoryEntryV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPHistoryEntryV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPHistoryEntryV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPHistoryEntryV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPHistoryEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCPHistoryEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCPHistoryEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCPHistoryEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCPHistoryEntryXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCPHistoryEntryXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCPHistoryEntryXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCPHistoryEntryXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCPHistoryEntryXDR_v0_roundTrip() throws {
        let original: SCPHistoryEntryXDR = .v0(SCPHistoryEntryV0XDR(quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])], ledgerMessages: LedgerSCPMessagesXDR(ledgerSeq: UInt32(42), messages: [])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPHistoryEntryXDR.fromXdrJson(json)
        let viaValue = try SCPHistoryEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPHistoryEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPHistoryEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPHistoryEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPHistoryEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPHistoryEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPHistoryEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanTransactionMetaExtV1_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanTransactionMetaExtV1.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanTransactionMetaExtV1 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanTransactionMetaExtV1_roundTrip() throws {
        let original: SorobanTransactionMetaExtV1 = SorobanTransactionMetaExtV1(ext: .void, totalNonRefundableResourceFeeCharged: Int64(1234567), totalRefundableResourceFeeCharged: Int64(1234567), rentFeeCharged: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanTransactionMetaExtV1.fromXdrJson(json)
        let viaValue = try SorobanTransactionMetaExtV1.fromXdrJsonValue(tree)
        let viaTree = try SorobanTransactionMetaExtV1.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanTransactionMetaExtV1 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanTransactionMetaExtV1 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanTransactionMetaExtV1 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanTransactionMetaExtV1 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanTransactionMetaExtV1 must reach the same bytes through JSON and XDR")
    }

    func test_SorobanTransactionMetaExt_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SorobanTransactionMetaExt.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SorobanTransactionMetaExt: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SorobanTransactionMetaExt")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SorobanTransactionMetaExt_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanTransactionMetaExt.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanTransactionMetaExt.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanTransactionMetaExt")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanTransactionMetaExt_v1_roundTrip() throws {
        let original: SorobanTransactionMetaExt = .v1(SorobanTransactionMetaExtV1(ext: .void, totalNonRefundableResourceFeeCharged: Int64(1234567), totalRefundableResourceFeeCharged: Int64(1234567), rentFeeCharged: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanTransactionMetaExt.fromXdrJson(json)
        let viaValue = try SorobanTransactionMetaExt.fromXdrJsonValue(tree)
        let viaTree = try SorobanTransactionMetaExt.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanTransactionMetaExt must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanTransactionMetaExt must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanTransactionMetaExt must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanTransactionMetaExt must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanTransactionMetaExt must reach the same bytes through JSON and XDR")
    }

    func test_SorobanTransactionMetaExt_void_roundTrip() throws {
        let original: SorobanTransactionMetaExt = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanTransactionMetaExt.fromXdrJson(json)
        let viaValue = try SorobanTransactionMetaExt.fromXdrJsonValue(tree)
        let viaTree = try SorobanTransactionMetaExt.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanTransactionMetaExt must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanTransactionMetaExt must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanTransactionMetaExt must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanTransactionMetaExt must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanTransactionMetaExt must reach the same bytes through JSON and XDR")
    }

    func test_SorobanTransactionMetaV2XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanTransactionMetaV2XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanTransactionMetaV2XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanTransactionMetaV2XDR_roundTrip() throws {
        let original: SorobanTransactionMetaV2XDR = SorobanTransactionMetaV2XDR(ext: .void, returnValue: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanTransactionMetaV2XDR.fromXdrJson(json)
        let viaValue = try SorobanTransactionMetaV2XDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanTransactionMetaV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanTransactionMetaV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanTransactionMetaV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanTransactionMetaV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanTransactionMetaV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanTransactionMetaV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanTransactionMetaXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanTransactionMetaXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanTransactionMetaXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanTransactionMetaXDR_roundTrip() throws {
        let original: SorobanTransactionMetaXDR = SorobanTransactionMetaXDR(ext: .void, events: [ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))], returnValue: .void, diagnosticEvents: [DiagnosticEventXDR(inSuccessfulContractCall: true, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanTransactionMetaXDR.fromXdrJson(json)
        let viaValue = try SorobanTransactionMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanTransactionMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanTransactionMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanTransactionMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanTransactionMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanTransactionMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanTransactionMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarValueTypeXDR_STELLAR_VALUE_BASIC() throws {
        let value: StellarValueTypeXDR = .basic
        XCTAssertEqual(try value.toXdrJson(), "\"basic\"",
                       "StellarValueTypeXDR.basic must render as basic")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "StellarValueTypeXDR.basic must keep its XDR value")
        XCTAssertEqual(try StellarValueTypeXDR.fromXdrJson("\"basic\""), value,
                       "basic must read back as StellarValueTypeXDR.basic")
    }

    func test_StellarValueTypeXDR_STELLAR_VALUE_EMPTY_TX_SET() throws {
        let value: StellarValueTypeXDR = .emptyTxSet
        XCTAssertEqual(try value.toXdrJson(), "\"empty_tx_set\"",
                       "StellarValueTypeXDR.emptyTxSet must render as empty_tx_set")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "StellarValueTypeXDR.emptyTxSet must keep its XDR value")
        XCTAssertEqual(try StellarValueTypeXDR.fromXdrJson("\"empty_tx_set\""), value,
                       "empty_tx_set must read back as StellarValueTypeXDR.emptyTxSet")
    }

    func test_StellarValueTypeXDR_STELLAR_VALUE_SIGNED() throws {
        let value: StellarValueTypeXDR = .signed
        XCTAssertEqual(try value.toXdrJson(), "\"signed\"",
                       "StellarValueTypeXDR.signed must render as signed")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "StellarValueTypeXDR.signed must keep its XDR value")
        XCTAssertEqual(try StellarValueTypeXDR.fromXdrJson("\"signed\""), value,
                       "signed must read back as StellarValueTypeXDR.signed")
    }

    func test_StellarValueTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try StellarValueTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("StellarValueTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarValueTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_StellarValueXDRExtXDR_basic_roundTrip() throws {
        let original: StellarValueXDRExtXDR = .basic
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarValueXDRExtXDR.fromXdrJson(json)
        let viaValue = try StellarValueXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarValueXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarValueXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarValueXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarValueXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarValueXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarValueXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarValueXDRExtXDR_lcValueSignature_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarValueXDRExtXDR.fromXdrJson("\"signed\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarValueXDRExtXDR.signed: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarValueXDRExtXDR")
            XCTAssertEqual(key, "signed",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarValueXDRExtXDR_lcValueSignature_roundTrip() throws {
        let original: StellarValueXDRExtXDR = .lcValueSignature(LedgerCloseValueSignatureXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signature: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarValueXDRExtXDR.fromXdrJson(json)
        let viaValue = try StellarValueXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarValueXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarValueXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarValueXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarValueXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarValueXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarValueXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarValueXDRExtXDR_proposedValue_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarValueXDRExtXDR.fromXdrJson("\"empty_tx_set\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarValueXDRExtXDR.empty_tx_set: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarValueXDRExtXDR")
            XCTAssertEqual(key, "empty_tx_set",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarValueXDRExtXDR_proposedValue_roundTrip() throws {
        let original: StellarValueXDRExtXDR = .proposedValue(StellarValueXDRProposedValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), previousLedgerVersion: UInt32(42), lcValueSignature: LedgerCloseValueSignatureXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signature: Data([0x01, 0x02, 0x03]))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarValueXDRExtXDR.fromXdrJson(json)
        let viaValue = try StellarValueXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarValueXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarValueXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarValueXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarValueXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarValueXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarValueXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarValueXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try StellarValueXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("StellarValueXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "StellarValueXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_StellarValueXDRProposedValueXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try StellarValueXDRProposedValueXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "StellarValueXDRProposedValueXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_StellarValueXDRProposedValueXDR_roundTrip() throws {
        let original: StellarValueXDRProposedValueXDR = StellarValueXDRProposedValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), previousLedgerVersion: UInt32(42), lcValueSignature: LedgerCloseValueSignatureXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signature: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarValueXDRProposedValueXDR.fromXdrJson(json)
        let viaValue = try StellarValueXDRProposedValueXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarValueXDRProposedValueXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarValueXDRProposedValueXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarValueXDRProposedValueXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarValueXDRProposedValueXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarValueXDRProposedValueXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarValueXDRProposedValueXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarValueXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try StellarValueXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "StellarValueXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_StellarValueXDR_roundTrip() throws {
        let original: StellarValueXDR = StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarValueXDR.fromXdrJson(json)
        let viaValue = try StellarValueXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarValueXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarValueXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarValueXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarValueXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarValueXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarValueXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionEventStage_TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS() throws {
        let value: TransactionEventStage = .afterAllTx
        XCTAssertEqual(try value.toXdrJson(), "\"after_all_txs\"",
                       "TransactionEventStage.afterAllTx must render as after_all_txs")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "TransactionEventStage.afterAllTx must keep its XDR value")
        XCTAssertEqual(try TransactionEventStage.fromXdrJson("\"after_all_txs\""), value,
                       "after_all_txs must read back as TransactionEventStage.afterAllTx")
    }

    func test_TransactionEventStage_TRANSACTION_EVENT_STAGE_AFTER_TX() throws {
        let value: TransactionEventStage = .afterTx
        XCTAssertEqual(try value.toXdrJson(), "\"after_tx\"",
                       "TransactionEventStage.afterTx must render as after_tx")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "TransactionEventStage.afterTx must keep its XDR value")
        XCTAssertEqual(try TransactionEventStage.fromXdrJson("\"after_tx\""), value,
                       "after_tx must read back as TransactionEventStage.afterTx")
    }

    func test_TransactionEventStage_TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS() throws {
        let value: TransactionEventStage = .beforeAllTxs
        XCTAssertEqual(try value.toXdrJson(), "\"before_all_txs\"",
                       "TransactionEventStage.beforeAllTxs must render as before_all_txs")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "TransactionEventStage.beforeAllTxs must keep its XDR value")
        XCTAssertEqual(try TransactionEventStage.fromXdrJson("\"before_all_txs\""), value,
                       "before_all_txs must read back as TransactionEventStage.beforeAllTxs")
    }

    func test_TransactionEventStage_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try TransactionEventStage.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("TransactionEventStage: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionEventStage")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_TransactionEventXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionEventXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionEventXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionEventXDR_roundTrip() throws {
        let original: TransactionEventXDR = TransactionEventXDR(stage: .beforeAllTxs, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionEventXDR.fromXdrJson(json)
        let viaValue = try TransactionEventXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionEventXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionEventXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionEventXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionEventXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionEventXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionEventXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionHistoryEntryXDRExtXDR_generalizedTxSet_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionHistoryEntryXDRExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionHistoryEntryXDRExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionHistoryEntryXDRExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionHistoryEntryXDRExtXDR_generalizedTxSet_roundTrip() throws {
        let original: TransactionHistoryEntryXDRExtXDR = .generalizedTxSet(.v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionHistoryEntryXDRExtXDR.fromXdrJson(json)
        let viaValue = try TransactionHistoryEntryXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionHistoryEntryXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionHistoryEntryXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionHistoryEntryXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionHistoryEntryXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionHistoryEntryXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionHistoryEntryXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionHistoryEntryXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionHistoryEntryXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionHistoryEntryXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionHistoryEntryXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionHistoryEntryXDRExtXDR_void_roundTrip() throws {
        let original: TransactionHistoryEntryXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionHistoryEntryXDRExtXDR.fromXdrJson(json)
        let viaValue = try TransactionHistoryEntryXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionHistoryEntryXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionHistoryEntryXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionHistoryEntryXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionHistoryEntryXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionHistoryEntryXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionHistoryEntryXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionHistoryEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionHistoryEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionHistoryEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionHistoryEntryXDR_roundTrip() throws {
        let original: TransactionHistoryEntryXDR = TransactionHistoryEntryXDR(ledgerSeq: UInt32(42), txSet: TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionHistoryEntryXDR.fromXdrJson(json)
        let viaValue = try TransactionHistoryEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionHistoryEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionHistoryEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionHistoryEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionHistoryEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionHistoryEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionHistoryEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionHistoryResultEntryXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionHistoryResultEntryXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionHistoryResultEntryXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionHistoryResultEntryXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionHistoryResultEntryXDRExtXDR_void_roundTrip() throws {
        let original: TransactionHistoryResultEntryXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionHistoryResultEntryXDRExtXDR.fromXdrJson(json)
        let viaValue = try TransactionHistoryResultEntryXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionHistoryResultEntryXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionHistoryResultEntryXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionHistoryResultEntryXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionHistoryResultEntryXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionHistoryResultEntryXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionHistoryResultEntryXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionHistoryResultEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionHistoryResultEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionHistoryResultEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionHistoryResultEntryXDR_roundTrip() throws {
        let original: TransactionHistoryResultEntryXDR = TransactionHistoryResultEntryXDR(ledgerSeq: UInt32(42), txResultSet: TransactionResultSetXDR(results: [TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void))]), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionHistoryResultEntryXDR.fromXdrJson(json)
        let viaValue = try TransactionHistoryResultEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionHistoryResultEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionHistoryResultEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionHistoryResultEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionHistoryResultEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionHistoryResultEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionHistoryResultEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionMetaV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionMetaV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionMetaV1XDR_roundTrip() throws {
        let original: TransactionMetaV1XDR = TransactionMetaV1XDR(txChanges: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), operations: [OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaV1XDR.fromXdrJson(json)
        let viaValue = try TransactionMetaV1XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaV2XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionMetaV2XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionMetaV2XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionMetaV2XDR_roundTrip() throws {
        let original: TransactionMetaV2XDR = TransactionMetaV2XDR(txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), operations: [OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaV2XDR.fromXdrJson(json)
        let viaValue = try TransactionMetaV2XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaV3XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionMetaV3XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionMetaV3XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionMetaV3XDR_roundTrip() throws {
        let original: TransactionMetaV3XDR = TransactionMetaV3XDR(ext: .void, txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), operations: [OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), sorobanMeta: SorobanTransactionMetaXDR(ext: .void, events: [ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))], returnValue: .void, diagnosticEvents: [DiagnosticEventXDR(inSuccessfulContractCall: true, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaV3XDR.fromXdrJson(json)
        let viaValue = try TransactionMetaV3XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaV3XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaV3XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaV3XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaV3XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaV3XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaV3XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaV4XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionMetaV4XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionMetaV4XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionMetaV4XDR_roundTrip() throws {
        let original: TransactionMetaV4XDR = TransactionMetaV4XDR(ext: .void, txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), operations: [OperationMetaV2XDR(ext: .void, changes: LedgerEntryChangesXDR(LedgerEntryChanges: []), events: [ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))])], txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), sorobanMeta: SorobanTransactionMetaV2XDR(ext: .void, returnValue: .void), events: [TransactionEventXDR(stage: .beforeAllTxs, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))], diagnosticEvents: [DiagnosticEventXDR(inSuccessfulContractCall: true, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaV4XDR.fromXdrJson(json)
        let viaValue = try TransactionMetaV4XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaV4XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaV4XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaV4XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaV4XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaV4XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaV4XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaXDR_operations_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionMetaXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionMetaXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionMetaXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionMetaXDR_operations_roundTrip() throws {
        let original: TransactionMetaXDR = .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaXDR.fromXdrJson(json)
        let viaValue = try TransactionMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionMetaXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionMetaXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionMetaXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionMetaXDR_transactionMetaV1_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionMetaXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionMetaXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionMetaXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionMetaXDR_transactionMetaV1_roundTrip() throws {
        let original: TransactionMetaXDR = .transactionMetaV1(TransactionMetaV1XDR(txChanges: LedgerEntryChangesXDR(LedgerEntryChanges: []), operations: [OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaXDR.fromXdrJson(json)
        let viaValue = try TransactionMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaXDR_transactionMetaV2_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionMetaXDR.fromXdrJson("\"v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionMetaXDR.v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionMetaXDR")
            XCTAssertEqual(key, "v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionMetaXDR_transactionMetaV2_roundTrip() throws {
        let original: TransactionMetaXDR = .transactionMetaV2(TransactionMetaV2XDR(txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []), operations: [OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaXDR.fromXdrJson(json)
        let viaValue = try TransactionMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaXDR_transactionMetaV3_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionMetaXDR.fromXdrJson("\"v3\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionMetaXDR.v3: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionMetaXDR")
            XCTAssertEqual(key, "v3",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionMetaXDR_transactionMetaV3_roundTrip() throws {
        let original: TransactionMetaXDR = .transactionMetaV3(TransactionMetaV3XDR(ext: .void, txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []), operations: [OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []), sorobanMeta: SorobanTransactionMetaXDR(ext: .void, events: [ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void)))], returnValue: .void, diagnosticEvents: [])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaXDR.fromXdrJson(json)
        let viaValue = try TransactionMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionMetaXDR_transactionMetaV4_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionMetaXDR.fromXdrJson("\"v4\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionMetaXDR.v4: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionMetaXDR")
            XCTAssertEqual(key, "v4",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionMetaXDR_transactionMetaV4_roundTrip() throws {
        let original: TransactionMetaXDR = .transactionMetaV4(TransactionMetaV4XDR(ext: .void, txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []), operations: [OperationMetaV2XDR(ext: .void, changes: LedgerEntryChangesXDR(LedgerEntryChanges: []), events: [])], txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []), sorobanMeta: SorobanTransactionMetaV2XDR(ext: .void, returnValue: .void), events: [TransactionEventXDR(stage: .beforeAllTxs, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))], diagnosticEvents: [DiagnosticEventXDR(inSuccessfulContractCall: true, event: ContractEventXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), type: Int32(0), body: .v0(ContractEventBodyV0XDR(topics: [.void], data: .void))))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionMetaXDR.fromXdrJson(json)
        let viaValue = try TransactionMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionPhaseXDR_parallelTxsComponent_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionPhaseXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionPhaseXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionPhaseXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionPhaseXDR_parallelTxsComponent_roundTrip() throws {
        let original: TransactionPhaseXDR = .parallelTxsComponent(ParallelTxsComponentXDR(baseFee: Int64(1234567), executionStages: [ParallelTxExecutionStageXDR(wrapped: [DependentTxClusterXDR(wrapped: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionPhaseXDR.fromXdrJson(json)
        let viaValue = try TransactionPhaseXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionPhaseXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionPhaseXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionPhaseXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionPhaseXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionPhaseXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionPhaseXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionPhaseXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionPhaseXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionPhaseXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionPhaseXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionPhaseXDR_v0Components_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionPhaseXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionPhaseXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionPhaseXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionPhaseXDR_v0Components_roundTrip() throws {
        let original: TransactionPhaseXDR = .v0Components([.txsMaybeDiscountedFee(TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: Int64(1234567), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionPhaseXDR.fromXdrJson(json)
        let viaValue = try TransactionPhaseXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionPhaseXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionPhaseXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionPhaseXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionPhaseXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionPhaseXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionPhaseXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultMetaV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionResultMetaV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionResultMetaV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionResultMetaV1XDR_roundTrip() throws {
        let original: TransactionResultMetaV1XDR = TransactionResultMetaV1XDR(ext: .void, result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]), postTxApplyFeeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultMetaV1XDR.fromXdrJson(json)
        let viaValue = try TransactionResultMetaV1XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultMetaV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultMetaV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultMetaV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultMetaV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultMetaV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultMetaV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultMetaXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionResultMetaXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionResultMetaXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionResultMetaXDR_roundTrip() throws {
        let original: TransactionResultMetaXDR = TransactionResultMetaXDR(result: TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)), feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]), txApplyProcessing: .operations([OperationMetaXDR(changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultMetaXDR.fromXdrJson(json)
        let viaValue = try TransactionResultMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultPairXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionResultPairXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionResultPairXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionResultPairXDR_roundTrip() throws {
        let original: TransactionResultPairXDR = TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultPairXDR.fromXdrJson(json)
        let viaValue = try TransactionResultPairXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultPairXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultPairXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultPairXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultPairXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultPairXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultPairXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultSetXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionResultSetXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionResultSetXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionResultSetXDR_roundTrip() throws {
        let original: TransactionResultSetXDR = TransactionResultSetXDR(results: [TransactionResultPairXDR(transactionHash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultSetXDR.fromXdrJson(json)
        let viaValue = try TransactionResultSetXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionSetV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionSetV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionSetV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionSetV1XDR_roundTrip() throws {
        let original: TransactionSetV1XDR = TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([.txsMaybeDiscountedFee(TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: Int64(1234567), txs: []))])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionSetV1XDR.fromXdrJson(json)
        let viaValue = try TransactionSetV1XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionSetV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionSetV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionSetV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionSetV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionSetV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionSetV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionSetXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionSetXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionSetXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionSetXDR_roundTrip() throws {
        let original: TransactionSetXDR = TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionSetXDR.fromXdrJson(json)
        let viaValue = try TransactionSetXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_TxSetComponentTypeXDR_TXSET_COMP_TXS_MAYBE_DISCOUNTED_FEE() throws {
        let value: TxSetComponentTypeXDR = .txsetCompTxsMaybeDiscountedFee
        XCTAssertEqual(try value.toXdrJson(), "\"txset_comp_txs_maybe_discounted_fee\"",
                       "TxSetComponentTypeXDR.txsetCompTxsMaybeDiscountedFee must render as txset_comp_txs_maybe_discounted_fee")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "TxSetComponentTypeXDR.txsetCompTxsMaybeDiscountedFee must keep its XDR value")
        XCTAssertEqual(try TxSetComponentTypeXDR.fromXdrJson("\"txset_comp_txs_maybe_discounted_fee\""), value,
                       "txset_comp_txs_maybe_discounted_fee must read back as TxSetComponentTypeXDR.txsetCompTxsMaybeDiscountedFee")
    }

    func test_TxSetComponentTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try TxSetComponentTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("TxSetComponentTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "TxSetComponentTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_TxSetComponentXDRTxsMaybeDiscountedFeeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TxSetComponentXDRTxsMaybeDiscountedFeeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TxSetComponentXDRTxsMaybeDiscountedFeeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TxSetComponentXDRTxsMaybeDiscountedFeeXDR_roundTrip() throws {
        let original: TxSetComponentXDRTxsMaybeDiscountedFeeXDR = TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: Int64(1234567), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TxSetComponentXDRTxsMaybeDiscountedFeeXDR.fromXdrJson(json)
        let viaValue = try TxSetComponentXDRTxsMaybeDiscountedFeeXDR.fromXdrJsonValue(tree)
        let viaTree = try TxSetComponentXDRTxsMaybeDiscountedFeeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TxSetComponentXDRTxsMaybeDiscountedFeeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TxSetComponentXDRTxsMaybeDiscountedFeeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TxSetComponentXDRTxsMaybeDiscountedFeeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TxSetComponentXDRTxsMaybeDiscountedFeeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TxSetComponentXDRTxsMaybeDiscountedFeeXDR must reach the same bytes through JSON and XDR")
    }

    func test_TxSetComponentXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TxSetComponentXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TxSetComponentXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TxSetComponentXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TxSetComponentXDR_txsMaybeDiscountedFee_rejectsBareString() throws {
        XCTAssertThrowsError(try TxSetComponentXDR.fromXdrJson("\"txset_comp_txs_maybe_discounted_fee\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TxSetComponentXDR.txset_comp_txs_maybe_discounted_fee: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TxSetComponentXDR")
            XCTAssertEqual(key, "txset_comp_txs_maybe_discounted_fee",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TxSetComponentXDR_txsMaybeDiscountedFee_roundTrip() throws {
        let original: TxSetComponentXDR = .txsMaybeDiscountedFee(TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: Int64(1234567), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TxSetComponentXDR.fromXdrJson(json)
        let viaValue = try TxSetComponentXDR.fromXdrJsonValue(tree)
        let viaTree = try TxSetComponentXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TxSetComponentXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TxSetComponentXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TxSetComponentXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TxSetComponentXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TxSetComponentXDR must reach the same bytes through JSON and XDR")
    }

    func test_UpgradeEntryMetaXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try UpgradeEntryMetaXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "UpgradeEntryMetaXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_UpgradeEntryMetaXDR_roundTrip() throws {
        let original: UpgradeEntryMetaXDR = UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: [.created(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))), reserved: .void))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try UpgradeEntryMetaXDR.fromXdrJson(json)
        let viaValue = try UpgradeEntryMetaXDR.fromXdrJsonValue(tree)
        let viaTree = try UpgradeEntryMetaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "UpgradeEntryMetaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "UpgradeEntryMetaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "UpgradeEntryMetaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "UpgradeEntryMetaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "UpgradeEntryMetaXDR must reach the same bytes through JSON and XDR")
    }

    func test_UpgradeTypeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try UpgradeTypeXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "UpgradeTypeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_UpgradeTypeXDR_roundTrip() throws {
        let original: UpgradeTypeXDR = Data([0x01, 0x02, 0x03])
        let tree = try UpgradeTypeXDRJsonCodec.toXdrJsonValue(original)
        let json = try UpgradeTypeXDRJsonCodec.toXdrJson(original)
        let decoded = try UpgradeTypeXDRJsonCodec.fromXdrJson(json)
        let viaValue = try UpgradeTypeXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try UpgradeTypeXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try UpgradeTypeXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "UpgradeTypeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try UpgradeTypeXDRJsonCodec.toXdrJson(decoded), json,
                       "UpgradeTypeXDR must produce the same text after a round trip")
        XCTAssertEqual(try UpgradeTypeXDRJsonCodec.toXdrJson(viaValue), json,
                       "UpgradeTypeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try UpgradeTypeXDRJsonCodec.toXdrJson(viaTree), json,
                       "UpgradeTypeXDR must read a depth-checked tree the same way")
    }
}
