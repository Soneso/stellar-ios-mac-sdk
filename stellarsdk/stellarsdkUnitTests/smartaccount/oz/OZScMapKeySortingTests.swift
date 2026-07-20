//
//  OZScMapKeySortingTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for `OZPolicyManager.sortMapByKeyXdr` and the byte-encoding helper
/// `OZPolicyManager.scValToXdrBytes`.
///
/// The sort routine is consumed by `OZPolicyInstallParams.weightedThreshold` for
/// the inner signer-weights map and by `OZContextRuleManager.addContextRule`
/// for the policies map. Both call sites depend on the keys being in the
/// Soroban host's ScMap key order: the host validates the order when it
/// materializes the map from an `SCVal` argument and rejects an out-of-order
/// map with `InvalidInput`, so a regression in this routine would surface as a
/// contract-side simulation failure for every weighted threshold install on
/// every chain.
///
/// Ordering rules exercised by these cases:
/// - Different SCVal types order by their discriminant value
///   (`SCV_U32 < SCV_BYTES < SCV_SYMBOL < SCV_ADDRESS …`).
/// - `Symbol`, `Bytes`, and `String` bodies compare by content, byte for byte
///   (unsigned); length is only a tiebreaker on a shared prefix.
/// - Struct-shaped outer keys are not subject to the dynamic-key sort — those
///   follow the alphabetical convention the Soroban Rust `#[contracttype]`
///   derive macro enforces. Those cases live in the policy-install-params
///   tests; this file covers the dynamic-key ordering path only.
final class OZScMapKeySortingTests: XCTestCase {

    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    // MARK: - Utility function tests (1 case)

    /// The comparator must treat bytes as unsigned and handle prefix
    /// relationships per the host's content-order contract (shorter first
    /// only on a shared prefix).
    func test_compareByteArraysLexicographically_unsignedAndPrefix() throws {
        // Equal arrays.
        XCTAssertEqual(
            compareKeyed(SCValXDR.bytes(Data([0x01, 0x02, 0x03])),
                         SCValXDR.bytes(Data([0x01, 0x02, 0x03]))),
            0
        )

        // First < second, differs at index 1.
        XCTAssertLessThan(
            compareKeyed(SCValXDR.bytes(Data([0x01, 0x02, 0x03])),
                         SCValXDR.bytes(Data([0x01, 0x03, 0x03]))),
            0
        )

        // Shorter < longer when prefix matches.
        XCTAssertLessThan(
            compareKeyed(SCValXDR.bytes(Data([0x01, 0x02])),
                         SCValXDR.bytes(Data([0x01, 0x02, 0x03]))),
            0
        )

        // Unsigned byte comparison: 0x01 < 0xFF.
        XCTAssertLessThan(
            compareKeyed(SCValXDR.bytes(Data([0x01])),
                         SCValXDR.bytes(Data([0xFF]))),
            0
        )
    }

    // MARK: - Single key-type entries (4 cases)

    /// Symbol-typed keys sort by content, byte for byte; length is only a
    /// tiebreaker on a shared prefix. "middle" sorts between "alpha" and
    /// "zebra" on its first byte (0x6d), regardless of being longer.
    func test_sortMapByKeyXdr_symbolKeys() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("zebra"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("alpha"), val: .u32(2)),
            SCMapEntryXDR(key: .symbol("middle"), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(extractSymbolName(sorted[0].key), "alpha")
        XCTAssertEqual(extractSymbolName(sorted[1].key), "middle")
        XCTAssertEqual(extractSymbolName(sorted[2].key), "zebra")
    }

