# SEP-30: Account Recovery

SEP-30 defines a protocol for recovering access to Stellar accounts when the owner loses their private key. Recovery servers act as additional signers on an account, allowing the user to regain control by proving their identity through alternate methods like email, phone, or another Stellar address.

Use SEP-30 when:
- Building a wallet with account recovery features
- You want to protect users from permanent key loss
- Implementing shared account access between multiple parties
- Setting up multi-device account access with recovery options

See the [SEP-30 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md) for protocol details.

## How Recovery Works

1. **Registration**: Register your account with a recovery server, providing identity information with authentication methods
2. **Add Signer**: Add the server's signer key to your Stellar account with appropriate weight
3. **Recovery**: If you lose your key, authenticate with the recovery server via alternate methods (email, phone, etc.)
4. **Sign Transaction**: The server signs a transaction that adds your new key to the account
5. **Submit**: Submit the signed transaction to the Stellar network to regain control

## Quick Example

This example shows the basic flow: register an account with a recovery server, then add the returned signer key to your Stellar account.

```swift
import stellarsdk

// Connect to recovery server
let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Set up identity with authentication methods
let authMethods = [
    Sep30AuthMethod(type: "email", value: "user@example.com"),
    Sep30AuthMethod(type: "phone_number", value: "+14155551234"),
]
let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)

// Register account with recovery server (requires SEP-10 JWT)
let request = Sep30Request(identities: [identity])
let responseEnum = await service.registerAccount(
    address: accountId,
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(let response):
    // Get the signer key to add to your account
    let signerKey = response.signers[0].key
    print("Add this signer to your account: \(signerKey)")
case .failure(let error):
    print("Registration failed: \(error)")
}
```

## Creating the Recovery Service

The `RecoveryService` class is the main entry point for all SEP-30 operations. Create an instance by providing the recovery server's base URL.

```swift
import stellarsdk

// Create service with recovery server URL
let service = RecoveryService(serviceAddress: "https://recovery.example.com")
```

## Registering an Account

Before your account can be recovered, you must register it with one or more recovery servers. Registration requires a SEP-10 JWT token proving you control the account.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Define how the user can prove their identity during recovery.
// Multiple authentication methods provide fallback options.
let authMethods = [
    Sep30AuthMethod(type: "stellar_address", value: "GXXXX..."), // SEP-10 auth (highest security)
    Sep30AuthMethod(type: "email", value: "user@example.com"),
    Sep30AuthMethod(type: "phone_number", value: "+14155551234"), // E.164 format required
]

// Create identity with role "owner" - roles are client-defined labels
// that help users understand their relationship to the account.
let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)

// Register with the recovery server
let request = Sep30Request(identities: [identity])
let responseEnum = await service.registerAccount(
    address: accountId,
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(let response):
    // The response includes signer keys to add to your Stellar account.
    // Signers are ordered from most recently added to least recently added.
    print("Account address: \(response.address)")
    for signer in response.signers {
        print("Signer key: \(signer.key)")
    }
    for identity in response.identities {
        print("Identity role: \(identity.role ?? "unspecified")")
    }
case .failure(let error):
    print("Registration failed: \(error)")
}
```

### Adding the Recovery Signer to Your Account

After registration, you must add the recovery server's signer key to your Stellar account. Configure account thresholds so the recovery server cannot unilaterally control your account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let accountKeyPair = try KeyPair(secretSeed: "SXXXXXX...")
let accountId = accountKeyPair.accountId
let accountEnum = await sdk.accounts.getAccountDetails(accountId: accountId)
guard case .success(let accountDetails) = accountEnum else { return }

// Add recovery server as a signer with weight 1.
// The signer key comes from the registration response.
let signerKey = response.signers[0].key

let sourceAccount = try Account(
    accountId: accountDetails.accountId,
    sequenceNumber: accountDetails.sequenceNumber
)

// Add the recovery signer and set thresholds
let addSignerOp = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: signerKey)),
    signerWeight: 1
)

// Set thresholds so recovery requires multiple signers.
// With threshold=2, both your key (weight 10) and recovery server (weight 1)
// together can meet threshold, but recovery server alone cannot.
let setThresholdsOp = try SetOptionsOperation(
    sourceAccountId: nil,
    highThreshold: 2,
    mediumThreshold: 2,
    lowThreshold: 2
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [addSignerOp, setThresholdsOp],
    memo: Memo.none,
    maxOperationFee: 100
)

try transaction.sign(keyPair: accountKeyPair, network: .testnet)
let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)

switch submitResult {
case .success(_):
    print("Recovery signer added to account")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination requires memo: \(destinationAccountId)")
case .failure(let error):
    print("Transaction failed: \(error)")
}
```

