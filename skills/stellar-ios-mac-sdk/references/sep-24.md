# SEP-24: Interactive Deposit and Withdrawal

**Purpose:** Interactive web flows for depositing fiat currency to receive Stellar tokens, or withdrawing Stellar tokens to a bank account or other external payment method.
**Prerequisites:** Requires JWT from SEP-10 authentication; anchor must publish `TRANSFER_SERVER_SEP0024` in `stellar.toml`
**SDK Class:** `InteractiveService`

## Table of Contents

- [Service Initialization](#service-initialization)
- [Info Endpoint](#info-endpoint)
- [Deposit Flow](#deposit-flow)
- [Withdrawal Flow](#withdrawal-flow)
- [Transaction Status Polling](#transaction-status-polling)
- [Transaction History](#transaction-history)
- [Sep24Transaction — All Fields](#sep24transaction--all-fields)
- [Transaction Statuses](#transaction-statuses)
- [Refund Objects](#refund-objects)
- [Fee Endpoint (deprecated)](#fee-endpoint-deprecated)
- [Error Handling](#error-handling)
- [Common Pitfalls](#common-pitfalls)

---

## Service Initialization

### From domain (recommended)

`InteractiveService.forDomain()` fetches `{domain}/.well-known/stellar.toml`, reads `TRANSFER_SERVER_SEP0024`, and returns a configured service instance. Returns `.failure(.invalidDomain)` for malformed URLs, `.failure(.invalidToml)` for bad TOML, and `.failure(.noInteractiveServerSet)` if the field is absent.

```swift
import stellarsdk

let result = await InteractiveService.forDomain(domain: "https://testanchor.stellar.org")
switch result {
case .success(let service):
    // service is ready to use
    print("Service URL: \(service.serviceAddress)")
case .failure(let error):
    print("Init failed: \(error)")
}
```

Method signature:
```
static func forDomain(domain: String) async -> InteractiveServiceForDomainEnum
```

Return type: `InteractiveServiceForDomainEnum` — `.success(response: InteractiveService)` or `.failure(error: InteractiveServiceError)`

### Manual construction

Use when you already have the transfer server URL.

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")
```

Constructor signature:
```
InteractiveService(serviceAddress: String)
```

`serviceAddress` is stored as `service.serviceAddress: String`.

---

## Info Endpoint

`info()` queries `GET /info` to discover supported assets, fee structures, and feature flags.

Method signature:
```
func info(language: String? = nil) async -> Sep24InfoResponseEnum
```

Return type: `Sep24InfoResponseEnum` — `.success(response: Sep24InfoResponse)` or `.failure(error: InteractiveServiceError)`

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// Optional language parameter (ISO 639-1, e.g. "en", "de")
let result = await service.info(language: "en")
// Or without language:
// let result = await service.info()

switch result {
case .success(let info):
    // Check deposit assets (keyed by asset code)
    if let depositAssets = info.depositAssets {
        for (code, asset) in depositAssets {
            if asset.enabled {
                print("Deposit \(code): min=\(asset.minAmount ?? 0) max=\(asset.maxAmount ?? 0)")
                if let feeFixed = asset.feeFixed { print("  Fixed fee: \(feeFixed)") }
                if let feePercent = asset.feePercent { print("  Percent fee: \(feePercent)%") }
            }
        }
    }

    // Check withdraw assets
    if let withdrawAssets = info.withdrawAssets {
        if let usd = withdrawAssets["USD"], usd.enabled {
            print("USD withdrawal enabled")
        }
    }

    // Feature flags
    if let flags = info.featureFlags {
        print("Account creation: \(flags.accountCreation)")
        print("Claimable balances: \(flags.claimableBalances)")
    }

    // Fee endpoint availability
    if let feeInfo = info.feeEndpointInfo {
        print("Fee endpoint enabled: \(feeInfo.enabled)")
        print("Auth required for fee: \(feeInfo.authenticationRequired)")
    }
case .failure(let error):
    print("Info failed: \(error)")
}
```

### Sep24InfoResponse fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `depositAssets` | `[String: Sep24DepositAsset]?` | `deposit` | Asset codes supported for deposit; nil if none |
| `withdrawAssets` | `[String: Sep24WithdrawAsset]?` | `withdraw` | Asset codes supported for withdrawal; nil if none |
| `feeEndpointInfo` | `Sep24FeeEndpointInfo?` | `fee` | Fee endpoint availability info |
| `featureFlags` | `Sep24FeatureFlags?` | `features` | Optional feature flags |

### Sep24DepositAsset fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `enabled` | `Bool` | `enabled` | Whether deposit of this asset is supported |
| `minAmount` | `Double?` | `min_amount` | Minimum deposit amount; no limit if nil |
| `maxAmount` | `Double?` | `max_amount` | Maximum deposit amount; no limit if nil |
| `feeFixed` | `Double?` | `fee_fixed` | Fixed fee in units of deposited asset |
| `feePercent` | `Double?` | `fee_percent` | Percentage fee in percentage points |
| `feeMinimum` | `Double?` | `fee_minimum` | Minimum fee in units of deposited asset |

`Sep24WithdrawAsset` has the same fields for withdrawals.

### Sep24FeatureFlags fields

| Property | Type | JSON key | Default | Description |
|----------|------|----------|---------|-------------|
| `accountCreation` | `Bool` | `account_creation` | `true` | Anchor can create accounts for new users |
| `claimableBalances` | `Bool` | `claimable_balances` | `false` | Anchor can send deposits as claimable balances |

### Sep24FeeEndpointInfo fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `enabled` | `Bool` | `enabled` | Whether the `/fee` endpoint is available |
| `authenticationRequired` | `Bool` | `authentication_required` | Whether SEP-10 auth is required for `/fee` |

---

## Deposit Flow

A deposit converts external funds (bank transfer, card, etc.) into Stellar tokens sent to the user's account. The anchor returns a URL where the user completes the process interactively.

`deposit()` posts to `POST /transactions/deposit/interactive`.

Method signature:
```
func deposit(request: Sep24DepositRequest) async -> Sep24InteractiveResponseEnum
```

Return type: `Sep24InteractiveResponseEnum` — `.success(response: Sep24InteractiveResponse)` or `.failure(error: InteractiveServiceError)`

### Sep24DepositRequest fields

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `jwt` | `String` | Yes | JWT from SEP-10 authentication |
| `assetCode` | `String` | Yes | Asset code to receive; use `"native"` for XLM |
| `assetIssuer` | `String?` | No | Issuer G... address; do not set for `"native"` |
| `sourceAsset` | `String?` | No | SEP-38 format asset user sends (e.g. `"iso4217:EUR"`) |
| `amount` | `String?` | No | Amount to deposit; must match quote if `quoteId` set |
| `quoteId` | `String?` | No | SEP-38 quote ID for cross-asset deposits |
| `account` | `String?` | No | Destination Stellar or muxed (M...) account; defaults to JWT account |
| `memo` | `String?` | No | Memo to attach; hash type must be base64-encoded |
| `memoType` | `String?` | No | Memo type: `"text"`, `"id"`, or `"hash"` |
| `walletName` | `String?` | No | Wallet display name for anchor UI |
| `walletUrl` | `String?` | No | Wallet URL for anchor notifications |
| `lang` | `String?` | No | RFC 4646 language for interactive UI (e.g. `"en"`, `"en-US"`) |
| `claimableBalanceSupported` | `String?` | No | `"true"` if client supports claimable balances |
| `kycFields` | `[KYCNaturalPersonFieldsEnum]?` | No | SEP-9 natural person KYC fields |
| `kycOrganizationFields` | `[KYCOrganizationFieldsEnum]?` | No | SEP-9 organization KYC fields |
| `kycFinancialAccountFields` | `[KYCFinancialAccountFieldsEnum]?` | No | SEP-9 financial account KYC fields |
| `customFields` | `[String: String]?` | No | Non-standard KYC fields |
| `customFiles` | `[String: Data]?` | No | Non-standard file uploads |

Constructor (required fields only):
```
Sep24DepositRequest(jwt: String, assetCode: String)
```

### Sep24InteractiveResponse fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `type` | `String` | `type` | Always `"interactive_customer_info_needed"` |
| `url` | `String` | `url` | URL to open in a webview for the user |
| `id` | `String` | `id` | Anchor-generated transaction ID for polling |

### Basic deposit

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USDC")
// assetCode and jwt are the only required fields

let result = await service.deposit(request: request)
switch result {
case .success(let response):
    // Open response.url in a webview for the user to complete the flow
    print("Open: \(response.url)")
    print("Transaction ID: \(response.id)")
    // response.type is always "interactive_customer_info_needed"
case .failure(let error):
    print("Deposit failed: \(error)")
}
```

### Deposit with amount and destination

```swift
import stellarsdk

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
request.amount = "100.00"
// Receive on a different account than the authenticated one
request.account = "GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
request.memo = "12345"
request.memoType = "id"   // "text", "id", or "hash"
request.lang = "en"

let result = await service.deposit(request: request)
```

### Deposit with SEP-38 quote (cross-asset)

```swift
import stellarsdk

// Get quoteId from SEP-38 first
var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USDC")
request.sourceAsset = "iso4217:EUR"  // user sends EUR, receives USDC
request.quoteId = "quote-abc-123"
request.amount = "100.00"            // must match quote's sell_amount

let result = await service.deposit(request: request)
```

### Deposit with KYC pre-fill

Pass KYC data to pre-fill the anchor's interactive form.

```swift
import stellarsdk

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

// Natural person fields (SEP-9)
request.kycFields = [
    KYCNaturalPersonFieldsEnum.firstName("Jane"),
    KYCNaturalPersonFieldsEnum.lastName("Doe"),
    KYCNaturalPersonFieldsEnum.emailAddress("jane@example.com"),
]

// Organization fields (SEP-9)
request.kycOrganizationFields = [
    KYCOrganizationFieldsEnum.name("Acme Corp"),
    KYCOrganizationFieldsEnum.VATNumber("VAT123456"),
]

// Financial account fields (SEP-9)
request.kycFinancialAccountFields = [
    KYCFinancialAccountFieldsEnum.bankName("Test Bank"),
    KYCFinancialAccountFieldsEnum.bankAccountNumber("123456789"),
]

// Non-standard fields
request.customFields = ["employer_name": "Tech Corp"]
request.customFiles = ["proof_of_income": pdfData]

let result = await service.deposit(request: request)
```

### Deposit with claimable balance support

```swift
import stellarsdk

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
// Tell the anchor the client supports receiving claimable balances
// (useful if the account has no trustline for the asset)
request.claimableBalanceSupported = "true"

let result = await service.deposit(request: request)
// After completion check tx.claimableBalanceId if the anchor used a claimable balance
```

---

## Withdrawal Flow

A withdrawal converts Stellar tokens into external funds sent to a bank account or other destination. After the user completes the interactive flow, the wallet sends a Stellar payment to the anchor.

`withdraw()` posts to `POST /transactions/withdraw/interactive`.

Method signature:
```
func withdraw(request: Sep24WithdrawRequest) async -> Sep24InteractiveResponseEnum
```

Return type: `Sep24InteractiveResponseEnum` — same as deposit.

### Sep24WithdrawRequest fields

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `jwt` | `String` | Yes | JWT from SEP-10 authentication |
| `assetCode` | `String` | Yes | Asset code to withdraw; use `"native"` for XLM |
| `assetIssuer` | `String?` | No | Issuer G... address; do not set for `"native"` |
| `destinationAsset` | `String?` | No | SEP-38 format asset user receives (e.g. `"iso4217:EUR"`) |
| `amount` | `String?` | No | Amount to withdraw |
| `quoteId` | `String?` | No | SEP-38 quote ID for cross-asset withdrawals |
| `account` | `String?` | No | Source Stellar or muxed (M...) account; defaults to JWT account |
| `memo` | `String?` | No | Deprecated — use SEP-10 JWT sub for shared accounts |
| `memoType` | `String?` | No | Deprecated — type of deprecated `memo` field |
| `walletName` | `String?` | No | Wallet display name for anchor UI |
| `walletUrl` | `String?` | No | Wallet URL for anchor notifications |
| `lang` | `String?` | No | RFC 4646 language for interactive UI |
| `refundMemo` | `String?` | No | Memo for refund payments; must set `refundMemoType` together |
| `refundMemoType` | `String?` | No | Refund memo type: `"text"`, `"id"`, or `"hash"` |
| `kycFields` | `[KYCNaturalPersonFieldsEnum]?` | No | SEP-9 natural person KYC fields |
| `kycOrganizationFields` | `[KYCOrganizationFieldsEnum]?` | No | SEP-9 organization KYC fields |
| `kycFinancialAccountFields` | `[KYCFinancialAccountFieldsEnum]?` | No | SEP-9 financial account KYC fields |
| `customFields` | `[String: String]?` | No | Non-standard KYC fields |
| `customFiles` | `[String: Data]?` | No | Non-standard file uploads |

Constructor (required fields only):
```
Sep24WithdrawRequest(jwt: String, assetCode: String)
```

### Basic withdrawal

```swift
import stellarsdk

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")

let result = await service.withdraw(request: request)
switch result {
case .success(let response):
    // Open response.url in a webview
    print("Open: \(response.url)")
    print("Transaction ID: \(response.id)")
    // After user completes the form, poll transaction endpoint.
    // When status is "pending_user_transfer_start", send the Stellar payment.
case .failure(let error):
    print("Withdraw failed: \(error)")
}
```

### Withdrawal with refund memo

```swift
import stellarsdk

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
request.amount = "500.00"
// Memo the anchor uses if it needs to send a refund payment back
request.refundMemo = "refund-ref-123"
request.refundMemoType = "text"  // must set both together
// WRONG: set refundMemo without refundMemoType — anchor may reject

let result = await service.withdraw(request: request)
```

### Withdrawal with SEP-38 quote (cross-asset)

```swift
import stellarsdk

// Get quoteId from SEP-38 first
var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USDC")
request.destinationAsset = "iso4217:EUR"  // user sends USDC, receives EUR
request.quoteId = "quote-xyz-789"
request.amount = "500.00"

let result = await service.withdraw(request: request)
```

### Completing a withdrawal: sending the Stellar payment

After the user completes the interactive flow, poll for `pending_user_transfer_start` status, then send the Stellar payment to the anchor's account.

```swift
import stellarsdk

// 1. Get transaction details
var txRequest = Sep24TransactionRequest(jwt: jwtToken)
txRequest.id = transactionId

let txResult = await service.getTransaction(request: txRequest)
guard case .success(let txResponse) = txResult else { return }
let tx = txResponse.transaction

// 2. Check if payment is needed
if tx.status == "pending_user_transfer_start",
   let anchorAccount = tx.withdrawAnchorAccount,
   let withdrawMemo = tx.withdrawMemo,
   let amountIn = tx.amountIn {
    // withdrawMemo may be nil if KYC is not yet complete — do not send without it

    let sdk = StellarSDK.testNet()
    let senderKeyPair = try KeyPair(secretSeed: secretSeed)
    let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else { return }
    let sourceAccount = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )

    let issuerKeyPair = try KeyPair(accountId: "GISSUER...")
    let asset = Asset(type: .ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
    guard let amount = Decimal(string: amountIn) else { return }

    let paymentOp = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: anchorAccount,
        asset: asset,
        amount: amount
    )

    let memoType = tx.withdrawMemoType ?? "text"
    let memo: Memo
    switch memoType {
    case "id": memo = Memo.id(UInt64(withdrawMemo) ?? 0)
    case "hash":
        let data = Data(base64Encoded: withdrawMemo) ?? Data()
        memo = try Memo.hash(data)
    default: memo = Memo.text(withdrawMemo)
    }

    let transaction = try Transaction(
        sourceAccount: sourceAccount,
        operations: [paymentOp],
        memo: memo,
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)
    let _ = await sdk.transactions.submitTransaction(transaction: transaction)
}
```

---

## Transaction Status Polling

Use `getTransaction()` to query a single transaction. Always use the `id` returned from `deposit()` or `withdraw()` for polling.

Method signature:
```
func getTransaction(request: Sep24TransactionRequest) async -> Sep24TransactionResponseEnum
```

Return type: `Sep24TransactionResponseEnum` — `.success(response: Sep24TransactionResponse)` or `.failure(error: InteractiveServiceError)`

`Sep24TransactionResponse` has a single property: `transaction: Sep24Transaction`.

### Sep24TransactionRequest fields

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `jwt` | `String` | Yes | JWT from SEP-10 authentication |
| `id` | `String?` | No | Anchor's internal transaction ID |
| `stellarTransactionId` | `String?` | No | Stellar network transaction hash |
| `externalTransactionId` | `String?` | No | External system transaction ID |
| `lang` | `String?` | No | RFC 4646 language for localized `message` field |

Constructor:
```
Sep24TransactionRequest(jwt: String)
```

At least one of `id`, `stellarTransactionId`, or `externalTransactionId` must be set.

```swift
import stellarsdk

// Query by anchor transaction ID (most common)
var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = "82fhs729f63dh0v4"   // from deposit/withdraw response
// OR: request.stellarTransactionId = "17a670bc..."
// OR: request.externalTransactionId = "1941491"

let result = await service.getTransaction(request: request)
switch result {
case .success(let response):
    let tx = response.transaction
    print("Status: \(tx.status)")
    print("Kind: \(tx.kind)")
case .failure(let error):
    switch error {
    case .notFound(let message):
        print("Transaction not found: \(message ?? "unknown")")
    case .authenticationRequired:
        print("Re-authenticate with SEP-10")
    default:
        print("Error: \(error)")
    }
}
```

### Polling loop

```swift
import stellarsdk

let terminalStatuses = ["completed", "refunded", "expired", "error", "no_market", "too_small", "too_large"]

var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = transactionId

for attempt in 0..<60 {
    let result = await service.getTransaction(request: request)
    guard case .success(let response) = result else { break }
    let tx = response.transaction

    print("Status: \(tx.status)")

    if terminalStatuses.contains(tx.status) { break }

    if tx.status == "pending_user_transfer_start" {
        // User must send the Stellar payment now (for withdrawals)
        break
    }

    // Use statusEta if provided; otherwise exponential backoff
    let delay: UInt64
    if let eta = tx.statusEta, eta > 0 {
        delay = UInt64(min(eta, 60)) * 1_000_000_000
    } else {
        delay = UInt64(min(2 * (1 << attempt), 60)) * 1_000_000_000
    }
    try? await Task.sleep(nanoseconds: delay)
}
```

---

## Transaction History

`getTransactions()` returns a list of transactions for the authenticated account, filtered by asset. Queries `GET /transactions`.

Method signature:
```
func getTransactions(request: Sep24TransactionsRequest) async -> Sep24TransactionsResponseEnum
```

Return type: `Sep24TransactionsResponseEnum` — `.success(response: Sep24TransactionsResponse)` or `.failure(error: InteractiveServiceError)`

`Sep24TransactionsResponse` has a single property: `transactions: [Sep24Transaction]` (always an array, never nil; empty when no results).

### Sep24TransactionsRequest fields

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `jwt` | `String` | Yes | JWT from SEP-10 authentication |
| `assetCode` | `String` | Yes | Asset code to filter by |
| `noOlderThan` | `Date?` | No | Only include transactions from this date onward |
| `limit` | `Int?` | No | Maximum number of transactions to return |
| `kind` | `String?` | No | `"deposit"` or `"withdrawal"`; omit for both |
| `pagingId` | `String?` | No | Returns transactions prior to (exclusive) this ID |
| `lang` | `String?` | No | RFC 4646 language code |

Constructor:
```
Sep24TransactionsRequest(jwt: String, assetCode: String)
```

```swift
import stellarsdk

var request = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "USD")
request.limit = 10
request.kind = "deposit"                              // omit for all kinds
request.noOlderThan = Date(timeIntervalSince1970: 1672531200)  // 2023-01-01
request.lang = "en"

let result = await service.getTransactions(request: request)
switch result {
case .success(let response):
    for tx in response.transactions {
        print("\(tx.id): \(tx.kind) - \(tx.status)")
    }

    // Pagination: pass last transaction ID as pagingId for next page
    if let lastTx = response.transactions.last {
        var nextRequest = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "USD")
        nextRequest.pagingId = lastTx.id
        let _ = await service.getTransactions(request: nextRequest)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

---

## Sep24Transaction — All Fields

`Sep24Transaction` is the object inside `Sep24TransactionResponse.transaction` and each element of `Sep24TransactionsResponse.transactions`.

### Always-present fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `id` | `String` | `id` | Unique anchor-generated transaction ID |
| `kind` | `String` | `kind` | `"deposit"`, `"withdrawal"`, `"deposit-exchange"`, or `"withdrawal-exchange"` |
| `status` | `String` | `status` | Current processing status |
| `startedAt` | `Date` | `started_at` | When the transaction was created (ISO 8601) |

### Optional fields (all nullable)

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `statusEta` | `Int?` | `status_eta` | Estimated seconds until next status change |
| `kycVerified` | `Bool?` | `kyc_verified` | Whether anchor verified KYC for this transaction |
| `moreInfoUrl` | `String?` | `more_info_url` | URL with additional transaction details |
| `amountIn` | `String?` | `amount_in` | Amount received by anchor (up to 7 decimals, as String) |
| `amountInAsset` | `String?` | `amount_in_asset` | SEP-38 format asset received by anchor |
| `amountOut` | `String?` | `amount_out` | Amount sent to user (up to 7 decimals, as String) |
| `amountOutAsset` | `String?` | `amount_out_asset` | SEP-38 format asset delivered to user |
| `amountFee` | `String?` | `amount_fee` | Fee charged by anchor (as String) |
| `amountFeeAsset` | `String?` | `amount_fee_asset` | SEP-38 format asset for fee |
| `quoteId` | `String?` | `quote_id` | SEP-38 quote ID used for this transaction |
| `completedAt` | `Date?` | `completed_at` | When transaction completed (ISO 8601) |
| `updatedAt` | `Date?` | `updated_at` | When transaction status last changed (ISO 8601) |
| `userActionRequiredBy` | `Date?` | `user_action_required_by` | Deadline for user action (ISO 8601) |
| `stellarTransactionId` | `String?` | `stellar_transaction_id` | Stellar network transaction hash |
| `externalTransactionId` | `String?` | `external_transaction_id` | External system transaction ID |
| `message` | `String?` | `message` | Human-readable status explanation |
| `refunded` | `Bool?` | `refunded` | Deprecated — use `refunds` and `"refunded"` status |
| `refunds` | `Sep24Refund?` | `refunds` | Refund details if transaction was refunded |
| `from` | `String?` | `from` | Deposit: sender address; Withdrawal: source Stellar address |
| `to` | `String?` | `to` | Deposit: destination Stellar address; Withdrawal: destination address |

### Deposit-only fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `depositMemo` | `String?` | `deposit_memo` | Memo used in the deposit payment |
| `depositMemoType` | `String?` | `deposit_memo_type` | Memo type for `depositMemo` |
| `claimableBalanceId` | `String?` | `claimable_balance_id` | ID of Claimable Balance used to send the asset |

### Withdrawal-only fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `withdrawAnchorAccount` | `String?` | `withdraw_anchor_account` | Anchor's Stellar account to send payment to |
| `withdrawMemo` | `String?` | `withdraw_memo` | Memo to include in the payment; nil if KYC not yet complete |
| `withdrawMemoType` | `String?` | `withdraw_memo_type` | Memo type for `withdrawMemo` |

### Reading transaction fields

```swift
import stellarsdk

var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = transactionId

let result = await service.getTransaction(request: request)
guard case .success(let response) = result else { return }
let tx = response.transaction

// Core fields — always present
print("ID: \(tx.id)")
print("Kind: \(tx.kind)")
print("Status: \(tx.status)")
print("Started: \(tx.startedAt)")

// Amount fields — Strings when present
if let amountIn = tx.amountIn { print("Amount in: \(amountIn)") }
if let amountOut = tx.amountOut { print("Amount out: \(amountOut)") }

// Date fields
if let completedAt = tx.completedAt { print("Completed: \(completedAt)") }
if let userActionBy = tx.userActionRequiredBy { print("Action required by: \(userActionBy)") }

// Withdrawal payment instructions
if tx.kind == "withdrawal" && tx.status == "pending_user_transfer_start" {
    // withdrawMemo is nil if KYC is not yet complete — do not send payment without it
    if let anchorAccount = tx.withdrawAnchorAccount,
       let memo = tx.withdrawMemo {
        print("Send \(tx.amountIn ?? "?") to \(anchorAccount)")
        print("Memo: \(memo) (\(tx.withdrawMemoType ?? "text"))")
    }
}

// Deposit claimable balance
if tx.kind == "deposit", let cbId = tx.claimableBalanceId {
    print("Claimable balance ID: \(cbId)")
}
```

---

## Transaction Statuses

The `status` field on `Sep24Transaction`:

| Status | Description |
|--------|-------------|
| `incomplete` | User has not completed the interactive flow yet |
| `pending_user_transfer_start` | Waiting for user to initiate transfer (withdrawal: send Stellar payment) |
| `pending_user_transfer_complete` | Stellar payment received; off-chain processing pending |
| `pending_external` | Waiting for off-chain confirmation (bank transfer, etc.) |
| `pending_anchor` | Anchor is processing the transaction |
| `pending_stellar` | Waiting for Stellar network confirmation |
| `pending_trust` | User must add a trustline for the asset |
| `pending_user` | User must take an action; see `message` or `moreInfoUrl` |
| `completed` | Transaction finished successfully |
| `refunded` | Transaction was fully or partially refunded; see `refunds` |
| `expired` | Transaction expired before completion |
| `no_market` | No market available for the asset pair (SEP-38 exchange) |
| `too_small` | Amount is below the anchor's minimum threshold |
| `too_large` | Amount exceeds the anchor's maximum threshold |
| `error` | Transaction failed due to an error |

---

## Refund Objects

When a transaction is refunded (`status == "refunded"` or `refunds` is non-nil), inspect the `refunds` field on the transaction.

### Sep24Refund fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `amountRefunded` | `String` | `amount_refunded` | Total refunded to user (in units of `amountInAsset`) |
| `amountFee` | `String` | `amount_fee` | Total fee for processing all refund payments |
| `payments` | `[Sep24RefundPayment]?` | `payments` | Individual refund payment records |

### Sep24RefundPayment fields

| Property | Type | JSON key | Description |
|----------|------|----------|-------------|
| `id` | `String` | `id` | Stellar tx hash or external payment reference |
| `idType` | `String` | `id_type` | `"stellar"` or `"external"` |
| `amount` | `String` | `amount` | Amount refunded by this payment |
| `fee` | `String` | `fee` | Fee charged for this refund payment |

```swift
import stellarsdk

var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = transactionId

let result = await service.getTransaction(request: request)
guard case .success(let response) = result else { return }
let tx = response.transaction

if let refunds = tx.refunds {
    print("Total refunded: \(refunds.amountRefunded)")
    print("Refund fees: \(refunds.amountFee)")

    if let payments = refunds.payments {
        for payment in payments {
            print("Payment ID: \(payment.id)")
            print("  Type: \(payment.idType)")   // "stellar" or "external"
            print("  Amount: \(payment.amount)")
            print("  Fee: \(payment.fee)")
        }
    }
}
```

---

## Fee Endpoint (deprecated)

The `/fee` endpoint is deprecated in favor of SEP-38 `GET /price`. Only use it if the anchor's `/info` response indicates it is enabled (`info.feeEndpointInfo?.enabled == true`).

Method signature:
```
func fee(request: Sep24FeeRequest) async -> Sep24FeeResponseEnum
```

Return type: `Sep24FeeResponseEnum` — `.success(response: Sep24FeeResponse)` or `.failure(error: InteractiveServiceError)`

`Sep24FeeResponse` has a single property: `fee: Double`.

### Sep24FeeRequest fields

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `operation` | `String` | Yes | `"deposit"` or `"withdraw"` |
| `assetCode` | `String` | Yes | Asset code |
| `amount` | `Double` | Yes | Amount to deposit/withdraw |
| `type` | `String?` | No | Payment type (e.g. `"SEPA"`, `"bank_account"`) |
| `jwt` | `String?` | No | JWT token (required if `authenticationRequired` is true) |

Constructor:
```
Sep24FeeRequest(operation: String, type: String? = nil, assetCode: String, amount: Double, jwt: String? = nil)
```

```swift
import stellarsdk

// Always check if the fee endpoint is enabled first
let infoResult = await service.info()
guard case .success(let info) = infoResult,
      let feeInfo = info.feeEndpointInfo,
      feeInfo.enabled else {
    print("Fee endpoint not available")
    return
}

let jwtIfRequired = feeInfo.authenticationRequired ? jwtToken : nil

let feeRequest = Sep24FeeRequest(
    operation: "deposit",
    type: "bank_account",     // optional
    assetCode: "USD",
    amount: 1000.0,
    jwt: jwtIfRequired
)

let feeResult = await service.fee(request: feeRequest)
switch feeResult {
case .success(let feeResponse):
    print("Fee: \(feeResponse.fee)")
case .failure(let error):
    print("Fee request failed: \(error)")
}
```

---

## Error Handling

All SEP-24 methods return a result enum with `.failure(error: InteractiveServiceError)`.

### InteractiveServiceError cases

| Case | Trigger | Action |
|------|---------|--------|
| `.invalidDomain` | Malformed domain URL passed to `forDomain()` | Check domain string includes scheme (https://) |
| `.invalidToml` | stellar.toml could not be fetched or parsed | Check domain is correct and toml is valid |
| `.noInteractiveServerSet` | `TRANSFER_SERVER_SEP0024` missing from toml | Anchor has not configured SEP-24 |
| `.authenticationRequired` | HTTP 403 with `"authentication_required"` type | Re-authenticate with SEP-10 and get a fresh JWT |
| `.notFound(message: String?)` | HTTP 404 | Transaction ID not found or not owned by authenticated user |
| `.anchorError(message: String)` | HTTP 400/5xx with `"error"` key in response | Check message for anchor-specific details (e.g., unsupported asset) |
| `.parsingResponseFailed(message: String)` | JSON parsing failed | Anchor returned unexpected response format |
| `.horizonError(error: HorizonRequestError)` | Network-level error | Check network connectivity |

```swift
import stellarsdk

var depositRequest = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

let result = await service.deposit(request: depositRequest)
switch result {
case .success(let response):
    print("Open: \(response.url)")
case .failure(let error):
    switch error {
    case .authenticationRequired:
        // HTTP 403 — JWT is invalid or expired
        print("Re-authenticate with SEP-10")
    case .anchorError(let message):
        // HTTP 400/5xx — e.g., "This anchor doesn't support the given currency code"
        print("Anchor error: \(message)")
    case .notFound(let message):
        print("Not found: \(message ?? "unknown")")
    case .parsingResponseFailed(let message):
        print("Parse error: \(message)")
    case .horizonError(let horizonError):
        print("Network error: \(horizonError)")
    case .invalidDomain, .invalidToml, .noInteractiveServerSet:
        print("Init error: \(error)")
    }
}
```

---

## Common Pitfalls

**Wrong: setting `assetIssuer` for native XLM**

```swift
// WRONG: native assets have no issuer
var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "native")
request.assetIssuer = "GABC..."  // anchor will reject

// CORRECT: omit assetIssuer for native
var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "native")
```

**Wrong: setting `refundMemo` without `refundMemoType` (or vice versa)**

```swift
// WRONG: both fields must be set together
var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
request.refundMemo = "ref-123"
// Missing: request.refundMemoType = "text"

// CORRECT: always set both together
request.refundMemo = "ref-123"
request.refundMemoType = "text"   // "text", "id", or "hash"
```

**Wrong: accessing `withdrawMemo` before KYC is complete**

```swift
// WRONG: withdrawMemo is nil until KYC is verified — even in pending_user_transfer_start
if tx.status == "pending_user_transfer_start" {
    sendPayment(to: tx.withdrawAnchorAccount!, memo: tx.withdrawMemo!)  // may crash
}

// CORRECT: guard on both fields
if tx.status == "pending_user_transfer_start",
   let anchorAccount = tx.withdrawAnchorAccount,
   let memo = tx.withdrawMemo {
    sendPayment(to: anchorAccount, memo: memo)
}
```

**Wrong: using `getTransactions()` to look up by transaction ID**

```swift
// WRONG: Sep24TransactionsRequest has no id field; requires assetCode
var req = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "USD")
// There is no req.id property — getTransactions() returns a list, not a single record

// CORRECT: use getTransaction() (singular) for ID-based lookup
var req = Sep24TransactionRequest(jwt: jwtToken)
req.id = transactionId
let result = await service.getTransaction(request: req)
```

**Wrong: treating amount fields as numbers**

```swift
// WRONG: amountIn, amountOut, amountFee are String? not Double
if tx.amountIn > 100.0 { ... }  // compile error — String vs Double

// CORRECT: convert String to Double for arithmetic
if let amountStr = tx.amountIn, let amount = Double(amountStr), amount > 100.0 {
    print("Large deposit: \(amount)")
}
```

**Wrong: not providing `language` parameter to `info()` — the parameter is named `language`, not `lang`**

```swift
// WRONG: parameter name is "lang" — does not compile
let result = await service.info(lang: "en")

// CORRECT: parameter is named "language"
let result = await service.info(language: "en")
// Or omit for default
let result = await service.info()
```

**Wrong: `Sep24TransactionRequest` init only takes `jwt` — set identifier fields separately**

```swift
// WRONG: no id parameter in constructor
var req = Sep24TransactionRequest(jwt: jwtToken, id: "82fhs729f63dh0v4")  // compile error

// CORRECT: set id after construction (it's a var property)
var req = Sep24TransactionRequest(jwt: jwtToken)
req.id = "82fhs729f63dh0v4"
```

**Wrong: `claimableBalanceSupported` is a String, not Bool**

```swift
// WRONG: Bool is not accepted
var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
request.claimableBalanceSupported = true  // compile error — type is String?

// CORRECT: pass the string "true"
request.claimableBalanceSupported = "true"
```

---

## Related SEPs

- [sep.md](sep.md) — All SEP implementations overview
- SEP-01 — stellar.toml (`TRANSFER_SERVER_SEP0024` is published here)
- SEP-10 — Web Authentication (required for JWT)
- SEP-12 — KYC API (often used alongside SEP-24)
- SEP-38 — Anchor RFQ API (quotes for exchange rates; replaces `/fee` endpoint)
