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
    case custom(networkId: String)
}

// MARK: Network Id

extension Network {
    var networkId: Data {
        switch self {
        case .public:
            return "Public Global Stellar Network ; September 2015".sha256Hash
        case .testnet:
            return "Test SDF Network ; September 2015".sha256Hash
        case .custom(let networkId):
            return networkId.sha256Hash
        }
    }
}

