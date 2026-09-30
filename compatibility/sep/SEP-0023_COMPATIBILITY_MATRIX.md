# SEP-0023 (Strkeys) Compatibility Matrix

**Generated:** 2026-09-30

**SDK Version:** 3.12.0

**SEP Version:** 1.3.0

**SEP Status:** Active

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md

## SEP Summary

Strkey is an ASCII format for representing Stellar account IDs and addresses.

## Overall Coverage

**Total Coverage:** 100.0% (32/32 fields)

- ✅ **Implemented:** 32/32
- ❌ **Not Implemented:** 0/32

**Required Fields:** 100.0% (32/32)

**Optional Fields:** 100.0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/crypto/VersionByte.swift`
- `stellarsdk/stellarsdk/extensions/Data+KeyUtils.swift`
- `stellarsdk/stellarsdk/extensions/String+KeyUtils.swift`

### Key Classes

- **`VersionByte`**: Enum of the version bytes, one case per SEP-23 key type, with the encoded lengths each type allows
- **`Data+KeyUtils`**: Data extension with one encode function per key type, writing the version byte, the key bytes and the CRC-16 checksum as unpadded base32
- **`String+KeyUtils`**: String extension with one decode and one isValid function per key type; decoding checks the length, the canonical base32 re-encoding, the version byte, the checksum and the signed payload and claimable balance framing

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Key types | 100.0% | 100.0% | 9 | 9 |
| Test vectors quoted in the StrKey unit test files | 100.0% | 100.0% | 23 | 23 |

## Detailed Field Comparison

### Key types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `STRKEY_PUBKEY` | ✓ | ✅ | `VersionByte.ed25519PublicKey, encodeEd25519PublicKey(), decodeEd25519PublicKey()` | Base value 6 << 3 = 48, first character G |
| `STRKEY_MUXED` | ✓ | ✅ | `VersionByte.med25519PublicKey, encodeMEd25519AccountId(), decodeMed25519PublicKey()` | Base value 12 << 3 = 96, first character M |
| `STRKEY_PRIVKEY` | ✓ | ✅ | `VersionByte.ed25519SecretSeed, encodeEd25519SecretSeed(), decodeEd25519SecretSeed()` | Base value 18 << 3 = 144, first character S |
| `STRKEY_PRE_AUTH_TX` | ✓ | ✅ | `VersionByte.preAuthTX, encodePreAuthTx(), decodePreAuthTx()` | Base value 19 << 3 = 152, first character T |
| `STRKEY_HASH_X` | ✓ | ✅ | `VersionByte.sha256Hash, encodeSha256Hash(), decodeSha256Hash()` | Base value 23 << 3 = 184, first character X |
| `STRKEY_SIGNED_PAYLOAD` | ✓ | ✅ | `VersionByte.signedPayload, encodeSignedPayload(), decodeSignedPayload()` | Base value 15 << 3 = 120, first character P |
| `STRKEY_CONTRACT` | ✓ | ✅ | `VersionByte.contract, encodeContractId(), decodeContractId()` | Base value 2 << 3 = 16, first character C |
| `STRKEY_LIQUIDITY_POOL` | ✓ | ✅ | `VersionByte.liquidityPool, encodeLiquidityPoolId(), decodeLiquidityPoolId()` | Base value 11 << 3 = 88, first character L |
| `STRKEY_CLAIMABLE_BALANCE` | ✓ | ✅ | `VersionByte.claimableBalance, encodeClaimableBalanceId(), decodeClaimableBalanceId()` | Base value 1 << 3 = 8, first character B |

### Test vectors quoted in the StrKey unit test files

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `valid_01` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid non-multiplexed account |
| `valid_02` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid multiplexed account |
| `valid_03` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid multiplexed account in which unsigned id exceeds maximum signed 64-bit integer |
| `valid_04` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid signed payload with an ed25519 public key and a 32-byte payload. |
| `valid_05` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid signed payload with an ed25519 public key and a 29-byte payload which becomes zero padded. |
| `valid_06` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid contract |
| `valid_07` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid liquidity pool address |
| `valid_08` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Valid claimable balance address |
| `invalid_01` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid length (Ed25519 should be 32 bytes, not 5) |
| `invalid_02` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: The unused trailing bit must be zero in the encoding of the last three bytes (24 bits) as five base-32 symbols (... |
| `invalid_03` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid length (congruent to 1 mod 8) |
| `invalid_04` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid length (base-32 decoding should yield 35 bytes, not 36) |
| `invalid_05` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid algorithm (low 3 bits of version byte are 7) |
| `invalid_06` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid length (congruent to 6 mod 8) |
| `invalid_07` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid length (base-32 decoding should yield 43 bytes, not 44) |
| `invalid_08` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid algorithm (low 3 bits of version byte are 7) |
| `invalid_09` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Padding bytes are not allowed |
| `invalid_10` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid checksum |
| `invalid_11` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Length prefix specifies length that is shorter than payload in signed payload |
| `invalid_12` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Length prefix specifies length that is longer than payload in signed payload |
| `invalid_13` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: No zero padding in signed payload |
| `invalid_14` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: The unused trailing 2-bits must be zero in the encoding of the last symbol. |
| `invalid_15` | ✓ | ✅ | - | quoted in `StrKeyUnitTests.swift`: Invalid claimable balance type (first byte of binary key is not 0) |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional