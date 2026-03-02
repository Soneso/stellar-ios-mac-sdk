# Soroban Smart Contracts

## Contract Lifecycle

Four operations manage Soroban contracts: install WASM, introspect spec, deploy instance, invoke methods. The SDK provides both a low-level `InvokeHostFunctionOperation` API and a high-level `SorobanClient` API.

**IMPORTANT:** `InstallRequest` and `DeployRequest` require `enableServerLogging: Bool` with NO default -- you must pass it explicitly (typically `false`). `ClientOptions` defaults to `false`.

## High-Level API: SorobanClient

`SorobanClient` handles the full lifecycle -- install, deploy, invoke -- with automatic simulation, signing, and submission.

### Install Contract WASM

Upload compiled WASM bytecode. Returns a hex-encoded hash identifying the code on-chain.

```swift
import stellarsdk

let sourceKeyPair = try KeyPair(secretSeed: "S_SECRET_KEY_HERE")
let rpcUrl = "https://soroban-testnet.stellar.org"
let wasmData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/contract.wasm"))

let installRequest = InstallRequest(
    rpcUrl: rpcUrl,
    network: Network.testnet,
    sourceAccountKeyPair: sourceKeyPair,
    wasmBytes: wasmData,
    enableServerLogging: false
)

let wasmHash = try await SorobanClient.install(installRequest: installRequest)
print("Installed WASM hash: \(wasmHash)")
```

If the code is already installed, `install` detects this during simulation and returns the existing hash without submitting a transaction. Pass `force: true` to always submit.

---

## Contract Introspection

Parse a contract's spec to discover its functions, types, and events programmatically.

### Loading Contract Info

```swift
import stellarsdk

// From local WASM bytecode (offline)
let wasmData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/contract.wasm"))
let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: wasmData)

// From network (by WASM hash)
let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
let infoEnum = await server.getContractInfoForWasmId(wasmId: wasmHash)
// GetContractInfoEnum cases: .success(response:), .parsingFailure(error:), .rpcFailure(error:)
guard case .success(let info) = infoEnum else { /* handle error */ return }

// From network (by deployed contract ID)
let infoEnum2 = await server.getContractInfoForContractId(contractId: "CCONTRACTID...")
guard case .success(let info2) = infoEnum2 else { /* handle error */ return }
```

### SorobanContractInfo Properties

| Property | Type | Description |
|----------|------|-------------|
| `specEntries` | `[SCSpecEntryXDR]` | All spec entries (raw) |
| `funcs` | `[SCSpecFunctionV0XDR]` | Contract functions |
| `udtStructs` | `[SCSpecUDTStructV0XDR]` | Struct definitions |
| `udtUnions` | `[SCSpecUDTUnionV0XDR]` | Union definitions |
| `udtEnums` | `[SCSpecUDTEnumV0XDR]` | Enum definitions |
| `udtErrorEnums` | `[SCSpecUDTErrorEnumV0XDR]` | Error enum definitions |
| `events` | `[SCSpecEventV0XDR]` | Event definitions |
| `metaEntries` | `[String: String]` | Contract metadata (e.g., `"rsver"`, `"rssdkver"`) |
| `supportedSeps` | `[String]` | SEP numbers from the `"sep"` meta key |

### Listing Functions and Parameters

```swift
for fn in contractInfo.funcs {
    let params = fn.inputs.map { "\($0.name): \(describeType($0.type))" }.joined(separator: ", ")
    let ret = fn.outputs.isEmpty ? "Void" : fn.outputs.map { describeType($0) }.joined(separator: ", ")
    print("fn \(fn.name)(\(params)) -> \(ret)")
}

// Helper to describe a type — use this for printing spec types
func describeType(_ ty: SCSpecTypeDefXDR) -> String {
    // WRONG: case .scSpecTypeU32, .scSpecTypeBool -- no scSpecType prefix exists
    // CORRECT: case .u32, .bool, .address, .string -- short names only
    switch ty {
    case .val: return "Val"
    case .bool: return "Bool"
    case .void: return "Void"
    case .error: return "Error"
    case .u32: return "U32"
    case .i32: return "I32"
    case .u64: return "U64"
    case .i64: return "I64"
    case .timepoint: return "Timepoint"
    case .duration: return "Duration"
    case .u128: return "U128"
    case .i128: return "I128"
    case .u256: return "U256"
    case .i256: return "I256"
    case .bytes: return "Bytes"
    case .string: return "String"
    case .symbol: return "Symbol"
    case .address: return "Address"
    case .muxedAddress: return "MuxedAddress"
    case .option(let o): return "Option<\(describeType(o.valueType))>"
    case .result(let r): return "Result<\(describeType(r.okType)), \(describeType(r.errorType))>"
    case .vec(let v): return "Vec<\(describeType(v.elementType))>"
    case .map(let m): return "Map<\(describeType(m.keyType)), \(describeType(m.valueType))>"
    case .tuple(let t): return "Tuple<\(t.valueTypes.map { describeType($0) }.joined(separator: ", "))>"
    case .bytesN(let b): return "BytesN<\(b.n)>"
    case .udt(let u): return u.name
    }
}
```

