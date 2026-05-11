//
//  OZSmartAccountAuthPayloadTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSmartAccountAuthPayloadTests: XCTestCase {

    private var validAccountG: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    override func setUp() {
        super.setUp()
        let keyPair = try! KeyPair.generateRandomKeyPair()
        validAccountG = keyPair.accountId
    }

    // MARK: - Construction

    func testPayloadConstruction_emptySignersAndRuleIds() {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        XCTAssertEqual(payload.signers.count, 0)
        XCTAssertEqual(payload.contextRuleIds.count, 0)
    }

    func testPayloadConstruction_withSignersAndRuleIds() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x01]))],
            contextRuleIds: [1, 2]
        )
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertEqual(payload.contextRuleIds, [1, 2])
    }

    func testPayloadSignersMap_isMutable() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        payload.signers.append(.init(signer: signer, signatureBytes: Data([0x05])))
        XCTAssertEqual(payload.signers.count, 1)
    }

    // MARK: - read

    func testRead_voidReturnsEmptyPayload() throws {
        let payload = try OZSmartAccountAuthPayloadCodec.read(.void)
        XCTAssertTrue(payload.signers.isEmpty)
        XCTAssertTrue(payload.contextRuleIds.isEmpty)
    }

    func testRead_nonMapNonVoidThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.read(.bool(true))) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testRead_symbolScValThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.read(.symbol("foo"))) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testRead_bytesScValThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.read(.bytes(Data([0x01])))) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testRead_vecScValThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.read(.vec([]))) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testRead_emptyMapReturnsEmptyPayload() throws {
        let payload = try OZSmartAccountAuthPayloadCodec.read(.map([]))
        XCTAssertTrue(payload.signers.isEmpty)
        XCTAssertTrue(payload.contextRuleIds.isEmpty)
    }

    func testRead_contextRuleIdsOnly() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(
                key: .symbol("context_rule_ids"),
                val: .vec([.u32(1), .u32(2), .u32(3)])
            )
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [1, 2, 3])
        XCTAssertTrue(payload.signers.isEmpty)
    }

    func testRead_signersOnly_delegatedSigner() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let signersMap: SCValXDR = .map([
            SCMapEntryXDR(key: try signer.toScVal(), val: .bytes(Data([0x10])))
        ])
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("signers"), val: signersMap)
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertTrue(payload.signers[0].signer is OZDelegatedSigner)
    }

    func testRead_signersOnly_externalSigner() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let signersMap: SCValXDR = .map([
            SCMapEntryXDR(key: try signer.toScVal(), val: .bytes(Data([0x20])))
        ])
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("signers"), val: signersMap)
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertTrue(payload.signers[0].signer is OZExternalSigner)
    }

    func testRead_multipleSigners() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA, 0xBB]))
        let signersMap: SCValXDR = .map([
            SCMapEntryXDR(key: try s1.toScVal(), val: .bytes(Data([0x10]))),
            SCMapEntryXDR(key: try s2.toScVal(), val: .bytes(Data([0x20])))
        ])
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("signers"), val: signersMap)
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.signers.count, 2)
    }

    func testRead_signerWithNonBytesValueThrows() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let signersMap: SCValXDR = .map([
            SCMapEntryXDR(key: try signer.toScVal(), val: .u32(42))
        ])
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("signers"), val: signersMap)
        ])
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.read(scVal)) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testRead_unknownKeysAreIgnored() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("unknown_field"), val: .u32(99)),
            SCMapEntryXDR(
                key: .symbol("context_rule_ids"),
                val: .vec([.u32(7)])
            )
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [7])
    }

    func testRead_nonSymbolKeysAreSkipped() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .u32(1), val: .u32(99)),
            SCMapEntryXDR(
                key: .symbol("context_rule_ids"),
                val: .vec([.u32(7)])
            )
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [7])
    }

    func testRead_emptyContextRuleIdsVec() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("context_rule_ids"), val: .vec([]))
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [])
    }

    func testRead_contextRuleIdsNotVecIsIgnored() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("context_rule_ids"), val: .u32(99))
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [])
    }

    func testRead_signersNotMapIsIgnored() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("signers"), val: .u32(99))
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertTrue(payload.signers.isEmpty)
    }

    func testRead_singleContextRuleId() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("context_rule_ids"), val: .vec([.u32(42)]))
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [42])
    }

    func testRead_contextRuleIdBoundaryValues() throws {
        let scVal: SCValXDR = .map([
            SCMapEntryXDR(
                key: .symbol("context_rule_ids"),
                val: .vec([.u32(0), .u32(UInt32.max)])
            )
        ])
        let payload = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(payload.contextRuleIds, [0, UInt32.max])
    }

    // MARK: - write

    func testWrite_emptyPayload() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries.count, 2)
    }

    func testWrite_withContextRuleIds() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [1, 2])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        guard case .vec(let optionalIds) = entries[0].val,
              let ids = optionalIds else {
            XCTFail("Expected vec")
            return
        }
        XCTAssertEqual(ids.count, 2)
    }

    func testWrite_withSingleOZDelegatedSigner() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x10]))],
            contextRuleIds: []
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries.count, 2)
    }

    func testWrite_withSingleOZExternalSigner() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x20]))],
            contextRuleIds: []
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries.count, 2)
    }

    func testWrite_outputMapHasCorrectFieldOrder() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x10]))],
            contextRuleIds: [1]
        )
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
        // Outer struct map keys are inserted in alphabetical order (c < s).
        XCTAssertEqual(key0, "context_rule_ids")
        XCTAssertEqual(key1, "signers")
    }

    // MARK: - Round trips

    func testRoundTrip_emptyPayload() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertTrue(decoded.signers.isEmpty)
        XCTAssertTrue(decoded.contextRuleIds.isEmpty)
    }

    func testRoundTrip_contextRuleIdsOnly() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [1, 2, 3])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.contextRuleIds, [1, 2, 3])
    }

    func testRoundTrip_delegatedSignerWithContextRuleIds() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x10, 0x11]))],
            contextRuleIds: [5]
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 1)
        XCTAssertEqual(decoded.contextRuleIds, [5])
        if let delegated = decoded.signers[0].signer as? OZDelegatedSigner {
            XCTAssertEqual(delegated.address, validAccountG)
        } else {
            XCTFail("Expected OZDelegatedSigner")
        }
    }

    func testRoundTrip_externalSignerWithContextRuleIds() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA, 0xBB]))
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x10]))],
            contextRuleIds: [9]
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 1)
        if let external = decoded.signers[0].signer as? OZExternalSigner {
            XCTAssertEqual(external.verifierAddress, validContractC)
            XCTAssertEqual(external.keyData, Data([0xAA, 0xBB]))
        } else {
            XCTFail("Expected OZExternalSigner")
        }
    }

    func testRoundTrip_multipleSignersMixed() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0x01])),
                .init(signer: s2, signatureBytes: Data([0x02]))
            ],
            contextRuleIds: [1, 2]
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 2)
        XCTAssertEqual(decoded.contextRuleIds, [1, 2])
    }

    // MARK: - upsertSigner

    func testUpsertSigner_addToEmptyPayload() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let signer = try OZDelegatedSigner(address: validAccountG)
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: signer, signatureBytes: Data([0x01]))
        XCTAssertEqual(payload.signers.count, 1)
    }

    func testUpsertSigner_addSecondDistinctSigner() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: s1, signatureBytes: Data([0xA]))
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: s2, signatureBytes: Data([0xB]))
        XCTAssertEqual(payload.signers.count, 2)
    }

    func testUpsertSigner_replacesExistingOZDelegatedSigner() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x01]))],
            contextRuleIds: []
        )
        let updated = try OZDelegatedSigner(address: validAccountG)
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: updated, signatureBytes: Data([0x99]))
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertEqual(payload.signers[0].signatureBytes, Data([0x99]))
    }

    func testUpsertSigner_replacesExistingOZExternalSigner() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x01]))],
            contextRuleIds: []
        )
        let updated = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: updated, signatureBytes: Data([0x99]))
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertEqual(payload.signers[0].signatureBytes, Data([0x99]))
    }

    func testUpsertSigner_doesNotReplaceDifferentSignerType() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: s1, signatureBytes: Data([0x01]))],
            contextRuleIds: []
        )
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: s2, signatureBytes: Data([0x02]))
        XCTAssertEqual(payload.signers.count, 2)
    }

    func testUpsertSigner_preservesContextRuleIds() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [1, 2])
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: signer, signatureBytes: Data([0x01]))
        XCTAssertEqual(payload.contextRuleIds, [1, 2])
    }

    func testUpsertSigner_multipleUpsertsOnSameSigner() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: signer, signatureBytes: Data([0x01]))
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: signer, signatureBytes: Data([0x02]))
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: signer, signatureBytes: Data([0x03]))
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertEqual(payload.signers[0].signatureBytes, Data([0x03]))
    }

    // MARK: - signerFromScVal

    func testSignerFromScVal_delegatedSigner() throws {
        let scVal: SCValXDR = .vec([
            .symbol("Delegated"),
            .address(try SCAddressXDR(accountId: validAccountG))
        ])
        let signer = try OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal)
        XCTAssertTrue(signer is OZDelegatedSigner)
    }

    func testSignerFromScVal_delegatedSignerWithContractAddress() throws {
        let scVal: SCValXDR = .vec([
            .symbol("Delegated"),
            .address(try SCAddressXDR(contractId: validContractC))
        ])
        let signer = try OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal)
        XCTAssertTrue(signer is OZDelegatedSigner)
        if let delegated = signer as? OZDelegatedSigner {
            XCTAssertEqual(delegated.address, validContractC)
        }
    }

    func testSignerFromScVal_externalSigner() throws {
        let scVal: SCValXDR = .vec([
            .symbol("External"),
            .address(try SCAddressXDR(contractId: validContractC)),
            .bytes(Data([0x01, 0x02]))
        ])
        let signer = try OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal)
        XCTAssertTrue(signer is OZExternalSigner)
    }

    func testSignerFromScVal_nonVecThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(.symbol("foo"))) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_emptyVecThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([]))) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_firstElementNotSymbolThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([.u32(1), .u32(2)]))
        ) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_unknownTypeTagThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([.symbol("Unknown")]))
        ) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_delegatedWithTooFewElementsThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([.symbol("Delegated")]))
        ) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_delegatedSecondElementNotAddressThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountAuthPayloadCodec.signerFromScVal(
                .vec([.symbol("Delegated"), .u32(1)])
            )
        ) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_externalWithTooFewElementsThrows() throws {
        let scVal: SCValXDR = .vec([
            .symbol("External"),
            .address(try SCAddressXDR(contractId: validContractC))
        ])
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal)) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_externalSecondElementNotAddressThrows() {
        let scVal: SCValXDR = .vec([
            .symbol("External"),
            .u32(1),
            .bytes(Data())
        ])
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal)) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_externalThirdElementNotBytesThrows() throws {
        let scVal: SCValXDR = .vec([
            .symbol("External"),
            .address(try SCAddressXDR(contractId: validContractC)),
            .u32(1)
        ])
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal)) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    func testSignerFromScVal_externalWithOnlySymbolThrows() {
        XCTAssertThrowsError(
            try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([.symbol("External")]))
        ) { error in
            XCTAssertTrue(error is TransactionException.SigningFailed)
        }
    }

    // MARK: - Sorting

    func testWrite_signersSortedDeterministically() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xFF]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let s3 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x80]))
        let payloadA = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0xA])),
                .init(signer: s2, signatureBytes: Data([0xB])),
                .init(signer: s3, signatureBytes: Data([0xC]))
            ],
            contextRuleIds: []
        )
        let payloadB = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s3, signatureBytes: Data([0xC])),
                .init(signer: s1, signatureBytes: Data([0xA])),
                .init(signer: s2, signatureBytes: Data([0xB]))
            ],
            contextRuleIds: []
        )
        let scA = try OZSmartAccountAuthPayloadCodec.write(payloadA)
        let scB = try OZSmartAccountAuthPayloadCodec.write(payloadB)
        XCTAssertEqual(
            try Data(XDREncoder.encode(scA)).base16EncodedString(),
            try Data(XDREncoder.encode(scB)).base16EncodedString()
        )
    }

    func testFullRoundTrip_complexPayload() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA, 0xBB]))
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0x10])),
                .init(signer: s2, signatureBytes: Data([0x20]))
            ],
            contextRuleIds: [1, 2, 3]
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 2)
        XCTAssertEqual(decoded.contextRuleIds, [1, 2, 3])
    }

    func testUpsertThenWriteAndRead_replacedSignerNotPresent() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x01]))],
            contextRuleIds: []
        )
        let same = try OZDelegatedSigner(address: validAccountG)
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: same, signatureBytes: Data([0x99]))
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 1)
        XCTAssertEqual(decoded.signers[0].signatureBytes, Data([0x99]))
    }

    // MARK: - Cross-SDK byte-identity golden vector (AuthPayload codec)
    //
    // Pins the byte-level XDR encoding of the OZ AuthPayload outer named-struct
    // map plus inner signer-map sort. Uses deterministic strkey constants
    // (rather than randomly-generated KeyPairs) so the encoded bytes are
    // reproducible across SDKs. The expected hex is byte-identical to the
    // matching fixture in the sibling SDK and must be updated in lockstep.

    func test_phase4_goldenVector5_authPayloadWithTwoDelegatedSigners_matchesFixture() throws {
        let stableG = "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
        let stableC = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"

        let signerA = try OZDelegatedSigner(address: stableG)
        let signerB = try OZDelegatedSigner(address: stableC)
        let payload = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: signerA, signatureBytes: Data([0xAA, 0xBB])),
                .init(signer: signerB, signatureBytes: Data([0xCC, 0xDD]))
            ],
            contextRuleIds: [7, 11]
        )

        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let encoded = try Data(XDREncoder.encode(scVal))
        let actualHex = encoded.base16EncodedString().lowercased()
        let expectedHex =
            "0000001100000001000000020000000f00000010636f6e746578745f72756c655f6964730000001000000001000000020000000300000007000000030000000b0000000f000000077369676e657273000000001100000001000000020000001000000001000000020000000f0000000944656c656761746564000000000000120000000000000000e8a61a861e60af60f80773e06346e5c72cbe59dcadda37608d58ef42511d9fdc0000000d00000002aabb00000000001000000001000000020000000f0000000944656c6567617465640000000000001200000001c58b2bfbc4f054e7324f6bf20cad3e026e41bbad1a6d20c3d7d4918ded1654110000000d00000002ccdd0000"
        XCTAssertEqual(actualHex, expectedHex,
                       "Golden vector 5 mismatch — actual: \(actualHex)")
    }
}
