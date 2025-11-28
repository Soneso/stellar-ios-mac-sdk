//
//  OperationMetaV2XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.06.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public struct OperationMetaV2XDR: XDRCodable, Sendable {
    public let ext: ExtensionPoint
    public let changes: LedgerEntryChangesXDR
    public let events: [ContractEventXDR]
    
    public init(ext:ExtensionPoint = ExtensionPoint.void, changes: LedgerEntryChangesXDR, events: [ContractEventXDR]) {
        self.ext = ext
        self.changes = changes
        self.events = events
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        changes = try container.decode(LedgerEntryChangesXDR.self)
        events = try decodeArray(type: ContractEventXDR.self, dec: decoder)
     }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(changes)
        try container.encode(events)
    }
}
