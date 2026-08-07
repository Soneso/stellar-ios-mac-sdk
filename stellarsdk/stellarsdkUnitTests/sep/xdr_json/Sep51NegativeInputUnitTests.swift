//
//  Sep51NegativeInputUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// One test per input this SDK refuses, each asserting the specific error it raises.
///
/// Two kinds of rejection are gathered here. Some are required by SEP-0051: a required key
/// that is absent, an object key repeated, a key the type does not declare, a string that
/// names no member of its enumeration, an object that is not the single-key shape a union arm
/// takes. Others are narrowings this SDK applies on top: hexadecimal must be lowercase and of
/// even length, an escape must be one the specification's ladder produces and its hexadecimal
/// digits must be lowercase, and an integer must be written as base-10 digits rather than
/// `1.0`, `1e10`, `0x10` or `+1`. Everything this SDK emits stays inside what a conforming
/// reader accepts, so narrowing what it reads costs no interoperability.
///
/// Asserting the error case rather than merely that something was thrown is the point: a
/// caller distinguishes a field it does not know from a value it cannot represent, and a test
/// that accepted any error would not notice the two collapsing into one. The type and key an
/// error carries are asserted for the same reason: they are what locates the offending value
/// in the document, so they name what the document declares rather than the typedef a field
/// happens to be spelled with.
final class Sep51NegativeInputUnitTests: XCTestCase {

    // MARK: - Hexadecimal

