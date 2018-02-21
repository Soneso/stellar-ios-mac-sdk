//
//  TrustlineEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

///  Represents an account trustline effect response. Superclass for trustline created, updated, removed, authorized and deauthorized effects.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
///  See [Stellar guides](https://www.stellar.org/developers/guides/concepts/assets.html#trustlines "Trustlines")
public class TrustlineEffectResponse: EffectResponse {
    
    /// The limit for which the account trusts the issuing account.
    public var limit:String
    
    /// The asset type of the asset refered by the trustline. E.g. native
    public var assetType:String
    
    /// The asset code of the asset refered by the trustline. E.g. BTC, nil if native
    public var assetCode:String?
    
    /// The issuer of the asset used by the trustline. Nil if asset type is "native"
    public var assetIssuer:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case limit
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
        limit = try values.decode(String.self, forKey: .limit)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        
        try super.init(from: decoder)
    }
}
