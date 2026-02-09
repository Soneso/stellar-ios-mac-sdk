//
//  KycAmlFields.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Field keys for natural person KYC information as defined in SEP-0009.
/// These keys are used to identify customer data fields in SEP-0012 KYC requests.
public enum KYCNaturalPersonFieldKey {
    static let lastName = "last_name"
    static let firstName = "first_name"
    static let additionalName = "additional_name"
    static let addressCountryCode = "address_country_code"
    static let stateOrProvince = "state_or_province"
    static let city = "city"
    static let postalCode = "postal_code"
    static let address = "address"
    static let mobileNumber = "mobile_number"
    static let mobileNumberFormat = "mobile_number_format"
    static let emailAddress = "email_address"
    static let birthDate = "birth_date"
    static let birthPlace = "birth_place"
    static let birthCountryCode = "birth_country_code"
    static let taxId = "tax_id"
    static let taxIdName = "tax_id_name"
    static let occupation = "occupation"
    static let employerName = "employer_name"
    static let employerAddress = "employer_address"
    static let languageCode = "language_code"
    static let idType = "id_type"
    static let idCountryCode = "id_country_code"
    static let idIssueDate = "id_issue_date"
    static let idExpirationDate = "id_expiration_date"
    static let idNumber = "id_number"
    static let photoIdFront = "photo_id_front"
    static let photoIdBack = "photo_id_back"
    static let notaryApprovalOfPhotoId = "notary_approval_of_photo_id"
    static let ipAddress = "ip_address"
    static let photoProofResidence = "photo_proof_residence"
    static let sex = "sex"
    static let proofOfIncome = "proof_of_income"
    static let proofOfLiveness = "proof_of_liveness"
    static let referralId = "referral_id"
}

/// KYC field values for natural person customer information as defined in SEP-0009.
/// This enum represents all standard fields that can be submitted in PUT /customer requests for individual customers.
/// Each case contains the field value and converts it to the appropriate multipart/form-data format.
public enum KYCNaturalPersonFieldsEnum: Sendable {
    /// Family or last name
    case lastName(String)
    /// Given or first name
    case firstName(String)
    /// Middle name or other additional name
    case additionalName(String)
    /// Country code for current address in ISO 3166-1 alpha-3 format
    case addressCountryCode(String)
    /// Name of state/province/region/prefecture
    case stateOrProvince(String)
    /// Name of city/town
    case city(String)
    /// Postal or other code identifying user's locale
    case postalCode(String)
    /// Entire address (country, state, postal code, street address, etc.) as a multi-line string
    case address(String)
    /// Mobile phone number with country code, in E.164 format
    case mobileNumber(String)
    /// Expected format of the mobile_number field (E.164, hash, etc.). Defaults to E.164 if not specified
    case mobileNumberFormat(String)
    /// Email address
    case emailAddress(String)
    /// Date of birth, e.g. 1976-07-04
    case birthDate(Date)
    /// Place of birth (city, state, country; as shown on passport)
    case birthPlace(String)
    /// Country of birth in ISO 3166-1 alpha-3 format
    case birthCountryCode(String)
    /// Tax identifier in customer's country (social security number in US)
    case taxId(String)
    /// Name of the tax ID type (SSN or ITIN in the US)
    case taxIdName(String)
    /// Occupation ISCO code
    case occupation(Int)
    /// Name of employer
    case employerName(String)
    /// Address of employer
    case employerAddress(String)
    /// Primary language in ISO 639-1 format
    case languageCode(String)
    /// Type of ID document (passport, drivers_license, id_card, etc.)
    case idType(String)
    /// Country issuing passport or photo ID in ISO 3166-1 alpha-3 format
    case idCountryCode(String)
    /// ID issue date
    case idIssueDate(String)
    /// ID expiration date
    case idExpirationDate(String)
    /// Passport or ID number
    case idNumber(String)
    /// Image of front of user's photo ID or passport
    case photoIdFront(Data)
    /// Image of back of user's photo ID or passport
    case photoIdBack(Data)
    /// Image of notary's approval of photo ID or passport
    case notaryApprovalOfPhotoId(Data)
    /// IP address of customer's computer
    case ipAddress(String)
    /// Image of a utility bill, bank statement or similar document with the user's name and address
    case photoProofResidence(Data)
    /// Customer's gender (male, female, or other)
    case sex(String)
    /// Image of user's proof of income document
    case proofOfIncome(Data)
    /// Video or image file of user as a liveness proof
    case proofOfLiveness(Data)
    /// Referral ID used to identify the source of the customer
    case referralId(String)
    
