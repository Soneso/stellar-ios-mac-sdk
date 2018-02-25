//
//  String32.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 24.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class String32XDR : XDRCodable {
    
    public let string:String
    
    public init?(string:String?) {
        if (string == nil) {return nil}
        self.string = string!
    }
    
    public required init(fromBinary decoder: XDRDecoder) throws {
        let utf8: [UInt8] = try Array(fromBinary: decoder)
        if let str = String(bytes: utf8, encoding: .utf8) {
            self.string = str
        } else {
            throw XDRDecoder.Error.invalidUTF8(utf8)
        }
    }
    
    public func xdrEncode(to encoder: XDREncoder) throws {
        let array = Array(self.string.utf8)

        try encoder.encode(Int32(array.count))
        
        for i in 0 ... 31 {
            if i < array.count {
                try (array[i] as Encodable).encode(to: encoder)
            } else {
                try (UInt8(0) as Encodable).encode(to: encoder)
            }
        }
    }
}
