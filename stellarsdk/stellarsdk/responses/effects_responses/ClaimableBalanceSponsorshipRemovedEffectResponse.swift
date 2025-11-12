//
//  ClaimableBalanceSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance sponsorship removal effect.
/// This effect occurs when sponsorship for a claimable balance's base reserve is revoked.
/// The claimable balance creator becomes responsible for paying the base reserve.
/// Triggered by the Revoke Sponsorship operation.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/sponsored-reserves "Sponsored Reserves")
public class ClaimableBalanceSponsorshipRemovedEffectResponse: EffectResponse {

    /// The account ID of the former sponsor.
    public var formerSponsor:String
    
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
