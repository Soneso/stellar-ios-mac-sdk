//
//  OZP27AuthTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Credential-arm handling and preimage construction in the OZ smart-account
//  signing paths under Protocol 27.
//

import XCTest
@testable import stellarsdk

// MARK: - Helpers

/// Builds a minimal SorobanAuthorizationEntryXDR for fixed parameters used across
/// the golden-vector and arm-handling tests.
///
/// Golden vector parameters (normative — must not be changed):
///   network:     "Test SDF Network ; September 2015"
///   nonce:       123456789101112
///   expiration:  4242
///   contract:    CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE
///   fn:          hello(u64 1234)
///
/// Expected legacy ADDRESS sha256 (hex):
///   120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe
private enum GoldenVector {
    static let network = "Test SDF Network ; September 2015"
    static let nonce: Int64 = 123456789101112
    static let expiration: UInt32 = 4242
    static let contractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

    /// Hex-encoded SHA-256 of the legacy ADDRESS preimage for the parameters above.
    static let legacyPreimageHashHex =
        "120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe"

    /// Builds the fixed test entry with the legacy ADDRESS arm.
    static func makeAddressEntry() throws -> SorobanAuthorizationEntryXDR {
        let contractAddress = try SCAddressXDR(contractId: contractId)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "hello",
                args: [.u64(1234)]
            )),
            subInvocations: []
        )
        let creds = SorobanAddressCredentialsXDR(
            address: contractAddress,
            nonce: nonce,
            signatureExpirationLedger: expiration,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(creds),
            rootInvocation: invocation
        )
    }

    /// Builds the same fixed entry but with the ADDRESS_V2 arm.
    static func makeAddressV2Entry() throws -> SorobanAuthorizationEntryXDR {
        var entry = try makeAddressEntry()
        let creds = entry.credentials.addressCredentials!
        entry.credentials = .addressV2(creds)
        return entry
    }

    /// Builds the same fixed entry but with the ADDRESS_WITH_DELEGATES arm (empty delegates).
    static func makeAddressWithDelegatesEntry() throws -> SorobanAuthorizationEntryXDR {
        var entry = try makeAddressEntry()
        let creds = entry.credentials.addressCredentials!
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: creds,
            delegates: []
        )
        entry.credentials = .addressWithDelegates(withDelegates)
        return entry
    }
}

// MARK: - Payload hash / preimage tests

final class OZP27PayloadHashTests: XCTestCase {

    // MARK: Golden-vector test

    /// Legacy ADDRESS preimage hash must match the cross-SDK golden vector.
    ///
    /// This test pins the byte-identity invariant: any future change to the ADDRESS preimage
    /// construction path that alters the hash will be caught immediately.
    func test_legacyAddressPreimageHash_matchesGoldenVector() async throws {
        let entry = try GoldenVector.makeAddressEntry()
        let hash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: GoldenVector.expiration,
            networkPassphrase: GoldenVector.network
        )
        XCTAssertEqual(
            hash.hexEncodedString(),
            GoldenVector.legacyPreimageHashHex,
            "Legacy ADDRESS preimage hash does not match the golden vector"
        )
    }

    // MARK: V2 arm produces a different hash from legacy for identical fields

    /// ADDRESS_V2 uses ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS, which includes an
    /// address field absent from the legacy arm. For otherwise identical credentials the two
    /// preimage hashes must differ.
    func test_addressV2PreimageHash_differsFromLegacy() async throws {
        let legacyEntry = try GoldenVector.makeAddressEntry()
        let v2Entry    = try GoldenVector.makeAddressV2Entry()

        let legacyHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: legacyEntry,
            expirationLedger: GoldenVector.expiration,
            networkPassphrase: GoldenVector.network
        )
        let v2Hash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: v2Entry,
            expirationLedger: GoldenVector.expiration,
            networkPassphrase: GoldenVector.network
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
        let entry = try GoldenVector.makeAddressEntry()
        let h1 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: 1000,
            networkPassphrase: GoldenVector.network
        )
        let h2 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: 2000,
            networkPassphrase: GoldenVector.network
        )
        XCTAssertNotEqual(h1, h2, "Different expirations must produce different hashes")
    }

    // MARK: Source-account entry throws

    func test_buildAuthPayloadHash_sourceAccountCredentials_throws() async throws {
        let contractAddress = try SCAddressXDR(contractId: GoldenVector.contractId)
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
                networkPassphrase: GoldenVector.network
            )
            XCTFail("Expected throw for source-account credentials")
        } catch is SmartAccountTransactionException {
            // Expected — source-account credentials are not signable via this path.
        }
    }
}

