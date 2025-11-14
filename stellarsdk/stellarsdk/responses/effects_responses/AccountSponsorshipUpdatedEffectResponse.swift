//
//  AccountSponsorshipUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents an account sponsorship update effect.
/// This effect occurs when the sponsoring account for an account's base reserve changes.
/// The sponsorship is transferred from one sponsor to another.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AccountSponsorshipUpdatedEffectResponse: EffectResponse {

    /// The account ID of the new sponsor.
    public var newSponsor:String

    /// The account ID of the former sponsor.
    public var formerSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case newSponsor = "new_sponsor"
        case formerSponsor = "former_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        newSponsor = try values.decode(String.self, forKey: .newSponsor)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        try super.init(from: decoder)
    }
}
