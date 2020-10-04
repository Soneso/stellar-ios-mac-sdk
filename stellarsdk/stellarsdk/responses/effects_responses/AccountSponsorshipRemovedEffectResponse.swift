//
//  AccountSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class AccountSponsorshipRemovedEffectResponse: EffectResponse {
    
    //  former sponsor of an account
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
