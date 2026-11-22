//
//  SACClientIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Verifies `SACClient` and the Stellar Asset Contract support of `SorobanClient`.
///
/// `testSACClient` runs against a live network. It issues a fresh asset, deploys its
/// Stellar Asset Contract at the id `Asset.contractId(network:)` derives, and opens the
/// contract with `SorobanClient.forClientOptions`. It then checks the read-only reads, a
/// transfer the source account sends, a transfer to a muxed account with its event, a
/// transfer another account authorizes, and the reads of the native asset's contract.
/// `testTransferToMuxedContract` runs against a live network that runs protocol 30 or later
/// and skips on an earlier protocol. It transfers a fresh asset to a muxed contract address
/// and checks the multiplexing id of the event and the balance of the base contract.
/// `testProtocolGate` runs offline against a mocked RPC server. It checks the protocol
/// check that decides whether `testTransferToMuxedContract` runs: its answer at, above and
/// below the required version, and its error naming the RPC URL for an answer without a
/// protocol version and for a JSON-RPC error.
final class SACClientIntegrationTests: XCTestCase {

    static let testOn = "testnet" // "futurenet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let rpcUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    /// The id of the native asset's Stellar Asset Contract on testnet.
    private static let testnetNativeContractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    /// The functions of the Stellar Asset Contract, in alphabetical order.
    private static let sacFunctionNames = [
        "admin", "allowance", "approve", "authorized", "balance", "burn", "burn_from", "clawback", "decimals",
        "mint", "name", "set_admin", "set_authorized", "symbol", "transfer", "transfer_from", "trust",
    ]

    /// The session and the mock of `testProtocolGate`; nil in the tests against the network.
    private var gateSession: URLSession?
    private var gateMock: RequestMock?