// MARK: - signAuthEntry arm-preservation tests

final class OZP27SignAuthEntryArmTests: XCTestCase {

    private let testNetwork = GoldenVector.network

    // MARK: ADDRESS arm preserved

    func test_signAuthEntry_addressArm_preserved() async throws {
        let entry = try GoldenVector.makeAddressEntry()
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        let signed = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: GoldenVector.expiration
        )
        if case .address = signed.credentials {
            // arm preserved — pass
        } else {
            XCTFail("Expected .address arm, got \(signed.credentials)")
        }
    }

    // MARK: ADDRESS_V2 arm preserved

    /// An ADDRESS_V2 entry must come out as ADDRESS_V2 after signing; the method must never
    /// coerce it to the legacy ADDRESS arm.
    func test_signAuthEntry_addressV2Arm_preserved() async throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        let signed = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: GoldenVector.expiration
        )
        if case .addressV2 = signed.credentials {
            // arm preserved — pass
        } else {
            XCTFail("Expected .addressV2 arm, got \(signed.credentials)")
        }
    }

    // MARK: ADDRESS_V2 carries a WITH_ADDRESS-based hash

    /// The payload hash produced for an ADDRESS_V2 entry must be the WITH_ADDRESS hash,
    /// which differs from the legacy ADDRESS hash for the same underlying fields.
    func test_signAuthEntry_addressV2_usesWithAddressHash() async throws {
        let legacyEntry = try GoldenVector.makeAddressEntry()
        let v2Entry    = try GoldenVector.makeAddressV2Entry()

        let legacyHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: legacyEntry,
            expirationLedger: GoldenVector.expiration,
            networkPassphrase: testNetwork
        )
        let v2Hash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: v2Entry,
            expirationLedger: GoldenVector.expiration,
            networkPassphrase: testNetwork
        )
        // The hashes must differ because the V2 preimage includes an address field.
        XCTAssertNotEqual(legacyHash, v2Hash)
    }

    // MARK: Expiration stamped on write-back

    /// The returned entry must carry the new expiration ledger regardless of the original
    /// value stored in the credentials.
    func test_signAuthEntry_expirationStampedOnWriteback() async throws {
        let entry = try GoldenVector.makeAddressEntry()
        // Original entry has expiration 4242; request a different value.
        let newExpiration: UInt32 = 9999
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        let signed = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: newExpiration
        )
        XCTAssertEqual(signed.credentials.addressCredentials?.signatureExpirationLedger, newExpiration)
    }

    // MARK: V2 entry expiration preserved with V2 arm

    func test_signAuthEntry_addressV2_expirationStampedArmPreserved() async throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        let newExpiration: UInt32 = 8888
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        let signed = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: newExpiration
        )
        guard case .addressV2 = signed.credentials else {
            XCTFail("Expected .addressV2 arm after signing, got \(signed.credentials)")
            return
        }
        XCTAssertEqual(signed.credentials.addressCredentials?.signatureExpirationLedger, newExpiration)
    }
}

// MARK: - addRawSignatureMapEntry arm-preservation tests

final class OZP27AddRawEntryTests: XCTestCase {

    // MARK: ADDRESS arm preserved

    func test_addRawSignatureMapEntry_addressArm_preserved() throws {
        let entry = try GoldenVector.makeAddressEntry()
        let delegatedSignerAddress = try KeyPair.generateRandomKeyPair().accountId
        let delegatedSigner = try OZDelegatedSigner(address: delegatedSignerAddress)
        let signerKey = try delegatedSigner.toScVal()
        let sigValue: SCValXDR = .bytes(Data([0x01, 0x02]))
        let updated = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: signerKey,
            signatureValue: sigValue
        )
        if case .address = updated.credentials {
            // arm preserved — pass
        } else {
            XCTFail("Expected .address arm, got \(updated.credentials)")
        }
    }

    // MARK: ADDRESS_V2 arm preserved

    func test_addRawSignatureMapEntry_addressV2Arm_preserved() throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        let delegatedSignerAddress = try KeyPair.generateRandomKeyPair().accountId
        let delegatedSigner = try OZDelegatedSigner(address: delegatedSignerAddress)
        let signerKey = try delegatedSigner.toScVal()
        let sigValue: SCValXDR = .bytes(Data([0x01, 0x02]))
        let updated = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: signerKey,
            signatureValue: sigValue
        )
        if case .addressV2 = updated.credentials {
            // arm preserved — pass
        } else {
            XCTFail("Expected .addressV2 arm, got \(updated.credentials)")
        }
    }
}

