//
//  Sep08PostTestRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

public struct Sep08PostTestRequest: Decodable {

    public var tx: String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case tx
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tx = try values.decode(String.self, forKey: .tx)
    }
}
