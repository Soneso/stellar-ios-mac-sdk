//
//  PathPaymentStrictReceiveOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar path payment operation guaranteeing exact destination amount received.
public class PathPaymentStrictReceiveOperation:PathPaymentOperation
{
    
    /// Creates a new PathPaymentStrictReceiveOperation object.
    public override init(sourceAccountId:String?, sendAsset:Asset, sendMax:Decimal, destinationAccountId:String, destAsset:Asset, destAmount:Decimal, path:[Asset]) throws {
        
        try super.init(sourceAccountId: sourceAccountId, sendAsset: sendAsset, sendMax: sendMax, destinationAccountId: destinationAccountId, destAsset: destAsset, destAmount: destAmount, path: path);
    }
    
    /// Creates a new PathPaymentStrictReceiveOperation object from the given PathPaymentOperationXDR object.
    public override init(fromXDR:PathPaymentOperationXDR, sourceAccountId:String?) {
        super.init(fromXDR: fromXDR, sourceAccountId: sourceAccountId)
    }
}
