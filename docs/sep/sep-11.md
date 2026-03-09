# SEP-11: Txrep (Transaction Representation)

Txrep is a human-readable text format for Stellar transactions. It converts the binary XDR transaction format into a structured key-value format that's easy to read, edit, and audit. Each line represents a field from the transaction's XDR structure.

**When to use:** Debugging transactions, displaying transaction details to users before signing, creating transaction templates, comparing transactions, or building tools that inspect or modify transactions.

See the [SEP-11 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md) for full protocol details.

## Quick Example

Convert a base64-encoded XDR transaction envelope to human-readable Txrep format:

```swift
import stellarsdk

let xdrBase64 = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

let txRep = try TxRep.toTxRep(transactionEnvelope: xdrBase64)
print(txRep)
```

Output:
```
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
```

## Converting XDR to Txrep

### Standard transaction

Build a transaction programmatically and convert it to Txrep for inspection:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Build a transaction
let sourceKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CPMLIHJPFV5RXN5M6CSS")
let accountResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
switch accountResponse {
case .success(let sourceAccount):
    let payment = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV",
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: Decimal(100)
    )

    let transaction = try Transaction(
        sourceAccount: sourceAccount,
        operations: [payment],
        memo: Memo.text("Test payment")
    )

    try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

    // Convert to Txrep for review
    let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())
    print(txRep)
case .failure(let error):
    print("Error loading account: \(error)")
}
```

### Fee bump transaction

Fee bump transactions wrap an inner transaction with a new fee. The Txrep output shows the nested structure:

```swift
import stellarsdk

let feeBumpXdr = "AAAABQAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAAAAGQAAAAAgAAAAAx5Qe+wF5jJp3kYrOZ2zBOQOcTHjtRBuR/GrBTLYydyQAAAGQAAVlhAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAAAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAL68IAAAAAAAAAAAEtjJ3JAAAAQFzU5qFDIaZRUzUxf0BrRO2abx0PuMn3WKM7o8NXZvmB7K0zvS+HBlmDo2P/M3IZpF5Riax21neE0N9/WiHRuAoAAAAAAAAAAdoh7ugAAABARiKZWxfy8ZOPRj6yZRTKXAp1Aw6SoEn5OvnFbOmVztZtSRUaVOaCnBpdDWFBNJ6xBwsm7lMxvomMaOyNM3T/Bg=="

let txRep = try TxRep.toTxRep(transactionEnvelope: feeBumpXdr)
print(txRep)
```

Output shows the nested structure:
```
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GBSH2PI5ILVBQYGYCK3QLYHBCJK6W34W23QCSFOOBWSBOXG2EHXOQIV3
feeBump.tx.fee: 400
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GAY6KB56YBPGGJU54RRLHGO3GBHEBZYTDY5VCBXEP4NLAUZNRSO4SSMH
feeBump.tx.innerTx.tx.fee: 100
...
```

## Converting Txrep to XDR

Parse Txrep text back into a binary transaction you can sign and submit.

> **Note:** Trailing comments in Txrep values are ignored during parsing. For example, timestamps may include human-readable annotations like `1535756672 (Fri Aug 31 16:04:32 PDT 2018)` -- the parser extracts only the numeric value and discards the comment portion.

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

let xdrBase64 = try TxRep.fromTxRep(txRep: txRep)
print(xdrBase64)
```

## Txrep format reference

### Envelope types

The `type` field indicates the transaction envelope type:

```
type: ENVELOPE_TYPE_TX           # Standard transaction (V1)
type: ENVELOPE_TYPE_TX_V0        # Legacy V0 transaction
type: ENVELOPE_TYPE_TX_FEE_BUMP  # Fee bump transaction
```

### Transaction fields

Core transaction fields (all amounts are in stroops: 1 XLM = 10,000,000 stroops):

```
tx.sourceAccount: G...           # Source account ID (G... or M... for muxed)
tx.fee: 100                      # Total fee in stroops
tx.seqNum: 123456789             # Sequence number
```

### Preconditions

Preconditions restrict when a transaction is valid:

