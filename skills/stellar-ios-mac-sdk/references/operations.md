# Stellar Operations Reference

All 25 Stellar operations with verified Swift constructors. Every operation extends the base `Operation` class. Amounts use `Decimal` type. The optional `sourceAccountId: String?` parameter defaults to the transaction's source account when `nil`.

For method signatures on response objects, see [API Reference](./api_reference.md).

## Account & Balance Operations

### CreateAccountOperation

Creates and funds a new account on the network.

```swift
import stellarsdk

// Using KeyPair
let newKeyPair = try KeyPair.generateRandomKeyPair()
let createOp = CreateAccountOperation(
    sourceAccountId: nil,
    destination: newKeyPair,
    startBalance: 10.0  // Decimal - minimum ~1 XLM for base reserve
)

// Using account ID string
let createOp2 = try CreateAccountOperation(
    sourceAccountId: nil,
    destinationAccountId: "GABC...",
    startBalance: 100.0
)
```

**Parameters:** `destination: KeyPair` or `destinationAccountId: String`, `startBalance: Decimal`

### AccountMergeOperation

Transfers all native XLM balance to destination and removes source account.

```swift
let mergeOp = try AccountMergeOperation(
    destinationAccountId: "GDEST...",
    sourceAccountId: nil
)
```

**Parameters:** `destinationAccountId: String`, `sourceAccountId: String?`

### BumpSequenceOperation

Bumps the source account's sequence number to a specified value.

```swift
let bumpOp = BumpSequenceOperation(
    bumpTo: 12345678,  // Int64
    sourceAccountId: nil
)
```

**Parameters:** `bumpTo: Int64`, `sourceAccountId: String?`

## Payment Operations

### PaymentOperation

Sends an asset from source to destination account.

```swift
// Native XLM payment
let xlmAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
let payOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: xlmAsset,
    amount: 100.0  // Decimal
)

// Issued asset payment (1-4 char codes use ALPHANUM4, 5-12 char codes use ALPHANUM12)
let usdAsset = Asset(
    type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,  // "USD" is 3 chars → ALPHANUM4
    code: "USD",
    issuer: try KeyPair(accountId: "GISSUER...")
)!
let usdPayment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: usdAsset,
    amount: 50.0
)
```

**Parameters:** `sourceAccountId: String?`, `destinationAccountId: String`, `asset: Asset`, `amount: Decimal`

### PathPaymentStrictReceiveOperation

Sends a payment through a path of DEX offers, guaranteeing the exact destination amount received. Sender specifies a maximum send amount.

```swift
let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
let usd = Asset(
    type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
    code: "USD",
    issuer: try KeyPair(accountId: "GISSUER...")
)!

let pathPayOp = try PathPaymentStrictReceiveOperation(
    sourceAccountId: nil,
    sendAsset: xlm,
    sendMax: 200.0,              // Decimal - max source willing to send
    destinationAccountId: "GDEST...",
    destAsset: usd,
    destAmount: 50.0,            // Decimal - exact amount destination receives
    path: []                     // [Asset] - intermediate assets, max 5
)
```

**Parameters:** `sourceAccountId: String?`, `sendAsset: Asset`, `sendMax: Decimal`, `destinationAccountId: String`, `destAsset: Asset`, `destAmount: Decimal`, `path: [Asset]`

### PathPaymentStrictSendOperation

Sends a payment through a path of DEX offers, guaranteeing the exact source amount sent. Sender specifies a minimum destination amount.

```swift
let strictSendOp = try PathPaymentStrictSendOperation(
    sourceAccountId: nil,
    sendAsset: xlm,
    sendMax: 100.0,              // Decimal - exact amount source sends (named sendMax in parent)
    destinationAccountId: "GDEST...",
    destAsset: usd,
    destAmount: 20.0,            // Decimal - minimum destination receives (named destAmount in parent)
    path: []
)
```

**Parameters:** Same as `PathPaymentStrictReceiveOperation`. For strict send: `sendMax` = exact send amount, `destAmount` = minimum receive amount.

## DEX / Offer Operations

### Price

All offer operations use the `Price` class to represent exchange rates as fractions.

```swift
// Direct fraction
let price = Price(numerator: 1, denominator: 4)  // 0.25

// From string
let price2 = Price.fromString(price: "2.5")       // numerator=5, denominator=2
```

### ManageSellOfferOperation

Creates, updates, or deletes a sell offer on the DEX.

