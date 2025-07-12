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

    static let testOn = "testnet" // "futurenet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    let accountKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp() async throws {
        try await super.setUp()
        
        let testAccountId = accountKeyPair.accountId
        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
    }
    
    func testAll() async {
        await pendingAndDuplicate();
        await statusError()
        await malformed()
    }
    
    func pendingAndDuplicate() async {
        let testAccountId = accountKeyPair.accountId
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let bumpSequenceOperation = BumpSequenceOperation(bumpTo: accountResponse.sequenceNumber + 10, sourceAccountId: nil)
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [bumpSequenceOperation],
                                              memo: Memo.text("Enjoy this transaction!"))

            
            try! transaction.sign(keyPair: self.accountKeyPair, network: self.network)
            
            let submitTxResponse = await sdk.transactions.submitAsyncTransaction(transaction: transaction)
            switch submitTxResponse {
            case .success(let submitAsyncResponse):
                XCTAssertEqual("PENDING", submitAsyncResponse.txStatus)
                let response = await sdk.transactions.submitAsyncTransaction(transaction: transaction)
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
            case .destinationRequiresMemo(let destinationAccountId):
                print("submitPending: Destination requires memo \(destinationAccountId)")
                XCTFail()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"submitSuccess", horizonRequestError:error)
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func statusError() async {
        let account = try! Account(accountId: accountKeyPair.accountId, sequenceNumber: 10000000)
        let bumpSequenceOperation = BumpSequenceOperation(bumpTo: account.sequenceNumber + 10, sourceAccountId: nil)
        let transaction = try! Transaction(sourceAccount: account,
                                          operations: [bumpSequenceOperation],
                                          memo: Memo.text("Enjoy this transaction!"))

        
        try! transaction.sign(keyPair: self.accountKeyPair, network: self.network)
        let submitTxResponse = await sdk.transactions.submitAsyncTransaction(transaction: transaction)
        switch submitTxResponse {
        case .success(let submitAsyncResponse):
            XCTAssertEqual("ERROR", submitAsyncResponse.txStatus)
        case .destinationRequiresMemo(let destinationAccountId):
            print("submitPending: Destination requires memo \(destinationAccountId)")
            XCTFail()
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"failed", horizonRequestError:error)
            XCTFail()
        }
    }
    
    func malformed() async {
        
        let submitTxResponse = await self.sdk.transactions.postTransactionAsync(transactionEnvelope: "Hello my friend!", skipMemoRequiredCheck: true)
        switch submitTxResponse {
        case .success(_):
            XCTFail()
        case .destinationRequiresMemo(let destinationAccountId):
            print("checkTransactionEnvelopePost: Destination requires memo \(destinationAccountId)")
            XCTFail()
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"malformed", horizonRequestError:error)
        }
    }

}
