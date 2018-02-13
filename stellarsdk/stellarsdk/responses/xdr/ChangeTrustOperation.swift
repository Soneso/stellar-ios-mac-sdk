//
//  ChangeTrustOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct ChangeTrustOperation: XDRCodable {
    public let asset: Asset
    public let limit: Int64 = Int64.max
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        asset = try container.decode(Asset.self)
        _ = try container.decode(Int64.self)
    }
    
    public init(asset: Asset) {
        self.asset = asset
    }
}
