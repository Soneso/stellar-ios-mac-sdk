//
//  DecoratedSignatureXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DecoratedSignatureXDR: XDRCodable {
    public let hint: WrappedData4;
    public let signature: Data
    
    public init(hint: WrappedData4, signature: Data) {
        self.hint = hint
        self.signature = signature
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        hint = try container.decode(WrappedData4.self)
        signature = try container.decode(Data.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(hint)
        try container.encode(signature)
    }
    
}
