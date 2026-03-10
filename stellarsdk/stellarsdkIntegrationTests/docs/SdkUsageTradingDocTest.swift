//
//  SdkUsageTradingDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SdkUsageTradingDocTest: XCTestCase {
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

    // MARK: - Sell Offer

    func testCreateSellOffer() async {
        // Snippet: Create Sell Offer
        let issuerKeyPair = try! KeyPair.generateRandomKeyPair()
        let traderKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(issuerKeyPair)
        await fundAccount(traderKeyPair)

        // Trader must trust the asset first
        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        let accResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            do {
                let trustOp = ChangeTrustOperation(
                    sourceAccountId: nil,
                    asset: ChangeTrustAsset(canonicalForm: usdAsset.toCanonicalForm())!,
                    limit: 10000
                )
                let transaction = try Transaction(
                    sourceAccount: account,
                    operations: [trustOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
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
            } catch {
                XCTFail("Error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
            return
        }

        // Issue some USD to the trader
        let issuerAccResponse = await sdk.accounts.getAccountDetails(accountId: issuerKeyPair.accountId)
        switch issuerAccResponse {
        case .success(let issuerAccount):
            do {
                let paymentOp = try PaymentOperation(
                    sourceAccountId: nil,
                    destinationAccountId: traderKeyPair.accountId,
                    asset: usdAsset,
                    amount: 500
                )
                let transaction = try Transaction(
                    sourceAccount: issuerAccount,
                    operations: [paymentOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: issuerKeyPair, network: Network.testnet)
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
            } catch {
                XCTFail("Error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
            return
        }

        // Create a sell offer: sell 100 XLM at 0.20 USD per XLM
        let traderAccResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch traderAccResponse {
        case .success(let traderAccount):
            do {
                let sellOp = ManageSellOfferOperation(
                    sourceAccountId: nil,
                    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    buying: usdAsset,
                    amount: 100,
                    price: Price(numerator: 1, denominator: 5),  // 0.20
                    offerId: 0  // 0 = new offer
                )
                let transaction = try Transaction(
                    sourceAccount: traderAccount,
                    operations: [sellOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
                let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResponse {
                case .success(let details):
                    XCTAssertTrue(details.operationCount > 0)
                case .destinationRequiresMemo(let destinationAccountId):
                    XCTFail("Destination \(destinationAccountId) requires memo")
                case .failure(let error):
                    XCTFail("Submit error: \(error)")
                }
            } catch {
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Buy Offer

    func testCreateBuyOffer() async {
        // Snippet: Create Buy Offer
        let issuerKeyPair = try! KeyPair.generateRandomKeyPair()
        let traderKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(issuerKeyPair)
        await fundAccount(traderKeyPair)

        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        // Trust the asset
        let accResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            do {
                let trustOp = ChangeTrustOperation(
                    sourceAccountId: nil,
                    asset: ChangeTrustAsset(canonicalForm: usdAsset.toCanonicalForm())!,
                    limit: 10000
                )
                let transaction = try Transaction(
                    sourceAccount: account,
                    operations: [trustOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
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
            } catch {
                XCTFail("Error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
            return
        }

        // Create a buy offer: buy 50 USD paying with XLM at 0.20 USD per XLM
        let traderAccResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch traderAccResponse {
        case .success(let traderAccount):
            do {
                let buyOp = ManageBuyOfferOperation(
                    sourceAccountId: nil,
                    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    buying: usdAsset,
                    amount: 50,
                    price: Price(numerator: 1, denominator: 5),  // 0.20
                    offerId: 0
                )
                let transaction = try Transaction(
                    sourceAccount: traderAccount,
                    operations: [buyOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
                let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResponse {
                case .success(let details):
                    XCTAssertTrue(details.operationCount > 0)
                case .destinationRequiresMemo(let destinationAccountId):
                    XCTFail("Destination \(destinationAccountId) requires memo")
                case .failure(let error):
                    XCTFail("Submit error: \(error)")
                }
            } catch {
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Passive Sell Offer

    func testCreatePassiveSellOffer() async {
        // Snippet: Passive Sell Offer
        let issuerKeyPair = try! KeyPair.generateRandomKeyPair()
        let traderKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(issuerKeyPair)
        await fundAccount(traderKeyPair)

        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        // Trust the asset
        let accResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            do {
                let trustOp = ChangeTrustOperation(
                    sourceAccountId: nil,
                    asset: ChangeTrustAsset(canonicalForm: usdAsset.toCanonicalForm())!,
                    limit: 10000
                )
                let transaction = try Transaction(
                    sourceAccount: account,
                    operations: [trustOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
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
            } catch {
                XCTFail("Error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
            return
        }

        // Create passive sell offer
        let traderAccResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch traderAccResponse {
        case .success(let traderAccount):
            do {
                let passiveOp = CreatePassiveSellOfferOperation(
                    sourceAccountId: nil,
                    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    buying: usdAsset,
                    amount: 100,
                    price: Price(numerator: 1, denominator: 5)  // 0.20
                )
                let transaction = try Transaction(
                    sourceAccount: traderAccount,
                    operations: [passiveOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
                let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResponse {
                case .success(let details):
                    XCTAssertTrue(details.operationCount > 0)
                case .destinationRequiresMemo(let destinationAccountId):
                    XCTFail("Destination \(destinationAccountId) requires memo")
                case .failure(let error):
                    XCTFail("Submit error: \(error)")
                }
            } catch {
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Offer Queries

    func testGetOffersForAccount() async {
        // Snippet: Get Offers for Account
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.offers.getOffers(forAccount: keyPair.accountId)
        switch response {
        case .success(let page):
            // New account has no offers; that's expected
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testGetSingleOffer() async {
        // Snippet: Get Single Offer
        // Create an offer first, then query it
        let issuerKeyPair = try! KeyPair.generateRandomKeyPair()
        let traderKeyPair = try! KeyPair.generateRandomKeyPair()

        await fundAccount(issuerKeyPair)
        await fundAccount(traderKeyPair)

        let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

        // Trust asset
        let accResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch accResponse {
        case .success(let account):
            do {
                let trustOp = ChangeTrustOperation(
                    sourceAccountId: nil,
                    asset: ChangeTrustAsset(canonicalForm: usdAsset.toCanonicalForm())!,
                    limit: 10000
                )
                let transaction = try Transaction(
                    sourceAccount: account,
                    operations: [trustOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
                let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResponse {
                case .success(_):
                    break
                case .destinationRequiresMemo(_):
                    XCTFail("Destination requires memo")
                    return
                case .failure(let error):
                    XCTFail("Submit error: \(error)")
                    return
                }
            } catch {
                XCTFail("Error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
            return
        }

        // Place a sell offer
        let traderAccResponse = await sdk.accounts.getAccountDetails(accountId: traderKeyPair.accountId)
        switch traderAccResponse {
        case .success(let traderAccount):
            do {
                let sellOp = ManageSellOfferOperation(
                    sourceAccountId: nil,
                    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    buying: usdAsset,
                    amount: 50,
                    price: Price(numerator: 1, denominator: 5),
                    offerId: 0
                )
                let transaction = try Transaction(
                    sourceAccount: traderAccount,
                    operations: [sellOp],
                    memo: Memo.none
                )
                try transaction.sign(keyPair: traderKeyPair, network: Network.testnet)
                let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResponse {
                case .success(_):
                    break
                case .destinationRequiresMemo(_):
                    XCTFail("Destination requires memo")
                    return
                case .failure(let error):
                    XCTFail("Submit error: \(error)")
                    return
                }
            } catch {
                XCTFail("Error: \(error)")
                return
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
            return
        }

        // Query offers for account
        let offersResponse = await sdk.offers.getOffers(forAccount: traderKeyPair.accountId)
        switch offersResponse {
        case .success(let page):
            guard let firstOffer = page.records.first else {
                XCTFail("No offers found")
                return
            }

            // Query the specific offer by ID
            let offerResponse = await sdk.offers.getOfferDetails(offerId: firstOffer.id)
            switch offerResponse {
            case .success(let offer):
                XCTAssertEqual(offer.id, firstOffer.id)
                XCTAssertFalse(offer.amount.isEmpty)
                XCTAssertFalse(offer.price.isEmpty)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Order Book Queries

    func testOrderBookQuery() async {
        // Snippet: Order Book Query
        let response = await sdk.orderbooks.getOrderbook(
            sellingAssetType: AssetTypeAsString.NATIVE,
            buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            limit: 10
        )
        switch response {
        case .success(let orderbook):
            XCTAssertNotNil(orderbook.bids)
            XCTAssertNotNil(orderbook.asks)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    // MARK: - Trade Queries

    func testTradesForAccount() async {
        // Snippet: Trades for Account
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.trades.getTrades(forAccount: keyPair.accountId)
        switch response {
        case .success(let page):
            // New account likely has no trades
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testTradesByAssetPair() async {
        // Snippet: Trades by Asset Pair
        let response = await sdk.trades.getTrades(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            limit: 10
        )
        switch response {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            // 404 notFound is acceptable: the asset pair may have no trading history on testnet.
            // The test validates the API call pattern, not that data exists.
            if case .notFound = error {
                break
            }
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Trade Aggregations

    func testTradeAggregations() async {
        // Snippet: Trade Aggregations (OHLCV)
        let oneDayAgo = Int64(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
        let now = Int64(Date().timeIntervalSince1970 * 1000)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            startTime: oneDayAgo,
            endTime: now,
            resolution: 3600000,  // 1 hour in milliseconds
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            limit: 24
        )
        switch response {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            // 404 notFound is acceptable: the asset pair may have no aggregation data on testnet.
            // The test validates the API call pattern, not that data exists.
            if case .notFound = error {
                break
            }
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Payment Path Queries

    func testStrictSendPaths() async {
        // Snippet: Strict Send Paths
        let response = await sdk.paymentPaths.strictSend(
            sourceAmount: "10",
            sourceAssetType: AssetTypeAsString.NATIVE,
            sourceAssetCode: nil,
            sourceAssetIssuer: nil,
            destinationAssets: "USD:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        )
        switch response {
        case .success(let paths):
            XCTAssertNotNil(paths.records)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }

    func testStrictReceivePaths() async {
        // Snippet: Strict Receive Paths
        let keyPair = try! KeyPair.generateRandomKeyPair()
        await fundAccount(keyPair)

        let response = await sdk.paymentPaths.strictReceive(
            sourceAccount: keyPair.accountId,
            sourceAssets: nil,
            destinationAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            destinationAssetCode: "USD",
            destinationAssetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            destinationAmount: "10"
        )
        switch response {
        case .success(let paths):
            XCTAssertNotNil(paths.records)
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }
}
