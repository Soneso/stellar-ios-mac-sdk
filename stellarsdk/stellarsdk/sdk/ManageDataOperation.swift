//
//  ManageDataOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Represents an manage data operation.
    See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#manage-data, "Manage Data Operations")
 */
public class ManageDataOperation:Operation {
    
    public let name:String
    public let data:Data
    
    public init(sourceAccount:KeyPair, name:String, data:Data) {
        self.name = name
        self.data = data
        super.init(sourceAccount:sourceAccount)
    }
}
