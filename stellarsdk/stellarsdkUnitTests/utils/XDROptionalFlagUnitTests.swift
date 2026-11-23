//
//  XDROptionalFlagUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// An XDR optional value starts with its presence flag, an XDR bool that is 0 or 1
/// (RFC 4506 section 4.19). Every other flag value is rejected with `boolOutOfRange`.
class XDROptionalFlagUnitTests: XCTestCase {

    func testStructOptionalFieldRejectsFlagOtherThanZeroOrOne() throws {
        let present: [UInt8] = [0, 0, 0, 1, 0x61, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 3, 1, 2, 3, 0]
        try assertRoundTrip(ManageDataOperationXDR(dataName: "a", dataValue: Data([1, 2, 3])), present)
        try assertRoundTrip(ManageDataOperationXDR(dataName: "a", dataValue: nil), [0, 0, 0, 1, 0x61, 0, 0, 0, 0, 0, 0, 0])
        assertBoolOutOfRange(ManageDataOperationXDR.self, flagged(present, at: 8, flag: 2), 2)
        assertBoolOutOfRange(ManageDataOperationXDR.self, flagged(present, at: 8, flag: 0xFFFFFFFF), 0xFFFFFFFF)
    }

    func testUnionOptionalArmRejectsFlagOtherThanZeroOrOne() throws {
        let u32Seven: [UInt8] = [0, 0, 0, 3, 0, 0, 0, 7]
        try assertRoundTrip(SCValXDR.vec(nil), [0, 0, 0, 16, 0, 0, 0, 0])
        try assertRoundTrip(SCValXDR.vec([]), [0, 0, 0, 16, 0, 0, 0, 1, 0, 0, 0, 0])
        let vec: [UInt8] = [0, 0, 0, 16, 0, 0, 0, 1, 0, 0, 0, 1] + u32Seven
        try assertRoundTrip(SCValXDR.vec([.u32(7)]), vec)
        assertBoolOutOfRange(SCValXDR.self, flagged(vec, at: 4, flag: 2), 2)

        try assertRoundTrip(SCValXDR.map(nil), [0, 0, 0, 17, 0, 0, 0, 0])
        try assertRoundTrip(SCValXDR.map([]), [0, 0, 0, 17, 0, 0, 0, 1, 0, 0, 0, 0])
        let map: [UInt8] = [0, 0, 0, 17, 0, 0, 0, 1, 0, 0, 0, 1] + u32Seven + [0, 0, 0, 3, 0, 0, 0, 8]
        try assertRoundTrip(SCValXDR.map([SCMapEntryXDR(key: .u32(7), val: .u32(8))]), map)
        assertBoolOutOfRange(SCValXDR.self, flagged(map, at: 4, flag: 2), 2)
    }

    func testArrayOfOptionalElementsRejectsFlagOtherThanZeroOrOne() throws {
        let first = try PublicKey([UInt8](repeating: 0x11, count: 32))
        let second = try PublicKey([UInt8](repeating: 0x22, count: 32))
        let key = { (byte: UInt8) -> [UInt8] in [0, 0, 0, 0] + [UInt8](repeating: byte, count: 32) }
        let (present, absent, ext): ([UInt8], [UInt8], [UInt8]) = ([0, 0, 0, 1], [0, 0, 0, 0], [0, 0, 0, 0])
        // numSponsored 5, numSponsoring 6, two sponsoring ids.
        let head: [UInt8] = [0, 0, 0, 5, 0, 0, 0, 6, 0, 0, 0, 2]
        let firstOnly: [UInt8] = head + present + key(0x11) + absent + ext
        try assertRoundTrip(AccountEntryExtensionV2(numSponsored: 5, numSponsoring: 6, signerSponsoringIDs: [first, nil], reserved: .void),
                            firstOnly)
        let both: [UInt8] = head + present + key(0x11) + present + key(0x22) + ext
        try assertRoundTrip(AccountEntryExtensionV2(numSponsored: 5, numSponsoring: 6, signerSponsoringIDs: [first, second], reserved: .void),
                            both)
        // The second element's flag follows the head, the first flag and the first key.
        assertBoolOutOfRange(AccountEntryExtensionV2.self, flagged(both, at: 52, flag: 2), 2)
    }

