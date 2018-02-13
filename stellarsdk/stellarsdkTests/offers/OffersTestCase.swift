//
//  OffersTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OffersTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetOffersForAccount() {
        let expectation = XCTestExpectation(description: "Get offers")
        
        sdk.offers.getOffers(forAccount: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX") { (response) -> (Void) in
            switch response {
            case .success(let offersResponse):
                // load next page
                offersResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextOffersResponse):
                        // load previous page, should contain the same transactions as the first page
                        nextOffersResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevOffersResponse):
                                let offer1 = offersResponse.records.first
                                let offer2 = prevOffersResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(offer1?.id == offer2?.id)
                                XCTAssertTrue(offer1?.pagingToken == offer2?.pagingToken)
                                XCTAssertTrue(offer1?.seller == offer2?.seller)
                                XCTAssertTrue(offer1?.buying == offer2?.buying)
                                XCTAssertTrue(offer1?.selling == offer2?.selling)
                                XCTAssertTrue(offer1?.amount == offer2?.amount)
                                XCTAssertTrue(offer1?.price == offer2?.price)
                                XCTAssertTrue(offer1?.priceR == offer2?.priceR)
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
