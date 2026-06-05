//
//  MockOZSmartAccountKit.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Test double for the smart account kit dependency consumed by
/// ``OZTransactionOperations`` and ``OZWalletOperations``.
///
/// Holds an in-memory connected state, a `SorobanServer` (configured against a
/// non-routable host so live RPC calls fail cleanly unless a `MockSorobanServer`
/// is supplied), a real ``OZInMemoryStorageAdapter``, an in-memory credential
/// manager that satisfies the ``OZCredentialManagerProtocol`` surface, and a
/// stub context-rule manager that returns empty data so the signing pass
/// falls through to the on-chain fallback when it is exercised.
final class MockOZSmartAccountKit: OZSmartAccountKitProtocol, @unchecked Sendable {

    // MARK: - OZSmartAccountKitProtocol surface

    let config: OZSmartAccountConfig
    let sorobanServer: SorobanServer
    var indexerClient: OZIndexerClient?
    var relayerClient: OZRelayerClient?
    let events: OZSmartAccountEventEmitter
    let credentialManager: OZCredentialManagerProtocol
    let contextRuleManager: OZContextRuleManagerProtocol

    // MARK: - Connected state

    private let stateLock = NSLock()
    private var connectedCredentialId: String?
    private var connectedContractId: String?

    // MARK: - Pinned transactionOperations

    private let txOpsLock = NSLock()
    private var _transactionOperations: OZTransactionOperations?

    /// Lazy-init pinned transaction-operations instance. Constructing on first
    /// access avoids the circular declaration between the kit and the
    /// operations classes; subsequent calls return the same instance so test
    /// assertions over invocation counts remain stable.
    var transactionOperations: OZTransactionOperations {
        txOpsLock.lock()
        defer { txOpsLock.unlock() }
        if let existing = _transactionOperations {
            return existing
        }
        let created = OZTransactionOperations(kit: self)
        _transactionOperations = created
        return created
    }

    // MARK: - Manager surface

    private let managerLock = NSLock()
    private var _signerManager: OZSignerManager?
    private var _policyManager: OZPolicyManager?
    private var _multiSignerManager: OZMultiSignerManager?

    /// Test override for ``signerManager``. When set, the supplied instance is
    /// returned instead of the lazily-constructed default.
    var signerManagerOverride: OZSignerManager?

    /// Test override for ``policyManager``.
    var policyManagerOverride: OZPolicyManager?

    /// Test override for ``multiSignerManager``. Tests that need to assert
    /// invocation behaviour install a recording subclass here.
    var multiSignerManagerOverride: OZMultiSignerManager?

    /// Pre-built external-signer manager returned by ``externalSigners``.
    /// Tests that exercise the wallet or Ed25519 signing path install one here
    /// (or rely on the default manager constructed from ``config``).
    var externalSignersOverride: OZExternalSignerManager?

    /// Lazily-constructed signer manager bound to this kit. Returns the
    /// override when one is installed.
    var signerManager: OZSignerManager {
        if let override = signerManagerOverride { return override }
        managerLock.lock()
        defer { managerLock.unlock() }
        if let existing = _signerManager { return existing }
        let created = OZSignerManager(kit: self)
        _signerManager = created
        return created
    }

    /// Lazily-constructed policy manager bound to this kit.
    var policyManager: OZPolicyManager {
        if let override = policyManagerOverride { return override }
        managerLock.lock()
        defer { managerLock.unlock() }
        if let existing = _policyManager { return existing }
        let created = OZPolicyManager(kit: self)
        _policyManager = created
        return created
    }

    /// Lazily-constructed multi-signer manager bound to this kit.
    var multiSignerManager: OZMultiSignerManager {
        if let override = multiSignerManagerOverride { return override }
        managerLock.lock()
        defer { managerLock.unlock() }
        if let existing = _multiSignerManager { return existing }
        let created = OZMultiSignerManager(kit: self)
        _multiSignerManager = created
        return created
    }

    /// Kit-owned external-signer manager returned by the protocol requirement.
    ///
    /// Returns ``externalSignersOverride`` when set, otherwise lazily constructs
    /// a manager from the mock config's wallet adapter and Ed25519 adapter so
    /// tests that don't need a custom manager still satisfy the protocol.
    var externalSigners: OZExternalSignerManager {
        if let override = externalSignersOverride { return override }
        return OZExternalSignerManager(
            networkPassphrase: config.networkPassphrase,
            walletAdapter: config.externalWallet,
            ed25519Adapter: config.externalEd25519Adapter
        )
    }

