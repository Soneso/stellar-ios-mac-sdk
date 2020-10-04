//
//  TrustlineSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class TrustlineSponsorshipCreatedEffectResponse: EffectResponse {
    
    // sponsor of a trustline
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
