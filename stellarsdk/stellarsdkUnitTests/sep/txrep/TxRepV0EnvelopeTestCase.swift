//
//  TxRepV0EnvelopeTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Tests for the V0 envelope TxRep path (ENVELOPE_TYPE_TX_V0).
///
/// V0 envelopes use a raw Ed25519 source account key (not a muxed account)
/// and an optional timeBounds instead of the full PRECOND_* structure.
/// These tests exercise `TransactionV0XDR+TxRep.swift` and
/// `TransactionV0EnvelopeXDR+TxRep.swift`, which had 0% coverage before Phase 8.
final class TxRepV0EnvelopeTestCase: XCTestCase {

    // Known test keypairs — using fixed seeds so tests are deterministic.
    private let sourceSeed = "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK"
    private let destAccountId = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"

    // MARK: - Helpers

    /// Build a signed V0 envelope and return its base64 XDR string.
    private func buildV0Envelope(
        seqNum: Int64 = 1000,
        timeBounds: TimeBoundsXDR? = nil,
        memo: MemoXDR = .none,
        operations: [OperationXDR]? = nil
    ) throws -> String {
        let source = try KeyPair(secretSeed: sourceSeed)
        let dest = try KeyPair(accountId: destAccountId)

        let ops: [OperationXDR]
        if let provided = operations {
            ops = provided
        } else {
            // Default: a single native payment.
            let destMuxed = MuxedAccountXDR.ed25519(dest.publicKey.bytes)
            let payBody = OperationBodyXDR.paymentOp(PaymentOperationXDR(
                destination: destMuxed,
                asset: .native,
                amount: 1_000_000
            ))
            ops = [OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: payBody)]
        }

