//
//  AccountSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents an account sponsorship removal effect.
/// This effect occurs when sponsorship for an account's base reserve is revoked.
/// The account becomes responsible for paying its own base reserve.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AccountSponsorshipRemovedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The account ID of the former sponsor.
    public let formerSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case formerSponsor = "former_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        try super.init(from: decoder)
    }
}
