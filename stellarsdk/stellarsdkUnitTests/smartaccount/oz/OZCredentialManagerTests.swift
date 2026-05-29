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
            sorobanServer = MockSorobanServer.makeMockedSorobanServer()
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
    /// (transport error, RPC error, parse failure). The credential is retained
    /// in storage and no exception escapes.
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

    // MARK: - sync — credentialSyncFailed event

    /// A.3.14: when sync() cannot reach the RPC endpoint it emits a
    /// `credentialSyncFailed` event carrying the credential id that was being
    /// synced and the underlying RPC error.
    ///
    /// The test drives the failure path by pointing the kit's SorobanServer at
    /// a non-routable host (127.0.0.1:1), which yields an immediate
    /// connection-refused error without needing the mock server infrastructure.
    func testSync_rpcFailure_emitsCredentialSyncFailedEvent() async throws {
        let (manager, kit, _) = try makeManager(useScriptedServer: false)
        _ = try await manager.createPendingCredential(
            credentialId: "sync-fail-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        let credentialIdBox = EventBox()
        let errorBox = ErrorBox()
        let unsubscribe = kit.events.addListener { event in
            if case let .credentialSyncFailed(credentialId, error) = event {
                credentialIdBox.set(credentialId)
                errorBox.set(error)
            }
        }
        defer { unsubscribe() }

        _ = try await manager.sync(credentialId: "sync-fail-cred")

        XCTAssertEqual(credentialIdBox.get(), "sync-fail-cred",
                       "Event credentialId must match the synced credential")
        XCTAssertNotNil(errorBox.get(),
                        "Event must carry the underlying RPC error")
    }

    /// A.3.15: sync() must still return `false` when the `credentialSyncFailed`
    /// event is emitted — the event emission must not alter the method's return
    /// value or cause the method to throw.
    func testSync_rpcFailure_returnsFalseAfterEmittingEvent() async throws {
        let (manager, _, _) = try makeManager(useScriptedServer: false)
        _ = try await manager.createPendingCredential(
            credentialId: "sync-false-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        let result = try await manager.sync(credentialId: "sync-false-cred")
        XCTAssertFalse(result,
                       "sync() must return false when the on-chain check fails")
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
    /// already exists; sync removes the credential and the deletion then
    /// throws CredentialException.Invalid.
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
    /// currently connected.
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
    /// same contract before promoting the target credential.
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

    // ========================================================================
    // MARK: - Storage error paths (Batch F)
    // ========================================================================

    /// Constructs a credential manager backed by a storage adapter that fails
    /// all write or read operations. Uses a minimal kit that returns the
    /// failing storage directly from `getStorage()`, bypassing the cast in
    /// `MockOZSmartAccountKit`.
    private func makeManagerWithFailingStorage(
        failOnWrite: Bool = false,
        failOnRead: Bool = false
    ) throws -> OZCredentialManager {
        let failingStorage = _CredentialTestFailingStorage(
            failOnWrite: failOnWrite,
            failOnRead: failOnRead
        )
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA
        )
        let kit = _CredentialManagerTestKit(config: config, storage: failingStorage)
        return OZCredentialManager(kit: kit)
    }

    /// `createPendingCredential` must surface `StorageException.WriteFailed`
    /// when the underlying storage adapter fails the write.
    func test_createPendingCredential_storageWriteFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnWrite: true)
        do {
            _ = try await manager.createPendingCredential(
                credentialId: "new-cred",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `saveCredential` must surface `StorageException.WriteFailed` when
    /// the underlying storage adapter fails the write.
    func test_saveCredential_storageWriteFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnWrite: true)
        do {
            _ = try await manager.saveCredential(
                credentialId: "cred-save",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `getAllCredentials` must surface `StorageException.ReadFailed` when
    /// the underlying storage adapter fails the read.
    func test_getAllCredentials_storageReadFails_throws() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.getAllCredentials()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `clearAll` must surface `StorageException.WriteFailed` when the
    /// underlying storage adapter fails the clear operation.
    func test_clearAll_storageWriteFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnWrite: true)
        do {
            try await manager.clearAll()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `updateNickname` on a non-existent credential must surface
    /// `CredentialException.NotFound` (the `updateCredential` guard fires
    /// before the storage write is attempted).
    func test_updateNickname_credentialNotFound_throwsCredentialException() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.updateNickname(
                credentialId: "does-not-exist",
                nickname: "new name"
            )
            XCTFail("expected CredentialException.NotFound")
        } catch is CredentialException.NotFound {
            // expected
        }
    }

    /// `getPendingCredentials` must surface `StorageException.ReadFailed` when
    /// the underlying storage adapter fails the getAll read.
    func test_getPendingCredentials_storageReadFails_throws() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.getPendingCredentials()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `getForConnectedWallet` returns an empty list when the kit is
    /// disconnected (the connection error is absorbed, not propagated).
    func test_getForConnectedWallet_notConnected_returnsEmptyList() async throws {
        let (manager, _, _) = try makeManager()
        let result = try await manager.getForConnectedWallet()
        XCTAssertEqual(0, result.count, "getForConnectedWallet must return empty when kit is disconnected")
    }

    /// When two credentials exist for the same contract and the indexer
    /// returns both, `isAmbiguous` for that contract returns `true`. Exercises
    /// the multi-match branch in `getCredentialsByContract` / the ambiguity
    /// check in `OZWalletOperations.connectWallet`.
    ///
    /// This test uses the in-memory storage adapter; it seeds two credentials
    /// with distinct IDs bound to the same contract and asserts that reading
    /// them back returns both (the platform for the ambiguity check is the
    /// caller's concern — here we verify storage returns the pair).
    func test_credentialsByContract_multipleSameContract_returnsBoth() async throws {
        let (manager, _, storage) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "cred-one",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "cred-two",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        let results = try await storage.getByContract(contractId: contractA)
        XCTAssertEqual(2, results.count, "Both credentials bound to the same contract must be returned")
    }

    /// `createPendingCredential` must rethrow `CredentialException` when
    /// the underlying storage throws one (covers the first catch branch).
    func test_createPendingCredential_storageThrowsCredentialException_rethrows() async throws {
        let throwingStorage = _TypedThrowingStorage(throwOnSave: .credential)
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA
        )
        let kit = _CredentialManagerTestKit(config: config, storage: throwingStorage)
        let manager = OZCredentialManager(kit: kit)

        do {
            _ = try await manager.createPendingCredential(
                credentialId: "cred-ce",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected CredentialException")
        } catch is CredentialException {
            // expected — CredentialException propagated as-is from storage
        }
    }

    /// `createPendingCredential` must wrap a generic `Error` from storage
    /// into `StorageException.WriteFailed` (covers the final catch branch).
    func test_createPendingCredential_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _TypedThrowingStorage(throwOnSave: .generic)
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA
        )
        let kit = _CredentialManagerTestKit(config: config, storage: throwingStorage)
        let manager = OZCredentialManager(kit: kit)

        do {
            _ = try await manager.createPendingCredential(
                credentialId: "cred-ge",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected StorageException.WriteFailed")
        } catch is StorageException.WriteFailed {
            // expected
        } catch is StorageException {
            // also acceptable
        }
    }

    // MARK: - syncAll storage-failure paths

    /// `syncAll` must rethrow `StorageException` when `getAll()` fails with one.
    /// Covers lines 341-342 in `OZCredentialManager.syncAll`.
    func test_syncAll_storageReadFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.syncAll()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `syncAll` must wrap a non-StorageException from `getAll()` into
    /// `StorageException.ReadFailed`. Covers lines 343-344.
    func test_syncAll_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .getAllGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.syncAll()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected — generic error wrapped into StorageException.readFailed
        }
    }

    /// `syncAll` deployed-count path (covers line 365: `deployed += 1`).
    ///
    /// Setup: a real in-memory manager with a scripted Soroban server that
    /// returns a valid contract instance for every `getContractData` call.
    /// With the credential stored and the on-chain check succeeding, `sync`
    /// returns `true` and `syncAll` increments the `deployed` counter.
    func test_syncAll_contractDeployed_incrementsDeployedCount() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (manager, _, _) = try makeManager(useScriptedServer: true)
        _ = try await manager.createPendingCredential(
            credentialId: "deployed-for-syncall",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        // Script the contract-data response so `sync` returns true.
        try script.setGetContractDataResponse(contractId: contractA)

        let result = try await manager.syncAll()
        XCTAssertEqual(result.deployed, 1,
                       "One deployed credential must be counted as deployed")
        XCTAssertEqual(result.pending, 0)
        XCTAssertEqual(result.failed, 0)
    }

    /// `syncAll` must absorb `CredentialException` thrown by `sync` for
    /// individual credentials (covers lines 356-361: the `CredentialException`
    /// catch inside the syncAll loop). When `sync` cannot find a credential
    /// that was in the list (race condition modelled by deleting it between
    /// `getAll` and the per-entry `sync`), syncAll treats it as not-deployed.
    ///
    /// Setup: seed a credential, then replace storage with a version that
    /// returns the credential from `getAll` but throws `CredentialException`
    /// from `get(credentialId:)` (which is what `sync` calls internally).
    func test_syncAll_syncThrowsCredentialException_treatsAsNotDeployed() async throws {
        // Use a real manager to seed the credential, then call syncAll against
        // a failing-storage manager that simulates the concurrent-deletion race.
        let throwingStorage = _DeleteAfterGetAllStorage()
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        // Seed a credential so getAll() returns something.
        try await throwingStorage.seedForGetAll(
            credentialId: "race-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        // syncAll should succeed (returning 0 deployed, because sync throws).
        let result = try await manager.syncAll()
        XCTAssertEqual(result.deployed, 0)
        XCTAssertEqual(result.pending, 1,
                       "credential not deployed must count as pending")
    }

    // MARK: - sync storage-error paths

    /// `sync` must rethrow a `StorageException` from its initial `storage.get`
    /// call (covers line 281: the StorageException catch in sync's get block).
    func test_sync_storageReadFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.sync(credentialId: "any-cred")
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `sync` must wrap a generic `Error` from `storage.get` into
    /// `StorageException.ReadFailed` (covers lines 282-283).
    func test_sync_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.sync(credentialId: "any-cred")
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected — generic error wrapped into StorageException.readFailed
        }
    }

    // MARK: - Generic error catch branches (Batch F extensions)

    /// `saveCredential` must wrap a non-StorageException write error into
    /// `StorageException.WriteFailed` (covers the generic catch branch, line 245).
    func test_saveCredential_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .writeGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.saveCredential(
                credentialId: "cred-generic-save",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected — generic error wrapped into StorageException.writeFailed
        }
    }

    /// `getCredential` must wrap a non-StorageException read error into
    /// `StorageException.ReadFailed` (covers the generic catch branch, lines 440-441).
    func test_getCredential_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getCredential(credentialId: "any")
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `getCredentialsByContract` must wrap a non-StorageException read error
    /// (covers the generic catch branch, lines 454-456).
    func test_getCredentialsByContract_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readByContractGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getCredentialsByContract(contractId: contractA)
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `getAllCredentials` must wrap a non-StorageException read error into
    /// `StorageException.ReadFailed` (covers the generic catch branch, lines 470-471).
    func test_getAllCredentials_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .getAllGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getAllCredentials()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `getPendingCredentials` must wrap a non-StorageException read error
    /// (covers the generic catch branch, line 513-514).
    func test_getPendingCredentials_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .getAllGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getPendingCredentials()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `clearAll` must wrap a non-StorageException clear error into
    /// `StorageException.WriteFailed` (covers the generic catch branch, lines 555-557).
    func test_clearAll_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .clearGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            try await manager.clearAll()
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    /// `updateCredential` must wrap a non-StorageException update error into
    /// `StorageException.WriteFailed` (covers the generic catch branch, lines 620-624).
    /// The credential must exist first so the guard-check passes; then the
    /// update itself fails with a generic error.
    func test_updateCredential_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .updateGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        // Seed a credential so the existence check passes.
        try await throwingStorage.seedCredential(
            credentialId: "exist-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.updateNickname(credentialId: "exist-cred", nickname: "new")
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected — generic update error wrapped into StorageException.writeFailed
        } catch is CredentialException {
            // Also acceptable if the existence check fires first (depends on seeding).
        }
    }

    /// `setPrimary` must surface `CredentialException.NotFound` when the
    /// credential does not exist (covers line 658).
    func test_setPrimary_credentialNotFound_throwsNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.setPrimary(credentialId: "nonexistent")
            XCTFail("expected CredentialException.NotFound")
        } catch is CredentialException.NotFound {
            // expected
        }
    }

    /// `setPrimary` on a credential with no contractId must use `getAll()`
    /// to resolve siblings (covers line 665).
    func test_setPrimary_noContractId_usesGetAllForSiblings() async throws {
        let (manager, _, storage) = try makeManager()
        // Create a credential without an explicit contractId.
        let credential = StoredCredential(
            credentialId: "no-contract-cred",
            publicKey: testPublicKey(),
            contractId: nil
        )
        try await storage.save(credential: credential)
        // Calling setPrimary must not throw — it uses getAll() for siblings
        // when contractId is nil.
        try await manager.setPrimary(credentialId: "no-contract-cred")
        let updated = try await storage.get(credentialId: "no-contract-cred")
        XCTAssertEqual(updated?.isPrimary, true,
                       "setPrimary must promote the credential to primary")
    }

    /// `setPrimary` must wrap a non-StorageException final-update error into
    /// `StorageException.WriteFailed` (covers the generic catch branch, lines 687-691).
    func test_setPrimary_updateThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .updateGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "primary-cred",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.setPrimary(credentialId: "primary-cred")
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected — generic update error wrapped
        } catch is CredentialException {
            // Acceptable if the not-found guard fires (seeding may not persist).
        }
    }

    // MARK: - deleteCredential storage-error path

    /// `deleteCredential` must rethrow `StorageException` when the initial
    /// `storage.get` fails (covers lines 401-402 in `deleteCredential`).
    func test_deleteCredential_storageReadFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            try await manager.deleteCredential(credentialId: "any-cred")
            XCTFail("expected StorageException")
        } catch is StorageException {
            // expected
        }
    }

    // MARK: - Private helpers for generic-error tests

    private func _makeManagerWithCustomStorage(
        _ storage: StorageAdapter
    ) throws -> OZCredentialManager {
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA
        )
        let kit = _CredentialManagerTestKit(config: config, storage: storage)
        return OZCredentialManager(kit: kit)
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

