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
    let source = "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N" //IOM holder
    let sourceSeed = "SD24I54ZUAYGZCKVQD6DZD6PQGLU7UQKVWDM37TKIACO3P47WG3BRW4C"
    let destination = "GAQC6DUD2OVIYV3DTBPOSLSSOJGE4YJZHEGQXOU4GV6T7RABWZXELCUT" //EUR holder
    let IOMIssuer = "GAHVPXP7RPX5EGT6WFDS26AOM3SBZW2RKEDBZ5VO45J7NYDGJYKYE6UW"
    let EURIssuer = "GA3IZ2KWEY3VNBWHOKY3VEGHGL2G4G2E2QK2RDQ76IK2PLJFITN6MYFF"
    let seller = "GCGBBRSKBPIQHGOPA5T637SQYHVGTKTIF6DUYZS34NLOUZNHI7JYBUNA" // holds IOM & EUR, sells EUR for IOM
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFindPaymentPaths() {
        let expectation = XCTestExpectation(description: "Find payment paths")
        
        sdk.paymentPaths.findPaymentPaths(destinationAccount:destination, destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer:EURIssuer, destinationAmount:"20", sourceAccount:source) { (response) -> (Void) in
            switch response {
            case .success(let findPaymentPathsResponse):
                
                for paymentPath in findPaymentPathsResponse.records {
                    print("FPP Test: \(paymentPath.destinationAmount) is the destination amount")
                    print("FPP Test: \(paymentPath.sourceAmount) is the source amount")
                }

                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"FPP Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStrictReceive() {
        let expectation = XCTestExpectation(description: "strict receive")
        
        sdk.paymentPaths.strictReceive(sourceAccount:source, sourceAssets:nil, destinationAccount: destination, destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer: EURIssuer, destinationAmount: "20") { (response) -> (Void) in
            switch response {
            case .success(let strictReceiveResponse):
                XCTAssert(strictReceiveResponse.records.count > 0)
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Strict receive Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStrictSend() {
        let expectation = XCTestExpectation(description: "strict send")
        
        sdk.paymentPaths.strictSend(sourceAmount:"10", sourceAssetType:"credit_alphanum4",sourceAssetCode:"IOM", sourceAssetIssuer:IOMIssuer, destinationAssets:"EUR:" + EURIssuer) { (response) -> (Void) in
            switch response {
            case .success(let strictSendResponse):
                XCTAssert(strictSendResponse.records.count > 0)
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Strict send Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStrictSendPayment() {
        
        let expectation = XCTestExpectation(description: "Non native payment successfully sent with strict send")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:sourceSeed)
            let IOMIssuerKP = try KeyPair(accountId:IOMIssuer)
            let EURIssuerKP = try KeyPair(accountId:EURIssuer)
            
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: IOMIssuerKP)
            let EUR = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: EURIssuerKP)
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                    
                        let muxDestination = try MuxedAccount(accountId:self.destination, id: 12345)
                        print ("Muxed destination account id: \(muxDestination.accountId)")
                        
                        let muxSource = try MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 6789)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let paymentOperation = try PathPaymentStrictSendOperation(sourceAccountId: muxSource.accountId, sendAsset: IOM!, sendMax: 20, destinationAccountId: muxDestination.accountId, destAsset: EUR!, destAmount: 18, path: [IOM!, EUR!])
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("StrictSendPayment Test: Transaction successfully sent. Hash: \(response.transactionHash)")
                                expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("StrictSendPayment Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"StrictSendPayment Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"StrictSendPayment Test", horizonRequestError:error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStrictReceivePayment() {
        
        let expectation = XCTestExpectation(description: "Non native payment successfully sent with strict receive")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:sourceSeed)
            
            let IOMIssuerKP = try KeyPair(accountId:IOMIssuer)
            let EURIssuerKP = try KeyPair(accountId:EURIssuer)
            
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: IOMIssuerKP)
            let EUR = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: EURIssuerKP)
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let muxDestination = try MuxedAccount(accountId:self.destination, id: 12345)
                        print ("Muxed destination account id: \(muxDestination.accountId)")
                        
                        let muxSource = try MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 6789)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let paymentOperation = try PathPaymentStrictReceiveOperation(sourceAccountId: muxSource.accountId, sendAsset: IOM!, sendMax: 20, destinationAccountId: muxDestination.accountId, destAsset: EUR!, destAmount: 18, path: [IOM!, EUR!])
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("StrictReceivePayment Test: Transaction successfully sent. Hash: \(response.transactionHash)")
                                expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("StrictReceivePayment Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"StrictReceivePayment Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"StrictReceivePayment Test", horizonRequestError:error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
