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
        // The codec sorts keys in the host's ScMap key order: content-wise,
        // byte for byte, with length only a tiebreaker on a shared prefix.
        XCTAssertLessThan(
            compareScValHostOrder(.bytes(Data([0x00, 0x01])), .bytes(Data([0x00, 0x02]))),
            0
        )
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
        // Sorted into host order: keyData 0x01 sorts before 0xFF.
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

    func testScValKeySort_property_random_keysets_geq_1000_is_permutation_invariant() throws {
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

    func testScValKeySort_outer_struct_is_alphabetical_insertion_order() throws {
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
        // The outer struct map keys are inserted in the contract's
        // `#[contracttype]` field order (alphabetical: `context_rule_ids`,
        // then `signers`) — they are never run through the dynamic-key sort.
        XCTAssertEqual(key0, "context_rule_ids")
        XCTAssertEqual(key1, "signers")
    }

    func testScValKeySort_inner_signers_uses_host_order() throws {
        // Insert in reverse order; verify the result is sorted into the host's
        // ScMap key order.
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
        // The s2 key (keyData starting 0x01) sorts before the s1 key
        // (keyData starting 0x80): content order decides.
        XCTAssertLessThan(compareScValHostOrder(inner[0].key, inner[1].key), 0)
        guard case .bytes(let firstSignature) = inner[0].val else {
            XCTFail("Expected Bytes value")
            return
        }
        XCTAssertEqual(firstSignature, Data([0x20]))
    }
}
