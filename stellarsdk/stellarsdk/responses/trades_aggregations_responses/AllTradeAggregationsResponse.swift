//
//  AllTradeAggregationsResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/9/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all trade aggregations response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/trade_aggregations.html "All Trades Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/trade_aggregation.html "Trade Aggregation")
public class AllTradeAggregationsResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:LinksResponse
    
    /// Trade Aggregations found in the response.
    public var tradeAggregations:[TradeAggregationResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The trades are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedTradeAggregationsResponseService
    struct EmbeddedTradeAggregationsResponseService: Decodable {
        let records: [TradeAggregationResponse]
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(LinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedTradeAggregationsResponseService.self, forKey: .embeddedRecords)
        self.tradeAggregations = self.embeddedRecords.records
    }
}
