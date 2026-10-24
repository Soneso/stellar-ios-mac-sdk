//
//  EventSourceUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// How `SSEStubProtocol` answers one request.
enum SSEReply {
    /// A response with the status code, then the body chunks, 20 ms apart, then the end of the response.
    case stream(status: Int, chunks: [String])
    /// A 200 response, then the body chunks, 20 ms apart, then a lost connection.
    case connectionLost(afterChunks: [String])
    /// A connection error before any response.
    case connectionError
}

/// Serves scripted Server-Sent Events bytes in chunks, 20 ms apart, then ends the response.
/// Request n gets reply n, the last reply repeats; each request's Last-Event-Id and start time
/// are recorded.
final class SSEStubProtocol: URLProtocol {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var replies = [SSEReply]()
    nonisolated(unsafe) private static var requests = 0
    nonisolated(unsafe) private static var lastEventIds = [String?]()
    nonisolated(unsafe) private static var requestUptimes = [UInt64]()
    nonisolated(unsafe) private static var onRequest: (@Sendable (Int) -> Void)?

    static func serve(_ chunks: [String], then later: [[String]] = [], onRequest: (@Sendable (Int) -> Void)? = nil) {
        serve(replies: ([chunks] + later).map { .stream(status: 200, chunks: $0) }, onRequest: onRequest)
    }

    static func serve(replies: [SSEReply], onRequest: (@Sendable (Int) -> Void)? = nil) {
        lock.lock()
        defer { lock.unlock() }
        self.replies = replies
        self.requests = 0
        self.lastEventIds = []
        self.requestUptimes = []
        self.onRequest = onRequest
    }

    static var recordedLastEventIds: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return lastEventIds
    }

    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }

    /// The `DispatchTime` uptime in nanoseconds at which each request started.
    static var recordedRequestUptimes: [UInt64] {
        lock.lock()
        defer { lock.unlock() }
        return requestUptimes
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        SSEStubProtocol.lock.lock()
        SSEStubProtocol.requests += 1
        SSEStubProtocol.lastEventIds.append(request.value(forHTTPHeaderField: "Last-Event-Id"))
        SSEStubProtocol.requestUptimes.append(DispatchTime.now().uptimeNanoseconds)
        let count = SSEStubProtocol.requests
        let reply = SSEStubProtocol.replies[min(count, SSEStubProtocol.replies.count) - 1]
        let onRequest = SSEStubProtocol.onRequest
        SSEStubProtocol.lock.unlock()
        onRequest?(count)
        switch reply {
        case let .stream(status, chunks):
            respond(status: status, chunks: chunks)
            client?.urlProtocolDidFinishLoading(self)
        case let .connectionLost(chunks):
            respond(status: 200, chunks: chunks)
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
        case .connectionError:
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
        }
    }

    private func respond(status: Int, chunks: [String]) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "text/event-stream"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in chunks {
            Thread.sleep(forTimeInterval: 0.02)
            client?.urlProtocol(self, didLoad: Data(chunk.utf8))
        }
    }

    override func stopLoading() {}
}

/// An EventSource that loads through `SSEStubProtocol` and reports each finished connection.
final class StubbedEventSource: EventSource, @unchecked Sendable {
    var onComplete: (() -> Void)?
    private let completionLock = NSLock()
    private var completionUptimes = [UInt64]()
    private var scheduledDelays = [Int?]()

    /// The `DispatchTime` uptime in nanoseconds at which each connection ended, taken before the
    /// EventSource schedules the reconnect.
    var recordedCompletionUptimes: [UInt64] {
        completionLock.lock()
        defer { completionLock.unlock() }
        return completionUptimes
    }

    /// The reconnect delay in milliseconds that the EventSource scheduled after each connection.
    var recordedScheduledDelays: [Int?] {
        completionLock.lock()
        defer { completionLock.unlock() }
        return scheduledDelays
    }

    override func newSession(_ configuration: URLSessionConfiguration) -> URLSession {
        configuration.protocolClasses = [SSEStubProtocol.self]
        return super.newSession(configuration)
    }

    override func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // The lock spans `super`, so a reader that sees the next request also sees both records.
        completionLock.lock()
        completionUptimes.append(DispatchTime.now().uptimeNanoseconds)
        super.urlSession(session, task: task, didCompleteWithError: error)
        scheduledDelays.append(lastScheduledReconnectDelay)
        completionLock.unlock()
        onComplete?()
    }
}

final class EventSourceUnitTests: XCTestCase {

    private var source: StubbedEventSource?

    override func tearDown() {
        source?.close()
        source = nil
        super.tearDown()
    }

