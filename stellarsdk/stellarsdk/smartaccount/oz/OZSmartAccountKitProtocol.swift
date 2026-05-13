//
//  OZSmartAccountKitProtocol.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Connected State

/// The connected state of an OpenZeppelin Smart Account Kit.
///
/// Returned by ``OZSmartAccountKitProtocol/requireConnected()`` after a successful
/// wallet connection. Identifies the credential and contract address bound to the
/// active session.
internal struct ConnectedState: Sendable, Equatable, Hashable {

    /// WebAuthn credential ID (Base64URL-encoded, no padding).
    let credentialId: String

    /// Smart account contract address (`C…` strkey).
    let contractId: String

    /// Initializes a new `ConnectedState`.
    init(credentialId: String, contractId: String) {
        self.credentialId = credentialId
        self.contractId = contractId
    }
}

// MARK: - Credential Manager Protocol

/// Storage-coordinator surface consumed by wallet and transaction operations.
///
/// Concrete implementations persist credential metadata, mark deployment outcomes,
/// and track the most recently used credential. Wallet and transaction operations
/// invoke these methods on best-effort paths; failures are swallowed at the call site
/// when the underlying operation is non-critical (for example, tracking
/// `lastUsedAt` after a successful signing pass).
internal protocol OZCredentialManagerProtocol: AnyObject, Sendable {

    /// Persists a new credential in the `pending` deployment state.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - publicKey: Uncompressed secp256r1 public key (65 bytes starting with `0x04`).
    ///   - contractId: Derived smart account contract address.
    ///   - nickname: Optional display name carried into the stored credential.
    ///   - transports: Optional WebAuthn transport hints captured during registration.
    ///   - deviceType: Optional authenticator device type (`singleDevice` / `multiDevice`).
    ///   - backedUp: Optional cloud-sync flag from the WebAuthn ceremony.
    /// - Returns: The persisted ``StoredCredential``.
    /// - Throws: ``ValidationException`` for malformed inputs, ``CredentialException``
    ///           for duplicate identifiers, ``StorageException`` for write failures.
    func createPendingCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String,
        nickname: String?,
        transports: [String]?,
        deviceType: String?,
        backedUp: Bool?
    ) async throws -> StoredCredential

    /// Fetches a previously stored credential by identifier.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Returns: The credential when present, otherwise `nil`.
    /// - Throws: ``StorageException`` on read failure.
    func getCredential(credentialId: String) async throws -> StoredCredential?

    /// Marks the credential's deployment as failed and stores the supplied error message.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - error: Human-readable failure description preserved on the credential.
    /// - Throws: ``CredentialException``, ``StorageException``.
    func markDeploymentFailed(credentialId: String, error: String) async throws

    /// Sets the supplied credential as the primary credential for the user.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Throws: ``CredentialException``, ``StorageException``.
    func setPrimary(credentialId: String) async throws

    /// Updates the credential's last-used timestamp to the current wall-clock time.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Throws: ``CredentialException``, ``StorageException``.
    func updateLastUsed(credentialId: String) async throws

    /// Deletes the credential from storage if present.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Throws: ``StorageException`` on write failure.
    func deleteCredential(credentialId: String) async throws
}

// MARK: - Context Rule Manager Protocol

/// Context-rule introspection surface consumed by transaction operations.
///
/// Wallet operations pre-fetch the active context rule set before iterating
/// authorization entries so the auth-entry signing loop avoids `N+1` RPC round
/// trips. The raw `SCValXDR` accessor supports inline credential-id discovery
/// for entries whose verifier key data is only available on-chain.
internal protocol OZContextRuleManagerProtocol: AnyObject, Sendable {

    /// Returns the parsed view of every active context rule on the connected smart
    /// account contract.
    ///
    /// - Returns: Parsed context rules in ascending rule-id order.
    /// - Throws: ``TransactionException`` on simulation failure, ``IndexerException``
    ///           when the indexer fallback fails.
    func listContextRules() async throws -> [ParsedContextRule]

