//
//  PathPaymentStrictReceiveOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

public class PathPaymentStrictReceiveOperation:PathPaymentOperation
{
    
    /// Creates a new PathPaymentStrictReceiveOperation object.
    @available(*, deprecated, message: "use init(sourceAccountId:String, ..., destinationAccountId:String, ...) instead")
    public override init(sourceAccount:KeyPair? = nil, sendAsset:Asset, sendMax:Decimal, destination:KeyPair, destAsset:Asset, destAmount:Decimal, path:[Asset]) throws {
        
        try super.init(sourceAccount: sourceAccount, sendAsset: sendAsset, sendMax: sendMax, destination: destination, destAsset: destAsset, destAmount: destAmount, path: path);
    }
    
    /// Creates a new PathPaymentStrictReceiveOperation object.
    public override init(sourceAccountId:String?, sendAsset:Asset, sendMax:Decimal, destinationAccountId:String, destAsset:Asset, destAmount:Decimal, path:[Asset]) throws {
        
        try super.init(sourceAccountId: sourceAccountId, sendAsset: sendAsset, sendMax: sendMax, destinationAccountId: destinationAccountId, destAsset: destAsset, destAmount: destAmount, path: path);
    }
    
    /// Creates a new PathPaymentStrictReceiveOperation object from the given PathPaymentOperationXDR object.
    @available(*, deprecated, message: "use init(fromXDR:PaymentOperationXDR, sourceAccountId:String? = nil) instead")
    public override init(fromXDR:PathPaymentOperationXDR, sourceAccount:KeyPair? = nil) {
        super.init(fromXDR: fromXDR, sourceAccount: sourceAccount)
    }
    
    /// Creates a new PathPaymentStrictReceiveOperation object from the given PathPaymentOperationXDR object.
    public override init(fromXDR:PathPaymentOperationXDR, sourceAccountId:String?) {
        super.init(fromXDR: fromXDR, sourceAccountId: sourceAccountId)
    }
}
