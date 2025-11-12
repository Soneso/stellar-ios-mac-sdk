//
//  ExtendFootprintTTLOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Represents an extend footprint TTL operation response.
/// This Soroban operation extends the time-to-live (TTL) of ledger entries specified in the transaction's footprint, preventing them from being archived.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#extend-footprint-ttl "Extend Footprint TTL Operation")
public class ExtendFootprintTTLOperationResponse: OperationResponse {

    /// New ledger number at which the entries will expire.
    public var extendTo:Int
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case extendTo = "extend_to"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        extendTo = try values.decode(Int.self, forKey: .extendTo)
        try super.init(from: decoder)
    }
}
