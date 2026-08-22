//
//  SorobanServerExternalRefUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 18.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests for CAP-85 external reference resolution in SorobanServer.
///
/// All RPC calls are served by ServerMock; no network access. The mock answers
/// only requests carrying the exact base64 ledger key a test expects, so a key
/// built with the wrong type, owner, tag or durability goes unanswered and the
/// request log exposes it.
final class SorobanServerExternalRefUnitTests: XCTestCase {

    var mockRpcUrl: String!
    var server: SorobanServer!
    var mockContractId: String!
    var ownerContractIdHex: String!
    var executableTag: String!
    var wasmHashBytes: Data!
    var keyPair: KeyPair!
    var tokenWasm: Data!

    /// Records the base64 ledger key of every served getLedgerEntries request,
    /// or "unmatched" for a request no expected key matched.
    private final class RequestLog: @unchecked Sendable {
        var entries: [String] = []
    }
    private var requestLog = RequestLog()

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        mockRpcUrl = "https://soroban-testnet.stellar.org"
        mockContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        ownerContractIdHex = "c0decafec0decafec0decafec0decafec0decafec0decafec0decafec0decafe"
        executableTag = "token-v1"
        wasmHashBytes = Data(repeating: 3, count: 32)
        keyPair = try! KeyPair.generateRandomKeyPair()
        server = SorobanServer(endpoint: mockRpcUrl)
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

    // MARK: - Fixtures

    private func ownerAddress() -> SCAddressXDR {
        return try! SCAddressXDR(contractId: ownerContractIdHex)
    }

    private func externalRef(tag: String? = nil, owner: SCAddressXDR? = nil) -> ContractExecutableExternalRefXDR {
        return ContractExecutableExternalRefXDR(executableOwner: owner ?? ownerAddress(),
                                                tag: tag ?? executableTag)
    }

    private func externalRef(tag: Data, owner: SCAddressXDR? = nil) -> ContractExecutableExternalRefXDR {
        return ContractExecutableExternalRefXDR(executableOwner: owner ?? ownerAddress(),
                                                tag: tag)
    }

