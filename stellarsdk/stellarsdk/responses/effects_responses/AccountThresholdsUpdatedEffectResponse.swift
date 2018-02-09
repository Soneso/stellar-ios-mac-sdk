//
//  AccountThresholdsUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account thresholds updated effect response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
///  See [Stellar guides](https://www.stellar.org/developers/guides/concepts/multi-sig.html#thresholds "Account Thresholds")
public class AccountThresholdsUpdatedEffectResponse: EffectResponse {
    
    /// The value of the low threshold for the account.
    public var lowThreshold:Int
    
    /// The value of the medium threshold for the account.
    public var medThreshold:Int
    
    /// The value of the medium threshold for the account.
    public var highThreshold:Int
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case lowThreshold = "low_threshold"
        case medThreshold = "med_threshold"
        case highThreshold = "high_threshold"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lowThreshold = try values.decode(Int.self, forKey: .lowThreshold)
        medThreshold = try values.decode(Int.self, forKey: .medThreshold)
        highThreshold = try values.decode(Int.self, forKey: .highThreshold)
        try super.init(from: decoder)
    }
}

