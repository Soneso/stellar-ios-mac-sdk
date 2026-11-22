//
//  OZValidation.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Address validation helpers

/// Validates that the supplied string is a valid Stellar contract address (`C…`).
///
/// Uses full StrKey validation including the CRC16 checksum. Throws when the
/// supplied value is not a syntactically valid contract address.
///
/// - Parameters:
///   - address: The address string to validate.
///   - fieldName: The field name embedded in the error message so callers can
///     identify which input failed validation.
/// - Throws: ``SmartAccountValidationException/InvalidAddress`` when `address` is not a
///   valid contract address.
internal func requireContractAddress(_ address: String, fieldName: String) throws {
    if !address.isValidContractId() {
        throw SmartAccountValidationException.InvalidAddress(
            message: "\(fieldName) must be a valid contract address (C...), got: \(address)"
        )
    }
}

/// Validates that the supplied string is a valid Stellar address (`G…` account
/// or `C…` contract).
///
/// Uses full StrKey validation including the CRC16 checksum. Muxed `M…`
/// addresses are deliberately rejected; only standard ed25519 accounts and
/// contract addresses are accepted.
///
/// - Parameters:
///   - address: The address string to validate.
///   - fieldName: The field name embedded in the error message so callers can
///     identify which input failed validation.
/// - Throws: ``SmartAccountValidationException/InvalidAddress`` when `address` is not a
///   valid Stellar account or contract address.
internal func requireStellarAddress(_ address: String, fieldName: String) throws {
    if !address.isValidEd25519PublicKey() && !address.isValidContractId() {
        throw SmartAccountValidationException.InvalidAddress(
            message: "\(fieldName) must be a valid Stellar address (G... or C...), got: \(address)"
        )
    }
}

/// Returns `true` when the supplied URL is a localhost URL safe for development.
///
/// Parses the URL via `URLComponents` and requires the resolved host to match
/// `localhost`, `127.0.0.1`, or `[::1]` exactly. URLs that smuggle a different
/// host through userinfo (for example `http://localhost:8080@evil.com/`, where
/// RFC 3986 parses `localhost:8080` as userinfo and `evil.com` as the host) are
/// rejected, as are any URLs that carry userinfo at all.
///
/// - Parameter url: The URL string to check.
/// - Returns: `true` when the URL refers to localhost over HTTP, otherwise `false`.
internal func isLocalhostUrl(_ url: String) -> Bool {
    guard let components = URLComponents(string: url),
          components.scheme?.lowercased() == "http" else {
        return false
    }
    guard let host = components.host?.lowercased() else {
        return false
    }
    if host != "localhost" && host != "127.0.0.1" && host != "[::1]" {
        return false
    }
    // why: even with a localhost host, the presence of userinfo signals an
    // attempted host-confusion attack — reject it outright rather than risk
    // a parser disagreement between this check and `URLSession`.
    if components.user != nil || components.password != nil {
        return false
    }
    return true
}

// MARK: - Function name validation

/// Validates that `targetFn` is non-blank after trimming whitespace.
///
/// - Parameter targetFn: The function name to validate.
/// - Throws: `SmartAccountValidationException.invalidInput` when `targetFn` is empty or whitespace-only.
internal func requireNonBlankFunctionName(_ targetFn: String) throws {
    if targetFn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw SmartAccountValidationException.invalidInput(
            field: "targetFn",
            reason: "Function name cannot be empty"
        )
    }
}

// MARK: - Contract limit validation

/// Validates a context rule name: non-empty and within the OpenZeppelin contract's
/// ``OZConstants/maxNameSize``-byte (UTF-8) limit. Rejecting oversized names
/// client-side turns an opaque on-chain failure into a clear error before submission.
///
/// - Parameter name: The context rule name to validate.
/// - Throws: ``SmartAccountValidationException/InvalidInput`` when the name is empty
///   or exceeds the byte limit.
internal func requireValidContextRuleName(_ name: String) throws {
    if name.isEmpty {
        throw SmartAccountValidationException.invalidInput(
            field: "name",
            reason: "Context rule name cannot be empty"
        )
    }
    let byteLength = name.utf8.count
    if byteLength > OZConstants.maxNameSize {
        throw SmartAccountValidationException.invalidInput(
            field: "name",
            reason: "Context rule name cannot exceed \(OZConstants.maxNameSize) bytes, got: \(byteLength)"
        )
    }
}

