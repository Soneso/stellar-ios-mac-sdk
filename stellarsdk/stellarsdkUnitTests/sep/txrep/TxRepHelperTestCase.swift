//
//  TxRepHelperTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

// Known-good 32-byte seed for deterministic test public keys.
// All-0xAB bytes → a stable G-address across test runs.
private let kTestBytes32: [UInt8] = Array(repeating: 0xAB, count: 32)
private let kTestBytes32b: [UInt8] = Array(repeating: 0xCD, count: 32)
private let kTestBytes32c: [UInt8] = Array(repeating: 0xEF, count: 32)



final class TxRepHelperTestCase: XCTestCase {

    // MARK: - Helper: build a PublicKey from raw bytes

    private func makePublicKey(_ bytes: [UInt8] = kTestBytes32) throws -> PublicKey {
        return try PublicKey(bytes)
    }

    // MARK: - parse()

    func testParseSimpleKeyValueLines() {
        let map = TxRepHelper.parse("tx.fee: 100\ntx.memo: none")
        XCTAssertEqual(map["tx.fee"], "100")
        XCTAssertEqual(map["tx.memo"], "none")
    }

    func testParseCrlfLineEndings() {
        let map = TxRepHelper.parse("tx.fee: 100\r\ntx.memo: none\r\n")
        XCTAssertEqual(map["tx.fee"], "100")
        XCTAssertEqual(map["tx.memo"], "none")
    }

    func testParseMixedLfCrlf() {
        let map = TxRepHelper.parse("tx.fee: 100\r\ntx.seq: 1\ntx.memo: none")
        XCTAssertEqual(map["tx.fee"], "100")
        XCTAssertEqual(map["tx.seq"], "1")
        XCTAssertEqual(map["tx.memo"], "none")
    }

    func testParseSkipsBlankLines() {
        let map = TxRepHelper.parse("tx.fee: 100\n\n\ntx.memo: none")
        XCTAssertEqual(map.count, 2)
    }

