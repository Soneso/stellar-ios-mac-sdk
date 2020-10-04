//
//  EndSponsoringFutureReservesOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class EndSponsoringFutureReservesOperationResponse: OperationResponse {
    
    public var beginSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case beginSponsor = "begin_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        beginSponsor = try values.decode(String.self, forKey: .beginSponsor)
        try super.init(from: decoder)
    }
}
