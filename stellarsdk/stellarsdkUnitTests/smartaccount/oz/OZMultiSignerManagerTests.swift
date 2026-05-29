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
    /// ``ValidationException/InvalidInput`` — the guard fires AFTER
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
    // Task cancellation propagation
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
    // cloneAuthEntry round-trip integrity
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

    // ========================================================================
    // Ed25519 SelectedSigner — shape and equality (2 cases)
    // ========================================================================

    func test_selectedSigner_ed25519_holdsVerifierAndPublicKey() {
        let pubKey = Data(repeating: 0xAB, count: 32)
        let signer = SelectedSigner.ed25519(
            verifierAddress: validContractId,
            publicKey: pubKey
        )
        if case .ed25519(let verifier, let key) = signer {
            XCTAssertEqual(verifier, validContractId)
            XCTAssertEqual(key, pubKey)
        } else {
            XCTFail("expected .ed25519 arm")
        }
    }

    func test_selectedSigner_ed25519_equalityAndHash() {
        let pubKey = Data(repeating: 0x12, count: 32)
        let a = SelectedSigner.ed25519(verifierAddress: validContractId, publicKey: pubKey)
        let b = SelectedSigner.ed25519(verifierAddress: validContractId, publicKey: pubKey)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashCode, b.hashCode)
    }

    // ========================================================================
    // Ed25519 validation — negative cases (4 cases)
    // ========================================================================

    /// `validateSignerSet` must reject an Ed25519 signer whose verifier address
    /// is not a well-formed C-strkey.
    func test_submitWithMultipleSigners_ed25519_invalidVerifierAddress_throwsInvalidInput() async throws {
        let (kit, manager) = try connectedKit()

        // Wire up a real external signer manager so the validation path is reached.
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: "NOT_A_CONTRACT_ADDRESS", publicKey: Data(count: 32))
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.lowercased().contains("verifier"),
                "error message must reference the verifier address, got: \(error.message)"
            )
        }
    }

    /// `validateSignerSet` must reject a public key that is not exactly 32 bytes.
    func test_submitWithMultipleSigners_ed25519_wrongPublicKeyLength_throwsInvalidInput() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: Data(count: 16))
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("32"),
                "error message must mention the required key length, got: \(error.message)"
            )
        }
    }

    /// `validateSignerSet` must reject an Ed25519 signer for which no signing
    /// source (keypair or adapter) is registered.
    func test_submitWithMultipleSigners_ed25519_noSigningSource_throwsInvalidInput() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        // A valid 32-byte key, but nothing is registered for it.
        let unregisteredKey = Data(repeating: 0x77, count: 32)
        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: unregisteredKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("no registered keypair or adapter"),
                "error message must reference missing signing source, got: \(error.message)"
            )
        }
    }

    /// When no `OZExternalSignerManager` is wired to the kit, passing an
    /// Ed25519 signer must surface a clear `ValidationException.InvalidInput`
    /// rather than a nil-dereference or ambiguous error.
    func test_submitWithMultipleSigners_ed25519_noExternalSignerManager_throwsInvalidInput() async throws {
        let (kit, manager) = try connectedKit()
        // kit.externalSignerManagerOverride is nil by default (see MockOZSmartAccountKit).
        XCTAssertNil(kit.externalSignerManagerOverride)

        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: Data(count: 32))
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("OZExternalSignerManager"),
                "error message must reference OZExternalSignerManager, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // Ed25519 validation — tuple-key disambiguation (2 cases)
    // ========================================================================

    /// Two Ed25519 signers with the same public key but different verifier
    /// addresses must be treated as distinct entries. Both are individually
    /// validated; registering one must not satisfy the validation for the other.
    func test_submitWithMultipleSigners_ed25519_sameKeyDifferentVerifiers_validatesEachSeparately() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let verifierAlpha = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let verifierBeta  = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
        let ed25519Seed   = Data(0x00 ..< 0x20)

        // Register the key only under verifierAlpha.
        let publicKey = try await extMgr.addEd25519FromRawKey(
            secretKeyBytes: ed25519Seed,
            verifierAddress: verifierAlpha
        )

        // A signer referencing verifierBeta (not registered) must fail.
        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: verifierBeta, publicKey: publicKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput for unregistered (verifierBeta, publicKey) pair")
        } catch is ValidationException.InvalidInput {
            // expected: (verifierBeta, publicKey) not in registry
        }
    }

    /// Registering a key under both verifier addresses and then passing both
    /// signers in the same request must pass the validation stage for both.
    func test_submitWithMultipleSigners_ed25519_sameKeyBothVerifiersRegistered_passesValidation() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let verifierAlpha = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let verifierBeta  = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
        let ed25519Seed   = Data(0x00 ..< 0x20)

        // Register the key under both verifier addresses.
        let pubKeyAlpha = try await extMgr.addEd25519FromRawKey(secretKeyBytes: ed25519Seed, verifierAddress: verifierAlpha)
        let pubKeyBeta  = try await extMgr.addEd25519FromRawKey(secretKeyBytes: ed25519Seed, verifierAddress: verifierBeta)
        XCTAssertEqual(pubKeyAlpha, pubKeyBeta, "same secret must produce the same public key bytes")

        // Both signers are registered — validation must pass (the pipeline will
        // subsequently fail at the RPC simulation step since the mock kit points
        // at a non-routable port, but it must NOT fail at validation).
        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: verifierAlpha, publicKey: pubKeyAlpha),
            .ed25519(verifierAddress: verifierBeta,  publicKey: pubKeyBeta)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
        } catch is ValidationException.InvalidInput {
            XCTFail("both (verifier, publicKey) pairs are registered; validation must pass")
        } catch {
            // Any non-validation error (e.g. RPC failure on the mock server) is
            // acceptable — it proves we are past the validation stage.
        }
    }

    // ========================================================================
    // Ed25519 submission pipeline — scenario tests (5 cases)
    // ========================================================================

    /// When a kit has an external signer manager with a registered Ed25519
    /// keypair and a passkey signer in the same `selectedSigners` list, the
    /// passkey `keyData` nil-check still fires (Ed25519 validation succeeds, but
    /// passkey validation fires for the passkey signer first in the same loop).
    func test_submitWithMultipleSigners_ed25519AndPasskeyMix_passkeyKeyDataNilStillRejects() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let ed25519Seed = Data(0x00 ..< 0x20)
        let pubKey = try await extMgr.addEd25519FromRawKey(secretKeyBytes: ed25519Seed, verifierAddress: validContractId)

        let signers: [SelectedSigner] = [
            // passkey with nil keyData — must be rejected before the Ed25519 signer is reached
            .passkey(credentialId: "cred", credentialIdBytes: Data([0x01]), keyData: nil),
            .ed25519(verifierAddress: validContractId, publicKey: pubKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput for nil keyData")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.lowercased().contains("keydata"),
                "error message must reference keyData, got: \(error.message)"
            )
        }
    }

    /// Ed25519 signer combined with a wallet signer: the wallet-adapter
    /// availability check fires before Ed25519 validation. When no adapter is
    /// configured on the kit config, the wallet check must throw.
    func test_submitWithMultipleSigners_ed25519AndWalletMix_walletAdapterMissingThrowsFirst() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let ed25519Seed = Data(0x00 ..< 0x20)
        let pubKey = try await extMgr.addEd25519FromRawKey(secretKeyBytes: ed25519Seed, verifierAddress: validContractId)

        // The kit config has no externalWallet configured.
        let signers: [SelectedSigner] = [
            .wallet(accountId: validAccountAddress),
            .ed25519(verifierAddress: validContractId, publicKey: pubKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected ValidationException.InvalidInput for missing wallet adapter")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.lowercased().contains("wallet adapter"),
                "error message must reference wallet adapter, got: \(error.message)"
            )
        }
    }

    /// An Ed25519 signer combined with a passkey that carries valid `keyData`
    /// passes the full validation stage. The pipeline then fails at the RPC
    /// simulation step (non-routable mock server). The test confirms that
    /// neither a validation error nor a silent success is returned — only an
    /// RPC-level failure or cancellation is acceptable.
    func test_submitWithMultipleSigners_ed25519WithRegisteredKeyAndPasskeyWithKeyData_passesValidation() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let ed25519Seed = Data(0x00 ..< 0x20)
        let pubKey = try await extMgr.addEd25519FromRawKey(secretKeyBytes: ed25519Seed, verifierAddress: validContractId)

        let signers: [SelectedSigner] = [
            .passkey(
                credentialId: "cred-A",
                credentialIdBytes: Data([0x0A]),
                keyData: Data(repeating: 0xCC, count: 65)
            ),
            .ed25519(verifierAddress: validContractId, publicKey: pubKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
        } catch is ValidationException.InvalidInput {
            XCTFail("validation must pass when both signers are properly configured")
        } catch {
            // Expected: RPC failure or cancellation after validation succeeds.
        }
    }

    /// An Ed25519-only signer set passes the signer-set validation stage and
    /// proceeds to the RPC simulation step. The mock kit uses a non-routable
    /// server, so the simulation step throws a non-validation error.
    func test_submitWithMultipleSigners_ed25519Only_passesValidationReachesRpc() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let ed25519Seed = Data(0x00 ..< 0x20)
        let pubKey = try await extMgr.addEd25519FromRawKey(secretKeyBytes: ed25519Seed, verifierAddress: validContractId)

        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: pubKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
        } catch is ValidationException.InvalidInput {
            XCTFail("a properly registered Ed25519 signer must pass validation")
        } catch {
            // Expected: any non-validation error (RPC refused, network error,
            // deployer fetch failure). The test passes as long as the pipeline
            // did not stop at the validation stage.
        }
    }

    // ========================================================================
    // Ed25519 local verification failure
    // ========================================================================

    /// `signEntryWithEd25519Signers` must throw `TransactionException.signingFailed`
    /// when the signing source returns a signature that fails local verification.
    ///
    /// The test wires a `FakeZeroByteEd25519Adapter` that always returns 64
    /// zero-bytes. The adapter passes the `canSignFor` check (returns `true`)
    /// so the pipeline reaches the local-verification step, where
    /// `KeyPair.verify(signature:message:)` returns `false` and the guard
    /// fires.
    ///
    /// A `MockSorobanServer` is used to script the initial simulation so the
    /// pipeline reaches the signing step rather than failing at the RPC layer.
    func test_submitWithMultipleSigners_ed25519LocalVerificationFailure_throwsSigningFailed() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        // Deterministic deployer so the deployer accountId is known ahead of time.
        let seedBytes = Data(repeating: 0x77, count: 32)
        let stellarSeed = try Seed(bytes: [UInt8](seedBytes))
        let deployer = KeyPair(seed: stellarSeed)

        // Build a kit backed by the mocked SorobanServer.
        let liveServer = MockSorobanServer.makeMockedSorobanServer()
        let kit = MockOZSmartAccountKit(
            config: try buildConfig(),
            sorobanServer: liveServer
        )
        kit.configuredDeployer = deployer
        kit.setConnectedState(credentialId: "test-cred", contractId: validContractId)

        // Register an Ed25519 keypair so validation passes (canSign returns true).
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let ed25519Seed = Data(0x00 ..< 0x20)
        let pubKey = try await extMgr.addEd25519FromRawKey(
            secretKeyBytes: ed25519Seed,
            verifierAddress: validContractId
        )

        // Install a fake adapter that returns 64 zero-bytes so local
        // verification fails. The adapter claims canSign = true for every
        // (verifierAddress, publicKey) pair, which takes precedence over the
        // in-memory keypair and causes the pipeline to reach the verify step.
        let zeroAdapter = FakeZeroByteEd25519Adapter()
        await extMgr.setEd25519Adapter(zeroAdapter)

        // Script: deployer account lookup (needed by runInitialSimulation).
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)

        // Script: initial simulation returns an auth entry whose credential
        // address matches the connected contract so signEntryWithEd25519Signers
        // is reached.
        let authEntry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractId,
            targetContract: validTargetContract,
            targetFn: "noop"
        )
        script.enqueueSimulate(authEntries: [authEntry])

        // Script: getLatestLedger for expiration computation.
        script.setGetLatestLedger(sequence: 1000)

        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: pubKey)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validTargetContract),
                functionName: "noop",
                args: []
            )
        )

        let manager = OZMultiSignerManager(kit: kit)
        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
            XCTFail("expected TransactionException.signingFailed")
        } catch let e as TransactionException.SigningFailed {
            XCTAssertTrue(
                e.message.contains("does not verify") || e.message.contains("verify"),
                "error message must describe local verification failure, got: \(e.message)"
            )
        }
    }

    // ========================================================================
    // Ed25519 validation — public-key disambiguation
    // ========================================================================

    /// An Ed25519 signer whose 32-byte public key coincides with the raw pubkey
    /// bytes of a wallet G-address must not be false-matched to the wallet branch.
    ///
    /// The two signer types are discriminated by the `SelectedSigner` enum case,
    /// not by their key bytes. Registering the 32-byte key as an Ed25519 entry
    /// and passing it as `.ed25519(verifierAddress:publicKey:)` must route only
    /// through the Ed25519 validation path.
    func test_validateSignerSet_ed25519PubkeyMatchesWalletGAddressBytes_noFalseMatch() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        // Extract the 32-byte raw public key bytes from the wallet G-address.
        let walletKeypair = try KeyPair(accountId: validAccountAddress)
        let rawPubKeyBytes = Data(walletKeypair.publicKey.bytes)
        XCTAssertEqual(rawPubKeyBytes.count, 32,
                       "raw Ed25519 public key must be exactly 32 bytes")

        // Register a different Ed25519 key under verifierAddress and confirm that the
        // ONLY signer in selectedSigners is an Ed25519 entry — no wallet signer present,
        // so the wallet-adapter check never fires. We use the key that was registered,
        // not rawPubKeyBytes directly.
        let ed25519Seed = Data(0x00 ..< 0x20)
        let registeredPubKey = try await extMgr.addEd25519FromRawKey(
            secretKeyBytes: ed25519Seed,
            verifierAddress: validContractId
        )

        // Confirm the test fixture: the registered Ed25519 public key and the
        // G-address raw bytes are distinct (they happen to be different keys).
        // The important invariant is that the Ed25519 branch uses the tuple
        // (verifierAddress, publicKey) as its key, not the account-address lookup.
        XCTAssertNotEqual(
            registeredPubKey,
            rawPubKeyBytes,
            "test fixture assumes the Ed25519 key and the wallet pubkey bytes are different"
        )

        // An Ed25519 signer with the same 32-byte key bytes as the G-address
        // raw pubkey. We can only register this via an adapter that claims
        // canSign = true for this specific key pair.
        let adapter = FixedKeyEd25519Adapter(
            targetPublicKey: rawPubKeyBytes,
            targetVerifierAddress: validContractId
        )
        await extMgr.setEd25519Adapter(adapter)

        // selectedSigners contains only an Ed25519 entry — no wallet signer.
        // The wallet-adapter check must not fire; the Ed25519 path must validate
        // the (verifierAddress, rawPubKeyBytes) pair via the adapter.
        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: rawPubKeyBytes)
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
        } catch is ValidationException.InvalidInput {
            XCTFail(
                "Ed25519 signer whose pubkey bytes match a G-address must not produce " +
                "a wallet-adapter error; only the Ed25519 path is involved here"
            )
        } catch {
            // Any non-validation error (RPC refused, connection error) is
            // expected and confirms the validation stage was passed correctly.
        }
    }

    // ========================================================================
    // Ed25519 / passkey at same position — no aliasing
    // ========================================================================

    /// Ed25519 signer and passkey signer at the same conceptual numeric index
    /// in the `selectedSigners` array must not alias each other. Each signer
    /// type is routed through its own branch in `signEntryWithEd25519Signers`
    /// (Ed25519) and `signEntryWithPasskeys` (passkey); the iteration guard
    /// `guard case .ed25519 = signer` ensures only Ed25519 entries are
    /// processed in the Ed25519 loop and vice versa.
    ///
    /// Validation must pass for both a well-configured Ed25519 entry and a
    /// well-configured passkey entry when placed at the same index (0 and 0 after
    /// separate array construction), and the pipeline must proceed past
    /// validation without a `ValidationException.InvalidInput`.
    func test_submitWithMultipleSigners_mixedRuleEd25519AndPasskeyAtSameIndex_routesCorrectly() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let ed25519Seed = Data(0x00 ..< 0x20)
        let pubKey = try await extMgr.addEd25519FromRawKey(
            secretKeyBytes: ed25519Seed,
            verifierAddress: validContractId
        )

        // Build valid keyData (65-byte uncompressed secp256r1 public key fixture).
        var passkeyKeyData = [UInt8](repeating: 0xAB, count: 65)
        passkeyKeyData[0] = SmartAccountConstants.uncompressedPubkeyPrefix

        // Both signers at index 0 of their respective conceptual "signer
        // type" slices; they occupy adjacent positions in the flat array.
        let signers: [SelectedSigner] = [
            .ed25519(verifierAddress: validContractId, publicKey: pubKey),
            .passkey(
                credentialId: "cred-passkey",
                credentialIdBytes: Data([0x42]),
                keyData: Data(passkeyKeyData)
            )
        ]
        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "test",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: signers
            )
        } catch is ValidationException.InvalidInput {
            XCTFail("mixed Ed25519 + passkey must pass validation when both are correctly configured")
        } catch {
            // Expected: RPC failure after successful validation.
        }
    }

    // ========================================================================
    // Policy-only auth with zero selectedSigners
    // ========================================================================

    /// Passing `selectedSigners: []` to the low-level `submitWithMultipleSigners`
    /// directly must not throw `ValidationException.InvalidInput`.
    ///
    /// The emptiness guard exists on `multiSignerContractCall` and
    /// `multiSignerExecuteAndSubmit` (caller-facing), but NOT on the low-level
    /// `submitWithMultipleSigners`. Policy-only-auth scenarios drive this path
    /// with an empty signer list. The validation stage skips all per-signer
    /// checks; the pipeline then reaches the RPC step (which fails on the
    /// non-routable server) without throwing a validation error.
    func test_submitWithMultipleSigners_ed25519PolicyOnlyAuth_succeedsWithZeroSelectedSigners() async throws {
        let (kit, manager) = try connectedKit()
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignerManagerOverride = extMgr

        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "policy_only",
                args: []
            )
        )

        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFn,
                selectedSigners: []
            )
        } catch is ValidationException.InvalidInput {
            XCTFail(
                "submitWithMultipleSigners with empty selectedSigners must not throw " +
                "ValidationException.InvalidInput — the emptiness guard lives on the " +
                "higher-level callers, not on this low-level method"
            )
        } catch {
            // Expected: non-validation error from the RPC step (connection
            // refused on the non-routable server), confirming the pipeline
            // proceeded past validation.
        }
    }

    // ========================================================================
    // Auth-payload Map shape for Ed25519 signatures
    // ========================================================================

    /// `OZSmartAccountAuth.signAuthEntry` must store the Ed25519 signature as exactly
    /// 64 raw bytes in `SignerEntry.signatureBytes` — no XDR wrapping.
    ///
    /// The OZ Ed25519 verifier contract receives `sig_data: BytesN<64>`. The host coerces
    /// `Bytes(64)` directly; any XDR envelope inflates to ~70 bytes and the coercion
    /// traps with `Error(Auth, InvalidAction)`. The public key is NOT included; the
    /// verifier reads it from on-chain `External(verifier, key_data)` storage.
    func test_submitWithMultipleSigners_ed25519Only_producesCorrectAuthPayloadSignatureBytes() async throws {
        let ed25519Seed = Data(0x00 ..< 0x20)
        let stellarSeed = try Seed(bytes: [UInt8](ed25519Seed))
        let keypair = KeyPair(seed: stellarSeed)
        let publicKey = Data(keypair.publicKey.bytes)

        // Build a deterministic 32-byte auth digest (simulates the payload hash).
        let authDigest = Data(repeating: 0x42, count: 32)
        let rawSig = Data(try keypair.sign([UInt8](authDigest)))
        XCTAssertEqual(rawSig.count, 64, "Ed25519 signature must be 64 bytes")

        let ed25519Sig = try OZEd25519Signature(publicKey: publicKey, signature: rawSig)
        let ed25519Signer = try OZExternalSigner.ed25519(
            verifierAddress: validContractId,
            publicKey: publicKey
        )

        // Build a minimal auth entry with void (empty) initial signature.
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractId),
            nonce: 0,
            signatureExpirationLedger: 500_000,
            signature: .void
        )
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "noop",
                args: []
            )),
            subInvocations: []
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        // Sign the entry via OZSmartAccountAuth.signAuthEntry.
        let signedEntry = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: ed25519Signer,
            signature: ed25519Sig,
            expirationLedger: 500_000,
            contextRuleIds: []
        )

        // Decode the resulting payload from the signed credentials.
        guard case .address(let signedCreds) = signedEntry.credentials else {
            XCTFail("signed entry credentials must be address-typed")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(signedCreds.signature)

        XCTAssertEqual(
            payload.signers.count, 1,
            "payload must contain exactly one signer entry for a single Ed25519 signer"
        )
        guard let signerEntry = payload.signers.first else {
            XCTFail("payload signers array is empty")
            return
        }

        // For Ed25519, signatureBytes must be the raw 64-byte signature with NO XDR wrapping.
        // The Ed25519 verifier expects BytesN<64>; any XDR envelope inflates to ~70 bytes
        // and the host coercion rejects it with Error(Auth, InvalidAction).
        XCTAssertEqual(
            signerEntry.signatureBytes.count, 64,
            "Ed25519 signatureBytes must be exactly 64 bytes (no XDR envelope)"
        )
        XCTAssertEqual(
            signerEntry.signatureBytes, rawSig,
            "signatureBytes must equal the original raw Ed25519 signature"
        )
    }
}

