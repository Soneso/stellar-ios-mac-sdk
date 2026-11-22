//
//  SACTestSupport.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Takes every HTTP(S) request that no `ServerMock` mock answers, records it, and fails it
/// with `URLError(.cannotConnectToHost)`.
///
/// `ServerMock` declines a request no mock matches, and the request would then load from
/// the network. A session whose `protocolClasses` list this class after `ServerMock` keeps
/// such a request off the network, and the test that sent it fails in `tearDown` through
/// `SACMockRPC.tearDown(file:line:)`.
final class SACUnmatchedRequestCatcher: URLProtocol {

    private final class Log: @unchecked Sendable {
        private let lock = NSLock()
        private var records: [String] = []

        func append(_ record: String) {
            lock.lock()
            records.append(record)
            lock.unlock()
        }

        func all() -> [String] {
            lock.lock()
            defer { lock.unlock() }
            return records
        }

        func removeAll() {
            lock.lock()
            records.removeAll()
            lock.unlock()
        }
    }

    private static let log = Log()

    /// The caught requests in the order they arrived, each as its HTTP method and URL.
    static var records: [String] {
        return log.all()
    }

    /// Empties the record of caught requests.
    static func clear() {
        log.removeAll()
    }

    override static func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        SACUnmatchedRequestCatcher.log.append("\(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
    }

    override func stopLoading() {
    }
}

/// The fields of a transaction envelope with one operation that the double and the tests
/// compare, whatever the operation is.
struct SACEnvelope {
    /// The account id of the transaction's source account.
    let source: String
    /// The sequence number of the transaction.
    let sequenceNumber: Int64
    /// The fee of the transaction.
    let fee: UInt32
    /// The Soroban data of the transaction as base64 XDR; nil when it carries none.
    let sorobanData: String?
    /// The authorization entries of an invoke host function operation, each as base64 XDR;
    /// empty for any other operation.
    let authEntries: [String]
    /// The signatures of the envelope, each as base64 XDR.
    let signatures: [String]
    /// Whether the operation restores a footprint.
    let isRestoreFootprint: Bool

    /// Decodes the base64 envelope of a transaction with exactly one operation.
    init(envelope: String) throws {
        try self.init(try SACEnvelope.decoded(envelope))
    }

    /// Reads the fields of a decoded envelope with exactly one operation.
    fileprivate init(_ v1: TransactionV1EnvelopeXDR) throws {
        let tx = v1.tx
        guard tx.operations.count == 1 else {
            throw SACTestError("the transaction has \(tx.operations.count) operations, expected one")
        }
        source = tx.sourceAccount.ed25519AccountId
        sequenceNumber = tx.seqNum
        fee = tx.fee
        if case .sorobanTransactionData(let data) = tx.ext {
            sorobanData = try SACTestXdr.base64(data)
        } else {
            sorobanData = nil
        }
        if case .invokeHostFunctionOp(let operation) = tx.operations[0].body {
            authEntries = try operation.auth.map { try SACTestXdr.base64($0) }
        } else {
            authEntries = []
        }
        signatures = try v1.signatures.map { try SACTestXdr.base64($0) }
        if case .restoreFootprintOp = tx.operations[0].body {
            isRestoreFootprint = true
        } else {
            isRestoreFootprint = false
        }
    }

    /// The v1 transaction envelope the base64 `envelope` holds.
    fileprivate static func decoded(_ envelope: String) throws -> TransactionV1EnvelopeXDR {
        guard case .v1(let v1) = try TransactionEnvelopeXDR(xdr: envelope) else {
            throw SACTestError("the envelope is not a v1 transaction envelope")
        }
        return v1
    }
}

/// The single contract invocation of a transaction, as a test asserts it.
struct SACInvocation {
    /// The envelope fields of the transaction: its source, sequence number, fee, and signatures.
    let envelope: SACEnvelope
    /// The upper time bound of the transaction; nil without time bounds.
    let maxTime: UInt64?
    /// The invoked contract as its "C..." strkey.
    let contractId: String
    /// The invoked function.
    let function: String
    /// The arguments in order, each as base64 XDR.
    let args: [String]

