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
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

        let testAccountId = sellerKeyPair.accountId
        let issuingAccountId = IOMIssuerKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let createAccountOp = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: buyerKeyPair.accountId, startBalance: 100)
        let changeTrustOp1 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)
        let changeTrustOp2 = ChangeTrustOperation(sourceAccountId:buyerKeyPair.accountId, asset:IOMAsset, limit: 100000000)
        let paymentOp = try! PaymentOperation(sourceAccountId: issuingAccountId, destinationAccountId: testAccountId, asset: IOMAsset, amount: 10000.0)

        
        sdk.accounts.createTestAccount(accountId: testAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: issuingAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.getAccountDetails(accountId: testAccountId) { (response) -> (Void) in
                            switch response {
                            case .success(let accountResponse):
                                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                                   operations: [createAccountOp, changeTrustOp1, changeTrustOp2, paymentOp],
                                                                  memo: Memo.none)
                                try! transaction.sign(keyPair: self.sellerKeyPair, network: Network.testnet)
                                try! transaction.sign(keyPair: self.IOMIssuerKeyPair, network: Network.testnet)
                                try! transaction.sign(keyPair: self.buyerKeyPair, network: Network.testnet)
                                
                                try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                    switch response {
                                    case .success(let response):
                                        print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                                        expectation.fulfill()
                                    default:
                                        XCTFail()
                                    }
                                }
                            case .failure(_):
                                XCTFail()
                            }
                        }
                    case .failure(_):
                        XCTFail()
                    }
                }
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 40.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testAll() {
        createSellOffers()
        createBuyOffers()
        getTradesForAccount()
        getTrades()
        getTradeAggregations()
    }
    
    func createSellOffers() {
        XCTContext.runActivity(named: "createSellOffers") { activity in
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
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
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("createSellOffers: Transaction successfully sent. Hash:\(response.transactionHash)")
                        case .destinationRequiresMemo(let destinationAccountId):
                            print("Destination requires memo \(destinationAccountId)")
                            XCTAssert(false)
                        case .failure(error: let error):
                            XCTAssert(false)
                            print("Transaction signing failed! Error: \(error)")
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createSellOffers", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func createBuyOffers() {
        XCTContext.runActivity(named: "createBuyOffers") { activity in
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    
                    
                    let offerOperation1 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 2), offerId: 0)
                    let offerOperation2 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 3), offerId: 0)
                    let offerOperation3 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 4), offerId: 0)
                    
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [offerOperation1, offerOperation2, offerOperation3],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("createOffers: Transaction successfully sent. Hash:\(response.transactionHash)")
                        case .destinationRequiresMemo(let destinationAccountId):
                            print("Destination requires memo \(destinationAccountId)")
                            XCTAssert(false)
                        case .failure(error: let error):
                            XCTAssert(false)
                            print("Transaction signing failed! Error: \(error)")
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createOffers", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getTradesForAccount() {
        XCTContext.runActivity(named: "getTradesForAccount") { activity in
            let expectation = XCTestExpectation(description: "Get trades response for account")
            sdk.trades.getTrades(forAccount:  buyerKeyPair.accountId, from: nil, order: nil, limit: nil) { (response) -> (Void) in
                switch response {
                case .success(let tradesResponse):
                    XCTAssertTrue(tradesResponse.records.count == 3)
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTradesForAccount", horizonRequestError: error)
                    XCTAssert(false)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getTrades() {
        XCTContext.runActivity(named: "getTrades") { activity in
            let expectation = XCTestExpectation(description: "Get trades response")
            
            sdk.trades.getTrades(limit: 10) { (response) -> (Void) in
                switch response {
                case .success(let tradesResponse):
                    XCTAssertFalse(tradesResponse.records.isEmpty)
                    
                    // load next page
                    tradesResponse.getNextPage(){ (response) -> (Void) in
                        switch response {
                        case .success(let nextTradesResponse):
                            // load previous page, should contain the same trades as the first page
                            nextTradesResponse.getPreviousPage(){ (response) -> (Void) in
                                switch response {
                                case .success(let prevTradesResponse):
                                    let trade1 = tradesResponse.records.first
                                    let trade2 = prevTradesResponse.records.last // because ordering is asc now.
                                    XCTAssertTrue(trade1?.baseAccount == trade2?.baseAccount)
                                    XCTAssertTrue(trade1?.baseAmount == trade2?.baseAmount)
                                    XCTAssertTrue(trade1?.baseAssetType == trade2?.baseAssetType)
                                    if (trade1?.baseAssetType != AssetTypeAsString.NATIVE) {
                                        XCTAssertTrue(trade1?.baseAssetCode == trade2?.baseAssetCode)
                                        XCTAssertTrue(trade1?.baseAssetIssuer == trade2?.baseAssetIssuer)
                                    }
                                    XCTAssertTrue(trade1?.counterAccount == trade2?.counterAccount)
                                    XCTAssertTrue(trade1?.counterAmount == trade2?.counterAmount)
                                    XCTAssertTrue(trade1?.counterAssetType == trade2?.counterAssetType)
                                    if (trade1?.counterAssetType != AssetTypeAsString.NATIVE) {
                                        XCTAssertTrue(trade1?.counterAssetCode == trade2?.counterAssetCode)
                                        XCTAssertTrue(trade1?.counterAssetIssuer == trade2?.counterAssetIssuer)
                                    }
                                    XCTAssert(true)
                                    expectation.fulfill()
                                case .failure(let error):
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                                    XCTAssert(false)
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                            XCTAssert(false)
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                    XCTAssert(false)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getTradeAggregations() {
        XCTContext.runActivity(named: "getTradeAggregations") { activity in
            let expectation = XCTestExpectation(description: "Get trade aggregations response")
            
            sdk.tradeAggregations.getTradeAggregations(resolution: 86400000, baseAssetType: AssetTypeAsString.NATIVE, counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4, counterAssetCode: "IOM", counterAssetIssuer: IOMIssuerKeyPair.accountId, order: Order.ascending, limit: 10) { (response) -> (Void) in
                switch response {
                case .success(let tradeAggregationsResponse):
                    XCTAssertFalse(tradeAggregationsResponse.records.isEmpty)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTradeAggregations", horizonRequestError: error)
                    XCTAssert(false)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
}
