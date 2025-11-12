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
/// - [Liquidity Pool](https://developers.stellar.org/api/horizon/reference/resources/liquidity-pool)
/// - [Automated Market Makers](https://developers.stellar.org/docs/learn/encyclopedia/sdex/liquidity-on-stellar-sdex-liquidity-pools)
/// - LiquidityPoolResponse for complete details
public class LiquidityPoolLinksResponse: NSObject, Decodable {

    /// Link to this liquidity pool resource (self reference).
    public var selflink:LinkResponse

    /// Templated link to transactions involving this liquidity pool. Supports cursor, order, and limit.
    public var transactions:LinkResponse

    /// Templated link to operations involving this liquidity pool. Supports cursor, order, and limit.
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
