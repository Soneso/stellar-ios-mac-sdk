//
//  LedgersRemoteTestCase.swift
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

class LedgersRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetLedgers() {
        let expectation = XCTestExpectation(description: "Get ledgers and parse their details successfully")
        
        sdk.ledgers.getLedgers(order:Order.descending, limit:10) { (response) -> (Void) in
            switch response {
            case .success(let ledgersResponse):
                
                // load next page
                ledgersResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextLedgersResponse):
                        // load previous page, should contain the same effects as the first page
                        nextLedgersResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevLedgersResponse):
                                let ledger1 = ledgersResponse.records.first
                                let ledger2 = prevLedgersResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(ledger1?.id == ledger2?.id)
                                XCTAssertTrue(ledger1?.hashXdr == ledger2?.hashXdr)
                                XCTAssertTrue(ledger1?.previousHashXdr == ledger2?.previousHashXdr)
                                XCTAssertTrue(ledger1?.sequenceNumber == ledger2?.sequenceNumber)
                                XCTAssertTrue(ledger1?.successfulTransactionCount == ledger2?.successfulTransactionCount)
                                XCTAssertTrue(ledger1?.failedTransactionCount == ledger2?.failedTransactionCount)
                                XCTAssertTrue(ledger1?.operationCount == ledger2?.operationCount)
                                XCTAssertTrue(ledger1?.txSetOperationCount == ledger2?.txSetOperationCount)
                                XCTAssertTrue(ledger1?.closedAt == ledger2?.closedAt)
                                XCTAssertTrue(ledger1?.totalCoins == ledger2?.totalCoins)
                                XCTAssertTrue(ledger1?.feePool == ledger2?.feePool)
                                XCTAssertTrue(ledger1?.baseFeeInStroops == ledger2?.baseFeeInStroops)
                                XCTAssertTrue(ledger1?.baseReserveInStroops == ledger2?.baseReserveInStroops)
                                XCTAssertTrue(ledger1?.maxTxSetSize == ledger2?.maxTxSetSize)
                                XCTAssertTrue(ledger1?.protocolVersion == ledger2?.protocolVersion)
                                XCTAssertTrue(ledger1?.headerXdr == ledger2?.headerXdr)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GL Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GL Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GL Test", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
  /*  func testLedgersStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.ledgers.stream(for: .allLedgers(cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    */
}

