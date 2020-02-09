//
//  FeeStatsRemoteTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 09.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class FeeStatsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetFeeStats() {
        let expectation = XCTestExpectation(description: "Get fee stats successfully")
        
        sdk.feeStats.getFeeStats() { (response) -> (Void) in
            switch response {
            case .success(let feeStatsResponse):
                XCTAssertNotEqual("", feeStatsResponse.lastLedger)
                XCTAssertNotEqual("", feeStatsResponse.lastLedgerBaseFee)
                XCTAssertNotEqual("", feeStatsResponse.ledgerCapacityUsage)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.max)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.min)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p10)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p20)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p30)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p40)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p50)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p60)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p70)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p80)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p90)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p95)
                XCTAssertNotEqual("", feeStatsResponse.feeCharged.p99)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.max)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.min)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p10)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p20)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p30)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p40)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p50)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p60)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p70)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p80)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p90)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p95)
                XCTAssertNotEqual("", feeStatsResponse.maxFee.p99)
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load fee stats testcase", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
