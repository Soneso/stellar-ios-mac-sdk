//
//  OZNoRedirectDelegate.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - No-Redirect URLSession Delegate

/// `URLSessionTaskDelegate` that refuses every HTTP redirect by answering the
/// redirect completion handler with `nil`, surfacing the original 3xx response
/// to the request site as a failure.
///
/// Redirects are dangerous here because the OZ HTTP clients only validate the
/// configured endpoint scheme at construction; a 3xx response could otherwise
/// silently forward security-sensitive request payloads and identification
/// headers to an unintended (possibly plain-`http://`) host, since `URLSession`
/// follows up to five redirects by default.
///
/// Caveat: this delegate is attached only to sessions the client constructs
/// itself. When a caller injects a `URLSession`, that session's redirect
/// behavior is the caller's responsibility.
internal final class OZNoRedirectDelegate: NSObject, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil) // LCOV_EXCL_LINE
    }
}