    public var parameter:(String, Data) {
        get {
            switch self {
            case .lastName(let value):
                return (KYCNaturalPersonFieldKey.lastName, value.data(using: .utf8)!)
            case .firstName(let value):
                return (KYCNaturalPersonFieldKey.firstName, value.data(using: .utf8)!)
            case .additionalName(let value):
                return (KYCNaturalPersonFieldKey.additionalName, value.data(using: .utf8)!)
            case .addressCountryCode(let value):
                return (KYCNaturalPersonFieldKey.addressCountryCode, value.data(using: .utf8)!)
            case .stateOrProvince(let value):
                return (KYCNaturalPersonFieldKey.stateOrProvince, value.data(using: .utf8)!)
            case .city(let value):
                return (KYCNaturalPersonFieldKey.city, value.data(using: .utf8)!)
            case .postalCode(let value):
                return (KYCNaturalPersonFieldKey.postalCode, value.data(using: .utf8)!)
            case .address(let value):
                return (KYCNaturalPersonFieldKey.address, value.data(using: .utf8)!)
            case .mobileNumber(let value):
                return (KYCNaturalPersonFieldKey.mobileNumber, value.data(using: .utf8)!)
            case .mobileNumberFormat(let value):
                return (KYCNaturalPersonFieldKey.mobileNumberFormat, value.data(using: .utf8)!)
            case .emailAddress(let value):
                return (KYCNaturalPersonFieldKey.emailAddress, value.data(using: .utf8)!)
            case .birthDate(let value):
                return (KYCNaturalPersonFieldKey.birthDate, DateFormatter.iso8601.string(from: value).data(using: .utf8)!)
            case .birthPlace(let value):
                return (KYCNaturalPersonFieldKey.birthPlace, value.data(using: .utf8)!)
            case .birthCountryCode(let value):
                return (KYCNaturalPersonFieldKey.birthCountryCode, value.data(using: .utf8)!)
            case .taxId(let value):
                return (KYCNaturalPersonFieldKey.taxId, value.data(using: .utf8)!)
            case .taxIdName(let value):
                return (KYCNaturalPersonFieldKey.taxIdName, value.data(using: .utf8)!)
            case .occupation(var value):
                return (KYCNaturalPersonFieldKey.occupation, Data(bytes: &value, count: MemoryLayout.size(ofValue: value)))
            case .employerName(let value):
                return (KYCNaturalPersonFieldKey.employerName, value.data(using: .utf8)!)
            case .employerAddress(let value):
                return (KYCNaturalPersonFieldKey.employerAddress, value.data(using: .utf8)!)
            case .languageCode(let value):
                return (KYCNaturalPersonFieldKey.languageCode, value.data(using: .utf8)!)
            case .idType(let value):
                return (KYCNaturalPersonFieldKey.idType, value.data(using: .utf8)!)
            case .idCountryCode(let value):
                return (KYCNaturalPersonFieldKey.idCountryCode, value.data(using: .utf8)!)
            case .idIssueDate(let value):
                return (KYCNaturalPersonFieldKey.idIssueDate, value.data(using: .utf8)!)
            case .idExpirationDate(let value):
                return (KYCNaturalPersonFieldKey.idExpirationDate, value.data(using: .utf8)!)
            case .idNumber(let value):
                return (KYCNaturalPersonFieldKey.idNumber, value.data(using: .utf8)!)
            case .photoIdFront(let value):
                return (KYCNaturalPersonFieldKey.photoIdFront, value)
            case .photoIdBack(let value):
                return (KYCNaturalPersonFieldKey.photoIdBack, value)
            case .notaryApprovalOfPhotoId(let value):
                return (KYCNaturalPersonFieldKey.notaryApprovalOfPhotoId, value)
            case .ipAddress(let value):
                return (KYCNaturalPersonFieldKey.ipAddress, value.data(using: .utf8)!)
            case .photoProofResidence(let value):
                return (KYCNaturalPersonFieldKey.photoProofResidence, value)
            case .sex(let value):
                return (KYCNaturalPersonFieldKey.sex, value.data(using: .utf8)!)
            case .proofOfIncome(let value):
                return (KYCNaturalPersonFieldKey.proofOfIncome, value)
            case .proofOfLiveness(let value):
                return (KYCNaturalPersonFieldKey.proofOfLiveness, value)
            case .referralId(let value):
                return (KYCNaturalPersonFieldKey.referralId, value.data(using: .utf8)!)
            }
        }
    }
}

