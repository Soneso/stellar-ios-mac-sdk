//
//  BumpSequenceOperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class BumpSequenceOperationResponse: OperationResponse {

    /// Value to bump the sequence to.
    public var bumpTo:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case bumpTo = "bump_to"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bumpTo = try values.decode(String.self, forKey: .bumpTo)
        
        try super.init(from: decoder)
    }
    
}
