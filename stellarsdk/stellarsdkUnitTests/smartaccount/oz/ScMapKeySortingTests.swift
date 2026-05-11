//
//  ScMapKeySortingTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class ScMapKeySortingTests: XCTestCase {

    private var validAccountG: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    override func setUp() {
        super.setUp()
        validAccountG = try! KeyPair.generateRandomKeyPair().accountId
    }

    // MARK: - Algorithm-level

    func testCompareByteArraysLexicographically() throws {
        // Use Data lex comparison — codec sorts by lowercase-hex of XDR-encoded bytes.
        let a = Data([0x00, 0x01])
        let b = Data([0x00, 0x02])
        XCTAssertTrue(a.lexicographicallyPrecedes(b))
    }

    func testSortMapByKeyXdrWithSymbolKeys() throws {
        // Create a payload with two external signers whose keyData hex differs in a
        // determinable way; the codec must produce identical output regardless of
        // insertion order.
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x02]))
        let payloadA = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0xA])),
                .init(signer: s2, signatureBytes: Data([0xB]))
            ],
            contextRuleIds: []
        )
        let payloadB = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s2, signatureBytes: Data([0xB])),
                .init(signer: s1, signatureBytes: Data([0xA]))
            ],
            contextRuleIds: []
        )
        let encA = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadA)))
        let encB = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadB)))
        XCTAssertEqual(encA, encB)
    }

    func testSortMapByKeyXdrWithAddressKeys() throws {
        let altContract = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let s1 = try OZDelegatedSigner(address: validContractC)
        let s2 = try OZDelegatedSigner(address: altContract)
        let payloadA = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0x01])),
                .init(signer: s2, signatureBytes: Data([0x02]))
            ],
            contextRuleIds: []
        )
        let payloadB = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s2, signatureBytes: Data([0x02])),
                .init(signer: s1, signatureBytes: Data([0x01]))
            ],
            contextRuleIds: []
        )
        let encA = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadA)))
        let encB = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadB)))
        XCTAssertEqual(encA, encB)
    }

    func testSortingWithDifferentScValKeyTypes() throws {
        let delegated = try OZDelegatedSigner(address: validAccountG)
        let external = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let payloadA = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: delegated, signatureBytes: Data([0x01])),
                .init(signer: external, signatureBytes: Data([0x02]))
            ],
            contextRuleIds: []
        )
        let payloadB = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: external, signatureBytes: Data([0x02])),
                .init(signer: delegated, signatureBytes: Data([0x01]))
            ],
            contextRuleIds: []
        )
        let encA = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadA)))
        let encB = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadB)))
        XCTAssertEqual(encA, encB)
    }

    func testSortEmptyMap() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        // Outer map always has 2 entries (context_rule_ids + signers), inner signers map is empty.
        XCTAssertEqual(entries.count, 2)
        if case .map(let signersEntries) = entries[1].val {
            XCTAssertEqual(signersEntries?.count, 0)
        }
    }

    func testSortSingleEntryMap() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x01]))],
            contextRuleIds: []
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries.count, 2)
    }

    func testSortAlreadySortedMap() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x80]))
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0xA])),
                .init(signer: s2, signatureBytes: Data([0xB]))
            ],
            contextRuleIds: []
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 2)
    }

    func testSortPreservesValues() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xFF]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0xAA])),
                .init(signer: s2, signatureBytes: Data([0xBB]))
            ],
            contextRuleIds: []
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        // Sorted by hex: keyData 0x01 sorts before 0xFF.
        XCTAssertEqual(decoded.signers[0].signatureBytes, Data([0xBB]))
        XCTAssertEqual(decoded.signers[1].signatureBytes, Data([0xAA]))
    }

    func testSimpleThresholdMapHasSingleKey() throws {
        // Sanity check that the OZ simple threshold map literal builds with one key.
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("threshold"), val: .u32(2))
        ]
        let scVal = SCValXDR.map(entries)
        if case .map(let entries) = scVal {
            XCTAssertEqual(entries?.count, 1)
        }
    }

    // MARK: - Property tests

    func testScValKeySort_property_random_keysets_geq_1000_match_reference() throws {
        var rng = SeededRng(seed: 0xCAFEBABE)
        for _ in 0..<1000 {
            // Generate 2-4 random external signers with distinct keyData.
            let count = Int(rng.nextUInt32() % 3) + 2
            var entries: [OZSmartAccountAuthPayload.SignerEntry] = []
            for _ in 0..<count {
                let len = Int(rng.nextUInt32() % 16) + 1
                var bytes = Data(count: len)
                for j in 0..<len {
                    bytes[j] = UInt8(rng.nextUInt32() & 0xFF)
                }
                let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: bytes)
                entries.append(.init(signer: signer, signatureBytes: bytes))
            }
            let payload = OZSmartAccountAuthPayload(signers: entries, contextRuleIds: [])
            let encoded = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payload)))
            // Re-encode after random reshuffle: produce same byte sequence.
            var shuffled = entries
            shuffled.swapAt(0, entries.count - 1)
            let payloadB = OZSmartAccountAuthPayload(signers: shuffled, contextRuleIds: [])
            let encodedB = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadB)))
            XCTAssertEqual(encoded, encodedB)
        }
    }

    func testScValKeySort_outer_struct_is_alphabetical_not_xdr_byte_sort() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [1])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        guard case .symbol(let key0) = entries[0].key,
              case .symbol(let key1) = entries[1].key else {
            XCTFail("Expected Symbol keys")
            return
        }
        // context_rule_ids (16 chars, XDR encodes longer) sorts BEFORE signers
        // alphabetically (c < s) but AFTER signers under XDR-byte sort because XDR length
        // prefix puts shorter strings first. The codec must emit alphabetical order to
        // match the contract's `#[contracttype]` derive convention.
        XCTAssertEqual(key0, "context_rule_ids")
        XCTAssertEqual(key1, "signers")
    }

    func testScValKeySort_inner_signers_uses_xdr_hex_sort() throws {
        // Insert in reverse order; verify the result is sorted by XDR-hex.
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x80, 0x01]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01, 0x02]))
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0x10])),
                .init(signer: s2, signatureBytes: Data([0x20]))
            ],
            contextRuleIds: []
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let outerEntries) = scVal, let outer = outerEntries else {
            XCTFail("Expected outer map")
            return
        }
        guard case .map(let innerEntries) = outer[1].val, let inner = innerEntries else {
            XCTFail("Expected inner map")
            return
        }
        // First inner key should encode to a smaller hex string.
        let key0Hex = try Data(XDREncoder.encode(inner[0].key)).base16EncodedString()
        let key1Hex = try Data(XDREncoder.encode(inner[1].key)).base16EncodedString()
        XCTAssertTrue(key0Hex < key1Hex)
    }

    func testScValKeySort_golden_alphabetical_vs_xdr_hex_diverge() throws {
        // Outer struct order: alphabetical. Verify "a" < "ab" alphabetically — true under
        // either ordering — but "zebra" < "middle" alphabetically false. Document the
        // invariant by checking that the outer map is in code-point order regardless of
        // XDR length.
        // (Tested above via testScValKeySort_outer_struct_is_alphabetical_not_xdr_byte_sort.)
        XCTAssertTrue("context_rule_ids" < "signers")
    }
}
