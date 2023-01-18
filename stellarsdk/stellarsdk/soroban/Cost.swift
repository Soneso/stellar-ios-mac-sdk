//
//  Cost.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Information about the fees expected, instructions used, etc.
public class Cost: NSObject, Decodable {
    
    /// Stringified-number of the total cpu instructions consumed by this transaction
    public var cpuInsns:String
    
    /// Stringified-number of the total memory bytes allocated by this transaction
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
