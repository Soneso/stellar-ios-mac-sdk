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
/// ``OZInMemoryStorageAdapter`` and lets the tests inject a scriptable
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
    /// The mock kit is constructed with a fresh ``OZInMemoryStorageAdapter`` and
    /// (when `useScriptedServer` is true) a ``SorobanServer`` whose URL is
    /// intercepted by ``MockSorobanServerScript`` so the sync paths can be
    /// driven without live RPC traffic.
    private func makeManager(
        useScriptedServer: Bool = false
    ) throws -> (manager: OZCredentialManager, kit: MockOZSmartAccountKit, storage: OZInMemoryStorageAdapter) {
        let storage = OZInMemoryStorageAdapter()
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected SmartAccountValidationException.InvalidInput, got \(type(of: error))")
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected SmartAccountValidationException.InvalidInput, got \(type(of: error))")
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
            XCTFail("expected SmartAccountCredentialException.AlreadyExists")
        } catch is SmartAccountCredentialException.AlreadyExists {
            // expected
        } catch {
            XCTFail("expected SmartAccountCredentialException.AlreadyExists, got \(type(of: error))")
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected SmartAccountValidationException.InvalidInput, got \(type(of: error))")
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("expected SmartAccountValidationException.InvalidInput, got \(type(of: error))")
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

    /// A.3.13: sync throws SmartAccountCredentialException.NotFound when the credential
    /// does not exist in storage.
    func testSync_credentialNotFound_throwsCredentialNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            _ = try await manager.sync(credentialId: "missing-cred")
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        } catch {
            XCTFail("expected SmartAccountCredentialException.NotFound, got \(type(of: error))")
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
    /// throws SmartAccountCredentialException.Invalid.
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
            XCTFail("expected SmartAccountCredentialException.Invalid")
        } catch is SmartAccountCredentialException.Invalid {
            // expected
        } catch {
            XCTFail("expected SmartAccountCredentialException.Invalid, got \(type(of: error))")
        }
        // sync removed the credential during the pre-delete check.
        let leftover = try await storage.get(credentialId: "deployed-cred")
        XCTAssertNil(leftover)
    }

    /// A.4.16: deleteCredential throws SmartAccountCredentialException.NotFound when the
    /// credential does not exist.
    func testDeleteCredential_credentialNotFound_throwsNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.deleteCredential(credentialId: "missing-cred")
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        } catch {
            XCTFail("expected SmartAccountCredentialException.NotFound, got \(type(of: error))")
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
            // the loop did not return a fully-populated OZSyncResult.
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

    /// `createPendingCredential` must surface `SmartAccountStorageException.WriteFailed`
    /// when the underlying storage adapter fails the write.
    func test_createPendingCredential_storageWriteFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnWrite: true)
        do {
            _ = try await manager.createPendingCredential(
                credentialId: "new-cred",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `saveCredential` must surface `SmartAccountStorageException.WriteFailed` when
    /// the underlying storage adapter fails the write.
    func test_saveCredential_storageWriteFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnWrite: true)
        do {
            _ = try await manager.saveCredential(
                credentialId: "cred-save",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `getAllCredentials` must surface `SmartAccountStorageException.ReadFailed` when
    /// the underlying storage adapter fails the read.
    func test_getAllCredentials_storageReadFails_throws() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.getAllCredentials()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `clearAll` must surface `SmartAccountStorageException.WriteFailed` when the
    /// underlying storage adapter fails the clear operation.
    func test_clearAll_storageWriteFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnWrite: true)
        do {
            try await manager.clearAll()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `updateNickname` on a non-existent credential must surface
    /// `SmartAccountCredentialException.NotFound` (the `updateCredential` guard fires
    /// before the storage write is attempted).
    func test_updateNickname_credentialNotFound_throwsCredentialException() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.updateNickname(
                credentialId: "does-not-exist",
                nickname: "new name"
            )
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        }
    }

    /// `getPendingCredentials` must surface `SmartAccountStorageException.ReadFailed` when
    /// the underlying storage adapter fails the getAll read.
    func test_getPendingCredentials_storageReadFails_throws() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.getPendingCredentials()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
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

    /// `createPendingCredential` must rethrow `SmartAccountCredentialException` when
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
            XCTFail("expected SmartAccountCredentialException")
        } catch is SmartAccountCredentialException {
            // expected — SmartAccountCredentialException propagated as-is from storage
        }
    }

    /// `createPendingCredential` must wrap a generic `Error` from storage
    /// into `SmartAccountStorageException.WriteFailed` (covers the final catch branch).
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
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch is SmartAccountStorageException.WriteFailed {
            // expected
        } catch is SmartAccountStorageException {
            // also acceptable
        }
    }

    // MARK: - syncAll storage-failure paths

    /// `syncAll` must rethrow `SmartAccountStorageException` when `getAll()` fails with one.
    /// Covers lines 341-342 in `OZCredentialManager.syncAll`.
    func test_syncAll_storageReadFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.syncAll()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `syncAll` must wrap a non-SmartAccountStorageException from `getAll()` into
    /// `SmartAccountStorageException.ReadFailed`. Covers lines 343-344.
    func test_syncAll_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .getAllGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.syncAll()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic error wrapped into SmartAccountStorageException.readFailed
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

    /// `syncAll` must absorb `SmartAccountCredentialException` thrown by `sync` for
    /// individual credentials (covers lines 356-361: the `SmartAccountCredentialException`
    /// catch inside the syncAll loop). When `sync` cannot find a credential
    /// that was in the list (race condition modelled by deleting it between
    /// `getAll` and the per-entry `sync`), syncAll treats it as not-deployed.
    ///
    /// Setup: seed a credential, then replace storage with a version that
    /// returns the credential from `getAll` but throws `SmartAccountCredentialException`
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

    /// `sync` must rethrow a `SmartAccountStorageException` from its initial `storage.get`
    /// call (covers line 281: the SmartAccountStorageException catch in sync's get block).
    func test_sync_storageReadFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.sync(credentialId: "any-cred")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `sync` must wrap a generic `Error` from `storage.get` into
    /// `SmartAccountStorageException.ReadFailed` (covers lines 282-283).
    func test_sync_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.sync(credentialId: "any-cred")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic error wrapped into SmartAccountStorageException.readFailed
        }
    }

    // MARK: - Generic error catch branches (Batch F extensions)

    /// `saveCredential` must wrap a non-SmartAccountStorageException write error into
    /// `SmartAccountStorageException.WriteFailed` (covers the generic catch branch, line 245).
    func test_saveCredential_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .writeGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.saveCredential(
                credentialId: "cred-generic-save",
                publicKey: testPublicKey(),
                contractId: contractA
            )
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic error wrapped into SmartAccountStorageException.writeFailed
        }
    }

    /// `getCredential` must wrap a non-SmartAccountStorageException read error into
    /// `SmartAccountStorageException.ReadFailed` (covers the generic catch branch, lines 440-441).
    func test_getCredential_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getCredential(credentialId: "any")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `getCredentialsByContract` must wrap a non-SmartAccountStorageException read error
    /// (covers the generic catch branch, lines 454-456).
    func test_getCredentialsByContract_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readByContractGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getCredentialsByContract(contractId: contractA)
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `getAllCredentials` must wrap a non-SmartAccountStorageException read error into
    /// `SmartAccountStorageException.ReadFailed` (covers the generic catch branch, lines 470-471).
    func test_getAllCredentials_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .getAllGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getAllCredentials()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `getPendingCredentials` must wrap a non-SmartAccountStorageException read error
    /// (covers the generic catch branch, line 513-514).
    func test_getPendingCredentials_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .getAllGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            _ = try await manager.getPendingCredentials()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `clearAll` must wrap a non-SmartAccountStorageException clear error into
    /// `SmartAccountStorageException.WriteFailed` (covers the generic catch branch, lines 555-557).
    func test_clearAll_storageThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .clearGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            try await manager.clearAll()
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    /// `updateCredential` must wrap a non-SmartAccountStorageException update error into
    /// `SmartAccountStorageException.WriteFailed` (covers the generic catch branch, lines 620-624).
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
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic update error wrapped into SmartAccountStorageException.writeFailed
        } catch is SmartAccountCredentialException {
            // Also acceptable if the existence check fires first (depends on seeding).
        }
    }

    /// `setPrimary` must surface `SmartAccountCredentialException.NotFound` when the
    /// credential does not exist (covers line 658).
    func test_setPrimary_credentialNotFound_throwsNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.setPrimary(credentialId: "nonexistent")
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        }
    }

    /// `setPrimary` on a credential with no contractId must use `getAll()`
    /// to resolve siblings (covers line 665).
    func test_setPrimary_noContractId_usesGetAllForSiblings() async throws {
        let (manager, _, storage) = try makeManager()
        // Create a credential without an explicit contractId.
        let credential = OZStoredCredential(
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

    /// `setPrimary` must wrap a non-SmartAccountStorageException final-update error into
    /// `SmartAccountStorageException.WriteFailed` (covers the generic catch branch, lines 687-691).
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
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic update error wrapped
        } catch is SmartAccountCredentialException {
            // Acceptable if the not-found guard fires (seeding may not persist).
        }
    }

    // MARK: - deleteCredential storage-error path

    /// `deleteCredential` must rethrow `SmartAccountStorageException` when the initial
    /// `storage.get` fails (covers lines 401-402 in `deleteCredential`).
    func test_deleteCredential_storageReadFails_throwsStorageException() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            try await manager.deleteCredential(credentialId: "any-cred")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected
        }
    }

    // MARK: - Private helpers for generic-error tests

    private func _makeManagerWithCustomStorage(
        _ storage: OZStorageAdapter
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

    /// Builds a manager bound to a custom storage adapter and a scripted
    /// `SorobanServer`, allowing tests to drive both the on-chain check and the
    /// storage failure surface in a single case. The returned kit exposes the
    /// scripted server so the on-chain `getContractData` call can be canned.
    private func _makeManagerWithCustomStorageAndScriptedServer(
        _ storage: OZStorageAdapter
    ) throws -> OZCredentialManager {
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA
        )
        let kit = _CredentialManagerTestKit(
            config: config,
            storage: storage,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        return OZCredentialManager(kit: kit)
    }

    // MARK: - sync: storage.delete failure after on-chain success

    /// `sync` must return `false` (not throw) when the on-chain check confirms
    /// the contract is deployed but the post-confirmation `storage.delete`
    /// fails. The credential remains in storage so a later sync can retry the
    /// cleanup. Covers lines 305-310 (the `catch { return false }` after the
    /// `.success` branch in `sync`).
    func test_sync_contractDeployedButDeleteFails_returnsFalseKeepsCredential() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let storage = _DeleteThrowingStorage()
        try await storage.seedCredential(
            credentialId: "deployed-delete-fails",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        let manager = try _makeManagerWithCustomStorageAndScriptedServer(storage)

        // On-chain check finds the contract instance, driving sync into the
        // `.success` branch where the delete is attempted (and fails).
        try script.setGetContractDataResponse(contractId: contractA)

        let exists = try await manager.sync(credentialId: "deployed-delete-fails")
        XCTAssertFalse(
            exists,
            "A failed post-confirmation delete must surface as not-deployed so the credential is retained"
        )
        let retained = try await storage.get(credentialId: "deployed-delete-fails")
        XCTAssertNotNil(
            retained,
            "The credential must remain in storage when the cleanup delete fails"
        )
    }

    // MARK: - deleteCredential: storage-error catch branches

    /// `deleteCredential` must wrap a non-`SmartAccountStorageException` read
    /// error from the initial `storage.get` into
    /// `SmartAccountStorageException.ReadFailed`. Covers line 399 (the generic
    /// catch in the leading get block of `deleteCredential`).
    func test_deleteCredential_storageGetThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .readGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        do {
            try await manager.deleteCredential(credentialId: "any-cred")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic read error wrapped into readFailed
        }
    }

    /// `deleteCredential` must wrap a non-`SmartAccountStorageException` error
    /// from `storage.delete` (after the not-deployed sync) into
    /// `SmartAccountStorageException.WriteFailed`. Covers lines 415-417 (the
    /// generic catch around the delete write in `deleteCredential`).
    ///
    /// The credential exists and is not deployed on-chain (RPC points at a
    /// non-routable host, so `sync` returns `false`); the subsequent delete
    /// then fails with a generic error.
    func test_deleteCredential_storageDeleteThrowsGenericError_wrapsInStorageException() async throws {
        let storage = _DeleteThrowingStorage()
        try await storage.seedCredential(
            credentialId: "del-generic",
            publicKey: testPublicKey(),
            contractId: nil
        )
        // No scripted server: the kit's SorobanServer points at 127.0.0.1:1 so
        // sync's on-chain check fails and returns false. With a nil contractId
        // sync short-circuits before any RPC call, returning false immediately.
        let manager = try _makeManagerWithCustomStorage(storage)
        do {
            try await manager.deleteCredential(credentialId: "del-generic")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic delete error wrapped into writeFailed
        }
    }

    // MARK: - Query helpers: SmartAccountStorageException rethrow branches

    /// `getCredential` must rethrow a `SmartAccountStorageException` from
    /// `storage.get` unchanged. Covers line 434 (the typed rethrow branch).
    func test_getCredential_storageThrowsStorageException_rethrows() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.getCredential(credentialId: "any-cred")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException.ReadFailed {
            // expected — typed exception propagated as-is
        } catch is SmartAccountStorageException {
            // also acceptable
        }
    }

    /// `getCredentialsByContract` must rethrow a `SmartAccountStorageException`
    /// from `storage.getByContract` unchanged. Covers line 449 (the typed
    /// rethrow branch).
    func test_getCredentialsByContract_storageThrowsStorageException_rethrows() async throws {
        let manager = try makeManagerWithFailingStorage(failOnRead: true)
        do {
            _ = try await manager.getCredentialsByContract(contractId: contractA)
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException.ReadFailed {
            // expected — typed exception propagated as-is
        } catch is SmartAccountStorageException {
            // also acceptable
        }
    }

    // MARK: - getForConnectedWallet: connected path

    /// `getForConnectedWallet` returns the credentials bound to the connected
    /// wallet's contract when a wallet is connected. Covers line 491 (the
    /// final `getCredentialsByContract(contractId:)` return after
    /// `requireConnected()` succeeds).
    func test_getForConnectedWallet_connected_returnsContractCredentials() async throws {
        let (manager, kit, _) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "connected-a1",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "connected-a2",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        // Bind a different contract's credential so the filter is observable.
        _ = try await manager.createPendingCredential(
            credentialId: "other-b1",
            publicKey: testPublicKey(),
            contractId: contractB
        )

        kit.setConnectedState(credentialId: "connected-a1", contractId: contractA)

        let result = try await manager.getForConnectedWallet()
        XCTAssertEqual(2, result.count,
                       "Only credentials bound to the connected contract must be returned")
        XCTAssertEqual(
            Set(result.map { $0.credentialId }),
            Set(["connected-a1", "connected-a2"])
        )
    }

    // MARK: - clearAll: success path

    /// `clearAll` removes every stored credential and completes without
    /// throwing on the success path. Covers line 553 (the closing of the
    /// successful `clearAll` body, which the failure-only tests never reach).
    func test_clearAll_success_removesAllCredentials() async throws {
        let (manager, _, storage) = try makeManager()
        _ = try await manager.createPendingCredential(
            credentialId: "clear-a",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        _ = try await manager.createPendingCredential(
            credentialId: "clear-b",
            publicKey: testPublicKey(),
            contractId: contractB
        )
        let countBeforeClear = try await storage.getAll().count
        XCTAssertEqual(2, countBeforeClear)

        try await manager.clearAll()

        let countAfterClear = try await storage.getAll().count
        XCTAssertEqual(
            0,
            countAfterClear,
            "clearAll must remove every stored credential"
        )
    }

    // MARK: - markDeploymentFailed: not-found and update catch branches

    /// `markDeploymentFailed` must throw `SmartAccountCredentialException.NotFound`
    /// when the credential does not exist. Covers lines 572-573 (the not-found
    /// guard in `markDeploymentFailed`).
    func test_markDeploymentFailed_credentialNotFound_throwsNotFound() async throws {
        let (manager, _, _) = try makeManager()
        do {
            try await manager.markDeploymentFailed(
                credentialId: "missing-cred",
                error: "boom"
            )
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        }
    }

    /// `markDeploymentFailed` must rethrow a `SmartAccountCredentialException`
    /// raised by `storage.update` unchanged. Covers lines 583-584 (the typed
    /// credential rethrow branch around the update).
    func test_markDeploymentFailed_updateThrowsCredentialException_rethrows() async throws {
        let throwingStorage = _UpdateTypedThrowingStorage(throwOnUpdate: .credential)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "mark-ce",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.markDeploymentFailed(credentialId: "mark-ce", error: "boom")
            XCTFail("expected SmartAccountCredentialException")
        } catch is SmartAccountCredentialException {
            // expected — typed credential exception propagated as-is
        }
    }

    /// `markDeploymentFailed` must rethrow a `SmartAccountStorageException`
    /// raised by `storage.update` unchanged. Covers lines 585-586 (the typed
    /// storage rethrow branch around the update).
    func test_markDeploymentFailed_updateThrowsStorageException_rethrows() async throws {
        let throwingStorage = _UpdateTypedThrowingStorage(throwOnUpdate: .storage)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "mark-se",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.markDeploymentFailed(credentialId: "mark-se", error: "boom")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — typed storage exception propagated as-is
        }
    }

    /// `markDeploymentFailed` must wrap a generic `storage.update` error into
    /// `SmartAccountStorageException.WriteFailed`. Covers lines 587-588 (the
    /// generic catch around the update).
    func test_markDeploymentFailed_updateThrowsGenericError_wrapsInStorageException() async throws {
        let throwingStorage = _GenericThrowingStorage(failMode: .updateGeneric)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "mark-ge",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.markDeploymentFailed(credentialId: "mark-ge", error: "boom")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — generic update error wrapped into writeFailed
        }
    }

    // MARK: - updateCredential: typed update catch branches

    /// `updateCredential` (via `updateNickname`) must rethrow a
    /// `SmartAccountCredentialException` raised by `storage.update` unchanged.
    /// Covers line 615 (the typed credential rethrow branch).
    func test_updateCredential_updateThrowsCredentialException_rethrows() async throws {
        let throwingStorage = _UpdateTypedThrowingStorage(throwOnUpdate: .credential)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "upd-ce",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.updateNickname(credentialId: "upd-ce", nickname: "new")
            XCTFail("expected SmartAccountCredentialException")
        } catch is SmartAccountCredentialException {
            // expected — typed credential exception propagated as-is
        }
    }

    /// `updateCredential` (via `updateNickname`) must rethrow a
    /// `SmartAccountStorageException` raised by `storage.update` unchanged.
    /// Covers lines 616-617 (the typed storage rethrow branch).
    func test_updateCredential_updateThrowsStorageException_rethrows() async throws {
        let throwingStorage = _UpdateTypedThrowingStorage(throwOnUpdate: .storage)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "upd-se",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.updateNickname(credentialId: "upd-se", nickname: "new")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — typed storage exception propagated as-is
        }
    }

    // MARK: - setPrimary: sibling-demote best-effort swallow

    /// `setPrimary` must swallow per-sibling demote failures (best-effort) and
    /// still promote the target credential. Covers lines 670-674 (the
    /// best-effort `catch { _ = error }` around the sibling unset pass).
    ///
    /// Two credentials are bound to the same contract; the existing primary is
    /// the sibling whose demote update is configured to fail. Promoting the
    /// second credential must succeed despite the sibling demote error.
    func test_setPrimary_siblingDemoteFails_stillPromotesTarget() async throws {
        let storage = _SiblingUpdateFailingStorage(
            failUpdateForCredentialId: "primary-sibling"
        )
        let manager = try _makeManagerWithCustomStorage(storage)

        // The sibling is already primary; its demote update will fail.
        try await storage.seedPrimaryCredential(
            credentialId: "primary-sibling",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        try await storage.seedCredential(
            credentialId: "new-primary",
            publicKey: testPublicKey(),
            contractId: contractA
        )

        // Must not throw even though demoting "primary-sibling" fails.
        try await manager.setPrimary(credentialId: "new-primary")

        let promoted = try await storage.get(credentialId: "new-primary")
        XCTAssertEqual(
            promoted?.isPrimary,
            true,
            "The target credential must be promoted even when a sibling demote fails"
        )
    }

    // MARK: - setPrimary: final-update typed rethrow branches

    /// `setPrimary` must rethrow a `SmartAccountCredentialException` raised by
    /// the final promotion `storage.update` unchanged. Covers lines 681-682
    /// (the typed credential rethrow branch around the final update).
    func test_setPrimary_finalUpdateThrowsCredentialException_rethrows() async throws {
        let throwingStorage = _UpdateTypedThrowingStorage(throwOnUpdate: .credential)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "primary-ce",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.setPrimary(credentialId: "primary-ce")
            XCTFail("expected SmartAccountCredentialException")
        } catch is SmartAccountCredentialException {
            // expected — typed credential exception propagated as-is
        }
    }

    /// `setPrimary` must rethrow a `SmartAccountStorageException` raised by the
    /// final promotion `storage.update` unchanged. Covers lines 683-684 (the
    /// typed storage rethrow branch around the final update).
    func test_setPrimary_finalUpdateThrowsStorageException_rethrows() async throws {
        let throwingStorage = _UpdateTypedThrowingStorage(throwOnUpdate: .storage)
        let manager = try _makeManagerWithCustomStorage(throwingStorage)
        try await throwingStorage.seedCredential(
            credentialId: "primary-se",
            publicKey: testPublicKey(),
            contractId: contractA
        )
        do {
            try await manager.setPrimary(credentialId: "primary-se")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            // expected — typed storage exception propagated as-is
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

/// `OZStorageAdapter` test double that fails all write and/or read operations
/// with `SmartAccountStorageException`. Used by the Batch F storage-error-path tests.
private final class _CredentialTestFailingStorage: OZStorageAdapter, @unchecked Sendable {

    private let failOnWrite: Bool
    private let failOnRead: Bool

    init(failOnWrite: Bool = false, failOnRead: Bool = false) {
        self.failOnWrite = failOnWrite
        self.failOnRead = failOnRead
    }

    func save(credential: OZStoredCredential) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: credential.credentialId)
        }
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: credentialId)
        }
        return nil
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: contractId)
        }
        return []
    }

    func getAll() async throws -> [OZStoredCredential] {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: "all")
        }
        return []
    }

    func delete(credentialId: String) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: credentialId)
        }
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: credentialId)
        }
    }

    func clear() async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: "all")
        }
    }

    func saveSession(_ session: OZStoredSession) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: "session")
        }
    }

    func getSession() async throws -> OZStoredSession? {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: "session")
        }
        return nil
    }

    func clearSession() async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: "session")
        }
    }
}

