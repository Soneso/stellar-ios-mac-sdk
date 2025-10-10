# SEP-0012 (KYC API) Compatibility Matrix

**Generated:** 2025-10-10

**SEP Version:** 1.15.0
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md

## SEP Summary

This SEP defines a standard way for stellar clients to upload KYC (or other) information to anchors and other services.

[SEP-6](sep-0006.md) and [SEP-31](sep-0031.md) use this protocol, but it can serve as a stand-alone service as well.

This SEP was made with these goals in mind: - interoperability - Allow a customer to enter their KYC information to their wallet once and use it across many services without re-entering information manually - handle the most common 80% of use cases - handle image and binary data - support the set of fields defined in [SEP-9](sep-0009.md) - support authentication via [SEP-10](sep-0010.md) - support the provision of data for [SEP-6](sep-0006.md), [SEP-24](sep-0024.md), [SEP-31](sep-0031.md), and others - give customers control over their data by supporting co.

## Overall Coverage

**Total Coverage:** 100.0% (28/28 fields)

- ✅ **Implemented:** 28/28
- ❌ **Not Implemented:** 0/28

**Required Fields:** 100.0% (12/12)

**Optional Fields:** 100.0% (16/16)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/kyc/KycService.swift`
- `stellarsdk/stellarsdk/kyc/responses/GetCustomerInfoResponse.swift`
- `stellarsdk/stellarsdk/kyc/responses/PutCustomerInfoResponse.swift`
- `stellarsdk/stellarsdk/kyc/responses/GetCustomerFilesResponse.swift`
- `stellarsdk/stellarsdk/kyc/responses/CustomerFileResponse.swift`
- `stellarsdk/stellarsdk/kyc/requests/GetCustomerInfoRequest.swift`
- `stellarsdk/stellarsdk/kyc/requests/PutCustomerInfoRequest.swift`
- `stellarsdk/stellarsdk/kyc/requests/PutCustomerVerificationRequest.swift`
- `stellarsdk/stellarsdk/kyc/requests/PutCustomerCallbackRequest.swift`

### Key Classes

- **`KycService`**: Main service class implementing all SEP-12 endpoints
- **`GetCustomerInfoRequest`**: Request model for GET /customer endpoint
- **`GetCustomerInfoResponse`**: Response model with customer status and fields
- **`PutCustomerInfoRequest`**: Request model for PUT /customer with SEP-9 fields
- **`PutCustomerInfoResponse`**: Response model with customer ID
- **`PutCustomerVerificationRequest`**: Request model for verification codes
- **`PutCustomerCallbackRequest`**: Request model for callback URL registration
- **`GetCustomerFilesResponse`**: Response model for file metadata
- **`CustomerFileResponse`**: Response model for file uploads
- **`GetCustomerInfoField`**: Field specification object for required fields
- **`GetCustomerInfoProvidedField`**: Field specification with status for provided fields
- **`KYCNaturalPersonFieldsEnum`**: SEP-9 natural person KYC fields
- **`KYCOrganizationFieldsEnum`**: SEP-9 organization KYC fields
- **`KYCFinancialAccountFieldsEnum`**: SEP-9 financial account fields
- **`KYCCardFieldsEnum`**: SEP-9 card payment fields

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| API Endpoints | 100.0% | 100.0% | 7 | 7 |
| Authentication | 100.0% | 100.0% | 1 | 1 |
| Field Type Specifications | 100.0% | 100.0% | 6 | 6 |
| File Upload | 100.0% | 100.0% | 1 | 1 |
| Request Parameters | 100.0% | 100.0% | 7 | 7 |
| Response Fields | 100.0% | 100.0% | 5 | 5 |
| SEP-9 Integration | 100.0% | 100.0% | 1 | 1 |

## Detailed Field Comparison

### API Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_customer` | ✓ | ✅ | `getCustomerInfo` | GET /customer - Check the status of a customers info |
| `put_customer` | ✓ | ✅ | `putCustomerInfo` | PUT /customer - Upload customer information to an anchor |
| `delete_customer` | ✓ | ✅ | `deleteCustomerInfo` | DELETE /customer/{account} - Delete all personal information about a customer |
| `put_customer_verification` | ✓ | ✅ | `putCustomerVerification` | PUT /customer/verification - Verify customer fields with confirmation codes |
| `put_customer_callback` | ✓ | ✅ | `putCustomerCallback` | PUT /customer/callback - Register a callback URL for customer status updates |
| `post_customer_files` | ✓ | ✅ | `postCustomerFile` | POST /customer/files - Upload binary files for customer KYC |
| `get_customer_files` | ✓ | ✅ | `getCustomerFiles` | GET /customer/files - Get metadata about uploaded files |

### Authentication

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `jwt_authentication` | ✓ | ✅ | `JWT Token` | JWT Token via SEP-10 - All endpoints require SEP-10 JWT authentication via Authorization header |

### Field Type Specifications

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `type` | ✓ | ✅ | `type` | Data type of field value |
| `description` |  | ✅ | `description` | Human-readable description of the field |
| `choices` |  | ✅ | `choices` | Array of valid values for this field |
| `optional` |  | ✅ | `optional` | Whether this field is required to proceed |
| `status` |  | ✅ | `status` | Status of provided field |
| `error` |  | ✅ | `error` | Description of why field was rejected |

### File Upload

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `multipart_file_upload` | ✓ | ✅ | `multipart/form-data` | Binary files uploaded using multipart/form-data for photo_id, proof_of_address, etc. |

### Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `id` |  | ✅ | `id` | ID of the customer as returned in previous PUT request |
| `account` |  | ✅ | `account` | Stellar account ID (G...) of the customer |
| `memo` |  | ✅ | `memo` | Memo that uniquely identifies a customer in shared accounts |
| `memo_type` |  | ✅ | `memoType` | Type of memo: text, id, or hash |
| `type` |  | ✅ | `type` | Type of action the customer is being KYCd for |
| `transaction_id` |  | ✅ | `transactionId` | Transaction ID with which customer info is associated |
| `lang` |  | ✅ | `lang` | Language code (ISO 639-1) for human-readable responses |

### Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `id` |  | ✅ | `id` | ID of the customer |
| `status` | ✓ | ✅ | `status` | Status of customer KYC process |
| `fields` |  | ✅ | `fields` | Fields the anchor has not yet received |
| `provided_fields` |  | ✅ | `providedFields` | Fields the anchor has received |
| `message` |  | ✅ | `message` | Human readable message describing KYC status |

### SEP-9 Integration

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `standard_kyc_fields` | ✓ | ✅ | `StandardKYCFields` | Supports all SEP-9 standard KYC fields for natural persons and organizations |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-12!
- Always use SEP-10 JWT authentication for all requests
- Handle customer status values appropriately (ACCEPTED, NEEDS_INFO, PROCESSING, REJECTED)
- Use multipart/form-data for uploading documents (photo_id, proof_of_address, etc.)
- Implement proper error handling for KycServiceError cases
- Consider using the callback endpoint for status updates
- Follow SEP-9 standard field naming conventions
- Validate file sizes before upload to avoid PAYLOAD_TOO_LARGE errors

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

---

**Report Generated:** 2025-10-10
**SDK Version:** 3.2.6
**Analysis Tool:** SEP Compatibility Matrix Generator v2.0