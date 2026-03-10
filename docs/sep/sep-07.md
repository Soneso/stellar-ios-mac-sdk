# SEP-07: URI Scheme for Delegated Signing

SEP-07 defines a URI scheme (`web+stellar:`) that enables applications to request transaction signing from external wallets. Instead of handling private keys directly, your application generates a URI that a wallet can open, sign, and submit.

**When to use:** Building applications that need users to sign transactions, creating payment request links, QR codes for payments, or integrating with hardware wallets or other signing services.

See the [SEP-07 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) for complete protocol details.

## Quick example

The simplest way to create a payment request URI is with `getPayOperationURI()`. This creates a `web+stellar:pay?` URI that any SEP-07 compliant wallet can process.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Generate a payment request URI for 100 USDC
let uri = uriScheme.getPayOperationURI(
    destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
    amount: Decimal(100),
    assetCode: "USDC",
    assetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
)

print(uri)
// Output: web+stellar:pay?destination=GDGUF4SC...&amount=100&asset_code=USDC&asset_issuer=GA5ZSEJY...
```

## Generating URIs

### Transaction signing (tx operation)

The `tx` operation requests a wallet to sign a specific XDR-encoded transaction. Use this when you have full control over the transaction structure and need an exact transaction to be signed.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Source account keypair (the account that will sign)
let sourceKeyPair = try! KeyPair(secretSeed: "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF")
let accountId = sourceKeyPair.accountId

let accountDetailsResponse = await sdk.accounts.getAccountDetails(accountId: accountId)
switch accountDetailsResponse {
case .success(let accountDetails):
    // Build a transaction that sets the home domain
    let setOp = try SetOptionsOperation(
        sourceAccountId: accountId,
        homeDomain: "www.example.com"
    )

    let transaction = TransactionXDR(
        sourceAccount: sourceKeyPair.publicKey,
        seqNum: accountDetails.sequenceNumber + 1,
        cond: PreconditionsXDR.none,
        memo: .none,
        operations: [try setOp.toXDR()]
    )

    // Generate a SEP-07 URI from the unsigned transaction
    let uriScheme = URIScheme()
    let uri = uriScheme.getSignTransactionURI(
        transactionXDR: transaction
    )

    print(uri)
    // Output: web+stellar:tx?xdr=AAAAAgAAAAD...
case .failure(let error):
    print("Error: \(error)")
}
```

### Transaction URI with all options

The `getSignTransactionURI()` method accepts optional parameters for callbacks, messages, signature verification, and more.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Build a transaction (see previous example for full transaction building)
// let transaction: TransactionXDR = ...

let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction,
    replace: nil,  // Field replacement spec (see "Field replacement with Txrep" section)
    callBack: "url:https://example.com/callback",  // Where to POST signed tx
    publicKey: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",  // Which account should sign
    chain: nil,  // Nested SEP-07 URI that triggered this one
    message: "Please sign to update your account settings",  // User-facing message (max 300 chars)
    networkPassphrase: Network.testnet.passphrase,  // Omit for public network
    originDomain: "example.com"  // Your domain (requires signing the URI)
)

print(uri)
```

### Field replacement with Txrep (replace parameter)

The `replace` parameter lets you specify fields in the transaction that should be filled in by the wallet user. This uses the [SEP-11 Txrep](sep-11.md) format to identify fields. Useful when you want the user to provide certain values like source account or destination.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Build a transaction (see earlier examples for full transaction building)
// let transaction: TransactionXDR = ...

// Build a replace string specifying fields the wallet should fill in
let replaceString = "sourceAccount:X,operations[0].destination:Y"

let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction,
    replace: replaceString
)

print(uri)
```

### Transaction chaining (chain parameter)

The `chain` parameter embeds a previous SEP-07 URI that triggered the creation of this one. This is informational and enables verification of the full request chain. Chains can nest up to 7 levels deep.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Build a transaction (see earlier examples for full transaction building)
// let transaction: TransactionXDR = ...

// The original URI that triggered this request
let originalUri = "web+stellar:tx?xdr=AAAA...&origin_domain=original.com&signature=..."

let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction,
    callBack: "url:https://multisig-coordinator.com/collect",
    chain: originalUri,  // Embed the original request for audit purposes
    originDomain: "multisig-coordinator.com"
)

