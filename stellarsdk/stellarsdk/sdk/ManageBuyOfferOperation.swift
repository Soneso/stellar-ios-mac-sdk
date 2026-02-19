//
//  ManageBuyOfferOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar manage buy offer operation creating or modifying offers with fixed buy amounts.
public class ManageBuyOfferOperation:ManageOfferOperation, @unchecked Sendable {
    
    /// Creates a new ManageOfferOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id,  must be valid, otherwise it will be ignored.
    /// - Parameter selling: Asset the offer creator is selling.
    /// - Parameter buying: Asset the offer creator is buying.
    /// - Parameter amount: Amount of buying being bought. Set to 0 if you want to delete an existing offer.
    /// - Parameter price: Price of 1 unit of buying in terms of selling. For example, if you wanted to buy 30 XLM and sell 5 BTC, the price would be {numerator, denominator} = {5,30}.
    /// - Parameter offerId: The ID of the offer. 0 for new offer. Set to existing offer ID to update or delete. If you want to update an existing offer set Offer ID to existing offer ID. If you want to delete an existing offer set Offer ID to existing offer ID and set Amount to 0.
    ///
    public override init(sourceAccountId:String?, selling:Asset, buying:Asset, amount:Decimal, price:Price, offerId:Int64) {
        super.init(sourceAccountId:sourceAccountId, selling:selling, buying: buying, amount:amount, price:price, offerId:offerId)
    }
    
    /// Creates a new ManageBuyOfferOperation object from the given ManageOfferOperationXDR object.
    ///
    /// - Parameter fromXDR: the ManageOfferOperationXDR object to be used to create a new ManageBuyOfferOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public override init(fromXDR:ManageOfferOperationXDR, sourceAccountId:String?) {
        super.init(fromXDR: fromXDR, sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let sellingXDR = try selling.toXDR()
        let buyingXDR = try buying.toXDR()
        let amountXDR = Operation.toXDRAmount(amount: amount)
        let priceXDR = price.toXdr()
        
        return OperationBodyXDR.manageBuyOffer(ManageOfferOperationXDR(selling: sellingXDR,
                                                                        buying: buyingXDR,
                                                                        amount: amountXDR,
                                                                        price: priceXDR,
                                                                        offerID: offerId))
    }
}
