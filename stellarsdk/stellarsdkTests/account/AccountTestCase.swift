//
//  AccountTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AccountTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testKeyGeneration() {
        let keyPair = try! KeyPair.generateRandomKeyPair()
        XCTAssert(keyPair.publicKey.bytes.count == 32, "Public key length is incorrect")
        XCTAssert(keyPair.privateKey.bytes.count == 64, "Private key length is incorrect")
    }
    
    func testAccountDetailsInvalid() {
        let expectation = XCTestExpectation(description: "Get account details response")
        
        sdk.accounts.getAccountDetails(accountId: "AAAAA") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .accountNotFound(_):
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAccountDetailsSuccessful() {
        let expectation = XCTestExpectation(description: "Get account details response")
        
        sdk.accounts.getAccountDetails(accountId: "GBZ3VAAP2T2WMKF6226FTC6OSQN6KKGAGPVCCCMDDVLCHYQMXTMNHLB3") { (response) -> (Void) in
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