    func testUppercaseHexadecimalIsRejected() {
        let uppercase = "\"000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F\""

        XCTAssertThrowsError(try HashXDRJsonCodec.fromXdrJson(uppercase)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "HashXDR")
            XCTAssertTrue(message.contains("lowercase hexadecimal"), message)
        }
    }

    func testOddLengthHexadecimalIsRejected() {
        XCTAssertThrowsError(try ValueXDRJsonCodec.fromXdrJson("\"abc\"")) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ValueXDR")
            XCTAssertTrue(message.contains("odd number of digits"), message)
        }
    }

    func testFixedWidthOpaqueRejectsTheWrongNumberOfBytes() {
        let tooLong = "\"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20\""

        XCTAssertThrowsError(try HashXDRJsonCodec.fromXdrJson(tooLong)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "HashXDR")
            XCTAssertTrue(message.contains("expected 32 bytes, got 33"), message)
        }

        XCTAssertThrowsError(try ThresholdsXDRJsonCodec.fromXdrJson("\"010203\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ThresholdsXDR")
            XCTAssertNil(key)
            XCTAssertTrue(message.contains("expected 4 bytes, got 3"), message)
        }
    }

    // MARK: - String escapes

    func testUppercaseHexadecimalEscapeIsRejected() {
        XCTAssertThrowsError(try AssetCode12XDRJsonCodec.fromXdrJson(#""ABCD\\xC3""#)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AssetCode12XDR")
            XCTAssertTrue(message.contains("two lowercase hexadecimal digits"), message)
        }
    }

    func testUnrecognisedEscapeIsRejected() {
        XCTAssertThrowsError(try AssetCode12XDRJsonCodec.fromXdrJson(#""ABCD\\q""#)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AssetCode12XDR")
            XCTAssertTrue(message.contains("unrecognised escape sequence"), message)
        }
    }

    func testTrailingBackslashIsRejected() {
        XCTAssertThrowsError(try AssetCode12XDRJsonCodec.fromXdrJson(#""ABCDE\\""#)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AssetCode12XDR")
            XCTAssertTrue(message.contains("trailing backslash"), message)
        }
    }

    // MARK: - Integer literals

    func testExponentNotationIsRejectedForAnIntegerField() {
        XCTAssertThrowsError(try Self.timeBounds(minTime: "1e10")) { error in
            Self.assertNotABase10Integer(error, literal: "1e10")
        }
        XCTAssertThrowsError(try Self.timeBounds(minTime: "\"1e10\"")) { error in
            Self.assertNotABase10Integer(error, literal: "1e10")
        }
    }

    func testFractionalNotationIsRejectedForAnIntegerField() {
        XCTAssertThrowsError(try Self.timeBounds(minTime: "1.0")) { error in
            Self.assertNotABase10Integer(error, literal: "1.0")
        }
        XCTAssertThrowsError(try Self.timeBounds(minTime: "\"1.0\"")) { error in
            Self.assertNotABase10Integer(error, literal: "1.0")
        }
    }

    func testHexadecimalNotationIsRejectedForAnIntegerField() {
        XCTAssertThrowsError(try Self.timeBounds(minTime: "\"0x10\"")) { error in
            Self.assertNotABase10Integer(error, literal: "0x10")
        }
        XCTAssertThrowsError(try Self.timeBounds(minTime: "0x10")) { error in
            guard case XdrJsonError.malformedJson = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    func testLeadingPlusIsRejectedForAnIntegerField() {
        XCTAssertThrowsError(try Self.timeBounds(minTime: "\"+1\"")) { error in
            Self.assertNotABase10Integer(error, literal: "+1")
        }
        XCTAssertThrowsError(try Self.timeBounds(minTime: "+1")) { error in
            guard case XdrJsonError.malformedJson = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    func testSurroundingWhitespaceInsideAnIntegerStringIsRejected() {
        XCTAssertThrowsError(try Self.timeBounds(minTime: "\" 1\"")) { error in
            Self.assertNotABase10Integer(error, literal: " 1")
        }
    }

    func testIntegerOutsideTheWidthOfItsFieldIsRejected() {
        XCTAssertThrowsError(try Self.timeBounds(minTime: "\"18446744073709551616\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(key, "min_time")
            XCTAssertTrue(message.contains("out of range for uint64"), message)
        }

        XCTAssertThrowsError(try Int64XDRJsonCodec.fromXdrJson("\"9223372036854775808\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "Int64XDR")
            XCTAssertNil(key)
            XCTAssertTrue(message.contains("out of range for int64"), message)
        }
    }

    // MARK: - Object shape

    func testAbsentDeclaredKeyIsRejected() {
        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson("{\"min_time\":\"0\"}")) { error in
            guard case XdrJsonError.missingField(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(key, "max_time")
        }
    }

    func testRepeatedKeyIsRejectedInTextAndInATreeBuiltByHand() {
        let document = "{\"min_time\":\"0\",\"min_time\":\"1\",\"max_time\":\"2\"}"
        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.malformedJson(let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertTrue(message.contains("duplicate object key"), message)
        }

        let tree = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "min_time", value: .string("1")),
            XdrJsonMember(key: "max_time", value: .string("2"))
        ])
        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJsonTree(tree)) { error in
            guard case XdrJsonError.duplicateKey(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(key, "min_time")
        }
    }

    func testUndeclaredKeyIsRejected() {
        let document = "{\"min_time\":\"0\",\"max_time\":\"1\",\"mid_time\":\"2\"}"

        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.unknownField(let type, let keys, let declared) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(keys, ["mid_time"])
            XCTAssertEqual(declared, ["min_time", "max_time"])

            let rendered = (error as? XdrJsonError)?.message ?? ""
            XCTAssertTrue(rendered.contains("unknown key \"mid_time\""), rendered)
            XCTAssertTrue(rendered.contains("declared keys are min_time, max_time"), rendered)
        }
    }

    func testSeveralUndeclaredKeysAreAllReported() {
        let document = "{\"min_time\":\"0\",\"max_time\":\"1\",\"a\":1,\"b\":2}"

        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.unknownField(_, let keys, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(keys, ["a", "b"])
        }
    }

    /// `type` and `type_` are two spellings of one declared key, so a document carrying both
    /// carries that key twice. Values that agree are the case worth pinning: an
    /// implementation that quietly preferred the canonical spelling would let it through.
    func testBothSpellingsOfTheReservedFieldNameAreRejectedEvenWhenTheirValuesAgree() {
        let hash = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
        let document = "{\"type\":\"error_msg\",\"type_\":\"error_msg\",\"req_hash\":\"\(hash)\"}"

        XCTAssertThrowsError(try DontHaveXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.duplicateKey(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "DontHaveXDR")
            XCTAssertEqual(key, "type")
        }
    }

    func testValueOfTheWrongJsonTypeIsRejected() {
        XCTAssertThrowsError(try ErrorXDR.fromXdrJson("{\"code\":\"misc\",\"msg\":7}")) { error in
            guard case XdrJsonError.unexpectedType(let type, let key, let expected, let got) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ErrorXDR")
            XCTAssertEqual(key, "msg")
            XCTAssertEqual(expected, "string")
            XCTAssertEqual(got, "number")
        }
    }

    func testArrayFieldGivenANonArrayIsRejected() {
        let document = "{\"num_sponsored\":1,\"num_sponsoring\":2,"
            + "\"signer_sponsoring_i_ds\":\"none\",\"ext\":\"v0\"}"

        XCTAssertThrowsError(try AccountEntryExtensionV2.fromXdrJson(document)) { error in
            guard case XdrJsonError.unexpectedType(let type, let key, let expected, let got) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtensionV2")
            XCTAssertEqual(key, "signer_sponsoring_i_ds")
            XCTAssertEqual(expected, "array")
            XCTAssertEqual(got, "string")
        }
    }

    // MARK: - Enumerations and unions

    func testStringNamingNoEnumerationMemberIsRejected() {
        XCTAssertThrowsError(try SCValType.fromXdrJson("\"u33\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCValType")
            XCTAssertEqual(value, "u33")
        }
    }

    func testObjectKeyNamingNoUnionArmIsRejected() {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("{\"u33\":1}")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "u33")
        }
    }

    func testStringNamingNoVoidUnionArmIsRejected() {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"nothing\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "nothing")
        }
    }

    func testUnionObjectCarryingMoreThanOneKeyIsRejected() {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("{\"u32\":1,\"i32\":2}")) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertTrue(message.contains("single-key object"), message)
            XCTAssertTrue(message.contains("got 2 keys"), message)
        }
    }

    // MARK: - Where a failure is reported

    /// An element is located by the array field that holds it, since an element carries no key
    /// of its own. `tx_hashes` holds `Hash`, a typedef, which the document never names.
    func testFailureInsideAnArrayElementNamesTheArrayFieldAndItsKey() {
        XCTAssertThrowsError(try FreezeBypassTxsXDR.fromXdrJson("{\"tx_hashes\":[\"abc\"]}")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "FreezeBypassTxsXDR")
            XCTAssertEqual(key, "tx_hashes")
            XCTAssertTrue(message.contains("odd number of digits"), message)
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "FreezeBypassTxsXDR.tx_hashes: hex string has an odd number of digits: abc")
        }
    }

    /// A union arm is located by the union and the arm key, which together are the path the
    /// document is written under. `hash` carries the `Hash` typedef.
    func testFailureInsideAUnionArmNamesTheUnionAndTheArm() {
        let uppercase = "{\"hash\":\"000102030405060708090A0B0C0D0E0F101112131415161718191a1b1c1d1e1f\"}"

        XCTAssertThrowsError(try MemoXDR.fromXdrJson(uppercase)) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "MemoXDR")
            XCTAssertEqual(key, "hash")
            XCTAssertTrue(message.contains("lowercase hexadecimal"), message)
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "MemoXDR.hash: hex string is not lowercase hexadecimal: " +
                           "000102030405060708090A0B0C0D0E0F101112131415161718191a1b1c1d1e1f")
        }
    }

    /// A codec called with no enclosing site has only its own name to report, which is the one
    /// position where a typedef names itself.
    func testFailureInAStandaloneTypedefConversionNamesTheTypedef() {
        XCTAssertThrowsError(try TimePointXDRJsonCodec.fromXdrJson("\"1e10\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimePointXDR")
            XCTAssertNil(key)
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "TimePointXDR: not a base-10 integer: 1e10")
        }
    }

    /// A union rendered as a bare strkey still locates a failure by its arm, even though the arm
    /// key never reaches the document: the arm is what selects the wire form, so it is what a
    /// caller needs in order to find the value.
    func testFailureInAStrKeyUnionArmNamesTheUnionAndTheArm() {
        let notAStrKey = "\"LBADBADBADBADBADBADBADBADBADBADBADBADBADBADBADBADBADBAD\""

        XCTAssertThrowsError(try SCAddressXDR.fromXdrJson(notAStrKey)) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCAddressXDR")
            XCTAssertEqual(key, "liquidity_pool")
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "SCAddressXDR.liquidity_pool: not a valid strkey: " +
                           "LBADBADBADBADBADBADBADBADBADBADBADBADBADBADBADBADBADBAD")
        }

        let overLong = SCAddressXDR.contract(WrappedData32(Data(repeating: 0x01, count: 33)))
        XCTAssertThrowsError(try overLong.toXdrJson()) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCAddressXDR")
            XCTAssertEqual(key, "contract")
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "SCAddressXDR.contract: expected 32 bytes, got 33")
        }
    }

    /// The asset-code union renders as a bare string as well, and each width is located by its
    /// own arm rather than by the asset-code typedef that formats it.
    func testFailureInAnAssetCodeArmNamesTheUnionAndTheWidth() {
        let overLong4 = AllowTrustOpAssetXDR.alphanum4(WrappedData4(Data(repeating: 0x41, count: 5)))
        XCTAssertThrowsError(try overLong4.toXdrJson()) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AllowTrustOpAssetXDR")
            XCTAssertEqual(key, "credit_alphanum4")
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "AllowTrustOpAssetXDR.credit_alphanum4: expected 4 bytes, got 5")
        }

        let overLong12 = AllowTrustOpAssetXDR.alphanum12(
            WrappedData12(Data(repeating: 0x41, count: 13)))
        XCTAssertThrowsError(try overLong12.toXdrJson()) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AllowTrustOpAssetXDR")
            XCTAssertEqual(key, "credit_alphanum12")
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "AllowTrustOpAssetXDR.credit_alphanum12: expected 12 bytes, got 13")
        }
    }

    // MARK: - Document shape

    func testTextThatIsNotWellFormedJsonIsRejected() {
        for document in ["{", "{\"min_time\":}", "{\"min_time\":\"0\",}", "\"unterminated",
                         "{\"min_time\":\"0\",\"max_time\":\"1\"} trailing"] {
            XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document), "accepted \(document)") { error in
                guard case XdrJsonError.malformedJson = error else {
                    return XCTFail("wrong error for \(document): \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    private static func timeBounds(minTime: String) throws -> TimeBoundsXDR {
        try TimeBoundsXDR.fromXdrJson("{\"min_time\":\(minTime),\"max_time\":\"1\"}")
    }

    /// The literal appears in the message so a caller can see which value was refused, and the
    /// type and key are the ones the document is written under.
    ///
    /// `min_time` is declared as `TimePoint`, itself a typedef over `Uint64`. Neither name
    /// occurs in the document, so a message naming either would send a caller looking for a
    /// key that is not there. The whole rendering is pinned, because a payload carrying the
    /// right type with the wrong key still locates the failure wrongly.
    private static func assertNotABase10Integer(_ error: Error, literal: String) {
        guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
            return XCTFail("wrong error: \(error)")
        }
        XCTAssertEqual(type, "TimeBoundsXDR")
        XCTAssertEqual(key, "min_time")
        XCTAssertTrue(message.contains("not a base-10 integer"), message)
        XCTAssertTrue(message.contains(literal), message)
        XCTAssertEqual((error as? XdrJsonError)?.message,
                       "TimeBoundsXDR.min_time: not a base-10 integer: \(literal)")
    }
}
