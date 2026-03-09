# SEP-05: Key derivation for Stellar

SEP-05 defines how to generate Stellar keypairs from mnemonic phrases using hierarchical deterministic (HD) key derivation. Users can backup their entire wallet with a simple word list and derive multiple accounts from a single seed using the path `m/44'/148'/index'`.

**When to use:** Building wallets that support mnemonic backup phrases, recovering accounts from seed words, or generating multiple related accounts from a single master seed.

See the [SEP-05 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) for protocol details.

## Quick example

```swift
import stellarsdk

// Generate a new 24-word mnemonic
let mnemonic = WalletUtils.generate24WordMnemonic()
print(mnemonic)

// Derive the first account
let keyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
print("Account: \(keyPair.accountId)")
```

## Generating mnemonics

The SDK supports generating mnemonics with 12 or 24 words using cryptographically secure entropy.

### 12-word mnemonic

Standard security for most use cases (128 bits entropy):

```swift
import stellarsdk

let mnemonic = WalletUtils.generate12WordMnemonic()
print(mnemonic)
// e.g. "bind struggle sausage repair machine fee setup finish transfer stamp benefit economy"
```

### 24-word mnemonic

Higher security for larger holdings (256 bits entropy, recommended for production):

```swift
import stellarsdk

let mnemonic = WalletUtils.generate24WordMnemonic()
print(mnemonic)
// e.g. "cabbage verb depart erase cable eye crowd approve tower umbrella violin tube
//  island tortoise suspect resemble harbor twelve romance away rug current robust practice"
```

## Mnemonics in other languages

The SDK supports BIP-39 word lists in multiple languages:

```swift
import stellarsdk

// French
let french = WalletUtils.generate12WordMnemonic(language: .french)
print(french)

// Korean
let korean = WalletUtils.generate24WordMnemonic(language: .korean)
print(korean)

// Spanish
let spanish = WalletUtils.generate12WordMnemonic(language: .spanish)
print(spanish)
```

**Supported languages:**
- `.english` (default)
- `.french`
- `.spanish`
- `.italian`
- `.korean`
- `.japanese`
- `.chineseSimplified`
- `.chineseTraditional`

## Deriving keypairs from mnemonics

All derivation follows the SEP-05 path `m/44'/148'/index'` where 44 is the BIP-44 purpose, 148 is Stellar's registered coin type, and index is the account number.

### Basic derivation

```swift
import stellarsdk

let words = "shell green recycle learn purchase able oxygen right echo claim hill again "
    + "hidden evidence nice decade panic enemy cake version say furnace garment glue"
let keyPair0 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
print("Account 0: \(keyPair0.accountId)")
// GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K

print("Secret 0: \(keyPair0.secretSeed!)")
// SATLGMF3SP2V47SJLBFVKZZJQARDOBDQ7DNSSPUV7NLQNPN3QB7M74XH

// Second account (index 1)
let keyPair1 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 1)
print("Account 1: \(keyPair1.accountId)")
// GBPHPX7SZKYEDV5CVOA5JOJE2RHJJDCJMRWMV4KBOIE5VSDJ6VAESR2W
```

### Derivation with passphrase

An optional passphrase adds extra security. Different passphrases produce completely different accounts:

```swift
import stellarsdk

let words = "cable spray genius state float twenty onion head street palace net private "
    + "method loan turn phrase state blanket interest dry amazing dress blast tube"
let keyPair0 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: "p4ssphr4se", index: 0)
print("Account: \(keyPair0.accountId)")
// GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ

let keyPair1 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: "p4ssphr4se", index: 1)
print("Account: \(keyPair1.accountId)")
// GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC
```

### Derivation from non-English mnemonic

Generate a mnemonic in another language and derive keypairs from it:

```swift
import stellarsdk

// Generate a Korean mnemonic
let korean = WalletUtils.generate24WordMnemonic(language: .korean)
print(korean)

// Derive a keypair from the mnemonic
let keyPair = try WalletUtils.createKeyPair(mnemonic: korean, passphrase: nil, index: 0)
print("Account: \(keyPair.accountId)")
```

### Restoring from non-English mnemonic

Restore an existing mnemonic in another language:

```swift
import stellarsdk

// Restore from existing Japanese mnemonic
let words = "あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん "
    + "あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あおぞら"
let keyPair = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
print("Account: \(keyPair.accountId)")
// Note: Produces a different account than the English equivalent because
// BIP-39 uses the actual words (not entropy) to derive the seed
```

> **Note:** When restoring from non-English mnemonics, the words must match the exact encoding used by the SDK's BIP-39 wordlists. Some languages like Korean and Japanese may use different Unicode normalization forms (NFD vs NFC), which can cause validation failures with copy-pasted text.

