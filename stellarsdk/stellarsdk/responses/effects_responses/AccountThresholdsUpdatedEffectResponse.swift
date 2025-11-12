//
//  AccountThresholdsUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account thresholds update effect.
/// This effect occurs when an account's signature thresholds are modified through a Set Options operation.
/// Thresholds determine the minimum signature weight required for different operation categories.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/security/signatures-multisig#thresholds "Account Thresholds")
public class AccountThresholdsUpdatedEffectResponse: EffectResponse {

    /// The updated low threshold value (used for Allow Trust and Bump Sequence operations).
    public var lowThreshold:Int

    /// The updated medium threshold value (used for most operations).
    public var medThreshold:Int

    /// The updated high threshold value (used for Set Options and Account Merge operations).
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

