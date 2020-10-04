//
//  DataSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class DataSponsorshipRemovedEffectResponse: EffectResponse {
    
    // name of the data removed
    public var dataName:String
    
    //  former sponsor of the account data
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
