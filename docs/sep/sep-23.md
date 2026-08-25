# SEP-23: Strkey Encoding

SEP-23 defines how Stellar encodes addresses between raw binary data and human-readable strings. Each address type starts with a specific letter -- account IDs start with "G", secret seeds with "S", muxed accounts with "M", contracts with "C", and so on.

**When to use:** Validating user-entered addresses, converting between raw bytes and string representations, working with different key types, and creating muxed accounts for sub-account tracking.

See the [SEP-23 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md) for protocol details.

## Quick example

This example demonstrates the most common strkey operations: generating a keypair, validating addresses, and converting between formats.

```swift
import stellarsdk
import Foundation

// Generate a keypair
let keyPair = try KeyPair.generateRandomKeyPair()
let accountId = keyPair.accountId // G...

// Validate an address
if accountId.isValidEd25519PublicKey() {
    print("Valid account ID")
}

// Decode to raw bytes and encode back
let rawPublicKey: Data = try accountId.decodeEd25519PublicKey()
let encoded: String = try rawPublicKey.encodeEd25519PublicKey()
```

## Account IDs and secret seeds

Account IDs (G...) are public keys that identify accounts on the network. Secret seeds (S...) are private keys used for signing transactions -- never share these publicly.

```swift
import stellarsdk
import Foundation

// Generate a disposable keypair for this local round-trip example.
let keyPair = try KeyPair.generateRandomKeyPair()
let accountId = keyPair.accountId
let secretSeed = keyPair.secretSeed!

// Validate
accountId.isValidEd25519PublicKey() // true
secretSeed.isValidEd25519SecretSeed() // true

// Decode to raw 32-byte keys
let rawPublicKey: Data = try accountId.decodeEd25519PublicKey()
let rawPrivateKey: Data = try secretSeed.decodeEd25519SecretSeed()

// Encode raw bytes back to string
let encodedAccountId: String = try rawPublicKey.encodeEd25519PublicKey()
let encodedSeed: String = try rawPrivateKey.encodeEd25519SecretSeed()

// Derive account ID from seed
let derivedAccountId = try KeyPair(secretSeed: secretSeed).accountId
```

## Muxed accounts (M...)

Muxed accounts (defined in [CAP-27](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md)) allow you to multiplex multiple virtual accounts onto a single Stellar account. This is useful for exchanges, payment processors, and custodial services that need to track funds for many users without creating separate on-chain accounts.

A muxed account combines:
- An Ed25519 account ID (G-address) -- the underlying Stellar account
- A 64-bit unsigned integer ID -- identifies the virtual sub-account

When encoded, muxed accounts start with "M" instead of "G".

### Creating muxed accounts

You can create muxed accounts by combining a G-address with a numeric ID, or by parsing an M-address string.

```swift
import stellarsdk

let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
let userId: UInt64 = 1234567890

// Create a muxed account from G-address and ID
let muxedAccount = try MuxedAccount(accountId: accountId, id: userId)
let muxedAccountId = muxedAccount.accountId // M...

// Parse an existing M-address
let parsedMuxed = try MuxedAccount(
    accountId: "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
)
```

### Extracting muxed account components

When you receive an M-address, you can extract both the underlying G-address and the numeric ID.

```swift
import stellarsdk

let muxedAccountId =
    "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

let muxedAccount = try MuxedAccount(accountId: muxedAccountId)

// Get the underlying G-address (the actual on-chain account)
let ed25519AccountId = muxedAccount.ed25519AccountId
print("Underlying account: \(ed25519AccountId)")

// Get the 64-bit ID (identifies the virtual sub-account)
let id: UInt64? = muxedAccount.id
print("User ID: \(id ?? 0)")

// Get the M-address (same as input for muxed, or G-address if no ID)
let accountIdResult = muxedAccount.accountId
```

### Using muxed accounts in transactions

