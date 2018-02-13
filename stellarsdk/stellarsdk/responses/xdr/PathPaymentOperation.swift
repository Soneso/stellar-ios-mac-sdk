//
//  PathPaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct PathPaymentOperation: XDRCodable {
    public let sendAsset: Asset
    public let sendMax: Int64
    public let destinationID: PublicKey
    public let destinationAsset: Asset
    public let destinationAmount: Int64
    public let path: [Asset]
    
    init(sendAsset: Asset, sendMax: Int64, destinationID: PublicKey, destinationAsset: Asset, destinationAmount:Int64, path:[Asset]) {
        self.sendAsset = sendAsset
        self.sendMax = sendMax
        self.destinationID = destinationID
        self.destinationAsset = destinationAsset
        self.destinationAmount = destinationAmount
        self.path = path
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sendAsset = try container.decode(Asset.self)
        sendMax = try container.decode(Int64.self)
        destinationID = try container.decode(PublicKey.self)
        destinationAsset = try container.decode(Asset.self)
        destinationAmount = try container.decode(Int64.self)
        self.path = try container.decode(Array<Asset>.self)
        
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
