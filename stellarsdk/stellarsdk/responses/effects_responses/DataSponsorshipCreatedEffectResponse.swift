//
//  DataSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a data entry sponsorship creation effect.
/// This effect occurs when a data entry's reserve requirement begins being sponsored by another account.
/// Sponsorship allows one account to pay the base reserve for another account's data entry.
/// Triggered by the Begin Sponsoring Future Reserves and End Sponsoring Future Reserves operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class DataSponsorshipCreatedEffectResponse: EffectResponse {

    /// The name (key) of the data entry being sponsored.
    public var dataName:String

    /// The account ID of the sponsor paying the data entry's base reserve.
    public var sponsor:String
    
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case dataName = "data_name"
        case sponsor
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dataName = try values.decode(String.self, forKey: .dataName)
        sponsor = try values.decode(String.self, forKey: .sponsor)
        try super.init(from: decoder)
    }
}
