//
//  QuoteServiceTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class QuoteServiceTestCase: XCTestCase {
    let quoteServer = "127.0.0.1"
    let jwtToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

    var quoteService: QuoteService!
    var sep38InfoMock: Sep38InfoResponseMock!
    var sep38PricesMock: Sep38PricesResponseMock!
    var sep38PriceMock: Sep38PriceResponseMock!
    var sep38PostQuoteMock: Sep38PostQuoteResponseMock!
    var sep38GetQuoteMock: Sep38GetQuoteResponseMock!

    override func setUp() {
        super.setUp()

        ServerMock.removeAll()
        URLProtocol.registerClass(ServerMock.self)
        sep38InfoMock = Sep38InfoResponseMock(host: quoteServer)
        sep38PricesMock = Sep38PricesResponseMock(host: quoteServer)
        sep38PriceMock = Sep38PriceResponseMock(host: quoteServer)
        sep38PostQuoteMock = Sep38PostQuoteResponseMock(host: quoteServer)
        sep38GetQuoteMock = Sep38GetQuoteResponseMock(host: quoteServer)
        ServerMock.add(mock: sep38GetQuoteMock.notFoundRequestMock())
        ServerMock.add(mock: sep38GetQuoteMock.badRequestMock())
        ServerMock.add(mock: sep38GetQuoteMock.forbiddenRequestMock())
        ServerMock.add(mock: sep38GetQuoteMock.expiredQuoteMock())
        ServerMock.add(mock: sep38GetQuoteMock.noFeeDetailsRequestMock())
        ServerMock.add(mock: sep38GetQuoteMock.malformedResponseMock())
        quoteService = QuoteService(serviceAddress: "http://\(quoteServer)")

    }

    // MARK: - Info Endpoint Tests

    func testGetInfo() async {
        let responseEnum = await quoteService.info(jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(3, response.assets.count)
            let assets = response.assets
            XCTAssertEqual("stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN", assets[0].asset)
            XCTAssertEqual("stellar:BRL:GDVKY2GU2DRXWTBEYJJWSFXIGBZV6AZNBVVSUHEPZI54LIS6BA7DVVSP", assets[1].asset)
            XCTAssertEqual("iso4217:BRL", assets[2].asset)
            XCTAssertNotNil(assets[2].countryCodes)
            XCTAssertEqual(1, assets[2].countryCodes?.count)
            XCTAssertEqual("BRA", assets[2].countryCodes?[0])
            XCTAssertNotNil(assets[2].sellDeliveryMethods)
            XCTAssertEqual(3, assets[2].sellDeliveryMethods?.count)
            XCTAssertEqual("cash", assets[2].sellDeliveryMethods?[0].name)
            XCTAssertEqual("Deposit cash BRL at one of our agent locations.", assets[2].sellDeliveryMethods?[0].description)
            XCTAssertEqual("ACH", assets[2].sellDeliveryMethods?[1].name)
            XCTAssertEqual("Send BRL directly to the Anchor's bank account.", assets[2].sellDeliveryMethods?[1].description)
            XCTAssertEqual("PIX", assets[2].sellDeliveryMethods?[2].name)
            XCTAssertEqual("Send BRL directly to the Anchor's bank account.", assets[2].sellDeliveryMethods?[2].description)
            XCTAssertNotNil(assets[2].buyDeliveryMethods)
            XCTAssertEqual(3, assets[2].buyDeliveryMethods?.count)
            XCTAssertEqual("ACH", assets[2].buyDeliveryMethods?[1].name)
            XCTAssertEqual("Have BRL sent directly to your bank account.", assets[2].buyDeliveryMethods?[1].description)
            XCTAssertEqual("PIX", assets[2].buyDeliveryMethods?[2].name)
            XCTAssertEqual("Have BRL sent directly to the account of your choice.", assets[2].buyDeliveryMethods?[2].description)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetInfoWithoutJwt() async {
        let responseEnum = await quoteService.info(jwt: nil)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(3, response.assets.count)
            XCTAssertEqual("stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN", response.assets[0].asset)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetInfoAssetsWithoutDeliveryMethods() async {
        let responseEnum = await quoteService.info(jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            // First two assets have no delivery methods
            XCTAssertNil(response.assets[0].sellDeliveryMethods)
            XCTAssertNil(response.assets[0].buyDeliveryMethods)
            XCTAssertNil(response.assets[0].countryCodes)
            XCTAssertNil(response.assets[1].sellDeliveryMethods)
            XCTAssertNil(response.assets[1].buyDeliveryMethods)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetInfoBadRequest() async {
        let responseEnum = await quoteService.info(jwt: jwtToken + "_error_bad")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("Invalid request format", message)
            default:
                XCTFail("Expected badRequest error but got: \(error)")
            }
        }
    }

    func testGetInfoForbidden() async {
        let responseEnum = await quoteService.info(jwt: jwtToken + "_error_forbidden")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected permission denied error")
        case .failure(let error):
            switch error {
            case .permissionDenied(let message):
                XCTAssertEqual("Authentication required", message)
            default:
                XCTFail("Expected permissionDenied error but got: \(error)")
            }
        }
    }

    // MARK: - Prices Endpoint Tests

    func testGetPrices() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let sellAmount = "100"
        let countryCode = "BRA"
        let buyDeliveryMethod = "ACH"

        let responseEnum = await quoteService.prices(sellAsset: sellAsset,
                                                     sellAmount: sellAmount,
                                                     buyDeliveryMethod: buyDeliveryMethod,
                                                     countryCode: countryCode,
                                                     jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(1, response.buyAssets.count)
            let buyAssets = response.buyAssets
            XCTAssertEqual(1, buyAssets.count)
            XCTAssertEqual("iso4217:BRL", buyAssets[0].asset)
            XCTAssertEqual("0.18", buyAssets[0].price)
            XCTAssertEqual(2, buyAssets[0].decimals)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPricesMinimalParameters() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let sellAmount = "100"

        let responseEnum = await quoteService.prices(sellAsset: sellAsset,
                                                     sellAmount: sellAmount,
                                                     jwt: nil)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.buyAssets.count, 1)
            XCTAssertEqual(response.buyAssets[0].asset, "iso4217:BRL")
            XCTAssertEqual(response.buyAssets[0].price, "0.18")
            XCTAssertEqual(response.buyAssets[0].decimals, 2)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPricesWithAllParameters() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let sellAmount = "100"
        let sellDeliveryMethod = "wire"
        let buyDeliveryMethod = "ACH"
        let countryCode = "USA"

        let responseEnum = await quoteService.prices(sellAsset: sellAsset,
                                                     sellAmount: sellAmount,
                                                     sellDeliveryMethod: sellDeliveryMethod,
                                                     buyDeliveryMethod: buyDeliveryMethod,
                                                     countryCode: countryCode,
                                                     jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.buyAssets.count, 1)
            XCTAssertEqual(response.buyAssets[0].asset, "iso4217:BRL")
            XCTAssertEqual(response.buyAssets[0].price, "0.18")
            XCTAssertEqual(response.buyAssets[0].decimals, 2)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPricesWithSellDeliveryMethodOnly() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let sellAmount = "50"
        let sellDeliveryMethod = "cash"

        let responseEnum = await quoteService.prices(sellAsset: sellAsset,
                                                     sellAmount: sellAmount,
                                                     sellDeliveryMethod: sellDeliveryMethod,
                                                     jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.buyAssets.count, 1)
            XCTAssertEqual(response.buyAssets[0].asset, "iso4217:BRL")
            XCTAssertEqual(response.buyAssets[0].price, "0.18")
            XCTAssertEqual(response.buyAssets[0].decimals, 2)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPricesBadRequest() async {
        let responseEnum = await quoteService.prices(sellAsset: "invalid",
                                                     sellAmount: "100",
                                                     jwt: jwtToken + "_error_bad")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("sell_asset is required", message)
            default:
                XCTFail("Expected badRequest error but got: \(error)")
            }
        }
    }

    func testGetPricesForbidden() async {
        let responseEnum = await quoteService.prices(sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                                                     sellAmount: "100",
                                                     jwt: jwtToken + "_error_forbidden")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected permission denied error")
        case .failure(let error):
            switch error {
            case .permissionDenied(let message):
                XCTAssertEqual("JWT token expired", message)
            default:
                XCTFail("Expected permissionDenied error but got: \(error)")
            }
        }
    }

    // MARK: - Price Endpoint Tests

    func testGetPrice() async {

        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let buyAmount = "500"
        let buyDeliveryMethod = "PIX"
        let countryCode = "BRA"
        let context = "sep31"

        let responseEnum = await quoteService.price(context:context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    buyAmount: buyAmount,
                                                    buyDeliveryMethod: buyDeliveryMethod,
                                                    countryCode: countryCode,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("0.20", response.totalPrice)
            XCTAssertEqual("0.18", response.price)
            XCTAssertEqual("100", response.sellAmount)
            XCTAssertEqual("500", response.buyAmount)
            XCTAssertNotNil(response.fee)
            let fee = response.fee
            XCTAssertEqual("10.00", fee.total)
            XCTAssertEqual("stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN", fee.asset)
            XCTAssertNotNil(fee.details)
            let feeDetails = fee.details
            XCTAssertEqual(2, feeDetails?.count)
            XCTAssertEqual("Service fee", feeDetails?[0].name)
            XCTAssertNil(feeDetails?[0].description)
            XCTAssertEqual("5.00", feeDetails?[0].amount)
            XCTAssertEqual("PIX fee", feeDetails?[1].name)
            XCTAssertEqual("Fee charged in order to process the outgoing BRL PIX transaction.", feeDetails?[1].description)
            XCTAssertEqual("5.00", feeDetails?[1].amount)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPriceSep6Context() async {
        let sellAsset = "iso4217:USD"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let sellAmount = "100"
        let context = "sep6"

        let responseEnum = await quoteService.price(context: context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    sellAmount: sellAmount,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.totalPrice, "0.20")
            XCTAssertEqual(response.price, "0.18")
            XCTAssertEqual(response.sellAmount, "100")
            XCTAssertEqual(response.buyAmount, "500")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPriceWithSellAmount() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let sellAmount = "100"
        let context = "sep31"

        let responseEnum = await quoteService.price(context: context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    sellAmount: sellAmount,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("100", response.sellAmount)
            XCTAssertEqual("500", response.buyAmount)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPriceWithBuyAmount() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let buyAmount = "500"
        let context = "sep31"

        let responseEnum = await quoteService.price(context: context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    buyAmount: buyAmount,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("100", response.sellAmount)
            XCTAssertEqual("500", response.buyAmount)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPriceFeeDetailsPresent() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let buyAmount = "500"
        let context = "sep31"

        let responseEnum = await quoteService.price(context: context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    buyAmount: buyAmount,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.fee.details)
            XCTAssertEqual(2, response.fee.details?.count)
            // Check first fee detail has no description
            XCTAssertNil(response.fee.details?[0].description)
            // Check second fee detail has description
            XCTAssertNotNil(response.fee.details?[1].description)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPriceErr1() async {

        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let buyAmount = "500"
        let buyDeliveryMethod = "PIX"
        let countryCode = "BRA"
        let context = "sep31"

        let responseEnum = await quoteService.price(context:context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    sellAmount: "100",
                                                    buyAmount: buyAmount,
                                                    buyDeliveryMethod: buyDeliveryMethod,
                                                    countryCode: countryCode,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err{
            case .invalidArgument(let message):
                XCTAssertEqual("The caller must provide either sellAmount or buyAmount, but not both", message)
            default:
                XCTFail()
            }
        }
    }

    func testGetPriceErr2() async {

        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let buyDeliveryMethod = "PIX"
        let countryCode = "BRA"
        let context = "sep31"

        let responseEnum = await quoteService.price(context:context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    buyDeliveryMethod: buyDeliveryMethod,
                                                    countryCode: countryCode,
                                                    jwt: jwtToken)

        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err{
            case .invalidArgument(let message):
                XCTAssertEqual("The caller must provide either sellAmount or buyAmount, but not both", message)
            default:
                XCTFail()
            }
        }
    }

    func testGetPriceWithAllDeliveryMethods() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"
        let sellAmount = "100"
        let sellDeliveryMethod = "wire"
        let buyDeliveryMethod = "PIX"
        let countryCode = "BRA"
        let context = "sep31"

        let responseEnum = await quoteService.price(context: context,
                                                    sellAsset: sellAsset,
                                                    buyAsset: buyAsset,
                                                    sellAmount: sellAmount,
                                                    sellDeliveryMethod: sellDeliveryMethod,
                                                    buyDeliveryMethod: buyDeliveryMethod,
                                                    countryCode: countryCode,
                                                    jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.totalPrice, "0.20")
            XCTAssertEqual(response.price, "0.18")
            XCTAssertEqual(response.sellAmount, "100")
            XCTAssertEqual(response.buyAmount, "500")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetPriceBadRequest() async {
        let responseEnum = await quoteService.price(context: "sep31",
                                                    sellAsset: "invalid",
                                                    buyAsset: "invalid",
                                                    sellAmount: "100",
                                                    jwt: jwtToken + "_error_bad")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("sell_asset and buy_asset are required", message)
            default:
                XCTFail("Expected badRequest error but got: \(error)")
            }
        }
    }

    func testGetPriceForbidden() async {
        let responseEnum = await quoteService.price(context: "sep31",
                                                    sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                                                    buyAsset: "iso4217:BRL",
                                                    sellAmount: "100",
                                                    jwt: jwtToken + "_error_forbidden")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected permission denied error")
        case .failure(let error):
            switch error {
            case .permissionDenied(let message):
                XCTAssertEqual("Invalid JWT signature", message)
            default:
                XCTFail("Expected permissionDenied error but got: \(error)")
            }
        }
    }

    // MARK: - PostQuote Endpoint Tests

    func testPostQuote() async {

        let sellAsset = "iso4217:BRL"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"


        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)
        request.buyAmount = "100"
        request.expireAfter = Date.now
        request.sellDeliveryMethod = "PIX"
        request.countryCode = "BRA"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("de762cda-a193-4961-861e-57b31fed6eb3", response.id)
            XCTAssertEqual("5.42", response.totalPrice)
            XCTAssertEqual("5.00", response.price)
            XCTAssertEqual(request.sellAsset, response.sellAsset)
            XCTAssertEqual(request.buyAsset, response.buyAsset)
            XCTAssertEqual("542", response.sellAmount)
            XCTAssertEqual(request.buyAmount, response.buyAmount)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteMinimalRequest() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:USD"

        var request = Sep38PostQuoteRequest(context: "sep6", sellAsset: sellAsset, buyAsset: buyAsset)
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            // The mock always returns the same response
            XCTAssertEqual(response.id, "de762cda-a193-4961-861e-57b31fed6eb3")
            XCTAssertEqual(response.sellAsset, "iso4217:BRL")
            XCTAssertEqual(response.buyAsset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteWithSellAmount() async {
        let sellAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let buyAsset = "iso4217:BRL"

        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.id, "de762cda-a193-4961-861e-57b31fed6eb3")
            XCTAssertEqual(response.sellAmount, "542")
            XCTAssertEqual(response.buyAmount, "100")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteWithBuyAmount() async {
        let sellAsset = "iso4217:BRL"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)
        request.buyAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.id, "de762cda-a193-4961-861e-57b31fed6eb3")
            XCTAssertEqual(response.buyAmount, "100")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteWithAllOptionalFields() async {
        let sellAsset = "iso4217:BRL"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)
        request.buyAmount = "100"
        request.expireAfter = Date(timeIntervalSinceNow: 3600)
        request.sellDeliveryMethod = "PIX"
        request.buyDeliveryMethod = "bank_transfer"
        request.countryCode = "BRA"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.id, "de762cda-a193-4961-861e-57b31fed6eb3")
            XCTAssertEqual(response.sellAsset, "iso4217:BRL")
            XCTAssertEqual(response.buyAsset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
            XCTAssertNotNil(response.expiresAt)
            XCTAssertNotNil(response.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteInvalidArgumentBothAmounts() async {
        let sellAsset = "iso4217:BRL"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)
        request.sellAmount = "100"
        request.buyAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected invalidArgument error")
        case .failure(let error):
            switch error {
            case .invalidArgument(let message):
                XCTAssertEqual("The caller must provide either sellAmount or buyAmount, but not both", message)
            default:
                XCTFail("Expected invalidArgument error but got: \(error)")
            }
        }
    }

    func testPostQuoteInvalidArgumentNoAmounts() async {
        let sellAsset = "iso4217:BRL"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

        let request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected invalidArgument error")
        case .failure(let error):
            switch error {
            case .invalidArgument(let message):
                XCTAssertEqual("The caller must provide either sellAmount or buyAmount, but not both", message)
            default:
                XCTFail("Expected invalidArgument error but got: \(error)")
            }
        }
    }

    func testPostQuoteFeeDetailsWithDescriptions() async {
        let sellAsset = "iso4217:BRL"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: sellAsset, buyAsset: buyAsset)
        request.buyAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.fee.details)
            let details = response.fee.details!
            XCTAssertEqual(3, details.count)
            // Check that some details have descriptions and some don't
            XCTAssertNotNil(details[0].description)
            XCTAssertNotNil(details[1].description)
            XCTAssertNil(details[2].description)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteSep6Context() async {
        let sellAsset = "iso4217:USD"
        let buyAsset = "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

        var request = Sep38PostQuoteRequest(context: "sep6", sellAsset: sellAsset, buyAsset: buyAsset)
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(response.id, "de762cda-a193-4961-861e-57b31fed6eb3")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPostQuoteBadRequest() async {
        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: "invalid", buyAsset: "invalid")
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken + "_error_bad")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("sell_asset is not a supported asset", message)
            default:
                XCTFail("Expected badRequest error but got: \(error)")
            }
        }
    }

    func testPostQuoteForbidden() async {
        var request = Sep38PostQuoteRequest(context: "sep31",
                                            sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                                            buyAsset: "iso4217:BRL")
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken + "_error_forbidden")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected permission denied error")
        case .failure(let error):
            switch error {
            case .permissionDenied(let message):
                XCTAssertEqual("User not authorized for this operation", message)
            default:
                XCTFail("Expected permissionDenied error but got: \(error)")
            }
        }
    }

    func testPostQuoteServerError() async {
        var request = Sep38PostQuoteRequest(context: "sep31",
                                            sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                                            buyAsset: "iso4217:BRL")
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken + "_error_server")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected server error")
        case .failure(let error):
            switch error {
            case .horizonError(let horizonError):
                switch horizonError {
                case .internalServerError(_, _):
                    break // Expected
                default:
                    XCTFail("Expected internalServerError but got: \(horizonError)")
                }
            default:
                XCTFail("Expected horizonError but got: \(error)")
            }
        }
    }

    func testPostQuoteMalformedResponse() async {
        var request = Sep38PostQuoteRequest(context: "sep31",
                                            sellAsset: "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                                            buyAsset: "iso4217:BRL")
        request.sellAmount = "100"

        let responseEnum = await quoteService.postQuote(request: request, jwt: jwtToken + "_error_malformed")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected parsing error")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(_):
                break // Expected
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }
    }

    // MARK: - GetQuote Endpoint Tests

    func testGetQuote() async {

        let responseEnum = await quoteService.getQuote(id: "de762cda-a193-4961-861e-57b31fed6eb3", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("de762cda-a193-4961-861e-57b31fed6eb3", response.id)
            XCTAssertEqual("5.42", response.totalPrice)
            XCTAssertEqual("5.00", response.price)
            XCTAssertEqual("iso4217:BRL", response.sellAsset)
            XCTAssertEqual("stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN", response.buyAsset)
            XCTAssertEqual("542", response.sellAmount)
            XCTAssertEqual("100", response.buyAmount)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetQuoteNotFound() async {
        let responseEnum = await quoteService.getQuote(id: "notfound", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error")
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("Quote not found", message)
            default:
                XCTFail("Expected notFound error but got: \(error)")
            }
        }
    }

    func testGetQuoteWithoutJwt() async {
        let responseEnum = await quoteService.getQuote(id: "de762cda-a193-4961-861e-57b31fed6eb3", jwt: nil)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("de762cda-a193-4961-861e-57b31fed6eb3", response.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetQuoteBadRequest() async {
        let responseEnum = await quoteService.getQuote(id: "invalid-format", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("Invalid quote ID format", message)
            default:
                XCTFail("Expected badRequest error but got: \(error)")
            }
        }
    }

    func testGetQuoteForbidden() async {
        let responseEnum = await quoteService.getQuote(id: "forbidden-id", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected permission denied error")
        case .failure(let error):
            switch error {
            case .permissionDenied(let message):
                XCTAssertEqual("Not authorized to access this quote", message)
            default:
                XCTFail("Expected permissionDenied error but got: \(error)")
            }
        }
    }

    func testGetQuoteExpired() async {
        let responseEnum = await quoteService.getQuote(id: "expired-id", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("expired-id", response.id)
            // Verify the quote is expired (expiresAt is in the past)
            XCTAssertTrue(response.expiresAt < Date())
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetQuoteNoFeeDetails() async {
        let responseEnum = await quoteService.getQuote(id: "no-fee-details-id", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("no-fee-details-id", response.id)
            XCTAssertEqual("2.00", response.fee.total)
            XCTAssertNil(response.fee.details)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testGetQuoteMalformedResponse() async {
        let responseEnum = await quoteService.getQuote(id: "malformed", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected parsing error")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(_):
                break // Expected
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }
    }

    func testGetQuoteFeeStructure() async {
        let responseEnum = await quoteService.getQuote(id: "de762cda-a193-4961-861e-57b31fed6eb3", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("42.00", response.fee.total)
            XCTAssertEqual("iso4217:BRL", response.fee.asset)
            XCTAssertNotNil(response.fee.details)
            XCTAssertEqual(3, response.fee.details?.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Sep38PostQuoteRequest Tests

    func testSep38PostQuoteRequestToJson() {
        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: "iso4217:BRL", buyAsset: "stellar:USDC:G...")
        request.sellAmount = "100"
        request.expireAfter = Date(timeIntervalSince1970: 1700000000)
        request.sellDeliveryMethod = "PIX"
        request.buyDeliveryMethod = "bank"
        request.countryCode = "BRA"

        let json = request.toJson()

        XCTAssertEqual("sep31", json["context"] as? String)
        XCTAssertEqual("iso4217:BRL", json["sell_asset"] as? String)
        XCTAssertEqual("stellar:USDC:G...", json["buy_asset"] as? String)
        XCTAssertEqual("100", json["sell_amount"] as? String)
        XCTAssertNotNil(json["expire_after"])
        XCTAssertEqual("PIX", json["sell_delivery_method"] as? String)
        XCTAssertEqual("bank", json["buy_delivery_method"] as? String)
        XCTAssertEqual("BRA", json["country_code"] as? String)
    }

    func testSep38PostQuoteRequestToJsonMinimal() {
        let request = Sep38PostQuoteRequest(context: "sep6", sellAsset: "stellar:XLM", buyAsset: "iso4217:USD")

        let json = request.toJson()

        XCTAssertEqual("sep6", json["context"] as? String)
        XCTAssertEqual("stellar:XLM", json["sell_asset"] as? String)
        XCTAssertEqual("iso4217:USD", json["buy_asset"] as? String)
        XCTAssertNil(json["sell_amount"])
        XCTAssertNil(json["buy_amount"])
        XCTAssertNil(json["expire_after"])
        XCTAssertNil(json["sell_delivery_method"])
        XCTAssertNil(json["buy_delivery_method"])
        XCTAssertNil(json["country_code"])
    }

    func testSep38PostQuoteRequestWithBuyAmount() {
        var request = Sep38PostQuoteRequest(context: "sep31", sellAsset: "iso4217:EUR", buyAsset: "stellar:USDC:G...")
        request.buyAmount = "500"

        let json = request.toJson()

        XCTAssertNil(json["sell_amount"])
        XCTAssertEqual("500", json["buy_amount"] as? String)
    }

    // MARK: - Edge Cases and Error Handling Tests

    func testQuoteServiceServiceAddress() {
        let service = QuoteService(serviceAddress: "https://anchor.example.com/sep38")
        XCTAssertEqual("https://anchor.example.com/sep38", service.serviceAddress)
    }

    func testQuoteResponseExpiresAtParsing() async {
        let responseEnum = await quoteService.getQuote(id: "de762cda-a193-4961-861e-57b31fed6eb3", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            // Verify the date is parsed correctly
            XCTAssertNotNil(response.expiresAt)
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: response.expiresAt)
            XCTAssertEqual(2021, components.year)
            XCTAssertEqual(4, components.month)
            XCTAssertEqual(30, components.day)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipleFeeDetailsInResponse() async {
        let responseEnum = await quoteService.getQuote(id: "de762cda-a193-4961-861e-57b31fed6eb3", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            guard let details = response.fee.details else {
                XCTFail("Expected fee details")
                return
            }
            XCTAssertEqual(3, details.count)

            // First detail
            XCTAssertEqual("PIX fee", details[0].name)
            XCTAssertEqual("12.00", details[0].amount)
            XCTAssertEqual("Fee charged in order to process the outgoing PIX transaction.", details[0].description)

            // Second detail
            XCTAssertEqual("Brazilian conciliation fee", details[1].name)
            XCTAssertEqual("15.00", details[1].amount)
            XCTAssertNotNil(details[1].description)

            // Third detail (no description)
            XCTAssertEqual("Service fee", details[2].name)
            XCTAssertEqual("15.00", details[2].amount)
            XCTAssertNil(details[2].description)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
