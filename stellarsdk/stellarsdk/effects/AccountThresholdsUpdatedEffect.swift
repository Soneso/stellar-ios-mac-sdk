//
//  AccountThresholdsUpdatedEffect.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

public class AccountThresholdsUpdatedEffect: Effect {
    public var lowThreshold:Int
    public var medThreshold:Int
    public var highThreshold:Int
    
    private enum CodingKeys: String, CodingKey {
        case lowThreshold = "low_threshold"
        case medThreshold = "med_threshold"
        case highThreshold = "high_threshold"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lowThreshold = try values.decode(Int.self, forKey: .lowThreshold)
        medThreshold = try values.decode(Int.self, forKey: .medThreshold)
        highThreshold = try values.decode(Int.self, forKey: .highThreshold)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowThreshold, forKey: .lowThreshold)
        try container.encode(medThreshold, forKey: .medThreshold)
        try container.encode(highThreshold, forKey: .highThreshold)
    }
}

