# SEP-10: Stellar Web Authentication

SEP-10 defines how wallets prove account ownership to anchors and other services. When a service needs to verify you control a Stellar account, SEP-10 handles the challenge-response flow and returns a JWT token you can use for authenticated requests.

**Use SEP-10 when:**
- Authenticating with anchors before deposits/withdrawals (SEP-6, SEP-24)
- Submitting KYC information (SEP-12)
- Accessing any service that requires proof of account ownership

**Spec:** [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)

## Quick Example

This example demonstrates the simplest SEP-10 authentication flow: creating a WebAuthenticator instance from the anchor's domain and obtaining a JWT token in a single call.

```swift
import stellarsdk

// Create WebAuthenticator from the anchor's domain - this automatically loads
// the stellar.toml and extracts the WEB_AUTH_ENDPOINT and SIGNING_KEY
let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// Get JWT token - handles challenge request, signing, and submission
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let jwtResult = await webAuth.jwtToken(forUserAccount: userKeyPair.accountId, signers: [userKeyPair])
guard case .success(let jwtToken) = jwtResult else { return }

// Use the token for authenticated requests to SEP-6, SEP-12, SEP-24, etc.
print("Authenticated! Token: \(jwtToken.prefix(50))...")
```

## Detailed Usage

### Creating WebAuthenticator

#### From domain (recommended)

This method loads configuration automatically from the anchor's stellar.toml file, so you always have the correct endpoint and signing key.

```swift
import stellarsdk

// Loads stellar.toml and extracts WEB_AUTH_ENDPOINT and SIGNING_KEY
let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
```

#### Manual construction

Use this when you already have the endpoint and signing key, or when testing with custom configurations.

```swift
import stellarsdk

let webAuth = WebAuthenticator(
    authEndpoint: "https://testanchor.stellar.org/auth",
    network: Network.testnet,
    serverSigningKey: "GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS",
    serverHomeDomain: "testanchor.stellar.org"
)
```

### Standard authentication

For most use cases, `jwtToken()` handles the entire SEP-10 flow: requesting a challenge, validating it, signing with your keypair(s), and getting the JWT token.

> **Note:** Accounts don't need to exist on the Stellar network to authenticate. SEP-10 only proves you control the signing key for an account address. The server handles non-existent accounts by assuming default signature requirements.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair]
)
```

The method performs these steps internally:
1. Requests a challenge transaction from the server
2. Validates the challenge (sequence number = 0, valid signatures, time bounds, operations)
3. Signs with your keypair(s)
4. Submits the signed transaction to the server
5. Returns the JWT token

### Multi-signature accounts

For accounts requiring multiple signatures to meet the authentication threshold, provide all required signers. The combined signature weight must meet the server's requirements.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// Provide all signers needed to meet the account's threshold
let signer1 = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let signer2 = try KeyPair(secretSeed: "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2HIF74DBGCZ6V5CSBRROPGKVZ")

let jwtResult = await webAuth.jwtToken(
    forUserAccount: signer1.accountId,
    signers: [signer1, signer2]
)
```

### Muxed accounts

Muxed accounts (M... addresses) bundle a user ID with a G... account. This lets services distinguish between multiple users sharing the same Stellar account.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

// Create muxed account with user ID embedded in the address
let muxedAccount = try MuxedAccount(accountId: userKeyPair.accountId, id: 1234567890)

let jwtResult = await webAuth.jwtToken(
    forUserAccount: muxedAccount.accountId, // Returns M... address
    signers: [userKeyPair]
)
```

#### Memo-based user separation

For services that use memos instead of muxed accounts to identify users sharing a single Stellar account, pass the memo as a separate parameter.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    memo: 1234567890, // User ID memo (must be UInt64)
    signers: [userKeyPair]
)
```

> **Note:** You cannot use both a muxed account (M...) and a memo simultaneously. The SDK will return a `.failure` with a `.requestError` if you attempt this.

### Client attribution (non-custodial wallets)

Client domain verification lets wallets prove their identity to anchors. Anchors can then provide different experiences for users coming from known, trusted wallets.

#### Local signing

When the wallet has direct access to its signing key, provide the keypair directly. The wallet's stellar.toml must include a `SIGNING_KEY` that matches the provided keypair.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")
let clientDomainKeyPair = try KeyPair(secretSeed: "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2HIF74DBGCZ6V5CSBRROPGKVZ")

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: clientDomainKeyPair
)
```

#### Remote signing callback

When the client domain signing key is stored on a separate server (recommended for security), use a callback to delegate signing. This is the recommended approach for production.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

// Public-key-only keypair — no private key, triggers use of signing function
let clientDomainAccountKeyPair = try KeyPair(accountId: "GBWW7NMWWIKPDEWZZKTTCSUGV2ZMVN23IZ5JFOZ4FWZBNVQNHMU47HOR")

// Signing function: receives base64 XDR, returns signed base64 XDR
let signingFunction: (String) async throws -> String = { transactionXdr in
    guard let url = URL(string: "https://signing-server.mywallet.com/sign") else {
        throw NSError(domain: "MyWallet", code: 1)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer YOUR_API_TOKEN", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
        "transaction": transactionXdr,
        "network_passphrase": "Test SDF Network ; September 2015"
    ])

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let signedTx = json["transaction"] as? String else {
        throw NSError(domain: "MyWallet", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid signing server response"])
    }
    return signedTx
}

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair],
    clientDomain: "mywallet.com",
    clientDomainAccountKeyPair: clientDomainAccountKeyPair,
    clientDomainSigningFunction: signingFunction
)
```

### Multiple home domains

When an anchor serves multiple domains from the same authentication server, specify which domain the challenge should be issued for.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

let jwtResult = await webAuth.jwtToken(
    forUserAccount: userKeyPair.accountId,
    signers: [userKeyPair],
    homeDomain: "other-domain.com" // Request challenge for specific domain
)
```

## Error handling

The SDK provides specific error types for different failure scenarios. This lets you handle errors precisely and give users appropriate feedback.

```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)

switch authResult {
case .failure(let error):
    switch error {
    case .invalidDomain:
        print("The domain string is not a valid URL or domain format")
    case .invalidToml:
        print("stellar.toml could not be parsed or is malformed")
    case .noAuthEndpoint:
        print("stellar.toml missing WEB_AUTH_ENDPOINT or SIGNING_KEY")
    }
    return
case .success(let webAuth):
    let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

    let jwtResult = await webAuth.jwtToken(forUserAccount: userKeyPair.accountId, signers: [userKeyPair])

    switch jwtResult {
    case .success(let jwtToken):
        print("Authenticated! Token: \(jwtToken)")

    case .failure(let error):
        switch error {
        case .requestError(let horizonError):
            // Network or server error during challenge GET or signed challenge POST
            print("Request failed: \(horizonError)")

        case .parsingError(let parseError):
            // Could not decode the challenge transaction XDR or server response
            print("Parsing failed: \(parseError)")

        case .signingError:
            // Transaction signing failed — keypair may lack a private key
            print("Signing failed — check that all signers have secret keys")

        case .validationErrorError(let validationError):
            switch validationError {
            case .sequenceNumberNot0:
                // CRITICAL SECURITY: Challenge has non-zero sequence number
                // This could indicate a malicious server trying to get you to sign a real transaction
                print("Security error: Invalid sequence number - DO NOT PROCEED")
            case .invalidSignature:
                // Challenge wasn't properly signed by the server's signing key
                print("Invalid server signature - check stellar.toml SIGNING_KEY")
            case .invalidTimeBounds:
                // Challenge expired or time bounds invalid - request a new one
                print("Challenge expired or invalid time bounds")
            case .invalidHomeDomain:
                // First operation's data key doesn't match expected "domain auth" format
                print("Invalid home domain in challenge")
            case .invalidWebAuthDomain:
                // web_auth_domain operation value doesn't match the auth endpoint host
                print("Invalid web auth domain")
            case .invalidSourceAccount:
                // Operation source account is incorrect (first op must be client, others must be server)
                print("Invalid source account in challenge operation")
            case .invalidOperationType:
                // Challenge contains non-ManageData operations (security risk)
                print("Invalid operation type - all operations must be ManageData")
            case .invalidOperationCount:
                // Challenge has zero operations
                print("Invalid operation count")
            case .invalidMemoType:
                // Memo must be MEMO_NONE or MEMO_ID
                print("Invalid memo type")
            case .invalidMemoValue:
                // Memo value doesn't match the requested memo
                print("Memo value mismatch")
            case .memoAndMuxedSourceAccountFound:
                // Challenge has both memo and muxed account (invalid per SEP-10)
                print("Cannot have both memo and muxed account")
            case .signatureNotFound:
                // Challenge has wrong number of signatures
                print("Server signature not found")
            case .validationFailure:
                // Generic validation failure (malformed XDR, etc.)
                print("Challenge validation failed")
            case .invalidTransactionType:
                // Fee-bump transactions not allowed for SEP-10
                print("Invalid transaction type")
            case .sourceAccountNotFound:
                // An operation is missing a source account field
                print("Source account not found on operation")
            }
        }
    }
}
```

### Error reference

| Error | Cause | Solution |
|-------|-------|----------|
| `.invalidDomain` | Domain string is not a valid URL or domain format | Check domain format |
| `.invalidToml` | stellar.toml could not be parsed or is malformed | Check domain supports SEP-10 |
| `.noAuthEndpoint` | stellar.toml missing WEB_AUTH_ENDPOINT or SIGNING_KEY | Check domain supports SEP-10 |
| `.requestError` | Network or server error during GET or POST | Check account ID format, server status |
| `.parsingError` | Failed to parse challenge XDR or server response | Check server response format |
| `.signingError` | Transaction signing failed (keypair lacks private key) | Ensure signers have secret keys |
| `.validationErrorError(.sequenceNumberNot0)` | Sequence number != 0 | **Security risk** - do not proceed |
| `.validationErrorError(.invalidSignature)` | Bad server signature | Verify stellar.toml SIGNING_KEY |
| `.validationErrorError(.invalidTimeBounds)` | Challenge expired | Request a new challenge |
| `.validationErrorError(.invalidHomeDomain)` | Wrong home domain | Check domain configuration |
| `.validationErrorError(.invalidWebAuthDomain)` | Wrong web auth domain | Verify auth endpoint URL |
| `.validationErrorError(.invalidSourceAccount)` | Wrong operation source | Server configuration issue |
| `.validationErrorError(.invalidOperationType)` | Non-ManageData operation | **Security risk** - server may be malicious |
| `.validationErrorError(.invalidMemoType)` | Memo not NONE or ID | Server configuration issue |
| `.validationErrorError(.invalidMemoValue)` | Memo mismatch | Check memo parameter matches server |
| `.validationErrorError(.memoAndMuxedSourceAccountFound)` | Both memo and M... address | Use one or the other, not both |

### Retry logic example

For production applications, implement retry logic with exponential backoff for transient failures.

```swift
import stellarsdk

