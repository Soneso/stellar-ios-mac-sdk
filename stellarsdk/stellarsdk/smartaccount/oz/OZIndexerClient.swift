//
//  OZIndexerClient.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Response Models

/// Response from looking up a credential ID in the indexer.
///
/// Contains the credential ID, all contracts where this credential is registered as a
/// signer, and the total count of contracts. The indexer's JSON uses camelCase at the
/// top level even though the inner contract summaries use snake_case keys.
public struct OZCredentialLookupResponse: Decodable, Equatable, Sendable {
    public let credentialId: String
    public let contracts: [OZIndexedContractSummary]
    public let count: Int

    public init(credentialId: String, contracts: [OZIndexedContractSummary], count: Int) {
        self.credentialId = credentialId
        self.contracts = contracts
        self.count = count
    }
}

/// Response from looking up a signer address in the indexer.
///
/// Contains the signer address, all contracts where this address is registered as a
/// signer, and the total count of contracts.
public struct OZAddressLookupResponse: Decodable, Equatable, Sendable {
    public let signerAddress: String
    public let contracts: [OZIndexedContractSummary]
    public let count: Int

    public init(signerAddress: String, contracts: [OZIndexedContractSummary], count: Int) {
        self.signerAddress = signerAddress
        self.contracts = contracts
        self.count = count
    }
}

/// Full details of a smart account contract.
///
/// Includes the contract ID, summary information, and all context rules with their
/// signers and policies. The indexer returns the top-level keys in camelCase; the
/// inner fields use snake_case.
public struct OZContractDetailsResponse: Decodable, Equatable, Sendable {
    public let contractId: String
    public let summary: OZIndexedContractSummary
    public let contextRules: [OZIndexedContextRule]

    public init(
        contractId: String,
        summary: OZIndexedContractSummary,
        contextRules: [OZIndexedContextRule]
    ) {
        self.contractId = contractId
        self.summary = summary
        self.contextRules = contextRules
    }
}

/// Summary information about a smart account contract.
///
/// Contains aggregate counts and metadata about signers, policies, and context rules.
public struct OZIndexedContractSummary: Decodable, Equatable, Sendable {
    public let contractId: String
    public let contextRuleCount: Int
    public let externalSignerCount: Int
    public let delegatedSignerCount: Int
    public let nativeSignerCount: Int
    public let firstSeenLedger: Int
    public let lastSeenLedger: Int
    public let contextRuleIds: [Int]

    public init(
        contractId: String,
        contextRuleCount: Int,
        externalSignerCount: Int,
        delegatedSignerCount: Int,
        nativeSignerCount: Int,
        firstSeenLedger: Int,
        lastSeenLedger: Int,
        contextRuleIds: [Int]
    ) {
        self.contractId = contractId
        self.contextRuleCount = contextRuleCount
        self.externalSignerCount = externalSignerCount
        self.delegatedSignerCount = delegatedSignerCount
        self.nativeSignerCount = nativeSignerCount
        self.firstSeenLedger = firstSeenLedger
        self.lastSeenLedger = lastSeenLedger
        self.contextRuleIds = contextRuleIds
    }

    private enum CodingKeys: String, CodingKey {
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
/// such as the `Default` context or `Call Token Contract X`.
public struct OZIndexedContextRule: Decodable, Equatable, Sendable {
    public let contextRuleId: Int
    public let signers: [OZIndexedSigner]
    public let policies: [OZIndexedPolicy]

    public init(
        contextRuleId: Int,
        signers: [OZIndexedSigner],
        policies: [OZIndexedPolicy]
    ) {
        self.contextRuleId = contextRuleId
        self.signers = signers
        self.policies = policies
    }

    private enum CodingKeys: String, CodingKey {
        case contextRuleId = "context_rule_id"
        case signers
        case policies
    }
}

/// A signer within a context rule.
///
/// `signerType` is one of `"External"` (WebAuthn / passkey), `"Delegated"` (a Stellar
/// account or contract address), or `"Native"`. External signers carry a `credentialId`
/// (hex-encoded by the indexer) and no `signerAddress`. Delegated signers carry a
/// `signerAddress` and no `credentialId`. Native signers carry neither.
public struct OZIndexedSigner: Decodable, Equatable, Sendable {
    public let signerType: String
    public let signerAddress: String?
    public let credentialId: String?

