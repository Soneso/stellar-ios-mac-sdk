//
//  IssuerDocumentation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class IssuerDocumentation {

    private enum Keys: String {
        case orgName = "ORG_NAME"
        case orgDBA = "ORG_DBA"
        case orgURL = "ORG_URL"
        case orgLogo = "ORG_LOGO"
        case orgDescription = "ORG_DESCRIPTION"
        case orgPhysicalAddress = "ORG_PHYSICAL_ADDRESS"
        case orgPhysicalAddressAttestation = "ORG_PHYSICAL_ADDRESS_ATTESTATION"
        case orgPhoneNumber = "ORG_PHONE_NUMBER"
        case orgPhoneNumberAttestation = "ORG_PHONE_NUMBER_ATTESTATION"
        case orgKeybase = "ORG_KEYBASE"
        case orgTwitter = "ORG_TWITTER"
        case orgGithub = "ORG_GITHUB"
        case orgOfficialEmail = "ORG_OFFICIAL_EMAIL"
        case orgSupportEmail = "ORG_SUPPORT_EMAIL"
        case orgLicensingAuthority = "ORG_LICENSING_AUTHORITY"
        case orgLicenseType = "ORG_LICENSE_TYPE"
        case orgLicenseNumber = "ORG_LICENSE_NUMBER"
    }

    /// Legal name of the organization
    public var orgName: String?
    
    /// (may not apply) DBA of the organization
    public var orgDBA: String?
    
    /// uses https:
    /// The organization's official URL. Your stellar.toml must be hosted on the same domain.
    public var orgURL: String?
    
    /// The organization's logo
    public var orgLogo: String?
    
    /// Short description of the organization
    public var orgDescription: String?
    
    /// Physical address of the organization
    public var orgPhysicalAddress: String?
    
    /// https:// url
    /// URL on the same domain as your ORG_URL that contains an image or pdf official document attesting to your physical address. It must list your ORG_NAME or ORG_DBA as the party at the address. Only documents from an official third party are acceptable. E.g. a utility bill, mail from a financial institution, or business license.
    public var orgPhysicalAddressAttestation: String?
    
    /// The organization's phone number
    public var orgPhoneNumber: String?
    
    /// https:// url
    /// URL on the same domain as your ORG_URL that contains an image or pdf of a phone bill showing both the phone number and your organization's name.
    public var orgPhoneNumberAttestation: String?
    
    /// A Keybase account name of the organization. Should contain proof of ownership of any public online accounts you list here, including your organization's domain.
    public var orgKeybase: String?
    
    /// The organization's Twitter account
    public var orgTwitter: String?
    
    /// The organization's Github account
    public var orgGithub: String?
    
    /// An email where clients can contact the organization. Must be hosted at your ORG_URL domain.
    public var orgOfficialEmail: String?
    
    /// An email that users can use to request support regarding the organizations Stellar assets or applications.
    public var orgSupportEmail: String?
    
    /// Name of the authority or agency that licensed the organization, if applicable
    public var orgLicensingAuthority: String?
    
    /// Type of financial or other license the organization holds, if applicable
    public var orgLicenseType: String?
    
    /// Official license number of the organization, if applicable
    public var orgLicenseNumber: String?
    
    public init(fromToml toml:Toml) {
        orgName = toml.string(Keys.orgName.rawValue)
        orgDBA = toml.string(Keys.orgDBA.rawValue)
        orgURL = toml.string(Keys.orgURL.rawValue)
        orgLogo = toml.string(Keys.orgLogo.rawValue)
        orgDescription = toml.string(Keys.orgDescription.rawValue)
        orgPhysicalAddress = toml.string(Keys.orgPhysicalAddress.rawValue)
        orgPhysicalAddressAttestation = toml.string(Keys.orgPhysicalAddressAttestation.rawValue)
        orgPhoneNumber = toml.string(Keys.orgPhoneNumber.rawValue)
        orgPhoneNumberAttestation = toml.string(Keys.orgPhoneNumberAttestation.rawValue)
        orgKeybase = toml.string(Keys.orgKeybase.rawValue)
        orgTwitter = toml.string(Keys.orgTwitter.rawValue)
        orgGithub = toml.string(Keys.orgGithub.rawValue)
        orgOfficialEmail = toml.string(Keys.orgOfficialEmail.rawValue)
        orgSupportEmail = toml.string(Keys.orgSupportEmail.rawValue)
        orgLicensingAuthority = toml.string(Keys.orgLicensingAuthority.rawValue)
        orgLicenseType = toml.string(Keys.orgLicenseType.rawValue)
        orgLicenseNumber = toml.string(Keys.orgLicenseNumber.rawValue)
    }
    
}
