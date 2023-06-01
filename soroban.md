
## [Stellar SDK for iOS](https://github.com/Soneso/stellar-ios-mac-sdk) 
## Soroban support

The following shows you how to use the iOS SDK to start **experimenting** with Soroban smart contracts. 

**Please note, that both, Soroban itself and the iOS SDK support for Soroban are still under development, so breaking changes may occur.**


### Quick Start

iOS SDK Soroban support allows you to deploy and to invoke smart contracts on Futurenet. Futurenet is a special test network provided by Stellar.

To deploy and/or invoke smart contracts with the iOS SDK use the ```SorobanServer``` class. It connects to a given local or remote Soroban-RPC Server.

Soroban-RPC can be simply described as a “live network gateway for Soroban”. It provides information that the network currently has in its view (i.e. current state). It also has the ability to send a transaction to the network and query the network for the status of previously sent transactions.

You can install your own instance of a Soroban-RPC Server as described [here](https://soroban.stellar.org/docs/tutorials/deploy-to-futurenet). Alternatively, you can use a public remote instance for testing.

The Soroban-RPC API is described [here](https://soroban.stellar.org/api/).

#### Initialize SorobanServer 

Provide the url to the endpoint of the Soroban-RPC server to connect to:

```swift
let sorobanServer = SorobanServer(endpoint: "https://rpc-futurenet.stellar.org:443")
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

Next you can fetch current information about your Stellar account using the ```iOS SDK```:

```swift
sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
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

On success, one can find the **soroban transaction data** and the **minimum resource fee** in the response.

Next we need to set the **soroban transaction data** to our transaction, add the **resource fee** and  **sign** the transaction before sending it to the network using the ```SorobanServer```:


```swift
transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
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

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```swift
// Fetch transaction status
sorobanServer.getTransaction(transactionHash: transactionId) { (response) -> (Void) in
    switch response {
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
On success, one can find the **soroban transaction data** and the **minimum resource fee** in the response.

Next we need to set the **soroban transaction data** to our transaction, add the **resource fee** and  **sign** the transaction before sending it to the network using the ```SorobanServer```:

```swift
transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
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

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```swift
// Fetch transaction status
sorobanServer.getTransaction(transactionHash: transactionId) { (response) -> (Void) in
    switch response {
    case .success(let statusResponse):
        if GetTransactionResponse.SUCCESS == statusResponse.status {
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
let contractCodeKey = simulateResponse.footprint.contractCodeLedgerKey

sorobanServer.getLedgerEntry(base64EncodedKey:contractCodeKey) { (response) -> (Void) in // ...
```

#### Invoking a contract

Now, that we successfully deployed our contract, we are going to invoke it using the iOS SDK.

First let's have a look to a simple (hello word) contract created with the [AssemblyScript Soroban SDK](https://github.com/Soneso/as-soroban-sdk). The code and instructions on how to build it, can be found in this [example](https://github.com/Soneso/as-soroban-examples/tree/main/hello_word).

*Hello Word contract AssemblyScript code:*

```typescript
import {Symbol, VecObject, fromSmallSymbolStr} from 'as-soroban-sdk/lib/value';
import {Vec} from 'as-soroban-sdk/lib/vec';

export function hello(to: Symbol): VecObject {

    let vec = new Vec();
    vec.pushFront(fromSmallSymbolStr("Hello"));
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

Next we need to **simulate** the transaction to obtain the **transaction data** and **resource fee** needed for final submission:

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
On success, one can find the **transaction data** and the **resource fee** in the response. 

Next we need to set the **soroban transaction data** to our transaction, to add the **resource fee** and **sign** the transaction to send it to the network using the ```SorobanServer```:

```swift
transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
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

#### Soroban Authorization

The iOS SDK provides support for the [Soroban Authorization Framework](https://soroban.stellar.org/docs/learn/authorization).

For this purpose, it offers the `Address`, `AuthorizedInvocation` and `ContractAuth` classes as well as helper functions like `getNonce(...)`.

Here is a code fragment showing how they can be used:

*Get nonce:* 

```swift
sorobanServer.getNonce(accountId:accountId, contractId:contractId) { (response) -> (Void) in
    switch response {
        case .success(let nonce):
            self.nonce = nonce
        case .failure(let error):
            //...
    }
}
```

*Authorization:*

```swift
let invokerAddress = Address.accountId(invokerId)

let functionName = "auth"
let args = [try SCValXDR(address:invokerAddress), SCValXDR.u32(3)]

let rootInvocation = AuthorizedInvocation(contractId: contractId, functionName: functionName, args: args)

let contractAuth = ContractAuth(address: invokerAddress, nonce: nonce, rootInvocation: rootInvocation)

try contractAuth.sign(signer: invokerKeyPair, network: Network.futurenet)

let invokeOperation = try InvokeHostFunctionOperation.forInvokingContract(contractId: contractId, 
                                                                          functionName: functionName,
                                                                          functionArguments: args, 
                                                                          auth: [contractAuth])
                
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [invokeOperation], 
                                  memo: Memo.none)
                
sorobanServer.simulateTransaction(transaction: transaction) { (response) -> //...
```

The example above invokes this assembly script [auth contract](https://github.com/Soneso/as-soroban-examples/tree/main/auth#code). In this example the submitter of the transaction is not the same as the "invoker" of the contract function. 

One can find another example in the [Soroban Auth Test Cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanAuthTest.swift) of the SDK where the submitter and invoker are the same, as well as an example where contract auth from the simulation response is used.


An advanced auth example can be found in the [iOS atomic swap](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanAtomicSwapTest.swift) test.

Hint: Resource values and fees have been added in the new soroban preview 9 version. The calculation of the minimum resource values and fee by the simulation (preflight) is not always accurate, because it does not consider signatures. This may result in a failing transaction because of insufficient resources. In this case one can experiment and increase the resources values within the soroban transaction data before signing and submitting the transaction. E.g.:

```swift
var transactionData = simulateResponse.transactionData!
transactionData.resources.instructions += transactionData.resources.instructions / 4
let resourceFee = simulateResponse.minResourceFee! + 3000;

transaction.setSorobanTransactionData(data: transactionData)
transaction.addResourceFee(resourceFee: resourceFee)
try transaction.sign(keyPair: accountKeyPair, network: Network.futurenet)
```
See also: https://discord.com/channels/897514728459468821/1112853306881081354

#### Get Events

The Soroban-RPC server provides the possibility to request contract events. 

You can use the iOS SDK to request events like this:

```swift
let eventFilter = EventFilter(type:"contract", contractIds: [contractId])

sorobanServer.getEvents(startLedger: startLedger, endLedger: endLedger, eventFilters: [eventFilter]) { (response) -> (Void) in
    switch response {
        case .success(let eventsResponse):
            // ...
        case .failure(let error):
            // ...
    }
}
```
Find the complete example code [here](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban/SorobanEventsTest.swift#L283).


#### Hints and Tips

You can find the working code and more in the [Soroban Test Cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/soroban) of the iOS SDK. The wasm byte-code files can also be found there.

Because Soroban and the iOS SDK support for Soroban are in development, errors may occur. For a better understanding of an error you can enable the ```SorobanServer``` logging:

```swift
sorobanServer.enableLogging = true
```
This will log the responses received from the Soroban-RPC server.

If you find any issues please report them [here](https://github.com/Soneso/stellar-ios-mac-sdk/issues). It will help us to improve the SDK.

