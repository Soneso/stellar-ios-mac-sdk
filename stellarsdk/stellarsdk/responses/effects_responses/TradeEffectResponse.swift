//
//  TradeEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Represents a trade effect.
/// This effect occurs when a trade is executed on the Stellar decentralized exchange (DEX).
/// Triggered when offers are matched through Manage Sell Offer, Manage Buy Offer, or Path Payment operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TradeEffectResponse: EffectResponse, @unchecked Sendable {

    /// The account ID of the seller in the trade.
    public let seller:String

    /// The multiplexed account address if the seller is a muxed account.
    public let sellerMuxed:String?

    /// The multiplexed account ID if the seller is a muxed account.
    public let sellerMuxedId:String?

    /// The ID of the offer that was matched.
    public let offerId:String

    /// The amount of the asset sold.
    public let soldAmount:String

    /// The type of the sold asset (e.g., native, credit_alphanum4, credit_alphanum12).
    public let soldAssetType:String

    /// The code of the sold asset. Nil for native assets.
    public let soldAssetCode:String?

    /// The issuer account ID of the sold asset. Nil for native assets.
    public let soldAssetIssuer:String?

    /// The amount of the asset bought.
    public let boughtAmount:String

    /// The type of the bought asset (e.g., native, credit_alphanum4, credit_alphanum12).
    public let boughtAssetType:String

    /// The code of the bought asset. Nil for native assets.
    public let boughtAssetCode:String?

    /// The issuer account ID of the bought asset. Nil for native assets.
    public let boughtAssetIssuer:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case seller
        case sellerMuxed = "seller_muxed"
        case sellerMuxedId = "seller_muxed_id"
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
        sellerMuxed = try values.decodeIfPresent(String.self, forKey: .sellerMuxed)
        sellerMuxedId = try values.decodeIfPresent(String.self, forKey: .sellerMuxedId)
        offerId = try values.decode(String.self, forKey: .offerId)
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
