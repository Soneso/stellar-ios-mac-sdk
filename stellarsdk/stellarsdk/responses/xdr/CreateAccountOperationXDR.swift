//
//  CreateAccountOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct CreateAccountOperationXDR: XDRCodable {
    public let destination: PublicKey
    public let startingBalance: Int64
    
    public init(destination: PublicKey, balance: Int64) {
        self.destination = destination
        self.startingBalance = balance
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        destination = try container.decode(PublicKey.self)
        startingBalance = try container.decode(Int64.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(destination)
        try container.encode(startingBalance)
    }
}
