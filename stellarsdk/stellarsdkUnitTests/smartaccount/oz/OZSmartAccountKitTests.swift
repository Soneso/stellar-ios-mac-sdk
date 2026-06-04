//
//  OZSmartAccountKitTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Thread-safe reference-typed recorder used by tests that capture event
/// payloads or state observations from closures crossing concurrency
/// boundaries.
private final class TestRecorder<Element>: @unchecked Sendable {
    private let recorderLock = NSLock()
    private var _items: [Element] = []

    func append(_ element: Element) {
        recorderLock.lock()
        _items.append(element)
        recorderLock.unlock()
    }

    var items: [Element] {
        recorderLock.lock()
        defer { recorderLock.unlock() }
        return _items
    }

    var count: Int {
        recorderLock.lock()
        defer { recorderLock.unlock() }
        return _items.count
    }
}

/// Thread-safe reference-typed counter for tests asserting invocation
/// counts of closures crossing concurrency boundaries.
private final class TestCounter: @unchecked Sendable {
    private let counterLock = NSLock()
    private var _value: Int = 0

    func increment() {
        counterLock.lock()
        _value += 1
        counterLock.unlock()
    }

    var value: Int {
        counterLock.lock()
        defer { counterLock.unlock() }
        return _value
    }
}

/// Thread-safe optional holder for tests capturing single optional
/// observations from closures crossing concurrency boundaries.
private final class TestHolder<Element>: @unchecked Sendable {
    private let holderLock = NSLock()
    private var _value: Element? = nil

    func set(_ value: Element?) {
        holderLock.lock()
        _value = value
        holderLock.unlock()
    }

    var value: Element? {
        holderLock.lock()
        defer { holderLock.unlock() }
        return _value
    }
}

final class OZSmartAccountKitTests: XCTestCase {

    // MARK: - Test fixtures

