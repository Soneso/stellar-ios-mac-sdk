//
//  SdkUsageStreamingDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SdkUsageStreamingDocTest: XCTestCase {
    let sdk = StellarSDK.testNet()

    // MARK: - Helper

    private func fundAccount(_ keyPair: KeyPair) async {
        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            XCTFail("Failed to fund \(keyPair.accountId): \(error)")
        }
    }

    private func sendPayment(from sender: KeyPair, to destination: String, amount: Decimal) async {
        let accResponse = await sdk.accounts.getAccountDetails(accountId: sender.accountId)
        switch accResponse {
        case .success(let account):
            do {
                let paymentOp = try PaymentOperation(
                    sourceAccountId: nil,
                    destinationAccountId: destination,
                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    amount: amount
                )
                let transaction = try Transaction(
                    sourceAccount: account,
                    operations: [paymentOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: sender, network: Network.testnet)
                let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResponse {
                case .success(_):
                    break
                case .destinationRequiresMemo(let destinationAccountId):
                    XCTFail("Destination \(destinationAccountId) requires memo")
                case .failure(let error):
                    XCTFail("Submit error: \(error)")
                }
            } catch {
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
        }
    }

    // MARK: - Stream Payments

    func testStreamPayments() async {
        // Snippet: Stream Payments
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let expectation = XCTestExpectation(description: "stream payments")

        let streamItem = sdk.payments.stream(for: .paymentsForAccount(account: receiverKeyPair.accountId, cursor: "now"))
        streamItem.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let payment = operationResponse as? PaymentOperationResponse {
                    XCTAssertFalse(payment.amount.isEmpty)
                    XCTAssertFalse(payment.from.isEmpty)
                    streamItem.closeStream()
                    expectation.fulfill()
                }
            case .error(let error):
                XCTFail("Stream error: \(error?.localizedDescription ?? "unknown")")
            }
        }

        // Trigger a payment
        await sendPayment(from: senderKeyPair, to: receiverKeyPair.accountId, amount: 10)

        await fulfillment(of: [expectation], timeout: 15.0)
    }

    // MARK: - Stream Transactions

    func testStreamTransactions() async {
        // Snippet: Stream Transactions
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let expectation = XCTestExpectation(description: "stream transactions")

        let streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: senderKeyPair.accountId, cursor: "now"))
        streamItem.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let transactionResponse):
                XCTAssertFalse(transactionResponse.transactionHash.isEmpty)
                XCTAssertTrue(transactionResponse.operationCount > 0)
                streamItem.closeStream()
                expectation.fulfill()
            case .error(let error):
                XCTFail("Stream error: \(error?.localizedDescription ?? "unknown")")
            }
        }

        // Trigger a transaction
        await sendPayment(from: senderKeyPair, to: receiverKeyPair.accountId, amount: 5)

        await fulfillment(of: [expectation], timeout: 15.0)
    }

    // MARK: - Stream Ledgers

    func testStreamLedgers() async {
        // Snippet: Stream Ledgers
        let expectation = XCTestExpectation(description: "stream ledgers")

        let streamItem = sdk.ledgers.stream(for: .allLedgers(cursor: "now"))
        streamItem.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let ledgerResponse):
                XCTAssertTrue(ledgerResponse.sequenceNumber > 0)
                streamItem.closeStream()
                expectation.fulfill()
            case .error(let error):
                XCTFail("Stream error: \(error?.localizedDescription ?? "unknown")")
            }
        }

        await fulfillment(of: [expectation], timeout: 15.0)
    }

    // MARK: - Stream Operations

    func testStreamOperations() async {
        // Snippet: Stream Operations
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let expectation = XCTestExpectation(description: "stream operations")

        let streamItem = sdk.operations.stream(for: .operationsForAccount(account: senderKeyPair.accountId, cursor: "now"))
        streamItem.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                XCTAssertFalse(operationResponse.operationTypeString.isEmpty)
                streamItem.closeStream()
                expectation.fulfill()
            case .error(let error):
                XCTFail("Stream error: \(error?.localizedDescription ?? "unknown")")
            }
        }

        // Trigger an operation
        await sendPayment(from: senderKeyPair, to: receiverKeyPair.accountId, amount: 5)

        await fulfillment(of: [expectation], timeout: 15.0)
    }

    // MARK: - Stream Effects

    func testStreamEffects() async {
        // Snippet: Stream Effects
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let expectation = XCTestExpectation(description: "stream effects")

        let streamItem = sdk.effects.stream(for: .effectsForAccount(account: senderKeyPair.accountId, cursor: "now"))
        streamItem.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let effectResponse):
                XCTAssertFalse(effectResponse.effectTypeString.isEmpty)
                streamItem.closeStream()
                expectation.fulfill()
            case .error(let error):
                XCTFail("Stream error: \(error?.localizedDescription ?? "unknown")")
            }
        }

        // Trigger an effect
        await sendPayment(from: senderKeyPair, to: receiverKeyPair.accountId, amount: 5)

        await fulfillment(of: [expectation], timeout: 15.0)
    }

    // MARK: - Stream Trades

    func testStreamTrades() async {
        // Snippet: Stream Trades
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        // Set up a stream for trades on this account.
        // We use tradesForAccount since it is simpler for testing.
        let streamItem = sdk.trades.stream(for: .tradesForAccount(account: keyPair.accountId, cursor: "now"))

        // Verify the stream item is created correctly
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    // MARK: - Stream Order Book

    func testStreamOrderBook() async {
        // Snippet: Stream Order Book
        let streamItem = sdk.orderbooks.stream(for: .orderbook(
            sellingAssetType: AssetTypeAsString.NATIVE,
            sellingAssetCode: nil,
            sellingAssetIssuer: nil,
            buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            limit: nil,
            cursor: "now"
        ))

        // Verify the stream item is created correctly
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    // MARK: - Stream Offers

    func testStreamOffers() async {
        // Snippet: Stream Offers
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let streamItem = sdk.offers.stream(for: .offersForAccount(account: keyPair.accountId, cursor: "now"))

        // Verify the stream item is created correctly
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }
}
