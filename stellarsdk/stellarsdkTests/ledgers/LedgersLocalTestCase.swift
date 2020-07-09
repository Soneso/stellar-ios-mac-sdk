//
//  LedgersLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 20.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LedgersLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var ledgersResponsesMock: LedgersResponsesMock? = nil
    var mockRegistered = false
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        ledgersResponsesMock = LedgersResponsesMock()
        let oneLedgerResponse = successResponse(limit: 1)
        let twoLedgersResponse = successResponse(limit: 2)
        
        ledgersResponsesMock?.addLedgersResponse(key: "1", response: oneLedgerResponse)
        ledgersResponsesMock?.addLedgersResponse(key: "2", response: twoLedgersResponse)
        
    }
    
    override func tearDown() {
        ledgersResponsesMock = nil
        super.tearDown()
    }
    
    func testGetLedgers() {
        let expectation = XCTestExpectation(description: "Get ledgers and parse their details successfully")
        
        sdk.ledgers.getLedgers(limit: 1) { (response) -> (Void) in
            switch response {
            case .success(let ledgersResponse):
                checkResult(ledgersResponse:ledgersResponse, limit:1)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GL Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        
        func checkResult(ledgersResponse:PageResponse<LedgerResponse>, limit:Int) {
            
            XCTAssertNotNil(ledgersResponse.links)
            XCTAssertNotNil(ledgersResponse.links.selflink)
            XCTAssertEqual(ledgersResponse.links.selflink.href, "https://horizon-testnet.stellar.org/ledgers?order=asc&limit=2&cursor=")
            XCTAssertNil(ledgersResponse.links.selflink.templated)
            
            XCTAssertNotNil(ledgersResponse.links.next)
            XCTAssertEqual(ledgersResponse.links.next?.href, "https://horizon-testnet.stellar.org/ledgers?order=asc&limit=2&cursor=8589934592")
            XCTAssertNil(ledgersResponse.links.next?.templated)
            
            XCTAssertNotNil(ledgersResponse.links.prev)
            XCTAssertEqual(ledgersResponse.links.prev?.href, "https://horizon-testnet.stellar.org/ledgers?order=desc&limit=2&cursor=4294967296")
            XCTAssertNil(ledgersResponse.links.prev?.templated)
            

            if limit == 1 {
                XCTAssertEqual(ledgersResponse.records.count, 1)
            } else if limit == 2 {
                XCTAssertEqual(ledgersResponse.records.count, 2)
            }
            
            let firstLedger = ledgersResponse.records.first
            XCTAssertNotNil(firstLedger)
            XCTAssertNotNil(firstLedger?.links)
            XCTAssertNotNil(firstLedger?.links.selflink)
            XCTAssertEqual(firstLedger?.links.selflink.href, "https://horizon-testnet.stellar.org/ledgers/1")

            XCTAssertNotNil(firstLedger?.links.transactions)
            XCTAssertEqual(firstLedger?.links.transactions.href, "https://horizon-testnet.stellar.org/ledgers/1/transactions{?cursor,limit,order}")
            XCTAssertNotNil(firstLedger?.links.transactions.templated)
            XCTAssertTrue((firstLedger?.links.transactions.templated)!)
            
            XCTAssertNotNil(firstLedger?.links.operations)
            XCTAssertEqual(firstLedger?.links.operations.href, "https://horizon-testnet.stellar.org/ledgers/1/operations{?cursor,limit,order}")
            XCTAssertNotNil(firstLedger?.links.operations.templated)
            XCTAssertTrue((firstLedger?.links.operations.templated)!)
            
            XCTAssertNotNil(firstLedger?.links.payments)
            XCTAssertEqual(firstLedger?.links.payments.href, "https://horizon-testnet.stellar.org/ledgers/1/payments{?cursor,limit,order}")
            XCTAssertNotNil(firstLedger?.links.payments.templated)
            XCTAssertTrue((firstLedger?.links.payments.templated)!)
            
            XCTAssertNotNil(firstLedger?.links.effects)
            XCTAssertEqual(firstLedger?.links.effects.href, "https://horizon-testnet.stellar.org/ledgers/1/effects{?cursor,limit,order}")
            XCTAssertNotNil(firstLedger?.links.effects.templated)
            XCTAssertTrue((firstLedger?.links.effects.templated)!)
            
            XCTAssertEqual(firstLedger?.id, "63d98f536ee68d1b27b5b89f23af5311b7569a24faf1403ad0b52b633b07be99")
            XCTAssertEqual(firstLedger?.pagingToken, "4294967296")
            XCTAssertEqual(firstLedger?.hashXdr, "63d98f536ee68d1b27b5b89f23af5311b7569a24faf1403ad0b52b633b07be99")
            XCTAssertNil(firstLedger?.previousHashXdr)
            XCTAssertEqual(firstLedger?.sequenceNumber, 1)
            XCTAssertNil(firstLedger?.successfulTransactionCount)
            XCTAssertNil(firstLedger?.failedTransactionCount)
            XCTAssertEqual(firstLedger?.operationCount, 0)
            let closedAt = DateFormatter.iso8601.date(from:"1970-01-01T00:00:00Z")
            XCTAssertEqual(firstLedger?.closedAt, closedAt)
            XCTAssertEqual(firstLedger?.feePool, "0.0000000")
            XCTAssertEqual(firstLedger?.baseFeeInStroops, 100)
            XCTAssertEqual(firstLedger?.baseReserveInStroops, 100000000)
            XCTAssertEqual(firstLedger?.maxTxSetSize, 100)
            XCTAssertEqual(firstLedger?.protocolVersion, 0)
            XCTAssertNil(firstLedger?.txSetOperationCount)
            XCTAssertEqual(firstLedger?.headerXdr, "AAAAAdy3Lr5Tev4ZYxKMei6LWkNgcQaWhEQWlPvuxqAYEUSST/2WLmbNl35twoFs78799llnNyPHs8u5xPtPvzoq9KEAAAAAVg4WeQAAAAAAAAAA3z9hmASpL9tAVxktxD3XSOp3itxSvEmM6AUkwBS4ERkHVi1wPY+0ie6g6YCletq0h1OSHiaWAqDQKJxtKEtlSAAAWsAN4r8dMwM+/wAAABDxA9f6AAAAAwAAAAAAAAAAAAAAZAX14QAAAAH0B1YtcD2PtInuoOmApXratIdTkh4mlgKg0CicbShLZUibK4xTjWYpfADpjyadb48ZEs52+TAOiCYDUIxrs+NjEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
            if (limit == 2) {
                let secondLedger = ledgersResponse.records.last
                XCTAssertNotNil(secondLedger)
                XCTAssertNotNil(secondLedger)
                XCTAssertNotNil(secondLedger?.links)
                XCTAssertNotNil(secondLedger?.links.selflink)
                XCTAssertEqual(secondLedger?.links.selflink.href, "https://horizon-testnet.stellar.org/ledgers/2")
                
                XCTAssertNotNil(secondLedger?.links.transactions)
                XCTAssertEqual(secondLedger?.links.transactions.href, "https://horizon-testnet.stellar.org/ledgers/2/transactions{?cursor,limit,order}")
                XCTAssertNotNil(secondLedger?.links.transactions.templated)
                XCTAssertTrue((secondLedger?.links.transactions.templated)!)
                
                XCTAssertNotNil(secondLedger?.links.operations)
                XCTAssertEqual(secondLedger?.links.operations.href, "https://horizon-testnet.stellar.org/ledgers/2/operations{?cursor,limit,order}")
                XCTAssertNotNil(secondLedger?.links.operations.templated)
                XCTAssertTrue((secondLedger?.links.operations.templated)!)
                
                XCTAssertNotNil(secondLedger?.links.payments)
                XCTAssertEqual(secondLedger?.links.payments.href, "https://horizon-testnet.stellar.org/ledgers/2/payments{?cursor,limit,order}")
                XCTAssertNotNil(secondLedger?.links.payments.templated)
                XCTAssertTrue((secondLedger?.links.payments.templated)!)
                
                XCTAssertNotNil(secondLedger?.links.effects)
                XCTAssertEqual(secondLedger?.links.effects.href, "https://horizon-testnet.stellar.org/ledgers/2/effects{?cursor,limit,order}")
                XCTAssertNotNil(secondLedger?.links.effects.templated)
                XCTAssertTrue((secondLedger?.links.effects.templated)!)
                
                XCTAssertEqual(secondLedger?.id, "6827e2e9d0e276395b7e54b3f8377de0b4e65fab914efbd0b520e8e1044de738")
                XCTAssertEqual(secondLedger?.pagingToken, "8589934592")
                XCTAssertEqual(secondLedger?.hashXdr, "6827e2e9d0e276395b7e54b3f8377de0b4e65fab914efbd0b520e8e1044de738")
                XCTAssertNotNil(secondLedger?.previousHashXdr)
                XCTAssertEqual(secondLedger?.previousHashXdr, "63d98f536ee68d1b27b5b89f23af5311b7569a24faf1403ad0b52b633b07be99")
                XCTAssertEqual(secondLedger?.sequenceNumber, 2)
                XCTAssertNil(secondLedger?.successfulTransactionCount)
                XCTAssertNil(secondLedger?.failedTransactionCount)
                XCTAssertEqual(secondLedger?.operationCount, 30)
                let closedAt = DateFormatter.iso8601.date(from:"2017-03-20T17:09:53Z")
                XCTAssertEqual(secondLedger?.closedAt, closedAt)
                XCTAssertEqual(secondLedger?.feePool, "23.0000000")
                XCTAssertEqual(secondLedger?.baseFeeInStroops, 200)
                XCTAssertEqual(secondLedger?.baseReserveInStroops, 130000000)
                XCTAssertEqual(secondLedger?.maxTxSetSize, 50)
                XCTAssertEqual(secondLedger?.protocolVersion, 4)
                XCTAssertEqual(secondLedger?.txSetOperationCount, 22)
                XCTAssertEqual(firstLedger?.headerXdr, "AAAAAdy3Lr5Tev4ZYxKMei6LWkNgcQaWhEQWlPvuxqAYEUSST/2WLmbNl35twoFs78799llnNyPHs8u5xPtPvzoq9KEAAAAAVg4WeQAAAAAAAAAA3z9hmASpL9tAVxktxD3XSOp3itxSvEmM6AUkwBS4ERkHVi1wPY+0ie6g6YCletq0h1OSHiaWAqDQKJxtKEtlSAAAWsAN4r8dMwM+/wAAABDxA9f6AAAAAwAAAAAAAAAAAAAAZAX14QAAAAH0B1YtcD2PtInuoOmApXratIdTkh4mlgKg0CicbShLZUibK4xTjWYpfADpjyadb48ZEs52+TAOiCYDUIxrs+NjEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
                expectation.fulfill()
                
            } else {
                sdk.ledgers.getLedgers(limit: 2) { (response) -> (Void) in
                    switch response {
                    case .success(let ledgersResponse):
                        checkResult(ledgersResponse:ledgersResponse, limit:2)
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load ledgers testcase", horizonRequestError: error)
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    public func successResponse(limit:Int) -> String {
        
        var ledgersResponseString = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/ledgers?order=asc&limit=2&cursor="
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/ledgers?order=asc&limit=2&cursor=8589934592"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/ledgers?order=desc&limit=2&cursor=4294967296"
                }
            },
            "_embedded": {
                "records": [
                {
                   "_links": {
                        "self": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/1"
                        },
                        "transactions": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/1/transactions{?cursor,limit,order}",
                            "templated": true
                        },
                        "operations": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/1/operations{?cursor,limit,order}",
                            "templated": true
                        },
                        "payments": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/1/payments{?cursor,limit,order}",
                            "templated": true
                        },
                        "effects": {
                            "href": "https://horizon-testnet.stellar.org/ledgers/1/effects{?cursor,limit,order}",
                            "templated": true
                        }
                    },
                    "id": "63d98f536ee68d1b27b5b89f23af5311b7569a24faf1403ad0b52b633b07be99",
                    "paging_token": "4294967296",
                    "hash": "63d98f536ee68d1b27b5b89f23af5311b7569a24faf1403ad0b52b633b07be99",
                    "sequence": 1,
                    "operation_count": 0,
                    "tx_set_operation_count": null,
                    "closed_at": "1970-01-01T00:00:00Z",
                    "total_coins": "100000000000.0000000",
                    "fee_pool": "0.0000000",
                    "base_fee_in_stroops": 100,
                    "base_reserve_in_stroops": 100000000,
                    "max_tx_set_size": 100,
                    "protocol_version": 0,
                    "header_xdr": "AAAAAdy3Lr5Tev4ZYxKMei6LWkNgcQaWhEQWlPvuxqAYEUSST/2WLmbNl35twoFs78799llnNyPHs8u5xPtPvzoq9KEAAAAAVg4WeQAAAAAAAAAA3z9hmASpL9tAVxktxD3XSOp3itxSvEmM6AUkwBS4ERkHVi1wPY+0ie6g6YCletq0h1OSHiaWAqDQKJxtKEtlSAAAWsAN4r8dMwM+/wAAABDxA9f6AAAAAwAAAAAAAAAAAAAAZAX14QAAAAH0B1YtcD2PtInuoOmApXratIdTkh4mlgKg0CicbShLZUibK4xTjWYpfADpjyadb48ZEs52+TAOiCYDUIxrs+NjEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                }
        """
        if limit > 1 {
            let record = """
                        ,
                        {
                            "_links": {
                                "self": {
                                    "href": "https://horizon-testnet.stellar.org/ledgers/2"
                                },
                                "transactions": {
                                    "href": "https://horizon-testnet.stellar.org/ledgers/2/transactions{?cursor,limit,order}",
                                    "templated": true
                                },
                                "operations": {
                                    "href": "https://horizon-testnet.stellar.org/ledgers/2/operations{?cursor,limit,order}",
                                    "templated": true
                                },
                                "payments": {
                                    "href": "https://horizon-testnet.stellar.org/ledgers/2/payments{?cursor,limit,order}",
                                    "templated": true
                                },
                                "effects": {
                                    "href": "https://horizon-testnet.stellar.org/ledgers/2/effects{?cursor,limit,order}",
                                    "templated": true
                                }
                            },
                            "id": "6827e2e9d0e276395b7e54b3f8377de0b4e65fab914efbd0b520e8e1044de738",
                            "paging_token": "8589934592",
                            "hash": "6827e2e9d0e276395b7e54b3f8377de0b4e65fab914efbd0b520e8e1044de738",
                            "prev_hash": "63d98f536ee68d1b27b5b89f23af5311b7569a24faf1403ad0b52b633b07be99",
                            "sequence": 2,
                            "successful_transaction_count": null,
                            "failed_transaction_count": null,
                            "operation_count": 30,
                            "tx_set_operation_count": 22,
                            "closed_at": "2017-03-20T17:09:53Z",
                            "total_coins": "100000000000.0000000",
                            "fee_pool": "23.0000000",
                            "base_fee_in_stroops": 200,
                            "base_reserve_in_stroops": 130000000,
                            "max_tx_set_size": 50,
                            "protocol_version": 4,
                            "header_xdr": "AAAAAdy3Lr5Tev4ZYxKMei6LWkNgcQaWhEQWlPvuxqAYEUSST/2WLmbNl35twoFs78799llnNyPHs8u5xPtPvzoq9KEAAAAAVg4WeQAAAAAAAAAA3z9hmASpL9tAVxktxD3XSOp3itxSvEmM6AUkwBS4ERkHVi1wPY+0ie6g6YCletq0h1OSHiaWAqDQKJxtKEtlSAAAWsAN4r8dMwM+/wAAABDxA9f6AAAAAwAAAAAAAAAAAAAAZAX14QAAAAH0B1YtcD2PtInuoOmApXratIdTkh4mlgKg0CicbShLZUibK4xTjWYpfADpjyadb48ZEs52+TAOiCYDUIxrs+NjEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                        }
            """
            ledgersResponseString.append(record)
        }
        let end = """
                    ]
                }
            }
            """
        ledgersResponseString.append(end)
        
        return ledgersResponseString
    }
}
