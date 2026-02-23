# SEP-45: Web Authentication for Contract Accounts

**Purpose:** Authenticate Soroban contract accounts (C... addresses) and obtain JWT tokens for SEP-compliant services (SEP-6, SEP-12, SEP-24, SEP-31, etc.)
**Prerequisites:** Requires SEP-01 to discover `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`, and `SIGNING_KEY` (see sep-01.md)
**SDK Class:** `WebAuthForContracts`

SEP-45 extends SEP-10 to support Soroban contract accounts. Instead of signing a transaction, the client signs Soroban authorization entries that call the contract's `web_auth_verify` function.

## Table of Contents

- [Quick Start](#quick-start)
- [Creating WebAuthForContracts](#creating-webauthforcontracts)
- [jwtToken() — the Complete Flow](#jwttoken--the-complete-flow)
- [Standard Authentication](#standard-authentication)
- [Multi-Signature Authentication](#multi-signature-authentication)
- [Contracts Without Signature Requirements](#contracts-without-signature-requirements)
- [Client Domain Verification](#client-domain-verification)
- [Advanced: Lower-Level API](#advanced-lower-level-api)
- [Result Enums Reference](#result-enums-reference)
- [Error Types Reference](#error-types-reference)
- [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```swift
import stellarsdk

// 1. Initialize from anchor domain (reads stellar.toml automatically)
let authResult = await WebAuthForContracts.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// 2. Get JWT token for contract account
let contractId = "CABC..."           // C... address
let signerKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SIGNER_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signerKeyPair]
)
guard case .success(let jwtToken) = jwtResult else { return }

// 3. Use JWT for SEP-12, SEP-24, etc.
print("Authenticated! Token: \(jwtToken)")
```

---

## Creating WebAuthForContracts

### From domain (recommended)

`WebAuthForContracts.from(domain:network:)` fetches the anchor's `stellar.toml`, reads
`WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`, and `SIGNING_KEY`, and returns a
configured `WebAuthForContracts` instance.

```swift
import stellarsdk

let result = await WebAuthForContracts.from(domain: "testanchor.stellar.org", network: Network.testnet)
switch result {
case .success(let webAuth):
    print("Auth endpoint: \(webAuth.authEndpoint)")
    print("Web auth contract ID: \(webAuth.webAuthContractId)")
    print("Server signing key: \(webAuth.serverSigningKey)")
    print("Soroban RPC URL: \(webAuth.sorobanRpcUrl ?? "default")")
case .failure(let error):
    switch error {
    case .invalidDomain:
        print("The domain string is not a valid URL or domain format")
    case .invalidToml:
        print("stellar.toml could not be parsed or is malformed")
    case .noAuthEndpoint:
        print("stellar.toml does not specify WEB_AUTH_FOR_CONTRACTS_ENDPOINT")
    case .noWebAuthContractId:
        print("stellar.toml does not specify WEB_AUTH_CONTRACT_ID")
    case .noSigningKey:
        print("stellar.toml does not specify SIGNING_KEY")
    default:
        print("Initialization error: \(error)")
    }
}
```

Method signature:
```swift
static func from(domain: String, network: Network, secure: Bool = true) async -> WebAuthForContractsForDomainEnum
```

The `secure` parameter defaults to `true` (HTTPS). Set to `false` only for local development.

### Manual construction

Use when you already have the endpoint, contract ID, and signing key (e.g., you loaded stellar.toml separately or are writing tests).

```swift
import stellarsdk

let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",          // C... address
    serverSigningKey: "GABCDEF...",        // G... address from stellar.toml SIGNING_KEY
    serverHomeDomain: "testanchor.stellar.org",
    network: Network.testnet
)
```

Constructor signature:
```swift
init(
    authEndpoint: String,
    webAuthContractId: String,
    serverSigningKey: String,
    serverHomeDomain: String,
    network: Network,
    sorobanRpcUrl: String? = nil   // defaults to network default if nil
) throws
```

The constructor validates parameters and throws `WebAuthForContractsError` if any are invalid:
- `webAuthContractId` must start with `C`
- `serverSigningKey` must start with `G`
- `authEndpoint` must be a valid URL with scheme and host
- `serverHomeDomain` must be non-empty

Public properties on `WebAuthForContracts`:
- `authEndpoint: String` — the SEP-45 authentication endpoint URL
- `webAuthContractId: String` — the web auth contract address (C...)
- `serverSigningKey: String` — the server's public signing key (G...)
- `serverHomeDomain: String` — the home domain hosting stellar.toml
- `network: Network` — the Stellar network used for authentication
- `useFormUrlEncoded: Bool` — whether to POST as form-urlencoded (default: `true`) or JSON
- `sorobanRpcUrl: String?` — Soroban RPC URL (auto-set from network if not provided)

Default RPC URLs set by the constructor:
- `Network.testnet` → `https://soroban-testnet.stellar.org`
- `Network.public` → `https://soroban.stellar.org`

---

## jwtToken() — the Complete Flow

`jwtToken(forContractAccount:signers:)` performs all SEP-45 steps internally:

1. Requests challenge authorization entries from the server (GET)
2. Validates the challenge (contract address, function name `web_auth_verify`, args map, nonces, server signature)
3. If `signers` is non-empty and `signatureExpirationLedger` is nil, fetches current ledger from Soroban RPC and sets expiration to `current + 10`
4. Signs the authorization entries with the provided keypairs
5. Submits signed entries to the server (POST) as `application/x-www-form-urlencoded` (or JSON if `useFormUrlEncoded = false`)
6. Returns the JWT token string

Method signature:
```swift
func jwtToken(
    forContractAccount clientAccountId: String,
    signers: [KeyPair],
    homeDomain: String? = nil,
    clientDomain: String? = nil,
    clientDomainAccountKeyPair: KeyPair? = nil,
    clientDomainSigningCallback: ((SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR)? = nil,
    signatureExpirationLedger: UInt32? = nil
) async -> GetContractJWTTokenResponseEnum
```

Returns `GetContractJWTTokenResponseEnum` — either `.success(jwtToken: String)` or `.failure(error: GetContractJWTTokenError)`.

---

## Standard Authentication

For a single-signer contract account:

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let contractId = "CABC..."
let signerKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SIGNER_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signerKeyPair]
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
    forContractAccount: contractId,
    signers: [signerKeyPair],
    homeDomain: "other-domain.com"
)
```

---

## Multi-Signature Authentication

For contracts that require multiple signers. Provide all required keypairs in the `signers` array — the SDK adds each signature to the client authorization entry. Combined weight must satisfy the contract's `__check_auth` requirements.

```swift
import stellarsdk

let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "testanchor.stellar.org",
    network: Network.testnet
)

let signer1 = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SEED_1"]!)
let signer2 = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SEED_2"]!)

let jwtResult = await webAuth.jwtToken(
    forContractAccount: "CABC...",
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

## Contracts Without Signature Requirements

Some contracts implement `__check_auth` in a way that does not require keypair signatures (e.g., custom auth logic based on state). Pass an empty `signers` array — the SDK will not attempt to sign and will not fetch the current ledger for expiration.

```swift
import stellarsdk

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: []  // No signatures required
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

---

## Client Domain Verification

Non-custodial wallets can prove their identity to anchors by including a client domain signature. The auth server verifies the wallet's `SIGNING_KEY` from stellar.toml.

The `clientDomainSigningCallback` receives a `SorobanAuthorizationEntryXDR` and must return the signed entry.

### Local signing (wallet holds the key)

```swift
import stellarsdk

let clientDomainKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["CLIENT_DOMAIN_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signerKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: clientDomainKeyPair  // has private key → signs locally
)
```

When `clientDomainAccountKeyPair` has a private key, the SDK uses it directly to sign the client domain authorization entry.

### Remote signing via callback (recommended for production)

When the wallet's signing key lives on a server, provide `clientDomainAccountKeyPair` (public key only) and a `clientDomainSigningCallback`. The SDK calls the callback with the unsigned entry and expects the signed entry back.

```swift
import stellarsdk

// Public-key-only — triggers use of signing callback
let clientDomainAccountKeyPair = try KeyPair(accountId: "GCLIENTDOMAIN...")

let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
    // Encode entry to base64 XDR, send to remote server, decode signed entry back
    let encodedBytes = try XDREncoder.encode(entry)
    let entryXdr = Data(encodedBytes).base64EncodedString()

    guard let url = URL(string: "https://signing-server.mywallet.com/sign-sep-45") else {
        throw NSError(domain: "MyWallet", code: 1)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["entry": entryXdr])

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let signedXdr = json["entry"] as? String,
          let xdrData = Data(base64Encoded: signedXdr) else {
        throw NSError(domain: "MyWallet", code: 2)
    }

    let decoder = XDRDecoder(data: xdrData)
    return try SorobanAuthorizationEntryXDR(from: decoder)
}

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signerKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: clientDomainAccountKeyPair,
    clientDomainSigningCallback: signingCallback
)

switch jwtResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Auth failed: \(error)")
}
```

**Decision rule for client domain signing in `jwtToken()`:**
- If `clientDomainAccountKeyPair` has a private key → SDK signs the entry directly
- If `clientDomainAccountKeyPair` is public-only → SDK calls `clientDomainSigningCallback`
- If neither is provided → SDK fetches the `SIGNING_KEY` from the client domain's stellar.toml (callback required in that case)

---

## Advanced: Lower-Level API

The `jwtToken()` method composes these lower-level methods. Use them directly only for testing or custom flows.

### getChallenge

Fetches challenge authorization entries from the authentication server.

```swift
import stellarsdk

let challengeResult = await webAuth.getChallenge(
    forContractAccount: contractId,
    homeDomain: nil,           // defaults to serverHomeDomain
    clientDomain: nil          // omit for standard auth
)

switch challengeResult {
case .success(let response):
    print("Entries XDR: \(response.authorizationEntries)")
    print("Network passphrase: \(response.networkPassphrase ?? "none")")
case .failure(let error):
    print("Challenge request failed: \(error)")
}
```

Method signature:
```swift
func getChallenge(
    forContractAccount clientAccountId: String,
    homeDomain: String? = nil,
    clientDomain: String? = nil
) async -> GetContractChallengeResponseEnum
```

### decodeAuthorizationEntries

Decodes the base64 XDR string from the challenge response into an array of `SorobanAuthorizationEntryXDR`.

```swift
import stellarsdk

let entries = try webAuth.decodeAuthorizationEntries(base64Xdr: response.authorizationEntries)
// → [SorobanAuthorizationEntryXDR]
```

Method signature:
```swift
func decodeAuthorizationEntries(base64Xdr: String) throws -> [SorobanAuthorizationEntryXDR]
```

### validateChallenge

Validates decoded authorization entries against SEP-45 security requirements.

```swift
import stellarsdk

// Throws ContractChallengeValidationError if invalid
try webAuth.validateChallenge(
    authEntries: entries,
    clientAccountId: contractId,
    homeDomain: nil,                  // defaults to serverHomeDomain
    clientDomainAccountId: nil        // provide if client domain is expected
)
```

Method signature:
```swift
func validateChallenge(
    authEntries: [SorobanAuthorizationEntryXDR],
    clientAccountId: String,
    homeDomain: String? = nil,
    clientDomainAccountId: String? = nil
) throws
```

Validation checks performed:
1. Entries array is non-empty
2. No sub-invocations in any entry
3. Each entry invokes a contract function (not sourceAccount)
4. Contract address matches `webAuthContractId`
5. Function name is `"web_auth_verify"`
6. Args map contains: `account`, `home_domain`, `web_auth_domain`, `web_auth_domain_account`, `nonce`
7. `account` matches `clientAccountId`
8. `home_domain` matches the effective home domain
9. `web_auth_domain` matches the auth endpoint host (including port if non-standard)
10. `web_auth_domain_account` matches `serverSigningKey`
11. `nonce` is consistent across all entries
12. Server entry exists and has a valid server signature
13. Client entry exists (credentials address matches `clientAccountId`)
14. Client domain entry exists if `clientDomainAccountId` was provided

### signAuthorizationEntries

Signs authorization entries with provided keypairs.

```swift
import stellarsdk

let signedEntries = try await webAuth.signAuthorizationEntries(
    authEntries: entries,
    clientAccountId: contractId,
    signers: [signerKeyPair],
    signatureExpirationLedger: 12345678,   // UInt32 or nil
    clientDomainKeyPair: nil,
    clientDomainAccountId: nil,
    clientDomainSigningCallback: nil
)
```

Method signature:
```swift
func signAuthorizationEntries(
    authEntries: [SorobanAuthorizationEntryXDR],
    clientAccountId: String,
    signers: [KeyPair],
    signatureExpirationLedger: UInt32?,
    clientDomainKeyPair: KeyPair?,
    clientDomainAccountId: String?,
    clientDomainSigningCallback: ((SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR)?
) async throws -> [SorobanAuthorizationEntryXDR]
```

The method sets `signatureExpirationLedger` on the client entry credentials before signing. The server entry (already signed by the server) is passed through unchanged.

### sendSignedChallenge

Submits signed authorization entries to get a JWT token.

```swift
import stellarsdk

let submitResult = await webAuth.sendSignedChallenge(signedEntries: signedEntries)
switch submitResult {
case .success(let jwtToken):
    print("JWT: \(jwtToken)")
case .failure(let error):
    print("Submit failed: \(error)")
}
```

Method signature:
```swift
func sendSignedChallenge(signedEntries: [SorobanAuthorizationEntryXDR]) async -> SubmitContractChallengeResponseEnum
```

The signed entries are XDR-encoded, base64-encoded, and posted as `authorization_entries` in the request body. By default uses `application/x-www-form-urlencoded` (`useFormUrlEncoded = true`). Set `webAuth.useFormUrlEncoded = false` to use `application/json`.

---

## Result Enums Reference

All `WebAuthForContracts` operations return custom result enums — not Swift `Result<T, E>`. Pattern-match with `switch`.

### WebAuthForContractsForDomainEnum

Returned by `WebAuthForContracts.from(domain:network:)`.

```swift
public enum WebAuthForContractsForDomainEnum: Sendable {
    case success(response: WebAuthForContracts)
    case failure(error: WebAuthForContractsError)
}
```

### GetContractJWTTokenResponseEnum

Returned by `jwtToken(forContractAccount:signers:)` — the primary API.

```swift
public enum GetContractJWTTokenResponseEnum: Sendable {
    case success(jwtToken: String)
    case failure(error: GetContractJWTTokenError)
}
```

### GetContractChallengeResponseEnum

Returned by `getChallenge(forContractAccount:homeDomain:clientDomain:)`.

```swift
public enum GetContractChallengeResponseEnum: Sendable {
    case success(response: ContractChallengeResponse)
    case failure(error: GetContractJWTTokenError)
}
```

### SubmitContractChallengeResponseEnum

Returned by `sendSignedChallenge(signedEntries:)`.

```swift
public enum SubmitContractChallengeResponseEnum: Sendable {
    case success(jwtToken: String)
    case failure(error: GetContractJWTTokenError)
}
```

### ContractChallengeResponse

The struct returned in `GetContractChallengeResponseEnum.success`.

```swift
public struct ContractChallengeResponse: Decodable, Sendable {
    public let authorizationEntries: String   // base64 XDR array of SorobanAuthorizationEntry
    public let networkPassphrase: String?     // optional; verify against expected network
}
```

The decoder accepts both `snake_case` (`authorization_entries`, `network_passphrase`) and `camelCase` (`authorizationEntries`, `networkPassphrase`) JSON keys.

---

## Error Types Reference

### WebAuthForContractsError

Returned when `WebAuthForContracts.from(domain:network:)` or the constructor fails.

```swift
public enum WebAuthForContractsError: Error, Sendable {
    case invalidDomain                           // domain string is not a valid format
    case invalidToml                             // stellar.toml could not be parsed
    case noAuthEndpoint                          // stellar.toml missing WEB_AUTH_FOR_CONTRACTS_ENDPOINT
    case noWebAuthContractId                     // stellar.toml missing WEB_AUTH_CONTRACT_ID
    case noSigningKey                            // stellar.toml missing SIGNING_KEY
    case invalidWebAuthContractId(message: String)  // webAuthContractId does not start with 'C'
    case invalidServerSigningKey(message: String)   // serverSigningKey does not start with 'G'
    case invalidAuthEndpoint(message: String)       // authEndpoint is not a valid URL
    case emptyServerHomeDomain                   // serverHomeDomain is blank
    case invalidClientAccountId(message: String)
    case missingClientDomainSigningCallback
}
```

### GetContractJWTTokenError

Top-level error from `jwtToken()`. Each case wraps the underlying cause.

```swift
public enum GetContractJWTTokenError: Error, Sendable {
    case requestError(error: Error)                            // network/server error during GET or POST
    case challengeRequestError(message: String)                // server returned error during challenge GET
    case submitChallengeError(message: String)                 // server returned error during challenge POST
    case submitChallengeTimeout                                // HTTP 504 from challenge POST
    case submitChallengeUnknownResponse(statusCode: Int)       // unexpected HTTP status code
    case parsingError(message: String)                         // failed to parse server response or XDR
    case validationError(error: ContractChallengeValidationError) // challenge failed security validation
    case signingError(message: String)                         // signing authorization entries failed
}
```

### ContractChallengeValidationError

Challenge validation failures wrapped in `.validationError`. All represent security or protocol violations.

```swift
public enum ContractChallengeValidationError: Error, Sendable {
    case invalidContractAddress(expected: String, received: String)  // SECURITY: wrong web auth contract
    case invalidFunctionName(expected: String, received: String)     // function not "web_auth_verify"
    case subInvocationsFound                                         // SECURITY: sub-invocations not allowed
    case invalidHomeDomain(expected: String, received: String)       // home_domain arg mismatch
    case invalidWebAuthDomain(expected: String, received: String)    // web_auth_domain arg mismatch
    case invalidAccount(expected: String, received: String)          // account arg mismatch
    case invalidNonce(message: String)                               // nonce missing or inconsistent
    case invalidServerSignature                                      // SECURITY: server sig invalid
    case missingServerEntry                                          // no entry for server account
    case missingClientEntry                                          // no entry for client contract
    case invalidArgs(message: String)                                // malformed or missing args
    case invalidNetworkPassphrase(expected: String, received: String) // network passphrase mismatch
    case invalidClientDomainAccount(expected: String, received: String)
}
```

### Full error handling example

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let contractId = "CABC..."
let signerKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["SIGNER_SEED"]!)

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signerKeyPair]
)

switch jwtResult {
case .success(let jwtToken):
    print("Authenticated! JWT: \(jwtToken)")

case .failure(let error):
    switch error {
    case .requestError(let requestError):
        print("Request failed: \(requestError)")

    case .challengeRequestError(let message):
        print("Challenge request error: \(message)")

    case .parsingError(let message):
        print("Parsing failed: \(message)")

    case .signingError(let message):
        print("Signing failed: \(message)")

    case .submitChallengeError(let message):
        print("Submit failed: \(message)")

    case .submitChallengeTimeout:
        print("Auth server timed out (HTTP 504)")

    case .submitChallengeUnknownResponse(let statusCode):
        print("Unexpected HTTP status: \(statusCode)")

    case .validationError(let validationError):
        switch validationError {
        case .invalidContractAddress(let expected, let received):
            // SECURITY: challenge invokes a different contract than the web auth contract
            print("SECURITY: wrong contract. Expected \(expected), got \(received)")
        case .subInvocationsFound:
            // SECURITY: sub-invocations indicate the challenge tries to do more than auth
            print("SECURITY: challenge has sub-invocations")
        case .invalidServerSignature:
            print("Server signature invalid — verify stellar.toml SIGNING_KEY matches network")
        case .invalidNetworkPassphrase(let expected, let received):
            print("Network mismatch. Expected: \(expected), received: \(received)")
        case .missingServerEntry:
            print("Challenge is missing the server authorization entry")
        case .missingClientEntry:
            print("Challenge is missing the client authorization entry")
        case .invalidNonce(let message):
            print("Nonce error: \(message)")
        case .invalidFunctionName(_, let received):
            print("Challenge invokes wrong function: \(received)")
        case .invalidHomeDomain(let expected, let received):
            print("Home domain mismatch. Expected: \(expected), received: \(received)")
        case .invalidWebAuthDomain(let expected, let received):
            print("Web auth domain mismatch. Expected: \(expected), received: \(received)")
        case .invalidAccount(let expected, let received):
            print("Account mismatch. Expected: \(expected), received: \(received)")
        case .invalidArgs(let message):
            print("Invalid challenge args: \(message)")
        case .invalidClientDomainAccount(let expected, let received):
            print("Client domain account mismatch. Expected: \(expected), received: \(received)")
        }
    }
}
```

---

## Common Pitfalls

**Wrong: using a G... account ID instead of a C... contract address**

```swift
// WRONG: clientAccountId must be a contract address starting with 'C'
let jwtResult = await webAuth.jwtToken(
    forContractAccount: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",  // G... address
    signers: [signerKeyPair]
)
// → .failure(error: .parsingError(message: "Client account must be a contract address (C...)"))

// CORRECT: pass the contract account ID (C... address)
let jwtResult = await webAuth.jwtToken(
    forContractAccount: "CABC...",   // C... address
    signers: [signerKeyPair]
)
```

**Wrong: using WebAuthenticator (SEP-10) for contract accounts**

```swift
// WRONG: WebAuthenticator is for G... and M... accounts (SEP-10), not for C... contract accounts
let result = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
let jwtResult = await webAuth.jwtToken(
    forUserAccount: "CABC...",   // C... address does not work with WebAuthenticator
    signers: [signerKeyPair]
)

// CORRECT: use WebAuthForContracts for C... contract accounts (SEP-45)
let result = await WebAuthForContracts.from(domain: "testanchor.stellar.org", network: Network.testnet)
let jwtResult = await webAuth.jwtToken(
    forContractAccount: "CABC...",
    signers: [signerKeyPair]
)
```

**Wrong: network mismatch causes invalid server signature**

```swift
// WRONG: WebAuthForContracts network must match the server's deployment network
let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "testanchor.stellar.org",
    network: .public   // WRONG if server is on testnet
)
// → .failure(error: .validationError(.invalidServerSignature))
// or .failure(error: .validationError(.invalidNetworkPassphrase(...)))

// CORRECT: match the network to the anchor's actual deployment
let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "testanchor.stellar.org",
    network: Network.testnet  // matches the server
)
```

**Wrong: webAuthContractId does not start with 'C'**

```swift
// WRONG: the init throws if webAuthContractId doesn't start with 'C'
let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "GABC...",   // G... address is not a contract ID
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "testanchor.stellar.org",
    network: Network.testnet
)
// throws WebAuthForContractsError.invalidWebAuthContractId(message: ...)

// CORRECT: use a C... contract address for webAuthContractId
let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",   // C... contract address
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "testanchor.stellar.org",
    network: Network.testnet
)
```

**Wrong: serverHomeDomain includes URL scheme**

```swift
// WRONG: serverHomeDomain should be the bare domain (no https://)
// The SDK extracts the web_auth_domain from the authEndpoint URL host.
// If serverHomeDomain has a scheme prefix it will cause home_domain validation failure.
let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "https://testanchor.stellar.org",   // WRONG: has scheme
    network: Network.testnet
)
// → .failure(error: .validationError(.invalidHomeDomain(...)))

// CORRECT: domain only, no scheme
let webAuth = try WebAuthForContracts(
    authEndpoint: "https://testanchor.stellar.org/auth/contracts",
    webAuthContractId: "CABC...",
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "testanchor.stellar.org",   // bare domain
    network: Network.testnet
)
```

**Wrong: signers with public-key-only keypairs**

```swift
// WRONG: signing requires a private key; KeyPair(accountId:) creates a public-only keypair
let publicOnly = try KeyPair(accountId: "GABC...")
let jwtResult = await webAuth.jwtToken(
    forContractAccount: "CABC...",
    signers: [publicOnly]   // no private key → signingError
)
// → .failure(error: .signingError(message: ...))

// CORRECT: load from secret seed for signing
let signerKeyPair = try KeyPair(secretSeed: "SABC...")
let jwtResult = await webAuth.jwtToken(
    forContractAccount: "CABC...",
    signers: [signerKeyPair]
)
```

**Wrong: treating validateChallenge as async — it is synchronous**

```swift
// WRONG: validateChallenge is NOT async — no await needed
let result = await webAuth.validateChallenge(authEntries: entries, clientAccountId: "CABC...")

// CORRECT: validateChallenge throws synchronously
do {
    try webAuth.validateChallenge(authEntries: entries, clientAccountId: "CABC...")
} catch let error as ContractChallengeValidationError {
    print("Validation error: \(error)")
}
```

**Security: treat subInvocationsFound and invalidContractAddress as fatal**

```swift
// These errors indicate potential malicious server behavior.
// subInvocationsFound: the challenge is trying to call additional contracts
// invalidContractAddress: the challenge invokes a different contract, not the known web auth contract
switch jwtResult {
case .failure(.validationError(.subInvocationsFound)):
    // SECURITY RISK: do NOT submit this challenge
    fatalError("SECURITY: challenge has sub-invocations")
case .failure(.validationError(.invalidContractAddress(let expected, let received))):
    // SECURITY RISK: challenge targets an unknown contract
    fatalError("SECURITY: wrong contract in challenge. Expected \(expected), got \(received)")
default:
    break
}
```

**web_auth_domain includes port for non-standard ports**

The SDK extracts `web_auth_domain` from the `authEndpoint` URL. If the endpoint uses a non-standard port (not 80 or 443), the expected `web_auth_domain` in the challenge args will include the port (e.g., `auth.example.com:8080`). This is handled automatically — just make sure your auth endpoint URL is accurate.

---

## JWT Token Structure

The JWT returned by `jwtToken()` is a standard JSON Web Token. The SDK returns it as a plain `String` and does not decode it. Use any JWT library or [jwt.io](https://jwt.io) to inspect claims.

Standard claims for SEP-45:

| Claim | Description |
|-------|-------------|
| `sub` | Authenticated contract account (C... address) |
| `iss` | Token issuer (the authentication server URL) |
| `iat` | Issued-at timestamp (Unix epoch) |
| `exp` | Expiration timestamp (typically 24 hours after `iat`) |
| `client_domain` | Present when client domain verification was performed |

Pass the token as a `Bearer` header for authenticated anchor APIs:

```swift
var request = URLRequest(url: URL(string: "https://testanchor.stellar.org/sep24/transactions")!)
request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
let (data, _) = try await URLSession.shared.data(for: request)
```

---

## Related SEPs

- [sep-01.md](sep-01.md) — stellar.toml discovery (provides `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`, and `SIGNING_KEY`)
- [sep-10.md](sep-10.md) — Web Authentication for traditional G... and M... accounts
- [sep-06.md](sep-06.md) — Deposit/Withdrawal API (requires JWT)
- [sep-12.md](sep-12.md) — KYC API (requires JWT)
- [sep-24.md](sep-24.md) — Interactive Deposit/Withdrawal (requires JWT)
