//
//  CreatePassiveOfferOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a create passive offer operation. A passive offer is an offer that does not act on and take a reverse offer of equal price. Instead, they only take offers of lesser price.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-offer, "Create Passive Offer Operations").
public class CreatePassiveOfferOperation:Operation {
    
    public let selling:Asset
    public let buying:Asset
    public let amount:Decimal
    public let price:Price
    
    /// Creates a new CreatePassiveOfferOperation object.
    ///
    /// - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
    /// - Parameter selling: The asset you would like to sell.
    /// - Parameter buying: The asset you would like to buy.
    /// - Parameter amount: Amount of selling being sold..
    /// - Parameter price: Price of 1 unit of selling in terms of buying. For example, if you wanted to sell 30 XLM and buy 5 BTC, the price would be {numerator, denominator} = {5,30}.
    ///
    public init(sourceAccount:KeyPair? = nil, selling:Asset, buying:Asset, amount:Decimal, price:Price) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new CreatePassiveOfferOperation object from the given CreatePassiveOfferOperationXDR object.
    ///
    /// - Parameter fromXDR: the CreatePassiveOfferOperationXDR object to be used to create a new CreatePassiveOfferOperation object.
    ///
    public init(fromXDR:CreatePassiveOfferOperationXDR, sourceAccount:KeyPair? = nil) {
        self.selling = try! Asset.fromXDR(assetXDR: fromXDR.selling)
        self.buying = try! Asset.fromXDR(assetXDR: fromXDR.buying)
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        self.price = Price(numerator: fromXDR.price.n, denominator: fromXDR.price.d)
        super.init(sourceAccount: sourceAccount)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let sellingXDR = try selling.toXDR()
        let buyingXDR = try buying.toXDR()
        let amountXDR = Operation.toXDRAmount(amount: amount)
        let priceXDR = price.toXdr()
        
        return OperationBodyXDR.createPassiveOffer(CreatePassiveOfferOperationXDR(selling: sellingXDR,
                                                                                  buying: buyingXDR,
                                                                                  amount: amountXDR,
                                                                                  price: priceXDR))
    }
}
