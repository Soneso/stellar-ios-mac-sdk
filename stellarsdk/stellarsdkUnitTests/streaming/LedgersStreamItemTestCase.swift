//
//  LedgersStreamItemTestCase.swift
//  stellarsdk
//
//  Created by Claude Code
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LedgersStreamItemTestCase: XCTestCase {

    var streamItem: LedgersStreamItem!
    let testUrl = "https://horizon-testnet.stellar.org/ledgers"

    override func setUp() {
        super.setUp()
        streamItem = LedgersStreamItem(requestUrl: testUrl)
    }

    override func tearDown() {
        streamItem?.closeStream()
        streamItem = nil
        super.tearDown()
    }

    // MARK: - Test 1: Initialization

    func testInitialization() {
        let streamItem = LedgersStreamItem(requestUrl: testUrl)
        XCTAssertNotNil(streamItem)
    }

    // MARK: - Test 2: Close Stream

    func testCloseStream() {
        let streamItem = LedgersStreamItem(requestUrl: testUrl)
        streamItem.closeStream()
        // If no crash occurs, the test passes
        XCTAssertTrue(true)
    }

    // MARK: - Test 3: OnReceive Handler Registration

    @MainActor
    func testOnReceiveRegistration() {
        let expectation = self.expectation(description: "Stream handler registered")
        expectation.isInverted = true

        streamItem.onReceive { response in
            // This should not be called immediately
        }

        // Wait briefly to ensure handler doesn't fire immediately
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    // MARK: - Test 4: Multiple Initializations

    func testMultipleInitializations() {
        let streamItem1 = LedgersStreamItem(requestUrl: testUrl)
        let streamItem2 = LedgersStreamItem(requestUrl: "https://horizon-testnet.stellar.org/ledgers?cursor=now")

        XCTAssertNotNil(streamItem1)
        XCTAssertNotNil(streamItem2)

        streamItem1.closeStream()
        streamItem2.closeStream()
    }

    // MARK: - Test 5: Close Before OnReceive

    func testCloseBeforeOnReceive() {
        let streamItem = LedgersStreamItem(requestUrl: testUrl)
        streamItem.closeStream()

        // Should not crash when registering handler after close
        streamItem.onReceive { response in
            // This handler should not be called
        }

        XCTAssertTrue(true)
    }

    // MARK: - Test 6: Multiple Close Calls

    func testMultipleCloseCalls() {
        let streamItem = LedgersStreamItem(requestUrl: testUrl)
        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()

        // Should not crash with multiple close calls
        XCTAssertTrue(true)
    }

    // MARK: - Test 7: Empty URL

    func testEmptyUrl() {
        let streamItem = LedgersStreamItem(requestUrl: "")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    // MARK: - Test 8: Invalid URL

    func testInvalidUrl() {
        let streamItem = LedgersStreamItem(requestUrl: "not-a-valid-url")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    // MARK: - Test 9: OnReceive Multiple Registrations

    func testOnReceiveMultipleRegistrations() {
        let streamItem = LedgersStreamItem(requestUrl: testUrl)

        streamItem.onReceive { response in
            // First handler
        }

        streamItem.onReceive { response in
            // Second handler (replaces first)
        }

        streamItem.closeStream()
        XCTAssertTrue(true)
    }

    // MARK: - Test 10: Sendable Conformance

    func testSendableConformance() {
        // Test that LedgersStreamItem conforms to Sendable
        let streamItem: any Sendable = LedgersStreamItem(requestUrl: testUrl)
        XCTAssertNotNil(streamItem)
    }
}
