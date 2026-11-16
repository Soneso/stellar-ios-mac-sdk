//
//  OZAuthDigestSchemeTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Selection of the auth digest scheme: the built-in and configured WASM hash tables of
/// ``OZSmartAccountConfig`` and the ledger read of `prepareSigningOperation`, which reads the
/// wallet's instance once per signing operation and takes the signature expiration from the
/// same response.
final class OZAuthDigestSchemeTests: XCTestCase {

    private let wallet = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let otherContract = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
    private let ownBuildHex = String(repeating: "ab", count: 32)
    private let signingLedger = 1000

    private var script: MockSorobanServerScript!

    override func setUp() {
        super.setUp()
        script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
    }

    override func tearDown() {
        MockSorobanServer.deactivate()
        script = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Helpers

    private func config(
        authDigestSchemes: [String: OZAuthDigestScheme] = [:],
        signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: otherContract,
            signatureExpirationLedgers: signatureExpirationLedgers,
            authDigestSchemes: authDigestSchemes
        )
    }

    private func builder() -> OZSmartAccountConfig.Builder {
        return OZSmartAccountConfig.Builder(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: otherContract
        )
    }

    /// The signing helpers of a kit on the scripted RPC.
    private func helpers(_ config: OZSmartAccountConfig) -> OZTransactionOperations {
        let kit = MockOZSmartAccountKit(config: config, sorobanServer: MockSorobanServer.makeMockedSorobanServer())
        return OZTransactionOperations(kit: kit)
    }

    private func walletEntry() throws -> SorobanAuthorizationEntryXDR {
        return try OZPipelineFixtures.addressCredentialsAuthEntry(contractAddress: wallet, targetContract: otherContract)
    }

    private func prepare(
        _ config: OZSmartAccountConfig,
        entries: [SorobanAuthorizationEntryXDR]? = nil
    ) async throws -> OZSigningOperationState {
        return try await helpers(config).prepareSigningOperation(
            contractId: wallet,
            authEntries: try entries ?? [walletEntry()]
        )
    }

    private func wasm(_ hex: String) throws -> ContractExecutableXDR {
        return .wasm(WrappedData32(try Data(base16Encoded: hex)))
    }

