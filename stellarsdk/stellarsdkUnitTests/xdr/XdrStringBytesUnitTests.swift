//
//  XdrStringBytesUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The memo text keeps the bytes it was decoded from; every other XDR string reads as strict
/// UTF-8 that keeps a leading byte order mark.
final class XdrStringBytesUnitTests: XCTestCase {

    private let invalid = Data([0xff, 0xfe, 0x20, 0x61, 0x62, 0x63])
    private let bom = Data([0xef, 0xbb, 0xbf, 0x61])
    private let doubleBom = Data([0xef, 0xbb, 0xbf, 0xef, 0xbb, 0xbf, 0x61])
    private let trailingBom = Data([0x61, 0xef, 0xbb, 0xbf])
    private let valid = Data([0xc3, 0xa9, 0x31])
    private let contract = SCAddressXDR.contract(WrappedData32(Data(repeating: 7, count: 32)))

    // MARK: - Memo text bytes

    func testMemoTextRoundTripsItsBytes() throws {
        let cases: [(base64: String, bytes: Data)] = [
            ("AAAAAQAAAAb//iBhYmMAAA==", invalid),
            ("AAAAAQAAAATvu79h", bom),
            ("AAAAAQAAAAfvu7/vu79hAA==", doubleBom),
        ]
        for testCase in cases {
            let memo = try XDRDecoder.decode(MemoXDR.self, data: [UInt8](try XCTUnwrap(Data(base64Encoded: testCase.base64))))
            guard case .text(let bytes) = memo else {
                return XCTFail("\(testCase.base64) decoded to \(memo)")
            }
            XCTAssertEqual(bytes, testCase.bytes)
            XCTAssertEqual(memo.xdrEncoded, testCase.base64)
        }
    }

