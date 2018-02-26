# Soneso Swift Stellar SDK


The Swift Stellar SDK by Soneso facilitates integration with the Stellar Horizon API server and submission of Stellar transactions from your iOS or macOS app. It has two main uses: querying Horizon and building, signing, and submitting transactions to the Stellar network.


## Querying Horizon

The sdk gives you access to all the endpoints exposed by Horizon.

The StellarSDK class provides access to the SDK services. Each service represents a main request type such as: accounts, effects, operations and so on.

First, the StellarSDK class has to be initialized. The constructor accepts a Horizon URL as a parameter. If the StellarSDK class is initialized without a specific Horizon URL it will connect to the testnet instance of Horizon provided by Stellar.org.

```swift

let sdk = StellarSDK()

sdk.accounts.getAccountDetails(accountId: "GAWE7LGEFNRN3QZL5ILVLYKKKGGVYCXXDCIBUJ3RVOC2ZWW6WLGK76TJ") { (response) -> (Void) in
    switch response {
        case .success(let accountResponse):
            print("Account ID: \(accountResponse.accountId)")
            print("Account Sequence: \(accountResponse.sequenceNumber)")
            for balance in accountResponse.balances {
                if balance.assetType == AssetTypeAsString.NATIVE {
                    print("Account balance: \(balance.balance) XLM")
                } else {
                    print("Account balance: \(balance.balance) \(balance.assetCode!) of issuer: \(balance.assetIssuer!)")
                }
            }
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
 
```
## Building and submitting transactions

Actions that change things in Stellar, like sending payments, changing your account, or making offers to trade various kinds of currencies, are called operations. In order to actually perform an operation, you create a transaction, which is just a group of operations accompanied by some extra information, like what account is making the transaction and a cryptographic signature to verify that the transaction is authentic. You can use the Transaction class to create the requests to send to Horizon. 

Stellar stores and communicates transaction data in a binary format called XDR. Luckily, the Stellar SDK provide tools that take care of all that. Here’s how you might send 10 lumens to another account:

```swift

let sourceAccountKeyPair = try KeyPair(secretSeed:"SA3QF6XW433CBDLUEY5ZAMHYJLJNHBBOPASLJLO4QKH75HRRXZ3UM2YJ")
let destinationAccountKeyPair = try KeyPair(accountId: "GCKECJ5DYFZUX6DMTNJFHO2M4QKTUO5OS5JZ4EIIS7C3VTLIGXNGRTRC")

// First, check to make sure that the destination account exists.
// You could skip this, but if the account does not exist, you will be charged
// the transaction fee when the transaction fails.
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
        case .success(let accountResponse): // account exists
            do {
                // create the payment operation
                let paymentOperation = PaymentOperation(sourceAccount: sourceAccountKeyPair,
                                                        destination: destinationAccountKeyPair,
                                                        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                        amount: 10.0)

                // create the transaction containing the payment operation  
                let transaction = try Transaction(sourceAccount: accountResponse,
                                                  operations: [paymentOperation],
                                                  memo: Memo.none,
                                                  timeBounds:nil)

                // Sign the transaction to prove you are actually the person sending it.
                try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                
                // And finally, send it off to Stellar!
                try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        print("Transaction successfully sent!")
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage("Sample", horizonRequestError:error)
                    }
                }
            } catch {
                ...
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Sample", horizonRequestError:error)

    }
}
```

## Streaming mode

The SDK provides streaming support for all Horizon endpoints that can be used in streaming mode.

It is possible to use the streaming mode for example to listen for new payments as transactions happen in the Stellar network. If called in streaming mode Horizon will start at the earliest known payment unless a cursor is set. In that case it will start from the cursor. You can also set cursor value to "now" to only stream effects created since your request time.

Following example shows how to stream on payments and filter the received payments for the asset named "IOM".

```swift

// specify asset
let issuingAccountKeyPair = try KeyPair(accountId: "GCXIZK3YMSKES64ATQWMQN5CX73EWHRHUSEZXIMHP5GYHXL5LNGCOGXU")
let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)

// listen for payments
sdk.payments.stream(for: .paymentsForAccount(account: accountId, cursor: "now")).onReceive { (response) -> (Void) in
    switch response {
    case .open:
        break
    case .response(let id, let operationResponse):
        if let paymentResponse = operationResponse as? PaymentOperationResponse {
            if paymentResponse.assetCode == IOM?.code {
                print("Payment of \(paymentResponse.amount) IOM from \(paymentResponse.sourceAccount) received -  id \(id)" )
            }
        }
    case .error(let error):
        ...
    }
}
```
