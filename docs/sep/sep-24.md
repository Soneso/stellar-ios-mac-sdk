# SEP-24: Interactive Deposit and Withdrawal

SEP-24 defines how to move money between traditional financial systems and the Stellar network. The anchor hosts a web interface where users complete the deposit or withdrawal process—the web UI handles KYC and payment method selection.

Use SEP-24 when:
- You want to deposit fiat currency (USD, EUR, etc.) to receive Stellar tokens
- You want to withdraw Stellar tokens back to a bank account or other payment method
- The anchor needs to collect information interactively from the user
- You're building a wallet that integrates with regulated on/off ramps

See the [SEP-24 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md) for protocol details.

## Quick example

This example shows how to start a deposit flow. The anchor returns a URL where users complete the deposit process interactively:

```swift
import stellarsdk

// Create service from anchor's domain
let serviceResult = await InteractiveService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let service) = serviceResult else { return }

// Start a deposit flow (requires JWT token from SEP-10 or SEP-45)
var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

let result = await service.deposit(request: request)
switch result {
case .success(let response):
    // Open this URL in a browser or webview for the user
    let interactiveUrl = response.url
    let transactionId = response.id

    print("Open: \(interactiveUrl)")
    print("Transaction ID: \(transactionId)")
case .failure(let error):
    print("Deposit failed: \(error)")
}
```

## Creating the interactive service

The `InteractiveService` class provides all SEP-24 operations. Create it from an anchor's domain (which discovers the transfer server URL from stellar.toml) or provide a direct URL.

**From an anchor's domain** (recommended):

```swift
import stellarsdk

// Loads the TRANSFER_SERVER_SEP0024 URL from stellar.toml
let serviceResult = await InteractiveService.forDomain(domain: "https://testanchor.stellar.org")
switch serviceResult {
case .success(let service):
    // service is ready to use
    print("Service URL: \(service.serviceAddress)")
case .failure(let error):
    print("Init failed: \(error)")
}
```

**From a direct URL**:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")
```

> **Note:** The iOS/macOS SDK does not support custom HTTP clients or request headers for `InteractiveService`. If you need custom networking behavior, configure `URLSession` or `URLProtocol` at the application level.

## Getting anchor information

Before starting a deposit or withdrawal, query the `/info` endpoint to see what assets the anchor supports and their fee structures:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// Get anchor info (optionally specify language code like "de" for German)
let infoResult = await service.info(language: "en")

switch infoResult {
case .success(let info):
    // Check supported deposit assets
    if let depositAssets = info.depositAssets {
        for (code, asset) in depositAssets {
            print("Deposit: \(code)")
            print("  Enabled: \(asset.enabled ? "Yes" : "No")")
            if let minAmount = asset.minAmount {
                print("  Min: \(minAmount)")
            }
            if let maxAmount = asset.maxAmount {
                print("  Max: \(maxAmount)")
            }
            if let feeFixed = asset.feeFixed {
                print("  Fixed fee: \(feeFixed)")
            }
            if let feePercent = asset.feePercent {
                print("  Percent fee: \(feePercent)%")
            }
            if let feeMinimum = asset.feeMinimum {
                print("  Minimum fee: \(feeMinimum)")
            }
        }
    }

    // Check supported withdrawal assets
    let withdrawAssets = info.withdrawAssets

    // Check feature support (claimable balances, account creation)
    if let flags = info.featureFlags {
        print("Account creation supported: \(flags.accountCreation ? "Yes" : "No")")
        print("Claimable balances supported: \(flags.claimableBalances ? "Yes" : "No")")
    }

    // Check if the deprecated fee endpoint is available
    if let feeInfo = info.feeEndpointInfo, feeInfo.enabled {
        print("Fee endpoint is available")
        print("Requires authentication: \(feeInfo.authenticationRequired ? "Yes" : "No")")
    }
case .failure(let error):
    print("Info failed: \(error)")
}
```

## Deposit flow

