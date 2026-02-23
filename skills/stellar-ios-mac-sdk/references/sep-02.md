# SEP-02: Federation Protocol

**Purpose:** Resolve `user*domain.com` Stellar addresses to account IDs and optional memo data for payments.
**Prerequisites:** None (for forward lookup via `Federation.resolve(stellarAddress:)`); federation server URL (for reverse/txid/forward lookups).
**SDK Class:** `Federation` (in `stellarsdk`)

## Table of Contents

- [How It Works](#how-it-works)
- [Quick Example](#quick-example)
- [Federation.resolve(stellarAddress:) — Static Forward Lookup](#federationresolvestellaraddress--static-forward-lookup)
- [Federation.forDomain() — Discover Server from stellar.toml](#federationfordomain--discover-server-from-stellartoml)
- [federation.resolve(address:) — Instance Forward Lookup](#federationresolveaddress--instance-forward-lookup)
- [federation.resolve(account_id:) — Reverse Lookup](#federationresolveaccount_id--reverse-lookup)
- [federation.resolve(transaction_id:) — Transaction Lookup](#federationresolvetransaction_id--transaction-lookup)
- [federation.resolve(forwardParams:) — Forward Lookup](#federationresolveforwardparams--forward-lookup)
- [ResolveAddressResponse Properties](#resolveaddressresponse-properties)
- [Building a Payment with Federation](#building-a-payment-with-federation)
- [Error Handling](#error-handling)
- [Common Pitfalls](#common-pitfalls)

## How It Works

A Stellar address has two parts: `username*domain.com`

When you call `Federation.resolve(stellarAddress: "bob*example.com")`, the SDK:
1. Splits on `*` to get username (`bob`) and domain (`example.com`)
2. Fetches `https://example.com/.well-known/stellar.toml`
3. Reads the `FEDERATION_SERVER` URL from the TOML
4. Makes `GET FEDERATION_SERVER?q=bob*example.com&type=name`
5. Returns a `ResolveAddressResponse` with the account ID and optional memo

The static `Federation.resolve(stellarAddress:)` handles the entire flow. For reverse, txid, or forward lookups you must create a `Federation` instance with the server URL directly.

## Quick Example

```swift
import stellarsdk

// Resolve a Stellar address — auto-discovers the federation server
let result = await Federation.resolve(stellarAddress: "bob*soneso.com")

switch result {
case .success(let response):
    print("Account ID:  \(response.accountId ?? "nil")")      // GBVPKXWMAB3...
    print("Stellar addr: \(response.stellarAddress ?? "nil")") // bob*soneso.com
    print("Memo type:   \(response.memoType ?? "none")")       // text
    print("Memo:        \(response.memo ?? "none")")           // hello memo text
case .failure(let error):
    print("Resolution failed: \(error)")
}
```

## Federation.resolve(stellarAddress:) — Static Forward Lookup

```swift
public static func resolve(stellarAddress: String, secure: Bool = true) async -> ResolveResponseEnum
```

Resolves a Stellar address to its federation record. Fetches `stellar.toml` automatically to discover the federation server. Returns `ResolveResponseEnum` (`.success(response:)` / `.failure(error:)`).

- `stellarAddress`: Address in `user*domain.com` format — must contain exactly one `*`
- `secure`: If `true` (default), fetches `stellar.toml` over HTTPS

```swift
import stellarsdk

let result = await Federation.resolve(stellarAddress: "alice*testanchor.stellar.org")
switch result {
case .success(let response):
    let destination = response.accountId    // Use for payment destination
    let memoType    = response.memoType     // "text", "id", "hash", or nil
    let memo        = response.memo         // Value to attach, or nil
case .failure(let error):
    print("Error: \(error)")
}
```

**Address validation:** The SDK validates the address format before making any network calls. An address without exactly one `*` returns `.failure(error: .invalidAddress)` immediately.

## Federation.forDomain() — Discover Server from stellar.toml

```swift
public static func forDomain(domain: String, secure: Bool = true) async -> FederationForDomainEnum
```

Discovers the federation server for a domain by fetching its `stellar.toml`. Returns `FederationForDomainEnum` (`.success(response: Federation)` / `.failure(error: FederationError)`). The returned `Federation` instance has `federationAddress` set to the server URL.

```swift
import stellarsdk

let domainResult = await Federation.forDomain(domain: "soneso.com")
switch domainResult {
case .success(let federation):
    // federation.federationAddress holds the FEDERATION_SERVER URL
    print("Server: \(federation.federationAddress)")
    // Now use the instance to do lookups
    let lookupResult = await federation.resolve(account_id: "GBVPKXWMAB3...")
case .failure(let error):
    print("No federation server: \(error)")
}
```

## federation.resolve(address:) — Instance Forward Lookup

```swift
public func resolve(address: String) async -> ResolveResponseEnum
```

Forward lookup using a `Federation` instance you have already created (e.g., from `Federation(federationAddress:)` or `Federation.forDomain()`). Sends `type=name` to the federation server.

```swift
import stellarsdk

let federation = Federation(federationAddress: "https://stellarid.io/federation")
let result = await federation.resolve(address: "bob*soneso.com")
switch result {
case .success(let response):
    print("Account: \(response.accountId ?? "nil")")
case .failure(let error):
    print("Error: \(error)")
}
```

## federation.resolve(account_id:) — Reverse Lookup

```swift
public func resolve(account_id: String) async -> ResolveResponseEnum
```

Reverse lookup: finds the Stellar address associated with a known account ID. Sends `type=id` to the federation server. You must provide the server URL via the `Federation` initializer — the account ID contains no domain information.

```swift
import stellarsdk

let federation = Federation(federationAddress: "https://stellarid.io/federation")
let result = await federation.resolve(account_id: "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI")
switch result {
case .success(let response):
    print("Stellar address: \(response.stellarAddress ?? "unknown")") // bob*soneso.com
case .failure(let error):
    print("Error: \(error)")
}
```

**Account ID validation:** The SDK validates the account ID with `PublicKey(accountId:)` before sending any request. An invalid account ID (wrong prefix, wrong length, wrong encoding) returns `.failure(error: .invalidAccountId)` immediately.

## federation.resolve(transaction_id:) — Transaction Lookup

```swift
public func resolve(transaction_id: String) async -> ResolveResponseEnum
```

Looks up the sender of a transaction by its hash. Sends `type=txid` to the federation server. Not all federation servers support this query type.

```swift
import stellarsdk

let federation = Federation(federationAddress: "https://stellarid.io/federation")
let txHash = "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a"
let result = await federation.resolve(transaction_id: txHash)
switch result {
case .success(let response):
    if let sender = response.stellarAddress {
        print("Sender: \(sender)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## federation.resolve(forwardParams:) — Forward Lookup

```swift
public func resolve(forwardParams: Dictionary<String, String>) async -> ResolveResponseEnum
```

Maps external identifiers (bank accounts, phone numbers, routing numbers) to Stellar accounts. Sends `type=forward` with additional key-value parameters appended to the query string. The parameters are anchor-specific.

```swift
import stellarsdk

let federation = Federation(federationAddress: "https://stellarid.io/federation")

var params = Dictionary<String, String>()
params["forward_type"] = "bank_account"
params["swift"]        = "BOPBPHMM"
params["acct"]         = "2382376"

let result = await federation.resolve(forwardParams: params)
switch result {
case .success(let response):
    print("Deposit to: \(response.accountId ?? "nil")")
    if let memoType = response.memoType, let memo = response.memo {
        print("Memo (\(memoType)): \(memo)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## ResolveAddressResponse Properties

`ResolveAddressResponse` is a `Decodable` struct. All properties are optional — only fields returned by the federation server will be non-nil.

| Property | Type | JSON field | Description |
|----------|------|------------|-------------|
| `stellarAddress` | `String?` | `stellar_address` | Federation address in `user*domain.com` format |
| `accountId` | `String?` | `account_id` | Stellar public key (G-address) for the payment destination |
| `memoType` | `String?` | `memo_type` | Memo type: `"text"`, `"id"`, or `"hash"` |
| `memo` | `String?` | `memo` | Memo value to include with the payment |

The JSON the SDK decodes from a federation server looks like:

```json
{
  "stellar_address": "bob*soneso.com",
  "account_id": "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI",
  "memo_type": "text",
  "memo": "hello memo text"
}
```

**Hash memos:** When `memoType` is `"hash"`, the value in `memo` is base64-encoded. Decode it before passing to `Memo.hash()`, which expects raw `Data`.

## Building a Payment with Federation

This complete example resolves a Stellar address and builds a transaction with the correct memo type.

```swift
import stellarsdk

func sendFederatedPayment(
    senderKeyPair: KeyPair,
    stellarAddress: String,
    amountXLM: Decimal
) async throws {
    let sdk = StellarSDK.testNet()

    // 1. Resolve federation address
    let fedResult = await Federation.resolve(stellarAddress: stellarAddress)
    guard case .success(let fedResponse) = fedResult else {
        throw NSError(domain: "Federation", code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "Resolution failed: \(fedResult)"])
    }
    guard let destinationId = fedResponse.accountId else {
        throw NSError(domain: "Federation", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "No account ID in federation response"])
    }

    // 2. Load sender account for sequence number
    let accountResult = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let accountResponse) = accountResult else { return }

    let sourceAccount = try Account(
        accountId: accountResponse.accountId,
        sequenceNumber: accountResponse.sequenceNumber
    )

    // 3. Build payment operation
    let paymentOp = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: destinationId,
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: amountXLM
    )

    // 4. Attach memo if the federation response includes one
    var memo: Memo = Memo.none
    if let memoType = fedResponse.memoType, let memoValue = fedResponse.memo {
        switch memoType {
        case "text":
            memo = Memo.text(memoValue)
        case "id":
            if let memoId = UInt64(memoValue) {
                memo = Memo.id(memoId)
            }
        case "hash":
            // CORRECT: hash memo is base64-encoded in the federation response; decode to Data
            if let memoData = Data(base64Encoded: memoValue) {
                memo = try Memo.hash(memoData)
            }
        default:
            break
        }
    }

    // 5. Build, sign, and submit transaction
    let transaction = try Transaction(
        sourceAccount: sourceAccount,
        operations: [paymentOp],
        memo: memo,
        maxOperationFee: 100
    )
    try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

    let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResult {
    case .success(let response):
        print("Payment sent! Hash: \(response.transactionHash)")
    case .destinationRequiresMemo(let accountId):
        print("SEP-29: Destination \(accountId) requires a memo")
    case .failure(let error):
        print("Submission failed: \(error)")
    }
}
```

## Error Handling

All federation methods return a result enum with a `.failure(error: FederationError)` case. Handle errors with a `switch` on `FederationError`:

```swift
import stellarsdk

let result = await Federation.resolve(stellarAddress: "bob*example.com")
switch result {
case .success(let response):
    print("Resolved: \(response.accountId ?? "nil")")
case .failure(let error):
    switch error {
    case .invalidAddress:
        // Address does not contain exactly one '*'
        // e.g., "bobexample.com", "bob@example.com", "bob*server*example.com"
        print("Bad address format — must be user*domain.com")
    case .invalidAccountId:
        // Provided account ID is not a valid Stellar public key
        // Only applies to resolve(account_id:)
        print("Invalid account ID — must start with G, 56 chars")
    case .invalidDomain:
        // Domain portion of the address is invalid (RFC 1035)
        print("Invalid domain in address")
    case .invalidTomlDomain:
        // Domain passed to forDomain() is invalid or unreachable
        print("Cannot fetch stellar.toml — invalid domain")
    case .invalidToml:
        // stellar.toml was found but could not be parsed
        print("stellar.toml parse error")
    case .noFederationSet:
        // stellar.toml exists but has no FEDERATION_SERVER field
        print("Domain does not publish a federation server")
    case .parsingResponseFailed(let message):
        // Federation server returned unexpected JSON
        print("Parse error: \(message)")
    case .horizonError(let horizonError):
        // HTTP-level failure (404 user not found, 500 server error, etc.)
        print("HTTP error: \(horizonError)")
    }
}
```

### FederationError cases

| Case | Trigger |
|------|---------|
| `.invalidAddress` | Address missing `*` or has more than one `*` |
| `.invalidAccountId` | Account ID failed `PublicKey` validation (wrong prefix, length, or encoding) |
| `.invalidDomain` | Domain portion of address does not conform to RFC 1035 |
| `.invalidTomlDomain` | Domain passed to `forDomain()` is invalid or unreachable |
| `.invalidToml` | `stellar.toml` could not be parsed |
| `.noFederationSet` | `stellar.toml` has no `FEDERATION_SERVER` entry |
| `.parsingResponseFailed(message:)` | Federation server response is not valid JSON or missing expected fields |
| `.horizonError(error:)` | Network failure or non-2xx HTTP status from the federation server |

## Common Pitfalls

**Forgetting the memo when sending to exchanges:**

Federation responses from custodial services (exchanges) often include a memo that identifies the recipient. Omitting the memo causes funds to be unattributed.

```swift
// WRONG: building a payment without checking the federation memo
let tx = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,   // Exchange cannot credit the recipient!
    maxOperationFee: 100
)

// CORRECT: always attach the federation memo when present
var memo: Memo = Memo.none
if let memoType = fedResponse.memoType, let memoValue = fedResponse.memo {
    if memoType == "text" { memo = Memo.text(memoValue) }
    else if memoType == "id", let id = UInt64(memoValue) { memo = Memo.id(id) }
    else if memoType == "hash", let data = Data(base64Encoded: memoValue) { memo = try Memo.hash(data) }
}
```

**Not base64-decoding hash memos:**

```swift
// WRONG: passes base64 string as Data — Memo.hash() expects raw bytes
if memoType == "hash" {
    let wrongData = memoValue.data(using: .utf8)!
    memo = try Memo.hash(wrongData)  // Wrong bytes!
}

// CORRECT: decode base64 first
if memoType == "hash", let rawData = Data(base64Encoded: memoValue) {
    memo = try Memo.hash(rawData)
}
```

**Using the static method for reverse lookup:**

```swift
// WRONG: static resolve(stellarAddress:) expects "user*domain.com" format
let result = await Federation.resolve(stellarAddress: "GBVPKXWMAB3...")
// Returns .failure(error: .invalidAddress) — G-addresses have no '*'

// CORRECT: use an instance and resolve(account_id:) for reverse lookup
let federation = Federation(federationAddress: "https://stellarid.io/federation")
let result = await federation.resolve(account_id: "GBVPKXWMAB3...")
```

**Constructing a Federation instance with the wrong URL:**

```swift
// WRONG: passing the domain, not the federation server URL
// WRONG: Federation(federationAddress: "soneso.com")

// CORRECT: federationAddress must be the full federation server URL
// Get it from stellar.toml if you don't have it:
let domainResult = await Federation.forDomain(domain: "soneso.com")
if case .success(let federation) = domainResult {
    // federation.federationAddress is the FEDERATION_SERVER URL
    let result = await federation.resolve(account_id: "GBVPKXWMAB3...")
}
```

**Treating the `memo` field as a typed value instead of a String:**

All federation response fields including `memo` are `String?`, even when `memoType` is `"id"`. Convert to the appropriate Swift type before use.

```swift
// WRONG: treating memo as UInt64 directly — it is always String?
// let memoId: UInt64 = fedResponse.memo  // compile error

// CORRECT: parse the string to the appropriate type
if fedResponse.memoType == "id", let memoValue = fedResponse.memo {
    if let memoId = UInt64(memoValue) {
        memo = Memo.id(memoId)
    }
}
```

**`resolve(account_id:)` on a key derived from `accountId` only:**

The account ID validation calls `PublicKey(accountId:)` internally. Keys with the wrong prefix (e.g., secret keys starting with `S`) immediately return `.invalidAccountId`.

```swift
// WRONG: passing a secret key (S-address) to account_id lookup
let result = await federation.resolve(account_id: "SBVPKXWMAB3...")
// Returns .failure(error: .invalidAccountId)

// CORRECT: always pass a public key (G-address)
let result = await federation.resolve(account_id: "GBVPKXWMAB3...")
```
