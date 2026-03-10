# Troubleshooting Guide

Comprehensive error handling and troubleshooting for the Stellar iOS/Mac SDK (`stellarsdk`).

## Error Type Hierarchy

The SDK uses six distinct error enums. All Horizon and Soroban RPC calls return result enums that you pattern match with `switch`.

| Error Type | Source | Pattern |
|-----------|--------|---------|
| `HorizonRequestError` | Horizon API calls | `.failure(let error)` on response enums |
| `SorobanRpcRequestError` | Soroban RPC calls | `.failure(let error)` on response enums |
| `StellarSDKError` | SDK validation, XDR | `throw` / `try` |
| `KeyUtilsError` | Account ID / key validation | `throw` / `try` |
| `AssembledTransactionError` | Soroban transaction lifecycle | `throw` / `try` |
| `SorobanClientError` | High-level contract client | `throw` / `try` |

## Horizon Errors

### HorizonRequestError Pattern Matching

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let accountId = "GABC..."

let response = await sdk.accounts.getAccountDetails(accountId: accountId)
switch response {
case .success(let details):
    print("Balance: \(details.balances)")
case .failure(let error):
    switch error {
    case .notFound(let message, _):
        print("Account not found: \(message)")
    case .badRequest(let message, _):
        print("Invalid request: \(message)")
    case .rateLimitExceeded(let message, _):
        print("Rate limited: \(message)")
    case .unauthorized(let message):
        print("Unauthorized: \(message)")
    case .requestFailed(let message, _):
        print("Network failure: \(message)")
    case .timeout(let message, _):
        print("Request timed out: \(message)")
    case .emptyResponse:
        print("Empty response from Horizon")
    case .parsingResponseFailed(let message):
        print("Failed to parse response: \(message)")
    case .errorOnStreamReceive(let message):
        print("Stream error: \(message)")
    default:
        print("Horizon error: \(error)")
    }
}
```

### Complete HorizonRequestError Cases

| Case | HTTP Code | Associated Values |
|------|-----------|-------------------|
| `.requestFailed` | Network error | `message: String, horizonErrorResponse: ErrorResponse?` |
| `.badRequest` | 400 | `message: String, horizonErrorResponse: BadRequestErrorResponse?` |
| `.unauthorized` | 401 | `message: String` |
| `.forbidden` | 403 | `message: String, horizonErrorResponse: ForbiddenErrorResponse?` |
| `.notFound` | 404 | `message: String, horizonErrorResponse: NotFoundErrorResponse?` |
| `.notAcceptable` | 406 | `message: String, horizonErrorResponse: NotAcceptableErrorResponse?` |
| `.duplicate` | 409 | `message: String, horizonErrorResponse: DuplicateErrorResponse?` |
| `.beforeHistory` | 410 | `message: String, horizonErrorResponse: BeforeHistoryErrorResponse?` |
| `.payloadTooLarge` | 413 | `message: String, horizonErrorResponse: PayloadTooLargeErrorResponse?` |
| `.rateLimitExceeded` | 429 | `message: String, horizonErrorResponse: RateLimitExceededErrorResponse?` |
| `.internalServerError` | 500 | `message: String, horizonErrorResponse: InternalServerErrorResponse?` |
| `.notImplemented` | 501 | `message: String, horizonErrorResponse: NotImplementedErrorResponse?` |
| `.staleHistory` | 503 | `message: String, horizonErrorResponse: StaleHistoryErrorResponse?` |
| `.timeout` | 504 | `message: String, horizonErrorResponse: TimeoutErrorResponse?` |
| `.emptyResponse` | -- | (none) |
| `.parsingResponseFailed` | -- | `message: String` |
| `.errorOnStreamReceive` | -- | `message: String` |

## Transaction Submission Errors

### Handling TransactionPostResponseEnum

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
// sourceKeyPair, transaction assumed built and signed earlier
let submitResponse = await sdk.transactions.submitTransaction(transaction: transaction)
switch submitResponse {
case .success(let details):
    // SubmitTransactionResponse is a typealias for TransactionResponse
    print("Transaction hash: \(details.transactionHash)")
case .destinationRequiresMemo(let destinationAccountId):
    // SEP-29: destination account requires a memo
    print("Add memo for destination: \(destinationAccountId)")
case .failure(let error):
    switch error {
    case .badRequest(let message, let errorResponse):
        // Transaction-level failures come as 400 Bad Request
        // The message contains the result code string
        print("Transaction failed: \(message)")
        if let extras = errorResponse {
            print("Error details: \(extras)")
        }
    default:
        print("Submission error: \(error)")
    }
}
```

