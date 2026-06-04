//
//  MockSorobanServer.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Scriptable transport-layer mock for `SorobanServer` consumed by the OZ
/// smart-account pipeline tests.
///
/// `SorobanServer`'s public RPC methods (`simulateTransaction`,
/// `sendTransaction`, `getTransaction`, `getLatestLedger`, `getLedgerEntries`)
/// are not declared `open` and cannot be overridden across modules. The mock
/// therefore intercepts at the `URLSession` boundary by installing
/// `MockURLProtocol` as a global `URLProtocol` subclass: every
/// `URLSession.shared` request issued by `SorobanServer` flows through the
/// mock handler, which inspects the JSON-RPC `method` field on the request
/// body and dispatches to a per-method scripted response.
///
/// ## Lifecycle
/// 1. `setUp` calls `MockSorobanServer.activate(script:)` to register
///    `MockURLProtocol` and install the script reference.
/// 2. The test populates the script with canned responses via
///    `enqueueSimulate`, `setSendResponse`, etc.
/// 3. The test invokes the production code (which reaches out to
///    `URLSession.shared` and lands in the mock).
/// 4. The test asserts against `script.simulateCalls`, `script.sendCalls`,
///    etc.
/// 5. `tearDown` calls `MockSorobanServer.deactivate()` so leaked state cannot
///    contaminate the next case.
///
/// ## Important
/// The mock returns minimal-but-valid JSON-RPC envelopes. Scripted responses
/// supply the JSON-shaped result payload directly so tests do not have to
/// construct typed response objects whose initializers are not publicly
/// reachable from the test target.
final class MockSorobanServerScript: @unchecked Sendable {

    /// Singleton script accessed by the global `MockURLProtocol`
    /// request handler. Reset between tests.
    nonisolated(unsafe) static var current: MockSorobanServerScript?

    private let scriptLock = NSLock()

    // MARK: - Scripted responses (JSON-RPC result payloads)

    private var simulateResults: [[String: Any]] = []
    private var simulateErrors: [String] = []
    private var sendResults: [[String: Any]] = []
    private var sendDefault: [String: Any]?
    private var getTransactionResults: [[String: Any]] = []
    private var getTransactionDefault: [String: Any]?
    private var getLatestLedgerResult: [String: Any]?
    private var getLedgerEntriesResult: [String: Any]?
    /// FIFO queue consulted before `getLedgerEntriesResult` for sequenced
    /// per-call responses (used by tests that need different ledger-entry
    /// payloads on successive calls).
    private var getLedgerEntriesQueue: [[String: Any]] = []

    // MARK: - Recorded invocations

    private var _simulateCalls: [Data] = []
    private var _sendCalls: [Data] = []
    private var _getTransactionCalls: [String] = []
    private var _getLatestLedgerCalls = 0
    private var _getLedgerEntriesCalls: [Data] = []

    var simulateCallCount: Int {
        scriptLock.lock(); defer { scriptLock.unlock() }
        return _simulateCalls.count
    }
    var sendCallCount: Int {
        scriptLock.lock(); defer { scriptLock.unlock() }
        return _sendCalls.count
    }
    var sendCalls: [Data] {
        scriptLock.lock(); defer { scriptLock.unlock() }
        return _sendCalls
    }
    var getTransactionCalls: [String] {
        scriptLock.lock(); defer { scriptLock.unlock() }
        return _getTransactionCalls
    }
    var getLatestLedgerCallCount: Int {
        scriptLock.lock(); defer { scriptLock.unlock() }
        return _getLatestLedgerCalls
    }
    var getLedgerEntriesCallCount: Int {
        scriptLock.lock(); defer { scriptLock.unlock() }
        return _getLedgerEntriesCalls.count
    }

    // MARK: - Script API

