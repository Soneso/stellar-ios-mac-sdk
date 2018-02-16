//
//  CreatePassiveOfferOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a create passive offer operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-offer, "Create Passive Offer Operations")
 */
public class CreatePassiveOfferOperation:Operation {
    
    public let selling:Asset
    public let buying:Asset
    public let amount:String
    public let price:String
    
    public init(sourceAccount:KeyPair, selling:Asset, buying:Asset, amount:String, price:String) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        super.init(sourceAccount:sourceAccount)
    }
}
