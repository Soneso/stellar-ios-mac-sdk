//
//  Sep51SpecExampleUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The worked examples of SEP-0051 §Specification, asserted in both directions.
///
/// Every expected value here is the specification's own, and every base64 is the binary the
/// specification prints beside it. Each example is pinned twice: the XDR value renders the
/// documented JSON, and the documented JSON reads back to the documented binary. A one-way
/// assertion would leave either direction free to drift.
///
/// Where the specification illustrates a rule with a construct the Stellar XDR set does not
/// declare standalone -- a bare `bool`, a fixed array of `int` -- the rule is pinned on the
/// narrowest type that does declare it, and the substitution is noted on the test.
final class Sep51SpecExampleUnitTests: XCTestCase {

    // MARK: - Integer (32-bit)

    func testSignedIntegerRendersAsAJsonNumber() throws {
        let value = try XDRDecoder.decode(Int32XDR.self, data: try Self.data("f////w=="))
        XCTAssertEqual(value, 2147483647)
        XCTAssertEqual(try Int32XDRJsonCodec.toXdrJson(value), "2147483647")

        let read = try Int32XDRJsonCodec.fromXdrJson("2147483647")
        XCTAssertEqual(try Self.base64(read), "f////w==")
    }

    // MARK: - Unsigned integer (32-bit)

    func testUnsignedIntegerRendersAsAJsonNumber() throws {
        let value = try XDRDecoder.decode(Uint32XDR.self, data: try Self.data("/////w=="))
        XCTAssertEqual(value, 4294967295)
        XCTAssertEqual(try Uint32XDRJsonCodec.toXdrJson(value), "4294967295")

        let read = try Uint32XDRJsonCodec.fromXdrJson("4294967295")
        XCTAssertEqual(try Self.base64(read), "/////w==")
    }

    // MARK: - Hyper integer (64-bit)

    func testHyperIntegerRendersAsABase10String() throws {
        let value = try XDRDecoder.decode(Int64XDR.self, data: try Self.data("f/////////8="))
        XCTAssertEqual(value, 9223372036854775807)
        XCTAssertEqual(try Int64XDRJsonCodec.toXdrJson(value), "\"9223372036854775807\"")

        let read = try Int64XDRJsonCodec.fromXdrJson("\"9223372036854775807\"")
        XCTAssertEqual(try Self.base64(read), "f/////////8=")
    }

    func testUnsignedHyperIntegerRendersAsABase10String() throws {
        let value = try XDRDecoder.decode(Uint64XDR.self, data: try Self.data("//////////8="))
        XCTAssertEqual(value, 18446744073709551615)
        XCTAssertEqual(try Uint64XDRJsonCodec.toXdrJson(value), "\"18446744073709551615\"")

        let read = try Uint64XDRJsonCodec.fromXdrJson("\"18446744073709551615\"")
        XCTAssertEqual(try Self.base64(read), "//////////8=")
    }

    /// The compatibility note under SEP-0051 §Hyper Integer: a version 1 document writes a
    /// 64-bit integer as a JSON number, and a reader should still accept it. Emission stays
    /// the string form.
    func testHyperIntegerAlsoAcceptsAJsonNumberOnInput() throws {
        XCTAssertEqual(try Int64XDRJsonCodec.fromXdrJson("9223372036854775807"), 9223372036854775807)
        XCTAssertEqual(try Uint64XDRJsonCodec.fromXdrJson("18446744073709551615"), 18446744073709551615)
        XCTAssertEqual(try Int64XDRJsonCodec.fromXdrJson("-1"), -1)
    }

    // MARK: - Boolean

    /// The Stellar XDR set declares no standalone `bool`, so the rule is pinned on `SCVal`'s
    /// boolean arm. Its payload is the specification's own `AAAAAQ==` body, carried behind
    /// the union discriminant.
    func testBooleanRendersAsAJsonBoolean() throws {
        let value = try XDRDecoder.decode(SCValXDR.self, data: try Self.data("AAAAAAAAAAE="))
        XCTAssertEqual(try value.toXdrJson(), "{\"bool\":true}")

        let read = try SCValXDR.fromXdrJson("{\"bool\":true}")
        XCTAssertEqual(try Self.base64(read), "AAAAAAAAAAE=")

        let negative = try SCValXDR.fromXdrJson("{\"bool\":false}")
        XCTAssertEqual(try negative.toXdrJson(), "{\"bool\":false}")
    }

