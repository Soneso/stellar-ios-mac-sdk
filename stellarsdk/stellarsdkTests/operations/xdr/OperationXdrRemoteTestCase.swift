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
    
    /*func testSubmitTransaction() {
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
                if transactionsResponse.records.first != nil {
//                    transaction.transactionResult
                    expectation.fulfill()
                }
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func validateOperation(operationXDR: OperationResultXDR) {
        switch operationXDR {
        case .createAccount(let code, let createAccount):
            
        default:
            break
        }
        
    }*/
}

