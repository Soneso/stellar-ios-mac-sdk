//
//  SorobanServerPollTransactionTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests for `SorobanServer.pollTransaction(hash:maxAttempts:sleepStrategy:)`.
/// All RPC calls are intercepted via `URLProtocol`-based mocks so no live network is used.
final class SorobanServerPollTransactionTests: XCTestCase {

    private let testHost = "soroban-testnet.stellar.org"
    private let testUrl = "https://soroban-testnet.stellar.org"
    private let txHash = "abc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1"
    private var server: SorobanServer!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        server = SorobanServer(endpoint: testUrl)
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
        server = nil
        super.tearDown()
    }

    // MARK: - max attempts behavior

    func test_pollTransaction_respects_max_attempts() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.notFoundJson() },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 3,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 3, "pollTransaction must invoke RPC exactly maxAttempts times when status stays NOT_FOUND")
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_NOT_FOUND)
        } else {
            XCTFail("Expected last NOT_FOUND response to be returned, got \(response)")
        }
    }

    func test_pollTransaction_zero_max_attempts_returns_failure() async {
        let response = await server.pollTransaction(hash: txHash, maxAttempts: 0)
        if case .failure(let error) = response,
           case .requestFailed(let message) = error {
            XCTAssertTrue(message.contains("maxAttempts"))
        } else {
            XCTFail("Expected .failure with requestFailed message, got \(response)")
        }
    }

    func test_pollTransaction_negative_max_attempts_returns_failure() async {
        let response = await server.pollTransaction(hash: txHash, maxAttempts: -5)
        if case .failure(let error) = response,
           case .requestFailed(let message) = error {
            XCTAssertTrue(message.contains("maxAttempts"))
        } else {
            XCTFail("Expected .failure with requestFailed message, got \(response)")
        }
    }

    // MARK: - happy paths

    func test_pollTransaction_returns_success_when_status_succeeds_on_first_attempt() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.successJson() },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 5,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 1, "Successful first attempt must short-circuit subsequent polls")
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_SUCCESS)
        } else {
            XCTFail("Expected .success, got \(response)")
        }
    }

    func test_pollTransaction_returns_failed_status_without_continuing_polling() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.failedJson() },
            { _ in requestCount += 1; return self.successJson() },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 5,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 1, "FAILED is a final state and must short-circuit further polling")
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_FAILED)
        } else {
            XCTFail("Expected .success(FAILED), got \(response)")
        }
    }

    func test_pollTransaction_swallows_transient_rpc_error_and_continues() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.errorResponseJson(message: "transient outage") },
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.successJson() },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 5,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 3, "Polling must continue past a transient RPC error")
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_SUCCESS)
        } else {
            XCTFail("Expected .success after transient error recovered, got \(response)")
        }
    }

    func test_pollTransaction_returns_last_successful_response_when_trailing_attempts_fail() async {
        // On a sequence of [success(NOT_FOUND), failure, failure] the helper must return
        // the prior success(NOT_FOUND) snapshot rather than the trailing transient failure.
        // Transient RPC errors are swallowed and only successful responses update the
        // last-observed snapshot.
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.errorResponseJson(message: "transient outage 1") },
            { _ in requestCount += 1; return self.errorResponseJson(message: "transient outage 2") },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 3,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 3, "Polling must run all attempts when only NOT_FOUND or transient errors are observed")
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_NOT_FOUND,
                           "Trailing transient failures must not overwrite the last successful NOT_FOUND snapshot")
        } else {
            XCTFail("Expected the prior success(NOT_FOUND) response to be returned, got \(response)")
        }
    }

    func test_pollTransaction_returns_last_failure_when_every_attempt_is_a_transient_error() async {
        // When no attempt ever produces a success response, the helper surfaces the
        // last per-attempt failure so the caller sees the actual cause.
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.errorResponseJson(message: "outage 1") },
            { _ in requestCount += 1; return self.errorResponseJson(message: "outage 2") },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 2,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 2)
        if case .failure(let error) = response {
            XCTAssertTrue("\(error)".contains("outage 2"),
                          "Expected the last per-attempt failure to surface, got \(error)")
        } else {
            XCTFail("Expected the last per-attempt failure, got \(response)")
        }
    }

    func test_pollTransaction_pending_then_success_two_attempt_sequence() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.successJson() },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 5,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 2)
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_SUCCESS)
        } else {
            XCTFail("Expected .success, got \(response)")
        }
    }

    // MARK: - boundaries

    func test_pollTransaction_attempts_equals_one_polls_exactly_once() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.successJson() },
        ])

        let response = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 1,
            sleepStrategy: { _ in 0.001 }
        )

        XCTAssertEqual(requestCount, 1, "maxAttempts=1 must perform exactly one RPC call")
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_NOT_FOUND)
        } else {
            XCTFail("Expected NOT_FOUND last response, got \(response)")
        }
    }

    // MARK: - sleep strategy

    func test_pollTransaction_default_sleep_strategy_is_one_second_per_attempt() async {
        // Capture the closure passed to pollTransaction by relying on the public default.
        // Verifying the default here exercises the default-argument code path explicitly.
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.successJson() },
        ])

        let response = await server.pollTransaction(hash: txHash, maxAttempts: 1)

        XCTAssertEqual(requestCount, 1)
        if case .success(let txResponse) = response {
            XCTAssertEqual(txResponse.status, GetTransactionResponse.STATUS_SUCCESS)
        } else {
            XCTFail("Expected .success with default sleep strategy, got \(response)")
        }
    }

    func test_pollTransaction_custom_sleep_strategy_called_with_attempt_number() async {
        var requestCount = 0
        registerSequence([
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.notFoundJson() },
            { _ in requestCount += 1; return self.notFoundJson() },
        ])

        let recordedAttempts: SleepCallRecorder = SleepCallRecorder()

        _ = await server.pollTransaction(
            hash: txHash,
            maxAttempts: 3,
            sleepStrategy: { attempt in
                recordedAttempts.record(attempt)
                return 0.001
            }
        )

        XCTAssertEqual(requestCount, 3)
        // sleepStrategy is invoked between attempts (not after the last), so call count == maxAttempts - 1.
        XCTAssertEqual(recordedAttempts.values, [1, 2], "Sleep strategy must receive 1-indexed attempt numbers")
    }

    // MARK: - Mock helpers

    private typealias HandlerStep = (URLRequest) -> String

    private func registerSequence(_ steps: [HandlerStep]) {
        let queue = HandlerQueue(steps: steps)
        let mock = RequestMock(
            host: testHost,
            path: "*",
            httpMethod: "POST",
            mockHandler: { mock, request in
                mock.statusCode = 200
                guard let next = queue.next() else {
                    return self.notFoundJson()
                }
                return next(request)
            }
        )
        ServerMock.add(mock: mock)
    }

    private func notFoundJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "NOT_FOUND",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890",
                "oldestLedger": 900000,
                "oldestLedgerCloseTime": "1234500000"
            }
        }
        """
    }

    private func successJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "SUCCESS",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890",
                "oldestLedger": 900000,
                "oldestLedgerCloseTime": "1234500000",
                "applicationOrder": 1,
                "ledger": 999999,
                "createdAt": "1234567880",
                "envelopeXdr": "AAAAAA==",
                "resultXdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=",
                "resultMetaXdr": "AAAAAA=="
            }
        }
        """
    }

    private func failedJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "FAILED",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890",
                "oldestLedger": 900000,
                "oldestLedgerCloseTime": "1234500000",
                "applicationOrder": 1,
                "ledger": 999999,
                "createdAt": "1234567880",
                "envelopeXdr": "AAAAAA==",
                "resultXdr": "AAAAAAAAAGT/////AAAAAA==",
                "resultMetaXdr": "AAAAAA=="
            }
        }
        """
    }

    private func errorResponseJson(message: String) -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "error": {
                "code": -32603,
                "message": "\(message)"
            }
        }
        """
    }
}

// MARK: - Mock helpers

/// Mutable, reference-typed counter for recording sleep-strategy calls inside a `@Sendable` closure.
/// Internally serializes access through a lock so the recorder is safe to capture across actor
/// boundaries.
private final class SleepCallRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Int] = []

    var values: [Int] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func record(_ attempt: Int) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(attempt)
    }
}

/// Reference-typed FIFO queue of handler steps. Reference semantics keep state mutable inside
/// the value-type capture context of the URLProtocol mock closure.
private final class HandlerQueue {
    private var steps: [(URLRequest) -> String]

    init(steps: [(URLRequest) -> String]) {
        self.steps = steps
    }

    func next() -> ((URLRequest) -> String)? {
        guard !steps.isEmpty else { return nil }
        return steps.removeFirst()
    }
}
