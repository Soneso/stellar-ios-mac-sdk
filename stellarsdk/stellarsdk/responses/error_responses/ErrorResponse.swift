//
//  ErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an error response from the Horizon API.
///
/// When a request fails, Horizon returns an error response with details about what went wrong.
/// Error responses include HTTP status codes, error types, descriptions, and additional debugging
/// information in the extras field.
///
/// Common error types:
/// - 400 Bad Request: Invalid parameters or malformed request
/// - 404 Not Found: Resource doesn't exist
/// - 429 Rate Limit Exceeded: Too many requests
/// - 500 Internal Server Error: Server-side problem
///
/// Example usage:
/// ```swift
/// let response = await sdk.transactions.submitTransaction(transaction: tx)
/// switch response {
/// case .success(let result):
///     print("Success: \(result.hash)")
/// case .failure(let error):
///     if case .badRequest(_, let horizonError) = error,
///        let errorResponse = horizonError {
///         print("Error: \(errorResponse.title)")
///         print("Detail: \(errorResponse.detail)")
///
///         // Check for transaction-specific errors
///         if let extras = errorResponse.extras,
///            let resultCodes = extras.resultCodes {
///             print("Transaction result: \(resultCodes.transaction ?? "")")
///             print("Operation results: \(resultCodes.operations ?? [])")
///         }
///     }
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - HorizonRequestError for error enum types
public class ErrorResponse: Decodable, @unchecked Sendable {

    /// URL identifier for the error type. Can be visited for more information.
    public let type:String

    /// Short human-readable summary of the error.
    public let title:String

    /// HTTP status code (400, 404, 429, 500, etc.).
    public let httpStatusCode:UInt

    /// Detailed description of the error and potential solutions.
    public let detail:String

    /// Unique request ID for correlating with server logs. Useful for support requests.
    public let instance:String?

    /// Additional error context including transaction result codes and XDR data.
    public let extras:ErrorResponseExtras?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case type
        case title
        case httpStatusCode = "status"
        case detail
        case instance
        case extras
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        title = try values.decode(String.self, forKey: .title)
        httpStatusCode = try values.decode(UInt.self, forKey: .httpStatusCode)
        detail = try values.decode(String.self, forKey: .detail)
        instance = try values.decodeIfPresent(String.self, forKey: .instance)
        extras = try values.decodeIfPresent(ErrorResponseExtras.self, forKey: .extras)
    }
}

/// Additional error information for transaction submission failures.
///
/// Contains transaction-specific debugging data including XDR representations
/// and result codes from Stellar Core.
public final class ErrorResponseExtras: Decodable, Sendable {
    /// Base64-encoded XDR of the transaction envelope that failed.
    public let envelopeXdr: String?

    /// Base64-encoded XDR of the transaction result from Stellar Core.
    public let resultXdr: String?

    /// Parsed result codes indicating why the transaction or operations failed.
    public let resultCodes: ErrorResultCodes?

    /// Hash of the submitted transaction.
    public let txHash: String?

    private enum CodingKeys: String, CodingKey {
        case envelopeXdr = "envelope_xdr"
        case resultXdr = "result_xdr"
        case resultCodes = "result_codes"
        case txHash = "hash"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        envelopeXdr = try values.decodeIfPresent(String.self, forKey: .envelopeXdr)
        resultXdr = try values.decodeIfPresent(String.self, forKey: .resultXdr)
        resultCodes = try values.decodeIfPresent(ErrorResultCodes.self, forKey: .resultCodes)
        txHash = try values.decodeIfPresent(String.self, forKey: .txHash)
    }
}

/// Result codes explaining transaction and operation failures.
///
/// Contains error codes from Stellar Core indicating why a transaction failed.
/// Transaction result codes apply to the whole transaction, while operation result
/// codes indicate which specific operations failed and why.
///
/// Common transaction results:
/// - tx_failed: One or more operations failed
/// - tx_bad_seq: Incorrect sequence number
/// - tx_insufficient_balance: Not enough XLM to pay fee
///
/// See [Stellar developer docs](https://developers.stellar.org)
public final class ErrorResultCodes: Decodable, Sendable {
    /// Transaction-level result code (e.g., "tx_failed", "tx_bad_seq").
    public let transaction: String?

    /// Array of operation result codes, one per operation. Indicates which operations failed.
    public let operations: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case transaction
        case operations
    }
    
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transaction = try values.decodeIfPresent(String.self, forKey: .transaction)
        operations = try values.decodeIfPresent([String].self, forKey: .operations)
    }
}

/// HTTP 504 Gateway Timeout error from Horizon indicating the request took too long to process.
///
/// This error occurs when:
/// - Request processing exceeded Horizon's configured timeout
/// - Stellar Core took too long to respond
/// - Database query exceeded time limits
/// - Network congestion or connectivity issues
///
/// Retry the request after a delay. For complex queries, consider narrowing the scope
/// or using pagination to reduce processing time.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - ErrorResponse for common error properties
public class TimeoutErrorResponse: ErrorResponse, @unchecked Sendable {}
