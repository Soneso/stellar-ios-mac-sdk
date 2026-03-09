# Getting Started Guide

**Looking for a quick start? See [Quick Start](quick-start.md) to get running in 15 minutes.**

This guide covers the fundamentals of the Stellar iOS/macOS SDK.

## Table of Contents

- [Installation](#installation)
- [Basic Concepts](#basic-concepts)
- [KeyPair Management](#keypair-management)
- [Account Operations](#account-operations)
- [Transaction Building](#transaction-building)
- [Connecting to Networks](#connecting-to-networks)
- [Soroban RPC](#soroban-rpc)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Next Steps](#next-steps)

## Installation

Add the SDK to your project using Swift Package Manager. In Xcode, go to **File > Add Package Dependencies** and enter the repository URL:

```
https://github.com/nicklama/stellar-ios-mac-sdk
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nicklama/stellar-ios-mac-sdk.git", from: "2.0.0")
]
```

**Requirements:** iOS 13+ / macOS 12+, Swift 5.7+.

## Basic Concepts

### Networks

Stellar has multiple networks with unique passphrases:

```swift
import stellarsdk

let testnet = Network.testnet    // Development (free test XLM via Friendbot)
let pubnet = Network.public      // Production (real assets)
let future = Network.futurenet   // Upcoming protocol features
```

### Accounts

Every Stellar account has:
- **Account ID** (public key): Starts with `G`. Safe to share.
- **Secret Seed** (private key): Starts with `S`. Keep secret!

An account must hold at least 1 XLM to exist (the base reserve).

### Assets

Stellar supports two types of assets:
- **Native (XLM):** The built-in currency used for fees and account reserves.
- **Issued assets:** Tokens created by any account (the "issuer"). To hold an issued asset, you must first establish a trustline to the issuer.

```swift
import stellarsdk

// Native XLM
let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!

// Issued asset (code + issuer account)
let usdc = Asset(
    type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
    code: "USDC",
    issuer: try! KeyPair(accountId: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
)!
```

### Operations and Transactions

A **transaction** groups one or more **operations** that execute atomically. Common operations:

- `CreateAccountOperation` -- Create a new account
- `PaymentOperation` -- Send assets
- `ChangeTrustOperation` -- Establish a trustline
- `ManageSellOfferOperation` -- Place a DEX order

## KeyPair Management

Manage cryptographic keys for signing transactions and identifying accounts.

### Generate a Random KeyPair

Create a new wallet with a random keypair. The account ID is your public address; the secret seed is your private key for signing transactions.

```swift
import stellarsdk

let keyPair = try! KeyPair.generateRandomKeyPair()

let accountId = keyPair.accountId     // GCFXHS4GXL6B... (public)
let secretSeed = keyPair.secretSeed!  // SAV76USXIJOB... (private)
```

### Import from Secret Seed

If you already have a secret seed (from a backup or another wallet), you can restore the full keypair. This lets you sign transactions.

```swift
import stellarsdk

// Restore keypair from seed (can sign transactions)
let keyPair = try! KeyPair(secretSeed: "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE")
```

### Import from Account ID

You can create a keypair from just an account ID (public key). This is useful for verifying signatures or specifying destinations, but you can't sign transactions without the secret seed.

```swift
import stellarsdk

// Public key only (cannot sign)
let keyPair = try! KeyPair(accountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D")
```

### Mnemonic Phrases (SEP-5)

For wallet backup and recovery. The SDK supports 12 or 24 word phrases:

```swift
import stellarsdk

// Generate mnemonic -- choose your preferred length:
let mnemonic = WalletUtils.generate24WordMnemonic()  // 24 words (recommended)
// or: let mnemonic = WalletUtils.generate12WordMnemonic()  // 12 words

// Store these words securely -- they control all derived accounts

// Derive multiple accounts from one mnemonic
let keyPair0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0) // First account
let keyPair1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1) // Second account

// Restore from existing words
let words = "your twelve or twenty four word phrase goes here ..."
let restoredKeyPair = try! WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
```

## Account Operations

Create accounts, fund them, and query their data from the network.

### Fund on Testnet

On testnet, Friendbot gives you 10,000 free test XLM to experiment with. This is the easiest way to get started.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let keyPair = try! KeyPair.generateRandomKeyPair()

let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
switch response {
case .success(let details):
    print("Funded: \(details)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Create Account on Public Network

On the public network, there's no Friendbot. You need an existing funded account to create new accounts using the `CreateAccountOperation`. The new account receives a starting balance from the source account.

```swift
import stellarsdk

let sdk = StellarSDK.publicNet()

let sourceKeyPair = try! KeyPair(secretSeed: "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF")
let newKeyPair = try! KeyPair.generateRandomKeyPair()

// Source account must already exist and have enough XLM for the new account's starting balance + fees
let accDetailsResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
switch accDetailsResponse {
case .success(let sourceAccount):
    do {
        let createOp = try CreateAccountOperation(
            sourceAccountId: nil,
            destinationAccountId: newKeyPair.accountId,
            startBalance: 10.0 // Starting balance in XLM
        )

        let transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [createOp],
            memo: Memo.none
        )

        try transaction.sign(keyPair: sourceKeyPair, network: Network.public)
        let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitResult {
        case .success(let details):
            print("Account created: \(newKeyPair.accountId)")
            print("Hash: \(details.transactionHash)")
        case .destinationRequiresMemo(let destinationAccountId):
            print("Destination \(destinationAccountId) requires memo")
        case .failure(let error):
            print("Error: \(error)")
        }
    } catch {
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Query Account Data

Load an account from the network to check its balances, sequence number, and signers. Always verify an account exists before sending payments to it.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let accountId = "GCQHNQR2VM5OPXSTWZSF7ISDLE5XZRF73LNU6EOZXFQG2IJFU4WB7VFY"

let accDetailsResponse = await sdk.accounts.getAccountDetails(accountId: accountId)
switch accDetailsResponse {
case .success(let account):
    print("Sequence: \(account.sequenceNumber)")

    // List balances
    for balance in account.balances {
        switch balance.assetType {
        case AssetTypeAsString.NATIVE:
            print("XLM: \(balance.balance)")
        default:
            print("\(balance.assetCode!): \(balance.balance)")
        }
    }

    // List signers
    for signer in account.signers {
        print("Signer: \(signer.key) (weight: \(signer.weight))")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Transaction Building

Construct transactions by adding operations, setting fees, and preparing for submission.

### Builder Pattern

Transactions are built by passing operations and options to the `Transaction` initializer:

```swift
import stellarsdk

// sourceAccount loaded via await sdk.accounts.getAccountDetails(...)
// operation1, operation2 built via operation constructors (see below)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [operation1, operation2],
    memo: Memo.text("Payment reference"),
    maxOperationFee: 200 // 200 stroops per operation
)
```

### Building Operations

Each operation type has its own constructor. Build the operations first, then add them to the transaction. Operations execute in order.

```swift
import stellarsdk

// Build operations
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDESTINATION...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.50
)

let trustAsset = Asset(
    type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
    code: "USD",
    issuer: try! KeyPair(accountId: "GISSUER...")
)!
let changeTrustAsset = ChangeTrustAsset(
    type: trustAsset.type,
    code: trustAsset.code,
    issuer: trustAsset.issuer
)!
let trustOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: changeTrustAsset,
    limit: nil
)

// Add operations to transaction
let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [trustOp, paymentOp],  // First: establish trustline, Then: send payment
    memo: Memo.none
)
```

### Signing and Submitting

Transactions need a valid signature before the network accepts them. The signature proves the source account authorized the transaction. Use the correct network passphrase when signing -- testnet and public have different passphrases, and a mismatch causes the transaction to fail.

```swift
import stellarsdk

// After building a transaction, sign it with the source account's keypair
// Use the correct network -- testnet and public have different passphrases!
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

// Multi-sig accounts: add signatures from all required signers
// try transaction.sign(keyPair: keyPairA, network: Network.testnet)
// try transaction.sign(keyPair: keyPairB, network: Network.testnet)

// Submit to the network
let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResult {
case .success(let details):
    print("Hash: \(details.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires memo")
case .failure(let error):
    print("Error: \(error)")
}
```

### Complete Payment Example

Here's a full example that sends 100 XLM on testnet. It loads the sender's account, builds a payment, signs it, and submits to the network.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let senderKeyPair = try! KeyPair(secretSeed: "SA52PD5FN425CUONRMMX2CY5HB6I473A5OYNIVU67INROUZ6W4SPHXZB")
let destination = "GCRFFUKMUWWBRIA6ABRDFL5NKO6CKDB2IOX7MOS2TRLXNXQD255Z2MYG"

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
            print("Payment sent! Hash: \(details.transactionHash)")
        case .destinationRequiresMemo(let accountId):
            print("Destination \(accountId) requires memo")
        case .failure(let error):
            print("Error: \(error)")
        }
    } catch {
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Connecting to Networks

The SDK connects to Horizon servers to query account data and submit transactions. Use testnet for development, public network for production.

```swift
import stellarsdk

// Testnet (https://horizon-testnet.stellar.org)
let testnetSdk = StellarSDK.testNet()

// Public network (https://horizon.stellar.org)
let publicSdk = StellarSDK.publicNet()

// Custom Horizon server
let customSdk = StellarSDK(withHorizonUrl: "https://horizon.your-company.com")
```

## Soroban RPC

Soroban is Stellar's smart contract platform. To interact with smart contracts, you connect to a Soroban RPC server instead of Horizon.

### Connecting to Soroban RPC

Create a `SorobanServer` instance to interact with the Soroban RPC endpoint.

```swift
import stellarsdk

// Testnet
let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Mainnet
let mainnetServer = SorobanServer(endpoint: "https://soroban.stellar.org")
```

### Health Check

Check if the Soroban RPC server is running and see which ledger range it has available.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let healthResponse = await server.getHealth()
switch healthResponse {
case .success(let health):
    if health.status == HealthStatus.HEALTHY {
        print("Server is healthy")
        print("Latest ledger: \(health.latestLedger)")
        print("Oldest ledger: \(health.oldestLedger)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Latest Ledger Info

Get the current ledger sequence and protocol version. Useful for checking network status.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let ledgerResponse = await server.getLatestLedger()
switch ledgerResponse {
case .success(let ledger):
    print("Ledger sequence: \(ledger.sequence)")
    print("Protocol version: \(ledger.protocolVersion)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Smart Contract Interaction

For deploying contracts, invoking functions, and handling Soroban transactions, see the [Soroban Guide](soroban.md).

## Error Handling

### Horizon Request Errors

Network requests can fail for many reasons -- invalid account IDs, network issues, or server errors. The SDK returns result enums for all Horizon requests that you can pattern-match on.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccountDetails(accountId: "GINVALIDACCOUNTID")
switch response {
case .success(let account):
    print("Account: \(account.accountId)")
case .failure(let error):
    switch error {
    case .notFound(let message, _):
        print("Not found: \(message)")
    case .badRequest(let message, _):
        print("Bad request: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

### Transaction Failures

When a transaction fails, the error response contains result codes explaining what went wrong -- both at the transaction level and for each operation.

```swift
import stellarsdk

let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResult {
case .success(let details):
    print("Success! Hash: \(details.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires memo")
case .failure(let error):
    switch error {
    case .badRequest(_, let errorResponse):
        if let extras = errorResponse?.extras,
           let resultCodes = extras.resultCodes {
            print("Transaction: \(resultCodes.transaction ?? "unknown")")
            if let opCodes = resultCodes.operations {
                for (i, code) in opCodes.enumerated() {
                    print("Operation \(i): \(code)")
                }
            }
        }
    default:
        print("Error: \(error)")
    }
}
```

### Common Error Codes

| Code | Meaning |
|------|---------|
| `tx_bad_seq` | Wrong sequence number. Reload account and retry. |
| `tx_insufficient_fee` | Fee too low. Increase `maxOperationFee`. |
| `tx_insufficient_balance` | Not enough XLM for operation + fees + reserves. |
| `op_underfunded` | Source lacks funds for payment amount. |
| `op_no_trust` | Destination lacks trustline for asset. |
| `op_line_full` | Destination trustline limit exceeded. |
| `op_no_destination` | Destination account doesn't exist. |

## Best Practices

**1. Never expose secret seeds**
```swift
// Bad
print("Error with account: \(keyPair.secretSeed!)")

// Good
print("Error with account: \(keyPair.accountId)")
```

**2. Use testnet for development** -- Always test against testnet first.

**3. Set appropriate fees**
```swift
import stellarsdk

let feeResponse = await sdk.feeStats.getFeeStats()
switch feeResponse {
case .success(let feeStats):
    let recommendedFee = feeStats.lastLedgerBaseFee
    print("Recommended fee: \(recommendedFee)")
case .failure(let error):
    print("Error: \(error)")
}
```

**4. Handle errors gracefully** -- Use the result enum pattern to handle all possible outcomes.

**5. Verify destination exists** -- Before payments, check if account exists. If not, use `CreateAccountOperation`.

**6. Use memos for exchanges** -- Many exchanges require a memo to credit your account.

## Next Steps

- **[Quick Start](quick-start.md)** -- First transaction in 15 minutes
- **[SDK Usage](sdk-usage.md)** -- All operations, queries, and patterns
- **[SEP Protocols](sep/README.md)** -- Authentication, deposits, cross-border payments
- **[Soroban Guide](soroban.md)** -- Smart contract interaction

---

**Navigation**: [<- Quick Start](quick-start.md) | [SDK Usage ->](sdk-usage.md)
