//
//  OZPolicyManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation


/// A signer selected for participation in a multi-signer authorization ceremony.
///
/// The smart-account contract supports M-of-N authorization across a mix of signer
/// kinds (passkey-backed external signers, Stellar G-address wallet signers, and Ed25519 external signers).
/// `OZSelectedSigner` is the single tagged-union shape passed by callers to manager
/// methods that take a `selectedSigners` parameter (for example
/// ``OZPolicyManager/addPolicy(contextRuleId:policyAddress:installParams:selectedSigners:forceMethod:)``).
///
/// When the supplied list is empty, manager methods route through the single-signer
/// submission path bound to the connected passkey credential. When the list is
/// non-empty, manager methods route through the multi-signer collection path which
/// gathers a signature from every supplied signer and assembles the final
/// authorization map.
///
/// - Important: This type is shared across every manager that supports multi-signer
///   authorization. It is defined here because the policy manager is the first
///   manager to require it; subsequent managers consume the same definition without
///   redeclaring it.
public enum OZSelectedSigner: Sendable, Hashable {

    /// A passkey-backed external signer identified by its WebAuthn credential id.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded WebAuthn credential identifier.
    ///   - credentialIdBytes: Optional raw credential identifier bytes. When
    ///     supplied, the multi-signer pipeline includes a matching
    ///     ``WebAuthnAllowCredential`` (with ``transports``) on the WebAuthn
    ///     authentication request so the OS can route to the correct passkey.
    ///     When `nil`, no `allowCredentials` list is passed to the provider and
    ///     the authenticator falls back to its default credential discovery.
    ///   - keyData: Optional pre-fetched secp256r1 public key plus credential id
    ///     bytes (`publicKey || credentialId`). Supplying this avoids an indexer
    ///     lookup during signature collection. May be `nil` when the manager
    ///     should resolve the key data on demand.
    ///   - transports: Optional WebAuthn transport hints (`internal`, `hybrid`,
    ///     `usb`, `ble`, `nfc`) propagated into the ``WebAuthnAllowCredential`` passed
    ///     to the WebAuthn provider when ``credentialIdBytes`` is non-nil.
    ///     Cross-device flows typically leave this `nil`.
    case passkey(credentialId: String, credentialIdBytes: Data? = nil, keyData: Data? = nil, transports: [String]? = nil)

    /// A wallet-backed signer identified by its `G…` Stellar account address.
    ///
    /// - Parameter accountId: Stellar account address (`G…` strkey) of the wallet
    ///   that will produce the signature, either through a configured external
    ///   wallet adapter or through an in-process keypair registered via
    ///   `OZExternalSignerManager`.
    case wallet(accountId: String)

    /// An Ed25519 signer backed by a verifier contract.
    ///
    /// Identifies a signer registered on-chain as an `External(verifierAddress, publicKey)`
    /// entry. The actual signing capability must be registered separately via
    /// ``OZExternalSignerManager/addEd25519FromRawKey(secretKeyBytes:verifierAddress:)`` or by
    /// supplying a conforming ``OZExternalEd25519SignerAdapter`` before the multi-signer
    /// pipeline executes.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier
    ///     contract registered as part of the on-chain `External(verifierAddress, publicKey)`
    ///     signer entry.
    ///   - publicKey: 32-byte Ed25519 public key that identifies the signer slot on the
    ///     smart account. Must match the public key registered in the on-chain signer entry.
    case ed25519(verifierAddress: String, publicKey: Data)
}


