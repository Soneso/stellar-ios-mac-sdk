//
//  PriceXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PriceXDRUnitTests: XCTestCase {

    // MARK: - Basic PriceXDR Tests

    func testPriceXDREncodeDecode() throws {
        let price = PriceXDR(n: 1, d: 2)

        let encoded = try XDREncoder.encode(price)
        XCTAssertFalse(encoded.isEmpty)
        XCTAssertEqual(encoded.count, 8) // Two Int32 values = 8 bytes

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)

        XCTAssertEqual(decoded.n, 1)
        XCTAssertEqual(decoded.d, 2)
    }

    func testPriceXDRRoundTrip() throws {
        let price = PriceXDR(n: 100, d: 7)

        let encoded = try XDREncoder.encode(price)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.n, 100)
        XCTAssertEqual(decoded.d, 7)
    }

    func testPriceXDRFromBase64() throws {
        // Create a price and encode it to base64
        let originalPrice = PriceXDR(n: 500, d: 250)

        let encoded = try XDREncoder.encode(originalPrice)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.n, originalPrice.n)
        XCTAssertEqual(decoded.d, originalPrice.d)
    }

    // MARK: - Edge Case Tests

    func testPriceXDRWithMaxNumerator() throws {
        let price = PriceXDR(n: Int32.max, d: 1)

        let encoded = try XDREncoder.encode(price)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)

        XCTAssertEqual(decoded.n, Int32.max)
        XCTAssertEqual(decoded.d, 1)
    }

    func testPriceXDRWithMaxDenominator() throws {
        let price = PriceXDR(n: 1, d: Int32.max)

        let encoded = try XDREncoder.encode(price)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)

        XCTAssertEqual(decoded.n, 1)
        XCTAssertEqual(decoded.d, Int32.max)
    }

    func testPriceXDRWithMinValues() throws {
        let price = PriceXDR(n: 1, d: 1)

        let encoded = try XDREncoder.encode(price)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)

        XCTAssertEqual(decoded.n, 1)
        XCTAssertEqual(decoded.d, 1)
    }

    func testPriceXDRWithOneToOne() throws {
        // Test 1:1 ratio representing equal value
        let price = PriceXDR(n: 1, d: 1)

        let encoded = try XDREncoder.encode(price)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.n, 1)
        XCTAssertEqual(decoded.d, 1)

        // Verify ratio is 1.0
        let ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.0001)
    }

    // MARK: - Value Tests

    func testPriceXDREquality() throws {
        let price1 = PriceXDR(n: 10, d: 5)
        let price2 = PriceXDR(n: 10, d: 5)
        let price3 = PriceXDR(n: 20, d: 10) // Same ratio but different values

        // Encode and decode both prices
        let encoded1 = try XDREncoder.encode(price1)
        let encoded2 = try XDREncoder.encode(price2)
        let encoded3 = try XDREncoder.encode(price3)

        let decoded1 = try XDRDecoder.decode(PriceXDR.self, data: encoded1)
        let decoded2 = try XDRDecoder.decode(PriceXDR.self, data: encoded2)
        let decoded3 = try XDRDecoder.decode(PriceXDR.self, data: encoded3)

        // Same n and d values should be equal
        XCTAssertEqual(decoded1.n, decoded2.n)
        XCTAssertEqual(decoded1.d, decoded2.d)

        // Different n and d values (even with same ratio) should have different representations
        XCTAssertNotEqual(decoded1.n, decoded3.n)
        XCTAssertNotEqual(decoded1.d, decoded3.d)

        // But their ratios should be equal
        let ratio1 = Double(decoded1.n) / Double(decoded1.d)
        let ratio3 = Double(decoded3.n) / Double(decoded3.d)
        XCTAssertEqual(ratio1, ratio3, accuracy: 0.0001)
    }

    func testPriceXDRFromDecimalString() throws {
        // Test various decimal representations as price ratios
        // Price 0.5 = 1/2
        let priceHalf = PriceXDR(n: 1, d: 2)
        var encoded = try XDREncoder.encode(priceHalf)
        var decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        var ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 0.5, accuracy: 0.0001)

        // Price 0.25 = 1/4
        let priceQuarter = PriceXDR(n: 1, d: 4)
        encoded = try XDREncoder.encode(priceQuarter)
        decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 0.25, accuracy: 0.0001)

        // Price 2.5 = 5/2
        let priceTwoPointFive = PriceXDR(n: 5, d: 2)
        encoded = try XDREncoder.encode(priceTwoPointFive)
        decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 2.5, accuracy: 0.0001)

        // Price 0.001 = 1/1000
        let priceSmall = PriceXDR(n: 1, d: 1000)
        encoded = try XDREncoder.encode(priceSmall)
        decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 0.001, accuracy: 0.0001)

        // Price 100.0 = 100/1
        let priceLarge = PriceXDR(n: 100, d: 1)
        encoded = try XDREncoder.encode(priceLarge)
        decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)
        ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 100.0, accuracy: 0.0001)
    }

    // MARK: - Additional Edge Cases

    func testPriceXDRWithMaxBothValues() throws {
        // Test with max values for both numerator and denominator
        let price = PriceXDR(n: Int32.max, d: Int32.max)

        let encoded = try XDREncoder.encode(price)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(PriceXDR.self, data: encoded)

        XCTAssertEqual(decoded.n, Int32.max)
        XCTAssertEqual(decoded.d, Int32.max)

        // Ratio should be 1.0
        let ratio = Double(decoded.n) / Double(decoded.d)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.0001)
    }
}
