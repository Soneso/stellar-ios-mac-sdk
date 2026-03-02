# SEP Implementations

The iOS SDK implements 17 Stellar Ecosystem Proposals (SEPs) that cover authentication, asset transfers, identity verification, and other standardized protocols for integrating with anchors and other Stellar services.

## SEP Reference Table

| SEP | Name | Description | Details |
|-----|------|-------------|---------|
| SEP-01 | Stellar Info File | Discover anchor information and supported assets | [Details](sep-01.md) |
| SEP-02 | Federation | Resolve user*domain addresses to account IDs | [Details](sep-02.md) |
| SEP-05 | Key Derivation | Derive keypairs from mnemonic phrases (BIP-39) | [Details](sep-05.md) |
| SEP-06 | Deposit/Withdrawal API | Programmatic deposits and withdrawals | [Details](sep-06.md) |
| SEP-07 | URI Scheme | Generate URIs for delegated signing by wallets | [Details](sep-07.md) |
| SEP-08 | Regulated Assets | Handle assets requiring issuer approval | [Details](sep-08.md) |
| SEP-09 | Standard KYC Fields | Standard vocabulary for KYC/AML data fields | [Details](sep-09.md) |
| SEP-10 | Web Authentication | Authenticate accounts and obtain JWT tokens | [Details](sep-10.md) |
| SEP-11 | Txrep | Convert transactions to human-readable format | [Details](sep-11.md) |
| SEP-12 | KYC API | Submit and manage customer information | [Details](sep-12.md) |
| SEP-23 | Strkey Encoding | Validate and convert Stellar addresses | [Details](sep-23.md) |
| SEP-24 | Interactive Deposit/Withdrawal | Interactive web flows for fiat on/off ramps | [Details](sep-24.md) |
| SEP-29 | Account Memo Requirements | Validate memo requirements on destination accounts | [Details](sep-29.md) |
| SEP-30 | Account Recovery | Recover access to accounts via identity verification | [Details](sep-30.md) |
| SEP-38 | Anchor RFQ API | Get exchange quotes for asset conversions | [Details](sep-38.md) |
| SEP-45 | Web Auth for Contracts | Authenticate Soroban contract accounts | [Details](sep-45.md) |
| SEP-53 | Sign/Verify Messages | Sign and verify arbitrary messages with keypairs | [Details](sep-53.md) |

## Common Flow: SEP-01 → SEP-10 → SEP-24

The most common integration pattern chains SEP-01 (discovery), SEP-10 (authentication), and SEP-24 (interactive deposit/withdrawal). See individual SEP files for complete, runnable examples.

**SEP-01: Discover anchor endpoints**
```swift
import stellarsdk

let result = await StellarToml.from(domain: "anchor.example.com")
```

**SEP-10: Authenticate and get JWT**
```swift
import stellarsdk

let authResult = await WebAuthenticator.from(domain: "anchor.example.com", network: Network.testnet)
let jwtResult = await webAuth.jwtToken(forUserAccount: userKeyPair.accountId, signers: [userKeyPair])
```

**SEP-24: Start interactive deposit**
```swift
import stellarsdk

let service = InteractiveService(serviceAddress: "https://anchor.example.com")
let depositResult = await service.deposit(request: Sep24DepositRequest(jwt: jwt, assetCode: "USDC"))
// Open the response.url in a webview for user interaction
```

## Dependencies

The following SEPs depend on other SEPs:

- **SEP-06 (Deposit/Withdrawal API)** → Requires SEP-10 for authentication; often paired with SEP-12 and SEP-38
- **SEP-10 (Web Authentication)** → Requires SEP-01 to discover web auth endpoint
- **SEP-12 (KYC API)** → Requires SEP-10 for authentication
- **SEP-24 (Interactive Deposit/Withdrawal)** → Requires SEP-10 for authentication; often paired with SEP-12 and SEP-38
- **SEP-30 (Account Recovery)** → Requires SEP-10 for authentication
- **SEP-38 (Anchor RFQ API)** → Requires SEP-10 for authentication; used with SEP-06 or SEP-24
- **SEP-45 (Web Auth for Contracts)** → Requires SEP-01 to discover web auth endpoint for contract accounts

No dependencies: SEP-02, SEP-05, SEP-07, SEP-08, SEP-09, SEP-11, SEP-23, SEP-29, SEP-53
