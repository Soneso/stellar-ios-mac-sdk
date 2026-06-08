//
//  OZConstantsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZConstantsTests: XCTestCase {

    func test_DEFAULT_SESSION_EXPIRY_MS_equals_604800000_ms_seven_days() {
        XCTAssertEqual(OZConstants.defaultSessionExpiryMs, 604_800_000)
    }

    func test_DEFAULT_INDEXER_TIMEOUT_MS_equals_10000() {
        XCTAssertEqual(OZConstants.defaultIndexerTimeoutMs, 10_000)
    }

    func test_DEFAULT_RELAYER_TIMEOUT_MS_equals_360000_ms_six_minutes() {
        XCTAssertEqual(OZConstants.defaultRelayerTimeoutMs, 360_000)
    }

    func test_FRIENDBOT_RESERVE_XLM_equals_5() {
        XCTAssertEqual(OZConstants.friendbotReserveXlm, 5)
    }

    func test_DEFAULT_TIMEOUT_SECONDS_equals_30() {
        XCTAssertEqual(OZConstants.defaultTimeoutSeconds, 30)
    }

    func test_MAX_SIGNERS_equals_15() {
        XCTAssertEqual(OZConstants.maxSigners, 15)
    }

    func test_MAX_POLICIES_equals_5() {
        XCTAssertEqual(OZConstants.maxPolicies, 5)
    }

    func test_CLIENT_NAME_HEADER_equals_X_Client_Name() {
        XCTAssertEqual(OZConstants.clientNameHeader, "X-Client-Name")
    }

    func test_CLIENT_VERSION_HEADER_equals_X_Client_Version() {
        XCTAssertEqual(OZConstants.clientVersionHeader, "X-Client-Version")
    }

    func test_CLIENT_NAME_per_platform() {
        XCTAssertEqual(OZConstants.clientName, "ios-stellar-sdk")
    }

    func test_OZConstants_exposes_exactly_10_public_constants() {
        // Each named constant must be reachable; reading every one and ensuring the
        // collection size is exactly 10 catches accidental additions or removals.
        let values: [Any] = [
            OZConstants.defaultSessionExpiryMs,
            OZConstants.defaultIndexerTimeoutMs,
            OZConstants.defaultRelayerTimeoutMs,
            OZConstants.friendbotReserveXlm,
            OZConstants.defaultTimeoutSeconds,
            OZConstants.maxSigners,
            OZConstants.maxPolicies,
            OZConstants.clientNameHeader,
            OZConstants.clientVersionHeader,
            OZConstants.clientName,
        ]
        XCTAssertEqual(values.count, 10)
    }
}