    // MARK: - Opaque data

    func testFixedLengthOpaqueDataRendersAsLowercaseHex() throws {
        let value = ThresholdsXDR(Data("abcd".utf8))
        XCTAssertEqual(try Self.base64(value), "YWJjZA==")
        XCTAssertEqual(try ThresholdsXDRJsonCodec.toXdrJson(value), "\"61626364\"")

        let read = try ThresholdsXDRJsonCodec.fromXdrJson("\"61626364\"")
        XCTAssertEqual(try Self.base64(read), "YWJjZA==")
    }

    func testVariableLengthOpaqueDataRendersAsLowercaseHex() throws {
        let value: ValueXDR = Data("abcd".utf8)
        XCTAssertEqual(try Self.base64(value), "AAAABGFiY2Q=")
        XCTAssertEqual(try ValueXDRJsonCodec.toXdrJson(value), "\"61626364\"")

        let read = try ValueXDRJsonCodec.fromXdrJson("\"61626364\"")
        XCTAssertEqual(try Self.base64(read), "AAAABGFiY2Q=")
    }

    /// SEP-0051 §Opaque Data (Variable Length) gives hex for the bytes, so no bytes is the
    /// empty string. `"0"` would be an odd number of digits and no byte count at all.
    func testEmptyVariableLengthOpaqueDataRendersAsAnEmptyString() throws {
        let value: ValueXDR = Data()
        XCTAssertEqual(try ValueXDRJsonCodec.toXdrJson(value), "\"\"")
        XCTAssertEqual(try ValueXDRJsonCodec.fromXdrJson("\"\""), Data())
    }

    // MARK: - String

