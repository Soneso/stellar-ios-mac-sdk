//
//  AccountHomeDomainUpdatedEffect.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

public class AccountHomeDomainUpdatedEffect: Effect {
    public var homeDomain:String
    
    private enum CodingKeys: String, CodingKey {
        case homeDomain = "home_domain"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        homeDomain = try values.decode(String.self, forKey: .homeDomain)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(homeDomain, forKey: .homeDomain)
    }
}

