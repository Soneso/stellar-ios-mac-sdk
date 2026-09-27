//
//  OZP27SignAuthEntryArmTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Credential-arm preservation in `signAuthEntry` under Protocol 27.
//

import XCTest
@testable import stellarsdk

final class OZP27SignAuthEntryArmTests: XCTestCase {

    private let testNetwork = OZP27GoldenVector.network

    // MARK: ADDRESS arm preserved

    func test_signAuthEntry_addressArm_preserved() async throws {
        let entry = try OZP27GoldenVector.makeAddressEntry()
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        let signed = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: OZP27GoldenVector.expiration
        )
        if case .address = signed.credentials {
            // arm preserved, pass
        } else {
            XCTFail("Expected .address arm, got \(signed.credentials)")
        }
    }

    // MARK: ADDRESS_V2 arm preserved

    /// An ADDRESS_V2 entry must come out as ADDRESS_V2 after signing; the method must never
    /// coerce it to the legacy ADDRESS arm.
    func test_signAuthEntry_addressV2Arm_preserved() async throws {
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
        let signer = try OZDelegatedSigner(address: try KeyPair.generateRandomKeyPair().accountId)
        let signed = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: OZP27GoldenVector.expiration
        )
        if case .addressV2 = signed.credentials {
            // arm preserved, pass
        } else {
            XCTFail("Expected .addressV2 arm, got \(signed.credentials)")
        }
    }

    // MARK: ADDRESS_V2 carries a WITH_ADDRESS-based hash

    /// The payload hash produced for an ADDRESS_V2 entry must be the WITH_ADDRESS hash,
    /// which differs from the legacy ADDRESS hash for the same underlying fields.
    func test_signAuthEntry_addressV2_usesWithAddressHash() async throws {
        let legacyEntry = try OZP27GoldenVector.makeAddressEntry()
        let v2Entry    = try OZP27GoldenVector.makeAddressV2Entry()

        let legacyHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: legacyEntry,
            expirationLedger: OZP27GoldenVector.expiration,
            networkPassphrase: testNetwork
        )
        let v2Hash = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: v2Entry,
            expirationLedger: OZP27GoldenVector.expiration,
            networkPassphrase: testNetwork
        )
        // The hashes must differ because the V2 preimage includes an address field.
        XCTAssertNotEqual(legacyHash, v2Hash)
    }

    // MARK: Expiration stamped on write-back

    /// The returned entry must carry the new expiration ledger regardless of the original
    /// value stored in the credentials.
    func test_signAuthEntry_expirationStampedOnWriteback() async throws {
        let entry = try OZP27GoldenVector.makeAddressEntry()
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
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
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
