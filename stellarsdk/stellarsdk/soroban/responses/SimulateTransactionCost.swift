//
//  SimulateTransactionCost.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// The cost object is legacy, inaccurate, and will be deprecated in future RPC releases. Please decode transactionData XDR to retrieve the correct resources.
public class SimulateTransactionCost: NSObject, Decodable {
    
    /// Stringified number - Total cpu instructions consumed by this transaction
    public var cpuInsns:String
    
    /// Stringified number - Total memory bytes allocated by this transaction
    public var memBytes:String
    
    private enum CodingKeys: String, CodingKey {
        case cpuInsns
        case memBytes
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cpuInsns = try values.decode(String.self, forKey: .cpuInsns)
        memBytes = try values.decode(String.self, forKey: .memBytes)
    }
}
