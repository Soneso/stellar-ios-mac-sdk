//
//  XdrJsonHelperUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class XdrJsonHelperUnitTests: XCTestCase {

    private let type = "SampleXDR"

    private func assertInvalidValue(_ expression: @autoclosure () throws -> Any,
                                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), "", file: file, line: line) { error in
            guard case XdrJsonError.invalidValue = error else {
                return XCTFail("wrong error: \(error)", file: file, line: line)
            }
        }
    }

    // MARK: - Integer emission

    func testThirtyTwoBitIntegersEmitAsNumbers() {
        XCTAssertEqual(XdrJson.int32(0), .number("0"))
        XCTAssertEqual(XdrJson.int32(Int32.min), .number("-2147483648"))
        XCTAssertEqual(XdrJson.int32(Int32.max), .number("2147483647"))
        XCTAssertEqual(XdrJson.uint32(UInt32.max), .number("4294967295"))
    }

    func testSixtyFourBitIntegersEmitAsStrings() {
        XCTAssertEqual(XdrJson.int64(-1), .string("-1"))
        XCTAssertEqual(XdrJson.int64(Int64.min), .string("-9223372036854775808"))
        XCTAssertEqual(XdrJson.int64(Int64.max), .string("9223372036854775807"))
        XCTAssertEqual(XdrJson.uint64(UInt64.max), .string("18446744073709551615"))
    }

    func testBooleanEmitsAsJsonBoolean() {
        XCTAssertEqual(XdrJson.bool(true), .bool(true))
        XCTAssertEqual(XdrJson.bool(false), .bool(false))
    }

    // MARK: - Integer reading

    func testThirtyTwoBitIntegersReadFromNumbers() throws {
        XCTAssertEqual(try XdrJson.int32(.number("-2147483648"), type: type), Int32.min)
        XCTAssertEqual(try XdrJson.uint32(.number("4294967295"), type: type), UInt32.max)
    }

    func testThirtyTwoBitIntegerRejectsTheStringForm() {
        XCTAssertThrowsError(try XdrJson.int32(.string("1"), type: type)) { error in
            guard case XdrJsonError.unexpectedType(_, _, let expected, let got) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(expected, "number")
            XCTAssertEqual(got, "string")
        }
    }

    func testSixtyFourBitIntegersReadFromStrings() throws {
        XCTAssertEqual(try XdrJson.int64(.string("-9223372036854775808"), type: type), Int64.min)
        XCTAssertEqual(try XdrJson.uint64(.string("18446744073709551615"), type: type), UInt64.max)
    }

    func testSixtyFourBitIntegersAlsoAcceptANumberForVersionOneCompatibility() throws {
        XCTAssertEqual(try XdrJson.int64(.number("-1"), type: type), -1)
        XCTAssertEqual(try XdrJson.uint64(.number("42"), type: type), 42)
    }

    func testNonIntegerLiteralsAreRejected() {
        for literal in ["1.0", "1e10", "+1", " 1", "1 ", "0x10", "", "-", "abc"] {
            assertInvalidValue(try XdrJson.int64(.string(literal), type: type))
        }
    }

    func testOutOfRangeIntegersAreRejected() {
        assertInvalidValue(try XdrJson.int32(.number("2147483648"), type: type))
        assertInvalidValue(try XdrJson.uint32(.number("-1"), type: type))
        assertInvalidValue(try XdrJson.int64(.string("9223372036854775808"), type: type))
        assertInvalidValue(try XdrJson.uint64(.string("-1"), type: type))
    }

    func testBooleanReadingRejectsOtherTypes() {
        XCTAssertThrowsError(try XdrJson.bool(.string("true"), type: type)) { error in
            guard case XdrJsonError.unexpectedType = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    // MARK: - Hex

    func testHexEmissionIsLowercaseAndEmptyDataIsAnEmptyString() {
        XCTAssertEqual(XdrJson.hex(Data()), .string(""))
        XCTAssertEqual(XdrJson.hex(Data([0x00, 0x01, 0xAB, 0xFF])), .string("0001abff"))
    }

    func testFixedWidthHexEmissionChecksTheDeclaredWidth() throws {
        let four = Data([1, 2, 3, 4])
        XCTAssertEqual(try XdrJson.hex(four, expectedLength: 4, type: type), .string("01020304"))
        assertInvalidValue(try XdrJson.hex(four, expectedLength: 32, type: type))
        // WrappedDataN does not validate its own width, so an over-long payload reaches here.
        assertInvalidValue(try XdrJson.hex(Data(repeating: 0, count: 40), expectedLength: 32, type: type))
    }

    func testHexReadingAcceptsLowercaseOnly() throws {
        XCTAssertEqual(try XdrJson.hex(.string("0001abff"), type: type), Data([0x00, 0x01, 0xAB, 0xFF]))
        XCTAssertEqual(try XdrJson.hex(.string(""), type: type), Data())
        assertInvalidValue(try XdrJson.hex(.string("0001ABFF"), type: type))
        assertInvalidValue(try XdrJson.hex(.string("0001Abff"), type: type))
    }

    func testHexReadingRejectsOddLengthAndNonHexDigits() {
        assertInvalidValue(try XdrJson.hex(.string("abc"), type: type))
        assertInvalidValue(try XdrJson.hex(.string("zz"), type: type))
        assertInvalidValue(try XdrJson.hex(.string("0x10"), type: type))
    }

    func testHexReadingChecksTheDeclaredWidth() {
        assertInvalidValue(try XdrJson.hex(.string("0102"), expectedLength: 4, type: type))
        assertInvalidValue(try XdrJson.hex(.string("0102030405"), expectedLength: 4, type: type))
    }

    // MARK: - The string escape ladder

    func testLadderEscapesTheFiveNamedBytes() {
        XCTAssertEqual(XdrJson.escapedText(Data([0x00])), "\\0")
        XCTAssertEqual(XdrJson.escapedText(Data([0x09])), "\\t")
        XCTAssertEqual(XdrJson.escapedText(Data([0x0A])), "\\n")
        XCTAssertEqual(XdrJson.escapedText(Data([0x0D])), "\\r")
        XCTAssertEqual(XdrJson.escapedText(Data([0x5C])), "\\\\")
    }

    func testLadderLeavesPrintableAsciiVerbatim() {
        XCTAssertEqual(XdrJson.escapedText(Data([0x20])), " ")
        XCTAssertEqual(XdrJson.escapedText(Data([0x7E])), "~")
        XCTAssertEqual(XdrJson.escapedText(Data("USD".utf8)), "USD")
    }

    func testLadderEscapesEverythingElseAsLowercaseHex() {
        XCTAssertEqual(XdrJson.escapedText(Data([0x01])), "\\x01")
        XCTAssertEqual(XdrJson.escapedText(Data([0x1F])), "\\x1f")
        XCTAssertEqual(XdrJson.escapedText(Data([0x7F])), "\\x7f")
        XCTAssertEqual(XdrJson.escapedText(Data([0xFF])), "\\xff")
        XCTAssertEqual(XdrJson.escapedText(Data([0xC3])), "\\xc3")
    }

    func testLadderRoundTripsEveryByteValue() throws {
        let all = Data((0...255).map { UInt8($0) })
        let escaped = XdrJson.escapedString(all)
        XCTAssertEqual(try XdrJson.unescapeString(escaped, type: type), all)
    }

    func testLadderAppliesToAStringsUtf8Bytes() {
        XCTAssertEqual(XdrJson.escapedString("é"), .string("\\xc3\\xa9"))
    }

    func testUnescapeRejectsMalformedLadderText() {
        assertInvalidValue(try XdrJson.unescapeString(.string("abc\\"), type: type))
        assertInvalidValue(try XdrJson.unescapeString(.string("\\q"), type: type))
        assertInvalidValue(try XdrJson.unescapeString(.string("\\xFF"), type: type))
        assertInvalidValue(try XdrJson.unescapeString(.string("\\xC3"), type: type))
        assertInvalidValue(try XdrJson.unescapeString(.string("\\x1"), type: type))
        assertInvalidValue(try XdrJson.unescapeString(.string("\\x"), type: type))
    }

    func testUnescapeRejectsARawByteTheLadderWouldHaveEscaped() {
        assertInvalidValue(try XdrJson.unescapeString(.string("é"), type: type))
        assertInvalidValue(try XdrJson.unescapeString(.string("a\u{0001}b"), type: type))
    }

    func testUnescapedTextRequiresValidUtf8() throws {
        XCTAssertEqual(try XdrJson.unescapedText(.string("\\xc3\\xa9"), type: type), "é")
        assertInvalidValue(try XdrJson.unescapedText(.string("\\xc3"), type: type))
    }

    // MARK: - Objects

    private let declared: [XdrJson.DeclaredKey] = ["min_time", "max_time"]

    func testObjectReadsTheDeclaredKeys() throws {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "max_time", value: .string("1"))
        ])
        let members = try XdrJson.object(value, type: type, keys: declared)
        XCTAssertEqual(members.map { $0.key }, ["min_time", "max_time"])
    }

    func testObjectStripsTheSchemaProperty() throws {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: XdrJson.schemaKey, value: .string("https://example.com/s.json")),
            XdrJsonMember(key: "min_time", value: .string("0"))
        ])
        let members = try XdrJson.object(value, type: type, keys: declared)
        XCTAssertEqual(members.map { $0.key }, ["min_time"])
    }

    func testObjectRejectsADocumentCarryingOnlyTheSchemaProperty() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: XdrJson.schemaKey, value: .string("https://example.com/s.json"))
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: declared)) { error in
            guard case XdrJsonError.invalidValue(_, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(message, "object carries no members beyond \"$schema\"")
        }
    }

    func testEmptyObjectIsRejectedWithoutBlamingTheSchemaProperty() {
        XCTAssertThrowsError(try XdrJson.object(.object([]), type: type, keys: declared)) { error in
            guard case XdrJsonError.invalidValue(_, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(message, "object carries no members")
        }
    }

    func testObjectRejectsADuplicateKeyInAHandBuiltTree() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .number("1")),
            XdrJsonMember(key: "min_time", value: .number("2"))
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: declared)) { error in
            guard case XdrJsonError.duplicateKey(let reported, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(reported, type)
            XCTAssertEqual(key, "min_time")
        }
    }

    func testObjectRejectsANonObject() {
        XCTAssertThrowsError(try XdrJson.object(.array([]), type: type, keys: declared)) { error in
            guard case XdrJsonError.unexpectedType(_, _, let expected, let got) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(expected, "object")
            XCTAssertEqual(got, "array")
        }
    }

    // MARK: - Unknown keys

    func testUnknownKeyIsRejectedNamingTheKeyAndTheType() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "max_time", value: .string("1")),
            XdrJsonMember(key: "foo", value: .number("1"))
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: declared)) { error in
            guard case XdrJsonError.unknownField(let reported, let keys, let declared) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(reported, type)
            XCTAssertEqual(keys, ["foo"])
            XCTAssertEqual(declared, ["min_time", "max_time"])
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "SampleXDR: unknown key \"foo\"; declared keys are min_time, max_time")
        }
    }

    func testEveryUnknownKeyIsNamed() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "foo", value: .null),
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "bar", value: .null)
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: declared)) { error in
            guard case XdrJsonError.unknownField(_, let keys, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(keys, ["foo", "bar"], "every undeclared key is reported, in document order")
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "SampleXDR: unknown keys \"foo\", \"bar\"; " +
                           "declared keys are min_time, max_time")
        }
    }

    func testSchemaIsStrippedBeforeTheUnknownKeyCheckAndDoesNotExcuseOthers() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: XdrJson.schemaKey, value: .string("https://example.com/s.json")),
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "foo", value: .null)
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: declared)) { error in
            guard case XdrJsonError.unknownField(_, let keys, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(keys, ["foo"],
                           "$schema is accepted, so it must not be reported as an unknown key")
        }
    }

    func testUnknownKeyPreviewIsNeutralisedBeforeItReachesTheMessage() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "\u{1B}[31mfoo", value: .null)
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: declared)) { error in
            guard case XdrJsonError.unknownField(_, let keys, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(keys, ["\u{1B}[31mfoo"], "the payload carries the key verbatim")

            let message = (error as? XdrJsonError)?.message ?? ""
            XCTAssertTrue(message.contains("\\x1b[31mfoo"), message)
            XCTAssertFalse(message.contains("\u{1B}"), "the raw escape byte reached the message")
        }
    }

    func testDeclaredKeyAliasCountsAsThatDeclaredKey() throws {
        let keys: [XdrJson.DeclaredKey] = [XdrJson.DeclaredKey("type", alias: "type_"), "msg"]
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "type_", value: .string("misc")),
            XdrJsonMember(key: "msg", value: .string("oops"))
        ])
        let members = try XdrJson.object(value, type: type, keys: keys)
        XCTAssertEqual(members.map { $0.key }, ["type_", "msg"])
    }

    /// The reference implementation reads the two spellings as one serde field, so a
    /// document carrying both is a duplicate rather than two fields. Probed against the
    /// pinned build: encoding DontHave with both "type" and "type_" fails with
    /// "duplicate field `type`".
    func testSupplyingBothSpellingsOfAnAliasedKeyIsADuplicate() {
        let keys: [XdrJson.DeclaredKey] = [XdrJson.DeclaredKey("type", alias: "type_"), "msg"]
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "type", value: .string("misc")),
            XdrJsonMember(key: "type_", value: .string("misc")),
            XdrJsonMember(key: "msg", value: .string("oops"))
        ])
        XCTAssertThrowsError(try XdrJson.object(value, type: type, keys: keys)) { error in
            guard case XdrJsonError.duplicateKey(let reported, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(reported, type)
            XCTAssertEqual(key, "type")
        }
    }

    func testUnionArmObjectsAreNotSubjectToTheDeclaredKeyCheck() throws {
        let value = XdrJsonValue.object([XdrJsonMember(key: "i_pv4", value: .string("01020304"))])
        let member = try XdrJson.singleKeyObject(value, type: type)
        XCTAssertEqual(member.key, "i_pv4")
    }

    // MARK: - Union arms

    func testSingleKeyObjectReadsTheArm() throws {
        let value = XdrJsonValue.object([XdrJsonMember(key: "i_pv4", value: .string("01020304"))])
        let member = try XdrJson.singleKeyObject(value, type: type)
        XCTAssertEqual(member.key, "i_pv4")
        XCTAssertEqual(member.value, .string("01020304"))
    }

    func testSingleKeyObjectIgnoresTheSchemaProperty() throws {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: XdrJson.schemaKey, value: .string("https://example.com/s.json")),
            XdrJsonMember(key: "tx", value: .object([]))
        ])
        XCTAssertEqual(try XdrJson.singleKeyObject(value, type: type).key, "tx")
    }

    func testSingleKeyObjectRejectsMoreThanOneKey() {
        let value = XdrJsonValue.object([
            XdrJsonMember(key: "a", value: .null),
            XdrJsonMember(key: "b", value: .null)
        ])
        XCTAssertThrowsError(try XdrJson.singleKeyObject(value, type: type)) { error in
            guard case XdrJsonError.invalidValue(_, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertTrue(message.contains("\"a\""), message)
            XCTAssertTrue(message.contains("\"b\""), message)
        }
    }

    // MARK: - Fields

    func testFieldReadsARequiredKey() throws {
        let members = [XdrJsonMember(key: "fee", value: .number("100"))]
        XCTAssertEqual(try XdrJson.field(members, key: "fee", type: type), .number("100"))
    }

    func testFieldReportsAMissingKeyByName() {
        XCTAssertThrowsError(try XdrJson.field([], key: "fee", type: type)) { error in
            guard case XdrJsonError.missingField(let reported, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(reported, type)
            XCTAssertEqual(key, "fee")
        }
    }

    func testFieldReadsEitherSpellingOfAnAliasedKey() throws {
        let key = XdrJson.DeclaredKey("type", alias: "type_")
        XCTAssertEqual(
            try XdrJson.field([XdrJsonMember(key: "type", value: .string("misc"))],
                              key: key, type: type),
            .string("misc"))
        XCTAssertEqual(
            try XdrJson.field([XdrJsonMember(key: "type_", value: .string("misc"))],
                              key: key, type: type),
            .string("misc"))
    }

    func testFieldReportsAMissingAliasedKeyUnderItsCanonicalName() {
        let key = XdrJson.DeclaredKey("type", alias: "type_")
        XCTAssertThrowsError(try XdrJson.field([], key: key, type: type)) { error in
            guard case XdrJsonError.missingField(_, let reported) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(reported, "type")
        }
    }

    func testOptionalFieldMayBeNullButItsKeyMustExist() throws {
        let members = [XdrJsonMember(key: "time_bounds", value: .null)]
        XCTAssertEqual(try XdrJson.field(members, key: "time_bounds", type: type), .null)
        XCTAssertThrowsError(try XdrJson.field([], key: "time_bounds", type: type))
    }

    // MARK: - Arrays and optionals

    func testArrayReadingRejectsANonArray() {
        XCTAssertThrowsError(try XdrJson.array(.object([]), type: type, key: "operations")) { error in
            guard case XdrJsonError.unexpectedType(_, let key, let expected, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(key, "operations")
            XCTAssertEqual(expected, "array")
        }
    }

    func testEmptyArrayEmitsAsAnEmptyArray() throws {
        XCTAssertEqual(XdrJson.array([]), .array([]))
        XCTAssertEqual(try XdrJson.array(.array([]), type: type), [])
    }

    func testAbsentOptionalEmitsAsNull() {
        XCTAssertEqual(XdrJson.optional(nil), .null)
        XCTAssertEqual(XdrJson.optional(.string("x")), .string("x"))
    }

    // MARK: - Wide integers

    func testWideDecimalEmission() {
        XCTAssertEqual(XdrJson.wideDecimal(Data(repeating: 0xFF, count: 16), signed: false),
                       .string("340282366920938463463374607431768211455"))
        XCTAssertEqual(XdrJson.wideDecimal(Data(repeating: 0xFF, count: 16), signed: true),
                       .string("-1"))
    }

    func testWideDecimalReading() throws {
        let bytes = try XdrJson.wideDecimal(.string("340282366920938463463374607431768211455"),
                                            bitSize: 128, signed: false, type: type)
        XCTAssertEqual(bytes, Data(repeating: 0xFF, count: 16))
    }

    func testWideDecimalRejectsOutOfRangeAndNonIntegerText() {
        assertInvalidValue(try XdrJson.wideDecimal(.string("340282366920938463463374607431768211456"),
                                                   bitSize: 128, signed: false, type: type))
        assertInvalidValue(try XdrJson.wideDecimal(.string("1.0"), bitSize: 128, signed: false, type: type))
        assertInvalidValue(try XdrJson.wideDecimal(.string("-1"), bitSize: 128, signed: false, type: type))
    }

    // MARK: - Depth

    func testDepthValidationAcceptsTheLimitAndRejectsOneBeyond() {
        XCTAssertNoThrow(try XdrJson.validateDepth(
            XdrJsonWriterUnitTests.nestedArray(depth: XdrJson.maxDepth)))
        XCTAssertThrowsError(try XdrJson.validateDepth(
            XdrJsonWriterUnitTests.nestedArray(depth: XdrJson.maxDepth + 1))) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, XdrJson.maxDepth)
        }
    }

    func testDepthValidationCountsContainersOnly() {
        let wide = XdrJsonValue.array((0..<1000).map { .number("\($0)") })
        XCTAssertNoThrow(try XdrJson.validateDepth(wide))
    }

    func testDepthValidationSeesEveryBranch() {
        let deep = XdrJsonWriterUnitTests.nestedObject(depth: XdrJson.maxDepth + 1)
        let tree = XdrJsonValue.array([.number("1"), deep])
        XCTAssertThrowsError(try XdrJson.validateDepth(tree))
    }

    // MARK: - Diagnostics

    func testPreviewTruncatesLongValues() {
        let long = String(repeating: "a", count: 200)
        let preview = XdrJson.preview(long)
        XCTAssertEqual(preview.count, XdrJson.previewLimit + 3)
        XCTAssertTrue(preview.hasSuffix("..."))
    }

    func testPreviewNeutralisesControlBytes() {
        XCTAssertEqual(XdrJson.preview("\u{1B}[31mred"), "\\x1b[31mred")
        XCTAssertEqual(XdrJson.preview("a\nb"), "a\\x0ab")
        XCTAssertEqual(XdrJson.preview("a\u{7F}b"), "a\\x7fb")
    }

    func testFailRaisesAnInvalidValueNamingTheTypeAndKey() {
        XCTAssertThrowsError(try XdrJson.fail(type: type, key: "asset", detail: "unsupported")) { error in
            guard case XdrJsonError.invalidValue(let reported, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(reported, type)
            XCTAssertEqual(key, "asset")
            XCTAssertEqual(message, "unsupported")
        }
    }

    func testErrorMessagesNameTheTypeAndKey() {
        XCTAssertEqual(XdrJsonError.missingField(type: "TimeBoundsXDR", key: "min_time").message,
                       "TimeBoundsXDR: missing key \"min_time\"")
        XCTAssertEqual(XdrJsonError.unexpectedType(type: "TimeBoundsXDR", key: "min_time",
                                                   expected: "string", got: "array").message,
                       "TimeBoundsXDR.min_time: expected string, got array")
        XCTAssertEqual(XdrJsonError.unknownUnionArm(type: "MemoXDR", key: "nope").message,
                       "MemoXDR: unknown union arm \"nope\"")
        XCTAssertEqual(XdrJsonError.unknownField(type: "TimeBoundsXDR", keys: ["foo"],
                                                 declared: ["min_time", "max_time"]).message,
                       "TimeBoundsXDR: unknown key \"foo\"; declared keys are min_time, max_time")
        XCTAssertEqual(XdrJsonError.recursionLimitExceeded(limit: 128).message,
                       "nesting exceeds the limit of 128 containers")
    }

    // MARK: - Tree conveniences

    func testMemberLookupAndTypeNames() {
        let value = XdrJsonValue.object([XdrJsonMember(key: "a", value: .number("1"))])
        XCTAssertEqual(value.member("a"), .number("1"))
        XCTAssertNil(value.member("b"))
        XCTAssertNil(XdrJsonValue.null.member("a"))
        XCTAssertTrue(XdrJsonValue.null.isNull)
        XCTAssertFalse(value.isNull)
        XCTAssertEqual(XdrJsonValue.bool(true).typeName, "boolean")
        XCTAssertEqual(XdrJsonValue.number("1").typeName, "number")
        XCTAssertEqual(XdrJsonValue.string("").typeName, "string")
        XCTAssertEqual(XdrJsonValue.array([]).typeName, "array")
        XCTAssertEqual(value.typeName, "object")
        XCTAssertEqual(XdrJsonValue.null.typeName, "null")
    }
}
