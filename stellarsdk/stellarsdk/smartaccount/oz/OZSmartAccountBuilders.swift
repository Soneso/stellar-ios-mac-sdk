//
//  OZSmartAccountBuilders.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Builder utilities for OpenZeppelin smart-account signers and policy parameters.
///
/// Provides type-safe constructors for creating signers and inspection helpers used by the
/// higher-level smart-account managers, plus constructors for policy parameter structs used
/// when installing policies on an OpenZeppelin Smart Account context rule. Includes:
/// - Signer builders for delegated, external, WebAuthn, and Ed25519 signers.
/// - Signer inspection (type checks, type description, credential and address extraction).
/// - Signer matching (by credential ID, by address, equality).
/// - Signer deduplication.
/// - Policy builders for simple threshold, weighted threshold, and spending limit policies.
public enum OZSmartAccountBuilders {

    // ========================================================================
    // Signer builders
    // ========================================================================

    /// Creates a delegated signer for a native Stellar account.
    ///
    /// Delegated signers use Stellar's native `require_auth()` mechanism; no external
    /// verifier contract is needed.
    ///
    /// - Parameter publicKey: Stellar account or contract address (`G…` or `C…` strkey).
    /// - Returns: An `OZDelegatedSigner` for use in context rules.
    /// - Throws: `ValidationException.InvalidAddress` when `publicKey` is not a valid strkey.
    public static func createDelegatedSigner(publicKey: String) throws -> OZDelegatedSigner {
        return try OZDelegatedSigner(address: publicKey)
    }

    /// Creates an external signer that delegates verification to a custom contract.
    ///
    /// Used for WebAuthn passkeys, Ed25519 with custom logic, and other non-native schemes.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the signature verifier.
    ///   - keyData: Public-key bytes plus any auxiliary authentication data; must not be empty.
    /// - Returns: An `OZExternalSigner` for use in context rules.
    /// - Throws: `ValidationException.InvalidAddress` when `verifierAddress` is not valid;
    ///           `ValidationException.InvalidInput` when `keyData` is empty.
    public static func createExternalSigner(
        verifierAddress: String,
        keyData: Data
    ) throws -> OZExternalSigner {
        return try OZExternalSigner(verifierAddress: verifierAddress, keyData: keyData)
    }

    /// Creates a WebAuthn passkey signer.
    ///
    /// Convenience wrapper around `createExternalSigner` that handles the `keyData` format
    /// for WebAuthn (`publicKey || credentialId`).
    ///
    /// - Parameters:
    ///   - webauthnVerifierAddress: WebAuthn verifier contract address (`C…` strkey).
    ///   - publicKey: 65-byte secp256r1 uncompressed public key (`0x04` prefix + X + Y).
    ///   - credentialId: WebAuthn credential identifier bytes; must not be empty.
    /// - Returns: An `OZExternalSigner` configured for WebAuthn verification.
    /// - Throws: `ValidationException.InvalidAddress` when the verifier address is invalid;
    ///           `ValidationException.InvalidInput` when the public key size or shape is
    ///           wrong, or when the credential ID is empty.
    public static func createWebAuthnSigner(
        webauthnVerifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) throws -> OZExternalSigner {
        return try OZExternalSigner.webAuthn(
            verifierAddress: webauthnVerifierAddress,
            publicKey: publicKey,
            credentialId: credentialId
        )
    }

    /// Creates an Ed25519 signer that delegates verification to a custom contract.
    ///
    /// The key data is the 32-byte Ed25519 public key.
    ///
    /// - Parameters:
    ///   - ed25519VerifierAddress: Ed25519 verifier contract address (`C…` strkey).
    ///   - publicKey: 32-byte Ed25519 public key.
    /// - Returns: An `OZExternalSigner` configured for Ed25519 verification.
    /// - Throws: `ValidationException.InvalidAddress` when the verifier address is invalid;
    ///           `ValidationException.InvalidInput` when the public key is not 32 bytes.
    public static func createEd25519Signer(
        ed25519VerifierAddress: String,
        publicKey: Data
    ) throws -> OZExternalSigner {
        return try OZExternalSigner.ed25519(
            verifierAddress: ed25519VerifierAddress,
            publicKey: publicKey
        )
    }

    // ========================================================================
    // Signer inspection utilities
    // ========================================================================

