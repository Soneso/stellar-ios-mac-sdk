//
//  SetOptionsOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a set options operation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class SetOptionsOperationResponse: OperationResponse, @unchecked Sendable {
    
    /// Threshold for low-security operations.
    public let lowThreshold:Int?

    /// Threshold for medium-security operations.
    public let medThreshold:Int?

    /// Threshold for high-security operations.
    public let highThreshold:Int?

    /// Account ID designated to receive inflation.
    public let inflationDestination:String?

    /// Home domain used for reverse federation lookup.
    public let homeDomain:String?

    /// Public key of the signer being added or modified.
    public let signerKey:String?

    /// Weight of the signer (0-255). Weight of 0 removes the signer.
    public let signerWeight:Int?

    /// Weight of the master key (0-255).
    public let masterKeyWeight:Int?

    /// Account flags being set (numeric values).
    public let setFlags:[Int]?

    /// Account flags being set (string values).
    public let setFlagsS:[String]?

    /// Account flags being cleared (numeric values).
    public let clearFlags:[Int]?

    /// Account flags being cleared (string values).
    public let clearFlagsS:[String]?
    
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case lowThreshold = "low_threshold"
        case medThreshold = "med_threshold"
        case highThreshold = "high_threshold"
        case inflationDestination = "inflation_dest"
        case homeDomain = "home_domain"
        case signerKey = "signer_key"
        case signerWeight = "signer_weight"
        case masterKeyWeight = "master_key_weight"
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
        lowThreshold = try values.decodeIfPresent(Int.self, forKey: .lowThreshold)
        medThreshold = try values.decodeIfPresent(Int.self, forKey: .medThreshold)
        highThreshold = try values.decodeIfPresent(Int.self, forKey: .highThreshold)
        inflationDestination = try values.decodeIfPresent(String.self, forKey: .inflationDestination)
        homeDomain = try values.decodeIfPresent(String.self, forKey: .homeDomain)
        signerKey = try values.decodeIfPresent(String.self, forKey: .signerKey)
        signerWeight = try values.decodeIfPresent(Int.self, forKey: .signerWeight)
        masterKeyWeight = try values.decodeIfPresent(Int.self, forKey: .masterKeyWeight)
        setFlags = try values.decodeIfPresent(Array.self, forKey: .setFlags)
        setFlagsS = try values.decodeIfPresent(Array.self, forKey: .setFlagsS)
        clearFlags = try values.decodeIfPresent(Array.self, forKey: .clearFlags)
        clearFlagsS = try values.decodeIfPresent(Array.self, forKey: .clearFlagsS)
        
        try super.init(from: decoder)
    }
}
