//
//  SmartAccountSharedUtils.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Shared utility functions for Smart Account operations.
///
/// Provides reusable helpers used across multiple Smart Account components:
/// - Transaction simulation and result extraction
/// - Amount conversion (XLM to stroops)
/// - Stroops to I128 ScVal conversion
/// - Base64URL encoding/decoding
/// - Address string extraction from SCAddressXDR
///
/// These utilities are extracted to eliminate duplication across
/// OZContextRuleManager, OZMultiSignerManager, OZTransactionOperations,
/// and OZWalletOperations.
public struct SmartAccountSharedUtils: Sendable {

    // MARK: - Transaction Simulation

    /// Simulates a host function and extracts the return value.
    ///
    /// Performs the following steps:
    /// 1. Fetches the deployer account
    /// 2. Builds a transaction with the host function
    /// 3. Simulates the transaction
    /// 4. Extracts and returns the result value from simulation
    ///
    /// Used for query operations that don't require transaction submission.
    ///
    /// - Parameters:
    ///   - hostFunction: The host function to simulate
    ///   - kit: The OZSmartAccountKit instance providing deployer and server access
    /// - Returns: The SCVal return value from the simulation
    /// - Throws: SmartAccountError if simulation fails or result extraction fails
    public static func simulateAndExtractResult(
        hostFunction: HostFunctionXDR,
        kit: OZSmartAccountKit
    ) async throws -> SCValXDR {
        // Get deployer account
        let deployer = try kit.getDeployer()

        let accountResponse = await kit.sorobanServer.getAccount(accountId: deployer.accountId)
        guard case .success(let deployerAccount) = accountResponse else {
            throw SmartAccountError.transactionSimulationFailed("Failed to fetch deployer account")
        }

        // Build operation
        let operation = InvokeHostFunctionOperation(hostFunction: hostFunction, auth: [])

        // Build transaction for simulation
        let transaction = try Transaction(
            sourceAccount: deployerAccount,
            operations: [operation],
            memo: Memo.none,
            preconditions: nil
        )

        // Simulate transaction
        let simulateRequest = SimulateTransactionRequest(transaction: transaction)
        let simulateResponse = await kit.sorobanServer.simulateTransaction(simulateTxRequest: simulateRequest)

        guard case .success(let simulation) = simulateResponse else {
            if case .failure(let error) = simulateResponse {
                throw SmartAccountError.transactionSimulationFailed(
                    "Transaction simulation failed: \(error.localizedDescription)",
                    cause: error
                )
            }
            throw SmartAccountError.transactionSimulationFailed("Transaction simulation failed")
        }

        // Check for simulation errors
        if let error = simulation.error {
            throw SmartAccountError.transactionSimulationFailed("Simulation error: \(error)")
        }

        // Extract result
        guard let results = simulation.results, !results.isEmpty else {
            throw SmartAccountError.transactionSimulationFailed("No results returned from simulation")
        }

        guard let returnValue = results[0].value else {
            throw SmartAccountError.transactionSimulationFailed("No return value in simulation result")
        }

        return returnValue
    }

    // MARK: - Amount Conversion

    /// Converts an XLM amount to stroops.
    ///
    /// Uses NSDecimalNumber for precise decimal arithmetic with banker's rounding.
    /// Validates that the resulting stroops value is positive and within Int64 range.
    ///
    /// - Parameter amount: The amount in XLM (must be positive)
    /// - Returns: The amount in stroops (1 XLM = 10,000,000 stroops)
    /// - Throws: SmartAccountError.invalidAmount if conversion would overflow or result is invalid
    public static func amountToStroops(_ amount: Decimal) throws -> Int64 {
        let stroopsDecimal = amount * Decimal(SmartAccountConstants.STROOPS_PER_XLM)

        // Round to nearest integer
        let rounded = NSDecimalNumber(decimal: stroopsDecimal).rounding(
            accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 0,
                raiseOnExactness: false,
                raiseOnOverflow: true,
                raiseOnUnderflow: true,
                raiseOnDivideByZero: true
            )
        )

        let stroops = rounded.int64Value

        // Validate range
        guard stroops > 0 && stroops <= Int64.max else {
            throw SmartAccountError.invalidAmount("Amount out of valid range")
        }

        return stroops
    }

    /// Converts stroops (Int64) to I128 ScVal.
    ///
    /// For positive values within Int64 range, the high part is 0 and the low part
    /// contains the value as UInt64.
    ///
    /// - Parameter stroops: The amount in stroops
    /// - Returns: ScVal::I128 representation
    public static func stroopsToI128ScVal(_ stroops: Int64) -> SCValXDR {
        let i128Parts = Int128PartsXDR(hi: 0, lo: UInt64(stroops))
        return .i128(i128Parts)
    }

    // MARK: - Base64URL Encoding/Decoding

    /// Encodes data to Base64URL format (RFC 4648, no padding).
    ///
    /// Converts standard Base64 characters to URL-safe equivalents:
    /// - `+` becomes `-`
    /// - `/` becomes `_`
    /// - Padding `=` characters are removed
    ///
    /// - Parameter data: The data to encode
    /// - Returns: Base64URL-encoded string without padding
    public static func base64urlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Decodes a Base64URL-encoded string to data.
    ///
    /// Converts URL-safe characters back to standard Base64:
    /// - `-` becomes `+`
    /// - `_` becomes `/`
    /// - Adds padding `=` characters as needed
    ///
    /// - Parameter string: The Base64URL-encoded string
    /// - Returns: Decoded data, or nil if decoding fails
    public static func base64urlDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        return Data(base64Encoded: base64)
    }

    // MARK: - Address Extraction

    /// Extracts a string address from an SCAddressXDR.
    ///
    /// Returns the G-address for account types or the C-address for contract types.
    ///
    /// - Parameter address: The SCAddressXDR to extract from
    /// - Returns: The string address, or nil if extraction fails
    public static func extractAddressString(from address: SCAddressXDR) -> String? {
        // Account address: G-address
        if let accountId = address.accountId {
            return accountId
        }

        // Contract address: encode raw bytes to C-address
        switch address {
        case .contract(let data):
            return try? data.wrapped.encodeContractId()
        default:
            return nil
        }
    }
}
