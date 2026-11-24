//
//  XDRDeclaredMaximumUnitTests.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 24.11.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The maxima the XDR definitions declare for variable-length arrays, strings and opaque data,
/// enforced on binary decoding and encoding.
///
/// Every decode vector is written out by hand: the count or length word, the repeated element
/// bytes and the padding. An oversized vector carries its full payload, so only the declared
/// maximum can refuse it; a second oversized vector of each kind ends right after the length
/// word, so the maximum must be checked before the remaining bytes are.
final class XDRDeclaredMaximumUnitTests: XCTestCase {

    // MARK: - Operations (hand-written, 100)

    func testTransactionOperationsAtTheMaximumRoundTrip() throws {
        let bytes = Vector.transaction(operations: 100)
        let decoded = try XDRDecoder.decode(TransactionXDR.self, data: bytes)
        XCTAssertEqual(decoded.operations.count, 100)
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    func testTransactionOperationsAboveTheMaximumAreRefused() throws {
        assertDecodeRefused(TransactionXDR.self, Vector.transaction(operations: 101),
                            "XDR array count 101 exceeds the maximum of 100")
        assertDecodeRefused(TransactionXDR.self, Vector.transactionPrefix + Vector.word(101),
                            "XDR array count 101 exceeds the maximum of 100")
        assertEncodeRefused(Value.transaction(operations: 101),
                            "XDR array count 101 exceeds the maximum of 100")
    }

    func testTransactionV0OperationsAtTheMaximumRoundTrip() throws {
        let bytes = Vector.transactionV0(operations: 100)
        let decoded = try XDRDecoder.decode(TransactionV0XDR.self, data: bytes)
        XCTAssertEqual(decoded.operations.count, 100)
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    func testTransactionV0OperationsAboveTheMaximumAreRefused() throws {
        assertDecodeRefused(TransactionV0XDR.self, Vector.transactionV0(operations: 101),
                            "XDR array count 101 exceeds the maximum of 100")
        assertEncodeRefused(try Value.transactionV0(operations: 101),
                            "XDR array count 101 exceeds the maximum of 100")
    }

    // MARK: - Signatures (hand-written, 20)

    func testEnvelopeSignaturesAtTheMaximumRoundTrip() throws {
        let v1 = Vector.transaction(operations: 1) + Vector.signatures(20)
        XCTAssertEqual(try XDRDecoder.decode(TransactionV1EnvelopeXDR.self, data: v1).signatures.count, 20)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(TransactionV1EnvelopeXDR.self, data: v1)), v1)

        let v0 = Vector.transactionV0(operations: 1) + Vector.signatures(20)
        XCTAssertEqual(try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: v0).signatures.count, 20)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: v0)), v0)

        let feeBump = Vector.feeBumpTransaction + Vector.signatures(20)
        XCTAssertEqual(try XDRDecoder.decode(FeeBumpTransactionEnvelopeXDR.self, data: feeBump).signatures.count, 20)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(FeeBumpTransactionEnvelopeXDR.self, data: feeBump)),
                       feeBump)
    }

    func testEnvelopeSignaturesAboveTheMaximumAreRefused() throws {
        let message = "XDR array count 21 exceeds the maximum of 20"
        assertDecodeRefused(TransactionV1EnvelopeXDR.self,
                            Vector.transaction(operations: 1) + Vector.signatures(21), message)
        assertDecodeRefused(TransactionV0EnvelopeXDR.self,
                            Vector.transactionV0(operations: 1) + Vector.signatures(21), message)
        assertDecodeRefused(FeeBumpTransactionEnvelopeXDR.self,
                            Vector.feeBumpTransaction + Vector.signatures(21), message)
        assertDecodeRefused(TransactionV1EnvelopeXDR.self,
                            Vector.transaction(operations: 1) + Vector.word(21), message)

        let signatures = [DecoratedSignatureXDR](repeating: Value.signature, count: 21)
        assertEncodeRefused(TransactionV1EnvelopeXDR(tx: Value.transaction(operations: 1), signatures: signatures),
                            message)
        assertEncodeRefused(TransactionV0EnvelopeXDR(tx: try Value.transactionV0(operations: 1), signatures: signatures),
                            message)
        assertEncodeRefused(FeeBumpTransactionEnvelopeXDR(tx: try Value.feeBumpTransaction(), signatures: signatures),
                            message)
    }

    // MARK: - Memo text (Data-backed string union arm, 28)

    func testMemoTextAtTheMaximumRoundTrips() throws {
        let bytes = Vector.word(1) + Vector.variable(Vector.repeated([0x61], 28))
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: bytes)
        guard case .text(let text) = decoded else { return XCTFail("expected MEMO_TEXT, got \(decoded)") }
        XCTAssertEqual(text, Data(repeating: 0x61, count: 28))
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    func testMemoTextAboveTheMaximumIsRefused() {
        assertDecodeRefused(MemoXDR.self, Vector.word(1) + Vector.variable(Vector.repeated([0x61], 29)),
                            "XDR string length 29 exceeds the maximum of 28")
        assertDecodeRefused(MemoXDR.self, Vector.word(1) + Vector.word(29),
                            "XDR string length 29 exceeds the maximum of 28")
        assertEncodeRefused(MemoXDR.text(Data(repeating: 0x61, count: 29)),
                            "XDR string length 29 exceeds the maximum of 28")
    }

    func testMemoTextCountsTheBytesOfMultiByteCharacters() throws {
        let atMaximum = String(repeating: "é", count: 14)
        XCTAssertEqual(atMaximum.utf8.count, 28)
        let encoded = try XDREncoder.encode(MemoXDR.text(Data(atMaximum.utf8)))
        XCTAssertEqual(encoded, Vector.word(1) + Vector.variable(Vector.repeated([0xC3, 0xA9], 14)))

        assertEncodeRefused(MemoXDR.text(Data((atMaximum + "a").utf8)),
                            "XDR string length 29 exceeds the maximum of 28")
        assertDecodeRefused(MemoXDR.self, Vector.word(1) + Vector.variable(Vector.repeated([0xC3, 0xA9], 14) + [0x61]),
                            "XDR string length 29 exceeds the maximum of 28")
    }

    func testMemoTextKeepsInvalidUTF8AndAByteOrderMarkAtTheMaximum() throws {
        let raw: [UInt8] = [0xEF, 0xBB, 0xBF, 0xFF, 0xFE] + Vector.repeated([0x62], 23)
        let bytes = Vector.word(1) + Vector.variable(raw)
        let decoded = try XDRDecoder.decode(MemoXDR.self, data: bytes)
        guard case .text(let text) = decoded else { return XCTFail("expected MEMO_TEXT, got \(decoded)") }
        XCTAssertEqual([UInt8](text), raw)
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    // MARK: - Symbol (String union arm through a typedef, 32)

    func testSymbolAtTheMaximumRoundTrips() throws {
        let bytes = Vector.word(15) + Vector.variable(Vector.repeated([0x73], 32))
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: bytes)
        guard case .symbol(let symbol) = decoded else { return XCTFail("expected SCV_SYMBOL, got \(decoded)") }
        XCTAssertEqual(symbol, String(repeating: "s", count: 32))
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    func testSymbolAboveTheMaximumIsRefused() {
        assertDecodeRefused(SCValXDR.self, Vector.word(15) + Vector.variable(Vector.repeated([0x73], 33)),
                            "XDR string length 33 exceeds the maximum of 32")
        assertDecodeRefused(SCValXDR.self, Vector.word(15) + Vector.word(33),
                            "XDR string length 33 exceeds the maximum of 32")
        assertEncodeRefused(SCValXDR.symbol(String(repeating: "s", count: 33)),
                            "XDR string length 33 exceeds the maximum of 32")
    }

    func testSymbolCountsTheUTF8BytesOfMultiByteCharacters() throws {
        let atMaximum = String(repeating: "é", count: 16)
        XCTAssertEqual(try XDREncoder.encode(SCValXDR.symbol(atMaximum)),
                       Vector.word(15) + Vector.variable(Vector.repeated([0xC3, 0xA9], 16)))

        let aboveMaximum = atMaximum + "a"
        XCTAssertEqual(aboveMaximum.count, 17)
        assertEncodeRefused(SCValXDR.symbol(aboveMaximum), "XDR string length 33 exceeds the maximum of 32")
    }

    func testSymbolKeepsAByteOrderMarkAtTheMaximum() throws {
        let raw: [UInt8] = [0xEF, 0xBB, 0xBF] + Vector.repeated([0x73], 29)
        let bytes = Vector.word(15) + Vector.variable(raw)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: bytes)
        guard case .symbol(let symbol) = decoded else { return XCTFail("expected SCV_SYMBOL, got \(decoded)") }
        XCTAssertEqual([UInt8](symbol.utf8), raw)
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    // MARK: - Signed payload (opaque, 64)

    func testSignedPayloadAtTheMaximumRoundTrips() throws {
        let bytes = Vector.key + Vector.variable(Vector.repeated([0x70], 64))
        let decoded = try XDRDecoder.decode(Ed25519SignedPayload.self, data: bytes)
        XCTAssertEqual(decoded.payload, Data(repeating: 0x70, count: 64))
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    func testSignedPayloadAboveTheMaximumIsRefused() {
        assertDecodeRefused(Ed25519SignedPayload.self, Vector.key + Vector.variable(Vector.repeated([0x70], 65)),
                            "XDR opaque length 65 exceeds the maximum of 64")
        assertDecodeRefused(Ed25519SignedPayload.self, Vector.key + Vector.word(65),
                            "XDR opaque length 65 exceeds the maximum of 64")
        assertEncodeRefused(Ed25519SignedPayload(ed25519: WrappedData32(Data(Vector.key)),
                                                 payload: Data(repeating: 0x70, count: 65)),
                            "XDR opaque length 65 exceeds the maximum of 64")
    }

    // MARK: - Path (5), claimants (10), extra signers (2)

    func testPathAtTheMaximumRoundTripsAndAboveIsRefused() throws {
        let atMaximum = Vector.pathPayment(path: 5)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(PathPaymentOperationXDR.self, data: atMaximum)),
                       atMaximum)

        assertDecodeRefused(PathPaymentOperationXDR.self, Vector.pathPayment(path: 6),
                            "XDR array count 6 exceeds the maximum of 5")
        assertEncodeRefused(PathPaymentOperationXDR(sendAsset: .native, sendMax: 1, destination: Value.muxedAccount,
                                                    destinationAsset: .native, destinationAmount: 1,
                                                    path: [AssetXDR](repeating: .native, count: 6)),
                            "XDR array count 6 exceeds the maximum of 5")
    }

    func testClaimantsAtTheMaximumRoundTripAndAboveAreRefused() throws {
        let atMaximum = Vector.createClaimableBalance(claimants: 10)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: atMaximum)),
                       atMaximum)

        assertDecodeRefused(CreateClaimableBalanceOpXDR.self, Vector.createClaimableBalance(claimants: 11),
                            "XDR array count 11 exceeds the maximum of 10")
        let claimant = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: try Value.publicKey(), predicate: .claimPredicateUnconditional))
        assertEncodeRefused(CreateClaimableBalanceOpXDR(asset: .native, amount: 1,
                                                        claimants: [ClaimantXDR](repeating: claimant, count: 11)),
                            "XDR array count 11 exceeds the maximum of 10")
    }

    func testExtraSignersAtTheMaximumRoundTripAndAboveAreRefused() throws {
        let atMaximum = Vector.preconditionsV2(extraSigners: 2)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(PreconditionsV2XDR.self, data: atMaximum)),
                       atMaximum)

        assertDecodeRefused(PreconditionsV2XDR.self, Vector.preconditionsV2(extraSigners: 3),
                            "XDR array count 3 exceeds the maximum of 2")
        assertEncodeRefused(PreconditionsV2XDR(minSeqAge: 0, minSeqLedgerGap: 0,
                                               extraSigners: [SignerKeyXDR](repeating: .ed25519(WrappedData32(Data(Vector.key))),
                                                                            count: 3)),
                            "XDR array count 3 exceeds the maximum of 2")
    }

    // MARK: - Contract spec tuple (12)

    func testContractSpecTupleAtTheMaximumRoundTripsAndAboveIsRefused() throws {
        let atMaximum = Vector.word(12) + Vector.repeated(Vector.word(1), 12)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(SCSpecTypeTupleXDR.self, data: atMaximum)),
                       atMaximum)

        assertDecodeRefused(SCSpecTypeTupleXDR.self, Vector.word(13) + Vector.repeated(Vector.word(1), 13),
                            "XDR array count 13 exceeds the maximum of 12")
        assertEncodeRefused(SCSpecTypeTupleXDR(valueTypes: [SCSpecTypeDefXDR](repeating: .bool, count: 13)),
                            "XDR array count 13 exceeds the maximum of 12")
    }

    // MARK: - Array of optional elements (20)

    func testSignerSponsoringIDsAtTheMaximumRoundTripAndAboveAreRefused() throws {
        let atMaximum = Vector.accountEntryExtensionV2(sponsoringIDs: 20)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(AccountEntryExtensionV2.self, data: atMaximum)),
                       atMaximum)

        assertDecodeRefused(AccountEntryExtensionV2.self, Vector.accountEntryExtensionV2(sponsoringIDs: 21),
                            "XDR array count 21 exceeds the maximum of 20")
        assertDecodeRefused(AccountEntryExtensionV2.self, Vector.word(0) + Vector.word(0) + Vector.word(21),
                            "XDR array count 21 exceeds the maximum of 20")
        assertEncodeRefused(AccountEntryExtensionV2(numSponsored: 0, numSponsoring: 0,
                                                    signerSponsoringIDs: [PublicKey?](repeating: nil, count: 21),
                                                    reserved: .void),
                            "XDR array count 21 exceeds the maximum of 20")
    }

    // MARK: - String and opaque typedefs at struct fields

    func testManageDataNameAndValueAtTheMaximumRoundTrip() throws {
        let bytes = Vector.variable(Vector.repeated([0x6E], 64)) + Vector.word(1) + Vector.variable(Vector.repeated([0x76], 64))
        let decoded = try XDRDecoder.decode(ManageDataOperationXDR.self, data: bytes)
        XCTAssertEqual(decoded.dataName, String(repeating: "n", count: 64))
        XCTAssertEqual(decoded.dataValue, Data(repeating: 0x76, count: 64))
        XCTAssertEqual(try XDREncoder.encode(decoded), bytes)
    }

    func testManageDataNameAndValueAboveTheMaximumAreRefused() {
        assertDecodeRefused(ManageDataOperationXDR.self, Vector.variable(Vector.repeated([0x6E], 65)) + Vector.word(0),
                            "XDR string length 65 exceeds the maximum of 64")
        assertDecodeRefused(ManageDataOperationXDR.self, Vector.word(65),
                            "XDR string length 65 exceeds the maximum of 64")
        assertDecodeRefused(ManageDataOperationXDR.self,
                            Vector.variable([0x6E]) + Vector.word(1) + Vector.variable(Vector.repeated([0x76], 65)),
                            "XDR opaque length 65 exceeds the maximum of 64")
        assertEncodeRefused(ManageDataOperationXDR(dataName: String(repeating: "n", count: 65)),
                            "XDR string length 65 exceeds the maximum of 64")
        assertEncodeRefused(ManageDataOperationXDR(dataName: "n", dataValue: Data(repeating: 0x76, count: 65)),
                            "XDR opaque length 65 exceeds the maximum of 64")
    }

    func testOptionalHomeDomainAboveTheMaximumIsRefused() throws {
        let atMaximum = SetOptionsOperationXDR(inflationDestination: nil, clearFlags: nil, setFlags: nil,
                                               masterWeight: nil, lowThreshold: nil, medThreshold: nil,
                                               highThreshold: nil, homeDomain: String(repeating: "d", count: 32),
                                               signer: nil)
        let bytes = Vector.repeated(Vector.word(0), 7) + Vector.word(1)
            + Vector.variable(Vector.repeated([0x64], 32)) + Vector.word(0)
        XCTAssertEqual(try XDREncoder.encode(atMaximum), bytes)
        XCTAssertEqual(try XDRDecoder.decode(SetOptionsOperationXDR.self, data: bytes).homeDomain,
                       String(repeating: "d", count: 32))

        assertDecodeRefused(SetOptionsOperationXDR.self,
                            Vector.repeated(Vector.word(0), 7) + Vector.word(1)
                                + Vector.variable(Vector.repeated([0x64], 33)) + Vector.word(0),
                            "XDR string length 33 exceeds the maximum of 32")
        assertEncodeRefused(SetOptionsOperationXDR(inflationDestination: nil, clearFlags: nil, setFlags: nil,
                                                   masterWeight: nil, lowThreshold: nil, medThreshold: nil,
                                                   highThreshold: nil, homeDomain: String(repeating: "d", count: 33),
                                                   signer: nil),
                            "XDR string length 33 exceeds the maximum of 32")
    }

    func testFunctionNameIsCountedAsAStringOfBytes() throws {
        let address = Vector.word(1) + Vector.key
        let atMaximum = address + Vector.variable(Vector.repeated([0x66], 32)) + Vector.word(0)
        let decoded = try XDRDecoder.decode(InvokeContractArgsXDR.self, data: atMaximum)
        XCTAssertEqual(decoded.functionName, Data(repeating: 0x66, count: 32))
        XCTAssertEqual(try XDREncoder.encode(decoded), atMaximum)

        assertDecodeRefused(InvokeContractArgsXDR.self,
                            address + Vector.variable(Vector.repeated([0x66], 33)) + Vector.word(0),
                            "XDR string length 33 exceeds the maximum of 32")
        assertEncodeRefused(InvokeContractArgsXDR(contractAddress: decoded.contractAddress,
                                                  functionName: Data(repeating: 0x66, count: 33), args: []),
                            "XDR string length 33 exceeds the maximum of 32")
    }

    // MARK: - Arrays of bounded strings and opaque values

    func testEventPrefixTopicsBoundTheArrayAndEachTopic() throws {
        let atMaximum = Vector.specEvent(topics: [Vector.repeated([0x74], 32), Vector.repeated([0x74], 32)])
        let decoded = try XDRDecoder.decode(SCSpecEventV0XDR.self, data: atMaximum)
        XCTAssertEqual(decoded.prefixTopics, [String(repeating: "t", count: 32), String(repeating: "t", count: 32)])
        XCTAssertEqual(try XDREncoder.encode(decoded), atMaximum)

        assertDecodeRefused(SCSpecEventV0XDR.self, Vector.specEvent(topics: [[0x74], [0x74], [0x74]]),
                            "XDR array count 3 exceeds the maximum of 2")
        assertDecodeRefused(SCSpecEventV0XDR.self, Vector.specEvent(topics: [Vector.repeated([0x74], 33)]),
                            "XDR string length 33 exceeds the maximum of 32")
        assertDecodeRefused(SCSpecEventV0XDR.self, Vector.specEventPrefix + Vector.word(1) + Vector.word(33),
                            "XDR string length 33 exceeds the maximum of 32")

        var tooMany = decoded
        tooMany.prefixTopics = ["a", "b", "c"]
        assertEncodeRefused(tooMany, "XDR array count 3 exceeds the maximum of 2")
        var tooLong = decoded
        tooLong.prefixTopics = [String(repeating: "t", count: 33)]
        assertEncodeRefused(tooLong, "XDR string length 33 exceeds the maximum of 32")
    }

    func testLedgerUpgradesBoundTheArrayAndEachUpgrade() throws {
        let upgrade = Vector.repeated([0x75], 128)
        let atMaximum = Vector.stellarValue(upgrades: [[UInt8]](repeating: upgrade, count: 6))
        let decoded = try XDRDecoder.decode(StellarValueXDR.self, data: atMaximum)
        XCTAssertEqual(decoded.upgrades, [Data](repeating: Data(upgrade), count: 6))
        XCTAssertEqual(try XDREncoder.encode(decoded), atMaximum)

        assertDecodeRefused(StellarValueXDR.self, Vector.stellarValue(upgrades: [[UInt8]](repeating: [0x75], count: 7)),
                            "XDR array count 7 exceeds the maximum of 6")
        assertDecodeRefused(StellarValueXDR.self, Vector.stellarValue(upgrades: [Vector.repeated([0x75], 129)]),
                            "XDR opaque length 129 exceeds the maximum of 128")
        assertDecodeRefused(StellarValueXDR.self, Vector.hash + Vector.hyper(0) + Vector.word(1) + Vector.word(129),
                            "XDR opaque length 129 exceeds the maximum of 128")

        var tooMany = decoded
        tooMany.upgrades = [Data](repeating: Data([0x75]), count: 7)
        assertEncodeRefused(tooMany, "XDR array count 7 exceeds the maximum of 6")
        var tooLong = decoded
        tooLong.upgrades = [Data(Vector.repeated([0x75], 129))]
        assertEncodeRefused(tooLong, "XDR opaque length 129 exceeds the maximum of 128")
    }

    // MARK: - Array typedef wrapper (1000) and union arm array (2)

    func testTxAdvertVectorAtTheMaximumRoundTripsAndAboveIsRefused() throws {
        let atMaximum = Vector.word(1000) + Vector.repeated(Vector.hash, 1000)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(TxAdvertVectorXDR.self, data: atMaximum)), atMaximum)

        assertDecodeRefused(TxAdvertVectorXDR.self, Vector.word(1001) + Vector.repeated(Vector.hash, 1001),
                            "XDR array count 1001 exceeds the maximum of 1000")
        assertDecodeRefused(TxAdvertVectorXDR.self, Vector.word(1001),
                            "XDR array count 1001 exceeds the maximum of 1000")
        assertEncodeRefused(TxAdvertVectorXDR(wrapped: [WrappedData32](repeating: WrappedData32(Data(Vector.hash)),
                                                                        count: 1001)),
                            "XDR array count 1001 exceeds the maximum of 1000")
    }

    func testClaimPredicateAndAtTheMaximumRoundTripsAndAboveIsRefused() throws {
        let atMaximum = Vector.word(1) + Vector.word(2) + Vector.repeated(Vector.word(0), 2)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(ClaimPredicateXDR.self, data: atMaximum)), atMaximum)

        assertDecodeRefused(ClaimPredicateXDR.self, Vector.word(1) + Vector.word(3) + Vector.repeated(Vector.word(0), 3),
                            "XDR array count 3 exceeds the maximum of 2")
        assertDecodeRefused(ClaimPredicateXDR.self, Vector.word(1) + Vector.word(3),
                            "XDR array count 3 exceeds the maximum of 2")
        assertEncodeRefused(ClaimPredicateXDR.claimPredicateAnd(
                                [ClaimPredicateXDR](repeating: .claimPredicateUnconditional, count: 3)),
                            "XDR array count 3 exceeds the maximum of 2")
    }

    // MARK: - Unbounded values

    func testUnboundedValuesWellAboveEveryMaximumRoundTrip() throws {
        let text = Vector.repeated([0x78], 70_000)
        let string = Vector.word(14) + Vector.variable(text)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(SCValXDR.self, data: string)), string)

        let bytes = Vector.word(13) + Vector.variable(text)
        XCTAssertEqual(try XDREncoder.encode(try XDRDecoder.decode(SCValXDR.self, data: bytes)), bytes)

        let vector = Vector.word(16) + Vector.word(1) + Vector.word(1_100) + Vector.repeated(Vector.word(1), 1_100)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: vector)
        guard case .vec(let elements?) = decoded else { return XCTFail("expected SCV_VEC, got \(decoded)") }
        XCTAssertEqual(elements.count, 1_100)
        XCTAssertEqual(try XDREncoder.encode(decoded), vector)
    }

    // MARK: - Foundation coders

    func testFoundationCodersDoNotApplyTheDeclaredMaxima() throws {
        let enumCase = SCSpecUDTEnumCaseV0XDR(doc: "", name: String(repeating: "n", count: 61), value: 1)
        assertEncodeRefused(enumCase, "XDR string length 61 exceeds the maximum of 60")
        let roundTripped = try JSONDecoder().decode(SCSpecUDTEnumCaseV0XDR.self,
                                                   from: try JSONEncoder().encode(enumCase))
        XCTAssertEqual(roundTripped.name, String(repeating: "n", count: 61))

        let memo = MemoXDR.text(Data(repeating: 0x61, count: 29))
        assertEncodeRefused(memo, "XDR string length 29 exceeds the maximum of 28")
        let memoBack = try JSONDecoder().decode(MemoXDR.self, from: try JSONEncoder().encode(memo))
        guard case .text(let text) = memoBack else { return XCTFail("expected MEMO_TEXT, got \(memoBack)") }
        XCTAssertEqual(text, Data(repeating: 0x61, count: 29))

        let payload = Ed25519SignedPayload(ed25519: WrappedData32(Data(Vector.key)),
                                           payload: Data(repeating: 0x70, count: 65))
        assertEncodeRefused(payload, "XDR opaque length 65 exceeds the maximum of 64")
        let payloadBack = try JSONDecoder().decode(Ed25519SignedPayload.self, from: try JSONEncoder().encode(payload))
        XCTAssertEqual(payloadBack.payload, Data(repeating: 0x70, count: 65))

        let tuple = SCSpecTypeTupleXDR(valueTypes: [SCSpecTypeDefXDR](repeating: .bool, count: 13))
        assertEncodeRefused(tuple, "XDR array count 13 exceeds the maximum of 12")
        XCTAssertNoThrow(try JSONEncoder().encode(tuple))
    }

    // MARK: - Encoder without the declared maxima

    // One test per bounded encode helper: the default encoder refuses the value, and an encoder
    // created without the declared maxima writes it in the XDR layout.

    func testEncoderWithoutTheMaximaWritesAnArrayAboveItsMaximum() throws {
        let tuple = SCSpecTypeTupleXDR(valueTypes: [SCSpecTypeDefXDR](repeating: .bool, count: 13))
        assertEncodeRefused(tuple, "XDR array count 13 exceeds the maximum of 12")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(tuple), Vector.word(13) + Vector.repeated(Vector.word(1), 13))
    }

    func testEncoderWithoutTheMaximaWritesAStringArrayAboveItsMaxima() throws {
        let tooMany = Value.specEvent(topics: ["a", "b", "c"])
        assertEncodeRefused(tooMany, "XDR array count 3 exceeds the maximum of 2")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(tooMany), Vector.specEvent(topics: [[0x61], [0x62], [0x63]]))

        let tooLong = Value.specEvent(topics: [String(repeating: "t", count: 33)])
        assertEncodeRefused(tooLong, "XDR string length 33 exceeds the maximum of 32")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(tooLong), Vector.specEvent(topics: [Vector.repeated([0x74], 33)]))
    }

    func testEncoderWithoutTheMaximaWritesAnOpaqueArrayAboveItsMaxima() throws {
        let tooMany = Value.stellarValue(upgrades: [Data](repeating: Data([0x75]), count: 7))
        assertEncodeRefused(tooMany, "XDR array count 7 exceeds the maximum of 6")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(tooMany),
                       Vector.stellarValue(upgrades: [[UInt8]](repeating: [0x75], count: 7)))

        let tooLong = Value.stellarValue(upgrades: [Data(repeating: 0x75, count: 129)])
        assertEncodeRefused(tooLong, "XDR opaque length 129 exceeds the maximum of 128")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(tooLong),
                       Vector.stellarValue(upgrades: [Vector.repeated([0x75], 129)]))
    }

    func testEncoderWithoutTheMaximaWritesAStringAboveItsMaximum() throws {
        let symbol = SCValXDR.symbol(String(repeating: "s", count: 33))
        assertEncodeRefused(symbol, "XDR string length 33 exceeds the maximum of 32")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(symbol),
                       Vector.word(15) + Vector.variable(Vector.repeated([0x73], 33)))
    }

    func testEncoderWithoutTheMaximaWritesOpaqueDataAboveItsMaximum() throws {
        let signature = DecoratedSignatureXDR(hint: WrappedData4(Data([0x01, 0x02, 0x03, 0x04])),
                                              signature: Data(repeating: 0x33, count: 65))
        assertEncodeRefused(signature, "XDR opaque length 65 exceeds the maximum of 64")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(signature),
                       [0x01, 0x02, 0x03, 0x04] + Vector.variable(Vector.repeated([0x33], 65)))
    }

    func testEncoderWithoutTheMaximaWritesStringBytesAboveTheirMaximum() throws {
        let memo = MemoXDR.text(Data(repeating: 0x61, count: 29))
        assertEncodeRefused(memo, "XDR string length 29 exceeds the maximum of 28")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(memo), Vector.word(1) + Vector.variable(Vector.repeated([0x61], 29)))
    }

    func testEncoderWithoutTheMaximaWritesAnArrayOfOptionalElementsAboveItsMaximum() throws {
        let ext = AccountEntryExtensionV2(numSponsored: 0, numSponsoring: 0,
                                          signerSponsoringIDs: [PublicKey?](repeating: nil, count: 21),
                                          reserved: .void)
        assertEncodeRefused(ext, "XDR array count 21 exceeds the maximum of 20")
        XCTAssertEqual(try encodedWithoutDeclaredMaxima(ext), Vector.accountEntryExtensionV2(sponsoringIDs: 21))
    }

    // MARK: - Decoding depth of bounded reads

    /// The decoder allows 128 nesting levels. Each node of a delegate chain sits one level below
    /// its parent, so the leaf of a chain of n nodes is read at level n. Its signature is a
    /// vector holding a symbol: the vector, its element array, the symbol, the bounded string
    /// read and its length word or bytes take the levels n + 1 to n + 5.
    func testBoundedStringReadAtTheDepthLimitDecodesAndOneLevelDeeperIsRefused() throws {
        let atLimit = Vector.delegateChain(nodes: 123)
        let decoded = try XDRDecoder.decode(SorobanDelegateSignatureXDR.self, data: atLimit)
        XCTAssertEqual(try XDREncoder.encode(decoded), atLimit)

        XCTAssertThrowsError(try XDRDecoder.decode(SorobanDelegateSignatureXDR.self,
                                                   data: Vector.delegateChain(nodes: 124))) { error in
            guard case XDRDecoder.Error.maxDecodingDepthExceeded = error else {
                return XCTFail("expected maxDecodingDepthExceeded, got \(error)")
            }
        }
    }

    // MARK: - Assertions

    private func assertDecodeRefused<T: XDRDecodable>(_ type: T.Type, _ bytes: [UInt8], _ message: String,
                                                      file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try XDRDecoder.decode(type, data: bytes), file: file, line: line) { error in
            guard case StellarSDKError.xdrDecodingError(let actual) = error else {
                return XCTFail("expected xdrDecodingError, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(actual, message, file: file, line: line)
        }
    }

    private func assertEncodeRefused(_ value: XDREncodable, _ message: String,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try XDREncoder.encode(value), file: file, line: line) { error in
            guard case StellarSDKError.xdrEncodingError(let actual) = error else {
                return XCTFail("expected xdrEncodingError, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(actual, message, file: file, line: line)
        }
    }

    private func encodedWithoutDeclaredMaxima(_ value: XDREncodable) throws -> [UInt8] {
        let encoder = XDREncoder(enforcingDeclaredMaxima: false)
        try value.xdrEncode(to: encoder)
        return encoder.data
    }
}

// MARK: - Hand-written vectors

private enum Vector {
    static func word(_ value: UInt32) -> [UInt8] {
        [UInt8(value >> 24 & 0xFF), UInt8(value >> 16 & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)]
    }

    static func hyper(_ value: UInt64) -> [UInt8] {
        word(UInt32(value >> 32)) + word(UInt32(value & 0xFFFF_FFFF))
    }

    static func repeated(_ element: [UInt8], _ count: Int) -> [UInt8] {
        Array([[UInt8]](repeating: element, count: count).joined())
    }

    /// A length word, the bytes and the zero padding to the next four-byte boundary.
    static func variable(_ payload: [UInt8]) -> [UInt8] {
        word(UInt32(payload.count)) + payload + [UInt8](repeating: 0, count: (4 - payload.count % 4) % 4)
    }

    static let key = repeated([0x11], 32)
    static let hash = repeated([0x22], 32)

    /// KEY_TYPE_ED25519 and the key.
    static let account = word(0) + key

    /// No source account, BUMP_SEQUENCE, bumpTo 1.
    static let operation = word(0) + word(11) + hyper(1)

    /// A four-byte hint and a 64-byte signature.
    static let signature = [0x01, 0x02, 0x03, 0x04] + variable(repeated([0x33], 64))

    static func signatures(_ count: Int) -> [UInt8] {
        word(UInt32(count)) + repeated(signature, count)
    }

    /// Source account, fee 100, sequence number 1, PRECOND_NONE and MEMO_NONE.
    static let transactionPrefix = account + word(100) + hyper(1) + word(0) + word(0)

    static func transaction(operations: Int) -> [UInt8] {
        transactionPrefix + word(UInt32(operations)) + repeated(operation, operations) + word(0)
    }

    /// Source key, fee 100, sequence number 1, no time bounds, MEMO_NONE, the operations and
    /// the extension point.
    static func transactionV0(operations: Int) -> [UInt8] {
        key + word(100) + hyper(1) + word(0) + word(0)
            + word(UInt32(operations)) + repeated(operation, operations) + word(0)
    }

    /// Fee source, fee 200, ENVELOPE_TYPE_TX with one operation and no signatures, and the
    /// extension point.
    static let feeBumpTransaction = account + hyper(200) + word(2) + transaction(operations: 1) + word(0) + word(0)

    /// Native assets and amounts around the destination, then the path of native assets.
    static func pathPayment(path: Int) -> [UInt8] {
        word(0) + hyper(1) + account + word(0) + hyper(1) + word(UInt32(path)) + repeated(word(0), path)
    }

    /// A native asset, amount 1, then CLAIMANT_TYPE_V0 claimants with an unconditional predicate.
    static func createClaimableBalance(claimants: Int) -> [UInt8] {
        word(0) + hyper(1) + word(UInt32(claimants)) + repeated(word(0) + account + word(0), claimants)
    }

    /// No time bounds, ledger bounds or minimum sequence number, zero age and gap, then the
    /// ed25519 signer keys.
    static func preconditionsV2(extraSigners: Int) -> [UInt8] {
        word(0) + word(0) + word(0) + hyper(0) + word(0) + word(UInt32(extraSigners)) + repeated(account, extraSigners)
    }

    /// No sponsored or sponsoring entries, absent sponsor IDs and the extension point.
    static func accountEntryExtensionV2(sponsoringIDs: Int) -> [UInt8] {
        word(0) + word(0) + word(UInt32(sponsoringIDs)) + repeated(word(0), sponsoringIDs) + word(0)
    }

    /// Empty doc and lib, name "e".
    static let specEventPrefix = variable([]) + variable([]) + variable([0x65])

    /// The prefix topics, no parameters and the single-value data format.
    static func specEvent(topics: [[UInt8]]) -> [UInt8] {
        specEventPrefix + word(UInt32(topics.count)) + topics.flatMap { variable($0) } + word(0) + word(0)
    }

    /// The transaction set hash, close time 0, the upgrades and STELLAR_VALUE_BASIC.
    static func stellarValue(upgrades: [[UInt8]]) -> [UInt8] {
        hash + hyper(0) + word(UInt32(upgrades.count)) + upgrades.flatMap { variable($0) } + word(0)
    }

    /// A chain of delegate signatures, each node the only nested delegate of its parent. Every
    /// node has a contract address; the leaf signs with a vector holding a 32-byte symbol, the
    /// maximum, and every other node with void.
    static func delegateChain(nodes: Int) -> [UInt8] {
        let address = word(1) + hash
        let leaf = address + word(16) + word(1) + word(1) + word(15) + variable(repeated([0x73], 32)) + word(0)
        return repeated(address + word(1) + word(1), nodes - 1) + leaf
    }
}

// MARK: - Values built through the public initializers

private enum Value {
    static let muxedAccount = MuxedAccountXDR.ed25519(Vector.key)

    static let signature = DecoratedSignatureXDR(hint: WrappedData4(Data([0x01, 0x02, 0x03, 0x04])),
                                                 signature: Data(repeating: 0x33, count: 64))

    static func publicKey() throws -> PublicKey {
        try PublicKey(Vector.key)
    }

    static func operations(_ count: Int) -> [OperationXDR] {
        [OperationXDR](repeating: OperationXDR(body: .bumpSequenceOp(BumpSequenceOperationXDR(bumpTo: 1))), count: count)
    }

    static func transaction(operations: Int) -> TransactionXDR {
        TransactionXDR(sourceAccount: muxedAccount, seqNum: 1, cond: .none, memo: .none,
                       operations: self.operations(operations))
    }

    static func transactionV0(operations: Int) throws -> TransactionV0XDR {
        TransactionV0XDR(sourceAccount: try publicKey(), seqNum: 1, timeBounds: nil, memo: .none,
                         operations: self.operations(operations))
    }

    /// Empty doc and lib, name "e", the prefix topics, no parameters and the single-value data
    /// format, as `Vector.specEvent(topics:)` writes it.
    static func specEvent(topics: [String]) -> SCSpecEventV0XDR {
        SCSpecEventV0XDR(doc: "", lib: "", name: "e", prefixTopics: topics, params: [], dataFormat: .singleValue)
    }

    /// The transaction set hash, close time 0, the upgrades and STELLAR_VALUE_BASIC, as
    /// `Vector.stellarValue(upgrades:)` writes it.
    static func stellarValue(upgrades: [Data]) -> StellarValueXDR {
        StellarValueXDR(txSetHash: WrappedData32(Data(Vector.hash)), closeTime: 0, upgrades: upgrades, ext: .basic)
    }

    static func feeBumpTransaction() throws -> FeeBumpTransactionXDR {
        FeeBumpTransactionXDR(sourceAccount: muxedAccount,
                              innerTx: .v1(TransactionV1EnvelopeXDR(tx: transaction(operations: 1), signatures: [])),
                              fee: 200)
    }
}
