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

    // MARK: - Rounding to seven decimal places

    func testMoreThanSevenDecimalsRoundsToSeven() {
        XCTAssertEqual("1.2345679", SepRequestAmount.format(1.23456789))
    }

    func testSeventhDigitIsRoundedNotTruncated() {
        // The Double here is 780615714.94290959835052490234375, so rendering more digits and
        // cutting at the seventh yields ...9429095 while rounding yields ...9429096.
        XCTAssertEqual("780615714.9429096", SepRequestAmount.format(780615714.9429096))
    }

    func testHalfStroopTieFollowsTheStoredValue() {
        // The Double nearest 1.5e-7 is 0.000000149999999999999993, so the nearer seven-decimal
        // value is one stroop, not two.
        XCTAssertEqual("0.0000001", SepRequestAmount.format(1.5e-7))
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
    /// The first assertion pins what a regional setting does to this format string; the ones
    /// after it catch a rendering that consults the device. They discriminate on any machine
    /// whose region format is not period-separated, which includes a language identifier
    /// carrying a regional override such as `en_US@rg=eszzzz` - the configuration that
    /// surfaces this in the field. Where the region is period-separated throughout they
    /// render the same either way, so that case rests on the explicit `locale: nil`.
    func testRenderingDoesNotFollowTheDeviceLocale() {
        XCTAssertEqual("0,0000123",
                       String(format: "%.7f", locale: Locale(identifier: "de_DE"), 0.0000123))
        XCTAssertEqual("0.0000123", SepRequestAmount.format(0.0000123))

        let allowed = Set("0123456789.-")
        let amounts: [Double] = [0.0000123, 1e21, -0.0000123, 1e16, 0.0000001]
        for amount in amounts {
            let rendered = SepRequestAmount.format(amount)
            XCTAssertTrue(rendered.allSatisfy { allowed.contains($0) },
                          "unexpected characters in \(rendered)")
        }
    }
}
