//
//  TransactionEventXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.06.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

// Transaction-level events happen at different stages of the ledger apply flow
// (as opposed to the operation events that all happen atomically after a transaction is applied).
// This enum represents the possible stages during which an event has been emitted.
public enum TransactionEventStage: Int32, Sendable {
    // The event has happened before any one of the transactions has its operations applied.
    case beforeAllTxs = 0
    
    // The event has happened immediately after operations of the transaction have been applied.
    case afterTx = 1
    
    // The event has happened after every transaction had its operations applied.
    case afterAllTx = 2
}

// Represents a transaction-level event in metadata.
// Currently this is limited to the fee events (when fee is charged or refunded).
public struct TransactionEventXDR: XDRCodable, Sendable {
    
    // Stage at which an event has occurred.
    public let stage: TransactionEventStage
    
    // The contract event that has occurred.
    public let event: ContractEventXDR
    
    public init(stage: TransactionEventStage, event: ContractEventXDR) {
        self.stage = stage
        self.event = event
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        guard let decodedStage = TransactionEventStage(rawValue: discriminant) else {
            throw StellarSDKError.decodingError(message: "unknown TransactionEventStage value: \(discriminant)")
        }
        stage = decodedStage
        event = try container.decode(ContractEventXDR.self)
     }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(stage.rawValue)
        try container.encode(event)
    }
}
