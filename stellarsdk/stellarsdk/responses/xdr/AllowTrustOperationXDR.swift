//
//  AllowTrustOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AllowTrustOperationXDR: XDRCodable {
    public var trustor: PublicKey
    public var asset: AllowTrustOpAssetXDR
    public var authorize:Bool
    
    public init(trustor: PublicKey, asset:AllowTrustOpAssetXDR, authorize:Bool) {
        self.trustor = trustor
        self.asset = asset
        self.authorize = authorize
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        trustor = try container.decode(PublicKey.self)
        asset = try container.decode(AllowTrustOpAssetXDR.self)
        authorize = try container.decode(Bool.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(trustor)
        try container.encode(asset)
        try container.encode(authorize)
    }
}
