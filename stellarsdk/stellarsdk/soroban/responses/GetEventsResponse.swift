//
//  GetEventsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class GetEventsResponse: NSObject, Decodable {
    
    public var events:[EventInfo]
    
    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public var latestLedger:Int
    
    /// For paging, only avaliable for protocol version >= 22
    public var cursor:String?
    
    /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the request.
    /// Only available for protocol version >= 23
    public var latestLedgerCloseTime:String?
    
    /// The oldest ledger ingested by Soroban-RPC at the time it handled the request.
    /// Only available for protocol version >= 23
    public var oldestLedger:Int?
    
    /// The unix timestamp of the close time of the oldest ledger ingested by Soroban-RPC at the time it handled the request.
    /// Only available for protocol version >= 23
    public var oldestLedgerCloseTime:String?

    private enum CodingKeys: String, CodingKey {
        case events
        case latestLedger
        case cursor
        case latestLedgerCloseTime
        case oldestLedger
        case oldestLedgerCloseTime
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let evs =  try? values.decode([EventInfo].self, forKey: .events) {
            events = evs
        } else {
            events = []
        }
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        cursor = try values.decodeIfPresent(String.self, forKey: .cursor) // protocol version > 22
        latestLedgerCloseTime = try values.decodeIfPresent(String.self, forKey: .latestLedgerCloseTime) // protocol version > 23
        oldestLedger = try values.decodeIfPresent(Int.self, forKey: .oldestLedger) // protocol version > 23
        oldestLedgerCloseTime = try values.decodeIfPresent(String.self, forKey: .oldestLedgerCloseTime) // protocol version > 23
    }
}
