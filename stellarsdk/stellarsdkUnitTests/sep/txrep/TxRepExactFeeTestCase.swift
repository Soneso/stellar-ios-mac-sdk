//
//  TxRepExactFeeTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 21.11.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Verifies that TxRep import keeps the exact fee: for V1, V0 and fee bump
/// inner envelopes with a fee that is not a multiple of the operation count,
/// and for V1 and V0 envelopes without operations.
final class TxRepExactFeeTestCase: XCTestCase {

    // Independent V1 and V0 envelopes carrying fee 201 and two native payments,
    // with their shared testnet transaction hash.
    private static let v1EnvelopeBase64 =
        "AAAAAgAAAABi/B0L0JGythwN1lY0aypo19NHxvLCyO5tBEcCVvwF9wAAAMkAAAAAAAAAAQAAAAAAAAAAAAAAAgAAAAAAAAABAAAAAD8MNL+TrQ2ZcdBMzJD3BVEcg4qtlzSkovsNegP8f+iaAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAPww0v5OtDZlx0EzMkPcFURyDiq2XNKSi+w16A/x/6JoAAAAAAAAAAAExLQAAAAAAAAAAAA=="
    private static let v0EnvelopeBase64 =
        "AAAAAGL8HQvQkbK2HA3WVjRrKmjX00fG8sLI7m0ERwJW/AX3AAAAyQAAAAAAAAABAAAAAAAAAAAAAAACAAAAAAAAAAEAAAAAPww0v5OtDZlx0EzMkPcFURyDiq2XNKSi+w16A/x/6JoAAAAAAAAAAACYloAAAAAAAAAAAQAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAAAAAAAATEtAAAAAAAAAAAA"
    private static let expectedTestnetHash =
        "e836206d3c12045e6a152356061bcc9cf15340e758cd28f0aa2d0615042d02ca"

    private static let expectedInnerFee: UInt32 = 201
    private static let expectedOperationCount = 2
    private static let feeBumpOuterFee: UInt64 = 601
    private static let testSourceAccountId =
        "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"
    // Odd UInt32 boundary values for two operations: minimum non-zero fee below
    // the operation count and maximum UInt32 fee.
    private static let boundaryFees: [UInt32] = [1, UInt32.max]

    // MARK: - Helpers

