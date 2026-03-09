# SEP-08: Regulated Assets

SEP-08 defines a protocol for assets that require issuer approval for every transaction. These "regulated assets" enable compliance with securities laws, KYC/AML requirements, velocity limits, and jurisdiction-based restrictions.

**Use SEP-08 when:**
- Transacting with assets marked as `regulated=true` in stellar.toml
- Working with securities tokens or compliance-controlled assets
- Building wallets that support regulated asset transfers

**How it works:** Before submitting a transaction involving a regulated asset to the Stellar network, you must first submit it to the issuer's approval server. The server evaluates the transaction against compliance rules and, if approved, signs it with the issuer's key.

**Spec:** [SEP-0008 v1.7.4](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md)

## Quick example

This example shows the basic flow: discovering a regulated asset and submitting a transaction for approval:

```swift
import stellarsdk

// Create service from anchor domain - loads stellar.toml automatically
let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }

// Get regulated assets defined in stellar.toml
let regulatedAssets = service.regulatedAssets
print("Found \(regulatedAssets.count) regulated asset(s)")

// Submit a transaction for approval
let signedTxXdr = "AAAAAgAAAA..." // Your signed transaction as base64 XDR
let response = await service.postTransaction(
    txB64Xdr: signedTxXdr,
    apporvalServer: regulatedAssets.first!.approvalServer
)

switch response {
case .success(let successResponse):
    print("Approved! Submit this transaction: \(successResponse.tx)")
case .rejected(let rejectedResponse):
    print("Rejected: \(rejectedResponse.error)")
default:
    break
}
```

## How regulated assets work

Per SEP-08, regulated assets require a specific setup and workflow:

1. **Issuer flags**: Asset issuer account has `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags set. This allows the issuer to grant and revoke transaction authorization atomically.
2. **stellar.toml discovery**: The issuer's stellar.toml (SEP-01) defines the asset as `regulated=true` and specifies an `approval_server` URL.
3. **Transaction composition**: Transactions are structured with operations that authorize accounts, perform the transfer, and deauthorize accounts—all atomically. Wallets can either submit simple payment transactions and let the approval server add the authorization operations (returning a `revised` transaction), or build compliant transactions manually using `SetTrustlineFlagsOperation`.
4. **Approval flow**: Wallet submits the signed transaction to the approval server (not the Stellar network). Note that approval servers must support CORS to allow browser-based wallets to interact with them directly.
5. **Compliance check**: The server evaluates the transaction against its regulatory rules.
6. **Signing**: If approved, the server signs and returns the transaction.
7. **Network submission**: Wallet submits the fully-signed transaction to the Stellar network.

## Creating the service

### From domain

Load stellar.toml from the issuer's domain and extract all regulated asset definitions:

```swift
import stellarsdk

// Loads stellar.toml and extracts regulated assets
let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)

switch serviceResult {
case .success(let service):
    // Access discovered regulated assets
    for asset in service.regulatedAssets {
        print("\(asset.assetCode) issued by \(asset.issuerId)")
    }
case .failure(let error):
    print("Failed to create service: \(error)")
}
```

### From StellarToml data

If you've already loaded the stellar.toml data, pass it directly to the constructor. The stellar.toml must contain a `NETWORK_PASSPHRASE` field:

```swift
import stellarsdk

let toml = try StellarToml(fromString: tomlString)
let service = try RegulatedAssetsService(tomlData: toml)
```

### With custom Horizon URL

You can provide a custom Horizon URL when initializing the service. Useful for custom network configurations:

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    horizonUrl: "https://custom-horizon.example.com",
    network: Network.testnet
)
```

### Service properties

After initialization, the service exposes these properties:

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }

// List of RegulatedAsset objects discovered from stellar.toml
let assets = service.regulatedAssets

// The StellarToml data used to initialize the service
let tomlData = service.tomlData

// The configured StellarSDK instance (for Horizon requests)
let sdk = service.sdk

// The network (used for transaction signing context)
let network = service.network
```

## Discovering regulated assets

The `RegulatedAsset` class extends `Asset`, so it can be used wherever a standard asset is expected. It adds approval server information required for the compliance workflow:

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }

for asset in service.regulatedAssets {
    // Standard asset properties (inherited from Asset)
    print("Asset: \(asset.assetCode)")
    print("Issuer: \(asset.issuerId)")

    // SEP-08 specific properties
    print("Approval server: \(asset.approvalServer)")

    if let criteria = asset.approvalCriteria {
        print("Criteria: \(criteria)")
    }
}
```

## Checking authorization requirements

Before transacting, verify the issuer account has proper authorization flags set. Per SEP-08, regulated asset issuers must have both `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags enabled:

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }
let asset = service.regulatedAssets.first!

// Checks that issuer has AUTH_REQUIRED and AUTH_REVOCABLE flags
let authResult = await service.authorizationRequired(asset: asset)

switch authResult {
case .success(let required):
    if required {
        print("Asset requires approval server for all transactions")
    } else {
        print("Warning: Issuer flags not properly configured for regulated assets")
    }
case .failure(let error):
    print("Failed to check issuer flags: \(error)")
}
```

