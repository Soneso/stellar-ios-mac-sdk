//
//  XDROverlayP2UnitTests.swift
//  stellarsdkTests
//
//  Created for Batch 11 XDR unit test coverage expansion.
//  Tests survey, TimeSliced, TopologyResponse, PeerStats, SurveyResponseBody,
//  and StellarMessageXDR union arms from Stellar-overlay.x.
//

import XCTest
import stellarsdk

/// Round-trip XDR tests for the second half of types defined in Stellar-overlay.x.
final class XDROverlayP2UnitTests: XCTestCase {

    // MARK: - Helpers

    /// Build a sample Curve25519PublicXDR key.
    private func sampleCurve25519Public() -> Curve25519PublicXDR {
        Curve25519PublicXDR(key: XDRTestHelpers.wrappedData32())
    }

    /// Build a sample PeerStatsXDR with realistic values.
    private func samplePeerStats() throws -> PeerStatsXDR {
        PeerStatsXDR(
            id: try XDRTestHelpers.publicKey(),
            versionStr: "stellar-core v21.3.1",
            messagesRead: 150_000,
            messagesWritten: 120_000,
            bytesRead: 45_000_000,
            bytesWritten: 38_000_000,
            secondsConnected: 86400,
            uniqueFloodBytesRecv: 10_000_000,
            duplicateFloodBytesRecv: 2_000_000,
            uniqueFetchBytesRecv: 5_000_000,
            duplicateFetchBytesRecv: 500_000,
            uniqueFloodMessageRecv: 80_000,
            duplicateFloodMessageRecv: 15_000,
            uniqueFetchMessageRecv: 40_000,
            duplicateFetchMessageRecv: 3_000
        )
    }

    /// Build a sample TimeSlicedNodeDataXDR with realistic values.
    private func sampleTimeSlicedNodeData() -> TimeSlicedNodeDataXDR {
        TimeSlicedNodeDataXDR(
            addedAuthenticatedPeers: 12,
            droppedAuthenticatedPeers: 3,
            totalInboundPeerCount: 64,
            totalOutboundPeerCount: 8,
            p75SCPFirstToSelfLatencyMs: 250,
            p75SCPSelfToOtherLatencyMs: 180,
            lostSyncCount: 1,
            isValidator: true,
            maxInboundPeerCount: 128,
            maxOutboundPeerCount: 16
        )
    }

    /// Build a sample TimeSlicedPeerDataXDR.
    private func sampleTimeSlicedPeerData() throws -> TimeSlicedPeerDataXDR {
        TimeSlicedPeerDataXDR(
            peerStats: try samplePeerStats(),
            averageLatencyMs: 95
        )
    }

    /// Build a sample SurveyRequestMessageXDR.
    private func sampleSurveyRequestMessage() throws -> SurveyRequestMessageXDR {
        SurveyRequestMessageXDR(
            surveyorPeerID: try XDRTestHelpers.publicKey(),
            surveyedPeerID: try XDRTestHelpers.publicKey(),
            ledgerNum: 50_000_000,
            encryptionKey: sampleCurve25519Public(),
            commandType: .timeSlicedSurveyTopology
        )
    }

    /// Build a sample SurveyResponseMessageXDR.
    private func sampleSurveyResponseMessage() throws -> SurveyResponseMessageXDR {
        SurveyResponseMessageXDR(
            surveyorPeerID: try XDRTestHelpers.publicKey(),
            surveyedPeerID: try XDRTestHelpers.publicKey(),
            ledgerNum: 50_000_001,
            commandType: .timeSlicedSurveyTopology,
            encryptedBody: Data(repeating: 0xBE, count: 128)
        )
    }

    /// Build a sample AuthCertXDR for use in Hello.
    private func sampleAuthCert() -> AuthCertXDR {
        AuthCertXDR(
            pubkey: sampleCurve25519Public(),
            expiration: 1700000000,
            sig: Data(repeating: 0xAB, count: 64)
        )
    }

    // MARK: - TimeSlicedSurveyStartCollectingMessageXDR

    func testTimeSlicedSurveyStartCollectingMessageRoundTrip() throws {
        let nodeID = try XDRTestHelpers.publicKey()
        let original = TimeSlicedSurveyStartCollectingMessageXDR(
            surveyorID: nodeID,
            nonce: 12345,
            ledgerNum: 49_999_999
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedSurveyStartCollectingMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 12345)
        XCTAssertEqual(decoded.ledgerNum, 49_999_999)
    }

    func testTimeSlicedSurveyStartCollectingMessageZeroValuesRoundTrip() throws {
        let nodeID = try XDRTestHelpers.publicKey()
        let original = TimeSlicedSurveyStartCollectingMessageXDR(
            surveyorID: nodeID,
            nonce: 0,
            ledgerNum: 0
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedSurveyStartCollectingMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 0)
        XCTAssertEqual(decoded.ledgerNum, 0)
    }

