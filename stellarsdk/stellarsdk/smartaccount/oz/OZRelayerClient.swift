//
//  OZRelayerClient.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Relayer Error Codes

/// Known error codes returned by the OpenZeppelin Smart Account relayer service.
///
/// These string constants identify specific failure conditions and can be compared
/// directly against `OZRelayerResponse.errorCode` for programmatic error handling. The
/// constant identifier and string value are intentionally identical so that the
/// printed and compared forms always match.
public enum OZRelayerErrorCodes {
    public static let INVALID_PARAMS: String = "INVALID_PARAMS"
    public static let INVALID_XDR: String = "INVALID_XDR"
    public static let POOL_CAPACITY: String = "POOL_CAPACITY"
    public static let SIMULATION_FAILED: String = "SIMULATION_FAILED"
    public static let ONCHAIN_FAILED: String = "ONCHAIN_FAILED"
    public static let INVALID_TIME_BOUNDS: String = "INVALID_TIME_BOUNDS"
    public static let FEE_LIMIT_EXCEEDED: String = "FEE_LIMIT_EXCEEDED"
    public static let UNAUTHORIZED: String = "UNAUTHORIZED"
    public static let TIMEOUT: String = "TIMEOUT"
}

// MARK: - Relayer Response

/// Response from the relayer service.
///
/// The relayer wraps user transactions with fee bumps and submits them to Stellar,
/// enabling gasless onboarding for accounts with no XLM balance.
///
/// - `success`: `true` when the relayer accepted the transaction.
/// - `transactionId`: relayer-assigned identifier when submission succeeded.
/// - `hash`: Stellar transaction hash returned by the relayer when available.
/// - `status`: transaction status string (for example `"PENDING"`, `"SUCCESS"`,
///   `"ERROR"`).
/// - `error`: human-readable error message when the request failed. Capped at
///   200 characters with a trailing `"..."` ellipsis when the relayer
///   returns a longer body, preventing a hostile server from forcing
///   arbitrarily large strings into caller-side logs.
/// - `errorCode`: machine-readable error code; one of the `OZRelayerErrorCodes`
///   constants when populated.
/// - `details`: additional details JSON forwarded from the relayer body's `data`
///   field. When the relayer emits a JSON object under `data`, its keys appear
///   verbatim. When the relayer emits a non-object value (string, number, array,
///   bool, or `null`) under `data`, the value is wrapped as `["value": <wrapped>]`
///   so callers always observe a `[String: OZJSONValue]` shape. `nil` when the
///   relayer omits `data` entirely.
public struct OZRelayerResponse: Decodable, Equatable, Hashable, Sendable {
    public let success: Bool
    public let transactionId: String?
    public let hash: String?
    public let status: String?
    public let error: String?
    public let errorCode: String?
    /// Additional details JSON forwarded from the relayer body's `data` field.
    /// When the relayer emits a JSON object under `data`, its keys appear verbatim.
    /// When the relayer emits a non-object value (string, number, array, bool, or
    /// `null`) under `data`, the value is wrapped as `["value": <wrapped>]` so
    /// callers always observe a `[String: OZJSONValue]` shape. `nil` when the
    /// relayer omits `data` entirely.
    public let details: [String: OZJSONValue]?

    public init(
        success: Bool,
        transactionId: String? = nil,
        hash: String? = nil,
        status: String? = nil,
        error: String? = nil,
        errorCode: String? = nil,
        details: [String: OZJSONValue]? = nil
    ) {
        self.success = success
        self.transactionId = transactionId
        self.hash = hash
        self.status = status
        self.error = error
        self.errorCode = errorCode
        self.details = details
    }

    /// Top-level coding keys; the same envelope is also used to look inside
    /// the nested `data` object when the relayer returns the wrapped shape.
    private enum CodingKeys: String, CodingKey {
        case success
        case transactionId
        case hash
        case status
        case error
        case message
        case code
        case errorCode
        case data
    }

