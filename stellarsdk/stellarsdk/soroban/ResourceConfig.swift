//
//  ResourceConfig.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.12.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Configuration for Soroban transaction resource calculation during simulation.
///
/// ResourceConfig allows you to adjust the instruction budget leeway used when
/// simulating Soroban transactions. This affects how conservatively the system
/// estimates the CPU instructions needed for transaction execution.
///
/// The instruction leeway is added as a safety margin to the actual instruction
/// count observed during simulation. A higher leeway provides more buffer against
/// edge cases but increases resource fees.
///
/// Use cases:
/// - Increase leeway for transactions with variable execution paths
/// - Reduce leeway for predictable operations to minimize fees
/// - Adjust based on network conditions and fee tolerance
///
/// Example:
/// ```swift
/// // Configure with 10% instruction leeway
/// let resourceConfig = ResourceConfig(instructionLeeway: 1000000)
///
/// // Use in transaction simulation
/// let request = SimulateTransactionRequest(
///     transaction: transaction,
///     resourceConfig: resourceConfig
/// )
///
/// let response = await server.simulateTransaction(request)
/// ```
///
/// See also:
/// - [SimulateTransactionRequest] for simulation configuration
/// - [SorobanServer.simulateTransaction] for running simulations
/// - [Soroban Resource Model](https://developers.stellar.org/docs/smart-contracts/guides/transactions/resource-limits)
public class ResourceConfig {

    /// Instruction budget leeway used in preflight calculations.
    ///
    /// This value is added to the instruction count observed during simulation
    /// to provide a safety margin for actual execution. Specified in instruction
    /// units, where typical values range from 100,000 to several million depending
    /// on transaction complexity and desired safety margin.
    public let instructionLeeway: Int

    /// Creates a resource configuration with specified instruction leeway.
    ///
    /// - Parameter instructionLeeway: Additional instructions to add as safety margin during simulation
    public init(instructionLeeway:Int) {
        self.instructionLeeway = instructionLeeway
    }

    /// Builds request parameters for Soroban RPC simulation requests.
    ///
    /// Converts the configuration into a dictionary suitable for JSON-RPC requests.
    ///
    /// - Returns: Dictionary containing the instructionLeeway parameter
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        result["instructionLeeway"] = instructionLeeway
        return result;
    }
}
