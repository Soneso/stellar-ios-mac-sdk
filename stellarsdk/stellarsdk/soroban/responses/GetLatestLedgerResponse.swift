//
//  GetLatestLedgerResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.04.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response for the getLatestLedger request
/// See: [Stellar developer docs](https://developers.stellar.org)
///
public struct GetLatestLedgerResponse: Decodable, Sendable {

    /// hash of the latest ledger as a hex-encoded string
    public let id:String
    /// Stellar Core protocol version associated with the latest ledger
    public let protocolVersion:Int
    /// sequence number of the latest ledger
    public let sequence:UInt32

    private enum CodingKeys: String, CodingKey {
        case id
        case protocolVersion
        case sequence
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        protocolVersion = try values.decode(Int.self, forKey: .protocolVersion)
        sequence = try values.decode(UInt32.self, forKey: .sequence)
    }
}