    /// Decodes the base64 envelope of a transaction with exactly one operation, which invokes
    /// a contract.
    init(envelope: String) throws {
        let v1 = try SACEnvelope.decoded(envelope)
        self.envelope = try SACEnvelope(v1)
        let tx = v1.tx
        guard case .invokeHostFunctionOp(let operation) = tx.operations[0].body,
              case .invokeContract(let invoked) = operation.hostFunction else {
            throw SACTestError("the transaction is not a single contract invocation")
        }
        guard let function = invoked.functionNameString else {
            throw SACTestError("the function name is not valid UTF-8")
        }
        switch tx.cond {
        case .none:
            maxTime = nil
        case .time(let timeBounds):
            maxTime = timeBounds.maxTime
        case .v2(let preconditions):
            maxTime = preconditions.timeBounds?.maxTime
        }
        contractId = try invoked.contractAddress.toStrKey()
        self.function = function
        args = try invoked.args.map { try SACTestXdr.base64($0) }
    }
}

/// An error of the test support itself.
struct SACTestError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

/// XDR helpers of the SAC tests.
enum SACTestXdr {

    /// The XDR of `value` in base64.
    static func base64(_ value: XDREncodable) throws -> String {
        return Data(try XDREncoder.encode(value)).base64EncodedString()
    }

    /// The XDR of each of `values` in base64, for comparing argument lists.
    static func base64(_ values: [SCValXDR]) throws -> [String] {
        return try values.map { try base64($0) }
    }
}

/// A Soroban RPC test double for one mock host.
///
/// It registers one `ServerMock` mock for every `POST` to its host and offers the URL
/// session that routes requests to it. It answers only the requests it expects:
/// - `getLedgerEntries` must carry exactly one key, that key must be one of the expected
///   keys (the source's account, or the contract's instance, code, or tag key), and an
///   answer must be queued under the key's name: `account`, `instance`, `code`, or `tag`.
/// - `simulateTransaction` (`simulate`) needs a queued simulation.
/// - `sendTransaction` (`send`) must carry the last simulated transaction, completed with
///   that simulation's Soroban data, authorization entries, and resource fee and signed once
///   by the source. The answer reports the envelope's hash.
/// - `getTransaction` (`getTx`) must ask for the hash the send answer reported.
///
/// Every answered request is logged by its name with its body. Any other request, and a
/// sent envelope or a polled hash that differs, is recorded as a failure; an unexpected
/// request is answered with a JSON-RPC error. A test keeps the double in a stored property
/// and calls `tearDown(file:line:)` from its own `tearDown`, which fails the test for a
/// recorded failure and for a request the catcher caught.
final class SACMockRPC {

    /// The answer to a `getLedgerEntries` request.
    enum LedgerAnswer {
        /// The ledger entry stored under the requested key.
        case entry(LedgerEntryDataXDR)
        /// A result without entries: nothing is stored under the requested key.
        case noEntry
        /// A JSON-RPC error.
        case rpcError(code: Int, message: String)
    }

    /// The result of a `simulateTransaction` request.
    struct Simulation {
        /// The Soroban data of the simulated transaction.
        var transactionData: SorobanTransactionDataXDR?
        /// The resource fee, sent as a decimal string.
        var minResourceFee: UInt32?
        /// The value the invocation returns; nil sends no `results`.
        var returnValue: SCValXDR?
        /// The authorization entries the invocation needs.
        var auth: [SorobanAuthorizationEntryXDR] = []
        /// The host error of a failed simulation.
        var error: String?
        /// The restore preamble: the Soroban data and the resource fee of the restore.
        var restorePreamble: (transactionData: SorobanTransactionDataXDR, minResourceFee: UInt32)?

        /// A successful simulation of a read: no authorization entry and nothing written.
        static func read(contractId: String, returning value: SCValXDR) -> Simulation {
            return Simulation(transactionData: SACMockRPC.transactionData(contractId: contractId, writes: false),
                              minResourceFee: 500,
                              returnValue: value)
        }

