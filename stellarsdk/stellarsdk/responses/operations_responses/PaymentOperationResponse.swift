//
//  PaymentOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a payment operation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class PaymentOperationResponse: OperationResponse {
    
    /// Amount of the asset sent.
    public var amount:String

    /// Asset type (native / alphanum4 / alphanum12).
    public var assetType:String

    /// Asset code being sent.
    public var assetCode:String?

    /// Asset issuer.
    public var assetIssuer:String?

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
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case from
        case fromMuxed = "from_muxed"
        case fromMuxedId = "from_muxed_id"
        case to
        case toMuxed = "to_muxed"
        case toMuxedId = "to_muxed_id"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        from = try values.decode(String.self, forKey: .from)
        fromMuxed = try values.decodeIfPresent(String.self, forKey: .fromMuxed)
        fromMuxedId = try values.decodeIfPresent(String.self, forKey: .fromMuxedId)
        to = try values.decode(String.self, forKey: .to)
        toMuxed = try values.decodeIfPresent(String.self, forKey: .toMuxed)
        toMuxedId = try values.decodeIfPresent(String.self, forKey: .toMuxedId)
        try super.init(from: decoder)
    }
}

