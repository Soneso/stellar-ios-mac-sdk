//
//  GetLedgerEntriesResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation


/// Response for the getLedgerEntry request
/// See: https://soroban.stellar.org/api/methods/getLedgerEntry
///
public class GetLedgerEntriesResponse: NSObject, Decodable {
    
    /// Hash of the latest ledger as a hex-encoded string
    public var entries:[LedgerEntry]
    
    /// The current latest ledger observed by the node when this response was generated.
    public var latestLedger:Int
    
    private enum CodingKeys: String, CodingKey {
        case entries
        case latestLedger
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        entries = try values.decode([LedgerEntry].self, forKey: .entries)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
    }
}
