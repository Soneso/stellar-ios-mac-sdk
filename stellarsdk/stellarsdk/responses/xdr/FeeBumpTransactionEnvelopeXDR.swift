//
//  FeeBumpTransactionEnvelopeXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class FeeBumpTransactionEnvelopeXDR: NSObject, XDRCodable {
    public let tx: FeeBumpTransactionXDR
    public var signatures: [DecoratedSignatureXDR]
    
    public init(tx: FeeBumpTransactionXDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(FeeBumpTransactionXDR.self)
        signatures = try decodeArray(type: DecoratedSignatureXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(tx)
        try container.encode(signatures)
    }
}
