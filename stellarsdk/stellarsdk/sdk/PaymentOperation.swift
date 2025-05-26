//
//  PaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a payment operation. Sends an amount in a specific asset to a destination account.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#payment, "Payment Operation").
public class PaymentOperation:Operation {
    
    public let destinationAccountId:String
    public let asset:Asset
    public let amount:Decimal
    
    /// Creates a new PaymentOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    /// - Parameter destinationAccountId: Account address that receives the payment. Must start with "G" and must be valid, otherwise this will throw an exception.
    /// - Parameter asset: Asset to send to the destination account.
    /// - Parameter amount: Amount of the aforementioned asset to send.
    public init(sourceAccountId:String?, destinationAccountId:String, asset:Asset, amount:Decimal) throws {
        
        let mux = try destinationAccountId.decodeMuxedAccount()
        self.destinationAccountId = mux.accountId
        self.asset = asset
        self.amount = amount
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new PaymentOperation object from the given PaymentOperationXDR object.
    ///
    /// - Parameter fromXDR: the PaymentOperationXDR object to be used to create a new PaymentOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:PaymentOperationXDR, sourceAccountId:String?) {
        self.destinationAccountId = fromXDR.destination.accountId
        self.asset = try! Asset.fromXDR(assetXDR: fromXDR.asset)
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let assetXDR = try asset.toXDR()
        let xdrAmount = Operation.toXDRAmount(amount: amount)
        let mDestination = try destinationAccountId.decodeMuxedAccount()
        return OperationBodyXDR.payment(PaymentOperationXDR(destination: mDestination,
                                                            asset:assetXDR,
                                                            amount: xdrAmount))
    }
}
