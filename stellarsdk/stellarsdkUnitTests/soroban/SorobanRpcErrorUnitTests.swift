//
//  SorobanRpcErrorUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class SorobanRpcErrorUnitTests: XCTestCase {

    func testSorobanRpcErrorParsing() {
        // Given a JSON-RPC error response
        let errorDict: [String: Any] = [
            "code": -32601,
            "message": "method not found",
            "data": "testMethod"
        ]

        // When parsed into SorobanRpcError
        let code = errorDict["code"] as? Int ?? -1
        let message = errorDict["message"] as? String
        let data = errorDict["data"] as? String
        let error = SorobanRpcError(code: code, message: message, data: data)

        // Then all fields should be correctly populated
        XCTAssertEqual(error.code, -32601)
        XCTAssertEqual(error.message, "method not found")
        XCTAssertEqual(error.data, "testMethod")
    }

    func testSorobanRpcErrorWithoutData() {
        // Test that data field is optional
        let error = SorobanRpcError(code: -32600, message: "Invalid Request", data: nil)

        XCTAssertEqual(error.code, -32600)
        XCTAssertEqual(error.message, "Invalid Request")
        XCTAssertNil(error.data)
    }

    func testSorobanRpcErrorWithoutMessage() {
        // Test that message field is optional
        let error = SorobanRpcError(code: -32700, message: nil, data: nil)

        XCTAssertEqual(error.code, -32700)
        XCTAssertNil(error.message)
        XCTAssertNil(error.data)
    }

    func testSorobanRpcErrorStandardCodes() {
        // Test standard JSON-RPC 2.0 error codes

        // Parse error
        let parseError = SorobanRpcError(code: -32700, message: "Parse error", data: nil)
        XCTAssertEqual(parseError.code, -32700)
        XCTAssertEqual(parseError.message, "Parse error")

        // Invalid Request
        let invalidRequest = SorobanRpcError(code: -32600, message: "Invalid Request", data: nil)
        XCTAssertEqual(invalidRequest.code, -32600)
        XCTAssertEqual(invalidRequest.message, "Invalid Request")

        // Method not found
        let methodNotFound = SorobanRpcError(code: -32601, message: "Method not found", data: nil)
        XCTAssertEqual(methodNotFound.code, -32601)
        XCTAssertEqual(methodNotFound.message, "Method not found")

        // Invalid params
        let invalidParams = SorobanRpcError(code: -32602, message: "Invalid params", data: nil)
        XCTAssertEqual(invalidParams.code, -32602)
        XCTAssertEqual(invalidParams.message, "Invalid params")

        // Internal error
        let internalError = SorobanRpcError(code: -32603, message: "Internal error", data: nil)
        XCTAssertEqual(internalError.code, -32603)
        XCTAssertEqual(internalError.message, "Internal error")
    }

    func testSorobanRpcRequestErrorTypes() {
        // Test requestFailed error case
        let requestFailedError = SorobanRpcRequestError.requestFailed(message: "Network timeout")
        if case .requestFailed(let message) = requestFailedError {
            XCTAssertEqual(message, "Network timeout")
        } else {
            XCTFail("Expected requestFailed error case")
        }

        // Test errorResponse error case
        let rpcError = SorobanRpcError(code: -32601, message: "method not found", data: "getInvalidMethod")
        let errorResponseError = SorobanRpcRequestError.errorResponse(error: rpcError)
        if case .errorResponse(let error) = errorResponseError {
            XCTAssertEqual(error.code, -32601)
            XCTAssertEqual(error.message, "method not found")
            XCTAssertEqual(error.data, "getInvalidMethod")
        } else {
            XCTFail("Expected errorResponse error case")
        }

        // Test parsingResponseFailed error case
        let responseData = Data("invalid json".utf8)
        let parsingError = SorobanRpcRequestError.parsingResponseFailed(message: "JSON parsing failed", responseData: responseData)
        if case .parsingResponseFailed(let message, let data) = parsingError {
            XCTAssertEqual(message, "JSON parsing failed")
            XCTAssertEqual(data, responseData)
        } else {
            XCTFail("Expected parsingResponseFailed error case")
        }
    }

    func testSorobanRpcErrorWithComplexData() {
        // Test error with more complex data field
        let complexData = "Additional context: The method 'simulateTransaction' is not available in this RPC version"
        let error = SorobanRpcError(code: -32601, message: "method not found", data: complexData)

        XCTAssertEqual(error.code, -32601)
        XCTAssertEqual(error.message, "method not found")
        XCTAssertEqual(error.data, complexData)
        XCTAssertTrue(error.data?.contains("simulateTransaction") ?? false)
    }

    func testSorobanRpcErrorInitialization() {
        // Test various initialization patterns

        // Full initialization
        let fullError = SorobanRpcError(code: -32000, message: "Server error", data: "details")
        XCTAssertEqual(fullError.code, -32000)
        XCTAssertEqual(fullError.message, "Server error")
        XCTAssertEqual(fullError.data, "details")

        // Initialization with only code
        let codeOnlyError = SorobanRpcError(code: -32001)
        XCTAssertEqual(codeOnlyError.code, -32001)
        XCTAssertNil(codeOnlyError.message)
        XCTAssertNil(codeOnlyError.data)

        // Initialization with code and message
        let codeAndMessageError = SorobanRpcError(code: -32002, message: "Custom error")
        XCTAssertEqual(codeAndMessageError.code, -32002)
        XCTAssertEqual(codeAndMessageError.message, "Custom error")
        XCTAssertNil(codeAndMessageError.data)
    }

    func testSorobanRpcErrorFromDictionary() {
        // Simulate parsing from a JSON-RPC response
        let jsonResponse: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "error": [
                "code": -32601,
                "message": "method not found",
                "data": "additional info"
            ]
        ]

        // Extract error dictionary
        guard let errorDict = jsonResponse["error"] as? [String: Any] else {
            XCTFail("Failed to extract error dictionary")
            return
        }

        // Parse into SorobanRpcError
        let code = errorDict["code"] as? Int ?? -1
        let message = errorDict["message"] as? String
        let data = errorDict["data"] as? String
        let error = SorobanRpcError(code: code, message: message, data: data)

        // Verify all fields
        XCTAssertEqual(error.code, -32601)
        XCTAssertEqual(error.message, "method not found")
        XCTAssertEqual(error.data, "additional info")
    }

    func testSorobanRpcErrorFromDictionaryWithMissingFields() {
        // Test parsing when some fields are missing
        let incompleteErrorDict: [String: Any] = [
            "code": -32602
        ]

        let code = incompleteErrorDict["code"] as? Int ?? -1
        let message = incompleteErrorDict["message"] as? String
        let data = incompleteErrorDict["data"] as? String
        let error = SorobanRpcError(code: code, message: message, data: data)

        XCTAssertEqual(error.code, -32602)
        XCTAssertNil(error.message)
        XCTAssertNil(error.data)
    }

    func testSorobanRpcErrorWithEmptyStrings() {
        // Test with empty strings
        let error = SorobanRpcError(code: -32000, message: "", data: "")

        XCTAssertEqual(error.code, -32000)
        XCTAssertEqual(error.message, "")
        XCTAssertEqual(error.data, "")
        XCTAssertNotNil(error.message)
        XCTAssertNotNil(error.data)
    }

    func testSorobanRpcErrorAsErrorType() {
        // Test that SorobanRpcError conforms to Error protocol
        let error: Error = SorobanRpcError(code: -32603, message: "Internal error", data: nil)
        XCTAssertTrue(error is SorobanRpcError)

        if let rpcError = error as? SorobanRpcError {
            XCTAssertEqual(rpcError.code, -32603)
            XCTAssertEqual(rpcError.message, "Internal error")
        } else {
            XCTFail("Failed to cast Error to SorobanRpcError")
        }
    }

    func testSorobanRpcErrorSendableConformance() {
        // Test that SorobanRpcError conforms to Sendable protocol
        // This is important for concurrency safety
        let error = SorobanRpcError(code: -32000, message: "Test", data: nil)

        // This test validates that the struct compiles with Sendable conformance
        // Sendable conformance is necessary for passing errors across async boundaries
        Task {
            let _ = error.code
            let _ = error.message
            let _ = error.data
        }

        // Verify the error properties are accessible
        XCTAssertEqual(error.code, -32000)
        XCTAssertEqual(error.message, "Test")
        XCTAssertNil(error.data)
    }

    func testSorobanRpcErrorIntegration() async {
        // Integration test that makes a real call to the Soroban RPC server
        // and verifies error responses are properly parsed
        let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

        // Test 1: Invalid transaction hash - should trigger an error or NOT_FOUND status
        let invalidHash = "invalid_hash_that_does_not_exist_and_is_not_valid_hex"
        let result = await sorobanServer.getTransaction(transactionHash: invalidHash)

        switch result {
        case .success(let response):
            // Some servers may return status NOT_FOUND instead of an error
            XCTAssertEqual(response.status, GetTransactionResponse.STATUS_NOT_FOUND,
                          "Expected NOT_FOUND status for invalid hash")
        case .failure(let error):
            // Verify we get a proper error
            switch error {
            case .errorResponse(let rpcError):
                // Verify the error has proper structure
                XCTAssertNotEqual(rpcError.code, 0, "Error should have a non-zero code")
                // Message should be present for standard RPC errors
                XCTAssertNotNil(rpcError.message, "Error should have a message")
            case .requestFailed(_):
                // Network or request failure is also acceptable
                break
            case .parsingResponseFailed(let message, _):
                // Parsing failure would indicate an issue with our error handling
                XCTFail("Should not fail to parse error response: \(message)")
            }
        }

        // Test 2: Invalid ledger entry key
        let invalidKey = "invalid_base64_key_that_does_not_exist"
        let ledgerResult = await sorobanServer.getLedgerEntries(base64EncodedKeys: [invalidKey])

        switch ledgerResult {
        case .success(_):
            // If successful, it might just return empty entries
            // This is acceptable behavior
            break
        case .failure(let error):
            // Verify we can handle the error properly
            switch error {
            case .errorResponse(let rpcError):
                XCTAssertNotEqual(rpcError.code, 0, "Error should have a non-zero code")
            case .requestFailed(_):
                break
            case .parsingResponseFailed(let message, _):
                XCTFail("Should not fail to parse error response: \(message)")
            }
        }
    }
}
