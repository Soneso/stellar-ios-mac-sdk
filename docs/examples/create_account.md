Ask the SDK to request a testnet account from Friendbot for you:

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

Create an account from another account of your own:


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
            let transaction = try Transaction(sourceAccount: accountResponse,
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