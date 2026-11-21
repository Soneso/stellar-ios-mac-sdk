//
//  TransactionV0XDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionV0XDRUnitTests: XCTestCase {

    // Helper method to create a simple bump sequence operation
    private func createBumpSequenceOperation(bumpTo: Int64 = 1000000) -> OperationXDR {
        let bumpSeqOp = BumpSequenceOperationXDR(bumpTo: bumpTo)
        let muxedAccount: MuxedAccountXDR? = nil
        return OperationXDR(sourceAccount: muxedAccount, body: .bumpSequenceOp(bumpSeqOp))
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

    // MARK: - TransactionV0XDR hash vectors

    // Testnet vectors computed outside the SDK. Core hashes a V0 transaction as
    // sha256(network id || ENVELOPE_TYPE_TX || 0 || tx), which equals the hash of its V1 form with
    // the same fields and the fee as written. Each V0 envelope carries one placeholder signature.
    private struct V0HashVector {
        let envelope: String
        let signaturePayload: String
        let v1EquivalentEnvelope: String
        let hash: String
    }

    private let twoPaymentVectors = [
        // Fee 200, no time bounds, memo none.
        V0HashVector(
            envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAAAAAAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            signaturePayload: "zuAwLVmETTK9ypFcggPdRLM/u37cGQUeo3q+3yjs1HIAAAACAAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAAAAAAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAA=",
            v1EquivalentEnvelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAMgAAAABAAAAAQAAAAAAAAAAAAAAAgAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAAExLQAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
            hash: "a8da8515801f02678a926092014c2cdc5210aa5907da2dfcda6c0e69bb4542c9"),
        // Fee 200, time bounds, text memo.
        V0HashVector(
            envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAQAAAAAAAAAAAAAAAGlVuQAAAAABAAAAA8OpMQAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            signaturePayload: "zuAwLVmETTK9ypFcggPdRLM/u37cGQUeo3q+3yjs1HIAAAACAAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAQAAAAAAAAAAAAAAAGlVuQAAAAABAAAAA8OpMQAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAA=",
            v1EquivalentEnvelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAMgAAAABAAAAAQAAAAEAAAAAAAAAAAAAAABpVbkAAAAAAQAAAAPDqTEAAAAAAgAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAAExLQAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
            hash: "6e3638fb3c7cb6581e1d8cf6169ce03f4c238d535d0b9cea44984e43fe5a1201"),
    ]

    private func v0Transaction(_ envelope: TransactionEnvelopeXDR) throws -> TransactionV0XDR {
        guard case .v0(let v0Envelope) = envelope else {
            throw StellarSDKError.invalidArgument(message: "Expected a V0 envelope, got type \(envelope.type())")
        }
        return v0Envelope.tx
    }

    func testTransactionV0XDRHashUsesFeeAsWritten() throws {
        for vector in twoPaymentVectors {
            let envelope = try TransactionEnvelopeXDR(fromBase64: vector.envelope)
            let tx = try v0Transaction(envelope)
            XCTAssertEqual(tx.fee, 200)
            XCTAssertEqual(tx.operations.count, 2)

            XCTAssertEqual(try tx.hash(network: .testnet).base16EncodedString(), vector.hash)
            XCTAssertEqual(try envelope.txHash(network: .testnet).base16EncodedString(), vector.hash)
            let v1Envelope = try TransactionEnvelopeXDR(fromBase64: vector.v1EquivalentEnvelope)
            XCTAssertEqual(try v1Envelope.txHash(network: .testnet).base16EncodedString(), vector.hash)
            XCTAssertEqual(envelope.xdrEncoded, vector.envelope)
        }
    }

    func testTransactionV0XDRSignCoversCoreSignaturePayload() throws {
        for vector in twoPaymentVectors {
            var tx = try v0Transaction(TransactionEnvelopeXDR(fromBase64: vector.envelope))
            let keyPair = try KeyPair.generateRandomKeyPair()
            try tx.sign(keyPair: keyPair, network: .testnet)

            let signatures = try tx.toEnvelopeV0XDR().signatures
            XCTAssertEqual(signatures.count, 1)
            let signature = try XCTUnwrap(signatures.first)
            let payloadHash = try XCTUnwrap(Data(base64Encoded: vector.signaturePayload)).sha256Hash
            XCTAssertEqual(payloadHash.base16EncodedString(), vector.hash)
            XCTAssertTrue(try keyPair.verify(signature: [UInt8](signature.signature), message: [UInt8](payloadHash)))
        }
    }

    func testTransactionV0XDRHashOfOneOperationTransaction() throws {
        // The first payment of the fee 200 vector alone, fee 100, built and hashed outside the SDK.
        let envelope = try TransactionEnvelopeXDR(fromBase64: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAAAAAAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==")
        let tx = try v0Transaction(envelope)
        XCTAssertEqual(tx.fee, 100)
        XCTAssertEqual(tx.operations.count, 1)

        let expectedHash = "8e41cbb44b6a7aa4509f02e04ffe0fc36181ceed9cace9ba8767efd3acb06f4e"
        XCTAssertEqual(try tx.hash(network: .testnet).base16EncodedString(), expectedHash)
        XCTAssertEqual(try envelope.txHash(network: .testnet).base16EncodedString(), expectedHash)
    }

    func testTransactionV0XDRHashWithMaximumFee() throws {
        // The two payments of the fee 200 vector with fee UInt32.max, built and hashed outside the SDK.
        let envelope = try TransactionEnvelopeXDR(fromBase64: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8g/////wAAAAEAAAABAAAAAAAAAAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
        XCTAssertEqual(envelope.txFee, UInt32.max)
        XCTAssertEqual(envelope.txOperations.count, 2)
        XCTAssertEqual(try envelope.txHash(network: .testnet).base16EncodedString(),
                       "26fda0c932d5b823a2507a8c1b5b136791e87a8474db0e9fd3cd12cdd30aebdc")
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

    private func operationResultForCode(_ code: OperationResultCode) -> OperationResultXDR {
        switch code {
        case .badAuth: return .badAuth
        case .noAccount: return .noAccount
        case .notSupported: return .notSupported
        case .tooManySubentries: return .tooManySubentries
        case .exceededWorkLimit: return .exceededWorkLimit
        case .tooManySponsoring: return .tooManySponsoring
        default: fatalError("Unexpected code: \(code)")
        }
    }

    func testOperationResultXDRErrorCodes() throws {
        let errorCodes: [OperationResultCode] = [
            .badAuth,
            .noAccount,
            .notSupported,
            .tooManySubentries,
            .exceededWorkLimit,
            .tooManySponsoring
        ]

        for errorCode in errorCodes {
            let opResult = operationResultForCode(errorCode)

            let encoded = try XDREncoder.encode(opResult)
            let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

            XCTAssertEqual(decoded.type(), errorCode.rawValue, "Type mismatch for code \(errorCode)")
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
