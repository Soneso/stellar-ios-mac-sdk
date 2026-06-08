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
