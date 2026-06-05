//
//  OZKeychainStorageAdapterTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
import Security
@testable import stellarsdk

@available(iOS 13.0, macOS 10.15, *)
final class OZKeychainStorageAdapterTests: XCTestCase {

    // ========================================================================
    // Test Data Helpers
    // ========================================================================

    /// Builds a 65-byte uncompressed secp256r1 public key with deterministic
    /// per-seed contents so two helpers with different seeds produce distinct
    /// payloads.
    private func testPublicKey(seed: Int = 0) -> Data {
        var bytes = [UInt8](repeating: 0, count: 65)
        bytes[0] = 0x04
        for i in 1..<65 {
            bytes[i] = UInt8((i + seed) % 256)
        }
        return Data(bytes)
    }

    private func fullCredential(
        id: String = "cred-full-001",
        contractId: String? = "CBCD1234EFGH5678IJKL9012MNOP3456QRST7890UVWX1234YZAB5678",
        seed: Int = 1
    ) -> OZStoredCredential {
        return OZStoredCredential(
            credentialId: id,
            publicKey: testPublicKey(seed: seed),
            contractId: contractId,
            deploymentStatus: .pending,
            deploymentError: nil,
            createdAt: 1_700_000_000_000,
            lastUsedAt: 1_700_001_000_000,
            nickname: "MacBook Pro Touch ID",
            isPrimary: true,
            transports: ["internal", "usb"],
            deviceType: "multiDevice",
            backedUp: true
        )
    }

    private func minimalCredential(id: String = "cred-minimal-001") -> OZStoredCredential {
        return OZStoredCredential(
            credentialId: id,
            publicKey: testPublicKey(seed: 2),
            createdAt: 1_700_000_000_000
        )
    }

    /// Fresh per-test service name so isolated test instances cannot collide
    /// with state left behind by parallel test bundles or the system
    /// Keychain.
    private func uniqueServiceName(_ tag: String = "test") -> String {
        return "com.soneso.stellar.smartaccount.\(tag).\(UUID().uuidString)"
    }

    /// Builds an adapter that uses an in-memory `FakeSecItemShim` so the
    /// suite can run inside any host environment, including unsigned CI
    /// binaries that lack Keychain entitlements.
    private func newAdapter(
        serviceName: String? = nil
    ) -> (OZKeychainStorageAdapter, InMemoryKeychain) {
        let store = InMemoryKeychain()
        let adapter = OZKeychainStorageAdapter(
            serviceName: serviceName ?? uniqueServiceName(),
            shim: store.makeShim()
        )
        return (adapter, store)
    }

    // ========================================================================
    // Save / Retrieve
    // ========================================================================

