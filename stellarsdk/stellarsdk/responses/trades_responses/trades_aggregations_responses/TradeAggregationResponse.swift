//
//  TradeAggregationResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/8/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a trade aggregation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public struct TradeAggregationResponse: Decodable, Sendable {

    /// start time for this trade_aggregation. Represented as milliseconds since epoch.
    public let timestamp:String

    /// total number of trades aggregated.
    public let tradeCount:String

    /// total volume of base asset.
    public let baseVolume:String

    /// total volume of counter asset.
    public let counterVolume:String

    /// weighted average price of counter asset in terms of base asset.
    public let averagePrice:String

    /// highest price for this time period.
    public let highPrice:String

    /// lowest price for this time period.
    public let lowPrice:String

    /// price as seen on first trade aggregated.
    public let openPrice:String

    /// price as seen on last trade aggregated.
    public let closePrice:String

    private enum CodingKeys: String, CodingKey {

        case timestamp
        case tradeCount = "trade_count"
        case baseVolume = "base_volume"
        case counterVolume = "counter_volume"
        case averagePrice = "avg"
        case highPrice = "high"
        case lowPrice = "low"
        case openPrice = "open"
        case closePrice = "close"
    }

    /**
     Initializer - creates a new instance by decoding from the given decoder.

     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try values.decode(String.self, forKey: .timestamp)
        tradeCount = try values.decode(String.self, forKey: .tradeCount)
        baseVolume = try values.decode(String.self, forKey: .baseVolume)
        counterVolume = try values.decode(String.self, forKey: .counterVolume)
        averagePrice = try values.decode(String.self, forKey: .averagePrice)
        highPrice = try values.decode(String.self, forKey: .highPrice)
        lowPrice = try values.decode(String.self, forKey: .lowPrice)
        openPrice = try values.decode(String.self, forKey: .openPrice)
        closePrice = try values.decode(String.self, forKey: .closePrice)
    }
}
