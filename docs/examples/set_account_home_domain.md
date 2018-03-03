Set home domain for account

```swift

// replace the seed with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")

let homeDomain = "http://www.soneso.com"

// load the account from horizon to be sure that we have the current sequence number.            
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
        do {
			
            // build a set options operation, provide the new home domain.
            let setHomeDomainOperation = try SetOptionsOperation(homeDomain: homeDomain)
			
            // build the transaction that contains our operation.
            let transaction = try Transaction(sourceAccount: accountResponse,
                                              operations: [setHomeDomainOperation],
                                              memo: Memo.none,
                                              timeBounds:nil)
			
			
            // sign the transaction.
            try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
			
            // submit the transaction to the stellar network.			
            try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(_):
                    print("Success")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError:error)
                }
            }
        } catch {
            // ...
        }
    case .failure(let error): // error loading account details
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError: error)
    }
}
```