/// Installation parameters for the three built-in OpenZeppelin policy types.
///
/// Policies are authorization rules attached to context rules. A context rule can
/// hold up to ``OZConstants/maxPolicies`` policies, and every attached policy must
/// be satisfied for a transaction to authorize. Three built-in policy contracts
/// ship with the OZ smart-account suite:
///
/// - ``simpleThreshold(threshold:)`` — `M`-of-`N` authorization with equal weight
///   per signer.
/// - ``weightedThreshold(signerWeights:threshold:)`` — weighted voting with a
///   configurable per-signer weight.
/// - ``spendingLimit(spendingLimit:periodLedgers:)`` — maximum spend amount per
///   rolling time window expressed in ledgers.
///
/// Each arm encodes its parameters into the `Map`-shaped `SCValXDR` value the
/// installation contract expects. Inner key ordering is normalized to satisfy the
/// Soroban host's strict map-key ordering requirement.
///
/// Most callers should prefer the convenience methods on ``OZPolicyManager``
/// (``OZPolicyManager/addSimpleThreshold(contextRuleId:policyAddress:threshold:selectedSigners:forceMethod:)``,
/// ``OZPolicyManager/addWeightedThreshold(contextRuleId:policyAddress:signerWeights:threshold:selectedSigners:forceMethod:)``,
/// ``OZPolicyManager/addSpendingLimit(contextRuleId:policyAddress:spendingLimit:periodLedgers:selectedSigners:forceMethod:)``)
/// which build the matching `OZPolicyInstallParams` value internally. Callers that
/// need to install a custom policy contract construct the `SCValXDR` directly and
/// pass it to ``OZPolicyManager/addPolicy(contextRuleId:policyAddress:installParams:selectedSigners:forceMethod:)``.
///
/// Example:
/// ```swift
/// // 2-of-3 simple threshold.
/// let simple = OZPolicyInstallParams.simpleThreshold(threshold: 2)
///
/// // Weighted vote with a single Stellar-account-backed signer.
/// let signer = try OZDelegatedSigner(address: "GAAZI4TCR3TY...")
/// let weighted = OZPolicyInstallParams.weightedThreshold(
///     signerWeights: [OZSignerWeightEntry(signer: signer, weight: 50)],
///     threshold: 50
/// )
///
/// // Spend at most one XLM per ledger day.
/// let spending = OZPolicyInstallParams.spendingLimit(
///     spendingLimit: "1",
///     periodLedgers: 17_280
/// )
/// ```
public enum OZPolicyInstallParams: Sendable {

    /// Simple threshold policy requiring at least `threshold` of the context
    /// rule's signers to authorize. All signers carry equal weight (one vote
    /// each).
    ///
    /// - Parameter threshold: Minimum number of distinct signers required to
    ///   authorize. Must be greater than zero.
    case simpleThreshold(threshold: UInt32)

    /// Weighted threshold policy requiring authorizing signers' summed weights to
    /// meet or exceed `threshold`.
    ///
    /// - Parameters:
    ///   - signerWeights: One ``OZSignerWeightEntry`` per signer with its assigned
    ///     vote weight. Must contain at least one entry. Order is normalized
    ///     internally — callers may supply any insertion order.
    ///   - threshold: Minimum summed weight required to authorize. Must be
    ///     greater than zero.
    case weightedThreshold(signerWeights: [OZSignerWeightEntry], threshold: UInt32)

    /// Spending limit policy capping cumulative spend within a rolling
    /// `periodLedgers`-ledger window.
    ///
    /// - Parameters:
    ///   - spendingLimit: Maximum cumulative amount in the token's base units as
    ///     a non-negative integer string (digits only, no decimal point). This is
    ///     the raw on-chain amount already scaled by the token's `decimals`; the
    ///     caller is responsible for that scaling.
    ///   - periodLedgers: Rolling window length in ledgers (Stellar produces a
    ///     ledger approximately every five seconds). Must be greater than zero.
    case spendingLimit(spendingLimit: String, periodLedgers: UInt32)

