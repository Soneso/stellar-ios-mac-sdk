//
//  Sep38DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-38 documentation code examples.
//  Uses ServerMock/RequestMock/ResponsesMock infrastructure for HTTP mocking.
//

import XCTest
import stellarsdk

// MARK: - Mock helpers (scoped to this file)

/// Provides GET /info mock response for SEP-38 quote service.
private class Sep38DocInfoResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "assets": [
                    {
                        "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                        "sell_delivery_methods": [
                            {"name": "wire", "description": "Wire transfer"}
                        ],
                        "buy_delivery_methods": [
                            {"name": "wire", "description": "Wire transfer"}
                        ]
                    },
                    {
                        "asset": "iso4217:USD",
                        "sell_delivery_methods": [
                            {"name": "ACH", "description": "ACH bank transfer"},
                            {"name": "wire", "description": "Wire transfer"}
                        ],
                        "buy_delivery_methods": [
                            {"name": "ACH", "description": "ACH bank transfer"}
                        ],
                        "country_codes": ["USA"]
                    },
                    {
                        "asset": "iso4217:BRL",
                        "sell_delivery_methods": [
                            {"name": "PIX", "description": "PIX instant transfer"}
                        ],
                        "buy_delivery_methods": [
                            {"name": "PIX", "description": "PIX instant transfer"}
                        ],
                        "country_codes": ["BRA"]
                    }
                ]
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/sep38/info",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /prices mock response.
private class Sep38DocPricesResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "buy_assets": [
                    {
                        "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                        "price": "0.18",
                        "decimals": 7
                    },
                    {
                        "asset": "iso4217:BRL",
                        "price": "5.42",
                        "decimals": 2
                    }
                ]
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/sep38/prices",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /price mock response.
private class Sep38DocPriceResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "total_price": "1.02",
                "price": "1.00",
                "sell_amount": "102.00",
                "buy_amount": "100.00",
                "fee": {
                    "total": "2.00",
                    "asset": "iso4217:USD",
                    "details": [
                        {"name": "Service fee", "amount": "1.50", "description": "Anchor processing fee"},
                        {"name": "Network fee", "amount": "0.50"}
                    ]
                }
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/sep38/price",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides POST /quote mock response.
private class Sep38DocPostQuoteResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            let expiresAt = ISO8601DateFormatter.full.string(from: Date(timeIntervalSinceNow: 3600))
            return """
            {
                "id": "de762cda-a193-4961-861e-57b31fed6eb3",
                "expires_at": "\(expiresAt)",
                "total_price": "1.02",
                "price": "1.00",
                "sell_asset": "iso4217:USD",
                "sell_amount": "102.00",
                "buy_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "buy_amount": "100.00",
                "fee": {
                    "total": "2.00",
                    "asset": "iso4217:USD",
                    "details": [
                        {"name": "Service fee", "amount": "1.50", "description": "Anchor processing fee"},
                        {"name": "Network fee", "amount": "0.50"}
                    ]
                }
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/sep38/quote",
            httpMethod: "POST",
            mockHandler: handler
        )
    }
}

/// Provides GET /quote/:id mock response.
private class Sep38DocGetQuoteResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            let expiresAt = ISO8601DateFormatter.full.string(from: Date(timeIntervalSinceNow: 3600))
            return """
            {
                "id": "de762cda-a193-4961-861e-57b31fed6eb3",
                "expires_at": "\(expiresAt)",
                "total_price": "1.02",
                "price": "1.00",
                "sell_asset": "iso4217:USD",
                "sell_amount": "102.00",
                "buy_asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "buy_amount": "100.00",
                "fee": {
                    "total": "2.00",
                    "asset": "iso4217:USD"
                }
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/sep38/quote/*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /price mock that returns 400 (bad request).
private class Sep38DocBadRequestResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {"error": "unsupported asset pair"}
            """
        }

        return RequestMock(
            host: address,
            path: "/sep38/price",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

// MARK: - Test class

class Sep38DocTest: XCTestCase {

    let quoteServerHost = "quote.anchor.example.com"
    let quoteServerAddress = "http://quote.anchor.example.com/sep38"
    let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"

    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
    }

    // MARK: - Snippet 1: Quick example (info + prices)

    func testQuickExample() async {
        let infoMock = Sep38DocInfoResponseMock(address: quoteServerHost)
        let pricesMock = Sep38DocPricesResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        // Get available assets for trading
        let infoResult = await quoteService.info()
        switch infoResult {
        case .success(let info):
            XCTAssertEqual(info.assets.count, 3)
            XCTAssertEqual(info.assets[0].asset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
        case .failure(let error):
            XCTFail("info() failed: \(error)")
            return
        }

        // Get indicative prices for selling 100 USD
        let pricesResult = await quoteService.prices(
            sellAsset: "iso4217:USD",
            sellAmount: "100"
        )

        switch pricesResult {
        case .success(let prices):
            XCTAssertEqual(prices.buyAssets.count, 2)
            XCTAssertEqual(prices.buyAssets[0].asset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssertEqual(prices.buyAssets[0].price, "0.18")
        case .failure(let error):
            XCTFail("prices() failed: \(error)")
        }
    }

    // MARK: - Snippet 2: Creating service from stellar.toml (direct URL)

    func testCreateServiceDirectUrl() {
        let quoteService = QuoteService(serviceAddress: "https://anchor.example.com/sep38")
        XCTAssertEqual(quoteService.serviceAddress, "https://anchor.example.com/sep38")
    }

    // MARK: - Snippet 3: Getting available assets (GET /info)

    func testGetInfo() async {
        let infoMock = Sep38DocInfoResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let infoResult = await quoteService.info(jwt: jwtToken)
        switch infoResult {
        case .success(let info):
            XCTAssertEqual(info.assets.count, 3)

            // Check Stellar asset
            let stellarAsset = info.assets[0]
            XCTAssertEqual(stellarAsset.asset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssertNotNil(stellarAsset.sellDeliveryMethods)
            XCTAssertNotNil(stellarAsset.buyDeliveryMethods)
            XCTAssertNil(stellarAsset.countryCodes)

            // Check fiat asset with country codes
            let usdAsset = info.assets[1]
            XCTAssertEqual(usdAsset.asset, "iso4217:USD")
            XCTAssertNotNil(usdAsset.countryCodes)
            XCTAssertEqual(usdAsset.countryCodes?.first, "USA")

            // Check delivery methods
            XCTAssertEqual(usdAsset.sellDeliveryMethods?.count, 2)
            XCTAssertEqual(usdAsset.sellDeliveryMethods?[0].name, "ACH")
            XCTAssertEqual(usdAsset.sellDeliveryMethods?[0].description, "ACH bank transfer")

            // Check BRL asset
            let brlAsset = info.assets[2]
            XCTAssertEqual(brlAsset.asset, "iso4217:BRL")
            XCTAssertEqual(brlAsset.countryCodes?.first, "BRA")
            XCTAssertEqual(brlAsset.sellDeliveryMethods?.first?.name, "PIX")

        case .failure(let error):
            XCTFail("info() failed: \(error)")
        }
    }

    // MARK: - Snippet 4: Getting indicative prices (GET /prices)

    func testGetPrices() async {
        let pricesMock = Sep38DocPricesResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let pricesResult = await quoteService.prices(
            sellAsset: "iso4217:USD",
            sellAmount: "100",
            jwt: jwtToken
        )

        switch pricesResult {
        case .success(let prices):
            XCTAssertEqual(prices.buyAssets.count, 2)
            XCTAssertEqual(prices.buyAssets[0].price, "0.18")
            XCTAssertEqual(prices.buyAssets[0].decimals, 7)
            XCTAssertEqual(prices.buyAssets[1].asset, "iso4217:BRL")
            XCTAssertEqual(prices.buyAssets[1].price, "5.42")
            XCTAssertEqual(prices.buyAssets[1].decimals, 2)
        case .failure(let error):
            XCTFail("prices() failed: \(error)")
        }
    }

    // MARK: - Snippet 5: Getting prices with delivery method and country code

    func testGetPricesWithDeliveryMethod() async {
        let pricesMock = Sep38DocPricesResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let pricesResult = await quoteService.prices(
            sellAsset: "iso4217:BRL",
            sellAmount: "500",
            sellDeliveryMethod: "PIX",
            countryCode: "BRA",
            jwt: jwtToken
        )

        switch pricesResult {
        case .success(let prices):
            XCTAssertFalse(prices.buyAssets.isEmpty)
        case .failure(let error):
            XCTFail("prices() with delivery method failed: \(error)")
        }
    }

    // MARK: - Snippet 6: Getting a price for a specific pair (GET /price)

    func testGetPrice() async {
        let priceMock = Sep38DocPriceResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let priceResult = await quoteService.price(
            context: "sep6",
            sellAsset: "iso4217:USD",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            sellAmount: "100",
            jwt: jwtToken
        )

        switch priceResult {
        case .success(let price):
            XCTAssertEqual(price.totalPrice, "1.02")
            XCTAssertEqual(price.price, "1.00")
            XCTAssertEqual(price.sellAmount, "102.00")
            XCTAssertEqual(price.buyAmount, "100.00")
            XCTAssertEqual(price.fee.total, "2.00")
            XCTAssertEqual(price.fee.asset, "iso4217:USD")
        case .failure(let error):
            XCTFail("price() failed: \(error)")
        }
    }

    // MARK: - Snippet 7: Query by buy amount

    func testGetPriceByBuyAmount() async {
        let priceMock = Sep38DocPriceResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let priceResult = await quoteService.price(
            context: "sep6",
            sellAsset: "iso4217:USD",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            buyAmount: "50",
            jwt: jwtToken
        )

        switch priceResult {
        case .success(let price):
            XCTAssertFalse(price.sellAmount.isEmpty)
            XCTAssertFalse(price.buyAmount.isEmpty)
        case .failure(let error):
            XCTFail("price() by buy amount failed: \(error)")
        }
    }

    // MARK: - Snippet 8: Price with delivery methods

    func testGetPriceWithDeliveryMethods() async {
        let priceMock = Sep38DocPriceResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let priceResult = await quoteService.price(
            context: "sep31",
            sellAsset: "iso4217:BRL",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            sellAmount: "500",
            sellDeliveryMethod: "PIX",
            countryCode: "BRA",
            jwt: jwtToken
        )

        switch priceResult {
        case .success(let price):
            XCTAssertFalse(price.totalPrice.isEmpty)
        case .failure(let error):
            XCTFail("price() with delivery methods failed: \(error)")
        }
    }

    // MARK: - Snippet 9: Working with fee details

    func testFeeDetails() async {
        let priceMock = Sep38DocPriceResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let priceResult = await quoteService.price(
            context: "sep6",
            sellAsset: "iso4217:BRL",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            sellAmount: "500",
            jwt: jwtToken
        )

        switch priceResult {
        case .success(let price):
            XCTAssertEqual(price.fee.total, "2.00")
            XCTAssertEqual(price.fee.asset, "iso4217:USD")

            // Check detailed fee breakdown
            XCTAssertNotNil(price.fee.details)
            XCTAssertEqual(price.fee.details?.count, 2)
            XCTAssertEqual(price.fee.details?[0].name, "Service fee")
            XCTAssertEqual(price.fee.details?[0].amount, "1.50")
            XCTAssertEqual(price.fee.details?[0].description, "Anchor processing fee")
            XCTAssertEqual(price.fee.details?[1].name, "Network fee")
            XCTAssertEqual(price.fee.details?[1].amount, "0.50")
            XCTAssertNil(price.fee.details?[1].description)

        case .failure(let error):
            XCTFail("price() for fee details failed: \(error)")
        }
    }

    // MARK: - Snippet 10: Requesting a firm quote (POST /quote)

    func testPostQuote() async {
        let postQuoteMock = Sep38DocPostQuoteResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        var request = Sep38PostQuoteRequest(
            context: "sep6",
            sellAsset: "iso4217:USD",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        )
        request.sellAmount = "100"

        let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)

        switch quoteResult {
        case .success(let quote):
            XCTAssertEqual(quote.id, "de762cda-a193-4961-861e-57b31fed6eb3")
            XCTAssertTrue(quote.expiresAt > Date())
            XCTAssertEqual(quote.totalPrice, "1.02")
            XCTAssertEqual(quote.price, "1.00")
            XCTAssertEqual(quote.sellAsset, "iso4217:USD")
            XCTAssertEqual(quote.sellAmount, "102.00")
            XCTAssertEqual(quote.buyAsset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssertEqual(quote.buyAmount, "100.00")
            XCTAssertEqual(quote.fee.total, "2.00")
        case .failure(let error):
            XCTFail("postQuote() failed: \(error)")
        }
    }

    // MARK: - Snippet 11: Quote with expiration preference

    func testPostQuoteWithExpiration() async {
        let postQuoteMock = Sep38DocPostQuoteResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        var request = Sep38PostQuoteRequest(
            context: "sep6",
            sellAsset: "iso4217:USD",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        )
        request.sellAmount = "100"
        request.expireAfter = Date(timeIntervalSinceNow: 3600)

        let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)

        switch quoteResult {
        case .success(let quote):
            XCTAssertTrue(quote.expiresAt > Date())
        case .failure(let error):
            XCTFail("postQuote() with expiration failed: \(error)")
        }
    }

    // MARK: - Snippet 12: Quote with delivery methods

    func testPostQuoteWithDeliveryMethods() async {
        let postQuoteMock = Sep38DocPostQuoteResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        var request = Sep38PostQuoteRequest(
            context: "sep6",
            sellAsset: "iso4217:BRL",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        )
        request.sellAmount = "1000"
        request.sellDeliveryMethod = "ACH"
        request.countryCode = "BRA"

        let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)

        switch quoteResult {
        case .success(let quote):
            XCTAssertFalse(quote.id.isEmpty)
        case .failure(let error):
            XCTFail("postQuote() with delivery methods failed: \(error)")
        }
    }

    // MARK: - Snippet 13: Retrieving a previous quote (GET /quote/:id)

    func testGetQuote() async {
        let getQuoteMock = Sep38DocGetQuoteResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let quoteId = "de762cda-a193-4961-861e-57b31fed6eb3"
        let quoteResult = await quoteService.getQuote(id: quoteId, jwt: jwtToken)

        switch quoteResult {
        case .success(let quote):
            XCTAssertEqual(quote.id, "de762cda-a193-4961-861e-57b31fed6eb3")
            XCTAssertTrue(quote.expiresAt > Date())
            XCTAssertEqual(quote.totalPrice, "1.02")
            XCTAssertEqual(quote.sellAsset, "iso4217:USD")
            XCTAssertEqual(quote.buyAsset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            // Fee details not present in this response
            XCTAssertNil(quote.fee.details)
        case .failure(let error):
            XCTFail("getQuote() failed: \(error)")
        }
    }

    // MARK: - Snippet 14: Error handling - invalid argument

    func testErrorHandlingInvalidArgument() async {
        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        // Providing both sellAmount and buyAmount should fail with .invalidArgument
        let priceResult = await quoteService.price(
            context: "sep6",
            sellAsset: "iso4217:USD",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            sellAmount: "100",
            buyAmount: "95"
        )

        switch priceResult {
        case .success:
            XCTFail("Should have failed with invalidArgument")
        case .failure(let error):
            switch error {
            case .invalidArgument:
                break // Expected
            default:
                XCTFail("Expected invalidArgument, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 15: Error handling - neither amount provided

    func testErrorHandlingNeitherAmountForPostQuote() async {
        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        // Not setting sellAmount or buyAmount should fail with .invalidArgument
        let request = Sep38PostQuoteRequest(
            context: "sep6",
            sellAsset: "iso4217:USD",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        )

        let quoteResult = await quoteService.postQuote(request: request, jwt: jwtToken)

        switch quoteResult {
        case .success:
            XCTFail("Should have failed with invalidArgument")
        case .failure(let error):
            switch error {
            case .invalidArgument:
                break // Expected
            default:
                XCTFail("Expected invalidArgument, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 16: Error handling - bad request from server

    func testErrorHandlingBadRequest() async {
        let badRequestMock = Sep38DocBadRequestResponseMock(address: quoteServerHost)

        let quoteService = QuoteService(serviceAddress: quoteServerAddress)

        let priceResult = await quoteService.price(
            context: "sep6",
            sellAsset: "iso4217:INVALID",
            buyAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
            sellAmount: "100"
        )

        switch priceResult {
        case .success:
            XCTFail("Should have failed with badRequest")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual(message, "unsupported asset pair")
            default:
                XCTFail("Expected badRequest, got: \(error)")
            }
        }
    }
}
