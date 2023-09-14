//
//  ContractMetaXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.09.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCMetaKind: Int32 {
    case v0 = 0
}

public struct SCMetaV0XDR: XDRCodable {
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        key = try container.decode(String.self)
        value = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(key)
        try container.encode(value)
    }
}

public enum SCMetaEntryXDR: XDRCodable {
    case v0 (SCMetaV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(Int32.self)
        
        switch type {
        default:
            let v0 = try container.decode(SCMetaV0XDR.self)
            self = .v0(v0)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .v0: return SCMetaKind.v0.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .v0 (let value):
            try container.encode(value)
        }
    }
}
