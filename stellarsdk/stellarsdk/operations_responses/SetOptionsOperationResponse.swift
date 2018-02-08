//
//  SetOptionsOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class SetOptionsOperationResponse: OperationResponse {
    
    public var lowThreshold:Int!
    public var medThreshold:Int!
    public var highThreshold:Int!
    public var inflationDestination:String!
    public var homeDomain:String!
    public var signerKey:String!
    public var signerWeight:Int!
    public var masterKeyWeight:Int!
    public var clearFlags:AccountFlagsResponse!
    public var setFlags:AccountFlagsResponse!
    
    
    private enum CodingKeys: String, CodingKey {
        case lowThreshold = "low_threshold"
        case medThreshold = "med_threshold"
        case highThreshold = "high_threshold"
        case inflationDestination = "inflation_dest"
        case homeDomain = "home_domain"
        case signerKey = "signer_key"
        case signerWeight = "signer_weight"
        case masterKeyWeight = "master_key_weight"
        case clearFlags = "clear_flags_s"
        case setFlags = "set_flags_s"
        
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lowThreshold = try values.decodeIfPresent(Int.self, forKey: .lowThreshold)
        medThreshold = try values.decodeIfPresent(Int.self, forKey: .medThreshold)
        highThreshold = try values.decodeIfPresent(Int.self, forKey: .highThreshold)
        inflationDestination = try values.decodeIfPresent(String.self, forKey: .inflationDestination)
        homeDomain = try values.decodeIfPresent(String.self, forKey: .homeDomain)
        signerKey = try values.decodeIfPresent(String.self, forKey: .signerKey)
        signerWeight = try values.decodeIfPresent(Int.self, forKey: .signerWeight)
        masterKeyWeight = try values.decodeIfPresent(Int.self, forKey: .masterKeyWeight)
        clearFlags = try values.decodeIfPresent(AccountFlagsResponse.self, forKey: .clearFlags)
        setFlags = try values.decodeIfPresent(AccountFlagsResponse.self, forKey: .setFlags)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowThreshold, forKey: .lowThreshold)
        try container.encode(medThreshold, forKey: .medThreshold)
        try container.encode(highThreshold, forKey: .highThreshold)
        try container.encode(inflationDestination, forKey: .inflationDestination)
        try container.encode(homeDomain, forKey: .homeDomain)
        try container.encode(signerKey, forKey: .signerKey)
        try container.encode(signerWeight, forKey: .signerWeight)
        try container.encode(clearFlags, forKey: .clearFlags)
        try container.encode(setFlags, forKey: .setFlags)
        
    }
}
