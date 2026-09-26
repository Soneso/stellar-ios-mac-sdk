//
//  MalformedXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 26.09.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Decoding of malformed XDR through the public decoders: array counts the remaining bytes
/// cannot hold and non-zero extension points.
///
/// Each vector is built with the SDK's own encoder and patched at a computed offset; the test
/// checks the original bytes at that offset before patching.
class MalformedXDRUnitTests: XCTestCase {

    // MARK: - Array counts

    func testTransactionResultCountWithoutElementsIsRejected() throws {
        let bytes = try XDREncoder.encode(TransactionResultXDR(feeCharged: 100, result: .success([])))
        // The fee charged (8) and the result code precede the operation results count.
        let countOffset = 12
        XCTAssertEqual(bigEndian(0) + bigEndian(0), Array(bytes[(countOffset - 4)..<(countOffset + 4)]))
        // A count of 0x40000000 and nothing after it: 16 bytes in total.
        let hostile = Array(bytes[0..<countOffset]) + bigEndian(0x40000000)
        XCTAssertEqual(16, hostile.count)

        assertCountRejected(count: 0x40000000, remaining: 0) {
            _ = try TransactionResultXDR.fromXdr(base64: base64(hostile))
        }
    }

    func testTransactionResultCountBeyondRemainingBytesIsRejected() throws {
        let bytes = try XDREncoder.encode(TransactionResultXDR(feeCharged: 100, result: .success([])))
        // The fee charged (8) and the result code precede the operation results count; the
        // extension (v0) follows it.
        let countOffset = 12
        XCTAssertEqual(bigEndian(0) + bigEndian(0), Array(bytes[(countOffset - 4)..<(countOffset + 4)]))
        let remaining = bytes.count - countOffset - 4
        let count = countAboveBound(remaining: remaining)

        assertCountRejected(count: count, remaining: remaining) {
            _ = try TransactionResultXDR.fromXdr(base64: base64(patchWord(bytes, at: countOffset, to: count)))
        }
    }

    func testSignerSponsoringIDsCountBeyondRemainingBytesIsRejected() throws {
        let entry = AccountEntryExtensionV2(numSponsored: 1,
                                            numSponsoring: 0,
                                            signerSponsoringIDs: [try KeyPair.generateRandomKeyPair().publicKey, nil],
                                            reserved: .void)
        let bytes = try XDREncoder.encode(entry)
        // The sponsored and sponsoring counts precede the signer sponsoring ids count.
        let countOffset = 8
        XCTAssertEqual(bigEndian(2), Array(bytes[countOffset..<(countOffset + 4)]))
        let remaining = bytes.count - countOffset - 4
        let count = countAboveBound(remaining: remaining)

        assertCountRejected(count: count, remaining: remaining) {
            _ = try AccountEntryExtensionV2(xdr: base64(patchWord(bytes, at: countOffset, to: count)))
        }
    }

    func testTransactionOperationsCountBeyondRemainingBytesIsRejected() throws {
        let (bytes, countOffset) = try transactionOperationsCountVector()
        let remaining = bytes.count - countOffset - 4
        let count = countAboveBound(remaining: remaining)

        assertCountRejected(count: count, remaining: remaining) {
            _ = try TransactionEnvelopeXDR(fromBase64: base64(patchWord(bytes, at: countOffset, to: count)))
        }
    }

    func testTransactionOperationsCountEqualToRemainingBytesIsRejected() throws {
        let (bytes, countOffset) = try transactionOperationsCountVector()
        let remaining = bytes.count - countOffset - 4
        let count = UInt32(remaining)

        assertCountRejected(count: count, remaining: remaining) {
            _ = try TransactionEnvelopeXDR(fromBase64: base64(patchWord(bytes, at: countOffset, to: count)))
        }
    }

    func testUInt32ArrayCountBoundedByRemainingBytes() throws {
        let elements = bigEndian(7) + bigEndian(8)

        let atBound = try [UInt32](fromBinary: XDRDecoder(data: bigEndian(2) + elements))
        XCTAssertEqual([7, 8], atBound)

        assertCountRejected(count: 3, remaining: elements.count) {
            _ = try [UInt32](fromBinary: XDRDecoder(data: bigEndian(3) + elements))
        }
    }

