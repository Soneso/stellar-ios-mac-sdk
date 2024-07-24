//
//  SubmitTransactionAsyncResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

import Foundation

/// See: https://developers.stellar.org/docs/data/horizon/api-reference/submit-async-transaction
public class SubmitTransactionAsyncResponse: NSObject, Decodable {
    
    public var txStatus:String // Possible values: [ERROR, PENDING, DUPLICATE, TRY_AGAIN_LATER]
    public var txHash:String
    public var errorResultXdr:String?
    
    private enum CodingKeys: String, CodingKey {
        case txStatus = "tx_status"
        case txHash = "hash"
        case errorResultXdr = "errorResultXdr"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        txStatus = try values.decode(String.self, forKey: .txStatus)
        txHash = try values.decode(String.self, forKey: .txHash)
        errorResultXdr = try values.decodeIfPresent(String.self, forKey: .errorResultXdr)
    }
}
