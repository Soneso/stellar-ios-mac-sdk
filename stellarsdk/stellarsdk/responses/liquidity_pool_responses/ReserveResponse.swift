//
//  ReserveResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class ReserveResponse: NSObject, Decodable {
    
    public var amount:String
    public var asset:Asset
   
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case asset = "asset"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        let canonicalAsset = try values.decode(String.self, forKey: .asset)
        if let a = Asset(canonicalForm: canonicalAsset) {
            asset = a
        } else {
            throw StellarSDKError.decodingError(message: "not a valid asset in horizon response")
        }
    }
}
