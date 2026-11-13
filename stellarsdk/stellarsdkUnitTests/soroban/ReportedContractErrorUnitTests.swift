//
//  ReportedContractErrorUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The contract error a failed simulation reports: selection from the response
/// (`SimulateTransactionResponse.reportedContractError()`), the message
/// `AssembledTransaction` throws, and `AssembledTransactionError.reportedContractError`.
final class ReportedContractErrorUnitTests: XCTestCase {

    private typealias Fixtures = SimulationFailureFixtures
    private typealias Synthetic = SyntheticDiagnosticEvent

    private let invokedContract = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let simulatePrefix = "Simulation failed with error: "
    private let simulationDataPrefix = "Transaction simulation failed. Error: "
    private let maskedContext = "HostError: Error(Context, InvalidAction)"
    private let maskedAuth = "HostError: Error(Auth, InvalidAction)"

    private var keyPair: KeyPair!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        keyPair = try! KeyPair.generateRandomKeyPair()
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
        super.tearDown()
    }

    // MARK: - Helpers

    private func suffix(_ code: UInt32, _ contractId: String?) -> String {
        guard let contractId = contractId else {
            return " (contract error in diagnostic events: Error(Contract, #\(code)))"
        }
        return " (contract error in diagnostic events: Error(Contract, #\(code)), contract \(contractId))"
    }

    private func fromEvents(_ code: UInt32, _ contractId: String?) -> ReportedContractError {
        return ReportedContractError(code: code, provenance: .diagnosticEvents, contractId: contractId)
    }

    private func fromHeader(_ code: UInt32) -> ReportedContractError {
        return ReportedContractError(code: code, provenance: .hostError, contractId: nil)
    }

    private func options(simulate: Bool = true) -> AssembledTransactionOptions {
        return AssembledTransactionOptions(
            clientOptions: ClientOptions(sourceAccountKeyPair: keyPair,
                                         contractId: invokedContract,
                                         network: Network.testnet,
                                         rpcUrl: SimulationRpcRouter.rpcUrl),
            methodOptions: MethodOptions(simulate: simulate),
            method: "test")
    }

    /// Runs the public `AssembledTransaction.build` against `body` and returns the thrown
    /// `.simulationFailed` error with its message.
    private func buildFailure(body: String,
                              file: StaticString = #filePath,
                              line: UInt = #line) async throws -> (AssembledTransactionError, String) {
        ServerMock.removeAll()
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [body])
        do {
            _ = try await AssembledTransaction.build(options: options())
        } catch let error as AssembledTransactionError {
            guard case .simulationFailed(let message) = error else {
                XCTFail("expected simulationFailed, got \(error)", file: file, line: line)
                throw error
            }
            XCTAssertEqual(router.sentTransactionRequests.count, 0, "no submission after a failed simulation",
                           file: file, line: line)
            return (error, message)
        }
        XCTFail("expected AssembledTransaction.build to throw", file: file, line: line)
        throw AssembledTransactionError.notYetSimulated(message: "no failure")
    }

    private func buildFailure(error: String, events: [String]?,
                              file: StaticString = #filePath,
                              line: UInt = #line) async throws -> (AssembledTransactionError, String) {
        let body = try Fixtures.rpcBody(result: Fixtures.failureResult(error: error, events: events))
        return try await buildFailure(body: body, file: file, line: line)
    }

    private func reported(error: String, events: [String]?) throws -> ReportedContractError? {
        return try Fixtures.decodeResponse(result: Fixtures.failureResult(error: error, events: events))
            .reportedContractError()
    }

    /// Asserts the selection on the decoded response and through `build`: the message, and the
    /// property on the thrown error.
    private func assertSelection(error: String,
                                 events: [String]?,
                                 expected: ReportedContractError?,
                                 expectedMessage: String,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async throws {
        XCTAssertEqual(try reported(error: error, events: events), expected, "response extraction",
                       file: file, line: line)
        let (thrown, message) = try await buildFailure(error: error, events: events, file: file, line: line)
        XCTAssertEqual(message, expectedMessage, file: file, line: line)
        XCTAssertEqual(thrown.reportedContractError, expected, "property on the thrown error",
                       file: file, line: line)
    }

    // MARK: - Real captures

    func testConstructorCaptureReportsThePolicyErrorFromTheEvents() async throws {
        let text = try Fixtures.errorText(Fixtures.caseA)
        XCTAssertEqual(text, maskedContext)
        let expected = fromEvents(3201, Fixtures.thresholdPolicy)
        XCTAssertEqual(try Fixtures.response(Fixtures.caseA).reportedContractError(), expected)

        let (thrown, message) = try await buildFailure(body: try Fixtures.body(Fixtures.caseA))
        XCTAssertEqual(message, simulatePrefix + maskedContext + suffix(3201, Fixtures.thresholdPolicy))
        XCTAssertEqual(thrown.reportedContractError, expected)
        XCTAssertEqual(OZContractErrorCodes.decode(Int(expected.code))?.name, "InvalidThreshold")
    }

    func testCheckAuthCapturesReportTheVerifierAndAccountErrors() async throws {
        XCTAssertEqual(try Fixtures.response(Fixtures.caseB1).reportedContractError(),
                       fromEvents(3114, Fixtures.webAuthnVerifier))
        XCTAssertEqual(try Fixtures.response(Fixtures.caseB2).reportedContractError(),
                       fromEvents(3016, Fixtures.smartAccount))

        let (thrown, message) = try await buildFailure(body: try Fixtures.body(Fixtures.caseB2))
        XCTAssertEqual(message, simulatePrefix + maskedAuth + suffix(3016, Fixtures.smartAccount))
        XCTAssertEqual(thrown.reportedContractError, fromEvents(3016, Fixtures.smartAccount))
    }

    func testCheckAuthCaptureWithOnlyACryptoErrorReportsNothing() async throws {
        XCTAssertNil(try Fixtures.response(Fixtures.caseB3).reportedContractError())
        let (thrown, message) = try await buildFailure(body: try Fixtures.body(Fixtures.caseB3))
        XCTAssertEqual(message, simulatePrefix + maskedAuth)
        XCTAssertNil(thrown.reportedContractError)
    }

    func testHeaderCapturesReportTheHeaderCode() async throws {
        XCTAssertEqual(try Fixtures.response(Fixtures.caseC1).reportedContractError(), fromHeader(3200))
        XCTAssertEqual(try Fixtures.response(Fixtures.caseC2).reportedContractError(), fromHeader(8))
        let (thrown, message) = try await buildFailure(body: try Fixtures.body(Fixtures.caseC2))
        XCTAssertEqual(message, simulatePrefix + "HostError: Error(Contract, #8)")
        XCTAssertEqual(thrown.reportedContractError, fromHeader(8))
    }

    /// A stellar-rpc 30.0.0 text carries the header and a newest-first event log.
    func testMultilineTextReadsOnlyTheHeaderAndTheEventArray() async throws {
        let text = try Fixtures.errorText(Fixtures.caseA30)
        XCTAssertTrue(text.hasPrefix(maskedContext + "\n"))
        XCTAssertTrue(text.contains("Error(Contract, #3201)"))
        XCTAssertTrue(text.hasSuffix("]\n"))

        let (thrown, message) = try await buildFailure(body: try Fixtures.body(Fixtures.caseA30))
        XCTAssertEqual(message, simulatePrefix + text + suffix(3201, Fixtures.thresholdPolicy))
        XCTAssertEqual(thrown.reportedContractError, fromEvents(3201, Fixtures.thresholdPolicy))

        // Without the event array the code that only the text log names is not reported.
        try await assertSelection(error: text, events: nil, expected: nil,
                                  expectedMessage: simulatePrefix + text)
    }

    // MARK: - Header

    /// A contract error in the header wins over error events.
    func testContractHeaderWinsOverErrorEvents() async throws {
        let events = [try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)]
        try await assertSelection(error: "HostError: Error(Contract, #8)", events: events,
                                  expected: fromHeader(8),
                                  expectedMessage: simulatePrefix + "HostError: Error(Contract, #8)")
        let padded = "  HostError:  Error( Contract ,  #8 )  "
        try await assertSelection(error: padded, events: events, expected: fromHeader(8),
                                  expectedMessage: simulatePrefix + padded)
        try await assertSelection(error: "Error(Contract, #8)", events: events, expected: fromHeader(8),
                                  expectedMessage: simulatePrefix + "Error(Contract, #8)")
    }

    func testMaskedHeaderWithoutHostErrorPrefixReadsTheEvents() async throws {
        let events = [try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)]
        try await assertSelection(error: "Error(Auth, InvalidAction)", events: events,
                                  expected: fromEvents(3016, Fixtures.smartAccount),
                                  expectedMessage: simulatePrefix + "Error(Auth, InvalidAction)"
                                    + suffix(3016, Fixtures.smartAccount))
    }

    /// No events, or a header that masks nothing.
    func testNoEventsOrUnmaskedHeadersReportNothing() async throws {
        try await assertSelection(error: maskedContext, events: nil, expected: nil,
                                  expectedMessage: simulatePrefix + maskedContext)
        try await assertSelection(error: maskedAuth, events: [], expected: nil,
                                  expectedMessage: simulatePrefix + maskedAuth)
        let events = [try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)]
        for header in ["HostError: Error(Storage, MissingValue)",
                       "HostError: Error(Budget, ExceededLimit)",
                       "HostError: Error(WasmVm, InvalidAction)",
                       "Simulation failed: invalid contract"] {
            try await assertSelection(error: header, events: events, expected: nil,
                                      expectedMessage: simulatePrefix + header)
        }
    }

    /// A successful simulation reports nothing, also when it carries the error event of a failed
    /// call that its caller caught, an event a failed simulation would report.
    func testSuccessfulSimulationReportsNothing() async throws {
        let caught = try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)
        XCTAssertEqual(try reported(error: maskedAuth, events: [caught]), fromEvents(3016, Fixtures.smartAccount))

        _ = SimulationRpcRouter(sourceAccount: keyPair,
                                simulateBodies: [SimulationRpcRouter.successBody(contractId: invokedContract,
                                                                                 events: [caught])])
        let tx = try await AssembledTransaction.build(options: options())
        let response = try XCTUnwrap(tx.simulationResponse)
        XCTAssertNil(response.error)
        XCTAssertEqual(response.events, [caught])
        XCTAssertNil(response.reportedContractError())
        XCTAssertNoThrow(try tx.getSimulationData())
    }

    /// Header codes at both ends of the u32 range; out-of-range codes fall back to nothing.
    func testHeaderCodeRange() async throws {
        let events = [try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)]
        try await assertSelection(error: "HostError: Error(Contract, #0)", events: events,
                                  expected: fromHeader(0),
                                  expectedMessage: simulatePrefix + "HostError: Error(Contract, #0)")
        try await assertSelection(error: "HostError: Error(Contract, #4294967295)", events: events,
                                  expected: fromHeader(UInt32.max),
                                  expectedMessage: simulatePrefix + "HostError: Error(Contract, #4294967295)")
        for header in ["HostError: Error(Contract, #4294967296)", "HostError: Error(Contract, #-1)"] {
            try await assertSelection(error: header, events: events, expected: nil,
                                      expectedMessage: simulatePrefix + header)
        }
    }

    // MARK: - Events

    /// Each entry the selection must skip, alone and before a qualifying control event.
    func testEntriesThatAreNoFailedCallContractErrorAreSkipped() async throws {
        let control = try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)
        let skipped: [(String, String)] = [
            ("invalid base64", "!!! not base64 !!!"),
            ("invalid XDR", Data([0x00, 0x00, 0x00, 0x01, 0x02]).base64EncodedString()),
            ("contract event", try Synthetic.contractError(5, type: .contract)),
            ("system event", try Synthetic.contractError(5, type: .system)),
            ("one topic", try Synthetic.event(topics: [.symbol("error")], data: .error(.contract(5)))),
            ("three topics", try Synthetic.event(topics: [.symbol("error"), .error(.contract(5)), .u32(1)])),
            ("string topic", try Synthetic.event(topics: [.string("error"), .error(.contract(5))])),
            ("other symbol", try Synthetic.event(topics: [.symbol("log"), .error(.contract(5))])),
            ("u32 instead of an error", try Synthetic.event(topics: [.symbol("error"), .u32(5)])),
            ("non-contract error", try Synthetic.event(topics: [.symbol("error"), .error(.context(.invalidAction))],
                                                       data: .error(.contract(5)))),
            ("code only in data", try Synthetic.event(topics: [.symbol("log")], data: .error(.contract(5)))),
        ]
        for (label, entry) in skipped {
            XCTAssertNil(try reported(error: maskedAuth, events: [entry]), label)
            XCTAssertEqual(try reported(error: maskedAuth, events: [entry, control]),
                           fromEvents(3016, Fixtures.smartAccount), label)
        }
        let (thrown, message) = try await buildFailure(error: maskedAuth, events: skipped.map { $0.1 } + [control])
        XCTAssertEqual(message, simulatePrefix + maskedAuth + suffix(3016, Fixtures.smartAccount))
        XCTAssertEqual(thrown.reportedContractError, fromEvents(3016, Fixtures.smartAccount))
    }

    /// Malformed entries before and between valid entries.
    func testMalformedEntriesDoNotHideLaterEvents() async throws {
        let malformed = ["%%%", Data([0xFF]).base64EncodedString()]
        let first = try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)
        let second = try Synthetic.contractError(3201, contractId: Fixtures.thresholdPolicy)
        try await assertSelection(error: maskedContext, events: malformed + [first] + malformed + [second],
                                  expected: fromEvents(3016, Fixtures.smartAccount),
                                  expectedMessage: simulatePrefix + maskedContext + suffix(3016, Fixtures.smartAccount))
    }

    /// Events of successful calls are skipped; an earlier failed-call error wins.
    func testSuccessfulCallEventsAreSkippedAndTheEarliestFailedCallErrorWins() async throws {
        let caught = try Synthetic.contractError(7, contractId: Fixtures.thresholdPolicy, inSuccessfulContractCall: true)
        let fatal = try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)
        try await assertSelection(error: maskedAuth, events: [caught, fatal],
                                  expected: fromEvents(3016, Fixtures.smartAccount),
                                  expectedMessage: simulatePrefix + maskedAuth + suffix(3016, Fixtures.smartAccount))
        // An error a contract caught is marked failed when its call rolled back; the heuristic
        // then selects it.
        let rolledBack = try Synthetic.contractError(1, contractId: Synthetic.otherContract)
        try await assertSelection(error: maskedAuth, events: [rolledBack, fatal],
                                  expected: fromEvents(1, Synthetic.otherContract),
                                  expectedMessage: simulatePrefix + maskedAuth + suffix(1, Synthetic.otherContract))
    }

    /// An event without a contract ID.
    func testEventWithoutContractIdReportsTheCodeWithoutContract() async throws {
        let anonymous = try Synthetic.contractError(3016, contractId: nil)
        let message = simulatePrefix + maskedAuth + " (contract error in diagnostic events: Error(Contract, #3016))"
        try await assertSelection(error: maskedAuth, events: [anonymous], expected: fromEvents(3016, nil),
                                  expectedMessage: message)
    }

    /// An unknown code is reported as found, also before a known OZ code.
    func testUnknownCodeIsReportedBeforeAKnownCode() async throws {
        let unknown = try Synthetic.contractError(1, contractId: Synthetic.otherContract)
        let known = try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)
        try await assertSelection(error: maskedAuth, events: [unknown, known],
                                  expected: fromEvents(1, Synthetic.otherContract),
                                  expectedMessage: simulatePrefix + maskedAuth + suffix(1, Synthetic.otherContract))
        XCTAssertNil(OZContractErrorCodes.decode(1))
    }

    /// Event codes at both ends of the u32 range.
    func testEventCodeRange() async throws {
        try await assertSelection(error: maskedAuth, events: [try Synthetic.contractError(0)],
                                  expected: fromEvents(0, Synthetic.otherContract),
                                  expectedMessage: simulatePrefix + maskedAuth + suffix(0, Synthetic.otherContract))
        try await assertSelection(error: maskedAuth, events: [try Synthetic.contractError(UInt32.max)],
                                  expected: fromEvents(UInt32.max, Synthetic.otherContract),
                                  expectedMessage: simulatePrefix + maskedAuth
                                    + suffix(4294967295, Synthetic.otherContract))
    }

    /// The earliest event wins with its contract, before an event of the invoked contract
    /// and before a known code; the response keeps every event in order.
    func testEarliestEventWinsAcrossContractsAndTheResponseKeepsEveryEvent() async throws {
        let events = [
            try Synthetic.contractError(9999, contractId: Synthetic.otherContract),
            try Synthetic.contractError(3016, contractId: invokedContract),
            try Synthetic.contractError(3016, contractId: invokedContract),
            try Synthetic.contractError(3201, contractId: Fixtures.thresholdPolicy),
        ]
        try await assertSelection(error: maskedContext, events: events,
                                  expected: fromEvents(9999, Synthetic.otherContract),
                                  expectedMessage: simulatePrefix + maskedContext + suffix(9999, Synthetic.otherContract))

        let body = try Fixtures.rpcBody(result: Fixtures.failureResult(error: maskedContext, events: events))
        _ = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [body])
        let tx = try await AssembledTransaction.build(options: options(simulate: false))
        do {
            try await tx.simulate()
            XCTFail("expected simulationFailed")
        } catch let error as AssembledTransactionError {
            XCTAssertEqual(error.reportedContractError, fromEvents(9999, Synthetic.otherContract))
        }
        XCTAssertEqual(tx.simulationResponse?.events, events)
    }

    // MARK: - Message round trip

    func testWrittenMessagesReadBack() throws {
        let values: [ReportedContractError] = [0, 3201, UInt32.max].flatMap { code in
            [fromHeader(code), fromEvents(code, Fixtures.thresholdPolicy), fromEvents(code, nil)]
        }
        for prefix in [SimulationFailureMessage.simulatePrefix, SimulationFailureMessage.simulationDataPrefix] {
            for value in values {
                let hostError = value.provenance == .hostError
                    ? "HostError: Error(Contract, #\(value.code))"
                    : maskedContext
                let message = SimulationFailureMessage.compose(prefix: prefix, hostError: hostError, reported: value)
                XCTAssertEqual(AssembledTransactionError.simulationFailed(message: message).reportedContractError,
                               value, message)
            }
        }
        XCTAssertEqual(SimulationFailureMessage.suffix(for: nil), "")
        XCTAssertEqual(SimulationFailureMessage.suffix(for: fromHeader(8)), "")
        XCTAssertEqual(SimulationFailureMessage.suffix(for: fromEvents(3201, Fixtures.thresholdPolicy)),
                       " (contract error in diagnostic events: Error(Contract, #3201), contract \(Fixtures.thresholdPolicy))")
        XCTAssertEqual(SimulationFailureMessage.suffix(for: fromEvents(3201, nil)),
                       " (contract error in diagnostic events: Error(Contract, #3201))")
        XCTAssertEqual(SimulationFailureMessage.simulatePrefix, simulatePrefix)
        XCTAssertEqual(SimulationFailureMessage.simulationDataPrefix, simulationDataPrefix)
    }

    /// Every capture reports its recorded selection from the response and at both writers,
    /// in the message and in the property.
    func testEveryCaptureReportsItsSelectionAtBothWriters() async throws {
        let expectations: [(name: String, expected: ReportedContractError?, messageSuffix: String)] = [
            (Fixtures.caseA, fromEvents(3201, Fixtures.thresholdPolicy), suffix(3201, Fixtures.thresholdPolicy)),
            (Fixtures.caseA30, fromEvents(3201, Fixtures.thresholdPolicy), suffix(3201, Fixtures.thresholdPolicy)),
            (Fixtures.caseB1, fromEvents(3114, Fixtures.webAuthnVerifier), suffix(3114, Fixtures.webAuthnVerifier)),
            (Fixtures.caseB130, fromEvents(3114, Fixtures.webAuthnVerifier), suffix(3114, Fixtures.webAuthnVerifier)),
            (Fixtures.caseB2, fromEvents(3016, Fixtures.smartAccount), suffix(3016, Fixtures.smartAccount)),
            (Fixtures.caseB230, fromEvents(3016, Fixtures.smartAccount), suffix(3016, Fixtures.smartAccount)),
            (Fixtures.caseB3, nil, ""),
            (Fixtures.caseB330, nil, ""),
            (Fixtures.caseC1, fromHeader(3200), ""),
            (Fixtures.caseC130, fromHeader(3200), ""),
            (Fixtures.caseC2, fromHeader(8), ""),
            (Fixtures.caseC230, fromHeader(8), ""),
        ]
        XCTAssertEqual(expectations.map { $0.name }, Fixtures.all)
        for (name, expected, expectedSuffix) in expectations {
            let text = try Fixtures.errorText(name)
            let body = try Fixtures.body(name)
            XCTAssertEqual(try Fixtures.response(name).reportedContractError(), expected, "response: \(name)")

            let (built, builtMessage) = try await buildFailure(body: body)
            XCTAssertEqual(builtMessage, simulatePrefix + text + expectedSuffix, "simulate: \(name)")
            XCTAssertEqual(built.reportedContractError, expected, "simulate: \(name)")

            ServerMock.removeAll()
            _ = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [body])
            let tx = try await AssembledTransaction.build(options: options(simulate: false))
            do {
                try await tx.simulate()
                XCTFail("expected simulationFailed: \(name)")
            } catch {}
            do {
                _ = try tx.getSimulationData()
                XCTFail("expected simulationFailed: \(name)")
            } catch let error as AssembledTransactionError {
                if case .simulationFailed(let message) = error {
                    XCTAssertEqual(message, simulationDataPrefix + text + expectedSuffix, "getSimulationData: \(name)")
                } else {
                    XCTFail("expected simulationFailed for \(name), got \(error)")
                }
                XCTAssertEqual(error.reportedContractError, expected, "getSimulationData: \(name)")
            }
            ServerMock.removeAll()
        }
    }

    // MARK: - Message anchoring

    /// In a multiline message only the header and the suffix count, not codes in the log.
    func testMultilineMessageReadsOnlyHeaderAndSuffix() async throws {
        let text = try Fixtures.errorText(Fixtures.caseA30)
        let (thrown, message) = try await buildFailure(
            error: text, events: [try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)])
        XCTAssertEqual(message, simulatePrefix + text + suffix(3016, Fixtures.smartAccount))
        XCTAssertEqual(thrown.reportedContractError, fromEvents(3016, Fixtures.smartAccount))

        let headerText = try Fixtures.errorText(Fixtures.caseC130)
            + "   9: [Diagnostic Event] topics:[error, Error(Contract, #3016)], data:\"other\"\n"
        XCTAssertTrue(headerText.hasPrefix("HostError: Error(Contract, #3200)\n"))
        let (headerError, _) = try await buildFailure(
            error: headerText, events: [try Synthetic.contractError(3016, contractId: Fixtures.smartAccount)])
        XCTAssertEqual(headerError.reportedContractError, fromHeader(3200))
    }

    /// Messages in neither form.
    func testMessagesInNeitherFormReadNothing() {
        let wellFormed = suffix(3201, Fixtures.thresholdPolicy)
        let messages = [
            "",
            "custom",
            "Transaction simulation failed",
            simulatePrefix,
            simulationDataPrefix,
            "simulation failed with error: " + maskedContext + wellFormed,
            " " + simulatePrefix + maskedContext + wellFormed,
            maskedContext + wellFormed,
            wellFormed,
            "Transaction simulation failed: Simulation error: " + maskedContext + wellFormed,
            simulatePrefix + maskedContext + " (contract error in diagnostic events: Error(Contract, #03201), contract \(Fixtures.thresholdPolicy))",
            simulatePrefix + maskedContext + " (contract error in diagnostic events: Error(Contract, #4294967296))",
            simulatePrefix + maskedContext + " (contract error in diagnostic events: Error(Contract, #-1))",
            simulatePrefix + maskedContext + " (contract error in diagnostic events: Error(Contract, #3201), contract CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUD)",
            simulatePrefix + maskedContext + " (contract error in diagnostic events: Error(Contract, #3201), contract GABXCG6JFT2XWKNFOG2CO5GRY2OKQ24HK54PBCIOV3P5FAYPZYBIHR7W)",
            simulatePrefix + maskedContext + wellFormed + " ",
            simulatePrefix + maskedContext + wellFormed + "\n",
            simulatePrefix + maskedContext + String(wellFormed.dropLast()),
            simulatePrefix + maskedContext + " (contract error in diagnostic events: Error(Contract, #3201)),  contract \(Fixtures.thresholdPolicy))",
            simulatePrefix + maskedContext + " (contract error in diagnostic events:  Error(Contract, #3201))",
        ]
        for message in messages {
            XCTAssertNil(AssembledTransactionError.simulationFailed(message: message).reportedContractError, message)
        }
        XCTAssertEqual(AssembledTransactionError.simulationFailed(message: simulatePrefix + maskedContext + wellFormed)
                        .reportedContractError, fromEvents(3201, Fixtures.thresholdPolicy))
    }

    /// Every other case reads nothing, whatever its message.
    func testOtherCasesReadNothing() {
        let message = simulatePrefix + maskedContext + suffix(3201, Fixtures.thresholdPolicy)
        let others: [AssembledTransactionError] = [
            .notYetAssembled(message: message),
            .notYetSimulated(message: message),
            .notYetSigned(message: message),
            .missingPrivateKey(message: message),
            .restoreNeeded(message: message),
            .isReadCall(message: message),
            .unexpectedTxType(message: message),
            .multipleSignersRequired(message: message),
            .pollInterrupted(message: message),
            .automaticRestoreFailed(message: message),
            .sendFailed(message: message),
        ]
        for error in others {
            XCTAssertNil(error.reportedContractError, "\(error)")
        }
        XCTAssertNotNil(AssembledTransactionError.simulationFailed(message: message).reportedContractError)
    }

    /// Suffix-shaped text that a caller or contract controls never sits at the end.
    func testSuffixShapedArgumentTextIsNotRead() async throws {
        let spoof = " (contract error in diagnostic events: Error(Contract, #1), contract \(Synthetic.otherContract))"
        let text = try Fixtures.errorText(Fixtures.caseA30)
            + "   13: [Diagnostic Event] topics:[fn_call, \(invokedContract), test], data:[\"x\(spoof)\"]\n"

        let (withoutEvents, message) = try await buildFailure(error: text, events: nil)
        XCTAssertEqual(message, simulatePrefix + text)
        XCTAssertNil(withoutEvents.reportedContractError)

        let (withEvents, _) = try await buildFailure(error: text, events: try Fixtures.events(Fixtures.caseA))
        XCTAssertEqual(withEvents.reportedContractError, fromEvents(3201, Fixtures.thresholdPolicy))

        let singleLine = simulatePrefix + maskedContext + " \"x\(spoof)\""
        XCTAssertNil(AssembledTransactionError.simulationFailed(message: singleLine).reportedContractError)
    }

    /// A suffix counts only after a masked header; a contract header keeps precedence.
    func testSuffixCountsOnlyAfterAMaskedHeader() {
        let wellFormed = suffix(3201, Fixtures.thresholdPolicy)
        XCTAssertNil(AssembledTransactionError.simulationFailed(
            message: simulatePrefix + "HostError: Error(Storage, MissingValue)" + wellFormed).reportedContractError)
        XCTAssertEqual(AssembledTransactionError.simulationFailed(
            message: simulatePrefix + "HostError: Error(Contract, #8)" + wellFormed).reportedContractError,
                       fromHeader(8))
        XCTAssertEqual(AssembledTransactionError.simulationFailed(
            message: simulationDataPrefix + maskedAuth + wellFormed).reportedContractError,
                       fromEvents(3201, Fixtures.thresholdPolicy))
    }

    /// The header is the first line only.
    func testHeaderIsReadFromTheFirstLineOnly() throws {
        XCTAssertNil(AssembledTransactionError.simulationFailed(
            message: simulatePrefix + "x\nHostError: Error(Contract, #5)").reportedContractError)
        XCTAssertNil(try reported(error: "x\nHostError: Error(Contract, #5)", events: nil))
        XCTAssertEqual(AssembledTransactionError.simulationFailed(
            message: simulatePrefix + "HostError: Error(Contract, #5)\nx").reportedContractError, fromHeader(5))
    }
}