    /// Extracts the credential ID from a WebAuthn signer's key data.
    ///
    /// WebAuthn signers store key data as: 65-byte uncompressed public key followed by the
    /// credential ID. Returns `nil` for non-WebAuthn signers (delegated signers, or
    /// external signers whose key data is not longer than 65 bytes).
    ///
    /// - Parameter signer: Signer to inspect.
    /// - Returns: Credential ID bytes, or `nil` for non-WebAuthn signers.
    public static func getCredentialIdFromSigner(signer: any OZSmartAccountSigner) -> Data? {
        guard let external = signer as? OZExternalSigner else { return nil }
        if external.keyData.count <= SmartAccountConstants.secp256r1PublicKeySize {
            return nil
        }
        let suffix = external.keyData.suffix(
            external.keyData.count - SmartAccountConstants.secp256r1PublicKeySize
        )
        return Data(suffix)
    }

    /// Returns the WebAuthn credential ID as a Base64URL-encoded string, or `nil` for
    /// non-WebAuthn signers.
    ///
    /// - Parameter signer: Signer to inspect.
    /// - Returns: Base64URL-encoded credential ID string, or `nil`.
    public static func getCredentialIdStringFromSigner(signer: any OZSmartAccountSigner) -> String? {
        guard let credentialId = getCredentialIdFromSigner(signer: signer) else { return nil }
        return credentialId.base64URLEncodedString()
    }

    /// Returns `true` when `signer` is an `OZDelegatedSigner`.
    public static func isDelegatedSigner(signer: any OZSmartAccountSigner) -> Bool {
        return signer is OZDelegatedSigner
    }

    /// Returns `true` when `signer` is an `OZExternalSigner`.
    public static func isExternalSigner(signer: any OZSmartAccountSigner) -> Bool {
        return signer is OZExternalSigner
    }

    /// Returns a human-readable description of the signer type.
    ///
    /// - Parameter signer: Signer to describe.
    /// - Returns: One of `"Stellar Account"`, `"Passkey (WebAuthn)"`, `"Ed25519"`, or
    ///            `"External Verifier"`.
    public static func describeSignerType(signer: any OZSmartAccountSigner) -> String {
        if signer is OZDelegatedSigner {
            return "Stellar Account"
        }
        guard let external = signer as? OZExternalSigner else {
            return "External Verifier"
        }
        if external.keyData.count > SmartAccountConstants.secp256r1PublicKeySize {
            return "Passkey (WebAuthn)"
        }
        if external.keyData.count == SmartAccountConstants.ed25519PublicKeySize {
            return "Ed25519"
        }
        return "External Verifier"
    }

    // ========================================================================
    // Signer matching
    // ========================================================================

    /// Returns `true` when `signer` is a WebAuthn signer whose credential ID matches the
    /// given raw `credentialId` bytes.
    public static func signerMatchesCredential(
        signer: any OZSmartAccountSigner,
        credentialId: Data
    ) -> Bool {
        guard let signerCredId = getCredentialIdFromSigner(signer: signer) else { return false }
        return signerCredId == credentialId
    }

    /// Returns `true` when `signer` is a WebAuthn signer whose credential ID, encoded as
    /// Base64URL, equals `credentialId`.
    public static func signerMatchesCredentialId(
        signer: any OZSmartAccountSigner,
        credentialId: String
    ) -> Bool {
        guard let signerCredId = getCredentialIdStringFromSigner(signer: signer) else {
            return false
        }
        return signerCredId == credentialId
    }

    /// Returns `true` when `signer` is an `OZDelegatedSigner` whose address equals `address`.
    public static func signerMatchesAddress(
        signer: any OZSmartAccountSigner,
        address: String
    ) -> Bool {
        guard let delegated = signer as? OZDelegatedSigner else { return false }
        return delegated.address == address
    }

    // ========================================================================
    // Signer comparison and deduplication
    // ========================================================================

    /// Compares two signers by type and field values.
    ///
    /// For delegated signers compares the address. For external signers compares the
    /// verifier address and the byte content of the key data.
    public static func signersEqual(
        _ a: any OZSmartAccountSigner,
        _ b: any OZSmartAccountSigner
    ) -> Bool {
        if let lhs = a as? OZDelegatedSigner, let rhs = b as? OZDelegatedSigner {
            return lhs.address == rhs.address
        }
        if let lhs = a as? OZExternalSigner, let rhs = b as? OZExternalSigner {
            if lhs.verifierAddress != rhs.verifierAddress { return false }
            return lhs.keyData == rhs.keyData
        }
        return false
    }

    /// Returns the unique-key string for `signer`. Equivalent to `signer.uniqueKey`.
    public static func getSignerKey(signer: any OZSmartAccountSigner) -> String {
        return signer.uniqueKey
    }

