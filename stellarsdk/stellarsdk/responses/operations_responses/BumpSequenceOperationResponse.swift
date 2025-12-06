//
//  BumpSequenceOperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a bump sequence operation response.
/// This operation bumps forward the sequence number of the source account to the specified value, invalidating any lower sequence numbers for future transactions.
/// See [Stellar developer docs](https://developers.stellar.org)
public class BumpSequenceOperationResponse: OperationResponse, @unchecked Sendable {

    /// Value to bump the sequence to.
    public let bumpTo:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case bumpTo = "bump_to"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bumpTo = try values.decode(String.self, forKey: .bumpTo)
        
        try super.init(from: decoder)
    }
    
}
