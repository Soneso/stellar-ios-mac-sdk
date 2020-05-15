//
//  TransactionV0EnvelopeXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class TransactionV0EnvelopeXDR: NSObject, XDRCodable {
    public let tx: TransactionV0XDR
    public var signatures: [DecoratedSignatureXDR]
    
    public init(tx: TransactionV0XDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(TransactionV0XDR.self)
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
            let pk = PublicKey(unchecked: tx.sourceAccountEd25519)
            return pk.accountId
        }
    }
}