    private func txRepLines(_ txRep: String) -> [String] {
        txRep.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    private func encodeEnvelope(_ envelope: TransactionEnvelopeXDR) throws -> String {
        Data(try XDREncoder.encode(envelope)).base64EncodedString()
    }

    private func replacingTxFee(in txRep: String, with fee: UInt32, file: StaticString = #filePath, line: UInt = #line) -> String {
        var replaced = false
        let updated = txRepLines(txRep).map { entry -> String in
            if entry.hasPrefix("tx.fee:") {
                replaced = true
                return "tx.fee: \(fee)"
            }
            return entry
        }
        XCTAssertTrue(replaced, "Expected tx.fee line in TxRep", file: file, line: line)
        return updated.joined(separator: "\n")
    }

    private func zeroOperationTxRep(envelopeType: String, fee: UInt32) -> String {
        """
        type: \(envelopeType)
        tx.sourceAccount: \(Self.testSourceAccountId)
        tx.fee: \(fee)
        tx.seqNum: 1
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
    }

    private func assertDecodedFee(
        _ base64: String,
        expectedFee: UInt32,
        expectedOperationCount: Int,
        isV0: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        switch (isV0, envelope) {
        case (false, .v1(let v1Envelope)):
            XCTAssertEqual(v1Envelope.tx.fee, expectedFee, file: file, line: line)
            XCTAssertEqual(v1Envelope.tx.operations.count, expectedOperationCount, file: file, line: line)
        case (true, .v0(let v0Envelope)):
            XCTAssertEqual(v0Envelope.tx.fee, expectedFee, file: file, line: line)
            XCTAssertEqual(v0Envelope.tx.operations.count, expectedOperationCount, file: file, line: line)
        default:
            XCTFail("Unexpected envelope variant: \(envelope)", file: file, line: line)
        }
    }

    // MARK: - Tests

    func testV1ExactFeeRoundTrip() throws {
        let txRep = try TxRep.toTxRep(transactionEnvelope: Self.v1EnvelopeBase64)
        let lines = txRepLines(txRep)
        XCTAssertTrue(lines.contains("type: ENVELOPE_TYPE_TX"))
        XCTAssertTrue(lines.contains("tx.fee: \(Self.expectedInnerFee)"))
        XCTAssertTrue(lines.contains("tx.operations.len: \(Self.expectedOperationCount)"))

        let roundTripped = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(roundTripped, Self.v1EnvelopeBase64)

        try assertDecodedFee(
            roundTripped,
            expectedFee: Self.expectedInnerFee,
            expectedOperationCount: Self.expectedOperationCount,
            isV0: false
        )
        let envelope = try TransactionEnvelopeXDR(fromBase64: roundTripped)
        XCTAssertEqual(
            try envelope.txHash(network: .testnet).base16EncodedString(),
            Self.expectedTestnetHash
        )
    }

    func testV0ExactFeeRoundTrip() throws {
        let txRep = try TxRep.toTxRep(transactionEnvelope: Self.v0EnvelopeBase64)
        let lines = txRepLines(txRep)
        XCTAssertTrue(lines.contains("type: ENVELOPE_TYPE_TX_V0"))
        XCTAssertTrue(lines.contains("tx.fee: \(Self.expectedInnerFee)"))
        XCTAssertTrue(lines.contains("tx.operations.len: \(Self.expectedOperationCount)"))

        let roundTripped = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(roundTripped, Self.v0EnvelopeBase64)

        try assertDecodedFee(
            roundTripped,
            expectedFee: Self.expectedInnerFee,
            expectedOperationCount: Self.expectedOperationCount,
            isV0: true
        )
        let envelope = try TransactionEnvelopeXDR(fromBase64: roundTripped)
        XCTAssertEqual(
            try envelope.txHash(network: .testnet).base16EncodedString(),
            Self.expectedTestnetHash
        )
    }

    func testFeeBumpInnerExactFeeRoundTrip() throws {
        let decodedV1 = try TransactionEnvelopeXDR(fromBase64: Self.v1EnvelopeBase64)
        guard case .v1(let innerEnvelope) = decodedV1 else {
            return XCTFail("Expected V1 envelope vector")
        }

        let feeSourceKey = try PublicKey(accountId: Self.testSourceAccountId)
        let feeBumpTx = FeeBumpTransactionXDR(
            sourceAccount: .ed25519(feeSourceKey.bytes),
            innerTx: .v1(innerEnvelope),
            fee: Self.feeBumpOuterFee
        )
        let originalFeeBumpBase64 = try encodeEnvelope(
            .feeBump(FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: []))
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: originalFeeBumpBase64)
        let lines = txRepLines(txRep)
        XCTAssertTrue(lines.contains("type: ENVELOPE_TYPE_TX_FEE_BUMP"))
        XCTAssertTrue(lines.contains("feeBump.tx.fee: \(Self.feeBumpOuterFee)"))
        XCTAssertTrue(lines.contains("feeBump.tx.innerTx.tx.fee: \(Self.expectedInnerFee)"))

        let roundTripped = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(roundTripped, originalFeeBumpBase64)

        let decodedFeeBump = try TransactionEnvelopeXDR(fromBase64: roundTripped)
        guard case .feeBump(let feeBumpEnvelope) = decodedFeeBump else {
            return XCTFail("Expected fee bump envelope")
        }
        XCTAssertEqual(feeBumpEnvelope.tx.fee, Self.feeBumpOuterFee)

        let decodedInnerEnvelope = feeBumpEnvelope.tx.innerTx.tx
        XCTAssertEqual(decodedInnerEnvelope.tx.fee, Self.expectedInnerFee)
        XCTAssertEqual(try encodeEnvelope(.v1(decodedInnerEnvelope)), Self.v1EnvelopeBase64)
        XCTAssertEqual(
            try decodedInnerEnvelope.tx.hash(network: .testnet).base16EncodedString(),
            Self.expectedTestnetHash
        )
    }

    func testZeroOperationsPreservesExactFee() throws {
        let variants: [(envelopeType: String, isV0: Bool)] = [
            ("ENVELOPE_TYPE_TX", false),
            ("ENVELOPE_TYPE_TX_V0", true)
        ]

        for variant in variants {
            let inputTxRep = zeroOperationTxRep(
                envelopeType: variant.envelopeType,
                fee: Self.expectedInnerFee
            )
            let base64 = try TxRep.fromTxRep(txRep: inputTxRep)
            try assertDecodedFee(
                base64,
                expectedFee: Self.expectedInnerFee,
                expectedOperationCount: 0,
                isV0: variant.isV0
            )

            let emittedTxRep = try TxRep.toTxRep(transactionEnvelope: base64)
            let lines = txRepLines(emittedTxRep)
            XCTAssertTrue(lines.contains("tx.fee: \(Self.expectedInnerFee)"))
            XCTAssertTrue(lines.contains("tx.operations.len: 0"))
            XCTAssertEqual(try TxRep.fromTxRep(txRep: emittedTxRep), base64)
        }
    }

    func testBoundaryFeesWithTwoOperations() throws {
        let templates: [(txRep: String, isV0: Bool)] = [
            (try TxRep.toTxRep(transactionEnvelope: Self.v1EnvelopeBase64), false),
            (try TxRep.toTxRep(transactionEnvelope: Self.v0EnvelopeBase64), true)
        ]

        for template in templates {
            for fee in Self.boundaryFees {
                let inputTxRep = replacingTxFee(in: template.txRep, with: fee)
                let base64 = try TxRep.fromTxRep(txRep: inputTxRep)
                try assertDecodedFee(
                    base64,
                    expectedFee: fee,
                    expectedOperationCount: Self.expectedOperationCount,
                    isV0: template.isV0
                )

                let emittedTxRep = try TxRep.toTxRep(transactionEnvelope: base64)
                XCTAssertTrue(txRepLines(emittedTxRep).contains("tx.fee: \(fee)"))
                XCTAssertEqual(try TxRep.fromTxRep(txRep: emittedTxRep), base64)
            }
        }
    }
}
