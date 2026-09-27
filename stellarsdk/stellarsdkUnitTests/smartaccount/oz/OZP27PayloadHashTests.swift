//
//  OZP27PayloadHashTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Payload hash and preimage construction in the OZ smart-account signing paths under Protocol 27.
//

import XCTest
@testable import stellarsdk

final class OZP27PayloadHashTests: XCTestCase {

    // MARK: Golden-vector test

    /// Legacy ADDRESS preimage hash must match the cross-SDK golden vector.
    ///
    /// This test pins the byte-identity invariant: any future change to the ADDRESS preimage
    /// construction path that alters the hash will be caught immediately.
    func test_legacyAddressPreimageHash_matchesGoldenVector() async throws {
        let entry = try OZP27GoldenVector.makeAddressEntry()
        let hash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: OZP27GoldenVector.expiration,
            networkPassphrase: OZP27GoldenVector.network
        )
        XCTAssertEqual(
            hash.hexEncodedString(),
            OZP27GoldenVector.legacyPreimageHashHex,
            "Legacy ADDRESS preimage hash does not match the golden vector"
        )
    }

    // MARK: V2 arm produces a different hash from legacy for identical fields

    /// ADDRESS_V2 uses ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS, which includes an
    /// address field absent from the legacy arm. For otherwise identical credentials the two
    /// preimage hashes must differ.
    func test_addressV2PreimageHash_differsFromLegacy() async throws {
        let legacyEntry = try OZP27GoldenVector.makeAddressEntry()
        let v2Entry    = try OZP27GoldenVector.makeAddressV2Entry()

        let legacyHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: legacyEntry,
            expirationLedger: OZP27GoldenVector.expiration,
            networkPassphrase: OZP27GoldenVector.network
        )
        let v2Hash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: v2Entry,
            expirationLedger: OZP27GoldenVector.expiration,
            networkPassphrase: OZP27GoldenVector.network
        )
        XCTAssertNotEqual(
            legacyHash, v2Hash,
            "ADDRESS_V2 and ADDRESS must produce different hashes for identical fields"
        )
    }

    // MARK: Expiration is bound into the hash before signing

    /// The preimage is built from the expiration passed to `buildAuthPayloadHash`, not from the
    /// stale expiration stored in the credentials. Changing the expiration must change the hash.
    func test_buildAuthPayloadHash_expirationBoundBeforeHashing() async throws {
        let entry = try OZP27GoldenVector.makeAddressEntry()
        let h1 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: 1000,
            networkPassphrase: OZP27GoldenVector.network
        )
        let h2 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: 2000,
            networkPassphrase: OZP27GoldenVector.network
        )
        XCTAssertNotEqual(h1, h2, "Different expirations must produce different hashes")
    }

    // MARK: Source-account entry throws

    func test_buildAuthPayloadHash_sourceAccountCredentials_throws() async throws {
        let contractAddress = try SCAddressXDR(contractId: OZP27GoldenVector.contractId)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "hello",
                args: []
            )),
            subInvocations: []
        )
        let sourceEntry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
        do {
            _ = try await OZSmartAccountAuth.buildAuthPayloadHash(
                entry: sourceEntry,
                expirationLedger: 100,
                networkPassphrase: OZP27GoldenVector.network
            )
            XCTFail("Expected throw for source-account credentials")
        } catch is SmartAccountTransactionException {
            // Expected: source-account credentials are not signable via this path.
        }
    }
}

// MARK: - Data hex helper (test-only)

private extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
