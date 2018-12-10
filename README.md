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
    pod 'stellar-ios-mac-sdk', '~> 1.5.6'
end
```

Then, run the following command:

```bash
$ pod repo update
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](https://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate stellar-ios-mac-sdk into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "soneso/stellar-ios-mac-sdk" ~> 1.1.5
```

Run `carthage update` to build the framework and drag the build `stellar-ios-mac-sdk.framework` into your Xcode project.

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

The Stellar Ecosystem Proposal [SEP-005 Key Derivation Methods for Stellar Accounts](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) describes methods for key derivation for Stellar. This improves key storage and moving keys between wallets and apps.

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

Get a transaction envelope from an XDR string:

```swift
let xdrString = "AAAAAJ/Ax+axve53/7sXfQY0fI6jzBeHEcPl0Vsg1C2tqyRbAAAAZAAAAAAAAAAAAAAAAQAAAABb2L/OAAAAAFvYwPoAAAAAAAAAAQAAAAEAAAAAo7FW8r8Nj+SMwPPeAoL4aUkLob7QU68+9Y8CAia5k78AAAAKAAAAN0NJcDhiSHdnU2hUR042ZDE3bjg1ZlFGRVBKdmNtNFhnSWhVVFBuUUF4cUtORVd4V3JYIGF1dGgAAAAAAQAAAEDh/7kQjZbcXypISjto5NtGLuaDGrfL/F08apZQYp38JNMNQ9p/e1Fy0z23WOg/Ic+e91+hgbdTude6+1+i0V41AAAAAAAAAAGtqyRbAAAAQNeY1rEwPynWnVXaaE/XWeuRnOHS/479J+Eu7s5OplSlF41xB7E8u9WzEItaOs167xuOVcLZUKBCBF1fnfzMEQg="
do {
    let envelope = try TransactionEnvelopeXDR(xdr:xdrString)
    let envelopeString = envelope.xdrEncoded
} catch {
    print("Invalid xdr string")
}
```

Get a transaction object from an XDR string:

```swift
let xdrString = "AAAAAJ/Ax+axve53/7sXfQY0fI6jzBeHEcPl0Vsg1C2tqyRbAAAAZAAAAAAAAAAAAAAAAQAAAABb2L/OAAAAAFvYwPoAAAAAAAAAAQAAAAEAAAAAo7FW8r8Nj+SMwPPeAoL4aUkLob7QU68+9Y8CAia5k78AAAAKAAAAN0NJcDhiSHdnU2hUR042ZDE3bjg1ZlFGRVBKdmNtNFhnSWhVVFBuUUF4cUtORVd4V3JYIGF1dGgAAAAAAQAAAEDh/7kQjZbcXypISjto5NtGLuaDGrfL/F08apZQYp38JNMNQ9p/e1Fy0z23WOg/Ic+e91+hgbdTude6+1+i0V41AAAAAA=="
do {
    // Get the transaction object
    let transaction = try Transaction(xdr:xdrString)
    // Convert your transaction back to xdr
    let transactionString = transaction.xdrEncoded
} catch {
    print("Invalid xdr string")
}
```

### 5. Using a federation server

The Stellar federation protocol defined in [SEP-002](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) maps Stellar addresses to more information about a given user. It’s a way for Stellar client software to resolve email-like addresses such as:

name*yourdomain.com 

into account IDs like: 

GCCVPYFOHY7ZB7557JKENAX62LUAPLMGIWNZJAFV2MITK6T32V37KEJU 

Stellar addresses provide an easy way for users to share payment details by using a syntax that interoperates across different domains and providers.

#### 5.1 Get federation server address for a domain

Get the federation of your domain:

```swift
Federation.forDomain(domain: "https://YOUR_DOMAIN") { (response) -> (Void) in
    switch response {
    case .success(let federation):
        //use the federation object to map your infos
    case .failure(_):
        //something went wrong
    }
}
```

#### 5.2 Resolve a federation address to an account id

Resolve your addresses:

```swift
let federation = Federation(federationAddress: "https://YOUR_FEDERATION_SERVER")
federation.resolve(address: "bob*YOUR_DOMAIN") { (response) -> (Void) in
    switch response {
    case .success(let federationResponse):
        if let accountId = federationResponse.accountId {
            // use the account id
        } else {
            // there is no account id corresponding to the given address
        }
    case .failure(_):
        // something went wrong
    }
}
```

### 6. Anchor-Client interoperability

The Stellar Ecosystem Proposal [SEP-006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) defines the standard way for anchors and wallets to interact on behalf of users. This improves user experience by allowing wallets and other clients to interact with anchors directly without the user needing to leave the wallet to go to the anchor's site.

This protocol requires anchors to implement endpoints on their TRANSFER_SERVER. An anchor must define the location of their transfer server in their stellar.toml. This is how a wallet knows where to find the anchor's server.

Example: TRANSFER_SERVER="https://api.example.com"

#### 6.1 Get the TransferServerService for a domain

Get the TransferServerService for your domain:

```swift
TransferServerService.forDomain(domain: "https://YOUR_DOMAIN") { (response) -> (Void) in
    switch response {
        case .success(let transferServerService):
	        // use the transferServerService object to call other operations
        case .failure(_):
	        // something went wrong
    }
}
```

#### 6.2 Deposit external assets with an anchor

A deposit is when a user sends an external token (BTC via Bitcoin, USD via bank transfer, etc...) to an address held by an anchor. In turn, the anchor sends an equal amount of tokens on the Stellar network (minus fees) to the user's Stellar account.
The deposit endpoint allows a wallet to get deposit information from an anchor, so a user has all the information needed to initiate a deposit. It also lets the anchor specify additional information (if desired) that the user must submit via the /customer endpoint to be able to deposit.

```swift
let request = DepositRequest(assetCode: "BTC", account: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q")
transferServerService.deposit(request: request) { (response) -> (Void) in
    switch response {
        case .success(let response):
	       // deposit was sent with success
        case .failure(_):
	       // something went wrong
    }
}
```

#### 6.3 Withdraw assets from an anchor

This operation allows a user to redeem an asset currently on the Stellar network for the real asset (BTC, USD, stock, etc...) via the anchor of the Stellar asset.
The withdraw endpoint allows a wallet to get withdrawal information from an anchor, so a user has all the information needed to initiate a withdrawal. It also lets the anchor specify additional information (if desired) that the user must submit via the /customer endpoint to be able to withdraw.

```swift
let request = WithdrawRequest(type: "crypto", assetCode: "BTC", dest: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q")
transferServerService.withdraw(request: request) { (response) -> (Void) in
	switch response {
	case .success(let info):
		// the withdraw operation completed successfully
	case .failure(_):
	        // something went wrong
	}
}
```

#### 6.4 Communicate deposit & withdrawal fee structure for an anchor to the user

Allows an anchor to communicate basic info about what their TRANSFER_SERVER supports to wallets and clients.

```swift
transferServerService.info { (response) -> (Void) in
	switch response {
	case .success(let info):
		// info returned successfully
	case .failure(_):
		// something went wrong
	}
}
```

#### 6.5 Using the transaction history endpoint

The transaction history endpoint helps anchors enable a better experience for users using an external wallet. With it, wallets can display the status of deposits and withdrawals while they process and a history of past transactions with the anchor. It's only for transactions that are deposits to or withdrawals from the anchor.

```swift
let request = AnchorTransactionsRequest(assetCode: "BTC", account: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q")
transferServerService.getTransactions(request: request) { (response) -> (Void) in
	switch response {
	case .success(let transactions):
		// the past transactions returned successfully
	case .failure(_):
		// something went wrong
	}
}
```

#### 6.7 Delete all KYC info about customer

Delete all personal information that the anchor has stored about a given customer. [account] is the Stellar account ID (G...) of the customer to delete. This request must be authenticated (via SEP-10) as coming from the owner of the account that will be deleted.

```swift
transferServerService.deleteCustomerInfo(account: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q") { (response) -> (Void) in
	switch response {
	case .success:
	        // all information for the given account was deleted successfully
	case .failure(_):
	        // something went wrong
	}
}
```

### 7. URI Scheme to facilitate delegated signing

The Stellar Ecosystem Proposal [SEP-007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) introduces a URI Scheme that can be used to generate a URI that will serve as a request to sign a transaction. The URI (request) will typically be signed by the user’s trusted wallet where she stores her secret key(s).

#### 7.1 Generate a URI for sign transaction.

Generate a URI that will serve as a request to sign a transaction. The URI (request) will typically be signed by the user’s trusted wallet where he stores his secret key(s).

```swift
sdk.accounts.getAccountDetails(accountId: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q") { (response) -> (Void) in
    switch response {
    case .success(let data):
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
        // create the URIScheme object
        let uriSchemeBuilder = URIScheme()
        
        // get the URI with your transactionXDR
	// more params can be added to the url, check method definition
        let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction.transactionXDR, callBack: "your_callback_api.com")
        
    case .failure(let error):
        //
    }
}
```

#### 7.2 Generate a URI for pay operation

Generate a URI that will serve as a request to pay a specific address with a specific asset, regardless of the source asset used by the payer.

```swift
let uriSchemeBuilder = URIScheme()
// more params can be added to the url, check method definition
let uriScheme = uriSchemeBuilder.getPayOperationURI(accountID: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q", amount: 100, assetCode: "BTC", callBack: "your_callback_api.com")
```

#### 7.3 Sign a transaction from a given URI and send it to the network

Signs a transaction from a URI and sends it to the callback url if present or to the stellar network otherwise.

```swift
uriBuilder.signTransaction(forURL: uri, signerKeyPair: keyPair, transactionConfirmation: { (transaction) -> (Bool) in
    // here the transaction from the uri can be checked and confirmed if the signing should continue
    return true
}) { (response) -> (Void) in
    switch response {
    case .success:
    // the transaction was successfully signed
    case .failure(error: let error):
        // the transaction wasn't valid or it didn't pass the confirmation
}
```

### 8. Stellar Web Authentication

This SEP defines the standard way for clients such as wallets or exchanges to create authenticated web sessions on behalf of a user who holds a Stellar account. A wallet may want to authenticate with any web service which requires a Stellar account ownership verification, for example, to upload KYC information to an anchor in an authenticated way as described in SEP-6.

#### 8.1 Get a JWT token.

Authenticate with a server and get a JWT token.

```swift
// Hold a strong reference to this to avoid being deallocated
let webAuthenticator = WebAuthenticator(authEndpoint: "http://your_api.stellar.org/auth", network: .testnet, serverSigningKey: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP")
    if let keyPair = try? KeyPair(secretSeed: "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX") {
        webAuthenticator.jwtToken(forKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .success(let jwtToken):
                // use the token to do your calls
            case .failure(let error):
                // handle the error
            }
        }
    }
}
```

## Documentation and Examples

You can find more documentation and examples in the [docs](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs) folder.

## Sample IOS app

Satraj from BlockEQ created an [open source iOS wallet](https://github.com/Block-Equity/stellar-ios-wallet) for Stellar, that uses our sdk. Thank you Satraj for your contribution to this project! 

## Stellar Ecosystem Proposals (SEPs) implemented

- [SEP-001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) - Stellar Toml
- [SEP-002](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) - Federation protocol
- [SEP-005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) - Key Derivation Methods for Stellar Accounts
- [SEP-006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) - Anchor/Client interoperability
- [SEP-007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) - URI Scheme to facilitate delegated signing
- [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) - Stellar Web Authentication
- [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md) - Anchor/Client customer info transfer

## How to contribute

Please read our [Contribution Guide](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/CONTRIBUTING.md).

Then please [sign the Contributor License Agreement](https://goo.gl/forms/hS2KOI8d7WcelI892).

## License

stellar-ios-mac-sdk is licensed under an Apache-2.0 license. See the [LICENSE](https://github.com/soneso/stellar-ios-mac-sdk/blob/master/LICENSE) file for details.

## Donations
Send lumens to: GANSYJ64BTHYFM6BAJEWXYLVSZVSHYZFPW4DIQDWJL5BOT6O6GUE7JM5
