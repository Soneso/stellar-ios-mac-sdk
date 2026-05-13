//
//  OZContextRuleManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// MARK: - Contract-ABI field-name constants
// ============================================================================

/// Single source-of-truth for the smart-account contract's `ContextRule`
/// struct field names. The on-chain Soroban runtime serialises Rust struct
/// values as `SCVal::Map` with `Symbol`-typed keys and enforces strict
/// lexicographic ordering. Centralising these strings keeps the parser
/// (``OZContextRuleManager/parseContextRule(scVal:)``) and the
/// argument builder (``OZContextRuleManager/addContextRule(contextType:name:validUntil:signers:policies:selectedSigners:forceMethod:)``)
/// reading and writing one canonical name set, preventing a silent ABI drift
/// if either side is edited in isolation.
private enum ContextRuleField {
    static let id = "id"
    static let name = "name"
    static let contextType = "context_type"
    static let signers = "signers"
    static let signerIds = "signer_ids"
    static let policies = "policies"
    static let policyIds = "policy_ids"
    static let validUntil = "valid_until"
}

/// Contract-ABI discriminant strings for ``ContextRuleType`` arms.
///
/// These strings appear in both the parser (decoding `Vec` discriminants from
/// the on-chain rule) and the encoder (``ContextRuleType/toScVal()``). Defined
/// at file scope so a single edit covers both paths.
private enum ContextTypeDiscriminant {
    static let defaultRule = "Default"
    static let callContract = "CallContract"
    static let createContract = "CreateContract"
}

/// Contract-ABI discriminant strings for the on-chain `Signer` enum arms
/// returned in the `signers` field of a parsed context rule.
private enum SignerDiscriminant {
    static let delegated = "Delegated"
    static let external = "External"
}

/// Contract method names invoked by ``OZContextRuleManager``. Co-located with
/// the parser/encoder so the smart-account ABI is single-source-of-truth in
/// this file.
private enum ContextRuleMethod {
    static let addContextRule = "add_context_rule"
    static let getContextRule = "get_context_rule"
    static let getContextRulesCount = "get_context_rules_count"
    static let updateContextRuleName = "update_context_rule_name"
    static let updateContextRuleValidUntil = "update_context_rule_valid_until"
    static let removeContextRule = "remove_context_rule"
}

// ============================================================================
// MARK: - OZContextRuleManager
// ============================================================================

/// Manages context rules for an OpenZeppelin Smart Account.
///
/// Context rules define authorization requirements for different categories of
/// operations. Each rule specifies:
/// - **Context type** — what operations the rule applies to (``ContextRuleType/defaultRule``,
///   ``ContextRuleType/callContract(contractAddress:)``, or
///   ``ContextRuleType/createContract(wasmHash:)``)
/// - **Name** — a human-readable identifier
/// - **Signers** — who can authorize operations matching this context
/// - **Policies** — additional constraints (spending limits, time locks,
///   multi-sig thresholds, and so on)
/// - **Valid until** — optional expiration ledger
///
/// The smart-account contract evaluates inbound transactions against the rule
/// set to determine which signers must sign and which policy contracts must
/// approve.
///
/// State-changing methods (``addContextRule(contextType:name:validUntil:signers:policies:selectedSigners:forceMethod:)``,
/// ``updateName(id:name:selectedSigners:forceMethod:)``,
/// ``updateValidUntil(id:validUntil:selectedSigners:forceMethod:)``,
/// ``removeContextRule(id:selectedSigners:forceMethod:)``) accept an optional
/// `selectedSigners` list. When empty (the default), the operation routes
/// through the single-signer submission path bound to the connected passkey.
/// When non-empty, it routes through ``OZMultiSignerSubmitting``.
///
/// Contract limits enforced at validation time:
/// - Maximum ``OZConstants/maxSigners`` signers per context rule.
/// - Maximum ``OZConstants/maxPolicies`` policies per context rule.
///
/// Example:
/// ```swift
/// let manager = kit.contextRuleManager
///
/// // Add a rule for token transfers requiring 2-of-3 multi-sig.
/// let result = try await manager.addContextRule(
///     contextType: .callContract(contractAddress: tokenContractAddress),
///     name: "TokenTransfers",
///     validUntil: nil,
///     signers: [signer1, signer2, signer3],
///     policies: [thresholdPolicyAddress: thresholdScVal]
/// )
///
/// // Discover existing rules.
/// let rules = try await manager.listContextRules()
/// let count = try await manager.getContextRulesCount()
///
/// // Remove a context rule.
/// _ = try await manager.removeContextRule(id: ruleId)
/// ```
///
/// - Note: Thread safety — every public method is `async` and may be invoked
///   concurrently. Internal state is limited to immutable properties captured
///   at initialization time, so no synchronization is required at this layer.
public final class OZContextRuleManager: OZContextRuleManagerProtocol, @unchecked Sendable {

    // MARK: - Stored properties

    /// Kit reference used to resolve the connected smart-account contract id
    /// and to delegate host-function submission to the kit's transaction
    /// operations.
    private let kit: OZSmartAccountKitProtocol

    /// Multi-signer submission collaborator consulted when a caller supplies a
    /// non-empty `selectedSigners` list. Optional so the manager can be
    /// constructed and unit-tested independently of the multi-signer manager;
    /// when the collaborator is `nil`, calls that route to the multi-signer
    /// path throw a configuration error.
    private let multiSignerSubmitter: OZMultiSignerSubmitting?

