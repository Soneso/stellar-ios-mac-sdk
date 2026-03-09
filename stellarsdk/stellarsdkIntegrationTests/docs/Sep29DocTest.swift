//
//  Sep29DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-29 documentation code examples.
//  SEP-29: Account Memo Requirements.
//
//  NOTE: Most SEP-29 functionality is tested via network calls
//  (submitTransaction with memo check). These tests verify the
//  offline construction patterns used in the documentation.
//  Full integration tests require funded testnet accounts.
//

import Foundation
import XCTest
import stellarsdk

class Sep29DocTest: XCTestCase {

    // MARK: - ManageDataOperation: setting memo_required flag

    func testSetMemoRequiredFlag() throws {
        // Verify ManageDataOperation can be constructed with the correct key and value
        let setMemoRequired = ManageDataOperation(
            sourceAccountId: nil,
            name: "config.memo_required",
            data: "1".data(using: .utf8)
        )
        XCTAssertEqual(setMemoRequired.name, "config.memo_required")
        XCTAssertEqual(setMemoRequired.data, "1".data(using: .utf8))
    }

    // MARK: - ManageDataOperation: removing memo_required flag

    func testRemoveMemoRequiredFlag() throws {
        // Passing nil deletes the data entry
        let removeMemoRequired = ManageDataOperation(
            sourceAccountId: nil,
            name: "config.memo_required",
            data: nil
        )
        XCTAssertEqual(removeMemoRequired.name, "config.memo_required")
        XCTAssertNil(removeMemoRequired.data)
    }

    // MARK: - Transaction construction with memo

    func testTransactionWithMemo() throws {
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let destKeyPair = try KeyPair.generateRandomKeyPair()

        let sourceAccount = try Account(
            accountId: senderKeyPair.accountId,
            sequenceNumber: 100
        )

        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )

        // Build with memo
        let transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [paymentOp],
            memo: Memo.text("user-123"),
            maxOperationFee: 100
        )
        try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

        // Verify the transaction was signed successfully
        let envelope = try transaction.encodedEnvelope()
        XCTAssertFalse(envelope.isEmpty)
    }

    // MARK: - Transaction construction without memo

    func testTransactionWithoutMemo() throws {
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let destKeyPair = try KeyPair.generateRandomKeyPair()

        let sourceAccount = try Account(
            accountId: senderKeyPair.accountId,
            sequenceNumber: 100
        )

        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )

        // Build without memo (Memo.none)
        let transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [paymentOp],
            memo: Memo.none,
            maxOperationFee: 100
        )
        try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

        let envelope = try transaction.encodedEnvelope()
        XCTAssertFalse(envelope.isEmpty)
    }

    // MARK: - AccountMergeOperation construction

    func testAccountMergeOperationConstruction() throws {
        let sourceKeyPair = try KeyPair.generateRandomKeyPair()
        let destKeyPair = try KeyPair.generateRandomKeyPair()

        let sourceAccount = try Account(
            accountId: sourceKeyPair.accountId,
            sequenceNumber: 100
        )

        let mergeOp = try AccountMergeOperation(
            destinationAccountId: destKeyPair.accountId,
            sourceAccountId: nil
        )

        // Build with memo
        let transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [mergeOp],
            memo: Memo.text("closing-account"),
            maxOperationFee: 100
        )
        try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

        let envelope = try transaction.encodedEnvelope()
        XCTAssertFalse(envelope.isEmpty)
    }

    // MARK: - Muxed account destination (M-address)

    func testMuxedAccountDestination() throws {
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let destKeyPair = try KeyPair.generateRandomKeyPair()

        let sourceAccount = try Account(
            accountId: senderKeyPair.accountId,
            sequenceNumber: 100
        )

        // Create a muxed destination with user ID embedded
        let muxedDestination = try MuxedAccount(
            accountId: destKeyPair.accountId,
            id: 12345
        )
        XCTAssertTrue(muxedDestination.accountId.hasPrefix("M"))

        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: muxedDestination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )

        // Build without memo -- muxed accounts don't need memos
        let transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [paymentOp],
            memo: Memo.none,
            maxOperationFee: 100
        )
        try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

        let envelope = try transaction.encodedEnvelope()
        XCTAssertFalse(envelope.isEmpty)
    }

    // MARK: - Multiple payment operations in one transaction

    func testMultiplePaymentOperations() throws {
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let dest1KeyPair = try KeyPair.generateRandomKeyPair()
        let dest2KeyPair = try KeyPair.generateRandomKeyPair()

        let sourceAccount = try Account(
            accountId: senderKeyPair.accountId,
            sequenceNumber: 100
        )

        let op1 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: dest1KeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let op2 = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: dest2KeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 50.0
        )

        // Build with memo covering both destinations
        let transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [op1, op2],
            memo: Memo.text("batch-ref-001"),
            maxOperationFee: 100
        )
        try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

        let envelope = try transaction.encodedEnvelope()
        XCTAssertFalse(envelope.isEmpty)
    }

    // MARK: - Verify memo_required data value encoding

    func testMemoRequiredDataValueEncoding() throws {
        // The value "1" encoded as UTF-8 then base64 should be "MQ=="
        let data = "1".data(using: .utf8)!
        let base64 = data.base64EncodedString()
        XCTAssertEqual(base64, "MQ==")
    }

    // MARK: - Rebuild transaction with fresh Account object

    func testRebuildTransactionWithFreshAccount() throws {
        // Demonstrates the correct pattern: create a fresh Account for the rebuild
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let destKeyPair = try KeyPair.generateRandomKeyPair()
        let originalSequenceNumber: Int64 = 100

        // First attempt (without memo)
        let sourceAccount1 = try Account(
            accountId: senderKeyPair.accountId,
            sequenceNumber: originalSequenceNumber
        )
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let tx1 = try Transaction(
            sourceAccount: sourceAccount1,
            operations: [paymentOp],
            memo: Memo.none,
            maxOperationFee: 100
        )
        try tx1.sign(keyPair: senderKeyPair, network: Network.testnet)

        // Rebuild with memo using a FRESH Account object (correct pattern)
        let sourceAccount2 = try Account(
            accountId: senderKeyPair.accountId,
            sequenceNumber: originalSequenceNumber
        )
        let tx2 = try Transaction(
            sourceAccount: sourceAccount2,
            operations: [paymentOp],
            memo: Memo.text("user-123"),
            maxOperationFee: 100
        )
        try tx2.sign(keyPair: senderKeyPair, network: Network.testnet)

        let envelope1 = try tx1.encodedEnvelope()
        let envelope2 = try tx2.encodedEnvelope()
        // Both should be valid but different (different memo)
        XCTAssertFalse(envelope1.isEmpty)
        XCTAssertFalse(envelope2.isEmpty)
        XCTAssertNotEqual(envelope1, envelope2)
    }
}
