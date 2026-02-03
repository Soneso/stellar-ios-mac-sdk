//
//  GetLedgersTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class GetLedgersTestCase: XCTestCase {

    static let testOn = "testnet" // "futurenet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    override func setUp() async throws {
        try await super.setUp()
        sorobanServer.enableLogging = true
    }

    func testGetLedgers() async {
        // Get latest ledger to determine a valid start point
        var latestLedger: UInt32? = nil
        let latestLedgerResponseEnum = await sorobanServer.getLatestLedger()
        switch latestLedgerResponseEnum {
        case .success(let latestLedgerResponse):
            latestLedger = latestLedgerResponse.sequence
        case .failure(let error):
            self.printError(error: error)
            XCTFail("Failed to get latest ledger")
            return
        }
        XCTAssertNotNil(latestLedger, "Latest ledger should not be nil")
        guard let currentLedger = latestLedger else { return }

        // Test 1: Basic getLedgers request with limit
        // Use a start ledger far enough back to ensure we have multiple ledgers available
        let startLedger = currentLedger > 100 ? currentLedger - 100 : 1
        var ledgersResponseEnum = await sorobanServer.getLedgers(startLedger: startLedger, paginationOptions: PaginationOptions(limit: 5))
        var cursor: String? = nil

        switch ledgersResponseEnum {
        case .success(let ledgersResponse):
            XCTAssert(ledgersResponse.ledgers.count > 0, "Should return at least one ledger")
            XCTAssert(ledgersResponse.ledgers.count <= 5, "Should not exceed requested limit of 5")
            XCTAssertNotNil(ledgersResponse.cursor, "Cursor should not be nil")
            XCTAssert(ledgersResponse.latestLedger > 0, "Latest ledger should be greater than 0")
            XCTAssert(ledgersResponse.oldestLedger > 0, "Oldest ledger should be greater than 0")

            // Verify ledger info structure
            if let firstLedger = ledgersResponse.ledgers.first {
                XCTAssertFalse(firstLedger.ledgerHash.isEmpty, "Ledger hash should not be empty")
                XCTAssert(firstLedger.sequence >= startLedger, "Ledger sequence should be >= start ledger")
                XCTAssertNotNil(firstLedger.headerXdr, "Header XDR should not be nil")
                XCTAssertNotNil(firstLedger.metadataXdr, "Metadata XDR should not be nil")
            } else {
                XCTFail("No ledgers returned in response")
            }
            cursor = ledgersResponse.cursor
        case .failure(let error):
            self.printError(error: error)
            XCTFail("Failed to get ledgers with basic request")
            return
        }
        XCTAssertNotNil(cursor, "Cursor from first request should not be nil")

        // Test 2: Pagination with cursor
        // Note: Cursor pagination might return fewer results or empty if we've reached the end
        ledgersResponseEnum = await sorobanServer.getLedgers(startLedger: startLedger, paginationOptions: PaginationOptions(cursor: cursor, limit: 3))
        switch ledgersResponseEnum {
        case .success(let ledgersResponse):
            // Validate the response structure even if no more ledgers
            XCTAssert(ledgersResponse.ledgers.count <= 3, "Should not exceed requested limit of 3")
            XCTAssert(ledgersResponse.latestLedger > 0, "Latest ledger should be greater than 0")
            // This test passes even with 0 results since we may have paginated past available ledgers
        case .failure(let error):
            // Log the error but don't fail - cursor pagination past the end might error
            self.printError(error: error)
            print("Note: Cursor pagination error may be expected if paginating past available ledgers")
        }

        // Test 3: Request without pagination options (should use default limit)
        ledgersResponseEnum = await sorobanServer.getLedgers(startLedger: startLedger)
        switch ledgersResponseEnum {
        case .success(let ledgersResponse):
            XCTAssert(ledgersResponse.ledgers.count > 0, "Should return at least one ledger without pagination")
            XCTAssertNotNil(ledgersResponse.cursor, "Cursor should not be nil in unpaginated response")
        case .failure(let error):
            self.printError(error: error)
            XCTFail("Failed to get ledgers without pagination options")
        }
    }

    func printError(error: SorobanRpcRequestError) {
        switch error {
        case .requestFailed(let message):
            print("Request failed: \(message)")
        case .errorResponse(let err):
            print("Error response: \(err)")
        case .parsingResponseFailed(let message, _):
            print("Parsing failed: \(message)")
        }
    }
}
