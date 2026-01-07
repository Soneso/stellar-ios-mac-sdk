# Horizon API vs iOS/macOS SDK Compatibility Matrix

**Horizon Version:** v25.0.0 (released 2025-12-11)  
**Horizon Source:** [v25.0.0](https://github.com/stellar/stellar-horizon/releases/tag/v25.0.0)  
**SDK Version:** 3.4.1  
**Generated:** 2026-01-07 14:54:50

**Horizon Endpoints Discovered:** 52  
**Public API Endpoints (in matrix):** 50

> **Note:** 2 endpoints intentionally excluded from the matrix:
> - `GET /paths` - Deprecated - use /paths/strict-receive and /paths/strict-send
> - `POST /friendbot` - Redundant - GET method is used instead

## Overall Coverage

**Coverage:** 100.0% (50/50 public API endpoints)

- **Fully Supported:** 50/50
- **Partially Supported:** 0/50
- **Not Supported:** 0/50
- **Deprecated:** 0/50

## Coverage by Category

| Category | Coverage | Supported | Not Supported | Total |
|----------|----------|-----------|---------------|-------|
| accounts | 100.0% | 9 | 0 | 9 |
| assets | 100.0% | 1 | 0 | 1 |
| claimable balances | 100.0% | 4 | 0 | 4 |
| effects | 100.0% | 1 | 0 | 1 |
| friendbot | 100.0% | 1 | 0 | 1 |
| ledgers | 100.0% | 6 | 0 | 6 |
| liquidity pools | 100.0% | 6 | 0 | 6 |
| network | 100.0% | 1 | 0 | 1 |
| offers | 100.0% | 3 | 0 | 3 |
| operations | 100.0% | 3 | 0 | 3 |
| order book | 100.0% | 1 | 0 | 1 |
| paths | 100.0% | 2 | 0 | 2 |
| payments | 100.0% | 1 | 0 | 1 |
| root | 100.0% | 2 | 0 | 2 |
| trades | 100.0% | 2 | 0 | 2 |
| transactions | 100.0% | 7 | 0 | 7 |

## Streaming Support

**Coverage:** 100.0%

- Streaming endpoints: 31
- Supported: 31

## Detailed Endpoint Comparison

### Accounts

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/accounts` | GET | Full | `AccountService.getAccounts()` |  | - |
| `/accounts/{account_id}` | GET | Full | `AccountService.getAccountDetails()` | Yes | streamAccount(accountId:) |
| `/accounts/{account_id}/data/{key}` | GET | Full | `AccountService.getDataForAccount()` | Yes | streamAccountData(accountId:key:) |
| `/accounts/{account_id}/offers` | GET | Full | `OffersService.getOffers()` | Yes | stream(for: .offersForAccount) |
| `/accounts/{account_id}/effects` | GET | Full | `EffectsService.getEffects()` | Yes | stream(for: .effectsForAccount) |
| `/accounts/{account_id}/operations` | GET | Full | `OperationsService.getOperations()` | Yes | stream(for: .operationsForAccount) |
| `/accounts/{account_id}/payments` | GET | Full | `PaymentsService.getPayments()` | Yes | stream(for: .paymentsForAccount) |
| `/accounts/{account_id}/trades` | GET | Full | `TradesService.getTrades()` | Yes | stream(for: .tradesForAccount) |
| `/accounts/{account_id}/transactions` | GET | Full | `TransactionsService.getTransactions()` | Yes | stream(for: .transactionsForAccount) |

### Assets

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/assets` | GET | Full | `AssetsService.getAssets()` |  | - |

### Claimable Balances

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/claimable_balances` | GET | Full | `ClaimableBalancesService.getClaimableBalances()` |  | - |
| `/claimable_balances/{id}` | GET | Full | `ClaimableBalancesService.getClaimableBalance()` |  | No streaming |
| `/claimable_balances/{claimable_balance_id}/operations` | GET | Full | `OperationsService.getOperations()` | Yes | stream(for: .operationsForClaimableBalance) |
| `/claimable_balances/{claimable_balance_id}/transactions` | GET | Full | `TransactionsService.getTransactions()` | Yes | stream(for: .transactionsForClaimableBalance) |

### Effects

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/effects` | GET | Full | `EffectsService.getEffects()` | Yes | stream(for: .allEffects) |

### Friendbot

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/friendbot` | GET | Full | `AccountService.createTestAccount()` |  | External friendbot URL |

### Ledgers

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/ledgers` | GET | Full | `LedgersService.getLedgers()` | Yes | stream(for: .allLedgers) |
| `/ledgers/{ledger_id}` | GET | Full | `LedgersService.getLedger()` |  | No streaming |
| `/ledgers/{ledger_id}/transactions` | GET | Full | `TransactionsService.getTransactions()` | Yes | stream(for: .transactionsForLedger) |
| `/ledgers/{ledger_id}/effects` | GET | Full | `EffectsService.getEffects()` | Yes | stream(for: .effectsForLedger) |
| `/ledgers/{ledger_id}/operations` | GET | Full | `OperationsService.getOperations()` | Yes | stream(for: .operationsForLedger) |
| `/ledgers/{ledger_id}/payments` | GET | Full | `PaymentsService.getPayments()` | Yes | stream(for: .paymentsForLedger) |

### Liquidity Pools

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/liquidity_pools` | GET | Full | `LiquidityPoolsService.getLiquidityPools()` |  | - |
| `/liquidity_pools/{liquidity_pool_id}` | GET | Full | `LiquidityPoolsService.getLiquidityPool()` |  | No streaming |
| `/liquidity_pools/{liquidity_pool_id}/operations` | GET | Full | `OperationsService.getOperations()` | Yes | stream(for: .operationsForLiquidityPool) |
| `/liquidity_pools/{liquidity_pool_id}/transactions` | GET | Full | `TransactionsService.getTransactions()` | Yes | stream(for: .transactionsForLiquidityPool) |
| `/liquidity_pools/{liquidity_pool_id}/effects` | GET | Full | `EffectsService.getEffects()` | Yes | stream(for: .effectsForLiquidityPool) |
| `/liquidity_pools/{liquidity_pool_id}/trades` | GET | Full | `LiquidityPoolsService.getLiquidityPoolTrades()` | Yes | streamTrades(forPoolId:) |

### Network

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/fee_stats` | GET | Full | `FeeStatsService.getFeeStats()` |  | - |

### Offers

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/offers` | GET | Full | `OffersService.getOffers()` | Yes | stream(for: .allOffers) |
| `/offers/{offer_id}` | GET | Full | `OffersService.getOfferDetails()` |  | No streaming |
| `/offers/{offer_id}/trades` | GET | Full | `OffersService.streamTrades()` | Yes | streamTrades(forOffer:) |

### Operations

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/operations` | GET | Full | `OperationsService.getOperations()` | Yes | stream(for: .allOperations) |
| `/operations/{id}` | GET | Full | `OperationsService.getOperationDetails()` |  | No streaming |
| `/operations/{op_id}/effects` | GET | Full | `EffectsService.getEffects()` | Yes | stream(for: .effectsForOperation) |

### Order Book

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/order_book` | GET | Full | `OrderbookService.getOrderbook()` | Yes | stream(for:) |

### Paths

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/paths/strict-receive` | GET | Full | `PaymentPathsService.strictReceive()` |  | - |
| `/paths/strict-send` | GET | Full | `PaymentPathsService.strictSend()` |  | - |

### Payments

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/payments` | GET | Full | `PaymentsService.getPayments()` | Yes | stream(for: .allPayments) |

### Root

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/health` | GET | Full | `HealthService.getHealth()` |  | - |
| `/` | GET | Full | `StellarSDK (configuration)` |  | Via SDK initialization |

### Trades

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/trades` | GET | Full | `TradesService.getTrades()` | Yes | stream(for: .tradesForAssetPair) |
| `/trade_aggregations` | GET | Full | `TradeAggregationsService.getTradeAggregations()` |  | - |

### Transactions

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/transactions` | GET | Full | `TransactionsService.getTransactions()` | Yes | stream(for: .allTransactions) |
| `/transactions/{tx_id}` | GET | Full | `TransactionsService.getTransactionDetails()` |  | No streaming |
| `/transactions/{tx_id}/effects` | GET | Full | `EffectsService.getEffects()` | Yes | stream(for: .effectsForTransaction) |
| `/transactions/{tx_id}/operations` | GET | Full | `OperationsService.getOperations()` | Yes | stream(for: .operationsForTransaction) |
| `/transactions/{tx_id}/payments` | GET | Full | `PaymentsService.getPayments()` | Yes | stream(for: .paymentsForTransaction) |
| `/transactions` | POST | Full | `TransactionsService.postTransactionCore()` |  | - |
| `/transactions_async` | POST | Full | `TransactionsService.postTransactionAsyncCore()` |  | - |

## Query Parameter Support

**Filter Parameters Coverage:** 39/39 (100.0%)

## Legend

- **Full** - Complete implementation with all features
- **Partial** - Basic functionality with some limitations
- **Missing** - Endpoint not implemented
- **Deprecated** - Deprecated endpoint with alternative available