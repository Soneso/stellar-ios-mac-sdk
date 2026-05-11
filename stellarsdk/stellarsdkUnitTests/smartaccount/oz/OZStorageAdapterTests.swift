//
//  OZStorageAdapterTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZStorageAdapterTests: XCTestCase {

    // MARK: - Test Data Helpers

    /// Creates a test public key (65 bytes, uncompressed secp256r1 format starting with 0x04).
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
        contractId: String = "CBCD1234EFGH5678IJKL9012MNOP3456QRST7890UVWX1234YZAB5678"
    ) -> StoredCredential {
        return StoredCredential(
            credentialId: id,
            publicKey: testPublicKey(seed: 1),
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

    private func minimalCredential(
        id: String = "cred-minimal-001"
    ) -> StoredCredential {
        return StoredCredential(
            credentialId: id,
            publicKey: testPublicKey(seed: 2),
            contractId: nil,
            deploymentStatus: .pending,
            deploymentError: nil,
            createdAt: 1_700_000_000_000,
            lastUsedAt: nil,
            nickname: nil,
            isPrimary: false,
            transports: nil,
            deviceType: nil,
            backedUp: nil
        )
    }

    private func newAdapter() -> InMemoryStorageAdapter {
        return InMemoryStorageAdapter()
    }

    // MARK: - Credential: Save and Retrieve

    func testSaveAndRetrieveCredential() async throws {
        let adapter = newAdapter()
        let credential = fullCredential()

        try await adapter.save(credential: credential)

        let retrieved = try await adapter.get(credentialId: credential.credentialId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(credential.credentialId, retrieved?.credentialId)
        XCTAssertEqual(credential.publicKey, retrieved?.publicKey)
        XCTAssertEqual(credential.contractId, retrieved?.contractId)
        XCTAssertEqual(credential.deploymentStatus, retrieved?.deploymentStatus)
        XCTAssertEqual(credential.nickname, retrieved?.nickname)
        XCTAssertEqual(credential.isPrimary, retrieved?.isPrimary)
    }

    func testSaveCredentialWithAllFieldsPopulated() async throws {
        let adapter = newAdapter()
        let credential = fullCredential()

        try await adapter.save(credential: credential)
        let retrieved = try await adapter.get(credentialId: credential.credentialId)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual("cred-full-001", retrieved?.credentialId)
        XCTAssertEqual(testPublicKey(seed: 1), retrieved?.publicKey)
        XCTAssertEqual(
            "CBCD1234EFGH5678IJKL9012MNOP3456QRST7890UVWX1234YZAB5678",
            retrieved?.contractId
        )
        XCTAssertEqual(.pending, retrieved?.deploymentStatus)
        XCTAssertNil(retrieved?.deploymentError)
        XCTAssertEqual(1_700_000_000_000, retrieved?.createdAt)
        XCTAssertEqual(1_700_001_000_000, retrieved?.lastUsedAt)
        XCTAssertEqual("MacBook Pro Touch ID", retrieved?.nickname)
        XCTAssertEqual(true, retrieved?.isPrimary)
        XCTAssertEqual(["internal", "usb"], retrieved?.transports)
        XCTAssertEqual("multiDevice", retrieved?.deviceType)
        XCTAssertEqual(true, retrieved?.backedUp)
    }

    func testSaveCredentialWithMinimalFields() async throws {
        let adapter = newAdapter()
        let credential = minimalCredential()

        try await adapter.save(credential: credential)
        let retrieved = try await adapter.get(credentialId: credential.credentialId)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual("cred-minimal-001", retrieved?.credentialId)
        XCTAssertEqual(testPublicKey(seed: 2), retrieved?.publicKey)
        XCTAssertNil(retrieved?.contractId)
        XCTAssertEqual(.pending, retrieved?.deploymentStatus)
        XCTAssertNil(retrieved?.deploymentError)
        XCTAssertNil(retrieved?.lastUsedAt)
        XCTAssertNil(retrieved?.nickname)
        XCTAssertEqual(false, retrieved?.isPrimary)
        XCTAssertNil(retrieved?.transports)
        XCTAssertNil(retrieved?.deviceType)
        XCTAssertNil(retrieved?.backedUp)
    }

    func testGetNonexistentCredentialReturnsNull() async throws {
        let adapter = newAdapter()
        let result = try await adapter.get(credentialId: "nonexistent-id")
        XCTAssertNil(result)
    }

    // MARK: - Credential: Upsert Behavior

    func testSaveExistingCredentialOverwrites() async throws {
        let adapter = newAdapter()
        let original = StoredCredential(
            credentialId: "cred-upsert",
            publicKey: testPublicKey(seed: 10),
            contractId: "CONTRACT_A",
            deploymentStatus: .pending,
            createdAt: 1_700_000_000_000,
            nickname: "Original Name"
        )
        try await adapter.save(credential: original)

        let replacement = StoredCredential(
            credentialId: "cred-upsert",
            publicKey: testPublicKey(seed: 20),
            contractId: "CONTRACT_B",
            deploymentStatus: .failed,
            deploymentError: "Insufficient balance",
            createdAt: 1_700_002_000_000,
            nickname: "Replaced Name"
        )
        try await adapter.save(credential: replacement)

        let retrieved = try await adapter.get(credentialId: "cred-upsert")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(testPublicKey(seed: 20), retrieved?.publicKey)
        XCTAssertEqual("CONTRACT_B", retrieved?.contractId)
        XCTAssertEqual(.failed, retrieved?.deploymentStatus)
        XCTAssertEqual("Replaced Name", retrieved?.nickname)
        XCTAssertEqual("Insufficient balance", retrieved?.deploymentError)

        let all = try await adapter.getAll()
        XCTAssertEqual(1, all.count)
    }

    // MARK: - Credential: Update

    func testUpdateCredentialDeploymentStatus() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(
                deploymentStatus: .failed,
                deploymentError: "Transaction failed: insufficient balance"
            )
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertNotNil(updated)
        XCTAssertEqual(.failed, updated?.deploymentStatus)
        XCTAssertEqual("Transaction failed: insufficient balance", updated?.deploymentError)
        XCTAssertEqual("MacBook Pro Touch ID", updated?.nickname)
        XCTAssertEqual(true, updated?.isPrimary)
    }

    func testUpdateCredentialLastUsedAt() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        let newTimestamp: Int64 = 1_700_099_000_000
        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(lastUsedAt: newTimestamp)
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual(newTimestamp, updated?.lastUsedAt)
        XCTAssertEqual("MacBook Pro Touch ID", updated?.nickname)
    }

    func testUpdateCredentialNickname() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(nickname: "YubiKey 5")
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual("YubiKey 5", updated?.nickname)
        XCTAssertEqual(1_700_001_000_000, updated?.lastUsedAt)
        XCTAssertEqual(true, updated?.isPrimary)
    }

    func testUpdateCredentialPrimaryFlag() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(isPrimary: false)
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual(false, updated?.isPrimary)
    }

    func testUpdateCredentialTransports() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(transports: ["ble", "nfc"])
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual(["ble", "nfc"], updated?.transports)
    }

    func testUpdateCredentialDeviceTypeAndBackedUp() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(deviceType: "singleDevice", backedUp: false)
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual("singleDevice", updated?.deviceType)
        XCTAssertEqual(false, updated?.backedUp)
    }

    func testUpdateCredentialContractId() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: minimalCredential())

        let newContractId = "CNEW1234CONT5678RACT9012ADDR3456GOES7890HERE1234ABCD5678"
        try await adapter.update(
            credentialId: "cred-minimal-001",
            updates: StoredCredentialUpdate(contractId: newContractId)
        )

        let updated = try await adapter.get(credentialId: "cred-minimal-001")
        XCTAssertEqual(newContractId, updated?.contractId)
    }

    func testUpdateOnlyNonNullFieldsAreApplied() async throws {
        let adapter = newAdapter()
        let original = fullCredential()
        try await adapter.save(credential: original)

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(nickname: "Updated Name")
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertNotNil(updated)
        XCTAssertEqual("Updated Name", updated?.nickname)
        XCTAssertEqual(original.contractId, updated?.contractId)
        XCTAssertEqual(original.deploymentStatus, updated?.deploymentStatus)
        XCTAssertEqual(original.deploymentError, updated?.deploymentError)
        XCTAssertEqual(original.lastUsedAt, updated?.lastUsedAt)
        XCTAssertEqual(original.isPrimary, updated?.isPrimary)
        XCTAssertEqual(original.transports, updated?.transports)
        XCTAssertEqual(original.deviceType, updated?.deviceType)
        XCTAssertEqual(original.backedUp, updated?.backedUp)
    }

    func testUpdateNonexistentCredentialThrows() async throws {
        let adapter = newAdapter()
        do {
            try await adapter.update(
                credentialId: "nonexistent-id",
                updates: StoredCredentialUpdate(nickname: "Should fail")
            )
            XCTFail("Expected CredentialException.NotFound")
        } catch let error as CredentialException.NotFound {
            XCTAssertEqual(SmartAccountErrorCode.credentialNotFound.code, error.code.code)
        } catch {
            XCTFail("Expected CredentialException.NotFound, got \(error)")
        }
    }

    func testUpdateMultipleFieldsAtOnce() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.update(
            credentialId: "cred-full-001",
            updates: StoredCredentialUpdate(
                deploymentStatus: .failed,
                deploymentError: "Network timeout",
                lastUsedAt: 1_700_099_000_000,
                nickname: "Updated Device",
                isPrimary: false
            )
        )

        let updated = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual(.failed, updated?.deploymentStatus)
        XCTAssertEqual("Network timeout", updated?.deploymentError)
        XCTAssertEqual(1_700_099_000_000, updated?.lastUsedAt)
        XCTAssertEqual("Updated Device", updated?.nickname)
        XCTAssertEqual(false, updated?.isPrimary)
        XCTAssertEqual(["internal", "usb"], updated?.transports)
        XCTAssertEqual("multiDevice", updated?.deviceType)
        XCTAssertEqual(true, updated?.backedUp)
    }

    // MARK: - Credential: Delete

    func testDeleteCredential() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        try await adapter.delete(credentialId: "cred-full-001")

        let result = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertNil(result)
    }

    func testDeleteNonexistentCredentialDoesNotThrow() async throws {
        let adapter = newAdapter()
        try await adapter.delete(credentialId: "nonexistent-id")
    }

    func testDeleteRemovesOnlyTargetCredential() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential(id: "cred-a"))
        try await adapter.save(credential: fullCredential(id: "cred-b"))
        try await adapter.save(credential: fullCredential(id: "cred-c"))

        try await adapter.delete(credentialId: "cred-b")

        let a = try await adapter.get(credentialId: "cred-a")
        let b = try await adapter.get(credentialId: "cred-b")
        let c = try await adapter.get(credentialId: "cred-c")
        XCTAssertNotNil(a)
        XCTAssertNil(b)
        XCTAssertNotNil(c)
        let all = try await adapter.getAll()
        XCTAssertEqual(2, all.count)
    }

    // MARK: - Credential: Get All

    func testGetAllEmptyReturnsEmptyList() async throws {
        let adapter = newAdapter()
        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testGetAllWithMultipleCredentials() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential(id: "cred-1"))
        try await adapter.save(credential: fullCredential(id: "cred-2"))
        try await adapter.save(credential: minimalCredential(id: "cred-3"))

        let all = try await adapter.getAll()
        XCTAssertEqual(3, all.count)

        let ids = Set(all.map { $0.credentialId })
        XCTAssertTrue(ids.contains("cred-1"))
        XCTAssertTrue(ids.contains("cred-2"))
        XCTAssertTrue(ids.contains("cred-3"))
    }

    // MARK: - Credential: Get by Contract ID

    func testGetByContractIdReturnsMatchingCredentials() async throws {
        let adapter = newAdapter()
        let contractA = "CAAA1234AAAA5678AAAA9012AAAA3456AAAA7890AAAA1234AAAA5678"
        let contractB = "CBBB1234BBBB5678BBBB9012BBBB3456BBBB7890BBBB1234BBBB5678"

        try await adapter.save(credential: fullCredential(id: "cred-a1", contractId: contractA))
        try await adapter.save(credential: fullCredential(id: "cred-a2", contractId: contractA))
        try await adapter.save(credential: fullCredential(id: "cred-b1", contractId: contractB))

        let resultA = try await adapter.getByContract(contractId: contractA)
        XCTAssertEqual(2, resultA.count)
        let idsA = Set(resultA.map { $0.credentialId })
        XCTAssertTrue(idsA.contains("cred-a1"))
        XCTAssertTrue(idsA.contains("cred-a2"))

        let resultB = try await adapter.getByContract(contractId: contractB)
        XCTAssertEqual(1, resultB.count)
        XCTAssertEqual("cred-b1", resultB[0].credentialId)
    }

    func testGetByContractIdNoMatchReturnsEmptyList() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        let result = try await adapter.getByContract(contractId: "NONEXISTENT_CONTRACT_ID")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetByContractIdExcludesNullContractIds() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: minimalCredential(id: "cred-no-contract"))
        try await adapter.save(credential: fullCredential(id: "cred-with-contract"))

        let result = try await adapter.getByContract(contractId: fullCredential().contractId!)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual("cred-with-contract", result[0].credentialId)
    }

    // MARK: - Credential: Clear

    func testClearRemovesAllCredentials() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential(id: "cred-1"))
        try await adapter.save(credential: fullCredential(id: "cred-2"))
        try await adapter.save(credential: minimalCredential(id: "cred-3"))

        try await adapter.clear()

        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
        let one = try await adapter.get(credentialId: "cred-1")
        let two = try await adapter.get(credentialId: "cred-2")
        let three = try await adapter.get(credentialId: "cred-3")
        XCTAssertNil(one)
        XCTAssertNil(two)
        XCTAssertNil(three)
    }

    func testClearOnEmptyAdapterDoesNotThrow() async throws {
        let adapter = newAdapter()
        try await adapter.clear()
        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Session: Save and Retrieve

    func testSaveAndRetrieveSession() async throws {
        let adapter = newAdapter()
        let now: Int64 = 1_700_000_000_000
        let expiresAt: Int64 = .max
        let session = StoredSession(
            credentialId: "cred-session-001",
            contractId: "CSESS1234CONT5678RACT9012ADDR3456GOES7890HERE1234ABCD5678",
            connectedAt: now,
            expiresAt: expiresAt
        )

        try await adapter.saveSession(session)

        let retrieved = try await adapter.getSession()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual("cred-session-001", retrieved?.credentialId)
        XCTAssertEqual(
            "CSESS1234CONT5678RACT9012ADDR3456GOES7890HERE1234ABCD5678",
            retrieved?.contractId
        )
        XCTAssertEqual(now, retrieved?.connectedAt)
        XCTAssertEqual(expiresAt, retrieved?.expiresAt)
    }

    func testGetSessionWhenNoneExistsReturnsNull() async throws {
        let adapter = newAdapter()
        let result = try await adapter.getSession()
        XCTAssertNil(result)
    }

    func testSaveSessionOverwritesPrevious() async throws {
        let adapter = newAdapter()
        let now: Int64 = 1_700_000_000_000

        let session1 = StoredSession(
            credentialId: "cred-session-1",
            contractId: "CONTRACT_1",
            connectedAt: now,
            expiresAt: .max
        )
        try await adapter.saveSession(session1)

        let session2 = StoredSession(
            credentialId: "cred-session-2",
            contractId: "CONTRACT_2",
            connectedAt: now + 1000,
            expiresAt: .max
        )
        try await adapter.saveSession(session2)

        let retrieved = try await adapter.getSession()
        XCTAssertEqual("cred-session-2", retrieved?.credentialId)
        XCTAssertEqual("CONTRACT_2", retrieved?.contractId)
    }

    // MARK: - Session: Clear

    func testClearSession() async throws {
        let adapter = newAdapter()
        let now: Int64 = 1_700_000_000_000
        try await adapter.saveSession(StoredSession(
            credentialId: "cred-session",
            contractId: "CONTRACT",
            connectedAt: now,
            expiresAt: now + 7 * 24 * 60 * 60 * 1000
        ))

        try await adapter.clearSession()

        let result = try await adapter.getSession()
        XCTAssertNil(result)
    }

    func testClearSessionWhenNoneExistsDoesNotThrow() async throws {
        let adapter = newAdapter()
        try await adapter.clearSession()
        let result = try await adapter.getSession()
        XCTAssertNil(result)
    }

    // MARK: - Session: Expiry Auto-Clear

    func testExpiredSessionAutoClearedOnGetSession() async throws {
        let adapter = newAdapter()
        let session = StoredSession(
            credentialId: "cred-expired",
            contractId: "CONTRACT_EXPIRED",
            connectedAt: 1000,
            expiresAt: 2000
        )
        try await adapter.saveSession(session)

        let result = try await adapter.getSession()
        XCTAssertNil(result, "Expired session should be auto-cleared and return nil")

        let secondResult = try await adapter.getSession()
        XCTAssertNil(secondResult, "Session should remain cleared after auto-eviction")
    }

    func testNonExpiredSessionIsReturned() async throws {
        let adapter = newAdapter()
        let session = StoredSession(
            credentialId: "cred-valid",
            contractId: "CONTRACT_VALID",
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await adapter.saveSession(session)

        let result = try await adapter.getSession()
        XCTAssertNotNil(result)
        XCTAssertEqual("cred-valid", result?.credentialId)
    }

    // MARK: - Session and Credentials Independence

    func testClearCredentialsDoesNotAffectSession() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())
        try await adapter.saveSession(StoredSession(
            credentialId: "cred-full-001",
            contractId: "CONTRACT",
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        ))

        try await adapter.clear()

        let all = try await adapter.getAll()
        XCTAssertTrue(all.isEmpty)
        let session = try await adapter.getSession()
        XCTAssertNotNil(session)
    }

    func testClearSessionDoesNotAffectCredentials() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())
        try await adapter.saveSession(StoredSession(
            credentialId: "cred-full-001",
            contractId: "CONTRACT",
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        ))

        try await adapter.clearSession()

        let session = try await adapter.getSession()
        XCTAssertNil(session)
        let all = try await adapter.getAll()
        XCTAssertEqual(1, all.count)
    }

    // MARK: - Edge Cases: Credential IDs with Special Characters

    func testCredentialIdWithSpecialCharacters() async throws {
        let adapter = newAdapter()
        let specialIds = [
            "cred-with-dashes",
            "cred_with_underscores",
            "cred.with.dots",
            "cred/with/slashes",
            "cred+with+plus",
            "cred=with=equals",
            "cred with spaces",
            "Scz0fXNlcjoxMjM0NTY3ODkw",
            "-__-SomeCredId",
            "cred@user:domain#fragment?query=1"
        ]

        for id in specialIds {
            try await adapter.save(credential: StoredCredential(
                credentialId: id,
                publicKey: testPublicKey(seed: 0),
                createdAt: 1_700_000_000_000
            ))
        }

        for id in specialIds {
            let retrieved = try await adapter.get(credentialId: id)
            XCTAssertNotNil(retrieved, "Should retrieve credential with ID: \(id)")
            XCTAssertEqual(id, retrieved?.credentialId)
        }

        let all = try await adapter.getAll()
        XCTAssertEqual(specialIds.count, all.count)
    }

    func testCredentialIdWithEmptyString() async throws {
        let adapter = newAdapter()
        let credential = StoredCredential(
            credentialId: "",
            publicKey: testPublicKey(seed: 0),
            createdAt: 1_700_000_000_000
        )

        try await adapter.save(credential: credential)

        let retrieved = try await adapter.get(credentialId: "")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual("", retrieved?.credentialId)
    }

    // MARK: - Edge Cases: Large Credential Data

    func testLargePublicKey() async throws {
        let adapter = newAdapter()
        var largeKey = Data(count: 1024)
        for i in 0..<1024 {
            largeKey[i] = UInt8(i % 256)
        }
        let credential = StoredCredential(
            credentialId: "cred-large-key",
            publicKey: largeKey,
            createdAt: 1_700_000_000_000
        )

        try await adapter.save(credential: credential)

        let retrieved = try await adapter.get(credentialId: "cred-large-key")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(largeKey, retrieved?.publicKey)
    }

    func testLargeNickname() async throws {
        let adapter = newAdapter()
        let longNickname = String(repeating: "A", count: 10_000)
        let credential = StoredCredential(
            credentialId: "cred-long-name",
            publicKey: testPublicKey(seed: 0),
            createdAt: 1_700_000_000_000,
            nickname: longNickname
        )

        try await adapter.save(credential: credential)

        let retrieved = try await adapter.get(credentialId: "cred-long-name")
        XCTAssertEqual(longNickname, retrieved?.nickname)
    }

    func testLargeTransportsList() async throws {
        let adapter = newAdapter()
        let manyTransports = (1...100).map { "transport-\($0)" }
        let credential = StoredCredential(
            credentialId: "cred-many-transports",
            publicKey: testPublicKey(seed: 0),
            createdAt: 1_700_000_000_000,
            transports: manyTransports
        )

        try await adapter.save(credential: credential)

        let retrieved = try await adapter.get(credentialId: "cred-many-transports")
        XCTAssertEqual(100, retrieved?.transports?.count)
        XCTAssertEqual("transport-1", retrieved?.transports?.first)
        XCTAssertEqual("transport-100", retrieved?.transports?.last)
    }

    // MARK: - Edge Cases: Multiple Credentials for Same Contract

    func testMultipleCredentialsForSameContractId() async throws {
        let adapter = newAdapter()
        let sharedContract = "CSHARED1234ABCD5678EFGH9012IJKL3456MNOP7890QRST1234UVWX"

        let cred1 = StoredCredential(
            credentialId: "cred-primary",
            publicKey: testPublicKey(seed: 1),
            contractId: sharedContract,
            createdAt: 1_700_000_000_000,
            nickname: "Primary Passkey",
            isPrimary: true
        )

        let cred2 = StoredCredential(
            credentialId: "cred-backup",
            publicKey: testPublicKey(seed: 2),
            contractId: sharedContract,
            createdAt: 1_700_000_001_000,
            nickname: "Backup YubiKey",
            isPrimary: false
        )

        let cred3 = StoredCredential(
            credentialId: "cred-recovery",
            publicKey: testPublicKey(seed: 3),
            contractId: sharedContract,
            createdAt: 1_700_000_002_000,
            nickname: "Recovery Key",
            isPrimary: false
        )

        try await adapter.save(credential: cred1)
        try await adapter.save(credential: cred2)
        try await adapter.save(credential: cred3)

        let byContract = try await adapter.getByContract(contractId: sharedContract)
        XCTAssertEqual(3, byContract.count)

        let ids = Set(byContract.map { $0.credentialId })
        XCTAssertTrue(ids.contains("cred-primary"))
        XCTAssertTrue(ids.contains("cred-backup"))
        XCTAssertTrue(ids.contains("cred-recovery"))
    }

    // MARK: - Edge Cases: Concurrent-like Operations

    func testRapidSaveAndRetrieveCycle() async throws {
        let adapter = newAdapter()

        for i in 1...50 {
            let id = "cred-rapid-\(i)"
            let credential = StoredCredential(
                credentialId: id,
                publicKey: testPublicKey(seed: i),
                contractId: "CONTRACT_RAPID",
                createdAt: 1_700_000_000_000 + Int64(i)
            )
            try await adapter.save(credential: credential)

            let retrieved = try await adapter.get(credentialId: id)
            XCTAssertNotNil(retrieved, "Should retrieve credential \(id) immediately after save")
            XCTAssertEqual(id, retrieved?.credentialId)
        }

        let all = try await adapter.getAll()
        XCTAssertEqual(50, all.count)
    }

    func testRapidUpdateCycle() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential())

        for i in 1...20 {
            try await adapter.update(
                credentialId: "cred-full-001",
                updates: StoredCredentialUpdate(
                    lastUsedAt: 1_700_000_000_000 + Int64(i) * 1000,
                    nickname: "Update #\(i)"
                )
            )
        }

        let final = try await adapter.get(credentialId: "cred-full-001")
        XCTAssertEqual(1_700_000_000_000 + 20 * 1000, final?.lastUsedAt)
        XCTAssertEqual("Update #20", final?.nickname)
    }

    // MARK: - Edge Cases: Deployment Status Transitions

    func testDeploymentStatusTransition() async throws {
        let adapter = newAdapter()
        let credential = StoredCredential(
            credentialId: "cred-deploy",
            publicKey: testPublicKey(seed: 0),
            deploymentStatus: .pending,
            createdAt: 1_700_000_000_000
        )
        try await adapter.save(credential: credential)

        try await adapter.update(
            credentialId: "cred-deploy",
            updates: StoredCredentialUpdate(
                deploymentStatus: .failed,
                deploymentError: "Transaction rejected"
            )
        )

        let failed = try await adapter.get(credentialId: "cred-deploy")
        XCTAssertEqual(.failed, failed?.deploymentStatus)
        XCTAssertEqual("Transaction rejected", failed?.deploymentError)

        try await adapter.update(
            credentialId: "cred-deploy",
            updates: StoredCredentialUpdate(deploymentStatus: .pending)
        )

        let retrying = try await adapter.get(credentialId: "cred-deploy")
        XCTAssertEqual(.pending, retrying?.deploymentStatus)
        // The deploymentError is not cleared because update only applies non-nil fields.
        XCTAssertEqual("Transaction rejected", retrying?.deploymentError)
    }

    // MARK: - Edge Cases: Delete Then Re-Save

    func testDeleteThenReSave() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential(id: "cred-lifecycle"))

        try await adapter.delete(credentialId: "cred-lifecycle")
        let afterDelete = try await adapter.get(credentialId: "cred-lifecycle")
        XCTAssertNil(afterDelete)

        let newCredential = StoredCredential(
            credentialId: "cred-lifecycle",
            publicKey: testPublicKey(seed: 99),
            contractId: "NEW_CONTRACT",
            createdAt: 1_700_099_000_000,
            nickname: "Reborn"
        )
        try await adapter.save(credential: newCredential)

        let retrieved = try await adapter.get(credentialId: "cred-lifecycle")
        XCTAssertEqual("NEW_CONTRACT", retrieved?.contractId)
        XCTAssertEqual("Reborn", retrieved?.nickname)
    }

    // MARK: - Edge Cases: Update After Delete Throws

    func testUpdateAfterDeleteThrows() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential(id: "cred-deleted"))

        try await adapter.delete(credentialId: "cred-deleted")

        do {
            try await adapter.update(
                credentialId: "cred-deleted",
                updates: StoredCredentialUpdate(nickname: "Should fail")
            )
            XCTFail("Expected CredentialException.NotFound")
        } catch is CredentialException.NotFound {
            // expected
        }
    }

    // MARK: - Edge Cases: Clear Then Add

    func testClearThenAddNewCredentials() async throws {
        let adapter = newAdapter()
        try await adapter.save(credential: fullCredential(id: "cred-old-1"))
        try await adapter.save(credential: fullCredential(id: "cred-old-2"))

        try await adapter.clear()

        try await adapter.save(credential: minimalCredential(id: "cred-new-1"))
        let all = try await adapter.getAll()
        XCTAssertEqual(1, all.count)
        let present = try await adapter.get(credentialId: "cred-new-1")
        XCTAssertNotNil(present)
        let absent = try await adapter.get(credentialId: "cred-old-1")
        XCTAssertNil(absent)
    }

    // MARK: - StoredSession.isExpired Property

    func testStoredSessionIsExpiredProperty() {
        let expired = StoredSession(
            credentialId: "cred",
            contractId: "CONTRACT",
            connectedAt: 1000,
            expiresAt: 2000
        )
        XCTAssertTrue(expired.isExpired, "Session expiring at epoch 2000ms should be expired")

        let valid = StoredSession(
            credentialId: "cred",
            contractId: "CONTRACT",
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        XCTAssertFalse(valid.isExpired, "Session expiring at Int64.max should not be expired")
    }

    // MARK: - StoredCredential Equality

    func testStoredCredentialEqualityWithSameData() {
        let key = testPublicKey(seed: 5)
        let cred1 = StoredCredential(
            credentialId: "cred-eq",
            publicKey: Data(key),
            contractId: "CONTRACT",
            createdAt: 1_700_000_000_000,
            nickname: "Test"
        )
        let cred2 = StoredCredential(
            credentialId: "cred-eq",
            publicKey: Data(key),
            contractId: "CONTRACT",
            createdAt: 1_700_000_000_000,
            nickname: "Test"
        )

        XCTAssertEqual(cred1, cred2)
        XCTAssertEqual(cred1.hashValue, cred2.hashValue)
    }

    func testStoredCredentialInequalityWithDifferentPublicKey() {
        let cred1 = StoredCredential(
            credentialId: "cred-neq",
            publicKey: testPublicKey(seed: 1),
            createdAt: 1_700_000_000_000
        )
        let cred2 = StoredCredential(
            credentialId: "cred-neq",
            publicKey: testPublicKey(seed: 2),
            createdAt: 1_700_000_000_000
        )

        XCTAssertNotEqual(cred1, cred2)
    }

    // MARK: - Interface Conformance

    func testInMemoryStorageAdapterImplementsStorageAdapterInterface() {
        let adapter: StorageAdapter = InMemoryStorageAdapter()
        XCTAssertNotNil(adapter)
    }

    // MARK: - Concurrent-write atomicity

    /// Fires ten parallel writes against a single adapter, then verifies that every
    /// readback returns one of the ten written values bit-identical and that the
    /// total count of stored credentials is exactly ten with no torn writes.
    func test_concurrent_writes_10_parallel_no_partial_state() async throws {
        let adapter = InMemoryStorageAdapter()

        var expected: [String: StoredCredential] = [:]
        for i in 0..<10 {
            let cred = StoredCredential(
                credentialId: "cred-concurrent-\(i)",
                publicKey: testPublicKey(seed: i + 100),
                contractId: "CONCURRENT_CONTRACT",
                createdAt: 1_700_000_000_000 + Int64(i)
            )
            expected[cred.credentialId] = cred
        }

        await withTaskGroup(of: Void.self) { group in
            for (_, cred) in expected {
                group.addTask {
                    try? await adapter.save(credential: cred)
                }
            }
        }

        let all = try await adapter.getAll()
        XCTAssertEqual(10, all.count, "Exactly ten credentials must be persisted with no overlap or loss")

        for (id, exp) in expected {
            let retrieved = try await adapter.get(credentialId: id)
            XCTAssertNotNil(retrieved, "Credential \(id) must be readable after concurrent writes")
            XCTAssertEqual(exp, retrieved, "Readback for \(id) must match the written value bit-identical")
        }

        let storedIds = Set(all.map { $0.credentialId })
        XCTAssertEqual(Set(expected.keys), storedIds, "Stored ID set must equal the written set")
    }
}
