//
//  OZSmartAccountKit.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Primary entry point for OpenZeppelin smart-account operations on Soroban.
///
/// The kit is the composition root that owns the operations modules
/// (``OZWalletOperations``, ``OZTransactionOperations``) and the per-domain
/// managers (``OZSignerManager``, ``OZPolicyManager``, ``OZContextRuleManager``,
/// ``OZCredentialManager``, ``OZMultiSignerManager``) bound to a single
/// configuration. It also holds the lifetime of the optional indexer and
/// relayer HTTP clients and the shared ``SorobanServer``.
///
/// Consumer applications obtain an instance through ``create(config:)``; the
/// initializer is `internal` so direct construction outside the SDK is not
/// permitted. The factory does not perform any network requests — it wires the
/// configuration into the runtime collaborators and returns a ready-to-use
/// kit. Saved sessions are not loaded automatically; call
/// ``OZWalletOperations/connectWallet(options:)`` explicitly when session
/// restoration is desired.
///
/// Example:
/// ```swift
/// let config = try OZSmartAccountConfig(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: Network.testnet.passphrase,
///     accountWasmHash: "<64-char hex WASM hash>",
///     webauthnVerifierAddress: "<C-strkey of WebAuthn verifier contract>"
/// )
/// let kit = OZSmartAccountKit.create(config: config)
/// defer {
///     Task { await kit.close() }
/// }
///
/// let wallet = try await kit.walletOperations.createWallet(userName: "My Wallet")
/// print("Created wallet: \(wallet.contractId)")
/// ```
///
public final class OZSmartAccountKit: OZSmartAccountKitProtocol, @unchecked Sendable {

    /// The configuration the kit was constructed with.
    public let config: OZSmartAccountConfig

    /// The Soroban RPC client shared by all operations and managers.
    ///
    /// Constructed from ``OZSmartAccountConfig/rpcUrl`` at ``create(config:)``
    /// time. The kit owns the lifetime; consumer code should not close the
    /// server directly. ``close()`` invalidates the dedicated
    /// ``URLSession`` the kit injected into the server so any in-flight RPC
    /// traffic is cancelled at teardown.
    public let sorobanServer: SorobanServer

    /// URL session injected into ``sorobanServer`` and owned by this kit.
    ///
    /// Non-nil when the kit was constructed through ``create(config:)``,
    /// which always allocates a dedicated session so ``close()`` can release
    /// the RPC transport without affecting ``URLSession/shared``. Nil when
    /// the kit was constructed through the internal init with a
    /// pre-built ``SorobanServer`` (test-only path); in that case session
    /// lifecycle is the caller's responsibility.
    private let ownedUrlSession: URLSession?

    /// Optional indexer client used for credential-to-contract discovery.
    ///
    /// Present when ``OZSmartAccountConfig/effectiveIndexerUrl()`` resolves to
    /// a non-`nil` URL at ``create(config:)`` time. The kit owns the lifetime
    /// and invalidates the underlying `URLSession` on ``close()``.
    public let indexerClient: OZIndexerClient?

    /// Optional relayer client used for fee-sponsored transaction submission.
    ///
    /// Present when ``OZSmartAccountConfig/relayerUrl`` is non-`nil` at
    /// ``create(config:)`` time. The kit owns the lifetime and invalidates the
    /// underlying `URLSession` on ``close()``.
    public let relayerClient: OZRelayerClient?

    /// Storage adapter for persisting credentials and sessions.
    private let storage: StorageAdapter

    /// Event emitter shared by every manager bound to this kit.
    ///
    /// A single ``SmartAccountEventEmitter`` instance is created at kit
    /// construction time and exposed to consumers and to the wallet- and
    /// transaction-operations modules. Lifecycle and credential-lifecycle
    /// listeners installed here observe events from every manager belonging
    /// to the same kit.
    public let events: SmartAccountEventEmitter

    /// Wallet-operations module bound to this kit.
    ///
    /// Backed by an implicitly-unwrapped optional set inside the initializer after every
    /// other stored property has been initialized — required because Swift's two-phase
    /// initialization forbids passing `self` to manager constructors before every stored
    /// property exists. Externally the property behaves as a non-optional `let`.
    ///
    /// Traps if accessed after `close()`.
    public var walletOperations: OZWalletOperations {
        return _walletOperations
    }
    private var _walletOperations: OZWalletOperations!

    /// Transaction-operations module bound to this kit.
    ///
    /// Traps if accessed after `close()`.
    public var transactionOperations: OZTransactionOperations {
        return _transactionOperations
    }
    private var _transactionOperations: OZTransactionOperations!

