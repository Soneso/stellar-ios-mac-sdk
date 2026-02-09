# Working with accounts

Accounts are a fundamental building block of Stellar: they hold all your balances, allow you to send and receive payments, and let you place offers to buy and sell assets. Since pretty much everything on Stellar is in some way tied to an account, the first thing you generally need to do when you start developing is create one. 

Before we get started with working with code, consider getting fammiliar with the [Stellar developer documentation](https://developers.stellar.org/) and the [Stellar Laboratory](https://laboratory.stellar.org/). The lab allows you create accounts, fund accounts on the Stellar test network, build transactions, run any operation, and inspect responses from Horizon via the Endpoint Explorer.

## Create a Keypair

Stellar uses public key cryptography to ensure that every transaction is secure: every Stellar account has a keypair consisting of a public key and a secret key. The public key (also called account id) is always safe to share — other people need it to identify your account and verify that you authorized a transaction. It's like an email address. The secret key, however, is private information that proves you own — and gives you access to — your account. It's like a password, and you should never share it with anyone.

Before creating an account, you need to generate your own keypair:

```swift
// create a completely new and unique pair of keys.
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account Id: \(keyPair.accountId)")
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("Secret Seed: \(keyPair.secretSeed!)")
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
```

## Create Account

A valid keypair, however, does not make an account: in order to prevent unused accounts from bloating the ledger, Stellar requires accounts to hold a minimum balance of 1 XLM before they actually exist. Until it gets a bit of funding, your keypair doesn't warrant space on the ledger.

On the public network, where live users make live transactions, your next step would be to acquire XLM, which you can do by consulting Stellar's [lumen buying guide](https://www.stellar.org/lumens/exchanges). Because this tutorial runs on the test network, you can get 10,000 test XLM from Friendbot, which is a friendly account funding tool.

To do that, send Friendbot the public key you created. It’ll create and fund a new account using that public key as the account ID.

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

Now for the next step: getting the account’s details and checking its balance. Accounts can carry multiple balances — one for each type of currency they hold.

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
case .failure(let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"account details", horizonRequestError: error)
}
```

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/docs/QuickStartTest.swift#L92)

Now that you have an account you can create other accounts by using it. To do so, we send need to send a transaction to the Stellar Network containing a so called create account operation. From the Stellar developer site, you learn the basics about [transactions and operations](https://developers.stellar.org/docs/fundamentals-and-concepts/stellar-data-structures/operations-and-transactions#transactions).

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

See also: [detailed code example](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/docs/QuickStartTest.swift#L37)

## Update Account Details

You can update the details of your account, such as thresholds, flags, signers, home domain by using the [set options operation](https://developers.stellar.org/docs/fundamentals-and-concepts/list-of-operations#set-options).

Following example shows how to change/set the home domain:

```swift

// replace the seed with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")

let homeDomain = "http://www.soneso.com"

// load the account from horizon to be sure that we have the current sequence number.
let responseEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
switch response {
case .success(let accountResponse):
do {
    // build a set options operation, provide the new home domain.
    let setHomeDomainOperation = try SetOptionsOperation(homeDomain: homeDomain)
        
    // build the transaction that contains our operation.
    let transaction = try Transaction(sourceAccount: accountResponse,
                                        operations: [setHomeDomainOperation],
                                        memo: Memo.none)
        
        
    // sign the transaction.
    try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
        
    // submit the transaction to the stellar network.
    let responseEnum = await sdk.transactions.submitTransaction(transaction: transaction)
    switch responseEnum {
    case .success(let details):
        print("Success")
    case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
        print("destination account \(destinationAccountId) requires memo")
    case .failure(error: let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"submitTransaction", horizonRequestError: error)
    }
} catch {
    // ...
}
case .failure(let error): // error loading account details
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"account details:", horizonRequestError: error)
}
```


## Load, add, change and remove account data

Each account in Stellar network can contain multiple data entries with key/value pairs associated with it. The SDK can be used to retrieve value of each data key. The returned value is base64-encoded.

Following example shows how to retreive the value for a given key:

```swift
let responseEnum = await sdk.accounts.getDataForAccount(accountId: myAcountId, key:"soneso")
switch responseEnum {
case .success(let dataForAccount):
    print("retrieved value: \(dataForAccount.value.base64Decoded())")
case .failure(let error):
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"account data", horizonRequestError: error)
}
```

You can add, update or detete key value pairs by using the [manage data operation](https://developers.stellar.org/docs/fundamentals-and-concepts/list-of-operations#manage-data). 

Following example shows how to add or change a key value pair:

```swift

// replace the seed with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")

let name = "soneso"
let value = "is super"

// load the account from horizon to be sure that we have the current sequence number.
let responseEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
switch responseEnum {
case .success(let accountResponse):
do {
    // build a manage data operation, provide key and value
    let manageDataOperation = ManageDataOperation(name:name, data:value.data(using: .utf8))
        
    // build the transaction that contains our operation.
    let transaction = try Transaction(sourceAccount: accountResponse,
                                        operations: [manageDataOperation],
                                        memo: Memo.none,
                                        timeBounds:nil)
                                            
    // sign the transaction.								  
    try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
        
    // submit the transaction to the stellar network.
    let txResponseEnum = await sdk.transactions.submitTransaction(transaction: transaction)
    switch txResponseEnum {
    case .success(let details):
        print("Success")
    case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
        print("destination account \(destinationAccountId) requires memo")
    case .failure(error: let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"submitTransaction", horizonRequestError: error)
    }
} catch {
    // ...
}
case .failure(let error): // error loading account details
    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error", horizonRequestError: error)
}
```

To delete an existing key value pair send nil as a value.

## Advanced KeyPair creation

You can also create keipairs by using the SDK's implementation of [SEP-005 Key Derivation Methods for Stellar Accounts](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md). It allows you to deterministically create keypairs. To find out how that works, please consult the sdk documentation [here](seps.md#key-derivation-methods-for-stellar-accounts---sep-0005).


Next chapter is [Send and receive native Payments](payments.md).