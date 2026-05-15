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

    // MARK: - Kit-level session lifecycle

    // why: every kit-level test below builds the real `OZSmartAccountKit`
    // through `makeKit(storage:)` so the assertions exercise the production
    // wiring (lock-protected state, eager-init managers, storage delegation)
    // rather than a mock seam.

    private let validRpcUrl = "https://soroban-testnet.stellar.org"
    private let validVerifier =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validWasmHash = "a" + String(repeating: "0", count: 63)

    private func makeKit(
        storage: StorageAdapter? = nil
    ) throws -> (kit: OZSmartAccountKit, storage: StorageAdapter) {
        let resolvedStorage: StorageAdapter = storage ?? InMemoryStorageAdapter()
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            storage: resolvedStorage
        )
        let kit = OZSmartAccountKit.create(config: config)
        return (kit, resolvedStorage)
    }

    private func testPublicKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: SmartAccountConstants.secp256r1PublicKeySize)
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        for i in 1..<SmartAccountConstants.secp256r1PublicKeySize {
            bytes[i] = UInt8(i % 256)
        }
        return Data(bytes)
    }

    /// Disconnect must remove the persisted `StoredSession` from storage even
    /// when the in-memory connection state has already been pre-seeded with a
    /// matching credential / contract pair. Asserts the storage-side effect
    /// in isolation: after `kit.disconnect()` the storage adapter's
    /// `getSession()` returns nil.
    func testKitDisconnect_clearsSession() async throws {
        let (kit, storage) = try makeKit()

        let session = StoredSession(
            credentialId: "session-cred",
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session)

        kit.setConnectedState(credentialId: "session-cred", contractId: testContractId)

        // Sanity check: the session is durable up to the disconnect call.
        let preDisconnect = try await storage.getSession()
        XCTAssertNotNil(preDisconnect, "Session must be present before disconnect")

        try await kit.disconnect()

        let postDisconnect = try await storage.getSession()
        XCTAssertNil(postDisconnect, "Disconnect must remove the stored session")
    }

    /// Stored credentials and the active session live in independent storage
    /// slots. Saving / clearing one must not modify the other. Asserts the
    /// orthogonality contract that the OZ smart account relies on for
    /// credential persistence across disconnect/reconnect cycles.
    func testSessionIndependentFromCredentials() async throws {
        let storage = InMemoryStorageAdapter()
        let (_, _) = try makeKit(storage: storage)

        let credential = StoredCredential(
            credentialId: "cred-shared",
            publicKey: testPublicKey(),
            contractId: testContractId,
            deploymentStatus: .pending,
            createdAt: 1_700_000_000_000,
            nickname: "primary",
            isPrimary: true
        )
        try await storage.save(credential: credential)

        let session = StoredSession(
            credentialId: "cred-shared",
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session)

        // Clearing the session must not delete the credential.
        try await storage.clearSession()
        let credentialAfterSessionClear = try await storage.get(credentialId: "cred-shared")
        XCTAssertNotNil(credentialAfterSessionClear, "Credential must survive session clear")
        XCTAssertEqual(credentialAfterSessionClear?.contractId, testContractId)
        let sessionAfterClear = try await storage.getSession()
        XCTAssertNil(sessionAfterClear)

        // Re-save the session, then delete the credential.
        try await storage.saveSession(session)
        try await storage.delete(credentialId: "cred-shared")
        let sessionAfterCredentialDelete = try await storage.getSession()
        XCTAssertNotNil(sessionAfterCredentialDelete, "Session must survive credential delete")
        XCTAssertEqual(sessionAfterCredentialDelete?.credentialId, "cred-shared")
        let credentialAfterDelete = try await storage.get(credentialId: "cred-shared")
        XCTAssertNil(credentialAfterDelete)
    }

    /// Kit-level disconnect clears the persisted session but leaves every
    /// stored credential untouched. The credentials remain available for
    /// `OZWalletOperations.connectWallet()` to reconnect against.
    func testClearSessionDoesNotAffectCredentials_kitLevel() async throws {
        let (kit, storage) = try makeKit()

        let primaryCredential = StoredCredential(
            credentialId: "cred-primary",
            publicKey: testPublicKey(),
            contractId: testContractId,
            deploymentStatus: .pending,
            createdAt: 1_700_000_000_000,
            nickname: "primary",
            isPrimary: true
        )
        let secondaryCredential = StoredCredential(
            credentialId: "cred-secondary",
            publicKey: testPublicKey(),
            contractId: testContractId,
            deploymentStatus: .failed,
            createdAt: 1_700_000_000_001,
            nickname: "secondary",
            isPrimary: false
        )
        try await storage.save(credential: primaryCredential)
        try await storage.save(credential: secondaryCredential)

        let session = StoredSession(
            credentialId: "cred-primary",
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session)

        kit.setConnectedState(credentialId: "cred-primary", contractId: testContractId)
        XCTAssertTrue(kit.isConnected)

        try await kit.disconnect()

        // Session is gone.
        let sessionAfterDisconnect = try await storage.getSession()
        XCTAssertNil(sessionAfterDisconnect)
        // Both credentials are still present and structurally intact.
        let allCredentials = try await storage.getAll()
        XCTAssertEqual(allCredentials.count, 2)
        let primaryAfter = try await storage.get(credentialId: "cred-primary")
        let secondaryAfter = try await storage.get(credentialId: "cred-secondary")
        XCTAssertNotNil(primaryAfter)
        XCTAssertNotNil(secondaryAfter)
        XCTAssertEqual(primaryAfter?.deploymentStatus, .pending)
        XCTAssertTrue(primaryAfter?.isPrimary ?? false)
        XCTAssertEqual(secondaryAfter?.deploymentStatus, .failed)
        XCTAssertEqual(secondaryAfter?.contractId, testContractId)
    }

    /// A freshly-constructed kit has no in-memory connection state. Asserts
    /// the public state accessors all reflect the disconnected baseline,
    /// which is the precondition every consumer relies on before invoking
    /// `connectWallet()` or `createWallet()`.
    func testKitIsConnected_initiallyFalse() throws {
        let (kit, _) = try makeKit()

        XCTAssertFalse(kit.isConnected, "Fresh kit must not report a connection")
        XCTAssertNil(kit.credentialId, "Fresh kit must expose nil credentialId")
        XCTAssertNil(kit.contractId, "Fresh kit must expose nil contractId")
        XCTAssertThrowsError(try kit.requireConnected()) { error in
            XCTAssertTrue(error is WalletException.NotConnected)
        }
    }

    /// `setConnectedState` is the single source of truth for the kit's
    /// in-memory connection state. Asserts every public accessor
    /// (`isConnected`, `credentialId`, `contractId`, `requireConnected`) is
    /// updated consistently after a single write, and that subsequent writes
    /// overwrite without any residual state from the prior connection.
    func testKitIsConnected_afterSetConnectedState() throws {
        let (kit, _) = try makeKit()

        let initialCredential = "cred-initial"
        let initialContract = testContractId
        kit.setConnectedState(credentialId: initialCredential, contractId: initialContract)

        XCTAssertTrue(kit.isConnected)
        XCTAssertEqual(kit.credentialId, initialCredential)
        XCTAssertEqual(kit.contractId, initialContract)
        let initialSnapshot = try kit.requireConnected()
        XCTAssertEqual(initialSnapshot.credentialId, initialCredential)
        XCTAssertEqual(initialSnapshot.contractId, initialContract)

        // Overwriting connection state must replace both fields atomically.
        let overwriteCredential = "cred-overwrite"
        let overwriteContract =
            "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
        kit.setConnectedState(credentialId: overwriteCredential, contractId: overwriteContract)

        XCTAssertTrue(kit.isConnected)
        XCTAssertEqual(kit.credentialId, overwriteCredential)
        XCTAssertEqual(kit.contractId, overwriteContract)
        let overwriteSnapshot = try kit.requireConnected()
        XCTAssertEqual(overwriteSnapshot.credentialId, overwriteCredential)
        XCTAssertEqual(overwriteSnapshot.contractId, overwriteContract)
    }

    /// Disconnect when no wallet is connected must be a no-op: it does not
    /// throw, it does not flip `isConnected` (already false), and it must
    /// not emit a `walletDisconnected` event because no contract id is
    /// available to populate the payload. Asserts the documented "safe to
    /// call even when no wallet is connected" contract on the disconnect
    /// path, distinct from the connected-disconnect coverage in
    /// `OZSmartAccountKitTests`.
    func testKitIsConnected_afterDisconnect() async throws {
        let (kit, storage) = try makeKit()

        XCTAssertFalse(kit.isConnected)

        let recorder = SessionDisconnectEventRecorder()
        kit.events.on(.walletDisconnected) { event in
            recorder.record(event)
        }

        // Calling disconnect with no prior connection must succeed silently.
        try await kit.disconnect()

        XCTAssertFalse(kit.isConnected)
        XCTAssertNil(kit.credentialId)
        XCTAssertNil(kit.contractId)
        let sessionAfterIdleDisconnect = try await storage.getSession()
        XCTAssertNil(sessionAfterIdleDisconnect)
        XCTAssertEqual(recorder.count, 0, "Disconnect from idle state must not emit walletDisconnected")

        // A second disconnect from the same idle baseline is also a no-op.
        try await kit.disconnect()
        XCTAssertEqual(recorder.count, 0)
    }

    /// `requireConnected` throws `WalletException.NotConnected` whenever the
    /// kit's in-memory state has no credential / contract pair. The message
    /// must be the kit-level guidance pointing the caller at
    /// `createWallet()` / `connectWallet()`. Also asserts the post-disconnect
    /// transition produces the same error type, distinct from the
    /// initial-state coverage in `OZSmartAccountKitTests`.
    func testKitRequireConnected_throwsWhenNotConnected() async throws {
        let (kit, _) = try makeKit()

        // Initial state — never connected.
        XCTAssertThrowsError(try kit.requireConnected()) { error in
            XCTAssertTrue(error is WalletException.NotConnected)
            let typed = error as? WalletException.NotConnected
            XCTAssertEqual(
                typed?.message,
                "No wallet connected. Call createWallet() or connectWallet() first."
            )
        }

        // After a connect/disconnect round trip the same error must surface.
        kit.setConnectedState(credentialId: "cred", contractId: testContractId)
        XCTAssertNoThrow(try kit.requireConnected())

        try await kit.disconnect()
        XCTAssertThrowsError(try kit.requireConnected()) { error in
            XCTAssertTrue(error is WalletException.NotConnected)
            let typed = error as? WalletException.NotConnected
            XCTAssertEqual(
                typed?.message,
                "No wallet connected. Call createWallet() or connectWallet() first."
            )
        }
    }
}

/// Thread-safe recorder for `walletDisconnected` events used by the
/// session-lifecycle tests. The kit's event emitter dispatches on an
/// arbitrary queue, so the recorder must synchronise its append/read
/// pair against concurrent writers.
private final class SessionDisconnectEventRecorder: @unchecked Sendable {
    private let recorderLock = NSLock()
    private var _events: [SmartAccountEvent] = []

    func record(_ event: SmartAccountEvent) {
        recorderLock.lock()
        _events.append(event)
        recorderLock.unlock()
    }

    var count: Int {
        recorderLock.lock()
        defer { recorderLock.unlock() }
        return _events.count
    }

    var events: [SmartAccountEvent] {
        recorderLock.lock()
        defer { recorderLock.unlock() }
        return _events
    }
}
