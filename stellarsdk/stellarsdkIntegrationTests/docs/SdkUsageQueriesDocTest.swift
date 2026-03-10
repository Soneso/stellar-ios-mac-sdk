//
//  SdkUsageQueriesDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SdkUsageQueriesDocTest: XCTestCase {
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

    // MARK: - Account Queries

    func testGetSingleAccount() async {
        // Snippet: Get Single Account
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch response {
        case .success(let account):
            XCTAssertEqual(account.accountId, keyPair.accountId)
            XCTAssertTrue(account.sequenceNumber > 0)
            XCTAssertTrue(account.subentryCount >= 0)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testQueryAccountsBySigner() async {
        // Snippet: Query by Signer
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.accounts.getAccounts(
            signer: keyPair.accountId,
            order: .descending,
            limit: 10
        )
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
            XCTAssertEqual(page.records.first?.accountId, keyPair.accountId)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testGetAccountDataEntry() async {
        // Snippet: Get Account Data Entry
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        // First set a data entry
        let accResponse = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch accResponse {
        case .success(let account):
            let setDataOp = ManageDataOperation(
                sourceAccountId: nil,
                name: "testKey",
                data: "testValue".data(using: .utf8)
            )
            let transaction = try! Transaction(
                sourceAccount: account,
                operations: [setDataOp],
                memo: Memo.none
            )
            try! transaction.sign(keyPair: keyPair, network: Network.testnet)
            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(_):
                break
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
                return
            case .failure(let error):
                XCTFail("Submit error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
            return
        }

        // Now read it back
        let dataResponse = await sdk.accounts.getDataForAccount(accountId: keyPair.accountId, key: "testKey")
        switch dataResponse {
        case .success(let data):
            XCTAssertFalse(data.value.isEmpty)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Transaction Queries

    func testGetTransactionsForAccount() async {
        // Snippet: Transactions for Account
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.transactions.getTransactions(
            forAccount: keyPair.accountId,
            order: .descending,
            limit: 20
        )
        switch response {
        case .success(let page):
            // Friendbot creates at least one transaction
            XCTAssertFalse(page.records.isEmpty)
            for tx in page.records {
                XCTAssertFalse(tx.transactionHash.isEmpty)
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testGetSingleTransaction() async {
        // Snippet: Get Single Transaction
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        // Get the latest transaction for the account
        let txListResponse = await sdk.transactions.getTransactions(
            forAccount: keyPair.accountId,
            order: .descending,
            limit: 1
        )
        switch txListResponse {
        case .success(let page):
            guard let firstTx = page.records.first else {
                XCTFail("No transactions found")
                return
            }

            let txResponse = await sdk.transactions.getTransactionDetails(transactionHash: firstTx.transactionHash)
            switch txResponse {
            case .success(let tx):
                XCTAssertEqual(tx.transactionHash, firstTx.transactionHash)
                XCTAssertTrue(tx.operationCount > 0)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Operation Queries

    func testGetOperationsForAccount() async {
        // Snippet: Operations for Account
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.operations.getOperations(
            forAccount: keyPair.accountId,
            order: .descending,
            limit: 50
        )
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
            for op in page.records {
                XCTAssertFalse(op.operationTypeString.isEmpty)
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testHandleOperationTypes() async {
        // Snippet: Handling Operation Types
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        // Send a payment to have an operation to query
        let accResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            let paymentOp = try! PaymentOperation(
                sourceAccountId: nil,
                destinationAccountId: receiverKeyPair.accountId,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: 10
            )
            let transaction = try! Transaction(
                sourceAccount: account,
                operations: [paymentOp],
                memo: Memo.none
            )
            try! transaction.sign(keyPair: senderKeyPair, network: Network.testnet)
            let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitResponse {
            case .success(_):
                break
            case .destinationRequiresMemo(let destinationAccountId):
                XCTFail("Destination \(destinationAccountId) requires memo")
                return
            case .failure(let error):
                XCTFail("Submit error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
            return
        }

        // Now query operations and check types
        let response = await sdk.operations.getOperations(
            forAccount: senderKeyPair.accountId,
            order: .descending,
            limit: 10
        )
        switch response {
        case .success(let page):
            var foundPayment = false
            for op in page.records {
                if let paymentOp = op as? PaymentOperationResponse {
                    XCTAssertFalse(paymentOp.amount.isEmpty)
                    XCTAssertFalse(paymentOp.to.isEmpty)
                    foundPayment = true
                } else if op is AccountCreatedOperationResponse {
                    // Friendbot creates account
                }
            }
            XCTAssertTrue(foundPayment)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Effect Queries

    func testEffectsForAccount() async {
        // Snippet: Effect Queries
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.effects.getEffects(
            forAccount: keyPair.accountId,
            limit: 50
        )
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Ledger Queries

    func testLedgerQueries() async {
        // Snippet: Ledger Queries
        let response = await sdk.ledgers.getLedgers(order: .descending, limit: 1)
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
            let latestLedger = page.records.first!
            XCTAssertTrue(latestLedger.sequenceNumber > 0)

            // Query that specific ledger
            let ledgerResponse = await sdk.ledgers.getLedger(sequenceNumber: String(latestLedger.sequenceNumber))
            switch ledgerResponse {
            case .success(let ledger):
                XCTAssertEqual(ledger.sequenceNumber, latestLedger.sequenceNumber)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Payment Queries

    func testPaymentQueries() async {
        // Snippet: Payment Queries
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.payments.getPayments(forAccount: keyPair.accountId)
        switch response {
        case .success(let page):
            // Friendbot creates an account creation payment
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Asset Queries

    func testAssetQueries() async {
        // Snippet: Find by Code
        let response = await sdk.assets.getAssets(for: "USD", limit: 5)
        switch response {
        case .success(let page):
            // There should be at least some USD assets on testnet
            for asset in page.records {
                XCTAssertEqual(asset.assetCode, "USD")
                XCTAssertFalse(asset.assetIssuer?.isEmpty ?? true)
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Fee Statistics

    func testFeeStatistics() async {
        // Snippet: Fee Statistics
        let response = await sdk.feeStats.getFeeStats()
        switch response {
        case .success(let feeStats):
            XCTAssertFalse(feeStats.feeCharged.min.isEmpty)
            XCTAssertFalse(feeStats.feeCharged.mode.isEmpty)
            XCTAssertFalse(feeStats.feeCharged.p90.isEmpty)
            XCTAssertFalse(feeStats.maxFee.min.isEmpty)
            XCTAssertFalse(feeStats.maxFee.mode.isEmpty)
            XCTAssertFalse(feeStats.maxFee.p90.isEmpty)
            XCTAssertFalse(feeStats.lastLedgerBaseFee.isEmpty)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Pagination

    func testPagination() async {
        // Snippet: Pagination
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        // First page
        let response = await sdk.transactions.getTransactions(
            forAccount: keyPair.accountId,
            order: .descending,
            limit: 1
        )
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)

            // Get next page using cursor from last record
            if let lastRecord = page.records.last {
                let nextPageResponse = await sdk.transactions.getTransactions(
                    forAccount: keyPair.accountId,
                    from: lastRecord.pagingToken,
                    order: .descending,
                    limit: 1
                )
                switch nextPageResponse {
                case .success(_):
                    // Success - may or may not have more records
                    break
                case .failure(let error):
                    XCTFail("Error on next page: \(error)")
                }
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Error Handling

    func testHorizonErrors() async {
        // Snippet: Horizon HTTP Errors
        let response = await sdk.accounts.getAccountDetails(accountId: "GINVALIDACCOUNT")
        switch response {
        case .success(_):
            XCTFail("Should not succeed for invalid account")
        case .failure(let error):
            // Expected to fail - either not found or bad request
            XCTAssertNotNil(error)
        }
    }
}
