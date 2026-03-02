# Horizon API Reference

Complete Horizon API coverage via `StellarSDK` service objects. All methods are `async` and return result enums for pattern matching. The SDK provides 100% Horizon endpoint coverage (50/50 endpoints).

## SDK Initialization

```swift
import stellarsdk

// Testnet (default)
let sdk = StellarSDK()

// Named network factories
let mainnet = StellarSDK.publicNet()
let testnet = StellarSDK.testNet()
let futurenet = StellarSDK.futureNet()

// Custom Horizon URL
let custom = StellarSDK(withHorizonUrl: "https://my-horizon.example.com")
```

## Service Objects

Access Horizon endpoints through typed service properties on `StellarSDK`:

| Property | Service Class | Description |
|----------|--------------|-------------|
| `sdk.accounts` | `AccountService` | Account details, data, filtering |
| `sdk.transactions` | `TransactionsService` | Query and submit transactions |
| `sdk.operations` | `OperationsService` | Operation history |
| `sdk.payments` | `PaymentsService` | Payment operation history |
| `sdk.ledgers` | `LedgersService` | Ledger history |
| `sdk.effects` | `EffectsService` | Effect history |
| `sdk.offers` | `OffersService` | DEX offer queries |
| `sdk.orderbooks` | `OrderbookService` | Order book snapshots |
| `sdk.trades` | `TradesService` | Trade history |
| `sdk.tradeAggregations` | `TradeAggregationsService` | OHLCV candle data |
| `sdk.assets` | `AssetsService` | Asset queries |
| `sdk.claimableBalances` | `ClaimableBalancesService` | Claimable balance queries |
| `sdk.liquidityPools` | `LiquidityPoolsService` | AMM pool queries |
| `sdk.paymentPaths` | `PaymentPathsService` | Path finding |
| `sdk.feeStats` | `FeeStatsService` | Network fee statistics |
| `sdk.health` | `HealthService` | Horizon server health |

## Common Query Pattern

All Horizon queries return result enums following this pattern:

```swift
let response = await sdk.accounts.getAccountDetails(accountId: "GABC...")
switch response {
case .success(let accountDetails):
    print("Balances: \(accountDetails.balances)")
case .failure(let error):
    // error is HorizonRequestError
    print("Error: \(error)")
}
```

For method signatures on response objects, see [API Reference](./api_reference.md).

## Accounts

```swift
// Get account details
let response = await sdk.accounts.getAccountDetails(accountId: "GABC...")

// Get account data field
let dataResponse = await sdk.accounts.getDataForAccount(
    accountId: "GABC...",
    key: "my_data_key"
)

// Query accounts with filters
let filtered = await sdk.accounts.getAccounts(
    signer: nil,
    asset: "USD:GISSUER...",   // canonical asset format
    sponsor: nil,
    liquidityPoolId: nil,
    cursor: nil,
    order: .descending,
    limit: 10
)

// Create testnet account (Friendbot)
let fundResult = await sdk.accounts.createTestAccount(accountId: "GNEW...")
```

## Transactions

### Querying

```swift
// All transactions
let txResponse = await sdk.transactions.getTransactions(
    cursor: nil,
    order: .descending,
    limit: 20
)

// Transactions for an account
let accountTxs = await sdk.transactions.getTransactions(
    forAccount: "GABC...",
    from: nil,      // cursor
    order: nil,
    limit: 10
)

// Transactions for a ledger
let ledgerTxs = await sdk.transactions.getTransactions(
    forLedger: "12345",
    from: nil,
    order: nil,
    limit: nil
)

// Transactions for a claimable balance
let cbTxs = await sdk.transactions.getTransactions(
    forClaimableBalance: "00000000abc...",
    from: nil,
    order: nil,
    limit: nil
)

// Transactions for a liquidity pool
let poolTxs = await sdk.transactions.getTransactions(
    forLiquidityPool: "abcdef012345...",
    from: nil,
    order: nil,
    limit: nil
)

// Single transaction by hash
let txDetail = await sdk.transactions.getTransactionDetails(
    transactionHash: "abc123..."
)
```

### Inspecting Transaction Memos

Transaction responses include a `memoType` string and a `memo` enum. Extract memo values by switching on the enum:

