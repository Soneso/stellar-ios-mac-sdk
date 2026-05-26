//
//  OZManagerSelectedSignersTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Group F unit tests verifying that the `selectedSigners` and `forceMethod`
/// parameters on ``OZSignerManager``, ``OZPolicyManager``, and
/// ``OZContextRuleManager`` are accepted and routed correctly. Mirrors
/// `ManagerSelectedSignersTest` from the cross-SDK source-of-truth suite.
///
/// These tests cover input-validation paths that do not require a live
/// Soroban server. Each manager method is exercised in two scenarios:
/// - Not connected: throws ``WalletException/NotConnected`` regardless of
///   whether `selectedSigners` is supplied or empty.
/// - Connected with invalid input: throws the appropriate validation error,
///   confirming the method accepted the `selectedSigners` parameter and
///   reached the next validation stage.
///
/// Group J.1 cases at the bottom exercise the multi-signer fanout shape
/// requirement (3-signer mix routing through
/// ``OZSmartAccountKitProtocol/multiSignerManager``).
/// Network-dependent multi-signer signing is covered by integration tests.
final class OZManagerSelectedSignersTests: XCTestCase {

    // ========================================================================
    // MARK: - Fixtures
    // ========================================================================

    private let validContractId =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validAccountAddress =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private let validVerifierAddress =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    /// Builds a kit-config suitable for unit tests. The RPC URL points at a
    /// non-routable loopback port so any accidental reach to the network
    /// fails immediately with connection-refused rather than hitting the
    /// public Testnet endpoint.
    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifierAddress
        )
    }

    /// Builds a disconnected mock kit. Every method invocation under test
    /// should throw ``WalletException/NotConnected`` against this kit.
    private func disconnectedKit(
        contextRuleParser: OZContextRuleParser? = nil
    ) throws -> MockOZSmartAccountKit {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.signerManagerOverride = OZSignerManager(
            kit: kit,
            contextRuleParser: contextRuleParser
        )
        kit.policyManagerOverride = OZPolicyManager(kit: kit)
        return kit
    }

    /// Builds a connected mock kit bound to the deterministic test contract id
    /// and credential id pair. Used to verify validation reaches the field
    /// checks after `requireConnected()` succeeds.
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

    /// Builds a context-rule manager bound to the supplied kit. The manager
    /// isn't installed on the kit by default so tests that exercise
    /// context-rule routing instantiate it here.
    private func contextRuleManager(
        for kit: MockOZSmartAccountKit
    ) -> OZContextRuleManager {
        return OZContextRuleManager(kit: kit)
    }

    /// A `SelectedSigner.passkey` stub with empty bytes. Sufficient to drive
    /// the selectedSigners parameter without triggering keyData validation
    /// because every test in this file fails at an earlier validation stage.
    private func passkeySignerStub() -> SelectedSigner {
        return .passkey(
            credentialId: "test",
            credentialIdBytes: Data([0x01]),
            keyData: nil
        )
    }

    /// A `SelectedSigner.wallet` stub for the canonical test G-address.
    private func walletSignerStub() -> SelectedSigner {
        return .wallet(accountId: validAccountAddress)
    }

    /// Two-signer mix used across most Group F cases: a passkey plus a wallet
    /// signer.
    private var multiSigners: [SelectedSigner] {
        return [passkeySignerStub(), walletSignerStub()]
    }

    /// Asserts the supplied closure throws ``WalletException/NotConnected``.
    private func assertNotConnected(
        _ block: () async throws -> Any,
        line: UInt = #line
    ) async {
        do {
            _ = try await block()
            XCTFail("expected WalletException.NotConnected", line: line)
        } catch is WalletException.NotConnected {
            // pass
        } catch {
            XCTFail(
                "expected WalletException.NotConnected, got: \(error)",
                line: line
            )
        }
    }

    /// Asserts the supplied closure throws ``ValidationException/InvalidInput``.
    private func assertInvalidInput(
        _ block: () async throws -> Any,
        line: UInt = #line
    ) async {
        do {
            _ = try await block()
            XCTFail("expected ValidationException.InvalidInput", line: line)
        } catch is ValidationException.InvalidInput {
            // pass
        } catch {
            XCTFail(
                "expected ValidationException.InvalidInput, got: \(error)",
                line: line
            )
        }
    }

    /// Asserts the supplied closure throws ``ValidationException/InvalidAddress``.
    private func assertInvalidAddress(
        _ block: () async throws -> Any,
        line: UInt = #line
    ) async {
        do {
            _ = try await block()
            XCTFail("expected ValidationException.InvalidAddress", line: line)
        } catch is ValidationException.InvalidAddress {
            // pass
        } catch {
            XCTFail(
                "expected ValidationException.InvalidAddress, got: \(error)",
                line: line
            )
        }
    }

    // ========================================================================
    // MARK: - OZSignerManager.addDelegated — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected`` even
    /// when `selectedSigners` is populated.
    func test_addDelegated_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.addDelegated(
                contextRuleId: 0,
                address: self.validAccountAddress,
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Connected kit with a malformed address must reach the address
    /// validation stage and surface ``ValidationException/InvalidAddress``.
    func test_addDelegated_connected_withSelectedSigners_reachesAddressValidation() async throws {
        let kit = try connectedKit()
        await assertInvalidAddress {
            try await kit.signerManager.addDelegated(
                contextRuleId: 0,
                address: "INVALID",
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZSignerManager.addEd25519 — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected``.
    func test_addEd25519_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.addEd25519(
                contextRuleId: 0,
                verifierAddress: self.validVerifierAddress,
                publicKey: Data(count: 32),
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Connected kit with a wrong-sized public key must reach the key-size
    /// validation stage.
    func test_addEd25519_connected_withSelectedSigners_reachesKeyValidation() async throws {
        let kit = try connectedKit()
        await assertInvalidInput {
            try await kit.signerManager.addEd25519(
                contextRuleId: 0,
                verifierAddress: self.validVerifierAddress,
                publicKey: Data(count: 10),
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZSignerManager.addPasskey — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected`` from
    /// `addPasskey` regardless of the public-key shape.
    func test_addPasskey_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.addPasskey(
                contextRuleId: 0,
                publicKey: Data(count: 65),
                credentialId: Data(count: 16),
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Connected kit with a wrong-sized public key must reach the key-size
    /// validation stage.
    func test_addPasskey_connected_withSelectedSigners_reachesKeyValidation() async throws {
        let kit = try connectedKit()
        await assertInvalidInput {
            try await kit.signerManager.addPasskey(
                contextRuleId: 0,
                publicKey: Data(count: 10),
                credentialId: Data(count: 16),
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZSignerManager.removeSigner — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected``.
    func test_removeSigner_byId_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.removeSigner(
                contextRuleId: 0,
                signerId: 1,
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Disconnected kit must surface ``WalletException/NotConnected`` from
    /// the value-based remove overload.
    func test_removeSignerBySigner_notConnected_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        let signer = try OZDelegatedSigner(address: validAccountAddress)
        await assertNotConnected {
            try await kit.signerManager.removeSignerBySigner(
                contextRuleId: 0,
                signer: signer,
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZPolicyManager.addPolicy — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected``.
    func test_addPolicy_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.policyManager.addPolicy(
                contextRuleId: 0,
                policyAddress: self.validContractId,
                installParams: .void,
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Connected kit with a malformed policy address must reach the address
    /// validation stage.
    func test_addPolicy_connected_withSelectedSigners_reachesAddressValidation() async throws {
        let kit = try connectedKit()
        await assertInvalidAddress {
            try await kit.policyManager.addPolicy(
                contextRuleId: 0,
                policyAddress: "INVALID",
                installParams: .void,
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZPolicyManager.removePolicy — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected``.
    func test_removePolicy_byId_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.policyManager.removePolicy(
                contextRuleId: 0,
                policyId: 1,
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Address-based remove overload accepts the `selectedSigners` parameter
    /// and surfaces a ``ValidationException/InvalidInput`` from the address
    /// resolution stage when the rule cannot be located against the disconnected
    /// kit's empty stub context-rule manager. The iOS pipeline performs the
    /// rule-id resolution before the connected-state check, so the surfaced
    /// error names the missing rule rather than the missing wallet.
    func test_removePolicyByAddress_notConnected_reachesContextRuleResolution() async throws {
        let kit = try disconnectedKit()
        await assertInvalidInput {
            try await kit.policyManager.removePolicyByAddress(
                contextRuleId: 0,
                policyAddress: self.validContractId,
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZContextRuleManager.updateName — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected``.
    func test_updateName_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.updateName(
                id: 0,
                name: "New Name",
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Connected kit with an empty name must reach the input validation stage.
    func test_updateName_connected_withSelectedSigners_reachesInputValidation() async throws {
        let kit = try connectedKit()
        let manager = contextRuleManager(for: kit)
        await assertInvalidInput {
            try await manager.updateName(
                id: 0,
                name: "",
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZContextRuleManager.updateValidUntil — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected``.
    func test_updateValidUntil_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.updateValidUntil(
                id: 0,
                validUntil: 100,
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - OZSignerManager.addNewPasskeySigner — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected`` from the
    /// composite `addNewPasskeySigner` flow before any WebAuthn ceremony runs.
    func test_addNewPasskeySigner_notConnected_withSelectedSigners_throwsNotConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.addNewPasskeySigner(
                contextRuleId: 0,
                userName: "test",
                selectedSigners: self.multiSigners
            )
        }
    }

    // ========================================================================
    // MARK: - Default `selectedSigners` parameter (empty list)
    // ========================================================================

    /// Calling `addDelegated` without `selectedSigners` must compile and use
    /// the empty-list default.
    func test_addDelegated_defaultSelectedSigners_isEmptyList() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.addDelegated(
                contextRuleId: 0,
                address: self.validAccountAddress
            )
        }
    }

    /// Calling `removeSigner` without `selectedSigners` must compile and use
    /// the empty-list default.
    func test_removeSigner_defaultSelectedSigners_isEmptyList() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.removeSigner(
                contextRuleId: 0,
                signerId: 1
            )
        }
    }

    /// Calling `addPolicy` without `selectedSigners` must compile and use the
    /// empty-list default.
    func test_addPolicy_defaultSelectedSigners_isEmptyList() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.policyManager.addPolicy(
                contextRuleId: 0,
                policyAddress: self.validContractId,
                installParams: .void
            )
        }
    }

    /// Calling `removePolicy(id:)` without `selectedSigners` must compile and
    /// use the empty-list default.
    func test_removePolicy_defaultSelectedSigners_isEmptyList() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.policyManager.removePolicy(
                contextRuleId: 0,
                policyId: 1
            )
        }
    }

    /// Calling `updateName` without `selectedSigners` must compile and use the
    /// empty-list default.
    func test_updateName_defaultSelectedSigners_isEmptyList() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.updateName(id: 0, name: "Test")
        }
    }

    /// Calling `updateValidUntil` without `selectedSigners` must compile and
    /// use the empty-list default.
    func test_updateValidUntil_defaultSelectedSigners_isEmptyList() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.updateValidUntil(id: 0, validUntil: 100)
        }
    }

    // ========================================================================
    // MARK: - OZContextRuleManager.addContextRule — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected`` from
    /// `addContextRule` regardless of `selectedSigners`.
    func test_addContextRule_withSelectedSigners_notConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TestRule",
                signers: [],
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Calling `addContextRule` without `selectedSigners` must compile and
    /// use the empty-list default.
    func test_addContextRule_defaultSelectedSigners() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TestRule",
                signers: []
            )
        }
    }

    // ========================================================================
    // MARK: - OZContextRuleManager.removeContextRule — selectedSigners
    // ========================================================================

    /// Disconnected kit must surface ``WalletException/NotConnected`` from
    /// `removeContextRule` regardless of `selectedSigners`.
    func test_removeContextRule_withSelectedSigners_notConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.removeContextRule(
                id: 0,
                selectedSigners: self.multiSigners
            )
        }
    }

    /// Calling `removeContextRule` without `selectedSigners` must compile and
    /// use the empty-list default.
    func test_removeContextRule_defaultSelectedSigners() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.removeContextRule(id: 0)
        }
    }

    // ========================================================================
    // MARK: - forceMethod parameter — accepted by manager methods
    // ========================================================================

    /// `addDelegated` accepts `forceMethod` and routes correctly while still
    /// surfacing ``WalletException/NotConnected`` from the disconnected kit.
    func test_addDelegated_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.addDelegated(
                contextRuleId: 0,
                address: self.validAccountAddress,
                forceMethod: .rpc
            )
        }
    }

    /// `removePolicy(id:)` accepts `forceMethod`.
    func test_removePolicy_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.policyManager.removePolicy(
                contextRuleId: 0,
                policyId: 1,
                forceMethod: .rpc
            )
        }
    }

    /// `updateName` accepts the default `forceMethod` (`nil`).
    func test_updateName_defaultForceMethod() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.updateName(id: 0, name: "Test")
        }
    }

    /// `addContextRule` accepts `forceMethod`.
    func test_addContextRule_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TestRule",
                signers: [],
                forceMethod: .relayer
            )
        }
    }

    /// `removeContextRule` accepts `forceMethod`.
    func test_removeContextRule_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.removeContextRule(id: 0, forceMethod: .rpc)
        }
    }

    /// `removeSigner(id:)` accepts `forceMethod`.
    func test_removeSigner_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.signerManager.removeSigner(
                contextRuleId: 0,
                signerId: 1,
                forceMethod: .rpc
            )
        }
    }

    /// `updateValidUntil` accepts `forceMethod`.
    func test_updateValidUntil_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        let manager = contextRuleManager(for: kit)
        await assertNotConnected {
            try await manager.updateValidUntil(
                id: 0,
                validUntil: 100,
                forceMethod: .relayer
            )
        }
    }

    /// `addSpendingLimit` accepts `forceMethod`.
    func test_addSpendingLimit_withForceMethod_notConnected() async throws {
        let kit = try disconnectedKit()
        await assertNotConnected {
            try await kit.policyManager.addSpendingLimit(
                contextRuleId: 0,
                policyAddress: self.validContractId,
                spendingLimit: "100",
                periodLedgers: 17_280,
                forceMethod: .rpc
            )
        }
    }

    // ========================================================================
    // MARK: - Group J.1 — multi-signer fanout (3-signer mix)
    // ========================================================================

    /// Three-signer mix routes through the multi-signer submitter when the
    /// caller passes a non-empty `selectedSigners` list.
    ///
    /// Verifies that ``OZSignerManager`` forwards the host function and the
    /// full three-entry signer list to
    /// ``OZSmartAccountKitProtocol/multiSignerManager`` rather than going
    /// through the kit's transaction operations directly.
    func test_submitWithMultipleSigners_threeSigners_passkey_delegated_ed25519_collectsAllSignatures() async throws {
        let kit = try connectedKit()
        let recordingSubmitter = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recordingSubmitter

        let firstPasskey = SelectedSigner.passkey(
            credentialId: "cred-A",
            credentialIdBytes: Data([0x0A, 0x0A]),
            keyData: Data(repeating: 0xAA, count: 65)
        )
        let walletEntry = SelectedSigner.wallet(accountId: validAccountAddress)
        let secondPasskey = SelectedSigner.passkey(
            credentialId: "cred-B",
            credentialIdBytes: Data([0x0B, 0x0B]),
            keyData: Data(repeating: 0xBB, count: 65)
        )
        let signers: [SelectedSigner] = [firstPasskey, walletEntry, secondPasskey]

        let result = try await kit.signerManager.addDelegated(
            contextRuleId: 0,
            address: validAccountAddress,
            selectedSigners: signers
        )

        XCTAssertTrue(result.success)
        XCTAssertEqual(recordingSubmitter.invocations.count, 1)
        let recorded = recordingSubmitter.invocations[0]
        XCTAssertEqual(recorded.selectedSigners.count, 3)
        XCTAssertEqual(recorded.selectedSigners, signers)
    }

    /// Mixed passkey + wallet selectedSigners both reach the multi-signer
    /// submitter; the passkey-key-data and wallet-address shapes are
    /// preserved end-to-end.
    func test_submitWithMultipleSigners_passkey_plus_wallet_resolvesContextRulesForBothSignerKinds() async throws {
        let kit = try connectedKit()
        let recordingSubmitter = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recordingSubmitter

        let signers: [SelectedSigner] = [
            .passkey(
                credentialId: "cred-A",
                credentialIdBytes: Data([0x01]),
                keyData: Data(repeating: 0x11, count: 65)
            ),
            .wallet(accountId: validAccountAddress)
        ]

        _ = try await kit.policyManager.addSimpleThreshold(
            contextRuleId: 0,
            policyAddress: validContractId,
            threshold: 2,
            selectedSigners: signers
        )

        XCTAssertEqual(recordingSubmitter.invocations.count, 1)
        let recorded = recordingSubmitter.invocations[0]
        XCTAssertEqual(recorded.selectedSigners.count, 2)
        guard case .passkey(let cid, let cidBytes, let keyData, _) = recorded.selectedSigners[0] else {
            return XCTFail("first signer must remain a passkey entry")
        }
        XCTAssertEqual(cid, "cred-A")
        XCTAssertEqual(cidBytes, Data([0x01]))
        XCTAssertEqual(keyData, Data(repeating: 0x11, count: 65))
        guard case .wallet(let accountId) = recorded.selectedSigners[1] else {
            return XCTFail("second signer must remain a wallet entry")
        }
        XCTAssertEqual(accountId, validAccountAddress)
    }

    /// When the multi-signer submitter throws partway through a three-signer
    /// ceremony, the manager surfaces the error without further routing.
    /// Models the behavior expected when a single signer cancels the ceremony
    /// (the submitter detects it and throws).
    func test_submitWithMultipleSigners_threeSigners_oneCancelled_failsFastNoFurtherPrompts() async throws {
        let kit = try connectedKit()
        let recordingSubmitter = MockOZMultiSignerManager(kit: kit)
        recordingSubmitter.throwOnSubmit = WebAuthnException.Cancelled(
            message: "User cancelled"
        )
        kit.multiSignerManagerOverride = recordingSubmitter

        let signers: [SelectedSigner] = [
            passkeySignerStub(),
            walletSignerStub(),
            passkeySignerStub()
        ]

        do {
            _ = try await kit.signerManager.addDelegated(
                contextRuleId: 0,
                address: validAccountAddress,
                selectedSigners: signers
            )
            XCTFail("expected WebAuthnException.Cancelled")
        } catch is WebAuthnException.Cancelled {
            // pass
        } catch {
            XCTFail("expected WebAuthnException.Cancelled, got: \(error)")
        }
        XCTAssertEqual(recordingSubmitter.invocations.count, 1)
    }

    // ========================================================================
    // SelectedSigner.passkey transport propagation
    // ========================================================================

    /// `SelectedSigner.passkey` carries optional `transports` hints that must
    /// flow through the multi-signer pipeline unchanged. The recording
    /// submitter captures the signer set received by the manager so we can
    /// confirm that the transport list is preserved across the routing hop.
    /// The downstream `AllowCredential` propagation is verified at the
    /// signing-pipeline integration layer; here we lock down the routing
    /// fidelity that the public `SelectedSigner` shape promises.
    func test_selectedSigner_passkey_transports_propagatesThroughRouting() async throws {
        let kit = try connectedKit()
        let recordingSubmitter = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recordingSubmitter

        let transports: [String] = ["internal", "hybrid"]
        let signers: [SelectedSigner] = [
            .passkey(
                credentialId: "cred-with-transports",
                credentialIdBytes: Data([0x01, 0x02]),
                keyData: Data(repeating: 0xAA, count: 65),
                transports: transports
            )
        ]

        _ = try await kit.policyManager.addSimpleThreshold(
            contextRuleId: 0,
            policyAddress: validContractId,
            threshold: 1,
            selectedSigners: signers
        )

        XCTAssertEqual(recordingSubmitter.invocations.count, 1)
        let recorded = recordingSubmitter.invocations[0]
        XCTAssertEqual(recorded.selectedSigners.count, 1)

        guard case .passkey(_, _, _, let recordedTransports) = recorded.selectedSigners[0] else {
            return XCTFail("first signer must remain a passkey entry")
        }
        XCTAssertEqual(
            recordedTransports,
            transports,
            "transports list must propagate verbatim through the routing hop"
        )
    }
}
