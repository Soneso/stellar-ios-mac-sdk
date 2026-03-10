# SDK Usage Guide

This guide covers SDK features organized by use case. For detailed method signatures, see the SDK source code and inline documentation.

## Table of Contents

- [Keypairs & Accounts](#keypairs--accounts)
- [Building Transactions](#building-transactions)
- [Operations](#operations)
- [Querying Horizon Data](#querying-horizon-data)
- [Streaming (SSE)](#streaming-sse)
- [Network Communication](#network-communication)
- [Assets](#assets)
- [Soroban (Smart Contracts)](#soroban-smart-contracts)

---

## Keypairs & Accounts

### Creating Keypairs

Every Stellar account has a keypair: a public key (the account ID, starts with G) and a secret seed (starts with S). The secret seed signs transactions; keep it secure and never share it.

```swift
import stellarsdk

// Generate new random keypair
let keyPair = try! KeyPair.generateRandomKeyPair()
print(keyPair.accountId)    // G... public key
print(keyPair.secretSeed!)  // S... secret seed

// Create from existing secret seed
let keyPair2 = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV")

// Create public-key-only keypair (cannot sign)
let publicOnly = try! KeyPair(accountId: "GABC123...")
```

### Loading an Account

Load an account from the network to check its balances, sequence number, and other data. The sequence number is required when building transactions.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Load account data from network
let response = await sdk.accounts.getAccountDetails(accountId: "GABC123...")
switch response {
case .success(let account):
    print("Sequence: \(account.sequenceNumber)")

    // Check balances
    for balance in account.balances {
        switch balance.assetType {
        case AssetTypeAsString.NATIVE:
            print("XLM: \(balance.balance)")
        default:
            print("\(balance.assetCode!): \(balance.balance)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}

// Check if account exists
let existsResponse = await sdk.accounts.getAccountDetails(accountId: "GABC123...")
switch existsResponse {
case .success(_):
    print("Account exists")
case .failure(let error):
    if case .notFound = error {
        print("Account does not exist")
    }
}
```

### Funding Testnet Accounts

FriendBot is a testnet service that funds new accounts with 10,000 test XLM. Only works on testnet; on mainnet you need an existing funded account to create new ones.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let keyPair = try! KeyPair.generateRandomKeyPair()

let response = await sdk.accounts.createTestAccount(accountId: keyPair.accountId)
switch response {
case .success(_):
    print("Account funded")
case .failure(let error):
    print("Error: \(error)")
}
```

### HD Wallets (SEP-5)

Derive multiple Stellar accounts from a single mnemonic phrase. Follows BIP-39 and SLIP-0010 standards, so the same phrase always produces the same accounts.

```swift
import stellarsdk

// Generate 24-word mnemonic
let mnemonic = WalletUtils.generate24WordMnemonic()
print(mnemonic)

// Derive keypairs: m/44'/148'/{index}'
let account0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
let account1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 1)
```

With an optional BIP-39 passphrase, the same mnemonic produces completely different accounts. The passphrase acts as a second factor: someone with only the mnemonic words can't access these accounts.

```swift
import stellarsdk

// Create keypairs from mnemonic with passphrase
let mnemonic = "cable spray genius state float ..."

// Derive with passphrase - produces completely different accounts than without
let account0 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "my-secret-passphrase", index: 0)
let account1 = try! WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "my-secret-passphrase", index: 1)

// Without the exact passphrase, you get different (wrong) accounts
// Keep both the mnemonic AND the passphrase safe
```

### Muxed Accounts

Muxed accounts let multiple virtual users share one Stellar account. Useful for exchanges and payment processors that need to track many users without creating separate accounts for each. The muxed address (M...) encodes both the base account and a 64-bit user ID.

```swift
import stellarsdk

// Create muxed account from base account + ID
let muxedAccount = try! MuxedAccount(accountId: "GABC...", id: 123456789)

print(muxedAccount.accountId)          // M... address
print(muxedAccount.id!)                // 123456789
print(muxedAccount.ed25519AccountId)   // GABC... (base account)

// Parse existing muxed address
let muxed = try! MuxedAccount(accountId: "MABC...")
print(muxed.accountId)          // M... address
print(muxed.ed25519AccountId)   // Underlying G... address
print(muxed.id!)                // The 64-bit ID

// Use in payments
let paymentOp = try! PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: muxedAccount.accountId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100
)
```

### Connecting to Networks

Stellar has multiple networks, each with its own Horizon server and network passphrase. Use testnet for development, public for production. The network passphrase is used when signing transactions.

```swift
import stellarsdk

// Testnet (development and testing)
let sdk = StellarSDK.testNet()
let network = Network.testnet

// Public network (production)
let sdkPublic = StellarSDK.publicNet()
let networkPublic = Network.public

// Futurenet (preview upcoming features)
let sdkFuture = StellarSDK.futureNet()
let networkFuture = Network.futurenet

// Custom Horizon server
let sdkCustom = StellarSDK(withHorizonUrl: "https://my-horizon-server.example.com")
```

---

## Building Transactions

Transactions group one or more operations together. All operations in a transaction execute atomically: either all succeed or all fail. Every transaction needs a source account (which pays the fee) and must be signed before submission.

### Simple Payments

The most common transaction: send XLM or another asset from one account to another.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let senderKeyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV")

let accResponse = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
switch accResponse {
case .success(let sender):
    // Build payment
    let paymentOp = try! PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: "GDEST...",
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: 100.50
    )

    // Build, sign, submit
    let transaction = try! Transaction(
        sourceAccount: sender,
        operations: [paymentOp],
        memo: Memo.none
    )

    try! transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

    let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResponse {
    case .success(let details):
        print("Payment sent! Hash: \(details.transactionHash)")
    case .destinationRequiresMemo(let destinationAccountId):
        print("Destination \(destinationAccountId) requires memo")
    case .failure(let error):
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error loading account: \(error)")
}
```

### Multi-Operation Transactions

Bundle multiple operations into one transaction. This example creates an account, sets up a trustline, and sends an initial payment, all in one atomic transaction. If any operation fails, the entire transaction is rolled back.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let funderKeyPair = try! KeyPair(secretSeed: "SFUNDER...")
let newAccountKeyPair = try! KeyPair.generateRandomKeyPair()
let newAccountId = newAccountKeyPair.accountId

let accResponse = await sdk.accounts.getAccountDetails(accountId: funderKeyPair.accountId)
switch accResponse {
case .success(let funder):
    let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
    let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

    // 1. Create the new account
    let createAccountOp = try! CreateAccountOperation(
        sourceAccountId: nil,
        destinationAccountId: newAccountId,
        startBalance: 5
    )

    // 2. Establish trustline for USD
    // The new account must be the source (not the funder) because trustlines
    // are created by the account that wants to hold the asset
    let trustlineOp = ChangeTrustOperation(
        sourceAccountId: newAccountId,
        asset: ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
    )

    // 3. Send initial USD to new account
    let paymentOp = try! PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: newAccountId,
        asset: usdAsset,
        amount: 100
    )

    // Build transaction with all operations
    let transaction = try! Transaction(
        sourceAccount: funder,
        operations: [createAccountOp, trustlineOp, paymentOp],
        memo: Memo.none
    )

    // Both accounts must sign:
    // - Funder: transaction source (pays fees) + creates account + sends payment
    // - New account: source of the trustline operation
    try! transaction.sign(keyPair: funderKeyPair, network: Network.testnet)
    try! transaction.sign(keyPair: newAccountKeyPair, network: Network.testnet)

    // Submit to network
    let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResponse {
    case .success(let details):
        print("Success: \(details.transactionHash)")
    case .destinationRequiresMemo(let destinationAccountId):
        print("Destination \(destinationAccountId) requires memo")
    case .failure(let error):
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error loading account: \(error)")
}
```

### Memos, Time Bounds, and Fees

Memos attach data to transactions (payment references, user IDs). Time bounds limit when a transaction is valid, preventing old signed transactions from being submitted later. Fees are paid in stroops (1 XLM = 10,000,000 stroops).

```swift
import stellarsdk

// Add memo
let transaction = try! Transaction(
    sourceAccount: account,
    operations: [operation],
    memo: Memo.text("Payment for invoice #1234")
)

// Memo types: Memo.text(), Memo.id(), Memo.hash(), Memo.returnHash()

// Time bounds (valid for next 5 minutes)
let now = UInt64(Date().timeIntervalSince1970)
let timeBounds = TimeBounds(minTime: 0, maxTime: now + 300)
let preconditions = TransactionPreconditions(timeBounds: timeBounds)
let transaction2 = try! Transaction(
    sourceAccount: account,
    operations: [operation],
    memo: Memo.none,
    preconditions: preconditions
)

// Custom fee (stroops per operation, default 100)
let transaction3 = try! Transaction(
    sourceAccount: account,
    operations: [operation],
    memo: Memo.none,
    maxOperationFee: 200
)
```

### Fee Bump Transactions

Fee bump transactions let a different account pay the fee for an existing transaction. Useful when the source account of the inner transaction doesn't have enough XLM to cover fees, or when a service wants to pay fees on behalf of users.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// The user wants to send a payment but has no XLM for fees
let userKeyPair = try! KeyPair(secretSeed: "SUSER...")

let accResponse = await sdk.accounts.getAccountDetails(accountId: userKeyPair.accountId)
switch accResponse {
case .success(let userAccount):
    // Build and sign the inner transaction (user signs their own transaction)
    let payOp1 = try! PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: "GDEST1...",
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: 10
    )
    let payOp2 = try! PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: "GDEST2...",
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: 20
    )

    let innerTransaction = try! Transaction(
        sourceAccount: userAccount,
        operations: [payOp1, payOp2],
        memo: Memo.none
    )

    try! innerTransaction.sign(keyPair: userKeyPair, network: Network.testnet)

    // A service (fee payer) wraps the transaction and pays the fee
    let feePayerKeyPair = try! KeyPair(secretSeed: "SFEEPAYER...")
    let feePayerMuxed = try! MuxedAccount(
        accountId: feePayerKeyPair.accountId,
        sequenceNumber: 0
    )

    // Build fee bump transaction
    // Base fee must be >= (inner tx base fee * number of operations) + 100
    let feeBumpTx = try! FeeBumpTransaction(
        sourceAccount: feePayerMuxed,
        fee: 300,
        innerTransaction: innerTransaction
    )

    // Only the fee payer signs the fee bump
    try! feeBumpTx.sign(keyPair: feePayerKeyPair, network: Network.testnet)

    // Submit the fee bump transaction
    let submitResponse = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBumpTx)
    switch submitResponse {
    case .success(let details):
        print("Fee bump submitted: \(details.transactionHash)")
    case .destinationRequiresMemo(let destinationAccountId):
        print("Destination \(destinationAccountId) requires memo")
    case .failure(let error):
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error loading account: \(error)")
}
```

---

## Operations

Operations are the individual actions within a transaction. Each operation type has its own class. Create the operation, then add it to a transaction.

### Payment Operations

Transfer XLM or custom assets between accounts.

```swift
import stellarsdk

// Native XLM payment
let paymentOp = try! PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100
)

// Custom asset payment
let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
let usdPaymentOp = try! PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: usdAsset,
    amount: 50.25
)
```

### Path Payment Operations

Path payments convert assets through the DEX during transfer. You send one asset and the recipient receives a different asset. Query Horizon for available paths, then choose the best one for your transaction.

First, query available paths to get the exchange route and expected amounts:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Find paths: "If I send 100 XLM, how much USD will the recipient get?"
let pathsResponse = await sdk.paymentPaths.strictSend(
    sourceAmount: "100",
    sourceAssetType: "native",
    destinationAssets: "\(usdAsset.toCanonicalForm())"
)

switch pathsResponse {
case .success(let paths):
    if let bestPath = paths.records.first {
        let destMin = bestPath.destinationAmount // expected USD amount
        let pathAssets = bestPath.path           // intermediate assets
        print("Send 100 XLM, receive \(destMin) USD")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

Then build the path payment operation:

```swift
// Strict send: send exactly 100 XLM, receive at least destMin USD
let pathPaymentOp = try! PathPaymentStrictSendOperation(
    sourceAccountId: nil,
    sendAsset: xlm,
    sendMax: 100,       // send amount (exact for strict send)
    destinationAccountId: "GDEST...",
    destAsset: usdAsset,
    destAmount: Decimal(string: destMin)!,  // minimum amount to receive
    path: []            // intermediate assets from path query
)
```

For strict receive (recipient gets exact amount, you pay variable):

```swift
// Find paths: "If recipient needs exactly 100 USD, how much XLM do I send?"
let pathsResponse = await sdk.paymentPaths.strictReceive(
    sourceAccount: "GSENDER...",
    destinationAssetType: "credit_alphanum4",
    destinationAssetCode: "USD",
    destinationAssetIssuer: issuerKeyPair.accountId,
    destinationAmount: "100"
)

switch pathsResponse {
case .success(let paths):
    if let bestPath = paths.records.first {
        let sendMax = bestPath.sourceAmount  // max XLM needed
        print("Send at most \(sendMax) XLM to receive 100 USD")
    }
case .failure(let error):
    print("Error: \(error)")
}

// Strict receive: receive exactly 100 USD, send at most sendMax XLM
let pathPaymentOp = try! PathPaymentStrictReceiveOperation(
    sourceAccountId: nil,
    sendAsset: xlm,
    sendMax: Decimal(string: sendMax)!,  // maximum amount to send
    destinationAccountId: "GDEST...",
    destAsset: usdAsset,
    destAmount: 100,    // destination amount (exact)
    path: []
)
```

### Account Operations

#### Create Account

Create a new account on the network. The source account funds the new account with a starting balance.

```swift
import stellarsdk

let createOp = try! CreateAccountOperation(
    sourceAccountId: nil,
    destinationAccountId: "GNEWACCOUNT...",
    startBalance: 10  // starting balance in XLM (minimum ~1 XLM for base reserve)
)
```

#### Merge Account

Close an account and transfer all its assets to another account. The merged account is removed from the ledger.

The account being merged is the operation's source account. If not set, it defaults to the transaction's source account.

The destination account must have trustlines for all non-XLM assets the account to be merged holds, otherwise the operation fails.

```swift
import stellarsdk

// Merge the transaction's source account into destination
let mergeOp = try! AccountMergeOperation(
    destinationAccountId: "GDEST...",  // destination receives all XLM and other assets
    sourceAccountId: nil
)

// Or merge a different account (must also sign the transaction)
let mergeOp2 = try! AccountMergeOperation(
    destinationAccountId: "GDEST...",
    sourceAccountId: "GACCOUNT_TO_MERGE..."
)
```

#### Manage Data

Store key-value data on your account (max 64 bytes per entry). Useful for app-specific metadata.

```swift
import Foundation
import stellarsdk

// Store a string value
let setDataOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "config",
    data: "production".data(using: .utf8)  // value (max 64 bytes)
)

// Store binary data (e.g., a hash)
let setHashOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "data_hash",
    data: "some data".data(using: .utf8)
)

// Delete an entry (set value to nil)
let deleteDataOp = ManageDataOperation(
    sourceAccountId: nil,
    name: "temp_key",
    data: nil  // nil removes the entry
)
```

#### Set Options

Configure account settings: home domain, thresholds, signers, and flags.

**Set Home Domain**

The home domain is used for SEP protocols like federation (SEP-2) and stellar.toml discovery.

```swift
import stellarsdk

let setDomainOp = try! SetOptionsOperation(
    sourceAccountId: nil,
    homeDomain: "example.com"
)
```

**Configure Multi-Sig Thresholds**

Operations require signatures with combined weight >= the operation's threshold. Each operation type has a threshold level:

- **Low:** Allow Trust, Set Trustline Flags, Bump Sequence
- **Medium:** Payments, Create Account, Path Payments, Manage Offers, most other operations
- **High:** Account Merge, Set Options (when changing signers or thresholds)

```swift
import stellarsdk

let setThresholdsOp = try! SetOptionsOperation(
    sourceAccountId: nil,
    masterKeyWeight: 10,   // weight of the master key
    lowThreshold: 10,      // e.g., bump sequence
    mediumThreshold: 20,   // e.g., payments
    highThreshold: 30      // e.g., account merge, adding signers
)
```

**Add or Remove Signers**

Add additional signers to create a multi-sig account. Each signer has a weight that contributes to meeting thresholds.

```swift
import stellarsdk

// Add a signer with weight 10
let signerKeyPair = try! KeyPair(accountId: "GSIGNER...")
let signerKey = SignerKeyXDR.ed25519(signerKeyPair.publicKey.bytes)
let addSignerOp = try! SetOptionsOperation(
    sourceAccountId: nil,
    signer: signerKey,
    signerWeight: 10
)

// Remove a signer (set weight to 0)
let removeSignerOp = try! SetOptionsOperation(
    sourceAccountId: nil,
    signer: signerKey,
    signerWeight: 0
)
```

**Set Account Flags**

Flags control asset issuance behavior. Typically set by asset issuers.

```swift
import stellarsdk

// Enable authorization required and revocable (for regulated assets)
let setFlagsOp = try! SetOptionsOperation(
    sourceAccountId: nil,
    setFlags: 1 | 2  // AUTH_REQUIRED_FLAG | AUTH_REVOCABLE_FLAG
)

// Clear a flag
let clearFlagsOp = try! SetOptionsOperation(
    sourceAccountId: nil,
    clearFlags: 2  // AUTH_REVOCABLE_FLAG
)

// Available flags:
// AUTH_REQUIRED_FLAG (1)         - Trustlines must be authorized by issuer
// AUTH_REVOCABLE_FLAG (2)        - Issuer can revoke authorization
// AUTH_IMMUTABLE_FLAG (4)        - Flags can never be changed (irreversible!)
// AUTH_CLAWBACK_ENABLED_FLAG (8) - Issuer can clawback assets
```

#### Bump Sequence

Manually set the account's sequence number. Useful for invalidating pre-signed transactions that use older sequence numbers.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Get the current sequence number
let accResponse = await sdk.accounts.getAccountDetails(accountId: "GABC...")
switch accResponse {
case .success(let account):
    let currentSequence = account.sequenceNumber

    // Bump to current + 100 (invalidates any pre-signed tx with sequence <= current + 100)
    let bumpOp = BumpSequenceOperation(
        bumpTo: currentSequence + 100,
        sourceAccountId: nil
    )
case .failure(let error):
    print("Error: \(error)")
}
```

### Asset Operations

Before receiving a custom asset, an account must create a trustline for it. Trustlines specify which assets the account accepts and set optional limits.

#### Create Trustline

Create a trustline to allow your account to hold a custom asset. The limit specifies the maximum amount you're willing to hold. If omitted, the limit defaults to the maximum possible value (unlimited).

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// With a specific limit
let trustOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: usdAsset,
    limit: 10000  // max amount you can hold
)

// Without limit (defaults to maximum possible value)
let trustOpUnlimited = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: usdAsset
)
```

#### Modify Trustline Limit

Change the maximum amount of an asset your account can hold.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Increase or decrease the limit
let modifyTrustOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: usdAsset,
    limit: 50000  // new limit
)
```

#### Remove Trustline

Remove a trustline by setting the limit to zero. Your balance must be zero first.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Balance must be zero before removing
let removeTrustOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: usdAsset,
    limit: 0  // zero limit removes the trustline
)
```

#### Authorize Trustline (Issuer Only)

If an asset has the AUTH_REQUIRED flag, the issuer must authorize trustlines before holders can receive the asset. Use `SetTrustlineFlagsOperation` to authorize or revoke.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Authorize a trustline (allow holder to receive the asset)
let authorizeOp = SetTrustlineFlagsOperation(
    sourceAccountId: nil,
    asset: usdAsset,
    trustorAccountId: "GTRUSTOR...",
    setFlags: 1,    // AUTHORIZED_FLAG
    clearFlags: 0
)

// Revoke authorization (holder can no longer receive, but can send)
let revokeOp = SetTrustlineFlagsOperation(
    sourceAccountId: nil,
    asset: usdAsset,
    trustorAccountId: "GTRUSTOR...",
    setFlags: 0,
    clearFlags: 1   // AUTHORIZED_FLAG
)
```

### Trading Operations

Place, update, or cancel offers on Stellar's built-in decentralized exchange (DEX).

#### Create Sell Offer

Sell a specific amount of an asset at a given price. You specify how much you want to sell.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Sell 100 XLM at 0.20 USD per XLM (receive 20 USD total)
let sellOp = ManageSellOfferOperation(
    sourceAccountId: nil,
    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    buying: usdAsset,
    amount: 100,
    price: Price(numerator: 1, denominator: 5),  // 0.20
    offerId: 0  // 0 = new offer
)
```

#### Create Buy Offer

Buy a specific amount of an asset at a given price. You specify how much you want to receive.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Buy 50 USD at 0.20 USD per XLM (spend 250 XLM total)
let buyOp = ManageBuyOfferOperation(
    sourceAccountId: nil,
    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    buying: usdAsset,
    amount: 50,
    price: Price(numerator: 1, denominator: 5),  // 0.20
    offerId: 0
)
```

#### Update Offer

Modify an existing offer by providing its offer ID. You can change the amount or price.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Update offer 12345: change amount to 150 XLM at new price 0.22 USD
let updateOp = ManageSellOfferOperation(
    sourceAccountId: nil,
    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    buying: usdAsset,
    amount: 150,
    price: Price(numerator: 11, denominator: 50),  // 0.22
    offerId: 12345  // existing offer to update
)
```

**How to get the offer ID**

You can get the offer ID by querying your account's existing offers:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Get all offers for an account
let offersResponse = await sdk.offers.getOffers(forAccount: "GABC...")
switch offersResponse {
case .success(let page):
    for offer in page.records {
        print("Offer ID: \(offer.id)")
        print("Selling: \(offer.amount)")
        print("Price: \(offer.price)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Cancel Offer

Cancel an existing offer by setting the amount to zero.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Cancel offer 12345
let cancelOp = ManageSellOfferOperation(
    sourceAccountId: nil,
    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    buying: usdAsset,
    amount: 0,       // zero amount cancels the offer
    price: Price(numerator: 1, denominator: 5),  // price doesn't matter when canceling
    offerId: 12345
)
```

#### Passive Sell Offer

A passive offer doesn't immediately match existing offers at the same price. Use it for market making when you want to provide liquidity without taking from the order book.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Passive offer: sell 100 XLM at 0.20 USD per XLM
// Won't match existing offers, waits for a counterparty
let passiveOp = CreatePassiveSellOfferOperation(
    sourceAccountId: nil,
    selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    buying: usdAsset,
    amount: 100,
    price: Price(numerator: 1, denominator: 5)  // 0.20
)
```

### Claimable Balance Operations

Send funds that recipients claim later, with optional time-based conditions. Useful for escrow, scheduled payments, or sending to accounts that don't exist yet.

#### Create Claimable Balance

Lock funds that one or more claimants can claim. Each claimant has a predicate that defines when they can claim.

```swift
import stellarsdk

// Create claimants (who can claim and under what conditions)
let claimant1 = Claimant(
    destination: "GCLAIMER1...",
    predicate: Claimant.predicateUnconditional()  // can claim anytime
)

let thirtyDaysFromNow = Int64(Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970)
let claimant2 = Claimant(
    destination: "GCLAIMER2...",
    predicate: Claimant.predicateBeforeAbsoluteTime(unixEpoch: thirtyDaysFromNow)  // must claim within 30 days
)

// Create the claimable balance
let createOp = CreateClaimableBalanceOperation(
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 100,
    claimants: [claimant1, claimant2]
)
```

#### Predicates

Predicates control when a claimant can claim. You can combine them for complex conditions.

```swift
import stellarsdk

// Unconditional: can claim anytime
let anytime = Claimant.predicateUnconditional()

// Before absolute time: must claim before this Unix timestamp
let thirtyDaysFromNow = Int64(Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970)
let before = Claimant.predicateBeforeAbsoluteTime(unixEpoch: thirtyDaysFromNow)

// Before relative time: must claim within X seconds of balance creation
let withinOneHour = Claimant.predicateBeforeRelativeTime(seconds: 3600)

// NOT: inverts a predicate (e.g., can claim AFTER a time)
let afterOneDay = Claimant.predicateNot(
    predicate: Claimant.predicateBeforeRelativeTime(seconds: 86400)  // NOT "before 1 day" = "after 1 day"
)

// AND: both conditions must be true
// Example: can claim after 1 day AND before 30 days (a time window)
let timeWindow = Claimant.predicateAnd(
    left: Claimant.predicateNot(predicate: Claimant.predicateBeforeRelativeTime(seconds: 86400)),  // after 1 day
    right: Claimant.predicateBeforeRelativeTime(seconds: 86400 * 30)                                // before 30 days
)

// OR: either condition can be true
let eitherCondition = Claimant.predicateOr(left: anytime, right: before)
```

#### Claim Balance

To claim a balance, you need its balance ID. Get it from the transaction response when created, or query claimable balances for your account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Find claimable balances you can claim
let balancesResponse = await sdk.claimableBalances.getClaimableBalances(claimantAccountId: "GCLAIMER1...")
switch balancesResponse {
case .success(let page):
    for balance in page.records {
        print("Balance ID: \(balance.balanceId)")  // hex string
        print("Amount: \(balance.amount)")
        print("Asset: \(balance.assetType)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

Then claim it:

```swift
import stellarsdk

// Claim the balance
let balanceId = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
let claimOp = ClaimClaimableBalanceOperation(balanceId: balanceId)
```

### Liquidity Pool Operations

Provide liquidity to Stellar's automated market maker (AMM) pools and earn trading fees.

#### Pool Share Trustline

Before depositing to a liquidity pool, you need a trustline for the pool shares. Create a pool share asset from the two assets in the pool.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Create pool share asset (assets must be in lexicographic order)
let poolShareAsset = try! ChangeTrustAsset(assetA: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, assetB: usdAsset)!

// Establish trustline for pool shares
let trustPoolOp = ChangeTrustOperation(
    sourceAccountId: nil,
    asset: poolShareAsset
)
```

#### Get Pool ID

Query the pool ID by the reserve assets, or find pools your account participates in.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Find pool by reserve assets
let poolsResponse = await sdk.liquidityPools.getLiquidityPools(
    reserveAssetA: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    reserveAssetB: usdAsset
)
switch poolsResponse {
case .success(let page):
    for pool in page.records {
        print("Pool ID: \(pool.poolId)")
        print("Total shares: \(pool.totalShares)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Deposit Liquidity

Add liquidity to a pool. You specify the maximum amounts of each asset to deposit and price bounds to protect against slippage.

```swift
import stellarsdk

let depositOp = LiquidityPoolDepositOperation(
    sourceAccountId: nil,
    liquidityPoolId: "poolid123abc...",
    maxAmountA: 1000,    // max amount of asset A (XLM)
    maxAmountB: 500,     // max amount of asset B (USD)
    minPrice: Price(numerator: 19, denominator: 10),   // min price - slippage protection
    maxPrice: Price(numerator: 21, denominator: 10)    // max price - slippage protection
)

// The actual amounts deposited depend on the current pool ratio
// Price bounds reject the transaction if the pool price moves outside your range
```

#### Withdraw Liquidity

Remove liquidity by burning pool shares. You receive both assets back proportionally.

```swift
import stellarsdk

let withdrawOp = LiquidityPoolWithdrawOperation(
    sourceAccountId: nil,
    liquidityPoolId: "poolid123abc...",
    amount: 100,       // amount of pool shares to burn
    minAmountA: 180,   // min amount of asset A to receive (slippage protection)
    minAmountB: 90     // min amount of asset B to receive (slippage protection)
)

// If you would receive less than the minimums, the transaction fails
```

### Sponsorship Operations

Sponsorship lets one account pay base reserves for another account's ledger entries. This enables user onboarding without requiring new users to hold XLM for reserves.

#### Sponsor Account Creation

Create a new account where the sponsor pays the base reserve. The new account can start with 0 XLM.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Sponsor: existing funded account that will pay reserves
let sponsorKeyPair = try! KeyPair(secretSeed: "SSPONSOR...")

let accResponse = await sdk.accounts.getAccountDetails(accountId: sponsorKeyPair.accountId)
switch accResponse {
case .success(let sponsorAccount):
    // New account to be sponsored
    let newAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    let newAccountId = newAccountKeyPair.accountId

    let transaction = try! Transaction(
        sourceAccount: sponsorAccount,
        operations: [
            // 1. Begin sponsoring - sponsor declares intent to pay reserves
            BeginSponsoringFutureReservesOperation(sponsoredAccountId: newAccountId),
            // 2. Create account with 0 XLM (sponsor pays the reserve)
            CreateAccountOperation(sourceAccountId: nil, destination: newAccountKeyPair, startBalance: 0),
            // 3. End sponsoring - new account must confirm (source = new account)
            EndSponsoringFutureReservesOperation(sponsoredAccountId: newAccountId)
        ],
        memo: Memo.none
    )

    // Both must sign:
    // - Sponsor: authorizes paying reserves and funds the transaction
    // - New account: confirms acceptance of sponsorship (required for EndSponsoring)
    try! transaction.sign(keyPair: sponsorKeyPair, network: Network.testnet)
    try! transaction.sign(keyPair: newAccountKeyPair, network: Network.testnet)

    let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResponse {
    case .success(let details):
        print("Sponsored account created: \(details.transactionHash)")
    case .destinationRequiresMemo(let destinationAccountId):
        print("Destination \(destinationAccountId) requires memo")
    case .failure(let error):
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Sponsor Trustline

Sponsor a trustline for an existing account. Useful when users want to hold an asset but don't have XLM for the trustline reserve.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let sponsorKeyPair = try! KeyPair(secretSeed: "SSPONSOR...")
let userKeyPair = try! KeyPair(secretSeed: "SUSER...")
let userId = userKeyPair.accountId

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

let accResponse = await sdk.accounts.getAccountDetails(accountId: sponsorKeyPair.accountId)
switch accResponse {
case .success(let sponsorAccount):
    let transaction = try! Transaction(
        sourceAccount: sponsorAccount,
        operations: [
            BeginSponsoringFutureReservesOperation(sponsoredAccountId: userId),
            ChangeTrustOperation(sourceAccountId: userId, asset: usdAsset),
            EndSponsoringFutureReservesOperation(sponsoredAccountId: userId)
        ],
        memo: Memo.none
    )

    // Both sign
    try! transaction.sign(keyPair: sponsorKeyPair, network: Network.testnet)
    try! transaction.sign(keyPair: userKeyPair, network: Network.testnet)

    let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResponse {
    case .success(let details):
        print("Trustline sponsored: \(details.transactionHash)")
    case .destinationRequiresMemo(let destinationAccountId):
        print("Destination \(destinationAccountId) requires memo")
    case .failure(let error):
        print("Error: \(error)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Revoke Sponsorship

Transfer the reserve responsibility back to the sponsored account. The operation fails if the account doesn't have enough XLM to cover its own reserves after revoking.

```swift
import stellarsdk

// Revoke account sponsorship
let revokeAccountKey = try! RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(
    accountId: "GSPONSORED..."
)
let revokeAccountOp = RevokeSponsorshipOperation(ledgerKey: revokeAccountKey)

// Revoke trustline sponsorship
let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
let revokeTrustlineKey = try! RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(
    accountId: "GSPONSORED...",
    asset: usdAsset
)
let revokeTrustlineOp = RevokeSponsorshipOperation(ledgerKey: revokeTrustlineKey)

// Revoke data entry sponsorship
let revokeDataKey = try! RevokeSponsorshipOperation.revokeDataSponsorshipLedgerKey(
    accountId: "GSPONSORED...",
    dataName: "data_key"
)
let revokeDataOp = RevokeSponsorshipOperation(ledgerKey: revokeDataKey)
```

---

## Querying Horizon Data

Horizon is the API server for Stellar. Query it for accounts, transactions, operations, and other network data. All query methods support `cursor`, `order`, and `limit` parameters for pagination (see [Pagination](#pagination) at the end of this section).

### Account Queries

Look up accounts by ID, signer, asset holdings, or sponsor.

#### Get Single Account

Fetch a specific account by its public key.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccountDetails(accountId: "GABC...")
switch response {
case .success(let account):
    print("Sequence: \(account.sequenceNumber)")
    print("Subentry count: \(account.subentryCount)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Check if Account Exists

Check whether an account exists on the network before attempting operations. Useful for deciding between `CreateAccountOperation` (new account) vs `PaymentOperation` (existing account).

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccountDetails(accountId: "GABC...")
switch response {
case .success(_):
    print("Account exists - use PaymentOperation")
case .failure(let error):
    if case .notFound = error {
        print("Account does not exist - use CreateAccountOperation")
    } else {
        print("Error: \(error)")
    }
}
```

#### Query by Signer

Find all accounts that have a specific key as a signer. Useful for discovering accounts controlled by a key.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccounts(
    signer: "GSIGNER...",
    order: .descending,
    limit: 50
)
switch response {
case .success(let page):
    for account in page.records {
        print(account.accountId)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Query by Asset

Find all accounts holding a specific asset. Useful for asset issuers to find their token holders.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccounts(
    asset: "USD:GISSUER..."
)
switch response {
case .success(let page):
    for account in page.records {
        print(account.accountId)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Query by Sponsor

Find all accounts sponsored by a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccounts(
    sponsor: "GSPONSOR..."
)
switch response {
case .success(let page):
    for account in page.records {
        print(account.accountId)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Get Account Data Entry

Retrieve a specific data entry stored on an account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getDataForAccount(accountId: "GABC...", key: "config")
switch response {
case .success(let data):
    print("Value: \(data.value)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Transaction Queries

Fetch transactions by hash, account, ledger, or related resources.

#### Get Single Transaction

Fetch a specific transaction by its hash.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.transactions.getTransactionDetails(transactionHash: "abc123hash...")
switch response {
case .success(let tx):
    print("Ledger: \(tx.ledger)")
    print("Fee paid: \(tx.feeCharged ?? "")")
    print("Operation count: \(tx.operationCount)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Transactions for Account

Get all transactions involving a specific account (as source or in any operation).

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.transactions.getTransactions(
    forAccount: "GABC...",
    order: .descending,
    limit: 20
)
switch response {
case .success(let page):
    for tx in page.records {
        print(tx.transactionHash)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Transactions by Related Resource

Find transactions related to a ledger, claimable balance, or liquidity pool.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Transactions in a specific ledger
let ledgerTxResponse = await sdk.transactions.getTransactions(forLedger: "12345678")

// Transactions affecting a claimable balance
let cbTxResponse = await sdk.transactions.getTransactions(forClaimableBalance: "00000000abc...")

// Transactions affecting a liquidity pool
let lpTxResponse = await sdk.transactions.getTransactions(forLiquidityPool: "poolid...")
```

### Operation Queries

Query operations by ID, account, transaction, or ledger.

#### Get Single Operation

Fetch a specific operation by its ID.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.operations.getOperationDetails(operationId: "123456789")
switch response {
case .success(let op):
    print("Transaction: \(op.transactionHash)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Operations for Account

Get all operations involving a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.operations.getOperations(
    forAccount: "GABC...",
    order: .descending,
    limit: 50
)
switch response {
case .success(let page):
    for op in page.records {
        print("\(op.id): \(op.operationTypeString)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Operations in Transaction

Get all operations within a specific transaction.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.operations.getOperations(forTransaction: "txhash...")
switch response {
case .success(let page):
    for op in page.records {
        print(op.operationTypeString)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Handling Operation Types

Operations are returned as specific response types based on their kind. Use `is` or `as?` to handle each type appropriately.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.operations.getOperations(forAccount: "GABC...")
switch response {
case .success(let page):
    for op in page.records {
        if let paymentOp = op as? PaymentOperationResponse {
            print("Payment: \(paymentOp.amount) to \(paymentOp.to)")
        } else if let createOp = op as? AccountCreatedOperationResponse {
            print("Account created: \(createOp.account)")
        } else if let trustOp = op as? ChangeTrustOperationResponse {
            print("Trustline changed for: \(trustOp.assetCode ?? "unknown")")
        } else if let sellOp = op as? ManageSellOfferOperationResponse {
            print("Offer: \(sellOp.amount) at \(sellOp.price)")
        } else if let pathOp = op as? PathPaymentStrictReceiveOperationResponse {
            print("Path payment: \(pathOp.sourceAmount) -> \(pathOp.amount)")
        }
        // Many other operation types available
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Effect Queries

Effects are the results of operations (account credited, trustline created, etc.).

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Effects for an account
let accountEffects = await sdk.effects.getEffects(
    forAccount: "GABC...",
    limit: 50
)

// Effects for a specific operation
let opEffects = await sdk.effects.getEffects(forOperation: "123456789")

switch accountEffects {
case .success(let page):
    for effect in page.records {
        print(effect.effectType)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Ledger & Payment Queries

Ledgers are blocks of transactions. The payments endpoint filters for payment-type operations only.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Ledgers
let ledgerResponse = await sdk.ledgers.getLedger(sequenceNumber: "12345678")
let ledgersResponse = await sdk.ledgers.getLedgers(order: .descending, limit: 10)

// Payments (Payment, PathPayment, CreateAccount, AccountMerge)
let paymentsResponse = await sdk.payments.getPayments(
    forAccount: "GABC..."
)
switch paymentsResponse {
case .success(let page):
    for payment in page.records {
        if let paymentOp = payment as? PaymentOperationResponse {
            print("Payment: \(paymentOp.amount)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Offer Queries

Query open offers on the DEX by account, asset, or sponsor.

#### Get Single Offer

Fetch a specific offer by its ID.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.offers.getOfferDetails(offerId: "12345")
switch response {
case .success(let offer):
    print("Selling: \(offer.amount) \(offer.selling.assetCode ?? "XLM")")
    print("Buying: \(offer.buying.assetCode ?? "XLM")")
    print("Price: \(offer.price)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Offers by Account

Get all open offers for a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.offers.getOffers(
    forAccount: "GABC...",
    limit: 50
)
switch response {
case .success(let page):
    for offer in page.records {
        print("\(offer.id): \(offer.amount) at \(offer.price)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Offers by Asset

Find all offers selling or buying a specific asset.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Find offers selling XLM for any asset
let offersResponse = await sdk.offers.getOffers(
    seller: nil,
    sellingAssetType: "native",
    buyingAssetType: "credit_alphanum4",
    buyingAssetCode: "USD",
    buyingAssetIssuer: "GISSUER..."
)
switch offersResponse {
case .success(let page):
    for offer in page.records {
        print("\(offer.id): \(offer.amount) at \(offer.price)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Offers by Sponsor

Find all offers sponsored by a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.offers.getOffers(
    seller: nil,
    sellingAssetType: "native",
    buyingAssetType: "native",
    sponsor: "GSPONSOR..."
)
switch response {
case .success(let page):
    for offer in page.records {
        print(offer.id)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Trade Queries

Query executed trades by account, asset pair, or offer.

#### Trades by Account

Get all trades involving a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.trades.getTrades(
    forAccount: "GABC...",
    order: .descending,
    limit: 50
)
switch response {
case .success(let page):
    for trade in page.records {
        print("\(trade.baseAmount) \(trade.baseAssetCode ?? "XLM")"
            + " for \(trade.counterAmount) \(trade.counterAssetCode ?? "XLM")")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Trades by Asset Pair

Get all trades between two specific assets. Useful for analyzing market activity.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.trades.getTrades(
    baseAssetType: "native",
    counterAssetType: "credit_alphanum4",
    counterAssetCode: "USD",
    counterAssetIssuer: "GISSUER...",
    order: .descending,
    limit: 50
)
switch response {
case .success(let page):
    for trade in page.records {
        print("\(trade.baseAmount) XLM for \(trade.counterAmount) USD")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Trades by Offer

Get all trades that filled a specific offer.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.trades.getTrades(offerId: "12345")
switch response {
case .success(let page):
    for trade in page.records {
        print("\(trade.baseAmount) at \(trade.price?.n ?? 0)/\(trade.price?.d ?? 1)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Trade Aggregations (OHLCV)

Get OHLCV (Open, High, Low, Close, Volume) candles for charting. Useful for building price charts and analyzing market trends.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Get hourly candles for a time range
let startTime = Int64(Date().addingTimeInterval(-24 * 60 * 60).timeIntervalSince1970 * 1000)
let endTime = Int64(Date().timeIntervalSince1970 * 1000)

let response = await sdk.tradeAggregations.getTradeAggregations(
    startTime: startTime,
    endTime: endTime,
    resolution: 3600000,    // 1 hour in ms
    baseAssetType: "native",
    counterAssetType: "credit_alphanum4",
    counterAssetCode: "USD",
    counterAssetIssuer: "GISSUER...",
    limit: 24
)
switch response {
case .success(let page):
    for candle in page.records {
        print("Open: \(candle.open)")
        print("High: \(candle.high)")
        print("Low: \(candle.low)")
        print("Close: \(candle.close)")
        print("Volume: \(candle.baseVolume)")
    }
case .failure(let error):
    print("Error: \(error)")
}

// Common resolutions (in milliseconds):
// 60000 (1 min), 300000 (5 min), 900000 (15 min),
// 3600000 (1 hour), 86400000 (1 day), 604800000 (1 week)
```

### Asset Queries

Look up assets by code or issuer. Useful for discovering all issuers of a token or all assets from an issuer.

#### Find by Code

Find all assets with a specific code. Different issuers can have the same asset code.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Find all USD assets (from different issuers)
let response = await sdk.assets.getAssets(for: "USD", limit: 20)
switch response {
case .success(let page):
    for asset in page.records {
        print("\(asset.assetCode ?? "") by \(asset.assetIssuer ?? "")")

        // Account statistics by authorization status
        print("Authorized holders: \(asset.accounts.authorized)")

        // Balance totals by authorization status
        print("Authorized supply: \(asset.balances.authorized)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Find by Issuer

Find all assets issued by a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.assets.getAssets(for: nil, assetIssuer: "GISSUER...")
switch response {
case .success(let page):
    for asset in page.records {
        let totalSupply = asset.balances.authorized
        print("\(asset.assetCode): \(totalSupply) total")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Order Book Queries

Get the current order book for an asset pair. Returns bids (buy orders) and asks (sell orders) sorted by price.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Get order book: people selling XLM for USD
let response = await sdk.orderbooks.getOrderbook(
    sellingAssetType: "native",
    buyingAssetType: "credit_alphanum4",
    buyingAssetCode: "USD",
    buyingAssetIssuer: "GISSUER..."
)
switch response {
case .success(let orderBook):
    // Bids: offers to buy the base asset (XLM)
    for bid in orderBook.bids {
        print("Bid: \(bid.amount) XLM at \(bid.price) USD")
    }

    // Asks: offers to sell the base asset (XLM)
    for ask in orderBook.asks {
        print("Ask: \(ask.amount) XLM at \(ask.price) USD")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Payment Path Queries

Find payment paths for cross-asset transfers. Used with path payment operations.

#### Strict Send Paths

Find paths when you know how much you want to send. Returns what the recipient can receive.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// "If I send 100 XLM, how much USD can the recipient get?"
let response = await sdk.paymentPaths.strictSend(
    sourceAmount: "100",
    sourceAssetType: "native",
    destinationAssets: "USD:GISSUER..."
)
switch response {
case .success(let paths):
    for path in paths.records {
        print("Send 100 XLM, receive \(path.destinationAmount) USD")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Strict Receive Paths

Find paths when you know how much the recipient needs. Returns what you need to send.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// "If recipient needs 100 USD, how much XLM do I send?"
let response = await sdk.paymentPaths.strictReceive(
    sourceAccount: "GSENDER...",
    destinationAssetType: "credit_alphanum4",
    destinationAssetCode: "USD",
    destinationAssetIssuer: "GISSUER...",
    destinationAmount: "100"
)
switch response {
case .success(let paths):
    for path in paths.records {
        print("Send \(path.sourceAmount) XLM to receive 100 USD")
    }
case .failure(let error):
    print("Error: \(error)")
}

// See "Path Payment Operations" section for how to use these paths
```

### Claimable Balance Queries

Find claimable balances you can claim, or look up a specific balance by ID.

#### Get Single Balance

Fetch a specific claimable balance by its ID.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Using hex format
let response = await sdk.claimableBalances.getClaimableBalance(
    balanceId: "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
)
switch response {
case .success(let balance):
    print("Amount: \(balance.amount)")
    print("Asset: \(balance.assetType)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Find by Claimant

Find all claimable balances that a specific account can claim.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.claimableBalances.getClaimableBalances(
    claimantAccountId: "GCLAIMER..."
)
switch response {
case .success(let page):
    for balance in page.records {
        print("\(balance.balanceId): \(balance.amount)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Find by Sponsor

Find all claimable balances sponsored by a specific account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.claimableBalances.getClaimableBalances(
    sponsorAccountId: "GSPONSOR..."
)
switch response {
case .success(let page):
    for balance in page.records {
        print(balance.balanceId)
    }
case .failure(let error):
    print("Error: \(error)")
}
```

#### Find by Asset

Find all claimable balances for a specific asset.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

let response = await sdk.claimableBalances.getClaimableBalances(asset: usdAsset)
switch response {
case .success(let page):
    for balance in page.records {
        print("\(balance.amount) \(balance.assetType)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Liquidity Pool Queries

Find liquidity pools by reserve assets or by account participation.

#### Get Single Pool

Fetch a specific liquidity pool by its ID.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.liquidityPools.getLiquidityPool(poolId: "poolid123...")
switch response {
case .success(let pool):
    print("Total shares: \(pool.totalShares)")
    print("Total trustlines: \(pool.totalTrustlines)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Find by Reserve Assets

Find pools containing specific reserve assets.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

let response = await sdk.liquidityPools.getLiquidityPools(
    reserveAssetA: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    reserveAssetB: usdAsset
)
switch response {
case .success(let page):
    for pool in page.records {
        print("Pool ID: \(pool.poolId)")
        print("Total shares: \(pool.totalShares)")
    }
case .failure(let error):
    print("Error: \(error)")
}
```

### Pagination

Navigate through large result sets using cursors. Each record has a paging token you can use to fetch the next page.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// First page
let response = await sdk.transactions.getTransactions(
    forAccount: "GABC...",
    order: .descending,
    limit: 20
)
switch response {
case .success(let page):
    // Process results
    for tx in page.records {
        print(tx.transactionHash)
    }

    // Get next page using cursor from last record
    if let lastRecord = page.records.last {
        let nextPageResponse = await sdk.transactions.getTransactions(
            forAccount: "GABC...",
            from: lastRecord.pagingToken,
            order: .descending,
            limit: 20
        )
        // Process next page...
    }
case .failure(let error):
    print("Error: \(error)")
}
```

---

## Streaming (SSE)

Get real-time updates via Server-Sent Events. The SDK wraps SSE connections as stream items with callback-based APIs. Use `cursor: "now"` to start from the current position rather than replaying historical data.

Always store the stream item reference and call `closeStream()` when you no longer need updates.

### Stream Payments

Stream payment-type operations (payments, path payments, create account, account merge) for an account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let streamItem = sdk.payments.stream(for: .paymentsForAccount(account: "GABC...", cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(let id, let operationResponse):
        if let payment = operationResponse as? PaymentOperationResponse {
            print("Payment: \(payment.amount) from \(payment.from) - id \(id)")
        } else if let pathPayment = operationResponse as? PathPaymentStrictReceiveOperationResponse {
            print("Path payment: \(pathPayment.amount)")
        }
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}

// Cancel when done
// streamItem.closeStream()
```

### Stream Transactions

Stream transactions for an account or all transactions on the network.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Stream transactions for a specific account
let streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: "GABC...", cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(let id, let transactionResponse):
        print("Transaction: \(transactionResponse.transactionHash) - id \(id)")
        print("Operations: \(transactionResponse.operationCount)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}

// Stream all transactions on the network
let allTxStream = sdk.transactions.stream(for: .allTransactions(cursor: "now"))
allTxStream.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let transactionResponse):
        print("New transaction in ledger \(transactionResponse.ledger)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

### Stream Ledgers

Stream ledger closes to track network progress.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let streamItem = sdk.ledgers.stream(for: .allLedgers(cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let ledgerResponse):
        print("Ledger \(ledgerResponse.sequenceNumber) closed")
        print("Transactions: \(ledgerResponse.successfulTransactionCount)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

### Stream Operations

Stream all operations for an account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let streamItem = sdk.operations.stream(for: .operationsForAccount(account: "GABC...", cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let operationResponse):
        print("Operation: \(operationResponse.operationTypeString)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

### Stream Effects

Stream effects (account credited, trustline created, etc.) for an account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let streamItem = sdk.effects.stream(for: .effectsForAccount(account: "GABC...", cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let effectResponse):
        print("Effect: \(effectResponse.effectType)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

### Stream Trades

Stream trades for an account or trading pair.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Stream trades for an account
let streamItem = sdk.trades.stream(for: .tradesForAccount(account: "GABC...", cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let tradeResponse):
        print("Trade: \(tradeResponse.baseAmount) for \(tradeResponse.counterAmount)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

### Stream Order Book

Stream order book updates for an asset pair.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let streamItem = sdk.orderbooks.stream(for: .orderbook(
    sellingAssetType: "native",
    sellingAssetCode: nil,
    sellingAssetIssuer: nil,
    buyingAssetType: "credit_alphanum4",
    buyingAssetCode: "USD",
    buyingAssetIssuer: "GISSUER...",
    limit: nil,
    cursor: "now"
))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let orderBookResponse):
        print("Bids: \(orderBookResponse.bids.count)")
        print("Asks: \(orderBookResponse.asks.count)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

### Stream Offers

Stream offer updates for an account.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let streamItem = sdk.offers.stream(for: .offersForAccount(account: "GABC...", cursor: "now"))
streamItem.onReceive { response in
    switch response {
    case .open:
        break
    case .response(_, let offerResponse):
        print("Offer \(offerResponse.id): \(offerResponse.amount) at \(offerResponse.price)")
    case .error(let error):
        print("Error: \(error?.localizedDescription ?? "unknown")")
    }
}
```

---

## Network Communication

Submit transactions, check fees, and handle network responses.

### Transaction Submission

Submit signed transactions to the network. The response includes the transaction hash and ledger number on success.

#### Synchronous Submission

The standard submission method waits for the transaction to be validated and included in a ledger before returning.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResponse {
case .success(let details):
    print("Hash: \(details.transactionHash)")
    print("Ledger: \(details.ledger ?? 0)")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination \(destinationAccountId) requires memo")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Asynchronous Submission

Submit without waiting for ledger inclusion. Returns immediately after Stellar Core accepts the transaction. Useful for high-throughput applications.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let asyncResponse = await sdk.transactions.submitAsyncTransaction(transaction: transaction)
switch asyncResponse {
case .success(let details):
    // Status: PENDING, DUPLICATE, TRY_AGAIN_LATER, or ERROR
    print("Status: \(details.txStatus)")
    print("Hash: \(details.txHash)")

    if details.txStatus == "PENDING" {
        // Transaction accepted - poll for result later
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        let txResponse = await sdk.transactions.getTransactionDetails(transactionHash: details.txHash)
        switch txResponse {
        case .success(let tx):
            print("Transaction confirmed in ledger \(tx.ledger)")
        case .failure(let error):
            if case .notFound = error {
                // Not yet ingested - retry later
            }
        }
    }
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination \(destinationAccountId) requires memo")
case .failure(let error):
    print("Error: \(error)")
}
```

### Fee Statistics

Query current network fee levels to set appropriate fees for your transactions. All values are in stroops (1 XLM = 10,000,000 stroops).

#### Fee Charged Statistics

Get statistics on fees actually charged in recent ledgers.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.feeStats.getFeeStats()
switch response {
case .success(let feeStats):
    // Fees actually charged in recent transactions
    print("Min fee charged: \(feeStats.feeCharged.min) stroops")
    print("Mode fee charged: \(feeStats.feeCharged.mode) stroops")
    print("P90 fee charged: \(feeStats.feeCharged.p90) stroops")
case .failure(let error):
    print("Error: \(error)")
}
```

#### Max Fee Statistics

Get statistics on maximum fees users were willing to pay.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.feeStats.getFeeStats()
switch response {
case .success(let feeStats):
    // Max fees users set (what they were willing to pay)
    print("Min max fee: \(feeStats.maxFee.min) stroops")
    print("Mode max fee: \(feeStats.maxFee.mode) stroops")
    print("P90 max fee: \(feeStats.maxFee.p90) stroops")

    // Network capacity and base fee
    print("Base fee: \(feeStats.lastLedgerBaseFee) stroops")
    print("Capacity usage: \(feeStats.ledgerCapacityUsage)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Error Handling

When transactions fail, Horizon returns detailed error information including result codes for the transaction and each operation.

#### Handling Submission Errors

Check the response for success or failure after submitting a transaction.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResponse {
case .success(let details):
    print("Success! Hash: \(details.transactionHash)")
case .destinationRequiresMemo(let destinationAccountId):
    print("Destination \(destinationAccountId) requires memo")
case .failure(let error):
    // Transaction failed - inspect the error
    print("Transaction failed: \(error)")
}
```

#### Horizon HTTP Errors

Handle HTTP-level errors when querying Horizon.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccountDetails(accountId: "GABC...")
switch response {
case .success(let account):
    print("Found account: \(account.accountId)")
case .failure(let error):
    switch error {
    case .notFound(_, _):
        print("Account not found (404)")
    case .requestFailed(let message, _):
        print("Request failed: \(message)")
    default:
        print("Horizon error: \(error)")
    }
}
```

#### Common Result Codes

**Transaction-level codes:**
- `tx_success` -- Transaction succeeded
- `tx_failed` -- One or more operations failed
- `tx_bad_seq` -- Sequence number mismatch (reload account and retry)
- `tx_insufficient_fee` -- Fee too low for current network load
- `tx_insufficient_balance` -- Not enough XLM to cover fee + reserves

**Operation-level codes:**
- `op_success` -- Operation succeeded
- `op_underfunded` -- Not enough balance for payment
- `op_no_trust` -- Destination missing trustline for asset
- `op_line_full` -- Destination trustline limit exceeded
- `op_low_reserve` -- Would leave account below minimum reserve

### Message Signing (SEP-53)

Sign and verify arbitrary messages with Stellar keypairs following the [SEP-53](sep/sep-53.md) specification. Useful for authentication and proving ownership of an account without creating a transaction.

#### Sign a Message

Create a cryptographic signature for any text using your secret key.

```swift
import Foundation
import stellarsdk

let keyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV")

// Sign a message
let message = "Please sign this message to verify your identity"
let signature = try! keyPair.signMessage(message)

// Encode signature for transmission (e.g., in HTTP header or JSON)
let signatureBase64 = Data(signature).base64EncodedString()
print("Signature: \(signatureBase64)")
```

#### Verify a Message

Confirm a signature matches the message and was created by a specific account.

```swift
import Foundation
import stellarsdk

// Verify with the signing keypair
let keyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV")

let message = "Please sign this message to verify your identity"
let signature = try! keyPair.signMessage(message)

let isValid = try! keyPair.verifyMessage(message, signature: signature)
if isValid {
    print("Signature is valid")
}
```

#### Verify with Public Key Only

When verifying, you only need the public key (account ID). This is typical for server-side verification.

```swift
import Foundation
import stellarsdk

// Only have the public key (account ID)
let publicKey = try! KeyPair(accountId: "GABC...")

// Signature received from client (base64 encoded)
let signatureBase64 = "..."
let signatureData = Data(base64Encoded: signatureBase64)!
let signature = [UInt8](signatureData)

let message = "Please sign this message to verify your identity"
let isValid = try! publicKey.verifyMessage(message, signature: signature)

if isValid {
    print("User owns this account")
}
```

---

## Assets

Stellar supports native XLM and custom assets issued by accounts. Asset codes are 1-4 characters (alphanumeric4) or 5-12 characters (alphanumeric12). Every custom asset is uniquely identified by its code plus issuer account.

### Native XLM

The native asset (XLM) has no issuer and doesn't require a trustline.

```swift
import stellarsdk

let xlm = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
```

### Credit Assets

Custom assets issued by Stellar accounts. Use `AssetType.ASSET_TYPE_CREDIT_ALPHANUM4` for 1-4 character codes or `AssetType.ASSET_TYPE_CREDIT_ALPHANUM12` for 5-12 character codes.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")

// 1-4 character code
let usd = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!
let btc = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "BTC", issuer: issuerKeyPair)!

// 5-12 character code
let myToken = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "MYTOKEN", issuer: issuerKeyPair)!
```

### Auto-Detect Code Length

Use the canonical form initializer to automatically choose the correct type based on code length.

```swift
import stellarsdk

// Automatically creates the correct asset type based on code length
let usd = Asset(canonicalForm: "USD:GISSUER...")!

let myToken = Asset(canonicalForm: "MYTOKEN:GISSUER...")!
```

### Canonical Form

Convert assets to/from canonical string format (`CODE:ISSUER`). Useful for storage, display, configuration, and SEP protocols like [SEP-38](sep/sep-38.md) (Anchor RFQ API).

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usd = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Convert to canonical string
let canonical = usd.toCanonicalForm()  // "USD:GISSUER..."

// Parse from canonical string
let asset = Asset(canonicalForm: "USD:GISSUER...")

// Native asset canonical form
let xlmCanonical = Asset(type: AssetType.ASSET_TYPE_NATIVE)!.toCanonicalForm()  // "native"
```

### Pool Share Assets

Liquidity pool share assets represent ownership in an AMM pool. Created from the two reserve assets.

```swift
import stellarsdk

let issuerKeyPair = try! KeyPair(accountId: "GISSUER...")
let usdAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerKeyPair)!

// Create pool share asset (assets must be in lexicographic order)
let poolShareAsset = try! ChangeTrustAsset(assetA: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, assetB: usdAsset)!
```

### Trustlines

Before receiving a custom asset, an account must create a trustline for it. Trustlines specify which assets the account accepts and set optional limits.

For detailed trustline operations (create, modify, remove, authorize), see [Asset Operations](#asset-operations) in the Operations chapter.

---

## Soroban (Smart Contracts)

Soroban is Stellar's smart contract platform. Smart contract transactions differ from classic transactions: they require a simulation step to determine resource requirements and fees before submission.

For complete documentation, see the dedicated [Soroban Guide](soroban.md).

### Quick Example

Deploy a contract and call a method with minimal setup.

```swift
import Foundation
import stellarsdk

let keyPair = try! KeyPair(secretSeed: "SXXX...")
let rpcUrl = "https://soroban-testnet.stellar.org:443"

// Install WASM and deploy contract
let wasmBytes: Data = ... // load your contract WASM bytes
let wasmHash = try await SorobanClient.install(
    installRequest: InstallRequest(
        rpcUrl: rpcUrl,
        network: Network.testnet,
        sourceAccountKeyPair: keyPair,
        wasmBytes: wasmBytes,
        enableServerLogging: false
    )
)

let client = try await SorobanClient.deploy(
    deployRequest: DeployRequest(
        rpcUrl: rpcUrl,
        network: Network.testnet,
        sourceAccountKeyPair: keyPair,
        wasmHash: wasmHash,
        enableServerLogging: false
    )
)

// Invoke contract method
let result = try await client.invokeMethod(
    name: "hello",
    args: [SCValXDR.forSymbol("World")]
)
print("\(result.vec![0].sym!), \(result.vec![1].sym!)") // Hello, World
```

### Soroban RPC Server

Direct communication with Soroban RPC nodes for low-level operations.

```swift
import stellarsdk

let server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org:443")

// Check server health
let healthResponse = await server.getHealth()
switch healthResponse {
case .success(let health):
    if health.status == "healthy" {
        print("Soroban RPC is healthy")
    }
case .rpcFailure(let error):
    print("RPC error: \(error)")
case .parsingFailure(let error):
    print("Parse error: \(error)")
}

// Get latest ledger
let ledgerResponse = await server.getLatestLedger()
switch ledgerResponse {
case .success(let ledger):
    print("Latest ledger: \(ledger.sequence)")
case .rpcFailure(let error):
    print("RPC error: \(error)")
case .parsingFailure(let error):
    print("Parse error: \(error)")
}
```

### What's Covered in the Soroban Guide

The [Soroban Guide](soroban.md) covers:

- **SorobanServer** -- Direct RPC communication, contract data queries
- **SorobanClient** -- High-level contract interaction API
- **Installing & Deploying** -- WASM installation and contract deployment
- **AssembledTransaction** -- Transaction lifecycle with simulation
- **Authorization** -- Signing auth entries for contract calls
- **Type Conversions** -- SCValXDR creation and parsing
- **Events** -- Reading contract events
- **Error Handling** -- Simulation and submission errors

---

## Further Reading

- [Quick Start Guide](quick-start.md) -- First transaction in 15 minutes
- [Getting Started](getting-started.md) -- Installation and fundamentals
- [Soroban Guide](soroban.md) -- Smart contract development
- [SEP Protocols](sep/README.md) -- Stellar Ecosystem Proposals

---

**Navigation:** [Getting Started](getting-started.md) | [Soroban Guide](soroban.md)
