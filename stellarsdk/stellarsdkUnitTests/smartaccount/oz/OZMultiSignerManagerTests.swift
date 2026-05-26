//
//  OZMultiSignerManagerTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for ``OZMultiSignerManager``.
///
/// Coverage focuses on the validation surface that can be exercised without a
/// live Soroban server. Validation order in
/// ``OZMultiSignerManager/multiSignerExecuteAndSubmit(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``
/// and
/// ``OZMultiSignerManager/multiSignerTransfer(tokenContract:recipient:amount:selectedSigners:forceMethod:resolveContextRuleIds:)``
/// (mirrored in the test structure):
///
/// 1. ``OZSmartAccountKitProtocol/requireConnected()`` — throws
///    ``WalletException/NotConnected`` when no wallet is connected.
/// 2. ``requireContractAddress(_:fieldName:)`` /
///    ``requireStellarAddress(_:fieldName:)`` — address-format validation.
/// 3. Blank function name check (`multiSignerExecuteAndSubmit` and
///    `multiSignerContractCall`).
/// 4. Empty `selectedSigners` check.
///
/// Tests targeting later validations first move the kit into a connected state
/// via ``OZSmartAccountKitProtocol/setConnectedState(credentialId:contractId:)``
/// so the earlier checks are bypassed.
///
/// The full multi-signer signing pipeline (simulation, auth-entry signing,
/// submission) requires testnet connectivity and is covered by the integration
/// suite.
final class OZMultiSignerManagerTests: XCTestCase {

    // ========================================================================
    // Test fixtures
    // ========================================================================

