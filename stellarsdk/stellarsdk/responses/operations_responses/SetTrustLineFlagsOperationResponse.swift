//
//  SetTrustLineFlagsOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class SetTrustLineFlagsOperationResponse: OperationResponse {
    
    public var trustor:String
    public var assetType:String
    public var assetCode:String?
    public var assetIssuer:String?
    public var setFlags:[Int]?
    public var setFlagsS:[String]?
    public var clearFlags:[Int]?
    public var clearFlagsS:[String]?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case trustor
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case setFlags = "set_flags"
        case setFlagsS = "set_flags_s"
        case clearFlags = "clear_flags"
        case clearFlagsS = "clear_flags_s"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trustor = try values.decode(String.self, forKey: .trustor)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        setFlags = try values.decodeIfPresent(Array.self, forKey: .setFlags)
        setFlagsS = try values.decodeIfPresent(Array.self, forKey: .setFlagsS)
        clearFlags = try values.decodeIfPresent(Array.self, forKey: .clearFlags)
        clearFlagsS = try values.decodeIfPresent(Array.self, forKey: .clearFlagsS)
        try super.init(from: decoder)
    }
}
