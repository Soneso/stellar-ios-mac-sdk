# SEP-0009 (Standard KYC Fields) Compatibility Matrix

**Generated:** 2025-12-08

**SEP Version:** 1.17.0
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md

## SEP Summary

This SEP defines a list of standard KYC, AML, and financial account-related fields for use in Stellar ecosystem protocols.

Applications on Stellar should use these fields when sending or requesting KYC, AML, or financial account-related information with other parties on Stellar.

This is an evolving list, so please suggest any missing fields that you use.

This is a list of possible fields that may be necessary to handle many different use cases, there is no expectation that any particular fields be used for a particular application.

The best fields to use in a particular case is determined by the needs of the application.

## Overall Coverage

**Total Coverage:** 100.0% (76/76 fields)

- ✅ **Implemented:** 76/76
- ❌ **Not Implemented:** 0/76

**Required Fields:** 100.0% (0/0)

**Optional Fields:** 100.0% (76/76)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/kyc/KycAmlFields.swift`

### Key Classes

- **`KYCNaturalPersonFieldsEnum`**: Enum for all natural person KYC fields (34 fields)
- **`KYCNaturalPersonFieldKey`**: Static constants for natural person field keys
- **`KYCOrganizationFieldsEnum`**: Enum for all organization KYC fields (17 fields)
- **`KYCOrganizationFieldKey`**: Static constants for organization field keys
- **`KYCFinancialAccountFieldsEnum`**: Enum for all financial account fields (14 fields)
- **`KYCFinancialAccountFieldKey`**: Static constants for financial account field keys
- **`KYCCardFieldsEnum`**: Enum for all card payment fields (11 fields)
- **`KYCCardFieldKey`**: Static constants for card field keys

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Natural Person Fields | 100.0% | 100.0% | 34 | 34 |
| Organization Fields | 100.0% | 100.0% | 17 | 17 |
| Financial Account Fields | 100.0% | 100.0% | 14 | 14 |
| Card Fields | 100.0% | 100.0% | 11 | 11 |

## Detailed Field Comparison

### Natural Person Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `last_name` |  | ✅ | `lastName` | Family or last name |
| `first_name` |  | ✅ | `firstName` | Given or first name |
| `additional_name` |  | ✅ | `additionalName` | Middle name or other additional name |
| `address_country_code` |  | ✅ | `addressCountryCode` | Country code for current address |
| `state_or_province` |  | ✅ | `stateOrProvince` | Name of state/province/region/prefecture |
| `city` |  | ✅ | `city` | Name of city/town |
| `postal_code` |  | ✅ | `postalCode` | Postal or other code identifying user's locale |
| `address` |  | ✅ | `address` | Entire address (country, state, postal code, street address, etc.) as a multi-line string |
| `mobile_number` |  | ✅ | `mobileNumber` | Mobile phone number with country code, in E.164 format |
| `mobile_number_format` |  | ✅ | `mobileNumberFormat` | Expected format of the mobile_number field (E.164, hash, etc.) |
| `email_address` |  | ✅ | `emailAddress` | Email address |
| `birth_date` |  | ✅ | `birthDate` | Date of birth (e.g., 1976-07-04) |
| `birth_place` |  | ✅ | `birthPlace` | Place of birth (city, state, country; as on passport) |
| `birth_country_code` |  | ✅ | `birthCountryCode` | ISO Code of country of birth (ISO 3166-1 alpha-3) |
| `tax_id` |  | ✅ | `taxId` | Tax identifier of user in their country (social security number in US) |
| `tax_id_name` |  | ✅ | `taxIdName` | Name of the tax ID (SSN or ITIN in the US) |
| `occupation` |  | ✅ | `occupation` | Occupation ISCO code |
| `employer_name` |  | ✅ | `employerName` | Name of employer |
| `employer_address` |  | ✅ | `employerAddress` | Address of employer |
| `language_code` |  | ✅ | `languageCode` | Primary language (ISO 639-1) |
| `id_type` |  | ✅ | `idType` | Type of ID (passport, drivers_license, id_card, etc.) |
| `id_country_code` |  | ✅ | `idCountryCode` | Country issuing passport or photo ID (ISO 3166-1 alpha-3) |
| `id_issue_date` |  | ✅ | `idIssueDate` | ID issue date |
| `id_expiration_date` |  | ✅ | `idExpirationDate` | ID expiration date |
| `id_number` |  | ✅ | `idNumber` | Passport or ID number |
| `photo_id_front` |  | ✅ | `photoIdFront` | Image of front of user's photo ID or passport |
| `photo_id_back` |  | ✅ | `photoIdBack` | Image of back of user's photo ID or passport |
| `notary_approval_of_photo_id` |  | ✅ | `notaryApprovalOfPhotoId` | Image of notary's approval of photo ID or passport |
| `ip_address` |  | ✅ | `ipAddress` | IP address of customer's computer |
| `photo_proof_residence` |  | ✅ | `photoProofResidence` | Image of a utility bill, bank statement or similar with the user's name and address |
| `sex` |  | ✅ | `sex` | Gender (male, female, or other) |
| `proof_of_income` |  | ✅ | `proofOfIncome` | Image of user's proof of income document |
| `proof_of_liveness` |  | ✅ | `proofOfLiveness` | Video or image file of user as a liveness proof |
| `referral_id` |  | ✅ | `referralId` | User's origin (such as an id in another application) or a referral code |

### Organization Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `organization.name` |  | ✅ | `name` | Full organization name as on the incorporation papers |
| `organization.VAT_number` |  | ✅ | `VATNumber` | Organization VAT number |
| `organization.registration_number` |  | ✅ | `registrationNumber` | Organization registration number |
| `organization.registration_date` |  | ✅ | `registrationDate` | Date the organization was registered |
| `organization.registered_address` |  | ✅ | `registeredAddress` | Organization registered address |
| `organization.number_of_shareholders` |  | ✅ | `numberOfShareholders` | Organization shareholder number |
| `organization.shareholder_name` |  | ✅ | `shareholderName` | Name of shareholder (can be organization or person) |
| `organization.photo_incorporation_doc` |  | ✅ | `photoIncorporationDoc` | Image of incorporation documents |
| `organization.photo_proof_address` |  | ✅ | `photoProofAddress` | Image of a utility bill, bank statement with the organization's name and address |
| `organization.address_country_code` |  | ✅ | `addressCountryCode` | Country code for current address |
| `organization.state_or_province` |  | ✅ | `stateOrProvince` | Name of state/province/region/prefecture |
| `organization.city` |  | ✅ | `city` | Name of city/town |
| `organization.postal_code` |  | ✅ | `postalCode` | Postal or other code identifying organization's locale |
| `organization.director_name` |  | ✅ | `directorName` | Organization registered managing director |
| `organization.website` |  | ✅ | `website` | Organization website |
| `organization.email` |  | ✅ | `email` | Organization contact email |
| `organization.phone` |  | ✅ | `phone` | Organization contact phone |

### Financial Account Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `bank_account_number` |  | ✅ | `bankAccountNumber` | Number identifying bank account |
| `bank_account_type` |  | ✅ | `bankAccountType` | Type of bank account |
| `bank_number` |  | ✅ | `bankNumber` | Number identifying bank in national banking system (routing number in US) |
| `bank_phone_number` |  | ✅ | `bankPhoneNumber` | Phone number with country code for bank |
| `bank_branch_number` |  | ✅ | `bankBranchNumber` | Number identifying bank branch |
| `bank_name` |  | ✅ | `bankName` | Name of the bank |
| `clabe_number` |  | ✅ | `clabeNumber` | Bank account number for Mexico |
| `cbu_number` |  | ✅ | `cbuNumber` | Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU) |
| `cbu_alias` |  | ✅ | `cbuAlias` | The alias for a CBU or CVU |
| `crypto_address` |  | ✅ | `cryptoAddress` | Address for a cryptocurrency account |
| `crypto_memo` |  | ✅ | `cryptoMemo` | A destination tag/memo used to identify a transaction |
| `mobile_money_number` |  | ✅ | `mobileMoneyNumber` | Mobile phone number in E.164 format with which a mobile money account is associated |
| `mobile_money_provider` |  | ✅ | `mobileMoneyProvider` | Name of the mobile money service provider |
| `external_transfer_memo` |  | ✅ | `externalTransferMemo` | A destination tag/memo used to identify a transaction |

### Card Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `card.number` |  | ✅ | `number` | Card number |
| `card.expiration_date` |  | ✅ | `expirationDate` | Expiration month and year in YY-MM format (e.g., 29-11, November 2029) |
| `card.cvc` |  | ✅ | `cvc` | CVC number (Digits on the back of the card) |
| `card.holder_name` |  | ✅ | `holderName` | Name of the card holder |
| `card.network` |  | ✅ | `network` | Brand of the card/network it operates within (e.g., Visa, Mastercard, AmEx, etc.) |
| `card.postal_code` |  | ✅ | `postalCode` | Billing address postal code |
| `card.country_code` |  | ✅ | `countryCode` | Billing address country code in ISO 3166-1 alpha-2 code (e.g., US) |
| `card.state_or_province` |  | ✅ | `stateOrProvince` | Name of state/province/region/prefecture in ISO 3166-2 format |
| `card.city` |  | ✅ | `city` | Name of city/town |
| `card.address` |  | ✅ | `address` | Entire address (country, state, postal code, street address, etc.) as a multi-line string |
| `card.token` |  | ✅ | `token` | Token representation of the card in some external payment system (e.g., Stripe) |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-09!
- Use the strongly-typed enums (KYCNaturalPersonFieldsEnum, etc.) for type safety
- Field keys are available as static constants for direct access
- Binary files (photo_id, proof_of_income) use Data type for automatic encoding
- Date fields are automatically formatted to ISO 8601 strings
- Combine field enums with SEP-12 KycService for complete KYC workflows
- Organization fields use 'organization.' prefix per SEP-09 spec
- Card fields use 'card.' prefix per SEP-09 spec

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

---

**Report Generated:** 2025-12-08
**SDK Version:** 3.4.0
**Analysis Tool:** SEP Compatibility Matrix Generator v2.0