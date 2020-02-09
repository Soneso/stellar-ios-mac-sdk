//
//  AccountRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class AccountRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    let testSuccessAccountId = "GD7RK5UAKK3U2F5ZM7JSELONZ6MYONDDJWV3DGKENJVUQB52DR3FYVK3"
    // priv SASX3JBZNVS4HKL2TZJPOO3VIQRRZPIAOBZTFMT22LWGUMOHMFXU2ZZ4 // for testing
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetAccountDetails() {
        
        let expectation = XCTestExpectation(description: "Get account details and parse them successfully")
        
        
        sdk.accounts.getAccountDetails(accountId: testSuccessAccountId) { (response) -> (Void) in
            switch response {
            case .success(let accountDetails):
                XCTAssertEqual(self.testSuccessAccountId, accountDetails.accountId)
                XCTAssertNotNil(accountDetails.sequenceNumber)
                //XCTAssertEqual(accountDetails.sequenceNumber, 516375328063489)
                XCTAssertNotNil(accountDetails.links)
                XCTAssertNotNil(accountDetails.links.selflink)
                XCTAssertNotNil(accountDetails.links.selflink.href)
                XCTAssertEqual(accountDetails.links.selflink.href, "https://horizon-testnet.stellar.org/accounts/\(accountDetails.accountId)")
                XCTAssertNil(accountDetails.links.selflink.templated)
                XCTAssertNotNil(accountDetails.links.transactions)
                XCTAssertNotNil(accountDetails.links.transactions.href)
                XCTAssertEqual(accountDetails.links.transactions.href, "https://horizon-testnet.stellar.org/accounts/\(accountDetails.accountId)/transactions{?cursor,limit,order}")
                XCTAssertTrue(accountDetails.links.transactions.templated ?? false)
                XCTAssertNotNil(accountDetails.links.operations)
                XCTAssertNotNil(accountDetails.links.operations.href)
                XCTAssertEqual(accountDetails.links.operations.href, "https://horizon-testnet.stellar.org/accounts/\(accountDetails.accountId)/operations{?cursor,limit,order}")
                XCTAssertTrue(accountDetails.links.operations.templated ?? false)
                XCTAssertNotNil(accountDetails.links.payments)
                XCTAssertNotNil(accountDetails.links.payments.href)
                XCTAssertEqual(accountDetails.links.payments.href, "https://horizon-testnet.stellar.org/accounts/\(accountDetails.accountId)/payments{?cursor,limit,order}")
                XCTAssertTrue(accountDetails.links.payments.templated ?? false)
                XCTAssertNotNil(accountDetails.links.effects)
                XCTAssertNotNil(accountDetails.links.effects.href)
                XCTAssertEqual(accountDetails.links.effects.href, "https://horizon-testnet.stellar.org/accounts/\(accountDetails.accountId)/effects{?cursor,limit,order}")
                XCTAssertTrue(accountDetails.links.effects.templated ?? false)
                XCTAssertNotNil(accountDetails.links.offers)
                XCTAssertNotNil(accountDetails.links.offers.href)
                XCTAssertEqual(accountDetails.links.offers.href, "https://horizon-testnet.stellar.org/accounts/\(accountDetails.accountId)/offers{?cursor,limit,order}")
                XCTAssertTrue(accountDetails.links.offers.templated ?? false)
                //XCTAssertEqual(accountDetails.pagingToken, "")
                //XCTAssertEqual(accountDetails.subentryCount, 2)
                XCTAssertNotNil(accountDetails.thresholds)
                XCTAssertEqual(accountDetails.thresholds.highThreshold, 0)
                XCTAssertEqual(accountDetails.thresholds.lowThreshold, 0)
                XCTAssertEqual(accountDetails.thresholds.medThreshold, 0)
                XCTAssertNotNil(accountDetails.flags)
                XCTAssertNotNil(accountDetails.flags.authRequired)
                XCTAssertEqual(accountDetails.flags.authRequired, false)
                XCTAssertEqual(accountDetails.flags.authRevocable, false)
                XCTAssertEqual(accountDetails.flags.authImmutable, false)
                
                XCTAssertNotNil(accountDetails.balances)
                XCTAssertTrue(accountDetails.balances.count == 1)
                let balance = accountDetails.balances.first!
                XCTAssertNotNil(balance)
                XCTAssertNotNil(balance.assetType)
                if balance.assetType == AssetTypeAsString.NATIVE {
                    XCTAssertNil(balance.assetCode)
                    XCTAssertNil(balance.assetIssuer)
                } else {
                    XCTAssertNotNil(balance.assetCode)
                    XCTAssertNotNil(balance.assetIssuer)
                }
                
                XCTAssertNotNil(accountDetails.signers)
                XCTAssertTrue(accountDetails.signers.count == 1)
                let signer = accountDetails.signers.first!
                XCTAssertEqual(signer.weight, 1)
                XCTAssertEqual(signer.key, accountDetails.accountId)
                XCTAssertEqual(signer.type, "ed25519_public_key")
                
                /*var key1found = false
                var key2found = false
                
                for (key, value) in accountDetails.data {
                    switch key {
                    case "stellar":
                        XCTAssertEqual(value.base64Decoded(), "is cool")
                        key1found = true
                    case "soneso":
                        XCTAssertEqual(value.base64Decoded(), "is fun")
                        key2found = true
                    default:
                        XCTAssertNotNil(key)
                    }
                }
                XCTAssertTrue(key1found)
                XCTAssertTrue(key2found)*/
                
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GAD Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountsByAsset() {
        let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
        
        sdk.accounts.getAccounts(signer: nil, asset: "IOM:GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII", cursor: nil, order: Order.descending, limit: 2) { (response) -> (Void) in
            switch response {
            case .success(let accountsResponse):
                // load next page
                accountsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextAccountsResponse):
                        // load previous page, should contain the same accounts as the first page
                        nextAccountsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevAccountsResponse):
                                let account1 = accountsResponse.records.first
                                let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                                XCTAssertNotNil(account1);
                                XCTAssertNotNil(account2);
                                XCTAssertTrue(account1?.accountId == account2?.accountId)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountsBySigner() {
        let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
        
        sdk.accounts.getAccounts(signer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII", asset:nil, cursor: nil, order: Order.descending, limit: 2) { (response) -> (Void) in
            switch response {
            case .success(let accountsResponse):
                // load next page
                accountsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextAccountsResponse):
                        // load previous page, should contain the same accounts as the first page
                        nextAccountsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevAccountsResponse):
                                let account1 = accountsResponse.records.first
                                let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                                XCTAssertNotNil(account1);
                                XCTAssertNotNil(account2);
                                XCTAssertTrue(account1?.accountId == account2?.accountId)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
