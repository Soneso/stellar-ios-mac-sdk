//
//  EffectsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 05/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class EffectsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    var transactionHash:String? = nil
    var ledger:Int? = nil
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

        let testAccountId = testKeyPair.accountId
        let manageDataOp = ManageDataOperation(sourceAccountId: testAccountId, name: "soneso", data: "is super".data(using: .utf8))

        self.sdk.accounts.createTestAccount(accountId: testAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.getAccountDetails(accountId: testAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [manageDataOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                            self.transactionHash = response.transactionHash
                            self.ledger = response.ledger
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
        wait(for: [expectation], timeout: 25.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() {
        getEffects()
        getEffectsForAccount()
        getEffectsForOperation()
        getEffectsForLedger()
        getEffectsForTransaction()
    }
        
    
    func getEffects() {
        XCTContext.runActivity(named: "getEffects") { activity in
            let expectation = XCTestExpectation(description: "Get effects and parse their details successfully")
            
            sdk.effects.getEffects { (response) -> (Void) in
                switch response {
                case .success(let effectsResponse):
                    // load next page
                    effectsResponse.getNextPage(){ (response) -> (Void) in
                        switch response {
                        case .success(let nextEffectsResponse):
                            // load previous page, should contain the same effects as the first page
                            nextEffectsResponse.getPreviousPage(){ (response) -> (Void) in
                                switch response {
                                case .success(let prevEffectsResponse):
                                    let effect1 = effectsResponse.records.first
                                    let effect2 = prevEffectsResponse.records.last // because ordering is asc now.
                                    XCTAssertTrue(effect1?.id == effect2?.id)
                                    XCTAssertTrue(effect1?.account == effect2?.account)
                                    XCTAssertTrue(effect1?.effectType == effect2?.effectType)
                                    XCTAssertTrue(effect1?.effectTypeString == effect2?.effectTypeString)
                                    XCTAssert(true)
                                    expectation.fulfill()
                                case .failure(let error):
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
                                    XCTAssert(false)
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
                            XCTAssert(false)
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getEffectsForAccount() {
        XCTContext.runActivity(named: "getEffectsForAccount") { activity in
            let expectation = XCTestExpectation(description: "Get effects for account and parse their details successfuly")
            
            sdk.effects.getEffects(forAccount: testKeyPair.accountId, order:Order.descending) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GEFA Test", horizonRequestError: error)
                    XCTAssert(false)
                }
                
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getEffectsForOperation() {
        XCTContext.runActivity(named: "getEffectsForOperation") { activity in
            let expectation = XCTestExpectation(description: "Get effects for operation")
            sdk.operations.getOperations(forAccount: testKeyPair.accountId, from: nil, order: Order.descending, includeFailed: true, join: "transactions") { (response) -> (Void) in
                switch response {
                case .success(let operations):
                    XCTAssertNotNil(operations.records.first)
                    if let operation = operations.records.first {
                        self.sdk.effects.getEffects(forOperation: operation.id) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForOperation", horizonRequestError: error)
                                XCTAssert(false)
                            }
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForOperation", horizonRequestError: error)
                    XCTAssert(false)
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getEffectsForLedger() {
        XCTContext.runActivity(named: "getEffectsForLedger") { activity in
            let expectation = XCTestExpectation(description: "Get effects for ledger")
            
            sdk.effects.getEffects(forLedger: String(self.ledger!)) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForLedger", horizonRequestError: error)
                    XCTAssert(false)
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getEffectsForTransaction() {
        XCTContext.runActivity(named: "getEffectsForTransaction") { activity in
            let expectation = XCTestExpectation(description: "Get effects for transaction")
            
            sdk.effects.getEffects(forTransaction: self.transactionHash!) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForTransaction", horizonRequestError: error)
                    XCTAssert(false)
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
}
