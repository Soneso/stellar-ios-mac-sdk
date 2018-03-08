//
//  Network.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 19/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Each network has a network passphrase which is hashed to every transaction id. There is no default network passphrase that is used when sending transactions. You need to specify network and choose its passphrase when you submit a transaction.
///
public enum Network: String {
    case `public` = "Public Global Stellar Network ; September 2015"
    case testnet = "Test SDF Network ; September 2015"
    
    var networkId: Data {
        get {
            return self.rawValue.sha256Hash
        }
    }
}