    func testMemoTextXdrJsonAndTxRepCarryTheBytesBothWays() throws {
        let cases: [(bytes: Data, json: String, line: String)] = [
            (invalid, #"{"text":"\\xff\\xfe abc"}"#, #"m.text: "\xff\xfe abc""#),
            (bom, #"{"text":"\\xef\\xbb\\xbfa"}"#, #"m.text: "\xef\xbb\xbfa""#),
        ]
        for testCase in cases {
            let memo = MemoXDR.text(testCase.bytes)
            XCTAssertEqual(try memo.toXdrJson(), testCase.json)
            XCTAssertEqual(try MemoXDR.fromXdrJson(testCase.json).xdrEncoded, memo.xdrEncoded)

            var lines: [String] = []
            try memo.toTxRep(prefix: "m", lines: &lines)
            XCTAssertEqual(lines.last, testCase.line)
            let map = TxRepHelper.parse(lines.joined(separator: "\n"))
            XCTAssertEqual(try MemoXDR.fromTxRep(map, prefix: "m").xdrEncoded, memo.xdrEncoded)
        }
    }

    func testMemoTextFactoryStoresTheUTF8Bytes() {
        guard case .text(let text) = MemoXDR.text("\u{FEFF}a") else {
            return XCTFail("the factory must build the text arm")
        }
        XCTAssertEqual(text, bom)
    }

    // MARK: - Text views

    func testTextViewsKeepEveryByteAndRefuseInvalidUTF8() {
        let cases: [(bytes: Data, text: String?)] = [
            (bom, "\u{FEFF}a"),
            (doubleBom, "\u{FEFF}\u{FEFF}a"),
            (trailingBom, "a\u{FEFF}"),
            (valid, "\u{00E9}1"),
            (invalid, nil),
            (Data([0xff, 0xfe, 0x61]), nil),
        ]
        for testCase in cases {
            let expected = testCase.text.map { Array($0.utf8) }
            let label = testCase.bytes.base16EncodedString()
            XCTAssertEqual(MemoXDR.text(testCase.bytes).textString.map { Array($0.utf8) }, expected, label)
            XCTAssertEqual(SCValXDR.executableTag(testCase.bytes).executableTagString.map { Array($0.utf8) }, expected, label)
            let reference = ContractExecutableExternalRefXDR(executableOwner: contract, tag: testCase.bytes)
            XCTAssertEqual(reference.tagString.map { Array($0.utf8) }, expected, label)
        }
        XCTAssertNil(MemoXDR.id(1).textString)
    }

    @available(*, deprecated)
    func testDeprecatedExecutableTagReadsAsExecutableTagString() {
        XCTAssertEqual(SCValXDR.executableTag(bom).executableTag.map { Array($0.utf8) }, [0xef, 0xbb, 0xbf, 0x61])
        XCTAssertEqual(SCValXDR.executableTag(doubleBom).executableTag.map { Array($0.utf8) },
                       [0xef, 0xbb, 0xbf, 0xef, 0xbb, 0xbf, 0x61])
        XCTAssertNil(SCValXDR.executableTag(Data([0xff, 0xfe, 0x61])).executableTag)
    }

    // MARK: - Strict text positions keep a leading byte order mark

    func testStringAndSymbolKeepALeadingByteOrderMark() throws {
        let cases: [(base64: String, symbol: Bool)] = [
            ("AAAADgAAAATvu79h", false),
            ("AAAADwAAAATvu79h", true),
        ]
        for testCase in cases {
            let value = try SCValXDR.fromXdr(base64: testCase.base64)
            switch value {
            case .string(let text) where !testCase.symbol:
                XCTAssertEqual(Array(text.utf8), [UInt8](bom))
            case .symbol(let text) where testCase.symbol:
                XCTAssertEqual(Array(text.utf8), [UInt8](bom))
            default:
                XCTFail("\(testCase.base64) decoded to \(value)")
            }
            XCTAssertEqual(value.xdrEncoded, testCase.base64)
        }
    }

    func testStringSymbolAndFunctionNameXdrJsonAndTxRepKeepALeadingByteOrderMark() throws {
        let cases: [(value: SCValXDR, json: String, line: String)] = [
            (.string("\u{FEFF}a"), #"{"string":"\\xef\\xbb\\xbfa"}"#, #"v.str: "\xef\xbb\xbfa""#),
            (.symbol("\u{FEFF}a"), #"{"symbol":"\\xef\\xbb\\xbfa"}"#, #"v.sym: "\xef\xbb\xbfa""#),
        ]
        for testCase in cases {
            XCTAssertEqual(try testCase.value.toXdrJson(), testCase.json)
            XCTAssertEqual(try SCValXDR.fromXdrJson(testCase.json).xdrEncoded, testCase.value.xdrEncoded)

            var lines: [String] = []
            try testCase.value.toTxRep(prefix: "v", lines: &lines)
            XCTAssertEqual(lines.last, testCase.line)
            let map = TxRepHelper.parse(lines.joined(separator: "\n"))
            XCTAssertEqual(try SCValXDR.fromTxRep(map, prefix: "v").xdrEncoded, testCase.value.xdrEncoded)
        }

        let call = InvokeContractArgsXDR(contractAddress: contract, functionName: "\u{FEFF}a", args: [])
        XCTAssertEqual(try InvokeContractArgsXDR.fromXdrJson(try call.toXdrJson()).xdrEncoded, call.xdrEncoded)
        var lines: [String] = []
        try call.toTxRep(prefix: "c", lines: &lines)
        let map = TxRepHelper.parse(lines.joined(separator: "\n"))
        XCTAssertEqual(try InvokeContractArgsXDR.fromTxRep(map, prefix: "c").xdrEncoded, call.xdrEncoded)
    }

    func testStringPositionsKeepALeadingByteOrderMark() throws {
        XCTAssertEqual(Array(try XDRDecoder.decode(String.self, data: [0, 0, 0, 4] + [UInt8](bom)).utf8), [UInt8](bom))
        let meta = SCMetaV0XDR(key: "\u{FEFF}k", value: "\u{FEFF}\u{FEFF}v")
        let decoded = try XDRDecoder.decode(SCMetaV0XDR.self, data: try XDREncoder.encode(meta))
        XCTAssertEqual(Array(decoded.key.utf8), [0xef, 0xbb, 0xbf, 0x6b])
        XCTAssertEqual(Array(decoded.value.utf8), [0xef, 0xbb, 0xbf, 0xef, 0xbb, 0xbf, 0x76])
    }

    func testTxRepUnescapeKeepsALeadingByteOrderMark() throws {
        XCTAssertEqual(Array(try TxRepHelper.unescapeString(#""\xef\xbb\xbfa""#).utf8), [UInt8](bom))
        XCTAssertEqual(Array(try TxRepHelper.unescapeString(#""a\xef\xbb\xbf""#).utf8), [UInt8](trailingBom))
        XCTAssertEqual(try TxRepHelper.decodeMemoTextBytes(#""\xff\xfe abc""#), invalid)
        XCTAssertEqual(try TxRepHelper.decodeMemoTextBytes(#""é1""#), valid)
    }

    func testXdrJsonUnescapedTextKeepsALeadingByteOrderMark() throws {
        let text = try XdrJson.unescapedText(.string(#"\xef\xbb\xbfa"#), type: "SCMetaV0XDR", key: "key")
        XCTAssertEqual(Array(text.utf8), [UInt8](bom))
    }

    // MARK: - A raw U+FEFF in XDR-JSON input

    func testXdrJsonParserKeepsARawByteOrderMark() throws {
        guard case .string(let start) = try XdrJsonParser.parse("\"\u{FEFF}a\""),
              case .string(let middle) = try XdrJsonParser.parse("\"a\u{FEFF}b\"") else {
            return XCTFail("expected JSON strings")
        }
        XCTAssertEqual(start.unicodeScalars.map(\.value), [0xFEFF, 0x61])
        XCTAssertEqual(middle.unicodeScalars.map(\.value), [0x61, 0xFEFF, 0x62])
    }

    /// The escape ladder writes U+FEFF as `\xef\xbb\xbf`, so a raw U+FEFF in a text is refused
    /// like every other raw character outside printable ASCII, and so is the JSON escape `\ufeff`.
    func testARawByteOrderMarkInATextIsRefusedLikeOtherRawCharacters() {
        let cases: [(json: String, decode: (String) throws -> Any, type: String, key: String, text: String)] = [
            ("{\"text\":\"\u{FEFF}a\"}", { try MemoXDR.fromXdrJson($0) }, "MemoXDR", "text", "\u{FEFF}a"),
            ("{\"text\":\"a\u{FEFF}b\"}", { try MemoXDR.fromXdrJson($0) }, "MemoXDR", "text", "a\u{FEFF}b"),
            ("{\"text\":\"\\ufeffa\"}", { try MemoXDR.fromXdrJson($0) }, "MemoXDR", "text", "\u{FEFF}a"),
            ("{\"text\":\"a\\ufeffb\"}", { try MemoXDR.fromXdrJson($0) }, "MemoXDR", "text", "a\u{FEFF}b"),
            ("{\"string\":\"\u{FEFF}a\"}", { try SCValXDR.fromXdrJson($0) }, "SCValXDR", "string", "\u{FEFF}a"),
            ("{\"string\":\"a\u{FEFF}b\"}", { try SCValXDR.fromXdrJson($0) }, "SCValXDR", "string", "a\u{FEFF}b"),
            ("{\"string\":\"\\ufeffa\"}", { try SCValXDR.fromXdrJson($0) }, "SCValXDR", "string", "\u{FEFF}a"),
            ("{\"string\":\"a\\ufeffb\"}", { try SCValXDR.fromXdrJson($0) }, "SCValXDR", "string", "a\u{FEFF}b"),
        ]
        for testCase in cases {
            XCTAssertThrowsError(try testCase.decode(testCase.json), testCase.json) { error in
                guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                    return XCTFail("\(testCase.json): wrong error: \(error)")
                }
                XCTAssertEqual(type, testCase.type, testCase.json)
                XCTAssertEqual(key, testCase.key, testCase.json)
                XCTAssertEqual(Array(message.utf8),
                               Array("byte outside printable ASCII must be written \\xNN: \(testCase.text)".utf8),
                               testCase.json)
            }
        }
    }

    func testAKeyThatCarriesARawByteOrderMarkIsAnUndeclaredKey() {
        let document = "{\"min_time\":\"0\",\"max_time\":\"1\",\"\u{FEFF}max_time\":\"1\"}"

        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.unknownField(let type, let keys, let declared) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(keys.map { Array($0.utf8) }, [Array("\u{FEFF}max_time".utf8)])
            XCTAssertEqual(declared, ["min_time", "max_time"])
        }
    }

    func testANumberThatCarriesARawByteOrderMarkIsRefused() {
        let cases: [(json: String, decode: (String) throws -> Any, type: String, key: String)] = [
            ("{\"id\":\"\u{FEFF}1\"}", { try MemoXDR.fromXdrJson($0) }, "MemoXDR", "id"),
            ("{\"min_time\":\"\u{FEFF}0\",\"max_time\":\"1\"}", { try TimeBoundsXDR.fromXdrJson($0) }, "TimeBoundsXDR", "min_time"),
        ]
        for testCase in cases {
            XCTAssertThrowsError(try testCase.decode(testCase.json), testCase.json) { error in
                guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                    return XCTFail("\(testCase.json): wrong error: \(error)")
                }
                XCTAssertEqual(type, testCase.type, testCase.json)
                XCTAssertEqual(key, testCase.key, testCase.json)
            }
        }
    }
}
