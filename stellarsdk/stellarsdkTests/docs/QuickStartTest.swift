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
    

    func testFriendbotExample() async {
        
        // prepare
        let keyPair = try! KeyPair.generateRandomKeyPair()
        print("Account Id: " + keyPair.accountId)
        print("Secret Seed: " + keyPair.secretSeed)
        
        // EXAMPLE CODE START
        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(let details):
            print(details)
        case .failure(let error):
            print(error.localizedDescription)
            XCTFail()
        }
        // EXAMPLE CODE END
    }
    
    func testCreateAccountExample() async {
    
        // prepare
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountKeyPair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountKeyPair.accountId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
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
                
                let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
                switch submitTxResponse {
                case .success(let details):
                    XCTAssert(details.operationCount > 0)
                    print(details.transactionHash)
                case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                    XCTFail("destination account \(destinationAccountId) requires memo")
                case .failure(error: let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
                    XCTFail("submit transaction error")
                }
                // EXAMPLE CODE END
            } catch {
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCreateAccountExample()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func testCheckAccountExample() async {
        // prepare
        let keyPair = try! KeyPair.generateRandomKeyPair()
        
        let responseEnum = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(keyPair.accountId)")
        }
        
        // EXAMPLE CODE START
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId);
        switch accDetailsResEnum {
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
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCheckAccountExample()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
        // EXAMPLE CODE END
    }
    
    func testCheckPaymentsExample() async {

        // EXAMPLE CODE START
        let responseEnum = await sdk.payments.getPayments(order:Order.descending, limit:10)
        switch responseEnum {
        case .success(let page):
            for payment in page.records {
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
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCheckPaymentsExample()", horizonRequestError: error)
            XCTFail("could not load payments")
        }
        // EXAMPLE CODE END
    }
    
    func testCheckPaymentsForAccountExample() async {
        
        // prepare
        let keyPair = try! KeyPair.generateRandomKeyPair()
        
        let responseEnum = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(keyPair.accountId)")
        }
        
        // EXAMPLE CODE START
        let response = await sdk.payments.getPayments(forAccount:keyPair.accountId, order:Order.descending, limit:10)
        switch response {
        case .success(let page):
            for payment in page.records {
                if let nextPayment = payment as? AccountCreatedOperationResponse {
                    print("account \(nextPayment.account) created by \(nextPayment.funder)" )
                }
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCheckPaymentsForAccountExample()", horizonRequestError: error)
            XCTFail("could not load payments")
        }
        // EXAMPLE CODE END
    }
    
    func testStreamPaymentsForAccountExample() async {
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
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create source account: \(sourceAccountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: destinationAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create destination account: \(destinationAccountId)")
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountId,
                                                    destinationAccountId: destinationAccountId,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 1.5)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [paymentOperation],
                                              memo: Memo.init(text: "test"))
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
                print("testSendAndReceiveNativePayment: Transaction successfully sent. Hash \(result.transactionHash)")
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamPaymentsForAccountExample()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamPaymentsForAccountExample()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func testSendPaymentExample() async {
        
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create source account: \(sourceAccountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: destinationAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create destination account: \(destinationAccountId)")
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountId)
        switch accDetailsEnum {
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
                let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitTxResultEnum {
                case .success(let result):
                    XCTAssertTrue(result.operationCount > 0)
                    print("testSendAndReceiveNativePayment: Transaction successfully sent. Hash \(result.transactionHash)")
                case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                    XCTFail("destination account \(destinationAccountId) requires memo")
                case .failure(error: let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testSendPaymentExample()", horizonRequestError: error)
                    XCTFail("submit transaction error")
                }
                // EXAMPLE CODE ENDS HERE
            } catch {
                XCTFail()
            }
            
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testSendPaymentExample()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountId)")
        }
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
    
    func testGenerateURIForSignTransaction() async {
    
        // prepare
        let sourceAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let sourceAccountId = sourceAccountKeyPair.accountId
        let destinationAccountKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationAccountId = destinationAccountKeyPair.accountId
        
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create source account: \(sourceAccountId)")
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountId)
        switch accDetailsEnum {
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
            } catch {
                XCTFail()
            }
            
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGenerateURIForSignTransaction()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountId)")
        }
    }
    
    func testGenerateURIForPayment() {
        let uriSchemeBuilder = URIScheme()
        
        let uriScheme = uriSchemeBuilder.getPayOperationURI(destination: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q", amount: 100, assetCode: "BTC", assetIssuer:"GC2PIUYXSD23UVLR5LZJPUMDREQ3VTM23XVMERNCHBRTRVFKWJUSRON5", callBack: "your_callback_api.com")

        print(uriScheme);
    }

}
