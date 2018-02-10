//
//  PageOfLedgersResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a page of ledgers response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/ledgers-all.html "All Ledgers Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/ledger.html "Ledger")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public class PageOfLedgersResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:PagingLinksResponse
    
    ///Ledgers found in the response.
    public var ledgers:[LedgerResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The ledgers are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedLedgersResponseService
    struct EmbeddedLedgersResponseService: Decodable {
        let records: [LedgerResponse]
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
    */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(PagingLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedLedgersResponseService.self, forKey: .embeddedRecords)
        self.ledgers = self.embeddedRecords.records
    }
}