        /// A successful simulation of a write, which returns void.
        static func write(contractId: String, auth: [SorobanAuthorizationEntryXDR] = [], minResourceFee: UInt32 = 1000) -> Simulation {
            return Simulation(transactionData: SACMockRPC.transactionData(contractId: contractId, writes: true),
                              minResourceFee: minResourceFee,
                              returnValue: SCValXDR.void,
                              auth: auth)
        }

        /// A simulation that fails with the given host error.
        static func failure(_ error: String) -> Simulation {
            return Simulation(error: error)
        }
    }

    /// The answer to a `sendTransaction` request.
    enum SendAnswer {
        /// A result with the given status, such as `PENDING` or `ERROR`, and the hash of the
        /// sent envelope.
        case status(String)
        /// A JSON-RPC error.
        case rpcError(code: Int, message: String)
    }

    /// The answer to a `getTransaction` request.
    enum TransactionAnswer {
        /// A result with the given status and, when given, the transaction result XDR.
        case status(String, resultXdr: String? = nil)
        /// A JSON-RPC error: a failed status request.
        case rpcError(code: Int, message: String)
    }

    /// One answered request: its name, such as `instance` or `simulate`, and its JSON-RPC body.
    struct Request {
        let name: String
        let body: Data

        /// The `params` object of the JSON-RPC body.
        func params() throws -> [String: Any] {
            guard let json = try JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let params = json["params"] as? [String: Any] else {
                throw SACTestError("the \(name) request has no params object")
            }
            return params
        }

        /// The base64 envelope a `simulate` or `send` request carries.
        func envelope() throws -> String {
            guard let envelope = try params()["transaction"] as? String else {
                throw SACTestError("the \(name) request carries no transaction")
            }
            return envelope
        }

        /// The envelope fields of the transaction a `simulate` or `send` request carries.
        func envelopeFields() throws -> SACEnvelope {
            return try SACEnvelope(envelope: try envelope())
        }

        /// The contract invocation a `simulate` or `send` request carries.
        func invocation() throws -> SACInvocation {
            return try SACInvocation(envelope: try envelope())
        }
    }

    static let account = "account"
    static let instance = "instance"
    static let code = "code"
    static let tag = "tag"
    static let simulate = "simulate"
    static let send = "send"
    static let getTx = "getTx"

    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private let network: Network
        private var expectedKeys: [String: String] = [:]
        private var ledgerAnswers: [String: [LedgerAnswer]] = [:]
        private var simulations: [Simulation] = []
        private var sendAnswer: SendAnswer?
        private var transactionAnswers: [TransactionAnswer] = []
        private var answered: [String: Int] = [:]
        private var signer: KeyPair?
        private var lastSimulated: (envelope: String, simulation: Simulation)?
        private var sentHash: String?
        private var requests: [Request] = []
        private var failures: [String] = []

        init(network: Network) {
            self.network = network
        }

        func locked<Value>(_ body: (State) -> Value) -> Value {
            lock.lock()
            defer { lock.unlock() }
            return body(self)
        }

        func expect(_ name: String, key: String) {
            locked { $0.expectedKeys[name] = key }
        }

        func setLedgerAnswers(_ answers: [LedgerAnswer], for name: String) {
            locked {
                $0.ledgerAnswers[name] = answers
                $0.answered[name] = 0
            }
        }

        func setSimulations(_ simulations: [Simulation]) {
            locked {
                $0.simulations = simulations
                $0.answered[SACMockRPC.simulate] = 0
            }
        }

        func setSendAnswer(_ answer: SendAnswer) {
            locked { $0.sendAnswer = answer }
        }

        func setTransactionAnswers(_ answers: [TransactionAnswer]) {
            locked {
                $0.transactionAnswers = answers
                $0.answered[SACMockRPC.getTx] = 0
            }
        }

