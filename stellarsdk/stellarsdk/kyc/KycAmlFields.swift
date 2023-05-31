//
//  KycAmlFields.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum KYCAMLFieldKey {
    static let lastName = "last_name"
    static let firstName = "first_name"
    static let additionalName = "additional_name"
    static let addressCountryCode = "address_country_code"
    static let stateOrProvince = "state_or_province"
    static let city = "city"
    static let postalCode = "postal_code"
    static let address = "address"
    static let mobileNumber = "mobile_number"
    static let emailAddress = "email_address"
    static let birthDate = "birth_date"
    static let birthPlace = "birth_place"
    static let birthCountryCode = "birth_country_code"
    static let bankAccountNumber = "bank_account_number"
    static let bankAccountType = "bank_account_type"
    static let bankNumber = "bank_number"
    static let bankPhoneNumber = "bank_phone_number"
    static let bankBranchNumber = "bank_branch_number"
    static let clabeNumber = "clabe_number"
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
    static let cbuNumber = "cbu_number"
    static let cbuAlias = "cbu_alias"
}

public enum KYCAMLFieldsEnum {
    /// Family or last name
    case lastName(String)
    /// Given or first name
    case firstName(String)
    /// Middle name or other additional name
    case additionalName(String)
    /// country code for current address
    case addressCountryCode(String)
    /// name of state/province/region/prefecture
    case stateOrProvince(String)
    /// name of city/town
    case city(String)
    /// Postal or other code identifying user's locale
    case postalCode(String)
    /// Entire address (country, state, postal code, street address, etc...) as a multi-line string
    case address(String)
    /// Mobile phone number with country code, in E.164 format
    case mobileNumber(String)
    /// Email address
    case emailAddress(String)
    /// Date of birth, e.g. 1976-07-04
    case birthDate(Date)
    /// Place of birth (city, state, country; as on passport)
    case birthPlace(Date)
    /// ISO Code of country of birth
    case birthCountryCode(String)
    /// Number identifying bank account
    case bankAccountNumber(String)
    /// "checking" or "savings"
    case bankAccountType(String)
    /// Number identifying bank (routing number in US)
    case bankNumber(String)
    /// Phone number with country code for bank
    case bankPhoneNumber(String)
    /// Number identifying bank branch
    case bankBranchNumber(String)
    /// Bank account number for Mexico
    case clabeNumber(String)
    /// Tax identifier of user in their country (social security number in US)
    case taxId(String)
    /// Name of the tax ID (SSN or ITIN in the US)
    case taxIdName(String)
    /// Occupation ISCO code
    case occupation(Int)
    /// Name of employer
    case employerName(String)
    /// Address of employer
    case employerAddress(String)
    /// primary language
    case languageCode(String)
    /// passport, drivers_license, id_card, etc...
    case idType(String)
    /// country issuing passport or photo ID as ISO 3166-1 alpha-3 code
    case idCountryCode(String)
    /// ID issue date
    case idIssueDate(String)
    /// ID expiration date
    case idExpirationDate(Data)
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
    /// Image of a utility bill, bank statement or similar with the user's name and address
    case photoProofResidence(Data)
    /// "male", "female", or "other"
    case sex(String)
    /// Image of user's proof of income document
    case proofOfIncome(Data)
    /// video or image file of user as a liveness proof
    case proofOfLiveness(Data)
    /// Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU). The unique key for every bank account in Argentina used for receiving deposits.
    case cbuNumber(String)
    /// The alias for a Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU).
    case cbuAlias(String)
    
