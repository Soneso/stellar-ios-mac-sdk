//
//  TransactionEnvelopeXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionEnvelopeXDRUnitTests: XCTestCase {

    // MARK: - Helper Methods

    private func createBumpSequenceOperation(bumpTo: Int64 = 1000000) -> OperationXDR {
        let bumpSeqOp = BumpSequenceOperationXDR(bumpTo: bumpTo)
        let muxedAccount: MuxedAccountXDR? = nil
        return OperationXDR(sourceAccount: muxedAccount, body: .bumpSequence(bumpSeqOp))
    }

    private func createTestSignature(hint: [UInt8] = [0x01, 0x02, 0x03, 0x04],
                                      signatureBytes: [UInt8]? = nil) -> DecoratedSignatureXDR {
        var sigBytes: [UInt8]
        if let provided = signatureBytes {
            sigBytes = provided
        } else {
            sigBytes = [UInt8](repeating: 0xAB, count: 64)
        }
        let hintData = Data(hint)
        let signatureData = Data(sigBytes)
        return DecoratedSignatureXDR(hint: WrappedData4(hintData), signature: signatureData)
    }

    // MARK: - TransactionEnvelopeXDR V0 Tests

    func testTransactionEnvelopeXDRV0() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 100001
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 500000)

        let txV0 = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                    seqNum: seqNum,
                                    timeBounds: nil,
                                    memo: memo,
                                    operations: [operation],
                                    maxOperationFee: 100)

        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let envelope = TransactionEnvelopeXDR.v0(v0Envelope)

        XCTAssertEqual(envelope.type(), 0) // ENVELOPE_TYPE_TX_V0
        XCTAssertEqual(envelope.txSeqNum, seqNum)
        XCTAssertEqual(envelope.txFee, 100)
        XCTAssertEqual(envelope.txOperations.count, 1)
    }

    // MARK: - TransactionEnvelopeXDR V1 Tests

    func testTransactionEnvelopeXDRV1() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 200002
        let memo = MemoXDR.text("v1 test memo")
        let cond = PreconditionsXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 600000)

        let txXDR = TransactionXDR(sourceAccount: sourcePublicKey,
                                   seqNum: seqNum,
                                   cond: cond,
                                   memo: memo,
                                   operations: [operation],
                                   maxOperationFee: 150)

        let v1Envelope = TransactionV1EnvelopeXDR(tx: txXDR, signatures: [])
        let envelope = TransactionEnvelopeXDR.v1(v1Envelope)

        XCTAssertEqual(envelope.type(), 2) // ENVELOPE_TYPE_TX
        XCTAssertEqual(envelope.txSeqNum, seqNum)
        XCTAssertEqual(envelope.txFee, 150)
        XCTAssertEqual(envelope.txOperations.count, 1)

        if case .text(let text) = envelope.txMemo {
            XCTAssertEqual(text, "v1 test memo")
        } else {
            XCTFail("Expected text memo")
        }
    }

    // MARK: - TransactionEnvelopeXDR Fee Bump Tests

    func testTransactionEnvelopeXDRFeeBump() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = innerKeyPair.publicKey
        let seqNum: Int64 = 300003
        let memo = MemoXDR.none
        let cond = PreconditionsXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 700000)

        let innerTxXDR = TransactionXDR(sourceAccount: sourcePublicKey,
                                        seqNum: seqNum,
                                        cond: cond,
                                        memo: memo,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)

        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])
        let envelope = TransactionEnvelopeXDR.feeBump(feeBumpEnvelope)

        XCTAssertEqual(envelope.type(), 5) // ENVELOPE_TYPE_TX_FEE_BUMP
        XCTAssertEqual(envelope.txSeqNum, seqNum)
        XCTAssertEqual(envelope.txFee, 100) // Inner transaction fee
        XCTAssertEqual(envelope.txOperations.count, 1)
    }

    // MARK: - Discriminant Tests

    func testTransactionEnvelopeXDRDiscriminants() throws {
        // Test envelope type values by verifying the type() method returns expected values
        // for each envelope variant (the constants themselves are internal)
        let keyPair = try KeyPair.generateRandomKeyPair()
        let operation = createBumpSequenceOperation()

        // V0 envelope should return type 0
        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: 1,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [operation])
        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let envelopeV0 = TransactionEnvelopeXDR.v0(v0Envelope)
        XCTAssertEqual(envelopeV0.type(), 0) // ENVELOPE_TYPE_TX_V0

        // V1 envelope should return type 2
        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: 2,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [operation])
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])
        let envelopeV1 = TransactionEnvelopeXDR.v1(v1Envelope)
        XCTAssertEqual(envelopeV1.type(), 2) // ENVELOPE_TYPE_TX

        // Fee bump envelope should return type 5
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(v1Envelope)
        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)
        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])
        let envelopeFeeBump = TransactionEnvelopeXDR.feeBump(feeBumpEnvelope)
        XCTAssertEqual(envelopeFeeBump.type(), 5) // ENVELOPE_TYPE_TX_FEE_BUMP
    }

    // MARK: - Base64 Decode Tests

    func testTransactionEnvelopeXDRFromBase64V0() throws {
        // Create a V0 envelope and encode it
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 400004
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 800000)

        let txV0 = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                    seqNum: seqNum,
                                    timeBounds: nil,
                                    memo: memo,
                                    operations: [operation],
                                    maxOperationFee: 100)

        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let originalEnvelope = TransactionEnvelopeXDR.v0(v0Envelope)

        // Encode to XDR then base64
        var encoded = try XDREncoder.encode(originalEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        // Decode from base64
        let decoded = try TransactionEnvelopeXDR(fromBase64: base64)

        XCTAssertEqual(decoded.type(), 0) // ENVELOPE_TYPE_TX_V0
        XCTAssertEqual(decoded.txSeqNum, seqNum)
        XCTAssertEqual(decoded.txFee, 100)
    }

    func testTransactionEnvelopeXDRFromBase64V1() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 500005
        let memo = MemoXDR.id(12345)
        let cond = PreconditionsXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 900000)

        let txXDR = TransactionXDR(sourceAccount: sourcePublicKey,
                                   seqNum: seqNum,
                                   cond: cond,
                                   memo: memo,
                                   operations: [operation],
                                   maxOperationFee: 200)

        let v1Envelope = TransactionV1EnvelopeXDR(tx: txXDR, signatures: [])
        let originalEnvelope = TransactionEnvelopeXDR.v1(v1Envelope)

        var encoded = try XDREncoder.encode(originalEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        let decoded = try TransactionEnvelopeXDR(fromBase64: base64)

        XCTAssertEqual(decoded.type(), 2) // ENVELOPE_TYPE_TX
        XCTAssertEqual(decoded.txSeqNum, seqNum)
        XCTAssertEqual(decoded.txFee, 200)

        if case .id(let memoId) = decoded.txMemo {
            XCTAssertEqual(memoId, 12345)
        } else {
            XCTFail("Expected id memo")
        }
    }

    // MARK: - Round Trip Tests

    func testTransactionEnvelopeXDRRoundTrip() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 600006
        let hashData = Data(repeating: 0xCD, count: 32)
        let memo = MemoXDR.hash(WrappedData32(hashData))
        let timeBounds = TimeBoundsXDR(minTime: 1000, maxTime: 2000000)
        let cond = PreconditionsXDR.time(timeBounds)

        let operation1 = createBumpSequenceOperation(bumpTo: 1000000)
        let operation2 = createBumpSequenceOperation(bumpTo: 2000000)

        let txXDR = TransactionXDR(sourceAccount: sourcePublicKey,
                                   seqNum: seqNum,
                                   cond: cond,
                                   memo: memo,
                                   operations: [operation1, operation2],
                                   maxOperationFee: 125)

        let signature = createTestSignature()
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txXDR, signatures: [signature])
        let originalEnvelope = TransactionEnvelopeXDR.v1(v1Envelope)

        // Encode
        let encoded = try XDREncoder.encode(originalEnvelope)
        XCTAssertFalse(encoded.isEmpty)

        // Decode
        let decoded = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data: encoded)

        // Verify
        XCTAssertEqual(decoded.type(), 2) // ENVELOPE_TYPE_TX
        XCTAssertEqual(decoded.txSeqNum, seqNum)
        XCTAssertEqual(decoded.txFee, 250) // 125 * 2 operations
        XCTAssertEqual(decoded.txOperations.count, 2)
        XCTAssertEqual(decoded.txSignatures.count, 1)
        XCTAssertNotNil(decoded.txTimeBounds)
        XCTAssertEqual(decoded.txTimeBounds?.minTime, 1000)
        XCTAssertEqual(decoded.txTimeBounds?.maxTime, 2000000)
    }

    // MARK: - Signature Tests

    func testTransactionEnvelopeXDRWithSignatures() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 700007
        let memo = MemoXDR.none
        let cond = PreconditionsXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1100000)

        let txXDR = TransactionXDR(sourceAccount: sourcePublicKey,
                                   seqNum: seqNum,
                                   cond: cond,
                                   memo: memo,
                                   operations: [operation],
                                   maxOperationFee: 100)

        let signature = createTestSignature(hint: [0x11, 0x22, 0x33, 0x44])
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txXDR, signatures: [signature])
        let envelope = TransactionEnvelopeXDR.v1(v1Envelope)

        XCTAssertEqual(envelope.txSignatures.count, 1)
        XCTAssertEqual(envelope.txSignatures[0].hint.wrapped, Data([0x11, 0x22, 0x33, 0x44]))
        XCTAssertEqual(envelope.txSignatures[0].signature.count, 64)
    }

    func testTransactionEnvelopeXDRWithMultipleSignatures() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 800008
        let memo = MemoXDR.none
        let cond = PreconditionsXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1200000)

        let txXDR = TransactionXDR(sourceAccount: sourcePublicKey,
                                   seqNum: seqNum,
                                   cond: cond,
                                   memo: memo,
                                   operations: [operation],
                                   maxOperationFee: 100)

        let sig1 = createTestSignature(hint: [0xAA, 0xBB, 0xCC, 0xDD])
        let sig2 = createTestSignature(hint: [0x11, 0x22, 0x33, 0x44])
        let sig3 = createTestSignature(hint: [0xEE, 0xFF, 0x00, 0x11])

        let v1Envelope = TransactionV1EnvelopeXDR(tx: txXDR, signatures: [sig1, sig2, sig3])
        let envelope = TransactionEnvelopeXDR.v1(v1Envelope)

        XCTAssertEqual(envelope.txSignatures.count, 3)
        XCTAssertEqual(envelope.txSignatures[0].hint.wrapped, Data([0xAA, 0xBB, 0xCC, 0xDD]))
        XCTAssertEqual(envelope.txSignatures[1].hint.wrapped, Data([0x11, 0x22, 0x33, 0x44]))
        XCTAssertEqual(envelope.txSignatures[2].hint.wrapped, Data([0xEE, 0xFF, 0x00, 0x11]))

        // Verify round-trip preserves all signatures
        let encoded = try XDREncoder.encode(envelope)
        let decoded = try XDRDecoder.decode(TransactionEnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.txSignatures.count, 3)
    }

    // MARK: - Source Account Accessor Tests

    func testTransactionEnvelopeXDRTxSourceAccount() throws {
        // Test V0 envelope source account
        let keyPairV0 = try KeyPair.generateRandomKeyPair()
        let txV0 = TransactionV0XDR(sourceAccount: keyPairV0.publicKey,
                                    seqNum: 1,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [createBumpSequenceOperation()])
        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let envelopeV0 = TransactionEnvelopeXDR.v0(v0Envelope)
        XCTAssertEqual(envelopeV0.txSourceAccountId, keyPairV0.accountId)

        // Test V1 envelope source account
        let keyPairV1 = try KeyPair.generateRandomKeyPair()
        let txV1 = TransactionXDR(sourceAccount: keyPairV1.publicKey,
                                  seqNum: 2,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [createBumpSequenceOperation()])
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])
        let envelopeV1 = TransactionEnvelopeXDR.v1(v1Envelope)
        XCTAssertEqual(envelopeV1.txSourceAccountId, keyPairV1.accountId)

        // Test fee bump envelope source account (should return inner tx source)
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)
        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)
        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])
        let envelopeFeeBump = TransactionEnvelopeXDR.feeBump(feeBumpEnvelope)
        XCTAssertEqual(envelopeFeeBump.txSourceAccountId, keyPairV1.accountId)
    }

    // MARK: - Fee Accessor Tests

    func testTransactionEnvelopeXDRTxFee() throws {
        // Test V0 fee
        let keyPair = try KeyPair.generateRandomKeyPair()
        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: 1,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [createBumpSequenceOperation()],
                                    maxOperationFee: 175)
        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let envelopeV0 = TransactionEnvelopeXDR.v0(v0Envelope)
        XCTAssertEqual(envelopeV0.txFee, 175)

        // Test V1 fee with multiple operations
        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: 2,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [createBumpSequenceOperation(), createBumpSequenceOperation()],
                                  maxOperationFee: 200)
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])
        let envelopeV1 = TransactionEnvelopeXDR.v1(v1Envelope)
        XCTAssertEqual(envelopeV1.txFee, 400) // 200 * 2 operations

        // Test fee bump (inner tx fee)
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let innerTxV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                       seqNum: 3,
                                       cond: PreconditionsXDR.none,
                                       memo: MemoXDR.none,
                                       operations: [createBumpSequenceOperation()],
                                       maxOperationFee: 300)
        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxV1, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)
        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 1000)
        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])
        let envelopeFeeBump = TransactionEnvelopeXDR.feeBump(feeBumpEnvelope)
        // txFee returns inner transaction fee, not fee bump fee
        XCTAssertEqual(envelopeFeeBump.txFee, 300)
    }

    // MARK: - Additional Accessor Tests

    func testTransactionEnvelopeXDRTxMuxedSourceId() throws {
        // V0 does not have muxed source ID
        let keyPairV0 = try KeyPair.generateRandomKeyPair()
        let txV0 = TransactionV0XDR(sourceAccount: keyPairV0.publicKey,
                                    seqNum: 1,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [createBumpSequenceOperation()])
        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let envelopeV0 = TransactionEnvelopeXDR.v0(v0Envelope)
        XCTAssertNil(envelopeV0.txMuxedSourceId)

        // V1 with muxed account
        let keyPairV1 = try KeyPair.generateRandomKeyPair()
        let muxedId: UInt64 = 123456789
        let muxedAccountMed = MuxedAccountMed25519XDR(id: muxedId, sourceAccountEd25519: keyPairV1.publicKey.bytes)
        let muxedAccount = MuxedAccountXDR.med25519(muxedAccountMed)
        let txV1 = TransactionXDR(sourceAccount: muxedAccount,
                                  seqNum: 2,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [createBumpSequenceOperation()])
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])
        let envelopeV1 = TransactionEnvelopeXDR.v1(v1Envelope)
        XCTAssertEqual(envelopeV1.txMuxedSourceId, muxedId)
    }

    // MARK: - FeeBumpTransactionXDR Tests

    func testFeeBumpTransactionXDREncodeDecode() throws {
        // Create inner transaction
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900001

        let operation = createBumpSequenceOperation(bumpTo: 1500000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpFee: UInt64 = 500

        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: feeBumpFee)

        // Encode
        let encoded = try XDREncoder.encode(feeBumpTx)
        XCTAssertFalse(encoded.isEmpty)

        // Decode
        let decoded = try XDRDecoder.decode(FeeBumpTransactionXDR.self, data: encoded)

        // Verify
        XCTAssertEqual(decoded.fee, feeBumpFee)
        XCTAssertEqual(decoded.reserved, 0)

        // Verify inner transaction
        let decodedInnerTx = decoded.innerTx.tx
        XCTAssertEqual(decodedInnerTx.tx.seqNum, seqNum)
        XCTAssertEqual(decodedInnerTx.tx.operations.count, 1)
    }

    func testFeeBumpTransactionXDRWithV1Inner() throws {
        // Create V1 inner transaction with more complex setup
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900002

        let operation1 = createBumpSequenceOperation(bumpTo: 1600000)
        let operation2 = createBumpSequenceOperation(bumpTo: 1700000)

        let timeBounds = TimeBoundsXDR(minTime: 0, maxTime: 9999999999)
        let cond = PreconditionsXDR.time(timeBounds)

        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: cond,
                                        memo: MemoXDR.text("inner memo"),
                                        operations: [operation1, operation2],
                                        maxOperationFee: 150)

        let innerSignature = createTestSignature(hint: [0x01, 0x02, 0x03, 0x04])
        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [innerSignature])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 1000)

        // Round-trip encode/decode
        let encoded = try XDREncoder.encode(feeBumpTx)
        let decoded = try XDRDecoder.decode(FeeBumpTransactionXDR.self, data: encoded)

        // Verify V1 inner transaction properties
        let decodedInnerV1 = decoded.innerTx.tx
        XCTAssertEqual(decodedInnerV1.tx.seqNum, seqNum)
        XCTAssertEqual(decodedInnerV1.tx.operations.count, 2)
        XCTAssertEqual(decodedInnerV1.tx.fee, 300) // 150 * 2 operations
        XCTAssertEqual(decodedInnerV1.signatures.count, 1)

        // Verify memo
        if case .text(let memoText) = decodedInnerV1.tx.memo {
            XCTAssertEqual(memoText, "inner memo")
        } else {
            XCTFail("Expected text memo in inner transaction")
        }
    }

    func testFeeBumpTransactionXDRFeeCalculation() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900003

        // Create inner transaction with specific fee
        let operation = createBumpSequenceOperation(bumpTo: 1800000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        // Fee bump fee must be higher than inner fee
        let feeBumpFee: UInt64 = 500 // 5x the inner fee
        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)

        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: feeBumpFee)

        // Verify fee source account
        if case .ed25519(let feeSourceBytes) = feeBumpTx.sourceAccount {
            XCTAssertEqual(feeSourceBytes, feeSourceKeyPair.publicKey.bytes)
        } else {
            XCTFail("Expected ed25519 fee source account")
        }

        // Verify fee bump fee
        XCTAssertEqual(feeBumpTx.fee, feeBumpFee)

        // Verify inner transaction fee is separate
        XCTAssertEqual(feeBumpTx.innerTx.tx.tx.fee, 100)
    }

    func testFeeBumpTransactionXDRRoundTrip() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900004

        // Create inner transaction with hash memo
        let hashData = Data(repeating: 0xAB, count: 32)
        let operation = createBumpSequenceOperation(bumpTo: 1900000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.hash(WrappedData32(hashData)),
                                        operations: [operation],
                                        maxOperationFee: 200)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let originalFeeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                                      innerTx: innerTx,
                                                      fee: 1000)

        // Encode to XDR bytes
        let encoded = try XDREncoder.encode(originalFeeBumpTx)

        // Convert to base64
        let base64 = Data(encoded).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(FeeBumpTransactionXDR.self, data: [UInt8](decodedData))

        // Verify all fields match
        XCTAssertEqual(decoded.fee, 1000)
        XCTAssertEqual(decoded.reserved, 0)

        let decodedInner = decoded.innerTx.tx
        XCTAssertEqual(decodedInner.tx.seqNum, seqNum)
        XCTAssertEqual(decodedInner.tx.fee, 200)

        // Verify hash memo
        if case .hash(let decodedHash) = decodedInner.tx.memo {
            XCTAssertEqual(decodedHash.wrapped, hashData)
        } else {
            XCTFail("Expected hash memo in decoded transaction")
        }
    }

    func testFeeBumpTransactionXDRWithMuxedFeeSource() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900005
        let muxedId: UInt64 = 9876543210

        let operation = createBumpSequenceOperation(bumpTo: 2000000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        // Create muxed fee source account
        let muxedAccountMed = MuxedAccountMed25519XDR(id: muxedId, sourceAccountEd25519: feeSourceKeyPair.publicKey.bytes)
        let feeSourceMuxed = MuxedAccountXDR.med25519(muxedAccountMed)

        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)

        // Round-trip
        let encoded = try XDREncoder.encode(feeBumpTx)
        let decoded = try XDRDecoder.decode(FeeBumpTransactionXDR.self, data: encoded)

        // Verify muxed account
        if case .med25519(let decodedMuxed) = decoded.sourceAccount {
            XCTAssertEqual(decodedMuxed.id, muxedId)
            XCTAssertEqual(decodedMuxed.sourceAccountEd25519, feeSourceKeyPair.publicKey.bytes)
        } else {
            XCTFail("Expected med25519 muxed account")
        }
    }

    // MARK: - FeeBumpTransactionEnvelopeXDR Tests

    func testFeeBumpTransactionEnvelopeXDREncodeDecode() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900006

        let operation = createBumpSequenceOperation(bumpTo: 2100000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)

        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])

        // Encode
        let encoded = try XDREncoder.encode(feeBumpEnvelope)
        XCTAssertFalse(encoded.isEmpty)

        // Decode
        let decoded = try XDRDecoder.decode(FeeBumpTransactionEnvelopeXDR.self, data: encoded)

        // Verify
        XCTAssertEqual(decoded.tx.fee, 500)
        XCTAssertEqual(decoded.signatures.count, 0)
        XCTAssertEqual(decoded.tx.innerTx.tx.tx.seqNum, seqNum)
    }

    func testFeeBumpTransactionEnvelopeXDRWithSignatures() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900007

        let operation = createBumpSequenceOperation(bumpTo: 2200000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        // Inner transaction with its own signature
        let innerSignature = createTestSignature(hint: [0xAA, 0xBB, 0xCC, 0xDD])
        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [innerSignature])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)

        // Fee bump envelope with its own signatures
        let feeBumpSig1 = createTestSignature(hint: [0x11, 0x22, 0x33, 0x44])
        let feeBumpSig2 = createTestSignature(hint: [0x55, 0x66, 0x77, 0x88])
        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [feeBumpSig1, feeBumpSig2])

        // Round-trip
        let encoded = try XDREncoder.encode(feeBumpEnvelope)
        let decoded = try XDRDecoder.decode(FeeBumpTransactionEnvelopeXDR.self, data: encoded)

        // Verify fee bump signatures
        XCTAssertEqual(decoded.signatures.count, 2)
        XCTAssertEqual(decoded.signatures[0].hint.wrapped, Data([0x11, 0x22, 0x33, 0x44]))
        XCTAssertEqual(decoded.signatures[1].hint.wrapped, Data([0x55, 0x66, 0x77, 0x88]))

        // Verify inner transaction signature preserved
        XCTAssertEqual(decoded.tx.innerTx.tx.signatures.count, 1)
        XCTAssertEqual(decoded.tx.innerTx.tx.signatures[0].hint.wrapped, Data([0xAA, 0xBB, 0xCC, 0xDD]))
    }

    func testFeeBumpTransactionEnvelopeXDRRoundTrip() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900008

        // Complex inner transaction
        let operation1 = createBumpSequenceOperation(bumpTo: 2300000)
        let operation2 = createBumpSequenceOperation(bumpTo: 2400000)
        let timeBounds = TimeBoundsXDR(minTime: 1000, maxTime: 5000000)
        let cond = PreconditionsXDR.time(timeBounds)

        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: cond,
                                        memo: MemoXDR.id(123456789),
                                        operations: [operation1, operation2],
                                        maxOperationFee: 150)

        let innerSig = createTestSignature(hint: [0xDE, 0xAD, 0xBE, 0xEF])
        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [innerSig])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 1000)

        let feeBumpSig = createTestSignature(hint: [0xCA, 0xFE, 0xBA, 0xBE])
        let originalEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [feeBumpSig])

        // Encode to base64
        var encoded = try XDREncoder.encode(originalEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(FeeBumpTransactionEnvelopeXDR.self, data: [UInt8](decodedData))

        // Verify fee bump transaction
        XCTAssertEqual(decoded.tx.fee, 1000)
        XCTAssertEqual(decoded.signatures.count, 1)
        XCTAssertEqual(decoded.signatures[0].hint.wrapped, Data([0xCA, 0xFE, 0xBA, 0xBE]))

        // Verify inner transaction
        let decodedInner = decoded.tx.innerTx.tx
        XCTAssertEqual(decodedInner.tx.seqNum, seqNum)
        XCTAssertEqual(decodedInner.tx.operations.count, 2)
        XCTAssertEqual(decodedInner.tx.fee, 300) // 150 * 2
        XCTAssertEqual(decodedInner.signatures.count, 1)

        // Verify memo
        if case .id(let memoId) = decodedInner.tx.memo {
            XCTAssertEqual(memoId, 123456789)
        } else {
            XCTFail("Expected id memo")
        }
    }

    // MARK: - Inner Transaction Tests

    func testFeeBumpTransactionInnerXDRV1Variant() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900009

        let operation = createBumpSequenceOperation(bumpTo: 2500000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.text("v1 inner"),
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerSig = createTestSignature(hint: [0x12, 0x34, 0x56, 0x78])
        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [innerSig])

        // Create inner transaction XDR
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        // Access the tx property
        let extractedV1 = innerTx.tx
        XCTAssertEqual(extractedV1.tx.seqNum, seqNum)
        XCTAssertEqual(extractedV1.tx.operations.count, 1)
        XCTAssertEqual(extractedV1.signatures.count, 1)

        // Verify memo
        if case .text(let memoText) = extractedV1.tx.memo {
            XCTAssertEqual(memoText, "v1 inner")
        } else {
            XCTFail("Expected text memo")
        }

        // Verify encode/decode of inner transaction
        let encoded = try XDREncoder.encode(innerTx)
        let decoded = try XDRDecoder.decode(FeeBumpTransactionXDR.InnerTransactionXDR.self, data: encoded)

        XCTAssertEqual(decoded.tx.tx.seqNum, seqNum)
        XCTAssertEqual(decoded.tx.signatures.count, 1)
        XCTAssertEqual(decoded.tx.signatures[0].hint.wrapped, Data([0x12, 0x34, 0x56, 0x78]))
    }

    func testFeeBumpTransactionInnerXDREnvelopeTypeEncoding() throws {
        // Verify that inner transaction encodes with ENVELOPE_TYPE_TX discriminant
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900010

        let operation = createBumpSequenceOperation(bumpTo: 2600000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        // Encode inner transaction
        let encoded = try XDREncoder.encode(innerTx)

        // First 4 bytes should be the envelope type discriminant (ENVELOPE_TYPE_TX = 2)
        XCTAssertTrue(encoded.count >= 4)
        let discriminant = Int32(encoded[0]) << 24 | Int32(encoded[1]) << 16 | Int32(encoded[2]) << 8 | Int32(encoded[3])
        XCTAssertEqual(discriminant, 2) // ENVELOPE_TYPE_TX
    }

    // MARK: - TransactionV0/V1 Envelope Tests

    func testTransactionV0EnvelopeXDREncodeDecode() throws {
        // Test basic encode/decode of TransactionV0EnvelopeXDR
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000001
        let timeBounds = TimeBoundsXDR(minTime: 0, maxTime: 1000000)

        let operation = createBumpSequenceOperation(bumpTo: 3000000)

        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: seqNum,
                                    timeBounds: timeBounds,
                                    memo: MemoXDR.text("v0 encode test"),
                                    operations: [operation],
                                    maxOperationFee: 100)

        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])

        // Encode
        let encoded = try XDREncoder.encode(v0Envelope)
        XCTAssertFalse(encoded.isEmpty)

        // Decode
        let decoded = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: encoded)

        // Verify
        XCTAssertEqual(decoded.tx.seqNum, seqNum)
        XCTAssertEqual(decoded.tx.fee, 100)
        XCTAssertEqual(decoded.tx.operations.count, 1)
        XCTAssertEqual(decoded.tx.reserved, 0)
        XCTAssertNotNil(decoded.tx.timeBounds)
        XCTAssertEqual(decoded.tx.timeBounds?.maxTime, 1000000)
        XCTAssertEqual(decoded.signatures.count, 0)

        if case .text(let memoText) = decoded.tx.memo {
            XCTAssertEqual(memoText, "v0 encode test")
        } else {
            XCTFail("Expected text memo")
        }
    }

    func testTransactionV0EnvelopeXDRWithSignatures() throws {
        // Test V0 envelope with multiple signatures
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000002

        let operation = createBumpSequenceOperation(bumpTo: 3100000)

        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: seqNum,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [operation],
                                    maxOperationFee: 150)

        let sig1 = createTestSignature(hint: [0x01, 0x02, 0x03, 0x04])
        let sig2 = createTestSignature(hint: [0x05, 0x06, 0x07, 0x08])

        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [sig1, sig2])

        // Encode and decode
        let encoded = try XDREncoder.encode(v0Envelope)
        let decoded = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: encoded)

        // Verify signatures
        XCTAssertEqual(decoded.signatures.count, 2)
        XCTAssertEqual(decoded.signatures[0].hint.wrapped, Data([0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(decoded.signatures[1].hint.wrapped, Data([0x05, 0x06, 0x07, 0x08]))
        XCTAssertEqual(decoded.signatures[0].signature.count, 64)
        XCTAssertEqual(decoded.signatures[1].signature.count, 64)
    }

    func testTransactionV0EnvelopeXDRRoundTrip() throws {
        // Test round-trip via base64
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000003
        let timeBounds = TimeBoundsXDR(minTime: 500, maxTime: 2000000)

        let operation1 = createBumpSequenceOperation(bumpTo: 3200000)
        let operation2 = createBumpSequenceOperation(bumpTo: 3300000)

        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: seqNum,
                                    timeBounds: timeBounds,
                                    memo: MemoXDR.id(987654321),
                                    operations: [operation1, operation2],
                                    maxOperationFee: 200)

        let signature = createTestSignature(hint: [0xAB, 0xCD, 0xEF, 0x12])
        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [signature])

        // Encode to base64
        var encoded = try XDREncoder.encode(v0Envelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: [UInt8](decodedData))

        // Verify all fields
        XCTAssertEqual(decoded.tx.seqNum, seqNum)
        XCTAssertEqual(decoded.tx.fee, 400) // 200 * 2 operations
        XCTAssertEqual(decoded.tx.operations.count, 2)
        XCTAssertEqual(decoded.tx.timeBounds?.minTime, 500)
        XCTAssertEqual(decoded.tx.timeBounds?.maxTime, 2000000)
        XCTAssertEqual(decoded.signatures.count, 1)
        XCTAssertEqual(decoded.signatures[0].hint.wrapped, Data([0xAB, 0xCD, 0xEF, 0x12]))

        if case .id(let memoId) = decoded.tx.memo {
            XCTAssertEqual(memoId, 987654321)
        } else {
            XCTFail("Expected id memo")
        }
    }

    func testTransactionV1EnvelopeXDREncodeDecode() throws {
        // Test basic encode/decode of TransactionV1EnvelopeXDR
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000004
        let timeBounds = TimeBoundsXDR(minTime: 0, maxTime: 3000000)
        let cond = PreconditionsXDR.time(timeBounds)

        let operation = createBumpSequenceOperation(bumpTo: 3400000)

        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: seqNum,
                                  cond: cond,
                                  memo: MemoXDR.text("v1 encode test"),
                                  operations: [operation],
                                  maxOperationFee: 125)

        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])

        // Encode
        let encoded = try XDREncoder.encode(v1Envelope)
        XCTAssertFalse(encoded.isEmpty)

        // Decode
        let decoded = try XDRDecoder.decode(TransactionV1EnvelopeXDR.self, data: encoded)

        // Verify
        XCTAssertEqual(decoded.tx.seqNum, seqNum)
        XCTAssertEqual(decoded.tx.fee, 125)
        XCTAssertEqual(decoded.tx.operations.count, 1)
        XCTAssertEqual(decoded.signatures.count, 0)

        if case .time(let decodedTimeBounds) = decoded.tx.cond {
            XCTAssertEqual(decodedTimeBounds.maxTime, 3000000)
        } else {
            XCTFail("Expected time preconditions")
        }

        if case .text(let memoText) = decoded.tx.memo {
            XCTAssertEqual(memoText, "v1 encode test")
        } else {
            XCTFail("Expected text memo")
        }
    }

    func testTransactionV1EnvelopeXDRWithSignatures() throws {
        // Test V1 envelope with multiple signatures
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000005

        let operation = createBumpSequenceOperation(bumpTo: 3500000)

        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: seqNum,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [operation],
                                  maxOperationFee: 175)

        let sig1 = createTestSignature(hint: [0x11, 0x22, 0x33, 0x44])
        let sig2 = createTestSignature(hint: [0x55, 0x66, 0x77, 0x88])
        let sig3 = createTestSignature(hint: [0x99, 0xAA, 0xBB, 0xCC])

        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [sig1, sig2, sig3])

        // Encode and decode
        let encoded = try XDREncoder.encode(v1Envelope)
        let decoded = try XDRDecoder.decode(TransactionV1EnvelopeXDR.self, data: encoded)

        // Verify signatures
        XCTAssertEqual(decoded.signatures.count, 3)
        XCTAssertEqual(decoded.signatures[0].hint.wrapped, Data([0x11, 0x22, 0x33, 0x44]))
        XCTAssertEqual(decoded.signatures[1].hint.wrapped, Data([0x55, 0x66, 0x77, 0x88]))
        XCTAssertEqual(decoded.signatures[2].hint.wrapped, Data([0x99, 0xAA, 0xBB, 0xCC]))

        // Verify all signatures have expected length
        for sig in decoded.signatures {
            XCTAssertEqual(sig.signature.count, 64)
        }
    }

    func testTransactionV1EnvelopeXDRRoundTrip() throws {
        // Test round-trip via base64
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000006
        let hashData = Data(repeating: 0xFE, count: 32)
        let timeBounds = TimeBoundsXDR(minTime: 1000, maxTime: 4000000)
        let cond = PreconditionsXDR.time(timeBounds)

        let operation1 = createBumpSequenceOperation(bumpTo: 3600000)
        let operation2 = createBumpSequenceOperation(bumpTo: 3700000)
        let operation3 = createBumpSequenceOperation(bumpTo: 3800000)

        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: seqNum,
                                  cond: cond,
                                  memo: MemoXDR.hash(WrappedData32(hashData)),
                                  operations: [operation1, operation2, operation3],
                                  maxOperationFee: 100)

        let sig1 = createTestSignature(hint: [0xDE, 0xAD, 0xBE, 0xEF])
        let sig2 = createTestSignature(hint: [0xCA, 0xFE, 0xBA, 0xBE])
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [sig1, sig2])

        // Encode to base64
        var encoded = try XDREncoder.encode(v1Envelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(TransactionV1EnvelopeXDR.self, data: [UInt8](decodedData))

        // Verify all fields
        XCTAssertEqual(decoded.tx.seqNum, seqNum)
        XCTAssertEqual(decoded.tx.fee, 300) // 100 * 3 operations
        XCTAssertEqual(decoded.tx.operations.count, 3)
        XCTAssertEqual(decoded.signatures.count, 2)
        XCTAssertEqual(decoded.signatures[0].hint.wrapped, Data([0xDE, 0xAD, 0xBE, 0xEF]))
        XCTAssertEqual(decoded.signatures[1].hint.wrapped, Data([0xCA, 0xFE, 0xBA, 0xBE]))

        if case .time(let decodedTimeBounds) = decoded.tx.cond {
            XCTAssertEqual(decodedTimeBounds.minTime, 1000)
            XCTAssertEqual(decodedTimeBounds.maxTime, 4000000)
        } else {
            XCTFail("Expected time preconditions")
        }

        if case .hash(let decodedHash) = decoded.tx.memo {
            XCTAssertEqual(decodedHash.wrapped, hashData)
        } else {
            XCTFail("Expected hash memo")
        }
    }

    func testTransactionV0XDRFields() throws {
        // Verify all V0 transaction fields
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000007
        let timeBounds = TimeBoundsXDR(minTime: 100, maxTime: 5000000)

        let operation = createBumpSequenceOperation(bumpTo: 3900000)

        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: seqNum,
                                    timeBounds: timeBounds,
                                    memo: MemoXDR.text("field test"),
                                    operations: [operation],
                                    maxOperationFee: 250)

        // Verify all fields are correctly set
        XCTAssertEqual(txV0.sourceAccountEd25519, keyPair.publicKey.bytes)
        XCTAssertEqual(txV0.seqNum, seqNum)
        XCTAssertEqual(txV0.fee, 250)
        XCTAssertEqual(txV0.operations.count, 1)
        XCTAssertEqual(txV0.reserved, 0)
        XCTAssertNotNil(txV0.timeBounds)
        XCTAssertEqual(txV0.timeBounds?.minTime, 100)
        XCTAssertEqual(txV0.timeBounds?.maxTime, 5000000)

        if case .text(let memoText) = txV0.memo {
            XCTAssertEqual(memoText, "field test")
        } else {
            XCTFail("Expected text memo")
        }

        // Test toEnvelopeXDR method
        let envelope = try txV0.toEnvelopeXDR()
        XCTAssertEqual(envelope.type(), 0) // ENVELOPE_TYPE_TX_V0
        XCTAssertEqual(envelope.txSeqNum, seqNum)

        // Test encodedEnvelope method
        let base64Envelope = try txV0.encodedEnvelope()
        XCTAssertFalse(base64Envelope.isEmpty)

        // Verify round-trip
        let decoded = try TransactionEnvelopeXDR(fromBase64: base64Envelope)
        XCTAssertEqual(decoded.txSeqNum, seqNum)
    }

    func testTransactionV1XDRFields() throws {
        // Verify all V1 transaction fields
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000008
        let timeBounds = TimeBoundsXDR(minTime: 200, maxTime: 6000000)
        let cond = PreconditionsXDR.time(timeBounds)

        let operation1 = createBumpSequenceOperation(bumpTo: 4000000)
        let operation2 = createBumpSequenceOperation(bumpTo: 4100000)

        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: seqNum,
                                  cond: cond,
                                  memo: MemoXDR.id(123456),
                                  operations: [operation1, operation2],
                                  maxOperationFee: 300)

        // Verify all fields are correctly set
        XCTAssertEqual(txV1.sourceAccount.accountId, keyPair.accountId)
        XCTAssertEqual(txV1.seqNum, seqNum)
        XCTAssertEqual(txV1.fee, 600) // 300 * 2 operations
        XCTAssertEqual(txV1.operations.count, 2)

        if case .time(let decodedTimeBounds) = txV1.cond {
            XCTAssertEqual(decodedTimeBounds.minTime, 200)
            XCTAssertEqual(decodedTimeBounds.maxTime, 6000000)
        } else {
            XCTFail("Expected time preconditions")
        }

        if case .id(let memoId) = txV1.memo {
            XCTAssertEqual(memoId, 123456)
        } else {
            XCTFail("Expected id memo")
        }

        // Verify extension is void by default
        if case .void = txV1.ext {
            // Expected
        } else {
            XCTFail("Expected void extension")
        }

        // Test toEnvelopeXDR method
        let envelope = try txV1.toEnvelopeXDR()
        XCTAssertEqual(envelope.type(), 2) // ENVELOPE_TYPE_TX
        XCTAssertEqual(envelope.txSeqNum, seqNum)
        XCTAssertEqual(envelope.txFee, 600)

        // Test encodedEnvelope method
        let base64Envelope = try txV1.encodedEnvelope()
        XCTAssertFalse(base64Envelope.isEmpty)

        // Verify round-trip
        let decoded = try TransactionEnvelopeXDR(fromBase64: base64Envelope)
        XCTAssertEqual(decoded.txSeqNum, seqNum)
        XCTAssertEqual(decoded.txFee, 600)
    }

    func testEnvelopeTypeXDRValues() throws {
        // Verify envelope type() method returns correct values for each variant
        // EnvelopeType constants are internal, so we verify via the type() method
        // Expected values: ENVELOPE_TYPE_TX_V0 = 0, ENVELOPE_TYPE_TX = 2, ENVELOPE_TYPE_TX_FEE_BUMP = 5
        let keyPair = try KeyPair.generateRandomKeyPair()
        let operation = createBumpSequenceOperation()

        // V0 envelope type should be 0 (ENVELOPE_TYPE_TX_V0)
        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: 1,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [operation])
        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])
        let envelopeV0 = TransactionEnvelopeXDR.v0(v0Envelope)
        XCTAssertEqual(envelopeV0.type(), 0) // ENVELOPE_TYPE_TX_V0

        // V1 envelope type should be 2 (ENVELOPE_TYPE_TX)
        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: 2,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [operation])
        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])
        let envelopeV1 = TransactionEnvelopeXDR.v1(v1Envelope)
        XCTAssertEqual(envelopeV1.type(), 2) // ENVELOPE_TYPE_TX

        // Fee bump envelope type should be 5 (ENVELOPE_TYPE_TX_FEE_BUMP)
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(v1Envelope)
        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)
        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])
        let envelopeFeeBump = TransactionEnvelopeXDR.feeBump(feeBumpEnvelope)
        XCTAssertEqual(envelopeFeeBump.type(), 5) // ENVELOPE_TYPE_TX_FEE_BUMP

        // Verify the type values are distinct and correctly ordered
        XCTAssertNotEqual(envelopeV0.type(), envelopeV1.type())
        XCTAssertNotEqual(envelopeV1.type(), envelopeFeeBump.type())
        XCTAssertNotEqual(envelopeV0.type(), envelopeFeeBump.type())
        XCTAssertTrue(envelopeV0.type() < envelopeV1.type())
        XCTAssertTrue(envelopeV1.type() < envelopeFeeBump.type())
    }

    func testTransactionV0EnvelopeXDRSourceAccountId() throws {
        // Test txSourceAccountId property of V0 envelope
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000009

        let operation = createBumpSequenceOperation(bumpTo: 4200000)

        let txV0 = TransactionV0XDR(sourceAccount: keyPair.publicKey,
                                    seqNum: seqNum,
                                    timeBounds: nil,
                                    memo: MemoXDR.none,
                                    operations: [operation])

        let v0Envelope = TransactionV0EnvelopeXDR(tx: txV0, signatures: [])

        // Verify txSourceAccountId
        XCTAssertEqual(v0Envelope.txSourceAccountId, keyPair.accountId)

        // Verify via TransactionEnvelopeXDR wrapper
        let envelope = TransactionEnvelopeXDR.v0(v0Envelope)
        XCTAssertEqual(envelope.txSourceAccountId, keyPair.accountId)
    }

    func testTransactionV1EnvelopeXDRSourceAccountId() throws {
        // Test txSourceAccountId property of V1 envelope
        let keyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 1000010

        let operation = createBumpSequenceOperation(bumpTo: 4300000)

        let txV1 = TransactionXDR(sourceAccount: keyPair.publicKey,
                                  seqNum: seqNum,
                                  cond: PreconditionsXDR.none,
                                  memo: MemoXDR.none,
                                  operations: [operation])

        let v1Envelope = TransactionV1EnvelopeXDR(tx: txV1, signatures: [])

        // Verify txSourceAccountId
        XCTAssertEqual(v1Envelope.txSourceAccountId, keyPair.accountId)

        // Verify via TransactionEnvelopeXDR wrapper
        let envelope = TransactionEnvelopeXDR.v1(v1Envelope)
        XCTAssertEqual(envelope.txSourceAccountId, keyPair.accountId)
    }

    func testFeeBumpTransactionXDRToEnvelopeXDR() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900011

        let operation = createBumpSequenceOperation(bumpTo: 2700000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)

        // Test toEnvelopeXDR method
        let envelope = try feeBumpTx.toEnvelopeXDR()

        // Verify it creates a fee bump envelope
        XCTAssertEqual(envelope.type(), 5) // ENVELOPE_TYPE_TX_FEE_BUMP

        // Verify inner transaction is accessible via envelope
        XCTAssertEqual(envelope.txSeqNum, seqNum)
        XCTAssertEqual(envelope.txOperations.count, 1)
    }

    func testFeeBumpTransactionXDREncodedEnvelope() throws {
        let innerKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let seqNum: Int64 = 900012

        let operation = createBumpSequenceOperation(bumpTo: 2800000)
        let innerTxXDR = TransactionXDR(sourceAccount: innerKeyPair.publicKey,
                                        seqNum: seqNum,
                                        cond: PreconditionsXDR.none,
                                        memo: MemoXDR.none,
                                        operations: [operation],
                                        maxOperationFee: 100)

        let innerV1Envelope = TransactionV1EnvelopeXDR(tx: innerTxXDR, signatures: [])
        let innerTx = FeeBumpTransactionXDR.InnerTransactionXDR.v1(innerV1Envelope)

        let feeSourceMuxed = MuxedAccountXDR.ed25519(feeSourceKeyPair.publicKey.bytes)
        let feeBumpTx = FeeBumpTransactionXDR(sourceAccount: feeSourceMuxed,
                                              innerTx: innerTx,
                                              fee: 500)

        // Test encodedEnvelope method - produces base64 string
        let base64Envelope = try feeBumpTx.encodedEnvelope()
        XCTAssertFalse(base64Envelope.isEmpty)

        // Verify it can be decoded back
        let decoded = try TransactionEnvelopeXDR(fromBase64: base64Envelope)
        XCTAssertEqual(decoded.type(), 5) // ENVELOPE_TYPE_TX_FEE_BUMP
        XCTAssertEqual(decoded.txSeqNum, seqNum)
    }
}
