//
//  PathPaymentStrictSendOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

/// Represents a path payment strict send operation response.
/// This operation sends a path payment where the source amount is specified, and the destination amount varies within a minimum limit.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#path-payment-strict-send "Path Payment Strict Send Operation")
public class PathPaymentStrictSendOperationResponse:PathPaymentOperationResponse {

    /// Minimum amount expected to be received by the destination.
    public var destinationMin:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case destinationMin = "destination_min"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        destinationMin = try values.decodeIfPresent(String.self, forKey: .destinationMin)
        try super.init(from: decoder)
    }
}