    var parameter:(String, Data) {
        get {
            switch self {
            case .lastName(let value):
                return (KYCAMLFieldKey.lastName, value.data(using: .utf8)!)
            case .firstName(let value):
                return (KYCAMLFieldKey.firstName, value.data(using: .utf8)!)
            case .additionalName(let value):
                return (KYCAMLFieldKey.additionalName, value.data(using: .utf8)!)
            case .addressCountryCode(let value):
                return (KYCAMLFieldKey.addressCountryCode, value.data(using: .utf8)!)
            case .stateOrProvince(let value):
                return (KYCAMLFieldKey.stateOrProvince, value.data(using: .utf8)!)
            case .city(let value):
                return (KYCAMLFieldKey.city, value.data(using: .utf8)!)
            case .postalCode(let value):
                return (KYCAMLFieldKey.postalCode, value.data(using: .utf8)!)
            case .address(let value):
                return (KYCAMLFieldKey.address, value.data(using: .utf8)!)
            case .mobileNumber(let value):
                return (KYCAMLFieldKey.mobileNumber, value.data(using: .utf8)!)
            case .emailAddress(let value):
                return (KYCAMLFieldKey.emailAddress, value.data(using: .utf8)!)
            case .birthDate(let value):
                return (KYCAMLFieldKey.birthDate, DateFormatter.iso8601.string(from: value).data(using: .utf8)!)
            case .birthPlace(let value):
                return (KYCAMLFieldKey.birthPlace, DateFormatter.iso8601.string(from: value).data(using: .utf8)!)
            case .birthCountryCode(let value):
                return (KYCAMLFieldKey.birthCountryCode, value.data(using: .utf8)!)
            case .bankAccountNumber(let value):
                return (KYCAMLFieldKey.bankAccountNumber, value.data(using: .utf8)!)
            case .bankAccountType(let value):
                return (KYCAMLFieldKey.bankAccountType, value.data(using: .utf8)!)
            case .bankNumber(let value):
                return (KYCAMLFieldKey.bankNumber, value.data(using: .utf8)!)
            case .bankPhoneNumber(let value):
                return (KYCAMLFieldKey.bankPhoneNumber, value.data(using: .utf8)!)
            case .bankBranchNumber(let value):
                return (KYCAMLFieldKey.bankBranchNumber, value.data(using: .utf8)!)
            case .clabeNumber(let value):
                return (KYCAMLFieldKey.clabeNumber, value.data(using: .utf8)!)
            case .taxId(let value):
                return (KYCAMLFieldKey.taxId, value.data(using: .utf8)!)
            case .taxIdName(let value):
                return (KYCAMLFieldKey.taxIdName, value.data(using: .utf8)!)
            case .occupation(var value):
                return (KYCAMLFieldKey.occupation, Data(bytes: &value, count: MemoryLayout.size(ofValue: value)))
            case .employerName(let value):
                return (KYCAMLFieldKey.employerName, value.data(using: .utf8)!)
            case .employerAddress(let value):
                return (KYCAMLFieldKey.employerAddress, value.data(using: .utf8)!)
            case .languageCode(let value):
                return (KYCAMLFieldKey.languageCode, value.data(using: .utf8)!)
            case .idType(let value):
                return (KYCAMLFieldKey.idType, value.data(using: .utf8)!)
            case .idCountryCode(let value):
                return (KYCAMLFieldKey.idCountryCode, value.data(using: .utf8)!)
            case .idIssueDate(let value):
                return (KYCAMLFieldKey.idIssueDate, value.data(using: .utf8)!)
            case .idExpirationDate(let value):
                return (KYCAMLFieldKey.idExpirationDate, value)
            case .idNumber(let value):
                return (KYCAMLFieldKey.idNumber, value.data(using: .utf8)!)
            case .photoIdFront(let value):
                return (KYCAMLFieldKey.photoIdFront, value)
            case .photoIdBack(let value):
                return (KYCAMLFieldKey.photoIdBack, value)
            case .notaryApprovalOfPhotoId(let value):
                return (KYCAMLFieldKey.notaryApprovalOfPhotoId, value)
            case .ipAddress(let value):
                return (KYCAMLFieldKey.ipAddress, value.data(using: .utf8)!)
            case .photoProofResidence(let value):
                return (KYCAMLFieldKey.photoProofResidence, value)
            case .sex(let value):
                return (KYCAMLFieldKey.sex, value.data(using: .utf8)!)
            case .proofOfIncome(let value):
                return (KYCAMLFieldKey.proofOfIncome, value)
            case .proofOfLiveness(let value):
                return (KYCAMLFieldKey.proofOfLiveness, value)
            case .cbuNumber(let value):
                return (KYCAMLFieldKey.cbuNumber, value.data(using: .utf8)!)
            case .cbuAlias(let value):
                return (KYCAMLFieldKey.cbuAlias, value.data(using: .utf8)!)
            }
        }
    }
}

