//
//  ManageOfferOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a manage offer operation. Creates, updates, or deletes an offer.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#manage-offer, "Manage Offer Operations")
 */
public class ManageOfferOperation:Operation {
    
    public let selling:Asset
    public let buying:Asset
    public let amount:String
    public let price:String
    public let offerId:UInt64
    
    /**
        Constructor
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
        - Parameter selling: Asset the offer creator is selling.
        - Parameter buying: Asset the offer creator is buying.
        - Parameter amount: Amount of selling being sold. Set to 0 if you want to delete an existing offer.
        - Parameter price: Price of 1 unit of selling in terms of buying. For example, if you wanted to sell 30 XLM and buy 5 BTC, the price would be {5,30}.
        - Parameter offerId: The ID of the offer. 0 for new offer. Set to existing offer ID to update or delete. If you want to update an existing offer set Offer ID to existing offer ID. If you want to delete an existing offer set Offer ID to existing offer ID and set Amount to 0.
     */
    public init(sourceAccount:KeyPair, selling:Asset, buying:Asset, amount:String, price:String, offerId:UInt64) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        self.offerId = offerId
        super.init(sourceAccount:sourceAccount)
    }
}
