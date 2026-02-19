//
//  ManageOfferOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a manage offer operation. Creates, updates, or deletes an offer.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ManageOfferOperation:Operation, @unchecked Sendable {

    /// The asset being sold.
    public let selling:Asset
    /// The asset being bought.
    public let buying:Asset
    /// Amount of selling asset to sell. Set to 0 to delete an existing offer.
    public let amount:Decimal
    /// Price of 1 unit of selling in terms of buying.
    public let price:Price
    /// The ID of the offer. 0 for new offer. Set to existing offer ID to update or delete.
    public let offerId:Int64
    
    /// Creates a new ManageOfferOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    /// - Parameter selling: Asset the offer creator is selling.
    /// - Parameter buying: Asset the offer creator is buying.
    /// - Parameter amount: Amount of selling being sold. Set to 0 if you want to delete an existing offer.
    /// - Parameter price: Price of 1 unit of selling in terms of buying. For example, if you wanted to sell 30 XLM and buy 5 BTC, the price would be {numerator, denominator} = {5,30}.
    /// - Parameter offerId: The ID of the offer. 0 for new offer. Set to existing offer ID to update or delete. If you want to update an existing offer set Offer ID to existing offer ID. If you want to delete an existing offer set Offer ID to existing offer ID and set Amount to 0.
    ///
    public init(sourceAccountId:String?, selling:Asset, buying:Asset, amount:Decimal, price:Price, offerId:Int64) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        self.offerId = offerId
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new ManageOfferOperation object from the given ManageOfferOperationXDR object.
    ///
    /// - Parameter fromXDR: the ManageOfferOperationXDR object to be used to create a new ManageOfferOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:ManageOfferOperationXDR, sourceAccountId:String?) {
        self.selling = try! Asset.fromXDR(assetXDR: fromXDR.selling)
        self.buying = try! Asset.fromXDR(assetXDR: fromXDR.buying)
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        self.price = Price(numerator: fromXDR.price.n, denominator: fromXDR.price.d)
        self.offerId = fromXDR.offerID
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let sellingXDR = try selling.toXDR()
        let buyingXDR = try buying.toXDR()
        let amountXDR = Operation.toXDRAmount(amount: amount)
        let priceXDR = price.toXdr()
        
        return OperationBodyXDR.manageSellOffer(ManageOfferOperationXDR(selling: sellingXDR,
                                                                    buying: buyingXDR,
                                                                    amount: amountXDR,
                                                                    price: priceXDR,
                                                                    offerID: offerId))
    }
}
