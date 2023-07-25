//
//  RestoreFootprintOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct RestoreFootprintOpXDR: XDRCodable {
    public var ext: ExtensionPoint
    
    public init(ext: ExtensionPoint) {
        self.ext = ext
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
    }
}
