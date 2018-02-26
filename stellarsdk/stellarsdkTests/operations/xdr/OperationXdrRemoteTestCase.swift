//
//  OperationXdrRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/23/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationXdrRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSubmitTransactionResultXdr() {
        let expectation = XCTestExpectation(description: "Get transaction details")
        let xdrEnvelope = "AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAByE3sAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAR+V72AAAABAAuiJ2+1FGpG7D+sS9qqZlk2/dsu8mdECuR1jiX9PaawJaJMETUP6u06cZgzrqopzmypJMOS/ob7BRvCQ3JkwDg=="
        
        sdk.transactions.postTransaction(transactionEnvelope: xdrEnvelope, response: { (response) -> (Void) in
            switch response {
            case .success(let response):
                if let resultBody = response.transactionResult.resultBody {
                    switch resultBody {
                    case .success(let operations):
                        self.validateOperation(operationXDR: operations.first!)
                        expectation.fulfill()
                    case .failed:
                        XCTAssert(false)
                    }
                }
            case .failure(_):
                XCTAssert(false)
            }
        })
        
        wait(for: [expectation], timeout: 25.0)
    }
    
    func testGetTransactionXdr() {
        let expectation = XCTestExpectation(description: "Get transaction xdr")
        
        sdk.transactions.getTransactions(limit:1) { (response) -> (Void) in
            switch response {
            case .success(let transactionsResponse):
                if let response = transactionsResponse.records.first {
                    if let resultBody = response.transactionResult.resultBody {
                        switch resultBody {
                        case .success(let operations):
                            self.validateOperation(operationXDR: operations.first!)
                            expectation.fulfill()
                        case .failed:
                            XCTAssert(false)
                        }
                    }
                }
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func validateOperation(operationXDR: OperationResultXDR) {
        switch operationXDR {
        case .createAccount(let code, _):
            XCTAssertEqual(code, CreateAccountResultCode.success.rawValue)
        case .payment(let code, _):
            XCTAssertEqual(code, PaymentResultCode.success.rawValue)
        case .pathPayment(let code, _):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
        case .manageOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .createPassiveOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .setOptions(let code, _):
            XCTAssertEqual(code, SetOptionsResultCode.success.rawValue)
        case .changeTrust(let code, _):
            XCTAssertEqual(code, ChangeTrustResultCode.success.rawValue)
        case .allowTrust(let code, _):
            XCTAssertEqual(code, AllowTrustResultCode.success.rawValue)
        case .accountMerge(let code, _):
            XCTAssertEqual(code, AccountMergeResultCode.success.rawValue)
        case .inflation(let code, _):
            XCTAssertEqual(code, InflationResultCode.success.rawValue)
        case .manageData(let code, _):
            XCTAssertEqual(code, ManageDataResultCode.success.rawValue)
        case .empty(let code):
            XCTAssertEqual(code, OperationResultCode.badAuth.rawValue)
        }
        
    }
    
    func testCreateAccountOperation() {
        let expectation = XCTestExpectation(description: "Create account operation")
        
        do {
            // GC5SIC4E3V56VOHJ3OZAX5SJDTWY52JYI2AFK6PUGSXFVRJQYQXXZBZF
            let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
            // GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR
            let destination = try KeyPair(secretSeed: "SDHZGHURAYXKU2KMVHPOXI6JG2Q4BSQUQCEOY72O3QQTCLR2T455PMII")
            let startAmount = Decimal(1000)
            
            let operation = CreateAccountOperation(sourceAccount: source, destination: destination, startBalance: startAmount)
            let operationXdr = try operation.toXDR()
            let parsedOperation = try Operation.fromXDR(operationXDR: operationXdr) as! CreateAccountOperation
            
            switch operationXdr.body {
            case .createAccount(let createAccountXdr):
                XCTAssertEqual(10000000000, createAccountXdr.startingBalance)
            default:
                break
            }
            XCTAssertEqual(source.accountId, parsedOperation.sourceAccount?.accountId)
            XCTAssertEqual(destination.accountId, parsedOperation.destination.accountId)
            XCTAssertEqual(startAmount, parsedOperation.startBalance)
            
            let base64 = try operation.toXDRBase64()
            XCTAssertEqual("AAAAAQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAAAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxAAAAACVAvkAA==", base64)
            
            expectation.fulfill()
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

