# SEP-29: Account Memo Requirements

**Purpose:** Prevent lost funds by allowing accounts to require incoming payments include a memo.
**Prerequisites:** None
**SDK Integration:** Automatic check built into `submitTransaction()` and `postTransaction()`
**Spec:** [SEP-0029](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)

Exchanges and custodial services use SEP-29 to identify which customer a deposit belongs to. Without a memo, incoming payments cannot be credited to the right user. The iOS SDK performs the SEP-29 check automatically inside `submitTransaction()` and returns a dedicated enum case when a destination requires a memo.

## How the Check Works

The check is integrated into `submitTransaction()` and `postTransaction()`. You do not call `checkMemoRequired()` directly — the SDK does it for you.

**When `submitTransaction()` is called without `skipMemoRequiredCheck: true`:**

1. If the transaction already has a memo (any type except `.none`) — skip the check, submit directly.
2. Collect all destination account IDs from `PaymentOperation`, `PathPaymentOperation`, and `AccountMergeOperation`. Skip any destination whose address starts with "M" (muxed accounts).
3. If no qualifying destinations — submit directly.
4. For each destination, call Horizon `GET /accounts/{destination}` and check `data["config.memo_required"] == "MQ=="` (base64 of "1").
   - If the account is not found (404), it is skipped — no memo required for non-existent accounts.
   - If the account has the flag set — return `.destinationRequiresMemo(destinationAccountId:)` immediately, without submitting.
5. If no destination has the flag set — submit the transaction.

**Operation types checked:** `PaymentOperation`, `PathPaymentOperation`, `AccountMergeOperation`

**Skipped automatically:** Muxed account destinations (M-addresses), transactions with any memo, non-existent destination accounts (404)

## Quick Start — Automatic Check via submitTransaction()

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SABC...")
let destAccountId = "GDEST..."

// Load sender account
let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destAccountId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0
)

// Build WITHOUT memo first
var transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .success(let response):
    print("Success! Hash: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    // Destination requires a memo — rebuild the transaction with one.
    // Reload the account: Account mutates sequenceNumber in memory after sign,
    // so reuse accountResponse.sequenceNumber directly for the rebuild.
    print("SEP-29: \(accountId) requires a memo — rebuilding with memo")

    let sourceAccount2 = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )
    transaction = try Transaction(
        sourceAccount: sourceAccount2,
        operations: [paymentOp],
        memo: Memo.text("user-12345"),
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

    let retryEnum = await sdk.transactions.submitTransaction(
        transaction: transaction,
        skipMemoRequiredCheck: true  // memo already added, skip recheck
    )
    if case .success(let response) = retryEnum {
        print("Success with memo: \(response.transactionHash)")
    }
case .failure(let error):
    print("Failed: \(error)")
}
```

## Response Enums

### TransactionPostResponseEnum (synchronous)

```swift
public enum TransactionPostResponseEnum {
    case success(details: SubmitTransactionResponse)         // TransactionResponse
    case destinationRequiresMemo(destinationAccountId: String)
    case failure(error: HorizonRequestError)
}
```

### TransactionPostAsyncResponseEnum (async submission)

```swift
public enum TransactionPostAsyncResponseEnum {
    case success(details: SubmitTransactionAsyncResponse)    // txStatus + txHash
    case destinationRequiresMemo(destinationAccountId: String)
    case failure(error: HorizonRequestError)
}
```

`SubmitTransactionResponse` is a typealias for `TransactionResponse`. Access the hash as `response.transactionHash`.

`SubmitTransactionAsyncResponse` has `txStatus` (String: "PENDING", "ERROR", "DUPLICATE", "TRY_AGAIN_LATER") and `txHash` (String).

## Method Signatures

```swift
// On TransactionsService (sdk.transactions):

// Synchronous submission with SEP-29 check
open func submitTransaction(
    transaction: Transaction,
    skipMemoRequiredCheck: Bool = false
) async -> TransactionPostResponseEnum

// Async submission with SEP-29 check
open func submitAsyncTransaction(
    transaction: Transaction,
    skipMemoRequiredCheck: Bool = false
) async -> TransactionPostAsyncResponseEnum

// Submit raw XDR envelope with SEP-29 check
open func postTransaction(
    transactionEnvelope: String,
    skipMemoRequiredCheck: Bool = false
) async -> TransactionPostResponseEnum