A deposit converts external funds (bank transfer, card, crypto from another chain) into Stellar tokens sent to your account. The user provides payment details through the anchor's web interface and completes KYC if required.

### Basic deposit

Start a deposit by specifying the asset you want to receive. The anchor returns a URL to open in a browser or webview:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

let result = await service.deposit(request: request)
switch result {
case .success(let response):
    // Show the interactive URL to your user
    let url = response.url
    let transactionId = response.id

    // The user completes the deposit in their browser
    // Then poll for status updates (see "Tracking Transactions" below)
    print("Open: \(url)")
case .failure(let error):
    print("Deposit failed: \(error)")
}
```

### Deposit with amount and account options

You can specify an amount, destination account (if different from the authenticated account), and memo for the deposit:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
request.amount = "100.0"
// Receive tokens on a different account than the one used for authentication
request.account = "GXXXXXXX..."
request.memo = "12345"
request.memoType = "id" // "text", "id", or "hash"
// Language for the interactive UI (RFC 4646 format)
request.lang = "en-US"

let result = await service.deposit(request: request)
```

### Deposit with asset issuer

When the anchor supports multiple issuers for the same asset code, specify which issuer you want:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
request.assetIssuer = "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"

let result = await service.deposit(request: request)
```

### Deposit with SEP-38 quote

For cross-asset deposits (deposit EUR to receive USDC), use a SEP-38 quote to lock in an exchange rate:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// First, get a quote from SEP-38 (see SEP-38 documentation)
let quoteId = "quote-abc-123"

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USDC")
request.quoteId = quoteId
request.sourceAsset = "iso4217:EUR" // Depositing EUR, receiving USDC tokens
request.amount = "100.0" // Must match the quote's sell_amount

let result = await service.deposit(request: request)
```

### Pre-filling KYC data

Provide KYC data upfront to pre-fill the anchor's form:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

// Provide personal KYC information (SEP-9 natural person fields)
request.kycFields = [
    KYCNaturalPersonFieldsEnum.firstName("Jane"),
    KYCNaturalPersonFieldsEnum.lastName("Doe"),
    KYCNaturalPersonFieldsEnum.emailAddress("jane@example.com"),
    KYCNaturalPersonFieldsEnum.mobileNumber("+1234567890"),
]

let result = await service.deposit(request: request)
// The anchor will pre-fill these fields in the interactive form
```

### Pre-filling organization KYC data

For business accounts, provide organization KYC fields:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

// Organization KYC information (SEP-9 organization fields)
request.kycOrganizationFields = [
    KYCOrganizationFieldsEnum.name("Acme Corporation"),
    KYCOrganizationFieldsEnum.registeredAddress("123 Business St, Suite 100"),
    KYCOrganizationFieldsEnum.email("contact@acme.com"),
]

let result = await service.deposit(request: request)
```

### Custom fields and files

For anchor-specific KYC requirements not covered by standard SEP-9 fields, use custom fields and files:

```swift
import Foundation
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
// Custom text fields
request.customFields = [
    "employer_name": "Tech Corp",
    "occupation": "Software Engineer",
]
// Custom file uploads (binary content)
request.customFiles = [
    "proof_of_income": Data(/* file bytes */),
]

let result = await service.deposit(request: request)
```

### Deposit with claimable balance support

If your account doesn't have a trustline for the asset, request that the anchor use claimable balances:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
request.claimableBalanceSupported = "true"

let result = await service.deposit(request: request)
// The anchor may create a claimable balance instead of a direct payment
// Check the transaction's claimableBalanceId field after completion
```

### Deposit native XLM

To deposit and receive native XLM (lumens), use the special `native` asset code:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "native")
// Do not set assetIssuer for native assets

let result = await service.deposit(request: request)
```

## Withdrawal flow

A withdrawal converts Stellar tokens into external funds sent to a bank account, card, or other destination. The user completes the anchor's interactive flow, then sends tokens to the anchor's Stellar account.

### Basic withdrawal

