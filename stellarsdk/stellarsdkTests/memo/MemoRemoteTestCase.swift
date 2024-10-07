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
    
    override func setUp()  async throws {
        try await super.setUp()

        let sourceAccountId = sourceKeyPair.accountId
        let destinationAccountId = destinationKeyPair.accountId
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: destinationAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(destinationAccountId)")
        }

    }
    
    func testAll() async {
        await memoWithPaymentTransaction(memo: Memo.none)
        await memoWithPaymentTransaction(memo: Memo.id(12345678))
        await memoWithPaymentTransaction(memo: try! Memo(text: "Memo text test")!)
        maxLengthMemoText()
    }
    
    func memoWithPaymentTransaction(memo: Memo) async {
        let sourceAccountKeyPair = sourceKeyPair
        let destinationAccountKeyPair = destinationKeyPair
        let expectation = XCTestExpectation(description: "memo set correctly")
        
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
        
        let accDetailsResEnum = await self.sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                    destinationAccountId: destinationAccountKeyPair.accountId,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 1.5)
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [paymentOperation],
                                              memo: memo)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            
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
        
        await fulfillment(of: [expectation], timeout: 15.0)
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
