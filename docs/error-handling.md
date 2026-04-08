# Error Handling

The SDK uses two error patterns:

- **Result enums** for network calls -- switch on `.success` / `.failure` after each request.
- **Thrown errors** for local validation and cryptographic operations -- use `do` / `catch`.

| Error Type | Source | Pattern |
|---|---|---|
| `HorizonRequestError` | Horizon API calls | `.failure(let error)` on response enums |
| `SorobanRpcRequestError` | Soroban RPC calls | `.failure(let error)` on response enums |
| `StellarSDKError` | SDK validation, XDR | `throw` / `try` |
| `KeyUtilsError` | Key decoding | `throw` / `try` |
| `Ed25519Error` | Cryptographic operations | `throw` / `try` |
| `AssembledTransactionError` | Soroban transaction lifecycle | `throw` / `try` |
| `SorobanClientError` | High-level contract client | `throw` / `try` |

## Transaction Submission Errors

### Handling Submission Results

`submitTransaction` returns a `TransactionPostResponseEnum` with three cases:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResponse {
case .success(let details):
    print("Transaction hash: \(details.transactionHash)")
case .destinationRequiresMemo(let destinationAccountId):
    // SEP-29: destination account requires a memo
    print("Add a memo for destination: \(destinationAccountId)")
case .failure(let error):
    print("Submission failed: \(error)")
}
```

### Extracting Result Codes

When a transaction fails, Horizon returns error details inside `ErrorResponse.extras.resultCodes`. Extract the transaction-level code and per-operation codes to determine the cause:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResponse {
case .success(let details):
    print("Transaction hash: \(details.transactionHash)")
case .destinationRequiresMemo(let destinationAccountId):
    print("Add a memo for destination: \(destinationAccountId)")
case .failure(let error):
    if case .badRequest(let message, let errorResponse) = error {
        print("Transaction rejected: \(message)")

        if let extras = errorResponse?.extras,
           let resultCodes = extras.resultCodes {
            print("Transaction result: \(resultCodes.transaction ?? "unknown")")
            if let opCodes = resultCodes.operations {
                for (i, code) in opCodes.enumerated() {
                    print("  Operation \(i): \(code)")
                }
            }
        }

        // Raw XDR for deeper debugging
        if let resultXdr = errorResponse?.extras?.resultXdr {
            print("Result XDR: \(resultXdr)")
        }
    } else {
        // Network error, timeout, etc.
        print("Submission error: \(error)")
    }
}
```

### Fixing tx_bad_seq

This is the most common production error. It happens when the sequence number used to build the transaction no longer matches the account's current sequence number on the network. Always reload the account immediately before building the transaction:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()
let sourceKeyPair = try KeyPair(secretSeed: "S...")

// Reload account right before building to get the current sequence number
let accountResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
guard case .success(let account) = accountResponse else {
    print("Failed to load account")
    return
}

let payment = try PaymentOperation(
    sourceAccountId: nil,
    destinationAccountId: "GABC...",
    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
    amount: 10.0
)

let transaction = try Transaction(
    sourceAccount: account,
    operations: [payment],
    memo: nil
)

try transaction.sign(keyPair: sourceKeyPair, network: .testnet)

let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResponse {
case .success(let details):
    print("Transaction hash: \(details.transactionHash)")
case .destinationRequiresMemo(let destinationAccountId):
    print("Add a memo for destination: \(destinationAccountId)")
case .failure(let error):
    print("Submission failed: \(error)")
}
```

### Setting Appropriate Fees

Query `feeStats` to avoid `tx_insufficient_fee` during network congestion:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let feeResponse = await sdk.feeStats.getFeeStats()
switch feeResponse {
case .success(let feeStats):
    // Use the 90th percentile of max fees for high priority
    let fee = UInt32(feeStats.maxFee.p90) ?? Transaction.minBaseFee

    let transaction = try Transaction(
        sourceAccount: account,
        operations: [payment],
        memo: nil,
        maxOperationFee: fee
    )
case .failure(let error):
    print("Failed to load fee stats: \(error)")
}
```

### Transaction Result Code Reference

| Result Code | Cause | Solution |
|---|---|---|
| `tx_failed` | One or more operations failed | Check operation result codes |
| `tx_bad_seq` | Sequence number mismatch | Reload account, retry with fresh sequence |
| `tx_bad_auth` | Invalid or missing signature | Verify KeyPair matches source account, check network passphrase |
| `tx_insufficient_balance` | Cannot pay fees | Fund account or reduce fee/operations |
| `tx_insufficient_fee` | Fee below network minimum | Query feeStats and increase maxOperationFee |
| `tx_no_source_account` | Source account not on-chain | Create account first or verify accountId |
| `tx_too_early` | minTime precondition not met | Wait or adjust TransactionPreconditions |
| `tx_too_late` | maxTime precondition expired | Rebuild transaction with new time bounds |
| `tx_not_supported` | Operation type not supported | Check network protocol version |

### Operation Result Code Reference

