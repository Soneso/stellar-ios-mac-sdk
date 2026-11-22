//
//  SorobanClientSACDetectionUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests how `SorobanClient.forClientOptions` opens a contract, and `SorobanClient.forSpecEntries`.
///
/// A Stellar Asset Contract has no wasm on chain, so loading its spec fails. The client then
/// reads the contract's instance once more and, for the built-in token executable, opens
/// with the embedded spec. A contract whose code loads sends only the requests of the load:
/// the instance, then the code, or the tag and the code. Every other failed load throws the
/// loader's error after that one more instance read.
///
/// The RPC is `SACMockRPC` on a host that resolves nowhere; `tearDown` fails a test whose
/// requests the mock did not expect or that left the mock.
final class SorobanClientSACDetectionUnitTests: XCTestCase {

    /// The id of the native asset's contract on testnet.
    private let sacId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let ownerId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
    private let muxedContractId = "WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG"
    private let wasmHash = Data(repeating: 7, count: 32)
    private let executableTag = Data("release".utf8)

    /// The functions of `soroban_token_contract.wasm` in the order of its spec, without its constructor.
    private let tokenMethodNames = [
        "mint", "set_admin", "allowance", "approve", "balance", "transfer", "transfer_from", "burn",
        "burn_from", "decimals", "name", "symbol",
    ]

    private var rpc: SACMockRPC!

    override func setUp() {
        super.setUp()
        rpc = SACMockRPC(host: "sac-detection-unit-tests.mock", contractId: sacId)
    }

    override func tearDown() {
        rpc.tearDown()
        rpc = nil
        super.tearDown()
    }

    private func clientOptions(contractId: String? = nil, sourceAccountKeyPair: KeyPair? = nil) throws -> ClientOptions {
        return ClientOptions(sourceAccountKeyPair: try sourceAccountKeyPair ?? KeyPair.generateRandomKeyPair(),
                             contractId: contractId ?? sacId,
                             network: Network.testnet,
                             rpcUrl: rpc.rpcUrl,
                             urlSession: rpc.session)
    }

    private func instance(_ executable: ContractExecutableXDR) -> SACMockRPC.LedgerAnswer {
        return .entry(SACMockRPC.instanceEntry(contractId: sacId, executable: executable))
    }

    private func code(_ bytes: Data) -> SACMockRPC.LedgerAnswer {
        return .entry(SACMockRPC.codeEntry(wasmHash: wasmHash, code: bytes))
    }

    private func externalReference() throws -> ContractExecutableXDR {
        return .externalRef(ContractExecutableExternalRefXDR(executableOwner: try SCAddressXDR(contractId: ownerId),
                                                             tag: executableTag))
    }

    private func tokenWasm() throws -> Data {
        let path = try XCTUnwrap(Bundle.module.path(forResource: "soroban_token_contract", ofType: "wasm"))
        return try XCTUnwrap(FileManager.default.contents(atPath: path))
    }

    private func leb128(_ value: Int) -> [UInt8] {
        var remaining = value
        var bytes: [UInt8] = []
        repeat {
            var byte = UInt8(remaining & 0x7f)
            remaining >>= 7
            if remaining != 0 {
                byte |= 0x80
            }
            bytes.append(byte)
        } while remaining != 0
        return bytes
    }

    /// A wasm custom section: the id 0, the payload size, the name length, the name, the content.
    private func customSection(_ name: String, _ content: [UInt8]) -> [UInt8] {
        let payload = leb128(name.utf8.count) + Array(name.utf8) + content
        return [0x00] + leb128(payload.count) + payload
    }

