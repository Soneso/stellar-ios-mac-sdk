# [Stellar SDK for iOS & macOS](https://github.com/Soneso/stellar-ios-mac-sdk)

[![GitHub release](https://img.shields.io/github/v/release/Soneso/stellar-ios-mac-sdk)](https://github.com/Soneso/stellar-ios-mac-sdk/releases) [![Tests](https://github.com/Soneso/stellar-ios-mac-sdk/actions/workflows/tests.yml/badge.svg)](https://github.com/Soneso/stellar-ios-mac-sdk/actions/workflows/tests.yml) [![codecov](https://codecov.io/gh/Soneso/stellar-ios-mac-sdk/branch/master/graph/badge.svg)](https://codecov.io/gh/Soneso/stellar-ios-mac-sdk) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Soneso/stellar-ios-mac-sdk)

Build and sign Stellar transactions, query [Horizon](https://developers.stellar.org/docs/data/apis/horizon), and interact with [Soroban](https://developers.stellar.org/docs/build/smart-contracts/overview) smart contracts via RPC. Communicate with anchors and external services using built-in support for 17 SEPs.

## Installation

### Swift Package Manager

```swift
.package(name: "stellarsdk", url: "git@github.com:Soneso/stellar-ios-mac-sdk.git", from: "3.5.0"),
```

### CocoaPods

```ruby
pod 'stellar-ios-mac-sdk', '~> 3.5.0'
```

Requires iOS 13+, macOS 10.15+, Swift 5.7+.

## Quick examples

### Send a payment

Transfer XLM between accounts:

```swift
let paymentOp = PaymentOperation(sourceAccountId: nil,
                                 destinationAccountId: receiverId,
                                 asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                 amount: 100)
let transaction = try Transaction(sourceAccount: senderAccount,
                                  operations: [paymentOp],
                                  memo: Memo.none)
try transaction.sign(keyPair: senderKeyPair, network: .testnet)
let response = await sdk.transactions.submitTransaction(transaction: transaction)
```

### Trust an asset

Enable your account to receive a token (like USDC):

```swift
let usdc = ChangeTrustAsset(canonicalForm: "USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5")!
let trustOp = ChangeTrustOperation(sourceAccountId: nil,
                                   asset: usdc,
                                   limit: nil)
let transaction = try Transaction(sourceAccount: account,
                                  operations: [trustOp],
                                  memo: Memo.none)
try transaction.sign(keyPair: accountKeyPair, network: .testnet)
let response = await sdk.transactions.submitTransaction(transaction: transaction)
```

### Call a smart contract

Invoke a Soroban contract method:

```swift
let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: "CABC...",
        network: .testnet,
        rpcUrl: "https://soroban-testnet.stellar.org",
        enableServerLogging: false
    )
)
let result = try await client.invokeMethod(name: "hello", args: [SCValXDR.symbol("World")])
```

For complete walkthroughs, see the [documentation](docs/).

## Agent Skill

This repository includes an [Agent Skill](https://agentskills.io) that teaches AI coding agents how to use this SDK. See [skills/](skills/) for installation instructions.

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick start](docs/quick-start.md) | Your first transaction in 15 minutes |
| [Getting started](docs/getting-started.md) | Keys, accounts, and fundamentals |
| [SDK usage](docs/sdk-usage.md) | Transactions, operations, Horizon queries, streaming |
| [Soroban](docs/soroban.md) | Smart contract deployment and interaction |
| [Smart Accounts](docs/smart-accounts/README.md) | OpenZeppelin smart account support: passkeys, multi-signer authorization, context rules, policies |
| [SEPs](docs/sep/) | Anchor integration, authentication, KYC, etc. |

[API reference](https://soneso.github.io/stellar-ios-mac-sdk/)

## Smart Accounts (Passkey) support

The SDK supports OpenZeppelin smart accounts on Stellar — passkey/WebAuthn authentication, multi-signer authorization, context rules, and policies. See the [Smart Accounts documentation](docs/smart-accounts/README.md) and the [demo app](https://github.com/Soneso/ios-oz-smartaccount-demo).

## Compatibility

- [Horizon API compatibility matrix](compatibility/horizon/HORIZON_COMPATIBILITY_MATRIX.md)
- [RPC API compatibility matrix](compatibility/rpc/RPC_COMPATIBILITY_MATRIX.md)
- [SEP support matrices](compatibility/sep/)

## Sample

This SDK is used by the open source [LOBSTR Vault](https://vault.lobstr.co) ([source](https://github.com/Lobstrco/Vault-iOS)) and the [LOBSTR Wallet](https://lobstr.co).

## Feedback

If you're using this SDK, feedback helps improve it:

- [Report a bug](https://github.com/Soneso/stellar-ios-mac-sdk/issues/new?template=bug_report.yml)
- [Request a feature](https://github.com/Soneso/stellar-ios-mac-sdk/issues/new?template=feature_request.yml)
- [Start a discussion](https://github.com/Soneso/stellar-ios-mac-sdk/discussions)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache 2.0. See [LICENSE](LICENSE).