    /// Resolves which context-rule identifiers should be bound into the signing
    /// digest for the supplied authorization entry.
    ///
    /// - Parameters:
    ///   - entry: The authorization entry being signed.
    ///   - signers: The signer values participating in the current ceremony.
    ///   - contextRules: Pre-fetched rule view, supplied to avoid repeated RPC calls.
    /// - Returns: Identifiers of every rule whose root authorizes the entry.
    /// - Throws: ``ValidationException`` when no rule matches the supplied signer set.
    func resolveContextRuleIdsForEntry(
        entry: SorobanAuthorizationEntryXDR,
        signers: [any OZSmartAccountSigner],
        contextRules: [ParsedContextRule]
    ) async throws -> [UInt32]

    /// Returns the raw `SCValXDR` representation of every active context rule, used
    /// for low-level credential-id lookups when local storage is not authoritative.
    ///
    /// - Returns: Raw `Map` ScVal representation of each active rule.
    /// - Throws: ``TransactionException`` on simulation failure.
    func getAllContextRules() async throws -> [SCValXDR]
}

// MARK: - OZSmartAccountKit Protocol

/// Internal surface that ``OZTransactionOperations`` and ``OZWalletOperations``
/// consume to interact with the kit they belong to.
///
/// The smart-account kit conforms to this protocol. Wallet- and
/// transaction-operations capture a strong reference to the kit through this
/// protocol so they can resolve RPC endpoints, configuration, event emission,
/// persistent storage, and managers without holding a typed kit reference
/// (which would create a circular declaration order between the operations
/// classes and the kit / manager modules they belong to).
///
/// Lifetime: the kit owns both operations classes (`kit.transactionOperations`
/// and `kit.walletOperations`). Each operations instance holds a strong
/// reference back to the kit through this protocol. The kit's own
/// `disconnect()` method is responsible for breaking the cycle when the kit
/// is torn down.
internal protocol OZSmartAccountKitProtocol: AnyObject, Sendable {

    /// Active configuration for the kit.
    var config: OZSmartAccountConfig { get }

    /// Soroban RPC client used for simulation, submission, polling, account
    /// lookups, and contract-data reads.
    var sorobanServer: SorobanServer { get }

    /// Optional indexer client. When `nil`, the cascade in ``OZWalletOperations``
    /// surfaces a "no contract found" error instead of falling through.
    var indexerClient: OZIndexerClient? { get }

    /// Optional relayer client used for fee-sponsored submission. Auto-detection
    /// in `getSubmissionMethod(_:)` falls back to RPC when this is `nil`.
    var relayerClient: OZRelayerClient? { get }

    /// Event emitter for the kit; receives lifecycle events emitted by wallet
    /// and transaction operations.
    var events: SmartAccountEventEmitter { get }

    /// Credential storage and metadata manager.
    var credentialManager: OZCredentialManagerProtocol { get }

    /// Context-rule manager used to introspect on-chain rules during the
    /// signing pass and to resolve rule identifiers for authorization entries.
    var contextRuleManager: OZContextRuleManagerProtocol { get }

    /// Transaction-operations instance bound to this kit. Wallet operations
    /// reach back through this property to delegate the funding flow
    /// (``OZTransactionOperations/fundWallet(nativeTokenContract:forceMethod:)``)
    /// to a single pinned instance per kit. Constructing a throwaway
    /// transaction-operations instance per call would break call-site
    /// invocation recording in test doubles and would silently double the
    /// number of allocation sites in production.
    var transactionOperations: OZTransactionOperations { get }

    /// Returns the storage adapter used by the kit.
    func getStorage() -> StorageAdapter

    /// Returns the deployer keypair, deriving the default deterministic deployer
    /// when no explicit deployer is configured.
    ///
    /// - Returns: The keypair used to deploy smart-account contracts and to pay
    ///   transaction fees when no relayer is configured.
    /// - Throws: ``ConfigurationException`` when default-deployer construction
    ///           fails.
    func getDeployer() async throws -> KeyPair

    /// Returns the connected wallet identity.
    ///
    /// - Returns: ``ConnectedState`` carrying the active credential and contract
    ///   identifiers.
    /// - Throws: ``WalletException/NotConnected`` when no wallet is connected.
    func requireConnected() throws -> ConnectedState

    /// Records the connected state on the kit.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - contractId: Smart account contract address.
    func setConnectedState(credentialId: String, contractId: String)
}
