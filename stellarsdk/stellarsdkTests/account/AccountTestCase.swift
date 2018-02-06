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
    var accountResponsesMock: AccountResponsesMock? = nil
    var mockRegistered = false
    let testSuccessAccountId = "GBZ3VAAP2T2WMKF6226FTC6OSQN6KKGAGPVCCCMDDVLCHYQMXTMNHLB3"
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        accountResponsesMock = AccountResponsesMock()
        let accountDetailsResponse = successResponse(accountId: testSuccessAccountId)
        accountResponsesMock?.addAccount(key:testSuccessAccountId, accountResponse: accountDetailsResponse)
        
    }
    
    override func tearDown() {
        accountResponsesMock = nil
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
        
        sdk.accounts.getAccountDetails(accountId: testSuccessAccountId) { (response) -> (Void) in
            switch response {
            case .success(let accountDetails):
                XCTAssertEqual(self.testSuccessAccountId, accountDetails.id)
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
    
    public func successResponse(accountId:String) -> String {
        
        let accountResponseString = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)"
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/transactions{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/operations{?cursor,limit,order}",
                    "templated": true
                },
                "payments": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/payments{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/effects{?cursor,limit,order}",
                    "templated": true
                },
                "offers": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/offers{?cursor,limit,order}",
                    "templated": true
                },
                "trades": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/trades{?cursor,limit,order}",
                    "templated": true
                },
                "data": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/data/{key}",
                    "templated": true
                }
            },
            "id": "\(accountId)",
            "paging_token": "",
            "account_id": "\(accountId)",
            "sequence": "30232549674450945",
            "subentry_count": 0,
            "inflation_destination": "GDLZ7O5LPSDUOEAD3JBJKCSKCVAMNG7IIRKH57CXQYB46ILW2D74F26M",
            "home_domain": "soneso.com",
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "126.8107491",
                    "limit": "5000.0000000",
                    "asset_type": "credit_alphanum4",
                    "asset_code": "BAR",
                    "asset_issuer": "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG"
                },
                {
                    "balance": "294.0000000",
                    "limit": "922337203685.4775807",
                    "asset_type": "credit_alphanum4",
                    "asset_code": "FOO",
                    "asset_issuer": "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG"
                },
                {
                    "balance": "9999.9999900",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "public_key": "\(accountId)",
                    "weight": 1,
                    "key": "GBZ3VAAP2T2WMKF6226FTC6OSQN6KKGAGPVCCCMDDVLCHYQMXTMNHLB3",
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """
        return accountResponseString
    }
}
