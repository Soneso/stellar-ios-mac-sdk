//
//  OZCredentialManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation


/// Result of synchronising every stored credential against on-chain contract state.
///
/// Returned by ``OZCredentialManager/syncAll()`` to summarise how many stored
/// credentials are confirmed deployed (and were therefore removed from local
/// storage), how many remain pending, and how many failed deployment.
public struct SyncResult: Sendable, Equatable, Hashable {

    /// Number of credentials confirmed as deployed on-chain (and removed from
    /// storage as part of the sync).
    public let deployed: Int

    /// Number of credentials still pending deployment.
    public let pending: Int

    /// Number of credentials whose deployment status is `.failed`.
    public let failed: Int

    /// Initialises a new ``SyncResult``.
    ///
    /// - Parameters:
    ///   - deployed: Credentials confirmed deployed on-chain (removed from storage).
    ///   - pending: Credentials still pending deployment.
    ///   - failed: Credentials with `.failed` deployment status.
    public init(deployed: Int, pending: Int, failed: Int) {
        self.deployed = deployed
        self.pending = pending
        self.failed = failed
    }
}


/// Manages the lifecycle of stored Smart Account credentials.
///
/// ``OZCredentialManager`` provides operations for creating, querying, updating,
/// and deleting stored credentials, and for reconciling local credential state
/// with on-chain deployment status. The manager is the only supported entry
/// point for the application-visible side of credential storage; lower-level
/// access goes through the underlying ``StorageAdapter``.
///
/// ## Credential State Machine
///
/// ```text
/// pending --[deploy success]------------------> credential DELETED from storage
/// pending --[deploy failure]------------------> failed (deploymentError set)
/// pending --[sync discovers contract on-chain]-> credential DELETED from storage
/// failed  --[deleteCredential]-----------------> credential DELETED from storage
/// ```
///
/// After successful deployment (or sync discovery), credentials are removed
/// from local storage. Reconnection works through sessions or the indexer.
/// Failed deployments can be retried by deleting the credential and creating a
/// new one with the same identifier.
///
/// ## Usage
///
/// ```swift
/// let manager = kit.credentialManager
///
/// // Get all credentials.
/// let all = try await manager.getAllCredentials()
///
/// // Get pending and failed credentials.
/// let pending = try await manager.getPendingCredentials()
///
/// // Sync a credential with on-chain state (deletes if deployed).
/// let isDeployed = try await manager.sync(credentialId: "base64url-id")
///
/// // Delete a pending credential.
/// try await manager.deleteCredential(credentialId: "base64url-id")
/// ```
public final class OZCredentialManager: OZCredentialManagerProtocol, @unchecked Sendable {

    // MARK: - Stored properties

    /// Smart Account kit the manager belongs to.
    ///
    /// Held through the internal kit protocol so the manager can resolve the
    /// underlying storage adapter, the connected wallet identifier, the
    /// Soroban RPC client, and the event emitter without binding to a typed
    /// kit reference (which would create a circular declaration order between
    /// the manager and the kit module).
    private let kit: OZSmartAccountKitProtocol

    // MARK: - Initialisation

    /// Internal initializer; instances are constructed by `OZSmartAccountKit`.
    internal init(kit: OZSmartAccountKitProtocol) {
        self.kit = kit
    }

    // MARK: - Computed accessors

    private var storage: StorageAdapter {
        return kit.getStorage()
    }

    // MARK: - Public API: Create

