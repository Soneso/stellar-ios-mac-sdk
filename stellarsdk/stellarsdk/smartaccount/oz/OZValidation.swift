//
//  OZValidation.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// Address validation helpers
// ============================================================================

/// Validates that the supplied string is a valid Stellar contract address (`C…`).
///
/// Uses full StrKey validation including the CRC16 checksum. Throws when the
/// supplied value is not a syntactically valid contract address.
///
/// - Parameters:
///   - address: The address string to validate.
///   - fieldName: The field name embedded in the error message so callers can
///     identify which input failed validation.
/// - Throws: ``ValidationException/InvalidAddress`` when `address` is not a
///   valid contract address.
internal func requireContractAddress(_ address: String, fieldName: String) throws {
    if !address.isValidContractId() {
        throw ValidationException.InvalidAddress(
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
/// - Throws: ``ValidationException/InvalidAddress`` when `address` is not a
///   valid Stellar account or contract address.
internal func requireStellarAddress(_ address: String, fieldName: String) throws {
    if !address.isValidEd25519PublicKey() && !address.isValidContractId() {
        throw ValidationException.InvalidAddress(
            message: "\(fieldName) must be a valid Stellar address (G... or C...), got: \(address)"
        )
    }
}

/// Returns `true` when the supplied URL is a localhost URL safe for development.
///
/// Matches `http://localhost` exactly, or followed by `:` (port) or `/` (path).
/// URLs such as `http://localhost.evil.com` are deliberately rejected.
///
/// - Parameter url: The URL string to check.
/// - Returns: `true` when the URL refers to localhost over HTTP, otherwise `false`.
internal func isLocalhostUrl(_ url: String) -> Bool {
    let prefix = "http://localhost"
    if !url.hasPrefix(prefix) { return false }
    let suffix = url.dropFirst(prefix.count)
    if suffix.isEmpty { return true }
    // why: an explicit boundary check on the character following "localhost"
    // is what rejects host-confusion attacks such as "http://localhost.evil.com".
    // A naive `hasPrefix` test would accept that string and route traffic to an
    // attacker-controlled host.
    let first = suffix[suffix.startIndex]
    return first == ":" || first == "/"
}
