//
//  OperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an all operations response, containing operation response objects and links from the all operations request
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/operations-all.html "All Operations")
///  Horizon API Request GET /operations{?cursor,limit,order}
public class AllOperationsResponse: NSObject {
    
    /// An array of operation response objects received from the API
    public var operations:[OperationResponse]
    
    /// A list of links related to this all operations response
    public var links: AllOperationsLinksResponse
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter operations: The operations received from the Horizon API
        - Parameter links: The links received from the Horizon API
     */
    public init(operations: [OperationResponse], links:AllOperationsLinksResponse) {
        self.operations = operations
        self.links = links
    }
}