/// Field keys for financial account information as defined in SEP-0009.
/// These keys are used to identify banking and financial account data fields in SEP-0012 KYC requests.
public enum KYCFinancialAccountFieldKey {
    static let bankName = "bank_name"
    static let bankAccountType = "bank_account_type"
    static let bankAccountNumber = "bank_account_number"
    static let bankNumber = "bank_number"
    static let bankPhoneNumber = "bank_phone_number"
    static let bankBranchNumber = "bank_branch_number"
    static let externalTransferMemo = "external_transfer_memo"
    static let clabeNumber = "clabe_number"
    static let cbuNumber = "cbu_number"
    static let cbuAlias = "cbu_alias"
    static let mobileMoneyNumber = "mobile_money_number"
    static let mobileMoneyProvider = "mobile_money_provider"
    static let cryptoAddress = "crypto_address"
    static let cryptoMemo = "crypto_memo"

}

/// KYC field values for financial account information as defined in SEP-0009.
/// This enum represents banking and financial account fields that can be submitted in PUT /customer requests
/// for receiving deposits or payments. Each case contains the field value and converts it to the appropriate format.
public enum KYCFinancialAccountFieldsEnum: Sendable {
    /// Name of the bank. May be necessary in regions that don't have a unified routing system
    case bankName(String)
    /// Type of bank account (checking or savings)
    case bankAccountType(String)
    /// Number identifying bank account
    case bankAccountNumber(String)
    /// Number identifying bank (routing number in US)
    case bankNumber(String)
    /// Phone number with country code for bank
    case bankPhoneNumber(String)
    /// Number identifying bank branch
    case bankBranchNumber(String)
    /// Destination tag/memo used to identify a transaction
    case externalTransferMemo(String)
    /// Bank account number for Mexico (CLABE format)
    case clabeNumber(String)
    /// Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU). Unique key for bank accounts in Argentina used for receiving deposits
    case cbuNumber(String)
    /// Alias for a Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU)
    case cbuAlias(String)
    /// Mobile phone number in E.164 format associated with a mobile money account. May be distinct from the customer's mobile_number
    case mobileMoneyNumber(String)
    /// Name of the mobile money service provider
    case mobileMoneyProvider(String)
    /// Address for a cryptocurrency account
    case cryptoAddress(String)
    /// Destination tag/memo used to identify a cryptocurrency transaction
    case cryptoMemo(String)
    
    public var parameter:(String, Data) {
        get {
            switch self {
            case .bankName(let value):
                return (KYCFinancialAccountFieldKey.bankName, value.data(using: .utf8)!)
            case .bankAccountType(let value):
                return (KYCFinancialAccountFieldKey.bankAccountType, value.data(using: .utf8)!)
            case .bankAccountNumber(let value):
                return (KYCFinancialAccountFieldKey.bankAccountNumber, value.data(using: .utf8)!)
            case .bankNumber(let value):
                return (KYCFinancialAccountFieldKey.bankNumber, value.data(using: .utf8)!)
            case .bankPhoneNumber(let value):
                return (KYCFinancialAccountFieldKey.bankPhoneNumber, value.data(using: .utf8)!)
            case .bankBranchNumber(let value):
                return (KYCFinancialAccountFieldKey.bankBranchNumber, value.data(using: .utf8)!)
            case .externalTransferMemo(let value):
                return (KYCFinancialAccountFieldKey.externalTransferMemo, value.data(using: .utf8)!)
            case .clabeNumber(let value):
                return (KYCFinancialAccountFieldKey.clabeNumber, value.data(using: .utf8)!)
            case .cbuNumber(let value):
                return (KYCFinancialAccountFieldKey.cbuNumber, value.data(using: .utf8)!)
            case .cbuAlias(let value):
                return (KYCFinancialAccountFieldKey.cbuAlias, value.data(using: .utf8)!)
            case .mobileMoneyNumber(let value):
                return (KYCFinancialAccountFieldKey.mobileMoneyNumber, value.data(using: .utf8)!)
            case .mobileMoneyProvider(let value):
                return (KYCFinancialAccountFieldKey.mobileMoneyProvider, value.data(using: .utf8)!)
            case .cryptoAddress(let value):
                return (KYCFinancialAccountFieldKey.cryptoAddress, value.data(using: .utf8)!)
            case .cryptoMemo(let value):
                return (KYCFinancialAccountFieldKey.cryptoMemo, value.data(using: .utf8)!)
            }
        }
    }
}

