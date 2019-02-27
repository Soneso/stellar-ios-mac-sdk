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
    
    func testGetTransactions() {
        let expectation = XCTestExpectation(description: "Get transactions")
        
        sdk.transactions.getTransactions(limit: 15) { (response) -> (Void) in
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
                                XCTAssertTrue(transaction1?.memo == transaction2?.memo)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTransactionsForAccount() {
        let expectation = XCTestExpectation(description: "Get transactions for account")
        
        sdk.transactions.getTransactions(forAccount: "GDQZ4N3CMM3FL2HLYKZPF3JPZX3IRHI3SQKNSTEG6GMEA3OAW337EBA6") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GTFA Test", horizonRequestError: error)
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
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GTFL Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTransactionDetails() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        
        sdk.transactions.getTransactionDetails(transactionHash: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GTD Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
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
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"TS Test", horizonRequestError:error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTransactionMultiSigning() {
        let expectation = XCTestExpectation(description: "Transaction Multisignature")
        
        do {
            let source = try KeyPair(secretSeed:"SA3QF6XW433CBDLUEY5ZAMHYJLJNH4GOPASLJLO4QKH75HRRXZ3UM2YJ")
            let destination = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            
            sdk.transactions.stream(for: .transactionsForAccount(account: source.accountId, cursor: "now")).onReceive { response in
                switch response {
                case .open:
                    break
                case .response(_, let response):
                    for sign in response.signatures {
                        print("Signature: \(sign)")
                    }
                    if response.signatures.count == 2 {
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
            
            sdk.accounts.getAccountDetails(accountId: source.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let paymentOperation = PaymentOperation(destination: destination,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 1.5)
                        
                        let paymentOperation2 = PaymentOperation(sourceAccount: destination,
                                                                destination: source,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 3.5)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [paymentOperation, paymentOperation2],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        
                        try transaction.sign(keyPair: source, network: .testnet)
                        try transaction.sign(keyPair: destination, network: .testnet)
                        
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
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testTransactionEnvelopePost() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        let xdrEnvelope = "AAAAAEoEH7ZQEw/9pvByb8zVNc778lBaE/CRqWCqLMqZfJEhAAAAZAAAAHgAAAABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAEH3Rayw4M0iCLoEe96rPFNGYim8AVHJU0z4ebYZW4JwAA41+pMaAAAAAAAAAAAABmXyRIQAAAEACF+2/akS2P9UVrnj63h7riTipaWPzeirDFP7P97VkcpBk12utsSbMhCg+YV5osZIKf4n9QsS6rDq3hZbP3qgD"
        
        sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
            switch response {
            case .success(_):
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"TEP Test", horizonRequestError:error)
                XCTAssert(false)
            }
        })
        
        wait(for: [expectation], timeout: 25.0)
    }

 /*
    func testTransactionsStream() {
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
        
        sdk.transactions.stream(for: .transactionsForAccount(account: "GDQZ4N3CMM3FL2HLYKZPF3JPZX3IRHI3SQKNSTEG6GMEA3OAW337EBA6", cursor: nil)).onReceive { (response) -> (Void) in
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
