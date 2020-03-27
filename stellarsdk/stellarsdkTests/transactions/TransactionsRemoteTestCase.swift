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
    let seed = "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF"
    var streamItem:TransactionsStreamItem? = nil
    
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
                                XCTAssertTrue(transaction1?.maxFee == transaction2?.maxFee)
                                XCTAssertTrue(transaction1?.feeCharged == transaction2?.feeCharged)
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
        
        sdk.transactions.getTransactions(forAccount: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV") { (response) -> (Void) in
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
        
        sdk.transactions.getTransactionDetails(transactionHash: "95d8f7dfcfb452cd89e047e5b4dba63083d6d6559673fc9f55ad0064b8c7eb10") { (response) -> (Void) in
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
        let keyPair = try! KeyPair(secretSeed: seed)
        
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
            let source = try KeyPair(secretSeed:seed)
            let destination = try KeyPair(secretSeed: "SDA5U2P5SVQUZVETSUZANY5GP3TQLQTP7P7N7OW2T7X643EHFL5BH27N")
            
            streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: source.accountId, cursor: "now"))
            streamItem?.onReceive { response in
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
                        self.streamItem?.closeStream()
                        self.streamItem = nil
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
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTransactionEnvelopePost() {
        let keyPair = try! KeyPair(secretSeed: "SBSRPDUWJ73OGOBDDNZ5IXWJYOUFWLMU5NGPVUPWL6PZIZ5KDJHLSII5")
        
        let expectation = XCTestExpectation(description: "Transaction successfully signed.")
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.inflation
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation], maxOperationFee: 190)
                
                try! transaction.sign(keyPair: keyPair, network: .testnet)
                let xdrEnvelope = try! transaction.encodedEnvelope()
                print(xdrEnvelope)
                self.sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        expectation.fulfill()
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"TEP Test", horizonRequestError:error)
                        XCTAssert(false)
                    }
                })
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"TS Test", horizonRequestError:error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 25.0)
    }

    func testCoSignTransactionEnvelope() {
        let keyPair = try! KeyPair(secretSeed: "SA33GXHR62NBMBH5OZK5JHXR3X7KAANKMVXPIP6VQQO6N5HGKFB66HWR")
        
        let xdr = "AAAAALR6uVN4RmrfW6K8wdmNznPg6i3Q0dFJTu+fC/RccUZQAAABkAAN4SkAAAABAAAAAAAAAAAAAAAEAAAAAAAAAAYAAAABRFNRAAAAAABHB84JGCc/5+R3BOlxDMXPzkRrWjzfWQvocgCZlHVYu3//////////AAAAAAAAAAYAAAABVVNEAAAAAAABxhW5NR6QVXaxvG7fKS5GdaoNNuHlB1wIB+Sdra3GIn//////////AAAAAAAAAAUAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAEAAAACAAAAAQAAAAIAAAABAAAAAgAAAAAAAAABAAAAADcAko3Ije9aGOP0RkukFkQVJtdyFphVAsp/A/iOD8+7AAAAAQAAAAEAAAAAb0vB44BU2bPolZjPxTq49MypRuzHJ9s9aYwS1QoGvoAAAAABAAAAALR6uVN4RmrfW6K8wdmNznPg6i3Q0dFJTu+fC/RccUZQAAAAAURTUQAAAAAARwfOCRgnP+fkdwTpcQzFz85Ea1o831kL6HIAmZR1WLsAAAAAO5rKAAAAAAAAAAABCga+gAAAAEAceq3kjgzL9Hd0ad60WltzntByI1fdBUXp8nmR8V1d5QlEoDcrOHMo73SvpqvW4yfmksM4P4ixS5Pi4VUeboQL"
        
        let transaction = try! Transaction(envelopeXdr: xdr)
        
        try! transaction.sign(keyPair: keyPair, network: .testnet)
        
        let xdrEnvelope = try! transaction.encodedEnvelope()
        print(xdrEnvelope)
        
        XCTAssertTrue(transaction.fee == 400)
        
    }
}