    // MARK: - Byte sequences

    func testStringRoundTripsAtUnalignedLengths() throws {
        for length in [1, 3, 4, 5] {
            let value = String(repeating: "a", count: length)
            let encoded = try XDREncoder.encode(value)
            XCTAssertEqual(4 + (length + 3) / 4 * 4, encoded.count, "length \(length)")
            XCTAssertEqual(value, try XDRDecoder.decode(String.self, data: encoded), "length \(length)")
        }
    }

    func testDataRoundTripsAtUnalignedLengths() throws {
        for length in [1, 3, 4, 5] {
            let value = Data((0..<length).map { UInt8($0 + 1) })
            let encoded = try XDREncoder.encode(value)
            XCTAssertEqual(4 + (length + 3) / 4 * 4, encoded.count, "length \(length)")
            XCTAssertEqual(value, try XDRDecoder.decode(Data.self, data: encoded), "length \(length)")
        }
    }

    func testDataLengthBeyondRemainingBytesIsRejected() throws {
        let encoded = try XDREncoder.encode(Data([1, 2, 3, 4]))
        XCTAssertEqual(bigEndian(4), Array(encoded[0..<4]))
        let remaining = encoded.count - 4

        XCTAssertThrowsError(try XDRDecoder.decode(Data.self, data: patchWord(encoded, at: 0, to: 5))) { error in
            guard case StellarSDKError.xdrDecodingError(let message) = error else {
                return XCTFail("expected xdrDecodingError, got \(error)")
            }
            XCTAssertEqual("XDR array count 5 exceeds the maximum of \(remaining) for the \(remaining) remaining bytes", message)
        }
    }

    // MARK: - Extension points

    func testFeeBumpTransactionExtensionPoint() throws {
        let envelope = TransactionEnvelopeXDR.feeBump(FeeBumpTransactionEnvelopeXDR(
            tx: FeeBumpTransactionXDR(sourceAccount: .ed25519(try KeyPair.generateRandomKeyPair().publicKey.bytes),
                                      innerTx: .v1(TransactionV1EnvelopeXDR(tx: try transactionXDR(), signatures: [])),
                                      fee: 500),
            signatures: []))
        let bytes = try XDREncoder.encode(envelope)
        // The fee bump extension and the empty outer signature list end the envelope.
        let extOffset = bytes.count - 8
        XCTAssertEqual(bigEndian(0) + bigEndian(0), Array(bytes[extOffset...]))

        let decoded = try TransactionEnvelopeXDR(fromBase64: base64(bytes))
        guard case .feeBump(let feeBump) = decoded else {
            return XCTFail("expected a fee bump envelope, got \(decoded)")
        }
        XCTAssertEqual(0, feeBump.tx.reserved)

        assertDecodingError("FeeBumpTransactionXDR extension point must be 0, got 1") {
            _ = try TransactionEnvelopeXDR(fromBase64: base64(patchWord(bytes, at: extOffset, to: 1)))
        }
    }

    func testTransactionV0ExtensionPoint() throws {
        let envelope = TransactionEnvelopeXDR.v0(TransactionV0EnvelopeXDR(
            tx: TransactionV0XDR(sourceAccount: try KeyPair.generateRandomKeyPair().publicKey,
                                 seqNum: 124,
                                 timeBounds: nil,
                                 memo: .none,
                                 operations: [bumpSequenceOperation()]),
            signatures: []))
        let bytes = try XDREncoder.encode(envelope)
        // The transaction extension and the empty signature list end the envelope.
        let extOffset = bytes.count - 8
        XCTAssertEqual(bigEndian(0) + bigEndian(0), Array(bytes[extOffset...]))

        let decoded = try TransactionEnvelopeXDR(fromBase64: base64(bytes))
        guard case .v0(let v0) = decoded else {
            return XCTFail("expected a v0 envelope, got \(decoded)")
        }
        XCTAssertEqual(0, v0.tx.reserved)

        assertDecodingError("TransactionV0XDR extension point must be 0, got 1") {
            _ = try TransactionEnvelopeXDR(fromBase64: base64(patchWord(bytes, at: extOffset, to: 1)))
        }
    }

