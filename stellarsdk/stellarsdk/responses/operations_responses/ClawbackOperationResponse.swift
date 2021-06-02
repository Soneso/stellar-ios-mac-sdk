//
//  ClawbackOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class ClawbackOperationResponse: OperationResponse {
    
    public var amount:String
    public var from:String
    public var fromMuxed:String?
    public var fromMuxedId:Int?
    public var assetType:String
    public var assetCode:String?
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
        fromMuxedId = try values.decodeIfPresent(Int.self, forKey: .fromMuxedId)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        try super.init(from: decoder)
    }
}
