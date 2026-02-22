# SEP-06: Deposit and Withdrawal API

**Purpose:** Programmatic deposits and withdrawals through anchors without user-facing web flows.
**Prerequisites:** Requires JWT from SEP-10 (see [sep-10.md](sep-10.md))
**SDK Class:** `TransferServerService`
**Spec:** SEP-0006 v4.3.0

## Table of Contents

- [Service Initialization](#service-initialization)
- [Info Endpoint](#info-endpoint)
- [Deposit Flow](#deposit-flow)
- [Deposit Exchange Flow (cross-asset)](#deposit-exchange-flow-cross-asset)
- [Withdraw Flow](#withdraw-flow)
- [Withdraw Exchange Flow (cross-asset)](#withdraw-exchange-flow-cross-asset)
- [Fee Endpoint](#fee-endpoint)
- [Transaction History](#transaction-history)
- [Single Transaction Status](#single-transaction-status)
- [Patch Transaction](#patch-transaction)
- [Error Handling](#error-handling)
- [Transaction Statuses](#transaction-statuses)
- [Common Pitfalls](#common-pitfalls)

---

## Service Initialization

### From domain (recommended)

Reads `TRANSFER_SERVER` from the anchor's `stellar.toml` via SEP-01 automatically.

```swift
import stellarsdk

// NOTE: forDomain requires a full URL with scheme (unlike WebAuthenticator.from which takes a plain domain)
let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
switch result {
case .success(let service):
    // service.transferServiceAddress contains the resolved endpoint
    print("Transfer server: \(service.transferServiceAddress)")
case .failure(let error):
    switch error {
    case .invalidDomain:
        print("Invalid domain URL")
    case .invalidToml:
        print("stellar.toml not found or malformed")
    case .noTransferServerSet:
        print("TRANSFER_SERVER not set in stellar.toml")
    default:
        print("Error: \(error)")
    }
}
```

`forDomain` signature:
```swift
static func forDomain(domain: String) async -> TransferServerServiceForDomainEnum
```

Result enum: `TransferServerServiceForDomainEnum`
- `.success(response: TransferServerService)` — service instance
- `.failure(error: TransferServerError)` — initialization error

### Direct URL constructor

Use when you already have the transfer server URL.

```swift
import stellarsdk

// Trailing slashes are automatically stripped
let service = TransferServerService(serviceAddress: "https://testanchor.stellar.org/sep6")
// service.transferServiceAddress == "https://testanchor.stellar.org/sep6"
```

`init` signature:
```swift
init(serviceAddress: String)
```

**Note:** Only the last trailing slash is removed. `"https://example.com///"` becomes `"https://example.com//"`.

---

## Info Endpoint

Query anchor capabilities before initiating deposits or withdrawals.

```swift
import stellarsdk

// Optional: pass JWT and/or language code
let responseEnum = await service.info(language: "en", jwtToken: jwtToken)
switch responseEnum {
case .success(let info):
    // info is AnchorInfoResponse
    if let depositAssets = info.deposit {
        for (code, asset) in depositAssets {
            // asset is DepositAsset
            print("\(code) enabled: \(asset.enabled)")
            print("  auth required: \(asset.authenticationRequired ?? false)")
            print("  fee fixed: \(asset.feeFixed.map { "\($0)" } ?? "none")")
            print("  fee percent: \(asset.feePercent.map { "\($0)" } ?? "none")")
            print("  min: \(asset.minAmount.map { "\($0)" } ?? "none")")
            print("  max: \(asset.maxAmount.map { "\($0)" } ?? "none")")
        }
    }
    if let withdrawAssets = info.withdraw {
        for (code, asset) in withdrawAssets {
            // asset is WithdrawAsset
            print("\(code) withdraw enabled: \(asset.enabled)")
            if let types = asset.types {
                for (typeName, withdrawType) in types {
                    // withdrawType is WithdrawType
                    print("  type: \(typeName)")
                    if let fields = withdrawType.fields {
                        for (fieldName, field) in fields {
                            // field is AnchorField
                            print("    \(fieldName): \(field.description ?? "")")
                        }
                    }
                }
            }
        }
    }
    if let features = info.features {
        print("account creation: \(features.accountCreation)") // defaults to true
        print("claimable balances: \(features.claimableBalances)") // defaults to false
    }
case .failure(let error):
    print("Error: \(error)")
}
```

`info()` signature:
```swift
func info(language: String? = nil, jwtToken: String? = nil) async -> AnchorInfoResponseEnum
```

Result enum: `AnchorInfoResponseEnum`
- `.success(response: AnchorInfoResponse)`
- `.failure(error: TransferServerError)`

### AnchorInfoResponse fields

| Property | Type | Description |
|----------|------|-------------|
| `deposit` | `[String: DepositAsset]?` | Keyed by asset code |
| `depositExchange` | `[String: DepositExchangeAsset]?` | Keyed by asset code |
| `withdraw` | `[String: WithdrawAsset]?` | Keyed by asset code |
| `withdrawExchange` | `[String: WithdrawExchangeAsset]?` | Keyed by asset code |
| `fee` | `AnchorFeeInfo?` | Fee endpoint availability |
| `transactions` | `AnchorTransactionsInfo?` | Transactions endpoint availability |
| `transaction` | `AnchorTransactionInfo?` | Transaction endpoint availability |
| `features` | `AnchorFeatureFlags?` | Feature support flags |

**DepositAsset** fields:

| Property | Type | Description |
|----------|------|-------------|
| `enabled` | `Bool` | Whether deposits are supported |
| `authenticationRequired` | `Bool?` | Whether JWT is required |
| `feeFixed` | `Double?` | Fixed fee in asset units |
| `feePercent` | `Double?` | Percentage fee in percentage points |
| `minAmount` | `Double?` | Minimum deposit amount |
| `maxAmount` | `Double?` | Maximum deposit amount |
| `fields` | `[String: AnchorField]?` | Deprecated: required field descriptors |

**DepositExchangeAsset** fields: `enabled`, `authenticationRequired`, `fields` (same as DepositAsset but no fee/limit fields).

**WithdrawAsset** fields: `enabled`, `authenticationRequired`, `feeFixed`, `feePercent`, `minAmount`, `maxAmount`, plus:

| Property | Type | Description |
|----------|------|-------------|
| `types` | `[String: WithdrawType]?` | Withdrawal methods keyed by type name |

**WithdrawType** has a single property: `fields: [String: AnchorField]?`

**WithdrawExchangeAsset** fields: `enabled`, `authenticationRequired`, `types`.

**AnchorField** (individual field descriptor):

| Property | Type | Description |
|----------|------|-------------|
| `description` | `String?` | Human-readable description |
| `optional` | `Bool?` | Whether field is optional |
| `choices` | `[String]?` | Allowed values |

**AnchorFeatureFlags:**
- `accountCreation: Bool` — defaults to `true` if absent
- `claimableBalances: Bool` — defaults to `false` if absent

**AnchorFeeInfo / AnchorTransactionsInfo / AnchorTransactionInfo:**
- `enabled: Bool`
- `authenticationRequired: Bool?`

---

## Deposit Flow

A deposit is where the user sends an external asset (cash, BTC, bank transfer) to the anchor, and the anchor sends equivalent Stellar tokens to the user's account. Call `info()` first to check the asset's `minAmount`/`maxAmount` and whether `type` is required by the anchor.

### DepositRequest init

Required parameters: `assetCode`, `account`. All others are optional.

```swift
// Minimal required init
var request = DepositRequest(assetCode: "USD", account: accountId, jwt: jwtToken)

// Then set optional fields
request.memoType = "id"                                   // text, id, or hash
request.memo = "12345"
request.emailAddress = "user@example.com"
request.type = "SEPA"                                     // deposit method — often required by anchors
request.lang = "en"                                       // RFC 4646 language code
request.onChangeCallback = "https://wallet.example.com/callback"
request.amount = "500.00"                                 // helps anchor determine KYC needs
request.countryCode = "USA"                               // ISO 3166-1 alpha-3
request.claimableBalanceSupported = "true"                // "true" or "false" as String
request.customerId = "cust-123"                           // SEP-12 customer ID
request.locationId = "loc-456"                            // cash drop-off location
request.walletName = "My Wallet"                          // deprecated
request.walletUrl = "https://wallet.example.com"         // deprecated
request.extraFields = ["custom_field": "value"]           // anchor-specific fields
```

`DepositRequest.init` signature:
```swift
init(assetCode: String, account: String, jwt: String? = nil)
```

### Basic deposit request

```swift
import stellarsdk

var request = DepositRequest(assetCode: "USD", account: accountId, jwt: jwtToken)

let responseEnum = await service.deposit(request: request)
switch responseEnum {
case .success(let response):
    // response is DepositResponse

    // how: deprecated terse instructions string (always present)
    print("How: \(response.how)")

    // instructions: structured key-value deposit instructions (preferred over 'how')
    // keys are SEP-9 field names; values are DepositInstruction objects
    if let instructions = response.instructions {
        for (key, instruction) in instructions {
            // instruction.value: the field value (e.g. bank account number)
            // instruction.description: human-readable label
            print("\(key): \(instruction.value) (\(instruction.description))")
        }
    }

    // id: anchor's transaction ID for status polling
    if let id = response.id {
        print("Transaction ID: \(id)")
    }

    // eta: estimated seconds to credit
    if let eta = response.eta {
        print("ETA: \(eta)s")
    }

    if let feeFixed = response.feeFixed { print("Fee (fixed): \(feeFixed)") }
    if let feePercent = response.feePercent { print("Fee (%): \(feePercent)") }
    if let minAmount = response.minAmount { print("Min: \(minAmount)") }
    if let maxAmount = response.maxAmount { print("Max: \(maxAmount)") }

    // extraInfo: optional additional message
    if let message = response.extraInfo?.message {
        print("Note: \(message)")
    }

case .failure(let error):
    switch error {
    case .authenticationRequired:
        print("Auth required — get a JWT via SEP-10 first")
    case .informationNeeded(let response):
        switch response {
        case .nonInteractive(let info):
            // info.fields: [String] — SEP-12 field names to submit
            print("KYC required: \(info.fields.joined(separator: ", "))")
        case .status(let info):
            // info.status: "pending" or "denied"
            // info.moreInfoUrl: String?
            // info.eta: Int?
            print("KYC status: \(info.status)")
        }
    case .anchorError(let message):
        print("Anchor error: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

`deposit()` signature:
```swift
func deposit(request: DepositRequest) async -> DepositResponseEnum
```

Result enum: `DepositResponseEnum`
- `.success(response: DepositResponse)`
- `.failure(error: TransferServerError)`

### DepositResponse fields

| Property | Type | Description |
|----------|------|-------------|
| `how` | `String` | Deprecated terse deposit instructions (always present) |
| `instructions` | `[String: DepositInstruction]?` | Structured deposit instructions (preferred) |
| `id` | `String?` | Anchor transaction ID |
| `eta` | `Int?` | Estimated seconds to credit |
| `minAmount` | `Double?` | Minimum deposit amount |
| `maxAmount` | `Double?` | Maximum deposit amount |
| `feeFixed` | `Double?` | Fixed fee in deposited asset units |
| `feePercent` | `Double?` | Percentage fee |
| `extraInfo` | `ExtraInfo?` | Additional info; only field is `message: String?` |

**DepositInstruction** (each element of `instructions`):
- `value: String` — the field value (e.g., bank account number)
- `description: String` — human-readable label

---

## Deposit Exchange Flow (cross-asset)

For currency-converting deposits (e.g., deposit BRL cash, receive USDC on Stellar). Requires anchor support for SEP-38 quotes.

### DepositExchangeRequest init

Required parameters: `destinationAsset`, `sourceAsset`, `amount`, `account`. All others optional.

```swift
// Minimal required init
var request = DepositExchangeRequest(
    destinationAsset: "USDC",         // on-chain Stellar asset code
    sourceAsset: "iso4217:BRL",       // SEP-38 asset identification format
    amount: "480.00",                  // in source asset (BRL)
    account: accountId,
    jwt: jwtToken
)

// Optional fields
request.quoteId = "282837"             // SEP-38 quote ID (locks exchange rate)
request.type = "bank_account"
request.memoType = "id"
request.memo = "12345"
request.emailAddress = "user@example.com"
request.lang = "en"
request.onChangeCallback = "https://wallet.example.com/callback"
request.countryCode = "BRA"
request.claimableBalanceSupported = "true"
request.customerId = "cust-123"
request.locationId = "loc-456"
request.walletName = "My Wallet"       // deprecated
request.walletUrl = "https://wallet.example.com" // deprecated
request.extraFields = ["custom_field": "value"]
```

`DepositExchangeRequest.init` signature:
```swift
init(destinationAsset: String, sourceAsset: String, amount: String, account: String, jwt: String? = nil)
```

```swift
import stellarsdk

let responseEnum = await service.depositExchange(request: request)
switch responseEnum {
case .success(let response):
    // response is DepositResponse (same type as regular deposit)
    print("Transaction ID: \(response.id ?? "none")")
    if let instructions = response.instructions {
        for (key, instruction) in instructions {
            print("\(key): \(instruction.value)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

`depositExchange()` returns `DepositResponseEnum` — same `DepositResponse` type as regular deposit.

---

## Withdraw Flow

A withdrawal is where the user sends Stellar tokens to the anchor's account, and the anchor sends equivalent external assets (cash, bank transfer, etc.) to the user's off-chain destination.

### WithdrawRequest init

Required parameters: `type`, `assetCode`. All others are optional.

```swift
// Minimal required init
var request = WithdrawRequest(type: "bank_account", assetCode: "USDC", jwt: jwtToken)

// Then set optional fields
request.dest = "123456789"                                // deprecated: bank account number
request.destExtra = "021000021"                           // deprecated: routing number, BIC
request.account = accountId                               // source Stellar account
request.memo = "12345"                                    // deprecated when using SEP-10
request.memoType = "id"                                   // deprecated
request.lang = "en"
request.onChangeCallback = "https://wallet.example.com/callback"
request.amount = "500.00"
request.countryCode = "DEU"
request.refundMemo = "refund-123"     // if set, refundMemoType must also be set
request.refundMemoType = "text"       // id, text, or hash
request.customerId = "cust-123"
request.locationId = "loc-456"
request.walletName = "My Wallet"      // deprecated
request.walletUrl = "https://wallet.example.com" // deprecated
request.extraFields = ["bank_name": "Example Bank"]
```

`WithdrawRequest.init` signature:
```swift
init(type: String, assetCode: String, jwt: String? = nil)
```

### Basic withdraw request

```swift
import stellarsdk

var request = WithdrawRequest(type: "bank_account", assetCode: "USDC", jwt: jwtToken)
request.account = accountId
request.amount = "500.00"

let responseEnum = await service.withdraw(request: request)
switch responseEnum {
case .success(let response):
    // response is WithdrawResponse

    // accountId: anchor's Stellar account to send tokens to
    if let accountId = response.accountId {
        print("Send payment to: \(accountId)")
    }

    // memo / memoType: include in the Stellar payment to the anchor
    if let memoType = response.memoType, let memo = response.memo {
        print("Memo (\(memoType)): \(memo)")
    }

    if let id = response.id { print("Transaction ID: \(id)") }
    if let eta = response.eta { print("ETA: \(eta)s") }
    if let feeFixed = response.feeFixed { print("Fee: \(feeFixed)") }
    if let message = response.extraInfo?.message { print("Note: \(message)") }

case .failure(let error):
    switch error {
    case .authenticationRequired:
        print("Auth required")
    case .informationNeeded(let response):
        switch response {
        case .nonInteractive(let info):
            print("KYC required: \(info.fields.joined(separator: ", "))")
        case .status(let info):
            print("KYC status: \(info.status)")
        }
    case .anchorError(let message):
        print("Anchor error: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

`withdraw()` signature:
```swift
func withdraw(request: WithdrawRequest) async -> WithdrawResponseEnum
```

Result enum: `WithdrawResponseEnum`
- `.success(response: WithdrawResponse)`
- `.failure(error: TransferServerError)`

### WithdrawResponse fields

| Property | Type | Description |
|----------|------|-------------|
| `accountId` | `String?` | Anchor's Stellar account to send payment to |
| `memoType` | `String?` | Memo type: text, id, or hash |
| `memo` | `String?` | Memo value to include in the Stellar payment |
| `id` | `String?` | Anchor transaction ID |
| `eta` | `Int?` | Estimated seconds to credit |
| `minAmount` | `Double?` | Minimum withdrawal amount |
| `maxAmount` | `Double?` | Maximum withdrawal amount |
| `feeFixed` | `Double?` | Fixed fee in withdrawn asset units |
| `feePercent` | `Double?` | Percentage fee |
| `extraInfo` | `ExtraInfo?` | Additional info; only field is `message: String?` |

---

## Withdraw Exchange Flow (cross-asset)

For currency-converting withdrawals (e.g., send USDC on Stellar, receive NGN to bank account). Requires anchor support for SEP-38 quotes.

### WithdrawExchangeRequest init

Required parameters: `sourceAsset`, `destinationAsset`, `amount`, `type`. All others optional.

```swift
// Minimal required init
var request = WithdrawExchangeRequest(
    sourceAsset: "USDC",              // on-chain Stellar asset to send
    destinationAsset: "iso4217:NGN",  // SEP-38 format for off-chain asset to receive
    amount: "100.00",                  // in source asset (USDC)
    type: "bank_account",
    jwt: jwtToken
)

// Optional fields
request.quoteId = "282838"             // SEP-38 quote ID (locks exchange rate)
request.dest = "NGN_ACCOUNT"           // deprecated
request.destExtra = "ROUTING_NUM"      // deprecated
request.account = accountId
request.memo = "12345"                 // deprecated
request.memoType = "id"                // deprecated
request.lang = "en"
request.onChangeCallback = "https://wallet.example.com/callback"
request.countryCode = "NGA"
request.refundMemo = "refund-456"
request.refundMemoType = "text"
request.customerId = "cust-123"
request.locationId = "loc-456"
request.walletName = "My Wallet"       // deprecated
request.walletUrl = "https://wallet.example.com" // deprecated
request.extraFields = ["bank_name": "Example Bank"]
```

`WithdrawExchangeRequest.init` signature:
```swift
init(sourceAsset: String, destinationAsset: String, amount: String, type: String, jwt: String? = nil)
```

```swift
import stellarsdk

let responseEnum = await service.withdrawExchange(request: request)
switch responseEnum {
case .success(let response):
    // response is WithdrawResponse (same type as regular withdraw)
    if let accountId = response.accountId {
        print("Send payment to: \(accountId)")
    }
    if let memo = response.memo {
        print("Memo (\(response.memoType ?? "")): \(memo)")
    }
    print("Transaction ID: \(response.id ?? "none")")
case .failure(let error):
    print("Error: \(error)")
}
```

`withdrawExchange()` returns `WithdrawResponseEnum` — same `WithdrawResponse` type as regular withdraw.

---

## Fee Endpoint

Query fees before initiating a transfer. Only available if the anchor's `/info` reports `fee.enabled == true`. This endpoint is deprecated; prefer fee information from `/info` or transaction `feeDetails`.

### FeeRequest init

```swift
// operation: "deposit" or "withdraw"
// amount: Double (not String — this differs from deposit/withdraw amount fields)
var request = FeeRequest(operation: "deposit", assetCode: "ETH", amount: 2034.09, jwt: jwtToken)
request.type = "SEPA"  // optional: deposit/withdrawal method
```

`FeeRequest.init` signature:
```swift
init(operation: String, type: String? = nil, assetCode: String, amount: Double, jwt: String? = nil)
```

```swift
import stellarsdk

// Check fee endpoint availability first
let infoEnum = await service.info()
guard case .success(let info) = infoEnum, info.fee?.enabled == true else {
    print("Fee endpoint not available")
    return
}

let feeRequest = FeeRequest(operation: "deposit", assetCode: "ETH", amount: 2034.09)
let feeEnum = await service.fee(request: feeRequest)
switch feeEnum {
case .success(let response):
    // response.fee: Double — total fee in asset units
    print("Fee: \(response.fee)")
case .failure(let error):
    print("Error: \(error)")
}
```

`fee()` signature:
```swift
func fee(request: FeeRequest) async -> AnchorFeeResponseEnum
```

Result enum: `AnchorFeeResponseEnum`
- `.success(response: AnchorFeeResponse)` — `AnchorFeeResponse.fee: Double`
- `.failure(error: TransferServerError)`

---

## Transaction History

List all transactions for an account with optional filtering.

### AnchorTransactionsRequest init

```swift
var request = AnchorTransactionsRequest(assetCode: "USD", account: accountId, jwt: jwtToken)
request.noOlderThan = Date(timeIntervalSinceNow: -30 * 24 * 3600)  // Date, not String
request.limit = 10
request.kind = "deposit"    // deposit, deposit-exchange, withdrawal, withdrawal-exchange
request.pagingId = "82fhs729f63dh0v4"  // pagination: return transactions before this ID (exclusive)
request.lang = "en"
```

`AnchorTransactionsRequest.init` signature:
```swift
init(assetCode: String, account: String, jwt: String? = nil)
```

```swift
import stellarsdk

let request = AnchorTransactionsRequest(assetCode: "XLM", account: accountId, jwt: jwtToken)
let responseEnum = await service.getTransactions(request: request)
switch responseEnum {
case .success(let response):
    // response.transactions: [AnchorTransaction]
    for tx in response.transactions {
        print("ID: \(tx.id)")
        print("  kind: \(tx.kind.rawValue)")    // "deposit", "deposit-exchange", "withdrawal", "withdrawal-exchange"
        print("  status: \(tx.status.rawValue)")
        print("  amountIn: \(tx.amountIn ?? "pending")")
        print("  amountOut: \(tx.amountOut ?? "pending")")
        print("  amountFee: \(tx.amountFee ?? "pending")") // deprecated; use feeDetails
        print("  startedAt: \(tx.startedAt.map { "\($0)" } ?? "-")")
        print("  completedAt: \(tx.completedAt.map { "\($0)" } ?? "-")")

        // Exchange transactions include SEP-38 asset fields
        if let amountInAsset = tx.amountInAsset {
            print("  amountInAsset: \(amountInAsset)")
        }
        if let amountOutAsset = tx.amountOutAsset {
            print("  amountOutAsset: \(amountOutAsset)")
        }

        // Fee details (preferred over deprecated amountFee/amountFeeAsset)
        if let feeDetails = tx.feeDetails {
            print("  feeTotal: \(feeDetails.total)")
            print("  feeAsset: \(feeDetails.asset)")
            if let details = feeDetails.details {
                for detail in details {
                    print("    \(detail.name): \(detail.amount)")
                }
            }
        }

        // Refund information
        if let refunds = tx.refunds {
            print("  refunds.amountRefunded: \(refunds.amountRefunded)")
            print("  refunds.amountFee: \(refunds.amountFee)")
            if let payments = refunds.payments {
                for payment in payments {
                    print("  refund: \(payment.id) (\(payment.idType)) \(payment.amount)")
                }
            }
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

`getTransactions()` signature:
```swift
func getTransactions(request: AnchorTransactionsRequest) async -> AnchorTransactionsResponseEnum
```

Result enum: `AnchorTransactionsResponseEnum`
- `.success(response: AnchorTransactionsResponse)` — `AnchorTransactionsResponse.transactions: [AnchorTransaction]`
- `.failure(error: TransferServerError)`

---

## Single Transaction Status

Query a specific transaction by one of three identifiers.

### AnchorTransactionRequest init

At least one identifier must be provided. Use the designated initializer with named parameters.

```swift
// Query by anchor transaction ID
let request = AnchorTransactionRequest(id: "82fhs729f63dh0v4", jwt: jwtToken)

// Query by Stellar transaction hash
let request2 = AnchorTransactionRequest(
    stellarTransactionId: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
    jwt: jwtToken
)

// Query by external transaction ID
let request3 = AnchorTransactionRequest(externalTransactionId: "1238234", jwt: jwtToken)

// Can combine multiple identifiers; also supports lang
var request4 = AnchorTransactionRequest(id: "82fhs729f63dh0v4")
request4.lang = "en"
request4.jwt = jwtToken
```

`AnchorTransactionRequest.init` signature:
```swift
init(id: String? = nil, stellarTransactionId: String? = nil, externalTransactionId: String? = nil, jwt: String? = nil)
```

```swift
import stellarsdk

let request = AnchorTransactionRequest(id: "82fhs729f63dh0v4", jwt: jwtToken)
let responseEnum = await service.getTransaction(request: request)
switch responseEnum {
case .success(let response):
    let tx = response.transaction  // AnchorTransaction
    print("Status: \(tx.status.rawValue)")
    print("Kind: \(tx.kind.rawValue)")
    // ... access all AnchorTransaction fields (see below)
case .failure(let error):
    print("Error: \(error)")
}
```

`getTransaction()` signature:
```swift
func getTransaction(request: AnchorTransactionRequest) async -> AnchorTransactionResponseEnum
```

Result enum: `AnchorTransactionResponseEnum`
- `.success(response: AnchorTransactionResponse)` — `AnchorTransactionResponse.transaction: AnchorTransaction`
- `.failure(error: TransferServerError)`

### AnchorTransaction — all fields

```swift
let tx = response.transaction  // AnchorTransaction

// Required fields
tx.id                       // String — anchor-generated unique ID
tx.kind                     // AnchorTransactionKind — .deposit, .depositExchange, .withdrawal, .withdrawalExchange
tx.status                   // AnchorTransactionStatus — see Transaction Statuses section
tx.startedAt                // Date? — when the transaction was created

// Optional status / timing
tx.statusEta                // Int? — estimated seconds until status change
tx.moreInfoUrl              // String? — URL for more account/status info
tx.updatedAt                // Date? — when status last changed
tx.completedAt              // Date? — when transaction completed
tx.userActionRequiredBy     // Date? — deadline for user action

// Amount fields (strings with up to 7 decimals)
tx.amountIn                 // String?
tx.amountInAsset            // String? — SEP-38 format; present for exchange transactions
tx.amountOut                // String?
tx.amountOutAsset           // String? — SEP-38 format; present for exchange transactions
tx.amountFee                // String? — deprecated; use feeDetails
tx.amountFeeAsset           // String? — deprecated; use feeDetails

// Fee details (preferred)
tx.feeDetails               // FeeDetails?
//   .total: String — total fee amount
//   .asset: String — SEP-38 asset format
//   .details: [FeeDetailsDetails]? — itemized breakdown
//     .name: String — fee component name
//     .amount: String — fee component amount
//     .description: String? — description

// Quote
tx.quoteId                  // String? — SEP-38 quote ID if used

// Account/address info
tx.from                     // String? — sent-from address (BTC, IBAN, or Stellar G-address)
tx.to                       // String? — sent-to address
tx.externalExtra            // String? — extra info (routing number, BIC, etc.)
tx.externalExtraText        // String? — bank name or store name

// Deposit-specific
tx.depositMemo              // String? — memo used on the Stellar payment to user
tx.depositMemoType          // String?

// Withdrawal-specific
tx.withdrawAnchorAccount    // String? — anchor's Stellar account receiving the payment
tx.withdrawMemo             // String? — memo to use when sending Stellar payment to anchor
tx.withdrawMemoType         // String?

// Stellar/external IDs
tx.stellarTransactionId     // String? — Stellar transaction hash
tx.externalTransactionId    // String? — external system ID

// Status messages
tx.message                  // String? — human-readable status explanation

// Refunds
tx.refunded                 // Bool? — deprecated; use refunds
tx.refunds                  // Refunds?
//   .amountRefunded: String — total refunded in amountInAsset units
//   .amountFee: String — total refund fees
//   .payments: [RefundPayment]?
//     .id: String — Stellar tx hash or external payment ID
//     .idType: String — "stellar" or "external"
//     .amount: String
//     .fee: String

// Pending info update (when status == .pendingTransactionInfoUpdate)
tx.requiredInfoMessage      // String? — human-readable explanation
tx.requiredInfoUpdates      // RequiredInfoUpdates?
//   .fields: [String: AnchorField]? — field names → descriptors

// Deposit instructions
tx.instructions             // [String: DepositInstruction]? — present once pending_user_transfer_start

// Claimable balance
tx.claimableBalanceId       // String? — Claimable Balance ID for deposit (if used)
```

---

## Patch Transaction

When a transaction reaches `pending_transaction_info_update` status, use PATCH to supply the requested fields.

```swift
import stellarsdk

// 1. Check what fields are needed
let txRequest = AnchorTransactionRequest(id: "82fhs729f63dh0v4", jwt: jwtToken)
let txEnum = await service.getTransaction(request: txRequest)
guard case .success(let txResponse) = txEnum else { return }
let tx = txResponse.transaction

if tx.status == .pendingTransactionInfoUpdate {
    if let message = tx.requiredInfoMessage {
        print("Message: \(message)")
    }
    if let fields = tx.requiredInfoUpdates?.fields {
        for (fieldName, field) in fields {
            print("Required: \(fieldName) — \(field.description ?? "")")
        }
    }

    // 2. Build the JSON body with required fields
    let updateFields: [String: String] = [
        "dest": "12345678901234",    // bank account number
        "dest_extra": "021000021",   // routing number
    ]
    guard let body = try? JSONSerialization.data(withJSONObject: updateFields) else { return }

    // 3. Submit the PATCH
    let patchEnum = await service.patchTransaction(
        id: "82fhs729f63dh0v4",
        jwt: jwtToken,
        contentType: "application/json",
        body: body
    )
    switch patchEnum {
    case .success(let response):
        print("Updated status: \(response.transaction.status.rawValue)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

`patchTransaction()` signature:
```swift
func patchTransaction(id: String, jwt: String?, contentType: String, body: Data) async -> AnchorTransactionResponseEnum
```

Returns `AnchorTransactionResponseEnum` — the updated transaction in `.success(response: AnchorTransactionResponse)`.

For multipart form data (e.g., uploading a photo):
```swift
let boundary = "boundary-\(UUID().uuidString)"
// build multipart body...
let patchEnum = await service.patchTransaction(
    id: transactionId,
    jwt: jwtToken,
    contentType: "multipart/form-data; boundary=\(boundary)",
    body: multipartData
)
```

---

## Error Handling

`TransferServerError` covers all SEP-06 failure modes:

```swift
import stellarsdk

let responseEnum = await service.deposit(request: request)
switch responseEnum {
case .success(let response):
    // handle success
case .failure(let error):
    switch error {
    case .authenticationRequired:
        // HTTP 403 with type=authentication_required
        // No JWT or invalid JWT — authenticate via SEP-10 first
        print("Auth required — get a JWT via SEP-10")

    case .informationNeeded(let response):
        // HTTP 403 with type=non_interactive_customer_info_needed or type=customer_info_status
        switch response {
        case .nonInteractive(let info):
            // info: CustomerInformationNeededNonInteractive
            // info.type: String — "non_interactive_customer_info_needed"
            // info.fields: [String] — SEP-12 field names to submit via PUT /customer
            print("KYC required: \(info.fields.joined(separator: ", "))")

        case .status(let info):
            // info: CustomerInformationStatus
            // info.type: String — "customer_info_status"
            // info.status: String — "pending" or "denied"
            // info.moreInfoUrl: String?
            // info.eta: Int? — estimated seconds until status update
            if info.status == "denied" {
                print("KYC denied.")
                if let url = info.moreInfoUrl { print("Details: \(url)") }
            } else {
                print("KYC under review. ETA: \(info.eta.map { "\($0)s" } ?? "unknown")")
            }
        }

    case .anchorError(let message):
        // Anchor returned {"error": "..."} in response body
        // HTTP 400, 404, 500, 429, etc.
        print("Anchor error: \(message)")

    case .parsingResponseFailed(let message):
        // JSON decode failed; usually indicates unexpected server response
        print("Parse error: \(message)")

    case .horizonError(let error):
        // Underlying HTTP error without a parseable anchor error body
        print("HTTP error: \(error)")

    case .invalidDomain:
        print("Invalid domain")

    case .invalidToml:
        print("stellar.toml not found or malformed")

    case .noTransferServerSet:
        print("TRANSFER_SERVER not set in stellar.toml")
    }
}
```

### TransferServerError cases

| Case | When thrown |
|------|-------------|
| `.authenticationRequired` | HTTP 403 with `type=authentication_required` |
| `.informationNeeded(.nonInteractive(info:))` | HTTP 403 with `type=non_interactive_customer_info_needed` |
| `.informationNeeded(.status(info:))` | HTTP 403 with `type=customer_info_status` |
| `.anchorError(message:)` | HTTP error with `{"error": "..."}` body |
| `.parsingResponseFailed(message:)` | JSON decode failure |
| `.horizonError(error:)` | HTTP error without parseable anchor body |
| `.invalidDomain` | Invalid domain URL passed to `forDomain` |
| `.invalidToml` | stellar.toml not found or malformed |
| `.noTransferServerSet` | `TRANSFER_SERVER` missing from stellar.toml |

---

## Transaction Statuses

`AnchorTransactionStatus` enum (use `.rawValue` for the string):

| Case | Raw Value | Meaning |
|------|-----------|---------|
| `.incomplete` | `"incomplete"` | Not yet initiated; user action needed |
| `.pendingUserTransferStart` | `"pending_user_transfer_start"` | Waiting for user to send funds to anchor |
| `.pendingUserTransferComplete` | `"pending_user_transfer_complete"` | User sent funds; anchor processing (withdrawal only) |
| `.pendingExternal` | `"pending_external"` | Waiting on external system (bank, crypto network) |
| `.pendingAnchor` | `"pending_anchor"` | Anchor is processing internally |
| `.pendingStellar` | `"pending_stellar"` | Stellar transaction submitted, not confirmed |
| `.pendingTrust` | `"pending_trust"` | User must add trustline for the asset |
| `.pendingUser` | `"pending_user"` | Waiting for user action (e.g., accept claimable balance) |
| `.pendingCustomerInfoUpdate` | `"pending_customer_info_update"` | Anchor needs more KYC via SEP-12 |
| `.pendingTransactionInfoUpdate` | `"pending_transaction_info_update"` | Anchor needs more transaction info — check `requiredInfoUpdates`, then PATCH |
| `.completed` | `"completed"` | Successfully completed |
| `.refunded` | `"refunded"` | Fully refunded to user |
| `.expired` | `"expired"` | Timed out without completion |
| `.noMarket` | `"no_market"` | No market available for conversion |
| `.tooSmall` | `"too_small"` | Amount below minimum |
| `.tooLarge` | `"too_large"` | Amount exceeds maximum |
| `.error` | `"error"` | Unrecoverable error |

`AnchorTransactionKind` enum:

| Case | Raw Value |
|------|-----------|
| `.deposit` | `"deposit"` |
| `.depositExchange` | `"deposit-exchange"` |
| `.withdrawal` | `"withdrawal"` |
| `.withdrawalExchange` | `"withdrawal-exchange"` |

---

## Common Pitfalls

**WRONG: accessing `WithdrawResponse.accountId` with wrong name**

```swift
// WRONG: no such property named account_id or account
let anchor = response.account_id   // compile error
let anchor = response.account      // compile error

// CORRECT: camelCase property
let anchor = response.accountId    // String?
```

**WRONG: swapping sourceAsset and destinationAsset in WithdrawExchangeRequest**

For `WithdrawExchangeRequest`, `sourceAsset` is the on-chain Stellar asset you send; `destinationAsset` is the off-chain asset you receive (SEP-38 format).

```swift
// WRONG: swapped — this means you'd be sending fiat (that's depositExchange)
let request = WithdrawExchangeRequest(
    sourceAsset: "iso4217:NGN",   // WRONG for withdrawExchange
    destinationAsset: "USDC",
    amount: "100.00",
    type: "bank_account"
)

// CORRECT: sourceAsset is the on-chain Stellar asset
let request = WithdrawExchangeRequest(
    sourceAsset: "USDC",              // on-chain asset to send
    destinationAsset: "iso4217:NGN",  // off-chain asset to receive
    amount: "100.00",
    type: "bank_account",
    jwt: jwtToken
)
```

**WRONG: using amount as Double in DepositRequest/WithdrawRequest**

`amount` on `DepositRequest` and `WithdrawRequest` is `String?`, not `Double`. Only `FeeRequest.amount` is `Double`.

```swift
// WRONG: type mismatch
var request = DepositRequest(assetCode: "USD", account: accountId)
request.amount = 100.0   // compile error: cannot assign Double to String?

// CORRECT: String
request.amount = "100.00"

// NOTE: FeeRequest.amount IS Double — that is different
let feeRequest = FeeRequest(operation: "deposit", assetCode: "USD", amount: 100.0)  // correct
```

**WRONG: setting refundMemo without refundMemoType**

Both fields must be set together. Setting one without the other may be rejected by the anchor.

```swift
// WRONG: only one set
var request = WithdrawRequest(type: "bank_account", assetCode: "USDC")
request.refundMemo = "ref-123"
// missing: request.refundMemoType = "text"

// CORRECT: set both
request.refundMemo = "ref-123"
request.refundMemoType = "text"   // id, text, or hash
```

**WRONG: iterating WithdrawAsset.types as AnchorField directly**

`WithdrawAsset.types` is `[String: WithdrawType]?` — each value is a `WithdrawType` with a `fields` property, not an `AnchorField` directly.

```swift
// WRONG: WithdrawType is not AnchorField
if let types = asset.types {
    for (typeName, field) in types {
        print(field.description)  // compile error: WithdrawType has no description
    }
}

// CORRECT: each value is WithdrawType; fields are inside it
if let types = asset.types {
    for (typeName, withdrawType) in types {
        print("Type: \(typeName)")
        if let fields = withdrawType.fields {
            for (fieldName, field) in fields {  // field is AnchorField
                print("  \(fieldName): \(field.description ?? "")")
            }
        }
    }
}
```

**WRONG: checking info.deposit before nil-check**

`AnchorInfoResponse.deposit` is `[String: DepositAsset]?`. Always nil-check before accessing.

```swift
// WRONG: will crash if no deposit assets returned
for (code, asset) in info.deposit { ... }  // compile error or nil crash

// CORRECT:
if let depositAssets = info.deposit {
    for (code, asset) in depositAssets { ... }
}
// Or for a specific asset:
if let usdAsset = info.deposit?["USD"], usdAsset.enabled { ... }
```

**WRONG: patchTransaction body without encoding as Data**

`patchTransaction` takes raw `Data`. Encode your fields before calling.

```swift
// WRONG: passing dictionary directly
await service.patchTransaction(id: txId, jwt: jwt, contentType: "application/json",
    body: ["dest": "123"])  // compile error: not Data

// CORRECT: encode first
let fields = ["dest": "123456789", "dest_extra": "021000021"]
guard let body = try? JSONSerialization.data(withJSONObject: fields) else { return }
await service.patchTransaction(id: txId, jwt: jwt, contentType: "application/json", body: body)
```

---

## Related SEPs

- [sep.md](sep.md) — All SEP implementations overview
- SEP-01 — Stellar TOML (service discovery, provides `TRANSFER_SERVER`)
- SEP-10 — Web Authentication (required for most SEP-06 operations)
- SEP-12 — KYC API (submit customer info when `.informationNeeded(.nonInteractive)` is returned)
- SEP-24 — Interactive deposits/withdrawals (alternative approach with web popup)
- SEP-38 — Anchor RFQ API (quotes used with deposit-exchange and withdraw-exchange)
