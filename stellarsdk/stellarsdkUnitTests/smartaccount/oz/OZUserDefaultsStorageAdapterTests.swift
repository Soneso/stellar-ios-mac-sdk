//
//  OZUserDefaultsStorageAdapterTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZUserDefaultsStorageAdapterTests: XCTestCase {

    // ========================================================================
    // Test Data Helpers
    // ========================================================================

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

    private var allocatedSuiteNames: [String] = []

    private func uniqueSuiteName(_ tag: String = "test") -> String {
        let name = "com.soneso.stellar.smartaccount.\(tag).\(UUID().uuidString)"
        allocatedSuiteNames.append(name)
        return name
    }

    override func tearDown() {
        // Remove every suite domain allocated during the test to ensure no
        // stale state survives across runs (`UserDefaults` persists to disk
        // even for ephemeral suite names).
        for name in allocatedSuiteNames {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        allocatedSuiteNames.removeAll()
        super.tearDown()
    }

    private func newAdapter() throws -> OZUserDefaultsStorageAdapter {
        return try OZUserDefaultsStorageAdapter(suiteName: uniqueSuiteName())
    }

    // ========================================================================
    // Save / Retrieve
    // ========================================================================

    func test_save_and_retrieve_credential() async throws {
        let adapter = try newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded, credential)
    }

    func test_save_credential_with_all_fields_populated() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        let credential = minimalCredential()
        try await adapter.save(credential: credential)

        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertEqual(loaded?.credentialId, credential.credentialId)
        XCTAssertEqual(loaded?.publicKey, credential.publicKey)
        XCTAssertNil(loaded?.contractId)
        XCTAssertNil(loaded?.lastUsedAt)
        XCTAssertNil(loaded?.nickname)
    }

    func test_get_nonexistent_credential_returns_nil() async throws {
        let adapter = try newAdapter()
        let loaded = try await adapter.get(credentialId: "missing-id")
        XCTAssertNil(loaded)
    }

    // ========================================================================
    // Upsert
    // ========================================================================

    func test_save_existing_credential_overwrites_and_does_not_duplicate_index() async throws {
        let adapter = try newAdapter()
        var credential = fullCredential()
        try await adapter.save(credential: credential)

        credential = credential.applyUpdate(OZStoredCredentialUpdate(nickname: "Updated nickname"))
        try await adapter.save(credential: credential)

        let all = try await adapter.getAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.nickname, "Updated nickname")
    }

    // ========================================================================
    // Update
    // ========================================================================

    func test_update_credential_deployment_status() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)

        try await adapter.delete(credentialId: credential.credentialId)
        let loaded = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertNil(loaded)
    }

    func test_delete_nonexistent_credential_does_not_throw() async throws {
        let adapter = try newAdapter()
        try await adapter.delete(credentialId: "never-existed")
    }

    func test_delete_removes_only_target_credential() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
    }

    func test_get_all_with_multiple_credentials() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        try await adapter.save(credential: fullCredential())
        let matches = try await adapter.getByContract(contractId: "DOES-NOT-EXIST")
        XCTAssertTrue(matches.isEmpty)
    }

    func test_get_by_contract_id_excludes_null_contract_id() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        try await adapter.save(credential: fullCredential(id: "a", seed: 1))
        try await adapter.save(credential: fullCredential(id: "b", seed: 2))

        try await adapter.clear()

        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
    }

    func test_clear_on_empty_adapter_does_not_throw() async throws {
        let adapter = try newAdapter()
        try await adapter.clear()
    }

    func test_clear_removes_session_too() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        let loaded = try await adapter.getSession()
        XCTAssertNil(loaded)
    }

    func test_save_session_overwrites_previous_session() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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

        let second = try await adapter.getSession()
        XCTAssertNil(second)
    }

    func test_non_expired_session_is_returned() async throws {
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
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
        let adapter = try newAdapter()
        try await adapter.clearSession()
    }

    func test_clear_session_does_not_affect_credentials() async throws {
        let adapter = try newAdapter()
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
    // Suite-name Isolation
    // ========================================================================

    func test_custom_suite_name_isolates_user_defaults_data() async throws {
        let adapterA = try OZUserDefaultsStorageAdapter(suiteName: uniqueSuiteName("A"))
        let adapterB = try OZUserDefaultsStorageAdapter(suiteName: uniqueSuiteName("B"))

        try await adapterA.save(credential: fullCredential(id: "in-A", seed: 1))
        try await adapterB.save(credential: fullCredential(id: "in-B", seed: 2))

        let onlyA = try await adapterA.getAll()
        let onlyB = try await adapterB.getAll()

        XCTAssertEqual(onlyA.map { $0.credentialId }, ["in-A"])
        XCTAssertEqual(onlyB.map { $0.credentialId }, ["in-B"])
    }

    func test_default_suite_name_is_used() async throws {
        XCTAssertEqual(
            OZUserDefaultsStorageAdapter.defaultSuiteName,
            "com.soneso.stellar.smartaccount"
        )
    }

    // ========================================================================
    // Interface Conformance
    // ========================================================================

    func test_user_defaults_adapter_conforms_to_storage_adapter_protocol() async throws {
        let adapter = try newAdapter()
        let asProtocol: any OZStorageAdapter = adapter
        try await asProtocol.save(credential: fullCredential())
        let all = try await asProtocol.getAll()
        XCTAssertEqual(all.count, 1)
    }

    // ========================================================================
    // Edge Cases
    // ========================================================================

    func test_delete_then_resave_credential() async throws {
        let adapter = try newAdapter()
        let credential = fullCredential()
        try await adapter.save(credential: credential)
        try await adapter.delete(credentialId: credential.credentialId)
        try await adapter.save(credential: credential)

        let all = try await adapter.getAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.credentialId, credential.credentialId)
    }

    func test_update_after_delete_throws_credential_not_found() async throws {
        let adapter = try newAdapter()
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
    // Failure-mode Coverage
    // ========================================================================

    func test_invalid_suite_name_throws_storage_exception_on_init() {
        // Apple documents `NSGlobalDomain` as the one suite name guaranteed
        // to be rejected by `UserDefaults(suiteName:)` (it is reserved for
        // system-wide defaults). Constructing the adapter with that name
        // must surface a typed `SmartAccountStorageException.WriteFailed` rather than
        // crashing or silently returning a no-op adapter.
        do {
            _ = try OZUserDefaultsStorageAdapter(suiteName: "NSGlobalDomain")
            XCTFail("expected SmartAccountStorageException.WriteFailed for reserved suite name")
        } catch let error as SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(error.code, .storageWriteFailed)
            XCTAssertTrue(error.message.contains("UserDefaults"))
        } catch {
            XCTFail("expected SmartAccountStorageException.WriteFailed, got \(error)")
        }
    }

    func test_concurrent_writes_10_parallel_no_partial_state() async throws {
        let adapter = try newAdapter()
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

    func test_corrupted_payload_throws_read_failed() async throws {
        // Write a non-JSON UTF-8 string into the suite's credential entry
        // bypassing the adapter's encoder, then verify the adapter surfaces
        // the JSON decoding failure as `SmartAccountStorageException.ReadFailed`. This
        // covers the catch-all arm in `get(credentialId:)` that maps any
        // decoder error into a typed read failure for the caller.
        let suiteName = uniqueSuiteName()
        let adapter = try OZUserDefaultsStorageAdapter(suiteName: suiteName)
        let credentialId = "corrupted-id"
        let credentialKey = "cred_" + credentialId

        // Inject a corrupted payload directly into the backing store.
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to open suite for direct write")
            return
        }
        defaults.set("not-json", forKey: credentialKey)

        do {
            _ = try await adapter.get(credentialId: credentialId)
            XCTFail("expected SmartAccountStorageException.ReadFailed for corrupted payload")
        } catch let error as SmartAccountStorageException.ReadFailed {
            XCTAssertEqual(error.code, .storageReadFailed)
            XCTAssertTrue(error.message.contains(credentialId))
        }
    }

    func test_oversized_payload_round_trip() async throws {
        let adapter = try newAdapter()
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
}
