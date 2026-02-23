# SEP-23: Strkey Encoding

**Purpose:** Encode and decode Stellar addresses (public keys, seeds, contract IDs, muxed accounts, etc.) using the StrKey format — versioned base32 with CRC-16 checksum.

**Prerequisites:** None — these are pure utility methods on `String` and `Data`.

**Specification:** [SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md)

## Table of Contents

1. [Address Types and Prefixes](#address-types-and-prefixes)
2. [Decoding Addresses (String → Data)](#decoding-addresses)
3. [Encoding Addresses (Data → String)](#encoding-addresses)
4. [Validation](#validation)
5. [Muxed Accounts (M-addresses)](#muxed-accounts)
6. [Signed Payloads (P-addresses)](#signed-payloads)
7. [Contract IDs (C-addresses)](#contract-ids)
8. [Liquidity Pool IDs (L-addresses)](#liquidity-pool-ids)
9. [Claimable Balance IDs (B-addresses)](#claimable-balance-ids)
10. [Error Handling](#error-handling)
11. [Common Pitfalls](#common-pitfalls)

---

## Address Types and Prefixes

The `VersionByte` enum defines the version byte for each address type:

| Type | Prefix | `VersionByte` case | Raw value | Use |
|------|--------|-------------------|-----------|-----|
| Ed25519 public key | `G` | `.ed25519PublicKey` | 48 | Standard account address |
| Ed25519 secret seed | `S` | `.ed25519SecretSeed` | 144 | Private key (never share) |
| Muxed Ed25519 public key | `M` | `.med25519PublicKey` | 96 | Account with embedded memo ID |
| Pre-authorized TX hash | `T` | `.preAuthTX` | 152 | Multi-sig signer |
| SHA-256 hash | `X` | `.sha256Hash` | 184 | Hash-based signer |
| Signed payload | `P` | `.signedPayload` | 120 | CAP-40 payload signer |
| Smart contract | `C` | `.contract` | 16 | Soroban contract address |
| Liquidity pool | `L` | `.liquidityPool` | 88 | AMM pool identifier |
| Claimable balance | `B` | `.claimableBalance` | 8 | Claimable balance identifier |

All standard address types (G, S, T, X, C, L) encode to **56 characters**. Muxed accounts (M) are **69 characters**. Claimable balances (B) are **58 characters**. Signed payloads (P) are **69–165 characters**.

---

## Decoding Addresses

`String` extensions decode StrKey strings back to raw `Data`. All decode methods throw `KeyUtilsError` on failure.

```swift
import stellarsdk

// G-address → 32-byte raw public key
let pubKeyData: Data = try "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".decodeEd25519PublicKey()

// S-address → 32-byte raw seed
let seedData: Data = try "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU".decodeEd25519SecretSeed()

// T-address → 32-byte raw pre-auth TX hash
let preAuthData: Data = try someStrKey.decodePreAuthTx()

// X-address → 32-byte raw SHA-256 hash
let hashData: Data = try someStrKey.decodeSha256Hash()

// C-address → 32-byte raw contract ID
let contractData: Data = try "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".decodeContractId()

// C-address → hex string
let contractHex: String = try "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".decodeContractIdToHex()
// → "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103"

// L-address → 32-byte raw liquidity pool ID
let lpData: Data = try "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN".decodeLiquidityPoolId()

// L-address → hex string
let lpHex: String = try "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN".decodeLiquidityPoolIdToHex()

// B-address → raw data (33 bytes: 1-byte type discriminant + 32-byte ID)
let cbData: Data = try "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".decodeClaimableBalanceId()

// B-address → hex string (includes 1-byte type discriminant "00" prefix)
let cbHex: String = try "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".decodeClaimableBalanceIdToHex()
// → "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"

// M-address → MuxedAccountXDR
let muxed: MuxedAccountXDR = try "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK".decodeMuxedAccount()

// M-address → raw data (for raw XDR bytes)
let muxedData: Data = try "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK".decodeMed25519PublicKey()

// P-address → Ed25519SignedPayload
let signedPayload: Ed25519SignedPayload = try "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM".decodeSignedPayload()
let pk: PublicKey = try signedPayload.publicKey()           // the signer's public key
let payloadBytes: Data = signedPayload.payload              // the raw payload
```

---

## Encoding Addresses

`Data` extensions encode raw bytes into StrKey strings. All encode methods throw on failure.

```swift
import stellarsdk

// 32-byte raw data → G-address
let gAddress: String = try publicKeyData.encodeEd25519PublicKey()

// 32-byte raw data → S-address
let sAddress: String = try seedData.encodeEd25519SecretSeed()

// 32-byte raw data → T-address
let tAddress: String = try preAuthData.encodePreAuthTx()

// 32-byte raw data → X-address
let xAddress: String = try hashData.encodeSha256Hash()

// 32-byte raw data → C-address
let cAddress: String = try contractData.encodeContractId()

// 32-byte raw data → L-address
let lAddress: String = try lpData.encodeLiquidityPoolId()

// 32-byte raw data → B-address
// NOTE: encodeClaimableBalanceId() auto-prepends the 1-byte type discriminant
// if data is exactly 32 bytes. Pass 33-byte data (with discriminant) or 32-byte
// data (without discriminant) — both work.
let bAddress: String = try cbData.encodeClaimableBalanceId()

// MuxedAccountXDR bytes → M- or G-address
// Decodes as MuxedAccountXDR first; returns M-address for med25519, G-address for ed25519
let muxedAddress: String = try xdrEncodedMuxedData.encodeMuxedAccount()

// XDR-encoded MuxedAccountXDR → M-address only (med25519 raw data)
let mAddress: String = try rawMuxedData.encodeMEd25519AccountId()
```

### Encode from hex strings

`String` extensions let you encode directly from hex without manually constructing `Data`:

```swift
// Hex → C-address
let cAddress: String = try "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103".encodeContractIdHex()
// → "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

// Hex → L-address
let lAddress: String = try "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".encodeLiquidityPoolIdHex()
// → "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"

// Hex (WITHOUT 1-byte discriminant) → B-address (discriminant is added automatically)
let bAddress: String = try "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".encodeClaimableBalanceIdHex()
// → "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
```

### Encode signed payload (P-address)

```swift
// Build from public key + payload bytes
let pk = try PublicKey(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
let payload = Data([0x01, 0x02, 0x03, 0x04])  // 4–64 bytes
let signedPayload = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: payload)
let pAddress: String = try signedPayload.encodeSignedPayload()

// Round-trip verification
let decoded = try pAddress.decodeSignedPayload()
let recoveredKey: PublicKey = try decoded.publicKey()
let recoveredPayload: Data = decoded.payload
```

---

## Validation

Validation methods return `Bool` and never throw. Use them to check user input before attempting a decode.

```swift
// Ed25519 public key (G-address, 56 chars)
"GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".isValidEd25519PublicKey()  // true
"SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU".isValidEd25519PublicKey()  // false (S-address)

// Secret seed (S-address, 56 chars)
"SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU".isValidEd25519SecretSeed()  // true
"GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".isValidEd25519SecretSeed()  // false (G-address)

// Muxed account (M-address, 69 chars)
"MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK".isValidMed25519PublicKey()  // true

// Pre-auth TX hash (T-address, 56 chars)
someStrKey.isValidPreAuthTx()

// SHA-256 hash (X-address, 56 chars)
someStrKey.isValidSha256Hash()

// Signed payload (P-address, 69–165 chars)
someStrKey.isValidSignedPayload()

// Contract ID (C-address, 56 chars)
"CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".isValidContractId()  // true
"GA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".isValidContractId()  // false (wrong prefix)

// Liquidity pool ID (L-address, 56 chars)
"LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN".isValidLiquidityPoolId()  // true

// Claimable balance ID (B-address, 58 chars)
"BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".isValidClaimableBalanceId()  // true

// Hex string utility
"3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".isHexString()  // true
"not-hex".isHexString()  // false
"123".isHexString()  // false (odd length)
```

### Validate before decode pattern

```swift
func processAddress(_ address: String) throws -> Data {
    // WRONG: call decode directly on untrusted input — throws on any invalid string
    // let data = try address.decodeEd25519PublicKey()

    // CORRECT: validate first, then decode
    guard address.isValidEd25519PublicKey() else {
        throw MyError.invalidAddress("Expected a G-address, got: \(address)")
    }
    return try address.decodeEd25519PublicKey()
}
```

---

## Muxed Accounts

Muxed accounts (M-addresses) embed a 64-bit ID inside a standard G-address to allow virtual sub-accounts without on-chain records.

```swift
import stellarsdk

// Decode M-address → MuxedAccountXDR
let address = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
let muxed: MuxedAccountXDR = try address.decodeMuxedAccount()

// Access base G-address and mux ID
let baseAccountId: String = muxed.ed25519AccountId  // the underlying G-address
let muxId: UInt64? = muxed.id                       // nil for plain ed25519, UInt64 for med25519

// Decode a G-address also works — returns .ed25519 case with id == nil
let gMuxed: MuxedAccountXDR = try "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N".decodeMuxedAccount()
// gMuxed.id == nil

// Build a MuxedAccountXDR and re-encode to M-address
let pk = try PublicKey(accountId: "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N")
let muxedStruct = MuxedAccountMed25519XDR(id: 12345, sourceAccountEd25519: pk.bytes)
let muxXdr = MuxedAccountXDR.med25519(muxedStruct)
var encoded = try XDREncoder.encode(muxXdr)
let muxData = Data(bytes: &encoded, count: encoded.count)
let mAddress: String = try muxData.encodeMuxedAccount()   // M-address

// Validate M-address
mAddress.isValidMed25519PublicKey()  // true

// Round-trip: M-address → raw bytes → M-address
let rawMuxedData = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a8000000000000000".data(using: .hexadecimal)!
let roundTripped: String = try rawMuxedData.encodeMEd25519AccountId()
```

---

## Signed Payloads

Signed payloads (P-addresses, CAP-40) combine an Ed25519 public key with an arbitrary payload (4–64 bytes).

```swift
import stellarsdk

// Build a signed payload signer using Signer utility
let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
let payload = Data([0x01, 0x02, 0x03, 0x04])   // 4–64 bytes

// Creates a SignerKeyXDR for use in SetOptions
let signerKey: SignerKeyXDR = try Signer.signedPayload(accountId: accountId, payload: payload)

// Build P-address from Ed25519SignedPayload directly
let pk = try PublicKey(accountId: accountId)
let signedPayload = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: payload)
let pAddress: String = try signedPayload.encodeSignedPayload()
// → "PA7QYNF7SOWQ3..."

// Validate and decode
guard pAddress.isValidSignedPayload() else { throw MyError.invalidSignedPayload }
let decoded: Ed25519SignedPayload = try pAddress.decodeSignedPayload()
let signerPublicKey: PublicKey = try decoded.publicKey()
let payloadData: Data = decoded.payload

// Payload size constraints
// WRONG: payload larger than 64 bytes throws StellarSDKError.invalidArgument
let tooLarge = Data(repeating: 0, count: 65)
_ = try Signer.signedPayload(accountId: accountId, payload: tooLarge)  // throws

// WRONG: empty payload encodes but fails isValidSignedPayload()
let emptyPayload = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: Data())
let emptyEncoded = try emptyPayload.encodeSignedPayload()
emptyEncoded.isValidSignedPayload()  // false — payload too short (min 4 bytes)
```

---

## Contract IDs

```swift
import stellarsdk

let contractStrKey = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

// Validate
contractStrKey.isValidContractId()  // true

// Decode C-address → raw Data (32 bytes)
let contractData: Data = try contractStrKey.decodeContractId()

// Decode C-address → hex string
let contractHex: String = try contractStrKey.decodeContractIdToHex()
// → "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103"

// Encode raw Data → C-address
let cAddress: String = try contractData.encodeContractId()

// Encode hex string → C-address
let cFromHex: String = try "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103".encodeContractIdHex()

// Use with SCAddressXDR (for Soroban contract invocations)
let address = try SCAddressXDR(contractId: contractStrKey)   // accepts C-address or hex
```

---

## Liquidity Pool IDs

```swift
import stellarsdk

let lpStrKey = "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"

// Validate
lpStrKey.isValidLiquidityPoolId()  // true

// Decode L-address → raw Data (32 bytes)
let lpData: Data = try lpStrKey.decodeLiquidityPoolId()

// Decode L-address → hex string
let lpHex: String = try lpStrKey.decodeLiquidityPoolIdToHex()
// → "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"

// Encode raw Data → L-address
let lAddress: String = try lpData.encodeLiquidityPoolId()

// Encode hex string → L-address
let lFromHex: String = try "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".encodeLiquidityPoolIdHex()
```

---

## Claimable Balance IDs

Claimable balance B-addresses include a 1-byte type discriminant (always `0x00` for `claimableBalanceIDTypeV0`) prepended before the 32-byte ID.

```swift
import stellarsdk

let cbStrKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"

// Validate
cbStrKey.isValidClaimableBalanceId()  // true

// Decode B-address → raw Data (33 bytes: 1-byte discriminant + 32-byte ID)
let cbData: Data = try cbStrKey.decodeClaimableBalanceId()

// Decode B-address → hex string (33 bytes, includes discriminant "00" prefix)
let cbHex: String = try cbStrKey.decodeClaimableBalanceIdToHex()
// → "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"

// Encode 33-byte Data (with discriminant) → B-address
let bAddress: String = try cbData.encodeClaimableBalanceId()

// Encode 32-byte Data (without discriminant) → B-address (discriminant auto-prepended)
let rawIdData: Data = cbData.dropFirst()  // remove the discriminant byte
let bFromRaw: String = try rawIdData.encodeClaimableBalanceId()  // same result

// Encode hex (32-byte, WITHOUT discriminant) → B-address (discriminant auto-prepended)
let bFromHex: String = try "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".encodeClaimableBalanceIdHex()

// Encode hex (33-byte, WITH discriminant) → B-address
let bFromFullHex: String = try "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".data(using: .hexadecimal)!.encodeClaimableBalanceId()

// Use with ClaimableBalanceIDXDR (accepts B-address or hex)
let cbXdr = try ClaimableBalanceIDXDR(claimableBalanceId: cbStrKey)   // from B-address
let cbXdrHex = try ClaimableBalanceIDXDR(claimableBalanceId: cbHex)   // from hex with discriminant

// Use with SCAddressXDR
let address = try SCAddressXDR(claimableBalanceId: cbStrKey)
let strKey = try address.getClaimableBalanceIdStrKey()  // → Optional("BAAD6DBUX6...")
```

---

## Error Handling

All decode methods throw `KeyUtilsError`. Hex-from-string encode methods (`encodeContractIdHex`, `encodeLiquidityPoolIdHex`, `encodeClaimableBalanceIdHex`) throw `StellarSDKError.invalidArgument`.

```swift
import stellarsdk

do {
    let data = try "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".decodeEd25519PublicKey()
} catch KeyUtilsError.invalidEncodedString {
    // Base32 decode failed, or re-encoding doesn't match (malformed string)
    print("Malformed StrKey string")
} catch KeyUtilsError.invalidVersionByte {
    // Version byte doesn't match expected type (e.g. S-address passed to decodeEd25519PublicKey)
    print("Wrong address type")
} catch KeyUtilsError.invalidChecksum {
    // CRC-16 checksum doesn't match (transcription error)
    print("Checksum mismatch — address may have a typo")
} catch {
    print("Unexpected error: \(error)")
}

// Hex encode errors
do {
    let _ = try "not-hex".encodeContractIdHex()
} catch StellarSDKError.invalidArgument(message: let message) {
    print("Invalid hex: \(message)")
}
```

---

## Common Pitfalls

**Wrong decode method for address type:**
```swift
let sAddress = "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU"

// WRONG: throws KeyUtilsError.invalidVersionByte
let data = try sAddress.decodeEd25519PublicKey()

// CORRECT: match the method to the address prefix
let data = try sAddress.decodeEd25519SecretSeed()
```

**Hex decode returns hex with discriminant; hex encode expects hex without:**
```swift
// decodeClaimableBalanceIdToHex() returns 33-byte hex (WITH 00 prefix)
let cbHex = try cbStrKey.decodeClaimableBalanceIdToHex()
// → "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"

// WRONG: passing the 33-byte hex back to encodeClaimableBalanceIdHex() double-prepends the discriminant
let wrong = try cbHex.encodeClaimableBalanceIdHex()  // incorrect result

// CORRECT option 1: use Data.encodeClaimableBalanceId() with the full 33-byte data
let cbData = try cbStrKey.decodeClaimableBalanceId()   // 33 bytes
let correct = try cbData.encodeClaimableBalanceId()    // correct B-address

// CORRECT option 2: strip the 2-char discriminant from hex first (32-byte hex)
let hexWithout = String(cbHex.dropFirst(2))  // remove "00" prefix
let correct2 = try hexWithout.encodeClaimableBalanceIdHex()  // correct B-address
```

**`isHexString()` returns true for empty string:**
```swift
// Empty string produces valid (but empty) hex data — isHexString() returns true
"".isHexString()  // true (implementation behavior — empty data is valid)

// CORRECT: also check length for non-trivial hex
let hex = ""
guard !hex.isEmpty && hex.isHexString() else { throw MyError.invalidHex }
```

**Odd-length hex strings are invalid:**
```swift
"123".isHexString()      // false — odd length cannot represent bytes
"1234".isHexString()     // true — 2 bytes
"0x1234".isHexString()   // true — 0x prefix is stripped automatically
```

**`encodeMuxedAccount()` vs `encodeMEd25519AccountId()`:**
```swift
// encodeMuxedAccount() decodes the bytes as MuxedAccountXDR first,
// then returns G-address for .ed25519, M-address for .med25519
let result = try xdrData.encodeMuxedAccount()  // M- or G-address depending on content

// encodeMEd25519AccountId() always encodes raw bytes as M-address (med25519 version byte)
// Use only for raw XDR payload bytes of a MuxedAccountMed25519XDR
let mAddress = try rawPayloadBytes.encodeMEd25519AccountId()  // always M-address
```

**Validation checks both prefix AND checksum AND length:**
```swift
// isValidEd25519PublicKey() returns false if:
// - String length != 56 characters
// - Version byte != ed25519PublicKey (0x30)
// - CRC-16 checksum doesn't match
// - Base32 decode fails

// Do NOT assume isValid*() only checks the prefix
let checksumedWrong = "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVT"  // last char changed
checksumedWrong.isValidEd25519PublicKey()  // false — checksum mismatch
```
