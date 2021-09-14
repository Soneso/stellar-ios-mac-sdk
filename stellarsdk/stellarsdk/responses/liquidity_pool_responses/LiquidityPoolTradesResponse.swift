//
//  LiquidityPoolTradesResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolTradesResponse: NSObject, Decodable {
    
    public var links:LiquidityPoolTradesLinksResponse
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
