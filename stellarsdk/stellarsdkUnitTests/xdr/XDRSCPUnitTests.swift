//
//  XDRSCPUnitTests.swift
//  stellarsdkTests
//
//  Created for Batch 9 XDR unit test coverage expansion.
//  Tests all types in Stellar-SCP.x that are not already covered.
//

import XCTest
import stellarsdk

/// Round-trip XDR tests for types defined in Stellar-SCP.x.
/// SCPBallotXDR and SCPQuorumSetXDR are tested in Batch 7 (XDRLedgerTypesP1UnitTests).
final class XDRSCPUnitTests: XCTestCase {

    // MARK: - Helpers

    /// Build a sample SCPBallotXDR for use in nested structs.
    private func sampleBallot() -> SCPBallotXDR {
        SCPBallotXDR(counter: 7, value: Data([0xCA, 0xFE, 0xBA, 0xBE]))
    }

    /// Build a sample HashXDR (WrappedData32) for quorum set hashes.
    private func sampleHash() -> HashXDR {
        XDRTestHelpers.wrappedData32()
    }

    /// Build a second distinct HashXDR.
    private func sampleHash2() -> HashXDR {
        WrappedData32(Data(repeating: 0xAA, count: 32))
    }

    /// Build a sample NodeIDXDR (PublicKey) for statement nodeID.
    private func sampleNodeID() throws -> NodeIDXDR {
        try XDRTestHelpers.publicKey()
    }

    // MARK: - SCPStatementTypeXDR (enum, Equatable)

