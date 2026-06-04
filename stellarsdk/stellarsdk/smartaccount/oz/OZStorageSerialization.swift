//
//  OZStorageSerialization.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// Internal Serializable Data Transfer Objects
// ============================================================================

/// JSON-serializable representation of a `StoredCredential`.
///
/// `StoredCredential` carries a `Data` field (`publicKey`) which JSON cannot encode
/// directly; this DTO converts the bytes to a hex string for storage. Used by
/// platform-specific persistent storage adapters that serialize credentials to JSON.
internal struct SerializableCredential: Codable, Equatable, Hashable {

    let credentialId: String
    let publicKeyHex: String
    let contractId: String?
    let deploymentStatus: String
    let deploymentError: String?
    let createdAt: Int64
    let lastUsedAt: Int64?
    let nickname: String?
    let isPrimary: Bool
    let transports: [String]?
    let deviceType: String?
    let backedUp: Bool?

    init(
        credentialId: String,
        publicKeyHex: String,
        contractId: String? = nil,
        deploymentStatus: String = CredentialDeploymentStatus.pending.rawValue,
        deploymentError: String? = nil,
        createdAt: Int64,
        lastUsedAt: Int64? = nil,
        nickname: String? = nil,
        isPrimary: Bool = false,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    ) {
        self.credentialId = credentialId
        self.publicKeyHex = publicKeyHex
        self.contractId = contractId
        self.deploymentStatus = deploymentStatus
        self.deploymentError = deploymentError
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.nickname = nickname
        self.isPrimary = isPrimary
        self.transports = transports
        self.deviceType = deviceType
        self.backedUp = backedUp
    }
}

/// JSON-serializable representation of a `StoredSession`.
internal struct SerializableSession: Codable, Equatable, Hashable {

    let credentialId: String
    let contractId: String
    let connectedAt: Int64
    let expiresAt: Int64

    init(credentialId: String, contractId: String, connectedAt: Int64, expiresAt: Int64) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
    }
}

/// JSON-serializable index of credential IDs for enumeration.
///
/// Persistent storage backends like Keychain or UserDefaults do not
/// uniformly support prefix-scan key enumeration. The credential IDs are mirrored
/// into a single index entry that the storage adapter loads to discover what
/// credentials exist.
internal struct CredentialIndex: Codable, Equatable, Hashable {

    let ids: [String]

    init(ids: [String]) {
        self.ids = ids
    }
}

// ============================================================================
// Conversion Helpers
// ============================================================================

internal extension StoredCredential {

    /// Converts this credential to its JSON-serializable form. The `publicKey` bytes
    /// are encoded as a lowercase hex string.
    func toSerializable() -> SerializableCredential {
        return SerializableCredential(
            credentialId: credentialId,
            publicKeyHex: publicKey.base16EncodedString(),
            contractId: contractId,
            deploymentStatus: deploymentStatus.rawValue,
            deploymentError: deploymentError,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            nickname: nickname,
            isPrimary: isPrimary,
            transports: transports,
            deviceType: deviceType,
            backedUp: backedUp
        )
    }
}

internal extension SerializableCredential {

    /// Converts this DTO back into a `StoredCredential`.
    ///
    /// - Throws: `ValidationException.InvalidInput` when `publicKeyHex` is malformed
    ///           or when `deploymentStatus` is not one of the recognised
    ///           `CredentialDeploymentStatus` raw values.
    func toStoredCredential() throws -> StoredCredential {
        let publicKey: Data
        do {
            publicKey = try Data(base16Encoded: publicKeyHex)
        } catch {
            throw ValidationException.invalidInput(
                field: "publicKeyHex",
                reason: "publicKeyHex is not a valid hex string",
                cause: error
            )
        }
        guard let status = CredentialDeploymentStatus(rawValue: deploymentStatus) else {
            throw ValidationException.invalidInput(
                field: "deploymentStatus",
                reason: "Unknown deployment status: \(deploymentStatus)"
            )
        }
        return StoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId,
            deploymentStatus: status,
            deploymentError: deploymentError,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            nickname: nickname,
            isPrimary: isPrimary,
            transports: transports,
            deviceType: deviceType,
            backedUp: backedUp
        )
    }
}

internal extension StoredSession {

    /// Converts this session to its JSON-serializable form.
    func toSerializable() -> SerializableSession {
        return SerializableSession(
            credentialId: credentialId,
            contractId: contractId,
            connectedAt: connectedAt,
            expiresAt: expiresAt
        )
    }
}

internal extension SerializableSession {

    /// Converts this DTO back into a `StoredSession`.
    func toStoredSession() -> StoredSession {
        return StoredSession(
            credentialId: credentialId,
            contractId: contractId,
            connectedAt: connectedAt,
            expiresAt: expiresAt
        )
    }
}

// MARK: - JSON string serialization

/// Encodes an `Encodable` value to a UTF-8 JSON string for persistence by the
/// storage adapters.
func encodeToString<T: Encodable>(_ value: T) throws -> String {
    let data = try JSONEncoder().encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
        throw StorageException.WriteFailed(
            message: "Failed to encode JSON payload as UTF-8 string"
        )
    }
    return string
}

/// Decodes a `Decodable` value from a UTF-8 JSON string produced by ``encodeToString(_:)``.
func decodeFromString<T: Decodable>(_ type: T.Type, _ jsonString: String) throws -> T {
    guard let data = jsonString.data(using: .utf8) else {
        throw StorageException.ReadFailed(
            message: "Failed to decode UTF-8 bytes from stored JSON payload"
        )
    }
    return try JSONDecoder().decode(type, from: data)
}
