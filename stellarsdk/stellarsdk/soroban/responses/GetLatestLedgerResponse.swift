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
    /// The unix timestamp of when the latest ledger was closed. Available since RPC v25.0.0.
    public let closeTime:String?
    /// Base64-encoded LedgerHeader XDR. Available since RPC v25.0.0.
    public let headerXdr:String?
    /// Base64-encoded LedgerCloseMeta XDR containing ledger close metadata. Available since RPC v25.0.0.
    public let metadataXdr:String?

    private enum CodingKeys: String, CodingKey {
        case id
        case protocolVersion
        case sequence
        case closeTime
        case headerXdr
        case metadataXdr
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        protocolVersion = try values.decode(Int.self, forKey: .protocolVersion)
        sequence = try values.decode(UInt32.self, forKey: .sequence)
        closeTime = try values.decodeIfPresent(String.self, forKey: .closeTime)
        headerXdr = try values.decodeIfPresent(String.self, forKey: .headerXdr)
        metadataXdr = try values.decodeIfPresent(String.self, forKey: .metadataXdr)
    }
}
