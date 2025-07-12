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
    
    static let testOn = "testnet" // "futurenet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    let testKeyPair = try! KeyPair.generateRandomKeyPair()

    override func setUp() async throws {
        try await super.setUp()
        let testAccountId = testKeyPair.accountId
        let manageDataOp = ManageDataOperation(sourceAccountId: testAccountId, name: "soneso", data: "is super".data(using: .utf8))
        
        let response = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch response {
        case .success(_):
            let accDetailsRes = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
            switch accDetailsRes {
            case .success(let accountResponse):
                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                  operations: [manageDataOp],
                                                  memo: Memo.none)
                try! transaction.sign(keyPair: self.testKeyPair, network: self.network)
                let submitTxRes = await self.sdk.transactions.submitTransaction(transaction: transaction)
                switch submitTxRes {
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
                XCTFail("could not load account details for test account: \(testAccountId)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetDataForAccount() async {
        
        let dataResponse = await sdk.accounts.getDataForAccount(accountId: testKeyPair.accountId, key:"soneso");
        switch dataResponse {
        case .success(let dataForAccount):
            XCTAssertEqual(dataForAccount.value.base64Decoded(), "is super")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetDataForAccount()", horizonRequestError: error)
            XCTFail()
        }
    }
}

