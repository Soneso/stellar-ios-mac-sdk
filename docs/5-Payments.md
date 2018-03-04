# 5. Payments


Now that you have an account, you can send and receive funds through the Stellar network. If you haven’t created an account yet, read here about [Accounts](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/docs/3-Accounts.md)

Most of the time, you’ll be sending money to someone else who has their own account. For this interactive guide, however, you should make a second account to transact with using the same method you used to make your first account.

## Send Payments

Actions that change things in Stellar, like sending payments, changing your account, or making offers to trade various kinds of currencies, are called operations.[1] In order to actually perform an operation, you create a transaction, which is just a group of operations accompanied by some extra information, like what account is making the transaction and a cryptographic signature to verify that the transaction is authentic.[2]

If any operation in the transaction fails, they all fail. For example, let’s say you have 100 lumens and you make two payment operations of 60 lumens each. If you make two transactions (each with one operation), the first will succeed and the second will fail because you don’t have enough lumens. You’ll be left with 40 lumens. However, if you group the two payments into a single transaction, they will both fail and you’ll be left with the full 100 lumens still in your account.

Finally, every transaction costs a small fee. Like the minimum balance on accounts, this fee helps stop people from overloading the system with lots of transactions. Known as the base fee, it is very small—100 stroops per operation (that’s 0.00001 XLM; stroops are easier to talk about than such tiny fractions of a lumen). A transaction with two operations would cost 200 stroops.

**Building a Transaction**

Stellar stores and communicates transaction data in a binary format called XDR. Luckily, the Stellar SDKs provide tools that take care of all that. Here’s how you might send 10.5 lumens to another account:
 
```swift

// source account. Please use your own
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

// destination account
let destinationAccountKeyPair = try KeyPair(accountId: "GCKECJ5DYFZUX6DMTNJFHO2M4QKTUO5OS5JZ4EIIS7C3VTLIGXNGRTRC")

// get the account data to be sure that we have the current sequence number.
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
        case .success(let accountResponse):
        do {
            // build the payment operation        
            let paymentOperation = PaymentOperation(destination: destinationAccountKeyPair,
                                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                    amount: 10.5)
            
            // build the transaction containing our payment operation.
            let transaction = try Transaction(sourceAccount: accountResponse,
                                              operations: [paymentOperation],
                                              memo: Memo.none,
                                              timeBounds:nil)
            // sign the transaction
            try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)

            // submit the transaction.                        
            try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(_):
                    print("Success")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test", horizonRequestError:error)
                }
            }
        } catch {
            //...
        }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"SRP Test", horizonRequestError:error)
	}
}
```

IMPORTANT: It’s possible that you will not receive a response from Horizon server due to a bug, network conditions, etc. In such situation it’s impossible to determine the status of your transaction. That’s why you should always save a built transaction (or transaction encoded in XDR format) in a variable or a database and resubmit it if you don’t know it’s status. If the transaction has already been successfully applied to the ledger, Horizon will simply return the saved result and not attempt to submit the transaction again. Only in cases where a transaction’s status is unknown (and thus will have a chance of being included into a ledger) will a resubmission to the network occur.

Hint: Sometimes it makes sense to first check if the destination account exists before sending the payment. If the account does not exist, you will be charged the transaction fee when the transaction fails. To check if the account exists you can just try to load its details with: ```swift sdk.accounts.getAccountDetails ```

## Receive Payments

You don’t actually need to do anything to receive payments into a Stellar account — if a payer makes a successful transaction to send assets to you, those assets will automatically be added to your account.

However, you’ll want to know that someone has actually paid you. If you are an automated rental car with a Stellar account, you’ll probably want to verify that the customer in your front seat actually paid before that person can turn on your engine.

A simple program that watches the network for payments and prints each one might look like:

```swift

sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: "now")).onReceive { (response) -> (Void) in
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
    case .error(let error):
        if let horizonRequestError = error as? HorizonRequestError {
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Receive payment", horizonRequestError:horizonRequestError)
        } else {
            print("Error \(error?.localizedDescription ?? "")") // Other error like e.g. streaming error, you may want to ignore this.
        }
    }
}

```

