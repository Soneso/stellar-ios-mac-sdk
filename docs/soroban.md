# Soroban Smart Contracts

Deploy and interact with Soroban smart contracts using the Stellar iOS/macOS SDK.

**Protocol details**: [Soroban Documentation](https://developers.stellar.org/docs/smart-contracts)

## Quick Start

Install WASM, deploy a contract, and call a method in one go.

```swift
import stellarsdk

let keyPair = try KeyPair(secretSeed: "SXXX...")
let rpcUrl = "https://soroban-testnet.stellar.org"

// 1. Install WASM
let wasmData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/hello.wasm"))
let wasmHash = try await SorobanClient.install(
    installRequest: InstallRequest(
        rpcUrl: rpcUrl,
        network: Network.testnet,
        sourceAccountKeyPair: keyPair,
        wasmBytes: wasmData,
        enableServerLogging: false
    )
)

// 2. Deploy
let client = try await SorobanClient.deploy(
    deployRequest: DeployRequest(
        rpcUrl: rpcUrl,
        network: Network.testnet,
        sourceAccountKeyPair: keyPair,
        wasmHash: wasmHash,
        enableServerLogging: false
    )
)

// 3. Invoke
let result = try await client.invokeMethod(
    name: "hello",
    args: [SCValXDR.symbol("World")]
)
if let vec = result.vec {
    print("\(vec[0].symbol!), \(vec[1].symbol!)") // Hello, World
}
```

## SorobanServer

Direct communication with Soroban RPC nodes for low-level operations.

### Connecting to RPC

Connect to a Soroban RPC node to send requests and receive responses.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Optional: enable debug logging
server.enableLogging = true
```

### Health Check

Verify the RPC node is operational before making requests.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let healthResponse = await server.getHealth()
switch healthResponse {
case .success(let health):
    if health.status == HealthStatus.HEALTHY {
        print("Node healthy")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Network Information

Get network passphrase and protocol version.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let networkResponse = await server.getNetwork()
switch networkResponse {
case .success(let network):
    print("Passphrase: \(network.passphrase)")
    print("Protocol version: \(network.protocolVersion)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Latest Ledger

Get the current ledger sequence for transaction timing.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let ledgerResponse = await server.getLatestLedger()
switch ledgerResponse {
case .success(let ledger):
    print("Sequence: \(ledger.sequence)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Account Data

Load account information (needed for transaction building).

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Returns Account via result enum (not AccountResponse like Horizon)
let accountResponse = await server.getAccount(accountId: "GABC...")
switch accountResponse {
case .success(let account):
    print("Sequence: \(account.sequenceNumber)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Contract Data

Read persistent or temporary data stored by a contract.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let contractDataResponse = await server.getContractData(
    contractId: "CCXYZ...",
    key: SCValXDR.symbol("counter"),
    durability: ContractDataDurability.persistent
)

switch contractDataResponse {
case .success(let entry):
    print("Last modified: \(entry.lastModifiedLedgerSeq)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Contract Info

Load contract specification and metadata.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// By contract ID
let infoResponse = await server.getContractInfoForContractId(contractId: "CCXYZ...")
switch infoResponse {
case .success(let info):
    print("Spec entries: \(info.specEntries.count)")
case .rpcFailure(let error):
    print("RPC error: \(error)")
case .parsingFailure(let error):
    print("Parsing error: \(error)")
}

// By WASM ID (hash of uploaded code)
let infoResponse2 = await server.getContractInfoForWasmId(wasmId: wasmId)
```

### Get Ledger Entries

Query raw ledger entries by their keys. Use when you need direct access to ledger state data.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Build ledger key for contract data
let contractDataKey = LedgerKeyContractDataXDR(
    contract: try SCAddressXDR(contractId: "CABC..."),
    key: SCValXDR.symbol("counter"),
    durability: ContractDataDurability.persistent
)
let ledgerKey = LedgerKeyXDR.contractData(contractDataKey)
let base64Key = ledgerKey.xdrEncoded!

// Request ledger entries
let entriesResponse = await server.getLedgerEntries(base64EncodedKeys: [base64Key])

switch entriesResponse {
case .success(let result):
    for entry in result.entries {
        print("Last modified: \(entry.lastModifiedLedgerSeq)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Load Contract Code

Helper methods to load contract bytecode from the network.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// By contract ID
let codeResponse = await server.getContractCodeForContractId(contractId: "CCXYZ...")
switch codeResponse {
case .success(let contractCode):
    print("Code size: \(contractCode.code.count) bytes")
case .failure(let error):
    print("Error: \(error)")
}

// By WASM ID
let codeResponse2 = await server.getContractCodeForWasmId(wasmId: wasmId)
```

## SorobanClient

High-level API for contract interaction.

### Creating a Client

Set up a SorobanClient instance for interacting with a specific contract.

```swift
import stellarsdk

let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        contractId: "CCXYZ...",
        network: Network.testnet,
        rpcUrl: "https://soroban-testnet.stellar.org"
    )
)

let methodNames = client.methodNames
let spec = client.getContractSpec()
```

### Invoking Methods

Call contract functions to read data or submit state changes.

```swift
import stellarsdk

let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        contractId: "CCXYZ...",
        network: Network.testnet,
        rpcUrl: "https://soroban-testnet.stellar.org"
    )
)

