# SEP-02: Federation protocol

Federation allows users to send payments using human-readable addresses like `bob*example.com` instead of raw account IDs like `GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ`. It also enables organizations to map bank accounts or other external identifiers to Stellar accounts.

**When to use:** Building a wallet that supports sending payments to Stellar addresses, or implementing a service that resolves external identifiers (bank accounts, phone numbers) to Stellar accounts.

See the [SEP-02 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) for protocol details.

## Address format

A Stellar address has two parts: `username*domain.com`
- **Username:** Any printable UTF-8 except `*` and `>` (emails and phone numbers are allowed)
- **Domain:** Any valid RFC 1035 domain name

Examples: `bob*example.com`, `alice@gmail.com*stellar.org`, `+14155550100*bank.com`

## How address resolution works

When you resolve a Stellar address like `bob*example.com`, this happens:

1. **Parse the address** - Split on `*` to get username (`bob`) and domain (`example.com`)
2. **Fetch stellar.toml** - Download `https://example.com/.well-known/stellar.toml`
3. **Find federation server** - Extract the `FEDERATION_SERVER` URL from the TOML
4. **Query federation server** - Make GET request: `FEDERATION_SERVER/federation?q=bob*example.com&type=name`
5. **Get account details** - Server returns account ID and optional memo

The SDK handles this entire flow automatically with `Federation.resolve(stellarAddress:)`.

**Note:** Federation servers may rate-limit requests. If you're making many lookups, consider caching responses appropriately (but remember that some services use ephemeral account IDs, so cache duration should be short).

## Quick example

Resolve a Stellar address to get the destination account ID for a payment. This single method call handles the entire federation lookup process, including fetching the stellar.toml and querying the federation server.

```swift
import stellarsdk

// Resolve a Stellar address to an account ID
let result = await Federation.resolve(stellarAddress: "bob*soneso.com")

switch result {
case .success(let response):
    print("Account: \(response.accountId ?? "nil")")
    print("Memo: \(response.memo ?? "none")")
case .failure(let error):
    print("Resolution failed: \(error)")
}
```

## Resolving Stellar addresses

Convert a Stellar address to an account ID and optional memo. The memo is important because some services (like exchanges) use a single Stellar account for all users and require a memo to identify the recipient.

```swift
import stellarsdk

let result = await Federation.resolve(stellarAddress: "bob*soneso.com")

switch result {
case .success(let response):
    // The destination account for payments
    let accountId = response.accountId
    print("Account ID: \(accountId ?? "nil")")
    // GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI

    // Include memo if provided (required for some destinations)
    let memo = response.memo
    let memoType = response.memoType

    if let memo = memo {
        print("Memo (\(memoType ?? "unknown")): \(memo)")
    }

    // Original address for confirmation
    let address = response.stellarAddress
    print("Address: \(address ?? "nil")")
    // bob*soneso.com
case .failure(let error):
    print("Resolution failed: \(error)")
}
```

**Important:** Don't cache federation responses. Some services use random account IDs for privacy, which may change over time.

## Reverse lookup (account ID to address)

Find the Stellar address associated with an account ID. Unlike forward lookups, reverse lookups require you to know which federation server to query since the account ID doesn't contain domain information.

```swift
import stellarsdk

let accountId = "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI"
let federationServer = "https://stellarid.io/federation/"

let federation = Federation(federationAddress: federationServer)
let result = await federation.resolve(account_id: accountId)

switch result {
case .success(let response):
    print("Address: \(response.stellarAddress ?? "unknown")")
    // bob*soneso.com
case .failure(let error):
    print("Reverse lookup failed: \(error)")
}
```

## Transaction lookup

Query a federation server to get information about who sent a transaction. This is useful for identifying the sender of an incoming payment when the federation server supports transaction lookups.

```swift
import stellarsdk

let txId = "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a"
let federationServer = "https://stellarid.io/federation/"

let federation = Federation(federationAddress: federationServer)
// Returns federation record of the sender if known
let result = await federation.resolve(transaction_id: txId)

switch result {
case .success(let response):
    if let sender = response.stellarAddress {
        print("Sender: \(sender)")
    }
case .failure(let error):
    print("Transaction lookup failed: \(error)")
}
```

## Forward federation

Forward federation maps external identifiers (bank accounts, routing numbers, etc.) to Stellar accounts. Use this to pay someone who doesn't have a Stellar address but has another type of account that an anchor supports.

```swift
import stellarsdk

// Pay to a bank account via an anchor
var params = Dictionary<String, String>()
params["forward_type"] = "bank_account"
params["swift"] = "BOPBPHMM"
params["acct"] = "2382376"

let federationServer = "https://stellarid.io/federation/"
let federation = Federation(federationAddress: federationServer)
let result = await federation.resolve(forwardParams: params)

switch result {
case .success(let response):
    print("Deposit to: \(response.accountId ?? "nil")")

    // Use the memo to identify the recipient
    if let memo = response.memo {
        print("Memo (\(response.memoType ?? "unknown")): \(memo)")
    }
case .failure(let error):
    print("Forward federation failed: \(error)")
}
```

## Building a payment with federation

This complete example shows how to send a payment using a Stellar address. It resolves the recipient's address, builds a transaction with the appropriate memo, and submits it to the network.

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

// Sender's keypair
let senderKeyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CPMLIHJPFV5RXN5M6CSS")
let senderAccountId = senderKeyPair.accountId

// Resolve recipient's Stellar address
let recipient = "alice*testanchor.stellar.org"
let fedResult = await Federation.resolve(stellarAddress: recipient)