    /// The specification's string example carries the byte `0xc3` followed by `w`, which is
    /// not valid UTF-8. This SDK stores every XDR `string<>` as a Swift `String`, which is
    /// guaranteed well-formed Unicode, so those bytes reach the escape ladder through an
    /// opaque field instead: an `AssetCode12` holds them exactly, and SEP-0051 §Asset Code
    /// Types routes it through the same §String ladder. The rendered text is the
    /// specification's, character for character.
    func testStringEscapesBytesOutsidePrintableAscii() throws {
        let bytes = Data("hello".utf8) + Data([0xc3]) + Data("world".utf8) + Data([0x00])
        let code = AssetCode12XDR(bytes)
        XCTAssertEqual(try Self.base64(code), "aGVsbG/Dd29ybGQA")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(code), #""hello\\xc3world""#)

        let read = try AssetCode12XDRJsonCodec.fromXdrJson(#""hello\\xc3world""#)
        XCTAssertEqual(read.wrapped, bytes)
    }

    func testStringEscapesBackslashAndControlBytes() throws {
        let backslash: SCStringXDR = "a\\b"
        XCTAssertEqual(try Self.base64(backslash), "AAAAA2FcYgA=")
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJson(backslash), #""a\\\\b""#)
        XCTAssertEqual(try SCStringXDRJsonCodec.fromXdrJson(#""a\\\\b""#), "a\\b")

        let newline: SCStringXDR = "line1\nline2"
        XCTAssertEqual(try Self.base64(newline), "AAAAC2xpbmUxCmxpbmUyAA==")
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJson(newline), #""line1\\nline2""#)
        XCTAssertEqual(try SCStringXDRJsonCodec.fromXdrJson(#""line1\\nline2""#), "line1\nline2")
    }

    func testPrintableAsciiPassesThroughUnescaped() throws {
        let text: SCStringXDR = "hello world"
        XCTAssertEqual(try Self.base64(text), "AAAAC2hlbGxvIHdvcmxkAA==")
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJson(text), "\"hello world\"")
        XCTAssertEqual(try SCStringXDRJsonCodec.fromXdrJson("\"hello world\""), "hello world")
    }

    // MARK: - Arrays

    /// The specification illustrates the variable-length array with `int identifier<>`
    /// holding `1, 2, 3, 4`. `SorobanResourcesExtV0` declares exactly one such field, so its
    /// binary is the specification's own, framed by nothing else.
    func testVariableLengthArrayRendersAsAJsonArray() throws {
        let value = try XDRDecoder.decode(SorobanResourcesExtV0.self,
                                          data: try Self.data("AAAABAAAAAEAAAACAAAAAwAAAAQ="))
        XCTAssertEqual(value.archivedSorobanEntries, [1, 2, 3, 4])
        XCTAssertEqual(try value.toXdrJson(), "{\"archived_soroban_entries\":[1,2,3,4]}")

        let read = try SorobanResourcesExtV0.fromXdrJson("{\"archived_soroban_entries\":[1,2,3,4]}")
        XCTAssertEqual(try Self.base64(read), "AAAABAAAAAEAAAACAAAAAwAAAAQ=")
    }

    func testEmptyVariableLengthArrayRendersAsAnEmptyJsonArray() throws {
        let value = SorobanResourcesExtV0(archivedSorobanEntries: [])
        XCTAssertEqual(try value.toXdrJson(), "{\"archived_soroban_entries\":[]}")
        XCTAssertEqual(try SorobanResourcesExtV0.fromXdrJson("{\"archived_soroban_entries\":[]}")
                        .archivedSorobanEntries, [])
    }

    /// `LedgerHeader.skipList` is the only fixed-length array of a non-opaque type in the
    /// Stellar XDR set, so it is where the fixed-array rule is pinned. Element order is part
    /// of the assertion: four distinct hashes would compare equal under any ordering bug if
    /// they were identical.
    func testFixedLengthArrayRendersAsAJsonArrayInDeclarationOrder() throws {
        let header = try XDRDecoder.decode(LedgerHeaderXDR.self, data: try Self.data(Self.ledgerHeaderBase64))
        let json = try header.toXdrJson()
        XCTAssertTrue(json.contains(Self.ledgerHeaderSkipList), json)

        let read = try LedgerHeaderXDR.fromXdrJson(json)
        XCTAssertEqual(try Self.base64(read), Self.ledgerHeaderBase64)
    }

    // MARK: - Enum

    func testEnumRendersAsItsSnakeCasedIdentifierWithTheSharedPrefixRemoved() throws {
        let value = try XDRDecoder.decode(SCValType.self, data: try Self.data("AAAAAw=="))
        XCTAssertEqual(value, .u32)
        XCTAssertEqual(try value.toXdrJson(), "\"u32\"")

        let read = try SCValType.fromXdrJson("\"u32\"")
        XCTAssertEqual(try Self.base64(read), "AAAAAw==")
    }

    // MARK: - Struct

    func testStructRendersAsAnObjectKeyedBySnakeCasedFieldNames() throws {
        let base64 = "AQIDBAUGBwgJEBESExQVFhcYGSAhIiMkJSYnKCkwMTIAAAAB"
        let expected = "{\"key_hash\":\"0102030405060708091011121314151617181920212223242526272829303132\","
            + "\"live_until_ledger_seq\":1}"

        let value = try XDRDecoder.decode(TTLEntryXDR.self, data: try Self.data(base64))
        XCTAssertEqual(try value.toXdrJson(), expected)

        let read = try TTLEntryXDR.fromXdrJson(expected)
        XCTAssertEqual(try Self.base64(read), base64)
    }

    // MARK: - Discriminated union

    func testVoidUnionArmRendersAsABareString() throws {
        let value = try XDRDecoder.decode(AssetXDR.self, data: try Self.data("AAAAAA=="))
        XCTAssertEqual(try value.toXdrJson(), "\"native\"")

        let read = try AssetXDR.fromXdrJson("\"native\"")
        XCTAssertEqual(try Self.base64(read), "AAAAAA==")
    }

    func testValueCarryingUnionArmRendersAsASingleKeyObject() throws {
        let base64 = "AAAAAUFCQ0QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        let expected = "{\"credit_alphanum4\":{\"asset_code\":\"ABCD\","
            + "\"issuer\":\"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF\"}}"

        let value = try XDRDecoder.decode(AssetXDR.self, data: try Self.data(base64))
        XCTAssertEqual(try value.toXdrJson(), expected)

        let read = try AssetXDR.fromXdrJson(expected)
        XCTAssertEqual(try Self.base64(read), base64)
    }

    func testIntegerCasedUnionRendersAsTheDiscriminantSuffixedByItsInteger() throws {
        let value = try XDRDecoder.decode(SorobanTransactionMetaExt.self, data: try Self.data("AAAAAA=="))
        XCTAssertEqual(try value.toXdrJson(), "\"v0\"")

        let read = try SorobanTransactionMetaExt.fromXdrJson("\"v0\"")
        XCTAssertEqual(try Self.base64(read), "AAAAAA==")
    }

    // MARK: - Optional data

    func testAbsentOptionalRendersAsNullWithItsKeyStillPresent() throws {
        let base64 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        let expected = "{\"inflation_dest\":null,\"clear_flags\":null,\"set_flags\":null,"
            + "\"master_weight\":null,\"low_threshold\":null,\"med_threshold\":null,"
            + "\"high_threshold\":null,\"home_domain\":null,\"signer\":null}"

        let value = try XDRDecoder.decode(SetOptionsOperationXDR.self, data: try Self.data(base64))
        XCTAssertEqual(try value.toXdrJson(), expected)

        let read = try SetOptionsOperationXDR.fromXdrJson(expected)
        XCTAssertEqual(try Self.base64(read), base64)
    }

    func testPresentOptionalRendersAsItsValue() throws {
        let base64 = "AAAAAAAAAAAAAAABAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        let expected = "{\"inflation_dest\":null,\"clear_flags\":null,\"set_flags\":1,"
            + "\"master_weight\":null,\"low_threshold\":null,\"med_threshold\":null,"
            + "\"high_threshold\":null,\"home_domain\":null,\"signer\":null}"

        let value = try XDRDecoder.decode(SetOptionsOperationXDR.self, data: try Self.data(base64))
        XCTAssertEqual(value.setFlags, 1)
        XCTAssertEqual(try value.toXdrJson(), expected)

        let read = try SetOptionsOperationXDR.fromXdrJson(expected)
        XCTAssertEqual(try Self.base64(read), base64)
    }

    // MARK: - Address types

    func testMuxedScAddressRendersAsAnMStrkey() throws {
        let base64 = "AAAAAgAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        let expected = "\"MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFNZG\""

        let value = try XDRDecoder.decode(SCAddressXDR.self, data: try Self.data(base64))
        XCTAssertEqual(try value.toXdrJson(), expected)

        let read = try SCAddressXDR.fromXdrJson(expected)
        XCTAssertEqual(try Self.base64(read), base64)
    }

    // MARK: - Asset code types

    func testAssetCode4TrimsEveryTrailingNulByte() throws {
        let code = AssetCode4XDR(Data("ABC".utf8) + Data([0x00]))
        XCTAssertEqual(try Self.base64(code), "QUJDAA==")
        XCTAssertEqual(try AssetCode4XDRJsonCodec.toXdrJson(code), "\"ABC\"")

        let read = try AssetCode4XDRJsonCodec.fromXdrJson("\"ABC\"")
        XCTAssertEqual(read.wrapped, Data("ABC".utf8) + Data([0x00]))
    }

    func testAssetCode12KeepsAtLeastFiveBytesAfterTrimming() throws {
        let five = AssetCode12XDR(Data("ABCDE".utf8) + Data(count: 7))
        XCTAssertEqual(try Self.base64(five), "QUJDREUAAAAAAAAA")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(five), "\"ABCDE\"")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.fromXdrJson("\"ABCDE\"").wrapped, five.wrapped)

        let three = AssetCode12XDR(Data("ABC".utf8) + Data(count: 9))
        XCTAssertEqual(try Self.base64(three), "QUJDAAAAAAAAAAAA")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(three), #""ABC\\0\\0""#)
        XCTAssertEqual(try AssetCode12XDRJsonCodec.fromXdrJson(#""ABC\\0\\0""#).wrapped, three.wrapped)
    }

    /// SEP-0051 §Asset Code Types says the `AssetCode` union renders according to its arm,
    /// which makes it a bare string rather than the keyed object a union otherwise takes.
    func testAssetCodeUnionRendersAsABareString() throws {
        let short = try XDRDecoder.decode(AllowTrustOpAssetXDR.self, data: try Self.data("AAAAAUFCQ0Q="))
        XCTAssertEqual(try short.toXdrJson(), "\"ABCD\"")
        XCTAssertEqual(try Self.base64(try AllowTrustOpAssetXDR.fromXdrJson("\"ABCD\"")), "AAAAAUFCQ0Q=")

        let long = try XDRDecoder.decode(AllowTrustOpAssetXDR.self,
                                         data: try Self.data("AAAAAkFCQ0RFAAAAAAAAAA=="))
        XCTAssertEqual(try long.toXdrJson(), "\"ABCDE\"")
        XCTAssertEqual(try Self.base64(try AllowTrustOpAssetXDR.fromXdrJson("\"ABCDE\"")),
                       "AAAAAkFCQ0RFAAAAAAAAAA==")
    }

    // MARK: - Integer types

    func testIntegerPartsTypesRenderAsOneBase10String() throws {
        let i128 = try XDRDecoder.decode(Int128PartsXDR.self,
                                         data: try Self.data("/////////////////////w=="))
        XCTAssertEqual(try i128.toXdrJson(), "\"-1\"")
        XCTAssertEqual(try Self.base64(try Int128PartsXDR.fromXdrJson("\"-1\"")),
                       "/////////////////////w==")

        let u128 = try XDRDecoder.decode(UInt128PartsXDR.self,
                                         data: try Self.data("AAAAAAAAAAAAAAAAAAAAAQ=="))
        XCTAssertEqual(try u128.toXdrJson(), "\"1\"")
        XCTAssertEqual(try Self.base64(try UInt128PartsXDR.fromXdrJson("\"1\"")),
                       "AAAAAAAAAAAAAAAAAAAAAQ==")

        let i256 = try XDRDecoder.decode(Int256PartsXDR.self,
                                         data: try Self.data("//////////////////////////////////////////8="))
        XCTAssertEqual(try i256.toXdrJson(), "\"-1\"")
        XCTAssertEqual(try Self.base64(try Int256PartsXDR.fromXdrJson("\"-1\"")),
                       "//////////////////////////////////////////8=")

        let u256 = try XDRDecoder.decode(UInt256PartsXDR.self,
                                         data: try Self.data("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE="))
        XCTAssertEqual(try u256.toXdrJson(), "\"1\"")
        XCTAssertEqual(try Self.base64(try UInt256PartsXDR.fromXdrJson("\"1\"")),
                       "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE=")
    }

    // MARK: - JSON schema

    /// SEP-0051 §JSON Schema prints this exact document for the `Asset` type. The property is
    /// optional on input and is never part of the output.
    func testSchemaPropertyOfTheSpecificationExampleIsAcceptedAndNotEmitted() throws {
        let document = "{\"$schema\":\"https://stellar.org/schema/xdr-json/main/Asset.json\","
            + "\"credit_alphanum4\":{\"asset_code\":\"ABCD\","
            + "\"issuer\":\"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF\"}}"

        let value = try AssetXDR.fromXdrJson(document)
        XCTAssertEqual(try Self.base64(value),
                       "AAAAAUFCQ0QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
        XCTAssertFalse(try value.toXdrJson().contains("$schema"))
    }

    // MARK: - Fixtures

    /// A ledger header carrying four distinct skip-list hashes. Produced by encoding the JSON
    /// below with the reference implementation, so both sides of the assertion are external.
    private static let ledgerHeaderBase64 =
        "AAAAF6qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqu7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7"
        + "u7u7u7sAAAAAZVPxAAAAAAAAAAAAzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzd3d3d3d3d3d"
        + "3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3QAB4kAN4Lazp2QAAAAAAAAAADA5AAAABwAAAAAAAABjAAAAZABM"
        + "S0AAAAPoAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQECAgICAgICAgICAgICAgICAgICAgICAg"
        + "ICAgICAgICAgMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDBAQEBAQEBAQEBAQEBAQEBAQEBAQE"
        + "BAQEBAQEBAQEBAQAAAAA"

    private static let ledgerHeaderSkipList =
        "\"skip_list\":[\"0101010101010101010101010101010101010101010101010101010101010101\","
        + "\"0202020202020202020202020202020202020202020202020202020202020202\","
        + "\"0303030303030303030303030303030303030303030303030303030303030303\","
        + "\"0404040404040404040404040404040404040404040404040404040404040404\"]"

    // MARK: - Helpers

    private static func data(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64), "not base64: \(base64)")
    }

    private static func base64(_ value: XDREncodable) throws -> String {
        Data(try XDREncoder.encode(value)).base64EncodedString()
    }
}