    func testTrustlineEntryExtensionV2ExtensionPoint() throws {
        let bytes = try XDREncoder.encode(TrustlineEntryExtensionV2(liquidityPoolUseCount: 5))
        // The liquidity pool use count precedes the extension.
        let extOffset = 4
        XCTAssertEqual(bigEndian(5) + bigEndian(0), bytes)

        let decoded = try TrustlineEntryExtensionV2(xdr: base64(bytes))
        XCTAssertEqual(5, decoded.liquidityPoolUseCount)

        assertDecodingError("TrustlineEntryExtensionV2 extension point must be 0, got 1") {
            _ = try TrustlineEntryExtensionV2(xdr: base64(patchWord(bytes, at: extOffset, to: 1)))
        }
    }

    // MARK: - Helpers

    private func bumpSequenceOperation() -> OperationXDR {
        let sourceAccount: MuxedAccountXDR? = nil
        return OperationXDR(sourceAccount: sourceAccount, body: .bumpSequenceOp(BumpSequenceOperationXDR(bumpTo: 1000)))
    }

    private func transactionXDR() throws -> TransactionXDR {
        TransactionXDR(sourceAccount: try KeyPair.generateRandomKeyPair().publicKey,
                       seqNum: 124,
                       cond: .none,
                       memo: .none,
                       operations: [bumpSequenceOperation()])
    }

    /// A one-operation transaction envelope and the offset of its operation count.
    private func transactionOperationsCountVector() throws -> ([UInt8], Int) {
        let envelope = TransactionEnvelopeXDR.v1(TransactionV1EnvelopeXDR(tx: try transactionXDR(), signatures: []))
        let bytes = try XDREncoder.encode(envelope)
        // Envelope type, source account (4 + 32), fee, sequence number (8), preconditions and
        // memo precede the operation count.
        let countOffset = 60
        XCTAssertEqual(bigEndian(1), Array(bytes[countOffset..<(countOffset + 4)]))
        return (bytes, countOffset)
    }

    /// The smallest count above a quarter of the remaining bytes. It does not exceed the
    /// remaining bytes, so only the 4-byte element bound rejects it.
    private func countAboveBound(remaining: Int, file: StaticString = #filePath, line: UInt = #line) -> UInt32 {
        let count = remaining / 4 + 1
        XCTAssertLessThanOrEqual(count, remaining, file: file, line: line)
        return UInt32(count)
    }

    private func base64(_ bytes: [UInt8]) -> String {
        Data(bytes).base64EncodedString()
    }

    private func bigEndian(_ value: UInt32) -> [UInt8] {
        withUnsafeBytes(of: value.bigEndian) { Array($0) }
    }

    private func patchWord(_ bytes: [UInt8], at offset: Int, to value: UInt32) -> [UInt8] {
        var patched = bytes
        patched.replaceSubrange(offset..<(offset + 4), with: bigEndian(value))
        return patched
    }

    /// Asserts the array count diagnostic for the given count and the bytes that remain after it.
    private func assertCountRejected(count: UInt32,
                                     remaining: Int,
                                     file: StaticString = #filePath,
                                     line: UInt = #line,
                                     _ decode: () throws -> Void) {
        assertDecodingError("XDR array count \(count) exceeds the maximum of \(remaining / 4) for the \(remaining) remaining bytes",
                            file: file,
                            line: line,
                            decode)
    }

    private func assertDecodingError(_ expectedMessage: String,
                                     file: StaticString = #filePath,
                                     line: UInt = #line,
                                     _ decode: () throws -> Void) {
        XCTAssertThrowsError(try decode(), file: file, line: line) { error in
            guard case StellarSDKError.xdrDecodingError(let message) = error else {
                return XCTFail("expected xdrDecodingError, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(expectedMessage, message, file: file, line: line)
        }
    }
}