    private func instanceKeyB64() -> String {
        let key = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: try! SCAddressXDR(contractId: mockContractId),
            key: SCValXDR.ledgerKeyContractInstance,
            durability: .persistent))
        return key.xdrEncoded!
    }

    private func tagKeyB64(tag: Data? = nil) -> String {
        let key = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: ownerAddress(),
            key: SCValXDR.executableTag(tag ?? Data(executableTag.utf8)),
            durability: .persistent))
        return key.xdrEncoded!
    }

    private func codeKeyB64() -> String {
        let key = LedgerKeyXDR.contractCode(try! LedgerKeyContractCodeXDR(wasmId: wasmHashBytes.base16EncodedString()))
        return key.xdrEncoded!
    }

    private func instanceEntry(executable: ContractExecutableXDR) -> LedgerEntryDataXDR {
        let instance = SCContractInstanceXDR(executable: executable, storage: nil)
        return LedgerEntryDataXDR.contractData(ContractDataEntryXDR(
            ext: .void,
            contract: try! SCAddressXDR(contractId: mockContractId),
            key: SCValXDR.ledgerKeyContractInstance,
            durability: .persistent,
            val: SCValXDR.contractInstance(instance)))
    }

    private func tagEntry(val: SCValXDR, tag: Data? = nil) -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.contractData(ContractDataEntryXDR(
            ext: .void,
            contract: ownerAddress(),
            key: SCValXDR.executableTag(tag ?? Data(executableTag.utf8)),
            durability: .persistent,
            val: val))
    }

    private func codeEntry(code: Data) -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.contractCode(ContractCodeEntryXDR(
            ext: .void,
            hash: WrappedData32(wasmHashBytes),
            code: code))
    }

    // MARK: - Mock setup

    /// Serves getLedgerEntries requests from [answers]: the response for a
    /// request is the entry stored under the exact base64 ledger key its body
    /// carries, or an empty entry list when the stored value is nil. Requests
    /// carrying a key that is not in [answers] are logged as "unmatched" and
    /// answered with an empty entry list.
    private func setupMock(answers: [String: LedgerEntryDataXDR?]) {
        let log = requestLog
        let mock = RequestMock(
            host: "soroban-testnet.stellar.org",
            path: "*",
            httpMethod: "POST"
        ) { mock, request in
            var body = request.httpBody
            if body == nil, let stream = request.httpBodyStream {
                body = stream.readfully()
            }
            guard let bodyData = body,
                  let rawBody = String(data: bodyData, encoding: .utf8),
                  rawBody.contains("getLedgerEntries") else {
                return nil
            }
            // JSON serialization escapes "/" in the base64 keys as "\/".
            let bodyString = rawBody.replacingOccurrences(of: "\\/", with: "/")
            mock.statusCode = 200
            for (keyB64, entry) in answers where bodyString.contains(keyB64) {
                log.entries.append(keyB64)
                guard let entry = entry else {
                    return self.emptyEntriesJson()
                }
                return self.ledgerEntryResponseJson(entryData: entry)
            }
            log.entries.append("unmatched")
            return self.emptyEntriesJson()
        }
        ServerMock.add(mock: mock)
    }

    private func emptyEntriesJson() -> String {
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

    private func resolverFailureMessage(_ result: GetExternalRefWasmHashResponseEnum) -> String? {
        if case .failure(let error) = result,
           case SorobanRpcRequestError.requestFailed(let message) = error {
            return message
        }
        return nil
    }

    private func codeFailureMessage(_ result: GetContractCodeResponseEnum) -> String? {
        if case .failure(let error) = result,
           case SorobanRpcRequestError.requestFailed(let message) = error {
            return message
        }
        return nil
    }

    // MARK: - Tests

    func testWasmArmStillLoadsCode() async throws {
        let wasm = Data([0, 97, 115, 109])
        setupMock(answers: [
            instanceKeyB64(): instanceEntry(executable: .wasm(WrappedData32(wasmHashBytes))),
            codeKeyB64(): codeEntry(code: wasm),
        ])

        let result = await server.getContractCodeForContractId(contractId: mockContractId)

        guard case .success(let response) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        XCTAssertEqual(response.code, wasm)
        XCTAssertEqual(requestLog.entries, [instanceKeyB64(), codeKeyB64()])
    }

    func testExternalRefResolvesThroughOwnerTagEntry() async throws {
        let wasm = Data([0, 97, 115, 109, 1])
        setupMock(answers: [
            instanceKeyB64(): instanceEntry(executable: .externalRef(externalRef())),
            tagKeyB64(): tagEntry(val: SCValXDR.bytes(wasmHashBytes)),
            codeKeyB64(): codeEntry(code: wasm),
        ])

        let result = await server.getContractCodeForContractId(contractId: mockContractId)

        guard case .success(let response) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        XCTAssertEqual(response.code, wasm)
        // The request sequence pins the resolution: the tag key carries the
        // executable tag on the owner at persistent durability, and the code
        // key carries the hash the tag entry held.
        XCTAssertEqual(requestLog.entries, [instanceKeyB64(), tagKeyB64(), codeKeyB64()])
    }

    func testResolverReturnsTheHashTheTagEntryHolds() async throws {
        setupMock(answers: [tagKeyB64(): tagEntry(val: SCValXDR.bytes(wasmHashBytes))])

        let result = await server.getExternalRefWasmHash(ref: externalRef())

        guard case .success(let hash) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        XCTAssertEqual(hash, wasmHashBytes)
    }

    func testMissingTagEntryFails() async throws {
        setupMock(answers: [
            instanceKeyB64(): instanceEntry(executable: .externalRef(externalRef())),
            tagKeyB64(): nil,
        ])

        let direct = await server.getExternalRefWasmHash(ref: externalRef())
        guard let directMessage = resolverFailureMessage(direct) else {
            XCTFail("Expected requestFailed, got \(direct)")
            return
        }
        XCTAssertTrue(directMessage.contains("no executable tag entry found on owner contract"),
                      "unexpected message: \(directMessage)")
        // A text tag renders in the message as its quoted escaped form.
        XCTAssertTrue(directMessage.contains(#""token-v1""#), "unexpected message: \(directMessage)")

        let viaLoader = await server.getContractCodeForContractId(contractId: mockContractId)
        guard let loaderMessage = codeFailureMessage(viaLoader) else {
            XCTFail("Expected requestFailed, got \(viaLoader)")
            return
        }
        XCTAssertEqual(loaderMessage, directMessage)
        XCTAssertEqual(requestLog.entries, [tagKeyB64(), instanceKeyB64(), tagKeyB64()])
    }

    func testBinaryTagResolvesThroughTheLedgerKeyOfTheExactBytes() async throws {
        let binaryTag = Data([0xC0, 0x00, 0xFF, 0xFE])
        setupMock(answers: [
            tagKeyB64(tag: binaryTag): tagEntry(val: SCValXDR.bytes(wasmHashBytes), tag: binaryTag),
        ])

        let result = await server.getExternalRefWasmHash(ref: externalRef(tag: binaryTag))

        guard case .success(let hash) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        XCTAssertEqual(hash, wasmHashBytes)
        // The mock answers only the exact base64 ledger key, so the log pins
        // that the request carried the persistent executable-tag key built
        // from the exact tag bytes.
        XCTAssertEqual(requestLog.entries, [tagKeyB64(tag: binaryTag)])
    }

    func testMissingBinaryTagEntryFailsNamingTheEscapedTag() async throws {
        let binaryTag = Data([0xC0, 0x00, 0xFF, 0xFE])
        setupMock(answers: [tagKeyB64(tag: binaryTag): nil])

        let result = await server.getExternalRefWasmHash(ref: externalRef(tag: binaryTag))

        guard let message = resolverFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("no executable tag entry found on owner contract"),
                      "unexpected message: \(message)")
        // A tag that is not printable text renders as \xNN escapes inside quotes.
        XCTAssertTrue(message.contains(#""\xc0\x00\xff\xfe""#), "unexpected message: \(message)")
    }

    func testMissingInstanceEntryFails() async throws {
        setupMock(answers: [instanceKeyB64(): nil])

        let result = await server.getContractCodeForContractId(contractId: mockContractId)

        guard let message = codeFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("no contract instance entry found for contract id"),
                      "unexpected message: \(message)")
        XCTAssertTrue(message.contains(mockContractId), "unexpected message: \(message)")
        XCTAssertEqual(requestLog.entries, [instanceKeyB64()])
    }

    func testTagEntryWithNonBytesValueFails() async throws {
        setupMock(answers: [tagKeyB64(): tagEntry(val: SCValXDR.symbol("not_a_hash"))])

        let result = await server.getExternalRefWasmHash(ref: externalRef())

        guard let message = resolverFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("does not hold a 32-byte wasm hash"),
                      "unexpected message: \(message)")
    }

    func testTagEntryWithWrongLengthBytesFails() async throws {
        for length in [31, 33] {
            ServerMock.removeAll()
            setupMock(answers: [tagKeyB64(): tagEntry(val: SCValXDR.bytes(Data(repeating: 1, count: length)))])

            let result = await server.getExternalRefWasmHash(ref: externalRef())

            guard let message = resolverFailureMessage(result) else {
                XCTFail("Expected requestFailed for length \(length), got \(result)")
                return
            }
            XCTAssertTrue(message.contains("does not hold a 32-byte wasm hash"),
                          "unexpected message for length \(length): \(message)")
        }
    }

    func testNonContractOwnerFailsWithoutRequest() async throws {
        setupMock(answers: [:])
        let accountOwner = try SCAddressXDR(accountId: keyPair.accountId)

        let result = await server.getExternalRefWasmHash(ref: externalRef(owner: accountOwner))

        guard let message = resolverFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("is not a contract address"),
                      "unexpected message: \(message)")
        XCTAssertTrue(message.contains(keyPair.accountId),
                      "message does not name the owner: \(message)")
        XCTAssertEqual(requestLog.entries, [])
    }

    func testLiquidityPoolOwnerFailsWithoutRequest() async throws {
        setupMock(answers: [:])
        let poolOwner = try SCAddressXDR(liquidityPoolId: ownerContractIdHex)

        let result = await server.getExternalRefWasmHash(ref: externalRef(owner: poolOwner))

        guard let message = resolverFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("is not a contract address"),
                      "unexpected message: \(message)")
        XCTAssertTrue(message.contains(ownerContractIdHex),
                      "message does not name the owner: \(message)")
        XCTAssertEqual(requestLog.entries, [])
    }

    func testClaimableBalanceOwnerFailsWithoutRequest() async throws {
        setupMock(answers: [:])
        let balanceOwner = try SCAddressXDR(claimableBalanceId: "00000000" + ownerContractIdHex)

        let result = await server.getExternalRefWasmHash(ref: externalRef(owner: balanceOwner))

        guard let message = resolverFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("is not a contract address"),
                      "unexpected message: \(message)")
        XCTAssertTrue(message.contains(balanceOwner.claimableBalanceId!),
                      "message does not name the owner: \(message)")
        XCTAssertEqual(requestLog.entries, [])
    }

    func testRpcErrorPropagatesUnchangedFromResolver() async throws {
        let mock = RequestMock(host: "soroban-testnet.stellar.org",
                               path: "*",
                               httpMethod: "POST") { mock, request in
            mock.statusCode = 200
            return """
            {
                "jsonrpc": "2.0",
                "id": 1,
                "error": {"code": -32603, "message": "Internal error"}
            }
            """
        }
        ServerMock.add(mock: mock)

        let result = await server.getExternalRefWasmHash(ref: externalRef())

        guard case .failure(let error) = result,
              case SorobanRpcRequestError.errorResponse(let rpcError) = error else {
            XCTFail("Expected errorResponse, got \(result)")
            return
        }
        XCTAssertEqual(rpcError.code, -32603)
        XCTAssertEqual(rpcError.message, "Internal error")
    }

    func testTagEntryThatIsNotContractDataFails() async throws {
        setupMock(answers: [tagKeyB64(): codeEntry(code: Data([1, 2, 3]))])

        let result = await server.getExternalRefWasmHash(ref: externalRef())

        guard let message = resolverFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("is not a contract data entry"),
                      "unexpected message: \(message)")
    }

    func testInstanceEntryThatIsNotAContractInstanceFails() async throws {
        let notAnInstance = LedgerEntryDataXDR.contractData(ContractDataEntryXDR(
            ext: .void,
            contract: try! SCAddressXDR(contractId: mockContractId),
            key: SCValXDR.ledgerKeyContractInstance,
            durability: .persistent,
            val: SCValXDR.symbol("x")))
        setupMock(answers: [instanceKeyB64(): notAnInstance])

        let result = await server.getContractCodeForContractId(contractId: mockContractId)

        guard let message = codeFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("is not a contract instance"),
                      "unexpected message: \(message)")
    }

    func testStellarAssetContractFails() async throws {
        setupMock(answers: [instanceKeyB64(): instanceEntry(executable: .token)])

        let result = await server.getContractCodeForContractId(contractId: mockContractId)

        guard let message = codeFailureMessage(result) else {
            XCTFail("Expected requestFailed, got \(result)")
            return
        }
        XCTAssertTrue(message.contains("Stellar Asset Contract"), "unexpected message: \(message)")
        XCTAssertEqual(requestLog.entries, [instanceKeyB64()])
    }

    func testClientForClientOptionsResolvesExternalRef() async throws {
        setupMock(answers: [
            instanceKeyB64(): instanceEntry(executable: .externalRef(externalRef())),
            tagKeyB64(): tagEntry(val: SCValXDR.bytes(wasmHashBytes)),
            codeKeyB64(): codeEntry(code: tokenWasm),
        ])

        let client = try await SorobanClient.forClientOptions(options: ClientOptions(
            sourceAccountKeyPair: keyPair,
            contractId: mockContractId,
            network: Network.testnet,
            rpcUrl: mockRpcUrl,
            enableServerLogging: false))

        XCTAssertTrue(client.methodNames.contains("transfer"))
    }

    func testTagSurvivesXdrRoundTripIntoTheSameLedgerKey() throws {
        let tag = "tøken-\u{0000}-火"
        let writtenKey = SCValXDR.executableTag(tag).xdrEncoded!

        let instanceVal = SCValXDR.contractInstance(SCContractInstanceXDR(
            executable: .externalRef(ContractExecutableExternalRefXDR(executableOwner: ownerAddress(), tag: tag)),
            storage: nil))
        let decoded = try SCValXDR.fromXdr(base64: instanceVal.xdrEncoded!)

        guard let decodedTag = decoded.contractInstance?.executable.externalRef?.tag else {
            XCTFail("decoded value carries no external ref tag")
            return
        }
        XCTAssertEqual(decodedTag, Data(tag.utf8))
        XCTAssertEqual(SCValXDR.executableTag(decodedTag).xdrEncoded!, writtenKey)
    }
}
