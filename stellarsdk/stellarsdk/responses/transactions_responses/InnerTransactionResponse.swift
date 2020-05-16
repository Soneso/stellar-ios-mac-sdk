//
//  InnerTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 16.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class InnerTransactionResponse: NSObject, Decodable {
    
    /// The id of this transaction.
    public var transactionHash:String // hash
    public var signatures:[String]
    public var maxFee:String
    
    private enum CodingKeys: String, CodingKey {
        case transactionHash = "hash"
        case signatures
        case maxFee = "max_fee"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transactionHash = try values.decode(String.self, forKey: .transactionHash)
        signatures = try values.decode([String].self, forKey: .signatures)
        maxFee = try values.decode(String.self, forKey: .maxFee)
    }
}
