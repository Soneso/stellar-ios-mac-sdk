//
//  SorobanP27WithDelegatesIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Integration test for the Protocol-27 (CAP-71) ADDRESS_WITH_DELEGATES credential arm.
//
//  Deploys a modular custom account whose __check_auth carries no signature of its own and
//  forwards authorization to its registered delegate signers, plus the standard auth
//  (increment) contract. The increment call is invoked with the modular account as the
//  authorizing address, so the host calls the modular account's __check_auth, which delegates
//  to a registered G-account signer.
//
//  Simulation returns a legacy ADDRESS entry for the modular account; it is converted to
//  ADDRESS_WITH_DELEGATES client-side (preserving the simulated nonce), the delegate node is
//  signed, and the transaction is re-simulated in enforcing mode so the modular account's
//  __check_auth runs and its footprint is captured before submission. Both contracts are
//  deployed with the high-level SorobanClient; the delegated-auth invocation is driven at the
//  SorobanServer level. The submit test is guarded by a protocol-version check so it skips
//  cleanly on networks that do not yet support Protocol 27.
//

import XCTest
import stellarsdk

final class SorobanP27WithDelegatesIntegrationTests: XCTestCase {

    static let testOn = "testnet"
    let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
    let sdk = StellarSDK.testNet()
    let network = Network.testnet
    let rpcUrl = "https://soroban-testnet.stellar.org"

    let modularAccountFileName = "soroban_modular_account_contract"
    let authContractFileName = "soroban_auth_contract"

    var submitterKeyPair: KeyPair!

    enum WithDelegatesTestError: Error {
        case unexpectedFailure(String)
    }

    override func setUp() async throws {
        try await super.setUp()
        sorobanServer.enableLogging = true
        submitterKeyPair = try KeyPair.generateRandomKeyPair()
        await fundTestnetAccount(accountId: submitterKeyPair.accountId)
    }

    /// Authorizes a contract call via ADDRESS_WITH_DELEGATES credentials end to end and verifies success.
    func testInvokeWithAddressWithDelegatesCredentials() async throws {
        let protocolVersion = try await fetchProtocolVersion()
        guard protocolVersion >= 27 else {
            throw XCTSkip("Testnet runs protocol \(protocolVersion); skipping P27 WITH_DELEGATES test")
        }

        // Fund a distinct delegate (a G-account that authorizes on behalf of the modular account).
        let delegateKeyPair = try KeyPair.generateRandomKeyPair()
        await fundTestnetAccount(accountId: delegateKeyPair.accountId)
        let delegateId = delegateKeyPair.accountId

        // Deploy the modular custom account (registering the delegate as an allowed signer) and the
        // auth (increment) business contract, both via the high-level client.
        let modularWasmHash = try await installContract(fileName: modularAccountFileName)
        let signersArg = SCValXDR.vec([SCValXDR.address(try SCAddressXDR(accountId: delegateId))])
        let modularClient = try await deployContract(wasmHash: modularWasmHash, constructorArgs: [signersArg])
        let modularAccountId = modularClient.contractId

        let authWasmHash = try await installContract(fileName: authContractFileName)
        let authClient = try await deployContract(wasmHash: authWasmHash)
        let authContractId = authClient.contractId

        // increment(user = modular account, value = 1) requires the modular account's authorization,
        // so the host invokes its __check_auth, which delegates to the registered G-account.
        let args = [SCValXDR.address(try SCAddressXDR(contractId: modularAccountId)), SCValXDR.u32(1)]
        let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: authContractId, functionName: "increment", functionArguments: args)

        let account = try await getAccount(accountId: submitterKeyPair.accountId)
        let transaction = try Transaction(sourceAccount: account, operations: [invokeOp], memo: Memo.none)

        // Recording-mode simulation: returns the legacy ADDRESS authorization entry for the modular
        // account (with the RPC-assigned nonce). __check_auth is not executed in this pass.
        let simResponse = try await simulate(SimulateTransactionRequest(transaction: transaction))
        guard let auth = simResponse.sorobanAuth else {
            XCTFail("Simulation should return authorization entries")
            return
        }
        XCTAssertEqual(1, auth.count, "increment should require exactly one authorization (the modular account)")

        let expirationLedger = try await fetchLatestLedgerSequence() + 100

        // Convert each address-based entry to the ADDRESS_WITH_DELEGATES arm (preserving the simulated
        // nonce), attach the delegate, and sign only the delegate node. The top-level signature stays
        // void: the modular account verifies no signature of its own and authorizes through its delegate.
        var signedAuth: [SorobanAuthorizationEntryXDR] = []
        for entry in auth {
            switch entry.credentials {
            case .address, .addressV2:
                var withDelegates = try SorobanAuthorizationEntryXDR.withDelegates(
                    entry: entry,
                    delegates: [SorobanDelegateDescriptor(address: delegateId)],
                    expirationLedger: expirationLedger)
                try withDelegates.sign(signer: delegateKeyPair, network: network, forAddress: delegateId)
                signedAuth.append(withDelegates)
            default:
                signedAuth.append(entry)
            }
        }

