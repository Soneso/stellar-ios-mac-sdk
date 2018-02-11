//
//  PageOfTradesResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/8/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all trades response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/trades.html "All Trades Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/trade.html "Trade")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public class PageOfTradesResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:PagingLinksResponse
    
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
        self.links = try values.decode(PagingLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedTradesResponseService.self, forKey: .embeddedRecords)
        self.trades = self.embeddedRecords.records
    }
    
    /**
        Checks if there is a previous page available.
     
        - Returns: true if a previous page is avialable
     */
    open func hasPreviousPage()->Bool {
        return links.prev != nil
    }
    
    /**
        Checks if there is a next page available.
     
        - Returns: true if a next page is avialable
     */
    open func hasNextPage()->Bool {
        return links.next != nil
    }
    
    /**
        Provides the next page if available. Before calling this, make sure there is a next page available by calling 'hasNextPage'.  If there is no next page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
        - Parameter response:   The closure to be called upon response.
    */
    open func getNextPage(response:@escaping PageOfTradesResponseClosure) {
        let tradesService = TradesService(baseURL:"")
        if let url = links.next?.href {
            tradesService.getTradesFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "next page not found", horizonErrorResponse: nil)))
        }
    }
    
    /**
        Provides the previous page if available. Before calling this, make sure there is a prevoius page available by calling 'hasPreviousPage'. If there is no prevoius page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
        - Parameter response:   The closure to be called upon response.
     */
    open func getPreviousPage(response:@escaping PageOfTradesResponseClosure) {
        let tradesService = TradesService(baseURL:"")
        if let url = links.prev?.href {
            tradesService.getTradesFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "previous page not found", horizonErrorResponse: nil)))
        }
    }
}
