# stellar-ios-mac-sdk

The Soneso open source Stellar SDK for iOS &amp; Mac provides APIs to query Horizon and Soroban RPC, build, sign and submit transactions to the Stellar Network. It supports different Stellar Ecosystem Proposals and helps developers deploy and invoke Soroban Smart Contracts.

## Installation

### Swift Package Manager

#### Latest stable release:

```swift
.package(name: "stellarsdk", url: "git@github.com:Soneso/stellar-ios-mac-sdk.git", from: "3.2.6"),
```

If not loading (err: `cannot use bare repository`), then remove:

```sh
[safe]
    bareRepository = explicit
```

from `~/.gitconfig`. See also this [SourceTree issue](https://forums.swift.org/t/fatal-cannot-use-bare-repository/75588). 

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate stellar SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

#### Last stable release:

```ruby
use_frameworks!

target '<Your Target Name>' do
    pod 'stellar-ios-mac-sdk', '~> 3.2.6'
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

#### Last stable release:

```ogdl
github "soneso/stellar-ios-mac-sdk" ~> 3.2.6
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

print("Account Id: \(keyPair.accountId)")
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("Secret Seed: \(keyPair.secretSeed!)")
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
```

#### 1.2 Deterministic generation

The Stellar Ecosystem Proposal [SEP-005 Key Derivation Methods for Stellar Accounts](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) describes methods for key derivation for Stellar. This improves key storage and moving keys between wallets and apps.

Generate mnemonic
```swift
let mnemonic = WalletUtils.generate24WordMnemonic()
print("generated 24 words mnemonic: \(mnemonic)")
// bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better
```

Generate key pairs
```swift
let keyPair0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
let keyPair1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1)

print("key pair 0 accountId: \(keyPair0.accountId)")
// key pair 0 accountId: GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ

print("key pair 0 secretSeed: \(keyPair0.secretSeed!)")
// key pair 0 secretSeed: SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7
```

Generate key pairs with passphrase
```swift
let keyPair0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
let keyPair1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 1)
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
let responseEnum = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
switch responseEnum {
case .success(let details):
    print(details)
case .failure(let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createTestAccount", horizonRequestError: error)
}
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L18)
 
#### 2.2 Public net

On the other hand, if you would like to create an account in the public net, you should buy some Stellar Lumens from an exchange. See [Stellar's lumen buying guide](https://www.stellar.org/lumens/exchanges). When you withdraw the Lumens into your new account, the exchange will automatically create the account for you. However, if you want to create an account from another account of your own, you may run the following code:

```swift
// build the operation
let createAccount = try CreateAccountOperation(sourceAccountId: nil,
                                           destinationAccountId: destinationAccountId,
                                           startBalance: 2.0)

// build the transaction
let transaction = try Transaction(sourceAccount: accountResponse,
                                     operations: [createAccount],
                                     memo: Memo.none)
                                     
// sign the transaction
try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
// submit the transaction
let responseEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch responseEnum {
case .success(let details):
    //...
case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
    print("destination account \(destinationAccountId) requires memo")
case .failure(error: let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"submitTransaction", horizonRequestError: error)
}
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L37)

### 3. Check account
#### 3.1 Basic info

After creating the account, we may check the basic information of the account.

```swift
let responseEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)

switch responseEnum {
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
        print("signer public key: \(signer.key)")
    }

    print("auth required: \(accountDetails.flags.authRequired)")
    print("auth revocable: \(accountDetails.flags.authRevocable)")

    for (key, value) in accountDetails.data {
        print("data key: \(key) value: \(value.base64Decoded() ?? "")")
    }
case .failure(let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"account details", horizonRequestError: error)
}
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L92)

#### 3.2 Check payments

You can check the most recent payments by:

```swift
let responseEnum = await sdk.payments.getPayments(order:Order.descending, limit:10)

switch responseEnum {
case .success(let page):
    for payment in page.records {
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
        else if let nextPayment = payment as? PathPaymentStrictSendOperationResponse {
            //...
        }
        // ...
    }
case .failure(let error):
    // ...
}
```
See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L139)

You can use the parameters:`limit`, `order`, and `cursor` to customize the query. You can also get most recent payments for accounts, ledgers and transactions. 

For example get payments for account:

