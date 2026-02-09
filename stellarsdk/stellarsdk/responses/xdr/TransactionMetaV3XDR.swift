//
//  TransactionMetaV3XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public struct TransactionMetaV3XDR: XDRCodable, Sendable {

    public var ext:ExtensionPoint
    public let txChangesBefore: LedgerEntryChangesXDR
    public var operations:[OperationMetaXDR]
    public let txChangesAfter: LedgerEntryChangesXDR
    public let sorobanMeta: SorobanTransactionMetaXDR?
    
    public init(ext: ExtensionPoint, txChangesBefore: LedgerEntryChangesXDR, operations: [OperationMetaXDR], txChangesAfter: LedgerEntryChangesXDR, sorobanMeta: SorobanTransactionMetaXDR? = nil) {
        self.ext = ext
        self.txChangesBefore = txChangesBefore
        self.operations = operations
        self.txChangesAfter = txChangesAfter
        self.sorobanMeta = sorobanMeta
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        txChangesBefore = try container.decode(LedgerEntryChangesXDR.self)
        operations = try decodeArray(type: OperationMetaXDR.self, dec: decoder)
        txChangesAfter = try container.decode(LedgerEntryChangesXDR.self)
        sorobanMeta = try decodeArray(type: SorobanTransactionMetaXDR.self, dec: decoder).first
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
    }
}

public struct SorobanTransactionMetaXDR: XDRCodable, Sendable {
    public var ext: SorobanTransactionMetaExt
    public var events:[ContractEventXDR]
    public var returnValue: SCValXDR
    public let diagnosticEvents: [DiagnosticEventXDR]

    public init(ext: SorobanTransactionMetaExt, events: [ContractEventXDR], returnValue: SCValXDR, diagnosticEvents: [DiagnosticEventXDR]) {
        self.ext = ext
        self.events = events
        self.returnValue = returnValue
        self.diagnosticEvents = diagnosticEvents
    }

    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(SorobanTransactionMetaExt.self)
        events = try decodeArray(type: ContractEventXDR.self, dec: decoder)
        returnValue = try container.decode(SCValXDR.self)
        diagnosticEvents = try decodeArray(type: DiagnosticEventXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(events)
        try container.encode(returnValue)
        try container.encode(diagnosticEvents)
    }
}

public enum SorobanTransactionMetaExt: XDRCodable, Sendable {
    case void
    case v1 (SorobanTransactionMetaExtV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .v1(try SorobanTransactionMetaExtV1(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .v1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .v1(let extV1):
            try container.encode(extV1)
        }
    }
}

public struct SorobanTransactionMetaExtV1: XDRCodable, Sendable {
    public var ext:ExtensionPoint
    
    // The following are the components of the overall Soroban resource fee
    // charged for the transaction.
    // The following relation holds:
    // `resourceFeeCharged = totalNonRefundableResourceFeeCharged + totalRefundableResourceFeeCharged`
    // where `resourceFeeCharged` is the overall fee charged for the
    // transaction. Also, `resourceFeeCharged` <= `sorobanData.resourceFee`
    // i.e.we never charge more than the declared resource fee.
    // The inclusion fee for charged the Soroban transaction can be found using
    // the following equation:
    // `result.feeCharged = resourceFeeCharged + inclusionFeeCharged`.
    
    // Total amount (in stroops) that has been charged for non-refundable
    // Soroban resources.
    // Non-refundable resources are charged based on the usage declared in
    // the transaction envelope (such as `instructions`, `readBytes` etc.) and
    // is charged regardless of the success of the transaction.
    public let totalNonRefundableResourceFeeCharged: Int64
    
    // Total amount (in stroops) that has been charged for refundable
    // Soroban resource fees.
    // Currently this comprises the rent fee (`rentFeeCharged`) and the
    // fee for the events and return value.
    // Refundable resources are charged based on the actual resources usage.
    // Since currently refundable resources are only used for the successful
    // transactions, this will be `0` for failed transactions.
    public let totalRefundableResourceFeeCharged: Int64
    
    // Amount (in stroops) that has been charged for rent.
    // This is a part of `totalNonRefundableResourceFeeCharged`.
    public let rentFeeCharged: Int64
    
    public init(ext: ExtensionPoint, totalNonRefundableResourceFeeCharged: Int64, totalRefundableResourceFeeCharged: Int64, rentFeeCharged: Int64) {
        self.ext = ext
        self.totalNonRefundableResourceFeeCharged = totalNonRefundableResourceFeeCharged
        self.totalRefundableResourceFeeCharged = totalRefundableResourceFeeCharged
        self.rentFeeCharged = rentFeeCharged
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        totalNonRefundableResourceFeeCharged = try container.decode(Int64.self)
        totalRefundableResourceFeeCharged = try container.decode(Int64.self)
        rentFeeCharged = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(totalNonRefundableResourceFeeCharged)
        try container.encode(totalRefundableResourceFeeCharged)
        try container.encode(rentFeeCharged)
    }
}
