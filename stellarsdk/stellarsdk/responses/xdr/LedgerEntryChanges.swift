//
//  LedgerEntryChanges.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct LedgerEntryChanges: XDRCodable {
    public let LedgerEntryChanges: [LedgerEntryChange]
    
    public init(LedgerEntryChanges: [LedgerEntryChange]) {
        self.LedgerEntryChanges = LedgerEntryChanges
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        LedgerEntryChanges = try container.decode([LedgerEntryChange].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(LedgerEntryChanges)
    }
}