    func testTransactionV0TimeBoundsRejectsFlagOtherThanZeroOrOne() throws {
        let source = try PublicKey([UInt8](repeating: 0x33, count: 32))
        let operation = OperationXDR(body: .bumpSequenceOp(BumpSequenceOperationXDR(bumpTo: 9)))
        let transaction = { (timeBounds: TimeBoundsXDR?) in
            TransactionV0XDR(sourceAccount: source, seqNum: 7, timeBounds: timeBounds, memo: .none, operations: [operation])
        }
        // The source key, the fee and the sequence number take 44 bytes before the time bounds flag.
        let absent = try XDREncoder.encode(transaction(nil))
        XCTAssertEqual(Array(absent[44..<48]), [0, 0, 0, 0])
        let present = try XDREncoder.encode(transaction(TimeBoundsXDR(minTime: 10, maxTime: 20)))
        XCTAssertEqual(Array(present[44..<64]), [0, 0, 0, 1] + bigEndian(UInt64(10)) + bigEndian(UInt64(20)))
        XCTAssertEqual(Array(present[0..<44] + present[64...]), Array(absent[0..<44] + absent[48...]))
        // An envelope is ENVELOPE_TYPE_TX_V0, the transaction and the signature count.
        let envelope = { (tx: [UInt8]) -> [UInt8] in [0, 0, 0, 0] + tx + [0, 0, 0, 0] }
        for bytes in [absent, present] {
            XCTAssertEqual(try XDREncoder.encode(XDRDecoder.decode(TransactionV0XDR.self, data: bytes)), bytes)
            XCTAssertEqual(try XDREncoder.encode(XDRDecoder.decode(TransactionEnvelopeXDR.self, data: envelope(bytes))), envelope(bytes))
        }
        // Flag 2, then two complete time bounds and the rest of the transaction.
        let flag2 = flagged(present, at: 44, flag: 2)
        let input = Array(flag2[0..<64]) + bigEndian(UInt64(30)) + bigEndian(UInt64(40)) + Array(flag2[64...])
        assertBoolOutOfRange(TransactionV0XDR.self, input, 2)
        assertBoolOutOfRange(TransactionEnvelopeXDR.self, envelope(input), 2)
    }

    // MARK: - Helpers

    private func assertRoundTrip<T: XDRCodable>(_ value: T, _ bytes: [UInt8], file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(try XDREncoder.encode(value), bytes, "encoded value", file: file, line: line)
        XCTAssertEqual(try XDREncoder.encode(XDRDecoder.decode(T.self, data: bytes)), bytes, "decoded and encoded again", file: file, line: line)
    }

    /// Returns `bytes` with the presence flag 1 at `offset` replaced by all four bytes of `flag`.
    private func flagged(_ bytes: [UInt8], at offset: Int, flag: UInt32, file: StaticString = #filePath, line: UInt = #line) -> [UInt8] {
        XCTAssertEqual(Array(bytes[offset..<offset + 4]), [0, 0, 0, 1], "presence flag at offset \(offset)", file: file, line: line)
        var result = bytes
        result.replaceSubrange(offset..<offset + 4, with: bigEndian(flag))
        return result
    }

    private func assertBoolOutOfRange<T: XDRDecodable>(_ type: T.Type, _ bytes: [UInt8], _ flag: UInt32, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try XDRDecoder.decode(type, data: bytes), file: file, line: line) { error in
            guard case XDRDecoder.Error.boolOutOfRange(let value) = error else {
                return XCTFail("Expected boolOutOfRange(\(flag)), got \(error)", file: file, line: line)
            }
            XCTAssertEqual(value, flag, file: file, line: line)
        }
    }

    private func bigEndian<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
        withUnsafeBytes(of: value.bigEndian) { Array($0) }
    }
}