    // MARK: - SignedTimeSlicedSurveyStartCollectingMessageXDR

    func testSignedTimeSlicedSurveyStartCollectingMessageRoundTrip() throws {
        let inner = TimeSlicedSurveyStartCollectingMessageXDR(
            surveyorID: try XDRTestHelpers.publicKey(),
            nonce: 99,
            ledgerNum: 50_000_000
        )
        let sig = Data(repeating: 0xAA, count: 64)
        let original = SignedTimeSlicedSurveyStartCollectingMessageXDR(
            signature: sig,
            startCollecting: inner
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignedTimeSlicedSurveyStartCollectingMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.signature, sig)
        XCTAssertEqual(decoded.startCollecting.nonce, 99)
        XCTAssertEqual(decoded.startCollecting.ledgerNum, 50_000_000)
    }

    // MARK: - TimeSlicedSurveyStopCollectingMessageXDR

    func testTimeSlicedSurveyStopCollectingMessageRoundTrip() throws {
        let nodeID = try XDRTestHelpers.publicKey()
        let original = TimeSlicedSurveyStopCollectingMessageXDR(
            surveyorID: nodeID,
            nonce: 67890,
            ledgerNum: 50_000_100
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedSurveyStopCollectingMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 67890)
        XCTAssertEqual(decoded.ledgerNum, 50_000_100)
    }

    // MARK: - SignedTimeSlicedSurveyStopCollectingMessageXDR

    func testSignedTimeSlicedSurveyStopCollectingMessageRoundTrip() throws {
        let inner = TimeSlicedSurveyStopCollectingMessageXDR(
            surveyorID: try XDRTestHelpers.publicKey(),
            nonce: 11111,
            ledgerNum: 50_001_000
        )
        let sig = Data(repeating: 0xBB, count: 48)
        let original = SignedTimeSlicedSurveyStopCollectingMessageXDR(
            signature: sig,
            stopCollecting: inner
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignedTimeSlicedSurveyStopCollectingMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.signature, sig)
        XCTAssertEqual(decoded.stopCollecting.nonce, 11111)
        XCTAssertEqual(decoded.stopCollecting.ledgerNum, 50_001_000)
    }

    // MARK: - SurveyRequestMessageXDR

