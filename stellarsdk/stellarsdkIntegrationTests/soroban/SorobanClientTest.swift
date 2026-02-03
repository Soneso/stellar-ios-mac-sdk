//
//  SorobanClientTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class SorobanClientTest: XCTestCase {
    static let testOn = "testnet" // "futurenet"
    let testnetServerUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    let helloContractFileName = "soroban_hello_world_contract"
    let authContractFileName = "soroban_auth_contract"
    let swapContractFilename = "soroban_atomic_swap_contract"
    let tokenContractFilename = "soroban_token_contract"
    var sourceAccountKeyPair:KeyPair!

    
    override func setUp() async throws {
        sourceAccountKeyPair = try KeyPair.generateRandomKeyPair()
        print("Signer seed: \(String(describing: sourceAccountKeyPair.secretSeed))")
        let testAccountId = sourceAccountKeyPair.accountId
        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountKeyPair.accountId)")
        }
    }

    func testContracts() async throws {
        try await helloContractTest()
        try await authContractTest()
        try await atomicSwapTest()
        
        // Test with generated bindings
        try await helloContractBindingTest()
        try await authContractBindingTest()
        try await atomicSwapBindingTest()
    }
    
    func testNativeToXdrSCVal() throws {
        let spec = ContractSpec(entries: [])
        let keyPair = try KeyPair.generateRandomKeyPair()
        let accountId = keyPair.accountId
        let contractId = "CCCZVCWISWKWZ3NNH737WGOVCDUI3P776QE3ZM7AUWMJKQBHCPW7NW3D"
        
        // Test void
        let voidVal = try spec.nativeToXdrSCVal(val: nil, ty: SCSpecTypeDefXDR.void)
        XCTAssertEqual(SCValType.void.rawValue, voidVal.type())
        
        // Test address - account ID
        let accountAddressVal = try spec.nativeToXdrSCVal(val: accountId, ty: SCSpecTypeDefXDR.address)
        XCTAssertEqual(SCValType.address.rawValue, accountAddressVal.type())
        
        // Test address - contract ID
        let contractAddressVal = try spec.nativeToXdrSCVal(val: contractId, ty: SCSpecTypeDefXDR.address)
        XCTAssertEqual(SCValType.address.rawValue, contractAddressVal.type())
        
        // Test vector
        let vecType = SCSpecTypeVecXDR(elementType: SCSpecTypeDefXDR.symbol)
        let vecTypeDefType = SCSpecTypeDefXDR.vec(vecType)
        let vecVal = try spec.nativeToXdrSCVal(val: ["a", "b"], ty: vecTypeDefType)
        XCTAssertEqual(SCValType.vec.rawValue, vecVal.type())
        XCTAssertEqual(2, vecVal.vec?.count)
        
        // Test map
        let mapType = SCSpecTypeMapXDR(keyType: SCSpecTypeDefXDR.string, valueType: SCSpecTypeDefXDR.address)
        let mapTypeDefType = SCSpecTypeDefXDR.map(mapType)
        let mapVal = try spec.nativeToXdrSCVal(val: ["a": accountId, "b": contractId], ty: mapTypeDefType)
        XCTAssertEqual(SCValType.map.rawValue, mapVal.type())
        XCTAssertEqual(2, mapVal.map?.count)
        
        // Test tuple
        let tupleType = SCSpecTypeTupleXDR(valueTypes: [SCSpecTypeDefXDR.string, SCSpecTypeDefXDR.bool])
        let tupleTypeDefType = SCSpecTypeDefXDR.tuple(tupleType)
        let tupleVal = try spec.nativeToXdrSCVal(val: ["a", true], ty: tupleTypeDefType)
        XCTAssertEqual(SCValType.vec.rawValue, tupleVal.type())
        XCTAssertEqual(2, tupleVal.vec?.count)
        
        // Test numbers
        let u32Val = try spec.nativeToXdrSCVal(val: 12, ty: SCSpecTypeDefXDR.u32)
        XCTAssertEqual(SCValType.u32.rawValue, u32Val.type())
        XCTAssertEqual(12, u32Val.u32)
        
        let i32Val = try spec.nativeToXdrSCVal(val: -12, ty: SCSpecTypeDefXDR.i32)
        XCTAssertEqual(SCValType.i32.rawValue, i32Val.type())
        XCTAssertEqual(-12, i32Val.i32)
        
        let u64Val = try spec.nativeToXdrSCVal(val: 112, ty: SCSpecTypeDefXDR.u64)
        XCTAssertEqual(SCValType.u64.rawValue, u64Val.type())
        XCTAssertEqual(112, u64Val.u64)
        
        let i64Val = try spec.nativeToXdrSCVal(val: -112, ty: SCSpecTypeDefXDR.i64)
        XCTAssertEqual(SCValType.i64.rawValue, i64Val.type())
        XCTAssertEqual(-112, i64Val.i64)
        
        // Test 128-bit numbers - Int values
        let u128Val = try spec.nativeToXdrSCVal(val: 1112, ty: SCSpecTypeDefXDR.u128)
        XCTAssertEqual(SCValType.u128.rawValue, u128Val.type())
        XCTAssertEqual(1112, u128Val.u128?.lo)
        
        let i128Val = try spec.nativeToXdrSCVal(val: 2112, ty: SCSpecTypeDefXDR.i128)
        XCTAssertEqual(SCValType.i128.rawValue, i128Val.type())
        XCTAssertEqual(2112, i128Val.i128?.lo)
        
        // Test negative values for signed 128-bit
        let i128NegVal = try spec.nativeToXdrSCVal(val: -1234, ty: SCSpecTypeDefXDR.i128)
        XCTAssertEqual(SCValType.i128.rawValue, i128NegVal.type())
        XCTAssertEqual("-1234", i128NegVal.i128String)
        
        // Test 256-bit numbers - Int values  
        let u256Val = try spec.nativeToXdrSCVal(val: 3112, ty: SCSpecTypeDefXDR.u256)
        XCTAssertEqual(SCValType.u256.rawValue, u256Val.type())
        XCTAssertEqual(3112, u256Val.u256?.loLo)
        
        let i256Val = try spec.nativeToXdrSCVal(val: 3112, ty: SCSpecTypeDefXDR.i256)
        XCTAssertEqual(SCValType.i256.rawValue, i256Val.type())
        XCTAssertEqual(3112, i256Val.i256?.loLo)
        
        // Test negative values for signed 256-bit
        let i256NegVal = try spec.nativeToXdrSCVal(val: -5678, ty: SCSpecTypeDefXDR.i256)
        XCTAssertEqual(SCValType.i256.rawValue, i256NegVal.type())
        XCTAssertEqual("-5678", i256NegVal.i256String)
        
        // Test big numbers with String values
        // Test u128 with large string value
        let u128StrVal = try spec.nativeToXdrSCVal(val: "340282366920938463463374607431768211455", ty: SCSpecTypeDefXDR.u128)
        XCTAssertEqual(SCValType.u128.rawValue, u128StrVal.type())
        XCTAssertEqual("340282366920938463463374607431768211455", u128StrVal.u128String)
        
        // Test i128 with negative string value
        let i128NegStrVal = try spec.nativeToXdrSCVal(val: "-170141183460469231731687303715884105728", ty: SCSpecTypeDefXDR.i128)
        XCTAssertEqual(SCValType.i128.rawValue, i128NegStrVal.type())
        XCTAssertEqual("-170141183460469231731687303715884105728", i128NegStrVal.i128String)
        
        // Test u256 with large string value
        let u256StrVal = try spec.nativeToXdrSCVal(val: "115792089237316195423570985008687907853269984665640564039457584007913129639935", ty: SCSpecTypeDefXDR.u256)
        XCTAssertEqual(SCValType.u256.rawValue, u256StrVal.type())
        XCTAssertEqual("115792089237316195423570985008687907853269984665640564039457584007913129639935", u256StrVal.u256String)
        
        // Test i256 with negative string value
        let i256NegStrVal = try spec.nativeToXdrSCVal(val: "-57896044618658097711785492504343953926634992332820282019728792003956564819968", ty: SCSpecTypeDefXDR.i256)
        XCTAssertEqual(SCValType.i256.rawValue, i256NegStrVal.type())
        XCTAssertEqual("-57896044618658097711785492504343953926634992332820282019728792003956564819968", i256NegStrVal.i256String)
        
        // Test big numbers with Data values
        // Test u128 with Data
        let u128Data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10])
        let u128DataVal = try spec.nativeToXdrSCVal(val: u128Data, ty: SCSpecTypeDefXDR.u128)
        XCTAssertEqual(SCValType.u128.rawValue, u128DataVal.type())
        XCTAssertNotNil(u128DataVal.u128String)
        
        // Test i128 with negative Data (two's complement)
        let i128NegData = Data([0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF9, 0xF8, 0xF7, 0xF6, 0xF5, 0xF4, 0xF3, 0xF2, 0xF1, 0xF0])
        let i128NegDataVal = try spec.nativeToXdrSCVal(val: i128NegData, ty: SCSpecTypeDefXDR.i128)
        XCTAssertEqual(SCValType.i128.rawValue, i128NegDataVal.type())
        XCTAssertNotNil(i128NegDataVal.i128String)
        
        // Test u256 with Data
        let u256Data = Data(Array(repeating: UInt8(0x11), count: 32))
        let u256DataVal = try spec.nativeToXdrSCVal(val: u256Data, ty: SCSpecTypeDefXDR.u256)
        XCTAssertEqual(SCValType.u256.rawValue, u256DataVal.type())
        XCTAssertNotNil(u256DataVal.u256String)
        
        // Test i256 with negative Data
        let i256NegData = Data(Array(repeating: UInt8(0x88), count: 32))
        let i256NegDataVal = try spec.nativeToXdrSCVal(val: i256NegData, ty: SCSpecTypeDefXDR.i256)
        XCTAssertEqual(SCValType.i256.rawValue, i256NegDataVal.type())
        XCTAssertNotNil(i256NegDataVal.i256String)
        
        // Test small Data values (should be padded)
        let smallData = Data([0x01, 0x02])
        let u128SmallDataVal = try spec.nativeToXdrSCVal(val: smallData, ty: SCSpecTypeDefXDR.u128)
        XCTAssertEqual(SCValType.u128.rawValue, u128SmallDataVal.type())
        XCTAssertEqual("258", u128SmallDataVal.u128String) // 0x0102 = 256 + 2 = 258
        
        // Test empty Data
        let emptyData = Data()
        let u128EmptyDataVal = try spec.nativeToXdrSCVal(val: emptyData, ty: SCSpecTypeDefXDR.u128)
        XCTAssertEqual(SCValType.u128.rawValue, u128EmptyDataVal.type())
        XCTAssertEqual("0", u128EmptyDataVal.u128String)
        
        // Test zero string
        let u128ZeroStrVal = try spec.nativeToXdrSCVal(val: "0", ty: SCSpecTypeDefXDR.u128)
        XCTAssertEqual(SCValType.u128.rawValue, u128ZeroStrVal.type())
        XCTAssertEqual("0", u128ZeroStrVal.u128String)
        
        // Test error cases - negative value for unsigned types
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: -1, ty: SCSpecTypeDefXDR.u128)) { error in
            XCTAssertTrue(error is ContractSpecError)
        }
        
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: -1, ty: SCSpecTypeDefXDR.u256)) { error in
            XCTAssertTrue(error is ContractSpecError)
        }
        
        // Test error case - invalid string format
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: "not_a_number", ty: SCSpecTypeDefXDR.u128)) { error in
            XCTAssertTrue(error is StellarSDKError)
        }
        
        // Test error case - Data too large
        let tooLargeData = Data(Array(repeating: UInt8(0xFF), count: 33))
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: tooLargeData, ty: SCSpecTypeDefXDR.u256)) { error in
            XCTAssertTrue(error is StellarSDKError)
        }
        
        // Test strings
        let bytesVal = try spec.nativeToXdrSCVal(val: keyPair.publicKey.accountId, ty: SCSpecTypeDefXDR.bytes)
        XCTAssertEqual(SCValType.bytes.rawValue, bytesVal.type())
        
        let stringVal = try spec.nativeToXdrSCVal(val: "hello this is a text", ty: SCSpecTypeDefXDR.string)
        XCTAssertEqual(SCValType.string.rawValue, stringVal.type())
        
        let symbolVal = try spec.nativeToXdrSCVal(val: "XLM", ty: SCSpecTypeDefXDR.symbol)
        XCTAssertEqual(SCValType.symbol.rawValue, symbolVal.type())
        
        // Test bool
        let boolVal = try spec.nativeToXdrSCVal(val: false, ty: SCSpecTypeDefXDR.bool)
        XCTAssertEqual(SCValType.bool.rawValue, boolVal.type())
        XCTAssertFalse(boolVal.bool ?? true)
        
        // Test option
        let optionType = SCSpecTypeOptionXDR(valueType: SCSpecTypeDefXDR.string)
        let optionTypeDefType = SCSpecTypeDefXDR.option(optionType)
        let optionSomeVal = try spec.nativeToXdrSCVal(val: "a string", ty: optionTypeDefType)
        XCTAssertEqual(SCValType.string.rawValue, optionSomeVal.type())
        
        let optionNoneVal = try spec.nativeToXdrSCVal(val: nil, ty: optionTypeDefType)
        XCTAssertEqual(SCValType.void.rawValue, optionNoneVal.type())
    }

    func helloContractTest() async throws {
        let helloContractWasmHash = try await installContract(fileName: helloContractFileName)
        print("Installed hello contract wasm hash: \(helloContractWasmHash)")
        
        let client = try await deployContract(wasmHash: helloContractWasmHash)
        print("Deployed hello contract contract id: \(client.contractId)")
        
        let methodNames = client.methodNames
        XCTAssertEqual(1, methodNames.count)
        XCTAssertEqual("hello", methodNames.first)
        
        let result = try await client.invokeMethod(name: "hello", args: [SCValXDR.symbol("John")])
        guard let vec = result.vec else {
            XCTFail("Hello contract invocation result is not a vector")
            return
        }
        
        XCTAssertEqual(2, vec.count)
        guard let firstSym = vec[0].symbol, let secondSym = vec[1].symbol else {
            XCTFail("Hello contract invocation result has unexpected values")
            return
        }
        XCTAssertEqual("Hello, John", "\(firstSym), \(secondSym)")
        
        // contract spec test
        let spec = client.getContractSpec()
        let args = try spec.funcArgsToXdrSCValues(name: "hello", args: ["to": "Maria"])
        XCTAssertEqual(1, args.count)
        let specResult = try await client.invokeMethod(name: "hello", args: args)
        guard let specVec = specResult.vec else {
            XCTFail("Hello contract spec invocation result is not a vector")
            return
        }
        
        XCTAssertEqual(2, specVec.count)
        guard let firstSpecSym = specVec[0].symbol, let secondSpecSym = specVec[1].symbol else {
            XCTFail("Hello contract spec invocation result has unexpected values")
            return
        }
        XCTAssertEqual("Hello, Maria", "\(firstSpecSym), \(secondSpecSym)")
    }
    
    func authContractTest() async throws {
        let authContractWasmHash = try await installContract(fileName: authContractFileName)
        print("Installed auth contract wasm hash: \(authContractWasmHash)")
        
        let deployedClient = try await deployContract(wasmHash: authContractWasmHash)
        print("Deployed auth contract contract id: \(deployedClient.contractId)")
        
        // just a small test to check if it can load by contract id
        
        let client = try await SorobanClient.forClientOptions(options: ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair,
                                                                                     contractId: deployedClient.contractId,
                                                                                     network: network,
                                                                                     rpcUrl: testnetServerUrl))
        XCTAssertEqual(deployedClient.contractId, client.contractId)
        
        let methodName = "increment"
        let methodNames = client.methodNames
        XCTAssertEqual(1, methodNames.count)
        XCTAssertEqual(methodName, methodNames.first)
        
        // submitter and invoker use are the same
        // no need to sign auth
        
        let invokerAccountId = sourceAccountKeyPair.accountId
        let spec = client.getContractSpec()
        var args = try spec.funcArgsToXdrSCValues(name: methodName, args: ["user": invokerAccountId, "value": 3])
        let result = try await client.invokeMethod(name: methodName, args: args)
        XCTAssertEqual(3, result.u32)
        
        // submitter and invoker use are NOT the same
        // we need to sign the auth entry
        
        let invokerKeyPair = try KeyPair.generateRandomKeyPair()
        await fundTestnetAccount(accountId: invokerKeyPair.accountId)
        
        let newInvokerAccountId = invokerKeyPair.accountId
        args = try spec.funcArgsToXdrSCValues(name: methodName, args: ["user": newInvokerAccountId, "value": 4])
        
        do {
            let _ = try await client.invokeMethod(name: methodName, args: args)
            XCTFail("should not reach due to missing signature")
        } catch {}
        
        let tx = try await client.buildInvokeMethodTx(name: methodName, args: args, enableServerLogging: true)
        try await tx.signAuthEntries(signerKeyPair: invokerKeyPair)
  
        let response = try await tx.signAndSend()
        guard let authResult = response.resultValue else {
            XCTFail("no result value from auth contract invocation")
            return
        }
        XCTAssertEqual(4, authResult.u32)
    }
    
    func atomicSwapTest() async throws {
        
        let swapContractWasmHash = try await installContract(fileName: swapContractFilename)
        print("Installed swap contract wasm hash: \(swapContractWasmHash)")
        
        let tokenContractWasmHash = try await installContract(fileName: tokenContractFilename)
        print("Installed token contract wasm hash: \(tokenContractWasmHash)")
        
        let adminKeyPair = try KeyPair.generateRandomKeyPair()
        let adminAccountId = adminKeyPair.accountId
        let aliceKeyPair = try KeyPair.generateRandomKeyPair()
        let aliceId = aliceKeyPair.accountId
        let bobKeyPair = try KeyPair.generateRandomKeyPair()
        let bobId = bobKeyPair.accountId
        
        await fundTestnetAccount(accountId: adminAccountId)
        await fundTestnetAccount(accountId: aliceId)
        await fundTestnetAccount(accountId: bobId)
        
        let atomicSwapClient = try await deployContract(wasmHash: swapContractWasmHash)
        print("Deployed swap contract contract id: \(atomicSwapClient.contractId)")
        
        var tokenName = SCValXDR.string("TokenA")
        var tokenSymbol = SCValXDR.string("TokenA")
        let decimal = SCValXDR.u32(8)
        let adminAddress = try SCAddressXDR(accountId: adminKeyPair.accountId)
        let adminAddressScVal = SCValXDR.address(adminAddress)
        
        let tokenAClient = try await deployContract(wasmHash: tokenContractWasmHash,
                                                    constructorArgs: [adminAddressScVal, decimal, tokenName, tokenSymbol])
        let tokenAContractId = tokenAClient.contractId
        print("Deployed token A contract contract id: \(tokenAContractId)")
        
        tokenName = SCValXDR.string("TokenB")
        tokenSymbol = SCValXDR.string("TokenB")
        
        let tokenBClient = try await deployContract(wasmHash: tokenContractWasmHash,
                                                    constructorArgs: [adminAddressScVal, decimal, tokenName, tokenSymbol])
        let tokenBContractId = tokenBClient.contractId
        print("Deployed token B contract contract id: \(tokenBContractId)")
        
        try await mint(tokenClient: tokenAClient, adminKp: adminKeyPair, toAccountId: aliceId, amount: 10000000000000)
        try await mint(tokenClient: tokenBClient, adminKp: adminKeyPair, toAccountId: bobId, amount: 10000000000000)
        print("Alice and Bob funded")
        
        let aliceTokenABalance = try await readBalance(forAccountId: aliceId, tokenClient: tokenAClient)
        XCTAssertEqual(10000000000000, aliceTokenABalance)
        
        let bobTokenBBalance = try await readBalance(forAccountId: bobId, tokenClient: tokenBClient)
        XCTAssertEqual(10000000000000, bobTokenBBalance)

        let swapMethodName = "swap"
        
        let spec = atomicSwapClient.getContractSpec()
        let args = try spec.funcArgsToXdrSCValues(name: swapMethodName, args: [
            "a": aliceId,
            "b": bobId,
            "token_a": tokenAContractId,
            "token_b": tokenBContractId,
            "amount_a": 1000,
            "min_b_for_a": 4500,
            "amount_b": 5000,
            "min_a_for_b": 950
        ])
        try! await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
        let tx = try await atomicSwapClient.buildInvokeMethodTx(name: swapMethodName, args: args, enableServerLogging: true)
        let whoElseNeedsToSign = try tx.needsNonInvokerSigningBy()
        XCTAssertEqual(2, whoElseNeedsToSign.count)
        XCTAssert(whoElseNeedsToSign.contains(aliceId))
        XCTAssert(whoElseNeedsToSign.contains(bobId))
        
        try await tx.signAuthEntries(signerKeyPair: aliceKeyPair)
        print("Signed by Alice")
        
        // test signing via callback
        let bobPublicKeyKeypair = try KeyPair(accountId: bobId)
        try await tx.signAuthEntries(signerKeyPair: bobPublicKeyKeypair, authorizeEntryCallback: { (entry, network) async throws in
            print("Bob is signing")
            // You can send it to some other server for signing by encoding it as a base64xdr string
            let base64Entry = entry.xdrEncoded!
            // send for signing ...
            // and on the other server you can decode it:
            var entryToSign = try SorobanAuthorizationEntryXDR.init(fromBase64: base64Entry)
            // sign it
            try entryToSign.sign(signer: bobKeyPair, network: network)
            // encode as a base64xdr string and send it back
            let signedBase64Entry = entryToSign.xdrEncoded!
            print("Bob signed")
            // here you can now decode it and return it
            return try SorobanAuthorizationEntryXDR.init(fromBase64: signedBase64Entry)
        })
        print("Signed by Bob")
        
        let response = try await tx.signAndSend()
        guard let result = response.resultValue else {
            XCTFail("no result obtained for invoking swap")
            return
        }
        XCTAssertEqual(SCValType.void.rawValue, result.type())
        print("Swap done")
        
        // small spec functions test
        let tokenSpec = tokenAClient.getContractSpec()
        let functions = tokenSpec.funcs()
        XCTAssertEqual(13, functions.count)
        let mintFunc = tokenSpec.getFunc(name: "mint")
        XCTAssertNotNil(mintFunc)
        XCTAssertEqual("mint", mintFunc?.name)
    }
    
    func mint(tokenClient:SorobanClient, adminKp:KeyPair, toAccountId:String, amount:UInt64) async throws {
        // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
        
        let methodName = "mint"
        let spec = tokenClient.getContractSpec()
        let args = try spec.funcArgsToXdrSCValues(name: methodName, args: [
            "to": toAccountId,
            "amount": Int(amount)
        ])
        let tx = try await tokenClient.buildInvokeMethodTx(name: methodName, args: args, enableServerLogging: true)
        try await tx.signAuthEntries(signerKeyPair: adminKp)
        let _ = try await tx.signAndSend()
    }
    
    func readBalance(forAccountId:String, tokenClient:SorobanClient) async throws -> UInt64 {
        // see https://soroban.stellar.org/docs/reference/interfaces/token-interface

        let methodName = "balance"
        let spec = tokenClient.getContractSpec()
        let args = try spec.funcArgsToXdrSCValues(name: methodName, args: [
            "id": forAccountId
        ])
        
        let resultValue = try await tokenClient.invokeMethod(name: methodName, args: args)
        guard let res = resultValue.i128?.lo else {
            XCTFail("invalid response from get token balance request for account:\(forAccountId)")
            return 0
        }
        return res
        
    }
    
    func installContract(fileName:String) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm") else {
            // File not found
            XCTFail("File \(fileName).wasm not found.")
            return ""
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            // File not found
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
    
    func deployContract(wasmHash:String, constructorArgs: [SCValXDR]? = nil) async throws -> SorobanClient {
        let deployRequest = DeployRequest(rpcUrl: testnetServerUrl,
                                          network: network,
                                          sourceAccountKeyPair: sourceAccountKeyPair,
                                          wasmHash: wasmHash,
                                          constructorArgs: constructorArgs,
                                          enableServerLogging: true)
        
        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }
    
    func fundTestnetAccount(accountId:String) async {
        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: accountId) : await sdk.accounts.createFutureNetTestAccount(accountId: accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"fundTestnetAccount(\(accountId))", horizonRequestError: error)
            XCTFail("could not create test account: \(accountId)")
        }
    }
    
    // MARK: - Generated Binding Tests
    
    func helloContractBindingTest() async throws {
        print("=== Starting helloContractBindingTest ===")
        
        let helloContractWasmHash = try await installContract(fileName: helloContractFileName)
        print("Installed hello contract wasm hash: \(helloContractWasmHash)")
        
        let client = try await deployContract(wasmHash: helloContractWasmHash)
        let contractId = client.contractId
        print("Deployed hello contract contract id: \(contractId)")
        
        // Test with generated binding
        let clientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair, contractId: contractId, network: network, rpcUrl: testnetServerUrl)
        let helloContract = try await HelloContract.forClientOptions(options: clientOptions)
        
        // Test the hello method
        let result: [String] = try await helloContract.hello(to: "World")
        XCTAssertEqual(2, result.count)
        XCTAssertEqual("Hello", result[0])
        XCTAssertEqual("World", result[1])
        print("HelloContract binding test passed with result: \(result[0]), \(result[1])")
        
        // Test with different name
        let result2: [String] = try await helloContract.hello(to: "Stellar")
        XCTAssertEqual(2, result2.count)
        XCTAssertEqual("Hello", result2[0])
        XCTAssertEqual("Stellar", result2[1])
        print("HelloContract binding test passed with result: \(result2[0]), \(result2[1])")
    }
    
    func authContractBindingTest() async throws {
        print("=== Starting authContractBindingTest ===")
        
        let authContractWasmHash = try await installContract(fileName: authContractFileName)
        print("Installed auth contract wasm hash: \(authContractWasmHash)")
        
        let deployedClient = try await deployContract(wasmHash: authContractWasmHash)
        let contractId = deployedClient.contractId
        print("Deployed auth contract contract id: \(contractId)")
        
        // Test with generated binding
        let clientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair, contractId: contractId, network: network, rpcUrl: testnetServerUrl)
        let authContract = try await AuthContract.forClientOptions(options: clientOptions)
        
        // Test when submitter and invoker are the same - no auth signing needed
        let invokerAccountId = sourceAccountKeyPair.accountId
        let userAddress = try SCAddressXDR(accountId: invokerAccountId)
        
        let result1 = try await authContract.increment(user: userAddress, value: 10)
        XCTAssertEqual(10, result1)
        print("AuthContract binding test (same invoker) passed with result: \(result1)")
        
        let result2 = try await authContract.increment(user: userAddress, value: 5)
        XCTAssertEqual(15, result2) // 10 + 5
        print("AuthContract binding test (cumulative) passed with result: \(result2)")
        
        // Test when submitter and invoker are different - need auth signing
        let differentInvokerKeyPair = try KeyPair.generateRandomKeyPair()
        await fundTestnetAccount(accountId: differentInvokerKeyPair.accountId)
        
        let differentInvokerAddress = try SCAddressXDR(accountId: differentInvokerKeyPair.accountId)
        
        // First try without signing - should fail
        do {
            let _ = try await authContract.increment(user: differentInvokerAddress, value: 7)
            XCTFail("Should have failed due to missing signature")
        } catch {
            print("Expected failure due to missing signature: \(error)")
        }
        
        // Now build transaction and sign auth entries
        let tx = try await authContract.buildIncrementTx(user: differentInvokerAddress, value: 7)
        try await tx.signAuthEntries(signerKeyPair: differentInvokerKeyPair)
        
        let response = try await tx.signAndSend()
        guard let authResult = response.resultValue else {
            XCTFail("No result value from auth contract invocation")
            return
        }
        XCTAssertEqual(7, authResult.u32)
        print("AuthContract binding test (different invoker with auth) passed with result: \(authResult.u32 ?? 0)")
    }
    
    func atomicSwapBindingTest() async throws {
        print("=== Starting atomicSwapBindingTest ===")
        
        // Install contracts
        let swapContractWasmHash = try await installContract(fileName: swapContractFilename)
        print("Installed swap contract wasm hash: \(swapContractWasmHash)")
        
        let tokenContractWasmHash = try await installContract(fileName: tokenContractFilename)
        print("Installed token contract wasm hash: \(tokenContractWasmHash)")
        
        // Create accounts
        let adminKeyPair = try KeyPair.generateRandomKeyPair()
        let adminAccountId = adminKeyPair.accountId
        let aliceKeyPair = try KeyPair.generateRandomKeyPair()
        let aliceId = aliceKeyPair.accountId
        let bobKeyPair = try KeyPair.generateRandomKeyPair()
        let bobId = bobKeyPair.accountId
        
        await fundTestnetAccount(accountId: adminAccountId)
        await fundTestnetAccount(accountId: aliceId)
        await fundTestnetAccount(accountId: bobId)
        
        // Deploy contracts
        let atomicSwapClient = try await deployContract(wasmHash: swapContractWasmHash)
        let swapContractId = atomicSwapClient.contractId
        print("Deployed swap contract contract id: \(swapContractId)")
        
        var tokenName = SCValXDR.string("TokenA")
        var tokenSymbol = SCValXDR.string("TokenA")
        let decimal = SCValXDR.u32(8)
        let adminAddress = try SCAddressXDR(accountId: adminKeyPair.accountId)
        let adminAddressScVal = SCValXDR.address(adminAddress)
        
        let tokenAClient = try await deployContract(wasmHash: tokenContractWasmHash,
                                                    constructorArgs: [adminAddressScVal, decimal, tokenName, tokenSymbol])
        let tokenAContractId = tokenAClient.contractId
        print("Deployed token A contract contract id: \(tokenAContractId)")
        
        tokenName = SCValXDR.string("TokenB")
        tokenSymbol = SCValXDR.string("TokenB")
        
        let tokenBClient = try await deployContract(wasmHash: tokenContractWasmHash,
                                                    constructorArgs: [adminAddressScVal, decimal, tokenName, tokenSymbol])
        
        let tokenBContractId = tokenBClient.contractId
        print("Deployed token B contract contract id: \(tokenBContractId)")
        
        // Initialize tokens using generated bindings

        let tokenAOptions = ClientOptions(sourceAccountKeyPair: adminKeyPair, contractId: tokenAContractId, network: network, rpcUrl: testnetServerUrl)
        let tokenAContract = try await TokenContract.forClientOptions(options: tokenAOptions)
        
        let tokenBOptions = ClientOptions(sourceAccountKeyPair: adminKeyPair, contractId: tokenBContractId, network: network, rpcUrl: testnetServerUrl)
        let tokenBContract = try await TokenContract.forClientOptions(options: tokenBOptions)
        
        // Mint tokens to Alice and Bob
        let aliceAddress = try SCAddressXDR(accountId: aliceId)
        let bobAddress = try SCAddressXDR(accountId: bobId)
        
        // Build mint transactions with auth signing
        let mintToAliceTx = try await tokenAContract.buildMintTx(to: aliceAddress, amount: "10000000000000")
        try await mintToAliceTx.signAuthEntries(signerKeyPair: adminKeyPair)
        let _ = try await mintToAliceTx.signAndSend()
        
        let mintToBobTx = try await tokenBContract.buildMintTx(to: bobAddress, amount: "10000000000000")
        try await mintToBobTx.signAuthEntries(signerKeyPair: adminKeyPair)
        let _ = try await mintToBobTx.signAndSend()
        print("Alice and Bob funded using bindings")
        
        // Check initial balances
        let aliceInitialBalance = try await tokenAContract.balance(id: aliceAddress)
        XCTAssertEqual("10000000000000", aliceInitialBalance)
        
        let bobInitialBalance = try await tokenBContract.balance(id: bobAddress)
        XCTAssertEqual("10000000000000", bobInitialBalance)
        print("Initial balances verified")
        
        // Perform atomic swap using generated binding
        let swapClientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair, contractId: swapContractId, network: network, rpcUrl: testnetServerUrl)
        let atomicSwapContract = try await AtomicSwapContract.forClientOptions(options: swapClientOptions)
        
        let tokenAAddress = try SCAddressXDR(contractId: tokenAContractId)
        let tokenBAddress = try SCAddressXDR(contractId: tokenBContractId)
        
        // Build swap transaction
        let swapTx = try await atomicSwapContract.buildSwapTx(
            a: aliceAddress,
            b: bobAddress,
            token_a: tokenAAddress,
            token_b: tokenBAddress,
            amount_a: "1000",
            min_b_for_a: "4500",
            amount_b: "5000",
            min_a_for_b: "950"
        )
        
        // Verify who needs to sign
        let signers = try swapTx.needsNonInvokerSigningBy()
        XCTAssertEqual(2, signers.count)
        XCTAssert(signers.contains(aliceId))
        XCTAssert(signers.contains(bobId))
        
        // Sign with Alice and Bob
        try await swapTx.signAuthEntries(signerKeyPair: aliceKeyPair)
        print("Signed by Alice")
        
        try await swapTx.signAuthEntries(signerKeyPair: bobKeyPair)
        print("Signed by Bob")
        
        // Execute swap
        let response = try await swapTx.signAndSend()
        guard let result = response.resultValue else {
            XCTFail("No result obtained for invoking swap")
            return
        }
        XCTAssertEqual(SCValType.void.rawValue, result.type())
        print("Swap executed successfully using bindings!")
        
        // Verify final balances
        let aliceFinalTokenA = try await tokenAContract.balance(id: aliceAddress)
        let aliceFinalTokenB = try await tokenBContract.balance(id: aliceAddress)
        let bobFinalTokenA = try await tokenAContract.balance(id: bobAddress)
        let bobFinalTokenB = try await tokenBContract.balance(id: bobAddress)
        
        print("Final balances:")
        print("  Alice - Token A: \(aliceFinalTokenA)")
        print("  Alice - Token B: \(aliceFinalTokenB)")
        print("  Bob - Token A: \(bobFinalTokenA)")
        print("  Bob - Token B: \(bobFinalTokenB)")
        
        // Verify swap occurred
        XCTAssertNotEqual("10000000000000", aliceFinalTokenA) // Alice spent some token A
        XCTAssertNotEqual("0", aliceFinalTokenB) // Alice received some token B
        XCTAssertNotEqual("0", bobFinalTokenA) // Bob received some token A
        XCTAssertNotEqual("10000000000000", bobFinalTokenB) // Bob spent some token B
        
        print("AtomicSwapContract binding test completed successfully!")
    }
}
