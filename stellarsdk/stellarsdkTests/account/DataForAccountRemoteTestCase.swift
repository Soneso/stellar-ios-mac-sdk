//
//  DataForAccountRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class DataForAccountRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    let testKeyPair = try! KeyPair.generateRandomKeyPair()

    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

        let testAccountId = testKeyPair.accountId
        let manageDataOp = ManageDataOperation(sourceAccountId: testAccountId, name: "soneso", data: "is super".data(using: .utf8))
        
        sdk.accounts.createTestAccount(accountId: testAccountId) { (response) -> (Void) in
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

    func testGetDataForAccount() {
        let expectation = XCTestExpectation(description: "Get data value for a given account and key")
        sdk.accounts.getDataForAccount(accountId: testKeyPair.accountId, key:"soneso") { (response) -> (Void) in
            switch response {
            case .success(let dataForAccount):
                XCTAssertEqual(dataForAccount.value.base64Decoded(), "is super")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetDataForAccount", horizonRequestError: error)
                XCTFail()
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}

