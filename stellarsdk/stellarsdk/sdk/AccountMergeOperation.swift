//
//  AccountMergeOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents an account merge operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#account-merge, "Account Merge Operations")
 */
public class AccountMergeOperation:Operation {
    
    public let destination:KeyPair
    
    public init(sourceAccount:KeyPair, destination:KeyPair) {
        self.destination = destination
        super.init(sourceAccount:sourceAccount)
    }
}
