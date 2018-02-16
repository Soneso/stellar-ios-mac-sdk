//
//  PaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a payment operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#payment, "Payment Operation")
 */
public class PaymentOperation:Operation {
    
    public let destination:KeyPair
    public let asset:Asset
    public let amount:String
    
    public init(sourceAccount:KeyPair, destination:KeyPair, asset:Asset, amount:String) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
        super.init(sourceAccount:sourceAccount)
    }
}