/// Validates signers that are about to be added to the smart account `walletContractId`.
///
/// A Delegated signer must be a Stellar account (`G…`) other than the shared default
/// deployer (``OZSmartAccountConfig/createDefaultDeployer()``). A contract delegate can let
/// anyone authorize the account without a key (GHSA-jpg9-m7w4-c7wc), the wallet itself
/// included, and the default deployer's secret derives from a public string. An External
/// signer's key data must not exceed the OpenZeppelin contract's
/// ``OZConstants/maxExternalKeySize``-byte limit.
///
/// Signers already on a wallet are not checked here; reading them never fails on these
/// rules.
///
/// - Parameters:
///   - signers: The signers to validate.
///   - walletContractId: The smart account the signers are added to (`C…`).
/// - Throws: ``SmartAccountValidationException/InvalidInput`` when a Delegated signer is the
///   default deployer or the wallet itself, or when an External signer's key data is too
///   large; ``SmartAccountValidationException/InvalidAddress`` when a Delegated signer is not
///   a `G…` address; ``SmartAccountConfigurationException/InvalidConfig`` when the default
///   deployer cannot be derived.
internal func requireValidSigners(
    _ signers: [any OZSmartAccountSigner],
    walletContractId: String
) async throws {
    var rules = OZAddedSignerRules(walletContractId: walletContractId)
    for signer in signers {
        if let delegated = signer as? OZDelegatedSigner {
            try await rules.requireValidDelegate(delegated.address)
        } else if let external = signer as? OZExternalSigner {
            try requireExternalKeySize(external.keyData)
        }
    }
}

/// Validates, with the rules of ``requireValidSigners(_:walletContractId:)``, every signer
/// that an `add_signer`, `batch_add_signer` or `add_context_rule` call on the smart account
/// `walletContractId` adds, anywhere in the invocation tree of `entry`.
///
/// The signing pipelines run this over each smart account entry before they ask any signer,
/// so a transaction built from raw contract calls cannot add a Delegated signer that
/// `OZSignerManager.addDelegated` or `OZContextRuleManager.addContextRule` refuses. The rules
/// apply to the fields of each signer value as the contract stores them, without the checks
/// of ``OZDelegatedSigner`` and ``OZExternalSigner``: an External signer with empty key data
/// or with a verifier that is no contract passes, as the contract and the smart-account-kit
/// accept it, while a muxed contract address (`W…`) as a Delegated address or an External
/// verifier fails, as the kit refuses it. A call without the signer argument is left to the
/// contract, which rejects it.
///
/// - Parameters:
///   - entry: The smart account authorization entry whose invocation tree is checked.
///   - walletContractId: The smart account (`C…`) whose signer-adding calls are checked.
/// - Throws: ``SmartAccountValidationException`` when an added signer fails the rules, or
///   when the signer list argument of `batch_add_signer` or `add_context_rule` is not a
///   `Vec`; `SmartAccountTransactionException.SigningFailed` when an added signer is not a
///   signer value.
internal func requireValidAddedSigners(
    entry: SorobanAuthorizationEntryXDR,
    walletContractId: String
) async throws {
    var rules = OZAddedSignerRules(walletContractId: walletContractId)
    var pending: [SorobanAuthorizedInvocationXDR] = [entry.rootInvocation]
    var nextIndex = 0
    while nextIndex < pending.count {
        let invocation = pending[nextIndex]
        nextIndex += 1
        pending.append(contentsOf: invocation.subInvocations)

        guard case .contractFn(let call) = invocation.function,
              let functionName = call.functionNameString,
              let position = signerArgumentPosition(functionName: functionName),
              OZAddressStrKey.fromXdr(call.contractAddress) == walletContractId,
              call.args.count > position.index else {
            continue
        }

        let argument = call.args[position.index]
        let signerValues: [SCValXDR]
        if !position.isList {
            signerValues = [argument]
        } else if case .vec(let values) = argument {
            signerValues = values ?? []
        } else {
            let argumentType = SCValType(rawValue: argument.type())?.enumName() ?? String(argument.type())
            throw SmartAccountValidationException.invalidInput(
                field: "signers",
                reason: "\(functionName) on \(walletContractId) carries \(argumentType) at argument \(position.index), where a Vec of signers is expected"
            )
        }
        for value in signerValues {
            try await requireValidAddedSignerValue(value, rules: &rules)
        }
    }
}

