//
//  OZSmartAccountKit.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// MARK: - OZSmartAccountKit
// ============================================================================

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
/// ``OZWalletOperations/connectWallet(_:)`` explicitly when session
/// restoration is desired.
///
/// Example:
/// ```swift
/// let config = try OZSmartAccountConfig(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: "Test SDF Network ; September 2015",
///     accountWasmHash: "abc123...",
///     webauthnVerifierAddress: "CBCD1234..."
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
/// Thread Safety:
/// All mutable connection state (``credentialId``, ``contractId``, and the
/// closed-flag guard) is protected by an internal ``NSLock``. Public
/// non-`async` getters acquire the lock for the duration of the read; the
/// `async` mutators (``setConnectedState(credentialId:contractId:)``,
/// ``disconnect()``) acquire it for the write-and-snapshot window only and
/// release it before performing storage I/O or event emission so listeners
/// observing the lifecycle event cannot deadlock against the kit.
public final class OZSmartAccountKit: OZSmartAccountKitProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// The configuration the kit was constructed with.
    ///
    /// Thread-safe: the configuration is an immutable value type captured at
    /// construction.
    public let config: OZSmartAccountConfig

    // MARK: - HTTP and RPC clients

    /// The Soroban RPC client shared by all operations and managers.
    ///
    /// Constructed from ``OZSmartAccountConfig/rpcUrl`` at ``create(config:)``
    /// time. The kit owns the lifetime; consumer code should not close the
    /// server directly. ``close()`` invalidates the dedicated
    /// ``URLSession`` the kit injected into the server so any in-flight RPC
    /// traffic is cancelled at teardown.
    ///
    /// Thread-safe: the underlying ``SorobanServer`` synchronizes its own
    /// state internally.
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
    ///
    /// Thread-safe: the underlying ``OZIndexerClient`` is internally
    /// synchronized.
    public let indexerClient: OZIndexerClient?

    /// Optional relayer client used for fee-sponsored transaction submission.
    ///
    /// Present when ``OZSmartAccountConfig/relayerUrl`` is non-`nil` at
    /// ``create(config:)`` time. The kit owns the lifetime and invalidates the
    /// underlying `URLSession` on ``close()``.
    ///
    /// Thread-safe: the underlying ``OZRelayerClient`` is internally
    /// synchronized.
    public let relayerClient: OZRelayerClient?

    // MARK: - Storage

    /// Storage adapter for persisting credentials and sessions.
    ///
    /// Resolved from ``OZSmartAccountConfig/storage`` at construction time.
    /// Thread-safe: each ``StorageAdapter`` implementation is required to be
    /// `Sendable` and is responsible for its own concurrency guarantees.
    private let storage: StorageAdapter

    // MARK: - Events

    /// Event emitter shared by every manager bound to this kit.
    ///
    /// A single ``SmartAccountEventEmitter`` instance is created at kit
    /// construction time and exposed to consumers and to the wallet- and
    /// transaction-operations modules. Lifecycle and credential-lifecycle
    /// listeners installed here observe events from every manager belonging
    /// to the same kit.
    ///
    /// Thread-safe: ``SmartAccountEventEmitter`` synchronizes listener
    /// registration, removal, and dispatch with its own lock.
    public let events: SmartAccountEventEmitter

    // MARK: - Operations modules

    /// Wallet-operations module bound to this kit.
    ///
    /// Thread-safe: the reference is set during construction and never
    /// reassigned afterwards; the module is internally synchronized for its
    /// in-flight signing state.
    public var walletOperations: OZWalletOperations {
        // why: backed by an implicitly-unwrapped optional set inside the
        // initializer after every other stored property has been
        // initialized. The optional is required only because Swift's
        // two-phase initialization forbids passing `self` to the manager
        // constructors before every stored property exists. Externally the
        // property behaves as a non-optional `let`. Accessing it after
        // ``close()`` has nilled the backing storage is a programming error
        // and produces a deliberate implicitly-unwrapped-optional trap.
        return _walletOperations
    }
    private var _walletOperations: OZWalletOperations!

    /// Transaction-operations module bound to this kit.
    ///
    /// Thread-safe: see ``walletOperations`` for the initialization pattern.
    public var transactionOperations: OZTransactionOperations {
        return _transactionOperations
    }
    private var _transactionOperations: OZTransactionOperations!

    // MARK: - Managers

    /// Signer manager bound to this kit.
    ///
    /// Thread-safe: the reference is set during construction and never
    /// reassigned afterwards.
    public var signerManager: OZSignerManager {
        return _signerManager
    }
    private var _signerManager: OZSignerManager!

    /// Policy manager bound to this kit.
    public var policyManager: OZPolicyManager {
        return _policyManager
    }
    private var _policyManager: OZPolicyManager!

    /// Context-rule manager bound to this kit.
    ///
    /// Exposed through the protocol surface consumed by sibling managers
    /// and the operations modules. At runtime the property always holds
    /// the concrete ``OZContextRuleManager`` constructed during kit
    /// initialization; reach the concrete API through
    /// ``contextRuleManagerConcrete``.
    ///
    /// Thread-safe: the reference is set during construction and never
    /// reassigned afterwards.
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
    /// Thread-safe: the reference is set during construction and never
    /// reassigned afterwards.
    public var contextRuleManagerConcrete: OZContextRuleManager {
        return _contextRuleManager
    }

    /// Credential manager bound to this kit.
    ///
    /// Exposed through the protocol surface consumed by sibling managers
    /// and the operations modules. At runtime the property always holds
    /// the concrete ``OZCredentialManager`` constructed during kit
    /// initialization; reach the concrete API through
    /// ``credentialManagerConcrete``.
    ///
    /// Thread-safe: the reference is set during construction and never
    /// reassigned afterwards.
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
    /// Thread-safe: the reference is set during construction and never
    /// reassigned afterwards.
    public var credentialManagerConcrete: OZCredentialManager {
        return _credentialManager
    }

    /// Multi-signer manager bound to this kit.
    ///
    /// Thread-safe: the reference is immutable.
    public var multiSignerManager: OZMultiSignerManager {
        return _multiSignerManager
    }
    private var _multiSignerManager: OZMultiSignerManager!

    /// External-signer manager bound to this kit.
    ///
    /// Not instantiated by the kit. Consumer applications construct
    /// ``OZExternalSignerManager`` directly when they need to coordinate
    /// non-WebAuthn signers; the manager is standalone and does not hold a
    /// kit reference. The kit exposes this property for protocol conformance
    /// and to make the absence of a kit-owned external-signer pipeline
    /// explicit at the API surface.
    public let externalSignerManager: OZExternalSignerManager? = nil

    /// External-wallet adapter resolved from the kit's configuration.
    ///
    /// Thread-safe: the adapter reference is immutable for the kit's
    /// lifetime.
    public var externalWallet: ExternalWalletAdapter? {
        return config.externalWallet
    }

    // MARK: - Mutable connection state

    /// Lock protecting ``_credentialId``, ``_contractId``, and ``_closed``.
    ///
    /// why: a synchronous ``NSLock`` keeps the non-`async` getters
    /// (``isConnected``, ``credentialId``, ``contractId``) lock-free at the
    /// Swift-concurrency boundary. Holding the lock across the body of every
    /// public getter is sub-microsecond on Apple platforms and is the only
    /// reliable Swift mechanism for non-`async` reads of mutable state that
    /// may have been written from an arbitrary thread.
    private let stateLock = NSLock()

    /// Currently connected credential identifier (Base64URL-encoded).
    private var _credentialId: String? = nil

    /// Currently connected smart-account contract address (C-strkey).
    private var _contractId: String? = nil

    /// Set to `true` once ``close()`` has run. Guards against double-close
    /// re-entry across the optional indexer/relayer clients and the event
    /// emitter.
    private var _closed: Bool = false

    /// Cached deployer keypair to avoid repeated derivation on hot paths.
    ///
    /// why: cache is not synchronized; concurrent callers may redundantly
    /// invoke ``OZSmartAccountConfig/effectiveDeployer()``, but the result is
    /// deterministic and idempotent so the redundancy is harmless and avoids
    /// the cost of acquiring the state lock on every ``getDeployer()`` call.
    private var cachedDeployer: KeyPair? = nil

    // MARK: - Public state accessors

    /// Indicates whether a wallet is currently connected.
    ///
    /// A wallet is connected when both the credential id and the contract id
    /// are set. This property reflects in-memory state only; after an app
    /// restart consumers should call
    /// ``OZWalletOperations/connectWallet(_:)`` to restore a saved session.
    ///
    /// Thread-safe.
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
    ///
    /// Thread-safe.
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
    ///
    /// Thread-safe.
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

        // why: every manager and operations module captures the kit through
        // the internal protocol so they can resolve RPC, configuration,
        // events, storage, and sibling managers without holding a typed
        // reference to this concrete class. The implicitly-unwrapped
        // optional backing storage is the standard Swift workaround for the
        // two-stage initialization rule: every other `let` / `var` stored
        // property has now been initialized, so `self` is reachable and
        // each manager can capture it. The context-rule manager is
        // constructed first because the signer and policy managers consume
        // it as a parser collaborator; the multi-signer manager is reached
        // through `kit.multiSignerManager` at call time, so its
        // construction no longer needs to precede the signer- and
        // policy-manager constructions.
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
    /// Thread-safe.
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
    /// ``OZWalletOperations/connectWallet(_:)``.
    ///
    /// Safe to call even when no wallet is connected.
    ///
    /// Thread-safe: clears the state under the lock, then releases the lock
    /// before invoking storage I/O and event emission so listeners observing
    /// the disconnected event see `isConnected == false` and cannot deadlock
    /// against the kit.
    public func disconnect() async throws {
        // why: NSLock cannot be acquired across an `await` boundary, so the
        // captured-and-clear transition is encapsulated in a synchronous
        // helper that returns the prior contract id outside the lock. The
        // storage-clear and event-emission steps then run without holding
        // the lock so a listener observing the disconnected event sees
        // `isConnected == false` and cannot deadlock against the kit.
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

    /// Closes the kit and releases the HTTP-client and event-emitter
    /// resources it owns.
    ///
    /// Closes the shared ``SorobanServer`` first so any in-flight RPC traffic
    /// is cancelled before the indexer and relayer transports tear down, then
    /// closes the indexer client (when present), the relayer client (when
    /// present), and removes every listener registered on ``events``. The
    /// in-memory connection state is not cleared by ``close()``; call
    /// ``disconnect()`` first when ending an active session before releasing
    /// the transport. ``close()`` is idempotent — calling it more than once
    /// is a no-op after the first call.
    ///
    /// Thread-safe: the close flag is guarded by the state lock; only the
    /// first invocation reaches the wrapped clients and the event emitter.
    public func close() async {
        // why: NSLock cannot be acquired across an `await` boundary because
        // Swift's concurrency model treats `unlock()` as unavailable inside
        // an async context. The close-flag transition is performed by a
        // synchronous helper so the async caller does not straddle the
        // lock; the helper returns `false` when the kit was already closed,
        // short-circuiting the teardown work.
        if !markClosed() {
            return
        }

        // why: the wrapped HTTP clients enforce their own internal
        // idempotency, but acquiring the kit's own close flag first
        // guarantees the listener-removal step runs exactly once across
        // re-entrant callers and avoids double-firing any teardown
        // assertions installed by test doubles. Order matters: cancel the
        // RPC transport first so any in-flight Soroban traffic stops
        // before the indexer and relayer clients release their own
        // transports.
        sorobanServer.close()
        ownedUrlSession?.invalidateAndCancel()
        events.removeAllListeners()
        indexerClient?.close()
        relayerClient?.close()

        // why: each manager and operations module captures the kit through
        // an internal protocol reference. Under ARC those references form a
        // strong-reference cycle (kit → manager → kit) that the runtime
        // cannot reclaim unless one side releases the other explicitly.
        // Dropping every manager reference here breaks the cycle so the
        // kit can deallocate once the consumer drops its own reference.
        // Subsequent accesses to any manager property after ``close()`` are
        // a programming error and produce an implicitly-unwrapped-optional
        // trap, matching the documented "must not use after close" rule.
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

    /// Releases the kit's strong references to every manager and operations
    /// module so the kit ↔ manager retain cycle can be reclaimed by ARC.
    ///
    /// Invoked from ``close()``; never invoked from any other code path.
    ///
    /// After this method runs every public manager / operations accessor
    /// is backed by a `nil` implicitly-unwrapped optional. Touching one of
    /// them after ``close()`` is a programming error and produces an
    /// IUO-nil runtime trap. The kit deliberately surfaces that trap
    /// rather than returning a stale reference so a misuse cannot escape
    /// unnoticed.
    private func releaseManagerReferences() {
        _walletOperations = nil
        _transactionOperations = nil
        _signerManager = nil
        _policyManager = nil
        _contextRuleManager = nil
        _credentialManager = nil
        _multiSignerManager = nil
    }

    // MARK: - Storage and deployer helpers

    /// Returns the storage adapter used by the kit.
    ///
    /// Thread-safe: the adapter reference is immutable.
    public func getStorage() -> StorageAdapter {
        return storage
    }

    /// Returns the deployer keypair, deriving the default deterministic
    /// deployer when no explicit deployer is configured.
    ///
    /// The result is cached after the first call. The cache is not
    /// synchronized — concurrent first callers may invoke
    /// ``OZSmartAccountConfig/effectiveDeployer()`` more than once, but the
    /// result is deterministic and idempotent so the redundant invocation
    /// is harmless and the property avoids the cost of acquiring the state
    /// lock on every call.
    ///
    /// - Returns: The keypair used to deploy smart-account contracts and to
    ///   pay transaction fees when no relayer is configured.
    /// - Throws: ``ConfigurationException/InvalidConfig`` when default
    ///   deployer derivation fails.
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
    /// ``OZWalletOperations/connectWallet(_:)`` after construction when
    /// session restoration is desired.
    ///
    /// - Parameter config: The configuration for the kit.
    /// - Returns: A new kit bound to the supplied configuration.
    public static func create(config: OZSmartAccountConfig) -> OZSmartAccountKit {
        let relayerClient: OZRelayerClient? = config.relayerUrl.flatMap { url in
            // why: invalid relayer URLs are rejected at configuration
            // construction time, so a non-`nil` URL is already known to
            // satisfy the relayer client's URL-validation contract. The
            // optional `try?` is defensive against a future relaxation of
            // the configuration validator.
            return try? OZRelayerClient(
                relayerUrl: url,
                timeoutMs: OZConstants.defaultRelayerTimeoutMs
            )
        }

        let indexerClient: OZIndexerClient? = config.effectiveIndexerUrl().flatMap { url in
            // why: the configuration provides either an explicit indexer URL
            // (already validated at construction time) or a default URL
            // resolved from `OZIndexerClient.getDefaultUrl(networkPassphrase:)`,
            // which is the same code path the client validates against.
            // Either way the URL satisfies the indexer client's constructor
            // contract; the optional `try?` is defensive against a future
            // relaxation of those checks.
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
