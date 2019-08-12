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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMemoNone() {
        memoWithPaymentTransaction(memo: Memo.none)
    }
    
    func testMemoText() {
        do {
            if let memo = try Memo(text: "Memo text test") {
                memoWithPaymentTransaction(memo: memo)
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }
    
    func testMemoId() {
        memoWithPaymentTransaction(memo: Memo.id(12345678))
    }
    
    /*func testMemoHash() {
        do {
            if let memo = try Memo(hash: Data(base64Encoded:"UQQWROg9ashoyElBi2OS3b6d9T8AAAAAAAAAAAAAAAA=")!) {
                memoWithPaymentTransaction(memo: memo)
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }
    
    func testMemoReturnHash() {
        do {
            if let memo = try Memo(returnHash: Data(base64Encoded:"UQQWROg9ashoyElBi2OS3b6d9T8AAAAAAAAAAAAAAAA=")!) {
                memoWithPaymentTransaction(memo: memo)
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }*/
    
    func memoWithPaymentTransaction(memo: Memo) {
        
        let expectation = XCTestExpectation(description: "Memo with payment transaction sent and received")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF")
            let destinationAccountKeyPair = try KeyPair(accountId: "GDKNTVRFEEQQUFQHT65J4IITT55GO22E23TBZBAF3LWNOT6U44QWHAQB")
            
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let paymentOperation = PaymentOperation(sourceAccount: sourceAccountKeyPair,
                                                                destination: destinationAccountKeyPair,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 1.5)
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [paymentOperation],
                                                          memo: memo,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("SRP Test: Transaction successfully sent")
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test", horizonRequestError:error)
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

    func testMaxLengthMemoText() {
        let failingTestString = "https://gift-fakeurlspam.info"
        let passingTestString1 = "https://gift-fakeurlspam.org"
        let passingTestString2 = "https://gift-fakeurlspam.cc"

        XCTAssertNoThrow(try Memo(text: passingTestString1))
        XCTAssertNoThrow(try Memo(text: passingTestString2))
        XCTAssertThrowsError(try Memo(text: failingTestString))
    }
}