### Common Transaction Result Codes

| Result Code | Cause | Solution |
|------------|-------|----------|
| `tx_failed` | One or more operations failed | Inspect operation result codes |
| `tx_bad_seq` | Sequence number mismatch | Reload account, retry with fresh sequence |
| `tx_bad_auth` | Invalid or missing signature | Verify KeyPair matches source, check network |
| `tx_insufficient_balance` | Cannot pay fees | Fund account or reduce fee/operations |
| `tx_insufficient_fee` | Fee below network minimum | Query `feeStats` and increase `maxOperationFee` |
| `tx_no_source_account` | Source account not found on-chain | Create account first or verify accountId |
| `tx_too_early` | `minTime` precondition not met | Wait or adjust `TransactionPreconditions` |
| `tx_too_late` | `maxTime` precondition expired | Rebuild transaction with new time bounds |
| `tx_bad_auth_extra` | Unnecessary extra signatures | Remove unneeded signers |
| `tx_not_supported` | Operation type not supported | Check network protocol version |
| `tx_fee_bump_inner_failed` | Inner transaction of fee bump failed | Fix inner transaction errors first |

### Common Operation Result Codes

| Result Code | Operations Affected | Solution |
|------------|-------------------|----------|
| `op_underfunded` | Payment, CreateAccount, PathPayment | Check balance, fund source account |
| `op_no_destination` | Payment, PathPayment | Create destination account first |
| `op_no_trust` | Payment (non-native) | Destination must add trustline via `ChangeTrustOperation` |
| `op_line_full` | Payment | Destination trustline limit reached |
| `op_low_reserve` | CreateAccount, ChangeTrust | Increase start balance above minimum reserve |
| `op_no_issuer` | ChangeTrust, Payment | Asset issuer account does not exist |
| `op_not_authorized` | Payment | Asset issuer must authorize holder via `SetTrustlineFlagsOperation` |
| `op_cross_self` | ManageSellOffer, ManageBuyOffer | Cannot trade with yourself; check offer parameters |
| `op_sell_no_trust` | ManageSellOffer | Source needs trustline for selling asset |
| `op_buy_no_trust` | ManageBuyOffer | Source needs trustline for buying asset |
| `op_offer_not_found` | ManageSellOffer, ManageBuyOffer | Offer ID does not exist; check `offerId` |

### Fixing tx_bad_seq

The most common error in production. Occurs when another transaction has been submitted from the same account and the locally cached sequence number is stale.

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")
let sourceKeyPair = try KeyPair(secretSeed: "S...")
let destinationId = "GDEST..."

// Always reload account before building a new transaction
let accountResponse = await sdk.accounts.getAccountDetails(accountId: sourceKeyPair.accountId)
switch accountResponse {
case .success(let account):
    let paymentOp = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: destinationId,
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: 10.0
    )
    let transaction = try Transaction(
        sourceAccount: account,
        operations: [paymentOp],
        memo: nil
    )
    try transaction.sign(keyPair: sourceKeyPair, network: Network.testnet)

    let submitResult = await sdk.transactions.submitTransaction(transaction: transaction)
    switch submitResult {
    case .success(let details):
        print("Success: \(details.transactionHash)")
    case .destinationRequiresMemo(let dest):
        print("Memo required for: \(dest)")
    case .failure(let error):
        print("Failed: \(error)")
    }
case .failure(let error):
    print("Could not load account: \(error)")
}
```

### Dynamic Fee Estimation

```swift
import stellarsdk

let sdk = StellarSDK(withHorizonUrl: "https://horizon-testnet.stellar.org")

