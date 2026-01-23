//
//  OZIndexerClient.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Response Models

/// Response from looking up a credential ID in the indexer.
///
/// Contains the credential ID, all contracts where this credential is registered as a signer,
/// and the total count of contracts.
public struct CredentialLookupResponse: Codable, Sendable {
    /// The credential ID that was queried (hex-encoded, no 0x prefix).
    public let credentialId: String

    /// List of contracts where this credential is registered as a signer.
    public let contracts: [IndexedContractSummary]

    /// Total number of contracts returned.
    public let count: Int

    enum CodingKeys: String, CodingKey {
        case credentialId = "credential_id"
        case contracts
        case count
    }
}

/// Response from looking up a signer address in the indexer.
///
/// Contains the signer address, all contracts where this address is registered as a signer,
/// and the total count of contracts.
public struct AddressLookupResponse: Codable, Sendable {
    /// The signer address that was queried (G... or C... address).
    public let signerAddress: String

    /// List of contracts where this address is registered as a signer.
    public let contracts: [IndexedContractSummary]

    /// Total number of contracts returned.
    public let count: Int

    enum CodingKeys: String, CodingKey {
        case signerAddress = "signer_address"
        case contracts
        case count
    }
}

/// Response containing full details of a smart account contract.
///
/// Includes the contract ID, summary information, and all context rules with their signers and policies.
public struct ContractDetailsResponse: Codable, Sendable {
    /// The contract ID (C... address).
    public let contractId: String

    /// Summary information about the contract.
    public let summary: IndexedContractSummary

    /// All context rules defined in this contract.
    public let contextRules: [IndexedContextRule]

    enum CodingKeys: String, CodingKey {
        case contractId = "contract_id"
        case summary
        case contextRules = "context_rules"
    }
}

/// Summary information about a smart account contract.
///
/// Contains aggregate counts and metadata about signers, policies, and context rules.
public struct IndexedContractSummary: Codable, Sendable {
    /// The contract ID (C... address).
    public let contractId: String

    /// Total number of context rules in this contract.
    public let contextRuleCount: Int

    /// Total number of external signers (WebAuthn/passkeys) across all context rules.
    public let externalSignerCount: Int

    /// Total number of delegated signers (Stellar addresses) across all context rules.
    public let delegatedSignerCount: Int

    /// Total number of native signers (built-in contract signers) across all context rules.
    public let nativeSignerCount: Int

    /// The ledger sequence number when this contract was first seen.
    public let firstSeenLedger: Int

    /// The ledger sequence number when this contract was last seen.
    public let lastSeenLedger: Int

    /// List of context rule IDs defined in this contract.
    public let contextRuleIds: [Int]

    enum CodingKeys: String, CodingKey {
        case contractId = "contract_id"
        case contextRuleCount = "context_rule_count"
        case externalSignerCount = "external_signer_count"
        case delegatedSignerCount = "delegated_signer_count"
        case nativeSignerCount = "native_signer_count"
        case firstSeenLedger = "first_seen_ledger"
        case lastSeenLedger = "last_seen_ledger"
        case contextRuleIds = "context_rule_ids"
    }
}

/// A context rule within a smart account contract.
///
/// Defines authorization requirements (signers and policies) for a specific context
/// (e.g., "Default" or "Call Token Contract X").
public struct IndexedContextRule: Codable, Sendable {
    /// The numeric ID of this context rule within the contract (0-based).
    public let contextRuleId: Int

    /// List of signers authorized under this context rule.
    public let signers: [IndexedSigner]

    /// List of policies that apply to this context rule.
    public let policies: [IndexedPolicy]

    enum CodingKeys: String, CodingKey {
        case contextRuleId = "context_rule_id"
        case signers
        case policies
    }
}

/// A signer within a context rule.
///
/// Can be either an external signer (WebAuthn/passkey with credential ID) or a delegated
/// signer (Stellar address using built-in signature verification).
public struct IndexedSigner: Codable, Sendable {
    /// The type of signer: "External" for WebAuthn/passkeys, "Delegated" for Stellar addresses.
    public let signerType: String