```
# Simple time bounds (PRECOND_TIME)
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0           # Unix timestamp, 0 = no minimum
tx.cond.timeBounds.maxTime: 1700000000  # Unix timestamp, 0 = no maximum

# Advanced preconditions (PRECOND_V2)
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: true
tx.cond.v2.timeBounds.minTime: 0
tx.cond.v2.timeBounds.maxTime: 0
tx.cond.v2.ledgerBounds._present: true
tx.cond.v2.ledgerBounds.minLedger: 1000
tx.cond.v2.ledgerBounds.maxLedger: 2000
tx.cond.v2.minSeqNum._present: true
tx.cond.v2.minSeqNum: 1234567890
tx.cond.v2.minSeqAge: 300               # Seconds since source account's sequence changed
tx.cond.v2.minSeqLedgerGap: 10          # Ledgers since source account's sequence changed
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: G...        # Additional required signer

# No preconditions
tx.cond.type: PRECOND_NONE
```

### Memo types

Memos attach metadata to transactions:

```
# No memo
tx.memo.type: MEMO_NONE

# Text memo (max 28 bytes UTF-8)
tx.memo.type: MEMO_TEXT
tx.memo.text: "Hello"

# Numeric ID memo
tx.memo.type: MEMO_ID
tx.memo.id: 12345

# Hash memo (32 bytes, hex-encoded)
tx.memo.type: MEMO_HASH
tx.memo.hash: 0102030405060708091011121314151617181920212223242526272829303132

# Return hash memo (32 bytes, hex-encoded)
tx.memo.type: MEMO_RETURN
tx.memo.retHash: 0102030405060708091011121314151617181920212223242526272829303132
```

### Asset formats

Assets use these formats:

```
XLM                                 # Native asset (SDK outputs "XLM")
native                              # Native asset (also valid for parsing)
USD:GISSUER...                      # 4-character code with issuer
LONGCODE:GISSUER...                 # 12-character code with issuer
abc123...def456:lp                  # Liquidity pool share (pool ID in hex + ":lp")
```

### Common operation types

Operations are indexed starting at 0:

```
# Payment
tx.operations[0].sourceAccount._present: false  # Uses tx source if false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: G...
tx.operations[0].body.paymentOp.asset: native
tx.operations[0].body.paymentOp.amount: 10000000  # 1 XLM

# Create Account
tx.operations[0].body.type: CREATE_ACCOUNT
tx.operations[0].body.createAccountOp.destination: G...
tx.operations[0].body.createAccountOp.startingBalance: 100000000  # 10 XLM

# Change Trust
tx.operations[0].body.type: CHANGE_TRUST
tx.operations[0].body.changeTrustOp.line: USD:GISSUER...
tx.operations[0].body.changeTrustOp.limit: 10000000000  # Max trustline limit

# Manage Sell Offer
tx.operations[0].body.type: MANAGE_SELL_OFFER
tx.operations[0].body.manageSellOfferOp.selling: USD:GISSUER...
tx.operations[0].body.manageSellOfferOp.buying: native
tx.operations[0].body.manageSellOfferOp.amount: 10000000
tx.operations[0].body.manageSellOfferOp.price.n: 1  # Numerator
tx.operations[0].body.manageSellOfferOp.price.d: 2  # Denominator (price = 0.5)
tx.operations[0].body.manageSellOfferOp.offerID: 0  # 0 = create new offer

# Set Options
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.homeDomain._present: true
tx.operations[0].body.setOptionsOp.homeDomain: "example.com"
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.signer._present: false

# Create Claimable Balance
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: native
tx.operations[0].body.createClaimableBalanceOp.amount: 10000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: G...
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL

# Claim Claimable Balance
tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE
tx.operations[0].body.claimClaimableBalanceOp.balanceID.v0: <64 hex chars>
```

### Soroban operations

Smart contract operations have additional fields for resources and authorization:

```
# Invoke Host Function (smart contract call)
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.contractId: <64 hex chars>
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.functionName: "transfer"
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args.len: 3
...

# Extend Footprint TTL (extend contract data lifetime)
tx.operations[0].body.type: EXTEND_FOOTPRINT_TTL
tx.operations[0].body.extendFootprintTTLOp.extendTo: 100000

# Restore Footprint (restore archived contract data)
tx.operations[0].body.type: RESTORE_FOOTPRINT
```

