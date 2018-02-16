//
//  PathPaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a path payment operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#path-payment, "Path Payment Operations")
 */
public class PathPaymentOperation:Operation {
    
    public let sendAsset:Asset
    public let sendMax:String
    public let destination:KeyPair
    public let destAsset:Asset
    public let destAmount:String
    public let path:[Asset]
    
    public init(sourceAccount:KeyPair, sendAsset:Asset, sendMax:String, destination:KeyPair, destAsset:Asset, destAmount:String, path:[Asset]) {
        self.sendAsset = sendAsset
        self.sendMax = sendMax
        self.destination = destination
        self.destAsset = destAsset
        self.destAmount = destAmount
        self.path = path
        super.init(sourceAccount:sourceAccount)
    }
}
