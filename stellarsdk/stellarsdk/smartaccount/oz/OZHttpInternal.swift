//
//  OZHttpInternal.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Shared helpers for OZ HTTP clients

/// Truncates a body or message string to at most `maxChars` characters,
/// appending a literal `"..."` ellipsis when the input is longer.
///
/// Used by both `OZIndexerClient` and `OZRelayerClient` to cap arbitrarily
/// large server-supplied strings (raw response body snippets surfaced in
/// JSON parse failures, server-supplied error messages echoed back to
/// callers) so a hostile remote endpoint cannot force unbounded text into
/// caller-side logs or rendered UI surfaces.
///
/// - Parameters:
///   - body: The input string to truncate.
///   - maxChars: Maximum number of characters retained before the trailing
///     ellipsis. Defaults to 200, matching the documented cap on both
///     clients' surfaced error strings.
/// - Returns: The original string when its character count is at most
///   `maxChars`; otherwise the first `maxChars` characters followed by
///   `"..."`.
internal func ozTruncateBody(_ body: String, maxChars: Int = 200) -> String {
    if body.count > maxChars {
        let prefixIndex = body.index(body.startIndex, offsetBy: maxChars)
        return String(body[..<prefixIndex]) + "..."
    }
    return body
}

/// Resolves the SDK identification version string for outbound HTTP requests
/// from the framework bundle's `CFBundleShortVersionString`. Falls back to
/// `"unknown"` when the bundle metadata is unavailable (for example, when
/// the framework is consumed outside a packaged build).
///
/// The value is cached at the call site (`ozClientVersionValue`) because the
/// version cannot change at runtime; the lookup happens once per process.
internal func ozResolveClientVersion() -> String {
    // why: `Bundle(for:)` requires a class type defined inside the framework
    // module so it resolves to the framework bundle rather than the host app
    // bundle. `OZHttpInternalBundleAnchor` exists only to serve as that
    // anchor; it carries no state and is never instantiated.
    let frameworkBundle = Bundle(for: OZHttpInternalBundleAnchor.self)
    if let version = frameworkBundle.infoDictionary?["CFBundleShortVersionString"] as? String,
       !version.isEmpty {
        return version
    }
    return "unknown"
}

/// Cached SDK identification version. Computed once on first access; the
/// underlying bundle value cannot change at runtime.
internal let ozClientVersionValue: String = ozResolveClientVersion()

/// Returns the headers attached to every outbound OZ HTTP request, keyed
/// for `URLSessionConfiguration.httpAdditionalHeaders`. Includes the SDK
/// client-name and version identification headers so every request issued
/// through the configured session carries them.
internal func ozBuildDefaultHeaders() -> [AnyHashable: Any] {
    var headers: [AnyHashable: Any] = [:]
    headers[OZConstants.clientNameHeader] = OZConstants.clientName
    headers[OZConstants.clientVersionHeader] = ozClientVersionValue
    return headers
}

/// Applies the SDK identification headers to a single `URLRequest`. Required
/// so that injected test sessions (which do not inherit
/// `URLSessionConfiguration.httpAdditionalHeaders` set by the client) still
/// observe the same headers as production traffic.
internal func ozApplyDefaultHeaders(to request: inout URLRequest) {
    request.setValue(OZConstants.clientName, forHTTPHeaderField: OZConstants.clientNameHeader)
    request.setValue(ozClientVersionValue, forHTTPHeaderField: OZConstants.clientVersionHeader)
}

/// Returns the canonical, lowercased media type extracted from a
/// `Content-Type` header value by dropping any `;`-delimited parameters
/// and trimming surrounding whitespace.
///
/// Used by `ozResponseIsJson` to perform strict equality on the media
/// type rather than a prefix check, which would otherwise admit values
/// such as `application/jsonx` or `application/json5` that are not in
/// fact JSON.
@inline(__always) private func mediaType(of contentType: String) -> String {
    let semi = contentType.firstIndex(of: ";")
    let raw = semi.map { String(contentType[..<$0]) } ?? contentType
    return raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

/// Returns `true` when the supplied `Content-Type` header value indicates
/// a JSON body, and `false` when the header is present but indicates
/// something else (for example `text/html`). A `nil` header is treated as
/// JSON to remain permissive against well-behaved endpoints that omit the
/// header on short success responses.
///
/// The media type is compared by strict equality after dropping any
/// `;`-delimited parameter segment, so `application/json; charset=utf-8`
/// is accepted while `application/jsonx` is rejected.
///
/// Used by both clients to short-circuit decoding when the remote endpoint
/// returns a non-JSON payload (typical for proxy / gateway error pages
/// served with `text/html` even when the upstream protocol is JSON).
internal func ozResponseIsJson(_ contentType: String?) -> Bool {
    guard let contentType else { return true }
    let media = mediaType(of: contentType)
    return media == "application/json" || media == "application/problem+json"
}

// MARK: - Bundle anchor

/// Internal sentinel type used as the `Bundle(for:)` anchor inside
/// `ozResolveClientVersion`. Anchoring on a class declared in this module
/// guarantees `Bundle(for:)` resolves to the framework bundle rather than
/// the host-app bundle.
internal final class OZHttpInternalBundleAnchor {}
