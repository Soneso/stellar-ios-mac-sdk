//
//  OZPolicyManager.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Policy type definitions for smart account context rules.
///
/// Policies define authorization rules that must be satisfied for transactions
/// to execute. Multiple policy types are supported:
///
/// - Simple Threshold: N-of-N authorization (all signers must sign)
/// - Weighted Threshold: Weighted voting with configurable threshold
/// - Spending Limit: Maximum amount per time period (in ledgers)
///
/// Policies are installed on specific context rules and evaluated during
/// transaction authorization.
///
/// Example usage:
/// ```swift
/// // Create a 2-of-3 simple threshold policy
/// let simplePolicy = OZPolicyType.simpleThreshold(threshold: 2)
///
/// // Create a weighted threshold policy (100 points required)
/// let weightedPolicy = OZPolicyType.weightedThreshold(
///     signerWeights: [
///         (signer: delegatedSigner1, weight: 50),
///         (signer: delegatedSigner2, weight: 30),
///         (signer: externalSigner, weight: 20)
///     ],
///     threshold: 100
/// )
///
/// // Create a spending limit (1000 XLM per day)
/// let spendingPolicy = OZPolicyType.spendingLimit(
///     limit: 1000 * 10_000_000, // Convert XLM to stroops
///     periodLedgers: UInt32(SmartAccountConstants.LEDGERS_PER_DAY)
/// )
/// ```
public enum OZPolicyType: Sendable {
    /// Simple threshold policy requiring exactly N signers to authorize.
    ///
    /// All signers in the context rule have equal weight (1 vote each).
    /// The threshold specifies how many signers must approve.
    ///
    /// - Parameter threshold: Number of signers required to authorize (1 to signer count)
    case simpleThreshold(threshold: UInt32)

    /// Weighted threshold policy with configurable signer weights.
    ///
    /// Each signer has a weight (vote power). The sum of approving signers'
    /// weights must meet or exceed the threshold.
    ///
    /// - Parameters:
    ///   - signerWeights: Array of (signer, weight) tuples defining vote power
    ///   - threshold: Minimum total weight required for authorization
    case weightedThreshold(signerWeights: [(signer: SmartAccountSigner, weight: UInt32)], threshold: UInt32)

    /// Spending limit policy restricting total amount per time period.
    ///
    /// Limits the total amount that can be spent within a rolling time window.
    /// The period is specified in ledgers (approximately 5 seconds per ledger).
    ///
    /// - Parameters:
    ///   - limit: Maximum amount in stroops for the period
    ///   - periodLedgers: Time window in ledgers (e.g., 17,280 for one day)
    case spendingLimit(limit: Int64, periodLedgers: UInt32)
}

/// Manager for policy operations on OpenZeppelin Smart Accounts.
///
/// Provides functionality to add and remove policies on context rules. Policies
/// define authorization rules that must be satisfied for transactions to execute.
///
/// A context rule can have multiple policies (up to MAX_POLICIES), and all
/// policies must be satisfied for a transaction to succeed.
///
/// Policy lifecycle:
/// 1. Deploy policy contract to network
/// 2. Add policy to context rule with installation parameters
/// 3. Policy is initialized on the smart account contract
/// 4. Policy is evaluated during transaction authorization
/// 5. Remove policy when no longer needed
///
/// This manager is typically accessed via OZSmartAccountKit rather than
/// instantiated directly.
///
/// Example usage:
/// ```swift
/// let kit = try OZSmartAccountKit(config: config)
/// let policyManager = OZPolicyManager(kit: kit, transactionOps: txOps)
///
/// // Add a simple threshold policy
/// let result = try await policyManager.addPolicy(
///     contextRuleId: 0,
///     policyAddress: "CBCD1234...",
///     policyType: .simpleThreshold(threshold: 2)
/// )
///
/// if result.success {
///     print("Policy added successfully")
/// }
///
/// // Remove a policy
/// let removeResult = try await policyManager.removePolicy(
///     contextRuleId: 0,
///     policyAddress: "CBCD1234..."
/// )
/// ```
///
/// Thread Safety:
/// This class is thread-safe. All operations are async and can be called from any thread.
public final class OZPolicyManager: @unchecked Sendable {
    /// Reference to the parent SmartAccountKit instance.
    private let kit: OZSmartAccountKit

