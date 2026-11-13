//
//  SimulationFailureTestSupport.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The failing `simulateTransaction` responses captured unsigned on testnet on 2026-11-13,
/// six from stellar-rpc 30.0.1 and their twins (`-rpc30.0.0`) from stellar-rpc 30.0.0.
enum SimulationFailureFixtures {

    /// Constructor whose threshold policy rejects the threshold: `Error(Context, InvalidAction)`,
    /// earliest error event 3201 from the policy contract.
    static let caseA = "case-a-response"
    static let caseA30 = "case-a-rpc30.0.0-response"
    /// `__check_auth` with a bad WebAuthn challenge: `Error(Auth, InvalidAction)`, 3114 from
    /// the verifier.
    static let caseB1 = "case-b1-registered-badsig-response"
    static let caseB130 = "case-b1-registered-badsig-rpc30.0.0-response"
    /// `__check_auth` with an unregistered signer: `Error(Auth, InvalidAction)`, 3016 from the
    /// account.
    static let caseB2 = "case-b2-unregistered-response"
    static let caseB230 = "case-b2-unregistered-rpc30.0.0-response"
    /// `__check_auth` with a bad signature: `Error(Auth, InvalidAction)`, only a Crypto error.
    static let caseB3 = "case-b3-registered-rightchallenge-badsig-response"
    static let caseB330 = "case-b3-registered-rightchallenge-badsig-rpc30.0.0-response"
    /// A policy call raising its own error: `Error(Contract, #3200)`.
    static let caseC1 = "case-c1-policy-get-threshold-response"
    static let caseC130 = "case-c1-policy-get-threshold-rpc30.0.0-response"
    /// A SAC transfer of a negative amount: `Error(Contract, #8)`.
    static let caseC2 = "case-c2-sac-negative-transfer-response"
    static let caseC230 = "case-c2-sac-negative-transfer-rpc30.0.0-response"

    static let all = [caseA, caseA30, caseB1, caseB130, caseB2, caseB230,
                      caseB3, caseB330, caseC1, caseC130, caseC2, caseC230]

    /// The threshold policy contract that emits 3201 in the constructor capture (`caseA`).
    static let thresholdPolicy = "CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC"
    /// The WebAuthn verifier that emits 3114 in the bad-challenge capture (`caseB1`).
    static let webAuthnVerifier = "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
    /// The smart account that emits 3016 in the unregistered-signer capture (`caseB2`).
    static let smartAccount = "CABAV4UNU66OZ75MXQDX3FFO35WNQLLXG2HZAHKJNZ27C2LGAX4DK253"

    /// The JSON-RPC response body exactly as captured.
    static func body(_ name: String) throws -> String {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "simulation_failures"),
            "missing fixture \(name)")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// The `result` object of the captured response.
    static func result(_ name: String) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: Data(try body(name).utf8))
        let envelope = try XCTUnwrap(object as? [String: Any])
        return try XCTUnwrap(envelope["result"] as? [String: Any])
    }

    /// The captured response decoded as the SDK decodes it.
    static func response(_ name: String) throws -> SimulateTransactionResponse {
        return try decodeResponse(result: try result(name))
    }

    /// The captured `events` array.
    static func events(_ name: String) throws -> [String] {
        return try XCTUnwrap(try result(name)["events"] as? [String])
    }

    /// The captured `error` text.
    static func errorText(_ name: String) throws -> String {
        return try XCTUnwrap(try result(name)["error"] as? String)
    }

    /// Decodes a `simulateTransaction` result object.
    static func decodeResponse(result: [String: Any]) throws -> SimulateTransactionResponse {
        let data = try JSONSerialization.data(withJSONObject: result)
        return try JSONDecoder().decode(SimulateTransactionResponse.self, from: data)
    }

    /// A JSON-RPC response body for a `simulateTransaction` result object.
    static func rpcBody(result: [String: Any]) throws -> String {
        let envelope: [String: Any] = ["jsonrpc": "2.0", "id": 1, "result": result]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    /// A failed simulation result with the given host error text and events (absent when nil).
    static func failureResult(error: String, events: [String]?) -> [String: Any] {
        var result: [String: Any] = ["latestLedger": 1000, "error": error]
        if let events = events {
            result["events"] = events
        }
        return result
    }
}

/// Synthetic diagnostic events built with the typed XDR API; every value here is synthetic.
enum SyntheticDiagnosticEvent {