// Read-only (returns simulation result)
let balance = try await client.invokeMethod(
    name: "balance",
    args: [SCValXDR.address(try SCAddressXDR(accountId: "GABC..."))]
)

// Write (auto-signs and submits)
let result = try await client.invokeMethod(
    name: "transfer",
    args: [
        SCValXDR.address(try SCAddressXDR(accountId: "GFROM...")),
        SCValXDR.address(try SCAddressXDR(accountId: "GTO...")),
        SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000)),
    ]
)

// Custom options
let result2 = try await client.invokeMethod(
    name: "expensive_op",
    args: [],
    methodOptions: MethodOptions(
        fee: 10000,
        timeoutInSeconds: 30,
        restore: true // Auto-restore expired state
    )
)
```

## Installing and Deploying

Put your contract on the network. Install uploads the WASM bytecode once; deploy creates contract instances from that code.

### Installation

Upload WASM bytecode (do once per contract version):

```swift
import stellarsdk

let wasmData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/contract.wasm"))
let wasmHash = try await SorobanClient.install(
    installRequest: InstallRequest(
        rpcUrl: "https://soroban-testnet.stellar.org",
        network: Network.testnet,
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        wasmBytes: wasmData,
        enableServerLogging: false
    )
)
```

### Deployment

Create contract instance from installed WASM:

```swift
import stellarsdk

// Basic deployment
let client = try await SorobanClient.deploy(
    deployRequest: DeployRequest(
        rpcUrl: "https://soroban-testnet.stellar.org",
        network: Network.testnet,
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        wasmHash: wasmHash,
        enableServerLogging: false
    )
)

// With constructor (protocol 22+)
let client2 = try await SorobanClient.deploy(
    deployRequest: DeployRequest(
        rpcUrl: "https://soroban-testnet.stellar.org",
        network: Network.testnet,
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        wasmHash: wasmHash,
        constructorArgs: [SCValXDR.symbol("MyToken"), SCValXDR.u32(8)],
        enableServerLogging: false
    )
)
```

## AssembledTransaction

Fine-grained control over the transaction lifecycle. Use `buildInvokeMethodTx()` instead of `invokeMethod()` when you need to inspect simulation results, add memos, or handle multi-signature workflows.

### Building Without Submitting

Build a transaction to inspect it before submission.

```swift
import stellarsdk

let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        contractId: "CCXYZ...",
        network: Network.testnet,
        rpcUrl: "https://soroban-testnet.stellar.org"
    )
)