    /// Encodes the installation parameters into the `Map`-shaped `SCValXDR` value
    /// the installation contract expects.
    ///
    /// Inner key ordering is normalized via ``OZPolicyManager/sortMapByKeyXdr(_:)``
    /// where dynamic keys are present (only ``weightedThreshold(signerWeights:threshold:)``
    /// has a dynamic-key inner map). Outer struct-shaped keys (`signer_weights`,
    /// `threshold`, `period_ledgers`, `spending_limit`) are inserted in
    /// alphabetical order to satisfy the Soroban Rust `#[contracttype]` derive
    /// convention.
    ///
    /// - Returns: The encoded `SCValXDR` map suitable for passing as the
    ///   `installParams` argument of the smart-account contract's `add_policy`
    ///   method.
    /// - Throws: ``SmartAccountValidationException/InvalidInput`` when the variant's
    ///   parameters are invalid (zero threshold, empty signer weights, non-positive
    ///   spending limit, zero period, or malformed spending-limit string).
    public func toScVal() throws -> SCValXDR {
        switch self {
        case .simpleThreshold(let threshold):
            if threshold == 0 {
                throw SmartAccountValidationException.invalidInput(
                    field: "threshold",
                    reason: "Threshold must be greater than zero"
                )
            }
            // Map with alphabetically ordered keys: ["threshold"].
            let entries: [SCMapEntryXDR] = [
                SCMapEntryXDR(key: .symbol("threshold"), val: .u32(threshold))
            ]
            return .map(entries)

        case .weightedThreshold(let signerWeights, let threshold):
            // Order matters: threshold validation runs before signer-weights
            // validation so the error surfaced when both inputs are bad
            // names the threshold first.
            if threshold == 0 {
                throw SmartAccountValidationException.invalidInput(
                    field: "threshold",
                    reason: "Threshold must be greater than zero"
                )
            }
            if signerWeights.isEmpty {
                throw SmartAccountValidationException.invalidInput(
                    field: "signerWeights",
                    reason: "Weighted threshold policy requires at least one signer with weight"
                )
            }

            // Build the inner signer-weights map. Two signers with byte-equal
            // ScVal encodings are considered duplicates by the Soroban host;
            // the host rejects ScMap values containing duplicate keys at
            // simulation time. We do not de-duplicate here because the
            // duplicate-key check belongs to the on-chain contract.
            var innerEntries: [SCMapEntryXDR] = []
            innerEntries.reserveCapacity(signerWeights.count)
            for entry in signerWeights {
                let signerScVal: SCValXDR
                do {
                    signerScVal = try entry.signer.toScVal()
                } catch {
                    throw SmartAccountValidationException.InvalidInput(
                        message: "Failed to encode signer for weighted threshold policy: \(error.localizedDescription)",
                        cause: error
                    )
                }
                innerEntries.append(
                    SCMapEntryXDR(key: signerScVal, val: .u32(entry.weight))
                )
            }

            // Sort the inner signer-weights map keys by XDR-encoded byte
            // ordering (Soroban host requirement for ScMap key uniqueness).
            let sortedInnerEntries = OZPolicyManager.sortMapByKeyXdr(innerEntries)

            // Outer struct map keys in alphabetical order:
            // ["signer_weights", "threshold"].
            let outerEntries: [SCMapEntryXDR] = [
                SCMapEntryXDR(
                    key: .symbol("signer_weights"),
                    val: .map(sortedInnerEntries)
                ),
                SCMapEntryXDR(
                    key: .symbol("threshold"),
                    val: .u32(threshold)
                )
            ]
            return .map(outerEntries)

        case .spendingLimit(let spendingLimit, let periodLedgers):
            // Validate the spending-limit string shape and sign before
            // normalising it through the SCVal i128 string parser. Use a
            // strict integer regex (no decimal point, no scientific notation,
            // no leading sign other than '-' which is rejected with a clear
            // message). The decimal-string parser inside `i128(stringValue:)`
            // tolerates a leading '-', so we reject it here so the surfaced
            // error message is field-specific.
            let trimmed = spendingLimit.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw SmartAccountValidationException.invalidInput(
                    field: "spendingLimit",
                    reason: "Spending limit must be greater than zero, got: \(spendingLimit)"
                )
            }

            // Reject negative values up front so the surfaced message is
            // field-specific and includes the offending value.
            if trimmed.hasPrefix("-") {
                throw SmartAccountValidationException.invalidInput(
                    field: "spendingLimit",
                    reason: "Spending limit must be greater than zero, got: \(spendingLimit)"
                )
            }

            // Strict integer shape: digits only, no decimal point, no
            // scientific notation. We treat the string as already in base units.
            let pattern = "^[0-9]+$"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                throw SmartAccountValidationException.invalidInput(
                    field: "spendingLimit",
                    reason: "Spending limit validator failed to initialize"
                )
            }
            let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            if regex.firstMatch(in: trimmed, options: [], range: nsRange) == nil {
                throw SmartAccountValidationException.invalidInput(
                    field: "spendingLimit",
                    reason: "Spending limit must be a positive integer in base units, got: \(spendingLimit)"
                )
            }

            // Reject zero with the canonical message after shape validation
            // so any leading-zero variant ("0", "00", "000") is rejected
            // uniformly.
            if OZPolicyInstallParams.isAllZeroDigits(trimmed) {
                throw SmartAccountValidationException.invalidInput(
                    field: "spendingLimit",
                    reason: "Spending limit must be greater than zero, got: \(spendingLimit)"
                )
            }

            if periodLedgers == 0 {
                throw SmartAccountValidationException.invalidInput(
                    field: "periodLedgers",
                    reason: "Period ledgers must be greater than zero, got: \(periodLedgers)"
                )
            }

            // Convert the validated decimal-integer string to its i128 SCVal
            // representation.
            let limitScVal: SCValXDR
            do {
                limitScVal = try SCValXDR.i128(stringValue: trimmed)
            } catch {
                throw SmartAccountValidationException.InvalidInput(
                    message: "Spending limit out of i128 range: \(spendingLimit)",
                    cause: error
                )
            }

