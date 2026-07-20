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

    func test_RPC_VISIBILITY_POLL_INTERVAL_MS_equals_1500() {
        XCTAssertEqual(OZConstants.rpcVisibilityPollIntervalMs, 1500)
    }

    func test_RPC_VISIBILITY_TIMEOUT_SECONDS_equals_45() {
        XCTAssertEqual(OZConstants.rpcVisibilityTimeoutSeconds, 45)
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

    func test_MAX_NAME_SIZE_equals_20() {
        XCTAssertEqual(OZConstants.maxNameSize, 20)
    }

    func test_MAX_EXTERNAL_KEY_SIZE_equals_256() {
        XCTAssertEqual(OZConstants.maxExternalKeySize, 256)
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

    func test_OZConstants_publicSurface_isReachable() {
        // Referencing every public constant in one place makes a rename or
        // removal fail to compile here. This is a hand-maintained inventory, not
        // an automatic guard: adding a constant without listing it does NOT fail
        // this test, so the list must be updated alongside the public surface.
        _ = [
            OZConstants.defaultSessionExpiryMs,
            OZConstants.defaultIndexerTimeoutMs,
            OZConstants.defaultRelayerTimeoutMs,
            OZConstants.friendbotReserveXlm,
            OZConstants.rpcVisibilityPollIntervalMs,
            OZConstants.rpcVisibilityTimeoutSeconds,
            OZConstants.defaultTimeoutSeconds,
            OZConstants.maxSigners,
            OZConstants.maxPolicies,
            OZConstants.maxNameSize,
            OZConstants.maxExternalKeySize,
            OZConstants.clientNameHeader,
            OZConstants.clientVersionHeader,
            OZConstants.clientName,
            OZConstants.maxIndexerResponseBytes,
            OZConstants.maxRelayerResponseBytes,
        ] as [Any]

        // The byte-size limits have no dedicated value test above, so pin them
        // directly rather than leaving the assertion tautological.
        XCTAssertEqual(OZConstants.maxIndexerResponseBytes, 1 * 1024 * 1024)
        XCTAssertEqual(OZConstants.maxRelayerResponseBytes, 256 * 1024)
    }
}
