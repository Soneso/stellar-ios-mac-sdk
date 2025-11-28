//
//  ClaimableBalanceSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance sponsorship creation effect.
/// This effect occurs when a claimable balance's reserve requirement begins being sponsored by another account.
/// Sponsorship allows one account to pay the base reserve for a claimable balance.
/// Triggered by the Begin Sponsoring Future Reserves and End Sponsoring Future Reserves operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimableBalanceSponsorshipCreatedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The account ID of the sponsor paying the claimable balance's base reserve.
    public let sponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sponsor
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sponsor = try values.decode(String.self, forKey: .sponsor)
        try super.init(from: decoder)
    }
}
