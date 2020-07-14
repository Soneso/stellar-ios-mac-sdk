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
        Federation.resolve(stellarAddress: "bob*soneso.com") { (response) -> (Void) in
            switch response {
            case .success(let federationResponse):
                XCTAssert("bob*soneso.com" == federationResponse.stellarAddress)
                XCTAssert("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" == federationResponse.accountId)
                XCTAssert("text" == federationResponse.memoType)
                XCTAssert("hello memo text" == federationResponse.memo)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testResolveStellarAccountId2() {
        
        let expectation = XCTestExpectation(description: "Resolve stellar account id")
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        federation.resolve(address: "bob*soneso.com") { (response) -> (Void) in
           switch response {
           case .success(let federationResponse):
               XCTAssert("bob*soneso.com" == federationResponse.stellarAddress)
               XCTAssert("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" == federationResponse.accountId)
               XCTAssert("text" == federationResponse.memoType)
               XCTAssert("hello memo text" == federationResponse.memo)
           case .failure(_):
               XCTAssert(false)
           }
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    // unfortunately this (account_id) is not supported by stellarid.io.
    // but one can test by debugging and checking the federation request url.
    func testResolveStellarAccountId() {
        
        let expectation = XCTestExpectation(description: "Resolve stellar account id")
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        federation.resolve(account_id: "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI") { (response) -> (Void) in
           switch response {
           case .success(let federationResponse):
               XCTAssert("bob*soneso.com" == federationResponse.stellarAddress)
               XCTAssert("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" == federationResponse.accountId)
               XCTAssert("text" == federationResponse.memoType)
               XCTAssert("hello memo text" == federationResponse.memo)
           case .failure(_):
               XCTAssert(false)
           }
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    // unfortunately this (transaction_id) is not supported by stellarid.io.
    // but one can test by debugging and checking the federation request url.
    func testResolveTransactionId() {
        
        let expectation = XCTestExpectation(description: "Resolve transaction id")
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        federation.resolve(transaction_id: "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a") { (response) -> (Void) in
           switch response {
           case .success(let federationResponse):
               XCTAssert("bob*soneso.com" == federationResponse.stellarAddress)
               XCTAssert("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" == federationResponse.accountId)
               XCTAssert("text" == federationResponse.memoType)
               XCTAssert("hello memo text" == federationResponse.memo)
           case .failure(_):
               XCTAssert(false)
           }
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    // unfortunately this (forward) is not supported by stellarid.io.
    // but one can test by debugging and checking the federation request url.
    func testResolveForward() {
        
        let expectation = XCTestExpectation(description: "Resolve forward")
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        
        var params = Dictionary<String,String>()
        params["forward_type"] = "bank_account"
        params["swift"] = "BOPBPHMM"
        params["acct"] = "2382376"
        
        federation.resolve(forwardParams: params) { (response) -> (Void) in
           switch response {
           case .success(let federationResponse):
               XCTAssert("bob*soneso.com" == federationResponse.stellarAddress)
               XCTAssert("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" == federationResponse.accountId)
               XCTAssert("text" == federationResponse.memoType)
               XCTAssert("hello memo text" == federationResponse.memo)
           case .failure(_):
               XCTAssert(false)
           }
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
