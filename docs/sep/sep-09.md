# SEP-09: Standard KYC Fields

SEP-09 defines a standard vocabulary for KYC (Know Your Customer) and AML (Anti-Money Laundering) data fields. When different services need to exchange customer information (deposits, withdrawals, cross-border payments), they use these field names so everyone speaks the same language.

**Use SEP-09 when:**
- Submitting KYC data via SEP-12
- Providing customer info for SEP-24 interactive flows
- Building anchor services that collect customer information

**Spec:** [SEP-0009 v1.18.0](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)

## Quick Example

This example shows how to create basic KYC fields for an individual customer and prepare them for API submission via a `PutCustomerInfoRequest`:

```swift
import stellarsdk

// Build KYC fields for an individual and assign to a request
var request = PutCustomerInfoRequest(jwt: jwtToken)
request.fields = [
    .firstName("John"),
    .lastName("Doe"),
    .emailAddress("john@example.com"),
    .birthDate(birthDate),  // Date object — SDK formats to ISO 8601 automatically
]

// The request is now ready to submit via KycService.putCustomerInfo(request:)
```

## Detailed Usage

### Natural Person Fields

Use `KYCNaturalPersonFieldsEnum` when collecting KYC data for individual customers. This enum covers personal identification, contact information, address, employment, tax, and identity document fields. Note that the spec also accepts `family_name`/`given_name` as aliases for `last_name`/`first_name`, but the SDK uses the more common `.lastName`/`.firstName` case names:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.fields = [
    // Personal identification
    .firstName("Maria"),             // Maps to 'first_name' (spec also accepts 'given_name')
    .lastName("Garcia"),             // Maps to 'last_name' (spec also accepts 'family_name')
    .additionalName("Elena"),        // Middle name
    .birthDate(birthDate),           // Date object — serialized as ISO 8601 automatically
    .birthPlace("Madrid, Spain"),
    .birthCountryCode("ESP"),        // ISO 3166-1 alpha-3
    .sex("female"),                  // "male", "female", or "other"

    // Contact information
    .emailAddress("maria@example.com"),
    .mobileNumber("+34612345678"),   // E.164 format
    .mobileNumberFormat("E.164"),    // Specify expected format (optional, defaults to E.164)

    // Current address
    .addressCountryCode("ESP"),      // ISO 3166-1 alpha-3
    .stateOrProvince("Madrid"),
    .city("Madrid"),
    .postalCode("28001"),
    .address("Calle Mayor 10\n28001 Madrid\nSpain"),  // Multi-line full address

    // Employment
    .occupation(2511),               // Int — ISCO-08 code (Software developer)
    .employerName("Tech Corp"),
    .employerAddress("Paseo de la Castellana 50, Madrid"),

    // Tax information
    .taxId("12345678Z"),
    .taxIdName("NIF"),               // Name of tax ID type (SSN, ITIN, NIF, etc.)

    // Identity document
    .idType("passport"),                     // "passport", "drivers_license", "id_card", etc.
    .idNumber("AB1234567"),
    .idCountryCode("ESP"),                   // ISO 3166-1 alpha-3
    .idIssueDate("2020-01-15"),              // String, not Date
    .idExpirationDate("2030-01-14"),         // String, not Date

    // Other
    .languageCode("es"),             // ISO 639-1
    .ipAddress("192.168.1.1"),
    .referralId("partner-12345"),    // Origin or referral code
]
```

### Document Uploads

Binary files (photos, documents) are passed as `Data` values within the same `fields` array. The SDK separates text fields and binary files internally when building the multipart/form-data request body:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

// Load raw file bytes — the SDK handles multipart encoding internally
let idFrontData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/passport-front.jpg"))
let idBackData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/passport-back.jpg"))
let notaryData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/notary-approval.pdf"))
let utilityBillData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/utility-bill.pdf"))
let payslipData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/payslip.pdf"))
let selfieVideoData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/selfie-video.mp4"))

request.fields = [
    .firstName("John"),
    .lastName("Doe"),
    // Binary document fields
    .photoIdFront(idFrontData),
    .photoIdBack(idBackData),
    .notaryApprovalOfPhotoId(notaryData),
    .photoProofResidence(utilityBillData),
    .proofOfIncome(payslipData),
    .proofOfLiveness(selfieVideoData),
]
```

> **Note:** Do not base64-encode file contents. The SDK sends file data as raw bytes via multipart/form-data.

### Organization Fields

Use `KYCOrganizationFieldsEnum` for business customers. All organization field keys are automatically sent with the `organization.` prefix to match the SEP-09 dot notation convention:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.organizationFields = [
    // Corporate identity
    .name("Acme Corporation S.L."),
    .VATNumber("ESB12345678"),
    .registrationNumber("B-12345678"),
    .registrationDate("2015-06-01"),          // ISO 8601 date string
    .registeredAddress("Calle Gran Via 100, 28013 Madrid, Spain"),

    // Corporate structure
    .numberOfShareholders(3),                 // Int
    .shareholderName("John Smith"),           // Query recursively for all UBOs
    .directorName("Jane Doe"),

    // Contact details
    .addressCountryCode("ESP"),               // ISO 3166-1 alpha-3
    .stateOrProvince("Madrid"),
    .city("Madrid"),
    .postalCode("28013"),
    .website("https://acme-corp.example.com"),
    .email("compliance@acme-corp.example.com"),
    .phone("+34911234567"),                   // E.164 format
]

// Organization fields use 'organization.' prefix automatically
// e.g. .name("Acme Corporation S.L.") sends as 'organization.name'
```

Organization documents can also be uploaded as `Data` values within the `organizationFields` array. The SDK places them at the end of the multipart body with the appropriate `organization.` prefix:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

// Documents (raw bytes)
let incorporationData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/incorporation.pdf"))
let businessUtilityBillData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/business-utility-bill.pdf"))

request.organizationFields = [
    .name("Acme Corporation S.L."),
    .photoIncorporationDoc(incorporationData),
    .photoProofAddress(businessUtilityBillData),
]
// Binary fields send as 'organization.photo_incorporation_doc', 'organization.photo_proof_address'
```

### Financial Account Fields

`KYCFinancialAccountFieldsEnum` supports bank accounts, crypto addresses, and mobile money for both individuals and organizations. It covers a wide variety of regional banking formats:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

// Personal identification
request.fields = [
    .firstName("John"),
    .lastName("Doe"),
]

// Add bank account details
request.financialAccountFields = [
    .bankName("First National Bank"),          // Bank name (useful in regions without unified routing)
    .bankAccountType("checking"),              // "checking" or "savings"
    .bankAccountNumber("123456789012"),
    .bankNumber("021000021"),                  // Routing number (US)
    .bankBranchNumber("001"),
    .bankPhoneNumber("+12025551234"),           // Bank contact number (E.164)

    // Regional bank formats
    .clabeNumber("012345678901234567"),         // Mexico (CLABE)
    .cbuNumber("0123456789012345678901"),       // Argentina (CBU or CVU)
    .cbuAlias("john.doe.acme"),                // Argentina (CBU/CVU alias)

    // Mobile money (common in Africa and Asia)
    .mobileMoneyNumber("+254712345678"),        // May differ from personal mobile
    .mobileMoneyProvider("M-Pesa"),

    // Crypto
    .cryptoAddress("GBH4TZYZ4IRCPO44CBOLFUHULU2WGALXTAVESQA6432MBJMABBB4GIYI"),
    .externalTransferMemo("user-12345"),        // Destination tag/memo

    // Note: .cryptoMemo is deprecated — use .externalTransferMemo instead
]
```

### Card Fields

`KYCCardFieldsEnum` handles credit and debit card information. All card field keys are sent with the `card.` prefix to distinguish them from other fields. When possible, prefer using tokenized card data to minimize PCI-DSS compliance scope:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.fields = [
    .firstName("John"),
    .lastName("Doe"),
]

request.cardFields = [
    // Card details
    .number("4111111111111111"),
    .expirationDate("29-11"),      // YY-MM format (November 2029)
    .cvc("123"),
    .holderName("JOHN DOE"),
    .network("Visa"),              // Visa, Mastercard, AmEx, etc.

    // Billing address
    .address("123 Main St\nApt 4B"),
    .city("New York"),
    .stateOrProvince("NY"),        // ISO 3166-2 format
    .postalCode("10001"),
    .countryCode("US"),            // ISO 3166-1 alpha-2 (note: 2-letter for cards)

    // Prefer tokens over raw card numbers for PCI-DSS compliance
    .token("tok_visa_4242"),       // From Stripe, etc.
]
// Card fields use 'card.' prefix: 'card.number', 'card.expiration_date', etc.
```

### Combining with Organizations

Organizations can also have financial accounts and cards. When nested under an organization, the financial account and card fields are added to the same request alongside the organization fields:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.organizationFields = [
    .name("Acme Corp"),
    .VATNumber("US12-3456789"),
]

request.financialAccountFields = [
    .bankName("Business Bank"),
    .bankAccountNumber("9876543210"),
    .bankNumber("021000021"),
]

// Both organization and financial account fields are sent in the same request
```

### Using Field Key Constants

The field key string for any enum case is available via the `.parameter` property (which returns a `(key: String, value: Data)` tuple). This is useful when you need to reference a specific field key programmatically:

```swift
import stellarsdk

// Natural person field keys — read via .parameter.0
print(KYCNaturalPersonFieldsEnum.firstName("x").parameter.0)          // "first_name"
print(KYCNaturalPersonFieldsEnum.lastName("x").parameter.0)           // "last_name"
print(KYCNaturalPersonFieldsEnum.emailAddress("x").parameter.0)       // "email_address"
print(KYCNaturalPersonFieldsEnum.birthDate(Date()).parameter.0)        // "birth_date"
print(KYCNaturalPersonFieldsEnum.mobileNumberFormat("x").parameter.0) // "mobile_number_format"
print(KYCNaturalPersonFieldsEnum.photoIdFront(Data()).parameter.0)     // "photo_id_front"
print(KYCNaturalPersonFieldsEnum.referralId("x").parameter.0)         // "referral_id"

// Organization field keys (includes "organization." prefix)
print(KYCOrganizationFieldsEnum.name("x").parameter.0)                // "organization.name"
print(KYCOrganizationFieldsEnum.VATNumber("x").parameter.0)           // "organization.VAT_number"
print(KYCOrganizationFieldsEnum.registrationNumber("x").parameter.0)  // "organization.registration_number"

// Financial account field keys
print(KYCFinancialAccountFieldsEnum.bankName("x").parameter.0)             // "bank_name"
print(KYCFinancialAccountFieldsEnum.bankAccountType("x").parameter.0)      // "bank_account_type"
print(KYCFinancialAccountFieldsEnum.clabeNumber("x").parameter.0)          // "clabe_number"
print(KYCFinancialAccountFieldsEnum.cbuNumber("x").parameter.0)            // "cbu_number"
print(KYCFinancialAccountFieldsEnum.mobileMoneyNumber("x").parameter.0)    // "mobile_money_number"
print(KYCFinancialAccountFieldsEnum.externalTransferMemo("x").parameter.0) // "external_transfer_memo"
print(KYCFinancialAccountFieldsEnum.cryptoAddress("x").parameter.0)        // "crypto_address"

// Card field keys (includes "card." prefix)
print(KYCCardFieldsEnum.number("x").parameter.0)          // "card.number"
print(KYCCardFieldsEnum.expirationDate("x").parameter.0)  // "card.expiration_date"
print(KYCCardFieldsEnum.token("x").parameter.0)           // "card.token"
print(KYCCardFieldsEnum.holderName("x").parameter.0)      // "card.holder_name"
```

### Integration with SEP-12

These KYC field enums work directly with the SEP-12 KYC service. Here is how to submit KYC data to an anchor:

```swift
import stellarsdk

// Build the KYC fields in a request
var request = PutCustomerInfoRequest(jwt: jwtToken)
request.fields = [
    .firstName("John"),
    .lastName("Doe"),
    .emailAddress("john@example.com"),
]

// Create KYC service and submit
let kycService = KycService(kycServiceAddress: "https://anchor.example.com/kyc")

