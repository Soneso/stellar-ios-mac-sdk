//
//  XdrWideIntegerUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The 128-bit and 256-bit conversions the XDR-JSON codec and the `SCValXDR` string
/// accessors share. The extremes of each width are the values a schoolbook base-256
/// converter is most likely to get wrong, and the values one step outside them are what
/// prove the range check is a boundary rather than an approximation.
final class XdrWideIntegerUnitTests: XCTestCase {

    private let u128Max = "340282366920938463463374607431768211455"
    private let u128Over = "340282366920938463463374607431768211456"
    private let i128Max = "170141183460469231731687303715884105727"
    private let i128Over = "170141183460469231731687303715884105728"
    private let i128Min = "-170141183460469231731687303715884105728"
    private let i128Under = "-170141183460469231731687303715884105729"

    private let u256Max =
        "115792089237316195423570985008687907853269984665640564039457584007913129639935"
    private let u256Over =
        "115792089237316195423570985008687907853269984665640564039457584007913129639936"
    private let i256Max =
        "57896044618658097711785492504343953926634992332820282019728792003956564819967"
    private let i256Over =
        "57896044618658097711785492504343953926634992332820282019728792003956564819968"
    private let i256Min =
        "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
    private let i256Under =
        "-57896044618658097711785492504343953926634992332820282019728792003956564819969"

    private func bytes(_ text: String, bitSize: Int, signed: Bool) throws -> Data {
        try XdrWideInteger.bytes(fromDecimalString: text, bitSize: bitSize, signed: signed)
    }

    /// The value parses but does not fit the target width.
    private func assertOutOfRange(_ text: String, bitSize: Int, signed: Bool,
                                  file: StaticString = #filePath, line: UInt = #line) {
        assertRejected(text, bitSize: bitSize, signed: signed,
                       becauseMessageContains: "out of range for", file: file, line: line)
    }

    /// The text is not a decimal integer at all, so the width never comes into it.
    private func assertNotADecimalInteger(_ text: String, bitSize: Int, signed: Bool,
                                          file: StaticString = #filePath, line: UInt = #line) {
        assertRejected(text, bitSize: bitSize, signed: signed,
                       becauseMessageContains: "Invalid number string", file: file, line: line)
    }

