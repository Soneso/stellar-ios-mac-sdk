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
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

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
        
        self.sdk.accounts.createTestAccount(accountId: sourceAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.getAccountDetails(accountId: sourceAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [createAccOp1, createAccOp2, createAccOp3, createAccOp4,
                                                                   chTrustOp1, chTrustOp2, chTrustOp3, chTrustOp4],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: self.sourceKeyPair, network: Network.testnet)
                    try! transaction.sign(keyPair: self.destinationKeyPair, network: Network.testnet)
                    try! transaction.sign(keyPair: self.sellerKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                            expectation.fulfill()
                        default:
                            XCTFail()
                            expectation.fulfill()
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
        distributeAssets()
        createOffer()
        findPaymentPaths()
        strictReceive()
        strictSend()
        strictSendPayment()
        strictReceivePayment()
    }
    
    func distributeAssets() {
        XCTContext.runActivity(named: "distributeAssets") { activity in
            let expectation = XCTestExpectation(description: "assets distributed")
            let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
            let EURAsset = ChangeTrustAsset(canonicalForm: "EUR:" + EURIssuerKeyPair.accountId)!
            let payOp1 = try! PaymentOperation(sourceAccountId: IOMIssuerKeyPair.accountId, destinationAccountId: sourceKeyPair.accountId, asset: IOMAsset, amount: 8000)
            let payOp2 = try! PaymentOperation(sourceAccountId: IOMIssuerKeyPair.accountId, destinationAccountId: sellerKeyPair.accountId, asset: IOMAsset, amount: 8000)
            let payOp3 = try! PaymentOperation(sourceAccountId: EURIssuerKeyPair.accountId, destinationAccountId: destinationKeyPair.accountId, asset: EURAsset, amount: 8000)
            let payOp4 = try! PaymentOperation(sourceAccountId: EURIssuerKeyPair.accountId, destinationAccountId: sellerKeyPair.accountId, asset: EURAsset, amount: 8000)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // wait for ledger to close
                self.sdk.accounts.getAccountDetails(accountId: self.IOMIssuerKeyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountResponse):
                        let transaction = try! Transaction(sourceAccount: accountResponse,
                                                          operations: [payOp1, payOp2, payOp3, payOp4],
                                                          memo: Memo.none)
                        try! transaction.sign(keyPair: self.IOMIssuerKeyPair, network: Network.testnet)
                        try! transaction.sign(keyPair: self.EURIssuerKeyPair, network: Network.testnet)
                        try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("distributeAssets: Transaction successfully sent. Hash:\(response.transactionHash)")
                                expectation.fulfill()
                            default:
                                XCTFail()
                                expectation.fulfill()
                            }
                        }
                    case .failure(_):
                        XCTFail()
                    }
                }
            }
            wait(for: [expectation], timeout: 25.0)
        }
    }
    
    func createOffer() {
        XCTContext.runActivity(named: "createOffer") { activity in
            let expectation = XCTestExpectation(description: "offer created")
            let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + IOMIssuerKeyPair.accountId)!
            let EURAsset = ChangeTrustAsset(canonicalForm: "EUR:" + EURIssuerKeyPair.accountId)!
            let offerOp1 = ManageOfferOperation(sourceAccountId: sellerKeyPair.accountId, selling: EURAsset, buying: IOMAsset, amount: 1000, price: Price.fromString(price: "1.0"), offerId: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // wait for ledger to close
                self.sdk.accounts.getAccountDetails(accountId: self.sellerKeyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountResponse):
                        let transaction = try! Transaction(sourceAccount: accountResponse,
                                                          operations: [offerOp1],
                                                          memo: Memo.none)
                        try! transaction.sign(keyPair: self.sellerKeyPair, network: Network.testnet)
                        try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("createOffer: Transaction successfully sent. Hash:\(response.transactionHash)")
                                expectation.fulfill()
                            default:
                                XCTFail()
                                expectation.fulfill()
                            }
                        }
                    case .failure(_):
                        XCTFail()
                    }
                }
            }
            wait(for: [expectation], timeout: 25.0)
        }
    }
    
    func findPaymentPaths() {
        XCTContext.runActivity(named: "findPaymentPaths") { activity in
            let expectation = XCTestExpectation(description: "Find payment paths")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // wait for ledger to close
                self.sdk.paymentPaths.findPaymentPaths(destinationAccount:self.destinationKeyPair.accountId, destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer:self.EURIssuerKeyPair.accountId, destinationAmount:"20", sourceAccount:self.sourceKeyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let findPaymentPathsResponse):
                        
                        XCTAssert(findPaymentPathsResponse.records.count > 0)
                        
                        for paymentPath in findPaymentPathsResponse.records {
                            print("findPaymentPaths: \(paymentPath.destinationAmount) is the destination amount")
                            print("findPaymentPaths: \(paymentPath.sourceAmount) is the source amount")
                        }

                        XCTAssert(true)
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"findPaymentPaths", horizonRequestError: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            }
        wait(for: [expectation], timeout: 15.0)
        }
    }

    func strictReceive() {
        XCTContext.runActivity(named: "strictReceive") { activity in
            let expectation = XCTestExpectation(description: "strict receive")
            
            sdk.paymentPaths.strictReceive(sourceAccount:sourceKeyPair.accountId, sourceAssets:nil, destinationAccount: destinationKeyPair.accountId, destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer: EURIssuerKeyPair.accountId, destinationAmount: "20") { (response) -> (Void) in
                switch response {
                case .success(let strictReceiveResponse):
                    XCTAssert(strictReceiveResponse.records.count > 0)
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Strict receive Test", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
 
    func strictSend() {
        XCTContext.runActivity(named: "strictSend") { activity in
            let expectation = XCTestExpectation(description: "strict send")
            
            sdk.paymentPaths.strictSend(sourceAmount:"10", sourceAssetType:"credit_alphanum4",sourceAssetCode:"IOM", sourceAssetIssuer:IOMIssuerKeyPair.accountId, destinationAssets:"EUR:" + EURIssuerKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let strictSendResponse):
                    XCTAssert(strictSendResponse.records.count > 0)
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Strict send Test", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func strictSendPayment() {
        XCTContext.runActivity(named: "strictSendPayment") { activity in
            let expectation = XCTestExpectation(description: "Non native payment successfully sent with strict send")
            let sourceAccountKeyPair = sourceKeyPair
            let IOMIssuerKP = IOMIssuerKeyPair
            let EURIssuerKP = EURIssuerKeyPair
            
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: IOMIssuerKP)
            let EUR = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: EURIssuerKP)
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxDestination = try! MuxedAccount(accountId:self.destinationKeyPair.accountId, id: 12345)
                    let muxSource = try! MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 6789)
                    
                    let paymentOperation = try! PathPaymentStrictSendOperation(sourceAccountId: muxSource.accountId, sendAsset: IOM!, sendMax: 20, destinationAccountId: muxDestination.accountId, destAsset: EUR!, destAmount: 18, path: [IOM!, EUR!])
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [paymentOperation],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("strictSendPayment: Transaction successfully sent. Hash: \(response.transactionHash)")
                            expectation.fulfill()
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"StrictSendPayment Test", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
   
    func strictReceivePayment() {
        XCTContext.runActivity(named: "strictReceivePayment") { activity in
            let expectation = XCTestExpectation(description: "Non native payment successfully sent with strict receive")
    
            let sourceAccountKeyPair = sourceKeyPair
            
            let IOMIssuerKP = IOMIssuerKeyPair
            let EURIssuerKP = EURIssuerKeyPair
            
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: IOMIssuerKP)
            let EUR = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: EURIssuerKP)
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxDestination = try! MuxedAccount(accountId:self.destinationKeyPair.accountId, id: 12345)
                    let muxSource = try! MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 6789)
                    
                    let paymentOperation = try! PathPaymentStrictReceiveOperation(sourceAccountId: muxSource.accountId, sendAsset: IOM!, sendMax: 20, destinationAccountId: muxDestination.accountId, destAsset: EUR!, destAmount: 18, path: [IOM!, EUR!])
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [paymentOperation],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("strictReceivePayment: Transaction successfully sent. Hash: \(response.transactionHash)")
                            expectation.fulfill()
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"StrictReceivePayment Test", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
}
