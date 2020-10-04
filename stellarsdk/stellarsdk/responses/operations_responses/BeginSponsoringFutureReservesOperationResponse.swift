//
//  BeginSponsoringFutureReservesOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class BeginSponsoringFutureReservesOperationResponse: OperationResponse {
    
    public var sponsoredId:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sponsoredId = "sponsored_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sponsoredId = try values.decode(String.self, forKey: .sponsoredId)
        try super.init(from: decoder)
    }
}