    /// Enqueues a successful simulate-transaction response with the supplied
    /// `latestLedger`, `minResourceFee`, optional `transactionData` (Base64
    /// XDR), optional first-result `xdr` return value (Base64), and optional
    /// `auth` (array of Base64 SorobanAuthorizationEntryXDR strings).
    func enqueueSimulateSuccess(
        latestLedger: Int = 1000,
        minResourceFee: UInt32 = 100_000,
        transactionData: String? = nil,
        resultXdr: String? = nil,
        auth: [String] = []
    ) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        var payload: [String: Any] = [
            "latestLedger": NSNumber(value: latestLedger),
            "minResourceFee": String(minResourceFee)
        ]
        if let txData = transactionData {
            payload["transactionData"] = txData
        }
        var results: [[String: Any]] = []
        var resultEntry: [String: Any] = ["auth": auth]
        if let xdr = resultXdr {
            resultEntry["xdr"] = xdr
        } else {
            resultEntry["xdr"] = ""
        }
        results.append(resultEntry)
        payload["results"] = results
        simulateResults.append(payload)
        simulateErrors.append("")
    }

    /// Enqueues a simulate-transaction response carrying an `error` field.
    /// Production code lifts this into `SmartAccountTransactionException.SimulationFailed`.
    func enqueueSimulateError(_ message: String, latestLedger: Int = 1000) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        let payload: [String: Any] = [
            "latestLedger": NSNumber(value: latestLedger),
            "error": message
        ]
        simulateResults.append(payload)
        simulateErrors.append(message)
    }

    /// Configures the next `sendTransaction` response (FIFO if multiple are
    /// enqueued; otherwise falls back to the default set via this method).
    /// The status maps to one of `SendTransactionResponse.STATUS_*`
    /// (typically `PENDING`, `ERROR`, `DUPLICATE`).
    func setSendSuccess(
        status: String,
        hash: String,
        latestLedger: Int = 1000,
        errorResultXdr: String? = nil
    ) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        var payload: [String: Any] = [
            "status": status,
            "hash": hash,
            "latestLedger": NSNumber(value: latestLedger),
            "latestLedgerCloseTime": "0"
        ]
        if let xdr = errorResultXdr {
            payload["errorResultXdr"] = xdr
        }
        sendDefault = payload
    }

    /// Enqueues an additional `sendTransaction` response consumed before
    /// `sendDefault` is used. Tests that exercise multiple submissions in the
    /// same case populate this queue.
    func enqueueSendResponse(_ payload: [String: Any]) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        sendResults.append(payload)
    }

    /// Enqueues a `getTransaction` response. Multiple entries are consumed in
    /// FIFO order so a polling loop can be modelled across attempts.
    func enqueueGetTransaction(
        status: String,
        ledger: Int? = nil,
        envelopeXdr: String? = nil,
        resultXdr: String? = nil,
        latestLedger: Int = 1000
    ) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        var payload: [String: Any] = [
            "status": status,
            "latestLedger": NSNumber(value: latestLedger),
            "latestLedgerCloseTime": "0",
            "oldestLedger": NSNumber(value: latestLedger - 100),
            "oldestLedgerCloseTime": "0"
        ]
        if let ledger = ledger {
            payload["ledger"] = NSNumber(value: ledger)
        }
        if let envelope = envelopeXdr {
            payload["envelopeXdr"] = envelope
        }
        if let result = resultXdr {
            payload["resultXdr"] = result
        }
        getTransactionResults.append(payload)
    }

    /// Configures the `getLatestLedger` response.
    func setGetLatestLedger(
        sequence: Int,
        id: String = "mock-ledger",
        protocolVersion: Int = 22
    ) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        getLatestLedgerResult = [
            "id": id,
            "protocolVersion": NSNumber(value: protocolVersion),
            "sequence": NSNumber(value: sequence)
        ]
    }

    /// Configures the `getLedgerEntries` response. Each entry is a
    /// `(key, xdr, lastModifiedLedgerSeq)` tuple. The `xdr` field is a
    /// Base64-encoded `LedgerEntryDataXDR`. The `key` field is a Base64-encoded
    /// `LedgerKeyXDR`.
    func setGetLedgerEntries(
        latestLedger: Int = 1000,
        entries: [(key: String, xdr: String, lastModifiedLedgerSeq: Int)]
    ) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        let entriesJson: [[String: Any]] = entries.map { e in
            [
                "key": e.key,
                "xdr": e.xdr,
                "lastModifiedLedgerSeq": NSNumber(value: e.lastModifiedLedgerSeq)
            ]
        }
        getLedgerEntriesResult = [
            "latestLedger": NSNumber(value: latestLedger),
            "entries": entriesJson
        ]
    }

    // MARK: - Internal payload ingestion (consumed by fixture-library extensions)

    /// Stores a fully-formed `simulateTransaction` JSON-RPC `result` payload
    /// produced by the fixture library.
    func ingestSimulateResponse(payload: [String: Any]) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        simulateResults.append(payload)
        let errorMessage = (payload["error"] as? String) ?? ""
        simulateErrors.append(errorMessage)
    }

    /// Stores a fully-formed `getTransaction` JSON-RPC `result` payload
    /// produced by the fixture library.
    func ingestGetTransactionResponse(payload: [String: Any]) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        getTransactionResults.append(payload)
    }

    /// Replaces the active `getLedgerEntries` JSON-RPC `result` payload with
    /// the supplied dictionary.
    func ingestGetLedgerEntriesResponse(payload: [String: Any]) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        getLedgerEntriesResult = payload
    }

    // MARK: - Internal consumers

    fileprivate func consumeSimulate(requestBody: Data) -> [String: Any]? {
        scriptLock.lock(); defer { scriptLock.unlock() }
        _simulateCalls.append(requestBody)
        guard !simulateResults.isEmpty else { return nil }
        let next = simulateResults.removeFirst()
        if !simulateErrors.isEmpty { _ = simulateErrors.removeFirst() }
        return next
    }

    fileprivate func consumeSend(requestBody: Data) -> [String: Any]? {
        scriptLock.lock(); defer { scriptLock.unlock() }
        _sendCalls.append(requestBody)
        if !sendResults.isEmpty {
            return sendResults.removeFirst()
        }
        return sendDefault
    }

    fileprivate func consumeGetTransaction(hash: String) -> [String: Any]? {
        scriptLock.lock(); defer { scriptLock.unlock() }
        _getTransactionCalls.append(hash)
        if !getTransactionResults.isEmpty {
            return getTransactionResults.removeFirst()
        }
        return getTransactionDefault
    }

    /// Configures the default `getTransaction` response returned after the
    /// scripted FIFO queue is exhausted. Used by polling tests where the same
    /// status should be returned for every poll attempt without enqueuing N
    /// copies of the response.
    func setGetTransactionDefault(payload: [String: Any]) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        getTransactionDefault = payload
    }

    fileprivate func consumeGetLatestLedger() -> [String: Any]? {
        scriptLock.lock(); defer { scriptLock.unlock() }
        _getLatestLedgerCalls += 1
        return getLatestLedgerResult
    }

    fileprivate func consumeGetLedgerEntries(requestBody: Data) -> [String: Any]? {
        scriptLock.lock(); defer { scriptLock.unlock() }
        _getLedgerEntriesCalls.append(requestBody)
        if !getLedgerEntriesQueue.isEmpty {
            return getLedgerEntriesQueue.removeFirst()
        }
        return getLedgerEntriesResult
    }

    /// Enqueues a single `getLedgerEntries` response consumed FIFO before the
    /// `getLedgerEntriesResult` default fallback. Tests that need successive
    /// calls to return different ledger-entry payloads (for example
    /// derivation-miss → indexer-verify) populate this queue.
    func enqueueGetLedgerEntriesResponse(_ payload: [String: Any]) {
        scriptLock.lock(); defer { scriptLock.unlock() }
        getLedgerEntriesQueue.append(payload)
    }
}

