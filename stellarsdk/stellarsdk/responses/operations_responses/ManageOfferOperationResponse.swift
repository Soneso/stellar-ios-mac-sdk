//
//  ManageOfferOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a manage offer operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#manage-offer "Manage offer Operation")
public class ManageOfferOperationResponse: OperationResponse {
    
    /// Offer ID.
    public var offerId:Int
    
    /// Amount of asset to be sold.
    public var amount:String
    
    /// Price to buy a buying asset.
    public var price:String
    
    /// Type of asset to buy (native / alphanum4 / alphanum12)
    public var buyingAssetType:String
    
    /// The code of asset to buy.
    public var buyingAssetCode:String?
    
    /// The issuer of asset to buy.
    public var buyingAssetIssuer:String?
    
    /// Type of asset to sell (native / alphanum4 / alphanum12)
    public var sellingAssetType:String
    
    /// The code of asset to sell.
    public var sellingAssetCode:String?
    
    /// The issuer of asset to sell.
    public var sellingAssetIssuer:String?
    
    // Properties to encode and decode
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
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        offerId = try values.decode(Int.self, forKey: .offerId)
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
}
