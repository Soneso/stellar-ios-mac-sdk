//
//  SorobanClientExternalRefDeployUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 19.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests for SorobanClient.deployFromExternalRef(), the external-ref create
/// operation builders and ContractIdUtils.deriveContractId().
///
/// The deploy flow resolves the CAP-85 external reference before the
/// transaction is built and loads the contract spec from the resolved wasm
/// code entry. All RPC calls are served by ServerMock; no network access. The
/// submitted transaction envelope is decoded to verify the external-ref
/// create host function it carries.
final class SorobanClientExternalRefDeployUnitTests: XCTestCase {

    var mockRpcUrl: String!
    var mockContractId: String!
    var ownerContractIdHex: String!
    var executableTag: String!
    var keyPair: KeyPair!
    var wasmHashBytes: Data!
    var tokenWasm: Data!
    var fixedSalt: WrappedData32!

    /// Records every served request as 'tag', 'code', 'contractData',
    /// 'account', 'simulate', 'send' or 'getTx', and the envelopes submitted
    /// via sendTransaction.
    private final class RequestLog: @unchecked Sendable {
        var entries: [String] = []
        var envelopes: [String] = []
    }
    private var requestLog = RequestLog()

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        mockRpcUrl = "https://soroban-testnet.stellar.org"
        mockContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        ownerContractIdHex = "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd"
        executableTag = "token-v1"
        keyPair = try! KeyPair.generateRandomKeyPair()
        wasmHashBytes = Data(repeating: 3, count: 32)
        fixedSalt = WrappedData32(Data(repeating: 0x11, count: 32))
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

    private func ownerStrKey() -> String {
        return try! ownerContractIdHex.encodeContractIdHex()
    }

