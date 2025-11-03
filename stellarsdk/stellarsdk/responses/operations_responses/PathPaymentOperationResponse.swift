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
    
    /// Amount received.
    public var amount:String
    
    /// Amount sent.
    public var sourceAmount:String
    
    /// Sender of a payment.
    public var from:String
    public var fromMuxed:String?
    public var fromMuxedId:String?
    
    /// Destination of a payment.
    public var to:String
    public var toMuxed:String?
    public var toMuxedId:String?
    
    /// Destination asset type (native / alphanum4 / alphanum12)
    public var assetType:String
    
    /// Code of the destination asset.
    public var assetCode:String?
    
    /// Destination asset issuer.
    public var assetIssuer:String?
    
    /// Source asset type (native / alphanum4 / alphanum12).
    public var sourceAssetType:String?
    
    /// Code of the source asset.
    public var sourceAssetCode:String?
    
    /// Source asset issuer.
    public var sourceAssetIssuer:String?
    
    /// Additional hops the operation went through to get to the destination asset.
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