## Building a transaction for approval

Create and sign your transaction normally, then submit the base64-encoded XDR to the approval server:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }
let regulatedAsset = service.regulatedAssets.first!

// Sender's keypair
let senderKeyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG...")
let accountResult = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let senderAccount) = accountResult else { return }

// Build the payment transaction using the regulated asset
let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GDEST...",
    asset: regulatedAsset,
    amount: Decimal(100)
)

let transaction = try Transaction(
    sourceAccount: senderAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)

// Sign with sender's key
try transaction.sign(keyPair: senderKeyPair, network: Network.testnet)

// Convert to base64 XDR for submission to approval server
let txXdr = try transaction.encodedEnvelope()
let response = await service.postTransaction(
    txB64Xdr: txXdr,
    apporvalServer: regulatedAsset.approvalServer
)
```

### Multiple regulated assets

When a transaction involves multiple regulated assets from different issuers (e.g., a path payment through several assets), each issuer's approval server must sign the transaction. Submit the transaction to each approval server sequentially, using the signed output from one server as input to the next. All issuers must approve before the transaction can be submitted to the Stellar network.

## Handling approval responses

The approval server returns one of five response types. Use a `switch` statement on the `PostSep08TransactionEnum` result to determine the response type and handle it:

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }
let response = await service.postTransaction(
    txB64Xdr: txXdr,
    apporvalServer: approvalServer
)

switch response {
case .success(let successResponse):
    // Transaction approved and signed by issuer - submit to network
    print("Approved!")
    if let message = successResponse.message {
        print("Message: \(message)")
    }
    let approvedTx = try Transaction(envelopeXdr: successResponse.tx)
    let submitResult = await sdk.transactions.submitTransaction(transaction: approvedTx)

case .revised(let revisedResponse):
    // Transaction was modified for compliance - REVIEW CAREFULLY before submitting
    print("Revised for compliance: \(revisedResponse.message)")
    // WARNING: Always inspect the revised transaction to ensure it matches your intent
    // The issuer may have added operations (fees, compliance ops) but should not change
    // the core intent of your transaction

case .pending(let pendingResponse):
    // Approval pending - retry after the timeout period
    // Note: timeout is in SECONDS per the SDK
    let timeoutSec = pendingResponse.timeout
    print("Pending. Check again in \(timeoutSec) seconds")
    if let message = pendingResponse.message {
        print("Message: \(message)")
    }

case .actionRequired(let actionResponse):
    // User action needed - see "Handling Action Required" section
    print("Action required: \(actionResponse.message)")
    print("Action URL: \(actionResponse.actionUrl)")

case .rejected(let rejectedResponse):
    // Transaction rejected - cannot be made compliant
    print("Rejected: \(rejectedResponse.error)")

case .failure(let error):
    // Network or parsing error
    print("Request failed: \(error)")
}
```

### Response types reference

| Response Case | Status | HTTP Code | Meaning |
|---------------|--------|-----------|---------|
| `.success` | `success` | 200 | Approved and signed -- submit to network |
| `.revised` | `revised` | 200 | Modified for compliance -- review before submitting |
| `.pending` | `pending` | 200 | Check back after `timeout` seconds |
| `.actionRequired` | `action_required` | 200 | User must complete action at URL |
| `.rejected` | `rejected` | 400 | Denied -- see error message |
| `.failure` | n/a | n/a | Network or parsing error |

## Handling action required

When the approval server needs additional information (KYC data, terms acceptance, etc.), it returns an `actionRequired` status. The SDK provides `postAction()` to submit the required data:

```swift
import stellarsdk

let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }
let response = await service.postTransaction(
    txB64Xdr: txXdr,
    apporvalServer: approvalServer
)

if case .actionRequired(let actionResponse) = response {
    print("Action needed: \(actionResponse.message)")

    // Check what SEP-9 KYC fields are requested
    if let actionFields = actionResponse.actionFields {
        print("Requested fields:")
        for field in actionFields {
            print("  - \(field)")
        }
    }

    // Handle based on action method (GET or POST)
    if actionResponse.actionMethod == "POST" {
        // Submit fields programmatically if you have them
        let actionResult = await service.postAction(
            url: actionResponse.actionUrl,
            actionFields: [
                "email_address": "user@example.com",
                "mobile_number": "+1234567890",
            ]
        )

        switch actionResult {
        case .done:
            // Action complete - resubmit the original transaction
            print("Action complete. Resubmitting transaction...")
            let retryResponse = await service.postTransaction(
                txB64Xdr: txXdr,
                apporvalServer: approvalServer
            )
            // Handle retryResponse...

        case .nextUrl(let nextUrlResponse):
            // More steps needed - user must complete action in browser
            print("Further action required at: \(nextUrlResponse.nextUrl)")
            if let message = nextUrlResponse.message {
                print("Message: \(message)")
            }

        case .failure(let error):
            print("Action submission failed: \(error)")
        }
    } else {
        // action_method is GET (or not specified) - open URL in browser
        // You can append action fields as query parameters
        print("Open in browser: \(actionResponse.actionUrl)")
    }
}
```

