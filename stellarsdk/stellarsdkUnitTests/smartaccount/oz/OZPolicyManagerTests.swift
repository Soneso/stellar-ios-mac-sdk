//
//  OZPolicyManagerTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for `PolicyInstallParams` ScVal encoding and the supporting
/// helpers exposed by `OZPolicyManager`.
///
/// These tests verify that the three policy types (`simpleThreshold`,
/// `weightedThreshold`, `spendingLimit`) produce correct ScVal output
/// compatible with the on-chain smart-account contracts and that the
/// supporting amount-conversion helpers and host-function builders generate
/// the byte-exact shapes the contract methods expect.
///
/// Network-dependent operations (the manager's add/remove flow that submits
/// transactions through the kit's transaction operations) are exercised by
/// integration tests; the unit-level coverage here focuses on argument
/// preparation, validation, and routing decisions.
final class OZPolicyManagerTests: XCTestCase {

    private let validAddr1 = "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7"
    private let validAddr2 = "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW"
    private let validAddr3 = "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG"
    private let validVerifier = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let validContractC =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validContractC2 =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractC
        )
    }

    private func disconnectedKit() throws -> (MockOZSmartAccountKit, OZPolicyManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (kit, OZPolicyManager(kit: kit))
    }

    private func connectedKit(
        contractId: String? = nil
    ) throws -> (MockOZSmartAccountKit, OZPolicyManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractC2
        )
        return (kit, OZPolicyManager(kit: kit))
    }

    // ========================================================================
    // SimpleThreshold — ScVal shape (5 cases)
    // ========================================================================

    func test_simpleThreshold_createsMapWithThresholdKey() throws {
        let scVal = try PolicyInstallParams.simpleThreshold(threshold: 2).toScVal()

        guard case .map(let entries) = scVal, let entries = entries else {
            return XCTFail("expected map")
        }
        XCTAssertEqual(entries.count, 1, "SimpleThreshold map must have exactly 1 entry")
        XCTAssertEqual(extractSymbolName(entries[0].key), "threshold")

        guard case .u32(let v) = entries[0].val else {
            return XCTFail("expected u32 threshold value")
        }
        XCTAssertEqual(v, 2)
    }

    func test_simpleThreshold_thresholdOfOne() throws {
        let scVal = try PolicyInstallParams.simpleThreshold(threshold: 1).toScVal()
        let entries = try extractMapEntries(scVal)
        guard case .u32(let v) = entries[0].val else {
            return XCTFail("expected u32 threshold value")
        }
        XCTAssertEqual(v, 1)
    }

    func test_simpleThreshold_largeThresholdValue() throws {
        let scVal = try PolicyInstallParams.simpleThreshold(threshold: UInt32.max).toScVal()
        let entries = try extractMapEntries(scVal)
        guard case .u32(let v) = entries[0].val else {
            return XCTFail("expected u32 threshold value")
        }
        XCTAssertEqual(v, UInt32.max)
    }

    func test_simpleThreshold_deterministicXdrEncoding() throws {
        let a = try PolicyInstallParams.simpleThreshold(threshold: 5).toScVal()
        let b = try PolicyInstallParams.simpleThreshold(threshold: 5).toScVal()

        let encA = try Data(XDREncoder.encode(a))
        let encB = try Data(XDREncoder.encode(b))
        XCTAssertEqual(encA, encB, "Identical SimpleThreshold params must produce identical XDR")
    }

    func test_simpleThreshold_differentThresholdsDifferentXdr() throws {
        let a = try PolicyInstallParams.simpleThreshold(threshold: 2).toScVal()
        let b = try PolicyInstallParams.simpleThreshold(threshold: 3).toScVal()

        let encA = try Data(XDREncoder.encode(a))
        let encB = try Data(XDREncoder.encode(b))
        XCTAssertNotEqual(encA, encB, "Different threshold values must produce different XDR")
    }

    // ========================================================================
    // WeightedThreshold — ScVal shape (8 cases)
    // ========================================================================

    func test_weightedThreshold_createsMapWithCorrectKeys() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)
        let scVal = try PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 50)],
            threshold: 100
        ).toScVal()

        guard case .map(let entries) = scVal, let entries = entries else {
            return XCTFail("expected map")
        }
        XCTAssertEqual(entries.count, 2, "WeightedThreshold map must have exactly 2 entries")
        XCTAssertEqual(extractSymbolName(entries[0].key), "signer_weights")
        XCTAssertEqual(extractSymbolName(entries[1].key), "threshold")
    }

    func test_weightedThreshold_thresholdValueIsCorrect() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)
        let scVal = try PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 50)],
            threshold: 100
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let thresholdEntry = entries.first { extractSymbolName($0.key) == "threshold" }
        XCTAssertNotNil(thresholdEntry)
        guard case .u32(let v) = thresholdEntry!.val else {
            return XCTFail("expected u32 threshold")
        }
        XCTAssertEqual(v, 100)
    }

    func test_weightedThreshold_signerWeightsInnerMapContainsCorrectEntries() throws {
        let signer1 = try OZDelegatedSigner(address: validAddr1)
        let signer2 = try OZDelegatedSigner(address: validAddr2)
        let scVal = try PolicyInstallParams.weightedThreshold(
            signerWeights: [
                SignerWeightEntry(signer: signer1, weight: 60),
                SignerWeightEntry(signer: signer2, weight: 40)
            ],
            threshold: 100
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let signerWeightsEntry = entries.first { extractSymbolName($0.key) == "signer_weights" }
        XCTAssertNotNil(signerWeightsEntry)
        let inner = try extractMapEntries(signerWeightsEntry!.val)
        XCTAssertEqual(inner.count, 2)

        var observed = Set<UInt32>()
        for entry in inner {
            guard case .u32(let w) = entry.val else {
                return XCTFail("expected u32 weight")
            }
            observed.insert(w)
        }
        XCTAssertTrue(observed.contains(60))
        XCTAssertTrue(observed.contains(40))
    }

    func test_weightedThreshold_signerWeightsAreSortedByXdr() throws {
        let signer1 = try OZDelegatedSigner(address: validAddr1)
        let signer2 = try OZDelegatedSigner(address: validAddr2)
        let signer3 = try OZDelegatedSigner(address: validAddr3)
        // Insert reversed so the sort actually has work to do.
        let scVal = try PolicyInstallParams.weightedThreshold(
            signerWeights: [
                SignerWeightEntry(signer: signer3, weight: 20),
                SignerWeightEntry(signer: signer1, weight: 50),
                SignerWeightEntry(signer: signer2, weight: 30)
            ],
            threshold: 100
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let signerWeightsEntry = entries.first { extractSymbolName($0.key) == "signer_weights" }
        XCTAssertNotNil(signerWeightsEntry)
        let inner = try extractMapEntries(signerWeightsEntry!.val)
        XCTAssertEqual(inner.count, 3)

        for i in 0 ..< inner.count - 1 {
            let cur = OZPolicyManager.scValToXdrBytes(inner[i].key)
            let nxt = OZPolicyManager.scValToXdrBytes(inner[i + 1].key)
            XCTAssertLessThan(
                Data(cur).base16EncodedString(),
                Data(nxt).base16EncodedString()
            )
        }
    }

    func test_weightedThreshold_withExternalSigners() throws {
        let signer = try OZExternalSigner(
            verifierAddress: validVerifier,
            keyData: Data([0x01, 0x02, 0x03, 0x04])
        )
        let scVal = try PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 75)],
            threshold: 75
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(extractSymbolName(entries[0].key), "signer_weights")
        XCTAssertEqual(extractSymbolName(entries[1].key), "threshold")

        let inner = try extractMapEntries(entries[0].val)
        XCTAssertEqual(inner.count, 1)

        // ExternalSigner encodes as a Vec; verify the discriminant.
        guard case .vec = inner[0].key else {
            return XCTFail("expected ExternalSigner key to be a Vec")
        }
        guard case .u32(let w) = inner[0].val else {
            return XCTFail("expected u32 weight")
        }
        XCTAssertEqual(w, 75)
    }

    func test_weightedThreshold_mixedDelegatedAndExternalSigners() throws {
        let delegated = try OZDelegatedSigner(address: validAddr1)
        let external = try OZExternalSigner(
            verifierAddress: validVerifier,
            keyData: Data([0x01, 0x02, 0x03, 0x04])
        )
        let scVal = try PolicyInstallParams.weightedThreshold(
            signerWeights: [
                SignerWeightEntry(signer: delegated, weight: 60),
                SignerWeightEntry(signer: external, weight: 40)
            ],
            threshold: 100
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let inner = try extractMapEntries(entries[0].val)
        XCTAssertEqual(inner.count, 2)

        // Both signer kinds encode as a Vec; verify all keys are vec-shaped.
        for entry in inner {
            guard case .vec = entry.key else {
                return XCTFail("expected Vec-shaped signer key")
            }
        }
        // Verify ordering by XDR bytes.
        for i in 0 ..< inner.count - 1 {
            let cur = OZPolicyManager.scValToXdrBytes(inner[i].key)
            let nxt = OZPolicyManager.scValToXdrBytes(inner[i + 1].key)
            XCTAssertLessThan(
                Data(cur).base16EncodedString(),
                Data(nxt).base16EncodedString()
            )
        }
    }

    func test_weightedThreshold_emptySignerWeightsThrows() throws {
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [],
            threshold: 100
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("at least one signer"),
                "Error message should mention at least one signer requirement"
            )
        }
    }

    func test_weightedThreshold_deterministicRegardlessOfInsertionOrder() throws {
        let signer1 = try OZDelegatedSigner(address: validAddr1)
        let signer2 = try OZDelegatedSigner(address: validAddr2)

        let a = try PolicyInstallParams.weightedThreshold(
            signerWeights: [
                SignerWeightEntry(signer: signer1, weight: 50),
                SignerWeightEntry(signer: signer2, weight: 30)
            ],
            threshold: 80
        ).toScVal()
        let b = try PolicyInstallParams.weightedThreshold(
            signerWeights: [
                SignerWeightEntry(signer: signer2, weight: 30),
                SignerWeightEntry(signer: signer1, weight: 50)
            ],
            threshold: 80
        ).toScVal()

        let encA = try Data(XDREncoder.encode(a))
        let encB = try Data(XDREncoder.encode(b))
        XCTAssertEqual(encA, encB, "Same signers in different order must produce identical XDR")
    }

    // ========================================================================
    // SpendingLimit — ScVal shape (8 cases)
    // ========================================================================

    func test_spendingLimit_createsMapWithCorrectKeys() throws {
        let scVal = try PolicyInstallParams.spendingLimit(
            spendingLimit: "10000000",
            periodLedgers: 17_280
        ).toScVal()

        guard case .map(let entries) = scVal, let entries = entries else {
            return XCTFail("expected map")
        }
        XCTAssertEqual(entries.count, 2, "SpendingLimit map must have exactly 2 entries")
        XCTAssertEqual(extractSymbolName(entries[0].key), "period_ledgers")
        XCTAssertEqual(extractSymbolName(entries[1].key), "spending_limit")
    }

    func test_spendingLimit_periodLedgersIsU32() throws {
        let scVal = try PolicyInstallParams.spendingLimit(
            spendingLimit: "10000000",
            periodLedgers: 17_280
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let periodEntry = entries.first { extractSymbolName($0.key) == "period_ledgers" }
        XCTAssertNotNil(periodEntry)
        guard case .u32(let v) = periodEntry!.val else {
            return XCTFail("expected u32 period_ledgers")
        }
        XCTAssertEqual(v, 17_280)
    }

    func test_spendingLimit_spendingLimitIsI128() throws {
        let scVal = try PolicyInstallParams.spendingLimit(
            spendingLimit: "10000000",
            periodLedgers: 17_280
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let limitEntry = entries.first { extractSymbolName($0.key) == "spending_limit" }
        XCTAssertNotNil(limitEntry)
        guard case .i128(let parts) = limitEntry!.val else {
            return XCTFail("expected i128 spending_limit")
        }
        XCTAssertEqual(parts.hi, 0, "Hi part must be 0 for positive values within Long range")
        XCTAssertEqual(parts.lo, 10_000_000, "Lo part must match the stroops value")
    }

    func test_spendingLimit_largeI128Value() throws {
        // 1 billion XLM = 10_000_000_000_000_000 stroops.
        let stroops = "10000000000000000"
        let scVal = try PolicyInstallParams.spendingLimit(
            spendingLimit: stroops,
            periodLedgers: UInt32(StellarProtocolConstants.ledgersPerDay)
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let limitEntry = entries.first { extractSymbolName($0.key) == "spending_limit" }
        XCTAssertNotNil(limitEntry)
        guard case .i128(let parts) = limitEntry!.val else {
            return XCTFail("expected i128 spending_limit")
        }
        XCTAssertEqual(parts.hi, 0)
        XCTAssertEqual(parts.lo, 10_000_000_000_000_000)
    }

    func test_spendingLimit_zeroSpendingLimitThrows() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "0",
            periodLedgers: 17_280
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("greater than zero"),
                "Error message should mention spending limit must be greater than zero"
            )
        }
    }

    func test_spendingLimit_negativeSpendingLimitThrows() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "-100",
            periodLedgers: 17_280
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("greater than zero"),
                "Error message should mention spending limit must be greater than zero"
            )
        }
    }

    func test_spendingLimit_zeroPeriodLedgersThrows() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "10000000",
            periodLedgers: 0
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("greater than zero"),
                "Error message should mention period ledgers must be greater than zero"
            )
        }
    }

    func test_spendingLimit_deterministicXdrEncoding() throws {
        let a = try PolicyInstallParams.spendingLimit(
            spendingLimit: "50000000",
            periodLedgers: 34_560
        ).toScVal()
        let b = try PolicyInstallParams.spendingLimit(
            spendingLimit: "50000000",
            periodLedgers: 34_560
        ).toScVal()

        let encA = try Data(XDREncoder.encode(a))
        let encB = try Data(XDREncoder.encode(b))
        XCTAssertEqual(encA, encB, "Identical SpendingLimit params must produce identical XDR")
    }

    // ========================================================================
    // SpendingLimit — boundary period values (2 cases)
    // ========================================================================

    func test_spendingLimit_oneLedgerPeriod() throws {
        let scVal = try PolicyInstallParams.spendingLimit(
            spendingLimit: "1",
            periodLedgers: 1
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let periodEntry = entries.first { extractSymbolName($0.key) == "period_ledgers" }
        let limitEntry = entries.first { extractSymbolName($0.key) == "spending_limit" }
        XCTAssertNotNil(periodEntry)
        XCTAssertNotNil(limitEntry)

        guard case .u32(let p) = periodEntry!.val,
              case .i128(let parts) = limitEntry!.val else {
            return XCTFail("unexpected SCVal shape")
        }
        XCTAssertEqual(p, 1)
        XCTAssertEqual(parts.hi, 0)
        XCTAssertEqual(parts.lo, 1)
    }

    func test_spendingLimit_maxUInt32PeriodLedgers() throws {
        let scVal = try PolicyInstallParams.spendingLimit(
            spendingLimit: "1000000",
            periodLedgers: UInt32.max
        ).toScVal()

        let entries = try extractMapEntries(scVal)
        let periodEntry = entries.first { extractSymbolName($0.key) == "period_ledgers" }
        XCTAssertNotNil(periodEntry)
        guard case .u32(let p) = periodEntry!.val else {
            return XCTFail("expected u32 period")
        }
        XCTAssertEqual(p, UInt32.max)
    }

    // ========================================================================
    // Cross-policy-type verification (2 cases)
    // ========================================================================

    func test_allPolicyTypes_produceMapScVal() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)

        let simple = try PolicyInstallParams.simpleThreshold(threshold: 2).toScVal()
        let weighted = try PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 50)],
            threshold: 50
        ).toScVal()
        let spending = try PolicyInstallParams.spendingLimit(
            spendingLimit: "10000000",
            periodLedgers: 17_280
        ).toScVal()

        if case .map = simple { } else { XCTFail("simple should produce a map") }
        if case .map = weighted { } else { XCTFail("weighted should produce a map") }
        if case .map = spending { } else { XCTFail("spending should produce a map") }
    }

    func test_allPolicyTypes_produceDifferentXdr() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)

        let simpleEnc = try Data(XDREncoder.encode(
            try PolicyInstallParams.simpleThreshold(threshold: 2).toScVal()
        ))
        let weightedEnc = try Data(XDREncoder.encode(
            try PolicyInstallParams.weightedThreshold(
                signerWeights: [SignerWeightEntry(signer: signer, weight: 50)],
                threshold: 50
            ).toScVal()
        ))
        let spendingEnc = try Data(XDREncoder.encode(
            try PolicyInstallParams.spendingLimit(
                spendingLimit: "10000000",
                periodLedgers: 17_280
            ).toScVal()
        ))

        XCTAssertNotEqual(simpleEnc, weightedEnc)
        XCTAssertNotEqual(simpleEnc, spendingEnc)
        XCTAssertNotEqual(weightedEnc, spendingEnc)
    }

    // ========================================================================
    // amountToStroops — XLM conversion (8 cases)
    // ========================================================================

    func test_amountToStroops_oneXlm() throws {
        let stroops = try OZTransactionOperations.amountToStroops("1")
        XCTAssertEqual(stroops, 10_000_000)
    }

    func test_amountToStroops_fractionalAmount() throws {
        let stroops = try OZTransactionOperations.amountToStroops("0.5")
        XCTAssertEqual(stroops, 5_000_000)
    }

    func test_amountToStroops_largeAmount() throws {
        let stroops = try OZTransactionOperations.amountToStroops("1000")
        XCTAssertEqual(stroops, 10_000_000_000)
    }

    func test_amountToStroops_emptyString_throws() throws {
        do {
            _ = try OZTransactionOperations.amountToStroops("")
            XCTFail("expected validation error")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_amountToStroops_whitespace_throws() throws {
        do {
            _ = try OZTransactionOperations.amountToStroops("   ")
            XCTFail("expected validation error")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_amountToStroops_nonNumeric_throws() throws {
        do {
            _ = try OZTransactionOperations.amountToStroops("abc")
            XCTFail("expected validation error")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_amountToStroops_scientificNotation_throws() throws {
        do {
            _ = try OZTransactionOperations.amountToStroops("1e7")
            XCTFail("expected validation error")
        } catch is ValidationException.InvalidAmount {
            // expected
        }
    }

    func test_amountToStroops_decimalPrecision() throws {
        let stroops = try OZTransactionOperations.amountToStroops("10.5")
        XCTAssertEqual(stroops, 105_000_000)
    }

    // ========================================================================
    // createSpendingLimitParams — convenience builder (2 cases)
    // ========================================================================

    func test_createSpendingLimitParams_valid() throws {
        let params = try OZSmartAccountBuilders.createSpendingLimitParams(
            spendingLimit: "100",
            periodLedgers: 720
        )
        XCTAssertEqual(params.spendingLimit, 1_000_000_000)
        XCTAssertEqual(params.periodLedgers, 720)
    }

    func test_createSpendingLimitParams_zeroPeriod_throws() throws {
        do {
            _ = try OZSmartAccountBuilders.createSpendingLimitParams(
                spendingLimit: "100",
                periodLedgers: 0
            )
            XCTFail("expected validation error")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // SCValXDR.i128(stroops:) — Int64 widening (1 case)
    // ========================================================================

    func test_scValI128Stroops_basicValue() throws {
        let scVal = SCValXDR.i128(stroops: 10_000_000)
        guard case .i128(let parts) = scVal else {
            return XCTFail("expected i128")
        }
        XCTAssertEqual(parts.hi, 0)
        XCTAssertEqual(parts.lo, 10_000_000)
    }

    // ========================================================================
    // OZPolicyManager — addPolicy / removePolicy routing (3 cases)
    // ========================================================================

    /// Disconnected kit + addPolicy must throw `WalletException.NotConnected`
    /// before performing any submission.
    func test_addPolicy_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        let installParams = try PolicyInstallParams
            .simpleThreshold(threshold: 2)
            .toScVal()
        do {
            _ = try await manager.addPolicy(
                contextRuleId: 0,
                policyAddress: validVerifier,
                installParams: installParams
            )
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    /// Connected kit + addPolicy with malformed policy address must throw
    /// `ValidationException.InvalidAddress` before any submission attempt.
    func test_addPolicy_invalidPolicyAddress_throws() async throws {
        let (_, manager) = try connectedKit()
        let installParams = try PolicyInstallParams
            .simpleThreshold(threshold: 2)
            .toScVal()
        do {
            _ = try await manager.addPolicy(
                contextRuleId: 0,
                policyAddress: "not-a-stellar-address",
                installParams: installParams
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertTrue(error.message.contains("policyAddress"))
        }
    }

    /// Disconnected kit + removePolicy by id must throw
    /// `WalletException.NotConnected`.
    func test_removePolicy_byId_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.removePolicy(
                contextRuleId: 0,
                policyId: 1
            )
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    // ========================================================================
    // OZPolicyManager — buildAddPolicyFunction shape (1 case)
    // ========================================================================

    /// `add_policy` invocation must carry the contract address, the function
    /// name `"add_policy"`, and the three positional arguments
    /// `[u32 contextRuleId, address policyAddress, installParams]`.
    func test_buildAddPolicyFunction_argShape() throws {
        let installParams = try PolicyInstallParams
            .simpleThreshold(threshold: 2)
            .toScVal()
        let hostFunction = try OZPolicyManager.buildAddPolicyFunction(
            contractId: validContractC2,
            contextRuleId: 7,
            policyAddress: validVerifier,
            installParams: installParams
        )
        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "add_policy")
        XCTAssertEqual(invokeArgs.args.count, 3)

        guard case .u32(let ruleId) = invokeArgs.args[0] else {
            return XCTFail("first arg must be u32 contextRuleId")
        }
        XCTAssertEqual(ruleId, 7)

        guard case .address = invokeArgs.args[1] else {
            return XCTFail("second arg must be address policyAddress")
        }

        // Third arg is the SCVal install params payload — verify it round-trips
        // byte-equally with the input.
        let inputBytes = try Data(XDREncoder.encode(installParams))
        let outputBytes = try Data(XDREncoder.encode(invokeArgs.args[2]))
        XCTAssertEqual(inputBytes, outputBytes)
    }

    // ========================================================================
    // OZPolicyManager — buildRemovePolicyFunction shape (1 case)
    // ========================================================================

    /// `remove_policy` invocation must carry the contract address, the function
    /// name `"remove_policy"`, and the two positional arguments
    /// `[u32 contextRuleId, u32 policyId]`.
    func test_buildRemovePolicyFunction_argShape() throws {
        let hostFunction = try OZPolicyManager.buildRemovePolicyFunction(
            contractId: validContractC2,
            contextRuleId: 3,
            policyId: 9
        )
        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "remove_policy")
        XCTAssertEqual(invokeArgs.args.count, 2)

        guard case .u32(let ruleId) = invokeArgs.args[0],
              case .u32(let policyId) = invokeArgs.args[1] else {
            return XCTFail("expected two u32 args")
        }
        XCTAssertEqual(ruleId, 3)
        XCTAssertEqual(policyId, 9)
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    private func extractMapEntries(_ scVal: SCValXDR) throws -> [SCMapEntryXDR] {
        guard case .map(let entries) = scVal else {
            XCTFail("expected SCValXDR.map, got \(scVal)")
            throw NSError(domain: "OZPolicyManagerTests", code: 1)
        }
        return entries ?? []
    }

    private func extractSymbolName(_ scVal: SCValXDR) -> String {
        guard case .symbol(let name) = scVal else {
            XCTFail("expected SCValXDR.symbol, got \(scVal)")
            return ""
        }
        return name
    }

    // ========================================================================
    // F-TC-iOS-1 — amountToStroops boundary cases
    // ========================================================================

    /// Sub-stroop amount strings (8 fractional digits) must be rejected. The
    /// XLM precision floor is one stroop = `0.0000001`, so anything finer is
    /// a malformed amount.
    func test_amountToStroops_subStroopAmount_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("0.00000001")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount)
        }
    }

    /// `0.0000001` is the smallest representable XLM amount (one stroop).
    /// The parser must accept it and return `1`.
    func test_amountToStroops_maxPrecision_oneStroop() throws {
        let stroops = try OZTransactionOperations.amountToStroops("0.0000001")
        XCTAssertEqual(stroops, 1, "0.0000001 XLM is exactly one stroop")
    }

    /// Spending-limit convenience helpers must reject negative, zero, and
    /// non-numeric amount strings before reaching the host-function builder.
    func test_createSpendingLimitParams_invalidAmount_throws() async {
        let (_, manager) = try! connectedKit()

        for invalid in ["-1", "0", "abc", "1e5", ""] {
            do {
                _ = try await manager.addSpendingLimit(
                    contextRuleId: 0,
                    policyAddress: validContractC2,
                    spendingLimit: invalid,
                    periodLedgers: 17280
                )
                XCTFail("expected ValidationException for spendingLimit=\(invalid)")
            } catch is ValidationException {
                // expected
            } catch {
                XCTFail("expected ValidationException for spendingLimit=\(invalid), got: \(error)")
            }
        }
    }

    /// `Int64.max` stroops must round-trip through the I128 SCVal helper
    /// without truncation. The high-64 bits of the result must be zero
    /// because the value fits in the signed 64-bit range.
    func test_stroopsToI128ScVal_maxLongValue_roundtrips() throws {
        let scVal = SCValXDR.i128(stroops: Int64.max)
        guard case .i128(let parts) = scVal else {
            return XCTFail("expected i128 SCVal, got \(scVal)")
        }
        XCTAssertEqual(parts.lo, UInt64(Int64.max), "Int64.max stroops must occupy the lo 64 bits exactly")
        XCTAssertEqual(parts.hi, 0, "Int64.max stroops must leave hi = 0 (positive value within Int64 range)")
    }

    // ========================================================================
    // F-TC-iOS-1 — amountToStroops additional boundary coverage
    // ========================================================================

    /// `"0"` is not a valid spending amount: the parser surfaces a strict
    /// `ValidationException.InvalidAmount` rather than returning zero stroops.
    /// Zero-amount transactions are not legitimate XLM moves and must be
    /// rejected upfront so downstream policy checks operate on a non-zero
    /// post-condition.
    func test_amountToStroops_zeroAmount_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("0")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount,
                          "expected ValidationException.InvalidAmount, got \(type(of: error))")
        }
    }

    /// Negative amounts must be rejected upfront. The parser's strict regex
    /// rejects the leading `-` sign and surfaces
    /// `ValidationException.InvalidAmount` so the caller does not produce a
    /// signed-int wraparound at the I128 conversion boundary.
    func test_amountToStroops_negativeAmount_throws() {
        XCTAssertThrowsError(try OZTransactionOperations.amountToStroops("-1")) { error in
            XCTAssertTrue(error is ValidationException.InvalidAmount,
                          "expected ValidationException.InvalidAmount, got \(type(of: error))")
        }
    }

    /// The maximum representable XLM amount that fits in `Int64` stroops is
    /// `922337203685.4775807` (Int64.max stroops = 9_223_372_036_854_775_807).
    /// The parser must accept this string and return `Int64.max` exactly,
    /// proving the conversion arithmetic does not silently overflow at the
    /// upper boundary.
    func test_amountToStroops_extremelyLargeButValidAmount_roundtripsToInt64Max() throws {
        let stroops = try OZTransactionOperations.amountToStroops("922337203685.4775807")
        XCTAssertEqual(stroops, Int64.max,
                       "Largest representable XLM amount must round-trip to Int64.max stroops")
    }

    /// Decimal-separator edge cases: leading-zero whole part (`"0.5"`) and a
    /// trailing-zero fractional part (`"1.5000000"`). Both are well-formed
    /// numeric strings within the seven-fractional-digit floor and must
    /// round-trip to the same stroop value as the canonical forms (`"0.5"`
    /// produces 5_000_000 stroops; `"1.5000000"` matches `"1.5"`'s
    /// 15_000_000 stroops).
    func test_amountToStroops_decimalSeparatorEdgeCases() throws {
        let leadingZero = try OZTransactionOperations.amountToStroops("0.5")
        XCTAssertEqual(leadingZero, 5_000_000,
                       "0.5 XLM must be 5,000,000 stroops")

        let trailingZeros = try OZTransactionOperations.amountToStroops("1.5000000")
        XCTAssertEqual(trailingZeros, 15_000_000,
                       "1.5000000 XLM must be 15,000,000 stroops (trailing zeros padded as expected)")

        // Cross-check: trailing zeros must produce the same value as the
        // shorter canonical form.
        let canonical = try OZTransactionOperations.amountToStroops("1.5")
        XCTAssertEqual(trailingZeros, canonical,
                       "1.5000000 and 1.5 must produce identical stroop values")
    }
}
