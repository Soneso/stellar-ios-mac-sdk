//
//  ServicesTier6UnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class HorizonCoreServicesUnitTests: XCTestCase {
    let sdk = StellarSDK()
    var mockRegistered = false

    override func setUp() {
        super.setUp()

        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - EffectsService Tests

    func testGetAllEffects() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "operation": {
                                "href": "https://horizon-testnet.stellar.org/operations/12884905984"
                            },
                            "precedes": {
                                "href": "https://horizon-testnet.stellar.org/effects?cursor=12884905984-1&order=asc"
                            },
                            "succeeds": {
                                "href": "https://horizon-testnet.stellar.org/effects?cursor=12884905984-1&order=desc"
                            }
                        },
                        "id": "0000000012884905984-0000000001",
                        "paging_token": "12884905984-1",
                        "account": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
                        "type": "account_created",
                        "type_i": 0,
                        "created_at": "2024-01-01T00:00:00Z",
                        "starting_balance": "10000.0000000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=&limit=10&order=asc"
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=123&limit=10&order=asc"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=123&limit=10&order=desc"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/effects"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects()

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
            XCTAssertEqual(page.records.count, 1)
            XCTAssertEqual(page.records[0].effectType, EffectType.accountCreated)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsWithPagination() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=test123&limit=50&order=desc"
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=next&limit=50&order=desc"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=prev&limit=50&order=desc"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("cursor=test123"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects(from: "test123", order: .descending, limit: 50)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsForAccount() async {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "operation": {
                                "href": "https://horizon-testnet.stellar.org/operations/12884905984"
                            },
                            "precedes": {
                                "href": "https://horizon-testnet.stellar.org/effects?cursor=12884905984-1&order=asc"
                            },
                            "succeeds": {
                                "href": "https://horizon-testnet.stellar.org/effects?cursor=12884905984-1&order=desc"
                            }
                        },
                        "id": "0000000012884905984-0000000001",
                        "paging_token": "12884905984-1",
                        "account": "\(accountId)",
                        "type": "account_credited",
                        "type_i": 2,
                        "created_at": "2024-01-01T00:00:00Z",
                        "asset_type": "native",
                        "amount": "100.0000000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/effects"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/effects"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects(forAccount: accountId)

        switch response {
        case .success(let page):
            XCTAssertEqual(page.records.count, 1)
            XCTAssertEqual(page.records[0].effectType, EffectType.accountCredited)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsForLedger() async {
        let ledger = "123456"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/\(ledger)/effects"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/ledgers/\(ledger)/effects"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/ledgers/*/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects(forLedger: ledger)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsForOperation() async {
        let operationId = "12884905984"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations/\(operationId)/effects"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/operations/\(operationId)/effects"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/operations/*/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects(forOperation: operationId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsForTransaction() async {
        let txHash = "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/\(txHash)/effects"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/transactions/\(txHash)/effects"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions/*/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects(forTransaction: txHash)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsForLiquidityPool() async {
        let liquidityPoolId = "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(liquidityPoolId)/effects"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/liquidity_pools/\(liquidityPoolId)/effects"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/*/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects(forLiquidityPool: liquidityPoolId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetEffectsFromUrl() async {
        let testUrl = "https://horizon-testnet.stellar.org/effects?cursor=now&limit=5"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "\(testUrl)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffectsFromUrl(url: testUrl)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testEffectsStreamForAllEffects() {
        let streamItem = sdk.effects.stream(for: .allEffects(cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testEffectsStreamForAccount() {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let streamItem = sdk.effects.stream(for: .effectsForAccount(account: accountId, cursor: "now"))
        XCTAssertNotNil(streamItem)
    }

    func testEffectsStreamForLedger() {
        let streamItem = sdk.effects.stream(for: .effectsForLedger(ledger: "123456", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testEffectsStreamForOperation() {
        let streamItem = sdk.effects.stream(for: .effectsForOperation(operation: "12884905984", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testEffectsStreamForTransaction() {
        let streamItem = sdk.effects.stream(for: .effectsForTransaction(transaction: "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testEffectsStreamForLiquidityPool() {
        let streamItem = sdk.effects.stream(for: .effectsForLiquidityPool(liquidityPool: "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    // MARK: - AccountService Tests

    func testGetAccountDetails() async {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let mockResponse = """
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
            "account_id": "\(accountId)",
            "sequence": "123456789",
            "subentry_count": 0,
            "last_modified_ledger": 1000,
            "last_modified_time": "2024-01-01T00:00:00Z",
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false,
                "auth_immutable": false,
                "auth_clawback_enabled": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "buying_liabilities": "0.0000000",
                    "selling_liabilities": "0.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {},
            "num_sponsoring": 0,
            "num_sponsored": 0,
            "paging_token": "\(accountId)"
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccountDetails(accountId: accountId)

        switch response {
        case .success(let account):
            XCTAssertEqual(account.accountId, accountId)
            XCTAssertEqual(account.sequenceNumber, 123456789)
            XCTAssertEqual(account.balances.count, 1)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetDataForAccount() async {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let key = "test_key"
        let mockResponse = """
        {
            "value": "dGVzdF92YWx1ZQ=="
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/data/\(key)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*/data/*",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getDataForAccount(accountId: accountId, key: key)

        switch response {
        case .success(let data):
            XCTAssertEqual(data.value, "dGVzdF92YWx1ZQ==")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetAccountsWithFilters() async {
        let signer = "GSIGNER123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts?signer=\(signer)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("signer=\(signer)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccounts(signer: signer)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetAccountsWithAssetFilter() async {
        let asset = "USD:GISSUER123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts?asset=\(asset)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("asset="))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccounts(asset: asset, limit: 20)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetAccountsWithSponsorFilter() async {
        let sponsor = "GSPONSOR123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts?sponsor=\(sponsor)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("sponsor=\(sponsor)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccounts(sponsor: sponsor)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetAccountsWithLiquidityPoolFilter() async {
        let liquidityPoolId = "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts?liquidity_pool=\(liquidityPoolId)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("liquidity_pool=\(liquidityPoolId)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccounts(liquidityPoolId: liquidityPoolId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetAccountsFromUrl() async {
        let testUrl = "https://horizon-testnet.stellar.org/accounts?cursor=now&limit=5"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "\(testUrl)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccountsFromUrl(url: testUrl)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testStreamAccount() {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let streamItem = sdk.accounts.streamAccount(accountId: accountId)
        XCTAssertNotNil(streamItem)
    }

    func testStreamAccountData() {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let streamItem = sdk.accounts.streamAccountData(accountId: accountId, key: "test_key")
        XCTAssertNotNil(streamItem)
    }

    // MARK: - OperationsService Tests

    func testGetOperationsWithPagination() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=test123&limit=50&order=desc"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("cursor=test123"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/operations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperations(from: "test123", order: .descending, limit: 50)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOperationsWithIncludeFailed() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations?include_failed=true"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("include_failed=true"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/operations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperations(includeFailed: true)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOperationsWithJoin() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations?join=transactions"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("join=transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/operations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperations(join: "transactions")

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOperationsForAccount() async {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/operations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/operations"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*/operations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperations(forAccount: accountId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOperationsForLedger() async {
        let ledger = "123456"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/\(ledger)/operations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/ledgers/\(ledger)/operations"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/ledgers/*/operations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperations(forLedger: ledger)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOperationsForTransaction() async {
        let txHash = "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/\(txHash)/operations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/transactions/\(txHash)/operations"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions/*/operations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperations(forTransaction: txHash)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOperationDetails() async {
        let operationId = "12884905984"
        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations/\(operationId)"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/\(operationId)/effects"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=\(operationId)"
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=\(operationId)"
                }
            },
            "id": "\(operationId)",
            "paging_token": "\(operationId)",
            "type": "payment",
            "type_i": 1,
            "created_at": "2024-01-01T00:00:00Z",
            "transaction_hash": "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889",
            "source_account": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
            "transaction_successful": true,
            "asset_type": "native",
            "from": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
            "to": "GACCOUNT123",
            "amount": "100.0000000"
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/operations/\(operationId)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/operations/*",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.operations.getOperationDetails(operationId: operationId)

        switch response {
        case .success(let operation):
            XCTAssertEqual(operation.id, operationId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testOperationsStreamForAllOperations() {
        let streamItem = sdk.operations.stream(for: .allOperations(cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testOperationsStreamForAccount() {
        let streamItem = sdk.operations.stream(for: .operationsForAccount(account: "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testOperationsStreamForClaimableBalance() {
        let streamItem = sdk.operations.stream(for: .operationsForClaimableBalance(claimableBalanceId: "00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testOperationsStreamForLedger() {
        let streamItem = sdk.operations.stream(for: .operationsForLedger(ledger: "123456", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testOperationsStreamForTransaction() {
        let streamItem = sdk.operations.stream(for: .operationsForTransaction(transaction: "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testOperationsStreamForLiquidityPool() {
        let streamItem = sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    // MARK: - OffersService Tests

    func testGetOffersForAccount() async {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon-testnet.stellar.org/offers/1"
                            },
                            "offer_maker": {
                                "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)"
                            }
                        },
                        "id": "1",
                        "paging_token": "1",
                        "seller": "\(accountId)",
                        "selling": {
                            "asset_type": "native"
                        },
                        "buying": {
                            "asset_type": "credit_alphanum4",
                            "asset_code": "USD",
                            "asset_issuer": "GISSUER123"
                        },
                        "amount": "1000.0000000",
                        "price": "1.5000000",
                        "price_r": {
                            "n": 3,
                            "d": 2
                        },
                        "last_modified_ledger": 123456,
                        "last_modified_time": "2024-01-01T00:00:00Z"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/offers"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/offers"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*/offers",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.offers.getOffers(forAccount: accountId)

        switch response {
        case .success(let page):
            XCTAssertEqual(page.records.count, 1)
            XCTAssertEqual(page.records[0].seller, accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOffersWithFilters() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("selling_asset_type=native"))
            XCTAssertTrue(url.absoluteString.contains("buying_asset_type=credit_alphanum4"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/offers",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.offers.getOffers(
            seller: nil,
            sellingAssetType: "native",
            buyingAssetType: "credit_alphanum4",
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GISSUER123"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOffersWithSeller() async {
        let seller = "GSELLER123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers?seller=\(seller)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("seller=\(seller)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/offers",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.offers.getOffers(
            seller: seller,
            sellingAssetType: "native",
            buyingAssetType: "credit_alphanum4",
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GISSUER123"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOffersWithSponsor() async {
        let sponsor = "GSPONSOR123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers?sponsor=\(sponsor)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("sponsor=\(sponsor)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/offers",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.offers.getOffers(
            seller: nil,
            sellingAssetType: "native",
            buyingAssetType: "credit_alphanum4",
            sponsor: sponsor
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOfferDetails() async {
        let offerId = "12345"
        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers/\(offerId)"
                },
                "offer_maker": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
                }
            },
            "id": "\(offerId)",
            "paging_token": "\(offerId)",
            "seller": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
            "selling": {
                "asset_type": "native"
            },
            "buying": {
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GISSUER123"
            },
            "amount": "1000.0000000",
            "price": "1.5000000",
            "price_r": {
                "n": 3,
                "d": 2
            },
            "last_modified_ledger": 123456,
            "last_modified_time": "2024-01-01T00:00:00Z"
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/offers/\(offerId)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/offers/*",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.offers.getOfferDetails(offerId: offerId)

        switch response {
        case .success(let offer):
            XCTAssertEqual(offer.id, offerId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradesForOffer() async {
        let offerId = "12345"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers/\(offerId)/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/offers/\(offerId)/trades"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/offers/*/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.offers.getTrades(forOffer: offerId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testOffersStreamForAllOffers() {
        let streamItem = sdk.offers.stream(for: .allOffers(
            seller: nil,
            sellingAssetType: "native",
            sellingAssetCode: nil,
            sellingAssetIssuer: nil,
            buyingAssetType: "credit_alphanum4",
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GISSUER123",
            sponsor: nil,
            cursor: nil,
            order: nil
        ))
        XCTAssertNotNil(streamItem)
    }

    func testOffersStreamForAccount() {
        let streamItem = sdk.offers.stream(for: .offersForAccount(account: "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testStreamTradesForOffer() {
        let streamItem = sdk.offers.streamTrades(forOffer: "12345", cursor: nil, order: nil, limit: nil)
        XCTAssertNotNil(streamItem)
    }

    // MARK: - PaymentsService Tests

    func testGetAllPayments() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon-testnet.stellar.org/operations/12884905984"
                            },
                            "transaction": {
                                "href": "https://horizon-testnet.stellar.org/transactions/3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
                            },
                            "effects": {
                                "href": "https://horizon-testnet.stellar.org/operations/12884905984/effects"
                            },
                            "succeeds": {
                                "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=12884905984"
                            },
                            "precedes": {
                                "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=12884905984"
                            }
                        },
                        "id": "12884905984",
                        "paging_token": "12884905984",
                        "type": "payment",
                        "type_i": 1,
                        "created_at": "2024-01-01T00:00:00Z",
                        "transaction_hash": "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889",
                        "source_account": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
                        "transaction_successful": true,
                        "asset_type": "native",
                        "from": "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75",
                        "to": "GACCOUNT123",
                        "amount": "100.0000000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/payments"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/payments"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments()

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
            XCTAssertEqual(page.records.count, 1)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsWithPagination() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/payments?cursor=test123&limit=50&order=desc"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("cursor=test123"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments(from: "test123", order: .descending, limit: 50)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsWithIncludeFailed() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/payments?include_failed=true"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("include_failed=true"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments(includeFailed: true)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsWithJoin() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/payments?join=transactions"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("join=transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments(join: "transactions")

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsForAccount() async {
        let accountId = "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/payments"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/payments"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments(forAccount: accountId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsForLedger() async {
        let ledger = "123456"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/\(ledger)/payments"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/ledgers/\(ledger)/payments"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/ledgers/*/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments(forLedger: ledger)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsForTransaction() async {
        let txHash = "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/\(txHash)/payments"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/transactions/\(txHash)/payments"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions/*/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPayments(forTransaction: txHash)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetPaymentsFromUrl() async {
        let testUrl = "https://horizon-testnet.stellar.org/payments?cursor=now&limit=5"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "\(testUrl)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/payments",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.payments.getPaymentsFromUrl(url: testUrl)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPaymentsStreamForAllPayments() {
        let streamItem = sdk.payments.stream(for: .allPayments(cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testPaymentsStreamForAccount() {
        let streamItem = sdk.payments.stream(for: .paymentsForAccount(account: "GAKLBGHNHFQ3BMUYG5KU4BEWO6EYQHZHAXEWC33W34PH2RBHZDSQBD75", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testPaymentsStreamForLedger() {
        let streamItem = sdk.payments.stream(for: .paymentsForLedger(ledger: "123456", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testPaymentsStreamForTransaction() {
        let streamItem = sdk.payments.stream(for: .paymentsForTransaction(transaction: "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889", cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    // MARK: - Error Handling Tests

    func testEffectsServiceParsingError() async {
        let mockResponse = "invalid json"

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/effects",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.effects.getEffects()

        switch response {
        case .success:
            XCTFail("Should have failed with parsing error")
        case .failure(let error):
            if case .parsingResponseFailed = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testAccountServiceNetworkError() async {
        let handler: MockHandler = { mock, request in
            return ""
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/*",
                                     httpMethod: "GET",
                                     statusCode: 404,
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.accounts.getAccountDetails(accountId: "GNOTFOUND")

        switch response {
        case .success:
            XCTFail("Should have failed with 404 error")
        case .failure:
            // Expected error
            break
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - AssetsService Tests

    func testGetAssets() async {
        let assetsResponsesMock = AssetsResponsesMock()
        let oneAssetResponse = assetsSuccessResponse(limit: 1)
        let twoAssetsResponse = assetsSuccessResponse(limit: 2)

        assetsResponsesMock.addAssetsResponse(key: "1", assetsResponse: oneAssetResponse)
        assetsResponsesMock.addAssetsResponse(key: "2", assetsResponse: twoAssetsResponse)

        let response = await sdk.assets.getAssets(limit: 1)
        switch response {
        case .success(let assetsResponse):
            await checkResult(assetsResponse: assetsResponse, limit: 1)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetAssets()", horizonRequestError: error)
            XCTFail()
        }

        func checkResult(assetsResponse: PageResponse<AssetResponse>, limit: Int) async {

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
                XCTAssertNotNil(secondAsset!.flags)
                XCTAssertTrue(secondAsset!.flags.authRequired)
                XCTAssertTrue(secondAsset!.flags.authRevocable)
                XCTAssertTrue(secondAsset!.flags.authImmutable)
                XCTAssertTrue(secondAsset!.flags.authClawbackEnabled)

            } else {
                let responseEnum = await sdk.assets.getAssets(limit: 2)
                switch responseEnum {
                case .success(let assetsResponse):
                    await checkResult(assetsResponse: assetsResponse, limit: 2)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag: "GA Test", horizonRequestError: error)
                    XCTFail()
                }
            }
        }
    }

    private func assetsSuccessResponse(limit: Int) -> String {

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
}

// MARK: - AssetsResponsesMock

class AssetsResponsesMock: ResponsesMock {
    var assetsResponses = [String: String]()

    func addAssetsResponse(key: String, assetsResponse: String) {
        assetsResponses[key] = assetsResponse
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["limit"],
                let assetsResponse = self?.assetsResponses[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
            }

            return assetsResponse
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/assets?limit=${limit}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
