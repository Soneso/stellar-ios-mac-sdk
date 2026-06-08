//
//  StellarProtocolConstantsTests.swift
//  stellarsdkUnitTests
//
//  Copyright © Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class StellarProtocolConstantsTests: XCTestCase {

    // MARK: - stroopsPerXlm

    func testStroopsPerXlm_equals10_000_000() {
        XCTAssertEqual(StellarProtocolConstants.stroopsPerXlm, 10_000_000)
    }

    func testStroopsPerXlm_isInt64() {
        let v: Int64 = StellarProtocolConstants.stroopsPerXlm
        XCTAssertEqual(v, 10_000_000)
    }

    func testStroopsPerXlm_oneXlmInStroops() {
        // 1 XLM expressed as stroops must equal the constant.
        let oneXlmStroops: Int64 = 1 * StellarProtocolConstants.stroopsPerXlm
        XCTAssertEqual(oneXlmStroops, 10_000_000)
    }

    // MARK: - ledgersPerHour

    func testLedgersPerHour_equals720() {
        XCTAssertEqual(StellarProtocolConstants.ledgersPerHour, 720)
    }

    func testLedgersPerHour_isInt() {
        let v: Int = StellarProtocolConstants.ledgersPerHour
        XCTAssertEqual(v, 720)
    }

    func testLedgersPerHour_derivedFrom5SecondLedgerInterval() {
        // 3600 seconds / 5 seconds per ledger = 720.
        XCTAssertEqual(StellarProtocolConstants.ledgersPerHour, 3600 / 5)
    }

    // MARK: - ledgersPerDay

    func testLedgersPerDay_equals17_280() {
        XCTAssertEqual(StellarProtocolConstants.ledgersPerDay, 17_280)
    }

    func testLedgersPerDay_isInt() {
        let v: Int = StellarProtocolConstants.ledgersPerDay
        XCTAssertEqual(v, 17_280)
    }

    func testLedgersPerDay_equals24xLedgersPerHour() {
        XCTAssertEqual(StellarProtocolConstants.ledgersPerDay, StellarProtocolConstants.ledgersPerHour * 24)
    }
}
