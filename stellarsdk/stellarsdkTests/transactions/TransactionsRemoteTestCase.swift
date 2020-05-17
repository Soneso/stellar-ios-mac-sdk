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
    let seed = "SD24I54ZUAYGZCKVQD6DZD6PQGLU7UQKVWDM37TKIACO3P47WG3BRW4C"
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
                                XCTAssertTrue(transaction1?.feeAccount == transaction2?.feeAccount)
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
        let pk = try! KeyPair(secretSeed: seed).publicKey
        sdk.transactions.getTransactions(forAccount: pk.accountId) { (response) -> (Void) in
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
        
        sdk.transactions.getTransactionDetails(transactionHash: "ed1dc9a219d5e8292a29b1b5c580b98fba0066aeb96fcd45a290fb68ff0b70bb") { (response) -> (Void) in
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
                let encodedT = try! transaction.encodedV1Transaction()
                print("\nTransaction V1:")
                print(encodedT)
                print("\nEnvelope V1:")
                let xdrEnvelopeV0 = try! transaction.encodedV1Envelope()
                print(xdrEnvelopeV0)
                print("\nEnvelope P13:")
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
    
    func testTransactionV0Signing() {
        let keyPair = try! KeyPair(secretSeed: seed)
        
        let expectation = XCTestExpectation(description: "Transaction successfully signed.")
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.inflation
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                var transaction = TransactionV0XDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation])
                try! transaction.sign(keyPair: keyPair, network: .testnet)
                let encodedT = try! transaction.encodedV0Transaction()
                print("\nTransaction VO:")
                print(encodedT)
                print("\nEnvelope VO:")
                let xdrEnvelopeV0 = try! transaction.encodedV0Envelope()
                print(xdrEnvelopeV0)
                print("\nEnvelope P13:")
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
            let destination = try KeyPair(secretSeed: "SBK3OW43UIX4HDWDJNO4FTOKL3ESZ4CBDPA57UAUE7SL3JMPNHWZEYGF")
            
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
                        
                        try transaction.sign(keyPair: source, network: .testnet, coreProtocolVersion: 13)
                        try transaction.sign(keyPair: destination, network: .testnet, coreProtocolVersion: 13)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction, coreProtocolVersion:13) { (response) -> (Void) in
                            switch response {
                            case .success(let rep):
                                print("SRP Test: Transaction successfully sent. Hash: \(rep.transactionHash)")
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
    
    func testTransactionEnvelopePost() {
        let keyPair = try! KeyPair(secretSeed: seed)
        
        let expectation = XCTestExpectation(description: "Transaction successfully signed.")
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.bumpSequence(BumpSequenceOperationXDR(bumpTo: data.sequenceNumber + 10))
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                var transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation], maxOperationFee: 190)
                
                try! transaction.sign(keyPair: keyPair, network: .testnet)
                let xdrEnvelope = try! transaction.encodedEnvelope()
                print(xdrEnvelope)
                self.sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        expectation.fulfill()
                    case .destinationRequiresMemo(let destinationAccountId):
                        print("TEP Test: Destination requires memo \(destinationAccountId)")
                        XCTAssert(false)
                        expectation.fulfill()
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"TEP Test", horizonRequestError:error)
                        XCTAssert(false)
                    }
                })
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"TEP Test", horizonRequestError:error)
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
    
    func testFeeBumpTransactionEnvelopePost() {
        let sourceAccountKeyPair = try! KeyPair(secretSeed: seed)
        
        let expectation = XCTestExpectation(description: "FeeBumpTransaction successfully sent.")
        let destination = "GAQC6DUD2OVIYV3DTBPOSLSSOJGE4YJZHEGQXOU4GV6T7RABWZXELCUT"
        let payerSeed = "SD7F3RYMDHQ6SBMVKONRRQCG4OFCW7HSWPS7CBGH762ZHVA6LC6RR5LD"
        
        
        do {
            let payerKeyPair = try KeyPair(secretSeed: payerSeed)
            
            streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: payerKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { response in
                switch response {
                case .open:
                    break
                case .response(_, let response):
                    
                    if let fbr = response.feeBumpTransactionResponse, let itr = response.innerTransactionResponse {
                        print("\nfee_bump-transaction: \(fbr.transactionHash)")
                        for signature in fbr.signatures {
                            print("signature: \(signature)")
                        }
                        print("\ninner_transaction: \(itr.transactionHash)")
                        for signature in itr.signatures {
                            print("signature: \(signature)")
                        }
                        print("max_fee: \(itr.maxFee)\n")
                        XCTAssert(true)
                    } else {
                        XCTAssert(false)
                    }
                    expectation.fulfill()
                    self.streamItem?.closeStream()
                    self.streamItem = nil
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                                destinationAccountId: destination,
                                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                amount: 1.5)
                        let innerTx = try Transaction(sourceAccount: accountResponse,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try innerTx.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        self.sdk.accounts.getAccountDetails(accountId: payerKeyPair.accountId) { (response) -> (Void) in
                            switch response {
                            case .success(let accountResponse):
                                do {
                                    let mux = try MuxedAccount(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber, id: 929299292)
                                    let fb = try FeeBumpTransaction(sourceAccount: mux, fee: 200, innerTransaction: innerTx)
                                    
                                    try fb.sign(keyPair: payerKeyPair, network: Network.testnet)
                                    
                                    try self.sdk.transactions.submitFeeBumpTransaction(transaction: fb) { (response) -> (Void) in
                                        switch response {
                                        case .success(let response):
                                            print("SFB Test: FeeBumpTransaction successfully sent. Hash \(response.transactionHash)")
                                            XCTAssert(true)
                                        case .destinationRequiresMemo(let destinationAccountId):
                                            print("SFB Test: Destination requires memo \(destinationAccountId)")
                                            XCTAssert(false)
                                            expectation.fulfill()
                                        case .failure(let error):
                                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"FBT Test", horizonRequestError:error)
                                            XCTAssert(false)
                                            expectation.fulfill()
                                        }
                                    }
                                } catch {
                                    XCTAssert(false)
                                    expectation.fulfill()
                                }
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"FBT Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"FBT Test", horizonRequestError:error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 25.0)
    }
    
    
    func testGetFeeBumpTransactionDetails() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        
        sdk.transactions.getTransactionDetails(transactionHash: "5a270b978380f9ac264787bea669eeca523a32ef7b8e1f0f570a207776d33c7b") { (response) -> (Void) in
            switch response {
            case .success(let response):
                if let fbr = response.feeBumpTransactionResponse, let itr = response.innerTransactionResponse {
                    print("\nfee_bump-transaction: \(fbr.transactionHash)")
                    for signature in fbr.signatures {
                        print("signature: \(signature)")
                    }
                    print("\ninner_transaction: \(itr.transactionHash)")
                    for signature in itr.signatures {
                        print("signature: \(signature)")
                    }
                    print("max_fee: \(itr.maxFee)\n")
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GTD Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
