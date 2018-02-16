//
//  ChangeTrustOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents a change trust operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#change-trust, "Change Trust Operations")
 */
public class ChangeTrustOperation:Operation {
    
    public let asset:Asset
    public let limit:String
    
    public init(sourceAccount:KeyPair, asset:Asset, limit:String) {
        self.asset = asset
        self.limit = limit
        super.init(sourceAccount:sourceAccount)
    }
}
