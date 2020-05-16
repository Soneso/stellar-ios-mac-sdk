//
//  OffersRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Istvan Elekes on 2/13/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OffersRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoadOffersForAccount() {
        let expectation = XCTestExpectation(description: "Get offers")
        
        sdk.offers.getOffers(forAccount: "GCGBBRSKBPIQHGOPA5T637SQYHVGTKTIF6DUYZS34NLOUZNHI7JYBUNA") { (response) -> (Void) in
            switch response {
            case .success(let offersResponse):
                // load next page
                offersResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextOffersResponse):
                        // load previous page, should contain the same transactions as the first page
                        nextOffersResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevOffersResponse):
                                let offer1 = offersResponse.records.first
                                let offer2 = prevOffersResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(offer1?.id == offer2?.id)
                                XCTAssertTrue(offer1?.pagingToken == offer2?.pagingToken)
                                XCTAssertTrue(offer1?.seller == offer2?.seller)
                                XCTAssertTrue(offer1?.buying == offer2?.buying)
                                XCTAssertTrue(offer1?.selling == offer2?.selling)
                                XCTAssertTrue(offer1?.amount == offer2?.amount)
                                XCTAssertTrue(offer1?.price == offer2?.price)
                                XCTAssertTrue(offer1?.priceR == offer2?.priceR)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testLoadOffersForSeller() {
        let expectation = XCTestExpectation(description: "Get offers")
        
        sdk.offers.getOffers(seller: "GDGNF4FLAPCTN2WQ4SM7RPB42QIEPM3FK5M4FAVREOBUALT7I6DVNHCX", sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII", buyingAssetType: "native") { (response) -> (Void) in
            switch response {
            case .success(let offersResponse):
                let offer = offersResponse.records.first
                XCTAssertNotNil(offer)
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testLoadOffersForSellingAsset() {
        let expectation = XCTestExpectation(description: "Get offers")
        
        sdk.offers.getOffers(seller:nil, sellingAssetType: "credit_alphanum4", sellingAssetCode: "IOM", sellingAssetIssuer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII", buyingAssetType: "native") { (response) -> (Void) in
            switch response {
            case .success(let offersResponse):
                let offer = offersResponse.records.first
                XCTAssertNotNil(offer)
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testLoadOffersForBuyingAsset() {
        let expectation = XCTestExpectation(description: "Get offers")
        
        sdk.offers.getOffers(seller:nil, sellingAssetType: "native", buyingAssetType:"credit_alphanum4", buyingAssetCode: "IOM", buyingAssetIssuer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII") { (response) -> (Void) in
            switch response {
            case .success(let offersResponse):
                let offer = offersResponse.records.first
                XCTAssertNotNil(offer)
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testLoadOffersForBuyer() {
        let expectation = XCTestExpectation(description: "Get offers")
        
        sdk.offers.getOffers(seller:"GAAH55HXH2YQRBGYWS52FBNUZUCCKDOOYYKCU7QYZMFW2474V6MNHJ7D", sellingAssetType: "native", buyingAssetType:"credit_alphanum4", buyingAssetCode: "IOM", buyingAssetIssuer: "GDLDBAEQ2HNCIGYUSOZGWOLVUFF6HCVPEAEN3NH54GD37LFJXGWBRPII") { (response) -> (Void) in
            switch response {
            case .success(let offersResponse):
                let offer = offersResponse.records.first
                XCTAssertNotNil(offer)
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load offers testcase", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
