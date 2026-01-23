//
//  OZSignerManager.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Manager for smart account signer operations.
///
/// OZSignerManager provides high-level operations for managing signers on a smart account.
/// It handles adding and removing different types of signers (passkeys, delegated accounts,
/// Ed25519 keys) to context rules, with automatic validation and transaction building.
///
/// Signer types supported:
/// - WebAuthn passkeys: secp256r1 signature verification via WebAuthn verifier contract
/// - Delegated signers: Stellar accounts or contracts using built-in require_auth verification
/// - Ed25519 signers: Traditional Ed25519 keys via Ed25519 verifier contract
///
/// Each context rule can have up to 15 signers. Signers are identified by their on-chain
/// representation (address for delegated, verifier+key for external).
///
/// Example usage:
/// ```swift
/// let kit = try OZSmartAccountKit(config: config)
/// let signerManager = OZSignerManager(kit: kit, transactionOps: txOps)
///
/// // Add a passkey signer to the Default context rule
/// let result = try await signerManager.addPasskey(
///     contextRuleId: 0,
///     verifierAddress: "CBCD1234...",
///     publicKey: secp256r1PublicKey,
///     credentialId: webAuthnCredentialId
/// )
/// print("Signer added: \(result.success)")
///
/// // Add a delegated account signer
/// let delegatedResult = try await signerManager.addDelegated(
///     contextRuleId: 0,
///     address: "GA7QYNF7..."
/// )
/// ```
///
/// Thread Safety:
/// This class is thread-safe. All operations are async and can be safely called from any thread.
public final class OZSignerManager: @unchecked Sendable {
    /// Reference to the parent SmartAccountKit instance.
    private let kit: OZSmartAccountKit

    /// Transaction operations for building and submitting transactions.
    private let transactionOps: OZTransactionOperations

    /// Creates a new OZSignerManager instance.
    ///
    /// - Parameters:
    ///   - kit: The parent OZSmartAccountKit instance
    ///   - transactionOps: Transaction operations for contract invocations
    internal init(kit: OZSmartAccountKit, transactionOps: OZTransactionOperations) {
        self.kit = kit
        self.transactionOps = transactionOps
    }

    // MARK: - Add Signers

    /// Adds a WebAuthn passkey signer to a context rule.
    ///
    /// Creates an external signer with WebAuthn verification and adds it to the specified
    /// context rule on the smart account contract. The public key must be an uncompressed
    /// secp256r1 key (65 bytes starting with 0x04), and the credential ID must be non-empty.
    ///
    /// The transaction requires authorization from an existing signer on the specified
    /// context rule. The user will be prompted for biometric authentication if the current
    /// passkey is the authorizing signer.
    ///
    /// Contract call: `smart_account.add_signer(context_rule_id, signer)`
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID to add the signer to (e.g., 0 for Default)
    ///   - verifierAddress: The WebAuthn verifier contract address (C-address)
    ///   - publicKey: The uncompressed secp256r1 public key (65 bytes, starting with 0x04)
    ///   - credentialId: The WebAuthn credential identifier
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction fails
    ///
    /// Example:
    /// ```swift
    /// let result = try await signerManager.addPasskey(
    ///     contextRuleId: 0,
    ///     verifierAddress: "CBCD1234...",
    ///     publicKey: secp256r1PublicKey,
    ///     credentialId: credentialIdData
    /// )
    ///
    /// if result.success {
    ///     print("Passkey signer added successfully")
    /// } else {
    ///     print("Failed to add signer: \(result.error ?? "")")
    /// }
    /// ```
    public func addPasskey(
        contextRuleId: UInt32,
        verifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) async throws -> TransactionResult {
        // Validate inputs
        _ = try kit.requireConnected()

        // Validate public key
        guard publicKey.count == SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE else {
            throw SmartAccountError.invalidInput(
                "Public key must be \(SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE) bytes, got: \(publicKey.count)"
            )
        }

        guard publicKey.first == SmartAccountConstants.UNCOMPRESSED_PUBKEY_PREFIX else {
            throw SmartAccountError.invalidInput(
                "Public key must start with 0x04 (uncompressed format), got: 0x\(String(format: "%02x", publicKey.first ?? 0))"
            )
        }

        guard !credentialId.isEmpty else {
            throw SmartAccountError.invalidInput("Credential ID cannot be empty")
        }

        // Build WebAuthn external signer
        let signer = try ExternalSigner.webAuthn(
            verifierAddress: verifierAddress,
            publicKey: publicKey,
            credentialId: credentialId
        )

        // Add signer via contract invocation
        return try await addSigner(contextRuleId: contextRuleId, signer: signer)
    }

