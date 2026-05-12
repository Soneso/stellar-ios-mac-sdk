//
//  OZBuilders.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// ContextRuleType
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
/// let defaultRule = ContextRuleType.defaultRule
///
/// // Rule for calling a specific token contract
/// let tokenRule = ContextRuleType.callContract(contractAddress: "CBCD1234...")
///
/// // Rule for deploying contracts with a specific WASM hash
/// let deployRule = ContextRuleType.createContract(wasmHash: wasmHashData)
/// ```
public enum ContextRuleType: Sendable, Hashable {

    /// Matches any operation (fallback / default rule).
    case defaultRule

    /// Matches invocations to a specific contract address (`C…`, 56 characters).
    case callContract(contractAddress: String)

    /// Matches contract deployments using a specific 32-byte WASM hash.
    case createContract(wasmHash: Data)

    // why: hand-written `==` keeps the byte comparison on `wasmHash` in
    // constant time. Swift's auto-synthesized `Equatable` for `Data` is a fast
    // length-then-memcmp short-circuit that leaks information about how many
    // leading bytes match through measurable timing differences.
    public static func == (lhs: ContextRuleType, rhs: ContextRuleType) -> Bool {
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

    // why: combine only the discriminant and length-aware content hash for
    // `wasmHash` so the hash output of two equal `CreateContract` arms is
    // identical (mirroring the constant-time equality contract above).
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
    /// - Throws: ``ValidationException/InvalidAddress`` when the call-contract
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
                throw ValidationException.invalidAddress(address: contractAddress, cause: error)
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
// ParsedContextRule
// ============================================================================

/// Parsed representation of a context rule sourced from on-chain data.
///
/// Carries every field describing a context rule: identifier, type, signers,
/// policies, and optional expiration. Constructed by the on-chain context-rule
/// parser; consumed by ``OZBuilders/collectUniqueSignersFromRules(rules:)`` and
/// by higher-level managers that decide which signers and policies apply to an
/// operation.
public struct ParsedContextRule: Sendable, Hashable {

    /// Unique identifier of this context rule.
    public let id: UInt32

    /// Type of operations this rule applies to.
    public let contextType: ContextRuleType

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

    /// Initializes a new ``ParsedContextRule`` from already-parsed on-chain data.
    ///
    /// - Parameters:
    ///   - id: Unique rule identifier.
    ///   - contextType: Operation-matching type.
    ///   - name: Human-readable rule name.
    ///   - signers: Signers authorized by this rule.
    ///   - signerIds: Positionally-aligned signer IDs.
    ///   - policies: Policy contract addresses applied by this rule.
    ///   - policyIds: Positionally-aligned policy IDs.
    ///   - validUntil: Optional expiration ledger number.
    public init(
        id: UInt32,
        contextType: ContextRuleType,
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

    public static func == (lhs: ParsedContextRule, rhs: ParsedContextRule) -> Bool {
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
/// Provides type-safe constructors and display utilities for ``ContextRuleType``
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
    /// - Returns: ``ContextRuleType/defaultRule`` for default authorization.
    public static func createDefaultContext() -> ContextRuleType {
        return .defaultRule
    }

    /// Creates a call-contract context rule type.
    ///
    /// Call-contract rules apply only when invoking a specific contract. Useful
    /// for restricting signers to specific dApps or operations.
    ///
    /// - Parameter contractAddress: Contract address this rule applies to (`C…`).
    /// - Returns: A ``ContextRuleType/callContract(contractAddress:)`` configured
    ///   for the supplied contract.
    /// - Throws: ``ValidationException/InvalidAddress`` if the contract address
    ///   format is invalid.
    public static func createCallContractContext(contractAddress: String) throws -> ContextRuleType {
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
    /// - Returns: A ``ContextRuleType/createContract(wasmHash:)`` for the
    ///   supplied hash.
    /// - Throws: ``ValidationException/InvalidInput`` when the hex string is not
    ///   exactly 64 characters after stripping any `0x` prefix or when it
    ///   contains non-hex characters.
    public static func createCreateContractContext(wasmHashHex: String) throws -> ContextRuleType {
        let cleanHash: String
        if wasmHashHex.hasPrefix("0x") {
            cleanHash = String(wasmHashHex.dropFirst(2))
        } else {
            cleanHash = wasmHashHex
        }
        if cleanHash.count != 64 {
            throw ValidationException.invalidInput(
                field: "wasmHash",
                reason: "WASM hash must be 32 bytes (64 hex characters), got: \(cleanHash.count) characters"
            )
        }
        let hashBytes: Data
        do {
            hashBytes = try Data(base16Encoded: cleanHash)
        } catch {
            throw ValidationException.invalidInput(
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
    /// - Returns: A ``ContextRuleType/createContract(wasmHash:)`` for the
    ///   supplied hash.
    /// - Throws: ``ValidationException/InvalidInput`` when `wasmHash` is not
    ///   exactly 32 bytes.
    public static func createCreateContractContext(wasmHash: Data) throws -> ContextRuleType {
        if wasmHash.count != 32 {
            throw ValidationException.invalidInput(
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
        rules: [ParsedContextRule]
    ) -> [any OZSmartAccountSigner] {
        let allSigners = rules.flatMap { $0.signers }
        return OZSmartAccountBuilders.collectUniqueSigners(signers: allSigners)
    }
}
