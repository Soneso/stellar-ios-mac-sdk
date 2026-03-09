//
//  ReadmeDocTest.swift
//  stellarsdkIntegrationTests
//
//  Validates the three Swift code snippets shown in the repository README.md.
//
//  README snippets tested:
//   1. "Send a payment"       — PaymentOperation, Transaction, sign, submitTransaction
//   2. "Trust an asset"       — ChangeTrustOperation with USDC trustline
//   3. "Call a smart contract" — SorobanClient.forClientOptions, invokeMethod
//
//  README bug findings (both README and this test corrected):
//   • Snippet 2: README used `Asset(type:code:issuer:)` but ChangeTrustOperation requires
//     `ChangeTrustAsset`. Also `limit: Decimal.greatestFiniteMagnitude` overflows Int64;
//     passing `nil` is correct (SDK defaults the XDR limit to Int64.max).
//   • Snippet 3: README used `SCValXDR.forSymbol("World")` which does not exist.
//     The correct enum case factory is `SCValXDR.symbol("World")`.
//

import XCTest
import stellarsdk

final class ReadmeDocTest: XCTestCase {

    // MARK: - Shared fixtures

    let sdk = StellarSDK.testNet()
    let network = Network.testnet
    let rpcUrl = "https://soroban-testnet.stellar.org"
    let helloContractFileName = "soroban_hello_world_contract"

    // MARK: - Snippet 1: Send a payment

    /// Validates the README "Send a payment" snippet.
    ///
    /// The README shows:
    /// ```swift
    /// let paymentOp = PaymentOperation(sourceAccountId: nil,
    ///                                  destinationAccountId: receiverId,
    ///                                  asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    ///                                  amount: 100)
    /// let transaction = try Transaction(sourceAccount: senderAccount,
    ///                                   operations: [paymentOp],
    ///                                   memo: Memo.none)
    /// try transaction.sign(keyPair: senderKeyPair, network: .testnet)
    /// let response = await sdk.transactions.submitTransaction(transaction: transaction)
    /// ```
    /// Status: API is correct. No changes needed to README or test.
    func testSendPayment() async throws {
        // Fund sender and receiver on testnet
        let senderKeyPair = try KeyPair.generateRandomKeyPair()
        let receiverKeyPair = try KeyPair.generateRandomKeyPair()

        var fundEnum = await sdk.accounts.createTestAccount(accountId: senderKeyPair.accountId)
        switch fundEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
            XCTFail("Could not fund sender: \(senderKeyPair.accountId)")
            return
        }

