Accounts must explicitly trust an issuing account before they’re able to hold the issuer’s asset.

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

To delete a trustline set the limit to 0.