        // A WITH_DELEGATES entry must be present with a void top-level signature and a signed delegate node.
        var withDelegatesCount = 0
        for entry in signedAuth {
            guard case .addressWithDelegates(let creds) = entry.credentials else { continue }
            withDelegatesCount += 1
            if case .void = creds.addressCredentials.signature {} else {
                XCTFail("The top-level signature must remain void (the modular account signs nothing itself)")
            }
            XCTAssertEqual(1, creds.delegates.count, "Exactly one delegate node should be attached")
            if case .void = creds.delegates[0].signature {
                XCTFail("The delegate node must carry a signature after signing")
            }
        }
        XCTAssertEqual(1, withDelegatesCount, "Expected exactly one ADDRESS_WITH_DELEGATES auth entry")

        // Attach the signed auth and re-simulate in enforcing mode so the modular account's __check_auth
        // runs and its footprint reads (plus the delegate's account entry) are captured. The
        // recording-mode simulation above could not have captured them.
        transaction.setSorobanAuth(auth: signedAuth)
        let reSim = try await simulate(SimulateTransactionRequest(transaction: transaction, authMode: "enforce"))
        guard let reSimData = reSim.transactionData, let reSimFee = reSim.minResourceFee else {
            XCTFail("Enforcing re-simulation must return transaction data and a resource fee")
            return
        }

        // Apply the enforcing simulation's footprint and resource fee; re-pin the already-signed auth.
        transaction.setSorobanTransactionData(data: reSimData)
        transaction.addResourceFee(resourceFee: reSimFee)
        transaction.setSorobanAuth(auth: signedAuth)
        try transaction.sign(keyPair: submitterKeyPair, network: network)

        let txId = try await send(transaction)
        let statusResponse = try await pollTransaction(txId)
        XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status,
                       "Transaction authorized via ADDRESS_WITH_DELEGATES credentials should succeed on Protocol 27")
        // increment returns the modular account's accumulated counter; a fresh account starts at 0,
        // so a single increment by 1 returns 1, proving the delegated authorization succeeded.
        XCTAssertEqual(1, statusResponse.resultValue?.u32,
                       "increment should return the accumulated counter value")
    }

    // MARK: - Helpers

    private func installContract(fileName: String) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm"),
              let contractCode = FileManager.default.contents(atPath: path) else {
            throw WithDelegatesTestError.unexpectedFailure("\(fileName).wasm not found in test bundle")
        }
        let installRequest = InstallRequest(
            rpcUrl: rpcUrl, network: network, sourceAccountKeyPair: submitterKeyPair,
            wasmBytes: contractCode, enableServerLogging: true)
        return try await SorobanClient.install(installRequest: installRequest)
    }

    private func deployContract(wasmHash: String, constructorArgs: [SCValXDR]? = nil) async throws -> SorobanClient {
        let deployRequest = DeployRequest(
            rpcUrl: rpcUrl, network: network, sourceAccountKeyPair: submitterKeyPair,
            wasmHash: wasmHash, constructorArgs: constructorArgs, enableServerLogging: true)
        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }

    private func getAccount(accountId: String) async throws -> Account {
        let responseEnum = await sorobanServer.getAccount(accountId: accountId)
        switch responseEnum {
        case .success(let account):
            return account
        case .failure(let error):
            throw WithDelegatesTestError.unexpectedFailure("getAccount failed: \(error)")
        }
    }

    private func simulate(_ request: SimulateTransactionRequest) async throws -> SimulateTransactionResponse {
        let responseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertNil(response.error, "simulation returned an error: \(String(describing: response.error))")
            return response
        case .failure(let error):
            throw WithDelegatesTestError.unexpectedFailure("simulateTransaction failed: \(error)")
        }
    }

    private func send(_ transaction: Transaction) async throws -> String {
        let responseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status,
                              "sendTransaction returned ERROR status")
            return response.transactionId
        case .failure(let error):
            throw WithDelegatesTestError.unexpectedFailure("sendTransaction failed: \(error)")
        }
    }

    private func pollTransaction(_ txId: String) async throws -> GetTransactionResponse {
        var attempts = 0
        while attempts < 30 {
            let responseEnum = await sorobanServer.getTransaction(transactionHash: txId)
            switch responseEnum {
            case .success(let statusResponse):
                if statusResponse.status != GetTransactionResponse.STATUS_NOT_FOUND {
                    return statusResponse
                }
            case .failure(let error):
                throw WithDelegatesTestError.unexpectedFailure("getTransaction failed: \(error)")
            }
            try await Task.sleep(nanoseconds: UInt64(3 * Double(NSEC_PER_SEC)))
            attempts += 1
        }
        throw WithDelegatesTestError.unexpectedFailure("transaction \(txId) was not confirmed in time")
    }

    private func fetchProtocolVersion() async throws -> Int {
        let responseEnum = await sorobanServer.getLatestLedger()
        switch responseEnum {
        case .success(let ledger):
            return ledger.protocolVersion
        case .failure(let error):
            throw WithDelegatesTestError.unexpectedFailure("getLatestLedger failed: \(error)")
        }
    }

    private func fetchLatestLedgerSequence() async throws -> UInt32 {
        let responseEnum = await sorobanServer.getLatestLedger()
        switch responseEnum {
        case .success(let ledger):
            return ledger.sequence
        case .failure(let error):
            throw WithDelegatesTestError.unexpectedFailure("getLatestLedger failed: \(error)")
        }
    }

    private func fundTestnetAccount(accountId: String) async {
        let responseEnum = await sdk.accounts.createTestAccount(accountId: accountId)
        switch responseEnum {
        case .success:
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(
                tag: "SorobanP27WithDelegatesIntegrationTests.fundTestnetAccount(\(accountId))",
                horizonRequestError: error)
            XCTFail("could not fund account: \(accountId)")
        }
    }
}
