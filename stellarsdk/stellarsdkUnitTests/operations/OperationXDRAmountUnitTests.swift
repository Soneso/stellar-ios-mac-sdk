//
//  OperationXDRAmountUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 28/03/26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for `Operation.toXDRAmount(amount:)` covering the security-hardened
/// negative-amount guard and Int64 overflow guard introduced in the sec-improvements branch.
class OperationXDRAmountUnitTests: XCTestCase {

    // MARK: - Negative amount

    func testNegativeAmountThrowsInvalidArgument() {
        XCTAssertThrowsError(try Operation.toXDRAmount(amount: Decimal(-1))) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(
                    message.contains("-1"),
                    "Error message should contain the offending value; got: \(message)"
                )
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    func testLargeNegativeAmountThrowsInvalidArgument() {
        XCTAssertThrowsError(try Operation.toXDRAmount(amount: Decimal(-9999999))) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument:
                break
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    // MARK: - Overflow

    /// An amount that, when multiplied by 10_000_000 (stroops/XLM), exceeds Int64.max.
    /// Int64.max = 9_223_372_036_854_775_807 stroops.
    /// 922_337_203_686 XLM * 10_000_000 = 9_223_372_036_860_000_000 > Int64.max.
    func testOverflowAmountThrowsInvalidArgument() {
        let overflowAmount = Decimal(922_337_203_686)
        XCTAssertThrowsError(try Operation.toXDRAmount(amount: overflowAmount)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(
                    message.contains("large") || message.contains("Int64") || message.contains("range"),
                    "Error message should indicate overflow; got: \(message)"
                )
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    func testExtremelyLargeAmountThrowsInvalidArgument() {
        let extremeAmount = Decimal(sign: .plus, exponent: 20, significand: 1)
        XCTAssertThrowsError(try Operation.toXDRAmount(amount: extremeAmount)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument:
                break
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    // MARK: - Zero

    func testZeroAmountSucceeds() throws {
        let result = try Operation.toXDRAmount(amount: Decimal(0))
        XCTAssertEqual(result, 0, "Zero XLM should produce 0 stroops")
    }

    // MARK: - Valid amounts

    func testTypicalAmountRoundTrip() throws {
        // 100 XLM = 1_000_000_000 stroops
        let result = try Operation.toXDRAmount(amount: Decimal(100))
        XCTAssertEqual(result, 1_000_000_000)
    }

    func testFractionalAmountRoundTrip() throws {
        // 0.5 XLM = 5_000_000 stroops
        let result = try Operation.toXDRAmount(amount: Decimal(string: "0.5")!)
        XCTAssertEqual(result, 5_000_000)
    }

    func testOneStroop() throws {
        // 0.0000001 XLM = 1 stroop
        let result = try Operation.toXDRAmount(amount: Decimal(string: "0.0000001")!)
        XCTAssertEqual(result, 1)
    }

    /// Maximum valid amount: 922_337_203_685 XLM.
    /// 922_337_203_685 * 10_000_000 = 9_223_372_036_850_000_000, which is <= Int64.max.
    func testMaximumValidAmountSucceeds() throws {
        let maxAmount = Decimal(922_337_203_685)
        let result = try Operation.toXDRAmount(amount: maxAmount)
        XCTAssertEqual(result, 9_223_372_036_850_000_000)
    }

    // MARK: - Fractional boundary near Int64.max

    /// Int64.max = 9_223_372_036_854_775_807 stroops = 922337203685.4775807 XLM.
    /// A fractional amount just at the maximum stroop value should succeed.
    func testFractionalMaxStroopsSucceeds() throws {
        let maxFractional = Decimal(string: "922337203685.4775807")!
        let result = try Operation.toXDRAmount(amount: maxFractional)
        XCTAssertEqual(result, Int64.max)
    }

    /// One stroop above Int64.max should throw.
    func testFractionalOneStroopAboveMaxThrows() {
        let aboveMax = Decimal(string: "922337203685.4775808")!
        XCTAssertThrowsError(try Operation.toXDRAmount(amount: aboveMax)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument:
                break
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }
}
