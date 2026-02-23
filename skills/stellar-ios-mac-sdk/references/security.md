# Security Best Practices

Security patterns for Stellar iOS/Mac SDK (`stellarsdk`) applications in production.

## Secret Key Management

### Never Hardcode Secrets

```swift
import stellarsdk

// WRONG - secret key in source code
let keyPair = try KeyPair(secretSeed: "SDJHRQF4GCMIQ...")

// CORRECT - load from secure storage
let secretSeed = try loadSecretFromKeychain(account: "stellar-signing-key")
let keyPair = try KeyPair(secretSeed: secretSeed)
```

### iOS/macOS Keychain Storage

Use Keychain Services to store secret seeds. The Keychain encrypts data at rest and ties it to the device.

```swift
import Foundation
import Security
import stellarsdk

func saveSecretToKeychain(secretSeed: String, account: String) throws {
    let seedData = secretSeed.data(using: .utf8)!

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecAttrService as String: "com.myapp.stellar",
        kSecValueData as String: seedData,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]

    // Delete any existing item first
    SecItemDelete(query as CFDictionary)

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
}

func loadSecretFromKeychain(account: String) throws -> String {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecAttrService as String: "com.myapp.stellar",
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data,
          let seed = String(data: data, encoding: .utf8) else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    return seed
}

func deleteSecretFromKeychain(account: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecAttrService as String: "com.myapp.stellar"
    ]
    SecItemDelete(query as CFDictionary)
}
```

### Keychain Access Control

For high-value signing keys, require biometric authentication before access:

```swift
import Security
import LocalAuthentication

func saveWithBiometric(secretSeed: String, account: String) throws {
    let access = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        .biometryCurrentSet,
        nil
    )!

    let seedData = secretSeed.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecAttrService as String: "com.myapp.stellar",
        kSecValueData as String: seedData,
        kSecAttrAccessControl as String: access
    ]

    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
}
```

### Memory Handling

Secret seeds are held as Swift `String` values in memory. Minimize their lifetime:

```swift
import stellarsdk

func signAndForget(
    transaction: Transaction,
    keychainAccount: String,
    network: Network
) throws {
    // Load secret only when needed
    let secretSeed = try loadSecretFromKeychain(account: keychainAccount)
    let signingKeyPair = try KeyPair(secretSeed: secretSeed)

    // Sign immediately
    try transaction.sign(keyPair: signingKeyPair, network: network)

    // signingKeyPair and secretSeed go out of scope here
    // Swift ARC will deallocate, but memory is not zeroed
    // For highest security, consider using Data with resetBytes
}
```

## Transaction Verification Before Signing

Always inspect a transaction before signing, especially if it was constructed by external code (e.g., SEP-7 URIs, server-provided XDR).

```swift
import stellarsdk

func verifyAndSign(
    envelopeXdr: String,
    signerKeyPair: KeyPair,
    network: Network,
    expectedSourceAccountId: String
) throws -> String {
    let transaction = try Transaction(envelopeXdr: envelopeXdr)

    // Verify source account matches expectation
    guard transaction.sourceAccount.keyPair.accountId == expectedSourceAccountId else {
        throw NSError(domain: "Security", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unexpected source account"])
    }

    // Verify operation count is reasonable
    guard transaction.operations.count <= 10 else {
        throw NSError(domain: "Security", code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Too many operations: \(transaction.operations.count)"])
    }

    // Inspect each operation type
    for (index, op) in transaction.operations.enumerated() {
        print("Operation \(index): \(type(of: op))")
        if let payment = op as? PaymentOperation {
            print("  Destination: \(payment.destinationAccountId)")
            print("  Amount: \(payment.amount)")
            print("  Asset: \(payment.asset.toCanonicalForm())")
        }
    }

    // Verify fee is reasonable
    let maxAcceptableFee: UInt32 = 10_000 // 0.001 XLM
    guard transaction.fee <= maxAcceptableFee else {
        throw NSError(domain: "Security", code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Fee too high: \(transaction.fee) stroops"])
    }

    try transaction.sign(keyPair: signerKeyPair, network: network)
    return try transaction.encodedEnvelope()
}
```

## Network Selection and Validation

### Prevent Mainnet Accidents

```swift
import stellarsdk

enum AppEnvironment {
    case production
    case development
}

func configureStellar(environment: AppEnvironment) -> (StellarSDK, Network) {
    switch environment {
    case .production:
        let sdk = StellarSDK(withHorizonUrl: StellarSDK.publicNetUrl)
        return (sdk, .public)
    case .development:
        let sdk = StellarSDK(withHorizonUrl: StellarSDK.testNetUrl)
        return (sdk, Network.testnet)
    }
}

// Validate network before signing
func validateNetwork(expected: Network, actual: Network) -> Bool {
    return expected.passphrase == actual.passphrase
}
```

### Verify Horizon Endpoint

Before submitting transactions, confirm the server is responding and matches your expected network:

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon.stellar.org")

let healthResponse = await sdk.health.getHealth()
switch healthResponse {
case .success:
    print("Horizon is healthy")
case .failure(let error):
    print("Horizon unreachable: \(error)")
    // Do NOT submit transactions to an unverified endpoint
}
```

## Multi-Signature Security

### Verify Signer Weights and Thresholds

Before relying on multi-sig, confirm the account's signer configuration:

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let accountId = "GABC..."

let response = await sdk.accounts.getAccountDetails(accountId: accountId)
switch response {
case .success(let account):
    print("Thresholds - low: \(account.thresholds.lowThreshold), "
        + "med: \(account.thresholds.medThreshold), "
        + "high: \(account.thresholds.highThreshold)")
    for signer in account.signers {
        print("Signer: \(signer.key) weight: \(signer.weight)")
    }
case .failure(let error):
    print("Cannot verify signers: \(error)")
}
```

