//
//  GetLedgersResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 05.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Response for the getLedgers request
/// See: [Stellar developer docs](https://developers.stellar.org)
public struct GetLedgersResponse: Decodable, Sendable {

    /// Array of ledger information
    public let ledgers: [LedgerInfo]

    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public let latestLedger: UInt32

    /// The unix timestamp of the close time of the latest ledger known to Soroban RPC at the time it handled the request.
    public let latestLedgerCloseTime: Int64

    /// The sequence number of the oldest ledger ingested by Soroban RPC at the time it handled the request.
    public let oldestLedger: UInt32

    /// The unix timestamp of the close time of the oldest ledger ingested by Soroban RPC at the time it handled the request.
    public let oldestLedgerCloseTime: Int64

    /// A cursor value for use in pagination
    public let cursor: String

    private enum CodingKeys: String, CodingKey {
        case ledgers
        case latestLedger
        case latestLedgerCloseTime
        case oldestLedger
        case oldestLedgerCloseTime
        case cursor
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let ledgersArray = try? values.decode([LedgerInfo].self, forKey: .ledgers) {
            ledgers = ledgersArray
        } else {
            ledgers = []
        }

        latestLedger = try values.decode(UInt32.self, forKey: .latestLedger)
        latestLedgerCloseTime = try values.decode(Int64.self, forKey: .latestLedgerCloseTime)
        oldestLedger = try values.decode(UInt32.self, forKey: .oldestLedger)
        oldestLedgerCloseTime = try values.decode(Int64.self, forKey: .oldestLedgerCloseTime)
        cursor = try values.decode(String.self, forKey: .cursor)
    }
}
