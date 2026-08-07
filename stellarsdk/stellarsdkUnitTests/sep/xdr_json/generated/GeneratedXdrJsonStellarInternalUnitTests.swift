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

final class GeneratedXdrJsonStellarInternalUnitTests: XCTestCase {

    func test_PersistedSCPStateV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PersistedSCPStateV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PersistedSCPStateV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PersistedSCPStateV0XDR_roundTrip() throws {
        let original: PersistedSCPStateV0XDR = PersistedSCPStateV0XDR(scpEnvelopes: [SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))), signature: Data([0x01, 0x02, 0x03]))], quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])])], txSets: [.txSet(TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PersistedSCPStateV0XDR.fromXdrJson(json)
        let viaValue = try PersistedSCPStateV0XDR.fromXdrJsonValue(tree)
        let viaTree = try PersistedSCPStateV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PersistedSCPStateV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PersistedSCPStateV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PersistedSCPStateV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PersistedSCPStateV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PersistedSCPStateV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_PersistedSCPStateV1XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PersistedSCPStateV1XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PersistedSCPStateV1XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PersistedSCPStateV1XDR_roundTrip() throws {
        let original: PersistedSCPStateV1XDR = PersistedSCPStateV1XDR(scpEnvelopes: [SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))), signature: Data([0x01, 0x02, 0x03]))], quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PersistedSCPStateV1XDR.fromXdrJson(json)
        let viaValue = try PersistedSCPStateV1XDR.fromXdrJsonValue(tree)
        let viaTree = try PersistedSCPStateV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PersistedSCPStateV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PersistedSCPStateV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PersistedSCPStateV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PersistedSCPStateV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PersistedSCPStateV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_PersistedSCPStateXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try PersistedSCPStateXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("PersistedSCPStateXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "PersistedSCPStateXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_PersistedSCPStateXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try PersistedSCPStateXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("PersistedSCPStateXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "PersistedSCPStateXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_PersistedSCPStateXDR_v0_roundTrip() throws {
        let original: PersistedSCPStateXDR = .v0(PersistedSCPStateV0XDR(scpEnvelopes: [SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .nominate(SCPNominationXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), votes: [], accepted: []))), signature: Data([0x01, 0x02, 0x03]))], quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])], txSets: [.txSet(TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PersistedSCPStateXDR.fromXdrJson(json)
        let viaValue = try PersistedSCPStateXDR.fromXdrJsonValue(tree)
        let viaTree = try PersistedSCPStateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PersistedSCPStateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PersistedSCPStateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PersistedSCPStateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PersistedSCPStateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PersistedSCPStateXDR must reach the same bytes through JSON and XDR")
    }

    func test_PersistedSCPStateXDR_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try PersistedSCPStateXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("PersistedSCPStateXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "PersistedSCPStateXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_PersistedSCPStateXDR_v1_roundTrip() throws {
        let original: PersistedSCPStateXDR = .v1(PersistedSCPStateV1XDR(scpEnvelopes: [SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .nominate(SCPNominationXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), votes: [], accepted: []))), signature: Data([0x01, 0x02, 0x03]))], quorumSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PersistedSCPStateXDR.fromXdrJson(json)
        let viaValue = try PersistedSCPStateXDR.fromXdrJsonValue(tree)
        let viaTree = try PersistedSCPStateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PersistedSCPStateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PersistedSCPStateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PersistedSCPStateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PersistedSCPStateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PersistedSCPStateXDR must reach the same bytes through JSON and XDR")
    }

    func test_StoredDebugTransactionSetXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try StoredDebugTransactionSetXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "StoredDebugTransactionSetXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_StoredDebugTransactionSetXDR_roundTrip() throws {
        let original: StoredDebugTransactionSetXDR = StoredDebugTransactionSetXDR(txSet: .txSet(TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))])), ledgerSeq: UInt32(42), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StoredDebugTransactionSetXDR.fromXdrJson(json)
        let viaValue = try StoredDebugTransactionSetXDR.fromXdrJsonValue(tree)
        let viaTree = try StoredDebugTransactionSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StoredDebugTransactionSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StoredDebugTransactionSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StoredDebugTransactionSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StoredDebugTransactionSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StoredDebugTransactionSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_StoredTransactionSetXDR_generalizedTxSet_rejectsBareString() throws {
        XCTAssertThrowsError(try StoredTransactionSetXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StoredTransactionSetXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StoredTransactionSetXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StoredTransactionSetXDR_generalizedTxSet_roundTrip() throws {
        let original: StoredTransactionSetXDR = .generalizedTxSet(.v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StoredTransactionSetXDR.fromXdrJson(json)
        let viaValue = try StoredTransactionSetXDR.fromXdrJsonValue(tree)
        let viaTree = try StoredTransactionSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StoredTransactionSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StoredTransactionSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StoredTransactionSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StoredTransactionSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StoredTransactionSetXDR must reach the same bytes through JSON and XDR")
    }

    func test_StoredTransactionSetXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try StoredTransactionSetXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("StoredTransactionSetXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "StoredTransactionSetXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_StoredTransactionSetXDR_txSet_rejectsBareString() throws {
        XCTAssertThrowsError(try StoredTransactionSetXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StoredTransactionSetXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StoredTransactionSetXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StoredTransactionSetXDR_txSet_roundTrip() throws {
        let original: StoredTransactionSetXDR = .txSet(TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StoredTransactionSetXDR.fromXdrJson(json)
        let viaValue = try StoredTransactionSetXDR.fromXdrJsonValue(tree)
        let viaTree = try StoredTransactionSetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StoredTransactionSetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StoredTransactionSetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StoredTransactionSetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StoredTransactionSetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StoredTransactionSetXDR must reach the same bytes through JSON and XDR")
    }
}
