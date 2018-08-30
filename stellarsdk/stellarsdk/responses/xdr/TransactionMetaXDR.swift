//
//  TransactionMetaXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum TransactionMetaType: Int32 {
    case operations = 0
    case transactionMetaV1 = 1
}

public enum TransactionMetaXDR: XDRCodable {
    case operations ([OperationMetaXDR])
    case transactionMetaV1 (TransactionMetaV1XDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        if let type = try TransactionMetaType(rawValue:container.decode(Int32.self)) {
            switch type {
            case .operations:
                self = .operations(try decodeArray(type: OperationMetaXDR.self, dec: decoder))
            case .transactionMetaV1:
                self = .transactionMetaV1(try TransactionMetaV1XDR(from: decoder))
            }
        } else {
            throw StellarSDKError.xdrDecodingError(message: "Invalid TransactionMetaType")
        }
    }
    
    private func type() -> Int32 {
        switch self {
            case .operations: return TransactionMetaType.operations.rawValue
            case .transactionMetaV1: return TransactionMetaType.transactionMetaV1.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .operations (let op):
            try container.encode(op)
        case .transactionMetaV1 (let metaV1):
            try container.encode(metaV1)
        }
    }
}