            // Outer struct map keys in alphabetical order:
            // ["period_ledgers", "spending_limit"].
            let outerEntries: [SCMapEntryXDR] = [
                SCMapEntryXDR(
                    key: .symbol("period_ledgers"),
                    val: .u32(periodLedgers)
                ),
                SCMapEntryXDR(
                    key: .symbol("spending_limit"),
                    val: limitScVal
                )
            ]
            return .map(outerEntries)
        }
    }

    /// Returns `true` when every character of `s` is `"0"`.
    private static func isAllZeroDigits(_ s: String) -> Bool {
        if s.isEmpty {
            return false
        }
        for ch in s where ch != "0" {
            return false
        }
        return true
    }
}


/// A single signer-weight pair carried by ``OZPolicyInstallParams/weightedThreshold(signerWeights:threshold:)``.
///
/// Models a weighted-vote contribution: the wrapped ``OZSmartAccountSigner``
/// contributes ``weight`` points toward a weighted-threshold policy when it
/// authorizes. The ``signer`` field is an existential ``OZSmartAccountSigner``
/// so callers may mix ``OZDelegatedSigner`` (Stellar-account or contract-address
/// signers) and ``OZExternalSigner`` (passkey or Ed25519 verifier-contract
/// signers) freely within a single policy.
///
/// Insertion order is preserved through validation; the final on-chain inner-map
/// ordering is normalized by ``OZPolicyManager/sortMapByKeyXdr(_:)`` at encoding
/// time, so the on-chain shape is deterministic regardless of the order callers
/// supply the entries.
///
/// - Note: An array of `OZSignerWeightEntry` is used in place of a `Dictionary`
///   keyed by signer because Swift protocol existentials do not satisfy the
///   `Hashable` requirement that dictionary keys impose. The array shape also
///   gives callers explicit, observable insertion order during construction
///   even though the on-chain map is sorted later.
public struct OZSignerWeightEntry: Sendable {

    /// The signer that contributes ``weight`` points when it authorizes.
    public let signer: any OZSmartAccountSigner

    /// Vote weight contributed by the signer when it authorizes. Must be greater
    /// than zero — a zero-weight signer is indistinguishable from no signer at
    /// all and is rejected by the smart-account contract.
    public let weight: UInt32

    /// Initializes a new `OZSignerWeightEntry`.
    ///
    /// - Parameters:
    ///   - signer: The signer that contributes ``weight`` points.
    ///   - weight: Vote weight contributed by the signer.
    public init(signer: any OZSmartAccountSigner, weight: UInt32) {
        self.signer = signer
        self.weight = weight
    }
}


/// Manager for policy operations on OpenZeppelin Smart Accounts.
///
/// Adds and removes policies on context rules. A context rule may carry up to
/// ``OZConstants/maxPolicies`` policies; every attached policy must be satisfied
/// for a transaction to authorize.
///
/// Built-in conveniences: ``addSimpleThreshold``, ``addWeightedThreshold``,
/// ``addSpendingLimit``. For custom policy contracts, pass encoded `SCValXDR`
/// install params to ``addPolicy(contextRuleId:policyAddress:installParams:selectedSigners:forceMethod:)``.
///
/// All state-changing methods accept an optional `selectedSigners` list. An
/// empty list routes through the single-signer path (connected passkey);
/// a non-empty list routes through the multi-signer ceremony coordinator.
///
/// Example:
/// ```swift
/// let result = try await kit.policyManager.addSimpleThreshold(
///     contextRuleId: 0,
///     policyAddress: "CBCD1234...",
///     threshold: 2
/// )
/// ```
public final class OZPolicyManager: OZManagerHelpers, @unchecked Sendable {

    // MARK: - Stored properties

    let kit: OZSmartAccountKitProtocol

    /// Context-rule parser consulted by
    /// ``removePolicyByAddress(contextRuleId:policyAddress:selectedSigners:forceMethod:)``
    /// to resolve a policy contract address to its numeric on-chain id with a
    /// single-rule fetch (instead of paginating every rule). Optional so the
    /// manager can be constructed and unit-tested without instantiating the
    /// full context-rule manager dependency graph.
    private let contextRuleParser: OZContextRuleParser?

    // MARK: - Initialization

    /// Internal initializer; instances are constructed by `OZSmartAccountKit`.
    internal init(
        kit: OZSmartAccountKitProtocol,
        contextRuleParser: OZContextRuleParser? = nil
    ) {
        self.kit = kit
        self.contextRuleParser = contextRuleParser
    }

