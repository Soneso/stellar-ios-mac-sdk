//
//  TradesTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TradesTestCase: XCTestCase {
    let sdk = StellarSDK()
    let testSuccessAccountId = "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetTrades() {
        let expectation = XCTestExpectation(description: "Get trades response")
        
        sdk.trades.getTrades(limit: 10) { (response) -> (Void) in
            switch response {
            case .success(let tradesResponse):
                
                for trade in tradesResponse.records {
                    print("\(trade.baseAccount) is the base account")
                    print("\(trade.baseAmount) is the base amount code")
                    print("\(trade.baseAssetType) is the base asset type")
                    print("\(trade.counterAccount) is the counter account")
                    print("\(trade.counterAmount) is the counter amount")
                    print("\(trade.counterAssetType) is the counter asset type")
                    print("\(trade.pagingToken) is the paging token")
                    print("\(trade.baseIsSeller) the base is seller")
                    print("\(trade.ledgerCloseTime) is the ledger close time")
                }
                
                // load next page
                tradesResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextTradesResponse):
                        // load previous page, should contain the same trades as the first page
                        nextTradesResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevTradesResponse):
                                let trade1 = tradesResponse.records.first
                                let trade2 = prevTradesResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(trade1?.baseAccount == trade2?.baseAccount)
                                XCTAssertTrue(trade1?.baseAmount == trade2?.baseAmount)
                                XCTAssertTrue(trade1?.baseAssetType == trade2?.baseAssetType)
                                if (trade1?.baseAssetType != AssetTypeAsString.NATIVE) {
                                    XCTAssertTrue(trade1?.baseAssetCode == trade2?.baseAssetCode)
                                    XCTAssertTrue(trade1?.baseAssetIssuer == trade2?.baseAssetIssuer)
                                }
                                XCTAssertTrue(trade1?.counterAccount == trade2?.counterAccount)
                                XCTAssertTrue(trade1?.counterAmount == trade2?.counterAmount)
                                XCTAssertTrue(trade1?.counterAssetType == trade2?.counterAssetType)
                                if (trade1?.counterAssetType != AssetTypeAsString.NATIVE) {
                                    XCTAssertTrue(trade1?.counterAssetCode == trade2?.counterAssetCode)
                                    XCTAssertTrue(trade1?.counterAssetIssuer == trade2?.counterAssetIssuer)
                                }
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetTradesForAccount() {
        let expectation = XCTestExpectation(description: "Get trades response for account")
        sdk.trades.getTrades(forAccount: testSuccessAccountId, from: nil, order: nil, limit: nil) { (response) -> (Void) in
            switch response {
            case .success(let tradesResponse):
                XCTAssertTrue(tradesResponse.records.count == 0)
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