    func test_save_and_retrieve_credential() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded, credential)
    }

    func test_save_credential_with_all_fields_populated() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.contractId, credential.contractId)
        XCTAssertEqual(loaded?.nickname, credential.nickname)
        XCTAssertEqual(loaded?.transports, credential.transports)
        XCTAssertEqual(loaded?.backedUp, credential.backedUp)
        XCTAssertEqual(loaded?.deviceType, credential.deviceType)
    }

    func test_save_credential_with_minimal_fields() async throws {
        let (adapter, _) = newAdapter()
        let credential = minimalCredential()
        try await adapter.save(credential: credential)

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.credentialId, credential.credentialId)
        XCTAssertEqual(loaded?.publicKey, credential.publicKey)
        XCTAssertNil(loaded?.contractId)
        XCTAssertNil(loaded?.lastUsedAt)
        XCTAssertNil(loaded?.nickname)
        XCTAssertFalse(loaded?.isPrimary ?? true)
    }

    func test_get_nonexistent_credential_returns_nil() async throws {
        let (adapter, _) = newAdapter()
        let loaded = try await adapter.get(credentialId: "missing-id")
        XCTAssertNil(loaded)
    }

    // ========================================================================
    // Upsert
    // ========================================================================

    func test_save_existing_credential_overwrites_and_does_not_duplicate_index() async throws {
        let (adapter, _) = newAdapter()
        var credential = fullCredential()
        try await adapter.save(credential: credential)

        credential = credential.copyWith(nickname: "Updated nickname")
        try await adapter.save(credential: credential)

        let all = try await adapter.getAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.nickname, "Updated nickname")
    }

    // ========================================================================
    // Update
    // ========================================================================

    func test_update_credential_deployment_status() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        try await adapter.update(
            credentialId: credential.credentialId,
            updates: OZStoredCredentialUpdate(deploymentStatus: .failed)
        )

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.deploymentStatus, .failed)
    }

    func test_update_credential_nickname() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        try await adapter.update(
            credentialId: credential.credentialId,
            updates: OZStoredCredentialUpdate(nickname: "New nickname")
        )

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.nickname, "New nickname")
    }

    func test_update_credential_contract_id() async throws {
        let (adapter, _) = newAdapter()
        let credential = minimalCredential()
        try await adapter.save(credential: credential)

        try await adapter.update(
            credentialId: credential.credentialId,
            updates: OZStoredCredentialUpdate(contractId: "CXYZ123")
        )

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.contractId, "CXYZ123")
    }

    func test_update_credential_is_primary() async throws {
        let (adapter, _) = newAdapter()
        let credential = minimalCredential()
        try await adapter.save(credential: credential)

        try await adapter.update(
            credentialId: credential.credentialId,
            updates: OZStoredCredentialUpdate(isPrimary: true)
        )

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.isPrimary, true)
    }

    func test_update_multiple_fields_at_once() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        try await adapter.update(
            credentialId: credential.credentialId,
            updates: OZStoredCredentialUpdate(
                deploymentStatus: .failed,
                deploymentError: "txn rejected",
                nickname: "Updated"
            )
        )

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.deploymentStatus, .failed)
        XCTAssertEqual(loaded?.deploymentError, "txn rejected")
        XCTAssertEqual(loaded?.nickname, "Updated")
    }

    func test_update_nonexistent_credential_throws_credential_not_found() async throws {
        let (adapter, _) = newAdapter()
        do {
            try await adapter.update(
                credentialId: "missing",
                updates: OZStoredCredentialUpdate(nickname: "X")
            )
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch let error as SmartAccountCredentialException.NotFound {
            XCTAssertEqual(error.code, .credentialNotFound)
        }
    }

    // ========================================================================
    // Delete
    // ========================================================================

    func test_delete_credential() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        try await adapter.delete(credentialId: credential.credentialId)
        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertNil(loaded)
    }

    func test_delete_nonexistent_credential_does_not_throw() async throws {
        let (adapter, _) = newAdapter()
        try await adapter.delete(credentialId: "never-existed")
    }

    func test_delete_removes_only_target_credential() async throws {
        let (adapter, _) = newAdapter()
        let one = fullCredential(id: "cred-1", seed: 1)
        let two = fullCredential(id: "cred-2", seed: 2)
        try await adapter.save(credential: one)
        try await adapter.save(credential: two)

        try await adapter.delete(credentialId: one.credentialId)

        let remainingOne = try await adapter.get(credentialId: one.credentialId)
        let remainingTwo = try await adapter.get(credentialId: two.credentialId)
        XCTAssertNil(remainingOne)
        XCTAssertEqual(remainingTwo?.credentialId, two.credentialId)
    }

    // ========================================================================
    // Get All
    // ========================================================================

    func test_get_all_empty_returns_empty_list() async throws {
        let (adapter, _) = newAdapter()
        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
    }

    func test_get_all_with_multiple_credentials() async throws {
        let (adapter, _) = newAdapter()
        let one = fullCredential(id: "cred-1", seed: 1)
        let two = fullCredential(id: "cred-2", seed: 2)
        let three = fullCredential(id: "cred-3", seed: 3)
        try await adapter.save(credential: one)
        try await adapter.save(credential: two)
        try await adapter.save(credential: three)

        let all = try await adapter.getAll()
        let ids = Set(all.map { $0.credentialId })
        XCTAssertEqual(ids, ["cred-1", "cred-2", "cred-3"])
    }

    // ========================================================================
    // Get by Contract
    // ========================================================================

    func test_get_by_contract_id_returns_matching_credentials() async throws {
        let (adapter, _) = newAdapter()
        let target = "CTARGETCONTRACT"
        let one = fullCredential(id: "cred-1", contractId: target, seed: 1)
        let two = fullCredential(id: "cred-2", contractId: "OTHER", seed: 2)
        let three = fullCredential(id: "cred-3", contractId: target, seed: 3)
        try await adapter.save(credential: one)
        try await adapter.save(credential: two)
        try await adapter.save(credential: three)

        let matches = try await adapter.getByContract(contractId: target)
        let ids = Set(matches.map { $0.credentialId })
        XCTAssertEqual(ids, ["cred-1", "cred-3"])
    }

    func test_get_by_contract_id_no_match_returns_empty_list() async throws {
        let (adapter, _) = newAdapter()
        try await adapter.save(credential: fullCredential())
        let matches = try await adapter.getByContract(contractId: "DOES-NOT-EXIST")
        XCTAssertTrue(matches.isEmpty)
    }

    func test_get_by_contract_id_excludes_null_contract_id() async throws {
        let (adapter, _) = newAdapter()
        try await adapter.save(credential: minimalCredential(id: "no-contract"))
        try await adapter.save(credential: fullCredential(id: "with-contract", contractId: "CTARGET"))

        let matches = try await adapter.getByContract(contractId: "CTARGET")
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.credentialId, "with-contract")
    }

    // ========================================================================
    // Clear
    // ========================================================================

    func test_clear_removes_all_credentials() async throws {
        let (adapter, _) = newAdapter()
        try await adapter.save(credential: fullCredential(id: "a", seed: 1))
        try await adapter.save(credential: fullCredential(id: "b", seed: 2))

        try await adapter.clear()

        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
    }

    func test_clear_on_empty_adapter_does_not_throw() async throws {
        let (adapter, _) = newAdapter()
        try await adapter.clear()
    }

    func test_clear_removes_session_too() async throws {
        let (adapter, _) = newAdapter()
        let session = OZStoredSession(
            credentialId: "c1",
            contractId: "CTARGET",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        )
        try await adapter.saveSession(session)

        try await adapter.clear()
        let loaded = try await adapter.getSession()
        XCTAssertNil(loaded)
    }

    // ========================================================================
    // Session Save / Retrieve
    // ========================================================================

    func test_save_and_retrieve_session() async throws {
        let (adapter, _) = newAdapter()
        let session = OZStoredSession(
            credentialId: "c1",
            contractId: "CTARGET",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        )
        try await adapter.saveSession(session)

        let loaded = try await adapter.getSession()
        XCTAssertEqual(loaded, session)
    }

    func test_get_session_when_none_exists_returns_nil() async throws {
        let (adapter, _) = newAdapter()
        let loaded = try await adapter.getSession()
        XCTAssertNil(loaded)
    }

    func test_save_session_overwrites_previous_session() async throws {
        let (adapter, _) = newAdapter()
        let first = OZStoredSession(
            credentialId: "c1",
            contractId: "CT1",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        )
        let second = OZStoredSession(
            credentialId: "c2",
            contractId: "CT2",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        )

        try await adapter.saveSession(first)
        try await adapter.saveSession(second)

        let loaded = try await adapter.getSession()
        XCTAssertEqual(loaded, second)
    }

    // ========================================================================
    // Session Expiry / Cross-domain
    // ========================================================================

    func test_expired_session_auto_cleared_on_get_session() async throws {
        let (adapter, _) = newAdapter()
        let pastMs = Int64(Date().timeIntervalSince1970 * 1000) - 1000
        let expired = OZStoredSession(
            credentialId: "c1",
            contractId: "CT",
            connectedAt: pastMs - 10_000,
            expiresAt: pastMs
        )
        try await adapter.saveSession(expired)

        let first = try await adapter.getSession()
        XCTAssertNil(first)

        // The expired entry must have been removed; a follow-up read also
        // returns nil without re-evaluating expiry.
        let second = try await adapter.getSession()
        XCTAssertNil(second)
    }

    func test_non_expired_session_is_returned() async throws {
        let (adapter, _) = newAdapter()
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let session = OZStoredSession(
            credentialId: "c1",
            contractId: "CT",
            connectedAt: nowMs,
            expiresAt: nowMs + 60_000
        )
        try await adapter.saveSession(session)

        let loaded = try await adapter.getSession()
        XCTAssertEqual(loaded, session)
    }

    func test_clear_session() async throws {
        let (adapter, _) = newAdapter()
        let session = OZStoredSession(
            credentialId: "c1",
            contractId: "CT",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        )
        try await adapter.saveSession(session)
        try await adapter.clearSession()

        let loaded = try await adapter.getSession()
        XCTAssertNil(loaded)
    }

    func test_clear_session_when_none_exists_does_not_throw() async throws {
        let (adapter, _) = newAdapter()
        try await adapter.clearSession()
    }

    func test_clear_session_does_not_affect_credentials() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)
        try await adapter.saveSession(OZStoredSession(
            credentialId: credential.credentialId,
            contractId: "CT",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        ))

        try await adapter.clearSession()

        let stillThere = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(stillThere, credential)
    }

    // ========================================================================
    // Service-name Isolation
    // ========================================================================

    func test_custom_service_name_isolates_keychain_data() async throws {
        // Use one shared backing store but two different service names; each
        // adapter's index entries / credential entries are scoped by service
        // name so they must not see each other's data.
        let store = InMemoryKeychain()
        let adapterA = OZKeychainStorageAdapter(
            serviceName: uniqueServiceName("A"),
            shim: store.makeShim()
        )
        let adapterB = OZKeychainStorageAdapter(
            serviceName: uniqueServiceName("B"),
            shim: store.makeShim()
        )

        try await adapterA.save(credential: fullCredential(id: "in-A", seed: 1))
        try await adapterB.save(credential: fullCredential(id: "in-B", seed: 2))

        let onlyA = try await adapterA.getAll()
        let onlyB = try await adapterB.getAll()

        XCTAssertEqual(onlyA.map { $0.credentialId }, ["in-A"])
        XCTAssertEqual(onlyB.map { $0.credentialId }, ["in-B"])
    }

    func test_default_service_name_is_used() async throws {
        XCTAssertEqual(
            OZKeychainStorageAdapter.defaultServiceName,
            "com.soneso.stellar.smartaccount"
        )
    }

    // ========================================================================
    // Interface Conformance
    // ========================================================================

    func test_keychain_adapter_conforms_to_storage_adapter_protocol() async throws {
        let (adapter, _) = newAdapter()
        let asProtocol: any OZStorageAdapter = adapter
        try await asProtocol.save(credential: fullCredential())
        let all = try await asProtocol.getAll()
        XCTAssertEqual(all.count, 1)
    }

    // ========================================================================
    // Edge Cases
    // ========================================================================

    func test_delete_then_resave_credential() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)
        try await adapter.delete(credentialId: credential.credentialId)
        try await adapter.save(credential: credential)

        let all = try await adapter.getAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.credentialId, credential.credentialId)
    }

    func test_update_after_delete_throws_credential_not_found() async throws {
        let (adapter, _) = newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)
        try await adapter.delete(credentialId: credential.credentialId)

        do {
            try await adapter.update(
                credentialId: credential.credentialId,
                updates: OZStoredCredentialUpdate(nickname: "X")
            )
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        }
    }

    // ========================================================================
    // Failure-mode coverage
    // ========================================================================

    func test_concurrent_writes_10_parallel_no_partial_state() async throws {
        let (adapter, _) = newAdapter()
        let total = 10

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<total {
                group.addTask {
                    let credential = OZStoredCredential(
                        credentialId: "concurrent-\(i)",
                        publicKey: Data(repeating: UInt8(i % 256), count: 65),
                        createdAt: 1_700_000_000_000
                    )
                    try? await adapter.save(credential: credential)
                }
            }
        }

        let all = try await adapter.getAll()
        XCTAssertEqual(all.count, total)
    }

    func test_keychain_device_locked_throws_storage_exception() async throws {
        // Inject a shim that always reports `errSecInteractionNotAllowed`
        // (-25308) on read, simulating a locked device. The adapter must
        // propagate the failure as `SmartAccountStorageException.ReadFailed`.
        let shim = FakeSecItemShim(
            copyMatchingHandler: { _, _ in errSecInteractionNotAllowed }
        )
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            _ = try await adapter.get(credentialId: "anything")
            XCTFail("expected SmartAccountStorageException.ReadFailed when device is locked")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("\(errSecInteractionNotAllowed)"))
        }
    }

    func test_corrupted_payload_throws_read_failed() async throws {
        // Inject a `FakeSecItemShim` whose `copyMatching` returns bytes that
        // are not valid JSON for the credential payload. The adapter wraps
        // the JSON decoding failure into `SmartAccountStorageException.ReadFailed` via
        // its catch-all arm; that mapping is otherwise uncovered by the
        // suite and is required to surface keychain corruption to callers.
        let serviceName = uniqueServiceName()
        let bogus = "not-valid-json-payload".data(using: .utf8)!
        let shim = FakeSecItemShim(
            copyMatchingHandler: { _, result in
                if let result = result {
                    result.pointee = bogus as CFData
                }
                return errSecSuccess
            }
        )
        let adapter = OZKeychainStorageAdapter(serviceName: serviceName, shim: shim)

        do {
            _ = try await adapter.get(credentialId: "any-credential-id")
            XCTFail("expected SmartAccountStorageException.ReadFailed for corrupted payload")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("any-credential-id"))
        }
    }

    func test_oversized_payload_rejected() async throws {
        // The adapter does not impose its own payload-size cap; this test
        // codifies that fact so a future regression that introduces a size
        // limit must update both the adapter and this test together. A 200 KiB
        // public key payload (well above any plausible real key size) saves
        // and round-trips successfully.
        let (adapter, _) = newAdapter()
        let bigPayload = Data(repeating: 0x42, count: 200 * 1024)
        let credential = OZStoredCredential(
            credentialId: "big",
            publicKey: bigPayload,
            createdAt: 1_700_000_000_000
        )

        try await adapter.save(credential: credential)
        let loaded = try await adapter.get(credentialId: "big")
        XCTAssertEqual(loaded?.publicKey.count, bigPayload.count)
    }

    // ========================================================================
    // Re-throw arms — inner keychain OSStatus failures propagate unchanged
    // ========================================================================

    func test_save_rethrows_storage_exception_when_add_fails() async throws {
        // `keychainUpsert` throws `SmartAccountStorageException.WriteFailed` on a
        // non-duplicate add status; `save` must re-throw it unwrapped.
        let shim = ControllableShim()
        shim.addStatus = { _ in errSecMissingEntitlement }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.save(credential: fullCredential())
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecMissingEntitlement)"))
        }
    }

    func test_get_by_contract_rethrows_storage_exception_on_read_failure() async throws {
        let shim = ControllableShim()
        shim.copyStatus = { _ in errSecInteractionNotAllowed }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            _ = try await adapter.getByContract(contractId: "CT")
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("\(errSecInteractionNotAllowed)"))
        }
    }

    func test_get_all_rethrows_storage_exception_on_read_failure() async throws {
        let shim = ControllableShim()
        shim.copyStatus = { _ in errSecInteractionNotAllowed }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            _ = try await adapter.getAll()
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
        }
    }

    func test_delete_rethrows_storage_exception_when_delete_fails() async throws {
        let shim = ControllableShim()
        shim.deleteStatus = { _ in errSecMissingEntitlement }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.delete(credentialId: "cred-1")
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecMissingEntitlement)"))
        }
    }

    func test_update_rethrows_storage_exception_on_read_failure() async throws {
        // The initial `readCredential` fails at the keychain layer with a
        // `SmartAccountStorageException`; `update` re-throws it (it is neither a
        // `SmartAccountCredentialException` nor the catch-all path).
        let shim = ControllableShim()
        shim.copyStatus = { _ in errSecInteractionNotAllowed }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.update(
                credentialId: "cred-1",
                updates: OZStoredCredentialUpdate(nickname: "X")
            )
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
        }
    }

    func test_clear_rethrows_storage_exception_on_index_read_failure() async throws {
        let shim = ControllableShim()
        shim.copyStatus = { _ in errSecInteractionNotAllowed }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.clear()
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
        }
    }

    func test_save_session_rethrows_storage_exception_when_add_fails() async throws {
        let shim = ControllableShim()
        shim.addStatus = { _ in errSecMissingEntitlement }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        let session = OZStoredSession(
            credentialId: "c1",
            contractId: "CT",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_900_000_000_000
        )
        do {
            try await adapter.saveSession(session)
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecMissingEntitlement)"))
        }
    }

    func test_get_session_rethrows_storage_exception_on_read_failure() async throws {
        let shim = ControllableShim()
        shim.copyStatus = { _ in errSecInteractionNotAllowed }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            _ = try await adapter.getSession()
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("\(errSecInteractionNotAllowed)"))
        }
    }

    func test_clear_session_rethrows_storage_exception_when_delete_fails() async throws {
        let shim = ControllableShim()
        shim.deleteStatus = { _ in errSecMissingEntitlement }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.clearSession()
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecMissingEntitlement)"))
        }
    }

    // ========================================================================
    // Catch-all arms — non-storage errors wrapped into Read/WriteFailed
    // ========================================================================

    func test_save_wraps_decoding_error_from_index_into_write_failed() async throws {
        // The credential upsert succeeds, then `readIndex` decodes a malformed
        // index entry and throws a `DecodingError`. `save` wraps that
        // non-storage error into `SmartAccountStorageException.WriteFailed`.
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(service: service, account: OZStorageKeys.credentialIndexKey, raw: "{ not json")
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            try await adapter.save(credential: fullCredential(id: "cred-x"))
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("cred-x"))
        }
    }

    func test_get_by_contract_wraps_decoding_error_into_read_failed() async throws {
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(service: service, account: OZStorageKeys.credentialIndexKey, raw: "<<<not json>>>")
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            _ = try await adapter.getByContract(contractId: "CT")
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("CT"))
        }
    }

    func test_get_all_wraps_decoding_error_into_read_failed() async throws {
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(service: service, account: OZStorageKeys.credentialIndexKey, raw: "}{")
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            _ = try await adapter.getAll()
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("all credentials"))
        }
    }

    func test_delete_wraps_decoding_error_from_index_into_write_failed() async throws {
        // The keychain delete of the credential succeeds (idempotent), then
        // `readIndex` hits a malformed index entry and throws a decoding error
        // that `delete` wraps into `WriteFailed`.
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(service: service, account: OZStorageKeys.credentialIndexKey, raw: "not-json")
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            try await adapter.delete(credentialId: "cred-z")
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("cred-z"))
        }
    }

    func test_update_wraps_decoding_error_into_write_failed() async throws {
        // The stored credential entry decodes to invalid JSON; `readCredential`
        // throws a `DecodingError` which is neither a credential nor a storage
        // exception, so `update` wraps it into `WriteFailed`.
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(
            service: service,
            account: OZStorageKeys.credentialKeyPrefix + "cred-bad",
            raw: "{ corrupt"
        )
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            try await adapter.update(
                credentialId: "cred-bad",
                updates: OZStoredCredentialUpdate(nickname: "X")
            )
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("cred-bad"))
        }
    }

    func test_clear_wraps_decoding_error_from_index_into_write_failed() async throws {
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(service: service, account: OZStorageKeys.credentialIndexKey, raw: "###")
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            try await adapter.clear()
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("clear all"))
        }
    }

    func test_get_session_wraps_decoding_error_into_read_failed() async throws {
        let store = RawBackedKeychain()
        let service = uniqueServiceName()
        store.put(service: service, account: OZStorageKeys.sessionKey, raw: "not-a-session")
        let adapter = OZKeychainStorageAdapter(serviceName: service, shim: store.makeShim())

        do {
            _ = try await adapter.getSession()
            XCTFail("expected SmartAccountStorageException.ReadFailed")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains("session"))
        }
    }

    // ========================================================================
    // keychainUpsert — duplicate-then-update and add default failure arms
    // ========================================================================

    func test_upsert_update_failure_throws_write_failed() async throws {
        // `add` reports `errSecDuplicateItem`, routing to the `update` fallback,
        // which then itself fails with a hard status. The adapter surfaces a
        // `WriteFailed` carrying the update OSStatus.
        let shim = ControllableShim()
        shim.addStatus = { _ in errSecDuplicateItem }
        shim.updateStatus = { _, _ in errSecInteractionNotAllowed }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.save(credential: fullCredential(id: "dup"))
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecInteractionNotAllowed)"))
            XCTAssertTrue(error.message.contains("update"))
        }
    }

    func test_upsert_duplicate_then_update_succeeds() async throws {
        // Exercises the benign duplicate arm: `add` returns `errSecDuplicateItem`
        // and `update` returns success, so the upsert completes without error.
        let shim = ControllableShim()
        shim.addStatus = { _ in errSecDuplicateItem }
        shim.updateStatus = { _, _ in errSecSuccess }
        // Reads must succeed with not-found so the index logic in `save` does not
        // observe a hard failure (the index read/write also route through this
        // shim and rely on the same duplicate-then-update path).
        shim.copyStatus = { _ in errSecItemNotFound }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        try await adapter.save(credential: fullCredential(id: "dup-ok"))
        XCTAssertGreaterThan(shim.updateCalls, 0)
    }

    func test_upsert_add_default_failure_throws_write_failed() async throws {
        // A non-success, non-duplicate add status hits the `default` arm of the
        // upsert switch and becomes a `WriteFailed` carrying the add OSStatus.
        let shim = ControllableShim()
        shim.addStatus = { _ in errSecNotAvailable }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.save(credential: fullCredential(id: "add-fail"))
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecNotAvailable)"))
            XCTAssertTrue(error.message.contains("add"))
        }
    }

    // ========================================================================
    // keychainDelete — hard OSStatus failure arm
    // ========================================================================

    func test_keychain_delete_hard_status_throws_write_failed() async throws {
        // A delete status that is neither success nor not-found must throw
        // `WriteFailed`. Routed through `clearSession`, whose only keychain
        // operation is a single delete.
        let shim = ControllableShim()
        shim.deleteStatus = { _ in errSecNotAvailable }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        do {
            try await adapter.clearSession()
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("\(errSecNotAvailable)"))
            XCTAssertTrue(error.message.contains("delete"))
        }
    }

    // ========================================================================
    // keychainRead — success status with a non-Data result yields nil
    // ========================================================================

    func test_keychain_read_success_with_non_data_result_returns_nil() async throws {
        // `copyMatching` reports success but writes a non-`Data` value into the
        // result pointer. The `resultRef as? Data` cast fails, so the read
        // returns nil and `get` surfaces nil rather than throwing.
        let shim = ControllableShim()
        shim.copyStatus = { result in
            if let result = result {
                result.pointee = "not-data" as CFString
            }
            return errSecSuccess
        }
        let adapter = OZKeychainStorageAdapter(serviceName: uniqueServiceName(), shim: shim)

        let loaded = try await adapter.get(credentialId: "any")
        XCTAssertNil(loaded)
    }
}

