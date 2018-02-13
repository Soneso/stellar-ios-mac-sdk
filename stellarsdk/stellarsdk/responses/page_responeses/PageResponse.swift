//
//  PageResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public struct PageResponse<Element:Decodable>: Decodable {
    
    public enum PageResponseEnum {
        case success(details: PageResponse)
        case failure(error: HorizonRequestError)
    }
    
    public typealias PageResponseClosure = (_ response:PageResponseEnum) -> (Void)
    
    /// A list of links related to this response.
    public var links:PagingLinksResponse
    
    /// records found in the response.
    public var records:[Element]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The offers are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedResponseService
    struct EmbeddedResponseService: Decodable {
        let records: [Element]
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(PagingLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedResponseService.self, forKey: .embeddedRecords)
        self.records = self.embeddedRecords.records
    }
    
    /**
     Checks if there is a previous page available.
     
     - Returns: true if a previous page is avialable
     */
    public func hasPreviousPage() -> Bool {
        return links.prev != nil
    }
    
    /**
     Checks if there is a next page available.
     
     - Returns: true if a next page is avialable
     */
    public func hasNextPage() -> Bool {
        return links.next != nil
    }
    
    /**
     Provides the next page if available. Before calling this, make sure there is a next page available by calling 'hasNextPage'.  If there is no next page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
     - Parameter response:   The closure to be called upon response.
     */
    public func getNextPage(response:@escaping PageResponseClosure) {
        if let url = links.next?.href {
            getRecordsFrom(url: url, response: response)
        } else {
            response(.failure(error: .notFound(message: "next page not found", horizonErrorResponse: nil)))
        }
    }
    
    /**
     Provides the previous page if available. Before calling this, make sure there is a prevoius page available by calling 'hasPreviousPage'. If there is no prevoius page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
     - Parameter response:   The closure to be called upon response.
     */
    public func getPreviousPage(response:@escaping PageResponseClosure) {
        if let url = links.prev?.href {
            getRecordsFrom(url: url, response: response)
        } else {
            response(.failure(error: .notFound(message: "previous page not found", horizonErrorResponse: nil)))
        }
    }
    
    private func getRecordsFrom(url:String, response:@escaping PageResponseClosure) {
        switch Element.self {
        case is AssetResponse.Type:
            let service = AssetsService(baseURL:"")
            service.getAssetsFromUrl(url:url, response:response as! (PageResponse<AssetResponse>.PageResponseEnum) -> (Void))
        case is TradeResponse.Type:
            let service = TradesService(baseURL:"")
            service.getTradesFromUrl(url:url, response:response as! (PageResponse<TradeResponse>.PageResponseEnum) -> (Void))
        case is OfferResponse.Type:
            let service = OffersService(baseURL:"")
            service.getOffersFromUrl(url: url, response:response as! (PageResponse<OfferResponse>.PageResponseEnum) -> (Void))
        case is LedgerResponse.Type:
            let service = LedgersService(baseURL:"")
            service.getLedgersFromUrl(url: url, response:response as! (PageResponse<LedgerResponse>.PageResponseEnum) -> (Void))
        default:
            assertionFailure("You should implement this case:\(Element.self)")
        }
    }
}
