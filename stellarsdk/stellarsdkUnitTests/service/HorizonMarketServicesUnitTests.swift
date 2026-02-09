//
//  ServicesAdditionalUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Additional unit tests for Horizon services: Orderbook, Trades, LiquidityPools
class HorizonMarketServicesUnitTests: XCTestCase {
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

    // MARK: - PageResponse Navigation Tests

    func testPageResponseHasNextPage() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=123&limit=10"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades()

        switch response {
        case .success(let page):
            XCTAssertTrue(page.hasNextPage())
            XCTAssertFalse(page.hasPreviousPage())
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPageResponseHasPreviousPage() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=456&limit=10"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades()

        switch response {
        case .success(let page):
            XCTAssertFalse(page.hasNextPage())
            XCTAssertTrue(page.hasPreviousPage())
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPageResponseHasNoNavigation() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades()

        switch response {
        case .success(let page):
            XCTAssertFalse(page.hasNextPage())
            XCTAssertFalse(page.hasPreviousPage())
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPageResponseGetNextPage() async {
        let firstPageResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon-testnet.stellar.org/trades/1"},
                            "base": {"href": "https://horizon-testnet.stellar.org/accounts/GBASE"},
                            "counter": {"href": "https://horizon-testnet.stellar.org/accounts/GCOUNTER"},
                            "operation": {"href": "https://horizon-testnet.stellar.org/operations/1"}
                        },
                        "id": "1",
                        "paging_token": "1",
                        "ledger_close_time": "2022-01-01T00:00:00Z",
                        "trade_type": "orderbook",
                        "base_offer_id": "1",
                        "base_account": "GBASE",
                        "base_amount": "100.0000000",
                        "base_asset_type": "native",
                        "counter_offer_id": "2",
                        "counter_account": "GCOUNTER",
                        "counter_amount": "50.0000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "USD",
                        "counter_asset_issuer": "GISSUER",
                        "base_is_seller": true,
                        "price": {
                            "n": 1,
                            "d": 2
                        }
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=123"
                }
            }
        }
        """

        let secondPageResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon-testnet.stellar.org/trades/2"},
                            "base": {"href": "https://horizon-testnet.stellar.org/accounts/GBASE2"},
                            "counter": {"href": "https://horizon-testnet.stellar.org/accounts/GCOUNTER2"},
                            "operation": {"href": "https://horizon-testnet.stellar.org/operations/2"}
                        },
                        "id": "2",
                        "paging_token": "2",
                        "ledger_close_time": "2022-01-02T00:00:00Z",
                        "trade_type": "orderbook",
                        "base_offer_id": "3",
                        "base_account": "GBASE2",
                        "base_amount": "200.0000000",
                        "base_asset_type": "native",
                        "counter_offer_id": "4",
                        "counter_account": "GCOUNTER2",
                        "counter_amount": "100.0000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "EUR",
                        "counter_asset_issuer": "GISSUER2",
                        "base_is_seller": true,
                        "price": {
                            "n": 1,
                            "d": 2
                        }
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=123"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            if url.absoluteString.contains("cursor=123") {
                return secondPageResponse
            } else {
                return firstPageResponse
            }
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                    path: "/trades",
                                    httpMethod: "GET",
                                    mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let firstResponse = await sdk.trades.getTrades()

        switch firstResponse {
        case .success(let page):
            XCTAssertTrue(page.hasNextPage())
            XCTAssertEqual(page.records.count, 1)
            XCTAssertEqual(page.records.first?.id, "1")

            let nextPageResponse = await page.getNextPage()
            switch nextPageResponse {
            case .success(let nextPage):
                XCTAssertEqual(nextPage.records.count, 1)
                XCTAssertEqual(nextPage.records.first?.id, "2")
            case .failure(let error):
                XCTFail("Next page request failed: \(error)")
            }
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPageResponseGetPreviousPage() async {
        let firstPageResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon-testnet.stellar.org/trades/2"},
                            "base": {"href": "https://horizon-testnet.stellar.org/accounts/GBASE"},
                            "counter": {"href": "https://horizon-testnet.stellar.org/accounts/GCOUNTER"},
                            "operation": {"href": "https://horizon-testnet.stellar.org/operations/2"}
                        },
                        "id": "2",
                        "paging_token": "2",
                        "ledger_close_time": "2022-01-02T00:00:00Z",
                        "trade_type": "orderbook",
                        "base_offer_id": "3",
                        "base_account": "GBASE",
                        "base_amount": "200.0000000",
                        "base_asset_type": "native",
                        "counter_offer_id": "4",
                        "counter_account": "GCOUNTER",
                        "counter_amount": "100.0000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "USD",
                        "counter_asset_issuer": "GISSUER",
                        "base_is_seller": true,
                        "price": {
                            "n": 1,
                            "d": 2
                        }
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=123"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=456"
                }
            }
        }
        """

