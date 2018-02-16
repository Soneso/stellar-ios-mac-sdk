//
//  AllowTrustOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents an allow trust operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#allow-trust, "Change Trust Operations")
 */
public class AllowTrustOperation:Operation {
    
    public let trustor:KeyPair
    public let assetCode:String
    public let authorize:Bool
    
    public init(sourceAccount:KeyPair, trustor:KeyPair, assetCode:String, authorize:Bool) {
        self.trustor = trustor
        self.assetCode = assetCode
        self.authorize = authorize
        super.init(sourceAccount:sourceAccount)
    }
}
