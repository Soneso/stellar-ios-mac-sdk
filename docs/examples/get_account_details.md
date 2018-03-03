Load account details from Horizon

```swift

let accountId = "GD53MSTOROVW4YQ2CWNJXYIK44ILXKDN4CYPKQVAF3EXVDT7Q6HASX5T"

sdk.accounts.getAccountDetails(accountId: destinationKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountDetails):
        
        // You can check the `balance`, `sequence`, `flags`, `signers`, `data` etc.
        
        for balance in accountDetails.balances {
            switch balance.assetType {
            case AssetTypeAsString.NATIVE:
                print("balance: \(balance.balance) XLM")
            default:
                print("balance: \(balance.balance) \(balance.assetCode!) issuer: \(balance.assetIssuer!)")
            }
        }

        print("sequence number: \(accountDetails.sequenceNumber)")

        for signer in accountDetails.signers {
            print("signer public key: \(signer.publicKey)")
        }

        print("auth required: \(accountDetails.flags.authRequired)")
        print("auth revocable: \(accountDetails.flags.authRevocable)")
        print("auth immutable: \(accountDetails.flags.authImmutable)")
        
        if let homeDomain = accountDetails.homeDomain {
            print("home domain: \(homeDomain)")
        }
                
        if let inflationDestination = accountDetails.inflationDestination {
            print("inflation destination: \(inflationDestination)")
        }

        for (key, value) in accountDetails.data {
            print("data key: \(key) value: \(value.base64Decoded() ?? "")")
        }
        
    case .failure(let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Sample", horizonRequestError: error)
    }
}
```
