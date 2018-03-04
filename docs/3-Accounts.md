# 2. Accounts


Now that you have a [seed and public key](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/docs/2-Key-Pairs.md#generate-keys), you can create an account. 

In order to prevent people from making a huge number of unnecessary accounts, each account must have a minimum balance of 1 lumen (lumens are the built-in currency of the Stellar network).

Since you don’t yet have any lumens, though, you can’t pay for an account. In the real world, you’ll usually pay an exchange that sells lumens in order to create a new account.

On Stellar’s test network, however, we can ask Friendbot, the friendly robot with a very fat wallet, to create an account for us.

## Ask the SDK for a testnet account 

The easiest way to create a testnet account is to ask the SDK to request one from Friendbot for you.
To create a test account, send the public key you created. It’ll create and fund a new account using that public key as the account ID.

```swift

// Init the SDK with an url of a horizon server using the testnet 
// E.g. let sdk = StellarSDK("https://horizon-testnet.yourcompany.org")

// If you init the SDK without argument, it will automatically use the testnet horizon 
// server provided by the stellar foundation ("https://horizon-testnet.stellar.org")
let sdk = StellarSDK()


// Create a completely new and unique pair of keys.
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account Id: " + keyPair.accountId)
print("Secret Seed: " + keyPair.secretSeed)

// Ask the SDK to create a testnet account for you. It’ll ask the Sellar Testnet Friendbot to create the account.
sdk.accounts.createTestAccount(accountId: keyPair.accountId) { (response) -> (Void) in
	switch response {
	case .success(let details):
	    print(details)
	case .failure(let error):
	    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError: error)
	}
}
 
```

Hint: 
Sometimes the Friendbot from the stellar foundation testnet ("https://horizon-testnet.stellar.org") is not is not very friendly or not running at all. 

In this case you can not create the account and if you don't already have another account you will have to wait until Friendbot is available again. 

In case of error you can also double check if Friendbot is available by trying to create an account with the [Stellar Laboratory](https://www.stellar.org/laboratory/#account-creator?network=test).

## Public network

On the other hand, if you would like to create an account in the public net, you should buy some Stellar Lumens from an exchange. When you withdraw the Lumens into your new account,
the exchange will automatically create the account for you. 

## Create from other account

However, if you want to create an account from another account of your own, you may run the following code:


```swift

// create keypair with the seed of your already existing account.
// replace the seed with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")

// generate a random keypair representing the new account to be created.
let destinationKeyPair = try KeyPair.generateRandomKeyPair()
print("Destination account Id: " + destinationKeyPair.accountId)
print("Destination secret seed: " + destinationKeyPair.secretSeed)

// load the source account from horizon to be sure that we have the current sequence number.
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
        case .success(let accountResponse): // source account successfully loaded.
	do {
            // build a create account operation.
            let createAccount = CreateAccountOperation(destination: destinationKeyPair, startBalance: 2.0)
            
	    // build a transaction that contains the create account operation.
            et transaction = try Transaction(sourceAccount: accountResponse,
							    operations: [createAccount],
							    memo: Memo.none,
							    timeBounds:nil)
								
            // sign the transaction.
            try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
            
	    // submit the transaction to the stellar network.
            try sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(_):
                    print("Account successfully created.")
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Create account", horizonRequestError: error)
                }
            }
        } catch {
            // ...
        }
	case .failure(let error): // error loading account details
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError: error)
    }
}

```

## Get account details from Horizon

Now that you created the account, you can get the account’s details and checking its balance. Accounts can carry multiple balances — one for each type of currency they hold.

```swift

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

        for (key, value) in accountDetails.data {
            print("data key: \(key) value: \(value.base64Decoded() ?? "")")
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

See also the [Stellar Guide](https://www.stellar.org/developers/guides/concepts/accounts.html) and the [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html) for a detailed description of the properties that accounts have.

## Change account details

You can change account details such as the home domain, inflation pool or thresholds with the set options operation.

Following example shows how to change/set the inflation destination:

```swift

// replace the seed and account id with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")
let destinationAccountId = "GD53MSTOROVW4YQ2CWNJXYIK44ILXKDN4CYPKQVAF3EXVDT7Q6HASX5T"


// load the account from horizon to be sure that we have the current sequence number.
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
    do {
        // build a set options operation, provide the new inflation destination.
        let setInflationOperation = try SetOptionsOperation(inflationDestination: KeyPair(accountId:destinationAccountId))
			
        // build the transaction that contains our operation.
        let transaction = try Transaction(sourceAccount: accountResponse,
                                          operations: [setInflationOperation],
                                          memo: Memo.none,
                                          timeBounds:nil)
											  
        // sign the transaction.
        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
			
        // submit the transaction to the stellar network.
        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
            switch response {
            case .success(_):
                print("Success")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Change inflation destination", horizonRequestError:error)
            }
        }
    } catch {
        // ...
    }
    case .failure(let error): // error loading account details
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError: error)
    }
}
```

Following example shows how to change/set the home domain:

```swift

// replace the seed with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")

let homeDomain = "http://www.soneso.com"

// load the account from horizon to be sure that we have the current sequence number.            
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
    case .success(let accountResponse):
    do {
        // build a set options operation, provide the new home domain.
        let setHomeDomainOperation = try SetOptionsOperation(homeDomain: homeDomain)
			
        // build the transaction that contains our operation.
        let transaction = try Transaction(sourceAccount: accountResponse,
                                          operations: [setHomeDomainOperation],
                                          memo: Memo.none,
                                          timeBounds:nil)
			
			
        // sign the transaction.
        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
			
        // submit the transaction to the stellar network.			
        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
            switch response {
            case .success(_):
                print("Success")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError:error)
            }
        }
    } catch {
        // ...
    }
    case .failure(let error): // error loading account details
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error:", horizonRequestError: error)
    }
}
```

## Load, add, change and remove account data

Each account in Stellar network can contain multiple key/value pairs associated with it. The SDK can be used to retrieve value of each data key. The returned value is base64-encoded.

Following example shows how to retreive the value for a given key:

```swift

sdk.accounts.getDataForAccount(accountId: testSuccessAccountId, key:"soneso") { (response) -> (Void) in
    switch response {
    case .success(let dataForAccount):
        print("retrieved value: \(dataForAccount.value.base64Decoded())")
    case .failure(let error):
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GDFA Test", horizonRequestError: error)
    }
}

```

You can also add, change or detete key value pairs. Following example shows how to add or change a key value pair:

```swift

// replace the seed with your own.
let sourceAccountKeyPair = try KeyPair(secretSeed:"SDXEJKRXYLTV344KWCRJ4PXXXJVXKGK3UGESRWBWLDEWYO4S5OQ6VQ6I")

let name = "soneso"
let value = "is super"

// load the account from horizon to be sure that we have the current sequence number.            
sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
    switch response {
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
        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
            switch response {
            case .success(_):
                print("Success")
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error: ", horizonRequestError:error)
            }
        }
    } catch {
        // ...
    }
    case .failure(let error): // error loading account details
        StellarSDKLog.printHorizonRequestErrorMessage(tag:"Error", horizonRequestError: error)
    }
}
```

To delete an existing key value pair send nil as a value.