    /// Signer manager bound to this kit.
    ///
    /// Traps if accessed after `close()`.
    public var signerManager: OZSignerManager {
        return _signerManager
    }
    private var _signerManager: OZSignerManager!

    /// Policy manager bound to this kit.
    ///
    /// Traps if accessed after `close()`.
    public var policyManager: OZPolicyManager {
        return _policyManager
    }
    private var _policyManager: OZPolicyManager!

    /// Context-rule manager bound to this kit.
    ///
    /// Exposed through the protocol surface consumed by sibling managers
    /// and the operations modules. At runtime the property always holds
    /// the concrete ``OZContextRuleManager`` constructed during kit
    /// initialization.
    ///
    /// Traps if accessed after `close()`.
    internal var contextRuleManager: OZContextRuleManagerProtocol {
        return _contextRuleManager
    }
    private var _contextRuleManager: OZContextRuleManager!

    /// Concrete-typed context-rule manager accessor.
    ///
    /// Exposes the concrete ``OZContextRuleManager`` API surface (which
    /// extends the read-only protocol surface with mutation helpers used by
    /// the kit's own composition graph).
    ///
    /// Traps if accessed after `close()`.
    public var contextRuleManagerConcrete: OZContextRuleManager {
        return _contextRuleManager
    }

    /// Credential manager bound to this kit.
    ///
    /// Exposed through the protocol surface consumed by sibling managers
    /// and the operations modules. At runtime the property always holds
    /// the concrete ``OZCredentialManager`` constructed during kit
    /// initialization.
    ///
    /// Traps if accessed after `close()`.
    internal var credentialManager: OZCredentialManagerProtocol {
        return _credentialManager
    }
    private var _credentialManager: OZCredentialManager!

    /// Concrete-typed credential-manager accessor.
    ///
    /// Exposes the concrete ``OZCredentialManager`` API surface (which
    /// extends the read-only protocol surface with bulk credential-listing
    /// and sync helpers consumed by application code).
    ///
    /// Traps if accessed after `close()`.
    public var credentialManagerConcrete: OZCredentialManager {
        return _credentialManager
    }

    /// Multi-signer manager bound to this kit.
    ///
    /// Traps if accessed after `close()`.
    public var multiSignerManager: OZMultiSignerManager {
        return _multiSignerManager
    }
    private var _multiSignerManager: OZMultiSignerManager!

    /// Kit-owned external-signer manager. The single front door for all external (non-passkey)
    /// signing sources.
    ///
    /// Constructed at kit initialization from ``OZSmartAccountConfig/externalWallet`` and
    /// ``OZSmartAccountConfig/externalEd25519Adapter``. Always non-`nil`; remains valid
    /// after ``close()``. Register in-memory keypairs at runtime via
    /// ``OZExternalSignerManager/addFromSecret(secretKey:)`` and
    /// ``OZExternalSignerManager/addEd25519FromRawKey(secretKeyBytes:verifierAddress:)``.
    public var externalSigners: OZExternalSignerManager {
        return _externalSigners
    }
    private let _externalSigners: OZExternalSignerManager

    // Sync lock keeps the non-async accessors (isConnected, credentialId, contractId) lock-free at the Swift-concurrency boundary.
    private let stateLock = NSLock()

    /// Currently connected credential identifier (Base64URL-encoded).
    private var _credentialId: String? = nil

    /// Currently connected smart-account contract address (C-strkey).
    private var _contractId: String? = nil

    /// Set to `true` once ``close()`` has run. Guards against double-close
    /// re-entry across the optional indexer/relayer clients and the event
    /// emitter.
    private var _closed: Bool = false

    // Cached deployer keypair; unsynchronized — concurrent first callers may redundantly
    // derive the key but the result is deterministic and idempotent.
    private var cachedDeployer: KeyPair? = nil