    /// Decodes from either the wrapped envelope (`{"success": ..., "data": {...}}`)
    /// or the flat envelope (`{"success": ..., "hash": ..., ...}`).
    ///
    /// `transactionId`, `hash`, and `status` are read from the nested `data` object
    /// if present, falling back to top-level. `error` and `errorCode` use a fixed
    /// lookup order (`code` → `errorCode` → nested `data.code`) and read text from
    /// `error` then `message`. `details` is sourced from the nested `data` object;
    /// non-object `data` payloads (string, number, array, bool, null) are wrapped
    /// under the key `"value"` so callers always observe a `[String: OZJSONValue]`.
    /// `nil` means the relayer omitted `data` entirely.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // why: only an actual JSON boolean must produce `true`. A mistyped
        // integer (`1`) or string (`"true"`) must NOT be coerced —
        // `JSONDecoder.decode(Bool.self)` throws `DecodingError.typeMismatch`
        // for non-boolean values; `try?` swallows that and `??` collapses
        // both throw and absent-key cases to `false`. Strict-Bool extraction
        // prevents a malformed `success` field from masking a failed
        // submission as successful.
        self.success = (try? container.decodeIfPresent(Bool.self, forKey: .success)) ?? false

        // why: the wrapped envelope nests payload fields under `data`. Try
        // decoding the nested object first; fall back to the top-level
        // values when no nested object is present. Both shapes are accepted —
        // see the struct DocC.
        let nested = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)

        if let nested = nested,
           let value = try nested.decodeIfPresent(String.self, forKey: .transactionId) {
            self.transactionId = value
        } else {
            self.transactionId = try container.decodeIfPresent(String.self, forKey: .transactionId)
        }

        if let nested = nested,
           let value = try nested.decodeIfPresent(String.self, forKey: .hash) {
            self.hash = value
        } else {
            self.hash = try container.decodeIfPresent(String.self, forKey: .hash)
        }

        if let nested = nested,
           let value = try nested.decodeIfPresent(String.self, forKey: .status) {
            self.status = value
        } else {
            self.status = try container.decodeIfPresent(String.self, forKey: .status)
        }

        if let value = try container.decodeIfPresent(String.self, forKey: .error),
           !value.isEmpty {
            self.error = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .message),
                  !value.isEmpty {
            self.error = value
        } else {
            self.error = nil
        }

        // Lookup order: top-level `code`, top-level `errorCode`, nested `data.code`.
        var resolvedErrorCode: String? = nil
        if let value = try container.decodeIfPresent(String.self, forKey: .code),
           !value.isEmpty {
            resolvedErrorCode = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .errorCode),
                  !value.isEmpty {
            resolvedErrorCode = value
        } else if let nested = nested,
                  let value = try nested.decodeIfPresent(String.self, forKey: .code),
                  !value.isEmpty {
            resolvedErrorCode = value
        }
        self.errorCode = resolvedErrorCode

        // `details` resolution order: nested `data` object form, then nested
        // `data` non-object form (wrapped in a single-key `"value"` map),
        // then `nil`.
        var resolvedDetails: [String: OZJSONValue]? = nil
        if container.contains(.data) {
            if let dict = try? container.decodeIfPresent([String: OZJSONValue].self, forKey: .data) {
                resolvedDetails = dict
            } else if let value = try? container.decodeIfPresent(OZJSONValue.self, forKey: .data) {
                resolvedDetails = ["value": value]
            }
        }
        self.details = resolvedDetails
    }
}

// MARK: - Relayer Client