print(uri)
```

### Multisig coordination

The `callBack` parameter is particularly useful for multisig coordination services. Instead of submitting directly to the network, the signed transaction is POSTed to a coordination service that collects signatures from multiple parties.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Build a transaction (see earlier examples for full transaction building)
// let transaction: TransactionXDR = ... // Transaction requiring multiple signatures

// Generate URI that sends signed tx to a multisig coordinator
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction,
    callBack: "url:https://multisig-service.example.com/collect",
    message: "Sign to approve the 2-of-3 multisig transaction",
    originDomain: "multisig-service.example.com"
)

// Each signer receives this URI and signs independently
// The coordinator collects signatures and submits when threshold is met
print(uri)
```

### Payment request (pay operation)

The `pay` operation requests a payment to a destination without pre-building a transaction. The wallet can choose the payment method (direct or path payment) and source asset.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Simple XLM payment (no asset_code means native XLM)
let uri = uriScheme.getPayOperationURI(
    destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
    amount: Decimal(50.5)
)
print(uri)
// Output: web+stellar:pay?destination=GDGUF4SC...&amount=50.5
```

### Payment with asset and memo

When accepting payments for specific assets or with order tracking via memos, specify the full payment details.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Payment with specific asset and text memo
let uri = uriScheme.getPayOperationURI(
    destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
    amount: Decimal(100),
    assetCode: "USDC",
    assetIssuer: "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    memo: "order-12345",
    memoType: MemoTypeAsString.TEXT
)
print(uri)
```

### Payment with hash or return memo

For `MEMO_HASH` and `MEMO_RETURN` memo types, the SDK automatically base64-encodes the memo value before URL-encoding it.

```swift
import stellarsdk
import Foundation
import CommonCrypto

let uriScheme = URIScheme()

// MEMO_HASH: the SDK handles base64 encoding internally
let memoValue = "my-unique-identifier"

let uri = uriScheme.getPayOperationURI(
    destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
    amount: Decimal(100),
    memo: memoValue,
    memoType: MemoTypeAsString.HASH
)
print(uri)
```

### Donation request (no amount)

Omit the amount to let the user decide how much to send. Useful for donations or tips.

```swift
import stellarsdk

let uriScheme = URIScheme()

// Omitting amount allows user to specify any amount
let uri = uriScheme.getPayOperationURI(
    destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
    message: "Support our open source project!"
)

print(uri)
// Output: web+stellar:pay?destination=GDGUF4SC...&msg=Support%20our%20open%20source%20project%21
```

## Signing URIs for origin verification

If your application issues SEP-07 URIs and wants to prove authenticity, sign them with a keypair whose public key is published as `URI_REQUEST_SIGNING_KEY` in your [stellar.toml](sep-01.md) file. Use `URISchemeValidator` to sign the URI.

```swift
import stellarsdk

let uriScheme = URIScheme()
let validator = URISchemeValidator()

// Your signing keypair - the public key must match URI_REQUEST_SIGNING_KEY in your stellar.toml
let signerKeyPair = try! KeyPair(secretSeed: "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF")

// First generate the URI with origin_domain (signature will be added by signURI)
// let transaction: TransactionXDR = ... // Build your transaction
let uri = uriScheme.getSignTransactionURI(
    transactionXDR: transaction,
    originDomain: "example.com"
)

// Sign the URI - this appends the signature parameter
let signResult = validator.signURI(url: uri, signerKeyPair: signerKeyPair)
switch signResult {
case .success(let signedURL):
    print(signedURL)
    // Output: web+stellar:tx?xdr=...&origin_domain=example.com&signature=bIZ53bPK...
case .failure(let error):
    print("Signing failed: \(error)")
}
```

## Validating URIs

Before processing a URI from an untrusted source, validate it. SEP-07 provides validation through `URISchemeValidator`.

### Full validation including signature (network request)

`checkURISchemeIsValid()` validates the URI structure, fetches `stellar.toml` from `origin_domain`, extracts `URI_REQUEST_SIGNING_KEY`, and verifies the Ed25519 signature.

