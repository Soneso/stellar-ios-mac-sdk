//
//  OperationsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetOperations() {
        let expectation = XCTestExpectation(description: "Get operations and parse their details successfully")
        
        sdk.operations.getOperations { (response) -> (Void) in
            switch response {
            case .success(let operationsResponse):
                // load next page
                operationsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextOperationsResponse):
                        // load previous page, should contain the same operations as the first page
                        nextOperationsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevOperationsResponse):
                                let operation1 = operationsResponse.records.first
                                let operation2 = prevOperationsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(operation1?.id == operation2?.id)
                                XCTAssertTrue(operation1?.sourceAccount == operation2?.sourceAccount)
                                XCTAssertTrue(operation1?.sourceAccount == operation2?.sourceAccount)
                                XCTAssertTrue(operation1?.operationTypeString == operation2?.operationTypeString)
                                XCTAssertTrue(operation1?.operationType == operation2?.operationType)
                                XCTAssertTrue(operation1?.createdAt == operation2?.createdAt)
                                XCTAssertTrue(operation1?.transactionHash == operation2?.transactionHash)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GO Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GO Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GO Test", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForAccount() {
        let expectation = XCTestExpectation(description: "Get operations for account")
        
        sdk.operations.getOperations(forAccount: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFA Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForLedger() {
        let expectation = XCTestExpectation(description: "Get operations for ledger")
        
        sdk.operations.getOperations(forLedger: "1") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFL Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForTransaction() {
        let expectation = XCTestExpectation(description: "Get operations for transaction")
        
        sdk.operations.getOperations(forTransaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFT Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationDetails() {
        let expectation = XCTestExpectation(description: "Get operation details")
        
        sdk.operations.getOperationDetails(operationId: "10157597659137") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOD Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }

/*
    func testOperationsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .allOperations(cursor: nil)).onReceive { (response) -> (Void) in
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
    func testOperationsForAccountStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .operationsForAccount(account: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX", cursor: nil)).onReceive { (response) -> (Void) in
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
    
    func testOperationsForLedgerStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .operationsForLedger(ledger: "2365", cursor: nil)).onReceive { (response) -> (Void) in
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
    
    func testOperationsForTransactionsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .operationsForTransaction(transaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a", cursor: nil)).onReceive { (response) -> (Void) in
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