// Build without submitting
let tx = try await client.buildInvokeMethodTx(
    name: "transfer",
    args: [SCValXDR.symbol("test")]
)
```

### Accessing Simulation Results

Get simulation data including return values and resource estimates.

```swift
import stellarsdk

// Access simulation results
let simData = try tx.getSimulationData()
let returnValue = simData.returnedValue
let minResourceFee = tx.simulationResponse?.minResourceFee
```

### Read-Only vs Write Calls

Check if a call is read-only (simulation only) or requires submission.

```swift
import stellarsdk

if try tx.isReadCall() {
    // Read-only: result available from simulation
    let result = try tx.getSimulationData().returnedValue
} else {
    // Write: must sign and submit
    let response = try await tx.signAndSend()
    let result = response.resultValue
}
```

### Modifying Before Submission

Skip automatic simulation to modify the transaction (e.g., add memo) before simulating.

```swift
import stellarsdk

// Build without auto-simulation
let tx = try await client.buildInvokeMethodTx(
    name: "my_method",
    args: [],
    methodOptions: MethodOptions(simulate: false)
)

// Modify the raw transaction
tx.raw?.setMemo(memo: Memo.text("My memo"))

// Now simulate and submit
try await tx.simulate()
let response = try await tx.signAndSend()
```

## Authorization

Handle multi-party signing for operations like swaps, escrow, and transfers that require consent from multiple accounts.

### Check Who Needs to Sign

Before submission, check which accounts need to authorize the transaction.

```swift
import stellarsdk

let alice = try KeyPair(secretSeed: "SALICE...")
let bob = try KeyPair(secretSeed: "SBOB...")

let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: alice,
        contractId: "CSWAP...",
        network: Network.testnet,
        rpcUrl: "https://soroban-testnet.stellar.org"
    )
)

let tx = try await client.buildInvokeMethodTx(
    name: "swap",
    args: [
        SCValXDR.address(try SCAddressXDR(accountId: alice.accountId)),
        SCValXDR.address(try SCAddressXDR(accountId: bob.accountId)),
        SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000)),
        SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 500)),
    ]
)

// Check who needs to sign (returns list of account IDs)
let neededSigners = try tx.needsNonInvokerSigningBy()
// e.g., ["GBOB..."] - Bob needs to authorize
```

### Local Signing

Sign auth entries when you have the private key locally.

```swift
import stellarsdk

// Sign Bob's auth entries (Bob's keypair available locally)
try await tx.signAuthEntries(signerKeyPair: bob)

// Submit (Alice signs the transaction envelope)
let response = try await tx.signAndSend()
```

### Remote Signing

Sign auth entries when the private key is on another server (e.g., custody service).

```swift
import stellarsdk

// Only have Bob's public key locally
let bobPublicKey = try KeyPair(accountId: "GBOB...")

try await tx.signAuthEntries(
    signerKeyPair: bobPublicKey,
    authorizeEntryCallback: { (entry, network) async throws in
        // Send to remote server for signing
        let base64Entry = entry.xdrEncoded!
        let signedBase64 = try await sendToRemoteServer(base64Entry) // Your implementation
        return try SorobanAuthorizationEntryXDR(fromBase64: signedBase64)
    }
)

// Submit after all auth entries are signed
let response = try await tx.signAndSend()
```

## Type Conversions

Convert between Swift native types and Soroban XDR values.

### Creating SCValXDR

Create XDR values manually for contract arguments.

#### Primitives

Basic data types like numbers, booleans, and strings.

```swift
import stellarsdk

let boolVal = SCValXDR.bool(true)
let u32Val = SCValXDR.u32(42)
let i32Val = SCValXDR.i32(-42)
let u64Val = SCValXDR.u64(1_000_000)
let i64Val = SCValXDR.i64(-1_000_000)
let stringVal = SCValXDR.string("Hello")
let symbolVal = SCValXDR.symbol("transfer")
let bytesVal = SCValXDR.bytes(Data([0xDE, 0xAD, 0xBE, 0xEF]))
let voidVal = SCValXDR.void
```

#### Big Integers (128/256-bit)

Handle integers that exceed Swift's native integer range using hi/lo parts.

```swift
import stellarsdk

