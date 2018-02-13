//
//  LedgerEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerEntryType: Int32 {
    case account = 0
    case trustline = 1
    case offer = 2
    case data = 3
}

public struct LedgerEntryXDR: XDRCodable {
    public let lastModifiedLedgerSeq: UInt32;
    public let data: LedgerEntryDataXDR
    public let reserved: Int32 = 0
    
    
    public init(lastModifiedLedgerSeq: UInt32, data:LedgerEntryDataXDR) {
        self.lastModifiedLedgerSeq = lastModifiedLedgerSeq
        self.data = data
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lastModifiedLedgerSeq = try container.decode(UInt32.self)
        data = try container.decode(LedgerEntryDataXDR.self)
        _ = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lastModifiedLedgerSeq)
        try container.encode(data)
        try container.encode(reserved)
    }
}
