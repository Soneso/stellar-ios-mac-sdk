//
//  XDROverlayP1UnitTests.swift
//  stellarsdkTests
//
//  Created for Batch 10 XDR unit test coverage expansion.
//  Tests peer, auth, error, and basic message types from Stellar-overlay.x.
//  Excludes StellarMessage union and survey types (covered in P2).
//

import XCTest
import stellarsdk

/// Round-trip XDR tests for the first half of types defined in Stellar-overlay.x.
final class XDROverlayP1UnitTests: XCTestCase {

    // MARK: - Helpers

    /// Build a sample Curve25519PublicXDR key.
    private func sampleCurve25519Public() -> Curve25519PublicXDR {
        Curve25519PublicXDR(key: XDRTestHelpers.wrappedData32())
    }

    /// Build a sample AuthCertXDR for use in Hello and other nested types.
    private func sampleAuthCert() -> AuthCertXDR {
        AuthCertXDR(
            pubkey: sampleCurve25519Public(),
            expiration: 1700000000,
            sig: Data(repeating: 0xAB, count: 64)
        )
    }

    /// Build a sample HmacSha256MacXDR.
    private func sampleHmac() -> HmacSha256MacXDR {
        HmacSha256MacXDR(mac: XDRTestHelpers.wrappedData32())
    }

    // MARK: - ErrorCodeXDR (simple enum, Equatable)