        func setSigner(_ signer: KeyPair) {
            locked { $0.signer = signer }
        }

        func allRequests() -> [Request] {
            return locked { $0.requests }
        }

        func clearRequests() {
            locked { $0.requests.removeAll() }
        }

        func allFailures() -> [String] {
            return locked { $0.failures }
        }

        func hashOfSentTransaction() -> String? {
            return locked { $0.sentHash }
        }

        /// The JSON-RPC answer to `request`.
        func respond(to request: URLRequest) -> String {
            // URLProtocol hands over the POST body as a stream.
            let body = request.httpBody ?? request.httpBodyStream?.readfully() ?? Data()
            lock.lock()
            defer { lock.unlock() }
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let method = json["method"] as? String else {
                return refuse("a body that is no JSON-RPC request", body: body)
            }
            let params = json["params"] as? [String: Any] ?? [:]
            switch method {
            case "getLedgerEntries":
                return ledgerEntries(params: params, body: body)
            case "simulateTransaction":
                return simulate(params: params, body: body)
            case "sendTransaction":
                return send(params: params, body: body)
            case "getTransaction":
                return transaction(params: params, body: body)
            default:
                return refuse("the unexpected method \(method)", body: body)
            }
        }

        /// The index of the next answer of `count` queued under `name`; the last one repeats.
        private func nextIndex(_ name: String, count: Int) -> Int {
            let index = min(answered[name] ?? 0, count - 1)
            answered[name] = index + 1
            return index
        }

        private func ledgerEntries(params: [String: Any], body: Data) -> String {
            guard let keys = params["keys"] as? [String], keys.count == 1 else {
                return refuse("getLedgerEntries without exactly one key", body: body)
            }
            guard let name = expectedKeys.first(where: { $0.value == keys[0] })?.key else {
                return refuse("getLedgerEntries for the unexpected key \(keys[0])", body: body)
            }
            guard let answers = ledgerAnswers[name], !answers.isEmpty else {
                return refuse("getLedgerEntries for \(name), which has no answer", body: body)
            }
            requests.append(Request(name: name, body: body))
            switch answers[nextIndex(name, count: answers.count)] {
            case .entry(let entry):
                return SACMockRPC.resultJson([
                    "entries": [["key": keys[0], "xdr": entry.xdrEncoded!, "lastModifiedLedgerSeq": 999000]],
                    "latestLedger": 1000000])
            case .noEntry:
                return SACMockRPC.resultJson(["entries": [], "latestLedger": 1000000])
            case .rpcError(let code, let message):
                return SACMockRPC.errorJson(code: code, message: message)
            }
        }

        private func simulate(params: [String: Any], body: Data) -> String {
            guard let envelope = params["transaction"] as? String else {
                return refuse("simulateTransaction without a transaction", body: body)
            }
            guard !simulations.isEmpty else {
                return refuse("simulateTransaction, which has no answer", body: body)
            }
            let simulation = simulations[nextIndex(SACMockRPC.simulate, count: simulations.count)]
            lastSimulated = (envelope, simulation)
            requests.append(Request(name: SACMockRPC.simulate, body: body))
            var result: [String: Any] = ["latestLedger": 12345]
            if let transactionData = simulation.transactionData {
                result["transactionData"] = transactionData.xdrEncoded!
            }
            if let minResourceFee = simulation.minResourceFee {
                result["minResourceFee"] = String(minResourceFee)
            }
            if let returnValue = simulation.returnValue {
                result["results"] = [["auth": simulation.auth.map { $0.xdrEncoded! }, "xdr": returnValue.xdrEncoded!]]
            }
            if let error = simulation.error {
                result["error"] = error
            }
            if let restorePreamble = simulation.restorePreamble {
                result["restorePreamble"] = [
                    "transactionData": restorePreamble.transactionData.xdrEncoded!,
                    "minResourceFee": String(restorePreamble.minResourceFee)]
            }
            return SACMockRPC.resultJson(result)
        }