    /// Returns a list of unique signers preserving the first occurrence of each duplicate.
    ///
    /// Uses `getSignerKey` to determine uniqueness; subsequent duplicates are discarded.
    ///
    /// - Parameter signers: Source list (may contain duplicates).
    /// - Returns: List of unique signers in insertion order.
    public static func collectUniqueSigners(
        signers: [any OZSmartAccountSigner]
    ) -> [any OZSmartAccountSigner] {
        var seen = Set<String>()
        var result: [any OZSmartAccountSigner] = []
        for signer in signers {
            let key = getSignerKey(signer: signer)
            if seen.insert(key).inserted {
                result.append(signer)
            }
        }
        return result
    }

    // ========================================================================
    // Policy parameter builders
    // ========================================================================

    /// Creates simple threshold policy parameters.
    ///
    /// Simple threshold requires at least `threshold` of the signers on the context rule
    /// to provide valid signatures.
    ///
    /// - Parameter threshold: Minimum number of signers required (must be >= 1).
    /// - Returns: Policy parameters for simple threshold.
    /// - Throws: `ValidationException.InvalidInput` when `threshold < 1`.
    public static func createThresholdParams(threshold: Int) throws -> OZSimpleThresholdParams {
        if threshold < 1 {
            throw ValidationException.invalidInput(
                field: "threshold",
                reason: "Threshold must be at least 1, got: \(threshold)"
            )
        }
        return OZSimpleThresholdParams(threshold: threshold)
    }

    /// Creates weighted threshold policy parameters.
    ///
    /// Each signer has a weight; authorisation succeeds when the sum of weights of
    /// authenticated signers meets or exceeds `threshold`.
    ///
    /// The `signerWeights` parameter is an ordered list of `OZSignerWeight` pairs rather
    /// than a dictionary. Pass one `OZSignerWeight(signer:weight:)` value per signer;
    /// duplicate signers are not merged by this builder — deduplication happens at the codec
    /// layer via key-based upsert. Example:
    /// ```swift
    /// let params = try OZSmartAccountBuilders.createWeightedThresholdParams(
    ///     threshold: 2,
    ///     signerWeights: [
    ///         OZSignerWeight(signer: signerA, weight: 2),
    ///         OZSignerWeight(signer: signerB, weight: 1),
    ///     ]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - threshold: Total weight required for authorisation (must be >= 1).
    ///   - signerWeights: Ordered list of signer-weight pairs (each weight must be >= 1).
    /// - Returns: Policy parameters for weighted threshold.
    /// - Throws: `ValidationException.InvalidInput` when `threshold < 1`, when
    ///           `signerWeights` is empty, when any weight is < 1, or when the total
    ///           weight is less than `threshold`.
    public static func createWeightedThresholdParams(
        threshold: Int,
        signerWeights: [OZSignerWeight]
    ) throws -> OZWeightedThresholdParams {
        if threshold < 1 {
            throw ValidationException.invalidInput(
                field: "threshold",
                reason: "Threshold must be at least 1, got: \(threshold)"
            )
        }
        if signerWeights.isEmpty {
            throw ValidationException.invalidInput(
                field: "signerWeights",
                reason: "At least one signer weight must be provided"
            )
        }
        var totalWeight = 0
        for entry in signerWeights {
            if entry.weight < 1 {
                throw ValidationException.invalidInput(
                    field: "signerWeights",
                    reason: "All weights must be positive integers, got: \(entry.weight)"
                )
            }
            totalWeight += entry.weight
        }
        if totalWeight < threshold {
            throw ValidationException.invalidInput(
                field: "signerWeights",
                reason: "Sum of weights (\(totalWeight)) must be >= threshold (\(threshold))"
            )
        }
        return OZWeightedThresholdParams(threshold: threshold, signerWeights: signerWeights)
    }

    /// Creates spending limit policy parameters.
    ///
    /// Restricts how much can be transferred within the supplied period. The
    /// `spendingLimit` is a decimal XLM string (for example `"100"` or `"10.5"`),
    /// converted to stroops via `Operation.toXDRAmount(amount:)`.
    ///
    /// Common values for `periodLedgers` are `StellarProtocolConstants.ledgersPerHour` and
    /// `StellarProtocolConstants.ledgersPerDay`.
    ///
    /// - Parameters:
    ///   - spendingLimit: Maximum amount allowed in the period as a decimal XLM string.
    ///   - periodLedgers: Number of ledgers in the period (must be >= 1).
    /// - Returns: Policy parameters for spending limit.
    /// - Throws: `StellarSDKError.invalidArgument` when the spending-limit string is
    ///           invalid; `ValidationException.InvalidInput` when `periodLedgers < 1`.
    public static func createSpendingLimitParams(
        spendingLimit: String,
        periodLedgers: Int
    ) throws -> OZSpendingLimitParams {
        let stroops = try Operation.toXDRAmount(amount: spendingLimit)
        if periodLedgers < 1 {
            throw ValidationException.invalidInput(
                field: "periodLedgers",
                reason: "Period must be at least 1 ledger, got: \(periodLedgers)"
            )
        }
        return OZSpendingLimitParams(spendingLimit: stroops, periodLedgers: periodLedgers)
    }
}