/// Authenticates with automatic retry for transient failures.
func authenticateWithRetry(
    webAuth: WebAuthenticator,
    accountId: String,
    signers: [KeyPair],
    maxRetries: Int = 3
) async -> GetJWTTokenResponseEnum {
    var attempt = 0
    var lastResult: GetJWTTokenResponseEnum?

    while attempt < maxRetries {
        let result = await webAuth.jwtToken(forUserAccount: accountId, signers: signers)
        switch result {
        case .success:
            return result
        case .failure(let error):
            lastResult = result
            switch error {
            case .validationErrorError(.invalidTimeBounds):
                // Challenge expired - retry immediately with fresh challenge
                attempt += 1
            case .requestError:
                // Server error - retry with exponential backoff
                attempt += 1
                try? await Task.sleep(nanoseconds: UInt64(1 << attempt) * 1_000_000_000)
            default:
                // Non-retryable error
                return result
            }
        }
    }

    return lastResult ?? .failure(error: .signingError)
}

// Usage
let authResult = await WebAuthenticator.from(domain: "testanchor.stellar.org", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
let userKeyPair = try KeyPair(secretSeed: "SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A")

let jwtResult = await authenticateWithRetry(webAuth: webAuth, accountId: userKeyPair.accountId, signers: [userKeyPair])
```

## Security notes

- **Store tokens securely.** JWT tokens grant access to protected services. Don't log them or expose them in URLs.
- **Use the correct network.** Ensure you pass `Network.testnet` or `Network.public` matching the server's network.

The SDK automatically validates challenges (sequence number, signatures, time bounds, operations) and throws specific errors if anything looks wrong.

> **Note:** The SDK does not currently support Authorization headers when requesting challenges (SEP-10 v3.4.0 feature). Most servers don't require this, as it's an optional feature that servers may implement to restrict or rate-limit challenge generation.

## Testing

Use the `WebAuthenticator` manual constructor with mock HTTP responses via `URLProtocol` (the `ServerMock`/`RequestMock`/`ResponsesMock` pattern). No network calls are made.

```swift
import XCTest
import stellarsdk

class Sep10MockTest: XCTestCase {
    // Server configuration - must match what WebAuthenticator is initialized with
    let serverPublicKey = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverPrivateKey = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"

    let domain = "place.domain.com"
    let authServer = "http://api.stellar.org/auth"

    // Client keypair
    let clientSecretSeed = "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX"

    let successJwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

    func generateNonce(length: Int) -> String? {
        let nonce = NSMutableData(length: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, nonce!.length, nonce!.mutableBytes)
        if result == errSecSuccess {
            return (nonce! as Data).base64EncodedString()
        } else {
            return nil
        }
    }

    // Build a valid challenge transaction (mimics what the server would produce)
    func buildChallenge(accountId: String) -> String {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        // Account with sequence -1: after build() the sequence becomes 0
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)

        let timeBounds = TimeBounds(
            minTime: UInt64(Date().timeIntervalSince1970),
            maxTime: UInt64(Date().timeIntervalSince1970 + 300)
        )

        // First op: '<domain> auth', source = client account
        let firstOp = ManageDataOperation(
            sourceAccountId: accountId,
            name: domain + " auth",
            data: generateNonce(length: 64)?.data(using: .utf8)
        )

        // Second op: 'web_auth_domain', source = server, value = host of authServer
        let secondOp = ManageDataOperation(
            sourceAccountId: serverKeyPair.accountId,
            name: "web_auth_domain",
            data: "api.stellar.org".data(using: .utf8)
        )

        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        let transaction = try! Transaction(
            sourceAccount: transactionAccount,
            operations: [firstOp, secondOp],
            memo: Memo.none,
            preconditions: preconditions
        )

        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        return """
        {"transaction": "\(try! transaction.encodedEnvelope())"}
        """
    }

    func testStandardAuthentication() async {
        // Register mock URL protocol
        URLProtocol.registerClass(ServerMock.self)

        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientSecretSeed)
        let clientAccountId = clientKeyPair.accountId

        // Register GET mock for challenge
        let challengeHandler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }
            if mock.variables["account"] == clientAccountId {
                mock.statusCode = 200
                return self.buildChallenge(accountId: clientAccountId)
            }
            mock.statusCode = 400
            return "{\"error\": \"Bad request\"}"
        }
        let challengeMock = RequestMock(
            host: "api.stellar.org",
            path: "/auth",
            httpMethod: "GET",
            mockHandler: challengeHandler
        )
        ServerMock.add(mock: challengeMock)

        // Register POST mock for token
        let tokenHandler: MockHandler = { mock, request in
            if let data = request.httpBodyStream?.readfully(),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let txXdr = json["transaction"] as? String {
                let envelope = try! TransactionEnvelopeXDR(xdr: txXdr)
                // Server signature [0] + client signature [1]
                if envelope.txSignatures.count == 2 {
                    mock.statusCode = 200
                    return "{\"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\"}"
                }
            }
            mock.statusCode = 400
            return "{\"error\": \"The provided transaction is not valid\"}"
        }
        let tokenMock = RequestMock(
            host: "api.stellar.org",
            path: "/auth",
            httpMethod: "POST",
            mockHandler: tokenHandler
        )
        ServerMock.add(mock: tokenMock)

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: clientAccountId,
            signers: [clientKeyPair]
        )

        switch jwtResult {
        case .success(let jwt):
            XCTAssertTrue(jwt.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Authentication failed: \(error)")
        }

        ServerMock.removeAll()
    }
}
```

**Key details for building a valid mock challenge:**
- The `Account` sequence starts at `-1` -- `Transaction` build increments it to 0 (required by SEP-10)
- First ManageData op key must be `'<serverHomeDomain> auth'`, source must be the client account
- The `web_auth_domain` op source must be the server signing key account ID; its value must be the **host** of the auth URL (e.g., `'api.stellar.org'`, not the full URL)
- The transaction must be signed by the server's keypair with the correct `Network`
- Time bounds must include the current time

## JWT token structure

The JWT token returned by SEP-10 authentication contains standard claims. The SDK doesn't include a JWT decoder, but understanding the token structure helps with debugging and validation.

**Standard JWT claims:**
- `sub` - The authenticated account (G... or M... address, or G...:memo format for memo-based auth)
- `iss` - The token issuer (authentication server URL)
- `iat` - Token issued at timestamp (Unix epoch)
- `exp` - Token expiration timestamp (Unix epoch)
- `client_domain` - (optional) Present when client domain verification was performed

To decode and inspect a JWT token, you can use any JWT library or the [jwt.io](https://jwt.io) debugger.

## Related SEPs

- [SEP-01](sep-01.md) - stellar.toml discovery (provides auth endpoint)
- [SEP-06](sep-06.md) - Deposit/withdrawal (uses SEP-10 auth)
- [SEP-12](sep-12.md) - KYC API (uses SEP-10 auth)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal (uses SEP-10 auth)
- [SEP-45](sep-45.md) - Web Authentication for Contract Accounts (Soroban alternative)

---

[Back to SEP Overview](README.md)