```swift
let sellOp = ManageSellOfferOperation(
    sourceAccountId: nil,
    selling: xlm,
    buying: usd,
    amount: 100.0,                            // Decimal - amount of selling asset
    price: Price(numerator: 1, denominator: 4), // Price of 1 selling in terms of buying
    offerId: 0                                 // Int64 - 0 for new, existing ID to update/delete
)

// WRONG: ManageSellOfferOperationResponse.offerId returns "0" for new offers
// CORRECT: query account offers to get the actual offer ID after submitting
// let offersEnum = await sdk.offers.getOffers(forAccount: traderKeyPair.accountId)
// if case .success(let page) = offersEnum, let offer = page.records.first {
//     let offerId = offer.id  // String — the live offer ID
// }

// Note: ManageOfferOperationResponse.offerId is String (not Int64)
// The constructor takes Int64, but the response returns String
```

**Delete offer:** Set `amount` to `0` and `offerId` to the existing offer ID.

**Parameters:** `sourceAccountId: String?`, `selling: Asset`, `buying: Asset`, `amount: Decimal`, `price: Price`, `offerId: Int64`

### ManageBuyOfferOperation

Creates, updates, or deletes a buy offer on the DEX.

```swift
let buyOp = ManageBuyOfferOperation(
    sourceAccountId: nil,
    selling: usd,
    buying: xlm,
    amount: 500.0,                             // Decimal - amount of buying asset to buy
    price: Price(numerator: 4, denominator: 1), // Price of 1 buying in terms of selling
    offerId: 0
)
```

**Parameters:** Same as `ManageSellOfferOperation`. `amount` is the buying asset amount.

### CreatePassiveSellOfferOperation

Creates a passive offer that does not take existing offers at the same price. Subclass of `CreatePassiveOfferOperation`.

```swift
let passiveOp = CreatePassiveSellOfferOperation(
    sourceAccountId: nil,
    selling: xlm,
    buying: usd,
    amount: 200.0,
    price: Price(numerator: 1, denominator: 4)
)
```

**Parameters:** `sourceAccountId: String?`, `selling: Asset`, `buying: Asset`, `amount: Decimal`, `price: Price`

Note: No `offerId` parameter -- passive offers cannot be updated directly. The actual class name in source is `CreatePassiveSellOfferOperation` which extends `CreatePassiveOfferOperation`.

## Trust & Asset Control Operations

### ChangeTrustOperation

Creates, updates, or removes a trustline for an asset.

```swift
// Standard asset trustline
let usdAsset = Asset(
    type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
    code: "USD",
    issuer: try KeyPair(accountId: "GISSUER...")
)!
let changeTrustAsset = ChangeTrustAsset(
    type: usdAsset.type,
    code: usdAsset.code,
    issuer: usdAsset.issuer
)!
let trustOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: changeTrustAsset,
    limit: 1000.0     // Decimal? - nil for max, 0 to remove trustline
)

// Liquidity pool trustline
let poolAsset = try ChangeTrustAsset(assetA: xlm, assetB: usdAsset)!
let poolTrustOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: poolAsset,
    limit: nil  // nil defaults to max Int64
)
```

**Parameters:** `sourceAccountId: String?`, `asset: ChangeTrustAsset`, `limit: Decimal?`

`ChangeTrustAsset` extends `Asset` and adds support for liquidity pool share assets via `init?(assetA: Asset, assetB: Asset)`.

### SetTrustlineFlagsOperation

Allows asset issuers to modify trustline authorization flags.

```swift
let setFlagsOp = SetTrustlineFlagsOperation(
    sourceAccountId: nil,
    asset: usdAsset,
    trustorAccountId: "GTRUSTOR...",
    setFlags: 1,     // UInt32 - TrustLineFlags to set (e.g., AUTHORIZED_FLAG = 1)
    clearFlags: 0    // UInt32 - TrustLineFlags to clear
)
```

**Parameters:** `sourceAccountId: String?`, `asset: Asset`, `trustorAccountId: String`, `setFlags: UInt32`, `clearFlags: UInt32`

### SetOptionsOperation

Configures account settings: thresholds, signers, flags, home domain.

```swift
let setOptionsOp = try SetOptionsOperation(
    sourceAccountId: nil,
    inflationDestination: nil,       // KeyPair?
    clearFlags: nil,                 // UInt32?
    setFlags: nil,                   // UInt32?
    masterKeyWeight: 1,              // UInt32?
    lowThreshold: 1,                 // UInt32?
    mediumThreshold: 2,              // UInt32?
    highThreshold: 3,                // UInt32?
    homeDomain: "example.com",       // String?
    signer: nil,                     // SignerKeyXDR?
    signerWeight: nil                // UInt32?
)

// Add a signer
let signerKey = Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: "GSIGNER..."))
let addSignerOp = try SetOptionsOperation(
    sourceAccountId: nil,
    signer: signerKey,
    signerWeight: 1   // 0 removes the signer
)
```

**Signer key factories:** `Signer.ed25519PublicKey(keyPair:)`, `Signer.ed25519PublicKey(accountId:)`, `Signer.sha256Hash(hash:)`, `Signer.preAuthTx(transaction:network:)`, `Signer.signedPayload(accountId:payload:)`

