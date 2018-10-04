//
//  PriceTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/15/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PriceTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPriceFromString() {
        let price1 = Price.fromString(price: "3.6666666666666666666666666666666")
        print("\(price1.n) is the price numerator")
        print("\(price1.d) is the price denominator")
        let price2 = Price(numerator: 11, denominator: 3)
        let price3 = Price(numerator: -11, denominator: -3)
        if price1 == price2 || price1 == price3 {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
}
