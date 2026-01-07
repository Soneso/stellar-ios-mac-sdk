# SEP-0045 (Stellar Web Authentication for Contract Accounts) Compatibility Matrix

**Generated:** 2026-01-07

**SDK Version:** 3.4.2

**SEP Version:** 0.1.1

**SEP Status:** Draft

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md

## SEP Summary

This SEP defines the standard way for clients such as wallets or exchanges to create authenticated web sessions on behalf of a user who holds a contract account.

A wallet may want to authenticate with any web service which requires a contract account ownership verification, for example, to upload KYC information to an anchor in an authenticated way as described in [SEP-12](sep-0012.md).

This SEP is based on [SEP-10](sep-0010.md), but does not replace it.

This SEP only supports `C` (contract) accounts.

SEP-10 only supports `G` and `M` accounts.

Services wishing to support all accounts should implement both SEPs.

## Overall Coverage

**Total Coverage:** 100.0% (31/31 fields)

- ✅ **Implemented:** 31/31
- ❌ **Not Implemented:** 0/31

**Required Fields:** 100.0% (20/20)

**Optional Fields:** 100.0% (11/11)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/web_authentication_contracts/WebAuthForContracts.swift`
- `stellarsdk/stellarsdk/web_authentication_contracts/WebAuthForContractsError.swift`
- `stellarsdk/stellarsdk/web_authentication_contracts/WebAuthForContractsResponse.swift`

### Key Classes

- **`WebAuthForContracts`**: Main class implementing SEP-45 authentication flow for contract accounts (C... addresses)
- **`ContractChallengeResponse`**: Response model for challenge authorization entries from server
- **`ContractChallengeValidationError`**: Error enum for challenge validation failures (13 cases)
- **`WebAuthForContractsError`**: Error enum for initialization errors (11 cases)
- **`GetContractJWTTokenError`**: Error enum for runtime authentication errors (8 cases)
- **`WebAuthForContractsForDomainEnum`**: Result enum for creating instance from stellar.toml
- **`GetContractJWTTokenResponseEnum`**: Result enum for complete authentication flow
- **`GetContractChallengeResponseEnum`**: Result enum for challenge request
- **`SubmitContractChallengeResponseEnum`**: Result enum for signed challenge submission

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Authentication Endpoints | 100.0% | 100.0% | 3 | 3 |
| Challenge Authorization Entry Features | 100.0% | 100.0% | 7 | 7 |
| Client Domain Features | 100.0% | 100.0% | 5 | 5 |
| Signature Features | 100.0% | 100.0% | 5 | 5 |
| Validation Features | 100.0% | 100.0% | 6 | 6 |
| JWT Token Features | 100.0% | 100.0% | 5 | 5 |

## Detailed Field Comparison

### Authentication Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_auth_challenge` | ✓ | ✅ | `getChallenge(forContractAccount:homeDomain:clientDomain:)` | GET /auth endpoint - Returns challenge authorization entries for contract accounts |
| `post_auth_token` | ✓ | ✅ | `sendSignedChallenge(signedEntries:)` | POST /auth endpoint - Validates signed authorization entries and returns JWT token |
| `stellar_toml_discovery` | ✓ | ✅ | `WebAuthForContracts.from(domain:network:)` | Automatic discovery of WEB_AUTH_FOR_CONTRACTS_ENDPOINT and WEB_AUTH_CONTRACT_ID from stellar.toml |

### Challenge Authorization Entry Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `authorization_entries_decoding` | ✓ | ✅ | `decodeAuthorizationEntries(base64Xdr:)` | Decode base64 XDR authorization entries from server response |
| `contract_address_validation` | ✓ | ✅ | `validateChallenge (contract address check)` | Validate contract_address matches WEB_AUTH_CONTRACT_ID |
| `function_name_validation` | ✓ | ✅ | `validateChallenge (function name check)` | Validate function_name is "web_auth_verify" |
| `no_sub_invocations` | ✓ | ✅ | `validateChallenge (sub-invocation check)` | Reject entries with sub-invocations for security |
| `args_map_parsing` | ✓ | ✅ | `extractArgsFromEntry(_:)` | Parse args map containing account, home_domain, web_auth_domain, nonce, etc. |
| `nonce_validation` | ✓ | ✅ | `validateChallenge (nonce validation)` | Validate nonce is consistent across all authorization entries |
| `network_passphrase_validation` |  | ✅ | `jwtToken (network passphrase check)` | Validate network_passphrase if provided by server |

### Client Domain Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `client_domain_parameter` |  | ✅ | `getChallenge(clientDomain:)` | Support optional client_domain parameter in GET /auth |
| `client_domain_entry` |  | ✅ | `validateChallenge (client domain entry)` | Handle client domain authorization entry in challenge |
| `client_domain_local_signing` |  | ✅ | `signAuthorizationEntries(clientDomainKeyPair:)` | Sign client domain entry with local keypair |
| `client_domain_callback_signing` |  | ✅ | `signAuthorizationEntries(clientDomainSigningCallback:)` | Support remote signing via callback function |
| `client_domain_account_validation` |  | ✅ | `validateChallenge (client domain account check)` | Validate client_domain_account matches expected account |

### Signature Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `client_entry_signing` | ✓ | ✅ | `signAuthorizationEntries (client signing)` | Sign client authorization entry with provided signers |
| `multi_signer_support` | ✓ | ✅ | `jwtToken(signers:)` | Support multiple signers for multi-sig contracts |
| `signature_expiration_ledger` | ✓ | ✅ | `signAuthorizationEntries(signatureExpirationLedger:)` | Set signature expiration ledger in credentials |
| `auto_expiration_ledger` |  | ✅ | `jwtToken (auto-fill expiration)` | Auto-fill signature expiration ledger from Soroban RPC (current + 10) |
| `empty_signers_support` |  | ✅ | `jwtToken (empty signers handling)` | Support empty signers array for contracts without signature requirements |

### Validation Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `server_entry_validation` | ✓ | ✅ | `validateChallenge (server entry check)` | Validate server authorization entry exists |
| `client_entry_validation` | ✓ | ✅ | `validateChallenge (client entry check)` | Validate client authorization entry exists |
| `server_signature_verification` | ✓ | ✅ | `verifyServerSignature(entry:)` | Verify server signature on authorization entry using SIGNING_KEY |
| `home_domain_validation` | ✓ | ✅ | `validateChallenge (home domain check)` | Validate home_domain in args matches expected value |
| `web_auth_domain_validation` | ✓ | ✅ | `validateChallenge (web auth domain check)` | Validate web_auth_domain matches auth endpoint domain |
| `account_validation` | ✓ | ✅ | `validateChallenge (account check)` | Validate account in args matches client contract account |

### JWT Token Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `authorization_entries_encoding` | ✓ | ✅ | `encodeAuthorizationEntries(_:)` | Encode signed authorization entries to base64 XDR for submission |
| `jwt_token_response` | ✓ | ✅ | `sendSignedChallenge response` | Parse JWT token from server response |
| `form_urlencoded_support` |  | ✅ | `useFormUrlEncoded property` | Support application/x-www-form-urlencoded for POST request |
| `json_content_support` |  | ✅ | `sendSignedChallenge (JSON support)` | Support application/json for POST request |
| `timeout_handling` |  | ✅ | `submitChallengeTimeout error` | Handle HTTP 504 timeout responses |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional