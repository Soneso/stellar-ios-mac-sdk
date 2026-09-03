//
//  SCValXDRToNativeUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 02.09.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Tests for the native Swift value conversion of `SCValXDR` and for the strkey
/// accessor of `SCAddressXDR`.
///
/// Every value is built in the test, so no network or ledger state is involved. The
/// strkey literals come from existing tests of this target, which assert them valid.
class SCValXDRToNativeUnitTests: XCTestCase {

    private let accountId = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
    private let muxedAccountId = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
    private let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let claimableBalanceId = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
    private let liquidityPoolId = "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"

    private let maxU128 = "340282366920938463463374607431768211455"
    private let minI128 = "-170141183460469231731687303715884105728"
    private let maxI128 = "170141183460469231731687303715884105727"
    private let maxU256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
    private let minI256 = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"

    // MARK: - Helpers

    /// Asserts that the conversion handed the value back: the result is an `SCValXDR`
    /// carrying the same wire encoding as the value that went in.
    private func assertIsValueItself(_ result: Any?, _ original: SCValXDR,
                                     file: StaticString = #filePath, line: UInt = #line) {
        guard let returned = result as? SCValXDR else {
            XCTFail("expected the SCValXDR itself", file: file, line: line)
            return
        }
        XCTAssertNotNil(original.xdrEncoded, file: file, line: line)
        XCTAssertEqual(returned.xdrEncoded, original.xdrEncoded, file: file, line: line)
    }

    /// The dictionary a map value converts to, or a failure if it did not convert.
    private func dictionary(of value: SCValXDR,
                            file: StaticString = #filePath, line: UInt = #line) throws -> [AnyHashable: Any?] {
        let result = value.toNative()
        XCTAssertFalse(result is SCValXDR, "the map was expected to convert", file: file, line: line)
        return try XCTUnwrap(result as? [AnyHashable: Any?], file: file, line: line)
    }

    /// The array a vec value converts to, or a failure if it did not convert.
    private func array(of value: SCValXDR,
                       file: StaticString = #filePath, line: UInt = #line) throws -> [Any?] {
        return try XCTUnwrap(value.toNative() as? [Any?], file: file, line: line)
    }

    private func entry(_ key: SCValXDR, _ value: SCValXDR) -> SCMapEntryXDR {
        return SCMapEntryXDR(key: key, val: value)
    }

    // MARK: - Booleans and void

    func testBool() {
        let trueResult = SCValXDR.bool(true).toNative()
        XCTAssertTrue(trueResult is Bool)
        XCTAssertEqual(trueResult as? Bool, true)

        let falseResult = SCValXDR.bool(false).toNative()
        XCTAssertTrue(falseResult is Bool)
        XCTAssertEqual(falseResult as? Bool, false)
    }

    func testVoid() {
        XCTAssertNil(SCValXDR.void.toNative())
    }

    // MARK: - Fixed width integers

    func testU32() {
        let zero = SCValXDR.u32(0).toNative()
        XCTAssertTrue(zero is UInt32)
        XCTAssertEqual(zero as? UInt32, 0)

        let max = SCValXDR.u32(4294967295).toNative()
        XCTAssertTrue(max is UInt32)
        XCTAssertEqual(max as? UInt32, UInt32.max)
    }

    func testI32() {
        let min = SCValXDR.i32(Int32.min).toNative()
        XCTAssertTrue(min is Int32)
        XCTAssertEqual(min as? Int32, Int32.min)

        let max = SCValXDR.i32(Int32.max).toNative()
        XCTAssertTrue(max is Int32)
        XCTAssertEqual(max as? Int32, Int32.max)
    }

    func testU64() {
        let zero = SCValXDR.u64(0).toNative()
        XCTAssertTrue(zero is UInt64)
        XCTAssertEqual(zero as? UInt64, 0)

        // A u64 above Int.max keeps its value, so the result is a UInt64 and not an Int.
        let max = SCValXDR.u64(18446744073709551615).toNative()
        XCTAssertTrue(max is UInt64)
        XCTAssertFalse(max is Int)
        XCTAssertEqual(max as? UInt64, UInt64.max)
    }

    func testI64() {
        let min = SCValXDR.i64(Int64.min).toNative()
        XCTAssertTrue(min is Int64)
        XCTAssertEqual(min as? Int64, Int64.min)

        let max = SCValXDR.i64(Int64.max).toNative()
        XCTAssertTrue(max is Int64)
        XCTAssertEqual(max as? Int64, Int64.max)
    }