    /// Runs `forClientOptions`, which must throw, and returns the request failure message.
    private func loaderFailure(_ options: ClientOptions, file: StaticString = #filePath, line: UInt = #line) async -> String? {
        let error = await SACAssert.error(file: file, line: line) {
            _ = try await SorobanClient.forClientOptions(options: options)
        }
        guard case SorobanRpcRequestError.requestFailed(let message)? = error else {
            XCTFail("expected SorobanRpcRequestError.requestFailed, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    // MARK: - forClientOptions: contracts that open

    /// An instance with the token executable opens with the 17 functions of the embedded
    /// spec after two instance requests: the load that fails and the detection.
    func testStellarAssetContractOpensWithEmbeddedSpec() async throws {
        rpc.serveInstance([instance(.token)])

        let client = try await SorobanClient.forClientOptions(options: try clientOptions())

        XCTAssertEqual(rpc.requestNames, ["instance", "instance"])
        XCTAssertEqual(client.contractId, sacId)
        // The 17 functions in the order of the embedded spec.
        XCTAssertEqual(client.methodNames, [
            "allowance", "authorized", "approve", "balance", "burn", "burn_from", "clawback", "decimals",
            "mint", "name", "set_admin", "admin", "set_authorized", "symbol", "transfer", "transfer_from",
            "trust",
        ])
        XCTAssertEqual(client.getSpecEntries().count, 30)
    }

    func testWasmContractPreservesRequests() async throws {
        let wasm = try tokenWasm()
        rpc.serveInstance([instance(.wasm(WrappedData32(wasmHash)))])
        rpc.serveCode(wasmHash: wasmHash, answers: [code(wasm)])

        let client = try await SorobanClient.forClientOptions(options: try clientOptions())

        XCTAssertEqual(rpc.requestNames, ["instance", "code"])
        XCTAssertEqual(client.methodNames, tokenMethodNames)
        let parsed = try SorobanContractParser.parseContractByteCode(byteCode: wasm)
        XCTAssertEqual(try client.getSpecEntries().map { try SACTestXdr.base64($0) },
                       try parsed.specEntries.map { try SACTestXdr.base64($0) })
    }

    /// Code with an interface version and an empty `contractspecv0` section loads: the
    /// client has no method names and no further request goes out.
    func testEmptyWasmSpecPreservesRequests() async throws {
        let interfaceVersion = SCEnvMetaEntryXDR.interfaceVersion(
            SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 23, preRelease: 0))
        let module: [UInt8] = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00]
            + customSection("contractenvmetav0", try XDREncoder.encode(interfaceVersion))
            + customSection("contractspecv0", [])
        rpc.serveInstance([instance(.wasm(WrappedData32(wasmHash)))])
        rpc.serveCode(wasmHash: wasmHash, answers: [code(Data(module))])

        let client = try await SorobanClient.forClientOptions(options: try clientOptions())

        XCTAssertEqual(rpc.requestNames, ["instance", "code"])
        XCTAssertEqual(client.methodNames, [])
        XCTAssertEqual(client.getSpecEntries().count, 0)
    }

    func testExternalReferencePreservesRequests() async throws {
        rpc.serveInstance([instance(try externalReference())])
        rpc.serveTag(owner: ownerId, tag: executableTag, answers: [
            .entry(SACMockRPC.contractDataEntry(contractId: ownerId,
                                                key: SCValXDR.executableTag(executableTag),
                                                val: SCValXDR.bytes(wasmHash))),
        ])
        rpc.serveCode(wasmHash: wasmHash, answers: [code(try tokenWasm())])

        let client = try await SorobanClient.forClientOptions(options: try clientOptions())

        XCTAssertEqual(rpc.requestNames, ["instance", "tag", "code"])
        XCTAssertEqual(client.methodNames, tokenMethodNames)
    }

    // MARK: - forClientOptions: the loader's errors

    func testMissingInstanceThrowsLoaderError() async throws {
        rpc.serveInstance([.noEntry])

        let message = await loaderFailure(try clientOptions())

        XCTAssertEqual(message, "no contract instance entry found for contract id CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC")
        XCTAssertEqual(rpc.requestNames, ["instance", "instance"])
    }

    func testMissingCodeThrowsLoaderError() async throws {
        rpc.serveInstance([instance(.wasm(WrappedData32(wasmHash)))])
        rpc.serveCode(wasmHash: wasmHash, answers: [.noEntry])

        let message = await loaderFailure(try clientOptions())

        XCTAssertEqual(message, "no contract code entry found for wasm id 0707070707070707070707070707070707070707070707070707070707070707")
        XCTAssertEqual(rpc.requestNames, ["instance", "code", "instance"])
    }

    func testUnresolvedReferenceThrowsLoaderError() async throws {
        rpc.serveInstance([instance(try externalReference())])
        rpc.serveTag(owner: ownerId, tag: executableTag, answers: [.noEntry])

        let message = await loaderFailure(try clientOptions())

        XCTAssertEqual(message, "no executable tag entry found on owner contract CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE for tag \"release\"")
        XCTAssertEqual(rpc.requestNames, ["instance", "tag", "instance"])
    }

    /// Code that does not parse throws the parser's error without a detection read.
    func testUnparsableCodeThrowsParserError() async throws {
        rpc.serveInstance([instance(.wasm(WrappedData32(wasmHash)))])
        rpc.serveCode(wasmHash: wasmHash, answers: [code(Data([1, 2, 3, 4]))])

        let options = try clientOptions()
        let error = await SACAssert.error {
            _ = try await SorobanClient.forClientOptions(options: options)
        }

        guard case SorobanContractParserError.malformedModule(let offset, let message)? = error else {
            XCTFail("expected SorobanContractParserError.malformedModule, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(offset, 0)
        XCTAssertEqual(message, "the module has 4 bytes, fewer than the 8 bytes of the wasm header")
        XCTAssertEqual(rpc.requestNames, ["instance", "code"])
    }

    /// The load finds no instance, and the detection read answers contract data that is no
    /// instance: the loader's error stands.
    func testDetectionReadWithoutInstanceThrowsLoaderError() async throws {
        rpc.serveInstance([
            .noEntry,
            .entry(SACMockRPC.contractDataEntry(contractId: sacId, key: SCValXDR.ledgerKeyContractInstance, val: SCValXDR.u32(1))),
        ])

        let message = await loaderFailure(try clientOptions())

        XCTAssertEqual(message, "no contract instance entry found for contract id CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC")
        XCTAssertEqual(rpc.requestNames, ["instance", "instance"])
    }

    /// The load meets the token executable, and the detection read fails with a JSON-RPC
    /// error: the loader's error stands.
    func testDetectionReadRpcErrorThrowsLoaderError() async throws {
        rpc.serveInstance([instance(.token), .rpcError(code: -32603, message: "internal error")])

        let message = await loaderFailure(try clientOptions())

        XCTAssertEqual(message, "contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC is a Stellar Asset Contract and has no wasm bytecode on chain")
        XCTAssertEqual(rpc.requestNames, ["instance", "instance"])
    }

    func testMuxedContractIdThrowsGuardErrorWithoutRequest() async throws {
        let message = await loaderFailure(try clientOptions(contractId: muxedContractId))

        XCTAssertEqual(message, "The contract to load must be a contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; use its base contract (C...) address")
        XCTAssertEqual(rpc.requestNames, [])
    }

    // MARK: - forSpecEntries

    /// `forSpecEntries` sends no request and keeps the given entries. Without `readOnly` its
    /// transactions are not read-only, so a build loads the source account.
    func testForSpecEntriesSendsNoRequestAndKeepsEntries() async throws {
        let entries = try SACClient.specEntries()
        let source = try KeyPair.generateRandomKeyPair()
        rpc.serveAccount(of: source)

        let client = try SorobanClient.forSpecEntries(specEntries: entries, options: try clientOptions(sourceAccountKeyPair: source))

        XCTAssertEqual(rpc.requestNames, [])
        XCTAssertEqual(client.contractId, sacId)
        XCTAssertEqual(try client.getSpecEntries().map { try SACTestXdr.base64($0) },
                       try entries.map { try SACTestXdr.base64($0) })
        XCTAssertEqual(client.methodNames.count, 17)

        let tx = try await client.buildInvokeMethodTx(name: "decimals", methodOptions: MethodOptions(simulate: false))

        XCTAssertFalse(tx.options.readOnly)
        XCTAssertEqual(rpc.requestNames, ["account"])
    }

    func testForSpecEntriesRejectsMuxedContractId() throws {
        let options = try clientOptions(contractId: muxedContractId)

        XCTAssertThrowsError(try SorobanClient.forSpecEntries(specEntries: [], options: options)) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                XCTFail("expected StellarSDKError.invalidArgument, got \(error)")
                return
            }
            XCTAssertEqual(message, "The contract to invoke must be a contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; use its base contract (C...) address")
        }
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testConstructorIsExcluded() throws {
        let entries = [
            SCSpecEntryXDR.functionV0(SCSpecFunctionV0XDR(doc: "", name: "__constructor", inputs: [], outputs: [])),
            SCSpecEntryXDR.functionV0(SCSpecFunctionV0XDR(doc: "", name: "balance", inputs: [], outputs: [])),
        ]

        let client = try SorobanClient.forSpecEntries(specEntries: entries, options: try clientOptions())

        XCTAssertEqual(try client.getSpecEntries().map { try SACTestXdr.base64($0) },
                       try entries.map { try SACTestXdr.base64($0) })
        XCTAssertEqual(client.methodNames, ["balance"])
        XCTAssertEqual(rpc.requestNames, [])
    }
}
