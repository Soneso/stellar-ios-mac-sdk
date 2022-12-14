# Soneso iOS Stellar SDK Overview


The iOS Stellar SDK by Soneso facilitates integration with the Stellar Horizon API server and submission of Stellar transactions from your iOS or macOS app. 

It has three main uses: 
- Querying the Stellar Blockchain by using Horizon 
- Building, signing, and submitting transactions to the Stellar Network.
- Interacting with the Stellar Ecosystem (e.g. Anchors), by using [Stellar Ecosystem Proposals](https://github.com/stellar/stellar-protocol/tree/master/ecosystem).

## Querying Horizon

The SDK gives you access to all the [endpoints exposed by Horizon](https://developers.stellar.org/api). This will allow you to query the data from the Stellar Blockchain.

**Initializing the SDK**

First, the [StellarSDK](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/StellarSDK.swift) class has to be initialized. The constructor accepts a Horizon URL as a parameter. If the StellarSDK class is initialized without a specific Horizon URL it will connect to the testnet instance of Horizon provided by Stellar.org.

```swift

let sdk = StellarSDK()
```

If you want to connect to the main public net, you can use the following horzion url: https://horizon.stellar.org:

```swift

let sdk = StellarSDK(withHorizonUrl: "https://horizon.stellar.org")
```

**Using the SDK services**

The [StellarSDK](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/StellarSDK.swift) class provides access to the SDK services. Each service represents a main request type such as: accounts, effects, transactions and so on.

For example, to query the details of an existing account you can use the `accounts` service implemented in the [AccountService](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/AccountService.swift) class of the SDK. It provides the function ```getAccountDetails``` that can be used as in following example:

```swift

let sdk = StellarSDK() // connect to testnet

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

As you can see, you first need an account id to be able to query the account details. The account id provided in the example above may not represent an existing account at the time you are trying to test this. It is so, because the testnet is reset every 3 month. We recommend you to generate your own account first, by using a very helpful tool named [Stellar Laboratory](https://laboratory.stellar.org/#account-creator?network=test).

To do so, first generate a new keypair, which represents the public key/account id and secret seed of a new account to be created (do not forget to save them somewhere). Next, fund the account on the testnet by using the "freindbot" provided by Stellar Laboratory.

Now that you have your new account on the test network, you can query it's details. First, give it a try in Stellar Laboratory. Navigate to `Explore Endpoints - Accounts - Single Account`, paste your new account id there and request the details. In the ```json``` response that you receive, you can see all details of the account. Check the [Stellar API Docs](https://developers.stellar.org/api/resources/accounts/) to learn more about account details.

Next, you can try to query the details by using the sdk as shown in the example above. First, replace the account id in the code with your own and then execute the code. 

The ```getAccountDetails``` function replies by using a completion handler. In case of success, you receive an [AccountResponse](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/responses/account_responses/AccountResponse.swift) object, holding the account details of the queried account. In the example above, we print it's account id, it's sequence number and the balances it possesses. 

As mentioned above, the sdk provides many services similar to the account service that allow you to query the data from the Stellar Blockchain. At the time of writing, following services are available:

- [Account Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/AccountService.swift)
- [Assets Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/AssetsService.swift)
- [Payments Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/PaymentsService.swift)
- [Transactions Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/TransactionsService.swift)
- [Ledgers Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/LedgersService.swift)
- [Operations Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/OperationsService.swift)
- [Trades Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/TradesService.swift)
- [Offers Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/OffersService.swift)
- [Fee Stats Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/FeeStatsService.swift)
- [Effects Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/EffectsService.swift)
- [Trade Aggregations Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/TradeAggregationsService.swift)
- [Orderbooks Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/OrderbookService.swift)
- [Paymnent Paths Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/PaymentPathsService.swift)
- [Claimable Balances Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/ClaimableBalancesService.swift)
- [Liquidity Pools Service](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/service/LiquidityPoolsService.swift)

## Building and submitting transactions

Actions that change things in Stellar, like sending payments, changing your account, or making offers to trade various kinds of currencies, are called operations. To actually perform an operation, you create a transaction, which is just a group of operations accompanied by some extra information, like what account is making the transaction and a cryptographic signature to verify that the transaction is authentic. You can use the [Transaction](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/sdk/Transaction.swift) class to create the requests to send to Horizon. 

Stellar stores and communicates transaction data in a binary format called XDR. Luckily, the Stellar SDK provide tools that take care of all that. 

Here’s an example how you might send 10 lumens to another account:

```swift

let sourceAccountKeyPair = try! KeyPair(secretSeed:"SA3QF6XW433CBDLUEY5ZAMHYJLJNHBBOPASLJLO4QKH75HRRXZ3UM2YJ")
let destinationAccountId = "GCKECJ5DYFZUX6DMTNJFHO2M4QKTUO5OS5JZ4EIIS7C3VTLIGXNGRTRC"

// First, check to make sure that the destination account exists.
// You could skip this, but if the account does not exist, you will be charged
// the transaction fee when the transaction fails.
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
        case .success(let accountResponse): // account exists
            do {
                // create the payment operation
                let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                        destinationAccountId: destinationAccountId,
                                                        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                        amount: 10.0)

                // create the transaction containing the payment operation
                let transaction = try Transaction(sourceAccount: accountResponse,
                                                    operations: [paymentOperation],
                                                    memo: Memo.none)

                // Sign the transaction to prove you are actually the person sending it.
                try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                
                // And finally, send it off to Stellar!
                try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        print("Transaction successfully sent!")
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag: "Sample", horizonRequestError:error)
                    case .destinationRequiresMemo(let destinationAccountId):
                        print("Destination account \(destinationAccountId) requires memo.")
                    }
                }
            } catch {
                // ...
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Sample", horizonRequestError:error)

    }
}
```

## Streaming mode

The SDK provides streaming support for all Horizon endpoints that can be used in streaming mode.

It is possible to use the streaming mode for example to listen for new payments as transactions happen in the Stellar network. If called in streaming mode Horizon will start at the earliest known payment unless a cursor is set. In that case it will start from the cursor. You can also set cursor value to "now" to only stream effects created since your request time. Learn more about it in the [Streaming](streaming.md) chapter of this documentation.


Next chapter is [Working with accounts](accounts.md).
