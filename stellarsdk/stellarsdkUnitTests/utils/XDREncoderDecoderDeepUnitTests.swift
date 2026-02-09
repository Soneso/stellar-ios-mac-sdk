//
//  XDREncoderDecoderDeepUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDREncoderDecoderDeepUnitTests: XCTestCase {

    // MARK: - XDREncoder Initialization Tests

    func testXDREncoderInitialization() {
        let encoder = XDREncoder()
        XCTAssertNotNil(encoder)
    }

    // MARK: - Bool Encoding/Decoding Tests

    func testEncodeBoolTrue() throws {
        let value: Bool = true
        let encoded = try XDREncoder.encode(value)
        XCTAssertFalse(encoded.isEmpty)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try decoder.decode(Bool.self)
        XCTAssertTrue(decoded)
    }

    func testEncodeBoolFalse() throws {
        let value: Bool = false
        let encoded = try XDREncoder.encode(value)
        XCTAssertFalse(encoded.isEmpty)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try decoder.decode(Bool.self)
        XCTAssertFalse(decoded)
    }

    func testDecodeBoolInvalidValue() throws {
        let invalidValue: UInt32 = 2
        let encoded = try XDREncoder.encode(invalidValue)

        let decoder = XDRDecoder(data: encoded)
        XCTAssertThrowsError(try decoder.decode(Bool.self)) { error in
            guard case XDRDecoder.Error.boolOutOfRange(let value) = error else {
                XCTFail("Expected boolOutOfRange error")
                return
            }
            XCTAssertEqual(value, 2)
        }
    }

    func testDecodeBoolLargeInvalidValue() throws {
        let invalidValue: UInt32 = 99
        let encoded = try XDREncoder.encode(invalidValue)

        let decoder = XDRDecoder(data: encoded)
        XCTAssertThrowsError(try decoder.decode(Bool.self)) { error in
            guard case XDRDecoder.Error.boolOutOfRange(let value) = error else {
                XCTFail("Expected boolOutOfRange error")
                return
            }
            XCTAssertEqual(value, 99)
        }
    }

    // MARK: - Float Encoding/Decoding Tests

    func testEncodeDecodeFloatWithStruct() throws {
        struct FloatContainer: XDRCodable {
            let value: Float

            init(value: Float) {
                self.value = value
            }

            func encode(to encoder: Encoder) throws {
                guard let xdrEncoder = encoder as? XDREncoder else {
                    throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: self))
                }
                xdrEncoder.encode(value)
            }

            init(from decoder: Decoder) throws {
                guard let xdrDecoder = decoder as? XDRDecoder else {
                    throw XDRDecoder.Error.typeNotConformingToDecodable(type(of: Self.self))
                }
                value = try xdrDecoder.decode(Float.self)
            }
        }

        let testValue: Float = 3.14159
        let container = FloatContainer(value: testValue)
        let encoded = try XDREncoder.encode(container)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try FloatContainer(fromBinary: decoder)
        XCTAssertEqual(decoded.value, testValue, accuracy: 0.00001)
    }

    func testEncodeDecodeFloatZero() throws {
        struct FloatContainer: XDRCodable {
            let value: Float

            init(value: Float) {
                self.value = value
            }

            func encode(to encoder: Encoder) throws {
                guard let xdrEncoder = encoder as? XDREncoder else {
                    throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: self))
                }
                xdrEncoder.encode(value)
            }

            init(from decoder: Decoder) throws {
                guard let xdrDecoder = decoder as? XDRDecoder else {
                    throw XDRDecoder.Error.typeNotConformingToDecodable(type(of: Self.self))
                }
                value = try xdrDecoder.decode(Float.self)
            }
        }

        let testValue: Float = 0.0
        let container = FloatContainer(value: testValue)
        let encoded = try XDREncoder.encode(container)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try FloatContainer(fromBinary: decoder)
        XCTAssertEqual(decoded.value, testValue)
    }

    func testEncodeDecodeFloatNegative() throws {
        struct FloatContainer: XDRCodable {
            let value: Float

            init(value: Float) {
                self.value = value
            }

            func encode(to encoder: Encoder) throws {
                guard let xdrEncoder = encoder as? XDREncoder else {
                    throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: self))
                }
                xdrEncoder.encode(value)
            }

            init(from decoder: Decoder) throws {
                guard let xdrDecoder = decoder as? XDRDecoder else {
                    throw XDRDecoder.Error.typeNotConformingToDecodable(type(of: Self.self))
                }
                value = try xdrDecoder.decode(Float.self)
            }
        }

        let testValue: Float = -123.456
        let container = FloatContainer(value: testValue)
        let encoded = try XDREncoder.encode(container)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try FloatContainer(fromBinary: decoder)
        XCTAssertEqual(decoded.value, testValue, accuracy: 0.001)
    }

    // MARK: - Double Encoding/Decoding Tests

    func testEncodeDecodeDouble() throws {
        struct DoubleContainer: XDRCodable {
            let value: Double

            init(value: Double) {
                self.value = value
            }

            func encode(to encoder: Encoder) throws {
                guard let xdrEncoder = encoder as? XDREncoder else {
                    throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: self))
                }
                xdrEncoder.encode(value)
            }

            init(from decoder: Decoder) throws {
                guard let xdrDecoder = decoder as? XDRDecoder else {
                    throw XDRDecoder.Error.typeNotConformingToDecodable(type(of: Self.self))
                }
                value = try xdrDecoder.decode(Double.self)
            }
        }

        let testValue: Double = 3.141592653589793
        let container = DoubleContainer(value: testValue)
        let encoded = try XDREncoder.encode(container)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try DoubleContainer(fromBinary: decoder)
        XCTAssertEqual(decoded.value, testValue, accuracy: 0.0000000001)
    }

    func testEncodeDecodeDoubleNegative() throws {
        struct DoubleContainer: XDRCodable {
            let value: Double

            init(value: Double) {
                self.value = value
            }

            func encode(to encoder: Encoder) throws {
                guard let xdrEncoder = encoder as? XDREncoder else {
                    throw XDREncoder.Error.typeNotConformingToXDREncodable(type(of: self))
                }
                xdrEncoder.encode(value)
            }

            init(from decoder: Decoder) throws {
                guard let xdrDecoder = decoder as? XDRDecoder else {
                    throw XDRDecoder.Error.typeNotConformingToDecodable(type(of: Self.self))
                }
                value = try xdrDecoder.decode(Double.self)
            }
        }

        let testValue: Double = -987654.321
        let container = DoubleContainer(value: testValue)
        let encoded = try XDREncoder.encode(container)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try DoubleContainer(fromBinary: decoder)
        XCTAssertEqual(decoded.value, testValue, accuracy: 0.0001)
    }

    // MARK: - Integer Encoding/Decoding Tests

    func testEncodeDecodeUInt8() throws {
        let testValue: UInt8 = 255
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt8(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeUInt8Zero() throws {
        let testValue: UInt8 = 0
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt8(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt32() throws {
        let testValue: Int32 = -123456
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Int32(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt32Max() throws {
        let testValue: Int32 = Int32.max
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Int32(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt32Min() throws {
        let testValue: Int32 = Int32.min
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Int32(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeUInt32() throws {
        let testValue: UInt32 = 987654321
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt32(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeUInt32Max() throws {
        let testValue: UInt32 = UInt32.max
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt32(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt64() throws {
        let testValue: Int64 = -9876543210
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Int64(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt64Max() throws {
        let testValue: Int64 = Int64.max
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Int64(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt64Min() throws {
        let testValue: Int64 = Int64.min
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Int64(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeUInt64() throws {
        let testValue: UInt64 = 1234567890123456789
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt64(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeUInt64Max() throws {
        let testValue: UInt64 = UInt64.max
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt64(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    // MARK: - String Encoding/Decoding Tests

    func testEncodeDecodeString() throws {
        let testValue = "Hello Stellar"
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try String(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeEmptyString() throws {
        let testValue = ""
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try String(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeStringWithSpecialCharacters() throws {
        let testValue = "Hello! @#$%^&*() 123"
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try String(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeStringWithUnicode() throws {
        let testValue = "Hello 世界 🌟"
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try String(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeStringLong() throws {
        let testValue = String(repeating: "A", count: 1000)
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try String(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeStringPadding() throws {
        let testValues = ["A", "AB", "ABC", "ABCD", "ABCDE"]

        for testValue in testValues {
            let encoded = try XDREncoder.encode(testValue)
            let decoder = XDRDecoder(data: encoded)
            let decoded = try String(fromBinary: decoder)
            XCTAssertEqual(decoded, testValue, "Failed for string: \(testValue)")
        }
    }

    // MARK: - Data Encoding/Decoding Tests

    func testEncodeDecodeData() throws {
        let testValue = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Data(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeDataEmpty() throws {
        let testValue = Data()
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Data(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeDataWithPadding() throws {
        let testValue = Data([0x01, 0x02, 0x03])
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Data(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeDataLarge() throws {
        let testValue = Data(count: 1024)
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try Data(fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    // MARK: - Array Encoding/Decoding Tests

    func testEncodeDecodeUInt32Array() throws {
        let testValue: [UInt32] = [1, 2, 3, 4, 5]
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try [UInt32](fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeEmptyArray() throws {
        let testValue: [UInt32] = []
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try [UInt32](fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeLargeArray() throws {
        let testValue: [UInt32] = Array(0..<100)
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try [UInt32](fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    func testEncodeDecodeInt64Array() throws {
        let testValue: [Int64] = [-100, -50, 0, 50, 100]
        let encoded = try XDREncoder.encode(testValue)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try [Int64](fromBinary: decoder)
        XCTAssertEqual(decoded, testValue)
    }

    // MARK: - Optional Encoding/Decoding Tests

    func testEncodeOptionalSome() throws {
        let testValue: UInt32? = 42
        let encoded = try XDREncoder.encode(testValue)

        XCTAssertGreaterThan(encoded.count, 4)
    }

    func testEncodeOptionalNone() throws {
        let testValue: UInt32? = nil
        let encoded = try XDREncoder.encode(testValue)

        XCTAssertEqual(encoded.count, 4)
    }

    // MARK: - Container Tests

    func testKeyedEncodingContainer() throws {
        let encoder = XDREncoder()
        let container = encoder.container(keyedBy: TestCodingKeys.self)
        XCTAssertNotNil(container)
    }

    func testUnkeyedEncodingContainer() throws {
        let encoder = XDREncoder()
        let container = encoder.unkeyedContainer()
        XCTAssertNotNil(container)
        XCTAssertEqual(container.count, 0)
    }

    func testSingleValueEncodingContainer() throws {
        let encoder = XDREncoder()
        let container = encoder.singleValueContainer()
        XCTAssertNotNil(container)
    }

    func testKeyedDecodingContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.container(keyedBy: TestCodingKeys.self)
        XCTAssertNotNil(container)
        XCTAssertTrue(container.allKeys.isEmpty)
        XCTAssertTrue(container.contains(.value))
    }

    func testUnkeyedDecodingContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.unkeyedContainer()
        XCTAssertNotNil(container)
        XCTAssertFalse(container.isAtEnd)
        XCTAssertEqual(container.currentIndex, 0)
    }

    func testSingleValueDecodingContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.singleValueContainer()
        XCTAssertNotNil(container)
    }

    func testNestedKeyedContainer() throws {
        let encoder = XDREncoder()
        var container = encoder.container(keyedBy: TestCodingKeys.self)
        let nested = container.nestedContainer(keyedBy: TestCodingKeys.self, forKey: .value)
        XCTAssertNotNil(nested)
    }

    func testNestedUnkeyedContainer() throws {
        let encoder = XDREncoder()
        var container = encoder.container(keyedBy: TestCodingKeys.self)
        let nested = container.nestedUnkeyedContainer(forKey: .value)
        XCTAssertNotNil(nested)
    }

    func testSuperEncoder() throws {
        let encoder = XDREncoder()
        var container = encoder.container(keyedBy: TestCodingKeys.self)
        let superEncoder = container.superEncoder()
        XCTAssertNotNil(superEncoder)
    }

    func testSuperEncoderForKey() throws {
        let encoder = XDREncoder()
        var container = encoder.container(keyedBy: TestCodingKeys.self)
        let superEncoder = container.superEncoder(forKey: .value)
        XCTAssertNotNil(superEncoder)
    }

    func testNestedDecodingContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.container(keyedBy: TestCodingKeys.self)
        let nested = try container.nestedContainer(keyedBy: TestCodingKeys.self, forKey: .value)
        XCTAssertNotNil(nested)
    }

    func testNestedUnkeyedDecodingContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.container(keyedBy: TestCodingKeys.self)
        let nested = try container.nestedUnkeyedContainer(forKey: .value)
        XCTAssertNotNil(nested)
    }

    func testSuperDecoder() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.container(keyedBy: TestCodingKeys.self)
        let superDecoder = try container.superDecoder()
        XCTAssertNotNil(superDecoder)
    }

    func testSuperDecoderForKey() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        let container = try decoder.container(keyedBy: TestCodingKeys.self)
        let superDecoder = try container.superDecoder(forKey: .value)
        XCTAssertNotNil(superDecoder)
    }

    func testDecodeNilFromKeyedContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 0])
        let container = try decoder.container(keyedBy: TestCodingKeys.self)
        let isNil = try container.decodeNil(forKey: .value)
        XCTAssertTrue(isNil)
    }

    func testDecodeNilFromUnkeyedContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 0])
        var container = try decoder.unkeyedContainer()
        let isNil = try container.decodeNil()
        XCTAssertTrue(isNil)
    }

    func testDecodeNilFromSingleValueContainer() throws {
        let decoder = XDRDecoder(data: [0, 0, 0, 0])
        let container = try decoder.singleValueContainer()
        let isNil = container.decodeNil()
        XCTAssertTrue(isNil)
    }

    // MARK: - Error Path Tests

    func testDecoderPrematureEndOfData() throws {
        let decoder = XDRDecoder(data: [0x01, 0x02])
        XCTAssertThrowsError(try decoder.decode(UInt32.self)) { error in
            guard case XDRDecoder.Error.prematureEndOfData = error else {
                XCTFail("Expected prematureEndOfData error")
                return
            }
        }
    }

    func testDecodeTypeNotConformingToXDRDecodable() throws {
        struct NotXDRDecodable: Decodable {}

        let decoder = XDRDecoder(data: [0, 0, 0, 1])
        XCTAssertThrowsError(try decoder.decode(NotXDRDecodable.self)) { error in
            guard case XDRDecoder.Error.typeNotConformingToXDRDecodable = error else {
                XCTFail("Expected typeNotConformingToXDRDecodable error")
                return
            }
        }
    }

    func testDecodeInvalidUTF8String() throws {
        let invalidUTF8: [UInt8] = [0x00, 0x00, 0x00, 0x02, 0xFF, 0xFE, 0x00, 0x00]
        let decoder = XDRDecoder(data: invalidUTF8)

        XCTAssertThrowsError(try String(fromBinary: decoder)) { error in
            guard case XDRDecoder.Error.invalidUTF8 = error else {
                XCTFail("Expected invalidUTF8 error, got \(error)")
                return
            }
        }
    }

    // MARK: - XDREncodable Extension Tests

    func testXDREncodedPropertySuccess() throws {
        let value: UInt32 = 12345
        guard let encoded = value.xdrEncoded else {
            XCTFail("Failed to encode value")
            return
        }

        XCTAssertFalse(encoded.isEmpty)

        guard let decodedData = Data(base64Encoded: encoded) else {
            XCTFail("Encoded value is not valid base64")
            return
        }

        XCTAssertFalse(decodedData.isEmpty)
    }

    // MARK: - XDRDecoder Initialization Tests

    func testXDRDecoderInitWithArray() {
        let data: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        let decoder = XDRDecoder(data: data)
        XCTAssertNotNil(decoder)
    }

    func testXDRDecoderInitWithData() {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        let decoder = XDRDecoder(data: data)
        XCTAssertNotNil(decoder)
    }

    func testXDRDecoderStaticDecodeWithArray() throws {
        let value: UInt32 = 42
        let encoded = try XDREncoder.encode(value)

        let decoded = try XDRDecoder.decode(UInt32.self, data: encoded)
        XCTAssertEqual(decoded, value)
    }

    func testXDRDecoderStaticDecodeWithData() throws {
        let value: UInt32 = 42
        let encoded = try XDREncoder.encode(value)

        let dataObj = Data(encoded)
        let decoded = try XDRDecoder.decode(UInt32.self, data: dataObj)
        XCTAssertEqual(decoded, value)
    }

    // MARK: - XDRDecodable Extension Tests

    func testXDRDecodableInitFromBinary() throws {
        let value: UInt32 = 777
        let encoded = try XDREncoder.encode(value)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt32(fromBinary: decoder)
        XCTAssertEqual(decoded, value)
    }

    func testXDRDecodableInitFromBinaryWithCount() throws {
        let value: UInt32 = 888
        let encoded = try XDREncoder.encode(value)

        let decoder = XDRDecoder(data: encoded)
        let decoded = try UInt32(fromBinary: decoder, count: 4)
        XCTAssertEqual(decoded, value)
    }

    func testXDRDecodableInitWithXDRString() throws {
        let value: UInt32 = 555
        let encoded = try XDREncoder.encode(value)

        let base64String = Data(encoded).base64EncodedString()
        let decoded = try UInt32(xdr: base64String)
        XCTAssertEqual(decoded, value)
    }

    // MARK: - Encoder Properties Tests

    func testEncoderCodingPath() {
        let encoder = XDREncoder()
        XCTAssertTrue(encoder.codingPath.isEmpty)
    }

    func testEncoderUserInfo() {
        let encoder = XDREncoder()
        XCTAssertTrue(encoder.userInfo.isEmpty)
    }

    func testDecoderCodingPath() {
        let decoder = XDRDecoder(data: [])
        XCTAssertTrue(decoder.codingPath.isEmpty)
    }

    func testDecoderUserInfo() {
        let decoder = XDRDecoder(data: [])
        XCTAssertTrue(decoder.userInfo.isEmpty)
    }

    // MARK: - Roundtrip Tests

    func testRoundtripMultipleValues() throws {
        struct MultiValue: XDRCodable {
            let v1: UInt32
            let v2: UInt32
            let v3: UInt32

            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(v1)
                try container.encode(v2)
                try container.encode(v3)
            }

            init(v1: UInt32, v2: UInt32, v3: UInt32) {
                self.v1 = v1
                self.v2 = v2
                self.v3 = v3
            }

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                v1 = try container.decode(UInt32.self)
                v2 = try container.decode(UInt32.self)
                v3 = try container.decode(UInt32.self)
            }
        }

        let original = MultiValue(v1: 1, v2: 2, v3: 3)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MultiValue.self, data: encoded)

        XCTAssertEqual(decoded.v1, 1)
        XCTAssertEqual(decoded.v2, 2)
        XCTAssertEqual(decoded.v3, 3)
    }

    func testRoundtripComplexStructure() throws {
        struct ComplexStruct: XDRCodable {
            let id: UInt32
            let name: String
            let values: [Int64]
            let flag: Bool

            init(id: UInt32, name: String, values: [Int64], flag: Bool) {
                self.id = id
                self.name = name
                self.values = values
                self.flag = flag
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(id)
                try container.encode(name)
                try container.encode(values)
                try container.encode(flag)
            }

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                id = try container.decode(UInt32.self)
                name = try container.decode(String.self)
                values = try container.decode([Int64].self)
                flag = try container.decode(Bool.self)
            }
        }

        let original = ComplexStruct(
            id: 12345,
            name: "Test",
            values: [100, 200, 300],
            flag: true
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ComplexStruct.self, data: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.values, original.values)
        XCTAssertEqual(decoded.flag, original.flag)
    }

    // MARK: - Encode Static Method Tests

    func testXDREncoderStaticEncode() throws {
        let value: UInt32 = 999
        let encoded = try XDREncoder.encode(value)

        XCTAssertFalse(encoded.isEmpty)
        XCTAssertEqual(encoded.count, 4)
    }

    // MARK: - Container Encode/Decode Tests

    func testKeyedContainerEncodeDecodeValue() throws {
        struct KeyedStruct: XDRCodable {
            let value: UInt32

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(value, forKey: .value)
            }

            init(value: UInt32) {
                self.value = value
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                value = try container.decode(UInt32.self, forKey: .value)
            }

            enum CodingKeys: String, CodingKey {
                case value
            }
        }

        let original = KeyedStruct(value: 777)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(KeyedStruct.self, data: encoded)

        XCTAssertEqual(decoded.value, original.value)
    }

    func testUnkeyedContainerNestedContainer() throws {
        let encoder = XDREncoder()
        var container = encoder.unkeyedContainer()
        let nested = container.nestedUnkeyedContainer()
        XCTAssertNotNil(nested)
    }

    // MARK: - Helper Types

    private enum TestCodingKeys: String, CodingKey {
        case value
    }
}