    private func assertInvalidConfig(
        _ expression: () throws -> OZSmartAccountConfig,
        contains expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard let invalid = error as? SmartAccountConfigurationException.InvalidConfig else {
                return XCTFail("expected InvalidConfig, got \(error)", file: file, line: line)
            }
            XCTAssertTrue(invalid.message.contains(expected), "unexpected message: \(invalid.message)", file: file, line: line)
        }
    }

    // MARK: - Tables

    func test_authDigestScheme_builtInV080Build_isPreimage() throws {
        let config = try config()
        XCTAssertEqual(config.authDigestScheme(forWasmHashHex: OZAuthDigestWasm.v080Hex), .preimageV1)
        XCTAssertEqual(config.authDigestScheme(forWasmHashHex: OZAuthDigestWasm.v080Hex.uppercased()), .preimageV1)
    }

    func test_authDigestScheme_unmappedHash_isLegacy() throws {
        XCTAssertEqual(try config().authDigestScheme(forWasmHashHex: ownBuildHex), .legacyConcat)
    }

    func test_authDigestScheme_configuredOwnBuild_isPreimageInAnyCase() throws {
        let config = try config(authDigestSchemes: [ownBuildHex.uppercased(): .preimageV1])
        XCTAssertEqual(config.authDigestScheme(forWasmHashHex: ownBuildHex), .preimageV1)
        XCTAssertEqual(config.authDigestScheme(forWasmHashHex: ownBuildHex.uppercased()), .preimageV1)
        XCTAssertEqual(config.authDigestScheme(forWasmHashHex: OZAuthDigestWasm.v080Hex), .preimageV1)
    }

    func test_authDigestScheme_configuredOverrideOfBuiltIn_isLegacy() throws {
        let config = try config(authDigestSchemes: [OZAuthDigestWasm.v080Hex: .legacyConcat])
        XCTAssertEqual(config.authDigestScheme(forWasmHashHex: OZAuthDigestWasm.v080Hex), .legacyConcat)
    }

    func test_config_invalidAuthDigestSchemesKey_throwsInInitAndBuild() {
        for key in ["abc", String(repeating: "a", count: 63), String(repeating: "g", count: 64), String(repeating: "a", count: 65)] {
            let expected = "authDigestSchemes key must be a 64-character hex string (SHA-256 of WASM), got: \(key)"
            assertInvalidConfig({ try self.config(authDigestSchemes: [key: .preimageV1]) }, contains: expected)
            assertInvalidConfig({ try self.builder().authDigestSchemes([key: .preimageV1]).build() }, contains: expected)
        }
    }

    func test_config_keysDifferingOnlyInCase_mustAgree() throws {
        let lower = ownBuildHex
        let upper = ownBuildHex.uppercased()
        let conflicting: [String: OZAuthDigestScheme] = [lower: .preimageV1, upper: .legacyConcat]
        let expected = "authDigestSchemes maps \(lower) to both"
        assertInvalidConfig({ try self.config(authDigestSchemes: conflicting) }, contains: expected)
        assertInvalidConfig({ try self.builder().authDigestSchemes(conflicting).build() }, contains: expected)

        let agreeing = try config(authDigestSchemes: [lower: .preimageV1, upper: .preimageV1])
        XCTAssertEqual(agreeing.authDigestScheme(forWasmHashHex: lower), .preimageV1)
    }

    func test_builder_authDigestSchemes_reachesTheConfig() throws {
        let schemes: [String: OZAuthDigestScheme] = [ownBuildHex: .preimageV1]
        let built = try builder().authDigestSchemes(schemes).build()
        XCTAssertEqual(built.authDigestSchemes, schemes)
        XCTAssertEqual(built.authDigestScheme(forWasmHashHex: ownBuildHex), .preimageV1)
        XCTAssertEqual(try builder().build().authDigestSchemes, [:])
    }

    func test_config_equalityAndHash_carryTheMap() throws {
        let first = try config(authDigestSchemes: [ownBuildHex: .preimageV1])
        let same = try config(authDigestSchemes: [ownBuildHex: .preimageV1])
        let other = try config(authDigestSchemes: [ownBuildHex: .legacyConcat])
        let empty = try config()

        XCTAssertEqual(first, same)
        XCTAssertEqual(first.hashValue, same.hashValue)
        XCTAssertNotEqual(first, other)
        XCTAssertNotEqual(first, empty)
        XCTAssertNotEqual(first.hashValue, other.hashValue)
    }

    // MARK: - The instance read

    func test_prepare_readsThePersistentInstanceOfTheWallet() async throws {
        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080, latestLedger: signingLedger)

        let state = try await prepare(try config())

        XCTAssertEqual(state.authDigestScheme, .preimageV1)
        XCTAssertEqual(state.expirationLedger, UInt32(signingLedger + StellarProtocolConstants.ledgersPerHour))
        XCTAssertEqual(script.getLedgerEntriesCallCount, 1)
        XCTAssertEqual(try script.walletInstanceReadCount(contractId: wallet), 1)
        XCTAssertEqual(script.getLatestLedgerCallCount, 0)
    }

    func test_prepare_configuredHash_followsTheConfig() async throws {
        try script.setWalletInstanceResponse(contractId: wallet, executable: try wasm(ownBuildHex))
        let ownBuild = try await prepare(try config(authDigestSchemes: [ownBuildHex: .preimageV1]))
        XCTAssertEqual(ownBuild.authDigestScheme, .preimageV1)

        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080)
        let overridden = try await prepare(try config(authDigestSchemes: [OZAuthDigestWasm.v080Hex: .legacyConcat]))
        XCTAssertEqual(overridden.authDigestScheme, .legacyConcat)
    }

    func test_prepare_unmappedHash_isLegacy() async throws {
        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.unmapped)
        let state = try await prepare(try config())
        XCTAssertEqual(state.authDigestScheme, .legacyConcat)
    }

    func test_prepare_externalReferenceExecutable_isLegacy() async throws {
        let reference = ContractExecutableExternalRefXDR(
            executableOwner: try SCAddressXDR(contractId: otherContract),
            tag: "v1"
        )
        try script.setWalletInstanceResponse(contractId: wallet, executable: .externalRef(reference))
        let state = try await prepare(try config())
        XCTAssertEqual(state.authDigestScheme, .legacyConcat)
    }

    func test_prepare_stellarAssetExecutable_isLegacy() async throws {
        try script.setWalletInstanceResponse(contractId: wallet, executable: .token)
        let state = try await prepare(try config())
        XCTAssertEqual(state.authDigestScheme, .legacyConcat)
    }

    func test_prepare_responseWithoutEntries_isLegacyAtTheReportedLedger() async throws {
        try script.setWalletInstanceRead(
            contractId: wallet,
            payload: OZPipelineFixtures.emptyGetLedgerEntriesResponse(latestLedger: 4242)
        )

        let state = try await prepare(try config())

        XCTAssertEqual(state.authDigestScheme, .legacyConcat)
        XCTAssertEqual(state.expirationLedger, UInt32(4242 + StellarProtocolConstants.ledgersPerHour))
        XCTAssertEqual(script.getLatestLedgerCallCount, 0)
    }

    func test_prepare_contractDataThatIsNoInstance_throwsSigningFailed() async throws {
        let payload = try XCTUnwrap(try OZPipelineFixtures.validGetContractDataResponse(contractId: wallet))
        try script.setWalletInstanceRead(contractId: wallet, payload: payload)
        do {
            _ = try await prepare(try config())
            XCTFail("expected SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertTrue(
                error.message.contains("The instance entry of \(wallet) is not a contract instance (CONTRACT_DATA)"),
                "unexpected message: \(error.message)"
            )
        }
    }

    func test_prepare_entryThatIsNoContractData_throwsSigningFailed() async throws {
        let payload = try XCTUnwrap(
            OZPipelineFixtures.validGetAccountResponse(accountId: try KeyPair.generateRandomKeyPair().accountId, sequence: 1)
        )
        try script.setWalletInstanceRead(contractId: wallet, payload: payload)
        do {
            _ = try await prepare(try config())
            XCTFail("expected SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertTrue(
                error.message.contains("The instance entry of \(wallet) is not a contract instance (ACCOUNT)"),
                "unexpected message: \(error.message)"
            )
        }
    }

    func test_prepare_undecodableEntry_throwsSigningFailed() async throws {
        try script.setWalletInstanceRead(contractId: wallet, payload: [
            "latestLedger": NSNumber(value: signingLedger),
            "entries": [[
                "key": try OZTransactionOperations.contractInstanceLedgerKey(contractId: wallet),
                "xdr": "AAAABg==",
                "lastModifiedLedgerSeq": NSNumber(value: signingLedger)
            ]]
        ])
        do {
            _ = try await prepare(try config())
            XCTFail("expected SigningFailed")
        } catch let error as SmartAccountTransactionException.SigningFailed {
            XCTAssertTrue(
                error.message.contains("Failed to decode the instance entry of \(wallet) to read its code"),
                "unexpected message: \(error.message)"
            )
            XCTAssertNotNil(error.cause)
        }
    }

    func test_prepare_rpcError_throwsSubmissionFailedAndNeverSignsLegacy() async throws {
        try script.setWalletInstanceRpcError(contractId: wallet)
        do {
            _ = try await prepare(try config())
            XCTFail("expected SubmissionFailed")
        } catch let error as SmartAccountTransactionException.SubmissionFailed {
            XCTAssertTrue(
                error.message.contains("Failed to read the instance of \(wallet) to select its auth digest scheme:"),
                "unexpected message: \(error.message)"
            )
            XCTAssertNotNil(error.cause)
        }
        XCTAssertEqual(script.getLatestLedgerCallCount, 0)
    }

    func test_prepare_latestLedgerOutsideUInt32_throwsSimulationFailed() async throws {
        for latestLedger in [-1, Int(UInt32.max) + 1] {
            try script.setWalletInstanceResponse(contractId: wallet, latestLedger: latestLedger)
            do {
                _ = try await prepare(try config())
                XCTFail("expected SimulationFailed for latestLedger \(latestLedger)")
            } catch let error as SmartAccountTransactionException.SimulationFailed {
                XCTAssertTrue(
                    error.message.contains("Latest ledger \(latestLedger) of the instance read of \(wallet) is not a UInt32 ledger sequence"),
                    "unexpected message: \(error.message)"
                )
            }
        }
    }

    func test_prepare_expirationOverflow_throwsSimulationFailed() async throws {
        let latestLedger = Int(UInt32.max) - 1
        try script.setWalletInstanceResponse(contractId: wallet, latestLedger: latestLedger)
        do {
            _ = try await prepare(try config())
            XCTFail("expected SimulationFailed")
        } catch let error as SmartAccountTransactionException.SimulationFailed {
            let sum = UInt64(latestLedger) + UInt64(StellarProtocolConstants.ledgersPerHour)
            XCTAssertTrue(
                error.message.contains("Computed expirationLedger \(sum) overflows UInt32"),
                "unexpected message: \(error.message)"
            )
        }
    }

    func test_prepare_upgradeBetweenOperations_changesTheScheme() async throws {
        let operations = helpers(try config())
        let entries = [try walletEntry()]

        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.unmapped)
        let before = try await operations.prepareSigningOperation(contractId: wallet, authEntries: entries)
        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080)
        let after = try await operations.prepareSigningOperation(contractId: wallet, authEntries: entries)

        XCTAssertEqual(before.authDigestScheme, .legacyConcat)
        XCTAssertEqual(after.authDigestScheme, .preimageV1)
        XCTAssertEqual(try script.walletInstanceReadCount(contractId: wallet), 2)
    }

    func test_prepare_configuredExpiration_isAddedToTheReadLedger() async throws {
        try script.setWalletInstanceResponse(contractId: wallet, latestLedger: 5000)
        let state = try await prepare(try config(signatureExpirationLedgers: 10))
        XCTAssertEqual(state.expirationLedger, 5010)
    }

    func test_prepare_walletEntriesOfEitherArm_readTheInstanceOncePerOperation() async throws {
        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080)
        var v2Entry = try walletEntry()
        if case .address(let credentials) = v2Entry.credentials {
            v2Entry.credentials = .addressV2(credentials)
        }
        let operations: [(String, [SorobanAuthorizationEntryXDR])] = [
            ("ADDRESS", [try walletEntry()]),
            ("ADDRESS_V2", [v2Entry]),
            ("ADDRESS and ADDRESS_V2", [try walletEntry(), v2Entry])
        ]

        for (index, (arms, entries)) in operations.enumerated() {
            let state = try await prepare(try config(), entries: entries)

            XCTAssertEqual(state.authDigestScheme, .preimageV1, arms)
            XCTAssertEqual(try script.walletInstanceReadCount(contractId: wallet), index + 1, arms)
            XCTAssertEqual(script.getLedgerEntriesCallCount, index + 1, arms)
        }
        XCTAssertEqual(script.getLatestLedgerCallCount, 0)
    }

    func test_prepare_noWalletEntry_readsTheLatestLedgerOnly() async throws {
        script.setGetLatestLedger(sequence: 777)
        var withDelegates = try walletEntry()
        if case .address(let credentials) = withDelegates.credentials {
            withDelegates.credentials = .addressWithDelegates(
                SorobanAddressCredentialsWithDelegatesXDR(addressCredentials: credentials, delegates: [])
            )
        }
        let entries: [SorobanAuthorizationEntryXDR] = [
            try OZPipelineFixtures.addressCredentialsAuthEntry(contractAddress: otherContract),
            try OZPipelineFixtures.accountAuthEntry(accountId: try KeyPair.generateRandomKeyPair().accountId, target: wallet),
            try OZPipelineFixtures.sourceAccountAuthEntry(targetContract: wallet),
            withDelegates
        ]

        let state = try await prepare(try config(), entries: entries)

        XCTAssertNil(state.authDigestScheme)
        XCTAssertEqual(state.expirationLedger, UInt32(777 + StellarProtocolConstants.ledgersPerHour))
        XCTAssertEqual(script.getLatestLedgerCallCount, 1)
        XCTAssertEqual(script.getLedgerEntriesCallCount, 0)
    }
}
