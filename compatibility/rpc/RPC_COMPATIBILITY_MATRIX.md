# Soroban RPC API Compatibility Matrix

## Matrix Legend

| Symbol | Status | Description |
|--------|--------|-------------|
| ✅ | Fully Supported | Method implemented with all required parameters and response fields |
| ⚠️ | Partially Supported | Basic functionality present, missing some optional parameters or response fields |
| ❌ | Not Supported | Method not implemented in SDK |
| N/A | Not Applicable | Method or feature not relevant to this SDK |

## Version Information

- **iOS & macOS SDK Version:** 3.2.8
- **Compatible RPC Version:** v23.0.4
- **Protocol Version:** 23
- **Last Updated:** 2025-11-14
- **Platforms:** iOS 13.0+, macOS 10.15+
- **Language:** Swift with full async/await support

## Overall Statistics

- **Total RPC Methods:** 12
- **Fully Supported:** 12 (100.0%)
- **Partially Supported:** 0 (0.0%)
- **Not Supported:** 0 (0.0%)
- **Helper Methods:** 6 additional convenience methods
- **Advanced Features:** 5 (Contract Bindings, AssembledTransaction, Multi-Auth, Deployment, Type Conversion)

## Compatibility Matrix

### Transaction Methods

| RPC Method | JSON-RPC Method | Status | SDK Method | Response Type | Notes |
|------------|-----------------|--------|------------|---------------|-------|
| sendTransaction | sendTransaction | ✅ | `sendTransaction(transaction:)` | SendTransactionResponse | Full support for all response fields including diagnosticEvents, errorResult. |
| simulateTransaction | simulateTransaction | ✅ | `simulateTransaction(simulateTxRequest:)` | SimulateTransactionResponse | Supports transaction, resourceConfig (instructionLeeway), and authMode (protocol 23+). |
| getTransaction | getTransaction | ✅ | `getTransaction(transactionHash:)` | GetTransactionResponse | Full support including protocol 23+ events field (TransactionEvents), computed properties. |
| getTransactions | getTransactions | ✅ | `getTransactions(startLedger:paginationOptions:)` | GetTransactionsResponse | Full pagination support with cursor and limit. |

### Ledger Methods

| RPC Method | JSON-RPC Method | Status | SDK Method | Response Type | Notes |
|------------|-----------------|--------|------------|---------------|-------|
| getLatestLedger | getLatestLedger | ✅ | `getLatestLedger()` | GetLatestLedgerResponse | Returns id, protocolVersion, and sequence. |
| getLedgers | getLedgers | ✅ | `getLedgers(startLedger:paginationOptions:)` | GetLedgersResponse | Full pagination support with cursor and limit. |
| getLedgerEntries | getLedgerEntries | ✅ | `getLedgerEntries(base64EncodedKeys:)` | GetLedgerEntriesResponse | Supports up to 200 keys, returns entries with lastModifiedLedgerSeq and liveUntilLedgerSeq. |

### Event Methods

| RPC Method | JSON-RPC Method | Status | SDK Method | Response Type | Notes |
|------------|-----------------|--------|------------|---------------|-------|
| getEvents | getEvents | ✅ | `getEvents(startLedger:endLedger:eventFilters:paginationOptions:)` | GetEventsResponse | Full support including endLedger parameter, event filters (type, contractIds, topics with wildcards), pagination. |

### Network Info Methods

| RPC Method | JSON-RPC Method | Status | SDK Method | Response Type | Notes |
|------------|-----------------|--------|------------|---------------|-------|
| getNetwork | getNetwork | ✅ | `getNetwork()` | GetNetworkResponse | Returns friendbotUrl (optional), passphrase, and protocolVersion. |
| getVersionInfo | getVersionInfo | ✅ | `getVersionInfo()` | GetVersionInfoResponse | Returns version, commitHash, buildTimestamp, captiveCoreVersion, protocolVersion. Protocol 23 compliant (camelCase fields only). |
| getFeeStats | getFeeStats | ✅ | `getFeeStats()` | GetFeeStatsResponse | Full support for sorobanInclusionFee and inclusionFee with all percentile statistics (p10-p99, mode, min, max, transactionCount, ledgerCount). |
| getHealth | getHealth | ✅ | `getHealth()` | GetHealthResponse | Full support for all fields: status, latestLedger, oldestLedger, and ledgerRetentionWindow. Note: Numeric fields use Int type (functionally equivalent to UInt32). |

## Advanced Features

### 1. Contract Bindings (SorobanClient)