guard case .success(let fedResponse) = fedResult else {
    print("Federation resolution failed")
    return
}
guard let destinationId = fedResponse.accountId else {
    print("No account ID in federation response")
    return
}

// Load sender account
let accResult = await sdk.accounts.getAccountDetails(accountId: senderAccountId)
guard case .success(let accountResponse) = accResult else {
    print("Failed to load sender account")
    return
}

// Build payment operation
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: destinationId,
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10
)

// Build transaction
let sourceAccount = try Account(
    accountId: accountResponse.accountId,
    sequenceNumber: accountResponse.sequenceNumber
)

// Attach memo if federation response requires it
var memo: Memo = Memo.none
if let memoType = fedResponse.memoType, let memoValue = fedResponse.memo {
    switch memoType {
    case "text":
        memo = Memo.text(memoValue)
    case "id":
        if let memoId = UInt64(memoValue) {
            memo = Memo.id(memoId)
        }
    case "hash":
        // Hash memo values are base64-encoded in federation responses
        if let memoData = Data(base64Encoded: memoValue) {
            memo = try Memo.hash(memoData)
        }
    default:
        break
    }
}

let transaction = try Transaction(
    sourceAccount: sourceAccount,
    operations: [paymentOp],
    memo: memo,
    maxOperationFee: 100
)
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResult {
case .success(_):
    print("Payment sent to \(recipient)")
case .destinationRequiresMemo(let accountId):
    print("Destination \(accountId) requires a memo")
case .failure(let error):
    print("Payment failed: \(error)")
}
```

## Error handling

Federation lookups can fail for various reasons. This example demonstrates how to handle the most common error scenarios: invalid address format, missing federation server configuration, and unknown users.

```swift
import stellarsdk

// Invalid address format (missing *)
// Returns .failure immediately without making network requests
let invalidResult = await Federation.resolve(stellarAddress: "invalid-no-asterisk")
switch invalidResult {
case .success(_):
    break
case .failure(let error):
    print("Invalid format: \(error)")
    // error is .invalidAddress
}

// Domain without federation server configured in stellar.toml
// Returns .failure when stellar.toml doesn't contain FEDERATION_SERVER
let noFedResult = await Federation.resolve(stellarAddress: "user*domain-without-federation.com")
switch noFedResult {
case .success(_):
    break
case .failure(let error):
    print("No federation server: \(error)")
}

// User not found or federation server error
let notFoundResult = await Federation.resolve(stellarAddress: "nonexistent*soneso.com")
switch notFoundResult {
case .success(let response):
    print("Account: \(response.accountId ?? "nil")")
case .failure(let error):
    print("Federation error: \(error)")
}
```

### Error summary

| Error | When Returned |
|-------|------------|
| `.invalidAddress` | Address doesn't contain exactly one `*` character |
| `.noFederationSet` | Domain's stellar.toml doesn't have `FEDERATION_SERVER` |
| `.horizonError` | Federation server returns HTTP error (404, 500, etc.) |

## Finding the federation server

Each domain publishes its federation server URL in stellar.toml. The `resolve(stellarAddress:)` method does this lookup automatically, but you can also fetch it directly when needed for reverse lookups or manual queries.

```swift
import stellarsdk

// Get federation server URL from stellar.toml
let domainResult = await Federation.forDomain(domain: "soneso.com")
switch domainResult {
case .success(let federation):
    print("Federation Server: \(federation.federationAddress)")
    // https://stellarid.io/federation/
case .failure(let error):
    print("Failed to discover federation server: \(error)")
}
```

**Note:** `Federation.resolve(stellarAddress:)` does this lookup automatically. You only need this for reverse lookups or when querying the federation server directly.

## ResolveAddressResponse properties

The `ResolveAddressResponse` object contains all the information returned by the federation server:

| Field | Type | Description |
|-------|------|-------------|
| `stellarAddress` | `String?` | Stellar address in `user*domain.com` format |
| `accountId` | `String?` | Stellar account ID (G-address) for payments |
| `memoType` | `String?` | Memo type: `text`, `id`, or `hash` |
| `memo` | `String?` | Memo value to include with payment |

**Note on hash memos:** When `memoType` is `hash`, the memo value is base64-encoded. Decode it before creating a `Memo.hash()`. This is necessary because `Memo.hash()` expects raw `Data` (exactly 32 bytes), not a base64 string. The federation server encodes the binary hash as base64 for safe JSON transport.

## Testing with mocks

Use the `ServerMock`/`RequestMock`/`ResponsesMock` infrastructure to test federation lookups without real network calls. For `resolve(stellarAddress:)`, the mock must handle two request paths: the stellar.toml fetch and the federation query.

```swift
import XCTest
import stellarsdk

// Register the ServerMock URL protocol
URLProtocol.registerClass(ServerMock.self)

// Mock the stellar.toml response
let tomlMock = FederationTomlMock(
    domain: "example.com",
    federationServer: "https://api.example.com/federation"
)

// Mock the federation server response
let federationMock = FederationResponseMock(host: "api.example.com")

// Now resolve using the mocked responses
let result = await Federation.resolve(stellarAddress: "alice*example.com")

switch result {
case .success(let response):
    print("Account: \(response.accountId ?? "nil")")
    print("Memo: \(response.memo ?? "none")")
case .failure(let error):
    XCTFail("Resolution failed: \(error)")
}
```

## Related SEPs

- [SEP-01 stellar.toml](sep-01.md) - Where the `FEDERATION_SERVER` URL is published
- [SEP-10 Authentication](sep-10.md) - Some federation servers may require authentication

---

[Back to SEP Overview](README.md)
