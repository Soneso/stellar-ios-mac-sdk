# Soroban RPC vs iOS/macOS SDK Compatibility Matrix

**RPC Version:** v25.0.0 (released 2025-12-12)  
**RPC Source:** [v25.0.0](https://github.com/stellar/stellar-rpc/releases/tag/v25.0.0)  
**SDK Version:** 3.4.3  
**Generated:** 2026-02-10 10:57:35

## Overall Coverage

**Coverage:** 100.0%

- **Fully Supported:** 12/12
- **Partially Supported:** 0/12
- **Not Supported:** 0/12

## Method Comparison

### Transaction Methods

| RPC Method | Status | SDK Method | Response Type | Notes |
|------------|--------|------------|---------------|-------|
| getTransaction | Full | `getTransaction(transactionHash:)` | GetTransactionResponse | Full support including protocol 23+ events field, computed properties. |
| getTransactions | Full | `getTransactions(startLedger:, paginationOptions:)` | GetTransactionsResponse | Full pagination support with cursor and limit. |
| sendTransaction | Full | `sendTransaction(transaction:)` | SendTransactionResponse | Full support for all response fields including diagnosticEvents, errorResult. |
| simulateTransaction | Full | `simulateTransaction(simulateTxRequest:)` | SimulateTransactionResponse | Supports transaction, resourceConfig (instructionLeeway), and authMode (protocol 23+). |

### Ledger Methods

| RPC Method | Status | SDK Method | Response Type | Notes |
|------------|--------|------------|---------------|-------|
| getLatestLedger | Full | `getLatestLedger()` | GetLatestLedgerResponse | Returns id, protocolVersion, and sequence. |
| getLedgerEntries | Full | `getLedgerEntries(base64EncodedKeys:)` | GetLedgerEntriesResponse | Supports up to 200 keys, returns entries with TTL info. |
| getLedgers | Full | `getLedgers(startLedger:, paginationOptions:, format:)` | GetLedgersResponse | Full pagination support with cursor and limit. |

### Event Methods

| RPC Method | Status | SDK Method | Response Type | Notes |
|------------|--------|------------|---------------|-------|
| getEvents | Full | `getEvents(startLedger:, endLedger:, eventFilters:, paginationOptions:)` | GetEventsResponse | Full support including endLedger, event filters (type, contractIds, topics), pagination. |

### Network Info Methods

| RPC Method | Status | SDK Method | Response Type | Notes |
|------------|--------|------------|---------------|-------|
| getFeeStats | Full | `getFeeStats()` | GetFeeStatsResponse | Full support for sorobanInclusionFee and inclusionFee statistics. |
| getHealth | Full | `getHealth()` | GetHealthResponse | Full support for all fields. |
| getNetwork | Full | `getNetwork()` | GetNetworkResponse | Returns friendbotUrl (optional), passphrase, and protocolVersion. |
| getVersionInfo | Full | `getVersionInfo()` | GetVersionInfoResponse | Protocol 23 compliant (camelCase fields only). |

## Parameter Coverage

Detailed breakdown of parameter support per method.

| RPC Method | RPC Params | SDK Params | Missing |
|------------|------------|------------|---------|
| getEvents | 4 | 4 | - |
| getFeeStats | 0 | 0 | - |
| getHealth | 0 | 0 | - |
| getLatestLedger | 0 | 0 | - |
| getLedgerEntries | 1 | 1 | - |
| getLedgers | 2 | 2 | - |
| getNetwork | 0 | 0 | - |
| getTransaction | 1 | 1 | - |
| getTransactions | 2 | 2 | - |
| getVersionInfo | 0 | 0 | - |
| sendTransaction | 1 | 1 | - |
| simulateTransaction | 3 | 3 | - |

## Response Field Coverage

Detailed breakdown of response field support per method.

| RPC Method | RPC Fields | SDK Fields | Missing |
|------------|------------|------------|---------|
| getEvents | 6 | 6 | - |
| getFeeStats | 3 | 3 | - |
| getHealth | 4 | 4 | - |
| getLatestLedger | 6 | 6 | - |
| getLedgerEntries | 2 | 2 | - |
| getLedgers | 6 | 6 | - |
| getNetwork | 3 | 3 | - |
| getTransaction | 15 | 15 | - |
| getTransactions | 6 | 6 | - |
| getVersionInfo | 5 | 5 | - |
| sendTransaction | 7 | 7 | - |
| simulateTransaction | 8 | 8 | - |

## Legend

| Status | Description |
|--------|-------------|
| Full | Method implemented with all required parameters and response fields |
| Partial | Basic functionality present, missing some optional parameters or response fields |
| Missing | Method not implemented in SDK |
