//
//  LedgersResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class LedgersResponse: NSObject, Codable {
    
    public var ledgers:[Ledger]
    
    private var embeddedRecords:EmbeddedLedgersService
    
    enum CodingKeys: String, CodingKey {
        case embeddedRecords = "_embedded"
    }
    
    struct EmbeddedLedgersService: Codable {
        let records: [Ledger]
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.embeddedRecords = try values.decode(EmbeddedLedgersService.self, forKey: .embeddedRecords)
        self.ledgers = self.embeddedRecords.records
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(embeddedRecords, forKey: .embeddedRecords)
    }
}
