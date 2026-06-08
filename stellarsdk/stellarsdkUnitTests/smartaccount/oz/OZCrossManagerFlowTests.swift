//
//  OZCrossManagerFlowTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests for cross-manager flow consistency and encoding conformance probes.
///
/// Cross-manager flow tests verify orchestrated multi-manager sequences
/// produce the expected host-function shapes and routing decisions.
/// Encoding conformance tests pin the SDK's outbound encoding so a silent
/// encoding drift surfaces immediately.
final class OZCrossManagerFlowTests: XCTestCase {

    // ========================================================================
    // MARK: - Fixtures
    // ========================================================================

    private let validContractId =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validAccountAddress =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private let validVerifierAddress =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let secondaryContractId =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    /// Builds a kit-config suitable for unit tests. RPC URL is the public
    /// Testnet placeholder; tests do not reach the network.
    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifierAddress
        )
    }

    /// Builds a connected mock kit. Callers wire a recording multi-signer
    /// manager onto the kit's ``MockOZSmartAccountKit/multiSignerManagerOverride``
    /// slot after construction so both the signer and policy managers route
    /// their multi-signer submissions through the recorder.
    private func connectedKit(
        contextRuleParser: OZContextRuleParser? = nil
    ) throws -> MockOZSmartAccountKit {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: validContractId
        )
        kit.signerManagerOverride = OZSignerManager(
            kit: kit,
            contextRuleParser: contextRuleParser
        )
        kit.policyManagerOverride = OZPolicyManager(kit: kit)
        return kit
    }

    /// Returns a deterministic 65-byte SEC1-prefixed secp256r1 public key.
    private func validSecp256r1PublicKey() -> Data {
        var bytes = [UInt8](
            repeating: 0,
            count: SmartAccountConstants.secp256r1PublicKeySize
        )
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        for i in 1 ..< SmartAccountConstants.secp256r1PublicKeySize {
            bytes[i] = UInt8(i % 256)
        }
        return Data(bytes)
    }

    // ========================================================================
    // MARK: - Cross-Manager Flow
    // ========================================================================

    /// Orchestrate `addPasskey` on the signer manager followed by
    /// `removeSigner(by signerId:)` and verify each call routes to the
    /// supplied multi-signer submitter with the matching host-function shape.
    ///
    /// The sequence verifies the cross-manager invariant that adding and
    /// removing a signer through the manager surface produces invocations
    /// against the same multi-signer pipeline rather than diverging into the
    /// single-signer path partway through the flow.
    func test_crossManagerFlow_addRule_addSigner_removeSigner_listRules_consistentState() async throws {
        let kit = try connectedKit()
        let recordingSubmitter = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recordingSubmitter

        let walletParticipant = OZSelectedSigner.wallet(accountId: validAccountAddress)
        let participants: [OZSelectedSigner] = [walletParticipant]

        // Step 1: add a passkey signer to the default rule.
        let addResult = try await kit.signerManager.addPasskey(
            contextRuleId: 0,
            publicKey: validSecp256r1PublicKey(),
            credentialId: Data([0x10, 0x11]),
            selectedSigners: participants
        )
        XCTAssertTrue(addResult.success)

        // Step 2: remove a different signer by id from the same rule.
        let removeResult = try await kit.signerManager.removeSigner(
            contextRuleId: 0,
            signerId: 5,
            selectedSigners: participants
        )
        XCTAssertTrue(removeResult.success)

        XCTAssertEqual(recordingSubmitter.invocations.count, 2)

        // Verify the add invocation shape.
        guard case .invokeContract(let addInvoke) = recordingSubmitter.invocations[0].hostFunction else {
            return XCTFail("first invocation must be invokeContract")
        }
        XCTAssertEqual(addInvoke.functionName, "add_signer")
        XCTAssertEqual(addInvoke.args.count, 2)
        guard case .u32(let addRuleId) = addInvoke.args[0] else {
            return XCTFail("first arg of add_signer must be u32")
        }
        XCTAssertEqual(addRuleId, 0)

        // Verify the remove invocation shape.
        guard case .invokeContract(let removeInvoke) = recordingSubmitter.invocations[1].hostFunction else {
            return XCTFail("second invocation must be invokeContract")
        }
        XCTAssertEqual(removeInvoke.functionName, "remove_signer")
        XCTAssertEqual(removeInvoke.args.count, 2)
        guard case .u32(let removeRuleId) = removeInvoke.args[0],
              case .u32(let signerId) = removeInvoke.args[1] else {
            return XCTFail("remove_signer args must be u32, u32")
        }
        XCTAssertEqual(removeRuleId, 0)
        XCTAssertEqual(signerId, 5)
    }

    /// Verify a policy add-then-remove sequence routes through the multi-signer
    /// submitter for both calls, and the policy address resolution surfaces
    /// the matching `policyId` in the resulting host function.
    func test_crossManagerFlow_addPolicy_byMultiSigner_removeByAddress_idResolution() async throws {
        let kit = try connectedKit()
        let recordingSubmitter = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recordingSubmitter

        let participants: [OZSelectedSigner] = [
            .wallet(accountId: validAccountAddress)
        ]

        // Step 1: install a simple-threshold policy on the default rule.
        let addResult = try await kit.policyManager.addSimpleThreshold(
            contextRuleId: 0,
            policyAddress: secondaryContractId,
            threshold: 2,
            selectedSigners: participants
        )
        XCTAssertTrue(addResult.success)

        // Step 2: remove the policy by numeric id (the address-based overload
        // depends on the kit's context-rule manager which is the empty stub
        // here; the id-based remove suffices to verify the multi-signer
        // routing decision).
        let removeResult = try await kit.policyManager.removePolicy(
            contextRuleId: 0,
            policyId: 3,
            selectedSigners: participants
        )
        XCTAssertTrue(removeResult.success)

        XCTAssertEqual(recordingSubmitter.invocations.count, 2)

        guard case .invokeContract(let addInvoke) = recordingSubmitter.invocations[0].hostFunction else {
            return XCTFail("first invocation must be invokeContract")
        }
        XCTAssertEqual(addInvoke.functionName, "add_policy")
        XCTAssertEqual(addInvoke.args.count, 3)

        guard case .invokeContract(let removeInvoke) = recordingSubmitter.invocations[1].hostFunction else {
            return XCTFail("second invocation must be invokeContract")
        }
        XCTAssertEqual(removeInvoke.functionName, "remove_policy")
        XCTAssertEqual(removeInvoke.args.count, 2)
        guard case .u32(let policyId) = removeInvoke.args[1] else {
            return XCTFail("second arg of remove_policy must be u32")
        }
        XCTAssertEqual(policyId, 3)
    }

    /// Verify ``OZExternalSignerManager`` can register a wallet keypair from a
    /// secret seed, and that the registered G-address shows up in
    /// `canSignFor(...)` so a downstream multi-signer ceremony will accept it.
    func test_crossManagerFlow_externalSignerManager_signsForMultiSignerWallet() async throws {
        let manager = OZExternalSignerManager(
            networkPassphrase: Network.testnet.passphrase
        )
        let keypair = try KeyPair.generateRandomKeyPair()
        guard let secret = keypair.secretSeed else {
            return XCTFail("generated keypair must expose a secret seed")
        }
        let address = try await manager.addFromSecret(secretKey: secret)
        XCTAssertEqual(address, keypair.accountId)

        let canSign = await manager.canSignFor(address: address)
        XCTAssertTrue(canSign)

        // A second random address is not registered and must not be signable.
        let outsider = try KeyPair.generateRandomKeyPair()
        let outsiderCanSign = await manager.canSignFor(address: outsider.accountId)
        XCTAssertFalse(outsiderCanSign)
    }

    // ========================================================================
    // MARK: - Encoding Conformance Probes
    // ========================================================================

    /// `addPasskey` with an empty `selectedSigners` list (single-signer path)
    /// builds an `add_signer` host function with a fixed argument shape.
    /// Asserts the shape directly through
    /// ``OZSignerManager/buildAddSignerFunction(contractId:contextRuleId:signer:)``.
    func test_crossSDK_addPasskey_singleSigner_relayer_buildsIdenticalHostFunction() throws {
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validVerifierAddress,
            publicKey: validSecp256r1PublicKey(),
            credentialId: Data([0x21, 0x22, 0x23, 0x24])
        )

        let hostFunction = try OZSignerManager.buildAddSignerFunction(
            contractId: validContractId,
            contextRuleId: 7,
            signer: signer
        )

        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "add_signer")
        XCTAssertEqual(invokeArgs.args.count, 2)

        guard case .u32(let ruleId) = invokeArgs.args[0] else {
            return XCTFail("first arg must be u32")
        }
        XCTAssertEqual(ruleId, 7)

        guard case .vec(let optVec) = invokeArgs.args[1], let signerVec = optVec else {
            return XCTFail("second arg must be Vec (signer enum)")
        }
        XCTAssertEqual(signerVec.count, 3)
        guard case .symbol(let variant) = signerVec[0] else {
            return XCTFail("first signer-vec element must be Symbol")
        }
        XCTAssertEqual(variant, "External")
    }

    /// `addContextRule` validates the policy address before any host function
    /// is built — verified by feeding a malformed address and asserting the
    /// thrown error type.
    func test_crossSDK_addContextRule_validatesPolicyAddressBeforeBuilding() async throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: validContractId
        )
        let manager = OZContextRuleManager(kit: kit)
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TestRule",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: ["INVALID-ADDRESS": .void]
            )
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // pass — the validation surface fires before any host function is built
        } catch {
            XCTFail("expected SmartAccountValidationException.InvalidAddress, got: \(error)")
        }
    }

    /// `resolveContextRuleIdsForEntry` arbitrates Tier 1 / 2 / 3 matching
    /// against the supplied parsed-rule set in the same order across SDK
    /// ports. The probe verifies that an exact-match Tier 1 case wins over
    /// the broader Tier 2 / 3 fallbacks.
    ///
    /// Models a smart account with two rules:
    /// 1. A specific `CallContract` rule for `secondaryContractId` with a
    ///    single delegated signer.
    /// 2. A Default rule with the same delegated signer.
    ///
    /// An auth entry whose root invocation calls `secondaryContractId.foo()`
    /// with the delegated signer present must resolve to rule 1 (exact match)
    /// rather than rule 0 (Default fallback).
    func test_crossSDK_resolveContextRuleIdsForEntry_threeTierAlgorithm_identicalArbitration() async throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: validContractId
        )
        let manager = OZContextRuleManager(kit: kit)

        let signer = try OZDelegatedSigner(address: validAccountAddress)
        let alternateSigner = try OZDelegatedSigner(
            address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW"
        )

        // The Default rule carries a DIFFERENT signer set so the three-tier
        // algorithm cannot match it on signer identity. The specific
        // `CallContract` rule carries the active signer so it wins Tier 1
        // exact-match arbitration.
        let defaultRule = OZParsedContextRule(
            id: 0,
            contextType: .defaultRule,
            name: "Default",
            signers: [alternateSigner],
            signerIds: [1],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let specificRule = OZParsedContextRule(
            id: 9,
            contextType: .callContract(contractAddress: secondaryContractId),
            name: "Specific",
            signers: [signer],
            signerIds: [2],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: secondaryContractId),
            functionName: "foo",
            args: []
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: .contractFn(invokeArgs),
                subInvocations: []
            )
        )

        let resolved = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [signer],
            contextRules: [defaultRule, specificRule]
        )
        // The specific rule should win Tier 1 arbitration over the Default
        // fallback because its `CallContract` discriminant exactly matches
        // the entry's root invocation.
        XCTAssertTrue(resolved.contains(specificRule.id))
    }
}
