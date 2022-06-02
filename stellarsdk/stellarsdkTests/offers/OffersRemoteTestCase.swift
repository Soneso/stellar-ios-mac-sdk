//
//  OffersRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OffersRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    let network = Network.testnet
    let sellerKeyPair = try! KeyPair.generateRandomKeyPair()
    let IOMIssuerKeyPair = try! KeyPair.generateRandomKeyPair()
    var operationsStreamItem:OperationsStreamItem? = nil
    var offerId:String? = nil
    let sponsorKeyPair = try! KeyPair.generateRandomKeyPair()
    let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
    let buyerKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

        let testAccountId = sellerKeyPair.accountId
        let issuingAccountId = IOMIssuerKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let createAccountOp1 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: sponsorKeyPair.accountId, startBalance: 100)
        let createAccountOp2 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: buyerKeyPair.accountId, startBalance: 100)
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
                                                                   operations: [createAccountOp1, createAccountOp2, changeTrustOp1, changeTrustOp2, paymentOp],
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
        wait(for: [expectation], timeout: 25.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() {
        createSellOffers()
        loadOffersForAccount()
        loadOffersForSeller()
        loadOfferById()
        sponsorOffers()
        loadOffersForSponsor()
        loadOffersForSellingAsset()
        createBuyOffers()
        loadOffersForBuyingAsset()
        getOrderbook()
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

    func loadOffersForAccount() {
        XCTContext.runActivity(named: "loadOffersForAccount") { activity in
            let expectation = XCTestExpectation(description: "Get offers")
            
            sdk.offers.getOffers(forAccount: sellerKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let offersResponse):
                    // load next page
                    offersResponse.getNextPage(){ (response) -> (Void) in
                        switch response {
                        case .success(let nextOffersResponse):
                            // load previous page, should contain the same transactions as the first page
                            nextOffersResponse.getPreviousPage(){ (response) -> (Void) in
                                switch response {
                                case .success(let prevOffersResponse):
                                    let offer1 = offersResponse.records.first
                                    let offer2 = prevOffersResponse.records.last // because ordering is asc now.
                                    XCTAssertTrue(offer1?.id == offer2?.id)
                                    XCTAssertTrue(offer1?.pagingToken == offer2?.pagingToken)
                                    XCTAssertTrue(offer1?.seller == offer2?.seller)
                                    XCTAssertTrue(offer1?.buying.assetType == offer2?.buying.assetType)
                                    XCTAssertTrue(offer1?.selling.assetType == offer2?.selling.assetType)
                                    XCTAssertTrue(offer1?.amount == offer2?.amount)
                                    XCTAssertTrue(offer1?.price == offer2?.price)
                                    XCTAssertTrue(offer1?.priceR.numerator == offer2?.priceR.numerator)
                                    XCTAssertTrue(offer1?.priceR.denominator == offer2?.priceR.denominator)
                                    XCTAssert(true)
                                    expectation.fulfill()
                                case .failure(let error):
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                                    XCTAssert(false)
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                            XCTAssert(false)
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                    XCTAssert(false)
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    
    func loadOffersForSeller() {
        XCTContext.runActivity(named: "loadOffersForSeller") { activity in
            let expectation = XCTestExpectation(description: "Get offers")
            
            sdk.offers.getOffers(seller: sellerKeyPair.accountId, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: IOMIssuerKeyPair.accountId, buyingAssetType: "native") { (response) -> (Void) in
                switch response {
                case .success(let offersResponse):
                    let offer = offersResponse.records.first
                    XCTAssertNotNil(offer)
                    self.offerId = offer?.id
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForSeller", horizonRequestError: error)
                    XCTAssert(false)
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func loadOfferById() {
        XCTContext.runActivity(named: "loadOfferById") { activity in
            let expectation = XCTestExpectation(description: "Get offer")
            
            sdk.offers.getOfferDetails(offerId: self.offerId!) { (response) -> (Void) in
                switch response {
                case .success(let offerResponse):
                    XCTAssertEqual(offerResponse.id, self.offerId!)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOfferById", horizonRequestError: error)
                    XCTAssert(false)
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func sponsorOffers() {
        XCTContext.runActivity(named: "sponsorOffers") { activity in
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorOffers Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("sponsorOffers stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    
                    let beginSponsoringOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: sourceAccountKeyPair.accountId, sponsoringAccountId: self.sponsorKeyPair.accountId)
                    let offerOperation1 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 2, denominator: 3), offerId: 0)
                    let offerOperation2 = ManageSellOfferOperation(sourceAccountId: self.sellerKeyPair.accountId, selling: IOM, buying: self.assetNative!, amount: 100, price: Price(numerator: 2, denominator: 5), offerId: 0)
                    let endSponsoringOp = EndSponsoringFutureReservesOperation(sponsoredAccountId: sourceAccountKeyPair.accountId)
                    
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [beginSponsoringOp, offerOperation1, offerOperation2, endSponsoringOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    try! transaction.sign(keyPair: self.sponsorKeyPair, network: self.network)
                    
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
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorOffers", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func loadOffersForSponsor() {
        XCTContext.runActivity(named: "loadOffersForSponsor") { activity in
            let expectation = XCTestExpectation(description: "Get offers")
            
            sdk.offers.getOffers(seller: sellerKeyPair.accountId, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: IOMIssuerKeyPair.accountId, buyingAssetType: "native", sponsor: sponsorKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let offersResponse):
                    let offer = offersResponse.records.first
                    XCTAssertNotNil(offer)
                    XCTAssert(true)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForSponsor", horizonRequestError: error)
                    XCTAssert(false)
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func loadOffersForSellingAsset() {
        XCTContext.runActivity(named: "loadOffersForSellingAsset") { activity in
            let expectation = XCTestExpectation(description: "Get offers")
            
            sdk.offers.getOffers(seller:nil, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: IOMIssuerKeyPair.accountId, buyingAssetType: "native") { (response) -> (Void) in
                switch response {
                case .success(let offersResponse):
                    let offer = offersResponse.records.first
                    XCTAssertNotNil(offer)
                    XCTAssert(true)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForSellingAsset", horizonRequestError: error)
                    XCTAssert(false)
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
                    
                    
                    let offerOperation1 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 7), offerId: 0)
                    let offerOperation2 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 8), offerId: 0)
                    let offerOperation3 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 9), offerId: 0)
                    
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
    
    func loadOffersForBuyingAsset() {
        XCTContext.runActivity(named: "loadOffersForBuyingAsset") { activity in
            let expectation = XCTestExpectation(description: "Get offers")
            
            sdk.offers.getOffers(seller:nil, sellingAssetType: "native", buyingAssetType:"credit_alphanum4", buyingAssetCode: "IOM", buyingAssetIssuer: IOMIssuerKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let offersResponse):
                    let offer = offersResponse.records.first
                    XCTAssertNotNil(offer)
                    XCTAssert(true)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForBuyingAsset", horizonRequestError: error)
                    XCTAssert(false)
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOrderbook() {
        XCTContext.runActivity(named: "loadOffersForBuyingAsset") { activity in
            let expectation = XCTestExpectation(description: "Get orderbook response and parse it successfully")
            
            sdk.orderbooks.getOrderbook(sellingAssetType: AssetTypeAsString.NATIVE, buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4, buyingAssetCode:"IOM", buyingAssetIssuer:IOMIssuerKeyPair.accountId, limit:10) { (response) -> (Void) in
                switch response {
                case .success(let orderbookResponse):
                    XCTAssertFalse(orderbookResponse.bids.isEmpty)
                    XCTAssertFalse(orderbookResponse.asks.isEmpty)
                    
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOB Test", horizonRequestError: error)
                    XCTAssert(false)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
}
