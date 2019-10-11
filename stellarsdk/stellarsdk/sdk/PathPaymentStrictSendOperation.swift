//
//  PathPaymentStrictSendOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

public class PathPaymentStrictSendOperation:PathPaymentOperation
{
    
    /// Creates a new PathPaymentStrictSendOperation object.
    public override init(sourceAccount:KeyPair? = nil, sendAsset:Asset, sendMax:Decimal, destination:KeyPair, destAsset:Asset, destAmount:Decimal, path:[Asset]) throws {
        
        try super.init(sourceAccount: sourceAccount, sendAsset: sendAsset, sendMax: sendMax, destination: destination, destAsset: destAsset, destAmount: destAmount, path: path);
    }
    
    /// Creates a new PathPaymentStrictSendOperation object from the given PathPaymentOperationXDR object.
    public override init(fromXDR:PathPaymentOperationXDR, sourceAccount:KeyPair? = nil) {
        super.init(fromXDR: fromXDR, sourceAccount: sourceAccount)
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
        
        return OperationBodyXDR.pathPaymentStrictSend(PathPaymentOperationXDR(sendAsset: sendAssetXDR,
                                                                                 sendMax:sendMaxXDR,
                                                                                 destinationID: destination.publicKey,
                                                                                 destinationAsset: destAssetXDR,
                                                                                 destinationAmount:destAmountXDR,
                                                                                 path: pathXDR))
    }
}
