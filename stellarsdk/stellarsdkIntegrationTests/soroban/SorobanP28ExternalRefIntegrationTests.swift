//
//  SorobanP28ExternalRefIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 18.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Verifies CAP-85 external reference resolution against a live network.
///
/// `testExternalRefLedgerKeyAcceptedByRpc` is self-contained: it deploys its
/// own contract and checks that the RPC accepts the executable tag ledger key
/// the resolver builds. `testLoadExternalRefContract` reads an external-ref
/// contract that already exists on the network; its contract id comes from the
/// environment variable `STELLAR_P28_EXTERNAL_REF_CONTRACT_ID`, which must
/// name a contract deployed with a CAP-85 external reference executable, and
/// the test skips when the variable is unset. Both tests skip when the network
/// runs a protocol below 28.
final class SorobanP28ExternalRefIntegrationTests: XCTestCase {

    static let testOn = "testnet" // "futurenet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let rpcUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    func testExternalRefLedgerKeyAcceptedByRpc() async throws {
        let protocolVersion = try await fetchProtocolVersion()
        guard protocolVersion >= 28 else {
            throw XCTSkip("Network runs protocol \(protocolVersion); skipping P28 external-ref key test")
        }

        let keyPair = try KeyPair.generateRandomKeyPair()
        try await fundTestAccountAndAwaitVisibility(accountId: keyPair.accountId,
                                                    rpc: sorobanServer,
                                                    useFuturenet: Self.testOn != "testnet")
        let wasmHash = try await installContract(fileName: "soroban_hello_world_contract",
                                                 sourceAccountKeyPair: keyPair)
        let client = try await deployContract(wasmHash: wasmHash, sourceAccountKeyPair: keyPair)
        let contractId = client.contractId

        // The executable dispatch still loads a wasm instance from the live ledger.
        let codeResponse = await sorobanServer.getContractCodeForContractId(contractId: contractId)
        guard case .success(let codeEntry) = codeResponse else {
            XCTFail("getContractCodeForContractId failed: \(codeResponse)")
            return
        }
        XCTAssertFalse(codeEntry.code.isEmpty)

        // The RPC must accept the executable tag ledger key the resolver builds,
        // answering an empty entry list for a tag no entry exists under. The
        // response is asserted directly because a resolver failure would not
        // distinguish an accepted-but-absent key from a rejected request.
        let unusedTag = "no entry exists under this tag"
        let owner = try SCAddressXDR(contractId: contractId)
        let tagKey = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: owner,
            key: SCValXDR.executableTag(unusedTag),
            durability: ContractDataDurability.persistent))
        let entriesResponse = await sorobanServer.getLedgerEntries(base64EncodedKeys: [tagKey.xdrEncoded!])
        guard case .success(let entriesResult) = entriesResponse else {
            XCTFail("RPC rejected the executable tag ledger key: \(entriesResponse)")
            return
        }
        XCTAssertTrue(entriesResult.entries.isEmpty)

        // The resolver reports the same absence with its missing-entry message.
        let ref = ContractExecutableExternalRefXDR(executableOwner: owner, tag: unusedTag)
        let hashResponse = await sorobanServer.getExternalRefWasmHash(ref: ref)
        guard case .failure(let error) = hashResponse,
              case SorobanRpcRequestError.requestFailed(let message) = error else {
            XCTFail("expected the missing-entry failure, got \(hashResponse)")
            return
        }
        XCTAssertTrue(message.contains("no executable tag entry found"),
                      "unexpected message: \(message)")
    }

    func testLoadExternalRefContract() async throws {
        let protocolVersion = try await fetchProtocolVersion()
        guard protocolVersion >= 28 else {
            throw XCTSkip("Network runs protocol \(protocolVersion); skipping P28 external-ref test")
        }
        guard let contractId = ProcessInfo.processInfo.environment["STELLAR_P28_EXTERNAL_REF_CONTRACT_ID"] else {
            throw XCTSkip("STELLAR_P28_EXTERNAL_REF_CONTRACT_ID not set; skipping P28 external-ref test")
        }

        // Read the instance the same way getContractCodeForContractId does and
        // require the external-ref arm. A fixture pointing at a contract with a
        // different executable is a broken fixture and must be visible.
        let dataResponse = await sorobanServer.getContractData(contractId: contractId,
                                                               key: SCValXDR.ledgerKeyContractInstance,
                                                               durability: ContractDataDurability.persistent)
        guard case .success(let entry) = dataResponse else {
            XCTFail("could not read contract instance for \(contractId): \(dataResponse)")
            return
        }
        let entryData = try LedgerEntryDataXDR(fromBase64: entry.xdr)
        guard let executable = entryData.contractData?.val.contractInstance?.executable else {
            XCTFail("ledger entry for \(contractId) is not a contract instance")
            return
        }
        guard case .externalRef(let ref) = executable else {
            XCTFail("fixture contract \(contractId) does not carry an external-ref executable; its executable is \(executable)")
            return
        }

        // The reference resolves to a 32-byte wasm hash.
        let hashResponse = await sorobanServer.getExternalRefWasmHash(ref: ref)
        guard case .success(let wasmHash) = hashResponse else {
            XCTFail("getExternalRefWasmHash failed: \(hashResponse)")
            return
        }
        XCTAssertEqual(wasmHash.count, 32)

        // The code loader resolves the reference and returns the code entry of
        // exactly that hash.
        let codeResponse = await sorobanServer.getContractCodeForContractId(contractId: contractId)
        guard case .success(let codeEntry) = codeResponse else {
            XCTFail("getContractCodeForContractId failed: \(codeResponse)")
            return
        }
        XCTAssertEqual(codeEntry.hash.wrapped, wasmHash)
        XCTAssertFalse(codeEntry.code.isEmpty)

        // The info loader parses the code behind the reference.
        let infoResponse = await sorobanServer.getContractInfoForContractId(contractId: contractId)
        guard case .success(let info) = infoResponse else {
            XCTFail("getContractInfoForContractId failed: \(infoResponse)")
            return
        }
        XCTAssertFalse(info.specEntries.isEmpty)
    }

    // MARK: - Helpers

    /// Returns the current ledger protocol version from the RPC.
    private func fetchProtocolVersion() async throws -> Int {
        let response = await sorobanServer.getLatestLedger()
        switch response {
        case .success(let ledger):
            return ledger.protocolVersion
        case .failure(let error):
            XCTFail("getLatestLedger failed: \(error)")
            return 0
        }
    }

    private func installContract(fileName: String, sourceAccountKeyPair: KeyPair) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm"),
              let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("\(fileName).wasm not found in test bundle")
            return ""
        }
        let installRequest = InstallRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: sourceAccountKeyPair,
            wasmBytes: contractCode,
            enableServerLogging: false
        )
        return try await SorobanClient.install(installRequest: installRequest)
    }

    private func deployContract(wasmHash: String, sourceAccountKeyPair: KeyPair) async throws -> SorobanClient {
        let deployRequest = DeployRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: sourceAccountKeyPair,
            wasmHash: wasmHash,
            enableServerLogging: false
        )
        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }
}
