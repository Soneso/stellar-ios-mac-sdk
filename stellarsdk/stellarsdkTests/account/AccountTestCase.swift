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
    
    func testAccountNotFoundOnHorizon() {
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
    
    func testLoadAccountFromHorizon() {
        let expectation = XCTestExpectation(description: "Get account details response")
        
        //TODO: replace this with an account created in this testcase as soon as account creation is available.
        let testAccountId = "GBZ3VAAP2T2WMKF6226FTC6OSQN6KKGAGPVCCCMDDVLCHYQMXTMNHLB3"
        
        sdk.accounts.getAccountDetails(accountId: testAccountId) { (response) -> (Void) in
            switch response {
            case .success(let accountDetails):
                XCTAssertEqual(testAccountId, accountDetails.id)
                XCTAssertNotNil(accountDetails.sequenceNumber)
                XCTAssertNotNil(accountDetails.links)
                XCTAssertNotNil(accountDetails.links.selflink)
                XCTAssertNotNil(accountDetails.links.selflink.href)
                XCTAssertNil(accountDetails.links.selflink.templated)
                XCTAssertNotNil(accountDetails.links.transactions)
                XCTAssertNotNil(accountDetails.links.transactions.href)
                XCTAssertNotNil(accountDetails.links.transactions.templated)
                XCTAssertNotNil(accountDetails.links.operations)
                XCTAssertNotNil(accountDetails.links.operations.href)
                XCTAssertNotNil(accountDetails.links.operations.templated)
                XCTAssertNotNil(accountDetails.links.payments)
                XCTAssertNotNil(accountDetails.links.payments.href)
                XCTAssertNotNil(accountDetails.links.payments.templated)
                XCTAssertNotNil(accountDetails.links.effects)
                XCTAssertNotNil(accountDetails.links.effects.href)
                XCTAssertNotNil(accountDetails.links.effects.templated)
                XCTAssertNotNil(accountDetails.links.offers)
                XCTAssertNotNil(accountDetails.links.offers.href)
                XCTAssertNotNil(accountDetails.links.offers.templated)
                XCTAssertNotNil(accountDetails.pagingToken)
                XCTAssertNotNil(accountDetails.subentryCount)
                XCTAssertNotNil(accountDetails.thresholds)
                XCTAssertNotNil(accountDetails.thresholds.highThreshold)
                XCTAssertNotNil(accountDetails.thresholds.lowThreshold)
                XCTAssertNotNil(accountDetails.thresholds.medThreshold)
                XCTAssertNotNil(accountDetails.flags)
                XCTAssertNotNil(accountDetails.flags.authRequired)
                XCTAssertNotNil(accountDetails.flags.authRevocable)
                XCTAssertNotNil(accountDetails.flags.authImmutable)
                
                XCTAssertNotNil(accountDetails.balances)
                XCTAssertTrue(accountDetails.balances.count > 0)
                for balance in accountDetails.balances {
                    XCTAssertNotNil(balance)
                    XCTAssertNotNil(balance.assetType)
                    XCTAssertNotNil(balance.balance)
                    
                    if balance.assetType == AssetType.NATIVE {
                        XCTAssertNil(balance.assetCode)
                        XCTAssertNil(balance.assetIssuer)
                    } else {
                        XCTAssertNotNil(balance.assetCode)
                        XCTAssertNotNil(balance.assetIssuer)
                    }
                    
                    // TODO: what about limit? can it be nil for an asset code different than native?
                }
                
                XCTAssertNotNil(accountDetails.signers)
                XCTAssertTrue(accountDetails.signers.count > 0)
                for signer in accountDetails.signers {
                    XCTAssertNotNil(signer)
                    XCTAssertNotNil(signer.publicKey)
                    XCTAssertNotNil(signer.weight)
                }
                
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
}