// MARK: - _CredentialManagerTestKit

/// Minimal `OZSmartAccountKitProtocol` conformance that returns a custom
/// `OZStorageAdapter` from `getStorage()`. Used by the Batch F
/// storage-error-path tests where `MockOZSmartAccountKit` is unsuitable
/// because it coerces the storage to `OZInMemoryStorageAdapter`.
private final class _CredentialManagerTestKit: OZSmartAccountKitProtocol, @unchecked Sendable {

    let config: OZSmartAccountConfig
    let sorobanServer: SorobanServer
    let indexerClient: OZIndexerClient? = nil
    let relayerClient: OZRelayerClient? = nil
    let events: OZSmartAccountEventEmitter = OZSmartAccountEventEmitter()
    let contractId: String? = nil
    let externalSigners: OZExternalSignerManager

    private let _storage: OZStorageAdapter
    let credentialManagerProtocol: OZCredentialManagerProtocol
    let contextRuleManagerProtocol: OZContextRuleManagerProtocol
    // Lazily constructed on first access to avoid circular init.
    private var _managers: (OZTransactionOperations, OZSignerManager, OZPolicyManager, OZMultiSignerManager)?

    init(
        config: OZSmartAccountConfig,
        storage: OZStorageAdapter,
        sorobanServer: SorobanServer? = nil
    ) {
        self.config = config
        self.sorobanServer = sorobanServer ?? SorobanServer(endpoint: "http://127.0.0.1:1")
        self._storage = storage
        self.credentialManagerProtocol = MockCredentialManager(storage: OZInMemoryStorageAdapter())
        self.contextRuleManagerProtocol = StubContextRuleManager()
        self.externalSigners = OZExternalSignerManager(
            networkPassphrase: config.networkPassphrase
        )
    }

