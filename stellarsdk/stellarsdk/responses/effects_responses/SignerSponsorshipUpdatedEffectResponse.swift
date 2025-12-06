//
//  SignerSponsorshipUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a signer sponsorship update effect.
/// This effect occurs when the sponsoring account for a signer's base reserve changes.
/// The sponsorship is transferred from one sponsor to another.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerSponsorshipUpdatedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The public key of the signer whose sponsorship is being updated.
    public let signer:String

    /// The account ID of the new sponsor.
    public let newSponsor:String

    /// The account ID of the former sponsor.
    public let formerSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case signer
        case newSponsor = "new_sponsor"
        case formerSponsor = "former_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signer = try values.decode(String.self, forKey: .signer)
        newSponsor = try values.decode(String.self, forKey: .newSponsor)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        try super.init(from: decoder)
    }
}
