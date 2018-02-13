//
//  OfferAssetResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents the offer asset(selling/buying) attribute.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/offer.html "Offer Asset")
public class OfferAssetResponse: NSObject, Decodable {
    
    /// The asset type. Possible values: native, credit_alphanum4, credit_alphanum12
    /// See also Constants.AssetType
    public var assetType:String
    
    /// The asset code e.g., USD or BTC.
    public var assetCode:String?
    
    /// The account id of the account that created the asset.
    public var assetIssuer:String?
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
    }
}
