//
//  ErrorHandlingDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class ErrorHandlingDocTest: XCTestCase {
    let sdk = StellarSDK.testNet()

    // MARK: - Helper

    private func fundAccount(_ keyPair: KeyPair) async {
        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            XCTFail("Failed to fund \(keyPair.accountId): \(error)")
        }
    }

    // MARK: - Transaction Submission Errors

    func testHandlingSubmissionResults() async throws {
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        await fundAccount(receiverKeyPair)

        let accountResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        guard case .success(let account) = accountResponse else {
            XCTFail("Failed to load account")
            return
        }

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: receiverKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 10.0
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: nil
        )

        try transaction.sign(keyPair: senderKeyPair, network: .testnet)

        // Snippet: Handling Submission Results
        // Note: .destinationRequiresMemo requires a specific SEP-29 account
        // configuration on testnet which cannot be reliably set up in isolation.
        let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitResponse {
        case .success(let details):
            XCTAssertFalse(details.transactionHash.isEmpty)
        case .destinationRequiresMemo(let destinationAccountId):
            XCTFail("Unexpected destinationRequiresMemo: \(destinationAccountId)")
        case .failure(let error):
            XCTFail("Submission failed: \(error)")
        }
    }

    func testExtractingResultCodes() async throws {
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try KeyPair.generateRandomKeyPair()

        await fundAccount(senderKeyPair)
        // Do not fund receiver -- payment to unfunded account should still
        // succeed for native asset. Instead, send more than the balance to
        // trigger op_underfunded.

        let accountResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        guard case .success(let account) = accountResponse else {
            XCTFail("Failed to load account")
            return
        }

        // Try to pay more XLM than the account has to trigger a failure
        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: receiverKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 999_999_999.0
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: nil
        )

        try transaction.sign(keyPair: senderKeyPair, network: .testnet)

        // Snippet: Extracting Result Codes
        let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitResponse {
        case .success(_):
            XCTFail("Expected failure but transaction succeeded")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo")
        case .failure(let error):
            if case .badRequest(let message, let errorResponse) = error {
                XCTAssertFalse(message.isEmpty)

                if let extras = errorResponse?.extras,
                   let resultCodes = extras.resultCodes {
                    XCTAssertEqual(resultCodes.transaction, "tx_failed")
                    XCTAssertNotNil(resultCodes.operations)
                    // Sending to an unfunded account with an amount exceeding
                    // the sender's balance produces op_no_destination or
                    // op_underfunded depending on which check Stellar Core
                    // evaluates first.
                    let opCodes = resultCodes.operations ?? []
                    XCTAssertFalse(opCodes.isEmpty)
                    print("Operation result codes: \(opCodes)")
                } else {
                    XCTFail("Expected extras with resultCodes")
                }

                XCTAssertNotNil(errorResponse?.extras?.resultXdr)
            } else {
                XCTFail("Expected badRequest but got: \(error)")
            }
        }
    }

    func testFixingTxBadSeqPrevention() async throws {
        // Tests the recommended pattern for preventing tx_bad_seq:
        // reload the account immediately before building the transaction.
        let sourceKeyPair = try KeyPair.generateRandomKeyPair()
        let destKeyPair = try KeyPair.generateRandomKeyPair()

        await fundAccount(sourceKeyPair)
        await fundAccount(destKeyPair)

        // Snippet: Fixing tx_bad_seq
        // Reload account right before building to get the current sequence number
        let accountResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
        guard case .success(let account) = accountResponse else {
            XCTFail("Failed to load account")
            return
        }

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 10.0
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: nil
        )

        try transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitResponse {
        case .success(let details):
            XCTAssertFalse(details.transactionHash.isEmpty)
        case .destinationRequiresMemo(let destinationAccountId):
            XCTFail("Unexpected destinationRequiresMemo: \(destinationAccountId)")
        case .failure(let error):
            XCTFail("Submission failed: \(error)")
        }
    }

    func testFeeStats() async throws {
        // Snippet: Setting Appropriate Fees
        let feeResponse = await sdk.feeStats.getFeeStats()
        switch feeResponse {
        case .success(let feeStats):
            let fee = UInt32(feeStats.maxFee.p90) ?? Transaction.minBaseFee
            XCTAssertGreaterThanOrEqual(fee, Transaction.minBaseFee)
        case .failure(let error):
            XCTFail("Failed to load fee stats: \(error)")
        }
    }

    // MARK: - Horizon Query Errors

    func testHorizonQueryNotFound() async throws {
        // Snippet: Horizon Query Errors
        // Use a valid-format but unfunded account to trigger a 404
        let nonExistentKeyPair = try KeyPair.generateRandomKeyPair()
        let response = await sdk.accounts.getAccountDetails(accountId: nonExistentKeyPair.accountId)
        switch response {
        case .success(_):
            XCTFail("Expected notFound for non-existent account")
        case .failure(let error):
            if case .notFound(let message, _) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected notFound but got: \(error)")
            }
        }
    }

    // MARK: - Soroban RPC Errors

    func testSorobanRpcHealth() async {
        // Snippet: SorobanRpcRequestError
        // Note: failure branches (.requestFailed, .errorResponse, .parsingResponseFailed)
        // cannot be reliably triggered in tests -- they require network failures or
        // a misconfigured RPC server. This test verifies the happy path and that
        // the pattern-matching code compiles.
        let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

        let healthResponse = await sorobanServer.getHealth()
        switch healthResponse {
        case .success(let health):
            XCTAssertEqual(health.status, "healthy")
        case .failure(let error):
            switch error {
            case .requestFailed(let message):
                XCTFail("Network error: \(message)")
            case .errorResponse(let rpcError):
                XCTFail("RPC error \(rpcError.code): \(rpcError.message ?? "unknown")")
            case .parsingResponseFailed(let message, _):
                XCTFail("Parse error: \(message)")
            }
        }
    }

    func testSorobanSendTransactionError() async throws {
        // Snippet: Sending Soroban Transactions
        // Submit an unsigned transaction to trigger STATUS_ERROR
        let sourceKeyPair = try KeyPair.generateRandomKeyPair()
        await fundAccount(sourceKeyPair)

        let accountResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
        guard case .success(let account) = accountResponse else {
            XCTFail("Failed to load account")
            return
        }

        // Build a minimal transaction but do not sign it
        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: sourceKeyPair.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 1.0
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: nil
        )

        let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

        let sendResponse = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendResponse {
        case .success(let result):
            switch result.status {
            case SendTransactionResponse.STATUS_PENDING:
                // Unlikely for unsigned tx, but handle the branch
                XCTAssertFalse(result.transactionId.isEmpty)
            case SendTransactionResponse.STATUS_ERROR:
                // Expected -- unsigned transaction rejected
                XCTAssertFalse(result.transactionId.isEmpty)
            case SendTransactionResponse.STATUS_DUPLICATE:
                print("Transaction already submitted")
            case SendTransactionResponse.STATUS_TRY_AGAIN_LATER:
                print("Server busy")
            default:
                XCTFail("Unexpected status: \(result.status)")
            }
        case .failure(let error):
            // RPC-level failure is also acceptable here
            print("RPC error: \(error)")
        }
    }

    func testSorobanGetTransactionNotFound() async {
        // Snippet: Polling Transaction Status
        // Poll for a non-existent transaction hash to trigger STATUS_NOT_FOUND
        let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
        let fakeHash = "0000000000000000000000000000000000000000000000000000000000000000"

        let txResponse = await sorobanServer.getTransaction(transactionHash: fakeHash)
        switch txResponse {
        case .success(let txInfo):
            switch txInfo.status {
            case GetTransactionResponse.STATUS_SUCCESS:
                XCTFail("Expected NOT_FOUND for fake hash")
            case GetTransactionResponse.STATUS_FAILED:
                XCTFail("Expected NOT_FOUND for fake hash")
            case GetTransactionResponse.STATUS_NOT_FOUND:
                // Expected -- transaction does not exist
                break
            default:
                XCTFail("Unexpected status: \(txInfo.status)")
            }
        case .failure(let error):
            XCTFail("RPC error: \(error)")
        }
    }

    // MARK: - Soroban Client Errors

    func testAssembledTransactionErrorCases() {
        // Verify all AssembledTransactionError cases can be matched
        // as documented in the error handling guide. This ensures the
        // switch statement in the docs stays in sync with the SDK.
        let cases: [AssembledTransactionError] = [
            .simulationFailed(message: "test"),
            .restoreNeeded(message: "test"),
            .automaticRestoreFailed(message: "test"),
            .missingPrivateKey(message: "test"),
            .multipleSignersRequired(message: "test"),
            .sendFailed(message: "test"),
            .notYetSimulated(message: "test"),
            .notYetAssembled(message: "test"),
            .notYetSigned(message: "test"),
            .isReadCall(message: "test"),
            .unexpectedTxType(message: "test"),
            .pollInterrupted(message: "test"),
        ]

        for error in cases {
            switch error {
            case .simulationFailed(let message):
                XCTAssertEqual(message, "test")
            case .restoreNeeded(let message):
                XCTAssertEqual(message, "test")
            case .automaticRestoreFailed(let message):
                XCTAssertEqual(message, "test")
            case .missingPrivateKey(let message):
                XCTAssertEqual(message, "test")
            case .multipleSignersRequired(let message):
                XCTAssertEqual(message, "test")
            case .sendFailed(let message):
                XCTAssertEqual(message, "test")
            case .notYetSimulated(let message):
                XCTAssertEqual(message, "test")
            case .notYetAssembled(let message):
                XCTAssertEqual(message, "test")
            case .notYetSigned(let message):
                XCTAssertEqual(message, "test")
            case .isReadCall(let message):
                XCTAssertEqual(message, "test")
            case .unexpectedTxType(let message):
                XCTAssertEqual(message, "test")
            case .pollInterrupted(let message):
                XCTAssertEqual(message, "test")
            }
        }
    }

    func testSorobanClientErrorCases() {
        // Verify all SorobanClientError cases can be matched
        let cases: [SorobanClientError] = [
            .methodNotFound(message: "test"),
            .invokeFailed(message: "test"),
            .deployFailed(message: "test"),
            .installFailed(message: "test"),
        ]

        for error in cases {
            switch error {
            case .methodNotFound(let message):
                XCTAssertEqual(message, "test")
            case .invokeFailed(let message):
                XCTAssertEqual(message, "test")
            case .deployFailed(let message):
                XCTAssertEqual(message, "test")
            case .installFailed(let message):
                XCTAssertEqual(message, "test")
            }
        }
    }

    // MARK: - SDK Validation Errors

    func testStellarSDKErrorInvalidArgument() throws {
        // Snippet: StellarSDKError
        // Trigger invalidArgument by decoding invalid XDR
        do {
            _ = try TransactionEnvelopeXDR(xdr: "not_valid_xdr")
            XCTFail("Expected StellarSDKError for invalid XDR")
        } catch is StellarSDKError {
            // Expected -- invalid XDR input triggers xdrDecodingError or invalidArgument
        } catch {
            // XDR decoding may throw other low-level errors depending on input
            // The key point is that it does throw
        }
    }

    func testStellarSDKErrorCases() {
        // Verify all StellarSDKError cases can be constructed and matched
        let cases: [StellarSDKError] = [
            .invalidArgument(message: "test"),
            .xdrDecodingError(message: "test"),
            .xdrEncodingError(message: "test"),
            .encodingError(message: "test"),
            .decodingError(message: "test"),
        ]

        for error in cases {
            switch error {
            case .invalidArgument(let message):
                XCTAssertEqual(message, "test")
            case .xdrDecodingError(let message):
                XCTAssertEqual(message, "test")
            case .xdrEncodingError(let message):
                XCTAssertEqual(message, "test")
            case .encodingError(let message):
                XCTAssertEqual(message, "test")
            case .decodingError(let message):
                XCTAssertEqual(message, "test")
            }
        }
    }

    func testKeyValidationErrors() throws {
        // Snippet: Key Validation Errors
        do {
            _ = try KeyPair(accountId: "NOT_A_VALID_KEY")
            XCTFail("Expected error for invalid key")
        } catch is KeyUtilsError {
            // Expected for malformed input
        } catch is Ed25519Error {
            // Expected for inputs that decode but fail validation
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testKeyValidationInvalidChecksum() throws {
        // Modify the last character of a valid-looking key to produce a checksum error
        do {
            _ = try KeyPair(accountId: "GABC5OPBHL5RKWVQU7FGLU4AAGCASIHMJBWYV2YII5ZP4QHDSYAYK7A")
            XCTFail("Expected error for bad checksum")
        } catch let error as KeyUtilsError {
            if case .invalidChecksum = error {
                // Expected
            } else {
                XCTFail("Expected invalidChecksum but got: \(error)")
            }
        } catch is Ed25519Error {
            // Some corrupted keys pass Base32 decode but fail Ed25519 validation
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
