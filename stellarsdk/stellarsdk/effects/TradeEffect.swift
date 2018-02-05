//
//  TradeEffect.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class TradeEffect: Effect {
    public var seller:String
    public var offerId:Int64
    public var soldAmount:String
    public var soldAssetType:String
    public var soldAssetCode:String!
    public var soldAssetIssuer:String!
    public var boughtAmount:String
    public var boughtAssetType:String
    public var boughtAssetCode:String!
    public var boughtAssetIssuer:String!
    
    private enum CodingKeys: String, CodingKey {
        case seller
        case offerId = "offer_id"
        case soldAmount = "sold_amount"
        case soldAssetType = "sold_asset_type"
        case soldAssetCode = "sold_asset_code"
        case soldAssetIssuer = "sold_asset_issuer"
        case boughtAmount = "bought_amount"
        case boughtAssetType = "bought_asset_type"
        case boughtAssetCode = "bought_asset_code"
        case boughtAssetIssuer = "bought_asset_issuer"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        seller = try values.decode(String.self, forKey: .seller)
        offerId = try values.decode(Int64.self, forKey: .offerId)
        soldAmount = try values.decode(String.self, forKey: .soldAmount)
        soldAssetType = try values.decode(String.self, forKey: .soldAssetType)
        soldAssetCode = try values.decodeIfPresent(String.self, forKey: .soldAssetCode)
        soldAssetIssuer = try values.decodeIfPresent(String.self, forKey: .soldAssetIssuer)
        boughtAmount = try values.decode(String.self, forKey: .boughtAmount)
        boughtAssetType = try values.decode(String.self, forKey: .soldAssetType)
        boughtAssetCode = try values.decodeIfPresent(String.self, forKey: .soldAssetCode)
        boughtAssetIssuer = try values.decodeIfPresent(String.self, forKey: .soldAssetIssuer)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seller, forKey: .seller)
        try container.encode(offerId, forKey: .offerId)
        try container.encode(soldAmount, forKey: .soldAmount)
        try container.encode(soldAssetType, forKey: .soldAssetType)
        try container.encode(soldAssetCode, forKey: .soldAssetCode)
        try container.encode(soldAssetIssuer, forKey: .soldAssetIssuer)
        try container.encode(boughtAmount, forKey: .boughtAmount)
        try container.encode(boughtAssetType, forKey: .boughtAssetType)
        try container.encode(boughtAssetCode, forKey: .boughtAssetCode)
        try container.encode(boughtAssetIssuer, forKey: .boughtAssetIssuer)
    }
}