    // MARK: - Initialization

    /// Initializes a new `OZContextRuleManager` bound to the supplied kit.
    ///
    /// - Parameters:
    ///   - kit: The owning smart account kit.
    ///   - multiSignerSubmitter: Optional collaborator consulted when a caller
    ///     supplies a non-empty `selectedSigners` list. The kit assembles the
    ///     concrete multi-signer manager and supplies it here at construction
    ///     time. Pass `nil` in unit tests that exclusively cover the
    ///     single-signer routing path or read-only operations.
    internal init(
        kit: OZSmartAccountKitProtocol,
        multiSignerSubmitter: OZMultiSignerSubmitting? = nil
    ) {
        self.kit = kit
        self.multiSignerSubmitter = multiSignerSubmitter
    }

    // MARK: - Add Context Rule

    /// Adds a new context rule to the connected smart account.
    ///
    /// Validates the inputs, builds the matching `add_context_rule` invocation,
    /// and routes the resulting host function through either the single-signer
    /// or the multi-signer submission path.
    ///
    /// Contract limits enforced before submission:
    /// - Maximum ``OZConstants/maxSigners`` signers per rule.
    /// - Maximum ``OZConstants/maxPolicies`` policies per rule.
    ///
    /// - Parameters:
    ///   - contextType: Operation-matching type for the rule.
    ///   - name: Human-readable rule name (must be non-empty).
    ///   - validUntil: Optional ledger number when this rule expires; `nil`
    ///     means the rule never expires.
    ///   - signers: Signers authorized by this rule. Either `signers` or
    ///     `policies` must be non-empty.
    ///   - policies: Map of policy contract addresses (`C…` strkey) to their
    ///     installation parameters encoded as `SCValXDR`. Keys are sorted by
    ///     XDR-byte order before submission to satisfy Soroban's `SCMap`
    ///     ordering invariant.
    ///   - selectedSigners: Optional multi-signer participants list. Empty
    ///     routes through single-signer submission; non-empty routes through
    ///     the multi-signer collaborator.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws:
    ///   - ``WalletException/NotConnected`` when no wallet is connected.
    ///   - ``ValidationException/InvalidInput`` when validation fails.
    ///   - ``ValidationException/InvalidAddress`` when a policy address is
    ///     malformed.
    ///   - ``TransactionException`` for simulation, signing, or submission
    ///     failures.
    public func addContextRule(
        contextType: ContextRuleType,
        name: String,
        validUntil: UInt32? = nil,
        signers: [any OZSmartAccountSigner],
        policies: [String: SCValXDR] = [:],
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        // Validate inputs.
        if name.isEmpty {
            throw ValidationException.invalidInput(
                field: "name",
                reason: "Context rule name cannot be empty"
            )
        }

        if signers.isEmpty && policies.isEmpty {
            throw ValidationException.invalidInput(
                field: "signers",
                reason: "Context rule must have at least one signer or one policy"
            )
        }

        if signers.count > OZConstants.maxSigners {
            throw ValidationException.invalidInput(
                field: "signers",
                reason: "Context rule cannot have more than \(OZConstants.maxSigners) signers, got: \(signers.count)"
            )
        }

        if policies.count > OZConstants.maxPolicies {
            throw ValidationException.invalidInput(
                field: "policies",
                reason: "Context rule cannot have more than \(OZConstants.maxPolicies) policies, got: \(policies.count)"
            )
        }

        // Validate policy addresses are well-formed C-addresses.
        for (address, _) in policies {
            try requireContractAddress(address, fieldName: "contractAddress")
        }

        // Build function arguments.
        //
        // arg 0: context_type — Vec discriminant encoding.
        let contextTypeScVal = try contextType.toScVal()

        // arg 1: name — Soroban String type (not Symbol).
        let nameScVal = SCValXDR.string(name)

        // arg 2: valid_until — Option<u32> represented as Void for None and U32 for Some.
        let validUntilScVal: SCValXDR
        if let validUntil = validUntil {
            validUntilScVal = .u32(validUntil)
        } else {
            validUntilScVal = .void
        }

        // arg 3: signers — Vec<Signer> where each Signer is the Vec discriminant shape.
        let signersScValList: [SCValXDR] = try signers.map { try $0.toScVal() }
        let signersScVal = SCValXDR.vec(signersScValList)

        // arg 4: policies — Map<Address, ScVal>. Keys MUST be sorted by their
        // XDR-byte representation per the Soroban `ScMap` ordering invariant;
        // delegated to ``OZPolicyManager/sortMapByKeyXdr(_:)`` (D-120).
        var policyEntries: [SCMapEntryXDR] = []
        policyEntries.reserveCapacity(policies.count)
        for (address, installParam) in policies {
            let policyScAddress = try SCAddressXDR(contractId: address)
            policyEntries.append(SCMapEntryXDR(
                key: .address(policyScAddress),
                val: installParam
            ))
        }
        let sortedPolicyEntries = OZPolicyManager.sortMapByKeyXdr(policyEntries)
        let policiesScVal = SCValXDR.map(sortedPolicyEntries)

        // Build invocation.
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: ContextRuleMethod.addContextRule,
            args: [
                contextTypeScVal,
                nameScVal,
                validUntilScVal,
                signersScVal,
                policiesScVal
            ]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Get Context Rule

    /// Retrieves a specific context rule by its on-chain numeric id.
    ///
    /// Returns the raw `SCValXDR` payload exactly as the contract emits it.
    /// Callers that need a typed view should parse the result with
    /// ``parseContextRule(scVal:)`` or use ``listContextRules()``, which
    /// performs the parse step internally.
    ///
    /// This is a read-only operation that issues a simulated invocation
    /// against the connected contract without producing or submitting an
    /// authorized transaction.
    ///
    /// - Parameter id: The context-rule identifier to look up.
    /// - Returns: The raw `SCValXDR` returned by the contract method.
    /// - Throws:
    ///   - ``WalletException/NotConnected`` when no wallet is connected.
    ///   - ``TransactionException/SimulationFailed`` when the simulation
    ///     fails (commonly because the rule does not exist on chain).
    public func getContextRule(id: UInt32) async throws -> SCValXDR {
        let connected = try kit.requireConnected()

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: ContextRuleMethod.getContextRule,
            args: [.u32(id)]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await kit.transactionOperations.simulateAndExtractResult(
            hostFunction: hostFunction
        )
    }

    // MARK: - Get Context Rules Count

    /// Retrieves the number of context rules currently configured on the
    /// connected smart account.
    ///
    /// This is a read-only operation that issues a simulated invocation
    /// against the connected contract.
    ///
    /// - Returns: The active rule count parsed as `UInt32`.
    /// - Throws:
    ///   - ``WalletException/NotConnected`` when no wallet is connected.
    ///   - ``TransactionException`` when the simulation fails.
    ///   - ``ValidationException/InvalidInput`` when the on-chain result is
    ///     not a `U32`.
    public func getContextRulesCount() async throws -> UInt32 {
        let connected = try kit.requireConnected()

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: ContextRuleMethod.getContextRulesCount,
            args: []
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        let resultScVal = try await kit.transactionOperations.simulateAndExtractResult(
            hostFunction: hostFunction
        )

        guard case .u32(let count) = resultScVal else {
            throw ValidationException.invalidInput(
                field: "result",
                reason: "Expected U32 result from \(ContextRuleMethod.getContextRulesCount), got: \(resultScVal)"
            )
        }
        return count
    }

    // MARK: - Get All Context Rules (raw)

    /// Retrieves every active context rule on the connected contract as raw
    /// `SCValXDR` map payloads, observing the kit's configured scan upper
    /// bound (``OZSmartAccountConfig/maxContextRuleScanId``).
    ///
    /// The contract assigns monotonically increasing identifiers; when a rule
    /// is removed its slot becomes empty but the identifier is never reused,
    /// creating gaps. This method iterates identifiers from zero upward,
    /// skipping gaps reported as ``TransactionException/SimulationFailed`` by
    /// the underlying simulation, until either the active rule count has been
    /// collected or the configured scan upper bound is reached.
    ///
    /// - Returns: One raw `SCValXDR` per active context rule in ascending id
    ///   order.
    /// - Throws:
    ///   - ``WalletException/NotConnected`` when no wallet is connected.
    ///   - ``TransactionException`` for non-gap simulation failures.
    ///   - ``ValidationException`` when ``getContextRulesCount()`` returns a
    ///     non-`U32` value.
    public func getAllContextRules() async throws -> [SCValXDR] {
        let activeCount = try await getContextRulesCount()
        if activeCount == 0 { return [] }

        let maxScanId = kit.config.maxContextRuleScanId
        var result: [SCValXDR] = []
        result.reserveCapacity(Int(activeCount))

        var id: UInt32 = 0
        while id < maxScanId {
            try Task.checkCancellation()
            // why: stop as soon as the active rules have been collected per
            // D-121 — the count fetched at the start of the scan is the
            // authoritative termination signal. A "3-consecutive-miss" rule
            // would behave incorrectly with sparse identifier layouts.
            if UInt32(result.count) >= activeCount { break }
            do {
                let ruleScVal = try await getContextRule(id: id)
                result.append(ruleScVal)
            } catch is TransactionException.SimulationFailed {
                // Gap from a previously removed rule — skip and continue.
            }
            id &+= 1
        }

        return result
    }

    // MARK: - List Context Rules (parsed)

    /// Returns the parsed view of every active context rule on the connected
    /// smart account contract.
    ///
    /// Fetches the raw payloads through ``getAllContextRules()`` and parses
    /// each via ``parseContextRule(scVal:)``.
    ///
    /// - Returns: Parsed context rules in ascending rule-id order.
    /// - Throws:
    ///   - ``WalletException/NotConnected`` when no wallet is connected.
    ///   - ``TransactionException`` for simulation failures.
    ///   - ``ValidationException`` when a payload cannot be parsed or the
    ///     count is malformed.
    public func listContextRules() async throws -> [ParsedContextRule] {
        let raw = try await getAllContextRules()
        var result: [ParsedContextRule] = []
        result.reserveCapacity(raw.count)
        for scVal in raw {
            result.append(try parseContextRule(scVal: scVal))
        }
        return result
    }

    // MARK: - parseContextRule (internal, cross-manager surface per D-104)

    /// Parses a context rule from its on-chain `SCValXDR` representation.
    ///
    /// The on-chain shape is a Soroban named struct serialised as
    /// `SCVal::Map` with `Symbol`-keyed entries. Fields are looked up by name
    /// (see ``ContextRuleField``) rather than by positional index, so the
    /// parser is robust to the ordering chosen by the Soroban host.
    ///
    /// - Parameter scVal: The raw `SCValXDR` payload returned by the contract.
    /// - Returns: A parsed view of the rule.
    /// - Throws: ``ValidationException/InvalidInput`` when the payload is not
    ///   a map, when a required field is missing, when a field has the wrong
    ///   type, or when a nested discriminant is unknown.
    internal func parseContextRule(scVal: SCValXDR) throws -> ParsedContextRule {
        guard case .map(let mapEntries) = scVal, let mapEntries = mapEntries else {
            throw ValidationException.invalidInput(
                field: "contextRule",
                reason: "Expected Map ScVal for context rule, got: \(scVal)"
            )
        }

        // Build a name → value lookup, skipping any non-Symbol keys per the
        // contract ABI (the contract emits Symbol keys exclusively; other key
        // types are silently ignored to keep the parser resilient against
        // future ABI additions that introduce auxiliary metadata fields).
        var fields: [String: SCValXDR] = [:]
        fields.reserveCapacity(mapEntries.count)
        for entry in mapEntries {
            if case .symbol(let key) = entry.key {
                fields[key] = entry.val
            }
        }

        // id (U32)
        guard let idScVal = fields[ContextRuleField.id] else {
            throw ValidationException.invalidInput(
                field: "contextRule",
                reason: "Missing required field: \(ContextRuleField.id)"
            )
        }
        guard case .u32(let id) = idScVal else {
            throw ValidationException.invalidInput(
                field: ContextRuleField.id,
                reason: "Expected U32 for \(ContextRuleField.id), got: \(idScVal)"
            )
        }

        // name (String)
        guard let nameScVal = fields[ContextRuleField.name] else {
            throw ValidationException.invalidInput(
                field: "contextRule",
                reason: "Missing required field: \(ContextRuleField.name)"
            )
        }
        guard case .string(let name) = nameScVal else {
            throw ValidationException.invalidInput(
                field: ContextRuleField.name,
                reason: "Expected String for \(ContextRuleField.name), got: \(nameScVal)"
            )
        }

        // context_type (Vec discriminant)
        guard let contextTypeScVal = fields[ContextRuleField.contextType] else {
            throw ValidationException.invalidInput(
                field: "contextRule",
                reason: "Missing required field: \(ContextRuleField.contextType)"
            )
        }
        let contextType = try parseContextRuleType(scVal: contextTypeScVal)

        // signers (Vec of signer Vec discriminants) — optional, defaults to [].
        let signers: [any OZSmartAccountSigner]
        if let signersScVal = fields[ContextRuleField.signers] {
            guard case .vec(let signerVec) = signersScVal, let signerVec = signerVec else {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.signers,
                    reason: "Expected Vec for \(ContextRuleField.signers), got: \(signersScVal)"
                )
            }
            var parsed: [any OZSmartAccountSigner] = []
            parsed.reserveCapacity(signerVec.count)
            for entry in signerVec {
                parsed.append(try parseSigner(scVal: entry))
            }
            signers = parsed
        } else {
            signers = []
        }

        // signer_ids (Vec of U32) — optional, defaults to [].
        let signerIds: [UInt32]
        if let signerIdsScVal = fields[ContextRuleField.signerIds] {
            guard case .vec(let idsVec) = signerIdsScVal, let idsVec = idsVec else {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.signerIds,
                    reason: "Expected Vec for \(ContextRuleField.signerIds), got: \(signerIdsScVal)"
                )
            }
            var parsedIds: [UInt32] = []
            parsedIds.reserveCapacity(idsVec.count)
            for entry in idsVec {
                guard case .u32(let value) = entry else {
                    throw ValidationException.invalidInput(
                        field: ContextRuleField.signerIds,
                        reason: "Expected U32 entries in \(ContextRuleField.signerIds), got: \(entry)"
                    )
                }
                parsedIds.append(value)
            }
            signerIds = parsedIds
        } else {
            signerIds = []
        }

