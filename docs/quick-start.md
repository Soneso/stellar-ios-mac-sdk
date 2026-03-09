# Quick Start Guide

Get your first Stellar transaction running in 15 minutes. This guide covers the essentials to start using the iOS/macOS SDK.

## What You'll Build

By the end of this guide, you'll:
- Generate a Stellar keypair (wallet)
- Fund an account on testnet
- Send your first payment transaction

## Installation

Add the SDK to your project using Swift Package Manager. In Xcode, go to **File > Add Packages** and enter the repository URL:

```
https://github.com/nickkjordan/stellar-ios-mac-sdk
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nickkjordan/stellar-ios-mac-sdk.git", from: "2.0.0")
]
```

**Requirements:** iOS 13+, macOS 10.15+, Swift 5.7+. See [Getting Started](getting-started.md) for full requirements.

## Your First KeyPair

Generate a random Stellar wallet:

```swift
import stellarsdk

// Generate a new random keypair
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account ID: \(keyPair.accountId)")
print("Secret Seed: \(keyPair.secretSeed!)")

// Example output:
// Account ID: GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB
// Secret Seed: SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
```

**Keep the secret seed safe** — it controls your account!

## Creating Accounts

New Stellar accounts need at least 1 XLM to exist. On testnet, FriendBot gives you 10,000 free test XLM:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Generate a new keypair
let keyPair = try! KeyPair.generateRandomKeyPair()

// Fund on testnet (10,000 test XLM)
let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
switch response {
case .success(_):
    print("Account funded: \(keyPair.accountId)")
case .failure(let error):
    print("Funding failed: \(error)")
}
```

> **Public network:** FriendBot only works on testnet. On the public network, you need an existing funded account to create new accounts using a `CreateAccountOperation`. See [Getting Started](getting-started.md#create-account-on-public-network) for details.

## Your First Transaction

Send a payment on the Stellar testnet:

```swift
import stellarsdk

// Connect to testnet
let sdk = StellarSDK.testNet()

// Your funded account (replace with your secret seed)
let senderKeyPair = try! KeyPair(secretSeed: "SXXX...")
let destinationId = "GYYY..." // Recipient address

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
            amount: 10.0 // Amount in XLM
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
            print("Payment sent! Hash: \(response.transactionHash)")
        case .destinationRequiresMemo(let accountId):
            print("Destination \(accountId) requires a memo")
        case .failure(let error):
            print("Transaction failed: \(error)")
        }
    } catch {
        print("Error building transaction: \(error)")
    }
case .failure(let error):
    print("Could not load account: \(error)")
}
```

## Complete Example

Here's everything together — two accounts, one payment:

```swift
import stellarsdk

// 1. Generate two keypairs
let alice = try! KeyPair.generateRandomKeyPair()
let bob = try! KeyPair.generateRandomKeyPair()

print("Alice: \(alice.accountId)")
print("Bob: \(bob.accountId)")

// 2. Connect to testnet
let sdk = StellarSDK.testNet()

// 3. Fund both accounts on testnet
let fundAlice = await sdk.accounts.createTestAccount(accountId: alice.accountId)
switch fundAlice {
case .success(_):
    break
case .failure(let error):
    print("Failed to fund Alice: \(error)")
}

let fundBob = await sdk.accounts.createTestAccount(accountId: bob.accountId)
switch fundBob {
case .success(_):
    break
case .failure(let error):
    print("Failed to fund Bob: \(error)")
}

print("Accounts funded!")

// 4. Load Alice's account
let accountResponse = await sdk.accounts.getAccountDetails(accountId: alice.accountId)
switch accountResponse {
case .success(let aliceAccount):
    do {
        // 5. Build payment: Alice sends 100 XLM to Bob
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

        // 6. Sign with Alice's key
        try transaction.sign(keyPair: alice, network: Network.testnet)

        // 7. Submit to network
        let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitResult {
        case .success(let response):
            print("Payment successful! Transaction: \(response.transactionHash)")
        case .destinationRequiresMemo(let accountId):
            print("Destination \(accountId) requires a memo")
        case .failure(let error):
            print("Payment failed: \(error)")
        }

        // 8. Check Bob's new balance
        let bobResponse = await sdk.accounts.getAccountDetails(accountId: bob.accountId)
        switch bobResponse {
        case .success(let bobAccount):
            for balance in bobAccount.balances {
                if balance.assetType == AssetTypeAsString.NATIVE {
                    print("Bob's balance: \(balance.balance) XLM")
                }
            }
        case .failure(let error):
            print("Could not load Bob's account: \(error)")
        }
    } catch {
        print("Error building transaction: \(error)")
    }
case .failure(let error):
    print("Could not load Alice's account: \(error)")
}
```

Run this code and you'll see Bob receive 100 XLM from Alice.

## Next Steps

You've created wallets and sent your first Stellar payment.

**Learn more:**
- **[Getting Started Guide](getting-started.md)** — Installation details, error handling, best practices
- **[SDK Usage](sdk-usage.md)** — All SDK features organized by use case
- **[Soroban Guide](soroban.md)** — Smart contract development
- **[SEP Protocols](sep/README.md)** — Stellar Ecosystem Proposals (authentication, deposits, KYC)

**Testnet vs Public Net:**
This guide uses testnet. For production, replace:
- `StellarSDK.testNet()` → `StellarSDK.publicNet()`
- `Network.testnet` → `Network.public`

---

**Navigation:** [← Documentation Home](README.md) | [Getting Started →](getting-started.md)
