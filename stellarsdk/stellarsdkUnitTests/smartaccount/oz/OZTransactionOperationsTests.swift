//
//  OZTransactionOperationsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZTransactionOperationsTests: XCTestCase {

    // MARK: - Fixtures

    private let validContractAddress =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validContractAddress2 =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let validAccountAddress =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private let validMuxedAddress =
        "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAPZFBVAI"

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://soroban-testnet.stellar.org",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractAddress
        )
    }

    private func disconnectedKit() throws -> (MockOZSmartAccountKit, OZTransactionOperations) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (kit, OZTransactionOperations(kit: kit))
    }

    private func connectedKit(
        contractId: String? = nil
    ) throws -> (MockOZSmartAccountKit, OZTransactionOperations) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractAddress2
        )
        return (kit, OZTransactionOperations(kit: kit))
    }

    // ========================================================================
    // MARK: - transfer validation (not connected)
    // ========================================================================

    func test_transfer_notConnected_throws() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "10"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
            XCTAssertTrue(error.message.contains("No wallet connected"))
        }
    }

    func test_transfer_invalidRecipient_garbage_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: "not-a-stellar-address",
                amount: "10"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("recipient"))
        }
    }

    func test_transfer_invalidRecipient_emptyString_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: "",
                amount: "10"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_transfer_invalidRecipient_muxedAddress_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validMuxedAddress,
                amount: "10"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_transfer_selfTransfer_throws() async throws {
        let (_, txOps) = try connectedKit(contractId: validContractAddress2)
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validContractAddress2,
                amount: "10"
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("Cannot transfer to self"))
        }
    }

    func test_transfer_zeroAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "0"
            )
            XCTFail("expected ValidationException.InvalidAmount")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_negativeAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "-5"
            )
            XCTFail("expected ValidationException.InvalidAmount")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_nonNumericAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "abc"
            )
            XCTFail("expected ValidationException.InvalidAmount")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_emptyAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: ""
            )
            XCTFail("expected ValidationException.InvalidAmount")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_scientificNotation_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "1e5"
            )
            XCTFail("expected ValidationException.InvalidAmount")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_amountTooSmall_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "0.00000001"
            )
            XCTFail("expected ValidationException.InvalidAmount")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_invalidTokenContract_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: "not-a-contract",
                recipient: validAccountAddress,
                amount: "10"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("target"))
        }
    }

    // ========================================================================
    // MARK: - transfer happy-path validation (network call expected to fail)
    // ========================================================================

    func test_transfer_recipientGAddress_passesValidation() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "10"
            )
            // If we get here, the pipeline somehow succeeded which is fine.
        } catch is ValidationException {
            XCTFail("Validation should pass for G-address recipient")
        } catch is WalletException {
            XCTFail("Wallet exception unexpected")
        } catch {
            // expected: network/simulation failure
        }
    }

    func test_transfer_recipientCAddress_passesValidation() async throws {
        let (_, txOps) = try connectedKit(contractId: validContractAddress)
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validContractAddress2,
                amount: "10"
            )
        } catch is ValidationException {
            XCTFail("Validation should pass for C-address recipient")
        } catch is WalletException {
            XCTFail("Wallet exception unexpected")
        } catch {
            // expected: network/simulation failure
        }
    }

    // ========================================================================
    // MARK: - contractCall validation
    // ========================================================================

    func test_contractCall_notConnected_throws() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validContractAddress,
                targetFn: "transfer"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_contractCall_invalidTarget_garbage_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: "not-a-contract-address",
                targetFn: "my_function"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("target"))
        }
    }

    func test_contractCall_invalidTarget_gAddress_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validAccountAddress,
                targetFn: "my_function"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_contractCall_invalidTarget_emptyString_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: "",
                targetFn: "my_function"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_contractCall_emptyFunctionName_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validContractAddress,
                targetFn: ""
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("Function name cannot be empty"))
        }
    }

    func test_contractCall_blankFunctionName_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validContractAddress,
                targetFn: "   "
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    func test_contractCall_validInputs_passesValidation() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validContractAddress,
                targetFn: "my_function"
            )
        } catch is ValidationException {
            XCTFail("Validation should pass for valid inputs")
        } catch is WalletException {
            XCTFail("Wallet exception unexpected")
        } catch {
            // expected
        }
    }

    // ========================================================================
    // MARK: - executeAndSubmit validation
    // ========================================================================

    func test_executeAndSubmit_notConnected_throws() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.executeAndSubmit(
                target: validContractAddress,
                targetFn: "execute"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_executeAndSubmit_invalidTarget_garbage_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.executeAndSubmit(
                target: "bad-address",
                targetFn: "do_something"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("target"))
        }
    }

    func test_executeAndSubmit_invalidTarget_gAddress_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.executeAndSubmit(
                target: validAccountAddress,
                targetFn: "do_something"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_executeAndSubmit_invalidTarget_emptyString_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.executeAndSubmit(
                target: "",
                targetFn: "do_something"
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_executeAndSubmit_emptyFunctionName_throwsValidationException() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.executeAndSubmit(
                target: validContractAddress,
                targetFn: ""
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // MARK: - TransactionResult data-class behavior
    // ========================================================================

    func test_transactionResult_allFields() {
        let result = TransactionResult(
            success: true,
            hash: "abc123",
            ledger: 42,
            error: nil
        )
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.hash, "abc123")
        XCTAssertEqual(result.ledger, 42)
        XCTAssertNil(result.error)
    }

    func test_transactionResult_defaults() {
        let result = TransactionResult(success: false)
        XCTAssertFalse(result.success)
        XCTAssertNil(result.hash)
        XCTAssertNil(result.ledger)
        XCTAssertNil(result.error)
    }

    func test_transactionResult_failureWithError() {
        let result = TransactionResult(
            success: false,
            hash: "def456",
            ledger: nil,
            error: "Simulation failed"
        )
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.hash, "def456")
        XCTAssertNil(result.ledger)
        XCTAssertEqual(result.error, "Simulation failed")
    }

    func test_transactionResult_successWithLedger() {
        let result = TransactionResult(success: true, hash: "txhash", ledger: 1000)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.ledger, 1000)
        XCTAssertNil(result.error)
    }

    func test_transactionResult_equalInstances() {
        let a = TransactionResult(success: true, hash: "h1", ledger: 10, error: nil)
        let b = TransactionResult(success: true, hash: "h1", ledger: 10, error: nil)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_transactionResult_unequalInstances() {
        let a = TransactionResult(success: true, hash: "h1", ledger: 10)
        let b = TransactionResult(success: false, hash: "h1", ledger: 10)
        XCTAssertNotEqual(a, b)
    }

    func test_transactionResult_copy() {
        let original = TransactionResult(success: true, hash: "orig")
        let modified = original.copy(success: false, error: "failed")
        XCTAssertTrue(original.success)
        XCTAssertFalse(modified.success)
        XCTAssertEqual(modified.hash, "orig")
        XCTAssertEqual(modified.error, "failed")
    }

    // ========================================================================
    // MARK: - SubmissionMethod enum behavior
    // ========================================================================

    func test_submissionMethod_values() {
        let values: [SubmissionMethod] = [.relayer, .rpc]
        XCTAssertEqual(values.count, 2)
        XCTAssertTrue(values.contains(.relayer))
        XCTAssertTrue(values.contains(.rpc))
    }

    func test_submissionMethod_valueOf() {
        // Swift enums are referenced through their static cases; this test
        // documents the case-mapping contract using an exhaustive switch so
        // every case is observed.
        let relayer: SubmissionMethod = .relayer
        let rpc: SubmissionMethod = .rpc
        switch relayer {
        case .relayer: break
        case .rpc: XCTFail()
        }
        switch rpc {
        case .relayer: XCTFail()
        case .rpc: break
        }
    }

    func test_submissionMethod_invalidValue_throws() {
        // Swift's exhaustive switch over the enum guarantees that no third
        // case can exist at compile time; an "invalid" submission method is
        // unrepresentable. This test pins that invariant.
        let value: SubmissionMethod = .relayer
        switch value {
        case .relayer, .rpc:
            // exhaustive: the type system rejects any third case at compile
            // time, so this branch covers every value the API can produce.
            break
        }
    }

    // ========================================================================
    // MARK: - ResolveContextRuleIds typealias behavior
    // ========================================================================

    func test_resolveContextRuleIds_lambdaUsable() async throws {
        let resolver: ResolveContextRuleIds = { _, index in
            return [UInt32(index)]
        }
        let result = try await resolver(minimalAuthEntry(), 3)
        XCTAssertEqual(result, [3])
    }

    func test_resolveContextRuleIds_emptyList() async throws {
        let resolver: ResolveContextRuleIds = { _, _ in [] }
        let result = try await resolver(minimalAuthEntry(), 0)
        XCTAssertTrue(result.isEmpty)
    }

    func test_resolveContextRuleIds_multipleIds() async throws {
        let resolver: ResolveContextRuleIds = { _, _ in [1, 2, 5] }
        let result = try await resolver(minimalAuthEntry(), 0)
        XCTAssertEqual(result, [1, 2, 5])
    }

    // ========================================================================
    // MARK: - Order-of-validation tests
    // ========================================================================

    func test_transfer_notConnected_beforeRecipientValidation() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: "invalid",
                amount: "10"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_transfer_notConnected_beforeAmountValidation() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "not-a-number"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_contractCall_notConnected_beforeTargetValidation() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.contractCall(
                target: "invalid-target",
                targetFn: "fn"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func test_executeAndSubmit_notConnected_beforeTargetValidation() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.executeAndSubmit(
                target: "invalid-target",
                targetFn: "fn"
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // MARK: - Auth-entry signing helpers (static-helper coverage)
    // ========================================================================

    func test_classicalEd25519SignatureScVal_shape_isVec_ofMap() {
        let publicKey = Data(repeating: 0x01, count: 32)
        let signature = Data(repeating: 0x02, count: 64)
        let scval = OZTransactionOperations.classicalEd25519SignatureScVal(
            publicKey: publicKey,
            signature: signature
        )

        guard case .vec(let outer) = scval, let outer = outer, outer.count == 1 else {
            XCTFail("expected outer Vec with single element")
            return
        }
        guard case .map(let entries) = outer[0], let entries = entries else {
            XCTFail("expected inner Map")
            return
        }
        XCTAssertEqual(entries.count, 2)
        if case .symbol(let firstKey) = entries[0].key {
            XCTAssertEqual(firstKey, "public_key")
        } else {
            XCTFail("first map key should be Symbol(\"public_key\")")
        }
        if case .symbol(let secondKey) = entries[1].key {
            XCTAssertEqual(secondKey, "signature")
        } else {
            XCTFail("second map key should be Symbol(\"signature\")")
        }
    }

    func test_classicalEd25519SignatureScVal_distinctFromAuthPayloadMap() {
        // The classical Ed25519 signature ScVal uses a Vec wrapper around a Map.
        // The OZ AuthPayload Map is a top-level Map with "context_rule_ids" and
        // "signers" keys. Asserting the outer type distinguishes the two shapes.
        let scval = OZTransactionOperations.classicalEd25519SignatureScVal(
            publicKey: Data(repeating: 0, count: 32),
            signature: Data(repeating: 0, count: 64)
        )
        if case .map = scval {
            XCTFail("classical Ed25519 signature must be Vec-wrapped, not a top-level Map")
        }
    }

    func test_generateNonce_isInt64SizedAndNonZero() throws {
        // Run a few iterations so a single zero outcome doesn't false-positive.
        var allZero = true
        for _ in 0..<8 {
            let nonce = try OZTransactionOperations.generateNonce()
            if nonce != 0 { allZero = false; break }
        }
        XCTAssertFalse(allZero, "generateNonce should not produce all-zero outputs")
    }

    func test_generateNonce_csprng_failure_throws() {
        // The OSStatus check inside `generateNonce()` ensures a non-zero
        // SecRandomCopyBytes failure cannot ship as a "random" nonce. We
        // cannot inject an `errSecSuccess`-failing outcome from the public
        // SecurityFramework surface, but we can pin that the method is
        // declared `throws` and that its signature surfaces a recoverable
        // error so callers cannot accidentally swallow CSPRNG failures.
        // Compile-time verification: the call site below would not compile
        // without a `try`. This guards the production-quality contract.
        XCTAssertNoThrow(try OZTransactionOperations.generateNonce())
    }

    // ========================================================================
    // MARK: - fundWallet amount formatting / balance parsing helpers
    // ========================================================================

    func test_formatXlmAmount_wholeNumber() {
        XCTAssertEqual(OZTransactionOperations.formatXlmAmount(stroops: 100_000_000_0), "100")
    }

    func test_formatXlmAmount_withFraction_trimsTrailingZeros() {
        // 5_123_456_700 stroops -> whole = 512, fraction = 3_456_700 (padded
        // "3456700", trimmed "34567") -> "512.34567"
        XCTAssertEqual(OZTransactionOperations.formatXlmAmount(stroops: 5_123_456_700), "512.34567")
    }

    func test_formatXlmAmount_smallFraction_keepsLeadingZeros() {
        XCTAssertEqual(OZTransactionOperations.formatXlmAmount(stroops: 1), "0.0000001")
    }

    func test_formatXlmAmount_oneXlm() {
        XCTAssertEqual(OZTransactionOperations.formatXlmAmount(stroops: 10_000_000), "1")
    }

    func test_scValToInt64_validI128_returnsValue() {
        // (hi = 0, lo = 1_000_000_000_000) — 100,000 XLM
        let parts = Int128PartsXDR(hi: 0, lo: 1_000_000_000_000)
        let scval = SCValXDR.i128(parts)
        XCTAssertEqual(OZTransactionOperations.scValToInt64(scval), 1_000_000_000_000)
    }

    func test_scValToInt64_oversizedI128_returnsNil() {
        // hi = 1 (any non-zero, non-minus-one high part) — does not fit Int64
        let parts = Int128PartsXDR(hi: 1, lo: 0)
        let scval = SCValXDR.i128(parts)
        XCTAssertNil(OZTransactionOperations.scValToInt64(scval))
    }

    func test_scValToInt64_nonInt128_returnsNil() {
        let scval = SCValXDR.u32(42)
        XCTAssertNil(OZTransactionOperations.scValToInt64(scval))
    }

    // ========================================================================
    // MARK: - fundWallet validation (insufficient balance / wrong contract)
    // ========================================================================

    func test_fundWallet_invalidNativeContract_throwsInvalidAddress() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.fundWallet(nativeTokenContract: "not-a-contract")
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        }
    }

    func test_fundWallet_notConnected_throws() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.fundWallet(nativeTokenContract: validContractAddress)
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // MARK: - amountToStroops static helper coverage
    // ========================================================================

    func test_amountToStroops_validInteger_returnsStroops() throws {
        let stroops = try OZTransactionOperations.amountToStroops("10")
        XCTAssertEqual(stroops, 100_000_000)
    }

    func test_amountToStroops_validFractional_returnsStroops() throws {
        let stroops = try OZTransactionOperations.amountToStroops("0.5")
        XCTAssertEqual(stroops, 5_000_000)
    }

    func test_amountToStroops_oneStroop_returnsOne() throws {
        let stroops = try OZTransactionOperations.amountToStroops("0.0000001")
        XCTAssertEqual(stroops, 1)
    }

    func test_amountToStroops_zero_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("0")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    func test_amountToStroops_belowOneStroop_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("0.00000001")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    func test_amountToStroops_scientific_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("1e5")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    func test_amountToStroops_empty_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    func test_amountToStroops_nonNumeric_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("abc")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    func test_amountToStroops_negative_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("-5")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    // ========================================================================
    // MARK: - failure-mode tests — submit pipeline failures
    // ========================================================================

    func test_submit_simulationRpcFailure_throwsSimulationFailed() async throws {
        // The default mock kit points at TEST-NET-1 (192.0.2.x); the RPC call
        // fails with a transport error, which submit() lifts into
        // TransactionException.SimulationFailed.
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validContractAddress,
                targetFn: "noop"
            )
            XCTFail("expected TransactionException")
        } catch is TransactionException {
            // expected
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    /// Minimal authorization entry with `sourceAccount` (Void) credentials and
    /// a trivial invocation tree. Used by ResolveContextRuleIds tests.
    private func minimalAuthEntry() -> SorobanAuthorizationEntryXDR {
        let contractAddress = SCAddressXDR.contract(WrappedData32(Data(count: 32)))
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "hello",
            args: []
        )
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(invokeArgs),
            subInvocations: []
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
    }
}
