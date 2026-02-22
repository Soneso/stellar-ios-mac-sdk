# Horizon Streaming (SSE)

The SDK provides real-time Server-Sent Events streaming for all major Horizon resources. Streams use closure-based callbacks and must be retained with a strong reference.

## Architecture

Every stream method returns a typed stream item object. Call `onReceive` to start receiving events, and `closeStream()` to stop.

| Service | Method | Stream Item Type | Response Type |
|---------|--------|-----------------|---------------|
| `sdk.payments` | `stream(for: PaymentsChange)` | `OperationsStreamItem` | `OperationResponse` |
| `sdk.transactions` | `stream(for: TransactionsChange)` | `TransactionsStreamItem` | `TransactionResponse` |
| `sdk.ledgers` | `stream(for: LedgersChange)` | `LedgersStreamItem` | `LedgerResponse` |
| `sdk.effects` | `stream(for: EffectsChange)` | `EffectsStreamItem` | `EffectResponse` |
| `sdk.operations` | `stream(for: OperationsChange)` | `OperationsStreamItem` | `OperationResponse` |
| `sdk.offers` | `stream(for: OffersChange)` | `OffersStreamItem` | `OfferResponse` |
| `sdk.trades` | `stream(for: TradesChange)` | `TradesStreamItem` | `TradeResponse` |
| `sdk.orderbooks` | `stream(for: OrderbookChange)` | `OrderbookStreamItem` | `OrderbookResponse` |
| `sdk.accounts` | `streamAccount(accountId:)` | `AccountStreamItem` | `AccountResponse` |

## StreamResponseEnum

All stream callbacks deliver `StreamResponseEnum<T>`:

```swift
public enum StreamResponseEnum<Data: Decodable> {
    case open
    case response(id: String, data: Data)
    case error(error: Error?)
}
```

## Stream Payments for an Account

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let accountId = "GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

// CRITICAL: Hold a strong reference to prevent deallocation
var paymentStream: OperationsStreamItem? = sdk.payments.stream(
    for: .paymentsForAccount(account: accountId, cursor: "now")
)

paymentStream?.onReceive { response in
    switch response {
    case .open:
        break
    case .response(let id, let operationResponse):
        if let payment = operationResponse as? PaymentOperationResponse {
            print("Payment received: \(payment.amount) \(payment.assetCode ?? "XLM")")
            print("From: \(payment.from)")
            print("Cursor: \(id)")
        }
    case .error(let error):
        if let horizonError = error as? HorizonRequestError {
            print("Stream error: \(horizonError)")
        }
    }
}

// Close when done
paymentStream?.closeStream()
paymentStream = nil
```

## Stream Transactions

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let accountId = "GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

var txStream: TransactionsStreamItem? = sdk.transactions.stream(
    for: .transactionsForAccount(account: accountId, cursor: "now")
)

txStream?.onReceive { response in
    switch response {
    case .open:
        break
    case .response(let id, let txResponse):
        print("Transaction: \(txResponse.transactionHash)")
        print("Ledger: \(txResponse.ledger)")
        print("Operations: \(txResponse.operationCount)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

## Stream Ledger Closes

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")

var ledgerStream: LedgersStreamItem? = sdk.ledgers.stream(
    for: .allLedgers(cursor: "now")
)

ledgerStream?.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let ledger):
        print("Ledger \(ledger.sequenceNumber) closed")
        print("Transactions: \(ledger.successfulTransactionCount)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

## Stream Effects

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let accountId = "GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

var effectStream: EffectsStreamItem? = sdk.effects.stream(
    for: .effectsForAccount(account: accountId, cursor: "now")
)

effectStream?.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let effect):
        print("Effect type: \(effect.effectTypeString)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

## Change Enum Filter Options

Each service has a Change enum controlling what to stream:

**PaymentsChange:**
- `.allPayments(cursor:)` -- all network payments
- `.paymentsForAccount(account:, cursor:)` -- payments for an account
- `.paymentsForLedger(ledger:, cursor:)` -- payments in a ledger
- `.paymentsForTransaction(transaction:, cursor:)` -- payments in a transaction

**TransactionsChange:**
- `.allTransactions(cursor:)` -- all network transactions
- `.transactionsForAccount(account:, cursor:)` -- transactions for an account
- `.transactionsForClaimableBalance(claimableBalanceId:, cursor:)` -- transactions for a claimable balance
- `.transactionsForLedger(ledger:, cursor:)` -- transactions in a ledger

**OperationsChange:**
- `.allOperations(cursor:)` -- all operations
- `.operationsForAccount(account:, cursor:)` -- operations for an account
- `.operationsForLedger(ledger:, cursor:)` -- operations in a ledger
- `.operationsForTransaction(transaction:, cursor:)` -- operations in a transaction
- `.operationsForClaimableBalance(claimableBalanceId:, cursor:)` -- operations for a claimable balance
- `.operationsForLiquidityPool(liquidityPoolId:, cursor:)` -- operations for a liquidity pool

**EffectsChange:**
- `.allEffects(cursor:)` -- all effects
- `.effectsForAccount(account:, cursor:)` -- effects for an account
- `.effectsForLedger(ledger:, cursor:)` -- effects in a ledger
- `.effectsForOperation(operation:, cursor:)` -- effects for an operation
- `.effectsForTransaction(transaction:, cursor:)` -- effects in a transaction
- `.effectsForLiquidityPool(liquidityPool:, cursor:)` -- effects for a liquidity pool

**LedgersChange:**
- `.allLedgers(cursor:)` -- all ledger closes

## Lifecycle and Reconnection

- The underlying `EventSource` (SSE client) automatically reconnects on transient network failures.
- Pass `cursor: "now"` to receive only new events, or a specific cursor string to resume from a known position.
- You **must** hold a strong reference to the stream item. If it is deallocated, the stream closes.
- Call `closeStream()` to terminate the connection. The stream item cannot be reused after closing -- create a new one instead.
- Stream callbacks arrive on background threads. Dispatch to `MainActor` for UI updates.

## Error Handling

Stream errors are delivered as `HorizonRequestError`:

- `.errorOnStreamReceive(message:)` -- network or parsing error during streaming
- `.notFound(message:, horizonErrorResponse:)` -- returned as error when HTTP 404 on stream open
- `.parsingResponseFailed(message:)` -- JSON decoding failure for a stream message

## Swift 6 Concurrency Patterns

Stream items are `@unchecked Sendable` and safe to store in any context.

**Shared mutable state with callbacks:**
```swift
// Use nonisolated(unsafe) for flags accessed in stream callbacks
nonisolated(unsafe) var streamOpened = false
nonisolated(unsafe) var paymentReceived = false

let stream = sdk.payments.stream(for: .paymentsForAccount(account: accountId, cursor: "now"))
stream?.onReceive { response in
    switch response {
    case .open:
        streamOpened = true
    case .response(_, let operation):
        if let payment = operation as? PaymentOperationResponse {
            paymentReceived = true
            print("Payment: \(payment.amount) from \(payment.from)")
        }
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

**Waiting for stream events in async code:**
```swift
// WRONG: DispatchSemaphore.wait() or DispatchGroup.wait() — blocks the thread and deadlocks
// CORRECT: async polling with Task.sleep
for _ in 0..<30 {
    if paymentReceived { break }
    try? await Task.sleep(nanoseconds: 1_000_000_000)
}

stream?.closeStream()
stream = nil
```
