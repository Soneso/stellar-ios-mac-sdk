---
name: stellar-ios-sdk
description: Build Stellar blockchain applications in Swift using stellar-ios-mac-sdk. Use when generating Swift code for transaction building, signing, Horizon API queries, Soroban RPC, smart contract deployment and invocation, XDR encoding/decoding, and SEP protocol integration. Covers 26+ operations, 50 Horizon endpoints, 12 RPC methods, and 17 SEP implementations with Swift async/await and callback-based streaming patterns. Full Swift 6 strict concurrency support (all types Sendable).
license: Apache 2.0
compatibility: Requires Swift 6.0+, iOS 15+, macOS 12+. Zero external dependencies.
metadata:
  version: "1.0.0"
  sdk_version: "3.4.5"
  last_updated: "2026-03-10"
---

# Stellar SDK for iOS & Mac

## Overview

The Stellar iOS/Mac SDK (`stellarsdk`) is a native Swift library for building Stellar applications on iOS 15+ and macOS 12+. It provides 100% Horizon API coverage (50/50 endpoints), 100% Soroban RPC coverage (12/12 methods), and 17 SEP implementations. All public APIs use Swift async/await with Swift 6 strict concurrency. The SDK has zero external dependencies.

**Module name:** `stellarsdk` (always lowercase in import statements)

## Installation

### Swift Package Manager

```swift
.package(name: "stellarsdk", url: "git@github.com:Soneso/stellar-ios-mac-sdk.git", from: "3.4.5")
```

### CocoaPods

```ruby
pod 'stellar-ios-mac-sdk', '~> 3.4.5'
```

> All code examples below assume `import stellarsdk`.
>
> If you can't find a constructor or method signature in this file or the topic references, grep `references/api_reference.md` — it has all public class/method signatures.

## 1. Stellar Basics

Fundamental Stellar concepts and SDK patterns.

### Keys and KeyPairs

```swift
// Generate new keypair
let keyPair = try KeyPair.generateRandomKeyPair()
let accountId = keyPair.accountId          // G-address
guard let secretSeed = keyPair.secretSeed else {
    throw StellarSDKError.invalidArgument(message: "Failed to get secret seed")
}
// WARNING: Store secretSeed securely (iOS Keychain). Never log or hardcode it.

// From existing seed
let keyPair = try KeyPair(secretSeed: seed)
let publicOnly = try KeyPair(accountId: "GABC...")  // public-only, cannot sign
```

### Accounts

```swift
// Fund testnet account (FriendBot)
let keyPair = try KeyPair.generateRandomKeyPair()
let sdk = StellarSDK.testNet()
let responseEnum = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)

// Query account
let responseEnum = await sdk.accounts.getAccountDetails(accountId: accountId)
switch responseEnum {
case .success(let accountResponse):
    print("Sequence: \(accountResponse.sequenceNumber)")
    print("Subentry count: \(accountResponse.subentryCount)")  // Trustlines, offers, data entries
    for balance in accountResponse.balances {
        print("Asset: \(balance.assetType), Balance: \(balance.balance)")
        // WRONG: balance.assetType == AssetType.ASSET_TYPE_NATIVE (comparing String to Int32)
        // CORRECT: balance.assetType == "native" (response fields are strings)
        if balance.assetType == "native" {
            print("  → Native XLM balance")
        } else if balance.assetType == "credit_alphanum4" || balance.assetType == "credit_alphanum12" {
            print("  → Custom asset: \(balance.assetCode ?? ""):\(balance.assetIssuer ?? "")")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Assets

```swift
// Native XLM
let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!

// Issued asset (4-char code)
let issuerKeyPair = try KeyPair(accountId: "GISSUER...")
let usdc = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
                 code: "USDC",
                 issuer: issuerKeyPair)!

// From canonical form
let asset = Asset(canonicalForm: "USDC:GISSUER...")!
```

### Networks

```swift
// Pre-configured: Network.testnet, Network.public, Network.futurenet
let testnetSdk = StellarSDK.testNet()
let publicSdk = StellarSDK.publicNet()

// Custom Horizon URL
let customSdk = StellarSDK(withHorizonUrl: "https://my-horizon.example.com")
```

## 2. Horizon API - Fetching Data

Query patterns for retrieving blockchain data. All queries return result enums (`.success`/`.failure`).

### Query Accounts & Transactions

```swift
let sdk = StellarSDK.testNet()

