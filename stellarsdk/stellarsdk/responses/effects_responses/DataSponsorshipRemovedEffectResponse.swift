//
//  DataSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a data entry sponsorship removal effect.
/// This effect occurs when sponsorship for a data entry's base reserve is revoked.
/// The account becomes responsible for paying the data entry's base reserve.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class DataSponsorshipRemovedEffectResponse: EffectResponse {

    /// The name (key) of the data entry whose sponsorship is being removed.
    public var dataName:String

    /// The account ID of the former sponsor.
    public var formerSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case dataName = "data_name"
        case formerSponsor = "former_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dataName = try values.decode(String.self, forKey: .dataName)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        try super.init(from: decoder)
    }
}
