//
//  SorobanP27XDRCodecUnitTests.swift
//  stellarsdkUnitTests
//
//  Covers the XDR decode and TxRep roundtrip paths for the protocol-27 XDR types:
//  - HashIDPreimageSorobanAuthorizationWithAddressXDR (init(from decoder:))
//  - HashIDPreimageXDR decoding of the sorobanAuthorizationWithAddress arm
//  - SorobanAddressCredentialsWithDelegatesXDR TxRep with non-empty delegates
//  - SorobanDelegateSignatureXDR TxRep with non-empty nestedDelegates
//

import XCTest
@testable import stellarsdk

final class SorobanP27XDRCodecUnitTests: XCTestCase {

    // Fixed inputs for all tests.
    private let contractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
    private let accountId  = "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D"

    // MARK: - HashIDPreimageSorobanAuthorizationWithAddressXDR XDR decode roundtrip

    /// Exercises `init(from decoder:)` by encoding a value then decoding it back.
    /// This is the XDR deserialisation path that was not reached by encoding-only tests.
    func testHashIDPreimageWithAddressXDRDecodeRoundtrip() throws {
        let networkID = WrappedData32(Data(repeating: 0xAB, count: 32))
        let address = try SCAddressXDR(accountId: accountId)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: contractId),
                functionName: "hello",
                args: [.u64(1234)]
            )),
            subInvocations: []
        )
        let original = HashIDPreimageSorobanAuthorizationWithAddressXDR(
            networkID: networkID,
            nonce: 999,
            signatureExpirationLedger: 100,
            address: address,
            invocation: invocation
        )

        // Encode to bytes then decode back via init(from decoder:).
        let encoded = try XDREncoder.encode(original)
        let decoded = try HashIDPreimageSorobanAuthorizationWithAddressXDR(
            from: XDRDecoder(data: encoded)
        )
        let reEncoded = try XDREncoder.encode(decoded)

        XCTAssertEqual(Data(encoded), Data(reEncoded),
                       "HashIDPreimageSorobanAuthorizationWithAddressXDR must survive XDR encode/decode roundtrip")
        XCTAssertEqual(decoded.nonce, 999)
        XCTAssertEqual(decoded.signatureExpirationLedger, 100)
    }

    // MARK: - HashIDPreimageXDR: sorobanAuthorizationWithAddress arm decode

    /// Exercises `HashIDPreimageXDR.init(from decoder:)` for the
    /// `sorobanAuthorizationWithAddress` discriminant (10).
    func testHashIDPreimageXDRDecodesWithAddressArm() throws {
        let networkID = WrappedData32(Data(repeating: 0xCD, count: 32))
        let address = try SCAddressXDR(contractId: contractId)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: address,
                functionName: "fn",
                args: []
            )),
            subInvocations: []
        )
        let body = HashIDPreimageSorobanAuthorizationWithAddressXDR(
            networkID: networkID,
            nonce: 77,
            signatureExpirationLedger: 200,
            address: address,
            invocation: invocation
        )
        let original = HashIDPreimageXDR.sorobanAuthorizationWithAddress(body)

        let encoded = try XDREncoder.encode(original)
        let decoded = try HashIDPreimageXDR(from: XDRDecoder(data: encoded))

        guard case .sorobanAuthorizationWithAddress(let decodedBody) = decoded else {
            XCTFail("Decoded HashIDPreimageXDR must be .sorobanAuthorizationWithAddress")
            return
        }
        XCTAssertEqual(decodedBody.nonce, 77)
        XCTAssertEqual(decodedBody.signatureExpirationLedger, 200)
    }

    // MARK: - SorobanAddressCredentialsWithDelegatesXDR TxRep with non-empty delegates

    /// The `toTxRep` and `fromTxRep` loop bodies in `SorobanAddressCredentialsWithDelegatesXDR`
    /// are only exercised when the `delegates` array is non-empty.
    func testSorobanAddressCredentialsWithDelegatesTxRepNonEmpty() throws {
        let accountAddr = try SCAddressXDR(accountId: accountId)
        let contractAddr = try SCAddressXDR(contractId: contractId)

        let delegate = SorobanDelegateSignatureXDR(
            address: contractAddr,
            signature: .void,
            nestedDelegates: []
        )
        let innerCreds = SorobanAddressCredentialsXDR(
            address: accountAddr,
            nonce: 55,
            signatureExpirationLedger: 500,
            signature: .void
        )
        let original = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: innerCreds,
            delegates: [delegate]
        )

        var lines: [String] = []
        try original.toTxRep(prefix: "test", lines: &lines)
        XCTAssertFalse(lines.isEmpty, "toTxRep must produce output")

        // Verify the delegate entry is present in TxRep output.
        let delegateLenLine = lines.first { $0.contains("delegates.len") }
        XCTAssertNotNil(delegateLenLine, "TxRep must contain a delegates.len line")
        XCTAssertTrue(delegateLenLine?.contains("1") == true, "delegates.len must be 1")

        // Parse and roundtrip via fromTxRep.
        var map: [String: String] = [:]
        for line in lines {
            if let range = line.range(of: ": ") {
                let key = String(line[..<range.lowerBound])
                let value = String(line[range.upperBound...])
                map[key] = value
            }
        }
        let back = try SorobanAddressCredentialsWithDelegatesXDR.fromTxRep(map, prefix: "test")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "SorobanAddressCredentialsWithDelegatesXDR TxRep roundtrip with non-empty delegates must match")
    }

    // MARK: - SorobanDelegateSignatureXDR TxRep with non-empty nestedDelegates

    /// The `toTxRep` and `fromTxRep` loop bodies in `SorobanDelegateSignatureXDR`
    /// are only exercised when `nestedDelegates` is non-empty.
    func testSorobanDelegateSignatureXDRTxRepNonEmpty() throws {
        let contractAddr = try SCAddressXDR(contractId: contractId)
        let accountAddr  = try SCAddressXDR(accountId: accountId)

        // Level 2 (nested delegate).
        let innerDelegate = SorobanDelegateSignatureXDR(
            address: accountAddr,
            signature: .void,
            nestedDelegates: []
        )
        // Level 1 (delegate with one nested delegate).
        let original = SorobanDelegateSignatureXDR(
            address: contractAddr,
            signature: .void,
            nestedDelegates: [innerDelegate]
        )

        var lines: [String] = []
        try original.toTxRep(prefix: "d", lines: &lines)
        XCTAssertFalse(lines.isEmpty, "toTxRep must produce output")

        // Verify the nestedDelegates entry appears in TxRep.
        let nestedLenLine = lines.first { $0.contains("nestedDelegates.len") }
        XCTAssertNotNil(nestedLenLine, "TxRep must contain a nestedDelegates.len line")
        XCTAssertTrue(nestedLenLine?.contains("1") == true, "nestedDelegates.len must be 1")

        // Roundtrip.
        var map: [String: String] = [:]
        for line in lines {
            if let range = line.range(of: ": ") {
                let key = String(line[..<range.lowerBound])
                let value = String(line[range.upperBound...])
                map[key] = value
            }
        }
        let back = try SorobanDelegateSignatureXDR.fromTxRep(map, prefix: "d")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64,
                       "SorobanDelegateSignatureXDR TxRep roundtrip with non-empty nestedDelegates must match")
    }

    // MARK: - SorobanAddressCredentialsWithDelegatesXDR XDR decode with non-empty delegates

    /// Verifies XDR encode/decode for `SorobanAddressCredentialsWithDelegatesXDR` with
    /// a non-empty `delegates` array, confirming each delegate node survives the codec.
    func testSorobanAddressCredentialsWithDelegatesXDRDecodeNonEmpty() throws {
        let accountAddr = try SCAddressXDR(accountId: accountId)
        let contractAddr = try SCAddressXDR(contractId: contractId)

        let delegate = SorobanDelegateSignatureXDR(
            address: accountAddr,
            signature: .void,
            nestedDelegates: []
        )
        let innerCreds = SorobanAddressCredentialsXDR(
            address: contractAddr,
            nonce: 11,
            signatureExpirationLedger: 300,
            signature: .void
        )
        let original = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: innerCreds,
            delegates: [delegate]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try SorobanAddressCredentialsWithDelegatesXDR(from: XDRDecoder(data: encoded))
        let reEncoded = try XDREncoder.encode(decoded)

        XCTAssertEqual(Data(encoded), Data(reEncoded),
                       "SorobanAddressCredentialsWithDelegatesXDR must survive XDR roundtrip with non-empty delegates")
        XCTAssertEqual(decoded.delegates.count, 1)
    }
}
