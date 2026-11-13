//
//  OZCheckAuthPolicyIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Testnet integration test for a policy that rejects inside `__check_auth`: the signature
/// stage passes and the policy fails the enforcing re-simulation.
///
/// The account has two delegated signers, G1 (funded on testnet) and G2 (random), and a
/// SimpleThreshold policy of 2 on its Default context rule. A context-rule update signed by
/// G1 alone passes the recording simulation; in the enforcing re-simulation the account
/// authenticates G1 and the policy counts one signer against the threshold of 2, so it fails
/// with `SimpleThresholdError::NotAllowed` (3202). The host error then reads
/// `Error(Auth, InvalidAction)` and the code appears only in the diagnostic events.
///
/// The kit runs on a session whose pass-through `URLProtocol` records the RPC request and
/// response bodies, so the test compares the thrown failure with the raw response. When the
/// environment variable `STELLAR_SDK_FIXTURE_DIR` names a directory, the failing response and
/// its request are written there unchanged. The RPC traffic carries public keys and
/// signatures only.
final class OZCheckAuthPolicyIntegrationTests: XCTestCase {

    // MARK: - Configuration

    let rpcUrl = "https://soroban-testnet.stellar.org"
    let network = Network.testnet

    /// Smart account contract WASM installed on testnet.
    let accountWasmHash = "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28"

    /// WebAuthn verifier contract deployed on testnet; the kit configuration requires it.
    let webauthnVerifier = "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"

    /// SimpleThreshold policy contract deployed on testnet.
    let thresholdPolicy = "CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC"

    override func setUp() {
        super.setUp()
        SimulationCaptureURLProtocol.reset()
    }

    override func tearDown() {
        SimulationCaptureURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Tests

    func testThresholdPolicyRejectionInCheckAuthReportsThePolicyError() async throws {
        let rpc = SorobanServer(endpoint: rpcUrl)
        let deployer = try KeyPair.generateRandomKeyPair()
        let signer1 = try KeyPair.generateRandomKeyPair()
        let signer2 = try KeyPair.generateRandomKeyPair()
        try await fundTestAccountAndAwaitVisibility(accountId: deployer.accountId, rpc: rpc)
        try await fundTestAccountAndAwaitVisibility(accountId: signer1.accountId, rpc: rpc)

        let contractId = try await deployAccount(deployer: deployer, signers: [signer1, signer2])

        let kit = try capturingKit(deployer: deployer)
        var thrown: Error?
        do {
            _ = try await kit.walletOperations.connectToContract(contractId: contractId)
            _ = try await kit.externalSigners.addFromSecret(secretKey: try XCTUnwrap(signer1.secretSeed))
            _ = try await kit.contextRuleManager.updateName(
                id: 0,
                name: "check-auth-threshold",
                selectedSigners: [.wallet(accountId: signer1.accountId)]
            )
        } catch {
            thrown = error
        }
        await kit.close()

        // The raw failing exchange is written before any assertion can end the test.
        let exchanges = SimulationCaptureURLProtocol.recorded
        let failedSimulations = exchanges.filter {
            rpcMethod(of: $0.requestBody) == "simulateTransaction" && rpcResult(of: $0.responseBody)?["error"] != nil
        }
        if let raw = failedSimulations.first {
            XCTAssertNoThrow(try writeFixture(raw))
        }

        let failure = try XCTUnwrap(
            thrown as? SmartAccountTransactionException.SimulationFailed,
            "the enforcing re-simulation must fail, got: \(String(describing: thrown))"
        )
        let suffix = " (contract error in diagnostic events: Error(Contract, #3202), contract \(thresholdPolicy))"
        XCTAssertTrue(
            failure.message.hasPrefix("Transaction simulation failed: Re-simulation error: HostError: Error(Auth, InvalidAction)"),
            failure.message
        )
        XCTAssertTrue(failure.message.hasSuffix(suffix), failure.message)
        XCTAssertEqual(failure.reportedContractError,
                       ReportedContractError(code: 3202, provenance: .diagnosticEvents, contractId: thresholdPolicy))
        let decoded = try XCTUnwrap(OZContractErrorCodes.decodeFromSimulationFailure(failure))
        XCTAssertEqual(decoded.contract, "SimpleThresholdError")
        XCTAssertEqual(decoded.name, "NotAllowed")
        XCTAssertFalse(failure.diagnosticEventsXdr.isEmpty)
        XCTAssertEqual(OZContractErrorCodes.decodeFromMessage(failure.message)?.code, 3202)

        XCTAssertEqual(failedSimulations.count, 1)
        let captured = try XCTUnwrap(failedSimulations.first)
        let result = try XCTUnwrap(rpcResult(of: captured.responseBody))
        let errorText = try XCTUnwrap(result["error"] as? String)
        XCTAssertTrue(errorText.hasPrefix("HostError: Error(Auth, InvalidAction)"), errorText)
        let response = try JSONDecoder().decode(
            SimulateTransactionResponse.self,
            from: try JSONSerialization.data(withJSONObject: result)
        )
        XCTAssertEqual(response.reportedContractError(), failure.reportedContractError)
        XCTAssertEqual(response.events ?? [], failure.diagnosticEventsXdr)
        XCTAssertEqual(exchanges.filter { rpcMethod(of: $0.requestBody) == "sendTransaction" }.count, 0)
    }

    // MARK: - Helpers

    /// Deploys a smart account whose Default context rule holds `signers` as delegated signers
    /// and the threshold policy with a threshold of 2.
    private func deployAccount(deployer: KeyPair, signers: [KeyPair]) async throws -> String {
        let signersScVal = SCValXDR.vec(try signers.map { try OZDelegatedSigner(address: $0.accountId).toScVal() })
        let policiesScVal = try OZPolicyManager.policiesToScVal([
            thresholdPolicy: try OZPolicyInstallParams.simpleThreshold(threshold: 2).toScVal()
        ])
        let client = try await SorobanClient.deploy(deployRequest: DeployRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: deployer,
            wasmHash: accountWasmHash,
            constructorArgs: [signersScVal, policiesScVal],
            enableServerLogging: false
        ))
        return client.contractId
    }

