# SEP-29: Account Memo Requirements

SEP-29 prevents lost funds by allowing accounts to require incoming payments include a memo. Exchanges and custodians use this to identify which customer a payment belongs to. Without a memo, deposits cannot be credited to the right user.

**Use SEP-29 when:**
- Sending payments to exchanges or custodial services
- Building a payment flow that needs to validate destinations before submission
- Running an exchange and requiring memos on incoming deposits

**Spec:** [SEP-0029](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)

## Quick Example

The iOS/macOS SDK checks memo requirements automatically inside `submitTransaction()`. When a destination requires a memo and the transaction lacks one, the SDK returns `.destinationRequiresMemo` instead of submitting. You can then rebuild the transaction with a memo attached:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let destinationId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT"

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destinationId,
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
    // Destination requires a memo -- rebuild the transaction with one.
    print("SEP-29: \(accountId) requires a memo -- rebuilding with memo")

    let sourceAccount2 = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )
    transaction = try Transaction(
        sourceAccount: sourceAccount2,
        operations: [paymentOp],
        memo: Memo.text("user-123"),
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

    let retryEnum = await sdk.transactions.submitTransaction(
        transaction: transaction,
        skipMemoRequiredCheck: true // memo already added, skip recheck
    )
    if case .success(let response) = retryEnum {
        print("Success with memo: \(response.transactionHash)")
    }
case .failure(let error):
    print("Failed: \(error)")
}
```

## How It Works

Accounts signal memo requirement by setting a data entry with key `config.memo_required` and value `1` (following the [SEP-18](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0018.md) namespace convention).

The iOS/macOS SDK has a built-in check integrated into `submitTransaction()` and `postTransaction()`. You do not call a separate method -- the SDK does it automatically.

**When `submitTransaction()` is called without `skipMemoRequiredCheck: true`:**

1. If the transaction already has a memo (any type except `.none`) -- skip the check, submit directly.
2. Collect all destination account IDs from `PaymentOperation`, `PathPaymentOperation`, and `AccountMergeOperation`. Skip any destination whose address starts with "M" (muxed accounts).
3. If no qualifying destinations -- submit directly.
4. For each destination, call Horizon `GET /accounts/{destination}` and check `data["config.memo_required"] == "MQ=="` (base64 of "1").
   - If the account is not found (404), it is skipped -- no memo required for non-existent accounts.
   - If the account has the flag set -- return `.destinationRequiresMemo(destinationAccountId:)` immediately, without submitting.
5. If no destination has the flag set -- submit the transaction.

**Checked operation types:** `PaymentOperation`, `PathPaymentOperation`, `AccountMergeOperation`

**Skipped automatically:** Muxed account destinations (M-addresses), transactions with any memo, non-existent destination accounts (404)

## Detailed Usage

### Setting Memo Requirement on Your Account

Exchanges and custodial services should set the `config.memo_required` data entry to ensure senders include a memo. Use a `ManageDataOperation` to add the entry:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let exchangeKeyPair = try KeyPair(secretSeed: "SBMSVD4KKELKGZXHBUQTIROWUAPQASDX7KEJITARP4VMZ6KLUHOGPTYW")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: exchangeKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Set memo_required flag
let setMemoRequired = ManageDataOperation(
    sourceAccountId: nil,
    name: "config.memo_required",
    data: "1".data(using: .utf8)
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [setMemoRequired],
    memo: Memo.none,
    maxOperationFee: 100
)

try transaction.sign(keyPair: exchangeKeyPair, network: Network.testnet)

let submitEnum = await sdk.transactions.submitTransaction(
    transaction: transaction,
    skipMemoRequiredCheck: true
)
if case .success(let response) = submitEnum {
    print("Flag set: \(response.transactionHash)")
}
```

To remove the requirement later, pass `nil` as the value. This deletes the data entry entirely:

```swift
import stellarsdk

let removeMemoRequired = ManageDataOperation(
    sourceAccountId: nil,
    name: "config.memo_required",
    data: nil // nil = delete the entry
)
```

### Checking Multiple Destinations

When a transaction contains multiple payment operations, the check examines each destination in order and returns the first one that requires a memo. A single memo satisfies the requirement for all destinations:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Batch payment to multiple recipients
let dest1 = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT"
let dest2 = "GCKUD4BHIYSBER7DI6TPMYQ4KNDEUKVMN44VKSUQGEFXWLNTHIIQE7FB"

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
    print("Account \(accountId) requires a memo -- rebuild with memo")