    /// Creates a new pending credential and persists it to storage.
    ///
    /// The credential is created with deployment status ``CredentialDeploymentStatus/pending``,
    /// `isPrimary` set to `false` (the wallet-creation flow is responsible for
    /// promoting a credential to primary), and `createdAt` set to the current
    /// wall-clock time in milliseconds since the Unix epoch.
    ///
    /// ## Validation
    ///
    /// - `publicKey` must be exactly ``SmartAccountConstants/secp256r1PublicKeySize`` bytes (uncompressed secp256r1).
    /// - `credentialId` must not be empty.
    /// - `credentialId` must be unique (no existing credential may share the identifier).
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier (must be unique and non-empty).
    ///   - publicKey: Uncompressed secp256r1 public key (`secp256r1PublicKeySize` bytes).
    ///   - contractId: Smart account contract address (`C…` strkey).
    ///   - nickname: Optional user-friendly display name.
    ///   - transports: Optional WebAuthn transport hints (e.g. `"usb"`, `"nfc"`, `"ble"`, `"internal"`).
    ///   - deviceType: Optional authenticator device type (`"singleDevice"` or `"multiDevice"`).
    ///   - backedUp: Optional flag indicating whether the passkey is backed up or synced.
    /// - Returns: The persisted ``StoredCredential``.
    /// - Throws:
    ///   - ``ValidationException/InvalidInput`` when validation fails.
    ///   - ``CredentialException/AlreadyExists`` when a credential with the same identifier already exists.
    ///   - ``StorageException/WriteFailed`` when persistence fails.
    public func createPendingCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String,
        nickname: String? = nil,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    ) async throws -> StoredCredential {
        if publicKey.count != SmartAccountConstants.secp256r1PublicKeySize {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Expected \(SmartAccountConstants.secp256r1PublicKeySize) bytes, got \(publicKey.count)"
            )
        }
        if credentialId.isEmpty {
            throw ValidationException.invalidInput(
                field: "credentialId",
                reason: "Credential ID cannot be empty"
            )
        }

        let existing = try await storage.get(credentialId: credentialId)
        if existing != nil {
            throw CredentialException.alreadyExists(credentialId: credentialId)
        }

        let credential = StoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId,
            deploymentStatus: .pending,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            nickname: nickname,
            isPrimary: false,
            transports: transports,
            deviceType: deviceType,
            backedUp: backedUp
        )

        do {
            try await storage.save(credential: credential)
        } catch let error as CredentialException {
            throw error
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: credentialId, cause: error)
        }

        return credential
    }

    /// Saves a credential directly to storage with looser validation than
    /// ``createPendingCredential(credentialId:publicKey:contractId:nickname:transports:deviceType:backedUp:)``.
    ///
    /// Unlike the create path this method does not check for duplicates, does
    /// not capture deployment-time WebAuthn metadata (`transports`,
    /// `deviceType`, `backedUp`), and persists `isPrimary = false`. A `nil`
    /// `contractId` is stored as the empty string to mirror the on-chain
    /// "not yet derived" sentinel used by other call sites.
    ///
    /// ## Validation
    ///
    /// - `credentialId` must not be empty.
    /// - `publicKey` must be exactly ``SmartAccountConstants/secp256r1PublicKeySize`` bytes.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - publicKey: Uncompressed secp256r1 public key (`secp256r1PublicKeySize` bytes).
    ///   - nickname: Optional user-friendly display name.
    ///   - contractId: Optional smart account contract address. `nil` is stored as the empty string.
    /// - Returns: The persisted ``StoredCredential``.
    /// - Throws:
    ///   - ``ValidationException/InvalidInput`` when validation fails.
    ///   - ``StorageException/WriteFailed`` when persistence fails.
    public func saveCredential(
        credentialId: String,
        publicKey: Data,
        nickname: String? = nil,
        contractId: String? = nil
    ) async throws -> StoredCredential {
        if credentialId.isEmpty {
            throw ValidationException.invalidInput(
                field: "credentialId",
                reason: "Credential ID cannot be empty"
            )
        }
        if publicKey.count != SmartAccountConstants.secp256r1PublicKeySize {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Expected \(SmartAccountConstants.secp256r1PublicKeySize) bytes, got \(publicKey.count)"
            )
        }

        let credential = StoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId ?? "",
            deploymentStatus: .pending,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            nickname: nickname,
            isPrimary: false
        )

        do {
            try await storage.save(credential: credential)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: credentialId, cause: error)
        }

        return credential
    }

    // MARK: - Public API: Sync

    /// Synchronises a single credential with on-chain contract state.
    ///
    /// Queries the contract instance for the credential's `contractId` via
    /// Soroban RPC. When the contract instance exists the credential is
    /// removed from local storage (deployment is confirmed) and the method
    /// returns `true`. When the contract instance does not exist, when the
    /// credential has no associated `contractId`, or when the on-chain check
    /// fails for any reason (transport error, parse error, RPC error), the
    /// method returns `false` without throwing.
    ///
    /// The on-chain check intentionally swallows errors: a pending-credentials
    /// sweep needs a binary answer, not a failure mode. The credential remains
    /// in storage in any non-deployed outcome.
    ///
    /// - Parameter credentialId: Identifier of the credential to sync.
    /// - Returns: `true` when the contract is deployed and the credential was
    ///   removed from local storage, otherwise `false`.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when no credential with the supplied
    ///     identifier exists in storage.
    ///   - ``StorageException/ReadFailed`` when reading the credential fails.
    @discardableResult
    public func sync(credentialId: String) async throws -> Bool {
        let credential: StoredCredential?
        do {
            credential = try await storage.get(credentialId: credentialId)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: credentialId, cause: error)
        }
        guard let credential = credential else {
            throw CredentialException.notFound(credentialId: credentialId)
        }

        guard let contractAddress = credential.contractId, !contractAddress.isEmpty else {
            return false
        }

        try Task.checkCancellation()

        let response = await kit.sorobanServer.getContractData(
            contractId: contractAddress,
            key: .ledgerKeyContractInstance,
            durability: .persistent
        )

        switch response {
        case .success:
            do {
                try await storage.delete(credentialId: credentialId)
            } catch {
                // why: storage failures during the post-confirmation cleanup
                // are surfaced as "not deployed" so the credential stays in
                // storage and a later sync attempt can retry the cleanup. The
                // on-chain state is already authoritative; treating the
                // cleanup failure as success would orphan the local entry.
                return false
            }
            return true
        case .failure(let rpcError):
            // why: the on-chain check is non-fatal — any RPC failure maps to
            // "not yet deployed" so a sweep continues across every credential.
            // Emit credentialSyncFailed so listeners can react without catching.
            kit.events.emit(.credentialSyncFailed(credentialId: credentialId, error: rpcError))
            return false
        }
    }

    /// Synchronises every stored credential with on-chain contract state.
    ///
    /// Iterates the full credential set, invoking ``sync(credentialId:)`` for
    /// each entry. Deployed credentials are removed from storage (and counted
    /// as `deployed`); failed credentials are counted as `failed`; everything
    /// else is counted as `pending`.
    ///
    /// - Returns: A ``SyncResult`` summarising the deployment status counts.
    /// - Throws: ``StorageException/ReadFailed`` when reading the credential
    ///   set fails.
    public func syncAll() async throws -> SyncResult {
        let all: [StoredCredential]
        do {
            all = try await storage.getAll()
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: "all", cause: error)
        }

        var deployed = 0
        var pending = 0
        var failed = 0

        for credential in all {
            try Task.checkCancellation()
            let exists: Bool
            do {
                exists = try await sync(credentialId: credential.credentialId)
            } catch is CredentialException {
                // why: the credential may have been removed by an earlier
                // iteration of this loop (or by a concurrent caller). Treat a
                // missing-credential error as "not deployed" so the loop
                // proceeds across the remaining entries.
                exists = false
            }

            if exists {
                deployed += 1
            } else if credential.deploymentStatus == .failed {
                failed += 1
            } else {
                pending += 1
            }
        }

        return SyncResult(deployed: deployed, pending: pending, failed: failed)
    }

    // MARK: - Public API: Delete

    /// Deletes a pending credential from storage.
    ///
    /// Before deletion the manager runs ``sync(credentialId:)`` to confirm the
    /// contract has not been deployed on-chain. When the contract is already
    /// deployed the sync removes the credential and the deletion is rejected
    /// with ``CredentialException/Invalid`` because the wallet exists on-chain
    /// and the local entry is no longer authoritative.
    ///
    /// On successful deletion the manager emits a
    /// ``SmartAccountEvent/credentialDeleted(credentialId:)`` event.
    ///
    /// - Parameter credentialId: Identifier of the credential to delete.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when no credential with the supplied
    ///     identifier exists in storage.
    ///   - ``CredentialException/Invalid`` when the credential is already
    ///     deployed on-chain.
    ///   - ``StorageException/ReadFailed`` when reading the credential fails.
    ///   - ``StorageException/WriteFailed`` when deletion fails.
    public func deleteCredential(credentialId: String) async throws {
        let credential: StoredCredential?
        do {
            credential = try await storage.get(credentialId: credentialId)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: credentialId, cause: error)
        }
        guard credential != nil else {
            throw CredentialException.notFound(credentialId: credentialId)
        }

        let isDeployed = try await sync(credentialId: credentialId)
        if isDeployed {
            throw CredentialException.invalid(
                reason: "Cannot delete a deployed credential. The wallet exists on-chain."
            )
        }

        do {
            try await storage.delete(credentialId: credentialId)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: credentialId, cause: error)
        }

        kit.events.emit(.credentialDeleted(credentialId: credentialId))
    }

    // MARK: - Public API: Query

    /// Retrieves a stored credential by its identifier.
    ///
    /// - Parameter credentialId: Identifier of the credential to look up.
    /// - Returns: The ``StoredCredential`` when present, otherwise `nil`.
    /// - Throws: ``StorageException/ReadFailed`` when reading fails.
    public func getCredential(credentialId: String) async throws -> StoredCredential? {
        do {
            return try await storage.get(credentialId: credentialId)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: credentialId, cause: error)
        }
    }

    /// Retrieves every credential associated with the supplied contract address.
    ///
    /// - Parameter contractId: Contract address to filter by.
    /// - Returns: Credentials whose `contractId` matches; empty when none match.
    /// - Throws: ``StorageException/ReadFailed`` when reading fails.
    public func getCredentialsByContract(contractId: String) async throws -> [StoredCredential] {
        do {
            return try await storage.getByContract(contractId: contractId)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: "contract:\(contractId)", cause: error)
        }
    }

    /// Retrieves every stored credential, regardless of deployment status or
    /// associated contract.
    ///
    /// - Returns: All stored credentials (empty when no credentials exist).
    /// - Throws: ``StorageException/ReadFailed`` when reading fails.
    public func getAllCredentials() async throws -> [StoredCredential] {
        do {
            return try await storage.getAll()
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: "all", cause: error)
        }
    }

    /// Retrieves every credential associated with the kit's currently
    /// connected wallet.
    ///
    /// Returns an empty list when no wallet is connected. The connected
    /// contract is queried through the kit's `contractId` accessor; concrete
    /// kits expose this through the Smart Account Kit's connected-state API.
    ///
    /// - Returns: Credentials whose `contractId` matches the connected
    ///   wallet's contract address (empty when not connected or when no
    ///   credentials match).
    /// - Throws: ``StorageException/ReadFailed`` when reading fails.
    public func getForConnectedWallet() async throws -> [StoredCredential] {
        let state: ConnectedState
        do {
            state = try kit.requireConnected()
        } catch {
            // why: the connected-state lookup throws when no wallet is bound;
            // treat that as "no credentials available" rather than propagating
            // the connection error to a query-style caller.
            return []
        }
        return try await getCredentialsByContract(contractId: state.contractId)
    }

    /// Retrieves every credential whose deployment status is pending or failed.
    ///
    /// Returned credentials have not been confirmed on-chain and may need
    /// attention (retry, sync, or delete).
    ///
    /// - Returns: Credentials with status `.pending` or `.failed` (empty when
    ///   none match).
    /// - Throws: ``StorageException/ReadFailed`` when reading fails.
    public func getPendingCredentials() async throws -> [StoredCredential] {
        let all: [StoredCredential]
        do {
            all = try await storage.getAll()
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.readFailed(key: "all", cause: error)
        }

        return all.filter { credential in
            credential.deploymentStatus == .pending ||
                credential.deploymentStatus == .failed
        }
    }

    // MARK: - Public API: Update

    /// Updates the nickname of a stored credential.
    ///
    /// Overwrites the nickname when `nickname` is non-nil. Passing `nil` leaves
    /// the existing nickname unchanged (the partial-update path treats `nil` as
    /// a no-op).
    /// The credential must exist before the update; the manager does not create
    /// a new credential as a side effect.
    ///
    /// - Parameters:
    ///   - credentialId: Identifier of the credential to update.
    ///   - nickname: New nickname, or `nil` to leave the existing nickname
    ///     unchanged.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when the credential does not exist.
    ///   - ``StorageException/WriteFailed`` when the update fails.
    public func updateNickname(credentialId: String, nickname: String?) async throws {
        let update = StoredCredentialUpdate(nickname: nickname)
        try await updateCredential(credentialId: credentialId, updates: update)
    }

    /// Clears every credential from storage.
    ///
    /// This operation is irreversible. Use with caution.
    ///
    /// - Throws: ``StorageException/WriteFailed`` when clearing fails.
    public func clearAll() async throws {
        do {
            try await storage.clear()
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: "all", cause: error)
        }
    }

    // MARK: - Internal API: Lifecycle helpers

    /// Marks a credential as failed deployment and records the supplied error
    /// message.
    ///
    /// Updates the credential's `deploymentStatus` to ``CredentialDeploymentStatus/failed``
    /// and stores the supplied error message. The credential can be retried by
    /// deleting it and creating a new one with the same identifier.
    ///
    /// - Parameters:
    ///   - credentialId: Identifier of the credential whose deployment failed.
    ///   - error: Human-readable error message describing the failure.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when the credential does not exist.
    ///   - ``StorageException/WriteFailed`` when the update fails.
    internal func markDeploymentFailed(credentialId: String, error: String) async throws {
        let existing = try await storage.get(credentialId: credentialId)
        guard existing != nil else {
            throw CredentialException.notFound(credentialId: credentialId)
        }

        let update = StoredCredentialUpdate(
            deploymentStatus: .failed,
            deploymentError: error
        )

        do {
            try await storage.update(credentialId: credentialId, updates: update)
        } catch let error as CredentialException {
            throw error
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: credentialId, cause: error)
        }
    }

    /// Updates a credential with the supplied partial changes.
    ///
    /// Only non-nil fields in `updates` are applied. The credential must exist
    /// in storage before the update.
    ///
    /// - Parameters:
    ///   - credentialId: Identifier of the credential to update.
    ///   - updates: The partial updates to apply.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when the credential does not exist.
    ///   - ``StorageException/WriteFailed`` when the update fails.
    internal func updateCredential(
        credentialId: String,
        updates: StoredCredentialUpdate
    ) async throws {
        let existing = try await storage.get(credentialId: credentialId)
        guard existing != nil else {
            throw CredentialException.notFound(credentialId: credentialId)
        }

        do {
            try await storage.update(credentialId: credentialId, updates: updates)
        } catch let error as CredentialException {
            throw error
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: credentialId, cause: error)
        }
    }

    /// Updates the `lastUsedAt` timestamp on a credential to the current
    /// wall-clock time in milliseconds since the Unix epoch.
    ///
    /// - Parameter credentialId: Identifier of the credential to update.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when the credential does not exist.
    ///   - ``StorageException/WriteFailed`` when the update fails.
    internal func updateLastUsed(credentialId: String) async throws {
        let update = StoredCredentialUpdate(
            lastUsedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        try await updateCredential(credentialId: credentialId, updates: update)
    }

    /// Marks a credential as the primary credential for the user.
    ///
    /// Best-effort unsets `isPrimary` on every other credential bound to the
    /// same contract before promoting the supplied credential. Per-credential
    /// failures during the unset pass are intentionally swallowed: the new
    /// primary is always set, and a transient brief overlap of two
    /// `isPrimary == true` credentials only affects which credential the
    /// auto-connect flow selects (first match wins).
    ///
    /// - Parameter credentialId: Identifier of the credential to promote.
    /// - Throws:
    ///   - ``CredentialException/NotFound`` when the credential does not exist.
    ///   - ``StorageException/WriteFailed`` when the final promotion update fails.
    internal func setPrimary(credentialId: String) async throws {
        let credential = try await storage.get(credentialId: credentialId)
        guard let credential = credential else {
            throw CredentialException.notFound(credentialId: credentialId)
        }

        let siblings: [StoredCredential]
        if let contractId = credential.contractId, !contractId.isEmpty {
            siblings = try await storage.getByContract(contractId: contractId)
        } else {
            siblings = try await storage.getAll()
        }

        for sibling in siblings where sibling.isPrimary && sibling.credentialId != credentialId {
            do {
                try await storage.update(
                    credentialId: sibling.credentialId,
                    updates: StoredCredentialUpdate(isPrimary: false)
                )
            } catch {
                // why: best-effort. Failing to demote a sibling is not fatal —
                // the new primary is always set below, and a brief overlap is
                // acceptable because the auto-connect flow takes the first
                // match wins.
                _ = error
            }
        }

        let update = StoredCredentialUpdate(isPrimary: true)
        do {
            try await storage.update(credentialId: credentialId, updates: update)
        } catch let error as CredentialException {
            throw error
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(key: credentialId, cause: error)
        }
    }
}
