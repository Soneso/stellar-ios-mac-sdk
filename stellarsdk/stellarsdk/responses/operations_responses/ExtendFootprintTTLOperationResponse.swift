//
//  ExtendFootprintTTLOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class ExtendFootprintTTLOperationResponse: OperationResponse {
    
    public var extendTo:Int
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case extendTo = "extend_to"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        extendTo = try values.decode(Int.self, forKey: .extendTo)
        try super.init(from: decoder)
    }
}
