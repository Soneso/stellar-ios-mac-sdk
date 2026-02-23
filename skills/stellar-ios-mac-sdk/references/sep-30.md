# SEP-30: Account Recovery

**Purpose:** Recover access to a Stellar account by registering identity verification methods with a recovery service and requesting transaction signatures on behalf of the account
**Prerequisites:** Requires SEP-10 for authentication (see sep-10.md)
**SDK Class:** `RecoveryService`

## Table of Contents

- [Quick Start](#quick-start)
- [Service Initialization](#service-initialization)
- [Building a Recovery Request](#building-a-recovery-request)
- [Register an Account](#register-an-account)
- [Update Identities](#update-identities)
- [Sign a Transaction](#sign-a-transaction)
- [Get Account Details](#get-account-details)
- [Delete an Account](#delete-an-account)
- [List Accessible Accounts](#list-accessible-accounts)
- [Response Objects](#response-objects)
- [Result Enums Reference](#result-enums-reference)
- [Error Handling](#error-handling)
- [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```swift
import stellarsdk

// 1. Initialize the recovery service
let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// 2. Build recovery identities (obtained via SEP-10 JWT)
let ownerAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
let ownerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [ownerAuth])
let request = Sep30Request(identities: [ownerIdentity])

// 3. Register the account
let responseEnum = await service.registerAccount(
    address: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(let account):
    // account.signers[0].key is the recovery service's signing key
    // Add this key as a signer on the Stellar account
    print("Recovery signer key: \(account.signers[0].key)")
case .failure(let error):
    print("Error: \(error)")
}
```

---

## Service Initialization

```swift
import stellarsdk

// Direct URL initialization (no stellar.toml lookup)
let service = RecoveryService(serviceAddress: "https://recovery.example.com")
```

`RecoveryService` init signature:
```swift
init(serviceAddress: String)
```

`serviceAddress` is the base URL of the SEP-30 recovery server. All API paths (`/accounts`, `/accounts/{address}/sign/{signingAddress}`, etc.) are appended to this base URL.

---

## Building a Recovery Request

A `Sep30Request` contains one or more `Sep30RequestIdentity` objects, each representing an entity that can authenticate to recover the account. Each identity has a role and one or more `Sep30AuthMethod` entries.

### Auth method types

| `type` | `value` format | Notes |
|--------|----------------|-------|
| `"stellar_address"` | G... address | Identity proven via SEP-10 |
| `"phone_number"` | E.164 format, e.g. `"+10000000001"` | Verified externally by the recovery server |
| `"email"` | e.g. `"person@example.com"` | Verified externally by the recovery server |

### Build request objects

```swift
import stellarsdk

// Auth methods for the sender identity
let senderAddrAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
let senderPhoneAuth = Sep30AuthMethod(type: "phone_number", value: "+10000000001")
let senderEmailAuth = Sep30AuthMethod(type: "email", value: "person1@example.com")

// Auth methods for the receiver identity
let receiverAddrAuth = Sep30AuthMethod(type: "stellar_address", value: "GDIL76BC2XGDWLDPXCZVYB3AIZX4MYBN6JUBQPAX5OHRWPSNX3XMLNCS")
let receiverPhoneAuth = Sep30AuthMethod(type: "phone_number", value: "+10000000002")
let receiverEmailAuth = Sep30AuthMethod(type: "email", value: "person2@example.com")

// Build identities
let senderIdentity = Sep30RequestIdentity(
    role: "sender",
    authMethods: [senderAddrAuth, senderPhoneAuth, senderEmailAuth]
)
let receiverIdentity = Sep30RequestIdentity(
    role: "receiver",
    authMethods: [receiverAddrAuth, receiverPhoneAuth, receiverEmailAuth]
)

// Wrap in the request
let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
```

`Sep30AuthMethod` init signature:
```swift
init(type: String, value: String)
```

`Sep30RequestIdentity` init signature:
```swift
init(role: String, authMethods: [Sep30AuthMethod])
```

`Sep30Request` init signature:
```swift
init(identities: [Sep30RequestIdentity])
```

The `role` field is not interpreted by the server — it is stored and returned verbatim. Use it to identify each identity in your client (common values: `"owner"`, `"sender"`, `"receiver"`).

---

## Register an Account

`POST /accounts/{address}` — registers a Stellar account with recovery identities for the first time. Returns a conflict error if the account is already registered.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

let ownerAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
let ownerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [ownerAuth])
let request = Sep30Request(identities: [ownerIdentity])

let responseEnum = await service.registerAccount(
    address: accountKeyPair.accountId,
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(let account):
    print("Registered account: \(account.address)")
    print("Identities: \(account.identities.count)")
    // Use the first signer key — most recently added
    if let signerKey = account.signers.first?.key {
        print("Recovery signer key: \(signerKey)")
        // Add this key as a signer to the Stellar account (see advanced.md for multi-sig)
    }
case .failure(let error):
    if case .conflict(let message) = error {
        print("Account already registered: \(message)")
    } else {
        print("Registration failed: \(error)")
    }
}
```

Method signature:
```swift
func registerAccount(address: String, request: Sep30Request, jwt: String) async -> Sep30AccountResponseEnum
```

---

## Update Identities

`PUT /accounts/{address}` — completely replaces the identities for a registered account. Existing identities are not merged — they are replaced entirely. To remove an identity, omit it from the request.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// New identities replace ALL existing ones — partial updates are not supported
let newOwnerAuth = Sep30AuthMethod(type: "email", value: "newemail@example.com")
let newOwnerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [newOwnerAuth])
let updateRequest = Sep30Request(identities: [newOwnerIdentity])

let responseEnum = await service.updateIdentitiesForAccount(
    address: accountKeyPair.accountId,
    request: updateRequest,
    jwt: jwtToken
)

switch responseEnum {
case .success(let account):
    print("Updated account: \(account.address)")
    print("New identity count: \(account.identities.count)")
case .failure(let error):
    print("Update failed: \(error)")
}
```

Method signature:
```swift
func updateIdentitiesForAccount(address: String, request: Sep30Request, jwt: String) async -> Sep30AccountResponseEnum
```

**Important:** Update replaces ALL identities. If you had an "owner" identity and send only a "sender" identity, the "owner" identity is removed.

---

## Sign a Transaction

`POST /accounts/{address}/sign/{signingAddress}` — requests the recovery service to sign a transaction XDR on behalf of the account. The recovery service verifies the JWT identity and returns a base64 signature plus the network passphrase it used.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Build and encode the recovery transaction (set signer back to original key, etc.)
let sdk = StellarSDK.testNet()
let accountEnum = await sdk.accounts.getAccountDetails(accountId: accountKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Example: add original keypair back as signer
// WRONG: Signer(key: SignerKey.ed25519PublicKey(...), weight:) — no such initializer
// CORRECT: Signer.ed25519PublicKey(keyPair:) static method + separate signerWeight: parameter
let addSignerOp = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: originalSignerAddress)),
    signerWeight: 1
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [addSignerOp],
    memo: Memo.none,
    maxOperationFee: 100
)

// Encode the transaction to XDR before requesting signature
let transactionXdr = try transaction.encodedEnvelope()

// signingAddress must be one of account.signers[].key returned at registration
let signEnum = await service.signTransaction(
    address: accountKeyPair.accountId,
    signingAddress: recoverySignerKey,  // from account.signers[0].key at registration
    transaction: transactionXdr,
    jwt: jwtToken
)

switch signEnum {
case .success(let signatureResponse):
    print("Signature: \(signatureResponse.signature)")
    print("Network passphrase: \(signatureResponse.networkPassphrase)")
    // Apply the signature to the transaction and submit
case .failure(let error):
    if case .notFound(let message) = error {
        print("Signer not found for this account: \(message)")
    } else {
        print("Sign failed: \(error)")
    }
}
```

Method signature:
```swift
func signTransaction(address: String, signingAddress: String, transaction: String, jwt: String) async -> Sep30SignatureResponseEnum
```

The `transaction` parameter must be base64-encoded XDR (the output of `transaction.encodedEnvelope()`).

The `signingAddress` must match one of the `key` values in `account.signers` returned when the account was registered. If it does not match, the service returns a `.notFound` error.

---

## Get Account Details

`GET /accounts/{address}` — returns the registered account's identities and signer keys. The `authenticated` field on each identity indicates whether the current JWT matches that identity.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

let responseEnum = await service.accountDetails(
    address: accountKeyPair.accountId,
    jwt: jwtToken
)

switch responseEnum {
case .success(let account):
    print("Account: \(account.address)")

    for identity in account.identities {
        let role = identity.role ?? "(no role)"
        let isAuthenticated = identity.authenticated ?? false
        print("  Identity role: \(role), authenticated: \(isAuthenticated)")
    }

    // Signers are ordered most-recently-added first
    for (i, signer) in account.signers.enumerated() {
        print("  Signer[\(i)]: \(signer.key)")
    }
case .failure(let error):
    if case .notFound(let message) = error {
        print("Account not registered: \(message)")
    } else {
        print("Lookup failed: \(error)")
    }
}
```

Method signature:
```swift
func accountDetails(address: String, jwt: String) async -> Sep30AccountResponseEnum
```

---

## Delete an Account

`DELETE /accounts/{address}` — permanently removes the account from the recovery service. This operation is irreversible. The response returns the last known state of the account before deletion.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

let responseEnum = await service.deleteAccount(
    address: accountKeyPair.accountId,
    jwt: jwtToken
)

switch responseEnum {
case .success(let account):
    // Returns the account details as they were before deletion
    print("Deleted account: \(account.address)")
case .failure(let error):
    if case .unauthorized(let message) = error {
        print("Not authorized to delete: \(message)")
    } else {
        print("Delete failed: \(error)")
    }
}
```

Method signature:
```swift
func deleteAccount(address: String, jwt: String) async -> Sep30AccountResponseEnum
```

---

## List Accessible Accounts

`GET /accounts` — returns all accounts the JWT token grants access to. Supports cursor-based pagination via the `after` parameter (an account address).

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Without pagination (first page)
let responseEnum = await service.accounts(jwt: jwtToken)

switch responseEnum {
case .success(let accountsResponse):
    print("Accessible accounts: \(accountsResponse.accounts.count)")
    for account in accountsResponse.accounts {
        print("  \(account.address)")
        for identity in account.identities {
            let authenticated = identity.authenticated ?? false
            print("    role: \(identity.role ?? "none"), authenticated: \(authenticated)")
        }
    }
case .failure(let error):
    print("List failed: \(error)")
}

// With pagination (cursor-based, pass the last account address as 'after')
let lastAddress = accountsResponse.accounts.last?.address
let nextPageEnum = await service.accounts(jwt: jwtToken, after: lastAddress)
```

Method signature:
```swift
func accounts(jwt: String, after: String? = nil) async -> Sep30AccountsResponseEnum
```

The `after` parameter is optional (defaults to `nil`, meaning start from the beginning). Pass the last account address from the previous page to retrieve the next page.

---

## Response Objects

### `Sep30AccountResponse`

Returned by `registerAccount`, `updateIdentitiesForAccount`, `accountDetails`, and `deleteAccount`.

```swift
public struct Sep30AccountResponse: Decodable, Sendable {
    public let address: String                      // Stellar G... account address
    public let identities: [SEP30ResponseIdentity]  // Configured identities (auth methods not exposed)
    public let signers: [SEP30ResponseSigner]        // Recovery service signer keys, newest first
}
```

### `SEP30ResponseIdentity`

```swift
public struct SEP30ResponseIdentity: Decodable, Sendable {
    public let role: String?          // "owner", "sender", "receiver", etc. (nil for GET /accounts)
    public let authenticated: Bool?   // true if the current JWT matches this identity; nil if not authenticated as this identity
}
```

`authenticated` is `nil` (not `false`) when the current JWT does not correspond to that identity. Check with `identity.authenticated == true` rather than `identity.authenticated ?? false` when distinguishing "authenticated" from "unknown".

### `SEP30ResponseSigner`

```swift
public struct SEP30ResponseSigner: Decodable, Sendable {
    public let key: String  // Public key the recovery service uses to sign transactions
}
```

`signers` are ordered most-recently-added first. Use `account.signers[0].key` as the current active signing key. When calling `signTransaction`, the `signingAddress` must match one of these key values.

### `Sep30AccountsResponse`

Returned by `accounts(jwt:after:)`.

```swift
public struct Sep30AccountsResponse: Decodable, Sendable {
    public let accounts: [Sep30AccountResponse]  // Accounts accessible by the authenticated JWT
}
```

### `Sep30SignatureResponse`

Returned by `signTransaction`.

```swift
public struct Sep30SignatureResponse: Decodable, Sendable {
    public let signature: String          // Base64 encoded signature from the recovery service's signing key
    public let networkPassphrase: String  // Network passphrase used during signing (JSON key: "network_passphrase")
}
```

---

## Result Enums Reference

All `RecoveryService` methods return custom result enums — not Swift `Result<T, E>`. Pattern-match with `switch`.

```swift
public enum Sep30AccountResponseEnum {
    case success(response: Sep30AccountResponse)
    case failure(error: RecoveryServiceError)
}

public enum Sep30SignatureResponseEnum {
    case success(response: Sep30SignatureResponse)
    case failure(error: RecoveryServiceError)
}

public enum Sep30AccountsResponseEnum {
    case success(response: Sep30AccountsResponse)
    case failure(error: RecoveryServiceError)
}
```

---

## Error Handling

All failure cases use `RecoveryServiceError`:

```swift
public enum RecoveryServiceError: Error {
    case badRequest(message: String)           // 400 — malformed request or missing fields
    case unauthorized(message: String)         // 401 — JWT missing, invalid, or expired
    case notFound(message: String)             // 404 — account or signer not found
    case conflict(message: String)             // 409 — account already registered
    case parsingResponseFailed(message: String) // SDK could not decode the server response
    case horizonError(error: HorizonRequestError) // Low-level network or HTTP error
}
```

Full error handling pattern:

```swift
import stellarsdk

let responseEnum = await service.registerAccount(address: address, request: request, jwt: jwt)
switch responseEnum {
case .success(let account):
    print("Registered: \(account.address)")

case .failure(let error):
    switch error {
    case .badRequest(let message):
        print("Bad request (400): \(message)")
        // Check that all required identities and auth methods are present

    case .unauthorized(let message):
        print("Unauthorized (401): \(message)")
        // JWT is missing, expired, or doesn't grant access — re-authenticate via SEP-10

    case .notFound(let message):
        print("Not found (404): \(message)")
        // Account is not registered, or authenticated user lacks access

    case .conflict(let message):
        print("Conflict (409): \(message)")
        // Account is already registered — use updateIdentitiesForAccount instead

    case .parsingResponseFailed(let message):
        print("Parse error: \(message)")
        // Unexpected response format from the server

    case .horizonError(let horizonError):
        print("Network error: \(horizonError)")
        // Low-level HTTP or network failure
    }
}
```

---

## Common Pitfalls

**Wrong: `updateIdentitiesForAccount` merges identities**

```swift
// WRONG: Assumes update adds to existing identities
// If the account had "owner" and you send only "sender", "owner" is REMOVED
let request = Sep30Request(identities: [senderIdentity])
await service.updateIdentitiesForAccount(address: address, request: request, jwt: jwt)
// Result: only "sender" identity remains — "owner" is gone

// CORRECT: Always include ALL identities you want to keep after the update
let request = Sep30Request(identities: [ownerIdentity, senderIdentity])  // keep both
await service.updateIdentitiesForAccount(address: address, request: request, jwt: jwt)
```

**Wrong: registering an account that is already registered**

```swift
// WRONG: Calling registerAccount for an already-registered account
let responseEnum = await service.registerAccount(address: address, request: request, jwt: jwt)
// → .failure(error: .conflict(message: "account already exists"))

// CORRECT: Use updateIdentitiesForAccount to replace identities for existing accounts
let responseEnum = await service.updateIdentitiesForAccount(address: address, request: request, jwt: jwt)
```

**Wrong: incorrect signingAddress in signTransaction**

```swift
// WRONG: Using a key that does not match any signer returned at registration
let signEnum = await service.signTransaction(
    address: address,
    signingAddress: "GINVALID_KEY...",  // not in account.signers
    transaction: txXdr,
    jwt: jwt
)
// → .failure(error: .notFound(message: "signer not found for account"))

// CORRECT: Use the key from account.signers[0].key (most recently added)
let accountEnum = await service.accountDetails(address: address, jwt: jwt)
guard case .success(let account) = accountEnum,
      let signerKey = account.signers.first?.key else { return }

let signEnum = await service.signTransaction(
    address: address,
    signingAddress: signerKey,  // from account.signers[0].key
    transaction: txXdr,
    jwt: jwt
)
```

**Wrong: passing raw transaction bytes instead of XDR string**

```swift
// WRONG: Passing a hash, envelope bytes, or non-XDR string
let signEnum = await service.signTransaction(
    address: address,
    signingAddress: signerKey,
    transaction: Data(txBytes).base64EncodedString(),  // arbitrary bytes, not XDR envelope
    jwt: jwt
)
// → .failure(error: .badRequest(message: "invalid transaction format"))

// CORRECT: Use encodedEnvelope() to produce the base64-encoded XDR envelope string
let transactionXdr = try transaction.encodedEnvelope()
let signEnum = await service.signTransaction(
    address: address,
    signingAddress: signerKey,
    transaction: transactionXdr,  // base64-encoded XDR from encodedEnvelope()
    jwt: jwt
)
```

**Wrong: treating `authenticated == nil` as unauthenticated**

```swift
// WRONG: nil is NOT the same as false — nil means no information provided for that identity
for identity in account.identities {
    if identity.authenticated == false {
        print("\(identity.role ?? "") is NOT authenticated")  // this branch never fires
    }
}

// CORRECT: nil means the server did not include the field (the identity is not authenticated)
for identity in account.identities {
    let isAuthenticated = identity.authenticated == true  // nil → not authenticated, false never occurs
    print("\(identity.role ?? "unknown") authenticated: \(isAuthenticated)")
}
```

---

## Full Recovery Workflow Example

This example shows the complete recovery workflow: registration, followed by recovery signing to restore account access.

```swift
import stellarsdk

// --- Step 1: Normal setup — register account with recovery service ---

let sdk = StellarSDK.testNet()
let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Obtain JWT via SEP-10 (see sep-10.md)
// let jwt = ...

let accountKeyPair = try KeyPair(secretSeed: ProcessInfo.processInfo.environment["STELLAR_SECRET_SEED"]!)

// Build identities: owner can authenticate via Stellar address or email
let ownerAuthByAddress = Sep30AuthMethod(type: "stellar_address", value: accountKeyPair.accountId)
let ownerAuthByEmail = Sep30AuthMethod(type: "email", value: "user@example.com")
let ownerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [ownerAuthByAddress, ownerAuthByEmail])

let registerEnum = await service.registerAccount(
    address: accountKeyPair.accountId,
    request: Sep30Request(identities: [ownerIdentity]),
    jwt: jwt
)

guard case .success(let registered) = registerEnum,
      let recoverySignerKey = registered.signers.first?.key else {
    print("Registration failed")
    return
}

print("Recovery signer key: \(recoverySignerKey)")

// Add recoverySignerKey as a signer on the Stellar account (see advanced.md for multi-sig setup)

// --- Step 2: Account recovery — request the service to sign a repair transaction ---

// (Later, when access to the original key is lost and a new key is needed)
let newKeyPair = try KeyPair.generateRandomKeyPair()

let accountEnum = await sdk.accounts.getAccountDetails(accountId: accountKeyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Build a transaction that replaces the old key with a new one
let addNewSignerOp = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: newKeyPair),
    signerWeight: 1
)

let recoveryTx = try Transaction(
    sourceAccount: sourceAccount,
    operations: [addNewSignerOp],
    memo: Memo.none,
    maxOperationFee: 100
)

// Encode to XDR for submission to recovery service
let txXdr = try recoveryTx.encodedEnvelope()

// Request recovery service signature (authenticated with recovery identity's JWT)
let signEnum = await service.signTransaction(
    address: accountKeyPair.accountId,
    signingAddress: recoverySignerKey,
    transaction: txXdr,
    jwt: recoveryJwt  // JWT from authenticating as the recovery identity (e.g. email auth)
)

switch signEnum {
case .success(let signatureResponse):
    print("Recovery signature obtained: \(signatureResponse.signature)")
    // The signature is base64-encoded — apply it to the transaction and submit
    // (advanced multi-sig submission: add signature to envelope and submit)
case .failure(let error):
    print("Recovery signing failed: \(error)")
}
```

---

## Related SEPs

- [sep-10.md](sep-10.md) — Web Authentication (required: provides the JWT for all RecoveryService calls)
- [sep.md](sep.md) — Overview of all SEP implementations
