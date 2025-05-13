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

    let testnetServerUrl = "https://soroban-testnet.stellar.org"
    let helloContractFileName = "soroban_hello_world_contract"
    let authContractFileName = "soroban_auth_contract"
    let swapContractFilename = "soroban_atomic_swap_contract"
    let tokenContractFilename = "soroban_token_contract"
    var sdk = StellarSDK.testNet()
    let network = Network.testnet
    var sourceAccountKeyPair:KeyPair!

    
    override func setUp() async throws {
        sourceAccountKeyPair = try KeyPair.generateRandomKeyPair()
        print("Signer seed: \(String(describing: sourceAccountKeyPair.secretSeed))")
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountKeyPair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountKeyPair.accountId)")
        }
    }

    func testAll() async throws {
        try await helloContractTest()
        try await authContractTest()
        try await atomicSwapTest()
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
        
        var invokerAddress = try SCAddressXDR(accountId: sourceAccountKeyPair.accountId)
        var args = [SCValXDR.address(invokerAddress), SCValXDR.u32(3)]
        let result = try await client.invokeMethod(name: methodName, args: args)
        XCTAssertEqual(3, result.u32)
        
        // submitter and invoker use are NOT the same
        // we need to sign the auth entry
        
        let invokerKeyPair = try KeyPair.generateRandomKeyPair()
        await fundTestnetAccount(accountId: invokerKeyPair.accountId)
        
        invokerAddress = try SCAddressXDR(accountId: invokerKeyPair.accountId)
        args = [SCValXDR.address(invokerAddress), SCValXDR.u32(4)]
        
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
        let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
        
        let swapContractWasmHash = try await installContract(fileName: swapContractFilename)
        print("Installed swap contract wasm hash: \(swapContractWasmHash)")
        
        let tokenContractWasmHash = try await installContract(fileName: tokenContractFilename)
        print("Installed token contract wasm hash: \(tokenContractWasmHash)")
        
        let adminKeyPair = try KeyPair.generateRandomKeyPair()
        let aliceKeyPair = try KeyPair.generateRandomKeyPair()
        let aliceId = aliceKeyPair.accountId
        let bobKeyPair = try KeyPair.generateRandomKeyPair()
        let bobId = bobKeyPair.accountId
        
        await fundTestnetAccount(accountId: adminKeyPair.accountId)
        await fundTestnetAccount(accountId: aliceId)
        await fundTestnetAccount(accountId: bobId)
        
        let atomicSwapClient = try await deployContract(wasmHash: swapContractWasmHash)
        print("Deployed swap contract contract id: \(atomicSwapClient.contractId)")
        
        let tokenAClient = try await deployContract(wasmHash: tokenContractWasmHash)
        let tokenAContractId = tokenAClient.contractId
        print("Deployed token A contract contract id: \(tokenAContractId)")
        
        let tokenBClient = try await deployContract(wasmHash: tokenContractWasmHash)
        let tokenBContractId = tokenBClient.contractId
        print("Deployed token B contract contract id: \(tokenBContractId)")
        
        try await createToken(tokenClient: tokenAClient, submitterKeyPair: adminKeyPair, name: "TokenA", symbol: "TokenA")
        try await createToken(tokenClient: tokenBClient, submitterKeyPair: adminKeyPair, name: "TokenB", symbol: "TokenB")
        print("Tokens created")
        
        try await mint(tokenClient: tokenAClient, adminKp: adminKeyPair, toAccountId: aliceId, amount: 10000000000000)
        try await mint(tokenClient: tokenBClient, adminKp: adminKeyPair, toAccountId: bobId, amount: 10000000000000)
        print("Alice and Bob funded")
        
        let aliceTokenABalance = try await readBalance(forAccountId: aliceId, tokenClient: tokenAClient)
        XCTAssertEqual(10000000000000, aliceTokenABalance)
        
        let bobTokenBBalance = try await readBalance(forAccountId: bobId, tokenClient: tokenBClient)
        XCTAssertEqual(10000000000000, bobTokenBBalance)

        let amountA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
        let minBForA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 4500))
        
        let amountB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5000))
        let minAForB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 950))
        
        let swapMethodName = "swap"
        
        let args:[SCValXDR] = [try SCValXDR.address(SCAddressXDR(accountId: aliceId)),
                    try SCValXDR.address(SCAddressXDR(accountId: bobId)),
                    try SCValXDR.address(SCAddressXDR(contractId: tokenAContractId)),
                    try SCValXDR.address(SCAddressXDR(contractId: tokenBContractId)),
                    amountA,
                    minBForA,
                    amountB,
                    minAForB
        ]
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
    }
    
    func createToken(tokenClient:SorobanClient, submitterKeyPair:KeyPair, name:String, symbol:String) async throws {
        // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
        let submitterId = submitterKeyPair.accountId
        let adminAddress = SCValXDR.address(try SCAddressXDR(accountId: submitterId))
        let methodName = "initialize"
        let tokenName = SCValXDR.string(name)
        let tokenSymbol = SCValXDR.string(symbol)
        let args = [adminAddress, SCValXDR.u32(8), tokenName, tokenSymbol]
        let _ = try await tokenClient.invokeMethod(name: methodName, args: args)
        
    }
    
    func mint(tokenClient:SorobanClient, adminKp:KeyPair, toAccountId:String, amount:UInt64) async throws {
        // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
        
        let methodName = "mint"
        
        let toAddress = SCValXDR.address(try SCAddressXDR(accountId: toAccountId))
        let amountValue = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: amount))
        
        let args = [toAddress, amountValue]
        let tx = try await tokenClient.buildInvokeMethodTx(name: methodName, args: args, enableServerLogging: true)
        try await tx.signAuthEntries(signerKeyPair: adminKp)
        let _ = try await tx.signAndSend()
    }
    
    func readBalance(forAccountId:String, tokenClient:SorobanClient) async throws -> UInt64 {
        // see https://soroban.stellar.org/docs/reference/interfaces/token-interface

        let address = SCValXDR.address(try SCAddressXDR(accountId: forAccountId))
        let methodName = "balance"
        let args = [address]
        
        let resultValue = try await tokenClient.invokeMethod(name: methodName, args: args)
        guard let res = resultValue.i128?.lo else {
            XCTFail("invalid response from get token balance request for account:\(forAccountId)")
            return 0
        }
        return res
        
    }
    
    func installContract(fileName:String) async throws -> String {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: fileName, ofType: "wasm") else {
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
    
    func deployContract(wasmHash:String) async throws -> SorobanClient {
        let deployRequest = DeployRequest(rpcUrl: testnetServerUrl,
                                          network: network,
                                          sourceAccountKeyPair: sourceAccountKeyPair,
                                          wasmHash: wasmHash,
                                          enableServerLogging: true)
        
        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }
    
    func fundTestnetAccount(accountId:String) async {
        let responseEnum = await sdk.accounts.createTestAccount(accountId: accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"fundTestnetAccount(\(accountId))", horizonRequestError: error)
            XCTFail("could not create test account: \(accountId)")
        }
    }
}
