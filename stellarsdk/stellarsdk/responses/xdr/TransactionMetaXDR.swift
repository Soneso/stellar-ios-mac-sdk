//
//  TransactionMetaXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum TransactionMetaXDR: XDRCodable {
    case operations ([OperationMetaXDR])
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(Int32.self)
        
        switch type {
            default:
                self = .operations(try decodeArray(type: OperationMetaXDR.self, dec: decoder))
        }
    }
    
    private func type() -> Int32 {
        switch self {
            case .operations: return 0
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .operations (let op):
            try container.encode(op)
        }
    }
}
