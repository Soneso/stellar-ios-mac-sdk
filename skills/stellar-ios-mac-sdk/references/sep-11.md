# SEP-11: Txrep

**Purpose:** Convert Stellar transactions between base64-encoded XDR and human-readable key-value text (TxRep format), for debugging, auditing, and manual transaction construction.

**Prerequisites:** None — TxRep conversion works offline, no network or signing required.

**SDK Class:** `TxRep` (static methods only, no instantiation needed)

**Spec:** [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md)

## Table of Contents

1. [Core Operations](#core-operations)
2. [TxRep Format](#txrep-format)
3. [Memo Types](#memo-types)
4. [Preconditions](#preconditions)
5. [Fee Bump Transactions](#fee-bump-transactions)
6. [Soroban Transactions](#soroban-transactions)
7. [Error Handling](#error-handling)
8. [Common Pitfalls](#common-pitfalls)

---

## Core Operations

### toTxRep — XDR to Human-Readable Text

```swift
import stellarsdk

// Build and sign a transaction
let sourceKeyPair = try KeyPair(secretSeed: "SABC...")
let account = Account(keyPair: sourceKeyPair, sequenceNumber: 123456)

let payment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: Decimal(100)
)

let transaction = try Transaction(
    sourceAccount: account,
    operations: [payment],
    memo: Memo.text("Hello, Stellar!")
)
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

// Convert signed XDR envelope to TxRep
let xdrEnvelope = try transaction.encodedEnvelope()
let txRep = try TxRep.toTxRep(transactionEnvelope: xdrEnvelope)
print(txRep)
// type: ENVELOPE_TYPE_TX
// tx.sourceAccount: GABC...
// tx.fee: 100
// tx.seqNum: 123457
// tx.cond.type: PRECOND_NONE
// tx.memo.type: MEMO_TEXT
// tx.memo.text: "Hello, Stellar!"
// tx.operations.len: 1
// tx.operations[0].sourceAccount._present: false
// tx.operations[0].body.type: PAYMENT
// tx.operations[0].body.paymentOp.destination: GDEST...
// tx.operations[0].body.paymentOp.asset: XLM
// tx.operations[0].body.paymentOp.amount: 1000000000
// tx.ext.v: 0
// signatures.len: 1
// signatures[0].hint: <hex>
// signatures[0].signature: <hex>
```

**Signature:**
```swift
public static func toTxRep(transactionEnvelope: String) throws -> String
```
- `transactionEnvelope`: Base64-encoded XDR envelope string (from `transaction.encodedEnvelope()`)
- Returns: Multi-line TxRep string with `key: value` pairs
- Throws: `TxRepError` if XDR cannot be parsed

### fromTxRep — Human-Readable Text to XDR

```swift
import stellarsdk

let txRep = """
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
tx.fee: 100
tx.seqNum: 46489056724385793
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1535756672
tx.cond.timeBounds.maxTime: 1567292672
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O
tx.operations[0].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operations[0].body.paymentOp.amount: 400004000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 4aa07ed0
signatures[0].signature: defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d31b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c
"""

let xdrEnvelope = try TxRep.fromTxRep(txRep: txRep)
// Decode back to Transaction object for inspection
let transaction = try Transaction(envelopeXdr: xdrEnvelope)
print("Fee: \(transaction.fee)")  // 100
print("Ops: \(transaction.operations.count)")  // 1
```

**Signature:**
```swift
public static func fromTxRep(txRep: String) throws -> String
```
- `txRep`: Multi-line TxRep string
- Returns: Base64-encoded XDR envelope string
- Throws: `TxRepError` if required fields are missing or malformed

### Roundtrip

```swift
import stellarsdk

// XDR → TxRep → XDR (lossless roundtrip including signatures)
let originalEnvelope = try transaction.encodedEnvelope()
let txRep = try TxRep.toTxRep(transactionEnvelope: originalEnvelope)
let reconstructedEnvelope = try TxRep.fromTxRep(txRep: txRep)
assert(originalEnvelope == reconstructedEnvelope)  // Always true for valid transactions
```

---

## TxRep Format

### Key Naming Conventions

| Concept | TxRep key prefix |
|---------|-----------------|
| Regular transaction | `tx.` |
| Fee bump outer | `feeBump.tx.` |
| Fee bump inner | `feeBump.tx.innerTx.tx.` |
| Operations | `tx.operations[N].body.` |
| Op source account | `tx.operations[N].sourceAccount` |
| Signatures | `signatures[N].` |

### Amount Encoding

**Amounts in TxRep are stored in stroops (Int64), not decimal XLM.** The SDK converts automatically when going through `toTxRep` / `fromTxRep`, but the raw TxRep text shows stroops:

```
tx.operations[0].body.paymentOp.amount: 1000000000  (= 100 XLM, 1 XLM = 10,000,000 stroops)
```

When parsing from TxRep, amounts are converted back to `Decimal` for `PaymentOperation.amount`.

### Asset Format

```
XLM                                      (native)
USD:GABC...                              (credit_alphanum4)
LONGASSET:GABC...                        (credit_alphanum12)
```

### Comments

TxRep comments use parentheses. The parser strips text after `(` on each value line:
```
tx.fee: 100 (this is ignored)
```

Values with colons (e.g., memo text) are handled correctly — the parser joins all parts after the first `:`:
```
tx.memo.text: "test:value:with:colons"  (parses correctly)
```

### Operation Source Account

Each operation has an `_present` flag controlling whether it overrides the transaction source:
```
tx.operations[0].sourceAccount._present: false   (uses tx source)
tx.operations[0].sourceAccount._present: true    (operation has its own source)
tx.operations[0].sourceAccount: GSRC_ACCOUNT...  (required when _present: true)
```

---

## Memo Types

All five Stellar memo types are supported:

| Memo type | TxRep key | Value |
|-----------|-----------|-------|
| `MEMO_NONE` | `tx.memo.type` | `MEMO_NONE` (no additional key) |
| `MEMO_TEXT` | `tx.memo.text` | JSON-encoded string (quoted) |
| `MEMO_ID` | `tx.memo.id` | Unsigned integer |
| `MEMO_HASH` | `tx.memo.hash` | Hex-encoded 32-byte hash |
| `MEMO_RETURN` | `tx.memo.retHash` | Hex-encoded 32-byte hash |

```swift
import stellarsdk

// MEMO_NONE
let tx1 = try Transaction(sourceAccount: account, operations: [op], memo: Memo.none)
// → tx.memo.type: MEMO_NONE

// MEMO_TEXT
let tx2 = try Transaction(sourceAccount: account, operations: [op], memo: .text("Hello"))
// → tx.memo.type: MEMO_TEXT
// → tx.memo.text: "Hello"

// MEMO_ID
let tx3 = try Transaction(sourceAccount: account, operations: [op], memo: .id(12345))
// → tx.memo.type: MEMO_ID
// → tx.memo.id: 12345

// MEMO_HASH (32 bytes)
let hashData = Data(repeating: 1, count: 32)
let tx4 = try Transaction(sourceAccount: account, operations: [op], memo: .hash(hashData))
// → tx.memo.type: MEMO_HASH
// → tx.memo.hash: <hex>

// MEMO_RETURN (32 bytes)
let returnData = Data(repeating: 2, count: 32)
let tx5 = try Transaction(sourceAccount: account, operations: [op], memo: .returnHash(returnData))
// → tx.memo.type: MEMO_RETURN
// → tx.memo.retHash: <hex>
```

---

## Preconditions

Preconditions use `TransactionPreconditions` with optional `TimeBounds` and `LedgerBounds`.

### PRECOND_NONE (default)

```
tx.cond.type: PRECOND_NONE
```

### PRECOND_TIME (time-only bounds)

Used when only `timeBounds` is set (no ledger bounds or other V2 fields):
```
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1535756672
tx.cond.timeBounds.maxTime: 1567292672
```

```swift
import stellarsdk

let timeBounds = TimeBounds(minTime: 1535756672, maxTime: 1567292672)
let preconditions = TransactionPreconditions(timeBounds: timeBounds)
let transaction = try Transaction(
    sourceAccount: account,
    operations: [op],
    memo: Memo.none,
    preconditions: preconditions
)
```

### PRECOND_V2 (CAP-21 extended preconditions)

Used when any of ledgerBounds, minSeqNumber, minSeqAge, minSeqLedgerGap, or extraSigners are set:

```
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: true
tx.cond.v2.timeBounds.minTime: 1640000000
tx.cond.v2.timeBounds.maxTime: 1650000000
tx.cond.v2.ledgerBounds._present: true
tx.cond.v2.ledgerBounds.minLedger: 500
tx.cond.v2.ledgerBounds.maxLedger: 1000
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 0
```

```swift
import stellarsdk

// Ledger bounds only (triggers PRECOND_V2)
let ledgerBounds = LedgerBounds(minLedger: 100, maxLedger: 200)
let preconditions = TransactionPreconditions(ledgerBounds: ledgerBounds)

// Combined time + ledger bounds
let timeBounds = TimeBounds(minTime: 1640000000, maxTime: 1650000000)
let ledgerBounds = LedgerBounds(minLedger: 500, maxLedger: 1000)
let preconditions = TransactionPreconditions(ledgerBounds: ledgerBounds, timeBounds: timeBounds)

// minSeqNum, minSeqAge, minSeqLedgerGap
let preconditions = TransactionPreconditions(
    minSeqNumber: 100000,
    minSeqAge: 3600,    // seconds
    minSeqLedgerGap: 10
)
```

**`TransactionPreconditions` constructor:**
```swift
public init(
    ledgerBounds: LedgerBounds? = nil,
    timeBounds: TimeBounds? = nil,
    minSeqNumber: Int64? = nil,
    minSeqAge: UInt64 = 0,
    minSeqLedgerGap: UInt32 = 0,
    extraSigners: [SignerKeyXDR] = []
)
```

---

## Fee Bump Transactions

Fee bump transactions wrap an inner transaction with a different fee source and fee. The TxRep structure uses nested prefixes:

```
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GFEE_SOURCE...
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GINNER_SOURCE...
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 654322
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 1
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
...
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 1
feeBump.tx.innerTx.signatures[0].hint: <hex>
feeBump.tx.innerTx.signatures[0].signature: <hex>
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: <hex>
feeBump.signatures[0].signature: <hex>
```

```swift
import stellarsdk

// Build inner transaction
let innerKeyPair = try KeyPair(secretSeed: "SINNER...")
let innerAccount = Account(keyPair: innerKeyPair, sequenceNumber: 654321)
let payment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: Decimal(50)
)
let innerTx = try Transaction(
    sourceAccount: innerAccount,
    operations: [payment],
    memo: Memo.none
)
try innerTx.sign(keyPair: innerKeyPair, network: Network.testnet)

// Wrap in fee bump
let feeBumpKeyPair = try KeyPair.generateRandomKeyPair()
let feeBumpTx = try FeeBumpTransaction(
    sourceAccount: MuxedAccount(accountId: feeBumpKeyPair.accountId),
    fee: 200,
    innerTransaction: innerTx
)
try feeBumpTx.sign(keyPair: feeBumpKeyPair, network: Network.testnet)

// Convert to TxRep
let txRep = try TxRep.toTxRep(transactionEnvelope: feeBumpTx.encodedEnvelope())
// Roundtrip
let reconstructed = try TxRep.fromTxRep(txRep: txRep)
```

---

## Soroban Transactions

Soroban (smart contract) transactions include a `sorobanData` extension when they have resource footprint set. The TxRep reflects this with `tx.ext.v: 1` and `tx.sorobanData.*` keys:

```
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 100000
tx.sorobanData.resources.diskReadBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 50000
```

Regular transactions have `tx.ext.v: 0` (no soroban data).

Invoke host function operations:
```
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.contractId: <hex>
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.functionName: increment
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
```

---

## Error Handling

The `TxRep` class throws `TxRepError` for all parse and generation errors:

```swift
public enum TxRepError: Error {
    case missingValue(key: String)   // Required key absent from TxRep
    case invalidValue(key: String)   // Key present but value cannot be parsed
}
```

### Pattern

```swift
import stellarsdk

do {
    let txRep = try TxRep.toTxRep(transactionEnvelope: xdrString)
    print(txRep)
} catch TxRepError.missingValue(let key) {
    print("Missing required field: \(key)")
} catch TxRepError.invalidValue(let key) {
    print("Invalid value for field: \(key)")
} catch {
    print("Unexpected error: \(error)")
}

do {
    let envelope = try TxRep.fromTxRep(txRep: txRepString)
} catch TxRepError.missingValue(let key) {
    print("Missing: \(key)")
} catch TxRepError.invalidValue(let key) {
    print("Invalid: \(key)")
} catch {
    // StellarSDKError.invalidArgument can occur if the resulting
    // transaction would be structurally invalid (e.g., 0 operations)
    print("Error: \(error)")
}
```

### Limits enforced by `fromTxRep`

| Limit | Error |
|-------|-------|
| `signatures.len > 20` | `invalidValue(key: "signatures.len > 20")` |
| `operations.len > 100` | `invalidValue(key: "operations.len > 100")` |
| 0 operations in transaction | `StellarSDKError.invalidArgument` |

---

## Common Pitfalls

**`toTxRep` requires the full envelope XDR, not just the transaction body:**
```swift
// WRONG: passing transaction body XDR
let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.transactionXDR.xdrEncoded)

// CORRECT: use encodedEnvelope() which wraps in TransactionEnvelopeXDR
let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())
```

**Amounts in TxRep are stroops, not XLM decimal:**
```swift
// In TxRep: tx.operations[0].body.paymentOp.amount: 1000000000
// That is 100 XLM (1 XLM = 10,000,000 stroops)
// SDK converts automatically — do NOT manually divide/multiply
let txRep = try TxRep.toTxRep(transactionEnvelope: tx.encodedEnvelope())
let rebuiltTx = try TxRep.fromTxRep(txRep: txRep)  // amounts restored correctly
```

**Memo text in TxRep is JSON-encoded (quoted):**
```
// In TxRep output:
tx.memo.text: "Hello, World!"

// In fromTxRep input, the quotes are required:
// WRONG: tx.memo.text: Hello
// CORRECT: tx.memo.text: "Hello"
```

**`Account(keyPair:sequenceNumber:)` vs `Account(accountId:sequenceNumber:)` — both valid for TxRep roundtrips (no network needed):**
```swift
// Both work for offline TxRep conversion:
let account1 = Account(keyPair: keyPair, sequenceNumber: 123456)
let account2 = try Account(accountId: "GABC...", sequenceNumber: 123456)
```

**`seqNum` in TxRep is one higher than the Account's current sequence number:**

The sequence number increments when a transaction is built. The `Account` object holds the pre-transaction sequence number; TxRep shows the incremented value:
```
// Account has sequenceNumber: 123456
// TxRep shows: tx.seqNum: 123457
```
`fromTxRep` automatically subtracts 1 when reconstructing the `Account` object internally.

**PRECOND_V2 vs PRECOND_TIME — ledger bounds force PRECOND_V2:**
```swift
// WRONG assumption: timeBounds alone always produces PRECOND_TIME
// If you also set ledgerBounds, minSeqNumber, minSeqAge, or minSeqLedgerGap,
// the output will be PRECOND_V2 instead.

// PRECOND_TIME (time-only):
TransactionPreconditions(timeBounds: timeBounds)

// PRECOND_V2 (ledger bounds or any V2 field):
TransactionPreconditions(ledgerBounds: ledgerBounds)
TransactionPreconditions(ledgerBounds: lb, timeBounds: tb)
TransactionPreconditions(minSeqNumber: 100)
TransactionPreconditions(minSeqAge: 3600)
```

**Operation type strings are uppercase — use the exact strings from the spec:**
```
// WRONG: tx.operations[0].body.type: Payment
// CORRECT: tx.operations[0].body.type: PAYMENT

// All supported operation types:
// CREATE_ACCOUNT, PAYMENT, PATH_PAYMENT_STRICT_RECEIVE,
// PATH_PAYMENT_STRICT_SEND, MANAGE_SELL_OFFER, CREATE_PASSIVE_SELL_OFFER,
// SET_OPTIONS, CHANGE_TRUST, ALLOW_TRUST, ACCOUNT_MERGE, MANAGE_DATA,
// BUMP_SEQUENCE, MANAGE_BUY_OFFER, CREATE_CLAIMABLE_BALANCE,
// CLAIM_CLAIMABLE_BALANCE, BEGIN_SPONSORING_FUTURE_RESERVES,
// END_SPONSORING_FUTURE_RESERVES, REVOKE_SPONSORSHIP, CLAWBACK,
// CLAWBACK_CLAIMABLE_BALANCE, SET_TRUST_LINE_FLAGS,
// LIQUIDITY_POOL_DEPOSIT, LIQUIDITY_POOL_WITHDRAW,
// INVOKE_HOST_FUNCTION, EXTEND_FOOTPRINT_TTL, RESTORE_FOOTPRINT
```

**ACCOUNT_MERGE omits the operation prefix in its body keys:**
```
// Other operations use: tx.operations[0].body.paymentOp.destination
// ACCOUNT_MERGE uses: tx.operations[0].body.destination (no "accountMergeOp." prefix)
```