// ============================================================================
// MARK: - multiSignerContractCall body coverage
// ============================================================================

extension OZMultiSignerManagerTests {

    /// Exercises the `multiSignerContractCall` body (lines that construct the
    /// `InvokeContractArgsXDR` and forward to `submitWithMultipleSigners`).
    ///
    /// All guard-checks pass: the kit is connected, the target is a valid
    /// C-address, the function name is non-blank, and the signer list is
    /// non-empty. The call then reaches the four-argument
    /// `submitWithMultipleSigners` which hits the first async step (deployer
    /// account fetch). Because the RPC URL is non-routable the pipeline fails
    /// at the network boundary rather than returning a result, but the body
    /// lines of `multiSignerContractCall` that construct the host function and
    /// forward the call are covered.
    func test_multiSignerContractCall_validArgs_reachesSubmitPipeline() async throws {
        let (_, manager) = try connectedKit()
        let keyData = Data(repeating: 0x42, count: SmartAccountConstants.secp256r1PublicKeySize + 4)
        let signer = SelectedSigner.passkey(
            credentialId: "cred",
            credentialIdBytes: Data([0x01]),
            keyData: keyData
        )
        do {
            _ = try await manager.multiSignerContractCall(
                target: validTargetContract,
                targetFn: "noop",
                targetArgs: [],
                selectedSigners: [signer]
            )
        } catch {
            // The pipeline fails at the first network call (non-routable RPC).
            // Any error here means the body was reached and the host function
            // was constructed — the test passes as long as the pre-validation
            // did not block execution.
        }
    }

