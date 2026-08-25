# XDR Encoding and Decoding

- [Overview](#overview)
- [Transaction Envelope Encoding](#transaction-envelope-encoding)
- [Transaction Envelope Decoding](#transaction-envelope-decoding)
- [Transaction Inspection Before Signing](#transaction-inspection-before-signing)
- [SCValXDR: Smart Contract Values](#scvalxdr-smart-contract-values)
- [XDR Base64 Serialization](#xdr-base64-serialization)
- [XDR-JSON Serialization](#xdr-json-serialization)
- [Soroban Authorization Credentials](#soroban-authorization-credentials)
- [Ledger Key Construction](#ledger-key-construction)
- [Multi-Signature XDR Sharing](#multi-signature-xdr-sharing)
- [Transaction Hash](#transaction-hash)

All examples assume `import stellarsdk`.

## Overview

XDR (External Data Representation) is the binary format Stellar uses for all on-wire data. The SDK provides 456 XDR types in `stellarsdk/responses/xdr/`. All XDR types conform to the `XDRCodable` protocol and support encoding to base64 via the `xdrEncoded` property and decoding from base64 via `init(fromBase64:)` initializers.

## Transaction Envelope Encoding

Encode a transaction to a base64 XDR string for storage, sharing, or submission.

```swift
import stellarsdk

// sourceSecretSeed: String for your funded source account, loaded from secure storage
let sourceKeyPair = try KeyPair(secretSeed: sourceSecretSeed)
let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")

// Load account
let accountEnum = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
guard case .success(let accountDetails) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Account not found")
}

// Build and sign transaction
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100.0
)
let transaction = try Transaction(
    sourceAccount: accountDetails,
    operations: [paymentOp],
    memo: Memo.text("hello"),
    maxOperationFee: 100
)
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

// Encode to base64 XDR envelope
let envelopeXdr = try transaction.encodedEnvelope()
print("Envelope XDR: \(envelopeXdr)")

// Also available on the underlying XDR struct
let xdrString = transaction.transactionXDR.xdrEncoded
```

## Transaction Envelope Decoding

Decode a base64 XDR string back into a `Transaction` or `TransactionEnvelopeXDR` for inspection.

```swift
import stellarsdk

let envelopeBase64 = "AAAAAgAAAAD..."  // base64 XDR envelope string

// Decode into high-level Transaction
let transaction = try Transaction(envelopeXdr: envelopeBase64)
print("Source: \(transaction.sourceAccount.keyPair.accountId)")
print("Fee: \(transaction.fee)")
print("Operations: \(transaction.operations.count)")

// Decode into low-level XDR enum
let envelopeXDR = try TransactionEnvelopeXDR(fromBase64: envelopeBase64)
print("Source: \(envelopeXDR.txSourceAccountId)")
print("Sequence: \(envelopeXDR.txSeqNum)")
print("Fee: \(envelopeXDR.txFee)")
print("Memo: \(envelopeXDR.txMemo)")
print("Signatures: \(envelopeXDR.txSignatures.count)")

// Inspect operations at XDR level
for opXDR in envelopeXDR.txOperations {
    switch opXDR.body {
    case .paymentOp(let paymentOp):
        print("Payment to: \(paymentOp.destination)")
    case .invokeHostFunctionOp(let invokeOp):
        print("Soroban invocation")
    default:
        print("Other operation type")
    }
}
```

## Transaction Inspection Before Signing

Always inspect transaction contents before signing. This is critical for security.

```swift
import stellarsdk

// An unsigned payment envelope, as received from an external source
let unsignedXdr = "AAAAAgAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAGQAAAAAAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAABAAAAALJ7r6e8L9AEbNeWfERQz1ySnW56835+xAv3XTy9BUqtAAAAAAAAAAAF9eEAAAAAAAAAAAA="

let transaction = try Transaction(envelopeXdr: unsignedXdr)

// Verify source account
let expectedSource = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
guard transaction.sourceAccount.keyPair.accountId == expectedSource else {
    throw StellarSDKError.invalidArgument(message: "Unexpected source account")
}

// Verify operation count and types
print("Operations: \(transaction.operations.count)")
for (index, op) in transaction.operations.enumerated() {
    print("  [\(index)] \(type(of: op))")
    if let payment = op as? PaymentOperation {
        print("    Destination: \(payment.destinationAccountId)")
        print("    Amount: \(payment.amount)")
        print("    Asset: \(payment.asset.toCanonicalForm())")
    }
}

// Verify memo
print("Memo: \(transaction.memo)")

// Check for Soroban transaction data
switch transaction.transactionXDR.ext {
case .sorobanTransactionData(let data):
    print("Soroban resource fee: \(data.resourceFee)")
    print("Read-only keys: \(data.resources.footprint.readOnly.count)")
    print("Read-write keys: \(data.resources.footprint.readWrite.count)")
case .void:
    break
}

// Sign only after verification
let signerKeyPair = try KeyPair.generateRandomKeyPair()
try transaction.sign(keyPair: signerKeyPair, network: Network.testnet)
```

## SCValXDR: Smart Contract Values

`SCValXDR` is the universal value type for Soroban contract arguments and return values.

### Primitive Types

```swift
import stellarsdk
import Foundation

// Booleans
let boolVal = SCValXDR.bool(true)

// Void
let voidVal = SCValXDR.void

// Integers
let u32Val = SCValXDR.u32(42)
let i32Val = SCValXDR.i32(-42)
let u64Val = SCValXDR.u64(100)
let i64Val = SCValXDR.i64(-100)

// 128-bit integers (hi/lo parts)
let u128Val = SCValXDR.u128(UInt128PartsXDR(hi: 0, lo: 1_000_000_0))
let i128Val = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5_000_000))

// 128-bit from string (handles large values)
let bigU128 = try SCValXDR.u128(stringValue: "340282366920938463463374607431768211455")
let bigI128 = try SCValXDR.i128(stringValue: "-170141183460469231731687303715884105728")

// 256-bit integers
let u256Val = SCValXDR.u256(UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 999))
let i256Val = SCValXDR.i256(Int256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 999))

// Timepoint and Duration
let timestamp = SCValXDR.timepoint(UInt64(Date().timeIntervalSince1970))
let duration = SCValXDR.duration(3600)
```

### String and Bytes Types

```swift
import stellarsdk
import Foundation

let symbolVal = SCValXDR.symbol("transfer")
let stringVal = SCValXDR.string("hello world")
let bytesVal = SCValXDR.bytes(Data([0x01, 0x02, 0x03]))
let keyPair = try KeyPair.generateRandomKeyPair()
let pubKeyBytes = SCValXDR.bytes(Data(keyPair.publicKey.bytes))  // 32-byte raw Ed25519 public key

// CAP-85 executable tag (protocol 28) — the arm carries raw bytes
let tagVal = SCValXDR.executableTag(Data([0x74, 0x61, 0x67]))
let tagFromText = SCValXDR.executableTag("token-v1")  // String factory encodes UTF-8 exactly once
let tagText = tagFromText.executableTagString  // UTF-8 view; nil for another arm or non-UTF-8 bytes
```

### Address Types

```swift
import stellarsdk

// SCAddressXDR() throws (validates the address) but SCValXDR.address() does NOT throw
// WRONG: try SCValXDR.address(...) — try on the enum case, causes unnecessary-try warning
// CORRECT: SCValXDR.address(try SCAddressXDR(...)) — try on the constructor only
let accountAddr = SCValXDR.address(try SCAddressXDR(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"))

let contractAddr = SCValXDR.address(try SCAddressXDR(contractId: "CB3FU6M3TOAGRBLN5WDLXL6A7VR5SSRGULMXQQOABNMPS25YRJ4CN5VV"))
```

### Collections

```swift
import stellarsdk

// Vector
let vecVal = SCValXDR.vec([
    SCValXDR.u32(1),
    SCValXDR.u32(2),
    SCValXDR.u32(3)
])

// Map
let mapVal = SCValXDR.map([
    SCMapEntryXDR(key: SCValXDR.symbol("name"), val: SCValXDR.string("Alice")),
    SCMapEntryXDR(key: SCValXDR.symbol("age"), val: SCValXDR.u32(30))
])

// Special: ledger key for contract instance lookup
let instanceKey = SCValXDR.ledgerKeyContractInstance
```

### Reading SCValXDR Values

Use typed `is*` checks and optional property accessors:

```swift
import stellarsdk

let result: SCValXDR = // ... from contract invocation or XDR decoding

// Direct Swift types (no unwrapping needed)
if result.isBool, let b = result.bool { print("Bool: \(b)") }
if result.isSymbol, let s = result.symbol { print("Symbol: \(s)") }
if result.isString, let s = result.string { print("String: \(s)") }
if result.isVec, let items = result.vec { print("Vec: \(items.count) items") }
if result.isMap, let entries = result.map { print("Map: \(entries.count) entries") }

// Numeric types — return UInt32/Int32 directly
if result.isU32, let n = result.u32 { print("U32: \(n)") }
if result.isI32, let n = result.i32 { print("I32: \(n)") }

// 64-bit — return UInt64/Int64 directly
if result.isU64, let n = result.u64 { print("U64: \(n)") }
if result.isI64, let n = result.i64 { print("I64: \(n)") }

// 128-bit — returns parts struct with hi/lo UInt64 fields
if result.isU128, let parts = result.u128 {
    print("U128 hi: \(parts.hi), lo: \(parts.lo)")
}
if result.isI128, let parts = result.i128 {
    // Use string conversion for display
    if let balanceString = result.i128String {
        print("I128: \(balanceString)")
    }
}

// Address — unwrap to account or contract ID
if result.isAddress, let addr = result.address {
    if let accountId = addr.accountId {
        print("Account: \(accountId)")
    } else if let contractId = addr.contractId {
        print("Contract: \(contractId)")
    }
}

// Collections — iterate items/entries
if result.isVec, let items = result.vec {
    for item in items { print("Item: \(item)") }
}
if result.isMap, let entries = result.map {
    for entry in entries { print("\(entry.key) -> \(entry.val)") }
}
```

## XDR Base64 Serialization

Any `XDRCodable` type can be encoded/decoded via the `xdrEncoded` property and `fromBase64` initializers.

```swift
import stellarsdk

// Encode SCValXDR to base64
let val = SCValXDR.symbol("hello")
let base64 = val.xdrEncoded  // Optional<String>

// Decode SCValXDR from base64
let decoded = try SCValXDR.fromXdr(base64: base64!)

// Encode/decode SorobanAuthorizationEntryXDR
let authEntry: SorobanAuthorizationEntryXDR = ...
let authBase64 = authEntry.xdrEncoded!
let decodedAuth = try SorobanAuthorizationEntryXDR(fromBase64: authBase64)

// Encode/decode LedgerKeyXDR
let ledgerKey: LedgerKeyXDR = .account(LedgerKeyAccountXDR(accountID: publicKey))
let keyBase64 = ledgerKey.xdrEncoded!
let decodedKey = try LedgerKeyXDR(fromBase64: keyBase64)

// Encode/decode SorobanTransactionDataXDR
let txData: SorobanTransactionDataXDR = ...
let dataBase64 = txData.xdrEncoded!
let decodedData = try SorobanTransactionDataXDR(fromBase64: dataBase64)
```

## XDR-JSON Serialization

Every XDR type also converts to and from canonical JSON, for logs, diffs and fixtures rather than for submission.

```swift
import stellarsdk

let json = try SCValXDR.symbol("hello").toXdrJson()  // {"symbol":"hello"}
let back = try SCValXDR.fromXdrJson(json)
```

See [SEP-51](sep-51.md) for the mapping rules, the error cases and the types that carry no members.

## Soroban Authorization Credentials

`SorobanCredentialsXDR` is a union with four arms:

```swift
case sourceAccount
case address(SorobanAddressCredentialsXDR)                            // legacy, default
case addressV2(SorobanAddressCredentialsXDR)                          // protocol 27
case addressWithDelegates(SorobanAddressCredentialsWithDelegatesXDR)  // protocol 27
```

`SorobanAddressCredentialsWithDelegatesXDR` carries `addressCredentials: SorobanAddressCredentialsXDR` and `delegates: [SorobanDelegateSignatureXDR]`; `SorobanDelegateSignatureXDR` is recursive (`address: SCAddressXDR`, `signature: SCValXDR`, `nestedDelegates: [SorobanDelegateSignatureXDR]`).

Helper accessors on `SorobanCredentialsXDR`:

```swift
var address: SorobanAddressCredentialsXDR? { get }             // legacy .address arm ONLY; nil for V2/WITH_DELEGATES
var addressCredentials: SorobanAddressCredentialsXDR? { get }  // any address arm; nil for .sourceAccount
func withAddressCredentials(_ c: SorobanAddressCredentialsXDR) throws -> SorobanCredentialsXDR  // arm-preserving write-back
```

The signing preimage is selected by arm: `.address` uses `HashIDPreimageXDR.sorobanAuthorization` (`EnvelopeType.sorobanAuthorization`); `.addressV2` and `.addressWithDelegates` use `HashIDPreimageXDR.sorobanAuthorizationWithAddress` (`EnvelopeType.sorobanAuthorizationWithAddress` = 10, protocol 27), which additionally binds the top-level credential address. Build preimages via `SorobanAuthorizationEntryXDR.buildPreimage(network:)` -- see [soroban_contracts.md](./soroban_contracts.md) for signing and delegated authorization.

Simulation requests the V2 arm by default (`useUpgradedAuth`); emitting the V2 or WITH_DELEGATES arms on a pre-protocol-27 network invalidates the transaction, so opt out with `useUpgradedAuth: false` there.

## Ledger Key Construction

Ledger keys identify specific entries in the Stellar ledger. Used with `SorobanServer.getLedgerEntries`.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Account ledger key
let accountKey = LedgerKeyXDR.account(
    LedgerKeyAccountXDR(accountID: try PublicKey(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"))
)

// Contract data ledger key
let contractDataKey = LedgerKeyXDR.contractData(
    LedgerKeyContractDataXDR(
        contract: try SCAddressXDR(contractId: "CB3FU6M3TOAGRBLN5WDLXL6A7VR5SSRGULMXQQOABNMPS25YRJ4CN5VV"),
        key: SCValXDR.ledgerKeyContractInstance,
        durability: .persistent
    )
)

// Contract code ledger key (by WASM hash; example hash -- pass your wasm's 64-char hex hash)
let contractCodeKey = LedgerKeyXDR.contractCode(
    try LedgerKeyContractCodeXDR(wasmId: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
)

// Query ledger entries
let keys = [accountKey.xdrEncoded!, contractDataKey.xdrEncoded!]
let entriesEnum = await server.getLedgerEntries(base64EncodedKeys: keys)
switch entriesEnum {
case .success(let response):
    for entry in response.entries {
        print("Key: \(entry.key), Live until: \(entry.liveUntilLedgerSeq ?? 0)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Multi-Signature XDR Sharing

Share unsigned transactions between co-signers using base64 XDR encoding.

```swift
import stellarsdk

// Signer 1: Build and partially sign
// signerOneSecretSeed: String for the first signer, loaded from secure storage
// destinationAccountId: String for an existing testnet destination account
let signerOneKeyPair = try KeyPair(secretSeed: signerOneSecretSeed)
let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")

let accountEnum = await sdk.accounts.getAccountDetails(accountId: signerOneKeyPair.accountId)
guard case .success(let accountDetails) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Account not found")
}

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destinationAccountId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 500.0
)
let transaction = try Transaction(
    sourceAccount: accountDetails,
    operations: [paymentOp],
    memo: nil,
    maxOperationFee: 100
)
try transaction.sign(keyPair: signerOneKeyPair, network: Network.testnet)

// Encode and share with signer 2
let partiallySignedXdr = try transaction.encodedEnvelope()

// --- Transfer XDR string to signer 2 ---

// Signer 2: Decode, add signature, submit
// signerTwoSecretSeed: String for the second signer, loaded from secure storage
let signerTwoKeyPair = try KeyPair(secretSeed: signerTwoSecretSeed)
let receivedTransaction = try Transaction(envelopeXdr: partiallySignedXdr)
try receivedTransaction.sign(keyPair: signerTwoKeyPair, network: Network.testnet)

// Submit fully signed transaction
let submitEnum = await sdk.transactions.submitTransaction(transaction: receivedTransaction)
switch submitEnum {
case .success(let response):
    print("Submitted: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires memo")
case .failure(let error):
    print("Error: \(error)")
}
```

## Transaction Hash

Compute the transaction hash (used for lookups and verification) without submitting.

```swift
import stellarsdk

let transaction = try Transaction(envelopeXdr: envelopeBase64)
let txHash = try transaction.getTransactionHash(network: Network.testnet)
print("Transaction hash: \(txHash)")

let txHashData = try transaction.getTransactionHashData(network: Network.testnet)
print("Hash bytes: \(txHashData.count)")
```
