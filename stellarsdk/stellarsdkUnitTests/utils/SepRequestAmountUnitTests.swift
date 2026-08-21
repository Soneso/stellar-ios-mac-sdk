//
//  SepRequestAmountUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class SepRequestAmountUnitTests: XCTestCase {

    // MARK: - Plain decimal rendering

    func testSmallAmountRendersPlainDecimal() {
        // 123 stroops, an ordinary amount. String(Double) spells it "1.23e-05".
        XCTAssertEqual("0.0000123", SepRequestAmount.format(0.0000123))
    }

    func testOneStroopRendersAllSevenDecimals() {
        XCTAssertEqual("0.0000001", SepRequestAmount.format(0.0000001))
    }

    func testWholeAmountSuppressesDecimalPoint() {
        XCTAssertEqual("100", SepRequestAmount.format(100.0))
        XCTAssertEqual("1", SepRequestAmount.format(1.0))
        // The trim stops at the decimal point, so zeroes in the integer part survive.
        XCTAssertEqual("120", SepRequestAmount.format(120.0))
        XCTAssertEqual("1000000000000000", SepRequestAmount.format(1e15))
    }

    func testTrailingZeroesInFractionAreTrimmed() {
        XCTAssertEqual("0.000012", SepRequestAmount.format(0.0000120))
        XCTAssertEqual("0.00001", SepRequestAmount.format(0.0000100))
    }

    func testLargeAmountRendersPlainDecimal() {
        // String(Double) spells these "1e+16" and "1e+21".
        XCTAssertEqual("10000000000000000", SepRequestAmount.format(1e16))
        XCTAssertEqual("1000000000000000000000", SepRequestAmount.format(1e21))
    }

    func testLargeAmountKeepsTheWrittenDecimals() {
        // The stored Double is 100000000000.100006103515625; the shortest representation is
        // the written value, and no digit beyond it may be rendered.
        XCTAssertEqual("100000000000.1", SepRequestAmount.format(100_000_000_000.1))
        XCTAssertEqual("-100000000000.1", SepRequestAmount.format(-100_000_000_000.1))
        XCTAssertEqual("600000000.1", SepRequestAmount.format(600_000_000.1))
    }

    // MARK: - Rounding to seven decimal places

    func testMoreThanSevenDecimalsRoundsToSeven() {
        XCTAssertEqual("1.2345679", SepRequestAmount.format(1.23456789))
    }

    func testSeventhDigitIsRoundedNotTruncated() {
        // The shortest representation carries exactly seven fractional digits here and is
        // rendered unchanged.
        XCTAssertEqual("780615714.9429096", SepRequestAmount.format(780615714.9429096))
    }

    func testHalfwayFractionRoundsAwayFromZero() {
        // The written value 0.00000015 ends exactly halfway at the seventh place.
        XCTAssertEqual("0.0000002", SepRequestAmount.format(1.5e-7))
        XCTAssertEqual("-0.0000002", SepRequestAmount.format(-1.5e-7))
        // Half a stroop exactly is halfway at the zero boundary and rounds away,
        // keeping its sign.
        XCTAssertEqual("0.0000001", SepRequestAmount.format(5e-8))
        XCTAssertEqual("-0.0000001", SepRequestAmount.format(-5e-8))
    }

    func testRoundingCarriesThroughTheIntegerPart() {
        XCTAssertEqual("1", SepRequestAmount.format(0.99999995))
        XCTAssertEqual("2", SepRequestAmount.format(1.99999996))
    }

    func testBelowHalfAStroopRoundsToZero() {
        XCTAssertEqual("0", SepRequestAmount.format(0.00000004))
        XCTAssertEqual("0", SepRequestAmount.format(1e-10))
    }

    // MARK: - Sign

    func testNegativeAmountKeepsItsSign() {
        XCTAssertEqual("-0.0000123", SepRequestAmount.format(-0.0000123))
        XCTAssertEqual("-1000000000000000000000", SepRequestAmount.format(-1e21))
    }

    func testZeroRendersWithoutSign() {
        XCTAssertEqual("0", SepRequestAmount.format(0.0))
        XCTAssertEqual("0", SepRequestAmount.format(-0.0))
        // An amount below half a stroop rounds away, and zero carries no sign.
        XCTAssertEqual("0", SepRequestAmount.format(-0.00000001))
    }

    // MARK: - Non-finite amounts

    func testNonFiniteAmountRendersEmpty() {
        XCTAssertEqual("", SepRequestAmount.format(.nan))
        XCTAssertEqual("", SepRequestAmount.format(.signalingNaN))
        XCTAssertEqual("", SepRequestAmount.format(.infinity))
        XCTAssertEqual("", SepRequestAmount.format(-.infinity))
    }

    // MARK: - Invariants

    func testNoFiniteAmountRendersAnExponent() {
        let amounts: [Double] = [0.0000001, 0.0000123, 1e-10, 1e16, 1e21, 1e60,
                                 .greatestFiniteMagnitude, .leastNormalMagnitude,
                                 -1e21, -0.0000123]
        for amount in amounts {
            let rendered = SepRequestAmount.format(amount)
            XCTAssertFalse(rendered.contains("e"), "exponent in \(rendered)")
            XCTAssertFalse(rendered.contains("E"), "exponent in \(rendered)")
        }
    }

    /// The rendering must not follow the device's regional settings, which would otherwise
    /// supply a comma separator or non-ASCII digits.
    ///
    /// The rendering is decimal string arithmetic on `String(Double)`, which never consults
    /// the device, so these assertions pin the ASCII-and-period character set on every
    /// machine, including one whose language identifier carries a regional override such as
    /// `en_US@rg=eszzzz` - the configuration that surfaces locale-dependent formatting in
    /// the field.
    func testRenderingDoesNotFollowTheDeviceLocale() {
        let allowed = Set("0123456789.-")
        let amounts: [Double] = [0.0000123, 1e21, -0.0000123, 1e16, 0.0000001,
                                 100_000_000_000.1, 1.5e-7]
        for amount in amounts {
            let rendered = SepRequestAmount.format(amount)
            XCTAssertTrue(rendered.allSatisfy { allowed.contains($0) },
                          "unexpected characters in \(rendered)")
        }
    }
}
