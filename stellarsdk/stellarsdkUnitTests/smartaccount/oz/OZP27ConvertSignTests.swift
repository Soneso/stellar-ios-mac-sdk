//
//  OZP27ConvertSignTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Credential-arm handling and errors in `convertAndSignAuthEntries` under Protocol 27.
//

import XCTest
@testable import stellarsdk

/// Verifies that the credential helpers (`addressCredentials`, `withAddressCredentials`,
/// `buildPreimage`) behave correctly for the WITH_DELEGATES and ADDRESS_V2 arms; these
/// are the invariants that the OZTransactionOperations signing loop relies on.
final class OZP27ConvertSignTests: XCTestCase {

    // MARK: WITH_DELEGATES exposes addressCredentials and has correct arm

    /// WITH_DELEGATES entries expose their inner address credentials via `addressCredentials`.
    /// The signing loop uses this accessor to detect WITH_DELEGATES entries and reject them
    /// with a descriptive error.
    func test_withDelegatesEntry_exposesAddressCredentials() throws {
        let delegatesEntry = try OZP27GoldenVector.makeAddressWithDelegatesEntry()

        guard case .addressWithDelegates = delegatesEntry.credentials else {
            XCTFail("Test fixture must carry .addressWithDelegates credentials")
            return
        }

        guard let inner = delegatesEntry.credentials.addressCredentials else {
            XCTFail("WITH_DELEGATES entry must expose inner address credentials via addressCredentials")
            return
        }
        XCTAssertEqual(inner.nonce, OZP27GoldenVector.nonce)
    }

    // MARK: ADDRESS_V2 arm preserved through convertAndSignAuthEntries

    /// In the funding flow, ADDRESS_V2 entries are handled like ADDRESS but with the V2 arm
    /// preserved on write-back. This confirms that `withAddressCredentials` preserves the V2
    /// arm, which is the invariant the convertAndSignAuthEntries code relies on.
    func test_withAddressCredentials_v2ArmPreserved() throws {
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
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
        let entry = try OZP27GoldenVector.makeAddressV2Entry()
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
        let delegatesEntry = try OZP27GoldenVector.makeAddressWithDelegatesEntry()

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
