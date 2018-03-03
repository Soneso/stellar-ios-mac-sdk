# 2. Key pairs


Every Stellar account has a public key and a secret seed. Stellar uses public key cryptography to ensure that every transaction is secure. The public key is always safe to share—other people need it to identify your account and verify that you authorized a transaction. The seed, however, is private information that proves you own your account. You should never share the seed with anyone. It’s kind of like the combination to a lock—anyone who knows the combination can open the lock. In the same way, anyone who knows your account’s seed can control your account.

If you’re familiar with public key cryptography, you might be wondering how the seed differs from a private key. The seed is actually the single secret piece of data that is used to generate both the public and private key for your account. Stellar’s tools use the seed instead of the private key for convenience: To have full access to an account, you only need to provide a seed instead of both a public key and a private key.

Because the seed must be kept secret, the first step in creating an account is creating your own seed and key—when you finally create the account, you’ll send only the public key to a Stellar server.


## Generate keys

You can generate the seed and key with the following command:

```swift

// create a completely new and unique pair of keys.
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account Id: " + keyPair.accountId)
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("Secret Seed: " + keyPair.secretSeed)
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
 
```

## Create KeyPair objects

KeyPair objects must contain the public key but holding of the seed is not mandatory. Depending on the usecase you can create and use key pairs with or without providing the seed. 

You can create a new KeyPair with one of the following constructors:

```swift

// Creates a new Stellar KeyPair object from an existing Stellar account ID (base64 encoded public key).
// The new KeyPair object will contain a public key but no private key.
let destinationAccountKeyPair = try KeyPair(accountId: "GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB")

// Creates a new Stellar KeyPair object from an existing Stellar base64 encoded seed.
// The new KeyPair object will contain public and private key.
let sourceAccountKeyPair = try KeyPair(secretSeed: "SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7")
        
// Creates a new Stellar KeyPair object from a PublicKey object
// The new KeyPair object will contain a public key but no private key.
let destination2AccountKeyPair = try KeyPair(publicKey: paymentOperationXDR.destination)
        
// other constructors
public init(publicKey: PublicKey, privateKey: PrivateKey?)
public convenience init(seed: Seed)
public convenience init(publicKey: [UInt8], privateKey: [UInt8])

```

## Get human readable accountId and secretSeed

You can obtain the human readable accountId (base64 encoded public key) with the following command:

```swift

let accountId = myKeyPair.accountId

```

You can obtain the human readable secret seed (base64 encoded seed) with the following command:


```swift

let secretSeed = myKeyPair.secretSeed

```

Of course, this only will return the human readable secret seed if the KeyPair object has a secret seed.
It has a secret seed if it was created by one of the following constructors:

```swift

public convenience init(secretSeed: String)
public convenience init(seed: Seed)
 

```

Or if it is a new KeyPair object that was created by the generate random function:

```swift

// use static func generateRandomKeyPair()
let keyPair = try! KeyPair.generateRandomKeyPair()
print("secretSeed: \(keyPair.secretSeed)")

```