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
    
    public var cursor:String
    
    private enum CodingKeys: String, CodingKey {
        case events
        case latestLedger
        case cursor
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let evs =  try? values.decode([EventInfo].self, forKey: .events) {
            events = evs
        } else {
            events = []
        }
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        cursor = try values.decode(String.self, forKey: .cursor)
    }
}
