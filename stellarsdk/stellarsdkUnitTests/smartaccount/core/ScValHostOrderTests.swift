//
//  ScValHostOrderTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Host-order ScMap key comparator (`compareScValHostOrder`) and its effect on the
/// smart-account signer maps. The Soroban host orders keys by content (Rust slice `Ord`),
/// with length only a tiebreaker on a common prefix. Sorting by the length-major XDR-byte
/// encoding instead diverges for variable-length keys whose lengths differ, producing a
/// map the host rejects with `InvalidInput`; this suite pins the correct order.
final class ScValHostOrderTests: XCTestCase {

    private let verifier = "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
    private let verifierOther = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    private func bytes(_ v: UInt8...) -> SCValXDR {
        return .bytes(Data(v))
    }

    /// Builds an external signer: keyData = pub(65, first byte varied) + credId(len, zeros).
    private func externalSigner(
        pubFirstByte: UInt8,
        credIdLen: Int,
        verifierAddress: String? = nil
    ) throws -> OZExternalSigner {
        var pub = Data(repeating: 0x01, count: 65)
        pub[0] = pubFirstByte
        let credId = Data(repeating: 0x00, count: credIdLen)
        return try OZExternalSigner(
            verifierAddress: verifierAddress ?? verifier,
            keyData: pub + credId
        )
    }

    /// Builds an external signer's ScVal key.
    private func signer(
        _ pubFirstByte: UInt8,
        _ credIdLen: Int,
        verifierAddress: String? = nil
    ) throws -> SCValXDR {
        return try externalSigner(
            pubFirstByte: pubFirstByte,
            credIdLen: credIdLen,
            verifierAddress: verifierAddress
        ).toScVal()
    }

    /// Length-major comparison of raw XDR encodings, used to pin where the two orders diverge.
    private func compareRawBytes(_ a: [UInt8], _ b: [UInt8]) -> Int {
        let shared = min(a.count, b.count)
        for i in 0..<shared {
            if a[i] != b[i] {
                return a[i] < b[i] ? -1 : 1
            }
        }
        if a.count == b.count { return 0 }
        return a.count < b.count ? -1 : 1
    }

    /// Bytes compare by content, not length: [0x01, 0x02] < [0xFF].
    func testBytes_contentBeforeLength() {
        let a = bytes(0xFF)
        let b = bytes(0x01, 0x02)
        XCTAssertLessThan(compareScValHostOrder(b, a), 0, "b (0x01..) must sort before a (0xFF)")
        XCTAssertGreaterThan(compareScValHostOrder(a, b), 0)
    }

    /// Prefix tiebreaker: the shorter value sorts first.
    func testBytes_prefixShorterFirst() {
        let a = bytes(0x01)
        let b = bytes(0x01, 0x00)
        XCTAssertLessThan(compareScValHostOrder(a, b), 0)
        XCTAssertGreaterThan(compareScValHostOrder(b, a), 0)
    }

    /// Two same-verifier signers with different-length keyData: host order is by content
    /// and is the opposite of the length-major XDR-byte order.
    func testSameVerifierSigners_hostOrderDivergesFromLengthMajor() throws {
        let signerA = try signer(0x02, 16) // keyData 81 bytes, pub greater
        let signerB = try signer(0x01, 20) // keyData 85 bytes, pub smaller

        // Host order: B before A (pubB 0x01 < pubA 0x02 in the first byte; length irrelevant).
        XCTAssertLessThan(compareScValHostOrder(signerB, signerA), 0)
        XCTAssertGreaterThan(compareScValHostOrder(signerA, signerB), 0)

        // Length-major XDR-byte order puts the shorter signerA first — the opposite of
        // the host. Asserting the disagreement pins the divergence at exactly the inputs
        // where the two orders differ.
        let xdrA = OZPolicyManager.scValToXdrBytes(signerA)
        let xdrB = OZPolicyManager.scValToXdrBytes(signerB)
        XCTAssertLessThan(xdrA.count, xdrB.count)
        XCTAssertLessThan(compareRawBytes(xdrA, xdrB), 0, "length-major XDR-byte order puts signerA first")
        XCTAssertGreaterThan(compareScValHostOrder(signerA, signerB), 0, "host order puts signerA last")
    }

