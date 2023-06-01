//
//  TransactionMetaV3XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct TransactionMetaV3XDR: XDRCodable {
    
    public var txChangesBefore:LedgerEntryChangesXDR
    public var operations:[OperationMetaXDR]
    public var txChangesAfter:LedgerEntryChangesXDR
    public var events:[OperationEventsXDR]
    public var txResult:TransactionResultXDR
    public var hashes:[WrappedData32]
    public var diagnosticEvents:[OperationDiagnosticEventsXDR]
    
    public init(txChangesBefore:LedgerEntryChangesXDR, operations:[OperationMetaXDR], txChangesAfter:LedgerEntryChangesXDR, events:[OperationEventsXDR], txResult:TransactionResultXDR,hashes:[WrappedData32], diagnosticEvents:[OperationDiagnosticEventsXDR]) {
        self.txChangesBefore = txChangesBefore
        self.operations = operations
        self.txChangesAfter = txChangesAfter
        self.events = events
        self.txResult = txResult
        self.hashes = hashes
        self.diagnosticEvents = diagnosticEvents
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        txChangesBefore = try container.decode(LedgerEntryChangesXDR.self)
        operations = try decodeArray(type: OperationMetaXDR.self, dec: decoder)
        txChangesAfter = try container.decode(LedgerEntryChangesXDR.self)
        events = try decodeArray(type: OperationEventsXDR.self, dec: decoder)
        txResult = try container.decode(TransactionResultXDR.self)
        hashes = [try container.decode(WrappedData32.self), try container.decode(WrappedData32.self), try container.decode(WrappedData32.self)]
        diagnosticEvents = try decodeArray(type: OperationDiagnosticEventsXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(txChangesBefore)
        try container.encode(operations)
        try container.encode(txChangesAfter)
        try container.encode(events)
        try container.encode(txResult)
        try container.encode(hashes[0])
        try container.encode(hashes[1])
        try container.encode(hashes[2])
        try container.encode(diagnosticEvents)
    }
    
}

public struct OperationEventsXDR: XDRCodable {
    public var events:[ContractEventXDR]
    
    public init(events:[ContractEventXDR]) {
        self.events = events
    }
    
    public init(from decoder: Decoder) throws {
        events = try decodeArray(type: ContractEventXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(events)
    }
}
