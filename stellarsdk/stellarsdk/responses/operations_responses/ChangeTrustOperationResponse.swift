//
//  ChangeTrustOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a change trust operation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class ChangeTrustOperationResponse: OperationResponse, @unchecked Sendable {
    
    /// Account ID of the trustor (the account creating or modifying the trustline).
    public let trustor:String

    /// Multiplexed account address of the trustor (if used).
    public let trustorMuxed:String?

    /// ID of the multiplexed trustor account (if used).
    public let trustorMuxedId:String?

    /// Account ID of the trustee (the asset issuer).
    public let trustee:String?

    /// Asset type (native / alphanum4 / alphanum12 / liquidity_pool_shares).
    public let assetType:String

    /// Asset code (if not native or liquidity pool shares).
    public let assetCode:String?

    /// Asset issuer (if not native or liquidity pool shares).
    public let assetIssuer:String?

    /// Trust limit for the asset (if 0, removes the trustline).
    public let limit:String?

    /// Liquidity pool ID (if asset type is liquidity_pool_shares).
    public let liquidityPoolId:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case trustor
        case trustorMuxed = "trustor_muxed"
        case trustorMuxedId = "trustor_muxed_id"
        case trustee
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case limit
        case liquidityPoolId = "liquidity_pool_id"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trustor = try values.decode(String.self, forKey: .trustor)
        trustorMuxed = try values.decodeIfPresent(String.self, forKey: .trustorMuxed)
        trustorMuxedId = try values.decodeIfPresent(String.self, forKey: .trustorMuxedId)
        trustee = try values.decodeIfPresent(String.self, forKey: .trustee)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        limit = try values.decodeIfPresent(String.self, forKey: .limit)
        liquidityPoolId = try values.decodeIfPresent(String.self, forKey: .liquidityPoolId)
        
        try super.init(from: decoder)
    }
}
