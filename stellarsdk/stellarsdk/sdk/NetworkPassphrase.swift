//
//  NetworkPassphrase.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 18.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
    Each network has a network passphrase which is hashed to every transaction id.
    There is no default network passphrase that is used when sending transactions.
    You need to specify network and choose its passphrase when you submit a transaction.
 */
public enum NetworkPassphrase: String {
    case publicNetwork = "Public Global Stellar Network ; September 2015"
    case testNetwork = "Test SDF Network ; September 2015"
}
