//
//  Price.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct PriceXDR: XDRCodable {
    public let n: Int32
    public let d: Int32
    
    public init(n: Int32, d:Int32) {
        self.n = n
        self.d = d
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        n = try container.decode(Int32.self)
        d = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(n)
        try container.encode(d)
    }
}
