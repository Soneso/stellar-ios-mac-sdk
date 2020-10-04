//
//  ClaimableBalanceLinksResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class ClaimableBalanceLinksResponse: NSObject, Decodable {
    
    /// Link to the current ledger request URL of this ledger.
    public var selflink:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
    }
}