| Result Code | Operations | Solution |
|---|---|---|
| `op_underfunded` | Payment, CreateAccount, PathPayment | Check balance, fund source account |
| `op_no_destination` | Payment, PathPayment | Create destination account first |
| `op_no_trust` | Payment (non-native) | Destination must add trustline |
| `op_line_full` | Payment | Destination trustline limit reached |
| `op_low_reserve` | CreateAccount, ChangeTrust | Increase amount above minimum reserve |
| `op_no_issuer` | ChangeTrust, Payment | Asset issuer account does not exist |
| `op_not_authorized` | Payment | Asset issuer must authorize holder |
| `op_cross_self` | ManageSellOffer, ManageBuyOffer | Cannot trade with yourself |
| `op_sell_no_trust` | ManageSellOffer | Source needs trustline for selling asset |
| `op_buy_no_trust` | ManageBuyOffer | Source needs trustline for buying asset |
| `op_offer_not_found` | ManageSellOffer, ManageBuyOffer | Offer ID does not exist |

## Horizon Query Errors

`HorizonRequestError` is returned in the `.failure` case of all Horizon response enums. Match specific cases to handle different failure modes:

```swift
import stellarsdk

let sdk = StellarSDK.testNet()

let response = await sdk.accounts.getAccountDetails(accountId: "GABC...")
switch response {
case .success(let account):
    print("Balance: \(account.balances)")
case .failure(let error):
    switch error {
    case .notFound(let message, _):
        print("Account does not exist: \(message)")
    case .badRequest(let message, let errorResponse):
        print("Invalid request: \(message)")
        if let detail = errorResponse?.detail {
            print("Detail: \(detail)")
        }
    case .rateLimitExceeded(let message, _):
        print("Too many requests: \(message)")
    case .requestFailed(let message, _):
        print("Network error: \(message)")
    case .timeout(let message, _):
        print("Request timed out: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

### HorizonRequestError Reference

| Case | HTTP Code | When It Happens |
|---|---|---|
| `.requestFailed` | Network error | No connectivity, DNS failure, connection refused |
| `.badRequest` | 400 | Invalid parameters, failed transaction |
| `.unauthorized` | 401 | Missing or invalid credentials |
| `.forbidden` | 403 | Access denied |
| `.notFound` | 404 | Account, transaction, or resource does not exist |
| `.notAcceptable` | 406 | Unsupported content type |
| `.duplicate` | 409 | Conflict with existing resource |
| `.beforeHistory` | 410 | Data before Horizon retention period |
| `.payloadTooLarge` | 413 | Request body too large |
| `.rateLimitExceeded` | 429 | Too many requests |
| `.internalServerError` | 500 | Horizon server error |
| `.notImplemented` | 501 | Feature not supported |
| `.staleHistory` | 503 | Horizon out of sync with network |
| `.timeout` | 504 | Request took too long |
| `.emptyResponse` | -- | Empty body from Horizon |
| `.parsingResponseFailed` | -- | JSON decode failure |
| `.errorOnStreamReceive` | -- | SSE stream error |

## Soroban RPC Errors

### SorobanRpcRequestError

All `SorobanServer` methods return result enums with `SorobanRpcRequestError` in the failure case:

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let healthResponse = await sorobanServer.getHealth()
switch healthResponse {
case .success(let health):
    print("Server status: \(health.status)")
case .failure(let error):
    switch error {
    case .requestFailed(let message):
        print("Network error: \(message)")
    case .errorResponse(let rpcError):
        print("RPC error \(rpcError.code): \(rpcError.message ?? "unknown")")
    case .parsingResponseFailed(let message, _):
        print("Failed to parse response: \(message)")
    }
}
```

### Sending Soroban Transactions

