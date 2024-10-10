//
//  PaymentPathsTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/14/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PaymentPathsTestCase: XCTestCase {
    let sdk = StellarSDK()    
    let sourceKeyPair = try! KeyPair.generateRandomKeyPair() // IOM holder
    let destinationKeyPair = try! KeyPair.generateRandomKeyPair() // EUR holder
    let IOMIssuerKeyPair = try! KeyPair.generateRandomKeyPair()
    let EURIssuerKeyPair = try! KeyPair.generateRandomKeyPair()
    let sellerKeyPair = try! KeyPair.generateRandomKeyPair() // holds IOM & EUR, sells EUR for IOM
    
    override func setUp() async throws {
        try await super.setUp()

        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
        let EURAsset = ChangeTrustAsset(canonicalForm: "EUR:" + EURIssuerKeyPair.accountId)!
        
        let sourceAccountId = sourceKeyPair.accountId
        let createAccOp1 = CreateAccountOperation(sourceAccountId: sourceAccountId, destination:destinationKeyPair, startBalance: 100)
        let createAccOp2 = CreateAccountOperation(sourceAccountId: sourceAccountId, destination:IOMIssuerKeyPair, startBalance: 100)
        let createAccOp3 = CreateAccountOperation(sourceAccountId: sourceAccountId, destination:EURIssuerKeyPair, startBalance: 100)
        let createAccOp4 = CreateAccountOperation(sourceAccountId: sourceAccountId, destination:sellerKeyPair, startBalance: 100)
        let chTrustOp1 = ChangeTrustOperation(sourceAccountId: sourceAccountId, asset: IOMAsset, limit: 10000)
        let chTrustOp2 = ChangeTrustOperation(sourceAccountId: destinationKeyPair.accountId, asset: EURAsset, limit: 10000)
        let chTrustOp3 = ChangeTrustOperation(sourceAccountId: sellerKeyPair.accountId, asset: IOMAsset, limit: 10000)
        let chTrustOp4 = ChangeTrustOperation(sourceAccountId: sellerKeyPair.accountId, asset: EURAsset, limit: 10000)
        
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createAccOp1, createAccOp2, createAccOp3, createAccOp4,
                                                           chTrustOp1, chTrustOp2, chTrustOp3, chTrustOp4],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.sourceKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.destinationKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.sellerKeyPair, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
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
        await distributeAssets()
        await createOffer()
        try! await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
        await findPaymentPaths()
        await strictReceive()
        await strictSend()
        await strictSendPayment()
        await strictReceivePayment()
    }
    
    func distributeAssets() async {
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
        let EURAsset = ChangeTrustAsset(canonicalForm: "EUR:" + EURIssuerKeyPair.accountId)!
        let payOp1 = try! PaymentOperation(sourceAccountId: IOMIssuerKeyPair.accountId, destinationAccountId: sourceKeyPair.accountId, asset: IOMAsset, amount: 8000)
        let payOp2 = try! PaymentOperation(sourceAccountId: IOMIssuerKeyPair.accountId, destinationAccountId: sellerKeyPair.accountId, asset: IOMAsset, amount: 8000)
        let payOp3 = try! PaymentOperation(sourceAccountId: EURIssuerKeyPair.accountId, destinationAccountId: destinationKeyPair.accountId, asset: EURAsset, amount: 8000)
        let payOp4 = try! PaymentOperation(sourceAccountId: EURIssuerKeyPair.accountId, destinationAccountId: sellerKeyPair.accountId, asset: EURAsset, amount: 8000)
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: self.IOMIssuerKeyPair.accountId)
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [payOp1, payOp2, payOp3, payOp4],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.IOMIssuerKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.EURIssuerKeyPair, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"distributeAssets()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"distributeAssets()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func createOffer() async {
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
        let EURAsset = ChangeTrustAsset(canonicalForm: "EUR:" + EURIssuerKeyPair.accountId)!
        let offerOp1 = ManageOfferOperation(sourceAccountId: sellerKeyPair.accountId, selling: EURAsset, buying: IOMAsset, amount: 1000, price: Price.fromString(price: "1.0"), offerId: 0)
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sellerKeyPair.accountId)
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [offerOp1],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sellerKeyPair, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createOffer()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createOffer()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func findPaymentPaths() async {
        let response = await sdk.paymentPaths.findPaymentPaths(destinationAccount:destinationKeyPair.accountId, destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer:EURIssuerKeyPair.accountId, destinationAmount:"20", sourceAccount:sourceKeyPair.accountId)
        switch response {
        case .success(let details):
            XCTAssert(details.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"findPaymentPaths()", horizonRequestError: error)
            XCTFail()
        }
    }

    func strictReceive() async {
        let response = await sdk.paymentPaths.strictReceive(sourceAccount:sourceKeyPair.accountId, sourceAssets:nil, destinationAccount: destinationKeyPair.accountId, destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer: EURIssuerKeyPair.accountId, destinationAmount: "20")
        switch response {
        case .success(let details):
            XCTAssert(details.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"strictReceive()", horizonRequestError: error)
            XCTFail()
        }
    }
 
    func strictSend() async {
        let response = await sdk.paymentPaths.strictSend(sourceAmount:"10", sourceAssetType:"credit_alphanum4",sourceAssetCode:"IOM", sourceAssetIssuer:IOMIssuerKeyPair.accountId, destinationAssets:"EUR:" + EURIssuerKeyPair.accountId)
        switch response {
        case .success(let details):
            XCTAssert(details.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"strictSend()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func strictSendPayment() async {
        let sourceAccountKeyPair = sourceKeyPair
        let IOMIssuerKP = IOMIssuerKeyPair
        let EURIssuerKP = EURIssuerKeyPair
        
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: IOMIssuerKP)
        let EUR = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: EURIssuerKP)
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxDestination = try! MuxedAccount(accountId:self.destinationKeyPair.accountId, id: 12345)
            let muxSource = try! MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 6789)
            
            let paymentOperation = try! PathPaymentStrictSendOperation(sourceAccountId: muxSource.accountId, sendAsset: IOM!, sendMax: 20, destinationAccountId: muxDestination.accountId, destAsset: EUR!, destAmount: 18, path: [IOM!, EUR!])
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [paymentOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"strictSendPayment()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"strictSendPayment()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
   
    func strictReceivePayment() async {
        let sourceAccountKeyPair = sourceKeyPair
        
        let IOMIssuerKP = IOMIssuerKeyPair
        let EURIssuerKP = EURIssuerKeyPair
        
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: IOMIssuerKP)
        let EUR = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: EURIssuerKP)
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxDestination = try! MuxedAccount(accountId:self.destinationKeyPair.accountId, id: 12345)
            let muxSource = try! MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 6789)
            
            let paymentOperation = try! PathPaymentStrictReceiveOperation(sourceAccountId: muxSource.accountId, sendAsset: IOM!, sendMax: 20, destinationAccountId: muxDestination.accountId, destAsset: EUR!, destAmount: 18, path: [IOM!, EUR!])
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [paymentOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"strictReceivePayment()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"strictReceivePayment()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
}
