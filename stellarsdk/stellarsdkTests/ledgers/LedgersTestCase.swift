//
//  LedgersTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

//
//  AssetsTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LedgersTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLedgersLoadingSuccessful() {
        let expectation = XCTestExpectation(description: "Get ledgers response")
        
        sdk.ledgers.getLedgers(order:Order.descending, limit:10) { (response) -> (Void) in
            switch response {
            case .success(let ledgersResponse):
                
                for ledger in ledgersResponse.ledgers {
                    print("\(ledger.id) is the ledger id")
                    print("\(ledger.pagingToken) is the paging token")
                    print("\(ledger.hashXdr) is the ledgers xdr hash")
                    print("\(ledger.previousHashXdr) is the hash of the prev ledger xdr")
                    print("\(ledger.sequenceNumber) is the sequence")
                    print("\(ledger.transactionCount) is the transactions count of the ledger")
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

