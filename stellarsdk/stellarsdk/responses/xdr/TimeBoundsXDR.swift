//
//  TimeBoundsXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TimeBoundsXDR: XDRCodable {
    public let minTime: UInt64
    public let maxTime: UInt64
    
    public init(minTime: UInt64, maxTime: UInt64) {
        self.minTime = minTime
        self.maxTime = maxTime
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        minTime = try container.decode(UInt64.self)
        maxTime = try container.decode(UInt64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(minTime)
        try container.encode(minTime)
    }
    
}