// ============================================================================
// Policy parameter data structs
// ============================================================================

/// Parameters for a simple threshold policy on an OpenZeppelin Smart Account context rule.
///
/// Authorisation succeeds when at least `threshold` signers on the context rule provide
/// valid signatures.
public struct OZSimpleThresholdParams: Sendable, Hashable {

    /// Minimum number of signers required (must be at least 1).
    public let threshold: Int

    /// Initializes new simple threshold parameters with the given `threshold`.
    public init(threshold: Int) {
        self.threshold = threshold
    }
}

/// One signer-weight pair used by `OZWeightedThresholdParams`.
///
/// Each `OZSignerWeight` binds a single `OZSmartAccountSigner` to an integer weight. A
/// weighted-threshold policy is parameterised by an ordered list of these pairs: callers
/// pass `[OZSignerWeight(signer: s1, weight: 2), OZSignerWeight(signer: s2, weight: 1), ...]`
/// to `OZSmartAccountBuilders.createWeightedThresholdParams`.
///
/// The list-of-pairs shape is used instead of a dictionary because Swift protocol
/// existentials (`any OZSmartAccountSigner`) cannot satisfy the `Hashable` requirement
/// needed for dictionary keys. The insertion order of the list is preserved through
/// validation and is normalised by the codec's key-sort step at serialisation time, so
/// the on-chain result is deterministic regardless of the order callers supply.
public struct OZSignerWeight: Sendable {

    /// Signer the weight applies to.
    public let signer: any OZSmartAccountSigner

    /// Weight assigned to the signer (must be >= 1).
    public let weight: Int

    /// Initializes a new signer-weight pair.
    public init(signer: any OZSmartAccountSigner, weight: Int) {
        self.signer = signer
        self.weight = weight
    }
}

/// Parameters for a weighted threshold policy on an OpenZeppelin Smart Account context rule.
///
/// Each signer has an integer weight; authorisation succeeds when the sum of weights of
/// authenticated signers meets or exceeds `threshold`.
public struct OZWeightedThresholdParams: Sendable {

    /// Total weight required for authorisation (must be >= 1).
    public let threshold: Int

    /// Per-signer weights; each weight is at least 1.
    public let signerWeights: [OZSignerWeight]

    /// Initializes new weighted threshold parameters.
    public init(threshold: Int, signerWeights: [OZSignerWeight]) {
        self.threshold = threshold
        self.signerWeights = signerWeights
    }
}

/// Parameters for a spending-limit policy on an OpenZeppelin Smart Account context rule.
///
/// Restricts how much can be transferred within a given time period. Construct instances
/// using `OZSmartAccountBuilders.createSpendingLimitParams`, which validates inputs and
/// converts the spending limit from a decimal XLM string to stroops.
public struct OZSpendingLimitParams: Sendable, Hashable {

    /// Maximum amount allowed in the period, expressed in stroops as `Int64`.
    ///
    /// The `Int64` type covers all current XLM amounts: the total XLM supply is
    /// approximately 5×10^17 stroops, well under `Int64.max` (~9.2×10^18 stroops). For
    /// non-XLM tokens or hypothetical future supply increases that exceed this range, callers
    /// should encode the spending limit directly as an `SCValXDR.i128(stringValue:)` and
    /// construct the policy call arguments by hand rather than using this builder.
    public let spendingLimit: Int64

    /// Number of ledgers in the period (at least 1). On the Stellar network a ledger
    /// closes approximately every five seconds.
    public let periodLedgers: Int

    /// Internal initializer invoked by `OZSmartAccountBuilders.createSpendingLimitParams`
    /// after validation; direct construction is intentionally not part of the public API
    /// so callers always go through the builder for input validation and unit conversion.
    internal init(spendingLimit: Int64, periodLedgers: Int) {
        self.spendingLimit = spendingLimit
        self.periodLedgers = periodLedgers
    }
}