let feeResponse = await sdk.feeStats.getFeeStats()
switch feeResponse {
case .success(let feeStats):
    // feeStats.maxFee and feeStats.feeCharged contain percentile data
    let baseFee = UInt32(feeStats.lastLedgerBaseFee) ?? Transaction.minBaseFee
    let recommendedFee = max(baseFee, Transaction.minBaseFee)
    print("Recommended fee per operation: \(recommendedFee) stroops")
case .failure(let error):
    print("Could not fetch fee stats: \(error)")
}
```

## Soroban RPC Errors

### SorobanRpcRequestError Pattern Matching

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")

let healthResponse = await sorobanServer.getHealth()
switch healthResponse {
case .success(let health):
    print("RPC status: \(health.status)")
case .failure(let error):
    switch error {
    case .requestFailed(let message):
        // Network-level failure (no connection, DNS, etc.)
        print("RPC request failed: \(message)")
    case .errorResponse(let rpcError):
        // JSON-RPC error from server
        // rpcError is SorobanRpcError with code, message, data
        print("RPC error \(rpcError.code): \(rpcError.message ?? "unknown")")
    case .parsingResponseFailed(let message, _):
        // Response received but could not be decoded
        print("Parse error: \(message)")
    }
}
```

### SorobanRpcError JSON-RPC Codes

| Code | Meaning | Solution |
|------|---------|----------|
| -32700 | Parse error | Check request format |
| -32600 | Invalid request | Validate JSON-RPC structure |
| -32601 | Method not found | Verify RPC method name |
| -32602 | Invalid params | Check parameter types and values |
| -32603 | Internal error | Server-side issue; retry later |

### SendTransactionResponse Status Handling

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
// signedTransaction assumed built, simulated, and signed earlier

