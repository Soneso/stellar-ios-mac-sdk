//
//  OZNoRedirectDelegate.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - No-Redirect URLSession Delegate

/// `URLSessionTaskDelegate` that refuses every HTTP redirect.
///
/// The OZ HTTP clients (`OZIndexerClient`, `OZRelayerClient`) validate at
/// construction that their configured endpoint uses `https://` (or
/// `http://localhost` for development). Without this delegate, a 3xx response
/// from the configured host could silently redirect outbound requests to a
/// third-party `http://` URL — `URLSession` follows up to five redirects by
/// default. Such a redirect would defeat the HTTPS-only check and forward
/// security-sensitive material to an unintended host:
///
/// - Signed `SorobanAuthorizationEntryXDR` and `TransactionEnvelopeXDR`
///   payloads (relayer `POST` bodies).
/// - `X-Client-*` identification headers pinned at the session configuration
///   level (both clients).
///
/// By implementing `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)`
/// and invoking the completion handler with `nil`, every redirect is denied and
/// the client surfaces the original 3xx response to the request site, where it
/// is treated as a failure.
///
/// One instance is created and retained per owning client; the client
/// constructs a `URLSession` with this delegate when no `URLSession` was
/// injected by the caller. When a caller injects a `URLSession`, the redirect
/// behavior of the injected session is the caller's responsibility — this
/// delegate is not attached to injected sessions.
internal final class OZNoRedirectDelegate: NSObject, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
