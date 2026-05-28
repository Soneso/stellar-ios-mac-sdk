//
//  OZContextRuleManager+Parsing.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Read-side decoding helpers for ``OZContextRuleManager``. Co-located with
//  the writer / argument-builder side in ``OZContextRuleManager.swift`` (same
//  directory) so a single edit to a contract-ABI field name (see
//  ``ContextRuleField``, ``ContextTypeDiscriminant``, ``SignerDiscriminant``)
//  covers both encode and decode paths and the file-pair ABI surface remains
//  the single source of truth.
//

import Foundation

// ============================================================================
// MARK: - OZContextRuleManager parsing extension
// ============================================================================

extension OZContextRuleManager {

    // MARK: - parseContextRule

    /// Parses a context rule from its on-chain `SCValXDR` representation.
    ///
    /// The on-chain shape is a Soroban named struct serialised as
    /// `SCVal::Map` with `Symbol`-keyed entries. Fields are looked up by name
    /// (see ``ContextRuleField``) rather than by positional index, so the
    /// parser tolerates any field ordering chosen by the Soroban host.
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

    // MARK: - Private parsing helpers

    /// Parses the `context_type` field from its `Vec` discriminant
    /// representation.
    ///
    /// Format produced by the contract:
    /// - Default: `Vec([Symbol("Default")])`
    /// - CallContract: `Vec([Symbol("CallContract"), Address])`
    /// - CreateContract: `Vec([Symbol("CreateContract"), Bytes])`
    fileprivate func parseContextRuleType(scVal: SCValXDR) throws -> ContextRuleType {
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
    /// - External: `Vec([Symbol("External"), Address, Bytes])` — the verifier
    ///   address must be a contract address (`C…`); G-addresses are rejected
    ///   because the on-chain `External` signer dispatches to a verifier
    ///   contract and an account address cannot satisfy that role.
    fileprivate func parseSigner(scVal: SCValXDR) throws -> any OZSmartAccountSigner {
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
            // why: the OZ contract dispatches an `External` signer through its
            // verifier contract. An account (`G…`) address cannot host a
            // verifier method, so reject anything that is not a strict
            // contract (`C…`) address here rather than constructing a signer
            // that would silently fail at submission time.
            let verifierAddress: String
            do {
                verifierAddress = try parseContractAddress(scVal: vec[1])
            } catch {
                throw ValidationException.invalidInput(
                    field: "signer",
                    reason: "Expected contract address for \(SignerDiscriminant.external) signer verifier, got: \(vec[1])",
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
    /// contract address (policy / call-contract target) but where account
    /// addresses are tolerated for forward compatibility with contract
    /// revisions that broaden the accepted address kind. The caller is
    /// responsible for asserting stricter constraints when the downstream
    /// consumer requires a contract-only address — see ``parseContractAddress(scVal:)``.
    fileprivate func parseAddressAcceptingAccount(scVal: SCValXDR) throws -> String {
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
            // Accept account addresses too — context type / target addresses
            // are nominally contract-only in the contract ABI but the
            // underlying arm is generic Address; honour both kinds here and
            // let the caller assert constraints when needed.
            return accountId
        }
        throw ValidationException.invalidInput(
            field: "address",
            reason: "Unsupported SCAddressXDR variant: \(scAddress)"
        )
    }

    /// Decodes an `SCValXDR.address` value as a strict contract (`C…`)
    /// strkey. G-addresses produce ``ValidationException/InvalidInput``.
    ///
    /// Used at parse sites where the contract ABI requires a contract
    /// address (for example, the verifier address in an `External` signer).
    /// Surfaces a clear validation error rather than masking a malformed
    /// on-chain record by tolerating an account address.
    fileprivate func parseContractAddress(scVal: SCValXDR) throws -> String {
        guard case .address(let scAddress) = scVal else {
            throw ValidationException.invalidInput(
                field: "address",
                reason: "Expected Address ScVal, got: \(scVal)"
            )
        }
        switch scAddress {
        case .contract(let wrapped):
            do {
                return try wrapped.wrapped.encodeContractId()
            } catch {
                throw ValidationException.invalidInput(
                    field: "address",
                    reason: "Failed to encode contract address: \(error.localizedDescription)",
                    cause: error
                )
            }
        default:
            let observed = scAddress.accountId ?? "\(scAddress)"
            throw ValidationException.invalidInput(
                field: "address",
                reason: "Expected contract address (C...), got non-contract address: \(observed)"
            )
        }
    }

    /// Decodes a generic `SCValXDR.address` into either its `G…` account
    /// strkey or `C…` contract strkey representation. Used by delegated
    /// signer parsing, where both kinds are valid.
    fileprivate func parseAccountOrContractAddress(scVal: SCValXDR) throws -> String {
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
}
