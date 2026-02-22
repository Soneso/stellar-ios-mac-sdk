# SEP-07: URI Scheme

**Purpose:** Generate and validate URIs for delegated transaction signing by wallets.
**Prerequisites:** None
**SDK Classes:** `URIScheme`, `URISchemeValidator`

## Table of Contents

1. [Overview](#overview)
2. [Generate a Pay URI](#generate-a-pay-uri)
3. [Generate a Transaction Signing URI](#generate-a-transaction-signing-uri)
4. [Sign and Submit a Transaction from URI](#sign-and-submit-a-transaction-from-uri)
5. [Extract Parameters from a URI](#extract-parameters-from-a-uri)
6. [Sign a URI (for servers)](#sign-a-uri-for-servers)
7. [Validate a URI Signature](#validate-a-uri-signature)
8. [Response Enums](#response-enums)
9. [Error Types](#error-types)
10. [Common Pitfalls](#common-pitfalls)

---

## Overview

SEP-07 defines a URI scheme (`web+stellar:`) that lets applications request a wallet to sign a transaction or make a payment on behalf of the user. The URI encodes either a pre-built transaction (`tx` operation) or a payment request (`pay` operation).

**Key constants (from SDK source):**
```swift
URISchemeName       = "web+stellar:"   // URI prefix
SignOperation       = "tx?"            // Transaction signing suffix
PayOperation        = "pay?"           // Payment request suffix
MessageMaximumLength = 300             // message param must be < 300 chars
```

**Two main classes:**
- `URIScheme` — generates URIs and extracts parameters
- `URISchemeValidator` — signs URIs and validates signatures against stellar.toml

---

## Generate a Pay URI

`getPayOperationURI(destination:...)` generates a `web+stellar:pay?` URI.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Minimal: destination only (XLM payment)
let uri = uriScheme.getPayOperationURI(
    destination: "GDEST..."
)
// → "web+stellar:pay?destination=GDEST..."

// Full example: USDC payment with memo and callback
let uri = uriScheme.getPayOperationURI(
    destination: "GDEST...",
    amount: Decimal(100.50),
    assetCode: "USDC",
    assetIssuer: "GISSUER...",
    memo: "Invoice #1234",
    memoType: MemoTypeAsString.TEXT,
    callBack: "url:https://example.com/callback",
    message: "Payment for services",
    networkPassphrase: Network.testnet.passphrase,
    originDomain: "example.com",
    signature: nil
)
print(uri)
```

**Method signature:**
```swift
public func getPayOperationURI(
    destination: String,
    amount: Decimal? = nil,
    assetCode: String? = nil,
    assetIssuer: String? = nil,
    memo: String? = nil,
    memoType: String? = MemoTypeAsString.TEXT,  // default is "text"
    callBack: String? = nil,
    message: String? = nil,
    networkPassphrase: String? = nil,
    originDomain: String? = nil,
    signature: String? = nil
) -> String
```

**`MemoTypeAsString` constants:**
```swift
MemoTypeAsString.TEXT   // "text"  — URL-encoded, max 28 bytes
MemoTypeAsString.ID     // "id"    — numeric string, not URL-encoded
MemoTypeAsString.HASH   // "hash"  — base64-encoded then URL-encoded
MemoTypeAsString.RETURN // "return"— base64-encoded then URL-encoded
```

The generated URI uses the SEP-07 memo_type prefix format: `MEMO_TEXT`, `MEMO_ID`, `MEMO_HASH`, `MEMO_RETURN`.

**Native XLM payment (omit assetCode and assetIssuer):**
```swift
let uri = uriScheme.getPayOperationURI(
    destination: "GDEST...",
    amount: Decimal(50)
)
// No asset_code or asset_issuer in URI — wallet defaults to XLM
```

---

## Generate a Transaction Signing URI

`getSignTransactionURI(transactionXDR:...)` generates a `web+stellar:tx?` URI from a built transaction.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Build the transaction
let keyPair = try KeyPair(secretSeed: "SABC...")
let account = Account(keyPair: keyPair, sequenceNumber: 123456)

let payment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: Decimal(100)
)

let transaction = try Transaction(
    sourceAccount: account,
    operations: [payment],
    memo: Memo.none
)

// Generate the URI — pass transaction.transactionXDR
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction.transactionXDR
)
// → "web+stellar:tx?xdr=AAAA..."

// Full example with optional parameters
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction.transactionXDR,
    replace: "sourceAccount:TX_SOURCE_ACCOUNT",
    callBack: "url:https://example.com/signed",
    publicKey: keyPair.accountId,
    chain: nil,
    message: "Please sign to authorize payment",
    networkPassphrase: Network.testnet.passphrase,
    originDomain: "example.com",
    signature: nil
)
```

**Method signature:**
```swift
public func getSignTransactionURI(
    transactionXDR: TransactionXDR,
    replace: String? = nil,
    callBack: String? = nil,
    publicKey: String? = nil,
    chain: String? = nil,
    message: String? = nil,
    networkPassphrase: String? = nil,
    originDomain: String? = nil,
    signature: String? = nil
) -> String
```

**Parameters:**
- `transactionXDR` — the `TransactionXDR` from `transaction.transactionXDR`
- `replace` — Txrep (SEP-11) fields to be replaced in the XDR
- `callBack` — URL for wallet to POST the signed XDR; must be prefixed with `"url:"`
- `publicKey` — public key that will sign (hint for wallet)
- `chain` — a prior SEP-07 URI that spawned this request
- `message` — shown to the user in wallet; silently dropped if `>= 300` characters
- `networkPassphrase` — required for non-public networks (testnet, futurenet, custom)
- `originDomain` — fully qualified domain name of the requesting app
- `signature` — pre-computed signature; usually appended via `URISchemeValidator.signURI`

---

## Sign and Submit a Transaction from URI

`signAndSubmitTransaction(forURL:signerKeyPair:network:transactionConfirmation:)` parses the XDR from a URI, optionally confirms via callback, signs it, and submits to Horizon or the callback URL.

```swift
import stellarsdk

let uriScheme = URIScheme()
let signerKeyPair = try KeyPair(secretSeed: "SABC...")

// Without confirmation callback — sign and submit immediately
let result = await uriScheme.signAndSubmitTransaction(
    forURL: "web+stellar:tx?xdr=AAAA...",
    signerKeyPair: signerKeyPair,
    network: Network.testnet
)

switch result {
case .success:
    print("Transaction submitted successfully")
case .destinationRequiresMemo(let destinationAccountId):
    print("SEP-29: destination \(destinationAccountId) requires a memo")
case .failure(let error):
    print("Failed: \(error)")
}

// With confirmation callback — user can reject
let result = await uriScheme.signAndSubmitTransaction(
    forURL: uri,
    signerKeyPair: signerKeyPair,
    network: Network.testnet,
    transactionConfirmation: { transactionXDR in
        // Inspect the transaction — return true to proceed, false to cancel
        print("Operations: \(transactionXDR.operations.count)")
        return true  // proceed with signing
    }
)
```

**Method signature:**
```swift
public func signAndSubmitTransaction(
    forURL url: String,
    signerKeyPair keyPair: KeyPair,
    network: Network = .public,
    transactionConfirmation: TransactionConfirmationClosure? = nil
) async -> SubmitTransactionEnum
```

**`TransactionConfirmationClosure` type:**
```swift
public typealias TransactionConfirmationClosure = ((TransactionXDR) -> (Bool))
```

---

## Extract Parameters from a URI

`getValue(forParam:fromURL:)` extracts a named parameter from a SEP-07 URI.

```swift
import stellarsdk

let uriScheme = URIScheme()

let uri = "web+stellar:tx?xdr=AAAA...&pubkey=GABC...&origin_domain=example.com&signature=abc123"

// Extract parameters using SignTransactionParams enum cases
let xdr           = uriScheme.getValue(forParam: .xdr,               fromURL: uri)
let callback      = uriScheme.getValue(forParam: .callback,          fromURL: uri)
let pubkey        = uriScheme.getValue(forParam: .pubkey,            fromURL: uri)
let msg           = uriScheme.getValue(forParam: .msg,               fromURL: uri)
let passphrase    = uriScheme.getValue(forParam: .network_passphrase, fromURL: uri)
let originDomain  = uriScheme.getValue(forParam: .origin_domain,     fromURL: uri)
let signature     = uriScheme.getValue(forParam: .signature,         fromURL: uri)
let replace       = uriScheme.getValue(forParam: .replace,           fromURL: uri)
let chain         = uriScheme.getValue(forParam: .chain,             fromURL: uri)

// Returns nil for missing parameters
if let domain = originDomain {
    print("Origin: \(domain)")
}
```

**`SignTransactionParams` enum cases:**

| Case | URI key |
|------|---------|
| `.xdr` | `xdr` |
| `.replace` | `replace` |
| `.callback` | `callback` |
| `.pubkey` | `pubkey` |
| `.chain` | `chain` |
| `.msg` | `msg` |
| `.network_passphrase` | `network_passphrase` |
| `.origin_domain` | `origin_domain` |
| `.signature` | `signature` |

Note: `getValue(forParam:fromURL:)` uses `SignTransactionParams` for both `tx` and `pay` URIs. There is no equivalent method that takes `PayOperationParams`.

---

## Sign a URI (for servers)

Servers that generate SEP-07 URIs must sign them so wallets can verify authenticity. Use `URISchemeValidator.signURI(url:signerKeyPair:)`.

```swift
import stellarsdk

let uriScheme = URIScheme()
let validator = URISchemeValidator()

// 1. Generate the URI (without signature)
let baseUri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction.transactionXDR,
    originDomain: "example.com"
)

// 2. Sign it with the server's URI signing key
let signerKeyPair = try KeyPair(secretSeed: "SERVER_SECRET_SEED")
let signResult = validator.signURI(url: baseUri, signerKeyPair: signerKeyPair)

switch signResult {
case .success(let signedURL):
    print("Signed URI: \(signedURL)")
    // Signed URI has &signature=<url-encoded-base64-sig> appended
case .failure(let error):
    print("Signing failed: \(error)")
}
```

**Method signature:**
```swift
public func signURI(url: String, signerKeyPair: KeyPair) -> SignURLEnum
```

The `URI_REQUEST_SIGNING_KEY` for the `originDomain` must be published in the domain's `stellar.toml` so wallets can verify the signature. The signing key in stellar.toml is looked up via `accountInformation.uriRequestSigningKey`.

---

## Validate a URI Signature

`URISchemeValidator.checkURISchemeIsValid(url:)` validates a URI by fetching the `origin_domain`'s stellar.toml, extracting `URI_REQUEST_SIGNING_KEY`, and verifying the `signature` parameter.

```swift
import stellarsdk

let validator = URISchemeValidator()

let result = await validator.checkURISchemeIsValid(url: uri)

switch result {
case .success:
    print("URI is valid and signature verified")
case .failure(let error):
    switch error {
    case .missingOriginDomain:
        print("URI missing origin_domain parameter")
    case .invalidOriginDomain:
        print("origin_domain is not a valid fully qualified domain name")
    case .tomlSignatureMissing:
        print("stellar.toml missing URI_REQUEST_SIGNING_KEY field")
    case .invalidTomlDomain:
        print("stellar.toml domain is invalid")
    case .invalidToml:
        print("stellar.toml could not be parsed")
    case .missingSignature:
        print("URI missing signature parameter or URI_REQUEST_SIGNING_KEY not resolvable")
    case .invalidSignature:
        print("Signature does not match URI_REQUEST_SIGNING_KEY")
    }
}
```

**Method signature:**
```swift
public func checkURISchemeIsValid(url: String) async -> URISchemeIsValidEnum
```

**Validation steps performed:**
1. `origin_domain` present → else `.missingOriginDomain`
2. `origin_domain` is a valid FQDN → else `.invalidOriginDomain`
3. Fetch `https://<origin_domain>/.well-known/stellar.toml` → else `.invalidTomlDomain` / `.invalidToml`
4. `URI_REQUEST_SIGNING_KEY` in stellar.toml → else `.tomlSignatureMissing`
5. `signature` parameter present and verifiable → else `.missingSignature` / `.invalidSignature`

---

## Response Enums

### `SubmitTransactionEnum`

Returned by `signAndSubmitTransaction(...)`:

```swift
public enum SubmitTransactionEnum {
    case success
    case destinationRequiresMemo(destinationAccountId: String)  // SEP-29
    case failure(error: HorizonRequestError)
}
```

### `SetupTransactionXDREnum`

Available for custom parsing flows:

```swift
public enum SetupTransactionXDREnum {
    case success(transactionXDR: TransactionXDR?)
    case failure(error: HorizonRequestError)
}
```

### `SignURLEnum`

Returned by `URISchemeValidator.signURI(...)`:

```swift
public enum SignURLEnum {
    case success(signedURL: String)
    case failure(URISchemeErrors)
}
```

### `URISchemeIsValidEnum`

Returned by `URISchemeValidator.checkURISchemeIsValid(...)`:

```swift
public enum URISchemeIsValidEnum {
    case success
    case failure(URISchemeErrors)
}
```

---

## Error Types

### `URISchemeErrors`

All validation errors from `URISchemeValidator`:

```swift
public enum URISchemeErrors {
    case invalidSignature      // signature present but cryptographically invalid
    case invalidOriginDomain   // origin_domain is not a valid FQDN
    case missingOriginDomain   // origin_domain parameter absent from URI
    case missingSignature      // signature parameter absent, or signing key not resolvable
    case invalidTomlDomain     // domain in TOML file is invalid
    case invalidToml           // stellar.toml is malformed or unparseable
    case tomlSignatureMissing  // URI_REQUEST_SIGNING_KEY absent from stellar.toml
}
```

---

## Common Pitfalls

**`message` parameter silently dropped at exactly 300 characters:**

```swift
// WRONG: message of length 300 is NOT included in the URI
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    message: String(repeating: "a", count: 300)  // dropped — not < 300
)

// CORRECT: message must be < 300 characters (strictly less than)
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    message: String(repeating: "a", count: 299)  // included
)
```

**`callBack` must be prefixed with `"url:"`:**

```swift
// WRONG: raw URL without "url:" prefix
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    callBack: "https://example.com/callback"  // submitTransaction won't POST to this
)

// CORRECT: prefix with "url:"
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    callBack: "url:https://example.com/callback"
)
```

**`memo_type` is only added when `memo` is also provided:**

```swift
// WRONG: passing memoType without memo — memo_type is NOT added to URI
let uri = uriScheme.getPayOperationURI(
    destination: "GDEST...",
    memoType: MemoTypeAsString.TEXT  // ignored — no memo provided
)

// CORRECT: provide both memo and memoType
let uri = uriScheme.getPayOperationURI(
    destination: "GDEST...",
    memo: "Invoice #42",
    memoType: MemoTypeAsString.TEXT  // added as MEMO_TEXT
)
```

**`networkPassphrase` is required for testnet URIs:**

The SDK's public network is assumed by default. If wallet mismatches the network, signing will fail silently or produce an invalid transaction.

```swift
// WRONG: testnet transaction without passphrase — wallet signs for wrong network
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR  // testnet transaction, no passphrase specified
)

// CORRECT: include network passphrase for non-public networks
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    networkPassphrase: Network.testnet.passphrase
)
```

**SDK bug: `signAndSubmitTransaction` ignores the `network` parameter and always signs for testnet:**

Inspecting the SDK source (`URIScheme.swift` line 273), `signAndSubmitTransaction` always calls `transaction.sign(keyPair: keyPair, network: Network.testnet)` regardless of the `network` parameter passed in. This means the method only works correctly for testnet transactions. For production use, prefer extracting the XDR from the URI and signing + submitting manually:

```swift
// NOTE: signAndSubmitTransaction always signs with Network.testnet internally
// For mainnet use, sign and submit manually instead:
let uriScheme = URIScheme()
if let encodedXdr = uriScheme.getValue(forParam: .xdr, fromURL: uri),
   let decodedXdr = encodedXdr.removingPercentEncoding {
    var txXDR = try Transaction(envelopeXdr: decodedXdr).transactionXDR
    try txXDR.sign(keyPair: signerKeyPair, network: .public)  // correct network
    let sdk = StellarSDK.publicNet()
    let response = await sdk.transactions.submitTransaction(transaction: try Transaction(envelopeXdr: txXDR.encodedEnvelope()))
}
```

**`originDomain` must be a valid FQDN for `checkURISchemeIsValid` to pass:**

```swift
// WRONG: "localhost" and bare hostnames fail FQDN validation
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    originDomain: "localhost"  // checkURISchemeIsValid → .failure(.invalidOriginDomain)
)

// CORRECT: use a proper domain with at least one dot and valid TLD
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: txXDR,
    originDomain: "app.example.com"
)
```

**`Account(keyPair:sequenceNumber:)` vs `Account(accountId:sequenceNumber:)` for offline URI generation:**

When building a transaction for a URI without fetching the live account, you can use either constructor:

```swift
// From a KeyPair (no network call)
let account = Account(keyPair: keyPair, sequenceNumber: 0)

// From an account ID string (throws)
let account = try Account(accountId: "GABC...", sequenceNumber: 0)
```

**`getValue(forParam:fromURL:)` returns URL-encoded values:**

The returned string is still URL-encoded. For the `xdr` parameter in particular, you must percent-decode before passing to `Transaction(envelopeXdr:)`:

```swift
let uriScheme = URIScheme()
if let encodedXdr = uriScheme.getValue(forParam: .xdr, fromURL: uri),
   let decodedXdr = encodedXdr.removingPercentEncoding {
    let transaction = try Transaction(envelopeXdr: decodedXdr)
}
```