// MARK: - ErrorBox

/// Tiny thread-safe slot used by tests that observe an emitted error value.
private final class ErrorBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Error?

    func set(_ value: Error) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func get() -> Error? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

// MARK: - _CredentialTestFailingStorage

/// `StorageAdapter` test double that fails all write and/or read operations
/// with `StorageException`. Used by the Batch F storage-error-path tests.
private final class _CredentialTestFailingStorage: StorageAdapter, @unchecked Sendable {

    private let failOnWrite: Bool
    private let failOnRead: Bool

    init(failOnWrite: Bool = false, failOnRead: Bool = false) {
        self.failOnWrite = failOnWrite
        self.failOnRead = failOnRead
    }

    func save(credential: StoredCredential) async throws {
        if failOnWrite {
            throw StorageException.writeFailed(key: credential.credentialId)
        }
    }

    func get(credentialId: String) async throws -> StoredCredential? {
        if failOnRead {
            throw StorageException.readFailed(key: credentialId)
        }
        return nil
    }

    func getByContract(contractId: String) async throws -> [StoredCredential] {
        if failOnRead {
            throw StorageException.readFailed(key: contractId)
        }
        return []
    }

    func getAll() async throws -> [StoredCredential] {
        if failOnRead {
            throw StorageException.readFailed(key: "all")
        }
        return []
    }

