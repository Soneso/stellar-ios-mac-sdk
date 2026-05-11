//
//  OZSessionLifecycleTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSessionLifecycleTests: XCTestCase {

    // MARK: - Test Fixtures

    private let testContractId = "CBCD1234" + String(repeating: "A", count: 48)

    private func newAdapter() -> InMemoryStorageAdapter {
        return InMemoryStorageAdapter()
    }

    // MARK: - StoredSession.isExpired Edge Cases

    func testStoredSession_expiresAtZero_isExpired() {
        let session = StoredSession(
            credentialId: "cred",
            contractId: testContractId,
            connectedAt: 0,
            expiresAt: 0
        )
        XCTAssertTrue(session.isExpired, "Session with expiresAt=0 should be expired")
    }

    func testStoredSession_expiresAtMaxValue_notExpired() {
        let session = StoredSession(
            credentialId: "cred",
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        XCTAssertFalse(session.isExpired, "Session with expiresAt=Int64.max should not be expired")
    }

    func testStoredSession_expiresAtInPast_isExpired() {
        let session = StoredSession(
            credentialId: "cred",
            contractId: testContractId,
            connectedAt: 1000,
            expiresAt: 5000
        )
        XCTAssertTrue(session.isExpired)
    }

    // MARK: - StoredSession Data Class Properties

    func testStoredSession_allFieldsAccessible() {
        let session = StoredSession(
            credentialId: "cred-abc",
            contractId: "CONTRACT-XYZ",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_700_604_800_000
        )

        XCTAssertEqual("cred-abc", session.credentialId)
        XCTAssertEqual("CONTRACT-XYZ", session.contractId)
        XCTAssertEqual(1_700_000_000_000, session.connectedAt)
        XCTAssertEqual(1_700_604_800_000, session.expiresAt)
    }

    func testStoredSession_equalityCheck() {
        let session1 = StoredSession(
            credentialId: "cred",
            contractId: "CONTRACT",
            connectedAt: 1000,
            expiresAt: 2000
        )
        let session2 = StoredSession(
            credentialId: "cred",
            contractId: "CONTRACT",
            connectedAt: 1000,
            expiresAt: 2000
        )

        XCTAssertEqual(session1, session2)
        XCTAssertEqual(session1.hashValue, session2.hashValue)
    }

    // MARK: - Session Save and Retrieve via Storage

    func testSaveSession_thenRetrieve() async throws {
        let storage = newAdapter()

        let session = StoredSession(
            credentialId: "cred-session",
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session)

        let retrieved = try await storage.getSession()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual("cred-session", retrieved?.credentialId)
        XCTAssertEqual(testContractId, retrieved?.contractId)
    }

    func testGetSession_noneExists_returnsNull() async throws {
        let storage = newAdapter()

        let result = try await storage.getSession()
        XCTAssertNil(result)
    }

    // MARK: - Session Overwrite Behavior

    func testSaveSession_overwritesPreviousSession() async throws {
        let storage = newAdapter()

        let session1 = StoredSession(
            credentialId: "cred-1",
            contractId: "CONTRACT_1",
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session1)

        let session2 = StoredSession(
            credentialId: "cred-2",
            contractId: "CONTRACT_2",
            connectedAt: 1_700_001_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session2)

        let retrieved = try await storage.getSession()
        XCTAssertEqual("cred-2", retrieved?.credentialId)
        XCTAssertEqual("CONTRACT_2", retrieved?.contractId)
    }

    // MARK: - Session Clear

    func testClearSession_removesSession() async throws {
        let storage = newAdapter()

        try await storage.saveSession(StoredSession(
            credentialId: "cred",
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        ))

        try await storage.clearSession()

        let result = try await storage.getSession()
        XCTAssertNil(result)
    }

    func testClearSession_whenNoneExists_noOp() async throws {
        let storage = newAdapter()

        try await storage.clearSession()
        let result = try await storage.getSession()
        XCTAssertNil(result)
    }

    // MARK: - Session Expiry Auto-Clear via Storage

    func testExpiredSession_autoClearedOnGet() async throws {
        let storage = newAdapter()

        let expiredSession = StoredSession(
            credentialId: "expired-cred",
            contractId: testContractId,
            connectedAt: 1000,
            expiresAt: 2000
        )
        try await storage.saveSession(expiredSession)

        let result = try await storage.getSession()
        XCTAssertNil(result, "Expired session should return nil")

        let secondResult = try await storage.getSession()
        XCTAssertNil(secondResult, "Expired session should remain cleared")
    }

    // MARK: - Config SessionExpiryMs

    func testConfigSessionExpiryMs_default() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://soroban-testnet.stellar.org",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        )

        XCTAssertEqual(OZConstants.defaultSessionExpiryMs, config.sessionExpiryMs)
    }

    func testConfigSessionExpiryMs_custom() throws {
        let oneDayMs: Int64 = 86_400_000
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://soroban-testnet.stellar.org",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            sessionExpiryMs: oneDayMs
        )

        XCTAssertEqual(oneDayMs, config.sessionExpiryMs)
    }

    // MARK: - Cross-phase deferred placeholders

    func testKitDisconnect_clearsSession() throws {
        throw XCTSkip("Deferred until OZSmartAccountKit.disconnect ships")
    }

    func testSessionIndependentFromCredentials() throws {
        throw XCTSkip("Deferred until OZCredentialManager ships")
    }

    func testClearSessionDoesNotAffectCredentials_kitLevel() throws {
        throw XCTSkip("Deferred until OZCredentialManager ships")
    }

    func testKitIsConnected_initiallyFalse() throws {
        throw XCTSkip("Deferred until OZSmartAccountKit ships")
    }

    func testKitIsConnected_afterSetConnectedState() throws {
        throw XCTSkip("Deferred until OZSmartAccountKit.setConnectedState ships")
    }

    func testKitIsConnected_afterDisconnect() throws {
        throw XCTSkip("Deferred until OZSmartAccountKit.disconnect ships")
    }

    func testKitRequireConnected_throwsWhenNotConnected() throws {
        throw XCTSkip("Deferred until OZSmartAccountKit.requireConnected ships")
    }
}