```swift
// Fetch a transaction
let txResponse = await sdk.transactions.getTransactionDetails(transactionHash: "hash...")
guard case .success(let tx) = txResponse else { return }

// WRONG: tx.memo as String? (it's a Memo? enum, not a String)
// CORRECT: Switch on the Memo enum to extract associated values
if let memo = tx.memo {
    switch memo {
    case .none:
        print("No memo")
    case .text(let text):
        print("Memo (text): \(text)")
    case .id(let id):
        print("Memo (id): \(id)")
    case .hash(let data):
        print("Memo (hash): \(data.base64EncodedString())")
    case .returnHash(let data):
        print("Memo (return): \(data.base64EncodedString())")
    }
} else {
    print("No memo")
}

// Alternative: check memoType string first
switch tx.memoType {
case "none":
    print("No memo")
case "text", "id", "hash", "return":
    if let memo = tx.memo {
        // switch on memo as shown above
    }
default:
    print("Unknown memo type: \(tx.memoType)")
}
```

**Property reference:**
- `tx.memoType` (String) — "none", "text", "id", "hash", or "return"
- `tx.memo` (Memo?) — Memo enum with associated values (.text(String), .id(UInt64), .hash(Data), .returnHash(Data))

### Submitting Transactions

```swift
// Synchronous submission (waits for ledger inclusion)
let result = await sdk.transactions.submitTransaction(
    transaction: signedTransaction,
    skipMemoRequiredCheck: false
)
switch result {
case .success(let response):
    print("Hash: \(response.transactionHash)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires a memo (SEP-29)")
case .failure(let error):
    print("Failed: \(error)")
}

// Fee bump transaction submission
let feeBumpResult = await sdk.transactions.submitFeeBumpTransaction(
    transaction: feeBumpTx
)

// Async submission (returns immediately after validation)
let asyncResult = await sdk.transactions.submitAsyncTransaction(
    transaction: signedTransaction,
    skipMemoRequiredCheck: false
)

// Submit raw XDR envelope
let xdrResult = await sdk.transactions.postTransaction(
    transactionEnvelope: "AAAAAgAAAA...",
    skipMemoRequiredCheck: false
)
```

## Operations

```swift
// All operations
let opsResponse = await sdk.operations.getOperations(
    cursor: nil,
    order: nil,
    limit: 20,
    includeFailed: true,   // Bool? - include failed operations
    join: "transactions"   // String? - join related resources
)

// Operations for an account
let accountOps = await sdk.operations.getOperations(
    forAccount: "GABC...",
    from: nil,
    order: nil,
    limit: nil,
    includeFailed: nil,
    join: nil
)

// Operations for a transaction
let txOps = await sdk.operations.getOperations(
    forTransaction: "txhash...",
    from: nil,
    order: nil,
    limit: nil,
    includeFailed: nil,
    join: nil
)

// Single operation by ID
let opDetail = await sdk.operations.getOperationDetails(operationId: "12345")

// Type-check operation responses — each is a typed subclass of OperationResponse
for op in page.records {
    print("\(op.id): \(op.operationTypeString)")  // e.g. "create_account", "payment"
    if let payment = op as? PaymentOperationResponse {
        print("  \(payment.from) -> \(payment.to): \(payment.amount)")
    } else if let created = op as? AccountCreatedOperationResponse {
        print("  Created: \(created.account) with \(created.startingBalance) XLM")
    } else if let merge = op as? AccountMergeOperationResponse {
        print("  Merged into: \(merge.into)")
    }
}
```

## Payments

```swift
// All payments
let payments = await sdk.payments.getPayments(
    cursor: nil,
    order: nil,
    limit: 20
)

// Payments for an account
let accountPayments = await sdk.payments.getPayments(
    forAccount: "GABC...",
    from: nil,
    order: .descending,
    limit: 10
)

// Payments for a ledger
let ledgerPayments = await sdk.payments.getPayments(
    forLedger: "12345",
    from: nil,
    order: nil,
    limit: nil
)

// Payments for a transaction
let txPayments = await sdk.payments.getPayments(
    forTransaction: "txhash...",
    from: nil,
    order: nil,
    limit: nil
)
```

## Ledgers

```swift
// List ledgers
let ledgers = await sdk.ledgers.getLedgers(
    cursor: nil,
    order: .descending,
    limit: 10
)

// Single ledger by sequence number
let ledger = await sdk.ledgers.getLedger(sequenceNumber: "12345")

// WRONG: ledger.sequence — JSON key is "sequence" but Swift property is sequenceNumber
// CORRECT: ledger.sequenceNumber (Int64)
// Other key properties: closedAt (Date), successfulTransactionCount (Int),
//   failedTransactionCount (Int), operationCount (Int), baseFeeInStroops (Int)
```