    public init(signerType: String, signerAddress: String? = nil, credentialId: String? = nil) {
        self.signerType = signerType
        self.signerAddress = signerAddress
        self.credentialId = credentialId
    }

    private enum CodingKeys: String, CodingKey {
        case signerType = "signer_type"
        case signerAddress = "signer_address"
        case credentialId = "credential_id"
    }
}

/// A policy attached to a context rule.
///
/// Policies enforce additional authorization requirements beyond signature verification
/// such as spending limits, time locks, or threshold requirements. The `installParams`
/// dictionary preserves the arbitrary JSON structure attached by the policy contract;
/// nested objects, arrays, numbers, strings, booleans, and `nil` (JSON `null`) are all
/// preserved.
public struct OZIndexedPolicy: Decodable, Equatable, Sendable {
    public let policyAddress: String
    public let installParams: [String: OZJSONValue]?

    public init(policyAddress: String, installParams: [String: OZJSONValue]? = nil) {
        self.policyAddress = policyAddress
        self.installParams = installParams
    }

    private enum CodingKeys: String, CodingKey {
        case policyAddress = "policy_address"
        case installParams = "install_params"
    }
}

/// Response from the indexer stats endpoint.
///
/// Contains aggregate statistics about the indexer state including total contracts,
/// credentials, and event type breakdowns.
public struct OZIndexerStatsResponse: Decodable, Equatable, Sendable {
    public let stats: OZIndexerStats

    public init(stats: OZIndexerStats) {
        self.stats = stats
    }
}

/// Statistics about the indexer state.
public struct OZIndexerStats: Decodable, Equatable, Sendable {
    public let totalEvents: Int64
    public let uniqueContracts: Int64
    public let uniqueCredentials: Int64
    public let firstLedger: Int64
    public let lastLedger: Int64
    public let eventTypes: [OZEventTypeCount]

    public init(
        totalEvents: Int64,
        uniqueContracts: Int64,
        uniqueCredentials: Int64,
        firstLedger: Int64,
        lastLedger: Int64,
        eventTypes: [OZEventTypeCount]
    ) {
        self.totalEvents = totalEvents
        self.uniqueContracts = uniqueContracts
        self.uniqueCredentials = uniqueCredentials
        self.firstLedger = firstLedger
        self.lastLedger = lastLedger
        self.eventTypes = eventTypes
    }

    private enum CodingKeys: String, CodingKey {
        case totalEvents = "total_events"
        case uniqueContracts = "unique_contracts"
        case uniqueCredentials = "unique_credentials"
        case firstLedger = "first_ledger"
        case lastLedger = "last_ledger"
        case eventTypes
    }
}

/// Count of events broken down by type.
public struct OZEventTypeCount: Decodable, Equatable, Sendable {
    public let eventType: String
    public let count: Int64

    public init(eventType: String, count: Int64) {
        self.eventType = eventType
        self.count = count
    }

