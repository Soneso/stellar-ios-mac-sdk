//
//  File.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct TransactionMetaV2XDR: XDRCodable {
    
    public var txChangesBefore:LedgerEntryChangesXDR
    private var operations:[OperationMetaXDR]
    public var txChangesAfter:LedgerEntryChangesXDR
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        txChangesBefore = try container.decode(LedgerEntryChangesXDR.self)
        operations = try decodeArray(type: OperationMetaXDR.self, dec: decoder)
        txChangesAfter = try container.decode(LedgerEntryChangesXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(txChangesBefore)
        try container.encode(operations)
        try container.encode(txChangesAfter)
    }
    
}
