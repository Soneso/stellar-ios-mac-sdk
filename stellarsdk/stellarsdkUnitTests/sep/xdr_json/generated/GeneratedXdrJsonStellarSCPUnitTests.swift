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

final class GeneratedXdrJsonStellarSCPUnitTests: XCTestCase {

    func test_SCPBallotXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPBallotXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPBallotXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPBallotXDR_roundTrip() throws {
        let original: SCPBallotXDR = SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPBallotXDR.fromXdrJson(json)
        let viaValue = try SCPBallotXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPBallotXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPBallotXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPBallotXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPBallotXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPBallotXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPBallotXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPEnvelopeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPEnvelopeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPEnvelopeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPEnvelopeXDR_roundTrip() throws {
        let original: SCPEnvelopeXDR = SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))), signature: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPEnvelopeXDR.fromXdrJson(json)
        let viaValue = try SCPEnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPEnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPEnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPEnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPEnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPEnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPEnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPNominationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPNominationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPNominationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPNominationXDR_roundTrip() throws {
        let original: SCPNominationXDR = SCPNominationXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), votes: [Data([0x01, 0x02, 0x03])], accepted: [Data([0x01, 0x02, 0x03])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPNominationXDR.fromXdrJson(json)
        let viaValue = try SCPNominationXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPNominationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPNominationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPNominationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPNominationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPNominationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPNominationXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPQuorumSetXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPQuorumSetXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPQuorumSetXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPQuorumSetXDR_roundTrip() throws {
        let original: SCPQuorumSetXDR = SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPQuorumSetXDR.fromXdrJson(json)
        let viaValue = try SCPQuorumSetXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPQuorumSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPQuorumSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPQuorumSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPQuorumSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPQuorumSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPQuorumSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementTypeXDR_SCP_ST_CONFIRM() throws {
        let value: SCPStatementTypeXDR = .confirm
        XCTAssertEqual(try value.toXdrJson(), "\"confirm\"",
                       "SCPStatementTypeXDR.confirm must render as confirm")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCPStatementTypeXDR.confirm must keep its XDR value")
        XCTAssertEqual(try SCPStatementTypeXDR.fromXdrJson("\"confirm\""), value,
                       "confirm must read back as SCPStatementTypeXDR.confirm")
    }

    func test_SCPStatementTypeXDR_SCP_ST_EXTERNALIZE() throws {
        let value: SCPStatementTypeXDR = .externalize
        XCTAssertEqual(try value.toXdrJson(), "\"externalize\"",
                       "SCPStatementTypeXDR.externalize must render as externalize")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCPStatementTypeXDR.externalize must keep its XDR value")
        XCTAssertEqual(try SCPStatementTypeXDR.fromXdrJson("\"externalize\""), value,
                       "externalize must read back as SCPStatementTypeXDR.externalize")
    }

    func test_SCPStatementTypeXDR_SCP_ST_NOMINATE() throws {
        let value: SCPStatementTypeXDR = .nominate
        XCTAssertEqual(try value.toXdrJson(), "\"nominate\"",
                       "SCPStatementTypeXDR.nominate must render as nominate")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCPStatementTypeXDR.nominate must keep its XDR value")
        XCTAssertEqual(try SCPStatementTypeXDR.fromXdrJson("\"nominate\""), value,
                       "nominate must read back as SCPStatementTypeXDR.nominate")
    }

    func test_SCPStatementTypeXDR_SCP_ST_PREPARE() throws {
        let value: SCPStatementTypeXDR = .prepare
        XCTAssertEqual(try value.toXdrJson(), "\"prepare\"",
                       "SCPStatementTypeXDR.prepare must render as prepare")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCPStatementTypeXDR.prepare must keep its XDR value")
        XCTAssertEqual(try SCPStatementTypeXDR.fromXdrJson("\"prepare\""), value,
                       "prepare must read back as SCPStatementTypeXDR.prepare")
    }

    func test_SCPStatementTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCPStatementTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCPStatementTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCPStatementTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCPStatementXDRConfirmXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPStatementXDRConfirmXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPStatementXDRConfirmXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPStatementXDRConfirmXDR_roundTrip() throws {
        let original: SCPStatementXDRConfirmXDR = SCPStatementXDRConfirmXDR(ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nPrepared: UInt32(42), nCommit: UInt32(42), nH: UInt32(42), quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRConfirmXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRConfirmXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRConfirmXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRConfirmXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRConfirmXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRConfirmXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRConfirmXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRConfirmXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDRExternalizeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPStatementXDRExternalizeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPStatementXDRExternalizeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPStatementXDRExternalizeXDR_roundTrip() throws {
        let original: SCPStatementXDRExternalizeXDR = SCPStatementXDRExternalizeXDR(commit: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nH: UInt32(42), commitQuorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRExternalizeXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRExternalizeXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRExternalizeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRExternalizeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRExternalizeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRExternalizeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRExternalizeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRExternalizeXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDRPledgesXDR_confirm_rejectsBareString() throws {
        XCTAssertThrowsError(try SCPStatementXDRPledgesXDR.fromXdrJson("\"confirm\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCPStatementXDRPledgesXDR.confirm: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCPStatementXDRPledgesXDR")
            XCTAssertEqual(key, "confirm",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCPStatementXDRPledgesXDR_confirm_roundTrip() throws {
        let original: SCPStatementXDRPledgesXDR = .confirm(SCPStatementXDRConfirmXDR(ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nPrepared: UInt32(42), nCommit: UInt32(42), nH: UInt32(42), quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRPledgesXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRPledgesXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRPledgesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRPledgesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRPledgesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDRPledgesXDR_externalize_rejectsBareString() throws {
        XCTAssertThrowsError(try SCPStatementXDRPledgesXDR.fromXdrJson("\"externalize\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCPStatementXDRPledgesXDR.externalize: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCPStatementXDRPledgesXDR")
            XCTAssertEqual(key, "externalize",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCPStatementXDRPledgesXDR_externalize_roundTrip() throws {
        let original: SCPStatementXDRPledgesXDR = .externalize(SCPStatementXDRExternalizeXDR(commit: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nH: UInt32(42), commitQuorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRPledgesXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRPledgesXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRPledgesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRPledgesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRPledgesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDRPledgesXDR_nominate_rejectsBareString() throws {
        XCTAssertThrowsError(try SCPStatementXDRPledgesXDR.fromXdrJson("\"nominate\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCPStatementXDRPledgesXDR.nominate: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCPStatementXDRPledgesXDR")
            XCTAssertEqual(key, "nominate",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCPStatementXDRPledgesXDR_nominate_roundTrip() throws {
        let original: SCPStatementXDRPledgesXDR = .nominate(SCPNominationXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), votes: [Data([0x01, 0x02, 0x03])], accepted: [Data([0x01, 0x02, 0x03])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRPledgesXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRPledgesXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRPledgesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRPledgesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRPledgesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDRPledgesXDR_prepare_rejectsBareString() throws {
        XCTAssertThrowsError(try SCPStatementXDRPledgesXDR.fromXdrJson("\"prepare\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCPStatementXDRPledgesXDR.prepare: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCPStatementXDRPledgesXDR")
            XCTAssertEqual(key, "prepare",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCPStatementXDRPledgesXDR_prepare_roundTrip() throws {
        let original: SCPStatementXDRPledgesXDR = .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRPledgesXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRPledgesXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRPledgesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRPledgesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRPledgesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRPledgesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDRPledgesXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCPStatementXDRPledgesXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCPStatementXDRPledgesXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCPStatementXDRPledgesXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCPStatementXDRPrepareXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPStatementXDRPrepareXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPStatementXDRPrepareXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPStatementXDRPrepareXDR_roundTrip() throws {
        let original: SCPStatementXDRPrepareXDR = SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDRPrepareXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDRPrepareXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDRPrepareXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDRPrepareXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDRPrepareXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDRPrepareXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDRPrepareXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDRPrepareXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCPStatementXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCPStatementXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCPStatementXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCPStatementXDR_roundTrip() throws {
        let original: SCPStatementXDR = SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCPStatementXDR.fromXdrJson(json)
        let viaValue = try SCPStatementXDR.fromXdrJsonValue(tree)
        let viaTree = try SCPStatementXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCPStatementXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCPStatementXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCPStatementXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCPStatementXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCPStatementXDR must reach the same bytes through JSON and XDR")
    }

    func test_ValueXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ValueXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ValueXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ValueXDR_roundTrip() throws {
        let original: ValueXDR = Data([0x01, 0x02, 0x03])
        let tree = try ValueXDRJsonCodec.toXdrJsonValue(original)
        let json = try ValueXDRJsonCodec.toXdrJson(original)
        let decoded = try ValueXDRJsonCodec.fromXdrJson(json)
        let viaValue = try ValueXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try ValueXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try ValueXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "ValueXDR must produce the same tree after a round trip")
        XCTAssertEqual(try ValueXDRJsonCodec.toXdrJson(decoded), json,
                       "ValueXDR must produce the same text after a round trip")
        XCTAssertEqual(try ValueXDRJsonCodec.toXdrJson(viaValue), json,
                       "ValueXDR must read a tree the same way it reads text")
        XCTAssertEqual(try ValueXDRJsonCodec.toXdrJson(viaTree), json,
                       "ValueXDR must read a depth-checked tree the same way")
    }
}
