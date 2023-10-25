//
//  ExtendFootprintTTLOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct ExtendFootprintTTLOpXDR: XDRCodable {
    public var ext: ExtensionPoint
    public var extendTo: UInt32
    
    public init(ext: ExtensionPoint, extendTo: UInt32) {
        self.ext = ext
        self.extendTo = extendTo
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        extendTo = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(extendTo)
    }
}