### Secure Multi-Party Signing Flow

Share unsigned transaction XDR between parties -- never share secret seeds.

```swift
import stellarsdk

// Party A: Build and partially sign
let envelopeXdr = try transaction.encodedEnvelope()
// Send envelopeXdr to Party B via secure channel

// Party B: Receive, verify, and add signature
let transaction = try Transaction(envelopeXdr: envelopeXdr)
// ALWAYS inspect before signing (see "Transaction Verification" section)
try transaction.sign(keyPair: partyBKeyPair, network: Network.testnet)
let fullySigned = try transaction.encodedEnvelope()
// Submit or send back
```

## SEP-10 Authentication Security

### Validate Challenge Transaction

The `WebAuthenticator` class handles SEP-10. Always use the SDK's built-in validation rather than manual parsing:

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://anchor.example.com/auth",
    network: Network.testnet,
    serverSigningKey: "GSERVER...",
    serverHomeDomain: "anchor.example.com"
)

let userKeyPair = try KeyPair(secretSeed: secretSeed)
let response = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair]
)
switch response {
case .success(let jwtToken):
    print("Authenticated, JWT: \(jwtToken.prefix(20))...")
case .failure(let error):
    // GetJWTTokenError cases:
    // .requestError(HorizonRequestError) - network failure
    // .parsingError(Error) - malformed challenge
    // .validationErrorError(ChallengeValidationError) - invalid challenge
    // .signingError - could not sign challenge
    print("Auth failed: \(error)")
}
```

### SEP-10 Security Checklist

- Verify `serverSigningKey` matches the anchor's published signing key from their `stellar.toml`
- Use `WebAuthenticator.from(domain:network:)` to auto-discover from TOML when possible
- Never reuse JWT tokens across different services
- Store JWT tokens securely (Keychain) and respect expiration
- Use HTTPS endpoints exclusively for the auth server

## Input Validation

### Stellar Address Validation

```swift
import stellarsdk

func isValidStellarAddress(_ address: String) -> Bool {
    do {
        _ = try KeyPair(accountId: address)
        return true
    } catch {
        return false
    }
}

// Validate before using in any operation
let destinationId = "GABC..."
guard isValidStellarAddress(destinationId) else {
    print("Invalid Stellar address")
    return
}
```

### Amount Validation

All Stellar amounts are represented as `Decimal` in the SDK. Validate range and precision:

```swift
func isValidAmount(_ amount: Decimal) -> Bool {
    // Must be positive
    guard amount > 0 else { return false }

    // Stellar supports 7 decimal places max
    let handler = NSDecimalNumberHandler(
        roundingMode: .plain,
        scale: 7,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
    )
    let rounded = NSDecimalNumber(decimal: amount)
        .rounding(accordingToBehavior: handler).decimalValue
    guard rounded == amount else { return false }

    // Max amount on Stellar: 922337203685.4775807
    let maxAmount: Decimal = 922_337_203_685.4775807
    guard amount <= maxAmount else { return false }

    return true
}
```

### Memo Validation

```swift
import stellarsdk

func validateMemo(_ memo: Memo) -> Bool {
    switch memo {
    case .text(let text):
        // Max 28 bytes UTF-8
        return text.utf8.count <= 28
    case .id:
        return true // UInt64, always valid if it compiles
    case .hash(let data), .returnHash(let data):
        return data.count == 32
    case .none:
        return true
    }
}
```

## HTTPS and Endpoint Security

### Always Use HTTPS

```swift
import stellarsdk

// WRONG - unencrypted connection
let sdk = StellarSDK(withHorizonUrl: "http://horizon.stellar.org")

// CORRECT - TLS encrypted
let sdk = StellarSDK(withHorizonUrl: "https://horizon.stellar.org")

// CORRECT - Soroban RPC over HTTPS
let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
```

### App Transport Security

iOS enforces HTTPS by default via App Transport Security (ATS). Do not disable ATS in your `Info.plist` for Stellar endpoints. If you must connect to a local development server, add only that specific domain as an exception, never `NSAllowsArbitraryLoads`.

## Production Deployment Checklist

### Pre-Launch

- [ ] All secret seeds stored in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- [ ] No hardcoded secret seeds, mnemonics, or private keys anywhere in source
- [ ] Biometric protection enabled for high-value signing keys
- [ ] Transaction verification implemented before every signing operation
- [ ] Network selection uses `Network.public` (not `Network.testnet`)
- [ ] Horizon URL points to `https://horizon.stellar.org` (or your own Horizon instance)
- [ ] Soroban RPC URL uses `https://` protocol
- [ ] All user-facing amounts validated (positive, 7 decimal max, under max)
- [ ] Stellar addresses validated via `KeyPair(accountId:)` before use
- [ ] Memo validation enforced (28-byte limit for text, 32-byte for hash)

### Runtime

- [ ] Fee estimation queries `feeStats` before each transaction
- [ ] Sequence numbers loaded fresh before each transaction build
- [ ] Rate limiting handled with exponential backoff
- [ ] SEP-29 memo check not skipped (`skipMemoRequiredCheck: false`)
- [ ] Error responses logged for debugging but never expose secrets in logs
- [ ] Soroban `enableLogging` set to `false` in production
- [ ] JWT tokens from SEP-10 stored in Keychain and refreshed before expiry

### Multi-Signature

- [ ] Transaction XDR shared between signers, never secret seeds
- [ ] Each signer verifies transaction contents before signing
- [ ] Signer weights and thresholds verified against on-chain state
- [ ] Pre-auth transaction hashes used for automated workflows where appropriate
