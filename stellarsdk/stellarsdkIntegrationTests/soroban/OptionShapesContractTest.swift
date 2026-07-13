//
//  OptionShapesContractTest.swift
//  stellarsdk
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class OptionShapesContractTest: XCTestCase {
    static let testOn = "testnet" // "futurenet"
    let testnetServerUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    let optionShapesContractFileName = "soroban_bindings_option_shapes_contract"
    var sourceAccountKeyPair: KeyPair!

    override func setUp() async throws {
        sourceAccountKeyPair = try KeyPair.generateRandomKeyPair()
        print("Signer seed: \(String(describing: sourceAccountKeyPair.secretSeed))")
        let testAccountId = sourceAccountKeyPair.accountId
        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountKeyPair.accountId)")
        }
    }

    func testOptionShapesContractBindings() async throws {
        print("=== Starting testOptionShapesContractBindings ===")

        let wasmHash = try await installContract(fileName: optionShapesContractFileName)
        print("Installed option shapes contract wasm hash: \(wasmHash)")

        let deployedClient = try await deployContract(wasmHash: wasmHash)
        let contractId = deployedClient.contractId
        print("Deployed option shapes contract contract id: \(contractId)")

        let clientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair, contractId: contractId, network: network, rpcUrl: testnetServerUrl)
        let contract = try await OptionShapesContract.forClientOptions(options: clientOptions)

        // Sanity check on the exposed method surface
        let methodNames = contract.methodNames
        XCTAssertTrue(methodNames.contains("opt_tuple"))
        XCTAssertTrue(methodNames.contains("opt_strukt"))
        XCTAssertTrue(methodNames.contains("opt_map"))
        XCTAssertTrue(methodNames.contains("opt_union"))
        XCTAssertTrue(methodNames.contains("default"))

        // tuple with optional element (Option<u32>, u32): some case
        let optTupleSomeResult = try await contract.optTuple(tuple: (77, 5))
        XCTAssertEqual(77, optTupleSomeResult.0)
        XCTAssertEqual(5, optTupleSomeResult.1)
        print("opt_tuple some round-trip passed: (\(String(describing: optTupleSomeResult.0)), \(optTupleSomeResult.1))")

        // tuple with optional element: nil case (encoded as ScVal void inside the vec)
        let optTupleNilResult = try await contract.optTuple(tuple: (nil, 5))
        XCTAssertNil(optTupleNilResult.0)
        XCTAssertEqual(5, optTupleNilResult.1)
        print("opt_tuple nil round-trip passed")

        // struct with optional field: maybe set
        let optStruktSomeResult = try await contract.optStrukt(
            strukt: OptionShapesContractMaybeStruct(flag: 1, maybe: 99))
        XCTAssertEqual(1, optStruktSomeResult.flag)
        XCTAssertEqual(99, optStruktSomeResult.maybe)
        print("opt_strukt maybe-set round-trip passed")

        // struct with optional field: maybe nil (encoded as ScVal void for the field)
        let optStruktNilResult = try await contract.optStrukt(
            strukt: OptionShapesContractMaybeStruct(flag: 2, maybe: nil))
        XCTAssertEqual(2, optStruktNilResult.flag)
        XCTAssertNil(optStruktNilResult.maybe)
        print("opt_strukt maybe-nil round-trip passed")

        // map<u32, Option<u32>> with mixed set and nil values. Swift Dictionary
        // iteration order is arbitrary; the binding must sort the ScMap entries by
        // key, which Soroban requires.
        let optMapValue: [UInt32: UInt32?] = [9: nil, 3: 30, 6: nil, 1: 10]
        let optMapResult = try await contract.optMap(map: optMapValue)
        XCTAssertEqual(optMapValue, optMapResult)
        print("map<u32,Option<u32>> round-trip passed")

        // union with optional payload: Nothing arm
        let optUnionNothingResult = try await contract.optUnion(union: .Nothing)
        guard case .Nothing = optUnionNothingResult else {
            XCTFail("expected OptUnion.Nothing")
            return
        }
        print("opt_union Nothing round-trip passed")

        // union with optional payload: Maybe(some) arm
        let optUnionMaybeResult = try await contract.optUnion(union: .Maybe(21))
        guard case .Maybe(let maybeValue) = optUnionMaybeResult else {
            XCTFail("expected OptUnion.Maybe")
            return
        }
        XCTAssertEqual(21, maybeValue)
        print("opt_union Maybe(some) round-trip passed: \(String(describing: maybeValue))")

        // union with optional payload: Maybe(nil) arm. The generated case carries a
        // UInt32? payload, so a Maybe holding no value is representable and must
        // round-trip distinctly from Nothing.
        let optUnionMaybeNilResult = try await contract.optUnion(union: .Maybe(nil))
        guard case .Maybe(let maybeNilValue) = optUnionMaybeNilResult else {
            XCTFail("expected OptUnion.Maybe with nil payload")
            return
        }
        XCTAssertNil(maybeNilValue)
        print("opt_union Maybe(nil) round-trip passed")

        // keyword-named method: default (Swift keyword, backticked in the generated client)
        let defaultResult = try await contract.`default`(value: 314)
        XCTAssertEqual(314, defaultResult)
        print("keyword-named default method passed: \(defaultResult)")

        print("=== testOptionShapesContractBindings completed successfully ===")
    }

    func installContract(fileName: String) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm") else {
            XCTFail("File \(fileName).wasm not found.")
            return ""
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("File \(fileName).wasm could not be loaded.")
            return ""
        }

        let installRequest = InstallRequest(rpcUrl: testnetServerUrl,
                                            network: network,
                                            sourceAccountKeyPair: sourceAccountKeyPair,
                                            wasmBytes: contractCode,
                                            enableServerLogging: true)
        return try await SorobanClient.install(installRequest: installRequest)
    }

    func deployContract(wasmHash: String, constructorArgs: [SCValXDR]? = nil) async throws -> SorobanClient {
        let deployRequest = DeployRequest(rpcUrl: testnetServerUrl,
                                          network: network,
                                          sourceAccountKeyPair: sourceAccountKeyPair,
                                          wasmHash: wasmHash,
                                          constructorArgs: constructorArgs,
                                          enableServerLogging: true)

        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }
}
