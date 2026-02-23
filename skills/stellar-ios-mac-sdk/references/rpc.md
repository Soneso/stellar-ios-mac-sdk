# Soroban RPC API

`SorobanServer` is the client for all 12 Soroban RPC methods. Every method is `async` and returns a result enum with `.success` and `.failure` cases.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
server.enableLogging = true // optional: logs request/response JSON
```

## Network Information Methods

### getHealth

Check if the RPC node is operational.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let healthResponse = await server.getHealth()
switch healthResponse {
case .success(let health):
    // health.status: String (e.g., HealthStatus.HEALTHY = "healthy")
    // health.latestLedger: Int
    // health.oldestLedger: Int
    // health.ledgerRetentionWindow: Int
    print("Status: \(health.status), ledger: \(health.latestLedger)")
case .failure(let error):
    print("RPC error: \(error)")
}
```

### getNetwork

Get network passphrase and protocol version.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let networkResponse = await server.getNetwork()
switch networkResponse {
case .success(let network):
    // network.passphrase: String
    // network.protocolVersion: Int
    // network.friendbotUrl: String? (testnet only)
    print("Passphrase: \(network.passphrase)")
case .failure(let error):
    print("Error: \(error)")
}
```

### getLatestLedger

Get the most recent ledger sequence and protocol version.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let ledgerResponse = await server.getLatestLedger()
switch ledgerResponse {
case .success(let latest):
    // latest.id: String (hex hash)
    // latest.sequence: UInt32
    // latest.protocolVersion: Int
    print("Latest ledger: \(latest.sequence)")
case .failure(let error):
    print("Error: \(error)")
}
```

### getVersionInfo

Get RPC server and Captive Core version details.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let versionResponse = await server.getVersionInfo()
switch versionResponse {
case .success(let info):
    // info.version: String
    // info.commitHash: String
    // info.buildTimeStamp: String
    // info.captiveCoreVersion: String
    // info.protocolVersion: Int
    print("RPC version: \(info.version)")
case .failure(let error):
    print("Error: \(error)")
}
```

### getFeeStats

Get fee statistics for transaction prioritization.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let feeResponse = await server.getFeeStats()
switch feeResponse {
case .success(let stats):
    // stats.sorobanInclusionFee: InclusionFee (for Soroban transactions)
    // stats.inclusionFee: InclusionFee (for classic transactions)
    // stats.latestLedger: Int
    // InclusionFee has: min, max, mode, p10, p20, p30, p40, p50, p60, p70, p80, p90, p99, transactionCount, ledgerCount
    // NOTE: There is NO p95 property. Available percentiles: p10, p20, p30, p40, p50, p60, p70, p80, p90, p99
    print("Soroban median fee: \(stats.sorobanInclusionFee.p50)")
case .failure(let error):
    print("Error: \(error)")
}
```

## Transaction Methods

### simulateTransaction

Simulate a Soroban transaction without submitting. Returns resource costs, return values, and auth requirements.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Build the transaction with an InvokeHostFunction operation first
let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
    contractId: "CCONTRACTID...",
    functionName: "hello",
    functionArguments: [SCValXDR.symbol("world")]
)
let account = Account(keyPair: try KeyPair(accountId: sourceAccountId), sequenceNumber: sequenceNumber)
let transaction = try Transaction(
    sourceAccount: account,
    operations: [invokeOp],
    memo: Memo.none
)

