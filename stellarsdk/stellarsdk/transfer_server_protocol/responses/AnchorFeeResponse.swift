//
//  AnchorFeeResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.06.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public struct AnchorFeeResponse: Decodable {

    /// The total fee (in units of the asset involved) that would be charged to deposit/withdraw the specified amount of asset_code.
    public var fee:Double
    
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case fee
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fee = try values.decode(Double.self, forKey: .fee)
    }
    
}
