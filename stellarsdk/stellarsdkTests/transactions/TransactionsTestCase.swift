//
//  TransactionsTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionsTestCase: XCTestCase {
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
                                let transaction1 = transactionsResponse.transactions.first
                                let transaction2 = prevTransactionsResponse.transactions.last // because ordering is asc now.
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
        
        sdk.transactions.getTransactionDetails(transactionHash: "db8d0da33ff3b40d24ba80318e49cc256e64f4e79e3780100730f4f1695c3ff9") { (response) -> (Void) in
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
    
}
