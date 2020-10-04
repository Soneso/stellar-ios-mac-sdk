//
//  SignerSponsorshipUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class SignerSponsorshipUpdatedEffectResponse: EffectResponse {
    
    // signer being sponsored
    public var signer:String
    
    // new sponsor of the signer
    public var newSponsor:String
    
    //  former sponsor of the signer
    public var formerSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case signer
        case newSponsor = "new_sponsor"
        case formerSponsor = "former_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signer = try values.decode(String.self, forKey: .signer)
        newSponsor = try values.decode(String.self, forKey: .newSponsor)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        try super.init(from: decoder)
    }
}
