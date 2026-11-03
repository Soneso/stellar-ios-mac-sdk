//
//  AssembledTransactionSendStatusUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 11.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests for AssembledTransaction.send() submission-status handling and for
/// the time bounds set on transactions built by AssembledTransaction.
/// All RPC calls are served by ServerMock; no network access.
final class AssembledTransactionSendStatusUnitTests: XCTestCase {

    var mockRpcUrl: String!
    var mockContractId: String!
    var keyPair: KeyPair!
    var options: AssembledTransactionOptions!

    /// Counts getTransaction polls served by the mock, and the mock's stopped loads before the first.
    private final class PollCounter: @unchecked Sendable {
        var count = 0
        var stopsBeforeFirstPoll = 0
    }
    private var pollCounter = PollCounter()

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        mockRpcUrl = "https://soroban-testnet.stellar.org"
        mockContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        keyPair = try! KeyPair.generateRandomKeyPair()
        pollCounter = PollCounter()
        let clientOptions = ClientOptions(
            sourceAccountKeyPair: keyPair,
            contractId: mockContractId,
            network: Network.testnet,
            rpcUrl: mockRpcUrl
        )
        options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(),
            method: "increment"
        )
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
        super.tearDown()
    }

    // MARK: - Mock setup

    /// Serves the whole build-sign-send flow. sendTransaction answers with
    /// [sendResult]; every getTransaction poll counts into pollCounter and answers
    /// SUCCESS, or what [pollResponse] returns for the poll number and the mock.
    @discardableResult
    private func setupSendFlowMock(sendResult: String, pollResponse: ((Int, RequestMock) -> String?)? = nil) -> RequestMock {
        let counter = pollCounter
        let mock = RequestMock(
            host: "soroban-testnet.stellar.org",
            path: "*",
            httpMethod: "POST"
        ) { mock, request in
            // URLProtocol puts the POST body into httpBodyStream, not httpBody.
            var body = request.httpBody
            if body == nil, let stream = request.httpBodyStream {
                body = stream.readfully()
            }
            guard let bodyData = body,
                  let bodyString = String(data: bodyData, encoding: .utf8) else {
                return nil
            }
            mock.statusCode = 200
            mock.stalls = false
            mock.bodyParts = nil
            if bodyString.contains("simulateTransaction") {
                return """
                {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "result": {
                        "transactionData": "\(self.writeFootprintTransactionDataXdr())",
                        "minResourceFee": "10000",
                        "results": [{
                            "auth": [],
                            "xdr": "\(SCValXDR.void.xdrEncoded!)"
                        }],
                        "latestLedger": 12345
                    }
                }
                """
            }
            if bodyString.contains("sendTransaction") {
                return sendResult
            }
            if bodyString.contains("getTransaction") {
                counter.count += 1
                if counter.count == 1 {
                    counter.stopsBeforeFirstPoll = mock.counts.stops
                }
                if let pollResponse = pollResponse {
                    return pollResponse(counter.count, mock)
                }
                return """
                {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "result": {
                        "status": "SUCCESS",
                        "latestLedger": 12345,
                        "latestLedgerCloseTime": "1234567890",
                        "oldestLedger": 100,
                        "resultXdr": "AAAAAwAAAAE="
                    }
                }
                """
            }
            if bodyString.contains("getLedgerEntries") {
                return self.accountLedgerEntriesJson()
            }
            return nil
        }
        ServerMock.add(mock: mock)
        return mock
    }

    private func accountLedgerEntriesJson() -> String {
        let publicKey = keyPair.publicKey
        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 100_000_000_0,
            sequenceNumber: 12345,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "",
            thresholds: WrappedData4(Data([1, 0, 0, 0])),
            signers: [],
            ext: .void
        )
        let entryData = LedgerEntryDataXDR.account(accountEntry)
        let accountKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: publicKey))
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "entries": [
                    {
                        "key": "\(accountKey.xdrEncoded!)",
                        "xdr": "\(entryData.xdrEncoded!)",
                        "lastModifiedLedgerSeq": 999000
                    }
                ],
                "latestLedger": 1000000
            }
        }
        """
    }

    private func writeFootprintTransactionDataXdr() -> String {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(
                    readOnly: [],
                    readWrite: [LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
                        contract: try! SCAddressXDR(contractId: mockContractId),
                        key: SCValXDR.u32(1),
                        durability: .persistent
                    ))]),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )
        return transactionData.xdrEncoded!
    }

    private func sendTransactionResult(status: String, errorResultXdr: String? = nil, diagnosticEventsXdr: [String]? = nil) -> String {
        var extra = ""
        if let errorResultXdr = errorResultXdr {
            extra += """
            ,
            "errorResultXdr": "\(errorResultXdr)"
            """
        }
        if let diagnosticEventsXdr = diagnosticEventsXdr {
            let joined = diagnosticEventsXdr.map { "\"\($0)\"" }.joined(separator: ", ")
            extra += """
            ,
            "diagnosticEventsXdr": [\(joined)]
            """
        }
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "\(status)",
                "hash": "a1b2c3d4e5f6",
                "latestLedger": 12345,
                "latestLedgerCloseTime": "1234567890"\(extra)
            }
        }
        """
    }

    private func buildSignedTransaction() async throws -> AssembledTransaction {
        let tx = try await AssembledTransaction.build(options: options)
        try tx.sign(force: true)
        return tx
    }

    // MARK: - send() submission-status handling

    func testSendPendingPollsToCompletion() async throws {
        setupSendFlowMock(sendResult: sendTransactionResult(status: "PENDING"))

        let tx = try await buildSignedTransaction()
        let response = try await tx.send()

        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertGreaterThan(pollCounter.count, 0)
    }

    func testSendDuplicatePollsToCompletion() async throws {
        setupSendFlowMock(sendResult: sendTransactionResult(status: "DUPLICATE"))

        let tx = try await buildSignedTransaction()
        let response = try await tx.send()

        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertGreaterThan(pollCounter.count, 0)
    }

    func testSendTryAgainLaterThrowsWithoutPolling() async throws {
        setupSendFlowMock(sendResult: sendTransactionResult(status: "TRY_AGAIN_LATER"))

        let tx = try await buildSignedTransaction()

        do {
            _ = try await tx.send()
            XCTFail("Expected sendFailed error")
        } catch AssembledTransactionError.sendFailed(let message) {
            XCTAssertTrue(message.contains("Send transaction failed with status: TRY_AGAIN_LATER"),
                          "unexpected message: \(message)")
        }
        XCTAssertEqual(pollCounter.count, 0)
    }

    func testSendUnknownStatusThrowsWithoutPolling() async throws {
        setupSendFlowMock(sendResult: sendTransactionResult(status: "SOMETHING_UNEXPECTED"))

        let tx = try await buildSignedTransaction()

        do {
            _ = try await tx.send()
            XCTFail("Expected sendFailed error")
        } catch AssembledTransactionError.sendFailed(let message) {
            XCTAssertTrue(message.contains("Send transaction failed with status: SOMETHING_UNEXPECTED"),
                          "unexpected message: \(message)")
        }
        XCTAssertEqual(pollCounter.count, 0)
    }

    func testSendErrorThrowsWithErrorXdrAndDiagnosticEvents() async throws {
        // A TransactionResult with code txBAD_SEQ.
        let errorResultXdr = "AAAAAAAAAGT////7AAAAAA=="
        let eventBody = ContractEventBodyXDR.v0(
            ContractEventBodyV0XDR(topics: [], data: SCValXDR.u32(7)))
        let diagnosticEvent = DiagnosticEventXDR(
            inSuccessfulContractCall: true,
            event: ContractEventXDR(ext: ExtensionPoint.void,
                                    type: ContractEventType.contract.rawValue,
                                    body: eventBody))
        let diagnosticEventXdr = diagnosticEvent.xdrEncoded!
        setupSendFlowMock(sendResult: sendTransactionResult(
            status: "ERROR",
            errorResultXdr: errorResultXdr,
            diagnosticEventsXdr: [diagnosticEventXdr]))

        let tx = try await buildSignedTransaction()

        do {
            _ = try await tx.send()
            XCTFail("Expected sendFailed error")
        } catch AssembledTransactionError.sendFailed(let message) {
            XCTAssertTrue(message.contains("Send transaction failed with status: ERROR"),
                          "unexpected message: \(message)")
            XCTAssertTrue(message.contains(errorResultXdr), "unexpected message: \(message)")
            XCTAssertTrue(message.contains(diagnosticEventXdr), "unexpected message: \(message)")
        }
        XCTAssertEqual(pollCounter.count, 0)
    }

    // MARK: - status poll deadline

    private func statusResult(_ status: String) -> String {
        return """
        {"jsonrpc": "2.0", "id": 1, "result": {"status": "\(status)", "ledger": 123, "latestLedger": 12345, "latestLedgerCloseTime": "1234567890", "oldestLedger": 100}}
        """
    }

    private func rpcErrorResult(code: Int, message: String) -> String {
        return "{\"jsonrpc\": \"2.0\", \"id\": 1, \"error\": {\"code\": \(code), \"message\": \"\(message)\"}}"
    }

    private func pollingTransaction(timeout: UInt64, pollResponse: @escaping (Int, RequestMock) -> String?) async throws -> (AssembledTransaction, RequestMock) {
        options = AssembledTransactionOptions(clientOptions: options.clientOptions,
                                              methodOptions: MethodOptions(timeoutInSeconds: timeout),
                                              method: "increment")
        let mock = setupSendFlowMock(sendResult: sendTransactionResult(status: "PENDING"), pollResponse: pollResponse)
        return (try await buildSignedTransaction(), mock)
    }

    /// Sends `tx`, expects `pollInterrupted` with the message for `timeout` and `lastError`,
    /// and returns the seconds `send()` took.
    private func sendExpectingInterrupt(_ tx: AssembledTransaction, timeout: UInt64, lastError: String?,
                                        file: StaticString = #filePath, line: UInt = #line) async -> TimeInterval {
        let started = Date()
        do {
            let response = try await tx.send()
            XCTFail("expected pollInterrupted, got status \(response.status)", file: file, line: line)
        } catch AssembledTransactionError.pollInterrupted(let message) {
            let expected = "Interrupted after waiting \(timeout) seconds (options->timeoutInSeconds) for the transaction a1b2c3d4e5f6 to complete."
                + (lastError.map { " Last status request error: \($0)" } ?? "")
            XCTAssertEqual(message, expected, file: file, line: line)
        } catch {
            XCTFail("expected pollInterrupted, got \(error)", file: file, line: line)
        }
        return Date().timeIntervalSince(started)
    }

    /// The loads of `mock` stopped since the first poll, read once `expected` is reached or after a
    /// second; URLSession stops a cancelled load shortly after the request returns.
    private func stopsSinceFirstPoll(_ mock: RequestMock, expected: Int) async -> Int {
        let deadline = Date().addingTimeInterval(1)
        while mock.counts.stops - pollCounter.stopsBeforeFirstPoll < expected && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return mock.counts.stops - pollCounter.stopsBeforeFirstPoll
    }

    func testPollRetriesTransportFailureAndReturnsSuccess() async throws {
        // The first poll at 3 s has 3 s left, so it stays a round request under a late wake-up.
        let (tx, _) = try await pollingTransaction(timeout: 6) { poll, mock in
            if poll == 1 {
                mock.statusCode = 503
                return "temporary status failure"
            }
            return self.statusResult("SUCCESS")
        }
        let response = try await tx.send()
        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertEqual(response.ledger, 123)
        XCTAssertEqual(pollCounter.count, 2)
    }

    func testPollRetriesErrorResponseAndReturnsSuccess() async throws {
        let (tx, _) = try await pollingTransaction(timeout: 6) { poll, _ in
            return poll == 1 ? self.rpcErrorResult(code: -32001, message: "status error") : self.statusResult("SUCCESS")
        }
        let response = try await tx.send()
        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertEqual(pollCounter.count, 2)
    }

    func testPollNotFoundUntilDeadlineNamesLastError() async throws {
        let (tx, _) = try await pollingTransaction(timeout: 6) { poll, _ in
            return poll == 1 ? self.rpcErrorResult(code: -32001, message: "status error 1") : self.statusResult("NOT_FOUND")
        }
        // Polls at 3 s, bounded by the 3 s left, and at the 6 s deadline.
        let elapsed = await sendExpectingInterrupt(tx, timeout: 6, lastError: "RPC error code: -32001, message: status error 1")
        XCTAssertEqual(pollCounter.count, 2)
        XCTAssertGreaterThanOrEqual(elapsed, 6)
        XCTAssertLessThan(elapsed, 8.5)
    }

    func testPollZeroTimeoutMakesOneImmediateRequest() async throws {
        let (tx, _) = try await pollingTransaction(timeout: 0) { _, _ in self.statusResult("NOT_FOUND") }
        let elapsed = await sendExpectingInterrupt(tx, timeout: 0, lastError: nil)
        XCTAssertEqual(pollCounter.count, 1)
        XCTAssertLessThan(elapsed, 2)
    }

    func testPollCancelledCallerDuringFinalRequestGetsCancellationError() async throws {
        let finalRequestStalls = XCTestExpectation(description: "the final status request arrived and stalls")
        let (tx, mock) = try await pollingTransaction(timeout: 1) { _, mock in
            mock.stalls = true
            finalRequestStalls.fulfill()
            return nil
        }
        let send = Task { try await tx.send() }
        // The only request is the final one: it starts at the 1 s deadline, stalls, and its bound ends it 3 s later.
        // The expectation orders the mock's counter write before the read below.
        await fulfillment(of: [finalRequestStalls], timeout: 10)
        XCTAssertEqual(pollCounter.count, 1)
        let cancelled = Date()
        send.cancel()
        let result = await send.result
        let latency = Date().timeIntervalSince(cancelled)
        guard case .failure(let error) = result else {
            return XCTFail("expected CancellationError, got a response")
        }
        XCTAssertTrue(error is CancellationError, "expected CancellationError, got \(error)")
        let stops = await stopsSinceFirstPoll(mock, expected: 1)
        XCTAssertEqual(stops, 1)
        XCTAssertLessThan(latency, 2)
    }

    func testPollReturnsFailed() async throws {
        let (tx, _) = try await pollingTransaction(timeout: 1) { _, _ in self.statusResult("FAILED") }
        let response = try await tx.send()
        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_FAILED)
        XCTAssertEqual(response.ledger, 123)
        XCTAssertEqual(pollCounter.count, 1)
    }

    func testPollUnderALargeTimeoutReturnsSuccess() async throws {
        let (tx, _) = try await pollingTransaction(timeout: UInt64.max / 2) { _, _ in self.statusResult("SUCCESS") }
        let response = try await tx.send()
        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertEqual(pollCounter.count, 1)
    }

    func testPollCancelsStalledStatusRequestsAtTheirBounds() async throws {
        let (tx, mock) = try await pollingTransaction(timeout: 4) { _, mock in
            mock.stalls = true
            return nil
        }
        // The round request is bounded by the one second left, the last request by the wait time.
        let elapsed = await sendExpectingInterrupt(tx, timeout: 4, lastError: "no response within 3.000 seconds")
        XCTAssertEqual(pollCounter.count, 2)
        let stops = await stopsSinceFirstPoll(mock, expected: 2)
        XCTAssertEqual(stops, 2)
        XCTAssertGreaterThanOrEqual(elapsed, 7)
        XCTAssertLessThan(elapsed, 9.5)
    }

    func testPollCancelsTricklingStatusResponseAtTheBound() async throws {
        let body = Data(statusResult("NOT_FOUND").utf8)
        let size = body.count / 20
        let parts = stride(from: 0, to: body.count, by: size).map { body.subdata(in: $0..<min($0 + size, body.count)) }
        let (tx, mock) = try await pollingTransaction(timeout: 1) { _, mock in
            mock.bodyParts = parts
            mock.partDelay = 0.5
            return nil
        }
        let elapsed = await sendExpectingInterrupt(tx, timeout: 1, lastError: "no response within 3.000 seconds")
        XCTAssertEqual(pollCounter.count, 1)
        let stops = await stopsSinceFirstPoll(mock, expected: 1)
        XCTAssertEqual(stops, 1)
        XCTAssertLessThan(mock.counts.sentParts, parts.count)
        XCTAssertGreaterThanOrEqual(elapsed, 4)
        XCTAssertLessThan(elapsed, 7)
    }

    func testPollCountsSlowNotFoundAsOnePoll() async throws {
        let (tx, _) = try await pollingTransaction(timeout: 6) { _, mock in
            mock.bodyParts = [Data(self.statusResult("NOT_FOUND").utf8)]
            mock.partDelay = 0.5
            return nil
        }
        // Polls at 3 s and at the 6 s deadline, each answered after half a second.
        let elapsed = await sendExpectingInterrupt(tx, timeout: 6, lastError: nil)
        XCTAssertEqual(pollCounter.count, 2)
        XCTAssertGreaterThanOrEqual(elapsed, 6.5)
        XCTAssertLessThan(elapsed, 8.5)
    }

    // MARK: - transaction time bounds

    func testBuiltTransactionSetsNoLowerTimeBound() async throws {
        setupSendFlowMock(sendResult: sendTransactionResult(status: "PENDING"))

        let tx = try await AssembledTransaction.build(options: options)

        guard let transaction = tx.tx else {
            XCTFail("Transaction was not assembled")
            return
        }
        guard let timeBounds = transaction.preconditions?.timeBounds else {
            XCTFail("Transaction carries no time bounds")
            return
        }
        XCTAssertEqual(timeBounds.minTime, 0)
        XCTAssertGreaterThan(timeBounds.maxTime, UInt64(Date().timeIntervalSince1970) - 60)
    }
}