    func testRecordWhoseJsonHoldsRetryTextIsDelivered() {
        let received = callbacks(from: ["retry: 1000\nevent: open\ndata: \"hello\"\n\n",
                                        "id: 7\ndata: {\"memo\":\"ret", "ry: later\"}\n\n"])
        XCTAssertEqual(received, [Callback("onMessage", "7", "message", "{\"memo\":\"retry: later\"}")])
    }

    func testStandaloneRetryLineSetsReconnectDelay() {
        let received = callbacks(from: ["retry: 10", "00\n\n", "data: x\n\n"])
        XCTAssertEqual(received, [Callback("onMessage", nil, "message", "x")])
        XCTAssertEqual(source?.retryTime, 1000)
    }

    func testMultiLineDataJoinsWithNewline() {
        let received = callbacks(from: ["data: first\r", "\ndata: second\r\n\r\n", "data: third\rdata\r\r"])
        XCTAssertEqual(received, [Callback("onMessage", nil, "message", "first\nsecond"),
                                  Callback("onMessage", nil, "message", "third\n")])
    }

    func testCommentLineUnknownFieldAndNulIdAreIgnored() {
        let received = callbacks(from: [": keep-alive\nx-unknown: 1\nid: 5\ndata: x\n\n", ":\n\n",
                                        "id: 6\u{0}\ndata: y\n\n"])
        XCTAssertEqual(received, [Callback("onMessage", "5", "message", "x"),
                                  Callback("onMessage", "5", "message", "y")])
    }

    func testNamedEventReachesItsListener() {
        // All first-connection callbacks are recorded for exact comparison.
        let received = callbacks(from: ["retry: 1000\nevent: open\ndata: \"hello\"\n\n",
                                        "data: a\n\nevent: message\ndata: b\n\nevent:\ndata: c\n\n"],
                                 listeners: ["open", "message"])
        XCTAssertEqual(received, [Callback("open", nil, "open", "\"hello\""),
                                  Callback("onMessage", nil, "message", "a"), Callback("message", nil, "message", "a"),
                                  Callback("onMessage", nil, "message", "b"), Callback("message", nil, "message", "b"),
                                  Callback("onMessage", nil, "message", "c"), Callback("message", nil, "message", "c")])
    }

    func testCutOffRecordIdDoesNotBecomeTheResumePosition() {
        let thirdRequest = expectation(description: "third request")
        SSEStubProtocol.serve(["retry: 50\n\n", "id: 7\ndata: a\n\n", "id: 8\n"],
                              then: [["data: hello\n\n"], []]) { count in
            if count == 3 { thirdRequest.fulfill() }
        }
        let source = StubbedEventSource(url: "https://horizon.example.com/ledgers?cursor=now")
        self.source = source
        wait(for: [thirdRequest], timeout: 5)
        XCTAssertEqual(Array(SSEStubProtocol.recordedLastEventIds.prefix(3)), [nil, "7", "7"])
    }

    func testCloseDuringReconnectDelayCreatesNoNewTask() {
        let finished = expectation(description: "first connection finished, reconnect scheduled")
        finished.assertForOverFulfill = false
        let reconnected = expectation(description: "second request")
        reconnected.isInverted = true
        SSEStubProtocol.serve(["retry: 300\n\n", "data: x\n\n"]) { count in
            if count == 2 { reconnected.fulfill() }
        }
        let source = StubbedEventSource(url: "https://horizon.example.com/ledgers?cursor=now")
        self.source = source
        source.onComplete = { finished.fulfill() }
        wait(for: [finished], timeout: 5)

        source.close()
        wait(for: [reconnected], timeout: 1)
        XCTAssertEqual(SSEStubProtocol.requestCount, 1)
        XCTAssertNil(source.urlSession)
    }

    func testConnectionErrorAfterShortRetryWaitsAtLeastOneSecond() throws {
        let reconnects = try observeReconnects([.stream(status: 200, chunks: ["retry: 10\n\n"]), .connectionError])
        XCTAssertEqual(reconnects[1].scheduled, 1000)
        XCTAssertGreaterThanOrEqual(reconnects[1].measured, 1.0)
        XCTAssertEqual(source?.retryTime, 10)
    }

    func testOrderlyEndAfterSuccessResponseWaitsServerRetry() throws {
        let reconnects = try observeReconnects([.stream(status: 200, chunks: ["retry: 10\n\n"])])
        XCTAssertEqual(reconnects[0].scheduled, 10)
        XCTAssertGreaterThanOrEqual(reconnects[0].measured, 0.01)
    }

