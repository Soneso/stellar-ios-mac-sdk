//
//  TradesLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/22/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TradesLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var tradesResponsesMock: TradesResponsesMock? = nil
    var mockRegistered = false
    let limit = 2
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        tradesResponsesMock = TradesResponsesMock()
        
        let firstResponse = successResponse(limit:limit)
        tradesResponsesMock?.addTradesResponse(key: String(limit), response: firstResponse)
    }
    
    override func tearDown() {
        tradesResponsesMock = nil
        super.tearDown()
    }
    
    func testGetTrades() {
        let expectation = XCTestExpectation(description: "Get trades and parse their details successfully")
        
        sdk.trades.getTrades(limit: limit) { response in
            switch response {
            case .success(let tradesResponse):
                checkResult(response: tradesResponse)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        func checkResult(response:PageResponse<TradeResponse>) {
            
            XCTAssertNotNil(response.links)
            XCTAssertNotNil(response.links.selflink)
            XCTAssertEqual(response.links.selflink.href, "https://horizon.stellar.org/trades?order=desc&limit=2&cursor=")
            XCTAssertNil(response.links.selflink.templated)
            
            XCTAssertNotNil(response.links.next)
            XCTAssertEqual(response.links.next?.href, "https://horizon.stellar.org/trades?order=desc&limit=2&cursor=64255919088738305-0")
            XCTAssertNil(response.links.next?.templated)
            
            XCTAssertNotNil(response.links.prev)
            XCTAssertEqual(response.links.prev?.href, "https://horizon.stellar.org/trades?order=asc&limit=2&cursor=64283226490810369-0")
            XCTAssertNil(response.links.prev?.templated)
            
            XCTAssertEqual(response.records.count, limit)
            
            for trade in response.records {
                XCTAssertNotNil(trade)
                XCTAssertNotNil(trade.links)
                
                XCTAssertNotNil(trade.links.base)
                XCTAssertEqual(trade.links.base.href, "https://horizon.stellar.org/accounts/GDZYXBXG4PIQYLHY7BXDMMP3CM3QP2MC65W44M2TP2OLIR6XHGHG3OHG")
                
                XCTAssertNotNil(trade.links.counter)
                XCTAssertEqual(trade.links.counter.href, "https://horizon.stellar.org/accounts/GDAGT3NCVD4VCLN4TBRPHPJURX2KKCCZPA3WCROTJDUQI73XXJ4LCIMF")
                
                XCTAssertNotNil(trade.links.operation)
                XCTAssertEqual(trade.links.operation.href, "https://horizon.stellar.org/operations/64283226490810369")
                
                XCTAssertEqual(trade.id, "64283226490810369-0")
                XCTAssertEqual(trade.pagingToken, "64283226490810369-0")
                let closeTime = DateFormatter.iso8601.date(from:"2017-12-08T20:27:12Z")
                XCTAssertEqual(trade.ledgerCloseTime, closeTime)
                XCTAssertEqual(trade.baseAccount, "GDZYXBXG4PIQYLHY7BXDMMP3CM3QP2MC65W44M2TP2OLIR6XHGHG3OHG")
                XCTAssertEqual(trade.baseAmount, "451.0000000")
                XCTAssertEqual(trade.baseAssetType, AssetTypeAsString.NATIVE)
                XCTAssertEqual(trade.counterAccount, "GDAGT3NCVD4VCLN4TBRPHPJURX2KKCCZPA3WCROTJDUQI73XXJ4LCIMF")
                XCTAssertEqual(trade.counterAmount, "0.0027962")
                XCTAssertEqual(trade.counterAssetType, AssetTypeAsString.CREDIT_ALPHANUM4)
                XCTAssertEqual(trade.counterAssetCode, "BTC")
                XCTAssertEqual(trade.counterAssetIssuer, "GATEMHCCKCY67ZUCKTROYN24ZYT5GK4EQZ65JJLDHKHRUZI3EUEKMTCH")
                XCTAssertEqual(trade.baseIsSeller, false)
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
                    "href": "https://horizon.stellar.org/trades?order=desc&limit=2&cursor="
                },
                "next": {
                    "href": "https://horizon.stellar.org/trades?order=desc&limit=2&cursor=64255919088738305-0"
                },
                "prev": {
                    "href": "https://horizon.stellar.org/trades?order=asc&limit=2&cursor=64283226490810369-0"
                }
            },
            "_embedded": {
                "records": [
        """
        
        let record = """
            {
            "_links": {
                "base": {
                    "href": "https://horizon.stellar.org/accounts/GDZYXBXG4PIQYLHY7BXDMMP3CM3QP2MC65W44M2TP2OLIR6XHGHG3OHG"
                },
                "counter": {
                    "href": "https://horizon.stellar.org/accounts/GDAGT3NCVD4VCLN4TBRPHPJURX2KKCCZPA3WCROTJDUQI73XXJ4LCIMF"
                },
                "operation": {
                    "href": "https://horizon.stellar.org/operations/64283226490810369"
                }
            },
            "id": "64283226490810369-0",
            "paging_token": "64283226490810369-0",
            "ledger_close_time": "2017-12-08T20:27:12Z",
            "offer_id": "286304",
            "base_account": "GDZYXBXG4PIQYLHY7BXDMMP3CM3QP2MC65W44M2TP2OLIR6XHGHG3OHG",
            "base_amount": "451.0000000",
            "base_asset_type": "native",
            "counter_account": "GDAGT3NCVD4VCLN4TBRPHPJURX2KKCCZPA3WCROTJDUQI73XXJ4LCIMF",
            "counter_amount": "0.0027962",
            "counter_asset_type": "credit_alphanum4",
            "counter_asset_code": "BTC",
            "counter_asset_issuer": "GATEMHCCKCY67ZUCKTROYN24ZYT5GK4EQZ65JJLDHKHRUZI3EUEKMTCH",
            "base_is_seller": false
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
