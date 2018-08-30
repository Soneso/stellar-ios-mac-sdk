//
//  TransactionMetaV1.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TransactionMetaV1XDR: XDRCodable {

    public var txChanges:LedgerEntryChangesXDR
    private var operations:[OperationMetaXDR]
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        txChanges = try container.decode(LedgerEntryChangesXDR.self)
        operations = try decodeArray(type: OperationMetaXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(txChanges)
        try container.encode(operations)
    }
    
}
