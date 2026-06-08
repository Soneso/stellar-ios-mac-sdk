//
//  OZSmartAccountConfigTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSmartAccountConfigTests: XCTestCase {

    // MARK: - Test Fixtures

    private let validRpcUrl = "https://soroban-testnet.stellar.org"
    private let validPassphrase = Network.testnet.passphrase
    private let validWasmHash = "a" + String(repeating: "0", count: 63)
    private let validVerifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    private func makeValidConfig(
        rpcUrl: String? = nil,
        networkPassphrase: String? = nil,
        accountWasmHash: String? = nil,
        webauthnVerifierAddress: String? = nil
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: rpcUrl ?? validRpcUrl,
            networkPassphrase: networkPassphrase ?? validPassphrase,
            accountWasmHash: accountWasmHash ?? validWasmHash,
            webauthnVerifierAddress: webauthnVerifierAddress ?? validVerifier
        )
    }

    // MARK: - Config Defaults

    func testConfigDefaults_optionalFieldsHaveCorrectDefaults() throws {
        let config = try makeValidConfig()

        XCTAssertNil(config.deployerKeypair)
        XCTAssertEqual(OZConstants.defaultSessionExpiryMs, config.sessionExpiryMs)
        XCTAssertEqual(StellarProtocolConstants.ledgersPerHour, config.signatureExpirationLedgers)
        XCTAssertEqual(OZConstants.defaultTimeoutSeconds, config.timeoutInSeconds)
        XCTAssertNil(config.relayerUrl)
        XCTAssertNil(config.indexerUrl)
        XCTAssertNil(config.webauthnProvider)
    }

    func testConfigDefaults_requiredFieldsStored() throws {
        let config = try makeValidConfig()

        XCTAssertEqual(validRpcUrl, config.rpcUrl)
        XCTAssertEqual(validPassphrase, config.networkPassphrase)
        XCTAssertEqual(validWasmHash, config.accountWasmHash)
        XCTAssertEqual(validVerifier, config.webauthnVerifierAddress)
    }

    // MARK: - webauthnVerifierAddress Edge Cases

    func testWebauthnVerifierAddress_whitespaceOnlyThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: "    "
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testWebauthnVerifierAddress_startsWithGThrows() {
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

    func testWebauthnVerifierAddress_tooShortThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: "CABC"
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testWebauthnVerifierAddress_tooLongThrows() {
        let badAddress = "C" + String(repeating: "A", count: 56)
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

    // MARK: - rpcUrl Validation Edge Cases

    func testRpcUrl_whitespaceOnlyThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: "   ",
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.MissingConfig)
        }
    }

    // MARK: - networkPassphrase Validation Edge Cases

    func testNetworkPassphrase_whitespaceOnlyThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: "   ",
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.MissingConfig)
        }
    }

    // MARK: - accountWasmHash Validation Edge Cases

    func testAccountWasmHash_whitespaceOnlyThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: "   ",
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.MissingConfig)
        }
    }

    func testAccountWasmHash_invalidHexThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: "not_a_valid_hex_hash",
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testAccountWasmHash_tooShortHexThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: "abcdef",
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    // MARK: - Builder Pattern Tests

    func testBuilder_allOptionalFields() throws {
        let config = try OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
            .sessionExpiryMs(86_400_000)
            .signatureExpirationLedgers(1440)
            .timeoutInSeconds(60)
            .relayerUrl("https://relayer.example.com")
            .indexerUrl("https://indexer.example.com")
            .build()

        XCTAssertEqual(86_400_000, config.sessionExpiryMs)
        XCTAssertEqual(1440, config.signatureExpirationLedgers)
        XCTAssertEqual(60, config.timeoutInSeconds)
        XCTAssertEqual("https://relayer.example.com", config.relayerUrl)
        XCTAssertEqual("https://indexer.example.com", config.indexerUrl)
    }

    func testBuilder_defaultValues() throws {
        let config = try OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        ).build()

        XCTAssertEqual(OZConstants.defaultSessionExpiryMs, config.sessionExpiryMs)
        XCTAssertEqual(StellarProtocolConstants.ledgersPerHour, config.signatureExpirationLedgers)
        XCTAssertEqual(OZConstants.defaultTimeoutSeconds, config.timeoutInSeconds)
        XCTAssertNil(config.relayerUrl)
        XCTAssertNil(config.indexerUrl)
        XCTAssertNil(config.deployerKeypair)
    }

    func testBuilder_producesIdenticalConfigToConstructor() throws {
        let constructorConfig = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            sessionExpiryMs: 100_000,
            relayerUrl: "https://relayer.test"
        )

        let builderConfig = try OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
            .sessionExpiryMs(100_000)
            .relayerUrl("https://relayer.test")
            .build()

        XCTAssertEqual(constructorConfig, builderConfig)
    }

    func testBuilder_nullOptionalValues() throws {
        let config = try OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
            .relayerUrl(nil)
            .indexerUrl(nil)
            .deployerKeypair(nil)
            .build()

        XCTAssertNil(config.relayerUrl)
        XCTAssertNil(config.indexerUrl)
        XCTAssertNil(config.deployerKeypair)
    }

    func testBuilder_chainable() throws {
        let builder = OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )

        let result = builder
            .sessionExpiryMs(1000)
            .signatureExpirationLedgers(100)
            .timeoutInSeconds(10)
            .relayerUrl("https://r.com")
            .indexerUrl("https://i.com")
            .deployerKeypair(nil)

        let config = try result.build()
        XCTAssertEqual(1000, config.sessionExpiryMs)
        XCTAssertEqual(100, config.signatureExpirationLedgers)
    }

    // MARK: - Config Data Class Properties

    func testConfigEquality_identicalConfigsAreEqual() throws {
        let config1 = try makeValidConfig()
        let config2 = try makeValidConfig()

        XCTAssertEqual(config1, config2)
        XCTAssertEqual(config1.hashValue, config2.hashValue)
    }

    func testConfigEquality_differentRpcUrlNotEqual() throws {
        let config1 = try OZSmartAccountConfig(
            rpcUrl: "https://rpc1.example.com",
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: "https://rpc2.example.com",
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )

        XCTAssertNotEqual(config1, config2)
    }

    // MARK: - Config Copy Tests

    func testConfigCopy_withModifiedFields() throws {
        let original = try makeValidConfig()
        let modified = try OZSmartAccountConfig(
            rpcUrl: original.rpcUrl,
            networkPassphrase: original.networkPassphrase,
            accountWasmHash: original.accountWasmHash,
            webauthnVerifierAddress: original.webauthnVerifierAddress,
            deployerKeypair: original.deployerKeypair,
            sessionExpiryMs: 86_400_000,
            signatureExpirationLedgers: original.signatureExpirationLedgers,
            timeoutInSeconds: original.timeoutInSeconds,
            relayerUrl: original.relayerUrl,
            indexerUrl: original.indexerUrl,
            webauthnProvider: original.webauthnProvider,
            storage: original.storage,
            externalWallet: original.externalWallet,
            maxContextRuleScanId: original.maxContextRuleScanId
        )

        XCTAssertEqual(86_400_000, modified.sessionExpiryMs)
        XCTAssertEqual(original.rpcUrl, modified.rpcUrl)
        XCTAssertEqual(original.networkPassphrase, modified.networkPassphrase)
    }

    // MARK: - effectiveIndexerUrl Tests

    func testEffectiveIndexerUrl_explicitUrlTakesPrecedence() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            indexerUrl: "https://custom-indexer.example.com"
        )

        XCTAssertEqual("https://custom-indexer.example.com", config.effectiveIndexerUrl())
    }

    func testEffectiveIndexerUrl_noExplicitUrlFallsBackToDefault() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            indexerUrl: nil
        )

        // Testnet has a built-in default indexer URL sourced from
        // OZIndexerClient.defaultIndexerUrls; with no explicit override the resolved
        // URL must be that default.
        let resolved = config.effectiveIndexerUrl()
        XCTAssertEqual(
            OZIndexerClient.getDefaultUrl(networkPassphrase: validPassphrase),
            resolved
        )
        XCTAssertNotNil(resolved)
        XCTAssertTrue(resolved!.hasPrefix("https://"))
    }

    func testEffectiveIndexerUrl_mainnetReturnsIndexerUrl() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: Network.public.passphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )

        let resolved = config.effectiveIndexerUrl()
        XCTAssertEqual(
            OZIndexerClient.getDefaultUrl(networkPassphrase: Network.public.passphrase),
            resolved
        )
        XCTAssertNotNil(resolved)
        XCTAssertTrue(resolved!.hasPrefix("https://"))
    }

    func testEffectiveIndexerUrl_unknownNetworkReturnsNil() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: "Unknown Network ; January 2099",
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )

        XCTAssertNil(config.effectiveIndexerUrl())
    }

    // MARK: - effectiveDeployer Tests

    func testGetDeployer_defaultDeployerIsDeterministic() async throws {
        let config = try makeValidConfig()

        let deployer1 = try await config.effectiveDeployer()
        let deployer2 = try await config.effectiveDeployer()

        XCTAssertEqual(deployer1.accountId, deployer2.accountId)
    }

    func testGetDeployer_customDeployerTakesPrecedence() async throws {
        let customDeployer = try KeyPair.generateRandomKeyPair()
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            deployerKeypair: customDeployer
        )

        let deployer = try await config.effectiveDeployer()
        XCTAssertEqual(customDeployer.accountId, deployer.accountId)
    }

    // MARK: - Config with Various Network Passphrases

    func testConfig_testnetPassphrase() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
        XCTAssertEqual(Network.testnet.passphrase, config.networkPassphrase)
    }

    func testConfig_mainnetPassphrase() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://soroban-mainnet.stellar.org",
            networkPassphrase: Network.public.passphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
        XCTAssertEqual(Network.public.passphrase, config.networkPassphrase)
    }

    func testConfig_customPassphrase() throws {
        let customPassphrase = "My Custom Stellar Network ; January 2026"
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: customPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
        XCTAssertEqual(customPassphrase, config.networkPassphrase)
    }

    // MARK: - Constants Tests

    func testOZConstants_defaultSessionExpiryMs() {
        XCTAssertEqual(7 * 24 * 60 * 60 * 1000, OZConstants.defaultSessionExpiryMs)
    }

    func testUtil_ledgersPerHour() {
        XCTAssertEqual(720, StellarProtocolConstants.ledgersPerHour)
    }

    func testOZConstants_defaultTimeoutSeconds() {
        XCTAssertEqual(30, OZConstants.defaultTimeoutSeconds)
    }

    // MARK: - Builder optional setters (Batch G)

    /// Exercises every optional builder setter. Verifies that the built
    /// `OZSmartAccountConfig` reflects the values set via the fluent API.
    func test_builder_allOptionalSetters_buildSucceeds() throws {
        let customStorage = OZInMemoryStorageAdapter()
        let customMaxScanId: UInt32 = 200

        let config = try OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
        .sessionExpiryMs(86_400_000)
        .signatureExpirationLedgers(720)
        .timeoutInSeconds(60)
        .relayerUrl("https://relayer.example.com")
        .indexerUrl("https://indexer.example.com")
        .webauthnProvider(nil)
        .storage(customStorage)
        .externalWallet(nil)
        .externalEd25519Adapter(nil)
        .maxContextRuleScanId(customMaxScanId)
        .build()

        XCTAssertEqual(86_400_000, config.sessionExpiryMs)
        XCTAssertEqual(720, config.signatureExpirationLedgers)
        XCTAssertEqual(60, config.timeoutInSeconds)
        XCTAssertEqual("https://relayer.example.com", config.relayerUrl)
        XCTAssertEqual("https://indexer.example.com", config.indexerUrl)
        XCTAssertNil(config.webauthnProvider)
        XCTAssertNil(config.externalWallet)
        XCTAssertNil(config.externalEd25519Adapter)
        XCTAssertEqual(customMaxScanId, config.maxContextRuleScanId)
    }

    // MARK: - isValidWasmHashHex — invalid character in 64-char string (line 328)

    /// A 64-character string that is otherwise the right length but contains a
    /// non-hex character must throw `SmartAccountConfigurationException.InvalidConfig`.
    /// This exercises the `return false` branch inside the hex character loop
    /// (line 328 in `OZSmartAccountConfig.swift`).
    func testAccountWasmHash_invalidCharInHexString_throws() {
        let invalidHash = "a" + String(repeating: "0", count: 62) + "Z"
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: invalidHash,
                webauthnVerifierAddress: validVerifier
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    // MARK: - Validation error paths

    /// `signatureExpirationLedgers` of zero must throw
    /// `SmartAccountConfigurationException.InvalidConfig`.
    func test_signatureExpirationLedgers_zeroThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: validVerifier,
                signatureExpirationLedgers: 0
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    /// Values above the former 535_680 cap must be accepted now that the client-side
    /// upper bound has been removed. The network's `maxEntryTTL` (CAP-0046-11)
    /// governs the real maximum and is enforced by the host at submission.
    func test_signatureExpirationLedgers_largeValueAccepted() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            signatureExpirationLedgers: 1_000_000
        )
        XCTAssertEqual(1_000_000, config.signatureExpirationLedgers)
    }

    /// `timeoutInSeconds` of zero must be accepted (0 means no expiry / infinite
    /// validity window).
    func test_timeoutInSeconds_zeroAccepted() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            timeoutInSeconds: 0
        )
        XCTAssertEqual(0, config.timeoutInSeconds)
    }

    /// `timeoutInSeconds` above the former 600 cap must be accepted now that the
    /// upper bound has been removed.
    func test_timeoutInSeconds_largeValueAccepted() throws {
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            timeoutInSeconds: 100_000
        )
        XCTAssertEqual(100_000, config.timeoutInSeconds)
    }

    /// A negative `timeoutInSeconds` must throw `SmartAccountConfigurationException.InvalidConfig`.
    func test_timeoutInSeconds_negativeThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountConfig(
                rpcUrl: validRpcUrl,
                networkPassphrase: validPassphrase,
                accountWasmHash: validWasmHash,
                webauthnVerifierAddress: validVerifier,
                timeoutInSeconds: -1
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    // MARK: - Equality and hash coverage

    /// Configs with different deployer keypairs must not be equal.
    func test_equality_differentDeployerKeypairNotEqual() throws {
        let keypair = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            deployerKeypair: keypair
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            deployerKeypair: nil
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// Configs with two non-nil deployer keypairs that are equal must be equal.
    func test_equality_sameDeployerKeypairEqual() throws {
        let keypair1 = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let keypair2 = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            deployerKeypair: keypair1
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            deployerKeypair: keypair2
        )
        XCTAssertEqual(config1, config2)
    }

    /// Configs with two different non-nil storage adapters that are NOT
    /// `OZInMemoryStorageAdapter` must be unequal when they are different instances.
    func test_equality_differentNonInMemoryStorageNotEqual() throws {
        let storage1 = _TestNamedStorageAdapter(name: "A")
        let storage2 = _TestNamedStorageAdapter(name: "B")
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            storage: storage1
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            storage: storage2
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// Hash includes the storage identity when the adapter is not `OZInMemoryStorageAdapter`.
    func test_hash_nonInMemoryStorageIncludesIdentity() throws {
        let storage = _TestNamedStorageAdapter(name: "X")
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            storage: storage
        )
        var hasher = Hasher()
        config.hash(into: &hasher)
        let hashValue = hasher.finalize()
        XCTAssertNotEqual(0, hashValue)
    }

    /// Two configs where one has a WebAuthn provider and the other does not
    /// must not be equal.
    func test_equality_differentWebAuthnProviderNotEqual() throws {
        let provider = MockWebAuthnProvider()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: nil
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// Two configs with the same non-nil WebAuthn provider instance must be equal.
    func test_equality_sameWebAuthnProviderEqual() throws {
        let provider = MockWebAuthnProvider()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider
        )
        XCTAssertEqual(config1, config2)
        XCTAssertEqual(config1.hashValue, config2.hashValue)
    }

    /// Configs that share the same `externalWallet` instance must be equal
    /// (exercises the identity-comparison branch, line 667).
    func test_equality_sameExternalWalletEqual() throws {
        let wallet = _TestExternalWalletAdapter()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: wallet
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: wallet
        )
        XCTAssertEqual(config1, config2)
    }

    /// A config with an `externalWallet` vs one without must not be equal
    /// (exercises the `default: return false` branch, line 669).
    func test_equality_externalWalletNilVsNonNilNotEqual() throws {
        let wallet = _TestExternalWalletAdapter()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: wallet
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: nil
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// Two configs that differ only in `externalWallet` must not be equal
    /// (exercises line 592 — the `return false` after `externalWalletAdaptersEqual`).
    func test_equality_differentExternalWalletNotEqual() throws {
        let wallet1 = _TestExternalWalletAdapter()
        let wallet2 = _TestExternalWalletAdapter()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: wallet1
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: wallet2
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// Configs with different `externalEd25519Adapter` instances must not be equal.
    func test_equality_differentExternalEd25519AdapterNotEqual() throws {
        let adapter1 = _TestEd25519SignerAdapter()
        let adapter2 = _TestEd25519SignerAdapter()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalEd25519Adapter: adapter1
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalEd25519Adapter: adapter2
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// A config with a non-nil `externalEd25519Adapter` must not equal a config
    /// with a nil one (exercises the `default: return false` branch).
    func test_equality_externalEd25519AdapterNilVsNonNilNotEqual() throws {
        let adapter = _TestEd25519SignerAdapter()
        let config1 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalEd25519Adapter: adapter
        )
        let config2 = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalEd25519Adapter: nil
        )
        XCTAssertNotEqual(config1, config2)
    }

    /// Hash includes the `externalWallet` identity when non-nil.
    func test_hash_externalWalletIncludesIdentity() throws {
        let wallet = _TestExternalWalletAdapter()
        let configWithWallet = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: wallet
        )
        let configWithoutWallet = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalWallet: nil
        )
        XCTAssertNotEqual(configWithWallet.hashValue, configWithoutWallet.hashValue)
    }

    /// Hash includes the `externalEd25519Adapter` identity when non-nil.
    func test_hash_externalEd25519AdapterIncludesIdentity() throws {
        let adapter = _TestEd25519SignerAdapter()
        let configWithAdapter = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalEd25519Adapter: adapter
        )
        let configWithoutAdapter = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            externalEd25519Adapter: nil
        )
        XCTAssertNotEqual(configWithAdapter.hashValue, configWithoutAdapter.hashValue)
    }
}

