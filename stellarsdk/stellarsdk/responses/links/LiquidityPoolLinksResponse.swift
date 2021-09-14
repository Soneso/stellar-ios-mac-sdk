//
//  LiquidityPoolLinksResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolLinksResponse: NSObject, Decodable {
    
    public var selflink:LinkResponse
    public var transactions:LinkResponse
    public var operations:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case transactions
        case operations
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        transactions = try values.decode(LinkResponse.self, forKey: .transactions)
        operations = try values.decode(LinkResponse.self, forKey: .operations)
    }
}
