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
    public var dataValue: Data?
    
    public init(dataName: String, dataValue: Data?) {
        self.dataName = dataName
        self.dataValue = dataValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        dataName = try container.decode(String.self)
        let strData = try decodeArray(type: String.self, dec: decoder).first
        dataValue = strData?.data(using: .utf8)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(dataName)
        try container.encode(dataValue)
    }
}
