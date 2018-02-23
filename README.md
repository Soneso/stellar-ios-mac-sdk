# stellar-ios-mac-sdk

The Soneso open source stellar SDK for iOS &amp; Mac provides APIs to build transactions and connect to [Horizon](https://github.com/stellar/horizon).

## Disclaimer
This sdk is under active development and should be considered beta quality. Please ensure that you've tested extensively on a test network before using it on the public network.

## Installation

We don't support yet CocoaPods or Carthage. The recommended setup is adding the SDK project as a subproject, and having the SDK as a target dependencies. Here is a step by step that we recommend:

1. Clone this repo (as a submodule or in a different directory, it's up to you);
2. Drag `stellarsdk.xcodeproj` as a subproject;
3. In your main `.xcodeproj` file, select the desired target(s);
4. Go to **Build Phases**, expand Target Dependencies, and add `stellarsdk`;
5. In Swift, `import stellarsdk` and you are good to go! 


## Quick Start

### 1. Create a Stellar key pair

```swift

// create a completely new and unique pair of keys.
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account Id: " + keyPair.accountId)
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("Secret Seed: " + keyPair.secretSeed)
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
 
```

### 2. Create an account
After the key pair generation, you have already got the address, but it is not activated until someone transfers at least 1 lumen into it.

#### 2.1 Testnet
If you want to play in the Stellar test network, the sdk can ask Friendbot to create an account for you as shown below:

```swift
// To create a test account, sdk.accounts.createTestAccount will send Friendbot the public key you created
sdk.accounts.createTestAccount(accountId: keyPair.accountId) { (response) -> (Void) in
    switch response {
        case .success(let details):
                print(details)
        case .failure(let error):
                print(error.localizedDescription)
     }
}
```

#### 2.2 Public net
On the other hand, if you would like to create an account in the public net, you should buy some Stellar Lumens from an exchange. When you withdraw the Lumens into your new account, the exchange will automatically create the account for you.

### 3. Check account
#### 3.1 Basic info
After creating the account, we may check the basic information of the account.

```swift
sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
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

        for (key, value) in accountDetails.data {
            print("data key: \(key) value: \(value.base64Decoded() ?? "")")
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

#### 3.2 Check payments
You can check the most recent payments by:

```swift
let accountId = "GD4FLXKATOO2Z4DME5BHLJDYF6UHUJS624CGA2FWTEVGUM4UZMXC7GVX"
sdk.payments.getPayments(order:Order.descending, limit:10) { response in
    switch response {
    case .success(let paymentsResponse):
        for payment in paymentsResponse.records {
            if payment is PaymentOperationResponse {
                let nextPayment = payment as! PaymentOperationResponse
                if (nextPayment.assetType == AssetTypeAsString.NATIVE) {
                    print("received: \(nextPayment.amount) lumen" )
                } else {
                    print("received: \(nextPayment.amount) \(nextPayment.assetCode!)" )
                }
                print("from: \(nextPayment.from)" )
            } else if payment is AccountCreatedOperationResponse {
                //...
            }
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```
You can use the parameters:`limit`, `order`, and `cursor` to customize the query. You can also get most recent payments for accounts, ledgers and transactions. 

Horizon has SSE support for push data, if you really want to, use it like this:

```swift
sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: nil)).onReceive { (response) -> (Void) in
    switch response {
        case .open:
            break
        case .response(let id, let paymentResponse):
            if paymentResponse.assetType == AssetTypeAsString.NATIVE {
                print("Payment of \(paymentResponse.amount) XLM from \(paymentResponse.sourceAccount) received -  id \(id)" )
            } else {
                print("Payment of \(paymentResponse.amount) \(paymentResponse.assetCode!) from \(paymentResponse.sourceAccount) received -  id \(id)" )
            }
            showDestinationAccountBalance(finish: true)
        case .error( _):
            XCTAssert(false)
            expectation.fulfill()
    }
}
```
#### 3.3 Check others
Just like payments, you you check `assets`, `transactions`, `effects`, `offers`, `operations`, `ledgers` etc.  by:

```swift
sdk.assets.getAssets()
sdk.transactions.getTransactions()
sdk.effects.getEffects()
sdk.offers.getOffers()
sdk.operations.getOperations()
// andd so on ...
```

### 4. Building and submitting transactions

Example payment:

```swift
// create the payment operation
let paymentOperation = PaymentOperation(sourceAccount: sourceAccountKeyPair,
                                        destination: destinationAccountKeyPair,
                                        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                        amount: 1.5)
                                        
// create the transaction containing the payment operation                                        
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [paymentOperation],
                                  memo: Memo.none,
                                  timeBounds:nil)

// sign the transaction
try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)

// submit the transaction
try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
      case .success(_):
          // ...
      case .failure(_):
          // ...
    }
}
```

# How to contribute

Please read our [Contribution Guide](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/CONTRIBUTING.md).

Then please [sign the Contributor License Agreement](https://goo.gl/forms/hS2KOI8d7WcelI892).

## License

stellar-ios-mac-sdk is licensed under an Apache-2.0 license. See the [LICENSE](https://github.com/soneso/stellar-ios-mac-sdk/blob/master/LICENSE) file for details.

## Donations
Send lumens to: GBD7Z2JSVGD2CWNMULKEROA75E6QXCAIERITPICSV77VMRDXNWIXNGLL