    /// Transaction operations for building and submitting policy changes.
    private let transactionOps: OZTransactionOperations

    /// Creates a new OZPolicyManager instance.
    ///
    /// - Parameters:
    ///   - kit: The parent OZSmartAccountKit instance
    ///   - transactionOps: Transaction operations for submission
    internal init(kit: OZSmartAccountKit, transactionOps: OZTransactionOperations) {
        self.kit = kit
        self.transactionOps = transactionOps
    }

    // MARK: - Add Policy

    /// Adds a policy to a context rule.
    ///
    /// Installs a new policy on the specified context rule. The policy contract must
    /// already be deployed on the network. The installation parameters are derived from
    /// the policy type and encoded as an SCVal map with keys in alphabetical order.
    ///
    /// Flow:
    /// 1. Validates inputs (connected wallet, policy address format)
    /// 2. Encodes policy-specific installation parameters
    /// 3. Builds contract invocation for add_policy
    /// 4. Submits transaction via transactionOps (handles simulation, signing, polling)
    ///
    /// IMPORTANT: This operation requires the connected wallet to have authorization
    /// on the smart account. The user will be prompted for biometric authentication
    /// to sign the transaction.
    ///
    /// Contract limits:
    /// - Maximum MAX_POLICIES policies per context rule
    /// - Policy address must be a valid C-address
    /// - Installation parameters must match policy contract expectations
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID to add the policy to (0 for Default rule)
    ///   - policyAddress: The policy contract address (C-address)
    ///   - policyType: The type of policy with configuration parameters
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction submission fails
    ///
    /// Example:
    /// ```swift
    /// // Add a 2-of-2 simple threshold policy
    /// let result = try await policyManager.addPolicy(
    ///     contextRuleId: 0,
    ///     policyAddress: "CBCD1234...",
    ///     policyType: .simpleThreshold(threshold: 2)
    /// )
    ///
    /// if result.success {
    ///     print("Policy added: \(result.hash ?? "")")
    /// } else {
    ///     print("Failed to add policy: \(result.error ?? "")")
    /// }
    /// ```
    public func addPolicy(
        contextRuleId: UInt32,
        policyAddress: String,
        policyType: OZPolicyType
    ) async throws -> TransactionResult {
        // Validate wallet is connected
        let (_, contractId) = try kit.requireConnected()

        // Validate policy address (must be C-address)
        guard policyAddress.hasPrefix("C"), policyAddress.count == 56 else {
            throw SmartAccountError.invalidAddress("Policy address must be a valid C-address, got: \(policyAddress)")
        }

        // Build installation parameter based on policy type
        let installParam = try buildInstallParam(for: policyType)

        // Build contract invocation
        // Contract method: add_policy(context_rule_id: u32, policy_address: Address, install_param: ScVal)
        let hostFunction = HostFunctionXDR.invokeContract(InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "add_policy",
            args: [
                .u32(contextRuleId),
                .address(try SCAddressXDR(contractId: policyAddress)),
                installParam
            ]
        ))

        // Submit transaction
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Remove Policy

    /// Removes a policy from a context rule.
    ///
    /// Uninstalls an existing policy from the specified context rule. The policy
    /// contract remains deployed on the network but is no longer evaluated for
    /// this context rule.
    ///
    /// Flow:
    /// 1. Validates inputs (connected wallet, policy address format)
    /// 2. Builds contract invocation for remove_policy
    /// 3. Submits transaction via transactionOps (handles simulation, signing, polling)
    ///
    /// IMPORTANT: This operation requires the connected wallet to have authorization
    /// on the smart account. The user will be prompted for biometric authentication
    /// to sign the transaction.
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID to remove the policy from (0 for Default rule)
    ///   - policyAddress: The policy contract address to remove (C-address)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction submission fails
    ///
    /// Example:
    /// ```swift
    /// // Remove a policy from the default context rule
    /// let result = try await policyManager.removePolicy(
    ///     contextRuleId: 0,
    ///     policyAddress: "CBCD1234..."
    /// )
    ///
    /// if result.success {
    ///     print("Policy removed: \(result.hash ?? "")")
    /// } else {
    ///     print("Failed to remove policy: \(result.error ?? "")")
    /// }
    /// ```
    public func removePolicy(
        contextRuleId: UInt32,
        policyAddress: String
    ) async throws -> TransactionResult {
        // Validate wallet is connected
        let (_, contractId) = try kit.requireConnected()

        // Validate policy address (must be C-address)
        guard policyAddress.hasPrefix("C"), policyAddress.count == 56 else {
            throw SmartAccountError.invalidAddress("Policy address must be a valid C-address, got: \(policyAddress)")
        }

        // Build contract invocation
        // Contract method: remove_policy(context_rule_id: u32, policy_address: Address)
        let hostFunction = HostFunctionXDR.invokeContract(InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "remove_policy",
            args: [
                .u32(contextRuleId),
                .address(try SCAddressXDR(contractId: policyAddress))
            ]
        ))