    func testSCPStatementTypePrepareRoundTrip() throws {
        let original = SCPStatementTypeXDR.prepare
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSCPStatementTypeConfirmRoundTrip() throws {
        let original = SCPStatementTypeXDR.confirm
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSCPStatementTypeExternalizeRoundTrip() throws {
        let original = SCPStatementTypeXDR.externalize
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSCPStatementTypeNominateRoundTrip() throws {
        let original = SCPStatementTypeXDR.nominate
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSCPStatementTypeAllRawValues() {
        XCTAssertEqual(SCPStatementTypeXDR.prepare.rawValue, 0)
        XCTAssertEqual(SCPStatementTypeXDR.confirm.rawValue, 1)
        XCTAssertEqual(SCPStatementTypeXDR.externalize.rawValue, 2)
        XCTAssertEqual(SCPStatementTypeXDR.nominate.rawValue, 3)
    }

    // MARK: - SCPNominationXDR

    func testSCPNominationEmptyArraysRoundTrip() throws {
        let hash = sampleHash()
        let original = SCPNominationXDR(
            quorumSetHash: hash,
            votes: [],
            accepted: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPNominationXDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSetHash, hash)
        XCTAssertEqual(decoded.votes.count, 0)
        XCTAssertEqual(decoded.accepted.count, 0)
    }

    // MARK: - SCPStatementXDRPrepareXDR

    func testSCPStatementPrepareWithOptionalsNilRoundTrip() throws {
        let ballot = sampleBallot()
        let hash = sampleHash()

        let original = SCPStatementXDRPrepareXDR(
            quorumSetHash: hash,
            ballot: ballot,
            prepared: nil,
            preparedPrime: nil,
            nC: 3,
            nH: 5
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPrepareXDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSetHash, hash)
        XCTAssertEqual(decoded.ballot.counter, 7)
        XCTAssertEqual(decoded.ballot.value, Data([0xCA, 0xFE, 0xBA, 0xBE]))
        XCTAssertNil(decoded.prepared)
        XCTAssertNil(decoded.preparedPrime)
        XCTAssertEqual(decoded.nC, 3)
        XCTAssertEqual(decoded.nH, 5)
    }

    func testSCPStatementPrepareWithOptionalsSetRoundTrip() throws {
        let ballot = sampleBallot()
        let prepared = SCPBallotXDR(counter: 5, value: Data([0x11, 0x22]))
        let preparedPrime = SCPBallotXDR(counter: 4, value: Data([0x33]))
        let hash = sampleHash()

        let original = SCPStatementXDRPrepareXDR(
            quorumSetHash: hash,
            ballot: ballot,
            prepared: prepared,
            preparedPrime: preparedPrime,
            nC: 10,
            nH: 20
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPrepareXDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSetHash, hash)
        XCTAssertEqual(decoded.ballot.counter, 7)
        XCTAssertNotNil(decoded.prepared)
        XCTAssertEqual(decoded.prepared?.counter, 5)
        XCTAssertEqual(decoded.prepared?.value, Data([0x11, 0x22]))
        XCTAssertNotNil(decoded.preparedPrime)
        XCTAssertEqual(decoded.preparedPrime?.counter, 4)
        XCTAssertEqual(decoded.preparedPrime?.value, Data([0x33]))
        XCTAssertEqual(decoded.nC, 10)
        XCTAssertEqual(decoded.nH, 20)
    }

    func testSCPStatementPrepareOnlyPreparedSetRoundTrip() throws {
        let prepared = SCPBallotXDR(counter: 6, value: Data([0xFF]))

        let original = SCPStatementXDRPrepareXDR(
            quorumSetHash: sampleHash(),
            ballot: sampleBallot(),
            prepared: prepared,
            preparedPrime: nil,
            nC: 0,
            nH: 1
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPrepareXDR.self, data: encoded)

        XCTAssertNotNil(decoded.prepared)
        XCTAssertEqual(decoded.prepared?.counter, 6)
        XCTAssertNil(decoded.preparedPrime)
        XCTAssertEqual(decoded.nC, 0)
        XCTAssertEqual(decoded.nH, 1)
    }

    // MARK: - SCPStatementXDRConfirmXDR

    func testSCPStatementConfirmRoundTrip() throws {
        let ballot = sampleBallot()
        let hash = sampleHash()

        let original = SCPStatementXDRConfirmXDR(
            ballot: ballot,
            nPrepared: 12,
            nCommit: 8,
            nH: 15,
            quorumSetHash: hash
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRConfirmXDR.self, data: encoded)

        XCTAssertEqual(decoded.ballot.counter, 7)
        XCTAssertEqual(decoded.ballot.value, Data([0xCA, 0xFE, 0xBA, 0xBE]))
        XCTAssertEqual(decoded.nPrepared, 12)
        XCTAssertEqual(decoded.nCommit, 8)
        XCTAssertEqual(decoded.nH, 15)
        XCTAssertEqual(decoded.quorumSetHash, hash)
    }

    // MARK: - SCPStatementXDRExternalizeXDR

    func testSCPStatementExternalizeRoundTrip() throws {
        let commit = SCPBallotXDR(counter: 99, value: Data([0xDE, 0xAD]))
        let hash = sampleHash2()

        let original = SCPStatementXDRExternalizeXDR(
            commit: commit,
            nH: 42,
            commitQuorumSetHash: hash
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRExternalizeXDR.self, data: encoded)

        XCTAssertEqual(decoded.commit.counter, 99)
        XCTAssertEqual(decoded.commit.value, Data([0xDE, 0xAD]))
        XCTAssertEqual(decoded.nH, 42)
        XCTAssertEqual(decoded.commitQuorumSetHash, hash)
    }

    // MARK: - SCPStatementXDRPledgesXDR (union, 4 arms)

    func testPledgesPrepareArmRoundTrip() throws {
        let prepare = SCPStatementXDRPrepareXDR(
            quorumSetHash: sampleHash(),
            ballot: sampleBallot(),
            prepared: nil,
            preparedPrime: nil,
            nC: 1,
            nH: 2
        )
        let original = SCPStatementXDRPledgesXDR.prepare(prepare)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPledgesXDR.self, data: encoded)

        if case .prepare(let val) = decoded {
            XCTAssertEqual(val.quorumSetHash, sampleHash())
            XCTAssertEqual(val.ballot.counter, 7)
            XCTAssertNil(val.prepared)
            XCTAssertNil(val.preparedPrime)
            XCTAssertEqual(val.nC, 1)
            XCTAssertEqual(val.nH, 2)
        } else {
            XCTFail("Expected .prepare arm")
        }
    }

    func testPledgesConfirmArmRoundTrip() throws {
        let confirm = SCPStatementXDRConfirmXDR(
            ballot: sampleBallot(),
            nPrepared: 5,
            nCommit: 3,
            nH: 10,
            quorumSetHash: sampleHash()
        )
        let original = SCPStatementXDRPledgesXDR.confirm(confirm)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPledgesXDR.self, data: encoded)

        if case .confirm(let val) = decoded {
            XCTAssertEqual(val.ballot.counter, 7)
            XCTAssertEqual(val.nPrepared, 5)
            XCTAssertEqual(val.nCommit, 3)
            XCTAssertEqual(val.nH, 10)
            XCTAssertEqual(val.quorumSetHash, sampleHash())
        } else {
            XCTFail("Expected .confirm arm")
        }
    }

    func testPledgesExternalizeArmRoundTrip() throws {
        let externalize = SCPStatementXDRExternalizeXDR(
            commit: SCPBallotXDR(counter: 50, value: Data([0xBE, 0xEF])),
            nH: 25,
            commitQuorumSetHash: sampleHash2()
        )
        let original = SCPStatementXDRPledgesXDR.externalize(externalize)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPledgesXDR.self, data: encoded)

        if case .externalize(let val) = decoded {
            XCTAssertEqual(val.commit.counter, 50)
            XCTAssertEqual(val.commit.value, Data([0xBE, 0xEF]))
            XCTAssertEqual(val.nH, 25)
            XCTAssertEqual(val.commitQuorumSetHash, sampleHash2())
        } else {
            XCTFail("Expected .externalize arm")
        }
    }

    func testPledgesNominateArmRoundTrip() throws {
        let nomination = SCPNominationXDR(
            quorumSetHash: sampleHash(),
            votes: [],
            accepted: []
        )
        let original = SCPStatementXDRPledgesXDR.nominate(nomination)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDRPledgesXDR.self, data: encoded)

        if case .nominate(let val) = decoded {
            XCTAssertEqual(val.quorumSetHash, sampleHash())
            XCTAssertEqual(val.votes.count, 0)
            XCTAssertEqual(val.accepted.count, 0)
        } else {
            XCTFail("Expected .nominate arm")
        }
    }

