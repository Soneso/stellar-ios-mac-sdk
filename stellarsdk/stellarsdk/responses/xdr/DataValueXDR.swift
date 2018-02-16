//
//  DataValueXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DataValueXDR: XDRCodable
{
    public let dataValue:Data?
    
    public init(dataValue: Data?) {
        self.dataValue = dataValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        dataValue = try container.decode(Data.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(dataValue)
    }
}
