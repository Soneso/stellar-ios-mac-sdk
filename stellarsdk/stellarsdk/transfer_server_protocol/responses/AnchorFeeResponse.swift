//
//  AnchorFeeResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.06.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Response returned when requesting fee information for a transaction.
///
/// This response is returned by GET /fee requests in SEP-6 (deprecated endpoint).
/// It provides the fee that would be charged for a specific deposit or withdrawal amount.
///
/// Note: This endpoint is deprecated. Anchors should use the fee information in the
/// GET /info response or the fee_details field in transaction responses instead.
///
/// See [SEP-6 Fee](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#fee)
public struct AnchorFeeResponse: Decodable , Sendable {

    /// The total fee (in units of the asset involved) that would be charged to deposit/withdraw the specified amount of asset_code.
    public let fee:Double
    
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case fee
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fee = try values.decode(Double.self, forKey: .fee)
    }
    
}
