//
//  StellarSDKLog.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 23.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Logging utility for Stellar SDK error messages and debugging.
///
/// This class provides static methods for logging Horizon request errors and error responses
/// to the console. It is primarily used for debugging and troubleshooting issues with API requests.
///
/// The logger automatically formats error messages with tags for easy identification and
/// includes detailed information about error responses, XDR data, and result codes when available.
///
/// ## Usage
///
/// ```swift
/// // Log a Horizon request error
/// StellarSDKLog.printHorizonRequestErrorMessage(tag: "MyClass", horizonRequestError: error)
///
/// // Log an error response directly
/// if let errorResponse = error.errorResponse {
///     StellarSDKLog.printErrorResponse(tag: "MyClass", errorResponse: errorResponse)
/// }
/// ```
///
/// - Note: All logging is done to standard output using Swift's print function.
///         Consider implementing custom log handlers if you need to redirect or filter output.
public final class StellarSDKLog {

    /// Prints a detailed Horizon request error message to the console.
    ///
    /// This method examines the error type and prints appropriate diagnostic information including
    /// error messages, HTTP status codes, and any error response details provided by Horizon.
    ///
    /// - Parameters:
    ///   - tag: A string identifier for the source of the error (e.g., class or method name)
    ///   - horizonRequestError: The Horizon request error to log
    ///
    /// ## Error Types Handled
    ///
    /// - Request failures (network errors, timeouts)
    /// - HTTP status errors (400, 401, 403, 404, etc.)
    /// - Rate limiting errors
    /// - Server errors (500, 501, etc.)
    /// - Parsing errors
    /// - Stream errors
    ///
    /// ## Example
    ///
    /// ```swift
    /// sdk.accounts.getAccountDetails(accountId: accountId) { response in
    ///     switch response {
    ///     case .failure(let error):
    ///         StellarSDKLog.printHorizonRequestErrorMessage(tag: "AccountService", horizonRequestError: error)
    ///     case .success(_):
    ///         // Handle success
    ///     }
    /// }
    /// ```
    public static func printHorizonRequestErrorMessage(tag: String, horizonRequestError: HorizonRequestError) {
        switch horizonRequestError {
        case .requestFailed(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .badRequest(let message, let errorResponse):
            print("\(tag): Horizon request error of type bad request with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .unauthorized(let message):
            print("\(tag): Horizon request error of type unauthorized with message: \(message)")
        case .forbidden(let message, let errorResponse):
            print("\(tag): Horizon request error of type forbidden with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notFound(let message, let errorResponse):
            print("\(tag): Horizon request error of type not found with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .duplicate(let message, let errorResponse):
            print("\(tag): Horizon request error of type duplicate with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notAcceptable(let message, let errorResponse):
            print("\(tag): Horizon request error of type not acceptable with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .beforeHistory(let message, let errorResponse):
            print("\(tag): Horizon request error of type before history with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .payloadTooLarge(let message, let errorResponse):
            print("\(tag): Horizon request error of type payload too large with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .rateLimitExceeded(let message, let errorResponse):
            print("\(tag): Horizon request error of type rate limit exceeded with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .internalServerError(let message, let errorResponse):
            print("\(tag): Horizon request error of type internal server error with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notImplemented(let message, let errorResponse):
            print("\(tag): Horizon request error of type not implemented with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .staleHistory(let message, let errorResponse):
            print("\(tag): Horizon request error of type stale history with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .timeout(let message, let errorResponse):
            print("\(tag): Horizon request error of type timeout with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .emptyResponse:
            print("\(tag): Horizon request error of type empty response.")
        case .parsingResponseFailed(let message):
            print("\(tag): Horizon request error of type parsing response failed with message: \(message)")
        case .errorOnStreamReceive(let message):
            print("\(tag): Horizon request error of type error on stream receive with message: \(message)")
        }
    }

    /// Prints detailed information about a Horizon error response.
    ///
    /// This method formats and prints all available details from a Horizon error response,
    /// including the error type, title, HTTP status code, detail message, and additional
    /// diagnostic information such as XDR data and result codes.
    ///
    /// - Parameters:
    ///   - tag: A string identifier for the source of the error (e.g., class or method name)
    ///   - errorResponse: The error response object to log, or nil if unavailable
    ///
    /// ## Information Logged
    ///
    /// - Error type (e.g., "transaction_failed", "bad_request")
    /// - Error title (human-readable description)
    /// - HTTP status code
    /// - Detailed error message
    /// - Horizon instance identifier (if available)
    /// - Transaction XDR envelope (if available)
    /// - Result XDR (if available)
    /// - Transaction hash (if available)
    /// - Transaction and operation result codes (if available)
    ///
    /// ## Example
    ///
    /// ```swift
    /// if case .badRequest(_, let errorResponse) = horizonError {
    ///     StellarSDKLog.printErrorResponse(tag: "TransactionService", errorResponse: errorResponse)
    /// }
    /// ```
    ///
    /// - Note: This method is typically called automatically by `printHorizonRequestErrorMessage`
    ///         but can be used independently when you have an ErrorResponse object.
    public static func printErrorResponse(tag: String, errorResponse: ErrorResponse?) {
        if let response = errorResponse {
            print("\(tag): Horizon Error response type: \(response.type)")
            print("\(tag): Horizon Error response tite: \(response.title)")
            print("\(tag): Horizon Error response httpStatusCode: \(response.httpStatusCode)")
            print("\(tag): Horizon Error response detail: \(response.detail)")
            if let horizonInstance = response.instance {
                print("\(tag): Horizon Error response instance: \(horizonInstance)")
            }
            
            if let extras = response.extras {
                if let envelopeXdr = extras.envelopeXdr {
                    print("\(tag): Horizon Error response extras.envelopeXdr : \(envelopeXdr)")
                }
                if let resultXdr = extras.resultXdr {
                    print("\(tag): Horizon Error response extras.resultXdr : \(resultXdr)")
                }
                if let txHash = extras.txHash {
                    print("\(tag): Horizon Error response extras.txHash : \(txHash)")
                }
                if let resultCodes = extras.resultCodes {
                    if let tx = resultCodes.transaction {
                        print("\(tag): Horizon Error response extras.resultCodes.transaction : \(tx)")
                    }
                    if let operations = resultCodes.operations {
                        for code in operations {
                            print("\(tag): Horizon Error response extras.resultCodes.operation:\(code)")
                        }
                    }
                }
            }
        }
    }
}