    func testErrorStatusAfterShortRetryWaitsAtLeastOneSecond() throws {
        let reconnects = try observeReconnects([.stream(status: 200, chunks: ["retry: 10\n\n"]),
                                         .stream(status: 503, chunks: [])])
        XCTAssertEqual(reconnects[1].scheduled, 1000)
        XCTAssertGreaterThanOrEqual(reconnects[1].measured, 1.0)
        XCTAssertEqual(source?.retryTime, 10)
    }

    func testServerRetryAppliesAgainAfterFailedConnection() throws {
        let reconnects = try observeReconnects([.connectionLost(afterChunks: ["retry: 10\n\n"]),
                                         .stream(status: 200, chunks: ["data: x\n\n"])])
        XCTAssertEqual(reconnects[0].scheduled, 1000)
        XCTAssertGreaterThanOrEqual(reconnects[0].measured, 1.0)
        XCTAssertEqual(reconnects[1].scheduled, 10)
        XCTAssertGreaterThanOrEqual(reconnects[1].measured, 0.01)
        XCTAssertEqual(source?.retryTime, 10)
    }

    func testFailedConnectionAfterLongRetryWaitsServerRetry() {
        let ended = expectation(description: "first connection ended")
        ended.assertForOverFulfill = false
        SSEStubProtocol.serve(replies: [.connectionLost(afterChunks: ["retry: 1500\n\n"])])
        let source = StubbedEventSource(url: "https://horizon.example.com/ledgers?cursor=now")
        self.source = source
        source.onComplete = { ended.fulfill() }
        wait(for: [ended], timeout: 5)
        source.close()
        XCTAssertEqual(source.lastScheduledReconnectDelay, 1500)
        XCTAssertEqual(source.retryTime, 1500)
    }

    /// Serves `replies` to consecutive connections and closes the source once the request after
    /// the last reply has started. Returns, per reply, the reconnect delay in milliseconds that
    /// the source scheduled after that connection and the measured time in seconds from the end
    /// of the connection to the start of the next request.
    private func observeReconnects(_ replies: [SSEReply]) throws -> [(scheduled: Int?, measured: TimeInterval)] {
        let measured = replies.count + 1
        let measuredRequest = expectation(description: "request \(measured)")
        SSEStubProtocol.serve(replies: replies) { count in
            if count == measured { measuredRequest.fulfill() }
        }
        let source = StubbedEventSource(url: "https://horizon.example.com/ledgers?cursor=now")
        self.source = source
        wait(for: [measuredRequest], timeout: 5)
        source.close()
        let requests = SSEStubProtocol.recordedRequestUptimes
        let completions = source.recordedCompletionUptimes
        let scheduled = source.recordedScheduledDelays
        guard requests.count > replies.count, completions.count >= replies.count, scheduled.count >= replies.count else {
            throw MissingReconnect(requests: requests.count, endedConnections: completions.count)
        }
        return replies.indices.map {
            (scheduled: scheduled[$0], measured: (Double(requests[$0 + 1]) - Double(completions[$0])) / Double(NSEC_PER_SEC))
        }
    }

    /// Streams `chunks` over one connection and returns, in order, every call of `onMessage` and of
    /// the listeners for `listeners` that the connection caused.
    private func callbacks(from chunks: [String], listeners: [String] = []) -> [Callback] {
        SSEStubProtocol.serve(chunks)
        let finished = expectation(description: "first connection finished")
        let log = CallbackLog()
        let source = StubbedEventSource(url: "https://horizon.example.com/ledgers?cursor=now")
        self.source = source
        source.onComplete = { finished.fulfill() }
        source.onMessage { id, event, data in log.append(Callback("onMessage", id, event, data)) }
        for name in listeners {
            source.addEventListener(name) { id, event, data in log.append(Callback(name, id, event, data)) }
        }
        wait(for: [finished], timeout: 5)
        // The callbacks were queued on the main queue before the connection finished.
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 5)
        return log.items
    }
}

private struct MissingReconnect: Error {
    let requests: Int
    let endedConnections: Int
}

private struct Callback: Equatable {
    let handler: String
    let id: String?
    let event: String?
    let data: String?

    init(_ handler: String, _ id: String?, _ event: String?, _ data: String?) {
        (self.handler, self.id, self.event, self.data) = (handler, id, event, data)
    }
}

private final class CallbackLog: @unchecked Sendable {
    private let lock = NSLock()
    private var stored = [Callback]()

    func append(_ callback: Callback) {
        lock.lock()
        stored.append(callback)
        lock.unlock()
    }

    var items: [Callback] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}