    /// The weighted-threshold signer_weights map sorts the two signers in host order [B, A].
    func testSignerWeightsMap_hostOrder() throws {
        let signerA = try signer(0x02, 16)
        let signerB = try signer(0x01, 20)
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: signerA, val: .u32(1)),
            SCMapEntryXDR(key: signerB, val: .u32(1))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(sorted.count, 2)
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(sorted[0].key),
            OZPolicyManager.scValToXdrBytes(signerB)
        )
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(sorted[1].key),
            OZPolicyManager.scValToXdrBytes(signerA)
        )
    }

    /// Same-length, different content: ordered by content, not spuriously reordered.
    func testSameLengthSigners_contentOrder() throws {
        let low = try signer(0x01, 16)
        let high = try signer(0x02, 16)
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: high, val: .u32(1)),
            SCMapEntryXDR(key: low, val: .u32(1))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(sorted[0].key),
            OZPolicyManager.scValToXdrBytes(low)
        )
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(sorted[1].key),
            OZPolicyManager.scValToXdrBytes(high)
        )
    }

    /// 3+ signers with mixed lengths: the full sort is a strict total order in host order.
    func testManySigners_strictTotalOrder() throws {
        let s1 = try signer(0x01, 16)
        let s2 = try signer(0x02, 40)
        let s3 = try signer(0x03, 8)
        let s4 = try signer(0x02, 12)
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: s3, val: .u32(1)),
            SCMapEntryXDR(key: s1, val: .u32(1)),
            SCMapEntryXDR(key: s4, val: .u32(1)),
            SCMapEntryXDR(key: s2, val: .u32(1))
        ]
        let sorted = OZPolicyManager.sortMapByKeyXdr(entries)
        XCTAssertEqual(sorted.count, 4)
        // First pub byte 0x01 is smallest; first pub byte 0x03 is largest.
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(sorted[0].key),
            OZPolicyManager.scValToXdrBytes(s1)
        )
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(sorted[3].key),
            OZPolicyManager.scValToXdrBytes(s3)
        )
        for i in 0..<sorted.count - 1 {
            XCTAssertLessThan(
                compareScValHostOrder(sorted[i].key, sorted[i + 1].key),
                0,
                "adjacent keys must be strictly increasing in host order"
            )
        }
    }

    /// Two signers on different verifiers with identical keyData: order is decided by the
    /// Address element of the Vec key, not the trailing Bytes.
    func testDifferentVerifiers_addressDecides() throws {
        let signerX = try signer(0x01, 16, verifierAddress: verifier)
        let signerY = try signer(0x01, 16, verifierAddress: verifierOther)
        let addrCmp = compareScValHostOrder(
            .address(try SCAddressXDR(contractId: verifier)),
            .address(try SCAddressXDR(contractId: verifierOther))
        )
        let signerCmp = compareScValHostOrder(signerX, signerY)
        XCTAssertNotEqual(addrCmp, 0, "the two verifier addresses must differ")
        XCTAssertEqual(
            signerCmp < 0,
            addrCmp < 0,
            "signer order must follow the verifier Address element, not the identical keyData"
        )
    }

    /// String comparands compare by content, byte for byte, with the shorter value first
    /// on a prefix tie.
    func testStringComparands_contentOrder() {
        let a = SCValXDR.string("apple")
        let b = SCValXDR.string("banana")
        XCTAssertLessThan(compareScValHostOrder(a, b), 0)
        XCTAssertGreaterThan(compareScValHostOrder(b, a), 0)

        let prefix = SCValXDR.string("app")
        XCTAssertLessThan(compareScValHostOrder(prefix, a), 0, "a prefix sorts before its extension")
        XCTAssertEqual(compareScValHostOrder(a, SCValXDR.string("apple")), 0)
    }

    /// Vec comparands: on a shared prefix, the shorter vec sorts first.
    func testVecComparands_prefixShorterFirst() {
        let short = SCValXDR.vec([.symbol("a")])
        let long = SCValXDR.vec([.symbol("a"), .symbol("b")])
        XCTAssertLessThan(compareScValHostOrder(short, long), 0)
        XCTAssertGreaterThan(compareScValHostOrder(long, short), 0)
    }

    /// Map comparands with identical keys: the first differing value decides.
    func testMapComparands_valueDecidesOnEqualKeys() {
        let lower = SCValXDR.map([SCMapEntryXDR(key: .symbol("k"), val: .u32(1))])
        let higher = SCValXDR.map([SCMapEntryXDR(key: .symbol("k"), val: .u32(2))])
        XCTAssertLessThan(compareScValHostOrder(lower, higher), 0)
        XCTAssertGreaterThan(compareScValHostOrder(higher, lower), 0)
    }

    /// Map comparands on a shared entry prefix: the map with fewer entries sorts first.
    func testMapComparands_entryCountTiebreakerOnSharedPrefix() {
        let oneEntry = SCValXDR.map([SCMapEntryXDR(key: .symbol("a"), val: .u32(1))])
        let twoEntries = SCValXDR.map([
            SCMapEntryXDR(key: .symbol("a"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("b"), val: .u32(2))
        ])
        XCTAssertLessThan(compareScValHostOrder(oneEntry, twoEntries), 0)
        XCTAssertGreaterThan(compareScValHostOrder(twoEntries, oneEntry), 0)
    }

    /// Map comparands compare entry-wise (first differing key/value decides), not by
    /// entry count.
    func testMapComparands_entryWiseNotEntryCount() {
        let oneEntry = SCValXDR.map([SCMapEntryXDR(key: .symbol("b"), val: .u32(1))])
        let twoEntries = SCValXDR.map([
            SCMapEntryXDR(key: .symbol("a"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("c"), val: .u32(2))
        ])
        // Entry-wise: the two-entry map's first key "a" sorts before "b", so it comes
        // first despite having more entries (entry count is only the tiebreaker on a
        // shared prefix).
        XCTAssertLessThan(compareScValHostOrder(twoEntries, oneEntry), 0)
        XCTAssertGreaterThan(compareScValHostOrder(oneEntry, twoEntries), 0)
    }

    /// The auth-payload write path emits the signers map in host order for two
    /// same-verifier signers with different-length key data.
    func testAuthPayloadWrite_signersMapInHostOrder() throws {
        let signerA = try externalSigner(pubFirstByte: 0x02, credIdLen: 16) // shorter keyData, greater pub
        let signerB = try externalSigner(pubFirstByte: 0x01, credIdLen: 20) // longer keyData, smaller pub
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: signerA, signatureBytes: Data(repeating: 0x07, count: 64)),
                .init(signer: signerB, signatureBytes: Data(repeating: 0x08, count: 64))
            ],
            contextRuleIds: [0]
        )

        let written = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let optionalOuterEntries) = written, let outerEntries = optionalOuterEntries else {
            return XCTFail("expected outer map")
        }
        guard let signersEntry = outerEntries.first(where: {
            if case .symbol(let name) = $0.key { return name == "signers" }
            return false
        }) else {
            return XCTFail("expected signers entry")
        }
        guard case .map(let optionalSignerEntries) = signersEntry.val,
              let signerEntries = optionalSignerEntries else {
            return XCTFail("expected inner signers map")
        }

        XCTAssertEqual(signerEntries.count, 2)
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(signerEntries[0].key),
            OZPolicyManager.scValToXdrBytes(try signerB.toScVal()),
            "smaller pubkey content must sort first despite longer keyData"
        )
        XCTAssertEqual(
            OZPolicyManager.scValToXdrBytes(signerEntries[1].key),
            OZPolicyManager.scValToXdrBytes(try signerA.toScVal())
        )
    }
}
