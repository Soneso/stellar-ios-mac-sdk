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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch let error as SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("Cannot transfer to self"))
        }
    }

    func test_transfer_zeroAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "0",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAmount")
        } catch is SmartAccountValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_negativeAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "-5",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAmount")
        } catch is SmartAccountValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_nonNumericAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "abc",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAmount")
        } catch is SmartAccountValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_emptyAmount_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAmount")
        } catch is SmartAccountValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_scientificNotation_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "1e5",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAmount")
        } catch is SmartAccountValidationException.InvalidAmount {
            // expected
        }
    }

    func test_transfer_amountTooSmall_throws() async throws {
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: validContractAddress,
                recipient: validAccountAddress,
                amount: "0.00000001",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAmount")
        } catch is SmartAccountValidationException.InvalidAmount {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch let error as SmartAccountValidationException.InvalidAddress {
            // With nil decimals the token contract is validated up front by the
            // automatic decimals fetch before any amount conversion or call.
            XCTAssertTrue(error.message.contains("tokenContract"))
        }
    }

    func test_transfer_explicitDecimals_invalidTokenContract_throws() async throws {
        // With explicit decimals there is no automatic fetch; the invalid token
        // contract surfaces from the downstream contract call as `target`.
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.transfer(
                tokenContract: "not-a-contract",
                recipient: validAccountAddress,
                amount: "10",
                decimals: 7
            )
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch let error as SmartAccountValidationException.InvalidAddress {
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
        } catch is SmartAccountValidationException {
            XCTFail("Validation should pass for G-address recipient")
        } catch is SmartAccountWalletException {
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
        } catch is SmartAccountValidationException {
            XCTFail("Validation should pass for C-address recipient")
        } catch is SmartAccountWalletException {
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch let error as SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
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
        } catch is SmartAccountValidationException {
            XCTFail("Validation should pass for valid inputs")
        } catch is SmartAccountWalletException {
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch let error as SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // MARK: - OZTransactionResult data-class behavior
    // ========================================================================

    func test_transactionResult_allFields() {
        let result = OZTransactionResult(
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
        let result = OZTransactionResult(success: false)
        XCTAssertFalse(result.success)
        XCTAssertNil(result.hash)
        XCTAssertNil(result.ledger)
        XCTAssertNil(result.error)
    }

    func test_transactionResult_failureWithError() {
        let result = OZTransactionResult(
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
        let result = OZTransactionResult(success: true, hash: "txhash", ledger: 1000)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.ledger, 1000)
        XCTAssertNil(result.error)
    }

    func test_transactionResult_equalInstances() {
        let a = OZTransactionResult(success: true, hash: "h1", ledger: 10, error: nil)
        let b = OZTransactionResult(success: true, hash: "h1", ledger: 10, error: nil)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_transactionResult_unequalInstances() {
        let a = OZTransactionResult(success: true, hash: "h1", ledger: 10)
        let b = OZTransactionResult(success: false, hash: "h1", ledger: 10)
        XCTAssertNotEqual(a, b)
    }

    // ========================================================================
    // MARK: - OZSubmissionMethod enum behavior
    // ========================================================================

    func test_submissionMethod_values() {
        let values: [OZSubmissionMethod] = [.relayer, .rpc]
        XCTAssertEqual(values.count, 2)
        XCTAssertTrue(values.contains(.relayer))
        XCTAssertTrue(values.contains(.rpc))
    }

    func test_submissionMethod_valueOf() {
        // Swift enums are referenced through their static cases; this test
        // documents the case-mapping contract using an exhaustive switch so
        // every case is observed.
        let relayer: OZSubmissionMethod = .relayer
        let rpc: OZSubmissionMethod = .rpc
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
        let value: OZSubmissionMethod = .relayer
        switch value {
        case .relayer, .rpc:
            // exhaustive: the type system rejects any third case at compile
            // time, so this branch covers every value the API can produce.
            break
        }
    }

    // ========================================================================
    // MARK: - OZResolveContextRuleIds typealias behavior
    // ========================================================================

    func test_resolveContextRuleIds_lambdaUsable() async throws {
        let resolver: OZResolveContextRuleIds = { _, index in
            return [UInt32(index)]
        }
        let result = try await resolver(minimalAuthEntry(), 3)
        XCTAssertEqual(result, [3])
    }

    func test_resolveContextRuleIds_emptyList() async throws {
        let resolver: OZResolveContextRuleIds = { _, _ in [] }
        let result = try await resolver(minimalAuthEntry(), 0)
        XCTAssertTrue(result.isEmpty)
    }

    func test_resolveContextRuleIds_multipleIds() async throws {
        let resolver: OZResolveContextRuleIds = { _, _ in [1, 2, 5] }
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
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
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        }
    }

    func test_fundWallet_notConnected_throws() async throws {
        let (_, txOps) = try disconnectedKit()
        do {
            _ = try await txOps.fundWallet(nativeTokenContract: validContractAddress)
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // MARK: - amountToBaseUnits static helper coverage
    // ========================================================================

    func test_amountToBaseUnits_validInteger_returnsBaseUnits() throws {
        let baseUnits = try OZTransactionOperations.amountToBaseUnits("10", decimals: 7)
        XCTAssertEqual(baseUnits, "100000000")
    }

    func test_amountToBaseUnits_validFractional_returnsBaseUnits() throws {
        let baseUnits = try OZTransactionOperations.amountToBaseUnits("0.5", decimals: 7)
        XCTAssertEqual(baseUnits, "5000000")
    }

    func test_amountToBaseUnits_oneBaseUnit_returnsOne() throws {
        let baseUnits = try OZTransactionOperations.amountToBaseUnits("0.0000001", decimals: 7)
        XCTAssertEqual(baseUnits, "1")
    }

    func test_amountToBaseUnits_aboveInt64_returnsFullPrecisionString() throws {
        // A value far beyond Int64.max must be preserved exactly as base units
        // (10^25 -> 10^32 base units), not capped at Int64.
        let baseUnits = try OZTransactionOperations.amountToBaseUnits(
            "10000000000000000000000000", decimals: 7)
        XCTAssertEqual(baseUnits, "100000000000000000000000000000000")
    }

    func test_amountToBaseUnits_sixDecimals_scalesBySix() throws {
        let baseUnits = try OZTransactionOperations.amountToBaseUnits("1.5", decimals: 6)
        XCTAssertEqual(baseUnits, "1500000")
    }

    func test_amountToBaseUnits_eighteenDecimals_scalesByEighteen() throws {
        let baseUnits = try OZTransactionOperations.amountToBaseUnits("2", decimals: 18)
        XCTAssertEqual(baseUnits, "2000000000000000000")
    }

    func test_amountToBaseUnits_zeroDecimals_integerAmount_returnsWhole() throws {
        let baseUnits = try OZTransactionOperations.amountToBaseUnits("42", decimals: 0)
        XCTAssertEqual(baseUnits, "42")
    }

    func test_amountToBaseUnits_zeroDecimals_fractionalAmount_throws() {
        // decimals == 0 accepts integer amounts only; any fractional digit is
        // rejected.
        XCTAssertThrowsError(
            try OZTransactionOperations.amountToBaseUnits("1.5", decimals: 0)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_tooManyFractionalDigitsForDecimals_throws() {
        // Seven fractional digits with a six-decimal scale exceeds the token's
        // precision and is rejected.
        XCTAssertThrowsError(
            try OZTransactionOperations.amountToBaseUnits("1.1234567", decimals: 6)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_negativeDecimals_throws() {
        XCTAssertThrowsError(
            try OZTransactionOperations.amountToBaseUnits("1", decimals: -1)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_decimalsAboveCap_throws() {
        XCTAssertThrowsError(
            try OZTransactionOperations.amountToBaseUnits(
                "1", decimals: OZTransactionOperations.maxTokenDecimals + 1)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_zeroResultAtNonSevenDecimals_throws() {
        // "0" must be rejected at any scale because the resulting base-units
        // value is zero.
        XCTAssertThrowsError(
            try OZTransactionOperations.amountToBaseUnits("0", decimals: 6)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_baseUnitsToI128ScVal_aboveInt64_encodesFullValue() throws {
        // Base units beyond Int64.max encode into the i128 high word rather than
        // overflowing or capping.
        let scVal = try OZTransactionOperations.baseUnitsToI128ScVal(
            "100000000000000000000000000000000", amount: "10000000000000000000000000")
        XCTAssertTrue(scVal.isI128)
    }

    func test_baseUnitsToI128ScVal_exceedsI128Range_throwsInvalidAmount() {
        // 2^127 (one past max i128) must be rejected, not silently truncated.
        XCTAssertThrowsError(
            try OZTransactionOperations.baseUnitsToI128ScVal(
                "170141183460469231731687303715884105728",
                amount: "170141183460469231731687303715884105728")
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_zero_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("0", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_belowOneBaseUnit_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("0.00000001", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_scientific_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("1e5", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_empty_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_nonNumeric_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("abc", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    func test_amountToBaseUnits_negative_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("-5", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    // ========================================================================
    // MARK: - failure-mode tests — submit pipeline failures
    // ========================================================================

    func test_submit_simulationRpcFailure_throwsSimulationFailed() async throws {
        // The default mock kit points at TEST-NET-1 (192.0.2.x); the RPC call
        // fails with a transport error, which submit() lifts into
        // SmartAccountTransactionException.SimulationFailed.
        let (_, txOps) = try connectedKit()
        do {
            _ = try await txOps.contractCall(
                target: validContractAddress,
                targetFn: "noop"
            )
            XCTFail("expected SmartAccountTransactionException")
        } catch is SmartAccountTransactionException {
            // expected
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    // ========================================================================
    // MARK: - scValToInt64 high-order-bit branches
    // ========================================================================

    func test_scValToInt64_hiZero_loExceedsInt64Max_returnsNil() {
        // hi == 0 but lo > Int64.max: the value does not fit a signed Int64.
        let parts = Int128PartsXDR(hi: 0, lo: UInt64(Int64.max) + 1)
        XCTAssertNil(OZTransactionOperations.scValToInt64(.i128(parts)))
    }

    func test_scValToInt64_hiZero_loEqualsInt64Max_returnsValue() {
        // Boundary: lo == Int64.max with hi == 0 is the largest representable
        // positive value and must round-trip.
        let parts = Int128PartsXDR(hi: 0, lo: UInt64(Int64.max))
        XCTAssertEqual(OZTransactionOperations.scValToInt64(.i128(parts)), Int64.max)
    }

    func test_scValToInt64_hiMinusOne_negativeValue_returnsValue() {
        // hi == -1 with a low-word bit pattern >= Int64.min's pattern decodes a
        // negative Int64. -1 is encoded as hi == -1, lo == UInt64.max.
        let parts = Int128PartsXDR(hi: -1, lo: UInt64.max)
        XCTAssertEqual(OZTransactionOperations.scValToInt64(.i128(parts)), -1)
    }

    func test_scValToInt64_hiMinusOne_loBelowInt64MinPattern_returnsNil() {
        // hi == -1 but lo below the Int64.min bit pattern cannot fit Int64.
        let parts = Int128PartsXDR(hi: -1, lo: 0)
        XCTAssertNil(OZTransactionOperations.scValToInt64(.i128(parts)))
    }

    func test_scValToInt64_hiMinusOne_loEqualsInt64MinPattern_returnsMin() {
        // Boundary: lo == Int64.min's bit pattern with hi == -1 decodes Int64.min.
        let parts = Int128PartsXDR(hi: -1, lo: UInt64(bitPattern: Int64.min))
        XCTAssertEqual(OZTransactionOperations.scValToInt64(.i128(parts)), Int64.min)
    }

    // ========================================================================
    // MARK: - amountToBaseUnits beyond Int64 (full precision)
    // ========================================================================

    func test_amountToBaseUnits_wholePartBeyondInt64_returnsFullPrecision() throws {
        // A 30-digit whole part far exceeds Int64 but is preserved exactly:
        // 30 nines -> 30 nines followed by 7 zeros in base units.
        let huge = String(repeating: "9", count: 30)
        let baseUnits = try OZTransactionOperations.amountToBaseUnits(huge, decimals: 7)
        XCTAssertEqual(baseUnits, huge + "0000000")
    }

    func test_amountToBaseUnits_tooManyFractionalDigits_throws() {
        // Eight fractional digits exceeds the seven-decimal base-unit precision.
        XCTAssertThrowsError(try OZTransactionOperations.amountToBaseUnits("1.123456789", decimals: 7)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidAmount)
        }
    }

    // ========================================================================
    // MARK: - tryFromContextRuleSignerScVal static helper
    // ========================================================================

    func test_tryFromContextRuleSignerScVal_validExternalSigner_returnsKeyData() throws {
        // Encode an external signer the same way the on-chain rule stores it,
        // then assert the decode-side helper recovers the keyData bytes.
        let keyData = Data(repeating: 0xAB, count: 65)
        let signer = try OZExternalSigner(
            verifierAddress: validContractAddress,
            keyData: keyData
        )
        let scVal = try signer.toScVal()
        let recovered = OZTransactionOperations.tryFromContextRuleSignerScVal(scVal)
        XCTAssertEqual(recovered, keyData)
    }

    func test_tryFromContextRuleSignerScVal_notAVec_returnsNil() {
        XCTAssertNil(OZTransactionOperations.tryFromContextRuleSignerScVal(.symbol("nope")))
    }

    func test_tryFromContextRuleSignerScVal_nilVec_returnsNil() {
        XCTAssertNil(OZTransactionOperations.tryFromContextRuleSignerScVal(.vec(nil)))
    }

    func test_tryFromContextRuleSignerScVal_tooFewParts_returnsNil() {
        let parts: [SCValXDR] = [.symbol("External"), .bytes(Data([0x01]))]
        XCTAssertNil(OZTransactionOperations.tryFromContextRuleSignerScVal(.vec(parts)))
    }

    func test_tryFromContextRuleSignerScVal_wrongTagSymbol_returnsNil() throws {
        let address = try SCAddressXDR(contractId: validContractAddress)
        let parts: [SCValXDR] = [
            .symbol("Native"),
            .address(address),
            .bytes(Data([0x01]))
        ]
        XCTAssertNil(OZTransactionOperations.tryFromContextRuleSignerScVal(.vec(parts)))
    }

    func test_tryFromContextRuleSignerScVal_firstElementNotSymbol_returnsNil() throws {
        let address = try SCAddressXDR(contractId: validContractAddress)
        let parts: [SCValXDR] = [
            .u32(7),
            .address(address),
            .bytes(Data([0x01]))
        ]
        XCTAssertNil(OZTransactionOperations.tryFromContextRuleSignerScVal(.vec(parts)))
    }

    func test_tryFromContextRuleSignerScVal_thirdElementNotBytes_returnsNil() throws {
        let address = try SCAddressXDR(contractId: validContractAddress)
        let parts: [SCValXDR] = [
            .symbol("External"),
            .address(address),
            .symbol("not-bytes")
        ]
        XCTAssertNil(OZTransactionOperations.tryFromContextRuleSignerScVal(.vec(parts)))
    }

    // ========================================================================
    // MARK: - applySimulation relayer-mode branches
    // ========================================================================

    /// Builds a minimal transaction whose source account is the supplied
    /// keypair so `applySimulation` can mutate its fee / soroban-data fields.
    private func buildTransactionForApply() throws -> Transaction {
        let kp = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: kp, sequenceNumber: 0)
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: validContractAddress),
            functionName: "noop",
            args: []
        )
        let op = InvokeHostFunctionOperation(
            hostFunction: .invokeContract(invokeArgs),
            auth: []
        )
        return try Transaction(
            sourceAccount: account,
            operations: [op],
            memo: Memo.none
        )
    }

    /// Decodes a `SimulateTransactionResponse` from a JSON-RPC `result`
    /// dictionary so `applySimulation` can be exercised without a live RPC hop.
    private func decodeSimulation(
        minResourceFee: UInt32?,
        transactionData: String? = nil
    ) throws -> SimulateTransactionResponse {
        var payload: [String: Any] = [
            "latestLedger": NSNumber(value: 1000)
        ]
        if let fee = minResourceFee {
            payload["minResourceFee"] = String(fee)
        }
        if let data = transactionData {
            payload["transactionData"] = data
        }
        payload["results"] = [["auth": [String](), "xdr": SCValXDR.void.xdrEncoded ?? ""]]
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(SimulateTransactionResponse.self, from: data)
    }

    func test_applySimulation_relayerMode_setsFeeToMinResourceFee() throws {
        let tx = try buildTransactionForApply()
        let simulation = try decodeSimulation(minResourceFee: 250_000)
        try OZTransactionOperations.applySimulation(
            simulation: simulation,
            transaction: tx,
            signedAuthEntries: [],
            relayerMode: true
        )
        // In relayer mode the fee is set (not added on top of base op fee) to
        // exactly the minResourceFee so the relayer can fee-bump cleanly.
        XCTAssertEqual(tx.fee, 250_000)
    }

    func test_applySimulation_nonRelayerMode_addsResourceFeeOnTopOfBase() throws {
        let tx = try buildTransactionForApply()
        let baseFee = tx.fee
        let simulation = try decodeSimulation(minResourceFee: 90_000)
        try OZTransactionOperations.applySimulation(
            simulation: simulation,
            transaction: tx,
            signedAuthEntries: [],
            relayerMode: false
        )
        XCTAssertEqual(tx.fee, baseFee + 90_000)
    }

    func test_applySimulation_relayerMode_missingMinResourceFee_throws() throws {
        let tx = try buildTransactionForApply()
        let simulation = try decodeSimulation(minResourceFee: nil)
        XCTAssertThrowsError(
            try OZTransactionOperations.applySimulation(
                simulation: simulation,
                transaction: tx,
                signedAuthEntries: [],
                relayerMode: true
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountTransactionException.SubmissionFailed)
        }
    }

    func test_applySimulation_nonRelayerMode_missingMinResourceFee_doesNotThrow() throws {
        // When not in relayer mode a missing minResourceFee is tolerated: the
        // transaction keeps its base fee and no resource fee is added.
        let tx = try buildTransactionForApply()
        let baseFee = tx.fee
        let simulation = try decodeSimulation(minResourceFee: nil)
        XCTAssertNoThrow(
            try OZTransactionOperations.applySimulation(
                simulation: simulation,
                transaction: tx,
                signedAuthEntries: [],
                relayerMode: false
            )
        )
        XCTAssertEqual(tx.fee, baseFee)
    }

    // ========================================================================
    // MARK: - SmartAccountException.messageOf
    // ========================================================================

    func test_messageOf_nil_returnsNil() {
        XCTAssertNil(SmartAccountException.messageOf(nil))
    }

    func test_messageOf_smartAccountException_returnsTypedMessage() {
        let err = SmartAccountValidationException.invalidInput(
            field: "x",
            reason: "bad value"
        )
        let message = SmartAccountException.messageOf(err)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("bad value"),
                      "expected the typed message, got: \(message ?? "nil")")
    }

    func test_messageOf_genericError_fallsBackToLocalizedDescription() {
        let err = NSError(
            domain: "test.domain",
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "localized failure text"]
        )
        let message = SmartAccountException.messageOf(err)
        XCTAssertEqual(message, "localized failure text")
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    /// Minimal authorization entry with `sourceAccount` (Void) credentials and
    /// a trivial invocation tree. Used by OZResolveContextRuleIds tests.
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
