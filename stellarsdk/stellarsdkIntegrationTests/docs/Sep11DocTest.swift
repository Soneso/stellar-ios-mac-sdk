//
//  Sep11DocTest.swift
//  stellarsdkTests
//
//  Created for documentation testing.
//

import XCTest
import stellarsdk

class Sep11DocTest: XCTestCase {

    // MARK: - Quick Example: XDR to TxRep

    func testQuickExampleXdrToTxRep() throws {
        // Snippet 1: Convert base64 XDR to TxRep
        let xdrBase64 = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

        let txRep = try TxRep.toTxRep(transactionEnvelope: xdrBase64)

        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX"))
        XCTAssertTrue(txRep.contains("tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN"))
        XCTAssertTrue(txRep.contains("tx.fee: 100"))
        XCTAssertTrue(txRep.contains("tx.seqNum: 46489056724385793"))
        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_TIME"))
        XCTAssertTrue(txRep.contains("tx.cond.timeBounds.minTime: 1535756672"))
        XCTAssertTrue(txRep.contains("tx.cond.timeBounds.maxTime: 1567292672"))
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_TEXT"))
        XCTAssertTrue(txRep.contains("tx.memo.text: \"Enjoy this transaction\""))
        XCTAssertTrue(txRep.contains("tx.operations.len: 1"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PAYMENT"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.destination: GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.amount: 400004000"))
        XCTAssertTrue(txRep.contains("signatures.len: 1"))
        XCTAssertTrue(txRep.contains("signatures[0].hint: 4aa07ed0"))
    }

    // MARK: - Standard Transaction to TxRep

    func testStandardTransactionToTxRep() throws {
        // Snippet 2: Build a transaction and convert to TxRep
        let sourceKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CPMLIHJPFV5RXN5M6CSS")
        let account = Account(keyPair: sourceKeyPair, sequenceNumber: 100)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.text("Test payment")
        )

