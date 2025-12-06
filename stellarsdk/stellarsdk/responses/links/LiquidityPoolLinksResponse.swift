//
//  LiquidityPoolLinksResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for liquidity pool-related resources.
///
/// Provides hypermedia links to resources associated with a liquidity pool, including
/// transactions and operations that interact with the pool.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - LiquidityPoolResponse for complete details
public struct LiquidityPoolLinksResponse: Decodable, Sendable {

    /// Link to this liquidity pool resource (self reference).
    public let selflink:LinkResponse

    /// Templated link to transactions involving this liquidity pool. Supports cursor, order, and limit.
    public let transactions:LinkResponse

    /// Templated link to operations involving this liquidity pool. Supports cursor, order, and limit.
    public let operations:LinkResponse
    
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
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        transactions = try values.decode(LinkResponse.self, forKey: .transactions)
        operations = try values.decode(LinkResponse.self, forKey: .operations)
    }
}
