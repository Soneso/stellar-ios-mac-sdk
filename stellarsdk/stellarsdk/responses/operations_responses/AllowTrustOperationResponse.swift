//
//  AllowTrustOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an allow trust operation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class AllowTrustOperationResponse: OperationResponse {
    
    /// Account ID of the trustor (the account trusting the asset).
    public var trustor:String

    /// Account ID of the trustee (the asset issuer).
    public var trustee:String

    /// Multiplexed account address of the trustee (if used).
    public var trusteeMuxed:String?

    /// ID of the multiplexed trustee account (if used).
    public var trusteeMuxedId:String?

    /// Asset type (native / alphanum4 / alphanum12).
    public var assetType:String

    /// Asset code being authorized.
    public var assetCode:String?

    /// Asset issuer (the trustee).
    public var assetIssuer:String?

    /// True when allowing trust, false when revoking trust.
    public var authorize:Bool

    /// True when authorizing the trustline to maintain liabilities.
    public var authorizeToMaintainLiabilities:Bool?
    
    /// The limit for the asset.
    private enum CodingKeys: String, CodingKey {
        case trustor
        case trustee
        case trusteeMuxed = "trustee_muxed"
        case trusteeMuxedId = "trustee_muxed_id"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case authorize
        case authorizeToMaintainLiabilities = "authorize_to_maintain_liabilities"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trustor = try values.decode(String.self, forKey: .trustor)
        trustee = try values.decode(String.self, forKey: .trustee)
        trusteeMuxed = try values.decodeIfPresent(String.self, forKey: .trusteeMuxed)
        trusteeMuxedId = try values.decodeIfPresent(String.self, forKey: .trusteeMuxedId)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        authorize = try values.decode(Bool.self, forKey: .authorize)
        authorizeToMaintainLiabilities = try values.decodeIfPresent(Bool.self, forKey: .authorizeToMaintainLiabilities)
        
        try super.init(from: decoder)
    }
}
