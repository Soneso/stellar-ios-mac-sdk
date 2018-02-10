//
//  TradesTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TradesTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTradesLoadingSuccessful() {
        let expectation = XCTestExpectation(description: "Get trades response")
        
        sdk.trades.getTrades(limit: 10) { (response) -> (Void) in
            switch response {
            case .success(let tradesResponse):
                
                for trade in tradesResponse.trades {
                    print("\(trade.baseAccount) is the base account")
                    print("\(trade.baseAmount) is the base amount code")
                    print("\(trade.baseAssetType) is the base asset type")
                    print("\(trade.counterAccount) is the counter account")
                    print("\(trade.counterAmount) is the counter amount")
                    print("\(trade.counterAssetType) is the counter asset type")
                    print("\(trade.pagingToken) is the paging token")
                    print("\(trade.baseIsSeller) the base is seller")
                    print("\(trade.ledgerCloseTime) is the ledger close time")
                }
                
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
}