    func testErrorCodeMiscRoundTrip() throws {
        let original = ErrorCodeXDR.misc
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorCodeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testErrorCodeDataRoundTrip() throws {
        let original = ErrorCodeXDR.data
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorCodeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testErrorCodeConfRoundTrip() throws {
        let original = ErrorCodeXDR.conf
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorCodeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testErrorCodeAuthRoundTrip() throws {
        let original = ErrorCodeXDR.auth
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorCodeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testErrorCodeLoadRoundTrip() throws {
        let original = ErrorCodeXDR.load
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorCodeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - ErrorXDR (struct, no Equatable)

    func testErrorXDRMiscRoundTrip() throws {
        let original = ErrorXDR(code: .misc, msg: "unspecific error")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorXDR.self, data: encoded)
        XCTAssertEqual(decoded.code, .misc)
        XCTAssertEqual(decoded.msg, "unspecific error")
    }

    func testErrorXDRAuthWithLongMessageRoundTrip() throws {
        let longMsg = String(repeating: "x", count: 100) // max length per XDR spec
        let original = ErrorXDR(code: .auth, msg: longMsg)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorXDR.self, data: encoded)
        XCTAssertEqual(decoded.code, .auth)
        XCTAssertEqual(decoded.msg, longMsg)
    }

    func testErrorXDRDataEmptyMessageRoundTrip() throws {
        let original = ErrorXDR(code: .data, msg: "")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorXDR.self, data: encoded)
        XCTAssertEqual(decoded.code, .data)
        XCTAssertEqual(decoded.msg, "")
    }

    func testErrorXDRLoadRoundTrip() throws {
        let original = ErrorXDR(code: .load, msg: "system overloaded")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ErrorXDR.self, data: encoded)
        XCTAssertEqual(decoded.code, .load)
        XCTAssertEqual(decoded.msg, "system overloaded")
    }

    // MARK: - IPAddrTypeXDR (simple enum, Equatable)

    func testIPAddrTypePv4RoundTrip() throws {
        let original = IPAddrTypeXDR.pv4
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(IPAddrTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testIPAddrTypePv6RoundTrip() throws {
        let original = IPAddrTypeXDR.pv6
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(IPAddrTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - PeerAddressXDRIpXDR (union, no Equatable)

    func testPeerAddressIpIPv4RoundTrip() throws {
        let ipv4Data = XDRTestHelpers.wrappedData4()
        let original = PeerAddressXDRIpXDR.ipv4(ipv4Data)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerAddressXDRIpXDR.self, data: encoded)
        if case .ipv4(let val) = decoded {
            XCTAssertEqual(val.wrapped, ipv4Data.wrapped)
        } else {
            XCTFail("Expected .ipv4")
        }
    }

    func testPeerAddressIpIPv6RoundTrip() throws {
        let ipv6Data = XDRTestHelpers.wrappedData16()
        let original = PeerAddressXDRIpXDR.ipv6(ipv6Data)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerAddressXDRIpXDR.self, data: encoded)
        if case .ipv6(let val) = decoded {
            XCTAssertEqual(val.wrapped, ipv6Data.wrapped)
        } else {
            XCTFail("Expected .ipv6")
        }
    }

    func testPeerAddressIpTypeDiscriminant() {
        let ipv4 = PeerAddressXDRIpXDR.ipv4(XDRTestHelpers.wrappedData4())
        let ipv6 = PeerAddressXDRIpXDR.ipv6(XDRTestHelpers.wrappedData16())
        XCTAssertEqual(ipv4.type(), IPAddrTypeXDR.pv4.rawValue)
        XCTAssertEqual(ipv6.type(), IPAddrTypeXDR.pv6.rawValue)
    }

    // MARK: - PeerAddressXDR (struct, no Equatable)

    func testPeerAddressIPv4RoundTrip() throws {
        let ip = PeerAddressXDRIpXDR.ipv4(WrappedData4(Data([192, 168, 1, 1])))
        let original = PeerAddressXDR(ip: ip, port: 11625, numFailures: 3)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerAddressXDR.self, data: encoded)
        XCTAssertEqual(decoded.port, 11625)
        XCTAssertEqual(decoded.numFailures, 3)
        if case .ipv4(let val) = decoded.ip {
            XCTAssertEqual(val.wrapped, Data([192, 168, 1, 1]))
        } else {
            XCTFail("Expected .ipv4 ip")
        }
    }

    func testPeerAddressIPv6RoundTrip() throws {
        let ipv6Bytes = Data([0x20, 0x01, 0x0d, 0xb8, 0x85, 0xa3, 0x00, 0x00,
                              0x00, 0x00, 0x8a, 0x2e, 0x03, 0x70, 0x73, 0x34])
        let ip = PeerAddressXDRIpXDR.ipv6(WrappedData16(ipv6Bytes))
        let original = PeerAddressXDR(ip: ip, port: 443, numFailures: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerAddressXDR.self, data: encoded)
        XCTAssertEqual(decoded.port, 443)
        XCTAssertEqual(decoded.numFailures, 0)
        if case .ipv6(let val) = decoded.ip {
            XCTAssertEqual(val.wrapped, ipv6Bytes)
        } else {
            XCTFail("Expected .ipv6 ip")
        }
    }

    func testPeerAddressHighFailureCountRoundTrip() throws {
        let ip = PeerAddressXDRIpXDR.ipv4(WrappedData4(Data([10, 0, 0, 1])))
        let original = PeerAddressXDR(ip: ip, port: 65535, numFailures: 999)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PeerAddressXDR.self, data: encoded)
        XCTAssertEqual(decoded.port, 65535)
        XCTAssertEqual(decoded.numFailures, 999)
    }

    // MARK: - MessageTypeXDR (simple enum, Equatable)

    func testMessageTypeAllCasesRoundTrip() throws {
        let allCases: [MessageTypeXDR] = [
            .errorMsg, .auth, .dontHave, .peers,
            .getTxSet, .txSet, .generalizedTxSet, .transaction,
            .getScpQuorumset, .scpQuorumset, .scpMessage, .getScpState,
            .hello, .sendMore, .sendMoreExtended,
            .floodAdvert, .floodDemand,
            .timeSlicedSurveyRequest, .timeSlicedSurveyResponse,
            .timeSlicedSurveyStartCollecting, .timeSlicedSurveyStopCollecting
        ]
        for msgType in allCases {
            let encoded = try XDREncoder.encode(msgType)
            let decoded = try XDRDecoder.decode(MessageTypeXDR.self, data: encoded)
            XCTAssertEqual(msgType, decoded, "MessageTypeXDR.\(msgType) failed round-trip")
        }
    }

    func testMessageTypeRawValuesStable() {
        XCTAssertEqual(MessageTypeXDR.errorMsg.rawValue, 0)
        XCTAssertEqual(MessageTypeXDR.auth.rawValue, 2)
        XCTAssertEqual(MessageTypeXDR.dontHave.rawValue, 3)
        XCTAssertEqual(MessageTypeXDR.peers.rawValue, 5)
        XCTAssertEqual(MessageTypeXDR.hello.rawValue, 13)
        XCTAssertEqual(MessageTypeXDR.sendMore.rawValue, 16)
        XCTAssertEqual(MessageTypeXDR.generalizedTxSet.rawValue, 17)
        XCTAssertEqual(MessageTypeXDR.floodAdvert.rawValue, 18)
        XCTAssertEqual(MessageTypeXDR.floodDemand.rawValue, 19)
        XCTAssertEqual(MessageTypeXDR.sendMoreExtended.rawValue, 20)
        XCTAssertEqual(MessageTypeXDR.timeSlicedSurveyRequest.rawValue, 21)
        XCTAssertEqual(MessageTypeXDR.timeSlicedSurveyResponse.rawValue, 22)
        XCTAssertEqual(MessageTypeXDR.timeSlicedSurveyStartCollecting.rawValue, 23)
        XCTAssertEqual(MessageTypeXDR.timeSlicedSurveyStopCollecting.rawValue, 24)
    }

    // MARK: - DontHaveXDR (struct, no Equatable)

    func testDontHaveRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let original = DontHaveXDR(type: .txSet, reqHash: hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DontHaveXDR.self, data: encoded)
        XCTAssertEqual(decoded.type, .txSet)
        XCTAssertEqual(decoded.reqHash.wrapped, hash.wrapped)
    }

