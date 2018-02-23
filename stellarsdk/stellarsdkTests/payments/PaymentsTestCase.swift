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
        
        sdk.payments.getPayments (forAccount: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX") { (response) -> (Void) in
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
        
        sdk.payments.getPayments(forLedger: "1") { (response) -> (Void) in
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
        
        sdk.payments.getPayments(forTransaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a") { (response) -> (Void) in
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
        
        sdk.payments.stream(for: .paymentsForAccount(account: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX", cursor: nil)).onReceive { (response) -> (Void) in
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
