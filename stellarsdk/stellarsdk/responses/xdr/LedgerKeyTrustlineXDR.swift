//
//  LedgerKeyTrustlineXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerKeyTrustLineXDR: XDRCodable {
    let accountID: PublicKey
    let asset: AssetXDR
    
    init(accountID: PublicKey, asset: AssetXDR) {
        self.accountID = accountID
        self.asset = asset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(asset)
    }
}
