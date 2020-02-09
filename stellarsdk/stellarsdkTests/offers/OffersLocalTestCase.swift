//
//  OffersLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/22/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OffersLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var offersResponsesMock: OffersResponsesMock? = nil
    var mockRegistered = false
    let limit = 4
    let accountId = "GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4"
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        offersResponsesMock = OffersResponsesMock()
        
        let firstResponse = successResponse(limit:limit)
        offersResponsesMock?.addOffersResponse(accountId: accountId, limit: String(limit), response: firstResponse)
    }
    
    override func tearDown() {
        offersResponsesMock = nil
        super.tearDown()
    }
    
    func testGetOffersForAccount() {
        let expectation = XCTestExpectation(description: "Get offers for account and parse their details successfully")
        
        sdk.offers.getOffers(forAccount: accountId, limit: limit) { response in
            switch response {
            case .success(let offersResponse):
                checkResult(offersResponse: offersResponse)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFA Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        func checkResult(offersResponse:PageResponse<OfferResponse>) {
            
            XCTAssertNotNil(offersResponse.links)
            XCTAssertNotNil(offersResponse.links.selflink)
            XCTAssertEqual(offersResponse.links.selflink.href, "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4/offers?order=asc&limit=10&cursor=")
            XCTAssertNil(offersResponse.links.selflink.templated)
            
            XCTAssertNotNil(offersResponse.links.next)
            XCTAssertEqual(offersResponse.links.next?.href, "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4/offers?order=asc&limit=10&cursor=122")
            XCTAssertNil(offersResponse.links.next?.templated)
            
            XCTAssertNotNil(offersResponse.links.prev)
            XCTAssertEqual(offersResponse.links.prev?.href, "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4/offers?order=desc&limit=10&cursor=121")
            XCTAssertNil(offersResponse.links.prev?.templated)
            
            XCTAssertEqual(offersResponse.records.count, limit)
            
            for offer in offersResponse.records {
                XCTAssertNotNil(offer)
                XCTAssertNotNil(offer.links)
                XCTAssertNotNil(offer.links.selflink)
                XCTAssertEqual(offer.links.selflink.href, "https://horizon-testnet.stellar.org/offers/121")
                
                XCTAssertNotNil(offer.links.seller)
                XCTAssertEqual(offer.links.seller.href, "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4")
                XCTAssertNil(offer.links.seller.templated)
                
                XCTAssertEqual(offer.id, "121")
                XCTAssertEqual(offer.pagingToken, "121")
                XCTAssertEqual(offer.seller, "GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4")
                XCTAssertEqual(offer.selling.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
                XCTAssertEqual(offer.selling.assetCode, "BAR")
                XCTAssertEqual(offer.selling.assetIssuer, "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG")
                XCTAssertEqual(offer.buying.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
                XCTAssertEqual(offer.buying.assetCode, "FOO")
                XCTAssertEqual(offer.buying.assetIssuer, "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG")
                XCTAssertEqual(offer.priceR.numerator, 387)
                XCTAssertEqual(offer.priceR.denominator, 50)
                XCTAssertEqual(offer.amount, "23.6692509")
                XCTAssertEqual(offer.price, "7.7400000")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    public func successResponse(limit:Int) -> String {
        var responseString = """
        {
            "_links": {
                "self": {
                  "href": "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4/offers?order=asc&limit=10&cursor="
                },
                "next": {
                  "href": "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4/offers?order=asc&limit=10&cursor=122"
                },
                "prev": {
                  "href": "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4/offers?order=desc&limit=10&cursor=121"
                }
            },
            "_embedded": {
                "records": [
        """
        
        let record = """
            {
                "_links": {
                    "self": {
                        "href": "https://horizon-testnet.stellar.org/offers/121"
                    },
                    "offer_maker": {
                        "href": "https://horizon-testnet.stellar.org/accounts/GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4"
                    }
                },
                "id": 121,
                "paging_token": "121",
                "seller": "GCJ34JYMXNI7N55YREWAACMMZECOMTPIYDTFCQBWPUP7BLJQDDTVGUW4",
                "selling": {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "BAR",
                    "asset_issuer": "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG"
                },
                "buying": {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "FOO",
                    "asset_issuer": "GBAUUA74H4XOQYRSOW2RZUA4QL5PB37U3JS5NE3RTB2ELJVMIF5RLMAG"
                },
                "amount": "23.6692509",
                "price_r": {
                    "n": 387,
                    "d": 50
                },
                "price": "7.7400000"
            }
            """
        
        responseString.append(record)
        for _ in 1...limit-1 {
            responseString.append(", " + record)
        }
        let end = """
                    ]
                }
            }
            """
        responseString.append(end)
        
        return responseString
    }
}