## Multi-Server Recovery

For better security, register with multiple recovery servers so no single server has full control. Each server provides a signer key with weight 1, and the account threshold is set to require cooperation from multiple servers.

```swift
import stellarsdk

// Create identity (reused for both servers)
let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
let request = Sep30Request(identities: [identity])

// Register with first recovery server
let service1 = RecoveryService(serviceAddress: "https://recovery1.example.com")
let responseEnum1 = await service1.registerAccount(
    address: accountId,
    request: request,
    jwt: jwtToken1
)
guard case .success(let response1) = responseEnum1 else { return }
let signerKey1 = response1.signers[0].key

// Register with second recovery server
let service2 = RecoveryService(serviceAddress: "https://recovery2.example.com")
let responseEnum2 = await service2.registerAccount(
    address: accountId,
    request: request,
    jwt: jwtToken2
)
guard case .success(let response2) = responseEnum2 else { return }
let signerKey2 = response2.signers[0].key

// Add both signers to your account with combined weight
let sdk = StellarSDK.testNet()
let accountKeyPair = try KeyPair(secretSeed: "SXXXXXX...")
let accountEnum = await sdk.accounts.getAccountDetails(accountId: accountKeyPair.accountId)
guard case .success(let accountDetails) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountDetails.accountId,
    sequenceNumber: accountDetails.sequenceNumber
)

let addSigner1Op = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: signerKey1)),
    signerWeight: 1
)

let addSigner2Op = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: signerKey2)),
    signerWeight: 1
)

// Set threshold to 2, requiring both recovery servers to sign
let setThresholdsOp = try SetOptionsOperation(
    sourceAccountId: nil,
    highThreshold: 2,
    mediumThreshold: 2,
    lowThreshold: 2
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [addSigner1Op, addSigner2Op, setThresholdsOp],
    memo: Memo.none,
    maxOperationFee: 100
)

try transaction.sign(keyPair: accountKeyPair, network: .testnet)
let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)

switch submitResult {
case .success(_):
    print("Multi-server recovery configured")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination requires memo: \(destinationAccountId)")
case .failure(let error):
    print("Transaction failed: \(error)")
}
```

## Recovering an Account

When you lose your private key, authenticate with the recovery server using one of your registered authentication methods (email, phone, etc.) to get a JWT. Then request the server to sign a transaction that adds your new key.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Get account details to find the signing address.
// The JWT here proves your identity via alternate auth (email/phone).
let accountDetailsEnum = await service.accountDetails(
    address: accountId,
    jwt: recoveryJwt
)
guard case .success(let accountDetails) = accountDetailsEnum else { return }
let signingAddress = accountDetails.signers[0].key

// Generate a new keypair for the recovered account
let newKeyPair = try KeyPair.generateRandomKeyPair()

// Build a transaction to add the new key with high weight
let sdk = StellarSDK.testNet()
let stellarAccountEnum = await sdk.accounts.getAccountDetails(accountId: accountId)
guard case .success(let stellarAccount) = stellarAccountEnum else { return }

let sourceAccount = try Account(
    accountId: stellarAccount.accountId,
    sequenceNumber: stellarAccount.sequenceNumber
)

let operation = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: newKeyPair),
    signerWeight: 10 // High weight to regain control
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [operation],
    memo: Memo.none,
    maxOperationFee: 100
)

// Get the recovery server to sign the transaction
let txBase64 = try transaction.encodedEnvelope()
let signatureEnum = await service.signTransaction(
    address: accountId,
    signingAddress: signingAddress,
    transaction: txBase64,
    jwt: recoveryJwt // JWT proving identity via alternate auth
)

