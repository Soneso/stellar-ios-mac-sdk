//
//  SignerEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an account signer (create,update,remove) effect response. Superclass for signer created, signer updated and signer removed effetcs.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
///  See [Stellar guides](https://www.stellar.org/developers/guides/concepts/accounts.html#signers "Account Signer")
public class SignerEffectResponse: EffectResponse {
    
    /// Public key of the signer.
    public var publicKey:String
    
    /// Weight of the signers public key.
    public var weight:Int
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        publicKey = try values.decode(String.self, forKey: .publicKey)
        weight = try values.decode(Int.self, forKey: .weight)
        
        try super.init(from: decoder)
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
     */
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(publicKey, forKey: .publicKey)
        try container.encode(weight, forKey: .weight)
    }
}