    private let validRpcUrl = "https://soroban-testnet.stellar.org"
    private let validPassphrase = Network.testnet.passphrase
    private let validWasmHash = "a" + String(repeating: "0", count: 63)
    private let validVerifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let testCredentialId = "test-credential-id"
    private let testContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    private func makeConfig(
        rpcUrl: String? = nil,
        networkPassphrase: String? = nil,
        accountWasmHash: String? = nil,
        webauthnVerifierAddress: String? = nil,
        storage: OZStorageAdapter? = nil,
        relayerUrl: String? = nil,
        indexerUrl: String? = nil,
        deployerKeypair: KeyPair? = nil,
        externalWallet: OZExternalWalletAdapter? = nil
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: rpcUrl ?? validRpcUrl,
            networkPassphrase: networkPassphrase ?? validPassphrase,
            accountWasmHash: accountWasmHash ?? validWasmHash,
            webauthnVerifierAddress: webauthnVerifierAddress ?? validVerifier,
            deployerKeypair: deployerKeypair,
            relayerUrl: relayerUrl,
            indexerUrl: indexerUrl,
            storage: storage ?? OZInMemoryStorageAdapter(),
            externalWallet: externalWallet
        )
    }

    // ========================================================================
    // MARK: - Kit initialization
    // ========================================================================

    func testKitInitialization_validConfig() throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertFalse(kit.isConnected)
        XCTAssertNil(kit.credentialId)
        XCTAssertNil(kit.contractId)
        XCTAssertNotNil(kit.events)
        XCTAssertNotNil(kit.sorobanServer)
        XCTAssertNotNil(kit.walletOperations)
        XCTAssertNotNil(kit.transactionOperations)
        XCTAssertNotNil(kit.signerManager)
        XCTAssertNotNil(kit.policyManager)
        XCTAssertNotNil(kit.multiSignerManager)
        XCTAssertNotNil(kit.contextRuleManagerConcrete)
        XCTAssertNotNil(kit.credentialManagerConcrete)
        XCTAssertNotNil(kit.externalSigners)
    }

    func test_externalSigners_isNonNilByDefault() throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)
        XCTAssertNotNil(
            kit.externalSigners,
            "externalSigners must be non-nil even when no adapters are supplied via config"
        )
    }

    func test_externalSigners_kitOwnedManagerUsesConfigAdapters() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
        let kit = OZSmartAccountKit.create(config: config)
        XCTAssertNotNil(
            kit.externalSigners,
            "externalSigners must be the kit-owned manager constructed from config"
        )
    }

    func testKitInitialization_missingRpcUrl() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: "",
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.MissingConfig)
        }
    }

    func testKitInitialization_missingNetworkPassphrase() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: "",
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.MissingConfig)
        }
    }

    func testKitInitialization_missingAccountWasmHash() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: "",
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.MissingConfig)
        }
    }

    func testKitInitialization_invalidWebauthnVerifierAddress_wrongPrefix() {
        let badAddress = "G" + String(repeating: "A", count: 55)
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: badAddress
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testKitInitialization_invalidWebauthnVerifierAddress_wrongLength() {
        let badAddress = "C" + String(repeating: "A", count: 12)
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: badAddress
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testKitInitialization_customStorageAdapter() throws {
        let customStorage = OZInMemoryStorageAdapter()
        let config = try makeConfig(storage: customStorage)
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertTrue(kit.getStorage() === customStorage)
    }

    func testKitInitialization_withRelayer() throws {
        let config = try makeConfig(relayerUrl: "https://relayer.example.test")
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertNotNil(kit.relayerClient)
    }

    func testKitInitialization_withIndexer() throws {
        let config = try makeConfig(indexerUrl: "https://indexer.example.test")
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertNotNil(kit.indexerClient)
    }

    func testKitInitialization_indexerDefaultsToNetworkUrl() throws {
        // why: the configuration does not specify an indexer URL but the
        // testnet network passphrase has a built-in default URL in
        // `OZIndexerClient.defaultIndexerUrls`, so the kit constructs an
        // indexer client from that default.
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertNotNil(kit.indexerClient)
    }

    // ========================================================================
    // MARK: - Close lifecycle
    // ========================================================================

    func testClose_canBeCalledOnFreshKit() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        await kit.close()
        // No throw expected; reaching this line is the assertion.
    }

    func testClose_canBeCalledTwice() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        await kit.close()
        await kit.close()
        // No throw expected; the close-flag guard short-circuits the
        // second invocation.
    }

    func testClose_withIndexerClient() async throws {
        let config = try makeConfig(indexerUrl: "https://indexer.example.test")
        let mockIndexer = try MockOZIndexerClient()
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: SorobanServer(endpoint: config.rpcUrl),
            relayerClient: nil,
            indexerClient: mockIndexer
        )

        await kit.close()

        XCTAssertEqual(mockIndexer.closeCallCount, 1)
    }

    func testClose_withoutIndexerClient() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: SorobanServer(endpoint: config.rpcUrl),
            relayerClient: nil,
            indexerClient: nil
        )

        await kit.close()
        // No throw expected; the optional-chain on `indexerClient` short
        // circuits when no indexer client is configured.
    }

    // ========================================================================
    // MARK: - Disconnect + requireConnected
    // ========================================================================

    func testKitDisconnect() async throws {
        let storage = OZInMemoryStorageAdapter()
        let config = try makeConfig(storage: storage)
        let kit = OZSmartAccountKit.create(config: config)

        let session = OZStoredSession(
            credentialId: testCredentialId,
            contractId: testContractId,
            connectedAt: 1_700_000_000_000,
            expiresAt: .max
        )
        try await storage.saveSession(session)

        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)
        XCTAssertTrue(kit.isConnected)

        let recorder = TestRecorder<OZSmartAccountEvent>()
        kit.events.on(.walletDisconnected) { event in
            recorder.append(event)
        }

        try await kit.disconnect()

        XCTAssertFalse(kit.isConnected)
        XCTAssertNil(kit.credentialId)
        XCTAssertNil(kit.contractId)
        let storedSession = try await storage.getSession()
        XCTAssertNil(storedSession)
        XCTAssertEqual(recorder.count, 1)
        if case .walletDisconnected(let cId) = recorder.items.first ?? .walletDisconnected(contractId: "") {
            XCTAssertEqual(cId, testContractId)
        } else {
            XCTFail("Expected walletDisconnected event")
        }
    }

    func testKitDisconnect_whenNotConnected_doesNotEmit() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let recorder = TestRecorder<OZSmartAccountEvent>()
        kit.events.on(.walletDisconnected) { event in
            recorder.append(event)
        }

        try await kit.disconnect()

        XCTAssertEqual(recorder.count, 0)
        XCTAssertFalse(kit.isConnected)
    }

    func testKitRequireConnected_notConnected() throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertThrowsError(try kit.requireConnected()) { error in
            XCTAssertTrue(error is SmartAccountWalletException.NotConnected)
            let walletError = error as? SmartAccountWalletException.NotConnected
            XCTAssertEqual(
                walletError?.message,
                "No wallet connected. Call createWallet() or connectWallet() first."
            )
        }
    }

    func testKitRequireConnected_connected() throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)

        let state = try kit.requireConnected()
        XCTAssertEqual(state.credentialId, testCredentialId)
        XCTAssertEqual(state.contractId, testContractId)
    }

    // ========================================================================
    // MARK: - Default deployer
    // ========================================================================

    func testDefaultDeployer() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let first = try await kit.getDeployer()
        let second = try await kit.getDeployer()

        XCTAssertEqual(first.accountId, second.accountId)

        let expected = try await OZSmartAccountConfig.createDefaultDeployer()
        XCTAssertEqual(first.accountId, expected.accountId)
    }

    func testGetDeployer_returnsCachedKeyPairAcrossCalls() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let first = try await kit.getDeployer()
        let second = try await kit.getDeployer()

        // why: the cache stores the same `KeyPair` reference, so successive
        // calls return identity-equal instances.
        XCTAssertTrue(first === second)
    }

    func testGetDeployer_returnsConfiguredKeyPair() async throws {
        let configuredDeployer = try KeyPair.generateRandomKeyPair()
        let config = try makeConfig(deployerKeypair: configuredDeployer)
        let kit = OZSmartAccountKit.create(config: config)

        let deployer = try await kit.getDeployer()
        XCTAssertEqual(deployer.accountId, configuredDeployer.accountId)
    }

    // ========================================================================
    // MARK: - Additional kit invariants (factory, transitions,
    // close-releases, identity preservation, concurrency, memory)
    // ========================================================================

    // E1: Factory invalid-config rejection — covered by Kit initialization error tests.

    // E2: State transitions
    func testStateTransitions_connectThenDisconnect() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertFalse(kit.isConnected)
        XCTAssertNil(kit.credentialId)
        XCTAssertNil(kit.contractId)

        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)
        XCTAssertTrue(kit.isConnected)
        XCTAssertEqual(kit.credentialId, testCredentialId)
        XCTAssertEqual(kit.contractId, testContractId)

        try await kit.disconnect()
        XCTAssertFalse(kit.isConnected)
        XCTAssertNil(kit.credentialId)
        XCTAssertNil(kit.contractId)
    }

    func testStateTransitions_disconnectEventReflectsClearedStateAtListenerTime() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)
        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)

        let observedIsConnected = TestHolder<Bool>()
        let observedCredentialId = TestHolder<String>()
        let observedContractId = TestHolder<String>()
        kit.events.on(.walletDisconnected) { [weak kit] _ in
            // why: the listener fires AFTER the lock-release-before-await
            // ordering. The kit must already be in a fully disconnected
            // state when the listener observes it.
            observedIsConnected.set(kit?.isConnected)
            observedCredentialId.set(kit?.credentialId)
            observedContractId.set(kit?.contractId)
        }

        try await kit.disconnect()

        XCTAssertEqual(observedIsConnected.value, false)
        XCTAssertNil(observedCredentialId.value)
        XCTAssertNil(observedContractId.value)
    }

    // E3: Close releases resources
    func testCloseReleasesResources_indexerAndRelayer() async throws {
        let config = try makeConfig(
            relayerUrl: "https://relayer.example.test",
            indexerUrl: "https://indexer.example.test"
        )
        let mockIndexer = try MockOZIndexerClient()
        let mockRelayer = try MockOZRelayerClient()
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: SorobanServer(endpoint: config.rpcUrl),
            relayerClient: mockRelayer,
            indexerClient: mockIndexer
        )

        await kit.close()

        XCTAssertEqual(mockIndexer.closeCallCount, 1)
        XCTAssertEqual(mockRelayer.closeCallCount, 1)
    }

    func testCloseReleasesResources_removesAllEventListeners() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let counter = TestCounter()
        kit.events.on(.walletDisconnected) { _ in
            counter.increment()
        }

        XCTAssertEqual(kit.events.listenerCount(eventType: "WalletDisconnected"), 1)

        await kit.close()

        XCTAssertEqual(kit.events.listenerCount(eventType: "WalletDisconnected"), 0)

        // Sanity check: emitting an event after close fires no listeners.
        kit.events.emit(.walletDisconnected(contractId: testContractId))
        XCTAssertEqual(counter.value, 0)
    }

    func testCloseReleasesResources_idempotentAcrossDoubleCall() async throws {
        let config = try makeConfig()
        let mockIndexer = try MockOZIndexerClient()
        let mockRelayer = try MockOZRelayerClient()
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: SorobanServer(endpoint: config.rpcUrl),
            relayerClient: mockRelayer,
            indexerClient: mockIndexer
        )

        await kit.close()
        await kit.close()
        await kit.close()

        XCTAssertEqual(mockIndexer.closeCallCount, 1)
        XCTAssertEqual(mockRelayer.closeCallCount, 1)
    }

    // E4: Manager identity preservation
    func testManagerIdentityPreservation() throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        XCTAssertTrue(kit.walletOperations === kit.walletOperations)
        XCTAssertTrue(kit.transactionOperations === kit.transactionOperations)
        XCTAssertTrue(kit.signerManager === kit.signerManager)
        XCTAssertTrue(kit.policyManager === kit.policyManager)
        XCTAssertTrue(kit.multiSignerManager === kit.multiSignerManager)
        XCTAssertTrue(kit.contextRuleManagerConcrete === kit.contextRuleManagerConcrete)
        XCTAssertTrue(kit.credentialManagerConcrete === kit.credentialManagerConcrete)
        XCTAssertTrue(kit.events === kit.events)
    }

    func testManagerStorageIdentityPreservation_kitStorageMatchesConfigStorage() throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let kitStorage = kit.getStorage()
        XCTAssertTrue(kitStorage === config.storage)
    }

    // E5a: Concurrency stress — parallel setConnectedState + requireConnected
    func testConcurrencyStress_parallelSetConnectedStateAndRequireConnected() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        // why: 10 parallel writers + 10 parallel readers exercise the state
        // lock under contention. The test asserts liveness within 30
        // seconds; a deadlock manifests as the task group never completing.
        let totalIterations = 10
        let writeContractId = testContractId
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<totalIterations {
                group.addTask { [weak kit] in
                    kit?.setConnectedState(
                        credentialId: "cred-\(i)",
                        contractId: writeContractId
                    )
                }
                group.addTask { [weak kit] in
                    _ = try? kit?.requireConnected()
                }
            }
            await group.waitForAll()
        }

        XCTAssertTrue(kit.isConnected)
    }

    func testConcurrencyStress_parallelGetDeployerReturnsIdenticalKeyPair() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let parallelism = 10
        let results = await withTaskGroup(of: KeyPair?.self, returning: [KeyPair].self) { group in
            for _ in 0..<parallelism {
                group.addTask { [weak kit] in
                    return try? await kit?.getDeployer()
                }
            }
            var collected: [KeyPair] = []
            for await result in group {
                if let kp = result {
                    collected.append(kp)
                }
            }
            return collected
        }

        XCTAssertEqual(results.count, parallelism)
        let accountIds = results.map { $0.accountId }
        XCTAssertEqual(Set(accountIds).count, 1, "All parallel callers must observe the same default deployer accountId")
    }

    // E5b: Per-instance WeakReference deallocation test
    func testKitDeallocatesAfterClose_weakReferenceGoesToNil() async throws {
        weak var weakKit: OZSmartAccountKit? = nil
        do {
            // Local scope so the strong reference can drop when the scope
            // ends.
            let config = try makeConfig()
            let kit = OZSmartAccountKit.create(config: config)
            weakKit = kit
            await kit.close()
        }

        // why: ARC reclaims the kit only when every strong reference has
        // been released. The eager-init managers each hold a strong
        // reference back to the kit through the protocol; `close()`
        // nulls out the kit's strong references to the managers,
        // breaking the cycle, so the weak reference becomes nil once
        // the local strong reference is released.
        XCTAssertNil(weakKit)
    }

    // E5c: Per-cycle behavioral test — 10 open-close cycles
    func testPerCycleCloseBehavior_tenCyclesEachInvokeMockClientsExactlyOnce() async throws {
        let config = try makeConfig()
        let cycleCount = 10

        var totalIndexerCloses = 0
        var totalRelayerCloses = 0
        for _ in 0..<cycleCount {
            let mockIndexer = try MockOZIndexerClient()
            let mockRelayer = try MockOZRelayerClient()
            let kit = OZSmartAccountKit(
                config: config,
                storage: OZInMemoryStorageAdapter(),
                sorobanServer: SorobanServer(endpoint: config.rpcUrl),
                relayerClient: mockRelayer,
                indexerClient: mockIndexer
            )
            await kit.close()
            totalIndexerCloses += mockIndexer.closeCallCount
            totalRelayerCloses += mockRelayer.closeCallCount
        }

        XCTAssertEqual(totalIndexerCloses, cycleCount)
        XCTAssertEqual(totalRelayerCloses, cycleCount)
    }

    // ========================================================================
    // MARK: - Events directly invoking kit
    // ========================================================================

    func testEvents_typeSafeSubscription() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)
        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)

        let recorder = TestRecorder<String>()
        kit.events.on(.walletDisconnected) { event in
            if case .walletDisconnected(let cId) = event {
                recorder.append(cId)
            }
        }

        try await kit.disconnect()

        XCTAssertEqual(recorder.items, [testContractId])
    }

    func testEvents_onceListener() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let counter = TestCounter()
        kit.events.once(.walletDisconnected) { _ in
            counter.increment()
        }

        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)
        try await kit.disconnect()
        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)
        try await kit.disconnect()

        XCTAssertEqual(counter.value, 1)
    }

    func testEvents_removeAllListeners() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)

        let counter = TestCounter()
        kit.events.on(.walletDisconnected) { _ in
            counter.increment()
        }

        kit.events.removeAllListeners()
        kit.setConnectedState(credentialId: testCredentialId, contractId: testContractId)
        try await kit.disconnect()

        XCTAssertEqual(counter.value, 0)
    }

    // MARK: - Protocol-typed accessor coverage

    /// Accessing `credentialManager`, `contextRuleManager`, and
    /// `externalSigners` through the `OZSmartAccountKitProtocol` interface
    /// verifies the internal computed-property forwarding paths.
    func test_protocolAccessors_credentialManagerAndExternalSigners_areAccessible() async throws {
        let config = try makeConfig()
        let kit = OZSmartAccountKit.create(config: config)
        let protocol_kit: OZSmartAccountKitProtocol = kit
        XCTAssertNotNil(protocol_kit.credentialManager)
        XCTAssertNotNil(protocol_kit.contextRuleManager)
        XCTAssertNotNil(protocol_kit.externalSigners)
        await kit.close()
    }
}