// MARK: - convertAndSignAuthEntries arm and error tests

/// Verifies that the credential helpers (`addressCredentials`, `withAddressCredentials`,
/// `buildPreimage`) behave correctly for the WITH_DELEGATES and ADDRESS_V2 arms — these
/// are the invariants that the OZTransactionOperations signing loop relies on.
final class OZP27ConvertSignTests: XCTestCase {

    // MARK: WITH_DELEGATES exposes addressCredentials and has correct arm

    /// WITH_DELEGATES entries expose their inner address credentials via `addressCredentials`.
    /// The signing loop uses this accessor to detect WITH_DELEGATES entries and reject them
    /// with a descriptive error.
    func test_withDelegatesEntry_exposesAddressCredentials() throws {
        let delegatesEntry = try GoldenVector.makeAddressWithDelegatesEntry()

        guard case .addressWithDelegates = delegatesEntry.credentials else {
            XCTFail("Test fixture must carry .addressWithDelegates credentials")
            return
        }

        guard let inner = delegatesEntry.credentials.addressCredentials else {
            XCTFail("WITH_DELEGATES entry must expose inner address credentials via addressCredentials")
            return
        }
        XCTAssertEqual(inner.nonce, GoldenVector.nonce)
    }

    // MARK: ADDRESS_V2 arm preserved through convertAndSignAuthEntries

    /// In the funding flow, ADDRESS_V2 entries are handled like ADDRESS but with the V2 arm
    /// preserved on write-back. This confirms that `withAddressCredentials` preserves the V2
    /// arm, which is the invariant the convertAndSignAuthEntries code relies on.
    func test_withAddressCredentials_v2ArmPreserved() throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        guard let creds = entry.credentials.addressCredentials else {
            XCTFail("V2 entry must expose addressCredentials")
            return
        }
        var updatedCreds = creds
        updatedCreds.signatureExpirationLedger = 9999
        let updated = try entry.credentials.withAddressCredentials(updatedCreds)
        if case .addressV2(let resultCreds) = updated {
            XCTAssertEqual(resultCreds.signatureExpirationLedger, 9999)
        } else {
            XCTFail("withAddressCredentials must preserve .addressV2 arm, got \(updated)")
        }
    }

    // MARK: Expiration stamp preserves V2 arm

    /// Stamping an expiration ledger onto an ADDRESS_V2 entry via `withAddressCredentials`
    /// must produce an ADDRESS_V2 result, never a legacy ADDRESS result.
    func test_expirationStamp_addressV2_armPreserved() throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        guard var creds = entry.credentials.addressCredentials else {
            XCTFail("V2 entry must expose addressCredentials")
            return
        }
        creds.signatureExpirationLedger = 5050
        let stamped = try entry.credentials.withAddressCredentials(creds)
        guard case .addressV2 = stamped else {
            XCTFail("Expiration stamp must not coerce .addressV2 to .address, got \(stamped)")
            return
        }
        XCTAssertEqual(stamped.addressCredentials?.signatureExpirationLedger, 5050)
    }

    // MARK: WITH_DELEGATES arm detected correctly

    /// Verifies the documented behavior: a WITH_DELEGATES entry is detected as
    /// `.addressWithDelegates` by Swift pattern matching, which is the guard the signing
    /// loops use to produce their descriptive error.
    func test_withDelegatesArm_detectedCorrectly() throws {
        let delegatesEntry = try GoldenVector.makeAddressWithDelegatesEntry()

        var didDetectWithDelegates = false
        if case .addressWithDelegates = delegatesEntry.credentials {
            didDetectWithDelegates = true
        }
        XCTAssertTrue(didDetectWithDelegates,
            "WITH_DELEGATES entry must be detected as .addressWithDelegates arm")

        XCTAssertNotNil(delegatesEntry.credentials.addressCredentials,
            "WITH_DELEGATES entry must expose inner address credentials")
    }
}

// MARK: - Preimage builder arm-selection tests

/// Verifies that `buildPreimage(network:)` selects the correct envelope type for each
/// credential arm, independently of the higher-level signing paths.
final class OZP27PreimageBuilderTests: XCTestCase {

