//
//  OZStorageAdapter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation
import Security

// MARK: - Credential Deployment Status

/// The deployment status of a smart account credential.
public enum CredentialDeploymentStatus: String, Codable, Sendable {
    /// The credential has been created but the smart account contract has not been deployed yet.
    case pending

    /// The deployment transaction failed.
    case failed
}

// MARK: - Stored Credential

/// A stored smart account credential with deployment and usage metadata.
///
/// Represents a WebAuthn credential (passkey) associated with a smart account.
/// Tracks the credential's deployment status, contract address, and usage history.
///
/// Example:
/// ```swift
/// let credential = StoredCredential(
///     credentialId: "base64url-encoded-id",
///     publicKey: secp256r1PublicKeyData,
///     contractId: "CBCD1234...",
///     deploymentStatus: .pending,
///     isPrimary: true
/// )
/// ```
public struct StoredCredential: Codable, Sendable {
    /// The WebAuthn credential ID (Base64URL encoded).
    ///
    /// This is the unique identifier returned by the browser during WebAuthn registration.
    public let credentialId: String

    /// The uncompressed secp256r1 public key (65 bytes starting with 0x04).
    ///
    /// This public key is used for signature verification in the WebAuthn verifier contract.
    public let publicKey: Data

    /// The smart account contract address (C-address).
    ///
    /// Set during wallet creation via deriveContractAddress. Nil if the contract
    /// address has not been derived yet.
    public var contractId: String?

    /// The current deployment status of the smart account contract.
    public var deploymentStatus: CredentialDeploymentStatus

    /// Error message if deployment failed.
    ///
    /// Contains details about why the deployment transaction failed.
    public var deploymentError: String?

    /// Timestamp of when this credential was last used for signing.
    ///
    /// Updated after successful transaction signatures.
    public var lastUsedAt: Date?

    /// Optional user-friendly nickname for this credential.
    ///
    /// Example: "MacBook Pro Touch ID", "YubiKey 5"
    public var nickname: String?

    /// Whether this is the primary credential for this smart account.
    ///
    /// The primary credential is used as the default for signing operations.
    public var isPrimary: Bool

    /// Timestamp of when this credential was created.
    public let createdAt: Date

    /// Creates a new stored credential.
    ///
    /// - Parameters:
    ///   - credentialId: The Base64URL-encoded credential ID
    ///   - publicKey: The uncompressed secp256r1 public key (65 bytes)
    ///   - contractId: Optional contract address (set during address derivation)
    ///   - deploymentStatus: The deployment status (default: .pending)
    ///   - deploymentError: Optional deployment error message
    ///   - lastUsedAt: Optional last usage timestamp
    ///   - nickname: Optional user-friendly name
    ///   - isPrimary: Whether this is the primary credential (default: false)
    ///   - createdAt: Creation timestamp (default: current date)
    public init(
        credentialId: String,
        publicKey: Data,
        contractId: String? = nil,
        deploymentStatus: CredentialDeploymentStatus = .pending,
        deploymentError: String? = nil,
        lastUsedAt: Date? = nil,
        nickname: String? = nil,
        isPrimary: Bool = false,
        createdAt: Date = Date()
    ) {
        self.credentialId = credentialId
        self.publicKey = publicKey
        self.contractId = contractId
        self.deploymentStatus = deploymentStatus
        self.deploymentError = deploymentError
        self.lastUsedAt = lastUsedAt
        self.nickname = nickname
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}

// MARK: - Stored Credential Update

/// Partial updates for a stored credential.
///
/// Only non-nil fields are applied during an update operation.
///
/// Example:
/// ```swift
/// let update = StoredCredentialUpdate(
///     deploymentStatus: .failed,
///     deploymentError: "Transaction failed: insufficient balance"
/// )
/// try storage.update(credentialId: "abc123", updates: update)
/// ```
public struct StoredCredentialUpdate: Sendable {
    /// New deployment status.
    public var deploymentStatus: CredentialDeploymentStatus?

    /// New deployment error message.
    public var deploymentError: String?

    /// New contract ID.
    public var contractId: String?

    /// New last used timestamp.
    public var lastUsedAt: Date?

    /// New nickname.
    public var nickname: String?

