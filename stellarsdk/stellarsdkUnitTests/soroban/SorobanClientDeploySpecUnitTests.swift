//
//  SorobanClientDeploySpecUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 11.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests for SorobanClient.deploy() contract-spec loading.
///
/// The spec of the returned client is loaded from the wasm code entry before
/// the deploy transaction is submitted, because the code entry is already
/// settled while the freshly created contract instance may not be visible to
/// the RPC yet. Loading by contract id remains the fallback when the code
/// entry cannot be read or parsed up front.
///
/// All RPC calls are served by ServerMock; no network access.
final class SorobanClientDeploySpecUnitTests: XCTestCase {

    var mockRpcUrl: String!
    var mockContractId: String!
    var keyPair: KeyPair!
    var wasmHashBytes: Data!
    var tokenWasm: Data!

    /// Records every served request as 'code', 'contractData', 'account',
    /// 'simulate', 'send' or 'getTx'.
    private final class RequestLog: @unchecked Sendable {
        var entries: [String] = []
        var codeRequests = 0
    }
    private var requestLog = RequestLog()

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        mockRpcUrl = "https://soroban-testnet.stellar.org"
        mockContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        keyPair = try! KeyPair.generateRandomKeyPair()
        wasmHashBytes = Data(repeating: 0, count: 32)
        requestLog = RequestLog()

