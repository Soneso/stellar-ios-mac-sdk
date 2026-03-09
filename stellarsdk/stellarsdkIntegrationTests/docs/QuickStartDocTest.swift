//
//  QuickStartDocTest.swift
//  stellarsdkTests
//
//  Created for documentation testing.
//

import Foundation

import XCTest
import stellarsdk

class QuickStartDocTest: XCTestCase {
    let sdk = StellarSDK.testNet()

    // Tests Snippet 1: "Your First KeyPair"
    func testGenerateKeyPair() {
        // Generate a new random keypair
        let keyPair = try! KeyPair.generateRandomKeyPair()

        // Verify account ID starts with G
        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        // Verify secret seed starts with S
        XCTAssertTrue(keyPair.secretSeed!.hasPrefix("S"))
        // Verify lengths
        XCTAssertEqual(keyPair.accountId.count, 56)
        XCTAssertEqual(keyPair.secretSeed!.count, 56)

        print("Account ID: \(keyPair.accountId)")
        print("Secret Seed: \(keyPair.secretSeed!)")
    }

    // Tests Snippet 2: "Creating Accounts"
    func testCreateAccount() async {
        // Generate a new keypair
        let keyPair = try! KeyPair.generateRandomKeyPair()

        // Fund on testnet (10,000 test XLM)
        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(_):
            print("Account funded: \(keyPair.accountId)")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCreateAccount()", horizonRequestError: error)
            XCTFail("Funding failed: \(error)")
            return
        }

        // Verify account exists and has a balance
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountDetails):
            XCTAssertFalse(accountDetails.balances.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCreateAccount()", horizonRequestError: error)
            XCTFail("Could not load account details")
        }
    }

    // Tests Snippet 3: "Your First Transaction"
    func testSendPayment() async {
        let senderKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationKeyPair = try! KeyPair.generateRandomKeyPair()
        let destinationId = destinationKeyPair.accountId

        // Fund both accounts
        var responseEnum = await sdk.accounts.createTestAccount(accountId: senderKeyPair.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
            XCTFail("Could not fund sender account: \(senderKeyPair.accountId)")
            return
        }

        responseEnum = await sdk.accounts.createTestAccount(accountId: destinationId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
            XCTFail("Could not fund destination account: \(destinationId)")
            return
        }

        // Load current account state from network
        let accountResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
        switch accountResponse {
        case .success(let senderAccount):
            do {
                // Build payment operation
                let paymentOp = try PaymentOperation(
                    sourceAccountId: nil,
                    destinationAccountId: destinationId,
                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    amount: 10.0
                )

                // Build and sign transaction
                let transaction = try Transaction(
                    sourceAccount: senderAccount,
                    operations: [paymentOp],
                    memo: Memo.none
                )

                try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

                // Submit to network
                let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResult {
                case .success(let response):
                    XCTAssertTrue(response.operationCount > 0)
                    print("Payment sent! Hash: \(response.transactionHash)")
                case .destinationRequiresMemo(destinationAccountId: let accountId):
                    XCTFail("Destination \(accountId) requires a memo")
                case .failure(error: let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
                    XCTFail("Transaction failed")
                }
            } catch {
                XCTFail("Error building transaction: \(error)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testSendPayment()", horizonRequestError: error)
            XCTFail("Could not load sender account")
        }
    }

    // Tests Snippet 4: "Complete Example" - Alice sends 100 XLM to Bob
    func testCompleteExample() async {
        // 1. Generate two keypairs
        let alice = try! KeyPair.generateRandomKeyPair()
        let bob = try! KeyPair.generateRandomKeyPair()

        print("Alice: \(alice.accountId)")
        print("Bob: \(bob.accountId)")

        // 2. Fund both accounts on testnet
        var responseEnum = await sdk.accounts.createTestAccount(accountId: alice.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCompleteExample()", horizonRequestError: error)
            XCTFail("Could not fund Alice: \(alice.accountId)")
            return
        }

        responseEnum = await sdk.accounts.createTestAccount(accountId: bob.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCompleteExample()", horizonRequestError: error)
            XCTFail("Could not fund Bob: \(bob.accountId)")
            return
        }

        print("Accounts funded!")

        // 3. Load Alice's account
        let accountResponse = await sdk.accounts.getAccountDetails(accountId: alice.accountId)
        switch accountResponse {
        case .success(let aliceAccount):
            do {
                // 4. Build payment: Alice sends 100 XLM to Bob
                let paymentOp = try PaymentOperation(
                    sourceAccountId: nil,
                    destinationAccountId: bob.accountId,
                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    amount: 100.0
                )

                let transaction = try Transaction(
                    sourceAccount: aliceAccount,
                    operations: [paymentOp],
                    memo: Memo.none
                )

                // 5. Sign with Alice's key
                try transaction.sign(keyPair: alice, network: Network.testnet)

                // 6. Submit to network
                let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
                switch submitResult {
                case .success(let response):
                    XCTAssertTrue(response.operationCount > 0)
                    print("Payment successful! Transaction: \(response.transactionHash)")
                case .destinationRequiresMemo(destinationAccountId: let accountId):
                    XCTFail("Destination \(accountId) requires a memo")
                case .failure(error: let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCompleteExample()", horizonRequestError: error)
                    XCTFail("Payment failed")
                }

                // 7. Check Bob's new balance
                let bobResponse = await sdk.accounts.getAccountDetails(accountId: bob.accountId)
                switch bobResponse {
                case .success(let bobAccount):
                    var foundNativeBalance = false
                    for balance in bobAccount.balances {
                        if balance.assetType == AssetTypeAsString.NATIVE {
                            print("Bob's balance: \(balance.balance) XLM")
                            foundNativeBalance = true
                            // Bob started with 10000 XLM from friendbot, received 100 from Alice
                            // Balance should be > 10000 (10000 + 100 = 10100)
                            if let balanceValue = Decimal(string: balance.balance) {
                                XCTAssertTrue(balanceValue > 10000)
                            }
                        }
                    }
                    XCTAssertTrue(foundNativeBalance, "Bob should have a native XLM balance")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCompleteExample()", horizonRequestError: error)
                    XCTFail("Could not load Bob's account")
                }
            } catch {
                XCTFail("Error building transaction: \(error)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag: "testCompleteExample()", horizonRequestError: error)
            XCTFail("Could not load Alice's account")
        }
    }
}
