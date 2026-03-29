//
//  SorobanDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//

import XCTest
import stellarsdk

final class SorobanDocTest: XCTestCase {

    let sdk = StellarSDK.testNet()
    let network = Network.testnet
    let rpcUrl = "https://soroban-testnet.stellar.org"
    let helloContractFileName = "soroban_hello_world_contract"
    let tokenContractFileName = "soroban_token_contract"
    let swapContractFileName = "soroban_atomic_swap_contract"
    let authContractFileName = "soroban_auth_contract"
    var sourceAccountKeyPair: KeyPair!

    override func setUp() async throws {
        sourceAccountKeyPair = try KeyPair.generateRandomKeyPair()
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceAccountKeyPair.accountId)
        switch responseEnum {
        case .success(_):
            try! await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(sourceAccountKeyPair.accountId)")
        }
    }

    // MARK: - Quick Start (Snippet 1)

    func testQuickStart() async throws {
        // Install
        let wasmHash = try await installContract(fileName: helloContractFileName)
        XCTAssertFalse(wasmHash.isEmpty)

        // Deploy
        let client = try await deployContract(wasmHash: wasmHash)
        XCTAssertFalse(client.contractId.isEmpty)

        // Invoke
        let result = try await client.invokeMethod(
            name: "hello",
            args: [SCValXDR.symbol("World")]
        )
        guard let vec = result.vec, vec.count == 2 else {
            XCTFail("Expected vector with 2 elements")
            return
        }
        XCTAssertEqual("Hello", vec[0].symbol)
        XCTAssertEqual("World", vec[1].symbol)
    }

    // MARK: - SorobanServer (Snippets 2-9)

    func testConnectToRPC() async {
        // Snippet 2: Connecting to RPC
        let server = SorobanServer(endpoint: rpcUrl)
        server.enableLogging = true
        XCTAssertNotNil(server)
    }

    func testHealthCheck() async {
        // Snippet 3: Health Check
        let server = SorobanServer(endpoint: rpcUrl)
        let healthResponse = await server.getHealth()
        switch healthResponse {
        case .success(let health):
            XCTAssertEqual(HealthStatus.HEALTHY, health.status)
        case .failure(let error):
            XCTFail("Health check failed: \(error)")
        }
    }

    func testNetworkInfo() async {
        // Snippet 4: Network Information
        let server = SorobanServer(endpoint: rpcUrl)
        let networkResponse = await server.getNetwork()
        switch networkResponse {
        case .success(let network):
            XCTAssertFalse(network.passphrase.isEmpty)
            XCTAssert(network.protocolVersion > 0)
        case .failure(let error):
            XCTFail("Network info failed: \(error)")
        }
    }

    func testLatestLedger() async {
        // Snippet 5: Latest Ledger
        let server = SorobanServer(endpoint: rpcUrl)
        let ledgerResponse = await server.getLatestLedger()
        switch ledgerResponse {
        case .success(let ledger):
            XCTAssert(ledger.sequence > 0)
        case .failure(let error):
            XCTFail("Latest ledger failed: \(error)")
        }
    }

    func testAccountData() async {
        // Snippet 6: Account Data
        let server = SorobanServer(endpoint: rpcUrl)
        let accountResponse = await server.getAccount(accountId: sourceAccountKeyPair.accountId)
        switch accountResponse {
        case .success(let account):
            XCTAssertEqual(sourceAccountKeyPair.accountId, account.accountId)
        case .failure(let error):
            XCTFail("Account data failed: \(error)")
        }
    }

    func testContractData() async throws {
        // Snippet 7: Contract Data
        // Deploy a contract first so we can query its instance data
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let server = SorobanServer(endpoint: rpcUrl)
        let contractDataResponse = await server.getContractData(
            contractId: client.contractId,
            key: SCValXDR.ledgerKeyContractInstance,
            durability: ContractDataDurability.persistent
        )
        switch contractDataResponse {
        case .success(let entry):
            XCTAssert(entry.lastModifiedLedgerSeq > 0)
        case .failure(let error):
            XCTFail("Contract data failed: \(error)")
        }
    }

    func testContractInfo() async throws {
        // Snippet 8: Contract Info
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let server = SorobanServer(endpoint: rpcUrl)

        // By contract ID
        let infoResponse = await server.getContractInfoForContractId(contractId: client.contractId)
        switch infoResponse {
        case .success(let info):
            XCTAssert(info.specEntries.count > 0)
        case .rpcFailure(let error):
            XCTFail("RPC error: \(error)")
        case .parsingFailure(let error):
            XCTFail("Parsing error: \(error)")
        }

        // By WASM ID
        let infoResponse2 = await server.getContractInfoForWasmId(wasmId: wasmHash)
        switch infoResponse2 {
        case .success(let info):
            XCTAssert(info.specEntries.count > 0)
        case .rpcFailure(let error):
            XCTFail("RPC error: \(error)")
        case .parsingFailure(let error):
            XCTFail("Parsing error: \(error)")
        }
    }

    func testGetLedgerEntries() async throws {
        // Snippet 9: Get Ledger Entries
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let server = SorobanServer(endpoint: rpcUrl)

        let contractDataKey = LedgerKeyContractDataXDR(
            contract: try SCAddressXDR(contractId: client.contractId),
            key: SCValXDR.ledgerKeyContractInstance,
            durability: ContractDataDurability.persistent
        )
        let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
        let base64Key = ledgerKey.xdrEncoded!

        let entriesResponse = await server.getLedgerEntries(base64EncodedKeys: [base64Key])
        switch entriesResponse {
        case .success(let result):
            XCTAssert(result.entries.count > 0)
        case .failure(let error):
            XCTFail("Ledger entries failed: \(error)")
        }
    }

    // MARK: - Load Contract Code (Snippet 10)

    func testLoadContractCode() async throws {
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let server = SorobanServer(endpoint: rpcUrl)

        // By contract ID
        let codeResponse = await server.getContractCodeForContractId(contractId: client.contractId)
        switch codeResponse {
        case .success(let contractCode):
            XCTAssert(contractCode.code.count > 0)
        case .failure(let error):
            XCTFail("Contract code load failed: \(error)")
        }

        // By WASM ID
        let codeResponse2 = await server.getContractCodeForWasmId(wasmId: wasmHash)
        switch codeResponse2 {
        case .success(let contractCode):
            XCTAssert(contractCode.code.count > 0)
        case .failure(let error):
            XCTFail("Contract code load by wasm id failed: \(error)")
        }
    }

    // MARK: - SorobanClient (Snippets 11-13)

    func testCreateClient() async throws {
        // Snippet 11: Creating a Client
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let deployedClient = try await deployContract(wasmHash: wasmHash)

        let client = try await SorobanClient.forClientOptions(
            options: ClientOptions(
                sourceAccountKeyPair: sourceAccountKeyPair,
                contractId: deployedClient.contractId,
                network: network,
                rpcUrl: rpcUrl
            )
        )
        XCTAssertEqual(deployedClient.contractId, client.contractId)
        let methodNames = client.methodNames
        XCTAssertTrue(methodNames.contains("hello"))
        let spec = client.getContractSpec()
        XCTAssertNotNil(spec)
    }

    func testInvokeMethods() async throws {
        // Snippet 12: Invoking Methods (read-only)
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let result = try await client.invokeMethod(
            name: "hello",
            args: [SCValXDR.symbol("Doc")]
        )
        guard let vec = result.vec, vec.count == 2 else {
            XCTFail("Expected vector result")
            return
        }
        XCTAssertEqual("Hello", vec[0].symbol)
        XCTAssertEqual("Doc", vec[1].symbol)
    }

    func testInvokeWithMethodOptions() async throws {
        // Snippet 13: Invoking with MethodOptions
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let result = try await client.invokeMethod(
            name: "hello",
            args: [SCValXDR.symbol("Options")],
            methodOptions: MethodOptions(
                fee: 10000,
                timeoutInSeconds: 30
            )
        )
        guard let vec = result.vec, vec.count == 2 else {
            XCTFail("Expected vector result with MethodOptions")
            return
        }
        XCTAssertEqual("Hello", vec[0].symbol)
        XCTAssertEqual("Options", vec[1].symbol)
    }

    // MARK: - Installing and Deploying (Snippets 14-15)

    func testInstallation() async throws {
        // Snippet 14: Installation
        let wasmHash = try await installContract(fileName: helloContractFileName)
        XCTAssertFalse(wasmHash.isEmpty)
    }

    func testDeployment() async throws {
        // Snippet 15: Deployment (basic and with constructor)
        let wasmHash = try await installContract(fileName: helloContractFileName)

        // Basic deployment
        let client = try await deployContract(wasmHash: wasmHash)
        XCTAssertFalse(client.contractId.isEmpty)

        // With constructor - deploy a token contract
        let tokenWasmHash = try await installContract(fileName: tokenContractFileName)
        let adminAddress = try SCAddressXDR(accountId: sourceAccountKeyPair.accountId)
        let tokenClient = try await deployContract(
            wasmHash: tokenWasmHash,
            constructorArgs: [
                SCValXDR.address(adminAddress),
                SCValXDR.u32(8),
                SCValXDR.string("TestToken"),
                SCValXDR.string("TT")
            ]
        )
        XCTAssertFalse(tokenClient.contractId.isEmpty)
    }

    // MARK: - AssembledTransaction (Snippets 16-19)

    func testBuildWithoutSubmitting() async throws {
        // Snippet 16: Building Without Submitting
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let tx = try await client.buildInvokeMethodTx(
            name: "hello",
            args: [SCValXDR.symbol("test")]
        )
        XCTAssertNotNil(tx)
    }

    func testAccessSimulationResults() async throws {
        // Snippet 17: Accessing Simulation Results
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let tx = try await client.buildInvokeMethodTx(
            name: "hello",
            args: [SCValXDR.symbol("sim")]
        )

        let simData = try tx.getSimulationData()
        XCTAssertNotNil(simData.returnedValue)
        XCTAssertNotNil(tx.simulationResponse)
    }

    func testReadOnlyVsWrite() async throws {
        // Snippet 18: Read-Only vs Write Calls
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let tx = try await client.buildInvokeMethodTx(
            name: "hello",
            args: [SCValXDR.symbol("check")]
        )

        let isReadCall = try tx.isReadCall()
        if isReadCall {
            let result = try tx.getSimulationData().returnedValue
            XCTAssertNotNil(result)
        }
    }

    func testModifyBeforeSubmission() async throws {
        // Snippet 19: Modifying Before Submission
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let tx = try await client.buildInvokeMethodTx(
            name: "hello",
            args: [SCValXDR.symbol("fee")],
            methodOptions: MethodOptions(simulate: false)
        )

        // Modify the raw transaction (e.g. adjust the fee)
        tx.raw?.setFee(fee: 200_000)

        // Now simulate
        try await tx.simulate()
        XCTAssertNotNil(tx.simulationResponse)
    }

    // MARK: - Authorization (Snippets 20-22)

    func testAuthorizationWorkflow() async throws {
        // Snippets 20-22: Check Who Needs to Sign, Local Signing, Remote Signing
        let swapWasmHash = try await installContract(fileName: swapContractFileName)
        let tokenWasmHash = try await installContract(fileName: tokenContractFileName)

        let adminKeyPair = try KeyPair.generateRandomKeyPair()
        let aliceKeyPair = try KeyPair.generateRandomKeyPair()
        let bobKeyPair = try KeyPair.generateRandomKeyPair()

        await fundAccount(accountId: adminKeyPair.accountId)
        await fundAccount(accountId: aliceKeyPair.accountId)
        await fundAccount(accountId: bobKeyPair.accountId)

        let swapClient = try await deployContract(wasmHash: swapWasmHash)

        let adminAddress = try SCAddressXDR(accountId: adminKeyPair.accountId)
        let tokenAClient = try await deployContract(
            wasmHash: tokenWasmHash,
            constructorArgs: [SCValXDR.address(adminAddress), SCValXDR.u32(8), SCValXDR.string("TokenA"), SCValXDR.string("TA")]
        )
        let tokenBClient = try await deployContract(
            wasmHash: tokenWasmHash,
            constructorArgs: [SCValXDR.address(adminAddress), SCValXDR.u32(8), SCValXDR.string("TokenB"), SCValXDR.string("TB")]
        )

        // Mint tokens
        try await mintToken(tokenClient: tokenAClient, adminKp: adminKeyPair, toAccountId: aliceKeyPair.accountId, amount: 10_000_000_000_000)
        try await mintToken(tokenClient: tokenBClient, adminKp: adminKeyPair, toAccountId: bobKeyPair.accountId, amount: 10_000_000_000_000)

        try! await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))

        let spec = swapClient.getContractSpec()
        let args = try spec.funcArgsToXdrSCValues(name: "swap", args: [
            "a": aliceKeyPair.accountId,
            "b": bobKeyPair.accountId,
            "token_a": tokenAClient.contractId,
            "token_b": tokenBClient.contractId,
            "amount_a": 1000,
            "min_b_for_a": 4500,
            "amount_b": 5000,
            "min_a_for_b": 950,
        ])

        let tx = try await swapClient.buildInvokeMethodTx(name: "swap", args: args, enableServerLogging: true)

        // Snippet 20: Check who needs to sign
        let neededSigners = try tx.needsNonInvokerSigningBy()
        XCTAssertEqual(2, neededSigners.count)
        XCTAssert(neededSigners.contains(aliceKeyPair.accountId))
        XCTAssert(neededSigners.contains(bobKeyPair.accountId))

        // Snippet 21: Local signing
        try await tx.signAuthEntries(signerKeyPair: aliceKeyPair)

        // Snippet 22: Remote signing (using callback)
        let bobPublicKeyPair = try KeyPair(accountId: bobKeyPair.accountId)
        try await tx.signAuthEntries(signerKeyPair: bobPublicKeyPair, authorizeEntryCallback: { (entry, network) async throws in
            let base64Entry = entry.xdrEncoded!
            var entryToSign = try SorobanAuthorizationEntryXDR(fromBase64: base64Entry)
            try entryToSign.sign(signer: bobKeyPair, network: network)
            let signedBase64Entry = entryToSign.xdrEncoded!
            return try SorobanAuthorizationEntryXDR(fromBase64: signedBase64Entry)
        })

        let response = try await tx.signAndSend()
        XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, response.status)
    }

    // MARK: - Type Conversions (Snippets 23-36)

    func testPrimitiveTypes() {
        // Snippet 23: Primitives
        let boolVal = SCValXDR.bool(true)
        XCTAssertEqual(true, boolVal.bool)

        let u32Val = SCValXDR.u32(42)
        XCTAssertEqual(42, u32Val.u32)

        let i32Val = SCValXDR.i32(-42)
        XCTAssertEqual(-42, i32Val.i32)

        let u64Val = SCValXDR.u64(1_000_000)
        XCTAssertEqual(1_000_000, u64Val.u64)

        let i64Val = SCValXDR.i64(-1_000_000)
        XCTAssertEqual(-1_000_000, i64Val.i64)

        let stringVal = SCValXDR.string("Hello")
        XCTAssertEqual("Hello", stringVal.string)

        let symbolVal = SCValXDR.symbol("transfer")
        XCTAssertEqual("transfer", symbolVal.symbol)

        let bytesVal = SCValXDR.bytes(Data([0xDE, 0xAD, 0xBE, 0xEF]))
        XCTAssertNotNil(bytesVal.bytes)

        let voidVal = SCValXDR.void
        XCTAssertEqual(SCValType.void.rawValue, voidVal.type())
    }

    func testBigIntegers() throws {
        // Snippet 24: Big Integers (128/256-bit)
        let u128Val = SCValXDR.u128(UInt128PartsXDR(hi: 0, lo: 1000))
        XCTAssertEqual(1000, u128Val.u128?.lo)

        let i128Val = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
        XCTAssertEqual(1000, i128Val.i128?.lo)

        let u256Val = SCValXDR.u256(UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 1000))
        XCTAssertEqual(1000, u256Val.u256?.loLo)

        // Large value via ContractSpec
        let spec = ContractSpec(entries: [])
        let largeU128 = try spec.nativeToXdrSCVal(
            val: "340282366920938463463374607431768211455",
            ty: SCSpecTypeDefXDR.u128
        )
        XCTAssertEqual(SCValType.u128.rawValue, largeU128.type())
        XCTAssertEqual("340282366920938463463374607431768211455", largeU128.u128String)
    }

    func testAddresses() throws {
        // Snippet 25: Addresses
        let keyPair = try KeyPair.generateRandomKeyPair()

        let accountAddr = SCValXDR.address(try SCAddressXDR(accountId: keyPair.accountId))
        XCTAssertEqual(SCValType.address.rawValue, accountAddr.type())

        let contractId = "CCCZVCWISWKWZ3NNH737WGOVCDUI3P776QE3ZM7AUWMJKQBHCPW7NW3D"
        let contractAddr = SCValXDR.address(try SCAddressXDR(contractId: contractId))
        XCTAssertEqual(SCValType.address.rawValue, contractAddr.type())
    }

    func testCollections() {
        // Snippet 26: Collections
        let vec = SCValXDR.vec([
            SCValXDR.symbol("a"),
            SCValXDR.symbol("b"),
        ])
        XCTAssertEqual(2, vec.vec?.count)

        let map = SCValXDR.map([
            SCMapEntryXDR(key: SCValXDR.symbol("name"), val: SCValXDR.string("Alice")),
            SCMapEntryXDR(key: SCValXDR.symbol("age"), val: SCValXDR.u32(30)),
        ])
        XCTAssertEqual(2, map.map?.count)
    }

    func testContractSpecUsage() async throws {
        // Snippet 27: Using ContractSpec
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let spec = client.getContractSpec()

        let args = try spec.funcArgsToXdrSCValues(name: "hello", args: ["to": "Maria"])
        XCTAssertEqual(1, args.count)

        let functions = spec.funcs()
        XCTAssert(functions.count > 0)

        let helloFunc = spec.getFunc(name: "hello")
        XCTAssertNotNil(helloFunc)
        XCTAssertEqual("hello", helloFunc?.name)
    }

    func testAdvancedTypeConversions() throws {
        // Snippets 28-32: Advanced Type Conversions
        let spec = ContractSpec(entries: [])

        // Snippet 28: Void and Option
        let voidVal = try spec.nativeToXdrSCVal(val: nil, ty: SCSpecTypeDefXDR.void)
        XCTAssertEqual(SCValType.void.rawValue, voidVal.type())

        let optionType = SCSpecTypeDefXDR.option(
            SCSpecTypeOptionXDR(valueType: SCSpecTypeDefXDR.string)
        )
        let strVal = try spec.nativeToXdrSCVal(val: "a string", ty: optionType)
        XCTAssertEqual(SCValType.string.rawValue, strVal.type())
        let noneVal = try spec.nativeToXdrSCVal(val: nil, ty: optionType)
        XCTAssertEqual(SCValType.void.rawValue, noneVal.type())

        // Snippet 29: Vectors with Element Type
        let vecType = SCSpecTypeDefXDR.vec(
            SCSpecTypeVecXDR(elementType: SCSpecTypeDefXDR.symbol)
        )
        let vecVal = try spec.nativeToXdrSCVal(val: ["a", "b", "c"], ty: vecType)
        XCTAssertEqual(SCValType.vec.rawValue, vecVal.type())
        XCTAssertEqual(3, vecVal.vec?.count)

        // Snippet 30: Maps with Key/Value Types
        let keyPair = try KeyPair.generateRandomKeyPair()
        let mapType = SCSpecTypeMapXDR(
            keyType: SCSpecTypeDefXDR.string,
            valueType: SCSpecTypeDefXDR.address
        )
        let mapTypeDef = SCSpecTypeDefXDR.map(mapType)
        let mapVal = try spec.nativeToXdrSCVal(val: [
            "alice": keyPair.accountId,
        ], ty: mapTypeDef)
        XCTAssertEqual(SCValType.map.rawValue, mapVal.type())

        // Snippet 31: Tuples
        let tupleType = SCSpecTypeTupleXDR(valueTypes: [
            SCSpecTypeDefXDR.string,
            SCSpecTypeDefXDR.bool,
            SCSpecTypeDefXDR.u32,
        ])
        let tupleTypeDef = SCSpecTypeDefXDR.tuple(tupleType)
        let tupleVal = try spec.nativeToXdrSCVal(val: ["hello", true, 42], ty: tupleTypeDef)
        XCTAssertEqual(SCValType.vec.rawValue, tupleVal.type())
        XCTAssertEqual(3, tupleVal.vec?.count)

        // Snippet 32: Bytes and BytesN
        let bytesVal = try spec.nativeToXdrSCVal(val: Data(count: 32), ty: SCSpecTypeDefXDR.bytes)
        XCTAssertEqual(SCValType.bytes.rawValue, bytesVal.type())

        let fixedType = SCSpecTypeDefXDR.bytesN(SCSpecTypeBytesNXDR(n: 32))
        let fixedVal = try spec.nativeToXdrSCVal(val: Data(count: 32), ty: fixedType)
        XCTAssertNotNil(fixedVal)
    }

    func testUserDefinedTypes() throws {
        // Snippet 33: Enum
        // Note: These require actual spec entries with matching UDT definitions.
        // We test the basic nativeToXdrSCVal with primitive types that don't require UDT spec.
        let spec = ContractSpec(entries: [])

        // Basic numeric types that prove nativeToXdrSCVal works
        let u32Val = try spec.nativeToXdrSCVal(val: 42, ty: SCSpecTypeDefXDR.u32)
        XCTAssertEqual(42, u32Val.u32)

        let boolVal = try spec.nativeToXdrSCVal(val: true, ty: SCSpecTypeDefXDR.bool)
        XCTAssertEqual(true, boolVal.bool)
    }

    func testReadReturnValues() async throws {
        // Snippet 36: Reading Return Values
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let result = try await client.invokeMethod(name: "hello", args: [SCValXDR.symbol("test")])

        // Check vector access
        if let vec = result.vec {
            XCTAssertEqual(2, vec.count)
            for item in vec {
                XCTAssertNotNil(item.symbol)
            }
        } else {
            XCTFail("Expected vector result")
        }
    }

    // MARK: - Events (Snippets 37-38)

    func testBasicEventQuery() async {
        // Snippet 37: Basic Event Query
        let server = SorobanServer(endpoint: rpcUrl)

        // Get latest ledger to use as start
        let latestEnum = await server.getLatestLedger()
        guard case .success(let latest) = latestEnum else {
            XCTFail("Could not get latest ledger")
            return
        }

        let eventsResponse = await server.getEvents(startLedger: Int(latest.sequence) - 10)
        switch eventsResponse {
        case .success(let result):
            // Events may or may not exist, but the call should succeed
            XCTAssertNotNil(result)
        case .failure(let error):
            XCTFail("Events query failed: \(error)")
        }
    }

    func testFilteredEventQuery() async {
        // Snippet 38: Filtering by Contract and Topic
        let server = SorobanServer(endpoint: rpcUrl)

        let latestEnum = await server.getLatestLedger()
        guard case .success(let latest) = latestEnum else {
            XCTFail("Could not get latest ledger")
            return
        }

        let topicFilter = TopicFilter(segmentMatchers: [
            "*",
            SCValXDR.symbol("transfer").xdrEncoded!,
        ])

        let filter = EventFilter(
            type: "contract",
            topics: [topicFilter]
        )

        let eventsResponse = await server.getEvents(
            startLedger: Int(latest.sequence) - 10,
            eventFilters: [filter]
        )
        switch eventsResponse {
        case .success(let result):
            XCTAssertNotNil(result)
        case .failure(let error):
            XCTFail("Filtered events query failed: \(error)")
        }
    }

    // MARK: - Error Handling (Snippets 39-43)

    func testDebugLogging() async throws {
        // Snippet 39: Debug Logging
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        // Create client with logging enabled
        let loggingClient = try await SorobanClient.forClientOptions(
            options: ClientOptions(
                sourceAccountKeyPair: sourceAccountKeyPair,
                contractId: client.contractId,
                network: network,
                rpcUrl: rpcUrl,
                enableServerLogging: true
            )
        )
        XCTAssertNotNil(loggingClient)
    }

    func testMethodNotFound() async throws {
        // Snippet 40: Method Not Found
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        do {
            let _ = try await client.buildInvokeMethodTx(
                name: "nonexistent",
                args: []
            )
            XCTFail("Should have thrown for nonexistent method")
        } catch {
            // Expected error
            XCTAssertTrue(error is SorobanClientError)
        }
    }

    func testSimulationErrors() async throws {
        // Snippet 41: Simulation Errors
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let tx = try await client.buildInvokeMethodTx(
            name: "hello",
            args: [SCValXDR.symbol("test")]
        )

        // For a valid call, error should be nil
        XCTAssertNil(tx.simulationResponse?.error)
    }

    func testAutoRestore() async throws {
        // Snippet 43: Auto-Restore Expired State
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let result = try await client.invokeMethod(
            name: "hello",
            args: [SCValXDR.symbol("restore")],
            methodOptions: MethodOptions(restore: true)
        )
        XCTAssertNotNil(result.vec)
    }

    // MARK: - Low-Level Operations (Snippets 44-50)

    func testLowLevelUploadWasm() async throws {
        // Snippet 44: Upload WASM (low-level)
        let server = SorobanServer(endpoint: rpcUrl)

        guard let path = Bundle.module.path(forResource: helloContractFileName, ofType: "wasm") else {
            XCTFail("WASM file not found")
            return
        }
        guard let wasmData = FileManager.default.contents(atPath: path) else {
            XCTFail("Could not load WASM file")
            return
        }

        let uploadOp = try InvokeHostFunctionOperation.forUploadingContractWasm(
            contractCode: wasmData
        )

        let accountEnum = await server.getAccount(accountId: sourceAccountKeyPair.accountId)
        guard case .success(let account) = accountEnum else {
            XCTFail("Account not found")
            return
        }

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [uploadOp],
            memo: nil
        )

        let simEnum = await server.simulateTransaction(
            simulateTxRequest: SimulateTransactionRequest(transaction: transaction)
        )
        guard case .success(let sim) = simEnum else {
            XCTFail("Simulation failed")
            return
        }

        if let txData = sim.transactionData {
            transaction.setSorobanTransactionData(data: txData)
        }
        if let minFee = sim.minResourceFee {
            transaction.addResourceFee(resourceFee: minFee)
        }
        try transaction.sign(keyPair: sourceAccountKeyPair, network: network)

        let sendEnum = await server.sendTransaction(transaction: transaction)
        guard case .success(let sendResponse) = sendEnum else {
            XCTFail("Send failed")
            return
        }
        XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, sendResponse.status)

        // Poll for result
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txEnum = await server.getTransaction(transactionHash: sendResponse.transactionId)
        if case .success(let txResponse) = txEnum {
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, txResponse.status)
            XCTAssertNotNil(txResponse.wasmId)
        }
    }

    func testLowLevelCreateContract() async throws {
        // Snippet 45: Create Contract Instance (low-level)
        let server = SorobanServer(endpoint: rpcUrl)
        let wasmHash = try await installContract(fileName: helloContractFileName)

        let sourceAddress = try SCAddressXDR(accountId: sourceAccountKeyPair.accountId)
        let createOp = try InvokeHostFunctionOperation.forCreatingContract(
            wasmId: wasmHash,
            address: sourceAddress
        )

        let accountEnum = await server.getAccount(accountId: sourceAccountKeyPair.accountId)
        guard case .success(let account) = accountEnum else {
            XCTFail("Account not found")
            return
        }

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [createOp],
            memo: nil
        )

        let simEnum = await server.simulateTransaction(
            simulateTxRequest: SimulateTransactionRequest(transaction: transaction)
        )
        guard case .success(let sim) = simEnum else {
            XCTFail("Simulation failed")
            return
        }

        if let txData = sim.transactionData {
            transaction.setSorobanTransactionData(data: txData)
        }
        transaction.setSorobanAuth(auth: sim.sorobanAuth)
        if let minFee = sim.minResourceFee {
            transaction.addResourceFee(resourceFee: minFee)
        }
        try transaction.sign(keyPair: sourceAccountKeyPair, network: network)

        let sendEnum = await server.sendTransaction(transaction: transaction)
        guard case .success(let sendResponse) = sendEnum else {
            XCTFail("Send failed")
            return
        }
        XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, sendResponse.status)

        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txEnum = await server.getTransaction(transactionHash: sendResponse.transactionId)
        if case .success(let txResponse) = txEnum {
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, txResponse.status)
            XCTAssertNotNil(txResponse.createdContractId)
        }
    }

    func testLowLevelCreateContractWithConstructor() async throws {
        // Snippet 46: Create Contract with Constructor
        let server = SorobanServer(endpoint: rpcUrl)
        let wasmHash = try await installContract(fileName: helloContractFileName)

        let sourceAddress = try SCAddressXDR(accountId: sourceAccountKeyPair.accountId)
        // Hello contract doesn't have a constructor, but we verify the API shape
        let createOp = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
            wasmId: wasmHash,
            address: sourceAddress,
            constructorArguments: []
        )
        XCTAssertNotNil(createOp)
    }

    func testLowLevelInvokeContract() async throws {
        // Snippet 47: Invoke Contract (Low-Level)
        let server = SorobanServer(endpoint: rpcUrl)
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: client.contractId,
            functionName: "hello",
            functionArguments: [SCValXDR.symbol("World")]
        )

        let accountEnum = await server.getAccount(accountId: sourceAccountKeyPair.accountId)
        guard case .success(let account) = accountEnum else {
            XCTFail("Account not found")
            return
        }

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [invokeOp],
            memo: nil
        )

        let simEnum = await server.simulateTransaction(
            simulateTxRequest: SimulateTransactionRequest(transaction: transaction)
        )
        guard case .success(let sim) = simEnum else {
            XCTFail("Simulation failed")
            return
        }

        if let txData = sim.transactionData {
            transaction.setSorobanTransactionData(data: txData)
        }
        if let minFee = sim.minResourceFee {
            transaction.addResourceFee(resourceFee: minFee)
        }
        try transaction.sign(keyPair: sourceAccountKeyPair, network: network)

        let sendEnum = await server.sendTransaction(transaction: transaction)
        guard case .success(let sendResponse) = sendEnum else {
            XCTFail("Send failed")
            return
        }
        XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, sendResponse.status)

        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txEnum = await server.getTransaction(transactionHash: sendResponse.transactionId)
        if case .success(let txResponse) = txEnum {
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, txResponse.status)
            if let vec = txResponse.resultValue?.vec, vec.count > 1 {
                XCTAssertEqual("Hello", vec[0].symbol)
                XCTAssertEqual("World", vec[1].symbol)
            }
        }
    }

    func testDeploySACWithAsset() async throws {
        // Snippet 48: Deploy Stellar Asset Contract (SAC)
        // Verify the API shape compiles correctly
        let issuerKeyPair = try KeyPair.generateRandomKeyPair()
        let usdcAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USDC", issuer: issuerKeyPair)!
        let sacOp = try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: usdcAsset)
        XCTAssertNotNil(sacOp)
    }

    // MARK: - Contract Parser (Snippets 50-51)

    func testParseFromBytecode() throws {
        // Snippet 50: Parse from Bytecode
        guard let path = Bundle.module.path(forResource: helloContractFileName, ofType: "wasm") else {
            XCTFail("WASM file not found")
            return
        }
        guard let bytecode = FileManager.default.contents(atPath: path) else {
            XCTFail("Could not load WASM file")
            return
        }

        let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: bytecode)

        XCTAssert(contractInfo.specEntries.count > 0)
        XCTAssert(contractInfo.metaEntries.count > 0)
    }

    func testParseFromNetwork() async throws {
        // Snippet 51: Parse from Network
        let wasmHash = try await installContract(fileName: helloContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let server = SorobanServer(endpoint: rpcUrl)

        // By contract ID
        let infoEnum = await server.getContractInfoForContractId(contractId: client.contractId)
        switch infoEnum {
        case .success(let contractInfo):
            let spec = ContractSpec(entries: contractInfo.specEntries)
            let functions = spec.funcs()
            XCTAssert(functions.count > 0)
        case .rpcFailure(let error):
            XCTFail("RPC error: \(error)")
        case .parsingFailure(let error):
            XCTFail("Parsing error: \(error)")
        }

        // By WASM ID
        let infoEnum2 = await server.getContractInfoForWasmId(wasmId: wasmHash)
        switch infoEnum2 {
        case .success(let contractInfo):
            XCTAssert(contractInfo.specEntries.count > 0)
        case .rpcFailure(let error):
            XCTFail("RPC error: \(error)")
        case .parsingFailure(let error):
            XCTFail("Parsing error: \(error)")
        }
    }

    // MARK: - Helper Methods

    func installContract(fileName: String) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm") else {
            XCTFail("File \(fileName).wasm not found.")
            return ""
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("File \(fileName).wasm could not be loaded.")
            return ""
        }

        let installRequest = InstallRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: sourceAccountKeyPair,
            wasmBytes: contractCode,
            enableServerLogging: true
        )
        return try await SorobanClient.install(installRequest: installRequest)
    }

    func deployContract(wasmHash: String, constructorArgs: [SCValXDR]? = nil) async throws -> SorobanClient {
        let deployRequest = DeployRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: sourceAccountKeyPair,
            wasmHash: wasmHash,
            constructorArgs: constructorArgs,
            enableServerLogging: true
        )
        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }

    func fundAccount(accountId: String) async {
        let responseEnum = await sdk.accounts.createTestAccount(accountId: accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "fundAccount(\(accountId))", horizonRequestError: error)
            XCTFail("could not create test account: \(accountId)")
        }
    }

    func mintToken(tokenClient: SorobanClient, adminKp: KeyPair, toAccountId: String, amount: UInt64) async throws {
        let spec = tokenClient.getContractSpec()
        let args = try spec.funcArgsToXdrSCValues(name: "mint", args: [
            "to": toAccountId,
            "amount": Int(amount),
        ])
        let tx = try await tokenClient.buildInvokeMethodTx(name: "mint", args: args, enableServerLogging: true)
        try await tx.signAuthEntries(signerKeyPair: adminKp)
        let _ = try await tx.signAndSend()
    }
}
