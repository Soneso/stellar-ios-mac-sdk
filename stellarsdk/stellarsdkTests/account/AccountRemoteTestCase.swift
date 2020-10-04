//
//  AccountRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class AccountRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    let accountId = "GDQ7DUQ2KA5SZH5ZSBO7GNSG2XOGM5NVT5AWJQZRB2HCYGOTQ5VQ4QOH"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetAccountDetails() {
        
        let expectation = XCTestExpectation(description: "Get account details and parse them successfully")
        
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountDetails):
                print("Account-ID: \(accountDetails.accountId)")
                print("Sequence Nr: \(accountDetails.sequenceNumber)")
                for balance in accountDetails.balances {
                    print("Balance \(balance.balance)")
                }
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Get account details test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountsByAsset() {
        let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
        
        sdk.accounts.getAccounts(signer: nil, asset: "RICH:GALA3JYOCVM4ENFPXMMXQBFGTQZKWRIOAVZSHGGNUVC4KOGOB3A4EFGZ", cursor: nil, order: Order.descending, limit: 2) { (response) -> (Void) in
            switch response {
            case .success(let accountsResponse):
                // load next page
                accountsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextAccountsResponse):
                        // load previous page, should contain the same accounts as the first page
                        nextAccountsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevAccountsResponse):
                                let account1 = accountsResponse.records.first
                                let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                                XCTAssertNotNil(account1);
                                XCTAssertNotNil(account2);
                                XCTAssertTrue(account1?.accountId == account2?.accountId)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountsBySigner() {
        let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
        
        sdk.accounts.getAccounts(signer: "GALA3JYOCVM4ENFPXMMXQBFGTQZKWRIOAVZSHGGNUVC4KOGOB3A4EFGZ", asset:nil, cursor: nil, order: Order.descending, limit: 2) { (response) -> (Void) in
            switch response {
            case .success(let accountsResponse):
                // load next page
                accountsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextAccountsResponse):
                        // load previous page, should contain the same accounts as the first page
                        nextAccountsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevAccountsResponse):
                                let account1 = accountsResponse.records.first
                                let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                                XCTAssertNotNil(account1);
                                XCTAssertNotNil(account2);
                                XCTAssertTrue(account1?.accountId == account2?.accountId)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountsBySponsor() {
        let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
        
        sdk.accounts.getAccounts(sponsor: "GALA3JYOCVM4ENFPXMMXQBFGTQZKWRIOAVZSHGGNUVC4KOGOB3A4EFGZ", cursor: nil, order: Order.descending, limit: 5) { (response) -> (Void) in
            switch response {
            case .success(let accountsResponse):
                print("sponsored accounts:\(accountsResponse.records.count)")
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
