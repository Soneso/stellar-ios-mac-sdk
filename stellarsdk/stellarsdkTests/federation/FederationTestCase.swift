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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testResolveStellarAddress() {
        
        let expectation = XCTestExpectation(description: "Resolve stellar address")
        Federation.resolve(stellarAddress: "stellar*lumenshine.com") { (response) -> (Void) in
            switch response {
            case .success(let federationResponse):
                if "GCM3C6QEQDEZLVDXJSCPOEWWU5LRBVOKQP4PIZLRAW444HKS67M2FFFR" == federationResponse.accountId {
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
   
        let expectation = XCTestExpectation(description: "Resolve account id")
        Federation.forDomain(domain: "lumenshine.com") { (response) -> (Void) in
            switch response {
            case .success(let federation):
                federation.resolve(account_id: "GCM3C6QEQDEZLVDXJSCPOEWWU5LRBVOKQP4PIZLRAW444HKS67M2FFFR") { (response) -> (Void) in
                    switch response {
                    case .success(let federationResponse):
                        if "stellar*lumenshine.com" == federationResponse.stellarAddress {
                            XCTAssert(true)
                        } else {
                            XCTAssert(false)
                        }
                    case .failure(_):
                        XCTAssert(false)
                    }
                    expectation.fulfill()
                }
            case .failure(_):
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testFederationInitWithFederationAddress() {
        
        let expectation = XCTestExpectation(description: "Init federation and resolve address")
        
        let federation = Federation(federationAddress: "https://api.lumenshine.com/federation")
        
        federation.resolve(address: "stellar*lumenshine.com") { (response) -> (Void) in
            switch response {
            case .success(let federationResponse):
                if "GCM3C6QEQDEZLVDXJSCPOEWWU5LRBVOKQP4PIZLRAW444HKS67M2FFFR" == federationResponse.accountId {
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
}
