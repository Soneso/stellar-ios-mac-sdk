//
//  SignerEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Base class for signer effect responses.
/// Represents changes to account signers, including creation, updates, and removal.
/// Signers allow an account to be controlled by multiple keys with configurable weights.
/// Triggered by the Set Options operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerEffectResponse: EffectResponse, @unchecked Sendable {

    /// Public key of the signer.
    public let publicKey:String

    /// Weight assigned to the signer's public key for transaction authorization.
    public let weight:Int

    /// The signer key in its encoded form.
    public let key: String?

    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
        case key
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        publicKey = try values.decode(String.self, forKey: .publicKey)
        weight = try values.decode(Int.self, forKey: .weight)
        key = try values.decodeIfPresent(String.self, forKey: .key)

        try super.init(from: decoder)
    }
}