### Listing Struct Types

```swift
for s in contractInfo.udtStructs {
    print("Struct: \(s.name)")
    for field in s.fields {
        print("  \(field.name): \(describeType(field.type))")
    }
}
```

### Listing Union Types

```swift
// WRONG: unionCase.name -- SCSpecUDTUnionCaseV0XDR (enum) has no .name
// CORRECT: switch on the case to access the wrapped struct's name
for u in contractInfo.udtUnions {
    print("Union: \(u.name)")
    for c in u.cases {
        switch c {
        case .voidV0(let v): print("  case \(v.name)")
        case .tupleV0(let t): print("  case \(t.name)(\(t.type.map { describeType($0) }.joined(separator: ", ")))")
        }
    }
}
```

### Listing Enum and Error Enum Types

```swift
for e in contractInfo.udtEnums {
    print("Enum: \(e.name)")
    for c in e.cases { print("  \(c.name) = \(c.value)") }
}
for e in contractInfo.udtErrorEnums {
    print("ErrorEnum: \(e.name)")
    for c in e.cases { print("  \(c.name) = \(c.value)") }
}
```

### Listing Events

```swift
// WRONG: event.topics, event.body -- SCSpecEventV0XDR has NO topics/body
// CORRECT: use event.params (array of SCSpecEventParamV0XDR)
for event in contractInfo.events {
    print("Event: \(event.name)")
    for p in event.params {
        print("  \(p.name): \(describeType(p.type))")
    }
}
```

### SCSpecTypeDefXDR Case to SCValXDR Factory Mapping

**Always use the type from introspection** -- do not override based on naming conventions:

```swift
// WRONG: guessing types based on convention — crashes if spec disagrees
// SCValXDR.symbol("MyToken")  // WRONG if spec says String (not Symbol)
// CORRECT: check spec first — spec says String → use SCValXDR.string("MyToken")
```

| SCSpecTypeDefXDR | SCValXDR Factory |
|-----------------|-----------------|
| `.bool` | `SCValXDR.bool(true)` |
| `.void` | `SCValXDR.void` |
| `.u32` | `SCValXDR.u32(UInt32)` |
| `.i32` | `SCValXDR.i32(Int32)` |
| `.u64` | `SCValXDR.u64(UInt64)` |
| `.i64` | `SCValXDR.i64(Int64)` |
| `.u128` | `SCValXDR.u128(UInt128PartsXDR(hi: UInt64, lo: UInt64))` |
| `.i128` | `SCValXDR.i128(Int128PartsXDR(hi: Int64, lo: UInt64))` |
| `.u256` | `SCValXDR.u256(UInt256PartsXDR(...))` |
| `.i256` | `SCValXDR.i256(Int256PartsXDR(...))` |
| `.bytes` | `SCValXDR.bytes(Data)` |
| `.string` | `SCValXDR.string("value")` |
| `.symbol` | `SCValXDR.symbol("name")` |
| `.address` | `SCValXDR.address(try SCAddressXDR(accountId: "G..."))` |
| `.vec(...)` | `SCValXDR.vec([SCValXDR])` |
| `.map(...)` | `SCValXDR.map([SCMapEntryXDR])` |

### ContractSpec Type Conversion

`ContractSpec` auto-converts native Swift values to `SCValXDR` using spec type info:

```swift
let spec = ContractSpec(entries: contractInfo.specEntries)

// Convert full function call args (ordered by parameter declaration)
let args = try spec.funcArgsToXdrSCValues(name: "transfer", args: [
    "from": "GABC...",  // address → SCValXDR.address (automatic)
    "to": "GXYZ...",    // address → SCValXDR.address (automatic)
    "amount": 1000,     // i128 → SCValXDR.i128 (automatic)
])

// Single value conversion
let val = try spec.nativeToXdrSCVal(val: 42, ty: .u32)  // SCValXDR.u32(42)
```

**Native Swift → SCValXDR mapping for `funcArgsToXdrSCValues` / `nativeToXdrSCVal`:**

