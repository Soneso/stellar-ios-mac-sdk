//
//  TradeEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

///  Represents a trade effect response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
public class TradeEffectResponse: EffectResponse {
    
    /// The seller in the trade effect.
    public var seller:String
    
    /// The id of the offer that has been traded.
    public var offerId:Int64
    
    /// The ammount of the asset sold.
    public var soldAmount:String
    
    /// The type of the sold asset. E.g. native
    public var soldAssetType:String
    
    /// The code of the sold asset. E.g. BTC. Nil if asset type is native.
    public var soldAssetCode:String?
    
    /// The asset issuer account id of the sold asset. Nil if asset type is native.
    public var soldAssetIssuer:String?
    
    /// The ammount of the asset sold.
    public var boughtAmount:String
    
    /// The type of the bought asset. E.g. native
    public var boughtAssetType:String
    
    /// The code of the bought asset. E.g. BTC. Nil if asset type is native.
    public var boughtAssetCode:String?
    
    /// The asset issuer account id of the bought asset. Nil if asset type is native.
    public var boughtAssetIssuer:String?
    
    // Properties to encode and decode
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
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        seller = try values.decode(String.self, forKey: .seller)
        offerId = try values.decode(Int64.self, forKey: .offerId)
        soldAmount = try values.decode(String.self, forKey: .soldAmount)
        soldAssetType = try values.decode(String.self, forKey: .soldAssetType)
        soldAssetCode = try values.decodeIfPresent(String.self, forKey: .soldAssetCode)
        soldAssetIssuer = try values.decodeIfPresent(String.self, forKey: .soldAssetIssuer)
        boughtAmount = try values.decode(String.self, forKey: .boughtAmount)
        boughtAssetType = try values.decode(String.self, forKey: .boughtAssetType)
        boughtAssetCode = try values.decodeIfPresent(String.self, forKey: .boughtAssetCode)
        boughtAssetIssuer = try values.decodeIfPresent(String.self, forKey: .boughtAssetIssuer)
        
        try super.init(from: decoder)
    }
}