Muxed accounts can be used as source accounts and destinations in operations. The Stellar network processes these using the underlying G-address, while preserving the ID for tracking purposes.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Sender keypair (must control the underlying G-address)
let senderKeyPair = try KeyPair(
    secretSeed: "SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECA"
)
let senderAccountId = senderKeyPair.accountId

// Create muxed source account (sender with user ID 100)
let muxedSource = try MuxedAccount(accountId: senderAccountId, id: 100)

// Create muxed destination (recipient with user ID 200)
let destinationAccountId =
    "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
let muxedDestination = try MuxedAccount(accountId: destinationAccountId, id: 200)

// Build payment operation with muxed destination
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: muxedDestination.accountId, // Can use M-address directly
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)

// Note: Load the sender's underlying G-address account for the transaction
let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderAccountId)
guard case .success(let accountResponse) = accountEnum else { return }

let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

var transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)

try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)
```

### Low-level muxed account encoding

For direct manipulation of muxed account binary data, use the String and Data extension methods.

```swift
import stellarsdk
import Foundation

let muxedAccountId =
    "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

// Validate M-address format
muxedAccountId.isValidMed25519PublicKey() // true

// Decode to MuxedAccountXDR
let muxedXdr: MuxedAccountXDR = try muxedAccountId.decodeMuxedAccount()

// Decode to raw binary
let rawData: Data = try muxedAccountId.decodeMed25519PublicKey()

// Encode raw binary back to M-address
let encoded: String = try rawData.encodeMEd25519AccountId()
```

## Pre-auth TX and SHA-256 hashes

Pre-auth transaction hashes (T...) authorize specific transactions in advance. SHA-256 hashes (X...) are for hash-locked transactions that require revealing a preimage to sign.

```swift
import stellarsdk
import Foundation

// Pre-auth TX (T...)
// In practice, this would be a real transaction hash
var transactionHash = Data(count: 32)
_ = transactionHash.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
let preAuthTx: String = try transactionHash.encodePreAuthTx()
preAuthTx.isValidPreAuthTx() // true
let decodedPreAuth: Data = try preAuthTx.decodePreAuthTx()

// SHA-256 hash signer (X...)
// Use any 32-byte hash value
var hash = Data(count: 32)
_ = hash.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
let hashSigner: String = try hash.encodeSha256Hash()
hashSigner.isValidSha256Hash() // true
let decodedHash: Data = try hashSigner.decodeSha256Hash()
```

## Contract IDs (C...)

Soroban smart contracts are identified by C-addresses. These encode the 32-byte contract hash.

```swift
import stellarsdk
import Foundation

// Encode a 32-byte hash as a contract ID
let contractHash = Data(try KeyPair.generateRandomKeyPair().publicKey.bytes) // any 32 bytes
let contractId: String = try contractHash.encodeContractId() // C...

// Validate
contractId.isValidContractId() // true

// Decode to raw bytes or hex
let raw: Data = try contractId.decodeContractId()
let hex: String = try contractId.decodeContractIdToHex()

// Encode from raw bytes or hex
let encodedFromBytes: String = try raw.encodeContractId()
let encodedFromHex: String = try hex.encodeContractIdHex()
```

## Signed payloads (P...)

Signed payloads (defined in [CAP-40](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md)) combine a public key with arbitrary payload data. They are used for delegated signing scenarios where a signature covers both the transaction and additional application-specific data.

```swift
import stellarsdk
import Foundation

let keyPair = try KeyPair.generateRandomKeyPair()
let payload = Data([0x01, 0x02, 0x03, 0x04]) // 1-64 bytes of application data

let pk = try PublicKey(accountId: keyPair.accountId)
let signedPayload = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: payload)
let signedPayloadStr: String = try signedPayload.encodeSignedPayload() // P...

