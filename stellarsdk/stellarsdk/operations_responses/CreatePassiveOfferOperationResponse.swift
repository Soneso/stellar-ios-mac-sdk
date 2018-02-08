//
//  CreatePassiveOfferOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class CreatePassiveOfferOperationResponse: OperationResponse {
    
    public var offerId:String
    public var amount:String
    public var price:String
    public var buyingAssetType:String
    public var buyingAssetCode:String!
    public var buyingAssetIssuer:String!
    public var sellingAssetType:String
    public var sellingAssetCode:String!
    public var sellingAssetIssuer:String!
    
    
    private enum CodingKeys: String, CodingKey {
        case offerId = "offer_id"
        case amount
        case price
        case buyingAssetType = "buying_asset_type"
        case buyingAssetCode = "buying_asset_code"
        case buyingAssetIssuer = "buying_asset_issuer"
        case sellingAssetType = "selling_asset_type"
        case sellingAssetCode = "selling_asset_code"
        case sellingAssetIssuer = "selling_asset_issuer"
        
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        offerId = try values.decode(String.self, forKey: .offerId)
        amount = try values.decode(String.self, forKey: .amount)
        price = try values.decode(String.self, forKey: .price)
        buyingAssetType = try values.decode(String.self, forKey: .buyingAssetType)
        buyingAssetCode = try values.decodeIfPresent(String.self, forKey: .buyingAssetCode)
        buyingAssetIssuer = try values.decodeIfPresent(String.self, forKey: .buyingAssetIssuer)
        sellingAssetType = try values.decode(String.self, forKey: .sellingAssetType)
        sellingAssetCode = try values.decodeIfPresent(String.self, forKey: .sellingAssetCode)
        sellingAssetIssuer = try values.decodeIfPresent(String.self, forKey: .sellingAssetIssuer)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(offerId, forKey: .offerId)
        try container.encode(amount, forKey: .amount)
        try container.encode(price, forKey: .price)
        try container.encode(buyingAssetType, forKey: .buyingAssetType)
        try container.encode(buyingAssetCode, forKey: .buyingAssetCode)
        try container.encode(buyingAssetIssuer, forKey: .buyingAssetIssuer)
        try container.encode(sellingAssetType, forKey: .sellingAssetType)
        try container.encode(sellingAssetCode, forKey: .sellingAssetCode)
        try container.encode(sellingAssetIssuer, forKey: .sellingAssetIssuer)
        
    }
}

