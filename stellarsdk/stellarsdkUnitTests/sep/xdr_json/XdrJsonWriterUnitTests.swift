//
//  XdrJsonWriterUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class XdrJsonWriterUnitTests: XCTestCase {

    private func write(_ value: XdrJsonValue) throws -> String {
        try XdrJsonWriter.canonicalString(from: value)
    }

    // MARK: - Scalars

    func testNullBooleanAndNumberRenderAsJsonLiterals() throws {
        XCTAssertEqual(try write(.null), "null")
        XCTAssertEqual(try write(.bool(true)), "true")
        XCTAssertEqual(try write(.bool(false)), "false")
        XCTAssertEqual(try write(.number("0")), "0")
        XCTAssertEqual(try write(.number("-2147483648")), "-2147483648")
        XCTAssertEqual(try write(.number("4294967295")), "4294967295")
    }

    func testStringRendersQuoted() throws {
        XCTAssertEqual(try write(.string("")), "\"\"")
        XCTAssertEqual(try write(.string("tx_success")), "\"tx_success\"")
    }

    // MARK: - Canonical form

    func testObjectKeepsInsertionOrderRatherThanSorting() throws {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "max_time", value: .string("1"))
        ])
        XCTAssertEqual(try write(value), "{\"min_time\":\"0\",\"max_time\":\"1\"}")

        let reversed = XdrJsonValue.object([
            XdrJsonMember(key: "max_time", value: .string("1")),
            XdrJsonMember(key: "min_time", value: .string("0"))
        ])
        XCTAssertEqual(try write(reversed), "{\"max_time\":\"1\",\"min_time\":\"0\"}")
    }

    func testOutputCarriesNoInsignificantWhitespace() throws {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "ip", value: .object([
                XdrJsonMember(key: "i_pv4", value: .string("01020304"))
            ])),
            XdrJsonMember(key: "port", value: .number("4851")),
            XdrJsonMember(key: "num_failures", value: .number("1"))
        ])
        XCTAssertEqual(try write(value),
                       "{\"ip\":{\"i_pv4\":\"01020304\"},\"port\":4851,\"num_failures\":1}")
    }

    func testEmptyContainersRenderAsEmptyLiterals() throws {
        XCTAssertEqual(try write(.array([])), "[]")
        XCTAssertEqual(try write(.object([])), "{}")
    }

    func testArrayElementsAreCommaSeparated() throws {
        XCTAssertEqual(try write(.array([.number("1"), .number("2"), .null])), "[1,2,null]")
    }

    // MARK: - String escaping

    func testQuoteAndBackslashAreEscaped() throws {
        XCTAssertEqual(try write(.string("a\"b")), "\"a\\\"b\"")
        XCTAssertEqual(try write(.string("a\\b")), "\"a\\\\b\"")
    }

    func testSolidusIsNotEscaped() throws {
        XCTAssertEqual(try write(.string("https://example.com/s.json")),
                       "\"https://example.com/s.json\"")
    }

    func testControlBytesAreEscapedAsLowercaseUnicodeEscapes() throws {
        XCTAssertEqual(try write(.string("\u{0000}")), "\"\\u0000\"")
        XCTAssertEqual(try write(.string("\u{001f}")), "\"\\u001f\"")
        XCTAssertEqual(try write(.string("\n")), "\"\\u000a\"")
        XCTAssertEqual(try write(.string("\t")), "\"\\u0009\"")
    }

    func testLadderEscapedTextIsEscapedASecondTimeByTheJsonLayer() throws {
        // An all-NUL AssetCode12 renders as five ladder escapes, which the JSON writer
        // then escapes again, exactly as the reference implementation writes it.
        let ladder = XdrJson.escapedString(Data(repeating: 0x00, count: 5))
        XCTAssertEqual(try write(ladder), "\"\\\\0\\\\0\\\\0\\\\0\\\\0\"")
    }

    func testKeysAreEscapedLikeValues() throws {
        let value = XdrJsonValue.object([XdrJsonMember(key: "a\"b", value: .null)])
        XCTAssertEqual(try write(value), "{\"a\\\"b\":null}")
    }

    // MARK: - Number literal validation

    func testNumberMemberHoldingANonNumberIsRejected() {
        for literal in ["", "oops", "+1", "01", "1.", ".5", "1e", "0x10", " 1", "1 ", "--1"] {
            XCTAssertThrowsError(try write(.number(literal)), "accepted \(literal)") { error in
                guard case XdrJsonError.invalidValue = error else {
                    return XCTFail("wrong error for \(literal): \(error)")
                }
            }
        }
    }

    func testNumberGrammarAcceptsEveryJsonForm() {
        for literal in ["0", "-0", "1", "-1", "1.0", "1e10", "1E10", "1e+10", "1e-10", "0.5", "-0.5"] {
            XCTAssertTrue(XdrJsonWriter.isJsonNumber(literal), "rejected \(literal)")
        }
    }

    // MARK: - Depth

    func testNestingAtTheLimitIsWritten() throws {
        let value = Self.nestedArray(depth: XdrJson.maxDepth)
        let text = try write(value)
        XCTAssertEqual(text.filter { $0 == "[" }.count, XdrJson.maxDepth)
    }

    func testNestingOneBeyondTheLimitIsRejected() {
        let value = Self.nestedArray(depth: XdrJson.maxDepth + 1)
        XCTAssertThrowsError(try write(value)) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, XdrJson.maxDepth)
        }
    }

    func testObjectNestingUsesTheSameLimitAsArrayNesting() throws {
        XCTAssertNoThrow(try write(Self.nestedObject(depth: XdrJson.maxDepth)))
        XCTAssertThrowsError(try write(Self.nestedObject(depth: XdrJson.maxDepth + 1))) { error in
            guard case XdrJsonError.recursionLimitExceeded = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    static func nestedArray(depth: Int) -> XdrJsonValue {
        var value = XdrJsonValue.number("1")
        for _ in 0..<depth { value = .array([value]) }
        return value
    }

    static func nestedObject(depth: Int) -> XdrJsonValue {
        var value = XdrJsonValue.number("1")
        for _ in 0..<depth { value = .object([XdrJsonMember(key: "v", value: value)]) }
        return value
    }
}
