//
//  LedgerInfo.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 05.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Represents a single ledger in the getLedgers response.
/// See: [Stellar developer docs](https://developers.stellar.org)
public struct LedgerInfo: Decodable, Sendable {

    /// Hash of the ledger as a hex-encoded string
    public let ledgerHash: String

    /// Sequence number of the ledger
    public let sequence: UInt32

    /// The unix timestamp of the close time of the ledger
    public let ledgerCloseTime: String

    /// Base64-encoded ledger header XDR
    public let headerXdr: String?

    /// Base64-encoded ledger metadata XDR
    public let metadataXdr: String?

    private enum CodingKeys: String, CodingKey {
        case ledgerHash = "hash"
        case sequence
        case ledgerCloseTime
        case headerXdr
        case metadataXdr
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ledgerHash = try values.decode(String.self, forKey: .ledgerHash)
        sequence = try values.decode(UInt32.self, forKey: .sequence)
        ledgerCloseTime = try values.decode(String.self, forKey: .ledgerCloseTime)
        headerXdr = try values.decodeIfPresent(String.self, forKey: .headerXdr)
        metadataXdr = try values.decodeIfPresent(String.self, forKey: .metadataXdr)
    }
}
