
## [Stellar SDK for iOS](https://github.com/Soneso/stellar-ios-mac-sdk) 
## Soroban support

The following shows you how to use the iOS SDK to start **experimenting** with Soroban smart contracts. 

**Please note, that both, Soroban itself and the iOS SDK support for Soroban are still under development, so breaking changes may occur.**


### Quick Start

iOS SDK Soroban support allows you to deploy and to invoke smart contracts on Futurenet. Futurenet is a special test network provided by Stellar.

To deploy and/or invoke smart contracts with the iOS SDK use the ```SorobanServer``` class. It connects to a given local or remote Soroban-RPC Server.

Soroban-RPC can be simply described as a “live network gateway for Soroban”. It provides information that the network currently has in its view (i.e. current state). It also has the ability to send a transaction to the network and query the network for the status of previously sent transactions.

You can install your own instance of a Soroban-RPC Server as described [here](https://soroban.stellar.org/docs/tutorials/deploy-to-futurenet). Alternatively, you can use a public remote instance for testing.

The Soroban-RPC API is described in this early stage [design document](https://docs.google.com/document/d/1TZUDgo_3zPz7TiPMMHVW_mtogjLyPL0plvzGMsxSz6A).

#### Initialize SorobanServer 

Provide the url to the endpoint of the Soroban-RPC server to connect to:

```swift
let sorobanServer = SorobanServer(endpoint: "https://futurenet.sorobandev.com/soroban/rpc")
```

Set the experimental flag to true. Otherwise it will not work.

```swift
sorobanServer.acknowledgeExperimental = true
```

#### General node health check
```swift
sorobanServer.getHealth() { (response) -> (Void) in
    switch response {
    case .success(let healthResponse):
        if(HealthStatus.HEALTHY == healthResponse.status) {
           // ...         
        }
    case .failure(let error):
        //...
    }
}
```

#### Get account data

You first need an account on Futurenet. You can fund it like this:

```swift
let accountKeyPair = try KeyPair.generateRandomKeyPair()
let accountId = accountKeyPair.accountId

sdk.accounts.createFutureNetTestAccount(accountId: accountId) { (response) -> (Void) in //...
```

Next you can fetch current information about your Stellar account using the ```SorobanServer```:

```swift
sorobanServer.getAccount(accountId: accountId) { (response) -> (Void) in
    switch response {
    case .success(let accResponse):
        print("Sequence: \(accResponse.sequence)")
    case .failure(let error):
        // ...
    }
}
```

#### Deploy your contract

If you want to create a smart contract for testing, you can easily build one with our [AssemblyScript Soroban SDK](https://github.com/Soneso/as-soroban-sdk) or with the [official Stellar Rust SDK](https://soroban.stellar.org/docs/examples/hello-world). Here you can find [examples](https://github.com/Soneso/as-soroban-examples) to be build with the AssemblyScript SDK.

There are two main steps involved in the process of deploying a contract. First you need to **install** the **contract code** and then to **create** the **contract**.

To **install** the **contract code**, first build a transaction containing the corresponding operation:

```swift
// Create the operation for installing the contract code (*.wasm file content)
let operation = try InvokeHostFunctionOperation.forInstallingContractCode(contractCode: contractCode)

// Build the transaction
let transaction = try Transaction(sourceAccount: account,
                                  operations: [operation], 
                                  memo: Memo.none)
```

Next we need to **simulate** the transaction to obtain the **footprint** needed for final submission:

```swift
// Simulate first to obtain the footprint
sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(let simulateResponse):
        let footprint = simulateResponse.footprint
        // ...
    case .failure(let error):
        // ...
    }
}
```
On success, one can find the **footprint** in the response. The response also contains other information such as information about the fees expected:

```swift
print("cpuInsns: " + simulateResponse.cost.cpuInsns)
print("memBytes: " + simulateResponse.cost.memBytes)
```

Next we need to set the **footprint** to our transaction, **sign** the transaction and send it to the network using the ```SorobanServer```:

```swift
transaction.setFootprint(footprint: footprint)
try transaction.sign(keyPair: accountKeyPair, network: Network.futurenet)

// send transaction to soroban rpc server
sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(let sendResponse):
        let transactionId = sendResponse.transactionId
        let status = sendResponse.status
        // ...
    case .failure(let error):
        // ...
    }
}
```

On success, the response contains the id and status of the transaction:

```swift
print("Transaction Id: " + sendResponse.transactionId)
print("Status: " + sendResponse.status) // pending
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransactionStatus``` request:

```swift
// Fetch transaction status
sorobanServer.getTransactionStatus(transactionHash: transactionId) { (response) -> (Void) in
    switch response {
    case .success(let statusResponse):
        if TransactionStatus.SUCCESS == statusResponse.status {
            let wasmId = statusResponse.wasmId
            // ...
        } else if TransactionStatus.PENDING == statusResponse.status {
            // try again later

        } else if TransactionStatus.ERROR == statusResponse.status {
            let error = stausResponse.error
        }
    case .failure(let error):
        // ...
    }
}
```

If the transaction was successful, the status response contains the ```wasmId``` of the installed contract code. We need the ```wasmId``` in our next step to **create** the contract:

```swift
// Build the operation for creating the contract
let operation = try InvokeHostFunctionOperation.forCreatingContract(wasmId: wasmId)

// Build the transaction for creating the contract
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [operation], 
                                  memo: Memo.none)
```

Next we need to **simulate** the transaction to obtain the **footprint** needed for final submission:

```swift
// Simulate first to obtain the footprint
sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(let simulateResponse):
        let footprint = simulateResponse.footprint
        // ...
    case .failure(let error):
        // ...
    }
}
```
On success, one can find the **footprint** in the response. The response also contains other information such as information about the fees expected:

```swift
print("cpuInsns: " + simulateResponse.cost.cpuInsns)
print("memBytes: " + simulateResponse.cost.memBytes)
```

Next we need to set the **footprint** to our transaction, **sign** the transaction and send it to the network using the ```SorobanServer```:

```swift
transaction.setFootprint(footprint: footprint)
try transaction.sign(keyPair: accountKeyPair, network: Network.futurenet)

// send transaction to soroban rpc server
sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(let sendResponse):
        let transactionId = sendResponse.transactionId
        let status = sendResponse.status
        // ...
    case .failure(let error):
        // ...
    }
}
```

On success, the response contains the id and status of the transaction:

```swift
print("Transaction Id: " + sendResponse.transactionId)
print("Status: " + sendResponse.status) // pending
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransactionStatus``` request:

```swift
// Fetch transaction status
sorobanServer.getTransactionStatus(transactionHash: transactionId) { (response) -> (Void) in
    switch response {
    case .success(let statusResponse):
        if TransactionStatus.SUCCESS == statusResponse.status {
            self.contractId = statusResponse.contractId // yey!
        } 
        // ...
    case .failure(let error):
        // ...
    }
}
```

Success!

#### Get Ledger Entry

The Soroban-RPC server also provides the possibility to request values of ledger entries directly. It will allow you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry. 

For example, to fetch contract wasm byte-code, use the ContractCode ledger entry key:

```swift
let contractCodeKey = footprint.contractCodeLedgerKey

sorobanServer.getLedgerEntry(base64EncodedKey:contractCodeKey) { (response) -> (Void) in // ...
```

#### Invoking a contract

Now, that we successfully deployed our contract, we are going to invoke it using the iOS SDK.

First let's have a look to a simple (hello word) contract created with the [AssemblyScript Soroban SDK](https://github.com/Soneso/as-soroban-sdk). The code and instructions on how to build it, can be found in this [example](https://github.com/Soneso/as-soroban-examples/tree/main/hello_word).

*Hello Word contract AssemblyScript code:*

```typescript
import {SymbolVal, VectorObject, fromSymbolStr} from 'as-soroban-sdk/lib/value';
import {Vec} from 'as-soroban-sdk/lib/vec';

export function hello(to: SymbolVal): VectorObject {

  let vec = new Vec();
  vec.pushFront(fromSymbolStr("Hello"));
  vec.pushBack(to);
  
  return vec.getHostObject();
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

Next we need to **simulate** the transaction to obtain the **footprint** needed for final submission:

```swift
// Simulate first to obtain the footprint
sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(let simulateResponse):
        let footprint = simulateResponse.footprint
        // ...
    case .failure(let error):
        // ...
    }
}
```
On success, one can find the **footprint** in the response. The response also contains other information such as information about the fees expected:

```swift
print("cpuInsns: " + simulateResponse.cost.cpuInsns)
print("memBytes: " + simulateResponse.cost.memBytes)
```

Next we need to set the **footprint** to our transaction, **sign** the transaction and send it to the network using the ```SorobanServer```:

```swift
transaction.setFootprint(footprint: footprint)
try transaction.sign(keyPair: accountKeyPair, network: Network.futurenet)

// send transaction to soroban rpc server
sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(let sendResponse):
        let transactionId = sendResponse.transactionId
        let status = sendResponse.status
        // ...
    case .failure(let error):
        // ...
    }
}
```

On success, the response contains the id and status of the transaction:

```swift
print("Transaction Id: " + sendResponse.transactionId)
print("Status: " + sendResponse.status) // pending
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransactionStatus``` request:

```swift
// Fetch transaction status
sorobanServer.getTransactionStatus(transactionHash: transactionId) { (response) -> (Void) in
    switch response {
    case .success(let statusResponse):
        if TransactionStatus.SUCCESS == statusResponse.status {
            let resultVal = statusResponse.resultValue
            // ...
        } else if TransactionStatus.PENDING == statusResponse.status {
            // try again later

        } else if TransactionStatus.ERROR == statusResponse.status {
            let error = stausResponse.error
        }
    case .failure(let error):
        // ...
    }
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
let operation = try InvokeHostFunctionOperation.forDeploySACWithSourceAccount()
```

2. Deploy SAC with asset:

```swift
let operation = try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: asset)
```

#### Hints and Tips

You can find the working code and more in the [Soroban Test Cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanTest.swift) of the iOS SDK. The Hello Word Contract wasm byte-code file can be found in the soroban [test folder](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/stellarsdk/stellarsdkTests/soroban) folder.

Because Soroban and the iOS SDK support for Soroban are in development, errors may occur. For a better understanding of an error you can enable the ```SorobanServer``` logging:

```swift
sorobanServer.enableLogging = true
```
This will log the responses received from the Soroban-RPC server.

If you find any issues please report them [here](https://github.com/Soneso/stellar-ios-mac-sdk/issues). It will help us to improve the SDK.

