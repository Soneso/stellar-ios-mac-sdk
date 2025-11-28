//
//  LiquidityPoolTradesLinksResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for liquidity pool trade-related resources.
///
/// Provides hypermedia links to resources associated with liquidity pool trades.
/// Currently only includes a self reference to the trades resource.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - LiquidityPoolResponse for complete details
public struct LiquidityPoolTradesLinksResponse: Decodable, Sendable {

    /// Link to this liquidity pool trades resource (self reference).
    public let selflink:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
    }
}
