//
//  SorobanAtomicSwapTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SorobanAtomicSwapTest: XCTestCase {
    // See https://developers.stellar.org/docs/smart-contracts/example-contracts/atomic-swap
    // See https://developers.stellar.org/docs/learn/smart-contract-internals/authorization

    static let testOn = "testnet" // "futurenet"
    static let rpcUrl = testOn == "testnet" ? "https://soroban-testnet.stellar.org" : "https://rpc-futurenet.stellar.org"
    let sorobanServer = SorobanServer(endpoint: rpcUrl)
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    private static let swapContractFileName = "soroban_atomic_swap_contract"
    private static let tokenContractFileName = "soroban_token_contract"
    private static let mintedAmount: UInt64 = 10_000_000_000_000

    enum AtomicSwapTestError: Error {
        case stepFailed(String)
    }

    // The admin submits every transaction and administers both tokens.
    var adminKeyPair: KeyPair!
    var aliceKeyPair: KeyPair!
    var bobKeyPair: KeyPair!

    override func setUp() async throws {
        try await super.setUp()
        sorobanServer.enableLogging = true

        adminKeyPair = try KeyPair.generateRandomKeyPair()
        aliceKeyPair = try KeyPair.generateRandomKeyPair()
        bobKeyPair = try KeyPair.generateRandomKeyPair()
        print("admin \(adminKeyPair.accountId), alice \(aliceKeyPair.accountId), bob \(bobKeyPair.accountId)")
        for accountId in [adminKeyPair.accountId, aliceKeyPair.accountId, bobKeyPair.accountId] {
            try await fundTestAccountAndAwaitVisibility(accountId: accountId,
                                                        rpc: sorobanServer,
                                                        useFuturenet: network.passphrase != Network.testnet.passphrase)
        }
    }

    func testAtomicSwap() async throws {
        let swapWasmHash = try await installContract(fileName: Self.swapContractFileName)
        let tokenWasmHash = try await installContract(fileName: Self.tokenContractFileName)

        let admin = SCValXDR.address(try SCAddressXDR(accountId: adminKeyPair.accountId))
        let swapContract = try await deployContract(wasmHash: swapWasmHash)
        let tokenA = try await deployContract(wasmHash: tokenWasmHash,
                                              constructorArgs: [admin, .u32(8), .string("TokenA"), .string("TokenA")])
        let tokenB = try await deployContract(wasmHash: tokenWasmHash,
                                              constructorArgs: [admin, .u32(8), .string("TokenB"), .string("TokenB")])
        print("swap contract \(swapContract.contractId), token A \(tokenA.contractId), token B \(tokenB.contractId)")

        let contractIds = [swapContract.contractId, tokenA.contractId, tokenB.contractId]
        for contractId in contractIds {
            try await awaitInstanceVisibility(contractId: contractId)
        }
        for contractId in contractIds {
            try await assertContractInfo(contractId: contractId)
        }

        try await mint(token: tokenA, to: aliceKeyPair.accountId, amount: Self.mintedAmount)
        try await mint(token: tokenB, to: bobKeyPair.accountId, amount: Self.mintedAmount)
        try await assertBalance(of: aliceKeyPair.accountId, on: tokenA, equals: Self.mintedAmount, step: "after mint")
        try await assertBalance(of: bobKeyPair.accountId, on: tokenB, equals: Self.mintedAmount, step: "after mint")

        try await swap(contractId: swapContract.contractId, tokenA: tokenA.contractId, tokenB: tokenB.contractId)

        // The contract takes each side's full amount, pays the counterpart the minimum it
        // asked for and refunds the rest: Alice gives 950 token A, Bob gives 4500 token B.
        try await assertBalance(of: aliceKeyPair.accountId, on: tokenA, equals: 9_999_999_999_050, step: "after swap")
        try await assertBalance(of: aliceKeyPair.accountId, on: tokenB, equals: 4_500, step: "after swap")
        try await assertBalance(of: bobKeyPair.accountId, on: tokenB, equals: 9_999_999_995_500, step: "after swap")
        try await assertBalance(of: bobKeyPair.accountId, on: tokenA, equals: 950, step: "after swap")
    }

    /// Invokes `swap` through `SorobanServer`: Alice and Bob sign their authorization
    /// entries by hand, the admin is the source account and signs the envelope.
    private func swap(contractId: String, tokenA: String, tokenB: String) async throws {
        let args: [SCValXDR] = [
            .address(try SCAddressXDR(accountId: aliceKeyPair.accountId)),
            .address(try SCAddressXDR(accountId: bobKeyPair.accountId)),
            .address(try SCAddressXDR(contractId: tokenA)),
            .address(try SCAddressXDR(contractId: tokenB)),
            .i128(Int128PartsXDR(hi: 0, lo: 1000)), // amount_a
            .i128(Int128PartsXDR(hi: 0, lo: 4500)), // min_b_for_a
            .i128(Int128PartsXDR(hi: 0, lo: 5000)), // amount_b
            .i128(Int128PartsXDR(hi: 0, lo: 950)), // min_a_for_b
        ]
        let operation = try InvokeHostFunctionOperation.forInvokingContract(contractId: contractId,
                                                                             functionName: "swap",
                                                                             functionArguments: args)
        let adminAccount = try await getAccount(accountId: adminKeyPair.accountId)
        let transaction = try Transaction(sourceAccount: adminAccount, operations: [operation], memo: Memo.none)

        let simulation = try await simulate(transaction)
        guard let transactionData = simulation.transactionData,
              let resourceFee = simulation.minResourceFee,
              let auth = simulation.sorobanAuth, !auth.isEmpty else {
            throw AtomicSwapTestError.stepFailed("swap simulation returned no transaction data, resource fee or auth entries")
        }
        transaction.setSorobanTransactionData(data: transactionData)
        transaction.addResourceFee(resourceFee: resourceFee)

        let latestLedger = try await latestLedgerSequence()
        let signatureExpirationLedger = latestLedger + 10
        var aliceSignedEntries = 0
        var bobSignedEntries = 0
        var signedAuth: [SorobanAuthorizationEntryXDR] = []
        for var entry in auth {
            // addressCredentials reads every address arm; the RPC returns ADDRESS_V2 entries.
            let accountId = entry.credentials.addressCredentials?.address.accountId
            if accountId == aliceKeyPair.accountId {
                try entry.sign(signer: aliceKeyPair, network: network, signatureExpirationLedger: signatureExpirationLedger)
                aliceSignedEntries += 1
            } else if accountId == bobKeyPair.accountId {
                try entry.sign(signer: bobKeyPair, network: network, signatureExpirationLedger: signatureExpirationLedger)
                bobSignedEntries += 1
            }
            signedAuth.append(entry)
        }
        XCTAssertEqual(1, aliceSignedEntries, "swap auth entries signed for Alice")
        XCTAssertEqual(1, bobSignedEntries, "swap auth entries signed for Bob")
        transaction.setSorobanAuth(auth: signedAuth)
        let operationCredentials = ((transaction.operations.first as? InvokeHostFunctionOperation)?.auth ?? [])
            .compactMap { $0.credentials.addressCredentials }
            .filter { [aliceKeyPair.accountId, bobKeyPair.accountId].contains($0.address.accountId) }
        XCTAssertEqual(2, operationCredentials.count, "swap auth entries of Alice and Bob in the operation")
        for credentials in operationCredentials {
            XCTAssertEqual(signatureExpirationLedger, credentials.signatureExpirationLedger,
                           "swap auth signature expiration ledger of \(credentials.address.accountId ?? "unknown")")
        }
        try transaction.sign(keyPair: adminKeyPair, network: network)

        let envelopeXdr = try transaction.encodedEnvelope()
        XCTAssertEqual(envelopeXdr, try Transaction(envelopeXdr: envelopeXdr).encodedEnvelope())

        let transactionId = try await send(transaction)
        switch await sorobanServer.pollTransaction(hash: transactionId, maxAttempts: 30, sleepStrategy: { _ in 2 }) {
        case .success(let response):
            guard response.status == GetTransactionResponse.STATUS_SUCCESS else {
                throw AtomicSwapTestError.stepFailed("swap transaction \(transactionId) ended with status \(response.status), result \(response.resultXdr ?? "none")")
            }
            XCTAssertEqual(true, response.resultValue?.isVoid,
                           "swap transaction \(transactionId) returned \(String(describing: response.resultValue)) instead of void")
        case .failure(let error):
            throw AtomicSwapTestError.stepFailed("swap transaction \(transactionId) status could not be read: \(error)")
        }
    }

    private func installContract(fileName: String) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm"),
              let wasmBytes = FileManager.default.contents(atPath: path) else {
            throw AtomicSwapTestError.stepFailed("install: \(fileName).wasm not found in the test bundle")
        }
        let installRequest = InstallRequest(rpcUrl: Self.rpcUrl, network: network, sourceAccountKeyPair: adminKeyPair,
                                            wasmBytes: wasmBytes, enableServerLogging: true)
        do {
            return try await SorobanClient.install(installRequest: installRequest)
        } catch {
            throw AtomicSwapTestError.stepFailed("install of \(fileName).wasm failed: \(error)")
        }
    }

    private func deployContract(wasmHash: String, constructorArgs: [SCValXDR]? = nil) async throws -> SorobanClient {
        let deployRequest = DeployRequest(rpcUrl: Self.rpcUrl, network: network, sourceAccountKeyPair: adminKeyPair,
                                          wasmHash: wasmHash, constructorArgs: constructorArgs, enableServerLogging: true)
        do {
            return try await SorobanClient.deploy(deployRequest: deployRequest)
        } catch {
            throw AtomicSwapTestError.stepFailed("deploy of wasm \(wasmHash) failed: \(error)")
        }
    }

    /// Polls until the RPC serves the instance entry of a newly deployed contract, at most
    /// `maxAttempts` times, 2 seconds apart.
    ///
    /// Only an empty result is retried: the RPC answers it while the deployment is not yet
    /// ingested, and `getContractInfoForContractId` reports it as a failure without retry.
    private func awaitInstanceVisibility(contractId: String, maxAttempts: Int = 30) async throws {
        let instanceKey = LedgerKeyXDR.contractData(LedgerKeyContractDataXDR(contract: try SCAddressXDR(contractId: contractId),
                                                                             key: SCValXDR.ledgerKeyContractInstance,
                                                                             durability: ContractDataDurability.persistent))
        guard let encodedKey = instanceKey.xdrEncoded else {
            throw AtomicSwapTestError.stepFailed("instance visibility: the instance key of contract \(contractId) could not be encoded")
        }
        let start = DispatchTime.now().uptimeNanoseconds
        for attempt in 1...maxAttempts {
            switch await sorobanServer.getLedgerEntries(base64EncodedKeys: [encodedKey]) {
            case .success(let response):
                if !response.entries.isEmpty {
                    return
                }
            case .failure(let error):
                throw AtomicSwapTestError.stepFailed("instance visibility of contract \(contractId) failed at attempt \(attempt): \(error)")
            }
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        let elapsedSeconds = (DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
        throw AtomicSwapTestError.stepFailed("instance visibility: contract \(contractId) not visible after \(maxAttempts) attempts in \(elapsedSeconds) seconds")
    }

    private func assertContractInfo(contractId: String) async throws {
        switch await sorobanServer.getContractInfoForContractId(contractId: contractId) {
        case .success(let info):
            XCTAssertGreaterThan(info.specEntries.count, 0, "spec entries of contract \(contractId)")
            XCTAssertGreaterThan(info.metaEntries.count, 0, "meta entries of contract \(contractId)")
        case .parsingFailure(let error):
            throw AtomicSwapTestError.stepFailed("contract info of \(contractId) could not be parsed: \(error)")
        case .rpcFailure(let error):
            throw AtomicSwapTestError.stepFailed("contract info of \(contractId) could not be loaded: \(error)")
        }
    }

    private func mint(token: SorobanClient, to accountId: String, amount: UInt64) async throws {
        do {
            let args = try token.getContractSpec().funcArgsToXdrSCValues(name: "mint", args: ["to": accountId, "amount": Int(amount)])
            _ = try await token.invokeMethod(name: "mint", args: args)
        } catch {
            throw AtomicSwapTestError.stepFailed("mint of \(amount) on token \(token.contractId) to \(accountId) failed: \(error)")
        }
    }

    private func assertBalance(of accountId: String, on token: SorobanClient, equals expected: UInt64, step: String) async throws {
        let balance: SCValXDR
        do {
            let args = try token.getContractSpec().funcArgsToXdrSCValues(name: "balance", args: ["id": accountId])
            balance = try await token.invokeMethod(name: "balance", args: args)
        } catch {
            throw AtomicSwapTestError.stepFailed("\(step): balance of \(accountId) on token \(token.contractId) could not be read: \(error)")
        }
        XCTAssertEqual(String(expected), balance.i128String, "\(step): balance of \(accountId) on token \(token.contractId)")
    }

    private func getAccount(accountId: String) async throws -> Account {
        switch await sorobanServer.getAccount(accountId: accountId) {
        case .success(let account):
            return account
        case .failure(let error):
            throw AtomicSwapTestError.stepFailed("account \(accountId) could not be loaded: \(error)")
        }
    }

    private func latestLedgerSequence() async throws -> UInt32 {
        switch await sorobanServer.getLatestLedger() {
        case .success(let ledger):
            return ledger.sequence
        case .failure(let error):
            throw AtomicSwapTestError.stepFailed("latest ledger could not be loaded: \(error)")
        }
    }

    private func simulate(_ transaction: Transaction) async throws -> SimulateTransactionResponse {
        switch await sorobanServer.simulateTransaction(simulateTxRequest: SimulateTransactionRequest(transaction: transaction)) {
        case .success(let response):
            if let error = response.error {
                throw AtomicSwapTestError.stepFailed("swap simulation returned an error: \(error)")
            }
            return response
        case .failure(let error):
            throw AtomicSwapTestError.stepFailed("swap simulation failed: \(error)")
        }
    }

    private func send(_ transaction: Transaction) async throws -> String {
        switch await sorobanServer.sendTransaction(transaction: transaction) {
        case .success(let response):
            guard response.status != SendTransactionResponse.STATUS_ERROR else {
                throw AtomicSwapTestError.stepFailed("swap submission returned ERROR, result \(response.errorResultXdr ?? "none")")
            }
            return response.transactionId
        case .failure(let error):
            throw AtomicSwapTestError.stepFailed("swap submission failed: \(error)")
        }
    }
}