// Submit raw XDR envelope asynchronously with SEP-29 check
open func postTransactionAsync(
    transactionEnvelope: String,
    skipMemoRequiredCheck: Bool = false
) async -> TransactionPostAsyncResponseEnum
```

The `skipMemoRequiredCheck` parameter defaults to `false` — the check runs automatically.

## Setting the Memo-Required Flag on Your Account

Exchanges and custodial services use `ManageDataOperation` to set the `config.memo_required` flag. The data value must be the UTF-8 string `"1"` encoded as `Data`.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let exchangeKeyPair = try KeyPair(secretSeed: "SEXCHANGE...")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: exchangeKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Set the flag: key = "config.memo_required", value = Data("1")
let setFlagOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "config.memo_required",
    data: "1".data(using: .utf8)  // "MQ==" when base64-encoded
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [setFlagOp],
    memo: Memo.none,
    maxOperationFee: 100
)
try transaction.sign(keyPair: exchangeKeyPair, network: Network.testnet)

let submitEnum = await sdk.transactions.submitTransaction(
    transaction: transaction,
    skipMemoRequiredCheck: true  // flag-setting tx has no payment destination
)
if case .success(let response) = submitEnum {
    print("Flag set: \(response.transactionHash)")
}
```

To remove the requirement, pass `nil` as the `data` parameter — this deletes the data entry:

```swift
let removeFlagOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "config.memo_required",
    data: nil  // nil = delete the entry
)
```

## Transactions with Multiple Destinations

When a transaction has multiple payment operations, the check examines each destination in order and returns the first one that requires a memo. A single memo satisfies the requirement for all destinations.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SABC...")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let dest1 = "GDEST1..."
let dest2 = "GDEST2..."

let op1 = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: dest1,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0
)
let op2 = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: dest2,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 50.0
)

var transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [op1, op2],
    memo: Memo.none,
    maxOperationFee: 100
)
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .success(let response):
    print("Success: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Account \(accountId) requires a memo — rebuild with memo")
    // Rebuild with memo (reload account to reset sequence)
    let reloadEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let reloaded) = reloadEnum else { return }
    let sourceAccount2 = try Account(
        accountId: reloaded.accountId,
        sequenceNumber: reloaded.sequenceNumber
    )
    transaction = try Transaction(
        sourceAccount: sourceAccount2,
        operations: [op1, op2],
        memo: Memo.text("batch-ref-001"),
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)
    let _ = await sdk.transactions.submitTransaction(
        transaction: transaction,
        skipMemoRequiredCheck: true
    )
case .failure(let error):
    print("Error: \(error)")
}
```

## AccountMergeOperation

`AccountMergeOperation` is also checked because merging sends the full account balance to the destination:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let sourceKeyPair = try KeyPair(secretSeed: "SABC...")
let destAccountId = "GDEST..."

let accountEnum = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let mergeOp = try AccountMergeOperation(
    destinationAccountId: destAccountId,
    sourceAccountId: nil
)

var transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [mergeOp],
    memo: Memo.none,
    maxOperationFee: 100
)
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitEnum {
case .success(let response):
    print("Merged: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires memo before merge")
    let sourceAccount2 = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )
    transaction = try Transaction(
        sourceAccount: sourceAccount2,
        operations: [mergeOp],
        memo: Memo.text("closing"),
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)
    let _ = await sdk.transactions.submitTransaction(
        transaction: transaction,
        skipMemoRequiredCheck: true
    )
case .failure(let error):
    print("Error: \(error)")
}
```

## Muxed Account Destinations

Muxed accounts (M-addresses) are automatically skipped by the check. The numeric ID embedded in the M-address already identifies the sub-account, so no memo is needed:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SABC...")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// M-address destinations are skipped — no Horizon lookup, no memo required
let muxedDest = try MuxedAccount(
    accountId: "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK",
    id: 1234  // user ID encoded in the M-address
)

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: muxedDest.accountId,  // M-address starts with "M", not "G"
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

