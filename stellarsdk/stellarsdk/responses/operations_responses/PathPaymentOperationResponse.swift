//
//  PathPaymentOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a path payment operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#path-payment "Path Payment Operation")
public class PathPaymentOperationResponse: OperationResponse {
    
    /// Amount received.
    public var amount:String
    
    /// Amount sent.
    public var sourceAmount:String
    
    /// Sender of a payment.
    public var from:String
    
    /// Destination of a payment.
    public var to:String
    
    /// Destination asset type (native / alphanum4 / alphanum12)
    public var assetType:String
    
    /// Code of the destination asset.
    public var assetCode:String?
    
    /// Destination asset issuer.
    public var assetIssuer:String?
    
    /// Source asset type (native / alphanum4 / alphanum12).
    public var sendAssetType:String
    
    /// Code of the source asset.
    public var sendAssetCode:String?
    
    /// Source asset issuer.
    public var sendAssetIssuer:String?

    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case sourceAmount = "source_amount"
        case from
        case to
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case sendAssetType = "send_asset_type"
        case sendAssetCode = "send_asset_code"
        case sendAssetIssuer = "send_asset_issuer"

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
        to = try values.decode(String.self, forKey: .to)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        sendAssetType = try values.decode(String.self, forKey: .sendAssetType)
        sendAssetCode = try values.decodeIfPresent(String.self, forKey: .sendAssetCode)
        sendAssetIssuer = try values.decodeIfPresent(String.self, forKey: .sendAssetIssuer)
        
        try super.init(from: decoder)
    }
}
