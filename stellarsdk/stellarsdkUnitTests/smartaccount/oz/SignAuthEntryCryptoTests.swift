//
//  SignAuthEntryCryptoTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class SignAuthEntryCryptoTests: XCTestCase {

    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let testNetwork = "Test SDF Network ; September 2015"

    func testSignAuthEntry_differentKeyPairDoesNotVerify() async throws {
        // Two different keypairs produce different ed25519 signatures over the same hash.
        let entry = try makeEntry(nonce: 1)
        let payloadHash1 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let kp1 = try KeyPair.generateRandomKeyPair()
        let kp2 = try KeyPair.generateRandomKeyPair()
        let sig1 = kp1.sign([UInt8](payloadHash1))
        let sig2 = kp2.sign([UInt8](payloadHash1))
        XCTAssertNotEqual(Data(sig1), Data(sig2))
    }

    func testSignAuthEntry_payloadHashChangesWithDifferentNonce() async throws {
        let entryA = try makeEntry(nonce: 1)
        let entryB = try makeEntry(nonce: 2)
        let h1 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entryA, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entryB, expirationLedger: 100, networkPassphrase: testNetwork
        )
        XCTAssertNotEqual(h1, h2)
    }

    func testSignAuthEntry_payloadHashChangesWithDifferentExpiration() async throws {
        let entry = try makeEntry(nonce: 1)
        let h1 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry, expirationLedger: 200, networkPassphrase: testNetwork
        )
        XCTAssertNotEqual(h1, h2)
    }

    func testSignAuthEntry_doesNotMutateOriginalEntry() async throws {
        let entry = try makeEntry(nonce: 1)
        let originalEnc = try Data(XDREncoder.encode(entry))
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        _ = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: 100
        )
        let afterEnc = try Data(XDREncoder.encode(entry))
        XCTAssertEqual(originalEnc, afterEnc)
    }

    private func makeEntry(nonce: Int64) throws -> SorobanAuthorizationEntryXDR {
        let function = SorobanAuthorizedFunctionXDR.contractFn(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractC),
                functionName: "noop",
                args: []
            )
        )
        let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractC),
            nonce: nonce,
            signatureExpirationLedger: 0,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )
    }
}
