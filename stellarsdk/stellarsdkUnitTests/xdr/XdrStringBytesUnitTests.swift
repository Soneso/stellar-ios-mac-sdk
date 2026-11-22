//
//  XdrStringBytesUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The memo text, the `SCVal` string and the invoked function name keep the bytes they were
/// decoded from; every other XDR string reads as strict UTF-8 that keeps a leading byte order
/// mark. A message shows an `SCVal` string as its text or as escaped bytes.
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

    // MARK: - SCVal string and function name bytes

    func testSCValStringRoundTripsItsBytes() throws {
        let cases: [(base64: String, bytes: Data)] = [
            ("AAAADgAAAAb//iBhYmMAAA==", invalid),
            ("AAAADgAAAATvu79h", bom),
            ("AAAADgAAAAPDqTEA", valid),
        ]
        for testCase in cases {
            let value = try SCValXDR.fromXdr(base64: testCase.base64)
            guard case .string(let bytes) = value else {
                return XCTFail("\(testCase.base64) decoded to \(value)")
            }
            XCTAssertEqual(bytes, testCase.bytes)
            XCTAssertEqual(value.xdrEncoded, testCase.base64)
        }
    }

    func testFunctionNameRoundTripsItsBytes() throws {
        let base64 = "AAAAAQcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHAAAABv/+IGFiYwAAAAAAAA=="
        let call = try XDRDecoder.decode(InvokeContractArgsXDR.self, data: [UInt8](try XCTUnwrap(Data(base64Encoded: base64))))
        XCTAssertEqual(call.functionName, invalid)
        XCTAssertNil(call.functionNameString)
        XCTAssertEqual(call.xdrEncoded, base64)
    }

    func testSCValStringAndFunctionNameXdrJsonAndTxRepCarryTheBytesBothWays() throws {
        let value = SCValXDR.string(invalid)
        let json = #"{"string":"\\xff\\xfe abc"}"#
        XCTAssertEqual(try value.toXdrJson(), json)
        XCTAssertEqual(try SCValXDR.fromXdrJson(json).xdrEncoded, value.xdrEncoded)
        var lines: [String] = []
        try value.toTxRep(prefix: "v", lines: &lines)
        XCTAssertEqual(lines.last, #"v.str: "\xff\xfe abc""#)
        XCTAssertEqual(try SCValXDR.fromTxRep(TxRepHelper.parse(lines.joined(separator: "\n")), prefix: "v").xdrEncoded,
                       value.xdrEncoded)

        let call = InvokeContractArgsXDR(contractAddress: contract, functionName: invalid, args: [])
        let callJson = #"{"contract_address":"CADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQP5KR","function_name":"\\xff\\xfe abc","args":[]}"#
        XCTAssertEqual(try call.toXdrJson(), callJson)
        XCTAssertEqual(try InvokeContractArgsXDR.fromXdrJson(callJson).xdrEncoded, call.xdrEncoded)
        var callLines: [String] = []
        try call.toTxRep(prefix: "c", lines: &callLines)
        XCTAssertTrue(callLines.contains(#"c.functionName: "\xff\xfe abc""#), callLines.joined(separator: "\n"))
        XCTAssertEqual(try InvokeContractArgsXDR.fromTxRep(TxRepHelper.parse(callLines.joined(separator: "\n")), prefix: "c").xdrEncoded,
                       call.xdrEncoded)
    }

    func testSCValStringAndFunctionNameFactoriesStoreTheUTF8Bytes() {
        guard case .string(let bytes) = SCValXDR.string("\u{FEFF}a") else {
            return XCTFail("the factory must build the string arm")
        }
        XCTAssertEqual(bytes, bom)
        XCTAssertEqual(InvokeContractArgsXDR(contractAddress: contract, functionName: "\u{FEFF}a", args: []).functionName, bom)
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
            XCTAssertEqual(SCValXDR.string(testCase.bytes).string.map { Array($0.utf8) }, expected, label)
            let call = InvokeContractArgsXDR(contractAddress: contract, functionName: testCase.bytes, args: [])
            XCTAssertEqual(call.functionNameString.map { Array($0.utf8) }, expected, label)
        }
        XCTAssertNil(MemoXDR.id(1).textString)
        XCTAssertNil(SCValXDR.symbol("a").string)
    }

    @available(*, deprecated)
    func testDeprecatedExecutableTagReadsAsExecutableTagString() {
        XCTAssertEqual(SCValXDR.executableTag(bom).executableTag.map { Array($0.utf8) }, [0xef, 0xbb, 0xbf, 0x61])
        XCTAssertEqual(SCValXDR.executableTag(doubleBom).executableTag.map { Array($0.utf8) },
                       [0xef, 0xbb, 0xbf, 0xef, 0xbb, 0xbf, 0x61])
        XCTAssertNil(SCValXDR.executableTag(Data([0xff, 0xfe, 0x61])).executableTag)
    }

    // MARK: - Text positions keep a leading byte order mark

    func testSymbolKeepsALeadingByteOrderMark() throws {
        let value = try SCValXDR.fromXdr(base64: "AAAADwAAAATvu79h")
        guard case .symbol(let text) = value else {
            return XCTFail("AAAADwAAAATvu79h decoded to \(value)")
        }
        XCTAssertEqual(Array(text.utf8), [UInt8](bom))
        XCTAssertEqual(value.xdrEncoded, "AAAADwAAAATvu79h")
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
        let callJson = #"{"contract_address":"CADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQP5KR","function_name":"\\xef\\xbb\\xbfa","args":[]}"#
        XCTAssertEqual(try call.toXdrJson(), callJson)
        XCTAssertEqual(try InvokeContractArgsXDR.fromXdrJson(callJson).xdrEncoded, call.xdrEncoded)
        var lines: [String] = []
        try call.toTxRep(prefix: "c", lines: &lines)
        XCTAssertTrue(lines.contains(#"c.functionName: "\xef\xbb\xbfa""#), lines.joined(separator: "\n"))
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

    // MARK: - Message text

    func testMessageTextEscapesTheStringText() {
        XCTAssertEqual(SCValXDR.string("a\\b\"c\nd").messageText, #"string("a\\b\"c\nd")"#)
        XCTAssertEqual(SCValXDR.string(Data([0xff, 0x5c, 0x22, 0x0a, 0x00])).messageText, #"string("\xff\\\"\n\x00")"#)
    }

    func testMessageTextIsTheDefaultDescriptionWithTheStringsAtAnyDepth() {
        let instance = { (storage: [SCMapEntryXDR]?) in
            SCValXDR.contractInstance(SCContractInstanceXDR(executable: .token, storage: storage))
        }
        let cases: [(value: SCValXDR, text: String)] = [
            (.vec([.string("a")]), #"vec(Optional([stellarsdk.SCValXDR.string("a")]))"#),
            (.map([SCMapEntryXDR(key: .string("k"), val: .string("v"))]),
             #"map(Optional([stellarsdk.SCMapEntryXDR(key: stellarsdk.SCValXDR.string("k"), val: stellarsdk.SCValXDR.string("v"))]))"#),
            (.vec([.vec([.string("a")]), .u32(1)]),
             #"vec(Optional([stellarsdk.SCValXDR.vec(Optional([stellarsdk.SCValXDR.string("a")])), stellarsdk.SCValXDR.u32(1)]))"#),
            (.vec([.map([SCMapEntryXDR(key: .u32(1), val: .string("x"))])]),
             #"vec(Optional([stellarsdk.SCValXDR.map(Optional([stellarsdk.SCMapEntryXDR(key: stellarsdk.SCValXDR.u32(1), val: stellarsdk.SCValXDR.string("x"))]))]))"#),
            (.vec([.symbol("s"), .u32(7)]), #"vec(Optional([stellarsdk.SCValXDR.symbol("s"), stellarsdk.SCValXDR.u32(7)]))"#),
            (.vec([]), "vec(Optional([]))"),
            (.vec(nil), "vec(nil)"),
            (.map(nil), "map(nil)"),
            (instance([SCMapEntryXDR(key: .symbol("k"), val: .string("v"))]),
             #"contractInstance(stellarsdk.SCContractInstanceXDR(executable: stellarsdk.ContractExecutableXDR.token, storage: Optional([stellarsdk.SCMapEntryXDR(key: stellarsdk.SCValXDR.symbol("k"), val: stellarsdk.SCValXDR.string("v"))])))"#),
            (instance(nil), "contractInstance(stellarsdk.SCContractInstanceXDR(executable: stellarsdk.ContractExecutableXDR.token, storage: nil))"),
            (.u32(7), "u32(7)"),
            (.vec([.string(Data([0xff]))]), #"vec(Optional([stellarsdk.SCValXDR.string("\xff")]))"#),
            (.map([SCMapEntryXDR(key: .string(Data([0xff])), val: .vec([.string(Data([0xfe]))]))]),
             #"map(Optional([stellarsdk.SCMapEntryXDR(key: stellarsdk.SCValXDR.string("\xff"), val: stellarsdk.SCValXDR.vec(Optional([stellarsdk.SCValXDR.string("\xfe")])))]))"#),
            (instance([SCMapEntryXDR(key: .symbol("k"), val: .string(Data([0xff])))]),
             #"contractInstance(stellarsdk.SCContractInstanceXDR(executable: stellarsdk.ContractExecutableXDR.token, storage: Optional([stellarsdk.SCMapEntryXDR(key: stellarsdk.SCValXDR.symbol("k"), val: stellarsdk.SCValXDR.string("\xff"))])))"#),
        ]
        for testCase in cases {
            XCTAssertEqual(testCase.value.messageText, testCase.text)
        }
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
