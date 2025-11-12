//
//  PathPaymentOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a path payment operation response.
///  See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#path-payment "Path Payment Operation")
public class PathPaymentOperationResponse: OperationResponse {
    
    /// Amount received by the destination.
    public var amount:String

    /// Amount sent from the source.
    public var sourceAmount:String

    /// Account ID of the payment sender.
    public var from:String

    /// Multiplexed account address of the sender (if used).
    public var fromMuxed:String?

    /// ID of the multiplexed sender account (if used).
    public var fromMuxedId:String?

    /// Account ID of the payment recipient.
    public var to:String

    /// Multiplexed account address of the recipient (if used).
    public var toMuxed:String?

    /// ID of the multiplexed recipient account (if used).
    public var toMuxedId:String?

    /// Destination asset type (native / alphanum4 / alphanum12).
    public var assetType:String

    /// Destination asset code.
    public var assetCode:String?

    /// Destination asset issuer.
    public var assetIssuer:String?

    /// Source asset type (native / alphanum4 / alphanum12).
    public var sourceAssetType:String?

    /// Source asset code.
    public var sourceAssetCode:String?

    /// Source asset issuer.
    public var sourceAssetIssuer:String?

    /// Path of asset conversions from source to destination.
    public var path:[OfferAssetResponse]?

    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case sourceAmount = "source_amount"
        case from
        case fromMuxed = "from_muxed"
        case fromMuxedId = "from_muxed_id"
        case to
        case toMuxed = "to_muxed"
        case toMuxedId = "to_muxed_id"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case sourceAssetType = "source_asset_type"
        case sourceAssetCode = "source_asset_code"
        case sourceAssetIssuer = "source_asset_issuer"
        case path = "path"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        sourceAmount = try values.decode(String.self, forKey: .sourceAmount)
        from = try values.decode(String.self, forKey: .from)
        fromMuxed = try values.decodeIfPresent(String.self, forKey: .fromMuxed)
        fromMuxedId = try values.decodeIfPresent(String.self, forKey: .fromMuxedId)
        to = try values.decode(String.self, forKey: .to)
        toMuxed = try values.decodeIfPresent(String.self, forKey: .toMuxed)
        toMuxedId = try values.decodeIfPresent(String.self, forKey: .toMuxedId)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        sourceAssetType = try values.decodeIfPresent(String.self, forKey: .sourceAssetType)
        sourceAssetCode = try values.decodeIfPresent(String.self, forKey: .sourceAssetCode)
        sourceAssetIssuer = try values.decodeIfPresent(String.self, forKey: .sourceAssetIssuer)
        path = try values.decodeIfPresent([OfferAssetResponse].self, forKey: .path)
        
        try super.init(from: decoder)
    }
}