switch signatureEnum {
case .success(let signatureResponse):
    // Add the server's signature to the transaction.
    // Create the hint from the signing address (last 4 bytes of public key).
    let signerKeyPair = try KeyPair(accountId: signingAddress)
    let hintBytes = Data(signerKeyPair.publicKey.bytes.suffix(4))
    let signatureBytes = Data(base64Encoded: signatureResponse.signature)!
    let decoratedSignature = DecoratedSignatureXDR(
        hint: WrappedData4(hintBytes),
        signature: signatureBytes
    )
    transaction.addSignature(signature: decoratedSignature)

    // For multi-server recovery, repeat the signing process with each server
    // and add all signatures before submitting.

    // Submit the signed transaction
    let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResult {
    case .success(_):
        print("Account recovered! New key: \(newKeyPair.secretSeed)")
        print("Store this seed securely!")
    case .destinationRequiresMemo(let destinationAccountId):
        print("Destination requires memo: \(destinationAccountId)")
    case .failure(let error):
        print("Submit failed: \(error)")
    }
case .failure(let error):
    print("Recovery signing failed: \(error)")
}
```

## Updating Identity Information

Update authentication methods for a registered account. This completely replaces all existing identities - identities not included in the request will be removed.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// New auth methods completely replace existing ones.
// Use this to add new methods, remove compromised ones, or update contact info.
let newAuthMethods = [
    Sep30AuthMethod(type: "email", value: "newemail@example.com"),
    Sep30AuthMethod(type: "phone_number", value: "+14155559999"),
    Sep30AuthMethod(type: "stellar_address", value: "GNEWADDRESS..."),
]
let identity = Sep30RequestIdentity(role: "owner", authMethods: newAuthMethods)

let request = Sep30Request(identities: [identity])
let responseEnum = await service.updateIdentitiesForAccount(
    address: accountId,
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(let response):
    print("Identities updated successfully")
    for identity in response.identities {
        print("Role: \(identity.role ?? "unspecified")")
    }
case .failure(let error):
    print("Update failed: \(error)")
}
```

## Shared Account Access

SEP-30 supports multiple parties sharing access to an account. Each party has their own identity with a unique role, allowing both to recover the account.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Primary owner - can recover the account
let ownerAuth = [
    Sep30AuthMethod(type: "email", value: "owner@example.com"),
    Sep30AuthMethod(type: "phone_number", value: "+14155551111"),
]
let ownerIdentity = Sep30RequestIdentity(role: "sender", authMethods: ownerAuth)

// Shared user - can also recover the account
let receiverAuth = [
    Sep30AuthMethod(type: "email", value: "partner@example.com"),
    Sep30AuthMethod(type: "phone_number", value: "+14155552222"),
]
let receiverIdentity = Sep30RequestIdentity(role: "receiver", authMethods: receiverAuth)

// Register both identities - either party can initiate recovery
let request = Sep30Request(identities: [ownerIdentity, receiverIdentity])
let responseEnum = await service.registerAccount(
    address: accountId,
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(_):
    print("Shared account registered")
    print("Both 'sender' and 'receiver' can now recover this account")
case .failure(let error):
    print("Registration failed: \(error)")
}
```

## Getting Account Details

Check registration status, view current signers, and see which identity is currently authenticated. Use this to monitor for key rotation and verify your recovery setup.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

let responseEnum = await service.accountDetails(
    address: accountId,
    jwt: jwtToken
)

switch responseEnum {
case .success(let response):
    print("Account: \(response.address)")

    print("\nIdentities:")
    for identity in response.identities {
        let authStatus = identity.authenticated == true ? " (authenticated)" : ""
        print("  Role: \(identity.role ?? "unspecified")\(authStatus)")
    }

    print("\nSigners (ordered most recent first):")
    for signer in response.signers {
        print("  Key: \(signer.key)")
    }

    // Best practice: periodically check for new signers and update your account
    // to use the most recent one (key rotation)
    let latestSigner = response.signers[0].key
    print("\nLatest signer for key rotation: \(latestSigner)")
case .failure(let error):
    print("Failed to get account details: \(error)")
}
```