let decoded: Ed25519SignedPayload = try signedPayloadStr.decodeSignedPayload()
let signerPublicKey: PublicKey = try decoded.publicKey()
print(signerPublicKey)
```

## Liquidity pool and claimable balance IDs

Pool IDs (L...) identify AMM liquidity pools. Claimable balance IDs (B...) reference claimable balance entries. Both support hex encoding for interoperability with APIs.

```swift
import stellarsdk
import Foundation

// Liquidity pool ID (L...)
let poolHex =
    "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
let poolId: String = try poolHex.encodeLiquidityPoolIdHex()
poolId.isValidLiquidityPoolId() // true
let decodedPool: Data = try poolId.decodeLiquidityPoolId()

// Claimable balance ID (B...)
let balanceHex =
    "929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfd00000000" // 32 bytes
let balanceId: String = try balanceHex.encodeClaimableBalanceIdHex()
balanceId.isValidClaimableBalanceId() // true
let decodedBalance: Data = try balanceId.decodeClaimableBalanceId()

// The encoders take the 32-byte id, the 33-byte body that already opens with the
// CLAIMABLE_BALANCE_ID_TYPE_V0 discriminant, or the 36-byte XDR encoding Horizon
// reports (72 hex characters), and all give the same B-address.
// decodeClaimableBalanceIdToHex() returns the 33-byte form.
let balanceBodyHex: String = try balanceId.decodeClaimableBalanceIdToHex()
let sameBalanceId: String = try balanceBodyHex.encodeClaimableBalanceIdHex()
print(sameBalanceId == balanceId) // true

// ClaimableBalanceIDXDR accepts the same spellings (plus the B-address) and renders
// two of them: claimableBalanceIdString is the 33-byte body hex, paddedBalanceIdHex
// the 36-byte XDR-encoding hex Horizon serves, both lower case.
let cbXdr = try ClaimableBalanceIDXDR(claimableBalanceId: balanceId)
print(cbXdr.paddedBalanceIdHex)
// "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfd00000000"
```

## Version bytes reference

Each strkey type has a unique version byte that determines its prefix character:

| Prefix | Type | Description |
|--------|------|-------------|
| G | Account ID | Ed25519 public key |
| S | Secret Seed | Ed25519 private key |
| M | Muxed Account | Account ID + 64-bit ID |
| T | Pre-Auth TX | Pre-authorized transaction hash |
| X | SHA-256 Hash | Hash signer |
| P | Signed Payload | Public key + payload |
| C | Contract ID | Soroban smart contract |
| L | Liquidity Pool ID | AMM liquidity pool |
| B | Claimable Balance | Claimable balance entry |

## Error handling

Every `decode*` method throws `KeyUtilsError` when its input is malformed, and every `isValid*` method returns false for exactly the inputs its matching `decode*` rejects. `decodeMuxedAccount()` can also throw `Ed25519Error`. Validate when a boolean is enough, decode inside `do`/`catch` when you want to tell the user what went wrong.

`decodeMuxedAccount()` takes either address form and picks its error by input length: a malformed 56-character account ID throws `Ed25519Error.invalidPublicKey`, a malformed 69-character muxed address throws `KeyUtilsError`, and an input of any other length throws `KeyUtilsError.invalidEncodedString`. Catch both types.

```swift
import stellarsdk
import Foundation

// One mistyped character breaks the checksum, so the address is rejected
do {
    let _ = try "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGA"
        .decodeEd25519PublicKey()
} catch KeyUtilsError.invalidEncodedString {
    print("Wrong length, not canonical base32, or a malformed body")
} catch KeyUtilsError.invalidVersionByte {
    print("Not a G-address")
} catch KeyUtilsError.invalidChecksum {
    print("Checksum mismatch, most likely a typo")
} catch {
    print("Invalid: \(error)")
}

// A muxed account can arrive as either address form, so catch both error types
let address = "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5E" // last character changed
do {
    let _: MuxedAccountXDR = try address.decodeMuxedAccount()
} catch let error as Ed25519Error {
    print("Malformed account ID: \(error)")      // 56 characters
} catch let error as KeyUtilsError {
    print("Malformed muxed address: \(error)")   // 69 characters
} catch {
    print("Invalid: \(error)")
}

