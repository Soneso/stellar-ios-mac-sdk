# 4. Assets


Assets are the units that are traded on the Stellar Network.

Other than lumens (see below) all assets consists of an type, code, and issuer.

Lumens (XLM) are the native currency of the network. A lumen is the only asset type that can be used on the Stellar network that doesn’t require an issuer or a trustline.

To learn more about the concept of assets in the Stellar network, take a look at the [Stellar assets concept guide](https://www.stellar.org/developers/guides/concepts/assets.html).

## Get assets

This function calls the endpoint that represents all assets. It will give you all the assets in the system along with various statistics about each. It responds with a page of assets. Pages represent a subset of a larger collection of objects. 

Parameters:
 - assetCode: Optional. Code of the Asset to filter by.
 - Parameter assetIssuer: Optional. Issuer of the Asset to filter by.
 - cursor: Optional. A paging token, specifying where to start returning records from.
 - order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
 - limit: Optional. Maximum number of records to return. Default: 10
 
 
```swift

sdk.assets.getAssets(order:Order.descending, limit:5) { (response) -> (Void) in
    switch response {
    case .success(let pageResponse): // PageResponse<AssetResponse>
        for nextAssetResponse in pageResponse.records {
            print("Asset code: \(nextAssetResponse.assetCode!)")
            print("Asset issuer: \(nextAssetResponse.assetIssuer!)")
        }
    case .failure(let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Get assets", horizonRequestError: error)
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


## Trusting an asset issuer

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