**Status:** ✅ Fully Implemented

The iOS SDK provides a comprehensive `SorobanClient` class for high-level contract interaction with automatic spec loading and type-safe method invocation.

**Key Features:**
- Automatic contract spec loading from blockchain
- Type-safe method invocation with native Swift types
- Automatic read/write call detection (read calls don't require signing)
- Contract deployment with constructor support
- Contract code installation (wasm upload)

**Main Methods:**
```swift
// Create client for existing contract
let client = try await SorobanClient.forClientOptions(options)

// Deploy new contract
let client = try await SorobanClient.deploy(deployRequest)

// Install contract code
let wasmHash = try await SorobanClient.install(installRequest, force: false)

// Invoke contract method (automatic read/write detection)
let result = try await client.invokeMethod(
    name: "transfer",
    args: [addressArg, amountArg],
    force: false,
    methodOptions: options
)

// Build transaction for manual control
let tx = try await client.buildInvokeMethodTx(
    name: "swap",
    args: args,
    methodOptions: options
)
```

**Contract Information:**
- `getSpecEntries()` - Returns contract spec entries
- `getContractSpec()` - Creates ContractSpec for type conversions
- `methodNames` - Array of available methods
- `contractId` - Contract identifier

**File:** `stellarsdk/stellarsdk/soroban/contract/SorobanClient.swift`

### 2. AssembledTransaction

**Status:** ✅ Fully Implemented

High-level transaction construction and management system providing comprehensive workflow automation.

**Key Features:**
- Automatic transaction simulation with resource estimation
- Automatic footprint calculation and soroban auth updates
- Automatic resource fee addition
- Optional automatic restore of expired ledger entries
- Read-only call detection
- Multi-signature workflow support
- Transaction polling with configurable timeout

**Workflow Example:**
```swift
// Build transaction
let tx = try await AssembledTransaction.build(options: txOptions)

// Simulate (automatically updates footprint and fees)
try await tx.simulate(restore: true)

// Sign and send
let response = try await tx.signAndSend(
    sourceAccountKeyPair: keyPair,
    force: false
)

// Or handle steps separately
try tx.sign(sourceAccountKeyPair: keyPair)
let response = try await tx.send()
```

**Advanced Features:**
- `needsNonInvokerSigningBy()` - Returns addresses that need to sign
- `signAuthEntries()` - Signs authorization entries with optional callback for remote signing
- `isReadCall()` - Determines if transaction is read-only
- `getSimulationData()` - Extracts return value, transaction data, and auth
- `restoreFootprint()` - Restores expired ledger entries

**Properties:**
- `raw` - Original transaction builder
- `tx` - Transaction after simulation
- `signed` - Signed transaction
- `simulationResponse` - Full simulation response
- `options` - Transaction configuration

**File:** `stellarsdk/stellarsdk/soroban/contract/AssembledTransaction.swift`

### 3. Contract Spec & Type Conversion

**Status:** ✅ Fully Implemented

Comprehensive type conversion system between native Swift types and XDR values based on contract specifications.

**ContractSpec Features:**
- Function specification lookup
- Native Swift value to XDR conversion
- Support for complex types (structs, unions, enums, tuples)
- UDT (User Defined Types) support
- Option types and void handling

**Supported Type Conversions:**
- **Primitives:** i32, i64, u32, u64, i128, u128, i256, u256
- **Strings:** String, Symbol
- **Binary:** Bytes, BytesN
- **Addresses:** Account and Contract addresses
- **Booleans:** Bool
- **Collections:** Arrays, Vectors, Maps, Dictionaries
- **Complex Types:** Structs (numeric and named fields), Unions, Enums, Tuples
- **Special:** Option types, Void, Timepoint, Duration

**Usage:**
```swift
let spec = client.getContractSpec()

// Convert function arguments
let xdrArgs = try spec.funcArgsToXdrSCValues(
    name: "transfer",
    args: ["from": fromAddress, "to": toAddress, "amount": 1000]
)

// Convert individual values
let xdrValue = try spec.nativeToXdrSCVal(
    val: mySwiftValue,
    ty: typeDefinition
)
```

**File:** `stellarsdk/stellarsdk/soroban/contract/ContractSpec.swift`

### 4. Multi-Signature Authorization Support

**Status:** ✅ Fully Implemented

Complete support for multi-signature workflows with both local and remote signing capabilities.

**Key Features:**
- Automatic detection of required non-invoker signers
- Authorization entry signing with callbacks
- Support for remote signing workflows
- Signature expiration ledger management
- Account and contract ID differentiation

**Workflow Example:**
```swift
// Build transaction (Alice is invoker)
let tx = try await client.buildInvokeMethodTx(name: "swap", args: swapArgs)

// Simulate
try await tx.simulate()

// Check who else needs to sign
let otherSigners = try tx.needsNonInvokerSigningBy()
// Returns: ["GBOB..."] (Bob's address)

// Option 1: Sign directly with Bob's keypair
try await tx.signAuthEntries(signerKeyPair: bobKeyPair)

// Option 2: Remote signing with callback
try await tx.signAuthEntries(
    signerKeyPair: aliceKeyPair,
    authorizeEntryCallback: { authEntry, network in
        // Send base64-encoded authEntry to remote server
        let encoded = try authEntry.xdrEncoded
        let signedEntry = try await remoteSign(encoded)
        return try SorobanAuthorizationEntryXDR(xdr: signedEntry)
    },
    validUntilLedgerSeq: currentLedger + 100
)

// Alice signs and sends
let response = try await tx.signAndSend(sourceAccountKeyPair: aliceKeyPair)
```

**Methods:**
- `needsNonInvokerSigningBy(includeAlreadySigned:)` - Returns array of required signers
- `signAuthEntries(signerKeyPair:authorizeEntryCallback:validUntilLedgerSeq:)` - Signs auth entries

**File:** `stellarsdk/stellarsdk/soroban/contract/AssembledTransaction.swift`

### 5. Contract Deployment & Code Management

**Status:** ✅ Fully Implemented

Complete contract lifecycle management from code installation to deployment.

**Features:**
- Contract code installation (wasm upload)
- Contract deployment with custom salt
- Constructor argument support
- Automatic contract ID extraction
- Force flag to override existing installations

**Installation Example:**
```swift
let installRequest = InstallRequest(
    rpcUrl: "https://soroban-testnet.stellar.org",
    network: .testnet,
    sourceAccountKeyPair: deployerKeyPair,
    wasmBytes: contractWasm,
    enableServerLogging: true
)

let wasmHash = try await SorobanClient.install(
    installRequest,
    force: false // set true to reinstall if already exists
)
```

**Deployment Example:**
```swift
let deployRequest = DeployRequest(
    rpcUrl: "https://soroban-testnet.stellar.org",
    network: .testnet,
    sourceAccountKeyPair: deployerKeyPair,
    wasmHash: wasmHash,
    constructorArgs: [nameArg, symbolArg], // Optional constructor args
    salt: customSalt, // Optional salt for contract ID generation
    methodOptions: methodOptions,
    enableServerLogging: true
)

let client = try await SorobanClient.deploy(deployRequest)
print("Contract deployed at: \(client.contractId)")
```

**Files:**
- `stellarsdk/stellarsdk/soroban/contract/InstallRequest.swift`
- `stellarsdk/stellarsdk/soroban/contract/DeployRequest.swift`

## Helper Methods

The SDK provides 6 additional helper methods built on top of core RPC methods:

| Helper Method | Description | Built On | Return Type |
|---------------|-------------|----------|-------------|
| `getContractCodeForWasmId(wasmId:)` | Loads contract code (wasm binary) for given wasmId | getLedgerEntries | ContractCodeEntryXDR |
| `getContractCodeForContractId(contractId:)` | Loads contract code for given contractId | getLedgerEntries (fetches instance first) | ContractCodeEntryXDR |
| `getContractInfoForContractId(contractId:)` | Extracts Environment Meta, Contract Spec, and Contract Meta from contract | getContractCodeForContractId + parser | SorobanContractInfo |
| `getContractInfoForWasmId(wasmId:)` | Extracts contract information from wasm id | getContractCodeForWasmId + parser | SorobanContractInfo |
| `getAccount(accountId:)` | Fetches minimal account info (sequence number) | getLedgerEntries | Account |
| `getContractData(contractId:key:durability:)` | Reads contract data ledger entries | getLedgerEntries | LedgerEntry |

**SorobanContractInfo Structure:**
```swift
struct SorobanContractInfo {
    let envInterfaceVersion: UInt64
    let specEntries: [SCSpecEntryXDR]
    let metaEntries: [String: String]
}
```

**Contract Parsing:**
The `SorobanContractParser` class parses contract bytecode to extract:
- Environment interface version
- Contract spec entries (functions, structs, enums, unions, etc.)
- Contract metadata (key-value pairs)

## Protocol 23+ Extension Fields

**Status:** ✅ **Fully Implemented**

The `getLedgerEntries` method supports Protocol 23+ optional extension field:
- ✅ `extXdr` - Base64-encoded LedgerEntry extension XDR

This field is included in the LedgerEntry response model and populated when present in the RPC response.

## Protocol Version Compatibility

### Baseline Support
- **Protocol 20+:** Full support for all core Soroban functionality

### Protocol 21 Features
✅ **Fully Supported:**
- `stateChanges` in SimulateTransactionResponse
- State change tracking for ledger entry modifications

### Protocol 22 Features
✅ **Fully Supported:**
- `cursor` in GetEventsResponse for pagination
- `txHash` in GetTransactionResponse

### Protocol 23 Features
✅ **Fully Supported:**
- `authMode` parameter in simulateTransaction (enforce, record, record_allow_nonroot)
- `latestLedgerCloseTime` in GetEventsResponse
- `oldestLedger` and `oldestLedgerCloseTime` in GetEventsResponse
- `events` (TransactionEvents) in GetTransactionResponse with contract and transaction events breakdown
- `operationIndex` field in event responses

⚠️ **Partially Supported:**
- Auto-restore for expired footprints (manual restore via AssembledTransaction)
- Extension fields in getLedgerEntries

✅ **Compatibility Notes:**
- Snake_case fields removed from getVersionInfo (SDK uses camelCase as required)
- Diagnostic events properly excluded from getEvents stream
- Support for '**' wildcard in event topic matching

## Implementation Quality

### Async/Await Support
✅ **Full Support:** All RPC methods and helper methods provide async/await interfaces with comprehensive error handling.

**Legacy Callbacks:** Available but deprecated. All methods have both async and callback versions for backwards compatibility.

### Error Handling
✅ **Comprehensive:** Typed errors for all scenarios with detailed error information.

**Error Types:**
- `SorobanRpcRequestError` - Network and RPC errors
- `AssembledTransactionError` - Transaction assembly errors
- `SorobanClientError` - Contract client errors
- `SorobanContractParserError` - Contract parsing errors
- `ContractSpecError` - Type conversion errors

### Type Safety
✅ **Strong:** Full Swift type safety with XDR classes for all Stellar types.

**XDR Support:**
- Complete XDR encoding/decoding for all Stellar types
- Type-safe conversions between native Swift and XDR
- Contract spec-based type validation

### HTTP Client
✅ **Production Ready:** URLSession-based with proper headers and configuration.

**Features:**
- Custom HTTP headers (X-Client-Version, X-Client-Name, X-App-Name, X-App-Version)
- JSON-RPC 2.0 compliant
- UUID request ID generation
- Optional logging support (`enableLogging` property)
- Proper error handling and response parsing

### Code Organization
✅ **Well Structured:** Clean separation of concerns with dedicated files for each component.

**Structure:**
- Core RPC client: `SorobanServer.swift`
- Response types: `responses/` directory
- Contract bindings: `contract/` directory
- Supporting types: Individual files for each type
- XDR definitions: Separate XDR package

## Unique SDK Features

The iOS/macOS SDK includes several features beyond the basic RPC API:

### 1. Automatic Read/Write Call Detection
The SDK automatically determines if a contract call is read-only (requires no signing) or write (requires signing and fees) based on:
- Authorization entries count (`authsCount == 0`)
- Write footprint length (`writeLength == 0`)

This allows developers to call `invokeMethod()` without knowing if the method requires signing.

### 2. Transaction Polling with Timeout
The `send()` method automatically polls for transaction completion with:
- Configurable timeout (default 300 seconds)
- 3-second intervals between polls
- Automatic status checking
- Complete response once confirmed

### 3. Computed Properties for Easy Data Access
Response objects include computed properties for common operations:
- `resultValue` - Extracts SCValXDR from transaction meta
- `transactionEnvelope` - Converts envelopeXdr to TransactionEnvelopeXDR
- `transactionResult` - Converts resultXdr to TransactionResultXDR
- `transactionMeta` - Converts resultMetaXdr to TransactionMetaXDR
- `wasmId` - Extracts wasm id if contract was installed
- `createdContractId` - Extracts contract id if contract was created
- `footprint` - Computed Footprint from simulation response
- `sorobanAuth` - Computed array of SorobanAuthorizationEntryXDR

### 4. Contract Bytecode Parsing
The `SorobanContractParser` extracts contract metadata directly from wasm bytecode:
- Environment interface version
- Contract specification (all function signatures, types, etc.)
- Contract metadata (author, description, etc.)

### 5. Comprehensive Native Type Support
The `ContractSpec.nativeToXdrSCVal()` method supports rich Swift types:
- Swift structs with named or positional fields
- Swift enums and unions (via NativeUnionVal)
- Swift arrays and dictionaries
- Swift optionals (mapped to Soroban Option type)
- All numeric types with proper size validation
- Address types (automatically detecting account vs contract)

### 6. Remote Signing Support
Multi-signature workflows support remote signing via callbacks, enabling:
- Mobile app signing for web applications
- Hardware wallet integration
- Multi-party signing workflows
- Authorization server patterns

### 7. Protocol Version Handling
The SDK handles protocol version differences gracefully:
- Conditionally includes protocol 23+ fields
- Maintains backwards compatibility
- Proper field name usage (camelCase for protocol 23+)

## Notes

### General Implementation Notes

1. **Production Ready:** The iOS SDK implementation is production-grade with comprehensive error handling, type safety, and extensive test coverage.

2. **Async/Await First:** All methods use modern Swift async/await patterns. Legacy callback support is deprecated but maintained for backwards compatibility.

3. **High-Level Abstractions:** The SDK provides both low-level RPC access (SorobanServer) and high-level abstractions (SorobanClient, AssembledTransaction) for different use cases.

4. **XDR Performance:** All XDR encoding/decoding is handled natively in Swift with optimal performance.

5. **Memory Efficient:** Response streaming and pagination are properly implemented to handle large result sets.

6. **Network Flexibility:** Supports custom RPC endpoints, Testnet, and Mainnet configurations.

7. **Logging Support:** Optional request/response logging for debugging (`enableLogging` property).

### Best Practices

1. **Use SorobanClient for Contract Interaction:** Prefer `SorobanClient` over direct RPC calls for contract methods. It handles spec loading, type conversion, and read/write detection automatically.

2. **Use AssembledTransaction for Complex Workflows:** For multi-signature workflows or when you need fine control over transaction lifecycle, use `AssembledTransaction`.

3. **Enable Restore for Simulations:** When simulating, set `restore: true` to automatically handle expired ledger entries:
   ```swift
   try await tx.simulate(restore: true)
   ```

4. **Handle Protocol Version Differences:** Check protocol version when using protocol 23+ features:
   ```swift
   let networkInfo = try await server.getNetwork()
   if networkInfo.protocolVersion >= 23 {
       // Use protocol 23+ features
   }
   ```

5. **Use Helper Methods:** Leverage helper methods like `getContractInfoForContractId()` instead of manually combining RPC calls.

6. **Set Reasonable Timeouts:** Configure `timeoutInSeconds` in `MethodOptions` based on expected contract execution time:
   ```swift
   let options = MethodOptions(
       fee: 100,
       timeoutInSeconds: 60, // 1 minute for simple contracts
       simulate: true,
       restore: false
   )
   ```

7. **Handle Errors Appropriately:** Use typed error handling for different failure scenarios:
   ```swift
   do {
       let result = try await client.invokeMethod(name: "transfer", args: args)
   } catch AssembledTransactionError.simulationFailed {
       // Handle simulation failure
   } catch AssembledTransactionError.restoreNeeded {
       // Handle restore needed
   } catch {
       // Handle other errors
   }
   ```

### Compatibility Recommendations


## Implementation Notes

### Type Compatibility
The `GetHealthResponse` uses `Int` type for ledger-related fields (`latestLedger`, `oldestLedger`, `ledgerRetentionWindow`) while the RPC specification uses unsigned integers. This is functionally equivalent for all practical values and does not affect data parsing or usage. Changing to `UInt32` would be a breaking change with no functional benefit, so the current implementation is maintained for backward compatibility.

### Performance Considerations

1. **Pagination:** Always use pagination for large result sets (events, transactions, ledgers).

2. **Key Batch Size:** When using `getLedgerEntries()`, stay well below the 200 key limit for better performance.

3. **Event Filtering:** Use specific filters (contractIds, topics) in `getEvents()` to reduce result set size.

4. **Simulation Caching:** Consider caching simulation results for read-only calls that don't depend on current state.

5. **Connection Pooling:** URLSession automatically handles connection pooling for optimal HTTP performance.

---

**Document Version:** 1.0
**Generated:** 2025-11-14
**SDK Version:** 3.2.8
**RPC Version:** v23.0.4
**Protocol Version:** 23
