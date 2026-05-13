//
//  OZPolicyInstallParamsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for `PolicyInstallParams` validation logic, ScVal structure
/// correctness, and the sealed-arm boundary cases.
///
/// Coverage focuses on:
/// - Validation error messages and the field-tagged exception type the kit
///   surfaces uniformly across every input failure.
/// - Threshold and weight boundary values (one, max).
/// - `WeightedThreshold` validation order — threshold-zero is checked before
///   empty-signers, so the surfaced error reflects the first failure.
/// - `SpendingLimit` values approaching and crossing the `Int64` ceiling
///   (full I128 range support via the decimal-string overload).
/// - `sortMapByKeyXdr` immutability and determinism on the supplied input.
/// - Sealed-enum exhaustivity and arm equality semantics.
final class OZPolicyInstallParamsTests: XCTestCase {

    private let validAddr1 = "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7"
    private let validAddr2 = "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW"
    private let validAddr3 = "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG"
    private let validVerifier1 = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let validVerifier2 = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"

    // ========================================================================
    // SimpleThreshold — validation error messages (2 cases)
    // ========================================================================

    func test_simpleThreshold_zeroThreshold_exceptionMessage() throws {
        do {
            _ = try PolicyInstallParams.simpleThreshold(threshold: 0).toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Threshold must be greater than zero"),
                "Error message must state that threshold must be greater than zero, got: \(error.message)"
            )
        }
    }

    func test_simpleThreshold_zeroThreshold_exceptionFieldName() throws {
        do {
            _ = try PolicyInstallParams.simpleThreshold(threshold: 0).toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("threshold"),
                "Error message must reference the 'threshold' field"
            )
        }
    }

    // ========================================================================
    // SimpleThreshold — sealed-enum equality (3 cases)
    // ========================================================================

    func test_simpleThreshold_caseEquality_sameValue() throws {
        let a = PolicyInstallParams.simpleThreshold(threshold: 5)
        let b = PolicyInstallParams.simpleThreshold(threshold: 5)
        // Compare encoded ScVals — the sealed enum has no synthesized Equatable
        // because its `weightedThreshold` arm carries existential signers that
        // do not conform to `Equatable`. Encoded bytes are the cross-cutting
        // identity check that matters for on-chain semantics.
        let encA = try Data(XDREncoder.encode(try a.toScVal()))
        let encB = try Data(XDREncoder.encode(try b.toScVal()))
        XCTAssertEqual(encA, encB)
    }

    func test_simpleThreshold_caseInequality_differentValue() throws {
        let a = PolicyInstallParams.simpleThreshold(threshold: 5)
        let b = PolicyInstallParams.simpleThreshold(threshold: 6)
        let encA = try Data(XDREncoder.encode(try a.toScVal()))
        let encB = try Data(XDREncoder.encode(try b.toScVal()))
        XCTAssertNotEqual(encA, encB)
    }

    /// Verifies the case captures the threshold value passed in — the
    /// associated value round-trips through pattern matching unchanged.
    func test_simpleThreshold_associatedValueRoundtrip() throws {
        let original = PolicyInstallParams.simpleThreshold(threshold: 3)
        let modified = PolicyInstallParams.simpleThreshold(threshold: 7)
        guard case .simpleThreshold(let originalThreshold) = original else {
            return XCTFail("expected simpleThreshold case")
        }
        guard case .simpleThreshold(let modifiedThreshold) = modified else {
            return XCTFail("expected simpleThreshold case")
        }
        XCTAssertEqual(originalThreshold, 3)
        XCTAssertEqual(modifiedThreshold, 7)
    }

    // ========================================================================
    // WeightedThreshold — zero threshold validation (2 cases)
    // ========================================================================

    func test_weightedThreshold_zeroThreshold_throws() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 50)],
            threshold: 0
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Threshold must be greater than zero"),
                "Zero threshold in WeightedThreshold must be rejected with clear message"
            )
        }
    }

    /// When both `threshold == 0` and `signerWeights` is empty, the threshold
    /// check runs first per the implementation order.
    func test_weightedThreshold_zeroThreshold_checkedBeforeEmptySigners() throws {
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [],
            threshold: 0
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Threshold must be greater than zero"),
                "Threshold validation must execute before signer weights validation"
            )
        }
    }

    // ========================================================================
    // WeightedThreshold — threshold boundary values (2 cases)
    // ========================================================================

    func test_weightedThreshold_thresholdOfOne() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 1)],
            threshold: 1
        )
        let scVal = try params.toScVal()
        let entries = try extractMapEntries(scVal)
        let thresholdEntry = entries.first { extractSymbolName($0.key) == "threshold" }
        XCTAssertNotNil(thresholdEntry)
        guard case .u32(let v) = thresholdEntry!.val else {
            return XCTFail("expected u32 threshold")
        }
        XCTAssertEqual(v, 1)
    }

    func test_weightedThreshold_maxUInt32Threshold() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: UInt32.max)],
            threshold: UInt32.max
        )
        let scVal = try params.toScVal()
        let entries = try extractMapEntries(scVal)
        let thresholdEntry = entries.first { extractSymbolName($0.key) == "threshold" }
        XCTAssertNotNil(thresholdEntry)
        guard case .u32(let v) = thresholdEntry!.val else {
            return XCTFail("expected u32 threshold")
        }
        XCTAssertEqual(v, UInt32.max)
    }

    // ========================================================================
    // WeightedThreshold — multi-signer structure (2 cases)
    // ========================================================================

    /// Five signers (mix of delegated and external) — verifies the inner map
    /// preserves every input and the keys end up sorted by XDR bytes.
    func test_weightedThreshold_fiveSigners_allSortedByXdr() throws {
        let signers: [any OZSmartAccountSigner] = [
            try OZDelegatedSigner(address: validAddr1),
            try OZDelegatedSigner(address: validAddr2),
            try OZDelegatedSigner(address: validAddr3),
            try OZExternalSigner(verifierAddress: validVerifier1, keyData: Data([0x01, 0x02, 0x03])),
            try OZExternalSigner(verifierAddress: validVerifier2, keyData: Data([0x04, 0x05, 0x06]))
        ]
        // Reverse-order insertion to verify the sort actually runs.
        let weights: [SignerWeightEntry] = [
            SignerWeightEntry(signer: signers[4], weight: 10),
            SignerWeightEntry(signer: signers[2], weight: 20),
            SignerWeightEntry(signer: signers[0], weight: 30),
            SignerWeightEntry(signer: signers[3], weight: 25),
            SignerWeightEntry(signer: signers[1], weight: 15)
        ]
        let params = PolicyInstallParams.weightedThreshold(signerWeights: weights, threshold: 100)
        let scVal = try params.toScVal()

        let outerEntries = try extractMapEntries(scVal)
        let signerWeightsEntry = outerEntries.first { extractSymbolName($0.key) == "signer_weights" }
        XCTAssertNotNil(signerWeightsEntry)
        let innerEntries = try extractMapEntries(signerWeightsEntry!.val)
        XCTAssertEqual(innerEntries.count, 5)

        for i in 0 ..< innerEntries.count - 1 {
            let cur = OZPolicyManager.scValToXdrBytes(innerEntries[i].key)
            let nxt = OZPolicyManager.scValToXdrBytes(innerEntries[i + 1].key)
            let curHex = Data(cur).base16EncodedString()
            let nxtHex = Data(nxt).base16EncodedString()
            XCTAssertLessThan(curHex, nxtHex)
        }

        // Every weight value must round-trip into the inner map.
        var observed = Set<UInt32>()
        for entry in innerEntries {
            guard case .u32(let w) = entry.val else { continue }
            observed.insert(w)
        }
        XCTAssertEqual(observed, Set([10, 15, 20, 25, 30]))
    }

    func test_weightedThreshold_singleSigner_weightEqualsThreshold() throws {
        let signer = try OZDelegatedSigner(address: validAddr1)
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 100)],
            threshold: 100
        )
        let scVal = try params.toScVal()
        let outerEntries = try extractMapEntries(scVal)
        let innerEntries = try extractMapEntries(outerEntries[0].val)
        XCTAssertEqual(innerEntries.count, 1)
        guard case .u32(let w) = innerEntries[0].val else {
            return XCTFail("expected u32 weight")
        }
        XCTAssertEqual(w, 100)
    }

    // ========================================================================
    // WeightedThreshold — empty signer weights (1 case)
    // ========================================================================

    func test_weightedThreshold_emptySigners_exceptionMessage() throws {
        let params = PolicyInstallParams.weightedThreshold(
            signerWeights: [],
            threshold: 10
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("at least one signer with weight"),
                "Error message must mention requirement for at least one signer"
            )
        }
    }

    // ========================================================================
    // SpendingLimit — large I128 values (3 cases)
    // ========================================================================

    /// Long.MAX_VALUE + 1 fits in `ULong` (lo part), `hi` should remain 0.
    func test_spendingLimit_valueExceedingInt64MaxValue() throws {
        // Int64.max = 9_223_372_036_854_775_807; +1 = 9_223_372_036_854_775_808.
        let beyond = "9223372036854775808"
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: beyond,
            periodLedgers: 17_280
        )
        let scVal = try params.toScVal()
        let outerEntries = try extractMapEntries(scVal)
        let limitEntry = outerEntries.first { extractSymbolName($0.key) == "spending_limit" }
        XCTAssertNotNil(limitEntry)
        guard case .i128(let parts) = limitEntry!.val else {
            return XCTFail("expected i128 limit")
        }
        XCTAssertEqual(parts.hi, 0, "2^63 fits in ULong, hi must be 0")
        XCTAssertEqual(parts.lo, UInt64(Int64.max) + 1)
    }

    /// `2^64` must set `hi=1`, `lo=0`.
    func test_spendingLimit_veryLargeValueRequiringHiBits() throws {
        let beyondULong = "18446744073709551616" // 2^64
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: beyondULong,
            periodLedgers: 720
        )
        let scVal = try params.toScVal()
        let outerEntries = try extractMapEntries(scVal)
        let limitEntry = outerEntries.first { extractSymbolName($0.key) == "spending_limit" }
        XCTAssertNotNil(limitEntry)
        guard case .i128(let parts) = limitEntry!.val else {
            return XCTFail("expected i128 limit")
        }
        XCTAssertEqual(parts.hi, 1, "2^64 must set hi=1")
        XCTAssertEqual(parts.lo, 0, "2^64 must set lo=0")
    }

    /// Maximum positive I128 = `2^127 - 1`.
    func test_spendingLimit_i128MaxPositiveValue() throws {
        let i128Max = "170141183460469231731687303715884105727"
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: i128Max,
            periodLedgers: 1
        )
        let scVal = try params.toScVal()
        let outerEntries = try extractMapEntries(scVal)
        let limitEntry = outerEntries.first { extractSymbolName($0.key) == "spending_limit" }
        XCTAssertNotNil(limitEntry)
        guard case .i128(let parts) = limitEntry!.val else {
            return XCTFail("expected i128 limit")
        }
        XCTAssertEqual(parts.hi, Int64.max, "I128 max hi must be Int64.max")
        XCTAssertEqual(parts.lo, UInt64.max, "I128 max lo must be UInt64.max")
    }

    // ========================================================================
    // SpendingLimit — validation error messages (3 cases)
    // ========================================================================

    func test_spendingLimit_zeroLimit_exceptionMessage() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "0",
            periodLedgers: 17_280
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Spending limit must be greater than zero"),
                "Error message must state spending limit requirement"
            )
        }
    }

    func test_spendingLimit_zeroPeriod_exceptionMessage() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "10000000",
            periodLedgers: 0
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Period ledgers must be greater than zero"),
                "Error message must state period ledgers requirement"
            )
        }
    }

    func test_spendingLimit_negativeLimit_exceptionMessageIncludesValue() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "-500",
            periodLedgers: 17_280
        )
        do {
            _ = try params.toScVal()
            XCTFail("expected validation error")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("-500"),
                "Error message must include the invalid value"
            )
        }
    }

    // ========================================================================
    // SpendingLimit — boundary period values (1 case)
    // ========================================================================

    func test_spendingLimit_singleLedgerPeriod_minimumValues() throws {
        let params = PolicyInstallParams.spendingLimit(
            spendingLimit: "1",
            periodLedgers: 1
        )
        let scVal = try params.toScVal()
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

    // ========================================================================
    // SpendingLimit — sealed-enum equality / arm capture (3 cases)
    // ========================================================================

    func test_spendingLimit_caseEquality_sameValue() throws {
        let a = PolicyInstallParams.spendingLimit(spendingLimit: "1000000", periodLedgers: 720)
        let b = PolicyInstallParams.spendingLimit(spendingLimit: "1000000", periodLedgers: 720)
        let encA = try Data(XDREncoder.encode(try a.toScVal()))
        let encB = try Data(XDREncoder.encode(try b.toScVal()))
        XCTAssertEqual(encA, encB)
    }

    func test_spendingLimit_caseInequality_differentLimit() throws {
        let a = PolicyInstallParams.spendingLimit(spendingLimit: "1000000", periodLedgers: 720)
        let b = PolicyInstallParams.spendingLimit(spendingLimit: "2000000", periodLedgers: 720)
        let encA = try Data(XDREncoder.encode(try a.toScVal()))
        let encB = try Data(XDREncoder.encode(try b.toScVal()))
        XCTAssertNotEqual(encA, encB)
    }

    func test_spendingLimit_caseInequality_differentPeriod() throws {
        let a = PolicyInstallParams.spendingLimit(spendingLimit: "1000000", periodLedgers: 720)
        let b = PolicyInstallParams.spendingLimit(spendingLimit: "1000000", periodLedgers: 1440)
        let encA = try Data(XDREncoder.encode(try a.toScVal()))
        let encB = try Data(XDREncoder.encode(try b.toScVal()))
        XCTAssertNotEqual(encA, encB)
    }

    // ========================================================================
    // sortMapByKeyXdr — extra edge cases (4 cases)
    // ========================================================================

    /// Reversed symbol keys of the same length sort alphabetically because the
    /// XDR length prefix is identical and the body bytes drive the order.
    func test_sortMapByKeyXdr_reversedSymbolKeysOfSameLength() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("zzz"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("aaa"), val: .u32(2)),
            SCMapEntryXDR(key: .symbol("mmm"), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(extractSymbolName(sorted[0].key), "aaa")
        XCTAssertEqual(extractSymbolName(sorted[1].key), "mmm")
        XCTAssertEqual(extractSymbolName(sorted[2].key), "zzz")
    }

    /// Symbols of differing length sort by length first, then alphabetically.
    func test_sortMapByKeyXdr_symbolKeysOfDifferentLengths() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("bb"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("a"), val: .u32(2)),
            SCMapEntryXDR(key: .symbol("aaa"), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(extractSymbolName(sorted[0].key), "a")
        XCTAssertEqual(extractSymbolName(sorted[1].key), "bb")
        XCTAssertEqual(extractSymbolName(sorted[2].key), "aaa")
    }

    /// U32 keys sort numerically — verified at the SCVal level here as a
    /// targeted regression guard separate from the broader Group-I coverage.
    func test_sortMapByKeyXdr_u32Keys_numericOrder() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .u32(300), val: .void),
            SCMapEntryXDR(key: .u32(100), val: .void),
            SCMapEntryXDR(key: .u32(200), val: .void)
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        guard case .u32(let v0) = sorted[0].key,
              case .u32(let v1) = sorted[1].key,
              case .u32(let v2) = sorted[2].key else {
            return XCTFail("expected u32 keys")
        }
        XCTAssertEqual([v0, v1, v2], [100, 200, 300])
    }

    /// The sort returns a new array — the input array is not mutated. Swift
    /// arrays are value types, so this property holds by language semantics
    /// regardless. The test confirms the contract explicitly.
    func test_sortMapByKeyXdr_doesNotModifyOriginal() throws {
        let original: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("z"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("a"), val: .u32(2))
        ]
        _ = OZPolicyManager.sortMapByKeyXdr(original)

        XCTAssertEqual(original.count, 2)
        XCTAssertEqual(extractSymbolName(original[0].key), "z")
        XCTAssertEqual(extractSymbolName(original[1].key), "a")
    }

    // ========================================================================
    // scValToXdrBytes — deterministic encoding (3 cases)
    // ========================================================================

    func test_scValToXdrBytes_sameInputProducesSameBytes() throws {
        let scVal = SCValXDR.symbol("test")
        let a = OZPolicyManager.scValToXdrBytes(scVal)
        let b = OZPolicyManager.scValToXdrBytes(scVal)
        XCTAssertEqual(a, b)
    }

    func test_scValToXdrBytes_differentInputProducesDifferentBytes() throws {
        let a = OZPolicyManager.scValToXdrBytes(.symbol("alpha"))
        let b = OZPolicyManager.scValToXdrBytes(.symbol("beta"))
        XCTAssertNotEqual(a, b)
    }

    func test_scValToXdrBytes_nonEmptyOutput() throws {
        let bytes = OZPolicyManager.scValToXdrBytes(.void)
        XCTAssertFalse(bytes.isEmpty, "XDR encoding of Void must produce non-empty bytes (the type discriminant alone is 4 bytes)")
    }

    // ========================================================================
    // Cross-type — sealed-arm exhaustivity (2 cases)
    // ========================================================================

    /// Each arm is a distinct case at the type level; the `switch` is
    /// exhaustive (compile-time check). Three concrete bindings demonstrate
    /// the polymorphic type can carry any arm.
    func test_policyInstallParams_isSealed() throws {
        let simple: PolicyInstallParams = .simpleThreshold(threshold: 1)
        let signer = try OZDelegatedSigner(address: validAddr1)
        let weighted: PolicyInstallParams = .weightedThreshold(
            signerWeights: [SignerWeightEntry(signer: signer, weight: 1)],
            threshold: 1
        )
        let spending: PolicyInstallParams = .spendingLimit(
            spendingLimit: "1",
            periodLedgers: 1
        )

        if case .simpleThreshold = simple { } else { XCTFail("simple should be simpleThreshold arm") }
        if case .weightedThreshold = weighted { } else { XCTFail("weighted should be weightedThreshold arm") }
        if case .spendingLimit = spending { } else { XCTFail("spending should be spendingLimit arm") }
    }

    /// Verifies a `switch` over `PolicyInstallParams` is exhaustive — Swift
    /// would emit a compile error if a new arm were added without updating
    /// this test, locking the case set in place.
    func test_policyInstallParams_switch_exhaustive() throws {
        let params: PolicyInstallParams = .simpleThreshold(threshold: 2)
        let typeName: String
        switch params {
        case .simpleThreshold: typeName = "simple"
        case .weightedThreshold: typeName = "weighted"
        case .spendingLimit: typeName = "spending"
        }
        XCTAssertEqual(typeName, "simple")
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    private func extractMapEntries(_ scVal: SCValXDR) throws -> [SCMapEntryXDR] {
        guard case .map(let entries) = scVal else {
            XCTFail("expected SCValXDR.map, got \(scVal)")
            throw NSError(domain: "OZPolicyInstallParamsTests", code: 1)
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
}