    override func tearDown() {
        ServerMock.removeAll()
        gateSession?.invalidateAndCancel()
        gateSession = nil
        gateMock = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testSACClient() async throws {
        let context = try await makeContext()
        let a = try SCAddressXDR(accountId: context.aId)
        let b = try SCAddressXDR(accountId: context.bId)

        // Detection: the generic client opens the contract, which has no wasm to load a spec from.
        let detected = try await SorobanClient.forClientOptions(options: ClientOptions(
            sourceAccountKeyPair: context.a,
            contractId: context.sacId,
            network: network,
            rpcUrl: rpcUrl))
        XCTAssertEqual(detected.methodNames.count, 17)
        XCTAssertEqual(detected.methodNames.sorted(), Self.sacFunctionNames)

        // Read-only reads, without a keypair.
        let reader = try SACClient.readOnlyForAsset(asset: context.asset, network: network, rpcUrl: rpcUrl)
        XCTAssertEqual(reader.contractId, context.sacId)
        let balanceOfA = try await reader.balance(holder: a)
        XCTAssertEqual(balanceOfA, "10000000000")
        let decimals = try await reader.decimals()
        XCTAssertEqual(decimals, 7)
        let name = try await reader.name()
        XCTAssertEqual(name, "TEST:\(context.issuerId)")
        let symbol = try await reader.symbol()
        XCTAssertEqual(symbol, "TEST")

        // A transfers to B as the source account.
        let clientOfA = try SACClient.forAsset(asset: context.asset,
                                               sourceAccountKeyPair: context.a,
                                               network: network,
                                               rpcUrl: rpcUrl)
        let sent = try await clientOfA.transferAndSend(to: b, amount: try SACClient.toBaseUnits("100"))
        XCTAssertEqual(sent.status, GetTransactionResponse.STATUS_SUCCESS)
        let balanceOfBAfterSend = try await reader.balance(holder: b)
        XCTAssertEqual(balanceOfBAfterSend, "1000000000")
        let balanceOfAAfterSend = try await reader.balance(holder: a)
        XCTAssertEqual(balanceOfAAfterSend, "9000000000")

        // A transfers to a muxed account of B: B is credited, and the event carries the id.
        let muxedB = try SCAddressXDR(accountId: try MuxedAccount(accountId: context.bId, id: 4242).accountId)
        let muxedTransfer = try await clientOfA.transfer(from: a, to: muxedB, amount: "250000000")
        let muxedResponse = try await muxedTransfer.signAndSend()
        XCTAssertEqual(muxedResponse.status, GetTransactionResponse.STATUS_SUCCESS)
        let muxedEvent = try transferEvent(in: muxedResponse)
        let muxedTopics = topics(of: muxedEvent)
        XCTAssertGreaterThanOrEqual(muxedTopics.count, 3)
        if muxedTopics.count >= 3 {
            XCTAssertEqual(muxedTopics[2].address?.accountId, context.bId)
        }
        let muxedData = try eventDataMap(muxedEvent)
        XCTAssertEqual(muxedData["amount"]?.i128String, "250000000")
        XCTAssertEqual(muxedData["to_muxed_id"]?.u64, 4242)
        let balanceOfBAfterMuxed = try await reader.balance(holder: b)
        XCTAssertEqual(try wholeNumber(balanceOfBAfterMuxed), try wholeNumber(balanceOfBAfterSend) + 250_000_000)

        // The issuer is the source account, so A authorizes the transfer with an entry.
        let clientOfIssuer = try SACClient.forAsset(asset: context.asset,
                                                    sourceAccountKeyPair: context.issuer,
                                                    network: network,
                                                    rpcUrl: rpcUrl)
        let authorizedTransfer = try await clientOfIssuer.transfer(from: a, to: b, amount: try SACClient.toBaseUnits("10.5"))
        XCTAssertEqual(try authorizedTransfer.needsNonInvokerSigningBy(), [context.aId])
        try await authorizedTransfer.signAuthEntries(signerKeyPair: context.a)
        let authorizedResponse = try await authorizedTransfer.signAndSend()
        XCTAssertEqual(authorizedResponse.status, GetTransactionResponse.STATUS_SUCCESS)
        let balanceOfBAfterAuthorized = try await reader.balance(holder: b)
        XCTAssertEqual(try wholeNumber(balanceOfBAfterAuthorized), try wholeNumber(balanceOfBAfterMuxed) + 105_000_000)

        // The native asset's contract.
        let native = try XCTUnwrap(Asset(type: AssetType.ASSET_TYPE_NATIVE))
        let nativeReader = try SACClient.readOnlyForAsset(asset: native, network: network, rpcUrl: rpcUrl)
        if Self.testOn == "testnet" {
            XCTAssertEqual(nativeReader.contractId, Self.testnetNativeContractId)
        }
        let nativeBalanceOfA = try await nativeReader.balance(holder: a)
        XCTAssertFalse(nativeBalanceOfA.isEmpty)
        XCTAssertTrue(nativeBalanceOfA.utf8.allSatisfy { $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") },
                      "unexpected balance: \(nativeBalanceOfA)")
        XCTAssertNotEqual(nativeBalanceOfA, "0")
        let nativeDecimals = try await nativeReader.decimals()
        XCTAssertEqual(nativeDecimals, 7)
        let nativeName = try await nativeReader.name()
        XCTAssertEqual(nativeName, "native")
        let nativeSymbol = try await nativeReader.symbol()
        XCTAssertEqual(nativeSymbol, "native")
    }

    func testTransferToMuxedContract() async throws {
        guard try await protocolAtLeast(30, server: sorobanServer, rpcUrl: rpcUrl) else {
            throw XCTSkip("The network at \(rpcUrl) runs a protocol version below 30; muxed contract (W...) destinations need protocol 30")
        }

        let context = try await makeContext()
        let clientOfA = try SACClient.forAsset(asset: context.asset,
                                               sourceAccountKeyPair: context.a,
                                               network: network,
                                               rpcUrl: rpcUrl)
        let transfer = try await clientOfA.transfer(from: try SCAddressXDR(accountId: context.aId),
                                                    to: try SCAddressXDR(contractId: context.sacId, id: 7),
                                                    amount: "50000000")
        let response = try await transfer.signAndSend()
        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)

        let data = try eventDataMap(try transferEvent(in: response))
        XCTAssertEqual(data["to_muxed_id"]?.u64, 7)

        // The base contract is credited.
        let reader = try SACClient.readOnlyForAsset(asset: context.asset, network: network, rpcUrl: rpcUrl)
        let balanceOfContract = try await reader.balance(holder: try SCAddressXDR(contractId: context.sacId))
        XCTAssertEqual(balanceOfContract, "50000000")
    }

    func testProtocolGate() async throws {
        let host = "sac-protocol-gate.mock"
        let gateUrl = "https://\(host)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ServerMock.self]
        let session = URLSession(configuration: configuration)
        gateSession = session
        let rpc = MockedLatestLedgerRpc()
        let mock = RequestMock(host: host, path: "*", httpMethod: "POST") { _, request in
            return rpc.answer(request)
        }
        gateMock = mock
        ServerMock.add(mock: mock)
        let server = SorobanServer(endpoint: gateUrl, urlSession: session)

        rpc.setResult(#"{"id": "\#(String(repeating: "ab", count: 32))", "protocolVersion": 30, "sequence": 1000}"#)
        let atRequiredVersion = try await protocolAtLeast(30, server: server, rpcUrl: gateUrl)
        XCTAssertTrue(atRequiredVersion)

        rpc.setResult(#"{"id": "\#(String(repeating: "ab", count: 32))", "protocolVersion": 31, "sequence": 1000}"#)
        let aboveRequiredVersion = try await protocolAtLeast(30, server: server, rpcUrl: gateUrl)
        XCTAssertTrue(aboveRequiredVersion)

        rpc.setResult(#"{"id": "\#(String(repeating: "ab", count: 32))", "protocolVersion": 29, "sequence": 1000}"#)
        let belowRequiredVersion = try await protocolAtLeast(30, server: server, rpcUrl: gateUrl)
        XCTAssertFalse(belowRequiredVersion)

        // An answer without a protocol version is no answer about the protocol.
        rpc.setResult(#"{"id": "\#(String(repeating: "ab", count: 32))", "sequence": 1000}"#)
        do {
            _ = try await protocolAtLeast(30, server: server, rpcUrl: gateUrl)
            XCTFail("expected an error for an answer without protocolVersion")
        } catch let error as ProtocolVersionUnavailable {
            XCTAssertEqual(error.rpcUrl, gateUrl)
            XCTAssertTrue(error.description.hasPrefix("Could not read the protocol version from https://sac-protocol-gate.mock: "),
                          "unexpected message: \(error.description)")
            guard case .parsingResponseFailed = error.cause else {
                XCTFail("expected a parsing failure, got \(error.cause)")
                return
            }
        }

        rpc.setError(#"{"code": -32603, "message": "internal error"}"#)
        do {
            _ = try await protocolAtLeast(30, server: server, rpcUrl: gateUrl)
            XCTFail("expected an error for a JSON-RPC error answer")
        } catch let error as ProtocolVersionUnavailable {
            XCTAssertEqual(error.rpcUrl, gateUrl)
            XCTAssertTrue(error.description.hasPrefix("Could not read the protocol version from https://sac-protocol-gate.mock: "),
                          "unexpected message: \(error.description)")
            guard case .errorResponse(let rpcError) = error.cause else {
                XCTFail("expected a JSON-RPC error, got \(error.cause)")
                return
            }
            XCTAssertEqual(rpcError.code, -32603)
            XCTAssertEqual(rpcError.message, "internal error")
        }

        // Every call asked the mocked server once, and nothing else.
        XCTAssertEqual(rpc.requestedMethods, Array(repeating: "getLatestLedger", count: 5))
    }

    // MARK: - Protocol gate

    /// Whether the network behind `server` runs the protocol `version` or a later one.
    ///
    /// - Throws: `ProtocolVersionUnavailable` naming `rpcUrl` when the server does not report
    ///   its protocol version, so a test fails on it: an unanswered question is no reason to skip.
    private func protocolAtLeast(_ version: Int, server: SorobanServer, rpcUrl: String) async throws -> Bool {
        let response = await server.getLatestLedger()
        switch response {
        case .success(let ledger):
            return ledger.protocolVersion >= version
        case .failure(let error):
            throw ProtocolVersionUnavailable(rpcUrl: rpcUrl, cause: error)
        }
    }

    // MARK: - Context

    /// A fresh issued asset with its deployed Stellar Asset Contract and two holders.
    private struct Context {
        let issuer: KeyPair
        let a: KeyPair
        let b: KeyPair
        let asset: ChangeTrustAsset
        let sacId: String

        var issuerId: String { issuer.accountId }
        var aId: String { a.accountId }
        var bId: String { b.accountId }
    }

    /// Funds a random issuer and two random accounts A and B, opens the trustlines of A and
    /// B for the issuer's asset `TEST`, deploys the Stellar Asset Contract of the asset, and
    /// pays 1000 TEST to A.
    private func makeContext() async throws -> Context {
        let issuer = try KeyPair.generateRandomKeyPair()
        let a = try KeyPair.generateRandomKeyPair()
        let b = try KeyPair.generateRandomKeyPair()
        for keyPair in [issuer, a, b] {
            try await fundTestAccountAndAwaitVisibility(accountId: keyPair.accountId,
                                                        horizon: sdk,
                                                        rpc: sorobanServer,
                                                        useFuturenet: Self.testOn != "testnet")
        }
        let asset = try XCTUnwrap(ChangeTrustAsset(canonicalForm: "TEST:" + issuer.accountId))
        let sacId = try asset.contractId(network: network)

        // Trustlines of A and B, in one transaction of the issuer.
        let trustlinesLedger = try await submitClassicTransaction(
            source: issuer,
            operations: [
                ChangeTrustOperation(sourceAccountId: a.accountId, asset: asset),
                ChangeTrustOperation(sourceAccountId: b.accountId, asset: asset),
            ],
            signers: [issuer, a, b])
        try await awaitLedger(trustlinesLedger)

        // The deployment creates the contract at the derived id.
        let deployOptions = AssembledTransactionOptions(
            clientOptions: ClientOptions(sourceAccountKeyPair: issuer, contractId: sacId, network: network, rpcUrl: rpcUrl),
            methodOptions: MethodOptions(),
            method: "deploy")
        let deployment = try await AssembledTransaction.buildWithOp(
            operation: try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: asset),
            options: deployOptions)
        let deployed = try await deployment.signAndSend()
        XCTAssertEqual(deployed.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertEqual(try XCTUnwrap(deployed.createdContractId).encodeContractIdHex(), sacId)
        try await awaitLedger(try XCTUnwrap(deployed.ledger))

        // The issuer pays 1000 TEST to A.
        let paymentLedger = try await submitClassicTransaction(
            source: issuer,
            operations: [
                try PaymentOperation(sourceAccountId: issuer.accountId, destinationAccountId: a.accountId, asset: asset, amount: 1000),
            ],
            signers: [issuer])
        try await awaitLedger(paymentLedger)

        return Context(issuer: issuer, a: a, b: b, asset: asset, sacId: sacId)
    }

    /// Submits a classic transaction of `source` with `operations`, signed by `signers`,
    /// through Horizon.
    ///
    /// - Returns: The sequence number of the ledger that holds the transaction.
    /// - Throws: `SACIntegrationTestError` when the account does not load or Horizon does not
    ///   accept the transaction.
    private func submitClassicTransaction(source: KeyPair, operations: [stellarsdk.Operation], signers: [KeyPair]) async throws -> Int {
        let accountResponse = await sdk.accounts.getAccountDetails(accountId: source.accountId)
        guard case .success(let account) = accountResponse else {
            throw SACIntegrationTestError(description: "Could not load the account \(source.accountId) from Horizon: \(accountResponse)")
        }
        let transaction = try Transaction(sourceAccount: account, operations: operations, memo: Memo.none)
        for signer in signers {
            try transaction.sign(keyPair: signer, network: network)
        }
        let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
        guard case .success(let details) = submitResponse else {
            throw SACIntegrationTestError(description: "Horizon did not accept the transaction of \(source.accountId): \(submitResponse)")
        }
        return details.ledger
    }

    /// Waits until the RPC server and Horizon both serve the ledger `sequence`, so the next
    /// read of either one sees the transactions of that ledger, such as the sequence number
    /// of an account that sent one through the other.
    ///
    /// - Throws: `SACIntegrationTestError` when one of them does not serve the ledger within
    ///   60 seconds.
    private func awaitLedger(_ sequence: Int) async throws {
        let deadline = Date().addingTimeInterval(60)
        while true {
            var rpcServesLedger = false
            let latestLedger = await sorobanServer.getLatestLedger()
            if case .success(let ledger) = latestLedger {
                rpcServesLedger = Int(ledger.sequence) >= sequence
            }
            var horizonServesLedger = false
            let ledgerDetails = await sdk.ledgers.getLedger(sequenceNumber: String(sequence))
            if case .success = ledgerDetails {
                horizonServesLedger = true
            }
            if rpcServesLedger && horizonServesLedger {
                return
            }
            if Date() > deadline {
                throw SACIntegrationTestError(description: "Ledger \(sequence) is not served after 60 seconds (rpc: \(rpcServesLedger), horizon: \(horizonServesLedger))")
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    // MARK: - Values

    /// The topics of a contract event.
    private func topics(of event: ContractEventXDR) -> [SCValXDR] {
        switch event.body {
        case .v0(let body):
            return body.topics
        }
    }

    /// The number a balance in base units spells.
    private func wholeNumber(_ baseUnits: String) throws -> Int64 {
        return try XCTUnwrap(Int64(baseUnits), "not a whole number: \(baseUnits)")
    }
}

/// The error of the protocol check when the RPC server at `rpcUrl` does not report its
/// protocol version.
private struct ProtocolVersionUnavailable: Error, CustomStringConvertible {
    let rpcUrl: String
    let cause: SorobanRpcRequestError

    var description: String {
        return "Could not read the protocol version from \(rpcUrl): \(cause)"
    }
}

/// A step of the test setup that did not complete.
private struct SACIntegrationTestError: Error, CustomStringConvertible {
    let description: String
}

/// The answers of a mocked RPC server to `getLatestLedger`, and the methods it was asked for.
///
/// It answers any other method with a JSON-RPC error. The handler of a `RequestMock` runs on
/// a URL loading thread, so a lock guards the state.
private final class MockedLatestLedgerRpc: @unchecked Sendable {
    private let lock = NSLock()
    private var payload = #""error": {"code": -32601, "message": "no answer set"}"#
    private var methods: [String] = []

    /// The methods of the requests received, in order; a request without one counts as "".
    var requestedMethods: [String] {
        lock.lock()
        defer { lock.unlock() }
        return methods
    }

    /// Answers the following requests with the JSON object `result` as the result.
    func setResult(_ result: String) {
        setPayload("\"result\": \(result)")
    }

    /// Answers the following requests with the JSON object `error` as a JSON-RPC error.
    func setError(_ error: String) {
        setPayload("\"error\": \(error)")
    }

    private func setPayload(_ newPayload: String) {
        lock.lock()
        defer { lock.unlock() }
        payload = newPayload
    }

    /// Records the method of `request` and returns the JSON-RPC answer to it.
    func answer(_ request: URLRequest) -> String {
        let body = request.httpBody ?? request.httpBodyStream?.readfully() ?? Data()
        let json = (try? JSONSerialization.jsonObject(with: body, options: [])) as? [String: Any]
        let method = json?["method"] as? String ?? ""
        lock.lock()
        defer { lock.unlock() }
        methods.append(method)
        guard method == "getLatestLedger" else {
            return #"{"jsonrpc": "2.0", "id": 1, "error": {"code": -32601, "message": "unexpected method"}}"#
        }
        return "{\"jsonrpc\": \"2.0\", \"id\": 1, \(payload)}"
    }
}