/// The argument of a wallet function that adds signers, and whether it is a `Vec` of
/// signers, by the stellar-accounts 0.8.0 signatures: `add_signer(context_rule_id, signer)`,
/// `batch_add_signer(context_rule_id, signers)` and
/// `add_context_rule(context_type, name, valid_until, signers, policies)`. `nil` for every
/// other function.
private func signerArgumentPosition(functionName: String) -> (index: Int, isList: Bool)? {
    switch functionName {
    case "add_signer":
        return (index: 1, isList: false)
    case "batch_add_signer":
        return (index: 1, isList: true)
    case "add_context_rule":
        return (index: 3, isList: true)
    default:
        return nil
    }
}

/// Applies the rules of ``requireValidSigners(_:walletContractId:)`` to one raw signer
/// `value`, read field by field as the contract stores it.
private func requireValidAddedSignerValue(
    _ value: SCValXDR,
    rules: inout OZAddedSignerRules
) async throws {
    guard case .vec(let vecElements) = value, let elements = vecElements, !elements.isEmpty else {
        throw SmartAccountTransactionException.signingFailed(
            reason: "Signer ScVal is not a non-empty Vec, got: \(value.messageText)"
        )
    }
    guard case .symbol(let tag) = elements[0] else {
        throw SmartAccountTransactionException.signingFailed(
            reason: "First element of signer Vec is not a Symbol, got: \(elements[0].messageText)"
        )
    }
    switch tag {
    case SignerDiscriminant.delegated:
        guard elements.count >= 2, case .address(let address) = elements[1] else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Delegated signer second element is not an Address, got: \(value.messageText)"
            )
        }
        try refuseMuxedContract(address, field: "Delegated signer address")
        let strKey = try address.toStrKey()
        try await rules.requireValidDelegate(strKey)
    case SignerDiscriminant.external:
        guard elements.count >= 3,
              case .address(let verifier) = elements[1],
              case .bytes(let keyData) = elements[2] else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "External signer Vec must hold an Address and Bytes, got: \(value.messageText)"
            )
        }
        try refuseMuxedContract(verifier, field: "External signer verifier address")
        try requireExternalKeySize(keyData)
    default:
        throw SmartAccountTransactionException.signingFailed(
            reason: "Unknown signer type tag: '\(tag)'"
        )
    }
}

/// Refuses a signer `address` of the muxed contract type (`W…`), which the
/// smart-account-kit cannot convert to a strkey and refuses; every other address type
/// passes.
private func refuseMuxedContract(_ address: SCAddressXDR, field: String) throws {
    if case .muxedContract = address {
        let strKey = try address.toStrKey()
        throw SmartAccountValidationException.invalidInput(
            field: "signer",
            reason: "\(field) has an unsupported address type: \(SCAddressType.muxedContract.enumName()), got: \(strKey)"
        )
    }
}

/// Refuses External signer key data above ``OZConstants/maxExternalKeySize`` bytes.
private func requireExternalKeySize(_ keyData: Data) throws {
    if keyData.count > OZConstants.maxExternalKeySize {
        throw SmartAccountValidationException.invalidInput(
            field: "keyData",
            reason: "External signer key data cannot exceed \(OZConstants.maxExternalKeySize) bytes, got: \(keyData.count)"
        )
    }
}

/// The Delegated signer rules for one validation pass over signers added to the smart
/// account `walletContractId`; the shared default deployer's address is derived once per
/// pass, at the first Delegated signer.
private struct OZAddedSignerRules {

    let walletContractId: String

    private var defaultDeployerAddress: String?

    init(walletContractId: String) {
        self.walletContractId = walletContractId
    }

