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
            case .success(let effectsResponse):
                // load next page
                effectsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextEffectsResponse):
                        // load previous page, should contain the same effects as the first page
                        nextEffectsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevEffectsResponse):
                                let effect1 = effectsResponse.records.first
                                let effect2 = prevEffectsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(effect1?.id == effect2?.id)
                                XCTAssertTrue(effect1?.account == effect2?.account)
                                XCTAssertTrue(effect1?.effectType == effect2?.effectType)
                                XCTAssertTrue(effect1?.effectTypeString == effect2?.effectTypeString)
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
                 expectation.fulfill()
            }
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
        let expectation = XCTestExpectation(description: "Get effects for operation")
        
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
        let expectation = XCTestExpectation(description: "Get effects for ledger")
        
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