// 128-bit using hi/lo parts
let u128Val = SCValXDR.u128(UInt128PartsXDR(hi: 0, lo: 1000))
let i128Val = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))

// 256-bit using four 64-bit parts
let u256Val = SCValXDR.u256(UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 1000))
let i256Val = SCValXDR.i256(Int256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 1000))

// For large values, use ContractSpec.nativeToXdrSCVal with a String:
let spec = ContractSpec(entries: [])
let largeU128 = try spec.nativeToXdrSCVal(
    val: "340282366920938463463374607431768211455",
    ty: SCSpecTypeDefXDR.u128
)
```

#### Addresses

Account and contract addresses for referencing entities on the network.

```swift
import stellarsdk

// Account address (G...)
let account = SCValXDR.address(try SCAddressXDR(accountId: "GABC..."))

// Contract address (C...)
let contract = SCValXDR.address(try SCAddressXDR(contractId: "CABC..."))
```

#### Collections

Arrays (vectors) and key-value pairs (maps) for structured data.

```swift
import stellarsdk

// Vector (array)
let vec = SCValXDR.vec([
    SCValXDR.symbol("a"),
    SCValXDR.symbol("b"),
])

// Map (key-value pairs)
let map = SCValXDR.map([
    SCMapEntryXDR(key: SCValXDR.symbol("name"), val: SCValXDR.string("Alice")),
    SCMapEntryXDR(key: SCValXDR.symbol("age"), val: SCValXDR.u32(30)),
])
```

### Using ContractSpec

Auto-convert native Swift values based on the contract specification. The spec is loaded from the contract and knows the expected types.

```swift
import stellarsdk

let spec = client.getContractSpec()

// Convert function arguments (uses spec to determine types)
let args = try spec.funcArgsToXdrSCValues(name: "swap", args: [
    "a": "GALICE...",        // Auto-converts to Address
    "b": "GBOB...",
    "token_a": "CTOKEN1...", // Contract address
    "token_b": "CTOKEN2...",
    "amount_a": 1000,         // Auto-converts to i128
    "min_b_for_a": 950,
    "amount_b": 500,
    "min_a_for_b": 450,
])

// Explore contract functions
let functions = spec.funcs()
let swapFunc = spec.getFunc(name: "swap")
```

### Advanced Type Conversions

For low-level control, use `nativeToXdrSCVal()` with explicit type definitions.

#### Void and Option (Nullable)

Empty values and nullable types for optional data.

```swift
import stellarsdk

// Void
let voidVal = try spec.nativeToXdrSCVal(val: nil, ty: SCSpecTypeDefXDR.void)

// Option (nullable) - returns string or void
let optionType = SCSpecTypeDefXDR.option(
    SCSpecTypeOptionXDR(valueType: SCSpecTypeDefXDR.string)
)
let strVal = try spec.nativeToXdrSCVal(val: "a string", ty: optionType)  // String value
let noneVal = try spec.nativeToXdrSCVal(val: nil, ty: optionType)        // Void (none)
```

#### Vectors with Element Type

Strongly-typed arrays where all elements share the same type.

```swift
import stellarsdk

let vecType = SCSpecTypeDefXDR.vec(
    SCSpecTypeVecXDR(elementType: SCSpecTypeDefXDR.symbol)
)
let val = try spec.nativeToXdrSCVal(val: ["a", "b", "c"], ty: vecType)
```

#### Maps with Key/Value Types

Strongly-typed key-value mappings with specific types for keys and values.

```swift
import stellarsdk

