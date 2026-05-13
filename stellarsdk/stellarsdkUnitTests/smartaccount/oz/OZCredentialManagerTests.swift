//
//  OZCredentialManagerTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for ``OZCredentialManager``.
///
/// Covers the credential lifecycle operations the manager owns: create / save /
/// query / update / sync / delete / setPrimary / clearAll. All tests use the
/// ``MockOZSmartAccountKit`` test double, which holds a real
/// ``InMemoryStorageAdapter`` and lets the tests inject a scriptable
/// ``MockSorobanServerScript`` for the on-chain sync paths.
final class OZCredentialManagerTests: XCTestCase {

    // MARK: - Fixtures

    private let contractA: String =
        "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
    private let contractB: String =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    /// A deterministic 65-byte uncompressed secp256r1 public key fixture.
    /// First byte is the SEC1 prefix; the remaining 64 bytes cycle through
    /// `1..64` so two consecutive fixtures compare equal but are clearly
    /// distinguishable from arbitrary other byte sequences.
    private func testPublicKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: SmartAccountConstants.secp256r1PublicKeySize)
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        for i in 1..<SmartAccountConstants.secp256r1PublicKeySize {
            bytes[i] = UInt8(i % 256)
        }
        return Data(bytes)
    }

    /// Builds a real ``OZCredentialManager`` bound to a ``MockOZSmartAccountKit``.
    ///
    /// The mock kit is constructed with a fresh ``InMemoryStorageAdapter`` and
    /// (when `useScriptedServer` is true) a ``SorobanServer`` whose URL is
    /// intercepted by ``MockSorobanServerScript`` so the sync paths can be
    /// driven without live RPC traffic.
    private func makeManager(
        useScriptedServer: Bool = false
    ) throws -> (manager: OZCredentialManager, kit: MockOZSmartAccountKit, storage: InMemoryStorageAdapter) {
        let storage = InMemoryStorageAdapter()
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA,
            storage: storage
        )
        let sorobanServer: SorobanServer
        if useScriptedServer {
            sorobanServer = SorobanServer(endpoint: "https://mock-rpc.invalid/rpc")
        } else {
            sorobanServer = SorobanServer(endpoint: "http://127.0.0.1:1")
        }
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: sorobanServer
        )
        let manager = OZCredentialManager(kit: kit)
        return (manager, kit, storage)
    }

    // MARK: - createPendingCredential

    /// A.1.1: createPendingCredential with valid input persists a credential
    /// initialised with PENDING status, `isPrimary` false, and a fresh
    /// `createdAt` timestamp.
    func testCreatePendingCredential_validInput_createsCredential() async throws {
        let (manager, _, storage) = try makeManager()
        let credential = try await manager.createPendingCredential(
            credentialId: "valid-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        XCTAssertEqual(credential.credentialId, "valid-cred")
        XCTAssertEqual(credential.contractId, contractA)
        XCTAssertEqual(credential.deploymentStatus, .pending)
        XCTAssertFalse(credential.isPrimary)
        XCTAssertGreaterThan(credential.createdAt, 0)

        let fetched = try await storage.get(credentialId: "valid-cred")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.deploymentStatus, .pending)
    }

    /// A.1.2: createPendingCredential rejects a public key of the wrong size.
    func testCreatePendingCredential_invalidPublicKeySize_throws() async throws {
        let (manager, _, _) = try makeManager()
        do {
            _ = try await manager.createPendingCredential(
                credentialId: "bad-key",
                publicKey: Data(repeating: 0, count: 32),
                contractId: contractA
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected ValidationException.InvalidInput, got \(type(of: error))")
        }
    }

    /// A.1.3: createPendingCredential rejects an empty credential id.
    func testCreatePendingCredential_emptyCredentialId_throws() async throws {
        let (manager, _, _) = try makeManager()
        do {
            _ = try await manager.createPendingCredential(
                credentialId: "",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected ValidationException.InvalidInput, got \(type(of: error))")
        }
    }

    /// A.1.4: createPendingCredential rejects a duplicate credential id.
    func testCreatePendingCredential_duplicateCredentialId_throwsAlreadyExists() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "dup-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            _ = try await manager.createPendingCredential(
                credentialId: "dup-cred",
                publicKey: testPublicKey(),
                contractId: contractB
            )
            XCTFail("expected CredentialException.AlreadyExists")
        } catch is CredentialException.AlreadyExists {
            // expected
        } catch {
            XCTFail("expected CredentialException.AlreadyExists, got \(type(of: error))")
        }
    }

    /// A.1.5: createPendingCredential persists `transports`, `deviceType`,
    /// `backedUp`, and `nickname` metadata when supplied.
    func testCreatePendingCredential_persistsAllMetadata() async throws {
        let (manager, _, storage) = try makeManager()
        let credential = try await manager.createPendingCredential(
            credentialId: "meta-cred",
            publicKey: testPublicKey(),
            contractId: contractA,
            nickname: "Alice",
            transports: ["internal", "usb"],
            deviceType: "multiDevice",
            backedUp: true
        )
        XCTAssertEqual(credential.nickname, "Alice")
        XCTAssertEqual(credential.transports, ["internal", "usb"])
        XCTAssertEqual(credential.deviceType, "multiDevice")
        XCTAssertEqual(credential.backedUp, true)
        XCTAssertFalse(credential.isPrimary)

        let fetched = try await storage.get(credentialId: "meta-cred")
        XCTAssertEqual(fetched?.transports, ["internal", "usb"])
        XCTAssertEqual(fetched?.deviceType, "multiDevice")
        XCTAssertEqual(fetched?.backedUp, true)
        XCTAssertEqual(fetched?.nickname, "Alice")
    }

    // MARK: - saveCredential

    /// A.2.6: saveCredential persists a credential with default deployment
    /// metadata and is retrievable via the manager.
    func testSaveCredential_validInput_persistsWithDefaults() async throws {
        let (manager, _, _) = try makeManager()
        let saved = try await manager.saveCredential(
            credentialId: "saved-cred",
            publicKey: testPublicKey(),
            nickname: "My MacBook",
            contractId: contractA
        )
        XCTAssertEqual(saved.credentialId, "saved-cred")
        XCTAssertEqual(saved.nickname, "My MacBook")
        XCTAssertEqual(saved.contractId, contractA)
        XCTAssertEqual(saved.deploymentStatus, .pending)
        XCTAssertFalse(saved.isPrimary)

        let retrieved = try await manager.getCredential(credentialId: "saved-cred")
        XCTAssertEqual(retrieved?.nickname, "My MacBook")
        XCTAssertEqual(retrieved?.contractId, contractA)
    }

    /// A.2.7: saveCredential rejects an empty credential id.
    func testSaveCredential_emptyCredentialId_throws() async throws {
        let (manager, _, _) = try makeManager()
        do {
            _ = try await manager.saveCredential(
                credentialId: "",
                publicKey: testPublicKey()
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected ValidationException.InvalidInput, got \(type(of: error))")
        }
    }

    /// A.2.8: saveCredential rejects a public key of the wrong size.
    func testSaveCredential_invalidPublicKeySize_throws() async throws {
        let (manager, _, _) = try makeManager()
        do {
            _ = try await manager.saveCredential(
                credentialId: "invalid-key-cred",
                publicKey: Data(repeating: 0, count: 32)
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected ValidationException.InvalidInput, got \(type(of: error))")
        }
    }

    // MARK: - sync / syncAll

    /// A.3.9: sync deletes the credential and returns true when the contract
    /// is reachable on-chain.
    func testSync_contractExists_deletesCredentialReturnsTrue() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (manager, _, storage) = try makeManager(useScriptedServer: true)
        _ = try await manager.createPendingCredential(
            credentialId: "deployed-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        try script.setGetContractDataResponse(contractId: contractA)

        let exists = try await manager.sync(credentialId: "deployed-cred")
        XCTAssertTrue(exists)
        let leftover = try await storage.get(credentialId: "deployed-cred")
        XCTAssertNil(leftover)
    }

    /// A.3.10: sync keeps the credential and returns false when the contract
    /// is not present on-chain.
    func testSync_contractMissing_returnsFalseKeepsCredential() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (manager, _, storage) = try makeManager(useScriptedServer: true)
        _ = try await manager.createPendingCredential(
            credentialId: "pending-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        script.setEmptyGetLedgerEntriesResponse()

        let exists = try await manager.sync(credentialId: "pending-cred")
        XCTAssertFalse(exists)
        let retained = try await storage.get(credentialId: "pending-cred")
        XCTAssertNotNil(retained)
    }

    /// A.3.11: sync returns false silently when the on-chain check fails
    /// (transport error, RPC error, parse failure). Per D-126 the credential
    /// is retained in storage and no exception escapes.
    func testSync_rpcError_returnsFalseSilently() async throws {
        // why: no MockSorobanServer.activate here — the kit is constructed
        // with a SorobanServer pointing at 127.0.0.1:1 which yields immediate
        // connection-refused on every call. The error must not propagate.
        let (manager, _, storage) = try makeManager(useScriptedServer: false)
        _ = try await manager.createPendingCredential(
            credentialId: "rpc-fail-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        let exists = try await manager.sync(credentialId: "rpc-fail-cred")
        XCTAssertFalse(exists)
        let retained = try await storage.get(credentialId: "rpc-fail-cred")
        XCTAssertNotNil(retained)
    }

    /// A.3.12: syncAll counts deployed, pending, and failed credentials
    /// correctly across a mixed credential set.
    func testSyncAll_mixedStatuses_countsDeployedPendingFailed() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (manager, _, _) = try makeManager(useScriptedServer: true)

        // Three credentials: one pending (not deployed), one failed (not
        // deployed), one without contractId (treated as not deployed).
        _ = try await manager.createPendingCredential(
            credentialId: "pending-1",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "failed-1",
            publicKey: testPublicKey(),
            contractId: contractB
        )
        try await manager.markDeploymentFailed(
            credentialId: "failed-1",
            error: "Insufficient balance"
        )
        _ = try await manager.saveCredential(
            credentialId: "no-contract",
            publicKey: testPublicKey(),
            contractId: nil
        )

        // The "pending-1" credential will hit RPC; script an empty response
        // so it is counted as pending. "failed-1" also hits RPC; script
        // another empty response. "no-contract" does not hit RPC because its
        // contractId is empty (early return in sync).
        script.setEmptyGetLedgerEntriesResponse()

        let result = try await manager.syncAll()
        XCTAssertEqual(result.deployed, 0)
        XCTAssertEqual(result.failed, 1)
        // "pending-1" and "no-contract" both fall into the pending bucket.
        XCTAssertEqual(result.pending, 2)
    }

    /// A.3.13: sync throws CredentialException.NotFound when the credential
    /// does not exist in storage.
    func testSync_credentialNotFound_throwsCredentialNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            _ = try await manager.sync(credentialId: "missing-cred")
            XCTFail("expected CredentialException.NotFound")
        } catch is CredentialException.NotFound {
            // expected
        } catch {
            XCTFail("expected CredentialException.NotFound, got \(type(of: error))")
        }
    }

    // MARK: - deleteCredential

    /// A.4.14: deleteCredential removes a pending credential and emits the
    /// CredentialDeleted event.
    func testDeleteCredential_pendingCredential_deletesAndEmitsEvent() async throws {
        let (manager, kit, storage) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "del-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        // Capture the credentialDeleted event.
        let received = EventBox()
        let unsubscribe = kit.events.addListener { event in
            if case let .credentialDeleted(credentialId) = event {
                received.set(credentialId)
            }
        }
        defer { unsubscribe() }

        try await manager.deleteCredential(credentialId: "del-cred")

        let leftover = try await storage.get(credentialId: "del-cred")
        XCTAssertNil(leftover)
        XCTAssertEqual(received.get(), "del-cred")
    }

    /// A.4.15: deleteCredential refuses to delete when the on-chain contract
    /// already exists; per D-127 the prior sync removes the credential and
    /// the deletion then throws CredentialException.Invalid.
    func testDeleteCredential_deployedCredential_throwsCannotDelete() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (manager, _, storage) = try makeManager(useScriptedServer: true)
        _ = try await manager.createPendingCredential(
            credentialId: "deployed-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        // sync()'s on-chain check finds the contract and removes the
        // credential. deleteCredential then surfaces Invalid.
        try script.setGetContractDataResponse(contractId: contractA)

        do {
            try await manager.deleteCredential(credentialId: "deployed-cred")
            XCTFail("expected CredentialException.Invalid")
        } catch is CredentialException.Invalid {
            // expected
        } catch {
            XCTFail("expected CredentialException.Invalid, got \(type(of: error))")
        }
        // sync removed the credential during the pre-delete check.
        let leftover = try await storage.get(credentialId: "deployed-cred")
        XCTAssertNil(leftover)
    }

    /// A.4.16: deleteCredential throws CredentialException.NotFound when the
    /// credential does not exist.
    func testDeleteCredential_credentialNotFound_throwsNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.deleteCredential(credentialId: "missing-cred")
            XCTFail("expected CredentialException.NotFound")
        } catch is CredentialException.NotFound {
            // expected
        } catch {
            XCTFail("expected CredentialException.NotFound, got \(type(of: error))")
        }
    }

    // MARK: - Query helpers

    /// A.5.17: getCredential returns the stored credential when present.
    func testGetCredential_existing_returnsCredential() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "lookup-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        let credential = try await manager.getCredential(credentialId: "lookup-cred")
        XCTAssertNotNil(credential)
        XCTAssertEqual(credential?.credentialId, "lookup-cred")
        XCTAssertEqual(credential?.contractId, contractA)
    }

    /// A.5.18: getCredentialsByContract returns only the credentials whose
    /// contractId matches the supplied filter.
    func testGetCredentialsByContract_returnsFilteredList() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "cred-a1",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "cred-a2",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "cred-b1",
            publicKey: testPublicKey(),
            contractId: contractB
        )

        let aCreds = try await manager.getCredentialsByContract(contractId: contractA)
        XCTAssertEqual(aCreds.count, 2)
        XCTAssertEqual(Set(aCreds.map { $0.credentialId }), Set(["cred-a1", "cred-a2"]))

        let bCreds = try await manager.getCredentialsByContract(contractId: contractB)
        XCTAssertEqual(bCreds.count, 1)
        XCTAssertEqual(bCreds.first?.credentialId, "cred-b1")
    }

    /// A.5.19: getForConnectedWallet returns empty when no wallet is
    /// currently connected (per D-122).
    func testGetForConnectedWallet_noConnection_returnsEmpty() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "free-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        let result = try await manager.getForConnectedWallet()
        XCTAssertTrue(result.isEmpty)
    }

    /// A.5.20: getPendingCredentials filters PENDING and FAILED entries.
    func testGetPendingCredentials_filtersPendingAndFailed() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "pending-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "failed-cred",
            publicKey: testPublicKey(),
            contractId: contractB
        )
        try await manager.markDeploymentFailed(
            credentialId: "failed-cred",
            error: "Insufficient balance"
        )

        let pending = try await manager.getPendingCredentials()
        XCTAssertEqual(pending.count, 2)
        let ids = Set(pending.map { $0.credentialId })
        XCTAssertTrue(ids.contains("pending-cred"))
        XCTAssertTrue(ids.contains("failed-cred"))

        let failedOnly = pending.first(where: { $0.credentialId == "failed-cred" })
        XCTAssertEqual(failedOnly?.deploymentStatus, .failed)
    }

    // MARK: - Update helpers

    /// A.6.21: updateNickname persists a new nickname when the credential
    /// exists.
    func testUpdateNickname_existing_persistsNewNickname() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "nick-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        try await manager.updateNickname(
            credentialId: "nick-cred",
            nickname: "YubiKey 5"
        )
        let updated = try await manager.getCredential(credentialId: "nick-cred")
        XCTAssertEqual(updated?.nickname, "YubiKey 5")
    }

    /// A.6.22: updateLastUsed sets a non-nil timestamp (internal helper).
    func testUpdateLastUsed_internal_setsTimestamp() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "used-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        try await manager.updateLastUsed(credentialId: "used-cred")
        let updated = try await manager.getCredential(credentialId: "used-cred")
        XCTAssertNotNil(updated?.lastUsedAt)
        XCTAssertGreaterThan(updated?.lastUsedAt ?? 0, 0)
    }

    /// A.6.23: setPrimary demotes any existing primary credential for the
    /// same contract before promoting the target credential (per D-124).
    func testSetPrimary_internal_unsetsExistingPrimary() async throws {
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "cred-a",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.saveCredential(
            credentialId: "cred-b",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        // Promote cred-a first; then promote cred-b. setPrimary should demote
        // cred-a as part of cred-b's promotion.
        try await manager.setPrimary(credentialId: "cred-a")
        try await manager.setPrimary(credentialId: "cred-b")

        let credA = try await manager.getCredential(credentialId: "cred-a")
        let credB = try await manager.getCredential(credentialId: "cred-b")
        XCTAssertEqual(credA?.isPrimary, false)
        XCTAssertEqual(credB?.isPrimary, true)
    }

    // MARK: - Task cancellation propagation

    /// `syncAll` walks every stored credential and issues an on-chain
    /// `sync(credentialId:)` call per entry. Cancelling the parent task
    /// between iterations must short-circuit the loop rather than continuing
    /// through the full credential set. The test seeds two credentials so the
    /// loop iterates at least once before the cancellation checkpoint fires.
    func testSyncAll_cancellation_propagatesCancellationError() async throws {
        // RPC points at a non-routable host so each sync call would otherwise
        // hang on connection-refused; cancellation must short-circuit the loop.
        let (manager, _, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "cancel-cred-a",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "cancel-cred-b",
            publicKey: testPublicKey(),
            contractId: contractB
        )

        let task = Task { [manager] in
            return try await manager.syncAll()
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("expected cancellation or error before full sync completes")
        } catch is CancellationError {
            // Expected: the loop's `Task.checkCancellation` fired between
            // credential iterations.
        } catch {
            // Acceptable alternative: an awaited RPC failure surfaced before
            // the cancellation checkpoint observed. Any thrown error proves
            // the loop did not return a fully-populated SyncResult.
        }
    }
}

// MARK: - EventBox

/// Tiny thread-safe slot used by tests that listen for a single emitted event.
private final class EventBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?

    func set(_ value: String) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func get() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