After calling `sendTransaction`, check the status to determine if the transaction was accepted:

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let sendResponse = await sorobanServer.sendTransaction(transaction: signedTransaction)
switch sendResponse {
case .success(let result):
    switch result.status {
    case SendTransactionResponse.STATUS_PENDING:
        // Transaction accepted, poll for final result
        print("Transaction pending: \(result.transactionId)")
    case SendTransactionResponse.STATUS_ERROR:
        print("Transaction rejected: \(result.error?.message ?? "unknown")")
        if let errorResult = result.errorResult {
            print("Result: \(errorResult)")
        }
    case SendTransactionResponse.STATUS_DUPLICATE:
        print("Transaction already submitted")
    case SendTransactionResponse.STATUS_TRY_AGAIN_LATER:
        print("Server busy, retry later")
    default:
        print("Unexpected status: \(result.status)")
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

### Polling Transaction Status

After a `PENDING` status, poll with `getTransaction` until it reaches a final state:

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let txResponse = await sorobanServer.getTransaction(transactionHash: txHash)
switch txResponse {
case .success(let txInfo):
    switch txInfo.status {
    case GetTransactionResponse.STATUS_SUCCESS:
        print("Transaction succeeded in ledger \(txInfo.ledger ?? 0)")
        if let result = txInfo.resultValue {
            print("Return value: \(result)")
        }
    case GetTransactionResponse.STATUS_FAILED:
        if let error = txInfo.error {
            print("Transaction failed: \(error.code) - \(error.message)")
        }
    case GetTransactionResponse.STATUS_NOT_FOUND:
        // Transaction not yet included, keep polling
        print("Transaction not yet finalized")
    default:
        print("Unknown status: \(txInfo.status)")
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

### JSON-RPC Error Codes

| Code | Meaning |
|---|---|
| -32700 | Parse error |
| -32600 | Invalid request |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |

Access these via `SorobanRpcError.code` when handling `.errorResponse`.

## Soroban Client Errors

`SorobanClient` and `AssembledTransaction` throw errors during contract operations. Catch both error types:

```swift
import stellarsdk

do {
    let result = try await client.invokeMethod(
        name: "transfer",
        args: [fromAddress, toAddress, amount]
    )
    print("Result: \(result)")
} catch let error as SorobanClientError {
    switch error {
    case .methodNotFound(let message):
        print("Method does not exist: \(message)")
    case .invokeFailed(let message):
        print("Invocation failed: \(message)")
    case .deployFailed(let message):
        print("Deployment failed: \(message)")
    case .installFailed(let message):
        print("WASM upload failed: \(message)")
    }
} catch let error as AssembledTransactionError {
    switch error {
    case .simulationFailed(let message):
        // Contract call would fail on-chain
        print("Simulation failed: \(message)")
    case .restoreNeeded(let message):
        // Archived ledger state needs restoration
        print("Restore required: \(message)")
    case .automaticRestoreFailed(let message):
        // SDK tried to restore state automatically but failed
        print("Auto-restore failed: \(message)")
    case .missingPrivateKey(let message):
        // No secret seed available for signing
        print("Cannot sign: \(message)")
    case .multipleSignersRequired(let message):
        // Transaction needs signatures from multiple parties
        print("Multi-auth needed: \(message)")
    case .sendFailed(let message):
        // Transaction submission failed
        print("Send failed: \(message)")
    case .notYetSimulated(let message):
        print("Must simulate before sending: \(message)")
    case .notYetAssembled(let message):
        print("Transaction not yet assembled: \(message)")
    case .notYetSigned(let message):
        print("Transaction not yet signed: \(message)")
    case .isReadCall(let message):
        print("Read-only call, cannot modify state: \(message)")
    case .unexpectedTxType(let message):
        print("Unexpected transaction type: \(message)")
    case .pollInterrupted(let message):
        print("Status polling interrupted: \(message)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## SDK Validation Errors

### StellarSDKError

Thrown when SDK-level validation or encoding fails:

```swift
import stellarsdk

do {
    let transaction = try Transaction(
        sourceAccount: account,
        operations: [],
        memo: nil
    )
} catch let error as StellarSDKError {
    switch error {
    case .invalidArgument(let message):
        print("Invalid argument: \(message)")
    case .xdrDecodingError(let message):
        print("XDR decode failed: \(message)")
    case .xdrEncodingError(let message):
        print("XDR encode failed: \(message)")
    case .encodingError(let message):
        print("Encoding error: \(message)")
    case .decodingError(let message):
        print("Decoding error: \(message)")
    }
}
```

### Key Validation Errors

`KeyPair(accountId:)` can throw either `KeyUtilsError` or `Ed25519Error` depending on how the input fails validation. You must catch both:

```swift
import stellarsdk

do {
    let keyPair = try KeyPair(accountId: someString)
    print("Valid account: \(keyPair.accountId)")
} catch let error as KeyUtilsError {
    switch error {
    case .invalidEncodedString:
        print("Not a valid Base32-encoded string")
    case .invalidVersionByte:
        print("Wrong key prefix (expected G for public key)")
    case .invalidChecksum:
        print("Checksum mismatch, key may be corrupted")
    }
} catch let error as Ed25519Error {
    switch error {
    case .invalidPublicKey:
        print("Decoded key fails Ed25519 validation")
    case .invalidPublicKeyLength:
        print("Decoded key has wrong byte length")
    default:
        print("Key error: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

Which error is thrown depends on the input:

| Input | Error |
|---|---|
| Random string, not valid Base32 | `KeyUtilsError.invalidEncodedString` |
| Valid Base32 but wrong version byte prefix | `KeyUtilsError.invalidVersionByte` |
| Correct format but corrupted checksum | `KeyUtilsError.invalidChecksum` |
| Passes Base32 decode but fails key validation | `Ed25519Error.invalidPublicKey` |
| Decoded bytes have wrong length | `Ed25519Error.invalidPublicKeyLength` |

## Debugging Tips

- **Enable Soroban RPC logging:** Set `sorobanServer.enableLogging = true` to print raw request/response data.
- **Inspect transaction XDR before submission:** Call `try transaction.encodedEnvelope()` and log the base64 string.
- **Verify network passphrase:** Signing with the wrong network (e.g., testnet key on pubnet) produces `tx_bad_auth`.
- **Use resultXdr for deep debugging:** The `errorResponse.extras.resultXdr` field contains the full `TransactionResult` XDR. Decode it to inspect individual operation results beyond what `resultCodes` provides.

---

**Navigation:** [SDK Usage Guide](sdk-usage.md) | [Documentation Index](README.md)