/// Field keys for organization KYC information as defined in SEP-0009.
/// These keys are used to identify corporate/business customer data fields in SEP-0012 KYC requests.
/// All keys use the "organization." prefix to distinguish them from natural person fields.
public enum KYCOrganizationFieldKey {
    static let name = "organization.name"
    static let VATNumber = "organization.VAT_number"
    static let registrationNumber = "organization.registration_number"
    static let registrationDate = "organization.registration_date"
    static let registeredAddress = "organization.registered_address"
    static let numberOfShareholders = "organization.number_of_shareholders"
    static let shareholderName = "organization.shareholder_name"
    static let photoIncorporationDoc = "organization.photo_incorporation_doc"
    static let photoProofAddress = "organization.photo_proof_address"
    static let addressCountryCode = "organization.address_country_code"
    static let stateOrProvince = "organization.state_or_province"
    static let city = "organization.city"
    static let postalCode = "organization.postal_code"
    static let directorName = "organization.director_name"
    static let website = "organization.website"
    static let email = "organization.email"
    static let phone = "organization.phone"
}

/// KYC field values for organization customer information as defined in SEP-0009.
/// This enum represents corporate/business entity fields that can be submitted in PUT /customer requests
/// for organizational customers. Each case contains the field value and converts it to the appropriate format.
public enum KYCOrganizationFieldsEnum: Sendable {
    /// Full organization name as shown on incorporation papers
    case name(String)
    /// Organization VAT number
    case VATNumber(String)
    /// Organization registration number
    case registrationNumber(String)
    /// Date the organization was registered
    case registrationDate(String)
    /// Organization's registered address
    case registeredAddress(String)
    /// Number of shareholders in the organization
    case numberOfShareholders(Int)
    /// Name of shareholder. Can be an organization or person and should be queried recursively up to ultimate beneficial owners
    case shareholderName(String)
    /// Image of incorporation documents
    case photoIncorporationDoc(Data)
    /// Image of a utility bill or bank statement with the organization's name and address
    case photoProofAddress(Data)
    /// Country code for organization's address in ISO 3166-1 alpha-3 format
    case addressCountryCode(String)
    /// Name of state/province/region/prefecture
    case stateOrProvince(String)
    /// Name of city/town
    case city(String)
    /// Postal or other code identifying organization's locale
    case postalCode(String)
    /// Organization's registered managing director. Additional information should be queried as an individual using natural person fields
    case directorName(String)
    /// Organization website
    case website(String)
    /// Organization contact email
    case email(String)
    /// Organization contact phone
    case phone(String)
    
