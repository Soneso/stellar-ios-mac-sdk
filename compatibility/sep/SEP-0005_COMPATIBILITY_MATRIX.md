# SEP-0005 (Key Derivation Methods for Stellar Keys) Compatibility Matrix

**Generated:** 2026-01-07

**SDK Version:** 3.4.2

**SEP Version:** Unknown

**SEP Status:** Final

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md

## SEP Summary

This Stellar Ecosystem Proposal describes methods for key derivation for Stellar.

This should improve key storage and moving keys between wallets and apps.

## Overall Coverage

**Total Coverage:** 100.0% (23/23 fields)

- ✅ **Implemented:** 23/23
- ❌ **Not Implemented:** 0/23

**Required Fields:** 100.0% (15/15)

**Optional Fields:** 100.0% (8/8)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/libs/HDWallet/Mnemonic.swift`
- `stellarsdk/stellarsdk/crypto/WalletUtils.swift`
- `stellarsdk/stellarsdk/crypto/Ed25519Derivation.swift`
- `stellarsdk/stellarsdk/libs/HDWallet/WordList.swift`

### Key Classes

- **`Mnemonic`**: BIP-39 mnemonic generation, seed creation, and validation
- **`WalletUtils`**: High-level wallet utilities for key pair generation from mnemonics
- **`Ed25519Derivation`**: BIP-32/SLIP-0010 Ed25519 key derivation implementation
- **`WordList`**: BIP-39 word lists for multiple languages

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| BIP-39 Mnemonic Features | 100.0% | 100.0% | 5 | 5 |
| BIP-32 Key Derivation | 100.0% | 100.0% | 4 | 4 |
| BIP-44 Multi-Account Support | 100.0% | 100.0% | 3 | 3 |
| Key Derivation Methods | 100.0% | 100.0% | 3 | 3 |
| Language Support | 100.0% | 100.0% | 8 | 8 |

## Detailed Field Comparison

### BIP-39 Mnemonic Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `mnemonic_generation_12_words` | ✓ | ✅ | `generate12WordMnemonic` | Generate 12-word BIP-39 mnemonic phrase |
| `mnemonic_generation_24_words` | ✓ | ✅ | `generate24WordMnemonic` | Generate 24-word BIP-39 mnemonic phrase |
| `mnemonic_to_seed` | ✓ | ✅ | `createSeed` | Convert BIP-39 mnemonic to seed using PBKDF2 |
| `mnemonic_validation` | ✓ | ✅ | `create (with checksum)` | Validate BIP-39 mnemonic phrase (word list and checksum) |
| `passphrase_support` |  | ✅ | `createSeed(withPassphrase:)` | Support optional BIP-39 passphrase (25th word) |

### BIP-32 Key Derivation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `master_key_generation` | ✓ | ✅ | `Ed25519Derivation.init(seed:)` | Generate master key from seed |
| `hd_key_derivation` | ✓ | ✅ | `derived(at:)` | BIP-32 hierarchical deterministic key derivation |
| `child_key_derivation` | ✓ | ✅ | `derived(at:)` | Derive child keys from parent keys |
| `ed25519_curve` | ✓ | ✅ | `Ed25519Derivation` | Support Ed25519 curve for Stellar keys |

### BIP-44 Multi-Account Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `stellar_derivation_path` | ✓ | ✅ | `createKeyPair (m/44'/148'/index')` | Support Stellar's BIP-44 derivation path: m/44'/148'/account' |
| `multiple_accounts` | ✓ | ✅ | `createKeyPair(index:)` | Derive multiple Stellar accounts from single seed |
| `account_index_support` | ✓ | ✅ | `index parameter` | Support account index parameter in derivation |

### Key Derivation Methods

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `keypair_from_mnemonic` | ✓ | ✅ | `createKeyPair(mnemonic:passphrase:index:)` | Generate Stellar KeyPair from mnemonic |
| `seed_from_mnemonic` | ✓ | ✅ | `Mnemonic.createSeed` | Convert mnemonic to raw seed bytes |
| `account_id_from_mnemonic` | ✓ | ✅ | `createKeyPair().accountId` | Get Stellar account ID from mnemonic |

### Language Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `english` | ✓ | ✅ | `English` | English BIP-39 word list (2048 words) |
| `chinese_simplified` |  | ✅ | `ChineseSimplified` | Chinese Simplified BIP-39 word list |
| `chinese_traditional` |  | ✅ | `ChineseTraditional` | Chinese Traditional BIP-39 word list |
| `french` |  | ✅ | `French` | French BIP-39 word list |
| `italian` |  | ✅ | `Italian` | Italian BIP-39 word list |
| `japanese` |  | ✅ | `Japanese` | Japanese BIP-39 word list |
| `korean` |  | ✅ | `Korean` | Korean BIP-39 word list |
| `spanish` |  | ✅ | `Spanish` | Spanish BIP-39 word list |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional