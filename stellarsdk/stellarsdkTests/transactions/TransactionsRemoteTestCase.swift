//
//  TransactionsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetAllTransactions() {
        let expectation = XCTestExpectation(description: "Get transactions")
        
        sdk.transactions.getTransactions(from: nil, order: nil, limit: 15) { (response) -> (Void) in
            switch response {
            case .success(let transactionsResponse):
                // load next page
                transactionsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextTransactionsResponse):
                        // load previous page, should contain the same transactions as the first page
                        nextTransactionsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevTransactionsResponse):
                                let transaction1 = transactionsResponse.records.first
                                let transaction2 = prevTransactionsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(transaction1?.id == transaction2?.id)
                                XCTAssertTrue(transaction1?.transactionHash == transaction2?.transactionHash)
                                XCTAssertTrue(transaction1?.ledger == transaction2?.ledger)
                                XCTAssertTrue(transaction1?.createdAt == transaction2?.createdAt)
                                XCTAssertTrue(transaction1?.sourceAccount == transaction2?.sourceAccount)
                                XCTAssertTrue(transaction1?.sourceAccountSequence == transaction2?.sourceAccountSequence)
                                XCTAssertTrue(transaction1?.feePaid == transaction2?.feePaid)
                                XCTAssertTrue(transaction1?.operationCount == transaction2?.operationCount)
                                XCTAssertTrue(transaction1?.memoType == transaction2?.memoType)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(_):
                                XCTAssert(false)
                            }
                        }
                    case .failure(_):
                        XCTAssert(false)
                    }
                }
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTransactionsForAccount() {
        let expectation = XCTestExpectation(description: "Get transactions for account")
        
        sdk.transactions.getTransactions(forAccount: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTransactionsForLedger() {
        let expectation = XCTestExpectation(description: "Get transactions for ledger")
        
        sdk.transactions.getTransactions(forLedger: "1") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTransactionDetails() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        
        sdk.transactions.getTransactionDetails(transactionHash: "6a1e3ff103473d8edbdb05a7a4bd17c9e84c310ff4f52b80596441d9e814e180") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSendAndReceivePayment() {
        
        let expectation = XCTestExpectation(description: "Payment successfully sent and received")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PAGAJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")
            let destinationAccountKeyPair = try KeyPair(accountId: "GCKECJ5DYFZUX6DMTNJFHO2M4QKTUO5OS5JZ4EIIS7C3VTLIGXNGRTRC")
            
            func send() {
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
                                                              memo: Memo.none,
                                                              timeBounds:nil)
                            try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                            
                            try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                switch response {
                                case .success(_):
                                    receive()
                                case .failure(_):
                                    XCTAssert(false)
                                    expectation.fulfill()
                                }
                            }
                        } catch {
                            XCTAssert(false)
                            expectation.fulfill()
                        }
                    case .failure(_):
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                }
            }
            
            func receive() {
                sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: nil)).onReceive { (response) -> (Void) in
                    switch response {
                        case .open:
                            break
                        case .response(let id, let paymentResponse):
                            print("Payment of \(paymentResponse.amount) XLM from \(paymentResponse.sourceAccount) received -  id \(id)" )
                            showDestinationAccountBalance(finish: true)
                        case .error( _):
                            XCTAssert(false)
                            expectation.fulfill()
                    }
                }
            }
            
            func showDestinationAccountBalance(finish:Bool) {
                sdk.accounts.getAccountDetails(accountId: destinationAccountKeyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountResponse):
                        for balance in accountResponse.balances {
                            if balance.assetType == AssetTypeAsString.NATIVE {
                                print("Destination account balance: \(balance.balance) XLM")
                                if (finish) {
                                    XCTAssert(true)
                                    expectation.fulfill()
                                }
                            }
                        }
                    case .failure(_):
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                }
            }
            
            showDestinationAccountBalance(finish: false)
            send()
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTransactionSigning() {
        let publicKey = Data(base64Encoded:"uHFsF4DaBlIsPUzFlMuBFkgEROGR9DlEBYCg3x+V72A=")!
        let privateKey = Data(base64Encoded: "KJJ6vrrDOe9XIDAj6iSftUzux0qWwSwf3er27YKUOU2ZbT/G/wqFm/tDeez3REW5YlD5mrf3iidmGjREBzOEjQ==")!
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        
        let expectation = XCTestExpectation(description: "Transaction successfully signed.")
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.inflation
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation])
                
                try! transaction.sign(keyPair: keyPair, network: .testnet)
                let xdrEnvelope = try! transaction.encodedEnvelope()
                print(xdrEnvelope)
                expectation.fulfill()
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTransactionEnvelopePost() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        let xdrEnvelope = "AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAByE3sAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAR+V72AAAABAAuiJ2+1FGpG7D+sS9qqZlk2/dsu8mdECuR1jiX9PaawJaJMETUP6u06cZgzrqopzmypJMOS/ob7BRvCQ3JkwDg=="
        
        sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
            switch response {
            case .success(_):
                expectation.fulfill()
            case .failure(_):
                XCTAssert(false)
            }
        })
        
        wait(for: [expectation], timeout: 25.0)
    }
    
 /* func testTransactionsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.transactions.stream(for: .allTransactions(cursor: nil)).onReceive { (response) -> (Void) in
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
    
    func testTransactionsForAccountStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.transactions.stream(for: .transactionsForAccount(account: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX", cursor: nil)).onReceive { (response) -> (Void) in
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
    
    func testTransactionsForLedgerStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.transactions.stream(for: .transactionsForLedger(ledger: "2365", cursor: nil)).onReceive { (response) -> (Void) in
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
