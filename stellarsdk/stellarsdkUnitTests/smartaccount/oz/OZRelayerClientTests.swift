//
//  OZRelayerClientTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZRelayerClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - XDR fixtures

    /// Creates a minimal `HostFunctionXDR` suitable for round-tripping through the
    /// relayer payload encoder. Uses the all-zero contract ID, function name
    /// `"hello"`, and a single symbol argument `"world"`.
    private func createTestHostFunction() -> HostFunctionXDR {
        let contractAddress = SCAddressXDR.contract(WrappedData32(Data(count: 32)))
        let args = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "hello",
            args: [SCValXDR.symbol("world")]
        )
        return HostFunctionXDR.invokeContract(args)
    }

    /// Creates a minimal `SorobanAuthorizationEntryXDR` with void credentials so the
    /// fixture round-trips without requiring signed credentials.
    private func createTestAuthEntry() -> SorobanAuthorizationEntryXDR {
        let contractAddress = SCAddressXDR.contract(WrappedData32(Data(count: 32)))
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "hello",
            args: []
        )
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(invokeArgs),
            subInvocations: []
        )
        return SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.sourceAccount,
            rootInvocation: invocation
        )
    }

    /// Creates a minimal `TransactionEnvelopeXDR.v1` envelope with a bump-sequence
    /// operation. The envelope round-trips through `xdrEncoded` and `init(xdr:)` so
    /// the relayer payload assertion `endsWith` works as expected.
    private func createTestTransactionEnvelope() -> TransactionEnvelopeXDR {
        let muxedSource = MuxedAccountXDR.ed25519([UInt8](repeating: 0, count: 32))
        let bumpOp = BumpSequenceOperationXDR(bumpTo: 1)
        let nilSource: MuxedAccountXDR? = nil
        let operation = OperationXDR(
            sourceAccount: nilSource,
            body: OperationBodyXDR.bumpSequenceOp(bumpOp)
        )
        let preconditions = PreconditionsXDR.none
        let tx = TransactionXDR(
            sourceAccount: muxedSource,
            seqNum: 1,
            cond: preconditions,
            memo: MemoXDR.none,
            operations: [operation],
            maxOperationFee: 100
        )
        return TransactionEnvelopeXDR.v1(TransactionV1EnvelopeXDR(tx: tx, signatures: []))
    }

    // MARK: - Helpers

    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func installResponder(
        body: String,
        statusCode: Int = 200,
        contentType: String = "application/json"
    ) {
        MockURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": contentType]
            )!
            return .success((response, body.data(using: .utf8)))
        }
    }

    private func installCapturingResponder(
        body: String,
        statusCode: Int = 200,
        bodyCapture: @escaping (String) -> Void
    ) {
        MockURLProtocol.requestHandler = { request in
            let payloadData = request.httpBody ?? Data()
            bodyCapture(String(data: payloadData, encoding: .utf8) ?? "")
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return .success((response, body.data(using: .utf8)))
        }
    }

    private func installThrowingResponder(error: Error) {
        MockURLProtocol.requestHandler = { _ in
            return .failure(error)
        }
    }

    // MARK: - Constructor validation

    func testConstructor_blankUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZRelayerClient(relayerUrl: "")) { error in
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_whitespaceUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZRelayerClient(relayerUrl: "   ")) { error in
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_httpUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZRelayerClient(relayerUrl: "http://relayer.example.com")) { error in
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_httpsUrlSucceeds() throws {
        let client = try OZRelayerClient(relayerUrl: "https://relayer.example.com")
        client.close()
    }

    func testConstructor_localhostHttpUrlSucceeds() throws {
        let client = try OZRelayerClient(relayerUrl: "http://localhost:3000")
        client.close()
    }

    func testConstructor_localhostWithoutPortSucceeds() throws {
        let client = try OZRelayerClient(relayerUrl: "http://localhost")
        client.close()
    }

    func testConstructor_trailingSlashNormalization() throws {
        let client = try OZRelayerClient(relayerUrl: "https://relayer.example.com///")
        client.close()
    }

    func testConstructor_trailingSlashNormalization_resolvesCanonicalRequestUrl() async throws {
        // why: a base URL supplied with trailing slashes must be normalised
        // so the outbound request URL is the canonical form (no trailing
        // slashes). Captures the actual request URL via `requestInspector`
        // and asserts the canonical form was used.
        var capturedUrl: String?
        MockURLProtocol.requestInspector = { request in
            capturedUrl = request.url?.absoluteString ?? ""
        }
        installResponder(body: #"{"success": true, "data": {"hash": "abc"}}"#)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com///",
            urlSession: session
        )
        defer { relayer.close() }

        _ = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertEqual(
            "https://relayer.example.com",
            capturedUrl,
            "Trailing slashes must be normalised away in the outbound request URL"
        )
    }

    func testConstructor_ftpSchemeThrows() {
        XCTAssertThrowsError(try OZRelayerClient(relayerUrl: "ftp://relayer.example.com")) { error in
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_noSchemeThrows() {
        XCTAssertThrowsError(try OZRelayerClient(relayerUrl: "relayer.example.com")) { error in
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_customTimeoutIsAccepted() throws {
        let client = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            timeoutMs: 10_000
        )
        client.close()
    }

    func testConstructor_leadingWhitespaceUrl_succeedsAfterTrim() throws {
        let client = try OZRelayerClient(relayerUrl: "  https://relayer.example.com")
        client.close()
    }

    func testConstructor_trailingNewlineUrl_succeedsAfterTrim() throws {
        let client = try OZRelayerClient(relayerUrl: "https://relayer.example.com\n")
        client.close()
    }

    func testConstructor_schemeOnlyUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZRelayerClient(relayerUrl: "https://")) { error in
            XCTAssertTrue(error is ConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_ownsSession_disallowsHttpRedirects() throws {
        // why: when the client owns its `URLSession` it must attach an
        // `OZNoRedirectDelegate` so a 3xx response from the configured host
        // cannot redirect signed authorization-entry or transaction-envelope
        // payloads (and pinned `X-Client-*` headers) to a third-party URL,
        // which would bypass the HTTPS-only constructor check.
        let client = try OZRelayerClient(relayerUrl: "https://relayer.example.com")
        defer { client.close() }

        XCTAssertNotNil(
            client.noRedirectDelegateForTesting,
            "Client that owns its URLSession must attach a no-redirect delegate"
        )
    }

    func testConstructor_injectedSession_doesNotOwnRedirectDelegate() throws {
        // why: when the caller injects a `URLSession`, the redirect-handling
        // policy belongs to the caller — the client does not attach its own
        // delegate. Verified by asserting the test-only accessor is `nil`.
        let injected = URLSession(configuration: .ephemeral)
        let client = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: injected
        )
        defer { client.close() }

        XCTAssertNil(
            client.noRedirectDelegateForTesting,
            "Client with injected URLSession must not attach its own redirect delegate"
        )
    }

    // MARK: - send: success

    func testSend_success_returnsHash() async throws {
        installResponder(
            body: #"{"success": true, "data": {"hash": "abc123", "transactionId": "tx-001", "status": "PENDING"}}"#
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual("abc123", response.hash)
        XCTAssertEqual("tx-001", response.transactionId)
        XCTAssertEqual("PENDING", response.status)
    }

    func testSend_buildsCorrectJsonPayload() async throws {
        var capturedBody: String?
        installCapturingResponder(
            body: #"{"success": true, "data": {"hash": "abc123"}}"#
        ) { capturedBody = $0 }
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual("abc123", response.hash)

        XCTAssertNotNil(capturedBody)
        let payloadData = capturedBody!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: payloadData, options: []) as! [String: Any]

        XCTAssertNotNil(parsed["func"])
        let funcValue = parsed["func"] as? String ?? ""
        XCTAssertFalse(funcValue.isEmpty)

        XCTAssertNotNil(parsed["auth"])
        let authArray = parsed["auth"] as? [String] ?? []
        XCTAssertEqual(1, authArray.count)
        XCTAssertFalse(authArray[0].isEmpty)
    }

    func testSend_errorResponse_returnsErrorWithCode() async throws {
        installResponder(
            body: #"{"success": false, "error": "simulation failed", "code": "SIMULATION_FAILED"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("simulation failed", response.error)
        XCTAssertEqual("SIMULATION_FAILED", response.errorCode)
    }

    func testSend_errorWithNestedDataCode_returnsCorrectErrorCode() async throws {
        installResponder(
            body: #"{"success": false, "error": "tx failed", "data": {"code": "ONCHAIN_FAILED", "details": "..."}}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("tx failed", response.error)
        XCTAssertEqual("ONCHAIN_FAILED", response.errorCode)
    }

    func testSend_nonJsonResponse_returnsError() async throws {
        // why: a non-JSON `Content-Type` (here `text/html`) is short-circuited
        // by the response-header guard before the JSON decoder is reached.
        // The surfaced error names the actual transport failure (the
        // unexpected Content-Type) rather than a generic JSON decode error.
        installResponder(body: "<html>Bad Gateway</html>", contentType: "text/html")
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.contains("Unexpected Content-Type"))
    }

    func testSend_nonJsonContentTypeWithJsonBody_returnsContentTypeError() async throws {
        // why: even when the body happens to be valid JSON, a non-JSON
        // `Content-Type` (here `text/html`) indicates a proxy / gateway
        // error page. The guard must short-circuit so the surfaced error
        // names the transport failure rather than the (otherwise parseable)
        // body.
        installResponder(
            body: #"{"success": true, "hash": "abc"}"#,
            contentType: "text/html"
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(
            response.error!.contains("Unexpected Content-Type"),
            "Surfaced error must name the unexpected Content-Type header"
        )
    }

    func testSend_networkError_returnsError() async throws {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: URLError.cannotConnectToHost.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Connection refused"]
        )
        installThrowingResponder(error: error)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
    }

    // MARK: - send: oversize response

    func testSend_oversizeResponseBody_returnsErrorResponse() async throws {
        // why: the relayer never throws on protocol failures, so a body over the
        // documented cap must surface as OZRelayerResponse(success: false, ...)
        // rather than propagating an exception or buffering an arbitrarily large
        // body into memory.
        let oversizeBytes = OZConstants.maxRelayerResponseBytes + 1024
        let oversizeBody = String(repeating: "a", count: oversizeBytes)
        installResponder(body: oversizeBody)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(
            response.error!.contains("exceeds maximum size"),
            "Error message must indicate the body exceeded the configured cap"
        )
        XCTAssertNil(response.errorCode)
    }

    // MARK: - send: timeout

    func testSend_timeout_returnsTimeoutErrorCode() async throws {
        installThrowingResponder(error: MockURLProtocol.timeoutError)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual(OZRelayerErrorCodes.TIMEOUT, response.errorCode)
        XCTAssertTrue(response.error!.contains("timed out"))
    }

    // MARK: - send: perRequestTimeoutMs

    func testSend_withPerRequestTimeout_overridesConstructorDefault() async throws {
        installResponder(body: #"{"success": true, "data": {"hash": "timeout-test-hash"}}"#)
        var capturedTimeout: TimeInterval?
        MockURLProtocol.requestInspector = { request in
            capturedTimeout = request.timeoutInterval
        }
        let session = makeMockSession()
        // why: constructor default (60 s here) is deliberately longer than the
        // per-request override so a regression that ignores the override would
        // surface as a captured value matching the constructor default rather
        // than the requested 5 s.
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            timeoutMs: 60_000,
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()],
            perRequestTimeoutMs: 5_000
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual("timeout-test-hash", response.hash)
        XCTAssertNotNil(capturedTimeout)
        XCTAssertEqual(5.0, capturedTimeout!, accuracy: 0.001)
    }

    func testSend_withoutPerRequestTimeout_usesConstructorDefault() async throws {
        installResponder(body: #"{"success": true, "data": {"hash": "default-timeout-hash"}}"#)
        var capturedTimeout: TimeInterval?
        MockURLProtocol.requestInspector = { request in
            capturedTimeout = request.timeoutInterval
        }
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            timeoutMs: 45_000,
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual("default-timeout-hash", response.hash)
        XCTAssertNotNil(capturedTimeout)
        XCTAssertEqual(45.0, capturedTimeout!, accuracy: 0.001)
    }

    // MARK: - sendXdr: success

    func testSendXdr_success_returnsHash() async throws {
        installResponder(
            body: #"{"success": true, "data": {"hash": "def456", "transactionId": "tx-002", "status": "SUCCESS"}}"#
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.sendXdr(transactionEnvelope: createTestTransactionEnvelope())
        XCTAssertTrue(response.success)
        XCTAssertEqual("def456", response.hash)
        XCTAssertEqual("tx-002", response.transactionId)
        XCTAssertEqual("SUCCESS", response.status)
    }

    func testSendXdr_buildsCorrectJsonPayload() async throws {
        var capturedBody: String?
        installCapturingResponder(
            body: #"{"success": true, "data": {"hash": "def456"}}"#
        ) { capturedBody = $0 }
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.sendXdr(transactionEnvelope: createTestTransactionEnvelope())
        XCTAssertTrue(response.success)
        XCTAssertEqual("def456", response.hash)

        XCTAssertNotNil(capturedBody)
        let payloadData = capturedBody!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: payloadData, options: []) as! [String: Any]

        XCTAssertNotNil(parsed["xdr"])
        let xdrValue = parsed["xdr"] as? String ?? ""
        XCTAssertFalse(xdrValue.isEmpty)

        let decoded = try TransactionEnvelopeXDR(xdr: xdrValue)
        switch decoded {
        case .v1:
            // expected envelope variant
            break
        default:
            XCTFail("Expected V1 transaction envelope; got \(decoded)")
        }
    }

    func testSendXdr_errorResponse_returnsError() async throws {
        installResponder(
            body: #"{"success": false, "error": "invalid xdr", "code": "INVALID_XDR"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.sendXdr(transactionEnvelope: createTestTransactionEnvelope())
        XCTAssertFalse(response.success)
        XCTAssertEqual("invalid xdr", response.error)
        XCTAssertEqual("INVALID_XDR", response.errorCode)
    }

    func testSendXdr_timeout_returnsTimeoutErrorCode() async throws {
        installThrowingResponder(error: MockURLProtocol.timeoutError)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.sendXdr(transactionEnvelope: createTestTransactionEnvelope())
        XCTAssertFalse(response.success)
        XCTAssertEqual(OZRelayerErrorCodes.TIMEOUT, response.errorCode)
        XCTAssertTrue(response.error!.contains("timed out"))
    }

    // MARK: - Response parsing

    func testResponseParsing_withDataWrapper_extractsNestedFields() async throws {
        installResponder(
            body: #"{"success": true, "data": {"transactionId": "tx-100", "hash": "hash-100", "status": "PENDING"}}"#
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual("tx-100", response.transactionId)
        XCTAssertEqual("hash-100", response.hash)
        XCTAssertEqual("PENDING", response.status)
    }

    func testResponseParsing_withoutDataWrapper_usesTopLevelFields() async throws {
        installResponder(
            body: #"{"success": true, "transactionId": "tx-200", "hash": "hash-200", "status": "SUCCESS"}"#
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual("tx-200", response.transactionId)
        XCTAssertEqual("hash-200", response.hash)
        XCTAssertEqual("SUCCESS", response.status)
    }

    func testResponseParsing_errorFromErrorField() async throws {
        installResponder(
            body: #"{"success": false, "error": "specific error message"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("specific error message", response.error)
    }

    func testResponseParsing_nonObjectDataPayload_wrappedAsValueKey() async throws {
        // why: when the relayer emits a non-object value (string, number,
        // array, bool, null) under `data`, the decoder wraps it under the
        // key `"value"` so callers always observe a uniform
        // `[String: OZJSONValue]` shape. Pins that wrapping behaviour.
        installResponder(
            body: #"{"success": false, "error": "x", "data": "raw-string"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.details)
        XCTAssertEqual(
            OZJSONValue.string("raw-string"),
            response.details?["value"],
            "Non-object `data` payloads must be wrapped under the key `\"value\"`"
        )
    }

    func testResponseParsing_errorFallbackToMessageField() async throws {
        installResponder(
            body: #"{"success": false, "message": "fallback error message"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("fallback error message", response.error)
    }

    // MARK: - extractErrorCode

    func testExtractErrorCode_topLevelCode() async throws {
        installResponder(
            body: #"{"success": false, "error": "failed", "code": "SIMULATION_FAILED"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("SIMULATION_FAILED", response.errorCode)
    }

    func testExtractErrorCode_errorCodeField() async throws {
        installResponder(
            body: #"{"success": false, "error": "unauthorized", "errorCode": "UNAUTHORIZED"}"#,
            statusCode: 403
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("UNAUTHORIZED", response.errorCode)
    }

    func testExtractErrorCode_nestedDataCode() async throws {
        installResponder(
            body: #"{"success": false, "error": "failed", "data": {"code": "ONCHAIN_FAILED"}}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("ONCHAIN_FAILED", response.errorCode)
    }

    func testExtractErrorCode_topLevelCodeWinsOverErrorCodeAndNestedData() async throws {
        // why: when multiple candidate fields are present the lookup order
        // is top-level `code`, then top-level `errorCode`, then nested
        // `data.code`. Stub a response that populates all three and assert
        // the top-level `code` wins.
        installResponder(
            body: #"{"success": false, "error": "failed", "code": "A", "errorCode": "B", "data": {"code": "C"}}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual(
            "A",
            response.errorCode,
            "Top-level `code` must take precedence over `errorCode` and nested `data.code`"
        )
    }

    func testExtractErrorCode_errorCodeWinsOverNestedDataCode() async throws {
        // why: when top-level `code` is absent the lookup order is
        // top-level `errorCode` before nested `data.code`. Stub a response
        // that exercises this disambiguation and assert top-level
        // `errorCode` wins.
        installResponder(
            body: #"{"success": false, "error": "x", "errorCode": "B", "data": {"code": "C"}}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual(
            "B",
            response.errorCode,
            "Top-level `errorCode` must take precedence over nested `data.code`"
        )
    }

    func testExtractErrorCode_noCodeFieldReturnsNull() async throws {
        installResponder(
            body: #"{"success": false, "error": "something went wrong"}"#,
            statusCode: 400
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertEqual("something went wrong", response.error)
        XCTAssertNil(response.errorCode)
    }

    // MARK: - Status code fallback message

    func testErrorResponse_statusCodeFallback_whenNoErrorOrMessageField() async throws {
        installResponder(body: #"{"success": false}"#, statusCode: 502)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(
            response.error!.contains("502"),
            "Error message must contain the HTTP status code when no error/message field is present"
        )
    }

    // MARK: - close

    func testClose_clientIsAutoCloseable() throws {
        let relayer = try OZRelayerClient(relayerUrl: "https://relayer.example.com")
        relayer.close()
    }

    func testClose_doubleCloseDoesNotThrow() throws {
        let relayer = try OZRelayerClient(relayerUrl: "https://relayer.example.com")
        relayer.close()
        relayer.close()
    }

    // MARK: - OZRelayerErrorCodes constants

    func testOZRelayerErrorCodes_allCodesAreNonBlank() {
        let codes: [String] = [
            OZRelayerErrorCodes.INVALID_PARAMS,
            OZRelayerErrorCodes.INVALID_XDR,
            OZRelayerErrorCodes.POOL_CAPACITY,
            OZRelayerErrorCodes.SIMULATION_FAILED,
            OZRelayerErrorCodes.ONCHAIN_FAILED,
            OZRelayerErrorCodes.INVALID_TIME_BOUNDS,
            OZRelayerErrorCodes.FEE_LIMIT_EXCEEDED,
            OZRelayerErrorCodes.UNAUTHORIZED,
            OZRelayerErrorCodes.TIMEOUT,
        ]
        for code in codes {
            XCTAssertFalse(
                code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Error code must not be blank: '\(code)'"
            )
        }
    }

    func testOZRelayerErrorCodes_specificValues() {
        XCTAssertEqual("TIMEOUT", OZRelayerErrorCodes.TIMEOUT)
        XCTAssertEqual("INVALID_PARAMS", OZRelayerErrorCodes.INVALID_PARAMS)
        XCTAssertEqual("INVALID_XDR", OZRelayerErrorCodes.INVALID_XDR)
        XCTAssertEqual("POOL_CAPACITY", OZRelayerErrorCodes.POOL_CAPACITY)
        XCTAssertEqual("SIMULATION_FAILED", OZRelayerErrorCodes.SIMULATION_FAILED)
        XCTAssertEqual("ONCHAIN_FAILED", OZRelayerErrorCodes.ONCHAIN_FAILED)
        XCTAssertEqual("INVALID_TIME_BOUNDS", OZRelayerErrorCodes.INVALID_TIME_BOUNDS)
        XCTAssertEqual("FEE_LIMIT_EXCEEDED", OZRelayerErrorCodes.FEE_LIMIT_EXCEEDED)
        XCTAssertEqual("UNAUTHORIZED", OZRelayerErrorCodes.UNAUTHORIZED)
    }

    // MARK: - send: error message truncation

    func testSend_errorMessageIsTruncated() async throws {
        // why: a hostile relayer can return a multi-KiB error string; the
        // truncation guard caps it to at most 200 characters plus a 3-char
        // ellipsis so it cannot bloat caller-side logs or UI surfaces.
        let longMessage = String(repeating: "E", count: 5000)
        let body = #"{"success": false, "error": "\#(longMessage)"}"#
        installResponder(body: body, statusCode: 400)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(
            203,
            response.error!.count,
            "Truncated error must be exactly 200 characters plus a 3-character ellipsis"
        )
        XCTAssertTrue(
            response.error!.hasSuffix("..."),
            "Truncated error must end with the literal ellipsis marker"
        )
        XCTAssertTrue(
            response.error!.hasPrefix(String(repeating: "E", count: 200)),
            "Truncated error must preserve the first 200 characters of the input"
        )
    }

    // MARK: - Request: missing Content-Type

    func testRequest_missingContentType_fallsThroughToJsonParse() async throws {
        // why: a missing `Content-Type` header must be treated as JSON so
        // well-behaved endpoints that omit the header on short success
        // responses are not surfaced as transport failures. Builds a
        // 200 response with an empty `headerFields` map and asserts the
        // success path returns a parsed `OZRelayerResponse`.
        MockURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
            let body = #"{"success": true, "data": {"hash": "abc123"}}"#
            return .success((response, body.data(using: .utf8)))
        }
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertTrue(response.success, "Missing Content-Type must not block successful decoding")
        XCTAssertEqual("abc123", response.hash)
    }

    // MARK: - send: strict success extraction

    func testSend_intSuccessFieldNotCoerced() async throws {
        // why: real relayers always emit a JSON boolean for `success`; an
        // integer value (here `1`) must NOT be coerced to `true`. Forbidding
        // coercion prevents a mistyped success field from tricking the
        // client into reporting a failed submission as successful.
        installResponder(
            body: #"{"success": 1, "hash": "x"}"#,
            statusCode: 200
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(
            response.success,
            "An integer `success` field must NOT be coerced to a successful response"
        )
    }

    func testSend_stringSuccessFieldNotCoerced() async throws {
        // why: a string value (here `"true"`) for the `success` field must
        // NOT be coerced. `JSONDecoder.decode(Bool.self)` throws
        // `DecodingError.typeMismatch` for a string value; that throw is
        // swallowed and the field collapses to `false`.
        installResponder(
            body: #"{"success": "true", "hash": "x"}"#,
            statusCode: 200
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(
            response.success,
            "A string `success` field must NOT be coerced to a successful response"
        )
    }

    func testSend_absentSuccessFieldDefaultsToFalse() async throws {
        // why: when the `success` key is entirely absent from the body the
        // decoder must default to `false` rather than treating the response
        // as successful. Guards against a relayer that silently drops the
        // field on partial or malformed responses.
        installResponder(
            body: #"{"hash": "x"}"#,
            statusCode: 200
        )
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        let response = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertFalse(
            response.success,
            "An absent `success` field must default to a failed response"
        )
    }

    // MARK: - OZRelayerResponse equality

    func testOZRelayerResponse_equalityWithIdenticalFields() {
        // why: pins the auto-synthesized Equatable behavior on
        // OZRelayerResponse so a future refactor that introduces a custom
        // implementation cannot silently regress structural equality —
        // including deep equality on the nested `details` dictionary.
        let detailsA: [String: OZJSONValue] = [
            "outer": .object([
                "inner": .array([.integer(1), .integer(2), .integer(3)]),
                "flag": .bool(true),
            ]),
            "extra": .string("value"),
        ]
        let detailsB: [String: OZJSONValue] = [
            "outer": .object([
                "inner": .array([.integer(1), .integer(2), .integer(3)]),
                "flag": .bool(true),
            ]),
            "extra": .string("value"),
        ]
        let a = OZRelayerResponse(
            success: false,
            transactionId: "tx",
            hash: "h",
            status: "PENDING",
            error: "oops",
            errorCode: "SIMULATION_FAILED",
            details: detailsA
        )
        let b = OZRelayerResponse(
            success: false,
            transactionId: "tx",
            hash: "h",
            status: "PENDING",
            error: "oops",
            errorCode: "SIMULATION_FAILED",
            details: detailsB
        )
        XCTAssertEqual(a, b)
    }

    func testOZRelayerResponse_inequalityWithDifferentDetails() {
        // why: a single nested-value difference in `details` must propagate
        // through the auto-synthesized Equatable and produce inequality;
        // otherwise callers diffing two relayer responses would miss the
        // change.
        let a = OZRelayerResponse(
            success: false,
            error: "oops",
            details: [
                "outer": .object([
                    "inner": .array([.integer(1), .integer(2), .integer(3)]),
                ]),
            ]
        )
        let b = OZRelayerResponse(
            success: false,
            error: "oops",
            details: [
                "outer": .object([
                    "inner": .array([.integer(1), .integer(2), .integer(4)]),
                ]),
            ]
        )
        XCTAssertNotEqual(
            a,
            b,
            "A nested-value difference in details must make OZRelayerResponse instances unequal"
        )
    }

    // MARK: - OZRelayerResponse Hashable

    func testOZRelayerResponse_hashEqualForIdenticalFields() {
        // why: structurally identical `OZRelayerResponse` instances must
        // hash to the same value so they can be inserted into a
        // `Set<OZRelayerResponse>` or used as `Dictionary` keys without
        // surprising collisions. Pins the custom `Hashable` implementation
        // attached when `OZJSONValue` was made hashable.
        let details: [String: OZJSONValue] = [
            "outer": .object([
                "inner": .array([.integer(1), .integer(2), .integer(3)]),
                "flag": .bool(true),
            ]),
            "extra": .string("value"),
        ]
        let a = OZRelayerResponse(
            success: true,
            transactionId: "tx",
            hash: "h",
            status: "PENDING",
            error: nil,
            errorCode: nil,
            details: details
        )
        let b = OZRelayerResponse(
            success: true,
            transactionId: "tx",
            hash: "h",
            status: "PENDING",
            error: nil,
            errorCode: nil,
            details: details
        )
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertEqual(Set([a, b]).count, 1)
    }

    func testOZRelayerResponse_hashCollisionAvoidedForDifferentDetails() {
        // why: `Set` semantics depend on `==` for equality but use `hashValue`
        // for bucketing. Two responses that differ only in a deeply nested
        // `details` payload must produce different hash values often enough
        // that they don't collide in practice. This test pins the
        // auto-synthesized behavior — identical hashing of unequal values
        // would not be a correctness bug (it's permitted by `Hashable`) but
        // would point at a regression in the custom `OZJSONValue.hash(into:)`
        // implementation that does not distinguish the two payloads at all.
        let a = OZRelayerResponse(
            success: false,
            error: "oops",
            details: [
                "outer": .object([
                    "inner": .array([.integer(1), .integer(2), .integer(3)]),
                ]),
            ]
        )
        let b = OZRelayerResponse(
            success: false,
            error: "oops",
            details: [
                "outer": .object([
                    "inner": .array([.integer(1), .integer(2), .integer(4)]),
                ]),
            ]
        )
        XCTAssertNotEqual(a, b)
        XCTAssertNotEqual(
            a.hashValue,
            b.hashValue,
            "Responses with different nested-value details must hash to different values"
        )
    }

    // MARK: - SDK identification headers

    func testPerformRequest_attachesSdkIdentificationHeaders() async throws {
        // why: every outbound relayer request must carry the SDK
        // identification headers so the server can attribute traffic.
        // Captures the inbound `URLRequest.allHTTPHeaderFields` via
        // `MockURLProtocol.requestInspector` and asserts the two SDK
        // identification headers are present and non-empty.
        var capturedHeaders: [String: String]?
        MockURLProtocol.requestInspector = { request in
            capturedHeaders = request.allHTTPHeaderFields
        }
        installResponder(body: #"{"success": true, "data": {"hash": "abc"}}"#)
        let session = makeMockSession()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: session
        )
        defer { relayer.close() }

        _ = await relayer.send(
            hostFunction: createTestHostFunction(),
            authEntries: [createTestAuthEntry()]
        )
        XCTAssertNotNil(capturedHeaders)
        let clientName = capturedHeaders?[OZConstants.clientNameHeader]
        let clientVersion = capturedHeaders?[OZConstants.clientVersionHeader]
        XCTAssertNotNil(clientName, "Client-name header must be attached")
        XCTAssertFalse(clientName?.isEmpty ?? true, "Client-name header must be non-empty")
        XCTAssertNotNil(clientVersion, "Client-version header must be attached")
        XCTAssertFalse(clientVersion?.isEmpty ?? true, "Client-version header must be non-empty")
    }
}