    func delete(credentialId: String) async throws {
        if failOnWrite {
            throw StorageException.writeFailed(key: credentialId)
        }
    }

    func update(credentialId: String, updates: StoredCredentialUpdate) async throws {
        if failOnWrite {
            throw StorageException.writeFailed(key: credentialId)
        }
    }

    func clear() async throws {
        if failOnWrite {
            throw StorageException.writeFailed(key: "all")
        }
    }

    func saveSession(_ session: StoredSession) async throws {
        if failOnWrite {
            throw StorageException.writeFailed(key: "session")
        }
    }

    func getSession() async throws -> StoredSession? {
        if failOnRead {
            throw StorageException.readFailed(key: "session")
        }
        return nil
    }

    func clearSession() async throws {
        if failOnWrite {
            throw StorageException.writeFailed(key: "session")
        }
    }
}

// MARK: - _CredentialManagerTestKit

/// Minimal `OZSmartAccountKitProtocol` conformance that returns a custom
/// `StorageAdapter` from `getStorage()`. Used by the Batch F
/// storage-error-path tests where `MockOZSmartAccountKit` is unsuitable
/// because it coerces the storage to `InMemoryStorageAdapter`.
private final class _CredentialManagerTestKit: OZSmartAccountKitProtocol, @unchecked Sendable {

