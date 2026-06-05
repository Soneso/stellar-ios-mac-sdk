//
//  OZBuilders.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// OZContextRuleType
// ============================================================================

/// Type of context rule that determines which operations it applies to.
///
/// Context rules use pattern matching to determine when signers and policies
/// should be enforced. Three types of context matching are supported:
/// - Default: Matches any operation (fallback rule)
/// - CallContract: Matches invocations to a specific contract address
/// - CreateContract: Matches contract deployments using a specific WASM hash
///
/// Example:
/// ```swift
/// // Default rule applies to all operations
/// let defaultRule = OZContextRuleType.defaultRule
///
/// // Rule for calling a specific token contract
/// let tokenRule = OZContextRuleType.callContract(contractAddress: "CBCD1234...")
///
/// // Rule for deploying contracts with a specific WASM hash
/// let deployRule = OZContextRuleType.createContract(wasmHash: wasmHashData)
/// ```
public enum OZContextRuleType: Sendable, Hashable {

    /// Matches any operation (fallback / default rule).
    case defaultRule

    /// Matches invocations to a specific contract address (`C…`, 56 characters).
    case callContract(contractAddress: String)

    /// Matches contract deployments using a specific 32-byte WASM hash.
    case createContract(wasmHash: Data)

    // why: `wasmHash` uses constant-time comparison via `Data.constantTimeEquals`;
    // see that extension for the timing-attack rationale.
    public static func == (lhs: OZContextRuleType, rhs: OZContextRuleType) -> Bool {
        switch (lhs, rhs) {
        case (.defaultRule, .defaultRule):
            return true
        case let (.callContract(a), .callContract(b)):
            return a == b
        case let (.createContract(a), .createContract(b)):
            return a.constantTimeEquals(b)
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .defaultRule:
            hasher.combine(0)
        case .callContract(let address):
            hasher.combine(1)
            hasher.combine(address)
        case .createContract(let wasmHash):
            hasher.combine(2)
            hasher.combine(wasmHash)
        }
    }

    /// Converts the context rule type to its on-chain `SCValXDR` representation.
    ///
    /// The on-chain representation is:
    /// - Default: `SCValXDR.vec([Symbol("Default")])`
    /// - CallContract: `SCValXDR.vec([Symbol("CallContract"), Address(contractAddress)])`
    /// - CreateContract: `SCValXDR.vec([Symbol("CreateContract"), Bytes(wasmHash)])`
    ///
    /// - Returns: The `SCValXDR` representation of this context rule type.
    /// - Throws: ``SmartAccountValidationException/InvalidAddress`` when the call-contract
    ///   address cannot be converted to an `SCAddressXDR`.
    public func toScVal() throws -> SCValXDR {
        switch self {
        case .defaultRule:
            return .vec([.symbol("Default")])
        case .callContract(let contractAddress):
            do {
                let scAddress = try SCAddressXDR(contractId: contractAddress)
                return .vec([
                    .symbol("CallContract"),
                    .address(scAddress)
                ])
            } catch {
                throw SmartAccountValidationException.invalidAddress(address: contractAddress, cause: error)
            }
        case .createContract(let wasmHash):
            return .vec([
                .symbol("CreateContract"),
                .bytes(wasmHash)
            ])
        }
    }
}

// ============================================================================
// OZParsedContextRule
// ============================================================================

/// Parsed representation of a context rule sourced from on-chain data.
///
/// Carries every field describing a context rule: identifier, type, signers,
/// policies, and optional expiration. Constructed by the on-chain context-rule
/// parser; consumed by ``OZBuilders/collectUniqueSignersFromRules(rules:)`` and
/// by higher-level managers that decide which signers and policies apply to an
/// operation.
public struct OZParsedContextRule: Sendable, Hashable {

    /// Unique identifier of this context rule.
    public let id: UInt32

    /// Type of operations this rule applies to.
    public let contextType: OZContextRuleType

    /// Human-readable name for the rule.
    public let name: String

    /// Signers who can authorize operations matching this context.
    public let signers: [any OZSmartAccountSigner]

    /// Positionally-aligned signer IDs corresponding to ``signers``.
    public let signerIds: [UInt32]

    /// Policy contract addresses that constrain operations matching this rule.
    public let policies: [String]

    /// Positionally-aligned policy IDs corresponding to ``policies``.
    public let policyIds: [UInt32]

    /// Optional ledger number when this rule expires (`nil` = never expires).
    public let validUntil: UInt32?

    public init(
        id: UInt32,
        contextType: OZContextRuleType,
        name: String,
        signers: [any OZSmartAccountSigner],
        signerIds: [UInt32],
        policies: [String],
        policyIds: [UInt32],
        validUntil: UInt32?
    ) {
        self.id = id
        self.contextType = contextType
        self.name = name
        self.signers = signers
        self.signerIds = signerIds
        self.policies = policies
        self.policyIds = policyIds
        self.validUntil = validUntil
    }