```swift
sdk.payments.getPayments(forAccount:keyPair.accountId, order:Order.descending, limit:10)
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L171)

Horizon has SSE support for push data. You can use it like this:

first define your stream item somewhere to be able to hold the reference:
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

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L201)

#### 3.3 Check others

Just like payments, you can check `assets`, `transactions`, `effects`, `offers`, `operations`, `ledgers` etc.  by:

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
let paymentOperation = PaymentOperation(sourceAccountId: sourceAccountId,
                                        destinationAccountId: destinationAccountId,
                                        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                        amount: 1.5)
                                        
// create the transaction containing the payment operation                                        
let transaction = try Transaction(sourceAccount: accountResponse,
                                  operations: [paymentOperation],
                                  memo: Memo.none)

// sign the transaction
try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)

// submit the transaction
let responseEnum = await sdk.transactions.submitTransaction(transaction: transaction)
switch responseEnum {
case .success(let result):
    // ...
default:
    // ...
}
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L281)

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
See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L342)

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
let responseEnum = await Federation.forDomain(domain: domain, secure: secure)
switch responseEnum {
case .success(let federation):
    //use the federation object to map your infos
case .failure(let error):
    //something went wrong
}
```

#### 5.2 Resolve a federation address to an account id

Resolve your addresses:

```swift
let federation = Federation(federationAddress: "https://YOUR_FEDERATION_SERVER")
let responseEnum = await federation.resolve(address: "bob*YOUR_DOMAIN")
switch responseEnum {
case .success(let federationResponse):
    if let accountId = federationResponse.accountId {
        // use the account id
    } else {
        // there is no account id corresponding to the given address
    }
case .failure(_):
    // something went wrong
}
```

### 6. Anchor-Client interoperability