let request = SimulateTransactionRequest(transaction: transaction)
let simResponse = await server.simulateTransaction(simulateTxRequest: request)
switch simResponse {
case .success(let simulation):
    // simulation.results: [SimulateTransactionResult]? -- return values
    // simulation.transactionData: SorobanTransactionDataXDR? -- footprint and resources
    // simulation.minResourceFee: UInt32? -- fee to add on top of base fee
    // simulation.error: String? -- nil on success
    // simulation.restorePreamble: RestorePreamble? -- if state needs restoring
    // simulation.sorobanAuth: [SorobanAuthorizationEntryXDR]? -- auth entries
    // simulation.footprint: Footprint? -- read/write ledger keys

    if let error = simulation.error {
        print("Simulation failed: \(error)")
        return
    }
    if let returnValue = simulation.results?.first?.returnValue {
        print("Return value: \(returnValue)")
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

### sendTransaction

Submit a signed transaction to the network. Returns immediately with a status -- does NOT wait for ledger inclusion.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// After simulating and applying resource data to the transaction:
let sendResponse = await server.sendTransaction(transaction: signedTransaction)
switch sendResponse {
case .success(let result):
    // result.transactionId: String (the transaction hash)
    // result.status: String (PENDING, DUPLICATE, TRY_AGAIN_LATER, ERROR)
    // result.latestLedger: Int
    // result.error: TransactionStatusError?
    // result.errorResult: TransactionResultXDR?
    // result.diagnosticEvents: [DiagnosticEventXDR]?
    switch result.status {
    case SendTransactionResponse.STATUS_PENDING:
        print("Submitted: \(result.transactionId)")
    case SendTransactionResponse.STATUS_ERROR:
        print("Rejected: \(result.error?.message ?? "unknown")")
    case SendTransactionResponse.STATUS_DUPLICATE:
        print("Already submitted")
    case SendTransactionResponse.STATUS_TRY_AGAIN_LATER:
        print("Server busy, retry")
    default:
        break
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

### getTransaction

Poll for a transaction's final status after submission.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
let txHash = "abc123..." // from sendTransaction result

let txResponse = await server.getTransaction(transactionHash: txHash)
switch txResponse {
case .success(let txInfo):
    // txInfo.status: String (SUCCESS, NOT_FOUND, FAILED)
    // txInfo.ledger: Int? -- ledger that included the tx
    // txInfo.createdAt: String? -- timestamp
    // txInfo.resultValue: SCValXDR? -- contract return value
    // txInfo.envelopeXdr: String?
    // txInfo.resultXdr: String?
    // txInfo.resultMetaXdr: String?
    // txInfo.wasmId: String? -- if contract was installed
    // txInfo.createdContractId: String? -- if contract was deployed
    switch txInfo.status {
    case GetTransactionResponse.STATUS_SUCCESS:
        print("Succeeded in ledger \(txInfo.ledger ?? 0)")
    case GetTransactionResponse.STATUS_NOT_FOUND:
        print("Still pending or expired")
    case GetTransactionResponse.STATUS_FAILED:
        print("Failed")
    default:
        break
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

### getTransactions

Get a paginated list of transactions starting from a specific ledger.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let txsResponse = await server.getTransactions(
    startLedger: 1000000,
    paginationOptions: PaginationOptions(limit: 10)
)
switch txsResponse {
case .success(let result):
    // result.transactions: [TransactionInfo]
    // result.latestLedger: Int
    // result.cursor: String? -- for pagination
    for tx in result.transactions {
        print("Hash: \(tx.txHash ?? "n/a"), status: \(tx.status), ledger: \(tx.ledger)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Ledger Entry Methods

### getLedgerEntries

Read current values of ledger entries directly (contract state, account data, etc.).

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Build a ledger key for a contract data entry
let contractId = "CCONTRACTID..."
let key = SCValXDR.symbol("counter")
let ledgerKey = LedgerKeyXDR.contractData(
    LedgerKeyContractDataXDR(
        contract: try SCAddressXDR(contractId: contractId),
        key: key,
        durability: .persistent
    )
)
let base64Key = ledgerKey.xdrEncoded!

let entriesResponse = await server.getLedgerEntries(base64EncodedKeys: [base64Key])
switch entriesResponse {
case .success(let result):
    // result.entries: [LedgerEntry]
    // result.latestLedger: Int
    for entry in result.entries {
        // entry.key: String (base64 XDR)
        // entry.xdr: String (base64 XDR of the value)
        // entry.lastModifiedLedgerSeq: Int
        // entry.liveUntilLedgerSeq: Int? (TTL for contract entries)
        if let valueXdr = entry.valueXdr {
            print("Entry data: \(valueXdr)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Event Methods

### getEvents

Query contract events within a ledger range with optional filters.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let contractId = "CCONTRACTID..."
let topicFilter = TopicFilter(segmentMatchers: [
    SCValXDR.symbol("transfer").xdrEncoded!,  // topic[0]: event name
    "*"                                        // topic[1]: wildcard
])
let eventFilter = EventFilter(
    type: "contract",
    contractIds: [contractId],
    topics: [topicFilter]
)

let eventsResponse = await server.getEvents(
    startLedger: 1000000,
    eventFilters: [eventFilter],
    paginationOptions: PaginationOptions(limit: 100)
)
switch eventsResponse {
case .success(let result):
    // result.events: [EventInfo]
    // result.latestLedger: Int
    // result.cursor: String? -- for pagination
    for event in result.events {
        // event.type: String ("contract", "system", "diagnostic")
        // event.contractId: String
        // event.id: String (unique event ID)
        // event.ledger: Int
        // event.topic: [String] (base64 XDR SCVal topics)
        // event.value: String (base64 XDR SCVal)
        // event.valueXdr: SCValXDR (decoded value)
        // event.txHash: String
        print("Event \(event.id) from \(event.contractId)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Complete Workflow: Simulate, Submit, Poll

The standard pattern for executing a Soroban contract write call:

```swift
import stellarsdk

let rpcUrl = "https://soroban-testnet.stellar.org"
let server = SorobanServer(endpoint: rpcUrl)
let network = Network.testnet
let sourceKeyPair = try KeyPair(secretSeed: "SXXXX...")
let contractId = "CCONTRACTID..."

// 1. Load account sequence number
let accountResponse = await server.getAccount(accountId: sourceKeyPair.accountId)
guard case .success(let account) = accountResponse else {
    print("Failed to load account")
    return
}

// 2. Build the invoke operation
let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
    contractId: contractId,
    functionName: "increment",
    functionArguments: []
)

// 3. Build the transaction
let transaction = try Transaction(
    sourceAccount: account,
    operations: [invokeOp],
    memo: Memo.none
)

// 4. Simulate to get resource requirements
let simRequest = SimulateTransactionRequest(transaction: transaction)
let simResponse = await server.simulateTransaction(simulateTxRequest: simRequest)
guard case .success(let simulation) = simResponse else {
    print("Simulation failed")
    return
}
if let simError = simulation.error {
    print("Simulation error: \(simError)")
    return
}

// 5. Check if state restoration is needed
if let restorePreamble = simulation.restorePreamble {
    let restoreOp = RestoreFootprintOperation()
    let restoreTx = try Transaction(
        sourceAccount: account,
        operations: [restoreOp],
        memo: Memo.none
    )
    restoreTx.setSorobanTransactionData(data: restorePreamble.transactionData)
    restoreTx.addResourceFee(resourceFee: restorePreamble.minResourceFee)
    try restoreTx.sign(keyPair: sourceKeyPair, network: network)
    let restoreResult = await server.sendTransaction(transaction: restoreTx)
    // Poll for restore completion before continuing...
}

// 6. Apply simulation data to the transaction
transaction.setSorobanTransactionData(data: simulation.transactionData!)
transaction.addResourceFee(resourceFee: simulation.minResourceFee!)
if let auth = simulation.sorobanAuth {
    transaction.setSorobanAuth(auth: auth)
}

// 7. Sign and submit
try transaction.sign(keyPair: sourceKeyPair, network: network)
let sendResult = await server.sendTransaction(transaction: transaction)
guard case .success(let sendInfo) = sendResult,
      sendInfo.status == SendTransactionResponse.STATUS_PENDING else {
    print("Submit failed")
    return
}
let txHash = sendInfo.transactionId

// 8. Poll for completion
var status = GetTransactionResponse.STATUS_NOT_FOUND
while status == GetTransactionResponse.STATUS_NOT_FOUND {
    try await Task.sleep(nanoseconds: 3_000_000_000)
    let pollResponse = await server.getTransaction(transactionHash: txHash)
    if case .success(let txInfo) = pollResponse {
        status = txInfo.status
        if status == GetTransactionResponse.STATUS_SUCCESS {
            if let returnValue = txInfo.resultValue {
                print("Contract returned: \(returnValue)")
            }
        } else if status == GetTransactionResponse.STATUS_FAILED {
            print("Transaction failed")
        }
    }
}
```

## Error Handling

All RPC methods return `SorobanRpcRequestError` on failure:

```swift
public enum SorobanRpcRequestError: Error, Sendable {
    case requestFailed(message: String)          // network/connection error
    case errorResponse(error: SorobanRpcError)   // JSON-RPC error from server
    case parsingResponseFailed(message: String, responseData: Data)  // response decode error
}

public struct SorobanRpcError: Error, Sendable {
    public let code: Int
    public let message: String?
    public let data: String?
}
```

Handle errors in a switch:

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let response = await server.getHealth()
switch response {
case .success(let health):
    print(health.status)
case .failure(let error):
    switch error {
    case .requestFailed(let message):
        print("Network error: \(message)")
    case .errorResponse(let rpcError):
        print("RPC error \(rpcError.code): \(rpcError.message ?? "")")
    case .parsingResponseFailed(let message, _):
        print("Parse error: \(message)")
    }
}
```

## Response Enum Quick Reference

| Method | Response Enum | Success Type |
|--------|--------------|--------------|
| `getHealth()` | `GetHealthResponseEnum` | `GetHealthResponse` |
| `getNetwork()` | `GetNetworkResponseEnum` | `GetNetworkResponse` |
| `getLatestLedger()` | `GetLatestLedgerResponseEnum` | `GetLatestLedgerResponse` |
| `getVersionInfo()` | `GetVersionInfoResponseEnum` | `GetVersionInfoResponse` |
| `getFeeStats()` | `GetFeeStatsResponseEnum` | `GetFeeStatsResponse` |
| `simulateTransaction(simulateTxRequest:)` | `SimulateTransactionResponseEnum` | `SimulateTransactionResponse` |
| `sendTransaction(transaction:)` | `SendTransactionResponseEnum` | `SendTransactionResponse` |
| `getTransaction(transactionHash:)` | `GetTransactionResponseEnum` | `GetTransactionResponse` |
| `getTransactions(startLedger:paginationOptions:)` | `GetTransactionsResponseEnum` | `GetTransactionsResponse` |
| `getLedgerEntries(base64EncodedKeys:)` | `GetLedgerEntriesResponseEnum` | `GetLedgerEntriesResponse` |
| `getEvents(startLedger:endLedger:eventFilters:paginationOptions:)` | `GetEventsResponseEnum` | `GetEventsResponse` |
| `getAccount(accountId:)` | `GetAccountResponseEnum` | `Account` |
