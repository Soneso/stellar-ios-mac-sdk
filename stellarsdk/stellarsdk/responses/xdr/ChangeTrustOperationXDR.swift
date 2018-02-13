//
//  ChangeTrustOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct ChangeTrustOperationXDR: XDRCodable {
    public let asset: AssetXDR
    public let limit: Int64 = Int64.max
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        asset = try container.decode(AssetXDR.self)
        _ = try container.decode(Int64.self)
    }
    
    public init(asset: AssetXDR) {
        self.asset = asset
    }
}
