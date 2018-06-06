# stellar-ios-mac-sdk

The Soneso open source stellar SDK for iOS &amp; Mac provides APIs to build transactions and connect to [Horizon](https://github.com/stellar/horizon).


## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate stellar SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
use_frameworks!

target '<Your Target Name>' do
    pod 'stellar-ios-mac-sdk', '~> 1.1.4'
end
```

Then, run the following command:

```bash
$ pod repo update
$ pod install
```

### Manual

Add the SDK project as a subproject, and having the SDK as a target dependencies. Here is a step by step that we recommend:

1. Clone this repo (as a submodule or in a different directory, it's up to you);
2. Drag `stellarsdk.xcodeproj` as a subproject;
3. In your main `.xcodeproj` file, select the desired target(s);
4. Go to **Build Phases**, expand Target Dependencies, and add `stellarsdk` for iOS and `stellarsdk-macOS` for OSX;
5. In Swift, `import stellarsdk` and you are good to go! 


## Quick Start

### 1. Create a Stellar key pair

#### 1.1 Random generation

```swift

// create a completely new and unique pair of keys.
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account Id: " + keyPair.accountId)
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("Secret Seed: " + keyPair.secretSeed)
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
 
```

#### 1.2 Deterministic generation
See [Key Derivation Methods for Stellar Accounts](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)

Generate mnemonic
```swift
let mnemonic = Wallet.generate24WordMnemonic()
print("generated 24 words mnemonic: \(mnemonic)")
// bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better
```

Generate key pairs
```swift
let keyPair0 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
let keyPair1 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1)

print("key pair 0 accountId: \(keyPair0.accountId)")
// key pair 0 accountId: GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ

print("key pair 0 secretSeed: \(keyPair0.secretSeed!)")
// key pair 0 secretSeed: SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7
```

Generate key pairs with passphrase
```swift
let keyPair0 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
let keyPair1 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
``` 

BIP and master key generation
```swift
let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)

let masterPrivateKey = Ed25519Derivation(seed: bip39Seed)
let purpose = masterPrivateKey.derived(at: 44)
let coinType = purpose.derived(at: 148)

let account0 = coinType.derived(at: 0)
let keyPair0 = try! KeyPair.init(seed: Seed(bytes: account0.raw.bytes))

let account1 = coinType.derived(at: 1)
let keyPair1 = try! KeyPair.init(seed: Seed(bytes: account1.raw.bytes))
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
On the other hand, if you would like to create an account in the public net, you should buy some Stellar Lumens from an exchange. When you withdraw the Lumens into your new account, the exchange will automatically create the account for you. However, if you want to create an account from another account of your own, you may run the following code:

```swift

// build the operation
let createAccount = CreateAccountOperation(sourceAccount: nil, 
                                           destination: destinationKeyPair, 
                                           startBalance: 2.0)

// build the transaction
let transaction = try Transaction(sourceAccount: accountResponse,
                                     operations: [createAccount],
                                     memo: Memo.none,
                                     timeBounds:nil)
                                     
// sign the transaction
try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
// submit the transaction
try sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
    case .success(_):
        //...
    case .failure(let error):
       // ...
    }
}
```

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
sdk.payments.getPayments(order:Order.descending, limit:10) { response in
    switch response {
    case .success(let paymentsResponse):
        for payment in paymentsResponse.records {
            if let nextPayment = payment as? PaymentOperationResponse {
                if (nextPayment.assetType == AssetTypeAsString.NATIVE) {
                    print("received: \(nextPayment.amount) lumen" )
                } else {
                    print("received: \(nextPayment.amount) \(nextPayment.assetCode!)" )
                }
                print("from: \(nextPayment.from)" )
            }
            else if let nextPayment = payment as? AccountCreatedOperationResponse {
                //...
            }
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```
You can use the parameters:`limit`, `order`, and `cursor` to customize the query. You can also get most recent payments for accounts, ledgers and transactions. 

Horizon has SSE support for push data. You can use it like this:

```swift
sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: nil)).onReceive { (response) -> (Void) in
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
#### 3.3 Check others
Just like payments, you you check `assets`, `transactions`, `effects`, `offers`, `operations`, `ledgers` etc.  by:

```swift
sdk.assets.getAssets()
sdk.transactions.getTransactions()
sdk.effects.getEffects()
sdk.offers.getOffers()
sdk.operations.getOperations()
// add so on ...
```

### 4. Building and submitting transactions

Example "send payment":

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
try sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
    switch response {
      case .success(_):
          // ...
      case .failure(_):
          // ...
    }
}
```

## Documentation and Examples

You can find documentation and examples in the [docs](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs) folder.

## Sample IOS app

Satraj from BlockEQ created an [open source iOS wallet](https://github.com/Block-Equity/stellar-ios-wallet) for Stellar, that uses our sdk. Thank you Satraj for your contribution to this project! 

## How to contribute

Please read our [Contribution Guide](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/CONTRIBUTING.md).

Then please [sign the Contributor License Agreement](https://goo.gl/forms/hS2KOI8d7WcelI892).

## License

stellar-ios-mac-sdk is licensed under an Apache-2.0 license. See the [LICENSE](https://github.com/soneso/stellar-ios-mac-sdk/blob/master/LICENSE) file for details.

## Donations
Send lumens to: GBD7Z2JSVGD2CWNMULKEROA75E6QXCAIERITPICSV77VMRDXNWIXNGLL
