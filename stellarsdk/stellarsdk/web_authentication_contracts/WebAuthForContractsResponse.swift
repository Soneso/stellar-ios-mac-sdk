//
//  WebAuthForContractsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13/12/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

// MARK: - Response Enums for Async Operations

/// Result enum for creating a WebAuthForContracts instance from a domain's stellar.toml file.
public enum WebAuthForContractsForDomainEnum: Sendable {
    /// Successfully created WebAuthForContracts instance with endpoint and contract ID from stellar.toml.
    case success(response: WebAuthForContracts)
    /// Failed to create authenticator due to invalid domain, malformed TOML, or missing required fields.
    case failure(error: WebAuthForContractsError)
}

/// Result enum for complete SEP-45 authentication flow.
public enum GetContractJWTTokenResponseEnum: Sendable {
    /// Successfully completed SEP-45 authentication and received JWT token.
    case success(jwtToken: String)
    /// Failed to complete authentication due to request, validation, or signing error.
    case failure(error: GetContractJWTTokenError)
}

/// Result enum for SEP-45 contract challenge transaction requests.
public enum GetContractChallengeResponseEnum: Sendable {
    /// Successfully retrieved challenge authorization entries from authentication server.
    case success(response: ContractChallengeResponse)
    /// Failed to retrieve challenge due to network or server error.
    case failure(error: GetContractJWTTokenError)
}

/// Result enum for submitting signed contract challenge authorization entries.
public enum SubmitContractChallengeResponseEnum: Sendable {
    /// Successfully submitted signed challenge and received JWT authentication token.
    case success(jwtToken: String)
    /// Failed to submit signed challenge due to invalid signature or server error.
    case failure(error: GetContractJWTTokenError)
}

// MARK: - Decodable Response Structs

/// Response from the SEP-45 challenge endpoint containing authorization entries to be signed.
///
/// This response is returned when requesting a challenge from the authentication server.
/// The authorization entries must be validated, signed by the client, and submitted back
/// to obtain a JWT token.
///
/// See also:
/// - [SEP-0045 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md)
public struct ContractChallengeResponse: Decodable, Sendable {

    /// Base64 XDR-encoded array of SorobanAuthorizationEntry objects.
    /// These entries must be validated and signed before submission.
    public let authorizationEntries: String

    /// Optional network passphrase for client verification.
    /// If provided, clients should verify it matches their expected network.
    public let networkPassphrase: String?

    /// Properties to encode and decode (snake_case per SEP-45 spec).
    private enum CodingKeys: String, CodingKey {
        case authorizationEntries = "authorization_entries"
        case networkPassphrase = "network_passphrase"
    }

    /// Alternative keys (camelCase used by some servers like testanchor).
    private enum AlternativeCodingKeys: String, CodingKey {
        case authorizationEntries
        case networkPassphrase
    }

    /// Creates a new instance by decoding from the given decoder.
    /// Supports both snake_case (per spec) and camelCase (used by some servers).
    ///
    /// - Parameter decoder: The decoder containing the data
    public init(from decoder: Decoder) throws {
        // Try snake_case first (per SEP-45 spec)
        if let values = try? decoder.container(keyedBy: CodingKeys.self),
           let entries = try? values.decode(String.self, forKey: .authorizationEntries) {
            authorizationEntries = entries
            networkPassphrase = try? values.decodeIfPresent(String.self, forKey: .networkPassphrase)
        }
        // Fall back to camelCase (used by some servers)
        else if let values = try? decoder.container(keyedBy: AlternativeCodingKeys.self),
                let entries = try? values.decode(String.self, forKey: .authorizationEntries) {
            authorizationEntries = entries
            networkPassphrase = try? values.decodeIfPresent(String.self, forKey: .networkPassphrase)
        }
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not find authorization_entries or authorizationEntries"
                )
            )
        }
    }
}
