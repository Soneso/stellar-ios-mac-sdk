//
//  PreconditionsLedgerBoundsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

public class PreconditionsLedgerBoundsResponse: NSObject, Decodable {
    
    public var minLedger:Int
    public var maxLedger:Int
    
    private enum CodingKeys: String, CodingKey {
        case minLedger = "min_ledger"
        case maxLedger = "max_ledger"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        minLedger = try values.decode(Int.self, forKey: .minLedger)
        maxLedger = try values.decode(Int.self, forKey: .maxLedger)
    }
}