    private enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case count
    }
}

/// Response from the indexer `/` health check endpoint.
///
/// Carries the indexer's reported status string; compared against `"ok"` by
/// `OZIndexerClient.isHealthy()`.
public struct OZIndexerHealthCheckResponse: Decodable, Equatable, Sendable {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}

// MARK: - JSON value (arbitrary JSON for install_params)

/// Generic JSON value used to preserve arbitrary structures inside policy install
/// parameters returned by the indexer.
///
/// The indexer returns `install_params` as an unbounded JSON value; the SDK never
/// inspects or rewrites it. Callers can introspect the case to recover specific
/// types or pass the value through to higher layers untouched.
public enum OZJSONValue: Decodable, Equatable, Hashable, Sendable {
    case string(String)
    case integer(Int64)
    case double(Double)
    case bool(Bool)
    case array([OZJSONValue])
    case object([String: OZJSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        if let value = try? container.decode(Int64.self) {
            self = .integer(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode([OZJSONValue].self) {
            self = .array(value)
            return
        }
        if let value = try? container.decode([String: OZJSONValue].self) {
            self = .object(value)
            return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Encountered a JSON value of an unsupported type"
        )
    }

    /// Custom `Hashable` implementation.
    ///
    /// Required because `Dictionary` is `Hashable` only when both its `Key` and
    /// `Value` are `Hashable`; Swift cannot auto-synthesize the conformance
    /// when one of the enum cases carries a `[String: OZJSONValue]` payload.
    /// Each discriminant is combined into the hasher before its payload so
    /// values across different cases cannot collide on payload alone. The
    /// `.object` case sorts its keys before hashing so identical dictionaries
    /// hash to the same value regardless of insertion order.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null:
            hasher.combine(0)
        case .bool(let value):
            hasher.combine(1)
            hasher.combine(value)
        case .integer(let value):
            hasher.combine(2)
            hasher.combine(value)
        case .double(let value):
            hasher.combine(3)
            hasher.combine(value)
        case .string(let value):
            hasher.combine(4)
            hasher.combine(value)
        case .array(let values):
            hasher.combine(5)
            for element in values {
                hasher.combine(element)
            }
        case .object(let dict):
            hasher.combine(6)
            for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                hasher.combine(key)
                hasher.combine(value)
            }
        }
    }
}

// MARK: - Indexer Client

/// Client for interacting with the OpenZeppelin Smart Account indexer service.
///
/// The indexer maps WebAuthn credential IDs and signer addresses to deployed smart
/// account contract addresses, enabling discovery-style flows for users with existing
/// wallets and detailed introspection of any deployed contract.
///
/// Example:
/// ```swift
/// let client = try OZIndexerClient(indexerUrl: "https://indexer.example.com")
/// let credentialResponse = try await client.lookupByCredentialId(credentialId: "abc123...")
/// print("Found \(credentialResponse.count) contracts")
///
/// let addressResponse = try await client.lookupByAddress(address: "GABC123...")
/// print("Signer is registered in \(addressResponse.count) contracts")
///
/// let contractDetails = try await client.getContract(contractId: "CABC123...")
/// print("Contract has \(contractDetails.contextRules.count) context rules")
///
/// client.close()
/// ```
///
/// The client validates its `indexerUrl` argument at construction. HTTPS is required,
/// with `http://localhost` allowed for development. After use, call `close()` to
/// invalidate the owned `URLSession`. When a custom `urlSession` is supplied (for
/// testing) the caller retains ownership.
public final class OZIndexerClient: @unchecked Sendable {

    // MARK: - Configuration

    /// HTTP path that returns `{"status": "ok"}` when the indexer service is reachable.
    /// Compared against `HealthCheckResponse.status` in `isHealthy()`.
    private static let healthStatusOk = "ok"

    /// Default indexer URLs by Stellar network passphrase.
    ///
    /// Used as the central source of truth for the SDK's built-in indexer endpoints.
    /// `OZSmartAccountConfig.effectiveIndexerUrl()` consults this map when the
    /// caller did not supply an explicit `indexerUrl`.
    public static let defaultIndexerUrls: [String: String] = [
        Network.testnet.passphrase: "https://smart-account-indexer.sdf-ecosystem.workers.dev",
        Network.public.passphrase: "https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev",
    ]

    /// Returns the default indexer URL for the supplied network passphrase, or `nil`
    /// when no default is configured for that network.
    ///
    /// - Parameter networkPassphrase: The Stellar network passphrase to look up.
    /// - Returns: The default indexer URL string, or `nil`.
    public static func getDefaultUrl(networkPassphrase: String) -> String? {
        return defaultIndexerUrls[networkPassphrase]
    }

    /// Creates an `OZIndexerClient` configured for a specific Stellar network using the
    /// SDK's default indexer endpoint for that network.
    ///
    /// - Parameters:
    ///   - networkPassphrase: The Stellar network passphrase. Use
    ///     `Network.testnet.passphrase` or `Network.public.passphrase` for the
    ///     built-in networks.
    ///   - timeoutMs: Request timeout in milliseconds.
    ///   - urlSession: Optional injected `URLSession`. When `nil`, the client owns a
    ///     freshly created session and invalidates it on `close()`.
    /// - Returns: A configured `OZIndexerClient`, or `nil` if no default URL is
    ///   configured for the network.
    public static func forNetwork(
        networkPassphrase: String,
        timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
        urlSession: URLSession? = nil
    ) -> OZIndexerClient? {
        guard let url = getDefaultUrl(networkPassphrase: networkPassphrase) else {
            return nil
        }
        // why: the static factory only resolves a URL string that has already passed the
        // default-URL allowlist; construction with the resolved URL cannot trip the
        // HTTPS validation branch, so the `try` here always succeeds.
        return try? OZIndexerClient(indexerUrl: url, timeoutMs: timeoutMs, urlSession: urlSession)
    }