Soroban transactions include resource information in the extension:

```
tx.ext.v: 1
tx.sorobanData.resources.footprint.readOnly.len: 2
tx.sorobanData.resources.footprint.readOnly[0].type: CONTRACT_DATA
...
tx.sorobanData.resources.footprint.readWrite.len: 1
...
tx.sorobanData.resources.instructions: 1000000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 500
tx.sorobanData.resourceFee: 10000
```

### Signatures

Signatures authenticate the transaction:

```
signatures.len: 2
signatures[0].hint: 4aa07ed0     # Last 4 bytes of public key (hex)
signatures[0].signature: def...  # 64-byte Ed25519 signature (hex)
signatures[1].hint: 1234abcd
signatures[1].signature: abc...
```

## Practical examples

### Inspecting a transaction before signing

Display transaction details to a user for review before they sign:

```swift
import stellarsdk

// Transaction received from an external source (e.g., a SEP-7 URI)
let xdrBase64 = "AAAAAgAAAAD..."

// Convert to readable format for user review
let txRep = try TxRep.toTxRep(transactionEnvelope: xdrBase64)

print("=== Transaction Details ===")
print(txRep)
print("==========================")

// Extract and display specific fields for the user
let lines = txRep.split(separator: "\n").map { String($0) }
for line in lines {
    if line.contains("tx.fee:") {
        let fee = line.split(separator: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        if let feeInt = Int(fee) {
            print("Fee: \(Double(feeInt) / 10_000_000) XLM")
        }
    }
    if line.contains("paymentOp.amount:") {
        let amount = line.split(separator: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        if let amountInt = Int(amount) {
            print("Payment Amount: \(Double(amountInt) / 10_000_000)")
        }
    }
    if line.contains("paymentOp.destination:") {
        let dest = line.split(separator: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        print("Destination: \(dest)")
    }
}
```

### Round-trip conversion

Verify that conversions are lossless by converting XDR -> Txrep -> XDR:

```swift
import stellarsdk

let originalXdr = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

// Convert XDR -> Txrep -> XDR
let txRep = try TxRep.toTxRep(transactionEnvelope: originalXdr)
let reconstructedXdr = try TxRep.fromTxRep(txRep: txRep)

if originalXdr == reconstructedXdr {
    print("Round-trip successful! XDR matches exactly.")
} else {
    print("Warning: XDR mismatch detected.")
}
```

### Comparing two transactions

Use Txrep to compare transactions line by line:

```swift
import stellarsdk

let xdr1 = "AAAAAgAAAAD..."
let xdr2 = "AAAAAgAAAAD..."

let txRep1 = try TxRep.toTxRep(transactionEnvelope: xdr1)
let txRep2 = try TxRep.toTxRep(transactionEnvelope: xdr2)

let lines1 = txRep1.split(separator: "\n").map { String($0) }
let lines2 = txRep2.split(separator: "\n").map { String($0) }

print("Differences:")
for i in 0..<lines1.count {
    let line2 = i < lines2.count ? lines2[i] : ""
    if lines1[i] != line2 {
        print("Line \(i + 1):")
        print("  TX1: \(lines1[i])")
        print("  TX2: \(line2)")
    }
}
```

## Error handling

The SDK throws exceptions for invalid input. Wrap conversions in do-catch blocks:

