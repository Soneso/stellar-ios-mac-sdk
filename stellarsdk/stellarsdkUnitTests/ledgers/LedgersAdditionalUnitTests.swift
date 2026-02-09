//
//  LedgersAdditionalUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LedgersAdditionalUnitTests: XCTestCase {

    let sdk = StellarSDK()
    var mockRegistered = false

    override func setUp() {
        super.setUp()

        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - getLedgersFromUrl() Tests

    func testGetLedgersFromUrlWithValidUrl() async {
        _ = LedgersUrlTestMock()

        // Test that getLedgersFromUrl works with a proper ledger URL
        let url = "https://horizon-testnet.stellar.org/ledgers?limit=1"
        let responseEnum = await sdk.ledgers.getLedgersFromUrl(url: url)

        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertGreaterThan(page.records.count, 0)
            XCTAssertNotNil(page.links)

        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetLedgersFromUrlWithValidUrl()", horizonRequestError: error)
            XCTFail("getLedgersFromUrl should succeed with valid URL")
        }
    }

    func testGetLedgersFromUrlNotFound() async {
        _ = LedgerNotFoundMock()

        // Test that getLedgersFromUrl properly handles 404 errors
        let url = "https://horizon-testnet.stellar.org/ledgers/999999999"
        let responseEnum = await sdk.ledgers.getLedgersFromUrl(url: url)

        switch responseEnum {
        case .success:
            XCTFail("should have failed with not found error")
        case .failure(let error):
            if case .notFound(_, _) = error {
                // Expected error type
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - Edge Cases and Boundary Tests

    func testGetLedgerWithZeroSequence() async {
        _ = LedgerErrorMock()

        // Ledger sequence 0 doesn't exist - should return error
        let responseEnum = await sdk.ledgers.getLedger(sequenceNumber: "0")

        switch responseEnum {
        case .success:
            XCTFail("Ledger 0 should not exist")
        case .failure(let error):
            // Should fail with bad request or not found
            switch error {
            case .badRequest(_, _), .notFound(_, _):
                // Expected error types for invalid ledger sequence
                break
            default:
                XCTFail("Expected badRequest or notFound error, got: \(error)")
            }
        }
    }

    func testGetLedgerWithNegativeSequence() async {
        _ = LedgerErrorMock()

        // Negative sequence should fail
        let responseEnum = await sdk.ledgers.getLedger(sequenceNumber: "-1")

        switch responseEnum {
        case .success:
            XCTFail("Negative ledger sequence should not be valid")
        case .failure(let error):
            // Should fail with bad request
            switch error {
            case .badRequest(_, _), .notFound(_, _):
                // Expected error types for invalid ledger sequence
                break
            default:
                XCTFail("Expected badRequest or notFound error, got: \(error)")
            }
        }
    }

    func testGetLedgerWithInvalidSequence() async {
        _ = LedgerErrorMock()

        // Non-numeric sequence should fail
        let responseEnum = await sdk.ledgers.getLedger(sequenceNumber: "invalid")

        switch responseEnum {
        case .success:
            XCTFail("Invalid ledger sequence should not be accepted")
        case .failure(let error):
            // Should fail with bad request for invalid input
            switch error {
            case .badRequest(let message, _):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            case .notFound(_, _):
                // Not found is also acceptable for invalid sequence
                break
            default:
                XCTFail("Expected badRequest or notFound error, got: \(error)")
            }
        }
    }

    // MARK: - LedgerResponse Field Tests

    func testLedgerResponseAllFieldsPresent() async {
        _ = LedgerFullFieldsMock()

        let responseEnum = await sdk.ledgers.getLedger(sequenceNumber: "777777")

        switch responseEnum {
        case .success(let ledger):
            // Verify all required fields are populated
            XCTAssertFalse(ledger.id.isEmpty)
            XCTAssertFalse(ledger.pagingToken.isEmpty)
            XCTAssertFalse(ledger.hashXdr.isEmpty)
            XCTAssertFalse(ledger.previousHashXdr.isEmpty)
            XCTAssertGreaterThan(ledger.sequenceNumber, 0)
            XCTAssertGreaterThanOrEqual(ledger.successfulTransactionCount, 0)
            XCTAssertGreaterThanOrEqual(ledger.failedTransactionCount, 0)
            XCTAssertGreaterThanOrEqual(ledger.operationCount, 0)
            XCTAssertGreaterThanOrEqual(ledger.txSetOperationCount, 0)
            XCTAssertNotNil(ledger.closedAt)
            XCTAssertFalse(ledger.totalCoins.isEmpty)
            XCTAssertFalse(ledger.feePool.isEmpty)
            XCTAssertGreaterThan(ledger.baseFeeInStroops, 0)
            XCTAssertGreaterThan(ledger.baseReserveInStroops, 0)
            XCTAssertGreaterThan(ledger.maxTxSetSize, 0)
            XCTAssertGreaterThanOrEqual(ledger.protocolVersion, 0)
            XCTAssertFalse(ledger.headerXdr.isEmpty)

        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testLedgerResponseAllFieldsPresent()", horizonRequestError: error)
            XCTFail("failed to load ledger")
        }
    }

    func testLedgerLinksStructure() async {
        _ = LedgerFullFieldsMock()

        let responseEnum = await sdk.ledgers.getLedger(sequenceNumber: "777777")

        switch responseEnum {
        case .success(let ledger):
            // Verify links structure
            XCTAssertFalse(ledger.links.selflink.href.isEmpty)
            XCTAssertFalse(ledger.links.transactions.href.isEmpty)
            XCTAssertEqual(ledger.links.transactions.templated, true)
            XCTAssertFalse(ledger.links.operations.href.isEmpty)
            XCTAssertEqual(ledger.links.operations.templated, true)
            XCTAssertFalse(ledger.links.payments.href.isEmpty)
            XCTAssertEqual(ledger.links.payments.templated, true)
            XCTAssertFalse(ledger.links.effects.href.isEmpty)
            XCTAssertEqual(ledger.links.effects.templated, true)

        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testLedgerLinksStructure()", horizonRequestError: error)
            XCTFail("failed to load ledger")
        }
    }

    // MARK: - Pagination Tests

    func testGetLedgersWithLargeLimit() async {
        _ = LedgersUrlTestMock()

        // Test with maximum limit value (Horizon typically maxes at 200)
        let responseEnum = await sdk.ledgers.getLedgers(limit: 200)

        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            // Should return some results but not necessarily 200
            XCTAssertLessThanOrEqual(page.records.count, 200)

        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetLedgersWithLargeLimit()", horizonRequestError: error)
            XCTFail("should accept large limit value")
        }
    }

    func testGetLedgersAscendingOrder() async {
        _ = LedgersUrlTestMock()

        let responseEnum = await sdk.ledgers.getLedgers(order: .ascending, limit: 2)

        switch responseEnum {
        case .success(let page):
            XCTAssertGreaterThanOrEqual(page.records.count, 1)

            // If we have 2+ records, verify ascending order
            if page.records.count >= 2 {
                let first = page.records[0]
                let second = page.records[1]
                XCTAssertLessThan(first.sequenceNumber, second.sequenceNumber, "Ledgers should be in ascending order")
            }

        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testGetLedgersAscendingOrder()", horizonRequestError: error)
            XCTFail("should retrieve ledgers in ascending order")
        }
    }
}

// MARK: - Mock Classes

class LedgersUrlTestMock: ResponsesMock {
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            return """
            {
                "_links": {
                    "self": {
                        "href": "https://horizon-testnet.stellar.org/ledgers?limit=1"
                    },
                    "next": {
                        "href": "https://horizon-testnet.stellar.org/ledgers?order=asc&limit=1&cursor=4294967296"
                    },
                    "prev": {
                        "href": "https://horizon-testnet.stellar.org/ledgers?order=desc&limit=1&cursor=4294967296"
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
                            "prev_hash": "5c809de2f203e578a5941a25946f9ed8760f437277cd3972d0db0ac320a6ba46",
                            "sequence": 1,
                            "successful_transaction_count": 2,
                            "failed_transaction_count": 1,
                            "operation_count": 0,
                            "tx_set_operation_count": 4,
                            "closed_at": "1970-01-01T00:00:00Z",
                            "total_coins": "100000000000.0000000",
                            "fee_pool": "0.0000000",
                            "base_fee_in_stroops": 100,
                            "base_reserve_in_stroops": 100000000,
                            "max_tx_set_size": 100,
                            "protocol_version": 0,
                            "header_xdr": "AAAAAdy3Lr5Tev4ZYxKMei6LWkNgcQaWhEQWlPvuxqAYEUSST/2WLmbNl35twoFs78799llnNyPHs8u5xPtPvzoq9KEAAAAAVg4WeQAAAAAAAAAA3z9hmASpL9tAVxktxD3XSOp3itxSvEmM6AUkwBS4ERkHVi1wPY+0ie6g6YCletq0h1OSHiaWAqDQKJxtKEtlSAAAWsAN4r8dMwM+/wAAABDxA9f6AAAAAwAAAAAAAAAAAAAAZAX14QAAAAH0B1YtcD2PtInuoOmApXratIdTkh4mlgKg0CicbShLZUibK4xTjWYpfADpjyadb48ZEs52+TAOiCYDUIxrs+NjEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                        },
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
                            "successful_transaction_count": 2,
                            "failed_transaction_count": 1,
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
                    ]
                }
            }
            """
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/ledgers",
                          httpMethod: "GET",
                          mockHandler: handler)
    }
}

