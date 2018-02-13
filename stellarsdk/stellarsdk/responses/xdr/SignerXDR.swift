//
//  SignerXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct SignerXDR: XDRCodable {
    public let key: SignerKeyXDR;
    public let weight: UInt32
    
    public init(key: SignerKeyXDR, weight:UInt32) {
        self.key = key
        self.weight = weight
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        key = try container.decode(SignerKeyXDR.self)
        weight = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(weight)
    }
}