    /// Builds the kit with the collaborators `OZSmartAccountKit.create(config:)` builds, on a
    /// session that records the RPC traffic.
    private func capturingKit(deployer: KeyPair) throws -> OZSmartAccountKit {
        let config = try OZSmartAccountConfig(
            rpcUrl: rpcUrl,
            networkPassphrase: network.passphrase,
            accountWasmHash: accountWasmHash,
            webauthnVerifierAddress: webauthnVerifier,
            deployerKeypair: deployer
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SimulationCaptureURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let indexerClient = config.effectiveIndexerUrl().flatMap { url in
            try? OZIndexerClient(indexerUrl: url, timeoutMs: OZConstants.defaultIndexerTimeoutMs)
        }
        return OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: SorobanServer(endpoint: config.rpcUrl, urlSession: session),
            relayerClient: nil,
            indexerClient: indexerClient,
            ownedUrlSession: session
        )
    }

    private func rpcMethod(of body: Data) -> String? {
        let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        return object?["method"] as? String
    }

    private func rpcResult(of body: Data) -> [String: Any]? {
        let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        return object?["result"] as? [String: Any]
    }

    /// Writes the captured response and request unchanged to `STELLAR_SDK_FIXTURE_DIR` when it
    /// is set, and prints only the two paths.
    private func writeFixture(_ exchange: SimulationCaptureURLProtocol.Exchange) throws {
        guard let directory = ProcessInfo.processInfo.environment["STELLAR_SDK_FIXTURE_DIR"],
              !directory.isEmpty else {
            return
        }
        let base = URL(fileURLWithPath: directory, isDirectory: true)
        let responseUrl = base.appendingPathComponent("case-d-checkauth-threshold-response.json")
        let requestUrl = base.appendingPathComponent("case-d-checkauth-threshold-request.json")
        try exchange.responseBody.write(to: responseUrl)
        try exchange.requestBody.write(to: requestUrl)
        print("fixture written: \(responseUrl.path)")
        print("fixture written: \(requestUrl.path)")
    }
}

/// Pass-through `URLProtocol` that forwards each request unchanged through its own session,
/// hands the response back unchanged, and records the request and response bodies.
final class SimulationCaptureURLProtocol: URLProtocol, @unchecked Sendable {

    /// One recorded request and its response body.
    struct Exchange: Sendable {
        let requestBody: Data
        let responseBody: Data
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var exchanges: [Exchange] = []
    private static let forwardingSession = URLSession(configuration: .ephemeral)

    private let taskLock = NSLock()
    private var forwardingTask: URLSessionDataTask?

    /// The recorded exchanges, in completion order.
    static var recorded: [Exchange] {
        lock.lock(); defer { lock.unlock() }
        return exchanges
    }

    /// Removes every recorded exchange.
    static func reset() {
        lock.lock(); defer { lock.unlock() }
        exchanges.removeAll()
    }

    private static func record(_ exchange: Exchange) {
        lock.lock(); defer { lock.unlock() }
        exchanges.append(exchange)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(SimulationCaptureURLProtocol.readAll) ?? Data()
        var forwarded = request
        forwarded.httpBody = body
        let dataTask = SimulationCaptureURLProtocol.forwardingSession.dataTask(with: forwarded) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            let responseBody = data ?? Data()
            SimulationCaptureURLProtocol.record(Exchange(requestBody: body, responseBody: responseBody))
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            self.client?.urlProtocol(self, didLoad: responseBody)
            self.client?.urlProtocolDidFinishLoading(self)
        }
        taskLock.lock()
        forwardingTask = dataTask
        taskLock.unlock()
        dataTask.resume()
    }

    override func stopLoading() {
        taskLock.lock()
        let dataTask = forwardingTask
        taskLock.unlock()
        dataTask?.cancel()
    }

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