    func testTimepoint() {
        let result = SCValXDR.timepoint(1700000000).toNative()
        XCTAssertTrue(result is UInt64)
        XCTAssertEqual(result as? UInt64, 1700000000)
    }

    func testDuration() {
        let result = SCValXDR.duration(UInt64.max).toNative()
        XCTAssertTrue(result is UInt64)
        XCTAssertEqual(result as? UInt64, UInt64.max)
    }

    // MARK: - 128 and 256 bit integers

    func testU128() throws {
        let result = try SCValXDR.u128(stringValue: maxU128).toNative()
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, maxU128)
    }

    func testI128() throws {
        let min = try SCValXDR.i128(stringValue: minI128).toNative()
        XCTAssertTrue(min is String)
        XCTAssertEqual(min as? String, minI128)

        let negativeOne = try SCValXDR.i128(stringValue: "-1").toNative()
        XCTAssertEqual(negativeOne as? String, "-1")
    }

    func testU256() throws {
        let result = try SCValXDR.u256(stringValue: maxU256).toNative()
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, maxU256)
    }

    func testI256() throws {
        let result = try SCValXDR.i256(stringValue: minI256).toNative()
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, minI256)
    }

    // MARK: - Bytes, strings and symbols

    func testBytes() {
        let payload = Data([0, 1, 255])
        let result = SCValXDR.bytes(payload).toNative()
        XCTAssertTrue(result is Data)
        XCTAssertEqual(result as? Data, payload)
    }

    func testString() {
        let plain = SCValXDR.string("hello").toNative()
        XCTAssertTrue(plain is String)
        XCTAssertEqual(plain as? String, "hello")

        // A multi byte text passes through unchanged.
        let unicode = "grüße 日本語"
        XCTAssertEqual(SCValXDR.string(unicode).toNative() as? String, unicode)
    }

    func testSymbol() {
        let result = SCValXDR.symbol("transfer").toNative()
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, "transfer")
    }

    // MARK: - Vectors

    func testVecKeepsElementOrderAndTypes() throws {
        let elements = try array(of: .vec([.u32(1), .symbol("a"), .vec([.bool(true)])]))
        XCTAssertEqual(elements.count, 3)
        XCTAssertTrue(elements[0] is UInt32)
        XCTAssertEqual(elements[0] as? UInt32, 1)
        XCTAssertEqual(elements[1] as? String, "a")

        let nested = try XCTUnwrap(elements[2] as? [Any?])
        XCTAssertEqual(nested.count, 1)
        XCTAssertEqual(nested[0] as? Bool, true)
    }

    func testEmptyAndAbsentVec() throws {
        XCTAssertEqual(try array(of: .vec([])).count, 0)
        XCTAssertEqual(try array(of: .vec(nil)).count, 0)
    }

    func testVecWithVoidElement() throws {
        let elements = try array(of: .vec([.void, .u32(1)]))
        XCTAssertEqual(elements.count, 2)
        XCTAssertNil(elements[0])
        XCTAssertEqual(elements[1] as? UInt32, 1)
    }

    func testVecContainsUnconvertedMap() throws {
        let mapWithVecKey = SCValXDR.map([entry(.vec([.u32(1)]), .u32(2))])
        let elements = try array(of: .vec([.u32(7), mapWithVecKey]))
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(elements[0] as? UInt32, 7)
        assertIsValueItself(elements[1], mapWithVecKey)
    }

    // MARK: - Maps that convert

    func testMapWithSymbolKeys() throws {
        let fields = try dictionary(of: .map([
            entry(.symbol("name"), .string("Alice")),
            entry(.symbol("age"), .u32(30)),
        ]))
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(fields["name"] as? String, "Alice")
        XCTAssertEqual(fields["age"] as? UInt32, 30)
    }

    func testMapWithU32Keys() throws {
        let fields = try dictionary(of: .map([
            entry(.u32(1), .symbol("one")),
            entry(.u32(2), .symbol("two")),
        ]))
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(fields[UInt32(1)] as? String, "one")
        XCTAssertEqual(fields[UInt32(2)] as? String, "two")
        // Keys compare as AnyHashable, which reads the fixed width integers as one
        // number, so an Int of the same value finds the entry too.
        XCTAssertEqual(fields[Int(1)] as? String, "one")
    }

    func testMapWithI64Key() throws {
        let fields = try dictionary(of: .map([entry(.i64(-5), .symbol("negative"))]))
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields[Int64(-5)] as? String, "negative")
    }

    func testMapWithU64Key() throws {
        let fields = try dictionary(of: .map([entry(.u64(UInt64.max), .symbol("top"))]))
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields[UInt64.max] as? String, "top")
    }

    func testMapWithI128Key() throws {
        let key = try SCValXDR.i128(stringValue: maxI128)
        let fields = try dictionary(of: .map([entry(key, .symbol("wide"))]))
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields[maxI128] as? String, "wide")
    }

    func testMapWithBoolKey() throws {
        let fields = try dictionary(of: .map([entry(.bool(true), .u32(1))]))
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields[true] as? UInt32, 1)
    }

    func testMapWithBytesKey() throws {
        let key = Data([1, 2])
        let fields = try dictionary(of: .map([entry(.bytes(key), .symbol("bytes"))]))
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields[key] as? String, "bytes")
    }

    func testMapWithEveryRepresentableKeyKind() throws {
        let fields = try dictionary(of: .map([
            entry(.bool(true), .symbol("bool")),
            entry(.u32(1), .symbol("u32")),
            entry(.i32(-2), .symbol("i32")),
            entry(.u64(3), .symbol("u64")),
            entry(.i64(-4), .symbol("i64")),
            entry(.timepoint(5), .symbol("timepoint")),
            entry(.duration(6), .symbol("duration")),
            entry(try SCValXDR.u128(stringValue: "7"), .symbol("u128")),
            entry(try SCValXDR.i128(stringValue: "-8"), .symbol("i128")),
            entry(try SCValXDR.u256(stringValue: "9"), .symbol("u256")),
            entry(try SCValXDR.i256(stringValue: "-10"), .symbol("i256")),
            entry(.bytes(Data([11])), .symbol("bytes")),
            entry(.string("text"), .symbol("string")),
            entry(.symbol("sym"), .symbol("symbol")),
            entry(.address(try SCAddressXDR(accountId: accountId)), .symbol("address")),
        ]))
        XCTAssertEqual(fields.count, 15)
        XCTAssertEqual(fields[true] as? String, "bool")
        XCTAssertEqual(fields[UInt32(1)] as? String, "u32")
        XCTAssertEqual(fields[Int32(-2)] as? String, "i32")
        XCTAssertEqual(fields[UInt64(3)] as? String, "u64")
        XCTAssertEqual(fields[Int64(-4)] as? String, "i64")
        XCTAssertEqual(fields[UInt64(5)] as? String, "timepoint")
        XCTAssertEqual(fields[UInt64(6)] as? String, "duration")
        XCTAssertEqual(fields["7"] as? String, "u128")
        XCTAssertEqual(fields["-8"] as? String, "i128")
        XCTAssertEqual(fields["9"] as? String, "u256")
        XCTAssertEqual(fields["-10"] as? String, "i256")
        XCTAssertEqual(fields[Data([11])] as? String, "bytes")
        XCTAssertEqual(fields["text"] as? String, "string")
        XCTAssertEqual(fields["sym"] as? String, "symbol")
        XCTAssertEqual(fields[accountId] as? String, "address")
    }

    func testMapKeepsVoidValue() throws {
        let fields = try dictionary(of: .map([
            entry(.symbol("a"), .void),
            entry(.symbol("b"), .u32(1)),
        ]))
        XCTAssertEqual(fields.count, 2)
        guard let stored = fields["a"] else {
            XCTFail("the entry with the void value is missing")
            return
        }
        XCTAssertNil(stored)
        XCTAssertEqual(fields["b"] as? UInt32, 1)
    }

    func testMapWithAddressKeys() throws {
        let fields = try dictionary(of: .map([
            entry(.address(try SCAddressXDR(accountId: accountId)), .symbol("account")),
            entry(.address(try SCAddressXDR(contractId: contractId)), .symbol("contract")),
            entry(.address(try SCAddressXDR(accountId: muxedAccountId)), .symbol("muxed")),
            entry(.address(try SCAddressXDR(claimableBalanceId: claimableBalanceId)), .symbol("balance")),
            entry(.address(try SCAddressXDR(liquidityPoolId: liquidityPoolId)), .symbol("pool")),
        ]))
        XCTAssertEqual(fields.count, 5)
        XCTAssertEqual(fields[accountId] as? String, "account")
        XCTAssertEqual(fields[contractId] as? String, "contract")
        XCTAssertEqual(fields[muxedAccountId] as? String, "muxed")
        XCTAssertEqual(fields[claimableBalanceId] as? String, "balance")
        XCTAssertEqual(fields[liquidityPoolId] as? String, "pool")
    }

    func testEmptyAndAbsentMap() throws {
        XCTAssertEqual(try dictionary(of: .map([])).count, 0)
        XCTAssertEqual(try dictionary(of: .map(nil)).count, 0)
    }

    func testNestedMapConvertsWithinAMap() throws {
        let outer = try dictionary(of: .map([
            entry(.symbol("inner"), .map([entry(.symbol("x"), .u32(1))])),
        ]))
        XCTAssertEqual(outer.count, 1)
        let inner = try XCTUnwrap(outer["inner"] as? [AnyHashable: Any?])
        XCTAssertEqual(inner.count, 1)
        XCTAssertEqual(inner["x"] as? UInt32, 1)
    }

    // MARK: - Maps that stay unconverted

    func testMapWithVoidKey() {
        let value = SCValXDR.map([entry(.void, .u32(1))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithVecKey() {
        let value = SCValXDR.map([entry(.vec([.u32(1)]), .u32(2))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithMapKey() {
        let value = SCValXDR.map([entry(.map([entry(.symbol("k"), .u32(1))]), .u32(2))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithErrorKey() {
        let value = SCValXDR.map([entry(.error(.contract(1)), .u32(2))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithContractInstanceKey() {
        let instance = SCContractInstanceXDR(executable: .token, storage: nil)
        let value = SCValXDR.map([entry(.contractInstance(instance), .u32(1))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithLedgerKeyContractInstanceKey() {
        let value = SCValXDR.map([entry(.ledgerKeyContractInstance, .u32(1))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithLedgerKeyNonceKey() {
        let value = SCValXDR.map([entry(.ledgerKeyNonce(SCNonceKeyXDR(nonce: 7)), .u32(1))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithExecutableTagKey() {
        let value = SCValXDR.map([entry(.executableTag(Data([0xFF])), .u32(1))])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithRepeatedKey() {
        let value = SCValXDR.map([
            entry(.symbol("a"), .u32(1)),
            entry(.symbol("a"), .u32(2)),
        ])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithNumericallyEqualKeys() {
        // A u32 key and a u64 key of the same value are equal as AnyHashable.
        let value = SCValXDR.map([
            entry(.u32(5), .symbol("u32")),
            entry(.u64(5), .symbol("u64")),
        ])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithWideIntegerAndSymbolKeysOfTheSameDigits() throws {
        // A 128 bit key reads as its decimal string, which the symbol of the same digits
        // equals.
        let value = SCValXDR.map([
            entry(try SCValXDR.u128(stringValue: "5"), .symbol("u128")),
            entry(.symbol("5"), .symbol("symbol")),
        ])
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithNestedUnconvertedMap() throws {
        // The enclosing map still converts; the nested one comes back as the value itself.
        let nested = SCValXDR.map([entry(.void, .u32(1))])
        let outer = try dictionary(of: .map([entry(.symbol("inner"), nested)]))
        XCTAssertEqual(outer.count, 1)
        assertIsValueItself(outer["inner"] ?? nil, nested)
    }

    // MARK: - Keys that stay apart

    func testSymbolAndU32KeysOfTheSameDigitsStayApart() throws {
        let fields = try dictionary(of: .map([
            entry(.symbol("5"), .symbol("symbol")),
            entry(.u32(5), .symbol("u32")),
        ]))
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(fields["5"] as? String, "symbol")
        XCTAssertEqual(fields[UInt32(5)] as? String, "u32")
    }

    func testBytesAndSymbolKeysStayApart() throws {
        let fields = try dictionary(of: .map([
            entry(.bytes(Data([0x35])), .symbol("bytes")),
            entry(.symbol("5"), .symbol("symbol")),
        ]))
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(fields[Data([0x35])] as? String, "bytes")
        XCTAssertEqual(fields["5"] as? String, "symbol")
    }

    func testBoolAndU32KeysStayApart() throws {
        // Bool takes no part in the numeric reading, so true and 1 are two keys.
        let fields = try dictionary(of: .map([
            entry(.bool(true), .symbol("bool")),
            entry(.u32(1), .symbol("u32")),
        ]))
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(fields[true] as? String, "bool")
        XCTAssertEqual(fields[UInt32(1)] as? String, "u32")
    }

    // MARK: - Addresses

    func testAccountAddressValue() throws {
        let result = SCValXDR.address(try SCAddressXDR(accountId: accountId)).toNative()
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, accountId)
    }

    func testMuxedAccountAddressValue() throws {
        let result = SCValXDR.address(try SCAddressXDR(accountId: muxedAccountId)).toNative()
        XCTAssertEqual(result as? String, muxedAccountId)
    }

    func testContractAddressValue() throws {
        let result = SCValXDR.address(try SCAddressXDR(contractId: contractId)).toNative()
        XCTAssertEqual(result as? String, contractId)
    }

    func testClaimableBalanceAddressValue() throws {
        let result = SCValXDR.address(try SCAddressXDR(claimableBalanceId: claimableBalanceId)).toNative()
        XCTAssertEqual(result as? String, claimableBalanceId)
    }

    func testLiquidityPoolAddressValue() throws {
        let result = SCValXDR.address(try SCAddressXDR(liquidityPoolId: liquidityPoolId)).toNative()
        XCTAssertEqual(result as? String, liquidityPoolId)
    }

    func testToStrKeyReturnsTheSourceStrKey() throws {
        XCTAssertEqual(try SCAddressXDR(accountId: accountId).toStrKey(), accountId)
        XCTAssertEqual(try SCAddressXDR(accountId: muxedAccountId).toStrKey(), muxedAccountId)
        XCTAssertEqual(try SCAddressXDR(contractId: contractId).toStrKey(), contractId)
        XCTAssertEqual(try SCAddressXDR(claimableBalanceId: claimableBalanceId).toStrKey(), claimableBalanceId)
        XCTAssertEqual(try SCAddressXDR(liquidityPoolId: liquidityPoolId).toStrKey(), liquidityPoolId)
    }

    func testToStrKeyThrowsOnAnIllFormedPayload() {
        // A contract id of 33 bytes reaches the strkey encoder, which rejects the width.
        let address = SCAddressXDR.contract(WrappedData32(Data(count: 33)))
        XCTAssertThrowsError(try address.toStrKey())
    }

    func testAddressWithoutStrKeyStaysTheValueItself() {
        // A contract id of 33 bytes has no strkey, and WrappedData32 pads a shorter
        // payload to 32 bytes, so an oversized one is what reaches the encoder.
        let value = SCValXDR.address(.contract(WrappedData32(Data(count: 33))))
        assertIsValueItself(value.toNative(), value)
    }

    func testMapWithAddressKeyWithoutStrKey() {
        let value = SCValXDR.map([
            entry(.address(.contract(WrappedData32(Data(count: 33)))), .u32(1)),
        ])
        assertIsValueItself(value.toNative(), value)
    }

    // MARK: - Arms with no native counterpart

    func testError() {
        let value = SCValXDR.error(.contract(1))
        assertIsValueItself(value.toNative(), value)
    }

    func testContractInstance() {
        let value = SCValXDR.contractInstance(SCContractInstanceXDR(executable: .token, storage: nil))
        assertIsValueItself(value.toNative(), value)
    }

    func testLedgerKeyContractInstance() {
        let value = SCValXDR.ledgerKeyContractInstance
        assertIsValueItself(value.toNative(), value)
    }

    func testLedgerKeyNonce() {
        let value = SCValXDR.ledgerKeyNonce(SCNonceKeyXDR(nonce: 42))
        assertIsValueItself(value.toNative(), value)
    }

    func testExecutableTag() {
        // The tag bytes need not be valid UTF-8, so they take no String conversion.
        let value = SCValXDR.executableTag(Data([0xFF, 0xFE]))
        assertIsValueItself(value.toNative(), value)
    }

    // MARK: - Round trip through the wire format

    func testConversionAfterDecodingFromXdr() throws {
        let original = SCValXDR.map([
            entry(.symbol("items"), .vec([.u32(1), .symbol("a")])),
            entry(.symbol("amount"), try SCValXDR.i128(stringValue: minI128)),
            entry(.symbol("owner"), .address(try SCAddressXDR(accountId: accountId))),
            entry(.symbol("nonce"), .u64(18446744073709551615)),
            entry(.symbol("salt"), .bytes(Data([0x01, 0x02]))),
        ])
        let encoded = try XCTUnwrap(original.xdrEncoded)
        let decoded = try SCValXDR.fromXdr(base64: encoded)

        let fromValue = try dictionary(of: original)
        let fromWire = try dictionary(of: decoded)
        XCTAssertEqual(fromWire.count, 5)
        XCTAssertEqual(fromValue.count, fromWire.count)

        for fields in [fromValue, fromWire] {
            let items = try XCTUnwrap(fields["items"] as? [Any?])
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0] as? UInt32, 1)
            XCTAssertEqual(items[1] as? String, "a")
            XCTAssertEqual(fields["amount"] as? String, minI128)
            XCTAssertEqual(fields["owner"] as? String, accountId)
            XCTAssertEqual(fields["nonce"] as? UInt64, UInt64.max)
            XCTAssertEqual(fields["salt"] as? Data, Data([0x01, 0x02]))
        }
    }
}
