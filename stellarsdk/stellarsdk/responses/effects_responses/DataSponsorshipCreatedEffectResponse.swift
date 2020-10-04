//
//  DataSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class DataSponsorshipCreatedEffectResponse: EffectResponse {
    
    // name of the data created
    public var dataName:String

    // account data sponsor
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
