//
//  BigIntTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 2025-10-05.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class BigIntTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - BInt Data Conversion Round-Trip Tests

    func testBIntDataRoundTripSingleByte() {
        let originalData = Data([0x42])
        let bint = BInt(data: originalData)
        let convertedData = bint.data

        // The data should match semantically (though padding may differ)
        let reconverted = BInt(data: convertedData)
        XCTAssertEqual(bint, reconverted, "Round-trip conversion should preserve value")
        XCTAssertEqual(BInt(0x42), bint, "Value should be 0x42")
    }

    func testBIntDataRoundTrip8Bytes() {
        let originalData = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        let bint = BInt(data: originalData)
        let convertedData = bint.data

        let reconverted = BInt(data: convertedData)
        XCTAssertEqual(bint, reconverted, "Round-trip conversion should preserve value for 8 bytes")
    }

    func testBIntDataRoundTrip32Bytes() {
        // 32 bytes - typical for crypto keys
        var bytes: [UInt8] = []
        for _ in 0..<32 {
            bytes.append(UInt8(bytes.count))
        }
        let originalData = Data(bytes)
        let bint = BInt(data: originalData)
        let convertedData = bint.data

        let reconverted = BInt(data: convertedData)
        XCTAssertEqual(bint, reconverted, "Round-trip conversion should preserve value for 32 bytes")
    }

    func testBIntDataRoundTrip64Bytes() {
        // 64 bytes - large crypto value
        var bytes: [UInt8] = []
        for _ in 0..<64 {
            bytes.append(UInt8((bytes.count * 3 + 7) % 256))
        }
        let originalData = Data(bytes)
        let bint = BInt(data: originalData)
        let convertedData = bint.data

        let reconverted = BInt(data: convertedData)
        XCTAssertEqual(bint, reconverted, "Round-trip conversion should preserve value for 64 bytes")
    }

    func testBIntDataRoundTripWithLeadingZeros() {
        // Test data with leading zeros
        let originalData = Data([0x00, 0x00, 0x01, 0x23])
        let bint = BInt(data: originalData)
        let convertedData = bint.data

        let reconverted = BInt(data: convertedData)
        XCTAssertEqual(bint, reconverted, "Round-trip should work with leading zeros")
        XCTAssertEqual(BInt(0x0123), bint, "Value should be 0x0123")
    }

    // MARK: - BInt Edge Cases

    func testBIntZeroValue() {
        let zero = BInt(0)
        XCTAssertEqual(zero, BInt(0), "Zero should equal zero")

        let zeroData = zero.data
        XCTAssertGreaterThan(zeroData.count, 0, "Zero should produce non-empty data")

        let reconverted = BInt(data: zeroData)
        XCTAssertEqual(zero, reconverted, "Zero should round-trip correctly")
    }

    func testBIntEmptyData() {
        let emptyData = Data()
        let bint = BInt(data: emptyData)
        XCTAssertEqual(bint, BInt(0), "Empty data should produce zero")
    }

    func testBIntSingleByteValues() {
        // Test various single byte values
        let testValues: [UInt8] = [0x00, 0x01, 0x0F, 0x10, 0x7F, 0x80, 0xFF]

        for value in testValues {
            let data = Data([value])
            let bint = BInt(data: data)
            let reconverted = BInt(data: bint.data)
            XCTAssertEqual(bint, reconverted, "Single byte value 0x\(String(value, radix: 16)) should round-trip")
        }
    }

    func testBIntLarge256BitNumber() {
        // Create a 256-bit number (32 bytes)
        var bytes: [UInt8] = []
        for _ in 0..<32 {
            bytes.append(0xFF)
        }
        let maxData = Data(bytes)
        let bint = BInt(data: maxData)
        let reconverted = BInt(data: bint.data)

        XCTAssertEqual(bint, reconverted, "256-bit number should round-trip correctly")
        XCTAssertNotEqual(bint, BInt(0), "256-bit max should not be zero")
    }

    // MARK: - DataConvertable Operator Tests

    func testDataPlusUInt8() {
        var data = Data()
        data += UInt8(0x42)
        XCTAssertEqual(data.count, 1, "Should add 1 byte")
        XCTAssertEqual(data[0], 0x42, "Byte value should be 0x42")
    }

    func testDataPlusUInt32BigEndian() {
        var data = Data()
        data += UInt32(0x12345678)
        XCTAssertEqual(data.count, 4, "Should add 4 bytes")

        // UInt32 should be stored in the platform's native byte order
        var value: UInt32 = 0x12345678
        let expected = withUnsafeBytes(of: &value) { Data($0) }
        XCTAssertEqual(data, expected, "UInt32 should be stored correctly")
    }

    func testDataPlusOperatorChaining() {
        var data = Data()
        data += UInt8(0x00)
        data += UInt32(123)

        XCTAssertEqual(data.count, 5, "Should have 5 bytes total (1 + 4)")
        XCTAssertEqual(data[0], 0x00, "First byte should be 0")
    }

    func testDataPlusOperatorChainingInline() {
        let index: UInt32 = 42
        var data = Data()
        data += UInt8(0)
        data += index

        XCTAssertEqual(data.count, 5, "Should have 5 bytes (1 + 4)")
        XCTAssertEqual(data[0], 0, "First byte should be 0")
    }

    func testDataPlusAssignmentOperator() {
        var data = Data([0x01, 0x02])
        data += UInt8(0x03)

        XCTAssertEqual(data.count, 3, "Should have 3 bytes")
        XCTAssertEqual(data[0], 0x01, "First byte unchanged")
        XCTAssertEqual(data[1], 0x02, "Second byte unchanged")
        XCTAssertEqual(data[2], 0x03, "Third byte added")
    }

    // MARK: - BInt Hashable Conformance Tests

    func testBIntHashableEqualValues() {
        let bint1 = BInt(12345)
        let bint2 = BInt(12345)

        XCTAssertEqual(bint1, bint2, "Equal BInts should be equal")
        XCTAssertEqual(bint1.hashValue, bint2.hashValue, "Equal BInts should have same hash")
    }

    func testBIntHashableDifferentValues() {
        let bint1 = BInt(12345)
        let bint2 = BInt(54321)

        XCTAssertNotEqual(bint1, bint2, "Different BInts should not be equal")
        // Note: Different values may theoretically have same hash (collision)
        // but it's extremely unlikely for these specific values
    }

    func testBIntInSet() {
        let bint1 = BInt(100)
        let bint2 = BInt(200)
        let bint3 = BInt(100) // Same as bint1

        var set = Set<BInt>()
        set.insert(bint1)
        set.insert(bint2)
        set.insert(bint3)

        XCTAssertEqual(set.count, 2, "Set should contain only 2 unique values")
        XCTAssertTrue(set.contains(bint1), "Set should contain first value")
        XCTAssertTrue(set.contains(bint2), "Set should contain second value")
        XCTAssertTrue(set.contains(bint3), "Set should contain duplicate value")
    }

    func testBIntHashConsistency() {
        guard let bint = BInt(hex: "FEDCBA9876543210") else {
            XCTFail("Failed to create BInt from hex")
            return
        }
        let hash1 = bint.hashValue
        let hash2 = bint.hashValue

        XCTAssertEqual(hash1, hash2, "Hash value should be consistent across calls")
    }

    func testBIntHashFromData() {
        let data1 = Data([0x12, 0x34, 0x56, 0x78])
        let data2 = Data([0x12, 0x34, 0x56, 0x78])

        let bint1 = BInt(data: data1)
        let bint2 = BInt(data: data2)

        XCTAssertEqual(bint1.hashValue, bint2.hashValue, "BInts from same data should have same hash")
    }

    func testBIntZeroHash() {
        let zero1 = BInt(0)
        let zero2 = BInt(data: Data())

        XCTAssertEqual(zero1, zero2, "Both zeros should be equal")
        XCTAssertEqual(zero1.hashValue, zero2.hashValue, "Zeros should have same hash")
    }

    // MARK: - Integration Tests

    func testBIntDataConversionPreservesValue() {
        // Test that converting through Data maintains the numeric value
        guard let original = BInt(hex: "123456789ABCDEF0") else {
            XCTFail("Failed to create BInt from hex")
            return
        }
        let data = original.data
        let converted = BInt(data: data)

        XCTAssertEqual(original, converted, "Conversion through data should preserve value")
        XCTAssertEqual(original.hashValue, converted.hashValue, "Hash should be preserved")
    }

    func testBIntNegativeNumberEdgeCase() {
        // While our Data conversion is unsigned, test that negative BInts work
        let negative = BInt(-12345)
        let positive = BInt(12345)

        XCTAssertNotEqual(negative, positive, "Negative and positive should differ")
        XCTAssertNotEqual(negative.hashValue, positive.hashValue, "Different signs should have different hashes")
    }
}