    /// New primary flag.
    public var isPrimary: Bool?

    /// Creates a new credential update.
    public init(
        deploymentStatus: CredentialDeploymentStatus? = nil,
        deploymentError: String? = nil,
        contractId: String? = nil,
        lastUsedAt: Date? = nil,
        nickname: String? = nil,
        isPrimary: Bool? = nil
    ) {
        self.deploymentStatus = deploymentStatus
        self.deploymentError = deploymentError
        self.contractId = contractId
        self.lastUsedAt = lastUsedAt
        self.nickname = nickname
        self.isPrimary = isPrimary
    }
}

// MARK: - Stored Session

/// A stored user session for silent reconnection.
///
/// Sessions enable users to reconnect to their smart account wallet without
/// re-authentication, as long as the session has not expired.
///
/// Example:
/// ```swift
/// let session = StoredSession(
///     credentialId: "base64url-encoded-id",
///     contractId: "CBCD1234...",
///     connectedAt: Date(),
///     expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
/// )
///
/// if !session.isExpired {
///     // Silently reconnect
/// }
/// ```
public struct StoredSession: Codable, Sendable {
    /// The credential ID associated with this session.
    public let credentialId: String

    /// The smart account contract address.
    public let contractId: String

    /// When the session was established.
    public let connectedAt: Date

    /// When the session expires.
    public let expiresAt: Date

    /// Whether the session has expired.
    public var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Creates a new stored session.
    ///
    /// - Parameters:
    ///   - credentialId: The credential ID
    ///   - contractId: The contract address
    ///   - connectedAt: When the session was established (default: current date)
    ///   - expiresAt: When the session expires
    public init(
        credentialId: String,
        contractId: String,
        connectedAt: Date = Date(),
        expiresAt: Date
    ) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Storage Adapter Protocol

/// Protocol for persisting smart account credentials and sessions.
///
/// Storage adapters provide a pluggable persistence layer for credentials and sessions.
/// Implementations must be thread-safe and support concurrent access.
///
/// The default implementation is KeychainStorageAdapter, which uses the iOS Keychain
/// for secure credential storage.
public protocol StorageAdapter: Sendable {
    /// Saves a credential to storage.
    ///
    /// - Parameter credential: The credential to save
    /// - Throws: SmartAccountError if the credential already exists or if saving fails
    func save(credential: StoredCredential) throws

    /// Retrieves a credential by its ID.
    ///
    /// - Parameter credentialId: The credential ID
    /// - Returns: The credential, or nil if not found
    /// - Throws: SmartAccountError if reading fails
    func get(credentialId: String) throws -> StoredCredential?

    /// Retrieves all credentials associated with a contract address.
    ///
    /// - Parameter contractId: The contract address
    /// - Returns: Array of credentials (empty if none found)
    /// - Throws: SmartAccountError if reading fails
    func getByContract(contractId: String) throws -> [StoredCredential]

    /// Retrieves all stored credentials.
    ///
    /// - Returns: Array of all credentials
    /// - Throws: SmartAccountError if reading fails
    func getAll() throws -> [StoredCredential]

    /// Deletes a credential by its ID.
    ///
    /// - Parameter credentialId: The credential ID to delete
    /// - Throws: SmartAccountError if deletion fails
    func delete(credentialId: String) throws

    /// Updates a credential with partial changes.
    ///
    /// Only non-nil fields in the update are applied.
    ///
    /// - Parameters:
    ///   - credentialId: The credential ID to update
    ///   - updates: The partial updates to apply
    /// - Throws: SmartAccountError if the credential is not found or if updating fails
    func update(credentialId: String, updates: StoredCredentialUpdate) throws

    /// Clears all credentials from storage.
    ///
    /// - Throws: SmartAccountError if clearing fails
    func clear() throws

    /// Saves a session to storage.
    ///
    /// - Parameter session: The session to save
    /// - Throws: SmartAccountError if saving fails
    func saveSession(session: StoredSession) throws

    /// Retrieves the current session.
    ///
    /// - Returns: The session, or nil if no session exists or if the session is expired
    /// - Throws: SmartAccountError if reading fails
    func getSession() throws -> StoredSession?

