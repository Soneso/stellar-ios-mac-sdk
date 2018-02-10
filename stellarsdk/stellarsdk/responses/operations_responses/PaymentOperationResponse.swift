//
//  PaymentOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a payment operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#payment "Payment Operation")
public class PaymentOperationResponse: OperationResponse {
    
    /// Amount sent.
    public var amount:String
    
    /// Asset type (native / alphanum4 / alphanum12)
    public var assetType:String
    
    /// Code of the destination asset.
    public var assetCode:String?
    
    /// Asset issuer.
    public var assetIssuer:String?
    
    /// Sender of a payment.
    public var from:String
    
    /// Destination of a payment.
    public var to:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case from
        case to
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
        to = try values.decode(String.self, forKey: .to)
        
        try super.init(from: decoder)
    }
}