## Complete workflow example

This example shows the full approval flow for a regulated asset transfer, including all response type handling:

```swift
import stellarsdk

// Setup
let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)
guard case .success(let service) = serviceResult else { return }
let sdk = service.sdk
let regulatedAsset = service.regulatedAssets.first!

let senderKeyPair = try! KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG...")
let recipientId = "GDESTINATION..."

// Verify asset requires approval (issuer has proper flags)
let authResult = await service.authorizationRequired(asset: regulatedAsset)
switch authResult {
case .success(let required):
    if !required {
        print("Asset issuer not properly configured for regulation")
        return
    }
case .failure(let error):
    print("Failed to check authorization: \(error)")
    return
}

// Build transaction
let accountResult = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
guard case .success(let senderAccount) = accountResult else { return }

let paymentOp = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: recipientId,
    asset: regulatedAsset,
    amount: Decimal(100)
)

let transaction = try Transaction(
    sourceAccount: senderAccount,
    operations: [paymentOp],
    memo: Memo.none,
    maxOperationFee: 100
)

try transaction.sign(keyPair: senderKeyPair, network: service.network)
let txXdr = try transaction.encodedEnvelope()

// Submit for approval
let response = await service.postTransaction(
    txB64Xdr: txXdr,
    apporvalServer: regulatedAsset.approvalServer
)

// Handle response
var approvedTx: String? = nil

switch response {
case .success(let successResponse):
    approvedTx = successResponse.tx

case .revised(let revisedResponse):
    // IMPORTANT: Review revised transaction before accepting
    // The message should explain what was modified
    print("Transaction revised: \(revisedResponse.message)")
    approvedTx = revisedResponse.tx

case .pending(let pendingResponse):
    // Timeout is in seconds
    print("Try again in \(pendingResponse.timeout) seconds")

case .actionRequired(let actionResponse):
    print("User action needed at: \(actionResponse.actionUrl)")

case .rejected(let rejectedResponse):
    print("Transaction rejected: \(rejectedResponse.error)")

case .failure(let error):
    print("Request failed: \(error)")
}

// Submit approved transaction to Stellar network
if let approvedTxXdr = approvedTx {
    let approvedTransaction = try Transaction(envelopeXdr: approvedTxXdr)
    let submitResult = await sdk.transactions.submitTransaction(transaction: approvedTransaction)
    if case .success(let details) = submitResult {
        print("Transaction submitted: \(details.transactionHash)")
    }
}
```

## Error handling

The SDK uses result enums for different error conditions:

```swift
import stellarsdk

// Service initialization errors
let serviceResult = await RegulatedAssetsService.forDomain(
    domain: "https://regulated-asset-issuer.com",
    network: Network.testnet
)

switch serviceResult {
case .success(let service):
    // Service created successfully
    let response = await service.postTransaction(
        txB64Xdr: txXdr,
        apporvalServer: approvalServer
    )

    switch response {
    case .failure(let error):
        // Network or parsing error from approval server
        switch error {
        case .parsingResponseFailed(let message):
            // Approval server returned an unrecognized status value
            print("Unknown server response: \(message)")
        case .requestFailed(_, let message):
            print("Network error: \(message ?? "unknown")")
        default:
            print("Error: \(error)")
        }
    default:
        break
    }

case .failure(let error):
    switch error {
    case .invalidDomain:
        // Domain string is not a valid URL (must include scheme, e.g. "https://")
        print("Invalid domain URL")
    case .invalidToml:
        // stellar.toml is missing, unparseable, or missing NETWORK_PASSPHRASE
        print("Invalid or missing stellar.toml")
    default:
        print("Service error: \(error)")
    }
}
```

### Error reference

| Error Type | When Returned |
|-----------|-------------|
| `RegulatedAssetsServiceError.invalidDomain` | Domain string cannot form a valid URL |
| `RegulatedAssetsServiceError.invalidToml` | stellar.toml fetch/parse failed, or missing required fields |
| `HorizonRequestError.parsingResponseFailed` | Approval server returned an unrecognized response |
| `HorizonRequestError.requestFailed` | Network error communicating with approval server |

## Security considerations

### Reviewing revised transactions

When you receive a `revised` response, **always inspect the transaction before submitting**. Per SEP-08, the approval server should only add operations (like authorization ops), not modify your original operations' intent. However, malicious servers could attempt to:

- Add operations that spend funds from your account
- Change payment destinations or amounts
- Add unexpected fees

Best practice: Compare the revised transaction with your original to ensure only expected operations were added.

### Authorization flags

The `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags on the issuer account are required for security. They ensure:
- No one can transact the asset without explicit authorization
- Authorization can be revoked if compliance issues arise
- Transactions are atomic (authorize -> transact -> deauthorize happens together)

## Related SEPs

- [SEP-01](sep-01.md) - stellar.toml (defines regulated assets with `regulated`, `approval_server`, `approval_criteria`)
- [SEP-09](sep-09.md) - Standard KYC fields (used in `action_required` flows)
- [SEP-10](sep-10.md) - Web authentication (approval servers may require this for identity verification)

---

[Back to SEP Overview](README.md)
