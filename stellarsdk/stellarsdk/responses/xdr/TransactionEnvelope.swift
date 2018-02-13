//
//  TransactionEnvelope.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class TransactionEnvelope: NSObject, XDRCodable {
    public let tx: Transaction
    public let signatures: [DecoratedSignature]
    
    public init(tx: Transaction, signatures: [DecoratedSignature]) {
        self.tx = tx
        self.signatures = signatures
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        tx = try container.decode(Transaction.self)
        signatures = try container.decode([DecoratedSignature].self)
    }
}
