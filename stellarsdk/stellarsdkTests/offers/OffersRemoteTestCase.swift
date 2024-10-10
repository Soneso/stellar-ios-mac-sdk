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
    
    override func setUp()  async throws {
        try await super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

        let testAccountId = sellerKeyPair.accountId
        let issuingAccountId = IOMIssuerKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let createAccountOp1 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: sponsorKeyPair.accountId, startBalance: 100)
        let createAccountOp2 = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: buyerKeyPair.accountId, startBalance: 100)
        let changeTrustOp1 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)
        let changeTrustOp2 = ChangeTrustOperation(sourceAccountId:buyerKeyPair.accountId, asset:IOMAsset, limit: 100000000)
        let paymentOp = try! PaymentOperation(sourceAccountId: issuingAccountId, destinationAccountId: testAccountId, asset: IOMAsset, amount: 10000.0)

        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create issuing account: \(testAccountId)")
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
                                               operations: [createAccountOp1, createAccountOp2, changeTrustOp1, changeTrustOp2, paymentOp],
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
        await loadOffersForAccount()
        await loadOffersForSeller()
        await loadOfferById()
        await sponsorOffers()
        await loadOffersForSponsor()
        await loadOffersForSellingAsset()
        await createBuyOffers()
        await loadOffersForBuyingAsset()
        await getOrderbook()
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

    func loadOffersForAccount() async {
        
        let offersResponseEnum = await sdk.offers.getOffers(forAccount: sellerKeyPair.accountId)
        switch offersResponseEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    XCTAssertTrue(page.records.count > 0)
                    XCTAssertTrue(firstPage.records.count > 0)
                    let offer1 = firstPage.records.first!
                    let offer2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(offer1.id == offer2.id)
                    XCTAssertTrue(offer1.pagingToken == offer2.pagingToken)
                    XCTAssertTrue(offer1.seller == offer2.seller)
                    XCTAssertTrue(offer1.buying.assetType == offer2.buying.assetType)
                    XCTAssertTrue(offer1.selling.assetType == offer2.selling.assetType)
                    XCTAssertTrue(offer1.amount == offer2.amount)
                    XCTAssertTrue(offer1.price == offer2.price)
                    XCTAssertTrue(offer1.priceR.numerator == offer2.priceR.numerator)
                    XCTAssertTrue(offer1.priceR.denominator == offer2.priceR.denominator)
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
    
    func loadOffersForSeller() async {
        let response = await sdk.offers.getOffers(seller: sellerKeyPair.accountId, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: IOMIssuerKeyPair.accountId, buyingAssetType: "native")
        switch response {
        case .success(let offersResponse):
            let offer = offersResponse.records.first
            XCTAssertNotNil(offer)
            self.offerId = offer!.id
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForSeller", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func loadOfferById() async {
        
        let response = await sdk.offers.getOfferDetails(offerId: self.offerId!)
        switch response {
        case .success(let offerResponse):
            XCTAssertEqual(offerResponse.id, self.offerId!)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOfferById", horizonRequestError: error)
            XCTFail()
        }
        
    }
    
    func sponsorOffers() async {
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
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
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
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorOffers()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorOffers()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }

    func loadOffersForSponsor() async {
        let response = await sdk.offers.getOffers(seller: sellerKeyPair.accountId, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: IOMIssuerKeyPair.accountId, buyingAssetType: "native", sponsor: sponsorKeyPair.accountId)
        
        switch response {
        case .success(let offersResponse):
            let offer = offersResponse.records.first
            XCTAssertNotNil(offer)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForSponsor", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func loadOffersForSellingAsset() async {
        let response = await sdk.offers.getOffers(seller:nil, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: IOMIssuerKeyPair.accountId, buyingAssetType: "native")
        
        switch response {
        case .success(let offersResponse):
            let offer = offersResponse.records.first
            XCTAssertNotNil(offer)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForSellingAsset", horizonRequestError: error)
            XCTFail()
        }
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
                    print("createBuyOffers stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            
            
            let offerOperation1 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 7), offerId: 0)
            let offerOperation2 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 8), offerId: 0)
            let offerOperation3 = ManageBuyOfferOperation(sourceAccountId: self.buyerKeyPair.accountId, selling: self.assetNative!, buying: IOM, amount: 100, price: Price(numerator: 1, denominator: 9), offerId: 0)
            
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
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createBuyOffers()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createBuyOffers()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }
    
    func loadOffersForBuyingAsset() async {
        let response = await sdk.offers.getOffers(seller:nil, sellingAssetType: "native", buyingAssetType:"credit_alphanum4", buyingAssetCode: "IOM", buyingAssetIssuer: IOMIssuerKeyPair.accountId)
        
        switch response {
        case .success(let offersResponse):
            let offer = offersResponse.records.first
            XCTAssertNotNil(offer)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"loadOffersForBuyingAsset", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getOrderbook() async {
        let response = await sdk.orderbooks.getOrderbook(sellingAssetType: AssetTypeAsString.NATIVE, buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4, buyingAssetCode:"IOM", buyingAssetIssuer:IOMIssuerKeyPair.accountId, limit:10)
        
        switch response {
        case .success(let orderbookResponse):
            XCTAssertFalse(orderbookResponse.bids.isEmpty)
            XCTAssertFalse(orderbookResponse.asks.isEmpty)
            
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOB Test", horizonRequestError: error)
            XCTFail()
        }
    }
}