    /// The Stellar address (G... or C...) for delegated signers. Nil for external signers.
    public let signerAddress: String?

    /// The credential ID (hex-encoded) for external signers. Nil for delegated signers.
    public let credentialId: String?

    enum CodingKeys: String, CodingKey {
        case signerType = "signer_type"
        case signerAddress = "signer_address"
        case credentialId = "credential_id"
    }
}

/// A policy attached to a context rule.
///
/// Policies enforce additional authorization requirements beyond signature verification
/// (e.g., spending limits, time locks, threshold requirements).
public struct IndexedPolicy: Codable, Sendable {
    /// The contract address of the policy (C... address).
    public let policyAddress: String

    /// Optional installation parameters for the policy (arbitrary JSON structure).
    public let installParams: JSONValue?

    enum CodingKeys: String, CodingKey {
        case policyAddress = "policy_address"
        case installParams = "install_params"
    }
}

// MARK: - JSON Value Type

/// A flexible JSON value type that can represent any valid JSON structure.
///
/// Used for policy installation parameters which can be arbitrary JSON objects.
public enum JSONValue: Codable, Sendable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int64.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode JSONValue"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

// MARK: - Indexer Client

/// Client for interacting with the OpenZeppelin Smart Account indexer service.
///
/// The indexer maps WebAuthn credential IDs and signer addresses to deployed smart account
/// contract addresses, enabling "Connect Wallet" discovery and contract exploration.
///
/// Example usage:
/// ```swift
/// let client = OZIndexerClient(indexerUrl: "https://indexer.example.com")
///
/// // Look up contracts by credential ID
/// let credentialResponse = try await client.lookupByCredentialId("abc123...")
/// print("Found \(credentialResponse.count) contracts")
///
/// // Look up contracts by signer address
/// let addressResponse = try await client.lookupByAddress("GABC123...")
/// print("Signer is registered in \(addressResponse.count) contracts")
///
/// // Get full contract details
/// let contractDetails = try await client.getContract("CABC123...")
/// print("Contract has \(contractDetails.contextRules.count) context rules")
/// ```
public final class OZIndexerClient: @unchecked Sendable {
    private let indexerUrl: String
    private let timeoutMs: Int64
    private let urlSession: URLSession

    /// Creates a new indexer client.
    ///
    /// - Parameters:
    ///   - indexerUrl: The base URL of the indexer service (e.g., "https://indexer.example.com")
    ///   - timeoutMs: Request timeout in milliseconds (default: 10 seconds)
    public init(
        indexerUrl: String,
        timeoutMs: Int64 = SmartAccountConstants.DEFAULT_INDEXER_TIMEOUT_MS
    ) {
        self.indexerUrl = indexerUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.timeoutMs = timeoutMs

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(timeoutMs) / 1000.0
        config.timeoutIntervalForResource = TimeInterval(timeoutMs) / 1000.0
        self.urlSession = URLSession(configuration: config)
    }

    /// Looks up smart account contracts by WebAuthn credential ID.
    ///
    /// Queries the indexer for all smart account contracts where the specified credential ID
    /// is registered as an external signer in any context rule.
    ///
    /// - Parameter credentialId: The credential ID to look up (base64url-encoded, no padding).
    ///                           Will be converted to hex for the API call.
    /// - Returns: A response containing the credential ID, matching contracts, and count.
    /// - Throws: SmartAccountError if the request fails or returns invalid data.
    public func lookupByCredentialId(_ credentialId: String) async throws -> CredentialLookupResponse {
        let hexCredentialId = try base64urlToHex(credentialId)
        let url = "\(indexerUrl)/api/lookup/\(hexCredentialId)"
        return try await performRequest(url: url, responseType: CredentialLookupResponse.self)
    }

