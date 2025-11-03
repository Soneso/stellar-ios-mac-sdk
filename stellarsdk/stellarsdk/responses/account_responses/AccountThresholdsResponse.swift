//
//  AccountThresholdsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents signature weight thresholds for multi-signature accounts.
///
/// Thresholds determine how many signature weights are required to authorize operations.
/// Each operation type (low, medium, high) requires a total signature weight that meets
/// or exceeds its threshold. Used for implementing multi-sig security.
///
/// Threshold categories:
/// - Low: Allow Trust, Bump Sequence
/// - Medium: All other operations
/// - High: Set Options (changing signers or thresholds)
///
/// See also:
/// - [Multi-Signature Documentation](https://developers.stellar.org/docs/encyclopedia/security/signatures-multisig#multisig)
/// - AccountSignerResponse for signer weights
public class AccountThresholdsResponse: NSObject, Decodable {

    /// Minimum total signature weight required for low security operations. Range: 0-255.
    public var lowThreshold:Int

    /// Minimum total signature weight required for medium security operations. Range: 0-255.
    public var medThreshold:Int

    /// Minimum total signature weight required for high security operations (e.g., changing signers). Range: 0-255.
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
