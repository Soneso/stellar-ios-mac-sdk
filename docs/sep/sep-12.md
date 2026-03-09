# SEP-12: KYC API

The [SEP-12](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md) protocol defines how to submit and manage customer information for Know Your Customer (KYC) requirements. Anchors use this to collect identity documents, personal information, and verification data before processing deposits, withdrawals, or payments.

Use SEP-12 when:
- An anchor requires identity verification before deposit/withdrawal
- You need to check what KYC information an anchor requires
- You want to update previously submitted customer information
- You need to verify contact information (phone, email)

This SDK implements SEP-12 v1.15.0.

## Table of Contents

- [Quick example](#quick-example)
- [Creating the KYC service](#creating-the-kyc-service)
- [Checking customer status](#checking-customer-status)
- [Submitting customer information](#submitting-customer-information)
  - [Personal information](#personal-information)
  - [Complete natural person fields](#complete-natural-person-fields)
  - [Financial account information](#financial-account-information)
  - [Uploading ID documents](#uploading-id-documents)
  - [Organization KYC](#organization-kyc)
- [Verifying contact information](#verifying-contact-information)
- [File upload endpoint](#file-upload-endpoint)
- [Callback notifications](#callback-notifications)
- [Deleting customer data](#deleting-customer-data)
- [Shared/omnibus accounts](#sharedomnibus-accounts)
- [Contract accounts (C... addresses)](#contract-accounts-c-addresses)
- [Transaction-based KYC](#transaction-based-kyc)
- [Error handling](#error-handling)
- [Customer statuses](#customer-statuses)
- [Field statuses](#field-statuses)
- [Related specifications](#related-specifications)

## Quick example

This example shows the typical KYC workflow: create the service, check what information is needed, then submit customer data.

```swift
import stellarsdk

// Create service from anchor's domain (discovers URL from stellar.toml)
let serviceResult = await KycService.forDomain(domain: "https://testanchor.stellar.org")
guard case .success(let kycService) = serviceResult else { return }

// Check what info the anchor needs (requires JWT token from SEP-10 or SEP-45)
var request = GetCustomerInfoRequest(jwt: jwtToken)
let getResult = await kycService.getCustomerInfo(request: request)

if case .success(let response) = getResult {
    print("Status: \(response.status)")
}

// Submit customer information
var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
putRequest.fields = [
    .firstName("Jane"),
    .lastName("Doe"),
    .emailAddress("jane@example.com"),
]

let putResult = await kycService.putCustomerInfo(request: putRequest)
if case .success(let putResponse) = putResult {
    let customerId = putResponse.id // Save for future requests
}
```

## Creating the KYC service

### From Domain (Recommended)

The recommended approach discovers the KYC service URL automatically from the anchor's `stellar.toml` file. This uses the `KYC_SERVER` or `TRANSFER_SERVER` endpoint.

```swift
import stellarsdk

// Loads service URL from stellar.toml automatically
let result = await KycService.forDomain(domain: "https://testanchor.stellar.org")
switch result {
case .success(let kycService):
    // Use kycService for all KYC operations
    print("KYC endpoint: \(kycService.kycServiceAddress)")
case .failure(let error):
    switch error {
    case .invalidDomain:
        print("Domain URL is malformed")
    case .invalidToml:
        print("Could not fetch or parse stellar.toml")
    case .noKycOrTransferServerSet:
        print("stellar.toml has no KYC_SERVER or TRANSFER_SERVER")
    default:
        print("Error: \(error)")
    }
}
```

### From Direct URL

Use this when you already know the KYC service endpoint URL.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")
```

## Checking customer status

Before submitting data, check what fields the anchor requires. The response includes the customer's current verification status and lists required fields.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = GetCustomerInfoRequest(jwt: jwtToken)

// For existing customers, include their ID for faster lookup
request.id = customerId

// Specify the type of operation (affects which fields are required)
request.type = "sep6-deposit" // or "sep6-deposit", etc.

// Request field descriptions in a specific language
request.lang = "de" // ISO 639-1 code, defaults to "en"

let result = await kycService.getCustomerInfo(request: request)
switch result {
case .success(let response):
    // Check customer status
    let status = response.status
    print("Status: \(status)") // ACCEPTED, PROCESSING, NEEDS_INFO, or REJECTED

    // Get customer ID (if registered)
    let id = response.id

    // Get human-readable status message
    let message = response.message

    // Check which fields are still needed
    if let fields = response.fields {
        for (fieldName, field) in fields {
            print("Field: \(fieldName)")
            print("  Type: \(field.type)") // string, binary, number, date
            print("  Description: \(field.description)")
            let required = (field.optional == true) ? "No" : "Yes"
            print("  Required: \(required)")

            // Some fields have predefined valid values
            if let choices = field.choices, !choices.isEmpty {
                print("  Valid values: \(choices.joined(separator: ", "))")
            }
        }
    }

    // Check fields already provided and their verification status
    if let providedFields = response.providedFields {
        for (fieldName, field) in providedFields {
            print("Provided: \(fieldName)")
            print("  Status: \(field.status ?? "unknown")") // ACCEPTED, PROCESSING, REJECTED, VERIFICATION_REQUIRED

            // If rejected, get the reason
            if field.status == "REJECTED" {
                print("  Error: \(field.error ?? "")")
            }
        }
    }

case .failure(let error):
    print("Error: \(error)")
}
```

## Submitting customer information

### Personal information

Submit basic personal information for individual customers. Use `KYCNaturalPersonFieldsEnum` cases assigned to the `fields` property of `PutCustomerInfoRequest`.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = PutCustomerInfoRequest(jwt: jwtToken)
request.type = "sep6-deposit"

request.fields = [
    .firstName("Jane"),
    .lastName("Doe"),
    .emailAddress("jane@example.com"),
    .mobileNumber("+14155551234"), // E.164 format
    .birthDate(DateFormatter.iso8601.date(from: "1990-05-15T00:00:00Z")!), // Date object
]

let result = await kycService.putCustomerInfo(request: request)
switch result {
case .success(let response):
    let customerId = response.id // Save this for future requests
case .failure(let error):
    print("Error: \(error)")
}
```

### Complete natural person fields

The SDK supports all SEP-9 standard fields for natural persons. Here is a complete example showing all available fields.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.fields = [
    // Name fields
    .firstName("Jane"),
    .lastName("Doe"),
    .additionalName("Marie"),           // Middle name

    // Address fields
    .address("123 Main St, Apt 4B"),
    .city("San Francisco"),
    .stateOrProvince("CA"),
    .postalCode("94102"),
    .addressCountryCode("USA"),         // ISO 3166-1 alpha-3

    // Contact information
    .mobileNumber("+14155551234"),       // E.164 format
    .mobileNumberFormat("E.164"),        // Optional: specify format
    .emailAddress("jane@example.com"),
    .languageCode("en"),                 // ISO 639-1

    // Birth information — birthDate takes a Date object
    .birthDate(DateFormatter.iso8601.date(from: "1990-05-15T00:00:00Z")!),
    .birthPlace("New York, NY, USA"),
    .birthCountryCode("USA"),            // ISO 3166-1 alpha-3

    // Tax information
    .taxId("123-45-6789"),
    .taxIdName("SSN"),                   // or "ITIN", etc.

    // Employment
    .occupation(2512),                   // Int (ISCO-08 code)
    .employerName("Acme Corp"),
    .employerAddress("456 Business Ave, New York, NY 10001"),

    // Identity document — idIssueDate and idExpirationDate are String, NOT Date
    .idType("passport"),                 // or "drivers_license", "id_card"
    .idNumber("AB123456"),
    .idCountryCode("USA"),               // ISO 3166-1 alpha-3
    .idIssueDate("2020-01-15"),
    .idExpirationDate("2030-01-15"),

    // Other fields
    .sex("female"),                      // or "male", "other"
    .ipAddress("192.168.1.1"),
    .referralId("REF123"),               // Referral or origin code
]

let result = await kycService.putCustomerInfo(request: request)
```

### Financial account information

For deposits and withdrawals, anchors often require banking or payment account details. Use `KYCFinancialAccountFieldsEnum` cases assigned to `financialAccountFields`.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = PutCustomerInfoRequest(jwt: jwtToken)

// Set person identity fields
request.fields = [.firstName("Jane"), .lastName("Doe")]

// Add banking details
request.financialAccountFields = [
    .bankName("First National Bank"),
    .bankAccountType("checking"),          // or "savings"
    .bankAccountNumber("1234567890"),
    .bankNumber("021000021"),              // Routing number (US)
    .bankBranchNumber("001"),
    .bankPhoneNumber("+18005551234"),      // E.164 format
    .externalTransferMemo("WIRE-REF-12345"),
    .clabeNumber("032180000118359719"),    // Mexico CLABE
    .cbuNumber("0110000000001234567890"),  // Argentina CBU/CVU
    .cbuAlias("mi.cuenta.arg"),
    .mobileMoneyNumber("+254712345678"),
    .mobileMoneyProvider("M-Pesa"),
    .cryptoAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f0AB12"),
]

let result = await kycService.putCustomerInfo(request: request)
```

### Uploading ID documents

Binary fields like photos and documents are passed as `Data` values inside `KYCNaturalPersonFieldsEnum` cases and sent via `multipart/form-data` automatically.

```swift
import stellarsdk
import Foundation

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Load ID document images as binary data
let idFrontData = try Data(contentsOf: URL(fileURLWithPath: "id_front.jpg"))
let idBackData = try Data(contentsOf: URL(fileURLWithPath: "id_back.jpg"))
let proofOfAddressData = try Data(contentsOf: URL(fileURLWithPath: "utility_bill.pdf"))
let proofOfIncomeData = try Data(contentsOf: URL(fileURLWithPath: "bank_statement.pdf"))
let selfieData = try Data(contentsOf: URL(fileURLWithPath: "selfie_video.mp4"))

var request = PutCustomerInfoRequest(jwt: jwtToken)
request.id = customerId // Update existing customer

request.fields = [
    // ID document details
    .idType("passport"),
    .idNumber("AB123456"),
    .idCountryCode("USA"),
    .idIssueDate("2020-01-15"),
    .idExpirationDate("2030-01-15"),

    // Document images (Data)
    .photoIdFront(idFrontData),
    .photoIdBack(idBackData),

    // Proof of address (utility bill, bank statement)
    .photoProofResidence(proofOfAddressData),

    // Proof of income (for high-value transactions)
    .proofOfIncome(proofOfIncomeData),

    // Liveness proof (video selfie for identity verification)
    .proofOfLiveness(selfieData),
]

let result = await kycService.putCustomerInfo(request: request)
```

### Organization KYC

For business/corporate customers, use `KYCOrganizationFieldsEnum` cases assigned to `organizationFields`. All organization fields are automatically prefixed with `organization.` as per SEP-9.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.organizationFields = [
    // Company identification
    .name("Acme Corporation"),
    .VATNumber("DE123456789"),                    // Note: VATNumber, not vatNumber
    .registrationNumber("HRB 12345"),
    .registrationDate("2010-06-15"),              // String (ISO 8601), NOT Date

    // Registered address
    .registeredAddress("456 Business Ave, Suite 100"),
    .city("New York"),
    .stateOrProvince("NY"),
    .postalCode("10001"),
    .addressCountryCode("USA"),                   // ISO 3166-1 alpha-3

    // Corporate structure
    .numberOfShareholders(3),
    .shareholderName("John Smith"),               // Ultimate beneficial owner
    .directorName("Jane Doe"),

    // Contact information
    .website("https://acme-corp.example.com"),
    .email("contact@acme-corp.example.com"),
    .phone("+12125551234"),                       // E.164 format
]

// Organization's bank account can also be set separately
request.financialAccountFields = [
    .bankName("Business Bank"),
    .bankAccountNumber("9876543210"),
    .bankNumber("021000021"),
]

let result = await kycService.putCustomerInfo(request: request)
```

### Using custom fields

If an anchor requires non-standard fields, use `extraFields` for text data and `extraFiles` for binary data.

```swift
import stellarsdk
import Foundation

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = PutCustomerInfoRequest(jwt: jwtToken)
request.id = customerId

// Custom text fields
request.extraFields = [
    "custom_field_1": "custom value",
    "anchor_specific_id": "ABC123",
]

// Custom binary files
let documentData = try Data(contentsOf: URL(fileURLWithPath: "document.pdf"))
request.extraFiles = [
    "additional_document": documentData,
]

let result = await kycService.putCustomerInfo(request: request)
```

## Verifying contact information

Some anchors require verification of contact information (phone or email) via a confirmation code. When a field has `VERIFICATION_REQUIRED` status, submit the code using the `PUT /customer` endpoint with `_verification` suffix.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// First, check if verification is required
var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
getRequest.id = customerId
let getResult = await kycService.getCustomerInfo(request: getRequest)

if case .success(let response) = getResult {
    if let providedFields = response.providedFields {
        for (fieldName, field) in providedFields {
            if field.status == "VERIFICATION_REQUIRED" {
                print("Verification required for: \(fieldName)")
                // Anchor has sent a code to the customer via SMS or email
            }
        }
    }
}

// Submit verification code via PUT /customer with _verification suffix
var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
putRequest.id = customerId
putRequest.extraFields = [
    "mobile_number_verification": "123456", // Code sent via SMS
]

let putResult = await kycService.putCustomerInfo(request: putRequest)
if case .success(let verifyResponse) = putResult {
    print("Customer ID: \(verifyResponse.id)")
}
```

### Deprecated verification endpoint

The SDK also supports the deprecated `PUT /customer/verification` endpoint for backwards compatibility. New implementations should use the method above instead.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Deprecated: Use PUT /customer with extraFields instead
let request = PutCustomerVerificationRequest(
    id: customerId,
    fields: [
        "mobile_number_verification": "123456",
        "email_address_verification": "ABC123",
    ],
    jwt: jwtToken
)

// Returns GetCustomerInfoResponseEnum (NOT PutCustomerInfoResponseEnum)
let result = await kycService.putCustomerVerification(request: request)
switch result {
case .success(let response):
    print("Status: \(response.status)")
case .failure(let error):
    print("Error: \(error)")
}
```

## File upload endpoint

For complex data structures that require `application/json`, upload files separately using the files endpoint, then reference them by `file_id` in customer requests.

### Upload a file

Upload a file and receive a `file_id` that can be referenced in subsequent `PUT /customer` requests.

```swift
import stellarsdk
import Foundation

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Upload file first
let fileData = try Data(contentsOf: URL(fileURLWithPath: "passport_front.jpg"))
let uploadResult = await kycService.postCustomerFile(file: fileData, jwtToken: jwtToken)

switch uploadResult {
case .success(let fileResponse):
    print("File ID: \(fileResponse.fileId)")
    print("Content-Type: \(fileResponse.contentType)")
    print("Size: \(fileResponse.size) bytes")

    // Optional: File may expire if not linked to a customer
    if let expiresAt = fileResponse.expiresAt {
        print("Expires: \(expiresAt)")
    }

    // Reference the file in customer data using _file_id suffix
    var request = PutCustomerInfoRequest(jwt: jwtToken)
    request.id = customerId
    request.extraFields = [
        "photo_id_front_file_id": fileResponse.fileId,
    ]

    let putResult = await kycService.putCustomerInfo(request: request)

case .failure(let error):
    switch error {
    case .payloadTooLarge(let message):
        print("File too large: \(message ?? "no details")")
    default:
        print("Upload failed: \(error)")
    }
}
```

### Retrieve file information

Get information about previously uploaded files by file ID or customer ID.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Get a specific file by ID
let result = await kycService.getCustomerFiles(fileId: "file_abc123", jwtToken: jwtToken)
switch result {
case .success(let response):
    for file in response.files {
        print("File: \(file.fileId)")
        print("  Type: \(file.contentType)")
        print("  Size: \(file.size) bytes")
        if let customerId = file.customerId {
            print("  Customer: \(customerId)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}

// Get all files for a customer
let result2 = await kycService.getCustomerFiles(customerId: customerId, jwtToken: jwtToken)
if case .success(let response2) = result2 {
    for file in response2.files {
        print("File: \(file.fileId) (\(file.contentType))")
    }
}
```

## Callback notifications

Register a callback URL to receive automatic notifications when customer status changes. This avoids polling the `GET /customer` endpoint.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = PutCustomerCallbackRequest(
    url: "https://myapp.com/kyc-callback",
    jwt: jwtToken
)
request.id = customerId

// Optional: identify customer without ID
// request.account = "GXXXXX..." // Stellar account
// request.memo = "12345"         // For shared accounts

let result = await kycService.putCustomerCallback(request: request)
switch result {
case .success:
    print("Callback registered successfully")
case .failure(let error):
    print("Error: \(error)")
}

// Your callback endpoint will receive POST requests with the same
// structure as GET /customer responses, plus a cryptographic signature
// in the Signature header for verification.
```

## Deleting customer data

Request deletion of all stored customer data. This is useful for GDPR compliance or when a customer closes their account.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// First argument is the Stellar account ID (G... address), NOT the customer UUID
let accountId = "GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

// Delete customer data
let result = await kycService.deleteCustomerInfo(account: accountId, jwt: jwtToken)
switch result {
case .success:
    print("Customer data deleted successfully")
case .failure(let error):
    switch error {
    case .notFound(let message):
        print("Customer not found: \(message)")
    case .unauthorized(let message):
        print("Unauthorized: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

## Shared/omnibus accounts

When multiple customers share a single Stellar account (common for exchanges and custodians), use memos to distinguish them. The memo should match the one used during SEP-10 or SEP-45 authentication.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Get customer info with memo
var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
getRequest.account = "GXXXXXX..." // Optional: inferred from JWT
getRequest.memo = "12345"          // Unique identifier for this customer
getRequest.memoType = "id"         // Deprecated: should always be "id"

let getResult = await kycService.getCustomerInfo(request: getRequest)

// Submit customer info with memo
var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
putRequest.fields = [
    .firstName("Jane"),
    .lastName("Doe"),
]
putRequest.memo = "12345"   // Must match JWT's sub value
putRequest.memoType = "id"  // Deprecated but supported
```

## Contract accounts (C... addresses)

For Soroban contract accounts (addresses starting with `C...`), authenticate using [SEP-45](sep-45.md) instead of SEP-10. The JWT token will contain the contract address.

> **Important:** When using contract accounts (C... addresses), you must **NOT** specify a `memo`. Contract addresses are unique identifiers and do not support memo-based sub-accounts.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Contract account address (starts with C...)
let contractAccount = "CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

// Get customer info for contract account
// JWT obtained via SEP-45 authentication
var getRequest = GetCustomerInfoRequest(jwt: sep45JwtToken)
getRequest.account = contractAccount
// Do NOT set memo for contract accounts!

let getResult = await kycService.getCustomerInfo(request: getRequest)

// Submit customer info for contract account
var putRequest = PutCustomerInfoRequest(jwt: sep45JwtToken)
putRequest.account = contractAccount
putRequest.fields = [
    .firstName("Jane"),
    .lastName("Doe"),
    .emailAddress("jane@example.com"),
]
// Do NOT set memo for contract accounts!

let putResult = await kycService.putCustomerInfo(request: putRequest)
```

## Transaction-based KYC

Some anchors require different KYC information based on transaction details (e.g., higher amounts require more verification). Use `transactionId` to link KYC to a specific transaction.

> **Important:** When using `transactionId`, the `type` parameter is **required**. Valid values include:
> - `sep6` - For SEP-6 deposit/withdrawal transactions

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

// Check KYC requirements for a specific transaction
var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
getRequest.transactionId = "tx_abc123" // From SEP-6
getRequest.type = "sep6"               // REQUIRED when using transactionId

let getResult = await kycService.getCustomerInfo(request: getRequest)

if case .success(let response) = getResult {
    // For large transactions, anchor may require additional fields
    if let fields = response.fields, fields.keys.contains("proof_of_income") {
        print("Large transaction: proof of income required")
    }
}

// Submit KYC for the transaction
var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
putRequest.fields = [
    .firstName("Jane"),
    .lastName("Doe"),
]
putRequest.transactionId = "tx_abc123"
putRequest.type = "sep6"

let putResult = await kycService.putCustomerInfo(request: putRequest)
```

## Error handling

Handle various error conditions that may occur during KYC operations. All methods return result enums. The `.failure` case contains a `KycServiceError` that you can switch on for detailed handling.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")

var request = GetCustomerInfoRequest(jwt: jwtToken)
request.id = customerId

let result = await kycService.getCustomerInfo(request: request)

switch result {
case .success(let response):
    // Handle different statuses
    switch response.status {
    case "ACCEPTED":
        print("Customer verified! Proceeding...")
    case "PROCESSING":
        print("KYC under review. Check back later.")
        print("Message: \(response.message ?? "")")
    case "NEEDS_INFO":
        print("Additional information required:")
        response.fields?.forEach { (name, field) in
            let required = (field.optional == true) ? "(optional)" : "(required)"
            print("  - \(name) \(required): \(field.description)")
        }
    case "REJECTED":
        print("KYC rejected: \(response.message ?? "")")
        // Customer cannot proceed - may need to contact support
    default:
        break
    }
case .failure(let error):
    switch error {
    case .badRequest(let message):
        print("Bad request: \(message)")
    case .unauthorized(let message):
        print("Authentication failed - JWT may be expired: \(message)")
    case .notFound(let message):
        print("Customer not found: \(message)")
    case .payloadTooLarge(let message):
        print("File too large: \(message ?? "no details")")
    case .parsingResponseFailed(let message):
        print("Parse error: \(message)")
    case .horizonError(let horizonError):
        print("Network error: \(horizonError)")
    default:
        print("Unexpected error: \(error)")
    }
}
```

## Customer statuses

The `status` field in `GetCustomerInfoResponse` indicates the customer's position in the KYC process:

| Status | Description |
|--------|-------------|
| `ACCEPTED` | All required KYC fields accepted. Customer can proceed with transactions. May revert if issues found later. |
| `PROCESSING` | KYC information is being reviewed. Check back later for updates. |
| `NEEDS_INFO` | Additional information required. Check `fields` map for what's needed. |
| `REJECTED` | KYC permanently rejected. Customer cannot use the service. Check `message` for reason. |

## Field statuses

The `status` field in `GetCustomerInfoProvidedField` indicates the verification state of individual fields:

| Status | Description |
|--------|-------------|
| `ACCEPTED` | Field has been validated and accepted. |
| `PROCESSING` | Field is being reviewed. Check back later. |
| `REJECTED` | Field was rejected. Check `error` for reason. May be resubmitted if customer status is `NEEDS_INFO`. |
| `VERIFICATION_REQUIRED` | Field needs verification (e.g., confirmation code). Submit code with `_verification` suffix. |

## Related specifications

- [SEP-10](sep-10.md) - Web Authentication (provides JWT for KYC requests)
- [SEP-45](sep-45.md) - Web Authentication for Contract Accounts (C... addresses)
- [SEP-9](sep-09.md) - Standard KYC Fields specification
- [SEP-6](sep-06.md) - Deposit and Withdrawal (often requires KYC)
- [SEP-24](sep-24.md) - Interactive Deposit/Withdrawal (often requires KYC)

---

[Back to SEP Overview](README.md)
