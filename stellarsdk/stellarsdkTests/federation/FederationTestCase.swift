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
        
    func testResolveStellarAddress() async {
        let responseEnum = await Federation.resolve(stellarAddress: "bob*soneso.com")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*soneso.com", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testResolveStellarAccountId2() async {
        
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        let responseEnum = await federation.resolve(address: "bob*soneso.com")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*soneso.com", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testResolveStellarAccountId() async {
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        let responseEnum = await federation.resolve(account_id: "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*soneso.com", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(_):
            XCTFail()
        }
    }
    
    // unfortunately this (transaction_id) is not supported by stellarid.io.
    // but one can test by debugging and checking the federation request url.
    func testResolveTransactionId() async {
        
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        let responseEnum = await federation.resolve(transaction_id: "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*soneso.com", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(_):
            XCTFail()
        }
    }
    
    // unfortunately this (forward) is not supported by stellarid.io.
    // but one can test by debugging and checking the federation request url.
    func testResolveForward() async {
        
        let federation = Federation(federationAddress: "https://stellarid.io/federation/")
        
        var params = Dictionary<String,String>()
        params["forward_type"] = "bank_account"
        params["swift"] = "BOPBPHMM"
        params["acct"] = "2382376"
        
        let responseEnum = await federation.resolve(forwardParams: params)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*soneso.com", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(_):
            XCTFail()
        }
    }
}