Start a withdrawal by specifying the asset you want to withdraw:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")

let result = await service.withdraw(request: request)
switch result {
case .success(let response):
    // Show the interactive URL to your user
    let url = response.url
    let transactionId = response.id

    // After completing the form, poll for status to get withdrawal instructions
    // When status is "pending_user_transfer_start", send the Stellar payment
    print("Open: \(url)")
case .failure(let error):
    print("Withdraw failed: \(error)")
}
```

### Withdrawal with options

Specify additional options like amount, source account, and language:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
request.amount = "500.0"
// Specify which Stellar account will send the withdrawal payment
request.account = "GXXXXXXX..."
// Language for the interactive UI
request.lang = "de" // German

let result = await service.withdraw(request: request)
```

### Withdrawal with refund memo

Specify a memo for refunds if the withdrawal fails or is cancelled:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
request.amount = "500.0"
// Memo for refund payments
request.refundMemo = "refund-123"
request.refundMemoType = "text" // "text", "id", or "hash"

let result = await service.withdraw(request: request)
```

### Withdrawal with SEP-38 quote (asset exchange)

For cross-asset withdrawals (send USDC, receive EUR in bank), use a SEP-38 quote:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// First, get a quote from SEP-38 (see SEP-38 documentation)
let quoteId = "quote-xyz-789"

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USDC")
request.quoteId = quoteId
request.destinationAsset = "iso4217:EUR" // Sending USDC, receiving EUR
request.amount = "500.0" // Must match the quote's sell_amount

let result = await service.withdraw(request: request)
```

### Withdrawal with KYC data

Pre-fill KYC data for the withdrawal form:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")

// Natural person KYC fields
request.kycFields = [
    KYCNaturalPersonFieldsEnum.firstName("John"),
    KYCNaturalPersonFieldsEnum.lastName("Smith"),
    KYCNaturalPersonFieldsEnum.emailAddress("john@example.com"),
]

// Financial account KYC fields (bank details)
request.kycFinancialAccountFields = [
    KYCFinancialAccountFieldsEnum.bankAccountNumber("123456789"),
    KYCFinancialAccountFieldsEnum.bankNumber("987654321"),
]

let result = await service.withdraw(request: request)
```

### Completing a withdrawal payment

After the user completes the interactive flow, poll the transaction endpoint to get payment instructions. When the status is `pending_user_transfer_start`, send the Stellar payment:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// Poll for transaction status
var txRequest = Sep24TransactionRequest(jwt: jwtToken)
txRequest.id = transactionId

let txResult = await service.getTransaction(request: txRequest)
guard case .success(let txResponse) = txResult else { return }
let tx = txResponse.transaction

if tx.status == "pending_user_transfer_start",
   let withdrawAccount = tx.withdrawAnchorAccount,
   let withdrawMemo = tx.withdrawMemo,
   let amountIn = tx.amountIn {

    // Build and submit the payment transaction
    let sdk = StellarSDK.testNet()
    let sourceKeyPair = try KeyPair(secretSeed: "SXXXXX...")
    let accountResult = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
    guard case .success(let accountResponse) = accountResult else { return }

    let issuerKeyPair = try KeyPair(accountId: "ISSUER_ACCOUNT_ID")
    let asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
    guard let amount = Decimal(string: amountIn) else { return }

    let paymentOp = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: withdrawAccount,
        asset: asset,
        amount: amount
    )

    let withdrawMemoType = tx.withdrawMemoType ?? "text"
    let memo: Memo
    switch withdrawMemoType {
    case "id": memo = Memo.id(UInt64(withdrawMemo) ?? 0)
    case "hash":
        let data = Data(base64Encoded: withdrawMemo) ?? Data()
        memo = try Memo.hash(data)
    default: memo = Memo.text(withdrawMemo)
    }

    let sourceAccount = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )
    let transaction = try Transaction(
        sourceAccount: sourceAccount,
        operations: [paymentOp],
        memo: memo,
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)
    let _ = await sdk.transactions.submitTransaction(transaction: transaction)
}
```

