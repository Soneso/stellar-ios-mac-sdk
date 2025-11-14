//
//  ClawbackOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a clawback operation response.
/// This operation burns an amount of an asset from a holding account. The asset issuer must have the AUTH_CLAWBACK_ENABLED flag set on the asset.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClawbackOperationResponse: OperationResponse {

    /// Amount of the asset clawed back.
    public var amount:String

    /// Account ID from which the asset was clawed back.
    public var from:String

    /// Multiplexed account address (if used).
    public var fromMuxed:String?

    /// ID of the multiplexed account (if used).
    public var fromMuxedId:String?

    /// Asset type (native / alphanum4 / alphanum12).
    public var assetType:String

    /// Asset code being clawed back.
    public var assetCode:String?

    /// Asset issuer performing the clawback.
    public var assetIssuer:String?

    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case from
        case fromMuxed = "from_muxed"
        case fromMuxedId = "from_muxed_id"
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
        amount = try values.decode(String.self, forKey: .amount)
        from = try values.decode(String.self, forKey: .from)
        fromMuxed = try values.decodeIfPresent(String.self, forKey: .fromMuxed)
        fromMuxedId = try values.decodeIfPresent(String.self, forKey: .fromMuxedId)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        try super.init(from: decoder)
    }
}
