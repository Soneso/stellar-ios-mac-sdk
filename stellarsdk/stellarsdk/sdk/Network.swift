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
public enum Network {
    case `public`
    case testnet
    case futurenet
    case custom(passphrase: String)
}

// MARK: passphrase, Network Id

public extension Network {
    
    var networkId: Data {
        return passphrase.sha256Hash
    }
    
    var passphrase: String {
        switch self {
        case .public:
            return "Public Global Stellar Network ; September 2015"
        case .testnet:
            return "Test SDF Network ; September 2015"
        case .futurenet:
            return "Test SDF Future Network ; October 2022"
        case .custom(let passphrase):
            return passphrase
        }
    }
}

