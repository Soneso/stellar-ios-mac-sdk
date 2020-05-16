//
//  MuxedAccountMed25519XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct MuxedAccountMed25519XDR: XDRCodable {
    public let id: UInt64
    public let sourceAccountEd25519: [UInt8]
    
    public init(id: UInt64, sourceAccountEd25519: [UInt8]) {
        self.id = id
        self.sourceAccountEd25519 = sourceAccountEd25519
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        id = try container.decode(UInt64.self)
        let wrappedData = try container.decode(WrappedData32.self)
        self.sourceAccountEd25519 = wrappedData.wrapped.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: wrappedData.wrapped.count))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(id)
        var bytesArray = sourceAccountEd25519
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }
}