// Account details
let accountEnum = await sdk.accounts.getAccountDetails(accountId: "GABC...")

// Transactions for account
let txEnum = await sdk.transactions.getTransactions(
    forAccount: "GABC...",
    from: nil,
    order: .descending,
    limit: 10
)

// Pagination: use cursor from last record's pagingToken
switch txEnum {
case .success(let page):
    if let lastRecord = page.records.last {
        let nextPage = await sdk.transactions.getTransactions(
            forAccount: "GABC...",
            from: lastRecord.pagingToken,
            order: .descending,
            limit: 10
        )
    }
case .failure(let error):
    print("Error: \(error)")
}
```

For all Horizon endpoints (50/50), advanced queries, and memo inspection:
[Horizon API Reference](./references/horizon_api.md)

## 3. Horizon API - Streaming

Real-time update patterns using Server-Sent Events. **You must hold a strong reference** to the stream item or it will close immediately.

```swift
class PaymentMonitor {
    private var streamItem: OperationsStreamItem?  // Strong reference required!
    private let sdk = StellarSDK.testNet()

    func startStreaming(accountId: String) {
        streamItem = sdk.payments.stream(
            for: .paymentsForAccount(account: accountId, cursor: "now")
        )

        streamItem?.onReceive { response in
            switch response {
            case .response(let id, let operationResponse):
                if let payment = operationResponse as? PaymentOperationResponse {
                    print("[\(id)] Payment: \(payment.amount) \(payment.assetCode ?? "XLM")")
                }
            case .error(let error):
                print("Stream error: \(error?.localizedDescription ?? "unknown")")
            default:
                break
            }
        }
    }

    func stopStreaming() {
        streamItem?.closeStream()
        streamItem = nil
    }
}
```

For reconnection patterns and all streaming endpoints:
[Horizon Streaming Guide](./references/horizon_streaming.md)

## 4. Transactions & Operations

Complete transaction lifecycle: Build -> Sign -> Submit.

```swift
let sdk = StellarSDK.testNet()

// 1. Load sender account (AccountResponse conforms to TransactionAccount)
let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

// 2. Create payment operation
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0  // Decimal type
)

// 3. Build transaction
let transaction = try Transaction(
    sourceAccount: accountResponse,
    operations: [paymentOp],
    memo: Memo.text("Payment"),
    maxOperationFee: 100
)

// 4. Sign
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

// 5. Submit
let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .success(let response):
    print("Success! Hash: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("SEP-29: Destination \(accountId) requires memo")
case .failure(let error):
    print("Failed: \(error)")
}
```

For all 26+ operations (ChangeTrust, ManageSellOffer, CreateAccount, etc.):
[Operations Reference](./references/operations.md)

## 5. Soroban RPC API

RPC endpoint patterns for Soroban smart contract queries.

```swift
let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
server.enableLogging = true  // Optional: debug logging

// Health check
let healthEnum = await server.getHealth()
// Network info
let networkEnum = await server.getNetwork()
```

For all 12 RPC methods (getAccount, simulateTransaction, getEvents, etc.):
[RPC Reference](./references/rpc.md)

## 6. Smart Contracts

Contract deployment and invocation patterns using `SorobanClient`.

### Deploy Contract

```swift
let keyPair = try KeyPair(secretSeed: secretSeed)
let rpcUrl = "https://soroban-testnet.stellar.org"

// Step 1: Install WASM
let wasmHash = try await SorobanClient.install(
    installRequest: InstallRequest(
        rpcUrl: rpcUrl,
        network: Network.testnet,
        sourceAccountKeyPair: keyPair,
        wasmBytes: wasmData
    )
)

// Step 2: Deploy instance
let client = try await SorobanClient.deploy(
    deployRequest: DeployRequest(
        rpcUrl: rpcUrl,
        network: Network.testnet,
        sourceAccountKeyPair: keyPair,
        wasmHash: wasmHash,
        constructorArgs: [SCValXDR.u32(1000)], // optional — see soroban_contracts.md
        enableServerLogging: false
    )
)
print("Contract ID: \(client.contractId)")
```

### Invoke Contract Function

```swift
// Create client for existing contract
let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: "CABC...",
        network: Network.testnet,
        rpcUrl: rpcUrl
    )
)