    private let network = Network.testnet

    // MARK: ADDRESS selects legacy envelope type

    func test_buildPreimage_addressArm_selectsLegacyEnvelopeType() throws {
        let entry = try GoldenVector.makeAddressEntry()
        let preimage = try entry.buildPreimage(network: network)
        if case .sorobanAuthorization = preimage {
            // correct envelope type — pass
        } else {
            XCTFail("ADDRESS arm must produce sorobanAuthorization preimage, got \(preimage)")
        }
    }

    // MARK: ADDRESS_V2 selects WITH_ADDRESS envelope type

    func test_buildPreimage_addressV2Arm_selectsWithAddressEnvelopeType() throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        let preimage = try entry.buildPreimage(network: network)
        if case .sorobanAuthorizationWithAddress = preimage {
            // correct envelope type — pass
        } else {
            XCTFail("ADDRESS_V2 arm must produce sorobanAuthorizationWithAddress preimage, got \(preimage)")
        }
    }

    // MARK: ADDRESS_WITH_DELEGATES selects WITH_ADDRESS envelope type

    func test_buildPreimage_withDelegatesArm_selectsWithAddressEnvelopeType() throws {
        let entry = try GoldenVector.makeAddressWithDelegatesEntry()
        let preimage = try entry.buildPreimage(network: network)
        if case .sorobanAuthorizationWithAddress = preimage {
            // correct envelope type — pass
        } else {
            XCTFail("ADDRESS_WITH_DELEGATES arm must produce sorobanAuthorizationWithAddress preimage, got \(preimage)")
        }
    }

    // MARK: ADDRESS and ADDRESS_V2 produce different hashes for identical credentials

    func test_buildPreimage_addressVsV2_produceDifferentHashes() throws {
        let addressEntry = try GoldenVector.makeAddressEntry()
        let v2Entry      = try GoldenVector.makeAddressV2Entry()

        let addressHash = try sha256OfPreimage(addressEntry)
        let v2Hash      = try sha256OfPreimage(v2Entry)

        XCTAssertNotEqual(addressHash, v2Hash,
            "ADDRESS and ADDRESS_V2 must produce different preimage hashes for identical credentials")
    }

    // MARK: ADDRESS_V2 and ADDRESS_WITH_DELEGATES produce same hash when delegates are empty

    /// Both V2 and WITH_DELEGATES (empty delegates) use the same preimage structure with the
    /// same address; the hashes must be equal when the top-level credentials are identical.
    func test_buildPreimage_v2AndEmptyWithDelegates_produceSameHash() throws {
        let v2Entry      = try GoldenVector.makeAddressV2Entry()
        let delegatesEntry = try GoldenVector.makeAddressWithDelegatesEntry()

        let v2Hash         = try sha256OfPreimage(v2Entry)
        let delegatesHash  = try sha256OfPreimage(delegatesEntry)

        XCTAssertEqual(v2Hash, delegatesHash,
            "ADDRESS_V2 and WITH_DELEGATES (empty) with identical credentials must produce the same preimage hash")
    }

    // MARK: Top-level address is embedded in WITH_ADDRESS preimage

    /// Verifies that the address field in the WITH_ADDRESS preimage is the top-level
    /// credential address, not a delegate address or zero bytes.
    func test_buildPreimage_withAddress_embedsTopLevelAddress() throws {
        let entry = try GoldenVector.makeAddressV2Entry()
        let preimage = try entry.buildPreimage(network: network)
        guard case .sorobanAuthorizationWithAddress(let body) = preimage else {
            XCTFail("Expected sorobanAuthorizationWithAddress")
            return
        }
        // The embedded address must equal the contract address used in the test fixture.
        let expectedAddress = try SCAddressXDR(contractId: GoldenVector.contractId)
        let encoded1 = try Data(XDREncoder.encode(body.address))
        let encoded2 = try Data(XDREncoder.encode(expectedAddress))
        XCTAssertEqual(encoded1, encoded2,
            "WITH_ADDRESS preimage must embed the top-level credential address")
    }

    // MARK: Helper

    private func sha256OfPreimage(_ entry: SorobanAuthorizationEntryXDR) throws -> Data {
        let preimage = try entry.buildPreimage(network: network)
        let encoded  = try Data(XDREncoder.encode(preimage))
        return encoded.sha256Hash
    }
}

// MARK: - Data hex helper (test-only)

private extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