    /// Refuses the shared default deployer, the wallet itself and every address that is not
    /// a `G…` account, in that order.
    mutating func requireValidDelegate(_ address: String) async throws {
        let defaultDeployer: String
        if let derived = defaultDeployerAddress {
            defaultDeployer = derived
        } else {
            defaultDeployer = try await OZSmartAccountConfig.createDefaultDeployer().accountId
            defaultDeployerAddress = defaultDeployer
        }
        if address == defaultDeployer {
            throw SmartAccountValidationException.invalidInput(
                field: "signer",
                reason: "The shared default deployer \(address) cannot be a delegated signer: its secret derives from a public string, so anyone could authorize the account through it"
            )
        }
        if address == walletContractId {
            throw SmartAccountValidationException.invalidInput(
                field: "signer",
                reason: "The smart account \(walletContractId) cannot be its own delegated signer"
            )
        }
        if !address.isValidEd25519PublicKey() {
            throw SmartAccountValidationException.InvalidAddress(
                message: "A delegated signer must be a Stellar account (G-address), got: \(address). Delegating to a contract can let anyone authorize the account."
            )
        }
    }
}

/// Validates constructor / context-rule policies: at most ``OZConstants/maxPolicies``
/// entries, each keyed by a valid contract address (`C…`). The values are pre-encoded
/// install-param ScVals and are not inspected here.
///
/// - Parameter policies: Policy install params keyed by policy contract address.
/// - Throws: ``SmartAccountValidationException/InvalidInput`` when too many policies
///   are supplied; ``SmartAccountValidationException/InvalidAddress`` when a policy
///   key is not a valid contract address.
internal func requireValidPolicies(_ policies: [String: SCValXDR]) throws {
    if policies.count > OZConstants.maxPolicies {
        throw SmartAccountValidationException.invalidInput(
            field: "policies",
            reason: "Cannot install more than \(OZConstants.maxPolicies) policies, got: \(policies.count)"
        )
    }
    for (address, _) in policies {
        try requireContractAddress(address, fieldName: "policyAddress")
    }
}

// MARK: - Endpoint validation/normalization

/// Validates and normalises a service endpoint URL for use by the OZ clients.
///
/// Trims whitespace, rejects empty strings, requires `https://` or localhost,
/// strips trailing slashes, then re-parses to confirm a non-empty host is present.
/// The normalised URL (no trailing slashes) is returned on success.
///
/// - Parameters:
///   - url: The raw URL string supplied by the caller.
///   - label: Human-readable label used in error messages (e.g. `"Indexer"`, `"Relayer"`).
/// - Returns: Normalised URL string with no trailing slashes.
/// - Throws: `SmartAccountConfigurationException.invalidConfig` when the URL is empty, does not
///   satisfy the HTTPS / localhost constraint, or has no host component.
internal func ozValidateAndNormalizeEndpoint(_ url: String, label: String) throws -> String {
    let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedUrl.isEmpty {
        throw SmartAccountConfigurationException.invalidConfig(details: "\(label) URL is required")
    }
    if !trimmedUrl.hasPrefix("https://") && !isLocalhostUrl(trimmedUrl) {
        throw SmartAccountConfigurationException.invalidConfig(
            details: "\(label) URL must use HTTPS (or http://localhost for development): \(trimmedUrl)"
        )
    }
    var stripped = trimmedUrl
    while stripped.hasSuffix("/") {
        stripped.removeLast()
    }
    // why: stripping trailing slashes can leave a scheme-only string (for
    // example "https://" → "https:") that the prefix check still treats as
    // valid; reject any result without a non-empty host so request-time
    // failures don't surface as opaque URL errors.
    guard let components = URLComponents(string: stripped),
          let host = components.host, !host.isEmpty else {
        throw SmartAccountConfigurationException.invalidConfig(
            details: "\(label) URL must include a host: \(trimmedUrl)"
        )
    }
    return stripped
}

// MARK: - Address conversion

/// Internal helpers for translating Soroban `SCAddressXDR` values into canonical
/// Stellar strkey strings.
///
/// The smart-account managers compare auth-entry addresses against user-supplied
/// wallet account addresses (`G…`) and contract addresses (`C…`). This helper unifies
/// both shapes into the canonical strkey form so downstream comparisons can use plain
/// string equality.
enum OZAddressStrKey {

    /// Returns the canonical strkey representation of `scAddress`: an account address
    /// (`G…`/`M…`) for account variants or a contract address (`C…`) for contract
    /// variants. Returns `nil` for unsupported variants, or if contract-id encoding
    /// fails (unreachable for a well-formed `.contract` payload).
    static func fromXdr(_ scAddress: SCAddressXDR) -> String? {
        if let accountId = scAddress.accountId {
            return accountId
        }
        if case .contract(let wrapped) = scAddress {
            return try? wrapped.wrapped.encodeContractId()
        }
        return nil
    }
}