```swift
import stellarsdk

let validator = URISchemeValidator()
let uri = "web+stellar:tx?xdr=...&origin_domain=example.com&signature=..."

let result = await validator.checkURISchemeIsValid(url: uri)
switch result {
case .success:
    // URI is valid and signature verified - safe to display origin_domain to user
    let uriScheme = URIScheme()
    if let originDomain = uriScheme.getValue(forParam: .origin_domain, fromURL: uri) {
        print("Verified request from: \(originDomain)")
    }
case .failure(let error):
    // Possible failure reasons:
    // - .missingOriginDomain
    // - .invalidOriginDomain
    // - .invalidTomlDomain / .invalidToml
    // - .tomlSignatureMissing
    // - .missingSignature / .invalidSignature
    print("Validation failed: \(error)")
}
```

### Signature verification with known public key

`URISchemeValidator.signURI()` can be used to sign a URI, and `checkURISchemeIsValid()` to verify it. For offline verification without fetching stellar.toml, you can sign a test URI and compare signatures.

```swift
import stellarsdk

let validator = URISchemeValidator()
let uriScheme = URIScheme()
let uri = "web+stellar:tx?xdr=...&origin_domain=example.com"
let signingKeyPair = try! KeyPair(secretSeed: "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF")

let signResult = validator.signURI(url: uri, signerKeyPair: signingKeyPair)
switch signResult {
case .success(let signedURL):
    print("Signature is valid: \(signedURL)")
case .failure(let error):
    print("Invalid or malformed: \(error)")
}
```

## Signing and submitting transactions

Use `signAndSubmitTransaction()` to sign a transaction from a URI and submit it. The method handles submission to either a callback URL or directly to the Stellar network.

> **Note:** The SDK's `signAndSubmitTransaction` always signs with `Network.testnet` internally regardless of the `network` parameter passed in. For mainnet use, extract the XDR and sign/submit manually.

```swift
import stellarsdk

let uriScheme = URIScheme()

// The URI containing the transaction to sign
let uri = "web+stellar:tx?xdr=AAAAAgAAAAD..."

// User's signing keypair
let signerKeyPair = try! KeyPair(secretSeed: "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF")

// Sign and submit the transaction
let result = await uriScheme.signAndSubmitTransaction(
    forURL: uri,
    signerKeyPair: signerKeyPair,
    network: Network.testnet
)

// Check the result
switch result {
case .success:
    print("Transaction submitted successfully")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination \(destinationAccountId) requires a memo (SEP-29)")
case .failure(let error):
    print("Transaction failed: \(error)")
}
```

## Extracting URI parameters

Use `getValue(forParam:fromURL:)` to extract named parameters from a SEP-07 URI.

```swift
import stellarsdk

let uriScheme = URIScheme()
let uri = "web+stellar:pay?destination=GDGUF4SC...&amount=100&msg=Payment%20for%20order"

// Extract parameters using SignTransactionParams enum cases
let destination = uriScheme.getValue(forParam: .pubkey, fromURL: uri)  // Note: use .xdr, .callback, etc.
let xdr = uriScheme.getValue(forParam: .xdr, fromURL: uri)
let callback = uriScheme.getValue(forParam: .callback, fromURL: uri)
let message = uriScheme.getValue(forParam: .msg, fromURL: uri)
let originDomain = uriScheme.getValue(forParam: .origin_domain, fromURL: uri)
let signature = uriScheme.getValue(forParam: .signature, fromURL: uri)
let networkPassphrase = uriScheme.getValue(forParam: .network_passphrase, fromURL: uri)
let replace = uriScheme.getValue(forParam: .replace, fromURL: uri)
let chain = uriScheme.getValue(forParam: .chain, fromURL: uri)

// Returns nil for missing parameters
if let domain = originDomain {
    print("Origin: \(domain)")
}

if let msg = message {
    print("Message: \(msg)")
}

if callback != nil {
    print("Has callback URL")
} else {
    print("Submit directly to network")
}
```

### Available parameter constants

The `SignTransactionParams` enum provides cases for all standard parameter names:

| Case | URI key | Description |
|------|---------|-------------|
| `.xdr` | `xdr` | Transaction envelope XDR |
| `.replace` | `replace` | Txrep field replacement spec |
| `.callback` | `callback` | Callback URL for submission |
| `.pubkey` | `pubkey` | Required signing public key |
| `.chain` | `chain` | Nested SEP-07 URI |
| `.msg` | `msg` | User-facing message |
| `.network_passphrase` | `network_passphrase` | Network identifier |
| `.origin_domain` | `origin_domain` | Request originator domain |
| `.signature` | `signature` | URI signature |

The `PayOperationParams` enum provides cases for payment-specific parameters:

