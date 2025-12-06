//
//  ContractEnvMetaXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCEnvMetaKind: Int32 {
    case interfaceVersion = 0
}

public enum SCEnvMetaEntryXDR: XDRCodable, Sendable {
    case interfaceVersion (UInt64)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(Int32.self)
        
        switch type {
        default:
            let version = try container.decode(UInt64.self)
            self = .interfaceVersion(version)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .interfaceVersion: return SCEnvMetaKind.interfaceVersion.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .interfaceVersion (let version):
            try container.encode(version)
        }
    }
}