    /// Indicates whether a wallet is currently connected.
    ///
    /// A wallet is connected when both the credential id and the contract id
    /// are set. This property reflects in-memory state only; after an app
    /// restart consumers should call
    /// ``OZWalletOperations/connectWallet(options:)`` to restore a saved session.
    public var isConnected: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _credentialId != nil && _contractId != nil
    }

    /// The credential identifier of the currently connected wallet, when a
    /// wallet is connected.
    ///
    /// Returns `nil` when no wallet is connected. The credential id is
    /// Base64URL-encoded without padding, matching the WebAuthn
    /// specification.
    public var credentialId: String? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _credentialId
    }

    /// The contract address of the currently connected wallet, when a wallet
    /// is connected.
    ///
    /// Returns `nil` when no wallet is connected. The contract id is a
    /// Stellar C-strkey (56 characters, starting with `C`).
    public var contractId: String? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _contractId
    }

    // MARK: - Initialization

    /// Initializes a new kit with the supplied configuration and
    /// pre-constructed collaborators.
    ///
    /// Internal to keep the configuration-to-collaborator wiring inside the
    /// SDK; consumer code constructs a kit through ``create(config:)``.
    ///
    /// - Parameters:
    ///   - config: The active configuration.
    ///   - storage: The storage adapter resolved from `config.storage`.
    ///   - sorobanServer: The Soroban RPC client owned by the kit.
    ///   - relayerClient: The optional relayer client owned by the kit.
    ///   - indexerClient: The optional indexer client owned by the kit.
    internal init(
        config: OZSmartAccountConfig,
        storage: StorageAdapter,
        sorobanServer: SorobanServer,
        relayerClient: OZRelayerClient?,
        indexerClient: OZIndexerClient?,
        ownedUrlSession: URLSession? = nil
    ) {
        self.config = config
        self.storage = storage
        self.sorobanServer = sorobanServer
        self.relayerClient = relayerClient
        self.indexerClient = indexerClient
        self.ownedUrlSession = ownedUrlSession
        self.events = SmartAccountEventEmitter()
        self._externalSigners = OZExternalSignerManager(
            networkPassphrase: config.networkPassphrase,
            walletAdapter: config.externalWallet,
            walletConnectionStorage: nil,
            ed25519Adapter: config.externalEd25519Adapter
        )

        // Every manager captures the kit through the internal protocol. The IUO backing
        // stores are the standard Swift workaround for the two-phase init rule (see
        // walletOperations doc). Context-rule manager is constructed first because signer
        // and policy managers consume it as a parser collaborator.
        let credentialManager = OZCredentialManager(kit: self)
        let contextRuleManager = OZContextRuleManager(kit: self)
        let multiSignerManager = OZMultiSignerManager(kit: self)
        let signerManager = OZSignerManager(
            kit: self,
            contextRuleParser: contextRuleManager
        )
        let policyManager = OZPolicyManager(
            kit: self,
            contextRuleParser: contextRuleManager
        )
        let walletOperations = OZWalletOperations(kit: self)
        let transactionOperations = OZTransactionOperations(kit: self)

        self._credentialManager = credentialManager
        self._contextRuleManager = contextRuleManager
        self._multiSignerManager = multiSignerManager
        self._signerManager = signerManager
        self._policyManager = policyManager
        self._walletOperations = walletOperations
        self._transactionOperations = transactionOperations
    }

    // MARK: - Lifecycle

    /// Sets the connected wallet state.
    ///
    /// Called by wallet-operations modules after a successful wallet
    /// creation or connection. Records the credential id and contract id
    /// under the state lock.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - contractId: Smart account contract address (C-strkey).
    internal func setConnectedState(credentialId: String, contractId: String) {
        stateLock.lock()
        _credentialId = credentialId
        _contractId = contractId
        stateLock.unlock()
    }

    /// Returns the connected wallet identity.
    ///
    /// - Returns: A ``ConnectedState`` carrying the active credential and
    ///   contract identifiers.
    /// - Throws: ``WalletException/NotConnected`` when no wallet is
    ///   connected.
    internal func requireConnected() throws -> ConnectedState {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let cId = _credentialId, let ctId = _contractId else {
            throw WalletException.notConnected(
                details: "No wallet connected. Call createWallet() or connectWallet() first."
            )
        }
        return ConnectedState(credentialId: cId, contractId: ctId)
    }

    /// Disconnects the currently connected wallet.
    ///
    /// Clears the in-memory connection state, removes the persisted session
    /// via ``StorageAdapter/clearSession()``, and emits
    /// ``SmartAccountEvent/walletDisconnected(contractId:)`` when a wallet
    /// was connected at the time of the call. Stored credentials remain in
    /// storage and can be reconnected with
    /// ``OZWalletOperations/connectWallet(options:)``.
    ///
    /// Safe to call even when no wallet is connected. State is cleared under the lock before
    /// storage I/O and event emission so listeners see `isConnected == false` without deadlock.
    public func disconnect() async throws {
        // NSLock cannot span an await; sync helper does the clear-and-snapshot transition.
        let contractIdToEmit = clearConnectedStateSnapshot()

        try await storage.clearSession()

        if let cId = contractIdToEmit {
            events.emit(.walletDisconnected(contractId: cId))
        }
    }

    /// Captures the current contract id and clears the connection state
    /// under the state lock.
    ///
    /// Returns the previously connected contract id (or `nil` when no
    /// wallet was connected) so the caller can decide whether to emit a
    /// disconnect event outside the lock.
    private func clearConnectedStateSnapshot() -> String? {
        stateLock.lock()
        defer { stateLock.unlock() }
        let previousContractId = _contractId
        _credentialId = nil
        _contractId = nil
        return previousContractId
    }

    /// Closes the kit and releases the HTTP-client and event-emitter resources it owns.
    ///
    /// Closes the shared ``SorobanServer`` first so any in-flight RPC traffic is cancelled
    /// before the indexer and relayer transports tear down, then closes the indexer client
    /// (when present), the relayer client (when present), and removes every listener
    /// registered on ``events``. The in-memory connection state is not cleared by ``close()``;
    /// call ``disconnect()`` first when ending an active session. ``close()`` is idempotent.
    public func close() async {
        // NSLock cannot span an await; sync helper does the close-flag transition.
        if !markClosed() {
            return
        }

        // Cancel RPC transport first so in-flight calls stop before HTTP clients tear down.
        sorobanServer.close()
        ownedUrlSession?.invalidateAndCancel()
        events.removeAllListeners()
        indexerClient?.close()
        relayerClient?.close()

        // Break the kit ↔ manager ARC cycle so the kit can deallocate once the consumer
        // drops its own reference. Post-close manager access traps on the IUO backing store.
        releaseManagerReferences()
    }

    /// Transitions the close flag from `false` to `true` under the state
    /// lock and reports whether the caller is the first closer.
    ///
    /// Returns `true` when the calling invocation observed the kit as not
    /// previously closed and is therefore responsible for releasing the
    /// owned resources. Returns `false` when another caller has already
    /// performed the transition; the calling invocation must skip
    /// teardown.
    private func markClosed() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        if _closed {
            return false
        }
        _closed = true
        return true
    }

    /// Releases strong references to every manager and operations module, breaking the
    /// kit ↔ manager ARC cycle. Invoked only from ``close()``.
    private func releaseManagerReferences() {
        _walletOperations = nil
        _transactionOperations = nil
        _signerManager = nil
        _policyManager = nil
        _contextRuleManager = nil
        _credentialManager = nil
        _multiSignerManager = nil
    }

    /// Returns the storage adapter used by the kit.
    public func getStorage() -> StorageAdapter {
        return storage
    }

    /// Returns the deployer keypair, deriving the default deterministic deployer when no
    /// explicit deployer is configured. The result is cached after the first call.
    ///
    /// - Returns: The keypair used to deploy smart-account contracts and to pay transaction
    ///   fees when no relayer is configured.
    /// - Throws: ``ConfigurationException/InvalidConfig`` when default deployer derivation fails.
    public func getDeployer() async throws -> KeyPair {
        if let cached = cachedDeployer {
            return cached
        }
        let deployer = try await config.effectiveDeployer()
        cachedDeployer = deployer
        return deployer
    }

    // MARK: - Factory

    /// Creates a new ``OZSmartAccountKit`` for the supplied configuration.
    ///
    /// Wires the configuration's storage adapter, RPC URL, optional relayer
    /// URL, and optional indexer URL into runtime collaborators. The
    /// factory does not perform any network requests and does not load any
    /// saved session — call
    /// ``OZWalletOperations/connectWallet(options:)`` after construction when
    /// session restoration is desired.
    ///
    /// - Parameter config: The configuration for the kit.
    /// - Returns: A new kit bound to the supplied configuration.
    public static func create(config: OZSmartAccountConfig) -> OZSmartAccountKit {
        let relayerClient: OZRelayerClient? = config.relayerUrl.flatMap { url in
            // try? is defensive — URL is pre-validated at config init.
            return try? OZRelayerClient(
                relayerUrl: url,
                timeoutMs: OZConstants.defaultRelayerTimeoutMs
            )
        }

        let indexerClient: OZIndexerClient? = config.effectiveIndexerUrl().flatMap { url in
            // try? is defensive — URL is pre-validated at config init.
            return try? OZIndexerClient(
                indexerUrl: url,
                timeoutMs: OZConstants.defaultIndexerTimeoutMs
            )
        }

        // Dedicated URL session so ``close()`` can release the RPC transport
        // without affecting ``URLSession/shared``, which is the default
        // session used by the rest of the SDK and by application code that
        // constructs ``SorobanServer`` directly.
        let ownedUrlSession = URLSession(configuration: .default)
        let sorobanServer = SorobanServer(
            endpoint: config.rpcUrl,
            urlSession: ownedUrlSession
        )

        return OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: sorobanServer,
            relayerClient: relayerClient,
            indexerClient: indexerClient,
            ownedUrlSession: ownedUrlSession
        )
    }
}
