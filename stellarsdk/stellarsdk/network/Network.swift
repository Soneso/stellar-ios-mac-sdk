//
//  Network.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 19/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum Network: String {
    case `public` = "Public Global Stellar Network ; September 2015"
    case testnet = "Test SDF Network ; September 2015"
    
    var networkId: Data {
        get {
            return self.rawValue.sha256
        }
    }
    
}