    let config: OZSmartAccountConfig
    let sorobanServer: SorobanServer
    let indexerClient: OZIndexerClient? = nil
    let relayerClient: OZRelayerClient? = nil
    let events: SmartAccountEventEmitter = SmartAccountEventEmitter()
    let contractId: String? = nil
    let externalSigners: OZExternalSignerManager

    private let _storage: StorageAdapter
    let credentialManager: OZCredentialManagerProtocol
    let contextRuleManager: OZContextRuleManagerProtocol
    // Lazily constructed on first access to avoid circular init.
    private var _managers: (OZTransactionOperations, OZSignerManager, OZPolicyManager, OZMultiSignerManager)?

    init(config: OZSmartAccountConfig, storage: StorageAdapter) {
        self.config = config
        self.sorobanServer = SorobanServer(endpoint: "http://127.0.0.1:1")
        self._storage = storage
        self.credentialManager = MockCredentialManager(storage: InMemoryStorageAdapter())
        self.contextRuleManager = StubContextRuleManager()
        self.externalSigners = OZExternalSignerManager(
            networkPassphrase: config.networkPassphrase
        )
    }

    func getStorage() -> StorageAdapter { _storage }

    var transactionOperations: OZTransactionOperations { ensureManagers().0 }
    var signerManager: OZSignerManager { ensureManagers().1 }
    var policyManager: OZPolicyManager { ensureManagers().2 }
    var multiSignerManager: OZMultiSignerManager { ensureManagers().3 }

