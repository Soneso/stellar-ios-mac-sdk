# SEP-45: Web Authentication for Contract Accounts

Authenticate Soroban smart contract accounts (C... addresses) with anchor services.

## Overview

SEP-45 enables wallets and clients to prove control of a Soroban contract account by signing authorization entries provided by an anchor's authentication server. Upon successful verification, the server returns a JWT token for accessing protected SEP services.

Use SEP-45 when:

- Authenticating a Soroban contract with an anchor
- Accessing SEP-24 deposits/withdrawals from a contract account
- Using SEP-12 KYC or SEP-38 quotes with contract accounts

**SEP-45 vs SEP-10:**
- SEP-45: For contract accounts (C... addresses)
- SEP-10: For traditional accounts (G... and M... addresses)

Services supporting all account types should implement both protocols.

### How it works

1. Client requests a challenge from the server
2. Server returns authorization entries calling `web_auth_verify` on its web-auth contract
3. Client validates and signs the entries with keypairs registered in the contract
4. Client submits signed entries to server
5. Server simulates the transaction -- this invokes the client contract's `__check_auth`
6. If `__check_auth` succeeds, server returns a JWT token

## Quick example

The `jwtToken()` method handles the entire flow automatically. This example loads configuration from the anchor's stellar.toml file.

```swift
import stellarsdk

// Your contract account (must implement __check_auth)
let contractId = "CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ"

// Signer registered in your contract's __check_auth implementation
let signer = try KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

// Create instance from domain and authenticate in one step
let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let jwtResult = await webAuth.jwtToken(forContractAccount: contractId, signers: [signer])
guard case .success(let jwtToken) = jwtResult else { return }

print("Authenticated! Token: \(jwtToken.prefix(50))...")
```

## Prerequisites

Before using SEP-45, ensure:

1. **Server Configuration**: The service must have a stellar.toml with:
   - `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`: URL for the authentication endpoint
   - `WEB_AUTH_CONTRACT_ID`: The server's web-auth contract address (C...)
   - `SIGNING_KEY`: The server's signing key (G...)

2. **Client Contract Requirements**: Your contract account must:
   - Be deployed on the Stellar network (testnet or pubnet)
   - Implement `__check_auth` to define authorization rules
   - Have the signer's public key registered in its contract storage

3. **Signer Keypairs**: You need the secret keys for the signers registered in your contract's `__check_auth` implementation

## Creating the service

### From stellar.toml

The `from(domain:network:)` factory method loads configuration from the anchor's stellar.toml file. This is the typical approach since it pulls the correct endpoint and contract information automatically.

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }
```

### Manual configuration

You can also provide all configuration values directly, which works well for testing or when you have the configuration cached.

```swift
import stellarsdk

let webAuth = try WebAuthForContracts(
    authEndpoint: "https://anchor.example.com/auth/sep45",
    webAuthContractId: "CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG", // webAuthContractId (C...)
    serverSigningKey: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP", // serverSigningKey (G...)
    serverHomeDomain: "anchor.example.com",
    network: Network.testnet
)
```

### Custom Soroban RPC URL

By default, the SDK uses `soroban-testnet.stellar.org` for testnet and `soroban.stellar.org` for pubnet. Specify a custom URL if you run a private RPC server.

```swift
import stellarsdk

let webAuth = try WebAuthForContracts(
    authEndpoint: "https://anchor.example.com/auth/sep45",
    webAuthContractId: "CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG",
    serverSigningKey: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
    serverHomeDomain: "anchor.example.com",
    network: Network.testnet,
    sorobanRpcUrl: "https://your-custom-rpc.example.com"
)
```

## Basic authentication

The `jwtToken()` method executes the complete SEP-45 flow: requesting the challenge, validating entries, signing with your keypairs, and submitting for a JWT.

```swift
import stellarsdk

let contractId = "CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ"
let signer = try KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let jwtResult = await webAuth.jwtToken(forContractAccount: contractId, signers: [signer])
```

## Signature expiration

Signatures include an expiration ledger for replay protection. Per SEP-45, this should be set to a near-future ledger to limit the replay window.

### Automatic expiration (default)

When you don't specify an expiration ledger, the SDK automatically fetches the current ledger from Soroban RPC and sets expiration to current ledger + 10 (~50-60 seconds).

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// Expiration is auto-filled (current ledger + 10)
let jwtResult = await webAuth.jwtToken(forContractAccount: contractId, signers: [signer])
```

### Custom expiration

You can also set a custom expiration ledger when you need more control over the signature validity window.

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signer],
    signatureExpirationLedger: 1500000
)
```

## Contracts without signature requirements

Some contracts implement `__check_auth` without requiring signature verification (e.g., contracts using other authorization mechanisms). Per SEP-45, client signatures are optional in such cases.

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// Empty signers list - no signatures will be added
let jwtResult = await webAuth.jwtToken(forContractAccount: contractId, signers: [])
```

**Note:** When the signers list is empty, the SDK skips the Soroban RPC call since no signature expiration is needed. This only works if both the anchor and your contract support signature-less authentication.

