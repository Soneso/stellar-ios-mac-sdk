//
//  TransactionEnvelopeXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class TransactionEnvelopeXDR: NSObject, XDRCodable {
    public let tx: TransactionXDR
    public let signatures: [DecoratedSignatureXDR]
    
    public init(tx: TransactionXDR, signatures: [DecoratedSignatureXDR]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(TransactionXDR.self)
        signatures = try container.decode([DecoratedSignatureXDR].self)
    }
}