**Throws** if `signer` is not nil but `signerWeight` is nil.

## Data Operations

### ManageDataOperation

Sets, modifies, or deletes a key/value data entry on an account.

```swift
// Set data
let setDataOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "my_key",             // String - up to 64 bytes
    data: "my_value".data(using: .utf8)  // Data? - up to 64 bytes, nil to delete
)

// Delete data
let deleteDataOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "my_key",
    data: nil
)
```

**Parameters:** `sourceAccountId: String?`, `name: String`, `data: Data?`

## Claimable Balance Operations

### CreateClaimableBalanceOperation

Creates a claimable balance that specified claimants can claim under defined conditions.

```swift
let claimant1 = Claimant(
    destination: "GCLAIMER1...",
    predicate: Claimant.predicateUnconditional()
)
let claimant2 = Claimant(
    destination: "GCLAIMER2...",
    predicate: Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1735689600)
)

let createCBOp = CreateClaimableBalanceOperation(
    asset: xlm,
    amount: 100.0,
    claimants: [claimant1, claimant2],
    sourceAccountId: nil
)
```

**Claimant predicates:** `predicateUnconditional()`, `predicateBeforeAbsoluteTime(unixEpoch:)`, `predicateBeforeRelativeTime(seconds:)`, `predicateAnd(left:right:)`, `predicateOr(left:right:)`, `predicateNot(predicate:)`

**Parameters:** `asset: Asset`, `amount: Decimal`, `claimants: [Claimant]`, `sourceAccountId: String?`

### ClaimClaimableBalanceOperation

Claims an existing claimable balance.

```swift
let claimOp = ClaimClaimableBalanceOperation(
    balanceId: "00000000abc123...",  // hex-encoded claimable balance ID
    sourceAccountId: nil
)
```

**Parameters:** `balanceId: String`, `sourceAccountId: String?`

## Sponsorship Operations

### BeginSponsoringFutureReservesOperation

Establishes a sponsorship relationship where the source account sponsors reserves for another account.

```swift
let beginSponsorOp = BeginSponsoringFutureReservesOperation(
    sponsoredAccountId: "GSPONSORED...",
    sponsoringAccountId: nil  // source account = sponsor
)
```

**Parameters:** `sponsoredAccountId: String`, `sponsoringAccountId: String?` (maps to sourceAccountId)

### EndSponsoringFutureReservesOperation

Terminates the current sponsorship relationship. Source account is the sponsored account.

```swift
let endSponsorOp = EndSponsoringFutureReservesOperation(
    sponsoredAccountId: nil  // maps to sourceAccountId
)
```

**Parameters:** `sponsoredAccountId: String?` (maps to sourceAccountId)

### RevokeSponsorshipOperation

Revokes sponsorship of a ledger entry or signer. Provides static factory methods for creating ledger keys.

```swift
// Revoke account sponsorship
let ledgerKey = try RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(
    accountId: "GACCOUNT..."
)
let revokeOp = RevokeSponsorshipOperation(
    ledgerKey: ledgerKey,
    sourceAccountId: nil
)

// Revoke trustline sponsorship
let tlKey = try RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(
    accountId: "GACCOUNT...",
    asset: usdAsset
)
let revokeTrustOp = RevokeSponsorshipOperation(ledgerKey: tlKey)

// Revoke signer sponsorship
let signerKey = Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: "GSIGNER..."))
let revokeSignerOp = RevokeSponsorshipOperation(
    signerAccountId: "GACCOUNT...",
    signerKey: signerKey,
    sourceAccountId: nil
)
```

**Ledger key factories:** `revokeAccountSponsorshipLedgerKey(accountId:)`, `revokeDataSponsorshipLedgerKey(accountId:dataName:)`, `revokeTrustlineSponsorshipLedgerKey(accountId:asset:)`, `revokeClaimableBalanceSponsorshipLedgerKey(balanceId:)`, `revokeOfferSponsorshipLedgerKey(sellerAccountId:offerId:)`

## Clawback Operations

### ClawbackOperation

Allows asset issuer to claw back (burn) assets from an account. Requires the clawback flag on the asset.

```swift
let clawbackOp = ClawbackOperation(
    sourceAccountId: nil,       // must be the asset issuer
    asset: usdAsset,
    fromAccountId: "GACCOUNT...",
    amount: 50.0
)
```

**Parameters:** `sourceAccountId: String?`, `asset: Asset`, `fromAccountId: String`, `amount: Decimal`

### ClawbackClaimableBalanceOperation

Allows asset issuer to claw back an unclaimed claimable balance.

```swift
let clawbackCBOp = ClawbackClaimableBalanceOperation(
    claimableBalanceID: "00000000abc123...",
    sourceAccountId: nil
)
```

**Parameters:** `claimableBalanceID: String`, `sourceAccountId: String?`

