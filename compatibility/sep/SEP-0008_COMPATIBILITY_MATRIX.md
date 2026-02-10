# SEP-0008 (Regulated Assets) Compatibility Matrix

**Generated:** 2026-02-10

**SDK Version:** 3.4.3

**SEP Version:** 1.7.4

**SEP Status:** Active

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md

## SEP Summary

Regulated Assets are assets that require an issuer’s approval (or a delegated third party’s approval, such as a licensed securities exchange) on a per-transaction basis.

It standardizes the identification of such assets as well as defines the protocol for performing compliance checks and requesting issuer approval.

## Overall Coverage

**Total Coverage:** 100.0% (32/32 fields)

- ✅ **Implemented:** 32/32
- ❌ **Not Implemented:** 0/32

**Required Fields:** 100.0% (27/27)

**Optional Fields:** 100.0% (5/5)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/regulated_assets/RegulatedAssetsService.swift`

### Key Classes

- **`RegulatedAssetsService`**: Main service class implementing SEP-08 approval server protocol
- **`RegulatedAsset`**: Model for regulated asset with approval server and criteria
- **`Sep08PostTransactionSuccess`**: Success response with signed transaction XDR
- **`Sep08PostTransactionRevised`**: Revised response with modified compliant transaction
- **`Sep08PostTransactionPending`**: Pending response with timeout for retry
- **`Sep08PostTransactionActionRequired`**: Action required response with action URL and method
- **`Sep08PostTransactionRejected`**: Rejected response with error message
- **`PostSep08TransactionEnum`**: Result enum for POST /tx_approve (success, revised, pending, actionRequired, rejected, or failure)
- **`Sep08PostActionNextUrl`**: Response for follow_next_url action result
- **`PostSep08ActionEnum`**: Result enum for POST to action URL (done, nextUrl, or failure)
- **`Sep08PostTransactionStatusResponse`**: Helper to decode response status field
- **`Sep08PostActionResultResponse`**: Helper to decode action result field
- **`RegulatedAssetsServiceError`**: Error enum for SEP-08 operations (invalidDomain, invalidToml, parsingResponseFailed, badRequest, notFound, unauthorized, horizonError)
- **`RegulatedAssetsServiceForDomainEnum`**: Result enum for forDomain factory method
- **`AuthorizationRequiredEnum`**: Result enum for authorization flag checking

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Approval Endpoint | 100.0% | 100.0% | 1 | 1 |
| Request Parameters | 100.0% | 100.0% | 1 | 1 |
| Response Statuses | 100.0% | 100.0% | 5 | 5 |
| Success Response Fields | 100.0% | 100.0% | 3 | 3 |
| Revised Response Fields | 100.0% | 100.0% | 3 | 3 |
| Pending Response Fields | 100.0% | 100.0% | 3 | 3 |
| Action Required Response Fields | 100.0% | 100.0% | 5 | 5 |
| Rejected Response Fields | 100.0% | 100.0% | 2 | 2 |
| Action URL Handling | 100.0% | 100.0% | 4 | 4 |
| Stellar TOML Fields | 100.0% | 100.0% | 3 | 3 |
| Authorization Flags | 100.0% | 100.0% | 2 | 2 |

## Detailed Field Comparison

### Approval Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `tx_approve` | ✓ | ✅ | `postTransaction(txB64Xdr:apporvalServer:)` | POST /tx_approve - Approval server endpoint that receives a signed transaction, checks for compliance, and signs it on success |

### Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `tx` | ✓ | ✅ | `txB64Xdr parameter` | A base64 encoded transaction envelope XDR signed by the user. This is the transaction that will be tested for compliance and signed on success. |

### Response Statuses

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `success` | ✓ | ✅ | `PostSep08TransactionEnum.success` | Transaction was found compliant and signed without being revised |
| `revised` | ✓ | ✅ | `PostSep08TransactionEnum.revised` | Transaction was revised to be made compliant |
| `pending` | ✓ | ✅ | `PostSep08TransactionEnum.pending` | Issuer could not determine whether to approve the transaction at the time of receiving it |
| `action_required` | ✓ | ✅ | `PostSep08TransactionEnum.actionRequired` | User must complete an action before this transaction can be approved |
| `rejected` | ✓ | ✅ | `PostSep08TransactionEnum.rejected` | Transaction is not compliant and could not be revised to be made compliant |

### Success Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `status` | ✓ | ✅ | `status (implicit)` | Status value "success" |
| `tx` | ✓ | ✅ | `tx` | Transaction envelope XDR, base64 encoded. This transaction will have both the original signature(s) from the request as well as one or multiple add... |
| `message` |  | ✅ | `message` | A human readable string containing information to pass on to the user |

### Revised Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `status` | ✓ | ✅ | `status (implicit)` | Status value "revised" |
| `tx` | ✓ | ✅ | `tx` | Transaction envelope XDR, base64 encoded. This transaction is a revised compliant version of the original request transaction, signed by the issuer. |
| `message` | ✓ | ✅ | `message` | A human readable string explaining the modifications made to the transaction to make it compliant |

### Pending Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `status` | ✓ | ✅ | `status (implicit)` | Status value "pending" |
| `timeout` | ✓ | ✅ | `timeout` | Number of milliseconds to wait before submitting the same transaction again. Use 0 if the wait time cannot be determined. |
| `message` |  | ✅ | `message` | A human readable string containing information to pass on to the user |

### Action Required Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `status` | ✓ | ✅ | `status (implicit)` | Status value "action_required" |
| `message` | ✓ | ✅ | `message` | A human readable string containing information regarding the action required |
| `action_url` | ✓ | ✅ | `actionUrl` | A URL that allows the user to complete the actions required to have the transaction approved |
| `action_method` |  | ✅ | `actionMethod` | GET or POST, indicating the type of request that should be made to the action_url. If not provided, GET is assumed. |
| `action_fields` |  | ✅ | `actionFields` | An array of additional fields defined by SEP-9 Standard KYC / AML fields that the client may optionally provide to the approval service when sendin... |

### Rejected Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `status` | ✓ | ✅ | `status (implicit)` | Status value "rejected" |
| `error` | ✓ | ✅ | `error` | A human readable string explaining why the transaction is not compliant and could not be made compliant |

### Action URL Handling

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `action_url_get` | ✓ | ✅ | `actionUrl field support` | Support for GET method to action_url with query parameters |
| `action_url_post` | ✓ | ✅ | `postAction(url:actionFields:)` | Support for POST method to action_url with JSON body |
| `action_url_post_response_no_further_action` | ✓ | ✅ | `PostSep08ActionEnum.done` | Handle POST response with result "no_further_action_required" |
| `action_url_post_response_follow_next_url` | ✓ | ✅ | `PostSep08ActionEnum.nextUrl` | Handle POST response with result "follow_next_url" and next_url field |

### Stellar TOML Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `regulated` | ✓ | ✅ | `regulated (CurrencyDocumentation)` | A boolean indicating whether or not this is a regulated asset. If missing, false is assumed. |
| `approval_server` | ✓ | ✅ | `approvalServer` | The URL of an approval service that signs validated transactions |
| `approval_criteria` |  | ✅ | `approvalCriteria` | A human readable string that explains the issuer's requirements for approving transactions |

### Authorization Flags

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `authorization_required` | ✓ | ✅ | `authorizationRequired() checks authRequired flag` | Authorization Required flag must be set on issuer account |
| `authorization_revocable` | ✓ | ✅ | `authorizationRequired() checks authRevocable flag` | Authorization Revocable flag must be set on issuer account |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional