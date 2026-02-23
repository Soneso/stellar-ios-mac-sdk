# SEP-05: Key Derivation for Stellar (BIP-39 / BIP-44)

**Purpose:** Derive Stellar keypairs from mnemonic phrases using hierarchical deterministic (HD) key derivation.
**Prerequisites:** None
**SDK Class:** `WalletUtils` (in `stellarsdk`)
**Derivation path:** `m/44'/148'/index'` — all levels are hardened

## Table of Contents

1. [Quick Start](#quick-start)
2. [Generating Mnemonics](#generating-mnemonics)
3. [Deriving KeyPairs from a Mnemonic](#deriving-keypairs-from-a-mnemonic)
4. [Passphrase Support](#passphrase-support)
5. [Multiple Account Derivation](#multiple-account-derivation)
6. [Language Support](#language-support)
7. [Working with the Derived KeyPair](#working-with-the-derived-keypair)
8. [Error Handling](#error-handling)
9. [API Reference](#api-reference)
10. [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```swift
import stellarsdk

// 1. Generate a new 24-word mnemonic (recommended)
let mnemonic = WalletUtils.generate24WordMnemonic()
print(mnemonic) // "bench hurt jump file august wise shallow faculty ..."

// 2. Derive the first Stellar account (m/44'/148'/0')
let keyPair0 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
print("Account:     \(keyPair0.accountId)")          // G...
print("Secret seed: \(keyPair0.secretSeed ?? "")")   // S...

// 3. Derive additional accounts from the same mnemonic
let keyPair1 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1)
let keyPair2 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 2)
```

---

## Generating Mnemonics

`WalletUtils` provides two static methods for generating BIP-39 mnemonics. Both return a plain `String` (space-separated words), not an object.

### 12-word mnemonic (128-bit entropy)

```swift
let mnemonic12 = WalletUtils.generate12WordMnemonic()
// Returns: "illness spike retreat truth genius clock brain pass fit cave bargain toe"

// Verify word count
let words = mnemonic12.components(separatedBy: " ")
print(words.count) // 12
```

### 24-word mnemonic (256-bit entropy — recommended for production)

```swift
let mnemonic24 = WalletUtils.generate24WordMnemonic()
// Returns: "bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better"

let words = mnemonic24.components(separatedBy: " ")
print(words.count) // 24
```

### With explicit language

Both methods accept an optional `language` parameter (default: `.english`):

```swift
let mnemonic = WalletUtils.generate12WordMnemonic(language: .spanish)
let mnemonic24 = WalletUtils.generate24WordMnemonic(language: .french)
```

### Restoring an existing mnemonic

There is no separate "restore" method. To use an existing mnemonic phrase, pass it directly as a `String` to `createKeyPair`:

```swift
let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
let keyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
// accountId:  GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
// secretSeed: SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN
```

---

## Deriving KeyPairs from a Mnemonic

`WalletUtils.createKeyPair(mnemonic:passphrase:index:)` implements the full SEP-05 derivation path `m/44'/148'/index'`. It:

1. Converts the mnemonic string to a 512-bit BIP-39 seed (PBKDF2-HMAC-SHA512, 2048 iterations)
2. Derives a master Ed25519 key from the seed
3. Traverses `m/44'/148'/index'` (all hardened levels)
4. Returns a `KeyPair` with both `accountId` and `secretSeed`

**Signature:**
```swift
static func createKeyPair(mnemonic: String, passphrase: String?, index: Int) throws -> KeyPair
```

**Parameters:**
- `mnemonic` — space-separated BIP-39 phrase string (12 or 24 words)
- `passphrase` — optional BIP-39 passphrase; pass `nil` or `""` for no passphrase
- `index` — account index (`0` = first account, `1` = second, etc.)

**SEP-05 Test Vectors:**

```swift
import stellarsdk

// Test Vector 1 — 12-word mnemonic, no passphrase
let mnemonic12 = "illness spike retreat truth genius clock brain pass fit cave bargain toe"

let kp0 = try WalletUtils.createKeyPair(mnemonic: mnemonic12, passphrase: nil, index: 0)
print(kp0.accountId)   // GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
print(kp0.secretSeed!) // SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN

let kp2 = try WalletUtils.createKeyPair(mnemonic: mnemonic12, passphrase: nil, index: 2)
print(kp2.accountId)   // GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW
print(kp2.secretSeed!) // SDAILLEZCSA67DUEP3XUPZJ7NYG7KGVRM46XA7K5QWWUIGADUZCZWTJP

// Test Vector 2 — 24-word mnemonic, no passphrase
let mnemonic24 = "bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better"

let kp0b = try WalletUtils.createKeyPair(mnemonic: mnemonic24, passphrase: nil, index: 0)
print(kp0b.accountId)   // GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ
print(kp0b.secretSeed!) // SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7
```

---

## Passphrase Support

An optional BIP-39 passphrase produces a completely different set of accounts from the same mnemonic. This is not a password for encryption — it changes the key derivation itself.

```swift
import stellarsdk

// Test Vector 4 — 24-word mnemonic with passphrase
let mnemonic = "cable spray genius state float twenty onion head street palace net private method loan turn phrase state blanket interest dry amazing dress blast tube"
let passphrase = "p4ssphr4se"

let kp0 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: passphrase, index: 0)
print(kp0.accountId)   // GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ
print(kp0.secretSeed!) // SAFWTGXVS7ELMNCXELFWCFZOPMHUZ5LXNBGUVRCY3FHLFPXK4QPXYP2X

let kp2 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: passphrase, index: 2)
print(kp2.accountId)   // GCLAQF5H5LGJ2A6ACOMNEHSWYDJ3VKVBUBHDWFGRBEPAVZ56L4D7JJID
print(kp2.secretSeed!) // SAF2LXRW6FOSVQNC4HHIIDURZL4SCGCG7UEGG23ZQG6Q2DKIGMPZV6BZ
```

**Empty string and nil are equivalent** — both produce the same keys:

```swift
// These produce identical keypairs
let kp1 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
let kp2 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "", index: 0)
// kp1.accountId == kp2.accountId — true
```

---

## Multiple Account Derivation

Derive multiple Stellar accounts from a single mnemonic by incrementing the index. Each index produces an independent keypair.

```swift
import stellarsdk

let mnemonic = WalletUtils.generate24WordMnemonic()

// Derive 5 accounts from the same mnemonic
for i in 0..<5 {
    let keyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: i)
    print("m/44'/148'/\(i)': \(keyPair.accountId)")
}
// m/44'/148'/0': GABC...
// m/44'/148'/1': GDEF...
// m/44'/148'/2': GHIJ...
// m/44'/148'/3': GKLM...
// m/44'/148'/4': GNOP...
```

---

## Language Support

Both `generate12WordMnemonic` and `generate24WordMnemonic` accept an optional `language` parameter of type `WordList` (a `public enum` in `stellarsdk`).

```swift
import stellarsdk

// English (default)
let en = WalletUtils.generate12WordMnemonic()
let en2 = WalletUtils.generate12WordMnemonic(language: .english) // identical

// Other supported languages
let chineseSimplified  = WalletUtils.generate24WordMnemonic(language: .chineseSimplified)
let chineseTraditional = WalletUtils.generate24WordMnemonic(language: .chineseTraditional)
let french   = WalletUtils.generate12WordMnemonic(language: .french)
let italian  = WalletUtils.generate12WordMnemonic(language: .italian)
let japanese = WalletUtils.generate24WordMnemonic(language: .japanese)
let korean   = WalletUtils.generate12WordMnemonic(language: .korean)
let spanish  = WalletUtils.generate24WordMnemonic(language: .spanish)

// Derivation works identically regardless of language
let keyPair = try WalletUtils.createKeyPair(mnemonic: french, passphrase: nil, index: 0)
print(keyPair.accountId)
```

**`WordList` enum cases:**

| Case | Language |
|------|----------|
| `.english` | English (default, 2048 words) |
| `.chineseSimplified` | Chinese Simplified (2048 words) |
| `.chineseTraditional` | Chinese Traditional (2048 words) |
| `.french` | French (2048 words) |
| `.italian` | Italian (2048 words) |
| `.japanese` | Japanese (2048 words) |
| `.korean` | Korean (2048 words) |
| `.spanish` | Spanish (2048 words) |

Each case also exposes its word list via the `words: [String]` property on `WordList`. For example `WordList.english.englishWords` returns the full `[String]` array.

---

## Working with the Derived KeyPair

`createKeyPair` returns a standard `KeyPair` with both keys populated. Use it exactly like any other `KeyPair`:

```swift
import stellarsdk

let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
let keyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)

// Access keys
print(keyPair.accountId)           // G-address (always present)
print(keyPair.secretSeed ?? "")    // S-address (present because derived from seed)

// secretSeed is Optional<String> — always non-nil when derived via createKeyPair
// but use guard or ?? to handle it safely
guard let secret = keyPair.secretSeed else { fatalError("No seed") }

// Use keypair for signing transactions
let sdk = StellarSDK.testNet()
let accountEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)
let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)
try transaction.sign(keyPair: keyPair, network: Network.testnet)
let result = await sdk.transactions.submitTransaction(transaction: transaction)
```

---

## Error Handling

`WalletUtils.createKeyPair` throws `Ed25519Error` on invalid input.

```swift
import stellarsdk

do {
    let keyPair = try WalletUtils.createKeyPair(
        mnemonic: "illness spike retreat truth genius clock brain pass fit cave bargain toe",
        passphrase: nil,
        index: 0
    )
    print(keyPair.accountId)
} catch Ed25519Error.invalidSeedLength {
    print("Derived seed is not 32 bytes — should not happen with valid mnemonic")
} catch {
    print("Derivation failed: \(error)")
}
```

**`Ed25519Error` cases relevant to SEP-05:**

| Error | Cause |
|-------|-------|
| `Ed25519Error.invalidSeedLength` | Derived key bytes are not 32 bytes (internal error) |
| `Ed25519Error.invalidSeed` | Invalid S-address format (when constructing `Seed` from secret string) |
| `Ed25519Error.seedGenerationFailed` | System RNG failed during random keypair generation |
| `Ed25519Error.missingPrivateKey` | Signing attempted with a public-only keypair |

Note: `createKeyPair` does NOT validate the mnemonic word list or checksum. Any string is accepted as the mnemonic input. Invalid or misspelled words will silently produce wrong (but deterministic) keys.

---

## API Reference

### `WalletUtils` (public final class, `Sendable`)

```swift
// Generate 12-word mnemonic (128-bit entropy)
static func generate12WordMnemonic(language: WordList = .english) -> String

// Generate 24-word mnemonic (256-bit entropy)
static func generate24WordMnemonic(language: WordList = .english) -> String

// Derive Stellar KeyPair at m/44'/148'/index'
static func createKeyPair(mnemonic: String, passphrase: String?, index: Int) throws -> KeyPair
```

### `WordList` (public enum)

```swift
public enum WordList {
    case english
    case chineseSimplified
    case chineseTraditional
    case french
    case italian
    case japanese
    case korean
    case spanish

    // Returns the 2048 words for this language
    var words: [String]
}
```

### `Ed25519Derivation` (public struct, `Sendable`)

Used internally by `WalletUtils.createKeyPair`. Exposed publicly for advanced use.

```swift
// Initialize master key from 64-byte BIP-39 seed
public init(seed: Data)

// Derive a hardened child key at the given index (index < 0x80000000)
// Internally adds 0x80000000 — do NOT pass a pre-hardened index
public func derived(at index: UInt32) -> Ed25519Derivation

// The derived 32-byte private key material
public let raw: Data

// The 32-byte chain code for further derivation
public let chainCode: Data
```

**Manual derivation (matches `createKeyPair` exactly):**

```swift
import stellarsdk

let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)  // 64 bytes

let masterKey  = Ed25519Derivation(seed: bip39Seed)
let purpose    = masterKey.derived(at: 44)   // m/44'
let coinType   = purpose.derived(at: 148)    // m/44'/148'
let account    = coinType.derived(at: 0)     // m/44'/148'/0'

let stellarSeed = try Seed(bytes: account.raw.bytes)
let keyPair     = KeyPair(seed: stellarSeed)
print(keyPair.accountId)   // GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
```

### `Mnemonic` (public final class)

Used internally by `WalletUtils`. Exposed publicly for advanced use.

```swift
// Generate a mnemonic string from secure random entropy
static func create(strength: Mnemonic.Strength = .normal, language: WordList = .english) -> String

// Generate a mnemonic from provided entropy Data
static func create(entropy: Data, language: WordList = .english) -> String

// Convert a mnemonic string to a 64-byte BIP-39 seed
static func createSeed(mnemonic: String, withPassphrase passphrase: String = "") -> Data
```

**`Mnemonic.Strength` enum:**

| Case | Entropy | Word count |
|------|---------|------------|
| `.normal` | 128 bits | 12 words |
| `.high` | 256 bits | 24 words |

---

## Common Pitfalls

**`secretSeed` is Optional — never force-unwrap without checking:**

```swift
// WRONG: crashes if keypair has no seed (e.g., created from accountId)
let secret = keyPair.secretSeed!

// CORRECT: guard or nil-coalescing
guard let secret = keyPair.secretSeed else {
    throw StellarSDKError.invalidArgument(message: "KeyPair has no secret seed")
}
```

**Mnemonic is a plain String, not an object:**

```swift
// CORRECT: pass the mnemonic string directly
let mnemonic = WalletUtils.generate24WordMnemonic()
let keyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)

// WRONG: WalletUtils does not accept Mnemonic objects (there is no fromMnemonic() taking Mnemonic)
// The Mnemonic class is internal; WalletUtils accepts String, not Mnemonic
```

**nil and empty-string passphrase produce the same keys:**

```swift
// Both are equivalent — nil is treated as empty string internally
let kp1 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
let kp2 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "", index: 0)
// kp1.accountId == kp2.accountId — true

// A non-empty passphrase produces DIFFERENT keys:
let kp3 = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
// kp3.accountId != kp1.accountId — completely different account
```

**`derived(at:)` takes unhardened indices — do NOT add 0x80000000 manually:**

```swift
// WRONG: passing a pre-hardened index causes fatalError("Invalid index")
let purpose = masterKey.derived(at: 44 + 0x80000000)  // fatalError!

// CORRECT: pass the plain index; hardening is applied internally
let purpose = masterKey.derived(at: 44)   // internally becomes 44 + 0x80000000
let coinType = purpose.derived(at: 148)   // internally becomes 148 + 0x80000000
let account  = coinType.derived(at: 0)    // internally becomes 0 + 0x80000000
```

**`createKeyPair` does not validate the mnemonic:**

```swift
// No error thrown — misspelled words are silently accepted and produce wrong keys
let badMnemonic = "illness spikE retreet truth genius clock brain pass fit cave bargain toe"
let keyPair = try WalletUtils.createKeyPair(mnemonic: badMnemonic, passphrase: nil, index: 0)
// Succeeds but produces a different (unexpected) keypair

// Always store and verify mnemonics carefully. No built-in validation API exists.
```

**`Seed(bytes:)` requires exactly 32 bytes — `Ed25519Derivation.raw` provides this:**

```swift
// Ed25519Derivation.raw is always 32 bytes — safe to use directly
let stellarSeed = try Seed(bytes: account.raw.bytes)  // correct

// WRONG: using the full 64-byte BIP-39 seed as a Seed
let stellarSeed = try Seed(bytes: [UInt8](bip39Seed))  // throws Ed25519Error.invalidSeedLength (64 bytes)
```

---
