//
//  SorobanClientError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur during high-level SorobanClient operations.
///
/// These errors represent failures in contract installation, deployment,
/// and invocation operations performed through SorobanClient.
///
/// Error cases:
/// - deployFailed: Contract deployment failed
/// - installFailed: Contract installation (WASM upload) failed
/// - invokeFailed: Contract method invocation failed
/// - methodNotFound: Attempted to invoke a non-existent contract method
///
/// Example error handling:
/// ```swift
/// do {
///     let result = try await client.invokeMethod(
///         name: "transfer",
///         args: [from, to, amount]
///     )
///     print("Success: \(result)")
/// } catch SorobanClientError.invokeFailed(let message) {
///     print("Invocation failed: \(message)")
/// } catch SorobanClientError.methodNotFound(let message) {
///     print("Method not found: \(message)")
/// } catch {
///     print("Other error: \(error)")
/// }
/// ```
///
/// See also:
/// - [SorobanClient] for operations that may throw these errors
public enum SorobanClientError: Error {
    case deployFailed(message: String)
    case installFailed(message: String)
    case invokeFailed(message: String)
    case methodNotFound(message: String)
}
