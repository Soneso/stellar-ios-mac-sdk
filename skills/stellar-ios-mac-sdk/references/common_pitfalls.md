# Common Pitfalls

The mistakes that most often break builds, signatures, or submissions when using stellarsdk. Each entry shows the wrong and the correct pattern.

All examples assume `import stellarsdk`.

## Table of Contents

1. [Module name is lowercase](#module-name-is-lowercase)
2. [Stream items must be retained](#stream-items-must-be-retained)
3. [Amounts are Decimal, not String](#amounts-are-decimal-not-string)
4. [Sequence number is already Int64](#sequence-number-is-already-int64)
5. [Sequence number mutation](#sequence-number-mutation)
6. [Network passphrase must match SDK](#network-passphrase-must-match-sdk)
7. [KeyPair from accountId is public-only](#keypair-from-accountid-is-public-only-cannot-sign)
8. [tx_bad_auth vs op_bad_auth](#tx_bad_auth-vs-op_bad_auth)
9. [Fee calculation](#fee-calculation)
10. [Soroban transactions require simulation first](#soroban-transactions-require-simulation-first)

## Module name is lowercase

```swift
// WRONG: import StellarSDK
// CORRECT:
import stellarsdk
```

## Stream items must be retained

```swift
// WRONG: nothing retains the stream item, so the stream closes immediately
func bad() {
    let sdk = StellarSDK.testNet()
    let _ = sdk.payments.stream(for: .paymentsForAccount(account: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ", cursor: nil))
}

// CORRECT: store as instance property
class Monitor {
    let sdk = StellarSDK.testNet()
    var streamItem: OperationsStreamItem?  // Strong reference
    func start() {
        streamItem = sdk.payments.stream(for: .paymentsForAccount(account: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ", cursor: nil))
    }
}
```

## Amounts are Decimal, not String

```swift
import Foundation

// Operations use Decimal amounts
let payment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",  // payment destination
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0  // Decimal type
)

// Horizon responses return String balances with 7 decimal places,
// e.g. "100.0000000" for 100 XLM — always 7 decimals, never "100".
// Convert with Decimal(string:), never through Double.
let balance = "100.0000000"  // as found in accountResponse.balances[n].balance
guard let amountDecimal = Decimal(string: balance) else {
    throw StellarSDKError.invalidArgument(message: "balance is not a decimal string")
}
let paymentFromBalance = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: amountDecimal
)
```

## Sequence number is already Int64

```swift
// accountResponse: an AccountResponse from sdk.accounts.getAccountDetails
// WRONG: Int64(accountResponse.sequenceNumber)! -- compile error
// CORRECT: use directly
let account = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber  // Already Int64
)
```

## Sequence number mutation

`Transaction(sourceAccount:)` increments the source account's sequence number internally. Reload the account before building a new transaction. Don't increment manually.

```swift
// CORRECT: reload account, Transaction increments sequence internally
let sdk = StellarSDK.testNet()
let op = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",  // payment destination
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)
let accountEnum = await sdk.accounts.getAccountDetails(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
guard case .success(let account) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "account not found")
}
let tx = try Transaction(sourceAccount: account, operations: [op], memo: Memo.none)
// account.sequenceNumber is now N+1

// WRONG: manually incrementing — Transaction already does this
// account.incrementSequenceNumber()  // now N+1
// let tx = try Transaction(sourceAccount: account, ...)  // uses N+2 — tx_bad_seq!
```

## Network passphrase must match SDK

Signing with the wrong network does not throw. It produces a signature over the wrong network id, and the network rejects the envelope on submission with `tx_bad_auth`.

```swift
// A transaction built offline for the demonstration
let keyPair = try KeyPair.generateRandomKeyPair()
let op = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",  // payment destination
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)

// WRONG: a public-network transaction signed with the testnet passphrase
let wrongAccount = try Account(accountId: keyPair.accountId, sequenceNumber: 1)
let wrongTransaction = try Transaction(sourceAccount: wrongAccount, operations: [op], memo: Memo.none)
let sdk = StellarSDK.publicNet()
try wrongTransaction.sign(keyPair: keyPair, network: Network.testnet)  // rejected if submitted

// CORRECT: build a fresh transaction and match the SDK's network.
// sign(...) appends a signature, so do not reuse wrongTransaction here.
let correctAccount = try Account(accountId: keyPair.accountId, sequenceNumber: 1)
let correctTransaction = try Transaction(sourceAccount: correctAccount, operations: [op], memo: Memo.none)
try correctTransaction.sign(keyPair: keyPair, network: Network.public)
```

## KeyPair from accountId is public-only (cannot sign)

```swift
// A transaction built offline for the demonstration
let signingKeyPair = try KeyPair.generateRandomKeyPair()
let account = try Account(accountId: signingKeyPair.accountId, sequenceNumber: 1)
let op = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",  // payment destination
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)
let transaction = try Transaction(sourceAccount: account, operations: [op], memo: Memo.none)

// WRONG: Trying to sign with a public-only KeyPair
let publicKeyPair = try KeyPair(accountId: signingKeyPair.accountId)  // succeeds — public key only
do {
    try transaction.sign(keyPair: publicKeyPair, network: Network.testnet)
} catch {
    // StellarSDKError.invalidArgument: "KeyPair must contain the private key to be able to sign the transaction."
    print("Cannot sign: \(error)")
}

// CORRECT: Load from secretSeed for signing
try transaction.sign(keyPair: signingKeyPair, network: Network.testnet)
```

## tx_bad_auth vs op_bad_auth

Which code an auth failure produces depends on whose signature requirements failed. Missing signatures for the transaction's source account — the common single-source multi-sig case — fail at the envelope level: `tx_bad_auth` in `resultCodes.transaction`. An operation with its own, different source account whose thresholds are not met fails at the operation level: `op_bad_auth` in `resultCodes.operations`. Check both places.

```swift
let sdk = StellarSDK.testNet()
// transaction: signed as in the lifecycle example, but with signatures below the required thresholds
let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .failure(let error):
    if case .badRequest(_, let errorResponse) = error {
        if let resultCodes = errorResponse?.extras?.resultCodes {
            // Signatures for the transaction's source account below thresholds
            if resultCodes.transaction == "tx_bad_auth" {
                print("Transaction source account: insufficient signatures")
            }
            // An operation's own source account did not meet its thresholds
            if let opCodes = resultCodes.operations, opCodes.contains("op_bad_auth") {
                print("Operation source account: insufficient signatures")
            }
        }
    }
default:
    break
}
```

## Fee calculation

The fee is per operation. For a transaction with N operations at `maxOperationFee: 200`, the total fee is N × 200 stroops. The minimum base fee is 100 stroops per operation.

## Soroban transactions require simulation first

```swift
let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
// tx: a Transaction wrapping an InvokeHostFunctionOperation, built as in soroban_contracts.md

// Simulate to get footprint and fees
let simRequest = SimulateTransactionRequest(transaction: tx)
let simEnum = await server.simulateTransaction(simulateTxRequest: simRequest)
guard case .success(let simResponse) = simEnum else {
    throw StellarSDKError.invalidArgument(message: "simulation failed")
}

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
[Troubleshooting Guide](./troubleshooting.md)
