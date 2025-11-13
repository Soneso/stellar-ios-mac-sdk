//
//  AccountSignerResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account signer with its key, type, and signing weight.
///
/// Stellar accounts can have multiple signers for implementing multi-signature authorization.
/// Each signer has a weight that contributes to meeting operation threshold requirements.
///
/// Common signer types:
/// - ed25519_public_key: Standard Stellar account public key
/// - sha256_hash: Hash of a preimage (for hash-locked transactions)
/// - preauth_tx: Hash of a pre-authorized transaction
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountThresholdsResponse for threshold requirements
public class AccountSignerResponse: NSObject, Decodable {

    /// Signature weight of this signer. Range: 0-255. Combined with other signers to meet thresholds.
    public var weight:Int

    /// Signer key, format depends on the type (public key, hash, or preauth transaction hash).
    public var key:String

    /// Type of signer key: "ed25519_public_key", "sha256_hash", or "preauth_tx".
    public var type:String

    /// Account ID sponsoring this signer's base reserve. Nil if not sponsored.
    public var sponsor:String?
    
     // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case weight
        case key
        case type
        case sponsor
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        weight = try values.decode(Int.self, forKey: .weight)
        key = try values.decode(String.self, forKey: .key)
        type = try values.decode(String.self, forKey: .type)
        sponsor = try values.decodeIfPresent(String.self, forKey: .sponsor)
    }
}
