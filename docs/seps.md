# Stellar Ecosystem Proposals

Each SEP is a distinct blueprint meant to help users build a product or service that interoperates with other products and services on the Stellar network. On the Stellar developer site they are described [here](https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-ecosystem-proposals).

This SDK provides implementations of following SEPs:

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
- [SEP-0038](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md) - Anchor RFQ API (Quotes)

# Stellar Info File - SEP-0001

The stellar info file is used to provide a common place where the Internet can find information about a domain’s Stellar integration. Any website can publish Stellar network information. They can announce their validation key, their federation server, peers they are running, their quorum set, if they are an anchor, etc.

The Stellar info file is a text file in the [TOML format](https://github.com/toml-lang/toml). The content is defined in [SEp-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)

Given the domain “DOMAIN”, the Stellar Info File will be searched for at the following location:

https://DOMAIN/.well-known/stellar.toml

This SDK provides tools to load Stellar Info Files and read data from them.

**Getting a StellarToml object and read data**

From domain:

```swift
try? StellarToml.from(domain: "soneso.com") { (result) -> (Void) in
    switch result {
    case .success(response: let stellarToml):
    
        // ex. read federation server url
        if let federationServer = stellarToml.accountInformation.federationServer {
            print(federationServer)
        } else {
            print("Toml contains no federation server url")
        }
        
        // read other data
        // stellarToml.accountInformation...
        // stellarToml.issuerDocumentation ...
        // stellarToml.pointsOfContact...
        // stellarToml.currenciesDocumentation...
        // stellarToml.validatorInformation...

    case .failure(let error):
        switch error {
        case .invalidDomain:
            // do something
        case .invalidToml:
            // do something
        }
    }
}
```

From string:

```swift
let stellarToml = try? StellarToml(fromString: tomlSample)

if let federationServer = stellarToml.accountInformation.federationServer {
    print(federationServer)
} else {
    print("Toml contains no federation server url")
}

// read other data
// stellarToml.accountInformation...
// stellarToml.issuerDocumentation ...
// stellarToml.pointsOfContact...
// stellarToml.currenciesDocumentation...
// stellarToml.validatorInformation...
```

You can find more source code examples regarding SEP-0001 in the [Toml test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/toml/TomlTestCase.swift) of the SDK. 

# Federation Protocol - SEP-0002

## Using a federation server

The Stellar federation protocol defined in [SEP-002](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) maps Stellar addresses to more information about a given user. It’s a way for Stellar client software to resolve email-like addresses such as:

name*yourdomain.com 

into account IDs like: 

GCCVPYFOHY7ZB7557JKENAX62LUAPLMGIWNZJAFV2MITK6T32V37KEJU 

Stellar addresses provide an easy way for users to share payment details by using a syntax that interoperates across different domains and providers.

## Get federation server address for a domain

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

## Resolve a federation address to an account id

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

You can find more source code examples regarding SEP-0002 in the [Federation test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/federation/FederationTestCase.swift) of the SDK. 

# Key Derivation Methods for Stellar Accounts - SEP-0005


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
let keyPair1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
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

You can find more source code examples regarding SEP-0005 in the [Mnemonic generation test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/wallet/MnemonicGeneration.swift) and the [Mnemonic keypair generation test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/wallet/MnemonicKeyPairGeneration.swift) of the SDK. 

# Anchor Client Interoperability - SEP-0006

See [SDK's SEP-006 docs](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/docs/SEP-0006.md)

# URI Scheme to facilitate delegated signing SEP-0007

The Stellar Ecosystem Proposal [SEP-0007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) introduces a URI Scheme that can be used to generate a URI that will serve as a request to sign a transaction. The URI (request) will typically be signed by the user’s trusted wallet where she stores her secret key(s).

## Generate a URI for sign transaction.

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

## Generate a URI for pay operation

Generate a URI that will serve as a request to pay a specific address with a specific asset, regardless of the source asset used by the payer.

```swift
let uriSchemeBuilder = URIScheme()
// more params can be added to the url, check method definition
let uriScheme = uriSchemeBuilder.getPayOperationURI(destination: "GAK7I2E6PVBFF27NU5MRY6UXGDWAJT4PF2AH46NUWLFJFFVLOZIEIO4Q", amount: 100, assetCode: "BTC", assetIssuer:"GC2PIUYXSD23UVLR5LZJPUMDREQ3VTM23XVMERNCHBRTRVFKWJUSRON5", callBack: "your_callback_api.com")
print (uriScheme);
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/docs/QuickStartTest.swift#L424)

## Sign a transaction from a given URI and send it to the network

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

You can find more source code examples regarding SEP-0007 in the [Uri scheme test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/uri_scheme/URISchemeTestCase.swift) of the SDK. 

#  Regulated Assets - SEP-0008

see [SEP-08 - Regulated Assets](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0008.md)

# Standard KYC / AML fields - SEP-0009

This SEP defines a list of standard KYC and AML fields for use in Stellar ecosystem protocols. Issuers, banks, and other entities on Stellar should use these fields when sending or requesting KYC / AML information with other parties on Stellar. See [SEP-0009](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md) for more details.

In this SDK they are implemented in the are implemented [here](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdk/transfer_server_protocol/requests/PutCustomerInfoRequest.swift).

# Stellar Web Authentication - SEP-0010

This SEP defines the standard way for clients such as wallets or exchanges to create authenticated web sessions on behalf of a user who holds a Stellar account. A wallet may want to authenticate with any web service which requires a Stellar account ownership verification, for example, to upload KYC information to an anchor in an authenticated way as described in SEP-6. Stellar Web Authentication is described in [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md).

## Get a JWT token.

Authenticate with a server and get a JWT token.

```swift
// Hold a strong reference to this to avoid being deallocated
let webAuthenticator = WebAuthenticator(authEndpoint: "http://your_api.stellar.org/auth", network: .testnet, serverSigningKey: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP", serverHomeDomain: "yourserverhomedomain.com" )
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

## Create WebAuthenticator from stellar.toml

Creates the WebAuthenticator by loading the web auth endpoint and the server signing key from the stellar.toml file of the given domain.

```swift

let webAuthenticator = WebAuthenticator.from(domain:"yourserverhomedomain.com", network: .testnet)

```
The Web Authenticator can now be used to get the JWT token.

You can find more source code examples regarding SEP-0010 in the [Web authenticator test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/web_authenticator/WebAuthenticatorTestCase.swift) of the SDK. 

# Txrep - SEP-0011

Txrep: human-readable low-level representation of Stellar transactions is described in [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md).

For more details have a look to our [Txrep examples](docs/SEP-0011.md)

You can find more source code examples regarding SEP-0011 in this [SDK test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/transactions/TransactionsLocalTestCase.swift) of the SDK. 

# Hosted Deposit and Withdrawal

see [SEP-24 - interactive](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0024.md)

#  Account Recovery

see [SEP-30 - Account Recovery](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0030.md)

#  Quotes

see [SEP-38 - Anchor RFQ API](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/docs/SEP-0038.md)

