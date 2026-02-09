//
//  StellarSDKLogUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for StellarSDKLog utility class
///
/// These tests verify that the logging methods handle all error types correctly
/// without crashing. Since the logger uses print() statements, we cannot intercept
/// the output directly, so we test for correct execution and no exceptions.
class StellarSDKLogUnitTests: XCTestCase {

    // MARK: - Test Helpers

    private func createBasicErrorResponse() -> ErrorResponse {
        let json = """
        {
            "type": "https://stellar.org/horizon-errors/bad_request",
            "title": "Bad Request",
            "status": 400,
            "detail": "The request you sent was invalid in some way."
        }
        """
        let data = json.data(using: .utf8)!
        return try! JSONDecoder().decode(ErrorResponse.self, from: data)
    }

    private func createFullErrorResponse() -> ErrorResponse {
        let json = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "instance": "horizon-testnet-001.stellar.org/12345",
            "extras": {
                "envelope_xdr": "AAAAAGXNHH4JTvHGJF5YAAAAAAB",
                "result_xdr": "AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=",
                "hash": "6cbb7f714d67e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2",
                "result_codes": {
                    "transaction": "tx_failed",
                    "operations": ["op_underfunded", "op_success"]
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        return try! JSONDecoder().decode(ErrorResponse.self, from: data)
    }

    // MARK: - Tests for printHorizonRequestErrorMessage

    func testPrintHorizonRequestErrorMessage_RequestFailed() {
        let tag = "TestTag"
        let message = "Network connection failed"
        let errorResponse = createBasicErrorResponse()
        let error = HorizonRequestError.requestFailed(message: message, horizonErrorResponse: errorResponse)

        StellarSDKLog.printHorizonRequestErrorMessage(tag: tag, horizonRequestError: error)

        XCTAssertTrue(true, "Should handle requestFailed error without crashing")
    }

    func testPrintHorizonRequestErrorMessage_Unauthorized() {
        let tag = "TestTag"
        let message = "Authentication required"
        let error = HorizonRequestError.unauthorized(message: message)

        StellarSDKLog.printHorizonRequestErrorMessage(tag: tag, horizonRequestError: error)

        XCTAssertTrue(true, "Should handle unauthorized error without crashing")
    }

    func testPrintHorizonRequestErrorMessage_EmptyResponse() {
        let tag = "TestTag"
        let error = HorizonRequestError.emptyResponse

        StellarSDKLog.printHorizonRequestErrorMessage(tag: tag, horizonRequestError: error)

        XCTAssertTrue(true, "Should handle emptyResponse error without crashing")
    }

    func testPrintHorizonRequestErrorMessage_ParsingResponseFailed() {
        let tag = "TestTag"
        let message = "Failed to parse JSON response"
        let error = HorizonRequestError.parsingResponseFailed(message: message)

        StellarSDKLog.printHorizonRequestErrorMessage(tag: tag, horizonRequestError: error)

        XCTAssertTrue(true, "Should handle parsingResponseFailed error without crashing")
    }

    func testPrintHorizonRequestErrorMessage_ErrorOnStreamReceive() {
        let tag = "TestTag"
        let message = "Stream connection interrupted"
        let error = HorizonRequestError.errorOnStreamReceive(message: message)

        StellarSDKLog.printHorizonRequestErrorMessage(tag: tag, horizonRequestError: error)

        XCTAssertTrue(true, "Should handle errorOnStreamReceive error without crashing")
    }

    func testPrintHorizonRequestErrorMessage_WithNilErrorResponse() {
        let tag = "TestTag"
        let message = "Network error"
        let error = HorizonRequestError.requestFailed(message: message, horizonErrorResponse: nil)

        StellarSDKLog.printHorizonRequestErrorMessage(tag: tag, horizonRequestError: error)

        XCTAssertTrue(true, "Should handle error with nil error response without crashing")
    }

    // MARK: - Tests for printErrorResponse

    func testPrintErrorResponse_WithBasicErrorResponse() {
        let tag = "TestTag"
        let errorResponse = createBasicErrorResponse()

        StellarSDKLog.printErrorResponse(tag: tag, errorResponse: errorResponse)

        XCTAssertTrue(true, "Should handle basic error response without crashing")
    }

    func testPrintErrorResponse_WithFullErrorResponse() {
        let tag = "TestTag"
        let errorResponse = createFullErrorResponse()

        StellarSDKLog.printErrorResponse(tag: tag, errorResponse: errorResponse)

        XCTAssertTrue(true, "Should handle full error response with extras without crashing")
    }

    func testPrintErrorResponse_WithNilErrorResponse() {
        let tag = "TestTag"

        StellarSDKLog.printErrorResponse(tag: tag, errorResponse: nil)

        XCTAssertTrue(true, "Should handle nil error response without crashing")
    }

    func testPrintErrorResponse_WithExtrasButNoResultCodes() {
        let json = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "extras": {
                "envelope_xdr": "AAAAAGXNHH4JTvHGJF5YAAAAAAB",
                "result_xdr": "AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=",
                "hash": "6cbb7f714d67e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2e4c4f2"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let errorResponse = try! JSONDecoder().decode(ErrorResponse.self, from: data)

        StellarSDKLog.printErrorResponse(tag: "TestTag", errorResponse: errorResponse)

        XCTAssertTrue(true, "Should handle error response with extras but no result codes without crashing")
    }

    func testPrintErrorResponse_WithMultipleOperationCodes() {
        let json = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "extras": {
                "result_codes": {
                    "transaction": "tx_failed",
                    "operations": ["op_underfunded", "op_line_full", "op_success", "op_no_trust"]
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let errorResponse = try! JSONDecoder().decode(ErrorResponse.self, from: data)

        StellarSDKLog.printErrorResponse(tag: "TestTag", errorResponse: errorResponse)

        XCTAssertTrue(true, "Should handle multiple operation codes without crashing")
    }

    func testPrintErrorResponse_WithEmptyOperationsArray() {
        let json = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "extras": {
                "result_codes": {
                    "transaction": "tx_failed",
                    "operations": []
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let errorResponse = try! JSONDecoder().decode(ErrorResponse.self, from: data)

        StellarSDKLog.printErrorResponse(tag: "TestTag", errorResponse: errorResponse)

        XCTAssertTrue(true, "Should handle empty operations array without crashing")
    }
}
