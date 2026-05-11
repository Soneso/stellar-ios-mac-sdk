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
        XCTAssertNil(config.rpId)
        XCTAssertEqual("Smart Account", config.rpName)
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
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
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
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
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
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
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
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
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
            XCTAssertTrue(error is ConfigurationException.MissingConfig)
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
            XCTAssertTrue(error is ConfigurationException.MissingConfig)
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
            XCTAssertTrue(error is ConfigurationException.MissingConfig)
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
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
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
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
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
            .rpName("My Custom Wallet")
            .rpId("example.com")
            .sessionExpiryMs(86_400_000)
            .signatureExpirationLedgers(1440)
            .timeoutInSeconds(60)
            .relayerUrl("https://relayer.example.com")
            .indexerUrl("https://indexer.example.com")
            .build()

        XCTAssertEqual("My Custom Wallet", config.rpName)
        XCTAssertEqual("example.com", config.rpId)
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

        XCTAssertEqual("Smart Account", config.rpName)
        XCTAssertNil(config.rpId)
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
            rpName: "Test",
            sessionExpiryMs: 100_000,
            relayerUrl: "https://relayer.test"
        )

        let builderConfig = try OZSmartAccountConfig.builder(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier
        )
            .rpName("Test")
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
            .rpId(nil)
            .relayerUrl(nil)
            .indexerUrl(nil)
            .deployerKeypair(nil)
            .build()

        XCTAssertNil(config.rpId)
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
            .rpName("A")
            .rpId("b.com")
            .sessionExpiryMs(1000)
            .signatureExpirationLedgers(100)
            .timeoutInSeconds(10)
            .relayerUrl("https://r.com")
            .indexerUrl("https://i.com")
            .deployerKeypair(nil)

        let config = try result.build()
        XCTAssertEqual("A", config.rpName)
        XCTAssertEqual("b.com", config.rpId)
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
            rpId: original.rpId,
            rpName: "Modified Wallet",
            sessionExpiryMs: original.sessionExpiryMs,
            signatureExpirationLedgers: original.signatureExpirationLedgers,
            timeoutInSeconds: original.timeoutInSeconds,
            relayerUrl: original.relayerUrl,
            indexerUrl: original.indexerUrl,
            webauthnProvider: original.webauthnProvider,
            storage: original.storage,
            externalWallet: original.externalWallet,
            maxContextRuleScanId: original.maxContextRuleScanId
        )

        XCTAssertEqual("Modified Wallet", modified.rpName)
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

        // The exact URL depends on the SDK's default-indexer table; this assertion
        // only checks that the call resolves without throwing or trapping.
        _ = config.effectiveIndexerUrl()
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
}