    func testSurveyRequestMessageRoundTrip() throws {
        let original = try sampleSurveyRequestMessage()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyRequestMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerNum, 50_000_000)
        XCTAssertEqual(decoded.commandType, .timeSlicedSurveyTopology)
        XCTAssertEqual(decoded.encryptionKey.key.wrapped, XDRTestHelpers.wrappedData32().wrapped)
    }

    func testSurveyRequestMessageMaxLedgerRoundTrip() throws {
        let original = SurveyRequestMessageXDR(
            surveyorPeerID: try XDRTestHelpers.publicKey(),
            surveyedPeerID: try XDRTestHelpers.publicKey(),
            ledgerNum: UInt32.max,
            encryptionKey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0x11, count: 32))),
            commandType: .timeSlicedSurveyTopology
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyRequestMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerNum, UInt32.max)
        XCTAssertEqual(decoded.encryptionKey.key.wrapped, Data(repeating: 0x11, count: 32))
    }

    // MARK: - TimeSlicedSurveyRequestMessageXDR

    func testTimeSlicedSurveyRequestMessageRoundTrip() throws {
        let request = try sampleSurveyRequestMessage()
        let original = TimeSlicedSurveyRequestMessageXDR(
            request: request,
            nonce: 42,
            inboundPeersIndex: 5,
            outboundPeersIndex: 10
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedSurveyRequestMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 42)
        XCTAssertEqual(decoded.inboundPeersIndex, 5)
        XCTAssertEqual(decoded.outboundPeersIndex, 10)
        XCTAssertEqual(decoded.request.ledgerNum, 50_000_000)
        XCTAssertEqual(decoded.request.commandType, .timeSlicedSurveyTopology)
    }

    // MARK: - SignedTimeSlicedSurveyRequestMessageXDR

    func testSignedTimeSlicedSurveyRequestMessageRoundTrip() throws {
        let inner = TimeSlicedSurveyRequestMessageXDR(
            request: try sampleSurveyRequestMessage(),
            nonce: 77,
            inboundPeersIndex: 0,
            outboundPeersIndex: 25
        )
        let sig = Data(repeating: 0xCC, count: 64)
        let original = SignedTimeSlicedSurveyRequestMessageXDR(
            requestSignature: sig,
            request: inner
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignedTimeSlicedSurveyRequestMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.requestSignature, sig)
        XCTAssertEqual(decoded.request.nonce, 77)
        XCTAssertEqual(decoded.request.outboundPeersIndex, 25)
    }

    // MARK: - SurveyResponseMessageXDR

    func testSurveyResponseMessageRoundTrip() throws {
        let original = try sampleSurveyResponseMessage()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyResponseMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerNum, 50_000_001)
        XCTAssertEqual(decoded.commandType, .timeSlicedSurveyTopology)
        XCTAssertEqual(decoded.encryptedBody, Data(repeating: 0xBE, count: 128))
    }

    func testSurveyResponseMessageEmptyBodyRoundTrip() throws {
        let original = SurveyResponseMessageXDR(
            surveyorPeerID: try XDRTestHelpers.publicKey(),
            surveyedPeerID: try XDRTestHelpers.publicKey(),
            ledgerNum: 1,
            commandType: .timeSlicedSurveyTopology,
            encryptedBody: Data()
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyResponseMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerNum, 1)
        XCTAssertEqual(decoded.encryptedBody, Data())
    }

    // MARK: - TimeSlicedSurveyResponseMessageXDR

    func testTimeSlicedSurveyResponseMessageRoundTrip() throws {
        let response = try sampleSurveyResponseMessage()
        let original = TimeSlicedSurveyResponseMessageXDR(
            response: response,
            nonce: 555
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedSurveyResponseMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 555)
        XCTAssertEqual(decoded.response.ledgerNum, 50_000_001)
        XCTAssertEqual(decoded.response.commandType, .timeSlicedSurveyTopology)
    }

    // MARK: - SignedTimeSlicedSurveyResponseMessageXDR

    func testSignedTimeSlicedSurveyResponseMessageRoundTrip() throws {
        let inner = TimeSlicedSurveyResponseMessageXDR(
            response: try sampleSurveyResponseMessage(),
            nonce: 888
        )
        let sig = Data(repeating: 0xDD, count: 32)
        let original = SignedTimeSlicedSurveyResponseMessageXDR(
            responseSignature: sig,
            response: inner
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignedTimeSlicedSurveyResponseMessageXDR.self, data: encoded)
        XCTAssertEqual(decoded.responseSignature, sig)
        XCTAssertEqual(decoded.response.nonce, 888)
        XCTAssertEqual(decoded.response.response.ledgerNum, 50_000_001)
    }

    // MARK: - PeerStatsXDR

    func testPeerStatsRoundTrip() throws {
        let original = try samplePeerStats()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerStatsXDR.self, data: encoded)
        XCTAssertEqual(decoded.versionStr, "stellar-core v21.3.1")
        XCTAssertEqual(decoded.messagesRead, 150_000)
        XCTAssertEqual(decoded.messagesWritten, 120_000)
        XCTAssertEqual(decoded.bytesRead, 45_000_000)
        XCTAssertEqual(decoded.bytesWritten, 38_000_000)
        XCTAssertEqual(decoded.secondsConnected, 86400)
        XCTAssertEqual(decoded.uniqueFloodBytesRecv, 10_000_000)
        XCTAssertEqual(decoded.duplicateFloodBytesRecv, 2_000_000)
        XCTAssertEqual(decoded.uniqueFetchBytesRecv, 5_000_000)
        XCTAssertEqual(decoded.duplicateFetchBytesRecv, 500_000)
        XCTAssertEqual(decoded.uniqueFloodMessageRecv, 80_000)
        XCTAssertEqual(decoded.duplicateFloodMessageRecv, 15_000)
        XCTAssertEqual(decoded.uniqueFetchMessageRecv, 40_000)
        XCTAssertEqual(decoded.duplicateFetchMessageRecv, 3_000)
    }

    func testPeerStatsZeroValuesRoundTrip() throws {
        let original = PeerStatsXDR(
            id: try XDRTestHelpers.publicKey(),
            versionStr: "",
            messagesRead: 0,
            messagesWritten: 0,
            bytesRead: 0,
            bytesWritten: 0,
            secondsConnected: 0,
            uniqueFloodBytesRecv: 0,
            duplicateFloodBytesRecv: 0,
            uniqueFetchBytesRecv: 0,
            duplicateFetchBytesRecv: 0,
            uniqueFloodMessageRecv: 0,
            duplicateFloodMessageRecv: 0,
            uniqueFetchMessageRecv: 0,
            duplicateFetchMessageRecv: 0
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerStatsXDR.self, data: encoded)
        XCTAssertEqual(decoded.versionStr, "")
        XCTAssertEqual(decoded.messagesRead, 0)
        XCTAssertEqual(decoded.bytesWritten, 0)
        XCTAssertEqual(decoded.secondsConnected, 0)
    }

    func testPeerStatsMaxValuesRoundTrip() throws {
        let original = PeerStatsXDR(
            id: try XDRTestHelpers.publicKey(),
            versionStr: String(repeating: "v", count: 100),
            messagesRead: UInt64.max,
            messagesWritten: UInt64.max,
            bytesRead: UInt64.max,
            bytesWritten: UInt64.max,
            secondsConnected: UInt64.max,
            uniqueFloodBytesRecv: UInt64.max,
            duplicateFloodBytesRecv: UInt64.max,
            uniqueFetchBytesRecv: UInt64.max,
            duplicateFetchBytesRecv: UInt64.max,
            uniqueFloodMessageRecv: UInt64.max,
            duplicateFloodMessageRecv: UInt64.max,
            uniqueFetchMessageRecv: UInt64.max,
            duplicateFetchMessageRecv: UInt64.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerStatsXDR.self, data: encoded)
        XCTAssertEqual(decoded.versionStr, String(repeating: "v", count: 100))
        XCTAssertEqual(decoded.messagesRead, UInt64.max)
        XCTAssertEqual(decoded.bytesWritten, UInt64.max)
        XCTAssertEqual(decoded.duplicateFetchMessageRecv, UInt64.max)
    }

    // MARK: - TimeSlicedNodeDataXDR

    func testTimeSlicedNodeDataRoundTrip() throws {
        let original = sampleTimeSlicedNodeData()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedNodeDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.addedAuthenticatedPeers, 12)
        XCTAssertEqual(decoded.droppedAuthenticatedPeers, 3)
        XCTAssertEqual(decoded.totalInboundPeerCount, 64)
        XCTAssertEqual(decoded.totalOutboundPeerCount, 8)
        XCTAssertEqual(decoded.p75SCPFirstToSelfLatencyMs, 250)
        XCTAssertEqual(decoded.p75SCPSelfToOtherLatencyMs, 180)
        XCTAssertEqual(decoded.lostSyncCount, 1)
        XCTAssertEqual(decoded.isValidator, true)
        XCTAssertEqual(decoded.maxInboundPeerCount, 128)
        XCTAssertEqual(decoded.maxOutboundPeerCount, 16)
    }

    func testTimeSlicedNodeDataNonValidatorRoundTrip() throws {
        let original = TimeSlicedNodeDataXDR(
            addedAuthenticatedPeers: 0,
            droppedAuthenticatedPeers: 0,
            totalInboundPeerCount: 10,
            totalOutboundPeerCount: 5,
            p75SCPFirstToSelfLatencyMs: 0,
            p75SCPSelfToOtherLatencyMs: 0,
            lostSyncCount: 0,
            isValidator: false,
            maxInboundPeerCount: 50,
            maxOutboundPeerCount: 10
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedNodeDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.isValidator, false)
        XCTAssertEqual(decoded.totalInboundPeerCount, 10)
        XCTAssertEqual(decoded.totalOutboundPeerCount, 5)
        XCTAssertEqual(decoded.lostSyncCount, 0)
    }

    // MARK: - TimeSlicedPeerDataXDR

    func testTimeSlicedPeerDataRoundTrip() throws {
        let original = try sampleTimeSlicedPeerData()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedPeerDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.averageLatencyMs, 95)
        XCTAssertEqual(decoded.peerStats.versionStr, "stellar-core v21.3.1")
        XCTAssertEqual(decoded.peerStats.messagesRead, 150_000)
    }

    func testTimeSlicedPeerDataZeroLatencyRoundTrip() throws {
        let stats = PeerStatsXDR(
            id: try XDRTestHelpers.publicKey(),
            versionStr: "v20",
            messagesRead: 1,
            messagesWritten: 2,
            bytesRead: 100,
            bytesWritten: 200,
            secondsConnected: 300,
            uniqueFloodBytesRecv: 10,
            duplicateFloodBytesRecv: 20,
            uniqueFetchBytesRecv: 30,
            duplicateFetchBytesRecv: 40,
            uniqueFloodMessageRecv: 50,
            duplicateFloodMessageRecv: 60,
            uniqueFetchMessageRecv: 70,
            duplicateFetchMessageRecv: 80
        )
        let original = TimeSlicedPeerDataXDR(peerStats: stats, averageLatencyMs: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedPeerDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.averageLatencyMs, 0)
        XCTAssertEqual(decoded.peerStats.versionStr, "v20")
    }

    // MARK: - TimeSlicedPeerDataListXDR

    func testTimeSlicedPeerDataListEmptyRoundTrip() throws {
        let original = TimeSlicedPeerDataListXDR(wrapped: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedPeerDataListXDR.self, data: encoded)
        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    func testTimeSlicedPeerDataListSingleElementRoundTrip() throws {
        let peerData = try sampleTimeSlicedPeerData()
        let original = TimeSlicedPeerDataListXDR(wrapped: [peerData])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedPeerDataListXDR.self, data: encoded)
        XCTAssertEqual(decoded.wrapped.count, 1)
        XCTAssertEqual(decoded.wrapped[0].averageLatencyMs, 95)
        XCTAssertEqual(decoded.wrapped[0].peerStats.versionStr, "stellar-core v21.3.1")
    }

    func testTimeSlicedPeerDataListMultipleElementsRoundTrip() throws {
        let peer1 = try sampleTimeSlicedPeerData()
        let stats2 = PeerStatsXDR(
            id: try XDRTestHelpers.publicKey(),
            versionStr: "v22.0.0",
            messagesRead: 999,
            messagesWritten: 888,
            bytesRead: 777,
            bytesWritten: 666,
            secondsConnected: 555,
            uniqueFloodBytesRecv: 444,
            duplicateFloodBytesRecv: 333,
            uniqueFetchBytesRecv: 222,
            duplicateFetchBytesRecv: 111,
            uniqueFloodMessageRecv: 99,
            duplicateFloodMessageRecv: 88,
            uniqueFetchMessageRecv: 77,
            duplicateFetchMessageRecv: 66
        )
        let peer2 = TimeSlicedPeerDataXDR(peerStats: stats2, averageLatencyMs: 200)
        let original = TimeSlicedPeerDataListXDR(wrapped: [peer1, peer2])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TimeSlicedPeerDataListXDR.self, data: encoded)
        XCTAssertEqual(decoded.wrapped.count, 2)
        XCTAssertEqual(decoded.wrapped[0].averageLatencyMs, 95)
        XCTAssertEqual(decoded.wrapped[1].averageLatencyMs, 200)
        XCTAssertEqual(decoded.wrapped[1].peerStats.versionStr, "v22.0.0")
    }

    // MARK: - TopologyResponseBodyV2XDR

    func testTopologyResponseBodyV2EmptyPeersRoundTrip() throws {
        let nodeData = sampleTimeSlicedNodeData()
        let original = TopologyResponseBodyV2XDR(
            inboundPeers: TimeSlicedPeerDataListXDR(wrapped: []),
            outboundPeers: TimeSlicedPeerDataListXDR(wrapped: []),
            nodeData: nodeData
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TopologyResponseBodyV2XDR.self, data: encoded)
        XCTAssertEqual(decoded.inboundPeers.wrapped.count, 0)
        XCTAssertEqual(decoded.outboundPeers.wrapped.count, 0)
        XCTAssertEqual(decoded.nodeData.isValidator, true)
        XCTAssertEqual(decoded.nodeData.addedAuthenticatedPeers, 12)
    }

    func testTopologyResponseBodyV2WithPeersRoundTrip() throws {
        let peer = try sampleTimeSlicedPeerData()
        let nodeData = sampleTimeSlicedNodeData()
        let original = TopologyResponseBodyV2XDR(
            inboundPeers: TimeSlicedPeerDataListXDR(wrapped: [peer]),
            outboundPeers: TimeSlicedPeerDataListXDR(wrapped: [peer]),
            nodeData: nodeData
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TopologyResponseBodyV2XDR.self, data: encoded)
        XCTAssertEqual(decoded.inboundPeers.wrapped.count, 1)
        XCTAssertEqual(decoded.outboundPeers.wrapped.count, 1)
        XCTAssertEqual(decoded.inboundPeers.wrapped[0].averageLatencyMs, 95)
        XCTAssertEqual(decoded.nodeData.maxInboundPeerCount, 128)
    }

    // MARK: - SurveyResponseBodyXDR (union)

    func testSurveyResponseBodyTopologyV2RoundTrip() throws {
        let nodeData = sampleTimeSlicedNodeData()
        let topoBody = TopologyResponseBodyV2XDR(
            inboundPeers: TimeSlicedPeerDataListXDR(wrapped: []),
            outboundPeers: TimeSlicedPeerDataListXDR(wrapped: []),
            nodeData: nodeData
        )
        let original = SurveyResponseBodyXDR.topologyResponseBodyV2(topoBody)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyResponseBodyXDR.self, data: encoded)
        if case .topologyResponseBodyV2(let body) = decoded {
            XCTAssertEqual(body.nodeData.isValidator, true)
            XCTAssertEqual(body.nodeData.totalInboundPeerCount, 64)
            XCTAssertEqual(body.inboundPeers.wrapped.count, 0)
        } else {
            XCTFail("Expected .topologyResponseBodyV2")
        }
    }

    func testSurveyResponseBodyTypeDiscriminant() {
        let body = SurveyResponseBodyXDR.topologyResponseBodyV2(
            TopologyResponseBodyV2XDR(
                inboundPeers: TimeSlicedPeerDataListXDR(wrapped: []),
                outboundPeers: TimeSlicedPeerDataListXDR(wrapped: []),
                nodeData: sampleTimeSlicedNodeData()
            )
        )
        XCTAssertEqual(body.type(), SurveyMessageResponseTypeXDR.surveyTopologyResponseV2.rawValue)
    }

    // MARK: - StellarMessageXDR union arms

    func testStellarMessageErrorRoundTrip() throws {
        let error = ErrorXDR(code: .auth, msg: "authentication failed")
        let original = StellarMessageXDR.error(error)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .error(let e) = decoded {
            XCTAssertEqual(e.code, .auth)
            XCTAssertEqual(e.msg, "authentication failed")
        } else {
            XCTFail("Expected .error")
        }
    }

    func testStellarMessageHelloRoundTrip() throws {
        let hello = HelloXDR(
            ledgerVersion: 21,
            overlayVersion: 33,
            overlayMinVersion: 30,
            networkID: XDRTestHelpers.wrappedData32(),
            versionStr: "stellar-core v21.0.0",
            listeningPort: 11625,
            peerID: try XDRTestHelpers.publicKey(),
            cert: sampleAuthCert(),
            nonce: WrappedData32(Data(repeating: 0xCA, count: 32))
        )
        let original = StellarMessageXDR.hello(hello)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .hello(let h) = decoded {
            XCTAssertEqual(h.ledgerVersion, 21)
            XCTAssertEqual(h.overlayVersion, 33)
            XCTAssertEqual(h.versionStr, "stellar-core v21.0.0")
            XCTAssertEqual(h.listeningPort, 11625)
        } else {
            XCTFail("Expected .hello")
        }
    }

    func testStellarMessageAuthRoundTrip() throws {
        let original = StellarMessageXDR.auth(AuthXDR(flags: 200))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .auth(let a) = decoded {
            XCTAssertEqual(a.flags, 200)
        } else {
            XCTFail("Expected .auth")
        }
    }

    func testStellarMessageDontHaveRoundTrip() throws {
        let hash = WrappedData32(Data(repeating: 0x42, count: 32))
        let dh = DontHaveXDR(type: .txSet, reqHash: hash)
        let original = StellarMessageXDR.dontHave(dh)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .dontHave(let d) = decoded {
            XCTAssertEqual(d.type, .txSet)
            XCTAssertEqual(d.reqHash.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .dontHave")
        }
    }

    func testStellarMessagePeersEmptyRoundTrip() throws {
        let original = StellarMessageXDR.peers([])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .peers(let p) = decoded {
            XCTAssertEqual(p.count, 0)
        } else {
            XCTFail("Expected .peers")
        }
    }

    func testStellarMessagePeersWithEntriesRoundTrip() throws {
        let ip = PeerAddressXDRIpXDR.ipv4(WrappedData4(Data([10, 0, 0, 1])))
        let addr = PeerAddressXDR(ip: ip, port: 11625, numFailures: 2)
        let original = StellarMessageXDR.peers([addr])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .peers(let p) = decoded {
            XCTAssertEqual(p.count, 1)
            XCTAssertEqual(p[0].port, 11625)
            XCTAssertEqual(p[0].numFailures, 2)
        } else {
            XCTFail("Expected .peers")
        }
    }

    func testStellarMessageGetTxSetRoundTrip() throws {
        let hash = WrappedData32(Data(repeating: 0xAA, count: 32))
        let original = StellarMessageXDR.txSetHash(hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .txSetHash(let h) = decoded {
            XCTAssertEqual(h.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .txSetHash")
        }
    }

    func testStellarMessageTxSetEmptyRoundTrip() throws {
        let txSet = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )
        let original = StellarMessageXDR.txSet(txSet)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .txSet(let ts) = decoded {
            XCTAssertEqual(ts.previousLedgerHash.wrapped, XDRTestHelpers.wrappedData32().wrapped)
            XCTAssertEqual(ts.txs.count, 0)
        } else {
            XCTFail("Expected .txSet")
        }
    }

    func testStellarMessageGeneralizedTxSetRoundTrip() throws {
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let original = StellarMessageXDR.generalizedTxSet(genTxSet)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .generalizedTxSet(let g) = decoded {
            if case .v1TxSet(let v1) = g {
                XCTAssertEqual(v1.previousLedgerHash.wrapped, XDRTestHelpers.wrappedData32().wrapped)
                XCTAssertEqual(v1.phases.count, 0)
            } else {
                XCTFail("Expected .v1TxSet inside generalizedTxSet")
            }
        } else {
            XCTFail("Expected .generalizedTxSet")
        }
    }

    func testStellarMessageGetScpQuorumsetRoundTrip() throws {
        let hash = WrappedData32(Data(repeating: 0xBB, count: 32))
        let original = StellarMessageXDR.qSetHash(hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .qSetHash(let h) = decoded {
            XCTAssertEqual(h.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .qSetHash")
        }
    }

    func testStellarMessageScpQuorumsetRoundTrip() throws {
        let validator = try XDRTestHelpers.publicKey()
        let qSet = SCPQuorumSetXDR(
            threshold: 2,
            validators: [validator],
            innerSets: []
        )
        let original = StellarMessageXDR.qSet(qSet)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .qSet(let q) = decoded {
            XCTAssertEqual(q.threshold, 2)
            XCTAssertEqual(q.validators.count, 1)
            XCTAssertEqual(q.innerSets.count, 0)
        } else {
            XCTFail("Expected .qSet")
        }
    }

    func testStellarMessageGetScpStateRoundTrip() throws {
        let original = StellarMessageXDR.getSCPLedgerSeq(12345)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .getSCPLedgerSeq(let seq) = decoded {
            XCTAssertEqual(seq, 12345)
        } else {
            XCTFail("Expected .getSCPLedgerSeq")
        }
    }

    func testStellarMessageGetScpStateZeroRoundTrip() throws {
        // ledger seq 0 means "latest"
        let original = StellarMessageXDR.getSCPLedgerSeq(0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .getSCPLedgerSeq(let seq) = decoded {
            XCTAssertEqual(seq, 0)
        } else {
            XCTFail("Expected .getSCPLedgerSeq")
        }
    }

    func testStellarMessageSendMoreRoundTrip() throws {
        let original = StellarMessageXDR.sendMoreMessage(SendMoreXDR(numMessages: 50))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .sendMoreMessage(let sm) = decoded {
            XCTAssertEqual(sm.numMessages, 50)
        } else {
            XCTFail("Expected .sendMoreMessage")
        }
    }

    func testStellarMessageSendMoreExtendedRoundTrip() throws {
        let original = StellarMessageXDR.sendMoreExtendedMessage(
            SendMoreExtendedXDR(numMessages: 100, numBytes: 1_048_576)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .sendMoreExtendedMessage(let sme) = decoded {
            XCTAssertEqual(sme.numMessages, 100)
            XCTAssertEqual(sme.numBytes, 1_048_576)
        } else {
            XCTFail("Expected .sendMoreExtendedMessage")
        }
    }

    func testStellarMessageFloodAdvertRoundTrip() throws {
        let original = StellarMessageXDR.floodAdvert(
            FloodAdvertXDR(txHashes: TxAdvertVectorXDR(wrapped: []))
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .floodAdvert(let fa) = decoded {
            XCTAssertEqual(fa.txHashes.wrapped.count, 0)
        } else {
            XCTFail("Expected .floodAdvert")
        }
    }

    func testStellarMessageFloodDemandRoundTrip() throws {
        let original = StellarMessageXDR.floodDemand(
            FloodDemandXDR(txHashes: TxDemandVectorXDR(wrapped: []))
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .floodDemand(let fd) = decoded {
            XCTAssertEqual(fd.txHashes.wrapped.count, 0)
        } else {
            XCTFail("Expected .floodDemand")
        }
    }

    func testStellarMessageTimeSlicedSurveyRequestRoundTrip() throws {
        let inner = TimeSlicedSurveyRequestMessageXDR(
            request: try sampleSurveyRequestMessage(),
            nonce: 42,
            inboundPeersIndex: 3,
            outboundPeersIndex: 7
        )
        let signed = SignedTimeSlicedSurveyRequestMessageXDR(
            requestSignature: Data(repeating: 0xF1, count: 64),
            request: inner
        )
        let original = StellarMessageXDR.signedTimeSlicedSurveyRequestMessage(signed)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .signedTimeSlicedSurveyRequestMessage(let msg) = decoded {
            XCTAssertEqual(msg.requestSignature, Data(repeating: 0xF1, count: 64))
            XCTAssertEqual(msg.request.nonce, 42)
            XCTAssertEqual(msg.request.inboundPeersIndex, 3)
            XCTAssertEqual(msg.request.outboundPeersIndex, 7)
        } else {
            XCTFail("Expected .signedTimeSlicedSurveyRequestMessage")
        }
    }

    func testStellarMessageTimeSlicedSurveyResponseRoundTrip() throws {
        let inner = TimeSlicedSurveyResponseMessageXDR(
            response: try sampleSurveyResponseMessage(),
            nonce: 999
        )
        let signed = SignedTimeSlicedSurveyResponseMessageXDR(
            responseSignature: Data(repeating: 0xF2, count: 64),
            response: inner
        )
        let original = StellarMessageXDR.signedTimeSlicedSurveyResponseMessage(signed)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .signedTimeSlicedSurveyResponseMessage(let msg) = decoded {
            XCTAssertEqual(msg.responseSignature, Data(repeating: 0xF2, count: 64))
            XCTAssertEqual(msg.response.nonce, 999)
        } else {
            XCTFail("Expected .signedTimeSlicedSurveyResponseMessage")
        }
    }

    func testStellarMessageTimeSlicedSurveyStartCollectingRoundTrip() throws {
        let inner = TimeSlicedSurveyStartCollectingMessageXDR(
            surveyorID: try XDRTestHelpers.publicKey(),
            nonce: 1234,
            ledgerNum: 51_000_000
        )
        let signed = SignedTimeSlicedSurveyStartCollectingMessageXDR(
            signature: Data(repeating: 0xF3, count: 64),
            startCollecting: inner
        )
        let original = StellarMessageXDR.signedTimeSlicedSurveyStartCollectingMessage(signed)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .signedTimeSlicedSurveyStartCollectingMessage(let msg) = decoded {
            XCTAssertEqual(msg.signature, Data(repeating: 0xF3, count: 64))
            XCTAssertEqual(msg.startCollecting.nonce, 1234)
            XCTAssertEqual(msg.startCollecting.ledgerNum, 51_000_000)
        } else {
            XCTFail("Expected .signedTimeSlicedSurveyStartCollectingMessage")
        }
    }

    func testStellarMessageTimeSlicedSurveyStopCollectingRoundTrip() throws {
        let inner = TimeSlicedSurveyStopCollectingMessageXDR(
            surveyorID: try XDRTestHelpers.publicKey(),
            nonce: 5678,
            ledgerNum: 52_000_000
        )
        let signed = SignedTimeSlicedSurveyStopCollectingMessageXDR(
            signature: Data(repeating: 0xF4, count: 64),
            stopCollecting: inner
        )
        let original = StellarMessageXDR.signedTimeSlicedSurveyStopCollectingMessage(signed)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarMessageXDR.self, data: encoded)
        if case .signedTimeSlicedSurveyStopCollectingMessage(let msg) = decoded {
            XCTAssertEqual(msg.signature, Data(repeating: 0xF4, count: 64))
            XCTAssertEqual(msg.stopCollecting.nonce, 5678)
            XCTAssertEqual(msg.stopCollecting.ledgerNum, 52_000_000)
        } else {
            XCTFail("Expected .signedTimeSlicedSurveyStopCollectingMessage")
        }
    }

    // MARK: - StellarMessageXDR type discriminant tests

    func testStellarMessageTypeDiscriminants() throws {
        let errorMsg = StellarMessageXDR.error(ErrorXDR(code: .misc, msg: ""))
        XCTAssertEqual(errorMsg.type(), MessageTypeXDR.errorMsg.rawValue)

        let auth = StellarMessageXDR.auth(AuthXDR(flags: 0))
        XCTAssertEqual(auth.type(), MessageTypeXDR.auth.rawValue)

        let sendMore = StellarMessageXDR.sendMoreMessage(SendMoreXDR(numMessages: 1))
        XCTAssertEqual(sendMore.type(), MessageTypeXDR.sendMore.rawValue)

        let sendMoreExt = StellarMessageXDR.sendMoreExtendedMessage(
            SendMoreExtendedXDR(numMessages: 1, numBytes: 1)
        )
        XCTAssertEqual(sendMoreExt.type(), MessageTypeXDR.sendMoreExtended.rawValue)

        let getScp = StellarMessageXDR.getSCPLedgerSeq(0)
        XCTAssertEqual(getScp.type(), MessageTypeXDR.getScpState.rawValue)

        let txSetHash = StellarMessageXDR.txSetHash(XDRTestHelpers.wrappedData32())
        XCTAssertEqual(txSetHash.type(), MessageTypeXDR.getTxSet.rawValue)

        let qSetHash = StellarMessageXDR.qSetHash(XDRTestHelpers.wrappedData32())
        XCTAssertEqual(qSetHash.type(), MessageTypeXDR.getScpQuorumset.rawValue)

        let floodAdvert = StellarMessageXDR.floodAdvert(
            FloodAdvertXDR(txHashes: TxAdvertVectorXDR(wrapped: []))
        )
        XCTAssertEqual(floodAdvert.type(), MessageTypeXDR.floodAdvert.rawValue)

        let floodDemand = StellarMessageXDR.floodDemand(
            FloodDemandXDR(txHashes: TxDemandVectorXDR(wrapped: []))
        )
        XCTAssertEqual(floodDemand.type(), MessageTypeXDR.floodDemand.rawValue)
    }
}
