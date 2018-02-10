//
//  AllPaymentsLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 10.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to the all payments response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/payments-all.html "All Payments Request")
public class AllPaymentsLinksResponse: NSObject {
    
    /// Link to the assets request URL.
    public var selflink:LinkResponse
    
    /// Link to the next "page" of the result.
    public var next:LinkResponse?
    
    /// Link to the previous "page" of the result.
    public var prev:LinkResponse?
    
    
    public required init(operationsLinks:AllOperationsLinksResponse) throws {
        self.selflink = operationsLinks.selflink
        self.next = operationsLinks.next
        self.prev = operationsLinks.prev
    }
}
