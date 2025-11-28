//
//  TrustlineEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Base class for trustline effect responses.
/// Represents changes to account trustlines, which enable accounts to hold and trade non-native assets.
/// Trustlines are established through Change Trust operations and can be authorized or modified by asset issuers.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineEffectResponse: EffectResponse, @unchecked Sendable {

    /// The maximum amount of the asset that the account is willing to hold.
    public let limit:String

    /// The asset type referenced by the trustline.
    public let assetType:String

    /// The asset code referenced by the trustline. Nil for native assets.
    public let assetCode:String?

    /// The issuer account ID of the asset. Nil for native assets.
    public let assetIssuer:String?

    /// The account establishing the trustline.
    public let trustor:String?

    /// Liquidity pool ID if the asset type is liquidity_pool_shares.
    public let liquidityPoolId:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case limit
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case trustor
        case liquidityPoolId = "liquidity_pool_id"
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
        trustor = try values.decodeIfPresent(String.self, forKey: .trustor)
        liquidityPoolId = try values.decodeIfPresent(String.self, forKey: .liquidityPoolId)
        
        try super.init(from: decoder)
    }
}