    private func tagKeyB64() -> String {
        let key = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: ownerAddress(),
            key: SCValXDR.executableTag(executableTag),
            durability: .persistent))
        return key.xdrEncoded!
    }

    private func codeKeyB64() -> String {
        let key = LedgerKeyXDR.contractCode(LedgerKeyContractCodeXDR(
            hash: WrappedData32(wasmHashBytes)))
        return key.xdrEncoded!
    }

    private func tagEntry() -> LedgerEntryDataXDR {
        return LedgerEntryDataXDR.contractData(ContractDataEntryXDR(
            ext: .void,
            contract: ownerAddress(),
            key: SCValXDR.executableTag(executableTag),
            durability: .persistent,
            val: SCValXDR.bytes(wasmHashBytes)))
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

    // MARK: - Mock setup

    /// Serves the full external-ref deploy flow: the executable tag entry for
    /// the resolution, the wasm code entry for the spec preload, the source
    /// account, simulate, send and getTransaction. When [tagEntryExists] is
    /// false, the resolution request is answered with no entries.
    private func setupDeployFlowMock(tagEntryExists: Bool = true) {
        let log = requestLog
        let tagKey = tagKeyB64()
        let codeKey = codeKeyB64()
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
                  let rawBody = String(data: bodyData, encoding: .utf8) else {
                return nil
            }
            // JSON serialization escapes "/" in the base64 keys as "\/".
            let bodyString = rawBody.replacingOccurrences(of: "\\/", with: "/")
            mock.statusCode = 200
            if bodyString.contains("simulateTransaction") {
                log.entries.append("simulate")
                return self.simulateResponseJson()
            }
            if bodyString.contains("sendTransaction") {
                log.entries.append("send")
                if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
                   let params = json["params"] as? [String: Any],
                   let envelope = params["transaction"] as? String {
                    log.envelopes.append(envelope)
                }
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
                if bodyString.contains(tagKey) {
                    log.entries.append("tag")
                    guard tagEntryExists else {
                        return self.emptyEntriesJson()
                    }
                    return self.ledgerEntryResponseJson(entryData: self.tagEntry())
                }
                // The code answer requires the exact CONTRACT_CODE key of the
                // resolved wasm hash, so a preload from any other value gets
                // no entry. CONTRACT_DATA keys encode with discriminant 6
                // ("AAAABg"); anything else is the account fetch.
                if bodyString.contains(codeKey) {
                    log.entries.append("code")
                    return self.ledgerEntryResponseJson(entryData: self.contractCodeEntry(code: self.tokenWasm))
                }
                if bodyString.contains("AAAABg") {
                    log.entries.append("contractData")
                    return self.emptyEntriesJson()
                }
                log.entries.append("account")
                return self.ledgerEntryResponseJson(entryData: self.accountEntry())
            }
            return nil
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

    private func deployRequest(constructorArgs: [SCValXDR]? = nil, salt: WrappedData32? = nil) -> DeployFromExternalRefRequest {
        return DeployFromExternalRefRequest(
            rpcUrl: mockRpcUrl,
            network: Network.testnet,
            sourceAccountKeyPair: keyPair,
            executableOwner: ownerStrKey(),
            tag: executableTag,
            constructorArgs: constructorArgs,
            salt: salt,
            enableServerLogging: false
        )
    }

    /// The host function of the invoke host function operation in the
    /// submitted envelope.
    private func submittedHostFunction() throws -> HostFunctionXDR? {
        XCTAssertEqual(requestLog.envelopes.count, 1)
        guard let envelopeB64 = requestLog.envelopes.first else {
            return nil
        }
        let envelope = try TransactionEnvelopeXDR(xdr: envelopeB64)
        guard case .v1(let env) = envelope,
              case .invokeHostFunctionOp(let invokeOp) = env.tx.operations.first?.body else {
            XCTFail("expected a v1 envelope with an invoke host function operation")
            return nil
        }
        return invokeOp.hostFunction
    }

    // MARK: - deployFromExternalRef

    func testDeployResolvesAndPinsTheEnvelope() async throws {
        setupDeployFlowMock()

        let client = try await SorobanClient.deployFromExternalRef(
            deployRequest: deployRequest(constructorArgs: [SCValXDR.u32(7)], salt: fixedSalt))

        XCTAssertEqual(client.contractId, mockContractId)
        XCTAssertTrue(client.methodNames.contains("transfer"))
        // The reference resolves and the spec loads before submission; the
        // contract instance is never read.
        XCTAssertFalse(requestLog.entries.contains("contractData"))
        guard let tagIndex = requestLog.entries.firstIndex(of: "tag"),
              let codeIndex = requestLog.entries.firstIndex(of: "code"),
              let sendIndex = requestLog.entries.firstIndex(of: "send") else {
            XCTFail("Expected tag, code and send requests, got: \(requestLog.entries)")
            return
        }
        XCTAssertLessThan(tagIndex, codeIndex)
        XCTAssertLessThan(codeIndex, sendIndex)

        guard let hostFunction = try submittedHostFunction(),
              case .createContractV2(let createArgs) = hostFunction else {
            XCTFail("expected a createContractV2 host function")
            return
        }
        guard case .externalRef(let ref) = createArgs.executable else {
            XCTFail("expected an external ref executable")
            return
        }
        XCTAssertEqual(ref.executableOwner.contractId, ownerContractIdHex)
        XCTAssertEqual(ref.tag, executableTag)
        guard case .fromAddress(let preimage) = createArgs.contractIDPreimage else {
            XCTFail("expected a fromAddress preimage")
            return
        }
        XCTAssertEqual(preimage.salt.wrapped, fixedSalt.wrapped)
        XCTAssertEqual(createArgs.constructorArgs.count, 1)
        XCTAssertEqual(createArgs.constructorArgs.first?.u32, 7)
    }

    func testDeployWithoutConstructorArgsUsesCreateContract() async throws {
        setupDeployFlowMock()

        let client = try await SorobanClient.deployFromExternalRef(
            deployRequest: deployRequest())

        XCTAssertEqual(client.contractId, mockContractId)

        guard let hostFunction = try submittedHostFunction(),
              case .createContract(let createArgs) = hostFunction else {
            XCTFail("expected a createContract host function")
            return
        }
        guard case .externalRef(let ref) = createArgs.executable else {
            XCTFail("expected an external ref executable")
            return
        }
        XCTAssertEqual(ref.executableOwner.contractId, ownerContractIdHex)
        XCTAssertEqual(ref.tag, executableTag)
        guard case .fromAddress(let preimage) = createArgs.contractIDPreimage else {
            XCTFail("expected a fromAddress preimage")
            return
        }
        XCTAssertEqual(preimage.salt.wrapped.count, 32)
    }

    func testDeployFailsNamingOwnerAndTagWhenTagEntryMissing() async throws {
        setupDeployFlowMock(tagEntryExists: false)

        do {
            _ = try await SorobanClient.deployFromExternalRef(deployRequest: deployRequest())
            XCTFail("expected deployFailed for an unresolvable reference")
        } catch SorobanClientError.deployFailed(let message) {
            XCTAssertTrue(message.contains("does not resolve"), "unexpected message: \(message)")
            // A contract owner is spelled as its "C..." strkey.
            XCTAssertTrue(message.contains(ownerStrKey()), "unexpected message: \(message)")
            XCTAssertTrue(message.contains(executableTag), "unexpected message: \(message)")
        }
        // The failure happened before anything was submitted.
        XCTAssertEqual(requestLog.entries, ["tag"])
    }

    // MARK: - Builders

    func testCreateContractFromExternalRefBuilderRoundTrips() throws {
        let deployer = try SCAddressXDR(accountId: keyPair.accountId)
        let op = try InvokeHostFunctionOperation.forCreatingContractFromExternalRef(
            executableOwner: ownerAddress(), tag: executableTag, address: deployer, salt: fixedSalt)

        guard case .createContract(let createArgs) = op.hostFunction else {
            XCTFail("expected a createContract host function")
            return
        }
        guard case .externalRef(let ref) = createArgs.executable else {
            XCTFail("expected an external ref executable")
            return
        }
        XCTAssertEqual(ref.executableOwner.contractId, ownerContractIdHex)
        XCTAssertEqual(ref.tag, executableTag)
        guard case .fromAddress(let preimage) = createArgs.contractIDPreimage else {
            XCTFail("expected a fromAddress preimage")
            return
        }
        XCTAssertEqual(preimage.salt.wrapped, fixedSalt.wrapped)

        // Byte-identical re-encode through the XDR layer.
        let encoded = op.hostFunction.xdrEncoded!
        let decoded = try HostFunctionXDR(xdr: encoded)
        XCTAssertEqual(decoded.xdrEncoded!, encoded)
    }

    func testCreateContractFromExternalRefWithConstructorBuilderRoundTrips() throws {
        let deployer = try SCAddressXDR(accountId: keyPair.accountId)
        let op = try InvokeHostFunctionOperation.forCreatingContractFromExternalRefWithConstructor(
            executableOwner: ownerAddress(), tag: executableTag, address: deployer,
            constructorArguments: [SCValXDR.u32(7)], salt: fixedSalt)

        guard case .createContractV2(let createArgs) = op.hostFunction else {
            XCTFail("expected a createContractV2 host function")
            return
        }
        guard case .externalRef(let ref) = createArgs.executable else {
            XCTFail("expected an external ref executable")
            return
        }
        XCTAssertEqual(ref.executableOwner.contractId, ownerContractIdHex)
        XCTAssertEqual(ref.tag, executableTag)
        XCTAssertEqual(createArgs.constructorArgs.count, 1)
        XCTAssertEqual(createArgs.constructorArgs.first?.u32, 7)

        let encoded = op.hostFunction.xdrEncoded!
        let decoded = try HostFunctionXDR(xdr: encoded)
        XCTAssertEqual(decoded.xdrEncoded!, encoded)
    }

    func testBuilderGeneratesRandomSaltWhenOmitted() throws {
        let deployer = try SCAddressXDR(accountId: keyPair.accountId)
        let op = try InvokeHostFunctionOperation.forCreatingContractFromExternalRef(
            executableOwner: ownerAddress(), tag: executableTag, address: deployer)

        guard case .createContract(let createArgs) = op.hostFunction,
              case .fromAddress(let preimage) = createArgs.contractIDPreimage else {
            XCTFail("expected a createContract host function with a fromAddress preimage")
            return
        }
        XCTAssertEqual(preimage.salt.wrapped.count, 32)
    }

    // MARK: - deriveContractId

    func testDeriveContractIdMatchesTheSharedCrossSdkVectors() throws {
        // Shared vectors pinned across the Soneso SDKs; independently computed
        // (js-stellar-base and a hand-encoded preimage), never from this
        // implementation.
        let salt = Data(repeating: 0x11, count: 32)
        let accountDeployer = try SCAddressXDR(
            accountId: "GABAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEJXA")

        XCTAssertEqual(
            try ContractIdUtils.deriveContractId(
                deployer: accountDeployer, salt: salt, network: Network.testnet),
            "CADHEGA2PTPG6IJXYA62AY6JUQLQWOHRYX7A6FAZ4GL747OLBDQU7QXR")
        XCTAssertEqual(
            try ContractIdUtils.deriveContractId(
                deployer: accountDeployer, salt: salt, network: Network.public),
            "CC22JLXJCLGHDQDBHJXTOEAFRM7GIS3D7CBQXR7M22HMWYNPUUPH6GKV")

        let contractDeployer = try SCAddressXDR(
            contractId: "3f0918bf77f7e30fe942e4bc2ce903ffa2d80e7f3e1f82ba58877f0eb73df0b7")

        XCTAssertEqual(
            try ContractIdUtils.deriveContractId(
                deployer: contractDeployer, salt: salt, network: Network.testnet),
            "CBU52TQFSCXOGX5OOE6QQKBRD3XNXAS2MRLI2XFKLGEODECDADE32QYU")
        XCTAssertEqual(
            try ContractIdUtils.deriveContractId(
                deployer: contractDeployer, salt: salt, network: Network.public),
            "CAXJ2CGFFIGYDFF55V64NWWUASL7IMAZTVVECYOKOVQWF4KQGXP2HH3U")
    }

    func testDeriveContractIdRejectsWrongSaltLength() throws {
        let deployer = try SCAddressXDR(
            accountId: "GABAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEJXA")

        // 31 for the off-by-one, 64 for the likeliest real mistake: a hex
        // string's byte length where raw bytes are expected.
        for length in [31, 64] {
            do {
                _ = try ContractIdUtils.deriveContractId(
                    deployer: deployer,
                    salt: Data(repeating: 0x11, count: length),
                    network: Network.testnet)
                XCTFail("expected invalidArgument for salt length \(length)")
            } catch StellarSDKError.invalidArgument(let message) {
                XCTAssertTrue(message.contains("must be exactly 32 bytes, got \(length)"),
                              "unexpected message: \(message)")
            }
        }
    }
}