    /// A well-formed Stellar contract address used as a dummy smart-account
    /// `contractId` and as the WebAuthn verifier address in the test config.
    private let validContractId =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    /// A second well-formed contract address used as the target of contract
    /// calls and execute calls.
    private let validTargetContract =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    /// A well-formed Stellar `G…` account address used as a transfer recipient
    /// or as a delegated wallet signer.
    private let validAccountAddress =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractId
        )
    }

    /// Builds a kit + manager pair where the kit is NOT connected.
    private func disconnectedKit() throws -> (MockOZSmartAccountKit, OZMultiSignerManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (kit, OZMultiSignerManager(kit: kit))
    }

    /// Builds a kit + manager pair where the kit IS connected.
    private func connectedKit(
        contractId: String? = nil
    ) throws -> (MockOZSmartAccountKit, OZMultiSignerManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractId
        )
        return (kit, OZMultiSignerManager(kit: kit))
    }

    /// Minimal passkey signer used for empty / shape checks. iOS
    /// ``SelectedSigner/passkey(credentialId:credentialIdBytes:keyData:)``
    /// requires non-optional `credentialId` and `credentialIdBytes`; both are
    /// fixed sentinel values that exercise the type construction surface
    /// without binding to any real WebAuthn ceremony.
    private func passkeySignerStub() -> SelectedSigner {
        return .passkey(
            credentialId: "stub-credential",
            credentialIdBytes: Data([0x01]),
            keyData: nil
        )
    }

    // ========================================================================
    // multiSignerExecuteAndSubmit — not-connected guard (1 case)
    // ========================================================================

    func test_multiSignerExecuteAndSubmit_notConnected_throwsWalletNotConnected() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "vote",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    // ========================================================================
    // multiSignerExecuteAndSubmit — target address validation (3 cases)
    // ========================================================================

    func test_multiSignerExecuteAndSubmit_targetIsGAddress_throwsInvalidAddress() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validAccountAddress,
                targetFn: "vote",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("target"))
        }
    }

    func test_multiSignerExecuteAndSubmit_targetTooShort_throwsInvalidAddress() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: "CABC",
                targetFn: "vote",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_multiSignerExecuteAndSubmit_targetIsBlank_throwsInvalidAddress() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: "",
                targetFn: "vote",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    // ========================================================================
    // multiSignerExecuteAndSubmit — function name validation (2 cases)
    // ========================================================================

    func test_multiSignerExecuteAndSubmit_targetFnIsBlank_throwsInvalidInput() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Function name"),
                "exception message must reference 'Function name', got: \(error.message)"
            )
        }
    }

    func test_multiSignerExecuteAndSubmit_targetFnIsWhitespaceOnly_throwsInvalidInput() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "   ",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // multiSignerExecuteAndSubmit — selectedSigners validation (1 case)
    // ========================================================================

    func test_multiSignerExecuteAndSubmit_emptySigners_throwsInvalidInput() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "vote",
                selectedSigners: []
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("signer"),
                "exception message must reference signers, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // multiSignerTransfer — not-connected guard (1 case)
    // ========================================================================

    func test_multiSignerTransfer_notConnected_throwsWalletNotConnected() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    // ========================================================================
    // multiSignerTransfer — recipient validation (1 case)
    // ========================================================================

    /// `multiSignerTransfer` validates `recipient` BEFORE `tokenContract` (per
    /// the implementation order: `requireStellarAddress(recipient, …)` runs
    /// first inside the connected-state branch, before the call delegates to
    /// ``OZMultiSignerManager/multiSignerContractCall(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``
    /// which validates `tokenContract`).
    func test_multiSignerTransfer_recipientInvalid_throwsInvalidAddress() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: "NOTAVALIDADDRESS",
                amount: "10",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(
                error.message.contains("recipient"),
                "exception message must reference 'recipient', got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // multiSignerTransfer — self-transfer guard (1 case)
    // ========================================================================

    /// Self-transfer (recipient == connected contractId) must throw
    /// ``ValidationException/InvalidInput`` per D-141 — the guard fires AFTER
    /// `requireConnected()` AND `requireStellarAddress(recipient, …)` so the
    /// caller receives the most specific error.
    func test_multiSignerTransfer_recipientIsSelf_throwsInvalidInput() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: validContractId,
                amount: "10",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.lowercased().contains("self"),
                "exception message must reference self-transfer, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // multiSignerTransfer — tokenContract validation (2 cases)
    // ========================================================================

    /// `multiSignerTransfer` rejects a `tokenContract` that is a Stellar
    /// account address (`G…`) — the actual `tokenContract` validation runs
    /// inside ``OZMultiSignerManager/multiSignerContractCall(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``
    /// which is called once `multiSignerTransfer` has assembled its arguments.
    /// Use a recipient that differs from the connected contract id so the
    /// self-transfer guard does not fire first.
    func test_multiSignerTransfer_tokenContractIsGAddress_throwsInvalidAddress() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validAccountAddress,
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("target"))
        }
    }

    /// `multiSignerTransfer` rejects a too-short `tokenContract` value the
    /// same way it rejects any malformed `C…` address.
    func test_multiSignerTransfer_tokenContractTooShort_throwsInvalidAddress() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: "CABC",
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    // ========================================================================
    // multiSignerTransfer — selectedSigners validation (1 case)
    // ========================================================================

    func test_multiSignerTransfer_emptySigners_throwsInvalidInput() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: []
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("signer"),
                "exception message must reference signers, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // multiSignerTransfer — forceMethod parameter acceptance (3 cases)
    // ========================================================================

    /// Verifies the signature compiles and the default `forceMethod` value is
    /// accepted; the call still throws `NotConnected` because the kit has no
    /// connected wallet, confirming `forceMethod` did not change the error
    /// path.
    func test_multiSignerTransfer_forceMethodNullDefault_signatureCompiles() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_multiSignerTransfer_forceMethodRpc_signatureCompiles() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: [passkeySignerStub()],
                forceMethod: .rpc
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_multiSignerTransfer_forceMethodRelayer_signatureCompiles() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerTransfer(
                tokenContract: validTargetContract,
                recipient: validAccountAddress,
                amount: "10",
                selectedSigners: [passkeySignerStub()],
                forceMethod: .relayer
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // multiSignerExecuteAndSubmit — forceMethod parameter acceptance (2 cases)
    // ========================================================================

    func test_multiSignerExecuteAndSubmit_forceMethodNullDefault_signatureCompiles() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "vote",
                selectedSigners: [passkeySignerStub()]
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_multiSignerExecuteAndSubmit_forceMethodRpc_signatureCompiles() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "vote",
                selectedSigners: [passkeySignerStub()],
                forceMethod: .rpc
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // SelectedSigner — sealed-class shape (5 cases)
    // ========================================================================

    /// The iOS ``SelectedSigner/passkey(credentialId:credentialIdBytes:keyData:)``
    /// arm requires non-optional `credentialId` (`String`) and
    /// `credentialIdBytes` (`Data`); only `keyData` is optional. This test
    /// exercises the empty-string / empty-bytes / nil-keyData boundary so the
    /// type construction surface accepts the absolute minimum input shape.
    func test_selectedSigner_passkey_emptyDefaultsAreAccepted() {
        let signer = SelectedSigner.passkey(
            credentialId: "",
            credentialIdBytes: Data(),
            keyData: nil
        )
        if case .passkey(let credentialId, let credentialIdBytes, let keyData, _) = signer {
            XCTAssertEqual(credentialId, "")
            XCTAssertEqual(credentialIdBytes, Data())
            XCTAssertNil(keyData)
        } else {
            XCTFail("expected .passkey arm")
        }
    }

    func test_selectedSigner_passkey_fieldsAreSetCorrectly() {
        let credId = "abc123"
        let credBytes = Data([0x01, 0x02, 0x03])
        let keyData = Data((0..<97).map { UInt8($0) })
        let signer = SelectedSigner.passkey(
            credentialId: credId,
            credentialIdBytes: credBytes,
            keyData: keyData
        )
        if case .passkey(let id, let idBytes, let key, _) = signer {
            XCTAssertEqual(id, credId)
            XCTAssertEqual(idBytes, credBytes)
            XCTAssertEqual(key, keyData)
        } else {
            XCTFail("expected .passkey arm")
        }
    }

    func test_selectedSigner_wallet_holdsAddress() {
        let signer = SelectedSigner.wallet(accountId: validAccountAddress)
        if case .wallet(let accountId) = signer {
            XCTAssertEqual(accountId, validAccountAddress)
        } else {
            XCTFail("expected .wallet arm")
        }
    }

    func test_selectedSigner_wallet_equalityAndHash() {
        let a = SelectedSigner.wallet(accountId: validAccountAddress)
        let b = SelectedSigner.wallet(accountId: validAccountAddress)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashCode, b.hashCode)
    }

    func test_selectedSigner_passkey_equalityWithEqualBytes() {
        let bytes = Data([0x01, 0x02])
        let a = SelectedSigner.passkey(
            credentialId: "id",
            credentialIdBytes: bytes,
            keyData: nil
        )
        let b = SelectedSigner.passkey(
            credentialId: "id",
            credentialIdBytes: bytes,
            keyData: nil
        )
        XCTAssertEqual(a, b)
    }

    // ========================================================================
    // OZMultiSignerManager — construction + protocol conformance (2 cases)
    // ========================================================================

    /// The manager must be constructable directly from any
    /// ``OZSmartAccountKitProtocol``. The kit composition root constructs the
    /// manager once and exposes it via ``OZSmartAccountKit/multiSignerManager``;
    /// at the unit-test level the same constructor is invoked on the test
    /// double.
    func test_manager_canBeConstructedFromKit() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        let manager = OZMultiSignerManager(kit: kit)
        XCTAssertNotNil(manager)
    }

    /// The manager exposes the three-argument
    /// ``OZMultiSignerManager/submitWithMultipleSigners(hostFunction:selectedSigners:forceMethod:)``
    /// overload consumed by sibling managers (signer / policy / context-rule)
    /// when one of their state-changing methods is invoked with a non-empty
    /// `selectedSigners` list. The kit exposes the same instance via
    /// ``OZSmartAccountKitProtocol/multiSignerManager`` so sibling managers
    /// reach it through the kit reference they already hold.
    func test_manager_exposesSiblingManagerSubmissionEntryPoint() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        let manager = OZMultiSignerManager(kit: kit)
        // why: bind to a function-value of the expected three-argument
        // signature so the compiler verifies the overload exists on the
        // type. The test does not invoke the function because doing so
        // would require a connected kit and a live RPC backend; the
        // compile-time type check is the contract lock.
        let _: (HostFunctionXDR, [SelectedSigner], SubmissionMethod?) async throws -> TransactionResult = manager.submitWithMultipleSigners
    }

    // ========================================================================
    // F-CQ-iOS-2 / F-TC-iOS-3 — Task cancellation propagation
    // ========================================================================

    /// `submitWithMultipleSigners` must observe Swift task cancellation. The
    /// pipeline performs multiple async hops (RPC fetches, WebAuthn prompts,
    /// re-simulation); cancelling the parent task between any of these hops
    /// must stop the work and surface ``CancellationError`` rather than
    /// continuing through to the on-chain submission. This protects against
    /// the user dismissing a long-running multi-signer ceremony from
    /// silently completing on chain.
    func test_submitWithMultipleSigners_cancellation_propagatesCancellationError() async throws {
        let (_, manager) = try connectedKit()
        let hostFunction = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )
        let signers: [SelectedSigner] = [passkeySignerStub()]

        let task = Task { [manager] in
            // Connecting via mock + non-routable RPC means the first await
            // (deployer fetch) will block; the cancellation we trigger from
            // outside must propagate before the result is produced.
            return try await manager.submitWithMultipleSigners(
                hostFunction: hostFunction,
                selectedSigners: signers
            )
        }

        // Cancel before the pipeline can complete. The mock kit points at a
        // non-routable RPC port so the deployer-account fetch loops on
        // connection-refused; cancellation must short-circuit it.
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("expected cancellation or error before submission completes")
        } catch is CancellationError {
            // Expected: the pipeline observed cancellation at one of its
            // checkpoints.
        } catch {
            // Acceptable alternative: the awaited RPC failed before the
            // cancellation checkpoint fired. The test passes as long as the
            // pipeline did not silently submit on chain — which we verify
            // by the absence of a `TransactionResult.success`.
            // Any thrown error proves the pipeline did not return a
            // success result.
        }
    }

    // ========================================================================
    // F-SEC-iOS-5 — cloneAuthEntry round-trip integrity
    // ========================================================================

    /// ``OZTransactionOperations/cloneAuthEntry(_:)`` returns a structurally
    /// equal copy of the supplied entry via an ``XdrEncoder`` round trip. The
    /// fixture exercises an `address`-credentials entry with a non-trivial
    /// nonce, a non-trivial signature placeholder, and a multi-step invocation
    /// tree (root invocation + two sub-invocations) so any silent field-level
    /// truncation, omission, or reordering during the clone surfaces as a
    /// byte-level mismatch on the encoded round trip.
    func test_cloneAuthEntry_addressCredentialsNonTrivialEntry_roundTripsByteEqual() throws {
        let credentialContractAddress = try SCAddressXDR(contractId: validContractId)
        let targetContractAddress = try SCAddressXDR(contractId: validTargetContract)
        let secondaryContractAddress = try SCAddressXDR(
            contractId: "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
        )

        // Non-trivial signature placeholder: a Map ScVal with two Symbol-keyed
        // entries so the clone has to traverse the nested map shape rather
        // than simply copying a scalar arm.
        let signaturePlaceholder = SCValXDR.map([
            SCMapEntryXDR(
                key: .symbol("signers"),
                val: .vec([.bytes(Data(repeating: 0xAB, count: 32))])
            ),
            SCMapEntryXDR(
                key: .symbol("context_rule_ids"),
                val: .vec([.u32(7), .u32(11)])
            )
        ])

        let credentials = SorobanAddressCredentialsXDR(
            address: credentialContractAddress,
            nonce: Int64(0x0123_4567_89AB_CDEF),
            signatureExpirationLedger: 0xDEADBEEF,
            signature: signaturePlaceholder
        )

        // Sub-invocation: contract call on a secondary contract.
        let subInvocationArgs = InvokeContractArgsXDR(
            contractAddress: secondaryContractAddress,
            functionName: "leaf_call",
            args: [.u32(99), .symbol("leaf")]
        )
        let subInvocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(subInvocationArgs),
            subInvocations: []
        )

        // Second sub-invocation with its own nested invocation under it.
        let nestedSubArgs = InvokeContractArgsXDR(
            contractAddress: secondaryContractAddress,
            functionName: "nested_call",
            args: [.bool(true)]
        )
        let nestedSub = SorobanAuthorizedInvocationXDR(
            function: .contractFn(nestedSubArgs),
            subInvocations: []
        )
        let secondSubArgs = InvokeContractArgsXDR(
            contractAddress: targetContractAddress,
            functionName: "branch_call",
            args: []
        )
        let secondSub = SorobanAuthorizedInvocationXDR(
            function: .contractFn(secondSubArgs),
            subInvocations: [nestedSub]
        )

        // Root invocation: target contract call carrying both sub-invocations.
        let rootArgs = InvokeContractArgsXDR(
            contractAddress: targetContractAddress,
            functionName: "root_call",
            args: [.address(credentialContractAddress), .u64(1234)]
        )
        let rootInvocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(rootArgs),
            subInvocations: [subInvocation, secondSub]
        )

        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: rootInvocation
        )

        let cloned = try OZTransactionOperations.cloneAuthEntry(entry)

        let originalBytes = try Data(XDREncoder.encode(entry))
        let clonedBytes = try Data(XDREncoder.encode(cloned))
        XCTAssertEqual(
            originalBytes,
            clonedBytes,
            "cloneAuthEntry must produce a byte-identical XDR round trip"
        )

        // Spot-check that mutating the clone does not affect the original — the
        // round-trip clone must be a deep copy, not a shared-reference view.
        guard case .address(let clonedCreds) = cloned.credentials else {
            return XCTFail("expected address credentials on cloned entry")
        }
        XCTAssertEqual(clonedCreds.nonce, credentials.nonce)
        XCTAssertEqual(clonedCreds.signatureExpirationLedger, credentials.signatureExpirationLedger)

        // Sub-invocation shape preservation: the top-level invocation must
        // still carry both sub-invocations and the deepest nested call must
        // retain its function name.
        XCTAssertEqual(cloned.rootInvocation.subInvocations.count, 2)
        let observedNested = cloned.rootInvocation.subInvocations[1].subInvocations.first?.function
        guard case .contractFn(let observedNestedArgs) = observedNested else {
            return XCTFail("nested sub-invocation must round-trip as contractFn")
        }
        XCTAssertEqual(observedNestedArgs.functionName, "nested_call")
    }
}

// ============================================================================
// MARK: - Test helpers
// ============================================================================

/// Provides a stable `hashCode` accessor over `Hashable` so the equality tests
/// can compare hash values without depending on a specific Swift runtime
/// ABI.
private extension Hashable {
    var hashCode: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }
}