| Case | URI key | Description |
|------|---------|-------------|
| `.destination` | `destination` | Payment recipient |
| `.amount` | `amount` | Payment amount |
| `.asset_code` | `asset_code` | Asset code |
| `.asset_issuer` | `asset_issuer` | Asset issuer account |
| `.memo` | `memo` | Transaction memo value |
| `.memo_type` | `memo_type` | Memo type |

## Error handling

Error handling for URI validation and transaction submission.

```swift
import stellarsdk

let uriScheme = URIScheme()
let validator = URISchemeValidator()

// 1. Validate signed URI (async - fetches stellar.toml)
let signedUri = "web+stellar:tx?xdr=...&origin_domain=example.com&signature=..."
let validationResult = await validator.checkURISchemeIsValid(url: signedUri)
switch validationResult {
case .success:
    print("URI is valid")
case .failure(let error):
    switch error {
    case .missingOriginDomain:
        print("Missing origin_domain parameter")
    case .invalidOriginDomain:
        print("origin_domain is not a valid FQDN")
    case .tomlSignatureMissing:
        print("No URI_REQUEST_SIGNING_KEY in stellar.toml")
    case .invalidTomlDomain:
        print("stellar.toml domain is invalid")
    case .invalidToml:
        print("stellar.toml could not be parsed")
    case .missingSignature:
        print("Missing signature parameter")
    case .invalidSignature:
        print("Signature does not match signing key")
    }
}

// 2. Handle transaction submission errors
let txUri = "web+stellar:tx?xdr=AAAAAgAAAAD..."
let keyPair = try! KeyPair(secretSeed: "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF")
let submitResult = await uriScheme.signAndSubmitTransaction(
    forURL: txUri,
    signerKeyPair: keyPair,
    network: Network.testnet
)

switch submitResult {
case .success:
    print("Transaction submitted successfully")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination \(destinationAccountId) requires a memo")
case .failure(let error):
    print("Transaction failed: \(error)")
}
```

## QR codes

SEP-07 URIs can be encoded into QR codes for mobile scanning. Encode the complete URI into the QR code data.

```swift
import stellarsdk

let uriScheme = URIScheme()

let uri = uriScheme.getPayOperationURI(
    destination: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
    amount: Decimal(25),
    memo: "coffee",
    memoType: MemoTypeAsString.TEXT
)

// Use any QR code library to encode the URI
// Example with CoreImage CIFilter:
// let qrFilter = CIFilter(name: "CIQRCodeGenerator")
// qrFilter?.setValue(uri.data(using: .utf8), forKey: "inputMessage")

print("Encode this URI in a QR code: \(uri)")
```

## Security considerations

When implementing SEP-07 support, follow these security practices from the specification:

### For applications generating URIs

- **Always sign your URIs** with an `origin_domain` and `signature` when possible. Unsigned URIs should be treated as untrusted.
- **Publish your `URI_REQUEST_SIGNING_KEY`** in your stellar.toml file.
- **Include meaningful messages** in the `msg` parameter to help users understand what they're signing.
- **Use unique memos** to track individual payment requests.

### For wallets processing URIs

- **Always validate signed URIs** before displaying `origin_domain` to users.
- **Never auto-sign transactions** - always get explicit user consent.
- **Display transaction details clearly** so users understand what they're signing.
- **Warn users about unsigned URIs** - they are equivalent to HTTP vs HTTPS.
- **Track known destination addresses** and warn about new recipients.
- **Use fonts that distinguish similar characters** to prevent homograph attacks (e.g., distinguishing `l` from `I`, or Latin from Cyrillic characters).
- **Cache `URI_REQUEST_SIGNING_KEY`** per domain and alert users if it changes.

### Callback security

- **Callbacks receive signed transactions** - be careful what endpoints you trust.
- **Validate callback URLs** before sending signed transactions to them.
- **The `msg` field can be spoofed** - only trust message content after successful signature validation.

## Further reading

- [SEP-07 test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/uri_scheme/URISchemeTestCase.swift) - SDK test cases demonstrating URI generation, signing, and validation

## Related SEPs

- [SEP-01 stellar.toml](sep-01.md) - Where `URI_REQUEST_SIGNING_KEY` is published for signature verification
- [SEP-11 Txrep](sep-11.md) - Human-readable transaction format used in the `replace` parameter

---

[Back to SEP Overview](README.md)