```swift
import stellarsdk

// Handle invalid base64 or XDR
do {
    let txRep = try TxRep.toTxRep(transactionEnvelope: "not-valid-base64!")
} catch {
    print("Failed to parse XDR: \(error)")
}

// Handle invalid Txrep format
do {
    let invalidTxrep = "this is not valid txrep"
    let xdr = try TxRep.fromTxRep(txRep: invalidTxrep)
} catch {
    print("Invalid Txrep format: \(error)")
}

// Handle missing required fields
do {
    let incompleteTxrep = """
    type: ENVELOPE_TYPE_TX
    tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
    """
    // Missing fee, seqNum, memo, operations, etc.
    let xdr = try TxRep.fromTxRep(txRep: incompleteTxrep)
} catch {
    print("Missing required field: \(error)")
}

// Handle invalid account IDs
do {
    let badAccountTxrep = """
    type: ENVELOPE_TYPE_TX
    tx.sourceAccount: NOT_A_VALID_ACCOUNT
    tx.fee: 100
    tx.seqNum: 1
    tx.cond.type: PRECOND_NONE
    tx.memo.type: MEMO_NONE
    tx.operations.len: 0
    tx.ext.v: 0
    signatures.len: 0
    """
    let xdr = try TxRep.fromTxRep(txRep: badAccountTxrep)
} catch {
    print("Invalid account: \(error)")
}
```

## Working with amounts

Txrep displays amounts in stroops (the smallest unit). Use these conversions:

```swift
import stellarsdk

// Stroops to display units (XLM or asset units)
let stroops = 400004000
let displayAmount = Double(stroops) / 10_000_000 // 40.0004

// Display units to stroops
let amount = 25.5
let stroopsValue = Int(amount * 10_000_000) // 255000000

// Format for display
func formatAmount(_ stroops: Int) -> String {
    return String(format: "%.7f", Double(stroops) / 10_000_000)
}

print(formatAmount(400004000)) // "40.0004000"
```

## Supported operations

The SDK supports all Stellar operation types in Txrep format:

| Operation | Type Constant |
|-----------|---------------|
| Create Account | `CREATE_ACCOUNT` |
| Payment | `PAYMENT` |
| Path Payment Strict Receive | `PATH_PAYMENT_STRICT_RECEIVE` |
| Path Payment Strict Send | `PATH_PAYMENT_STRICT_SEND` |
| Manage Sell Offer | `MANAGE_SELL_OFFER` |
| Manage Buy Offer | `MANAGE_BUY_OFFER` |
| Create Passive Sell Offer | `CREATE_PASSIVE_SELL_OFFER` |
| Set Options | `SET_OPTIONS` |
| Change Trust | `CHANGE_TRUST` |
| Allow Trust | `ALLOW_TRUST` |
| Account Merge | `ACCOUNT_MERGE` |
| Inflation | `INFLATION` (deprecated) |
| Manage Data | `MANAGE_DATA` |
| Bump Sequence | `BUMP_SEQUENCE` |
| Create Claimable Balance | `CREATE_CLAIMABLE_BALANCE` |
| Claim Claimable Balance | `CLAIM_CLAIMABLE_BALANCE` |
| Begin Sponsoring Future Reserves | `BEGIN_SPONSORING_FUTURE_RESERVES` |
| End Sponsoring Future Reserves | `END_SPONSORING_FUTURE_RESERVES` |
| Revoke Sponsorship | `REVOKE_SPONSORSHIP` |
| Clawback | `CLAWBACK` |
| Clawback Claimable Balance | `CLAWBACK_CLAIMABLE_BALANCE` |
| Set Trustline Flags | `SET_TRUST_LINE_FLAGS` |
| Liquidity Pool Deposit | `LIQUIDITY_POOL_DEPOSIT` |
| Liquidity Pool Withdraw | `LIQUIDITY_POOL_WITHDRAW` |
| Invoke Host Function | `INVOKE_HOST_FUNCTION` |
| Extend Footprint TTL | `EXTEND_FOOTPRINT_TTL` |
| Restore Footprint | `RESTORE_FOOTPRINT` |

## Normalized Txrep

The SEP-11 specification defines a "normalized" form of Txrep with strict ordering and completeness requirements. The `toTxRep(transactionEnvelope:)` method produces normalized output where:

- Every field appears exactly once
- Fields appear in XDR marshaling order
- Array elements are in order from 0 to length-1
- Pseudo-fields (`._present`, `.len`) appear immediately before the values they affect

This makes the output suitable for comparing transactions or generating consistent documentation.

## Related SEPs

- [SEP-07](sep-07.md) - Uses Txrep concepts in the `replace` parameter for field substitution in transaction URIs

---

[Back to SEP Overview](README.md)
