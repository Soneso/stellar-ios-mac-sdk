//
//  MemoRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/27/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MemoRemoteTestCase: XCTestCase, @unchecked Sendable {
    
    static let testOn = "testnet" // "futurenet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    var streamItem:TransactionsStreamItem? = nil
    
    let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
    let destinationKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp()  async throws {
        try await super.setUp()

        let sourceAccountId = sourceKeyPair.accountId
        let destinationAccountId = destinationKeyPair.accountId
        
        try await fundTestAccountAndAwaitVisibility(accountId: sourceAccountId, horizon: sdk, useFuturenet: network.passphrase != Network.testnet.passphrase)

        try await fundTestAccountAndAwaitVisibility(accountId: destinationAccountId, horizon: sdk, useFuturenet: network.passphrase != Network.testnet.passphrase)

    }
    
    func testAll() async {
        await memoWithPaymentTransaction(memo: Memo.none)
        await memoWithPaymentTransaction(memo: Memo.id(12345678))
        await memoWithPaymentTransaction(memo: try! Memo(text: "Memo text test")!)
        maxLengthMemoText()
    }
    
    func testTextMemoBytesThatAreNotUTF8() async throws {
        let memoBytes = Data([0xff, 0xfe, 0x20, 0x61, 0x62, 0x63])

        let accountEnum = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
        guard case .success(let accountResponse) = accountEnum else {
            XCTFail("could not load account details")
            return
        }
        let paymentOperation = try PaymentOperation(sourceAccountId: sourceKeyPair.accountId,
                                                    destinationAccountId: destinationKeyPair.accountId,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 1.5)
        let transaction = try Transaction(sourceAccount: accountResponse,
                                          operations: [paymentOperation],
                                          memoXDR: .text(memoBytes))
        try transaction.sign(keyPair: sourceKeyPair, network: network)
        let envelope = try transaction.encodedEnvelope()
        let hash = try transaction.getTransactionHash(network: network)

        let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitEnum {
        case .success(let details):
            XCTAssertEqual(details.transactionHash, hash)
        case .destinationRequiresMemo(let destinationAccountId):
            XCTFail("destination account \(destinationAccountId) requires memo")
            return
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testTextMemoBytesThatAreNotUTF8", horizonRequestError: error)
            XCTFail("submit transaction error")
            return
        }

        let detailsEnum = await sdk.transactions.getTransactionDetails(transactionHash: hash)
        guard case .success(let details) = detailsEnum else {
            XCTFail("could not load transaction details")
            return
        }
        XCTAssertEqual(details.transactionHash, hash)
        XCTAssertEqual(details.memoType, "text")
        XCTAssertEqual(details.memoBytes, memoBytes)
        XCTAssertEqual(details.memo, Memo.text("\u{FFFD}\u{FFFD} abc"))
        XCTAssertEqual(details.transactionEnvelope.xdrEncoded, envelope)

        let imported = try Transaction(envelopeXdr: try XCTUnwrap(details.transactionEnvelope.xdrEncoded))
        XCTAssertEqual(try imported.encodedEnvelope(), envelope)
        XCTAssertEqual(try imported.getTransactionHash(network: network), hash)
        guard case .text(let importedBytes) = imported.transactionXDR.memo else {
            XCTFail("imported memo is not a text memo")
            return
        }
        XCTAssertEqual(importedBytes, memoBytes)
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
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                    destinationAccountId: destinationAccountKeyPair.accountId,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 1.5)
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [paymentOperation],
                                              memo: memo)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
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
