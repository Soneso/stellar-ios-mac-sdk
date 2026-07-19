//
//  OZConstructorPoliciesTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Constructor-time policy installation: the config-level
//  ``OZSmartAccountConfig/defaultPolicies`` default and the per-call `policies`
//  override on ``OZWalletOperations/createWallet`` and
//  ``OZWalletOperations/deployPendingCredential``, plus the
//  `requireValidPolicies` guard that runs before the passkey ceremony. The
//  pipeline cases decode the signed deploy envelope and assert the exact
//  constructor-arg encoding produced by the build.
//

import XCTest
@testable import stellarsdk

final class OZConstructorPoliciesTests: XCTestCase {

    // MARK: - Constants

    private let verifierContract =
        "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
    private let credentialIdB64Url = "aGVsbG8tc21hcnQtYWNjb3VudA"

    // MARK: - State

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

    // MARK: - Fixtures

    /// Synthesizes a valid `C…` contract address from a deterministic 32-byte
    /// payload derived from `seed`.
    private func policyAddress(seed: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        for index in 0..<32 {
            bytes[index] = UInt8(truncatingIfNeeded: index + seed)
        }
        return try Data(bytes).encodeContractId()
    }

    /// A minimal valid install-param ScVal (SimpleThreshold with threshold 1).
    private func installParam() throws -> SCValXDR {
        return try OZPolicyInstallParams.simpleThreshold(threshold: 1).toScVal()
    }

    /// Builds `n` policies keyed by synthesized contract addresses.
    private func policies(_ n: Int) throws -> [String: SCValXDR] {
        var result: [String: SCValXDR] = [:]
        for index in 0..<n {
            result[try policyAddress(seed: index)] = try installParam()
        }
        return result
    }

