//
//  SequenceBumpedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a sequence number bump effect.
/// This effect occurs when an account's sequence number is manually bumped to a higher value.
/// Triggered by the Bump Sequence operation, which can be used to invalidate future transactions or implement time bounds.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SequenceBumpedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The new sequence number after the bump.
    public let newSequence:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case newSequence = "new_seq"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        newSequence = try values.decode(String.self, forKey: .newSequence)
        
        try super.init(from: decoder)
    }
    
}