        private func send(params: [String: Any], body: Data) -> String {
            guard let envelope = params["transaction"] as? String else {
                return refuse("sendTransaction without a transaction", body: body)
            }
            guard let answer = sendAnswer else {
                return refuse("sendTransaction, which has no answer", body: body)
            }
            guard let hash = try? Transaction(envelopeXdr: envelope).getTransactionHash(network: network) else {
                return refuse("sendTransaction with an envelope that does not decode", body: body)
            }
            failures += sentEnvelopeMismatches(envelope)
            sentHash = hash
            requests.append(Request(name: SACMockRPC.send, body: body))
            switch answer {
            case .status(let status):
                return SACMockRPC.resultJson([
                    "status": status,
                    "hash": hash,
                    "latestLedger": 12345,
                    "latestLedgerCloseTime": "1234567890"])
            case .rpcError(let code, let message):
                return SACMockRPC.errorJson(code: code, message: message)
            }
        }

        /// What differs between the sent envelope and the last simulated transaction after
        /// the simulation's Soroban data, authorization entries, and resource fee are applied
        /// and the source has signed once: each field by its name, then the whole envelope.
        private func sentEnvelopeMismatches(_ sent: String) -> [String] {
            guard let (simulatedEnvelope, simulation) = lastSimulated else {
                return ["sendTransaction without a simulated transaction"]
            }
            guard let signer = signer else {
                return ["sendTransaction, but the double has no signer to build the expected envelope"]
            }
            do {
                let transaction = try Transaction(envelopeXdr: simulatedEnvelope)
                if let transactionData = simulation.transactionData {
                    transaction.setSorobanTransactionData(data: transactionData)
                    if simulation.returnValue != nil {
                        transaction.setSorobanAuth(auth: simulation.auth)
                    }
                    if let minResourceFee = simulation.minResourceFee {
                        transaction.addResourceFee(resourceFee: minResourceFee)
                    }
                }
                try transaction.sign(keyPair: signer, network: network)
                let expectedEnvelope = try transaction.encodedEnvelope()
                let expected = try SACEnvelope(envelope: expectedEnvelope)
                let actual = try SACEnvelope(envelope: sent)
                var mismatches: [String] = []
                if actual.fee != expected.fee {
                    mismatches.append("sendTransaction fee is \(actual.fee), expected \(expected.fee)")
                }
                if actual.sequenceNumber != expected.sequenceNumber {
                    mismatches.append("sendTransaction sequence number is \(actual.sequenceNumber), expected \(expected.sequenceNumber)")
                }
                if actual.sorobanData != expected.sorobanData {
                    mismatches.append("sendTransaction Soroban data is \(actual.sorobanData ?? "absent"), expected \(expected.sorobanData ?? "absent")")
                }
                if actual.authEntries != expected.authEntries {
                    mismatches.append("sendTransaction authorization entries are \(actual.authEntries), expected \(expected.authEntries)")
                }
                if actual.signatures != expected.signatures {
                    mismatches.append("sendTransaction signatures are \(actual.signatures), expected \(expected.signatures)")
                }
                if sent != expectedEnvelope {
                    mismatches.append("sendTransaction envelope is \(sent), expected \(expectedEnvelope)")
                }
                return mismatches
            } catch {
                return ["sendTransaction envelope cannot be compared: \(error)"]
            }
        }

        private func transaction(params: [String: Any], body: Data) -> String {
            guard let hash = params["hash"] as? String else {
                return refuse("getTransaction without a hash", body: body)
            }
            guard !transactionAnswers.isEmpty else {
                return refuse("getTransaction, which has no answer", body: body)
            }
            guard hash == sentHash else {
                return refuse("getTransaction for the hash \(hash), expected \(sentHash ?? "no request before a send")", body: body)
            }
            requests.append(Request(name: SACMockRPC.getTx, body: body))
            switch transactionAnswers[nextIndex(SACMockRPC.getTx, count: transactionAnswers.count)] {
            case .status(let status, let resultXdr):
                var result: [String: Any] = [
                    "status": status,
                    "latestLedger": 12345,
                    "latestLedgerCloseTime": "1234567890",
                    "oldestLedger": 100]
                if let resultXdr = resultXdr {
                    result["resultXdr"] = resultXdr
                }
                return SACMockRPC.resultJson(result)
            case .rpcError(let code, let message):
                return SACMockRPC.errorJson(code: code, message: message)
            }
        }

