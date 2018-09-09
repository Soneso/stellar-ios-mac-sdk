//
//  PutCustomerInfoRequest.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

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
    /// Number identifying bank (routing number in US)
    case bankNumber(String)
    /// Phone number with country code for bank
    case bankPhoneNumber(String)
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
    
    var parameter:(String, Data) {
        get {
            switch self {
            case .lastName(let value):
                return ("last_name", value.data(using: .utf8)!)
            case .firstName(let value):
                return ("first_name", value.data(using: .utf8)!)
            case .additionalName(let value):
                return ("additional_name", value.data(using: .utf8)!)
            case .addressCountryCode(let value):
                return ("address_country_code", value.data(using: .utf8)!)
            case .stateOrProvince(let value):
                return ("state_or_province", value.data(using: .utf8)!)
            case .city(let value):
                return ("city", value.data(using: .utf8)!)
            case .postalCode(let value):
                return ("postal_code", value.data(using: .utf8)!)
            case .address(let value):
                return ("address", value.data(using: .utf8)!)
            case .mobileNumber(let value):
                return ("mobile_number", value.data(using: .utf8)!)
            case .emailAddress(let value):
                return ("email_address", value.data(using: .utf8)!)
            case .birthDate(let value):
                return ("birth_date", DateFormatter.iso8601.string(from: value).data(using: .utf8)!)
            case .birthPlace(let value):
                return ("birth_place", DateFormatter.iso8601.string(from: value).data(using: .utf8)!)
            case .birthCountryCode(let value):
                return ("birth_country_code", value.data(using: .utf8)!)
            case .bankAccountNumber(let value):
                return ("bank_account_number", value.data(using: .utf8)!)
            case .bankNumber(let value):
                return ("bank_number", value.data(using: .utf8)!)
            case .bankPhoneNumber(let value):
                return ("bank_phone_number", value.data(using: .utf8)!)
            case .taxId(let value):
                return ("tax_id", value.data(using: .utf8)!)
            case .taxIdName(let value):
                return ("tax_id_name", value.data(using: .utf8)!)
            case .occupation(var value):
                return ("occupation", Data(bytes: &value, count: MemoryLayout.size(ofValue: value)))
            case .employerName(let value):
                return ("employer_name", value.data(using: .utf8)!)
            case .employerAddress(let value):
                return ("employer_address", value.data(using: .utf8)!)
            case .languageCode(let value):
                return ("language_code", value.data(using: .utf8)!)
            case .idType(let value):
                return ("id_type", value.data(using: .utf8)!)
            case .idCountryCode(let value):
                return ("id_country_code", value.data(using: .utf8)!)
            case .idIssueDate(let value):
                return ("id_issue_date", value.data(using: .utf8)!)
            case .idExpirationDate(let value):
                return ("id_expiration_date", value)
            case .idNumber(let value):
                return ("id_number", value.data(using: .utf8)!)
            case .photoIdFront(let value):
                return ("photo_id_front", value)
            case .photoIdBack(let value):
                return ("photo_id_back", value)
            case .notaryApprovalOfPhotoId(let value):
                return ("notary_approval_of_photo_id", value)
            }
        }
    }
    
}

public struct PutCustomerInfoRequest {

    /// The Stellar account ID to upload KYC data for
    public var account:String
    
    /// The JWT previously sent by the anchor via the /jwt endpoint via SEP-10 authentication
    public var jwt:String
    
    /// (optional) Uniquely identifies individual customer in schemes where multiple wallet users share one Stellar address. If included, the KYC data will only apply to deposit/withdraw requests that include this memo.
    public var memo:String?
    
    /// (optional) type of memo. One of text, id or hash
    public var memoType:String?
    
    /// one or more of the fields listed in SEP-9
    public var fields:[KYCAMLFieldsEnum]?
    
    public init(account:String, jwt:String) {
        self.account = account
        self.jwt = jwt
    }
    
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        parameters["account"] = account.data(using: .utf8)
        parameters["jwt"] = jwt.data(using: .utf8)
        if let memo = memo {
            parameters["memo"] = memo.data(using: .utf8)
        }
        if let memoType = memoType {
            parameters["memo_type"] = memoType.data(using: .utf8)
        }
        if let fields = fields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        return parameters
    }
    
}
