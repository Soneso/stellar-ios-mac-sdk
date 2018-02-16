//
//  ManageOfferOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a manage offer operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#manage-offer, "Manage Offer Operations")
 */
public class ManageOfferOperation:Operation {
    
    public let selling:Asset
    public let buying:Asset
    public let amount:String
    public let price:String
    public let offerId:UInt64
    
    public init(sourceAccount:KeyPair, selling:Asset, buying:Asset, amount:String, price:String, offerId:UInt64) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        self.offerId = offerId
        super.init(sourceAccount:sourceAccount)
    }
}
