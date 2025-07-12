//
//  PaymentsTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 10.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PaymentsTestCase: XCTestCase {

    static let testOn = "testnet" // "futurenet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    var streamItem:OperationsStreamItem? = nil
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let IOMIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()

    override func setUp() async throws {
        try await super.setUp()

        let testAccountId = testKeyPair.accountId
        let issuingAccountId = IOMIssuingAccountKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let changeTrustOp = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)
        let manageDataOp = ManageDataOperation(sourceAccountId: issuingAccountId, name: "config.memo_required", data: Data(base64Encoded: "MQ=="))
        
        var response = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        
        response = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: issuingAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: issuingAccountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create issuing account: \(testAccountId)")
        }
        
        let accDetailsRes = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsRes {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp, manageDataOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: self.network)
            try! transaction.sign(keyPair: self.IOMIssuingAccountKeyPair, network: self.network)
            
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
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() async {
        await getPayments()
        await getPaymentsForAccount()
        await getPaymentsForTransactionAndLedger()
        await sendAndReceiveNativePayment()
        await sendAndReceiveNativePaymentWithPreconditions()
        await sendAndReceiveNonNativePayment()
        await destinationRequiresMemo()
    }
    
    func getPayments() async {
        let result = await sdk.payments.getPayments()
        switch result {
        case .success(let paymentsPage):
            let nextPageResult = await paymentsPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPaymentsPage):
                let prevPageResult = await nextPaymentsPage.getPreviousPage()
                switch prevPageResult {
                case .success(let prevPaymentsPage):
                    XCTAssertTrue(paymentsPage.records.count > 0)
                    let payment1 = paymentsPage.records.first!
                    let payment2 = prevPaymentsPage.records.last! // because ordering is asc now.
                    XCTAssertTrue(payment1.id == payment2.id)
                    XCTAssertTrue(payment1.sourceAccount == payment2.sourceAccount)
                    XCTAssertTrue(payment1.sourceAccount == payment2.sourceAccount)
                    XCTAssertTrue(payment1.operationTypeString == payment2.operationTypeString)
                    XCTAssertTrue(payment1.operationType == payment2.operationType)
                    XCTAssertTrue(payment1.createdAt == payment2.createdAt)
                    XCTAssertTrue(payment1.transactionHash == payment2.transactionHash)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPayments()", horizonRequestError: error)
                    XCTFail("could not load previous payments page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPayments()", horizonRequestError: error)
                XCTFail("could not load next payments page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPayments()", horizonRequestError: error)
            XCTFail("could not load payments")
        }
    }
    
    func getPaymentsForAccount() async {
        let accountId = testKeyPair.accountId
        let paymentsPageResult = await sdk.payments.getPayments (forAccount: accountId, includeFailed:true, join:"transactions");
        switch paymentsPageResult {
        case .success(let page):
            XCTAssertTrue(page.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPaymentsForAccount()", horizonRequestError: error)
            XCTFail("could not load payments for account: \(accountId)")
        }
    }
    
    func getPaymentsForTransactionAndLedger() async {
        let txPageEnum = await sdk.transactions.getTransactions(forAccount: testKeyPair.accountId);
        switch txPageEnum {
        case .success(let page):
            XCTAssertTrue(page.records.count > 0)
            let txId = page.records.first!.id
            var paymentsPageEnum = await self.sdk.payments.getPayments(forTransaction: txId, includeFailed: true, join:"transactions");
            switch paymentsPageEnum {
            case .success(let page):
                XCTAssert(page.records.count > 0)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPaymentsForTransactionAndLedger()", horizonRequestError: error)
                XCTFail("could not load payments for tx: \(txId)")
            }
            
            let ledgerSeq = page.records.first!.ledger
            paymentsPageEnum = await sdk.payments.getPayments(forLedger: "\(ledgerSeq)" , includeFailed:true, join:"transactions");
            switch paymentsPageEnum {
            case .success(let page):
                XCTAssert(page.records.count > 0)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPaymentsForTransactionAndLedger()", horizonRequestError: error)
                XCTFail("could not load payments for ledger: \(ledgerSeq)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getPaymentsForTransactionAndLedger()", horizonRequestError: error)
            XCTFail("could not load transactions for account: \(testKeyPair.accountId)")
        }
    }
    
    func sendAndReceiveNativePayment() async {
        let expectation = XCTestExpectation(description: "Native payment successfully sent and received")
        
        let sourceAccountKeyPair = testKeyPair
        let destinationAccountId = IOMIssuingAccountKeyPair.accountId
        
        streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(let id, let operationResponse):
                if let paymentResponse = operationResponse as? PaymentOperationResponse {
                    print("Payment of \(paymentResponse.amount) XLM from \(paymentResponse.sourceAccount) received -  id \(id)" )
                    self.streamItem?.closeStream()
                    self.streamItem = nil
                    XCTAssert(true)
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNativePayment()", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accountDetailsResponseEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accountDetailsResponseEnum {
        case .success(let details):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: details.sequenceNumber, id: 1278881)
            let muxDest = try! MuxedAccount(accountId: destinationAccountId, id:9919191919)
            
            let paymentOperation = try! PaymentOperation(sourceAccountId: muxSource.accountId,
                                                    destinationAccountId: muxDest.accountId,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 1.5)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [paymentOperation],
                                              memo: Memo.init(text: "test"))
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
                expectation.fulfill()
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNativePayment()", horizonRequestError: error)
                XCTFail("submit transaction error")
                expectation.fulfill()
            }
            
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNativePayment()", horizonRequestError: error)
            XCTFail("could not load deatils for account: \(sourceAccountKeyPair.accountId)")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func sendAndReceiveNativePaymentWithPreconditions() async {
        let expectation = XCTestExpectation(description: "Native payment with preconditions successfully sent and received")
        let sourceAccountKeyPair = testKeyPair
        let destinationAccountId = IOMIssuingAccountKeyPair.accountId
        
        // wait for ledger to close
        sleep(5)
        
        self.streamItem = self.sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountId, cursor: "now"))
        self.streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(let id, let operationResponse):
                if let paymentResponse = operationResponse as? PaymentOperationResponse {
                    print("Payment of \(paymentResponse.amount) XLM from \(paymentResponse.sourceAccount) received -  id \(id)" )
                    self.streamItem?.closeStream()
                    self.streamItem = nil
                    XCTAssert(true)
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testSendAndReceiveNativePaymentWithPreconditions", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accountDetailsResponseEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accountDetailsResponseEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            let muxDest = try! MuxedAccount(accountId: destinationAccountId, id:9919191919)
            
            let paymentOperation = try! PaymentOperation(sourceAccountId: muxSource.accountId,
                                                    destinationAccountId: muxDest.accountId,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 1.5)
            
            let lb = LedgerBounds(minLedger: 0, maxLedger: 18779025)
            let tb = TimeBounds(minTime: 1652110741, maxTime: 1846805141)
            
            let precond = TransactionPreconditions(ledgerBounds: lb, timeBounds: tb, minSeqNumber: accountResponse.sequenceNumber, minSeqAge: 1, minSeqLedgerGap: 1)

            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [paymentOperation],
                                              memo: Memo.init(text: "test"),
                                              preconditions:precond)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
                expectation.fulfill()
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNativePaymentWithPreconditions()", horizonRequestError: error)
                XCTFail("submit transaction error")
                expectation.fulfill()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNativePaymentWithPreconditions()", horizonRequestError: error)
            XCTFail("could not load deatils for account: \(sourceAccountKeyPair.accountId)")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 35.0)
    }
    
    func sendAndReceiveNonNativePayment() async {
        let expectation = XCTestExpectation(description: "Non native payment successfully sent and received")
        
        let sourceKeyPair = IOMIssuingAccountKeyPair
        let destinationAccountId = testKeyPair.accountId
        let IOMAsset = Asset(canonicalForm: "IOM:" + IOMIssuingAccountKeyPair.accountId)!
        
        streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(let id, let operationResponse):
                if let paymentResponse = operationResponse as? PaymentOperationResponse {
                    if paymentResponse.assetCode == IOMAsset.code {
                        print("Payment of \(paymentResponse.amount) IOM from \(paymentResponse.sourceAccount) received -  id \(id)" )
                        XCTAssert(true)
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNonNativePayment", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accountDetailsResponseEnum = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId);
        switch accountDetailsResponseEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            let muxDest = try! MuxedAccount(accountId: destinationAccountId, id:9919191919)
            
            let paymentOperation = try! PaymentOperation(sourceAccountId: muxSource.accountId,
                                                    destinationAccountId: muxDest.accountId,
                                                    asset: IOMAsset,
                                                    amount: 2.5)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [paymentOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceKeyPair, network: self.network)
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let details):
                XCTAssertTrue(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
                expectation.fulfill()
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNonNativePayment()", horizonRequestError: error)
                XCTFail("submit transaction error")
                expectation.fulfill()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendAndReceiveNonNativePayment()", horizonRequestError: error)
            XCTFail("could not load deatils for account: \(sourceKeyPair.accountId)")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    
    func destinationRequiresMemo() async {
        
        let sourceAccountKeyPair = testKeyPair
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountId = IOMIssuingAccountKeyPair.accountId
        
        let accountDetailsResponseEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accountDetailsResponseEnum {
        case .success(let accountResponse):
            let paymentOperationOne = try! PaymentOperation(sourceAccountId: sourceAccountId,
                                                            destinationAccountId: sourceAccountId,
                                                            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                            amount: 1.5)
            let paymentOperationTwo = try! PaymentOperation(sourceAccountId: sourceAccountId,
                                                       destinationAccountId: destinationAccountId,
                                                       asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                       amount: 1.5)
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [paymentOperationOne, paymentOperationTwo],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(_):
                XCTFail("destination did not require memo")
            case .destinationRequiresMemo(destinationAccountId: let accId):
                XCTAssertTrue(destinationAccountId == accId)
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"destinationRequiresMemo()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"destinationRequiresMemo()", horizonRequestError: error)
            XCTFail("could not load deatils for account: \(sourceAccountKeyPair.accountId)")
        }
    }
}
