//
//  LedgerEntryChangesXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerEntryChangesXDR: XDRCodable {
    public let ledgerEntryChanges: [LedgerEntryChangeXDR]
    
    public init(LedgerEntryChanges: [LedgerEntryChangeXDR]) {
        self.ledgerEntryChanges = LedgerEntryChanges
    }
    
    public init(from decoder: Decoder) throws {
        ledgerEntryChanges = try decodeArray(type: LedgerEntryChangeXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerEntryChanges)
    }
}