    /// Clears the current session.
    ///
    /// - Throws: SmartAccountError if clearing fails
    func clearSession() throws
}

// MARK: - External Wallet Adapter Protocol

/// Protocol for integrating external wallet adapters for multi-signer support.
///
/// External wallet adapters enable signing with external wallets like Freighter or Albedo
/// for multi-signature smart accounts. They handle wallet connection, signature collection,
/// and wallet reconnection.
///
/// Example implementation:
/// ```swift
/// class FreighterAdapter: ExternalWalletAdapter {
///     func connect() async throws {
///         // Request wallet connection via Freighter browser extension
///     }
///
///     func signAuthEntry(preimageXdr: String, options: ExternalSignOptions?) async throws -> String {
///         // Request signature from Freighter
///     }
/// }
/// ```
public protocol ExternalWalletAdapter: Sendable {
    /// Connects to the external wallet.
    ///
    /// Prompts the user to authorize the connection via the wallet's UI.
    ///
    /// - Throws: An error if connection fails or is rejected
    func connect() async throws

    /// Disconnects from the external wallet.
    ///
    /// - Throws: An error if disconnection fails
    func disconnect() async throws

    /// Signs an authorization entry preimage with the external wallet.
    ///
    /// - Parameters:
    ///   - preimageXdr: The base64-encoded XDR of the auth entry preimage
    ///   - options: Optional signing options (address hint, network passphrase)
    /// - Returns: The base64-encoded signature
    /// - Throws: An error if signing fails or is rejected
    func signAuthEntry(preimageXdr: String, options: ExternalSignOptions?) async throws -> String

    /// Gets the connected wallet addresses.
    ///
    /// - Returns: Array of connected Stellar addresses (G-addresses)
    /// - Throws: An error if retrieval fails
    func getConnectedWallets() async throws -> [String]

    /// Checks if the wallet can sign for a specific address.
    ///
    /// - Parameter address: The Stellar address to check
    /// - Returns: True if the wallet can sign for this address
    /// - Throws: An error if the check fails
    func canSignFor(address: String) async throws -> Bool

    /// Attempts to reconnect to the external wallet.
    ///
    /// Called on app launch to restore a previous connection without prompting the user.
    ///
    /// - Throws: An error if reconnection fails
    func reconnect() async throws
}

/// Options for external wallet signing operations.
public struct ExternalSignOptions: Sendable {
    /// Optional address hint for which signer should be used.
    public let address: String?

    /// Optional network passphrase override.
    public let networkPassphrase: String?

    /// Creates new external sign options.
    public init(address: String? = nil, networkPassphrase: String? = nil) {
        self.address = address
        self.networkPassphrase = networkPassphrase
    }
}

// MARK: - Keychain Storage Adapter

/// iOS Keychain-based storage adapter for secure credential persistence.
///
/// Uses the iOS Keychain to securely store credentials and sessions. All operations
/// are serialized on a dedicated queue for thread safety.
///
/// Example:
/// ```swift
/// let storage = KeychainStorageAdapter()
/// let credential = StoredCredential(...)
/// try storage.save(credential: credential)
/// ```
public final class KeychainStorageAdapter: StorageAdapter, @unchecked Sendable {
    private let queue: DispatchQueue
    private let serviceName: String
    private let credentialsKey: String
    private let sessionKey: String

    /// Creates a new Keychain storage adapter.
    ///
    /// - Parameter serviceName: Optional custom service name for Keychain namespacing (default: "com.stellarsdk.smartaccount")
    public init(serviceName: String = "com.stellarsdk.smartaccount") {
        self.queue = DispatchQueue(label: "com.stellarsdk.smartaccount.storage", qos: .userInitiated)
        self.serviceName = serviceName
        self.credentialsKey = "\(serviceName).credentials"
        self.sessionKey = "\(serviceName).session"
    }

    // MARK: - Credential Operations

    public func save(credential: StoredCredential) throws {
        try queue.sync {
            var credentials = try readAllCredentialsUnsafe()

            // Check for duplicates
            if credentials.contains(where: { $0.credentialId == credential.credentialId }) {
                throw SmartAccountError.credentialAlreadyExists("Credential with ID \(credential.credentialId) already exists")
            }

            credentials.append(credential)
            try writeCredentialsUnsafe(credentials)
        }
    }

