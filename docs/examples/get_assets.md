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