## Liquidity Pool Operations

### LiquidityPoolDepositOperation

Deposits assets into an AMM liquidity pool.

```swift
let depositOp = LiquidityPoolDepositOperation(
    sourceAccountId: nil,
    liquidityPoolId: "abcdef0123456789...",  // hex pool ID
    maxAmountA: 1000.0,                       // Decimal
    maxAmountB: 2000.0,                       // Decimal
    minPrice: Price(numerator: 1, denominator: 2),  // min A/B price
    maxPrice: Price(numerator: 2, denominator: 1)   // max A/B price
)
```

**Parameters:** `sourceAccountId: String?`, `liquidityPoolId: String`, `maxAmountA: Decimal`, `maxAmountB: Decimal`, `minPrice: Price`, `maxPrice: Price`

### LiquidityPoolWithdrawOperation

Withdraws assets from an AMM liquidity pool.

```swift
let withdrawOp = LiquidityPoolWithdrawOperation(
    sourceAccountId: nil,
    liquidityPoolId: "abcdef0123456789...",
    amount: 500.0,         // Decimal - pool shares to withdraw
    minAmountA: 400.0,     // Decimal - minimum first asset received
    minAmountB: 800.0      // Decimal - minimum second asset received
)
```

**Parameters:** `sourceAccountId: String?`, `liquidityPoolId: String`, `amount: Decimal`, `minAmountA: Decimal`, `minAmountB: Decimal`

## Soroban Operations

### InvokeHostFunctionOperation

Invokes Soroban smart contract functions. Use factory methods rather than the raw constructor.

```swift
// Invoke a contract function
let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
    contractId: "CABC...",
    functionName: "transfer",
    functionArguments: [
        SCValXDR.address(try SCAddressXDR(accountId: "GSOURCE...")),
        SCValXDR.address(try SCAddressXDR(accountId: "GDEST...")),
        SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
    ],
    sourceAccountId: nil
)

// Upload WASM bytecode
let uploadOp = try InvokeHostFunctionOperation.forUploadingContractWasm(
    contractCode: wasmBytes,  // Data
    sourceAccountId: nil
)

// Create contract from WASM hash
let createContractOp = try InvokeHostFunctionOperation.forCreatingContract(
    wasmId: "abc123...",  // hex WASM hash
    address: try SCAddressXDR(accountId: "GSOURCE..."),
    sourceAccountId: nil
)

// Create contract with constructor args (protocol 22+)
let createV2Op = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
    wasmId: "abc123...",
    address: try SCAddressXDR(accountId: "GSOURCE..."),
    constructorArguments: [SCValXDR.symbol("init_val")],
    sourceAccountId: nil
)

// Deploy Stellar Asset Contract
let sacOp = try InvokeHostFunctionOperation.forDeploySACWithAsset(
    asset: usdAsset,
    sourceAccountId: nil
)
```

### ExtendFootprintTTLOperation

Extends the TTL of Soroban contract state entries.

```swift
let extendOp = ExtendFootprintTTLOperation(
    ledgersToExpire: 535_680,  // UInt32 - ~31 days at 5s/ledger
    sourceAccountId: nil
)
```

**Parameters:** `ledgersToExpire: UInt32`, `sourceAccountId: String?`

### RestoreFootprintOperation

Restores archived Soroban contract state entries to active state.

```swift
let restoreOp = RestoreFootprintOperation(sourceAccountId: nil)
```

**Parameters:** `sourceAccountId: String?`

## Building a Transaction with Operations

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let sourceKeyPair = try KeyPair(secretSeed: "SCZANGBA...")

// Load account for sequence number
let accountResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
guard case .success(let accountDetails) = accountResponse else { return }

// Build transaction with operations
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)

let transaction = try Transaction(
    sourceAccount: accountDetails,
    operations: [paymentOp],
    memo: Memo.text("payment"),
    maxOperationFee: 100  // UInt32 - stroops per operation
)

// Sign and submit
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)
let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResult {
case .success(let response):
    print("Transaction hash: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Account \(accountId) requires memo")
case .failure(let error):
    print("Failed: \(error)")
}
```

**Multiple operations with per-operation source accounts:**

```swift
let op1 = try CreateAccountOperation(
    sourceAccountId: nil,  // uses transaction source
    destinationAccountId: accountAKeyPair.accountId,
    startBalance: 100.0
)
let op2 = try PaymentOperation(
    sourceAccountId: otherKeyPair.accountId,  // overrides transaction source for this op
    destinationAccountId: accountAKeyPair.accountId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 25.0
)

let transaction = try Transaction(
    sourceAccount: accountDetails,
    operations: [op1, op2],
    memo: Memo.none
)

// All source accounts involved must sign
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)
try transaction.sign(keyPair: otherKeyPair, network: Network.testnet)
```
