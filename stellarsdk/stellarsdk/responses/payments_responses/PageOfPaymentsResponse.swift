//
//  AllPaymentsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 10.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a page of payments response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/payments-all.html "All Payments Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#payment "Payment Operation")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public class PageOfPaymentsResponse: NSObject {
    
    /// A list of links related to this response.
    public var links:PagingLinksResponse
    
    /// Assets found in the response.
    public var payments:[OperationResponse]
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case embeddedRecords = "_embedded"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter operations: The payment operations received from the Horizon API
     - Parameter links: The links received from the Horizon API
     */
    public init(payments: [OperationResponse], links:PagingLinksResponse) {
        self.payments = payments
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
    open func getNextPage(response:@escaping PageOfPaymentsResponseClosure) {
        let paymentsService = PaymentsService(baseURL:"")
        if let url = links.next?.href {
            paymentsService.getPaymentsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "next page not found", horizonErrorResponse: nil)))
        }
    }
    
    /**
     Provides the previous page if available. Before calling this, make sure there is a prevoius page available by calling 'hasPreviousPage'. If there is no prevoius page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
     - Parameter response:   The closure to be called upon response.
     */
    open func getPreviousPage(response:@escaping PageOfPaymentsResponseClosure) {
        let paymentsService = PaymentsService(baseURL:"")
        if let url = links.prev?.href {
            paymentsService.getPaymentsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "previous page not found", horizonErrorResponse: nil)))
        }
    }
}
