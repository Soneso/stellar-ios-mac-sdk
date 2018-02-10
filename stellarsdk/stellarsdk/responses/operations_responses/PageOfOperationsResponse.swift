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
}
