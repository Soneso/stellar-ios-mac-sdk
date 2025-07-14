//
//  TransactionMetaV4XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.06.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public struct TransactionMetaV4XDR: XDRCodable {

    public var ext:ExtensionPoint
    
    // tx level changes before operations are applied if any
    public var txChangesBefore:LedgerEntryChangesXDR
    
    // meta for each operation
    public var operations:[OperationMetaV2XDR]
    
    //  tx level changes after operations are applied if any
    public var txChangesAfter:LedgerEntryChangesXDR
    
    // Soroban-specific meta (only for Soroban transactions).
    public var sorobanMeta:SorobanTransactionMetaV2XDR?
    
    // Used for transaction-level events (like fee payment)
    public var events:[TransactionEventXDR]
    
    // Used for all diagnostic information
    public var diagnosticEvents:[DiagnosticEventXDR]
    
    internal init(ext: ExtensionPoint, txChangesBefore: LedgerEntryChangesXDR, operations: [OperationMetaV2XDR], txChangesAfter: LedgerEntryChangesXDR, sorobanMeta: SorobanTransactionMetaV2XDR? = nil, events:[TransactionEventXDR], diagnosticEvents:[DiagnosticEventXDR]) {
        self.ext = ext
        self.txChangesBefore = txChangesBefore
        self.operations = operations
        self.txChangesAfter = txChangesAfter
        self.sorobanMeta = sorobanMeta
        self.events = events
        self.diagnosticEvents = diagnosticEvents
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        txChangesBefore = try container.decode(LedgerEntryChangesXDR.self)
        operations = try decodeArray(type: OperationMetaV2XDR.self, dec: decoder)
        txChangesAfter = try container.decode(LedgerEntryChangesXDR.self)
        sorobanMeta = try decodeArray(type: SorobanTransactionMetaV2XDR.self, dec: decoder).first
        events = try decodeArray(type: TransactionEventXDR.self, dec: decoder)
        diagnosticEvents = try decodeArray(type: DiagnosticEventXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(txChangesBefore)
        try container.encode(operations)
        try container.encode(txChangesAfter)
        if let sm = sorobanMeta {
            try container.encode(Int32(1))
            try container.encode(sm)
        }
        else {
            try container.encode(Int32(0))
        }
        
        try container.encode(events)
        try container.encode(diagnosticEvents)
    }
}

public struct SorobanTransactionMetaV2XDR: XDRCodable {
    public var ext: SorobanTransactionMetaExt
    public var returnValue: SCValXDR?

    public init(ext: SorobanTransactionMetaExt, returnValue: SCValXDR?) {
        self.ext = ext
        self.returnValue = returnValue
    }

    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(SorobanTransactionMetaExt.self)
        returnValue = try decodeArray(type: SCValXDR.self, dec: decoder).first
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(returnValue)
    }
}