// Invoke method (handles simulation, signing, submission)
let result = try await client.invokeMethod(
    name: "hello",
    args: [SCValXDR.symbol("world")]
)
```

For multi-auth workflows, low-level deploy/invoke, and contract authorization:
[Smart Contracts Guide](./references/soroban_contracts.md)

## 7. XDR Encoding & Decoding

XDR is Stellar's binary serialization format.

```swift
// Encode transaction to XDR
let xdrBase64 = try transaction.encodedEnvelope()

// Decode XDR to transaction
let transaction = try Transaction(envelopeXdr: xdrBase64)

// Soroban contract values
let boolVal = SCValXDR.bool(true)
let u32Val = SCValXDR.u32(42)
let symbolVal = SCValXDR.symbol("transfer")
let addressVal = SCValXDR.address(try SCAddressXDR(accountId: "GABC...")) // SCAddressXDR throws, .address() does not
```

For all XdrSCVal types and encoding/decoding utilities:
[XDR Reference](./references/xdr.md)

## 8. Error Handling & Troubleshooting

### Horizon Errors

```swift
let responseEnum = await sdk.accounts.getAccountDetails(accountId: "GINVALID...")
switch responseEnum {
case .success(let account):
    print("Found: \(account.accountId)")
case .failure(let error):
    switch error {
    case .notFound(let message, _):
        print("Account not found: \(message)")
    case .rateLimitExceeded(let message, _):
        print("Rate limited: \(message)")
    default:
        print("Other error: \(error)")
    }
}
```

### Transaction Errors

```swift
let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .success(let response):
    print("Success: \(response.transactionHash)")
case .failure(let error):
    if case .badRequest(_, let errorResponse) = error {
        if let resultCodes = errorResponse?.extras?.resultCodes {
            print("TX code: \(resultCodes.transaction ?? "unknown")")
            print("Op codes: \(resultCodes.operations ?? [])")
        }
    }
case .destinationRequiresMemo:
    print("SEP-29 memo required")
}
```

For comprehensive error catalog and solutions:
[Troubleshooting Guide](./references/troubleshooting.md)

## 9. Security Best Practices

Never hardcode secret seeds. Use iOS Keychain for storage. Always verify transaction details before signing. Validate network passphrases to prevent mainnet accidents.

[Security Best Practices](./references/security.md)

## 10. SEP Implementations

The SDK implements 17 Stellar Ecosystem Proposals (SEPs): SEP-01 (TOML), SEP-02 (Federation), SEP-05 (Key Derivation), SEP-10 (Web Auth), SEP-24 (Interactive deposit/withdrawal), and more.

[SEP Implementations Reference](./references/sep.md)

## 11. Advanced Features

Multi-signature accounts, sponsored reserves, claimable balances, liquidity pools, muxed accounts (M-addresses), fee-bump transactions, path payments.

[Advanced Features Reference](./references/advanced.md)

## Reference Documentation

- [Operations Reference](./references/operations.md) - All 26+ Stellar operations with Swift examples
- [Horizon API Reference](./references/horizon_api.md) - Complete Horizon endpoint coverage (50/50)
- [Horizon Streaming Guide](./references/horizon_streaming.md) - SSE patterns and reconnection
- [RPC Reference](./references/rpc.md) - All 12 Soroban RPC methods
- [Smart Contracts Guide](./references/soroban_contracts.md) - Contract deployment, invocation, auth
- [XDR Guide](./references/xdr.md) - XDR encoding/decoding and debugging
- [Troubleshooting Guide](./references/troubleshooting.md) - Error codes and solutions
- [Security Best Practices](./references/security.md) - Keychain storage, transaction verification
- [SEP Implementations](./references/sep.md) - All 17 SEP protocol implementations
- [Advanced Features](./references/advanced.md) - Multi-sig, sponsorship, claimable balances, liquidity pools
- [API Reference (Signatures)](./references/api_reference.md) - All public class/method signatures

**External Resources:**
- [Stellar Developer Docs](https://developers.stellar.org/)
- [SDK Repository](https://github.com/Soneso/stellar-ios-mac-sdk)
- [Soroban Docs](https://soroban.stellar.org/)

## Common Pitfalls

**Module name is lowercase:**
```swift
// WRONG: import StellarSDK
// CORRECT:
import stellarsdk
```

**Stream items must be retained:**
```swift
// WRONG: stream closes immediately
func bad() {
    let _ = sdk.payments.stream(for: .paymentsForAccount(account: "G...", cursor: nil))
}

