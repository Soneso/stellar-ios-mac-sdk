# SEP-53: Sign/Verify Messages

**Purpose:** Sign and verify arbitrary messages with Ed25519 keypairs
**Prerequisites:** None
**SDK Class:** `KeyPair`

SEP-53 defines a standard method for signing and verifying arbitrary messages. The protocol prepends `"Stellar Signed Message:\n"` to the message, hashes with SHA-256, and signs the hash with Ed25519. This prefix prevents signed messages from being confused with Stellar transaction signatures.

## API

All methods are defined on `KeyPair`. No extra imports beyond `import stellarsdk`.

### Sign

```swift
// Sign a string (UTF-8 encoded internally)
func signMessage(_ message: String) throws -> [UInt8]

// Sign binary data
func signMessage(_ message: [UInt8]) throws -> [UInt8]
```

Both return a 64-byte Ed25519 signature.
Both throw `Ed25519Error.missingPrivateKey` if the keypair was created from an account ID (no private key).

### Verify

```swift
// Verify a string message
func verifyMessage(_ message: String, signature: [UInt8]) throws -> Bool

// Verify binary data
func verifyMessage(_ message: [UInt8], signature: [UInt8]) throws -> Bool
```

Returns `true` if valid, `false` if the signature does not match.
Throws `Ed25519Error.invalidSignatureLength` if `signature.count != 64`.

## Usage

### Sign and verify (round-trip)

```swift
import stellarsdk

let keyPair = try KeyPair(secretSeed: "SABC...")

// Sign
let signature = try keyPair.signMessage("I agree to the terms of service")

// Verify with the same keypair
let isValid = try keyPair.verifyMessage("I agree to the terms of service", signature: signature)
print(isValid) // true
```

### Verify with a public-key-only keypair

Verification requires only the public key. This is the typical server-side flow.

```swift
import stellarsdk

// Server: create keypair from account ID only — no private key needed
let verifier = try KeyPair(accountId: "GABC...")

// Receive signature as base64 from client
let signature = [UInt8](Data(base64Encoded: receivedBase64)!)

let isValid = try verifier.verifyMessage("I agree to the terms of service", signature: signature)
if isValid {
    print("Verified")
} else {
    print("Invalid signature")
}
```

### Sign binary data

The message can be any binary content, not just text.

```swift
import stellarsdk

let keyPair = try KeyPair(secretSeed: "SABC...")

let fileBytes = [UInt8](try Data(contentsOf: URL(fileURLWithPath: "document.pdf")))
let signature = try keyPair.signMessage(fileBytes)

// Encode signature for transmission
let base64Signature = Data(signature).base64EncodedString()
```

### Encode signature as hex

```swift
import stellarsdk

let keyPair = try KeyPair(secretSeed: "SABC...")
let signature = try keyPair.signMessage("Hello")

// WRONG: hexEncodedString() is deprecated
// let hex = Data(signature).hexEncodedString()

// CORRECT: use base16EncodedString()
let hex = Data(signature).base16EncodedString()

// Decode hex back to bytes for verification
let sigBytes = [UInt8](try Data(base16Encoded: hex))
let isValid = try keyPair.verifyMessage("Hello", signature: sigBytes)
```

### Error handling

```swift
import stellarsdk

// Signing with a public-key-only keypair
let publicOnly = try KeyPair(accountId: "GABC...")
do {
    let _ = try publicOnly.signMessage("test")
} catch Ed25519Error.missingPrivateKey {
    print("Keypair has no private key — create from secretSeed to sign")
}

// Verification with a malformed (wrong-length) signature
let keyPair = try KeyPair(secretSeed: "SABC...")
let shortSig = [UInt8](repeating: 0, count: 63)  // must be exactly 64 bytes
do {
    let _ = try keyPair.verifyMessage("test", signature: shortSig)
} catch Ed25519Error.invalidSignatureLength {
    print("Signature must be exactly 64 bytes")
}

// Verification returning false (not throwing)
let zeros = [UInt8](repeating: 0, count: 64)
let result = try keyPair.verifyMessage("test", signature: zeros)
// result == false — wrong message, wrong key, or corrupted signature
```

## WRONG/CORRECT pitfalls

```swift
// WRONG: Using plain sign() instead of signMessage() skips the SEP-53 prefix+hash
// CORRECT: Always use signMessage() for SEP-53 compliance
let wrongSig = keyPair.sign([UInt8]("Hello".utf8))     // NOT SEP-53
let correctSig = try keyPair.signMessage("Hello")       // SEP-53

// WRONG: Using verify() to check a signMessage() signature
// CORRECT: Always pair signMessage() with verifyMessage()
let wrongCheck = try keyPair.verify(signature: correctSig, message: [UInt8]("Hello".utf8))  // false
let correctCheck = try keyPair.verifyMessage("Hello", signature: correctSig)                 // true

// WRONG: hexEncodedString() is deprecated
// let hex = Data(signature).hexEncodedString()
// CORRECT:
let hex = Data(signature).base16EncodedString()

// WRONG: Passing signature as Data instead of [UInt8]
// let sig: Data = ...
// try keyPair.verifyMessage("Hello", signature: sig)  // compile error
// CORRECT:
// try keyPair.verifyMessage("Hello", signature: [UInt8](sig))
```

## Protocol internals

The SDK implements the SEP-53 hash as:

```
SHA-256("Stellar Signed Message:\n" + message_bytes)
```

The 32-byte hash is then signed with Ed25519. This happens automatically inside `signMessage()` and `verifyMessage()`. Do not pre-hash messages before calling these methods.

String overloads convert to UTF-8 bytes first; `signMessage("Hello")` and `signMessage([UInt8]("Hello".utf8))` produce identical signatures.

## Test vectors

These vectors come from the SDK's unit tests. All use the same keypair.

**Seed:** `SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW`
**Account ID:** `GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L`

```swift
import stellarsdk

let seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW"
let keyPair = try KeyPair(secretSeed: seed)
assert(keyPair.accountId == "GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L")

// Vector 1: ASCII string
let sig1 = try keyPair.signMessage("Hello, World!")
assert(Data(sig1).base16EncodedString() ==
    "7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd" +
    "6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04")

// Vector 2: UTF-8 multibyte (Japanese)
let sig2 = try keyPair.signMessage("こんにちは、世界！")
assert(Data(sig2).base16EncodedString() ==
    "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd98" +
    "0e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604")

// Vector 3: Binary data
let binaryMsg = [UInt8](Data(base64Encoded: "2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=")!)
let sig3 = try keyPair.signMessage(binaryMsg)
assert(Data(sig3).base16EncodedString() ==
    "540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539f" +
    "f8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d")

// All vectors pass round-trip verification
assert(try keyPair.verifyMessage("Hello, World!", signature: sig1))
assert(try keyPair.verifyMessage("こんにちは、世界！", signature: sig2))
assert(try keyPair.verifyMessage(binaryMsg, signature: sig3))
```

Signatures are deterministic: signing the same message twice with the same keypair produces identical bytes.

## Cross-SDK compatibility

SEP-53 signatures are interoperable across all Stellar SDKs that implement the spec (Java, Python, Flutter, PHP, iOS). A signature produced by one SDK can be verified by any other.

```swift
import stellarsdk

// Verify a signature received from a Flutter/PHP/Python client
let verifier = try KeyPair(accountId: "GABC...")
let sig = [UInt8](Data(base64Encoded: signatureFromOtherSDK)!)
let isValid = try verifier.verifyMessage("shared message", signature: sig)
```