    public func get(credentialId: String) throws -> StoredCredential? {
        try queue.sync {
            let credentials = try readAllCredentialsUnsafe()
            return credentials.first { $0.credentialId == credentialId }
        }
    }

    public func getByContract(contractId: String) throws -> [StoredCredential] {
        try queue.sync {
            let credentials = try readAllCredentialsUnsafe()
            return credentials.filter { $0.contractId == contractId }
        }
    }

    public func getAll() throws -> [StoredCredential] {
        try queue.sync {
            try readAllCredentialsUnsafe()
        }
    }

    public func delete(credentialId: String) throws {
        try queue.sync {
            var credentials = try readAllCredentialsUnsafe()
            credentials.removeAll { $0.credentialId == credentialId }
            try writeCredentialsUnsafe(credentials)
        }
    }

    public func update(credentialId: String, updates: StoredCredentialUpdate) throws {
        try queue.sync {
            var credentials = try readAllCredentialsUnsafe()

            guard let index = credentials.firstIndex(where: { $0.credentialId == credentialId }) else {
                throw SmartAccountError.credentialNotFound("Credential with ID \(credentialId) not found")
            }

            var credential = credentials[index]

            // Apply updates (only non-nil fields)
            if let deploymentStatus = updates.deploymentStatus {
                credential.deploymentStatus = deploymentStatus
            }
            if let deploymentError = updates.deploymentError {
                credential.deploymentError = deploymentError
            }
            if let contractId = updates.contractId {
                credential.contractId = contractId
            }
            if let lastUsedAt = updates.lastUsedAt {
                credential.lastUsedAt = lastUsedAt
            }
            if let nickname = updates.nickname {
                credential.nickname = nickname
            }
            if let isPrimary = updates.isPrimary {
                credential.isPrimary = isPrimary
            }

            credentials[index] = credential
            try writeCredentialsUnsafe(credentials)
        }
    }

    public func clear() throws {
        try queue.sync {
            try deleteKeychainItemUnsafe(account: credentialsKey)
        }
    }

    // MARK: - Session Operations

    public func saveSession(session: StoredSession) throws {
        try queue.sync {
            let data = try JSONEncoder().encode(session)
            try writeKeychainItemUnsafe(account: sessionKey, data: data)
        }
    }

    public func getSession() throws -> StoredSession? {
        try queue.sync {
            guard let data = try readKeychainItemUnsafe(account: sessionKey) else {
                return nil
            }

            let session = try JSONDecoder().decode(StoredSession.self, from: data)

            // Return nil for expired sessions (don't throw)
            if session.isExpired {
                return nil
            }

            return session
        }
    }

    public func clearSession() throws {
        try queue.sync {
            try deleteKeychainItemUnsafe(account: sessionKey)
        }
    }

    // MARK: - Internal Helpers (Unsafe - must be called within queue.sync)

    private func readAllCredentialsUnsafe() throws -> [StoredCredential] {
        guard let data = try readKeychainItemUnsafe(account: credentialsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StoredCredential].self, from: data)
        } catch {
            throw SmartAccountError.storageReadFailed("Failed to decode credentials: \(error.localizedDescription)", cause: error)
        }
    }

    private func writeCredentialsUnsafe(_ credentials: [StoredCredential]) throws {
        do {
            let data = try JSONEncoder().encode(credentials)
            try writeKeychainItemUnsafe(account: credentialsKey, data: data)
        } catch {
            throw SmartAccountError.storageWriteFailed("Failed to encode credentials: \(error.localizedDescription)", cause: error)
        }
    }

    // MARK: - Keychain Primitives

    private func readKeychainItemUnsafe(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw SmartAccountError.storageReadFailed("Keychain item is not Data")
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw SmartAccountError.storageReadFailed("Keychain read failed with status: \(status)")
        }
    }

    private func writeKeychainItemUnsafe(account: String, data: Data) throws {
        // Try to update existing item first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // If item doesn't exist, add it
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw SmartAccountError.storageWriteFailed("Keychain write failed with status: \(status)")
        }
    }

    private func deleteKeychainItemUnsafe(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Success or item not found are both acceptable
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SmartAccountError.storageWriteFailed("Keychain delete failed with status: \(status)")
        }
    }
}
