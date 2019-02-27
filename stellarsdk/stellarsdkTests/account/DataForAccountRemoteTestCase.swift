//
//  DataForAccountRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class DataForAccountRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    let testSuccessPrivateKey = "SDBLUM623VOIEQWXD5FN6K7HOU5GUKUGD6SGWTW2BB3PPD5GVFG7RZU5"
    let testSuccessAccountId = "GBGZOWY7AVV4EPEB6OOWWLPHS6CP62W5AENP7CW52G6UTBJYEYJMHCIM"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetDataForAccount() {
        let expectation = XCTestExpectation(description: "Get data value for a given account and key")
        sdk.accounts.getDataForAccount(accountId: testSuccessAccountId, key:"soneso") { (response) -> (Void) in
            switch response {
            case .success(let dataForAccount):
                XCTAssertEqual(dataForAccount.value.base64Decoded(), "is fun")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GDFA testcase", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}