    /// Adds a simple threshold policy to the supplied context rule.
    ///
    /// A simple threshold policy authorizes when at least `threshold` of the
    /// context rule's signers have signed. All signers carry equal weight (one
    /// vote each); for weighted voting use
    /// ``addWeightedThreshold(contextRuleId:policyAddress:signerWeights:threshold:selectedSigners:forceMethod:)``.
    ///
    /// Encodes the parameters and delegates to
    /// ``addPolicy(contextRuleId:policyAddress:installParams:selectedSigners:forceMethod:)``.
    ///
    /// - Parameters:
    ///   - contextRuleId: The context-rule identifier the policy is being added
    ///     to (zero is the default rule).
    ///   - policyAddress: Policy contract address (`C…` strkey). Must be a valid
    ///     contract address — Stellar account `G…` addresses are rejected.
    ///   - threshold: Minimum number of signers that must authorize. Must be
    ///     greater than zero.
    ///   - selectedSigners: Optional list of signers participating in the
    ///     authorization ceremony. Empty (default) routes through single-signer
    ///     submission with the connected passkey; non-empty routes through the
    ///     multi-signer path.
    ///   - forceMethod: Optional submission-method override. When `nil` the
    ///     kit's configured default is used.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountValidationException`` when validation fails;
    ///   ``SmartAccountWalletException`` when no wallet is connected;
    ///   ``SmartAccountTransactionException`` for simulation, signing, or submission
    ///   failures.
    public func addSimpleThreshold(
        contextRuleId: UInt32,
        policyAddress: String,
        threshold: UInt32,
        selectedSigners: [OZSelectedSigner] = [],
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let params = OZPolicyInstallParams.simpleThreshold(threshold: threshold)
        let installParams = try params.toScVal()
        return try await addPolicy(
            contextRuleId: contextRuleId,
            policyAddress: policyAddress,
            installParams: installParams,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Adds a weighted threshold policy to the supplied context rule.
    ///
    /// A weighted threshold policy authorizes when the sum of weights of every
    /// authorizing signer meets or exceeds `threshold`. Each signer in
    /// `signerWeights` contributes its assigned vote weight when it authorizes.
    ///
    /// Encodes the parameters and delegates to
    /// ``addPolicy(contextRuleId:policyAddress:installParams:selectedSigners:forceMethod:)``.
    ///
    /// - Parameters:
    ///   - contextRuleId: The context-rule identifier the policy is being added
    ///     to (zero is the default rule).
    ///   - policyAddress: Policy contract address (`C…` strkey).
    ///   - signerWeights: One ``OZSignerWeightEntry`` per signer with its assigned
    ///     vote weight. Must contain at least one entry.
    ///   - threshold: Minimum summed weight required to authorize. Must be
    ///     greater than zero.
    ///   - selectedSigners: Optional multi-signer participants list (see
    ///     ``addSimpleThreshold(contextRuleId:policyAddress:threshold:selectedSigners:forceMethod:)``).
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountValidationException`` for invalid input;
    ///   ``SmartAccountWalletException`` for missing connection;
    ///   ``SmartAccountTransactionException`` for submission failures.
    public func addWeightedThreshold(
        contextRuleId: UInt32,
        policyAddress: String,
        signerWeights: [OZSignerWeightEntry],
        threshold: UInt32,
        selectedSigners: [OZSelectedSigner] = [],
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let params = OZPolicyInstallParams.weightedThreshold(
            signerWeights: signerWeights,
            threshold: threshold
        )
        let installParams = try params.toScVal()
        return try await addPolicy(
            contextRuleId: contextRuleId,
            policyAddress: policyAddress,
            installParams: installParams,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Adds a spending limit policy to the supplied context rule.
    ///
    /// A spending limit policy caps the cumulative spend within a rolling
    /// `periodLedgers`-ledger window (Stellar produces a ledger approximately
    /// every five seconds; ``StellarProtocolConstants/ledgersPerHour`` supplies
    /// the canonical hour count, and ~17 280 ledgers approximates one day).
    ///
    /// The amount is supplied as a positive decimal string and converted to the
    /// token's base units using `decimals` (default 7).
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the policy is being added to
    ///     (zero is the default rule).
    ///   - policyAddress: Policy contract address (`C…` strkey).
    ///   - spendingLimit: Maximum cumulative amount per period as a positive
    ///     decimal string (for example `"100"` or `"0.5"`). Converted to the
    ///     token's base units internally using `decimals`; up to `decimals`
    ///     fractional digits are accepted.
    ///   - periodLedgers: Rolling-window length in ledgers. Must be greater
    ///     than zero.
    ///   - decimals: The token's decimal scale used to convert `spendingLimit`
    ///     to base units. Defaults to 7. This method has no token-contract
    ///     parameter and therefore does not fetch the scale automatically.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountValidationException`` for invalid input;
    ///   ``SmartAccountWalletException`` for missing connection;
    ///   ``SmartAccountTransactionException`` for submission failures.
    public func addSpendingLimit(
        contextRuleId: UInt32,
        policyAddress: String,
        spendingLimit: String,
        periodLedgers: UInt32,
        decimals: Int = 7,
        selectedSigners: [OZSelectedSigner] = [],
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        // Convert the decimal string to base units using the same routine the
        // transaction-operations layer uses for token transfers. The result is a
        // non-negative integer base-units string.
        let baseUnits: String
        do {
            baseUnits = try OZTransactionOperations.amountToBaseUnits(spendingLimit, decimals: decimals)
        } catch let error as SmartAccountValidationException.InvalidAmount {
            // Re-surface as a field-tagged validation error so the message
            // refers to the policy parameter the caller supplied rather than
            // the generic "amount" label.
            throw SmartAccountValidationException.invalidInput(
                field: "spendingLimit",
                reason: error.message,
                cause: error
            )
        }

        let params = OZPolicyInstallParams.spendingLimit(
            spendingLimit: baseUnits,
            periodLedgers: periodLedgers
        )
        let installParams = try params.toScVal()
        return try await addPolicy(
            contextRuleId: contextRuleId,
            policyAddress: policyAddress,
            installParams: installParams,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Removes a policy from a context rule by its on-chain numeric id.
    ///
    /// The id is assigned by the smart-account contract when the policy is
    /// installed and surfaces on the parsed context rule's `policyIds` field.
    /// Use ``removePolicyByAddress(contextRuleId:policyAddress:selectedSigners:forceMethod:)``
    /// when only the policy contract address is known — that overload resolves
    /// the id internally with one extra RPC round trip.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the policy is being removed
    ///     from (zero is the default rule).
    ///   - policyId: Numeric policy identifier assigned at installation time.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException`` for missing connection;
    ///   ``SmartAccountTransactionException`` for submission failures.
    public func removePolicy(
        contextRuleId: UInt32,
        policyId: UInt32,
        selectedSigners: [OZSelectedSigner] = [],
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()

        let hostFunction = try OZPolicyManager.buildRemovePolicyFunction(
            contractId: connected.contractId,
            contextRuleId: contextRuleId,
            policyId: policyId
        )

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Removes a policy from a context rule by matching the policy contract
    /// address.
    ///
    /// Convenience overload that resolves the on-chain numeric policy id
    /// internally before delegating to ``removePolicy(contextRuleId:policyId:selectedSigners:forceMethod:)``.
    /// One extra RPC round trip is performed to fetch the context rule and
    /// locate the policy address within the rule's `policies` list.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the policy is being removed
    ///     from.
    ///   - policyAddress: Policy contract address (`C…` strkey) to match
    ///     against the rule's installed policies.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException`` for missing connection;
    ///   ``SmartAccountValidationException`` when `policyAddress` is malformed or absent
    ///   from the rule;
    ///   ``SmartAccountTransactionException`` for submission failures.
    ///
    /// - Note: The Swift name differs from the underlying contract method to
    ///   distinguish this overload at the call site from the id-based
    ///   ``removePolicy(contextRuleId:policyId:selectedSigners:forceMethod:)``.
    ///   The `byAddress` suffix keeps the call site self-documenting.
    public func removePolicyByAddress(
        contextRuleId: UInt32,
        policyAddress: String,
        selectedSigners: [OZSelectedSigner] = [],
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        try requireContractAddress(policyAddress, fieldName: "policyAddress")

        let policyId = try await resolvePolicyIdByAddress(
            contextRuleId: contextRuleId,
            policyAddress: policyAddress
        )
        return try await removePolicy(
            contextRuleId: contextRuleId,
            policyId: policyId,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Adds a policy to a context rule with caller-supplied installation
    /// parameters.
    ///
    /// This is the generic method that
    /// ``addSimpleThreshold(contextRuleId:policyAddress:threshold:selectedSigners:forceMethod:)``,
    /// ``addWeightedThreshold(contextRuleId:policyAddress:signerWeights:threshold:selectedSigners:forceMethod:)``,
    /// and
    /// ``addSpendingLimit(contextRuleId:policyAddress:spendingLimit:periodLedgers:selectedSigners:forceMethod:)``
    /// delegate to. Use this method directly when installing a custom policy
    /// contract that is not covered by the convenience methods.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the policy is being added to.
    ///   - policyAddress: Policy contract address (`C…` strkey).
    ///   - installParams: Policy-specific installation parameters encoded as
    ///     `SCValXDR`. The structure depends on the target policy contract; for
    ///     the three built-in policy types use ``OZPolicyInstallParams/toScVal()``
    ///     on the matching enum case.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException`` for missing connection;
    ///   ``SmartAccountValidationException`` when `policyAddress` is malformed;
    ///   ``SmartAccountTransactionException`` for submission failures.
    public func addPolicy(
        contextRuleId: UInt32,
        policyAddress: String,
        installParams: SCValXDR,
        selectedSigners: [OZSelectedSigner] = [],
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()
        try requireContractAddress(policyAddress, fieldName: "policyAddress")

        let hostFunction = try OZPolicyManager.buildAddPolicyFunction(
            contractId: connected.contractId,
            contextRuleId: contextRuleId,
            policyAddress: policyAddress,
            installParams: installParams
        )

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Private routing & helpers

    /// Resolves a policy contract address to its on-chain numeric id by
    /// fetching the supplied context rule and locating the policy's index in
    /// the rule's `policies` list.
    ///
    /// When a context-rule parser was wired at construction time, this method
    /// performs a single-rule fetch + parse — exactly one RPC simulation. When
    /// no parser is available (unit-test paths that wire the manager without
    /// the parser), the method falls back to `listContextRules()` which scans
    /// the full rule set.
    ///
    /// - Parameters:
    ///   - contextRuleId: Identifier of the rule containing the policy.
    ///   - policyAddress: Policy contract address to resolve.
    /// - Returns: The numeric policy id at the matching index.
    /// - Throws: ``SmartAccountValidationException`` when the address is absent from the
    ///   rule, when the rule's `policies` and `policyIds` arrays are
    ///   misaligned, or when the rule itself cannot be located.
    private func resolvePolicyIdByAddress(
        contextRuleId: UInt32,
        policyAddress: String
    ) async throws -> UInt32 {
        let rule: OZParsedContextRule
        if let parser = contextRuleParser {
            // Fast path: single-rule fetch + parse, one RPC simulation.
            let scVal = try await parser.getContextRule(contextRuleId: contextRuleId)
            rule = try parser.parseContextRule(scVal)
        } else {
            // Fallback path used by unit tests that wire the manager without
            // a context-rule parser. Performs `N` RPC simulations because the
            // protocol does not expose a single-rule fetch helper outside the
            // parser surface.
            let rules = try await kit.contextRuleManagerProtocol.listContextRules(maxScanId: nil)
            guard let located = rules.first(where: { $0.id == contextRuleId }) else {
                throw SmartAccountValidationException.invalidInput(
                    field: "contextRuleId",
                    reason: "Context rule \(contextRuleId) not found"
                )
            }
            rule = located
        }

        guard let index = rule.policies.firstIndex(where: { $0 == policyAddress }) else {
            throw SmartAccountValidationException.invalidInput(
                field: "policyAddress",
                reason: "Policy \(policyAddress) not found on context rule \(contextRuleId)"
            )
        }

        // why: the smart-account contract exposes a parallel `policyIds` array
        // alongside `policies`. The arrays must be the same length, but a
        // parser bug (or a future contract revision that adds entries to one
        // array but not the other) could violate the invariant. Detect the
        // misalignment explicitly so the surfaced error names the constraint
        // rather than throwing an opaque out-of-bounds runtime trap.
        if index >= rule.policyIds.count {
            throw SmartAccountValidationException.invalidInput(
                field: "policyAddress",
                reason: "Policy found at index \(index) but policyIds has only \(rule.policyIds.count) entries"
            )
        }

        return rule.policyIds[index]
    }

    /// Builds the host function that invokes the smart-account contract's
    /// `add_policy` method.
    ///
    /// - Parameters:
    ///   - contractId: Smart-account contract address (`C…` strkey).
    ///   - contextRuleId: Identifier of the context rule the policy attaches
    ///     to.
    ///   - policyAddress: Policy contract address (`C…` strkey) being
    ///     installed.
    ///   - installParams: Policy installation parameters encoded as `SCValXDR`.
    /// - Returns: The matching ``HostFunctionXDR`` ready for transaction
    ///   assembly.
    /// - Throws: ``StellarSDKError`` when the supplied addresses cannot be
    ///   encoded into their `SCAddressXDR` representations.
    internal static func buildAddPolicyFunction(
        contractId: String,
        contextRuleId: UInt32,
        policyAddress: String,
        installParams: SCValXDR
    ) throws -> HostFunctionXDR {
        let contractScAddress = try SCAddressXDR(contractId: contractId)
        let policyScAddress = try SCAddressXDR(contractId: policyAddress)

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractScAddress,
            functionName: "add_policy",
            args: [
                .u32(contextRuleId),
                .address(policyScAddress),
                installParams
            ]
        )
        return HostFunctionXDR.invokeContract(invokeArgs)
    }

    /// Builds the host function that invokes the smart-account contract's
    /// `remove_policy` method.
    ///
    /// - Parameters:
    ///   - contractId: Smart-account contract address (`C…` strkey).
    ///   - contextRuleId: Identifier of the context rule the policy is being
    ///     removed from.
    ///   - policyId: Numeric identifier of the installed policy.
    /// - Returns: The matching ``HostFunctionXDR`` ready for transaction
    ///   assembly.
    /// - Throws: ``StellarSDKError`` when the supplied contract id cannot be
    ///   encoded into an `SCAddressXDR`.
    internal static func buildRemovePolicyFunction(
        contractId: String,
        contextRuleId: UInt32,
        policyId: UInt32
    ) throws -> HostFunctionXDR {
        let contractScAddress = try SCAddressXDR(contractId: contractId)

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractScAddress,
            functionName: "remove_policy",
            args: [
                .u32(contextRuleId),
                .u32(policyId)
            ]
        )
        return HostFunctionXDR.invokeContract(invokeArgs)
    }

    // MARK: - ScMap key sorting

    /// Sorts a list of `SCMapEntryXDR` entries by the lexicographic byte
    /// ordering of their keys' XDR encoding.
    ///
    /// Soroban's host enforces strict byte-lexicographic ordering of `SCMap`
    /// keys for canonicality and uniqueness checks. Use this helper whenever a
    /// dynamically-keyed map is built from caller-supplied data so the on-chain
    /// shape is deterministic regardless of insertion order.
    ///
    /// The supplied list is not mutated; a new sorted list is returned. Two
    /// entries whose keys encode to byte-equal sequences preserve their
    /// relative input order (stable sort), but byte-equal keys signal a
    /// duplicate-key bug and the on-chain host rejects such maps at
    /// simulation time.
    ///
    /// - Parameter entries: Entries to sort.
    /// - Returns: A new array of entries sorted by XDR-encoded key bytes in
    ///   ascending order.
    public static func sortMapByKeyXdr(
        _ entries: [SCMapEntryXDR]
    ) -> [SCMapEntryXDR] {
        if entries.count <= 1 {
            return entries
        }

        // why: precompute each key's XDR bytes so the comparator does not
        // re-encode the same key on every comparison. Hex strings are monotone
        // in the byte sequence, so lexicographic comparison agrees with raw
        // byte comparison.
        struct Keyed {
            let hex: String
            let entry: SCMapEntryXDR
        }
        var keyed: [Keyed] = []
        keyed.reserveCapacity(entries.count)
        for entry in entries {
            let keyBytes = OZPolicyManager.scValToXdrBytes(entry.key)
            let hex = Data(keyBytes).base16EncodedString()
            keyed.append(Keyed(hex: hex, entry: entry))
        }
        // Swift 5+ `sorted(by:)` is stable, so byte-equal keys retain their
        // input order without needing an index-tagged tiebreaker.
        let sorted = keyed.sorted { $0.hex < $1.hex }
        return sorted.map { $0.entry }
    }

    /// Encodes an `SCValXDR` value to its raw XDR byte sequence.
    ///
    /// Used by ``sortMapByKeyXdr(_:)`` to derive the deterministic sort key
    /// for each map entry. Exposed at `internal` visibility so unit tests can
    /// verify byte-level encoding determinism without exporting the helper to
    /// SDK consumers.
    ///
    /// - Parameter scVal: The value to encode.
    /// - Returns: The XDR-encoded byte sequence.
    internal static func scValToXdrBytes(_ scVal: SCValXDR) -> [UInt8] {
        do {
            return try XDREncoder.encode(scVal)
        } catch {
            // why: every `SCValXDR` is serializable by construction, so a
            // failure here signals a malformed value produced upstream. Trap
            // rather than return empty bytes, which would collapse distinct
            // values onto byte-equal sort keys.
            preconditionFailure("SCValXDR encoding must not fail: \(error)")
        }
    }
}