        try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX"))
        XCTAssertTrue(txRep.contains("tx.sourceAccount: \(sourceKeyPair.accountId)"))
        XCTAssertTrue(txRep.contains("tx.fee: 100"))
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_TEXT"))
        XCTAssertTrue(txRep.contains("tx.memo.text: \"Test payment\""))
        XCTAssertTrue(txRep.contains("tx.operations.len: 1"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PAYMENT"))
        XCTAssertTrue(txRep.contains("GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"))
        XCTAssertTrue(txRep.contains("signatures.len: 1"))
    }

    // MARK: - Fee Bump Transaction to TxRep

    func testFeeBumpTransactionToTxRep() throws {
        // Snippet 3: Convert fee bump XDR to TxRep
        let feeBumpXdr = "AAAABQAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAAAAGQAAAAAgAAAAAx5Qe+wF5jJp3kYrOZ2zBOQOcTHjtRBuR/GrBTLYydyQAAAGQAAVlhAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAAAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAL68IAAAAAAAAAAAEtjJ3JAAAAQFzU5qFDIaZRUzUxf0BrRO2abx0PuMn3WKM7o8NXZvmB7K0zvS+HBlmDo2P/M3IZpF5Riax21neE0N9/WiHRuAoAAAAAAAAAAdoh7ugAAABARiKZWxfy8ZOPRj6yZRTKXAp1Aw6SoEn5OvnFbOmVztZtSRUaVOaCnBpdDWFBNJ6xBwsm7lMxvomMaOyNM3T/Bg=="

        let txRep = try TxRep.toTxRep(transactionEnvelope: feeBumpXdr)

        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX_FEE_BUMP"))
        XCTAssertTrue(txRep.contains("feeBump.tx.feeSource:"))
        XCTAssertTrue(txRep.contains("feeBump.tx.fee: 400"))
        XCTAssertTrue(txRep.contains("feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX"))
        XCTAssertTrue(txRep.contains("feeBump.tx.innerTx.tx.sourceAccount:"))
        XCTAssertTrue(txRep.contains("feeBump.tx.innerTx.tx.fee: 100"))
    }

    // MARK: - TxRep to XDR

    func testTxRepToXdr() throws {
        // Snippet 4: Parse TxRep back into XDR
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

        let xdrBase64 = try TxRep.fromTxRep(txRep: txRep)

        XCTAssertFalse(xdrBase64.isEmpty)

        // Verify the resulting XDR can be decoded back to a Transaction
        let transaction = try Transaction(envelopeXdr: xdrBase64)
        XCTAssertEqual(transaction.fee, 100)
        XCTAssertEqual(transaction.operations.count, 1)

        guard let paymentOp = transaction.operations[0] as? PaymentOperation else {
            XCTFail("Expected PaymentOperation")
            return
        }
        XCTAssertEqual(paymentOp.destinationAccountId, "GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O")
        XCTAssertEqual(paymentOp.amount, Decimal(string: "40.0004"))
    }

    // MARK: - Inspecting a Transaction

    func testInspectTransactionBeforeSigning() throws {
        // Snippet 5: Parse XDR and extract fields from TxRep lines
        let xdrBase64 = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

        let txRep = try TxRep.toTxRep(transactionEnvelope: xdrBase64)

        let lines = txRep.split(separator: "\n").map { String($0) }
        var foundFee = false
        var foundAmount = false
        var foundDestination = false

        for line in lines {
            if line.contains("tx.fee:") {
                let fee = line.split(separator: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if let feeInt = Int(fee) {
                    XCTAssertEqual(feeInt, 100)
                    foundFee = true
                }
            }
            if line.contains("paymentOp.amount:") {
                let amount = line.split(separator: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if let amountInt = Int(amount) {
                    XCTAssertEqual(amountInt, 400004000)
                    foundAmount = true
                }
            }
            if line.contains("paymentOp.destination:") {
                let dest = line.split(separator: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                XCTAssertEqual(dest, "GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O")
                foundDestination = true
            }
        }

        XCTAssertTrue(foundFee, "Should find fee in TxRep output")
        XCTAssertTrue(foundAmount, "Should find amount in TxRep output")
        XCTAssertTrue(foundDestination, "Should find destination in TxRep output")
    }

    // MARK: - Round-Trip Conversion

    func testRoundTripConversion() throws {
        // Snippet 6: XDR -> TxRep -> XDR round-trip
        let originalXdr = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

        let txRep = try TxRep.toTxRep(transactionEnvelope: originalXdr)
        let reconstructedXdr = try TxRep.fromTxRep(txRep: txRep)

        XCTAssertEqual(originalXdr, reconstructedXdr)
    }

    // MARK: - Comparing Two Transactions

    func testCompareTwoTransactions() throws {
        // Snippet 7: Compare two transactions via TxRep
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")

        // Transaction 1: 100 XLM payment
        let account1 = Account(keyPair: source, sequenceNumber: 100)
        let payment1 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )
        let tx1 = try Transaction(
            sourceAccount: account1,
            operations: [payment1],
            memo: Memo.none
        )

        // Transaction 2: 200 XLM payment (different amount)
        let account2 = Account(keyPair: source, sequenceNumber: 100)
        let payment2 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(200)
        )
        let tx2 = try Transaction(
            sourceAccount: account2,
            operations: [payment2],
            memo: Memo.none
        )

        let txRep1 = try TxRep.toTxRep(transactionEnvelope: tx1.encodedEnvelope())
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: tx2.encodedEnvelope())

        let lines1 = txRep1.split(separator: "\n").map { String($0) }
        let lines2 = txRep2.split(separator: "\n").map { String($0) }

        // The transactions should differ in the payment amount
        var differences = [(Int, String, String)]()
        for i in 0..<lines1.count {
            let line2 = i < lines2.count ? lines2[i] : ""
            if lines1[i] != line2 {
                differences.append((i + 1, lines1[i], line2))
            }
        }

        // There should be at least one difference (the amount line)
        XCTAssertFalse(differences.isEmpty, "Transactions should have differences")

        // Verify the amount difference exists
        let amountDiff = differences.first { $0.1.contains("paymentOp.amount") }
        XCTAssertNotNil(amountDiff, "Should find difference in payment amount")
    }

    // MARK: - Error Handling

    func testErrorHandlingInvalidBase64() throws {
        // Snippet 8: Error handling for invalid XDR
        XCTAssertThrowsError(try TxRep.toTxRep(transactionEnvelope: "not-valid-base64!")) { error in
            // Should throw an error for invalid base64/XDR
            XCTAssertNotNil(error)
        }
    }

    func testErrorHandlingInvalidTxRep() throws {
        // Snippet 8 continued: Error handling for invalid TxRep
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: "this is not valid txrep")) { error in
            XCTAssertNotNil(error)
        }
    }

    func testErrorHandlingMissingFields() throws {
        // Snippet 8 continued: Error handling for incomplete TxRep
        let incompleteTxrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: incompleteTxrep)) { error in
            XCTAssertNotNil(error)
        }
    }

    func testErrorHandlingInvalidAccount() throws {
        // Snippet 8 continued: Error handling for invalid account ID
        let badAccountTxrep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: NOT_A_VALID_ACCOUNT
        tx.fee: 100
        tx.seqNum: 1
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: badAccountTxrep)) { error in
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Working with Amounts

    func testAmountConversions() {
        // Snippet 9: Stroops conversion
        let stroops = 400004000
        let displayAmount = Double(stroops) / Double(10_000_000)
        XCTAssertEqual(displayAmount, 40.0004, accuracy: 0.0000001)

        let amount = 25.5
        let stroopsValue = Int(amount * 10_000_000.0)
        XCTAssertEqual(stroopsValue, 255000000)

        func formatAmount(_ stroops: Int) -> String {
            return String(format: "%.7f", Double(stroops) / 10_000_000.0)
        }

        XCTAssertEqual(formatAmount(400004000), "40.0004000")
    }

    // MARK: - Fee Bump Transaction Round-Trip

    func testFeeBumpTransactionRoundTrip() throws {
        // Additional test: build a fee bump transaction and round-trip it
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
            sourceAccount: try MuxedAccount(accountId: feeBumpSource.accountId),
            fee: 200,
            innerTransaction: innerTransaction
        )

        try feeBumpTx.sign(keyPair: feeBumpSource, network: .testnet)

        let originalEnvelope = try feeBumpTx.encodedEnvelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: originalEnvelope)

        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX_FEE_BUMP"))
        XCTAssertTrue(txRep.contains("feeBump.tx.feeSource: \(feeBumpSource.accountId)"))
        XCTAssertTrue(txRep.contains("feeBump.tx.fee: 200"))

        let reconstructedEnvelope = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(originalEnvelope, reconstructedEnvelope)
    }

    // MARK: - Programmatic Transaction Round-Trip

    func testProgrammaticTransactionRoundTrip() throws {
        // Build a transaction from scratch, convert to TxRep, and back
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
}
