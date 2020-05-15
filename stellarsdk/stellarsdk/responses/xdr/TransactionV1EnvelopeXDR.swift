//
//  TransactionV1EnvelopeXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class TransactionV1EnvelopeXDR: NSObject, XDRCodable {
    public let tx: TransactionXDR
    public var signatures: [DecoratedSignatureXDR]
    
    public init(tx: TransactionXDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(TransactionXDR.self)
        signatures = try decodeArray(type: DecoratedSignatureXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(tx)
        try container.encode(signatures)
    }
    
    /// Human readable Stellar account ID of the transaction.
    public var txSourceAccountId: String {
        get {
            return tx.sourceAccount.accountId
        }
    }
}