### Multiple account derivation

A single mnemonic can derive an unlimited number of accounts. Index 0 is the primary account; subsequent indices are independent accounts under the same seed.

```swift
import stellarsdk

let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"

// Derive accounts 0-4
for i in 0..<5 {
    let kp = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: i)
    print("Account \(i): \(kp.accountId)")
}
// Account 0: GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
// Account 1: GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX
// Account 2: GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW
// Account 3: GAOD5NRAEORFE34G5D4EOSKIJB6V4Z2FGPBCJNQI6MNICVITE6CSYIAE
// Account 4: GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4
```

## Working with BIP-39 seeds

The 512-bit seed is derived from the mnemonic using PBKDF2 with 2048 iterations. Use these methods when interoperating with other wallets or tools.

### From a hex seed directly

When you have a pre-computed 64-byte BIP-39 seed (e.g. from a hardware wallet export or another library), you can use the lower-level `Ed25519Derivation` and `Mnemonic` classes to derive keypairs manually:

```swift
import stellarsdk

// Convert hex seed to Data
let hexSeed = "e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497e"
    + "e4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186"
let seedData = Data(hex: hexSeed)

// Derive using Ed25519Derivation manually
let masterKey = Ed25519Derivation(seed: seedData)
let purpose = masterKey.derived(at: 44)
let coinType = purpose.derived(at: 148)

let account0 = coinType.derived(at: 0)
let stellarSeed0 = try Seed(bytes: account0.raw.bytes)
let kp0 = KeyPair(seed: stellarSeed0)
print("Account: \(kp0.accountId)")
// GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6

let account1 = coinType.derived(at: 1)
let stellarSeed1 = try Seed(bytes: account1.raw.bytes)
let kp1 = KeyPair(seed: stellarSeed1)
print("Account: \(kp1.accountId)")
// GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX
```

### From seed Data

```swift
import stellarsdk

let seedData: Data = ... // your 64-byte seed
let masterKey = Ed25519Derivation(seed: seedData)
let purpose = masterKey.derived(at: 44)
let coinType = purpose.derived(at: 148)
let account = coinType.derived(at: 0)
let stellarSeed = try Seed(bytes: account.raw.bytes)
let kp = KeyPair(seed: stellarSeed)
```

## Restoring from words

Pass a space-separated word string to `WalletUtils.createKeyPair`:

```swift
import stellarsdk

let words = "illness spike retreat truth genius clock brain pass fit cave bargain toe"

do {
    let keyPair = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
    print("Recovered account: \(keyPair.accountId)")
    // GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
} catch {
    print("Derivation failed: \(error)")
}
```

## Mnemonic validation

> **Note:** The iOS SDK's `WalletUtils.createKeyPair` does **not** validate the mnemonic word list or checksum. Any string is accepted as input. Invalid or misspelled words will silently produce wrong (but deterministic) keys. Always store and verify mnemonics carefully.

## Entropy and security requirements

### Entropy standards

The SDK enforces BIP-39 entropy requirements:
- **Minimum**: 128 bits (12 words) - acceptable for most use cases
- **Recommended**: 256 bits (24 words) - recommended for production
- **Supported**: 128, 256 bits (12, 24 words)
- **Source**: Cryptographically secure random number generation

### Checksum validation

Each mnemonic includes a checksum to detect errors:
- **12 words**: 4-bit checksum (1 in 16 chance random words pass)
- **24 words**: 8-bit checksum (1 in 256 chance random words pass)
- **Generation**: Checksums are included automatically when generating mnemonics via `WalletUtils.generate12WordMnemonic()` or `WalletUtils.generate24WordMnemonic()`

## Security notes

- **Never share your mnemonic** -- Anyone with your words can access all derived accounts
- **Store mnemonics offline** -- Write them on paper, use a hardware wallet, or use encrypted storage
- **Use passphrases for extra security** -- A passphrase creates a completely different set of accounts
- **Verify checksums** -- Generated mnemonics include BIP-39 checksums automatically
- **Test recovery** -- Before using an account for real funds, verify you can recover it from the mnemonic
- **Hardware security** -- Consider using hardware wallets for high-value accounts

## Compatibility

The SDK is compatible with BIP-39 wallets and uses the standard Stellar derivation path `m/44'/148'/index'`.

## Test vectors

The SEP-05 specification includes detailed test vectors for validating implementations. Use these to verify your integration produces correct results across different mnemonic lengths, languages, and passphrases.

See the [official SEP-05 test vectors](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md#test-cases) in the specification.

## Related SEPs

- [SEP-30 Account Recovery](sep-30.md) - Uses mnemonics for account recovery flows

---

[Back to SEP Overview](README.md)
