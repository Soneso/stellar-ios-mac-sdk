# SEP-0010 (Stellar Web Authentication) Compatibility Matrix

**Generated:** 2025-11-14

**SEP Version:** 3.4.1
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md

## SEP Summary

This SEP defines the standard way for clients such as wallets or exchanges to create authenticated web sessions on behalf of a user who holds a Stellar account.

A wallet may want to authenticate with any web service which requires a Stellar account ownership verification, for example, to upload KYC information to an anchor in an authenticated way as described in [SEP-12](sep-0012.md).

This SEP also supports authenticating users of shared, omnibus, or pooled Stellar accounts.

Clients can use [memos](#memos) or [muxed accounts](#muxed-accounts) to distinguish users or sub-accounts of shared accounts.

This protocol is a variation of mutual challenge-response, which uses Stellar transactions to encode challenges and responses.

It involves the following components: - A **Home Domain**: a domain.

## Overall Coverage

**Total Coverage:** 100.0% (24/24 fields)

- ✅ **Implemented:** 24/24
- ❌ **Not Implemented:** 0/24

_Note: Excludes 2 server-side-only feature(s) not applicable to client SDKs_

**Required Fields:** 100.0% (19/19)

**Optional Fields:** 100.0% (5/5)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/web_authentication/WebAuthenticator.swift`
- `stellarsdk/stellarsdk/toml/AccountInformation.swift`

### Key Classes

- **`WebAuthenticator`**: Main class implementing SEP-10 authentication flow
- **`AccountInformation`**: Contains WEB_AUTH_ENDPOINT and SIGNING_KEY from stellar.toml
- **`ChallengeValidationError`**: Error enum for challenge validation failures
- **`GetJWTTokenError`**: Error enum for JWT token retrieval failures

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Authentication Endpoints | 100.0% | 100.0% | 2 | 2 |
| Challenge Transaction Features | 100.0% | 100.0% | 9 | 9 |
| Client Domain Features | 100.0% | 100.0% | 3 | 3 |
| JWT Token Features | 100.0% | 100.0% | 4 | 4 |
| Verification Features | 100.0% | 100.0% | 6 | 6 |

## Detailed Field Comparison

### Authentication Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_auth_challenge` | ✓ | ✅ | `getChallenge(forAccount:memo:homeDomain:clientDomain:)` | GET /auth endpoint - Returns challenge transaction |
| `post_auth_token` | ✓ | ✅ | `sendCompletedChallenge(base64EnvelopeXDR:)` | POST /auth endpoint - Validates signed challenge and returns JWT token |

### Challenge Transaction Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `challenge_transaction_generation` | ✓ | ✅ | `getChallenge()` | Generate challenge transaction with proper structure |
| `home_domain_operation` | ✓ | ✅ | `isValidChallenge (home domain validation)` | First operation contains home_domain + " auth" as data name |
| `manage_data_operations` | ✓ | ✅ | `isValidChallenge (operation type check)` | Challenge uses ManageData operations for auth data |
| `nonce_generation` | ✓ | ✅ | `getChallenge (receives nonce)` | Random nonce in ManageData operation value |
| `sequence_number_zero` | ✓ | ✅ | `isValidChallenge (sequence validation)` | Challenge transaction has sequence number 0 |
| `server_signature` | ✓ | ✅ | `isValidChallenge (signature verification)` | Challenge is signed by server before sending to client |
| `timebounds_enforcement` | ✓ | ✅ | `isValidChallenge (timebounds validation)` | Challenge transaction has timebounds for expiration |
| `transaction_envelope_format` | ✓ | ✅ | `TransactionEnvelopeXDR` | Challenge uses proper Stellar transaction envelope format |
| `web_auth_domain_operation` |  | ✅ | `isValidChallenge (web_auth_domain validation)` | Optional operation with web_auth_domain for domain verification |

### Client Domain Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `client_domain_operation` |  | ✅ | `isValidChallenge (client_domain operation)` | Add client_domain ManageData operation to challenge |
| `client_domain_parameter` |  | ✅ | `getChallenge(clientDomain:)` | Support optional client_domain parameter in GET /auth |
| `client_domain_signature` |  | ✅ | `jwtToken(clientDomainAccountKeyPair:)` | Require signature from client domain account |
| `client_domain_verification` |  | ⚙️ Server | N/A | Verify client domain by checking stellar.toml **Note:** This is a server-side verification feature. Client SDKs only need to support the client_dom... |

### JWT Token Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `jwt_claims` | ✓ | ✅ | `sendCompletedChallenge (receives JWT)` | JWT token includes required claims (sub, iat, exp) |
| `jwt_expiration` | ✓ | ✅ | `JWT token response` | JWT token includes expiration time |
| `jwt_token_generation` | ✓ | ✅ | `sendCompletedChallenge (receives JWT)` | Generate JWT token after successful challenge validation |
| `jwt_token_response` | ✓ | ✅ | `sendCompletedChallenge response` | Return JWT token in JSON response with "token" field |
| `jwt_token_validation` |  | ⚙️ Server | N/A | Validate JWT token structure and signature **Note:** This is a server-side validation feature. Client SDKs only need to receive, store, and send th... |

### Verification Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `challenge_validation` | ✓ | ✅ | `isValidChallenge()` | Validate challenge transaction structure and content |
| `home_domain_validation` | ✓ | ✅ | `isValidChallenge (home domain check)` | Validate home domain in challenge matches server |
| `memo_support` |  | ✅ | `getChallenge(memo:)` | Support optional memo in challenge for muxed accounts |
| `multi_signature_support` | ✓ | ✅ | `signTransaction(keyPairs:)` | Support multiple signatures on challenge (client account + signers) |
| `signature_verification` | ✓ | ✅ | `isValidChallenge (signature verification)` | Verify all signatures on challenge transaction |
| `timebounds_validation` | ✓ | ✅ | `isValidChallenge (timebounds with grace period)` | Validate challenge is within valid time window |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-10!
- Always use secure (HTTPS) endpoints in production
- Implement proper JWT token storage and refresh logic
- Use client_domain parameter for enhanced security when available
- Handle ChallengeValidationError cases appropriately
- Consider using grace period for time bounds validation
- Validate JWT tokens before use in subsequent requests

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

**Note:** Excludes 2 server-side-only feature(s) not applicable to client SDKs

---

**Report Generated:** 2025-11-14
**SDK Version:** 3.2.7
**Analysis Tool:** SEP Compatibility Matrix Generator v2.0