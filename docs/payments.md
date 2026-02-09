# Send and receive payments

Most of the time, you’ll be sending money to someone else who has their own account. For this tutorial, however, you'll need a second account to transact with. So before proceeding, follow the steps outlined in [Create an Account](accounts.md#create-account) to make two accounts: one for sending and one for receiving.

## About operations and transactions

Actions that do things on Stellar — like sending payments or making buy or sell offers — are called operations. To submit an operation to the network, you bundle it into a transaction, which is a group of anywhere from 1 to 100 operations accompanied by some extra information, like which account is making the transaction and a cryptographic signature to verify that the transaction is authentic.

Transactions are atomic, meaning that if any operation in a transaction fails, they all fail. Let’s say you have 100 lumens and you make two payment operations of 60 lumens each. If you make two transactions (each with one operation), the first will succeed and the second will fail because you don’t have enough lumens. You’ll be left with 40 lumens. However, if you group the two payments into a single transaction, they will both fail and you’ll be left with the full 100 lumens still in your account.

Every transaction also incurs a small fee. Like the minimum balance on accounts, this fee deters spam and prevents people from overloading the system. This base fee is very small — 100 stroops per operation where a stroop equals 1 * 10 ^-7 XLM — and it's charged for each operation in a transaction. A transaction with two operations, for instance, would cost 200 stroops.

## Send a payment

Stellar stores and communicates transaction data in a binary format called XDR. Luckily, the Stellar SDKs provide tools that take care of all that. Here’s how you might send 10.5 lumens to another account:


```swift
let responseEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
switch responseEnum {
case .success(let accountResponse):
    do {
        // build the payment operation
        let paymentOperation = try PaymentOperation(sourceAccountId: sourceAccountKeyPair.accountId,
                                                destinationAccountId: destinationAccountId,
                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                amount: 10.5)
        
        // build the transaction containing our payment operation.
        let transaction = try Transaction(sourceAccount: accountResponse,
                                            operations: [paymentOperation],
                                            memo: Memo.none)
        // sign the transaction
        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)

        // submit the transaction.
        let txResponseEnum = await sdk.transactions.submitTransaction(transaction: transaction)
        switch txResponseEnum {
        case .success(_):
            print("Success")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Test", horizonRequestError:error)
        case .destinationRequiresMemo(let destinationAccountId):
            print("Destination account \(destinationAccountId) requires memo.")
        }
    } catch {
        //...
    }
case .failure(let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Test", horizonRequestError:error)
}
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/docs/QuickStartTest.swift#L299)

Hint: Sometimes it makes sense to first check if the destination account exists before sending the payment. If the account does not exist, you will be charged the transaction fee when the transaction fails. To check if the account exists you can just try to load its details with: ```swift sdk.accounts.getAccountDetails ```

## Receive Payments

You don’t actually need to do anything to receive payments into a Stellar account — if a payer makes a successful transaction to send assets to you, those assets will automatically be added to your account.

However, you’ll want to know that someone has actually paid you. If you are an automated rental car with a Stellar account, you’ll probably want to verify that the customer in your front seat actually paid before that person can turn on your engine.

A simple program that watches the network for payments and prints each one might look like:

First define your stream item somewhere to be able to hold the reference:
```swift
var streamItem:OperationsStreamItem? = nil
```

then create, assign and use it:
```swift
streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountId, cursor: nil))

streamItem.onReceive { (response) -> (Void) in
    switch response {
    case .open:
        break
    case .response(let id, let operationResponse):
        if let paymentResponse = operationResponse as? PaymentOperationResponse {
            switch paymentResponse.assetType {
            case AssetTypeAsString.NATIVE:
                print("Payment of \(paymentResponse.amount) XLM from \(paymentResponse.sourceAccount) received -  id \(id)" )
            default:
                print("Payment of \(paymentResponse.amount) \(paymentResponse.assetCode!) from \(paymentResponse.sourceAccount) received -  id \(id)" )
            }
        }
    case .error(let err):
        print(err?.localizedDescription ?? "Error")
    }
}
```

later you can close the stream item:

```swift
streamItem.close()
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/docs/QuickStartTest.swift#L222)


## Check payments

You can also "manually" check the most recent payments by:

```swift
let responseEnum = await sdk.payments.getPayments(order:Order.descending, limit:10)
switch responseEnum {
case .success(let paymentsResponse):
    for payment in paymentsResponse.records {
        if let nextPayment = payment as? PaymentOperationResponse {
            if (nextPayment.assetType == AssetTypeAsString.NATIVE) {
                print("received: \(nextPayment.amount) lumen" )
            } else {
                print("received: \(nextPayment.amount) \(nextPayment.assetCode!)" )
            }
            print("from: \(nextPayment.from)" )
        }
        else if let nextPayment = payment as? AccountCreatedOperationResponse {
            //...
        }
    }
case .failure(let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Test", horizonRequestError:error)
}
```
See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/docs/QuickStartTest.swift#L158)

You can use the parameters:`limit`, `order`, and `cursor` to customize the query. You can also get most recent payments for accounts, ledgers and transactions. 

For example get payments for account:

```swift
sdk.payments.getPayments(forAccount:keyPair.accountId, order:Order.descending, limit:10)
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/docs/QuickStartTest.swift#L188)

Next chapter is [Working with Assets](assets.md).