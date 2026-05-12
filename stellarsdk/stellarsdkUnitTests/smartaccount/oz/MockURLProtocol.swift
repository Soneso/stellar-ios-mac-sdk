//
//  MockURLProtocol.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// `URLProtocol` subclass that intercepts every `URLRequest` issued through a
/// `URLSession` configured with this protocol installed via
/// `URLSessionConfiguration.protocolClasses`. Each test installs a handler closure
/// that inspects the inbound request (URL, headers, body) and returns the canned
/// response data, HTTP status, and content-type to deliver.
///
/// Two failure modes are supported in addition to canned responses: handlers may
/// return a `Result.failure(error)` to surface a URL-loading error in the same way
/// the platform networking stack would, and the static `timeoutError` constant
/// returns a `URLError(.timedOut)` that the production code converts into an
/// `IndexerException.Timeout` / `OZRelayerErrorCodes.TIMEOUT`.
///
/// Usage:
/// ```swift
/// let configuration = URLSessionConfiguration.ephemeral
/// configuration.protocolClasses = [MockURLProtocol.self]
/// let session = URLSession(configuration: configuration)
/// MockURLProtocol.requestHandler = { request in
///     let data = #"{"status":"ok"}"#.data(using: .utf8)!
///     let response = HTTPURLResponse(url: request.url!, statusCode: 200,
///                                    httpVersion: nil,
///                                    headerFields: ["Content-Type": "application/json"])!
///     return .success((response, data))
/// }
/// let client = try OZIndexerClient(indexerUrl: "https://test.example.com",
///                                  urlSession: session)
/// ```
///
/// Multiple `MockURLProtocol` instances share the same `requestHandler` static; the
/// `setUp` and `tearDown` methods in each test reset the handler between cases.
final class MockURLProtocol: URLProtocol {

    /// Result returned by the test handler for one request. Either a canned response
    /// (with optional body data) or an error that should surface to the client.
    typealias HandlerResult = Result<(HTTPURLResponse, Data?), Error>

    /// Closure invoked for every intercepted request. Tests assign this property to
    /// inspect the request and return the desired response. The closure must be
    /// reset between tests via `tearDown`; otherwise the previous test's handler
    /// would leak into the next.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) -> HandlerResult)?

    /// Optional inspector that captures the inbound request for assertion side
    /// effects (URL, headers, body). Invoked before `requestHandler`. Tests use this
    /// to assert request shape (URL path, query string, request body bytes) without
    /// duplicating the handler closure across cases.
    nonisolated(unsafe) static var requestInspector: ((URLRequest) -> Void)?

    /// A standard timeout error matching the one the platform networking stack
    /// produces. Tests pass this through `requestHandler` to simulate a request
    /// timeout without waiting for the actual timeout interval to elapse.
    static var timeoutError: NSError {
        return NSError(
            domain: NSURLErrorDomain,
            code: URLError.timedOut.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
        )
    }

    /// Resets the handler and inspector between tests so leakage between cases is
    /// impossible. Call this in every `tearDown`.
    static func reset() {
        requestHandler = nil
        requestInspector = nil
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Drain a streamed body into a buffer so test inspectors can compare against
        // the produced JSON. `URLRequest.httpBody` is `nil` once the request enters
        // the protocol pipeline; the body is exposed via `httpBodyStream` instead.
        var inspectedRequest = request
        if inspectedRequest.httpBody == nil, let stream = inspectedRequest.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = Data()
            let bufferSize = 4096
            var bytes = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&bytes, maxLength: bufferSize)
                if read <= 0 {
                    break
                }
                buffer.append(bytes, count: read)
            }
            inspectedRequest.httpBody = buffer
        }

        if let inspector = MockURLProtocol.requestInspector {
            inspector(inspectedRequest)
        }

        guard let handler = MockURLProtocol.requestHandler else {
            let error = NSError(
                domain: NSURLErrorDomain,
                code: URLError.unknown.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "MockURLProtocol.requestHandler not set"]
            )
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        switch handler(inspectedRequest) {
        case .success(let (response, data)):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op; the canned response is delivered synchronously in `startLoading`.
    }
}