    func testPledgesDiscriminantValues() throws {
        let prepPledge = SCPStatementXDRPledgesXDR.prepare(
            SCPStatementXDRPrepareXDR(
                quorumSetHash: sampleHash(), ballot: sampleBallot(),
                nC: 0, nH: 0
            )
        )
        XCTAssertEqual(prepPledge.type(), 0) // SCP_ST_PREPARE

        let confPledge = SCPStatementXDRPledgesXDR.confirm(
            SCPStatementXDRConfirmXDR(
                ballot: sampleBallot(), nPrepared: 0, nCommit: 0,
                nH: 0, quorumSetHash: sampleHash()
            )
        )
        XCTAssertEqual(confPledge.type(), 1) // SCP_ST_CONFIRM

        let extPledge = SCPStatementXDRPledgesXDR.externalize(
            SCPStatementXDRExternalizeXDR(
                commit: sampleBallot(), nH: 0,
                commitQuorumSetHash: sampleHash()
            )
        )
        XCTAssertEqual(extPledge.type(), 2) // SCP_ST_EXTERNALIZE

        let nomPledge = SCPStatementXDRPledgesXDR.nominate(
            SCPNominationXDR(quorumSetHash: sampleHash(), votes: [], accepted: [])
        )
        XCTAssertEqual(nomPledge.type(), 3) // SCP_ST_NOMINATE
    }

    // MARK: - SCPStatementXDR

    func testSCPStatementWithPrepareRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let prepare = SCPStatementXDRPrepareXDR(
            quorumSetHash: sampleHash(),
            ballot: sampleBallot(),
            prepared: SCPBallotXDR(counter: 3, value: Data([0x11])),
            preparedPrime: nil,
            nC: 2,
            nH: 4
        )
        let original = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 12345,
            pledges: .prepare(prepare)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDR.self, data: encoded)

        XCTAssertEqual(decoded.slotIndex, 12345)
        if case .prepare(let val) = decoded.pledges {
            XCTAssertEqual(val.quorumSetHash, sampleHash())
            XCTAssertEqual(val.ballot.counter, 7)
            XCTAssertNotNil(val.prepared)
            XCTAssertEqual(val.prepared?.counter, 3)
            XCTAssertNil(val.preparedPrime)
            XCTAssertEqual(val.nC, 2)
            XCTAssertEqual(val.nH, 4)
        } else {
            XCTFail("Expected .prepare pledges")
        }
    }

    func testSCPStatementWithConfirmRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let confirm = SCPStatementXDRConfirmXDR(
            ballot: sampleBallot(),
            nPrepared: 100,
            nCommit: 50,
            nH: 200,
            quorumSetHash: sampleHash()
        )
        let original = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 9999,
            pledges: .confirm(confirm)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDR.self, data: encoded)

        XCTAssertEqual(decoded.slotIndex, 9999)
        if case .confirm(let val) = decoded.pledges {
            XCTAssertEqual(val.nPrepared, 100)
            XCTAssertEqual(val.nCommit, 50)
            XCTAssertEqual(val.nH, 200)
        } else {
            XCTFail("Expected .confirm pledges")
        }
    }

    func testSCPStatementWithExternalizeRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let externalize = SCPStatementXDRExternalizeXDR(
            commit: SCPBallotXDR(counter: 77, value: Data([0xAB, 0xCD, 0xEF])),
            nH: 33,
            commitQuorumSetHash: sampleHash2()
        )
        let original = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 500_000,
            pledges: .externalize(externalize)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDR.self, data: encoded)

        XCTAssertEqual(decoded.slotIndex, 500_000)
        if case .externalize(let val) = decoded.pledges {
            XCTAssertEqual(val.commit.counter, 77)
            XCTAssertEqual(val.commit.value, Data([0xAB, 0xCD, 0xEF]))
            XCTAssertEqual(val.nH, 33)
            XCTAssertEqual(val.commitQuorumSetHash, sampleHash2())
        } else {
            XCTFail("Expected .externalize pledges")
        }
    }

    func testSCPStatementWithNominateRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let nomination = SCPNominationXDR(
            quorumSetHash: sampleHash(),
            votes: [],
            accepted: []
        )
        let original = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 1,
            pledges: .nominate(nomination)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPStatementXDR.self, data: encoded)

        XCTAssertEqual(decoded.slotIndex, 1)
        if case .nominate(let val) = decoded.pledges {
            XCTAssertEqual(val.quorumSetHash, sampleHash())
            XCTAssertEqual(val.votes.count, 0)
            XCTAssertEqual(val.accepted.count, 0)
        } else {
            XCTFail("Expected .nominate pledges")
        }
    }

    // MARK: - SCPEnvelopeXDR

    func testSCPEnvelopeWithPrepareRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let sig = Data(repeating: 0xAB, count: 64)
        let prepare = SCPStatementXDRPrepareXDR(
            quorumSetHash: sampleHash(),
            ballot: sampleBallot(),
            prepared: nil,
            preparedPrime: nil,
            nC: 0,
            nH: 0
        )
        let statement = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 42,
            pledges: .prepare(prepare)
        )
        let original = SCPEnvelopeXDR(statement: statement, signature: sig)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPEnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.signature, sig)
        XCTAssertEqual(decoded.statement.slotIndex, 42)
        if case .prepare(let val) = decoded.statement.pledges {
            XCTAssertEqual(val.quorumSetHash, sampleHash())
            XCTAssertEqual(val.ballot.counter, 7)
            XCTAssertNil(val.prepared)
            XCTAssertNil(val.preparedPrime)
        } else {
            XCTFail("Expected .prepare pledges in envelope")
        }
    }

    func testSCPEnvelopeWithNominateRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let sig = Data([0x01, 0x02, 0x03, 0x04])
        let nomination = SCPNominationXDR(
            quorumSetHash: sampleHash2(),
            votes: [],
            accepted: []
        )
        let statement = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 88888,
            pledges: .nominate(nomination)
        )
        let original = SCPEnvelopeXDR(statement: statement, signature: sig)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPEnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.signature, sig)
        XCTAssertEqual(decoded.statement.slotIndex, 88888)
        if case .nominate(let val) = decoded.statement.pledges {
            XCTAssertEqual(val.quorumSetHash, sampleHash2())
            XCTAssertEqual(val.votes.count, 0)
            XCTAssertEqual(val.accepted.count, 0)
        } else {
            XCTFail("Expected .nominate pledges in envelope")
        }
    }

    func testSCPEnvelopeWithConfirmRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let sig = Data(repeating: 0x77, count: 32)
        let confirm = SCPStatementXDRConfirmXDR(
            ballot: SCPBallotXDR(counter: 20, value: Data([0x99])),
            nPrepared: 15,
            nCommit: 10,
            nH: 18,
            quorumSetHash: sampleHash()
        )
        let statement = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 7777,
            pledges: .confirm(confirm)
        )
        let original = SCPEnvelopeXDR(statement: statement, signature: sig)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPEnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.signature, sig)
        XCTAssertEqual(decoded.statement.slotIndex, 7777)
        if case .confirm(let val) = decoded.statement.pledges {
            XCTAssertEqual(val.ballot.counter, 20)
            XCTAssertEqual(val.ballot.value, Data([0x99]))
            XCTAssertEqual(val.nPrepared, 15)
            XCTAssertEqual(val.nCommit, 10)
            XCTAssertEqual(val.nH, 18)
        } else {
            XCTFail("Expected .confirm pledges in envelope")
        }
    }

    func testSCPEnvelopeWithExternalizeRoundTrip() throws {
        let nodeID = try sampleNodeID()
        let sig = Data(repeating: 0x55, count: 16)
        let externalize = SCPStatementXDRExternalizeXDR(
            commit: SCPBallotXDR(counter: 1000, value: Data(repeating: 0xFE, count: 8)),
            nH: 500,
            commitQuorumSetHash: sampleHash()
        )
        let statement = SCPStatementXDR(
            nodeID: nodeID,
            slotIndex: 100_000,
            pledges: .externalize(externalize)
        )
        let original = SCPEnvelopeXDR(statement: statement, signature: sig)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPEnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.signature, sig)
        XCTAssertEqual(decoded.statement.slotIndex, 100_000)
        if case .externalize(let val) = decoded.statement.pledges {
            XCTAssertEqual(val.commit.counter, 1000)
            XCTAssertEqual(val.commit.value, Data(repeating: 0xFE, count: 8))
            XCTAssertEqual(val.nH, 500)
            XCTAssertEqual(val.commitQuorumSetHash, sampleHash())
        } else {
            XCTFail("Expected .externalize pledges in envelope")
        }
    }
}
