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
    case transactionMetaV2 = 2
    case transactionMetaV3 = 3
}

public enum TransactionMetaXDR: XDRCodable {
    case operations ([OperationMetaXDR])
    case transactionMetaV1 (TransactionMetaV1XDR)
    case transactionMetaV2 (TransactionMetaV2XDR)
    case transactionMetaV3 (TransactionMetaV3XDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        if let type = try TransactionMetaType(rawValue:container.decode(Int32.self)) {
            switch type {
            case .operations:
                self = .operations(try decodeArray(type: OperationMetaXDR.self, dec: decoder))
            case .transactionMetaV1:
                self = .transactionMetaV1(try TransactionMetaV1XDR(from: decoder))
            case .transactionMetaV2:
                self = .transactionMetaV2(try TransactionMetaV2XDR(from: decoder))
            case .transactionMetaV3:
                self = .transactionMetaV3(try TransactionMetaV3XDR(from: decoder))
            }
        } else {
            throw StellarSDKError.xdrDecodingError(message: "Invalid TransactionMetaType")
        }
    }
    
    private func type() -> Int32 {
        switch self {
            case .operations: return TransactionMetaType.operations.rawValue
            case .transactionMetaV1: return TransactionMetaType.transactionMetaV1.rawValue
            case .transactionMetaV2: return TransactionMetaType.transactionMetaV2.rawValue
            case .transactionMetaV3: return TransactionMetaType.transactionMetaV3.rawValue
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
        case .transactionMetaV2 (let metaV2):
            try container.encode(metaV2)
        case .transactionMetaV3 (let metaV3):
            try container.encode(metaV3)
        }
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try TransactionMetaXDR(from: xdrDecoder)
    }
    
    public var transactionMetaV3:TransactionMetaV3XDR? {
        switch self {
        case .transactionMetaV3(let val):
            return val
        default:
            return nil
        }
    }
}
