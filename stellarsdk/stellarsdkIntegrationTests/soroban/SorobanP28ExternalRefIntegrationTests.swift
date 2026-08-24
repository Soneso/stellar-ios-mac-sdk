//
//  SorobanP28ExternalRefIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 18.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import Security
import stellarsdk

/// Verifies the CAP-85 external reference lifecycle against a live network.
///
/// `testExternalRefLifecycle` is self-contained: it installs the owner fixture
/// contract (source in tools/p28-owner-fixture), deploys it, installs the hello
/// world contract's wasm, writes an executable tag entry naming it, resolves the
/// reference, and deploys a new instance from it with an explicit salt. It
/// verifies the created contract id against `ContractIdUtils.deriveContractId`,
/// and checks the instance's executable arm, the loaded code bytes, and a live
/// invocation.
/// `testLoadExternalRefContract` reads an external-ref contract that already
/// exists on the network; its contract id comes from the environment variable
/// `STELLAR_P28_EXTERNAL_REF_CONTRACT_ID`, and the test skips when the
/// variable is unset. Both tests skip when the network runs a protocol
/// below 28.
final class SorobanP28ExternalRefIntegrationTests: XCTestCase {

    static let testOn = "testnet" // "futurenet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let rpcUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    func testExternalRefLifecycle() async throws {
        let protocolVersion = try await fetchProtocolVersion()
        guard protocolVersion >= 28 else {
            throw XCTSkip("Network runs protocol \(protocolVersion); skipping P28 external-ref lifecycle test")
        }

        let keyPair = try KeyPair.generateRandomKeyPair()
        try await fundTestAccountAndAwaitVisibility(accountId: keyPair.accountId,
                                                    rpc: sorobanServer,
                                                    useFuturenet: Self.testOn != "testnet")

        // Install and deploy the owner fixture holding the executable tag entries.
        let ownerWasmHash = try await installContract(fileName: "p28_owner_fixture",
                                                      sourceAccountKeyPair: keyPair)
        let ownerClient = try await deployContract(wasmHash: ownerWasmHash, sourceAccountKeyPair: keyPair)
        XCTAssertTrue(ownerClient.methodNames.contains("set_executable"))
        let owner = try SCAddressXDR(contractId: ownerClient.contractId)

        // Install the target code and write the tag entry naming it.
        let targetWasmHash = try await installContract(fileName: "soroban_hello_world_contract",
                                                       sourceAccountKeyPair: keyPair)
        let executableTag = "sdk-e2e-v1"
        _ = try await ownerClient.invokeMethod(name: "set_executable", args: [
            SCValXDR.string(executableTag),
            SCValXDR.bytes(targetWasmHash.data(using: .hexadecimal)!),
        ])

        // The reference resolves to the stored wasm hash.
        let ref = ContractExecutableExternalRefXDR(executableOwner: owner, tag: executableTag)
        let hashResponse = await sorobanServer.getExternalRefWasmHash(ref: ref)
        guard case .success(let resolvedHash) = hashResponse else {
            XCTFail("getExternalRefWasmHash failed: \(hashResponse)")
            return
        }
        XCTAssertEqual(resolvedHash.base16EncodedString(), targetWasmHash)

        // The RPC must accept the executable tag ledger key the resolver builds,
        // answering an empty entry list for a tag no entry exists under. The
        // response is asserted directly because a resolver failure would not
        // distinguish an accepted-but-absent key from a rejected request.
        let unusedTag = "no entry exists under this tag"
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
        let unusedRef = ContractExecutableExternalRefXDR(executableOwner: owner, tag: unusedTag)
        let unusedResponse = await sorobanServer.getExternalRefWasmHash(ref: unusedRef)
        guard case .failure(let error) = unusedResponse,
              case SorobanRpcRequestError.requestFailed(let message) = error else {
            XCTFail("expected the missing-entry failure, got \(unusedResponse)")
            return
        }
        XCTAssertTrue(message.contains("no executable tag entry found"),
                      "unexpected message: \(message)")

        // Deploy from the reference with an explicit salt; the created contract id
        // must match the derivation, and the instance must run the target's code.
        var salt = Data(count: 32)
        let saltResult = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        XCTAssertEqual(saltResult, errSecSuccess)
        let predictedContractId = try ContractIdUtils.deriveContractId(
            deployer: try SCAddressXDR(accountId: keyPair.accountId),
            salt: salt,
            network: network)
        let client = try await SorobanClient.deployFromExternalRef(
            deployRequest: DeployFromExternalRefRequest(
                rpcUrl: rpcUrl,
                network: network,
                sourceAccountKeyPair: keyPair,
                executableOwner: ownerClient.contractId,
                tag: executableTag,
                salt: WrappedData32(salt),
                enableServerLogging: false))
        XCTAssertEqual(client.contractId, predictedContractId)
        XCTAssertTrue(client.methodNames.contains("hello"))

        // The instance entry carries the external reference arm naming owner and tag.
        let dataResponse = await sorobanServer.getContractData(contractId: client.contractId,
                                                               key: SCValXDR.ledgerKeyContractInstance,
                                                               durability: ContractDataDurability.persistent)
        guard case .success(let entry) = dataResponse else {
            XCTFail("could not read the deployed contract instance: \(dataResponse)")
            return
        }
        let entryData = try LedgerEntryDataXDR(fromBase64: entry.xdr)
        guard case .externalRef(let instanceRef) = entryData.contractData?.val.contractInstance?.executable else {
            XCTFail("the deployed instance does not carry an external-ref executable")
            return
        }
        XCTAssertEqual(instanceRef.executableOwner.contractId, owner.contractId)
        XCTAssertEqual(instanceRef.tag, Data(executableTag.utf8))

        // The code loader resolves the reference to the target's code.
        let codeResponse = await sorobanServer.getContractCodeForContractId(contractId: client.contractId)
        guard case .success(let codeEntry) = codeResponse else {
            XCTFail("getContractCodeForContractId failed: \(codeResponse)")
            return
        }
        XCTAssertEqual(codeEntry.hash.wrapped.base16EncodedString(), targetWasmHash)
        guard let targetPath = Bundle.module.path(forResource: "soroban_hello_world_contract", ofType: "wasm"),
              let targetBytes = FileManager.default.contents(atPath: targetPath) else {
            XCTFail("soroban_hello_world_contract.wasm not found in test bundle")
            return
        }
        XCTAssertEqual(codeEntry.code, targetBytes)

        // The deployed instance is live: it answers as the target contract.
        let result = try await client.invokeMethod(name: "hello", args: [SCValXDR.symbol("friend")])
        XCTAssertEqual(result.vec?.first?.symbol, "Hello")
        XCTAssertEqual(result.vec?.last?.symbol, "friend")
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
