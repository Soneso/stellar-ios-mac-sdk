//
//  PathPaymentStrictSendOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar path payment operation guaranteeing exact source amount sent.
public class PathPaymentStrictSendOperation:PathPaymentOperation
{
    
    /// Creates a new PathPaymentStrictSendOperation object.
    public override init(sourceAccountId:String?, sendAsset:Asset, sendMax:Decimal, destinationAccountId:String, destAsset:Asset, destAmount:Decimal, path:[Asset]) throws {
        
        try super.init(sourceAccountId: sourceAccountId, sendAsset: sendAsset, sendMax: sendMax, destinationAccountId: destinationAccountId, destAsset: destAsset, destAmount: destAmount, path: path);
    }
    
    /// Creates a new PathPaymentStrictSendOperation object from the given PathPaymentOperationXDR object.
    public override init(fromXDR:PathPaymentOperationXDR, sourceAccountId:String?) {
        super.init(fromXDR: fromXDR, sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        let sendAssetXDR = try sendAsset.toXDR()
        let destAssetXDR = try destAsset.toXDR()
        var pathXDR = [AssetXDR]()
        
        for asset in path {
            try pathXDR.append(asset.toXDR())
        }
        
        let sendMaxXDR = Operation.toXDRAmount(amount: sendMax)
        let destAmountXDR = Operation.toXDRAmount(amount: destAmount)
        let mDestination = try destinationAccountId.decodeMuxedAccount()
        
        return OperationBodyXDR.pathPaymentStrictSend(PathPaymentOperationXDR(sendAsset: sendAssetXDR,
                                                                                 sendMax:sendMaxXDR,
                                                                                 destination: mDestination,
                                                                                 destinationAsset: destAssetXDR,
                                                                                 destinationAmount:destAmountXDR,
                                                                                 path: pathXDR))
    }
}
