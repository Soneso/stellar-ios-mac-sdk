//
//  AllPaymentsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 10.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all payments response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/payments-all.html "All Payments Request")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#payment "Payment Operation")
public class AllPaymentsResponse: NSObject {
    
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
}
