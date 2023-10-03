//
//  ContractDebitedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class ContractDebitedEffectResponse: EffectResponse {
    
    public var contract:String
    public var amount:String
    public var assetType:String
    public var assetCode:String?
    public var assetIssuer:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case contract
        case amount
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
        contract = try values.decode(String.self, forKey: .contract)
        amount = try values.decode(String.self, forKey: .amount)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        try super.init(from: decoder)
    }
}
