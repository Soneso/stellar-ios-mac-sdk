//
//  FederationError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 22/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur during SEP-0002 federation operations.
///
/// This enumeration represents all possible failure cases when resolving Stellar addresses,
/// performing reverse lookups, or communicating with federation servers.
public enum FederationError: Error, Sendable {

    /// The provided Stellar address format is invalid.
    ///
    /// Occurs when the address does not contain the required "*" separator or does not
    /// follow the "username*domain.tld" format.
    ///
    /// Example invalid addresses: "alice", "alice@example.com", "alice*"
    case invalidAddress

    /// The provided Stellar account ID format is invalid.
    ///
    /// Occurs when attempting reverse lookup with an account ID that is not a valid
    /// Stellar public key (must start with G and be 56 characters total).
    ///
    /// Example: "INVALID123" or malformed public keys
    case invalidAccountId

    /// The domain extracted from the Stellar address is invalid.
    ///
    /// Occurs when the domain portion of the address does not conform to RFC 1035
    /// domain name specifications.
    case invalidDomain

    /// The domain specified for stellar.toml lookup is invalid.
    ///
    /// Occurs when attempting to fetch stellar.toml from a domain that does not
    /// meet the required format or cannot be resolved.
    case invalidTomlDomain

    /// The stellar.toml file could not be parsed or contains invalid data.
    ///
    /// Occurs when the stellar.toml file is malformed, missing required fields,
    /// or contains syntax errors.
    case invalidToml

    /// The stellar.toml file does not specify a federation server.
    ///
    /// Occurs when the FEDERATION_SERVER field is missing from the stellar.toml
    /// file at the specified domain, indicating the domain does not support federation.
    case noFederationSet

    /// The federation server response could not be parsed.
    ///
    /// Occurs when the server returns data that does not match the expected JSON
    /// structure or contains invalid field values.
    ///
    /// - Parameter message: Detailed error message describing the parsing failure
    case parsingResponseFailed(message:String)

    /// An underlying HTTP request error occurred when communicating with the server.
    ///
    /// Occurs when the federation server request fails due to network issues,
    /// server errors (5xx), not found (404), or other HTTP-level problems.
    ///
    /// - Parameter error: The underlying HorizonRequestError with details about the failure
    case horizonError(error: HorizonRequestError)
}