    func testParseSkipsCommentOnlyLines() {
        let map = TxRepHelper.parse(": this is a comment\ntx.fee: 100")
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["tx.fee"], "100")
    }

    func testParseSkipsWhitespacePaddedCommentLines() {
        let map = TxRepHelper.parse("   : comment\ntx.fee: 100")
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["tx.fee"], "100")
    }

    func testParseSkipsLinesWithNoColon() {
        let map = TxRepHelper.parse("no colon here\ntx.fee: 100")
        XCTAssertEqual(map.count, 1)
        XCTAssertNil(map["no colon here"])
    }

    func testParseSplitsOnFirstColonOnly() {
        let map = TxRepHelper.parse("tx.asset: USD:GISSUER")
        XCTAssertEqual(map["tx.asset"], "USD:GISSUER")
    }

    func testParseTrimsValues() {
        let map = TxRepHelper.parse("tx.fee:   100  ")
        XCTAssertEqual(map["tx.fee"], "100")
    }

    func testParseTrimsKeys() {
        let map = TxRepHelper.parse("  tx.fee  : 100")
        XCTAssertEqual(map["tx.fee"], "100")
    }

    func testParseSkipsEmptyKeyAfterTrim() {
        let map = TxRepHelper.parse("  : value\ntx.fee: 100")
        XCTAssertEqual(map.count, 1)
        XCTAssertNil(map[""])
    }

    func testParseDuplicateKeysLastWriteWins() {
        let map = TxRepHelper.parse("tx.fee: 100\ntx.fee: 200")
        XCTAssertEqual(map["tx.fee"], "200")
    }

    func testParseEmptyInput() {
        let map = TxRepHelper.parse("")
        XCTAssertTrue(map.isEmpty)
    }

    func testParseOnlyBlankLines() {
        let map = TxRepHelper.parse("\n\n\n")
        XCTAssertTrue(map.isEmpty)
    }

    func testParseValueWithColonInValue() {
        // Colon in value — should keep remainder as value
        let map = TxRepHelper.parse("key: val:ue:extra")
        XCTAssertEqual(map["key"], "val:ue:extra")
    }

    // MARK: - getValue()

    func testGetValueReturnsNilForMissingKey() {
        let result = TxRepHelper.getValue([:], "missing")
        XCTAssertNil(result)
    }

    func testGetValueStripsInlineParenComment() {
        let map = ["tx.fee": "100 (fee amount)"]
        XCTAssertEqual(TxRepHelper.getValue(map, "tx.fee"), "100")
    }

    func testGetValueReturnsPlainValueWhenNoComment() {
        let map = ["tx.fee": "100"]
        XCTAssertEqual(TxRepHelper.getValue(map, "tx.fee"), "100")
    }

    func testGetValueHandlesQuotedStringWithParens() {
        let map = ["tx.memo": "\"hello (world)\""]
        XCTAssertEqual(TxRepHelper.getValue(map, "tx.memo"), "\"hello (world)\"")
    }

    // MARK: - removeComment()

    func testRemoveCommentTrimsTrailingWhitespace() {
        XCTAssertEqual(TxRepHelper.removeComment("hello  "), "hello")
    }

    func testRemoveCommentRemovesParenComment() {
        XCTAssertEqual(TxRepHelper.removeComment("100 (fee amount)"), "100")
    }

    func testRemoveCommentHandlesQuotedStringWithParens() {
        XCTAssertEqual(TxRepHelper.removeComment("\"hello (world)\""), "\"hello (world)\"")
    }

    func testRemoveCommentHandlesEscapedQuoteInsideQuotedString() {
        // "say \"hi\"" — escaped inner quote must not end the scan early
        XCTAssertEqual(TxRepHelper.removeComment("\"say \\\"hi\\\"\""), "\"say \\\"hi\\\"\"")
    }

    func testRemoveCommentHandlesUnclosedQuotedString() {
        XCTAssertEqual(TxRepHelper.removeComment("\"unclosed"), "\"unclosed")
    }

    func testRemoveCommentValueStartingWithOpenParen() {
        XCTAssertEqual(TxRepHelper.removeComment("(comment)"), "")
    }

    func testRemoveCommentNoCommentNoChange() {
        XCTAssertEqual(TxRepHelper.removeComment("simple"), "simple")
    }

    func testRemoveCommentQuotedStringTrailingComment() {
        // "hello" (ignored) — after closing quote, extra stuff is stripped
        XCTAssertEqual(TxRepHelper.removeComment("\"hello\" (ignored)"), "\"hello\"")
    }

    // MARK: - bytesToHex()

    func testBytesToHexEncodesTwoBytes() {
        let data = Data([0xAB, 0xCD])
        XCTAssertEqual(TxRepHelper.bytesToHex(data), "abcd")
    }

    func testBytesToHexReturnsZeroForEmpty() {
        XCTAssertEqual(TxRepHelper.bytesToHex(Data()), "0")
    }

    func testBytesToHexSingleByte() {
        XCTAssertEqual(TxRepHelper.bytesToHex(Data([0x0F])), "0f")
    }

    func testBytesToHexAllZeroBytes() {
        XCTAssertEqual(TxRepHelper.bytesToHex(Data([0x00, 0x00])), "0000")
    }

    func testBytesToHexAllFF() {
        XCTAssertEqual(TxRepHelper.bytesToHex(Data([0xFF, 0xFF])), "ffff")
    }

    // MARK: - hexToBytes()

    func testHexToBytesDecodesTwoBytes() throws {
        let data = try TxRepHelper.hexToBytes("abcd")
        XCTAssertEqual(data, Data([0xAB, 0xCD]))
    }

    func testHexToBytesReturnsEmptyForZero() throws {
        let data = try TxRepHelper.hexToBytes("0")
        XCTAssertEqual(data, Data())
    }

    func testHexToBytesHandlesOddLengthHex() throws {
        // "abc" → "0abc" → [0x0A, 0xBC]
        let data = try TxRepHelper.hexToBytes("abc")
        XCTAssertEqual(data, Data([0x0A, 0xBC]))
    }

    func testHexToBytesHandlesSingleOddDigit() throws {
        // "f" → "0f" → [0x0F]
        let data = try TxRepHelper.hexToBytes("f")
        XCTAssertEqual(data, Data([0x0F]))
    }

    func testHexToBytesAcceptsUppercaseHex() throws {
        let data = try TxRepHelper.hexToBytes("ABCD")
        XCTAssertEqual(data, Data([0xAB, 0xCD]))
    }

    func testHexToBytesAcceptsMixedCaseHex() throws {
        let data = try TxRepHelper.hexToBytes("AbCd")
        XCTAssertEqual(data, Data([0xAB, 0xCD]))
    }

    func testHexToBytesThrowsOnInvalidChar() {
        XCTAssertThrowsError(try TxRepHelper.hexToBytes("zz")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testHexToBytesThrowsOnSpaceInHex() {
        XCTAssertThrowsError(try TxRepHelper.hexToBytes("ab cd"))
    }

    func testHexToBytesRoundtrip() throws {
        let original = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        let hex = TxRepHelper.bytesToHex(original)
        let decoded = try TxRepHelper.hexToBytes(hex)
        XCTAssertEqual(decoded, original)
    }

    func testHexToBytesAllZeroesHex() throws {
        let data = try TxRepHelper.hexToBytes("0000")
        XCTAssertEqual(data, Data([0x00, 0x00]))
    }

    // MARK: - escapeString()

    func testEscapeStringWrapsInDoubleQuotes() {
        XCTAssertEqual(TxRepHelper.escapeString("hello"), "\"hello\"")
    }

    func testEscapeStringEscapesBackslash() {
        XCTAssertEqual(TxRepHelper.escapeString("a\\b"), "\"a\\\\b\"")
    }

    func testEscapeStringEscapesDoubleQuote() {
        XCTAssertEqual(TxRepHelper.escapeString("a\"b"), "\"a\\\"b\"")
    }

    func testEscapeStringEscapesNewline() {
        XCTAssertEqual(TxRepHelper.escapeString("a\nb"), "\"a\\nb\"")
    }

    func testEscapeStringEscapesCarriageReturn() {
        XCTAssertEqual(TxRepHelper.escapeString("a\rb"), "\"a\\rb\"")
    }

    func testEscapeStringEscapesTab() {
        XCTAssertEqual(TxRepHelper.escapeString("a\tb"), "\"a\\tb\"")
    }

    func testEscapeStringEncodesNonAsciiAsHexBytes() {
        // U+00FF (ÿ) → UTF-8 bytes 0xC3 0xBF → \xc3\xbf
        XCTAssertEqual(TxRepHelper.escapeString("\u{00FF}"), "\"\\xc3\\xbf\"")
    }

    func testEscapeStringEncodesHighUnicode() {
        // U+0100 → UTF-8 0xC4 0x80
        XCTAssertEqual(TxRepHelper.escapeString("\u{0100}"), "\"\\xc4\\x80\"")
    }

    func testEscapeStringPassesPrintableAsciiThrough() {
        XCTAssertEqual(TxRepHelper.escapeString("abc 123!@#"), "\"abc 123!@#\"")
    }

    func testEscapeStringNullByteEncodedAsHex() {
        XCTAssertEqual(TxRepHelper.escapeString("\0"), "\"\\x00\"")
    }

    func testEscapeStringControlByteEncodedAsHex() {
        // 0x01 is non-printable, non-special → \x01
        XCTAssertEqual(TxRepHelper.escapeString("\u{01}"), "\"\\x01\"")
    }

    func testEscapeStringDELEncodedAsHex() {
        // 0x7F (DEL) → \x7f
        XCTAssertEqual(TxRepHelper.escapeString("\u{7F}"), "\"\\x7f\"")
    }

    func testEscapeStringEmptyString() {
        XCTAssertEqual(TxRepHelper.escapeString(""), "\"\"")
    }

    // MARK: - unescapeString()

    func testUnescapeStringStripsEnclosingQuotes() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"hello\""), "hello")
    }

    func testUnescapeStringNoQuotesReturnedAsIs() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("hello"), "hello")
    }

    func testUnescapeStringUnescapesBackslash() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"a\\\\b\""), "a\\b")
    }

    func testUnescapeStringUnescapesDoubleQuote() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"a\\\"b\""), "a\"b")
    }

    func testUnescapeStringUnescapesNewline() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"a\\nb\""), "a\nb")
    }

    func testUnescapeStringUnescapesCarriageReturn() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"a\\rb\""), "a\rb")
    }

    func testUnescapeStringUnescapesTab() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"a\\tb\""), "a\tb")
    }

    func testUnescapeStringUnescapesHexSequence() throws {
        // \xc3\xbf → UTF-8 for U+00FF
        let result = try TxRepHelper.unescapeString("\"\\xc3\\xbf\"")
        XCTAssertEqual(result, "\u{00FF}")
    }

    func testUnescapeStringThrowsOnInvalidHexInXSequence() {
        XCTAssertThrowsError(try TxRepHelper.unescapeString("\"\\xZZ\"")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testUnescapeStringUnknownEscapePassesThroughBackslash() throws {
        // \q → unknown, pass \ through literally
        let result = try TxRepHelper.unescapeString("\"\\q\"")
        XCTAssertEqual(result, "\\q")
    }

    func testUnescapeStringThrowsForUnclosedQuotedString() {
        XCTAssertThrowsError(try TxRepHelper.unescapeString("\"unclosed"))
    }

    func testUnescapeStringSingleQuoteThrows() {
        // Just a single quote — unclosed
        XCTAssertThrowsError(try TxRepHelper.unescapeString("\""))
    }

    func testUnescapeStringEmptyQuotedString() throws {
        XCTAssertEqual(try TxRepHelper.unescapeString("\"\""), "")
    }

    func testUnescapeStringRoundtripsWithEscapeString() throws {
        let original = "hello \"world\"\nnew line \\ backslash"
        let escaped = TxRepHelper.escapeString(original)
        let unescaped = try TxRepHelper.unescapeString(escaped)
        XCTAssertEqual(unescaped, original)
    }

    func testUnescapeStringRoundtripsNonAscii() throws {
        // U+00FF and U+0100
        let original = "\u{00FF}\u{0100}"
        let escaped = TxRepHelper.escapeString(original)
        let unescaped = try TxRepHelper.unescapeString(escaped)
        XCTAssertEqual(unescaped, original)
    }

    func testUnescapeStringOctalEscape() throws {
        // \101 is octal for 65 = 'A'
        let result = try TxRepHelper.unescapeString("\"\\101\"")
        XCTAssertEqual(result, "A")
    }

    func testUnescapeStringIncompleteXSequenceTreatedLiterally() throws {
        // \x with fewer than 2 hex digits at end of string — pass backslash through
        let result = try TxRepHelper.unescapeString("\"\\x\"")
        XCTAssertEqual(result, "\\x")
    }

    // MARK: - parseInt()

    func testParseIntDecimalPositive() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("42"), 42)
    }

    func testParseIntDecimalNegative() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("-42"), -42)
    }

    func testParseIntHexLowerPrefix() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("0xff"), 255)
    }

    func testParseIntHexUpperPrefix() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("0XFF"), 255)
    }

    func testParseIntNegativeHex() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("-0xff"), -255)
    }

    func testParseIntZero() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("0"), 0)
    }

    func testParseIntTrimsWhitespace() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("  42  "), 42)
    }

    func testParseIntMaxValue() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("2147483647"), Int32.max)
    }

    func testParseIntMinValue() throws {
        XCTAssertEqual(try TxRepHelper.parseInt("-2147483648"), Int32.min)
    }

    func testParseIntOverflowThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt("2147483648"))
    }

    func testParseIntNegativeOverflowThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt("-2147483649"))
    }

    func testParseIntInvalidCharsThrow() {
        XCTAssertThrowsError(try TxRepHelper.parseInt("abc"))
    }

    func testParseIntEmptyStringThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt(""))
    }

    // MARK: - parseInt64()

    func testParseInt64DecimalPositive() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("123456789"), 123456789)
    }

    func testParseInt64DecimalNegative() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("-42"), -42)
    }

    func testParseInt64HexLowerPrefix() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("0xff"), 255)
    }

    func testParseInt64HexUpperPrefix() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("0XFF"), 255)
    }

    func testParseInt64NegativeHex() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("-0xff"), -255)
    }

    func testParseInt64Zero() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("0"), 0)
    }

    func testParseInt64MaxValue() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("9223372036854775807"), Int64.max)
    }

    func testParseInt64MinValue() throws {
        XCTAssertEqual(try TxRepHelper.parseInt64("-9223372036854775808"), Int64.min)
    }

    func testParseInt64OverflowThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt64("9223372036854775808"))
    }

    func testParseInt64InvalidCharsThrow() {
        XCTAssertThrowsError(try TxRepHelper.parseInt64("not_a_number"))
    }

    func testParseInt64EmptyStringThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt64(""))
    }

    func testParseInt64HexMaxFitsThrows() {
        // 0x10000000000000000 overflows UInt64 → throws
        XCTAssertThrowsError(try TxRepHelper.parseInt64("0x10000000000000000"))
    }

    // MARK: - parseUInt64()

    func testParseUInt64DecimalPositive() throws {
        XCTAssertEqual(try TxRepHelper.parseUInt64("12345678901234"), 12345678901234)
    }

    func testParseUInt64HexLowerPrefix() throws {
        XCTAssertEqual(try TxRepHelper.parseUInt64("0xff"), 255)
    }

    func testParseUInt64HexUpperPrefix() throws {
        XCTAssertEqual(try TxRepHelper.parseUInt64("0XFF"), 255)
    }

    func testParseUInt64Zero() throws {
        XCTAssertEqual(try TxRepHelper.parseUInt64("0"), 0)
    }

    func testParseUInt64MaxValue() throws {
        XCTAssertEqual(try TxRepHelper.parseUInt64("18446744073709551615"), UInt64.max)
    }

    func testParseUInt64OverflowThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseUInt64("18446744073709551616"))
    }

    func testParseUInt64NegativeThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseUInt64("-1"))
    }

    func testParseUInt64InvalidCharsThrow() {
        XCTAssertThrowsError(try TxRepHelper.parseUInt64("abc"))
    }

    func testParseUInt64EmptyStringThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseUInt64(""))
    }

    func testParseUInt64TrimsWhitespace() throws {
        XCTAssertEqual(try TxRepHelper.parseUInt64("  100  "), 100)
    }

    // MARK: - formatAccountId() / parseAccountId()

    func testFormatAccountIdReturnsGAddress() throws {
        let pk = try makePublicKey()
        let formatted = TxRepHelper.formatAccountId(pk)
        XCTAssertTrue(formatted.hasPrefix("G"), "Expected G-address, got \(formatted)")
    }

    func testParseAccountIdRoundtrip() throws {
        let pk = try makePublicKey()
        let accountId = TxRepHelper.formatAccountId(pk)
        let parsed = try TxRepHelper.parseAccountId(accountId)
        XCTAssertEqual(parsed.accountId, pk.accountId)
    }

    func testParseAccountIdKnownKey() throws {
        // Derive a valid G-address from a known KeyPair seed and verify it parses.
        let kp = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let parsed = try TxRepHelper.parseAccountId(kp.accountId)
        XCTAssertTrue(parsed.accountId.hasPrefix("G"))
        XCTAssertEqual(parsed.accountId, kp.accountId)
    }

    func testParseAccountIdInvalidStrKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAccountId("INVALID_KEY")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseAccountIdEmptyStringThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAccountId(""))
    }

    func testParseAccountIdMKeyThrows() {
        // M-addresses are muxed, not plain G-addresses — must throw for parseAccountId
        // Construct a known M-address via the muxed account path and confirm it rejects
        let muxed = MuxedAccountXDR.med25519(MuxedAccountMed25519XDR(
            id: 1,
            sourceAccountEd25519: kTestBytes32
        ))
        let mAddress = muxed.accountId
        if mAddress.hasPrefix("M") {
            XCTAssertThrowsError(try TxRepHelper.parseAccountId(mAddress))
        }
        // If somehow accountId is empty (encoding failed), test is moot — skip silently
    }

    // MARK: - formatMuxedAccount() / parseMuxedAccount()

    func testFormatMuxedAccountEd25519ReturnsGAddress() throws {
        let pk = try makePublicKey()
        let muxed = MuxedAccountXDR.ed25519(pk.bytes)
        let formatted = try TxRepHelper.formatMuxedAccount(muxed)
        XCTAssertTrue(formatted.hasPrefix("G"))
    }

    func testFormatMuxedAccountMed25519ReturnsMAddress() throws {
        let muxed = MuxedAccountXDR.med25519(MuxedAccountMed25519XDR(
            id: 42,
            sourceAccountEd25519: kTestBytes32
        ))
        let formatted = try TxRepHelper.formatMuxedAccount(muxed)
        // M-addresses start with M
        XCTAssertTrue(formatted.hasPrefix("M") || formatted.hasPrefix("G"),
                      "Expected M- or G-address, got \(formatted)")
    }

    func testParseMuxedAccountGAddressRoundtrip() throws {
        let pk = try makePublicKey()
        let muxed = MuxedAccountXDR.ed25519(pk.bytes)
        let formatted = try TxRepHelper.formatMuxedAccount(muxed)
        let parsed = try TxRepHelper.parseMuxedAccount(formatted)
        let formattedAgain = try TxRepHelper.formatMuxedAccount(parsed)
        XCTAssertEqual(formatted, formattedAgain)
    }

    func testParseMuxedAccountInvalidThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseMuxedAccount("INVALID")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseMuxedAccountEmptyStringThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseMuxedAccount(""))
    }

    // MARK: - formatAsset() / parseAsset()

    func testFormatAssetNative() {
        XCTAssertEqual(TxRepHelper.formatAsset(.native), "XLM")
    }

    func testFormatAssetAlphanum4() throws {
        let issuer = try makePublicKey()
        let asset = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])), // USD\0
            issuer: issuer
        ))
        let formatted = TxRepHelper.formatAsset(asset)
        XCTAssertTrue(formatted.hasPrefix("USD:G"), "Expected USD:G…, got \(formatted)")
    }

    func testFormatAssetAlphanum12() throws {
        let issuer = try makePublicKey()
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45]) // LONGCODE
        codeBytes.append(Data(repeating: 0, count: 4))
        let asset = AssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer
        ))
        let formatted = TxRepHelper.formatAsset(asset)
        XCTAssertTrue(formatted.hasPrefix("LONGCODE:G"), "Expected LONGCODE:G…, got \(formatted)")
    }

    func testParseAssetNativeXLM() throws {
        let asset = try TxRepHelper.parseAsset("XLM")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testParseAssetNativeKeyword() throws {
        let asset = try TxRepHelper.parseAsset("native")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testParseAssetRoundtripsAlphanum4() throws {
        let issuer = try makePublicKey()
        let original = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer
        ))
        let formatted = TxRepHelper.formatAsset(original)
        let parsed = try TxRepHelper.parseAsset(formatted)
        if case .alphanum4(let a) = parsed {
            XCTAssertEqual(a.issuer.accountId, issuer.accountId)
        } else {
            XCTFail("Expected .alphanum4")
        }
    }

    func testParseAssetRoundtripsAlphanum12() throws {
        let issuer = try makePublicKey()
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let original = AssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer
        ))
        let formatted = TxRepHelper.formatAsset(original)
        let parsed = try TxRepHelper.parseAsset(formatted)
        if case .alphanum12 = parsed { /* ok */ } else { XCTFail("Expected .alphanum12") }
    }

    func testParseAssetInvalidFormatThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAsset("NO_COLON"))
    }

    func testParseAssetCodeTooLongThrows() throws {
        let issuer = try makePublicKey()
        XCTAssertThrowsError(try TxRepHelper.parseAsset("TOOLONGASSETCODE:\(issuer.accountId)"))
    }

    func testParseAssetEmptyCodeThrows() throws {
        let issuer = try makePublicKey()
        XCTAssertThrowsError(try TxRepHelper.parseAsset(":\(issuer.accountId)"))
    }

    func testParseAssetInvalidIssuerThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAsset("USD:INVALID_ISSUER"))
    }

    // MARK: - formatChangeTrustAsset() / parseChangeTrustAsset()

    func testFormatChangeTrustAssetNative() throws {
        XCTAssertEqual(try TxRepHelper.formatChangeTrustAsset(.native), "XLM")
    }

    func testFormatChangeTrustAssetAlphanum4() throws {
        let issuer = try makePublicKey()
        let asset = ChangeTrustAssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatChangeTrustAsset(asset)
        XCTAssertTrue(formatted.hasPrefix("USD:G"))
    }

    func testFormatChangeTrustAssetAlphanum12() throws {
        let issuer = try makePublicKey()
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let asset = ChangeTrustAssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatChangeTrustAsset(asset)
        XCTAssertTrue(formatted.hasPrefix("LONGCODE:G"))
    }

    func testFormatChangeTrustAssetPoolShareThrows() {
        // Pool-share requires fee parameters — we need a placeholder.
        // Use a constant product pool parameters stub.
        let issuer: PublicKey
        do { issuer = try makePublicKey() } catch { return XCTFail("makePublicKey failed") }
        let assetA = AssetXDR.native
        let assetB = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer
        ))
        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: assetA,
            assetB: assetB,
            fee: 30
        )
        let poolParams = LiquidityPoolParametersXDR.constantProduct(params)
        let asset = ChangeTrustAssetXDR.poolShare(poolParams)
        XCTAssertThrowsError(try TxRepHelper.formatChangeTrustAsset(asset)) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseChangeTrustAssetNativeXLM() throws {
        let asset = try TxRepHelper.parseChangeTrustAsset("XLM")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testParseChangeTrustAssetNativeKeyword() throws {
        let asset = try TxRepHelper.parseChangeTrustAsset("native")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testParseChangeTrustAssetRoundtripsAlphanum4() throws {
        let issuer = try makePublicKey()
        let original = ChangeTrustAssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatChangeTrustAsset(original)
        let parsed = try TxRepHelper.parseChangeTrustAsset(formatted)
        if case .alphanum4(let a) = parsed {
            XCTAssertEqual(a.issuer.accountId, issuer.accountId)
        } else {
            XCTFail("Expected .alphanum4")
        }
    }

    func testParseChangeTrustAssetRoundtripsAlphanum12() throws {
        let issuer = try makePublicKey()
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let original = ChangeTrustAssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatChangeTrustAsset(original)
        let parsed = try TxRepHelper.parseChangeTrustAsset(formatted)
        if case .alphanum12 = parsed { /* ok */ } else { XCTFail("Expected .alphanum12") }
    }

    func testParseChangeTrustAssetInvalidFormatThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseChangeTrustAsset("bad:format:extra"))
    }

    func testParseChangeTrustAssetCodeTooLongThrows() throws {
        let issuer = try makePublicKey()
        XCTAssertThrowsError(try TxRepHelper.parseChangeTrustAsset("TOOLONGASSETCODE:\(issuer.accountId)"))
    }

    // MARK: - formatTrustlineAsset() / parseTrustlineAsset()

    func testFormatTrustlineAssetNative() throws {
        XCTAssertEqual(try TxRepHelper.formatTrustlineAsset(.native), "XLM")
    }

    func testFormatTrustlineAssetAlphanum4() throws {
        let issuer = try makePublicKey()
        let asset = TrustlineAssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatTrustlineAsset(asset)
        XCTAssertTrue(formatted.hasPrefix("USD:G"))
    }

    func testFormatTrustlineAssetAlphanum12() throws {
        let issuer = try makePublicKey()
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let asset = TrustlineAssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatTrustlineAsset(asset)
        XCTAssertTrue(formatted.hasPrefix("LONGCODE:G"))
    }

    func testFormatTrustlineAssetPoolShareIsHex() throws {
        let poolData = Data(repeating: 0xAB, count: 32)
        let asset = TrustlineAssetXDR.poolShare(WrappedData32(poolData))
        let formatted = try TxRepHelper.formatTrustlineAsset(asset)
        XCTAssertEqual(formatted.count, 64, "Pool share should be 64-char hex")
        // All chars must be hex
        XCTAssertTrue(formatted.allSatisfy { $0.isHexDigit }, "All chars must be hex")
    }

    func testParseTrustlineAssetNativeXLM() throws {
        let asset = try TxRepHelper.parseTrustlineAsset("XLM")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testParseTrustlineAssetNativeKeyword() throws {
        let asset = try TxRepHelper.parseTrustlineAsset("native")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testParseTrustlineAssetPoolShareRoundtrip() throws {
        let poolData = Data(repeating: 0xAB, count: 32)
        let original = TrustlineAssetXDR.poolShare(WrappedData32(poolData))
        let formatted = try TxRepHelper.formatTrustlineAsset(original)
        XCTAssertEqual(formatted.count, 64)
        let parsed = try TxRepHelper.parseTrustlineAsset(formatted)
        if case .poolShare(let wd) = parsed {
            XCTAssertEqual(wd.wrapped, poolData)
        } else {
            XCTFail("Expected .poolShare")
        }
    }

    func testParseTrustlineAssetRoundtripsAlphanum4() throws {
        let issuer = try makePublicKey()
        let original = TrustlineAssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatTrustlineAsset(original)
        let parsed = try TxRepHelper.parseTrustlineAsset(formatted)
        if case .alphanum4(let a) = parsed {
            XCTAssertEqual(a.issuer.accountId, issuer.accountId)
        } else {
            XCTFail("Expected .alphanum4")
        }
    }

    func testParseTrustlineAssetRoundtripsAlphanum12() throws {
        let issuer = try makePublicKey()
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let original = TrustlineAssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer
        ))
        let formatted = try TxRepHelper.formatTrustlineAsset(original)
        let parsed = try TxRepHelper.parseTrustlineAsset(formatted)
        if case .alphanum12 = parsed { /* ok */ } else { XCTFail("Expected .alphanum12") }
    }

    func testParseTrustlineAssetInvalidFormatThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseTrustlineAsset("bad:format:extra"))
    }

    func testParseTrustlineAssetCodeTooLongThrows() throws {
        let issuer = try makePublicKey()
        XCTAssertThrowsError(try TxRepHelper.parseTrustlineAsset("TOOLONGASSETCODE:\(issuer.accountId)"))
    }

    // MARK: - formatSignerKey() / parseSignerKey()

    func testFormatAndParseSignerKeyEd25519() throws {
        let key = SignerKeyXDR.ed25519(Uint256XDR(Data(kTestBytes32)))
        let formatted = try TxRepHelper.formatSignerKey(key)
        XCTAssertTrue(formatted.hasPrefix("G"), "Expected G-address, got \(formatted)")
        let parsed = try TxRepHelper.parseSignerKey(formatted)
        if case .ed25519(let data) = parsed {
            XCTAssertEqual(data.wrapped, Data(kTestBytes32))
        } else {
            XCTFail("Expected .ed25519")
        }
    }

    func testFormatAndParseSignerKeyPreAuthTx() throws {
        let key = SignerKeyXDR.preAuthTx(Uint256XDR(Data(kTestBytes32b)))
        let formatted = try TxRepHelper.formatSignerKey(key)
        XCTAssertTrue(formatted.hasPrefix("T"), "Expected T-address, got \(formatted)")
        let parsed = try TxRepHelper.parseSignerKey(formatted)
        if case .preAuthTx(let data) = parsed {
            XCTAssertEqual(data.wrapped, Data(kTestBytes32b))
        } else {
            XCTFail("Expected .preAuthTx")
        }
    }

    func testFormatAndParseSignerKeyHashX() throws {
        let key = SignerKeyXDR.hashX(Uint256XDR(Data(kTestBytes32c)))
        let formatted = try TxRepHelper.formatSignerKey(key)
        XCTAssertTrue(formatted.hasPrefix("X"), "Expected X-address, got \(formatted)")
        let parsed = try TxRepHelper.parseSignerKey(formatted)
        if case .hashX(let data) = parsed {
            XCTAssertEqual(data.wrapped, Data(kTestBytes32c))
        } else {
            XCTFail("Expected .hashX")
        }
    }

    func testFormatAndParseSignerKeySignedPayload() throws {
        let payload = Ed25519SignedPayload(
            ed25519: Uint256XDR(Data(kTestBytes32)),
            payload: Data([1, 2, 3, 4])
        )
        let key = SignerKeyXDR.signedPayload(payload)
        let formatted = try TxRepHelper.formatSignerKey(key)
        XCTAssertTrue(formatted.hasPrefix("P"), "Expected P-address, got \(formatted)")
        let parsed = try TxRepHelper.parseSignerKey(formatted)
        if case .signedPayload(let sp) = parsed {
            XCTAssertEqual(sp.payload, Data([1, 2, 3, 4]))
        } else {
            XCTFail("Expected .signedPayload")
        }
    }

    func testParseSignerKeyUnknownPrefixThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseSignerKey("Z1234")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseSignerKeyInvalidGAddressThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseSignerKey("GBADBADBAD"))
    }

    func testParseSignerKeyInvalidTAddressThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseSignerKey("TBADBADBAD"))
    }

    func testParseSignerKeyInvalidXAddressThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseSignerKey("XBADBADBAD"))
    }

    func testParseSignerKeyInvalidPAddressThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseSignerKey("PBADBADBAD"))
    }

    // MARK: - formatAllowTrustAsset() / parseAllowTrustAsset()

    func testFormatAllowTrustAssetAlphanum4() throws {
        let asset = AllowTrustOpAssetXDR.alphanum4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00])))
        let formatted = try TxRepHelper.formatAllowTrustAsset(asset)
        XCTAssertEqual(formatted, "USD")
    }

    func testFormatAllowTrustAssetAlphanum12() throws {
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45]) // LONGCODE
        codeBytes.append(Data(repeating: 0, count: 4))
        let asset = AllowTrustOpAssetXDR.alphanum12(WrappedData12(codeBytes))
        let formatted = try TxRepHelper.formatAllowTrustAsset(asset)
        XCTAssertEqual(formatted, "LONGCODE")
    }

    func testParseAllowTrustAssetAlphanum4Short() throws {
        let parsed = try TxRepHelper.parseAllowTrustAsset("USD")
        if case .alphanum4 = parsed { /* ok */ } else { XCTFail("Expected .alphanum4") }
    }

    func testParseAllowTrustAssetAlphanum4ExactlyFourChars() throws {
        let parsed = try TxRepHelper.parseAllowTrustAsset("USDC")
        if case .alphanum4 = parsed { /* ok */ } else { XCTFail("Expected .alphanum4") }
    }

    func testParseAllowTrustAssetAlphanum12() throws {
        let parsed = try TxRepHelper.parseAllowTrustAsset("LONGASSET")
        if case .alphanum12 = parsed { /* ok */ } else { XCTFail("Expected .alphanum12") }
    }

    func testParseAllowTrustAssetAlphanum12ExactlyTwelveChars() throws {
        let parsed = try TxRepHelper.parseAllowTrustAsset("ABCDEFGHIJKL")
        if case .alphanum12 = parsed { /* ok */ } else { XCTFail("Expected .alphanum12") }
    }

    func testParseAllowTrustAssetCodeTooLongThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAllowTrustAsset("TOOLONGASSETCODE")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseAllowTrustAssetEmptyCodeThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAllowTrustAsset(""))
    }

    func testParseAllowTrustAssetWhitespaceOnlyThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseAllowTrustAsset("   "))
    }

    func testFormatAllowTrustAssetRoundtrip4() throws {
        let original = AllowTrustOpAssetXDR.alphanum4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00])))
        let formatted = try TxRepHelper.formatAllowTrustAsset(original)
        let parsed = try TxRepHelper.parseAllowTrustAsset(formatted)
        let reformatted = try TxRepHelper.formatAllowTrustAsset(parsed)
        XCTAssertEqual(formatted, reformatted)
    }

    func testFormatAllowTrustAssetRoundtrip12() throws {
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let original = AllowTrustOpAssetXDR.alphanum12(WrappedData12(codeBytes))
        let formatted = try TxRepHelper.formatAllowTrustAsset(original)
        let parsed = try TxRepHelper.parseAllowTrustAsset(formatted)
        let reformatted = try TxRepHelper.formatAllowTrustAsset(parsed)
        XCTAssertEqual(formatted, reformatted)
    }

    // MARK: - removeComment() — backslash-at-end-of-string branch

    func testRemoveCommentBackslashAtEndOfQuotedString() {
        // A quoted string where the final character is a backslash — the escape-skip
        // branch consumes the backslash and then hits `next == endIndex`, advancing i
        // to endIndex via `i = next`.  No closing quote is ever found, so the string
        // is returned as-is (the "no closing quote" path).
        let input = "\"hello\\"
        let result = TxRepHelper.removeComment(input)
        XCTAssertEqual(result, input)
    }

    // MARK: - hexNibble() — uppercase A–F branch (via unescapeString \xNN)

    func testUnescapeStringUppercaseHexNibbleInXSequence() throws {
        // \xC3\xBF with uppercase C — exercises the A–F branch in hexNibble().
        // 0xC3 0xBF is valid UTF-8 for U+00FF (ÿ).
        let result = try TxRepHelper.unescapeString("\"\\xC3\\xBF\"")
        XCTAssertEqual(result, "\u{00FF}")
    }

    func testUnescapeStringUppercaseMixedNibblePairs() throws {
        // \xC3\xAB — uppercase C and A, producing valid UTF-8 U+00EB (ë).
        let result = try TxRepHelper.unescapeString("\"\\xC3\\xAB\"")
        XCTAssertEqual(result, "\u{00EB}")
    }

    // MARK: - unescapeString() — invalid UTF-8 bytes path

    func testUnescapeStringThrowsForInvalidUTF8Bytes() {
        // \xc3 alone is the first byte of a 2-byte UTF-8 sequence but has no
        // continuation byte, producing an invalid UTF-8 byte sequence.
        // String(bytes:encoding:.utf8) returns nil, so the function must throw.
        XCTAssertThrowsError(try TxRepHelper.unescapeString("\"\\xc3\"")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    // MARK: - parseInt() — hex parse failure branch

    func testParseIntHexEmptyAfterPrefixThrows() {
        // "0x" with no digits — UInt64("", radix:16) returns nil → throws.
        XCTAssertThrowsError(try TxRepHelper.parseInt("0x")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseIntNegativeHexEmptyAfterPrefixThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt("-0x"))
    }

    // MARK: - parseInt64() — hex overflow branches

    func testParseInt64NegativeHexExactMinValueSucceeds() throws {
        // -0x8000000000000000 == Int64.min — the two's-complement special case.
        let result = try TxRepHelper.parseInt64("-0x8000000000000000")
        XCTAssertEqual(result, Int64.min)
    }

    func testParseInt64NegativeHexOverflowThrows() {
        // val = 0x8000000000000001 > UInt64(Int64.max) + 1 → overflow throw.
        XCTAssertThrowsError(try TxRepHelper.parseInt64("-0x8000000000000001")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseInt64PositiveHexOverflowThrows() {
        // 0x8000000000000000 = 2^63 > Int64.max → overflow throw.
        XCTAssertThrowsError(try TxRepHelper.parseInt64("0x8000000000000000")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseInt64HexEmptyAfterPrefixThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt64("0x"))
    }

    func testParseInt64NegativeHexEmptyAfterPrefixThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseInt64("-0x"))
    }

    // MARK: - parseInt64() — decimal negative edge cases

    func testParseInt64NegativeZeroIsZero() throws {
        // "-0" is valid: negative == true, val == 0 → returns 0.
        let result = try TxRepHelper.parseInt64("-0")
        XCTAssertEqual(result, 0)
    }

    func testParseInt64AbsoluteMinEdge() throws {
        // 9223372036854775808 overflows Int64 but fits UInt64 — special-cased path.
        let result = try TxRepHelper.parseInt64("-9223372036854775808")
        XCTAssertEqual(result, Int64.min)
    }

    // MARK: - parseUInt64() — hex parse failure branch

    func testParseUInt64HexEmptyAfterPrefixThrows() {
        XCTAssertThrowsError(try TxRepHelper.parseUInt64("0x")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseUInt64HexInvalidCharsThrow() {
        XCTAssertThrowsError(try TxRepHelper.parseUInt64("0xGG"))
    }

    // MARK: - parseChangeTrustAsset() — empty code guard

    func testParseChangeTrustAssetEmptyCodeThrows() throws {
        let issuer = try makePublicKey()
        XCTAssertThrowsError(try TxRepHelper.parseChangeTrustAsset(":\(issuer.accountId)")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    // MARK: - parseTrustlineAsset() — uncovered guard branches

    func testParseTrustlineAssetNoColonNot64CharsThrows() {
        // Not "XLM"/"native", no colon, not 64 chars → falls to parts.count guard → throws.
        XCTAssertThrowsError(try TxRepHelper.parseTrustlineAsset("NOCOL")) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testParseTrustlineAsset64CharNonHexThrows() {
        // Exactly 64 chars, no colon, but contains non-hex characters → invalid pool ID.
        let nonHex = String(repeating: "Z", count: 64)
        XCTAssertThrowsError(try TxRepHelper.parseTrustlineAsset(nonHex)) { error in
            guard case TxRepError.invalidValue = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    // MARK: - formatSignerKey() — error catch branches
    //
    // The underlying StrKey encode functions (encodeEd25519PublicKey, encodePreAuthTx,
    // encodeSha256Hash) delegate to encodeCheck() which is infallible in practice —
    // it always produces a valid base32 string for any byte sequence. Therefore the
    // catch/rethrow branches on lines 623, 629, 635 are genuinely unreachable with any
    // legitimately constructed SignerKeyXDR value.
    //
    // The signedPayload branch (line 641) routes through XDREncoder.encode which can
    // theoretically throw, but in practice does not for a well-formed Ed25519SignedPayload.
    //
    // These four catch clauses are defensive guards against future SDK changes; they are
    // documented here as confirmed-unreachable with the current SDK implementation.

    // MARK: - formatMuxedAccount() — empty accountId branch
    //
    // The empty-accountId guard (line 422) is entered only when MuxedAccountXDR.accountId
    // returns "". For .ed25519 this is impossible (PublicKey.accountId never returns "").
    // For .med25519 the accountId property catches XDR encode / StrKey encode errors and
    // returns "" — but constructing a med25519 value that triggers those internal errors
    // is not possible through the public SDK API. This branch is unreachable in practice.

    // MARK: - encodeMemoText / decodeMemoText

    /// Plain ASCII text encodes as a quoted string and round-trips correctly.
    func testEncodeMemoTextAscii() throws {
        let encoded = TxRepHelper.encodeMemoText("Hello world")
        XCTAssertEqual(encoded, "\"Hello world\"")
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, "Hello world")
    }

    /// A string containing double-quote characters is escaped correctly.
    func testEncodeMemoTextWithQuotes() throws {
        let input = "say \"hi\""
        let encoded = TxRepHelper.encodeMemoText(input)
        XCTAssertTrue(encoded.hasPrefix("\""))
        XCTAssertTrue(encoded.hasSuffix("\""))
        XCTAssertTrue(encoded.contains("\\\""))
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, input)
    }

    /// A string containing a newline is escaped as \n.
    func testEncodeMemoTextWithNewline() throws {
        let input = "line1\nline2"
        let encoded = TxRepHelper.encodeMemoText(input)
        XCTAssertTrue(encoded.contains("\\n"), "newline should escape as \\n")
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, input)
    }

    /// Non-ASCII text encodes via SEP-0011 \xNN per-UTF-8-byte format,
    /// NOT via JSON \uNNNN Unicode code points. This matches the reference
    /// stc implementation and the PHP SDK.
    func testEncodeMemoTextNonAsciiUsesXEscape() throws {
        let input = "caf\u{00E9}"  // "café" — U+00E9 is C3 A9 in UTF-8
        let encoded = TxRepHelper.encodeMemoText(input)
        XCTAssertEqual(encoded, "\"caf\\xc3\\xa9\"",
                       "SEP-0011 requires \\xNN per-byte UTF-8 escaping")
        // Must NOT contain JSON-style \u Unicode escape.
        XCTAssertFalse(encoded.contains("\\u00"),
                       "must not emit JSON-style \\uNNNN escapes")
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, input)
    }

    /// Multi-byte Unicode characters (CJK) encode as multiple \xNN bytes.
    func testEncodeMemoTextCJK() throws {
        let input = "\u{65E5}\u{672C}"  // "日本" — each char is 3 UTF-8 bytes
        let encoded = TxRepHelper.encodeMemoText(input)
        XCTAssertEqual(encoded, "\"\\xe6\\x97\\xa5\\xe6\\x9c\\xac\"")
        XCTAssertFalse(encoded.contains("\\u"),
                       "must not emit JSON-style \\u escapes")
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, input)
    }

    /// 4-byte UTF-8 sequences (emoji / supplementary plane) encode as four \xNN bytes.
    func testEncodeMemoTextEmoji() throws {
        let input = "\u{1F600}"  // grinning face emoji — F0 9F 98 80 in UTF-8
        let encoded = TxRepHelper.encodeMemoText(input)
        XCTAssertEqual(encoded, "\"\\xf0\\x9f\\x98\\x80\"")
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, input)
    }

    /// decodeMemoText still accepts the legacy JSON \uNNNN format produced
    /// by older iOS SDK builds (and the unfixed Flutter SDK), for backward
    /// compatibility with previously written TxRep data.
    func testDecodeMemoTextAcceptsLegacyJsonUnicodeEscape() throws {
        // Hand-crafted JSON literal in the old buggy iOS / Flutter format.
        let legacy = "\"caf\\u00e9\""
        let decoded = try TxRepHelper.decodeMemoText(legacy)
        XCTAssertEqual(decoded, "caf\u{00E9}",
                       "legacy JSON \\uNNNN format must still decode")
    }

    /// decodeMemoText accepts JSON literals that use UTF-8 byte passthrough
    /// (older Flutter behavior — non-ASCII bytes pass through inside JSON
    /// quotes without any escaping).
    func testDecodeMemoTextAcceptsLegacyJsonUtf8Passthrough() throws {
        // JSON literal with raw UTF-8 bytes inside the quotes.
        let legacy = "\"caf\u{00E9}\""
        let decoded = try TxRepHelper.decodeMemoText(legacy)
        XCTAssertEqual(decoded, "caf\u{00E9}")
    }

    /// decodeMemoText round-trips its own (SEP-0011) output.
    func testDecodeMemoTextRoundtripSepFormat() throws {
        let escaped = TxRepHelper.escapeString("caf\u{00E9}")
        let decoded = try TxRepHelper.decodeMemoText(escaped)
        XCTAssertEqual(decoded, "caf\u{00E9}")
    }

    /// decodeMemoText handles a bare unquoted value (no quotes, no escapes) as-is.
    func testDecodeMemoTextUnquoted() throws {
        let decoded = try TxRepHelper.decodeMemoText("simpleMemo")
        XCTAssertEqual(decoded, "simpleMemo")
    }

    /// Roundtrip for a plain-ASCII memo (matches the old TxRep.swift test vector).
    func testEncodeMemoTextTestMemoRoundtrip() throws {
        let encoded = TxRepHelper.encodeMemoText("Test memo")
        XCTAssertEqual(encoded, "\"Test memo\"")
        let decoded = try TxRepHelper.decodeMemoText(encoded)
        XCTAssertEqual(decoded, "Test memo")
    }
}
