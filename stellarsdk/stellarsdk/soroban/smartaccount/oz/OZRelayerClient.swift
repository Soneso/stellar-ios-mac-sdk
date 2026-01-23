//
//  OZRelayerClient.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Response from the relayer service.
///
/// The relayer wraps transactions with fee bumps and submits them to Stellar,
/// enabling gasless onboarding for users with empty wallets.
public struct RelayerResponse: Sendable, Codable {
    /// Indicates whether the transaction was successfully submitted.
    public let success: Bool

    /// The transaction hash if submission succeeded.
    public let hash: String?

    /// The transaction status (e.g., "PENDING", "SUCCESS", "ERROR").
    public let status: String?

    /// Error message if the request failed.
    public let error: String?

    /// Error code if the request failed.
    ///
    /// Known error codes:
    /// - INVALID_PARAMS: Request parameters are invalid
    /// - INVALID_XDR: XDR encoding is malformed
    /// - POOL_CAPACITY: Relayer pool is at capacity
    /// - SIMULATION_FAILED: Transaction simulation failed
    /// - ONCHAIN_FAILED: Transaction failed on-chain
    /// - INVALID_TIME_BOUNDS: Transaction time bounds are invalid
    /// - FEE_LIMIT_EXCEEDED: Transaction fee exceeds relayer limit
    /// - UNAUTHORIZED: Request is not authorized
    /// - TIMEOUT: Request timed out (client-side)
    public let errorCode: String?

    /// Creates a new RelayerResponse.
    ///
    /// - Parameters:
    ///   - success: Whether the transaction succeeded
    ///   - hash: Optional transaction hash
    ///   - status: Optional status string
    ///   - error: Optional error message
    ///   - errorCode: Optional error code
    public init(
        success: Bool,
        hash: String? = nil,
        status: String? = nil,
        error: String? = nil,
        errorCode: String? = nil
    ) {
        self.success = success
        self.hash = hash
        self.status = status
        self.error = error
        self.errorCode = errorCode
    }
}

/// Client for submitting transactions to an OpenZeppelin Smart Account relayer.
///
/// The relayer provides fee sponsoring by wrapping user transactions with fee bumps,
/// enabling gasless onboarding and transactions for users with empty wallets.
///
/// Two submission modes are supported:
///
/// 1. **Host Function + Auth Entries**: Submit transaction components separately
///    for the relayer to construct and wrap the full transaction.
///
/// 2. **Signed Transaction XDR**: Submit a complete, signed transaction envelope
///    for the relayer to wrap and submit.
///
/// Example usage:
/// ```swift
/// let relayer = OZRelayerClient(relayerUrl: "https://relayer.example.com")
///
/// // Mode 1: Submit host function and auth entries
/// let hostFunction = // ... HostFunctionXDR
/// let authEntries = // ... [SorobanAuthorizationEntryXDR]
/// let response = try await relayer.send(func: hostFunction, auth: authEntries)
///
/// // Mode 2: Submit signed transaction XDR
/// let txEnvelope = "AAAAAgAAAAD..." // base64 TransactionEnvelope
/// let response = try await relayer.sendXdr(txEnvelope)
///
/// if response.success {
///     print("Transaction hash: \(response.hash ?? "unknown")")
/// } else {
///     print("Error: \(response.error ?? "unknown")")
/// }
/// ```
public final class OZRelayerClient: @unchecked Sendable {
    /// The relayer endpoint URL.
    private let relayerUrl: String

    /// Request timeout in milliseconds.
    private let timeoutMs: Int64

    /// JSON encoder for request payloads.
    private let jsonEncoder = JSONEncoder()

    /// JSON decoder for response payloads.
    private let jsonDecoder = JSONDecoder()

    /// Creates a new OZRelayerClient.
    ///
    /// - Parameters:
    ///   - relayerUrl: The relayer endpoint URL
    ///   - timeoutMs: Request timeout in milliseconds (default: 6 minutes)
    public init(
        relayerUrl: String,
        timeoutMs: Int64 = SmartAccountConstants.DEFAULT_RELAYER_TIMEOUT_MS
    ) {
        self.relayerUrl = relayerUrl
        self.timeoutMs = timeoutMs
    }

