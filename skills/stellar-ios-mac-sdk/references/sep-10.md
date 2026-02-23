# SEP-10: Stellar Web Authentication

**Purpose:** Prove ownership of a Stellar account to an anchor and receive a JWT token for authenticated API calls (SEP-6, SEP-12, SEP-24, SEP-31, etc.)
**Prerequisites:** Requires SEP-01 to discover `WEB_AUTH_ENDPOINT` and `SIGNING_KEY` (see sep-01.md)
**SDK Class:** `WebAuthenticator`

## Table of Contents

- [Quick Start](#quick-start)
- [Creating WebAuthenticator](#creating-webauthenticator)
- [jwtToken() — the Complete Flow](#jwttoken--the-complete-flow)
- [Standard Authentication](#standard-authentication)
- [Multi-Signature Authentication](#multi-signature-authentication)
- [Memo-Based Authentication](#memo-based-authentication)
- [Muxed Account Authentication](#muxed-account-authentication)
- [Client Domain Verification](#client-domain-verification)
- [Result Enums Reference](#result-enums-reference)
- [Error Types Reference](#error-types-reference)
- [Mock Testing Patterns](#mock-testing-patterns)
- [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```swift
import stellarsdk

// 1. Initialize from anchor domain (reads stellar.toml automatically)
let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// 2. Get JWT token for user account
let userKeyPair = try KeyPair(secretSeed: "S...")
let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair]
)
guard case .success(let jwtToken) = jwtResult else { return }

// 3. Use JWT for SEP-12, SEP-24, etc.
print("Authenticated! Token: \(jwtToken)")
```

---

## Creating WebAuthenticator

### From domain (recommended)

`WebAuthenticator.from(domain:network:)` fetches the anchor's `stellar.toml`, reads `WEB_AUTH_ENDPOINT` and `SIGNING_KEY`, and returns a configured `WebAuthenticator` instance.

```swift
import stellarsdk

let result = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
switch result {
case .success(let webAuth):
    print("Auth endpoint: \(webAuth.authEndpoint)")
    print("Server key: \(webAuth.serverSigningKey)")
case .failure(let error):
    switch error {
    case .invalidDomain:
        print("The domain string is not a valid URL or domain format")
    case .invalidToml:
        print("stellar.toml could not be parsed or is malformed")
    case .noAuthEndpoint:
        print("stellar.toml does not specify WEB_AUTH_ENDPOINT")
    }
}
```

Method signature:
```swift
static func from(domain: String, network: Network, secure: Bool = true) async -> WebAuthenticatorForDomainEnum
```

The `secure` parameter defaults to `true` (HTTPS). Set to `false` only for local development.

### Manual construction

Use when you already have the endpoint and signing key (e.g., you loaded stellar.toml separately or are writing tests).

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS",
    serverHomeDomain: "testanchor.stellar.org"
)
```

Constructor signature:
```swift
init(authEndpoint: String, network: Network, serverSigningKey: String, serverHomeDomain: String)
```

Public properties on `WebAuthenticator`:
- `authEndpoint: String` — the SEP-10 web authentication endpoint URL
- `serverSigningKey: String` — the server's public signing key
- `network: Network` — the Stellar network
- `serverHomeDomain: String` — the home domain hosting stellar.toml
- `gracePeriod: UInt64` — time bounds grace period in seconds (5 minutes, read-only)

---

## jwtToken() — the Complete Flow

`jwtToken(forUserAccount:signers:)` performs all SEP-10 steps internally:

1. Requests a challenge transaction from the server (GET)
2. Validates the challenge (sequence number = 0, server signature, time bounds, operation types, source accounts, home domain, web_auth_domain)
3. Signs the transaction with the provided keypairs
4. Submits the signed transaction to the server (POST)
5. Returns the JWT token string

Method signature:
```swift
func jwtToken(
    forUserAccount accountId: String,
    memo: UInt64? = nil,
    signers: [KeyPair],
    homeDomain: String? = nil,
    clientDomain: String? = nil,
    clientDomainAccountKeyPair: KeyPair? = nil,
    clientDomainSigningFunction: ((_ :String) async throws -> String)? = nil
) async -> GetJWTTokenResponseEnum
```

Returns `GetJWTTokenResponseEnum` — either `.success(jwtToken: String)` or `.failure(error: GetJWTTokenError)`.

---

## Standard Authentication

For a single-signature account. The account does not need to exist on-chain — SEP-10 only proves key ownership.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let userKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["STELLAR_SECRET_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair]
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

The optional `homeDomain` parameter overrides the anchor's home domain in the challenge request. Use when an auth server handles multiple home domains:

```swift
let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair],
    homeDomain: "other-domain.com"
)
```

---

## Multi-Signature Authentication

For accounts that require multiple signers. Provide all required keypairs in the `signers` array — the combined weight must satisfy the server's requirements.

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "testanchor.stellar.org"
)

let signer1 = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SEED_1"]!)
let signer2 = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SEED_2"]!)

// Both signers sign the challenge. Combined weight must meet the server threshold.
let jwtResult = await webAuth.jwtToken(
    forUserAccount: signer1.accountId,
    signers: [signer1, signer2]
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

---

## Memo-Based Authentication

For services that distinguish users sharing a single Stellar account via an integer memo. The `memo` parameter is a `UInt64`.

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "testanchor.stellar.org"
)

let sharedAccountKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SHARED_SEED"]!)
let userId: UInt64 = 19989123

let jwtResult = await webAuth.jwtToken(
    forUserAccount: sharedAccountKeyPair.accountId,  // G... address
    memo: userId,
    signers: [sharedAccountKeyPair]
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT for user \(userId): \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

**Important:** `memo` only works with G... (non-muxed) account IDs. Passing a memo together with an M... address results in a `.failure(error: .requestError(...))` because the server rejects the request before a challenge is issued.

---

## Muxed Account Authentication

Muxed accounts (M... addresses) embed a user ID into the account address. Pass the M... address as `forUserAccount` and the underlying G... keypair in `signers`.

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "testanchor.stellar.org"
)

let baseKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["STELLAR_SECRET_SEED"]!)
let muxedAccountId = "MC6PZZU7XEYLCV7XW5LZC3J72HKQ7CABZCLVGPXCPLLRPZ4SJHC2UAAAAAAACMICQPLEG"

let jwtResult = await webAuth.jwtToken(
    forUserAccount: muxedAccountId,  // M... address
    signers: [baseKeyPair]           // sign with the underlying G... key
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

```swift
// WRONG: memo with M... address — server rejects the challenge request
let jwtResult = await webAuth.jwtToken(
    forUserAccount: muxedAccountId,  // M... address
    memo: 12345,                     // ERROR: mutually exclusive with M... address
    signers: [baseKeyPair]
)
// → .failure(error: .requestError(...))

// CORRECT: use one or the other, never both
// Option A: muxed account (no memo)
let jwtResult = await webAuth.jwtToken(forUserAccount: muxedAccountId, signers: [baseKeyPair])
// Option B: G... address with memo
let jwtResult = await webAuth.jwtToken(forUserAccount: gAddress, memo: 12345, signers: [baseKeyPair])
```

---

## Client Domain Verification

Non-custodial wallets can prove their identity to anchors by including a client domain signature. The anchor's server verifies that the wallet's `stellar.toml` publishes the `SIGNING_KEY` used to sign the challenge.

### Local signing (wallet holds the key)

Provide `clientDomain` and `clientDomainAccountKeyPair` with a secret key. The SDK signs the challenge directly.

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "testanchor.stellar.org"
)

let userKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["USER_SEED"]!)

// This keypair must have a private key for local signing
let clientDomainKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["CLIENT_DOMAIN_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: clientDomainKeyPair  // has private key → signs locally
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

### Remote signing via callback (recommended for production)

When the wallet's signing key lives on a server, provide a public-key-only `clientDomainAccountKeyPair` and a `clientDomainSigningFunction`. The SDK calls the function with the base64-encoded transaction XDR and expects the signed transaction back as base64-encoded XDR.

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "testanchor.stellar.org"
)

let userKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["USER_SEED"]!)

// Public-key-only keypair — no private key, triggers use of signing function
let clientDomainSigningKey = "GBWW7NMWWIKPDEWZZKTTCSUGV2ZMVN23IZ5JFOZ4FWZBNVQNHMU47HOR"
let clientDomainAccountKeyPair = try KeyPair(accountId: clientDomainSigningKey)

// Signing function: receives base64 XDR, returns signed base64 XDR
let signingFunction: (String) async throws -> String = { transactionXdr in
    guard let url = URL(string: "https://signing-server.mywallet.com/sign-sep-10") else {
        throw NSError(domain: "MyWallet", code: 1)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(ProcessInfo.processInfo.environment["SIGNING_TOKEN"]!)",
                     forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
        "transaction": transactionXdr,
        "network_passphrase": "Test SDF Network ; September 2015"
    ])

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let signedTx = json["transaction"] as? String else {
        throw NSError(domain: "MyWallet", code: 2)
    }
    return signedTx
}

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: clientDomainAccountKeyPair,  // public key only
    clientDomainSigningFunction: signingFunction              // handles actual signing
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

**Decision rule for `clientDomainAccountKeyPair`:**
- If `clientDomainAccountKeyPair.privateKey != nil` → SDK signs locally (ignores `clientDomainSigningFunction`)
- If `clientDomainAccountKeyPair.privateKey == nil` → SDK calls `clientDomainSigningFunction`

---

## Result Enums Reference

All WebAuthenticator operations return custom result enums — not Swift `Result<T, E>`. Pattern-match with `switch`.

### WebAuthenticatorForDomainEnum

Returned by `WebAuthenticator.from(domain:network:)`.

```swift
public enum WebAuthenticatorForDomainEnum {
    case success(response: WebAuthenticator)
    case failure(error: WebAuthenticatorError)
}
```

### ChallengeResponseEnum

Returned by `getChallenge(forAccount:memo:homeDomain:clientDomain:)`.

```swift
public enum ChallengeResponseEnum {
    case success(challenge: String)       // base64-encoded XDR challenge transaction
    case failure(error: HorizonRequestError)
}
```

### ChallengeValidationResponseEnum

Returned by `isValidChallenge(transactionEnvelopeXDR:userAccountId:memo:serverSigningKey:clientDomainAccount:timeBoundsGracePeriod:)`.

```swift
public enum ChallengeValidationResponseEnum {
    case success
    case failure(error: ChallengeValidationError)
}
```

### SendChallengeResponseEnum

Returned by `sendCompletedChallenge(base64EnvelopeXDR:)`.

```swift
public enum SendChallengeResponseEnum {
    case success(jwtToken: String)
    case failure(error: HorizonRequestError)
}
```

### GetJWTTokenResponseEnum

Returned by `jwtToken(forUserAccount:signers:)` — the primary API.

```swift
public enum GetJWTTokenResponseEnum: Sendable {
    case success(jwtToken: String)
    case failure(error: GetJWTTokenError)
}
```

---

## Error Types Reference

### WebAuthenticatorError

Returned when `WebAuthenticator.from(domain:network:)` fails.

```swift
public enum WebAuthenticatorError: Error {
    case invalidDomain    // domain string is not a valid URL or domain format
    case invalidToml      // stellar.toml could not be parsed or is malformed
    case noAuthEndpoint   // stellar.toml does not specify WEB_AUTH_ENDPOINT (or SIGNING_KEY missing)
}
```

### GetJWTTokenError

Top-level error from `jwtToken()`. Each case wraps the underlying cause.

```swift
public enum GetJWTTokenError: Error {
    case requestError(HorizonRequestError)           // network/server error during GET or POST
    case parsingError(Error)                         // failed to parse challenge XDR or server response
    case validationErrorError(ChallengeValidationError) // challenge failed security validation
    case signingError                                // transaction signing failed (bad keypair)
}
```

### ChallengeValidationError

Challenge validation failures wrapped in `.validationErrorError`. All are protocol violations or security issues.

```swift
public enum ChallengeValidationError: Error {
    case sequenceNumberNot0        // SECURITY: seq number != 0 — could be executable transaction
    case invalidSourceAccount      // wrong source account on an operation
    case sourceAccountNotFound     // an operation has no source account field
    case invalidOperationType      // SECURITY: non-ManageData operation in challenge
    case invalidOperationCount     // zero operations in challenge transaction
    case invalidHomeDomain         // first op key != "<serverHomeDomain> auth"
    case invalidTimeBounds         // challenge expired or not yet valid
    case invalidSignature          // server signature on challenge is invalid
    case signatureNotFound         // challenge has != 1 signature (before client signing)
    case validationFailure         // generic validation failure (malformed XDR, etc.)
    case invalidTransactionType    // fee-bump transactions not allowed for SEP-10
    case invalidWebAuthDomain      // web_auth_domain op value != auth endpoint host
    case memoAndMuxedSourceAccountFound  // challenge has both memo and M... source account
    case invalidMemoType           // memo in challenge is not MEMO_TYPE_ID
    case invalidMemoValue          // memo value in challenge doesn't match requested value
}
```

### Full error handling example

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let keyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["STELLAR_SECRET_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forUserAccount: keyPair.accountId,
    signers: [keyPair]
)

switch jwtResult {
case .success(let jwtToken):
    print("Authenticated! JWT: \(jwtToken)")

case .failure(let error):
    switch error {
    case .requestError(let horizonError):
        // Network or server error during challenge GET or signed challenge POST
        print("Request failed: \(horizonError)")

    case .parsingError(let parseError):
        // Could not decode the challenge transaction XDR or server response
        print("Parsing failed: \(parseError)")

    case .signingError:
        // Transaction signing failed — keypair may lack a private key
        print("Signing failed — check that all signers have secret keys")

    case .validationErrorError(let validationError):
        switch validationError {
        case .sequenceNumberNot0:
            // SECURITY RISK: Do not sign this transaction — it could be executable
            print("SECURITY: challenge has non-zero sequence number")
        case .invalidOperationType:
            // SECURITY RISK: Non-ManageData operation could transfer funds
            print("SECURITY: challenge contains non-ManageData operation")
        case .invalidSignature:
            print("Server signature invalid — verify stellar.toml SIGNING_KEY matches network")
        case .signatureNotFound:
            print("Challenge missing server signature")
        case .invalidTimeBounds:
            print("Challenge expired — retry to get a fresh challenge")
        case .invalidHomeDomain:
            print("Home domain mismatch in challenge")
        case .invalidWebAuthDomain:
            print("web_auth_domain mismatch in challenge")
        case .invalidSourceAccount:
            print("Invalid source account on challenge operation")
        case .sourceAccountNotFound:
            print("Challenge operation missing source account")
        case .invalidOperationCount:
            print("Challenge has zero operations")
        case .memoAndMuxedSourceAccountFound:
            print("Challenge has both memo and muxed source account")
        case .invalidMemoType:
            print("Memo in challenge is not MEMO_TYPE_ID")
        case .invalidMemoValue:
            print("Memo value in challenge doesn't match requested value")
        case .invalidTransactionType:
            print("Fee-bump transaction used in challenge (not allowed)")
        case .validationFailure:
            print("Challenge validation failed: malformed XDR or unexpected structure")
        }
    }
}
```

---

## Mock Testing Patterns

For unit tests, use the `WebAuthenticator` direct initializer with pre-configured test data. The SDK uses `URLProtocol` mock infrastructure — register mock handlers before creating the authenticator.

The unit test file in the SDK provides this pattern. The key idea is to construct the `WebAuthenticator` manually and register mock server responses via `URLProtocol.registerClass(ServerMock.self)`.

### Manually building a valid challenge transaction for tests

When you need to construct a challenge response that will pass validation:

```swift
import stellarsdk

// In test setup
let serverKeyPair = try KeyPair.generateRandomKeyPair()
let clientKeyPair = try KeyPair.generateRandomKeyPair()
let serverHomeDomain = "place.domain.com"
let authServer = "http://api.stellar.org/auth"

// Build challenge (mimics what the auth server produces)
// 1. Server account starts at sequence -1 so first operation sets it to 0
let serverAccount = try Account(
    accountId: serverKeyPair.accountId,
    sequenceNumber: -1
)

let now = UInt64(Date().timeIntervalSince1970)

// First ManageData op: key = "<homeDomain> auth", source = client account
let authOp = try ManageDataOperation(
    sourceAccountId: clientKeyPair.accountId,
    name: serverHomeDomain + " auth",
    data: Data(randomBytes(64))  // 64-byte random nonce
)

// Second ManageData op: key = "web_auth_domain", source = server key, value = auth endpoint host
let webAuthDomainOp = try ManageDataOperation(
    sourceAccountId: serverKeyPair.accountId,
    name: "web_auth_domain",
    data: "api.stellar.org".data(using: .utf8)
)

let transaction = try Transaction(
    sourceAccount: serverAccount,
    operations: [authOp, webAuthDomainOp],
    memo: Memo.none,
    timeBounds: TimeBounds(minTime: now - 1, maxTime: now + 300),
    maxOperationFee: 100
)
try transaction.sign(keyPair: serverKeyPair, network: Network.testnet)
let challengeXdr = try transaction.encodedEnvelope()

// The WebAuthenticator to test
let webAuth = WebAuthenticator(
    authEndpoint: authServer,
    network: Network.testnet,
    serverSigningKey: serverKeyPair.accountId,
    serverHomeDomain: serverHomeDomain
)
```

### Calling isValidChallenge directly

For testing validation logic without network calls:

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "http://api.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: serverPublicKey,
    serverHomeDomain: "place.domain.com"
)

let transactionEnvelope = try TransactionEnvelopeXDR(xdr: challengeXdr)

let validationResult = webAuth.isValidChallenge(
    transactionEnvelopeXDR: transactionEnvelope,
    userAccountId: clientKeyPair.accountId,
    memo: nil,
    serverSigningKey: serverPublicKey,
    clientDomainAccount: nil,
    timeBoundsGracePeriod: 300
)

switch validationResult {
case .success:
    print("Challenge is valid")
case .failure(let error):
    print("Challenge invalid: \(error)")
}
```

### Calling signTransaction directly

```swift
import stellarsdk

let envelope = try TransactionEnvelopeXDR(xdr: challengeXdr)
let signedXdr = webAuth.signTransaction(
    transactionEnvelopeXDR: envelope,
    keyPairs: [clientKeyPair]
)
// signedXdr is String? — nil if signing fails
```

### Calling sendCompletedChallenge directly

```swift
import stellarsdk

let response = await webAuth.sendCompletedChallenge(base64EnvelopeXDR: signedXdr)
switch response {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Submit failed: \(error)")
}
```

---

## Common Pitfalls

**Wrong: memo with M... address**

```swift
// WRONG: memo cannot be used with a muxed (M...) account ID
// Server rejects the challenge GET request before any validation happens
let jwtResult = await webAuth.jwtToken(
    forUserAccount: "MC6PZZU7XEYLCV7XW5LZC3J72HKQ7CABZCLVGPXCPLLRPZ4SJHC2UAAAAAAACMICQPLEG",
    memo: 12345,  // ERROR: mutually exclusive with M... address
    signers: [keyPair]
)
// → .failure(error: .requestError(...))

// CORRECT: use muxed account without memo, OR G... address with memo
let jwtResult = await webAuth.jwtToken(
    forUserAccount: "M...",  // muxed account (no memo)
    signers: [keyPair]
)
let jwtResult = await webAuth.jwtToken(
    forUserAccount: "G...",  // G... address with memo
    memo: 12345,
    signers: [keyPair]
)
```

**Wrong: network mismatch causes invalid signature**

```swift
// WRONG: authenticator network must match the network the server signed with
// The challenge XDR is valid but signature verification fails because
// the transaction hash depends on the network passphrase
let webAuth = WebAuthenticator(
    authEndpoint: "https://anchor.example.com/auth",
    network: .public,       // ← WRONG if server is on testnet
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "anchor.example.com"
)
// → .failure(error: .validationErrorError(.invalidSignature))

// CORRECT: match the network to the anchor's actual deployment
let webAuth = WebAuthenticator(
    authEndpoint: "https://anchor.example.com/auth",
    network: Network.testnet,      // ← matches the server
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "anchor.example.com"
)
```

**Wrong: using public-only KeyPair for signing**

```swift
// WRONG: KeyPair(accountId:) creates a public-only keypair — cannot sign
let publicOnly = try KeyPair(accountId: "GABC...")
let jwtResult = await webAuth.jwtToken(
    forUserAccount: "GABC...",
    signers: [publicOnly]  // ERROR: no private key → signingError
)
// → .failure(error: .signingError)

// CORRECT: load from secret seed for signing
let signingKeyPair = try KeyPair(secretSeed: "SABC...")
let jwtResult = await webAuth.jwtToken(
    forUserAccount: signingKeyPair.accountId,
    signers: [signingKeyPair]
)
```

**Wrong: `clientDomainAccountKeyPair` with public-key-only but no signing function**

```swift
// WRONG: public-key-only clientDomainAccountKeyPair without a signing function
// The SDK has no way to sign the client domain operation
let publicKeyPair = try KeyPair(accountId: "GCLIENTDOMAIN...")
let jwtResult = await webAuth.jwtToken(
    forUserAccount: userAccountId,
    signers: [userKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: publicKeyPair
    // no clientDomainSigningFunction provided
)
// Challenge validation passes, but client domain signature is missing from the submission

// CORRECT: provide signing function when keypair has no private key
let jwtResult = await webAuth.jwtToken(
    forUserAccount: userAccountId,
    signers: [userKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: publicKeyPair,
    clientDomainSigningFunction: { txXdr in
        // sign on remote server and return signed XDR
        return try await signOnServer(txXdr)
    }
)
```

**Security: treat sequenceNumberNot0 and invalidOperationType as fatal**

```swift
// These two errors indicate potential malicious server behavior.
// A non-zero sequence number means the challenge could execute a real transaction.
// A non-ManageData operation could transfer funds or modify account settings.
// NEVER retry or ignore these — abort and alert the user.
switch jwtResult {
case .failure(.validationErrorError(.sequenceNumberNot0)):
    // SECURITY RISK: this challenge could execute a real transaction if signed
    fatalError("SECURITY: auth server sent non-zero sequence number")
case .failure(.validationErrorError(.invalidOperationType)):
    // SECURITY RISK: challenge may contain a payment or dangerous operation
    fatalError("SECURITY: auth server sent non-ManageData operation")
default:
    break
}
```

**Wrong: checking serverHomeDomain format**

```swift
// WRONG: serverHomeDomain should be the domain only (no https://)
// The SDK validates: first op key == serverHomeDomain + " auth"
let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "https://testanchor.stellar.org"  // WRONG: includes scheme
)
// → .failure(error: .validationErrorError(.invalidHomeDomain))

// CORRECT: domain only, no scheme
let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ...",
    serverHomeDomain: "testanchor.stellar.org"  // domain only
)
```

---

## JWT Token Structure

The JWT returned by `jwtToken()` is a standard JSON Web Token. The SDK returns it as a plain `String` and does not decode it. Use any JWT library or [jwt.io](https://jwt.io) to inspect claims.

Standard claims:

| Claim | Description |
|-------|-------------|
| `sub` | Authenticated account: G... address, M... address, or `G...:memo` for memo auth |
| `iss` | Token issuer (the authentication server URL) |
| `iat` | Issued-at timestamp (Unix epoch) |
| `exp` | Expiration timestamp (typically 24 hours after `iat`) |
| `client_domain` | Present when client domain verification was performed |

Pass the token as a `Bearer` header for authenticated anchor APIs (SEP-6, SEP-12, SEP-24, SEP-31, etc.):

```swift
var request = URLRequest(url: URL(string: "https://anchor.example.com/sep24/transactions")!)
request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
let (data, _) = try await URLSession.shared.data(for: request)
```

---

## Related SEPs

- [sep-01.md](sep-01.md) — stellar.toml discovery (provides `WEB_AUTH_ENDPOINT` and `SIGNING_KEY`)
- [sep-06.md](sep-06.md) — Deposit/Withdrawal API (requires SEP-10 JWT)
- [sep-12.md](sep-12.md) — KYC API (requires SEP-10 JWT)
- [sep-24.md](sep-24.md) — Interactive Deposit/Withdrawal (requires SEP-10 JWT)
- [sep-45.md](sep-45.md) — Web Authentication for Soroban Contract Accounts
