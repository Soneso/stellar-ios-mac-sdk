# SEP-0030 (Account Recovery: multi-party recovery of Stellar accounts) Compatibility Matrix

**Generated:** 2026-03-29

**SDK Version:** 3.4.6

**SEP Version:** 0.8.1

**SEP Status:** Draft

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md

## SEP Summary

This protocol defines an API that enables an individual (e.g., a user or wallet) to regain access to a Stellar account that it owns after the individual has lost its private key without providing any third party control of the account.

Using this protocol, the user or wallet will preregister the account and a phone number, email, or other form of authentication with one or more servers implementing the protocol and add those servers as signers of the account.

If two or more servers are used with appropriate signer configuration no individual server will have control of the account, but collectively, they may help the individual recover access to the account.

The protocol also enables individuals to pass control of a Stellar account to another individual.

## Overall Coverage

**Total Coverage:** 100.0% (33/33 fields)

- ✅ **Implemented:** 33/33
- ❌ **Not Implemented:** 0/33

**Required Fields:** 100.0% (29/29)

**Optional Fields:** 100.0% (4/4)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/recovery/RecoveryService.swift`
- `stellarsdk/stellarsdk/recovery/request/SEP30Request.swift`
- `stellarsdk/stellarsdk/recovery/responses/SEP30Responses.swift`
- `stellarsdk/stellarsdk/recovery/errors/RecoveryServiceError.swift`

### Key Classes

- **`RecoveryService`**: Main service class implementing all SEP-30 recovery endpoints
- **`Sep30Request`**: Request model for account registration and updates
- **`Sep30RequestIdentity`**: Identity object with role and authentication methods
- **`Sep30AuthMethod`**: Authentication method with type and value
- **`Sep30AccountResponse`**: Response model with account address, identities, and signers
- **`Sep30SignatureResponse`**: Response model with transaction signature and network passphrase
- **`Sep30AccountsResponse`**: Response model for list accounts endpoint
- **`SEP30ResponseIdentity`**: Identity object in responses with role and authenticated flag
- **`SEP30ResponseSigner`**: Signer object with public key
- **`RecoveryServiceError`**: Error enum for SEP-30 error cases (400, 401, 404, 409)

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| API Endpoints | 100.0% | 100.0% | 6 | 6 |
| Request Fields | 100.0% | 100.0% | 7 | 7 |
| Response Fields | 100.0% | 100.0% | 9 | 9 |
| Error Codes | 100.0% | 100.0% | 4 | 4 |
| Recovery Features | 100.0% | 100.0% | 6 | 6 |
| Authentication | 100.0% | 100.0% | 1 | 1 |

## Detailed Field Comparison

### API Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `register_account` | ✓ | ✅ | `registerAccount(address:request:jwt:)` | POST /accounts/{address} - Register an account for recovery |
| `update_account` | ✓ | ✅ | `updateIdentitiesForAccount(address:request:jwt:)` | PUT /accounts/{address} - Update identities for an account |
| `get_account` | ✓ | ✅ | `accountDetails(address:jwt:)` | GET /accounts/{address} - Retrieve account details |
| `delete_account` | ✓ | ✅ | `deleteAccount(address:jwt:)` | DELETE /accounts/{address} - Delete account record |
| `list_accounts` | ✓ | ✅ | `accounts(jwt:after:)` | GET /accounts - List accessible accounts |
| `sign_transaction` | ✓ | ✅ | `signTransaction(address:signingAddress:transaction:jwt:)` | POST /accounts/{address}/sign/{signing-address} - Sign a transaction |

### Request Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `identities` | ✓ | ✅ | `identities` | Array of identity objects for account recovery |
| `role` | ✓ | ✅ | `role` | Role of the identity (owner or other) |
| `auth_methods` | ✓ | ✅ | `authMethods` | Array of authentication methods for the identity |
| `type` | ✓ | ✅ | `type` | Type of authentication method |
| `value` | ✓ | ✅ | `value` | Value of the authentication method (address, phone, email, etc.) |
| `transaction` | ✓ | ✅ | `transaction (parameter)` | Base64-encoded XDR transaction envelope to sign |
| `after` |  | ✅ | `after (parameter)` | Cursor for pagination in list accounts endpoint |

### Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `address` | ✓ | ✅ | `address` | Stellar address of the registered account |
| `identities` | ✓ | ✅ | `identities` | Array of registered identity objects |
| `signers` | ✓ | ✅ | `signers` | Array of signer objects for the account |
| `role` | ✓ | ✅ | `role` | Role of the identity in response |
| `authenticated` |  | ✅ | `authenticated` | Whether the identity has been authenticated |
| `key` | ✓ | ✅ | `key` | Public key of the signer |
| `signature` | ✓ | ✅ | `signature` | Base64-encoded signature of the transaction |
| `network_passphrase` | ✓ | ✅ | `networkPassphrase` | Network passphrase used for signing |
| `accounts` | ✓ | ✅ | `accounts` | Array of account objects in list response |

### Error Codes

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `400` | ✓ | ✅ | `badRequest` | Bad Request - Invalid request parameters or malformed data |
| `401` | ✓ | ✅ | `unauthorized` | Unauthorized - Missing or invalid JWT token |
| `404` | ✓ | ✅ | `notFound` | Not Found - Account or resource not found |
| `409` | ✓ | ✅ | `conflict` | Conflict - Account already exists or conflicting operation |

### Recovery Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `multi_party_recovery` | ✓ | ✅ | `Supported via registration and signing endpoints` | Support for multi-server account recovery |
| `flexible_auth_methods` | ✓ | ✅ | `Sep30AuthMethod.type and value` | Support for multiple authentication method types |
| `transaction_signing` | ✓ | ✅ | `signTransaction(address:signingAddress:transaction:jwt:)` | Server-side transaction signing for recovery |
| `account_sharing` |  | ✅ | `accounts(jwt:after:) endpoint` | Support for shared account access |
| `identity_roles` | ✓ | ✅ | `Sep30RequestIdentity.role` | Support for owner and other identity roles |
| `pagination` |  | ✅ | `accounts(jwt:after:) with optional after parameter` | Pagination support in list accounts endpoint |

### Authentication

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `jwt_token` | ✓ | ✅ | `jwt parameter required for all endpoints` | All endpoints require authentication via Authorization header with JWT token from SEP-10 or external auth provider |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional