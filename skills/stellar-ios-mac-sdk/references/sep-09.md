# SEP-09: Standard KYC Fields

**Purpose:** Standard vocabulary and definitions for KYC/AML data fields used in SEP-12 customer submissions
**Prerequisites:** None (field definitions only; used with `KycService` from SEP-12)
**SDK Types:** `KYCNaturalPersonFieldsEnum`, `KYCOrganizationFieldsEnum`, `KYCFinancialAccountFieldsEnum`, `KYCCardFieldsEnum`

## Table of Contents

- [Overview](#overview)
- [Natural person fields](#natural-person-fields)
- [Organization fields](#organization-fields)
- [Financial account fields](#financial-account-fields)
- [Card fields](#card-fields)
- [Field key constants](#field-key-constants)
- [Common pitfalls](#common-pitfalls)

---

## Overview

SEP-09 defines a standard vocabulary of KYC/AML field names and data types. The iOS SDK provides four enums whose cases map directly to these field names. You pass arrays of these enum cases to `PutCustomerInfoRequest` when submitting customer data via SEP-12.

```swift
import stellarsdk

// Natural person: request.fields = [KYCNaturalPersonFieldsEnum]
// Organization:   request.organizationFields = [KYCOrganizationFieldsEnum]
// Bank account:   request.financialAccountFields = [KYCFinancialAccountFieldsEnum]
// Card:           request.cardFields = [KYCCardFieldsEnum]
```

Each enum case carries the field value as its associated value. The `.parameter` property on each case returns a `(String, Data)` tuple (unnamed) that the SDK uses to build the multipart/form-data request body — you do not call `.parameter` directly.

SEP-09 fields are used by [SEP-12](sep-12.md) (`PutCustomerInfoRequest.fields`, `.organizationFields`, `.financialAccountFields`, `.cardFields`) and SEP-24.

---

## Natural person fields

`KYCNaturalPersonFieldsEnum` covers individual customer identity and contact data.

### Complete example

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.fields = [
    // Identity
    .firstName("Jane"),
    .lastName("Doe"),
    .additionalName("Marie"),               // middle or additional name
    .sex("female"),                         // "male", "female", or "other"

    // Address
    .address("123 Main St, Apt 4B"),
    .city("San Francisco"),
    .stateOrProvince("CA"),
    .postalCode("94102"),
    .addressCountryCode("USA"),             // ISO 3166-1 alpha-3

    // Contact
    .mobileNumber("+14155551234"),          // E.164 format
    .mobileNumberFormat("E.164"),           // optional; defaults to E.164 if absent
    .emailAddress("jane@example.com"),
    .languageCode("en"),                    // ISO 639-1

    // Birth
    .birthDate(Date()),                     // Date — SDK formats to ISO 8601 automatically
    .birthPlace("New York, NY"),
    .birthCountryCode("USA"),               // ISO 3166-1 alpha-3

    // Tax
    .taxId("123-45-6789"),
    .taxIdName("SSN"),                      // name of the tax ID type (SSN, ITIN, etc.)

    // Employment
    .occupation(2512),                      // Int — ISCO-08 occupational code
    .employerName("Acme Corp"),
    .employerAddress("456 Business Ave, New York, NY"),

    // ID document
    .idType("passport"),                    // passport, drivers_license, id_card, etc.
    .idNumber("AB123456"),
    .idCountryCode("USA"),
    .idIssueDate("2020-01-15"),             // String, not Date
    .idExpirationDate("2030-01-15"),        // String, not Date

    // Network — NOTE: these are string-typed but the SDK places them in the
    // multipart body alongside binary fields (at the end), not with other text fields
    .ipAddress("192.168.1.1"),
    .referralId("REF123"),

    // Binary documents — pass as Data
    .photoIdFront(idFrontData),
    .photoIdBack(idBackData),
    .notaryApprovalOfPhotoId(notaryData),
    .photoProofResidence(utilityBillData),
    .proofOfIncome(bankStatementData),
    .proofOfLiveness(selfieVideoData),
]
```

### All cases

| Case | Associated type | Field key sent | Notes |
|------|----------------|----------------|-------|
| `.firstName(String)` | String | `first_name` | Given or first name |
| `.lastName(String)` | String | `last_name` | Family or last name |
| `.additionalName(String)` | String | `additional_name` | Middle name or other additional name |
| `.sex(String)` | String | `sex` | `"male"`, `"female"`, or `"other"` |
| `.address(String)` | String | `address` | Full address as multi-line string |
| `.city(String)` | String | `city` | City or town name |
| `.stateOrProvince(String)` | String | `state_or_province` | State, province, region, or prefecture |
| `.postalCode(String)` | String | `postal_code` | Postal or other locale code |
| `.addressCountryCode(String)` | String | `address_country_code` | ISO 3166-1 alpha-3 |
| `.mobileNumber(String)` | String | `mobile_number` | With country code, E.164 format |
| `.mobileNumberFormat(String)` | String | `mobile_number_format` | Defaults to E.164 if absent |
| `.emailAddress(String)` | String | `email_address` | |
| `.languageCode(String)` | String | `language_code` | ISO 639-1 |
| `.birthDate(Date)` | **Date** | `birth_date` | SDK formats to ISO 8601 |
| `.birthPlace(String)` | String | `birth_place` | City, state, country as on passport |
| `.birthCountryCode(String)` | String | `birth_country_code` | ISO 3166-1 alpha-3 |
| `.taxId(String)` | String | `tax_id` | Social security number in US |
| `.taxIdName(String)` | String | `tax_id_name` | Name of the tax ID type (SSN, ITIN) |
| `.occupation(Int)` | **Int** | `occupation` | ISCO-08 occupational code |
| `.employerName(String)` | String | `employer_name` | |
| `.employerAddress(String)` | String | `employer_address` | |
| `.idType(String)` | String | `id_type` | `passport`, `drivers_license`, `id_card`, etc. |
| `.idNumber(String)` | String | `id_number` | Passport or ID document number |
| `.idCountryCode(String)` | String | `id_country_code` | ISO 3166-1 alpha-3 |
| `.idIssueDate(String)` | **String** | `id_issue_date` | Date string, e.g. `"2020-01-15"` |
| `.idExpirationDate(String)` | **String** | `id_expiration_date` | Date string, e.g. `"2030-01-15"` |
| `.ipAddress(String)` | String | `ip_address` | Customer's computer IP address |
| `.referralId(String)` | String | `referral_id` | Identifies the source of the customer |
| `.photoIdFront(Data)` | **Data** | `photo_id_front` | Image of front of photo ID or passport |
| `.photoIdBack(Data)` | **Data** | `photo_id_back` | Image of back of photo ID or passport |
| `.notaryApprovalOfPhotoId(Data)` | **Data** | `notary_approval_of_photo_id` | Notary's approval image |
| `.photoProofResidence(Data)` | **Data** | `photo_proof_residence` | Utility bill, bank statement, etc. |
| `.proofOfIncome(Data)` | **Data** | `proof_of_income` | Income document image |
| `.proofOfLiveness(Data)` | **Data** | `proof_of_liveness` | Video or image liveness proof |

---

## Organization fields

`KYCOrganizationFieldsEnum` covers corporate/business entity data. All field keys are automatically sent with the `organization.` prefix.

### Complete example

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.organizationFields = [
    .name("Acme Corporation"),                      // organization.name
    .VATNumber("DE123456789"),                      // organization.VAT_number
    .registrationNumber("HRB 12345"),               // organization.registration_number
    .registrationDate("2010-06-15"),                // organization.registration_date (String)
    .registeredAddress("456 Business Ave"),         // organization.registered_address
    .city("New York"),                              // organization.city
    .stateOrProvince("NY"),                         // organization.state_or_province
    .postalCode("10001"),                           // organization.postal_code
    .addressCountryCode("USA"),                     // organization.address_country_code (ISO 3166-1 alpha-3)
    .numberOfShareholders(3),                       // organization.number_of_shareholders (Int)
    .shareholderName("John Smith"),                 // organization.shareholder_name
    .directorName("Jane Doe"),                      // organization.director_name
    .website("https://acme.example.com"),           // organization.website
    .email("contact@acme.example.com"),             // organization.email
    .phone("+12125551234"),                         // organization.phone
    // Binary documents:
    .photoIncorporationDoc(incorporationData),      // organization.photo_incorporation_doc
    .photoProofAddress(utilityBillData),            // organization.photo_proof_address
]
```

### All cases

| Case | Associated type | Field key sent | Notes |
|------|----------------|----------------|-------|
| `.name(String)` | String | `organization.name` | Full name as on incorporation papers |
| `.VATNumber(String)` | String | `organization.VAT_number` | Note: case is `.VATNumber`, not `.vatNumber` |
| `.registrationNumber(String)` | String | `organization.registration_number` | |
| `.registrationDate(String)` | String | `organization.registration_date` | Date string |
| `.registeredAddress(String)` | String | `organization.registered_address` | |
| `.city(String)` | String | `organization.city` | |
| `.stateOrProvince(String)` | String | `organization.state_or_province` | |
| `.postalCode(String)` | String | `organization.postal_code` | |
| `.addressCountryCode(String)` | String | `organization.address_country_code` | ISO 3166-1 alpha-3 |
| `.numberOfShareholders(Int)` | **Int** | `organization.number_of_shareholders` | |
| `.shareholderName(String)` | String | `organization.shareholder_name` | Can be a person or an organization |
| `.directorName(String)` | String | `organization.director_name` | Registered managing director |
| `.website(String)` | String | `organization.website` | |
| `.email(String)` | String | `organization.email` | |
| `.phone(String)` | String | `organization.phone` | |
| `.photoIncorporationDoc(Data)` | **Data** | `organization.photo_incorporation_doc` | Image of incorporation documents |
| `.photoProofAddress(Data)` | **Data** | `organization.photo_proof_address` | Utility bill or bank statement with org name+address |

---

## Financial account fields

`KYCFinancialAccountFieldsEnum` covers banking and payment account data. All fields are plain strings with no prefix.

### Complete example

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.financialAccountFields = [
    .bankName("First National Bank"),
    .bankAccountType("checking"),              // "checking" or "savings"
    .bankAccountNumber("1234567890"),
    .bankNumber("021000021"),                  // routing number (US)
    .bankBranchNumber("001"),
    .bankPhoneNumber("+18005551234"),           // E.164 format
    .externalTransferMemo("WIRE-REF-12345"),
    .clabeNumber("032180000118359719"),         // Mexico CLABE format
    .cbuNumber("0110000000001234567890"),       // Argentina CBU/CVU
    .cbuAlias("mi.cuenta.arg"),
    .mobileMoneyNumber("+254712345678"),        // E.164; may differ from customer's mobile_number
    .mobileMoneyProvider("M-Pesa"),
    .cryptoAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f0AB12"),
    .cryptoMemo("tag123"),
]
```

### All cases

| Case | Field key sent | Notes |
|------|----------------|-------|
| `.bankName(String)` | `bank_name` | Required in regions without a unified routing system |
| `.bankAccountType(String)` | `bank_account_type` | `"checking"` or `"savings"` |
| `.bankAccountNumber(String)` | `bank_account_number` | |
| `.bankNumber(String)` | `bank_number` | Routing number (US) |
| `.bankPhoneNumber(String)` | `bank_phone_number` | E.164 format |
| `.bankBranchNumber(String)` | `bank_branch_number` | |
| `.externalTransferMemo(String)` | `external_transfer_memo` | Destination tag/memo for the transfer |
| `.clabeNumber(String)` | `clabe_number` | Mexico CLABE format bank account |
| `.cbuNumber(String)` | `cbu_number` | Argentina CBU or CVU |
| `.cbuAlias(String)` | `cbu_alias` | Alias for CBU/CVU |
| `.mobileMoneyNumber(String)` | `mobile_money_number` | E.164; may differ from customer's `mobile_number` |
| `.mobileMoneyProvider(String)` | `mobile_money_provider` | Name of the mobile money provider |
| `.cryptoAddress(String)` | `crypto_address` | Cryptocurrency account address |
| `.cryptoMemo(String)` | `crypto_memo` | Destination tag/memo for a crypto transaction |

---

## Card fields

`KYCCardFieldsEnum` covers payment card data. All field keys are automatically sent with the `card.` prefix.

### Complete example

```swift
import stellarsdk

var request = PutCustomerInfoRequest(jwt: jwtToken)

request.cardFields = [
    .number("4111111111111111"),
    .expirationDate("29-11"),               // YY-MM format (e.g. November 2029)
    .cvc("123"),
    .holderName("Jane Doe"),
    .network("Visa"),                       // Visa, Mastercard, AmEx, etc.
    .postalCode("94102"),                   // billing address postal code
    .countryCode("US"),                     // ISO 3166-1 alpha-2 (note: alpha-2, not alpha-3)
    .stateOrProvince("CA-CA"),              // ISO 3166-2
    .city("San Francisco"),
    .address("123 Main St"),
    .token("tok_visa"),                     // token from an external payment system (e.g. Stripe)
]
```

### All cases

| Case | Field key sent | Notes |
|------|----------------|-------|
| `.number(String)` | `card.number` | Card number |
| `.expirationDate(String)` | `card.expiration_date` | YY-MM format, e.g. `"29-11"` for Nov 2029 |
| `.cvc(String)` | `card.cvc` | Security digits on back of card |
| `.holderName(String)` | `card.holder_name` | Name of the card holder |
| `.network(String)` | `card.network` | Card brand/network (Visa, Mastercard, AmEx, etc.) |
| `.postalCode(String)` | `card.postal_code` | Billing address postal code |
| `.countryCode(String)` | `card.country_code` | ISO 3166-1 alpha-2 (e.g. `"US"`) — not alpha-3 |
| `.stateOrProvince(String)` | `card.state_or_province` | ISO 3166-2 format |
| `.city(String)` | `card.city` | Billing address city |
| `.address(String)` | `card.address` | Complete billing address as multi-line string |
| `.token(String)` | `card.token` | Token from an external payment system |

---

## Field key constants

The SDK also exposes static key constant enums that map case names to the string values sent over the wire. These are used internally and are available if you need the raw string key (e.g. for `extraFields`).

| Swift enum | Key prefix | Example |
|------------|------------|---------|
| `KYCNaturalPersonFieldKey` | none | `KYCNaturalPersonFieldKey.firstName == "first_name"` |
| `KYCOrganizationFieldKey` | `organization.` | `KYCOrganizationFieldKey.VATNumber == "organization.VAT_number"` |
| `KYCFinancialAccountFieldKey` | none | `KYCFinancialAccountFieldKey.bankName == "bank_name"` |
| `KYCCardFieldKey` | `card.` | `KYCCardFieldKey.number == "card.number"` |

These are `static let` string constants, not enum cases, so they cannot be iterated. Use the `FieldsEnum` types when building requests; use the `FieldKey` enums only when you need a literal key string.

---

## Common pitfalls

**WRONG: `birthDate` takes `Date`, but `idIssueDate` and `idExpirationDate` take `String`**

```swift
// WRONG: passing Date to idIssueDate — compile error, expects String
request.fields = [.idIssueDate(Date())]

// CORRECT: idIssueDate and idExpirationDate accept String; birthDate accepts Date
request.fields = [
    .birthDate(Date()),              // Date — SDK calls DateFormatter.iso8601.string(from:)
    .idIssueDate("2020-01-15"),      // String — provide the formatted date string directly
    .idExpirationDate("2030-01-15"),
]
```

**WRONG: using `.vatNumber` — the case is `.VATNumber` (all-caps)**

```swift
// WRONG: vatNumber does not exist
request.organizationFields = [.vatNumber("DE123456789")]

// CORRECT: VAT is all-caps
request.organizationFields = [.VATNumber("DE123456789")]
```

**WRONG: `card.countryCode` is ISO 3166-1 alpha-2, not alpha-3**

```swift
// WRONG: alpha-3 for card country code
request.cardFields = [.countryCode("USA")]

// CORRECT: alpha-2 for card fields; alpha-3 for person/org addressCountryCode
request.cardFields = [.countryCode("US")]
request.fields = [.addressCountryCode("USA")]  // alpha-3 for natural person
```

**WRONG: `card.expirationDate` is YY-MM, not MM/YY or YYYY-MM**

```swift
// WRONG: common credit-card display format
request.cardFields = [.expirationDate("11/29")]

// CORRECT: YY-MM order
request.cardFields = [.expirationDate("29-11")]   // November 2029
```

**WRONG: directly accessing `.parameter` on field cases**

```swift
// WRONG: you do not call .parameter yourself — it is used internally by the SDK
let (key, data) = KYCNaturalPersonFieldsEnum.firstName("Jane").parameter  // unnecessary

// CORRECT: assign to the request field arrays and let putCustomerInfo handle encoding
request.fields = [.firstName("Jane"), .lastName("Doe")]
let result = await kycService.putCustomerInfo(request: request)
```

**WRONG: `occupation` and `numberOfShareholders` take `Int`, not `String`**

```swift
// WRONG: String literal where Int is expected
request.fields = [.occupation("2512")]              // compile error
request.organizationFields = [.numberOfShareholders("3")]  // compile error

// CORRECT: pass Int directly
request.fields = [.occupation(2512)]                // ISCO-08 code
request.organizationFields = [.numberOfShareholders(3)]
```