public enum KYCAMLOrganizationFieldKey {
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
    static let stateOrProvice = "organization.state_or_province"
    static let city = "organization.city"
    static let postalCode = "organization.postal_code"
    static let directorName = "organization.director_name"
    static let website = "organization.website"
    static let email = "organization.email"
    static let phone = "organization.phone"
}

public enum KYCAMLOrganizationFieldsEnum {
    /// Full organiation name as on the incorporation papers
    case name(String)
    /// Organization VAT number
    case VATNumber(String)
    /// Organization registration number
    case registrationNumber(String)
    /// Date the organization was registered
    case registrationDate(String)
    /// Organization registered address
    case registeredAddress(String)
    /// Organization shareholder number
    case numberOfShareholders(Int)
    /// Can be an organization or a person and should be queried recursively up to the ultimate beneficial owners (with KYC information for natural persons such as above)
    case shareholderName(String)
    /// Image of incorporation documents
    case photoIncorporationDoc(Data)
    /// Image of a utility bill, bank statement with the organization's name and address
    case photoProofAddress(Data)
    /// country code for current address
    case addressCountryCode(String)
    /// name of state/province/region/prefecture
    case stateOrProvice(String)
    /// name of city/town
    case city(String)
    /// Postal or other code identifying organization's locale
    case postalCode(String)
    /// Organization registered managing director (the rest of the information should be queried as an individual using the fields above)
    case directorName(String)
    /// Organization website
    case website(String)
    /// Organization contact email
    case email(String)
    /// Organization contact phone
    case phone(String)
    
    var parameter:(String, Data) {
        get {
            switch self {
            case .name(let value):
                return (KYCAMLOrganizationFieldKey.name, value.data(using: .utf8)!)
            case .VATNumber(let value):
                return (KYCAMLOrganizationFieldKey.VATNumber, value.data(using: .utf8)!)
            case .registrationNumber(let value):
                return (KYCAMLOrganizationFieldKey.registrationNumber, value.data(using: .utf8)!)
            case .registrationDate(let value):
                return (KYCAMLOrganizationFieldKey.registrationDate, value.data(using: .utf8)!)
            case .registeredAddress(let value):
                return (KYCAMLOrganizationFieldKey.registeredAddress, value.data(using: .utf8)!)
            case .numberOfShareholders(var value):
                return (KYCAMLOrganizationFieldKey.numberOfShareholders, Data(bytes: &value, count: MemoryLayout.size(ofValue: value)))
            case .shareholderName(let value):
                return (KYCAMLOrganizationFieldKey.shareholderName, value.data(using: .utf8)!)
            case .photoIncorporationDoc(let value):
                return (KYCAMLOrganizationFieldKey.photoIncorporationDoc, value)
            case .photoProofAddress(let value):
                return (KYCAMLOrganizationFieldKey.photoProofAddress, value)
            case .addressCountryCode(let value):
                return (KYCAMLOrganizationFieldKey.addressCountryCode, value.data(using: .utf8)!)
            case .stateOrProvice(let value):
                return (KYCAMLOrganizationFieldKey.stateOrProvice, value.data(using: .utf8)!)
            case .city(let value):
                return (KYCAMLOrganizationFieldKey.city, value.data(using: .utf8)!)
            case .postalCode(let value):
                return (KYCAMLOrganizationFieldKey.postalCode, value.data(using: .utf8)!)
            case .directorName(let value):
                return (KYCAMLOrganizationFieldKey.directorName, value.data(using: .utf8)!)
            case .website(let value):
                return (KYCAMLOrganizationFieldKey.website, value.data(using: .utf8)!)
            case .email(let value):
                return (KYCAMLOrganizationFieldKey.email, value.data(using: .utf8)!)
            case .phone(let value):
                return (KYCAMLOrganizationFieldKey.phone, value.data(using: .utf8)!)
            }
        }
    }
}