let sendResult = await sorobanServer.sendTransaction(transaction: signedTransaction)
switch sendResult {
case .success(let response):
    switch response.status {
    case SendTransactionResponse.STATUS_PENDING:
        print("Submitted, polling: \(response.transactionId)")
        // Poll with getTransaction
    case SendTransactionResponse.STATUS_ERROR:
        if let statusError = response.error {
            print("Rejected: \(statusError.code) - \(statusError.message)")
        }
        if let resultXdr = response.errorResultXdr {
            print("Result XDR: \(resultXdr)")
        }
    case SendTransactionResponse.STATUS_DUPLICATE:
        print("Already submitted: \(response.transactionId)")
    case SendTransactionResponse.STATUS_TRY_AGAIN_LATER:
        print("Server busy, retry after delay")
    default:
        print("Unknown status: \(response.status)")
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

### GetTransactionResponse Status Polling

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
let txHash = "abc123..."

let txResult = await sorobanServer.getTransaction(transactionHash: txHash)
switch txResult {
case .success(let response):
    switch response.status {
    case GetTransactionResponse.STATUS_SUCCESS:
        print("Transaction succeeded in ledger: \(response.ledger ?? 0)")
    case GetTransactionResponse.STATUS_FAILED:
        print("Transaction failed on-chain")
    case GetTransactionResponse.STATUS_NOT_FOUND:
        print("Transaction not yet processed; poll again")
    default:
        print("Status: \(response.status)")
    }
case .failure(let error):
    print("RPC error: \(error)")
}
```

## Soroban Client Errors

### AssembledTransactionError

Thrown during the `AssembledTransaction` lifecycle (build, simulate, sign, send).

```swift
import stellarsdk

// client is a SorobanClient instance, assumed initialized earlier
do {
    let result = try await client.invokeMethod(name: "transfer", args: args)
    print("Result: \(result)")
} catch let error as AssembledTransactionError {
    switch error {
    case .simulationFailed(let message):
        print("Simulation failed: \(message)")
    case .restoreNeeded(let message):
        print("Contract state archived, restore needed: \(message)")
    case .notYetSimulated(let message):
        print("Must simulate before sending: \(message)")
    case .missingPrivateKey(let message):
        print("No secret seed for signing: \(message)")
    case .multipleSignersRequired(let message):
        print("Multi-auth needed: \(message)")
    case .sendFailed(let message):
        print("Send failed: \(message)")
    case .pollInterrupted(let message):
        print("Polling interrupted: \(message)")
    default:
        print("Assembled tx error: \(error)")
    }
} catch let error as SorobanClientError {
    switch error {
    case .methodNotFound(let message):
        print("Contract method does not exist: \(message)")
    case .invokeFailed(let message):
        print("Invocation failed: \(message)")
    case .deployFailed(let message):
        print("Deploy failed: \(message)")
    case .installFailed(let message):
        print("Install failed: \(message)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## SDK Validation Errors

### StellarSDKError

Thrown during local validation before any network call.

```swift
import stellarsdk

do {
    let keyPair = try KeyPair(accountId: "INVALID_ID")
} catch let error as StellarSDKError {
    switch error {
    case .invalidArgument(let message):
        print("Invalid input: \(message)")
    case .xdrDecodingError(let message):
        print("XDR decode failed: \(message)")
    case .xdrEncodingError(let message):
        print("XDR encode failed: \(message)")
    case .encodingError(let message):
        print("Encoding error: \(message)")
    case .decodingError(let message):
        print("Decoding error: \(message)")
    }
} catch {
    print("Other error: \(error)")
}
```

### KeyUtilsError and Ed25519Error

`KeyPair(accountId:)` can throw **either** `KeyUtilsError` or `Ed25519Error` depending on the input. Catch both:

```swift
import stellarsdk

do {
    let keyPair = try KeyPair(accountId: "INVALID_ACCOUNT_ID")
} catch let error as KeyUtilsError {
    // Thrown for strings that fail Base32 decoding
    switch error {
    case .invalidEncodedString:
        print("Invalid format — not valid Base32")
    case .invalidVersionByte:
        print("Wrong version byte")
    case .invalidChecksum:
        print("Checksum validation failed")
    }
} catch let error as Ed25519Error {
    // Thrown for strings that decode but fail key validation
    switch error {
    case .invalidPublicKey:
        print("Decoded but not a valid public key")
    case .invalidPublicKeyLength:
        print("Decoded bytes have wrong length (must be 32)")
    default:
        print("Ed25519 error: \(error)")
    }
} catch {
    print("Other error: \(error)")
}
```

**Which error gets thrown depends on the input:**
- Completely random strings (not Base32) → `KeyUtilsError.invalidEncodedString`
- Valid Base32 but wrong version byte → `KeyUtilsError.invalidVersionByte`
- Valid format but bad checksum → `KeyUtilsError.invalidChecksum`
- Passes Base32 decode but fails key validation → `Ed25519Error.invalidPublicKey`
- Decoded bytes wrong length → `Ed25519Error.invalidPublicKeyLength`

> **WRONG:** Only catching `KeyUtilsError` — some invalid inputs throw `Ed25519Error` instead
> **CORRECT:** Catch both `KeyUtilsError` and `Ed25519Error`, or use a generic `catch` fallback

## Debugging Techniques

### Enable Soroban RPC Logging

```swift
import stellarsdk

let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
sorobanServer.enableLogging = true
// All RPC requests and responses will be printed to console
```

### Inspect Transaction Before Submission

```swift
import stellarsdk

// transaction assumed built earlier
let sourceKeyPair = try KeyPair(secretSeed: "S...")
print("Source: \(transaction.sourceAccount.keyPair.accountId)")
print("Fee: \(transaction.fee) stroops")
print("Operations: \(transaction.operations.count)")
for (index, op) in transaction.operations.enumerated() {
    print("  [\(index)] \(type(of: op))")
}

// Inspect XDR before signing
if let xdr = try? transaction.encodedEnvelope() {
    print("Envelope XDR: \(xdr)")
}
```

### Verify Network Passphrase

Wrong network passphrase is a common cause of `tx_bad_auth`. The signature is valid but was computed against a different network.

```swift
import stellarsdk

// Confirm which network you are targeting
let network: Network = Network.testnet
print("Network passphrase: \(network.passphrase)")
// Expected: "Test SDF Network ; September 2015"

// For public network:
let publicNetwork: Network = .public
print("Public passphrase: \(publicNetwork.passphrase)")
// Expected: "Public Global Stellar Network ; September 2015"
```

## Common Patterns

### Retry with Exponential Backoff

```swift
import stellarsdk

func retryWithBackoff<T>(
    maxRetries: Int = 3,
    initialDelay: UInt64 = 1_000_000_000,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error
            let delay = initialDelay * UInt64(1 << attempt)
            try await Task.sleep(nanoseconds: delay)
        }
    }
    throw lastError!
}
```

## Getting Help

When seeking support, provide:
1. SDK version (3.4.5)
2. iOS/macOS version
3. Complete error message and type
4. Transaction XDR (from `transaction.encodedEnvelope()`)
5. Minimal reproduction code

**Resources:**
- Stellar Stack Exchange
- Stellar Discord (#sdk channel)
- GitHub Issues: github.com/Soneso/stellar-ios-mac-sdk/issues
