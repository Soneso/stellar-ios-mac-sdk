//
//  SetTrustLineFlagsOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a set trustline flags operation response.
/// This operation allows an asset issuer to set or clear flags on a trustline, controlling authorization and clawback capabilities.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SetTrustLineFlagsOperationResponse: OperationResponse, @unchecked Sendable {

    /// Account ID of the trustline holder.
    public let trustor:String

    /// Asset type (native / alphanum4 / alphanum12).
    public let assetType:String

    /// Asset code.
    public let assetCode:String?

    /// Asset issuer.
    public let assetIssuer:String?

    /// Flags being set (numeric values).
    public let setFlags:[Int]?

    /// Flags being set (string values).
    public let setFlagsS:[String]?

    /// Flags being cleared (numeric values).
    public let clearFlags:[Int]?

    /// Flags being cleared (string values).
    public let clearFlagsS:[String]?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case trustor
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case setFlags = "set_flags"
        case setFlagsS = "set_flags_s"
        case clearFlags = "clear_flags"
        case clearFlagsS = "clear_flags_s"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trustor = try values.decode(String.self, forKey: .trustor)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        setFlags = try values.decodeIfPresent(Array.self, forKey: .setFlags)
        setFlagsS = try values.decodeIfPresent(Array.self, forKey: .setFlagsS)
        clearFlags = try values.decodeIfPresent(Array.self, forKey: .clearFlags)
        clearFlagsS = try values.decodeIfPresent(Array.self, forKey: .clearFlagsS)
        try super.init(from: decoder)
    }
}
