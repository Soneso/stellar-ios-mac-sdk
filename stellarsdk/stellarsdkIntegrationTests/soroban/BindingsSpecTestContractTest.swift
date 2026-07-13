//
//  BindingsSpecTestContractTest.swift
//  stellarsdk
//
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class BindingsSpecTestContractTest: XCTestCase {
    static let testOn = "testnet" // "futurenet"
    let testnetServerUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    let specTestContractFileName = "soroban_bindings_spec_test_contract"
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

    func testBindingsSpecTestContractBindings() async throws {
        print("=== Starting testBindingsSpecTestContractBindings ===")

        let wasmHash = try await installContract(fileName: specTestContractFileName)
        print("Installed bindings spec test contract wasm hash: \(wasmHash)")

        let deployedClient = try await deployContract(wasmHash: wasmHash)
        let contractId = deployedClient.contractId
        print("Deployed bindings spec test contract contract id: \(contractId)")

        let clientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair, contractId: contractId, network: network, rpcUrl: testnetServerUrl)
        let contract = try await BindingsSpecTestContract.forClientOptions(options: clientOptions)

        // Sanity check on the exposed method surface
        let methodNames = contract.methodNames
        XCTAssertTrue(methodNames.contains("u64"))
        XCTAssertTrue(methodNames.contains("complex"))
        XCTAssertTrue(methodNames.contains("void"))
        XCTAssertTrue(methodNames.contains("from"))
        XCTAssertTrue(methodNames.contains("u32_fail_on_even"))

        // u64 above 2^53 (beyond the range a Double can represent exactly)
        let bigU64: UInt64 = 9_007_199_254_740_993 // 2^53 + 1
        let u64Result = try await contract.u64(u64: bigU64)
        XCTAssertEqual(bigU64, u64Result)
        print("u64 above 2^53 round-trip passed: \(u64Result)")

        // negative i64
        let negI64: Int64 = -9_007_199_254_740_993
        let i64Result = try await contract.i64(i64: negI64)
        XCTAssertEqual(negI64, i64Result)
        print("negative i64 round-trip passed: \(i64Result)")

        // timepoint
        let timepointValue: UInt64 = 1_700_000_000
        let timepointResult = try await contract.timepoint(timepoint: timepointValue)
        XCTAssertEqual(timepointValue, timepointResult)
        print("timepoint round-trip passed: \(timepointResult)")

        // duration
        let durationValue: UInt64 = 987_654_321
        let durationResult = try await contract.duration(duration: durationValue)
        XCTAssertEqual(durationValue, durationResult)
        print("duration round-trip passed: \(durationResult)")

        // bytes
        let bytesValue = Data([0x00, 0x01, 0x02, 0xFE, 0xFF])
        let bytesResult = try await contract.bytes(bytes_: bytesValue)
        XCTAssertEqual(bytesValue, bytesResult)
        print("bytes round-trip passed")

        // map<u32, bool>. Keys are intentionally provided out of ascending order so
        // the round-trip exercises the generated binding sorting the ScMap entries by
        // key, which Soroban requires for conversion to a host map.
        let mapValue: [UInt32: Bool] = [7: false, 1: true, 2: true]
        let mapResult = try await contract.map(map: mapValue)
        XCTAssertEqual(mapValue, mapResult)
        print("map<u32,bool> round-trip passed")

        // tuple (Symbol, u32) argument and return
        let tupleResult = try await contract.tuple(tuple: ("hello", 42))
        XCTAssertEqual("hello", tupleResult.0)
        XCTAssertEqual(42, tupleResult.1)
        print("tuple round-trip passed: (\(tupleResult.0), \(tupleResult.1))")

        // option some
        let optionSomeResult = try await contract.option(option: 123)
        XCTAssertEqual(123, optionSomeResult)
        print("option some round-trip passed: \(String(describing: optionSomeResult))")

        // option none
        let optionNoneResult = try await contract.option(option: nil)
        XCTAssertNil(optionNoneResult)
        print("option none round-trip passed")

        // struct round-trip
        let structValue = BindingsSpecTestContractSimpleStruct(a: 42, b: true, c: "world")
        let structResult = try await contract.strukt(strukt: structValue)
        XCTAssertEqual(42, structResult.a)
        XCTAssertTrue(structResult.b)
        XCTAssertEqual("world", structResult.c)
        print("struct round-trip passed")

        // union round-trip: void case
        let complexVoidResult = try await contract.complex(complex: .Void)
        guard case .Void = complexVoidResult else {
            XCTFail("expected ComplexEnum.Void")
            return
        }
        print("union void case round-trip passed")

        // union round-trip: tuple case
        let tupleStruct = BindingsSpecTestContractTupleStruct(value: (
            BindingsSpecTestContractSimpleStruct(a: 7, b: false, c: "sym"),
            BindingsSpecTestContractSimpleEnum.Second
        ))
        let complexTupleResult = try await contract.complex(complex: .Tuple(tupleStruct))
        guard case .Tuple(let returnedTupleStruct) = complexTupleResult else {
            XCTFail("expected ComplexEnum.Tuple")
            return
        }
        XCTAssertEqual(7, returnedTupleStruct.value.0.a)
        XCTAssertFalse(returnedTupleStruct.value.0.b)
        XCTAssertEqual("sym", returnedTupleStruct.value.0.c)
        guard case .Second = returnedTupleStruct.value.1 else {
            XCTFail("expected SimpleEnum.Second inside tuple")
            return
        }
        print("union tuple case round-trip passed")

        // union round-trip: Asset(Address, i128) case
        let assetAddress = try SCAddressXDR(accountId: sourceAccountKeyPair.accountId)
        let assetAmount = "170141183460469231731687303715884105727" // i128 max
        let complexAssetResult = try await contract.complex(complex: .Asset(assetAddress, assetAmount))
        guard case .Asset(let returnedAddress, let returnedAmount) = complexAssetResult else {
            XCTFail("expected ComplexEnum.Asset")
            return
        }
        XCTAssertEqual(sourceAccountKeyPair.accountId, returnedAddress.accountId)
        XCTAssertEqual(assetAmount, returnedAmount)
        print("union Asset(Address,i128) case round-trip passed")

        // error-enum returning method: odd succeeds, even fails
        let oddResult = try await contract.u32FailOnEven(u32_: 7)
        XCTAssertEqual(7, oddResult)
        print("u32_fail_on_even odd input passed: \(oddResult)")

        do {
            let _ = try await contract.u32FailOnEven(u32_: 8)
            XCTFail("u32_fail_on_even should have failed for an even input")
        } catch let AssembledTransactionError.simulationFailed(message) {
            // The contract returns Err(NumberMustBeOdd = 1) for even input; the host
            // surfaces this as Error(Contract, #1) inside the simulation failure message.
            // Asserting the specific code ensures an unrelated failure cannot pass here.
            XCTAssertTrue(message.contains("Error(Contract, #1)"),
                          "expected NumberMustBeOdd (Error(Contract, #1)) in simulation failure, got: \(message)")
            print("u32_fail_on_even even input failed as expected: \(message)")
        }

        // keyword-named method: void
        try await contract.void()
        print("keyword-named void method passed")

        // keyword-named method: from
        let fromResult = try await contract.from(finally: "keyword")
        XCTAssertEqual("keyword", fromResult)
        print("keyword-named from method passed: \(fromResult)")

        // address round-trip
        let addressValue = try SCAddressXDR(accountId: sourceAccountKeyPair.accountId)
        let addressResult = try await contract.address(address: addressValue)
        XCTAssertEqual(sourceAccountKeyPair.accountId, addressResult.accountId)
        print("address round-trip passed: \(String(describing: addressResult.accountId))")

        // muxed address round-trip (an M-address encodes as SC_ADDRESS_TYPE_MUXED_ACCOUNT)
        let muxedAccount = try MuxedAccount(accountId: sourceAccountKeyPair.accountId, id: 123456789)
        let muxedValue = try SCAddressXDR(accountId: muxedAccount.accountId)
        let muxedResult = try await contract.muxedAddress(address: muxedValue)
        XCTAssertEqual(muxedAccount.accountId, muxedResult.accountId)
        print("muxed address round-trip passed: \(String(describing: muxedResult.accountId))")

        // 128-bit integers at the type extremes (decimal strings end to end)
        let i128Min = "-170141183460469231731687303715884105728"
        let i128Result = try await contract.i128(i128: i128Min)
        XCTAssertEqual(i128Min, i128Result)
        print("i128 min round-trip passed")

        let u128Max = "340282366920938463463374607431768211455"
        let u128Result = try await contract.u128(u128: u128Max)
        XCTAssertEqual(u128Max, u128Result)
        print("u128 max round-trip passed")

        // integer-discriminant enum (RoyalCard: Jack=11, Queen=12, King=13). This
        // exercises the u32-rawValue enum conversion path.
        let cardResult = try await contract.card(card: .Queen)
        XCTAssertEqual(BindingsSpecTestContractRoyalCard.Queen, cardResult)
        print("card (RoyalCard.Queen) round-trip passed: \(cardResult)")

        // vec<u32> collection
        let vecValue: [UInt32] = [1, 2, 3, 4294967295]
        let vecResult = try await contract.vec(vec: vecValue)
        XCTAssertEqual(vecValue, vecResult)
        print("vec<u32> round-trip passed: \(vecResult)")

        // u256 maximum (2^256 - 1)
        let u256Max = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        let u256Result = try await contract.u256(u256: u256Max)
        XCTAssertEqual(u256Max, u256Result)
        print("u256 max round-trip passed: \(u256Result)")

        // i256 minimum (-2^255)
        let i256Min = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
        let i256Result = try await contract.i256(i256: i256Min)
        XCTAssertEqual(i256Min, i256Result)
        print("i256 min round-trip passed: \(i256Result)")

        print("=== testBindingsSpecTestContractBindings completed successfully ===")
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
