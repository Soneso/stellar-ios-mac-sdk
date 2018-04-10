//
//  PathPaymentOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct PathPaymentOperationXDR: XDRCodable {
    public let sendAsset: AssetXDR
    public let sendMax: Int64
    public let destinationID: PublicKey
    public let destinationAsset: AssetXDR
    public let destinationAmount: Int64
    public let path: [AssetXDR]
    
    init(sendAsset: AssetXDR, sendMax: Int64, destinationID: PublicKey, destinationAsset: AssetXDR, destinationAmount:Int64, path:[AssetXDR]) {
        self.sendAsset = sendAsset
        self.sendMax = sendMax
        self.destinationID = destinationID
        self.destinationAsset = destinationAsset
        self.destinationAmount = destinationAmount
        self.path = path
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sendAsset = try container.decode(AssetXDR.self)
        sendMax = try container.decode(Int64.self)
        destinationID = try container.decode(PublicKey.self)
        destinationAsset = try container.decode(AssetXDR.self)
        destinationAmount = try container.decode(Int64.self)
        self.path = try decodeArray(type: AssetXDR.self, dec: decoder)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sendAsset)
        try container.encode(sendMax)
        try container.encode(destinationID)
        try container.encode(destinationAsset)
        try container.encode(destinationAmount)
        try container.encode(path)
    }
}
