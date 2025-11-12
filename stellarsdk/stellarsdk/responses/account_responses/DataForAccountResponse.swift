//
//  DataForAccountResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a single data entry value from an account's key-value data store.
///
/// Accounts can store arbitrary key-value pairs (up to 64 bytes per value). This response
/// contains the value for a specific key requested via the Horizon API. Values are base64 encoded.
///
/// Data entries are used for storing metadata like:
/// - Domain verification proofs
/// - Off-chain data references
/// - Application-specific configuration
///
/// See also:
/// - [Data Entry Endpoint](https://developers.stellar.org/api/horizon/reference/endpoints/data-for-account)
/// - [Manage Data Operation](https://developers.stellar.org/docs/learn/fundamentals/transactions/list-of-operations#manage-data)
/// - AccountResponse for the complete account data dictionary
public class DataForAccountResponse: NSObject, Decodable {

    /// Base64-encoded value for the requested key. Decode to access the raw bytes.
    public var value:String

    /// Account ID sponsoring this data entry's base reserve. Nil if not sponsored.
    public var sponsor:String?
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case value
        case sponsor
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decode(String.self, forKey: .value)
        sponsor = try values.decodeIfPresent(String.self, forKey: .sponsor)
    }
}
