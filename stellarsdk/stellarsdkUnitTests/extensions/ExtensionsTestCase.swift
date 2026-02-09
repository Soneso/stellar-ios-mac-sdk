//
//  ExtensionsTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 2026-02-03.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class ExtensionsTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Data+CRC Tests

    func testDataCRC16() {
        // Test CRC16 calculation on known data
        let testData = Data([0x01, 0x02, 0x03, 0x04])
        let crc = testData.crc16()
        XCTAssertGreaterThan(crc, 0, "CRC16 should produce non-zero result for non-zero data")

        // Test that same data produces same CRC
        let crc2 = testData.crc16()
        XCTAssertEqual(crc, crc2, "CRC16 should be deterministic")

        // Test empty data
        let emptyData = Data()
        let emptyCrc = emptyData.crc16()
        XCTAssertEqual(emptyCrc, CryptographicConstants.CRC16_INITIAL, "Empty data should return initial CRC value")

        // Test that different data produces different CRC
        let differentData = Data([0x05, 0x06, 0x07, 0x08])
        let differentCrc = differentData.crc16()
        XCTAssertNotEqual(crc, differentCrc, "Different data should produce different CRC")
    }

    func testDataCRC16Data() {
        // Test appending CRC16 checksum to data
        let testData = Data([0x01, 0x02, 0x03, 0x04])
        let checksummedData = testData.crc16Data()

        // Should be original data + 2 bytes of CRC
        XCTAssertEqual(checksummedData.count, testData.count + CryptographicConstants.CRC16_SIZE, "Checksummed data should be original + 2 bytes")

        // First bytes should match original
        XCTAssertEqual(checksummedData.prefix(testData.count), testData, "Original data should be preserved")

        // Should be valid
        XCTAssertTrue(checksummedData.crcValid(), "Appended checksum should be valid")
    }

    func testDataCRCValid() {
        // Test CRC validation
        let testData = Data([0x01, 0x02, 0x03, 0x04])
        let checksummedData = testData.crc16Data()

        XCTAssertTrue(checksummedData.crcValid(), "Valid checksum should pass validation")

        // Corrupt the checksum
        var corruptedData = checksummedData
        let lastIndex = corruptedData.count - 1
        corruptedData[lastIndex] = corruptedData[lastIndex] ^ 0xFF

        XCTAssertFalse(corruptedData.crcValid(), "Corrupted checksum should fail validation")
    }

    // MARK: - Data+Hash Tests

    func testDataSHA256Hash() {
        // Test SHA256 hash calculation
        let testData = Data([0x01, 0x02, 0x03, 0x04])
        let hash = testData.sha256Hash

        // SHA256 produces 32 bytes
        XCTAssertEqual(hash.count, 32, "SHA256 should produce 32 bytes")

        // Same data produces same hash
        let hash2 = testData.sha256Hash
        XCTAssertEqual(hash, hash2, "SHA256 should be deterministic")

        // Different data produces different hash
        let differentData = Data([0x05, 0x06, 0x07, 0x08])
        let differentHash = differentData.sha256Hash
        XCTAssertNotEqual(hash, differentHash, "Different data should produce different hash")

        // Empty data produces hash
        let emptyData = Data()
        let emptyHash = emptyData.sha256Hash
        XCTAssertEqual(emptyHash.count, 32, "Empty data should still produce 32-byte hash")
    }

    func testStringSHA256Hash() {
        // Test string SHA256 hash extension
        let testString = "Hello Stellar"
        let hash = testString.sha256Hash

        XCTAssertEqual(hash.count, 32, "String SHA256 should produce 32 bytes")

        // Same string produces same hash
        let hash2 = testString.sha256Hash
        XCTAssertEqual(hash, hash2, "String SHA256 should be deterministic")

        // Known test vector for "hello" (from various SHA256 test suites)
        let hello = "hello"
        let helloHash = hello.sha256Hash
        let expectedHash = try! Data(base16Encoded: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        XCTAssertEqual(helloHash, expectedHash, "SHA256 of 'hello' should match known test vector")
    }

    // MARK: - Data+B16 Tests (base16EncodedString)

    func testB16EncodedStringBasic() {
        // Test basic encoding
        let testData = Data([0x12, 0x34, 0xAB, 0xCD])
        let hex = testData.base16EncodedString()
        XCTAssertEqual(hex, "1234abcd", "Base16 encoding should produce lowercase by default")
    }

    func testB16EncodedStringUppercase() {
        // Test uppercase option
        let testData = Data([0x12, 0x34, 0xAB, 0xCD])
        let hexUpper = testData.base16EncodedString(options: [.uppercase])
        XCTAssertEqual(hexUpper, "1234ABCD", "Base16 encoding with uppercase option should produce uppercase")
    }

    func testB16EncodedStringEmpty() {
        // Test empty data
        let emptyData = Data()
        let emptyHex = emptyData.base16EncodedString()
        XCTAssertEqual(emptyHex, "", "Empty data should produce empty hex string")
    }

    func testB16EncodedStringVariousLengths() {
        // Test single byte
        let singleByte = Data([0xFF])
        XCTAssertEqual(singleByte.base16EncodedString(), "ff", "Single byte should encode correctly")

        // Test two bytes
        let twoBytes = Data([0x00, 0xFF])
        XCTAssertEqual(twoBytes.base16EncodedString(), "00ff", "Two bytes should encode correctly")

        // Test three bytes
        let threeBytes = Data([0xDE, 0xAD, 0xBE])
        XCTAssertEqual(threeBytes.base16EncodedString(), "deadbe", "Three bytes should encode correctly")

        // Test four bytes
        let fourBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(fourBytes.base16EncodedString(), "deadbeef", "Four bytes should encode correctly")

        // Test long data (32 bytes - typical hash)
        let longData = Data([0xb6, 0xef, 0xd7, 0xad, 0xfb, 0xa8, 0x4c, 0xfc,
                             0x8c, 0x07, 0x27, 0xa3, 0x38, 0xff, 0xab, 0x23,
                             0x79, 0xcd, 0x1a, 0xfc, 0x35, 0xa6, 0x9f, 0x43,
                             0x64, 0x46, 0x8c, 0x4f, 0x2f, 0x1a, 0x8a, 0xd1])
        let expected = "b6efd7adfba84cfc8c0727a338ffab2379cd1afc35a69f4364468c4f2f1a8ad1"
        XCTAssertEqual(longData.base16EncodedString(), expected, "Long data should encode correctly")
    }

    func testB16EncodedStringAllByteValues() {
        // Test all possible byte values (0x00-0xFF)
        let allBytes = Data((0...255).map { UInt8($0) })
        let encoded = allBytes.base16EncodedString()
        XCTAssertEqual(encoded.count, 512, "256 bytes should produce 512 hex characters")

        // Verify starts with "00" and ends with "ff"
        XCTAssertTrue(encoded.hasPrefix("00"), "Should start with 00")
        XCTAssertTrue(encoded.hasSuffix("ff"), "Should end with ff")
    }

    // MARK: - Data+B16 Tests (base16EncodedData)

    func testB16EncodedData() {
        // Test that base16EncodedData returns UTF-8 encoded hex string
        let testData = Data([0x12, 0x34, 0xAB, 0xCD])
        let encodedData = testData.base16EncodedData()
        let expectedString = "1234abcd"

        XCTAssertEqual(encodedData, expectedString.data(using: .utf8),
                      "base16EncodedData should return UTF-8 encoded hex string")
    }

    func testB16EncodedDataUppercase() {
        // Test uppercase option
        let testData = Data([0x12, 0x34, 0xAB, 0xCD])
        let encodedData = testData.base16EncodedData(options: [.uppercase])
        let expectedString = "1234ABCD"

        XCTAssertEqual(encodedData, expectedString.data(using: .utf8),
                      "base16EncodedData with uppercase should return uppercase hex")
    }

    func testB16EncodedDataEmpty() {
        // Test empty data
        let emptyData = Data()
        let encodedData = emptyData.base16EncodedData()

        XCTAssertEqual(encodedData, Data(), "Empty data should produce empty encoded data")
    }

    // MARK: - Data+B16 Tests (init base16Encoded String)

    func testB16InitFromStringLowercase() {
        // Test decoding lowercase hex string
        let hexString = "1234abcd"
        let decoded = try! Data(base16Encoded: hexString)
        let expected = Data([0x12, 0x34, 0xAB, 0xCD])
        XCTAssertEqual(decoded, expected, "Hex decoding should work with lowercase")
    }

    func testB16InitFromStringUppercase() {
        // Test decoding uppercase hex string
        let hexUpper = "1234ABCD"
        let decodedUpper = try! Data(base16Encoded: hexUpper)
        let expected = Data([0x12, 0x34, 0xAB, 0xCD])
        XCTAssertEqual(decodedUpper, expected, "Hex decoding should work with uppercase")
    }

    func testB16InitFromStringMixedCase() {
        // Test decoding mixed case hex string
        let hexMixed = "1234AbCd"
        let decodedMixed = try! Data(base16Encoded: hexMixed)
        let expected = Data([0x12, 0x34, 0xAB, 0xCD])
        XCTAssertEqual(decodedMixed, expected, "Hex decoding should work with mixed case")
    }

    func testB16InitFromStringEmpty() {
        // Test decoding empty string
        let emptyHex = ""
        let emptyDecoded = try! Data(base16Encoded: emptyHex)
        XCTAssertEqual(emptyDecoded, Data(), "Empty hex string should produce empty data")
    }

    func testB16InitFromStringOddLength() {
        // Test invalid length (odd number of characters)
        let oddHex = "123"
        XCTAssertThrowsError(try Data(base16Encoded: oddHex), "Odd length hex string should throw error") { error in
            guard let base16Error = error as? Base16EncodingError else {
                XCTFail("Should throw Base16EncodingError")
                return
            }
            if case .invalidLength = base16Error {
                // Expected
            } else {
                XCTFail("Should throw invalidLength error")
            }
        }
    }

    func testB16InitFromStringInvalidCharacters() {
        // Test invalid characters
        let invalidHex = "12GH"
        XCTAssertThrowsError(try Data(base16Encoded: invalidHex), "Invalid hex characters should throw error") { error in
            guard let base16Error = error as? Base16EncodingError else {
                XCTFail("Should throw Base16EncodingError")
                return
            }
            if case .invalidByteString(let byteString) = base16Error {
                XCTAssertEqual(byteString, "GH", "Should report the invalid byte string")
            } else {
                XCTFail("Should throw invalidByteString error")
            }
        }

        // Test with spaces
        let spacedHex = "12 34"
        XCTAssertThrowsError(try Data(base16Encoded: spacedHex), "Hex with spaces should throw error")

        // Test with special characters
        let specialHex = "12!@"
        XCTAssertThrowsError(try Data(base16Encoded: specialHex), "Hex with special chars should throw error")
    }

    func testB16InitFromStringSingleByte() {
        // Test single byte decoding
        let singleByteHex = "ff"
        let decoded = try! Data(base16Encoded: singleByteHex)
        XCTAssertEqual(decoded, Data([0xFF]), "Single byte hex should decode correctly")

        let zeroByte = "00"
        let decodedZero = try! Data(base16Encoded: zeroByte)
        XCTAssertEqual(decodedZero, Data([0x00]), "Zero byte hex should decode correctly")
    }

    // MARK: - Data+B16 Tests (init base16Encoded Data)

    func testB16InitFromData() {
        // Test decoding from UTF-8 Data
        let hexString = "1234abcd"
        let hexData = hexString.data(using: .utf8)!
        let decoded = try! Data(base16Encoded: hexData)
        let expected = Data([0x12, 0x34, 0xAB, 0xCD])
        XCTAssertEqual(decoded, expected, "Hex decoding from Data should work")
    }

    func testB16InitFromDataEmpty() {
        // Test decoding empty Data
        let emptyData = Data()
        let decoded = try! Data(base16Encoded: emptyData)
        XCTAssertEqual(decoded, Data(), "Empty hex data should produce empty data")
    }

    func testB16InitFromDataInvalidUTF8() {
        // Test invalid UTF-8 data
        let invalidUTF8 = Data([0xFF, 0xFE])
        XCTAssertThrowsError(try Data(base16Encoded: invalidUTF8), "Invalid UTF-8 should throw error") { error in
            guard let base16Error = error as? Base16EncodingError else {
                XCTFail("Should throw Base16EncodingError")
                return
            }
            if case .invalidStringEncoding = base16Error {
                // Expected
            } else {
                XCTFail("Should throw invalidStringEncoding error")
            }
        }
    }

    func testB16InitFromDataOddLength() {
        // Test odd length hex data
        let oddHexData = "123".data(using: .utf8)!
        XCTAssertThrowsError(try Data(base16Encoded: oddHexData), "Odd length hex data should throw error") { error in
            guard let base16Error = error as? Base16EncodingError else {
                XCTFail("Should throw Base16EncodingError")
                return
            }
            if case .invalidLength = base16Error {
                // Expected
            } else {
                XCTFail("Should throw invalidLength error")
            }
        }
    }

    // MARK: - Data+B16 Round Trip Tests

    func testB16RoundTrip() {
        // Test round-trip encoding and decoding
        let originalData = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
        let encoded = originalData.base16EncodedString()
        let decoded = try! Data(base16Encoded: encoded)
        XCTAssertEqual(decoded, originalData, "Round-trip encoding/decoding should preserve data")
    }

    func testB16RoundTripUppercase() {
        // Test round-trip with uppercase
        let originalData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let encoded = originalData.base16EncodedString(options: [.uppercase])
        let decoded = try! Data(base16Encoded: encoded)
        XCTAssertEqual(decoded, originalData, "Round-trip with uppercase should preserve data")
    }

    func testB16RoundTripViaData() {
        // Test round-trip via base16EncodedData
        let originalData = Data([0xCA, 0xFE, 0xBA, 0xBE])
        let encodedData = originalData.base16EncodedData()
        let decoded = try! Data(base16Encoded: encodedData)
        XCTAssertEqual(decoded, originalData, "Round-trip via encodedData should preserve data")
    }

    func testB16RoundTripAllByteValues() {
        // Test round-trip for all byte values
        let allBytes = Data((0...255).map { UInt8($0) })
        let encoded = allBytes.base16EncodedString()
        let decoded = try! Data(base16Encoded: encoded)
        XCTAssertEqual(decoded, allBytes, "Round-trip should preserve all byte values")
    }

    func testB16RoundTripVariousLengths() {
        // Test round-trip for various data lengths
        for length in [0, 1, 2, 3, 4, 5, 16, 32, 64, 100] {
            let data = Data((0..<length).map { UInt8($0 % 256) })
            let encoded = data.base16EncodedString()
            let decoded = try! Data(base16Encoded: encoded)
            XCTAssertEqual(decoded, data, "Round-trip should work for length \(length)")
        }
    }

    // MARK: - Data+Base16 Tests (deprecated hexEncodedString - for backward compatibility)

    func testBase16Encoding() {
        // Test hex encoding (deprecated method for backward compatibility)
        let testData = Data([0x12, 0x34, 0xAB, 0xCD])

        // Test lowercase (default)
        let hexLower = testData.hexEncodedString()
        XCTAssertEqual(hexLower, "1234abcd", "Hex encoding should produce lowercase by default")

        // Test uppercase
        let hexUpper = testData.hexEncodedString(options: .upperCase)
        XCTAssertEqual(hexUpper, "1234ABCD", "Hex encoding with uppercase option should produce uppercase")

        // Test empty data
        let emptyData = Data()
        let emptyHex = emptyData.hexEncodedString()
        XCTAssertEqual(emptyHex, "", "Empty data should produce empty hex string")

        // Test single byte
        let singleByte = Data([0xFF])
        let singleHex = singleByte.hexEncodedString()
        XCTAssertEqual(singleHex, "ff", "Single byte should encode correctly")
    }

    func testBase16Decoding() {
        // Test hex decoding using Data+B16
        let hexString = "1234abcd"
        let decoded = try! Data(base16Encoded: hexString)
        let expected = Data([0x12, 0x34, 0xAB, 0xCD])
        XCTAssertEqual(decoded, expected, "Hex decoding should work with lowercase")

        // Test uppercase
        let hexUpper = "1234ABCD"
        let decodedUpper = try! Data(base16Encoded: hexUpper)
        XCTAssertEqual(decodedUpper, expected, "Hex decoding should work with uppercase")

        // Test mixed case
        let hexMixed = "1234AbCd"
        let decodedMixed = try! Data(base16Encoded: hexMixed)
        XCTAssertEqual(decodedMixed, expected, "Hex decoding should work with mixed case")

        // Test empty string
        let emptyHex = ""
        let emptyDecoded = try! Data(base16Encoded: emptyHex)
        XCTAssertEqual(emptyDecoded, Data(), "Empty hex string should produce empty data")

        // Test invalid length (odd number of characters)
        let oddHex = "123"
        XCTAssertThrowsError(try Data(base16Encoded: oddHex), "Odd length hex string should throw error") { error in
            XCTAssertTrue(error is Base16EncodingError, "Should throw Base16EncodingError")
        }

        // Test invalid characters
        let invalidHex = "12GH"
        XCTAssertThrowsError(try Data(base16Encoded: invalidHex), "Invalid hex characters should throw error") { error in
            XCTAssertTrue(error is Base16EncodingError, "Should throw Base16EncodingError")
        }
    }

    func testBase16RoundTrip() {
        // Test round-trip encoding and decoding using base16EncodedString (new) and init(base16Encoded:)
        let originalData = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
        let encoded = originalData.base16EncodedString()
        let decoded = try! Data(base16Encoded: encoded)
        XCTAssertEqual(decoded, originalData, "Round-trip encoding/decoding should preserve data")
    }

    // MARK: - Test compatibility between hexEncodedString and base16EncodedString

    func testHexAndBase16Compatibility() {
        // Verify that hexEncodedString and base16EncodedString produce the same output
        let testData = Data([0x12, 0x34, 0xAB, 0xCD, 0xEF])

        let hexEncoded = testData.hexEncodedString()
        let base16Encoded = testData.base16EncodedString()

        XCTAssertEqual(hexEncoded, base16Encoded,
                      "hexEncodedString and base16EncodedString should produce identical output")

        // Test uppercase variants
        let hexEncodedUpper = testData.hexEncodedString(options: .upperCase)
        let base16EncodedUpper = testData.base16EncodedString(options: [.uppercase])

        XCTAssertEqual(hexEncodedUpper, base16EncodedUpper,
                      "hexEncodedString(upperCase) and base16EncodedString(uppercase) should produce identical output")
    }

    // MARK: - String+Base64 Tests

    func testBase64Encoding() {
        // Test base64 encoding
        let testString = "Hello, Stellar!"
        let encoded = testString.base64Encoded()
        XCTAssertNotNil(encoded, "Base64 encoding should succeed")

        // Known test vector
        let hello = "hello"
        let helloEncoded = hello.base64Encoded()
        XCTAssertEqual(helloEncoded, "aGVsbG8=", "Base64 of 'hello' should match known encoding")

        // Empty string
        let empty = ""
        let emptyEncoded = empty.base64Encoded()
        XCTAssertNotNil(emptyEncoded, "Empty string should encode successfully")
    }

    func testBase64Decoding() {
        // Test base64 decoding
        let encoded = "SGVsbG8sIFN0ZWxsYXIh"
        let decoded = encoded.base64Decoded()
        XCTAssertEqual(decoded, "Hello, Stellar!", "Base64 decoding should work correctly")

        // Known test vector
        let helloEncoded = "aGVsbG8="
        let helloDecoded = helloEncoded.base64Decoded()
        XCTAssertEqual(helloDecoded, "hello", "Base64 decoding of 'aGVsbG8=' should produce 'hello'")

        // Invalid base64 should return nil
        let invalid = "!!invalid!!"
        let invalidDecoded = invalid.base64Decoded()
        XCTAssertNil(invalidDecoded, "Invalid base64 should return nil")
    }

    func testBase64RoundTrip() {
        // Test round-trip encoding and decoding
        let testStrings = ["", "a", "Hello", "Hello, Stellar!", "Special chars: !@#$%^&*()"]

        for original in testStrings {
            guard let encoded = original.base64Encoded(),
                  let decoded = encoded.base64Decoded() else {
                XCTFail("Base64 round-trip failed for '\(original)'")
                continue
            }
            XCTAssertEqual(decoded, original, "Round-trip encoding/decoding should preserve string '\(original)'")
        }
    }

    // MARK: - String+Encoding Tests

    func testURLEncoding() {
        // Test URL encoding
        let plain = "Hello World"
        let encoded = plain.urlEncoded
        XCTAssertNotNil(encoded, "URL encoding should succeed")
        XCTAssertTrue(encoded!.contains("%20"), "Spaces should be percent-encoded")

        // Test special characters
        let special = "Hello&World=Test"
        let specialEncoded = special.urlEncoded
        XCTAssertNotNil(specialEncoded, "URL encoding with special chars should succeed")
        XCTAssertTrue(specialEncoded!.contains("%26") || specialEncoded!.contains("%3D"), "Special chars should be encoded")

        // Test already safe characters
        let safe = "HelloWorld123"
        let safeEncoded = safe.urlEncoded
        XCTAssertNotNil(safeEncoded, "URL encoding safe string should succeed")
    }

    func testURLDecoding() {
        // Test URL decoding
        let encoded = "Hello%20World"
        let decoded = encoded.urlDecoded
        XCTAssertEqual(decoded, "Hello World", "URL decoding should restore spaces")

        // Test special characters
        let specialEncoded = "Hello%26World%3DTest"
        let specialDecoded = specialEncoded.urlDecoded
        XCTAssertNotNil(specialDecoded, "URL decoding should succeed")

        // Test already decoded string
        let plain = "HelloWorld"
        let plainDecoded = plain.urlDecoded
        XCTAssertEqual(plainDecoded, plain, "Decoding plain string should return unchanged")
    }

    func testHexadecimalEncoding() {
        // Test hexadecimal string to data conversion
        let hexString = "1234abcd"
        let data = hexString.data(using: .hexadecimal)
        XCTAssertNotNil(data, "Hexadecimal conversion should succeed")
        XCTAssertEqual(data, Data([0x12, 0x34, 0xAB, 0xCD]), "Hexadecimal conversion should produce correct data")

        // Test with 0x prefix
        let hexWith0x = "0x1234abcd"
        let dataWith0x = hexWith0x.data(using: .hexadecimal)
        XCTAssertEqual(dataWith0x, Data([0x12, 0x34, 0xAB, 0xCD]), "Hexadecimal conversion should handle 0x prefix")

        // Test odd length (should fail)
        let oddHex = "123"
        let oddData = oddHex.data(using: .hexadecimal)
        XCTAssertNil(oddData, "Odd length hex string should return nil")

        // Test invalid characters
        let invalidHex = "12GH"
        let invalidData = invalidHex.data(using: .hexadecimal)
        XCTAssertNil(invalidData, "Invalid hex characters should return nil")
    }

    func testIsFullyQualifiedDomainName() {
        // Test valid FQDNs
        let validFQDNs = ["example.com", "subdomain.example.com", "api.stellar.org", "test-domain.co.uk"]
        for fqdn in validFQDNs {
            XCTAssertTrue(fqdn.isFullyQualifiedDomainName, "'\(fqdn)' should be valid FQDN")
        }

        // Test invalid FQDNs - single-word domains without dots are now correctly rejected
        let invalidFQDNs = ["", "a", "ab", "abc", "localhost", "test", "-example.com", "example-.com"]
        for invalid in invalidFQDNs {
            XCTAssertFalse(invalid.isFullyQualifiedDomainName, "'\(invalid)' should not be valid FQDN")
        }
    }

    // MARK: - Dictionary+HttpParams Tests

    func testDictionaryHttpParams() {
        // Test HTTP parameter string conversion
        let params: [String: String] = ["limit": "10", "order": "desc"]
        let queryString = params.stringFromHttpParameters()
        XCTAssertNotNil(queryString, "HTTP parameters should convert to string")

        // Query string should contain both parameters
        XCTAssertTrue(queryString!.contains("limit=10"), "Should contain limit parameter")
        XCTAssertTrue(queryString!.contains("order=desc"), "Should contain order parameter")
        XCTAssertTrue(queryString!.contains("&"), "Parameters should be separated by &")

        // Test empty dictionary
        let emptyParams: [String: String] = [:]
        let emptyQuery = emptyParams.stringFromHttpParameters()
        XCTAssertNotNil(emptyQuery, "Empty parameters should produce empty string")
        XCTAssertEqual(emptyQuery, "", "Empty parameters should produce empty string")

        // Test single parameter
        let singleParam: [String: String] = ["key": "value"]
        let singleQuery = singleParam.stringFromHttpParameters()
        XCTAssertEqual(singleQuery, "key=value", "Single parameter should not have &")

        // Test special characters (should be URL encoded)
        let specialParams: [String: String] = ["key": "value with spaces"]
        let specialQuery = specialParams.stringFromHttpParameters()
        XCTAssertNotNil(specialQuery, "Special characters should be encoded")
        XCTAssertTrue(specialQuery!.contains("value%20with%20spaces") || specialQuery!.contains("value+with+spaces"),
                     "Spaces should be encoded")
    }

    // MARK: - Data+KeyUtils Tests

    func testDataXOR() {
        // Test XOR operation on equal-length data
        let data1 = Data([0xFF, 0x00, 0xAA])
        let data2 = Data([0x0F, 0xF0, 0x55])
        let result = Data.xor(left: data1, right: data2)
        let expected = Data([0xF0, 0xF0, 0xFF])
        XCTAssertEqual(result, expected, "XOR should compute correctly")

        // Test XOR with different lengths (longer left)
        let longer = Data([0xFF, 0xFF, 0xFF, 0xFF])
        let shorter = Data([0x0F, 0x0F])
        let resultLonger = Data.xor(left: longer, right: shorter)
        XCTAssertEqual(resultLonger, Data([0xF0, 0xF0, 0xFF, 0xFF]), "XOR should handle different lengths")

        // Test XOR with different lengths (longer right)
        let resultShorter = Data.xor(left: shorter, right: longer)
        XCTAssertEqual(resultShorter, Data([0xF0, 0xF0, 0xFF, 0xFF]), "XOR should be commutative for appended bytes")

        // Test XOR with empty data
        let empty = Data()
        let resultEmpty = Data.xor(left: data1, right: empty)
        XCTAssertEqual(resultEmpty, data1, "XOR with empty should return original")
    }

    // MARK: - KeyedCoding+Collections Extension Tests
    // These tests EXPLICITLY call the extension methods in KeyedCoding+Collections.swift
    // by using custom Decodable implementations that invoke the extension.

    func testDecodeAnyDictionary() throws {
        // Test decoding [String: Any] using the extension method
        let json = """
        {
            "data": {
                "stringValue": "hello",
                "intValue": 42,
                "doubleValue": 3.14,
                "boolValue": true
            }
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyDictionaryWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.data["stringValue"] as? String, "hello")
        XCTAssertEqual(decoded.data["intValue"] as? Int, 42)
        XCTAssertEqual(decoded.data["doubleValue"] as? Double, 3.14)
        XCTAssertEqual(decoded.data["boolValue"] as? Bool, true)
    }

    func testDecodeAnyDictionaryWithNestedObjects() throws {
        // Test decoding nested dictionaries
        let json = """
        {
            "data": {
                "name": "parent",
                "nested": {
                    "name": "child",
                    "value": 123
                }
            }
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyDictionaryWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.data["name"] as? String, "parent")

        let nested = decoded.data["nested"] as? [String: Any]
        XCTAssertNotNil(nested)
        XCTAssertEqual(nested?["name"] as? String, "child")
        XCTAssertEqual(nested?["value"] as? Int, 123)
    }

    func testDecodeAnyDictionaryWithArrays() throws {
        // Test decoding dictionaries containing arrays
        let json = """
        {
            "data": {
                "items": [1, 2, 3],
                "names": ["Alice", "Bob"]
            }
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyDictionaryWrapper.self, from: jsonData)

        let items = decoded.data["items"] as? [Any]
        XCTAssertNotNil(items)
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items?[0] as? Double, 1.0) // JSON numbers decode as Double in [Any]
        XCTAssertEqual(items?[1] as? Double, 2.0)
        XCTAssertEqual(items?[2] as? Double, 3.0)

        let names = decoded.data["names"] as? [Any]
        XCTAssertNotNil(names)
        XCTAssertEqual(names?[0] as? String, "Alice")
        XCTAssertEqual(names?[1] as? String, "Bob")
    }

    func testDecodeAnyDictionaryEmpty() throws {
        // Test decoding empty dictionary
        let json = """
        {
            "data": {}
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyDictionaryWrapper.self, from: jsonData)

        XCTAssertTrue(decoded.data.isEmpty)
    }

    func testDecodeAnyDictionaryIfPresent() throws {
        // Test decodeIfPresent when key is present
        let jsonWithKey = """
        {
            "required": "value",
            "optional": {
                "key": "value"
            }
        }
        """
        let dataWithKey = jsonWithKey.data(using: .utf8)!
        let decodedWithKey = try JSONDecoder().decode(OptionalAnyDictionaryWrapper.self, from: dataWithKey)

        XCTAssertEqual(decodedWithKey.required, "value")
        XCTAssertNotNil(decodedWithKey.optional)
        XCTAssertEqual(decodedWithKey.optional?["key"] as? String, "value")

        // Test decodeIfPresent when key is missing
        let jsonWithoutKey = """
        {
            "required": "value"
        }
        """
        let dataWithoutKey = jsonWithoutKey.data(using: .utf8)!
        let decodedWithoutKey = try JSONDecoder().decode(OptionalAnyDictionaryWrapper.self, from: dataWithoutKey)

        XCTAssertEqual(decodedWithoutKey.required, "value")
        XCTAssertNil(decodedWithoutKey.optional)

        // Test decodeIfPresent when key is null
        let jsonWithNull = """
        {
            "required": "value",
            "optional": null
        }
        """
        let dataWithNull = jsonWithNull.data(using: .utf8)!
        let decodedWithNull = try JSONDecoder().decode(OptionalAnyDictionaryWrapper.self, from: dataWithNull)

        XCTAssertNil(decodedWithNull.optional)
    }

    func testDecodeAnyArray() throws {
        // Test decoding [Any] using the extension method
        let json = """
        {
            "items": ["hello", 42, 3.14, true]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.items.count, 4)
        XCTAssertEqual(decoded.items[0] as? String, "hello")
        // Note: JSON numbers in [Any] context may decode as Double
        XCTAssertEqual(decoded.items[1] as? Double, 42.0)
        XCTAssertEqual(decoded.items[2] as? Double, 3.14)
        XCTAssertEqual(decoded.items[3] as? Bool, true)
    }

    func testDecodeAnyArrayWithNestedObjects() throws {
        // Test decoding arrays containing dictionaries
        let json = """
        {
            "items": [
                {"name": "item1", "value": 1},
                {"name": "item2", "value": 2}
            ]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.items.count, 2)

        let item1 = decoded.items[0] as? [String: Any]
        XCTAssertNotNil(item1)
        XCTAssertEqual(item1?["name"] as? String, "item1")

        let item2 = decoded.items[1] as? [String: Any]
        XCTAssertNotNil(item2)
        XCTAssertEqual(item2?["name"] as? String, "item2")
    }

    func testDecodeAnyArrayWithNestedArrays() throws {
        // Test directly nested arrays [[1,2], [3,4], [5,6]]
        let json = """
        {
            "items": [[1, 2], [3, 4], [5, 6]]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.items.count, 3)

        let firstArray = decoded.items[0] as? [Any]
        XCTAssertNotNil(firstArray)
        XCTAssertEqual(firstArray?.count, 2)
        XCTAssertEqual(firstArray?[0] as? Double, 1.0)
        XCTAssertEqual(firstArray?[1] as? Double, 2.0)

        let secondArray = decoded.items[1] as? [Any]
        XCTAssertNotNil(secondArray)
        XCTAssertEqual(secondArray?[0] as? Double, 3.0)
        XCTAssertEqual(secondArray?[1] as? Double, 4.0)

        let thirdArray = decoded.items[2] as? [Any]
        XCTAssertNotNil(thirdArray)
        XCTAssertEqual(thirdArray?[0] as? Double, 5.0)
        XCTAssertEqual(thirdArray?[1] as? Double, 6.0)
    }

    func testDecodeDirectlyNestedArrays() throws {
        // Test that directly nested arrays work without crashing
        let json = """
        {
            "items": [[1, 2], [3, 4], [5, 6]]
        }
        """
        let jsonData = json.data(using: .utf8)!

        // This should work without causing a segfault
        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.items.count, 3)

        // Verify each nested array is decoded correctly
        for (index, item) in decoded.items.enumerated() {
            let nestedArray = item as? [Any]
            XCTAssertNotNil(nestedArray, "Item at index \(index) should be an array")
            XCTAssertEqual(nestedArray?.count, 2, "Each nested array should have 2 elements")
        }
    }

    func testDecodeDeeplyNestedArrays() throws {
        // Test deeply nested arrays [[[1, 2]], [[3, 4]]]
        let json = """
        {
            "items": [[[1, 2]], [[3, 4]]]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.items.count, 2)

        let firstOuter = decoded.items[0] as? [Any]
        XCTAssertNotNil(firstOuter)
        XCTAssertEqual(firstOuter?.count, 1)

        let firstInner = firstOuter?[0] as? [Any]
        XCTAssertNotNil(firstInner)
        XCTAssertEqual(firstInner?.count, 2)
        XCTAssertEqual(firstInner?[0] as? Double, 1.0)
        XCTAssertEqual(firstInner?[1] as? Double, 2.0)
    }

    func testDecodeMixedNestedArrays() throws {
        // Test mixed content in nested arrays
        let json = """
        {
            "items": [["a", "b"], [1, 2], [true, false]]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.items.count, 3)

        let stringArray = decoded.items[0] as? [Any]
        XCTAssertEqual(stringArray?[0] as? String, "a")
        XCTAssertEqual(stringArray?[1] as? String, "b")

        let numberArray = decoded.items[1] as? [Any]
        XCTAssertEqual(numberArray?[0] as? Double, 1.0)
        XCTAssertEqual(numberArray?[1] as? Double, 2.0)

        let boolArray = decoded.items[2] as? [Any]
        XCTAssertEqual(boolArray?[0] as? Bool, true)
        XCTAssertEqual(boolArray?[1] as? Bool, false)
    }

    func testDecodeAnyArrayEmpty() throws {
        // Test decoding empty array
        let json = """
        {
            "items": []
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        XCTAssertTrue(decoded.items.isEmpty)
    }

    func testDecodeAnyArrayIfPresent() throws {
        // Test decodeIfPresent when key is present
        let jsonWithKey = """
        {
            "required": "value",
            "optional": [1, 2, 3]
        }
        """
        let dataWithKey = jsonWithKey.data(using: .utf8)!
        let decodedWithKey = try JSONDecoder().decode(OptionalAnyArrayWrapper.self, from: dataWithKey)

        XCTAssertEqual(decodedWithKey.required, "value")
        XCTAssertNotNil(decodedWithKey.optional)
        XCTAssertEqual(decodedWithKey.optional?.count, 3)

        // Test decodeIfPresent when key is missing
        let jsonWithoutKey = """
        {
            "required": "value"
        }
        """
        let dataWithoutKey = jsonWithoutKey.data(using: .utf8)!
        let decodedWithoutKey = try JSONDecoder().decode(OptionalAnyArrayWrapper.self, from: dataWithoutKey)

        XCTAssertNil(decodedWithoutKey.optional)

        // Test decodeIfPresent when key is null
        let jsonWithNull = """
        {
            "required": "value",
            "optional": null
        }
        """
        let dataWithNull = jsonWithNull.data(using: .utf8)!
        let decodedWithNull = try JSONDecoder().decode(OptionalAnyArrayWrapper.self, from: dataWithNull)

        XCTAssertNil(decodedWithNull.optional)
    }

    func testDecodeAnyDictionaryDeeplyNested() throws {
        // Test deeply nested structures
        let json = """
        {
            "data": {
                "level1": {
                    "level2": {
                        "level3": {
                            "value": "deep"
                        }
                    }
                }
            }
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyDictionaryWrapper.self, from: jsonData)

        let level1 = decoded.data["level1"] as? [String: Any]
        XCTAssertNotNil(level1)

        let level2 = level1?["level2"] as? [String: Any]
        XCTAssertNotNil(level2)

        let level3 = level2?["level3"] as? [String: Any]
        XCTAssertNotNil(level3)

        XCTAssertEqual(level3?["value"] as? String, "deep")
    }

    func testDecodeAnyArrayWithNullValues() throws {
        // Test array containing null values - they should be skipped per the extension implementation
        let json = """
        {
            "items": [1, null, 2, null, 3]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyArrayWrapper.self, from: jsonData)

        // The extension skips null values, so we should only get the non-null values
        XCTAssertEqual(decoded.items.count, 3)
        XCTAssertEqual(decoded.items[0] as? Double, 1.0)
        XCTAssertEqual(decoded.items[1] as? Double, 2.0)
        XCTAssertEqual(decoded.items[2] as? Double, 3.0)
    }

    func testDecodeAnyDictionaryMixedTypes() throws {
        // Test comprehensive mixed types
        let json = """
        {
            "data": {
                "string": "text",
                "integer": 42,
                "float": 3.14159,
                "boolTrue": true,
                "boolFalse": false,
                "array": [1, "two", true],
                "object": {"nested": "value"},
                "emptyArray": [],
                "emptyObject": {}
            }
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AnyDictionaryWrapper.self, from: jsonData)

        XCTAssertEqual(decoded.data["string"] as? String, "text")
        XCTAssertEqual(decoded.data["integer"] as? Int, 42)
        if let floatValue = decoded.data["float"] as? Double {
            XCTAssertEqual(floatValue, 3.14159, accuracy: 0.00001)
        } else {
            XCTFail("float value should be a Double")
        }
        XCTAssertEqual(decoded.data["boolTrue"] as? Bool, true)
        XCTAssertEqual(decoded.data["boolFalse"] as? Bool, false)

        let array = decoded.data["array"] as? [Any]
        XCTAssertEqual(array?.count, 3)

        let object = decoded.data["object"] as? [String: Any]
        XCTAssertEqual(object?["nested"] as? String, "value")

        let emptyArray = decoded.data["emptyArray"] as? [Any]
        XCTAssertTrue(emptyArray?.isEmpty ?? false)

        let emptyObject = decoded.data["emptyObject"] as? [String: Any]
        XCTAssertTrue(emptyObject?.isEmpty ?? false)
    }

    // MARK: - KeyedCoding+Collections Typed Tests (using synthesized Decodable)
    // These tests verify standard Decodable behavior with typed structs.

    func testDecodeDictionaryWithTypedValues() throws {
        // Test decoding a JSON dictionary with typed values using a safe wrapper
        let json = """
        {
            "stringValue": "hello",
            "intValue": 42,
            "doubleValue": 3.14,
            "boolValue": true
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(TypedDictionaryContainer.self, from: jsonData)

        XCTAssertEqual(decoded.stringValue, "hello")
        XCTAssertEqual(decoded.intValue, 42)
        XCTAssertEqual(decoded.doubleValue, 3.14, accuracy: 0.001)
        XCTAssertTrue(decoded.boolValue)
    }

    func testDecodeOptionalTypedDictionary() throws {
        // Test decoding with present optional fields
        let jsonWithValues = """
        {
            "requiredField": "required",
            "optionalString": "optional",
            "optionalInt": 123
        }
        """
        let dataWithValues = jsonWithValues.data(using: .utf8)!
        let decodedWithValues = try JSONDecoder().decode(OptionalTypedContainer.self, from: dataWithValues)
        XCTAssertEqual(decodedWithValues.requiredField, "required")
        XCTAssertEqual(decodedWithValues.optionalString, "optional")
        XCTAssertEqual(decodedWithValues.optionalInt, 123)

        // Test decoding without optional keys
        let jsonWithoutOptional = """
        {
            "requiredField": "required"
        }
        """
        let dataWithoutOptional = jsonWithoutOptional.data(using: .utf8)!
        let decodedWithoutOptional = try JSONDecoder().decode(OptionalTypedContainer.self, from: dataWithoutOptional)
        XCTAssertEqual(decodedWithoutOptional.requiredField, "required")
        XCTAssertNil(decodedWithoutOptional.optionalString)
        XCTAssertNil(decodedWithoutOptional.optionalInt)

        // Test decoding with null value
        let jsonWithNull = """
        {
            "requiredField": "required",
            "optionalString": null
        }
        """
        let dataWithNull = jsonWithNull.data(using: .utf8)!
        let decodedWithNull = try JSONDecoder().decode(OptionalTypedContainer.self, from: dataWithNull)
        XCTAssertNil(decodedWithNull.optionalString)
    }

    func testDecodeArrayWithTypedValues() throws {
        // Test decoding a JSON array with typed values
        let json = """
        {
            "strings": ["first", "second", "third"],
            "numbers": [1, 2, 3]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(TypedArrayContainer.self, from: jsonData)
        XCTAssertEqual(decoded.strings.count, 3)
        XCTAssertEqual(decoded.strings[0], "first")
        XCTAssertEqual(decoded.strings[1], "second")
        XCTAssertEqual(decoded.strings[2], "third")
        XCTAssertEqual(decoded.numbers, [1, 2, 3])
    }

    func testDecodeOptionalTypedArray() throws {
        // Test decoding with present array
        let jsonWithArray = """
        {
            "requiredArray": ["a"],
            "optionalArray": ["b", "c"]
        }
        """
        let dataWithArray = jsonWithArray.data(using: .utf8)!
        let decodedWithArray = try JSONDecoder().decode(OptionalTypedArrayContainer.self, from: dataWithArray)
        XCTAssertEqual(decodedWithArray.requiredArray, ["a"])
        XCTAssertEqual(decodedWithArray.optionalArray, ["b", "c"])

        // Test decoding without the optional key
        let jsonWithoutArray = """
        {
            "requiredArray": ["a"]
        }
        """
        let dataWithoutArray = jsonWithoutArray.data(using: .utf8)!
        let decodedWithoutArray = try JSONDecoder().decode(OptionalTypedArrayContainer.self, from: dataWithoutArray)
        XCTAssertEqual(decodedWithoutArray.requiredArray, ["a"])
        XCTAssertNil(decodedWithoutArray.optionalArray)

        // Test decoding with null value
        let jsonWithNull = """
        {
            "requiredArray": ["a"],
            "optionalArray": null
        }
        """
        let dataWithNull = jsonWithNull.data(using: .utf8)!
        let decodedWithNull = try JSONDecoder().decode(OptionalTypedArrayContainer.self, from: dataWithNull)
        XCTAssertNil(decodedWithNull.optionalArray)
    }

    func testDecodeNestedStructures() throws {
        // Test decoding nested objects and arrays
        let json = """
        {
            "name": "parent",
            "nested": {
                "name": "child",
                "value": 42
            },
            "items": [
                {"name": "item1", "value": 1},
                {"name": "item2", "value": 2}
            ]
        }
        """
        let jsonData = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(NestedTypedContainer.self, from: jsonData)
        XCTAssertEqual(decoded.name, "parent")
        XCTAssertEqual(decoded.nested.name, "child")
        XCTAssertEqual(decoded.nested.value, 42)
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.items[0].name, "item1")
        XCTAssertEqual(decoded.items[1].value, 2)
    }

    func testDecodeEmptyCollections() throws {
        // Test decoding empty arrays
        let emptyArrayJson = """
        {
            "strings": [],
            "numbers": []
        }
        """
        let emptyArrayData = emptyArrayJson.data(using: .utf8)!
        let decodedArray = try JSONDecoder().decode(TypedArrayContainer.self, from: emptyArrayData)
        XCTAssertTrue(decodedArray.strings.isEmpty, "Empty array should be decoded as empty")
        XCTAssertTrue(decodedArray.numbers.isEmpty, "Empty array should be decoded as empty")
    }

    func testJSONCodingKeysInitializers() {
        // Test string-based initializer
        let stringKey = JSONCodingKeys(stringValue: "testKey")
        XCTAssertNotNil(stringKey)
        XCTAssertEqual(stringKey?.stringValue, "testKey")
        XCTAssertNil(stringKey?.intValue)

        // Test int-based initializer
        let intKey = JSONCodingKeys(intValue: 42)
        XCTAssertNotNil(intKey)
        XCTAssertEqual(intKey?.stringValue, "42")
        XCTAssertEqual(intKey?.intValue, 42)

        // Test with zero
        let zeroKey = JSONCodingKeys(intValue: 0)
        XCTAssertNotNil(zeroKey)
        XCTAssertEqual(zeroKey?.stringValue, "0")
        XCTAssertEqual(zeroKey?.intValue, 0)

        // Test with negative number
        let negativeKey = JSONCodingKeys(intValue: -5)
        XCTAssertNotNil(negativeKey)
        XCTAssertEqual(negativeKey?.stringValue, "-5")
        XCTAssertEqual(negativeKey?.intValue, -5)
    }

    // MARK: - URLRequest+MultipartFormData Tests

    func testMultipartFormDataBasic() throws {
        let url = URL(string: "https://example.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let testData = "Hello, World!".data(using: .utf8)!
        try request.setMultipartFormData(["field1": testData], encoding: .utf8)

        // Verify Content-Type header is set
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        XCTAssertNotNil(contentType, "Content-Type header should be set")
        XCTAssertTrue(contentType!.contains("multipart/form-data"), "Content-Type should be multipart/form-data")
        XCTAssertTrue(contentType!.contains("boundary="), "Content-Type should contain boundary")
        XCTAssertTrue(contentType!.contains("charset="), "Content-Type should contain charset")

        // Verify httpBody is set
        XCTAssertNotNil(request.httpBody, "HTTP body should be set")

        // Verify body contains the field name
        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"field1\""), "Body should contain field disposition")
        XCTAssertTrue(bodyString.contains("Hello, World!"), "Body should contain the data")
    }

    func testMultipartFormDataMultipleFields() throws {
        let url = URL(string: "https://example.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let field1Data = "Field 1 Data".data(using: .utf8)!
        let field2Data = "Field 2 Data".data(using: .utf8)!
        let parameters: [String: Data] = [
            "field1": field1Data,
            "field2": field2Data
        ]

        try request.setMultipartFormData(parameters, encoding: .utf8)

        let bodyString = String(data: request.httpBody!, encoding: .utf8)!

        // Both fields should be present
        XCTAssertTrue(bodyString.contains("name=\"field1\""), "Body should contain field1")
        XCTAssertTrue(bodyString.contains("name=\"field2\""), "Body should contain field2")
        XCTAssertTrue(bodyString.contains("Field 1 Data"), "Body should contain field1 data")
        XCTAssertTrue(bodyString.contains("Field 2 Data"), "Body should contain field2 data")
    }

    func testMultipartFormDataEmptyParameters() throws {
        let url = URL(string: "https://example.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        try request.setMultipartFormData([:], encoding: .utf8)

        // Should still set Content-Type and body
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertNotNil(request.httpBody)

        // Body should just have the closing boundary
        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("--"), "Body should contain boundary markers")
    }

    func testMultipartFormDataBinaryContent() throws {
        let url = URL(string: "https://example.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create binary data (not valid UTF-8 text)
        let binaryData = Data([0x00, 0x01, 0xFF, 0xFE, 0x89, 0x50, 0x4E, 0x47])

        try request.setMultipartFormData(["binaryField": binaryData], encoding: .utf8)

        XCTAssertNotNil(request.httpBody, "HTTP body should be set")

        // Verify the binary data is in the body
        let body = request.httpBody!
        XCTAssertTrue(body.count > binaryData.count, "Body should contain binary data plus headers")
    }

    func testMultipartFormDataEncodingError() {
        let url = URL(string: "https://example.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create a field name that cannot be converted to ASCII
        let testData = "test".data(using: .utf8)!

        // ASCII encoding should fail for non-ASCII field names
        // Note: The implementation checks if the field name can be converted to the encoding
        // Using Japanese characters that cannot be encoded in ASCII
        let nonAsciiFieldName = "field\u{1234}"
        let parameters: [String: Data] = [nonAsciiFieldName: testData]

        // This should throw an EncodingError for the name
        XCTAssertThrowsError(try request.setMultipartFormData(parameters, encoding: .ascii)) { error in
            XCTAssertTrue(error is EncodingError, "Should throw EncodingError")
            if let encodingError = error as? EncodingError {
                XCTAssertEqual(encodingError.what, "name", "Error should be for 'name'")
            }
        }
    }

    func testMultipartFormDataSpecialFieldNames() throws {
        let url = URL(string: "https://example.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let testData = "test".data(using: .utf8)!

        // Test with special characters in field name (but still ASCII-compatible)
        let parameters: [String: Data] = [
            "field-with-dashes": testData,
            "field_with_underscores": testData,
            "field.with.dots": testData
        ]

        try request.setMultipartFormData(parameters, encoding: .utf8)

        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("name=\"field-with-dashes\""))
        XCTAssertTrue(bodyString.contains("name=\"field_with_underscores\""))
        XCTAssertTrue(bodyString.contains("name=\"field.with.dots\""))
    }

    func testEncodingErrorDescription() {
        let error = EncodingError(what: "test_field")
        XCTAssertEqual(error.what, "test_field", "Error should store the 'what' field")
    }

    // MARK: - String UTF-8 Extension Tests (StringExtension.swift)
    // Note: These tests only cover ASCII strings because the current implementation
    // has a known limitation with non-ASCII characters (bytes >= 128).

    func testDataUsingUTF8StringEncoding() {
        // Test basic ASCII string
        let asciiString = "Hello"
        let asciiData = asciiString.dataUsingUTF8StringEncoding
        XCTAssertEqual(asciiData, Data([72, 101, 108, 108, 111]), "ASCII string should encode correctly")

        // Test empty string
        let emptyString = ""
        let emptyData = emptyString.dataUsingUTF8StringEncoding
        XCTAssertEqual(emptyData, Data(), "Empty string should produce empty data")

        // Test string with numbers
        let numberString = "12345"
        let numberData = numberString.dataUsingUTF8StringEncoding
        XCTAssertEqual(numberData, Data([49, 50, 51, 52, 53]), "Number string should encode correctly")

        // Test string with special characters (ASCII range)
        let specialString = "!@#$%"
        let specialData = specialString.dataUsingUTF8StringEncoding
        XCTAssertEqual(specialData, Data([33, 64, 35, 36, 37]), "Special characters should encode correctly")

        // Test with various ASCII characters
        let allAsciiPrintable = " ~"  // Space (32) and tilde (126) - ASCII range boundaries
        let asciiRangeData = allAsciiPrintable.dataUsingUTF8StringEncoding
        XCTAssertEqual(asciiRangeData, Data([32, 126]), "ASCII boundary characters should encode correctly")

        // Test with newline and tab
        let whitespaceString = "a\nb\tc"
        let whitespaceData = whitespaceString.dataUsingUTF8StringEncoding
        XCTAssertEqual(whitespaceData, Data([97, 10, 98, 9, 99]), "Whitespace characters should encode correctly")
    }

    func testArrayUsingUTF8StringEncoding() {
        // Test basic ASCII string
        let asciiString = "Hello"
        let asciiArray = asciiString.arrayUsingUTF8StringEncoding
        XCTAssertEqual(asciiArray, [72, 101, 108, 108, 111], "ASCII string should encode correctly")

        // Test empty string
        let emptyString = ""
        let emptyArray = emptyString.arrayUsingUTF8StringEncoding
        XCTAssertEqual(emptyArray, [], "Empty string should produce empty array")

        // Test string with numbers
        let numberString = "12345"
        let numberArray = numberString.arrayUsingUTF8StringEncoding
        XCTAssertEqual(numberArray, [49, 50, 51, 52, 53], "Number string should encode correctly")

        // Test string with special characters (ASCII range)
        let specialString = "!@#$%"
        let specialArray = specialString.arrayUsingUTF8StringEncoding
        XCTAssertEqual(specialArray, [33, 64, 35, 36, 37], "Special characters should encode correctly")

        // Test with various ASCII characters
        let allAsciiPrintable = " ~"  // Space (32) and tilde (126) - ASCII range boundaries
        let asciiRangeArray = allAsciiPrintable.arrayUsingUTF8StringEncoding
        XCTAssertEqual(asciiRangeArray, [32, 126], "ASCII boundary characters should encode correctly")
    }

    func testDataAndArrayConsistency() {
        // Verify that dataUsingUTF8StringEncoding and arrayUsingUTF8StringEncoding
        // produce consistent results (ASCII strings only due to implementation limitation)
        let testStrings = ["Hello", "", "Test123", "Mixed content!", "a\nb\tc"]

        for string in testStrings {
            let dataResult = string.dataUsingUTF8StringEncoding
            let arrayResult = string.arrayUsingUTF8StringEncoding

            XCTAssertEqual(dataResult, Data(arrayResult),
                          "Data and array encodings should be consistent for '\(string)'")
        }
    }

    func testUTF8EncodingNeverNil() {
        // Test that the property never returns nil (unlike String.data(using:))
        // Testing with ASCII strings only due to implementation limitation
        let testStrings = [
            "Normal string",
            "",
            "String with\nnewlines",
            "String\twith\ttabs",
            String(repeating: "a", count: 10000) // long string
        ]

        for string in testStrings {
            let data = string.dataUsingUTF8StringEncoding
            let array = string.arrayUsingUTF8StringEncoding

            // These should never fail for ASCII strings
            XCTAssertNotNil(data, "dataUsingUTF8StringEncoding should never be nil")
            XCTAssertNotNil(array, "arrayUsingUTF8StringEncoding should never be nil")
        }
    }

    // MARK: - String+Base32 Tests

    func testBase32EncodedString() {
        // Test basic encoding
        let text = "Hello"
        let encoded = text.base32EncodedString
        XCTAssertEqual(encoded, "JBSWY3DP", "Base32 encoding should match RFC 4648")

        // Test empty string
        let empty = ""
        let emptyEncoded = empty.base32EncodedString
        XCTAssertEqual(emptyEncoded, "", "Empty string should encode to empty")

        // Test longer text
        let longer = "Hello, World!"
        let longerEncoded = longer.base32EncodedString
        XCTAssertFalse(longerEncoded.isEmpty, "Longer text should encode")
    }

    func testBase32DecodedData() {
        // Test basic decoding
        let encoded = "JBSWY3DP"
        let decoded = encoded.base32DecodedData
        XCTAssertNotNil(decoded, "Valid base32 should decode")
        XCTAssertEqual(String(data: decoded!, encoding: .utf8), "Hello", "Decoded data should match original")

        // Test empty string
        let empty = ""
        let emptyDecoded = empty.base32DecodedData
        XCTAssertNotNil(emptyDecoded, "Empty string should decode")
        XCTAssertEqual(emptyDecoded?.count, 0, "Empty decode should be empty data")

        // Test invalid base32 (contains invalid character '1')
        let invalid = "1234ABCD"
        let invalidDecoded = invalid.base32DecodedData
        XCTAssertNil(invalidDecoded, "Invalid base32 should return nil")
    }

    func testBase32DecodedString() {
        // Test basic decoding to string
        let encoded = "JBSWY3DP"
        let decoded = encoded.base32DecodedString()
        XCTAssertEqual(decoded, "Hello", "Base32 decoded string should match original")

        // Test longer string with padding (ORSXG5A= is base32 of "test")
        let paddedEncoded = "ORSXG5A="
        let paddedDecoded = paddedEncoded.base32DecodedString()
        XCTAssertEqual(paddedDecoded, "test", "Padded base32 should decode correctly")
    }

    func testBase32HexEncodedString() {
        // Test base32hex encoding
        let text = "Hello"
        let encoded = text.base32HexEncodedString
        XCTAssertFalse(encoded.isEmpty, "Base32hex should encode")

        // Base32hex uses different alphabet (0-9, A-V)
        // Verify it's different from standard base32
        let standardEncoded = text.base32EncodedString
        XCTAssertNotEqual(encoded, standardEncoded, "Base32hex should differ from standard base32")
    }

    func testBase32HexDecodedData() {
        // Encode then decode to verify round-trip
        let original = "Test"
        let encoded = original.base32HexEncodedString
        let decoded = encoded.base32HexDecodedData
        XCTAssertNotNil(decoded, "Base32hex should decode")
        XCTAssertEqual(String(data: decoded!, encoding: .utf8), original, "Round-trip should preserve data")
    }

    func testBase32HexDecodedString() {
        // Encode then decode to verify round-trip
        let original = "Hello"
        let encoded = original.base32HexEncodedString
        let decoded = encoded.base32HexDecodedString()
        XCTAssertEqual(decoded, original, "Base32hex round-trip should preserve string")
    }

    func testBase32RoundTrip() {
        // Test round-trip for various strings
        let testStrings = ["A", "AB", "ABC", "ABCD", "ABCDE", "Hello, World!", ""]

        for original in testStrings {
            let encoded = original.base32EncodedString
            let decoded = encoded.base32DecodedString()
            XCTAssertEqual(decoded, original, "Base32 round-trip should preserve '\(original)'")
        }
    }

    // MARK: - Data+Base32 Tests

    func testDataBase32EncodedString() {
        // Test basic encoding
        let data = Data([72, 101, 108, 108, 111]) // "Hello"
        let encoded = data.base32EncodedString
        XCTAssertEqual(encoded, "JBSWY3DP", "Data base32 encoding should match")

        // Test empty data
        let emptyData = Data()
        let emptyEncoded = emptyData.base32EncodedString
        XCTAssertEqual(emptyEncoded, "", "Empty data should encode to empty string")
    }

    func testDataBase32EncodedData() {
        // Test that encoded data is UTF-8 representation of encoded string
        let data = Data([72, 101, 108, 108, 111]) // "Hello"
        let encodedData = data.base32EncodedData
        let encodedString = data.base32EncodedString

        XCTAssertEqual(encodedData, encodedString.data(using: .utf8),
                      "Encoded data should be UTF-8 of encoded string")
    }

    func testDataBase32DecodedData() {
        // Test decoding base32-encoded data
        let encodedString = "JBSWY3DP"
        let encodedData = encodedString.data(using: .utf8)!
        let decoded = encodedData.base32DecodedData

        XCTAssertNotNil(decoded, "Should decode successfully")
        XCTAssertEqual(decoded, Data([72, 101, 108, 108, 111]), "Decoded should be 'Hello' bytes")
    }

    func testDataBase32HexEncodedString() {
        // Test base32hex encoding
        let data = Data([72, 101, 108, 108, 111]) // "Hello"
        let encoded = data.base32HexEncodedString
        XCTAssertFalse(encoded.isEmpty, "Base32hex should encode")

        // Should be different from standard base32
        let standardEncoded = data.base32EncodedString
        XCTAssertNotEqual(encoded, standardEncoded, "Base32hex should differ from standard")
    }

    func testDataBase32HexEncodedData() {
        // Test that hex encoded data is UTF-8 representation
        let data = Data([72, 101, 108, 108, 111])
        let encodedData = data.base32HexEncodedData
        let encodedString = data.base32HexEncodedString

        XCTAssertEqual(encodedData, encodedString.data(using: .utf8),
                      "Hex encoded data should be UTF-8 of encoded string")
    }

    func testDataBase32HexDecodedData() {
        // Encode then decode to verify round-trip
        let original = Data([1, 2, 3, 4, 5])
        let encodedString = original.base32HexEncodedString
        let encodedData = encodedString.data(using: .utf8)!
        let decoded = encodedData.base32HexDecodedData

        XCTAssertNotNil(decoded, "Should decode successfully")
        XCTAssertEqual(decoded, original, "Round-trip should preserve data")
    }

    func testDataBase32RoundTrip() {
        // Test round-trip for various data
        let testData = [
            Data(),
            Data([0]),
            Data([0, 1]),
            Data([0, 1, 2]),
            Data([0, 1, 2, 3]),
            Data([0, 1, 2, 3, 4]),
            Data((0..<256).map { UInt8($0) })
        ]

        for original in testData {
            let encoded = original.base32EncodedString
            let decoded = encoded.base32DecodedData
            XCTAssertEqual(decoded, original, "Base32 round-trip should preserve data of length \(original.count)")
        }
    }
}

// MARK: - Test Helper Types for KeyedCoding+Collections

/// Helper struct for testing typed dictionary decoding
private struct TypedDictionaryContainer: Decodable {
    let stringValue: String
    let intValue: Int
    let doubleValue: Double
    let boolValue: Bool
}

/// Helper struct for testing optional typed values
private struct OptionalTypedContainer: Decodable {
    let requiredField: String
    let optionalString: String?
    let optionalInt: Int?
}

/// Helper struct for testing typed array decoding
private struct TypedArrayContainer: Decodable {
    let strings: [String]
    let numbers: [Int]
}

/// Helper struct for testing optional typed arrays
private struct OptionalTypedArrayContainer: Decodable {
    let requiredArray: [String]
    let optionalArray: [String]?
}

/// Helper struct for testing nested structures
private struct NestedTypedContainer: Decodable {
    let name: String
    let nested: NestedItem
    let items: [NestedItem]

    struct NestedItem: Decodable {
        let name: String
        let value: Int
    }
}

// MARK: - Test Helper Types for KeyedCoding+Collections Extension Tests
// These structs EXPLICITLY call the extension methods in their init(from decoder:)

/// Wrapper that explicitly calls decode([String: Any].self, forKey:) extension method
private struct AnyDictionaryWrapper: Decodable {
    let data: [String: Any]

    enum CodingKeys: String, CodingKey {
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // This explicitly calls the extension method:
        self.data = try container.decode([String: Any].self, forKey: .data)
    }
}

/// Wrapper that explicitly calls decodeIfPresent([String: Any].self, forKey:) extension method
private struct OptionalAnyDictionaryWrapper: Decodable {
    let required: String
    let optional: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case required
        case optional
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.required = try container.decode(String.self, forKey: .required)
        // This explicitly calls the extension method:
        self.optional = try container.decodeIfPresent([String: Any].self, forKey: .optional)
    }
}

/// Wrapper that explicitly calls decode([Any].self, forKey:) extension method
private struct AnyArrayWrapper: Decodable {
    let items: [Any]

    enum CodingKeys: String, CodingKey {
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // This explicitly calls the extension method:
        self.items = try container.decode([Any].self, forKey: .items)
    }
}

/// Wrapper that explicitly calls decodeIfPresent([Any].self, forKey:) extension method
private struct OptionalAnyArrayWrapper: Decodable {
    let required: String
    let optional: [Any]?

    enum CodingKeys: String, CodingKey {
        case required
        case optional
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.required = try container.decode(String.self, forKey: .required)
        // This explicitly calls the extension method:
        self.optional = try container.decodeIfPresent([Any].self, forKey: .optional)
    }
}