let mapType = SCSpecTypeMapXDR(
    keyType: SCSpecTypeDefXDR.string,
    valueType: SCSpecTypeDefXDR.address
)
let mapTypeDef = SCSpecTypeDefXDR.map(mapType)
let val = try spec.nativeToXdrSCVal(val: [
    "alice": "GALICE...",
    "bob": "GBOB...",
], ty: mapTypeDef)
```

#### Tuples

Fixed-size collections of values where each position has a specific type.

```swift
import stellarsdk

let tupleType = SCSpecTypeTupleXDR(valueTypes: [
    SCSpecTypeDefXDR.string,
    SCSpecTypeDefXDR.bool,
    SCSpecTypeDefXDR.u32,
])
let tupleTypeDef = SCSpecTypeDefXDR.tuple(tupleType)
let val = try spec.nativeToXdrSCVal(val: ["hello", true, 42], ty: tupleTypeDef)
```

#### Bytes and BytesN

Binary data of variable or fixed length for hashes, keys, and raw data.

```swift
import stellarsdk

// Variable-length bytes
let val = try spec.nativeToXdrSCVal(val: Data(count: 32), ty: SCSpecTypeDefXDR.bytes)

// Fixed-length bytes (e.g., 32 bytes for a hash)
let fixedType = SCSpecTypeDefXDR.bytesN(SCSpecTypeBytesNXDR(n: 32))
let fixedVal = try spec.nativeToXdrSCVal(val: Data(count: 32), ty: fixedType)
```

#### User-Defined Types (Enum, Struct, Union)

**Enum** -- pass the integer value:

```swift
import stellarsdk

let enumType = SCSpecTypeDefXDR.udt(SCSpecTypeUDTXDR(name: "MyEnum"))
let val = try spec.nativeToXdrSCVal(val: 2, ty: enumType) // Enum case with value 2
```

**Struct** -- pass a dictionary:

```swift
import stellarsdk

let structType = SCSpecTypeDefXDR.udt(SCSpecTypeUDTXDR(name: "MyStruct"))
let val = try spec.nativeToXdrSCVal(val: [
    "field1": 100,
    "field2": "hello",
    "field3": true,
] as [String: Any], ty: structType)
```

**Union** -- use `NativeUnionVal`:

```swift
import stellarsdk

let unionType = SCSpecTypeDefXDR.udt(SCSpecTypeUDTXDR(name: "MyUnion"))

// Void case (no values)
let val = try spec.nativeToXdrSCVal(val: NativeUnionVal(tag: "voidCase"), ty: unionType)

// Tuple case (with values)
let tupleVal = try spec.nativeToXdrSCVal(
    val: NativeUnionVal(tag: "tupleCase", values: ["hello", 42]),
    ty: unionType
)
```

### Reading Return Values

Access return values by their XDR type.

```swift
import stellarsdk

let result = try await client.invokeMethod(name: "get_data", args: [])

// Direct types (no unwrapping needed)
let name = result.string
let symbol = result.symbol
let flag = result.bool

// Numeric values
let count = result.u32
let bigVal = result.i64

// i128 extraction (common for token balances)
if let i128 = result.i128 {
    let hi = i128.hi
    let lo = i128.lo
    // Or use the convenience string representation
    let valueString = result.i128String
}

// Iterate vector elements
if let vec = result.vec {
    for item in vec {
        print(item.symbol ?? "")
    }
}

