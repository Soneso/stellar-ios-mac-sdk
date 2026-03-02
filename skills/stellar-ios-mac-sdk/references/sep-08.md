# SEP-08: Regulated Assets

**Purpose:** Handle assets that require issuer approval before transfers (compliance, KYC/AML, securities regulations)
**Prerequisites:** None
**SDK Class:** `RegulatedAssetsService`

## Table of Contents

- [Quick Start](#quick-start)
- [Service Initialization](#service-initialization)
- [Check Authorization Required](#check-authorization-required)
- [Submit Transaction for Approval](#submit-transaction-for-approval)
- [Handle Action Required](#handle-action-required)
- [Full Approval Flow](#full-approval-flow)
- [Response Objects Reference](#response-objects-reference)
- [Error Handling](#error-handling)
- [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```swift
import stellarsdk

// 1. Initialize service from issuer domain
let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://issuer.example.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }

// 2. Build and encode transaction
let txXdr = try transaction.encodedEnvelope()

// 3. Submit to approval server
let asset = service.regulatedAssets[0]
let approvalResult = await service.postTransaction(
    txB64Xdr: txXdr,
    apporvalServer: asset.approvalServer  // NOTE: typo in SDK — "apporvalServer"
)

switch approvalResult {
case .success(let response):
    // Approved — submit the (possibly modified) transaction to Horizon
    let approvedTx = try Transaction(envelopeXdr: response.tx)
    let submitResult = await sdk.transactions.submitTransaction(transaction: approvedTx)
case .revised(let response):
    // Issuer revised the transaction (e.g., added compliance fee)
    let revisedTx = try Transaction(envelopeXdr: response.tx)
    let submitResult = await sdk.transactions.submitTransaction(transaction: revisedTx)
case .pending(let response):
    // Retry after response.timeout seconds
    print("Pending, retry after \(response.timeout)s: \(response.message ?? "")")
case .actionRequired(let response):
    // User must complete action (e.g., KYC) before approval
    print("Action required: \(response.message)")
case .rejected(let response):
    print("Rejected: \(response.error)")
case .failure(let error):
    print("Error: \(error)")
}
```

---

## Service Initialization

### From domain (recommended)

`RegulatedAssetsService.forDomain(domain:network:)` fetches `{domain}/.well-known/stellar.toml`, discovers regulated assets, and creates the service. All assets with `regulated = true` and `approval_server` set are parsed into `service.regulatedAssets`.

```swift
import stellarsdk

let result = await RegulatedAssetsService.forDomain(
    domain: "https://issuer.example.com",
    network: Network.testnet
)

switch result {
case .success(let service):
    print("Network: \(service.network.passphrase)")
    print("Regulated assets: \(service.regulatedAssets.count)")
    for asset in service.regulatedAssets {
        print("  \(asset.assetCode):\(asset.issuerId)")
        print("  Approval server: \(asset.approvalServer)")
        print("  Criteria: \(asset.approvalCriteria ?? "not specified")")
    }
case .failure(let error):
    switch error {
    case .invalidDomain:
        print("Domain string is not a valid URL")
    case .invalidToml:
        print("stellar.toml is missing, unparseable, or missing NETWORK_PASSPHRASE")
    default:
        print("Error: \(error)")
    }
}
```

Method signature:
```swift
static func forDomain(
    domain: String,
    horizonUrl: String? = nil,
    network: Network? = nil
) async -> RegulatedAssetsServiceForDomainEnum
```

- `domain` — must include scheme, e.g. `"https://issuer.example.com"` (not just `"issuer.example.com"`)
- `horizonUrl` — optional override; if nil, uses `HORIZON_URL` from TOML or network default
- `network` — optional override; if nil, derives from `NETWORK_PASSPHRASE` in TOML

### From parsed TOML (when you already have stellar.toml)

```swift
import stellarsdk

let tomlString = """
NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
HORIZON_URL = "https://horizon-testnet.stellar.org"

[[CURRENCIES]]
code = "REG"
issuer = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
regulated = true
approval_server = "https://approval.issuer.example.com"
approval_criteria = "Must pass KYC verification"
"""

let toml = try StellarToml(fromString: tomlString)

// Provide network explicitly:
let service = try RegulatedAssetsService(tomlData: toml, network: Network.testnet)

// Or let it derive network from NETWORK_PASSPHRASE in TOML:
let service = try RegulatedAssetsService(tomlData: toml)
// Throws RegulatedAssetsServiceError.invalidToml if no passphrase and no network given,
// or if using a custom passphrase without HORIZON_URL in TOML.
```

Constructor signature:
```swift
init(tomlData: StellarToml, horizonUrl: String? = nil, network: Network? = nil) throws
```

Public properties on `RegulatedAssetsService`:
- `tomlData: StellarToml` — the parsed stellar.toml
- `network: Network` — the network this service operates on
- `sdk: StellarSDK` — the Horizon SDK instance
- `regulatedAssets: [RegulatedAsset]` — assets discovered from TOML

---

## Check Authorization Required

Before submitting a transaction, verify that the issuer has set `AUTH_REQUIRED` AND `AUTH_REVOCABLE` flags. Both flags must be set for the asset to actually be regulated on-chain.

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://issuer.example.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }
let asset = service.regulatedAssets[0]

let authResult = await service.authorizationRequired(asset: asset)
switch authResult {
case .success(let required):
    if required {
        print("Asset requires authorization — must submit to approval server")
    } else {
        print("Asset does NOT require authorization (flags not set on issuer account)")
    }
case .failure(let error):
    print("Failed to check flags: \(error)")
}
```

Method signature:
```swift
func authorizationRequired(asset: RegulatedAsset) async -> AuthorizationRequiredEnum
```

Returns `true` only when BOTH `auth_required` AND `auth_revocable` are set on the issuer's account. If only one flag is set, returns `false`.

---

## Submit Transaction for Approval

Build a normal Stellar transaction, encode it as XDR, and POST it to the approval server. The server inspects it and returns one of five outcomes.

```swift
import stellarsdk

// 1. Build the transaction (normal Stellar transaction)
let sdk = StellarSDK.testNet()
let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

let issuerKeyPair = try KeyPair(accountId: asset.issuerId)
let regulatedAsset = Asset(
    type: asset.type,
    code: asset.assetCode,
    issuer: issuerKeyPair
)!

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: regulatedAsset,
    amount: Decimal(100)
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)

// 2. Sign with sender key (BEFORE submitting to approval server)
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

// 3. Encode and submit for approval
let txXdr = try transaction.encodedEnvelope()
let result = await service.postTransaction(
    txB64Xdr: txXdr,
    apporvalServer: asset.approvalServer  // NOTE: "apporvalServer" — typo in SDK parameter name
)

switch result {
case .success(let response):
    // Server approved and signed — submit response.tx to Horizon
    let approvedTx = try Transaction(envelopeXdr: response.tx)
    let submitResult = await sdk.transactions.submitTransaction(transaction: approvedTx)
    if case .success(let txResponse) = submitResult {
        print("Submitted! Hash: \(txResponse.transactionHash)")
    }

case .revised(let response):
    // Server modified the transaction (e.g., added compliance operation)
    // response.message explains what changed
    print("Revised: \(response.message)")
    let revisedTx = try Transaction(envelopeXdr: response.tx)
    // Re-sign with your key, then submit
    try revisedTx.sign(keyPair: senderKeyPair, network: Network.testnet)
    let submitResult = await sdk.transactions.submitTransaction(transaction: revisedTx)

case .pending(let response):
    // Server is processing — wait and retry
    print("Pending (retry in \(response.timeout)s): \(response.message ?? "")")
    try await Task.sleep(nanoseconds: UInt64(response.timeout) * 1_000_000_000)
    // Retry postTransaction with the same txXdr

case .actionRequired(let response):
    // User action needed before approval (see Handle Action Required section)
    print("Action required at: \(response.actionUrl)")
    print("Fields needed: \(response.actionFields ?? [])")

case .rejected(let response):
    print("Transaction rejected: \(response.error)")

case .failure(let error):
    print("Request failed: \(error)")
}
```

Method signature:
```swift
func postTransaction(txB64Xdr: String, apporvalServer: String) async -> PostSep08TransactionEnum
```

Note: `apporvalServer` is a typo in the SDK source — use this exact spelling.

---

## Handle Action Required

When `postTransaction` returns `.actionRequired`, the user must provide additional information (e.g., KYC data) before the approval server will process the transaction.

```swift
import stellarsdk

// From the actionRequired response:
// response.message      — human-readable description of what's needed
// response.actionUrl    — URL to POST the action data to
// response.actionMethod — HTTP method, default "GET" (use service.postAction regardless)
// response.actionFields — list of field names to supply (optional)

// Collect user data matching response.actionFields
let actionData: [String: Any] = [
    "email": "user@example.com",
    "kyc_id": "ABC123456"
]

let actionResult = await service.postAction(
    url: response.actionUrl,
    actionFields: actionData
)

switch actionResult {
case .done:
    // No further action needed — retry postTransaction with the original txXdr
    let retryResult = await service.postTransaction(
        txB64Xdr: txXdr,
        apporvalServer: asset.approvalServer
    )
    // handle retryResult...

case .nextUrl(let nextResponse):
    // Multi-step flow — open nextResponse.nextUrl in a browser or webview
    print("Go to: \(nextResponse.nextUrl)")
    print("Message: \(nextResponse.message ?? "")")

case .failure(let error):
    print("Action submission failed: \(error)")
}
```

Method signature:
```swift
func postAction(url: String, actionFields: [String: Any]) async -> PostSep08ActionEnum
```

- `url` — the `actionUrl` from the `Sep08PostTransactionActionRequired` response
- `actionFields` — dictionary of field names and their values

---

## Full Approval Flow

Complete end-to-end example handling all possible server responses with retry logic:

```swift
import stellarsdk

func sendRegulatedPayment(
    service: RegulatedAssetsService,
    senderKeyPair: KeyPair,
    destinationId: String,
    asset: RegulatedAsset,
    amount: Decimal
) async throws {
    let sdk = service.sdk

    // Build transaction
    let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw NSError(domain: "SEP08", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load account"])
    }

    let sourceAccount = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )
    let issuerKeyPair = try KeyPair(accountId: asset.issuerId)
    let regulatedAsset = Asset(type: asset.type, code: asset.assetCode, issuer: issuerKeyPair)!
    let paymentOp = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: destinationId,
        asset: regulatedAsset,
        amount: amount
    )
    let transaction = try Transaction(
        sourceAccount: sourceAccount,
        operations: [paymentOp],
        memo: Memo.none,
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: senderKeyPair, network: service.network)
    let txXdr = try transaction.encodedEnvelope()

    // Submit for approval with retry loop
    var attempts = 0
    while attempts < 5 {
        attempts += 1
        let result = await service.postTransaction(
            txB64Xdr: txXdr,
            apporvalServer: asset.approvalServer
        )

        switch result {
        case .success(let response):
            let approvedTx = try Transaction(envelopeXdr: response.tx)
            let submitResult = await sdk.transactions.submitTransaction(transaction: approvedTx)
            if case .success(let txResponse) = submitResult {
                print("Success! Hash: \(txResponse.transactionHash)")
            }
            return

        case .revised(let response):
            print("Revised: \(response.message)")
            let revisedTx = try Transaction(envelopeXdr: response.tx)
            try revisedTx.sign(keyPair: senderKeyPair, network: service.network)
            let submitResult = await sdk.transactions.submitTransaction(transaction: revisedTx)
            if case .success(let txResponse) = submitResult {
                print("Success (revised)! Hash: \(txResponse.transactionHash)")
            }
            return

        case .pending(let response):
            let waitSeconds = max(response.timeout, 5)
            print("Pending, waiting \(waitSeconds)s...")
            try await Task.sleep(nanoseconds: UInt64(waitSeconds) * 1_000_000_000)
            // loop again

        case .actionRequired(let response):
            print("Action required: \(response.message)")
            // In a real app, prompt the user for data matching response.actionFields
            let actionData: [String: Any] = ["email": "user@example.com"]
            let actionResult = await service.postAction(
                url: response.actionUrl,
                actionFields: actionData
            )
            switch actionResult {
            case .done:
                break  // loop again to retry postTransaction
            case .nextUrl(let nextResponse):
                print("Open URL: \(nextResponse.nextUrl)")
                return  // user must complete web flow
            case .failure(let error):
                throw NSError(domain: "SEP08", code: 2, userInfo: [NSLocalizedDescriptionKey: "Action failed: \(error)"])
            }

        case .rejected(let response):
            throw NSError(domain: "SEP08", code: 3, userInfo: [NSLocalizedDescriptionKey: "Rejected: \(response.error)"])

        case .failure(let error):
            throw NSError(domain: "SEP08", code: 4, userInfo: [NSLocalizedDescriptionKey: "Request failed: \(error)"])
        }
    }
}
```

---

## Response Objects Reference

### RegulatedAsset

Subclass of `Asset`. Discovered from `service.regulatedAssets`.

```swift
public class RegulatedAsset: Asset {
    public let assetCode: String         // e.g. "EURT"
    public let issuerId: String          // issuer G... address
    public let approvalServer: String    // URL of the SEP-08 approval server
    public let approvalCriteria: String? // optional human-readable criteria description
    // Inherits from Asset: .type (Int32), .code (String?), .issuer (KeyPair?)
}
```

Asset type is automatically set: codes ≤ 4 chars → `ASSET_TYPE_CREDIT_ALPHANUM4`, 5–12 chars → `ASSET_TYPE_CREDIT_ALPHANUM12`. Codes longer than 12 chars or missing `approval_server` are silently ignored.

### PostSep08TransactionEnum

Returned by `postTransaction()`:

```swift
public enum PostSep08TransactionEnum {
    case success(response: Sep08PostTransactionSuccess)
    case revised(response: Sep08PostTransactionRevised)
    case pending(response: Sep08PostTransactionPending)
    case actionRequired(response: Sep08PostTransactionActionRequired)
    case rejected(response: Sep08PostTransactionRejected)
    case failure(error: HorizonRequestError)
}
```

### Sep08PostTransactionSuccess

Transaction approved without modifications:

```swift
public struct Sep08PostTransactionSuccess {
    public var tx: String          // base64-encoded XDR of the approved transaction
    public var message: String?    // optional human-readable message
}
```

### Sep08PostTransactionRevised

Transaction approved with modifications (e.g., compliance fee added):

```swift
public struct Sep08PostTransactionRevised {
    public var tx: String       // base64-encoded XDR of the REVISED transaction
    public var message: String  // required — explains what was changed
}
```

### Sep08PostTransactionPending

Approval is processing, retry later:

```swift
public struct Sep08PostTransactionPending {
    public var timeout: Int    // seconds to wait before retrying (defaults to 0 if missing)
    public var message: String? // optional explanation
}
```

### Sep08PostTransactionActionRequired

User must provide additional information:

```swift
public struct Sep08PostTransactionActionRequired {
    public var message: String         // description of what's needed
    public var actionUrl: String       // URL to POST the action data to
    public var actionMethod: String    // HTTP method, defaults to "GET" when not in response
    public var actionFields: [String]? // optional list of field names to supply
}
```

Note: `actionUrl` maps from JSON key `"action_url"`, `actionMethod` from `"action_method"`, `actionFields` from `"action_fields"`.

### Sep08PostTransactionRejected

Transaction rejected permanently:

```swift
public struct Sep08PostTransactionRejected {
    public var error: String  // explanation of why it was rejected
}
```

Note: Servers may return `rejected` with HTTP 400 (bad request) OR HTTP 200. The SDK handles both — either way you get `.rejected`.

### PostSep08ActionEnum

Returned by `postAction()`:

```swift
public enum PostSep08ActionEnum {
    case done                               // no further action needed, retry postTransaction
    case nextUrl(response: Sep08PostActionNextUrl)
    case failure(error: HorizonRequestError)
}
```

### Sep08PostActionNextUrl

Multi-step action flow continues:

```swift
public struct Sep08PostActionNextUrl {
    public var nextUrl: String   // maps from JSON key "next_url"
    public var message: String?  // optional explanation
}
```

---

## Error Handling

### RegulatedAssetsServiceError

Returned by `forDomain()` and thrown by the `init` constructor:

```swift
public enum RegulatedAssetsServiceError: Error {
    case invalidDomain           // domain string could not form a valid URL
    case invalidToml             // TOML fetch failed, parse error, missing NETWORK_PASSPHRASE,
                                 // or custom network without HORIZON_URL
    case parsingResponseFailed(message: String)  // unexpected approval server response
    case badRequest(error: String)
    case notFound(error: String)
    case unauthorized(message: String)
    case horizonError(error: HorizonRequestError)
}
```

`forDomain()` returns `.failure(error: .invalidToml)` for all TOML fetch and parse failures — network errors, 404, malformed content, missing passphrase all map to `invalidToml`.

### HorizonRequestError in postTransaction/postAction

When `.failure(error: HorizonRequestError)` is returned by `postTransaction` or `postAction`:

```swift
let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: asset.approvalServer)
if case .failure(let error) = result {
    switch error {
    case .parsingResponseFailed(let message):
        // Approval server returned an unrecognized status value
        print("Unknown server response: \(message)")
    case .requestFailed(_, let message):
        print("Network error: \(message ?? "unknown")")
    default:
        print("Error: \(error)")
    }
}
```

---

## Common Pitfalls

**`apporvalServer` parameter has a typo — use exactly as written:**

```swift
// WRONG: "approvalServer" — compile error, parameter name doesn't exist
let result = await service.postTransaction(txB64Xdr: txXdr, approvalServer: url)

// CORRECT: "apporvalServer" — matches the SDK source exactly
let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: url)
```

**forDomain requires scheme in the domain string:**

```swift
// WRONG: no scheme — URL constructor fails → .failure(.invalidDomain) or .failure(.invalidToml)
let result = await RegulatedAssetsService.forDomain(domain: "issuer.example.com", network: Network.testnet)

// CORRECT: include https://
let result = await RegulatedAssetsService.forDomain(domain: "https://issuer.example.com", network: Network.testnet)
```

**Assets without approval_server are silently ignored:**

```swift
// stellar.toml with regulated = true but no approval_server → asset is NOT in regulatedAssets
// Check service.regulatedAssets.count before proceeding
guard !service.regulatedAssets.isEmpty else {
    print("No regulated assets found — check that approval_server is set in stellar.toml")
    return
}
```

**Custom network passphrase requires HORIZON_URL in TOML:**

```swift
// WRONG: custom passphrase with no HORIZON_URL and no horizonUrl parameter → throws invalidToml
let toml = try StellarToml(fromString: """
NETWORK_PASSPHRASE = "My Custom Network"
""")
let service = try RegulatedAssetsService(tomlData: toml)  // throws!

// CORRECT: provide horizonUrl when using a custom network passphrase
let service = try RegulatedAssetsService(
    tomlData: toml,
    horizonUrl: "https://my-horizon.example.com"
)
// OR: provide network explicitly and include HORIZON_URL in TOML
```

**Revised transactions need re-signing before submission:**

```swift
// WRONG: submitting revised.tx directly (server signed it but your signature may no longer be valid)
// CORRECT: after revision, re-sign with your key:
case .revised(let response):
    let revisedTx = try Transaction(envelopeXdr: response.tx)
    try revisedTx.sign(keyPair: senderKeyPair, network: service.network)
    let submitResult = await sdk.transactions.submitTransaction(transaction: revisedTx)
```

**authorizationRequired requires BOTH flags:**

```swift
// Returns false if ONLY auth_required is set (without auth_revocable)
// Returns false if ONLY auth_revocable is set (without auth_required)
// Returns true ONLY when BOTH auth_required AND auth_revocable are set on the issuer account
let authResult = await service.authorizationRequired(asset: asset)
// Use this to guard against submitting to the approval server unnecessarily
```

**`Sep08PostTransactionActionRequired.actionMethod` defaults to "GET" when absent:**

```swift
// The SDK default is "GET", but the SEP-08 spec typically uses "POST" for action submissions.
// The SDK's postAction() method always uses POST regardless of actionMethod.
// Use service.postAction() rather than building your own request from actionMethod.
case .actionRequired(let response):
    let actionResult = await service.postAction(
        url: response.actionUrl,
        actionFields: collectedData
    )
```