        // policies (Vec of Address) — optional, defaults to []. Each entry is
        // decoded to its strkey representation (C-address).
        let policies: [String]
        if let policiesScVal = fields[ContextRuleField.policies] {
            guard case .vec(let policiesVec) = policiesScVal, let policiesVec = policiesVec else {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.policies,
                    reason: "Expected Vec for \(ContextRuleField.policies), got: \(policiesScVal)"
                )
            }
            var addresses: [String] = []
            addresses.reserveCapacity(policiesVec.count)
            for entry in policiesVec {
                addresses.append(try parseAddressAcceptingAccount(scVal: entry))
            }
            policies = addresses
        } else {
            policies = []
        }

        // policy_ids (Vec of U32) — optional, defaults to [].
        let policyIds: [UInt32]
        if let policyIdsScVal = fields[ContextRuleField.policyIds] {
            guard case .vec(let idsVec) = policyIdsScVal, let idsVec = idsVec else {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.policyIds,
                    reason: "Expected Vec for \(ContextRuleField.policyIds), got: \(policyIdsScVal)"
                )
            }
            var parsedIds: [UInt32] = []
            parsedIds.reserveCapacity(idsVec.count)
            for entry in idsVec {
                guard case .u32(let value) = entry else {
                    throw ValidationException.invalidInput(
                        field: ContextRuleField.policyIds,
                        reason: "Expected U32 entries in \(ContextRuleField.policyIds), got: \(entry)"
                    )
                }
                parsedIds.append(value)
            }
            policyIds = parsedIds
        } else {
            policyIds = []
        }

        // valid_until (Option<U32> — Void = nil, U32 = expires-at-ledger)
        let validUntil: UInt32?
        if let validUntilScVal = fields[ContextRuleField.validUntil] {
            switch validUntilScVal {
            case .void:
                validUntil = nil
            case .u32(let value):
                validUntil = value
            default:
                throw ValidationException.invalidInput(
                    field: ContextRuleField.validUntil,
                    reason: "Expected U32 or Void for \(ContextRuleField.validUntil), got: \(validUntilScVal)"
                )
            }
        } else {
            validUntil = nil
        }

        return ParsedContextRule(
            id: id,
            contextType: contextType,
            name: name,
            signers: signers,
            signerIds: signerIds,
            policies: policies,
            policyIds: policyIds,
            validUntil: validUntil
        )
    }

    /// Parses the `context_type` field from its `Vec` discriminant
    /// representation.
    ///
    /// Format produced by the contract:
    /// - Default: `Vec([Symbol("Default")])`
    /// - CallContract: `Vec([Symbol("CallContract"), Address])`
    /// - CreateContract: `Vec([Symbol("CreateContract"), Bytes])`
    private func parseContextRuleType(scVal: SCValXDR) throws -> ContextRuleType {
        guard case .vec(let vec) = scVal, let vec = vec else {
            throw ValidationException.invalidInput(
                field: ContextRuleField.contextType,
                reason: "Expected Vec for \(ContextRuleField.contextType), got: \(scVal)"
            )
        }
        guard let firstElement = vec.first else {
            throw ValidationException.invalidInput(
                field: ContextRuleField.contextType,
                reason: "\(ContextRuleField.contextType) Vec is empty"
            )
        }
        guard case .symbol(let discriminant) = firstElement else {
            throw ValidationException.invalidInput(
                field: ContextRuleField.contextType,
                reason: "Expected Symbol discriminant in \(ContextRuleField.contextType) Vec, got: \(firstElement)"
            )
        }

        switch discriminant {
        case ContextTypeDiscriminant.defaultRule:
            return .defaultRule

        case ContextTypeDiscriminant.callContract:
            if vec.count < 2 {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.contextType,
                    reason: "\(ContextTypeDiscriminant.callContract) context_type missing address element"
                )
            }
            let address: String
            do {
                address = try parseAddressAcceptingAccount(scVal: vec[1])
            } catch {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.contextType,
                    reason: "Expected Address for \(ContextTypeDiscriminant.callContract) context_type, got: \(vec[1])",
                    cause: error
                )
            }
            return .callContract(contractAddress: address)

        case ContextTypeDiscriminant.createContract:
            if vec.count < 2 {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.contextType,
                    reason: "\(ContextTypeDiscriminant.createContract) context_type missing wasm hash element"
                )
            }
            guard case .bytes(let wasmHash) = vec[1] else {
                throw ValidationException.invalidInput(
                    field: ContextRuleField.contextType,
                    reason: "Expected Bytes for \(ContextTypeDiscriminant.createContract) context_type, got: \(vec[1])"
                )
            }
            return .createContract(wasmHash: wasmHash)

        default:
            throw ValidationException.invalidInput(
                field: ContextRuleField.contextType,
                reason: "Unknown \(ContextRuleField.contextType) discriminant: \(discriminant)"
            )
        }
    }

    /// Parses a signer from its `Vec` discriminant representation.
    ///
    /// Format produced by the contract:
    /// - Delegated: `Vec([Symbol("Delegated"), Address])`
    /// - External: `Vec([Symbol("External"), Address, Bytes])`
    private func parseSigner(scVal: SCValXDR) throws -> any OZSmartAccountSigner {
        guard case .vec(let vec) = scVal, let vec = vec else {
            throw ValidationException.invalidInput(
                field: "signer",
                reason: "Expected Vec for signer, got: \(scVal)"
            )
        }
        guard let firstElement = vec.first else {
            throw ValidationException.invalidInput(
                field: "signer",
                reason: "Signer Vec is empty"
            )
        }
        guard case .symbol(let discriminant) = firstElement else {
            throw ValidationException.invalidInput(
                field: "signer",
                reason: "Expected Symbol discriminant in signer Vec, got: \(firstElement)"
            )
        }

        switch discriminant {
        case SignerDiscriminant.delegated:
            if vec.count < 2 {
                throw ValidationException.invalidInput(
                    field: "signer",
                    reason: "\(SignerDiscriminant.delegated) signer missing address element"
                )
            }
            let address: String
            do {
                address = try parseAccountOrContractAddress(scVal: vec[1])
            } catch {
                throw ValidationException.invalidInput(
                    field: "signer",
                    reason: "Expected Address for \(SignerDiscriminant.delegated) signer, got: \(vec[1])",
                    cause: error
                )
            }
            return try OZDelegatedSigner(address: address)

        case SignerDiscriminant.external:
            if vec.count < 3 {
                throw ValidationException.invalidInput(
                    field: "signer",
                    reason: "\(SignerDiscriminant.external) signer missing address or keyData element"
                )
            }
            let verifierAddress: String
            do {
                verifierAddress = try parseAddressAcceptingAccount(scVal: vec[1])
            } catch {
                throw ValidationException.invalidInput(
                    field: "signer",
                    reason: "Expected Address for \(SignerDiscriminant.external) signer verifier, got: \(vec[1])",
                    cause: error
                )
            }
            guard case .bytes(let keyData) = vec[2] else {
                throw ValidationException.invalidInput(
                    field: "signer",
                    reason: "Expected Bytes for \(SignerDiscriminant.external) signer keyData, got: \(vec[2])"
                )
            }
            return try OZExternalSigner(verifierAddress: verifierAddress, keyData: keyData)

        default:
            throw ValidationException.invalidInput(
                field: "signer",
                reason: "Unknown signer discriminant: \(discriminant)"
            )
        }
    }

    /// Decodes an `SCValXDR.address` value, accepting both contract (`C…`)
    /// and account (`G…`) strkey forms.
    ///
    /// Used at parse sites where the contract ABI nominally expects a
    /// contract address (policy / verifier / call-contract target) but where
    /// account addresses are tolerated for the sake of forward compatibility
    /// with contract revisions that broaden the accepted address kind. The
    /// caller is responsible for asserting stricter constraints when the
    /// downstream consumer requires a contract-only address.
    private func parseAddressAcceptingAccount(scVal: SCValXDR) throws -> String {
        guard case .address(let scAddress) = scVal else {
            throw ValidationException.invalidInput(
                field: "address",
                reason: "Expected Address ScVal, got: \(scVal)"
            )
        }
        if case .contract(let wrapped) = scAddress {
            do {
                return try wrapped.wrapped.encodeContractId()
            } catch {
                throw ValidationException.invalidInput(
                    field: "address",
                    reason: "Failed to encode contract address: \(error.localizedDescription)",
                    cause: error
                )
            }
        }
        if let accountId = scAddress.accountId {
            // Accept account addresses too — context type / verifier addresses
            // should be contract-only in practice, but the underlying ABI is
            // generic Address, so honour both arms here and let the caller
            // assert constraints when needed.
            return accountId
        }
        throw ValidationException.invalidInput(
            field: "address",
            reason: "Unsupported SCAddressXDR variant: \(scAddress)"
        )
    }

    /// Decodes a generic `SCValXDR.address` into either its `G…` account
    /// strkey or `C…` contract strkey representation. Used by delegated
    /// signer parsing, where both kinds are valid.
    private func parseAccountOrContractAddress(scVal: SCValXDR) throws -> String {
        guard case .address(let scAddress) = scVal else {
            throw ValidationException.invalidInput(
                field: "address",
                reason: "Expected Address ScVal, got: \(scVal)"
            )
        }
        if let accountId = scAddress.accountId {
            return accountId
        }
        if case .contract(let wrapped) = scAddress {
            do {
                return try wrapped.wrapped.encodeContractId()
            } catch {
                throw ValidationException.invalidInput(
                    field: "address",
                    reason: "Failed to encode contract address: \(error.localizedDescription)",
                    cause: error
                )
            }
        }
        throw ValidationException.invalidInput(
            field: "address",
            reason: "Unsupported SCAddressXDR variant: \(scAddress)"
        )
    }

    // MARK: - Resolve Context Rule IDs

    /// Resolves the on-chain context-rule identifiers that should be bound
    /// into the signing digest for the supplied authorization entry.
    ///
    /// Fetches the active rule set via ``listContextRules()`` then delegates
    /// to the three-arg overload. Callers that need to resolve multiple auth
    /// entries inside the same transaction should fetch the rules once and
    /// invoke the three-arg overload directly to avoid redundant RPC round
    /// trips.
    ///
    /// - Parameters:
    ///   - entry: The authorization entry being signed.
    ///   - signers: The signer values participating in the current ceremony.
    /// - Returns: One identifier per invocation context (depth-first traversal
    ///   of the entry's invocation tree).
    /// - Throws: ``ValidationException``, ``TransactionException``.
    internal func resolveContextRuleIdsForEntry(
        entry: SorobanAuthorizationEntryXDR,
        signers: [any OZSmartAccountSigner]
    ) async throws -> [UInt32] {
        let rules = try await listContextRules()
        return try await resolveContextRuleIdsForEntry(
            entry: entry,
            signers: signers,
            contextRules: rules
        )
    }

    /// Resolves context rule identifiers using a pre-fetched rule list.
    ///
    /// Implements the three-tier resolution algorithm:
    /// 1. Filter rules by context-type match
    ///    (``contextRuleTypeMatches(ruleType:requiredType:)``).
    /// 2. If exactly one rule matches, use it (D-135 fast path).
    /// 3. **Tier 1** — exact signer match: same signer count plus bidirectional
    ///    containment between `signers` and the rule's signer list (D-135).
    /// 4. **Tier 2** — rule-signers-subset-of-selected with no policies: every
    ///    rule signer must appear in `signers`, and the rule must have no
    ///    installed policies (D-136 precondition).
    /// 5. **Tier 3** — selected-signers-subset-of-rule: every selected signer
    ///    must appear in the rule (threshold scenarios where the user picks
    ///    fewer signers than the rule has) (D-137).
    ///
    /// Failure semantics (D-138):
    /// - No candidates after the context-type filter → ``ValidationException``
    ///   advising the caller to add a Default rule.
    /// - Multiple candidates whose signer sets all contain every selected
    ///   signer → ``ValidationException`` listing the matching rule ids.
    /// - Candidates exist but none contains every selected signer →
    ///   ``ValidationException`` advising the caller that no rule contains all
    ///   selected signers.
    ///
    /// - Parameters:
    ///   - entry: The authorization entry being signed.
    ///   - signers: The signer values participating in the current ceremony.
    ///   - contextRules: Pre-fetched rule list.
    /// - Returns: One identifier per invocation context.
    /// - Throws: ``ValidationException`` for unresolvable or ambiguous cases.
    public func resolveContextRuleIdsForEntry(
        entry: SorobanAuthorizationEntryXDR,
        signers: [any OZSmartAccountSigner],
        contextRules: [ParsedContextRule]
    ) async throws -> [UInt32] {
        let contexts = try buildInvocationContextTypes(entry: entry)
        var result: [UInt32] = []
        result.reserveCapacity(contexts.count)

        for contextType in contexts {
            let candidates = contextRules.filter { rule in
                contextRuleTypeMatches(ruleType: rule.contextType, requiredType: contextType)
            }

            // why: a single candidate is unambiguous regardless of signer
            // overlap — the caller already chose to sign with this rule by
            // installing it as the sole matcher for this context type.
            if candidates.count == 1 {
                result.append(candidates[0].id)
                continue
            }

            // Tier 1: bidirectional exact match between selected signers and rule signers.
            let exactSignerMatches = candidates.filter { rule in
                if rule.signers.count != signers.count { return false }
                let allSelectedInRule = signers.allSatisfy { selected in
                    rule.signers.contains { OZSmartAccountBuilders.signersEqual($0, selected) }
                }
                let allRuleInSelected = rule.signers.allSatisfy { ruleSigner in
                    signers.contains { OZSmartAccountBuilders.signersEqual(ruleSigner, $0) }
                }
                return allSelectedInRule && allRuleInSelected
            }
            if exactSignerMatches.count == 1 {
                result.append(exactSignerMatches[0].id)
                continue
            }

            // Tier 2: rule signers are a subset of selected and the rule has no policies (D-136).
            let signerSubsetMatches = candidates.filter { rule in
                if !rule.policies.isEmpty { return false }
                return rule.signers.allSatisfy { ruleSigner in
                    signers.contains { OZSmartAccountBuilders.signersEqual(ruleSigner, $0) }
                }
            }
            if signerSubsetMatches.count == 1 {
                result.append(signerSubsetMatches[0].id)
                continue
            }

            // Tier 3: selected signers are a subset of the rule's signers.
            let selectedSubsetMatches = candidates.filter { rule in
                signers.allSatisfy { selected in
                    rule.signers.contains { OZSmartAccountBuilders.signersEqual($0, selected) }
                }
            }
            if selectedSubsetMatches.count == 1 {
                result.append(selectedSubsetMatches[0].id)
                continue
            }

            // Failure paths (D-138).
            if candidates.isEmpty {
                throw ValidationException.invalidInput(
                    field: "contextRuleIds",
                    reason: "No context rule matches \(contextType). Add a rule for this context type or a Default rule."
                )
            }

            // Collect every candidate whose signer set contains every selected signer.
            let containsAll = candidates.filter { rule in
                signers.allSatisfy { selected in
                    rule.signers.contains { OZSmartAccountBuilders.signersEqual($0, selected) }
                }
            }
            if containsAll.count > 1 {
                let ids = containsAll.map { String($0.id) }.joined(separator: ", ")
                throw ValidationException.invalidInput(
                    field: "contextRuleIds",
                    reason: "Selected signers match multiple context rules: \(ids)."
                )
            }

            throw ValidationException.invalidInput(
                field: "contextRuleIds",
                reason: "No context rule contains all selected signers."
            )
        }

        return result
    }

    // MARK: - Invocation tree traversal

    /// Extracts the context-type list from an auth entry's invocation tree.
    ///
    /// Walks the root invocation followed by every sub-invocation (depth-first)
    /// and emits one ``ContextRuleType`` per invocation node:
    /// - `contractFn` produces ``ContextRuleType/callContract(contractAddress:)``
    ///   with the invocation's contract address.
    /// - `createContractHostFn` / `createContractV2HostFn` produce
    ///   ``ContextRuleType/createContract(wasmHash:)`` with the executable's
    ///   WASM hash. Stellar Asset Contract executables throw because they have
    ///   no WASM hash.
    private func buildInvocationContextTypes(
        entry: SorobanAuthorizationEntryXDR
    ) throws -> [ContextRuleType] {
        var result: [ContextRuleType] = []
        try collectInvocationContextTypes(
            function: entry.rootInvocation.function,
            into: &result
        )
        try collectSubInvocationContextTypes(
            subInvocations: entry.rootInvocation.subInvocations,
            into: &result
        )
        return result
    }

    private func collectInvocationContextTypes(
        function: SorobanAuthorizedFunctionXDR,
        into result: inout [ContextRuleType]
    ) throws {
        switch function {
        case .contractFn(let invokeArgs):
            let address: String
            do {
                address = try addressString(from: invokeArgs.contractAddress)
            } catch {
                throw ValidationException.invalidInput(
                    field: "contractAddress",
                    reason: "Failed to parse contract address from ContractFn invocation: \(error.localizedDescription)",
                    cause: error
                )
            }
            result.append(.callContract(contractAddress: address))

        case .createContractHostFn(let args):
            let wasmHash = try extractWasmHash(executable: args.executable)
            result.append(.createContract(wasmHash: wasmHash))

        case .createContractV2HostFn(let args):
            let wasmHash = try extractWasmHash(executable: args.executable)
            result.append(.createContract(wasmHash: wasmHash))
        }
    }

    private func collectSubInvocationContextTypes(
        subInvocations: [SorobanAuthorizedInvocationXDR],
        into result: inout [ContextRuleType]
    ) throws {
        for subInvocation in subInvocations {
            try collectInvocationContextTypes(
                function: subInvocation.function,
                into: &result
            )
            try collectSubInvocationContextTypes(
                subInvocations: subInvocation.subInvocations,
                into: &result
            )
        }
    }

    /// Extracts a WASM hash from a ``ContractExecutableXDR``. Stellar Asset
    /// Contract executables (the `.token` arm) carry no WASM hash; attempting
    /// to use them as a `CreateContract` context-rule target throws.
    private func extractWasmHash(executable: ContractExecutableXDR) throws -> Data {
        switch executable {
        case .wasm(let hash):
            return Data(hash.wrapped)
        case .token:
            throw ValidationException.invalidInput(
                field: "executable",
                reason: "CreateContract invocation references a Stellar Asset Contract, not a WASM contract"
            )
        }
    }

    /// Decodes an `SCAddressXDR` to its strkey form. Mirrors the helper used
    /// in ``OZSmartAccountAuthPayload`` so the entire OZ module shares one
    /// canonical address-stringification routine.
    private func addressString(from scAddress: SCAddressXDR) throws -> String {
        if let accountId = scAddress.accountId {
            return accountId
        }
        if case .contract(let wrapped) = scAddress {
            return try wrapped.wrapped.encodeContractId()
        }
        throw ValidationException.invalidInput(
            field: "address",
            reason: "Unsupported SCAddressXDR variant: \(scAddress)"
        )
    }

    // MARK: - Context Rule Type Matching

    /// Returns `true` when the rule's context type matches the required
    /// context type.
    ///
    /// ``ContextRuleType/defaultRule`` matches any required context type (the
    /// fallback semantics intended by the contract); every other arm requires
    /// exact equality.
    private func contextRuleTypeMatches(
        ruleType: ContextRuleType,
        requiredType: ContextRuleType
    ) -> Bool {
        if case .defaultRule = ruleType { return true }
        return ruleType == requiredType
    }

    // MARK: - Update Context Rule Name

    /// Updates the human-readable name of an existing context rule.
    ///
    /// The on-chain `name` field is metadata only — it has no effect on rule
    /// matching or enforcement.
    ///
    /// - Parameters:
    ///   - id: The context-rule identifier to update.
    ///   - name: The new name (must be non-empty).
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected``,
    ///   ``ValidationException/InvalidInput``, ``TransactionException``.
    public func updateName(
        id: UInt32,
        name: String,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        if name.isEmpty {
            throw ValidationException.invalidInput(
                field: "name",
                reason: "Context rule name cannot be empty"
            )
        }

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: ContextRuleMethod.updateContextRuleName,
            args: [
                .u32(id),
                .string(name)
            ]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Update Context Rule Valid Until

    /// Updates the expiration ledger of an existing context rule.
    ///
    /// Pass `nil` to clear the expiration (the rule becomes non-expiring).
    /// On chain the field is `Option<u32>`, encoded as `Void` for `None` and
    /// `U32` for `Some`.
    ///
    /// - Parameters:
    ///   - id: The context-rule identifier to update.
    ///   - validUntil: The new expiration ledger, or `nil` to clear.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected``, ``TransactionException``.
    public func updateValidUntil(
        id: UInt32,
        validUntil: UInt32?,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        let validUntilScVal: SCValXDR
        if let validUntil = validUntil {
            validUntilScVal = .u32(validUntil)
        } else {
            validUntilScVal = .void
        }

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: ContextRuleMethod.updateContextRuleValidUntil,
            args: [
                .u32(id),
                validUntilScVal
            ]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Remove Context Rule

    /// Removes a context rule from the connected smart account.
    ///
    /// Removed rules leave a numeric gap in the identifier sequence that
    /// ``getAllContextRules()`` skips during enumeration.
    ///
    /// - Parameters:
    ///   - id: The context-rule identifier to remove.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected``, ``TransactionException``.
    public func removeContextRule(
        id: UInt32,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: ContextRuleMethod.removeContextRule,
            args: [.u32(id)]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Private routing helpers

    /// Routes a host-function submission to either the single-signer or
    /// multi-signer code path based on the supplied `selectedSigners` list.
    ///
    /// Thin forwarding wrapper over ``OZSubmissionRouter/route(hostFunction:selectedSigners:forceMethod:kit:multiSignerSubmitter:managerName:)``
    /// that carries the manager-specific configuration-error name.
    private func routeSubmission(
        hostFunction: HostFunctionXDR,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod?
    ) async throws -> TransactionResult {
        return try await OZSubmissionRouter.route(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod,
            kit: kit,
            multiSignerSubmitter: multiSignerSubmitter,
            managerName: "context rule manager"
        )
    }
}
