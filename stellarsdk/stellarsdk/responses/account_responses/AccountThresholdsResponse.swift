//
//  AccountThresholdsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents account thresholds.
///  See [Stellar documentation](https://www.stellar.org/developers/guides/concepts/multi-sig.html#thresholds "Account Thresholds")
public class AccountThresholdsResponse: NSObject, Decodable {
    
    /// The account's threshhold for low security operations.
    public var lowThreshold:Int
    
    /// The account's threshhold for medium security operations.
    public var medThreshold:Int
    
    /// The account's threshhold for high security operations.
    public var highThreshold:Int
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case lowThreshold = "low_threshold"
        case medThreshold = "med_threshold"
        case highThreshold = "high_threshold"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lowThreshold = try values.decode(Int.self, forKey: .lowThreshold)
        medThreshold = try values.decode(Int.self, forKey: .medThreshold)
        highThreshold = try values.decode(Int.self, forKey: .highThreshold)
    }
}