/// Static helpers wrapping the global `URLProtocol` registration so individual
/// tests can opt into the JSON-RPC interception transport.
enum MockSorobanServer {

    /// Activates the global `MockURLProtocol` interception. Tests call this in
    /// `setUp` after constructing a `MockSorobanServerScript`.
    static func activate(script: MockSorobanServerScript) {
        MockSorobanServerScript.current = script
        URLProtocol.registerClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = { request in
            return handle(request: request, script: script)
        }
    }

    /// Constructs a `SorobanServer` whose owned `URLSession` has
    /// `MockURLProtocol` installed so the active script intercepts every
    /// outbound RPC call.
    static func makeMockedSorobanServer(endpoint: String = "https://mock-rpc.invalid/rpc") -> SorobanServer {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return SorobanServer(endpoint: endpoint, urlSession: session)
    }

    /// Routes one URL request through the supplied script's JSON-RPC handler.
    /// Tests that need to install a custom URL handler (e.g. to intercept
    /// relayer / indexer / friendbot traffic by host) delegate JSON-RPC
    /// methods to this helper so the script-driven flow remains the source
    /// of truth for simulate / send / getTransaction / etc.
    static func handle(
        request: URLRequest,
        script: MockSorobanServerScript
    ) -> MockURLProtocol.HandlerResult {
        let body = extractBody(from: request) ?? Data()
        guard let method = extractRpcMethod(from: body) else {
            return .success((makeHttpResponse(url: request.url), encodeError("missing JSON-RPC method")))
        }
        let resultPayload: [String: Any]?
        switch method {
        case "simulateTransaction":
            resultPayload = script.consumeSimulate(requestBody: body)
        case "sendTransaction":
            resultPayload = script.consumeSend(requestBody: body)
        case "getTransaction":
            let hash = extractStringParam(body: body, key: "hash") ?? ""
            resultPayload = script.consumeGetTransaction(hash: hash)
        case "getLatestLedger":
            resultPayload = script.consumeGetLatestLedger()
        case "getLedgerEntries":
            resultPayload = script.consumeGetLedgerEntries(requestBody: body)
        default:
            return .success((makeHttpResponse(url: request.url), encodeError("unknown method: \(method)")))
        }
        let data: Data
        if let payload = resultPayload {
            data = encodeResult(payload)
        } else {
            data = encodeError("no scripted response for \(method)")
        }
        return .success((makeHttpResponse(url: request.url), data))
    }

    /// Unregisters `MockURLProtocol` and clears the script reference.
    static func deactivate() {
        MockURLProtocol.requestHandler = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockSorobanServerScript.current = nil
    }

    private static func extractBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var buffer = Data()
        let bufferSize = 4096
        var bytes = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&bytes, maxLength: bufferSize)
            if read <= 0 { break }
            buffer.append(bytes, count: read)
        }
        return buffer
    }

    private static func extractRpcMethod(from body: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return nil
        }
        return json["method"] as? String
    }

    private static func extractStringParam(body: Data, key: String) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let params = json["params"] as? [String: Any] else {
            return nil
        }
        return params[key] as? String
    }

    private static func makeHttpResponse(url: URL?) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: url ?? URL(string: "https://mock-rpc.invalid")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    private static func encodeResult(_ result: [String: Any]) -> Data {
        let envelope: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "mock",
            "result": result
        ]
        return (try? JSONSerialization.data(withJSONObject: envelope, options: [])) ?? Data()
    }

    private static func encodeError(_ message: String) -> Data {
        let envelope: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "mock",
            "error": [
                "code": -32000,
                "message": message
            ]
        ]
        return (try? JSONSerialization.data(withJSONObject: envelope, options: [])) ?? Data()
    }
}