    // MARK: - Mode 1: Host Function + Auth Entries

    /// Submits a transaction using host function and authorization entries.
    ///
    /// The relayer will construct a full transaction from these components,
    /// wrap it with a fee bump, and submit it to the Stellar network.
    ///
    /// - Parameters:
    ///   - hostFunction: The host function to execute
    ///   - auth: Authorization entries for the transaction
    /// - Returns: The relayer response with transaction hash or error
    /// - Throws: SmartAccountError if the request fails
    public func send(
        func hostFunction: HostFunctionXDR,
        auth: [SorobanAuthorizationEntryXDR]
    ) async throws -> RelayerResponse {
        // Encode host function to base64
        guard let funcBase64 = hostFunction.xdrEncoded else {
            throw SmartAccountError.transactionSubmissionFailed(
                "Failed to encode host function to XDR"
            )
        }

        // Encode auth entries to base64
        var authBase64Array: [String] = []
        for entry in auth {
            guard let entryBase64 = entry.xdrEncoded else {
                throw SmartAccountError.transactionSubmissionFailed(
                    "Failed to encode auth entry to XDR"
                )
            }
            authBase64Array.append(entryBase64)
        }

        // Build request payload
        let payload: [String: Any] = [
            "func": funcBase64,
            "auth": authBase64Array
        ]

        return try await performRequest(payload: payload)
    }

    // MARK: - Mode 2: Signed Transaction XDR

    /// Submits a complete signed transaction envelope.
    ///
    /// The relayer will wrap this transaction with a fee bump and submit it
    /// to the Stellar network.
    ///
    /// - Parameter transactionEnvelopeXdr: Base64-encoded TransactionEnvelope XDR
    /// - Returns: The relayer response with transaction hash or error
    /// - Throws: SmartAccountError if the request fails
    public func sendXdr(_ transactionEnvelopeXdr: String) async throws -> RelayerResponse {
        // Build request payload
        let payload: [String: Any] = [
            "xdr": transactionEnvelopeXdr
        ]

        return try await performRequest(payload: payload)
    }

    // MARK: - Private Methods

    /// Performs the HTTP request to the relayer.
    ///
    /// - Parameter payload: The JSON payload to send
    /// - Returns: The parsed relayer response
    /// - Throws: SmartAccountError if the request fails
    private func performRequest(payload: [String: Any]) async throws -> RelayerResponse {
        // Create URL
        guard let url = URL(string: relayerUrl) else {
            throw SmartAccountError.transactionSubmissionFailed(
                "Invalid relayer URL: \(relayerUrl)"
            )
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = TimeInterval(timeoutMs) / 1000.0

        // Encode JSON body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw SmartAccountError.transactionSubmissionFailed(
                "Failed to encode request payload",
                cause: error
            )
        }

        // Perform request with timeout handling
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw SmartAccountError.transactionSubmissionFailed(
                "Request timed out after \(timeoutMs)ms",
                cause: urlError
            )
        } catch {
            throw SmartAccountError.transactionSubmissionFailed(
                "Network request failed: \(error.localizedDescription)",
                cause: error
            )
        }

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SmartAccountError.transactionSubmissionFailed(
                "Invalid response type"
            )
        }

        // Handle non-200 status codes
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)

            throw SmartAccountError.transactionSubmissionFailed(
                "Relayer returned HTTP \(httpResponse.statusCode): \(errorMessage)"
            )
        }

        // Decode response
        let relayerResponse: RelayerResponse
        do {
            relayerResponse = try jsonDecoder.decode(RelayerResponse.self, from: data)
        } catch {
            throw SmartAccountError.transactionSubmissionFailed(
                "Failed to decode relayer response",
                cause: error
            )
        }

        return relayerResponse
    }
}
