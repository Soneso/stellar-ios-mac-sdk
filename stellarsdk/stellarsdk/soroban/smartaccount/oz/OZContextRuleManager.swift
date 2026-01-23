//
//  OZContextRuleManager.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Type of context rule that determines which operations it applies to.
///
/// Context rules use pattern matching to determine when signers and policies should be enforced.
/// Three types of context matching are supported:
/// - Default: Matches any operation (fallback rule)
/// - CallContract: Matches invocations to a specific contract address
/// - CreateContract: Matches contract deployments using a specific WASM hash
///
/// Example usage:
/// ```swift
/// // Default rule applies to all operations
/// let defaultRule = OZContextRuleType.default
///
/// // Rule for calling a specific token contract
/// let tokenRule = OZContextRuleType.callContract("CBCD1234...")
///
/// // Rule for deploying contracts with a specific WASM hash
/// let deployRule = OZContextRuleType.createContract(wasmHashData)
/// ```
public enum OZContextRuleType: Sendable {
    /// Matches any operation (fallback/default rule).
    case `default`

    /// Matches invocations to a specific contract address.
    /// - Parameter: Contract address (C-address, 56 characters)
    case callContract(String)

    /// Matches contract deployments using a specific WASM hash.
    /// - Parameter: WASM hash (32 bytes)
    case createContract(Data)

    /// Converts the context rule type to its on-chain ScVal representation.
    ///
    /// The on-chain representation is:
    /// - Default: `ScVal::Vec([Symbol("Default")])`
    /// - CallContract: `ScVal::Vec([Symbol("CallContract"), Address(contractAddress)])`
    /// - CreateContract: `ScVal::Vec([Symbol("CreateContract"), Bytes(wasmHash)])`
    ///
    /// - Returns: The SCVal representation of this context rule type
    /// - Throws: SmartAccountError if address conversion fails
    ///
    /// Example:
    /// ```swift
    /// let ruleType = OZContextRuleType.callContract("CBCD1234...")
    /// let scVal = try ruleType.toScVal()
    /// // ScVal::Vec([Symbol("CallContract"), Address("CBCD1234...")])
    /// ```
    public func toScVal() throws -> SCValXDR {
        switch self {
        case .default:
            return .vec([.symbol("Default")])

        case .callContract(let address):
            let scAddress = try SCAddressXDR(contractId: address)
            return .vec([.symbol("CallContract"), .address(scAddress)])

        case .createContract(let wasmHash):
            return .vec([.symbol("CreateContract"), .bytes(wasmHash)])
        }
    }
}

/// Manages context rules for OpenZeppelin Smart Accounts.
///
/// Context rules define authorization requirements for different types of operations.
/// Each rule specifies:
/// - Context type: What operations does this rule apply to (default, call contract, create contract)
/// - Name: A human-readable identifier for the rule
/// - Signers: Who can authorize operations matching this context
/// - Policies: What constraints apply (spending limits, time locks, multi-sig thresholds, etc.)
/// - Valid until: Optional expiration ledger number
///
/// The smart account evaluates transactions against context rules to determine:
/// 1. Which signers are required to authorize the transaction
/// 2. Which policies must be satisfied for the transaction to execute
///
/// Contract limits:
/// - Maximum 15 context rules per smart account
/// - Maximum 15 signers per context rule
/// - Maximum 5 policies per context rule
///
/// Example usage:
/// ```swift
/// let contextMgr = OZContextRuleManager(kit: kit, transactionOps: txOps)
///
/// // Add a rule for token transfers requiring 2-of-3 multi-sig
/// let result = try await contextMgr.addContextRule(
///     contextType: .callContract(tokenContractAddress),
///     name: "TokenTransfers",
///     validUntil: nil,
///     signers: [signer1, signer2, signer3],
///     policies: [
///         (address: thresholdPolicyAddress, installParam: thresholdScVal)
///     ]
/// )
///
/// // Get all context rules
/// let rules = try await contextMgr.getContextRules(contextType: .default)
///
/// // Remove a context rule
/// let removeResult = try await contextMgr.removeContextRule(id: ruleId)
/// ```
public final class OZContextRuleManager: @unchecked Sendable {
    /// Reference to the parent SmartAccountKit instance.
    private let kit: OZSmartAccountKit

