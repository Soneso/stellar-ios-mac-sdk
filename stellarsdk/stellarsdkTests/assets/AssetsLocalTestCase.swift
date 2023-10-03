//
//  AssetsLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AssetsLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var assetsResponsesMock: AssetsResponsesMock? = nil
    var mockRegistered = false
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        assetsResponsesMock = AssetsResponsesMock()
        let oneAssetResponse = successResponse(limit: 1)
        let twoAssetsResponse = successResponse(limit: 2)
        
        assetsResponsesMock?.addAssetsResponse(key: "1", assetsResponse: oneAssetResponse)
        assetsResponsesMock?.addAssetsResponse(key: "2", assetsResponse: twoAssetsResponse)
        
    }
    
    override func tearDown() {
        assetsResponsesMock = nil
        super.tearDown()
    }
    
    func testGetAssets() {
        let expectation = XCTestExpectation(description: "Get assets and parse their details successfully")
        
        sdk.assets.getAssets(limit: 1) { (response) -> (Void) in
            switch response {
            case .success(let assetsResponse):
                checkResult(assetsResponse:assetsResponse, limit:1)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GA Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        func checkResult(assetsResponse:PageResponse<AssetResponse>, limit:Int) {
            
            XCTAssertNotNil(assetsResponse.links)
            XCTAssertNotNil(assetsResponse.links.selflink)
            XCTAssertEqual(assetsResponse.links.selflink.href, "https://horizon-testnet.stellar.org/assets?order=desc&limit=&cursor=")
            XCTAssertNil(assetsResponse.links.selflink.templated)
            
            XCTAssertNotNil(assetsResponse.links.prev)
            XCTAssertEqual(assetsResponse.links.prev?.href, "https://horizon-testnet.stellar.org/assets?order=asc&limit=3&cursor=ZZZ_GCTEZSVHLL5GNQ3VNSWJMU3W3ODMBWTXBDHKFYTUBBPZMFSYD5QXLSAM_credit_alphanum4")
            XCTAssertNil(assetsResponse.links.prev?.templated)
            
            XCTAssertNotNil(assetsResponse.links.next)
            XCTAssertEqual(assetsResponse.links.next?.href, "https://horizon-testnet.stellar.org/assets?order=desc&limit=&cursor=zZtdJBs5egz8_GBGKYTIF74HSGAW5M6FMT7XJEPCZBXOD6RFHMETK4HL4EK55DUXEHVAZ_credit_alphanum12")
            XCTAssertNil(assetsResponse.links.next?.templated)
            
            if limit == 1 {
                XCTAssertEqual(assetsResponse.records.count, 1)
            } else if limit == 2 {
                XCTAssertEqual(assetsResponse.records.count, 2)
            }
            
            let firstAsset = assetsResponse.records.first
            XCTAssertNotNil(firstAsset)
            XCTAssertNotNil(firstAsset!.links.toml.href)
            XCTAssertEqual(firstAsset!.links.toml.href, "")
            XCTAssertEqual(firstAsset!.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
            XCTAssertEqual(firstAsset!.assetCode, "ZZZ")
            XCTAssertEqual(firstAsset!.assetIssuer, "GCTEZSVHLL5GNQ3VNSWJMU3W3ODMBWTXBDHKFYTUBBPZMFSYD5QXLSAM")
            XCTAssertEqual(firstAsset!.pagingToken, "ZZZ_GCTEZSVHLL5GNQ3VNSWJMU3W3ODMBWTXBDHKFYTUBBPZMFSYD5QXLSAM_credit_alphanum4")
            XCTAssertEqual(firstAsset!.amount, 42.0)
            XCTAssertEqual(firstAsset!.numberOfAccounts, 1)
            XCTAssertNotNil(firstAsset!.accounts)
            XCTAssertEqual(firstAsset!.accounts.authorized, 1)
            XCTAssertEqual(firstAsset!.accounts.authorizedToMaintainLiabilities, 1)
            XCTAssertEqual(firstAsset!.accounts.unauthorized, 1)
            XCTAssertEqual(firstAsset!.numClaimableBalances, 1)
            XCTAssertNotNil(firstAsset!.balances)
            XCTAssertEqual(firstAsset!.balances.authorized, 20000.0)
            XCTAssertEqual(firstAsset!.balances.authorizedToMaintainLiabilities, 1.0)
            XCTAssertEqual(firstAsset!.balances.unauthorized, 5.0)
            XCTAssertNotNil(firstAsset!.flags)
            XCTAssertFalse(firstAsset!.flags.authRequired)
            XCTAssertFalse(firstAsset!.flags.authRevocable)
            XCTAssertFalse(firstAsset!.flags.authImmutable)
            XCTAssertFalse(firstAsset!.flags.authClawbackEnabled)
            XCTAssertEqual(firstAsset!.claimableBalancesAmount, 4.0)
            XCTAssertEqual(firstAsset!.numLiquidityPools, 2)
            XCTAssertEqual(firstAsset!.numContracts, 3)
            XCTAssertEqual(firstAsset!.liquidityPoolsAmount, "12.0")
            XCTAssertEqual(firstAsset!.contractsAmount, "13.0")
            
            if (limit == 2) {
                let secondAsset = assetsResponse.records.last
                XCTAssertNotNil(secondAsset)
                XCTAssertNotNil(secondAsset)
                XCTAssertNotNil(secondAsset!.links.toml.href)
                XCTAssertEqual(secondAsset!.links.toml.href, "https://stellar.surge.sh/.well-known/stellar.toml")
                XCTAssertEqual(secondAsset!.assetType, AssetTypeAsString.CREDIT_ALPHANUM12)
                XCTAssertEqual(secondAsset!.assetCode, "zzv7wZvwguhe")
                XCTAssertEqual(secondAsset!.assetIssuer, "GBGKYTIF74HSGAW5M6FMT7XJEPCZBXOD6RFHMETK4HL4EK55DUXEHVAZ")
                XCTAssertEqual(secondAsset!.pagingToken, "zzv7wZvwguhe_GBGKYTIF74HSGAW5M6FMT7XJEPCZBXOD6RFHMETK4HL4EK55DUXEHVAZ_credit_alphanum12")
                XCTAssertEqual(secondAsset!.amount, 0)
                XCTAssertEqual(secondAsset!.numberOfAccounts, 0)
                XCTAssertNotNil(secondAsset!.flags)
                XCTAssertTrue(secondAsset!.flags.authRequired)
                XCTAssertTrue(secondAsset!.flags.authRevocable)
                XCTAssertTrue(secondAsset!.flags.authImmutable)
                XCTAssertTrue(secondAsset!.flags.authClawbackEnabled)
                
                expectation.fulfill()
            } else {
                sdk.assets.getAssets(limit: 2) { (response) -> (Void) in
                    switch response {
                    case .success(let assetsResponse):
                        checkResult(assetsResponse:assetsResponse, limit:2)
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GA Test", horizonRequestError: error)
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    public func successResponse(limit:Int) -> String {
        
        var accountResponseString = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/assets?order=desc&limit=&cursor="
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/assets?order=desc&limit=&cursor=zZtdJBs5egz8_GBGKYTIF74HSGAW5M6FMT7XJEPCZBXOD6RFHMETK4HL4EK55DUXEHVAZ_credit_alphanum12"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/assets?order=asc&limit=3&cursor=ZZZ_GCTEZSVHLL5GNQ3VNSWJMU3W3ODMBWTXBDHKFYTUBBPZMFSYD5QXLSAM_credit_alphanum4"
                }
            },
            "_embedded": {
                "records": [
                {
                    "_links": {
                        "toml": {
                            "href": ""
                        }
                    },
                    "asset_type": "credit_alphanum4",
                    "asset_code": "ZZZ",
                    "asset_issuer": "GCTEZSVHLL5GNQ3VNSWJMU3W3ODMBWTXBDHKFYTUBBPZMFSYD5QXLSAM",
                    "paging_token": "ZZZ_GCTEZSVHLL5GNQ3VNSWJMU3W3ODMBWTXBDHKFYTUBBPZMFSYD5QXLSAM_credit_alphanum4",
                    "amount": "42.0000000",
                    "num_accounts": 1,
                    "accounts": {
                        "authorized": 1,
                        "authorized_to_maintain_liabilities": 1,
                        "unauthorized": 1
                    },
                    "num_claimable_balances": 1,
                    "balances": {
                        "authorized": "20000.0000000",
                        "authorized_to_maintain_liabilities": "1.0000000",
                        "unauthorized": "5.0000000"
                    },
                    "claimable_balances_amount": "4.0000000",
                    "flags": {
                        "auth_required": false,
                        "auth_revocable": false,
                        "auth_immutable": false,
                        "auth_clawback_enabled": false
                    },
                    "num_liquidity_pools": 2,
                    "liquidity_pools_amount": "12.0",
                    "num_contracts": 3,
                    "contract_amount": "13.0"
                }
        """
        if limit > 1 {
            let record = """
                        ,
                        {
                            "_links": {
                                "toml": {
                                    "href": "https://stellar.surge.sh/.well-known/stellar.toml"
                                }
                            },
                            "asset_type": "credit_alphanum12",
                            "asset_code": "zzv7wZvwguhe",
                            "asset_issuer": "GBGKYTIF74HSGAW5M6FMT7XJEPCZBXOD6RFHMETK4HL4EK55DUXEHVAZ",
                            "paging_token": "zzv7wZvwguhe_GBGKYTIF74HSGAW5M6FMT7XJEPCZBXOD6RFHMETK4HL4EK55DUXEHVAZ_credit_alphanum12",
                            "amount": "0.0000000",
                            "num_accounts": 0,
                            "accounts": {
                                "authorized": 1,
                                "authorized_to_maintain_liabilities": 0,
                                "unauthorized": 0
                            },
                            "num_claimable_balances": 0,
                            "balances": {
                                "authorized": "20000.0000000",
                                "authorized_to_maintain_liabilities": "0.0000000",
                                "unauthorized": "0.0000000"
                            },
                            "claimable_balances_amount": "0.0000000",
                            "flags": {
                                "auth_required": true,
                                "auth_revocable": true,
                                "auth_immutable": true,
                                "auth_clawback_enabled": true
                            },
                            "num_liquidity_pools": 2,
                            "liquidity_pools_amount": "12.0",
                            "num_contracts": 3,
                            "contract_amount": "13.0"
                        }
            """
            accountResponseString.append(record)
        }
        let end = """
                    ]
                }
            }
            """
        accountResponseString.append(end)
        
        return accountResponseString
    }
    
    func testAssetNative() {
        do {
            let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            XCTAssertNotNil(assetNative)

            let assetXDR = try assetNative!.toXDR()
            let parsedAsset = try Asset.fromXDR(assetXDR: assetXDR)
        
            XCTAssertNotNil(parsedAsset)
            XCTAssertEqual(parsedAsset.type, AssetType.ASSET_TYPE_NATIVE)
            XCTAssertNil(parsedAsset.code)
            XCTAssertNil(parsedAsset.issuer)
            
        }catch {
            XCTAssert(false)
        }
    }
    
    func testAssetTypeCreditAlphaNum4() {
        do {
            let code = "USB"
            let keyPair = try! KeyPair.generateRandomKeyPair()
            let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code:code, issuer:keyPair)
            XCTAssertNotNil(asset)
            
            let assetXDR = try asset!.toXDR()
            let parsedAsset = try Asset.fromXDR(assetXDR: assetXDR)
            
            XCTAssertNotNil(parsedAsset)
            XCTAssertEqual(parsedAsset.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
            XCTAssertNotNil(parsedAsset.code)
            XCTAssertTrue(parsedAsset.code!.hasPrefix(code))
            XCTAssertNotNil(parsedAsset.issuer)
            // TODO compare public key
            
        }catch {
            XCTAssert(false)
        }
    }
    
    func testAssetTypeCreditAlphaNum12() {
        do {
            let code = "TESTTEST"
            let keyPair = try! KeyPair.generateRandomKeyPair()
            let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code:code, issuer:keyPair)
            XCTAssertNotNil(asset)
            
            let assetXDR = try asset!.toXDR()
            let parsedAsset = try Asset.fromXDR(assetXDR: assetXDR)
            
            XCTAssertNotNil(parsedAsset)
            XCTAssertEqual(parsedAsset.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
            XCTAssertNotNil(parsedAsset.code)
            XCTAssertTrue(parsedAsset.code!.hasPrefix(code))
            XCTAssertNotNil(parsedAsset.issuer)
            // TODO compare public key
            
        }catch {
            XCTAssert(false)
        }
    }
}