// Access map entries
if let map = result.map {
    for entry in map {
        print("\(entry.key.symbol ?? ""): \(entry.val.string ?? "")")
    }
}
```

## Events

Query contract events emitted during execution. Useful for tracking transfers, state changes, and other contract activity.

### Basic Event Query

Query events starting from a specific ledger.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Get events starting from ledger 12345
let eventsResponse = await server.getEvents(startLedger: 12345)

switch eventsResponse {
case .success(let result):
    for event in result.events {
        print("Ledger: \(event.ledger)")
        print("Contract: \(event.contractId)")
        print("Type: \(event.type)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Filtering by Contract and Topic

Filter events by contract ID and topic values.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let contractId = "CCXYZ..."

// Filter: any first topic, "transfer" as second topic
let topicFilter = TopicFilter(segmentMatchers: [
    "*", // Wildcard for first topic
    SCValXDR.symbol("transfer").xdrEncoded!,
])

let filter = EventFilter(
    type: "contract",
    contractIds: [contractId],
    topics: [topicFilter]
)

let eventsResponse = await server.getEvents(
    startLedger: 12345,
    eventFilters: [filter]
)

switch eventsResponse {
case .success(let result):
    for event in result.events {
        print("Ledger: \(event.ledger)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

## Error Handling

Handle errors at different stages: client creation, simulation, and transaction submission.

### Debug Logging

Enable logging to diagnose issues.

```swift
import stellarsdk

let client = try await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
        contractId: "CCXYZ...",
        network: Network.testnet,
        rpcUrl: "https://soroban-testnet.stellar.org",
        enableServerLogging: true // Debug JSON-RPC requests/responses
    )
)
```

### Method Not Found

Handle invalid method names or arguments.

```swift
import stellarsdk

do {
    let tx = try await client.buildInvokeMethodTx(
        name: "nonexistent",
        args: []
    )
} catch {
    print("Error: \(error)")
}
```

### Simulation Errors

Check simulation response for errors before submission.

```swift
import stellarsdk

let tx = try await client.buildInvokeMethodTx(
    name: "my_method",
    args: []
)

if let simError = tx.simulationResponse?.error {
    print("Simulation failed: \(simError)")
    // Don't submit - fix the issue first
}
```

### Transaction Failures

Handle failures after submission.

```swift
import stellarsdk

do {
    let response = try await tx.signAndSend()

    if response.status == GetTransactionResponse.STATUS_FAILED {
        print("Transaction failed: \(response.resultXdr ?? "unknown")")
    } else if response.status == GetTransactionResponse.STATUS_SUCCESS {
        print("Success!")
    }
} catch {
    print("Submission error: \(error)")
}
```

### Auto-Restore Expired State

Automatically restore expired contract state before invocation.

```swift
import stellarsdk

// If contract state has expired, restore it automatically
let result = try await client.invokeMethod(
    name: "my_method",
    args: [],
    methodOptions: MethodOptions(restore: true)
)
```

## Contract Bindings

Generate type-safe Swift classes from contract specifications. This provides IDE autocompletion and compile-time type checking.

### Generate Bindings

Use [stellar-contract-bindings](https://github.com/nicktomlin/stellar-contract-bindings) to generate Swift classes:

```bash
pip install stellar-contract-bindings

stellar-contract-bindings swift \
  --contract-id YOUR_CONTRACT_ID \
  --rpc-url https://soroban-testnet.stellar.org \
  --output ./generated \
  --class-name TokenClient
```

Or use the [web interface](https://stellar-contract-bindings.fly.dev/).

### Use Generated Client

The generated client provides type-safe method calls with native Swift types.

```swift
import stellarsdk
// import your generated bindings

let clientOptions = ClientOptions(
    sourceAccountKeyPair: try KeyPair(secretSeed: "SXXX..."),
    contractId: "CTOKEN...",
    network: Network.testnet,
    rpcUrl: "https://soroban-testnet.stellar.org"
)
let tokenClient = try await TokenContract.forClientOptions(options: clientOptions)

// Type-safe calls with native Swift types
let balance = try await tokenClient.balance(id: try SCAddressXDR(accountId: "GABC..."))
let mintTx = try await tokenClient.buildMintTx(
    to: try SCAddressXDR(accountId: "GTO..."),
    amount: "1000"
)
```

## Low-Level Operations

Manual operations for custom workflows requiring full control over the transaction process.

### Upload WASM

Upload contract bytecode to the network. Returns a WASM hash for deployment.

```swift
import stellarsdk

