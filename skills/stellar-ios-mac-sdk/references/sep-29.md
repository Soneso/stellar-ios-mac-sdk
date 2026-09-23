# SEP-29: Account Memo Requirements

**Purpose:** Prevent lost funds by allowing accounts to require incoming payments include a memo.
**Prerequisites:** None
**SDK Integration:** Automatic check built into every submit method of `sdk.transactions`, including the fee bump variants
**Spec:** [SEP-0029](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)

All examples assume `import stellarsdk`.

Exchanges and custodial services use SEP-29 to identify which customer a deposit belongs to. Without a memo, incoming payments cannot be credited to the right user. The iOS SDK performs the SEP-29 check automatically inside every submit method of `sdk.transactions` and returns a dedicated enum case when a destination requires a memo.

- [How the Check Works](#how-the-check-works)
- [Quick Start — Automatic Check via submitTransaction()](#quick-start--automatic-check-via-submittransaction)
- [Response Enums](#response-enums)
- [Method Signatures](#method-signatures)
- [Setting the Memo-Required Flag on Your Account](#setting-the-memo-required-flag-on-your-account)
- [Transactions with Multiple Destinations](#transactions-with-multiple-destinations)
- [AccountMergeOperation](#accountmergeoperation)
- [Muxed Account Destinations](#muxed-account-destinations)
- [Skipping the Check Explicitly](#skipping-the-check-explicitly)
- [CheckMemoRequiredResponseEnum](#checkmemorequiredresponseenum)
- [Common Pitfalls](#common-pitfalls)
- [Related SEPs](#related-seps)

## How the Check Works

The check is integrated into `submitTransaction()`, `submitAsyncTransaction()`, `submitFeeBumpTransaction()`, `submitFeeBumpAsyncTransaction()`, `postTransaction()` and `postTransactionAsync()`. You do not call `checkMemoRequired()` directly — the SDK does it for you. For a fee bump transaction the check runs against the inner transaction of the envelope that is submitted, which carries the memo and the operations.

**When a submit method is called without `skipMemoRequiredCheck: true`:**

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
// senderSecretSeed: String for your funded sender account, loaded from secure storage
// destAccountId: String for an existing testnet destination account
let senderKeyPair = try KeyPair(secretSeed: senderSecretSeed)

// Load sender account
let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Could not load the sender account")
}

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
    // Transaction init incremented the first Account's sequenceNumber, so build
    // the retry from a fresh Account with accountResponse.sequenceNumber.
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

    // The memo short-circuits the check, so the retry needs no account lookup.
    let retryEnum = await sdk.transactions.submitTransaction(transaction: transaction)
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

// Fee bump submission; the SEP-29 check runs against the inner transaction
open func submitFeeBumpTransaction(
    transaction: FeeBumpTransaction,
    skipMemoRequiredCheck: Bool = false
) async -> TransactionPostResponseEnum

// Async fee bump submission; the SEP-29 check runs against the inner transaction
open func submitFeeBumpAsyncTransaction(
    transaction: FeeBumpTransaction,
    skipMemoRequiredCheck: Bool = false
) async -> TransactionPostAsyncResponseEnum
```

The `skipMemoRequiredCheck` parameter defaults to `false` — the check runs automatically. A raw envelope passed to `postTransaction()` or `postTransactionAsync()` may be a fee bump envelope; it is checked against its inner transaction as well.

## Setting the Memo-Required Flag on Your Account

Exchanges and custodial services use `ManageDataOperation` to set the `config.memo_required` flag. The data value must be the UTF-8 string `"1"` encoded as `Data`.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
// exchangeSecretSeed: String for the exchange account, loaded from secure storage
let exchangeKeyPair = try KeyPair(secretSeed: exchangeSecretSeed)

let accountEnum = await sdk.accounts.getAccountDetails(accountId: exchangeKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Could not load the exchange account")
}

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
// senderSecretSeed: String for your funded sender account, loaded from secure storage
let senderKeyPair = try KeyPair(secretSeed: senderSecretSeed)

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Could not load the sender account")
}

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// dest1 and dest2: String values for existing testnet destination accounts

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
    guard case .success(let reloaded) = reloadEnum else {
        throw StellarSDKError.invalidArgument(message: "Could not reload the sender account")
    }
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
    let _ = await sdk.transactions.submitTransaction(transaction: transaction)
case .failure(let error):
    print("Error: \(error)")
}
```

## AccountMergeOperation

`AccountMergeOperation` is also checked because merging sends the full account balance to the destination:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
// sourceSecretSeed: String for your funded source account, loaded from secure storage
// destAccountId: String for an existing testnet destination account
let sourceKeyPair = try KeyPair(secretSeed: sourceSecretSeed)

let accountEnum = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Could not load the source account")
}

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
    let _ = await sdk.transactions.submitTransaction(transaction: transaction)
case .failure(let error):
    print("Error: \(error)")
}
```

## Muxed Account Destinations

Muxed accounts (M-addresses) are automatically skipped by the check. The numeric ID embedded in the M-address already identifies the sub-account, so no memo is needed:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
// senderSecretSeed: String for your funded sender account, loaded from secure storage
let senderKeyPair = try KeyPair(secretSeed: senderSecretSeed)

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Could not load the sender account")
}

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

**Wrong: building both transactions from the same `Account` object:**

```swift
// WRONG: Transaction init increments Account.sequenceNumber; signing does not change it.
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

**Wrong: handling `.destinationRequiresMemo` from a fee bump by rebuilding only the fee bump:**

```swift
// WRONG: the memo lives on the inner transaction; a FeeBumpTransaction has no memo field.
let feeBumpEnum = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBumpTx)
if case .destinationRequiresMemo = feeBumpEnum {
    let retry = try FeeBumpTransaction(sourceAccount: feeSource, fee: 300, innerTransaction: innerTx)
    // retry wraps the same memo-less inner transaction and returns .destinationRequiresMemo again
}

// CORRECT: rebuild the inner transaction with a memo, sign it, then wrap it again.
if case .destinationRequiresMemo = feeBumpEnum {
    let innerAccount = try Account(accountId: accountResponse.accountId, sequenceNumber: accountResponse.sequenceNumber)
    let innerWithMemo = try Transaction(sourceAccount: innerAccount, operations: [paymentOp], memo: Memo.text("customer 42"), maxOperationFee: 100)
    try innerWithMemo.sign(keyPair: innerKeyPair, network: Network.testnet)
    let feeSource = try MuxedAccount(accountId: feeSourceKeyPair.accountId, sequenceNumber: 0)
    let feeBumpWithMemo = try FeeBumpTransaction(sourceAccount: feeSource, fee: 300, innerTransaction: innerWithMemo)
    try feeBumpWithMemo.sign(keyPair: feeSourceKeyPair, network: Network.testnet)
    let retryEnum = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBumpWithMemo)
}
```

## Related SEPs

- **[SEP-10](sep.md)** — Web Authentication (often required by exchanges that use memos for user identification)
- **[SEP-24](sep.md)** — Interactive deposit/withdrawal (anchors assign per-user deposit memos)