let response = await kycService.putCustomerInfo(request: request)
switch response {
case .success(let info):
    print("Customer ID: \(info.id)")
case .failure(let error):
    // Handle errors (network issues, validation failures, etc.)
    print("KYC submission failed: \(error)")
}
```

## Field Reference

### Natural Person Fields

| Field | Type | Description |
|-------|------|-------------|
| `first_name`, `last_name` | String | Name fields (spec also accepts `given_name`, `family_name`) |
| `additional_name` | String | Middle name or other additional name |
| `email_address` | String | Email (RFC 5322) |
| `mobile_number` | String | Phone (E.164 format by default) |
| `mobile_number_format` | String | Expected format of mobile_number (e.g., E.164, hash) |
| `birth_date` | Date | Date of birth (SDK serializes to ISO 8601 automatically) |
| `birth_place` | String | Place of birth as on passport |
| `birth_country_code` | String | ISO 3166-1 alpha-3 |
| `sex` | String | male, female, other |
| `address` | String | Full address as multi-line string |
| `city`, `postal_code` | String | Address fields |
| `state_or_province` | String | State/province/region name |
| `address_country_code` | String | ISO 3166-1 alpha-3 |
| `id_type` | String | passport, drivers_license, id_card |
| `id_number`, `id_country_code` | String | Document details |
| `id_issue_date`, `id_expiration_date` | String | Document dates (provide as "YYYY-MM-DD" string) |
| `tax_id`, `tax_id_name` | String | Tax information |
| `occupation` | Int | ISCO-08 code |
| `employer_name`, `employer_address` | String | Employment details |
| `language_code` | String | ISO 639-1 code |
| `ip_address` | String | Customer's IP address |
| `referral_id` | String | Origin or referral code |

**File fields** (Data):

| Field | Description |
|-------|-------------|
| `photo_id_front` | Front of photo ID or passport |
| `photo_id_back` | Back of photo ID or passport |
| `notary_approval_of_photo_id` | Notary approval of photo ID |
| `photo_proof_residence` | Utility bill, bank statement, etc. |
| `proof_of_income` | Income verification document |
| `proof_of_liveness` | Video or image as liveness proof |

### Organization Fields

All prefixed with `organization.`:

| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Legal name as on incorporation |
| `VAT_number`, `registration_number` | String | Corporate IDs |
| `registration_date` | String | Date registered (ISO 8601) |
| `registered_address` | String | Legal address |
| `number_of_shareholders` | Int | Shareholder count |
| `shareholder_name`, `director_name` | String | Key persons |
| `address_country_code` | String | ISO 3166-1 alpha-3 |
| `state_or_province`, `city`, `postal_code` | String | Address fields |
| `website`, `email`, `phone` | String | Contact info |

**File fields** (Data, prefixed with `organization.`):

| Field | Description |
|-------|-------------|
| `photo_incorporation_doc` | Incorporation documents |
| `photo_proof_address` | Business utility bill, bank statement |

### Financial Account Fields

| Field | Type | Description |
|-------|------|-------------|
| `bank_name` | String | Bank name (useful in regions without unified routing) |
| `bank_account_type` | String | checking, savings |
| `bank_account_number`, `bank_number` | String | Account/routing numbers |
| `bank_branch_number` | String | Branch identifier |
| `bank_phone_number` | String | Bank contact (E.164) |
| `clabe_number` | String | Mexico (CLABE) |
| `cbu_number`, `cbu_alias` | String | Argentina (CBU/CVU) |
| `mobile_money_number` | String | Mobile money phone (E.164) |
| `mobile_money_provider` | String | Mobile money service name |
| `crypto_address` | String | Cryptocurrency address |
| `external_transfer_memo` | String | Destination tag/memo |
| `crypto_memo` | String | **Deprecated** - use `external_transfer_memo` |

### Card Fields

All prefixed with `card.`:

| Field | Type | Description |
|-------|------|-------------|
| `number`, `cvc` | String | Card number and security code |
| `expiration_date` | String | YY-MM format (e.g., 29-11) |
| `holder_name`, `network` | String | Cardholder and brand |
| `token` | String | Payment processor token |
| `address`, `city`, `state_or_province` | String | Billing address |
| `postal_code` | String | Billing postal code |
| `country_code` | String | ISO 3166-1 alpha-2 (2-letter) |

## Error Handling

When submitting KYC data via SEP-12, various errors can occur. Here is how to handle common scenarios:

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)
request.fields = [
    .firstName("John"),
    .lastName("Doe"),
]

let kycService = KycService(kycServiceAddress: "https://anchor.example.com/kyc")

let response = await kycService.putCustomerInfo(request: request)
switch response {
case .success(let info):
    print("Success! Customer ID: \(info.id)")
case .failure(let error):
    // The SDK returns a failure case for HTTP errors and network issues.
    // Check the error for details about the failure
    // (invalid fields, auth errors, customer not found, etc.)
    print("KYC submission failed: \(error)")
}
```

## Security Considerations

- **Transmit over HTTPS only** - KYC data contains sensitive PII
- **Encrypt at rest** - Store collected data encrypted
- **Card data requires PCI-DSS** - Prefer tokenization over raw card numbers
- **Minimize collection** - Only request fields you actually need
- **Respect data regulations** - GDPR, CCPA, and local privacy laws apply
- **Use secure file handling** - Validate and sanitize uploaded documents
- **Implement access controls** - Audit logging and proper authorization

## Related SEPs

- [SEP-12](sep-12.md) - KYC API (submits SEP-09 fields to anchors)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal (may collect SEP-09 data)

---

[Back to SEP Overview](README.md)
