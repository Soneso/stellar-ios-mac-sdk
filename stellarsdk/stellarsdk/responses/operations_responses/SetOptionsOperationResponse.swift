//
//  SetOptionsOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a set options operation response.
///  See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#set-options "Set Options Operation")
public class SetOptionsOperationResponse: OperationResponse {
    
    /// The sum weight for the low threshold.
    public var lowThreshold:Int?
    
    /// The sum weight for the medium threshold.
    public var medThreshold:Int?
    
    /// The sum weight for the high threshold.
    public var highThreshold:Int?
    
    /// The inflation destination account.
    public var inflationDestination:String?
    
    /// The home domain used for reverse federation lookup
    public var homeDomain:String?
    
    /// The public key of the new signer.
    public var signerKey:String?
    
    /// The weight of the new signer (1-255).
    public var signerWeight:Int?
    
    /// The weight of the master key (1-255).
    public var masterKeyWeight:Int?
    
    public var setFlags:[Int]?
    public var setFlagsS:[String]?
    public var clearFlags:[Int]?
    public var clearFlagsS:[String]?
    
    
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