    func testDontHaveTransactionRoundTrip() throws {
        let hash = WrappedData32(Data(repeating: 0x42, count: 32))
        let original = DontHaveXDR(type: .transaction, reqHash: hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DontHaveXDR.self, data: encoded)
        XCTAssertEqual(decoded.type, .transaction)
        XCTAssertEqual(decoded.reqHash.wrapped, hash.wrapped)
    }

    func testDontHaveScpQuorumsetRoundTrip() throws {
        let hash = WrappedData32(Data(repeating: 0xFF, count: 32))
        let original = DontHaveXDR(type: .scpQuorumset, reqHash: hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DontHaveXDR.self, data: encoded)
        XCTAssertEqual(decoded.type, .scpQuorumset)
        XCTAssertEqual(decoded.reqHash.wrapped, hash.wrapped)
    }

    // MARK: - Curve25519PublicXDR (struct, no Equatable)

    func testCurve25519PublicRoundTrip() throws {
        let keyData = WrappedData32(Data(repeating: 0x77, count: 32))
        let original = Curve25519PublicXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Curve25519PublicXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyData.wrapped)
    }

    // MARK: - AuthCertXDR (struct, no Equatable)

    func testAuthCertRoundTrip() throws {
        let pubkey = sampleCurve25519Public()
        let expiration: UInt64 = 1700000000
        let sig = Data(repeating: 0xAB, count: 64)
        let original = AuthCertXDR(pubkey: pubkey, expiration: expiration, sig: sig)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthCertXDR.self, data: encoded)
        XCTAssertEqual(decoded.pubkey.key.wrapped, pubkey.key.wrapped)
        XCTAssertEqual(decoded.expiration, expiration)
        XCTAssertEqual(decoded.sig, sig)
    }

    func testAuthCertZeroExpirationRoundTrip() throws {
        let pubkey = Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0x11, count: 32)))
        let original = AuthCertXDR(pubkey: pubkey, expiration: 0, sig: Data([0x01, 0x02]))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthCertXDR.self, data: encoded)
        XCTAssertEqual(decoded.pubkey.key.wrapped, pubkey.key.wrapped)
        XCTAssertEqual(decoded.expiration, 0)
        XCTAssertEqual(decoded.sig, Data([0x01, 0x02]))
    }

    func testAuthCertMaxExpirationRoundTrip() throws {
        let pubkey = sampleCurve25519Public()
        let original = AuthCertXDR(pubkey: pubkey, expiration: UInt64.max, sig: Data([0xFF]))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthCertXDR.self, data: encoded)
        XCTAssertEqual(decoded.expiration, UInt64.max)
        XCTAssertEqual(decoded.sig, Data([0xFF]))
    }

    // MARK: - HelloXDR (struct, no Equatable)

    func testHelloRoundTrip() throws {
        let peerID = try XDRTestHelpers.publicKey()
        let networkID = WrappedData32(Data(repeating: 0xDE, count: 32))
        let nonce = WrappedData32(Data(repeating: 0xCA, count: 32))
        let cert = sampleAuthCert()

        let original = HelloXDR(
            ledgerVersion: 21,
            overlayVersion: 33,
            overlayMinVersion: 30,
            networkID: networkID,
            versionStr: "stellar-core v21.0.0",
            listeningPort: 11625,
            peerID: peerID,
            cert: cert,
            nonce: nonce
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HelloXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerVersion, 21)
        XCTAssertEqual(decoded.overlayVersion, 33)
        XCTAssertEqual(decoded.overlayMinVersion, 30)
        XCTAssertEqual(decoded.networkID.wrapped, networkID.wrapped)
        XCTAssertEqual(decoded.versionStr, "stellar-core v21.0.0")
        XCTAssertEqual(decoded.listeningPort, 11625)
        XCTAssertEqual(decoded.nonce.wrapped, nonce.wrapped)
        // Verify nested AuthCert
        XCTAssertEqual(decoded.cert.expiration, cert.expiration)
        XCTAssertEqual(decoded.cert.pubkey.key.wrapped, cert.pubkey.key.wrapped)
    }

    func testHelloEmptyVersionStringRoundTrip() throws {
        let peerID = try XDRTestHelpers.publicKey()
        let cert = sampleAuthCert()
        let original = HelloXDR(
            ledgerVersion: 1,
            overlayVersion: 1,
            overlayMinVersion: 0,
            networkID: XDRTestHelpers.wrappedData32(),
            versionStr: "",
            listeningPort: 0,
            peerID: peerID,
            cert: cert,
            nonce: XDRTestHelpers.wrappedData32()
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HelloXDR.self, data: encoded)
        XCTAssertEqual(decoded.versionStr, "")
        XCTAssertEqual(decoded.listeningPort, 0)
        XCTAssertEqual(decoded.ledgerVersion, 1)
    }

    // MARK: - AuthXDR (struct, no Equatable)

    func testAuthFlagsZeroRoundTrip() throws {
        let original = AuthXDR(flags: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthXDR.self, data: encoded)
        XCTAssertEqual(decoded.flags, 0)
    }

    func testAuthFlagsFlowControlRoundTrip() throws {
        // AUTH_MSG_FLAG_FLOW_CONTROL_BYTES_REQUESTED = 200
        let original = AuthXDR(flags: 200)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthXDR.self, data: encoded)
        XCTAssertEqual(decoded.flags, 200)
    }

    func testAuthFlagsNegativeRoundTrip() throws {
        let original = AuthXDR(flags: -1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthXDR.self, data: encoded)
        XCTAssertEqual(decoded.flags, -1)
    }

    // MARK: - SendMoreXDR (struct, no Equatable)

    func testSendMoreRoundTrip() throws {
        let original = SendMoreXDR(numMessages: 42)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SendMoreXDR.self, data: encoded)
        XCTAssertEqual(decoded.numMessages, 42)
    }

    func testSendMoreZeroRoundTrip() throws {
        let original = SendMoreXDR(numMessages: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SendMoreXDR.self, data: encoded)
        XCTAssertEqual(decoded.numMessages, 0)
    }

    func testSendMoreMaxRoundTrip() throws {
        let original = SendMoreXDR(numMessages: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SendMoreXDR.self, data: encoded)
        XCTAssertEqual(decoded.numMessages, UInt32.max)
    }

    // MARK: - SendMoreExtendedXDR (struct, no Equatable)

    func testSendMoreExtendedRoundTrip() throws {
        let original = SendMoreExtendedXDR(numMessages: 100, numBytes: 65536)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SendMoreExtendedXDR.self, data: encoded)
        XCTAssertEqual(decoded.numMessages, 100)
        XCTAssertEqual(decoded.numBytes, 65536)
    }

    func testSendMoreExtendedZeroRoundTrip() throws {
        let original = SendMoreExtendedXDR(numMessages: 0, numBytes: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SendMoreExtendedXDR.self, data: encoded)
        XCTAssertEqual(decoded.numMessages, 0)
        XCTAssertEqual(decoded.numBytes, 0)
    }

    func testSendMoreExtendedMaxValuesRoundTrip() throws {
        let original = SendMoreExtendedXDR(numMessages: UInt32.max, numBytes: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SendMoreExtendedXDR.self, data: encoded)
        XCTAssertEqual(decoded.numMessages, UInt32.max)
        XCTAssertEqual(decoded.numBytes, UInt32.max)
    }

    // MARK: - TxAdvertVectorXDR (typedef wrapper, no Equatable)

    func testTxAdvertVectorEmptyRoundTrip() throws {
        let original = TxAdvertVectorXDR(wrapped: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TxAdvertVectorXDR.self, data: encoded)
        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    // MARK: - TxDemandVectorXDR (typedef wrapper, no Equatable)

    func testTxDemandVectorEmptyRoundTrip() throws {
        let original = TxDemandVectorXDR(wrapped: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TxDemandVectorXDR.self, data: encoded)
        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    // MARK: - FloodAdvertXDR (struct, no Equatable)

    func testFloodAdvertEmptyRoundTrip() throws {
        let original = FloodAdvertXDR(txHashes: TxAdvertVectorXDR(wrapped: []))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(FloodAdvertXDR.self, data: encoded)
        XCTAssertEqual(decoded.txHashes.wrapped.count, 0)
    }

    // MARK: - FloodDemandXDR (struct, no Equatable)

    func testFloodDemandEmptyRoundTrip() throws {
        let original = FloodDemandXDR(txHashes: TxDemandVectorXDR(wrapped: []))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(FloodDemandXDR.self, data: encoded)
        XCTAssertEqual(decoded.txHashes.wrapped.count, 0)
    }


    // MARK: - SurveyMessageCommandTypeXDR (simple enum, Equatable)

    func testSurveyMessageCommandTypeRoundTrip() throws {
        let original = SurveyMessageCommandTypeXDR.timeSlicedSurveyTopology
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyMessageCommandTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.rawValue, 1)
    }

    // MARK: - SurveyMessageResponseTypeXDR (simple enum, Equatable)

    func testSurveyMessageResponseTypeRoundTrip() throws {
        let original = SurveyMessageResponseTypeXDR.surveyTopologyResponseV2
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SurveyMessageResponseTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.rawValue, 2)
    }

    // MARK: - HmacSha256MacXDR (struct, no Equatable)
    // Note: HmacSha256MacXDR is already tested in XDRTypesUnitTests.swift.
    // Including one test here for completeness within the overlay types context.

    func testHmacSha256MacOverlayContextRoundTrip() throws {
        let macData = WrappedData32(Data(repeating: 0x99, count: 32))
        let original = HmacSha256MacXDR(mac: macData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HmacSha256MacXDR.self, data: encoded)
        XCTAssertEqual(decoded.mac.wrapped, macData.wrapped)
    }

    // MARK: - AuthenticatedMessageXDR (union, no Equatable)
    // Note: AuthenticatedMessageXDR.v0 contains StellarMessageXDR (the big union).
    // We skip deep testing of StellarMessage itself but test with a simple arm.

    func testAuthenticatedMessageV0WithSendMoreRoundTrip() throws {
        let sendMore = SendMoreXDR(numMessages: 10)
        let stellarMsg = StellarMessageXDR.sendMoreMessage(sendMore)
        let mac = HmacSha256MacXDR(mac: XDRTestHelpers.wrappedData32())
        let v0 = AuthenticatedMessageXDRV0XDR(
            sequence: 42,
            message: stellarMsg,
            mac: mac
        )
        let original = AuthenticatedMessageXDR.v0(v0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthenticatedMessageXDR.self, data: encoded)
        if case .v0(let decodedV0) = decoded {
            XCTAssertEqual(decodedV0.sequence, 42)
            XCTAssertEqual(decodedV0.mac.mac.wrapped, mac.mac.wrapped)
            if case .sendMoreMessage(let sm) = decodedV0.message {
                XCTAssertEqual(sm.numMessages, 10)
            } else {
                XCTFail("Expected .sendMoreMessage")
            }
        } else {
            XCTFail("Expected .v0")
        }
    }

    func testAuthenticatedMessageV0TypeDiscriminant() {
        let v0 = AuthenticatedMessageXDRV0XDR(
            sequence: 0,
            message: .sendMoreMessage(SendMoreXDR(numMessages: 1)),
            mac: HmacSha256MacXDR(mac: XDRTestHelpers.wrappedData32())
        )
        let msg = AuthenticatedMessageXDR.v0(v0)
        XCTAssertEqual(msg.type(), 0)
    }

    // MARK: - AuthenticatedMessageXDRV0XDR (struct, no Equatable)

    func testAuthenticatedMessageV0StructWithAuthRoundTrip() throws {
        let auth = AuthXDR(flags: 200)
        let stellarMsg = StellarMessageXDR.auth(auth)
        let mac = HmacSha256MacXDR(mac: WrappedData32(Data(repeating: 0x01, count: 32)))
        let original = AuthenticatedMessageXDRV0XDR(
            sequence: 100,
            message: stellarMsg,
            mac: mac
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AuthenticatedMessageXDRV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.sequence, 100)
        if case .auth(let decodedAuth) = decoded.message {
            XCTAssertEqual(decodedAuth.flags, 200)
        } else {
            XCTFail("Expected .auth message")
        }
    }
}
