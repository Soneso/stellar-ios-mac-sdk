Send and receive lumens:

```swift

// Source account. Please use your own account.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

// Destination account.
let destinationAccountKeyPair = try KeyPair(accountId: "GCKECJ5DYFZUX6DMTNJFHO2M4QKTUO5OS5JZ4EIIS7C3VTLIGXNGRTRC")


// Listen for payments on the destination account.
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
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error receiving payment", horizonRequestError:horizonRequestError)
        }
    } 
}

// Send a payment
// First load the source account details to be sure that we have the current sequence number.           
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
    do {
        // build the payment operation.
        let paymentOperation = PaymentOperation(destination: destinationAccountKeyPair,
                                                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                amount: 1.5)

        // build the transaction containing the payment operation.                                                    
        let transaction = try Transaction(sourceAccount: accountResponse,
                                          operations: [paymentOperation],
                                          memo: Memo.none,
                                          timeBounds:nil)

        // sign the transaction.
        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                
        // submit the transaction        
        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
            switch response {
            case .success(_):
                print("Transaction successfully sent")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error sending payment", horizonRequestError:error)
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

Send and receive IOM, the SDK asset:

```swift

// Source account. Please use your own account.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

// Destination account. It needs to have a trustline to the issuer of the asset.
let destinationAccountKeyPair = try KeyPair(accountId: "GAWE7LGEFNRN3QZL5ILVLYKKKGGVYCXXDCIBUJ3RVOC2ZWW6WLGK76TJ")

// The asset data.
let issuingAccountKeyPair = try KeyPair(accountId: "GCXIZK3YMSKES64ATQWMQN5CX73EWHRHUSEZXIMHP5GYHXL5LNGCOGXU")
let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)

// Listen for payments on the destination account.
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
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error receiving payment", horizonRequestError:horizonRequestError)
        }
    } 
}

// Send a payment
// First load the source account details to be sure that we have the current sequence number.           
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
    do {
        // build the payment operation.
        let paymentOperation = PaymentOperation(destination: destinationAccountKeyPair,
                                                asset: IOM!,
                                                amount: 2.5)

        // build the transaction containing the payment operation.                                                    
        let transaction = try Transaction(sourceAccount: accountResponse,
                                          operations: [paymentOperation],
                                          memo: Memo.none,
                                          timeBounds:nil)

        // sign the transaction.
        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                
        // submit the transaction        
        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
            switch response {
            case .success(_):
                print("Transaction successfully sent")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error sending payment", horizonRequestError:error)
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