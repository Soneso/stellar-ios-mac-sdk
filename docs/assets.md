# Working with Assets


Assets are the units that are traded on the Stellar Network.

Other than lumens (see below) all assets consist of an type, code, and issuer.

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
let IOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)

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

## Issue an asset

There is no dedicated operation to create an asset on Stellar. Instead, assets are created with a payment operation: an issuing account makes a payment using the asset it’s issuing, and that payment creates the asset on the network.

The public key of the issuing account is linked on the ledger to the asset. Responsibility for and control over an asset resides with the issuing account. Since settings are stored at the account level on the ledger, the issuing account is where you use set_options operations to link to meta-information about an asset and set authorization flags.

In the chapter [update account details](accounts.md#update-account-details) we described how you can change the details of, for example an issuing account.

You can read more about issuing assets on the official [Stellar developer site](https://developers.stellar.org/docs/category/issue-assets).

### Issue an asset tutorial

This tutorial is based on the example from the official Stellar developer site which can be found [here](https://developers.stellar.org/docs/issuing-assets/how-to-issue-an-asset).

**1. Create issuing account and an object to represent the new asset**

```swift
let issuerKeypair = try! KeyPair.generateRandomKeyPair()
let astroDollar = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "AstroDollar", issuer: issuerKeypair)!;
```

**2. Create distribution account**

```swift
let distributionKeypair = try! KeyPair.generateRandomKeyPair()
        
// Alternative: This loads a keypair from a secret key you already have
// let distributionKeypair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4");
```

**3. Establish trustline between the two**

```swift
// build the change trust operation
let changeTrustAsset = ChangeTrustAsset(type: astroDollar.type, code: astroDollar.code, issuer: astroDollar.issuer)!
let changeTrustOperation = ChangeTrustOperation(sourceAccountId: distributionKeypair.accountId,
                                                asset: changeTrustAsset,
                                                limit: 1000)

// build the transaction
let transaction = try Transaction(sourceAccount: accountResponse,
                                        operations: [changeTrustOperation],
                                        memo: Memo.none)
```                                                                 

**4. Make a payment from issuing to distribution account, issuing the asset**

```swift
//build the payment operation
let paymentOperation = try PaymentOperation(sourceAccountId: issuerKeypair.accountId,
                                            destinationAccountId: distributionKeypair.accountId,
                                            asset: astroDollar,
                                            amount: 1000)

// build the transaction
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [paymentOperation],
                                  memo: Memo.none)
```

You can find the full working code as a testcase [here](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/IssueAssetTest.swift).

### Publish Information About An Asset

How to publish information about an asset is described on the official Stellar developer site [here](https://developers.stellar.org/docs/issuing-assets/publishing-asset-info).

This SDK supports the parsing of Stellar Info Files as described in [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md). The description on how to use the integrated parser of the SDK can be found [here](seps#stellar-info-file---sep-0001.md).

Next chapter is [Querying data](querying.md).