| Spec type | Swift input | Notes |
|-----------|-------------|-------|
| `.address` | `String` (G... or C...) | Auto-converts to SCAddressXDR |
| `.u32`/`.i32`/`.u64`/`.i64` | `Int` | Negative Int throws for unsigned |
| `.u128`/`.i128`/`.u256`/`.i256` | `Int`, `String`, or `Data` | Use `String` for values > Int.max |
| `.string` | `String` | |
| `.symbol` | `String` | |
| `.bool` | `Bool` | |
| `.bytes` / `.bytesN` | `String` (UTF-8) or `Data` | |
| `.vec(...)` | `[Any]` | Element type from spec |
| `.map(...)` | `[AnyHashable: Any]` | Key/value types from spec |
| `.udt(name)` | dict (struct), `Int` (enum), `NativeUnionVal` (union) | See below |
| Any `SCValXDR` | `SCValXDR` | Returned as-is (passthrough) |

**NativeUnionVal — passing union arguments:**

```swift
// Void union case (tag only)
let noneVal = NativeUnionVal(tag: "none")

// Tuple union case (tag + values matching the tuple case types)
let someVal = NativeUnionVal(tag: "some", values: ["hello", 42])

let unionType = SCSpecTypeDefXDR.udt(SCSpecTypeUDTXDR(name: "MyUnion"))
let xdr = try spec.nativeToXdrSCVal(val: someVal, ty: unionType)
```

---

### Deploy Contract Instance

Create a contract instance from an installed WASM hash. Constructor arguments are supported (protocol 22+).

```swift
import stellarsdk

let sourceKeyPair = try KeyPair(secretSeed: "S_SECRET_KEY_HERE")
let rpcUrl = "https://soroban-testnet.stellar.org"
let wasmHash = "abc123..."  // from install step

// Constructor arguments (if contract has __constructor)
let adminAddress = try SCAddressXDR(accountId: sourceKeyPair.accountId)
let constructorArgs: [SCValXDR] = [
    SCValXDR.address(adminAddress),
    SCValXDR.u32(1000)
]

let deployRequest = DeployRequest(
    rpcUrl: rpcUrl,
    network: Network.testnet,
    sourceAccountKeyPair: sourceKeyPair,
    wasmHash: wasmHash,
    constructorArgs: constructorArgs,
    enableServerLogging: false
)

let client = try await SorobanClient.deploy(deployRequest: deployRequest)
print("Contract deployed at: \(client.contractId)")
print("Available methods: \(client.methodNames)")
```

### Deploy with Spec-Based Constructor Arguments

**Preferred: use `funcArgsToXdrSCValues` when you have the contract spec.** It auto-converts native Swift values to the correct `SCValXDR` types based on the spec — no manual type mapping needed:

```swift
import stellarsdk

let sourceKeyPair = try KeyPair(secretSeed: "S_SECRET_KEY_HERE")
let rpcUrl = "https://soroban-testnet.stellar.org"
let wasmHash = "abc123..."  // from install step

// Load spec from installed WASM
let server = SorobanServer(endpoint: rpcUrl)
let infoEnum = await server.getContractInfoForWasmId(wasmId: wasmHash)
guard case .success(let info) = infoEnum else { throw StellarSDKError.invalidArgument(message: "spec not found") }
let spec = ContractSpec(entries: info.specEntries)

// Auto-convert named args based on __constructor spec types
let constructorArgs = try spec.funcArgsToXdrSCValues(name: "__constructor", args: [
    "admin": sourceKeyPair.accountId,  // String → Address (automatic)
    "decimal": 7,                       // Int → U32 (automatic)
    "name": "MyToken",                  // String → String (automatic)
    "symbol": "MTK",                    // String → Symbol (automatic)
])

let deployRequest = DeployRequest(
    rpcUrl: rpcUrl,
    network: Network.testnet,
    sourceAccountKeyPair: sourceKeyPair,
    wasmHash: wasmHash,
    constructorArgs: constructorArgs,
    enableServerLogging: false
)

let client = try await SorobanClient.deploy(deployRequest: deployRequest)
print("Contract deployed at: \(client.contractId)")
```

```swift
// WRONG: guessing types based on convention — crashes with conversionFailed if spec disagrees
// SCValXDR.symbol("MyToken")  // WRONG if spec says String (not Symbol)

// CORRECT: check spec first — spec says String → use funcArgsToXdrSCValues (auto-converts)
//          or manually use SCValXDR.string("MyToken") if you know the spec type
```

After deployment, you can also get the spec from the client:

```swift
let spec = client.getContractSpec()
let args = try spec.funcArgsToXdrSCValues(name: "transfer", args: [
    "from": sourceKeyPair.accountId,
    "to": "GDEST...",
    "amount": 1000,
])
```

