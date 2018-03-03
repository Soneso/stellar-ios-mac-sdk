Following example shows how to change/set the inflation destination:

```swift

// replace the seed and account id with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")
let destinationAccountId = "GD53MSTOROVW4YQ2CWNJXYIK44ILXKDN4CYPKQVAF3EXVDT7Q6HASX5T"


// load the account from horizon to be sure that we have the current sequence number.
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
        do {
            // build a set options operation, provide the new inflation destination.
            let setInflationOperation = try SetOptionsOperation(inflationDestination: KeyPair(accountId:destinationAccountId))
			
            // build the transaction that contains our operation.
            let transaction = try Transaction(sourceAccount: accountResponse,
                                              operations: [setInflationOperation],
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
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Change inflation destination", horizonRequestError:error)
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