    /// Adds a delegated signer to a context rule.
    ///
    /// Creates a delegated signer that uses built-in Soroban require_auth verification
    /// and adds it to the specified context rule. The address can be either a Stellar
    /// account (G-address) or a smart contract (C-address).
    ///
    /// Delegated signers authorize transactions using the native Soroban authorization
    /// mechanism, which calls `require_auth_for_args()` on the signer's address.
    ///
    /// The transaction requires authorization from an existing signer on the specified
    /// context rule.
    ///
    /// Contract call: `smart_account.add_signer(context_rule_id, signer)`
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID to add the signer to (e.g., 0 for Default)
    ///   - address: The Stellar address (G-address for accounts, C-address for contracts)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction fails
    ///
    /// Example:
    /// ```swift
    /// // Add an account signer
    /// let result = try await signerManager.addDelegated(
    ///     contextRuleId: 0,
    ///     address: "GA7QYNF7SOWQ..."
    /// )
    ///
    /// // Add a contract signer
    /// let contractResult = try await signerManager.addDelegated(
    ///     contextRuleId: 1,
    ///     address: "CBCD1234..."
    /// )
    /// ```
    public func addDelegated(
        contextRuleId: UInt32,
        address: String
    ) async throws -> TransactionResult {
        // Validate inputs
        _ = try kit.requireConnected()

        // Build delegated signer (validation happens in initializer)
        let signer = try DelegatedSigner(address: address)

        // Add signer via contract invocation
        return try await addSigner(contextRuleId: contextRuleId, signer: signer)
    }

    /// Adds an Ed25519 signer to a context rule.
    ///
    /// Creates an external signer with Ed25519 signature verification and adds it to the
    /// specified context rule on the smart account contract. The public key must be a
    /// 32-byte Ed25519 public key.
    ///
    /// Ed25519 signers use the traditional Stellar signing algorithm. The verifier contract
    /// validates signatures against the provided public key.
    ///
    /// The transaction requires authorization from an existing signer on the specified
    /// context rule.
    ///
    /// Contract call: `smart_account.add_signer(context_rule_id, signer)`
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID to add the signer to (e.g., 0 for Default)
    ///   - verifierAddress: The Ed25519 verifier contract address (C-address)
    ///   - publicKey: The Ed25519 public key (32 bytes)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction fails
    ///
    /// Example:
    /// ```swift
    /// let result = try await signerManager.addEd25519(
    ///     contextRuleId: 0,
    ///     verifierAddress: "CDEF5678...",
    ///     publicKey: ed25519PublicKey
    /// )
    ///
    /// if result.success {
    ///     print("Ed25519 signer added successfully")
    /// }
    /// ```
    public func addEd25519(
        contextRuleId: UInt32,
        verifierAddress: String,
        publicKey: Data
    ) async throws -> TransactionResult {
        // Validate inputs
        _ = try kit.requireConnected()

        // Build Ed25519 external signer (validation happens in factory method)
        let signer = try ExternalSigner.ed25519(
            verifierAddress: verifierAddress,
            publicKey: publicKey
        )

        // Add signer via contract invocation
        return try await addSigner(contextRuleId: contextRuleId, signer: signer)
    }

    // MARK: - Remove Signer

    /// Removes a signer from a context rule.
    ///
    /// Removes the specified signer from the given context rule on the smart account contract.
    /// The signer is identified by its on-chain representation (address for delegated signers,
    /// verifier+key for external signers).
    ///
    /// The transaction requires authorization from an existing signer on the specified
    /// context rule.
    ///
    /// IMPORTANT: You cannot remove the last signer from a context rule unless the rule
    /// has policies that provide authorization. The contract will throw error 3004
    /// if you attempt to remove the last signer with no policies configured.
    ///
    /// Contract call: `smart_account.remove_signer(context_rule_id, signer)`
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID to remove the signer from
    ///   - signer: The signer to remove (must match an existing signer exactly)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails or transaction fails
    ///
    /// Example:
    /// ```swift
    /// // Remove a delegated signer
    /// let delegatedSigner = try DelegatedSigner(address: "GA7QYNF7...")
    /// let result = try await signerManager.removeSigner(
    ///     contextRuleId: 0,
    ///     signer: delegatedSigner
    /// )
    ///
    /// // Remove a passkey signer
    /// let passkeySignerToRemove = try ExternalSigner.webAuthn(
    ///     verifierAddress: "CBCD1234...",
    ///     publicKey: publicKey,
    ///     credentialId: credentialId
    /// )
    /// let removeResult = try await signerManager.removeSigner(
    ///     contextRuleId: 0,
    ///     signer: passkeySignerToRemove
    /// )
    ///
    /// if !result.success {
    ///     print("Failed to remove signer: \(result.error ?? "")")
    /// }
    /// ```
    public func removeSigner(
        contextRuleId: UInt32,
        signer: SmartAccountSigner
    ) async throws -> TransactionResult {
        // Validate inputs
        let (_, contractId) = try kit.requireConnected()

        // Build contract invocation for remove_signer
        let signerScVal = try signer.toScVal()

        let functionArgs: [SCValXDR] = [
            .u32(contextRuleId),
            signerScVal
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "remove_signer",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Submit via transaction operations (handles simulation, signing, submission)
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Private Helpers

    /// Internal helper to add a signer to a context rule.
    ///
    /// Builds the contract invocation for add_signer and submits it via transaction operations.
    /// The submit method handles simulation, authorization entry signing, and transaction submission.
    ///
    /// - Parameters:
    ///   - contextRuleId: The context rule ID
    ///   - signer: The signer to add
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if the operation fails
    private func addSigner(
        contextRuleId: UInt32,
        signer: SmartAccountSigner
    ) async throws -> TransactionResult {
        let (_, contractId) = try kit.requireConnected()

        // Build contract invocation for add_signer
        let signerScVal = try signer.toScVal()

        let functionArgs: [SCValXDR] = [
            .u32(contextRuleId),
            signerScVal
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "add_signer",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // Submit via transaction operations (handles simulation, signing, submission)
        return try await transactionOps.submit(hostFunction: hostFunction, auth: [])
    }
}
