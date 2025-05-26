//
//  TradesTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TradesTestCase: XCTestCase {
    let sdk = StellarSDK()
    let network = Network.testnet
    let sellerKeyPair = try! KeyPair.generateRandomKeyPair()
    let IOMIssuerKeyPair = try! KeyPair.generateRandomKeyPair()
    var operationsStreamItem:OperationsStreamItem? = nil
    let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
    let buyerKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp() async throws {
        try await super.setUp()

        let testAccountId = sellerKeyPair.accountId
        let issuingAccountId = IOMIssuerKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let createAccountOp = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: buyerKeyPair.accountId, startBalance: 100)
        let changeTrustOp1 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)
        let changeTrustOp2 = ChangeTrustOperation(sourceAccountId:buyerKeyPair.accountId, asset:IOMAsset, limit: 100000000)
        let paymentOp = try! PaymentOperation(sourceAccountId: issuingAccountId, destinationAccountId: testAccountId, asset: IOMAsset, amount: 10000.0)

        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: issuingAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create issuing account: \(issuingAccountId)")
        }
        
        let accDetailsResEnum = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                               operations: [createAccountOp, changeTrustOp1, changeTrustOp2, paymentOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.sellerKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.IOMIssuerKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.buyerKeyPair, network: Network.testnet)
            
            let submitTxResponse = await self.sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func testAll() async {
        await createSellOffers()
        await createBuyOffers()
        await getTradesForAccount()
        await getTrades()
        await getTradeAggregations()
    }
    
    func createSellOffers() async {
        let expectation = XCTestExpectation(description: "offers created")
        
        let sourceAccountKeyPair = sellerKeyPair
        let IOM = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
        
        operationsStreamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
        operationsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let _ = operationResponse as?  ManageSellOfferOperationResponse {
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createOffers Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("createSellOffers stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            
            
            let offerOperation1 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 1, denominator: 2), offerId: 0)
            let offerOperation2 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 1, denominator: 3), offerId: 0)
            let offerOperation3 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 1, denominator: 4), offerId: 0)
            let offerOperation4 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 1, denominator: 5), offerId: 0)
            let offerOperation5 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 1, denominator: 6), offerId: 0)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [offerOperation1, offerOperation2, offerOperation3, offerOperation4, offerOperation5],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createSellOffers()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createSellOffers()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func createBuyOffers() async {
        let expectation = XCTestExpectation(description: "offers created")
        
        let sourceAccountKeyPair = buyerKeyPair
        let IOM = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
        
        operationsStreamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
        operationsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let _ = operationResponse as?  ManageBuyOfferOperationResponse {
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createOffers Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("createOffers stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            
            
            let offerOperation1 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 2), offerId: 0)
            let offerOperation2 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 3), offerId: 0)
            let offerOperation3 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 4), offerId: 0)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [offerOperation1, offerOperation2, offerOperation3],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createSellOffers()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createSellOffers()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func getTradesForAccount() async {
        let response = await sdk.trades.getTrades(forAccount:  buyerKeyPair.accountId, from: nil, order: nil, limit: nil)
        switch response {
        case .success(let tradesResponse):
            XCTAssertTrue(tradesResponse.records.count == 3)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTradesForAccount", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getTrades() async {
        
        let tradesResponseEnum = await sdk.trades.getTrades(limit: 10)
        switch tradesResponseEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    XCTAssertTrue(page.records.count > 0)
                    XCTAssertTrue(firstPage.records.count > 0)
                    let trade1 = firstPage.records.first!
                    let trade2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(trade1.baseAccount == trade2.baseAccount)
                    XCTAssertTrue(trade1.baseAmount == trade2.baseAmount)
                    XCTAssertTrue(trade1.baseAssetType == trade2.baseAssetType)
                    if (trade1.baseAssetType != AssetTypeAsString.NATIVE) {
                        XCTAssertTrue(trade1.baseAssetCode == trade2.baseAssetCode)
                        XCTAssertTrue(trade1.baseAssetIssuer == trade2.baseAssetIssuer)
                    }
                    XCTAssertTrue(trade1.counterAccount == trade2.counterAccount)
                    XCTAssertTrue(trade1.counterAmount == trade2.counterAmount)
                    XCTAssertTrue(trade1.counterAssetType == trade2.counterAssetType)
                    if (trade1.counterAssetType != AssetTypeAsString.NATIVE) {
                        XCTAssertTrue(trade1.counterAssetCode == trade2.counterAssetCode)
                        XCTAssertTrue(trade1.counterAssetIssuer == trade2.counterAssetIssuer)
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
                    XCTFail("failed to load prev page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
                XCTFail("failed to load next page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
            XCTFail("failed to load transactions")
        }
    }
    
    func getTradeAggregations() async {
        let response = await sdk.tradeAggregations.getTradeAggregations(resolution: 86400000, baseAssetType: AssetTypeAsString.NATIVE, counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4, counterAssetCode: "IOM", counterAssetIssuer: IOMIssuerKeyPair.accountId, order: Order.ascending, limit: 10)
        
        switch response {
        case .success(let tradeAggregationsResponse):
            XCTAssertFalse(tradeAggregationsResponse.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTradeAggregations", horizonRequestError: error)
            XCTFail()
        }
    }
    
}
