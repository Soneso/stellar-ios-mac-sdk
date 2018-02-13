//
//  ManageDataOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct ManageDataOperationXDR: XDRCodable {
    public let dataName: String
    public var dataValue: DataValueXDR?
    
    public init(dataName: String, dataValue: DataValueXDR?) {
        self.dataName = dataName
        self.dataValue = dataValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        dataName = try container.decode(String.self)
        dataValue = try container.decode(Array<DataValueXDR>.self).first
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(dataName)
        try container.encode(dataName)
    }
}
