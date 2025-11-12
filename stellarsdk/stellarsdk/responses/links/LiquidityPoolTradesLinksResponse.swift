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
/// - [Liquidity Pool Trades](https://developers.stellar.org/api/horizon/reference/resources/liquidity-pool)
/// - [Automated Market Makers](https://developers.stellar.org/docs/learn/encyclopedia/sdex/liquidity-on-stellar-sdex-liquidity-pools)
/// - LiquidityPoolResponse for complete details
public class LiquidityPoolTradesLinksResponse: NSObject, Decodable {

    /// Link to this liquidity pool trades resource (self reference).
    public var selflink:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
    }
}
