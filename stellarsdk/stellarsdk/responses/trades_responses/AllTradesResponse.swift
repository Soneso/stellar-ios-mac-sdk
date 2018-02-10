//
//  AllTradesResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/8/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all trades response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/trades.html "All Trades Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/trade.html "Trade")
public class AllTradesResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:LinksResponse
    
    /// Trades found in the response.
    public var trades:[TradeResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The trades are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedTradesResponseService
    struct EmbeddedTradesResponseService: Decodable {
        let records: [TradeResponse]
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(LinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedTradesResponseService.self, forKey: .embeddedRecords)
        self.trades = self.embeddedRecords.records
    }
}