/// Client for submitting transactions to an OpenZeppelin Smart Account relayer.
///
/// The relayer wraps user transactions with fee bumps and submits them to Stellar,
/// supplying the transaction fee on behalf of the user. Two submission modes are
/// supported:
///
/// 1. **Host function + auth entries** via `send(hostFunction:authEntries:)`: the
///    relayer assembles the full transaction from the supplied components.
/// 2. **Signed transaction envelope** via `sendXdr(transactionEnvelope:)`: the relayer
///    fee-bumps the supplied envelope, preserving the inner signatures (required
///    for source-account auth such as contract deployments).
///
/// Example:
/// ```swift
/// let relayer = try OZRelayerClient(relayerUrl: "https://relayer.example.com")
/// let response = try await relayer.send(hostFunction: hf, authEntries: entries)
/// if response.success {
///     print("Transaction hash: \(response.hash ?? "unknown")")
/// } else {
///     print("Error: \(response.error ?? "unknown") (\(response.errorCode ?? ""))")
/// }
/// relayer.close()
/// ```
///
/// The client validates its `relayerUrl` argument at construction. HTTPS is required,
/// with `http://localhost` allowed for development. Both submission methods capture
/// all failure modes in the returned `OZRelayerResponse`; they do not throw network or
/// HTTP errors directly. Only XDR encoding failures surface in the response via the
/// `error` field — exceptions are not propagated.
///
/// Subclassing contract: `OZRelayerClient` is `open`-able for test doubles. Any
/// subclass that overrides ``close()`` MUST either call `super.close()` or invoke
/// the internal teardown helper, otherwise the owned `URLSession` will leak. The
/// SDK recording mocks (`MockOZRelayerClient`) follow this pattern; consumer code
/// is generally expected to inject a custom `urlSession` rather than subclass.
public class OZRelayerClient: @unchecked Sendable {

    // MARK: - Instance state

    /// Normalized base URL (no trailing slashes).
    private let normalizedUrl: String

    /// Default per-request timeout in seconds; applied when `perRequestTimeoutMs` is
    /// `nil`. Per-request overrides bypass this value.
    private let defaultTimeoutInterval: TimeInterval

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

    /// Set once `close()` has been called; subsequent `close()` calls are no-ops.
    private var isClosed: Bool = false

    /// Synchronizes access to `isClosed` so `close()` is safe to call concurrently.
    private let stateLock = NSLock()

    /// Test-only accessor exposing the no-redirect delegate attached to the
    /// owned `URLSession`. `nil` when the caller injected a `URLSession`.
    /// Used by unit tests to verify that redirects are denied on owned sessions.
    internal var noRedirectDelegateForTesting: OZNoRedirectDelegate? { noRedirectDelegate }

    // MARK: - Initialization