## Client domain verification

Non-custodial wallets can prove their domain to the anchor, letting the anchor attribute requests to a specific wallet application. Your domain needs a stellar.toml with a `SIGNING_KEY`.

### Local signing

When you have direct access to the client domain's signing key, you can sign locally.

```swift
import stellarsdk

let contractId = "CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ"
let signer = try KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

// Your wallet's SIGNING_KEY from stellar.toml
let clientDomainKeyPair = try KeyPair(secretSeed: "SYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY")

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signer],
    homeDomain: "anchor.example.com",
    clientDomain: "wallet.example.com",
    clientDomainAccountKeyPair: clientDomainKeyPair
)
```

### Remote signing via callback

If the client domain signing key is on a remote server, use a callback function. The callback receives a `SorobanAuthorizationEntryXDR` and returns the signed entry.

```swift
import stellarsdk

let contractId = "CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ"
let signer = try KeyPair(secretSeed: "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
    // Send the entry to your remote signing service
    let encodedBytes = try XDREncoder.encode(entry)
    let entryXdr = Data(encodedBytes).base64EncodedString()

    guard let url = URL(string: "https://your-signing-server.com/sign-sep-45") else {
        throw NSError(domain: "SigningError", code: 1)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
        "authorization_entry": entryXdr,
        "network_passphrase": "Test SDF Network ; September 2015",
    ])

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let signedXdr = json["authorization_entry"] as? String,
          let xdrData = Data(base64Encoded: signedXdr) else {
        throw NSError(domain: "SigningError", code: 2)
    }

    let decoder = XDRDecoder(data: xdrData)
    return try SorobanAuthorizationEntryXDR(from: decoder)
}

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let jwtResult = await webAuth.jwtToken(
    forContractAccount: contractId,
    signers: [signer],
    clientDomain: "wallet.example.com",
    clientDomainSigningCallback: signingCallback
)
```

## Step-by-step authentication

For more control, you can execute each step individually. Helpful for debugging or when you need to customize the flow.

```swift
import stellarsdk

let contractAccountId = "CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ"
let signerKeyPair = try KeyPair(secretSeed: "SXXXXX...")
let homeDomain = "anchor.example.com"

let authResult = await WebAuthForContracts.from(domain: homeDomain, network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

do {
    // Step 1: Get challenge from server
    let challengeResponse = await webAuth.getChallenge(forContractAccount: contractAccountId, homeDomain: homeDomain)
    guard case .success(let response) = challengeResponse else { return }

    // Step 2: Decode authorization entries from base64 XDR
    let authEntries = try webAuth.decodeAuthorizationEntries(base64Xdr: response.authorizationEntries)

    // Step 3: Validate challenge (security checks)
    try webAuth.validateChallenge(authEntries: authEntries, clientAccountId: contractAccountId, homeDomain: homeDomain)

    // Step 4: Get current ledger for signature expiration
    let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
    let latestLedgerResponse = await sorobanServer.getLatestLedger()
    guard case .success(let latestLedger) = latestLedgerResponse else { return }
    let expirationLedger = latestLedger.sequence + 10

    // Step 5: Sign authorization entries
    let signedEntries = try await webAuth.signAuthorizationEntries(
        authEntries: authEntries,
        clientAccountId: contractAccountId,
        signers: [signerKeyPair],
        signatureExpirationLedger: expirationLedger,
        clientDomainKeyPair: nil,
        clientDomainAccountId: nil,
        clientDomainSigningCallback: nil
    )

    // Step 6: Submit signed entries for JWT token
    let submitResult = await webAuth.sendSignedChallenge(signedEntries: signedEntries)
    switch submitResult {
    case .success(let jwtToken):
        print("JWT Token: \(jwtToken)")
    case .failure(let error):
        print("Submit failed: \(error)")
    }
} catch {
    print("Error: \(error)")
}
```

## Request format configuration

The SDK supports both `application/x-www-form-urlencoded` and `application/json` when submitting signed challenges. Form URL encoding is used by default.

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

// Use JSON format instead of form-urlencoded
webAuth.useFormUrlEncoded = false

let jwtResult = await webAuth.jwtToken(forContractAccount: contractId, signers: [signer])
```

## Error handling

The SDK returns specific error types through result enums for different failure scenarios:

```swift
import stellarsdk

let authResult = await WebAuthForContracts.from(domain: "anchor.example.com", network: Network.testnet)
guard case .success(let webAuth) = authResult else { return }

let jwtResult = await webAuth.jwtToken(forContractAccount: contractId, signers: [signer])

