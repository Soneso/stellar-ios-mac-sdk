---
name: stellar-ios-mac-sdk
description: Guides Stellar blockchain development in Swift using stellar-ios-mac-sdk. Use when generating Swift code for transaction building, signing, Horizon API queries, Soroban RPC, smart contract deployment and invocation, smart accounts (OpenZeppelin) with passkey / WebAuthn authentication, XDR encoding/decoding, and SEP protocol integration. Network APIs use Swift async/await; Horizon streaming is callback-based. Triggers when the developer mentions Stellar, blockchain, passkey, smart wallet, or biometric signing on iOS or macOS. Full Swift 6 strict concurrency support (all types Sendable).
license: Apache 2.0
compatibility: Requires Xcode 16+ (Swift 6 toolchain), iOS 15+, macOS 12+. Zero external dependencies.
metadata:
  version: "1.5.0"
  sdk_version: "3.10.0"
  last_updated: "2026-08-25"
---

# Stellar SDK for iOS & Mac

## Overview

The Stellar iOS/Mac SDK (`stellarsdk`) is a native Swift library for building Stellar applications on iOS 15+ and macOS 12+. It covers the Horizon API, the Soroban RPC API, and the SEP protocol suite. Network APIs use Swift async/await; the Horizon streaming endpoints are callback-based (`onReceive` closures on retained stream items); builders, encoders, and other utilities are synchronous. The SDK compiles with Swift 6 strict concurrency and has zero external dependencies.

**Module name:** `stellarsdk` (always lowercase in import statements)

## Installation

### Swift Package Manager

```swift
.package(name: "stellarsdk", url: "git@github.com:Soneso/stellar-ios-mac-sdk.git", from: "3.10.0")
```

### CocoaPods

```ruby
pod 'stellar-ios-mac-sdk', '~> 3.10.0'
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
```

```swift
// From existing seed (seed: the "S..." secret seed string, loaded from secure storage)
let keyPair = try KeyPair(secretSeed: seed)
let publicOnly = try KeyPair(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")  // public-only, cannot sign
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
let issuerKeyPair = try KeyPair(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")  // asset issuer
let usdc = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
                 code: "USDC",
                 issuer: issuerKeyPair)!

// From canonical form "CODE:ISSUER" — failable, returns nil for a malformed string
if let asset = Asset(canonicalForm: "USDC:GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ") {
    print(asset.toCanonicalForm())
}
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
let accountEnum = await sdk.accounts.getAccountDetails(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")

// Transactions for account
let txEnum = await sdk.transactions.getTransactions(
    forAccount: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
    from: nil,
    order: .descending,
    limit: 10
)

// Pagination: use cursor from last record's pagingToken
switch txEnum {
case .success(let page):
    if let lastRecord = page.records.last {
        let nextPage = await sdk.transactions.getTransactions(
            forAccount: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
            from: lastRecord.pagingToken,
            order: .descending,
            limit: 10
        )
    }
case .failure(let error):
    print("Error: \(error)")
}
```

For the full Horizon endpoint coverage, advanced queries, and memo inspection:
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
// senderKeyPair: the sender's signing KeyPair, built from its secret seed
// destinationAccountId: an existing account on the selected network

// 1. Load sender account (AccountResponse conforms to TransactionAccount)
let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Could not load the sender account")
}

// 2. Create payment operation
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destinationAccountId,
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

For all operations (ChangeTrust, ManageSellOffer, CreateAccount, etc.):
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

For all RPC methods (getAccount, simulateTransaction, getEvents, etc.):
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
        wasmBytes: wasmData,
        enableServerLogging: false
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
// keyPair, rpcUrl: as in the deploy example above
// Create client for existing contract
let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: "CB3FU6M3TOAGRBLN5WDLXL6A7VR5SSRGULMXQQOABNMPS25YRJ4CN5VV",  // deployed contract
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

For multi-auth workflows, low-level deploy/invoke, contract authorization, and protocol-27 (CAP-71) credential arms and delegated authorization:
[Smart Contracts Guide](./references/soroban_contracts.md)

## 7. Smart Accounts (OpenZeppelin)

Passkey-authenticated Soroban smart accounts: biometric (Face ID / Touch ID) auth, multiple signers (passkey / delegated / Ed25519), context rules, policies, and optional fee sponsoring via a relayer. Entry point: `OZSmartAccountKit.create(config:)`.

- [Smart Accounts Guide](./references/smart_accounts.md) — kit config, wallet create/connect, signer types, transactions, credentials, events, `submit` / `fundWallet`, the `externalSigners` manager, indexer
- [Context Rules & Policies](./references/smart_accounts_policies.md) — signer management, context rules, policies, multi-signer operations, common scenarios (recovery, rotation, `__check_auth` debugging), contract error codes
- [WebAuthn Platform Setup](./references/smart_accounts_webauthn.md) — iOS and macOS WebAuthn providers and storage adapters, Associated Domains / AASA, cross-device passkeys

