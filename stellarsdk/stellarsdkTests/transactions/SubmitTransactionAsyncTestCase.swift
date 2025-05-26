//
//  SubmitTransactionAsyncTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class SubmitTransactionAsyncTestCase: XCTestCase {

    let sdk = StellarSDK()
    let accountKeyPair = try! KeyPair.generateRandomKeyPair()
    var accountResponse:AccountResponse? = nil
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sdk.accounts.createTestAccount(accountId: accountKeyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.getAccountDetails(accountId: self.accountKeyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountResponse):
                        self.accountResponse = accountResponse
                        expectation.fulfill()
                    case .failure(_):
                        XCTFail()
                    }
                }
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAll() {
        pendingAndDuplicate();
        statusError()
        malformed()
    }
    
    func pendingAndDuplicate() {
        XCTContext.runActivity(named: "submitSuccess") { activity in
            let expectation = XCTestExpectation(description: "First submission is pending, the second is duplicate")
            self.sdk.accounts.getAccountDetails(accountId: self.accountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let bumpSequenceOperation = BumpSequenceOperation(bumpTo: accountResponse.sequenceNumber + 10, sourceAccountId: nil)
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [bumpSequenceOperation],
                                                      memo: Memo.text("Enjoy this transaction!"))

                    
                    try! transaction.sign(keyPair: self.accountKeyPair, network: Network.testnet)
                    self.sdk.transactions.submitAsyncTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let submitAsyncResponse):
                            XCTAssertEqual("PENDING", submitAsyncResponse.txStatus)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.sdk.transactions.submitAsyncTransaction(transaction: transaction) { (response) -> (Void) in
                                    switch response {
                                    case .success(let submitAsyncResponse2):
                                        XCTAssertEqual("DUPLICATE", submitAsyncResponse2.txStatus)
                                    case .destinationRequiresMemo(let destinationAccountId):
                                        print("submitDuplicate: Destination requires memo \(destinationAccountId)")
                                        XCTFail()
                                    case .failure(let error):
                                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"submitSuccess", horizonRequestError:error)
                                        XCTFail()
                                    }
                                    expectation.fulfill()
                                }
                            }
                        case .destinationRequiresMemo(let destinationAccountId):
                            print("submitPending: Destination requires memo \(destinationAccountId)")
                            XCTFail()
                            expectation.fulfill()
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"submitSuccess", horizonRequestError:error)
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(_):
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func statusError() {
        XCTContext.runActivity(named: "errorSubmission") { activity in
            let expectation = XCTestExpectation(description: "Status is ERROR")
            let account = try! Account(accountId: accountKeyPair.accountId, sequenceNumber: 10000000)
            let bumpSequenceOperation = BumpSequenceOperation(bumpTo: account.sequenceNumber + 10, sourceAccountId: nil)
            let transaction = try! Transaction(sourceAccount: account,
                                              operations: [bumpSequenceOperation],
                                              memo: Memo.text("Enjoy this transaction!"))

            
            try! transaction.sign(keyPair: self.accountKeyPair, network: Network.testnet)
            self.sdk.transactions.submitAsyncTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let submitAsyncResponse):
                    XCTAssertEqual("ERROR", submitAsyncResponse.txStatus)
                    expectation.fulfill()
                case .destinationRequiresMemo(let destinationAccountId):
                    print("submitPending: Destination requires memo \(destinationAccountId)")
                    XCTFail()
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"failed", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func malformed() {
        XCTContext.runActivity(named: "marformedSubmission") { activity in
            let expectation = XCTestExpectation(description: "horizon error with status 400 received")
            self.sdk.transactions.postTransactionAsync(transactionEnvelope: "Hello my friend!", skipMemoRequiredCheck: true,  response: { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTFail()
                case .destinationRequiresMemo(let destinationAccountId):
                    print("checkTransactionEnvelopePost: Destination requires memo \(destinationAccountId)")
                    XCTFail()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"malformed", horizonRequestError:error)
                }
                expectation.fulfill()
            })
                        
            wait(for: [expectation], timeout: 15.0)
        }
    }

}
