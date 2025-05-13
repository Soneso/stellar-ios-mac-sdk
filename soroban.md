
## [Stellar SDK for iOS](https://github.com/Soneso/stellar-ios-mac-sdk) 
## Soroban support

The following shows you how to use the iOS SDK to interact with Soroban. 

### Quick Start

iOS SDK Soroban support allows you to deploy and to invoke smart contracts.

To deploy and/or invoke smart contracts with the iOS SDK use the `SorobanServer` class. It connects to a given local or remote Soroban-RPC Server.

Soroban-RPC can be simply described as a “live network gateway for Soroban”. It provides information that the network currently has in its view (i.e. current state). It also has the ability to send a transaction to the network and query the network for the status of previously sent transactions.

You can install your own instance of a Soroban-RPC Server as described [here](https://soroban.stellar.org/docs/tutorials/deploy-to-futurenet). Alternatively, you can use a public remote instance for testing. The Soroban-RPC API is described [here](https://developers.stellar.org/docs/data/rpc/api-reference).

The easiest way to interact with Soroban smart contract is by using the class `SorobanClient`. It helps you to install and deploy smart contracts and to invoke their methods. You can find a more detailed description below. 

The Soroban-RPC API is described [here](https://soroban.stellar.org/api/methods).

## SorobanServer

Provide the url to the endpoint of the Soroban-RPC server to connect to:

```swift
let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
```

Now you can use your `SorobanServer` instance to access the [API endpoints](https://developers.stellar.org/docs/data/rpc/api-reference/methods) provided by the Soroban RPC server.

### Examples 

General node health check:

```swift
let responseEnum = await sorobanServer.getHealth()
switch responseEnum {
case .success(let healthResponse):
    if(HealthStatus.HEALTHY == healthResponse.status) {
        // ...         
    }
case .failure(let error):
    //...
}
```

Fetch current information about your account:

```swift
let responseEnum = await sorobanServer.getAccount(accountId: "G...")
switch responseEnum {
    case .success(let account):
        print("Sequence: \(account.sequenceNumber)")
    case .failure(let error):
        //...
}
```

Fetch the latest ledger sequence:

```swift
let responseEnum = await sorobanServer.getLatestLedger()
switch responseEnum {
    case .success(let response):
        print("latest ledger sequence: \(response.sequence)")
    case .failure(let error):
        // ..
}
```

## SorobanClient

The easiest way to interact with Soroban smart contracts is by using the class `SorobanClient`. It helps you to install and deploy smart contracts and to invoke their methods.

If you want to create a smart contract for testing, you can find the official examples [here](https://github.com/stellar/soroban-examples).
You can also create smart contracts with our AssemblyScript Soroban SDK. Examples can be found [here](https://github.com/Soneso/as-soroban-examples).

The following chapters show examples of interaction with Soroban smart contracts. Please also take a look at the [`SorobanClientTest`](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanClientTest.swift), where you can try out this functionality right away.

### Install a contract

As soon as you have the wasm byte code of a compiled contract you can install it as follows:

```swift
guard let contractCode = FileManager.default.contents(atPath: path) else {
            // File not found ...
}
        
let installRequest = InstallRequest(rpcUrl: "https://...",
                                    network: Network.testnet,
                                    sourceAccountKeyPair: sourceAccountKeyPair,
                                    wasmBytes: contractCode)

let wasmHash = try await SorobanClient.install(installRequest: installRequest)
```

It will return the wasm hash of the installed contract that you can now use to deploy the contract.

### Deploy a contract

As soon as you have the wasm hash of an installed contract, you can deploy an instance of the contract.

Deployment works as follows:

```swift
let deployRequest = DeployRequest(rpcUrl: "https://...",
                                  network: Network.testnet,
                                  sourceAccountKeyPair: sourceAccountKeyPair,
                                  wasmHash: wasmHash)
        
let client = try await SorobanClient.deploy(deployRequest: deployRequest)
```

Now you can use the new instance to interact with the contract.

### Invoking a method

As soon as a new instance is created, you can invoke the contract's methods:

```swift
let result = try await client.invokeMethod(name: "hello", args: [SCValXDR.symbol("friend")])
```

It will return the result of the method invocation as a `SCValXDR` object.

For more advanced usecases where you need to manipulate the transaction (e.g. add memo, additional signers, etc.) you can
obtain the `AssembledTransaction` before sending it to the Soroban RPC Server
as follows:

```swift
let tx = try await client.buildInvokeMethodTx(name: methodName, args: args)
```

In the following chapter we will discuss how you can use the obtained `AssembledTransaction`.

## AssembledTransaction

The main workhorse of `SorobanClient`. This class is used to wrap a
transaction-under-construction and provide high-level interfaces to the most
common workflows, while still providing access to low-level stellar-sdk
transaction manipulation.

Most of the time, you will not construct an `AssembledTransaction` directly,
but instead receive one as the return value of a `SorobanClient.buildInvokeMethodTx` method.

Let's look at examples of how to use `AssembledTransaction` for a variety of
 use-cases:

### 1. Simple read call

Since these only require simulation, you can get the `result` of the call
right after constructing your `AssembledTransaction`:

```swift
let clientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair,
                                  contractId: "C123…",
                                  network: Network.testnet,
                                  rpcUrl: "https://…")

let txOptions = AssembledTransactionOptions(clientOptions: clientOptions,
                                            methodOptions: MethodOptions(),
                                            method: "myReadMethod",
                                            arguments: args)
let tx = try await AssembledTransaction.build(options: txOptions)
let result = try tx.getSimulationData().returnedValue
```

While that looks pretty complicated, most of the time you will use this in
conjunction with `SorobanClient`, which simplifies it to:

```swift
let result = try await client.invokeMethod(name: "myReadMethod", args: args)
```

#### 2. Simple write call

For write calls that will be simulated and then sent to the network without
further manipulation, only one more step is needed:

```swift
let tx = try await AssembledTransaction.build(options: txOptions)
let response = try await tx.signAndSend()
if response.status == GetTransactionResponse.STATUS_SUCCESS {
   let result = response.resultValue
}
```

If you are using it in conjunction with `SorobanClient`:

```swift
let result = try await client.invokeMethod(name: "myWriteMethod", args: args)
```

#### 3. More fine-grained control over transaction construction

If you need more control over the transaction before simulating it, you can
set various `MethodOptions` when constructing your
`AssembledTransaction`. With a `SorobanClient`,  this can be passed as an
argument when calling `invokeMethod` or `buildInvokeMethodTx` :

```swift
let methodOptions = MethodOptions(fee: 10000,
                                  timeoutInSeconds: 20,
                                  simulate: false)

let tx = try await client.buildInvokeMethodTx(name: "myWriteMethod",
                                             args: args,
                                             methodOptions: methodOptions)
```

Since we've skipped simulation, we can now edit the `raw` transaction builder and
then manually call `simulate`:

```swift
tx.raw?.setMemo(memo: Memo.text("Hello"))
try await tx.simulate()

```

If you need to inspect the simulation later, you can access it with
`let data = try tx.getSimulationData()`

#### 4. Multi-auth workflows

Soroban, and Stellar in general, allows multiple parties to sign a
transaction.

Let's consider an Atomic Swap contract. Alice wants to give some of her Token
A tokens to Bob for some of his Token B tokens.

```swift
let swapMethodName = "swap"
let amountA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
let minBForA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 4500))

let amountB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5000))
let minAForB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 950))
let args:[SCValXDR] = [try SCValXDR.address(SCAddressXDR(accountId: aliceId)),
                       try SCValXDR.address(SCAddressXDR(accountId: bobId)),
                       try SCValXDR.address(SCAddressXDR(contractId: tokenAContractId)),
                       try SCValXDR.address(SCAddressXDR(contractId: tokenBContractId)),
                       amountA,
                       minBForA,
                       amountB,
                       minAForB]

```

Let's say Alice is also going to be the one signing the final transaction
envelope, meaning she is the invoker. So your app, she
simulates the `swap` call:

```swift
let tx = try await atomicSwapClient.buildInvokeMethodTx(name: swapMethodName,
                                                         args: args)
```

But your app can't `signAndSend` this right away, because Bob needs to sign
it first. You can check this:

```swift
let whoElseNeedsToSign = try tx.needsNonInvokerSigningBy()
```

You can verify that `whoElseNeedsToSign` is an array of length `1`,
containing only Bob's public key.

If you have Bob's secret key, you can sign it right away with:

```swift
let bobsKeyPair = try KeyPair(secretSeed: "S...")
try await tx.signAuthEntries(signerKeyPair: bobsKeyPair)
```
But if you don't have Bob's private key, and e.g. need to send it to another server for signing,
you can provide a callback function for signing the auth entry:

```swift
let bobPublicKeyKeypair = try KeyPair(accountId: bobsAccountId)
try await tx.signAuthEntries(signerKeyPair: bobPublicKeyKeypair, authorizeEntryCallback: { (entry, network) async throws in

       // You can send it to some other server for signing by encoding it as a base64xdr string
       let base64Entry = entry.xdrEncoded!
       
       // send for signing ...
       // and on the other server you can decode it:
       var entryToSign = try SorobanAuthorizationEntryXDR.init(fromBase64: base64Entry)
       
       // sign it
       try entryToSign.sign(signer: bobsSecretKeyPair, network: network)
       
       // encode as a base64xdr string and send it back
       let signedBase64Entry = entryToSign.xdrEncoded!

       // here you can now decode it and return it
       return try SorobanAuthorizationEntryXDR.init(fromBase64: signedBase64Entry)
})
```

To see an even more complicated example, where Alice swaps with Bob but the
transaction is invoked by yet another party, check out in the `SorobanClientTest.atomicSwapTest()`

## Interacting with Soroban without using the SorobanClient

The `SorobanClient` was introduced as a usability improvement, that allows you to easily 
install and deploy smart contracts and to invoke their methods. It uses the underlying SDK functionality to facilitate this. If you want to learn more about the underlying functionality or need it, the following chapters are for you.

#### Deploy your contract

If you want to create a smart contract for testing, you can find the official examples [here](https://github.com/stellar/soroban-examples).
You can also create smart contracts with our AssemblyScript Soroban SDK. Examples can be found [here](https://github.com/Soneso/as-soroban-examples).

There are two main steps involved in the process of deploying a contract. First you need to **upload** the **contract code** and then to **create** the **contract**.

To **upload** the **contract code**, first build a transaction containing the corresponding operation:

```swift
// Create the operation for uploading the contract code (*.wasm file content)
let operation = try InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: contractCode)

// Build the transaction
let transaction = try Transaction(sourceAccount: account,
                                  operations: [operation], 
                                  memo: Memo.none)
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and the **resource fee** needed for final submission:

```swift
// Simulate first to obtain the transaction data and ressource fee
let simulateTxRequest = SimulateTransactionRequest(transaction: transaction);
let responseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
switch respresponseEnumonse {
case .success(let simulateResponse):
    let transactionData = simulateResponse.transactionData
    let resourceFee = simulateResponse.minResourceFee
    // ...
case .failure(let error):
    // ...
}
```

On success, one can find the **soroban transaction data** and the **minimum resource fee** in the response.

Next we need to set the **soroban transaction data** to our transaction, add the **resource fee** and  **sign** the transaction before sending it to the network using the ```SorobanServer```:


```swift
transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
try transaction.sign(keyPair: accountKeyPair, network: Network.testnet)

// send transaction to soroban rpc server
let responseEnum = await sorobanServer.sendTransaction(transaction: transaction)
switch responseEnum {
case .success(let sendResponse):
    let transactionId = sendResponse.transactionId
    let status = sendResponse.status
    // ...
case .failure(let error):
    // ...
}
```

On success, the response contains the id and status of the transaction:

```swift
print("Transaction Id: " + sendResponse.transactionId)
print("Status: " + sendResponse.status) // pending
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```swift
// Fetch transaction status
let responseEnum = await sorobanServer.getTransaction(transactionHash: transactionId)
switch responseEnum {
case .success(let statusResponse):
    if TransactionStatus.SUCCESS == statusResponse.status {
        let wasmId = statusResponse.wasmId
        // ...
    } else if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
        // try again later

    } else if GetTransactionResponse.ERROR == statusResponse.status {
        // ...
    }
case .failure(let error):
    // ...
}
```

If the transaction was successful, the status response contains the ```wasmId``` of the installed contract code. We need the ```wasmId``` in our next step to **create** the contract:

```swift
// Build the operation for creating the contract
let operation = try InvokeHostFunctionOperation.forCreatingContract(wasmId: wasmId, 
        address: SCAddressXDR(accountId: accountId))

// Build the transaction for creating the contract
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [operation], 
                                  memo: Memo.none)
```

Next we need to **simulate** the transaction to obtain the resources needed for final submission:

```swift
// Simulate first to obtain the transaction data, fee and soroban auth
let simulateTxRequest = SimulateTransactionRequest(transaction: transaction);
let responseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
switch responseEnum {
case .success(let simulateResponse):
    let transactionData = simulateResponse.transactionData
    let resourceFee = simulateResponse.minResourceFee
    let sorobanAuth = simulateResponse.sorobanAuth
    // ...
case .failure(let error):
    // ...
}
```
On success, one can find the **soroban transaction data**, the **minimum resource fee** and the **soroban auth entries** in the response.

Next we need to set the resources to our transaction and  **sign** the transaction before sending it to the network using the ```SorobanServer```:

```swift
transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth)
transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
try transaction.sign(keyPair: accountKeyPair, network: Network.testnet)

// send transaction to soroban rpc server
let responseEnum = await sorobanServer.sendTransaction(transaction: transaction) 
switch responseEnum {
case .success(let sendResponse):
    let transactionId = sendResponse.transactionId
    let status = sendResponse.status
    // ...
case .failure(let error):
    // ...
}
```

On success, the response contains the id and status of the transaction:

```swift
print("Transaction Id: " + sendResponse.transactionId)
print("Status: " + sendResponse.status) // pending
```

As you can see, we use the ```wasmId``` to create the operation and the transaction for creating the contract. After simulating, we obtain the transaction data and resource fee for the transaction. Next, sign the transaction and send it to the Soroban-RPC Server. The transaction status will be "pending", so we need to wait a bit and poll for the current status:

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```swift
// Fetch transaction status
let responseEnum = await sorobanServer.getTransaction(transactionHash: txId) 
switch responseEnum {
case .success(let txResponse):
    if GetTransactionResponse.SUCCESS == txResponse.status {
        self.contractId = txResponse.createdContractId // yey!
    } 
    // ...
case .failure(let error):
    // ...
}
```

Success!

With the introduction of Protocol 22, contracts with constructor can also be created. The `InvokeHostFunctionOperation.forCreatingContractWithConstructor` function is used to create the operation.

#### Get Ledger Entries

The Soroban-RPC server also provides the possibility to request values of ledger entries directly. It will allow you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry. 

For example, to fetch contract wasm byte-code, use the ContractCode ledger entry key:

```swift
let contractCodeKey = LedgerKeyContractCodeXDR(wasmId: wasmId, bodyType: ContractEntryBodyType.dataEntry)
let ledgerKey = LedgerKeyXDR.contractCode(contractCodeKey)

sorobanServer.getLedgerEntries(base64EncodedKeys:[ledgerKey.xdrEncoded]) { (response) -> (Void) in // ...
```
If you already have a contractId you can load the code as follows:

```swift
sorobanServer.getContractCodeForContractId(contractId: contractId) { (response) -> (Void) in // ...
```

If you have a wasmId:

```swift
sorobanServer.getContractCodeForWasmId(wasmId: wasmId) { (response) -> (Void) in // ...
```

Requesting the latest ledger:

```swift
sorobanServer.getLatestLedger() { (response) -> (Void) in // ...
```


#### Invoking a contract

Now, that we successfully deployed our contract, we are going to invoke it using the iOS SDK.

First let's have a look to a simple (hello word) contract created with the Rust Soroban SDK. The code and instructions on how to build it, can be found in the official [soroban docs](https://soroban.stellar.org/docs/getting-started/hello-world).
*Hello Word contract code:*

```rust
impl HelloContract {
    pub fn hello(env: Env, to: Symbol) -> Vec<Symbol> {
        vec![&env, symbol_short!("Hello"), to]
    }
}
```

It's only function is called ```hello``` and it accepts a ```symbol``` as an argument. It returns a ```vector``` containing two symbols.

To invoke the contract with the iOS SDK, we first need to build the corresponding operation and transaction:


```swift
// Name of the function to be invoked
let functionName = "hello"

// Prepare the argument (Symbol)
let arg = SCValXDR.symbol("friend")

// Prepare the "invoke" operation
let operation = try InvokeHostFunctionOperation.forInvokingContract(contractId: contractId,
                                                                    functionName: functionName,
                                                                    functionArguments: [arg])

// Build the transaction
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [operation], 
                                  memo: Memo.none)
```

Next we need to **simulate** the transaction to obtain the **transaction data** and **resource fee** needed for final submission:

```swift
// Simulate first to obtain the footprint
let simulateTxRequest = SimulateTransactionRequest(transaction: transaction);
let responseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
switch responseEnum {
case .success(let simulateResponse):
    let transactionData = simulateResponse.transactionData
    let resourceFee = simulateResponse.minResourceFee
    // ...
case .failure(let error):
    // ...
}
```
On success, one can find the **transaction data** and the **resource fee** in the response. 

Next we need to set the **soroban transaction data** to our transaction, to add the **resource fee** and **sign** the transaction to send it to the network using the ```SorobanServer```:

```swift
transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
try transaction.sign(keyPair: accountKeyPair, network: Network.testnet)

// send transaction to soroban rpc server
let responseEnum = await sorobanServer.sendTransaction(transaction: transaction)
switch responseEnum {
case .success(let sendResponse):
    let transactionId = sendResponse.transactionId
    let status = sendResponse.status
    // ...
case .failure(let error):
    // ...
}
```

On success, the response contains the id and status of the transaction:

```swift
print("Transaction Id: " + sendResponse.transactionId)
print("Status: " + sendResponse.status) // pending
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```swift
// Fetch transaction status
let responseEnum = await sorobanServer.getTransaction(transactionHash: transactionId)
switch responseEnum {
case .success(let txResponse):
    if TransactionStatus.SUCCESS == txResponse.status {
        let resultVal = txResponse.resultValue
        // ...
    } else if TransactionStatus.PENDING == txResponse.status {
        // try again later

    } else if TransactionStatus.ERROR == txResponse.status {
        let error = stausResponse.error
    }
case .failure(let error):
    // ...
}
```

If the transaction was successful, the status response contains the result:

```swift
let resultVal = statusResponse.resultValue

// Extract the Vector & Print result
if let vec = resultValue?.vec, vec.count > 1 {
    print("[" + vec[0].symbol! + "," + vec[1].symbol! + "]")
    // [Hello, friend]
}
```

Success!

#### Deploying Stellar Asset Contract (SAC)

The iOS SDK also provides support for deploying the build-in [Stellar Asset Contract](https://soroban.stellar.org/docs/built-in-contracts/stellar-asset-contract) (SAC). The following operations are available for this purpose:

1. Deploy SAC with source account:

```swift
let operation = try InvokeHostFunctionOperation.forDeploySACWithSourceAccount(address: SCAddressXDR(accountId: accountId))
```

2. Deploy SAC with asset:

```swift
let operation = try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: asset)
```

#### Soroban Authorization

The iOS SDK provides support for the [Soroban Authorization Framework](https://soroban.stellar.org/docs/fundamentals-and-concepts/authorization).

To provide authorization you can add an array of `SorobanAuthorizationEntry` to the transaction before sending it.

```swift
transaction.setSorobanAuth(auth: myArray)
```

The easiest way to do this is to use the auth data generated by the simulation.

```swift
transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth)
```
But you can also compose the authorization entries by yourself.


If the entries need to be signed you can do it as follows:

```swift
// sign auth and set it to the transaction
var sorobanAuth = simulateResponse.sorobanAuth!
for i in sorobanAuth.indices {
    try sorobanAuth[i].sign(signer: invokerKeyPair,
                        network: Network.testnet,
                        signatureExpirationLedger: latestLedger + 10)
}
transaction.setSorobanAuth(auth: sorobanAuth)             
```
To load the latest ledger sequence you can use:

```swift
self.sorobanServer.getLatestLedger() { (response) -> (Void) in // ...
```

You can find multiple examples in the [Soroban Auth Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanAuthTest.swift) and in the [Atomic Swap Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanAtomicSwapTest.swift) of the SDK.

#### Get Events

The Soroban-RPC server provides the possibility to request contract events. 

You can use the iOS SDK to request events like this:

```swift
let topicFilter = TopicFilter(segmentMatchers:["*", SCValXDR.symbol("increment").xdrEncoded!])
let eventFilter = EventFilter(type:"contract", contractIds: [contractId], topics: [topicFilter])

let responseEnum = await sorobanServer.getEvents(startLedger: ledger, eventFilters: [eventFilter])           
switch responseEnum {
case .success(let eventsResponse):
    // ...
case .failure(let error):
    // ...
}
```

contractId must currently start with "C...". If you only have the hex value you can encode it with: `contractId.encodeContractIdHex()`

Find the complete code in the [Soroban Events Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanEventsTest.swift).


#### Hints and Tips

You can find the working code and more in the [SorobanClient Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanClientTest.swift), [Soroban Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban), the [Soroban Auth Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanAuthTest.swift) and in the [Atomic Swap Test](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanAtomicSwapTest.swift) of the iOS SDK. The wasm byte-code files can also be found there.

For a better understanding of an error you can enable the ```SorobanServer``` logging:

```swift
sorobanServer.enableLogging = true
```
This will log the responses received from the Soroban-RPC server.

If you find any issues please report them [here](https://github.com/Soneso/stellar-ios-mac-sdk/issues). It will help us to improve the SDK.

### Soroban contract parser

The soroban contract parser allows you to access the contract info stored in the contract bytecode.
You can access the environment metadata, contract spec and contract meta.

The environment metadata holds the interface version that should match the version of the soroban environment host functions supported.

The contract spec contains a `SCSpecEntryXDR` for every function, struct, and union exported by the contract.

In the contract meta, contracts may store any metadata in the entries that can be used by applications and tooling off-network.

You can access the parser directly if you have the contract bytecode:

```swift
let byteCode = FileManager.default.contents(atPath: 'path to .wasm file')
let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: byteCode)
```

Or you can use `SorobanServer` methods to load the contract code form the network and parse it.

By contract id:
```swift
let responseEnum = await sorobanServer.getContractInfoForContractId(contractId: contractId)
switch responseEnum {
case .success(let contractInfo):
    // ...
case .rpcFailure(let error):
    // ...
case .parsingFailure (let error):
    // ...
}
```

By wasm id:
```swift
let responseEnum = await sorobanServer.getContractInfoForWasmId(wasmId: wasmId)
switch responseEnum {
case .success(let contractInfo):
    // ...
case .rpcFailure(let error):
    // ...
case .parsingFailure (let error):
    // ...
}
```

The parser returns a `SorobanContractInfo` object containing the parsed data.
In [SorobanParserTest.swift](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanParserTest.swift) you can find a detailed example of how you can access the parsed data.
