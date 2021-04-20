//
//  ClawbackOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class ClawbackOperation:Operation {
    
    public let asset:Asset
    public let fromAccountId:String
    public let amount:Decimal
    
    
    /// Creates a new ClawbackOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "M" or "G" and must be valid, otherwise it will be ignored.
    /// - Parameter asset: The asset to be clawed back
    /// - Parameter fromAccountId: account from which the asset is clawed back
    /// - Parameter amount:  asset amount clawed back
    ///
    public init(sourceAccountId:String?, asset:Asset,fromAccountId:String, amount:Decimal) {
        self.asset = asset
        self.fromAccountId = fromAccountId
        self.amount = amount
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new ClawbackOperation object from the given ClawbackOpXDR object.
    ///
    /// - Parameter fromXDR: the ClawbackOpXDR object to be used to create a new ClawbackOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:ClawbackOpXDR, sourceAccountId:String?) {
        self.asset = try! Asset.fromXDR(assetXDR: fromXDR.asset)
        self.fromAccountId = fromXDR.from.accountId
        self.amount = Operation.fromXDRAmount(fromXDR.amount)
        
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let assetXDR = try asset.toXDR()
        let amountXDR = Operation.toXDRAmount(amount: amount)
        let fromXDR = try fromAccountId.decodeMuxedAccount()
    
        return OperationBodyXDR.clawback(ClawbackOpXDR(asset: assetXDR, from: fromXDR, amount: amountXDR))
    }
}
