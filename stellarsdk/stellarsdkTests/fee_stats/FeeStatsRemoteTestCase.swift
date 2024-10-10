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
    
    func testGetFeeStats() async {

        let response = await sdk.feeStats.getFeeStats()
        
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
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load fee stats testcase", horizonRequestError: error)
        }
    }
}