    /// The testnet native asset contract, which emits the events of the SAC transfer capture
    /// (`caseC2`). The synthetic events use it as an emitter other than the policy, verifier
    /// and account contracts of `SimulationFailureFixtures`.
    static let otherContract = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    /// A base64 diagnostic event with the given topics and data.
    static func event(
        topics: [SCValXDR],
        data: SCValXDR = .void,
        contractId: String? = otherContract,
        inSuccessfulContractCall: Bool = false,
        type: ContractEventType = .diagnostic
    ) throws -> String {
        let hash = try contractId.map { WrappedData32(try $0.decodeContractId()) }
        let event = DiagnosticEventXDR(
            inSuccessfulContractCall: inSuccessfulContractCall,
            event: ContractEventXDR(
                ext: .void,
                hash: hash,
                type: type.rawValue,
                body: .v0(ContractEventBodyV0XDR(topics: topics, data: data))))
        return try XCTUnwrap(event.xdrEncoded)
    }

    /// A failed-call diagnostic error event with the topics `error` and `Error(Contract, #code)`.
    static func contractError(
        _ code: UInt32,
        contractId: String? = otherContract,
        inSuccessfulContractCall: Bool = false,
        type: ContractEventType = .diagnostic
    ) throws -> String {
        return try event(topics: [.symbol("error"), .error(.contract(code))],
                         data: .string("synthetic failure"),
                         contractId: contractId,
                         inSuccessfulContractCall: inSuccessfulContractCall,
                         type: type)
    }
}

/// Routes the JSON-RPC requests of an `AssembledTransaction` or `SorobanClient` call to
/// scripted responses on the mocked host `soroban-testnet.stellar.org`.
///
/// `getLedgerEntries` returns the source account, `simulateTransaction` takes the next body of
/// `simulateBodies` (the last one repeats) with `simulateStatusCode`, `sendTransaction` answers
/// PENDING and records the request body, `getTransaction` answers SUCCESS, `getLatestLedger`
/// answers a fixed ledger. Every response other than the simulation has the status 200.
final class SimulationRpcRouter: @unchecked Sendable {

    static let host = "soroban-testnet.stellar.org"
    static let rpcUrl = "https://soroban-testnet.stellar.org"

    private let lock = NSLock()
    private var simulateBodies: [String]
    private let simulateStatusCode: Int
    private var sendBodies: [String] = []
    private var simulateCount = 0
    private let accountJson: String

    /// Registers the router with `ServerMock`. The registered mock holds the router until the
    /// test's `tearDown` calls `ServerMock.removeAll()`. `ServerMock` answers with the first
    /// registered mock that matches, so a second router in one test needs that call first.
    init(sourceAccount: KeyPair, simulateBodies: [String], simulateStatusCode: Int = 200) {
        self.simulateBodies = simulateBodies
        self.simulateStatusCode = simulateStatusCode
        self.accountJson = SimulationRpcRouter.accountJson(for: sourceAccount)
        let mock = RequestMock(host: SimulationRpcRouter.host, path: "*", httpMethod: "POST") { mock, request in
            let (statusCode, body) = self.respond(to: request)
            mock.statusCode = statusCode
            return body
        }
        ServerMock.add(mock: mock)
    }

    /// The bodies of the `sendTransaction` requests, in order.
    var sentTransactionRequests: [String] {
        lock.lock(); defer { lock.unlock() }
        return sendBodies
    }

    /// The number of `simulateTransaction` requests answered.
    var simulateRequestCount: Int {
        lock.lock(); defer { lock.unlock() }
        return simulateCount
    }

    private func respond(to request: URLRequest) -> (Int, String?) {
        let bodyData = request.httpBody ?? request.httpBodyStream?.readfully() ?? Data()
        let body = String(decoding: bodyData, as: UTF8.self)
        lock.lock(); defer { lock.unlock() }
        if body.contains("\"getLedgerEntries\"") {
            return (200, accountJson)
        }
        if body.contains("\"simulateTransaction\"") {
            simulateCount += 1
            guard let next = simulateBodies.first else {
                return (simulateStatusCode, nil)
            }
            if simulateBodies.count > 1 {
                simulateBodies.removeFirst()
            }
            return (simulateStatusCode, next)
        }
        if body.contains("\"sendTransaction\"") {
            sendBodies.append(body)
            return (200, """
            {"jsonrpc": "2.0", "id": 1, "result": {"status": "PENDING", "hash": "abc123def456", "latestLedger": 1000000, "latestLedgerCloseTime": "1234567890"}}
            """)
        }
        if body.contains("\"getTransaction\"") {
            return (200, """
            {"jsonrpc": "2.0", "id": 1, "result": {"status": "SUCCESS", "latestLedger": 1000000, "latestLedgerCloseTime": "1234567890", "oldestLedger": 900000, "oldestLedgerCloseTime": "1234500000", "applicationOrder": 1, "ledger": 999999, "createdAt": "1234567880", "envelopeXdr": "AAAAAA==", "resultXdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=", "resultMetaXdr": "AAAAAA=="}}
            """)
        }
        if body.contains("\"getLatestLedger\"") {
            return (200, """
            {"jsonrpc": "2.0", "id": 1, "result": {"id": "abc123", "sequence": 999900, "protocolVersion": 20}}
            """)
        }
        return (200, nil)
    }

