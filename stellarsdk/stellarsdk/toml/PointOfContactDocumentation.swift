//
//  PointOfContactDocumentation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class PointOfContactDocumentation {

    private enum Keys: String {
        case name = "name"
        case email = "email"
        case keybase = "keybase"
        case telegram = "telegram"
        case twitter = "twitter"
        case github = "github"
        case idPhotoHash = "id_photo_hash"
        case verificationPhotoHash = "verification_photo_hash"
    }
    
    /// Full legal name
    public var name: String?
    
    /// Business email address for the principal
    public var email: String?
    
    /// Personal Keybase account. Should include proof of ownership for other online accounts, as well as the organization's domain.
    public var keybase: String?
    
    /// Personal Telegram account
    public var telegram: String?
    
    /// Personal Twitter account
    public var twitter: String?
    
    /// Personal Github account
    public var github: String?
    
    /// SHA-256 hash of a photo of the principal's government-issued photo ID
    public var idPhotoHash: String?
    
    /// SHA-256 hash of a verification photo of principal. Should be well-lit and contain: principal holding ID card and signed, dated, hand-written message stating I, $NAME, am a principal of $ORG_NAME, a Stellar token issuer with address $ISSUER_ADDRESS.
    public var verificationPhotoHash: String?
    
    public init(fromToml toml:Toml) {
        name = toml.string(Keys.name.rawValue)
        email = toml.string(Keys.email.rawValue)
        keybase = toml.string(Keys.keybase.rawValue)
        telegram = toml.string(Keys.telegram.rawValue)
        twitter = toml.string(Keys.twitter.rawValue)
        github = toml.string(Keys.github.rawValue)
        idPhotoHash = toml.string(Keys.idPhotoHash.rawValue)
        verificationPhotoHash = toml.string(Keys.verificationPhotoHash.rawValue)
    }
    
}