        fundEnum = await sdk.accounts.createTestAccount(accountId: receiverKeyPair.accountId)
        switch fundEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
            XCTFail("Could not fund receiver: \(receiverKeyPair.accountId)")
            return
        }

        // Load sender account state from network
        let senderAccountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        guard case .success(let senderAccount) = senderAccountEnum else {
            XCTFail("Could not load sender account")
            return
        }

        let receiverId = receiverKeyPair.accountId

        // --- Snippet 1 from README (corrected to compile) ---
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: receiverId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100
        )
        let transaction = try Transaction(
            sourceAccount: senderAccount,
            operations: [paymentOp],
            memo: Memo.none
        )
        try transaction.sign(keyPair: senderKeyPair, network: .testnet)
        let response = await sdk.transactions.submitTransaction(transaction: transaction)
        // --- End snippet ---

        switch response {
        case .success(let details):
            XCTAssertTrue(details.operationCount > 0, "Transaction should contain at least one operation")
            print("Payment successful. Hash: \(details.transactionHash)")
        case .destinationRequiresMemo(let destinationAccountId):
            XCTFail("Destination \(destinationAccountId) requires a memo")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
            XCTFail("Transaction submission failed")
        }

        // Verify receiver balance increased
        let receiverAccountEnum = await sdk.accounts.getAccountDetails(accountId: receiverId)
        guard case .success(let receiverAccount) = receiverAccountEnum else {
            XCTFail("Could not load receiver account")
            return
        }

        var foundNativeBalance = false
        for balance in receiverAccount.balances where balance.assetType == AssetTypeAsString.NATIVE {
            foundNativeBalance = true
            if let balanceValue = Decimal(string: balance.balance) {
                // Receiver started with ~10000 XLM from friendbot and received 100 XLM
                XCTAssertTrue(balanceValue > 10000, "Receiver balance should be > 10000 XLM")
            }
        }
        XCTAssertTrue(foundNativeBalance, "Receiver should have a native XLM balance")
    }

    // MARK: - Snippet 2: Trust an asset

    /// Validates the README "Trust an asset" snippet.
    ///
    /// Validates the README "Trust an asset" snippet using `ChangeTrustAsset(canonicalForm:)`.
    func testTrustAsset() async throws {
        let accountKeyPair = try KeyPair.generateRandomKeyPair()

        let fundEnum = await sdk.accounts.createTestAccount(accountId: accountKeyPair.accountId)
        switch fundEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testTrustAsset()", horizonRequestError: error)
            XCTFail("Could not fund account: \(accountKeyPair.accountId)")
            return
        }

        // Load account state from network
        let accountEnum = await sdk.accounts.getAccountDetails(accountId: accountKeyPair.accountId)
        guard case .success(let account) = accountEnum else {
            XCTFail("Could not load account details")
            return
        }

        // --- Snippet 2 from README ---
        let usdc = ChangeTrustAsset(canonicalForm: "USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5")!
        let trustOp = ChangeTrustOperation(
            sourceAccountId: nil,
            asset: usdc,
            limit: nil
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [trustOp],
            memo: Memo.none
        )
        try transaction.sign(keyPair: accountKeyPair, network: .testnet)
        let response = await sdk.transactions.submitTransaction(transaction: transaction)
        // --- End snippet ---

        switch response {
        case .success(let details):
            XCTAssertTrue(details.operationCount > 0, "Transaction should contain at least one operation")
            print("Trustline created. Hash: \(details.transactionHash)")
        case .destinationRequiresMemo(let destinationAccountId):
            XCTFail("Unexpected memo requirement for \(destinationAccountId)")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testTrustAsset()", horizonRequestError: error)
            XCTFail("Trustline transaction failed")
        }

        // Verify the USDC trustline was created
        let updatedAccountEnum = await sdk.accounts.getAccountDetails(accountId: accountKeyPair.accountId)
        guard case .success(let updatedAccount) = updatedAccountEnum else {
            XCTFail("Could not reload account after trustline creation")
            return
        }

        let foundUsdcTrustline = updatedAccount.balances.contains {
            $0.assetCode == "USDC" && $0.assetIssuer == "GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5"
        }
        XCTAssertTrue(foundUsdcTrustline, "USDC trustline should appear in account balances")
    }

    // MARK: - Snippet 3: Call a smart contract

    /// Validates the README "Call a smart contract" snippet.
    ///
    /// README bug: `SCValXDR.forSymbol("World")` does not exist in the SDK.
    ///   The correct enum case factory is `SCValXDR.symbol("World")`.
    ///
    /// The README shows:
    /// ```swift
    /// let result = try await client.invokeMethod(name: "hello",
    ///                                            args: [SCValXDR.forSymbol("World")])
    /// ```
    /// Corrected:
    /// ```swift
    /// let result = try await client.invokeMethod(name: "hello",
    ///                                            args: [SCValXDR.symbol("World")])
    /// ```
    ///
    /// Note: `SorobanClient.forClientOptions` is correct as shown in the README.
    func testCallSmartContract() async throws {
        // Fund the source account
        let keyPair = try KeyPair.generateRandomKeyPair()
        let fundEnum = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch fundEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCallSmartContract()", horizonRequestError: error)
            XCTFail("Could not fund account: \(keyPair.accountId)")
            return
        }

        // Install the hello world contract from the test bundle
        guard let wasmPath = Bundle.module.path(forResource: helloContractFileName, ofType: "wasm") else {
            XCTFail("\(helloContractFileName).wasm not found in test bundle")
            return
        }
        guard let wasmBytes = FileManager.default.contents(atPath: wasmPath) else {
            XCTFail("Could not read \(helloContractFileName).wasm")
            return
        }

        let installRequest = InstallRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: keyPair,
            wasmBytes: wasmBytes,
            enableServerLogging: true
        )
        let wasmHash = try await SorobanClient.install(installRequest: installRequest)
        XCTAssertFalse(wasmHash.isEmpty, "wasmHash should not be empty after installation")

        // Deploy the contract to obtain a contract ID
        let deployRequest = DeployRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: keyPair,
            wasmHash: wasmHash,
            enableServerLogging: true
        )
        let deployedClient = try await SorobanClient.deploy(deployRequest: deployRequest)
        let contractId = deployedClient.contractId
        XCTAssertFalse(contractId.isEmpty, "contractId should not be empty after deployment")

        // --- Snippet 3 from README (corrected) ---
        //
        // README bug fix: SCValXDR.forSymbol("World") does not exist.
        //   Use SCValXDR.symbol("World") instead.
        let client = try await SorobanClient.forClientOptions(
            options: ClientOptions(
                sourceAccountKeyPair: keyPair,
                contractId: contractId,
                network: .testnet,
                rpcUrl: rpcUrl,
                enableServerLogging: false
            )
        )
        let result = try await client.invokeMethod(
            name: "hello",
            args: [SCValXDR.symbol("World")]
        )
        // --- End snippet ---

        // The hello contract returns a Vec<Symbol>: ["Hello", "World"]
        guard let vec = result.vec, vec.count == 2 else {
            XCTFail("Expected a vector with 2 elements, got: \(result)")
            return
        }
        XCTAssertEqual("Hello", vec[0].symbol, "First element should be 'Hello'")
        XCTAssertEqual("World", vec[1].symbol, "Second element should be 'World'")
    }
}