## 8. XDR Encoding & Decoding

XDR is Stellar's binary serialization format.

```swift
// transaction: a built Transaction (see section 4)
let xdrBase64 = try transaction.encodedEnvelope()

// Decode XDR back into a transaction
let decoded = try Transaction(envelopeXdr: xdrBase64)
```

```swift
// Soroban contract values
let boolVal = SCValXDR.bool(true)
let u32Val = SCValXDR.u32(42)
let symbolVal = SCValXDR.symbol("transfer")
let addressVal = SCValXDR.address(try SCAddressXDR(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")) // SCAddressXDR throws, .address() does not
```

For all XdrSCVal types and encoding/decoding utilities:
[XDR Reference](./references/xdr.md)

## 9. Error Handling & Troubleshooting

### Horizon Errors

```swift
let sdk = StellarSDK.testNet()

// Checksum-valid account id, not funded on any network — Horizon answers 404
let responseEnum = await sdk.accounts.getAccountDetails(accountId: "GB6HKIDW4WVQPPFPTXTVKZMAJIL33DUZGWBVLQV35TTYUNIUL7AL2UTG")
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

For the full error catalog and solutions:
[Troubleshooting Guide](./references/troubleshooting.md)

## 10. Security Best Practices

Never hardcode secret seeds. Use iOS Keychain for storage. Always verify transaction details before signing. Validate network passphrases to prevent mainnet accidents.

[Security Best Practices](./references/security.md)

## 11. SEP Implementations

The SDK implements the Stellar Ecosystem Proposals for discovery, authentication, KYC, deposits and withdrawals, quotes, and messaging: SEP-01 (TOML), SEP-02 (Federation), SEP-05 (Key Derivation), SEP-10 (Web Auth), SEP-24 (Interactive deposit/withdrawal), and more.

[SEP Implementations Reference](./references/sep.md)

## 12. Advanced Features

Multi-signature accounts, sponsored reserves, claimable balances, liquidity pools, muxed accounts (M-addresses), fee-bump transactions, path payments.

[Advanced Features Reference](./references/advanced.md)

## Reference Documentation

- [Operations Reference](./references/operations.md) - All Stellar operations with Swift examples
- [Horizon API Reference](./references/horizon_api.md) - Complete Horizon endpoint coverage
- [Horizon Streaming Guide](./references/horizon_streaming.md) - SSE patterns and reconnection
- [RPC Reference](./references/rpc.md) - All Soroban RPC methods
- [Smart Contracts Guide](./references/soroban_contracts.md) - Contract deployment, invocation, auth
- [Smart Accounts Guide](./references/smart_accounts.md) - OZ kit core: config, wallet create/connect, signer types, transactions, credentials, external signers, events, indexer
- [Smart Accounts - Policies](./references/smart_accounts_policies.md) - Signer management, context rules, policies, multi-signer operations
- [Smart Accounts - WebAuthn](./references/smart_accounts_webauthn.md) - WebAuthn providers and storage adapters for iOS and macOS
- [XDR Guide](./references/xdr.md) - XDR encoding/decoding and debugging
- [Troubleshooting Guide](./references/troubleshooting.md) - Error codes and solutions
- [Security Best Practices](./references/security.md) - Keychain storage, transaction verification
- [SEP Implementations](./references/sep.md) - The SEP protocol implementations
- [Advanced Features](./references/advanced.md) - Multi-sig, sponsorship, claimable balances, liquidity pools
- [Common Pitfalls Reference](./references/common_pitfalls.md) - Frequent mistakes with WRONG/CORRECT examples
- [API Reference (Signatures)](./references/api_reference.md) - All public class/method signatures

**External Resources:**
- [Stellar Developer Docs](https://developers.stellar.org/)
- [SDK Repository](https://github.com/Soneso/stellar-ios-mac-sdk)
- [Soroban Docs](https://soroban.stellar.org/)

## Common Pitfalls

The mistakes that most often break builds or transactions, each with WRONG/CORRECT Swift examples: lowercase `import stellarsdk`; stream items must be retained; operation amounts are `Decimal` while Horizon returns `String` balances; sequence numbers are already `Int64` and `Transaction(sourceAccount:)` increments them internally; the signing network must match the SDK instance; a `KeyPair` built from an accountId cannot sign; missing signatures for the transaction's source account surface as `tx_bad_auth` in the transaction code, while an operation whose own source account fails its thresholds surfaces as `op_bad_auth` in the operation codes; fees are per operation; Soroban transactions need simulation before signing.

[Common Pitfalls Reference](./references/common_pitfalls.md)

For error handling patterns and troubleshooting:
[Troubleshooting Guide](./references/troubleshooting.md)
