//
//  PaymentPathsTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/14/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PaymentPathsTestCase: XCTestCase {
    let sdk = StellarSDK()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetPaymentPathsForAccount() {
        let expectation = XCTestExpectation(description: "Get payment paths")
        
        sdk.paymentPaths.getPaymentPaths(destinationAccount:"GAEDTJ4PPEFVW5XV2S7LUXBEHNQMX5Q2GM562RJGOQG7GVCE5H3HIB4V", destinationAssetType: "credit_alphanum4", destinationAssetCode:"EUR", destinationAssetIssuer:"GDSBCQO34HWPGUGQSP3QBFEXVTSR2PW46UIGTHVWGWJGQKH3AFNHXHXN", destinationAmount:"20", sourceAccount:"GARSFJNXJIHO6ULUBK3DBYKVSIZE7SC72S5DYBCHU7DKL22UXKVD7MXP") { response in
            switch response {
            case .success(let paymentPathsResponse):
                // load next page
                paymentPathsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextPaymentPathsResponse):
                        // load previous page, should contain the same transactions as the first page
                        nextPaymentPathsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevPaymentPathsResponse):
                                let path1 = paymentPathsResponse.records.first
                                let path2 = prevPaymentPathsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(path1?.destinationAmount == path2?.destinationAmount)
                                XCTAssertTrue(path1?.sourceAmount == path2?.sourceAmount)
                                XCTAssertTrue(path1?.destinationAssetType == path2?.destinationAssetType)
                                XCTAssertTrue(path1?.destinationAssetCode == path2?.destinationAssetCode)
                                XCTAssertTrue(path1?.destinationAssetIssuer == path2?.destinationAssetIssuer)
                                XCTAssertTrue(path1?.sourceAssetType == path2?.sourceAssetType)
                                XCTAssertTrue(path1?.sourceAssetCode == path2?.sourceAssetCode)
                                XCTAssertTrue(path1?.sourceAssetIssuer == path2?.sourceAssetIssuer)
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
    
}
