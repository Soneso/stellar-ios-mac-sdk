//
//  OZStorageSerializationTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZStorageSerializationTests: XCTestCase {

    // MARK: - Helpers

    private func testPublicKey(seed: Int = 0) -> Data {
        var bytes = [UInt8](repeating: 0, count: 65)
        bytes[0] = 0x04
        for i in 1..<65 {
            bytes[i] = UInt8((i + seed) % 256)
        }
        return Data(bytes)
    }

    // MARK: - Credential Round-Trip

    func test_credentialRoundTrip_fullPopulated() throws {
        let original = OZStoredCredential(
            credentialId: "cred-roundtrip-001",
            publicKey: testPublicKey(seed: 7),
            contractId: "CBCD1234EFGH5678IJKL9012MNOP3456QRST7890UVWX1234YZAB5678",
            deploymentStatus: .pending,
            deploymentError: "boom",
            createdAt: 1_700_000_000_000,
            lastUsedAt: 1_700_001_000_000,
            nickname: "MacBook Pro Touch ID",
            isPrimary: true,
            transports: ["internal", "usb"],
            deviceType: "multiDevice",
            backedUp: true
        )

        let serializable = original.toSerializable()
        let restored = try serializable.toStoredCredential()

        XCTAssertEqual(original, restored)
        XCTAssertEqual("PENDING", serializable.deploymentStatus)
        XCTAssertEqual(testPublicKey(seed: 7).base16EncodedString(), serializable.publicKeyHex)
    }

    func test_credentialRoundTrip_minimalNullable() throws {
        let original = OZStoredCredential(
            credentialId: "cred-min",
            publicKey: testPublicKey(seed: 1),
            contractId: nil,
            deploymentStatus: .failed,
            deploymentError: nil,
            createdAt: 1_700_000_000_000,
            lastUsedAt: nil,
            nickname: nil,
            isPrimary: false,
            transports: nil,
            deviceType: nil,
            backedUp: nil
        )

        let serializable = original.toSerializable()
        let restored = try serializable.toStoredCredential()

        XCTAssertEqual(original, restored)
        XCTAssertEqual("FAILED", serializable.deploymentStatus)
    }

    func test_credentialRoundTrip_jsonEncodeDecode() throws {
        let original = OZStoredCredential(
            credentialId: "cred-json",
            publicKey: testPublicKey(seed: 3),
            contractId: "CBCD1234EFGH5678IJKL9012MNOP3456QRST7890UVWX1234YZAB5678",
            createdAt: 1_700_000_000_000,
            isPrimary: true
        )

        let dto = original.toSerializable()
        let json = try JSONEncoder().encode(dto)
        let decoded = try JSONDecoder().decode(SerializableCredential.self, from: json)
        let restored = try decoded.toStoredCredential()

        XCTAssertEqual(original, restored)
    }

    func test_serializableCredential_unknownStatusThrows() {
        let dto = SerializableCredential(
            credentialId: "cred-bad",
            publicKeyHex: testPublicKey(seed: 0).base16EncodedString(),
            deploymentStatus: "NOT_A_REAL_STATUS",
            createdAt: 1_700_000_000_000
        )

        XCTAssertThrowsError(try dto.toStoredCredential()) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_serializableCredential_invalidHexThrows() {
        let dto = SerializableCredential(
            credentialId: "cred-bad-hex",
            publicKeyHex: "ZZZ-not-hex",
            createdAt: 1_700_000_000_000
        )

        XCTAssertThrowsError(try dto.toStoredCredential()) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    // MARK: - Session Round-Trip

    func test_sessionRoundTrip_basic() {
        let original = OZStoredSession(
            credentialId: "cred-session",
            contractId: "CBCD1234",
            connectedAt: 1_700_000_000_000,
            expiresAt: 1_700_604_800_000
        )

        let serializable = original.toSerializable()
        let restored = serializable.toStoredSession()

        XCTAssertEqual(original, restored)
    }

    func test_sessionRoundTrip_jsonEncodeDecode() throws {
        let original = OZStoredSession(
            credentialId: "cred-session-json",
            contractId: "CONTRACT_X",
            connectedAt: 1,
            expiresAt: .max
        )

        let dto = original.toSerializable()
        let json = try JSONEncoder().encode(dto)
        let decoded = try JSONDecoder().decode(SerializableSession.self, from: json)
        let restored = decoded.toStoredSession()

        XCTAssertEqual(original, restored)
    }

    // MARK: - Credential Index

    func test_credentialIndex_jsonEncodeDecode() throws {
        let index = CredentialIndex(ids: ["a", "b", "c"])

        let json = try JSONEncoder().encode(index)
        let decoded = try JSONDecoder().decode(CredentialIndex.self, from: json)

        XCTAssertEqual(index, decoded)
        XCTAssertEqual(["a", "b", "c"], decoded.ids)
    }
}