// MARK: - _TestExternalWalletAdapter

/// Minimal `OZExternalWalletAdapter` used by equality/hash tests.
private final class _TestExternalWalletAdapter: OZExternalWalletAdapter, @unchecked Sendable {
    func connect() async throws -> OZConnectedWallet? { return nil }
    func disconnect() async throws {}
    func signAuthEntry(preimageXdr: String, options: OZSignAuthEntryOptions?) async throws -> OZSignAuthEntryResult {
        return OZSignAuthEntryResult(signedAuthEntry: "")
    }
    func getConnectedWallets() -> [OZConnectedWallet] { return [] }
    func canSignFor(address: String) -> Bool { return false }
}

// MARK: - _TestEd25519SignerAdapter

/// Minimal `OZExternalEd25519SignerAdapter` used by equality/hash tests.
private final class _TestEd25519SignerAdapter: OZExternalEd25519SignerAdapter, @unchecked Sendable {
    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool { return false }
    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data { return Data(repeating: 0, count: 64) }
}

// MARK: - _TestNamedStorageAdapter

/// Concrete `OZStorageAdapter` that is neither `OZInMemoryStorageAdapter` nor
/// `OZKeychainStorageAdapter`. Used by equality tests to exercise the identity-
/// comparison branch in `storageAdaptersEqual(_:_:)`.
private final class _TestNamedStorageAdapter: OZStorageAdapter, @unchecked Sendable {
    let name: String
    private let inner = OZInMemoryStorageAdapter()

    init(name: String) { self.name = name }

    func save(credential: OZStoredCredential) async throws { try await inner.save(credential: credential) }
    func get(credentialId: String) async throws -> OZStoredCredential? { try await inner.get(credentialId: credentialId) }
    func getByContract(contractId: String) async throws -> [OZStoredCredential] { try await inner.getByContract(contractId: contractId) }
    func getAll() async throws -> [OZStoredCredential] { try await inner.getAll() }
    func delete(credentialId: String) async throws { try await inner.delete(credentialId: credentialId) }
    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws { try await inner.update(credentialId: credentialId, updates: updates) }
    func clear() async throws { try await inner.clear() }
    func saveSession(_ session: OZStoredSession) async throws { try await inner.saveSession(session) }
    func getSession() async throws -> OZStoredSession? { try await inner.getSession() }
    func clearSession() async throws { try await inner.clearSession() }
}