class LedgerFullFieldsMock: ResponsesMock {
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            guard let sequence = mock.variables["sequence"] else {
                mock.statusCode = 404
                return self.resourceMissingResponse()
            }

            return """
            {
                "_links": {
                    "self": {
                        "href": "https://horizon-testnet.stellar.org/ledgers/\(sequence)"
                    },
                    "transactions": {
                        "href": "https://horizon-testnet.stellar.org/ledgers/\(sequence)/transactions{?cursor,limit,order}",
                        "templated": true
                    },
                    "operations": {
                        "href": "https://horizon-testnet.stellar.org/ledgers/\(sequence)/operations{?cursor,limit,order}",
                        "templated": true
                    },
                    "payments": {
                        "href": "https://horizon-testnet.stellar.org/ledgers/\(sequence)/payments{?cursor,limit,order}",
                        "templated": true
                    },
                    "effects": {
                        "href": "https://horizon-testnet.stellar.org/ledgers/\(sequence)/effects{?cursor,limit,order}",
                        "templated": true
                    }
                },
                "id": "abc123def456abc123def456abc123def456abc123def456abc123def456abc123",
                "paging_token": "3339999111222333",
                "hash": "abc123def456abc123def456abc123def456abc123def456abc123def456abc123",
                "prev_hash": "def456abc123def456abc123def456abc123def456abc123def456abc123def456",
                "sequence": \(sequence),
                "successful_transaction_count": 100,
                "failed_transaction_count": 5,
                "operation_count": 300,
                "tx_set_operation_count": 300,
                "closed_at": "2024-05-15T14:30:45Z",
                "total_coins": "100000000000.0000000",
                "fee_pool": "10000.0000000",
                "base_fee_in_stroops": 100,
                "base_reserve_in_stroops": 5000000,
                "max_tx_set_size": 1000,
                "protocol_version": 21,
                "header_xdr": "AAAAAdy3Lr5Tev4ZYxKMei6LWkNgcQaWhEQWlPvuxqAYEUSST/2WLmbNl35twoFs78799llnNyPHs8u5xPtPvzoq9KEAAAAAVg4WeQAAAAAAAAAA3z9hmASpL9tAVxktxD3XSOp3itxSvEmM6AUkwBS4ERkHVi1wPY+0ie6g6YCletq0h1OSHiaWAqDQKJxtKEtlSAAAWsAN4r8dMwM+/wAAABDxA9f6AAAAAwAAAAAAAAAAAAAAZAX14QAAAAH0B1YtcD2PtInuoOmApXratIdTkh4mlgKg0CicbShLZUibK4xTjWYpfADpjyadb48ZEs52+TAOiCYDUIxrs+NjEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            }
            """
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/ledgers/${sequence}",
                          httpMethod: "GET",
                          mockHandler: handler)
    }
}

class LedgerNotFoundMock: ResponsesMock {
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 404
            return self?.resourceMissingResponse()
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/ledgers/${sequence}",
                          httpMethod: "GET",
                          mockHandler: handler)
    }
}

class LedgerErrorMock: ResponsesMock {
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            guard let sequence = mock.variables["sequence"] else {
                mock.statusCode = 400
                return self.badRequestResponse()
            }

            // Return bad request for invalid sequences (0, negative, non-numeric)
            if sequence == "0" || sequence == "-1" || Int(sequence) == nil {
                mock.statusCode = 400
                return self.badRequestResponse()
            }

            // For other sequences, return not found
            mock.statusCode = 404
            return self.resourceMissingResponse()
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                          path: "/ledgers/${sequence}",
                          httpMethod: "GET",
                          mockHandler: handler)
    }

    func badRequestResponse() -> String {
        return """
        {
            "type": "https://stellar.org/horizon-errors/bad_request",
            "title": "Bad Request",
            "status": 400,
            "detail": "The request you sent was invalid in some way.",
            "instance": "horizon-testnet-001/BadRequest-12345"
        }
        """
    }
}
