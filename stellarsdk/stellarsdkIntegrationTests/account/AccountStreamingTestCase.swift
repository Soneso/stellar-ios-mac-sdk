//
//  AccountStreamingTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 07.01.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AccountStreamingTestCase: XCTestCase {

    static let testOn = "testnet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    var accountStreamItem: AccountStreamItem? = nil
    var dataStreamItem: AccountDataStreamItem? = nil

    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let destinationKeyPair = try! KeyPair.generateRandomKeyPair()

    override func setUp() async throws {
        try await super.setUp()

        let testAccountId = testKeyPair.accountId
        let destinationAccountId = destinationKeyPair.accountId

        let manageDataOp = ManageDataOperation(sourceAccountId: testAccountId, name: "test_key", data: "initial".data(using: .utf8))
        let createAccountOp = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: destinationAccountId, startBalance: 10.0)

        let response = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }

        let accDetailsRes = await self.sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsRes {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [manageDataOp, createAccountOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: self.network)

            let submitTxResponse = await self.sdk.transactions.submitTransaction(transaction: transaction)
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
    }

    override func tearDown() {
        accountStreamItem?.closeStream()
        dataStreamItem?.closeStream()
        super.tearDown()
    }

    func testAll() async {
        await testStreamAccount()
        await testStreamAccountData()
    }

    func testStreamAccount() async {
        let expectation = XCTestExpectation(description: "Account stream receives update")

        let sourceAccountKeyPair = testKeyPair
        let destinationAccountId = destinationKeyPair.accountId

        nonisolated(unsafe) var streamOpened = false
        nonisolated(unsafe) var updateReceived = false

        accountStreamItem = sdk.accounts.streamAccount(accountId: destinationAccountId)
        accountStreamItem?.onReceive { response in
            switch response {
            case .open:
                streamOpened = true
            case .response(id: let id, data: let account):
                print("Account stream update received - id: \(id), sequence: \(account.sequenceNumber)")
                if account.accountId == destinationAccountId {
                    updateReceived = true
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamAccount", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
                XCTFail("Stream error occurred")
                expectation.fulfill()
            }
        }

        // Wait for stream to open
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Send a payment to trigger account update
        let accDetailsRes = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsRes {
        case .success(let accountResponse):
            let paymentOperation = try! PaymentOperation(
                sourceAccountId: sourceAccountKeyPair.accountId,
                destinationAccountId: destinationAccountId,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: 1.0
            )

            let transaction = try! Transaction(
                sourceAccount: accountResponse,
                operations: [paymentOperation],
                memo: Memo.none
            )
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)

            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
                expectation.fulfill()
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamAccount()", horizonRequestError: error)
                XCTFail("submit transaction error")
                expectation.fulfill()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamAccount()", horizonRequestError: error)
            XCTFail("could not load account details")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 25.0)

        XCTAssertTrue(streamOpened, "Stream should have opened")
        XCTAssertTrue(updateReceived, "Should have received account update")

        accountStreamItem?.closeStream()
        accountStreamItem = nil
    }

    func testStreamAccountData() async {
        let expectation = XCTestExpectation(description: "Account data stream receives update")

        let testAccountId = testKeyPair.accountId
        let dataKey = "test_key"

        nonisolated(unsafe) var streamOpened = false
        nonisolated(unsafe) var updateReceived = false

        dataStreamItem = sdk.accounts.streamAccountData(accountId: testAccountId, key: dataKey)
        dataStreamItem?.onReceive { response in
            switch response {
            case .open:
                streamOpened = true
            case .response(id: let id, data: let dataEntry):
                print("Account data stream update received - id: \(id)")
                if let decodedValue = dataEntry.value.base64Decoded() {
                    print("Data value: \(decodedValue)")
                    if decodedValue == "updated" {
                        updateReceived = true
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamAccountData", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
                XCTFail("Stream error occurred")
                expectation.fulfill()
            }
        }

        // Wait for stream to open
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Update the data entry to trigger stream update
        let accDetailsRes = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsRes {
        case .success(let accountResponse):
            let manageDataOp = ManageDataOperation(
                sourceAccountId: testAccountId,
                name: dataKey,
                data: "updated".data(using: .utf8)
            )

            let transaction = try! Transaction(
                sourceAccount: accountResponse,
                operations: [manageDataOp],
                memo: Memo.none
            )
            try! transaction.sign(keyPair: testKeyPair, network: self.network)

            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
                expectation.fulfill()
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamAccountData()", horizonRequestError: error)
                XCTFail("submit transaction error")
                expectation.fulfill()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamAccountData()", horizonRequestError: error)
            XCTFail("could not load account details")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 25.0)

        XCTAssertTrue(streamOpened, "Stream should have opened")
        XCTAssertTrue(updateReceived, "Should have received data update")

        dataStreamItem?.closeStream()
        dataStreamItem = nil
    }
}