    private func assertRejected(_ text: String, bitSize: Int, signed: Bool,
                                becauseMessageContains fragment: String,
                                file: StaticString, line: UInt) {
        XCTAssertThrowsError(try bytes(text, bitSize: bitSize, signed: signed),
                             "accepted \(text)", file: file, line: line) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                return XCTFail("wrong error for \(text): \(error)", file: file, line: line)
            }
            XCTAssertTrue(message.contains(fragment),
                          "\(text): expected a message containing \(fragment), got \(message)",
                          file: file, line: line)
        }
    }

    // MARK: - 128-bit boundaries

    func testUnsigned128Maximum() throws {
        let encoded = try bytes(u128Max, bitSize: 128, signed: false)
        XCTAssertEqual(encoded, Data(repeating: 0xFF, count: 16))
        XCTAssertEqual(XdrWideInteger.decimalString(from: encoded, signed: false), u128Max)
    }

    func testUnsigned128AboveMaximumIsRejected() {
        assertOutOfRange(u128Over, bitSize: 128, signed: false)
    }

    func testUnsigned128RejectsANegativeValue() {
        assertOutOfRange("-1", bitSize: 128, signed: false)
    }

    func testSigned128Maximum() throws {
        let encoded = try bytes(i128Max, bitSize: 128, signed: true)
        XCTAssertEqual(encoded, Data([0x7F] + Array(repeating: UInt8(0xFF), count: 15)))
        XCTAssertEqual(XdrWideInteger.decimalString(from: encoded, signed: true), i128Max)
    }

    func testSigned128AboveMaximumIsRejected() {
        assertOutOfRange(i128Over, bitSize: 128, signed: true)
    }

    func testSigned128Minimum() throws {
        let encoded = try bytes(i128Min, bitSize: 128, signed: true)
        XCTAssertEqual(encoded, Data([0x80] + Array(repeating: UInt8(0x00), count: 15)))
        XCTAssertEqual(XdrWideInteger.decimalString(from: encoded, signed: true), i128Min)
    }

    func testSigned128BelowMinimumIsRejected() {
        assertOutOfRange(i128Under, bitSize: 128, signed: true)
    }

    // MARK: - 256-bit boundaries

    func testUnsigned256Maximum() throws {
        let encoded = try bytes(u256Max, bitSize: 256, signed: false)
        XCTAssertEqual(encoded, Data(repeating: 0xFF, count: 32))
        XCTAssertEqual(XdrWideInteger.decimalString(from: encoded, signed: false), u256Max)
    }

    func testUnsigned256AboveMaximumIsRejected() {
        assertOutOfRange(u256Over, bitSize: 256, signed: false)
    }

    func testSigned256Maximum() throws {
        let encoded = try bytes(i256Max, bitSize: 256, signed: true)
        XCTAssertEqual(encoded, Data([0x7F] + Array(repeating: UInt8(0xFF), count: 31)))
        XCTAssertEqual(XdrWideInteger.decimalString(from: encoded, signed: true), i256Max)
    }

    func testSigned256AboveMaximumIsRejected() {
        assertOutOfRange(i256Over, bitSize: 256, signed: true)
    }

    func testSigned256Minimum() throws {
        let encoded = try bytes(i256Min, bitSize: 256, signed: true)
        XCTAssertEqual(encoded, Data([0x80] + Array(repeating: UInt8(0x00), count: 31)))
        XCTAssertEqual(XdrWideInteger.decimalString(from: encoded, signed: true), i256Min)
    }

    func testSigned256BelowMinimumIsRejected() {
        assertOutOfRange(i256Under, bitSize: 256, signed: true)
    }

    // MARK: - Ordinary values

    func testZeroAndSmallValues() throws {
        XCTAssertEqual(try bytes("0", bitSize: 128, signed: false), Data(repeating: 0, count: 16))
        XCTAssertEqual(try bytes("0", bitSize: 256, signed: true), Data(repeating: 0, count: 32))
        XCTAssertEqual(XdrWideInteger.decimalString(from: Data(repeating: 0, count: 16), signed: false), "0")

        let fortyTwo = try bytes("42", bitSize: 128, signed: false)
        XCTAssertEqual(fortyTwo, Data(Array(repeating: UInt8(0), count: 15) + [0x2A]))
        XCTAssertEqual(XdrWideInteger.decimalString(from: fortyTwo, signed: false), "42")
    }

    func testMinusOneIsAllOnes() throws {
        XCTAssertEqual(try bytes("-1", bitSize: 128, signed: true), Data(repeating: 0xFF, count: 16))
        XCTAssertEqual(try bytes("-1", bitSize: 256, signed: true), Data(repeating: 0xFF, count: 32))
    }

    func testMalformedDecimalTextIsRejected() {
        for text in ["", "-", "abc", "1.0", "0x10", "1e10", "+1", "1_000"] {
            assertNotADecimalInteger(text, bitSize: 128, signed: true)
        }
    }

    /// Digits outside ASCII carry no positional value the base-256 conversion can use: it
    /// reads its input as UTF-8 bytes offset from `0x30`, so a character that merely belongs
    /// to a Unicode numeric category would be converted into an unrelated value. Every shape
    /// here is one that a category test admits.
    func testNonAsciiNumericCharactersAreRejected() {
        let samples = [
            "\u{0661}",                     // Arabic-Indic digit one
            "\u{0661}\u{0662}",             // Arabic-Indic digits one, two
            "\u{FF11}\u{FF12}\u{FF13}",     // fullwidth digits one, two, three
            "\u{0966}",                     // Devanagari digit zero
            "\u{00BD}",                     // vulgar fraction one half
            "\u{2168}",                     // Roman numeral nine
            "\u{00B2}",                     // superscript two
            "1\u{0661}"                     // an ASCII digit followed by a non-ASCII one
        ]
        for text in samples {
            assertNotADecimalInteger(text, bitSize: 128, signed: false)
            assertNotADecimalInteger(text, bitSize: 256, signed: true)
        }
    }

    func testTheDigitPredicateAdmitsOnlyAsciiDecimalText() {
        XCTAssertTrue(XdrWideInteger.isDecimalInteger("0"))
        XCTAssertTrue(XdrWideInteger.isDecimalInteger("-1"))
        XCTAssertTrue(XdrWideInteger.isDecimalInteger("340282366920938463463374607431768211455"))
        XCTAssertFalse(XdrWideInteger.isDecimalInteger(""))
        XCTAssertFalse(XdrWideInteger.isDecimalInteger("-"))
        XCTAssertFalse(XdrWideInteger.isDecimalInteger("--1"))
        XCTAssertFalse(XdrWideInteger.isDecimalInteger("1-"))
        XCTAssertFalse(XdrWideInteger.isDecimalInteger("\u{0661}"))
    }

    /// The converter trims surrounding whitespace before applying the predicate; the SEP-0051
    /// reader applies it to the JSON literal as written. The two layers differ here on
    /// purpose, so a document containing `" 42 "` is rejected while a caller passing the
    /// same text to the converter is not.
    func testSurroundingWhitespaceIsToleratedByTheConverterButNotByTheSep51Reader() throws {
        let padded = " 42 "
        XCTAssertEqual(XdrWideInteger.decimalString(
            from: try bytes(padded, bitSize: 128, signed: false), signed: false), "42")
        XCTAssertFalse(XdrJson.isDecimalInteger(padded))
    }

    /// The SEP-0051 reader and the wide-integer parser share one predicate, so a shape one
    /// rejects cannot be admitted by the other.
    func testTheSep51ReaderAndTheConverterShareOneDigitPredicate() {
        for text in ["0", "-1", "42", "", "-", "1.0", "\u{0661}", "\u{FF11}"] {
            XCTAssertEqual(XdrJson.isDecimalInteger(text), XdrWideInteger.isDecimalInteger(text),
                           "disagreement on \(text.debugDescription)")
        }
    }

    // MARK: - Limbs

    func testLimbsRoundTripThroughBytes() throws {
        let encoded = try bytes(i128Min, bitSize: 128, signed: true)
        let parts = XdrWideInteger.parts128(from: encoded)
        XCTAssertEqual(parts.hi, 0x8000_0000_0000_0000)
        XCTAssertEqual(parts.lo, 0)
        XCTAssertEqual(XdrWideInteger.data128(hi: parts.hi, lo: parts.lo), encoded)
    }

    func testFourLimbsRoundTripThroughBytes() throws {
        let encoded = try bytes(u256Max, bitSize: 256, signed: false)
        let parts = XdrWideInteger.parts256(from: encoded)
        XCTAssertEqual(parts.hiHi, UInt64.max)
        XCTAssertEqual(parts.hiLo, UInt64.max)
        XCTAssertEqual(parts.loHi, UInt64.max)
        XCTAssertEqual(parts.loLo, UInt64.max)
        XCTAssertEqual(XdrWideInteger.data256(hiHi: parts.hiHi, hiLo: parts.hiLo,
                                              loHi: parts.loHi, loLo: parts.loLo), encoded)
    }

    func testDecimalTextConvertsStraightToLimbs() throws {
        let parts = try XdrWideInteger.parts128(fromDecimalString: u128Max, signed: false)
        XCTAssertEqual(parts.hi, UInt64.max)
        XCTAssertEqual(parts.lo, UInt64.max)

        let wide = try XdrWideInteger.parts256(fromDecimalString: i256Min, signed: true)
        XCTAssertEqual(wide.hiHi, 0x8000_0000_0000_0000)
        XCTAssertEqual(wide.hiLo, 0)
        XCTAssertEqual(wide.loHi, 0)
        XCTAssertEqual(wide.loLo, 0)
    }

    // MARK: - Width adjustment

    func testPaddingSignExtendsANegativeValue() {
        let narrow = Data([0xFF])
        XCTAssertEqual(XdrWideInteger.pad(narrow, targetSize: 4, signed: true),
                       Data([0xFF, 0xFF, 0xFF, 0xFF]))
        XCTAssertEqual(XdrWideInteger.pad(narrow, targetSize: 4, signed: false),
                       Data([0x00, 0x00, 0x00, 0xFF]))
    }

    func testPaddingKeepsTheLowBytesOfAnOverlongValue() {
        let wide = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        XCTAssertEqual(XdrWideInteger.pad(wide, targetSize: 4, signed: false),
                       Data([0x02, 0x03, 0x04, 0x05]))
    }

    // MARK: - The SCValXDR accessors that share this machinery

    func testSCValAccessorsAgreeWithTheSharedConverter() throws {
        XCTAssertEqual(try SCValXDR.u128(stringValue: u128Max).u128String, u128Max)
        XCTAssertEqual(try SCValXDR.i128(stringValue: i128Min).i128String, i128Min)
        XCTAssertEqual(try SCValXDR.u256(stringValue: u256Max).u256String, u256Max)
        XCTAssertEqual(try SCValXDR.i256(stringValue: i256Min).i256String, i256Min)
    }

    /// The public factories reject non-ASCII numeric characters rather than converting them
    /// into an unrelated value, which is what their documented contract promises.
    func testSCValFactoriesRejectNonAsciiNumericCharacters() {
        for text in ["\u{0661}", "\u{0661}\u{0662}", "\u{FF11}\u{FF12}\u{FF13}", "\u{00BD}", "\u{2168}"] {
            assertFactoriesReject(text)
        }
    }

    private func assertFactoriesReject(_ text: String,
                                       file: StaticString = #filePath, line: UInt = #line) {
        let factories: [(String, (String) throws -> SCValXDR)] = [
            ("u128", SCValXDR.u128(stringValue:)),
            ("i128", SCValXDR.i128(stringValue:)),
            ("u256", SCValXDR.u256(stringValue:)),
            ("i256", SCValXDR.i256(stringValue:))
        ]
        for (name, factory) in factories {
            XCTAssertThrowsError(try factory(text),
                                 "\(name) accepted \(text.debugDescription)",
                                 file: file, line: line) { error in
                guard case StellarSDKError.invalidArgument(let message) = error else {
                    return XCTFail("\(name): wrong error \(error)", file: file, line: line)
                }
                XCTAssertTrue(message.contains("Invalid number string"),
                              "\(name): unexpected message \(message)", file: file, line: line)
            }
        }
    }
}
