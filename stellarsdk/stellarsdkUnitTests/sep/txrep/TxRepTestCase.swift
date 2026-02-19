//
//  TxRepTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TxRepTestCase: XCTestCase {

    func testToTxRepBasicTransaction() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 123456)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX"))
        XCTAssertTrue(txRep.contains("tx.sourceAccount: \(source.accountId)"))
        XCTAssertTrue(txRep.contains("tx.seqNum: 123457"))
        XCTAssertTrue(txRep.contains("tx.operations.len: 1"))
        XCTAssertTrue(txRep.contains("PAYMENT"))
        XCTAssertTrue(txRep.contains("signatures.len: 1"))
    }

    func testToTxRepWithMemoNone() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 100)
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(50)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_NONE"))
    }

    func testToTxRepWithMemoText() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 200)
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(75)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .text("Test memo")
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_TEXT"))
        XCTAssertTrue(txRep.contains("tx.memo.text: \"Test memo\""))
    }

    func testToTxRepWithMemoId() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 300)
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(25)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .id(12345)
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_ID"))
        XCTAssertTrue(txRep.contains("tx.memo.id: 12345"))
    }

    func testToTxRepWithMemoHash() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 400)
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(10)
        )

        let hashData = Data(repeating: 1, count: 32)
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .hash(hashData)
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_HASH"))
        XCTAssertTrue(txRep.contains("tx.memo.hash:"))
    }

    func testToTxRepWithMemoReturn() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 500)
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(5)
        )

        let returnData = Data(repeating: 2, count: 32)
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .returnHash(returnData)
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_RETURN"))
        XCTAssertTrue(txRep.contains("tx.memo.retHash:"))
    }

    func testMemoReturnRoundTrip() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let account = Account(keyPair: source, sequenceNumber: 500)
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(5)
        )

        let returnData = Data(repeating: 0xAB, count: 32)
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .returnHash(returnData)
        )

        let envelope = try transaction.encodedEnvelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: envelope)
        let roundTrippedEnvelope = try TxRep.fromTxRep(txRep: txRep)
        let roundTrippedTx = try Transaction(envelopeXdr: roundTrippedEnvelope)

        if case .returnHash(let data) = roundTrippedTx.memo {
            XCTAssertEqual(data, returnData)
        } else {
            XCTFail("Expected MEMO_RETURN memo after round-trip")
        }
    }

    func testFromTxRepBasicTransaction() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 1535756672
        tx.cond.timeBounds.maxTime: 1567292672
        tx.memo.type: MEMO_TEXT
        tx.memo.text: "Enjoy this transaction"
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O
        tx.operations[0].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
        tx.operations[0].body.paymentOp.amount: 400004000
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: 4aa07ed0
        signatures[0].signature: defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d31b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c
        """

        let envelope = try TxRep.fromTxRep(txRep: txRep)

        XCTAssertFalse(envelope.isEmpty)

        let transaction = try Transaction(envelopeXdr: envelope)
        XCTAssertEqual(transaction.operations.count, 1)
        XCTAssertEqual(transaction.fee, 100)

        guard let paymentOp = transaction.operations[0] as? PaymentOperation else {
            XCTFail("Expected PaymentOperation")
            return
        }

        XCTAssertEqual(paymentOp.destinationAccountId, "GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O")
        XCTAssertEqual(paymentOp.amount, Decimal(string: "40.0004"))
    }

    func testTxRepRoundtrip() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 123456)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .text("Test")
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let originalEnvelope = try transaction.encodedEnvelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: originalEnvelope)
        let reconstructedEnvelope = try TxRep.fromTxRep(txRep: txRep)

        XCTAssertEqual(originalEnvelope, reconstructedEnvelope)
    }

    func testFeeBumpTransaction() throws {
        let innerSource = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: innerSource, sequenceNumber: 654321)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(50)
        )

        let innerTransaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try innerTransaction.sign(keyPair: innerSource, network: .testnet)

        let feeBumpSource = try KeyPair.generateRandomKeyPair()
        let feeBumpTx = try FeeBumpTransaction(
            sourceAccount: MuxedAccount(accountId: feeBumpSource.accountId),
            fee: 200,
            innerTransaction: innerTransaction
        )

        try feeBumpTx.sign(keyPair: feeBumpSource, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: feeBumpTx.encodedEnvelope())

        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX_FEE_BUMP"))
        XCTAssertTrue(txRep.contains("feeBump.tx.feeSource: \(feeBumpSource.accountId)"))
        XCTAssertTrue(txRep.contains("feeBump.tx.fee: 200"))
        XCTAssertTrue(txRep.contains("feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX"))
        XCTAssertTrue(txRep.contains("feeBump.tx.innerTx.tx.sourceAccount: \(innerSource.accountId)"))
    }

    func testFeeBumpTransactionRoundtrip() throws {
        let innerSource = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: innerSource, sequenceNumber: 987654)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(25)
        )

        let innerTransaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: .id(999)
        )

        try innerTransaction.sign(keyPair: innerSource, network: .testnet)

        let feeBumpSource = try KeyPair.generateRandomKeyPair()
        let feeBumpTx = try FeeBumpTransaction(
            sourceAccount: MuxedAccount(accountId: feeBumpSource.accountId),
            fee: 300,
            innerTransaction: innerTransaction
        )

        try feeBumpTx.sign(keyPair: feeBumpSource, network: .testnet)

        let originalEnvelope = try feeBumpTx.encodedEnvelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: originalEnvelope)
        let reconstructedEnvelope = try TxRep.fromTxRep(txRep: txRep)

        XCTAssertEqual(originalEnvelope, reconstructedEnvelope)
    }

    func testInvalidTxRepMissingValue() throws {
        let incompleteTxRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: incompleteTxRep)) { error in
            guard let txRepError = error as? TxRepError else {
                XCTFail("Expected TxRepError, got \(type(of: error))")
                return
            }

            if case .missingValue = txRepError {
                // Expected error type
            } else {
                XCTFail("Expected missingValue error")
            }
        }
    }

    func testInvalidTxRepInvalidValue() throws {
        let invalidTxRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: INVALID_ACCOUNT_ID
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: invalidTxRep)) { error in
            // Should throw an error for invalid account ID
            // Could be TxRepError.invalidValue or another error type
        }
    }

    func testTxRepWithPreconditions() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 111111)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(15)
        )

        let minTime: UInt64 = 1609459200  // 2021-01-01
        let maxTime: UInt64 = 1640995200  // 2022-01-01
        let timeBounds = TimeBounds(minTime: minTime, maxTime: maxTime)
        let preconditions = TransactionPreconditions(timeBounds: timeBounds)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none,
            preconditions: preconditions
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_TIME"))
        XCTAssertTrue(txRep.contains("tx.cond.timeBounds.minTime: \(minTime)"))
        XCTAssertTrue(txRep.contains("tx.cond.timeBounds.maxTime: \(maxTime)"))
    }

    func testTxRepWithMultipleOperations() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 222222)

        let payment1 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(10)
        )

        let payment2 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(20)
        )

        let payment3 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(30)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment1, payment2, payment3],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations.len: 3"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PAYMENT"))
        XCTAssertTrue(txRep.contains("tx.operations[1].body.type: PAYMENT"))
        XCTAssertTrue(txRep.contains("tx.operations[2].body.type: PAYMENT"))
    }

    func testTxRepWithMultipleSignatures() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 333333)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(40)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: .testnet)

        let additionalSigner = try KeyPair.generateRandomKeyPair()
        try transaction.sign(keyPair: additionalSigner, network: .testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("signatures.len: 2"))
        XCTAssertTrue(txRep.contains("signatures[0].hint:"))
        XCTAssertTrue(txRep.contains("signatures[0].signature:"))
        XCTAssertTrue(txRep.contains("signatures[1].hint:"))
        XCTAssertTrue(txRep.contains("signatures[1].signature:"))
    }
}
