You can generate the seed and key with the following command:

```swift

// create a completely new and unique pair of keys.
let keyPair = try! KeyPair.generateRandomKeyPair()

print("Account Id: " + keyPair.accountId)
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("Secret Seed: " + keyPair.secretSeed)
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
 
```

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