//
//  PriceTestCase.swift
//  stellarsdk
//
//  Created by Soneso on 05.10.2025.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PriceTestCase: XCTestCase {

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - testFromStringBasicCases

    func testFromStringZero() {
        let price = Price.fromString(price: "0")
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringOne() {
        let price = Price.fromString(price: "1")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringPointOne() {
        let price = Price.fromString(price: "0.1")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 10)
    }

    func testFromStringPointFive() {
        let price = Price.fromString(price: "0.5")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 2)
    }

    func testFromStringOnePointFive() {
        let price = Price.fromString(price: "1.5")
        XCTAssertEqual(price.n, 3)
        XCTAssertEqual(price.d, 2)
    }

    func testFromStringFive() {
        let price = Price.fromString(price: "5")
        XCTAssertEqual(price.n, 5)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringTen() {
        let price = Price.fromString(price: "10")
        XCTAssertEqual(price.n, 10)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringPointZeroOne() {
        let price = Price.fromString(price: "0.01")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 100)
    }

    func testFromStringPointZeroZeroOne() {
        let price = Price.fromString(price: "0.001")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 1000)
    }

    func testFromStringOneQuarter() {
        let price = Price.fromString(price: "0.25")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 4)
    }

    func testFromStringThreeQuarters() {
        let price = Price.fromString(price: "0.75")
        XCTAssertEqual(price.n, 3)
        XCTAssertEqual(price.d, 4)
    }

    func testFromStringOneThird() {
        // 0.333... should approximate to 1/3
        let price = Price.fromString(price: "0.3333333333333333")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 3)
    }

    func testFromStringTwoThirds() {
        // 0.666... should approximate to 2/3
        let price = Price.fromString(price: "0.6666666666666666")
        XCTAssertEqual(price.n, 2)
        XCTAssertEqual(price.d, 3)
    }

    func testFromStringThreeAndTwoThirds() {
        // 3.666... should approximate to 11/3
        let price = Price.fromString(price: "3.6666666666666666666666666666666")
        XCTAssertEqual(price.n, 11)
        XCTAssertEqual(price.d, 3)
    }

    func testFromStringPi() {
        // Pi should approximate reasonably
        let price = Price.fromString(price: "3.14159265358979")
        // Check the approximation is reasonable (355/113 is a famous approximation)
        let actualValue = Double(price.n) / Double(price.d)
        XCTAssertEqual(actualValue, 3.14159265358979, accuracy: 0.0001)
    }

    func testFromStringHundred() {
        let price = Price.fromString(price: "100")
        XCTAssertEqual(price.n, 100)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringThousand() {
        let price = Price.fromString(price: "1000")
        XCTAssertEqual(price.n, 1000)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringTwo() {
        let price = Price.fromString(price: "2")
        XCTAssertEqual(price.n, 2)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringTwentyFiveHundredths() {
        let price = Price.fromString(price: "2.5")
        XCTAssertEqual(price.n, 5)
        XCTAssertEqual(price.d, 2)
    }

    // MARK: - testFromStringEdgeCases

    func testFromStringMaxInt32() {
        let price = Price.fromString(price: "2147483647")
        XCTAssertEqual(price.n, Int32.max)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringVerySmallDecimal() {
        let price = Price.fromString(price: "0.0000001")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 10000000)
    }

    func testFromStringVerySmallDecimalLimit() {
        // Test a decimal that approaches the Int32 limit for denominator
        let price = Price.fromString(price: "0.000000001")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 1000000000)
    }

    func testFromStringLargeWholeNumber() {
        let price = Price.fromString(price: "1000000")
        XCTAssertEqual(price.n, 1000000)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringLargeFraction() {
        // A large value that results in a manageable fraction
        let price = Price.fromString(price: "123456.789")
        let actualValue = Double(price.n) / Double(price.d)
        XCTAssertEqual(actualValue, 123456.789, accuracy: 0.001)
    }

    func testFromStringLeadingZeros() {
        let price = Price.fromString(price: "00001")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringTrailingZeros() {
        let price = Price.fromString(price: "1.00")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 1)
    }

    // MARK: - testFromStringInvalidInput

    func testFromStringEmptyString() {
        let price = Price.fromString(price: "")
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 0)
    }

    func testFromStringInvalidText() {
        let price = Price.fromString(price: "abc")
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 0)
    }

    func testFromStringInvalidMixedText() {
        // Note: Decimal(string:) parses "12abc34" as 12 (takes leading numeric portion)
        let price = Price.fromString(price: "12abc34")
        XCTAssertEqual(price.n, 12)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringSpecialCharacters() {
        let price = Price.fromString(price: "!@#$%")
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 0)
    }

    func testFromStringMultipleDecimals() {
        // Note: Decimal(string:) parses "1.2.3" as 1.2 (ignores second decimal point)
        let price = Price.fromString(price: "1.2.3")
        XCTAssertEqual(price.n, 6)
        XCTAssertEqual(price.d, 5)
    }

    func testFromStringWhitespace() {
        // Note: Decimal(string:) parses "   " as 0 (whitespace-only strings parse as zero)
        let price = Price.fromString(price: "   ")
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 1)
    }

    // MARK: - testConstructorBasic

    func testConstructorBasicValues() {
        let price = Price(numerator: 5, denominator: 10)
        XCTAssertEqual(price.n, 5)
        XCTAssertEqual(price.d, 10)
    }

    func testConstructorOneOne() {
        let price = Price(numerator: 1, denominator: 1)
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 1)
    }

    func testConstructorZeroNumerator() {
        let price = Price(numerator: 0, denominator: 1)
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 1)
    }

    func testConstructorLargeValues() {
        let price = Price(numerator: 1000000, denominator: 3)
        XCTAssertEqual(price.n, 1000000)
        XCTAssertEqual(price.d, 3)
    }

    // MARK: - testConstructorEdgeCases

    func testConstructorZeroDenominator() {
        // Constructor allows zero denominator (no validation)
        let price = Price(numerator: 1, denominator: 0)
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 0)
    }

    func testConstructorNegativeNumerator() {
        let price = Price(numerator: -5, denominator: 10)
        XCTAssertEqual(price.n, -5)
        XCTAssertEqual(price.d, 10)
    }

    func testConstructorNegativeDenominator() {
        let price = Price(numerator: 5, denominator: -10)
        XCTAssertEqual(price.n, 5)
        XCTAssertEqual(price.d, -10)
    }

    func testConstructorBothNegative() {
        let price = Price(numerator: -5, denominator: -10)
        XCTAssertEqual(price.n, -5)
        XCTAssertEqual(price.d, -10)
    }

    func testConstructorMaxInt32Numerator() {
        let price = Price(numerator: Int32.max, denominator: 1)
        XCTAssertEqual(price.n, Int32.max)
        XCTAssertEqual(price.d, 1)
    }

    func testConstructorMaxInt32Denominator() {
        let price = Price(numerator: 1, denominator: Int32.max)
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, Int32.max)
    }

    func testConstructorMinInt32Values() {
        let price = Price(numerator: Int32.min, denominator: Int32.min)
        XCTAssertEqual(price.n, Int32.min)
        XCTAssertEqual(price.d, Int32.min)
    }

    func testConstructorBothZero() {
        let price = Price(numerator: 0, denominator: 0)
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 0)
    }

    // MARK: - testEqualityOperator

    func testEqualityReflexivity() {
        let price = Price(numerator: 5, denominator: 10)
        XCTAssertEqual(price, price)
    }

    func testEqualitySymmetry() {
        let price1 = Price(numerator: 5, denominator: 10)
        let price2 = Price(numerator: 5, denominator: 10)
        XCTAssertEqual(price1, price2)
        XCTAssertEqual(price2, price1)
    }

    func testEqualityDifferentNumerator() {
        let price1 = Price(numerator: 5, denominator: 10)
        let price2 = Price(numerator: 6, denominator: 10)
        XCTAssertNotEqual(price1, price2)
    }

    func testEqualityDifferentDenominator() {
        let price1 = Price(numerator: 5, denominator: 10)
        let price2 = Price(numerator: 5, denominator: 11)
        XCTAssertNotEqual(price1, price2)
    }

    func testEqualityBothDifferent() {
        let price1 = Price(numerator: 5, denominator: 10)
        let price2 = Price(numerator: 6, denominator: 11)
        XCTAssertNotEqual(price1, price2)
    }

    func testEqualityEquivalentFractionsNotEqual() {
        // Note: Price equality is based on raw values, not mathematical equivalence
        // 1/2 and 2/4 are mathematically equal but not equal as Price objects
        let price1 = Price(numerator: 1, denominator: 2)
        let price2 = Price(numerator: 2, denominator: 4)
        XCTAssertNotEqual(price1, price2)
    }

    func testEqualityZeroValues() {
        let price1 = Price(numerator: 0, denominator: 1)
        let price2 = Price(numerator: 0, denominator: 1)
        XCTAssertEqual(price1, price2)
    }

    func testEqualityNegativeValues() {
        let price1 = Price(numerator: -5, denominator: 10)
        let price2 = Price(numerator: -5, denominator: 10)
        XCTAssertEqual(price1, price2)
    }

    // MARK: - testToXdrConversion

    func testToXdrBasic() {
        let price = Price(numerator: 5, denominator: 10)
        let xdr = price.toXdr()
        XCTAssertEqual(xdr.n, 5)
        XCTAssertEqual(xdr.d, 10)
    }

    func testToXdrZeroNumerator() {
        let price = Price(numerator: 0, denominator: 1)
        let xdr = price.toXdr()
        XCTAssertEqual(xdr.n, 0)
        XCTAssertEqual(xdr.d, 1)
    }

    func testToXdrMaxValues() {
        let price = Price(numerator: Int32.max, denominator: Int32.max)
        let xdr = price.toXdr()
        XCTAssertEqual(xdr.n, Int32.max)
        XCTAssertEqual(xdr.d, Int32.max)
    }

    func testToXdrNegativeValues() {
        let price = Price(numerator: -5, denominator: -10)
        let xdr = price.toXdr()
        XCTAssertEqual(xdr.n, -5)
        XCTAssertEqual(xdr.d, -10)
    }

    func testToXdrFromString() {
        let price = Price.fromString(price: "0.5")
        let xdr = price.toXdr()
        XCTAssertEqual(xdr.n, 1)
        XCTAssertEqual(xdr.d, 2)
    }

    // MARK: - testXDREncodingDecoding

    func testPriceXDREncodingDecoding() throws {
        let original = PriceXDR(n: 5, d: 10)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        XCTAssertEqual(decoded.n, original.n)
        XCTAssertEqual(decoded.d, original.d)
    }

    func testPriceXDREncodingDecodingZero() throws {
        let original = PriceXDR(n: 0, d: 1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        XCTAssertEqual(decoded.n, 0)
        XCTAssertEqual(decoded.d, 1)
    }

    func testPriceXDREncodingDecodingMaxValues() throws {
        let original = PriceXDR(n: Int32.max, d: Int32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        XCTAssertEqual(decoded.n, Int32.max)
        XCTAssertEqual(decoded.d, Int32.max)
    }

    func testPriceXDREncodingDecodingNegative() throws {
        let original = PriceXDR(n: -100, d: -200)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        XCTAssertEqual(decoded.n, -100)
        XCTAssertEqual(decoded.d, -200)
    }

    func testPriceToXdrRoundTrip() throws {
        let price = Price(numerator: 123, denominator: 456)
        let xdr = price.toXdr()
        let encoded = try XDREncoder.encode(xdr)
        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        XCTAssertEqual(decoded.n, price.n)
        XCTAssertEqual(decoded.d, price.d)
    }

    // MARK: - testJSONDecoding

    func testJSONDecodingBasic() throws {
        let json = """
        {"n": 5, "d": 10}
        """
        let data = json.data(using: .utf8)!
        let price = try JSONDecoder().decode(Price.self, from: data)
        XCTAssertEqual(price.n, 5)
        XCTAssertEqual(price.d, 10)
    }

    func testJSONDecodingZero() throws {
        let json = """
        {"n": 0, "d": 1}
        """
        let data = json.data(using: .utf8)!
        let price = try JSONDecoder().decode(Price.self, from: data)
        XCTAssertEqual(price.n, 0)
        XCTAssertEqual(price.d, 1)
    }

    func testJSONDecodingMaxValues() throws {
        let json = """
        {"n": 2147483647, "d": 2147483647}
        """
        let data = json.data(using: .utf8)!
        let price = try JSONDecoder().decode(Price.self, from: data)
        XCTAssertEqual(price.n, Int32.max)
        XCTAssertEqual(price.d, Int32.max)
    }

    func testJSONDecodingNegative() throws {
        let json = """
        {"n": -100, "d": -200}
        """
        let data = json.data(using: .utf8)!
        let price = try JSONDecoder().decode(Price.self, from: data)
        XCTAssertEqual(price.n, -100)
        XCTAssertEqual(price.d, -200)
    }

    func testJSONDecodingMinValues() throws {
        let json = """
        {"n": -2147483648, "d": -2147483648}
        """
        let data = json.data(using: .utf8)!
        let price = try JSONDecoder().decode(Price.self, from: data)
        XCTAssertEqual(price.n, Int32.min)
        XCTAssertEqual(price.d, Int32.min)
    }

    func testJSONDecodingMissingField() {
        let json = """
        {"n": 5}
        """
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Price.self, from: data))
    }

    func testJSONDecodingInvalidType() {
        let json = """
        {"n": "five", "d": 10}
        """
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Price.self, from: data))
    }

    // MARK: - testPropertiesAccess

    func testPropertiesAccessNumerator() {
        let price = Price(numerator: 7, denominator: 13)
        XCTAssertEqual(price.n, 7)
    }

    func testPropertiesAccessDenominator() {
        let price = Price(numerator: 7, denominator: 13)
        XCTAssertEqual(price.d, 13)
    }

    func testPropertiesAccessFromString() {
        let price = Price.fromString(price: "0.125")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 8)
    }

    func testPropertiesImmutable() {
        let price = Price(numerator: 5, denominator: 10)
        // Properties n and d are declared as 'let', so they are immutable
        // This test verifies the values remain unchanged after access
        let _ = price.n
        let _ = price.d
        XCTAssertEqual(price.n, 5)
        XCTAssertEqual(price.d, 10)
    }

    // MARK: - testPriceXDRDirect

    func testPriceXDRDirectConstruction() {
        let xdr = PriceXDR(n: 100, d: 200)
        XCTAssertEqual(xdr.n, 100)
        XCTAssertEqual(xdr.d, 200)
    }

    func testPriceXDRPropertiesAccess() {
        let xdr = PriceXDR(n: 42, d: 84)
        XCTAssertEqual(xdr.n, 42)
        XCTAssertEqual(xdr.d, 84)
    }

    // MARK: - Additional fromString Precision Tests

    func testFromStringEighth() {
        let price = Price.fromString(price: "0.125")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 8)
    }

    func testFromStringSixteenth() {
        let price = Price.fromString(price: "0.0625")
        XCTAssertEqual(price.n, 1)
        XCTAssertEqual(price.d, 16)
    }

    func testFromStringSevenEighths() {
        let price = Price.fromString(price: "0.875")
        XCTAssertEqual(price.n, 7)
        XCTAssertEqual(price.d, 8)
    }

    func testFromStringNinetyNine() {
        let price = Price.fromString(price: "99")
        XCTAssertEqual(price.n, 99)
        XCTAssertEqual(price.d, 1)
    }

    func testFromStringNinetyNinePointNine() {
        let price = Price.fromString(price: "99.9")
        XCTAssertEqual(price.n, 999)
        XCTAssertEqual(price.d, 10)
    }
}