## Effects

```swift
// All effects
let effects = await sdk.effects.getEffects(cursor: nil, order: nil, limit: 20)

// Effects for account, ledger, operation, transaction, or liquidity pool
let accountEffects = await sdk.effects.getEffects(
    forAccount: "GABC...",
    from: nil,
    order: nil,
    limit: nil
)
let opEffects = await sdk.effects.getEffects(
    forOperation: "12345",
    from: nil,
    order: nil,
    limit: nil
)
```

## Offers & Orderbook

```swift
// Offers for an account
let offers = await sdk.offers.getOffers(
    forAccount: "GABC...",
    cursor: nil,
    order: nil,
    limit: nil
)

// Single offer details
let offer = await sdk.offers.getOfferDetails(offerId: "12345")

// Trades for a specific offer
let offerTrades = await sdk.offers.getTrades(
    forOffer: "12345",
    cursor: nil,
    order: nil,
    limit: nil
)

// Order book snapshot
let orderbook = await sdk.orderbooks.getOrderbook(
    sellingAssetType: "credit_alphanum4",
    sellingAssetCode: "USD",
    sellingAssetIssuer: "GISSUER...",
    buyingAssetType: "native",
    buyingAssetCode: nil,
    buyingAssetIssuer: nil,
    limit: 20
)
switch orderbook {
case .success(let ob):
    for bid in ob.bids { print("Bid: \(bid.price) x \(bid.amount)") }
    for ask in ob.asks { print("Ask: \(ask.price) x \(ask.amount)") }
case .failure(let error):
    print("Error: \(error)")
}
```

**Order book perspective:**
Query parameters define the market from the **offer creator's perspective**:
- `sellingAssetType/Code/Issuer` = what offers are **SELLING**
- `buyingAssetType/Code/Issuer` = what offers want to **BUY**

Example: To see offers selling USD for XLM, specify `selling = USD`, `buying = XLM`.

```swift
// WRONG: Swapped parameters - shows opposite side of market
let wrongBook = await sdk.orderbooks.getOrderbook(
    sellingAssetType: "native",          // Offers selling XLM (not what you want)
    sellingAssetCode: nil,
    sellingAssetIssuer: nil,
    buyingAssetType: "credit_alphanum4", // Offers buying USD
    buyingAssetCode: "USD",
    buyingAssetIssuer: "GISSUER...",
    limit: 20
)

// CORRECT: Shows offers selling USD for XLM
let correctBook = await sdk.orderbooks.getOrderbook(
    sellingAssetType: "credit_alphanum4", // Offers selling USD
    sellingAssetCode: "USD",
    sellingAssetIssuer: "GISSUER...",
    buyingAssetType: "native",           // Offers buying XLM
    buyingAssetCode: nil,
    buyingAssetIssuer: nil,
    limit: 20
)
```

## Trades & Aggregations

```swift
// Query trades
let trades = await sdk.trades.getTrades(
    baseAssetType: "native",
    baseAssetCode: nil,
    baseAssetIssuer: nil,
    counterAssetType: "credit_alphanum4",
    counterAssetCode: "USD",
    counterAssetIssuer: "GISSUER...",
    offerId: nil,
    cursor: nil,
    order: nil,
    limit: nil
)

// Trade aggregations (OHLCV candles)
let aggregations = await sdk.tradeAggregations.getTradeAggregations(
    baseAssetType: "native",
    baseAssetCode: nil,
    baseAssetIssuer: nil,
    counterAssetType: "credit_alphanum4",
    counterAssetCode: "USD",
    counterAssetIssuer: "GISSUER...",
    resolution: 3600000,   // Int64 - milliseconds (1 hour)
    startTime: nil,
    endTime: nil,
    offset: nil,
    order: nil,
    limit: nil
)
```

## Assets

```swift
let assets = await sdk.assets.getAssets(
    assetCode: "USD",
    assetIssuer: nil,
    cursor: nil,
    order: nil,
    limit: nil
)
```

## Claimable Balances

