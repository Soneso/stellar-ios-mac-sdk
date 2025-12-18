//
//  WebAuthForContractsError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13/12/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Errors that occur during contract challenge validation for SEP-45 Web Authentication for Contracts.
/// These errors represent validation failures when processing challenge authorization entries.
public enum ContractChallengeValidationError: Error, Sendable {
    /// The contract address in the authorization entry does not match the expected WEB_AUTH_CONTRACT_ID.
    case invalidContractAddress(expected: String, received: String)
    /// The function name in the authorization entry is not "web_auth_verify".
    case invalidFunctionName(expected: String, received: String)
    /// An authorization entry contains sub-invocations, which are not allowed in SEP-45 challenges.
    case subInvocationsFound
    /// The home_domain argument does not match the expected value.
    case invalidHomeDomain(expected: String, received: String)
    /// The web_auth_domain argument does not match the authentication server's domain.
    case invalidWebAuthDomain(expected: String, received: String)
    /// The account argument does not match the expected client account.
    case invalidAccount(expected: String, received: String)
    /// The nonce value is invalid, missing, or inconsistent across authorization entries.
    case invalidNonce(message: String)
    /// The server's signature on the authorization entry is invalid or could not be verified.
    case invalidServerSignature
    /// No authorization entry exists for the server account. At least one server entry is required.
    case missingServerEntry
    /// No authorization entry exists for the client account. At least one client entry is required.
    case missingClientEntry
    /// The arguments in the contract function call are invalid, malformed, or missing required fields.
    case invalidArgs(message: String)
    /// The network passphrase does not match the expected network.
    case invalidNetworkPassphrase(expected: String, received: String)
    /// The client domain account does not match the expected value.
    case invalidClientDomainAccount(expected: String, received: String)
}

/// Errors that occur during WebAuthForContracts initialization and configuration.
/// These errors represent failures when setting up the SEP-45 authentication service.
public enum WebAuthForContractsError: Error, Sendable {
    /// The provided domain is not a valid URL or domain format.
    case invalidDomain
    /// The stellar.toml file could not be parsed or is malformed.
    case invalidToml
    /// The stellar.toml file does not specify a WEB_AUTH_FOR_CONTRACTS_ENDPOINT.
    case noAuthEndpoint
    /// The stellar.toml file does not specify a WEB_AUTH_CONTRACT_ID.
    case noWebAuthContractId
    /// The stellar.toml file does not specify a SIGNING_KEY for the authentication server.
    case noSigningKey
    /// The WEB_AUTH_CONTRACT_ID is invalid or malformed.
    case invalidWebAuthContractId(message: String)
    /// The server's SIGNING_KEY is invalid or not in the correct format.
    case invalidServerSigningKey(message: String)
    /// The WEB_AUTH_FOR_CONTRACTS_ENDPOINT URL is invalid or malformed.
    case invalidAuthEndpoint(message: String)
    /// The server home domain is empty or missing.
    case emptyServerHomeDomain
    /// The client account ID is invalid or not in the correct contract address format.
    case invalidClientAccountId(message: String)
    /// A client domain signing callback is required but was not provided.
    case missingClientDomainSigningCallback
}

/// Errors that occur during runtime SEP-45 authentication operations.
/// These errors represent failures when executing the authentication flow to obtain a JWT token.
public enum GetContractJWTTokenError: Error, Sendable {
    /// Network or server request failed during SEP-45 authentication flow.
    case requestError(error: Error)
    /// Failed to request challenge from the authentication server.
    case challengeRequestError(message: String)
    /// Failed to submit signed challenge to the authentication server.
    case submitChallengeError(message: String)
    /// The challenge submission request timed out (HTTP 504).
    case submitChallengeTimeout
    /// The server returned an unknown or unexpected response.
    case submitChallengeUnknownResponse(statusCode: Int)
    /// Failed to parse server response or authorization entry data.
    case parsingError(message: String)
    /// Challenge authorization entries validation failed due to security or protocol violation.
    case validationError(error: ContractChallengeValidationError)
    /// Failed to sign the authorization entries with the provided signing keys.
    case signingError(message: String)
}
