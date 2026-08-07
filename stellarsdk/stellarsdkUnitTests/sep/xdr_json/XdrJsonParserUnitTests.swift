//
//  XdrJsonParserUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class XdrJsonParserUnitTests: XCTestCase {

    private func parse(_ text: String) throws -> XdrJsonValue {
        try XdrJsonParser.parse(text)
    }

    private func assertMalformed(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try parse(text), "accepted \(text)", file: file, line: line) { error in
            guard case XdrJsonError.malformedJson = error else {
                return XCTFail("wrong error for \(text): \(error)", file: file, line: line)
            }
        }
    }

    // MARK: - Scalars

    func testLiteralsParse() throws {
        XCTAssertEqual(try parse("null"), .null)
        XCTAssertEqual(try parse("true"), .bool(true))
        XCTAssertEqual(try parse("false"), .bool(false))
    }

    func testTruncatedLiteralIsRejected() {
        assertMalformed("tru")
        assertMalformed("nul")
        assertMalformed("fals")
    }

    func testNumbersKeepTheirSourceLiteral() throws {
        XCTAssertEqual(try parse("0"), .number("0"))
        XCTAssertEqual(try parse("-0"), .number("-0"))
        XCTAssertEqual(try parse("1e10"), .number("1e10"))
        XCTAssertEqual(try parse("1.50"), .number("1.50"))
        // A value beyond 53 bits of mantissa survives verbatim rather than being rounded.
        XCTAssertEqual(try parse("9223372036854775807"), .number("9223372036854775807"))
    }

    func testMalformedNumbersAreRejected() {
        for text in ["01", "+1", ".5", "1.", "1e", "1e+", "-", "0x10", "--1", "1..2"] {
            assertMalformed(text)
        }
    }

    // MARK: - Strings

    func testStringEscapesAreDecoded() throws {
        XCTAssertEqual(try parse("\"a\\\"b\""), .string("a\"b"))
        XCTAssertEqual(try parse("\"a\\\\b\""), .string("a\\b"))
        XCTAssertEqual(try parse("\"a\\/b\""), .string("a/b"))
        XCTAssertEqual(try parse("\"\\b\\f\\n\\r\\t\""), .string("\u{08}\u{0C}\n\r\t"))
        XCTAssertEqual(try parse("\"\\u0041\""), .string("A"))
        XCTAssertEqual(try parse("\"\\u00E9\""), .string("é"))
    }

    func testSurrogatePairIsCombined() throws {
        XCTAssertEqual(try parse("\"\\ud83d\\ude00\""), .string("\u{1F600}"))
    }

    func testUnpairedSurrogateIsRejected() {
        assertMalformed("\"\\ud83d\"")
        assertMalformed("\"\\ud83dA\"")
        assertMalformed("\"\\udc00\"")
        assertMalformed("\"\\ud83d\\u0041\"")
    }

    func testUnrecognisedEscapeIsRejected() {
        assertMalformed("\"\\q\"")
        assertMalformed("\"\\x41\"")
    }

    func testTrailingBackslashIsRejected() {
        assertMalformed("\"abc\\")
    }

    func testUnescapedControlByteInStringIsRejected() {
        assertMalformed("\"a\u{0001}b\"")
        assertMalformed("\"a\nb\"")
    }

    func testShortUnicodeEscapeIsRejected() {
        assertMalformed("\"\\u04\"")
        assertMalformed("\"\\uzzzz\"")
    }

    func testUnterminatedStringIsRejected() {
        assertMalformed("\"abc")
    }

    func testMultiByteUtf8PassesThrough() throws {
        // Two-, three- and four-byte sequences, so the continuation-byte scan is exercised
        // at every length.
        let text = "\u{00E9}\u{2603}\u{1F600}"
        XCTAssertEqual(try parse("\"\(text)\""), .string(text))
    }

    // MARK: - Containers

    func testObjectKeyOrderSurvivesParsing() throws {
        let value = try parse("{\"b\":1,\"a\":2,\"c\":3}")
        guard case .object(let members) = value else { return XCTFail("expected an object") }
        XCTAssertEqual(members.map { $0.key }, ["b", "a", "c"])
    }

    func testEmptyContainersParse() throws {
        XCTAssertEqual(try parse("[]"), .array([]))
        XCTAssertEqual(try parse("{}"), .object([]))
    }

    func testDuplicateKeyIsRejected() {
        XCTAssertThrowsError(try parse("{\"a\":1,\"a\":2}")) { error in
            guard case XdrJsonError.malformedJson(let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertTrue(message.contains("duplicate object key"), message)
            XCTAssertTrue(message.contains("\"a\""), message)
        }
    }

    func testStructuralErrorsAreRejected() {
        for text in ["{", "[", "{\"a\"}", "{\"a\":}", "{a:1}", "[1,]", "{\"a\":1,}", "[1 2]"] {
            assertMalformed(text)
        }
    }

    func testWhitespaceBetweenTokensIsAccepted() throws {
        let value = try parse(" {\n \"a\" : [ 1 , 2 ] \t} \r\n")
        XCTAssertEqual(value, .object([
            XdrJsonMember(key: "a", value: .array([.number("1"), .number("2")]))
        ]))
    }

    func testTrailingContentIsRejected() {
        assertMalformed("{} {}")
        assertMalformed("1 2")
        assertMalformed("null x")
    }

    func testEmptyInputIsRejected() {
        assertMalformed("")
        assertMalformed("   ")
    }

    // MARK: - Depth

    func testNestingAtTheLimitParses() throws {
        let text = String(repeating: "[", count: XdrJson.maxDepth)
            + "1" + String(repeating: "]", count: XdrJson.maxDepth)
        XCTAssertNoThrow(try parse(text))
    }

    func testNestingOneBeyondTheLimitIsRejected() {
        let depth = XdrJson.maxDepth + 1
        let text = String(repeating: "[", count: depth) + "1" + String(repeating: "]", count: depth)
        XCTAssertThrowsError(try parse(text)) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, XdrJson.maxDepth)
        }
    }

    func testObjectNestingUsesTheSameLimit() {
        let atLimit = Self.nestedObjectText(depth: XdrJson.maxDepth)
        XCTAssertNoThrow(try parse(atLimit))

        let beyond = Self.nestedObjectText(depth: XdrJson.maxDepth + 1)
        XCTAssertThrowsError(try parse(beyond)) { error in
            guard case XdrJsonError.recursionLimitExceeded = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    private static func nestedObjectText(depth: Int) -> String {
        String(repeating: "{\"v\":", count: depth) + "1" + String(repeating: "}", count: depth)
    }

    // MARK: - Round trip with the writer

    func testCanonicalTextSurvivesAParseAndWriteRoundTrip() throws {
        let samples = [
            "null",
            "\"tx_success\"",
            "{\"min_time\":\"0\",\"max_time\":\"1\"}",
            "{\"ip\":{\"i_pv4\":\"01020304\"},\"port\":4851,\"num_failures\":1}",
            "[[],{},[1,2,3]]",
            "{\"code\":\"misc\",\"msg\":\"oops\"}",
            "\"\\\\0\\\\0\\\\0\\\\0\\\\0\""
        ]
        for sample in samples {
            let tree = try parse(sample)
            XCTAssertEqual(try XdrJsonWriter.canonicalString(from: tree), sample)
        }
    }
}
