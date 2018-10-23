//
//  FederationTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 23/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class FederationTestCase: XCTestCase {
    
    let federationServer = "http://127.0.0.1:8000"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFederationForDomain() {
        let expectation = XCTestExpectation(description: "Get federation for a domain")
        
        Federation.forDomain(domain: "https://demo.lumenshine.com/") { (response) -> (Void) in
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
    
    func testResolveAddress() {
        let federation = Federation(federationAddress: federationServer)
        
        let expectation = XCTestExpectation(description: "Resolve federation address")
        federation.resolve(address: "bob*demo.lumenshine.com") { (response) -> (Void) in
            switch response {
            case .success(let federationResponse):
                if let _ = federationResponse.accountId {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testResolveAccountId() {
        let federation = Federation(federationAddress: federationServer)
        
        let expectation = XCTestExpectation(description: "Resolve account id")
        federation.resolve(account_id: "GAXQIFFSOX3HMHMM3KSSYG6ZO2MN3FPPAZA4IPHAEGHNE4SR5TX53BYK") { (response) -> (Void) in
            switch response {
            case .success(let federationResponse):
                if let _ = federationResponse.stellarAddress {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testResolveStellarAddress() {
        let expectation = XCTestExpectation(description: "Resolve account id")
        Federation.resolve(stellarAddress: "bob*demo.lumenshine.com") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(_):
                XCTAssert(true)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
