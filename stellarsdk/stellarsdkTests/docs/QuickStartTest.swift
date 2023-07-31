//
//  ExamplesTest.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 11.12.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class QuickStartTest: XCTestCase {
    let sdk = StellarSDK()
    

    func testFriendbotExample() {
        
        let expectation = XCTestExpectation(description: "friendbot creates account by using the code from quickstart guide")
        
        // prepare
        let keyPair = try! KeyPair.generateRandomKeyPair()
        print("Account Id: " + keyPair.accountId)
        print("Secret Seed: " + keyPair.secretSeed)
        
        // EXAMPLE CODE START
        sdk.accounts.createTestAccount(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let details):
                print(details)
                expectation.fulfill()
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
        // EXAMPLE CODE END
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testCreateAccountExample() {
        
        let expectation = XCTestExpectation(description: "creates account by using the code from quickstart guide")
        
        // prepare
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        sdk.accounts.createTestAccount(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                
                self.sdk.accounts.getAccountDetails(accountId: sourceAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        // EXAMPLE CODE START
                        // build the operation
                        let createAccount = try CreateAccountOperation(sourceAccountId: nil,
                                                                   destinationAccountId: destinationAccountId,
                                                                   startBalance: 2.0)

                        // build the transaction
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                             operations: [createAccount],
                                                             memo: Memo.none)
                                                             
                        // sign the transaction
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                                                
                        // submit the transaction
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let result):
                                print(result.transactionHash)
                                expectation.fulfill()
                            case .destinationRequiresMemo(_):
                                XCTFail()
                            case .failure(let error):
                                print(error.localizedDescription)
                                XCTFail()
                            }
                        }
                        // EXAMPLE CODE END
                    } catch {
                        XCTFail()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    XCTFail()
                }
            }
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testCheckAccountExample() {
        let expectation = XCTestExpectation(description: "fatches the account details by using the code from quickstart guide")
        
        // prepare
        let keyPair = try! KeyPair.generateRandomKeyPair()
        
        sdk.accounts.createTestAccount(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                // EXAMPLE CODE START
                self.sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountDetails):
                        
                        // You can check the `balance`, `sequence`, `flags`, `signers`, `data` etc.
                        
                        for balance in accountDetails.balances {
                            switch balance.assetType {
                            case AssetTypeAsString.NATIVE:
                                print("balance: \(balance.balance) XLM")
                            default:
                                print("balance: \(balance.balance) \(balance.assetCode!) issuer: \(balance.assetIssuer!)")
                            }
                        }

                        print("sequence number: \(accountDetails.sequenceNumber)")

                        for signer in accountDetails.signers {
                            print("signer public key: \(signer.key)")
                        }

                        print("auth required: \(accountDetails.flags.authRequired)")
                        print("auth revocable: \(accountDetails.flags.authRevocable)")

                        for (key, value) in accountDetails.data {
                            print("data key: \(key) value: \(value.base64Decoded() ?? "")")
                        }
                        expectation.fulfill()
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                // EXAMPLE CODE END
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
    
        wait(for: [expectation], timeout: 25.0)
    }
    
    func testCheckPaymentsExample() {
        let expectation = XCTestExpectation(description: "fatches payments by using the code from quickstart guide")
        
        // EXAMPLE CODE START
        sdk.payments.getPayments(order:Order.descending, limit:10) { response in
            switch response {
            case .success(let paymentsResponse):
                for payment in paymentsResponse.records {
                    if let nextPayment = payment as? PaymentOperationResponse {
                        if (nextPayment.assetType == AssetTypeAsString.NATIVE) {
                            print("received: \(nextPayment.amount) lumen" )
                        } else {
                            print("received: \(nextPayment.amount) \(nextPayment.assetCode!)" )
                        }
                        print("from: \(nextPayment.from)" )
                    }
                    else if let nextPayment = payment as? AccountCreatedOperationResponse {
                        print("account \(nextPayment.account) created by \(nextPayment.funder)" )
                    }
                }
                expectation.fulfill()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        // EXAMPLE CODE END
    
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testCheckPaymentsForAccountExample() {
        let expectation = XCTestExpectation(description: "fatches the account payments by using the code from quickstart guide")
        
        // prepare
        let keyPair = try! KeyPair.generateRandomKeyPair()
        
        sdk.accounts.createTestAccount(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                // EXAMPLE CODE START
                self.sdk.payments.getPayments(forAccount:keyPair.accountId, order:Order.descending, limit:10) { response in
                // EXAMPLE CODE END
                    switch response {
                    case .success(let paymentsResponse):
                        for payment in paymentsResponse.records {
                            if let nextPayment = payment as? AccountCreatedOperationResponse {
                                print("account \(nextPayment.account) created by \(nextPayment.funder)" )
                            }
                        }
                        expectation.fulfill()
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                // EXAMPLE CODE END
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
    
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStreamPaymentsForAccountExample() {
        let expectation = XCTestExpectation(description: "streams payments for account by using the code from quickstart guide")
        
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        // EXAMPLE CODE START
        let streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountId, cursor: "now"))
        streamItem.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(let id, let operationResponse):
                if let paymentResponse = operationResponse as? PaymentOperationResponse {
                    switch paymentResponse.assetType {
                    case AssetTypeAsString.NATIVE:
                        print("Payment of \(paymentResponse.amount) XLM from \(paymentResponse.sourceAccount) received -  id \(id)" )
                    default:
                        print("Payment of \(paymentResponse.amount) \(paymentResponse.assetCode!) from \(paymentResponse.sourceAccount) received -  id \(id)" )
                    }
                    streamItem.closeStream()
                    expectation.fulfill()
                }
            case .error(let err):
                    print(err?.localizedDescription ?? "Error")
            }
        }
        // EXAMPLE CODE END
        
        sdk.accounts.createTestAccount(accountId: sourceAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: destinationAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                            switch response {
                            case .success(let accountResponse):
                                
                                let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountId,
                                                                        destinationAccountId: destinationAccountId,
                                                                        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                        amount: 1.5)
                                
                                let transaction = try! Transaction(sourceAccount: accountResponse,
                                                                  operations: [paymentOperation],
                                                                  memo: Memo.init(text: "test"))
                                try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                                
                                try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                    switch response {
                                    case .success(let response):
                                        print("testSendAndReceiveNativePayment: Transaction successfully sent. Hash \(response.transactionHash)")
                                    default:
                                        XCTFail()
                                    }
                                }
                            case .failure(_):
                                XCTFail()
                            }
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                        XCTFail()
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 25.0)
    }
    
    func testSendPaymentExample() {
        let expectation = XCTestExpectation(description: "sends a payment by using the code from quickstart guide")
        
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        sdk.accounts.createTestAccount(accountId: sourceAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: destinationAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                            switch response {
                            case .success(let accountResponse):
                                do {
                                    // EXAMPLE CODE STARTS HERE
                                    let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountId,
                                                                            destinationAccountId: destinationAccountId,
                                                                            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                            amount: 1.5)
                                    
                                    let transaction = try Transaction(sourceAccount: accountResponse,
                                                                      operations: [paymentOperation],
                                                                      memo: Memo.none)
                                    try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                                    
                                    try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                        switch response {
                                        case .success(let response):
                                            print("Transaction successfully sent. Hash \(response.transactionHash)")
                                            expectation.fulfill()
                                        default:
                                            XCTFail()
                                        }
                                    }
                                    // EXAMPLE CODE ENDS HERE
                                } catch {
                                    XCTFail()
                                }
                            case .failure(_):
                                XCTFail()
                            }
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                        XCTFail()
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 25.0)
    }
    
    func testTransactionEnvelopeFromXDRExample() {
        let xdrString = "AAAAAJ/Ax+axve53/7sXfQY0fI6jzBeHEcPl0Vsg1C2tqyRbAAAAZAAAAAAAAAAAAAAAAQAAAABb2L/OAAAAAFvYwPoAAAAAAAAAAQAAAAEAAAAAo7FW8r8Nj+SMwPPeAoL4aUkLob7QU68+9Y8CAia5k78AAAAKAAAAN0NJcDhiSHdnU2hUR042ZDE3bjg1ZlFGRVBKdmNtNFhnSWhVVFBuUUF4cUtORVd4V3JYIGF1dGgAAAAAAQAAAEDh/7kQjZbcXypISjto5NtGLuaDGrfL/F08apZQYp38JNMNQ9p/e1Fy0z23WOg/Ic+e91+hgbdTude6+1+i0V41AAAAAA=="
        do {
            // Get the transaction object
            let transaction = try Transaction(xdr:xdrString)
            // Convert your transaction back to xdr
            let transactionString = transaction.xdrEncoded
            XCTAssertEqual(transactionString, xdrString)
        } catch {
            print("Invalid xdr string")
        }
    }
    
    func testGenerateURIForSignTransaction() {
        let expectation = XCTestExpectation(description: "generates uri for sign transaction using the code from quickstart guide")
        
        // prepare
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        sdk.accounts.createTestAccount(accountId: sourceAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.getAccountDetails(accountId: sourceAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(let accountResponse):
                        do {
                            // EXAMPLE CODE START
                            // create the payment operation
                            let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountId,
                                                                    destinationAccountId: destinationAccountId,
                                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                    amount: 1.5)
                            
                            // create the transaction containing the payment operation
                            let transaction = try Transaction(sourceAccount: accountResponse,
                                                              operations: [paymentOperation],
                                                              memo: Memo.none)
                            // create the URIScheme object
                            let uriSchemeBuilder = URIScheme()
                            
                            // get the URI with your transactionXDR
                            // more params can be added to the url, check method definition
                            let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction.transactionXDR, callBack: "your_callback_api.com")
                            print (uriScheme);
                            // EXAMPLE CODE END
                            expectation.fulfill()
                        } catch {
                            XCTFail()
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail()
            }
        }
    
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGenerateURIForPayment() {
        let uriSchemeBuilder = URIScheme()
        
        let uriScheme = uriSchemeBuilder.getPayOperationURI(destination: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q", amount: 100, assetCode: "BTC", assetIssuer:"GC2PIUYXSD23UVLR5LZJPUMDREQ3VTM23XVMERNCHBRTRVFKWJUSRON5", callBack: "your_callback_api.com")

        print(uriScheme);
    }

}