        guard let path = Bundle.module.path(forResource: "soroban_token_contract", ofType: "wasm"),
              let wasm = FileManager.default.contents(atPath: path) else {
            XCTFail("Failed to load soroban_token_contract.wasm")
            return
        }
        tokenWasm = wasm
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
        super.tearDown()
    }

    // MARK: - Mock setup

    /// Serves the full deploy flow. The wasm code entry answer per request is
    /// taken from [codeEntryAnswers] in order (its last element repeats), so
    /// tests can serve a missing (nil) or unparseable entry to the pre-deploy
    /// load and the real one to the fallback.
    private func setupDeployFlowMock(codeEntryAnswers: [Data?]) {
        let log = requestLog
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
                log.entries.append("simulate")
                return self.simulateResponseJson()
            }
            if bodyString.contains("sendTransaction") {
                log.entries.append("send")
                return """
                {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "result": {
                        "status": "PENDING",
                        "hash": "a1b2c3d4e5f6",
                        "latestLedger": 12345,
                        "latestLedgerCloseTime": "1234567890"
                    }
                }
                """
            }
            if bodyString.contains("getTransaction") {
                log.entries.append("getTx")
                return self.deploySuccessResponseJson()
            }
            if bodyString.contains("getLedgerEntries") {
                // Dispatch on the requested ledger key type: CONTRACT_CODE
                // encodes with discriminant 7 ("AAAABw"), CONTRACT_DATA with
                // 6 ("AAAABg"); anything else is the account fetch.
                if bodyString.contains("AAAABw") {
                    log.entries.append("code")
                    let answer = log.codeRequests < codeEntryAnswers.count
                        ? codeEntryAnswers[log.codeRequests]
                        : codeEntryAnswers.last!
                    log.codeRequests += 1
                    guard let code = answer else {
                        return """
                        {
                            "jsonrpc": "2.0",
                            "id": 1,
                            "result": {
                                "entries": [],
                                "latestLedger": 1000000
                            }
                        }
                        """
                    }
                    return self.ledgerEntryResponseJson(entryData: self.contractCodeEntry(code: code))
                }
                if bodyString.contains("AAAABg") {
                    log.entries.append("contractData")
                    return self.ledgerEntryResponseJson(entryData: self.contractInstanceEntry())
                }
                log.entries.append("account")
                return self.ledgerEntryResponseJson(entryData: self.accountEntry())
            }
            return nil
        }
        ServerMock.add(mock: mock)
    }

    private func accountEntry() -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.account(AccountEntryXDR(
            accountID: keyPair.publicKey,
            balance: 100_000_000_0,
            sequenceNumber: 12345,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "",
            thresholds: WrappedData4(Data([1, 0, 0, 0])),
            signers: [],
            ext: .void
        ))
    }

    private func contractCodeEntry(code: Data) -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.contractCode(ContractCodeEntryXDR(
            ext: .void,
            hash: WrappedData32(wasmHashBytes),
            code: code
        ))
    }

    private func contractInstanceEntry() -> LedgerEntryDataXDR {
        let instance = SCContractInstanceXDR(
            executable: .wasm(WrappedData32(wasmHashBytes)),
            storage: nil
        )
        return LedgerEntryDataXDR.contractData(ContractDataEntryXDR(
            ext: .void,
            contract: try! SCAddressXDR(contractId: mockContractId),
            key: SCValXDR.ledgerKeyContractInstance,
            durability: .persistent,
            val: SCValXDR.contractInstance(instance)
        ))
    }

    private func ledgerEntryResponseJson(entryData: LedgerEntryDataXDR) -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "entries": [
                    {
                        "key": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                        "xdr": "\(entryData.xdrEncoded!)",
                        "lastModifiedLedgerSeq": 999000
                    }
                ],
                "latestLedger": 1000000
            }
        }
        """
    }

    private func simulateResponseJson() -> String {
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
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "transactionData": "\(transactionData.xdrEncoded!)",
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

    /// A SUCCESS getTransaction result whose meta returns the created
    /// contract address, as required by GetTransactionResponse.createdContractId.
    private func deploySuccessResponseJson() -> String {
        let createdAddress = try! SCAddressXDR(contractId: mockContractId)
        let meta = TransactionMetaXDR.transactionMetaV3(TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: SorobanTransactionMetaXDR(
                ext: .void,
                events: [],
                returnValue: SCValXDR.address(createdAddress),
                diagnosticEvents: [])))
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "SUCCESS",
                "latestLedger": 12345,
                "latestLedgerCloseTime": "1234567890",
                "oldestLedger": 100,
                "resultXdr": "AAAAAwAAAAE=",
                "resultMetaXdr": "\(meta.xdrEncoded!)"
            }
        }
        """
    }

    private func deployRequest() -> DeployRequest {
        return DeployRequest(
            rpcUrl: mockRpcUrl,
            network: Network.testnet,
            sourceAccountKeyPair: keyPair,
            wasmHash: wasmHashBytes.base16EncodedString(),
            enableServerLogging: false
        )
    }

    // MARK: - Tests

    func testDeployLoadsSpecFromWasmCodeEntryBeforeSubmitting() async throws {
        setupDeployFlowMock(codeEntryAnswers: [tokenWasm])

        let client = try await SorobanClient.deploy(deployRequest: deployRequest())

        XCTAssertEqual(client.contractId, mockContractId)
        XCTAssertTrue(client.methodNames.contains("transfer"))
        // The spec came from the code entry requested before submission; the
        // contract instance is never read.
        XCTAssertFalse(requestLog.entries.contains("contractData"))
        guard let codeIndex = requestLog.entries.firstIndex(of: "code"),
              let sendIndex = requestLog.entries.firstIndex(of: "send") else {
            XCTFail("Expected both a code request and a send request, got: \(requestLog.entries)")
            return
        }
        XCTAssertLessThan(codeIndex, sendIndex)
    }

    func testDeployFallsBackWhenCodeEntryMissing() async throws {
        setupDeployFlowMock(codeEntryAnswers: [nil, tokenWasm])

        let client = try await SorobanClient.deploy(deployRequest: deployRequest())

        XCTAssertEqual(client.contractId, mockContractId)
        XCTAssertTrue(client.methodNames.contains("transfer"))
        XCTAssertTrue(requestLog.entries.contains("contractData"))
    }

    func testDeployFallsBackWhenCodeHasNoParseableSpec() async throws {
        setupDeployFlowMock(codeEntryAnswers: [Data([1, 2, 3, 4]), tokenWasm])

        let client = try await SorobanClient.deploy(deployRequest: deployRequest())

        XCTAssertEqual(client.contractId, mockContractId)
        XCTAssertTrue(client.methodNames.contains("transfer"))
        XCTAssertTrue(requestLog.entries.contains("contractData"))
    }
}
