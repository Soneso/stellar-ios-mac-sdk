//
//  ManageDataOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct ManageDataOperation: XDRCodable {
    public let dataName: String
    public var dataValue: DataValue?
    
    public init(dataName: String, dataValue: DataValue?) {
        self.dataName = dataName
        self.dataValue = dataValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        dataName = try container.decode(String.self)
        dataValue = try container.decode(Array<DataValue>.self).first
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(dataName)
        try container.encode(dataName)
    }
}