        var v0Tx = TransactionV0XDR(
            sourceAccount: source.publicKey,
            seqNum: seqNum,
            timeBounds: timeBounds,
            memo: memo,
            operations: ops,
            maxOperationFee: 100
        )
        try v0Tx.sign(keyPair: source, network: Network.testnet)
        let envelopeXDR = try v0Tx.toEnvelopeXDR()
        var encoded = try XDREncoder.encode(envelopeXDR)
        return Data(bytes: &encoded, count: encoded.count).base64EncodedString()
    }

    // MARK: - Basic V0 roundtrip

    func testV0EnvelopeToTxRepContainsV0Type() throws {
        let base64 = try buildV0Envelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX_V0"),
                      "V0 envelope must emit ENVELOPE_TYPE_TX_V0")
    }

    func testV0EnvelopeToTxRepContainsSourceAccount() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let base64 = try buildV0Envelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.sourceAccount: \(source.accountId)"),
                      "V0 source account must be normalised to G-address")
    }

    func testV0EnvelopeToTxRepContainsFeeAndSeqNum() throws {
        let base64 = try buildV0Envelope(seqNum: 5000)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.fee:"), "V0 txRep must contain fee field")
        XCTAssertTrue(txRep.contains("tx.seqNum: 5000"), "seqNum must match")
    }

    func testV0EnvelopeRoundtrip() throws {
        let base64 = try buildV0Envelope(seqNum: 999)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed, "V0 envelope must survive full TxRep roundtrip")
    }

    // MARK: - V0 with PRECOND_NONE (no timeBounds)

    func testV0EnvelopeNoPrecondEmitsPrecondNone() throws {
        let base64 = try buildV0Envelope(timeBounds: nil)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_NONE"),
                      "V0 with no timeBounds must emit PRECOND_NONE")
    }

    func testV0EnvelopeNoPrecondRoundtrips() throws {
        let base64 = try buildV0Envelope(timeBounds: nil)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    // MARK: - V0 with timeBounds (PRECOND_TIME)

    func testV0EnvelopeWithTimeBoundsEmitsPrecondTime() throws {
        let tb = TimeBoundsXDR(minTime: 1000, maxTime: 2000)
        let base64 = try buildV0Envelope(timeBounds: tb)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_TIME"),
                      "V0 with timeBounds must emit PRECOND_TIME")
        XCTAssertTrue(txRep.contains("tx.cond.timeBounds.minTime: 1000"))
        XCTAssertTrue(txRep.contains("tx.cond.timeBounds.maxTime: 2000"))
    }

    func testV0EnvelopeWithTimeBoundsRoundtrips() throws {
        let tb = TimeBoundsXDR(minTime: 1_700_000_000, maxTime: 1_800_000_000)
        let base64 = try buildV0Envelope(timeBounds: tb)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    // MARK: - V0 with various memo types

    func testV0EnvelopeWithMemoNone() throws {
        let base64 = try buildV0Envelope(memo: .none)
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_NONE"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    func testV0EnvelopeWithMemoText() throws {
        let base64 = try buildV0Envelope(memo: .text("v0 test memo"))
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_TEXT"))
        XCTAssertTrue(txRep.contains("v0 test memo"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    func testV0EnvelopeWithMemoId() throws {
        let base64 = try buildV0Envelope(memo: .id(42_000))
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_ID"))
        XCTAssertTrue(txRep.contains("tx.memo.id: 42000"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    func testV0EnvelopeWithMemoHash() throws {
        let hashData = Data(repeating: 0xAB, count: 32)
        let base64 = try buildV0Envelope(memo: .hash(WrappedData32(hashData)))
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_HASH"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    func testV0EnvelopeWithMemoReturn() throws {
        let hashData = Data(repeating: 0xCD, count: 32)
        let base64 = try buildV0Envelope(memo: .returnHash(WrappedData32(hashData)))
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.memo.type: MEMO_RETURN"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    // MARK: - V0 with operations

    func testV0EnvelopeWithCreateAccountOperation() throws {
        let dest = try KeyPair(accountId: destAccountId)
        let destPk = dest.publicKey
        let body = OperationBodyXDR.createAccountOp(CreateAccountOperationXDR(
            destination: destPk,
            balance: 10_000_000
        ))
        let op = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: body)
        let base64 = try buildV0Envelope(operations: [op])
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("type: ENVELOPE_TYPE_TX_V0"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: CREATE_ACCOUNT"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    func testV0EnvelopeWithMultipleOperations() throws {
        let dest = try KeyPair(accountId: destAccountId)
        let destMuxed = MuxedAccountXDR.ed25519(dest.publicKey.bytes)

        let pay1 = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: .paymentOp(PaymentOperationXDR(
            destination: destMuxed, asset: .native, amount: 100_000
        )))
        let pay2 = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: .paymentOp(PaymentOperationXDR(
            destination: destMuxed, asset: .native, amount: 200_000
        )))
        let base64 = try buildV0Envelope(operations: [pay1, pay2])
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.operations.len: 2"))
        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: PAYMENT"))
        XCTAssertTrue(txRep.contains("tx.operations[1].body.type: PAYMENT"))
        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    // MARK: - V0 ext field

    func testV0EnvelopeEmitsExtV0() throws {
        let base64 = try buildV0Envelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.ext.v: 0"),
                      "V0 transactions always emit ext.v: 0")
    }

    // MARK: - V0 signatures

    func testV0EnvelopeContainsSignaturesLen() throws {
        let base64 = try buildV0Envelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("signatures.len: 1"),
                      "Signed V0 envelope must emit signatures.len: 1")
        XCTAssertTrue(txRep.contains("signatures[0].hint:"))
        XCTAssertTrue(txRep.contains("signatures[0].signature:"))
    }

    // MARK: - fromTxRep V0 parsing

    func testFromTxRepV0WithPrecondNone() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(base64.isEmpty)
        // Re-encode and verify it roundtrips.
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("type: ENVELOPE_TYPE_TX_V0"))
    }

    func testFromTxRepV0WithPrecondTime() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 200
        tx.seqNum: 2002
        tx.cond.type: PRECOND_TIME
        tx.cond.timeBounds.minTime: 500
        tx.cond.timeBounds.maxTime: 9999
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 500000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("tx.cond.type: PRECOND_TIME"))
        XCTAssertTrue(txRep2.contains("tx.cond.timeBounds.minTime: 500"))
        XCTAssertTrue(txRep2.contains("tx.cond.timeBounds.maxTime: 9999"))
    }

    /// Legacy format: timeBounds._present = true (pre-PRECOND support).
    func testFromTxRepV0LegacyTimeBoundsPresent() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 3003
        tx.timeBounds._present: true
        tx.timeBounds.minTime: 100
        tx.timeBounds.maxTime: 800
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 100000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        // Should parse successfully as PRECOND_TIME with timeBounds.
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("type: ENVELOPE_TYPE_TX_V0"))
    }

    /// Legacy format: timeBounds._present = false (no time bounds).
    func testFromTxRepV0LegacyTimeBoundsAbsent() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 4004
        tx.timeBounds._present: false
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 100000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("tx.cond.type: PRECOND_NONE"))
    }

    /// PRECOND_V2 with embedded timeBounds falls back to only timeBounds in V0.
    func testFromTxRepV0PrecondV2WithTimeBounds() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 5005
        tx.cond.type: PRECOND_V2
        tx.cond.v2.timeBounds._present: true
        tx.cond.v2.timeBounds.minTime: 200
        tx.cond.v2.timeBounds.maxTime: 700
        tx.cond.v2.ledgerBounds._present: false
        tx.cond.v2.minSeqNum._present: false
        tx.cond.v2.minSeqAge: 0
        tx.cond.v2.minSeqLedgerGap: 0
        tx.cond.v2.extraSigners.len: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 100000
        tx.ext.v: 0
        signatures.len: 0
        """
        // V0 reduces PRECOND_V2 to just its timeBounds arm.
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(base64.isEmpty)
    }

    /// PRECOND_V2 without timeBounds → no timeBounds on V0 TX.
    func testFromTxRepV0PrecondV2NoTimeBounds() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 6006
        tx.cond.type: PRECOND_V2
        tx.cond.v2.timeBounds._present: false
        tx.cond.v2.ledgerBounds._present: false
        tx.cond.v2.minSeqNum._present: false
        tx.cond.v2.minSeqAge: 0
        tx.cond.v2.minSeqLedgerGap: 0
        tx.cond.v2.extraSigners.len: 0
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 100000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(base64.isEmpty)
    }

    // MARK: - fromTxRep V0 error cases

    func testFromTxRepV0MissingSourceAccountThrows() {
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.fee: 100
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("sourceAccount"))
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testFromTxRepV0InvalidSourceAccountThrows() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: NOT_A_VALID_KEY
        tx.fee: 100
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("sourceAccount"))
            } else {
                XCTFail("Expected invalidValue for sourceAccount, got \(error)")
            }
        }
    }

    func testFromTxRepV0MissingFeeThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("fee"))
            } else {
                XCTFail("Expected missingValue for fee, got \(error)")
            }
        }
    }

    func testFromTxRepV0InvalidFeeThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: not_a_number
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("fee"))
            } else {
                XCTFail("Expected invalidValue for fee, got \(error)")
            }
        }
    }

    func testFromTxRepV0MissingSeqNumThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("seqNum"))
            } else {
                XCTFail("Expected missingValue for seqNum, got \(error)")
            }
        }
    }

    func testFromTxRepV0InvalidSeqNumThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: not_a_number
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("seqNum"))
            } else {
                XCTFail("Expected invalidValue for seqNum, got \(error)")
            }
        }
    }

    func testFromTxRepV0MissingOperationsLenThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("operations.len"))
            } else {
                XCTFail("Expected missingValue for operations.len, got \(error)")
            }
        }
    }

    func testFromTxRepV0InvalidOperationsLenThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: -1
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("operations.len"))
            } else {
                XCTFail("Expected invalidValue for operations.len, got \(error)")
            }
        }
    }

    func testFromTxRepV0OperationsLenTooLargeThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX_V0
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 1001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 101
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("operations.len"))
            } else {
                XCTFail("Expected invalidValue for operations.len > 100, got \(error)")
            }
        }
    }
}
