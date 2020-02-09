//
//  TradeAggregationsTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TradeAggregationsTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetTradeAggregations() {
        let expectation = XCTestExpectation(description: "Get trade aggregations response")
        
        sdk.tradeAggregations.getTradeAggregations(resolution: 86400000, baseAssetType: AssetTypeAsString.NATIVE, counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4, counterAssetCode: "IOM", counterAssetIssuer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII", order: Order.ascending, limit: 10) { (response) -> (Void) in
            switch response {
            case .success(let tradeAggregationsResponse):
                
                for tradeAggregation in tradeAggregationsResponse.records {
                    print("\(tradeAggregation.timestamp) is the timestamp")
                    print("\(tradeAggregation.tradeCount) is the trade count")
                    print("\(tradeAggregation.baseVolume) is the base volume")
                    print("\(tradeAggregation.counterVolume) is the counter volume")
                    print("\(tradeAggregation.averagePrice) is the average price")
                    print("\(tradeAggregation.highPrice) is the highest price")
                    print("\(tradeAggregation.lowPrice) is the lowest price")
                    print("\(tradeAggregation.openPrice) is the first aggregated trade price")
                    print("\(tradeAggregation.closePrice) is the last aggregated trade price")
                }
                
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GTA Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
}