### Invoke Contract Methods

`invokeMethod` automatically distinguishes read-only vs write calls. Read-only calls return simulation results without signing or submitting.

```swift
import stellarsdk

let sourceKeyPair = try KeyPair(secretSeed: "S_SECRET_KEY_HERE")
let rpcUrl = "https://soroban-testnet.stellar.org"
let contractId = "CCONTRACTID..."

let clientOptions = ClientOptions(
    sourceAccountKeyPair: sourceKeyPair,
    contractId: contractId,
    network: Network.testnet,
    rpcUrl: rpcUrl
)
let client = try await SorobanClient.forClientOptions(options: clientOptions)

// Read-only call (no signing, returns simulation result)
let balance = try await client.invokeMethod(
    name: "balance",
    args: [SCValXDR.address(try SCAddressXDR(accountId: sourceKeyPair.accountId))]
)
if let balanceValue = balance.i128String {
    print("Balance: \(balanceValue)")
}

// Write call (auto-signed and submitted)
let toAddress = try SCAddressXDR(accountId: "GDEST...")
let amount = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5_000_000_0))
let transferResult = try await client.invokeMethod(
    name: "transfer",
    args: [
        SCValXDR.address(try SCAddressXDR(accountId: sourceKeyPair.accountId)),
        SCValXDR.address(toAddress),
        amount
    ]
)
print("Transfer result: \(transferResult)")
```

### MethodOptions for Fine-Tuning

```swift
import stellarsdk

let methodOptions = MethodOptions(
    fee: 10000,             // 10000 stroops
    timeoutInSeconds: 60,   // 1 minute validity
    simulate: true,         // auto-simulate (default)
    restore: true           // auto-restore archived entries
)

let result = try await client.invokeMethod(
    name: "transfer",
    args: transferArgs,
    methodOptions: methodOptions
)
```

## Low-Level API: InvokeHostFunctionOperation

For full control over transaction construction, use `InvokeHostFunctionOperation` factory methods directly.

### Upload WASM

```swift
import stellarsdk

let sourceKeyPair = try KeyPair(secretSeed: "S_SECRET_KEY_HERE")
let wasmData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/contract.wasm"))
let rpcUrl = "https://soroban-testnet.stellar.org"
let server = SorobanServer(endpoint: rpcUrl)

// 1. Build the upload operation
let uploadOp = try InvokeHostFunctionOperation.forUploadingContractWasm(
    contractCode: wasmData
)

// 2. Load account for sequence number
let accountEnum = await server.getAccount(accountId: sourceKeyPair.accountId)
guard case .success(let account) = accountEnum else {
    throw StellarSDKError.invalidArgument(message: "Account not found")
}

// 3. Build transaction
let transaction = try Transaction(
    sourceAccount: account,
    operations: [uploadOp],
    memo: nil,
    maxOperationFee: 10000
)

// 4. Simulate to get resource requirements
let simRequest = SimulateTransactionRequest(transaction: transaction)
let simEnum = await server.simulateTransaction(simulateTxRequest: simRequest)
guard case .success(let simResponse) = simEnum else {
    throw StellarSDKError.invalidArgument(message: "Simulation failed")
}

// 5. Apply simulation data
if let txData = simResponse.transactionData {
    transaction.setSorobanTransactionData(data: txData)
}
if let minFee = simResponse.minResourceFee {
    transaction.addResourceFee(resourceFee: minFee)
}
if let auth = simResponse.sorobanAuth {
    transaction.setSorobanAuth(auth: auth)
}

// 6. Sign and submit
try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)
let sendEnum = await server.sendTransaction(transaction: transaction)
guard case .success(let sendResponse) = sendEnum else {
    throw StellarSDKError.invalidArgument(message: "Send failed")
}
print("Transaction ID: \(sendResponse.transactionId)")
```

### Create Contract Instance

```swift
import stellarsdk

let sourceAddress = try SCAddressXDR(accountId: sourceKeyPair.accountId)

// Without constructor
let createOp = try InvokeHostFunctionOperation.forCreatingContract(
    wasmId: wasmHash,
    address: sourceAddress
)

// With constructor (protocol 22+)
let createOpV2 = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
    wasmId: wasmHash,
    address: sourceAddress,
    constructorArguments: [SCValXDR.symbol("init_arg")]
)
```

### Invoke Contract Function

```swift
import stellarsdk

let invokeOp = try InvokeHostFunctionOperation.forInvokingContract(
    contractId: "CCONTRACTID...",
    functionName: "transfer",
    functionArguments: [
        SCValXDR.address(try SCAddressXDR(accountId: "GSOURCE...")),
        SCValXDR.address(try SCAddressXDR(accountId: "GDEST...")),
        SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1_000_000_0))
    ]
)
```

