//
//  SdkUsageAccountsDocTest.swift
//  stellarsdk
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SdkUsageAccountsDocTest: XCTestCase {
    let sdk = StellarSDK.testNet()

    // MARK: - Keypairs

    func testCreateKeypairs() {
        // Snippet: Creating Keypairs
        let keyPair = try! KeyPair.generateRandomKeyPair()
        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        XCTAssertNotNil(keyPair.secretSeed)
        XCTAssertTrue(keyPair.secretSeed!.hasPrefix("S"))

        // From existing secret seed
        let keyPair2 = try! KeyPair(secretSeed: "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE")
        XCTAssertTrue(keyPair2.accountId.hasPrefix("G"))

        // Public-key-only keypair (cannot sign)
        let publicOnly = try! KeyPair(accountId: keyPair.accountId)
        XCTAssertEqual(publicOnly.accountId, keyPair.accountId)
        XCTAssertNil(publicOnly.privateKey)
    }

    // MARK: - Loading an Account

    func testLoadAccount() async {
        // Snippet: Loading an Account
        let keyPair = try! KeyPair.generateRandomKeyPair()

        // Fund via friendbot first
        let fundResponse = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            XCTFail("Failed to fund: \(error)")
            return
        }

        // Load account data from network
        let response = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch response {
        case .success(let account):
            XCTAssertEqual(account.accountId, keyPair.accountId)
            XCTAssertTrue(account.sequenceNumber > 0)

            // Check balances
            var foundNative = false
            for balance in account.balances {
                switch balance.assetType {
                case AssetTypeAsString.NATIVE:
                    XCTAssertFalse(balance.balance.isEmpty)
                    foundNative = true
                default:
                    break
                }
            }
            XCTAssertTrue(foundNative)
        case .failure(let error):
            XCTFail("Error loading account: \(error)")
        }
    }

    // MARK: - Funding Testnet Accounts

    func testFundTestnetAccount() async {
        // Snippet: Funding Testnet Accounts
        let keyPair = try! KeyPair.generateRandomKeyPair()

        let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch response {
        case .success(_):
            // Verify account exists
            let accResponse = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
            switch accResponse {
            case .success(let account):
                XCTAssertEqual(account.accountId, keyPair.accountId)
            case .failure(let error):
                XCTFail("Account not found after funding: \(error)")
            }
        case .failure(let error):
            XCTFail("Failed to fund: \(error)")
        }
    }

    // MARK: - HD Wallets (SEP-5)

    func testHDWallets() {
        // Snippet: HD Wallets (SEP-5)
        let mnemonic = WalletUtils.generate24WordMnemonic()
        XCTAssertFalse(mnemonic.isEmpty)

        let account0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        let account1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1)

        XCTAssertTrue(account0.accountId.hasPrefix("G"))
        XCTAssertTrue(account1.accountId.hasPrefix("G"))
        XCTAssertNotEqual(account0.accountId, account1.accountId)

        // Restore from same mnemonic gives same keypair
        let restored = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        XCTAssertEqual(account0.accountId, restored.accountId)
    }

    func testHDWalletsWithPassphrase() {
        // Snippet: HD Wallets with passphrase
        let mnemonic = WalletUtils.generate24WordMnemonic()

        let withPassphrase = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "my-secret", index: 0)
        let withoutPassphrase = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)

        // Same mnemonic with different passphrase produces different accounts
        XCTAssertNotEqual(withPassphrase.accountId, withoutPassphrase.accountId)
    }

    // MARK: - Muxed Accounts

    func testMuxedAccounts() async {
        // Snippet: Muxed Accounts
        let keyPair = try! KeyPair.generateRandomKeyPair()

        // Fund the base account
        let fundResponse = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            XCTFail("Failed to fund: \(error)")
            return
        }

        // Create muxed account from base account + ID
        let muxedAccount = try! MuxedAccount(accountId: keyPair.accountId, id: 123456789)

        XCTAssertTrue(muxedAccount.accountId.hasPrefix("M"))
        XCTAssertEqual(muxedAccount.id, 123456789)
        XCTAssertEqual(muxedAccount.ed25519AccountId, keyPair.accountId)

        // Parse existing muxed address
        let muxed = try! MuxedAccount(accountId: muxedAccount.accountId)
        XCTAssertEqual(muxed.ed25519AccountId, keyPair.accountId)
        XCTAssertEqual(muxed.id, 123456789)
    }

    // MARK: - Connecting to Networks

    func testConnectingToNetworks() {
        // Snippet: Connecting to Networks
        let testSdk = StellarSDK.testNet()
        XCTAssertEqual(testSdk.horizonURL, StellarSDK.testNetUrl)

        let publicSdk = StellarSDK.publicNet()
        XCTAssertEqual(publicSdk.horizonURL, StellarSDK.publicNetUrl)

        let futureSdk = StellarSDK.futureNet()
        XCTAssertEqual(futureSdk.horizonURL, StellarSDK.futureNetUrl)

        let customSdk = StellarSDK(withHorizonUrl: "https://my-horizon-server.example.com")
        XCTAssertEqual(customSdk.horizonURL, "https://my-horizon-server.example.com")

        let testnet = Network.testnet
        let pubnet = Network.public
        let future = Network.futurenet

        XCTAssertFalse(testnet.passphrase.isEmpty)
        XCTAssertFalse(pubnet.passphrase.isEmpty)
        XCTAssertFalse(future.passphrase.isEmpty)
    }

    // MARK: - Check Account Exists

    func testCheckAccountExists() async {
        // Snippet: Check if Account Exists
        let keyPair = try! KeyPair.generateRandomKeyPair()

        // Account does not exist yet
        let response1 = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch response1 {
        case .success(_):
            XCTFail("Account should not exist yet")
        case .failure(let error):
            if case .notFound = error {
                // Expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Fund and check again
        let fundResponse = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
        switch fundResponse {
        case .success(_):
            break
        case .failure(let error):
            XCTFail("Failed to fund: \(error)")
            return
        }

        let response2 = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
        switch response2 {
        case .success(let account):
            XCTAssertEqual(account.accountId, keyPair.accountId)
        case .failure(let error):
            XCTFail("Account should exist now: \(error)")
        }
    }

    // MARK: - Message Signing (SEP-53)

    func testMessageSigning() {
        // Snippet: Sign and Verify a Message
        let keyPair = try! KeyPair(secretSeed: "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE")

        let message = "Please sign this message to verify your identity"
        let signature = try! keyPair.signMessage(message)
        XCTAssertFalse(signature.isEmpty)

        // Verify with full keypair
        let isValid = try! keyPair.verifyMessage(message, signature: signature)
        XCTAssertTrue(isValid)

        // Verify with public key only
        let publicOnly = try! KeyPair(accountId: keyPair.accountId)
        let isValidPublicOnly = try! publicOnly.verifyMessage(message, signature: signature)
        XCTAssertTrue(isValidPublicOnly)

        // Wrong message fails verification
        let wrongResult = try! keyPair.verifyMessage("wrong message", signature: signature)
        XCTAssertFalse(wrongResult)
    }
}
