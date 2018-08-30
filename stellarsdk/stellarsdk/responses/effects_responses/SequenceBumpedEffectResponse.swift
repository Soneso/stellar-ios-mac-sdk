//
//  SequenceBumpedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class SequenceBumpedEffectResponse: EffectResponse {

    // The new sequence
    public var newSequence:Int64
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case newSequence = "new_seq"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        newSequence = try values.decode(Int64.self, forKey: .newSequence)
        
        try super.init(from: decoder)
    }
    
}