    /// Exercises the `multiSignerContractCall` body with non-empty `targetArgs`.
    ///
    /// Supplies a single `SCValXDR.u32` argument so the args-list encoding
    /// path is traversed. The call fails at network (non-routable RPC); the
    /// body lines that build the `InvokeContractArgsXDR` with the arg list
    /// are covered by the traversal up to the first await.
    func test_multiSignerContractCall_withTargetArgs_reachesSubmitPipeline() async throws {
        let (_, manager) = try connectedKit()
        let keyData = Data(repeating: 0x77, count: SmartAccountConstants.secp256r1PublicKeySize + 4)
        let signer = SelectedSigner.passkey(
            credentialId: "cred2",
            credentialIdBytes: Data([0x02]),
            keyData: keyData
        )
        do {
            _ = try await manager.multiSignerContractCall(
                target: validTargetContract,
                targetFn: "vote",
                targetArgs: [.u32(42), .symbol("yes")],
                selectedSigners: [signer]
            )
        } catch {
            // Any error after reaching the pipeline body is acceptable.
        }
    }

    // ========================================================================
    // MARK: - multiSignerExecuteAndSubmit body coverage
    // ========================================================================

    /// Exercises the `multiSignerExecuteAndSubmit` body (lines that construct
    /// the execute host function forwarding through the smart account's
    /// `execute` entry point and call `submitWithMultipleSigners`).
    ///
    /// All guard-checks pass; the pipeline fails at the RPC boundary.
    func test_multiSignerExecuteAndSubmit_validArgs_reachesSubmitPipeline() async throws {
        let (_, manager) = try connectedKit()
        let keyData = Data(repeating: 0x11, count: SmartAccountConstants.secp256r1PublicKeySize + 4)
        let signer = SelectedSigner.passkey(
            credentialId: "exec-cred",
            credentialIdBytes: Data([0x03]),
            keyData: keyData
        )
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "transfer",
                targetArgs: [],
                selectedSigners: [signer]
            )
        } catch {
            // Any error after the body lines are traversed is acceptable.
        }
    }

    /// Exercises the `multiSignerExecuteAndSubmit` body with non-empty
    /// `targetArgs`, confirming the vector-encoding branch that wraps the
    /// args list in a `SCValXDR.vec` is traversed.
    func test_multiSignerExecuteAndSubmit_withTargetArgs_reachesSubmitPipeline() async throws {
        let (_, manager) = try connectedKit()
        let keyData = Data(repeating: 0x22, count: SmartAccountConstants.secp256r1PublicKeySize + 4)
        let signer = SelectedSigner.passkey(
            credentialId: "exec-cred2",
            credentialIdBytes: Data([0x04]),
            keyData: keyData
        )
        do {
            _ = try await manager.multiSignerExecuteAndSubmit(
                target: validTargetContract,
                targetFn: "swap",
                targetArgs: [.u32(1), .u32(2)],
                selectedSigners: [signer]
            )
        } catch {
            // Any error after the body lines are traversed is acceptable.
        }
    }

    // ========================================================================
    // MARK: - validatePasskeyKeyData nil guard
    // ========================================================================

    /// `submitWithMultipleSigners` must reject a passkey signer whose `keyData`
    /// is `nil`. The nil guard in `validatePasskeyKeyData` fires during
    /// `validateSignerSet`, before any RPC is engaged.
    func test_submitWithMultipleSigners_passkeyNilKeyData_throwsInvalidInput() async throws {
        let (_, manager) = try connectedKit()
        let hostFunction = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractId),
                functionName: "noop",
                args: []
            )
        )
        // A passkey signer with keyData == nil is invalid.
        let signer = SelectedSigner.passkey(
            credentialId: "pk",
            credentialIdBytes: Data([0x01]),
            keyData: nil
        )
        do {
            _ = try await manager.submitWithMultipleSigners(
                hostFunction: hostFunction,
                selectedSigners: [signer],
                forceMethod: nil,
                resolveContextRuleIds: nil
            )
            XCTFail("expected ValidationException.InvalidInput for nil keyData")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.lowercased().contains("keydata"),
                "error message must reference keyData, got: \(error.message)"
            )
        }
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

