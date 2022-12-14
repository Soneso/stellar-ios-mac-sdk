# Querying data

This SDK supports all endpoints exposed by [Horizon](https://developers.stellar.org/api/introduction/). 

The Horizon API serves as a bridge between apps and Stellar Core. Projects like wallets, decentralized exchanges, and asset issuers use Horizon to submit transactions, query an account balance, or stream events like transactions to an account.

Querying Horizon is one of the main uses of this SDK. The SDK takes care of the underlaying communication with Horizon and converts the received data into easy-to-use response objects.

**Resources**

Data on the Stellar ledger is organized according to resources. Each resource has several different endpoints provided by Horizon.

Resource types are: Ledgers, Transactions, Operations, Effects, Accounts, Offers, Claimable Balances, Trades, Assets, Liquidity Pools.

The SDK covers all endpoints by providing so called services. 


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

The ```getAccountDetails``` function replies by using a completion handler. In case of success, you receive an [AccountResponse](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/responses/account_responses/AccountResponse.swift) object, holding the account details of the queried account. In the example above, we print it's account id, its sequence number and the balances it possesses. 

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


Horizon also provides a streaming mechanism for receiving events in near real time. Read about how to use the SDK for [streaming](streaming.md) in the next chapter.
