//
//  OrderbooksTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OrderbooksTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrderbookLoadingSuccessful() {
        let expectation = XCTestExpectation(description: "Get orderbooks response")
        
        sdk.orderbooks.getOrderbook(sellingAssetType: AssetConstants.NATIVE, buyingAssetType: AssetConstants.CREDIT_ALPHANUM4, buyingAssetCode:"FOO", buyingAssetIssuer:"GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG", limit:10) { (response) -> (Void) in
            switch response {
            case .success(let orderbookResponse):
                
                for bid in orderbookResponse.bids {
                    print("\(bid.amount) is the bid amount")
                    print("\(bid.price) is the bid price")
                    print("\(bid.priceR) is the bid priceR")
                }
                for ask in orderbookResponse.asks {
                    print("\(ask.amount) is the ask amount")
                    print("\(ask.price) is the ask price")
                    print("\(ask.priceR) is the ask priceR")
                }
                print("\(orderbookResponse.buying) is the asset this offer wants to buy.")
                print("\(orderbookResponse.selling) is the asset this offer wants to sell.")
                
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
}