// submitTransaction skips the SEP-29 check for M-address destinations automatically
let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
// .destinationRequiresMemo will never fire for muxed destinations
```

## Skipping the Check Explicitly

Pass `skipMemoRequiredCheck: true` to bypass the check entirely. Use this when:
- You have already verified memo requirements yourself
- You are re-submitting after adding a memo (avoids a redundant network round-trip)
- The transaction has no payment-type operations

```swift
// Skip the check — submit immediately without Horizon account lookups
let submitEnum = await sdk.transactions.submitTransaction(
    transaction: transaction,
    skipMemoRequiredCheck: true
)
```

## CheckMemoRequiredResponseEnum

The internal `checkMemoRequired(transaction:)` method returns this enum (used internally by `postTransaction`). You do not call this directly, but understanding it helps with debugging:

```swift
public enum CheckMemoRequiredResponseEnum {
    case noMemoRequired
    case memoRequired(destination: String)
    case failure(error: HorizonRequestError)
}
```

## Common Pitfalls

**Wrong: building both transactions from the same `Account` object after signing:**

```swift
// WRONG: Account.sequenceNumber is mutated by Transaction init and sign.
// Reusing the same sourceAccount for the rebuild gives a stale sequence number.
let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)
var tx1 = try Transaction(sourceAccount: sourceAccount, operations: [op], memo: Memo.none, maxOperationFee: 100)
try tx1.sign(keyPair: keyPair, network: Network.testnet)
// ... destinationRequiresMemo fires ...
var tx2 = try Transaction(sourceAccount: sourceAccount, operations: [op], memo: Memo.text("x"), maxOperationFee: 100)
// tx2 has wrong sequence number → tx_bad_seq on submit

// CORRECT: create a fresh Account object for the rebuild using the original sequenceNumber
let sourceAccount2 = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber  // original value, not mutated
)
var tx2 = try Transaction(sourceAccount: sourceAccount2, operations: [op], memo: Memo.text("x"), maxOperationFee: 100)
```

**Wrong: expecting `.destinationRequiresMemo` to fire when a memo is already set:**

```swift
// WRONG: the check is skipped entirely when any memo is present
let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.text("hello"),  // any non-none memo skips the SEP-29 check
    maxOperationFee: 100
)
// submitTransaction will NEVER return .destinationRequiresMemo here
// The check only runs when memo is Memo.none

// CORRECT: build without a memo first, then handle .destinationRequiresMemo
let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)
```

**Wrong: using the wrong value when setting the memo-required flag:**

```swift
// WRONG: these will NOT trigger the check — value stored is not "MQ==" when base64-encoded
ManageDataOperation(sourceAccountId: nil, name: "config.memo_required", data: "true".data(using: .utf8))
ManageDataOperation(sourceAccountId: nil, name: "config.memo_required", data: "1 ".data(using: .utf8))  // trailing space

// CORRECT: value must be exactly the UTF-8 string "1"
ManageDataOperation(sourceAccountId: nil, name: "config.memo_required", data: "1".data(using: .utf8))
// The SDK checks: accountDetails.data["config.memo_required"] == "MQ==" (base64 of "1")
```

**Wrong: calling `submitFeeBumpTransaction` expects SEP-29 to check the inner transaction:**

```swift
// WRONG: submitFeeBumpTransaction does NOT run the SEP-29 check
// It calls postTransactionCore directly, bypassing checkMemoRequired entirely
let feeBumpEnum = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBumpTx)
// .destinationRequiresMemo is never returned from submitFeeBumpTransaction

// CORRECT: check and build the inner transaction first, then wrap it
var innerTx = try Transaction(...)
try innerTx.sign(keyPair: innerKeyPair, network: Network.testnet)

// Submit the inner transaction to trigger the SEP-29 check
let innerCheck = await sdk.transactions.submitTransaction(transaction: innerTx)
if case .destinationRequiresMemo(let accountId) = innerCheck {
    // Rebuild innerTx with memo, then proceed to fee-bump
}

// Alternatively, check via postTransaction before building the fee-bump
let xdr = try innerTx.encodedEnvelope()
let checkEnum = await sdk.transactions.postTransaction(transactionEnvelope: xdr)
```

## Related SEPs

- **[SEP-10](sep.md)** — Web Authentication (often required by exchanges that use memos for user identification)
- **[SEP-24](sep.md)** — Interactive deposit/withdrawal (anchors assign per-user deposit memos)
