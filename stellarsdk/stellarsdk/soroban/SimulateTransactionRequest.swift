//
//  SimulateTransactionRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.12.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Request parameters for simulating a Soroban transaction.
///
/// SimulateTransactionRequest configures how a transaction should be simulated
/// by the Soroban RPC server.
///
/// Parameters:
/// - transaction: The transaction to simulate (must contain InvokeHostFunction operation)
/// - resourceConfig: Optional resource budget configuration (default: 3000000 instruction leeway)
/// - authMode: Authorization simulation mode (protocol 23+)
/// - useUpgradedAuth: Request protocol-27 V2 credential arms in the simulation response (default false)
///
/// Authorization modes (protocol 23+):
/// - "enforce": Strict authorization checking (default)
/// - "record": Record auth entries without enforcing
/// - "record_allow_nonroot": Allow non-root authorization
///
/// **`useUpgradedAuth` flag**
///
/// When `useUpgradedAuth` is `true`, the key `"useUpgradedAuth": true` is included as a sibling of
/// `"transaction"` in the JSON-RPC params. The key is omitted entirely when `false`
/// (never sent as `"useUpgradedAuth": false`). Emitting V2 credential arms on a network below
/// protocol 27 invalidates the transaction, so this flag defaults to `false`.
///
/// RPC servers that do not support `useUpgradedAuth` silently ignore the key and return legacy
/// `ADDRESS` credential arms. The caller must detect V2 support by inspecting the
/// credential arm of the returned entries, not by expecting an error.
///
/// Example:
/// ```swift
/// let request = SimulateTransactionRequest(
///     transaction: transaction,
///     resourceConfig: ResourceConfig(instructionLeeway: 5000000)
/// )
///
/// let response = await server.simulateTransaction(simulateTxRequest: request)
/// ```
///
/// See also:
/// - [SorobanServer.simulateTransaction] for running simulations
/// - [SimulateTransactionResponse] for simulation results
/// - [ResourceConfig] for resource configuration
public final class SimulateTransactionRequest: @unchecked Sendable {

    /// Transaction to simulate (must contain InvokeHostFunction operation).
    public let transaction: Transaction

    /// Resource limits for simulation (instruction leeway, memory bounds).
    public let resourceConfig: ResourceConfig?

    /// Support for non-root authorization. Only available for protocol >= 23
    /// Possible values: "enforce" | "record" | "record_allow_nonroot"
    public let authMode: String?

    /// Request protocol-27 V2 credential arms in the simulation response.
    ///
    /// When `true`, `"useUpgradedAuth": true` is included in the JSON-RPC params. The key is
    /// omitted entirely when `false`. Requires protocol 27; emitting V2 on older networks
    /// invalidates the transaction. RPC servers without support silently ignore this flag
    /// and return legacy `ADDRESS` entries.
    public let useUpgradedAuth: Bool

    /// Creates a request for simulating Soroban transaction execution.
    public init(transaction: Transaction, resourceConfig: ResourceConfig? = nil, authMode: String? = nil, useUpgradedAuth: Bool = false) {
        self.transaction = transaction
        self.resourceConfig = resourceConfig
        self.authMode = authMode
        self.useUpgradedAuth = useUpgradedAuth
    }

    /// Builds JSON-RPC request parameters from the simulation configuration.
    public func buildRequestParams() -> [String: Any] {
        var result: [String: Any] = [:]
        result["transaction"] = try? transaction.encodedEnvelope()
        if let rC = resourceConfig {
            result["resourceConfig"] = rC.buildRequestParams()
        }
        if let authMode = authMode {
            result["authMode"] = authMode
        }
        if useUpgradedAuth {
            result["useUpgradedAuth"] = true
        }
        return result
    }
}
