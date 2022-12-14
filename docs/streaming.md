## Streaming

This SDK provides streaming support for all [Horizon endpoints](https://developers.stellar.org/api/introduction/streaming/) that can be used in streaming mode.

It is possible to use the streaming mode for example to listen for new payments for a given account as transactions happen in the Stellar network. You can use it like this:

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

See: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L222) 


Next chapter is [Path Payments](path-payments.md).