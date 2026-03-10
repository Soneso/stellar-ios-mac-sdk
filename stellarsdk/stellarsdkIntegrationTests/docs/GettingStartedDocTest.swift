//
//  GettingStartedDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class GettingStartedDocTest: XCTestCase {
    let sdk = StellarSDK.testNet()

    // MARK: - Basic Concepts

    func testNetworks() {
        // Snippet: Networks
        let testnet = Network.testnet
        let pubnet = Network.public
        let future = Network.futurenet

        XCTAssertFalse(testnet.passphrase.isEmpty)
        XCTAssertFalse(pubnet.passphrase.isEmpty)
        XCTAssertFalse(future.passphrase.isEmpty)
        XCTAssertNotEqual(testnet.passphrase, pubnet.passphrase)
    }

    func testAssets() {
        // Snippet: Assets
        let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        XCTAssertNotNil(xlm)

        let usdc = Asset(
            type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
            code: "USDC",
            issuer: try! KeyPair(accountId: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
        )!
        XCTAssertNotNil(usdc)
        XCTAssertEqual(usdc.code, "USDC")
    }

    // MARK: - KeyPair Management

    func testGenerateRandomKeyPair() {
        // Snippet: Generate a Random KeyPair
        let keyPair = try! KeyPair.generateRandomKeyPair()

        let accountId = keyPair.accountId
        let secretSeed = keyPair.secretSeed!

        XCTAssertTrue(accountId.hasPrefix("G"))
        XCTAssertTrue(secretSeed.hasPrefix("S"))
    }

    func testImportFromSecretSeed() {
        // Snippet: Import from Secret Seed
        let keyPair = try! KeyPair(secretSeed: "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE")

        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        XCTAssertNotNil(keyPair.secretSeed)
    }

    func testImportFromAccountId() {
        // Snippet: Import from Account ID
        let keyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")

        XCTAssertEqual(keyPair.accountId, "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
    }

    func testMnemonicPhrases() {
        // Snippet: Mnemonic Phrases (SEP-5)
        let mnemonic = WalletUtils.generate24WordMnemonic()

        let keyPair0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        let keyPair1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1)

        XCTAssertTrue(keyPair0.accountId.hasPrefix("G"))
        XCTAssertTrue(keyPair1.accountId.hasPrefix("G"))
        XCTAssertNotEqual(keyPair0.accountId, keyPair1.accountId)

        // Restore from same mnemonic gives same keypair
        let restoredKeyPair = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        XCTAssertEqual(keyPair0.accountId, restoredKeyPair.accountId)
    }

    // MARK: - Account Operations

    func testFundOnTestnet() async {
        // Snippet: Fund on Testnet
        let keyPair = try! KeyPair.generateRandomKeyPair()

        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(let details):
            print("Funded: \(details)")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testFundOnTestnet()", horizonRequestError: error)
            XCTFail("Failed to fund account")
            return
        }

        // Verify the account exists
        let accDetailsResponse = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch accDetailsResponse {
        case .success(let account):
            XCTAssertEqual(account.accountId, keyPair.accountId)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testFundOnTestnet()", horizonRequestError: error)
            XCTFail("Failed to get account details")
        }
    }

    func testCreateAccountOnTestnet() async {
        // Snippet: Create Account (using testnet instead of public for testing)
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let newKeyPair = try! KeyPair.generateRandomKeyPair()

        // Fund the source account
        let fundResponse = await sdk.accounts.createTestAccount(accountId: sourceKeyPair.accountId)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCreateAccountOnTestnet()", horizonRequestError: error)
            XCTFail("could not create source account: \(sourceKeyPair.accountId)")
            return
        }

        let accDetailsResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
        switch accDetailsResponse {
        case .success(let sourceAccount):
            do {
                let createOp = try CreateAccountOperation(
                    sourceAccountId: nil,
                    destinationAccountId: newKeyPair.accountId,
                    startBalance: 10.0
                )

                let transaction = try Transaction(
                    sourceAccount: sourceAccount,
                    operations: [createOp],
                    memo: Memo.none
                )

                try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)
                let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResult {
                case .success(let details):
                    XCTAssert(details.operationCount > 0)
                    print("Account created: \(newKeyPair.accountId), hash: \(details.transactionHash)")
                case .destinationRequiresMemo(let destinationAccountId):
                    XCTFail("destination account \(destinationAccountId) requires memo")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCreateAccountOnTestnet()", horizonRequestError: error)
                    XCTFail("submit transaction error")
                }
            } catch {
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCreateAccountOnTestnet()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }

    func testQueryAccountData() async {
        // Snippet: Query Account Data
        let keyPair = try! KeyPair.generateRandomKeyPair()

        // Fund the account first
        let fundResponse = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testQueryAccountData()", horizonRequestError: error)
            XCTFail("could not create test account: \(keyPair.accountId)")
            return
        }

        let accDetailsResponse = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch accDetailsResponse {
        case .success(let account):
            print("Sequence: \(account.sequenceNumber)")

            // List balances
            var foundNativeBalance = false
            for balance in account.balances {
                switch balance.assetType {
                case AssetTypeAsString.NATIVE:
                    print("XLM: \(balance.balance)")
                    foundNativeBalance = true
                default:
                    print("\(balance.assetCode!): \(balance.balance)")
                }
            }
            XCTAssertTrue(foundNativeBalance)

            // List signers
            XCTAssertFalse(account.signers.isEmpty)
            for signer in account.signers {
                print("Signer: \(signer.key) (weight: \(signer.weight))")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testQueryAccountData()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }

    // MARK: - Transaction Building

    func testCompletePayment() async {
        // Snippet: Complete Payment Example
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationKeyPair = try! KeyPair.generateRandomKeyPair()
        let destination = destinationKeyPair.accountId

        // Fund both accounts
        var fundResponse = await sdk.accounts.createTestAccount(accountId: senderKeyPair.accountId)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCompletePayment()", horizonRequestError: error)
            XCTFail("could not create sender account: \(senderKeyPair.accountId)")
            return
        }

        fundResponse = await sdk.accounts.createTestAccount(accountId: destination)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCompletePayment()", horizonRequestError: error)
            XCTFail("could not create destination account: \(destination)")
            return
        }

        let accDetailsResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        switch accDetailsResponse {
        case .success(let senderAccount):
            do {
                let paymentOp = try PaymentOperation(
                    sourceAccountId: nil,
                    destinationAccountId: destination,
                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    amount: 100
                )

                let transaction = try Transaction(
                    sourceAccount: senderAccount,
                    operations: [paymentOp],
                    memo: Memo.text("Coffee payment")
                )

                try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)
                let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResult {
                case .success(let details):
                    XCTAssertTrue(details.operationCount > 0)
                    print("Payment sent! Hash: \(details.transactionHash)")
                case .destinationRequiresMemo(let destinationAccountId):
                    XCTFail("destination account \(destinationAccountId) requires memo")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCompletePayment()", horizonRequestError: error)
                    XCTFail("submit transaction error")
                }
            } catch {
                XCTFail("Error: \(error)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCompletePayment()", horizonRequestError: error)
            XCTFail("could not load account details for \(senderKeyPair.accountId)")
        }
    }

    // MARK: - Connecting to Networks

    func testConnectingToNetworks() {
        // Snippet: Connecting to Networks
        let testnetSdk = StellarSDK.testNet()
        let publicSdk = StellarSDK.publicNet()
        let customSdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")

        XCTAssertNotNil(testnetSdk)
        XCTAssertNotNil(publicSdk)
        XCTAssertNotNil(customSdk)
    }

    // MARK: - Soroban RPC

    func testSorobanHealthCheck() async {
        // Snippet: Health Check
        let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

        let healthResponse = await server.getHealth()
        switch healthResponse {
        case .success(let health):
            XCTAssertEqual(health.status, HealthStatus.HEALTHY)
            print("Server is healthy")
            print("Latest ledger: \(health.latestLedger)")
            print("Oldest ledger: \(health.oldestLedger)")
        case .failure(let error):
            XCTFail("Health check failed: \(error)")
        }
    }

    func testSorobanLatestLedger() async {
        // Snippet: Latest Ledger Info
        let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

        let ledgerResponse = await server.getLatestLedger()
        switch ledgerResponse {
        case .success(let ledger):
            XCTAssertTrue(ledger.sequence > 0)
            XCTAssertTrue(ledger.protocolVersion > 0)
            print("Ledger sequence: \(ledger.sequence)")
            print("Protocol version: \(ledger.protocolVersion)")
        case .failure(let error):
            XCTFail("Get latest ledger failed: \(error)")
        }
    }

    // MARK: - Error Handling

    func testHorizonRequestErrors() async {
        // Snippet: Horizon Request Errors
        let response = await sdk.accounts.getAccountDetails(accountId: "GINVALIDACCOUNTID")
        switch response {
        case .success(_):
            XCTFail("Should not succeed with invalid account ID")
        case .failure(let error):
            // Expected: error for invalid account ID
            switch error {
            case .notFound(_, _):
                print("Not found (expected)")
            case .badRequest(_, _):
                print("Bad request (expected)")
            default:
                print("Error (expected): \(error)")
            }
        }
    }

    // MARK: - Best Practices

    func testFeeStats() async {
        // Snippet: Set appropriate fees
        let feeResponse = await sdk.feeStats.getFeeStats()
        switch feeResponse {
        case .success(let feeStats):
            let recommendedFee = feeStats.lastLedgerBaseFee
            XCTAssertFalse(recommendedFee.isEmpty)
            print("Recommended fee: \(recommendedFee)")
        case .failure(let error):
            XCTFail("Fee stats failed: \(error)")
        }
    }
}