switch jwtResult {
case .success(let jwtToken):
    print("Authenticated! JWT: \(jwtToken)")

case .failure(let error):
    switch error {
    case .validationError(let validationError):
        switch validationError {
        case .invalidContractAddress(let expected, let received):
            // Server's contract address doesn't match stellar.toml - potential security issue
            print("Security error: contract address mismatch. Expected \(expected), got \(received)")

        case .subInvocationsFound:
            // Challenge contains unauthorized sub-invocations - do NOT sign
            print("Security error: sub-invocations detected. Report to anchor.")

        case .invalidServerSignature:
            // Server's signature is invalid - potential man-in-the-middle attack
            print("Security error: invalid server signature")

        case .invalidNetworkPassphrase(let expected, let received):
            // Network passphrase mismatch - wrong network configuration
            print("Configuration error: network passphrase mismatch. Expected \(expected), got \(received)")

        case .invalidFunctionName(_, let received):
            // Function name is not 'web_auth_verify' - invalid challenge
            print("Invalid challenge: wrong function name: \(received)")

        case .missingServerEntry:
            // No authorization entry for server account
            print("Invalid challenge: missing server entry")

        case .missingClientEntry:
            // No authorization entry for client account
            print("Invalid challenge: missing client entry")

        default:
            print("Validation error: \(validationError)")
        }

    case .challengeRequestError(let message):
        // Server returned an error for challenge request
        print("Challenge request failed: \(message)")

    case .submitChallengeError(let message):
        // Server rejected the signed challenge
        // Common cause: signer not registered in contract's __check_auth
        print("Authentication failed: \(message)")

    case .submitChallengeTimeout:
        // Server timed out processing the challenge
        print("Server timeout - please try again")

    case .submitChallengeUnknownResponse(let statusCode):
        // Unexpected server response
        print("Unexpected error (HTTP \(statusCode))")

    case .requestError(let requestError):
        print("Request error: \(requestError)")

    case .parsingError(let message):
        print("Parsing error: \(message)")

    case .signingError(let message):
        print("Signing error: \(message)")
    }
}
```

### Common issues

| Error | Cause | Solution |
|-------|-------|----------|
| `.submitChallengeError` | Signer not in contract's `__check_auth` | Verify signer is registered in contract storage |
| `.validationError(.invalidContractAddress)` | Contract address mismatch | Check stellar.toml `WEB_AUTH_CONTRACT_ID` |
| `.validationError(.subInvocationsFound)` | Malicious challenge | Don't sign; report to anchor |
| `.validationError(.invalidNetworkPassphrase)` | Wrong network | Check you're using testnet vs pubnet correctly |
| `.validationError(.invalidServerSignature)` | Invalid server signature | Server may be compromised or misconfigured |

## Security notes

- **Store JWT tokens securely** -- Never expose them in logs, URLs, or insecure storage. Use HTTPS for all requests.
- **Report suspicious challenges** -- If authentication fails with `.validationError(.subInvocationsFound)`, the anchor may be compromised. Do not sign and report the issue.
- **Nonce validation** -- The SDK automatically validates nonce consistency across all authorization entries for replay protection.
- **Network passphrase validation** -- The SDK verifies that the network passphrase in the challenge matches your configured network, preventing cross-network replay attacks.

The SDK automatically validates challenges (contract address, server signature, function name, network passphrase, nonce consistency) and returns specific error types if anything looks wrong.

## Using the JWT token

Once authenticated, include the JWT token in the `Authorization` header when making requests to protected SEP services.

```swift
import Foundation

let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

// Use token with SEP-24 deposit
var depositRequest = URLRequest(url: URL(string: "https://anchor.example.com/sep24/transactions/deposit/interactive")!)
depositRequest.httpMethod = "POST"
depositRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
depositRequest.httpBody = "asset_code=USDC".data(using: .utf8)
let (depositData, _) = try await URLSession.shared.data(for: depositRequest)

// Use token with SEP-12 KYC
var kycRequest = URLRequest(url: URL(string: "https://anchor.example.com/kyc/customer")!)
kycRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
let (kycData, _) = try await URLSession.shared.data(for: kycRequest)
```

## Network support

The SDK supports both testnet and public (mainnet) networks. Use the appropriate network constant when creating the service.

```swift
import stellarsdk

// Testnet
let webAuthTestnetResult = await WebAuthForContracts.from(domain: "testnet.anchor.com", network: Network.testnet)

// Public network (mainnet)
let webAuthPubnetResult = await WebAuthForContracts.from(domain: "anchor.com", network: Network.public)
```

## Reference contracts

Your contract account must implement `__check_auth` to define authorization rules. The Stellar Anchor Platform provides a reference implementation:

- [Account Contract](https://github.com/stellar/anchor-platform/tree/main/soroban/contracts/account) - Sample contract with Ed25519 signature verification in `__check_auth`

**Server-side web auth contract:** Anchors deploy a web auth contract at `WEB_AUTH_CONTRACT_ID`. The reference implementation is deployed on pubnet at `CALI6JC3MSNDGFRP7Z2OKUEPREHOJRRXKMJEWQDEFZPFGXALA45RAUTH`.

## Related SEPs

- [SEP-10](sep-10.md) - Authentication for traditional accounts (G... addresses)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal
- [SEP-12](sep-12.md) - KYC API
- [SEP-38](sep-38.md) - Quotes API

## Reference

- [SEP-45 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md)
- [Stellar iOS/macOS SDK](https://github.com/Soneso/stellar-ios-mac-sdk)

---

[Back to SEP Overview](README.md)
