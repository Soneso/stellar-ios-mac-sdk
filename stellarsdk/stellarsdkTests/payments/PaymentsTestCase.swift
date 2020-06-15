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
    let sdk = StellarSDK()
    //let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org/?customParam=123&secondCustomParam=987")
    var streamItem:OperationsStreamItem? = nil
    let IOMIssuingAccountId = "GAHVPXP7RPX5EGT6WFDS26AOM3SBZW2RKEDBZ5VO45J7NYDGJYKYE6UW"
    let seed = "SD24I54ZUAYGZCKVQD6DZD6PQGLU7UQKVWDM37TKIACO3P47WG3BRW4C"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetPayments() {
        let expectation = XCTestExpectation(description: "Test get payments and paging")
        
        sdk.payments.getPayments { (response) -> (Void) in
            switch response {
            case .success(let paymentsResponse):
                // load next page
                paymentsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextPaymentsResponse):
                        // load previous page, should contain the same payments as the first page
                        nextPaymentsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevPaymentsResponse):
                                let payment1 = paymentsResponse.records.first
                                let payment2 = prevPaymentsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(payment1?.id == payment2?.id)
                                XCTAssertTrue(payment1?.sourceAccount == payment2?.sourceAccount)
                                XCTAssertTrue(payment1?.sourceAccount == payment2?.sourceAccount)
                                XCTAssertTrue(payment1?.operationTypeString == payment2?.operationTypeString)
                                XCTAssertTrue(payment1?.operationType == payment2?.operationType)
                                XCTAssertTrue(payment1?.createdAt == payment2?.createdAt)
                                XCTAssertTrue(payment1?.transactionHash == payment2?.transactionHash)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GP Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GP Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GP Test", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetPaymentsForAccount() {
        let expectation = XCTestExpectation(description: "Get payments for account")
        let accID = try! KeyPair(secretSeed: seed).accountId
        sdk.payments.getPayments (forAccount: accID, includeFailed:true, join:"transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GPFA Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetPaymentsForLedger() {
        let expectation = XCTestExpectation(description: "Get payments for ledger")
        
        sdk.payments.getPayments(forLedger: "194461", includeFailed:true, join:"transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GPFL Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetPaymentsForTransaction() {
        let expectation = XCTestExpectation(description: "Get payments for transaction")
        
        sdk.payments.getPayments(forTransaction: "50b76312829a9c6077678a00b4fee2f12cbe531900b83f72ef4145fc0763c409", includeFailed: true, join:"transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GPFT Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDestinationRequiresMemo() {
        
        let expectation = XCTestExpectation(description: "Native payment can not be sent because destination requires memo")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            let destinationOneAccountKeyPair = try KeyPair(accountId: "GAQC6DUD2OVIYV3DTBPOSLSSOJGE4YJZHEGQXOU4GV6T7RABWZXELCUT")
            let destinationTwoAccountKeyPair = try KeyPair(accountId: "GDC3CJZ5GQU3UKSA45JFYHOWCH5H43QIRUJ752CK7LBXYPJM4SIGCJYW")
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let paymentOperationOne = PaymentOperation(sourceAccount: sourceAccountKeyPair,
                                                                destination: destinationOneAccountKeyPair,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 1.5)
                        let paymentOperationTwo = PaymentOperation(sourceAccount: sourceAccountKeyPair,
                                                                   destination: destinationTwoAccountKeyPair,
                                                                   asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                   amount: 1.5)
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [paymentOperationOne, paymentOperationTwo],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("DRM Test: Transaction successfully sent")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("DRM Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"DRM Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"DRM Test", horizonRequestError:error)
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
    
    func testSendAndReceiveNativePayment() {
        
        let expectation = XCTestExpectation(description: "Native payment successfully sent and received")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            let destinationAccountKeyPair = try KeyPair(accountId: IOMIssuingAccountId)
            
            streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: "now"))
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
                        let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let muxDest = try MuxedAccount(accountId: self.IOMIssuingAccountId, id:9919191919)
                        
                        print ("Muxed destination account id: \(muxDest.accountId)")
                        
                        let paymentOperation = try PaymentOperation(sourceAccountId: muxSource.accountId,
                                                                destinationAccountId: muxDest.accountId,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 1.5)
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("SRP Test: Transaction successfully sent. Hash \(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("SRP Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
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
    
    func testSendAndReceiveNonNativePayment() {
        
        let expectation = XCTestExpectation(description: "Non native payment successfully sent and received")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            let destinationAccountKeyPair = try KeyPair(accountId:IOMIssuingAccountId)
            printAccountDetails(tag: "SRNNP Test - source", accountId: sourceAccountKeyPair.accountId)
            printAccountDetails(tag: "SRNNP Test - dest", accountId: destinationAccountKeyPair.accountId)
            
            let issuingAccountKeyPair = try KeyPair(accountId: IOMIssuingAccountId)
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            
            streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let operationResponse):
                    if let paymentResponse = operationResponse as? PaymentOperationResponse {
                        if paymentResponse.assetCode == IOM?.code {
                            print("Payment of \(paymentResponse.amount) IOM from \(paymentResponse.sourceAccount) received -  id \(id)" )
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRNNP Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let muxDest = try MuxedAccount(accountId: self.IOMIssuingAccountId, id:9919191919)
                        
                        print ("Muxed destination account id: \(muxDest.accountId)")
                        
                        let paymentOperation = try PaymentOperation(sourceAccountId: muxSource.accountId,
                                                                destinationAccountId: muxDest.accountId,
                                                                asset: IOM!,
                                                                amount: 2.5)
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("SRNNP Test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("SRNNP Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRNNP Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRNNP Test", horizonRequestError:error)
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
    
    func printAccountDetails(tag: String, accountId: String) {
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                print("\(tag): Account ID: \(accountResponse.accountId)")
                print("\(tag): Account Sequence: \(accountResponse.sequenceNumber)")
                for balance in accountResponse.balances {
                    if balance.assetType == AssetTypeAsString.NATIVE {
                        print("\(tag): Account balance: \(balance.balance) XLM")
                    } else {
                        print("\(tag): Account balance: \(balance.balance) \(balance.assetCode!) of issuer: \(balance.assetIssuer!)")
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
/*
   func testPaymentsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.payments.stream(for: .allPayments(cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_,_):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }

    func testPaymentsForAccountStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.payments.stream(for: .paymentsForAccount(account: "GDQZ4N3CMM3FL2HLYKZPF3JPZX3IRHI3SQKNSTEG6GMEA3OAW337EBA6", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPaymentsForLedgerStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.payments.stream(for: .paymentsForLedger(ledger: "2365", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPaymentsForTransactionsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.payments.stream(for: .paymentsForTransaction(transaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    */
}
