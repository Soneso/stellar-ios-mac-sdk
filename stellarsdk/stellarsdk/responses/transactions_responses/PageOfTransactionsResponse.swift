//
//  AllTransactionsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all transactions response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/transactions-all.html "All Transactions")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/transaction.html "Transaction")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public class PageOfTransactionsResponse: NSObject, Decodable {
    
    /// A list of links related to this response.
    public var links:PagingLinksResponse
    
    /// Transactions found in the response.
    public var transactions:[TransactionResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    // The assets are represented by "records" within the _embedded json tag.
    private var embeddedRecords:EmbeddedTransactionsResponseService
    struct EmbeddedTransactionsResponseService: Decodable {
        let records: [TransactionResponse]
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try values.decode(PagingLinksResponse.self, forKey: .links)
        self.embeddedRecords = try values.decode(EmbeddedTransactionsResponseService.self, forKey: .embeddedRecords)
        self.transactions = self.embeddedRecords.records
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
    open func getNextPage(response:@escaping PageOfTransactionsResponseClosure) {
        let transactionsService = TransactionsService(baseURL:"")
        if let url = links.next?.href {
            transactionsService.getTransactionsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "next page not found", horizonErrorResponse: nil)))
        }
    }
    
    /**
        Provides the previous page if available. Before calling this, make sure there is a prevoius page available by calling 'hasPreviousPage'. If there is no prevoius page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
        - Parameter response:   The closure to be called upon response.
     */
    open func getPreviousPage(response:@escaping PageOfTransactionsResponseClosure) {
        let transactionsService = TransactionsService(baseURL:"")
        if let url = links.prev?.href {
            transactionsService.getTransactionsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "previous page not found", horizonErrorResponse: nil)))
        }
    }
}
