//
//  PaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a payment operation. Sends an amount in a specific asset to a destination account.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#payment, "Payment Operation")
 */
public class PaymentOperation:Operation {
    
    public let destination:KeyPair
    public let asset:Asset
    public let amount:String
    
    /**
        Constructor
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
        - Parameter destination: Account address that receives the payment.
        - Parameter asset: Asset to send to the destination account.
        - Parameter amount: Amount of the aforementioned asset to send.
     */
    public init(sourceAccount:KeyPair, destination:KeyPair, asset:Asset, amount:String) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
        super.init(sourceAccount:sourceAccount)
    }
}
