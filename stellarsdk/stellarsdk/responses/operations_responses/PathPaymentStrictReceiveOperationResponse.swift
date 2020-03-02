//
//  PathPaymentStrictReceiveOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.10.19.
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

///  Represents a path payment strict receive operation response.
public class PathPaymentStrictReceiveOperationResponse:PathPaymentOperationResponse {
    
    /// Max send amount.
    public var sourceMax:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sourceMax = "source_max"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sourceMax = try values.decodeIfPresent(String.self, forKey: .sourceMax)
        try super.init(from: decoder)
    }
}
