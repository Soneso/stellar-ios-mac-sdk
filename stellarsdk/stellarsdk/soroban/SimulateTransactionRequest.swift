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
/// - useUpgradedAuth: Request protocol-27 V2 credential arms in the simulation response (default true)
///
/// Authorization modes (protocol 23+):
/// - "enforce": Strict authorization checking (default)
/// - "record": Record auth entries without enforcing
/// - "record_allow_nonroot": Allow non-root authorization
///
/// **`useUpgradedAuth` flag**
///
/// The key `"useUpgradedAuth"` is always included as a sibling of `"transaction"` in the
/// JSON-RPC params, carrying the current flag value. When `true` (the default), the RPC
/// records `ADDRESS_V2` credential arms; when `false`, legacy `ADDRESS` arms. Set the flag
/// to `false` on a network below protocol 27, where V2 credential arms invalidate the
/// transaction.
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

    /// Selects the credential arm the simulation records.
    ///
    /// When `true` (the default), `ADDRESS_V2` credential arms are requested; when `false`,
    /// legacy `ADDRESS` arms. The key is always sent in the JSON-RPC params with the current
    /// value. Set to `false` on a network below protocol 27, where V2 arms invalidate the
    /// transaction. RPC servers without support silently ignore this flag and return legacy
    /// `ADDRESS` entries.
    public let useUpgradedAuth: Bool

    /// Creates a request for simulating Soroban transaction execution.
    public init(transaction: Transaction, resourceConfig: ResourceConfig? = nil, authMode: String? = nil, useUpgradedAuth: Bool = true) {
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
        result["useUpgradedAuth"] = useUpgradedAuth
        return result
    }
}
