//
//  PathPaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class PathPaymentOperation: Operation {
    
    public var amount:String
    public var sourceAmount:String
    public var from:String
    public var to:String
    public var assetType:String
    public var assetCode:String!
    public var assetIssuer:String!
    public var sendAssetType:String
    public var sendAssetCode:String!
    public var sendAssetIssuer:String!

    
    private enum CodingKeys: String, CodingKey {
        case amount
        case sourceAmount = "source_amount"
        case from
        case to
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case sendAssetType = "send_asset_type"
        case sendAssetCode = "send_asset_code"
        case sendAssetIssuer = "send_asset_issuer"

    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        sourceAmount = try values.decode(String.self, forKey: .sourceAmount)
        from = try values.decode(String.self, forKey: .from)
        to = try values.decode(String.self, forKey: .to)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        sendAssetType = try values.decode(String.self, forKey: .sendAssetType)
        sendAssetCode = try values.decodeIfPresent(String.self, forKey: .sendAssetCode)
        sendAssetIssuer = try values.decodeIfPresent(String.self, forKey: .sendAssetIssuer)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(sourceAmount, forKey: .sourceAmount)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
        try container.encode(assetType, forKey: .assetType)
        try container.encode(assetCode, forKey: .assetCode)
        try container.encode(assetIssuer, forKey: .assetIssuer)
        try container.encode(sendAssetType, forKey: .sendAssetType)
        try container.encode(sendAssetCode, forKey: .sendAssetCode)
        try container.encode(sendAssetIssuer, forKey: .sendAssetIssuer)

    }
}
