//
//  OZCredentialManager.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Manages the lifecycle of smart account credentials.
///
/// OZCredentialManager provides operations for creating, querying, updating, and deleting
/// stored credentials. It handles credential deployment state transitions and ensures
/// data integrity through validation and consistent error handling.
///
/// Credential State Machine:
/// ```
/// pending --[deploy success]--> credential DELETED from storage
/// pending --[deploy failure]--> failed (deploymentError set)
/// ```
///
/// After successful deployment, credentials are deleted from storage. Reconnection works
/// via sessions or the indexer. Failed deployments can be retried by deleting the
/// credential and creating a new one.
///
/// Thread Safety:
/// All operations delegate to the StorageAdapter, which is responsible for thread-safety.
/// This class is marked @unchecked Sendable because it uses a thread-safe storage adapter.
///
/// Example usage:
/// ```swift
/// let manager = OZCredentialManager(storage: keychainAdapter)
///
/// // Create a pending credential
/// let credential = try manager.createPendingCredential(
///     credentialId: "base64url-id",
///     publicKey: secp256r1PublicKey,
///     contractId: "CBCD1234..."
/// )
///
/// // If deployment fails, mark it
/// try manager.markDeploymentFailed(
///     credentialId: credential.credentialId,
///     error: "Transaction failed: insufficient balance"
/// )
///
/// // On successful deployment, delete the credential
/// try manager.deleteCredential(credentialId: credential.credentialId)
/// ```
public final class OZCredentialManager: @unchecked Sendable {
    /// Storage adapter for credential persistence.
    private let storage: StorageAdapter

    /// Creates a new credential manager.
    ///
    /// - Parameter storage: The storage adapter for persisting credentials
    internal init(storage: StorageAdapter) {
        self.storage = storage
    }

    // MARK: - Public API

