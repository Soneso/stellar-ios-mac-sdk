//
//  SCValXDRBigIntUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class SCValXDRBigIntUnitTests: XCTestCase {
    
    // MARK: - U128 Tests
    
    func testU128FromStringPositive() throws {
        // Test small positive number
        let val1 = try SCValXDR.u128(stringValue: "12345")
        XCTAssertEqual(val1.u128String, "12345")
        
        // Test maximum u128 value: 2^128 - 1
        let maxU128 = "340282366920938463463374607431768211455"
        let val2 = try SCValXDR.u128(stringValue: maxU128)
        XCTAssertEqual(val2.u128String, maxU128)
        
        // Test zero
        let val3 = try SCValXDR.u128(stringValue: "0")
        XCTAssertEqual(val3.u128String, "0")
        
        // Test large number
        let largeNum = "170141183460469231731687303715884105727"
        let val4 = try SCValXDR.u128(stringValue: largeNum)
        XCTAssertEqual(val4.u128String, largeNum)
    }
    
    func testU128FromData() throws {
        // Test with small value
        let data1 = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x39]) // 12345
        let val1 = try SCValXDR.u128(data: data1)
        XCTAssertEqual(val1.u128String, "12345")
        
        // Test with max value (all FF)
        let dataMax = Data(repeating: 0xFF, count: 16)
        let valMax = try SCValXDR.u128(data: dataMax)
        XCTAssertEqual(valMax.u128String, "340282366920938463463374607431768211455")
    }
    
    // MARK: - I128 Tests
    
    func testI128FromStringPositiveAndNegative() throws {
        // Test positive number
        let val1 = try SCValXDR.i128(stringValue: "12345")
        XCTAssertEqual(val1.i128String, "12345")
        
        // Test negative number
        let val2 = try SCValXDR.i128(stringValue: "-12345")
        XCTAssertEqual(val2.i128String, "-12345")
        
        // Test maximum i128 value: 2^127 - 1
        let maxI128 = "170141183460469231731687303715884105727"
        let val3 = try SCValXDR.i128(stringValue: maxI128)
        XCTAssertEqual(val3.i128String, maxI128)
        
        // Test minimum i128 value: -2^127
        let minI128 = "-170141183460469231731687303715884105728"
        let val4 = try SCValXDR.i128(stringValue: minI128)
        XCTAssertEqual(val4.i128String, minI128)
        
        // Test zero
        let val5 = try SCValXDR.i128(stringValue: "0")
        XCTAssertEqual(val5.i128String, "0")
        
        // Test -1
        let val6 = try SCValXDR.i128(stringValue: "-1")
        XCTAssertEqual(val6.i128String, "-1")
    }
    
    func testI128FromData() throws {
        // Test positive value
        let data1 = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x39]) // 12345
        let val1 = try SCValXDR.i128(data: data1)
        XCTAssertEqual(val1.i128String, "12345")
        
        // Test -1 (all FF in two's complement)
        let dataNeg1 = Data(repeating: 0xFF, count: 16)
        let valNeg1 = try SCValXDR.i128(data: dataNeg1)
        XCTAssertEqual(valNeg1.i128String, "-1")
    }
    
    // MARK: - U256 Tests
    
    func testU256FromStringPositive() throws {
        // Test small positive number
        let val1 = try SCValXDR.u256(stringValue: "12345")
        XCTAssertEqual(val1.u256String, "12345")
        
        // Test maximum u256 value: 2^256 - 1
        let maxU256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        let val2 = try SCValXDR.u256(stringValue: maxU256)
        XCTAssertEqual(val2.u256String, maxU256)
        
        // Test zero
        let val3 = try SCValXDR.u256(stringValue: "0")
        XCTAssertEqual(val3.u256String, "0")
        
        // Test large number
        let largeNum = "57896044618658097711785492504343953926634992332820282019728792003956564819967"
        let val4 = try SCValXDR.u256(stringValue: largeNum)
        XCTAssertEqual(val4.u256String, largeNum)
    }
    
    func testU256FromData() throws {
        // Test with small value
        let data1 = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x39]) // 12345
        let val1 = try SCValXDR.u256(data: data1)
        XCTAssertEqual(val1.u256String, "12345")
        
        // Test with max value (all FF)
        let dataMax = Data(repeating: 0xFF, count: 32)
        let valMax = try SCValXDR.u256(data: dataMax)
        XCTAssertEqual(valMax.u256String, "115792089237316195423570985008687907853269984665640564039457584007913129639935")
    }
    
    // MARK: - I256 Tests
    
    func testI256FromStringPositiveAndNegative() throws {
        // Test positive number
        let val1 = try SCValXDR.i256(stringValue: "12345")
        XCTAssertEqual(val1.i256String, "12345")
        
        // Test negative number
        let val2 = try SCValXDR.i256(stringValue: "-12345")
        XCTAssertEqual(val2.i256String, "-12345")
        
        // Test maximum i256 value: 2^255 - 1
        let maxI256 = "57896044618658097711785492504343953926634992332820282019728792003956564819967"
        let val3 = try SCValXDR.i256(stringValue: maxI256)
        XCTAssertEqual(val3.i256String, maxI256)
        
        // Test minimum i256 value: -2^255
        let minI256 = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
        let val4 = try SCValXDR.i256(stringValue: minI256)
        XCTAssertEqual(val4.i256String, minI256)
        
        // Test zero
        let val5 = try SCValXDR.i256(stringValue: "0")
        XCTAssertEqual(val5.i256String, "0")
        
        // Test -1
        let val6 = try SCValXDR.i256(stringValue: "-1")
        XCTAssertEqual(val6.i256String, "-1")
    }
    
    func testI256FromData() throws {
        // Test positive value
        let data1 = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x39]) // 12345
        let val1 = try SCValXDR.i256(data: data1)
        XCTAssertEqual(val1.i256String, "12345")
        
        // Test -1 (all FF in two's complement)
        let dataNeg1 = Data(repeating: 0xFF, count: 32)
        let valNeg1 = try SCValXDR.i256(data: dataNeg1)
        XCTAssertEqual(valNeg1.i256String, "-1")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidStringInput() {
        // Test invalid characters
        XCTAssertThrowsError(try SCValXDR.u128(stringValue: "12a45"))
        XCTAssertThrowsError(try SCValXDR.i128(stringValue: "hello"))
        XCTAssertThrowsError(try SCValXDR.u256(stringValue: "123.45"))
        XCTAssertThrowsError(try SCValXDR.i256(stringValue: "--123"))
        
        // Test empty string
        XCTAssertThrowsError(try SCValXDR.u128(stringValue: ""))
        XCTAssertThrowsError(try SCValXDR.i128(stringValue: " "))
    }
    
    func testDataTooLarge() {
        // Test data too large for u128
        let largeData17 = Data(repeating: 0xFF, count: 17)
        XCTAssertThrowsError(try SCValXDR.u128(data: largeData17))
        XCTAssertThrowsError(try SCValXDR.i128(data: largeData17))
        
        // Test data too large for u256
        let largeData33 = Data(repeating: 0xFF, count: 33)
        XCTAssertThrowsError(try SCValXDR.u256(data: largeData33))
        XCTAssertThrowsError(try SCValXDR.i256(data: largeData33))
    }
    
    // MARK: - Roundtrip Tests
    
    func testRoundtripConversion() throws {
        // Test various values for roundtrip conversion
        let testValues = [
            "0",
            "1",
            "12345",
            "999999999999999999999999999999",
            "340282366920938463463374607431768211455", // max u128
            "170141183460469231731687303715884105727", // max i128
        ]
        
        for value in testValues {
            // Test u128 roundtrip
            let u128Val = try SCValXDR.u128(stringValue: value)
            XCTAssertEqual(u128Val.u128String, value)
            
            // Test u256 roundtrip
            let u256Val = try SCValXDR.u256(stringValue: value)
            XCTAssertEqual(u256Val.u256String, value)
        }
        
        // Test negative values for signed types
        let negativeValues = [
            "-1",
            "-12345",
            "-999999999999999999999999999999",
            "-170141183460469231731687303715884105728", // min i128
        ]
        
        for value in negativeValues {
            // Test i128 roundtrip
            let i128Val = try SCValXDR.i128(stringValue: value)
            XCTAssertEqual(i128Val.i128String, value)
            
            // Test i256 roundtrip
            let i256Val = try SCValXDR.i256(stringValue: value)
            XCTAssertEqual(i256Val.i256String, value)
        }
    }
    
    // MARK: - XDR Encoding/Decoding Tests
    
    func testXDREncodingDecoding() throws {
        // Test u128 XDR encoding/decoding
        let u128Val = try SCValXDR.u128(stringValue: "12345")
        XCTAssertNotNil(u128Val.xdrEncoded)
        let u128Decoded = try SCValXDR.fromXdr(base64: u128Val.xdrEncoded!)
        XCTAssertEqual(u128Decoded.u128String, "12345")
        
        // Test i128 XDR encoding/decoding
        let i128Val = try SCValXDR.i128(stringValue: "-12345")
        XCTAssertNotNil(i128Val.xdrEncoded)
        let i128Decoded = try SCValXDR.fromXdr(base64: i128Val.xdrEncoded!)
        XCTAssertEqual(i128Decoded.i128String, "-12345")
        
        // Test u256 XDR encoding/decoding
        let u256Val = try SCValXDR.u256(stringValue: "999999999999999999999999999999")
        XCTAssertNotNil(u256Val.xdrEncoded)
        let u256Decoded = try SCValXDR.fromXdr(base64: u256Val.xdrEncoded!)
        XCTAssertEqual(u256Decoded.u256String, "999999999999999999999999999999")
        
        // Test i256 XDR encoding/decoding
        let i256Val = try SCValXDR.i256(stringValue: "-999999999999999999999999999999")
        XCTAssertNotNil(i256Val.xdrEncoded)
        let i256Decoded = try SCValXDR.fromXdr(base64: i256Val.xdrEncoded!)
        XCTAssertEqual(i256Decoded.i256String, "-999999999999999999999999999999")
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases() throws {
        // Test with leading zeros in string
        let val1 = try SCValXDR.u128(stringValue: "00012345")
        XCTAssertEqual(val1.u128String, "12345")
        
        // Test small data (less than full size)
        let smallData = Data([0x30, 0x39]) // 12345
        let val2 = try SCValXDR.u128(data: smallData)
        XCTAssertEqual(val2.u128String, "12345")
        
        // Test single byte
        let singleByte = Data([0xFF])
        let val3 = try SCValXDR.u128(data: singleByte)
        XCTAssertEqual(val3.u128String, "255")
        
        let val4 = try SCValXDR.i128(data: singleByte)
        XCTAssertEqual(val4.i128String, "-1") // 0xFF is -1 in signed interpretation
    }
    
    // MARK: - Parts Verification Tests
    
    func testPartsConversion() throws {
        // Test that parts are correctly split for u128
        let val1 = try SCValXDR.u128(stringValue: "340282366920938463463374607431768211455")
        if case .u128(let parts) = val1 {
            XCTAssertEqual(parts.hi, UInt64.max)
            XCTAssertEqual(parts.lo, UInt64.max)
        } else {
            XCTFail("Expected u128 type")
        }
        
        // Test that parts are correctly split for i128 with -1
        let val2 = try SCValXDR.i128(stringValue: "-1")
        if case .i128(let parts) = val2 {
            XCTAssertEqual(parts.hi, -1)
            XCTAssertEqual(parts.lo, UInt64.max)
        } else {
            XCTFail("Expected i128 type")
        }
        
        // Test u256 parts
        let val3 = try SCValXDR.u256(stringValue: "115792089237316195423570985008687907853269984665640564039457584007913129639935")
        if case .u256(let parts) = val3 {
            XCTAssertEqual(parts.hiHi, UInt64.max)
            XCTAssertEqual(parts.hiLo, UInt64.max)
            XCTAssertEqual(parts.loHi, UInt64.max)
            XCTAssertEqual(parts.loLo, UInt64.max)
        } else {
            XCTFail("Expected u256 type")
        }
        
        // Test i256 parts with -1
        let val4 = try SCValXDR.i256(stringValue: "-1")
        if case .i256(let parts) = val4 {
            XCTAssertEqual(parts.hiHi, -1)
            XCTAssertEqual(parts.hiLo, UInt64.max)
            XCTAssertEqual(parts.loHi, UInt64.max)
            XCTAssertEqual(parts.loLo, UInt64.max)
        } else {
            XCTFail("Expected i256 type")
        }
    }
}
