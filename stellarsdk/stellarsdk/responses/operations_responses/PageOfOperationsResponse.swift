//
//  PageOfOperationsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a page of operations response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/operations-all.html "All Operations")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public class PageOfOperationsResponse: NSObject {
    
    /// An array of operation response objects received from the API
    public var operations:[OperationResponse]
    
    /// A list of links related to this all operations response
    public var links: PagingLinksResponse
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter operations: The operations received from the Horizon API
        - Parameter links: The links received from the Horizon API
     */
    public init(operations: [OperationResponse], links:PagingLinksResponse) {
        self.operations = operations
        self.links = links
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
    open func getNextPage(response:@escaping PageOfOperationsResponseClosure) {
        let operationsService = OperationsService(baseURL:"")
        if let url = links.next?.href {
            operationsService.getOperationsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "next page not found", horizonErrorResponse: nil)))
        }
    }
    
    /**
        Provides the previous page if available. Before calling this, make sure there is a prevoius page available by calling 'hasPreviousPage'. If there is no prevoius page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
        - Parameter response:   The closure to be called upon response.
     */
    open func getPreviousPage(response:@escaping PageOfOperationsResponseClosure) {
        let operationsService = OperationsService(baseURL:"")
        if let url = links.prev?.href {
            operationsService.getOperationsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "previous page not found", horizonErrorResponse: nil)))
        }
    }
}
