//
//  AllowTrustOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an allow trust operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#allow-trust "Allow Trust Operation")
public class AllowTrustOperationResponse: OperationResponse {
    
    /// Trustor account.
    public var trustor:String
    
    /// Trustee account.
    public var trustee:String
    
    /// Asset type (native / alphanum4 / alphanum12)
    public var assetType:String
    
    /// Asset code.
    public var assetCode:String?
    
    /// Asset issuer.
    public var assetIssuer:String?
    
    /// true when allowing trust, false when revoking trust.
    public var authorize:Bool
    
    /// The limit for the asset.
    private enum CodingKeys: String, CodingKey {
        case trustor
        case trustee
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case authorize
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trustor = try values.decode(String.self, forKey: .trustor)
        trustee = try values.decode(String.self, forKey: .trustee)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        authorize = try values.decode(Bool.self, forKey: .authorize)
        
        try super.init(from: decoder)
    }
}
