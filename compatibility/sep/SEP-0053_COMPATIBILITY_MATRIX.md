# SEP-0053 (Sign and Verify Messages) Compatibility Matrix

**Generated:** 2026-02-20

**SDK Version:** 3.4.4

**SEP Version:** 0.0.1

**SEP Status:** Draft

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md

## SEP Summary

This SEP proposes a canonical method for signing and verifying arbitrary messages using Stellar key pairs.

It aims to standardize message signing functionality across various Stellar wallets, libraries, and services, preventing ecosystem fragmentation and ensuring interoperability.

Stellar uses ed25519 keys for transaction signatures by design, but there is currently no canonical specification for signing arbitrary messages outside the normal transaction flow.

This proposal defines: - A message format supporting user-supplied data in various encodings - SHA-256 as the standard hashing function - Standardized procedures for signing and verifying messages off-chain By adopting this SEP, developers can seamlessly incorporate message signing capabilities for multi-lingual text or arbitrary bin.

## Overall Coverage

**Total Coverage:** 100.0% (8/8 fields)

- ✅ **Implemented:** 8/8
- ❌ **Not Implemented:** 0/8

**Required Fields:** 100.0% (8/8)

**Optional Fields:** 100.0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/crypto/KeyPair.swift`

### Key Classes

- **`KeyPair`**: Stellar key pair with SEP-53 message signing and verification methods (signMessage, verifyMessage, calculateMessageHash)

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Message Signing (SEP-53) | 100.0% | 100.0% | 8 | 8 |

## Detailed Field Comparison

### Message Signing (SEP-53)

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `message_prefix` | ✓ | ✅ | `calculateMessageHash (prefix constant)` | Uses "Stellar Signed Message:\n" prefix before hashing |
| `sha256_hashing` | ✓ | ✅ | `calculateMessageHash (SHA-256 hash)` | SHA-256 hash of prefixed message |
| `sign_message_binary` | ✓ | ✅ | `signMessage(_: [UInt8])` | Sign binary message per SEP-53 |
| `sign_message_string` | ✓ | ✅ | `signMessage(_: String)` | Sign UTF-8 string message per SEP-53 |
| `verify_message_binary` | ✓ | ✅ | `verifyMessage(_: [UInt8], signature:)` | Verify binary message signature per SEP-53 |
| `verify_message_string` | ✓ | ✅ | `verifyMessage(_: String, signature:)` | Verify UTF-8 string message signature per SEP-53 |
| `ed25519_signature` | ✓ | ✅ | `sign (Ed25519 64-byte signature)` | 64-byte Ed25519 signature output |
| `utf8_encoding` | ✓ | ✅ | `signMessage (UTF-8 encoding)` | UTF-8 encoding for string messages |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional