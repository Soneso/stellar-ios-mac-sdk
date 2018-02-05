//
//  EffectsTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 05/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class EffectsTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetAllEffects() {
        let expectation = XCTestExpectation(description: "Get effects")
        
        sdk.effects.getEffects { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountEffects() {
        let expectation = XCTestExpectation(description: "Get effects for account")
        
        sdk.effects.getEffects(forAccount: "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationEffects() {
        let expectation = XCTestExpectation(description: "Get effects for account")
        
        sdk.effects.getEffects(forOperation: "10157597659137") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetLedgerEffects() {
        let expectation = XCTestExpectation(description: "Get effects for account")
        
        sdk.effects.getEffects(forLedger: "1") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTransactionEffects() {
        let expectation = XCTestExpectation(description: "Get effects for account")
        
        sdk.effects.getEffects(forTransaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
}
