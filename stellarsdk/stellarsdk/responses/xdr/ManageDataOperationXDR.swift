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
        let dataValuePresent = try container.decode(UInt32.self)
        if dataValuePresent != 0 {
            let data = try decodeArray(type:UInt8.self, dec: decoder)
            dataValue = Data(bytes: data)
        } else {
            dataValue = nil
        }
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(dataName)
        if let dataValue = dataValue {
            let flag: Int32 = 1
            try container.encode(flag)
            try container.encode(dataValue.bytes)
        } else {
            let flag: Int32 = 0
            try container.encode(flag)
        }
        
    }
}
