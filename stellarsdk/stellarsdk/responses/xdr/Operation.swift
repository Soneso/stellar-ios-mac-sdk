//
//  Operation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct Operation: XDRCodable {
    public var sourceAccount: PublicKey?
    public let body: OperationBody
    
    init(sourceAccount: PublicKey?, body: OperationBody) {
        self.sourceAccount = sourceAccount
        self.body = body
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(Array<PublicKey>.self).first
        body = try container.decode(OperationBody.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        if sourceAccount != nil {
            try container.encode(1)
            try container.encode(sourceAccount)
        }
        else {
            try container.encode(0)
        }
        
        try container.encode(body)
    }
}