    public static func == (lhs: OZParsedContextRule, rhs: OZParsedContextRule) -> Bool {
        guard lhs.id == rhs.id,
              lhs.contextType == rhs.contextType,
              lhs.name == rhs.name,
              lhs.signerIds == rhs.signerIds,
              lhs.policies == rhs.policies,
              lhs.policyIds == rhs.policyIds,
              lhs.validUntil == rhs.validUntil,
              lhs.signers.count == rhs.signers.count else {
            return false
        }
        for (a, b) in zip(lhs.signers, rhs.signers) where a.uniqueKey != b.uniqueKey {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(contextType)
        hasher.combine(name)
        for signer in signers {
            hasher.combine(signer.uniqueKey)
        }
        hasher.combine(signerIds)
        hasher.combine(policies)
        hasher.combine(policyIds)
        hasher.combine(validUntil)
    }
}

// ============================================================================
// OZBuilders namespace
// ============================================================================

/// Builder utilities for OpenZeppelin smart account context rules.
///
/// Provides type-safe constructors and display utilities for ``OZContextRuleType``
/// and related OZ-specific operations. These functions are separated from
/// ``OZSmartAccountBuilders`` to avoid a circular dependency between core and OZ
/// types.
///
/// `OZBuilders` is a caseless enum used as a namespace; it cannot be
/// instantiated.
public enum OZBuilders {

    // MARK: - Context Rule Type Builders

    /// Creates a default context rule type.
    ///
    /// Default rules apply to any operation that does not match a more specific
    /// `callContract` or `createContract` rule.
    ///
    /// - Returns: ``OZContextRuleType/defaultRule`` for default authorization.
    public static func createDefaultContextType() -> OZContextRuleType {
        return .defaultRule
    }

    /// Creates a call-contract context rule type.
    ///
    /// Call-contract rules apply only when invoking a specific contract. Useful
    /// for restricting signers to specific dApps or operations.
    ///
    /// - Parameter contractAddress: Contract address this rule applies to (`C…`).
    /// - Returns: An ``OZContextRuleType/callContract(contractAddress:)`` configured
    ///   for the supplied contract.
    /// - Throws: ``SmartAccountValidationException/InvalidAddress`` if the contract address
    ///   format is invalid.
    public static func createCallContractContextType(contractAddress: String) throws -> OZContextRuleType {
        try requireContractAddress(contractAddress, fieldName: "contractAddress")
        return .callContract(contractAddress: contractAddress)
    }

    /// Creates a create-contract context rule type from a hex-encoded WASM hash.
    ///
    /// Create-contract rules apply only when deploying contracts with a specific
    /// WASM hash.
    ///
    /// - Parameter wasmHashHex: WASM hash as a 64-character hex string (an
    ///   optional `0x` prefix is accepted and stripped).
    /// - Returns: An ``OZContextRuleType/createContract(wasmHash:)`` for the
    ///   supplied hash.
    /// - Throws: ``SmartAccountValidationException/InvalidInput`` when the hex string is not
    ///   exactly 64 characters after stripping any `0x` prefix or when it
    ///   contains non-hex characters.
    public static func createCreateContractContextType(wasmHashHex: String) throws -> OZContextRuleType {
        let cleanHash: String
        if wasmHashHex.hasPrefix("0x") {
            cleanHash = String(wasmHashHex.dropFirst(2))
        } else {
            cleanHash = wasmHashHex
        }
        if cleanHash.count != 64 {
            throw SmartAccountValidationException.invalidInput(
                field: "wasmHash",
                reason: "WASM hash must be 32 bytes (64 hex characters), got: \(cleanHash.count) characters"
            )
        }
        let hashBytes: Data
        do {
            hashBytes = try Data(base16Encoded: cleanHash)
        } catch {
            throw SmartAccountValidationException.invalidInput(
                field: "wasmHash",
                reason: "WASM hash hex string must contain only hex characters",
                cause: error
            )
        }
        return .createContract(wasmHash: hashBytes)
    }

    /// Creates a create-contract context rule type from raw WASM hash bytes.
    ///
    /// Create-contract rules apply only when deploying contracts with a specific
    /// WASM hash.
    ///
    /// - Parameter wasmHash: 32-byte WASM hash.
    /// - Returns: An ``OZContextRuleType/createContract(wasmHash:)`` for the
    ///   supplied hash.
    /// - Throws: ``SmartAccountValidationException/InvalidInput`` when `wasmHash` is not
    ///   exactly 32 bytes.
    public static func createCreateContractContextType(wasmHash: Data) throws -> OZContextRuleType {
        if wasmHash.count != 32 {
            throw SmartAccountValidationException.invalidInput(
                field: "wasmHash",
                reason: "WASM hash must be 32 bytes, got: \(wasmHash.count)"
            )
        }
        return .createContract(wasmHash: wasmHash)
    }

    // MARK: - Signer Inspection Utilities

    /// Collects unique signers across a list of parsed context rules.
    ///
    /// Iterates through the supplied rules, gathers each rule's signers, and
    /// returns a deduplicated list preserving the first occurrence of each
    /// signer. Deduplication uses ``OZSmartAccountSigner/uniqueKey`` and shares
    /// the implementation with ``OZSmartAccountBuilders/collectUniqueSigners(signers:)``.
    ///
    /// - Parameter rules: The parsed context rules to scan.
    /// - Returns: Unique signers across all rules, in first-occurrence order.
    public static func collectUniqueSignersFromRules(
        rules: [OZParsedContextRule]
    ) -> [any OZSmartAccountSigner] {
        let allSigners = rules.flatMap { $0.signers }
        return OZSmartAccountBuilders.collectUniqueSigners(signers: allSigners)
    }
}
