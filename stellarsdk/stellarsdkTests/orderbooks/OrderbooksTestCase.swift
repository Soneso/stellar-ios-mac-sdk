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
    
    func testGetOrderbook() {
        let expectation = XCTestExpectation(description: "Get orderbook response and parse it successfully")
        
        sdk.orderbooks.getOrderbook(sellingAssetType: AssetTypeAsString.NATIVE, buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4, buyingAssetCode:"FOO", buyingAssetIssuer:"GCGBBRSKBPIQHGOPA5T637SQYHVGTKTIF6DUYZS34NLOUZNHI7JYBUNA", limit:10) { (response) -> (Void) in
            switch response {
            case .success(let orderbookResponse):
                
                for bid in orderbookResponse.bids {
                    print("GOB Test: \(bid.amount) is the bid amount")
                    print("GOB Test: \(bid.price) is the bid price")
                    print("GOB Test: \(bid.priceR) is the bid priceR")
                }
                for ask in orderbookResponse.asks {
                    print("GOB Test: \(ask.amount) is the ask amount")
                    print("GOB Test: \(ask.price) is the ask price")
                    print("GOB Test: \(ask.priceR) is the ask priceR")
                }
                print("GOB Test: \(orderbookResponse.buying) is the asset this offer wants to buy.")
                print("GOB Test: \(orderbookResponse.selling) is the asset this offer wants to sell.")
                
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOB Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
