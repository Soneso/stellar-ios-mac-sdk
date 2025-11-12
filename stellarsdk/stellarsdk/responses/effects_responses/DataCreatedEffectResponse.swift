//
//  DataCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a data entry creation effect.
/// This effect occurs when a new key-value pair is added to an account's data entries.
/// Account data entries allow accounts to store arbitrary data on the ledger.
/// Triggered by the Manage Data operation.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/operations-and-transactions#manage-data "Manage Data")
public class DataCreatedEffectResponse: EffectResponse {

    /// The name (key) of the data entry created.
    public var name:String

    /// The base64-encoded value of the data entry created.
    public var value:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case name
        case value
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        value = try values.decode(String.self, forKey: .value)
        try super.init(from: decoder)
    }
}