    /// Creates a new pending credential in storage.
    ///
    /// The credential is created with:
    /// - deploymentStatus: .pending
    /// - isPrimary: true (first credential is the primary credential)
    /// - createdAt: current date
    ///
    /// Validation:
    /// - Public key must be exactly 65 bytes (uncompressed secp256r1 format)
    /// - Credential ID must not be empty
    /// - Credential ID must be unique (no existing credential with same ID)
    ///
    /// - Parameters:
    ///   - credentialId: The Base64URL-encoded credential ID (must be unique and non-empty)
    ///   - publicKey: The uncompressed secp256r1 public key (must be 65 bytes)
    ///   - contractId: The smart account contract address (C-address)
    /// - Returns: The newly created credential
    /// - Throws:
    ///   - SmartAccountError.invalidInput if validation fails
    ///   - SmartAccountError.credentialAlreadyExists if a credential with the same ID exists
    ///   - SmartAccountError.storageWriteFailed if saving fails
    ///
    /// Example:
    /// ```swift
    /// let credential = try manager.createPendingCredential(
    ///     credentialId: "abc123",
    ///     publicKey: publicKeyData,
    ///     contractId: "CBCD1234..."
    /// )
    /// print("Created credential: \(credential.credentialId)")
    /// ```
    public func createPendingCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String
    ) throws -> StoredCredential {
        // Validate public key size
        guard publicKey.count == SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE else {
            throw SmartAccountError.invalidInput(
                "Invalid public key size: expected \(SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE) bytes, got \(publicKey.count)"
            )
        }

        // Validate credential ID is not empty
        guard !credentialId.isEmpty else {
            throw SmartAccountError.invalidInput("Credential ID cannot be empty")
        }

        // Check for existing credential with same ID
        if let _ = try storage.get(credentialId: credentialId) {
            throw SmartAccountError.credentialAlreadyExists(
                "Credential with ID \(credentialId) already exists"
            )
        }

        // Create the credential
        let credential = StoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId,
            deploymentStatus: .pending,
            isPrimary: true,
            createdAt: Date()
        )

        // Save to storage
        do {
            try storage.save(credential: credential)
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageWriteFailed(
                "Failed to save credential: \(error.localizedDescription)",
                cause: error
            )
        }

        return credential
    }

    /// Marks a credential as failed deployment.
    ///
    /// Updates the credential's deployment status to .failed and sets the deployment
    /// error message. The credential can be retried by deleting it and creating a new one.
    ///
    /// - Parameters:
    ///   - credentialId: The ID of the credential that failed deployment
    ///   - error: The error message describing why deployment failed
    /// - Throws:
    ///   - SmartAccountError.credentialNotFound if the credential does not exist
    ///   - SmartAccountError.storageWriteFailed if the update fails
    ///
    /// Example:
    /// ```swift
    /// try manager.markDeploymentFailed(
    ///     credentialId: "abc123",
    ///     error: "Transaction failed: insufficient balance"
    /// )
    /// ```
    public func markDeploymentFailed(
        credentialId: String,
        error: String
    ) throws {
        // Verify credential exists
        guard let _ = try storage.get(credentialId: credentialId) else {
            throw SmartAccountError.credentialNotFound(
                "Credential with ID \(credentialId) not found"
            )
        }

        // Update deployment status
        let update = StoredCredentialUpdate(
            deploymentStatus: .failed,
            deploymentError: error
        )

        do {
            try storage.update(credentialId: credentialId, updates: update)
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageWriteFailed(
                "Failed to mark deployment as failed: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Deletes a credential from storage.
    ///
    /// Called after successful deployment. Credentials are not persisted after deployment
    /// because reconnection works via sessions or the indexer.
    ///
    /// This method does not throw if the credential does not exist (deletion is idempotent).
    ///
    /// - Parameter credentialId: The ID of the credential to delete
    /// - Throws: SmartAccountError.storageWriteFailed if deletion fails
    ///
    /// Example:
    /// ```swift
    /// // After successful deployment
    /// try manager.deleteCredential(credentialId: "abc123")
    /// ```
    public func deleteCredential(credentialId: String) throws {
        do {
            try storage.delete(credentialId: credentialId)
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageWriteFailed(
                "Failed to delete credential: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Retrieves a credential by its ID.
    ///
    /// - Parameter credentialId: The credential ID to look up
    /// - Returns: The stored credential, or nil if not found
    /// - Throws: SmartAccountError.storageReadFailed if reading fails
    ///
    /// Example:
    /// ```swift
    /// if let credential = try manager.getCredential(credentialId: "abc123") {
    ///     print("Found credential for contract: \(credential.contractId ?? "unknown")")
    /// } else {
    ///     print("Credential not found")
    /// }
    /// ```
    public func getCredential(credentialId: String) throws -> StoredCredential? {
        do {
            return try storage.get(credentialId: credentialId)
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageReadFailed(
                "Failed to get credential: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Retrieves all credentials associated with a specific contract.
    ///
    /// Returns credentials where the contractId matches the provided contract address.
    /// Useful for finding all credentials (including failed deployments) for a wallet.
    ///
    /// - Parameter contractId: The contract address to filter by
    /// - Returns: Array of credentials for this contract (empty if none found)
    /// - Throws: SmartAccountError.storageReadFailed if reading fails
    ///
    /// Example:
    /// ```swift
    /// let credentials = try manager.getCredentialsByContract(contractId: "CBCD1234...")
    /// print("Found \(credentials.count) credential(s) for this contract")
    /// ```
    public func getCredentialsByContract(contractId: String) throws -> [StoredCredential] {
        do {
            return try storage.getByContract(contractId: contractId)
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageReadFailed(
                "Failed to get credentials by contract: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Retrieves all stored credentials.
    ///
    /// Returns all credentials regardless of deployment status or contract address.
    /// Useful for displaying all wallets or performing batch operations.
    ///
    /// - Returns: Array of all stored credentials (empty if none exist)
    /// - Throws: SmartAccountError.storageReadFailed if reading fails
    ///
    /// Example:
    /// ```swift
    /// let allCredentials = try manager.getAllCredentials()
    /// print("Total credentials: \(allCredentials.count)")
    /// ```
    public func getAllCredentials() throws -> [StoredCredential] {
        do {
            return try storage.getAll()
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageReadFailed(
                "Failed to get all credentials: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Updates a credential with partial changes.
    ///
    /// Only non-nil fields in the update are applied. The credential must exist
    /// in storage before updating.
    ///
    /// - Parameters:
    ///   - credentialId: The ID of the credential to update
    ///   - updates: The partial updates to apply
    /// - Throws:
    ///   - SmartAccountError.credentialNotFound if the credential does not exist
    ///   - SmartAccountError.storageWriteFailed if the update fails
    ///
    /// Example:
    /// ```swift
    /// let update = StoredCredentialUpdate(
    ///     nickname: "MacBook Pro",
    ///     lastUsedAt: Date()
    /// )
    /// try manager.updateCredential(credentialId: "abc123", updates: update)
    /// ```
    public func updateCredential(credentialId: String, updates: StoredCredentialUpdate) throws {
        // Verify credential exists
        guard let _ = try storage.get(credentialId: credentialId) else {
            throw SmartAccountError.credentialNotFound(
                "Credential with ID \(credentialId) not found"
            )
        }

        // Apply update
        do {
            try storage.update(credentialId: credentialId, updates: updates)
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageWriteFailed(
                "Failed to update credential: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Clears all credentials from storage.
    ///
    /// This operation is irreversible. Use with caution.
    ///
    /// - Throws: SmartAccountError.storageWriteFailed if clearing fails
    ///
    /// Example:
    /// ```swift
    /// // Clear all credentials (e.g., on account deletion or reset)
    /// try manager.clearAll()
    /// ```
    public func clearAll() throws {
        do {
            try storage.clear()
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageWriteFailed(
                "Failed to clear all credentials: \(error.localizedDescription)",
                cause: error
            )
        }
    }
}
