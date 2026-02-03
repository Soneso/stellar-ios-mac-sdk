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
        quoteService = QuoteService(serviceAddress: "http://\(quoteServer)")

    }
    
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
}
