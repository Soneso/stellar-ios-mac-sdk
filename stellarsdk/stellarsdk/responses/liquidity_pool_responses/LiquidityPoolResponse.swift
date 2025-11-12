//
//  LiquidityPoolResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool response from the Horizon API.
/// Liquidity pools are automated market makers that enable decentralized trading
/// by maintaining reserves of two assets and allowing users to swap between them.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/liquiditypool "Liquidity Pool")
public class LiquidityPoolResponse: NSObject, Decodable {

    /// A list of links related to this liquidity pool.
    public var links:LiquidityPoolLinksResponse

    /// Unique identifier for this liquidity pool.
    public var poolId:String

    /// The fee charged for swaps in this pool, in basis points.
    public var fee:Int64

    /// The type of liquidity pool. Currently only "constant_product" is supported.
    public var type:String

    /// The number of trustlines to this liquidity pool.
    public var totalTrustlines:String

    /// The total number of pool shares issued.
    public var totalShares:String

    /// The reserves of assets in this liquidity pool.
    public var reserves:[ReserveResponse]

    /// Paging token suitable for use as a cursor parameter.
    public var pagingToken:String

    /// The sequence number of the ledger in which this liquidity pool was last modified.
    public var lastModifiedLedger:Int

    /// An ISO 8601 formatted string of when this liquidity pool was last modified.
    public var lastModifiedTime:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case poolId = "id"
        case fee = "fee_bp"
        case type
        case totalTrustlines = "total_trustlines"
        case totalShares = "total_shares"
        case reserves
        case pagingToken = "paging_token"
        case lastModifiedLedger = "last_modified_ledger"
        case lastModifiedTime = "last_modified_time"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(LiquidityPoolLinksResponse.self, forKey: .links)
        poolId = try values.decode(String.self, forKey: .poolId)
        fee = try values.decode(Int64.self, forKey: .fee)
        type = try values.decode(String.self, forKey: .type)
        totalTrustlines = try values.decode(String.self, forKey: .totalTrustlines)
        totalShares = try values.decode(String.self, forKey: .totalShares)
        reserves = try values.decode([ReserveResponse].self, forKey: .reserves)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        lastModifiedLedger = try values.decode(Int.self, forKey: .lastModifiedLedger)
        lastModifiedTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedTime)
    }
}
