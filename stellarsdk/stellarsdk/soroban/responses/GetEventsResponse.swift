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
    /// The ledger number of the last time this entry was updated (optional)
    public var latestLedger:Int
    
    private enum CodingKeys: String, CodingKey {
        case events
        case latestLedger
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        events = try values.decode([EventInfo].self, forKey: .events)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
    }
}