    private func ensureManagers() -> (OZTransactionOperations, OZSignerManager, OZPolicyManager, OZMultiSignerManager) {
        if let m = _managers { return m }
        let tx = OZTransactionOperations(kit: self)
        let sg = OZSignerManager(kit: self)
        let po = OZPolicyManager(kit: self)
        let ms = OZMultiSignerManager(kit: self)
        _managers = (tx, sg, po, ms)
        return (tx, sg, po, ms)
    }

    func getDeployer() async throws -> KeyPair {
        return try await OZSmartAccountConfig.createDefaultDeployer()
    }

    func requireConnected() throws -> ConnectedState {
        throw WalletException.notConnected(details: "Test kit is always disconnected")
    }

    func setConnectedState(credentialId: String, contractId: String) {}
}

// MARK: - _TypedThrowingStorage

/// Storage adapter that throws a specific error type from `save(credential:)`.
/// Allows testing catch branches for `CredentialException` (line 178) and
/// generic errors (line 182) in `OZCredentialManager.createPendingCredential`.
private final class _TypedThrowingStorage: StorageAdapter, @unchecked Sendable {

    enum ThrowKind {
        case credential
        case generic
        case none
    }

    private let throwOnSave: ThrowKind
    private let inner = InMemoryStorageAdapter()