    // MARK: - Instance state

    /// Normalized base URL (no trailing slashes).
    private let baseUrl: String

    /// The `URLSession` used to issue requests. Owned by the client unless
    /// `urlSessionWasInjected` is `true`.
    private let urlSession: URLSession

    /// `true` when the caller supplied the `URLSession`; in that case `close()` does
    /// NOT invalidate the session — ownership remains with the caller.
    private let urlSessionWasInjected: Bool

    /// Strong reference to the no-redirect delegate attached to the owned
    /// `URLSession`. `URLSession` retains its delegate, but holding a strong
    /// reference here keeps the delegate visible for testing and matches the
    /// lifetime of the session. `nil` when the caller injected their own session;
    /// in that case the redirect-handling policy is the caller's responsibility.
    private let noRedirectDelegate: OZNoRedirectDelegate?

    /// Per-request timeout interval in seconds; applied to every outbound `URLRequest`.
    private let timeoutInterval: TimeInterval

    /// Set once `close()` has been called; subsequent `close()` calls are no-ops.
    private var isClosed: Bool = false

    /// Synchronizes access to `isClosed` so `close()` is safe to call from multiple
    /// threads and from `deinit`.
    private let stateLock = NSLock()

    /// Test-only accessor exposing the no-redirect delegate attached to the
    /// owned `URLSession`. `nil` when the caller injected a `URLSession`.
    /// Used by unit tests to verify that redirects are denied on owned sessions.
    internal var noRedirectDelegateForTesting: OZNoRedirectDelegate? { noRedirectDelegate }

    // MARK: - Initialization

