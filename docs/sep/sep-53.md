# SEP-53: Sign and Verify Messages

Prove ownership of a Stellar private key by signing arbitrary messages.

## Overview

> **Note:** SEP-53 is currently in Draft status (v0.0.1). The specification may evolve before reaching final status.

SEP-53 defines how to sign and verify messages with Stellar keypairs. Use it when you need to:

- Authenticate users by proving key ownership
- Sign attestations or consent agreements
- Verify signatures from other Stellar SDKs
- Create provable off-chain statements

The protocol adds a prefix (`"Stellar Signed Message:\n"`) before hashing, which prevents signed messages from being confused with transaction signatures.

## Quick example

Sign a message and verify the signature:

```swift
import stellarsdk

// Generate a random keypair (or use KeyPair(secretSeed:) for an existing key)
let keyPair = try! KeyPair.generateRandomKeyPair()

// Sign a message
let signature = try keyPair.signMessage("I agree to the terms of service")

// Verify the signature
let isValid = try keyPair.verifyMessage("I agree to the terms of service", signature: signature)
print(isValid ? "Valid" : "Invalid")
```

## Detailed usage

### Signing messages

Sign a message and encode the signature for transmission. The raw signature is 64 bytes, so you'll typically encode it as base64 or hex:

```swift
import stellarsdk
import Foundation

let keyPair = try! KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

let message = "User consent granted at 2025-01-15T12:00:00Z"
let signature = try keyPair.signMessage(message)

// Encode as base64 for transmission
let base64Signature = Data(signature).base64EncodedString()
print("Signature: \(base64Signature)")

// Or encode as hex
let hexSignature = Data(signature).base16EncodedString()
print("Signature (hex): \(hexSignature)")
```

### Verifying messages

Verify a signature using only the public key. This is typically done server-side after receiving a signed message from a client:

```swift
import stellarsdk
import Foundation

// Create keypair from public key only (no private key needed for verification)
let publicKey = try! KeyPair(accountId: "GABC...")

let message = "User consent granted at 2025-01-15T12:00:00Z"
let base64Signature = "..." // Received from client

let signature = [UInt8](Data(base64Encoded: base64Signature)!)
let isValid = try publicKey.verifyMessage(message, signature: signature)

if isValid {
    print("Signature verified")
} else {
    print("Invalid signature")
}
```

### Verifying hex-encoded signatures

If the signature was transmitted as a hex string, decode it with `Data(base16Encoded:)` before verification:

```swift
import stellarsdk
import Foundation

let publicKey = try! KeyPair(accountId: "GABC...")

let message = "Cross-platform message"
let hexSignature = "a1b2c3d4..." // Received as hex
let signature = [UInt8](try Data(base16Encoded: hexSignature))

let isValid = try publicKey.verifyMessage(message, signature: signature)
```

### Signing binary data

The message doesn't have to be text. You can sign any binary data such as file contents:

```swift
import stellarsdk
import Foundation

let keyPair = try! KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

// Sign file contents
let fileContents = [UInt8](try Data(contentsOf: URL(fileURLWithPath: "document.pdf")))
let signature = try keyPair.signMessage(fileContents)

let base64Signature = Data(signature).base64EncodedString()
print("Document signature: \(base64Signature)")
```

### Authentication flow example

A complete authentication flow where the server generates a challenge and the client proves key ownership:

```swift
import stellarsdk
import Foundation

// === SERVER: Generate a challenge ===
var randomBytes = [UInt8](repeating: 0, count: 16)
_ = SecRandomCopyBytes(kSecRandomDefault, 16, &randomBytes)
let challenge = "authenticate:\(Data(randomBytes).base16EncodedString()):\(Int(Date().timeIntervalSince1970))"

// === CLIENT: Sign the challenge ===
let clientKeyPair = try! KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
let signature = try clientKeyPair.signMessage(challenge)

let response: [String: String] = [
    "account_id": clientKeyPair.accountId,
    "signature": Data(signature).base64EncodedString(),
    "challenge": challenge,
]

// === SERVER: Verify the response ===
let publicKey = try! KeyPair(accountId: response["account_id"]!)
let decodedSignature = [UInt8](Data(base64Encoded: response["signature"]!)!)

if try publicKey.verifyMessage(response["challenge"]!, signature: decodedSignature) {
    print("User authenticated as \(response["account_id"]!)")
} else {
    print("Authentication failed")
}
```

## Error handling

### Signing without a private key

Attempting to sign with a public-key-only keypair throws `Ed25519Error.missingPrivateKey`:

```swift
import stellarsdk

// This keypair has no private key
let publicKeyOnly = try! KeyPair(accountId: "GABC...")

do {
    // Throws Ed25519Error.missingPrivateKey - no private key available
    let _ = try publicKeyOnly.signMessage("test")
} catch Ed25519Error.missingPrivateKey {
    print("Cannot sign: keypair has no private key")
}
```

### Checking before signing

Check `privateKey != nil` to determine whether a keypair has a private key before attempting to sign:

```swift
import stellarsdk
import Foundation

let keyPair = try! KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

if keyPair.privateKey != nil {
    let signature = try keyPair.signMessage("Important message")
    let base64Signature = Data(signature).base64EncodedString()
} else {
    print("Signing not possible - no private key")
}
```

### Common verification failures

When verification fails, several causes are possible:

```swift
import stellarsdk
import Foundation

let publicKey = try! KeyPair(accountId: "GABC...")
let signature = [UInt8](Data(base64Encoded: receivedSignature)!)

if try !publicKey.verifyMessage(message, signature: signature) {
    // Possible causes:
    // 1. Message was modified after signing
    // 2. Signature was modified or corrupted in transit
    // 3. Wrong public key used for verification
    // 4. Signature was created for a different message
    print("Invalid signature")
}

// Verification with a correct-length signature returns false on mismatch (does not throw)
let result = try publicKey.verifyMessage("Hello", signature: [UInt8](repeating: 0, count: 64)) // false, not an exception
```

## Protocol details

SEP-53 signing works like this:

```
signature = Ed25519Sign(privateKey, SHA256("Stellar Signed Message:\n" + message))
```

Verification reverses it:

```
valid = Ed25519Verify(publicKey, SHA256("Stellar Signed Message:\n" + message), signature)
```

The `"Stellar Signed Message:\n"` prefix provides domain separation. A signed message can never be confused with a Stellar transaction signature.

## Test vectors

Use these official test vectors from the SEP-53 specification to validate your implementation:

### ASCII message

```swift
import stellarsdk
import Foundation

let seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW"
let expectedAccountId = "GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L"
let message = "Hello, World!"

let keyPair = try! KeyPair(secretSeed: seed)
assert(keyPair.accountId == expectedAccountId)

let signature = try keyPair.signMessage(message)
let base64Signature = Data(signature).base64EncodedString()
let hexSignature = Data(signature).base16EncodedString()

// Expected signatures:
let expectedBase64 = "fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA=="
let expectedHex = "7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04"

assert(base64Signature == expectedBase64)
assert(hexSignature == expectedHex)

print("ASCII test vector passed")
```

### Japanese (UTF-8) message

```swift
import stellarsdk
import Foundation

let seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW"
let message = "こんにちは、世界！"

let keyPair = try! KeyPair(secretSeed: seed)
let signature = try keyPair.signMessage(message)

let expectedBase64 = "CDU265Xs8y3OWbB/56H9jPgUss5G9A0qFuTqH2zs2YDgTm+++dIfmAEceFqB7bhfN3am59lCtDXrCtwH2k1GBA=="
let expectedHex = "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604"

assert(Data(signature).base64EncodedString() == expectedBase64)
assert(Data(signature).base16EncodedString() == expectedHex)

print("Japanese test vector passed")
```

### Binary data message

```swift
import stellarsdk
import Foundation

let seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW"

// Binary data (base64-decoded)
let message = [UInt8](Data(base64Encoded: "2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=")!)

let keyPair = try! KeyPair(secretSeed: seed)
let signature = try keyPair.signMessage(message)

let expectedBase64 = "VA1+7hefNwv2NKScH6n+Sljj15kLAge+M2wE7fzFOf+L0MMbssA1mwfJZRyyrhBORQRle10X1Dxpx+UOI4EbDQ=="
let expectedHex = "540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d"

assert(Data(signature).base64EncodedString() == expectedBase64)
assert(Data(signature).base16EncodedString() == expectedHex)

print("Binary test vector passed")
```

## Security notes

### Display messages before signing

Always show users the full message before signing. Never auto-sign without user review. This prevents phishing where users sign malicious content.

### Key ownership vs account control

A valid signature proves the signer has the private key. It doesn't prove they control the account:

- **Multi-sig accounts**: One signature doesn't mean transaction authority
- **Revoked signers**: A key may have been removed from the account
- **Weight thresholds**: The key may lack sufficient weight

For critical operations, check the account's current state on-chain.

### Signature encoding

SEP-53 doesn't specify an encoding format. Common choices:

| Encoding | Pros | Cons |
|----------|------|------|
| Base64 | Compact, URL-safe variant available | Needs decode |
| Hex | Human-readable, simple | 2x larger |

Pick one and document it. The raw signature is always 64 bytes.

## Cross-SDK compatibility

SEP-53 signatures work across all Stellar SDKs. A signature created in Java, Python, or PHP can be verified in Swift, and vice versa.

**Compatible SDKs:** Java, Python, PHP, JavaScript, Kotlin (KMP), and this iOS/macOS SDK.

```swift
import stellarsdk
import Foundation

// Signature from Java/Python/PHP SDK
let base64Signature = "..."
let message = "Cross-platform message"

let publicKey = try! KeyPair(accountId: "GABC...")
let signature = [UInt8](Data(base64Encoded: base64Signature)!)

if try publicKey.verifyMessage(message, signature: signature) {
    print("Verified across SDKs")
}
```

## Related SEPs

- [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) - Web authentication for accounts
- [SEP-45](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md) - Web authentication for contract accounts

## Reference

- [SEP-53 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md)
- [KeyPair Source Code](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/crypto/KeyPair.swift)

---

[Back to SEP Overview](README.md)