        // Submit transaction
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Private Helpers

    /// Builds the installation parameter ScVal for a policy type.
    ///
    /// Encodes policy-specific configuration as an SCVal map with keys in
    /// ALPHABETICAL ORDER. This ordering is critical for contract compatibility.
    ///
    /// Map structures:
    /// - Simple Threshold: { "threshold": U32 }
    /// - Weighted Threshold: { "signer_weights": Map[Signer => U32], "threshold": U32 }
    /// - Spending Limit: { "period_ledgers": U32, "spending_limit": I128 }
    ///
    /// - Parameter policyType: The policy type with configuration
    /// - Returns: SCVal map with installation parameters
    /// - Throws: SmartAccountError if encoding fails
    private func buildInstallParam(for policyType: OZPolicyType) throws -> SCValXDR {
        switch policyType {
        case .simpleThreshold(let threshold):
            // Simple threshold: { "threshold": U32 }
            // Keys: ["threshold"] - already alphabetical
            let entries: [SCMapEntryXDR] = [
                SCMapEntryXDR(
                    key: .symbol("threshold"),
                    val: .u32(threshold)
                )
            ]
            return .map(entries)

        case .weightedThreshold(let signerWeights, let threshold):
            // Weighted threshold: { "signer_weights": Map, "threshold": U32 }
            // Keys: ["signer_weights", "threshold"] - alphabetically correct

            // Validate signer weights array
            guard !signerWeights.isEmpty else {
                throw SmartAccountError.invalidInput("Weighted threshold policy requires at least one signer with weight")
            }

            // Build signer weights map
            var signerWeightEntries: [SCMapEntryXDR] = []
            for (signer, weight) in signerWeights {
                let signerScVal = try signer.toScVal()
                signerWeightEntries.append(SCMapEntryXDR(
                    key: signerScVal,
                    val: .u32(weight)
                ))
            }

            let signerWeightsMap = SCValXDR.map(signerWeightEntries)

            // Build policy parameter map (alphabetical order)
            let entries: [SCMapEntryXDR] = [
                SCMapEntryXDR(
                    key: .symbol("signer_weights"),
                    val: signerWeightsMap
                ),
                SCMapEntryXDR(
                    key: .symbol("threshold"),
                    val: .u32(threshold)
                )
            ]
            return .map(entries)

        case .spendingLimit(let limit, let periodLedgers):
            // Spending limit: { "period_ledgers": U32, "spending_limit": I128 }
            // Keys: ["period_ledgers", "spending_limit"] - alphabetically correct

            // Validate inputs
            guard limit > 0 else {
                throw SmartAccountError.invalidAmount("Spending limit must be greater than zero, got: \(limit)")
            }

            guard periodLedgers > 0 else {
                throw SmartAccountError.invalidInput("Period ledgers must be greater than zero, got: \(periodLedgers)")
            }

            // Convert limit to I128 ScVal
            // For positive values within Int64 range: hi = 0, lo = UInt64(value)
            let limitI128 = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: UInt64(limit)))

            // Build policy parameter map (alphabetical order)
            let entries: [SCMapEntryXDR] = [
                SCMapEntryXDR(
                    key: .symbol("period_ledgers"),
                    val: .u32(periodLedgers)
                ),
                SCMapEntryXDR(
                    key: .symbol("spending_limit"),
                    val: limitI128
                )
            ]
            return .map(entries)
        }
    }
}
