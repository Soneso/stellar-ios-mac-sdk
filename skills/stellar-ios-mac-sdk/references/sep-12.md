# SEP-12: KYC API

**Purpose:** Submit and manage customer KYC information for Know Your Customer compliance with anchors.
**Prerequisites:** Requires JWT from SEP-10 (see [sep.md](sep.md))
**SDK Class:** `KycService`
**Standard KYC Fields:** See [sep-09.md](sep-09.md) for all KYC field enums (`KYCNaturalPersonFieldsEnum`, `KYCOrganizationFieldsEnum`, etc.)

## Table of Contents

- [Service initialization](#service-initialization)
- [Get customer info](#get-customer-info)
- [Put customer info](#put-customer-info)
  - [Natural person fields](#natural-person-fields)
  - [Organization fields](#organization-fields)
  - [Financial account fields](#financial-account-fields)
  - [Card fields](#card-fields)
  - [File uploads (binary fields)](#file-uploads-binary-fields)
  - [File upload via postCustomerFile](#file-upload-via-postcustomerfile)
  - [Custom fields and files](#custom-fields-and-files)
- [Put customer verification (deprecated)](#put-customer-verification-deprecated)
- [Put customer callback](#put-customer-callback)
- [Get customer files](#get-customer-files)
- [Delete customer](#delete-customer)
- [Error handling](#error-handling)
- [Response reference](#response-reference)
- [Common pitfalls](#common-pitfalls)

---

## Service initialization

### From domain (recommended)

`KycService.forDomain()` fetches the anchor's `stellar.toml`, reads `KYC_SERVER` (falls back to `TRANSFER_SERVER`), and returns a configured `KycService`. Returns `KycServiceForDomainEnum`.

```swift
import stellarsdk

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

`forDomain` looks for `KYC_SERVER` first; if absent, it falls back to `TRANSFER_SERVER`.

### Direct construction

Use when you already know the KYC endpoint URL.

```swift
import stellarsdk

let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")
```

Constructor signature:
```
KycService(kycServiceAddress: String)
```

Public property:
- `kycServiceAddress: String` — the base URL of the KYC endpoint

---

## Get customer info

Check the status of a customer's KYC process or fetch the fields the anchor requires.

```swift
import stellarsdk

// Build request — only jwt is required
var request = GetCustomerInfoRequest(jwt: jwtToken)

// Optional: identify an existing customer
request.id = customerId          // anchor-assigned ID from a previous PUT
request.account = "GABC..."     // Stellar account (inferred from JWT sub; legacy)
request.memo = "12345"           // integer memo for shared/omnibus accounts
request.memoType = "id"          // deprecated; memos are always type id

// Optional: filter what fields are required
request.type = "sep6-deposit"    // customer type; affects required fields
request.transactionId = "tx_abc" // link to a specific transaction
request.lang = "en"              // ISO 639-1; defaults to "en"

let result = await kycService.getCustomerInfo(request: request)
switch result {
case .success(let response):
    // response.status — ACCEPTED, PROCESSING, NEEDS_INFO, or REJECTED
    print("Status: \(response.status)")
    print("ID: \(response.id ?? "not yet assigned")")
    print("Message: \(response.message ?? "")")

    // Fields the anchor still needs (present when status is NEEDS_INFO)
    if let fields = response.fields {
        for (fieldName, field) in fields {
            let required = (field.optional == true) ? "optional" : "required"
            print("\(fieldName) (\(required)): \(field.description)")
            // field.type — "string", "binary", "number", or "date"
            if let choices = field.choices {
                print("  Valid values: \(choices.joined(separator: ", "))")
            }
        }
    }

    // Fields already submitted and their validation status
    if let providedFields = response.providedFields {
        for (fieldName, field) in providedFields {
            print("\(fieldName): \(field.status ?? "unknown")")
            if field.status == "REJECTED" {
                print("  Reason: \(field.error ?? "")")
            }
        }
    }

case .failure(let error):
    print("Error: \(error)")
}
```

`GetCustomerInfoRequest` init signature:
```
init(jwt: String)
```

All other fields are optional var properties set after init.

---

## Put customer info

Submit or update customer data. Returns a `PutCustomerInfoResponse` with an `id: String` — save this ID for future requests.

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

// To update an existing customer, set their anchor-assigned ID
// request.id = customerId

// Optional routing fields
request.account = "GABC..."      // Stellar account (inferred from JWT sub)
request.memo = "12345"           // memo for shared/omnibus accounts
request.type = "sep6-deposit"    // customer type

let result = await kycService.putCustomerInfo(request: request)
switch result {
case .success(let response):
    // response.id — always present (non-optional String)
    let customerId = response.id
    print("Customer ID: \(customerId)")
case .failure(let error):
    print("Error: \(error)")
}
```

`PutCustomerInfoRequest` init signature:
```
init(jwt: String)
```

All other fields are optional var properties set after init. KYC data is assigned via the typed field array properties below.

### Natural person fields

Use `KYCNaturalPersonFieldsEnum` cases. Assign an array to `request.fields`.

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.fields = [
    // Name
    .firstName("Jane"),
    .lastName("Doe"),
    .additionalName("Marie"),           // middle name

    // Address
    .address("123 Main St, Apt 4B"),
    .city("San Francisco"),
    .stateOrProvince("CA"),
    .postalCode("94102"),
    .addressCountryCode("USA"),         // ISO 3166-1 alpha-3

    // Contact
    .mobileNumber("+14155551234"),      // E.164 format
    .mobileNumberFormat("E.164"),       // optional; defaults to E.164
    .emailAddress("jane@example.com"),
    .languageCode("en"),                // ISO 639-1

    // Birth
    .birthDate(Date()),                 // Date object; formatted as ISO 8601
    .birthPlace("New York, NY"),
    .birthCountryCode("USA"),           // ISO 3166-1 alpha-3

    // Tax
    .taxId("123-45-6789"),
    .taxIdName("SSN"),

    // Employment
    .occupation(2512),                  // Int: ISCO-08 code
    .employerName("Acme Corp"),
    .employerAddress("456 Business Ave, New York, NY"),

    // ID document
    .idType("passport"),               // passport, drivers_license, id_card, etc.
    .idNumber("AB123456"),
    .idCountryCode("USA"),
    .idIssueDate("2020-01-15"),        // String (not Date)
    .idExpirationDate("2030-01-15"),   // String (not Date)

    // Other
    .sex("female"),                    // male, female, or other
    .ipAddress("192.168.1.1"),
    .referralId("REF123"),
]

let result = await kycService.putCustomerInfo(request: request)
```

All `KYCNaturalPersonFieldsEnum` cases:

| Case | Associated type | Field key sent |
|------|----------------|----------------|
| `.firstName(String)` | String | `first_name` |
| `.lastName(String)` | String | `last_name` |
| `.additionalName(String)` | String | `additional_name` |
| `.address(String)` | String | `address` |
| `.city(String)` | String | `city` |
| `.stateOrProvince(String)` | String | `state_or_province` |
| `.postalCode(String)` | String | `postal_code` |
| `.addressCountryCode(String)` | String | `address_country_code` |
| `.mobileNumber(String)` | String | `mobile_number` |
| `.mobileNumberFormat(String)` | String | `mobile_number_format` |
| `.emailAddress(String)` | String | `email_address` |
| `.languageCode(String)` | String | `language_code` |
| `.birthDate(Date)` | Date | `birth_date` |
| `.birthPlace(String)` | String | `birth_place` |
| `.birthCountryCode(String)` | String | `birth_country_code` |
| `.taxId(String)` | String | `tax_id` |
| `.taxIdName(String)` | String | `tax_id_name` |
| `.occupation(Int)` | Int | `occupation` |
| `.employerName(String)` | String | `employer_name` |
| `.employerAddress(String)` | String | `employer_address` |
| `.idType(String)` | String | `id_type` |
| `.idNumber(String)` | String | `id_number` |
| `.idCountryCode(String)` | String | `id_country_code` |
| `.idIssueDate(String)` | String | `id_issue_date` |
| `.idExpirationDate(String)` | String | `id_expiration_date` |
| `.sex(String)` | String | `sex` |
| `.ipAddress(String)` | String | `ip_address` |
| `.referralId(String)` | String | `referral_id` |
| `.photoIdFront(Data)` | Data | `photo_id_front` |
| `.photoIdBack(Data)` | Data | `photo_id_back` |
| `.notaryApprovalOfPhotoId(Data)` | Data | `notary_approval_of_photo_id` |
| `.photoProofResidence(Data)` | Data | `photo_proof_residence` |
| `.proofOfIncome(Data)` | Data | `proof_of_income` |
| `.proofOfLiveness(Data)` | Data | `proof_of_liveness` |

### Organization fields

Use `KYCOrganizationFieldsEnum` cases. Assign an array to `request.organizationFields`. All keys are automatically sent with the `organization.` prefix.

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.organizationFields = [
    .name("Acme Corporation"),                    // organization.name
    .VATNumber("DE123456789"),                    // organization.VAT_number
    .registrationNumber("HRB 12345"),             // organization.registration_number
    .registrationDate("2010-06-15"),              // organization.registration_date
    .registeredAddress("456 Business Ave"),       // organization.registered_address
    .city("New York"),                            // organization.city
    .stateOrProvince("NY"),                       // organization.state_or_province
    .postalCode("10001"),                         // organization.postal_code
    .addressCountryCode("USA"),                   // organization.address_country_code
    .numberOfShareholders(3),                     // organization.number_of_shareholders (Int)
    .shareholderName("John Smith"),               // organization.shareholder_name
    .directorName("Jane Doe"),                    // organization.director_name
    .website("https://acme.example.com"),         // organization.website
    .email("contact@acme.example.com"),           // organization.email
    .phone("+12125551234"),                       // organization.phone
    // Binary documents:
    .photoIncorporationDoc(incorporationData),    // organization.photo_incorporation_doc
    .photoProofAddress(utilityBillData),          // organization.photo_proof_address
]

let result = await kycService.putCustomerInfo(request: request)
```

All `KYCOrganizationFieldsEnum` cases:

| Case | Associated type | Field key sent |
|------|----------------|----------------|
| `.name(String)` | String | `organization.name` |
| `.VATNumber(String)` | String | `organization.VAT_number` |
| `.registrationNumber(String)` | String | `organization.registration_number` |
| `.registrationDate(String)` | String | `organization.registration_date` |
| `.registeredAddress(String)` | String | `organization.registered_address` |
| `.city(String)` | String | `organization.city` |
| `.stateOrProvince(String)` | String | `organization.state_or_province` |
| `.postalCode(String)` | String | `organization.postal_code` |
| `.addressCountryCode(String)` | String | `organization.address_country_code` |
| `.numberOfShareholders(Int)` | Int | `organization.number_of_shareholders` |
| `.shareholderName(String)` | String | `organization.shareholder_name` |
| `.directorName(String)` | String | `organization.director_name` |
| `.website(String)` | String | `organization.website` |
| `.email(String)` | String | `organization.email` |
| `.phone(String)` | String | `organization.phone` |
| `.photoIncorporationDoc(Data)` | Data | `organization.photo_incorporation_doc` |
| `.photoProofAddress(Data)` | Data | `organization.photo_proof_address` |

### Financial account fields

Use `KYCFinancialAccountFieldsEnum` cases. Assign an array to `request.financialAccountFields`.

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

// Set person identity fields
request.fields = [.firstName("Jane"), .lastName("Doe")]

// Add banking details
request.financialAccountFields = [
    .bankName("First National Bank"),
    .bankAccountType("checking"),          // checking or savings
    .bankAccountNumber("1234567890"),
    .bankNumber("021000021"),              // routing number (US)
    .bankBranchNumber("001"),
    .bankPhoneNumber("+18005551234"),      // E.164
    .externalTransferMemo("WIRE-REF-12345"),
    .clabeNumber("032180000118359719"),    // Mexico CLABE
    .cbuNumber("0110000000001234567890"),  // Argentina CBU/CVU
    .cbuAlias("mi.cuenta.arg"),
    .mobileMoneyNumber("+254712345678"),
    .mobileMoneyProvider("M-Pesa"),
    .cryptoAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f0AB12"),
    .cryptoMemo("tag123"),
]

let result = await kycService.putCustomerInfo(request: request)
```

All `KYCFinancialAccountFieldsEnum` cases:

| Case | Field key sent |
|------|----------------|
| `.bankName(String)` | `bank_name` |
| `.bankAccountType(String)` | `bank_account_type` |
| `.bankAccountNumber(String)` | `bank_account_number` |
| `.bankNumber(String)` | `bank_number` |
| `.bankPhoneNumber(String)` | `bank_phone_number` |
| `.bankBranchNumber(String)` | `bank_branch_number` |
| `.externalTransferMemo(String)` | `external_transfer_memo` |
| `.clabeNumber(String)` | `clabe_number` |
| `.cbuNumber(String)` | `cbu_number` |
| `.cbuAlias(String)` | `cbu_alias` |
| `.mobileMoneyNumber(String)` | `mobile_money_number` |
| `.mobileMoneyProvider(String)` | `mobile_money_provider` |
| `.cryptoAddress(String)` | `crypto_address` |
| `.cryptoMemo(String)` | `crypto_memo` |

### Card fields

Use `KYCCardFieldsEnum` cases. Assign an array to `request.cardFields`. All keys use the `card.` prefix.

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.cardFields = [
    .number("4111111111111111"),
    .expirationDate("29-11"),         // YY-MM format (e.g. November 2029)
    .cvc("123"),
    .holderName("Jane Doe"),
    .network("Visa"),
    .postalCode("94102"),
    .countryCode("US"),               // ISO 3166-1 alpha-2
    .stateOrProvince("CA-CA"),        // ISO 3166-2
    .city("San Francisco"),
    .address("123 Main St"),
    .token("tok_visa"),               // external payment system token
]
```

All `KYCCardFieldsEnum` cases:

| Case | Field key sent |
|------|----------------|
| `.number(String)` | `card.number` |
| `.expirationDate(String)` | `card.expiration_date` |
| `.cvc(String)` | `card.cvc` |
| `.holderName(String)` | `card.holder_name` |
| `.network(String)` | `card.network` |
| `.postalCode(String)` | `card.postal_code` |
| `.countryCode(String)` | `card.country_code` |
| `.stateOrProvince(String)` | `card.state_or_province` |
| `.city(String)` | `card.city` |
| `.address(String)` | `card.address` |
| `.token(String)` | `card.token` |

### File uploads (binary fields)

Binary fields (photos, documents) are passed as `Data` values inside `KYCNaturalPersonFieldsEnum` or `KYCOrganizationFieldsEnum` cases. The SDK sends them via multipart/form-data automatically, placing binary fields after text fields.

```swift
import stellarsdk

// Load image data from disk or camera
let idFrontData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/id_front.jpg"))
let idBackData  = try Data(contentsOf: URL(fileURLWithPath: "/path/to/id_back.jpg"))

var request = PutCustomerInfoRequest(jwt: jwtToken)
request.id = customerId   // update existing customer

request.fields = [
    .idType("passport"),
    .idNumber("AB123456"),
    .idCountryCode("USA"),
    // Binary fields — passed as Data:
    .photoIdFront(idFrontData),
    .photoIdBack(idBackData),
    .notaryApprovalOfPhotoId(notaryData),
    .photoProofResidence(utilityBillData),
    .proofOfIncome(bankStatementData),
    .proofOfLiveness(selfieVideoData),
]

let result = await kycService.putCustomerInfo(request: request)
```

Binary fields on `KYCNaturalPersonFieldsEnum`:

| Case | Field key sent |
|------|----------------|
| `.photoIdFront(Data)` | `photo_id_front` |
| `.photoIdBack(Data)` | `photo_id_back` |
| `.notaryApprovalOfPhotoId(Data)` | `notary_approval_of_photo_id` |
| `.photoProofResidence(Data)` | `photo_proof_residence` |
| `.proofOfIncome(Data)` | `proof_of_income` |
| `.proofOfLiveness(Data)` | `proof_of_liveness` |

Binary fields on `KYCOrganizationFieldsEnum`:

| Case | Field key sent |
|------|----------------|
| `.photoIncorporationDoc(Data)` | `organization.photo_incorporation_doc` |
| `.photoProofAddress(Data)` | `organization.photo_proof_address` |

### File upload via postCustomerFile

Upload a binary file first, then reference it by `fileId` in a subsequent `PUT /customer` request. Use the `{field_name}_file_id` naming convention in `extraFields`.

```swift
import stellarsdk

// Step 1: Upload the file
let imageData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/passport.jpg"))

let uploadResult = await kycService.postCustomerFile(file: imageData, jwtToken: jwtToken)
switch uploadResult {
case .success(let fileResponse):
    print("File ID: \(fileResponse.fileId)")
    print("Content-Type: \(fileResponse.contentType)")
    print("Size: \(fileResponse.size) bytes")
    print("Customer ID: \(fileResponse.customerId ?? "not yet linked")")
    if let expiresAt = fileResponse.expiresAt {
        print("Expires: \(expiresAt)")
    }

    // Step 2: Reference file in PUT /customer using {field_name}_file_id
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

`postCustomerFile` signature:
```
func postCustomerFile(file: Data, jwtToken: String) async -> PostCustomerFileResponseEnum
```

### Custom fields and files

For anchor-specific fields not covered by SEP-9, use `extraFields` (text) and `extraFiles` (binary).

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)
request.jwt = jwtToken
request.id = customerId

// Custom text fields — [String: String]
request.extraFields = [
    "custom_field_1": "custom value",
    "anchor_specific_id": "ABC123",
]

// Custom binary files — [String: Data]
request.extraFiles = [
    "additional_document": documentData,
]

let result = await kycService.putCustomerInfo(request: request)
```

---

## Put customer verification (deprecated)

The `PUT /customer/verification` endpoint is deprecated. Supported for backwards compatibility. Returns `GetCustomerInfoResponseEnum` (same type as `getCustomerInfo()`), not `PutCustomerInfoResponseEnum`.

```swift
import stellarsdk

// DEPRECATED: use PUT /customer with extraFields instead
let request = PutCustomerVerificationRequest(
    id: customerId,   // required: anchor-assigned customer ID
    fields: [
        "mobile_number_verification": "2735021",
        "email_address_verification": "T32U1",
    ],
    jwt: jwtToken
)

// Returns GetCustomerInfoResponseEnum, not PutCustomerInfoResponseEnum
let result = await kycService.putCustomerVerification(request: request)
switch result {
case .success(let response):
    // response is GetCustomerInfoResponse — check status
    print("Status: \(response.status)")  // ACCEPTED, NEEDS_INFO, etc.
case .failure(let error):
    print("Error: \(error)")
}
```

`PutCustomerVerificationRequest` init signature (all parameters required):
```
init(id: String, fields: [String: String], jwt: String)
```

The `fields` dictionary maps SEP-9 field names with `_verification` suffix to the codes received by the customer (e.g. SMS or email codes).

---

## Put customer callback

Register a URL to receive POST notifications when a customer's KYC status changes. The new URL replaces any previously registered callback.

```swift
import stellarsdk

var request = PutCustomerCallbackRequest(
    url: "https://myapp.com/kyc-callback",
    jwt: jwtToken
)

// Identify customer — use one of: id, account, or account+memo
request.id = customerId      // preferred: anchor-assigned ID
// request.account = "GABC..."  // or Stellar account
// request.memo = "12345"        // with memo for shared accounts
// request.memoType = "id"       // deprecated

// Returns PutCustomerCallbackResponseEnum (no associated value on success)
let result = await kycService.putCustomerCallback(request: request)
switch result {
case .success:
    print("Callback registered")
case .failure(let error):
    switch error {
    case .badRequest(let message):
        print("Invalid callback URL: \(message)")
    case .notFound(let message):
        print("Customer not found: \(message)")
    default:
        print("Error: \(error)")
    }
}
```

`PutCustomerCallbackRequest` init signature:
```
init(url: String, jwt: String)
```

Optional var properties: `id`, `account`, `memo`, `memoType`.

The anchor's POST to your callback URL uses the same JSON shape as `GET /customer` responses.

---

## Get customer files

Retrieve metadata about files uploaded via `postCustomerFile`. Filter by `fileId`, `customerId`, or neither.

```swift
import stellarsdk

// All files (no filter)
let result = await kycService.getCustomerFiles(jwtToken: jwtToken)

// Filter by file ID
let result = await kycService.getCustomerFiles(fileId: "file_abc123", jwtToken: jwtToken)

// Filter by customer ID
let result = await kycService.getCustomerFiles(customerId: customerId, jwtToken: jwtToken)

// Both filters
let result = await kycService.getCustomerFiles(
    fileId: "file_abc123",
    customerId: customerId,
    jwtToken: jwtToken
)

switch result {
case .success(let response):
    // response.files — [CustomerFileResponse]; empty array if no files found
    for file in response.files {
        print("File: \(file.fileId)")
        print("  Type: \(file.contentType)")
        print("  Size: \(file.size) bytes")
        print("  Customer: \(file.customerId ?? "not linked")")
        if let expiresAt = file.expiresAt {
            print("  Expires: \(expiresAt)")
        }
    }
case .failure(let error):
    print("Error: \(error)")
}
```

`getCustomerFiles` signature:
```
func getCustomerFiles(fileId: String? = nil, customerId: String? = nil, jwtToken: String) async -> GetCustomerFilesResponseEnum
```

Note: `jwtToken` is the third parameter; `fileId` and `customerId` are optional and default to `nil`.

---

## Delete customer

Delete all personal data stored by the anchor for a given Stellar account. Used for GDPR compliance.

```swift
import stellarsdk

// First parameter is the Stellar account ID (G... address), not the customer UUID
let result = await kycService.deleteCustomerInfo(account: "GABC...", jwt: jwtToken)
switch result {
case .success:
    print("Customer data deleted")
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

`deleteCustomerInfo` signature:
```
func deleteCustomerInfo(account: String, jwt: String) async -> DeleteCustomerResponseEnum
```

`DeleteCustomerResponseEnum` has no associated value on `.success`.

---

## Error handling

All methods return result enums. The `KycServiceError` enum covers all error cases:

```swift
import stellarsdk

let result = await kycService.putCustomerInfo(request: request)
switch result {
case .success(let response):
    print("Customer ID: \(response.id)")
case .failure(let error):
    switch error {
    case .badRequest(let message):
        // HTTP 400 — invalid field value, missing required field, unrecognized parameter
        print("Bad request: \(message)")
    case .unauthorized(let message):
        // HTTP 401 — JWT invalid, expired, or missing
        print("Auth failed: \(message)")
    case .notFound(let message):
        // HTTP 404 — customer ID not found or created by a different account
        print("Not found: \(message)")
    case .payloadTooLarge(let message):
        // HTTP 413 — uploaded file exceeds server size limit
        print("File too large: \(message ?? "no details")")
    case .parsingResponseFailed(let message):
        // Server returned unexpected JSON format
        print("Parse error: \(message)")
    case .invalidDomain:
        print("Domain URL is malformed")
    case .invalidToml:
        print("stellar.toml could not be fetched or parsed")
    case .noKycOrTransferServerSet:
        print("stellar.toml has no KYC_SERVER or TRANSFER_SERVER")
    case .horizonError(let horizonError):
        // Network failure or unexpected server response
        print("Network error: \(horizonError)")
    }
}
```

`KycServiceError` cases summary:

| Case | Trigger |
|------|---------|
| `.invalidDomain` | Domain URL is malformed in `forDomain()` |
| `.invalidToml` | `stellar.toml` could not be fetched or parsed |
| `.noKycOrTransferServerSet` | `stellar.toml` has no `KYC_SERVER` or `TRANSFER_SERVER` |
| `.parsingResponseFailed(message: String)` | Server returned unexpected JSON |
| `.badRequest(error: String)` | HTTP 400 |
| `.notFound(error: String)` | HTTP 404 |
| `.unauthorized(message: String)` | HTTP 401 |
| `.payloadTooLarge(error: String?)` | HTTP 413; error string may be nil |
| `.horizonError(error: HorizonRequestError)` | Network or unexpected server error |

---

## Response reference

### GetCustomerInfoResponse

Returned by `getCustomerInfo()` and `putCustomerVerification()`.

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String?` | Anchor-assigned customer ID; nil if not yet registered |
| `status` | `String` | `ACCEPTED`, `PROCESSING`, `NEEDS_INFO`, or `REJECTED` |
| `fields` | `[String: GetCustomerInfoField]?` | Fields anchor has not yet received; present when `NEEDS_INFO` |
| `providedFields` | `[String: GetCustomerInfoProvidedField]?` | Fields already submitted and their status |
| `message` | `String?` | Human-readable description of the current KYC state |

### GetCustomerInfoField

Describes a field the anchor still needs from the customer.

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | `"string"`, `"binary"`, `"number"`, or `"date"` |
| `description` | `String` | Human-readable field description |
| `choices` | `[String]?` | Valid values; nil if unconstrained |
| `optional` | `Bool?` | `true` = optional; `false` or nil = required |

### GetCustomerInfoProvidedField

Describes a field the customer has already submitted. Same properties as `GetCustomerInfoField`, plus:

| Property | Type | Description |
|----------|------|-------------|
| `status` | `String?` | `ACCEPTED`, `PROCESSING`, `REJECTED`, or `VERIFICATION_REQUIRED` |
| `error` | `String?` | Rejection reason when `status == "REJECTED"` |

### PutCustomerInfoResponse

Returned by `putCustomerInfo()`.

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Anchor-assigned customer ID (always present, non-optional) |

### CustomerFileResponse

Returned by `postCustomerFile()` and in `GetCustomerFilesResponse.files`.

| Property | Type | Description |
|----------|------|-------------|
| `fileId` | `String` | Unique file identifier |
| `contentType` | `String` | MIME type (e.g. `"image/jpeg"`, `"image/png"`) |
| `size` | `Int` | File size in bytes |
| `expiresAt` | `Date?` | Expiry date; file discarded if not linked to a customer by this time |
| `customerId` | `String?` | Linked customer ID; nil if not yet linked |

### GetCustomerFilesResponse

Returned by `getCustomerFiles()`.

| Property | Type | Description |
|----------|------|-------------|
| `files` | `[CustomerFileResponse]` | List of file metadata; empty array if no files found |

---

## Common pitfalls

**WRONG: passing a customer UUID to `deleteCustomerInfo(account:)` — it expects a Stellar account ID**

```swift
// WRONG: passing the anchor-assigned customer ID (UUID)
await kycService.deleteCustomerInfo(account: "391fb415-c223-4608-b2f5-dd1e91e3a986", jwt: jwt)  // 404

// CORRECT: first argument is the Stellar account ID (G... address)
await kycService.deleteCustomerInfo(account: "GABC...stellarAccountId", jwt: jwt)
```

**WRONG: `putCustomerVerification()` returns `GetCustomerInfoResponseEnum`, not `PutCustomerInfoResponseEnum`**

```swift
// WRONG: treating the response as a PutCustomerInfoResponse (which has non-optional id: String)
let result = await kycService.putCustomerVerification(request: request)
if case .success(let response) = result {
    let id = response.id  // This is GetCustomerInfoResponse.id which is String? (optional)
}

// CORRECT: use response.status to confirm verification
if case .success(let response) = result {
    print(response.status)  // "ACCEPTED", "NEEDS_INFO", etc.
}
```

**WRONG: `birthDate` takes `Date`, but `idIssueDate` and `idExpirationDate` take `String`**

```swift
// WRONG: passing Date to idIssueDate — it expects String
request.fields = [.idIssueDate(Date())]   // compile error: expected String

// CORRECT: idIssueDate and idExpirationDate are String; birthDate is Date
request.fields = [
    .birthDate(Date()),             // Date — formatted to ISO 8601 by SDK
    .idIssueDate("2020-01-15"),     // String — you provide the date string directly
    .idExpirationDate("2030-01-15"),
]
```

**WRONG: `PutCustomerInfoResponse.id` is non-optional `String`, unlike `GetCustomerInfoResponse.id`**

```swift
// GetCustomerInfoResponse.id is optional (String?)
let getResult = await kycService.getCustomerInfo(request: request)
if case .success(let response) = getResult {
    let id = response.id ?? "not yet assigned"  // must unwrap
}

// PutCustomerInfoResponse.id is non-optional (String)
let putResult = await kycService.putCustomerInfo(request: request)
if case .success(let response) = putResult {
    let id = response.id  // CORRECT: no unwrap needed
}
```

**WRONG: referencing an uploaded file by the file ID directly instead of using the `_file_id` suffix**

```swift
// WRONG: passing fileId as the field value for a binary field
request.fields = [.photoIdFront(fileResponse.fileId.data(using: .utf8)!)]

// CORRECT: use extraFields with {field_name}_file_id key
request.extraFields = ["photo_id_front_file_id": fileResponse.fileId]
```

**WRONG: calling `getCustomerFiles` without labeling `jwtToken`**

```swift
// WRONG: positional — fileId maps to jwtToken parameter
await kycService.getCustomerFiles("200_jwt")   // compile error or wrong behavior

// CORRECT: jwtToken is the third labeled parameter; first two are optional
await kycService.getCustomerFiles(jwtToken: jwtToken)
await kycService.getCustomerFiles(fileId: "file_abc", jwtToken: jwtToken)
await kycService.getCustomerFiles(customerId: customerId, jwtToken: jwtToken)
```

---

## Customer statuses

| Status | Meaning |
|--------|---------|
| `ACCEPTED` | All required info verified. Customer may proceed. |
| `PROCESSING` | Info under review. Check back later. |
| `NEEDS_INFO` | Additional fields required. See `response.fields`. |
| `REJECTED` | Permanently rejected. See `response.message` for reason. |

## Field statuses (in providedFields)

| Status | Meaning |
|--------|---------|
| `ACCEPTED` | Field validated. |
| `PROCESSING` | Field under review. |
| `REJECTED` | Field rejected. See `field.error` for reason. |
| `VERIFICATION_REQUIRED` | Code sent to customer (SMS/email); submit code via `putCustomerVerification()`. |
