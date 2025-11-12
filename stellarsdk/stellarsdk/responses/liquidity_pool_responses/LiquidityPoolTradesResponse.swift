//
//  LiquidityPoolTradesResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a paginated collection of trades for a liquidity pool.
/// This response contains trade records and navigation links for pagination.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/endpoints/liquiditypools-single-trades "Liquidity Pool Trades")
public class LiquidityPoolTradesResponse: NSObject, Decodable {

    /// Navigation links for this page of trades.
    public var links:LiquidityPoolTradesLinksResponse

    /// Array of trade records for this liquidity pool.
    public var records:[TradeResponse]
    
    private var embeddedRecords:EmbeddedResponseService
    struct EmbeddedResponseService: Decodable {
        let records: [TradeResponse]
        
        init(records:[TradeResponse]) {
            self.records = records
        }
    }
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(LiquidityPoolTradesLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedResponseService.self, forKey: .embeddedRecords)
        self.records = self.embeddedRecords.records
    }
}
