//
//  GetLatestLedgerResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.04.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response for the getLatestLedger request
/// See: https://soroban.stellar.org/api/methods/getLatestLedger
///
public class GetLatestLedgerResponse: NSObject, Decodable {
    
    /// hash of the latest ledger as a hex-encoded string
    public var id:String
    /// Stellar Core protocol version associated with the latest ledger
    public var protocolVersion:Int
    /// sequence number of the latest ledger
    public var sequence:UInt32
    
    private enum CodingKeys: String, CodingKey {
        case id
        case protocolVersion
        case sequence
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        protocolVersion = try values.decode(Int.self, forKey: .protocolVersion)
        sequence = try values.decode(UInt32.self, forKey: .sequence)
    }
}
