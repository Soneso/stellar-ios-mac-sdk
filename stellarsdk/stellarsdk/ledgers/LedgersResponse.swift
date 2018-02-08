//
//  LedgersResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an all ledgers response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/ledgers-all.html "All Ledgers Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/ledger.html "Ledger")
public class LedgersResponse: NSObject, Codable {
    
    /// A list of links related to this response.
    public var links:AllLedgersLinks
    
    ///Ledgers found in the response.
    public var ledgers:[Ledger]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The ledgers are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedLedgersService
    struct EmbeddedLedgersService: Codable {
        let records: [Ledger]
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
    */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(AllLedgersLinks.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedLedgersService.self, forKey: .embeddedRecords)
        self.ledgers = self.embeddedRecords.records
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
    */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(embeddedRecords, forKey: .embeddedRecords)
    }
}