    /// Reference to transaction operations for submission.
    private let transactionOps: OZTransactionOperations

    /// Creates a new OZContextRuleManager instance.
    ///
    /// This initializer is internal and should not be called directly.
    /// Access the context rule manager through the SmartAccountKit instance.
    ///
    /// - Parameters:
    ///   - kit: The parent OZSmartAccountKit instance
    ///   - transactionOps: The transaction operations instance for submitting state-changing operations
    internal init(kit: OZSmartAccountKit, transactionOps: OZTransactionOperations) {
        self.kit = kit
        self.transactionOps = transactionOps
    }

    // MARK: - Add Context Rule

    /// Adds a new context rule to the smart account.
    ///
    /// Creates a context rule that defines authorization requirements for operations matching
    /// the specified context type. The rule includes signers who can authorize matching operations
    /// and policies that constrain how operations can be executed.
    ///
    /// Flow:
    /// 1. Validates inputs (name, signers count, policies count)
    /// 2. Checks that adding this rule won't exceed MAX_CONTEXT_RULES
    /// 3. Builds contract invocation for add_context_rule
    /// 4. Simulates to get auth entries
    /// 5. Signs auth entries (requires user interaction)
    /// 6. Submits transaction
    /// 7. Polls for confirmation
    ///
    /// Contract limits enforced:
    /// - Maximum 15 context rules per smart account (checked via getContextRulesCount)
    /// - Maximum 15 signers per context rule
    /// - Maximum 5 policies per context rule
    ///
    /// IMPORTANT: This is a state-changing operation requiring smart account authorization.
    /// The user will be prompted for biometric authentication.
    ///
    /// - Parameters:
    ///   - contextType: The type of context this rule applies to
    ///   - name: A human-readable name for the rule (e.g., "DefaultRule", "TokenTransfers")
    ///   - validUntil: Optional ledger number when this rule expires (nil = no expiration)
    ///   - signers: Array of signers who can authorize operations matching this context
    ///   - policies: Array of policy contract addresses and their installation parameters
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction submission fails
    ///
    /// Example:
    /// ```swift
    /// let result = try await contextMgr.addContextRule(
    ///     contextType: .callContract("CBCD1234..."),
    ///     name: "TokenOps",
    ///     validUntil: 12345678,
    ///     signers: [webAuthnSigner, delegatedSigner],
    ///     policies: [
    ///         (address: thresholdPolicyAddress, installParam: .u32(2)),
    ///         (address: spendingLimitPolicyAddress, installParam: limitScVal)
    ///     ]
    /// )
    /// if result.success {
    ///     print("Context rule added. Hash: \(result.hash ?? "")")
    /// }
    /// ```
    public func addContextRule(
        contextType: OZContextRuleType,
        name: String,
        validUntil: UInt32? = nil,
        signers: [SmartAccountSigner],
        policies: [(address: String, installParam: SCValXDR)]
    ) async throws -> TransactionResult {
        let (_, contractId) = try kit.requireConnected()

        // Validate inputs
        guard !name.isEmpty else {
            throw SmartAccountError.invalidInput("Context rule name cannot be empty")
        }

        guard signers.count > 0, signers.count <= SmartAccountConstants.MAX_SIGNERS else {
            throw SmartAccountError.invalidInput(
                "Context rule must have between 1 and \(SmartAccountConstants.MAX_SIGNERS) signers, got: \(signers.count)"
            )
        }

        guard policies.count <= SmartAccountConstants.MAX_POLICIES else {
            throw SmartAccountError.invalidInput(
                "Context rule cannot have more than \(SmartAccountConstants.MAX_POLICIES) policies, got: \(policies.count)"
            )
        }

        // Validate policy addresses
        for (address, _) in policies {
            guard address.hasPrefix("C"), address.count == 56 else {
                throw SmartAccountError.invalidAddress("Policy address must be a valid C-address, got: \(address)")
            }
        }

        // Check MAX_CONTEXT_RULES limit
        let currentCount = try await getContextRulesCount()
        guard currentCount < SmartAccountConstants.MAX_CONTEXT_RULES else {
            throw SmartAccountError.invalidInput(
                "Cannot add context rule: maximum of \(SmartAccountConstants.MAX_CONTEXT_RULES) rules already reached"
            )
        }

        // Build function arguments
        // arg 0: context_type (ScVal from contextType.toScVal())
        let contextTypeScVal = try contextType.toScVal()

        // arg 1: name (Symbol or String - using Symbol as it's typically shorter and more gas-efficient)
        let nameScVal = SCValXDR.symbol(name)

        // arg 2: valid_until (Option<u32> - represented as void for None, u32 for Some)
        let validUntilScVal: SCValXDR
        if let expiration = validUntil {
            validUntilScVal = .u32(expiration)
        } else {
            validUntilScVal = .void
        }

        // arg 3: signers (Vec<Signer>)
        var signersVec: [SCValXDR] = []
        for signer in signers {
            let signerScVal = try signer.toScVal()
            signersVec.append(signerScVal)
        }
        let signersScVal = SCValXDR.vec(signersVec)

        // arg 4: policies (Map<Address, ScVal> for policy address -> install param)
        var policiesMap: [SCMapEntryXDR] = []
        for (address, installParam) in policies {
            let policyAddress = try SCAddressXDR(contractId: address)
            let mapEntry = SCMapEntryXDR(
                key: .address(policyAddress),
                val: installParam
            )
            policiesMap.append(mapEntry)
        }
        let policiesScVal = SCValXDR.map(policiesMap)

        // Build invocation
        let functionArgs: [SCValXDR] = [
            contextTypeScVal,
            nameScVal,
            validUntilScVal,
            signersScVal,
            policiesScVal
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "add_context_rule",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Submit transaction (will handle simulation, signing, and polling)
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Get Context Rule

    /// Retrieves a specific context rule by its ID.
    ///
    /// Queries the smart account contract for a context rule with the specified ID.
    /// The raw SCVal response is returned, containing the rule details in encoded form.
    ///
    /// This is a query operation (read-only, no authorization required). It uses simulation
    /// to extract the return value without submitting a transaction.
    ///
    /// The returned ScVal structure contains:
    /// - id: u32
    /// - context_type: Vec[Symbol, ...] (Default | CallContract | CreateContract)
    /// - name: Symbol or String
    /// - signers: Vec[signer ScVals]
    /// - policies: Map[Address -> ScVal]
    /// - valid_until: Option<u32> (void for None, u32 for Some)
    ///
    /// NOTE: Parsing the full context rule from ScVal is complex due to nested structures.
    /// For initial implementation, this method returns the raw ScVal. Applications can
    /// extract specific fields as needed.
    ///
    /// - Parameter id: The context rule ID to retrieve
    /// - Returns: The raw SCVal response containing the context rule details
    /// - Throws: SmartAccountError if simulation fails or the rule doesn't exist
    ///
    /// Example:
    /// ```swift
    /// let ruleScVal = try await contextMgr.getContextRule(id: 1)
    /// // Parse ruleScVal to extract rule details
    /// ```
    public func getContextRule(id: UInt32) async throws -> SCValXDR {
        let (_, contractId) = try kit.requireConnected()

        // Build invocation
        let functionArgs: [SCValXDR] = [.u32(id)]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "get_context_rule",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Query operation - simulate to get return value
        return try await SmartAccountSharedUtils.simulateAndExtractResult(hostFunction: hostFunction, kit: kit)
    }

    // MARK: - Get Context Rules

    /// Retrieves all context rules matching the specified context type.
    ///
    /// Queries the smart account contract for all context rules that match the given
    /// context type pattern. The raw SCVal response is returned, containing an array
    /// of rule details.
    ///
    /// This is a query operation (read-only, no authorization required). It uses simulation
    /// to extract the return value without submitting a transaction.
    ///
    /// The returned ScVal is a Vec containing multiple context rule structures.
    ///
    /// NOTE: Parsing the full context rules list from ScVal is complex. For initial
    /// implementation, this method returns the raw ScVal. Applications can extract
    /// specific fields as needed.
    ///
    /// - Parameter contextType: The context type to filter by
    /// - Returns: The raw SCVal response containing the array of matching context rules
    /// - Throws: SmartAccountError if simulation fails
    ///
    /// Example:
    /// ```swift
    /// // Get all default rules
    /// let defaultRules = try await contextMgr.getContextRules(
    ///     contextType: .default
    /// )
    ///
    /// // Get all rules for a specific contract
    /// let tokenRules = try await contextMgr.getContextRules(
    ///     contextType: .callContract("CBCD1234...")
    /// )
    /// ```
    public func getContextRules(contextType: OZContextRuleType) async throws -> SCValXDR {
        let (_, contractId) = try kit.requireConnected()

        // Build invocation
        let contextTypeScVal = try contextType.toScVal()
        let functionArgs: [SCValXDR] = [contextTypeScVal]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "get_context_rules",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Query operation - simulate to get return value
        return try await SmartAccountSharedUtils.simulateAndExtractResult(hostFunction: hostFunction, kit: kit)
    }

    // MARK: - Get Context Rules Count

    /// Retrieves the total number of context rules in the smart account.
    ///
    /// Queries the smart account contract to determine how many context rules are
    /// currently configured. This is useful for checking whether adding a new rule
    /// would exceed the MAX_CONTEXT_RULES limit.
    ///
    /// This is a query operation (read-only, no authorization required). It uses simulation
    /// to extract the return value without submitting a transaction.
    ///
    /// - Returns: The number of context rules currently configured
    /// - Throws: SmartAccountError if simulation fails or parsing fails
    ///
    /// Example:
    /// ```swift
    /// let count = try await contextMgr.getContextRulesCount()
    /// print("Smart account has \(count) context rules")
    ///
    /// if count < SmartAccountConstants.MAX_CONTEXT_RULES {
    ///     // Can add more rules
    /// }
    /// ```
    public func getContextRulesCount() async throws -> UInt32 {
        let (_, contractId) = try kit.requireConnected()

        // Build invocation (no arguments)
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "get_context_rules_count",
            args: []
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Query operation - simulate to get return value
        let resultScVal = try await SmartAccountSharedUtils.simulateAndExtractResult(hostFunction: hostFunction, kit: kit)

        // Parse U32 result
        guard let count = resultScVal.u32 else {
            throw SmartAccountError.invalidInput(
                "Expected U32 result from get_context_rules_count, got: \(resultScVal)"
            )
        }

        return count
    }

    // MARK: - Remove Context Rule

    /// Removes a context rule from the smart account.
    ///
    /// Deletes the context rule with the specified ID from the smart account. Once removed,
    /// the rule will no longer apply to future transactions.
    ///
    /// Flow:
    /// 1. Validates that a wallet is connected
    /// 2. Builds contract invocation for remove_context_rule
    /// 3. Simulates to get auth entries
    /// 4. Signs auth entries (requires user interaction)
    /// 5. Submits transaction
    /// 6. Polls for confirmation
    ///
    /// IMPORTANT: This is a state-changing operation requiring smart account authorization.
    /// The user will be prompted for biometric authentication.
    ///
    /// - Parameter id: The ID of the context rule to remove
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if the rule doesn't exist or transaction submission fails
    ///
    /// Example:
    /// ```swift
    /// let result = try await contextMgr.removeContextRule(id: 3)
    /// if result.success {
    ///     print("Context rule removed. Hash: \(result.hash ?? "")")
    /// }
    /// ```
    public func removeContextRule(id: UInt32) async throws -> TransactionResult {
        let (_, contractId) = try kit.requireConnected()

        // Build invocation
        let functionArgs: [SCValXDR] = [.u32(id)]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "remove_context_rule",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Submit transaction (will handle simulation, signing, and polling)
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Update Context Rule Name

    /// Updates the name of an existing context rule.
    ///
    /// Changes the human-readable name of the context rule with the specified ID.
    /// The name is used for identification and has no effect on rule matching or enforcement.
    ///
    /// Flow:
    /// 1. Validates inputs (name not empty)
    /// 2. Builds contract invocation for update_context_rule_name
    /// 3. Simulates to get auth entries
    /// 4. Signs auth entries (requires user interaction)
    /// 5. Submits transaction
    /// 6. Polls for confirmation
    ///
    /// IMPORTANT: This is a state-changing operation requiring smart account authorization.
    /// The user will be prompted for biometric authentication.
    ///
    /// - Parameters:
    ///   - id: The ID of the context rule to update
    ///   - name: The new name for the context rule
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction submission fails
    ///
    /// Example:
    /// ```swift
    /// let result = try await contextMgr.updateContextRuleName(
    ///     id: 2,
    ///     name: "UpdatedTokenOps"
    /// )
    /// if result.success {
    ///     print("Context rule name updated. Hash: \(result.hash ?? "")")
    /// }
    /// ```
    public func updateContextRuleName(id: UInt32, name: String) async throws -> TransactionResult {
        let (_, contractId) = try kit.requireConnected()

        // Validate input
        guard !name.isEmpty else {
            throw SmartAccountError.invalidInput("Context rule name cannot be empty")
        }

        // Build invocation
        let functionArgs: [SCValXDR] = [
            .u32(id),
            .symbol(name)
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "update_context_rule_name",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Submit transaction (will handle simulation, signing, and polling)
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Update Context Rule Valid Until

    /// Updates the expiration ledger of an existing context rule.
    ///
    /// Changes the ledger number at which the context rule expires. After expiration,
    /// the rule will no longer apply to transactions. Pass nil to remove the expiration.
    ///
    /// Flow:
    /// 1. Builds contract invocation for update_context_rule_valid_until
    /// 2. Simulates to get auth entries
    /// 3. Signs auth entries (requires user interaction)
    /// 4. Submits transaction
    /// 5. Polls for confirmation
    ///
    /// IMPORTANT: This is a state-changing operation requiring smart account authorization.
    /// The user will be prompted for biometric authentication.
    ///
    /// - Parameters:
    ///   - id: The ID of the context rule to update
    ///   - validUntil: The new expiration ledger number, or nil for no expiration
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if transaction submission fails
    ///
    /// Example:
    /// ```swift
    /// // Set expiration to ledger 12345678
    /// let result = try await contextMgr.updateContextRuleValidUntil(
    ///     id: 2,
    ///     validUntil: 12345678
    /// )
    ///
    /// // Remove expiration (rule never expires)
    /// let result2 = try await contextMgr.updateContextRuleValidUntil(
    ///     id: 2,
    ///     validUntil: nil
    /// )
    /// ```
    public func updateContextRuleValidUntil(id: UInt32, validUntil: UInt32?) async throws -> TransactionResult {
        let (_, contractId) = try kit.requireConnected()

        // Build valid_until ScVal (Option<u32>)
        let validUntilScVal: SCValXDR
        if let expiration = validUntil {
            validUntilScVal = .u32(expiration)
        } else {
            validUntilScVal = .void
        }

        // Build invocation
        let functionArgs: [SCValXDR] = [
            .u32(id),
            validUntilScVal
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "update_context_rule_valid_until",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Submit transaction (will handle simulation, signing, and polling)
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

}
