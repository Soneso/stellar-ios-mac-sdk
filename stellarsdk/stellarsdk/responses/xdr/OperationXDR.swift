//
//  OperationXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct OperationXDR: XDRCodable {
    public var sourceAccount: PublicKey?
    public let body: OperationBodyXDR
    
    public init(sourceAccount: PublicKey?, body: OperationBodyXDR) {
        self.sourceAccount = sourceAccount
        self.body = body
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try decodeArray(type: PublicKey.self, dec: decoder).first
        body = try container.decode(OperationBodyXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        if sourceAccount != nil {
            try container.encode([sourceAccount])
        }
        else {
            try container.encode([PublicKey]())
        }
        
        try container.encode(body)
    }
}
