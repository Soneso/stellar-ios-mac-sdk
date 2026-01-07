# SEP-0002 (Federation protocol) Compatibility Matrix

**Generated:** 2026-01-07

**SDK Version:** 3.4.1

**SEP Version:** 1.1.0

**SEP Status:** Final

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md

## SEP Summary

The Stellar federation protocol maps Stellar addresses to more information about a given user.

It’s a way for Stellar client software to resolve email-like addresses such as `name*yourdomain.com` into account IDs like: `GCCVPYFOHY7ZB7557JKENAX62LUAPLMGIWNZJAFV2MITK6T32V37KEJU`.

Stellar addresses provide an easy way for users to share payment details by using a syntax that interoperates across different domains and providers.

## Overall Coverage

**Total Coverage:** 100.0% (10/10 fields)

- ✅ **Implemented:** 10/10
- ❌ **Not Implemented:** 0/10

**Required Fields:** 100.0% (6/6)

**Optional Fields:** 100.0% (4/4)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/federation/Federation.swift`
- `stellarsdk/stellarsdk/federation/responses/ResolveAddressResponse.swift`
- `stellarsdk/stellarsdk/federation/errors/FederationError.swift`

### Key Classes

- **`Federation`**: Main class for resolving Stellar federation addresses
- **`ResolveAddressResponse`**: Response model for federation address resolution
- **`FederationError`**: Error types for federation operations

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Request Parameters | 100.0% | 100.0% | 2 | 2 |
| Request Types | 100.0% | 100.0% | 4 | 4 |
| Response Fields | 100.0% | 100.0% | 4 | 4 |

## Detailed Field Comparison

### Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `q` | ✓ | ✅ | `q` | String to look up (stellar address, account ID, or transaction ID) |
| `type` | ✓ | ✅ | `type` | Type of lookup (name, id, txid, or forward) |

### Request Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `name` | ✓ | ✅ | `resolveStellarAddress` | returns the federation record for the given Stellar address. |
| `id` | ✓ | ✅ | `resolveStellarAccountId` | returns the federation record of the Stellar address associated with the given account ID. In some cases this is ambiguous. For instance if an anch... |
| `txid` |  | ✅ | `resolveStellarTransactionId` | returns the federation record of the sender of the transaction if known by the server. |
| `forward` |  | ✅ | `resolveForward` | Used for forwarding the payment on to a different network or different financial institution. The other parameters of the query will vary depending... |

### Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `stellar_address` | ✓ | ✅ | `stellarAddress` | stellar address |
| `account_id` | ✓ | ✅ | `accountId` | Stellar public key / account ID |
| `memo_type` |  | ✅ | `memoType` | type of memo to attach to transaction, one of text, id or hash |
| `memo` |  | ✅ | `memo` | value of memo to attach to transaction, for hash this should be base64-encoded. This field should always be of type string (even when memo_type is ... |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional