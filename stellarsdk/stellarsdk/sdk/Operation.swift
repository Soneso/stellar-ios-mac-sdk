//
//  Operation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Superclass for operations. You should never use this class directly. Please use one of its subclasses.
    See [Stellar Guides] (https://www.stellar.org/developers/guides/concepts/operations.html, "Operations")
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html, "List of Operations")
 */

public class Operation {
    let sourceAccount:KeyPair?
    
    /**
        Initializer
     
        - Parameter sourceAccount: Operations are executed on behalf of the source account specified in the transaction, unless there is an override defined for the operation.
     */
    public init(sourceAccount:KeyPair?) {
        self.sourceAccount = sourceAccount
    }
}
