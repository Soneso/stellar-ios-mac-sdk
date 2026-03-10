# SEP-06: Deposit and Withdrawal API

SEP-06 defines a standard protocol for programmatic deposits and withdrawals through anchors. Users send off-chain assets (USD via bank, BTC, etc.) to receive Stellar tokens, or redeem Stellar tokens for off-chain assets.

**Use SEP-06 when:**
- Building automated deposit/withdrawal flows
- Integrating anchor services programmatically without user-facing web flows
- You need direct API access (vs. SEP-24's interactive popup approach)

**Spec:** [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)

## Quick example

This example shows how to authenticate with an anchor via SEP-10 and initiate a deposit request.

```swift
import stellarsdk

// 1. Authenticate with the anchor via SEP-10
let webAuthResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: .testnet)
guard case .success(let webAuth) = webAuthResult else { return }
let userKeyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let jwtResult = await webAuth.jwtToken(forUserAccount: userKeyPair.accountId, signers: [userKeyPair])
guard case .success(let jwtToken) = jwtResult else { return }

// 2. Create transfer service and request deposit
let serviceResult = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = serviceResult else { return }

let request = DepositRequest(assetCode: "USD", account: userKeyPair.accountId, jwt: jwtToken)

let responseEnum = await transferService.deposit(request: request)
switch responseEnum {
case .success(let response):
    print("Deposit instructions: \(response.how)")
    if let feeFixed = response.feeFixed {
        print("Fee: \(feeFixed)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Creating the service

### From domain (recommended)

The SDK discovers the `TRANSFER_SERVER` URL automatically from the anchor's `stellar.toml` file.

```swift
import stellarsdk

// Discovers TRANSFER_SERVER from stellar.toml via SEP-01
// NOTE: forDomain requires a full URL with scheme
let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
switch result {
case .success(let transferService):
    print("Transfer server: \(transferService.transferServiceAddress)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Direct URL

If you already know the transfer server URL, construct the service directly.

```swift
import stellarsdk

let transferService = TransferServerService(serviceAddress: "https://testanchor.stellar.org/sep6")
```

## Querying anchor info

Before initiating deposits or withdrawals, query the info endpoint to discover supported assets, methods, and requirements.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

let infoEnum = await transferService.info()
switch infoEnum {
case .success(let info):
    // Check deposit assets and their limits
    if let depositAssets = info.deposit {
        for (code, asset) in depositAssets {
            print("Deposit \(code): \(asset.enabled ? "enabled" : "disabled")")
            if asset.authenticationRequired == true {
                print("  Authentication required")
            }
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
        }
    }

    // Check withdrawal assets
    if let withdrawAssets = info.withdraw {
        for (code, asset) in withdrawAssets {
            print("Withdraw \(code): \(asset.enabled ? "enabled" : "disabled")")
        }
    }

    // Check deposit-exchange assets (for cross-asset deposits with SEP-38 quotes)
    if let depositExchangeAssets = info.depositExchange {
        for (code, asset) in depositExchangeAssets {
            print("Deposit-Exchange \(code): \(asset.enabled ? "enabled" : "disabled")")
        }
    }

    // Check withdraw-exchange assets (for cross-asset withdrawals with SEP-38 quotes)
    if let withdrawExchangeAssets = info.withdrawExchange {
        for (code, asset) in withdrawExchangeAssets {
            print("Withdraw-Exchange \(code): \(asset.enabled ? "enabled" : "disabled")")
        }
    }

    // Feature flags
    if let features = info.features {
        print("Account creation supported: \(features.accountCreation ? "yes" : "no")")
        print("Claimable balances supported: \(features.claimableBalances ? "yes" : "no")")
    }

    // Check endpoint availability
    print("Fee endpoint enabled: \(info.fee?.enabled == true ? "yes" : "no")")
    print("Transactions endpoint enabled: \(info.transactions?.enabled == true ? "yes" : "no")")
    print("Transaction endpoint enabled: \(info.transaction?.enabled == true ? "yes" : "no")")

case .failure(let error):
    print("Error: \(error)")
}
```

## Deposits

A deposit is when a user sends an external asset (BTC, USD via bank, etc.) to an anchor and receives equivalent Stellar tokens in their account.

### Basic deposit request

Request deposit instructions from the anchor by specifying the asset code and destination Stellar account.

> **Note:** The `account` parameter accepts both regular Stellar accounts (`G...`) and muxed accounts (`M...`).

> **Note:** The `type` parameter corresponds to the SEP-06 `funding_method` concept introduced in v4.3.0. The SDK currently supports `type`; `funding_method` may be added in a future release.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

var request = DepositRequest(
    assetCode: "USD",
    account: "GCQTGZQTVZ...",  // Stellar account to receive tokens (G... or M... for muxed)
    jwt: jwtToken
)
request.type = "bank_account"      // Optional: deposit method (SEPA, SWIFT, etc.)
request.amount = "100.00"          // Optional: helps anchor determine KYC needs

let responseEnum = await transferService.deposit(request: request)
switch responseEnum {
case .success(let response):
    // Display deposit instructions to user
    print("How to deposit: \(response.how)")

    // Structured deposit instructions (preferred over 'how')
    if let instructions = response.instructions {
        for (key, instruction) in instructions {
            print("\(key): \(instruction.value)")
            print("  (\(instruction.description))")
        }
    }

    // Save transaction ID for status tracking
    if let id = response.id {
        print("Transaction ID: \(id)")
    }

    // Fee info
    if let feeFixed = response.feeFixed {
        print("Fixed fee: \(feeFixed)")
    }
    if let feePercent = response.feePercent {
        print("Percent fee: \(feePercent)%")
    }

    // Amount limits
    if let minAmount = response.minAmount {
        print("Minimum deposit: \(minAmount)")
    }
    if let maxAmount = response.maxAmount {
        print("Maximum deposit: \(maxAmount)")
    }

    // Estimated time
    if let eta = response.eta {
        print("Estimated time: \(eta) seconds")
    }

    // Extra info
    if let message = response.extraInfo?.message {
        print("Note: \(message)")
    }

case .failure(let error):
    switch error {
    case .informationNeeded(let response):
        switch response {
        case .nonInteractive(let info):
            // Anchor needs KYC info via SEP-12
            print("Required fields:")
            for field in info.fields {
                print("  - \(field)")
            }
        case .status(let info):
            // KYC submitted but pending/denied
            print("KYC status: \(info.status)")
            if let moreInfoUrl = info.moreInfoUrl {
                print("More info: \(moreInfoUrl)")
            }
        }
    default:
        print("Error: \(error)")
    }
}
```

### Deposit with all options

The `DepositRequest` struct supports optional parameters for different use cases.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

var request = DepositRequest(
    assetCode: "USD",
    account: "GCQTGZQTVZ...",
    jwt: jwtToken
)
request.memoType = "id"                                       // Memo type for Stellar payment (text, id, hash)
request.memo = "12345"                                        // Memo value
request.emailAddress = "user@example.com"                     // For anchor to send updates
request.type = "SEPA"                                         // Deposit method
request.lang = "en"                                           // Response language (RFC 4646)
request.onChangeCallback = "https://wallet.example.com/callback"  // Status update webhook
request.amount = "500.00"                                     // Deposit amount
request.countryCode = "USA"                                   // ISO 3166-1 alpha-3
request.claimableBalanceSupported = "true"                    // Enable claimable balance (pass as String, NOT Bool)
request.customerId = "cust-123"                               // SEP-12 customer ID if known
request.locationId = "loc-456"                                // For cash deposits: pickup location
request.extraFields = ["custom_field": "value"]               // Anchor-specific extra fields

let responseEnum = await transferService.deposit(request: request)
```

## Withdrawals

A withdrawal is when a user redeems Stellar tokens for their off-chain equivalent, such as sending USDC to receive USD in a bank account.

### Basic withdrawal request

Request withdrawal instructions by specifying the asset and withdrawal method.

> **Note:** The `account` parameter accepts both regular Stellar accounts (`G...`) and muxed accounts (`M...`).

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

var request = WithdrawRequest(
    type: "bank_account",      // Withdrawal method: bank_account, cash, crypto, mobile, etc.
    assetCode: "USDC",
    jwt: jwtToken
)
request.account = "GCQTGZQTVZ..."  // Optional: source Stellar account
request.amount = "500.00"          // Optional: withdrawal amount

let responseEnum = await transferService.withdraw(request: request)
switch responseEnum {
case .success(let response):
    // Where to send the Stellar payment
    if let accountId = response.accountId {
        print("Send payment to: \(accountId)")
    }

    // Include memo in the payment
    if let memoType = response.memoType, let memo = response.memo {
        print("Memo (\(memoType)): \(memo)")
    }

    // Save transaction ID for status tracking
    if let id = response.id {
        print("Transaction ID: \(id)")
    }

    // Fee info
    if let feeFixed = response.feeFixed {
        print("Fixed fee: \(feeFixed)")
    }
    if let feePercent = response.feePercent {
        print("Percent fee: \(feePercent)%")
    }

    // Amount limits
    if let minAmount = response.minAmount {
        print("Minimum withdrawal: \(minAmount)")
    }
    if let maxAmount = response.maxAmount {
        print("Maximum withdrawal: \(maxAmount)")
    }

    // Estimated time
    if let eta = response.eta {
        print("Estimated time: \(eta) seconds")
    }

case .failure(let error):
    switch error {
    case .informationNeeded(let response):
        switch response {
        case .nonInteractive(let info):
            print("Need KYC fields: \(info.fields)")
        case .status(let info):
            print("KYC status: \(info.status)")
        }
    default:
        print("Error: \(error)")
    }
}
```

### Withdrawal with all options

The `WithdrawRequest` struct supports parameters for refund handling, memos, and more.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

var request = WithdrawRequest(
    type: "bank_account",
    assetCode: "USDC",
    jwt: jwtToken
)
request.account = "GCQTGZQTVZ..."                             // Source Stellar account
request.lang = "en"                                           // Response language
request.onChangeCallback = "https://wallet.example.com/callback"
request.amount = "1000.00"
request.countryCode = "DEU"
request.refundMemo = "refund-123"                              // Memo for refund payments
request.refundMemoType = "text"                                // Refund memo type
request.customerId = "cust-123"                                // SEP-12 customer ID
request.locationId = "loc-456"                                 // For cash withdrawals: pickup location
request.extraFields = ["bank_name": "Example Bank"]

let responseEnum = await transferService.withdraw(request: request)
```

## Exchange operations (cross-asset)

For deposits or withdrawals with currency conversion (e.g., deposit BRL, receive USDC), use the exchange endpoints. These require anchor support for SEP-38 quotes.

### Deposit exchange

Deposit one asset (e.g., off-chain BRL) and receive a different Stellar asset (e.g., USDC).

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

// Deposit BRL, receive USDC on Stellar
var depositExchange = DepositExchangeRequest(
    destinationAsset: "USDC",               // Stellar asset to receive
    sourceAsset: "iso4217:BRL",             // Off-chain asset being deposited (SEP-38 format)
    amount: "480.00",                       // Amount in source asset
    account: "GCQTGZQTVZ...",              // Stellar account to receive tokens
    jwt: jwtToken
)
depositExchange.quoteId = "282837"          // Optional: SEP-38 quote ID for locked exchange rate
depositExchange.type = "bank_account"       // Deposit method

let responseEnum = await transferService.depositExchange(request: depositExchange)
switch responseEnum {
case .success(let response):
    if let id = response.id {
        print("Transaction ID: \(id)")
    }
    if let instructions = response.instructions {
        for (key, instruction) in instructions {
            print("\(key): \(instruction.value)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Withdraw exchange

Send one Stellar asset (e.g., USDC) and receive a different off-chain asset (e.g., NGN).

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

// Withdraw USDC, receive NGN to bank
var withdrawExchange = WithdrawExchangeRequest(
    sourceAsset: "USDC",                    // Stellar asset to send
    destinationAsset: "iso4217:NGN",        // Off-chain asset to receive (SEP-38 format)
    amount: "100.00",                       // Amount in source asset
    type: "bank_account",                   // Withdrawal method
    jwt: jwtToken
)
withdrawExchange.quoteId = "282838"         // Optional: SEP-38 quote ID for locked exchange rate
withdrawExchange.account = "GCQTGZQTVZ..." // Source Stellar account

let responseEnum = await transferService.withdrawExchange(request: withdrawExchange)
switch responseEnum {
case .success(let response):
    if let id = response.id {
        print("Transaction ID: \(id)")
    }
    if let accountId = response.accountId {
        print("Send to: \(accountId)")
    }
    if let memo = response.memo {
        print("Memo: \(memo)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Checking fees

Query the fee endpoint to calculate fees before initiating transfers.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

// Check if fee endpoint is enabled
let infoEnum = await transferService.info()
guard case .success(let info) = infoEnum, info.fee?.enabled == true else {
    print("Fee endpoint not available")
    return
}

var feeRequest = FeeRequest(
    operation: "deposit",    // "deposit" or "withdraw"
    assetCode: "USD",
    amount: 100.00,          // Note: amount is Double, NOT a String
    jwt: jwtToken
)
feeRequest.type = "bank_account"    // Optional: deposit/withdrawal method

let feeEnum = await transferService.fee(request: feeRequest)
switch feeEnum {
case .success(let feeResponse):
    print("Fee for deposit: \(feeResponse.fee)")
case .failure(let error):
    print("Error: \(error)")
}
```

## Transaction history

List all transactions for an account, with optional filtering by asset, type, and time range.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

var request = AnchorTransactionsRequest(
    assetCode: "USD",
    account: "GCQTGZQTVZ...",
    jwt: jwtToken
)
request.noOlderThan = Date(timeIntervalSinceNow: -30 * 24 * 3600)  // Optional: filter by date
request.limit = 10                               // Optional: max results
request.kind = "deposit"                         // Optional: "deposit" or "withdrawal"
request.pagingId = nil                           // Optional: for pagination
request.lang = "en"                              // Optional: response language

let responseEnum = await transferService.getTransactions(request: request)
switch responseEnum {
case .success(let response):
    for tx in response.transactions {
        print("Transaction: \(tx.id)")
        print("  Kind: \(tx.kind.rawValue)")
        print("  Status: \(tx.status.rawValue)")
        print("  Amount In: \(tx.amountIn ?? "pending")")
        print("  Amount Out: \(tx.amountOut ?? "pending")")
        print("  Started: \(tx.startedAt.map { "\($0)" } ?? "-")")

        // For exchange transactions
        if let amountInAsset = tx.amountInAsset {
            print("  Amount In Asset: \(amountInAsset)")
        }
        if let amountOutAsset = tx.amountOutAsset {
            print("  Amount Out Asset: \(amountOutAsset)")
        }

        // Fee details
        if let feeDetails = tx.feeDetails {
            print("  Total Fee: \(feeDetails.total)")
        } else if let amountFee = tx.amountFee {
            print("  Fee: \(amountFee)")
        }

        // Refund information
        if let refunds = tx.refunds {
            print("  Refunded: \(refunds.amountRefunded)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Single transaction status

Query a specific transaction by ID, Stellar transaction hash, or external transaction ID.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

// Query by anchor transaction ID
let request = AnchorTransactionRequest(id: "82fhs729f63dh0v4", jwt: jwtToken)

let responseEnum = await transferService.getTransaction(request: request)
switch responseEnum {
case .success(let response):
    let tx = response.transaction

    print("Status: \(tx.status.rawValue)")
    print("Kind: \(tx.kind.rawValue)")

    // Check if user action is required by a deadline
    if let userActionRequiredBy = tx.userActionRequiredBy {
        print("Action required by: \(userActionRequiredBy)")
    }

    // For withdrawals, show payment destination
    if let withdrawAnchorAccount = tx.withdrawAnchorAccount {
        print("Send to: \(withdrawAnchorAccount)")
        print("Memo: \(tx.withdrawMemo ?? "") (\(tx.withdrawMemoType ?? ""))")
    }

    // For deposits, show deposit instructions
    if let instructions = tx.instructions {
        for (key, instruction) in instructions {
            print("\(key): \(instruction.value)")
        }
    }

    // Check for claimable balance (deposit)
    if let claimableBalanceId = tx.claimableBalanceId {
        print("Claimable Balance ID: \(claimableBalanceId)")
    }

case .failure(let error):
    print("Error: \(error)")
}

// Also supports lookup by Stellar transaction hash
let request2 = AnchorTransactionRequest(
    stellarTransactionId: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
    jwt: jwtToken
)
let _ = await transferService.getTransaction(request: request2)

// Or by external transaction ID
let request3 = AnchorTransactionRequest(externalTransactionId: "1238234", jwt: jwtToken)
let _ = await transferService.getTransaction(request: request3)
```

## Updating pending transactions

When an anchor requests more info via `pending_transaction_info_update` status, use this endpoint to provide the missing information.

```swift
import stellarsdk

let result = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let transferService) = result else { return }

// First, check what fields are required
let txRequest = AnchorTransactionRequest(id: "82fhs729f63dh0v4", jwt: jwtToken)
let txEnum = await transferService.getTransaction(request: txRequest)
guard case .success(let txResponse) = txEnum else { return }

if txResponse.transaction.status == .pendingTransactionInfoUpdate {
    // Check required fields
    if let fields = txResponse.transaction.requiredInfoUpdates?.fields {
        print("Required updates:")
        for (field, info) in fields {
            print("  - \(field): \(info.description ?? "")")
        }
    }

    if let requiredInfoMessage = txResponse.transaction.requiredInfoMessage {
        print("Message: \(requiredInfoMessage)")
    }

    // Submit the updated information
    let updateFields: [String: String] = [
        "dest": "12345678901234",        // Bank account
        "dest_extra": "021000021",       // Routing number
    ]
    guard let body = try? JSONSerialization.data(withJSONObject: updateFields) else { return }

    let patchEnum = await transferService.patchTransaction(
        id: "82fhs729f63dh0v4",
        jwt: jwtToken,
        contentType: "application/json",
        body: body
    )
    switch patchEnum {
    case .success(let patchResponse):
        print("Updated status: \(patchResponse.transaction.status.rawValue)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Error handling

The SDK returns specific error cases for different error conditions via the `TransferServerError` enum.

```swift
import stellarsdk

let serviceResult = await TransferServerService.forDomain(domain: "https://testanchor.stellar.org")
switch serviceResult {
case .success(let transferService):
    let request = DepositRequest(
        assetCode: "USD",
        account: "GCQTGZQTVZ...",
        jwt: jwtToken
    )

    let responseEnum = await transferService.deposit(request: request)
    switch responseEnum {
    case .success(let response):
        print("How: \(response.how)")

    case .failure(let error):
        switch error {
        case .authenticationRequired:
            // Endpoint requires SEP-10 authentication
            print("Authentication required. Get a JWT token via SEP-10 first.")

        case .informationNeeded(let response):
            switch response {
            case .nonInteractive(let info):
                // Anchor needs KYC info - submit via SEP-12
                print("KYC required. Fields needed:")
                for field in info.fields {
                    print("  - \(field)")
                }
                // Now use SEP-12 to submit the required customer information

            case .status(let info):
                // KYC submitted but has issues
                if info.status == "denied" {
                    print("KYC denied. Contact anchor support.")
                    if let moreInfoUrl = info.moreInfoUrl {
                        print("Details: \(moreInfoUrl)")
                    }
                } else if info.status == "pending" {
                    print("KYC pending review. Try again later.")
                    if let eta = info.eta {
                        print("Estimated wait: \(eta) seconds")
                    }
                }
            }

        case .anchorError(let message):
            print("Anchor error: \(message)")

        case .parsingResponseFailed(let message):
            print("Parse error: \(message)")

        case .horizonError(let horizonError):
            print("HTTP error: \(horizonError)")

        case .invalidDomain:
            print("Invalid domain")

        case .invalidToml:
            print("stellar.toml not found or malformed")

        case .noTransferServerSet:
            print("TRANSFER_SERVER not set in stellar.toml")
        }
    }

case .failure(let error):
    // Domain resolution errors
    print("Error: \(error)")
}
```

### Common error cases

| Error Case | Cause | Solution |
|-----------|-------|----------|
| `.authenticationRequired` | Missing or invalid JWT | Authenticate via SEP-10 first |
| `.informationNeeded(.nonInteractive)` | KYC information required | Submit info via SEP-12 |
| `.informationNeeded(.status)` | KYC pending or denied | Wait for review or contact anchor |
| `.anchorError` | Anchor returned an error message | Check the message for details |
| `.parsingResponseFailed` | Unexpected response format | Verify anchor compatibility |
| `.horizonError` | Network or HTTP error | Check connectivity |

## Transaction statuses

| Status | Meaning |
|--------|---------|
| `incomplete` | Transaction not yet ready, more info needed (non-interactive) |
| `pending_user_transfer_start` | Waiting for user to send funds to anchor |
| `pending_user_transfer_complete` | User sent funds, processing |
| `pending_external` | Waiting on external system (bank, crypto network) |
| `pending_anchor` | Anchor is processing the transaction |
| `pending_stellar` | Stellar transaction pending |
| `pending_trust` | User must add trustline for the asset |
| `pending_customer_info_update` | Anchor needs more KYC info. Use SEP-12 `GET /customer` to find required fields |
| `pending_transaction_info_update` | Anchor needs more transaction info. Query `/transaction` for `requiredInfoUpdates`, then use PATCH |
| `on_hold` | Transaction is on hold (e.g., compliance review) |
| `completed` | Transaction successfully completed |
| `refunded` | Transaction refunded to user |
| `expired` | Transaction timed out without completion |
| `no_market` | No market available for requested conversion |
| `too_small` | Transaction amount below minimum |
| `too_large` | Transaction amount exceeds maximum |
| `error` | Unrecoverable error occurred |

## Complete deposit flow

This example shows a complete deposit flow: authentication, info discovery, deposit initiation, and transaction polling.

```swift
import stellarsdk

let anchorDomain = "testanchor.stellar.org"
let userKeyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

// 1. Authenticate via SEP-10
let webAuthResult = await WebAuthenticator.from(domain: anchorDomain, network: .testnet)
guard case .success(let webAuth) = webAuthResult else { return }
let jwtResult = await webAuth.jwtToken(forUserAccount: userKeyPair.accountId, signers: [userKeyPair])
guard case .success(let jwtToken) = jwtResult else { return }

// 2. Create transfer service and check info
let serviceResult = await TransferServerService.forDomain(domain: "https://\(anchorDomain)")
guard case .success(let transferService) = serviceResult else { return }
let infoEnum = await transferService.info()
guard case .success(let info) = infoEnum else { return }

// Verify deposit is supported for USD
guard let usdDeposit = info.deposit?["USD"], usdDeposit.enabled else {
    print("USD deposits not supported")
    return
}

// 3. Initiate deposit
var transactionId: String?

var depositRequest = DepositRequest(
    assetCode: "USD",
    account: userKeyPair.accountId,
    jwt: jwtToken
)
depositRequest.type = "bank_account"
depositRequest.amount = "100.00"
depositRequest.claimableBalanceSupported = "true"

let depositEnum = await transferService.deposit(request: depositRequest)
switch depositEnum {
case .success(let depositResponse):
    transactionId = depositResponse.id

    print("Deposit initiated. Transaction ID: \(transactionId ?? "")")

    // Display deposit instructions
    if let instructions = depositResponse.instructions {
        print("Deposit instructions:")
        for (key, instruction) in instructions {
            print("  \(key): \(instruction.value)")
        }
    }

case .failure(let error):
    switch error {
    case .informationNeeded(let response):
        switch response {
        case .nonInteractive(let info):
            // Handle KYC requirements via SEP-12
            print("KYC required. Submit via SEP-12: \(info.fields)")
        case .status(let info):
            print("KYC status: \(info.status)")
        }
        return
    default:
        print("Error: \(error)")
        return
    }
}

// 4. Poll for transaction status
guard let txId = transactionId else { return }
let txRequest = AnchorTransactionRequest(id: txId, jwt: jwtToken)

let maxAttempts = 60
var attempt = 0

while attempt < maxAttempts {
    let txEnum = await transferService.getTransaction(request: txRequest)
    guard case .success(let txResponse) = txEnum else { break }
    let status = txResponse.transaction.status

    print("Status: \(status.rawValue)")

    switch status {
    case .completed:
        print("Deposit completed!")
        print("Amount received: \(txResponse.transaction.amountOut ?? "")")
        return

    case .pendingUserTransferStart:
        print("Waiting for off-chain deposit...")

    case .pendingTrust:
        print("Add trustline for the asset")

    case .pendingCustomerInfoUpdate:
        print("Additional KYC required")

    case .error, .expired:
        print("Transaction failed: \(txResponse.transaction.message ?? status.rawValue)")
        return

    default:
        break
    }

    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
    attempt += 1
}
```

## Related SEPs

- [SEP-01](sep-01.md) - Stellar TOML (service discovery)
- [SEP-10](sep-10.md) - Web authentication (required for most operations)
- [SEP-12](sep-12.md) - KYC API (for customer information submission)
- [SEP-24](sep-24.md) - Interactive deposits/withdrawals (alternative approach)
- [SEP-38](sep-38.md) - Quotes API (for exchange operations)

---

[Back to SEP Overview](README.md)
