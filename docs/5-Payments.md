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

You can request the next or previous page like this:

```swift

pageResponse.getNextPage(){ (response) -> (Void) in
    switch response {
    case .success(let nextPageResponse):
        for assetResponse in nextPageResponse.records {
            print("Asset code: \(assetResponse.assetCode!)")
            print("Asset issuer: \(assetResponse.assetIssuer!)")
        }
    case .failure(let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"get next page", horizonRequestError: error)
    }
}

```


## Trusting an asset

Accounts must explicitly trust an issuing account before they’re able to hold the issuer’s asset. To trust an issuing account, you create a trustline. Trustlines are entries that persist in the Stellar ledger. They track the limit for which your account trusts the issuing account and the amount of credit from the issuing account that your account currently holds.

If you are not familiar with trustlines you can find more information in the [Stellar Guide](https://www.stellar.org/developers/guides/concepts/assets.html#trustlines).

Following example shows how to build such a trustline:


```swift

// asset issuer
let issuingAccountKeyPair = try KeyPair(accountId: "GCXIZK3YMSKES64ATQWMQN5CX73EWHRHUSEZXIMHP5GYHXL5LNGCOGXU")

// asset
let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)

// our account that wants to hold "IOM" the sdk currency. Please use your own account.          
let trustingAccountKeyPair = try KeyPair(secretSeed: "SA3XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXUM2YJ")

// load our accounts details to be sure that we have the current sequence number.
sdk.accounts.getAccountDetails(accountId: trustingAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
    do {
        // build a change trust operation.
        let changeTrustOp = ChangeTrustOperation(asset:IOM!, limit: 100000000)

        // build the transaction containing our operation
        let transaction = try Transaction(sourceAccount: accountResponse,
                                          operations: [changeTrustOp],
                                          memo: Memo.none,
                                          timeBounds:nil)
		// sign the transaction                        
        try transaction.sign(keyPair: trustingAccountKeyPair, network: Network.testnet)
        
        // sublit the transaction
        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
            switch response {
            case .success(_):
                print("Success")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Trust error", horizonRequestError:error)
            }
        }
    } catch {
        //...
    }
    case .failure(let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Get account error", horizonRequestError:error)
    }
}

```