        private func refuse(_ reason: String, body: Data) -> String {
            failures.append("unexpected request: \(reason): \(String(decoding: body, as: UTF8.self))")
            return SACMockRPC.errorJson(code: -32600, message: "unexpected request: \(reason)")
        }
    }

    /// The RPC URL on the mock host, which resolves nowhere.
    let rpcUrl: String

    /// The session whose requests reach this double; a request no mock matches is caught by
    /// `SACUnmatchedRequestCatcher`.
    let session: URLSession

    private let state: State
    private let mock: RequestMock

    /// Creates the double for `host` and registers its mock.
    ///
    /// - Parameter host: A host name ending in `.mock`.
    /// - Parameter contractId: The contract whose instance key the double expects, a "C..." strkey.
    /// - Parameter network: The network whose passphrase signs and hashes the transactions.
    ///   Default testnet.
    init(host: String, contractId: String, network: Network = Network.testnet) {
        self.rpcUrl = "https://\(host)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ServerMock.self, SACUnmatchedRequestCatcher.self]
        self.session = URLSession(configuration: configuration)
        let state = State(network: network)
        self.state = state
        self.mock = RequestMock(host: host, path: "*", httpMethod: "POST") { mock, request in
            mock.statusCode = 200
            return state.respond(to: request)
        }
        ServerMock.add(mock: mock)
        state.expect(SACMockRPC.instance, key: SACMockRPC.instanceKey(contractId: contractId))
    }

    // MARK: - Expectations and answers

    /// Expects the account request of `source` and answers it with its account entry at each
    /// of `sequenceNumbers`, one per request in order; the last one repeats. The double builds
    /// the expected `sendTransaction` envelope with `source`, which needs its private key for that.
    func serveAccount(of source: KeyPair, sequenceNumbers: [Int64] = [12345]) {
        state.expect(SACMockRPC.account, key: SACMockRPC.accountKey(accountId: source.accountId))
        state.setLedgerAnswers(sequenceNumbers.map { .entry(SACMockRPC.accountEntry(of: source, sequenceNumber: $0)) },
                               for: SACMockRPC.account)
        state.setSigner(source)
    }

    /// Expects the code request for `wasmHash` and queues its answers.
    func serveCode(wasmHash: Data, answers: [LedgerAnswer]) {
        state.expect(SACMockRPC.code, key: SACMockRPC.codeKey(wasmHash: wasmHash))
        state.setLedgerAnswers(answers, for: SACMockRPC.code)
    }

    /// Expects the request for the entry of `owner` under the executable tag `tag` and
    /// queues its answers.
    func serveTag(owner: String, tag: Data, answers: [LedgerAnswer]) {
        state.expect(SACMockRPC.tag, key: SACMockRPC.tagKey(owner: owner, tag: tag))
        state.setLedgerAnswers(answers, for: SACMockRPC.tag)
    }

    /// Queues the answers to the instance requests, one per request in order; the last one
    /// repeats.
    func serveInstance(_ answers: [LedgerAnswer]) {
        state.setLedgerAnswers(answers, for: SACMockRPC.instance)
    }

    /// Queues the results of the `simulateTransaction` requests, one per request in order;
    /// the last one repeats.
    func serveSimulations(_ simulations: [Simulation]) {
        state.setSimulations(simulations)
    }

    /// Sets the answer to `sendTransaction` requests.
    func serveSend(_ answer: SendAnswer) {
        state.setSendAnswer(answer)
    }

    /// Queues the answers to the `getTransaction` requests, one per request in order; the
    /// last one repeats.
    func serveTransaction(_ answers: [TransactionAnswer]) {
        state.setTransactionAnswers(answers)
    }

    // MARK: - The log

    /// The answered requests in the order they arrived.
    var requests: [Request] {
        return state.allRequests()
    }

    /// The answered request at `index` in the order of arrival.
    func request(_ index: Int) throws -> Request {
        let requests = state.allRequests()
        guard requests.indices.contains(index) else {
            throw SACTestError("the request log has \(requests.count) requests, none at index \(index)")
        }
        return requests[index]
    }

    /// The names of the answered requests in the order they arrived.
    var requestNames: [String] {
        return state.allRequests().map { $0.name }
    }

    /// The answered requests named `name` in the order they arrived.
    func requests(named name: String) -> [Request] {
        return state.allRequests().filter { $0.name == name }
    }

    /// Empties the log of answered requests; queued answers and their positions stay.
    func clearRequests() {
        state.clearRequests()
    }

    /// The hash the last `sendTransaction` answer reported.
    var sentHash: String? {
        return state.hashOfSentTransaction()
    }

    /// The requests the double did not expect and the sent envelopes and polled hashes that
    /// differ, each as the reason.
    var failures: [String] {
        return state.allFailures()
    }

    /// Fails the test for a recorded failure and for a request the catcher caught, then
    /// removes the mock and invalidates the session.
    func tearDown(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(failures, [], "the mock RPC received requests it did not expect", file: file, line: line)
        XCTAssertEqual(SACUnmatchedRequestCatcher.records, [], "requests left the mock", file: file, line: line)
        SACUnmatchedRequestCatcher.clear()
        ServerMock.removeAll()
        session.invalidateAndCancel()
    }

    // MARK: - Ledger keys

    /// The base64 ledger key of the account `accountId`.
    static func accountKey(accountId: String) -> String {
        return LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: try! PublicKey(accountId: accountId))).xdrEncoded!
    }

    /// The base64 ledger key of the instance entry of `contractId`.
    static func instanceKey(contractId: String) -> String {
        return contractDataKey(contractId: contractId, key: SCValXDR.ledgerKeyContractInstance)
    }

    /// The base64 ledger key of the entry of `owner` under the executable tag `tag`.
    static func tagKey(owner: String, tag: Data) -> String {
        return contractDataKey(contractId: owner, key: SCValXDR.executableTag(tag))
    }

    /// The base64 ledger key of the code with the hash `wasmHash`.
    static func codeKey(wasmHash: Data) -> String {
        return LedgerKeyXDR.contractCode(try! LedgerKeyContractCodeXDR(wasmId: wasmHash.base16EncodedString())).xdrEncoded!
    }

    private static func contractDataKey(contractId: String, key: SCValXDR) -> String {
        return LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: try! SCAddressXDR(contractId: contractId),
            key: key,
            durability: .persistent)).xdrEncoded!
    }

    // MARK: - Ledger entries

    /// The account entry of `keyPair` at `sequenceNumber`.
    static func accountEntry(of keyPair: KeyPair, sequenceNumber: Int64) -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.account(AccountEntryXDR(
            accountID: keyPair.publicKey,
            balance: 100_000_000_0,
            sequenceNumber: sequenceNumber,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "",
            thresholds: WrappedData4(Data([1, 0, 0, 0])),
            signers: [],
            ext: .void))
    }

    /// The instance entry of `contractId` with the given executable and no storage.
    static func instanceEntry(contractId: String, executable: ContractExecutableXDR) -> LedgerEntryDataXDR {
        return contractDataEntry(contractId: contractId,
                                 key: SCValXDR.ledgerKeyContractInstance,
                                 val: SCValXDR.contractInstance(SCContractInstanceXDR(executable: executable, storage: nil)))
    }

    /// A persistent contract data entry of `contractId`.
    static func contractDataEntry(contractId: String, key: SCValXDR, val: SCValXDR) -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.contractData(ContractDataEntryXDR(
            ext: .void,
            contract: try! SCAddressXDR(contractId: contractId),
            key: key,
            durability: .persistent,
            val: val))
    }

    /// The code entry with the hash `wasmHash` and the bytes `code`.
    static func codeEntry(wasmHash: Data, code: Data) -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.contractCode(ContractCodeEntryXDR(ext: .void, hash: WrappedData32(wasmHash), code: code))
    }

    /// Soroban data whose footprint reads the instance of `contractId` and, with `writes`,
    /// writes one of its data entries.
    static func transactionData(contractId: String, writes: Bool, resourceFee: Int64 = 10000) -> SorobanTransactionDataXDR {
        let contract = try! SCAddressXDR(contractId: contractId)
        let instance = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: contract, key: SCValXDR.ledgerKeyContractInstance, durability: .persistent))
        let balance = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: contract, key: SCValXDR.u32(1), durability: .persistent))
        return SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [instance], readWrite: writes ? [balance] : []),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: writes ? 50 : 0),
            resourceFee: resourceFee)
    }

    /// An unsigned authorization entry with address credentials of `address` for a call of
    /// `function` on `contractId`.
    static func addressAuthEntry(address: SCAddressXDR, contractId: String, function: String, args: [SCValXDR]) -> SorobanAuthorizationEntryXDR {
        let credentials = SorobanAddressCredentialsXDR(address: address,
                                                       nonce: 123,
                                                       signatureExpirationLedger: 0,
                                                       signature: SCValXDR.void)
        return SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(credentials),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: SorobanAuthorizedFunctionXDR.contractFn(InvokeContractArgsXDR(
                    contractAddress: try! SCAddressXDR(contractId: contractId),
                    functionName: function,
                    args: args)),
                subInvocations: []))
    }

    // MARK: - JSON-RPC answers

    private static func resultJson(_ result: [String: Any]) -> String {
        return json(["jsonrpc": "2.0", "id": 1, "result": result])
    }

    private static func errorJson(code: Int, message: String) -> String {
        return json(["jsonrpc": "2.0", "id": 1, "error": ["code": code, "message": message]])
    }

    private static func json(_ object: [String: Any]) -> String {
        return String(decoding: try! JSONSerialization.data(withJSONObject: object), as: UTF8.self)
    }
}

