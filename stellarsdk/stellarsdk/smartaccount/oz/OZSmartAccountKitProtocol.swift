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

/// Internal credential-metadata persistence protocol consumed by wallet and transaction operations.
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
    /// - Returns: The persisted ``OZStoredCredential``.
    /// - Throws: ``SmartAccountValidationException`` for malformed inputs, ``SmartAccountCredentialException``
    ///           for duplicate identifiers, ``SmartAccountStorageException`` for write failures.
    func createPendingCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String,
        nickname: String?,
        transports: [String]?,
        deviceType: String?,
        backedUp: Bool?
    ) async throws -> OZStoredCredential

    /// Fetches a previously stored credential by identifier.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Returns: The credential when present, otherwise `nil`.
    /// - Throws: ``SmartAccountStorageException`` on read failure.
    func getCredential(credentialId: String) async throws -> OZStoredCredential?

    /// Marks the credential's deployment as failed and stores the supplied error message.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - error: Human-readable failure description preserved on the credential.
    /// - Throws: ``SmartAccountCredentialException``, ``SmartAccountStorageException``.
    func markDeploymentFailed(credentialId: String, error: String) async throws

    /// Sets the supplied credential as the primary credential for the user.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Throws: ``SmartAccountCredentialException``, ``SmartAccountStorageException``.
    func setPrimary(credentialId: String) async throws

    /// Updates the credential's last-used timestamp to the current wall-clock time.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Throws: ``SmartAccountCredentialException``, ``SmartAccountStorageException``.
    func updateLastUsed(credentialId: String) async throws

    /// Deletes the credential from storage if present.
    ///
    /// - Parameter credentialId: Base64URL-encoded credential identifier.
    /// - Throws: ``SmartAccountStorageException`` on write failure.
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
    /// - Throws: ``SmartAccountTransactionException`` on simulation failure, ``SmartAccountIndexerException``
    ///           when the indexer fallback fails.
    func listContextRules(maxScanId: UInt32?) async throws -> [OZParsedContextRule]

    /// Resolves which context-rule identifiers should be bound into the signing
    /// digest for the supplied authorization entry.
    ///
    /// - Parameters:
    ///   - entry: The authorization entry being signed.
    ///   - signers: The signer values participating in the current ceremony.
    ///   - contextRules: Pre-fetched rule view, supplied to avoid repeated RPC calls.
    /// - Returns: Identifiers of every rule whose root authorizes the entry.
    /// - Throws: ``SmartAccountValidationException`` when no rule matches the supplied signer set.
    func resolveContextRuleIdsForEntry(
        entry: SorobanAuthorizationEntryXDR,
        signers: [any OZSmartAccountSigner],
        contextRules: [OZParsedContextRule]
    ) async throws -> [UInt32]

    /// Returns the raw `SCValXDR` representation of every active context rule, used
    /// for low-level credential-id lookups when local storage is not authoritative.
    ///
    /// - Returns: Raw `Map` ScVal representation of each active rule.
    /// - Throws: ``SmartAccountTransactionException`` on simulation failure.
    func getAllContextRules(maxScanId: UInt32?) async throws -> [SCValXDR]

    /// Retrieves the raw `SCValXDR` payload of a single context rule by its
    /// numeric identifier.
    ///
    /// Issues a simulated host-function invocation against the connected
    /// smart-account contract. Use ``parseContextRule(_:)`` to convert the
    /// returned payload into the typed ``OZParsedContextRule`` shape.
    ///
    /// - Parameter id: The context-rule identifier to look up.
    /// - Returns: The raw `SCValXDR` payload returned by the contract.
    /// - Throws: ``SmartAccountWalletException/NotConnected`` when no wallet is connected;
    ///   ``SmartAccountTransactionException`` when the simulation fails.
    func getContextRule(id: UInt32) async throws -> SCValXDR

    /// Parses a raw context-rule `SCValXDR` payload into the typed
    /// ``OZParsedContextRule`` representation.
    ///
    /// - Parameter scVal: The raw `SCValXDR` payload returned by the contract.
    /// - Returns: A typed view over the rule's signers, signer ids, policies,
    ///   policy ids, name, and expiration ledger.
    /// - Throws: ``SmartAccountValidationException`` when the payload is malformed.
    func parseContextRule(_ scVal: SCValXDR) throws -> OZParsedContextRule
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
/// `close()` method is responsible for breaking the cycle when the kit
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
    /// in `resolveSubmissionMethod(forceMethod:)` falls back to RPC when this is `nil`.
    var relayerClient: OZRelayerClient? { get }

    /// Event emitter for the kit; receives lifecycle events emitted by wallet
    /// and transaction operations.
    var events: OZSmartAccountEventEmitter { get }

    /// Credential storage and metadata manager.
    var credentialManagerProtocol: OZCredentialManagerProtocol { get }

    /// Context-rule manager used to introspect on-chain rules during the
    /// signing pass and to resolve rule identifiers for authorization entries.
    var contextRuleManagerProtocol: OZContextRuleManagerProtocol { get }

    /// Transaction-operations instance bound to this kit. Wallet operations
    /// delegate the funding flow to this pinned instance so a single
    /// allocation site is shared across all callers.
    var transactionOperations: OZTransactionOperations { get }

    /// Returns the storage adapter used by the kit.
    func getStorage() -> OZStorageAdapter

    /// Returns the deployer keypair, deriving the default deterministic deployer
    /// when no explicit deployer is configured.
    ///
    /// - Returns: The keypair used to deploy smart-account contracts and to pay
    ///   transaction fees when no relayer is configured.
    /// - Throws: ``SmartAccountConfigurationException`` when default-deployer construction
    ///           fails.
    func getDeployer() async throws -> KeyPair

    /// Returns the connected wallet identity.
    ///
    /// - Returns: ``ConnectedState`` carrying the active credential and contract
    ///   identifiers.
    /// - Throws: ``SmartAccountWalletException/NotConnected`` when no wallet is connected.
    func requireConnected() throws -> ConnectedState

    /// Records the connected state on the kit.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - contractId: Smart account contract address.
    func setConnectedState(credentialId: String, contractId: String)

    /// Signer manager bound to this kit. Exposed through the protocol so
    /// sibling managers and tests can resolve it without holding a typed
    /// reference to the kit's concrete class.
    var signerManager: OZSignerManager { get }

    /// Policy manager bound to this kit.
    var policyManager: OZPolicyManager { get }

    /// Multi-signer manager bound to this kit. Coordinates signature
    /// collection across passkey and wallet signers when a manager method is
    /// invoked with a non-empty `selectedSigners` list.
    var multiSignerManager: OZMultiSignerManager { get }

    /// Kit-owned external-signer manager. The single front door for all
    /// external (non-passkey) signing sources. Constructed at kit
    /// initialization from the configuration's wallet adapter and Ed25519
    /// adapter; always non-`nil` and valid after ``close()``.
    var externalSigners: OZExternalSignerManager { get }

    /// Connected smart-account contract identifier, when a wallet is
    /// connected. Returns `nil` when no wallet is connected; callers that
    /// require connectivity should use ``requireConnected()`` instead.
    var contractId: String? { get }
}
