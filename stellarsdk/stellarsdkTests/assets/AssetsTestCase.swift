//
//  AssetsTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AssetsTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAssetsLoadingSuccessful() {
        let expectation = XCTestExpectation(description: "Get account details response")
        
        sdk.assets.getAssets(order:Order.descending, limit:10) { (response) -> (Void) in
            switch response {
            case .success(let assetsResponse):
                
                for asset in assetsResponse.assets {
                    print("\(asset.assetCode) is the asset code")
                    print("\(asset.assetType) is the asset type")
                    print("\(asset.assetIssuer) is the asset issuer")
                    print("\(asset.pagingToken) is the paging token")
                    print("\(asset.amount) is the amount")
                    print("\(asset.numberOfAccounts) is the number of accounts")
                }
                
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
}
