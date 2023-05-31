//
//  PutCustomerInfoResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct PutCustomerInfoResponse: Decodable {
    
    /// An identifier for the updated or created customer
    public var id:String
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case id
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
    }
}