let keyPair = try KeyPair(secretSeed: "SXXX...")
let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// Build upload operation
let wasmData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/contract.wasm"))
let uploadOp = try InvokeHostFunctionOperation.forUploadingContractWasm(
    contractCode: wasmData
)

// Load account for sequence number
let accountEnum = await server.getAccount(accountId: keyPair.accountId)
guard case .success(let account) = accountEnum else {
    print("Account not found")
    return
}

// Build and simulate transaction
let transaction = try Transaction(
    sourceAccount: account,
    operations: [uploadOp],
    memo: nil
)

let simEnum = await server.simulateTransaction(
    simulateTxRequest: SimulateTransactionRequest(transaction: transaction)
)
guard case .success(let sim) = simEnum else {
    print("Simulation failed")
    return
}

if let txData = sim.transactionData {
    transaction.setSorobanTransactionData(data: txData)
}
if let minFee = sim.minResourceFee {
    transaction.addResourceFee(resourceFee: minFee)
}
try transaction.sign(keyPair: keyPair, network: Network.testnet)

// Submit
let sendEnum = await server.sendTransaction(transaction: transaction)
guard case .success(let sendResponse) = sendEnum else {
    print("Send failed")
    return
}

// Poll for result
var status = GetTransactionResponse.STATUS_NOT_FOUND
while status == GetTransactionResponse.STATUS_NOT_FOUND {
    try await Task.sleep(nanoseconds: 3_000_000_000)
    let txEnum = await server.getTransaction(transactionHash: sendResponse.transactionId)
    if case .success(let txResponse) = txEnum {
        status = txResponse.status
        if status == GetTransactionResponse.STATUS_SUCCESS {
            let wasmHash = txResponse.wasmId
        }
    }
}
```

### Create Contract Instance

Deploy a contract instance from an uploaded WASM hash.

```swift
import stellarsdk

let sourceAddress = try SCAddressXDR(accountId: keyPair.accountId)
let createOp = try InvokeHostFunctionOperation.forCreatingContract(
    wasmId: wasmHash,
    address: sourceAddress
)

// Build, simulate, set auth, sign, and send
let accountEnum = await server.getAccount(accountId: keyPair.accountId)
guard case .success(let account) = accountEnum else { return }

let transaction = try Transaction(
    sourceAccount: account,
    operations: [createOp],
    memo: nil
)

let simEnum = await server.simulateTransaction(
    simulateTxRequest: SimulateTransactionRequest(transaction: transaction)
)
guard case .success(let sim) = simEnum else { return }

if let txData = sim.transactionData {
    transaction.setSorobanTransactionData(data: txData)
}
transaction.setSorobanAuth(auth: sim.sorobanAuth)
if let minFee = sim.minResourceFee {
    transaction.addResourceFee(resourceFee: minFee)
}
try transaction.sign(keyPair: keyPair, network: Network.testnet)

let sendEnum = await server.sendTransaction(transaction: transaction)
```

### Create Contract with Constructor (Protocol 22+)

Deploy contracts that have constructors.

```swift
import stellarsdk

let sourceAddress = try SCAddressXDR(accountId: keyPair.accountId)
let createOp = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
    wasmId: wasmHash,
    address: sourceAddress,
    constructorArguments: [SCValXDR.symbol("MyToken"), SCValXDR.u32(8)]
)

// Build, simulate, sign, and send (same pattern)
```

### Invoke Contract (Low-Level)

Invoke a contract method without using SorobanClient.

```swift
import stellarsdk

let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
    contractId: contractId,
    functionName: "hello",
    functionArguments: [SCValXDR.symbol("World")]
)

// Build transaction
let accountEnum = await server.getAccount(accountId: keyPair.accountId)
guard case .success(let account) = accountEnum else { return }

let transaction = try Transaction(
    sourceAccount: account,
    operations: [invokeOp],
    memo: nil
)