See [SDK's SEP-006 docs](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/docs/SEP-0006.md)

### 7. URI Scheme to facilitate delegated signing

The Stellar Ecosystem Proposal [SEP-007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) introduces a URI Scheme that can be used to generate a URI that will serve as a request to sign a transaction. The URI (request) will typically be signed by the user’s trusted wallet where she stores her secret key(s).

#### 7.1 Generate a URI for sign transaction.

Generate a URI that will serve as a request to sign a transaction. The URI (request) will typically be signed by the user’s trusted wallet where he stores his secret key(s).

```swift
// create the payment operation
let paymentOperation = try! PaymentOperation(sourceAccountId: sourceAccountId,
                                        destinationAccountId: destinationAccountId,
                                        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                        amount: 1.5)

// create the transaction containing the payment operation
let transaction = try! Transaction(sourceAccount: accountResponse,
                                  operations: [paymentOperation],
                                  memo: Memo.none)
// create the URIScheme object
let uriSchemeBuilder = URIScheme()

// get the URI with your transactionXDR
// more params can be added to the url, check method definition
let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction.transactionXDR, callBack: "your_callback_api.com")
print (uriScheme);
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L372)

#### 7.2 Generate a URI for pay operation

Generate a URI that will serve as a request to pay a specific address with a specific asset, regardless of the source asset used by the payer.

```swift
let uriSchemeBuilder = URIScheme()
// more params can be added to the url, check method definition
let uriScheme = uriSchemeBuilder.getPayOperationURI(destination: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q", amount: 100, assetCode: "BTC", assetIssuer:"GC2PIUYXSD23UVLR5LZJPUMDREQ3VTM23XVMERNCHBRTRVFKWJUSRON5", callBack: "your_callback_api.com")
print (uriScheme);
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L424)

#### 7.3 Sign a transaction from a given URI and send it to the network

Signs a transaction from a URI and sends it to the callback url if present or to the stellar network otherwise.

```swift
let responseEnum = await uriBuilder.signAndSubmitTransaction(forURL: uri, signerKeyPair: keyPair, transactionConfirmation: { (transaction) -> (Bool) in
    // here the transaction from the uri can be checked and confirmed if the signing should continue
    return false
})

switch responseEnum {
case .success:
    // the transaction was successfully signed and sent
case .failure(error: let error):
    // the transaction wasn't valid or it didn't pass the confirmation
}
```

### 8. Stellar Web Authentication

This SEP defines the standard way for clients such as wallets or exchanges to create authenticated web sessions on behalf of a user who holds a Stellar account. A wallet may want to authenticate with any web service which requires a Stellar account ownership verification, for example, to upload KYC information to an anchor in an authenticated way as described in SEP-6. Stellar Web Authentication is described in [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md).

#### 8.1 Get a JWT token.

Authenticate with a server and get a JWT token.

```swift
let authEndpoint = "https://testanchor.stellar.org/auth"
let serverSigningKey = "GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS"
let serverHomeDomain = "testanchor.stellar.org"
let userAccountId = "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V"
let userSeed = "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX"

// Hold a strong reference to this to avoid being deallocated
let webAuth = WebAuthenticator(authEndpoint: authEndpoint, network: .testnet,
                                serverSigningKey: serverSigningKey, serverHomeDomain: serverHomeDomain)

let signers = [try! KeyPair(secretSeed: self.userSeed)]

let responseEnum = await webAuth.jwtToken(forUserAccount: userAccountId, signers: signers)
switch responseEnum {
case .success(let jwtToken):
    print("JWT received: \(jwtToken)")
case .failure(let error):
    // ...
}
```

#### 8.2 Create WebAuthenticator from stellar.toml

Creates the WebAuthenticator by loading the web auth endpoint and the server signing key from the stellar.toml file of the given domain.

```swift
let responseEnum = await WebAuthenticator.from(domain:"yourserverhomedomain.com", network: .testnet)
switch responseEnum {
case .success(let webAuth):
    // use the web auth object
case .failure(let error):
    //...
}

```
The Web Authenticator can now be used to get the JWT token (see: 8.1)


### 9.  Txrep: human-readable low-level representation of Stellar transactions
Txrep: human-readable low-level representation of Stellar transactions is described in [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md).

For more details have a look to our [Txrep examples](docs/SEP-0011.md)


### 10. Hosted Deposit and Withdrawal

Helps clients to interact with anchors in a standard way defined by [SEP-0024: Hosted Deposit and Withdrawal](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md).

See [SEP-0024 SDK documentation](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0024.md)

### 11. Account recovery

Enables an individual (e.g., a user or wallet) to regain access to a Stellar account as defined by 
[SEP-0030: Account Recovery](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md).

See [SEP-0030: Account Recovery](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0030.md)

### 12. Quotes

see [SEP-38 - Anchor RFQ API](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0038.md)

### 13. Regulated Assets 

see [SEP-08 - Regulated Assets](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0008.md)

## Documentation and Examples

You can find more documentation and examples in the [docs](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs) folder.

## Sample

Our SDK is used by the open source [LOBSTR Vault](https://vault.lobstr.co). You can find the LOBSTR Vault source code [here](https://github.com/Lobstrco/Vault-iOS).

Our SDK is also used by the [LOBSTR Wallet](https://lobstr.co).

## Stellar Ecosystem Proposals (SEPs) supported

- [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) - Stellar Info File (Toml)
- [SEP-0002](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) - Federation protocol
- [SEP-0005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) - Key Derivation Methods for Stellar Accounts
- [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) - Anchor/Client interoperability
- [SEP-0007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) - URI Scheme to facilitate delegated signing
- [SEP-0008](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md) - Regulated Assets
- [SEP-0009](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md) - Standard KYC / AML fields
- [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) - Stellar Web Authentication
- [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md) - Txrep
- [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md) - Anchor/Client customer info transfer
- [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md) - Hosted Deposit and Withdrawal
- [SEP-0030](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md) - Account Recovery
- [SEP-0038](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md) - Anchor RFQ API

## Soroban support

This SDK provides [support for Soroban](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/soroban.md). 

## Soroban Smart Wallets (Passkey) support

We are working on integrating passkey support for Soroban Smart Wallets into this SDK. In the meantime, we are providing an experimental Passkey Kit for working with Soroban Smart Wallets that you can find here:  [SwiftPasskeyKit](https://github.com/Soneso/SwiftPasskeyKit). 

## Compatibility matrices
- [Horizon API compatibility matrix](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/compatibility/horizon/HORIZON_COMPATIBILITY_MATRIX.md)
- [RPC API compatibility matrix](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/compatibility/rpc/RPC_COMPATIBILITY_MATRIX.md)

## Feedback & Feature Requests  

We’d love to hear from you! 
If you’re using this SDK in your project, your feedback is incredibly valuable for helping us improve.  

- ✅ What’s working well?  
- ⚡ What could be improved?  
- 🌟 Any features you’d like to see in the future?  

Please share your thoughts in [GitHub Discussions](https://github.com/Soneso/stellar-ios-mac-sdk/discussions),  
or open an issue directly:  
- [🐞 Bug Report](https://github.com/Soneso/stellar-ios-mac-sdk/issues/new?template=bug_report.yml)  
- [🌟 Feature Request](https://github.com/Soneso/stellar-ios-mac-sdk/issues/new?template=feature_request.yml)  

Even a couple of quick notes go a long way — thank you for helping us make the SDK better for the whole Stellar community! 🙏  

## Contributing

Contributions are welcome! There are several ways you can help improve this SDK:

- 🐞 [Report bugs](https://github.com/Soneso/stellar-ios-mac-sdk/issues/new?template=bug_report.yml)  
- 🌟 [Request features](https://github.com/Soneso/stellar-ios-mac-sdk/issues/new?template=feature_request.yml)  
- 💬 Share your ideas in [Discussions](https://github.com/Soneso/stellar-ios-mac-sdk/discussions)  
- 🔧 Submit a Pull Request with code improvements  

Please check out our [Contributing Guide](./CONTRIBUTING.md) for details. 🙏


## DeepWiki
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Soneso/stellar-ios-mac-sdk)