    public var parameter:(String, Data) {
        get {
            switch self {
            case .name(let value):
                return (KYCOrganizationFieldKey.name, value.data(using: .utf8)!)
            case .VATNumber(let value):
                return (KYCOrganizationFieldKey.VATNumber, value.data(using: .utf8)!)
            case .registrationNumber(let value):
                return (KYCOrganizationFieldKey.registrationNumber, value.data(using: .utf8)!)
            case .registrationDate(let value):
                return (KYCOrganizationFieldKey.registrationDate, value.data(using: .utf8)!)
            case .registeredAddress(let value):
                return (KYCOrganizationFieldKey.registeredAddress, value.data(using: .utf8)!)
            case .numberOfShareholders(var value):
                return (KYCOrganizationFieldKey.numberOfShareholders, Data(bytes: &value, count: MemoryLayout.size(ofValue: value)))
            case .shareholderName(let value):
                return (KYCOrganizationFieldKey.shareholderName, value.data(using: .utf8)!)
            case .photoIncorporationDoc(let value):
                return (KYCOrganizationFieldKey.photoIncorporationDoc, value)
            case .photoProofAddress(let value):
                return (KYCOrganizationFieldKey.photoProofAddress, value)
            case .addressCountryCode(let value):
                return (KYCOrganizationFieldKey.addressCountryCode, value.data(using: .utf8)!)
            case .stateOrProvince(let value):
                return (KYCOrganizationFieldKey.stateOrProvince, value.data(using: .utf8)!)
            case .city(let value):
                return (KYCOrganizationFieldKey.city, value.data(using: .utf8)!)
            case .postalCode(let value):
                return (KYCOrganizationFieldKey.postalCode, value.data(using: .utf8)!)
            case .directorName(let value):
                return (KYCOrganizationFieldKey.directorName, value.data(using: .utf8)!)
            case .website(let value):
                return (KYCOrganizationFieldKey.website, value.data(using: .utf8)!)
            case .email(let value):
                return (KYCOrganizationFieldKey.email, value.data(using: .utf8)!)
            case .phone(let value):
                return (KYCOrganizationFieldKey.phone, value.data(using: .utf8)!)
            }
        }
    }
}

/// Field keys for payment card information as defined in SEP-0009.
/// These keys are used to identify credit/debit card data fields in SEP-0012 KYC requests.
/// All keys use the "card." prefix to distinguish them from other field types.
public enum KYCCardFieldKey {
    static let number = "card.number"
    static let expirationDate = "card.expiration_date"
    static let cvc = "card.cvc"
    static let holderName = "card.holder_name"
    static let network = "card.network"
    static let postalCode = "card.postal_code"
    static let countryCode = "card.country_code"
    static let stateOrProvince = "card.state_or_province"
    static let city = "card.city"
    static let address = "card.address"
    static let token = "card.token"
}

/// KYC field values for payment card information as defined in SEP-0009.
/// This enum represents credit/debit card fields that can be submitted in PUT /customer requests
/// for card-based payment methods. Each case contains the field value and converts it to the appropriate format.
public enum KYCCardFieldsEnum: Sendable {
    /// Card number
    case number(String)
    /// Expiration month and year in YY-MM format (e.g. 29-11 for November 2029)
    case expirationDate(String)
    /// CVC security code (digits on the back of the card)
    case cvc(String)
    /// Name of the card holder
    case holderName(String)
    /// Brand of the card/network it operates within (Visa, Mastercard, AmEx, etc.)
    case network(String)
    /// Billing address postal code
    case postalCode(String)
    /// Billing address country code in ISO 3166-1 alpha-2 format (e.g. US)
    case countryCode(String)
    /// Billing address state/province/region/prefecture in ISO 3166-2 format
    case stateOrProvince(String)
    /// Billing address city/town
    case city(String)
    /// Complete billing address (country, state, postal code, street address, etc.) as a multi-line string
    case address(String)
    /// Token representation of the card in an external payment system (e.g. Stripe)
    case token(String)
    
    public var parameter:(String, Data) {
        get {
            switch self {
            case .number(let value):
                return (KYCCardFieldKey.number, value.data(using: .utf8)!)
            case .expirationDate(let value):
                return (KYCCardFieldKey.expirationDate, value.data(using: .utf8)!)
            case .cvc(let value):
                return (KYCCardFieldKey.cvc, value.data(using: .utf8)!)
            case .holderName(let value):
                return (KYCCardFieldKey.holderName, value.data(using: .utf8)!)
            case .network(let value):
                return (KYCCardFieldKey.network, value.data(using: .utf8)!)
            case .postalCode(let value):
                return (KYCCardFieldKey.postalCode, value.data(using: .utf8)!)
            case .countryCode(let value):
                return (KYCCardFieldKey.countryCode, value.data(using: .utf8)!)
            case .stateOrProvince(let value):
                return (KYCCardFieldKey.stateOrProvince, value.data(using: .utf8)!)
            case .city(let value):
                return (KYCCardFieldKey.city, value.data(using: .utf8)!)
            case .address(let value):
                return (KYCCardFieldKey.address, value.data(using: .utf8)!)
            case .token(let value):
                return (KYCCardFieldKey.token, value.data(using: .utf8)!)
            }
        }
    }
}
