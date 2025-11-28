//
//  SorobanRpcRequestError.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents an error response from the Soroban RPC server following JSON-RPC 2.0 specification.
public struct SorobanRpcError: Error, Sendable {
    /// The error code. Standard JSON-RPC codes include:
    /// -32700 (Parse error), -32600 (Invalid Request), -32601 (Method not found),
    /// -32602 (Invalid params), -32603 (Internal error)
    public let code: Int

    /// A short description of the error.
    public let message: String?

    /// Additional information about the error (optional).
    public let data: String?

    public init(code: Int, message: String? = nil, data: String? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    /// Creates an error from a JSON-RPC error dictionary.
    init(fromDictionary dict: [String: Any]) {
        self.code = dict["code"] as? Int ?? -1
        self.message = dict["message"] as? String
        self.data = dict["data"] as? String
    }
}

/// Errors that can occur during Soroban RPC requests.
///
/// These errors represent failures in communication with the Soroban RPC server
/// or problems processing RPC responses.
///
/// Error cases:
/// - requestFailed: The HTTP request to the RPC server failed
/// - errorResponse: The RPC server returned an error response
/// - parsingResponseFailed: The response could not be parsed
///
/// Example error handling:
/// ```swift
/// let response = await server.simulateTransaction(simulateTxRequest: request)
/// switch response {
/// case .success(let simulation):
///     // Handle success
///     break
/// case .failure(let error):
///     switch error {
///     case .requestFailed(let message):
///         print("Request failed: \(message)")
///     case .errorResponse(let error):
///         print("RPC error: code=\(error.code), message=\(error.message ?? "none")")
///     case .parsingResponseFailed(let message, _):
///         print("Failed to parse response: \(message)")
///     }
/// }
/// ```
///
/// See also:
/// - [SorobanServer] for RPC operations that may throw these errors
public enum SorobanRpcRequestError: Error, Sendable {
    /// HTTP request to the Soroban RPC server failed.
    case requestFailed(message: String)
    /// RPC server returned an error response.
    case errorResponse(error: SorobanRpcError)
    /// Failed to parse the RPC response data.
    case parsingResponseFailed(message: String, responseData: Data)
}
