//
//  Data+Base64URLTests.swift
//  stellarsdkUnitTests
//
//  Copyright © Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class DataBase64URLTests: XCTestCase {

    // MARK: - Encoding

    func testEncodeEmpty() {
        XCTAssertEqual(Data().base64URLEncodedString(), "")
    }

    func testEncodeSingleByte() {
        XCTAssertEqual(Data([0x66]).base64URLEncodedString(), "Zg")
    }

    func testEncodeTwoBytes() {
        XCTAssertEqual(Data([0x66, 0x6F]).base64URLEncodedString(), "Zm8")
    }

    func testEncodeThreeBytes() {
        XCTAssertEqual(Data([0x66, 0x6F, 0x6F]).base64URLEncodedString(), "Zm9v")
    }

    func testEncodeNoPaddingInOutput() {
        let encoded = Data(repeating: 0x55, count: 17).base64URLEncodedString()
        XCTAssertFalse(encoded.contains("="))
    }

    func testEncodeUrlSafeCharacterSubstitution_noPlusSign() {
        let encoded = Data([0xFB, 0xFF]).base64URLEncodedString()
        XCTAssertFalse(encoded.contains("+"))
    }

    func testEncodeUrlSafeCharacterSubstitution_noSlash() {
        let encoded = Data([0xFB, 0xFF]).base64URLEncodedString()
        XCTAssertFalse(encoded.contains("/"))
    }

    func testEncodeUrlSafeCharacterSubstitution_mixed() {
        let encoded = Data([0xFB, 0xFF, 0xBF, 0xFB, 0xFE]).base64URLEncodedString()
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertFalse(encoded.contains("="))
    }

    func testEncode_dashAndUnderscore() {
        // [0xFB] encodes to "-w"; [0xFF] encodes to "_w".
        XCTAssertEqual(Data([0xFB]).base64URLEncodedString(), "-w")
        XCTAssertEqual(Data([0xFF]).base64URLEncodedString(), "_w")
    }

    func testEncode_mixedSpecialChars() {
        // Standard Base64 of [0xFB, 0xFF] is "+/8="; URL-safe no-pad: "-_8".
        XCTAssertEqual(Data([0xFB, 0xFF]).base64URLEncodedString(), "-_8")
    }

    // MARK: - Decoding

    func testDecodeEmpty() throws {
        XCTAssertEqual(try Data(base64URLEncoded: ""), Data())
    }

    func testDecodeSingleChar() throws {
        XCTAssertEqual(try Data(base64URLEncoded: "Zg"), Data([0x66]))
    }

    func testDecodeWithDash() throws {
        XCTAssertEqual(try Data(base64URLEncoded: "-w"), Data([0xFB]))
    }

    func testDecodeWithUnderscore() throws {
        XCTAssertEqual(try Data(base64URLEncoded: "_w"), Data([0xFF]))
    }

    func testDecodeWithPaddingAccepted() throws {
        // Standard Base64 with trailing padding must also decode.
        XCTAssertEqual(try Data(base64URLEncoded: "Zg=="), Data([0x66]))
    }

    func testDecodeInvalidInputThrows() {
        XCTAssertThrowsError(try Data(base64URLEncoded: "!!@@##")) { error in
            XCTAssertTrue(error is Base64URLEncodingError)
        }
    }

    func testDecodePaddingEdgeCases() throws {
        XCTAssertEqual(try Data(base64URLEncoded: "Zg"), Data([0x66]))
        XCTAssertEqual(try Data(base64URLEncoded: "Zm8"), Data([0x66, 0x6F]))
        XCTAssertEqual(try Data(base64URLEncoded: "Zm9v"), Data([0x66, 0x6F, 0x6F]))
    }

    // MARK: - Round-trips

    func testRoundTripEmpty() throws {
        let data = Data()
        XCTAssertEqual(try Data(base64URLEncoded: data.base64URLEncodedString()), data)
    }

    func testRoundTripSingleByte() throws {
        for value: UInt8 in [0x00, 0x01, 0x7F, 0x80, 0xFF] {
            let data = Data([value])
            let encoded = data.base64URLEncodedString()
            XCTAssertEqual(try Data(base64URLEncoded: encoded), data)
        }
    }

    func testRoundTripAllLengths() throws {
        for length in 0..<32 {
            let data = Data((0..<length).map { UInt8($0 & 0xFF) })
            let encoded = data.base64URLEncodedString()
            XCTAssertEqual(try Data(base64URLEncoded: encoded), data)
        }
    }

    func testRoundTripAllByteValues() throws {
        let data = Data((0..<256).map { UInt8($0 & 0xFF) })
        let encoded = data.base64URLEncodedString()
        XCTAssertEqual(try Data(base64URLEncoded: encoded), data)
    }

    func testRoundTripUrlSafeChars() throws {
        let data = Data([0xFB, 0xFF, 0xBF, 0xFA, 0xFE, 0xCE, 0xEF, 0xFC])
        let encoded = data.base64URLEncodedString()
        XCTAssertEqual(try Data(base64URLEncoded: encoded), data)
    }
}