case .failure(let error):
    print("Error: \(error)")
}
```

### Account Merge Operations

The memo check also applies to `AccountMergeOperation`, since merging sends the account balance to the destination. Validate before merging an account:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let sourceKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let destinationId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT"

let accountEnum = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let mergeOp = try AccountMergeOperation(
    destinationAccountId: destinationId,
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
    // Rebuild with memo before merging
    let sourceAccount2 = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )
    transaction = try Transaction(
        sourceAccount: sourceAccount2,
        operations: [mergeOp],
        memo: Memo.text("closing-account"),
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

### Multiplexed Accounts (M-addresses)

Per the SEP-29 specification, multiplexed accounts are excluded from memo requirement checks. Muxed accounts (M-addresses) already encode user identification in the address itself, making a separate memo unnecessary:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Create a muxed destination with user ID embedded
let baseAccountId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT"
let muxedDestination = try MuxedAccount(accountId: baseAccountId, id: 12345)

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: muxedDestination.accountId, // M-address
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)

// Muxed accounts encode user ID in the address, so no memo check needed
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

// submitTransaction skips the SEP-29 check for M-address destinations automatically
let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
```

## Integration with Payment Flows

Use memo requirement checking as part of your payment validation flow. The SDK's automatic check via `submitTransaction()` handles validation transparently:

```swift
import stellarsdk

/// Sends a payment, handling memo requirements automatically via the SDK.
/// Returns a dictionary with "success", "error", "message", or "hash".
func sendPayment(
    sdk: StellarSDK,
    senderKeyPair: KeyPair,
    destinationId: String,
    amount: Decimal,
    memo: String? = nil
) async -> [String: Any] {

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        return [
            "success": false,
            "error": "account_not_found",
            "message": "Sender account does not exist",
        ]
    }

    let sourceAccount: Account
    do {
        sourceAccount = try Account(
            accountId: accountResponse.accountId,
            sequenceNumber: accountResponse.sequenceNumber
        )
    } catch {
        return ["success": false, "error": "account_init_failed", "message": "\(error)"]
    }

    let paymentOp: PaymentOperation
    do {
        paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destinationId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: amount
        )
    } catch {
        return ["success": false, "error": "operation_failed", "message": "\(error)"]
    }

    let memoValue: Memo = (memo != nil) ? Memo.text(memo!) : Memo.none

    do {
        var transaction = try Transaction(
            sourceAccount: sourceAccount,
            operations: [paymentOp],
            memo: memoValue,
            maxOperationFee: 100
        )
        try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

        let submitEnum = await sdk.transactions.submitTransaction(transaction: transaction)
        switch submitEnum {
        case .success(let response):
            return ["success": true, "hash": response.transactionHash]
        case .destinationRequiresMemo(let accountId):
            return [
                "success": false,
                "error": "memo_required",
                "account": accountId,
            ]
        case .failure(let error):
            return ["success": false, "error": "submit_failed", "message": "\(error)"]
        }
    } catch {
        return ["success": false, "error": "transaction_failed", "message": "\(error)"]
    }
}
```

## Error Handling

The SDK's automatic check queries Horizon for each destination account's data. Common failure modes include the destination account not existing yet or Horizon being unavailable. In both cases the SDK handles it gracefully:

- Non-existent accounts (404) are skipped -- no memo required
- Horizon errors result in `.failure(error:)` being returned

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let senderKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let destinationId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT"

let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destinationId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0
)

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
    print("Success: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires a memo.")
case .failure(let error):
    // Destination account might not exist yet, or Horizon is unavailable
    print("Could not complete payment: \(error)")
}
```

**Important notes:**
- Fee bump transactions submitted via `submitFeeBumpTransaction` do NOT run the SEP-29 check. Check the inner transaction first before wrapping it.
- The check only validates memo *presence*, not memo *type* (SEP-29 intentionally omits type validation).
- Pass `skipMemoRequiredCheck: true` to bypass the check when you have already verified memo requirements yourself.

## Related SEPs

- **[SEP-10](sep-10.md)** -- Web authentication (often used by exchanges that require memos)
- **[SEP-24](sep-24.md)** -- Interactive deposit/withdrawal (anchors provide deposit memos)

---

[Back to SEP Overview](README.md)
