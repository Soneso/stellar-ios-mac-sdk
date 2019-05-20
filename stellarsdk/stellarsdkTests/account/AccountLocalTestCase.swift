//
//  AccountLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AccountLocalTestCase: XCTestCase {
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
        XCTAssert(keyPair.privateKey!.bytes.count == 64, "Private key length is incorrect")
        XCTAssert(keyPair.seed!.bytes.count == 32, "Seed length is incorrect")
        XCTAssertNotNil(keyPair.secretSeed)
        
        do {
            let _ = try KeyPair(secretSeed: "Sssdd")
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
        
        do {
            let _ = try KeyPair(secretSeed: "GCTMMHMQONEFT4AW6O57UUIGESXW4TYAQIN6TGRGCF5XZIE6WSOTSL4S")
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
        
        do {
            let _ = try KeyPair(secretSeed: "SCTMMHMQONEFT4AW6O57UUIGESXW4TYAQIN6TGRGCF5XZIE6WSOTSL4S")
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }
    
    func testKeyFromAccountIdCreation() {
        let keyPair = try! KeyPair(publicKey: PublicKey(accountId:"GC5EGTDV2RFIIHAEKF47KVCIOH6IK6WCO6I5ICT2YAWF6ZYZIHNHLEPR"), privateKey:nil)
        
        XCTAssert(keyPair.publicKey.bytes.count == 32, "Public key length is incorrect")
        
        do {
            let _ = try KeyPair(accountId: "SC5EGTDV2RFIIHAEKF47KVCIOH6IK6WCO6I5ICT2YAWF6ZYZIHNHLEPR")
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testKeyFromAccountSecretCreation() {
        let seed = try! Seed(secret:"SAOZTU5IRNFJNLJQZH5HPWVVHUFU5V6IDEFHTDGWNGUY2HM6BVO6AV4T")
        let keyPair = KeyPair(seed: seed)
        
        XCTAssert(keyPair.publicKey.bytes.count == 32, "Public key length is incorrect")
    }
    
 /*   func testCreateTestAccount() {
        
        let expectation = XCTestExpectation(description: "Create key and ask friendbot to fund it.")
        
        let keyPair = try! KeyPair.generateRandomKeyPair()
        XCTAssertNotNil(keyPair.secretSeed)
        
        
        print("Account ID: " + keyPair.accountId)
        print("Secret Seed: " + keyPair.secretSeed)
        
        sdk.effects.stream(for: .effectsForAccount(account:keyPair.accountId, cursor:nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(let id, let effectResponse):
                if let accountCreatedResponse = effectResponse as? AccountCreatedEffectResponse {
                    // success
                    print("CTA Test: Stream source account received response with effect-ID: \(id) - type: Account created - starting balance: \(accountCreatedResponse.startingBalance)")
                    XCTAssert(true)
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CA Test - source", horizonRequestError:horizonRequestError)
                } else {
                    print("CTA Test: Stream error on source account: \(error?.localizedDescription ?? "")")
                } // ignore sse errors, some are just nil
            }
        }
        
        sdk.accounts.createTestAccount(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let details):
                print(details)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CTA Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    */
    func testAccountNotFound() {
        let expectation = XCTestExpectation(description: "Get and parse account not found error")
        
        sdk.accounts.getAccountDetails(accountId: "AAAAA") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound( _, _):
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountDetails() {
        let expectation = XCTestExpectation(description: "Get account details and parse the successfully.")
        
        sdk.accounts.getAccountDetails(accountId: testSuccessAccountId) { (response) -> (Void) in
            switch response {
            case .success(let accountDetails):
                XCTAssertEqual(self.testSuccessAccountId, accountDetails.accountId)
                XCTAssertNotNil(accountDetails.sequenceNumber)
                XCTAssertEqual(accountDetails.sequenceNumber, 30232549674450945)
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
                XCTAssertEqual(accountDetails.pagingToken, "999")
                XCTAssertEqual(accountDetails.subentryCount, 1)
                XCTAssertNotNil(accountDetails.thresholds)
                XCTAssertEqual(accountDetails.thresholds.highThreshold, 3)
                XCTAssertEqual(accountDetails.thresholds.lowThreshold, 1)
                XCTAssertEqual(accountDetails.thresholds.medThreshold, 2)
                XCTAssertNotNil(accountDetails.flags)
                XCTAssertNotNil(accountDetails.flags.authRequired)
                XCTAssertEqual(accountDetails.flags.authRequired, true)
                XCTAssertEqual(accountDetails.flags.authRevocable, true)
                XCTAssertEqual(accountDetails.flags.authImmutable, true)
                
                XCTAssertNotNil(accountDetails.balances)
                XCTAssertTrue(accountDetails.balances.count == 3)
                var count = 0
                for balance in accountDetails.balances {
                    XCTAssertNotNil(balance)
                    XCTAssertNotNil(balance.assetType)
                    
                    switch count {
                        case 0:
                            XCTAssertEqual(balance.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
                            XCTAssertEqual(balance.balance, "126.8107491")
                            XCTAssertEqual(balance.limit, "5000.0000000")
                            XCTAssertEqual(balance.assetCode, "BAR")
                            XCTAssertEqual(balance.assetIssuer, "BARUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG")
                        case 1:
                            XCTAssertEqual(balance.assetType, AssetTypeAsString.CREDIT_ALPHANUM12)
                            XCTAssertEqual(balance.balance, "294.0000000")
                            XCTAssertEqual(balance.limit, "922337203685.4775807")
                            XCTAssertEqual(balance.assetCode, "FOXYMOXY")
                            XCTAssertEqual(balance.assetIssuer, "FOXUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG")
                        default:
                            XCTAssertEqual(balance.assetType, AssetTypeAsString.NATIVE)
                            XCTAssertEqual(balance.balance, "9999.9999900")
                            XCTAssertNil(balance.assetCode)
                            XCTAssertNil(balance.assetIssuer)
                    }
                    
                    if balance.assetType == AssetTypeAsString.NATIVE {
                        XCTAssertNil(balance.assetCode)
                        XCTAssertNil(balance.assetIssuer)
                    } else {
                        XCTAssertNotNil(balance.assetCode)
                        XCTAssertNotNil(balance.assetIssuer)
                    }
                    count += 1
                    // TODO: what about limit? can it be nil for an asset code different than native?
                }
                
                XCTAssertNotNil(accountDetails.signers)
                XCTAssertTrue(accountDetails.signers.count > 0)
                count = 0
                for signer in accountDetails.signers {
                    switch count {
                        case 0:
                            XCTAssertEqual(signer.weight, 1)
                            XCTAssertEqual(signer.key, accountDetails.accountId)
                            XCTAssertEqual(signer.type, "ed25519_public_key")
                        default:
                            XCTAssertEqual(signer.weight, 2)
                            XCTAssertEqual(signer.key, "BARUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG")
                            XCTAssertEqual(signer.type, "test")
                    }
                    count += 1
                }
                
                var key1found = false
                var key2found = false
                
                for (key, value) in accountDetails.data {
                    switch key {
                        case "club":
                            XCTAssertEqual(value, "MTAw")
                            key1found = true
                        case "run":
                            XCTAssertEqual(value, "faster")
                            key2found = true
                        default:
                            XCTAssertNotNil(key)
                    }
                }
                XCTAssertTrue(key1found)
                XCTAssertTrue(key2found)
                
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GAD Test", horizonRequestError: error)
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
            "paging_token": "999",
            "account_id": "\(accountId)",
            "sequence": "30232549674450945",
            "subentry_count": 1,
            "inflation_destination": "GDLZ7O5LPSDUOEAD3JBJKCSKCVAMNG7IIRKH57CXQYB46ILW2D74F26M",
            "home_domain": "soneso.com",
            "thresholds": {
                "low_threshold": 1,
                "med_threshold": 2,
                "high_threshold": 3
            },
            "flags": {
                "auth_required": true,
                "auth_revocable": true,
                "auth_immutable": true
            },
            "balances": [
                {
                    "balance": "126.8107491",
                    "limit": "5000.0000000",
                    "asset_type": "credit_alphanum4",
                    "asset_code": "BAR",
                    "asset_issuer": "BARUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG",
                    "buying_liabilities": "0.0000",
                    "selling_liabilities": "0.0000"
                },
                {
                    "balance": "294.0000000",
                    "limit": "922337203685.4775807",
                    "asset_type": "credit_alphanum12",
                    "asset_code": "FOXYMOXY",
                    "asset_issuer": "FOXUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG",
                    "buying_liabilities": "0.0000",
                    "selling_liabilities": "0.0000"
                },
                {
                    "balance": "9999.9999900",
                    "asset_type": "native",
                    "buying_liabilities": "0.0000",
                    "selling_liabilities": "0.0000"
                }
            ],
            "signers": [
                {
                    "public_key": "\(accountId)",
                    "weight": 1,
                    "key": "\(accountId)",
                    "type": "ed25519_public_key"
                },
                {
                    "public_key": "FOXUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG",
                    "weight": 2,
                    "key": "BARUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG",
                    "type": "test"
                }
            ],
            "data": {
                "club": "MTAw",
                "run": "faster"
            }
        }
        """
        return accountResponseString
    }
}