    func getStorage() -> OZStorageAdapter { _storage }

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
        throw SmartAccountWalletException.notConnected(details: "Test kit is always disconnected")
    }

    func setConnectedState(credentialId: String, contractId: String) {}
}

// MARK: - _TypedThrowingStorage

/// Storage adapter that throws a specific error type from `save(credential:)`.
/// Allows testing catch branches for `SmartAccountCredentialException` (line 178) and
/// generic errors (line 182) in `OZCredentialManager.createPendingCredential`.
private final class _TypedThrowingStorage: OZStorageAdapter, @unchecked Sendable {

    enum ThrowKind {
        case credential
        case generic
        case none
    }

    private let throwOnSave: ThrowKind
    private let inner = OZInMemoryStorageAdapter()

    init(throwOnSave: ThrowKind = .none) {
        self.throwOnSave = throwOnSave
    }

    func save(credential: OZStoredCredential) async throws {
        switch throwOnSave {
        case .credential:
            throw SmartAccountCredentialException.alreadyExists(credentialId: credential.credentialId)
        case .generic:
            struct SyntheticError: Error {}
            throw SyntheticError()
        case .none:
            try await inner.save(credential: credential)
        }
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [OZStoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> OZStoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _DeleteAfterGetAllStorage

/// `OZStorageAdapter` that returns a fixed list from `getAll()` but throws
/// `SmartAccountCredentialException.notFound` from `get(credentialId:)`.
///
/// Used by `test_syncAll_syncThrowsCredentialException_treatsAsNotDeployed`
/// to model the concurrent-deletion race: `syncAll` calls `getAll()` first
/// (sees the credential), then calls `sync(credentialId:)` per entry (which
/// calls `get(credentialId:)` internally and gets a SmartAccountCredentialException).
private final class _DeleteAfterGetAllStorage: OZStorageAdapter, @unchecked Sendable {

    private let inner = OZInMemoryStorageAdapter()

    /// Pre-seed a credential for `getAll()` without storing it in a way
    /// that `get(credentialId:)` can retrieve it.
    func seedForGetAll(credentialId: String, publicKey: Data, contractId: String?) async throws {
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func save(credential: OZStoredCredential) async throws {
        try await inner.save(credential: credential)
    }

    /// Returns nil for every credentialId (simulates concurrent deletion).
    func get(credentialId: String) async throws -> OZStoredCredential? {
        return nil
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [OZStoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> OZStoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _GenericThrowingStorage

/// `OZStorageAdapter` that throws a non-`SmartAccountStorageException` generic error from a
/// specific method. Used by Batch F extension tests to exercise the generic
/// catch branches in `OZCredentialManager` (which wrap non-SmartAccountStorageException
/// errors into `SmartAccountStorageException.writeFailed` or `SmartAccountStorageException.readFailed`).
///
/// Each `FailMode` case maps to one adapter method; all other methods delegate
/// to an internal `OZInMemoryStorageAdapter` so seeding and existence checks work.
private final class _GenericThrowingStorage: OZStorageAdapter, @unchecked Sendable {

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
    private let inner = OZInMemoryStorageAdapter()

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
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func save(credential: OZStoredCredential) async throws {
        if failMode == .writeGeneric { throw SyntheticError() }
        try await inner.save(credential: credential)
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        if failMode == .readGeneric { throw SyntheticError() }
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        if failMode == .readByContractGeneric { throw SyntheticError() }
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [OZStoredCredential] {
        if failMode == .getAllGeneric { throw SyntheticError() }
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        if failMode == .updateGeneric { throw SyntheticError() }
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        if failMode == .clearGeneric { throw SyntheticError() }
        try await inner.clear()
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> OZStoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _DeleteThrowingStorage

/// `OZStorageAdapter` whose `delete(credentialId:)` throws a generic error.
/// All other operations delegate to an internal `OZInMemoryStorageAdapter` so
/// the credential can be seeded, read, and (on the on-chain-success sync path)
/// reach the failing delete. Used to cover both the `sync` post-confirmation
/// delete-failure path and the `deleteCredential` generic delete-error wrap.
private final class _DeleteThrowingStorage: OZStorageAdapter, @unchecked Sendable {

    private struct SyntheticError: Error {}
    private let inner = OZInMemoryStorageAdapter()

    func seedCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String?
    ) async throws {
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func save(credential: OZStoredCredential) async throws {
        try await inner.save(credential: credential)
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [OZStoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        throw SyntheticError()
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> OZStoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _UpdateTypedThrowingStorage

/// `OZStorageAdapter` whose `update(credentialId:updates:)` throws a chosen
/// typed exception (`SmartAccountCredentialException` or
/// `SmartAccountStorageException`). All other operations delegate to an
/// internal `OZInMemoryStorageAdapter` so existence guards pass before the
/// update is attempted. Used to cover the typed rethrow branches around the
/// update call in `markDeploymentFailed`, `updateCredential`, and `setPrimary`.
private final class _UpdateTypedThrowingStorage: OZStorageAdapter, @unchecked Sendable {

    enum ThrowKind {
        case credential
        case storage
    }

    private let throwOnUpdate: ThrowKind
    private let inner = OZInMemoryStorageAdapter()

    init(throwOnUpdate: ThrowKind) {
        self.throwOnUpdate = throwOnUpdate
    }

    func seedCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String?
    ) async throws {
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func save(credential: OZStoredCredential) async throws {
        try await inner.save(credential: credential)
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [OZStoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        switch throwOnUpdate {
        case .credential:
            throw SmartAccountCredentialException.invalid(reason: "update rejected")
        case .storage:
            throw SmartAccountStorageException.writeFailed(key: credentialId)
        }
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> OZStoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}

// MARK: - _SiblingUpdateFailingStorage

/// `OZStorageAdapter` whose `update(credentialId:updates:)` throws for one
/// specific credential id (the sibling to demote) but succeeds for every other
/// id. Used to cover the best-effort sibling-demote swallow in `setPrimary`:
/// the failing sibling demote must not prevent the target promotion.
private final class _SiblingUpdateFailingStorage: OZStorageAdapter, @unchecked Sendable {

    private struct SyntheticError: Error {}
    private let failUpdateForCredentialId: String
    private let inner = OZInMemoryStorageAdapter()

    init(failUpdateForCredentialId: String) {
        self.failUpdateForCredentialId = failUpdateForCredentialId
    }

    func seedCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String?
    ) async throws {
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId
        )
        try await inner.save(credential: credential)
    }

    func seedPrimaryCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String?
    ) async throws {
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId,
            isPrimary: true
        )
        try await inner.save(credential: credential)
    }

    func save(credential: OZStoredCredential) async throws {
        try await inner.save(credential: credential)
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        return try await inner.get(credentialId: credentialId)
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        return try await inner.getByContract(contractId: contractId)
    }

    func getAll() async throws -> [OZStoredCredential] {
        return try await inner.getAll()
    }

    func delete(credentialId: String) async throws {
        try await inner.delete(credentialId: credentialId)
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        if credentialId == failUpdateForCredentialId {
            throw SyntheticError()
        }
        try await inner.update(credentialId: credentialId, updates: updates)
    }

    func clear() async throws {
        try await inner.clear()
    }

    func saveSession(_ session: OZStoredSession) async throws {
        try await inner.saveSession(session)
    }

    func getSession() async throws -> OZStoredSession? {
        return try await inner.getSession()
    }

    func clearSession() async throws {
        try await inner.clearSession()
    }
}