    /// Contract-address keys sort in the host's ScMap key order. Addresses
    /// are fixed-width (a 32-byte contract id following the address-type
    /// discriminant), so content order equals XDR-byte order here.
    func test_sortMapByKeyXdr_addressKeys() throws {
        let addr1 = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let addr2 = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"
        let addr3 = "CCK4LNH73QFN6KSRCP7ZBF4ISLXHZDMZGCMC3ETCMMUPNGQJZCPHVZQ3"

        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr1)), val: .void),
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr2)), val: .void),
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr3)), val: .void)
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        XCTAssertEqual(sorted.count, 3)
        for i in 0 ..< sorted.count - 1 {
            XCTAssertLessThan(compareScValHostOrder(sorted[i].key, sorted[i + 1].key), 0)
        }
    }

    /// U32-typed keys: discriminant is constant across entries, so the sort
    /// is by the numeric value of the U32 itself.
    func test_sortMapByKeyXdr_u32Keys() throws {
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
        XCTAssertEqual(v0, 100)
        XCTAssertEqual(v1, 200)
        XCTAssertEqual(v2, 300)
    }

    /// Bytes-typed keys sort by their content, byte for byte (unsigned);
    /// length is only a tiebreaker on a shared prefix.
    func test_sortMapByKeyXdr_bytesKeys() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .bytes(Data([0xFF])), val: .u32(1)),
            SCMapEntryXDR(key: .bytes(Data([0x01])), val: .u32(2)),
            SCMapEntryXDR(key: .bytes(Data([0x80])), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        guard case .bytes(let b0) = sorted[0].key,
              case .bytes(let b1) = sorted[1].key,
              case .bytes(let b2) = sorted[2].key else {
            return XCTFail("expected bytes keys")
        }
        XCTAssertEqual(b0, Data([0x01]))
        XCTAssertEqual(b1, Data([0x80]))
        XCTAssertEqual(b2, Data([0xFF]))
    }

    // MARK: - Mixed key types (XDR discriminant ordering) (3 cases)

    /// Different SCVal discriminants impose an outer ordering on the sort —
    /// every U32 entry sorts before every Bytes entry which sorts before
    /// every Symbol entry, regardless of body content.
    func test_sortMapByKeyXdr_mixedDiscriminants() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("middle"), val: .u32(1)),
            SCMapEntryXDR(key: .u32(42), val: .u32(2)),
            SCMapEntryXDR(key: .bytes(Data([0x01])), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        // The exact ordering follows the SCVal discriminant numeric ranks; we
        // assert pairwise discriminant ordering rather than hard-coding the
        // discriminant constants here.
        for i in 0 ..< sorted.count - 1 {
            XCTAssertLessThan(sorted[i].key.type(), sorted[i + 1].key.type())
        }
    }

    /// Determinism: shuffling the input list must yield the same output.
    func test_sortMapByKeyXdr_isDeterministic() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x80, 0x01]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01, 0x02]))
        let s3 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xFF]))

        let a: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: try s1.toScVal(), val: .u32(10)),
            SCMapEntryXDR(key: try s2.toScVal(), val: .u32(20)),
            SCMapEntryXDR(key: try s3.toScVal(), val: .u32(30))
        ]
        let b: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: try s3.toScVal(), val: .u32(30)),
            SCMapEntryXDR(key: try s1.toScVal(), val: .u32(10)),
            SCMapEntryXDR(key: try s2.toScVal(), val: .u32(20))
        ]

        let sa = OZPolicyManager.sortMapByKeyXdr(a)
        let sb = OZPolicyManager.sortMapByKeyXdr(b)

        // Compare encoded byte sequences to ensure full structural equality.
        let encA = try Data(XDREncoder.encode(SCValXDR.map(sa)))
        let encB = try Data(XDREncoder.encode(SCValXDR.map(sb)))
        XCTAssertEqual(encA, encB)
    }

    /// Stable on equal keys: when two entries have byte-equal keys (a
    /// duplicate-key scenario), the sort must preserve their input order so
    /// downstream tooling can locate the duplicate and surface a deterministic
    /// diagnostic. The Soroban host rejects ScMap values with duplicate keys
    /// at simulation time, but the sort itself must not introduce a fresh
    /// non-determinism.
    func test_sortMapByKeyXdr_stableOnDuplicateKeys() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("dup"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("dup"), val: .u32(2)),
            SCMapEntryXDR(key: .symbol("dup"), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        guard case .u32(let v0) = sorted[0].val,
              case .u32(let v1) = sorted[1].val,
              case .u32(let v2) = sorted[2].val else {
            return XCTFail("expected u32 values")
        }
        XCTAssertEqual([v0, v1, v2], [1, 2, 3])
    }

    // MARK: - Boundary cases (4 cases)

    /// Empty input returns an empty output.
    func test_sortMapByKeyXdr_emptyMap() throws {
        let sorted = OZPolicyManager.sortMapByKeyXdr([])
        XCTAssertTrue(sorted.isEmpty)
    }

    /// Single-entry input is returned unchanged.
    func test_sortMapByKeyXdr_singleEntry() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("only"), val: .u32(42))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(extractSymbolName(sorted[0].key), "only")
        guard case .u32(let v) = sorted[0].val else {
            return XCTFail("expected u32 value")
        }
        XCTAssertEqual(v, 42)
    }

    /// Sorting preserves values bound to each key, not just the keys.
    func test_sortMapByKeyXdr_preservesValues() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("z"), val: .u32(100)),
            SCMapEntryXDR(key: .symbol("a"), val: .u32(200)),
            SCMapEntryXDR(key: .symbol("m"), val: .u32(300))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        guard case .u32(let v0) = sorted[0].val,
              case .u32(let v1) = sorted[1].val,
              case .u32(let v2) = sorted[2].val else {
            return XCTFail("expected u32 values")
        }
        XCTAssertEqual(extractSymbolName(sorted[0].key), "a")
        XCTAssertEqual(v0, 200)
        XCTAssertEqual(extractSymbolName(sorted[1].key), "m")
        XCTAssertEqual(v1, 300)
        XCTAssertEqual(extractSymbolName(sorted[2].key), "z")
        XCTAssertEqual(v2, 100)
    }

    /// Deeply nested map keys: when a key is itself a map (a legitimate but
    /// uncommon shape), the sort still produces a deterministic ordering
    /// because map keys compare entry-wise, recursing into their own keys
    /// and values.
    func test_sortMapByKeyXdr_nestedMapKeys() throws {
        let innerA: [SCMapEntryXDR] = [SCMapEntryXDR(key: .symbol("a"), val: .u32(1))]
        let innerB: [SCMapEntryXDR] = [SCMapEntryXDR(key: .symbol("b"), val: .u32(2))]

        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .map(innerB), val: .u32(20)),
            SCMapEntryXDR(key: .map(innerA), val: .u32(10))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        // The "a"-keyed inner map sorts before the "b"-keyed inner map because
        // the content of `Symbol("a")` precedes `Symbol("b")`.
        guard case .u32(let v0) = sorted[0].val,
              case .u32(let v1) = sorted[1].val else {
            return XCTFail("expected u32 values")
        }
        XCTAssertEqual(v0, 10)
        XCTAssertEqual(v1, 20)
    }

    // MARK: - Round trip with WeightedThreshold and policies map (4 cases)

    /// `OZPolicyInstallParams.weightedThreshold` calls `sortMapByKeyXdr` on its
    /// inner signer-weights map; the encoded shape must match across
    /// equivalent inputs in different order.
    func test_sortMapByKeyXdr_weightedThresholdRoundtripDeterministic() throws {
        let s1 = try OZDelegatedSigner(address: "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7")
        let s2 = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")
        let s3 = try OZDelegatedSigner(address: "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG")

        let paramsA = OZPolicyInstallParams.weightedThreshold(
            signerWeights: [
                OZSignerWeightEntry(signer: s3, weight: 20),
                OZSignerWeightEntry(signer: s1, weight: 50),
                OZSignerWeightEntry(signer: s2, weight: 30)
            ],
            threshold: 100
        )
        let paramsB = OZPolicyInstallParams.weightedThreshold(
            signerWeights: [
                OZSignerWeightEntry(signer: s2, weight: 30),
                OZSignerWeightEntry(signer: s1, weight: 50),
                OZSignerWeightEntry(signer: s3, weight: 20)
            ],
            threshold: 100
        )

        let encA = try Data(XDREncoder.encode(try paramsA.toScVal()))
        let encB = try Data(XDREncoder.encode(try paramsB.toScVal()))
        XCTAssertEqual(encA, encB)
    }

    /// The inner signer-weights map keys are in strictly ascending host
    /// order regardless of caller insertion order.
    func test_sortMapByKeyXdr_weightedThresholdInnerKeysAreSorted() throws {
        let s1 = try OZDelegatedSigner(address: "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7")
        let s2 = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")
        let s3 = try OZDelegatedSigner(address: "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG")

        let params = OZPolicyInstallParams.weightedThreshold(
            signerWeights: [
                OZSignerWeightEntry(signer: s3, weight: 20),
                OZSignerWeightEntry(signer: s1, weight: 50),
                OZSignerWeightEntry(signer: s2, weight: 30)
            ],
            threshold: 100
        )

        guard case .map(let outerEntries) = try params.toScVal(), let outer = outerEntries else {
            return XCTFail("expected outer map")
        }
        guard let signerWeights = outer.first(where: { extractSymbolName($0.key) == "signer_weights" }),
              case .map(let innerEntries) = signerWeights.val, let inner = innerEntries else {
            return XCTFail("expected inner signer_weights map")
        }
        XCTAssertEqual(inner.count, 3)
        for i in 0 ..< inner.count - 1 {
            XCTAssertLessThan(compareScValHostOrder(inner[i].key, inner[i + 1].key), 0)
        }
    }

    /// Simulates the policies-map construction `OZContextRuleManager.addContextRule`
    /// performs: each policy contract address is encoded as a key with `.void`
    /// as the install-params placeholder, then the map is sorted into the
    /// host's ScMap key order before being passed on to the contract.
    func test_sortMapByKeyXdr_policiesMapAddressKeysAreSorted() throws {
        let policyAddr1 = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let policyAddr2 = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"
        let policyAddr3 = "CCK4LNH73QFN6KSRCP7ZBF4ISLXHZDMZGCMC3ETCMMUPNGQJZCPHVZQ3"

        let entries: [SCMapEntryXDR] = try [policyAddr1, policyAddr2, policyAddr3].map { address in
            SCMapEntryXDR(
                key: .address(try SCAddressXDR(contractId: address)),
                val: .void
            )
        }
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(sorted.count, 3)

        for i in 0 ..< sorted.count - 1 {
            XCTAssertLessThan(compareScValHostOrder(sorted[i].key, sorted[i + 1].key), 0)
        }
    }

    /// Same policy addresses in different insertion order produce identical
    /// XDR after sorting.
    func test_sortMapByKeyXdr_policiesMapSortingIsDeterministic() throws {
        let addr1 = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let addr2 = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"

        let entriesA: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr1)), val: .void),
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr2)), val: .void)
        ]
        let entriesB: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr2)), val: .void),
            SCMapEntryXDR(key: .address(try SCAddressXDR(contractId: addr1)), val: .void)
        ]
        let sortedA = OZPolicyManager.sortMapByKeyXdr(entriesA)
        let sortedB = OZPolicyManager.sortMapByKeyXdr(entriesB)

        let encA = try Data(XDREncoder.encode(SCValXDR.map(sortedA)))
        let encB = try Data(XDREncoder.encode(SCValXDR.map(sortedB)))
        XCTAssertEqual(encA, encB)
    }

    // MARK: - Already-sorted, miscellaneous (2 cases — extra coverage)

    /// An input that is already in correct order is returned in the same order
    /// (the sort is a no-op for sorted inputs).
    func test_sortMapByKeyXdr_alreadySorted_noOp() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("aaa"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("bbb"), val: .u32(2)),
            SCMapEntryXDR(key: .symbol("ccc"), val: .u32(3))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)

        XCTAssertEqual(extractSymbolName(sorted[0].key), "aaa")
        XCTAssertEqual(extractSymbolName(sorted[1].key), "bbb")
        XCTAssertEqual(extractSymbolName(sorted[2].key), "ccc")
    }

    /// Same input twice produces the same byte output (sanity check on
    /// `scValToXdrBytes` determinism for the same value).
    func test_scValToXdrBytes_determinism() throws {
        let scVal = SCValXDR.symbol("test")
        let bytesA = OZPolicyManager.scValToXdrBytes(scVal)
        let bytesB = OZPolicyManager.scValToXdrBytes(scVal)
        XCTAssertEqual(bytesA, bytesB)
        XCTAssertFalse(bytesA.isEmpty)
    }

    // MARK: - Helpers

    private func extractSymbolName(_ scVal: SCValXDR) -> String {
        guard case .symbol(let name) = scVal else {
            XCTFail("expected Symbol SCVal")
            return ""
        }
        return name
    }

    private func compareKeyed(_ a: SCValXDR, _ b: SCValXDR) -> Int {
        return compareScValHostOrder(a, b)
    }
}
