//
//  PathPaymentStrictSendOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

///  Represents a path payment strict send operation response.
public class PathPaymentStrictSendOperationResponse:PathPaymentOperationResponse {
    
    /// The minimum amount of destination asset expected to be received.
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
