//
//  SorobanRpcRequestError.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

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
///     case .errorResponse(let errorData):
///         if let code = errorData["code"], let message = errorData["message"] {
///             print("RPC error \(code): \(message)")
///         }
///     case .parsingResponseFailed(let message, _):
///         print("Failed to parse response: \(message)")
///     }
/// }
/// ```
///
/// See also:
/// - [SorobanServer] for RPC operations that may throw these errors
public enum SorobanRpcRequestError: Error {
    /// HTTP request to the Soroban RPC server failed.
    case requestFailed(message: String)
    /// RPC server returned an error response.
    case errorResponse(errorData:[String: Any])
    /// Failed to parse the RPC response data.
    case parsingResponseFailed(message:String, responseData:Data)
}
