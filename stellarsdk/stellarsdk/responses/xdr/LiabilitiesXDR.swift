//
//  LiabilitiesXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LiabilitiesXDR: XDRCodable {
    public let buying: Int64
    public let selling: Int64
    
    public init(buying: Int64, selling: Int64) {
        self.buying = buying
        self.selling = selling
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        buying = try container.decode(Int64.self)
        selling = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(buying)
        try container.encode(selling)
    }
}