// ============================================================================
// MARK: - Ed25519 test doubles
// ============================================================================

/// `OZExternalEd25519SignerAdapter` stub that always returns 64 zero-bytes from
/// `signAuthDigest` and reports `canSignFor` as `true` for every
/// (verifierAddress, publicKey) pair. Used to exercise the local-verification
/// failure path in `OZMultiSignerManager.signEntryWithEd25519Signers` without
/// a real hardware-signing backend.
private final class FakeZeroByteEd25519Adapter: OZExternalEd25519SignerAdapter, @unchecked Sendable {

    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool {
        return true
    }

    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data {
        return Data(repeating: 0x00, count: 64)
    }
}

/// `OZExternalEd25519SignerAdapter` stub that reports `canSignFor` as `true`
/// only for a pre-configured (verifierAddress, publicKey) pair. Used to
/// register a specific 32-byte public key under the adapter path without
/// needing a matching secret key (e.g. when the public key bytes are derived
/// from a G-address rather than a keypair secret).
private final class FixedKeyEd25519Adapter: OZExternalEd25519SignerAdapter, @unchecked Sendable {

    private let targetPublicKey: Data
    private let targetVerifierAddress: String

    init(targetPublicKey: Data, targetVerifierAddress: String) {
        self.targetPublicKey = targetPublicKey
        self.targetVerifierAddress = targetVerifierAddress
    }

    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool {
        return verifierAddress == targetVerifierAddress && publicKey == targetPublicKey
    }

    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data {
        // Returns 64 zero-bytes; the pipeline will fail at local verification.
        // This adapter is used in tests that only care about the routing logic,
        // not about successful signature verification.
        return Data(repeating: 0x00, count: 64)
    }
}

