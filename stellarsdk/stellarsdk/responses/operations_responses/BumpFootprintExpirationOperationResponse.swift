//
//  BumpFootprintExpirationOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class BumpFootprintExpirationOperationResponse: OperationResponse {
    
    public var ledgersToExpire:Int

    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case ledgersToExpire = "ledgers_to_expire"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ledgersToExpire = try values.decode(Int.self, forKey: .ledgersToExpire)
        try super.init(from: decoder)
    }
}
