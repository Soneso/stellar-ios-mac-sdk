//
//  AssembledTransactionDeepUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class AssembledTransactionDeepUnitTests: XCTestCase {

    var keyPair: KeyPair!
    var mockRpcUrl: String!
    var mockContractId: String!
    var clientOptions: ClientOptions!
    var methodOptions: MethodOptions!

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        keyPair = try! KeyPair(secretSeed: "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF")
        mockRpcUrl = "https://soroban-testnet.stellar.org"
        mockContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        clientOptions = ClientOptions(
            sourceAccountKeyPair: keyPair,
            contractId: mockContractId,
            network: Network.testnet,
            rpcUrl: mockRpcUrl
        )
        methodOptions = MethodOptions()
    }

    override func tearDown() {
        ServerMock.removeAll()
        URLProtocol.unregisterClass(ServerMock.self)
        super.tearDown()
    }

    // MARK: - Constructor and Initialization Tests

    func testAssembledTransactionInitialization() {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test_method"
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertNotNil(tx)
        XCTAssertEqual(tx.options.method, "test_method")
        XCTAssertNil(tx.raw)
        XCTAssertNil(tx.signed)
        XCTAssertNil(tx.tx)
        XCTAssertNil(tx.simulationResponse)
    }

    func testAssembledTransactionWithArguments() {
        let args: [SCValXDR] = [
            SCValXDR.u32(100),
            SCValXDR.u64(200),
            SCValXDR.string("test")
        ]

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "transfer",
            arguments: args
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.arguments?.count, 3)
        XCTAssertEqual(tx.options.method, "transfer")
    }

    func testAssembledTransactionWithCustomMethodOptions() {
        let customMethodOptions = MethodOptions(
            fee: 10000,
            timeoutInSeconds: 120,
            simulate: false,
            restore: true
        )

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: customMethodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.methodOptions.fee, 10000)
        XCTAssertEqual(tx.options.methodOptions.timeoutInSeconds, 120)
        XCTAssertFalse(tx.options.methodOptions.simulate)
        XCTAssertTrue(tx.options.methodOptions.restore)
    }

    func testAssembledTransactionWithServerLogging() {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test",
            enableServerLogging: true
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertTrue(tx.options.enableServerLogging)
    }

    // MARK: - Build Method Tests

    func testBuildWithSimulation() async throws {
        setupRpcMock(simulateResponse: .success)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "balance",
            arguments: nil
        )

        let tx = try await AssembledTransaction.build(options: options)
        XCTAssertNotNil(tx)
        XCTAssertNotNil(tx.raw)
    }

    func testBuildWithoutSimulation() async throws {
        setupRpcMock()

        let customMethodOptions = MethodOptions(simulate: false)
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: customMethodOptions,
            method: "test"
        )

        let tx = try await AssembledTransaction.build(options: options)
        XCTAssertNotNil(tx)
        XCTAssertNotNil(tx.raw)
        XCTAssertNil(tx.simulationResponse)
    }

    /// Counts the requests the mock of `countRequests()` receives.
    private final class RequestCounter: @unchecked Sendable {
        var count = 0
    }

    private func countRequests() -> RequestCounter {
        let counter = RequestCounter()
        ServerMock.add(mock: RequestMock(host: "soroban-testnet.stellar.org", path: "*", httpMethod: "POST") { _, _ in
            counter.count += 1
            return nil
        })
        return counter
    }

    /// The SEP-23 muxed contract, muxed account and account vectors with their invoke target refusals.
    private let invokeTargetRefusals = [
        ("WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG",
         "The contract to invoke must be a contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; use its base contract (C...) address"),
        ("MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK",
         "The contract to invoke must be a contract (C...) address, got a muxed account (M...) address: MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"),
        ("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
         "The contract to invoke must be a contract (C...) address, got an account (G...) address: GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"),
    ]

    /// A muxed address or an account as the contract to invoke is refused before the source
    /// account is fetched.
    func testBuildRefusesMuxedContractIds() async {
        let requests = countRequests()
        for (contractId, message) in invokeTargetRefusals {
            let client = ClientOptions(sourceAccountKeyPair: keyPair, contractId: contractId, network: Network.testnet, rpcUrl: mockRpcUrl)
            let options = AssembledTransactionOptions(clientOptions: client, methodOptions: methodOptions, method: "balance")
            do {
                _ = try await AssembledTransaction.build(options: options)
                XCTFail("Expected \(contractId) to be refused")
            } catch StellarSDKError.invalidArgument(let actual) {
                XCTAssertEqual(actual, message)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(requests.count, 0)
    }

    /// A decoded operation whose invoke target is a muxed address or an account is refused before
    /// the source account is fetched.
    func testBuildWithOpRefusesMuxedContractTarget() async throws {
        let requests = countRequests()
        let options = AssembledTransactionOptions(clientOptions: clientOptions, methodOptions: methodOptions, method: "balance")
        for (target, message) in invokeTargetRefusals {
            let address = target.hasPrefix("W") ? try SCAddressXDR(muxedContractId: target) : try SCAddressXDR(accountId: target)
            let operation = try InvokeHostFunctionOperation(fromXDR: InvokeHostFunctionOpXDR(
                hostFunction: .invokeContract(InvokeContractArgsXDR(contractAddress: address, functionName: "balance", args: [])),
                auth: []), sourceAccountId: nil)
            do {
                _ = try await AssembledTransaction.buildWithOp(operation: operation, options: options)
                XCTFail("Expected \(target) to be refused")
            } catch StellarSDKError.invalidArgument(let actual) {
                XCTAssertEqual(actual, message)
            }
        }
        XCTAssertEqual(requests.count, 0)
    }

    func testBuildWithOpCustomOperation() async throws {
        setupRpcMock(simulateResponse: .success)

        let operation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: mockContractId,
            functionName: "custom_function",
            functionArguments: [SCValXDR.u32(42)]
        )

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "custom_function"
        )

        let tx = try await AssembledTransaction.buildWithOp(operation: operation, options: options)
        XCTAssertNotNil(tx)
        XCTAssertNotNil(tx.raw)
    }

    // MARK: - Simulate Method Tests

    func testSimulateNotYetAssembled() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            try await tx.simulate()
            XCTFail("Expected notYetAssembled error")
        } catch AssembledTransactionError.notYetAssembled(let message) {
            XCTAssertTrue(message.contains("not yet been assembled"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSimulateWithSuccessResponse() async throws {
        setupRpcMock(simulateResponse: .success)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(simulate: false),
            method: "test"
        )

        let tx = try await AssembledTransaction.build(options: options)
        try await tx.simulate()
        XCTAssertNotNil(tx.simulationResponse)
    }

    func testSimulateWithFailureResponse() async throws {
        setupRpcMock(simulateResponse: .failure)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(simulate: false),
            method: "test"
        )

        do {
            let tx = try await AssembledTransaction.build(options: options)
            try await tx.simulate()
            XCTFail("Expected simulation to fail")
        } catch AssembledTransactionError.simulationFailed {
            // Expected: simulation returns an error
        }
    }

    func testSimulateWithRestorePreambleNoPrivateKey() async throws {
        setupRpcMock(simulateResponse: .restorePreamble)

        let keyPairNoPrivate = try KeyPair(accountId: keyPair.accountId)
        let optionsNoPrivate = ClientOptions(
            sourceAccountKeyPair: keyPairNoPrivate,
            contractId: mockContractId,
            network: Network.testnet,
            rpcUrl: mockRpcUrl
        )

        let options = AssembledTransactionOptions(
            clientOptions: optionsNoPrivate,
            methodOptions: MethodOptions(simulate: false, restore: true),
            method: "test"
        )

        do {
            let tx = try await AssembledTransaction.build(options: options)
            try await tx.simulate(restore: true)
            XCTFail("Expected missingPrivateKey error")
        } catch AssembledTransactionError.missingPrivateKey {
            // Expected: source keypair has no private key for auto-restore
        }
    }

    // MARK: - Sign Method Tests

    func testSignNotYetSimulated() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            try tx.sign()
            XCTFail("Expected notYetSimulated error")
        } catch AssembledTransactionError.notYetSimulated(let message) {
            XCTAssertTrue(message.contains("not yet been simulated"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignWithoutPrivateKey() async throws {
        setupRpcMock(simulateResponse: .success)

        let keyPairNoPrivate = try KeyPair(accountId: keyPair.accountId)
        let optionsNoPrivate = ClientOptions(
            sourceAccountKeyPair: keyPairNoPrivate,
            contractId: mockContractId,
            network: Network.testnet,
            rpcUrl: mockRpcUrl
        )

        let txOptions = AssembledTransactionOptions(
            clientOptions: optionsNoPrivate,
            methodOptions: methodOptions,
            method: "test"
        )

        do {
            let tx = try await AssembledTransaction.build(options: txOptions)
            try tx.sign()
            XCTFail("Expected missingPrivateKey error")
        } catch AssembledTransactionError.missingPrivateKey {
            // Expected: keypair has no private key
        }
    }

    func testSignReadCallWithoutForce() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        // Mock transaction data to simulate a read call
        tx.tx = try createMockTransaction()
        tx.simulationResponse = createMockSimulationResponseReadCall()

        do {
            try tx.sign()
            XCTFail("Expected isReadCall error")
        } catch AssembledTransactionError.isReadCall(let message) {
            XCTAssertTrue(message.contains("read call"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignReadCallWithForce() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        // Mock transaction data to simulate a read call
        tx.tx = try createMockTransaction()
        tx.simulationResponse = createMockSimulationResponseReadCall()

        try tx.sign(force: true)
        XCTAssertNotNil(tx.signed)
    }

    func testSignWithMultipleSignersRequired() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        // Mock transaction data with multiple signers including contract addresses
        tx.tx = try createMockTransactionWithMultipleSigners()
        tx.simulationResponse = createMockSimulationResponseWriteCall()

        do {
            try tx.sign()
            XCTFail("Expected multipleSignersRequired error")
        } catch AssembledTransactionError.multipleSignersRequired(let message) {
            XCTAssertTrue(message.contains("multiple signers"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignSuccess() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        // Mock transaction data
        tx.tx = try createMockTransaction()
        tx.simulationResponse = createMockSimulationResponseWriteCall()

        try tx.sign(force: true)
        XCTAssertNotNil(tx.signed)
    }

    func testSignWithCustomKeyPair() async throws {
        let customKeyPair = try KeyPair.generateRandomKeyPair()

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransaction()
        tx.simulationResponse = createMockSimulationResponseWriteCall()

        try tx.sign(sourceAccountKeyPair: customKeyPair, force: true)
        XCTAssertNotNil(tx.signed)
    }

    // MARK: - Send Method Tests

    func testSendNotYetSigned() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            _ = try await tx.send()
            XCTFail("Expected notYetSigned error")
        } catch AssembledTransactionError.notYetSigned(let message) {
            XCTAssertTrue(message.contains("not yet been signed"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendWithErrorStatus() async throws {
        setupRpcMock(sendResponse: .error)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.signed = try createMockSignedTransaction()

        do {
            _ = try await tx.send()
            XCTFail("Expected sendFailed error")
        } catch AssembledTransactionError.sendFailed {
            // Expected: send returns ERROR status
        }
    }

    // MARK: - SignAndSend Method Tests

    func testSignAndSendNotYetSimulated() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            _ = try await tx.signAndSend()
            XCTFail("Expected notYetSimulated error")
        } catch AssembledTransactionError.notYetSimulated {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignAndSendSuccess() async throws {
        setupRpcMock(sendResponse: .success, getTransactionResponse: .success)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(timeoutInSeconds: 10),
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransaction()
        tx.simulationResponse = createMockSimulationResponseWriteCall()

        let response = try await tx.signAndSend(force: true)
        XCTAssertNotNil(response)
    }

    func testSignAndSendWithCustomKeyPair() async throws {
        setupRpcMock(sendResponse: .success, getTransactionResponse: .success)

        let customKeyPair = try KeyPair.generateRandomKeyPair()

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(timeoutInSeconds: 10),
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransaction()
        tx.simulationResponse = createMockSimulationResponseWriteCall()

        let response = try await tx.signAndSend(sourceAccountKeyPair: customKeyPair, force: true)
        XCTAssertNotNil(response)
    }

    // MARK: - GetSimulationData Method Tests

    func testGetSimulationDataNotYetSimulated() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            _ = try tx.getSimulationData()
            XCTFail("Expected notYetSimulated error")
        } catch AssembledTransactionError.notYetSimulated {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetSimulationDataWithError() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseWithError()

        do {
            _ = try tx.getSimulationData()
            XCTFail("Expected simulationFailed error")
        } catch AssembledTransactionError.simulationFailed {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetSimulationDataWithRestorePreamble() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseWithRestorePreambleSuccess()

        do {
            _ = try tx.getSimulationData()
            XCTFail("Expected restoreNeeded error")
        } catch AssembledTransactionError.restoreNeeded(let message) {
            XCTAssertTrue(message.contains("restore"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetSimulationDataSuccess() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseSuccess()

        do {
            let data = try tx.getSimulationData()
            XCTAssertNotNil(data)
            XCTAssertNotNil(data.transactionData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetSimulationDataCaching() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseSuccess()

        let data1 = try tx.getSimulationData()
        let data2 = try tx.getSimulationData()

        XCTAssertNotNil(data1)
        XCTAssertNotNil(data2)
    }

    // MARK: - IsReadCall Method Tests

    func testIsReadCallNotYetSimulated() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            _ = try tx.isReadCall()
            XCTFail("Expected notYetSimulated error")
        } catch AssembledTransactionError.notYetSimulated {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testIsReadCallReturnsTrue() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseReadCall()

        let isRead = try tx.isReadCall()
        XCTAssertTrue(isRead)
    }

    func testIsReadCallReturnsFalseWithAuth() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseWriteCall()

        let isRead = try tx.isReadCall()
        XCTAssertFalse(isRead)
    }

    func testIsReadCallReturnsFalseWithReadWrite() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.simulationResponse = createMockSimulationResponseWithReadWrite()

        let isRead = try tx.isReadCall()
        XCTAssertFalse(isRead)
    }

    // MARK: - NeedsNonInvokerSigningBy Method Tests

    func testNeedsNonInvokerSigningByNotYetSimulated() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            _ = try tx.needsNonInvokerSigningBy()
            XCTFail("Expected notYetSimulated error")
        } catch AssembledTransactionError.notYetSimulated {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNeedsNonInvokerSigningByNoOperations() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        // Attempt to create transaction with no operations should fail
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)

        do {
            tx.tx = try Transaction(sourceAccount: account, operations: [], memo: Memo.none)
            XCTFail("Expected transaction creation to fail with no operations")
        } catch StellarSDKError.invalidArgument(let message) {
            XCTAssertTrue(message.contains("At least one operation required"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNeedsNonInvokerSigningByNoAuth() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransaction()

        let signers = try tx.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 0)
    }

    func testNeedsNonInvokerSigningByWithSigners() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransactionWithAuth()

        let signers = try tx.needsNonInvokerSigningBy()
        XCTAssertGreaterThan(signers.count, 0)
    }

    func testNeedsNonInvokerSigningByIncludeAlreadySigned() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransactionWithAuth()

        let signersExcluded = try tx.needsNonInvokerSigningBy(includeAlreadySigned: false)
        let signersIncluded = try tx.needsNonInvokerSigningBy(includeAlreadySigned: true)

        XCTAssertGreaterThanOrEqual(signersIncluded.count, signersExcluded.count)
    }

    func testNeedsNonInvokerSigningByNonInvokeHostFunctionOp() throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)
        let restoreOp = RestoreFootprintOperation()
        tx.tx = try Transaction(sourceAccount: account, operations: [restoreOp], memo: Memo.none)

        let signers = try tx.needsNonInvokerSigningBy()
        XCTAssertEqual(signers.count, 0)
    }

    // MARK: - SignAuthEntries Method Tests

    func testSignAuthEntriesNotYetSimulated() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        do {
            try await tx.signAuthEntries(signerKeyPair: keyPair)
            XCTFail("Expected notYetSimulated error")
        } catch AssembledTransactionError.notYetSimulated {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignAuthEntriesWithoutPrivateKey() async throws {
        setupMockForGetLatestLedger()

        let keyPairNoPrivate = try KeyPair(accountId: keyPair.accountId)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransactionWithAuth()

        do {
            try await tx.signAuthEntries(signerKeyPair: keyPairNoPrivate)
            XCTFail("Expected missingPrivateKey error")
        } catch AssembledTransactionError.missingPrivateKey {
            // Expected: keypair has no private key
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignAuthEntriesWithCallback() async throws {
        setupMockForGetLatestLedger()

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransactionWithAuthForSigner(accountId: keyPair.accountId)

        let callback: (SorobanAuthorizationEntryXDR, Network) async throws -> SorobanAuthorizationEntryXDR = { entry, network in
            var signedEntry = entry
            try signedEntry.sign(signer: self.keyPair, network: network)
            return signedEntry
        }

        try await tx.signAuthEntries(signerKeyPair: keyPair, authorizeEntryCallback: callback)
        XCTAssertNotNil(tx.tx)
    }

    func testSignAuthEntriesWithValidUntilLedgerSeq() async throws {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)
        tx.tx = try createMockTransactionWithAuthForSigner(accountId: keyPair.accountId)

        try await tx.signAuthEntries(signerKeyPair: keyPair, validUntilLedgerSeq: 1000000)
        XCTAssertNotNil(tx.tx)
    }

    // MARK: - RestoreFootprint Method Tests

    func testRestoreFootprint() async throws {
        setupRpcMock(simulateResponse: .success, sendResponse: .success, getTransactionResponse: .success)

        let restorePreamble = createMockRestorePreamble()

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(timeoutInSeconds: 10),
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        let response = try await tx.restoreFootprint(restorePreamble: restorePreamble)
        XCTAssertNotNil(response)
    }

    // MARK: - Error Cases Tests

    func testAllErrorCases() {
        let error1 = AssembledTransactionError.notYetAssembled(message: "test")
        let error2 = AssembledTransactionError.notYetSimulated(message: "test")
        let error3 = AssembledTransactionError.notYetSigned(message: "test")
        let error4 = AssembledTransactionError.missingPrivateKey(message: "test")
        let error5 = AssembledTransactionError.simulationFailed(message: "test")
        let error6 = AssembledTransactionError.restoreNeeded(message: "test")
        let error7 = AssembledTransactionError.isReadCall(message: "test")
        let error8 = AssembledTransactionError.unexpectedTxType(message: "test")
        let error9 = AssembledTransactionError.multipleSignersRequired(message: "test")
        let error10 = AssembledTransactionError.pollInterrupted(message: "test")
        let error11 = AssembledTransactionError.automaticRestoreFailed(message: "test")
        let error12 = AssembledTransactionError.sendFailed(message: "test")

        XCTAssertNotNil(error1)
        XCTAssertNotNil(error2)
        XCTAssertNotNil(error3)
        XCTAssertNotNil(error4)
        XCTAssertNotNil(error5)
        XCTAssertNotNil(error6)
        XCTAssertNotNil(error7)
        XCTAssertNotNil(error8)
        XCTAssertNotNil(error9)
        XCTAssertNotNil(error10)
        XCTAssertNotNil(error11)
        XCTAssertNotNil(error12)
    }

    // MARK: - Edge Cases Tests

    func testTransactionWithEmptyArguments() {
        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test",
            arguments: []
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.arguments?.count, 0)
    }

    func testTransactionWithLargeNumberOfArguments() {
        let args = Array(repeating: SCValXDR.u32(100), count: 50)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: "test",
            arguments: args
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.arguments?.count, 50)
    }

    func testTransactionWithLongMethodName() {
        let longMethodName = String(repeating: "a", count: 1000)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: methodOptions,
            method: longMethodName
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.method, longMethodName)
    }

    func testTransactionWithVeryHighFee() {
        let highFee: UInt32 = UInt32.max
        let customMethodOptions = MethodOptions(fee: highFee)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: customMethodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.methodOptions.fee, highFee)
    }

    func testTransactionWithVeryLongTimeout() {
        let longTimeout: UInt64 = UInt64.max
        let customMethodOptions = MethodOptions(timeoutInSeconds: longTimeout)

        let options = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: customMethodOptions,
            method: "test"
        )

        let tx = AssembledTransaction(options: options)

        XCTAssertEqual(tx.options.methodOptions.timeoutInSeconds, longTimeout)
    }

    // MARK: - Simulation Failure Contract Error Tests

    private let reportedB2 = ReportedContractError(code: 3016, provenance: .diagnosticEvents,
                                                   contractId: SimulationFailureFixtures.smartAccount)
    private let suffixB2 = " (contract error in diagnostic events: Error(Contract, #3016), contract "
        + SimulationFailureFixtures.smartAccount + ")"

    private func simulationFailedMessage(_ error: Error, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard let assembled = error as? AssembledTransactionError,
              case .simulationFailed(let message) = assembled else {
            XCTFail("expected AssembledTransactionError.simulationFailed, got \(error)", file: file, line: line)
            return nil
        }
        return message
    }

    func testSimulateFailureOnAnAssembledTransactionReportsTheContractError() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair,
                                         simulateBodies: [try SimulationFailureFixtures.body(SimulationFailureFixtures.caseB2)])
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(simulate: false),
                                                  method: "test")
        let tx = try await AssembledTransaction.build(options: options)
        do {
            try await tx.simulate()
            XCTFail("expected simulationFailed")
        } catch {
            XCTAssertEqual(simulationFailedMessage(error),
                           "Simulation failed with error: HostError: Error(Auth, InvalidAction)" + suffixB2)
            XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError, reportedB2)
        }
        XCTAssertEqual(tx.simulationResponse?.events,
                       try SimulationFailureFixtures.events(SimulationFailureFixtures.caseB2))
        XCTAssertEqual(router.sentTransactionRequests.count, 0)
    }

    func testBuildWithOpFailsBeforeReturningAnObjectWithTheContractError() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair,
                                         simulateBodies: [try SimulationFailureFixtures.body(SimulationFailureFixtures.caseB2)])
        let operation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: mockContractId, functionName: "test", functionArguments: [])
        let options = AssembledTransactionOptions(clientOptions: clientOptions, methodOptions: MethodOptions(), method: "test")
        do {
            _ = try await AssembledTransaction.buildWithOp(operation: operation, options: options)
            XCTFail("expected simulationFailed")
        } catch {
            XCTAssertEqual(simulationFailedMessage(error),
                           "Simulation failed with error: HostError: Error(Auth, InvalidAction)" + suffixB2)
            XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError, reportedB2)
        }
        XCTAssertEqual(router.sentTransactionRequests.count, 0)
    }

    func testSimulationDataReadsAfterAFailedSimulateReportTheContractError() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair,
                                         simulateBodies: [try SimulationFailureFixtures.body(SimulationFailureFixtures.caseB2)])
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(simulate: false),
                                                  method: "test")
        let tx = try await AssembledTransaction.build(options: options)
        do {
            try await tx.simulate()
            XCTFail("expected simulationFailed")
        } catch {}
        let expected = "Transaction simulation failed. Error: HostError: Error(Auth, InvalidAction)" + suffixB2
        let reads: [(String, () throws -> Void)] = [
            ("getSimulationData", { _ = try tx.getSimulationData() }),
            ("isReadCall", { _ = try tx.isReadCall() }),
            ("sign", { try tx.sign() }),
        ]
        for (label, read) in reads {
            do {
                try read()
                XCTFail("expected simulationFailed from \(label)")
            } catch {
                XCTAssertEqual(simulationFailedMessage(error), expected, label)
                XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError, reportedB2, label)
            }
        }
        do {
            _ = try await tx.signAndSend()
            XCTFail("expected simulationFailed from signAndSend")
        } catch {
            XCTAssertEqual(simulationFailedMessage(error), expected)
        }
        XCTAssertEqual(router.sentTransactionRequests.count, 0)
    }

    func testMissingTransactionDataKeepsItsMessageAndReportsNoContractError() async throws {
        _ = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [SimulationRpcRouter.noTransactionDataBody])
        let options = AssembledTransactionOptions(clientOptions: clientOptions, methodOptions: MethodOptions(), method: "test")
        let tx = try await AssembledTransaction.build(options: options)
        do {
            _ = try tx.getSimulationData()
            XCTFail("expected simulationFailed")
        } catch {
            XCTAssertEqual(simulationFailedMessage(error), "Transaction simulation failed")
            XCTAssertNil((error as? AssembledTransactionError)?.reportedContractError)
        }
    }

    /// A JSON-RPC error, an HTTP 500 and an unparsable body rethrow their
    /// `SorobanRpcRequestError` from `build` and from `simulate()`. No response is stored, so the
    /// next read reports no contract error.
    func testSimulateTransportFailuresRethrowTheRpcError() async throws {
        for transport in SimulationTransportFailure.allCases {
            ServerMock.removeAll()
            let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [transport.body],
                                             simulateStatusCode: transport.statusCode)
            let buildOptions = AssembledTransactionOptions(clientOptions: clientOptions,
                                                           methodOptions: MethodOptions(), method: "test")
            var buildError: Error?
            do {
                _ = try await AssembledTransaction.build(options: buildOptions)
                XCTFail("expected build to throw for \(transport)")
            } catch {
                buildError = error
            }
            transport.assertError(buildError)

            let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                      methodOptions: MethodOptions(simulate: false), method: "test")
            let tx = try await AssembledTransaction.build(options: options)
            var simulateError: Error?
            do {
                try await tx.simulate()
                XCTFail("expected simulate to throw for \(transport)")
            } catch {
                simulateError = error
            }
            transport.assertError(simulateError)
            XCTAssertNil(tx.simulationResponse, "\(transport)")
            do {
                _ = try tx.getSimulationData()
                XCTFail("expected notYetSimulated for \(transport)")
            } catch let error as AssembledTransactionError {
                if case .notYetSimulated(let message) = error {
                    XCTAssertEqual(message, "Transaction has not yet been simulated", "\(transport)")
                } else {
                    XCTFail("expected notYetSimulated for \(transport), got \(error)")
                }
                XCTAssertNil(error.reportedContractError, "\(transport)")
            }
            XCTAssertEqual(router.simulateRequestCount, 2, "\(transport)")
            XCTAssertEqual(router.sentTransactionRequests.count, 0, "\(transport)")
        }
    }

    func testFailingRestoreTransactionSimulationReportsItsContractError() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            SimulationRpcRouter.restorePreambleBody(contractId: mockContractId),
            try SimulationFailureFixtures.body(SimulationFailureFixtures.caseB2),
        ])
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(simulate: false, restore: true),
                                                  method: "test")
        let tx = try await AssembledTransaction.build(options: options)
        do {
            try await tx.simulate()
            XCTFail("expected simulationFailed")
        } catch {
            XCTAssertEqual(simulationFailedMessage(error),
                           "Simulation failed with error: HostError: Error(Auth, InvalidAction)" + suffixB2)
            XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError, reportedB2)
        }
        XCTAssertEqual(router.simulateRequestCount, 2)
        XCTAssertEqual(router.sentTransactionRequests.count, 0)
    }

    func testFailingReSimulationAfterRestoreSubmitsOnlyTheRestore() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            SimulationRpcRouter.restorePreambleBody(contractId: mockContractId),
            SimulationRpcRouter.successBody(contractId: mockContractId),
            try SimulationFailureFixtures.body(SimulationFailureFixtures.caseA),
        ])
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(simulate: false, restore: true),
                                                  method: "test")
        let tx = try await AssembledTransaction.build(options: options)
        do {
            try await tx.simulate()
            XCTFail("expected simulationFailed")
        } catch {
            XCTAssertEqual(simulationFailedMessage(error),
                           "Simulation failed with error: HostError: Error(Context, InvalidAction)"
                            + " (contract error in diagnostic events: Error(Contract, #3201), contract "
                            + SimulationFailureFixtures.thresholdPolicy + ")")
            XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError,
                           ReportedContractError(code: 3201, provenance: .diagnosticEvents,
                                                 contractId: SimulationFailureFixtures.thresholdPolicy))
        }
        XCTAssertEqual(router.simulateRequestCount, 3)
        let sent = router.sentTransactionRequests
        XCTAssertEqual(sent.count, 1, "only the restore transaction is submitted")
        let restore = try sentEnvelope(in: try XCTUnwrap(sent.first))
        XCTAssertEqual(restore.operations.count, 1)
        XCTAssertTrue(restore.operations.first is RestoreFootprintOperation)
    }

    // MARK: - Automatic Restore Tests

    /// A simulation that asks for a restore.
    private var restorePreamble: String {
        return SimulationRpcRouter.restorePreambleBody(contractId: mockContractId)
    }

    /// The simulation of the restore transaction.
    private var restoreSimulation: String {
        return SimulationRpcRouter.successBody(contractId: mockContractId)
    }

    /// A base64 auth entry of the source account for a call of `function`.
    private func sourceAccountAuth(_ function: String) throws -> String {
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: .contractFn(InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId: mockContractId),
                                                            functionName: function, args: [])),
                subInvocations: []))
        return try XCTUnwrap(entry.xdrEncoded)
    }

    private func restoringOptions(arguments: [SCValXDR]? = nil, restore: Bool = true) -> AssembledTransactionOptions {
        return AssembledTransactionOptions(clientOptions: clientOptions,
                                           methodOptions: MethodOptions(simulate: false, restore: restore),
                                           method: "test", arguments: arguments)
    }

    /// The function name, arguments and auth entries of the single contract invocation of `transaction`.
    private func invocation(of transaction: Transaction) throws
        -> (name: String, args: [SCValXDR], auth: [SorobanAuthorizationEntryXDR]) {
        XCTAssertEqual(transaction.operations.count, 1)
        let operation = try XCTUnwrap(transaction.operations.first as? InvokeHostFunctionOperation)
        var invoked: InvokeContractArgsXDR?
        if case .invokeContract(let args) = operation.hostFunction {
            invoked = args
        }
        let args = try XCTUnwrap(invoked, "expected a contract invocation")
        return (args.functionName, args.args, operation.auth)
    }

    /// The transaction was simulated once, so it carries the Soroban data, the auth entry and the
    /// resource fee 11000 of that simulation when `simulate(restore: true)` meets a restore
    /// preamble. The restore transaction consumes the sequence number 12346.
    func testSuccessfulRestoreAfterAnEarlierSimulationAssemblesOnlyTheReSimulation() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 11000,
                                            auth: [try sourceAccountAuth("first_auth")], returnValue: .u32(1)),
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: SyntheticDiagnosticEvent.otherContract, resourceFee: 12000,
                                            auth: [try sourceAccountAuth("second_auth")], returnValue: .u32(2)),
        ], accountSequenceNumbers: [12345, 12345, 12346])
        let options = AssembledTransactionOptions(clientOptions: clientOptions, methodOptions: MethodOptions(), method: "test")
        let tx = try await AssembledTransaction.build(options: options)
        XCTAssertEqual(try tx.getSimulationData().returnedValue.u32, 1)
        XCTAssertEqual(tx.tx?.fee, 11100)

        try await tx.simulate(restore: true)

        let simulated = router.simulateTransactionRequests
        XCTAssertEqual(simulated.count, 4)
        let sent = router.sentTransactionRequests
        XCTAssertEqual(sent.count, 1, "only the restore transaction is submitted")
        let restore = try sentEnvelope(in: try XCTUnwrap(sent.first))
        XCTAssertTrue(restore.operations.first is RestoreFootprintOperation)
        XCTAssertEqual(restore.transactionXDR.seqNum, 12346)

        // The re-simulated request carries the inclusion fee and the first simulation's data with the
        // resource fee 0, without its auth entry; tx carries only what the re-simulation returns.
        let request = try sentEnvelope(in: simulated[3])
        XCTAssertEqual(request.transactionXDR.seqNum, 12347)
        XCTAssertEqual(request.fee, 100)
        guard case .sorobanTransactionData(let carried) = request.transactionXDR.ext,
              case .contractData(let carriedKey)? = carried.resources.footprint.readWrite.first else {
            return XCTFail("expected the first simulation's data in the re-simulated request")
        }
        XCTAssertEqual(carried.resourceFee, 0)
        XCTAssertEqual(carried.resources.footprint.readWrite.count, 1)
        XCTAssertEqual(try carriedKey.contract.toStrKey(), mockContractId)
        XCTAssertEqual(carried.resources.instructions, 1000)
        XCTAssertEqual(try invocation(of: request).auth.count, 0)

        let assembled = try XCTUnwrap(tx.tx)
        XCTAssertEqual(assembled.transactionXDR.seqNum, 12347)
        XCTAssertEqual(assembled.fee, 12100, "the inclusion fee 100 plus the re-simulation's resource fee 12000")
        XCTAssertEqual(assembled.transactionXDR.fee, 12100)
        guard case .sorobanTransactionData(let data) = assembled.transactionXDR.ext,
              case .contractData(let key)? = data.resources.footprint.readWrite.first else {
            return XCTFail("expected the re-simulation's footprint on tx")
        }
        XCTAssertEqual(data.resourceFee, 12000)
        XCTAssertEqual(data.resources.footprint.readWrite.count, 1)
        XCTAssertEqual(try key.contract.toStrKey(), SyntheticDiagnosticEvent.otherContract)
        let auth = try invocation(of: assembled).auth
        XCTAssertEqual(auth.count, 1)
        guard case .contractFn(let authorized)? = auth.first?.rootInvocation.function else {
            return XCTFail("expected a contract function in the auth entry")
        }
        XCTAssertEqual(authorized.functionName, "second_auth")
        XCTAssertEqual(tx.simulationResponse?.minResourceFee, 12000)
        XCTAssertNil(tx.simulationResponse?.restorePreamble)
        XCTAssertEqual(try tx.getSimulationData().returnedValue.u32, 2)

        try tx.sign()
        XCTAssertEqual(tx.signed?.transactionXDR.seqNum, 12347)
    }

    /// A transaction the caller customized before its first simulation, which asks for a restore.
    func testSuccessfulRestoreKeepsTheMemoPreconditionsFeeAndOperationOfTheCaller() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 12000),
        ], accountSequenceNumbers: [12345, 12345, 12346])
        let operation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: mockContractId, functionName: "custom_call", functionArguments: [SCValXDR.u32(7)])
        let tx = try await AssembledTransaction.buildWithOp(operation: operation,
                                                            options: restoringOptions(arguments: [SCValXDR.u32(1)]))
        let raw = try XCTUnwrap(tx.raw)
        raw.setMemo(memo: .text("restore memo"))
        raw.setPreconditions(preconditions: TransactionPreconditions(
            ledgerBounds: LedgerBounds(minLedger: 999000, maxLedger: 1001000),
            timeBounds: TimeBounds(minTime: 1700000000, maxTime: 1900000000)))
        raw.setFee(fee: 200000)

        try await tx.simulate()

        XCTAssertEqual(router.simulateRequestCount, 3)
        XCTAssertEqual(router.sentTransactionRequests.count, 1)
        let request = try sentEnvelope(in: try XCTUnwrap(router.simulateTransactionRequests.last))
        XCTAssertEqual(request.fee, 200000)
        let assembled = try XCTUnwrap(tx.tx)
        XCTAssertEqual(assembled.fee, 212000, "the inclusion fee 200000 plus the re-simulation's resource fee 12000")
        for (label, transaction) in [("re-simulated request", request), ("tx", assembled)] {
            XCTAssertEqual(transaction.transactionXDR.seqNum, 12347, label)
            XCTAssertEqual(transaction.memo, Memo.text("restore memo"), label)
            XCTAssertEqual(transaction.preconditions?.ledgerBounds?.minLedger, 999000, label)
            XCTAssertEqual(transaction.preconditions?.ledgerBounds?.maxLedger, 1001000, label)
            XCTAssertEqual(transaction.preconditions?.timeBounds?.minTime, 1700000000, label)
            XCTAssertEqual(transaction.preconditions?.timeBounds?.maxTime, 1900000000, label)
            let invoked = try invocation(of: transaction)
            XCTAssertEqual(invoked.name, "custom_call", label)
            XCTAssertEqual(invoked.args.map { $0.u32 }, [7], label)
        }
    }

    /// Restores a transaction whose `raw` carries Soroban data the caller set with `resourceFee`
    /// and the fee `fee`, and returns the fee of the re-simulated request and of the assembled
    /// transaction. The re-simulation has the resource fee 12000.
    private func restoreWithCarriedSorobanData(fee: UInt32, resourceFee: Int64) async throws
        -> (request: UInt32, assembled: UInt32?) {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 12000),
        ], accountSequenceNumbers: [12345, 12345, 12346])
        let tx = try await AssembledTransaction.build(options: restoringOptions())
        let raw = try XCTUnwrap(tx.raw)
        raw.setSorobanTransactionData(data: SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                                           instructions: 0, diskReadBytes: 0, writeBytes: 0),
            resourceFee: resourceFee))
        raw.setFee(fee: fee)

        try await tx.simulate()

        XCTAssertEqual(router.simulateRequestCount, 3)
        guard case .sorobanTransactionData(let callerData) = raw.transactionXDR.ext else {
            XCTFail("expected the caller's Soroban data on the caller's transaction")
            return (0, nil)
        }
        XCTAssertEqual(callerData.resourceFee, resourceFee, "the caller's transaction keeps its data")
        let request = try sentEnvelope(in: try XCTUnwrap(router.simulateTransactionRequests.last))
        return (request.fee, tx.tx?.fee)
    }

    func testSuccessfulRestoreKeepsAFeeBelowTheResourceFeeOfTheCarriedSorobanDataWhole() async throws {
        let fees = try await restoreWithCarriedSorobanData(fee: 100, resourceFee: 5000)
        XCTAssertEqual(fees.request, 100)
        XCTAssertEqual(fees.assembled, 12100, "the whole fee 100 plus the re-simulation's resource fee 12000")
    }

    func testSuccessfulRestoreDerivesTheInclusionFeeZeroFromAFeeEqualToTheResourceFee() async throws {
        let fees = try await restoreWithCarriedSorobanData(fee: 5000, resourceFee: 5000)
        XCTAssertEqual(fees.request, 0)
        XCTAssertEqual(fees.assembled, 12000, "the inclusion fee 0 plus the re-simulation's resource fee 12000")
    }

    /// A `raw` the caller built for an instance made with `init(options:)`: its source is a muxed
    /// address of an account other than the options' source account, which signs the restore, and
    /// its operation is one that `options.method` does not name. The account read after the
    /// restore is that other account, with the sequence number 12346.
    func testSuccessfulRestoreOfACallerBuiltRawKeepsItsOperationAndMuxedSource() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 12000,
                                            auth: [try sourceAccountAuth("second_auth")]),
        ], accountSequenceNumbers: [12345, 12346])
        let rawSource = try KeyPair(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
        let operation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: mockContractId, functionName: "custom_call", functionArguments: [SCValXDR.u32(7)])
        let callerRaw = try Transaction(sourceAccount: MuxedAccount(keyPair: rawSource, sequenceNumber: 12345, id: 42),
                                        operations: [operation], memo: nil)
        let tx = AssembledTransaction(options: restoringOptions())
        tx.raw = callerRaw

        try await tx.simulate()

        XCTAssertEqual(router.simulateRequestCount, 3)
        let request = try sentEnvelope(in: try XCTUnwrap(router.simulateTransactionRequests.last))
        let assembled = try XCTUnwrap(tx.tx)
        for (label, transaction) in [("re-simulated request", request), ("tx", assembled)] {
            XCTAssertEqual(transaction.transactionXDR.seqNum, 12347, label)
            guard case .med25519(let muxed) = transaction.transactionXDR.sourceAccount else {
                XCTFail("expected the muxed source in \(label)")
                continue
            }
            XCTAssertEqual(muxed.id, 42, label)
            XCTAssertEqual(muxed.sourceAccountEd25519, rawSource.publicKey.bytes, label)
            let invoked = try invocation(of: transaction)
            XCTAssertEqual(invoked.name, "custom_call", label)
            XCTAssertEqual(invoked.args.map { $0.u32 }, [7], label)
        }
        XCTAssertEqual(try invocation(of: assembled).auth.count, 1)
        // The re-simulation's auth entry lands in tx only, not in the caller's objects.
        XCTAssertFalse(assembled === callerRaw)
        XCTAssertEqual(operation.auth.count, 0)
        XCTAssertEqual(try invocation(of: callerRaw).auth.count, 0)
        XCTAssertEqual(callerRaw.transactionXDR.seqNum, 12346)
    }

    /// A `raw` the caller built for an instance made with `init(options:)` that extends the TTL of
    /// an archived entry, with Soroban data that names the entry in its read-only footprint.
    func testSuccessfulRestoreReSimulatesAnExtendFootprintTTLWithItsFootprint() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: SyntheticDiagnosticEvent.otherContract, resourceFee: 12000),
        ], accountSequenceNumbers: [12345, 12346])
        let archived = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
            contract: try SCAddressXDR(contractId: mockContractId), key: SCValXDR.u32(1), durability: .persistent))
        let callerRaw = try Transaction(sourceAccount: Account(keyPair: keyPair, sequenceNumber: 12345),
                                        operations: [ExtendFootprintTTLOperation(ledgersToExpire: 100000)], memo: nil)
        callerRaw.setSorobanTransactionData(data: SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [archived], readWrite: []),
                                           instructions: 0, diskReadBytes: 0, writeBytes: 0),
            resourceFee: 0))
        let tx = AssembledTransaction(options: restoringOptions())
        tx.raw = callerRaw

        try await tx.simulate()

        XCTAssertEqual(router.simulateRequestCount, 3)
        XCTAssertEqual(router.sentTransactionRequests.count, 1)
        let request = try sentEnvelope(in: try XCTUnwrap(router.simulateTransactionRequests.last))
        XCTAssertEqual(request.transactionXDR.seqNum, 12347)
        XCTAssertEqual((request.operations.first as? ExtendFootprintTTLOperation)?.extendTo, 100000)
        guard case .sorobanTransactionData(let carried) = request.transactionXDR.ext else {
            return XCTFail("expected the footprint in the re-simulated request")
        }
        XCTAssertEqual(carried.resources.footprint.readOnly.map { $0.xdrEncoded }, [archived.xdrEncoded])
        XCTAssertEqual(carried.resources.footprint.readWrite.count, 0)

        let assembled = try XCTUnwrap(tx.tx)
        guard case .sorobanTransactionData(let data) = assembled.transactionXDR.ext,
              case .contractData(let key)? = data.resources.footprint.readWrite.first else {
            return XCTFail("expected the re-simulation's data on tx")
        }
        XCTAssertEqual(data.resourceFee, 12000)
        XCTAssertEqual(data.resources.footprint.readOnly.count, 0)
        XCTAssertEqual(try key.contract.toStrKey(), SyntheticDiagnosticEvent.otherContract)
        XCTAssertEqual(assembled.fee, 12100, "the inclusion fee 100 plus the re-simulation's resource fee 12000")
    }

    func testSimulateWithRestoreTrueRestoresASecondPreambleWhenTheOptionIsFalse() async throws {
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            restorePreamble,
            restoreSimulation,
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 12000),
        ], accountSequenceNumbers: [12345, 12345, 12346, 12346, 12347])
        let tx = try await AssembledTransaction.build(options: restoringOptions(restore: false))

        try await tx.simulate(restore: true)

        XCTAssertEqual(router.simulateRequestCount, 5)
        let restores = try router.sentTransactionRequests.map { try sentEnvelope(in: $0) }
        XCTAssertEqual(restores.count, 2)
        XCTAssertTrue(restores.allSatisfy { $0.operations.first is RestoreFootprintOperation })
        XCTAssertEqual(restores.map { $0.transactionXDR.seqNum }, [12346, 12347])
        XCTAssertEqual(tx.tx?.transactionXDR.seqNum, 12348)
        XCTAssertEqual(tx.tx?.fee, 12100)
        XCTAssertNil(tx.simulationResponse?.restorePreamble)
    }

    /// Simulates with `restore: true` a transaction built with the fee 200000 that meets two
    /// restore preambles in a row before a simulation with the resource fee 12000. With
    /// `simulateFirst`, the build simulates it once before, with the resource fee 11000. Returns,
    /// for the simulated invocation requests in order, their fees and the resource fees of the
    /// Soroban data they carry, and the fee of the assembled transaction.
    private func restoreTwice(simulateFirst: Bool) async throws
        -> (requests: [UInt32], carried: [Int64?], assembled: UInt32?) {
        let earlier = simulateFirst
            ? [SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 11000)]
            : []
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: earlier + [
            restorePreamble,
            restoreSimulation,
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 12000),
        ], accountSequenceNumbers: [12345, 12345, 12346, 12346, 12347])
        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(fee: 200000, simulate: simulateFirst),
                                                  method: "test")
        let tx = try await AssembledTransaction.build(options: options)

        try await tx.simulate(restore: true)

        XCTAssertEqual(router.sentTransactionRequests.count, 2)
        let invocations = try router.simulateTransactionRequests.map { try sentEnvelope(in: $0) }
            .filter { $0.operations.first is InvokeHostFunctionOperation }
        let carried = invocations.map { request -> Int64? in
            guard case .sorobanTransactionData(let data) = request.transactionXDR.ext else { return nil }
            return data.resourceFee
        }
        return (invocations.map { $0.fee }, carried, tx.tx?.fee)
    }

    func testRepeatedRestoresAfterAnEarlierSimulationKeepTheInclusionFee() async throws {
        let fees = try await restoreTwice(simulateFirst: true)
        // The earlier simulation, the simulation that meets the first preamble, the two re-simulations.
        XCTAssertEqual(fees.requests, [200000, 211000, 200000, 200000])
        XCTAssertEqual(fees.carried, [nil, 11000, 0, 0])
        XCTAssertEqual(fees.assembled, 212000, "the inclusion fee 200000 plus the final resource fee 12000")
    }

    func testRepeatedRestoresOfANeverSimulatedTransactionKeepItsFee() async throws {
        let fees = try await restoreTwice(simulateFirst: false)
        // The simulation that meets the first preamble, the two re-simulations.
        XCTAssertEqual(fees.requests, [200000, 200000, 200000])
        XCTAssertEqual(fees.carried, [nil, nil, nil])
        XCTAssertEqual(fees.assembled, 212000, "the fee 200000 plus the final resource fee 12000")
    }

    func testFailedRestoreThrowsAutomaticRestoreFailedWithoutReSimulation() async throws {
        // fee charged 5100, txFAILED with RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED
        let failedResultXdr = "AAAAAAAAE+z/////AAAAAQAAAAAAAAAa/////gAAAAA="
        let router = SimulationRpcRouter(sourceAccount: keyPair, simulateBodies: [
            restorePreamble,
            restoreSimulation,
            SimulationRpcRouter.successBody(contractId: mockContractId, resourceFee: 12000),
        ], failedTransactionResultXdr: failedResultXdr)
        let tx = try await AssembledTransaction.build(options: restoringOptions())
        do {
            try await tx.simulate()
            XCTFail("expected automaticRestoreFailed")
        } catch AssembledTransactionError.automaticRestoreFailed(let message) {
            XCTAssertEqual(message, "Automatic restore failed! You set 'restore: true' but the attempted restore did not work. Status: FAILED , transaction result xdr: AAAAAAAAE+z/////AAAAAQAAAAAAAAAa/////gAAAAA=")
        }
        XCTAssertEqual(router.simulateRequestCount, 2, "the first simulation and the restore transaction's")
        XCTAssertEqual(router.sentTransactionRequests.count, 1)
    }

    // MARK: - Mock Response Type Enums

    enum SimulateResponseType {
        case success
        case successReadCall
        case failure
        case restorePreamble
    }

    enum SendResponseType {
        case success
        case error
    }

    enum GetTransactionResponseType {
        case success
        case notFound
    }

    // MARK: - Unified RPC Mock Setup

    /// Sets up a single mock handler that routes JSON-RPC requests by method name.
    /// This ensures that multiple RPC methods (getLedgerEntries, simulateTransaction,
    /// sendTransaction, getTransaction, getLatestLedger) all work correctly within
    /// the same test, because only one RequestMock is registered and it dispatches
    /// based on the request body content.
    private func setupRpcMock(
        simulateResponse: SimulateResponseType? = nil,
        sendResponse: SendResponseType? = nil,
        getTransactionResponse: GetTransactionResponseType? = nil
    ) {
        let mock = RequestMock(
            host: "soroban-testnet.stellar.org",
            path: "*",
            httpMethod: "POST"
        ) { mock, request in
            mock.statusCode = 200

            // Read the request body to determine the JSON-RPC method
            let bodyString: String?
            if let bodyData = request.httpBody {
                bodyString = String(data: bodyData, encoding: .utf8)
            } else if let stream = request.httpBodyStream {
                let data = stream.readfully()
                bodyString = String(data: data, encoding: .utf8)
            } else {
                bodyString = nil
            }

            guard let body = bodyString else {
                return nil
            }

            if body.contains("\"getLedgerEntries\"") {
                return self.getLedgerEntriesAccountJson()
            }

            if body.contains("\"simulateTransaction\"") {
                switch simulateResponse {
                case .success, .successReadCall:
                    return self.simulateTransactionSuccessJson()
                case .failure:
                    return self.simulateTransactionFailureJson()
                case .restorePreamble:
                    return self.simulateTransactionWithRestorePreambleJson()
                case .none:
                    return nil
                }
            }

            if body.contains("\"sendTransaction\"") {
                switch sendResponse {
                case .success:
                    return self.sendTransactionSuccessJson()
                case .error:
                    return self.sendTransactionErrorJson()
                case .none:
                    return nil
                }
            }

            if body.contains("\"getTransaction\"") {
                switch getTransactionResponse {
                case .success:
                    return self.getTransactionSuccessJson()
                case .notFound:
                    return self.getTransactionResponseJson()
                case .none:
                    return nil
                }
            }

            if body.contains("\"getLatestLedger\"") {
                return self.getLatestLedgerJson()
            }

            return nil
        }

        ServerMock.add(mock: mock)
    }

    private func setupMockForGetLatestLedger() {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return self.getLatestLedgerJson()
        }
        ServerMock.add(mock: RequestMock(
            host: "soroban-testnet.stellar.org", path: "*", httpMethod: "POST", mockHandler: handler
        ))
    }

    // MARK: - Mock Transaction Helpers

    private func createMockTransaction() throws -> Transaction {
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)
        let operation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: mockContractId,
            functionName: "test",
            functionArguments: []
        )

        return try Transaction(sourceAccount: account, operations: [operation], memo: Memo.none)
    }

    private func createMockSignedTransaction() throws -> Transaction {
        let tx = try createMockTransaction()
        try tx.sign(keyPair: keyPair, network: Network.testnet)
        return tx
    }

    private func createMockTransactionWithAuth() throws -> Transaction {
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)

        let addressCredentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: keyPair.accountId),
            nonce: 123,
            signatureExpirationLedger: 1000,
            signature: SCValXDR.void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(addressCredentials),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: SorobanAuthorizedFunctionXDR.contractFn(
                    InvokeContractArgsXDR(
                        contractAddress: try SCAddressXDR(contractId: mockContractId),
                        functionName: "test",
                        args: []
                    )
                ),
                subInvocations: []
            )
        )

        let operation = InvokeHostFunctionOperation(
            hostFunction: HostFunctionXDR.invokeContract(
                InvokeContractArgsXDR(
                    contractAddress: try SCAddressXDR(contractId: mockContractId),
                    functionName: "test",
                    args: []
                )
            ),
            auth: [authEntry],
            sourceAccountId: nil
        )

        return try Transaction(sourceAccount: account, operations: [operation], memo: Memo.none)
    }

    private func createMockTransactionWithAuthForSigner(accountId: String) throws -> Transaction {
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)

        let addressCredentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: accountId),
            nonce: 123,
            signatureExpirationLedger: 1000,
            signature: SCValXDR.void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(addressCredentials),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: SorobanAuthorizedFunctionXDR.contractFn(
                    InvokeContractArgsXDR(
                        contractAddress: try SCAddressXDR(contractId: mockContractId),
                        functionName: "test",
                        args: []
                    )
                ),
                subInvocations: []
            )
        )

        let operation = InvokeHostFunctionOperation(
            hostFunction: HostFunctionXDR.invokeContract(
                InvokeContractArgsXDR(
                    contractAddress: try SCAddressXDR(contractId: mockContractId),
                    functionName: "test",
                    args: []
                )
            ),
            auth: [authEntry],
            sourceAccountId: nil
        )

        return try Transaction(sourceAccount: account, operations: [operation], memo: Memo.none)
    }

    private func createMockTransactionWithMultipleSigners() throws -> Transaction {
        let account = Account(keyPair: keyPair, sequenceNumber: 12345)

        let otherKeyPair = try KeyPair.generateRandomKeyPair()

        let addressCredentials1 = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: "GCQHNAXSI55GX2GN6D67GK7BHVPSLJUGZQEU7WJ5LKR5PNUCGLIMAMSW"),
            nonce: 123,
            signatureExpirationLedger: 1000,
            signature: SCValXDR.void
        )

        let addressCredentials2 = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(accountId: otherKeyPair.accountId),
            nonce: 124,
            signatureExpirationLedger: 1000,
            signature: SCValXDR.void
        )

        let authEntry1 = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(addressCredentials1),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: SorobanAuthorizedFunctionXDR.contractFn(
                    InvokeContractArgsXDR(
                        contractAddress: try SCAddressXDR(contractId: mockContractId),
                        functionName: "test",
                        args: []
                    )
                ),
                subInvocations: []
            )
        )

        let authEntry2 = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(addressCredentials2),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: SorobanAuthorizedFunctionXDR.contractFn(
                    InvokeContractArgsXDR(
                        contractAddress: try SCAddressXDR(contractId: mockContractId),
                        functionName: "test",
                        args: []
                    )
                ),
                subInvocations: []
            )
        )

        let operation = InvokeHostFunctionOperation(
            hostFunction: HostFunctionXDR.invokeContract(
                InvokeContractArgsXDR(
                    contractAddress: try SCAddressXDR(contractId: mockContractId),
                    functionName: "test",
                    args: []
                )
            ),
            auth: [authEntry1, authEntry2],
            sourceAccountId: nil
        )

        return try Transaction(sourceAccount: account, operations: [operation], memo: Memo.none)
    }

    // MARK: - Mock Response Helpers

    private func createMockSimulationResponseReadCall() -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let returnValue = SCValXDR.u32(42)
        let returnValueXdrBase64 = returnValue.xdrEncoded!
        let transactionDataXdrBase64 = transactionData.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "transactionData": "\(transactionDataXdrBase64)",
            "minResourceFee": "10000",
            "results": [
                {
                    "auth": [],
                    "xdr": "\(returnValueXdrBase64)"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockSimulationResponseWriteCall() -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(
                    readOnly: [],
                    readWrite: [LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
                        contract: try! SCAddressXDR(contractId: mockContractId),
                        key: SCValXDR.u32(1),
                        durability: .persistent
                    ))]
                ),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let addressCredentials = SorobanAddressCredentialsXDR(
            address: try! SCAddressXDR(accountId: keyPair.accountId),
            nonce: 123,
            signatureExpirationLedger: 1000,
            signature: SCValXDR.void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(addressCredentials),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: SorobanAuthorizedFunctionXDR.contractFn(
                    InvokeContractArgsXDR(
                        contractAddress: try! SCAddressXDR(contractId: mockContractId),
                        functionName: "test",
                        args: []
                    )
                ),
                subInvocations: []
            )
        )

        let returnValue = SCValXDR.void
        let returnValueXdrBase64 = returnValue.xdrEncoded!
        let transactionDataXdrBase64 = transactionData.xdrEncoded!
        let authEntryXdrBase64 = authEntry.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "transactionData": "\(transactionDataXdrBase64)",
            "minResourceFee": "10000",
            "results": [
                {
                    "auth": ["\(authEntryXdrBase64)"],
                    "xdr": "\(returnValueXdrBase64)"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockSimulationResponseWithReadWrite() -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(
                    readOnly: [],
                    readWrite: [LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
                        contract: try! SCAddressXDR(contractId: mockContractId),
                        key: SCValXDR.u32(1),
                        durability: .persistent
                    ))]
                ),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let returnValue = SCValXDR.u32(42)
        let returnValueXdrBase64 = returnValue.xdrEncoded!
        let transactionDataXdrBase64 = transactionData.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "transactionData": "\(transactionDataXdrBase64)",
            "minResourceFee": "10000",
            "results": [
                {
                    "auth": [],
                    "xdr": "\(returnValueXdrBase64)"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockSimulationResponseWithError() -> SimulateTransactionResponse {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "error": "Simulation failed"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockSimulationResponseWithRestorePreamble() -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let transactionDataXdrBase64 = transactionData.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "restorePreamble": {
                "transactionData": "\(transactionDataXdrBase64)",
                "minResourceFee": "5000"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockSimulationResponseWithRestorePreambleSuccess() -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let returnValue = SCValXDR.u32(42)
        let returnValueXdrBase64 = returnValue.xdrEncoded!
        let transactionDataXdrBase64 = transactionData.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "transactionData": "\(transactionDataXdrBase64)",
            "minResourceFee": "10000",
            "restorePreamble": {
                "transactionData": "\(transactionDataXdrBase64)",
                "minResourceFee": "5000"
            },
            "results": [
                {
                    "auth": [],
                    "xdr": "\(returnValueXdrBase64)"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockSimulationResponseSuccess() -> SimulateTransactionResponse {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let returnValue = SCValXDR.u32(42)
        let returnValueXdrBase64 = returnValue.xdrEncoded!
        let transactionDataXdrBase64 = transactionData.xdrEncoded!

        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "transactionData": "\(transactionDataXdrBase64)",
            "minResourceFee": "10000",
            "results": [
                {
                    "auth": [],
                    "xdr": "\(returnValueXdrBase64)"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(SimulateTransactionResponse.self, from: jsonData)
    }

    private func createMockRestorePreamble() -> RestorePreamble {
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: []),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )

        let transactionDataXdrBase64 = transactionData.xdrEncoded!

        let jsonResponse = """
        {
            "transactionData": "\(transactionDataXdrBase64)",
            "minResourceFee": "5000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(RestorePreamble.self, from: jsonData)
    }

    // MARK: - Mock JSON Response Helpers

    private func getLedgerEntriesAccountJson() -> String {
        // Build a valid LedgerEntryDataXDR.account XDR to return as a ledger entry
        let publicKey = keyPair.publicKey
        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 100_000_000_0,
            sequenceNumber: 12345,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "",
            thresholds: WrappedData4(Data([1, 0, 0, 0])),
            signers: [],
            ext: .void
        )
        let ledgerEntryData = LedgerEntryDataXDR.account(accountEntry)
        let xdrBase64 = ledgerEntryData.xdrEncoded!

        // Also need the ledger key for the response
        let accountKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: publicKey))
        let keyBase64 = accountKey.xdrEncoded!

        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "entries": [
                    {
                        "key": "\(keyBase64)",
                        "xdr": "\(xdrBase64)",
                        "lastModifiedLedgerSeq": 999000
                    }
                ],
                "latestLedger": 1000000
            }
        }
        """
    }

    private func validTransactionDataXdrBase64(includeWriteFootprint: Bool = true) -> String {
        var readWrite: [LedgerKeyXDR] = []
        if includeWriteFootprint {
            readWrite.append(LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(
                contract: try! SCAddressXDR(contractId: mockContractId),
                key: SCValXDR.u32(1),
                durability: .persistent
            )))
        }
        let transactionData = SorobanTransactionDataXDR(
            resources: SorobanResourcesXDR(
                footprint: LedgerFootprintXDR(readOnly: [], readWrite: readWrite),
                instructions: 1000,
                diskReadBytes: 100,
                writeBytes: 50
            ),
            resourceFee: 10000
        )
        return transactionData.xdrEncoded!
    }

    private func simulateTransactionResponseJson() -> String {
        let txDataXdr = validTransactionDataXdrBase64()
        let returnValue = SCValXDR.u32(10)
        let returnValueXdr = returnValue.xdrEncoded!

        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "latestLedger": 1000000,
                "transactionData": "\(txDataXdr)",
                "minResourceFee": "10000",
                "cost": {
                    "cpuInsns": "1000",
                    "memBytes": "2000"
                },
                "results": [
                    {
                        "auth": [],
                        "xdr": "\(returnValueXdr)"
                    }
                ]
            }
        }
        """
    }

    private func simulateTransactionSuccessJson() -> String {
        return simulateTransactionResponseJson()
    }

    private func simulateTransactionFailureJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "latestLedger": 1000000,
                "error": "Simulation failed: invalid contract"
            }
        }
        """
    }

    private func simulateTransactionWithRestorePreambleJson() -> String {
        let txDataXdr = validTransactionDataXdrBase64()
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "latestLedger": 1000000,
                "restorePreamble": {
                    "transactionData": "\(txDataXdr)",
                    "minResourceFee": "5000"
                }
            }
        }
        """
    }

    private func sendTransactionSuccessJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "PENDING",
                "hash": "abc123def456",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890"
            }
        }
        """
    }

    private func sendTransactionErrorJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "ERROR",
                "hash": "abc123def456",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890",
                "errorResultXdr": "AAAAAAAAAGT////7AAAAAA=="
            }
        }
        """
    }

    private func getTransactionResponseJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "NOT_FOUND",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890",
                "oldestLedger": 900000,
                "oldestLedgerCloseTime": "1234500000"
            }
        }
        """
    }

    private func getTransactionSuccessJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "status": "SUCCESS",
                "latestLedger": 1000000,
                "latestLedgerCloseTime": "1234567890",
                "oldestLedger": 900000,
                "oldestLedgerCloseTime": "1234500000",
                "applicationOrder": 1,
                "ledger": 999999,
                "createdAt": "1234567880",
                "envelopeXdr": "AAAAAA==",
                "resultXdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=",
                "resultMetaXdr": "AAAAAA=="
            }
        }
        """
    }

    private func getLatestLedgerJson() -> String {
        return """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "id": "abc123",
                "sequence": 999900,
                "protocolVersion": 20
            }
        }
        """
    }
}
