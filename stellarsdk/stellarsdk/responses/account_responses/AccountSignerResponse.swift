//
//  AccountSignerResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents the account signer response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html "Account")
///  See [Stellar Guides] (https://www.stellar.org/developers/guides/concepts/accounts.html#signers "Account signers")
///  Currently there are three flags, used by issuers of assets: Authorization required, Authorization revocable and Authorization immutable.
public class AccountSignerResponse: NSObject, Decodable {
    
    /// Public key of the signer / account id.
    public var publicKey:String
    
    /// The signature weight of the public key of the signer.
    public var weight:Int
    
    /// Not sure about this key.
    public var key:String?
    
    /// Type of the key e.g. ed25519_public_key
    public var type:String?
    
     // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
        case key
        case type
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
        type = try values.decodeIfPresent(String.self, forKey: .type)
    }
}
