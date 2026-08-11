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

    /// Counts getTransaction polls served by the mock.
    private final class PollCounter: @unchecked Sendable {
        var count = 0
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
    /// [sendResult]; every getTransaction poll answers SUCCESS and counts
    /// into pollCounter.
    private func setupSendFlowMock(sendResult: String) {
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