## Tracking transactions

After starting a deposit or withdrawal, poll the anchor for status updates. The SDK provides methods to query single transactions or list multiple transactions.

### Get a single transaction by ID

Query a specific transaction using its anchor-generated ID:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = transactionId // From deposit/withdraw response

let result = await service.getTransaction(request: request)
switch result {
case .success(let response):
    let tx = response.transaction

    print("ID: \(tx.id)")
    print("Kind: \(tx.kind)")
    print("Status: \(tx.status)")
    print("Started: \(tx.startedAt)")

    if let amountIn = tx.amountIn {
        print("Amount in: \(amountIn)")
    }
    if let amountOut = tx.amountOut {
        print("Amount out: \(amountOut)")
    }
    if let amountFee = tx.amountFee {
        print("Fee: \(amountFee)")
    }
    if let message = tx.message {
        print("Message: \(message)")
    }
    if let moreInfoUrl = tx.moreInfoUrl {
        print("More info: \(moreInfoUrl)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Get transaction by Stellar transaction ID

Look up a transaction using its Stellar network transaction hash:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24TransactionRequest(jwt: jwtToken)
request.stellarTransactionId = "abc123def456..." // Stellar transaction hash

let result = await service.getTransaction(request: request)
```

### Get transaction by external transaction ID

Look up a transaction using an external reference (e.g., bank transfer reference):

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24TransactionRequest(jwt: jwtToken)
request.externalTransactionId = "BANK-REF-123456"

let result = await service.getTransaction(request: request)
```

### Get transaction history

Query multiple transactions with filtering and pagination:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "USD")
request.limit = 10
request.kind = "deposit" // or "withdrawal", or omit for both
// Only transactions after this date
request.noOlderThan = Date(timeIntervalSince1970: 1704067200) // 2024-01-01
// Language for localized responses
request.lang = "en"

let result = await service.getTransactions(request: request)
switch result {
case .success(let response):
    for tx in response.transactions {
        var line = "\(tx.id): \(tx.kind) - \(tx.status)"
        if let amountIn = tx.amountIn {
            line += " - \(amountIn)"
        }
        print(line)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Pagination with paging ID

For paginating through large transaction lists:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// First page
var request = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "USD")
request.limit = 10

let result = await service.getTransactions(request: request)
switch result {
case .success(let response):
    let transactions = response.transactions

    // Get next page using the last transaction's ID
    if let lastTx = transactions.last {
        let lastId = lastTx.id

        var nextRequest = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "USD")
        nextRequest.pagingId = lastId
        let _ = await service.getTransactions(request: nextRequest)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Transaction object details

The `Sep24Transaction` object contains detailed information about a transaction. Here are the key fields:

### Common fields (all transactions)

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique anchor-generated transaction ID |
| `kind` | `String` | `deposit` or `withdrawal` |
| `status` | `String` | Current status (see status table below) |
| `statusEta` | `Int?` | Estimated seconds until next status change |
| `kycVerified` | `Bool?` | Whether anchor verified user's KYC for this transaction |
| `moreInfoUrl` | `String?` | URL with additional transaction details |
| `amountIn` | `String?` | Amount received by anchor |
| `amountInAsset` | `String?` | Asset received (SEP-38 format) |
| `amountOut` | `String?` | Amount sent to user |
| `amountOutAsset` | `String?` | Asset sent (SEP-38 format) |
| `amountFee` | `String?` | Fee charged by anchor |
| `amountFeeAsset` | `String?` | Asset for fee calculation |
| `quoteId` | `String?` | SEP-38 quote ID if used |
| `startedAt` | `Date` | Transaction start time |
| `completedAt` | `Date?` | Completion time |
| `updatedAt` | `Date?` | Last update time |
| `userActionRequiredBy` | `Date?` | Deadline for user action |
| `stellarTransactionId` | `String?` | Stellar transaction hash |
| `externalTransactionId` | `String?` | External system transaction ID |
| `message` | `String?` | Human-readable status explanation |
| `from` | `String?` | Source address/account |
| `to` | `String?` | Destination address/account |

### Deposit-specific fields

| Field | Type | Description |
|-------|------|-------------|
| `depositMemo` | `String?` | Memo used in the deposit payment |
| `depositMemoType` | `String?` | Memo type (`text`, `id`, `hash`) |
| `claimableBalanceId` | `String?` | Claimable balance ID if used |

### Withdrawal-specific fields

| Field | Type | Description |
|-------|------|-------------|
| `withdrawAnchorAccount` | `String?` | Anchor's Stellar account to send payment to |
| `withdrawMemo` | `String?` | Memo to include in the payment |
| `withdrawMemoType` | `String?` | Memo type (`text`, `id`, `hash`) |

### Reading transaction fields

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = transactionId

let result = await service.getTransaction(request: request)
guard case .success(let response) = result else { return }
let tx = response.transaction

// Check if KYC is verified
if tx.kycVerified == true {
    print("KYC verified for this transaction")
}

// Check for user action deadline
if let userActionBy = tx.userActionRequiredBy {
    print("Action required by: \(userActionBy)")
}

// For deposits, check for claimable balance
if tx.kind == "deposit", let claimableBalanceId = tx.claimableBalanceId {
    print("Claim balance: \(claimableBalanceId)")
}

// For withdrawals in pending_user_transfer_start status
if tx.kind == "withdrawal" && tx.status == "pending_user_transfer_start" {
    if let anchorAccount = tx.withdrawAnchorAccount,
       let memo = tx.withdrawMemo {
        print("Send \(tx.amountIn ?? "?") to \(anchorAccount)")
        print("With memo: \(memo) (\(tx.withdrawMemoType ?? "text"))")
    }
}
```

## Transaction statuses

The `status` field indicates the current state of the transaction:

| Status | Description |
|--------|-------------|
| `incomplete` | User hasn't completed the interactive flow yet |
| `pending_user_transfer_start` | Waiting for user to send funds to anchor |
| `pending_user_transfer_complete` | Stellar payment received, off-chain funds ready for pickup |
| `pending_external` | Waiting for external network confirmation (bank, crypto) |
| `pending_anchor` | Anchor is processing the transaction |
| `on_hold` | Transaction on hold pending compliance review |
| `pending_stellar` | Waiting for Stellar network transaction confirmation |
| `pending_trust` | User needs to add a trustline for the asset |
| `pending_user` | User action required (see message or more_info_url) |
| `completed` | Transaction finished successfully |
| `refunded` | Transaction was refunded (see refunds object) |
| `expired` | Transaction expired before completion |
| `no_market` | No market available for the asset exchange |
| `too_small` | Amount below minimum threshold |
| `too_large` | Amount above maximum threshold |
| `error` | Transaction failed due to an error |

## Handling refunds

When a transaction is refunded, check the `refunds` object for details:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var request = Sep24TransactionRequest(jwt: jwtToken)
request.id = transactionId

let result = await service.getTransaction(request: request)
guard case .success(let response) = result else { return }
let tx = response.transaction

if tx.status == "refunded", let refunds = tx.refunds {
    print("Total refunded: \(refunds.amountRefunded)")
    print("Refund fees: \(refunds.amountFee)")

    // Individual refund payments
    if let payments = refunds.payments {
        for payment in payments {
            print("Payment ID: \(payment.id)")
            print("Type: \(payment.idType)") // "stellar" or "external"
            print("Amount: \(payment.amount)")
            print("Fee: \(payment.fee)")
        }
    }
}
```

## Error handling

The SDK returns result enums with `.failure(error: InteractiveServiceError)` for different error scenarios:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

var depositRequest = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

let result = await service.deposit(request: depositRequest)
switch result {
case .success(let response):
    print("Interactive URL: \(response.url)")
case .failure(let error):
    switch error {
    case .authenticationRequired:
        // HTTP 403: JWT token is invalid, expired, or missing
        // Re-authenticate with SEP-10 or SEP-45 and retry
        print("Authentication required")
    case .anchorError(let message):
        // HTTP 400 or other error: Invalid parameters, unsupported asset, etc.
        // Check the error message for details from the anchor
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

// For transaction queries, handle the not-found case
var txRequest = Sep24TransactionRequest(jwt: jwtToken)
txRequest.id = "invalid-or-unknown-id"

let txResult = await service.getTransaction(request: txRequest)
switch txResult {
case .success(let response):
    print("Transaction: \(response.transaction.id)")
case .failure(let error):
    switch error {
    case .notFound(let message):
        // HTTP 404: Transaction doesn't exist or doesn't belong to this user
        print("Transaction not found: \(message ?? "unknown")")
    case .authenticationRequired:
        print("Need to re-authenticate")
    case .anchorError(let message):
        print("Error: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

## Fee information (deprecated)

The `/fee` endpoint is deprecated in favor of SEP-38. For anchors that still support it:

```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")

// Check if fee endpoint is available
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
    type: "bank_account",
    assetCode: "USD",
    amount: 1000.0,
    jwt: jwtIfRequired
)

let feeResult = await service.fee(request: feeRequest)
switch feeResult {
case .success(let feeResponse):
    print("Fee for $1000 deposit: $\(feeResponse.fee)")
case .failure(let error):
    print("Fee request failed: \(error)")
}
```

> **Note:** New integrations should use [SEP-38](sep-38.md) `/price` endpoint for fee and exchange rate information.

## Polling strategy

When monitoring transactions, use exponential backoff to avoid hammering the server:

```swift
import Foundation
import stellarsdk

func pollTransaction(
    service: InteractiveService,
    jwt: String,
    transactionId: String,
    terminalStatuses: Set<String> = ["completed", "refunded", "expired", "error"]
) async -> Sep24Transaction? {
    var request = Sep24TransactionRequest(jwt: jwt)
    request.id = transactionId

    var attempts = 0
    let maxAttempts = 60
    let baseDelay = 2 // seconds

    while attempts < maxAttempts {
        let result = await service.getTransaction(request: request)
        guard case .success(let response) = result else { break }
        let tx = response.transaction

        print("Status: \(tx.status)")

        if terminalStatuses.contains(tx.status) {
            return tx
        }

        // Use statusEta if provided, otherwise exponential backoff
        let delay: UInt64
        if let eta = tx.statusEta, eta > 0 {
            delay = UInt64(min(eta, 60)) * 1_000_000_000
        } else {
            delay = UInt64(min(baseDelay * (1 << attempts), 60)) * 1_000_000_000
        }

        try? await Task.sleep(nanoseconds: delay)
        attempts += 1
    }

    return nil // Timeout
}

// Usage:
// let completedTx = await pollTransaction(
//     service: service, jwt: jwtToken, transactionId: transactionId
// )
// if let completedTx = completedTx {
//     print("Transaction completed with status: \(completedTx.status)")
// }
```

## Related specifications

- [SEP-1](sep-01.md) - stellar.toml (where `TRANSFER_SERVER_SEP0024` is published)
- [SEP-10](sep-10.md) - Web Authentication for traditional accounts (G... addresses)
- [SEP-45](sep-45.md) - Web Authentication for Contract Accounts (C... addresses)
- [SEP-12](sep-12.md) - KYC API (often used alongside SEP-24)
- [SEP-38](sep-38.md) - Anchor RFQ API (quotes for exchange rates)
- [SEP-6](sep-06.md) - Programmatic Deposit/Withdrawal (non-interactive alternative)

## Further reading

- [SDK test cases](https://github.com/nicorescu/stellar-ios-mac-sdk/tree/master/stellarsdk/stellarsdkUnitTests/sep/interactive) - examples covering deposits, withdrawals, transaction queries, and error handling

---

[Back to SEP Overview](README.md)