// Simulate to get resource requirements
let simEnum = await server.simulateTransaction(
    simulateTxRequest: SimulateTransactionRequest(transaction: transaction)
)
guard case .success(let sim) = simEnum else { return }

if let txData = sim.transactionData {
    transaction.setSorobanTransactionData(data: txData)
}
if let minFee = sim.minResourceFee {
    transaction.addResourceFee(resourceFee: minFee)
}
try transaction.sign(keyPair: keyPair, network: Network.testnet)

// Submit and poll for result
let sendEnum = await server.sendTransaction(transaction: transaction)
// Poll getTransaction until success, then get result:
// let result = txResponse.resultValue
```

### Deploy Stellar Asset Contract (SAC)

Wrap a classic Stellar asset as a Soroban token contract. The protocol requires a `FROM_ASSET` contract ID preimage, so SAC deployment uses `InvokeHostFunctionOperation.forDeploySACWithAsset` with the asset to wrap.

```swift
import stellarsdk

let usdcIssuer = try KeyPair(accountId: "GISSUER...")
let usdcAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USDC", issuer: usdcIssuer)!

let sacOp = try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: usdcAsset)

// Build, simulate, sign, and send
```

### Direct Authorization Signing

For advanced auth workflows, sign authorization entries directly.

```swift
import stellarsdk

// Get auth entries from simulation
let auth = sim.sorobanAuth

let latestLedgerEnum = await server.getLatestLedger()
guard case .success(let latestLedger) = latestLedgerEnum else { return }

if var authEntries = auth {
    for i in 0..<authEntries.count {
        // Set signature expiration (~50 seconds at 5s/ledger)
        authEntries[i].credentials.addressCredentials?.signatureExpirationLedger =
            latestLedger.sequence + 10

        // Sign the entry
        try authEntries[i].sign(signer: signerKeyPair, network: Network.testnet)
    }

    // Set signed auth on transaction
    transaction.setSorobanAuth(auth: authEntries)
}
```

> **Tip**: Contract IDs must be C-prefixed strkey format.

## Contract Parser

Parse contract bytecode to access specifications, metadata, and environment information without deploying.

### Parse from Bytecode

Parse a local WASM file directly.

```swift
import stellarsdk

let bytecode = try Data(contentsOf: URL(fileURLWithPath: "/path/to/contract.wasm"))
let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: bytecode)

// Contract spec (functions, structs, unions)
for entry in contractInfo.specEntries {
    print(entry)
}

// Contract meta (arbitrary metadata as key-value pairs)
let meta = contractInfo.metaEntries
```

### Parse from Network

Load and parse contract info from a deployed contract.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

// By contract ID
let infoEnum = await server.getContractInfoForContractId(contractId: "CCXYZ...")

// By WASM ID
let infoEnum2 = await server.getContractInfoForWasmId(wasmId: wasmId)

switch infoEnum {
case .success(let contractInfo):
    // Use ContractSpec for type conversions
    let spec = ContractSpec(entries: contractInfo.specEntries)
    let functions = spec.funcs()

    for func_ in functions {
        print("Function: \(func_.name)")
    }
case .rpcFailure(let error):
    print("RPC error: \(error)")
case .parsingFailure(let error):
    print("Parsing error: \(error)")
}
```

## Further Reading

- [SorobanClientTest.swift](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/soroban/SorobanClientTest.swift) -- High-level API tests
- [Soroban Docs](https://developers.stellar.org/docs/smart-contracts) -- Protocol details
- [Soroban Examples](https://github.com/stellar/soroban-examples) -- Official example contracts
- [RPC API Reference](https://developers.stellar.org/docs/data/rpc/api-reference) -- Soroban RPC methods
- [SEP Protocols](sep/README.md) -- Stellar Ecosystem Proposals

---

**Navigation:** [← SDK Usage](sdk-usage.md) | [SEP Protocols →](sep/README.md)