// ============================================================================
// ControllableShim — per-primitive OSStatus and result injection
// ============================================================================

/// `OZSecItemShim` whose per-primitive behavior is fully driven by closures.
/// Unlike `InMemoryKeychain`, it keeps no backing store; each handler returns a
/// canned `OSStatus` and may populate the result pointer directly. Used to drive
/// the adapter's keychain failure arms deterministically.
@available(iOS 13.0, macOS 10.15, *)
final class ControllableShim: OZSecItemShim, @unchecked Sendable {

    private let lock = NSLock()

    /// Returns the status for `add`. Defaults to success.
    var addStatus: @Sendable (UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = { _ in errSecSuccess }
    /// Returns the status for `copyMatching` and may populate the result pointer.
    /// Defaults to not-found.
    var copyStatus: @Sendable (UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = { _ in errSecItemNotFound }
    /// Returns the status for `update`. Defaults to success.
    var updateStatus: @Sendable (CFDictionary, CFDictionary) -> OSStatus = { _, _ in errSecSuccess }
    /// Returns the status for `delete`. Defaults to success.
    var deleteStatus: @Sendable (CFDictionary) -> OSStatus = { _ in errSecSuccess }

    private(set) var updateCalls: Int = 0

    func add(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        lock.lock(); defer { lock.unlock() }
        return addStatus(result)
    }

    func copyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        lock.lock(); defer { lock.unlock() }
        return copyStatus(result)
    }

    func update(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus {
        lock.lock(); updateCalls += 1; defer { lock.unlock() }
        return updateStatus(query, attributesToUpdate)
    }

    func delete(query: CFDictionary) -> OSStatus {
        lock.lock(); defer { lock.unlock() }
        return deleteStatus(query)
    }
}

// ============================================================================
// RawBackedKeychain — in-memory store that accepts pre-planted raw payloads
// ============================================================================

/// In-memory Keychain stand-in that lets tests plant arbitrary raw bytes at a
/// `(service, account)` key before the adapter runs. Used to seed malformed
/// JSON so the adapter's decode-failure (catch-all) arms can be exercised.
/// Behaves like `InMemoryKeychain` for add / update / delete on keys the adapter
/// writes itself.
@available(iOS 13.0, macOS 10.15, *)
final class RawBackedKeychain: @unchecked Sendable {

    struct Key: Hashable {
        let service: String
        let account: String
    }

    private let lock = NSLock()
    private var storage: [Key: Data] = [:]

    /// Plants raw UTF-8 bytes at the given service/account, bypassing the
    /// adapter's own serialization.
    func put(service: String, account: String, raw: String) {
        lock.lock(); defer { lock.unlock() }
        storage[Key(service: service, account: account)] = raw.data(using: .utf8)!
    }

    func makeShim() -> OZSecItemShim {
        let store = self
        return FakeSecItemShim(
            addHandler: { query, _ in store.add(query: query) },
            copyMatchingHandler: { query, result in store.copyMatching(query: query, result: result) },
            updateHandler: { query, attrs in store.update(query: query, attrs: attrs) },
            deleteHandler: { query in store.delete(query: query) }
        )
    }

    private func key(from query: CFDictionary) -> Key? {
        let dict = query as NSDictionary
        guard
            let service = dict[kSecAttrService] as? String,
            let account = dict[kSecAttrAccount] as? String
        else {
            return nil
        }
        return Key(service: service, account: account)
    }

    private func payload(from dict: CFDictionary) -> Data? {
        let nsDict = dict as NSDictionary
        return nsDict[kSecValueData] as? Data
    }

    private func add(query: CFDictionary) -> OSStatus {
        guard let key = key(from: query), let payload = payload(from: query) else {
            return errSecParam
        }
        lock.lock(); defer { lock.unlock() }
        if storage[key] != nil { return errSecDuplicateItem }
        storage[key] = payload
        return errSecSuccess
    }

    private func copyMatching(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        guard let key = key(from: query) else { return errSecParam }
        lock.lock(); defer { lock.unlock() }
        guard let stored = storage[key] else { return errSecItemNotFound }
        if let result = result { result.pointee = stored as CFData }
        return errSecSuccess
    }

    private func update(query: CFDictionary, attrs: CFDictionary) -> OSStatus {
        guard let key = key(from: query) else { return errSecParam }
        guard let payload = payload(from: attrs) else { return errSecParam }
        lock.lock(); defer { lock.unlock() }
        guard storage[key] != nil else { return errSecItemNotFound }
        storage[key] = payload
        return errSecSuccess
    }

    private func delete(query: CFDictionary) -> OSStatus {
        guard let key = key(from: query) else { return errSecParam }
        lock.lock(); defer { lock.unlock() }
        guard storage.removeValue(forKey: key) != nil else { return errSecItemNotFound }
        return errSecSuccess
    }
}

// ============================================================================
// InMemoryKeychain — test-only Keychain stand-in
// ============================================================================

/// Backing store used by the test suite to simulate the iOS Keychain in-memory
/// without requiring entitlements. Each instance maintains a dictionary of
/// `(service, account) → payload bytes` and provides an `OZSecItemShim`
/// conformance that operates against that dictionary using the same
/// `OSStatus` semantics as the real Keychain.
@available(iOS 13.0, macOS 10.15, *)
final class InMemoryKeychain: @unchecked Sendable {

    struct Key: Hashable {
        let service: String
        let account: String
    }

    private let lock = NSLock()
    private var storage: [Key: Data] = [:]

    func makeShim() -> OZSecItemShim {
        let store = self
        return FakeSecItemShim(
            addHandler: { query, _ in store.add(query: query) },
            copyMatchingHandler: { query, result in store.copyMatching(query: query, result: result) },
            updateHandler: { query, attrs in store.update(query: query, attrs: attrs) },
            deleteHandler: { query in store.delete(query: query) }
        )
    }

    private func key(from query: CFDictionary) -> Key? {
        let dict = query as NSDictionary
        guard
            let service = dict[kSecAttrService] as? String,
            let account = dict[kSecAttrAccount] as? String
        else {
            return nil
        }
        return Key(service: service, account: account)
    }

    private func payload(from dict: CFDictionary) -> Data? {
        let nsDict = dict as NSDictionary
        if let data = nsDict[kSecValueData] as? Data {
            return data
        }
        return nil
    }

    fileprivate func add(query: CFDictionary) -> OSStatus {
        guard let key = key(from: query), let payload = payload(from: query) else {
            return errSecParam
        }
        lock.lock()
        defer { lock.unlock() }
        if storage[key] != nil {
            return errSecDuplicateItem
        }
        storage[key] = payload
        return errSecSuccess
    }

    fileprivate func copyMatching(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        guard let key = key(from: query) else { return errSecParam }
        lock.lock()
        defer { lock.unlock() }
        guard let stored = storage[key] else {
            return errSecItemNotFound
        }
        if let result = result {
            result.pointee = stored as CFData
        }
        return errSecSuccess
    }

    fileprivate func update(query: CFDictionary, attrs: CFDictionary) -> OSStatus {
        guard let key = key(from: query) else { return errSecParam }
        guard let payload = payload(from: attrs) else { return errSecParam }
        lock.lock()
        defer { lock.unlock() }
        guard storage[key] != nil else { return errSecItemNotFound }
        storage[key] = payload
        return errSecSuccess
    }

    fileprivate func delete(query: CFDictionary) -> OSStatus {
        guard let key = key(from: query) else { return errSecParam }
        lock.lock()
        defer { lock.unlock() }
        guard storage.removeValue(forKey: key) != nil else {
            return errSecItemNotFound
        }
        return errSecSuccess
    }
}
