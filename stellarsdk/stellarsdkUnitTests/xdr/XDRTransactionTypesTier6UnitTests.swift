//
//  XDRTransactionTypesTier6UnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDRTransactionTypesTier6UnitTests: XCTestCase {

    // Helper method to create a simple bump sequence operation
    private func createBumpSequenceOperation(bumpTo: Int64 = 1000000) -> OperationXDR {
        let bumpSeqOp = BumpSequenceOperationXDR(bumpTo: bumpTo)
        let muxedAccount: MuxedAccountXDR? = nil
        return OperationXDR(sourceAccount: muxedAccount, body: .bumpSequence(bumpSeqOp))
    }

    // MARK: - TransactionV0XDR Tests

    func testTransactionV0XDRInitWithSourceAccount() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 123456789
        let memo = MemoXDR.none
        let timeBounds = TimeBoundsXDR(minTime: 0, maxTime: 1000000)

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: timeBounds,
                                  memo: memo,
                                  operations: [operation],
                                  maxOperationFee: 150)

        XCTAssertEqual(tx.seqNum, seqNum)
        XCTAssertEqual(tx.fee, 150)
        XCTAssertEqual(tx.operations.count, 1)
        XCTAssertEqual(tx.reserved, 0)
        XCTAssertNotNil(tx.timeBounds)
    }

    func testTransactionV0XDRRoundTrip() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 987654321
        let memo = MemoXDR.text("Test memo")
        let timeBounds = TimeBoundsXDR(minTime: 100, maxTime: 2000000)

        let operation = createBumpSequenceOperation(bumpTo: 5000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: timeBounds,
                                  memo: memo,
                                  operations: [operation],
                                  maxOperationFee: 200)

        let encoded = try XDREncoder.encode(tx)
        let decoded = try XDRDecoder.decode(TransactionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.seqNum, seqNum)
        XCTAssertEqual(decoded.fee, 200)
        XCTAssertEqual(decoded.operations.count, 1)
        XCTAssertEqual(decoded.reserved, 0)
        XCTAssertEqual(decoded.sourceAccountEd25519.count, 32)
    }

    func testTransactionV0XDRWithoutTimeBounds() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 111111
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation],
                                  maxOperationFee: 100)

        let encoded = try XDREncoder.encode(tx)
        let decoded = try XDRDecoder.decode(TransactionV0XDR.self, data: encoded)

        XCTAssertNil(decoded.timeBounds)
        XCTAssertEqual(decoded.seqNum, seqNum)
    }

    func testTransactionV0XDRMultipleOperations() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 222222
        let hashData = Data(repeating: 0xAB, count: 32)
        let memo = MemoXDR.hash(WrappedData32(hashData))

        let operation1 = createBumpSequenceOperation(bumpTo: 1000000)
        let operation2 = createBumpSequenceOperation(bumpTo: 2000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation1, operation2],
                                  maxOperationFee: 100)

        XCTAssertEqual(tx.fee, 200) // 100 * 2 operations
        XCTAssertEqual(tx.operations.count, 2)

        let encoded = try XDREncoder.encode(tx)
        let decoded = try XDRDecoder.decode(TransactionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.operations.count, 2)
        XCTAssertEqual(decoded.fee, 200)
    }

    func testTransactionV0XDRSignature() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 333333
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        var tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        try tx.sign(keyPair: keyPair, network: .testnet)

        let hash = try tx.hash(network: .testnet)
        XCTAssertEqual(hash.count, 32)
    }

    func testTransactionV0XDRAddSignature() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 444444
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        var tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let signatureData = Data(repeating: 0xCD, count: 64)
        let hintData = Data(repeating: 0xEF, count: 4)
        let signature = DecoratedSignatureXDR(hint: WrappedData4(hintData),
                                             signature: signatureData)
        tx.addSignature(signature: signature)

        let envelope = try tx.toEnvelopeV0XDR()
        XCTAssertEqual(envelope.signatures.count, 1)
    }

    func testTransactionV0XDRToEnvelopeXDR() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 555555
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let envelope = try tx.toEnvelopeXDR()

        switch envelope {
        case .v0(let v0Envelope):
            XCTAssertEqual(v0Envelope.tx.seqNum, seqNum)
        default:
            XCTFail("Expected v0 envelope")
        }
    }

    func testTransactionV0XDREncodedEnvelope() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 666666
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let encodedEnvelope = try tx.encodedEnvelope()
        XCTAssertFalse(encodedEnvelope.isEmpty)
        XCTAssertGreaterThan(encodedEnvelope.count, 0)
    }

    func testTransactionV0XDREncodedV0Envelope() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 777777
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let encodedV0Envelope = try tx.encodedV0Envelope()
        XCTAssertFalse(encodedV0Envelope.isEmpty)
        XCTAssertGreaterThan(encodedV0Envelope.count, 0)
    }

    func testTransactionV0XDREncodedV0Transaction() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 888888
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let encodedTransaction = try tx.encodedV0Transaction()
        XCTAssertFalse(encodedTransaction.isEmpty)
        XCTAssertGreaterThan(encodedTransaction.count, 0)
    }

    func testTransactionV0XDRHashWithTimeBounds() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 999999
        let memo = MemoXDR.none
        let timeBounds = TimeBoundsXDR(minTime: 500, maxTime: 5000000)

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: timeBounds,
                                  memo: memo,
                                  operations: [operation])

        let hash = try tx.hash(network: .testnet)
        XCTAssertEqual(hash.count, 32)
    }

    // MARK: - TransactionV0EnvelopeXDR Tests

    func testTransactionV0EnvelopeXDRInit() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 123456
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let signatureData = Data(repeating: 0xAB, count: 64)
        let hintData = Data(repeating: 0xCD, count: 4)
        let signature = DecoratedSignatureXDR(hint: WrappedData4(hintData),
                                             signature: signatureData)

        let envelope = TransactionV0EnvelopeXDR(tx: tx, signatures: [signature])

        XCTAssertEqual(envelope.tx.seqNum, seqNum)
        XCTAssertEqual(envelope.signatures.count, 1)
    }

    func testTransactionV0EnvelopeXDRRoundTrip() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 654321
        let memo = MemoXDR.text("Test")

        let operation = createBumpSequenceOperation(bumpTo: 2000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let signatureData = Data(repeating: 0x12, count: 64)
        let hintData = Data(repeating: 0x34, count: 4)
        let signature = DecoratedSignatureXDR(hint: WrappedData4(hintData),
                                             signature: signatureData)

        let envelope = TransactionV0EnvelopeXDR(tx: tx, signatures: [signature])

        let encoded = try XDREncoder.encode(envelope)
        let decoded = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.tx.seqNum, seqNum)
        XCTAssertEqual(decoded.signatures.count, 1)
    }

    func testTransactionV0EnvelopeXDRTxSourceAccountId() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let seqNum: Int64 = 111111
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: publicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let envelope = TransactionV0EnvelopeXDR(tx: tx, signatures: [])

        let sourceAccountId = envelope.txSourceAccountId
        XCTAssertEqual(sourceAccountId, accountIdString)
    }

    func testTransactionV0EnvelopeXDRWithMultipleSignatures() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 999999
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let signature1 = DecoratedSignatureXDR(hint: WrappedData4(Data(repeating: 0x11, count: 4)),
                                              signature: Data(repeating: 0xAA, count: 64))
        let signature2 = DecoratedSignatureXDR(hint: WrappedData4(Data(repeating: 0x22, count: 4)),
                                              signature: Data(repeating: 0xBB, count: 64))

        let envelope = TransactionV0EnvelopeXDR(tx: tx, signatures: [signature1, signature2])

        let encoded = try XDREncoder.encode(envelope)
        let decoded = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.signatures.count, 2)
    }

    func testTransactionV0EnvelopeXDREmptySignatures() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let sourcePublicKey = keyPair.publicKey
        let seqNum: Int64 = 123123
        let memo = MemoXDR.none

        let operation = createBumpSequenceOperation(bumpTo: 1000000)

        let tx = TransactionV0XDR(sourceAccount: sourcePublicKey,
                                  seqNum: seqNum,
                                  timeBounds: nil,
                                  memo: memo,
                                  operations: [operation])

        let envelope = TransactionV0EnvelopeXDR(tx: tx, signatures: [])

        let encoded = try XDREncoder.encode(envelope)
        let decoded = try XDRDecoder.decode(TransactionV0EnvelopeXDR.self, data: encoded)

        XCTAssertEqual(decoded.signatures.count, 0)
    }

    // MARK: - TransactionMetaV2XDR Tests

    func testTransactionMetaV2XDRDecodingFromValidData() throws {
        // Create a minimal valid TransactionMetaV2XDR by encoding data
        // Since there's no public init, we test the decoding path which is the main coverage target

        var data = [UInt8]()

        // txChangesBefore: empty array (4 bytes for count = 0)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // operations: array with 1 element (4 bytes for count = 1)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])

        // OperationMetaXDR: changes (empty array, 4 bytes for count = 0)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // txChangesAfter: empty array (4 bytes for count = 0)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: data)

        XCTAssertEqual(decoded.operations.count, 1)
        XCTAssertEqual(decoded.txChangesBefore.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.txChangesAfter.ledgerEntryChanges.count, 0)
    }

    func testTransactionMetaV2XDRDecodingWithMultipleOperations() throws {
        var data = [UInt8]()

        // txChangesBefore: empty array
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // operations: array with 3 elements
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x03])

        // OperationMetaXDR 1: changes (empty array)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // OperationMetaXDR 2: changes (empty array)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // OperationMetaXDR 3: changes (empty array)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // txChangesAfter: empty array
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: data)

        XCTAssertEqual(decoded.operations.count, 3)
    }

    func testTransactionMetaV2XDRDecodingEmptyOperations() throws {
        var data = [UInt8]()

        // txChangesBefore: empty array
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // operations: empty array
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // txChangesAfter: empty array
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: data)

        XCTAssertEqual(decoded.operations.count, 0)
    }

    // MARK: - OperationResultXDR Tests

    func testOperationResultXDREmpty() throws {
        let errorCodes: [OperationResultCode] = [
            .badAuth,
            .noAccount,
            .notSupported,
            .tooManySubentries,
            .exceededWorkLimit,
            .tooManySponsoring
        ]

        for errorCode in errorCodes {
            let opResult = OperationResultXDR.empty(errorCode.rawValue)

            let encoded = try XDREncoder.encode(opResult)
            let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

            switch decoded {
            case .empty(let code):
                XCTAssertEqual(code, errorCode.rawValue)
            default:
                XCTFail("Expected empty result for code \(errorCode.rawValue)")
            }
        }
    }

    // MARK: - LiquidityPoolEntryXDR Tests

    func testLiquidityPoolConstantProductParametersXDRRoundTrip() throws {
        let assetA = AssetXDR.native
        let assetB = AssetXDR.native
        let fee: Int32 = 50

        let params = LiquidityPoolConstantProductParametersXDR(assetA: assetA, assetB: assetB, fee: fee)

        let encoded = try XDREncoder.encode(params)
        let decoded = try XDRDecoder.decode(LiquidityPoolConstantProductParametersXDR.self, data: encoded)

        XCTAssertEqual(decoded.fee, fee)
    }

    func testLiquidityPoolConstantProductParametersXDRWithAssets() throws {
        let issuerAString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let issuerA = try PublicKey(accountId: issuerAString)

        let assetCodeAData = Data("USD".utf8) + Data(repeating: 0, count: 1)
        let assetCodeAWrapped = WrappedData4(assetCodeAData)
        let assetA = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeAWrapped, issuer: issuerA))

        let issuerBString = "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
        let issuerB = try PublicKey(accountId: issuerBString)

        let assetCodeBData = Data("EUR".utf8) + Data(repeating: 0, count: 1)
        let assetCodeBWrapped = WrappedData4(assetCodeBData)
        let assetB = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeBWrapped, issuer: issuerB))

        let fee: Int32 = 100

        let params = LiquidityPoolConstantProductParametersXDR(assetA: assetA, assetB: assetB, fee: fee)

        let encoded = try XDREncoder.encode(params)
        let decoded = try XDRDecoder.decode(LiquidityPoolConstantProductParametersXDR.self, data: encoded)

        XCTAssertEqual(decoded.fee, fee)
    }

    func testLiquidityPoolBodyXDRConstantProductType() throws {
        var data = [UInt8]()
        // LiquidityPoolType.constantProduct = 0
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Encode the ConstantProductXDR
        // params (LiquidityPoolConstantProductParametersXDR)
        //   assetA (native): type = 0
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        //   assetB (native): type = 0
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        //   fee: Int32 = 30
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x1E])

        // reserveA: Int64 = 100000
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x86, 0xA0])
        // reserveB: Int64 = 200000
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x0D, 0x40])
        // totalPoolShares: Int64 = 300000
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x93, 0xE0])
        // poolSharesTrustLineCount: Int64 = 5
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05])

        let decoded = try XDRDecoder.decode(LiquidityPoolBodyXDR.self, data: data)

        XCTAssertEqual(decoded.type(), LiquidityPoolType.constantProduct.rawValue)
    }
}
