//
//  OZConstructorPoliciesIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Testnet integration tests for constructor-time policy installation: a wallet deployed with
/// `policies` installs them on the Default context rule via the contract constructor.
///
/// The deploy transaction is signed by the deployer, not the passkey, so the passkey side is a
/// `StubWebAuthnProvider` carrying a valid secp256r1 point (the curve's generator) as the
/// public key: it passes client-side curve validation and the on-chain verifier's key
/// canonicalization, and is never used for signing here. A random credential ID gives every
/// run a fresh derived contract address.
final class OZConstructorPoliciesIntegrationTests: XCTestCase {

    // MARK: - Configuration

    let rpcUrl = "https://soroban-testnet.stellar.org"
    let sdk = StellarSDK.testNet()
    let network = Network.testnet

    /// Smart account contract WASM installed on testnet.
    let accountWasmHash = "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28"

    /// WebAuthn verifier contract deployed on testnet.
    let webauthnVerifier = "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"

    /// SimpleThreshold policy contract deployed on testnet.
    let thresholdPolicy = "CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC"

    /// Uncompressed secp256r1 generator point: a valid on-curve public key.
    let p256GeneratorPubKey = (
        "04"
        + "6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296"
        + "4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5"
    ).data(using: .hexadecimal)!

    // MARK: - Tests

    /// A wallet deployed with a satisfiable threshold-one policy must carry that policy on
    /// its Default context rule when the rules are read back from the chain.
    func testDeployWithThresholdOnePolicyInstallsOnDefaultRule() async throws {
        try await withKit { kit in
            let result = try await kit.walletOperations.createWallet(
                userName: "Constructor Policy Test",
                autoSubmit: true,
                policies: [
                    self.thresholdPolicy: try OZPolicyInstallParams.simpleThreshold(threshold: 1).toScVal()
                ]
            )
            XCTAssertFalse(result.contractId.isEmpty, "deploy must yield a contract address")

            // Read back the Default rule and verify the policy was installed at construction.
            let rules = try await kit.contextRuleManager.listContextRules()
            let defaultRule = try XCTUnwrap(
                rules.first { $0.id == 0 },
                "the deployed wallet must expose its Default context rule"
            )
            XCTAssertTrue(
                defaultRule.policies.contains(self.thresholdPolicy),
                "Default rule must carry the constructor-installed threshold policy, got: \(defaultRule.policies)"
            )
        }
    }

    /// A threshold of 2 exceeds the Default rule's single initial signer; the policy contract
    /// rejects the install during deploy simulation with `InvalidThreshold` (3201).
    func testDeployWithTwoOfOneThresholdFailsAtSimulationWithInvalidThreshold() async throws {
        try await withKit { kit in
            var thrown: Error?
            do {
                _ = try await kit.walletOperations.createWallet(
                    userName: "Constructor Policy Negative Test",
                    autoSubmit: false,
                    policies: [
                        self.thresholdPolicy: try OZPolicyInstallParams.simpleThreshold(threshold: 2).toScVal()
                    ]
                )
            } catch {
                thrown = error
            }
            let exception = try XCTUnwrap(
                thrown as? SmartAccountTransactionException,
                "createWallet must fail when the threshold exceeds the signer count, got: \(String(describing: thrown))"
            )
            let decoded = try XCTUnwrap(
                OZContractErrorCodes.decodeFromMessage(exception.message),
                "simulation error must carry a decodable contract error, got: \(exception.message)"
            )
            XCTAssertEqual(3201, decoded.code)
            XCTAssertEqual("InvalidThreshold", decoded.name)
            XCTAssertEqual("SimpleThresholdError", decoded.contract)
        }
    }

    // MARK: - Helpers

    /// Creates a kit backed by a freshly funded deployer, runs `body`, and closes the kit on
    /// both the success and the failure path.
    private func withKit(_ body: (OZSmartAccountKit) async throws -> Void) async throws {
        let kit = try await createKit()
        do {
            try await body(kit)
        } catch {
            await kit.close()
            throw error
        }
        await kit.close()
    }

    /// Builds a kit whose deployer is a fresh testnet-funded keypair and whose passkey side
    /// is a stub provider returning the secp256r1 generator point plus a random credential ID.
    private func createKit() async throws -> OZSmartAccountKit {
        let deployer = try KeyPair.generateRandomKeyPair()
        let responseEnum = await sdk.accounts.createTestAccount(accountId: deployer.accountId)
        switch responseEnum {
        case .success:
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(
                tag: "OZConstructorPoliciesIntegrationTests.createKit()",
                horizonRequestError: error
            )
            XCTFail("could not create test account: \(deployer.accountId)")
            throw error
        }
        try await waitForRpcAccount(accountId: deployer.accountId)

        let provider = StubWebAuthnProvider(
            registrationResult: WebAuthnRegistrationResult(
                credentialId: randomBytes(count: 16),
                publicKey: p256GeneratorPubKey,
                attestationObject: syntheticAttestationObject(),
                transports: ["internal"],
                deviceType: "multiDevice",
                backedUp: true
            )
        )

        let config = try OZSmartAccountConfig(
            rpcUrl: rpcUrl,
            networkPassphrase: network.passphrase,
            accountWasmHash: accountWasmHash,
            webauthnVerifierAddress: webauthnVerifier,
            deployerKeypair: deployer,
            webauthnProvider: provider
        )
        return OZSmartAccountKit.create(config: config)
    }

    /// Waits until the RPC exposes the freshly funded account. The deploy path fetches the
    /// deployer through the RPC, so Friendbot funding must be visible there before deploying.
    private func waitForRpcAccount(accountId: String) async throws {
        let sorobanServer = SorobanServer(endpoint: rpcUrl)
        for _ in 0..<20 {
            let response = await sorobanServer.getAccount(accountId: accountId)
            if case .success = response {
                return
            }
            try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
        }
        XCTFail("funded account \(accountId) did not become visible on the RPC")
    }

    /// Cryptographically random bytes for credential IDs.
    private func randomBytes(count: Int) -> Data {
        var data = Data(count: count)
        for i in 0..<count {
            data[i] = UInt8.random(in: .min ... .max)
        }
        return data
    }

    /// Deterministic 128-byte synthetic attestation object. The deploy path takes the public
    /// key directly from the registration result's 65-byte `publicKey`, so the attestation
    /// bytes are never parsed here.
    private func syntheticAttestationObject() -> Data {
        var bytes = Data(count: 128)
        for i in 0..<128 {
            bytes[i] = UInt8((i + 0x10) % 256)
        }
        return bytes
    }
}

/// Passkey stub for deploy-path tests: `register` returns the configured result;
/// `authenticate` fails, asserting the deploy flow never requests a passkey signature.
private final class StubWebAuthnProvider: WebAuthnProvider, @unchecked Sendable {

    let registrationResult: WebAuthnRegistrationResult

    init(registrationResult: WebAuthnRegistrationResult) {
        self.registrationResult = registrationResult
    }

    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult {
        return registrationResult
    }

    func authenticate(
        challenge: Data,
        allowCredentials: [WebAuthnAllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult {
        throw WebAuthnException.authenticationFailed(
            reason: "authenticate must not be called: the deploy transaction is signed by the deployer"
        )
    }
}
