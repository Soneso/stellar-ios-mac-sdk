//
//  XdrFixedLengthUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class XdrFixedLengthUnitTests: XCTestCase {

    // All-zero 32-byte Ed25519 public key and its SEP-23 strkeys (id = 0 for M...).
    private static let zeroKey32: [UInt8] = Array(repeating: 0x00, count: 32)
    private static let zeroAccountId = "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"
    // 1 'M' + 64 'A's + "B5IG" = 69 characters (SEP-23 med25519 strkey for zero key, id = 0).
    private static let zeroMuxedAccountId = "MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB5IG"

    // 32 ascending bytes: 0x00 ..< 0x20.
    private static let seqBytes32: [UInt8] = Array(0..<32)
    private static let seqHex32 = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"

    // MARK: - Helpers

    private func assertInvalidArgument(
        expectedMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () throws -> Any
    ) {
        XCTAssertThrowsError(try block(), file: file, line: line) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                XCTFail("Expected StellarSDKError.invalidArgument(\"\(expectedMessage)\"), got \(error)", file: file, line: line)
                return
            }
            XCTAssertEqual(message, expectedMessage, file: file, line: line)
        }
    }

    private func assertXdrJsonInvalidValue(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () throws -> Any
    ) {
        XCTAssertThrowsError(try block(), file: file, line: line) { error in
            guard case XdrJsonError.invalidValue = error else {
                XCTFail("Expected XdrJsonError.invalidValue, got \(error)", file: file, line: line)
                return
            }
        }
    }

    private func assertTxRepInvalidValue(
        expectedKey: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () throws -> Any
    ) {
        XCTAssertThrowsError(try block(), file: file, line: line) { error in
            guard case TxRepError.invalidValue(let key) = error else {
                XCTFail("Expected TxRepError.invalidValue, got \(error)", file: file, line: line)
                return
            }
            if let expectedKey = expectedKey {
                XCTAssertEqual(key, expectedKey, file: file, line: line)
            }
        }
    }

    // MARK: - Binary: Hash struct field (LedgerKeyContractCodeXDR)

    func testBinaryLedgerKeyContractCode33BytesThrowsAndMatchesXdrJson() {
        let key = LedgerKeyContractCodeXDR(hash: WrappedData32(Data(repeating: 0xAA, count: 33)))
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(key)
        }
        assertXdrJsonInvalidValue {
            try key.toXdrJson()
        }
    }

    func testBinaryLedgerKeyContractCode31AssignedBytesThrowsWritesNothingAndMatchesXdrJson() {
        var hash = WrappedData32()
        hash.wrapped = Data(repeating: 0xBB, count: 31)
        let encoder = XDREncoder()
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try hash.xdrEncode(to: encoder)
        }
        XCTAssertTrue(encoder.data.isEmpty)

        let key = LedgerKeyContractCodeXDR(hash: hash)
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(key)
        }
        assertXdrJsonInvalidValue {
            try key.toXdrJson()
        }
    }

    func testBinaryLedgerKeyContractCode32BytesEncodesExact() throws {
        let key = LedgerKeyContractCodeXDR(hash: WrappedData32(Data(Self.seqBytes32)))
        let encoded = try XDREncoder.encode(key)
        XCTAssertEqual(encoded, Self.seqBytes32)
    }

    func testBinaryLedgerKeyContractCode31BytesInitPadsTo32() throws {
        let input31 = Array(Self.seqBytes32.prefix(31))
        let key = LedgerKeyContractCodeXDR(hash: WrappedData32(Data(input31)))
        let encoded = try XDREncoder.encode(key)
        XCTAssertEqual(encoded, input31 + [0x00])
    }

    // MARK: - Binary: DecoratedSignatureXDR.hint (WrappedData4)

    func testBinaryDecoratedSignatureHint3AssignedBytesThrowsAndMatchesXdrJson() {
        var hint = WrappedData4()
        hint.wrapped = Data([0x11, 0x22, 0x33])
        let sig = DecoratedSignatureXDR(hint: hint, signature: Data([0xDE, 0xAD, 0xBE, 0xEF]))
        assertInvalidArgument(expectedMessage: "expected 4 bytes, got 3") {
            try XDREncoder.encode(sig)
        }
        assertXdrJsonInvalidValue {
            try sig.toXdrJson()
        }
    }

    func testBinaryDecoratedSignatureHint5BytesThrowsAndMatchesXdrJson() {
        let hint = WrappedData4(Data([0x11, 0x22, 0x33, 0x44, 0x55]))
        let sig = DecoratedSignatureXDR(hint: hint, signature: Data([0xDE, 0xAD, 0xBE, 0xEF]))
        assertInvalidArgument(expectedMessage: "expected 4 bytes, got 5") {
            try XDREncoder.encode(sig)
        }
        assertXdrJsonInvalidValue {
            try sig.toXdrJson()
        }
    }

    func testBinaryDecoratedSignatureHint4BytesEncodesExact() throws {
        let sig = DecoratedSignatureXDR(
            hint: WrappedData4(Data([0x11, 0x22, 0x33, 0x44])),
            signature: Data([0xDE, 0xAD, 0xBE, 0xEF])
        )
        let encoded = try XDREncoder.encode(sig)
        // 4 raw hint bytes + 4-byte signature length (4) + 4 signature bytes.
        let expected: [UInt8] = [
            0x11, 0x22, 0x33, 0x44,
            0x00, 0x00, 0x00, 0x04,
            0xDE, 0xAD, 0xBE, 0xEF
        ]
        XCTAssertEqual(encoded, expected)
    }

    // MARK: - Binary: WrappedData16 (ShortHashSeedXDR)

    func testBinaryShortHashSeedWrongWidthThrowsAndMatchesXdrJson() {
        var seed15 = WrappedData16()
        seed15.wrapped = Data(repeating: 0x10, count: 15)
        let shortSeed = ShortHashSeedXDR(seed: seed15)
        assertInvalidArgument(expectedMessage: "expected 16 bytes, got 15") {
            try XDREncoder.encode(shortSeed)
        }
        assertXdrJsonInvalidValue {
            try shortSeed.toXdrJson()
        }

        let longSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x20, count: 17)))
        assertInvalidArgument(expectedMessage: "expected 16 bytes, got 17") {
            try XDREncoder.encode(longSeed)
        }
        assertXdrJsonInvalidValue {
            try longSeed.toXdrJson()
        }
    }

    func testBinaryShortHashSeed16BytesEncodesExact() throws {
        let bytes16: [UInt8] = Array(0x10..<0x20)
        let seed = ShortHashSeedXDR(seed: WrappedData16(Data(bytes16)))
        let encoded = try XDREncoder.encode(seed)
        XCTAssertEqual(encoded, bytes16)
    }

    // MARK: - Binary: Union arm (MemoXDR.hash)

    func testBinaryMemoHashWrongWidthThrowsAndMatchesXdrJson() {
        var hash31 = WrappedData32()
        hash31.wrapped = Data(repeating: 0xCC, count: 31)
        let shortMemo = MemoXDR.hash(hash31)
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(shortMemo)
        }
        assertXdrJsonInvalidValue {
            try shortMemo.toXdrJson()
        }

        let longMemo = MemoXDR.hash(WrappedData32(Data(repeating: 0xDD, count: 33)))
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(longMemo)
        }
        assertXdrJsonInvalidValue {
            try longMemo.toXdrJson()
        }
    }

    func testBinaryMemoHash32BytesEncodesExact() throws {
        let memo = MemoXDR.hash(WrappedData32(Data(Self.seqBytes32)))
        let encoded = try XDREncoder.encode(memo)
        // Discriminant MEMO_HASH = 3 (big-endian Int32) followed by 32 raw hash bytes.
        let expected: [UInt8] = [0x00, 0x00, 0x00, 0x03] + Self.seqBytes32
        XCTAssertEqual(encoded, expected)
    }

    // MARK: - Binary: Array of hashes (FreezeBypassTxsXDR)

    func testBinaryHashArrayWithWrongWidthElementThrowsAndMatchesXdrJson() {
        let valid = WrappedData32(Data(Self.seqBytes32))
        let bad33 = WrappedData32(Data(repeating: 0xEE, count: 33))
        let txsLong = FreezeBypassTxsXDR(txHashes: [valid, bad33])
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(txsLong)
        }
        assertXdrJsonInvalidValue {
            try txsLong.toXdrJson()
        }

        var bad31 = WrappedData32()
        bad31.wrapped = Data(repeating: 0xFF, count: 31)
        let txsShort = FreezeBypassTxsXDR(txHashes: [valid, bad31])
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(txsShort)
        }
        assertXdrJsonInvalidValue {
            try txsShort.toXdrJson()
        }
    }

    func testBinaryHashArrayValidEncodesExact() throws {
        let h1: [UInt8] = Self.seqBytes32
        let h2: [UInt8] = Array(repeating: 0x5A, count: 32)
        let txs = FreezeBypassTxsXDR(txHashes: [WrappedData32(Data(h1)), WrappedData32(Data(h2))])
        let encoded = try XDREncoder.encode(txs)
        // 4-byte array count (2) followed by two 32-byte raw hashes.
        let expected: [UInt8] = [0x00, 0x00, 0x00, 0x02] + h1 + h2
        XCTAssertEqual(encoded, expected)
    }

    // MARK: - Binary: Alpha4XDR asset code

    func testBinaryAlpha4AssetCode5BytesThrowsAndMatchesXdrJson() throws {
        let issuer = try PublicKey(Self.zeroKey32)
        let alpha4 = Alpha4XDR(assetCode: WrappedData4(Data([0x41, 0x42, 0x43, 0x44, 0x45])), issuer: issuer)
        assertInvalidArgument(expectedMessage: "expected 4 bytes, got 5") {
            try XDREncoder.encode(alpha4)
        }
        assertXdrJsonInvalidValue {
            try alpha4.toXdrJson()
        }
    }

    func testBinaryAlpha4AssetCode4BytesEncodesExact() throws {
        let issuer = try PublicKey(Self.zeroKey32)
        let alpha4 = Alpha4XDR(assetCode: WrappedData4(Data([0x41, 0x42, 0x43, 0x00])), issuer: issuer)
        let encoded = try XDREncoder.encode(alpha4)
        // 4 asset code bytes + 4-byte PUBLIC_KEY_TYPE_ED25519 (0) + 32 issuer bytes.
        let expected: [UInt8] = [0x41, 0x42, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00] + Self.zeroKey32
        XCTAssertEqual(encoded, expected)
    }

    // MARK: - Binary and TxRep: Hand-written uint256 sites

    func testMuxedAccountEd25519WrongWidthThrowsAndMatchesXdrJson() {
        let shortMux = MuxedAccountXDR.ed25519(Array(repeating: 0x01, count: 31))
        let muxEncoder = XDREncoder()
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try shortMux.encode(to: muxEncoder)
        }
        XCTAssertTrue(muxEncoder.data.isEmpty)
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(shortMux)
        }
        assertXdrJsonInvalidValue {
            try shortMux.toXdrJson()
        }
        assertTxRepInvalidValue(expectedKey: "muxedAccount") {
            try TxRepHelper.formatMuxedAccount(shortMux)
        }

        let longMux = MuxedAccountXDR.ed25519(Array(repeating: 0x02, count: 33))
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(longMux)
        }
        assertXdrJsonInvalidValue {
            try longMux.toXdrJson()
        }
        assertTxRepInvalidValue(expectedKey: "muxedAccount") {
            try TxRepHelper.formatMuxedAccount(longMux)
        }
    }

    func testMuxedAccountEd25519ValidEncodesExact() throws {
        let mux = MuxedAccountXDR.ed25519(Self.zeroKey32)
        let encoded = try XDREncoder.encode(mux)
        // KEY_TYPE_ED25519 = 0 (4 bytes) + 32 key bytes.
        XCTAssertEqual(encoded, [0x00, 0x00, 0x00, 0x00] + Self.zeroKey32)
        XCTAssertEqual(try TxRepHelper.formatMuxedAccount(mux), Self.zeroAccountId)
    }

    func testMuxedAccountMed25519WrongWidthThrowsAndMatchesXdrJson() {
        let shortInner = MuxedAccountMed25519XDR(id: 0, sourceAccountEd25519: Array(repeating: 0x03, count: 31))
        let shortMux = MuxedAccountXDR.med25519(shortInner)
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(shortInner)
        }
        let muxEncoder = XDREncoder()
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try shortMux.encode(to: muxEncoder)
        }
        XCTAssertTrue(muxEncoder.data.isEmpty)
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(shortMux)
        }
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(shortInner.toMuxedAccountMed25519XDRInverted())
        }
        assertXdrJsonInvalidValue {
            try shortInner.toXdrJson()
        }
        assertXdrJsonInvalidValue {
            try shortMux.toXdrJson()
        }
        assertTxRepInvalidValue(expectedKey: "muxedAccount") {
            try TxRepHelper.formatMuxedAccount(shortMux)
        }
        var lines: [String] = []
        assertTxRepInvalidValue(expectedKey: "m") {
            try shortInner.toTxRep(prefix: "m", lines: &lines)
        }
        XCTAssertTrue(lines.isEmpty)

        let longInner = MuxedAccountMed25519XDR(id: 0, sourceAccountEd25519: Array(repeating: 0x04, count: 33))
        let longMux = MuxedAccountXDR.med25519(longInner)
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(longInner)
        }
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(longMux)
        }
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 33") {
            try XDREncoder.encode(longInner.toMuxedAccountMed25519XDRInverted())
        }
        assertXdrJsonInvalidValue {
            try longInner.toXdrJson()
        }
        assertXdrJsonInvalidValue {
            try longMux.toXdrJson()
        }
        assertTxRepInvalidValue(expectedKey: "muxedAccount") {
            try TxRepHelper.formatMuxedAccount(longMux)
        }
        var linesLong: [String] = []
        assertTxRepInvalidValue(expectedKey: "m") {
            try longInner.toTxRep(prefix: "m", lines: &linesLong)
        }
        XCTAssertTrue(linesLong.isEmpty)
    }

    func testMuxedAccountMed25519ValidEncodesExact() throws {
        let inner = MuxedAccountMed25519XDR(id: 0, sourceAccountEd25519: Self.zeroKey32)
        let mux = MuxedAccountXDR.med25519(inner)
        // 8-byte id (0) + 32-byte key.
        let idZero: [UInt8] = Array(repeating: 0x00, count: 8)
        XCTAssertEqual(try XDREncoder.encode(inner), idZero + Self.zeroKey32)
        // KEY_TYPE_MUXED_ED25519 = 0x100 (4 bytes) + 8-byte id + 32-byte key.
        XCTAssertEqual(try XDREncoder.encode(mux), [0x00, 0x00, 0x01, 0x00] + idZero + Self.zeroKey32)
        // Inverted: 32-byte key + 8-byte id.
        XCTAssertEqual(try XDREncoder.encode(inner.toMuxedAccountMed25519XDRInverted()), Self.zeroKey32 + idZero)
        XCTAssertEqual(try TxRepHelper.formatMuxedAccount(mux), Self.zeroMuxedAccountId)

        var lines: [String] = []
        try inner.toTxRep(prefix: "m", lines: &lines)
        XCTAssertEqual(lines, ["m: \(Self.zeroMuxedAccountId)"])
    }

    func testTransactionV031ByteSourceThrowsAndMatchesXdrJson() {
        let tx = TransactionV0XDR(
            sourceAccountEd25519: Array(repeating: 0x05, count: 31),
            fee: 100,
            seqNum: 1,
            timeBounds: nil,
            memo: .none,
            operations: []
        )
        assertInvalidArgument(expectedMessage: "expected 32 bytes, got 31") {
            try XDREncoder.encode(tx)
        }
        assertXdrJsonInvalidValue {
            try tx.toXdrJson()
        }
        var lines: [String] = []
        assertTxRepInvalidValue(expectedKey: "tx.sourceAccount") {
            try tx.toTxRep(prefix: "tx", lines: &lines)
        }
        XCTAssertTrue(lines.isEmpty)
    }

    func testTransactionV0ValidEncodesExact() throws {
        let tx = TransactionV0XDR(
            sourceAccountEd25519: Self.zeroKey32,
            fee: 100,
            seqNum: 1,
            timeBounds: nil,
            memo: .none,
            operations: []
        )
        let encoded = try XDREncoder.encode(tx)
        // 32-byte source + fee(100) + seqNum(1) + timeBounds(absent=0) + memo(none=0) + ops(0) + ext(0).
        let expected: [UInt8] = Self.zeroKey32 + [
            0x00, 0x00, 0x00, 0x64,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
        ]
        XCTAssertEqual(encoded, expected)

        var lines: [String] = []
        try tx.toTxRep(prefix: "tx", lines: &lines)
        XCTAssertEqual(lines.first, "tx.sourceAccount: \(Self.zeroAccountId)")
    }

    // MARK: - TxRep writers

    func testTxRepLedgerKeyContractCodeWrongWidthThrows() {
        var hash31 = WrappedData32()
        hash31.wrapped = Data(repeating: 0x11, count: 31)
        var lines31: [String] = []
        assertTxRepInvalidValue(expectedKey: "k.hash") {
            try LedgerKeyContractCodeXDR(hash: hash31).toTxRep(prefix: "k", lines: &lines31)
        }
        XCTAssertTrue(lines31.isEmpty)

        let hash33 = WrappedData32(Data(repeating: 0x22, count: 33))
        var lines33: [String] = []
        assertTxRepInvalidValue(expectedKey: "k.hash") {
            try LedgerKeyContractCodeXDR(hash: hash33).toTxRep(prefix: "k", lines: &lines33)
        }
        XCTAssertTrue(lines33.isEmpty)
    }

    func testTxRepLedgerKeyContractCodeValidWritesHexLine() throws {
        var lines: [String] = []
        try LedgerKeyContractCodeXDR(hash: WrappedData32(Data(Self.seqBytes32))).toTxRep(prefix: "k", lines: &lines)
        XCTAssertEqual(lines, ["k.hash: \(Self.seqHex32)"])
    }

    func testTxRepFormatAssetAndTrustlineAsset5ByteCodeThrows() throws {
        let issuer = try PublicKey(Self.zeroKey32)
        let badAlpha4 = Alpha4XDR(assetCode: WrappedData4(Data([0x41, 0x42, 0x43, 0x44, 0x45])), issuer: issuer)

        assertTxRepInvalidValue(expectedKey: "assetCode") {
            try TxRepHelper.formatAsset(.alphanum4(badAlpha4))
        }
        assertTxRepInvalidValue(expectedKey: "assetCode") {
            try TxRepHelper.formatTrustlineAsset(.alphanum4(badAlpha4))
        }
        assertTxRepInvalidValue(expectedKey: "assetCode") {
            try TxRepHelper.formatChangeTrustAsset(.alphanum4(badAlpha4))
        }
        assertTxRepInvalidValue(expectedKey: "assetCode") {
            try TxRepHelper.formatAllowTrustAsset(.alphanum4(WrappedData4(Data([0x41, 0x42, 0x43, 0x44, 0x45]))))
        }
    }

    func testTxRepFormatTrustlineAssetPoolShareWrongWidthThrows() {
        let badPool = TrustlineAssetXDR.poolShare(WrappedData32(Data(repeating: 0xAB, count: 33)))
        assertTxRepInvalidValue(expectedKey: "liquidityPoolID") {
            try TxRepHelper.formatTrustlineAsset(badPool)
        }
        var lines: [String] = []
        assertTxRepInvalidValue(expectedKey: "tl.liquidityPoolID") {
            try badPool.toTxRep(prefix: "tl", lines: &lines)
        }
        XCTAssertTrue(lines.isEmpty)
    }

    func testTxRepFormatAsset4ByteAbcNullWritesAbc() throws {
        let issuer = try PublicKey(Self.zeroKey32)
        let alpha4 = Alpha4XDR(assetCode: WrappedData4(Data([0x41, 0x42, 0x43, 0x00])), issuer: issuer)
        let expected = "ABC:\(Self.zeroAccountId)"
        XCTAssertEqual(try TxRepHelper.formatAsset(.alphanum4(alpha4)), expected)
        XCTAssertEqual(try TxRepHelper.formatTrustlineAsset(.alphanum4(alpha4)), expected)
    }

    // MARK: - TxRep readers

    func testTxRepParseTrustlineAssetPoolShare0xPrefixThrows() {
        let prefixed = "0x" + String(repeating: "ab", count: 31)
        XCTAssertEqual(prefixed.count, 64)
        assertTxRepInvalidValue(expectedKey: prefixed) {
            try TxRepHelper.parseTrustlineAsset(prefixed)
        }
    }

    func testTxRepParseTrustlineAssetPoolShare64HexReadsExact() throws {
        let parsed = try TxRepHelper.parseTrustlineAsset(Self.seqHex32)
        guard case .poolShare(let poolId) = parsed else {
            XCTFail("Expected .poolShare, got \(parsed)")
            return
        }
        XCTAssertEqual(poolId.wrapped, Data(Self.seqBytes32))
    }

    func testTxRepParseAssetMultiByteUtf8UsesByteLength() throws {
        // "ÄÄÄ" is 3 characters and 6 UTF-8 bytes (C3 84 repeated three times), so it is ALPHANUM12.
        let value = "ÄÄÄ:\(Self.zeroAccountId)"
        let expectedCode = Data([0xC3, 0x84, 0xC3, 0x84, 0xC3, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        let asset = try TxRepHelper.parseAsset(value)
        guard case .alphanum12(let a12) = asset else {
            XCTFail("Expected .alphanum12, got \(asset)")
            return
        }
        XCTAssertEqual(a12.assetCode.wrapped, expectedCode)
        XCTAssertEqual(a12.issuer.accountId, Self.zeroAccountId)

        let ctAsset = try TxRepHelper.parseChangeTrustAsset(value)
        guard case .alphanum12(let ct12) = ctAsset else {
            XCTFail("Expected .alphanum12, got \(ctAsset)")
            return
        }
        XCTAssertEqual(ct12.assetCode.wrapped, expectedCode)

        let tlAsset = try TxRepHelper.parseTrustlineAsset(value)
        guard case .alphanum12(let tl12) = tlAsset else {
            XCTFail("Expected .alphanum12, got \(tlAsset)")
            return
        }
        XCTAssertEqual(tl12.assetCode.wrapped, expectedCode)
    }

    func testTxRepParseAsset13Utf8BytesThrows() {
        // 6 x "Ä" (12 UTF-8 bytes) + "A" (1 UTF-8 byte) = 7 characters, 13 UTF-8 bytes.
        let code13 = "ÄÄÄÄÄÄA"
        XCTAssertEqual(code13.utf8.count, 13)
        let value = "\(code13):\(Self.zeroAccountId)"

        assertTxRepInvalidValue {
            try TxRepHelper.parseAsset(value)
        }
        assertTxRepInvalidValue {
            try TxRepHelper.parseChangeTrustAsset(value)
        }
        assertTxRepInvalidValue {
            try TxRepHelper.parseTrustlineAsset(value)
        }
        assertTxRepInvalidValue {
            try TxRepHelper.parseAllowTrustAsset(code13)
        }
    }

    func testTxRepParseAssetAsciiAbcReadsAlphanum4() throws {
        let parsed = try TxRepHelper.parseAsset("ABC:\(Self.zeroAccountId)")
        guard case .alphanum4(let a4) = parsed else {
            XCTFail("Expected .alphanum4, got \(parsed)")
            return
        }
        XCTAssertEqual(a4.assetCode.wrapped, Data([0x41, 0x42, 0x43, 0x00]))
        XCTAssertEqual(a4.issuer.accountId, Self.zeroAccountId)
    }

    func testTxRepParseAllowTrustAsset5Utf8BytesIn4CharsReadsAlphanum12() throws {
        // "ÄABC" is 4 characters and 5 UTF-8 bytes: C3 84 41 42 43.
        let code = "ÄABC"
        XCTAssertEqual(code.count, 4)
        XCTAssertEqual(code.utf8.count, 5)
        let parsed = try TxRepHelper.parseAllowTrustAsset(code)
        guard case .alphanum12(let data12) = parsed else {
            XCTFail("Expected .alphanum12, got \(parsed)")
            return
        }
        XCTAssertEqual(
            data12.wrapped,
            Data([0xC3, 0x84, 0x41, 0x42, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        )
    }
}
