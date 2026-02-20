//
//  PointOfContactDocumentation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents point of contact information from a stellar.toml file.
///
/// This class parses and provides access to the PRINCIPALS section of a domain's
/// stellar.toml file. It contains information about key individuals associated with
/// the organization, such as executives, directors, or other responsible parties.
///
/// The PRINCIPALS section helps establish accountability and trust by identifying
/// real people behind an organization. This includes their contact information,
/// social media accounts for verification, and cryptographic hashes of identity
/// verification photos.
///
/// Developers use this class to display information about who is responsible for
/// an asset or service, enabling users to verify the legitimacy of an organization
/// through the identities of its key personnel.
///
/// See also:
/// - [StellarToml] for the main stellar.toml parser
/// - [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
public final class PointOfContactDocumentation: Sendable {

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
    public let name: String?
    
    /// Business email address for the principal
    public let email: String?
    
    /// Personal Keybase account. Should include proof of ownership for other online accounts, as well as the organization's domain.
    public let keybase: String?
    
    /// Personal Telegram account
    public let telegram: String?
    
    /// Personal Twitter account
    public let twitter: String?
    
    /// Personal Github account
    public let github: String?
    
    /// SHA-256 hash of a photo of the principal's government-issued photo ID
    public let idPhotoHash: String?
    
    /// SHA-256 hash of a verification photo of principal. Should be well-lit and contain: principal holding ID card and signed, dated, hand-written message stating I, $NAME, am a principal of $ORG_NAME, a Stellar token issuer with address $ISSUER_ADDRESS.
    public let verificationPhotoHash: String?

    /// Initializes point of contact documentation from a parsed TOML document.
    ///
    /// - Parameter toml: The parsed TOML document containing principal information
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