    /// Builds a config carrying the supplied provider / deployer / storage /
    /// default policies.
    private func buildConfig(
        provider: WebAuthnProvider? = nil,
        deployer: KeyPair? = nil,
        storage: OZStorageAdapter = OZInMemoryStorageAdapter(),
        defaultPolicies: [String: SCValXDR] = [:]
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: verifierContract,
            deployerKeypair: deployer,
            webauthnProvider: provider,
            storage: storage,
            defaultPolicies: defaultPolicies
        )
    }

    /// Returns a deterministic deployer keypair so fixtures can pre-compute
    /// `accountId` for scripting the deployer account-fetch response.
    private func deterministicDeployer(seed: UInt8 = 0x77) throws -> KeyPair {
        let seedBytes = Data(repeating: seed, count: 32)
        let stellarSeed = try Seed(bytes: [UInt8](seedBytes))
        return KeyPair(seed: stellarSeed)
    }

    /// secp256r1 generator point assembled into a 65-byte uncompressed SEC1
    /// public key. `extractPublicKeyFromRegistration` validates the point lies
    /// on the curve, so a real on-curve point is required for createWallet.
    private func generatorPointPublicKey() -> Data {
        let x = Data([
            0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
            0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
            0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
            0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96
        ])
        let y = Data([
            0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
            0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
            0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
            0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5
        ])
        var pk = Data([0x04])
        pk.append(x)
        pk.append(y)
        return pk
    }

    /// Builds a `WebAuthnRegistrationResult` carrying the supplied credential
    /// id and an on-curve public key.
    private func registrationResult(credentialId: Data) -> WebAuthnRegistrationResult {
        return WebAuthnRegistrationResult(
            credentialId: credentialId,
            publicKey: generatorPointPublicKey(),
            attestationObject: Data(),
            transports: ["internal"],
            deviceType: "multiDevice",
            backedUp: true
        )
    }

    /// Builds a kit wired to the scripted RPC transport.
    private func pipelineKit(config: OZSmartAccountConfig, deployer: KeyPair) -> MockOZSmartAccountKit {
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer
        return kit
    }

    /// Enqueues the deployer account-fetch response so the deploy build's
    /// `getAccount(deployer.accountId)` lookup succeeds.
    private func enqueueDeployerAccount(deployer: KeyPair, sequence: Int64 = 1) {
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: sequence)
    }

    /// Stores a credential under `credentialIdB64Url` whose `contractId`
    /// matches the deterministic derivation `deployPendingCredential` re-runs.
    private func storePendingCredential(
        storage: OZInMemoryStorageAdapter,
        deployer: KeyPair
    ) async throws -> String {
        let credentialIdBytes = try Data(base64URLEncoded: credentialIdB64Url)
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        let stored = OZStoredCredential(
            credentialId: credentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: derivedContractId
        )
        try await storage.save(credential: stored)
        return derivedContractId
    }

    /// Returns the first InvokeHostFunction operation body in the envelope, or nil.
    private func firstInvokeHostFunctionOp(
        envelope: TransactionEnvelopeXDR
    ) -> InvokeHostFunctionOpXDR? {
        let operations: [OperationXDR]
        switch envelope {
        case .v0(let env): operations = env.tx.operations
        case .v1(let env): operations = env.tx.operations
        case .feeBump(let env):
            if case .v1(let inner) = env.tx.innerTx {
                operations = inner.tx.operations
            } else {
                return nil
            }
        }
        for op in operations {
            if case .invokeHostFunctionOp(let invoke) = op.body {
                return invoke
            }
        }
        return nil
    }

    /// Decodes the signed deploy envelope and returns the CreateContractV2
    /// constructor's policies argument (constructor arg index 1).
    private func constructorPoliciesScVal(signedTransactionXdr: String) throws -> SCValXDR {
        let envelope = try TransactionEnvelopeXDR(xdr: signedTransactionXdr)
        let op = try XCTUnwrap(
            firstInvokeHostFunctionOp(envelope: envelope),
            "expected an InvokeHostFunctionOp in the deploy envelope"
        )
        guard case .createContractV2(let createArgs) = op.hostFunction else {
            XCTFail("expected createContractV2 host function")
            throw SmartAccountValidationException.invalidInput(
                field: "hostFunction",
                reason: "expected createContractV2"
            )
        }
        XCTAssertEqual(createArgs.constructorArgs.count, 2,
                       "constructor takes exactly (signers, policies)")
        return createArgs.constructorArgs[1]
    }

    /// Asserts the two ScVals encode to identical XDR byte sequences.
    private func assertSameXdrBytes(
        _ actual: SCValXDR,
        _ expected: SCValXDR,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(actual),
            OZPolicyManager.scValToXdrBytes(expected),
            message,
            file: file,
            line: line
        )
    }

    // ========================================================================
    // MARK: - requireValidPolicies
    // ========================================================================

    func test_requireValidPolicies_emptyAndAtMax_ok() throws {
        XCTAssertNoThrow(try requireValidPolicies([:]))
        XCTAssertNoThrow(try requireValidPolicies(try policies(OZConstants.maxPolicies)))
    }

    func test_requireValidPolicies_tooMany_throws() throws {
        do {
            try requireValidPolicies(try policies(OZConstants.maxPolicies + 1))
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(
                error.message,
                "Invalid input for policies: Cannot install more than \(OZConstants.maxPolicies) policies, got: \(OZConstants.maxPolicies + 1)"
            )
        }
    }

    func test_requireValidPolicies_invalidAddress_throws() throws {
        do {
            try requireValidPolicies(["not-a-contract-address": try installParam()])
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch let error as SmartAccountValidationException.InvalidAddress {
            XCTAssertEqual(
                error.message,
                "policyAddress must be a valid contract address (C...), got: not-a-contract-address"
            )
        }
    }

    // ========================================================================
    // MARK: - Config defaultPolicies
    // ========================================================================

    func test_config_defaultPolicies_defaultsEmpty() throws {
        XCTAssertTrue(try buildConfig().defaultPolicies.isEmpty)
    }

    func test_config_defaultPolicies_viaInitAndBuilder() throws {
        let p = try policies(2)

        let direct = try buildConfig(defaultPolicies: p)
        XCTAssertEqual(Set(direct.defaultPolicies.keys), Set(p.keys))
        for (key, value) in p {
            let stored = try XCTUnwrap(direct.defaultPolicies[key])
            assertSameXdrBytes(stored, value, "init must store the supplied install params byte-identically")
        }

        let built = try OZSmartAccountConfig.builder(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: verifierContract
        )
            .defaultPolicies(p)
            .build()
        XCTAssertEqual(Set(built.defaultPolicies.keys), Set(p.keys))
        for (key, value) in p {
            let stored = try XCTUnwrap(built.defaultPolicies[key])
            assertSameXdrBytes(stored, value, "builder must store the supplied install params byte-identically")
        }
        XCTAssertEqual(direct, built, "init and builder must produce equal configs")
    }

    // ========================================================================
    // MARK: - createWallet validation before the passkey ceremony
    // ========================================================================

    func test_createWallet_invalidPerCallPolicies_throwsBeforeCeremony() async throws {
        let provider = RecordingWebAuthnProvider()
        let kit = MockOZSmartAccountKit(config: try buildConfig(provider: provider))
        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.createWallet(
                policies: ["not-a-contract": try installParam()]
            )
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        }
        XCTAssertEqual(provider.registerCalls.count, 0,
                       "policy validation must run before the passkey ceremony")
    }

    func test_createWallet_tooManyPerCallPolicies_throwsBeforeCeremony() async throws {
        let provider = RecordingWebAuthnProvider()
        let kit = MockOZSmartAccountKit(config: try buildConfig(provider: provider))
        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.createWallet(
                policies: try policies(OZConstants.maxPolicies + 1)
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
        XCTAssertEqual(provider.registerCalls.count, 0)
    }

    func test_createWallet_usesConfigDefaultWhenNoOverride() async throws {
        // No per-call policies -> the invalid config default is used -> throws
        // before the ceremony.
        let provider = RecordingWebAuthnProvider()
        let kit = MockOZSmartAccountKit(
            config: try buildConfig(
                provider: provider,
                defaultPolicies: try policies(OZConstants.maxPolicies + 1)
            )
        )
        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.createWallet()
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
        XCTAssertEqual(provider.registerCalls.count, 0)
    }

    func test_deployPendingCredential_invalidPolicies_throwsBeforeCredentialLookup() async throws {
        // Policy validation runs before the stored-credential lookup: an
        // unknown credential with an invalid policies map fails with the
        // validation error, not NotFound.
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "unknown-credential",
                policies: try policies(OZConstants.maxPolicies + 1)
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    func test_createWallet_perCallOverridesInvalidConfigDefault() async throws {
        // A valid per-call override supersedes an invalid config default:
        // validation passes, the ceremony runs, and the deploy encodes the
        // override (an empty map) rather than the config default.
        let provider = RecordingWebAuthnProvider()
        let deployer = try deterministicDeployer()
        let config = try buildConfig(
            provider: provider,
            deployer: deployer,
            defaultPolicies: try policies(OZConstants.maxPolicies + 1)
        )
        let kit = pipelineKit(config: config, deployer: deployer)

        let credentialIdBytes = try Data(base64URLEncoded: credentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))
        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.createWallet(
            autoSubmit: false,
            policies: [:]
        )

        XCTAssertEqual(provider.registerCalls.count, 1,
                       "a valid per-call override must supersede the invalid config default")
        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, .map([]),
                           "an explicit empty map must deploy with no policies")
    }

    // ========================================================================
    // MARK: - createWallet deploy encoding
    // ========================================================================

    func test_createWallet_perCallPolicies_encodedIntoConstructorArgs() async throws {
        let provider = RecordingWebAuthnProvider()
        let deployer = try deterministicDeployer()
        let config = try buildConfig(provider: provider, deployer: deployer)
        let kit = pipelineKit(config: config, deployer: deployer)

        let credentialIdBytes = try Data(base64URLEncoded: credentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))
        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let p = try policies(3)
        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.createWallet(
            autoSubmit: false,
            policies: p
        )

        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, try OZPolicyManager.policiesToScVal(p),
                           "per-call policies must be encoded into the constructor args")

        // The encoded map's keys must follow the host's ScMap key order.
        guard case .map(let entries) = policiesArg, let entries = entries else {
            XCTFail("policies constructor arg is not an SCValXDR.map")
            return
        }
        XCTAssertEqual(entries.count, 3)
        for index in 0..<(entries.count - 1) {
            XCTAssertLessThan(
                compareScValHostOrder(entries[index].key, entries[index + 1].key),
                0,
                "policy map keys must be sorted into the host's ScMap key order"
            )
        }
    }

    func test_createWallet_configDefaultPolicies_usedWhenPerCallNil() async throws {
        let provider = RecordingWebAuthnProvider()
        let deployer = try deterministicDeployer()
        let p = try policies(2)
        let config = try buildConfig(
            provider: provider,
            deployer: deployer,
            defaultPolicies: p
        )
        let kit = pipelineKit(config: config, deployer: deployer)

        let credentialIdBytes = try Data(base64URLEncoded: credentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))
        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.createWallet(autoSubmit: false)

        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, try OZPolicyManager.policiesToScVal(p),
                           "config defaultPolicies must be used when no per-call policies are given")
    }

    func test_createWallet_noPolicies_constructorArgsByteIdenticalToEmptyMap() async throws {
        // With neither a config default nor a per-call map, the constructor's
        // policies argument must stay byte-identical to an empty ScMap.
        let provider = RecordingWebAuthnProvider()
        let deployer = try deterministicDeployer()
        let config = try buildConfig(provider: provider, deployer: deployer)
        let kit = pipelineKit(config: config, deployer: deployer)

        let credentialIdBytes = try Data(base64URLEncoded: credentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))
        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.createWallet(autoSubmit: false)

        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, .map([]),
                           "the no-policies deploy must encode an empty ScMap")
    }

    // ========================================================================
    // MARK: - deployPendingCredential wiring
    // ========================================================================

    func test_deployPendingCredential_perCallPolicies_threadedIntoDeploy() async throws {
        let deployer = try deterministicDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try buildConfig(deployer: deployer, storage: storage)
        let kit = pipelineKit(config: config, deployer: deployer)
        _ = try await storePendingCredential(storage: storage, deployer: deployer)

        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let p = try policies(2)
        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.deployPendingCredential(
            credentialId: credentialIdB64Url,
            autoSubmit: false,
            policies: p
        )

        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, try OZPolicyManager.policiesToScVal(p),
                           "per-call policies must be threaded into the pending-credential deploy")
    }

    func test_deployPendingCredential_configDefaultPolicies_usedWhenPerCallNil() async throws {
        let deployer = try deterministicDeployer()
        let storage = OZInMemoryStorageAdapter()
        let p = try policies(2)
        let config = try buildConfig(
            deployer: deployer,
            storage: storage,
            defaultPolicies: p
        )
        let kit = pipelineKit(config: config, deployer: deployer)
        _ = try await storePendingCredential(storage: storage, deployer: deployer)

        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.deployPendingCredential(
            credentialId: credentialIdB64Url,
            autoSubmit: false
        )

        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, try OZPolicyManager.policiesToScVal(p),
                           "config defaultPolicies must apply to pending-credential deploys")
    }

    func test_deployPendingCredential_explicitEmptyMap_suppressesConfigDefault() async throws {
        let deployer = try deterministicDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try buildConfig(
            deployer: deployer,
            storage: storage,
            defaultPolicies: try policies(2)
        )
        let kit = pipelineKit(config: config, deployer: deployer)
        _ = try await storePendingCredential(storage: storage, deployer: deployer)

        enqueueDeployerAccount(deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.deployPendingCredential(
            credentialId: credentialIdB64Url,
            autoSubmit: false,
            policies: [:]
        )

        let policiesArg = try constructorPoliciesScVal(
            signedTransactionXdr: result.signedTransactionXdr
        )
        assertSameXdrBytes(policiesArg, .map([]),
                           "an explicit empty map must suppress the config default")
    }
}