    /// Connected contract identifier or `nil` when no wallet is connected.
    var contractId: String? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return connectedContractId
    }

    // MARK: - Test hooks

    /// Pre-set deployer keypair used for `getDeployer()`. When nil, a fresh
    /// random keypair is created on every call.
    var configuredDeployer: KeyPair?

    /// Underlying storage adapter (also returned by `getStorage()`).
    let storage: OZInMemoryStorageAdapter

    /// Records the last `setConnectedState` invocation so tests can assert
    /// state writes occurred.
    private(set) var setConnectedStateInvocations: [(credentialId: String, contractId: String)] = []

    // MARK: - Initialization

    init(
        config: OZSmartAccountConfig,
        sorobanServer: SorobanServer? = nil,
        relayerClient: OZRelayerClient? = nil,
        indexerClient: OZIndexerClient? = nil,
        events: OZSmartAccountEventEmitter? = nil,
        credentialManager: MockCredentialManager? = nil,
        contextRuleManager: OZContextRuleManagerProtocol? = nil
    ) {
        self.config = config
        // why: pointing at localhost with a high port that nothing listens on
        // yields an immediate connection-refused error from the local TCP
        // stack rather than waiting for the OS-level connection timeout. This
        // keeps RPC-touching tests fast (sub-second) while still exercising
        // the failure path through SorobanServer.
        self.sorobanServer = sorobanServer ?? SorobanServer(
            endpoint: "http://127.0.0.1:1"
        )
        self.relayerClient = relayerClient
        self.indexerClient = indexerClient
        self.events = events ?? OZSmartAccountEventEmitter()
        self.storage = config.storage as? OZInMemoryStorageAdapter ?? OZInMemoryStorageAdapter()
        self.credentialManager = credentialManager ?? MockCredentialManager(storage: self.storage)
        self.contextRuleManager = contextRuleManager ?? StubContextRuleManager()
    }

    func getStorage() -> OZStorageAdapter {
        return storage
    }

    func getDeployer() async throws -> KeyPair {
        if let deployer = configuredDeployer {
            return deployer
        }
        if let configured = config.deployerKeypair {
            return configured
        }
        return try await OZSmartAccountConfig.createDefaultDeployer()
    }

    func requireConnected() throws -> ConnectedState {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let credentialId = connectedCredentialId,
              let contractId = connectedContractId else {
            throw SmartAccountWalletException.notConnected(
                details: "No wallet connected"
            )
        }
        return ConnectedState(credentialId: credentialId, contractId: contractId)
    }

    func setConnectedState(credentialId: String, contractId: String) {
        stateLock.lock()
        connectedCredentialId = credentialId
        connectedContractId = contractId
        setConnectedStateInvocations.append((credentialId, contractId))
        stateLock.unlock()
    }

    // MARK: - Test helpers

    /// Returns the current connected state without throwing. Used by tests.
    var currentConnectedState: ConnectedState? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let credentialId = connectedCredentialId,
              let contractId = connectedContractId else {
            return nil
        }
        return ConnectedState(credentialId: credentialId, contractId: contractId)
    }

    var isConnected: Bool {
        return currentConnectedState != nil
    }

    /// Clears the connected state. Used by tests to model `disconnect`.
    func clearConnectedState() {
        stateLock.lock()
        connectedCredentialId = nil
        connectedContractId = nil
        stateLock.unlock()
    }
}

// ============================================================================
// MockCredentialManager
// ============================================================================

/// In-memory credential manager used by the operations-unit tests. Persists
/// credentials in the supplied ``OZInMemoryStorageAdapter`` and records the
/// most recent invocations so tests can assert call counts and arguments.
final class MockCredentialManager: OZCredentialManagerProtocol, @unchecked Sendable {

    private let storage: OZInMemoryStorageAdapter
    private let stateQueue = DispatchQueue(label: "MockCredentialManager.state")

    // Recorded invocations
    private var _createPendingCalls: [(credentialId: String, publicKey: Data, contractId: String)] = []
    private var _markDeploymentFailedCalls: [(credentialId: String, error: String)] = []
    private var _setPrimaryCalls: [String] = []
    private var _updateLastUsedCalls: [String] = []
    private var _deleteCredentialCalls: [String] = []

    // Hooks
    var throwOnCreatePending: SmartAccountException?
    var throwOnGetCredential: SmartAccountException?
    var throwOnMarkDeploymentFailed: SmartAccountException?
    var throwOnSetPrimary: SmartAccountException?
    var throwOnUpdateLastUsed: SmartAccountException?
    var throwOnDeleteCredential: SmartAccountException?

    var createPendingCalls: [(credentialId: String, publicKey: Data, contractId: String)] {
        return stateQueue.sync { _createPendingCalls }
    }
    var markDeploymentFailedCalls: [(credentialId: String, error: String)] {
        return stateQueue.sync { _markDeploymentFailedCalls }
    }
    var setPrimaryCalls: [String] {
        return stateQueue.sync { _setPrimaryCalls }
    }
    var updateLastUsedCalls: [String] {
        return stateQueue.sync { _updateLastUsedCalls }
    }
    var deleteCredentialCalls: [String] {
        return stateQueue.sync { _deleteCredentialCalls }
    }

    init(storage: OZInMemoryStorageAdapter) {
        self.storage = storage
    }

