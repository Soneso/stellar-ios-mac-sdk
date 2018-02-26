//
//  DataForAccountLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class DataForAccountLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var dataForAccountResponsesMock: DataForAccountResponsesMock? = nil
    var mockRegistered = false
    let testSuccessAccountId = "GBZ3VAAP2T2WMKF6226FTC6OSQN6KKGAGPVCCCMDDVLCHYQMXTMNHLB3"
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        dataForAccountResponsesMock = DataForAccountResponsesMock()
        let sonesoValue = """
                    {
                        "value": "aXMgZnVu"
                    }
                    """
        dataForAccountResponsesMock?.addDataEntry(accountId:testSuccessAccountId, key:"soneso", value: sonesoValue)
        
    }
    
    override func tearDown() {
        dataForAccountResponsesMock = nil
        super.tearDown()
    }
    
    func testAccountNotFound() {
        let expectation = XCTestExpectation(description: "Get error response")
        
        sdk.accounts.getDataForAccount(accountId: "AAAAA", key: "soneso") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound( _, _):
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testKeyNotFound() {
        let expectation = XCTestExpectation(description: "Get error response")
        
        sdk.accounts.getDataForAccount(accountId: testSuccessAccountId, key: "stellar") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound( _, _):
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetDataForAccount() {
        let expectation = XCTestExpectation(description: "Get value for a given account and key")
        
        sdk.accounts.getDataForAccount(accountId: testSuccessAccountId, key:"soneso") { (response) -> (Void) in
            switch response {
                case .success(let dataForAccount):
                    XCTAssertEqual(dataForAccount.value.base64Decoded(), "is fun")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"GDFA Test", horizonRequestError: error)
                    XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