// CORRECT: store as instance property
class Monitor {
    var streamItem: OperationsStreamItem?  // Strong reference
    func start() {
        streamItem = sdk.payments.stream(for: .paymentsForAccount(account: "G...", cursor: nil))
    }
}
```

**Amounts are Decimal, not String:**
```swift
// Operations use Decimal
let payment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0  // Decimal type
)

// Horizon responses return String balances with 7 decimal places
// e.g., "100.0000000" for 100 XLM — always 7 decimals, never "100"
let balance = accountResponse.balances[0]
guard let amountDecimal = Decimal(string: balance.balance) else { throw ... }
let payment = try PaymentOperation(..., amount: amountDecimal)
```

**Sequence number is already Int64:**
```swift
// WRONG: Int64(accountResponse.sequenceNumber)! -- compile error
// CORRECT: use directly
let account = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber  // Already Int64
)
```

**Sequence number mutation:** `Transaction(sourceAccount:)` increments the source account's sequence number internally. Reload the account before building a new transaction. Don't increment manually.
```swift
// CORRECT: reload account, Transaction increments sequence internally
let accountResponse = await sdk.accounts.getAccountDetails(accountId: accountId)
guard case .success(let account) = accountResponse else { return }
let tx = try Transaction(sourceAccount: account, operations: [op], memo: Memo.none)
// account.sequenceNumber is now N+1

// WRONG: manually incrementing — Transaction already does this
// account.incrementSequenceNumber()  // now N+1
// let tx = try Transaction(sourceAccount: account, ...)  // uses N+2 — tx_bad_seq!
```

**Network passphrase must match SDK:**
```swift
// WRONG: Mismatched network
let sdk = StellarSDK.publicNet()
try transaction.sign(keyPair: keyPair, network: Network.testnet)  // ERROR!

// CORRECT: Match SDK and signing network
let sdk = StellarSDK.publicNet()
try transaction.sign(keyPair: keyPair, network: .public)
```

**KeyPair from accountId is public-only (cannot sign):**
```swift
// WRONG: Trying to sign with public-only KeyPair
let publicKeyPair = try KeyPair(accountId: "GABC...")
try transaction.sign(keyPair: publicKeyPair, network: Network.testnet)  // ERROR!

// CORRECT: Load from secretSeed for signing
let signingKeyPair = try KeyPair(secretSeed: "SABC...")
try transaction.sign(keyPair: signingKeyPair, network: Network.testnet)
```

**Insufficient signatures return `op_bad_auth`, not `tx_bad_auth`:**
```swift
// Multi-sig auth failures appear in operation codes, not transaction code
let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .failure(let error):
    if case .badRequest(_, let errorResponse) = error {
        if let resultCodes = errorResponse?.extras?.resultCodes {
            // WRONG: checking transaction code for auth failure
            if resultCodes.transaction == "tx_bad_auth" { /* never matches */ }
            
            // CORRECT: check operation codes for op_bad_auth
            if let opCodes = resultCodes.operations, opCodes.contains("op_bad_auth") {
                print("Insufficient signatures!")
            }
        }
    }
default:
    break
}
```

**Fee calculation:**
The fee is per operation. For a transaction with N operations at `maxOperationFee: 200`, the total fee is N × 200 stroops. The minimum base fee is 100 stroops per operation.

**Soroban transactions require simulation first:**
```swift
// Build transaction, then simulate to get footprint/fees
let simRequest = SimulateTransactionRequest(transaction: tx)
let simEnum = await server.simulateTransaction(simulateTxRequest: simRequest)
guard case .success(let simResponse) = simEnum else { return }

// Apply simulation results before signing
if let transactionData = simResponse.transactionData {
    tx.setSorobanTransactionData(data: transactionData)
}
if let minResourceFee = simResponse.minResourceFee {
    tx.addResourceFee(resourceFee: minResourceFee)
}
tx.setSorobanAuth(auth: simResponse.sorobanAuth)
```

For error handling patterns and troubleshooting:
[Troubleshooting Guide](./references/troubleshooting.md)
