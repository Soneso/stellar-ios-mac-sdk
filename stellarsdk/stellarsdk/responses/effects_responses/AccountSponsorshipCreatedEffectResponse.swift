//
//  AccountSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents an account sponsorship creation effect.
/// This effect occurs when an account's reserves begin being sponsored by another account.
/// Sponsorship allows one account to pay the base reserve for another account's existence.
/// Triggered by the Begin Sponsoring Future Reserves and End Sponsoring Future Reserves operations.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/sponsored-reserves "Sponsored Reserves")
public class AccountSponsorshipCreatedEffectResponse: EffectResponse {

    /// The account ID of the sponsor paying the account's base reserve.
    public var sponsor:String
    
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