```swift
// Query by claimant account (separate methods per filter - pick ONE)
let balances = await sdk.claimableBalances.getClaimableBalances(
    claimantAccountId: "GCLAIMER...",
    cursor: nil, order: nil, limit: nil
)

// Query by asset
let byAsset = await sdk.claimableBalances.getClaimableBalances(
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    cursor: nil, order: nil, limit: nil
)

// Query by sponsor
let byFunder = await sdk.claimableBalances.getClaimableBalances(
    sponsorAccountId: "GSPONSOR...",
    cursor: nil, order: nil, limit: nil
)

// Single claimable balance
let balance = await sdk.claimableBalances.getClaimableBalance(
    balanceId: "00000000abc..."
)

// WRONG: balance.balanceID — uppercase D does NOT exist
// CORRECT: balance.balanceId — camelCase from JSON key "id"
// Other properties: balance.amount (String), balance.asset (Asset),
//   balance.sponsor (String?), balance.claimants ([ClaimantResponse])
```

## Liquidity Pools

```swift
// List pools with filters
let pools = await sdk.liquidityPools.getLiquidityPools(
    reserves: "native",       // filter by reserve asset
    account: nil,
    cursor: nil,
    order: nil,
    limit: nil
)

// Single pool
let pool = await sdk.liquidityPools.getLiquidityPool(poolId: "abcdef...")
```

## Path Finding

```swift
// Strict receive - find paths to deliver exact destination amount
let paths = await sdk.paymentPaths.strictReceive(
    sourceAccount: "GSOURCE...",
    sourceAssets: nil,
    destinationAccount: "GDEST...",
    destinationAssetType: "native",
    destinationAssetCode: nil,
    destinationAssetIssuer: nil,
    destinationAmount: "100.0"
)

// Strict send - find paths for exact source amount
let sendPaths = await sdk.paymentPaths.strictSend(
    sourceAmount: "50.0",
    sourceAssetType: "credit_alphanum4",
    sourceAssetCode: "USD",
    sourceAssetIssuer: "GISSUER...",
    destinationAccount: "GDEST...",
    destinationAssets: nil
)
```

## Fee Statistics

```swift
let feeResponse = await sdk.feeStats.getFeeStats()
switch feeResponse {
case .success(let stats):
    // All fee stats values are String type (not Int)
    print("Last ledger base fee: \(stats.lastLedgerBaseFee)")
    print("Fee charged p50: \(stats.feeCharged.p50)")
    print("Fee charged p90: \(stats.feeCharged.p90)")
    print("Fee charged p99: \(stats.feeCharged.p99)")
case .failure(let error):
    print("Error: \(error)")
}
```

## Pagination

All list queries return `PageResponse<T>` which contains records and navigation links.

```swift
// First page
let firstPage = await sdk.transactions.getTransactions(
    cursor: nil,
    order: .descending,
    limit: 10
)

switch firstPage {
case .success(let page):
    // Access records
    for tx in page.records {
        print("Hash: \(tx.transactionHash)")
    }

    // Get next page using the cursor from the last record
    if let lastRecord = page.records.last {
        let nextPage = await sdk.transactions.getTransactions(
            cursor: lastRecord.pagingToken,
            order: .descending,
            limit: 10
        )
        // Process next page...
    }
case .failure(let error):
    print("Error: \(error)")
}
```

**Key pagination parameters:**
- `cursor: String?` -- Paging token from a previous record's `pagingToken` property
- `order: Order?` -- `.ascending` (oldest first) or `.descending` (newest first)
- `limit: Int?` -- Max records per page (default 10, max 200)

## Error Handling

All Horizon service methods return errors as `HorizonRequestError`:

```swift
let response = await sdk.accounts.getAccountDetails(accountId: "GINVALID...")
switch response {
case .success(let details):
    print(details.accountId)
case .failure(let error):
    switch error {
    case .notFound(let message, let errorResponse):
        print("Account not found: \(message)")
    case .badRequest(let message, let errorResponse):
        print("Bad request: \(message)")
        if let extras = errorResponse?.extras {
            print("Result codes: \(extras)")
        }
    case .rateLimitExceeded(let message, _):
        print("Rate limited: \(message)")
    case .requestFailed(let message, _):
        print("Network error: \(message)")
    case .parsingResponseFailed(let message):
        print("Parse error: \(message)")
    default:
        print("Other error: \(error)")
    }
}
```

**Error variants:** `requestFailed`, `badRequest`, `unauthorized`, `forbidden`, `notFound`, `notAcceptable`, `duplicate`, `beforeHistory`, `payloadTooLarge`, `rateLimitExceeded`, `internalServerError`, `notImplemented`, `staleHistory`, `timeout`, `emptyResponse`, `parsingResponseFailed`, `errorOnStreamReceive`