    func createPendingCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String,
        nickname: String?,
        transports: [String]?,
        deviceType: String?,
        backedUp: Bool?
    ) async throws -> OZStoredCredential {
        let hook: SmartAccountException? = stateQueue.sync {
            _createPendingCalls.append((credentialId, publicKey, contractId))
            return throwOnCreatePending
        }
        if let hook = hook { throw hook }
        let credential = OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: contractId,
            deploymentStatus: .pending,
            nickname: nickname,
            transports: transports,
            deviceType: deviceType,
            backedUp: backedUp
        )
        try await storage.save(credential: credential)
        return credential
    }

    func getCredential(credentialId: String) async throws -> OZStoredCredential? {
        if let hook = throwOnGetCredential { throw hook }
        return try await storage.get(credentialId: credentialId)
    }

    func markDeploymentFailed(credentialId: String, error: String) async throws {
        let hook: SmartAccountException? = stateQueue.sync {
            _markDeploymentFailedCalls.append((credentialId, error))
            return throwOnMarkDeploymentFailed
        }
        if let hook = hook { throw hook }
        if let existing = try await storage.get(credentialId: credentialId) {
            let updated = existing.applyUpdate(OZStoredCredentialUpdate(
                deploymentStatus: .failed,
                deploymentError: error
            ))
            try await storage.save(credential: updated)
        }
    }

    func setPrimary(credentialId: String) async throws {
        let hook: SmartAccountException? = stateQueue.sync {
            _setPrimaryCalls.append(credentialId)
            return throwOnSetPrimary
        }
        if let hook = hook { throw hook }
    }

    func updateLastUsed(credentialId: String) async throws {
        let hook: SmartAccountException? = stateQueue.sync {
            _updateLastUsedCalls.append(credentialId)
            return throwOnUpdateLastUsed
        }
        if let hook = hook { throw hook }
    }

    func deleteCredential(credentialId: String) async throws {
        let hook: SmartAccountException? = stateQueue.sync {
            _deleteCredentialCalls.append(credentialId)
            return throwOnDeleteCredential
        }
        if let hook = hook { throw hook }
        try await storage.delete(credentialId: credentialId)
    }
}

// ============================================================================
// StubContextRuleManager
// ============================================================================

/// Empty-context-rule manager used by tests that exercise the validation surface
/// of ``OZTransactionOperations``. Returns empty rule lists so the signing pass
/// (when reached) falls through to the on-chain fallback without performing
/// real RPC traffic.
final class StubContextRuleManager: OZContextRuleManagerProtocol, @unchecked Sendable {

    var listRulesResult: [OZParsedContextRule] = []
    var resolveContextRuleIdsResult: [UInt32] = []
    var getAllContextRulesResult: [SCValXDR] = []

    var throwOnListContextRules: SmartAccountException?
    var throwOnResolveContextRuleIdsForEntry: SmartAccountException?
    var throwOnGetAllContextRules: SmartAccountException?

    func listContextRules(maxScanId: UInt32? = nil) async throws -> [OZParsedContextRule] {
        if let hook = throwOnListContextRules { throw hook }
        return listRulesResult
    }

    func resolveContextRuleIdsForEntry(
        entry: SorobanAuthorizationEntryXDR,
        signers: [any OZSmartAccountSigner],
        contextRules: [OZParsedContextRule]
    ) async throws -> [UInt32] {
        if let hook = throwOnResolveContextRuleIdsForEntry { throw hook }
        return resolveContextRuleIdsResult
    }

    func getAllContextRules(maxScanId: UInt32? = nil) async throws -> [SCValXDR] {
        if let hook = throwOnGetAllContextRules { throw hook }
        return getAllContextRulesResult
    }

    // MARK: - Context-rule manager extended surface

    /// Pre-set raw rule keyed by id for ``getContextRule(id:)``.
    var getContextRuleResultsById: [UInt32: SCValXDR] = [:]

    /// Pre-set parsed rule returned by ``parseContextRule(_:)``.
    var parseContextRuleResult: OZParsedContextRule?

    /// Optional thrown error for ``getContextRule(id:)``.
    var throwOnGetContextRule: SmartAccountException?

    /// Optional thrown error for ``parseContextRule(_:)``.
    var throwOnParseContextRule: SmartAccountException?

    /// Records every call to ``getContextRule(id:)`` so tests can assert the
    /// stub was consulted.
    private(set) var getContextRuleCalls: [UInt32] = []

    /// Counts every invocation of ``parseContextRule(_:)``.
    private(set) var parseContextRuleCalls: Int = 0

    func getContextRule(id: UInt32) async throws -> SCValXDR {
        getContextRuleCalls.append(id)
        if let hook = throwOnGetContextRule { throw hook }
        if let value = getContextRuleResultsById[id] { return value }
        return SCValXDR.void
    }

    func parseContextRule(_ scVal: SCValXDR) throws -> OZParsedContextRule {
        parseContextRuleCalls += 1
        if let hook = throwOnParseContextRule { throw hook }
        if let value = parseContextRuleResult { return value }
        throw SmartAccountValidationException.invalidInput(
            field: "scVal",
            reason: "Stub holds no parsed rule"
        )
    }
}