    /// Creates a new `OZIndexerClient`.
    ///
    /// - Parameters:
    ///   - indexerUrl: The indexer endpoint URL. Must start with `https://` or
    ///     `http://localhost` (with optional port and path).
    ///   - timeoutMs: Request timeout in milliseconds. Defaults to
    ///     `OZConstants.defaultIndexerTimeoutMs` (10 seconds).
    ///   - urlSession: Optional pre-configured `URLSession`. Use this to
    ///     inject a test mock OR to apply production transport configuration
    ///     such as certificate pinning, proxy settings, or request inspection.
    ///     When `nil`, the client builds an ephemeral session whose redirect
    ///     handler denies all 3xx redirects to protect signed payloads and
    ///     pinned identification headers; the owned session is invalidated on
    ///     `close()`. When an injected session is supplied, the
    ///     redirect-handling policy of that session is the caller's
    ///     responsibility.
    /// - Throws: `ConfigurationException.InvalidConfig` when the URL is blank or
    ///   does not satisfy the HTTPS / localhost constraint.
    public init(
        indexerUrl: String,
        timeoutMs: Int64 = OZConstants.defaultIndexerTimeoutMs,
        urlSession: URLSession? = nil
    ) throws {
        let trimmedUrl = indexerUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUrl.isEmpty {
            throw ConfigurationException.invalidConfig(details: "Indexer URL is required")
        }
        if !trimmedUrl.hasPrefix("https://") && !isLocalhostUrl(trimmedUrl) {
            throw ConfigurationException.invalidConfig(
                details: "Indexer URL must use HTTPS (or http://localhost for development): \(trimmedUrl)"
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
            throw ConfigurationException.invalidConfig(
                details: "Indexer URL must include a host: \(trimmedUrl)"
            )
        }
        self.baseUrl = stripped

        let timeoutSeconds = TimeInterval(timeoutMs) / 1000.0
        self.timeoutInterval = timeoutSeconds

        if let injected = urlSession {
            self.urlSession = injected
            self.urlSessionWasInjected = true
            self.noRedirectDelegate = nil
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = timeoutSeconds
            configuration.timeoutIntervalForResource = timeoutSeconds
            // why: identification headers are pinned at the configuration layer so
            // every outbound request carries them even if the caller only sets a few
            // request-specific headers in a future code path.
            configuration.httpAdditionalHeaders = ozBuildDefaultHeaders()
            // why: refuse HTTP redirects so a 3xx response from the configured
            // host cannot redirect outbound requests to a third-party URL,
            // which would bypass the HTTPS-only constructor check and leak the
            // pinned `X-Client-*` identification headers.
            let delegate = OZNoRedirectDelegate()
            self.noRedirectDelegate = delegate
            self.urlSession = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
            self.urlSessionWasInjected = false
        }
    }

    // MARK: - Public methods

    /// Looks up smart account contracts by WebAuthn credential ID.
    ///
    /// - Parameter credentialId: The credential ID to look up, base64url-encoded with
    ///   no padding. The client converts it to hex before contacting the indexer.
    /// - Returns: The decoded `OZCredentialLookupResponse`.
    /// - Throws: `ValidationException.InvalidInput` when the credential ID is not
    ///   valid base64url. `IndexerException.RequestFailed` on network failure,
    ///   non-2xx response, or decoding failure. `IndexerException.Timeout` when the
    ///   request exceeds the configured timeout.
    public func lookupByCredentialId(credentialId: String) async throws -> OZCredentialLookupResponse {
        let hexCredentialId = try base64UrlToHex(credentialId)
        let url = "\(baseUrl)/api/lookup/\(hexCredentialId)"
        return try await performRequest(url: url)
    }

    /// Looks up smart account contracts by signer address.
    ///
    /// - Parameter address: A `G…` account or `C…` contract address.
    /// - Returns: The decoded `OZAddressLookupResponse`.
    /// - Throws: `ValidationException.InvalidAddress` when the address is malformed.
    ///   `IndexerException.RequestFailed` on network failure, non-2xx response, or
    ///   decoding failure. `IndexerException.Timeout` on per-request timeout.
    public func lookupByAddress(address: String) async throws -> OZAddressLookupResponse {
        try requireStellarAddress(address, fieldName: "address")
        let url = "\(baseUrl)/api/lookup/address/\(address)"
        return try await performRequest(url: url)
    }

    /// Gets detailed information about a smart account contract.
    ///
    /// - Parameter contractId: The contract ID (`C…` strkey).
    /// - Returns: The decoded `OZContractDetailsResponse`.
    /// - Throws: `ValidationException.InvalidAddress` when the contract ID is
    ///   malformed. `IndexerException.RequestFailed` on network failure, non-2xx
    ///   response, or decoding failure. `IndexerException.Timeout` on per-request
    ///   timeout.
    public func getContract(contractId: String) async throws -> OZContractDetailsResponse {
        try requireContractAddress(contractId, fieldName: "contractId")
        let url = "\(baseUrl)/api/contract/\(contractId)"
        return try await performRequest(url: url)
    }

    /// Gets aggregate statistics from the indexer.
    ///
    /// - Returns: The decoded `OZIndexerStatsResponse`.
    /// - Throws: `IndexerException.RequestFailed` on network failure, non-2xx
    ///   response, or decoding failure. `IndexerException.Timeout` on per-request
    ///   timeout.
    public func getStats() async throws -> OZIndexerStatsResponse {
        let url = "\(baseUrl)/api/stats"
        return try await performRequest(url: url)
    }

    /// Checks if the indexer service is reachable and healthy.
    ///
    /// Performs a lightweight `GET /` and returns `true` only when the server
    /// responds with HTTP 2xx AND a parsed `HealthCheckResponse` whose `status`
    /// equals `"ok"`. Any other outcome — non-2xx status, decode failure, network
    /// error, or timeout — returns `false`. This method does NOT throw.
    ///
    /// - Returns: `true` if the indexer is healthy and reachable; `false` otherwise.
    public func isHealthy() async -> Bool {
        let url = "\(baseUrl)/"
        guard let urlObject = URL(string: url) else {
            return false
        }

        var request = URLRequest(url: urlObject, timeoutInterval: timeoutInterval)
        request.httpMethod = "GET"
        ozApplyDefaultHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            if !(200...299).contains(httpResponse.statusCode) {
                return false
            }
            // why: enforce the indexer body cap here too. `isHealthy()` is
            // contractually a never-throws probe, so an oversize body returns
            // `false` rather than surfacing the protocol failure as an
            // exception. A compromised endpoint cannot bypass the size guard
            // by responding on the health route.
            if data.count > OZConstants.maxIndexerResponseBytes {
                return false
            }
            // why: a non-JSON Content-Type signals a proxy / gateway error
            // page rather than a real health response; treat it as unhealthy.
            if !ozResponseIsJson(httpResponse.value(forHTTPHeaderField: "Content-Type")) {
                return false
            }
            let decoder = JSONDecoder()
            let healthCheck = try decoder.decode(OZIndexerHealthCheckResponse.self, from: data)
            return healthCheck.status == OZIndexerClient.healthStatusOk
        } catch {
            return false
        }
    }

