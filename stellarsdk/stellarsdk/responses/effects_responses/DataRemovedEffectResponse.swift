//
//  DataRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a data created effect response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
public class DataRemovedEffectResponse: EffectResponse {
    
    // name of the account data removed
    public var name:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        try super.init(from: decoder)
    }
}