/// Assertions the SAC tests share.
enum SACAssert {

    /// Asserts the complete invocation `request` carries: the source account, the sequence
    /// number, the contract, the function, and the full argument list in order.
    static func invocation(_ request: SACMockRPC.Request,
                           source: String,
                           sequenceNumber: Int64,
                           contractId: String,
                           function: String,
                           args: [SCValXDR],
                           file: StaticString = #filePath,
                           line: UInt = #line) throws {
        let invocation = try request.invocation()
        XCTAssertEqual(invocation.envelope.source, source, "source", file: file, line: line)
        XCTAssertEqual(invocation.envelope.sequenceNumber, sequenceNumber, "sequence number", file: file, line: line)
        XCTAssertEqual(invocation.contractId, contractId, "contract", file: file, line: line)
        XCTAssertEqual(invocation.function, function, "function", file: file, line: line)
        XCTAssertEqual(invocation.args, try SACTestXdr.base64(args), "arguments", file: file, line: line)
    }

    /// Asserts that `text` holds no 8 character window of `seed`.
    static func holdsNoPartOfSeed(_ text: String, seed: String, file: StaticString = #filePath, line: UInt = #line) {
        let characters = Array(seed)
        XCTAssertGreaterThanOrEqual(characters.count, 8, file: file, line: line)
        for start in 0...(characters.count - 8) {
            let window = String(characters[start..<(start + 8)])
            XCTAssertFalse(text.contains(window), "the text holds \(window) of the seed", file: file, line: line)
        }
    }

    /// Runs `body`, which must throw, and returns the error it throws.
    static func error(file: StaticString = #filePath, line: UInt = #line, _ body: () async throws -> Void) async -> Error? {
        do {
            try await body()
            XCTFail("expected an error", file: file, line: line)
            return nil
        } catch {
            return error
        }
    }
}