    /// Releases the owned `URLSession` and marks the client as closed.
    ///
    /// When the client was constructed with a caller-supplied `urlSession`, the
    /// caller retains ownership and the session is NOT invalidated. After `close()`
    /// completes the client must not be used again; subsequent calls to `close()`
    /// are safe no-ops.
    public func close() {
        stateLock.lock()
        defer { stateLock.unlock() }
        if isClosed {
            return
        }
        isClosed = true
        if !urlSessionWasInjected {
            urlSession.invalidateAndCancel()
        }
    }

    deinit {
        if !urlSessionWasInjected {
            urlSession.invalidateAndCancel()
        }
    }

    // MARK: - Private helpers

    /// Issues a GET request, decodes the JSON response body, and maps HTTP / network
    /// failures into `IndexerException` instances.
    private func performRequest<T: Decodable>(url: String) async throws -> T {
        guard let urlObject = URL(string: url) else {
            throw IndexerException.requestFailed(reason: "Invalid URL: \(url)")
        }

        var request = URLRequest(url: urlObject, timeoutInterval: timeoutInterval)
        request.httpMethod = "GET"
        ozApplyDefaultHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw IndexerException.timeout(url: url, cause: error)
        } catch {
            let message = error.localizedDescription
            throw IndexerException.requestFailed(reason: message, cause: error)
        }

        if data.count > OZConstants.maxIndexerResponseBytes {
            throw IndexerException.requestFailed(
                reason: "Response body exceeds maximum size of \(OZConstants.maxIndexerResponseBytes) bytes"
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IndexerException.requestFailed(reason: "Response is not an HTTP response")
        }

        let statusCode = httpResponse.statusCode
        if !(200...299).contains(statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? "(unable to decode response body)"
            let truncatedBody = ozTruncateBody(errorBody)
            throw IndexerException.requestFailed(reason: "HTTP \(statusCode): \(truncatedBody)")
        }

        // why: a proxy / gateway error page typically arrives with
        // `Content-Type: text/html` even when the upstream protocol is JSON.
        // Surface the actual transport failure here rather than letting it
        // bubble up as an opaque JSON decode error.
        let responseContentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        if !ozResponseIsJson(responseContentType),
           let contentType = responseContentType {
            throw IndexerException.requestFailed(
                reason: "Unexpected Content-Type: \(ozTruncateBody(contentType))"
            )
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let exception as SmartAccountException {
            throw exception
        } catch {
            throw IndexerException.requestFailed(reason: error.localizedDescription, cause: error)
        }
    }

    /// Converts a base64url-encoded string to lowercase hex with no `0x` prefix.
    ///
    /// The SDK stores credential IDs in base64url format (RFC 4648, no padding). The
    /// indexer API expects hex encoding without any prefix. Invalid base64url input
    /// surfaces as `ValidationException.InvalidInput`.
    private func base64UrlToHex(_ base64url: String) throws -> String {
        do {
            let bytes = try Data(base64URLEncoded: base64url)
            return bytes.base16EncodedString()
        } catch {
            throw ValidationException.invalidInput(
                field: "credentialId",
                reason: "Failed to decode base64url credential ID"
            )
        }
    }
}