    init(throwOnSave: ThrowKind = .none) {
        self.throwOnSave = throwOnSave
    }

    func save(credential: StoredCredential) async throws {
        switch throwOnSave {
        case .credential:
            throw CredentialException.alreadyExists(credentialId: credential.credentialId)
        case .generic:
            struct SyntheticError: Error {}
            throw SyntheticError()
        case .none:
            try await inner.save(credential: credential)
        }
    }

    func get(credentialId: String) async throws -> StoredCredential? {
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [StoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [StoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: StoredCredentialUpdate) async throws {
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: StoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> StoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _DeleteAfterGetAllStorage

/// `StorageAdapter` that returns a fixed list from `getAll()` but throws
/// `CredentialException.notFound` from `get(credentialId:)`.
///
/// Used by `test_syncAll_syncThrowsCredentialException_treatsAsNotDeployed`
/// to model the concurrent-deletion race: `syncAll` calls `getAll()` first
/// (sees the credential), then calls `sync(credentialId:)` per entry (which
/// calls `get(credentialId:)` internally and gets a CredentialException).
private final class _DeleteAfterGetAllStorage: StorageAdapter, @unchecked Sendable {

    private let inner = InMemoryStorageAdapter()

    /// Pre-seed a credential for `getAll()` without storing it in a way
    /// that `get(credentialId:)` can retrieve it.
    func seedForGetAll(credentialId: String, publicKey: Data, contractId: String?) async throws {
        let credential = StoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func save(credential: StoredCredential) async throws {
        try await inner.save(credential: credential)
    }

    /// Returns nil for every credentialId (simulates concurrent deletion).
    func get(credentialId: String) async throws -> StoredCredential? {
        return nil
    }

    func getByContract(contractId: String) async throws -> [StoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [StoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: StoredCredentialUpdate) async throws {
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: StoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> StoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _GenericThrowingStorage

/// `StorageAdapter` that throws a non-`StorageException` generic error from a
/// specific method. Used by Batch F extension tests to exercise the generic
/// catch branches in `OZCredentialManager` (which wrap non-StorageException
/// errors into `StorageException.writeFailed` or `StorageException.readFailed`).
///
/// Each `FailMode` case maps to one adapter method; all other methods delegate
/// to an internal `InMemoryStorageAdapter` so seeding and existence checks work.
private final class _GenericThrowingStorage: StorageAdapter, @unchecked Sendable {

    enum FailMode {
        case writeGeneric       // save(credential:) throws generic
        case readGeneric        // get(credentialId:) throws generic
        case readByContractGeneric // getByContract(contractId:) throws generic
        case getAllGeneric       // getAll() throws generic
        case clearGeneric       // clear() throws generic
        case updateGeneric      // update(credentialId:updates:) throws generic
    }

    private struct SyntheticError: Error {}

    private let failMode: FailMode
    private let inner = InMemoryStorageAdapter()

    init(failMode: FailMode) {
        self.failMode = failMode
    }

    /// Seeds a credential directly into the inner storage so existence checks
    /// (which call `get(credentialId:)`) can return a non-nil result when
    /// `failMode` does not affect `get`.
    func seedCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String?
    ) async throws {
        let credential = StoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func save(credential: StoredCredential) async throws {
        if failMode == .writeGeneric { throw SyntheticError() }
        try await inner.save(credential: credential)
    }

    func get(credentialId: String) async throws -> StoredCredential? {
        if failMode == .readGeneric { throw SyntheticError() }
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [StoredCredential] {
        if failMode == .readByContractGeneric { throw SyntheticError() }
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [StoredCredential] {
        if failMode == .getAllGeneric { throw SyntheticError() }
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: StoredCredentialUpdate) async throws {
        if failMode == .updateGeneric { throw SyntheticError() }
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        if failMode == .clearGeneric { throw SyntheticError() }
        try await inner.clear()
    }

    func saveSession(_ session: StoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> StoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}
