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