        let prevPageResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon-testnet.stellar.org/trades/1"},
                            "base": {"href": "https://horizon-testnet.stellar.org/accounts/GBASE"},
                            "counter": {"href": "https://horizon-testnet.stellar.org/accounts/GCOUNTER"},
                            "operation": {"href": "https://horizon-testnet.stellar.org/operations/1"}
                        },
                        "id": "1",
                        "paging_token": "1",
                        "ledger_close_time": "2022-01-01T00:00:00Z",
                        "trade_type": "orderbook",
                        "base_offer_id": "1",
                        "base_account": "GBASE",
                        "base_amount": "100.0000000",
                        "base_asset_type": "native",
                        "counter_offer_id": "2",
                        "counter_account": "GCOUNTER",
                        "counter_amount": "50.0000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "USD",
                        "counter_asset_issuer": "GISSUER",
                        "base_is_seller": true,
                        "price": {
                            "n": 1,
                            "d": 2
                        }
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades?cursor=456"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            if url.absoluteString.contains("cursor=456") {
                return prevPageResponse
            } else {
                return firstPageResponse
            }
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                    path: "/trades",
                                    httpMethod: "GET",
                                    mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let firstResponse = await sdk.trades.getTrades()

        switch firstResponse {
        case .success(let page):
            XCTAssertTrue(page.hasPreviousPage())
            XCTAssertEqual(page.records.count, 1)
            XCTAssertEqual(page.records.first?.id, "2")

            let prevPageResponse = await page.getPreviousPage()
            switch prevPageResponse {
            case .success(let prevPage):
                XCTAssertEqual(prevPage.records.count, 1)
                XCTAssertEqual(prevPage.records.first?.id, "1")
            case .failure(let error):
                XCTFail("Previous page request failed: \(error)")
            }
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPageResponseGetNextPageNotFound() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades()

        switch response {
        case .success(let page):
            XCTAssertFalse(page.hasNextPage())

            let nextPageResponse = await page.getNextPage()
            switch nextPageResponse {
            case .success(_):
                XCTFail("Expected error but got success")
            case .failure(let error):
                switch error {
                case .notFound(let message, _):
                    XCTAssertTrue(message.contains("next page not found"))
                default:
                    XCTFail("Expected notFound error but got: \(error)")
                }
            }
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPageResponseGetPreviousPageNotFound() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades()

        switch response {
        case .success(let page):
            XCTAssertFalse(page.hasPreviousPage())

            let prevPageResponse = await page.getPreviousPage()
            switch prevPageResponse {
            case .success(_):
                XCTFail("Expected error but got success")
            case .failure(let error):
                switch error {
                case .notFound(let message, _):
                    XCTAssertTrue(message.contains("previous page not found"))
                default:
                    XCTFail("Expected notFound error but got: \(error)")
                }
            }
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - OrderbookService Tests

    func testGetOrderbookWithAllParameters() async {
        let mockResponse = """
        {
            "bids": [
                {
                    "price_r": {"n": 1, "d": 2},
                    "price": "0.5000000",
                    "amount": "100.0000000"
                }
            ],
            "asks": [
                {
                    "price_r": {"n": 2, "d": 1},
                    "price": "2.0000000",
                    "amount": "50.0000000"
                }
            ],
            "base": {
                "asset_type": "native"
            },
            "counter": {
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GISSUER"
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/order_book"))
            XCTAssertTrue(url.absoluteString.contains("selling_asset_type=credit_alphanum4"))
            XCTAssertTrue(url.absoluteString.contains("selling_asset_code=EUR"))
            XCTAssertTrue(url.absoluteString.contains("selling_asset_issuer=GSELLINGISSUER"))
            XCTAssertTrue(url.absoluteString.contains("buying_asset_type=credit_alphanum4"))
            XCTAssertTrue(url.absoluteString.contains("buying_asset_code=USD"))
            XCTAssertTrue(url.absoluteString.contains("buying_asset_issuer=GBUYINGISSUER"))
            XCTAssertTrue(url.absoluteString.contains("limit=100"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/order_book",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.orderbooks.getOrderbook(
            sellingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            sellingAssetCode: "EUR",
            sellingAssetIssuer: "GSELLINGISSUER",
            buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GBUYINGISSUER",
            limit: 100
        )

        switch response {
        case .success(let orderbook):
            XCTAssertNotNil(orderbook.bids)
            XCTAssertNotNil(orderbook.asks)
            XCTAssertEqual(orderbook.bids.count, 1)
            XCTAssertEqual(orderbook.asks.count, 1)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetOrderbookWithNativeSellingAsset() async {
        let mockResponse = """
        {
            "bids": [],
            "asks": [],
            "base": {
                "asset_type": "native"
            },
            "counter": {
                "asset_type": "credit_alphanum12",
                "asset_code": "LONGASSET123",
                "asset_issuer": "GISSUER"
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("selling_asset_type=native"))
            XCTAssertTrue(url.absoluteString.contains("buying_asset_type=credit_alphanum12"))
            XCTAssertTrue(url.absoluteString.contains("buying_asset_code=LONGASSET123"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/order_book",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.orderbooks.getOrderbook(
            sellingAssetType: AssetTypeAsString.NATIVE,
            buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM12,
            buyingAssetCode: "LONGASSET123",
            buyingAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let orderbook):
            XCTAssertNotNil(orderbook)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testOrderbookStreamCreation() {
        let streamItem = sdk.orderbooks.stream(for: .orderbook(
            sellingAssetType: AssetTypeAsString.NATIVE,
            sellingAssetCode: nil,
            sellingAssetIssuer: nil,
            buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GISSUER",
            limit: 20,
            cursor: "test_cursor"
        ))

        XCTAssertNotNil(streamItem)
    }

    func testOrderbookParsingError() async {
        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/order_book",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.orderbooks.getOrderbook(
            sellingAssetType: AssetTypeAsString.NATIVE,
            buyingAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            buyingAssetCode: "USD",
            buyingAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - TradesService Tests

    func testGetTradesWithAllParameters() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon-testnet.stellar.org/trades/1"},
                            "base": {"href": "https://horizon-testnet.stellar.org/accounts/GBASE"},
                            "counter": {"href": "https://horizon-testnet.stellar.org/accounts/GCOUNTER"},
                            "operation": {"href": "https://horizon-testnet.stellar.org/operations/1"}
                        },
                        "id": "1",
                        "paging_token": "1",
                        "ledger_close_time": "2022-01-01T00:00:00Z",
                        "trade_type": "orderbook",
                        "base_offer_id": "100",
                        "base_account": "GBASE",
                        "base_amount": "100.0000000",
                        "base_asset_type": "native",
                        "counter_offer_id": "200",
                        "counter_account": "GCOUNTER",
                        "counter_amount": "50.0000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "USD",
                        "counter_asset_issuer": "GISSUER",
                        "base_is_seller": true,
                        "price": {
                            "n": 1,
                            "d": 2
                        }
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/trades"))
            XCTAssertTrue(url.absoluteString.contains("base_asset_type=native"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_type=credit_alphanum4"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_code=USD"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_issuer=GISSUER"))
            XCTAssertTrue(url.absoluteString.contains("cursor=test123"))
            XCTAssertTrue(url.absoluteString.contains("order=asc"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER",
            cursor: "test123",
            order: .ascending,
            limit: 50
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertEqual(page.records.count, 1)
            if let trade = page.records.first {
                XCTAssertEqual(trade.id, "1")
                XCTAssertEqual(trade.baseAmount, "100.0000000")
            }
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradesWithOfferId() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("offer_id=12345"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades(offerId: "12345")

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradesForAccountWithParameters() async {
        let accountId = "GACCOUNT123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/trades"))
            XCTAssertTrue(url.absoluteString.contains("cursor=abc123"))
            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            XCTAssertTrue(url.absoluteString.contains("limit=25"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/\(accountId)/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades(forAccount: accountId, from: "abc123", order: .descending, limit: 25)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradesForAccountOnly() async {
        let accountId = "GACCOUNT456"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/trades"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/\(accountId)/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades(forAccount: accountId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradesWithLiquidityPoolId() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("liquidity_pool_id=\(poolId)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades(forLiquidityPool: poolId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradesWithTradeType() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("trade_type=liquidity_pool"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades(tradeType: "liquidity_pool")

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testTradesStreamAllTrades() {
        let streamItem = sdk.trades.stream(for: .allTrades(
            baseAssetType: AssetTypeAsString.NATIVE,
            baseAssetCode: nil,
            baseAssetIssuer: nil,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER",
            cursor: "test_cursor",
            order: .ascending,
            limit: 50
        ))

        XCTAssertNotNil(streamItem)
    }

    func testTradesStreamForAccount() {
        let accountId = "GACCOUNT123"
        let streamItem = sdk.trades.stream(for: .tradesForAccount(
            account: accountId,
            cursor: "test_cursor"
        ))

        XCTAssertNotNil(streamItem)
    }

    func testTradesStreamForAccountNoCursor() {
        let accountId = "GACCOUNT456"
        let streamItem = sdk.trades.stream(for: .tradesForAccount(
            account: accountId,
            cursor: nil
        ))

        XCTAssertNotNil(streamItem)
    }

    func testTradesParsingError() async {
        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.trades.getTrades()

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - LiquidityPoolsService Tests

    func testGetLiquidityPool() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(poolId)"
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(poolId)/transactions{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(poolId)/operations{?cursor,limit,order}",
                    "templated": true
                }
            },
            "id": "\(poolId)",
            "paging_token": "123",
            "fee_bp": 30,
            "type": "constant_product",
            "total_trustlines": "100",
            "total_shares": "10000.0000000",
            "reserves": [
                {
                    "amount": "5000.0000000",
                    "asset": "native"
                },
                {
                    "amount": "5000.0000000",
                    "asset": "USD:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
                }
            ],
            "last_modified_ledger": 12345,
            "last_modified_time": "2022-01-01T00:00:00Z"
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/liquidity_pools/\(poolId)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(poolId)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)

        switch response {
        case .success(let pool):
            XCTAssertEqual(pool.poolId, poolId)
            XCTAssertEqual(pool.totalShares, "10000.0000000")
            XCTAssertEqual(pool.reserves.count, 2)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetLiquidityPoolWithLAddress() async {
        let hexId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let lAddress = try! hexId.data(using: .hexadecimal)!.encodeLiquidityPoolId()
        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(hexId)"
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(hexId)/effects{?cursor,limit,order}",
                    "templated": true
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(hexId)/transactions{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(hexId)/operations{?cursor,limit,order}",
                    "templated": true
                }
            },
            "id": "\(hexId)",
            "paging_token": "123",
            "fee_bp": 30,
            "type": "constant_product",
            "total_trustlines": "100",
            "total_shares": "10000.0000000",
            "reserves": [
                {
                    "amount": "5000.0000000",
                    "asset": "native"
                },
                {
                    "amount": "5000.0000000",
                    "asset": "USD:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
                }
            ],
            "last_modified_ledger": 12345,
            "last_modified_time": "2022-01-01T00:00:00Z"
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(hexId)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: lAddress)

        switch response {
        case .success(let pool):
            XCTAssertEqual(pool.poolId, hexId)
            XCTAssertEqual(pool.totalShares, "10000.0000000")
            XCTAssertEqual(pool.fee, 30)
            XCTAssertEqual(pool.type, "constant_product")
            XCTAssertEqual(pool.reserves.count, 2)
        case .failure(let error):
            XCTFail("Request failed with error: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetLiquidityPoolsWithAllParameters() async {
        let accountId = "GACCOUNT123"
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("account=\(accountId)"))
            XCTAssertTrue(url.absoluteString.contains("cursor=test123"))
            XCTAssertTrue(url.absoluteString.contains("order=asc"))
            XCTAssertTrue(url.absoluteString.contains("limit=100"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPools(
            account: accountId,
            cursor: "test123",
            order: .ascending,
            limit: 100
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetLiquidityPoolsNoFilters() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPools()

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetLiquidityPoolsByReserveAssets() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("reserves=native"))
            XCTAssertTrue(url.absoluteString.contains("USD:GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"))
            XCTAssertTrue(url.absoluteString.contains("cursor=test456"))
            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let nativeAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let usdAsset = Asset(canonicalForm: "USD:GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")!

        let response = await sdk.liquidityPools.getLiquidityPools(
            reserveAssetA: nativeAsset,
            reserveAssetB: usdAsset,
            cursor: "test456",
            order: .descending,
            limit: 50
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetLiquidityPoolTrades() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(poolId)/trades"
                }
            },
            "_embedded": {
                "records": []
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/liquidity_pools/\(poolId)/trades"))
            XCTAssertTrue(url.absoluteString.contains("cursor=trade123"))
            XCTAssertTrue(url.absoluteString.contains("order=asc"))
            XCTAssertTrue(url.absoluteString.contains("limit=75"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(poolId)/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPoolTrades(
            poolId: poolId,
            cursor: "trade123",
            order: .ascending,
            limit: 75
        )

        switch response {
        case .success(let trades):
            XCTAssertNotNil(trades)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetLiquidityPoolTradesNoFilters() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/liquidity_pools/\(poolId)/trades"
                }
            },
            "_embedded": {
                "records": []
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(poolId)/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPoolTrades(poolId: poolId)

        switch response {
        case .success(let trades):
            XCTAssertNotNil(trades)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testLiquidityPoolTradesStream() {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let streamItem = sdk.liquidityPools.streamTrades(forPoolId: poolId)

        XCTAssertNotNil(streamItem)
    }

    func testLiquidityPoolTradesStreamWithLAddress() {
        let lAddress = "LABCD1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF12345"
        let streamItem = sdk.liquidityPools.streamTrades(forPoolId: lAddress)

        XCTAssertNotNil(streamItem)
    }

    func testLiquidityPoolsParsingError() async {
        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPools()

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testLiquidityPoolDetailsParsingError() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"

        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(poolId)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testLiquidityPoolTradesParsingError() async {
        let poolId = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"

        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(poolId)/trades",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPoolTrades(poolId: poolId)

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testLiquidityPoolNotFound() async {
        let poolId = "notfound123"

        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "type": "https://stellar.org/horizon-errors/not_found",
                "title": "Resource Missing",
                "status": 404,
                "detail": "The resource at the url requested was not found."
            }
            """
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(poolId)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.liquidityPools.getLiquidityPool(poolId: poolId)

        switch response {
        case .success(_):
            XCTFail("Expected error but got success")
        case .failure(let error):
            switch error {
            case .notFound(let message, _):
                XCTAssertFalse(message.isEmpty, "Not found message should not be empty")
            default:
                XCTFail("Expected notFound error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - TradeAggregationsService Tests

    func testGetTradeAggregationsBasic() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "timestamp": "1609459200000",
                        "trade_count": "42",
                        "base_volume": "1000.0000000",
                        "counter_volume": "500.0000000",
                        "avg": "0.5000000",
                        "high": "0.6000000",
                        "low": "0.4000000",
                        "open": "0.4500000",
                        "close": "0.5500000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("/trade_aggregations"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertEqual(page.records.count, 1)
            let aggregation = page.records.first!
            XCTAssertEqual(aggregation.timestamp, "1609459200000")
            XCTAssertEqual(aggregation.tradeCount, "42")
            XCTAssertEqual(aggregation.baseVolume, "1000.0000000")
            XCTAssertEqual(aggregation.counterVolume, "500.0000000")
            XCTAssertEqual(aggregation.averagePrice, "0.5000000")
            XCTAssertEqual(aggregation.highPrice, "0.6000000")
            XCTAssertEqual(aggregation.lowPrice, "0.4000000")
            XCTAssertEqual(aggregation.openPrice, "0.4500000")
            XCTAssertEqual(aggregation.closePrice, "0.5500000")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithResolution1Min() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("resolution=60000"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            resolution: 60000, // 1 minute
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithResolution1Hour() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("resolution=3600000"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            resolution: 3600000, // 1 hour
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithResolution1Day() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("resolution=86400000"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            resolution: 86400000, // 1 day
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithResolution1Week() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("resolution=604800000"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            resolution: 604800000, // 1 week
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithTimeRange() async {
        let startTime: Int64 = 1609459200000
        let endTime: Int64 = 1609545600000
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("start_time=\(startTime)"))
            XCTAssertTrue(url.absoluteString.contains("end_time=\(endTime)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            startTime: startTime,
            endTime: endTime,
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithOrder() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER",
            order: .descending
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithLimit() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("limit=100"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER",
            limit: 100
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithCursor() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("cursor=123456789"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER",
            cursor: "123456789"
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithAllParameters() async {
        let startTime: Int64 = 1609459200000
        let endTime: Int64 = 1609545600000
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "timestamp": "1609459200000",
                        "trade_count": "100",
                        "base_volume": "5000.0000000",
                        "counter_volume": "2500.0000000",
                        "avg": "0.5000000",
                        "high": "0.7000000",
                        "low": "0.3000000",
                        "open": "0.4000000",
                        "close": "0.6000000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations?cursor=next123"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("start_time=\(startTime)"))
            XCTAssertTrue(url.absoluteString.contains("end_time=\(endTime)"))
            XCTAssertTrue(url.absoluteString.contains("resolution=3600000"))
            XCTAssertTrue(url.absoluteString.contains("base_asset_type=credit_alphanum4"))
            XCTAssertTrue(url.absoluteString.contains("base_asset_code=EUR"))
            XCTAssertTrue(url.absoluteString.contains("base_asset_issuer=GBASEISSUER"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_type=credit_alphanum4"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_code=USD"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_issuer=GCOUNTERISSUER"))
            XCTAssertTrue(url.absoluteString.contains("cursor=test_cursor"))
            XCTAssertTrue(url.absoluteString.contains("order=asc"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            startTime: startTime,
            endTime: endTime,
            resolution: 3600000,
            baseAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            baseAssetCode: "EUR",
            baseAssetIssuer: "GBASEISSUER",
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GCOUNTERISSUER",
            cursor: "test_cursor",
            order: .ascending,
            limit: 50
        )

        switch response {
        case .success(let page):
            XCTAssertEqual(page.records.count, 1)
            XCTAssertTrue(page.hasNextPage())
            let aggregation = page.records.first!
            XCTAssertEqual(aggregation.tradeCount, "100")
            XCTAssertEqual(aggregation.baseVolume, "5000.0000000")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsParsingError() async {
        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(_):
                XCTAssertNotNil(error)
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsNotFound() async {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "type": "https://stellar.org/horizon-errors/not_found",
                "title": "Resource Missing",
                "status": 404,
                "detail": "The resource at the url requested was not found."
            }
            """
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(_):
            XCTFail("Expected error but got success")
        case .failure(let error):
            switch error {
            case .notFound(_, _):
                XCTAssertNotNil(error)
            default:
                XCTFail("Expected notFound error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testTradeAggregationResponseFullParsing() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "timestamp": "1609459200000",
                        "trade_count": "150",
                        "base_volume": "10000.0000000",
                        "counter_volume": "5000.0000000",
                        "avg": "0.5000000",
                        "high": "0.8000000",
                        "low": "0.2000000",
                        "open": "0.3000000",
                        "close": "0.7000000"
                    },
                    {
                        "timestamp": "1609462800000",
                        "trade_count": "200",
                        "base_volume": "15000.0000000",
                        "counter_volume": "7500.0000000",
                        "avg": "0.5000000",
                        "high": "0.9000000",
                        "low": "0.1000000",
                        "open": "0.7000000",
                        "close": "0.4000000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations?cursor=next456"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations?cursor=prev789"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.CREDIT_ALPHANUM4,
            counterAssetCode: "USD",
            counterAssetIssuer: "GISSUER"
        )

        switch response {
        case .success(let page):
            XCTAssertEqual(page.records.count, 2)
            XCTAssertTrue(page.hasNextPage())
            XCTAssertTrue(page.hasPreviousPage())

            let first = page.records[0]
            XCTAssertEqual(first.timestamp, "1609459200000")
            XCTAssertEqual(first.tradeCount, "150")
            XCTAssertEqual(first.baseVolume, "10000.0000000")
            XCTAssertEqual(first.counterVolume, "5000.0000000")
            XCTAssertEqual(first.averagePrice, "0.5000000")
            XCTAssertEqual(first.highPrice, "0.8000000")
            XCTAssertEqual(first.lowPrice, "0.2000000")
            XCTAssertEqual(first.openPrice, "0.3000000")
            XCTAssertEqual(first.closePrice, "0.7000000")

            let second = page.records[1]
            XCTAssertEqual(second.timestamp, "1609462800000")
            XCTAssertEqual(second.tradeCount, "200")
            XCTAssertEqual(second.baseVolume, "15000.0000000")
            XCTAssertEqual(second.counterVolume, "7500.0000000")
            XCTAssertEqual(second.highPrice, "0.9000000")
            XCTAssertEqual(second.lowPrice, "0.1000000")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsFromUrl() async {
        let customUrl = "https://horizon-testnet.stellar.org/trade_aggregations?base_asset_type=native&counter_asset_type=credit_alphanum4&counter_asset_code=USD&counter_asset_issuer=GISSUER&resolution=3600000"
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "timestamp": "1609459200000",
                        "trade_count": "75",
                        "base_volume": "2500.0000000",
                        "counter_volume": "1250.0000000",
                        "avg": "0.5000000",
                        "high": "0.5500000",
                        "low": "0.4500000",
                        "open": "0.4800000",
                        "close": "0.5200000"
                    }
                ]
            },
            "_links": {
                "self": {
                    "href": "\(customUrl)"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregationsFromUrl(url: customUrl)

        switch response {
        case .success(let page):
            XCTAssertEqual(page.records.count, 1)
            let aggregation = page.records.first!
            XCTAssertEqual(aggregation.tradeCount, "75")
            XCTAssertEqual(aggregation.baseVolume, "2500.0000000")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTradeAggregationsWithNativeAssets() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": []
            },
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trade_aggregations"
                }
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return ""
            }

            XCTAssertTrue(url.absoluteString.contains("base_asset_type=native"))
            XCTAssertTrue(url.absoluteString.contains("counter_asset_type=native"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/trade_aggregations",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.tradeAggregations.getTradeAggregations(
            baseAssetType: AssetTypeAsString.NATIVE,
            counterAssetType: AssetTypeAsString.NATIVE
        )

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.links)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }
}