    /// Looks up smart account contracts by signer address.
    ///
    /// Queries the indexer for all smart account contracts where the specified address
    /// is registered as a delegated signer in any context rule.
    ///
    /// - Parameter address: The signer address to look up (G... or C... format).
    /// - Returns: A response containing the signer address, matching contracts, and count.
    /// - Throws: SmartAccountError if the request fails or returns invalid data.
    public func lookupByAddress(_ address: String) async throws -> AddressLookupResponse {
        guard address.hasPrefix("G") || address.hasPrefix("C") else {
            throw SmartAccountError.invalidAddress("Signer address must start with 'G' or 'C', got: \(address)")
        }

        let url = "\(indexerUrl)/api/lookup/address/\(address)"
        return try await performRequest(url: url, responseType: AddressLookupResponse.self)
    }

    /// Gets detailed information about a smart account contract.
    ///
    /// Retrieves full contract details including summary information and all context rules
    /// with their signers and policies.
    ///
    /// - Parameter contractId: The contract ID to query (C... format).
    /// - Returns: A response containing the contract ID, summary, and all context rules.
    /// - Throws: SmartAccountError if the request fails or returns invalid data.
    public func getContract(_ contractId: String) async throws -> ContractDetailsResponse {
        guard contractId.hasPrefix("C") else {
            throw SmartAccountError.invalidAddress("Contract ID must start with 'C', got: \(contractId)")
        }

        let url = "\(indexerUrl)/api/contract/\(contractId)"
        return try await performRequest(url: url, responseType: ContractDetailsResponse.self)
    }

    // MARK: - Private Helper Methods

    /// Performs an HTTP GET request and decodes the JSON response.
    ///
    /// - Parameters:
    ///   - url: The full URL to request
    ///   - responseType: The type to decode the JSON response into
    /// - Returns: The decoded response object
    /// - Throws: SmartAccountError for network, timeout, or decoding errors
    private func performRequest<T: Decodable>(
        url: String,
        responseType: T.Type
    ) async throws -> T {
        guard let requestUrl = URL(string: url) else {
            throw SmartAccountError.invalidInput("Invalid URL: \(url)")
        }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw SmartAccountError.invalidInput(
                "Indexer request timed out after \(timeoutMs)ms: \(url)",
                cause: error
            )
        } catch {
            throw SmartAccountError.invalidInput(
                "Indexer request failed: \(error.localizedDescription)",
                cause: error
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SmartAccountError.invalidInput("Invalid response from indexer: not an HTTP response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "(unable to decode response body)"
            throw SmartAccountError.invalidInput(
                "Indexer returned HTTP \(httpResponse.statusCode): \(errorBody)"
            )
        }

        let decoder = JSONDecoder()

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let responseBody = String(data: data, encoding: .utf8) ?? "(unable to decode response body)"
            throw SmartAccountError.invalidInput(
                "Failed to decode indexer response: \(error.localizedDescription). Response: \(responseBody)",
                cause: error
            )
        }
    }

    /// Converts a base64url-encoded string to hex encoding.
    ///
    /// The SDK stores credential IDs in base64url format (RFC 4648, no padding).
    /// The indexer API expects hex encoding (no 0x prefix).
    ///
    /// - Parameter base64url: The base64url-encoded string (no padding)
    /// - Returns: The hex-encoded string (lowercase, no 0x prefix)
    /// - Throws: SmartAccountError if the input is not valid base64url
    private func base64urlToHex(_ base64url: String) throws -> String {
        // Convert base64url to standard base64
        var base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed (base64 requires length to be multiple of 4)
        let paddingLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLength)

        // Decode base64 to bytes
        guard let data = Data(base64Encoded: base64) else {
            throw SmartAccountError.invalidInput(
                "Failed to decode base64url credential ID: \(base64url)"
            )
        }

        // Convert bytes to hex string
        return data.map { String(format: "%02x", $0) }.joined()
    }
}