    /// Creates a new `OZRelayerClient`.
    ///
    /// - Parameters:
    ///   - relayerUrl: The relayer endpoint URL. Must start with `https://` or
    ///     `http://localhost` (with optional port and path).
    ///   - timeoutMs: Default request timeout in milliseconds. Defaults to
    ///     `OZConstants.defaultRelayerTimeoutMs` (6 minutes) to accommodate testnet
    ///     submission retries.
    ///   - urlSession: Optional pre-configured `URLSession`. Use this to
    ///     inject a test mock OR to apply production transport configuration
    ///     such as certificate pinning, proxy settings, or request inspection.
    ///     When `nil`, the client builds an ephemeral session whose redirect
    ///     handler denies all 3xx redirects to protect signed
    ///     `SorobanAuthorizationEntryXDR` / `TransactionEnvelopeXDR`
    ///     payloads and pinned identification headers; the owned session is
    ///     invalidated on `close()`. When an injected session is supplied,
    ///     the redirect-handling policy of that session is the caller's
    ///     responsibility.
    /// - Throws: `ConfigurationException.InvalidConfig` when the URL is blank or
    ///   does not satisfy the HTTPS / localhost constraint.
    public init(
        relayerUrl: String,
        timeoutMs: Int64 = OZConstants.defaultRelayerTimeoutMs,
        urlSession: URLSession? = nil
    ) throws {
        let trimmedUrl = relayerUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUrl.isEmpty {
            throw ConfigurationException.invalidConfig(details: "Relayer URL is required")
        }
        if !trimmedUrl.hasPrefix("https://") && !isLocalhostUrl(trimmedUrl) {
            throw ConfigurationException.invalidConfig(
                details: "Relayer URL must use HTTPS (or http://localhost for development): \(trimmedUrl)"
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
                details: "Relayer URL must include a host: \(trimmedUrl)"
            )
        }
        self.normalizedUrl = stripped

        let timeoutSeconds = TimeInterval(timeoutMs) / 1000.0
        self.defaultTimeoutInterval = timeoutSeconds

        if let injected = urlSession {
            self.urlSession = injected
            self.urlSessionWasInjected = true
            self.noRedirectDelegate = nil
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = timeoutSeconds
            configuration.timeoutIntervalForResource = timeoutSeconds
            // why: SDK identification headers are pinned at the configuration layer
            // so every outbound request carries them, even if a future code path
            // overrides other request-specific headers.
            configuration.httpAdditionalHeaders = ozBuildDefaultHeaders()
            // why: refuse HTTP redirects so a 3xx response from the configured
            // host cannot redirect signed authorization-entry / transaction
            // envelope payloads (and pinned `X-Client-*` headers) to a
            // third-party URL, which would bypass the HTTPS-only constructor
            // check.
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

    /// Submits a transaction using a host function and authorization entries.
    ///
    /// The relayer constructs the full transaction from the supplied components,
    /// wraps it with a fee bump, and submits it to the Stellar network. This method
    /// does not throw network or HTTP errors; all failure modes are captured in the
    /// returned `OZRelayerResponse`. Only XDR encoding failures (pre-request) surface
    /// as `OZRelayerResponse(success: false, error: ...)` with no `errorCode`.
    ///
    /// - Parameters:
    ///   - hostFunction: The host function to execute.
    ///   - authEntries: Authorization entries for the transaction.
    ///   - perRequestTimeoutMs: Optional per-request timeout override in milliseconds.
    ///     When supplied, overrides the timeout supplied to the constructor for this
    ///     single request.
    /// - Returns: The relayer response with transaction hash or error details.
    public func send(
        hostFunction: HostFunctionXDR,
        authEntries: [SorobanAuthorizationEntryXDR],
        perRequestTimeoutMs: Int64? = nil
    ) async -> OZRelayerResponse {
        guard let funcBase64 = hostFunction.xdrEncoded else {
            return OZRelayerResponse(
                success: false,
                error: "Failed to encode host function to XDR"
            )
        }

        var authBase64Array: [String] = []
        authBase64Array.reserveCapacity(authEntries.count)
        for entry in authEntries {
            guard let encoded = entry.xdrEncoded else {
                return OZRelayerResponse(
                    success: false,
                    error: "Failed to encode auth entry to XDR"
                )
            }
            authBase64Array.append(encoded)
        }

        let payload: [String: Any] = [
            "func": funcBase64,
            "auth": authBase64Array,
        ]
        return await performRequest(payload: payload, perRequestTimeoutMs: perRequestTimeoutMs)
    }

    /// Submits a signed transaction envelope.
    ///
    /// Use this when the transaction requires source-account authentication (for
    /// example, smart account contract deployments). The relayer fee-bumps the
    /// signed envelope, preserving the inner signatures. This method does not throw
    /// network or HTTP errors; all failure modes are captured in the returned
    /// `OZRelayerResponse`.
    ///
    /// - Parameters:
    ///   - transactionEnvelope: The signed `TransactionEnvelopeXDR` to submit.
    ///   - perRequestTimeoutMs: Optional per-request timeout override in milliseconds.
    /// - Returns: The relayer response with transaction hash or error details.
    public func sendXdr(
        transactionEnvelope: TransactionEnvelopeXDR,
        perRequestTimeoutMs: Int64? = nil
    ) async -> OZRelayerResponse {
        guard let xdrBase64 = transactionEnvelope.xdrEncoded else {
            return OZRelayerResponse(
                success: false,
                error: "Failed to encode transaction envelope to XDR"
            )
        }

        let payload: [String: Any] = [
            "xdr": xdrBase64
        ]
        return await performRequest(payload: payload, perRequestTimeoutMs: perRequestTimeoutMs)
    }

    /// Releases the owned `URLSession` and marks the client as closed.
    ///
    /// When the client was constructed with a caller-supplied `urlSession`, the
    /// caller retains ownership and the session is NOT invalidated. After `close()`
    /// completes the client must not be used again; subsequent calls to `close()`
    /// are safe no-ops.
    ///
    /// Subclasses overriding this method MUST call `super.close()` (or
    /// ``performCloseInternal()`` directly) to invalidate the owned
    /// `URLSession`; otherwise the underlying transport leaks.
    public func close() {
        performCloseInternal()
    }

    /// Performs the canonical close sequence: idempotent state flip plus
    /// `URLSession` invalidation when the session is owned.
    ///
    /// Subclasses that override ``close()`` should call this helper from
    /// their override so the resource teardown remains correct even if the
    /// override is reordered or augmented with additional bookkeeping.
    public final func performCloseInternal() {
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

    /// Issues a POST request, decodes the JSON response body via `JSONDecoder`,
    /// and maps every failure mode into a `OZRelayerResponse`. This method
    /// never throws — network, HTTP, decoding, and oversize-body failures all
    /// surface as `OZRelayerResponse(success: false, ...)`.
    private func performRequest(
        payload: [String: Any],
        perRequestTimeoutMs: Int64?
    ) async -> OZRelayerResponse {
        guard let urlObject = URL(string: normalizedUrl) else {
            return OZRelayerResponse(
                success: false,
                error: "Invalid relayer URL: \(normalizedUrl)"
            )
        }

        // why: the request payload is built as a Swift dictionary of
        // primitives. `JSONSerialization` is the only Foundation-supplied
        // encoder that accepts a heterogeneous `[String: Any]` directly,
        // and the inputs are constrained at the call site (a base64 string
        // and an array of base64 strings) so the encoder cannot surface
        // arbitrary nested-type concerns.
        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            return OZRelayerResponse(
                success: false,
                error: "Failed to encode request payload: \(error.localizedDescription)"
            )
        }

        let timeoutInterval: TimeInterval
        if let override = perRequestTimeoutMs {
            timeoutInterval = TimeInterval(override) / 1000.0
        } else {
            timeoutInterval = defaultTimeoutInterval
        }

        var request = URLRequest(url: urlObject, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        ozApplyDefaultHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = bodyData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            return OZRelayerResponse(
                success: false,
                error: "Relayer request timed out",
                errorCode: OZRelayerErrorCodes.TIMEOUT
            )
        } catch {
            return OZRelayerResponse(
                success: false,
                error: error.localizedDescription
            )
        }

        if data.count > OZConstants.maxRelayerResponseBytes {
            return OZRelayerResponse(
                success: false,
                error: "Response body exceeds maximum size of \(OZConstants.maxRelayerResponseBytes) bytes"
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return OZRelayerResponse(
                success: false,
                error: "Relayer response is not an HTTP response"
            )
        }

        // why: a proxy or gateway error page typically arrives with
        // `Content-Type: text/html` even when the upstream protocol is JSON.
        // Short-circuit the JSON decode in that case so the surfaced error
        // names the actual transport failure rather than a generic decoding
        // error.
        let responseContentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        if !ozResponseIsJson(responseContentType),
           let contentType = responseContentType {
            return OZRelayerResponse(
                success: false,
                error: "Unexpected Content-Type: \(ozTruncateBody(contentType))"
            )
        }

        let decoder = JSONDecoder()
        let parsed: OZRelayerResponse
        do {
            parsed = try decoder.decode(OZRelayerResponse.self, from: data)
        } catch {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            return OZRelayerResponse(
                success: false,
                error: "Failed to parse relayer response as JSON: \(ozTruncateBody(bodyString))"
            )
        }

        let statusCode = httpResponse.statusCode
        let httpSuccess = (200...299).contains(statusCode)

        if httpSuccess && parsed.success {
            // why: drop `errorCode` / `error` carried by the envelope on success
            // so a successful response is unambiguous.
            return OZRelayerResponse(
                success: true,
                transactionId: parsed.transactionId,
                hash: parsed.hash,
                status: parsed.status
            )
        }

        // Failure path. The relayer's `error` field is a server-curated
        // string intended for direct display, often containing a transaction
        // simulation error followed by a multi-line diagnostic event log. The
        // overall body is already bounded by `ozMaxRelayerResponseBytes`; a
        // second per-string cap would drop the event log without preserving
        // the most actionable trailing context.
        let errorMessage = parsed.error ?? "Relayer request failed with status \(statusCode)"

        return OZRelayerResponse(
            success: false,
            error: errorMessage,
            errorCode: parsed.errorCode,
            details: parsed.details
        )
    }
}
