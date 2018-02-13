//
//  DataEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DataEntryXDR: XDRCodable {
    public let accountID: PublicKey
    public let dataName: String
    public let dataValue: Data
    public let reserved: Int32 = 0
    
    public init(accountID: PublicKey, dataName:String, dataValue:Data) {
        self.accountID = accountID
        self.dataName = dataName
        self.dataValue = dataValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        accountID = try container.decode(PublicKey.self)
        dataName = try container.decode(String.self)
        dataValue = try container.decode(Data.self)
        _ = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(dataName)
        try container.encode(dataValue)
        try container.encode(reserved)
    }
}