// Use validation to avoid exceptions
let input = "user-provided-address"
if input.isValidEd25519PublicKey() {
    let raw: Data = try input.decodeEd25519PublicKey()
} else if input.isValidMed25519PublicKey() {
    let muxed: MuxedAccountXDR = try input.decodeMuxedAccount()
    let raw: Data = try muxed.ed25519AccountId.decodeEd25519PublicKey()
} else {
    print("Invalid address format")
}

// MuxedAccount validates on construction
do {
    let _ = try MuxedAccount(accountId: "INVALID", id: 123)
} catch {
    print("Invalid: \(error)")
}
```

`KeyPair(accountId:)`, `KeyPair(secretSeed:)`, `PublicKey(accountId:)`, `Seed(secret:)` and `MuxedAccount(accountId:)` run the same decoder, so they accept exactly the strkeys `decode*` accepts. A secret seed with one wrong character fails its checksum and throws `Ed25519Error.invalidSeed`.

```swift
import stellarsdk

// Last character changed: the checksum no longer matches the body
do {
    let _ = try KeyPair(secretSeed: "SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECB")
} catch Ed25519Error.invalidSeed {
    print("Corrupted secret seed, check it against your backup")
} catch {
    print("Invalid: \(error)")
}
```

### Common validation errors

A strkey is rejected when any of these does not hold:

- **Encoded length**: exactly 56 characters for G, S, T, X, C and L, 69 for M, 58 for B, and 69 to 165 for P
- **Base32 characters**: only A-Z and 2-7, and the string must be the canonical encoding of the bytes it decodes to
- **Padding**: strkeys carry no `=` padding characters
- **Version byte**: the leading byte must be the one the requested type uses
- **Checksum**: the trailing CRC-16 must match the version byte and the body
- **Signed payload framing** (P): the body is the 32-byte signer key, a 4-byte big-endian length field naming 1 to 64 bytes of signed data, that signed data, and zero padding up to a multiple of four bytes. The body must be exactly 36 bytes plus the padded width of the signed data, and every padding byte must be zero
- **Claimable balance discriminant** (B): the body must open with `CLAIMABLE_BALANCE_ID_TYPE_V0` (byte `0x00`), the only type the XDR union defines

The encoders enforce the same rules on the bytes you hand them, so anything they accept decodes back. `Data.encodeSignedPayload()` requires the framing above, while `Data.encodeClaimableBalanceId()` takes the bare 32-byte id, putting the discriminant in front of it, the 33-byte body that already opens with it, or the 36-byte XDR encoding Horizon reports, whose four-byte union discriminant it verifies and strips. `Signer.signedPayload(accountId:payload:)` takes 1 to 64 bytes of payload. The fixed-width encoders -- `encodeEd25519PublicKey()`, `encodeEd25519SecretSeed()`, `encodePreAuthTx()`, `encodeSha256Hash()`, `encodeContractId()` and `encodeLiquidityPoolId()` at 32 bytes, `encodeMEd25519AccountId()` at 40 -- take that width and nothing else. All of them throw `StellarSDKError.invalidArgument`.

```swift
import stellarsdk
import Foundation

// A 31-byte key is not an ed25519 public key, so there is no G-address for it
do {
    let _ = try Data(repeating: 0, count: 31).encodeEd25519PublicKey()
} catch StellarSDKError.invalidArgument(let message) {
    print("Cannot encode: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Related specifications

- [SEP-05 Key Derivation](sep-05.md) -- Deriving keypairs from mnemonic phrases
- [SEP-10 Web Authentication](sep-10.md) -- Uses account IDs for authentication challenges
- [SEP-45 Web Authentication for Contract Accounts](sep-45.md) -- Authentication for Soroban contract accounts (C... addresses)

---

[Back to SEP Overview](README.md)