## Listing Registered Accounts

List all accounts accessible by the authenticated identity. This is useful for identity providers or users managing multiple accounts. Results are paginated using cursor-based pagination.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Get first page of accounts
let responseEnum = await service.accounts(jwt: jwtToken)

switch responseEnum {
case .success(let response):
    print("Found \(response.accounts.count) accounts:")
    for account in response.accounts {
        print("  Address: \(account.address)")
        for identity in account.identities {
            let auth = identity.authenticated == true ? " (you)" : ""
            let role = identity.role ?? "(unspecified)"
            print("    Role: \(role)\(auth)")
        }
    }

    // Pagination: use the last account address as cursor for next page
    if let lastAddress = response.accounts.last?.address {
        let nextPageEnum = await service.accounts(
            jwt: jwtToken,
            after: lastAddress
        )
        switch nextPageEnum {
        case .success(let nextPage):
            if !nextPage.accounts.isEmpty {
                print("\nNext page has \(nextPage.accounts.count) more accounts")
            }
        case .failure(let error):
            print("Pagination failed: \(error)")
        }
    }
case .failure(let error):
    print("Failed to list accounts: \(error)")
}
```

## Deleting Registration

Remove your account from the recovery server. This operation is **irrecoverable** - once deleted, you cannot recover the account through this server. Remember to also remove the server's signer from your Stellar account.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

// Get the signer key before deletion so we can remove it from the account
let detailsEnum = await service.accountDetails(
    address: accountId,
    jwt: jwtToken
)
guard case .success(let details) = detailsEnum else { return }
let signerToRemove = details.signers[0].key

// Delete registration from recovery server
let responseEnum = await service.deleteAccount(
    address: accountId,
    jwt: jwtToken
)

switch responseEnum {
case .success(_):
    print("Account deleted from recovery server")
case .failure(let error):
    print("Delete failed: \(error)")
}

// Important: also remove the server's signer from your Stellar account
let sdk = StellarSDK.testNet()
let accountKeyPair = try KeyPair(secretSeed: "SXXXXXX...")
let accountEnum = await sdk.accounts.getAccountDetails(accountId: accountKeyPair.accountId)
guard case .success(let accountDetails) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountDetails.accountId,
    sequenceNumber: accountDetails.sequenceNumber
)

let removeSignerOp = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: signerToRemove)),
    signerWeight: 0 // Weight 0 removes the signer
)

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [removeSignerOp],
    memo: Memo.none,
    maxOperationFee: 100
)

try transaction.sign(keyPair: accountKeyPair, network: .testnet)
let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)

switch submitResult {
case .success(_):
    print("Recovery signer removed from Stellar account")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination requires memo: \(destinationAccountId)")
case .failure(let error):
    print("Transaction failed: \(error)")
}
```

## Error Handling

The SDK returns specific error cases for different error conditions through the `RecoveryServiceError` enum. Handle these appropriately in your application.

```swift
import stellarsdk

let service = RecoveryService(serviceAddress: "https://recovery.example.com")

let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
let request = Sep30Request(identities: [identity])

let responseEnum = await service.registerAccount(
    address: accountId,
    request: request,
    jwt: jwtToken
)

switch responseEnum {
case .success(let response):
    print("Registration successful!")

case .failure(let error):
    switch error {
    case .badRequest(let message):
        // HTTP 400 - Invalid request data, malformed JSON, invalid auth methods,
        // or transaction contains unauthorized operations (for signing)
        print("Bad request: \(message)")

    case .unauthorized(let message):
        // HTTP 401 - JWT token missing, invalid, expired, or doesn't prove
        // ownership of the account
        print("Unauthorized: \(message)")
        print("Please obtain a valid SEP-10 JWT token")

    case .notFound(let message):
        // HTTP 404 - Account not registered, signing address not recognized,
        // or authenticated identity doesn't have access
        print("Not found: \(message)")

    case .conflict(let message):
        // HTTP 409 - Account already registered (for registration),
        // or update conflicts with server state
        print("Conflict: \(message)")
        print("Account may already be registered. Try updateIdentitiesForAccount() instead.")

    case .parsingResponseFailed(let message):
        // SDK could not decode the server response
        print("Parse error: \(message)")

    case .horizonError(let horizonError):
        // Low-level network or HTTP errors
        print("Network error: \(horizonError)")
    }
}
```

## Authentication Methods

SEP-30 defines three standard authentication types. Recovery servers may also support custom types.

| Type | Format | Example | Security Notes |
|------|--------|---------|----------------|
| `stellar_address` | G... public key | `GDUAB...` | Highest security - requires SEP-10 cryptographic proof |
| `phone_number` | E.164 format with + | `+14155551234` | Vulnerable to SIM swapping attacks |
| `email` | Standard email | `user@example.com` | Security depends on email provider |

### Phone Number Format

Phone numbers must follow ITU-T E.164 international format:
- Include country code with leading `+`
- No spaces or formatting
- Example: `+14155551234` (not `+1 415 555 1234` or `(415) 555-1234`)

```swift
import stellarsdk

// Correct E.164 format
let phoneAuth = Sep30AuthMethod(type: "phone_number", value: "+14155551234")

// These formats are INCORRECT and may fail:
// "+1 415 555 1234"  (has spaces)
// "(415) 555-1234"   (missing country code, has formatting)
// "4155551234"       (missing + and country code)
```

## Identity Roles

Roles are client-defined labels stored by the server and returned in responses. They help users understand their relationship to an account but are not validated or enforced by the server.

Common role patterns:

| Role | Use Case |
|------|----------|
| `owner` | Single-user recovery - the account owner |
| `sender` | Account sharing - the person sharing the account |
| `receiver` | Account sharing - the person receiving shared access |
| `device` | Multi-device access - represents a specific device |
| `backup` | Backup identity with alternate authentication |

## Security Considerations

### Multi-Server Setup
- Use 2+ recovery servers with account threshold set to require multiple signatures
- No single server should have enough weight to unilaterally control the account
- Example: Each server weight=1, threshold=2

### Signer Weights and Thresholds
- Give each recovery server weight=1
- Set account thresholds to require multiple signers (e.g., threshold=2 for two servers)
- Your own key should have higher weight (e.g., weight=10) for normal operations

### Authentication Security
- `stellar_address` provides cryptographic proof via SEP-10 (strongest)
- Phone numbers are vulnerable to SIM swapping - evaluate risk for high-value accounts
- Email security depends on your email provider

### Key Rotation
- Recovery servers may rotate their signing keys over time
- Periodically check `accountDetails()` for new signers
- Update your account to use the most recent signer (first in the array)
- Old signers remain valid until explicitly removed

### General Best Practices
- Always use HTTPS for recovery server communication
- Store JWT tokens securely and never log them
- After deleting registration, remove the signer from your Stellar account
- Test your recovery setup before you actually need it

## Related SEPs

- [SEP-10](sep-10.md) - Web Authentication (required for `stellar_address` auth method and registration)

## Further Reading

- [SDK test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkUnitTests/sep/recovery/RecoveryServiceTestCase.swift) - Complete examples of SEP-30 operations

## SDK Classes Reference

| Class | Description |
|-------|-------------|
| `RecoveryService` | Main service class for all SEP-30 operations |
| `Sep30Request` | Request containing identities for registration/update |
| `Sep30RequestIdentity` | Identity with role and authentication methods |
| `Sep30AuthMethod` | Single authentication method (type and value) |
| `Sep30AccountResponse` | Response with account address, identities, and signers |
| `Sep30AccountsResponse` | Response containing list of accounts (pagination) |
| `Sep30SignatureResponse` | Response with signature and network passphrase |
| `SEP30ResponseIdentity` | Identity in response with role and authenticated flag |
| `SEP30ResponseSigner` | Signer key in response |
| `RecoveryServiceError` | Error enum with cases: `badRequest`, `unauthorized`, `notFound`, `conflict`, `parsingResponseFailed`, `horizonError` |

---

[Back to SEP Overview](README.md)
