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

    
    func testGetLedgers() async {
        let ledgersResponseEnum = await sdk.ledgers.getLedgers(order:Order.descending, limit:10)
        switch ledgersResponseEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    XCTAssertTrue(page.records.count > 0)
                    XCTAssertTrue(firstPage.records.count > 0)
                    let ledger1 = firstPage.records.first!
                    let ledger2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(ledger1.id == ledger2.id)
                    XCTAssertTrue(ledger1.hashXdr == ledger2.hashXdr)
                    XCTAssertTrue(ledger1.previousHashXdr == ledger2.previousHashXdr)
                    XCTAssertTrue(ledger1.sequenceNumber == ledger2.sequenceNumber)
                    XCTAssertTrue(ledger1.successfulTransactionCount == ledger2.successfulTransactionCount)
                    XCTAssertTrue(ledger1.failedTransactionCount == ledger2.failedTransactionCount)
                    XCTAssertTrue(ledger1.operationCount == ledger2.operationCount)
                    XCTAssertTrue(ledger1.txSetOperationCount == ledger2.txSetOperationCount)
                    XCTAssertTrue(ledger1.closedAt == ledger2.closedAt)
                    XCTAssertTrue(ledger1.totalCoins == ledger2.totalCoins)
                    XCTAssertTrue(ledger1.feePool == ledger2.feePool)
                    XCTAssertTrue(ledger1.baseFeeInStroops == ledger2.baseFeeInStroops)
                    XCTAssertTrue(ledger1.baseReserveInStroops == ledger2.baseReserveInStroops)
                    XCTAssertTrue(ledger1.maxTxSetSize == ledger2.maxTxSetSize)
                    XCTAssertTrue(ledger1.protocolVersion == ledger2.protocolVersion)
                    XCTAssertTrue(ledger1.headerXdr == ledger2.headerXdr)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLedgers()", horizonRequestError: error)
                    XCTFail("failed to load prev page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLedgers()", horizonRequestError: error)
                XCTFail("failed to load next page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLedgers()", horizonRequestError: error)
            XCTFail("failed to load ledgers")
        }
    }
}

