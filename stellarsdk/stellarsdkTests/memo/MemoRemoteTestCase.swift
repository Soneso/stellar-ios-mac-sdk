//
//  MemoRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/27/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MemoRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    var streamItem:TransactionsStreamItem? = nil
    
    let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
    let destinationKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")
        let sourceAccountId = sourceKeyPair.accountId
        let destinationAccountId = destinationKeyPair.accountId
        
        sdk.accounts.createTestAccount(accountId: sourceAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: destinationAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        expectation.fulfill()
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
        memoWithPaymentTransaction(memo: Memo.none)
        memoWithPaymentTransaction(memo: Memo.id(12345678))
        memoWithPaymentTransaction(memo: try! Memo(text: "Memo text test")!)
        maxLengthMemoText()
    }
    
    func memoWithPaymentTransaction(memo: Memo) {
        XCTContext.runActivity(named: "memoWithPaymentTransaction" + memo.type()) { activity in
            let expectation = XCTestExpectation(description: "Memo with payment transaction sent and received")
            
            let sourceAccountKeyPair = sourceKeyPair
            let destinationAccountKeyPair = destinationKeyPair
            
            streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let response):
                    if response.memoType == memo.type(), response.memo == memo {
                        XCTAssert(true)
                        self.streamItem?.closeStream()
                        self.streamItem = nil
                        expectation.fulfill()
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"memoWithPaymentTransaction", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                            destinationAccountId: destinationAccountKeyPair.accountId,
                                                            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                            amount: 1.5)
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [paymentOperation],
                                                      memo: memo)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            XCTAssertNotNil(response)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"memoWithPaymentTransaction", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func maxLengthMemoText() {
        let failingTestString = "https://gift-fakeurlspam.info"
        let passingTestString1 = "https://gift-fakeurlspam.org"
        let passingTestString2 = "https://gift-fakeurlspam.cc"

        XCTAssertNoThrow(try Memo(text: passingTestString1))
        XCTAssertNoThrow(try Memo(text: passingTestString2))
        XCTAssertThrowsError(try Memo(text: failingTestString))
    }
}
