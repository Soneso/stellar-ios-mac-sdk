//
//  TransactionSorobanDataUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// A decoded Soroban transaction keeps its Soroban data, also as the inner transaction of a fee bump,
/// so it keeps its bytes, its hash and the signatures that sign that hash. The fixtures are raw XDR,
/// and each expected hash is sha256(sha256(passphrase) || envelope type || transaction bytes),
/// computed outside the SDK.
final class TransactionSorobanDataUnitTests: XCTestCase {

    /// Public network fee bump 06bf9c122421591a1a5e6dc4248a0912c1dfcc397dfd6111c82afca2851b8336 (ledger
    /// 65566583) around a signed contract invocation with Soroban data.
    private let sorobanFeeBumpEnvelope = "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"
    /// Public network hash of the inner transaction of `sorobanFeeBumpEnvelope`.
    private let sorobanInnerHash = "7e2fdae0792914cac7421dc4f35f89a8185fb9c2e5a791b0875c8fef44abc006"
    /// Byte ranges of the decoded `sorobanFeeBumpEnvelope`. The inner type-2 envelope follows the envelope
    /// type (4 bytes), the ed25519 fee source (36) and the fee (8), and ends before the fee bump ext (4)
    /// and the outer signature (76). The inner transaction ends before the inner signature (76); its
    /// Soroban data follows the transaction ext discriminant 1 at byte 340.
    private let innerEnvelopeBytes = 48..<2952
    private let innerTransactionBytes = 52..<2876
    private let sorobanDataBytes = 344..<2876
    /// A payment transaction in a V1 envelope with one signature.
    private let classicInnerEnvelope = "AAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAGQABGLVPIq6wQAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAADt4FJhvNwvlQqjuhc7bjLVyRf5e4K2QOzI0c6nWfVvEAAAAAAAAAAAAJiWgAAAAAAAAAABmIUMTQAAAEARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER"
    /// Testnet hash of the transaction in `classicInnerEnvelope`.
    private let classicInnerHash = "314950c2ee5f935abf54a68aaa5852e828ddfe373b320808c994729010bc1b57"
    /// `classicInnerEnvelope` bumped to fee 400, with one outer signature.
    private let classicFeeBumpEnvelope = "AAAABQAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAAAAAGQAAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAGQABGLVPIq6wQAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAADt4FJhvNwvlQqjuhc7bjLVyRf5e4K2QOzI0c6nWfVvEAAAAAAAAAAAAJiWgAAAAAAAAAABmIUMTQAAAEARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERAAAAAAAAAAH8f+iaAAAAQCIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiI="
    /// A payment transaction in a V0 envelope with one signature.
    private let classicV0Envelope = "AAAAAGV+lDNEWJN2FhmJZgrrObjhhYYF80e+hc48z6KYhQxNAAAD6AAPsVkAAAAEAAAAAAAAAAAAAAABAAAAAQAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAAEAAAAAHIfqDW5SWNoW2fFBEisLrHjuQunW8cRyaX5aF3NCNYoAAAAAAAAAAADk4cAAAAAAAAAAAZiFDE0AAABAxGFuP73x/OBT75+39J3k13/aos+h9yAvJErIlp9IoziNI02QsZAovmgVImdoGdo7FnslzirqzkZX3LVtych1Bw=="

    /// Base64 of the bytes in `range` of the decoded `sorobanFeeBumpEnvelope`.
    private func fixtureBytes(_ range: Range<Int>) throws -> String {
        return try XCTUnwrap(Data(base64Encoded: sorobanFeeBumpEnvelope)).subdata(in: range).base64EncodedString()
    }

    func testSorobanFeeBumpInnerTransactionKeepsBytesAndHash() throws {
        let inner = try Transaction(envelopeXdr: sorobanFeeBumpEnvelope)
        XCTAssertEqual(try inner.getTransactionHash(network: .public), sorobanInnerHash)
        XCTAssertEqual(inner.xdrEncoded, try fixtureBytes(innerTransactionBytes))
        XCTAssertEqual(try inner.encodedEnvelope(), try fixtureBytes(innerEnvelopeBytes))
        let envelope = try TransactionEnvelopeXDR(xdr: sorobanFeeBumpEnvelope)
        XCTAssertEqual(envelope.sorobanTransactionData?.xdrEncoded, try fixtureBytes(sorobanDataBytes))
    }

    func testSorobanFeeBumpEnvelopeReturnsTheDataOfItsInnerV1Envelope() throws {
        let v1Data = try TransactionEnvelopeXDR(xdr: try fixtureBytes(innerEnvelopeBytes)).sorobanTransactionData
        let feeBumpData = try TransactionEnvelopeXDR(xdr: sorobanFeeBumpEnvelope).sorobanTransactionData
        XCTAssertNotNil(v1Data)
        XCTAssertEqual(feeBumpData?.xdrEncoded, v1Data?.xdrEncoded)
    }

    func testSorobanDataOfV1EnvelopeAndNilWithoutSorobanTransaction() throws {
        let v1Data = try TransactionEnvelopeXDR(xdr: try fixtureBytes(innerEnvelopeBytes)).sorobanTransactionData
        XCTAssertEqual(v1Data?.xdrEncoded, try fixtureBytes(sorobanDataBytes))
        for envelope in [classicV0Envelope, classicInnerEnvelope, classicFeeBumpEnvelope] {
            XCTAssertNil(try TransactionEnvelopeXDR(xdr: envelope).sorobanTransactionData)
        }
    }

    func testSorobanTransactionXdrKeepsBytesAndHash() throws {
        let innerTransaction = try fixtureBytes(innerTransactionBytes)
        let transaction = try Transaction(xdr: innerTransaction)
        XCTAssertEqual(try transaction.getTransactionHash(network: .public), sorobanInnerHash)
        XCTAssertEqual(transaction.xdrEncoded, innerTransaction)
    }

    func testV1SorobanEnvelopeKeepsBytesAndHash() throws {
        let innerEnvelope = try fixtureBytes(innerEnvelopeBytes)
        let transaction = try Transaction(envelopeXdr: innerEnvelope)
        XCTAssertEqual(try transaction.getTransactionHash(network: .public), sorobanInnerHash)
        XCTAssertEqual(try transaction.encodedEnvelope(), innerEnvelope)
    }

    func testClassicFeeBumpInnerTransactionKeepsBytesAndHash() throws {
        let inner = try Transaction(envelopeXdr: classicFeeBumpEnvelope)
        XCTAssertEqual(try inner.getTransactionHash(network: .testnet), classicInnerHash)
        XCTAssertEqual(try inner.encodedEnvelope(), classicInnerEnvelope)
    }
}