### Deploy Stellar Asset Contract (SAC)

```swift
import stellarsdk

let usdcIssuer = try KeyPair(accountId: "GISSUER...")
let usdcAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USDC", issuer: usdcIssuer)!
let sacOp = try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: usdcAsset)
```

## AssembledTransaction for Mid-Level Control

`AssembledTransaction` wraps a transaction-under-construction with simulation, signing, and multi-auth support. Use `SorobanClient.buildInvokeMethodTx` to get one.

```swift
import stellarsdk

// Build without auto-sending
let tx = try await client.buildInvokeMethodTx(
    name: "transfer",
    args: transferArgs,
    methodOptions: MethodOptions(fee: 10000, simulate: false)
)

// Modify before simulation
tx.raw?.setMemo(memo: Memo.text("payment"))

// Simulate manually
try await tx.simulate()

// Inspect simulation data
let simData = try tx.getSimulationData()
print("Return value: \(simData.returnedValue)")

// Sign and send
let response = try await tx.signAndSend()
if response.status == GetTransactionResponse.STATUS_SUCCESS {
    print("Success! Result: \(response.resultValue ?? SCValXDR.void)")
}
```

## Multi-Party Authorization

Soroban supports multiple signers on a single transaction. Use `needsNonInvokerSigningBy` and `signAuthEntries` to coordinate.

### Atomic Swap Example

```swift
import stellarsdk

let aliceKeyPair = try KeyPair(secretSeed: "S_ALICE_SECRET")
let bobKeyPair = try KeyPair(secretSeed: "S_BOB_SECRET")
let aliceId = aliceKeyPair.accountId
let bobId = bobKeyPair.accountId
let tokenAContractId = "CTOKENA..."
let tokenBContractId = "CTOKENB..."

// Build swap arguments
let args: [SCValXDR] = [
    SCValXDR.address(try SCAddressXDR(accountId: aliceId)),
    SCValXDR.address(try SCAddressXDR(accountId: bobId)),
    SCValXDR.address(try SCAddressXDR(contractId: tokenAContractId)),
    SCValXDR.address(try SCAddressXDR(contractId: tokenBContractId)),
    SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000)),   // amountA
    SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 4500)),   // minBForA
    SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5000)),   // amountB
    SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 950))     // minAForB
]

// Alice builds and simulates (she is the invoker)
let tx = try await swapClient.buildInvokeMethodTx(name: "swap", args: args)

// Check who else needs to sign
let additionalSigners = try tx.needsNonInvokerSigningBy()
// additionalSigners contains Bob's account ID

// Bob signs his auth entries (with his private key)
try await tx.signAuthEntries(signerKeyPair: bobKeyPair)

// Alice signs the transaction envelope and sends
let response = try await tx.signAndSend()
print("Swap status: \(response.status)")
```

### Remote Signing via Callback

When the other signer is on a different server, use the callback pattern:

```swift
import stellarsdk

let bobPublicKeyPair = try KeyPair(accountId: bobId)

try await tx.signAuthEntries(
    signerKeyPair: bobPublicKeyPair,
    authorizeEntryCallback: { entry, network in
        // Encode entry to base64 for transport
        let base64Entry = entry.xdrEncoded!

        // Send to remote server for signing...
        // On the remote server:
        var entryToSign = try SorobanAuthorizationEntryXDR(fromBase64: base64Entry)
        try entryToSign.sign(signer: bobSecretKeyPair, network: network)
        let signedBase64 = entryToSign.xdrEncoded!

        // Return the signed entry
        return try SorobanAuthorizationEntryXDR(fromBase64: signedBase64)
    }
)
```

## Error Handling

```swift
import stellarsdk

do {
    let result = try await client.invokeMethod(name: "transfer", args: transferArgs)
} catch let error as SorobanClientError {
    switch error {
    case .methodNotFound(let msg):
        print("Method does not exist: \(msg)")
    case .invokeFailed(let msg):
        print("Invocation failed: \(msg)")
    case .installFailed(let msg):
        print("Install failed: \(msg)")
    case .deployFailed(let msg):
        print("Deploy failed: \(msg)")
    }
} catch let error as AssembledTransactionError {
    switch error {
    case .simulationFailed(let msg):
        print("Simulation error: \(msg)")
    case .restoreNeeded(let msg):
        print("State needs restore: \(msg)")
    case .multipleSignersRequired(let msg):
        print("Multi-sig needed: \(msg)")
    default:
        print("Transaction error: \(error)")
    }
}
```