    /// A successful simulation with a read-write footprint, so the transaction is no read call,
    /// and with `events` as its diagnostic events (absent when empty).
    static func successBody(contractId: String, events: [String] = []) -> String {
        let eventsField = events.isEmpty
            ? ""
            : ", \"events\": [" + events.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        return """
        {"jsonrpc": "2.0", "id": 1, "result": {"latestLedger": 1000000, "transactionData": "\(transactionData(contractId: contractId))", "minResourceFee": "10000", "results": [{"auth": [], "xdr": "\(SCValXDR.u32(10).xdrEncoded!)"}]\(eventsField)}}
        """
    }

    /// A successful simulation that asks for a restore first.
    static func restorePreambleBody(contractId: String) -> String {
        return """
        {"jsonrpc": "2.0", "id": 1, "result": {"latestLedger": 1000000, "restorePreamble": {"transactionData": "\(transactionData(contractId: contractId))", "minResourceFee": "5000"}}}
        """
    }

    /// Base64 transaction data whose read-write footprint holds one persistent entry of
    /// `contractId`.
    private static func transactionData(contractId: String) -> String {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: [
                    LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
                        contract: try! SCAddressXDR(contractId: contractId),
                        key: SCValXDR.u32(1),
                        durability: .persistent))
                ]),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50),
            resourceFee: 10000)
        return transactionData.xdrEncoded!
    }

    /// A simulation without an error and without transaction data.
    static let noTransactionDataBody = """
    {"jsonrpc": "2.0", "id": 1, "result": {"latestLedger": 1000000}}
    """

    private static func accountJson(for keyPair: KeyPair) -> String {
        let accountEntry = AccountEntryXDR(
            accountID: keyPair.publicKey,
            balance: 1_000_000_000,
            sequenceNumber: 12345,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "",
            thresholds: WrappedData4(Data([1, 0, 0, 0])),
            signers: [],
            ext: .void)
        let entry = LedgerEntryDataXDR.account(accountEntry).xdrEncoded!
        let key = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: keyPair.publicKey)).xdrEncoded!
        return """
        {"jsonrpc": "2.0", "id": 1, "result": {"entries": [{"key": "\(key)", "xdr": "\(entry)", "lastModifiedLedgerSeq": 999000}], "latestLedger": 1000000}}
        """
    }
}

/// The simulation transport failures with a scripted HTTP status and body, and the
/// `SorobanRpcRequestError` `SorobanServer` reports for each.
enum SimulationTransportFailure: CaseIterable {
    /// A JSON-RPC error object.
    case jsonRpcError
    /// An HTTP 500 with a plain-text body.
    case http500
    /// An HTTP 200 whose body is no JSON.
    case unparsable

    var statusCode: Int {
        return self == .http500 ? 500 : 200
    }

    var body: String {
        switch self {
        case .jsonRpcError:
            return #"{"jsonrpc": "2.0", "id": 1, "error": {"code": -32603, "message": "Internal error"}}"#
        case .http500:
            return "Internal Server Error"
        case .unparsable:
            return "<html><body>Service Unavailable</body></html>"
        }
    }

    /// Asserts that `error` is the `SorobanRpcRequestError` for this failure, with its literal
    /// code and message.
    func assertError(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        guard let rpcError = error as? SorobanRpcRequestError else {
            return XCTFail("expected SorobanRpcRequestError for \(self), got \(String(describing: error))",
                           file: file, line: line)
        }
        switch (self, rpcError) {
        case (.jsonRpcError, .errorResponse(let response)):
            XCTAssertEqual(response.code, -32603, file: file, line: line)
            XCTAssertEqual(response.message, "Internal error", file: file, line: line)
            XCTAssertNil(response.data, file: file, line: line)
        case (.http500, .requestFailed(let message)):
            XCTAssertEqual(message, "Internal Server Error", file: file, line: line)
        case (.unparsable, .parsingResponseFailed(let message, let responseData)):
            XCTAssertEqual(message, "Invalid JSON", file: file, line: line)
            XCTAssertEqual(responseData, Data("<html><body>Service Unavailable</body></html>".utf8),
                           file: file, line: line)
        default:
            XCTFail("unexpected \(rpcError) for \(self)", file: file, line: line)
        }
    }
}

/// The `transaction` parameter of a recorded `sendTransaction` request body.
func sentEnvelope(in requestBody: String) throws -> Transaction {
    let object = try JSONSerialization.jsonObject(with: Data(requestBody.utf8))
    let params = try XCTUnwrap((object as? [String: Any])?["params"] as? [String: Any])
    let envelope = try XCTUnwrap(params["transaction"] as? String)
    return try Transaction(envelopeXdr: envelope)
}
