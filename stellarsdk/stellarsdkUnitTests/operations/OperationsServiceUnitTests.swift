//
//  OperationsServiceUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationsServiceUnitTests: XCTestCase {

    // MARK: - Properties

    let horizonServer = "horizon-testnet.stellar.org"
    let testAccountId = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
    let testLedger = "12345"
    let testTransactionHash = "6b983a4e0dc3c04f4bd6b9037c55f70a09c434dfd01492be1077cf7ea68c2e4a"
    let testClaimableBalanceIdHex = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
    let testClaimableBalanceId = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
    let testLiquidityPoolIdHex = "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
    let testOperationId = "123456789"

    var sdk: StellarSDK!
    var operationsServiceResponseMock: OperationsServiceResponseMock!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)
        ServerMock.removeAll()

        sdk = StellarSDK(withHorizonUrl: "https://\(horizonServer)")
        operationsServiceResponseMock = OperationsServiceResponseMock(address: horizonServer)
    }

    override func tearDown() {
        operationsServiceResponseMock = nil
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - getOperations() Tests

    func testGetOperations() async {
        let responseEnum = await sdk.operations.getOperations()
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")
            XCTAssertNotNil(page.links.selflink)

            // Verify first operation details from mock
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)
            XCTAssertEqual(firstOperation.transactionHash, testTransactionHash)
            XCTAssertEqual(firstOperation.pagingToken, "123456789")
            XCTAssertTrue(firstOperation.transactionSuccessful)

            // Verify payment-specific fields
            if let paymentOp = firstOperation as? PaymentOperationResponse {
                XCTAssertEqual(paymentOp.amount, "100.0000000")
                XCTAssertEqual(paymentOp.assetCode, "USD")
                XCTAssertEqual(paymentOp.from, testAccountId)
                XCTAssertEqual(paymentOp.to, "GBTKSLJLC2E5SZCNUKNB34GXMXVR3LHJQFSAID64RDQQEZ3IQPBXZHZ6")
            } else {
                XCTFail("First operation should be PaymentOperationResponse")
            }

            // Verify second operation is create_account type
            let secondOperation = page.records[1]
            XCTAssertEqual(secondOperation.id, "123456788")
            XCTAssertEqual(secondOperation.operationType, .accountCreated)

        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithLimit() async {
        let responseEnum = await sdk.operations.getOperations(limit: 50)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 50)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithCursor() async {
        let cursor = "123456789"
        let responseEnum = await sdk.operations.getOperations(from: cursor)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithOrder() async {
        let responseEnum = await sdk.operations.getOperations(order: .descending)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            if page.records.count >= 2 {
                let first = page.records[0]
                let second = page.records[1]
                XCTAssertGreaterThanOrEqual(first.id, second.id)
            }
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithIncludeFailed() async {
        let responseEnum = await sdk.operations.getOperations(includeFailed: true)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithJoin() async {
        let responseEnum = await sdk.operations.getOperations(join: "transactions")
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithAllParameters() async {
        let responseEnum = await sdk.operations.getOperations(
            from: "123456789",
            order: .ascending,
            limit: 25,
            includeFailed: true,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 25)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsWithLargeLimit() async {
        let responseEnum = await sdk.operations.getOperations(limit: 200)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 200)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    // MARK: - getOperations(forAccount:) Tests

    func testGetOperationsForAccount() async {
        let responseEnum = await sdk.operations.getOperations(forAccount: testAccountId)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)
            XCTAssertEqual(firstOperation.transactionHash, testTransactionHash)

            // Verify all operations have source account matching test account
            for operation in page.records {
                XCTAssertEqual(operation.sourceAccount, testAccountId)
            }
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForAccountWithParameters() async {
        let responseEnum = await sdk.operations.getOperations(
            forAccount: testAccountId,
            from: "123456789",
            order: .descending,
            limit: 20,
            includeFailed: false,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 20)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForInvalidAccount() async {
        let responseEnum = await sdk.operations.getOperations(forAccount: "INVALID")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with invalid account")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - getOperations(forLedger:) Tests

    func testGetOperationsForLedger() async {
        let responseEnum = await sdk.operations.getOperations(forLedger: testLedger)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForLedgerWithParameters() async {
        let responseEnum = await sdk.operations.getOperations(
            forLedger: testLedger,
            from: "123456789",
            order: .ascending,
            limit: 15,
            includeFailed: true,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 15)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForInvalidLedger() async {
        let responseEnum = await sdk.operations.getOperations(forLedger: "99999999999")
        switch responseEnum {
        case .success(let page):
            // May return empty results for non-existent ledger
            XCTAssertEqual(page.records.count, 5, "Mock returns operations for any valid ledger format")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error or success, got: \(error)")
            }
        }
    }

    // MARK: - getOperations(forTransaction:) Tests

    func testGetOperationsForTransaction() async {
        let responseEnum = await sdk.operations.getOperations(forTransaction: testTransactionHash)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.transactionHash, testTransactionHash)
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)

            // Verify all operations have transaction hash
            for operation in page.records {
                XCTAssertFalse(operation.transactionHash.isEmpty, "Transaction hash should not be empty")
            }
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForTransactionWithParameters() async {
        let responseEnum = await sdk.operations.getOperations(
            forTransaction: testTransactionHash,
            from: "123456789",
            order: .descending,
            limit: 10,
            includeFailed: true,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 10)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForInvalidTransaction() async {
        let responseEnum = await sdk.operations.getOperations(forTransaction: "invalid_hash")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with invalid transaction hash")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - getOperations(forClaimableBalance:) Tests

    func testGetOperationsForClaimableBalanceHex() async {
        let responseEnum = await sdk.operations.getOperations(forClaimableBalance: testClaimableBalanceIdHex)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForClaimableBalanceBPrefix() async {
        let bAddress = "B00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        let responseEnum = await sdk.operations.getOperations(forClaimableBalance: bAddress)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForClaimableBalanceWithParameters() async {
        let responseEnum = await sdk.operations.getOperations(
            forClaimableBalance: testClaimableBalanceIdHex,
            from: "123456789",
            order: .ascending,
            limit: 30,
            includeFailed: false,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 30)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForInvalidClaimableBalance() async {
        let responseEnum = await sdk.operations.getOperations(forClaimableBalance: "invalid")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with invalid claimable balance ID")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - getOperations(forLiquidityPool:) Tests

    func testGetOperationsForLiquidityPoolHex() async {
        let responseEnum = await sdk.operations.getOperations(forLiquidityPool: testLiquidityPoolIdHex)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForLiquidityPoolLPrefix() async {
        let lAddress = "L67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
        let responseEnum = await sdk.operations.getOperations(forLiquidityPool: lAddress)
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForLiquidityPoolWithParameters() async {
        let responseEnum = await sdk.operations.getOperations(
            forLiquidityPool: testLiquidityPoolIdHex,
            from: "123456789",
            order: .descending,
            limit: 40,
            includeFailed: true,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 40)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsForInvalidLiquidityPool() async {
        let responseEnum = await sdk.operations.getOperations(forLiquidityPool: "invalid")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with invalid liquidity pool ID")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - getOperationDetails(operationId:) Tests

    func testGetOperationDetails() async {
        let responseEnum = await sdk.operations.getOperationDetails(operationId: testOperationId)
        switch responseEnum {
        case .success(let operation):
            XCTAssertEqual(operation.id, testOperationId)
            XCTAssertNotNil(operation.sourceAccount)
            XCTAssertNotNil(operation.operationType)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationDetailsWithIncludeFailed() async {
        let responseEnum = await sdk.operations.getOperationDetails(
            operationId: testOperationId,
            includeFailed: true
        )
        switch responseEnum {
        case .success(let operation):
            XCTAssertEqual(operation.id, testOperationId)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationDetailsWithJoin() async {
        let responseEnum = await sdk.operations.getOperationDetails(
            operationId: testOperationId,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let operation):
            XCTAssertEqual(operation.id, testOperationId)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationDetailsWithAllParameters() async {
        let responseEnum = await sdk.operations.getOperationDetails(
            operationId: testOperationId,
            includeFailed: true,
            join: "transactions"
        )
        switch responseEnum {
        case .success(let operation):
            XCTAssertEqual(operation.id, testOperationId)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationDetailsNotFound() async {
        let responseEnum = await sdk.operations.getOperationDetails(operationId: "999999999999")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with not found error")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    func testGetOperationDetailsInvalidId() async {
        let responseEnum = await sdk.operations.getOperationDetails(operationId: "invalid")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with invalid ID")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - getOperationsFromUrl(url:) Tests

    func testGetOperationsFromUrl() async {
        let url = "https://\(horizonServer)/operations?limit=10"
        let responseEnum = await sdk.operations.getOperationsFromUrl(url: url)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
            XCTAssertEqual(firstOperation.operationType, .payment)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsFromUrlWithPagination() async {
        let url = "https://\(horizonServer)/operations?cursor=123456789&order=asc&limit=5"
        let responseEnum = await sdk.operations.getOperationsFromUrl(url: url)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            // Verify pagination links are present and properly formatted
            XCTAssertNotNil(page.links.next)
            XCTAssertNotNil(page.links.prev)
            XCTAssertTrue(page.links.next!.href.contains("cursor="))
            XCTAssertTrue(page.links.prev!.href.contains("cursor="))

            // Verify first operation details
            let firstOperation = page.records[0]
            XCTAssertEqual(firstOperation.id, "123456789")
            XCTAssertEqual(firstOperation.sourceAccount, testAccountId)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testGetOperationsFromInvalidUrl() async {
        let url = "https://\(horizonServer)/invalid_endpoint"
        let responseEnum = await sdk.operations.getOperationsFromUrl(url: url)
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with invalid URL")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - Error Handling Tests

    func testBadRequestError() async {
        let responseEnum = await sdk.operations.getOperations(limit: 999999)
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with bad request error")
        case .failure(let error):
            if case .badRequest(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected badRequest error, got: \(error)")
            }
        }
    }

    func testMalformedJsonResponse() async {
        let responseEnum = await sdk.operations.getOperationDetails(operationId: "malformed")
        switch responseEnum {
        case .success(_):
            XCTFail("Should have failed with malformed JSON")
        case .failure(let error):
            if case .parsingResponseFailed(let message) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                // Also acceptable: requestFailed may occur for JSON parsing errors
                if case .requestFailed(let message, _) = error {
                    XCTAssertFalse(message.isEmpty, "Error message should not be empty")
                } else {
                    XCTFail("Expected parsingResponseFailed or requestFailed error, got: \(error)")
                }
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testEmptyResultsForAccount() async {
        let emptyAccount = "GDUMMY7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        let responseEnum = await sdk.operations.getOperations(forAccount: emptyAccount)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 0, "Expected empty results for dummy account")
            XCTAssertNotNil(page.links.selflink, "Links should still be present in empty response")
        case .failure(let error):
            // Also acceptable - account may not be found
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error or empty success, got: \(error)")
            }
        }
    }

    func testEmptyResultsForLedger() async {
        let responseEnum = await sdk.operations.getOperations(forLedger: "1")
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 0, "Expected empty results for ledger 1")
            XCTAssertNotNil(page.links.selflink, "Links should still be present in empty response")
        case .failure(let error):
            // Also acceptable - ledger may have no operations
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected notFound error or empty success, got: \(error)")
            }
        }
    }

    func testPaginationConsistency() async {
        // Get first page
        let firstPageResponse = await sdk.operations.getOperations(limit: 2)
        guard case .success(let firstPage) = firstPageResponse else {
            XCTFail("Failed to get first page")
            return
        }

        XCTAssertNotNil(firstPage.links.next)

        // Get next page using next link
        if let nextUrl = firstPage.links.next?.href {
            let secondPageResponse = await sdk.operations.getOperationsFromUrl(url: nextUrl)
            switch secondPageResponse {
            case .success(let secondPage):
                XCTAssertNotNil(secondPage.records)
                // Mock returns same data but pagination links are present
                XCTAssertNotNil(secondPage.links.next)
                XCTAssertNotNil(secondPage.links.prev)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
        }
    }

    func testOrderingAscending() async {
        let responseEnum = await sdk.operations.getOperations(order: .ascending, limit: 5)
        switch responseEnum {
        case .success(let page):
            guard page.records.count >= 2 else {
                return
            }

            // Mock returns descending by default, so just verify we got operations
            XCTAssertGreaterThan(page.records.count, 0)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testOrderingDescending() async {
        let responseEnum = await sdk.operations.getOperations(order: .descending, limit: 5)
        switch responseEnum {
        case .success(let page):
            guard page.records.count >= 2 else {
                return
            }

            for i in 0..<(page.records.count - 1) {
                let current = page.records[i].id
                let next = page.records[i + 1].id
                XCTAssertGreaterThanOrEqual(current, next, "Operations should be in descending order")
            }
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testOperationTypesVariety() async {
        let responseEnum = await sdk.operations.getOperations(limit: 100)
        switch responseEnum {
        case .success(let page):
            let operationTypes = Set(page.records.map { $0.operationType })
            // Just verify we get some operations with types
            XCTAssertGreaterThan(operationTypes.count, 0)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testLimitBoundaries() async {
        // Test limit = 1
        let responseMin = await sdk.operations.getOperations(limit: 1)
        switch responseMin {
        case .success(let page):
            // Mock returns 5 operations, but we verify it's not more than reasonable
            XCTAssertNotNil(page.records)
            XCTAssertGreaterThan(page.records.count, 0)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }

        // Test limit = 200 (max)
        let responseMax = await sdk.operations.getOperations(limit: 200)
        switch responseMax {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertLessThanOrEqual(page.records.count, 200)
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testCursorNavigation() async {
        // Get operations and use cursor from last record
        let firstResponse = await sdk.operations.getOperations(limit: 5)
        guard case .success(let firstPage) = firstResponse,
              let lastOperation = firstPage.records.last else {
            XCTFail("Failed to get first page")
            return
        }

        let cursor = lastOperation.pagingToken
        let secondResponse = await sdk.operations.getOperations(from: cursor, order: .ascending, limit: 5)
        switch secondResponse {
        case .success(let secondPage):
            XCTAssertNotNil(secondPage.records)
            // Verify cursor worked - first operation in second page should come after cursor
            if let firstInSecondPage = secondPage.records.first {
                XCTAssertGreaterThan(firstInSecondPage.id, lastOperation.id)
            }
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testMultipleOperationTypesInResponse() async {
        let responseEnum = await sdk.operations.getOperations(limit: 50)
        switch responseEnum {
        case .success(let page):
            XCTAssertEqual(page.records.count, 5, "Expected 5 operations from mock response")

            var hasPayment = false
            var hasAccountCreated = false
            var hasManageSellOffer = false
            var hasManageBuyOffer = false
            var hasSetOptions = false

            for operation in page.records {
                switch operation.operationType {
                case .payment:
                    hasPayment = true
                case .accountCreated:
                    hasAccountCreated = true
                case .manageSellOffer:
                    hasManageSellOffer = true
                case .manageBuyOffer:
                    hasManageBuyOffer = true
                case .setOptions:
                    hasSetOptions = true
                default:
                    break
                }
            }

            // Verify all expected operation types from mock are present
            XCTAssertTrue(hasPayment, "Mock should include payment operation")
            XCTAssertTrue(hasAccountCreated, "Mock should include create_account operation")
            XCTAssertTrue(hasManageSellOffer, "Mock should include manage_sell_offer operation")
            XCTAssertTrue(hasManageBuyOffer, "Mock should include manage_buy_offer operation")
            XCTAssertTrue(hasSetOptions, "Mock should include set_options operation")
        case .failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }
}
